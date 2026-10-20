// Package registry knows every engine Sora can drive, finds the builds this
// machine has, picks one per plan by capability and measures servers through
// the engine that carries them.
package registry

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
	"github.com/levvs-one/sora-client/core/engine/mihomo"
	"github.com/levvs-one/sora-client/core/engine/singbox"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/engine/xraytun"
	"github.com/levvs-one/sora-client/core/errs"
)

// mihomoBridgeMinVersion is the oldest mihomo the Xray TUN bridge accepts.
// The bridge pairs Xray routing with mihomo's packet path; keep this in
// sync with the shipped mihomo build (packaging/engines/engines.lock).
var mihomoBridgeMinVersion = engine.Version{Raw: "1.19.32", Major: 1, Minor: 19, Patch: 32}

// measureFunc times a real request through every outbound with one engine.
type measureFunc func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions, out chan<- engine.Measurement) error

// driver ties an engine kind to its prober, its constructor and its way of
// measuring many servers.
type driver struct {
	prober  supervise.Prober
	build   func(supervise.Config) (engine.Engine, error)
	measure measureFunc
}

var drivers = map[engine.Kind]driver{}

func init() {
	buildSingBox := func(c supervise.Config) (engine.Engine, error) { return singbox.New(c) }
	buildMihomo := func(c supervise.Config) (engine.Engine, error) { return mihomo.New(c) }
	drivers[engine.KindSingBox] = driver{singbox.Prober, buildSingBox, measureThroughController(buildSingBox)}
	drivers[engine.KindMihomo] = driver{mihomo.Prober, buildMihomo, measureThroughController(buildMihomo)}
	drivers[engine.KindXray] = driver{xray.Prober, func(c supervise.Config) (engine.Engine, error) { return xray.New(c) }, xray.Measure}
}

// Registry is the result of one discovery.
type Registry struct {
	binaries     map[engine.Kind]supervise.Binary
	availability []engine.Availability
	// preference is the default engine order; the service may narrow it to
	// one pinned engine, and a plan may bring its own order.
	preference []engine.Kind
	// base is the configuration every engine instance starts from.
	base supervise.Config
	// tpws is zapret's proxy for bypass outbounds; empty when not
	// installed.
	tpws string
	// nfqws is zapret's packet filter for desync bypass outbounds;
	// empty when not installed. zapretAssets is the shipped zapret
	// directory holding its fake/ payloads.
	nfqws        string
	zapretAssets string

	mu   sync.Mutex
	last engine.Selection

	// hostAt is when the HostFacts stamped into availability were
	// last measured; Availability re-probes past hostFactsTTL.
	hostMu sync.Mutex
	hostAt time.Time
}

// hostFactsTTL bounds how long discovery's host facts (TUN device,
// kernel WireGuard) are trusted. The probe itself is two cheap
// syscalls (an open of /dev/net/tun, one generic-netlink query —
// supervise.ProbeHost), while full discovery SHA-256-verifies and
// executes every engine binary, so the binaries stay discovered
// once per process (see lazyEngines in sora-core) but the host
// facts do not: the core is a long-lived service and the host
// changes under it — a TUN node appears when its module loads, a
// container's devices are attached after start. Thirty seconds
// keeps selection honest about the current host without probing
// on every call (CENSOR-P4 fix M4).
const hostFactsTTL = 30 * time.Second

