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
}

// IngressFirewall decorates a Firewall with ingress protection. It
// implements the Firewall interface so it can replace the platform
// firewall wherever one is used.
type IngressFirewall struct {
	mu      sync.Mutex
	inner   Firewall
	cfg     IngressConfig
	backend ingressBackend
	armed   bool
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

// Arm arms the kill switch first, then the ingress rules when enabled.
// The kill switch refusing to arm (for example the Linux root-UID fail
// closed) aborts before any ingress rule is touched.
func (f *IngressFirewall) Arm(ctx context.Context, enginePorts []uint16) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	if err := f.inner.Arm(ctx, enginePorts); err != nil {
		return err
	}
	if !f.cfg.Enabled || f.armed {
		return nil
	}
	if err := validateIngressConfig(f.cfg); err != nil {
		return err
	}
	backend, err := newIngressBackend(f.inner, f.cfg)
	if err != nil {
		return err
	}
	f.backend = backend
	if backend != nil {
		if err := backend.arm(ctx); err != nil {
			f.backend = nil
			return err
		}
	}
	f.armed = true
	return nil
}

// Disarm removes the ingress rules first, then disarms the kill switch,
// so inbound stays filtered until the last moment. It succeeds when
// nothing is armed.
func (f *IngressFirewall) Disarm(ctx context.Context) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.armed && f.backend != nil {
		if err := f.backend.disarm(ctx); err != nil {
			return err
		}
	}
	f.backend = nil
	f.armed = false
	return f.inner.Disarm(ctx)
}

// Armed reports whether the kill switch (the inner firewall) is armed.
func (f *IngressFirewall) Armed(ctx context.Context) (bool, error) {
	return f.inner.Armed(ctx)
}

// IngressArmed reports whether the ingress rules are installed by this
// decorator.
func (f *IngressFirewall) IngressArmed() bool {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.armed
}

// Inner exposes the wrapped firewall for diagnostics.
func (f *IngressFirewall) Inner() Firewall {
	return f.inner
}

// Name identifies the decorator in a diagnostics line.
func (f *IngressFirewall) Name() string { return "ingress+" + firewallName(f.inner) }

func firewallName(f Firewall) string {
	if named, ok := f.(interface{ Name() string }); ok {
		return named.Name()
	}
	return "firewall"
}
