package session

import (
	"context"
	"errors"
	"net/netip"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
)

// Settings describes session-owned system changes. The platform guard applies
// them and restores prior state on every exit path.
type Settings struct {
	TunNetworks []netip.Prefix
	// FakeIPRange is the fake-address pool the engines answer with; the
	// guard blocks it outside the tunnel.
	FakeIPRange netip.Prefix
	// FakeIPRange6 is the IPv6 fake-address pool, set only when the plan
	// actually renders it. fc00::/18 sits inside the default fc00::/7
	// bypass, so the block must exist exactly when fake IPv6 answers do —
	// at any other time it would drop real ULA traffic.
	FakeIPRange6 netip.Prefix
	// KillSwitch blocks non-session traffic and stays armed while the
	// engine is down.
	KillSwitch bool
	// Bypass lists destinations that must skip the tunnel.
	Bypass []string
	// TunnelMode is the tunnel the plan asked for: system, application or
	// none.
	TunnelMode string
}

// Guard applies and restores session system changes. Apply is idempotent;
// Restore tolerates repeated calls. Restoration failures must be reported, and
// settings must not be assumed to survive crashes.
type Guard interface {
	// Apply brings the system to the requested settings.
	Apply(ctx context.Context, s Settings) error
	// Restore returns the system to the state it had before Apply. Calling
	// it
	// without a prior Apply must succeed and change nothing.
	Restore(ctx context.Context) error
	// Current reports the settings the guard believes are in force.
	Current() Settings
	// Blocked reports whether the block is actually in force right now,
	// checked against the platform rather than the applied settings: a
	// table removed out-of-band (or left by a crashed core) must not be
	// echoed back as armed. Diagnostics ask this, not Current().KillSwitch.
	Blocked(ctx context.Context) (bool, error)
	// Name identifies the implementation in diagnostics.
	Name() string
}

// BlockHolder is an optional Guard extension for server switches. When
// both the old and the new session want the kill switch, the manager
// holds the block before stopping the old session and releases it only
// after the new session (or a rolled-back previous session) is running:
// Restore calls made while a hold is active must clear the session's
// ownership of the settings without lifting the block itself. A hold is
// a count, not the guard lock — implementations must return promptly and
// let Apply/Restore run while a hold is outstanding. The returned
// release is idempotent on success — a duplicate call never consumes
// another hold — but a release whose final disarm FAILED must stay
// retryable: it must not cache the failure as final, and either a
// retry of the same release or a later Restore must be able to repeat
// the disarm. Releasing the last hold lifts the block only
// when no applied settings want it any more. Guards that do not
// implement BlockHolder keep the previous switch behaviour (a window
// with no block between the old Restore and the new Apply).
type BlockHolder interface {
	HoldBlock(ctx context.Context) (release func(ctx context.Context) error, err error)
}

// errBlockHoldUnsupported marks a BlockHolder that, underneath, holds
// nothing (for example a composite whose parts are all plain guards).
// The manager treats it as "no hold available" and switches the old way
// instead of failing a switch that would otherwise work.
var errBlockHoldUnsupported = errors.New("session: guard does not support holding the kill-switch block")

// acquireBlockHold takes a block hold when the guard supports it. A nil
// release with a nil error means the guard cannot hold and the caller
// proceeds without continuity; any other error is real and fails closed.
func acquireBlockHold(ctx context.Context, guard Guard) (func(context.Context) error, error) {
	holder, ok := guard.(BlockHolder)
	if !ok {
		return nil, nil
	}
	release, err := holder.HoldBlock(ctx)
	if err != nil {
		if errors.Is(err, errBlockHoldUnsupported) {
			return nil, nil
		}
		return nil, err
	}
	return release, nil
}

// NoopGuard supports system-owned tunnels such as Android, where this process
// manages no system settings.
type NoopGuard struct{}

// Apply records nothing and succeeds.
func (NoopGuard) Apply(context.Context, Settings) error { return nil }

// Restore succeeds without touching anything.
func (NoopGuard) Restore(context.Context) error { return nil }

// Current reports empty settings.
func (NoopGuard) Current() Settings { return Settings{} }

// Blocked reports that nothing is blocked: there is no firewall to probe.
func (NoopGuard) Blocked(context.Context) (bool, error) { return false, nil }

// Name identifies the implementation in diagnostics.
func (NoopGuard) Name() string { return "noop" }