// Discover searches environment overrides (only with an explicit operator
// opt-in), then the digest-verified engines directory, for each engine.
// Missing builds are recorded without failing discovery. Instances inherit
// base and use separate directories under base.HomeDir. PATH is never
// consulted: a planted binary must not become the VPN engine (SORA-H5).
func Discover(ctx context.Context, enginesDir string, base supervise.Config) *Registry {
	r := &Registry{binaries: map[engine.Kind]supervise.Binary{}, preference: engine.DefaultPreference, base: base}
	if enginesDir != "" {
		candidate := filepath.Join(enginesDir, "tpws")
		if info, err := os.Stat(candidate); err == nil && info.Mode().IsRegular() && info.Mode().Perm()&0o111 != 0 { //nolint:gosec // the engines directory is set by the service, not by a client
			// SORA-H5 covers zapret's helper too: a tpws that cannot be
			// verified against engines.digests is not used. The bypass is
			// then honestly unavailable (BypassAvailable reports it).
			if verr := supervise.VerifyNamedInDir(enginesDir, "tpws"); verr == nil {
				r.tpws = candidate
			}
		}
		// nfqws (winws.exe on Windows) gets exactly the tpws treatment:
		// same executable-bit and digest gates — an unverifiable
		// packet filter must never run with the core's privileges.
		nfqwsName := "nfqws"
		if runtime.GOOS == "windows" {
			nfqwsName = "winws.exe"
		}
		candidate = filepath.Join(enginesDir, nfqwsName)
		if info, err := os.Stat(candidate); err == nil && info.Mode().IsRegular() && info.Mode().Perm()&0o111 != 0 { //nolint:gosec // the engines directory is set by the service, not by a client
			if verr := supervise.VerifyNamedInDir(enginesDir, nfqwsName); verr == nil {
				r.nfqws = candidate
			}
		}
		// The shipped fake payloads live next to the binaries; the
		// nfqws executor resolves strategy fake names under it.
		r.zapretAssets = filepath.Join(enginesDir, "zapret")
	}
	discovery := supervise.DiscoveryOptions{AllowEnvBin: base.AllowEnvBin}
	// Probe the host (TUN device, kernel WireGuard): the facts
	// are the same for every engine and selection gates on them, so
	// they are stamped onto every Availability entry — measured here,
	// never assumed from the pins (CENSOR-P4) — and re-measured on
	// the hostFactsTTL cadence by Availability (CENSOR-P4 fix M4).
	host := supervise.ProbeHost()
	r.hostAt = time.Now()
	for _, kind := range engine.DefaultPreference {
		b, err := drivers[kind].prober.Discover(ctx, enginesDir, discovery)
		if err != nil {
			// Probe errors contain local paths; expose them only
			// through sora-core -check, not diagnostics.
			r.availability = append(r.availability, engine.Availability{Kind: kind, Reason: "not installed",
				HostProbed: host.Probed, TUNDevice: host.TUNDevice, KernelWireGuard: host.KernelWireGuard})
			continue
		}
		r.binaries[kind] = b
		r.availability = append(r.availability, engine.Availability{Kind: kind, Path: b.Path, Version: b.Version, BuildTags: b.BuildTags, Usable: true,
			HostProbed: host.Probed, TUNDevice: host.TUNDevice, KernelWireGuard: host.KernelWireGuard})
	}
	return r
}

// Availability returns discovery results for all known engines,
// with host facts no older than hostFactsTTL: past the TTL the
// cheap host probe runs again and the fresh facts are re-stamped
// onto every entry, so a host change since discovery (a TUN device
// appearing, a module loading) reaches selection without waiting
// for a core restart (CENSOR-P4 fix M4).
func (r *Registry) Availability() []engine.Availability {
	r.hostMu.Lock()
	defer r.hostMu.Unlock()
	r.refreshHostFactsLocked()
	return slices.Clone(r.availability)
}

// refreshHostFactsLocked re-probes the host when the stamped facts
// are older than hostFactsTTL. The caller holds hostMu, so the
// re-stamp and any Availability clone are one atomic step.
func (r *Registry) refreshHostFactsLocked() {
	if time.Since(r.hostAt) < hostFactsTTL {
		return
	}
	host := supervise.ProbeHost()
	r.hostAt = time.Now()
	for i := range r.availability {
		r.availability[i].HostProbed = host.Probed
		r.availability[i].TUNDevice = host.TUNDevice
		r.availability[i].KernelWireGuard = host.KernelWireGuard
	}
}

// Binaries returns the usable builds in default preference order.
func (r *Registry) Binaries() []supervise.Binary {
	var out []supervise.Binary
	for _, kind := range engine.DefaultPreference {
		if b, ok := r.binaries[kind]; ok {
			out = append(out, b)
		}
	}
	return out
}

// Usable reports whether at least one engine can be started.
func (r *Registry) Usable() bool { return len(r.binaries) > 0 }

// BypassAvailable reports whether the serverless engine can run on this platform.
func (r *Registry) BypassAvailable() bool {
	return runtime.GOOS == "linux" && r.tpws != "" && r.Usable()
}

// BypassBackends reports which zapret backends discovery found (and
// digest-verified) in the engines directory: the tpws proxy and the
// nfqws packet filter. Availability reporting names the backends
// separately because a plan may need either — or both.
func (r *Registry) BypassBackends() (tpws, nfqws bool) {
	return r.tpws != "", r.nfqws != ""
}

// LastSelection returns the latest engine choice and rejection reasons for
// diagnostics.
func (r *Registry) LastSelection() engine.Selection {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.last
}

// Pin restricts the service to one engine, overriding plan preference order.
func (r *Registry) Pin(kind engine.Kind) error {
	if kind == "" {
		return nil
	}
	if _, known := drivers[kind]; !known {
		return fmt.Errorf("registry: unknown engine %q", kind)
	}
	r.preference = []engine.Kind{kind}
	return nil
}

// order selects service pin, request order, or default order, in that priority.
func (r *Registry) order(requested []engine.Kind) ([]engine.Kind, error) {
	if len(r.preference) == 1 || len(requested) == 0 {
		return r.preference, nil
	}
	for _, kind := range requested {
		if _, known := drivers[kind]; !known {
			return nil, fmt.Errorf("registry: unknown engine %q", kind)
		}
	}
	return requested, nil
}

