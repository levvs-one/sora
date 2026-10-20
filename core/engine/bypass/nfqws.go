package bypass

import (
	"context"
	"fmt"
	"runtime"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/logs"
)

// The nfqws executor: the runtime half of the nfqws backend, sibling to
// the tpws path in bypass.go. One Engine supervises both backends with
// the same lifecycle, the same log source and the same fail-closed
// policy; only the interception mechanics differ (a loopback SOCKS
// listener for tpws, NFQUEUE steering for nfqws).
//
// See NFQWS-MIGRATION.md for the design. Windows (winws/WinDivert) is
// interface-only: discovery finds winws.exe, but no executor starts it
// yet, and Apply says so instead of pretending (see nfqws_other.go).

// interceptor owns the kernel-side steering that feeds nfqws: which
// output traffic lands in which NFQUEUE. Implementations replace the
// whole state atomically, so the kernel never holds rules for queues
// with no live instance behind them.
type interceptor interface {
	// Sync makes the interception state exactly specs; an empty list
	// removes it entirely.
	Sync(ctx context.Context, specs []QueueSpec) error
	// Sweep drops state left behind by a previous core process that
	// died before it could clean up.
	Sweep(ctx context.Context) error
}

// filter is one running nfqws instance: one per distinct rendered
// argument set (NFQWSArgs), serving every outbound whose strategy
// renders the same.
type filter struct {
	queue  int
	spec   QueueSpec
	proc   *supervise.Process
	cancel context.CancelFunc
}

// nfqKey identifies a strategy for the nfqws backend: the rendered
// command line, mirroring how key() identifies tpws strategies.
func (e *Engine) nfqKey(s engine.BypassStrategy) string {
	return strings.Join(NFQWSArgs(s, e.assetsDir()), " ")
}

// assetsDir is where fake payload files live: the shipped zapret
// directory (engines/zapret) when discovery provided one, else the
// runtime zapret home (tests and embedded use).
func (e *Engine) assetsDir() string {
	if e.assets != "" {
		return e.assets
	}
	return e.home
}

// sweep drops a stale interception table left by a previous core,
// logging instead of failing: the table is ours alone, and the Sync
// that follows a failed sweep reports the real error.
func (e *Engine) sweep(ctx context.Context, icept interceptor) {
	if err := icept.Sweep(ctx); err != nil && e.logs != nil {
		e.logs.Write(time.Time{}, logs.LevelWarning, Source,
			fmt.Sprintf("nfqws: dropping a stale interception table failed: %v", err))
	}
}

// interceptor lazily builds the platform interceptor and caches the
// outcome: building it resolves the privileged nft helper from the
// trusted system directories, which must not be redone per Apply.
func (e *Engine) interceptor() (interceptor, error) {
	if e.iceptOverride != nil {
		return e.iceptOverride, nil
	}
	e.iceptOnce.Do(func() {
		e.icept, e.iceptErr = newInterceptor()
	})
	return e.icept, e.iceptErr
}

// checkNFQWS fails closed before any state changes when the plan needs
// the nfqws backend but this host cannot run it: no binary, no
// interception on this platform, or a strategy that would queue
// unfiltered traffic. The error names the missing piece (spec §6);
// there is no silent tpws fallback. ids maps each needed key to an
// outbound that carries it, for error attribution.
func (e *Engine) checkNFQWS(needed map[string]engine.BypassStrategy, ids map[string]string) error {
	if e.nfqws == "" {
		for _, id := range ids {
			return fmt.Errorf("bypass: outbound %s needs the nfqws backend, but nfqws is not installed in the engines directory", id)
		}
	}
	if _, err := e.interceptor(); err != nil {
		for _, id := range ids {
			return fmt.Errorf("bypass: outbound %s needs the nfqws backend: %w", id, err)
		}
	}
	for k, s := range needed {
		if s.FilterTCP == "" && s.FilterUDP == "" {
			return fmt.Errorf("bypass: outbound %s sets no filter-tcp/filter-udp: the executor will not queue unfiltered traffic", ids[k])
		}
	}
	return nil
}