// compositeGuard applies guards in order and restores in reverse to respect
// dependencies. Restoring firewall before proxy could leave proxied traffic
// unfiltered.
type compositeGuard struct {
	mu     sync.Mutex
	parts  []Guard
	active int
}

// NewCompositeGuard combines guards into one. The first guard is applied first
// and restored last.
func NewCompositeGuard(parts ...Guard) Guard {
	kept := make([]Guard, 0, len(parts))
	for _, part := range parts {
		if part != nil {
			kept = append(kept, part)
		}
	}
	if len(kept) == 0 {
		return NoopGuard{}
	}
	if len(kept) == 1 {
		return kept[0]
	}
	return &compositeGuard{parts: kept}
}

// Apply runs guards in order and rolls back earlier guards if a later one
// fails.
func (c *compositeGuard) Apply(ctx context.Context, s Settings) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	applied := 0
	for _, part := range c.parts {
		c.active = applied + 1
		if err := part.Apply(ctx, s); err != nil {
			var rollback error
			for i := c.active - 1; i >= 0; i-- {
				rollback = errors.Join(rollback, c.parts[i].Restore(context.WithoutCancel(ctx)))
			}
			if rollback == nil {
				c.active = 0
			}
			return errs.Wrap(errors.Join(err, rollback), errs.CodeOf(err), errs.KeyOf(err))
		}
		applied++
	}
	c.active = applied
	return nil
}

// Restore tries all applied guards in reverse order and returns the first
// failure, ensuring one error does not skip remaining cleanup.
func (c *compositeGuard) Restore(ctx context.Context) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	var first error
	for i := c.active - 1; i >= 0; i-- {
		if err := c.parts[i].Restore(ctx); err != nil && first == nil {
			first = err
		}
	}
	if first == nil {
		c.active = 0
	}
	return first
}

// Current returns the first guard's settings, representing the outermost system
// change.
func (c *compositeGuard) Current() Settings {
	c.mu.Lock()
	defer c.mu.Unlock()
	if len(c.parts) == 0 {
		return Settings{}
	}
	return c.parts[0].Current()
}

// Blocked reports true when any part reports its block in force. A block
// owned by any part still blocks traffic, so the first positive answer
// decides; a probe failure leaves the answer unknown instead of guessing.
func (c *compositeGuard) Blocked(ctx context.Context) (bool, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	for _, part := range c.parts {
		blocked, err := part.Blocked(ctx)
		if err != nil {
			return false, err
		}
		if blocked {
			return true, nil
		}
	}
	return false, nil
}

// HoldBlock holds the block on every part that supports holding and
// reports errBlockHoldUnsupported when no part does, so the manager
// falls back to the old switch behaviour for plain composites. Parts
// without BlockHolder are not covered: their Restore still lifts their
// share of the block during a switch. A part failing mid-acquire
// releases the holds already taken.
func (c *compositeGuard) HoldBlock(ctx context.Context) (func(context.Context) error, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	var releases []func(context.Context) error
	for _, part := range c.parts {
		holder, ok := part.(BlockHolder)
		if !ok {
			continue
		}
		release, err := holder.HoldBlock(ctx)
		if err != nil {
			if errors.Is(err, errBlockHoldUnsupported) {
				continue
			}
			var joined error
			for i := len(releases) - 1; i >= 0; i-- {
				joined = errors.Join(joined, releases[i](context.WithoutCancel(ctx)))
			}
			return nil, errors.Join(err, joined)
		}
		if release != nil {
			releases = append(releases, release)
		}
	}
	if len(releases) == 0 {
		return nil, errBlockHoldUnsupported
	}
	// Idempotent on success only, like the parts: caching a failure
	// through a sync.Once would make a transient disarm failure of
	// one part unretryable through the composite. Parts that already
	// released successfully answer a retry with nil, so re-running
	// the whole list only re-attempts the parts that failed.
	var mu sync.Mutex
	done := false
	return func(ctx context.Context) error {
		mu.Lock()
		defer mu.Unlock()
		if done {
			return nil
		}
		var relErr error
		for i := len(releases) - 1; i >= 0; i-- {
			relErr = errors.Join(relErr, releases[i](ctx))
		}
		if relErr != nil {
			return relErr
		}
		done = true
		return nil
	}, nil
}

// Name lists guard names in apply order for diagnostics.
func (c *compositeGuard) Name() string {
	name := ""
	for i, part := range c.parts {
		if i > 0 {
			name += "+"
		}
		name += part.Name()
	}
	return name
}