// Factory creates the first engine in preference order that supports the entire
// plan.
func (r *Registry) Factory() func(context.Context, *engine.Plan) (engine.Engine, error) {
	return func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
		if p == nil {
			return nil, errors.New("registry: nil plan")
		}
		order, err := r.order(p.Engines)
		if err != nil {
			return nil, err
		}
		if len(p.Engines) == 0 && p.PrivateControl {
			order = engine.PrivatePreference
		}
		withBypass := bypass.Has(p)
		// Missing installations use the missing-engine key rather than
		// an invalid-plan error. The gate is per backend: a plan whose
		// bypass outbounds are all nfqws-bound needs nfqws, not tpws,
		// and a mixed plan needs both (NFQWS-MIGRATION.md §4).
		if withBypass {
			needsTPWS, needsNFQWS := false, false
			for _, o := range p.Outbounds {
				if o.Protocol != engine.ProtocolBypass {
					continue
				}
				if o.Bypass != nil && bypass.BackendOf(*o.Bypass) == bypass.BackendNFQWS {
					needsNFQWS = true
				} else {
					needsTPWS = true
				}
			}
			if needsTPWS && r.tpws == "" {
				return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing,
					"registry: bypass outbounds need zapret's tpws in the engines directory")
			}
			if needsNFQWS && r.nfqws == "" {
				return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing,
					"registry: bypass outbounds need zapret's nfqws in the engines directory")
			}
		}
		// Select capabilities against the SOCKS5 plan produced by
		// bypass rewriting. Plans without a bypass outbound (the common
		// case) select against themselves: rewriting them only cloned
		// every outbound to produce an identical plan, and selection
		// only reads the plan. The bridge adjustment in selectPlan
		// copies on write (candidate := *p, and DNS.Servers is cloned
		// before any server is stepped down), so the caller's plan is
		// never mutated — pinned by
		// TestXrayBridgeAdjustmentNeverMutatesTheCallerPlan.
		selectPlan := p
		if withBypass {
			selectPlan = bypass.Rewrite(p, nil)
		}
		sel, bridge, err := r.selectPlan(selectPlan, order)
		r.mu.Lock()
		r.last = sel
		r.mu.Unlock()
		if err != nil {
			return nil, err
		}
		cfg := r.base
		cfg.Binary = r.binaries[sel.Kind]
		cfg.HomeDir = filepath.Join(r.base.HomeDir, string(sel.Kind))
		var built engine.Engine
		if bridge {
			tcfg := r.base
			tcfg.Binary = r.binaries[engine.KindMihomo]
			tcfg.HomeDir = filepath.Join(r.base.HomeDir, "xray-tun")
			built, err = xraytun.New(cfg, tcfg)
		} else {
			built, err = drivers[sel.Kind].build(cfg)
		}
		if err != nil || !withBypass {
			return built, err
		}
		return bypass.Wrap(built, bypass.Binaries{TPWS: r.tpws, NFQWS: r.nfqws, Assets: r.zapretAssets},
			filepath.Join(r.base.HomeDir, "zapret"), r.base.Logs), nil
	}
}

// selectPlan checks Xray's routing independently of its installed packet
// engine. Automatic selection must also carry provider-only Xray profiles.
func (r *Registry) selectPlan(p *engine.Plan, order []engine.Kind) (engine.Selection, bool, error) {
	var selection engine.Selection
	key := errs.KeyEngineBinaryMissing
	for _, kind := range order {
		candidate := *p
		bridge := kind == engine.KindXray && p.Tun.Enabled &&
			(runtime.GOOS != "linux" || slices.Contains([]string{"system", "mixed", "mips"}, p.Tun.Stack))
		if bridge {
			candidate.Tun = engine.Tun{}
			if candidate.DNS.Mode == string(engine.DNSFakeIP) {
				candidate.DNS.Mode = "rule"
			}
			// The bridge answers client DNS through the packet engine
			// (which keeps h3); Xray's own leg steps h3 resolvers down
			// to DoH (see xraytun.plans). Select against what Xray will
			// actually render, or every h3 plan would be rejected here.
			// Clone: candidate shares the plan's backing array.
			candidate.DNS.Servers = slices.Clone(candidate.DNS.Servers)
			for i, s := range candidate.DNS.Servers {
				if s.Transport == engine.DNSH3 {
					candidate.DNS.Servers[i].Transport = engine.DNSHTTPS
				}
			}
		}
		if _, installed := r.binaries[kind]; installed {
			key = errs.KeyPlanEngineUnsupported
		}
		picked, err := engine.SelectEngine(&candidate, r.Availability(), []engine.Kind{kind})
		if err != nil {
			selection.Rejected = append(selection.Rejected, picked.Rejected...)
			continue
		}
		if bridge {
			packet, installed := r.binaries[engine.KindMihomo]
			var packetErr error
			if !installed {
				packetErr = errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineBinaryMissing,
					"registry: Xray's selected TUN stack needs mihomo in the engines directory")
			} else if packet.Version.Less(mihomoBridgeMinVersion) {
				packetErr = errs.Newf(errs.CodeFailedPrecondition, errs.KeyPlanEngineUnsupported,
					"registry: Xray's selected TUN stack needs mihomo %s or newer", mihomoBridgeMinVersion)
			}
			if packetErr != nil {
				selection.Rejected = append(selection.Rejected, packetErr.Error())
				if len(order) == 1 {
					return selection, false, packetErr
				}
				continue
			}
		}
		selection.Kind, selection.Reason = picked.Kind, picked.Reason
		return selection, bridge, nil
	}
	return selection, false, errs.Newf(errs.CodeFailedPrecondition, key,
		"registry: no engine can carry this plan (%s)", strings.Join(selection.Rejected, "; "))
}

