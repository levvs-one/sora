package ext

// Background workers (runtime v2): periodic tasks for extensions that
// declare the "background" capability and hold the "background" permission.
//
// A worker runs in WorkerEnv, a deliberately small sandbox: it can append
// to the extension log and, only when the extension also holds "net.fetch",
// make allowlisted HTTP requests through the extension's own Fetcher. There
// is no filesystem, no process control, no raw network. The app-side JS
// runner executes the manifest's worker script inside this envelope; the
// Go WorkerFunc below is the seam where the host plugs that runner in.
//
// Scheduling: the declared interval_minutes is clamped into
// [MinWorkerInterval, MaxWorkerInterval]. Every run's outcome - success or
// failure, including a recovered panic - is written to the extension log.

import (
	"context"
	"fmt"
	"hash/fnv"
	"net/http"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Worker scheduling bounds. The 15-minute floor keeps a buggy or hostile
// extension from hot-looping the device; the 7-day ceiling matches the
// largest declarable manifest interval.
const (
	MinWorkerInterval = 15 * time.Minute
	MaxWorkerInterval = 7 * 24 * time.Hour
	// WorkerRunTimeout bounds one worker execution.
	WorkerRunTimeout = 5 * time.Minute
	// maxConsecutiveWorkerFailures is the circuit breaker: a task whose run
	// keeps failing is unregistered (stopped) after this many consecutive
	// failures. A permanently broken worker must not burn CPU, log volume
	// and battery forever; the next app start re-registers it from the
	// stored manifest, so a fixed extension recovers on its own.
	maxConsecutiveWorkerFailures = 10
)

// ClampWorkerInterval maps a declared interval in minutes to the effective
// schedule: at least MinWorkerInterval, at most MaxWorkerInterval.
func ClampWorkerInterval(minutes int) time.Duration {
	d := time.Duration(minutes) * time.Minute
	if d < MinWorkerInterval {
		return MinWorkerInterval
	}
	if d > MaxWorkerInterval {
		return MaxWorkerInterval
	}
	return d
}

// WorkerEnv is the limited environment one worker run executes in. It is
// intentionally narrow: logging plus optional allowlisted fetching. A nil
// Fetcher means the extension was not granted "net.fetch", and Fetch then
// reports a permission error instead of touching the network.
type WorkerEnv struct {
	extID   string
	log     *ExtLog
	fetcher *Fetcher
}

// Logf appends a formatted line to the extension's log.
func (e *WorkerEnv) Logf(format string, args ...any) {
	e.log.Append(LogInfo, fmt.Sprintf(format, args...))
}

// Fetch performs an allowlisted HTTP request on the worker's behalf. It
// fails closed when the extension lacks the "net.fetch" permission.
func (e *WorkerEnv) Fetch(ctx context.Context, req FetchRequest) (*FetchResponse, error) {
	if e.fetcher == nil {
		e.log.Append(LogWarn, "fetch DENIED: extension was not granted the \"net.fetch\" permission")
		return nil, errs.Newf(errs.CodePermissionDenied, KeyNetFetchDenied,
			"ext: net.fetch requires the %q permission", "net.fetch")
	}
	return e.fetcher.Fetch(ctx, req)
}

// WorkerFunc is one worker execution. A nil error means success; anything
// else (or a panic) is recorded in the extension log as a failed run.
type WorkerFunc func(ctx context.Context, env *WorkerEnv) error

// WorkerTask is a registered periodic task.
type WorkerTask struct {
	ExtensionID string
	// Interval is the effective, clamped schedule.
	Interval time.Duration
	// Entry is the manifest's worker script (for the app-side JS runner).
	Entry string

	run     WorkerFunc
	fetcher *Fetcher
	// running guards against overlapping runs: when a run overruns the
	// interval, the next tick is skipped instead of piling up.
	running atomic.Bool
	// disabled is set when the user's <id>.background.json says
	// enabled=false: the task is registered but never runs. The extension
	// itself stays installed and enabled.
	disabled atomic.Bool
	// fails counts consecutive failed runs for the circuit breaker.
	fails atomic.Int32
	// Last-run bookkeeping for Scheduler.Status. A skipped (overlap) tick
	// is not a run and is never recorded here.
	hasRun             atomic.Bool
	lastRunUnixNano    atomic.Int64
	lastRunOK          atomic.Bool
	lastRunInterrupted atomic.Bool
	// ctx is the task loop's context, derived from the scheduler's run
	// context. It is canceled when the task is unregistered, replaced, or
	// the scheduler stops, so no ticker loop outlives its task.
	ctx  context.Context
	stop context.CancelFunc // cancels ctx; nil until the scheduler starts
}

// Scheduler owns background tasks for enabled extensions.
type Scheduler struct {
	mu     sync.Mutex
	tasks  map[string]*WorkerTask
	hub    *LogHub
	runCtx context.Context // non-nil while Start..Stop is active
	stop   context.CancelFunc
	wg     sync.WaitGroup
	// fetchTransport, when set, supplies the HTTP transport for an
	// extension's net.fetch. Production wiring must return a transport
	// bound to the core's tunnel (local proxy), so extension traffic
	// follows the VPN instead of leaking direct. Nil (tests, dev) means
	// direct dials. Set before Start/Register; not safe to change while
	// running.
	fetchTransport func(extensionID string) http.RoundTripper
	// Kill-switch pause (see SetKillSwitch). While paused, ticker loops
	// wait instead of starting runs, Fetcher.Fetch fails fast, and the
	// in-flight runs' contexts are canceled. pauseMu guards paused and
	// pauseCh; pauseCtx/pauseCancel back the in-flight run contexts and
	// are recreated on every pause so post-resume runs are not born
	// canceled.
	pauseMu     sync.Mutex
	paused      bool
	pauseCh     chan struct{} // non-nil while paused; closed on resume to wake the waiters
	pauseCtx    context.Context
	pauseCancel context.CancelFunc
}

// NewScheduler returns a scheduler writing to hub. A nil hub gets a fresh
// one.
func NewScheduler(hub *LogHub) *Scheduler {
	if hub == nil {
		hub = NewLogHub()
	}
	pauseCtx, pauseCancel := context.WithCancel(context.Background())
	return &Scheduler{tasks: map[string]*WorkerTask{}, hub: hub, pauseCtx: pauseCtx, pauseCancel: pauseCancel}
}

// Hub exposes the log sink the scheduler writes to.
func (s *Scheduler) Hub() *LogHub { return s.hub }

// SetFetchTransport installs the hook that supplies the HTTP transport for
// an extension's net.fetch (see the fetchTransport field). Call before
// Start/Register.
func (s *Scheduler) SetFetchTransport(fn func(extensionID string) http.RoundTripper) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.fetchTransport = fn
}