// syncFilters reconciles the running nfqws instances with the plan's
// needed set. Kernel rules are synced to the desired set before any
// process starts, so a queue never exists without rules being final,
// and re-synced to the survivors if a start fails.
func (e *Engine) syncFilters(ctx context.Context, needed map[string]engine.BypassStrategy) error {
	e.mu.Lock()
	running := len(e.filters)
	e.mu.Unlock()
	if len(needed) == 0 && running == 0 {
		// Nothing to run. Still sweep a stale table once, best
		// effort: a previous core may have died holding it, and its
		// rules would keep steering traffic into dead queues. A host
		// without nft cannot have the table either, so an interceptor
		// error here is not fatal — unlike the paths below, where
		// nfqws is actually required.
		e.sweepOnce.Do(func() {
			if icept, err := e.interceptor(); err == nil {
				e.sweep(ctx, icept)
			}
		})
		return nil
	}
	icept, err := e.interceptor()
	if err != nil {
		return err // already wrapped by checkNFQWS on the Apply path
	}
	e.sweepOnce.Do(func() { e.sweep(ctx, icept) })

	// Assign queues: running instances keep theirs, new strategies
	// take a free one.
	e.mu.Lock()
	queues := make(map[string]int, len(needed))
	var fresh []int
	for k := range needed {
		if f, ok := e.filters[k]; ok {
			queues[k] = f.queue
			continue
		}
		q, ok := e.alloc.Acquire()
		if !ok {
			e.mu.Unlock()
			for _, rq := range fresh {
				e.alloc.Release(rq)
			}
			return fmt.Errorf("bypass: more than %d distinct nfqws strategies in one plan", queueCount)
		}
		fresh = append(fresh, q)
		queues[k] = q
	}
	e.mu.Unlock()

	specs := make([]QueueSpec, 0, len(needed))
	for k, s := range needed {
		specs = append(specs, QueueSpec{Queue: queues[k], TCPPorts: s.FilterTCP, UDPPorts: s.FilterUDP})
	}
	slices.SortFunc(specs, func(a, b QueueSpec) int { return a.Queue - b.Queue })
	if err := icept.Sync(ctx, specs); err != nil {
		for _, q := range fresh {
			e.alloc.Release(q)
		}
		return fmt.Errorf("bypass: installing nfqws queue rules: %w", err)
	}

	// Stop instances the plan no longer needs.
	e.mu.Lock()
	for k, f := range e.filters {
		if _, keep := needed[k]; !keep {
			f.stop()
			e.alloc.Release(f.queue)
			delete(e.filters, k)
		}
	}
	e.mu.Unlock()

	// Start the missing instances outside the lock, like tpws: a
	// start waits for the process to settle.
	for k, s := range needed {
		if e.currentFilter(k) != nil {
			continue
		}
		f, err := e.startFilter(ctx, s, queues[k])
		if err != nil {
			// Re-sync the rules to the instances that actually run,
			// so a failed start never leaves a queue rule steering
			// traffic into a dead queue.
			e.resyncRules(ctx)
			e.alloc.Release(queues[k])
			return err
		}
		e.publishFilter(k, f)
	}
	return nil
}

// resyncRules rewrites the kernel state to match the live instances
// after a partial failure. Best effort: the caller already returns the
// start error, and a later Apply re-syncs from scratch.
func (e *Engine) resyncRules(ctx context.Context) {
	icept, err := e.interceptor()
	if err != nil {
		return
	}
	e.mu.Lock()
	specs := make([]QueueSpec, 0, len(e.filters))
	for _, f := range e.filters {
		specs = append(specs, f.spec)
	}
	e.mu.Unlock()
	slices.SortFunc(specs, func(a, b QueueSpec) int { return a.Queue - b.Queue })
	_ = icept.Sync(ctx, specs)
}

func (e *Engine) currentFilter(k string) *filter {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.filters[k]
}

// publishFilter installs a started filter, or drops it in favour of
// one a concurrent Apply installed first (same discipline as tpws).
func (e *Engine) publishFilter(k string, f *filter) *filter {
	e.mu.Lock()
	defer e.mu.Unlock()
	if cur, ok := e.filters[k]; ok {
		f.stop()
		e.alloc.Release(f.queue)
		return cur
	}
	e.filters[k] = f
	return f
}

