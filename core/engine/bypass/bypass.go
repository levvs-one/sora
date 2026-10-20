// Package bypass runs zapret to reshape direct TLS, HTTP and QUIC
// handshakes against DPI. Legacy strategies run on tpws, one loopback
// SOCKS5 proxy per strategy, with bypass outbounds rewritten to SOCKS5;
// strategies with desync methods run on the nfqws executor (fake
// packets, autottl, UDP/QUIC desync over NFQUEUE on Linux), whose
// outbounds stay direct at the engine — desync happens at the packet
// layer below it. Both backends share one lifecycle, one log source and
// one fail-closed policy in this package (see NFQWS-MIGRATION.md).
// Windows winws is discovery-only for now: such plans fail closed
// naming the pending WinDivert step. Supports all engines, rules, and
// groups.
package bypass

import (
	"context"
	"errors"
	"fmt"
	"net"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/logs"
)

// Source names zapret in the log center.
const Source = "zapret"

// Backend is the zapret binary a strategy runs on.
type Backend int

const (
	// BackendTPWS is zapret's transparent SOCKS proxy: TCP only, no
	// packet injection.
	BackendTPWS Backend = iota
	// BackendNFQWS is zapret's packet filter (nfqws on Linux, winws on
	// Windows): fake packets, autottl, UDP/QUIC desync. The Linux
	// executor is wired (nfqws.go); the Windows one is not yet.
	BackendNFQWS
)

// BackendOf reports which zapret binary a strategy needs. Any desync
// method selects nfqws; the legacy split/disorder/oob/tlsrec/HTTP
// shaping runs on tpws.
func BackendOf(s engine.BypassStrategy) Backend {
	if len(s.Desync) > 0 {
		return BackendNFQWS
	}
	return BackendTPWS
}

// defaultQUICFake is the shipped QUIC Initial used when a strategy asks
// for the "quic" fake keyword. QUIC has no built-in fake in zapret, so
// the file (packaging/zapret ships it under fake/) is mandatory.
const defaultQUICFake = "quic_initial_www_google_com.bin"

// DefaultStrategy is the modern nfqws/winws desync set: fake, split2,
// disorder2 and multisplit with autottl, applied to TCP 80/443 and UDP
// 443 (TLS and QUIC), with a shipped QUIC Initial as the QUIC fake.
// It runs on the nfqws backend; since the executor landed it is the
// built-in strategy applyZapretWithVPN applies when the client sends
// none (see NFQWS-MIGRATION.md).
func DefaultStrategy() engine.BypassStrategy {
	return engine.BypassStrategy{
		Desync:    []string{"fake", "split2", "disorder2", "multisplit"},
		AutoTTL:   true,
		FilterTCP: "80,443",
		FilterUDP: "443",
		FilterL7:  "tls,quic",
		FakeQUIC:  defaultQUICFake,
	}
}

// NFQWSArgs returns the nfqws (winws on Windows) arguments for a
// strategy. home is the zapret home directory; fake payload files
// resolve under its fake/ subdirectory. Strategies are validated
// before this runs (engine.BypassStrategy validation), so names here
// are already known-good.
func NFQWSArgs(s engine.BypassStrategy, home string) []string {
	var args []string
	if len(s.Desync) > 0 {
		args = append(args, "--dpi-desync="+strings.Join(s.Desync, ","))
	}
	if len(s.SplitPos) > 0 {
		args = append(args, "--dpi-desync-split-pos="+strings.Join(s.SplitPos, ","))
	}
	if s.Fooling != "" {
		args = append(args, "--dpi-desync-fooling="+s.Fooling)
	}
	switch {
	case s.AutoTTL && s.AutoTTLDelta > 0:
		// The vendored nfqws accepts --dpi-desync-autottl=<delta>[:<min>[-<max>]]:
		// delta is the FakeTTL safety margin (the fake dies delta hops
		// before the server), and the clamp window is FakeTTL's own
		// usable range, so the calibrated and the fixed-TTL paths can
		// never disagree about what a survivable fake TTL is.
		args = append(args, fmt.Sprintf("--dpi-desync-autottl=%d:%d-%d", s.AutoTTLDelta, minFakeTTL, maxFakeTTL))
	case s.AutoTTL:
		args = append(args, "--dpi-desync-autottl")
	case s.TTL > 0:
		args = append(args, "--dpi-desync-ttl="+strconv.Itoa(s.TTL))
	}
	if s.Repeats > 1 {
		args = append(args, "--dpi-desync-repeats="+strconv.Itoa(s.Repeats))
	}
	// "tls" keeps zapret's built-in ClientHello; anything else is a
	// shipped fake file.
	if s.FakeTLS != "" && s.FakeTLS != "tls" {
		args = append(args, "--dpi-desync-fake-tls="+filepath.Join(home, "fake", s.FakeTLS))
	}
	if s.FakeQUIC != "" {
		name := s.FakeQUIC
		if name == "quic" {
			name = defaultQUICFake
		}
		args = append(args, "--dpi-desync-fake-quic="+filepath.Join(home, "fake", name))
	}
	if s.FilterTCP != "" {
		args = append(args, "--filter-tcp="+s.FilterTCP)
	}
	if s.FilterUDP != "" {
		args = append(args, "--filter-udp="+s.FilterUDP)
	}
	if s.FilterL7 != "" {
		args = append(args, "--filter-l7="+s.FilterL7)
	}
	return args
}

