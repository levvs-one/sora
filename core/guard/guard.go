// Package guard manages reversible kill-switch rules owned by the core. It
// records armed state and restores it on every exit path; tunnel implementation
// is separate.
package guard

import (
	"context"
	"net/netip"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/session"
)

var _ session.Guard = (*Guard)(nil)
var _ session.BlockHolder = (*Guard)(nil)

// NoopFirewall supports system-owned tunnels such as Android VpnService, where
// this process has no firewall rules to manage.
type NoopFirewall struct{}

// Arm succeeds and reports that nothing is blocked.
func (NoopFirewall) Arm(context.Context, []uint16) error { return nil }

// Disarm succeeds without changing anything.
func (NoopFirewall) Disarm(context.Context) error { return nil }

// Armed reports that no rule of this package is in force.
func (NoopFirewall) Armed(context.Context) (bool, error) { return false, nil }

// Firewall blocks or unblocks traffic that does not belong to the tunnel.
type Firewall interface {
	// Arm blocks traffic while the tunnel is down. It is idempotent.
	Arm(ctx context.Context, enginePorts []uint16) error
	// Disarm removes the block. It succeeds when nothing is armed.
	Disarm(ctx context.Context) error
	// Armed reports whether the block is in force.
	Armed(ctx context.Context) (bool, error)
}

// FirewallOptions configures kill-switch exemptions outside the tunnel.
type FirewallOptions struct {
	// EngineUID is the account the engines run as; Linux matches them by
	// it. It must not be 0: arming the kill switch as root would exempt
	// every root process, so Arm fails closed instead (SORA-H4).
	EngineUID int
	// EnginesDir holds the engine executables; Windows matches them by
	// file.
	EnginesDir string
	// Bypass are the networks that stay reachable; empty means private
	// space.
	Bypass []string
}

// Options identifies engine listener ports that must stay reachable for tunnel
// recovery.
type Options struct {
	// EnginePorts are the local ports the kill switch must never block.
	EnginePorts []uint16
	// Mode selects how far the kill switch goes: ModeStandard arms it
	// while the session asks for it, and ModeOff never arms it. A
	// persistent (strict) mode exists inside the package for tests but
	// is not selectable here — enabling a block that survives reboots
	// is a product decision the owner has not taken. The zero value is
	// ModeStandard.
	Mode Mode
	// StateDir holds the internal strict-mode marker. It must survive
	// reboots (for example /var/lib/sora on Linux).
	StateDir string
}

// Guard owns and restores the session kill switch. The system proxy belongs to
// the signed-in user and is managed by the user UI.
type Guard struct {
	mu        sync.Mutex
	firewall  Firewall
	opts      Options
	mode      Mode
	stateDir  string
	applied   session.Settings
	restoring bool
	// holds counts outstanding session.BlockHolder holds. While it is
	// positive Restore clears the session's ownership but leaves the
	// firewall armed, so a server switch with the kill switch wanted on
	// both sides never opens a direct-traffic window.
	holds int
}

// New creates a guard. Nil uses NoopFirewall for platforms without a
// process-managed firewall.
func New(opts Options, firewall Firewall) (*Guard, error) {
	if len(opts.EnginePorts) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: no engine ports to keep open")
	}
	switch opts.Mode {
	case ModeStandard, modeStrict, ModeOff:
	default:
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: unknown kill-switch mode %d", int(opts.Mode))
	}
	if opts.Mode == modeStrict && opts.StateDir == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: strict mode needs a state directory for its marker; refusing a strict switch that could not survive a reboot")
	}
	if firewall == nil {
		firewall = NoopFirewall{}
	}
	return &Guard{firewall: firewall, opts: opts, mode: opts.Mode, stateDir: opts.StateDir}, nil
}