// Measure streams request timings through each outbound's first compatible
// engine. Unsupported outbounds return ErrNoEngine for TCP fallback; the
// channel closes after all results.
func (r *Registry) Measure(ctx context.Context, outbounds []engine.Outbound, opts engine.MeasureOptions) (<-chan engine.Measurement, error) {
	order, err := r.order(opts.Engines)
	if err != nil {
		return nil, err
	}
	byKind := map[engine.Kind][]engine.Outbound{}
	var orphans []engine.Outbound
	for _, o := range outbounds {
		single := &engine.Plan{Outbounds: []engine.Outbound{o}}
		sel, err := engine.SelectEngine(single, r.Availability(), order)
		if err != nil {
			orphans = append(orphans, o)
			continue
		}
		byKind[sel.Kind] = append(byKind[sel.Kind], o)
	}

	out := make(chan engine.Measurement, len(outbounds))
	var wg sync.WaitGroup
	for kind, group := range byKind {
		wg.Add(1)
		go func() {
			defer wg.Done()
			cfg := r.base
			cfg.Binary = r.binaries[kind]
			cfg.HomeDir = filepath.Join(r.base.HomeDir, "measure-"+string(kind))
			cfg.LocalPort = 0
			// Suppress measurement engine logs; results already
			// report probe outcomes.
			cfg.Logs = nil
			if err := drivers[kind].measure(ctx, cfg, group, opts, out); err != nil {
				// Startup failures must produce a result for
				// every affected server.
				for _, o := range group {
					out <- engine.Measurement{OutboundID: o.ID, Engine: kind, Err: err}
				}
			}
		}()
	}
	for _, o := range orphans {
		out <- engine.Measurement{OutboundID: o.ID, Err: engine.ErrNoEngine}
	}
	go func() {
		wg.Wait()
		close(out)
	}()
	return out, nil
}

// measureThroughController starts one temporary Clash API engine for all
// outbounds and times each through the controller.
func measureThroughController(build func(supervise.Config) (engine.Engine, error)) measureFunc {
	return func(ctx context.Context, cfg supervise.Config, outbounds []engine.Outbound, opts engine.MeasureOptions, out chan<- engine.Measurement) error {
		if opts.Concurrency <= 0 {
			opts.Concurrency = 8
		}
		if opts.Timeout <= 0 {
			opts.Timeout = 5 * time.Second
		}
		plan := &engine.Plan{
			SessionID: "measure",
			Rules:     []engine.Rule{{Type: engine.RuleMatchAll, Target: "direct"}},
			Options:   engine.Options{LogLevel: "error", TestURL: opts.URL},
		}
		// Plain unique probe names keep controller lookup consistent
		// with rendered names.
		ids := make(map[string]string, len(outbounds))
		for i, o := range outbounds {
			o.Name = fmt.Sprintf("probe-%d", i+1)
			ids[o.Name] = o.ID
			plan.Outbounds = append(plan.Outbounds, o)
		}
		eng, err := build(cfg)
		if err != nil {
			return err
		}
		defer func() { _ = eng.Close() }()
		if err := eng.Apply(ctx, plan); err != nil {
			return err
		}
		sem := make(chan struct{}, opts.Concurrency)
		var wg sync.WaitGroup
		for name, id := range ids {
			wg.Add(1)
			sem <- struct{}{}
			go func() {
				defer wg.Done()
				defer func() { <-sem }()
				d, err := eng.Delay(ctx, name, opts.URL, opts.Timeout)
				out <- engine.Measurement{OutboundID: id, Engine: eng.Kind(), Latency: d, Err: err}
			}()
		}
		wg.Wait()
		return nil
	}
}