// fetchTransportFor returns the configured transport for extID, or nil for
// direct dials.
func (s *Scheduler) fetchTransportFor(extID string) http.RoundTripper {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.fetchTransport == nil {
		return nil
	}
	return s.fetchTransport(extID)
}

// Register validates the manifest pair and installs the task. It requires
// the "background" capability and permission plus a declared
// background_task; the effective schedule is the manifest's declared
// interval clamped (see ClampWorkerInterval), because no user override was
// supplied. A nil run is rejected. Re-registering an extension replaces its
// task.
//
// To apply the user's <id>.background.json override, read it with
// Store.GetBackgroundConfig and call RegisterConfig instead.
func (s *Scheduler) Register(m *Manifest, x *ManifestExt, run WorkerFunc) error {
	return s.RegisterConfig(m, x, BackgroundDefaults(x), run)
}

// RegisterConfig is Register with an explicit BackgroundConfig (the user's
// <id>.background.json override, see background.go):
//   - cfg.IntervalMinutes replaces the manifest's declared interval and is
//     clamped into [MinWorkerInterval, MaxWorkerInterval];
//   - cfg.Enabled=false registers the task disabled: it is stored and
//     visible via Task, but no ticker loop starts and no run ever fires.
//     The extension itself stays installed and enabled. Re-registering
//     with enabled=true resumes the schedule.
func (s *Scheduler) RegisterConfig(m *Manifest, x *ManifestExt, cfg BackgroundConfig, run WorkerFunc) error {
	if m == nil || x == nil || x.Background == nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			"ext: background worker needs a manifest with background_task")
	}
	if !hasCapability(m, "background") {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			`ext: background worker requires the "background" capability`)
	}
	if !hasPermission(m, "background") {
		return errs.Newf(errs.CodePermissionDenied, KeyBackgroundInvalid,
			`ext: background worker requires the "background" permission`)
	}
	if run == nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			"ext: background worker needs a run function")
	}
	var fetcher *Fetcher
	if hasPermission(m, "net.fetch") {
		f, err := NewFetcherForExtensionWithTransport(m.ID, x, FetchLimits{}, s.fetchTransportFor(m.ID), s.hub)
		if err != nil {
			return err
		}
		// The fetcher fails fast while the kill-switch pause is active;
		// the gate is read on every Fetch call, so toggling the pause
		// needs no fetcher rebuild.
		f.paused = s.Paused
		fetcher = f
	}
	task := &WorkerTask{
		ExtensionID: m.ID,
		Interval:    ClampWorkerInterval(cfg.IntervalMinutes),
		Entry:       x.Background.Entry,
		run:         run,
		fetcher:     fetcher,
	}
	task.disabled.Store(!cfg.Enabled)
	s.mu.Lock()
	if old, ok := s.tasks[m.ID]; ok && old.stop != nil {
		// Replacing a running task: stop the old ticker loop first, or
		// two loops would fire for the same extension.
		old.stop()
	}
	s.tasks[m.ID] = task
	var taskCtx context.Context
	if s.runCtx != nil && !task.disabled.Load() {
		taskCtx, task.stop = context.WithCancel(s.runCtx)
		task.ctx = taskCtx
	}
	s.mu.Unlock()
	if task.disabled.Load() {
		s.hub.Log(m.ID).Append(LogInfo,
			"background worker disabled by the user's background.json override; not scheduled")
		return nil
	}
	s.hub.Log(m.ID).Append(LogInfo,
		fmt.Sprintf("background worker registered: every %s (wanted %d min), entry %s",
			task.Interval, cfg.IntervalMinutes, task.Entry))
	if taskCtx != nil {
		s.startLoopWith(task)
	}
	return nil
}

