// Ingress protection: the kill switch in this package blocks outbound
// traffic that bypasses the tunnel. Ingress protection is the mirror
// image: it drops inbound connection attempts arriving on physical
// interfaces that are not part of an established VPN session.
//
// The protection is a decorator over the platform Firewall. It arms the
// ingress rules exactly when the kill switch arms (that is the "enabled by
// default when the kill switch is on" behaviour) and removes them when the
// kill switch disarms. Setting IngressConfig.Enabled to false leaves the
// kill switch untouched while skipping the ingress rules entirely.
//
// Ordering inside each platform ruleset is load-bearing: established and
// related traffic, loopback, the tunnel interface, and the configured VPN
// server endpoints are accepted first; the final rule drops the rest.
// Loopback and, unless disabled, local networks are never broken by the
// drop.
package guard

import (
	"context"
	"errors"
	"net/netip"
	"strings"
	"sync"

	"github.com/levvs-one/sora-client/core/errs"
)

// IngressConfig controls the ingress protection decorator. The zero value
// is not usable: obtain a default with DefaultIngressConfig and adjust it.
type IngressConfig struct {
	// Enabled installs the ingress rules when the kill switch arms.
	// DefaultIngressConfig sets it to true; set it to false to keep only
	// the outbound kill switch.
	Enabled bool
	// VPNEndpoints are the VPN server addresses whose inbound traffic must
	// stay reachable. Each entry is an IP address or an "ip:port" pair;
	// the port is accepted syntactically but matching is by address —
	// a server we trust with all our traffic is trusted inbound too.
	// Invalid entries fail closed at Arm.
	VPNEndpoints []string
	// AllowLoopback keeps loopback inbound reachable. Disabling it would
	// break the local engine, so Arm refuses a config with it false.
	AllowLoopback bool
	// AllowLAN keeps inbound from local networks reachable, using the
	// same bypass networks as the kill switch.
	AllowLAN bool
}

// DefaultIngressConfig returns the owner-mandated default: protection on,
// loopback and LAN preserved.
func DefaultIngressConfig() IngressConfig {
	return IngressConfig{
		Enabled:       true,
		AllowLoopback: true,
		AllowLAN:      true,
	}
}

// parseIngressEndpoints validates the configured VPN server endpoints and
// returns their addresses. Anything that is not an IP address or an
// "ip:port" pair (domains, garbage, injection attempts) is rejected so a
// bad entry fails closed instead of silently widening or narrowing the
// ruleset.
func parseIngressEndpoints(entries []string) ([]netip.Addr, error) {
	addrs := make([]netip.Addr, 0, len(entries))
	for _, entry := range entries {
		entry = strings.TrimSpace(entry)
		if addr, err := netip.ParseAddr(entry); err == nil {
			addrs = append(addrs, addr)
			continue
		}
		if addrPort, err := netip.ParseAddrPort(entry); err == nil {
			addrs = append(addrs, addrPort.Addr())
			continue
		}
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: the VPN endpoint %q is not an IP address or ip:port pair", entry)
	}
	return addrs, nil
}

// validateIngressConfig rejects configurations that would break the local
// engine or silently disable the protection.
func validateIngressConfig(cfg IngressConfig) error {
	if !cfg.AllowLoopback {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: ingress protection without loopback would break the local engine; refusing")
	}
	if _, err := parseIngressEndpoints(cfg.VPNEndpoints); err != nil {
		return err
	}
	return nil
}

// ingressBackend installs and removes the platform ingress rules. It is
// provided per platform; a nil backend means the platform has no
// process-managed firewall (NoopFirewall) and there is nothing to install.
type ingressBackend interface {
	arm(ctx context.Context) error
	disarm(ctx context.Context) error
	// armed reports whether the platform rules are actually installed,
	// checked against the platform rather than this process's memory, so
	// a crash can never make the protection report itself absent while
	// its rules are still in force (or vice versa).
	armed(ctx context.Context) (bool, error)
}

// IngressFirewall decorates a Firewall with ingress protection. It
// implements the Firewall interface so it can replace the platform
// firewall wherever one is used.
type IngressFirewall struct {
	mu      sync.Mutex
	inner   Firewall
	cfg     IngressConfig
	backend ingressBackend
}

var _ Firewall = (*IngressFirewall)(nil)

// WithIngress wraps inner with ingress protection controlled by cfg. A nil
// inner becomes NoopFirewall, matching New.
func WithIngress(inner Firewall, cfg IngressConfig) *IngressFirewall {
	if inner == nil {
		inner = NoopFirewall{}
	}
	return &IngressFirewall{inner: inner, cfg: cfg}
}