// Has reports whether a plan carries a bypass outbound.
func Has(p *engine.Plan) bool {
	return p != nil && slices.ContainsFunc(p.Outbounds, func(o engine.Outbound) bool { return o.Protocol == engine.ProtocolBypass })
}

// Args returns listener and strategy arguments for tpws. Plans cannot set file,
// user, or daemon options.
func Args(s engine.BypassStrategy, port int) []string {
	args := []string{"--socks", "--bind-addr=127.0.0.1", "--port=" + strconv.Itoa(port)}
	if len(s.SplitPos) > 0 {
		args = append(args, "--split-pos="+strings.Join(s.SplitPos, ","))
	}
	if s.SplitAnyProtocol {
		args = append(args, "--split-any-protocol")
	}
	switch {
	case s.Disorder && s.DisorderScope != "":
		args = append(args, "--disorder="+s.DisorderScope)
	case s.Disorder:
		args = append(args, "--disorder")
	}
	switch {
	case s.OOB && s.OOBScope != "":
		args = append(args, "--oob="+s.OOBScope)
	case s.OOB:
		args = append(args, "--oob")
	}
	if s.TLSRecord != "" {
		args = append(args, "--tlsrec="+s.TLSRecord)
	}
	if s.HostCase {
		args = append(args, "--hostcase")
	}
	if s.DomainCase {
		args = append(args, "--domcase")
	}
	if s.MethodEOL {
		args = append(args, "--methodeol")
	}
	if s.HostDot {
		args = append(args, "--hostdot")
	}
	if s.HostTab {
		args = append(args, "--hosttab")
	}
	if s.HostNoSpace {
		args = append(args, "--hostnospace")
	}
	if s.MethodSpace {
		args = append(args, "--methodspace")
	}
	if s.UnixEOL {
		args = append(args, "--unixeol")
	}
	if s.TamperStart != "" {
		args = append(args, "--tamper-start="+s.TamperStart)
	}
	if s.TamperCutoff != "" {
		args = append(args, "--tamper-cutoff="+s.TamperCutoff)
	}
	if s.OOBData != "" {
		args = append(args, "--oob-data="+s.OOBData)
	}
	if s.MSS != "" {
		args = append(args, "--mss="+s.MSS)
	}
	return args
}

// key identifies a strategy so matching outbounds share one tpws process.
func key(s engine.BypassStrategy) string { return strings.Join(Args(s, 0), " ") }

// Rewrite prepares a plan for an engine. tpws-bound outbounds become
// SOCKS5 proxies to the strategy's tpws (ports maps strategy keys;
// absent keys use port 1 for validation without a running proxy).
// nfqws-bound outbounds become direct: nfqws works at the packet
// layer, so the engine must route them untouched while the queue
// rules desync them below it (NFQWS-MIGRATION.md §4).
func Rewrite(p *engine.Plan, ports map[string]int) *engine.Plan {
	out := *p
	out.Outbounds = slices.Clone(p.Outbounds)
	for i, o := range out.Outbounds {
		if o.Protocol != engine.ProtocolBypass || o.Bypass == nil {
			continue
		}
		if BackendOf(*o.Bypass) == BackendNFQWS {
			out.Outbounds[i] = engine.Outbound{ID: o.ID, Name: o.Name, Protocol: engine.ProtocolDirect}
			continue
		}
		port := ports[key(*o.Bypass)]
		if port == 0 {
			port = 1
		}
		out.Outbounds[i] = engine.Outbound{ID: o.ID, Name: o.Name, Protocol: engine.ProtocolSOCKS5,
			Server: "127.0.0.1", Port: uint16(port)} //nolint:gosec // a loopback port from FreePort
	}
	return &out
}