// Unregister removes the extension's task, if any, and stops its ticker
// loop.
func (s *Scheduler) Unregister(extID string) {
	s.mu.Lock()
	task, ok := s.tasks[extID]
	delete(s.tasks, extID)
	s.mu.Unlock()
	if ok && task.stop != nil {
		task.stop()
	}
}

// Task returns the registered task for extID.
func (s *Scheduler) Task(extID string) (*WorkerTask, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	t, ok := s.tasks[extID]
	return t, ok
}

// WorkerStatus is an honest snapshot of one registered background task:
// what the scheduler actually knows, nothing more. It exists so the host
// (and one day the UI) can say "disabled by the user", "paused by the kill
// switch" or "last run failed" instead of guessing from the install state.
// A task stopped by the circuit breaker is unregistered, so it reports
// ok=false here exactly like a never-registered extension - the breaker
// trip itself is in the extension log.
type WorkerStatus struct {
	ExtensionID string
	// Entry is the manifest's worker script.
	Entry string
	// Interval is the effective, clamped schedule.
	Interval time.Duration
	// Disabled: the user's background.json override turned this worker
	// off; it is registered but never runs.
	Disabled bool
	// Running: a run is in flight right now.
	Running bool
	// Paused: the scheduler-wide kill-switch pause is active.
	Paused bool
	// ConsecutiveFailures is the circuit-breaker counter.
	ConsecutiveFailures int
	// HasRun reports whether any run has finished (ok, failed or
	// interrupted) since registration.
	HasRun bool
	// LastRunAt is when the last finished run ended. Zero without HasRun.
	LastRunAt time.Time
	// LastRunOK is the last finished run's outcome. It is false for a
	// failed run and for an interrupted one (see LastRunInterrupted).
	LastRunOK bool
	// LastRunInterrupted: the last run was aborted by the kill-switch
	// pause or by the task being stopped/unregistered - not a failure,
	// and it never counted toward the circuit breaker.
	LastRunInterrupted bool
	// Fetch holds the task fetcher's counters, or nil when the extension
	// was not granted "net.fetch" and has no fetcher.
	Fetch *FetchStats
}

