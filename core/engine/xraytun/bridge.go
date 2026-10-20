// Package xraytun pairs Xray routing with mihomo's selectable TUN stacks.
// Both processes retain the shared supervisor's restart and cleanup ownership.
package xraytun

import (
	"context"
	"errors"
	"fmt"
	"maps"
	"path/filepath"
	"runtime"
	"slices"
	"sync"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/mihomo"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
	"github.com/levvs-one/sora-client/core/errs"
)

const bridgeID = "sora-xray-bridge"

// Engine owns a private authenticated SOCKS link and one TUN adapter. Xray
// retains provider routing, groups and transports; mihomo handles packets.
type Engine struct {
	engine.Engine
	tun      engine.Engine
	port     int
	password string
	xrayName string
	bus      *engine.EventBus
	op       sync.Mutex
	close    sync.Once
	closeErr error
	relays   sync.WaitGroup
	unsub    []func()
}

// New creates both engines without starting listeners or changing routes.
func New(xcfg, tcfg supervise.Config) (*Engine, error) {
	port, err := supervise.FreePort()
	if err != nil {
		return nil, err
	}
	secret, err := supervise.RandomSecret()
	if err != nil {
		return nil, err
	}
	xcfg.LocalPort = port
	x, err := xray.New(xcfg)
	if err != nil {
		return nil, err
	}
	tun, err := mihomo.New(tcfg)
	if err != nil {
		_ = x.Close()
		return nil, err
	}
	e := &Engine{Engine: x, tun: tun, port: port, password: secret,
		xrayName: filepath.Base(xcfg.Binary.Path), bus: engine.NewEventBus(128)}
	for _, child := range []engine.Engine{x, tun} {
		ch, unsub := child.Events().Subscribe()
		e.unsub = append(e.unsub, unsub)
		e.relays.Add(1)
		go func() {
			defer e.relays.Done()
			for ev := range ch {
				if ev.Kind == engine.EventState {
					ev.State = e.State()
				}
				e.bus.Publish(ev)
			}
		}()
	}
	return e, nil
}

// State reports readiness only when both supervisors are running.
func (e *Engine) State() engine.State {
	x, tun := e.Engine.State(), e.tun.State()
	if x == tun {
		return x
	}
	for _, state := range []engine.State{engine.StateFailed, engine.StateStopping, engine.StateStopped,
		engine.StateRecovering, engine.StateApplying, engine.StateStarting} {
		if x == state || tun == state {
			return state
		}
	}
	return engine.StateStarting
}

// Events includes failures from either process so the session owns both.
func (e *Engine) Events() *engine.EventBus { return e.bus }

// Capabilities adds the packet engine's FakeIP support to Xray's transports.
func (e *Engine) Capabilities() engine.Capabilities {
	caps := e.Engine.Capabilities()
	caps.Features = maps.Clone(caps.Features)
	caps.Features[engine.FeatureTun] = e.tun.Capabilities().Supports(engine.FeatureTun)
	caps.Features[engine.FeatureFakeIP] = e.tun.Capabilities().Supports(engine.FeatureFakeIP)
	// DNS answers come from the packet engine, so DoH3 follows its
	// capabilities, not Xray's (which has no H3 DNS transport).
	caps.Features[engine.FeatureDoH3] = e.tun.Capabilities().Supports(engine.FeatureDoH3)
	return caps
}