// Apply brings the system to the requested settings.
func (g *Guard) Apply(ctx context.Context, settings session.Settings) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.restoring {
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
			"guard: the guard is being restored")
	}
	if f, ok := g.firewall.(interface{ SetTunNetworks([]netip.Prefix) }); ok {
		f.SetTunNetworks(settings.TunNetworks)
	}
	if f, ok := g.firewall.(interface{ SetBlockedNetworks([]netip.Prefix) }); ok {
		networks := append([]netip.Prefix(nil), settings.TunNetworks...)
		if settings.FakeIPRange.IsValid() {
			networks = append(networks, settings.FakeIPRange.Masked())
		}
		// The IPv6 fake pool (fc00::/18 by default) sits inside the
		// default fc00::/7 bypass: without the block, fake IPv6 answers
		// would leave the tunnel through the LAN permit.
		if settings.FakeIPRange6.IsValid() {
			networks = append(networks, settings.FakeIPRange6.Masked())
		}
		f.SetBlockedNetworks(networks)
	}
	if err := g.applyKillSwitch(ctx, settings.KillSwitch); err != nil {
		return err
	}
	g.applied = settings
	return nil
}

// applyKillSwitch moves the firewall to the wanted state for the guard's
// mode. In strict mode the marker — not this process's memory — is the
// source of truth for "was the switch on", so a crash between Apply calls
// can never lose the persistent intent.
func (g *Guard) applyKillSwitch(ctx context.Context, want bool) error {
	switch g.mode {
	case ModeOff:
		if want {
			return errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
				"guard: the kill switch is off and will not arm; refusing instead of reporting a block that is not there")
		}
		return nil
	case modeStrict:
		was := g.applied.KillSwitch || strictWanted(g.stateDir)
		switch {
		case want && !was:
			if err := g.firewall.Arm(ctx, g.opts.EnginePorts); err != nil {
				return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
			}
			if err := writeStrictMarker(g.stateDir); err != nil {
				// The block is up but the intent is not recorded: a
				// crash would now lose it. Roll the Arm back so the
				// reported state stays honest.
				_ = g.firewall.Disarm(context.WithoutCancel(ctx))
				return err
			}
		case want && was && !g.applied.KillSwitch:
			// The marker says the block should be up, but this
			// process never armed it (crash or reboot without a
			// reconcile): verify against the platform and repair.
			armed, err := g.firewall.Armed(ctx)
			if err != nil {
				return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
			}
			if !armed {
				if err := g.firewall.Arm(ctx, g.opts.EnginePorts); err != nil {
					return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
				}
			}
		case !want && was:
			if err := g.firewall.Disarm(ctx); err != nil {
				return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
			}
			// The firewall is down; a leftover marker would re-arm
			// it on the next reconcile. Failing to clear it keeps
			// blocking (fail closed) and reports the problem.
			if err := removeStrictMarker(g.stateDir); err != nil {
				return err
			}
		}
		return nil
	default: // ModeStandard
		if want && !g.applied.KillSwitch {
			if err := g.firewall.Arm(ctx, g.opts.EnginePorts); err != nil {
				return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
			}
		}
		if !want && g.applied.KillSwitch {
			if err := g.firewall.Disarm(ctx); err != nil {
				return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
			}
		}
		return nil
	}
}

// reconcile matches the firewall against the persistent intent at startup.
// It is internal: callers use it once, before the first Apply. In strict
// mode with a marker it re-arms the block (idempotent), so the switch
// survives crashes and reboots; otherwise it removes a table a crashed
// core left behind, so stale rules do not keep blocking traffic with no
// live session (SORA-M4).
func (g *Guard) reconcile(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.mode == modeStrict && strictWanted(g.stateDir) {
		if err := g.firewall.Arm(ctx, g.opts.EnginePorts); err != nil {
			return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
		}
		g.applied.KillSwitch = true
		return nil
	}
	if cleaner, ok := g.firewall.(interface {
		CleanupStale(context.Context) error
	}); ok {
		if err := cleaner.CleanupStale(ctx); err != nil {
			return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
		}
	}
	return nil
}

// Blocked reports whether traffic is actually blocked right now, checked
// against the firewall rather than this process's memory. This is the
// honest source for a UI "Blocked" state: after a crash the in-memory
// settings are gone, but the kernel tables may still be in force.
func (g *Guard) Blocked(ctx context.Context) (bool, error) {
	g.mu.Lock()
	defer g.mu.Unlock()
	return g.firewall.Armed(ctx)
}

