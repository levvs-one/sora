// Package xray runs Xray-core with stdin configuration ("run -c stdin:") for
// XHTTP, VLESS Encryption, and REALITY. Counters and automatic-group latency
// use loopback /debug/vars. Selectors require routing changes and restarts;
// Delay times a request through a temporary SOCKS-enabled Xray.
package xray

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"maps"
	"net"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"slices"
	"strconv"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/tunroute"
)

// Prober recognizes "xray version" output such as "Xray 26.3.27" with build and
// platform details.
var Prober = supervise.Prober{
	Kind:    engine.KindXray,
	Name:    "xray",
	EnvVar:  "SORA_XRAY_BIN",
	Args:    []string{"version"},
	Pattern: regexp.MustCompile(`^Xray v?(\d+\.\d+\.\d+[0-9A-Za-z.\-]*)\s.*\(go[^ ]+ (\w+)/(\w+)\)`),
}

// Engine runs Xray under the shared supervisor.
type Engine struct {
	*supervise.Supervisor
	cfg    supervise.Config
	driver *driver

	mu       sync.Mutex
	counters engine.Counters
}

// New creates an Xray engine without starting it. Apply starts it.
func New(cfg supervise.Config) (*Engine, error) {
	d := &driver{sel: Selection{}}
	sup, err := supervise.New(cfg, d)
	if err != nil {
		return nil, err
	}
	return &Engine{Supervisor: sup, cfg: cfg, driver: d}, nil
}

type driver struct {
	mu  sync.Mutex
	sel Selection
	fp  map[string]string // outbound ID -> probe-discovered working uTLS fingerprint
}

func (*driver) Kind() engine.Kind { return engine.KindXray }

// Route directs machine traffic through Xray's adapter, keeping the core
// account's traffic on the main table.
func (*driver) Route(ctx context.Context, p *engine.Plan) error {
	return tunroute.Route(ctx, p.Tun, os.Getuid())
}

func (*driver) Unroute(ctx context.Context) error { return tunroute.Unroute(ctx) }

func (d *driver) Render(p *engine.Plan, rt supervise.Runtime) ([]byte, error) {
	return render(p, rt, d.selection(), d.fingerprintHints())
}