// Status returns the status snapshot for one registered task.
func (s *Scheduler) Status(extID string) (WorkerStatus, bool) {
	s.mu.Lock()
	t, ok := s.tasks[extID]
	s.mu.Unlock()
	if !ok {
		return WorkerStatus{}, false
	}
	return s.statusOf(t), true
}

// Statuses returns snapshots of all registered tasks, sorted by id.
func (s *Scheduler) Statuses() []WorkerStatus {
	s.mu.Lock()
	tasks := make([]*WorkerTask, 0, len(s.tasks))
	for _, t := range s.tasks {
		tasks = append(tasks, t)
	}
	s.mu.Unlock()
	out := make([]WorkerStatus, 0, len(tasks))
	for _, t := range tasks {
		out = append(out, s.statusOf(t))
	}
	sort.Slice(out, func(i, j int) bool { return out[i].ExtensionID < out[j].ExtensionID })
	return out
}

func (s *Scheduler) statusOf(t *WorkerTask) WorkerStatus {
	st := WorkerStatus{
		ExtensionID:         t.ExtensionID,
		Entry:               t.Entry,
		Interval:            t.Interval,
		Disabled:            t.disabled.Load(),
		Running:             t.running.Load(),
		Paused:              s.Paused(),
		ConsecutiveFailures: int(t.fails.Load()),
		HasRun:              t.hasRun.Load(),
		LastRunOK:           t.lastRunOK.Load(),
		LastRunInterrupted:  t.lastRunInterrupted.Load(),
	}
	if ns := t.lastRunUnixNano.Load(); ns != 0 {
		st.LastRunAt = time.Unix(0, ns).UTC()
	}
	if t.fetcher != nil {
		fs := t.fetcher.Stats()
		st.Fetch = &fs
	}
	return st
}

// recordRun stores one finished run's outcome for Status.
func (t *WorkerTask) recordRun(ok, interrupted bool) {
	t.lastRunUnixNano.Store(time.Now().UnixNano())
	t.lastRunOK.Store(ok)
	t.lastRunInterrupted.Store(interrupted)
	t.hasRun.Store(true)
}

// Start begins ticking all registered tasks. It is idempotent; tasks
// registered while running start ticking immediately.
func (s *Scheduler) Start(ctx context.Context) {
	s.mu.Lock()
	if s.runCtx != nil {
		s.mu.Unlock()
		return
	}
	runCtx, cancel := context.WithCancel(ctx)
	s.runCtx = runCtx
	s.stop = cancel
	tasks := make([]*WorkerTask, 0, len(s.tasks))
	for _, t := range s.tasks {
		if t.disabled.Load() {
			// The user turned this worker off via background.json: no
			// ticker loop, no runs. Re-registering enabled starts it.
			continue
		}
		tasks = append(tasks, t)
		t.ctx, t.stop = context.WithCancel(runCtx)
	}
	s.mu.Unlock()
	for _, t := range tasks {
		s.startLoopWith(t)
	}
}

// Stop halts all task loops and waits for in-flight runs to finish.
func (s *Scheduler) Stop() {
	s.mu.Lock()
	if s.runCtx == nil {
		s.mu.Unlock()
		return
	}
	stop := s.stop
	s.runCtx = nil
	s.stop = nil
	s.mu.Unlock()
	stop()
	s.wg.Wait()
}