// Binaries names the zapret executables the wrapper may run, as
// discovered (and digest-verified) by the registry. An empty path
// means that backend is not installed; plans needing it fail closed.
type Binaries struct {
	// TPWS is zapret's transparent SOCKS proxy (tpws).
	TPWS string
	// NFQWS is zapret's packet filter: nfqws on Linux, winws.exe on
	// Windows.
	NFQWS string
	// Assets is the shipped zapret directory holding the fake/
	// payload files (engines/zapret). Empty: resolve payloads under
	// the runtime zapret home instead.
	Assets string
}

// Engine runs an engine with the zapret processes its plan needs:
// tpws proxies for legacy strategies, nfqws filters for desync ones.
type Engine struct {
	engine.Engine
	tpws   string
	nfqws  string
	home   string
	assets string
	logs   *logs.Center

	mu      sync.Mutex
	procs   map[string]*proxy
	filters map[string]*filter
	alloc   *QueueAllocator

	iceptOnce sync.Once
	icept     interceptor
	iceptErr  error
	sweepOnce sync.Once
	// iceptOverride replaces the platform interceptor in tests.
	iceptOverride interceptor

	// capsMu guards the capability snapshot cache (capability.go).
	capsMu sync.Mutex
	caps   *Capabilities
	// capsOverride pins the capability snapshot in tests.
	capsOverride *Capabilities
	// tableLive records that this Engine installed the nft table, so
	// teardown sweeps it even if every filter was already removed by
	// a later Apply (a leaked table steers traffic into dead queues:
	// a fail-open defect, see capability.go).
	tableLive bool
	// swept records the startup sweep ran (nfqws.go), so teardown
	// knows a stale table from a previous process was already handled.
	swept bool
}

type proxy struct {
	port   int
	proc   *supervise.Process
	cancel context.CancelFunc
}

// Wrap adds bypass outbounds to an engine. bins names the discovered
// zapret binaries; home is the runtime zapret working directory.
func Wrap(inner engine.Engine, bins Binaries, home string, center *logs.Center) *Engine {
	return &Engine{Engine: inner, tpws: bins.TPWS, nfqws: bins.NFQWS, home: home, assets: bins.Assets,
		logs: center, procs: map[string]*proxy{}, filters: map[string]*filter{}, alloc: &QueueAllocator{}}
}

// Validate checks the plan the engine will run.
func (e *Engine) Validate(ctx context.Context, p *engine.Plan) error {
	return e.Engine.Validate(ctx, Rewrite(p, nil))
}

// Apply starts the zapret processes of the plan (tpws proxies and
// nfqws filters), stops the ones it no longer needs, and applies the
// rewritten plan to the engine. A plan may mix both backends. Any
// piece the nfqws backend needs but the host lacks fails the whole
// Apply closed, before any state changes: silently running a desync
// strategy without interception would pretend to desync (e.g. QUIC)
// while doing nothing.
func (e *Engine) Apply(ctx context.Context, p *engine.Plan) error {
	needed := map[string]engine.BypassStrategy{}
	neededNFQWS := map[string]engine.BypassStrategy{}
	nfqIDs := map[string]string{}
	tpwsIDs := map[string]string{}
	for _, o := range p.Outbounds {
		if o.Protocol == engine.ProtocolBypass && o.Bypass != nil {
			if BackendOf(*o.Bypass) == BackendNFQWS {
				k := e.nfqKey(*o.Bypass)
				neededNFQWS[k] = *o.Bypass
				nfqIDs[k] = o.ID
			} else {
				k := key(*o.Bypass)
				needed[k] = *o.Bypass
				tpwsIDs[k] = o.ID
			}
		}
	}
	// Capability gate first, before any state changes: the probed
	// host capabilities (capability.go) decide as data whether each
	// backend can run here; a missing capability is an honest,
	// named refusal — never a silent skip of the obfuscation.
	if err := e.gateStrategies(ctx, needed, neededNFQWS, tpwsIDs, nfqIDs); err != nil {
		return err
	}
	if len(neededNFQWS) > 0 {
		if err := e.checkNFQWS(neededNFQWS, nfqIDs); err != nil {
			return err
		}
	}
	if err := e.syncFilters(ctx, neededNFQWS); err != nil {
		return err
	}
	e.mu.Lock()
	for k, px := range e.procs {
		if _, keep := needed[k]; !keep {
			px.stop()
			delete(e.procs, k)
		}
	}
	e.mu.Unlock()
	// Start missing strategies without holding the lock: starting waits up
	// to five seconds for the process to listen, and Stop must not wait
	// behind that.
	ports := map[string]int{}
	var err error
	for k, strategy := range needed {
		px := e.current(k)
		if px == nil {
			if px, err = e.start(ctx, strategy); err != nil {
				break
			}
			px = e.publish(k, px)
		}
		ports[k] = px.port
	}
	if err != nil {
		return err
	}
	return e.Engine.Apply(ctx, Rewrite(p, ports))
}

