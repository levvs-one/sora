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
	// while the session asks for it, ModeStrict keeps the block armed
	// across crashes, clean exits, and reboots until explicitly turned
	// off, and ModeOff never arms it. The zero value is ModeStandard.
	Mode Mode
	// StateDir holds the strict-mode marker when Mode is ModeStrict. It
	// must survive reboots (for example /var/lib/sora on Linux); New
	// fails closed when it is empty in strict mode.
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
}

// New creates a guard. Nil uses NoopFirewall for platforms without a
// process-managed firewall.
func New(opts Options, firewall Firewall) (*Guard, error) {
	if len(opts.EnginePorts) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: no engine ports to keep open")
	}
	switch opts.Mode {
	case ModeStandard, ModeStrict, ModeOff:
	default:
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: unknown kill-switch mode %d", int(opts.Mode))
	}
	if opts.Mode == ModeStrict && opts.StateDir == "" {
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
	case ModeStrict:
		was := g.applied.KillSwitch || StrictWanted(g.stateDir)
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
			// Recover): verify against the platform and repair.
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
			// it on the next Recover. Failing to clear it keeps
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

// Recover reconciles the firewall with the persistent intent at startup.
// Call it once, while holding the instance lock, before the first Apply:
//
//   - strict mode with a marker: re-arms the block (idempotent), so the
//     switch survives crashes and reboots;
//   - otherwise: removes a table a crashed core left behind, so stale
//     rules do not keep blocking traffic with no live session (SORA-M4).
func (g *Guard) Recover(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.mode == ModeStrict && StrictWanted(g.stateDir) {
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

// StrictWanted reports whether the user asked for a persistent strict
// block that was never explicitly turned off. When true but Blocked is
// false (for example before Recover runs at startup), the UI should show
// the block as pending rather than "Disconnected".
func (g *Guard) StrictWanted() bool {
	g.mu.Lock()
	defer g.mu.Unlock()
	return g.mode == ModeStrict && StrictWanted(g.stateDir)
}

// Restore lifts the kill switch if this guard armed it. In strict mode
// Restore deliberately keeps the block: the persistent intent belongs to
// the user, not to the session, and only an explicit Apply with the
// switch off clears it.
func (g *Guard) Restore(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.restoring = true
	defer func() { g.restoring = false }()

	if g.mode == ModeStrict {
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
	if g.mode == ModeStrict && StrictWanted(g.stateDir) {
		current.KillSwitch = true
	}
	return current
}

// Name identifies the guard in a diagnostics line.
func (g *Guard) Name() string { return "sora-guard" }