// Arm arms the kill switch first, then the ingress rules when enabled. The
// config is validated before anything is armed, and the kill switch refusing
// to arm (for example the Linux root-UID fail closed) aborts before any
// ingress rule is installed. Re-arming re-applies the ingress rules so an
// externally removed table is restored; both backends arm idempotently, so
// a repeated Arm never duplicates rules.
func (f *IngressFirewall) Arm(ctx context.Context, enginePorts []uint16) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	if !f.cfg.Enabled {
		return f.inner.Arm(ctx, enginePorts)
	}
	if err := validateIngressConfig(f.cfg); err != nil {
		return err
	}
	if err := f.inner.Arm(ctx, enginePorts); err != nil {
		return err
	}
	if err := f.ensureBackend(); err != nil {
		// F-02: a failed Arm after a successful inner.Arm must not leave
		// the kill switch armed with no session. Guard.Restore only
		// disarms what applyKillSwitch recorded, and a failed Arm records
		// nothing — so roll back here, or the user loses connectivity
		// until a core restart.
		return f.rollbackArm(ctx, err)
	}
	if f.backend != nil {
		if err := f.backend.arm(ctx); err != nil {
			return f.rollbackArm(ctx, err)
		}
	}
	return nil
}

// rollbackArm undoes a successful inner.Arm after a later Arm step failed.
// Disarm succeeds when nothing is armed (see the platform contracts), so
// the rollback is always safe.
func (f *IngressFirewall) rollbackArm(ctx context.Context, err error) error {
	if disarmErr := f.inner.Disarm(context.WithoutCancel(ctx)); disarmErr != nil {
		return errors.Join(err, disarmErr)
	}
	return err
}

// ensureBackend builds the platform backend on first use. A nil inner
// (NoopFirewall) leaves the backend nil: there is nothing to install.
func (f *IngressFirewall) ensureBackend() error {
	if f.backend != nil {
		return nil
	}
	backend, err := newIngressBackend(f.inner, f.cfg)
	if err != nil {
		return err
	}
	f.backend = backend
	return nil
}

// Disarm removes the ingress rules first, then disarms the kill switch,
// so inbound stays filtered until the last moment. It succeeds when
// nothing is armed. The platform rules are removed whenever they are
// actually installed — even when a crashed predecessor installed them
// and this process never armed.
func (f *IngressFirewall) Disarm(ctx context.Context) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	// A backend that cannot be built never installed anything through
	// this decorator; ignoring the error keeps Disarm a safe cleanup
	// path after a failed Arm.
	_ = f.ensureBackend()
	if f.backend != nil {
		armed, err := f.backend.armed(ctx)
		if err != nil {
			return err
		}
		if armed {
			if err := f.backend.disarm(ctx); err != nil {
				return err
			}
		}
		f.backend = nil
	}
	return f.inner.Disarm(ctx)
}

// Armed reports whether the kill switch (the inner firewall) is armed.
func (f *IngressFirewall) Armed(ctx context.Context) (bool, error) {
	return f.inner.Armed(ctx)
}

// IngressArmed reports whether the ingress rules are actually installed,
// checked against the platform rather than this process's memory. After a
// crash the kernel tables may still be in force while this process never
// armed them; IngressArmed reports that truthfully so diagnostics and the
// UI never claim the inbound side is open when it is not.
func (f *IngressFirewall) IngressArmed(ctx context.Context) (bool, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if !f.cfg.Enabled {
		return false, nil
	}
	if err := f.ensureBackend(); err != nil {
		return false, err
	}
	if f.backend == nil {
		return false, nil
	}
	return f.backend.armed(ctx)
}

// Inner exposes the wrapped firewall for diagnostics.
func (f *IngressFirewall) Inner() Firewall {
	return f.inner
}

// SetTunNetworks forwards the session adapter subnets to the inner
// firewall. Guard.Apply calls this through the Firewall interface, and a
// decorator without the method would silently swallow the call: the type
// assertion in Guard.Apply would never fire, and the adapter permits
// would be lost in production.
func (f *IngressFirewall) SetTunNetworks(networks []netip.Prefix) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if s, ok := f.inner.(interface{ SetTunNetworks([]netip.Prefix) }); ok {
		s.SetTunNetworks(networks)
	}
}

// SetBlockedNetworks forwards the session destinations that must never
// bypass the tunnel (the fake-IP pool and the adapter subnets). Without
// this the type assertion in Guard.Apply misses through the decorator
// and the fake-IP block silently vanishes from the installed ruleset.
func (f *IngressFirewall) SetBlockedNetworks(networks []netip.Prefix) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if s, ok := f.inner.(interface{ SetBlockedNetworks([]netip.Prefix) }); ok {
		s.SetBlockedNetworks(networks)
	}
}

// CleanupStale removes a kill-switch table a crashed core left behind,
// forwarded to the inner firewall. The startup path asserts this
// capability on the wrapped firewall, so the wrap must not swallow it
// (SORA-M4).
func (f *IngressFirewall) CleanupStale(ctx context.Context) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	if c, ok := f.inner.(interface {
		CleanupStale(context.Context) error
	}); ok {
		return c.CleanupStale(ctx)
	}
	return nil
}

// Name identifies the decorator in a diagnostics line.
func (f *IngressFirewall) Name() string { return "ingress+" + firewallName(f.inner) }

func firewallName(f Firewall) string {
	if named, ok := f.(interface{ Name() string }); ok {
		return named.Name()
	}
	return "firewall"
}