func (e *Engine) plans(p *engine.Plan) (*engine.Plan, *engine.Plan, error) {
	if p == nil {
		return nil, nil, errors.New("xray TUN: nil plan")
	}
	if err := p.Validate(); err != nil {
		return nil, nil, err
	}
	if !p.Tun.Enabled || !slices.Contains([]string{"", "gvisor", "system", "mixed", "mips"}, p.Tun.Stack) {
		return nil, nil, fmt.Errorf("xray TUN: unsupported bridge stack %q", p.Tun.Stack)
	}
	for _, rule := range p.Rules {
		if rule.Type == engine.RuleProcess &&
			(runtime.GOOS != "windows" || !slices.Contains([]string{"direct", "reject"}, rule.Target)) {
			// SOCKS carries destinations but loses the originating process.
			// Reject rules we cannot preserve rather than silently bypassing VPN.
			return nil, nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyPlanEngineUnsupported,
				"xray TUN bridge: this process rule needs another engine or Linux native gvisor")
		}
	}
	x := *p
	x.Tun = engine.Tun{}
	x.LocalProxy = engine.LocalProxy{Enabled: true, Username: bridgeID, Password: e.password}
	// Fake addresses are owned by the packet engine. Xray receives the
	// recovered hostname through SOCKS and must not synthesize a second pool.
	if x.DNS.Mode == string(engine.DNSFakeIP) {
		x.DNS.Mode = "rule"
	}
	// Xray has no DNS-over-HTTP/3 transport. The packet engine answers
	// client queries, so it keeps h3; Xray's own leg only resolves proxy
	// hostnames and steps those resolvers down to DoH. Without this an
	// h3:// resolver fails Xray's Validate and kills the session.
	// Clone: x shares the plan's backing array through the shallow copy.
	x.DNS.Servers = slices.Clone(x.DNS.Servers)
	for i, s := range x.DNS.Servers {
		if s.Transport == engine.DNSH3 {
			x.DNS.Servers[i].Transport = engine.DNSHTTPS
		}
	}
	x.Options.AllowLAN = false
	tun := *p
	tun.Engines = []engine.Kind{engine.KindMihomo}
	tun.PrivateControl = true
	tun.Outbounds = []engine.Outbound{{ID: bridgeID, Name: bridgeID, Protocol: engine.ProtocolSOCKS5,
		Server: "127.0.0.1", Port: uint16(e.port), UserID: bridgeID, Password: e.password, SOCKSUDP: true}} //nolint:gosec // FreePort returns a TCP port
	tun.Groups = nil
	tun.Rules = []engine.Rule{{Type: engine.RuleMatchAll, Target: bridgeID}}
	if runtime.GOOS == "windows" {
		// Linux excludes the core UID through policy routing. Windows needs
		// the packet engine to send Xray's own sockets to the real interface.
		// Process rules also belong here, before SOCKS loses their identity.
		tun.Rules = []engine.Rule{{Type: engine.RuleProcess, Value: e.xrayName, Target: "direct"}}
		for _, rule := range p.Rules {
			if !engine.IsBuiltInTarget(rule.Target) {
				rule.Target = bridgeID
			}
			tun.Rules = append(tun.Rules, rule)
		}
		tun.Rules = append(tun.Rules, engine.Rule{Type: engine.RuleMatchAll, Target: bridgeID})
	}
	tun.Options.Mode = "rule"
	tun.Options.Fragment = engine.Fragment{}
	tun.DNS.Servers = slices.Clone(p.DNS.Servers)
	for i, server := range tun.DNS.Servers {
		if server.Dialer != "" && server.Dialer != "direct" {
			tun.DNS.Servers[i].Dialer = bridgeID
		}
	}
	return &x, &tun, nil
}

// Validate checks both native configurations before the session is replaced.
func (e *Engine) Validate(ctx context.Context, p *engine.Plan) error {
	x, tun, err := e.plans(p)
	if err != nil {
		return err
	}
	if err := e.Engine.Validate(ctx, x); err != nil {
		return err
	}
	return e.tun.Validate(ctx, tun)
}

// Apply starts Xray before opening TUN so packets always have a receiver.
func (e *Engine) Apply(ctx context.Context, p *engine.Plan) error {
	e.op.Lock()
	defer e.op.Unlock()
	if err := engine.PrepareTun(p); err != nil {
		return err
	}
	x, tun, err := e.plans(p)
	if err != nil {
		return err
	}
	if err := e.Validate(ctx, p); err != nil {
		return err
	}
	if err := e.stop(ctx); err != nil {
		return err
	}
	if err := e.Engine.Apply(ctx, x); err != nil {
		return errors.Join(err, e.stop(context.WithoutCancel(ctx)))
	}
	if err := e.tun.Apply(ctx, tun); err != nil {
		return errors.Join(err, e.stop(context.WithoutCancel(ctx)))
	}
	return nil
}

// Select drops packet-engine connections before changing Xray's routing.
func (e *Engine) Select(ctx context.Context, group, target string) error {
	e.op.Lock()
	defer e.op.Unlock()
	// The TUN side is always a connection-tracking engine today, but assert
	// defensively: a failed assertion must not panic the session.
	tracker, ok := e.tun.(engine.ConnectionTracker)
	if !ok {
		return errs.Newf(errs.CodeInternal, errs.KeyEngineStartFailed,
			"xraytun: the packet engine does not track connections")
	}
	if err := tracker.CloseConnections(ctx); err != nil {
		return err
	}
	return e.Engine.Select(ctx, group, target)
}

// Counters use the packet engine so TUN traffic is counted once.
func (e *Engine) Counters(ctx context.Context) (engine.Counters, error) {
	return e.tun.Counters(ctx)
}

func (e *Engine) stop(ctx context.Context) error {
	// Remove the adapter and its routes before retiring the SOCKS receiver.
	return errors.Join(e.tun.Stop(ctx), e.Engine.Stop(ctx))
}

// Stop serializes shutdown with Apply to prevent a half-running bridge.
func (e *Engine) Stop(ctx context.Context) error {
	e.op.Lock()
	defer e.op.Unlock()
	return e.stop(ctx)
}

// Close releases event subscriptions only after both supervisors are closed.
func (e *Engine) Close() error {
	e.close.Do(func() {
		e.op.Lock()
		e.closeErr = errors.Join(e.tun.Close(), e.Engine.Close())
		e.op.Unlock()
		for _, unsub := range e.unsub {
			unsub()
		}
		e.relays.Wait()
	})
	return e.closeErr
}