// SetKillSwitch pauses (active=true) or resumes (active=false) all
// background extension work. It is the host's hook for the VPN kill
// switch: call it when the guard arms (e.g. Session.SetKillSwitch(true) /
// guard.Apply) and again when the switch is lifted.
//
// While paused:
//   - ticker loops wait instead of starting runs - no worker executes,
//     not even once, until resume;
//   - Fetcher.Fetch fails fast with ext.netfetch.paused, so no background
//     request is attempted against the blocked network;
//   - the contexts of runs that are already in flight are canceled, so
//     their network I/O stops promptly instead of draining the timeout.
//     Such an interrupted run is logged but NOT counted toward the circuit
//     breaker.
//
// Resume needs no re-registration: the waiting loops pick up their normal
// schedule. No goroutine is spawned per pause/resume or per tick - the
// waiting happens inside the existing ticker loops, so pausing cannot leak.
func (s *Scheduler) SetKillSwitch(active bool) {
	s.pauseMu.Lock()
	if active == s.paused {
		s.pauseMu.Unlock()
		return
	}
	s.paused = active
	s.mu.Lock()
	tasks := make([]*WorkerTask, 0, len(s.tasks))
	for _, t := range s.tasks {
		tasks = append(tasks, t)
	}
	s.mu.Unlock()
	if active {
		s.pauseCh = make(chan struct{})
		// Abort in-flight runs: their contexts derive from pauseCtx.
		// Recreate it at once so runs started after resume are not born
		// canceled.
		s.pauseCancel()
		s.pauseCtx, s.pauseCancel = context.WithCancel(context.Background())
		s.pauseMu.Unlock()
		for _, t := range tasks {
			s.hub.Log(t.ExtensionID).Append(LogWarn,
				"background network paused: kill switch is active")
		}
		return
	}
	ch := s.pauseCh
	s.pauseCh = nil
	s.pauseMu.Unlock()
	close(ch) // wakes the loops waiting in waitWhilePaused
	for _, t := range tasks {
		s.hub.Log(t.ExtensionID).Append(LogInfo,
			"background network resumed: kill switch is off")
	}
}

// Paused reports whether the kill-switch pause is active. The scheduler
// wires it into every task fetcher, so extension fetches fail fast while
// paused.
func (s *Scheduler) Paused() bool {
	s.pauseMu.Lock()
	defer s.pauseMu.Unlock()
	return s.paused
}

// waitWhilePaused blocks while the kill-switch pause is active. It returns
// false when ctx ends first (unregistered, replaced, or scheduler
// stopped), in which case the caller must exit its loop.
//
// The pause predicate is re-checked after every wakeup: a tick that read
// the pause channel just before a resume→re-pause toggle must not trust
// the stale wakeup, or it would start a run while the kill switch is
// active again.
func (s *Scheduler) waitWhilePaused(ctx context.Context) bool {
	for {
		s.pauseMu.Lock()
		ch := s.pauseCh
		s.pauseMu.Unlock()
		if ch == nil {
			return true
		}
		select {
		case <-ctx.Done():
			return false
		case <-ch:
			// Resumed - but a new pause may have started already;
			// loop back and re-check instead of running.
		}
	}
}

// startLoopWith runs the ticker loop for one task until the task's context
// ends (unregistered, replaced, or scheduler stopped).
func (s *Scheduler) startLoopWith(task *WorkerTask) {
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()
		// Stagger the first run so N extensions enabled at once do not
		// fire simultaneously; the stagger is deterministic per
		// extension id and bounded by one minute.
		h := fnv.New32a()
		_, _ = h.Write([]byte(task.ExtensionID))
		stagger := time.Duration(h.Sum32()%60) * time.Second
		timer := time.NewTimer(stagger + task.Interval)
		defer timer.Stop()
		for {
			select {
			case <-task.ctx.Done():
				return
			case <-timer.C:
				// While the kill-switch pause is active the loop waits
				// here instead of starting runs; on resume the normal
				// schedule continues. The wait happens in this same
				// goroutine - no extra goroutine per tick or per pause.
				if !s.waitWhilePaused(task.ctx) {
					return
				}
				s.runOnce(task)
				timer.Reset(task.Interval)
			}
		}
	}()
}

