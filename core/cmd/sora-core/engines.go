package main

import (
	"context"
	"log/slog"
	"sync"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/session"
)

// lazyEngines defers engine discovery past core startup.
//
// Discovery is the most expensive step of New: it SHA-256-verifies every
// installed engine binary against engines.digests before executing
// anything (SORA-H5) and then runs each candidate to learn its version.
// With the three shipped engines that is well over 100 MB of hashing plus
// three process spawns — on the order of a second — yet nothing needs the
// result before the first session start, measurement, benchmark, or
// status call. Discovery therefore starts during New, in the background,
// so the registry is normally warm before anyone asks, while the control
// API becomes ready without waiting for it.
//
// Every accessor blocks on the same sync.Once, so callers always observe
// the fully discovered, pinned registry — exactly what the synchronous
// discovery in New produced before. A discovery triggered concurrently
// from several goroutines runs once; the rest wait for the same result.
//
// The once-for-the-process caching is deliberate for the BINARIES:
// discovery hash-verifies and executes every engine build, far too
// expensive to repeat per session. It does NOT extend to the host
// facts discovery stamps (TUN device, kernel WireGuard): those are
// two cheap syscalls to measure, the host changes under a long-lived
// service, and the registry re-probes them on its own TTL
// (registry.hostFactsTTL, CENSOR-P4 fix M4) behind this same cached
// registry — so a device that appears after core start is seen
// without a restart, while binaries stay discovered exactly once.
type lazyEngines struct {
	once sync.Once
	reg  *registry.Registry

	ctx        context.Context
	log        *slog.Logger
	enginesDir string
	base       supervise.Config
	pin        engine.Kind
	// discover is registry.Discover in production; tests substitute a
	// counting fake.
	discover func(ctx context.Context, enginesDir string, base supervise.Config) *registry.Registry
}

// newLazyEngines validates the engine pin eagerly — an unknown kind must
// fail the core at startup, as it did when New pinned the discovered
// registry — and starts discovery in the background.
func newLazyEngines(ctx context.Context, log *slog.Logger, enginesDir string, base supervise.Config, pin engine.Kind) (*lazyEngines, error) {
	return newLazyEnginesWithDiscover(ctx, log, enginesDir, base, pin, registry.Discover)
}

func newLazyEnginesWithDiscover(ctx context.Context, log *slog.Logger, enginesDir string, base supervise.Config, pin engine.Kind, discover func(ctx context.Context, enginesDir string, base supervise.Config) *registry.Registry) (*lazyEngines, error) {
	// Pin on the zero registry consults only the static driver table, so
	// it validates the kind with no discovery. The pin is re-applied to
	// the discovered registry in get, where it cannot fail.
	if err := new(registry.Registry).Pin(pin); err != nil {
		return nil, err
	}
	l := &lazyEngines{
		ctx: ctx, log: log, enginesDir: enginesDir, base: base, pin: pin,
		discover: discover,
	}
	go l.warm()
	return l, nil
}

// warm runs discovery ahead of the first accessor call.
func (l *lazyEngines) warm() { l.get() }

// get returns the discovered registry, running discovery first if no
// accessor or the warm-up goroutine has reached it yet.
func (l *lazyEngines) get() *registry.Registry {
	l.once.Do(func() {
		reg := l.discover(l.ctx, l.enginesDir, l.base)
		if err := reg.Pin(l.pin); err != nil {
			// Unreachable: newLazyEngines validated the pin against the
			// same driver table. Logged rather than dropped so a future
			// driver-table change cannot silently lose the pin.
			l.log.Error("core: engine pin rejected after validation",
				"engine", string(l.pin), "err", err)
		}
		if !reg.Usable() {
			// Keep status, diagnostics, and import available when
			// no engine is installed.
			l.log.Warn("no engine binary found; connecting fails until one is installed",
				"engines_dir", l.enginesDir)
		}
		l.reg = reg
	})
	return l.reg
}

// Factory returns the session factory, resolving discovery on each call
// so constructing the session manager during New stays cheap.
func (l *lazyEngines) Factory() session.Factory {
	return func(ctx context.Context, plan *engine.Plan) (engine.Engine, error) {
		return l.get().Factory()(ctx, plan)
	}
}

// Availability returns discovery results for all known engines.
func (l *lazyEngines) Availability() []engine.Availability { return l.get().Availability() }

// Binaries returns the usable builds in default preference order.
func (l *lazyEngines) Binaries() []supervise.Binary { return l.get().Binaries() }

// Usable reports whether at least one engine can be started.
func (l *lazyEngines) Usable() bool { return l.get().Usable() }

// BypassAvailable reports whether the serverless engine can run on this
// platform.
func (l *lazyEngines) BypassAvailable() bool { return l.get().BypassAvailable() }

// BypassBinaries returns the digest-verified zapret binary paths
// discovery found (empty for a missing backend), for measured bypass
// capability reporting.
func (l *lazyEngines) BypassBinaries() (tpws, nfqws string) { return l.get().BypassBinaries() }

// LastSelection returns the latest engine choice and rejection reasons
// for diagnostics.
func (l *lazyEngines) LastSelection() engine.Selection { return l.get().LastSelection() }

// Measure times requests through one engine, satisfying control.Measurer.
func (l *lazyEngines) Measure(ctx context.Context, outbounds []engine.Outbound, opts engine.MeasureOptions) (<-chan engine.Measurement, error) {
	return l.get().Measure(ctx, outbounds, opts)
}