// startFilter supervises one nfqws process on its queue. nfqws has no
// listener to probe: readiness is the process surviving its startup
// window, because a bad argument set, a missing fake file or a kernel
// without NFQUEUE support all make it exit immediately with the reason
// on its output.
func (e *Engine) startFilter(ctx context.Context, strategy engine.BypassStrategy, queue int) (*filter, error) {
	args := append([]string{"--qnum=" + strconv.Itoa(queue)}, NFQWSArgs(strategy, e.assetsDir())...)
	pctx, cancel := context.WithCancel(context.Background())
	f := &filter{queue: queue, cancel: cancel,
		spec: QueueSpec{Queue: queue, TCPPorts: strategy.FilterTCP, UDPPorts: strategy.FilterUDP}}
	spec := supervise.Spec{Name: "nfqws", Path: e.nfqws, Args: args, Dir: e.home, Lines: e.logLine}
	proc, err := supervise.Start(pctx, spec)
	if err != nil {
		cancel()
		return nil, err
	}
	f.proc = proc
	if err := waitSettled(ctx, proc); err != nil {
		f.stop()
		return nil, fmt.Errorf("bypass: nfqws (queue %d) did not start: %w", queue, err)
	}
	go e.keepFilter(pctx, f, spec)
	return f, nil
}

// waitSettled gives a freshly started nfqws a short window to die of
// its startup errors. 250 ms is generous for a queue-open failure and
// bounds the Apply latency a new strategy adds.
func waitSettled(ctx context.Context, proc *supervise.Process) error {
	deadline := time.NewTimer(250 * time.Millisecond)
	defer deadline.Stop()
	tick := time.NewTicker(10 * time.Millisecond)
	defer tick.Stop()
	for {
		if proc.Exited() {
			if err := proc.Err(); err != nil {
				return fmt.Errorf("%v (output: %s)", err, strings.TrimSpace(proc.Output().String()))
			}
			return fmt.Errorf("nfqws exited during startup (output: %s)", strings.TrimSpace(proc.Output().String()))
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-deadline.C:
			return nil
		case <-tick.C:
		}
	}
}

func (e *Engine) keepFilter(ctx context.Context, f *filter, spec supervise.Spec) {
	backoff := engine.DefaultBackoff()
	for attempt := 0; ; attempt++ {
		e.mu.Lock()
		proc := f.proc
		e.mu.Unlock()
		if err := proc.Wait(ctx); ctx.Err() != nil {
			return
		} else if e.logs != nil {
			e.logs.Write(time.Time{}, logs.LevelWarning, Source, fmt.Sprintf("nfqws stopped (%v); starting it again", err))
		}
		if backoff.Wait(ctx, attempt) != nil {
			return
		}
		next, err := supervise.Start(ctx, spec)
		if err != nil {
			continue
		}
		e.mu.Lock()
		f.proc = next
		e.mu.Unlock()
	}
}

func (f *filter) stop() {
	f.cancel()
	_ = f.proc.Stop(context.Background(), time.Second)
}

// stopFilters stops every nfqws instance and removes the interception
// state. Called from Engine.Stop/Close alongside the tpws teardown.
func (e *Engine) stopFilters(ctx context.Context) {
	e.mu.Lock()
	filters := e.filters
	e.filters = map[string]*filter{}
	e.mu.Unlock()
	for _, f := range filters {
		f.stop()
		e.alloc.Release(f.queue)
	}
	if len(filters) == 0 {
		return
	}
	if icept, err := e.interceptor(); err == nil {
		_ = icept.Sync(ctx, nil)
	}
}

// platformExecutorNote names the piece a non-Linux host is missing, for
// fail-closed errors. Windows has discovery and an interface but no
// executor yet (WinDivert driver step pending, NFQWS-MIGRATION.md §3).
func platformExecutorNote() string {
	if runtime.GOOS == "windows" {
		return "the winws executor is not wired up yet (WinDivert driver step pending; see core/engine/bypass/NFQWS-MIGRATION.md)"
	}
	return "the nfqws executor runs on Linux only"
}