// strictIntent reports whether the user asked for a persistent strict
// block that was never explicitly turned off. When true but Blocked is
// false (for example before reconcile runs at startup), the UI should show
// the block as pending rather than "Disconnected". Internal with the rest
// of the strict machinery.
func (g *Guard) strictIntent() bool {
	g.mu.Lock()
	defer g.mu.Unlock()
	return g.mode == modeStrict && strictWanted(g.stateDir)
}

// HoldBlock implements session.BlockHolder: it pins the kill-switch
// block across a server switch. The block a running session armed stays
// armed while the hold is outstanding — Restore clears ownership only —
// and releasing the last hold disarms it when no session has re-applied
// the switch in the meantime. In strict mode the block already survives
// Restore by design, so a hold only counts. In off mode there is no
// block to hold: the hold is vacuous and the canonical Apply refusal
// still decides the switch. The hold interacts with IngressFirewall
// only through Arm/Disarm: Restore under a hold never calls Disarm, so
// the ingress rules stay installed too, and a re-Apply re-arms the
// decorator idempotently; the one path a hold cannot cover is
// IngressFirewall's own rollbackArm disarming its inner firewall after
// a failed ingress Arm inside Apply (F-02) — that disarm is the
// decorator's, not this guard's, and a later rollback re-Apply re-arms.
func (g *Guard) HoldBlock(ctx context.Context) (func(context.Context) error, error) {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.restoring {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
			"guard: the guard is being restored")
	}
	if g.mode == ModeStandard && !g.applied.KillSwitch {
		// No session block is recorded (the caller holds defensively):
		// arm now so the release has a symmetric block to drop.
		if err := g.firewall.Arm(ctx, g.opts.EnginePorts); err != nil {
			return nil, errs.Wrap(err, errs.CodeInternal, errs.KeyGuardFirewallFail)
		}
	}
	g.holds++
	var once sync.Once
	var relErr error
	release := func(ctx context.Context) error {
		once.Do(func() { relErr = g.releaseBlockHold(ctx) })
		return relErr
	}
	return release, nil
}

// releaseBlockHold drops one hold and, for the last one, disarms the
// block no session re-applied while switching. A block the new (or
// rolled-back) session applied is left exactly as it was.
func (g *Guard) releaseBlockHold(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.holds > 0 {
		g.holds--
	}
	if g.holds == 0 && g.mode == ModeStandard && !g.applied.KillSwitch {
		if err := g.firewall.Disarm(ctx); err != nil {
			return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardRestoreFailed)
		}
	}
	return nil
}

// Restore lifts the kill switch if this guard armed it. In strict mode
// Restore deliberately keeps the block: the persistent intent belongs to
// the user, not to the session, and only an explicit Apply with the
// switch off clears it. While a block hold is outstanding (a server
// switch) Restore also keeps the block and only clears ownership, so
// the replacement session re-applies onto an armed firewall.
func (g *Guard) Restore(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.restoring = true
	defer func() { g.restoring = false }()

	if g.mode == modeStrict {
		g.applied = session.Settings{}
		return nil
	}
	if g.holds > 0 {
		g.applied = session.Settings{}
		return nil
	}
	if g.applied.KillSwitch {
		if err := g.firewall.Disarm(ctx); err != nil {
			// Retain armed state after a failed restore so
			// subsequent cleanup can retry.
			return errs.Wrap(err, errs.CodeInternal, errs.KeyGuardRestoreFailed)
		}
	}
	g.applied = session.Settings{}
	return nil
}

// Current reports the settings the guard believes are in force. In strict
// mode a surviving marker counts as "the switch is on" even when this
// process never armed it, so Current never claims the traffic is open
// while the persistent block is in force.
func (g *Guard) Current() session.Settings {
	g.mu.Lock()
	defer g.mu.Unlock()
	current := g.applied
	if g.mode == modeStrict && strictWanted(g.stateDir) {
		current.KillSwitch = true
	}
	return current
}

// Name identifies the guard in a diagnostics line.
func (g *Guard) Name() string { return "sora-guard" }