// noteFingerprint remembers a uTLS fingerprint that probing proved working
// for an outbound; the next render uses it instead of the default.
func (d *driver) noteFingerprint(id, fp string) {
	if id == "" || fp == "" {
		return
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.fp == nil {
		d.fp = make(map[string]string)
	}
	d.fp[id] = fp
}

func (d *driver) fingerprintHints() map[string]string {
	d.mu.Lock()
	defer d.mu.Unlock()
	return maps.Clone(d.fp)
}

func (d *driver) selection() Selection {
	d.mu.Lock()
	defer d.mu.Unlock()
	return maps.Clone(d.sel)
}

func (*driver) RunArgs(supervise.Runtime) []string   { return []string{"run", "-c", "stdin:"} }
func (*driver) CheckArgs(supervise.Runtime) []string { return []string{"run", "-test", "-c", "stdin:"} }

// ControlAddress disables TCP-only Xray 26.3 metrics for private plans to avoid
// network discovery. Balancers and observatory still work internally, but
// traffic counters are unavailable.
func (*driver) ControlAddress(rt supervise.Runtime, private bool) (string, error) {
	if private {
		return "", nil
	}
	return rt.ControlAddr, nil
}

// Handshake waits for metrics and retains the probed version. Without metrics,
// readiness uses the local proxy or the session's TUN adapter check.
func (*driver) Handshake(ctx context.Context, rt supervise.Runtime) (string, error) {
	// Private TUN plans have no listener to prove startup. Routing must wait
	// for Xray to create the adapter rather than racing its process launch.
	if rt.TunDevice != "" {
		if _, err := net.InterfaceByName(rt.TunDevice); err != nil {
			return "", fmt.Errorf("xray: the TUN adapter is not ready yet: %w", err)
		}
	}
	if rt.ControlAddr == "" {
		if !rt.LocalProxy {
			return "", nil
		}
		conn, err := (&net.Dialer{}).DialContext(ctx, "tcp", net.JoinHostPort("127.0.0.1", strconv.Itoa(rt.LocalPort)))
		if err != nil {
			return "", fmt.Errorf("xray: the local proxy is not listening yet: %w", err)
		}
		return "", conn.Close()
	}
	_, err := readVars(ctx, rt.ControlAddr)
	return "", err
}

func (*driver) Reload(context.Context, supervise.Runtime, []byte) error {
	return supervise.ErrReloadUnsupported
}

// vars is the part of /debug/vars Sora reads.
type vars struct {
	Stats struct {
		Inbound  map[string]traffic `json:"inbound"`
		Outbound map[string]traffic `json:"outbound"`
	} `json:"stats"`
	Observatory map[string]struct {
		Alive bool `json:"alive"`
		Delay int  `json:"delay"`
	} `json:"observatory"`
	Memstats struct {
		Alloc uint64 `json:"Alloc"`
	} `json:"memstats"`
}

type traffic struct {
	Uplink   uint64 `json:"uplink"`
	Downlink uint64 `json:"downlink"`
}

// metricsClient talks to the loopback metrics endpoint directly: it must
// never honor HTTP_PROXY from the environment, or internal stats would be
// sent to a proxy (SORA-L10).
var metricsClient = &http.Client{Transport: directTransport()}

// directTransport clones the default transport without its ProxyFromEnvironment.
func directTransport() http.RoundTripper {
	if t, ok := http.DefaultTransport.(*http.Transport); ok {
		direct := t.Clone()
		direct.Proxy = nil
		return direct
	}
	return &http.Transport{}
}

func readVars(ctx context.Context, addr string) (vars, error) {
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+addr+"/debug/vars", nil)
	if err != nil {
		return vars{}, err
	}
	resp, err := metricsClient.Do(req)
	if err != nil {
		return vars{}, fmt.Errorf("xray: metrics are not reachable: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()
	if resp.StatusCode != http.StatusOK {
		return vars{}, fmt.Errorf("xray: metrics answered %d", resp.StatusCode)
	}
	var v vars
	if err := json.NewDecoder(io.LimitReader(resp.Body, 8<<20)).Decode(&v); err != nil {
		return vars{}, fmt.Errorf("xray: decode metrics: %w", err)
	}
	return v, nil
}

// Counters returns mixed-inbound application traffic. Metrics errors include
// the last known totals to avoid resetting charts.
func (e *Engine) Counters(ctx context.Context) (engine.Counters, error) {
	rt, err := e.Running()
	if err != nil {
		return engine.Counters{}, err
	}
	if rt.ControlAddr == "" {
		return engine.Counters{At: time.Now()}, nil
	}
	v, verr := readVars(ctx, rt.ControlAddr)
	e.mu.Lock()
	defer e.mu.Unlock()
	if verr != nil {
		return e.counters, e.Redactor().Err(verr)
	}
	in := v.Stats.Inbound[tagInbound]
	e.counters = engine.Counters{BytesUp: in.Uplink, BytesDown: in.Downlink, MemoryBytes: v.Memstats.Alloc, At: time.Now()}
	return e.counters, nil
}

// Groups reports selected members and the fastest live members of automatic
// groups.
func (e *Engine) Groups(ctx context.Context) ([]engine.GroupStatus, error) {
	rt, err := e.Running()
	if err != nil {
		return nil, err
	}
	p := e.Plan()
	if p == nil {
		return nil, supervise.ErrNotRunning
	}
	var v vars
	if rt.ControlAddr != "" {
		if v, err = readVars(ctx, rt.ControlAddr); err != nil {
			return nil, e.Redactor().Err(err)
		}
	}
	names, tags := map[string]string{}, map[string]string{}
	for i, o := range p.Outbounds {
		names[o.ID] = displayName(o)
		tags[o.ID] = outboundTag(i)
	}
	sel := e.driver.selection()
	out := make([]engine.GroupStatus, 0, len(p.Groups))
	for _, g := range p.Groups {
		status := engine.GroupStatus{Name: g.Name, Type: g.Type, Hidden: g.Hidden, Icon: g.Icon,
			TestURL: g.URL, LatencyMS: map[string]int{}, UpdatedAt: time.Now()}
		best := -1
		for _, id := range g.Outbounds {
			name := orDefault(names[id], id)
			status.All = append(status.All, name)
			if probe, ok := v.Observatory[tags[id]]; ok && probe.Alive {
				status.LatencyMS[name] = probe.Delay
				if best < 0 || probe.Delay < best {
					best, status.Selected = probe.Delay, name
				}
			}
		}
		if g.Type == engine.GroupSelect && len(g.Outbounds) > 0 {
			pinned := g.Outbounds[0]
			if s, ok := sel[g.Name]; ok {
				pinned = s
			}
			status.Selected = orDefault(names[pinned], pinned)
		}
		out = append(out, status)
	}
	return out, nil
}

// Select pins a member by plan ID or display name and restarts Xray with
// updated routing.
func (e *Engine) Select(ctx context.Context, group, target string) error {
	p := e.Plan()
	if p == nil {
		return supervise.ErrNotRunning
	}
	member, err := resolveMember(p, group, target)
	if err != nil {
		return err
	}
	e.driver.mu.Lock()
	previous, had := e.driver.sel[group]
	e.driver.sel[group] = member
	e.driver.mu.Unlock()
	if err := e.Apply(ctx, p); err != nil {
		e.driver.mu.Lock()
		if had {
			e.driver.sel[group] = previous
		} else {
			delete(e.driver.sel, group)
		}
		e.driver.mu.Unlock()
		return err
	}
	e.Events().Publish(engine.Event{Kind: engine.EventGroup, Group: &engine.GroupStatus{Name: group, Selected: target}})
	return nil
}

// seedPlanSelection fills the selection map from the plan's select
// groups (Group.Selected), so a fresh start routes through the member
// the plan names instead of always the first one. Groups that already
// have a selection keep it: Select stores the user's runtime choice in
// the same map before re-applying the plan, and a reconnect re-applies
// the plan without wanting to undo that choice. A fresh engine (one per
// session) starts with an empty map, so seeding is what makes the
// plan's Selected effective at Connect.
func (d *driver) seedPlanSelection(p *engine.Plan) {
	if p == nil {
		return
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.sel == nil {
		d.sel = Selection{}
	}
	for _, g := range p.Groups {
		if g.Type != engine.GroupSelect || g.Selected == "" {
			continue
		}
		if _, ok := d.sel[g.Name]; ok {
			continue
		}
		if slices.Contains(g.Outbounds, g.Selected) {
			d.sel[g.Name] = g.Selected
		}
	}
}

// Apply warns about VLESS+REALITY outbounds without a vision flow, then
// starts the engine as usual. The warning is journal-only: without vision
// the inner TLS runs inside the outer REALITY TLS (TLS-in-TLS), a
// detectable signal, but the connection itself still works.
func (e *Engine) Apply(ctx context.Context, p *engine.Plan) error {
	e.warnRealityWithoutVision(p)
	e.driver.seedPlanSelection(p)
	return e.Supervisor.Apply(ctx, p)
}

// warnRealityWithoutVision publishes one journal warning per VLESS+REALITY
// outbound that lacks a vision flow.
func (e *Engine) warnRealityWithoutVision(p *engine.Plan) {
	if p == nil {
		return
	}
	for i := range p.Outbounds {
		o := &p.Outbounds[i]
		if !realityWithoutVision(*o) {
			continue
		}
		e.Events().Publish(engine.Event{Kind: engine.EventLog, Message: fmt.Sprintf(
			"xray: outbound %q uses VLESS+REALITY without a vision flow (TLS-in-TLS is detectable); set flow xtls-rprx-vision",
			displayName(*o))})
	}
}

func resolveMember(p *engine.Plan, group, target string) (string, error) {
	for _, g := range p.Groups {
		if g.Name != group {
			continue
		}
		if g.Type != engine.GroupSelect {
			return "", fmt.Errorf("xray: group %q is not a select group", group)
		}
		for _, id := range g.Outbounds {
			if id == target {
				return id, nil
			}
			if o, ok := p.OutboundByID(id); ok && displayName(o) == target {
				return id, nil
			}
		}
		return "", fmt.Errorf("xray: %q is not a member of group %q", target, group)
	}
	return "", fmt.Errorf("xray: no group %q", group)
}

func displayName(o engine.Outbound) string { return orDefault(o.Name, o.ID) }

// Delay times a real request through a temporary Xray containing only the
// measured outbound, leaving session routing unchanged.
func (e *Engine) Delay(ctx context.Context, name, testURL string, timeout time.Duration) (time.Duration, error) {
	p := e.Plan()
	if p == nil {
		return 0, supervise.ErrNotRunning
	}
	var target *engine.Outbound
	for i := range p.Outbounds {
		if p.Outbounds[i].ID == name || displayName(p.Outbounds[i]) == name {
			target = &p.Outbounds[i]
			break
		}
	}
	if target == nil {
		return 0, fmt.Errorf("xray: no outbound %q", name)
	}
	results := make(chan engine.Measurement, 1)
	opts := engine.MeasureOptions{URL: orDefault(testURL, e.ProbeURL()), Timeout: timeout, Concurrency: 1}
	hints, err := measure(ctx, e.cfg, []engine.Outbound{*target}, opts, results, runProbe)
	if err != nil {
		return 0, e.Redactor().Err(err)
	}
	m := <-results
	if m.Err == nil {
		// A probe that only passed with a rotated fingerprint leaves its
		// working fingerprint for the session renderer.
		if fp, ok := hints[target.ID]; ok {
			e.driver.noteFingerprint(target.ID, fp)
		}
	}
	return m.Latency, e.Redactor().Err(m.Err)
}

// probeBatch bounds the inbounds of one measuring process.
const probeBatch = 128

// probeResult is one outbound's timing through a temporary Xray.
type probeResult struct {
	latency time.Duration
	err     error
}

// probeFunc runs one batch of outbounds through a temporary Xray,
// returning one result per outbound in batch order. It is a parameter so
// tests can simulate timeouts without network access.
type probeFunc func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions) ([]probeResult, error)

// Measure streams one timing per outbound in batches. Each temporary Xray
// process exposes one SOCKS inbound per outbound.
func Measure(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions, out chan<- engine.Measurement) error {
	if opts.URL == "" {
		opts.URL = engine.TestURLProduction
	}
	if opts.Timeout <= 0 {
		opts.Timeout = 5 * time.Second
	}
	if opts.Concurrency <= 0 {
		opts.Concurrency = 8
	}
	if cfg.StartTimeout <= 0 {
		cfg.StartTimeout = 10 * time.Second
	}
	_, err := measure(ctx, cfg, outbounds, opts, out, runProbe)
	return err
}

// measure probes outbounds in batches and returns the uTLS fingerprints
// that only worked after rotation, keyed by outbound ID. Probes that pass
// with the default fingerprint leave no entry.
func measure(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions, out chan<- engine.Measurement, run probeFunc) (map[string]string, error) {
	hints := make(map[string]string)
	for start := 0; start < len(outbounds); start += probeBatch {
		batch := outbounds[start:min(start+probeBatch, len(outbounds))]
		if err := measureAttempts(ctx, cfg, batch, opts, out, run, 0, hints); err != nil {
			return nil, err
		}
	}
	return hints, nil
}

// measureAttempts probes one batch, retrying timed-out REALITY outbounds
// with the next uTLS fingerprint instead of marking them dead. attempt
// indexes fingerprintRotation; the working fingerprint of a rotated
// success is recorded in hints for the session renderer.
func measureAttempts(ctx context.Context, cfg supervise.Config, batch []engine.Outbound, opts engine.MeasureOptions, out chan<- engine.Measurement, run probeFunc, attempt int, hints map[string]string) error {
	rotated := batch
	if fp := retryFingerprint(attempt); fp != "" {
		rotated = make([]engine.Outbound, len(batch))
		for i, o := range batch {
			rotated[i] = o
			if fingerprintRotatable(o) {
				rotated[i].TLS.Fingerprint = fp
			}
		}
	}
	results, err := run(ctx, cfg, rotated, opts)
	if err != nil {
		return err
	}
	var retry []engine.Outbound
	for i := range results {
		if i >= len(batch) {
			break // defensive: run must return one result per outbound
		}
		o := batch[i]
		r := results[i]
		if r.err != nil && fingerprintRotatable(o) && isTimeout(r.err) && retryFingerprint(attempt+1) != "" {
			retry = append(retry, o)
			continue
		}
		if r.err == nil {
			if fp := retryFingerprint(attempt); fp != "" && fingerprintRotatable(o) {
				hints[o.ID] = fp
			}
		}
		out <- engine.Measurement{OutboundID: o.ID, Engine: engine.KindXray, Latency: r.latency, Err: r.err}
	}
	if len(retry) > 0 {
		return measureAttempts(ctx, cfg, retry, opts, out, run, attempt+1, hints)
	}
	return nil
}

// fingerprintRotatable reports whether probing may rotate the outbound's
// uTLS fingerprint after a timeout: REALITY always handshakes with a
// fingerprint, and an explicit plan value is the user's choice to respect.
func fingerprintRotatable(o engine.Outbound) bool {
	return o.TLS.Reality && engine.NormalizeFingerprint(o.TLS.Fingerprint) == ""
}

// retryFingerprint returns the fingerprint for probe retry attempt n: the
// initial attempt renders the default ("" lets the renderer decide), later
// attempts walk fingerprintRotation, and "" past its end stops retrying.
func retryFingerprint(attempt int) string {
	if attempt <= 0 || attempt >= len(fingerprintRotation) {
		return ""
	}
	return fingerprintRotation[attempt]
}

// isTimeout reports whether err is a timeout. A stalled TLS handshake
// surfaces here as a client-side deadline, whatever Xray logged.
func isTimeout(err error) bool {
	var uerr *url.Error
	if errors.As(err, &uerr) {
		return uerr.Timeout()
	}
	var nerr net.Error
	return errors.As(err, &nerr) && nerr.Timeout()
}

// runProbe renders one temporary Xray for batch and times each outbound
// through its loopback SOCKS inbound, returning one result per outbound in
// batch order.
func runProbe(ctx context.Context, cfg supervise.Config, batch []engine.Outbound, opts engine.MeasureOptions) ([]probeResult, error) {
	ports := make([]int, len(batch))
	for i := range ports {
		p, err := supervise.FreePort()
		if err != nil {
			return nil, err
		}
		ports[i] = p
	}
	raw, err := RenderProbe(batch, ports)
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	proc, err := supervise.Start(ctx, supervise.Spec{Name: "xray", Path: cfg.Binary.Path, Args: []string{"run", "-c", "stdin:"}, Dir: cfg.HomeDir, Config: raw})
	if err != nil {
		return nil, err
	}
	defer func() { _ = proc.Stop(context.WithoutCancel(ctx), 0) }()
	ready, cancelReady := context.WithTimeout(ctx, cfg.StartTimeout)
	defer cancelReady()
	if err := waitListening(ready, proc, ports[len(ports)-1]); err != nil {
		return nil, err
	}

	results := make([]probeResult, len(batch))
	sem := make(chan struct{}, opts.Concurrency)
	var wg sync.WaitGroup
	for i := range batch {
		wg.Add(1)
		sem <- struct{}{}
		go func() {
			defer wg.Done()
			defer func() { <-sem }()
			d, err := timeThrough(ctx, ports[i], opts)
			results[i] = probeResult{latency: d, err: err}
		}()
	}
	wg.Wait()
	return results, nil
}

// timeThrough warms the proxy tunnel and target TLS session, then times a
// second request on the same connection. Cold timings primarily measure proxy,
// REALITY/XHTTP, and TLS handshakes.
func timeThrough(ctx context.Context, port int, opts engine.MeasureOptions) (time.Duration, error) {
	proxy := &url.URL{Scheme: "socks5h", Host: "127.0.0.1:" + strconv.Itoa(port)}
	transport := &http.Transport{Proxy: http.ProxyURL(proxy), MaxIdleConnsPerHost: 1}
	defer transport.CloseIdleConnections()
	client := &http.Client{Timeout: opts.Timeout, Transport: transport}
	var timed time.Duration
	for range 2 {
		req, err := http.NewRequestWithContext(ctx, http.MethodHead, opts.URL, nil)
		if err != nil {
			return 0, err
		}
		start := time.Now()
		resp, err := client.Do(req)
		if err != nil {
			return 0, fmt.Errorf("xray: latency test failed: %w", err)
		}
		_, _ = io.Copy(io.Discard, resp.Body)
		_ = resp.Body.Close()
		if resp.StatusCode >= 500 {
			return 0, fmt.Errorf("xray: latency test answered %d", resp.StatusCode)
		}
		timed = time.Since(start)
	}
	return timed, nil
}

func waitListening(ctx context.Context, proc *supervise.Process, port int) error {
	addr := "127.0.0.1:" + strconv.Itoa(port)
	var dialer net.Dialer
	for {
		conn, err := dialer.DialContext(ctx, "tcp", addr)
		if err == nil {
			return conn.Close()
		}
		if reason := proc.Err(); reason != nil {
			return reason
		}
		select {
		case <-ctx.Done():
			return errors.Join(ctx.Err(), errors.New(proc.Output().Last(3)))
		case <-time.After(50 * time.Millisecond):
		}
	}
}