// runOnce executes one task run with a timeout, recovers panics, and logs
// the outcome to the extension's log.
//
// Two guards keep one bad worker from hurting the host:
//   - overlap: a run that overruns the interval makes the next tick skip
//     instead of piling concurrent runs onto the device;
//   - circuit breaker: after maxConsecutiveWorkerFailures consecutive
//     failures the task is unregistered (stopped) with an error in the log.
//     The extension itself stays installed and enabled; the next app start
//     re-registers its worker from the stored manifest.
//
// A run aborted by the host - the kill-switch pause (see SetKillSwitch)
// or the task being stopped/unregistered - is logged as interrupted and
// does not count toward the circuit breaker.
func (s *Scheduler) runOnce(task *WorkerTask) {
	if !task.running.CompareAndSwap(false, true) {
		s.hub.Log(task.ExtensionID).Append(LogWarn,
			"background worker run skipped: the previous run is still in flight")
		return
	}
	defer task.running.Store(false)
	// The run context ends with whichever comes first: the run timeout,
	// the task's own context (unregistered, replaced, or the scheduler
	// stopping - Stop must not block on a stuck worker until the timeout
	// drains), or the kill-switch pause context (SetKillSwitch(true)
	// cancels it, aborting in-flight runs and their fetches promptly).
	base := task.ctx
	if base == nil {
		base = context.Background()
	}
	ctx, cancel := context.WithTimeout(base, WorkerRunTimeout)
	defer cancel()
	s.pauseMu.Lock()
	pctx := s.pauseCtx
	s.pauseMu.Unlock()
	stopPauseLink := context.AfterFunc(pctx, cancel)
	defer stopPauseLink()
	env := &WorkerEnv{extID: task.ExtensionID, log: s.hub.Log(task.ExtensionID), fetcher: task.fetcher}
	start := time.Now()
	err := func() (err error) {
		defer func() {
			if r := recover(); r != nil {
				err = errs.Newf(errs.CodeInvalidArgument, KeyWorkerFailed,
					"ext: background worker panicked: %v", r)
			}
		}()
		return task.run(ctx, env)
	}()
	elapsed := time.Since(start).Truncate(time.Millisecond)
	if err != nil {
		// A run aborted by the host is not a failure: the kill-switch
		// pause cut the network under it, or the task was stopped /
		// unregistered / replaced under it. Log it as interrupted and
		// keep it out of the circuit breaker, or a few switch toggles
		// (or one disable) would permanently unregister a healthy
		// worker.
		if ctx.Err() != nil && s.Paused() {
			task.recordRun(false, true)
			s.hub.Log(task.ExtensionID).Append(LogInfo,
				fmt.Sprintf("background worker run interrupted by the kill-switch pause after %s", elapsed))
			return
		}
		if task.ctx != nil && task.ctx.Err() != nil {
			task.recordRun(false, true)
			s.hub.Log(task.ExtensionID).Append(LogInfo,
				fmt.Sprintf("background worker run interrupted: the task was stopped after %s", elapsed))
			return
		}
		task.recordRun(false, false)
		n := task.fails.Add(1)
		s.hub.Log(task.ExtensionID).Append(LogError,
			fmt.Sprintf("background worker run failed after %s: %v", elapsed, oneLine(err, 300)))
		if n >= maxConsecutiveWorkerFailures {
			s.hub.Log(task.ExtensionID).Append(LogError,
				fmt.Sprintf("background worker stopped after %d consecutive failures; it will be re-registered on the next start", n))
			s.Unregister(task.ExtensionID)
		}
		return
	}
	task.recordRun(true, false)
	task.fails.Store(0)
	s.hub.Log(task.ExtensionID).Append(LogInfo,
		fmt.Sprintf("background worker run ok (%s)", elapsed))
}

// oneLine collapses an error to a single bounded line for logs.
func oneLine(err error, limit int) string {
	s := strings.ReplaceAll(strings.ReplaceAll(err.Error(), "\n", " "), "\r", " ")
	s = strings.Join(strings.Fields(s), " ")
	if len(s) > limit {
		s = s[:limit] + "…"
	}
	return s
}