// current returns the running proxy for k, if any.
func (e *Engine) current(k string) *proxy {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.procs[k]
}

// publish installs a freshly started proxy, or drops it in favour of one a
// concurrent Apply installed first.
func (e *Engine) publish(k string, px *proxy) *proxy {
	e.mu.Lock()
	defer e.mu.Unlock()
	if cur, ok := e.procs[k]; ok {
		px.stop()
		return cur
	}
	e.procs[k] = px
	return px
}

// start supervises one tpws process, restarting it on the same port with
// increasing delays so engine outbounds remain valid.
func (e *Engine) start(ctx context.Context, strategy engine.BypassStrategy) (*proxy, error) {
	port, err := supervise.FreePort()
	if err != nil {
		return nil, err
	}
	// The process lives on its own context, stopped by px.stop; the wait
	// below honors the caller's context so a cancelled Apply does not sit
	// out the full listening timeout.
	pctx, cancel := context.WithCancel(context.Background())
	px := &proxy{port: port, cancel: cancel}
	spec := supervise.Spec{Name: "tpws", Path: e.tpws, Args: Args(strategy, port), Dir: e.home, Lines: e.logLine}
	if px.proc, err = supervise.Start(pctx, spec); err != nil {
		cancel()
		return nil, err
	}
	if err := waitListening(ctx, px.proc, port); err != nil {
		px.stop()
		return nil, err
	}
	go e.keep(pctx, px, spec)
	return px, nil
}

func (e *Engine) keep(ctx context.Context, px *proxy, spec supervise.Spec) {
	backoff := engine.DefaultBackoff()
	for attempt := 0; ; attempt++ {
		e.mu.Lock()
		proc := px.proc
		e.mu.Unlock()
		if err := proc.Wait(ctx); ctx.Err() != nil {
			return
		} else if e.logs != nil {
			e.logs.Write(time.Time{}, logs.LevelWarning, Source, e.mask(fmt.Sprintf("tpws stopped (%v); starting it again", err)))
		}
		if backoff.Wait(ctx, attempt) != nil {
			return
		}
		next, err := supervise.Start(ctx, spec)
		if err != nil {
			continue
		}
		e.mu.Lock()
		px.proc = next
		e.mu.Unlock()
	}
}

func (px *proxy) stop() {
	px.cancel()
	_ = px.proc.Stop(context.Background(), time.Second)
}

// mask redacts one bypass-process output line before it reaches the
// log center. tpws/nfqws output names the hosts and SNI values it is
// desyncing — the exact destinations the core must not persist — and
// this path previously wrote it raw, bypassing every redactor the
// engine path uses (CENSOR-LEAK). The inner engine's redactor knows
// the plan's seeds and identifiers; when the inner engine exposes
// none, a pattern-only redactor still applies the generic patterns.
func (e *Engine) mask(line string) string {
	if r, ok := e.Engine.(interface{ Redactor() *engine.Redactor }); ok && r.Redactor() != nil {
		return r.Redactor().String(line)
	}
	return engine.NewRedactor().String(line)
}

func (e *Engine) logLine(line string) {
	if e.logs != nil {
		e.logs.Write(time.Time{}, logs.LevelInfo, Source, e.mask(line))
	}
}

// Stop stops the engine and every zapret process (tpws and nfqws).
func (e *Engine) Stop(ctx context.Context) error {
	err := e.Engine.Stop(ctx)
	e.stopAll()
	return err
}

// Close closes the engine and stops every zapret process.
func (e *Engine) Close() error {
	err := e.Engine.Close()
	e.stopAll()
	return err
}

func (e *Engine) stopAll() {
	e.stopFilters(context.Background())
	e.mu.Lock()
	defer e.mu.Unlock()
	for k, px := range e.procs {
		px.stop()
		delete(e.procs, k)
	}
}

var dialer net.Dialer

func waitListening(ctx context.Context, proc *supervise.Process, port int) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	addr := "127.0.0.1:" + strconv.Itoa(port)
	for {
		if conn, err := (&dialer).DialContext(ctx, "tcp", addr); err == nil {
			return conn.Close()
		}
		if err := proc.Err(); err != nil {
			return err
		}
		select {
		case <-ctx.Done():
			return errors.New("bypass: tpws did not start listening")
		case <-time.After(20 * time.Millisecond):
		}
	}
}
