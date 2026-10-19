package diagnostics

import (
	"context"
	"net"
	"net/netip"
	"strconv"
	"strings"
	"time"
)

// Check IDs returned by CheckDnsLeaks. They are a stable contract with the
// UI: the interface switches on them, never on free text.
const (
	// DnsLeakTunnelDNS verifies the session routes DNS through its own
	// resolvers and sanity-probes the tunnel DNS path.
	DnsLeakTunnelDNS = "tunnel-dns"
	// DnsLeakSystemResolvers compares the OS resolvers against the tunnel
	// resolvers. A mismatch outside the tunnel is a leak.
	DnsLeakSystemResolvers = "system-resolvers"
	// DnsLeakKillSwitchDNS reports whether the kill switch covers DNS. It
	// is a warning, never a leak by itself.
	DnsLeakKillSwitchDNS = "killswitch-dns"
)

// Localization keys for the check titles shown in the UI.
const (
	DnsLeakLabelTunnelDNS       = "dnsLeak.check.tunnelDns"
	DnsLeakLabelSystemResolvers = "dnsLeak.check.systemResolvers"
	DnsLeakLabelKillSwitchDNS   = "dnsLeak.check.killSwitchDns"
)

// Localization keys for the suggested fixes. A check may carry a hint
// without being a leak; the UI renders those as warnings.
const (
	DnsLeakFixConfigureTunnel  = "dnsLeak.fix.configureTunnelDns"
	DnsLeakFixReviewResolvers  = "dnsLeak.fix.reviewSystemResolvers"
	DnsLeakFixEnableKillSwitch = "dnsLeak.fix.enableKillSwitch"
)

// canaryHost is the fixed, documented name used to sanity-probe the tunnel
// DNS path. It is a stable public anycast name; resolving it issues a single
// DNS query and no other network traffic.
const canaryHost = "one.one.one.one"

// defaultResolveTimeout bounds one canary query.
const defaultResolveTimeout = 3 * time.Second

// TunnelResolver is one resolver the session routes DNS through.
type TunnelResolver struct {
	// Address is the resolver address as configured (IP or name).
	Address string
	// Port is the resolver port; 0 means the transport default (53).
	Port uint16
	// Transport is "udp", "tcp", "tls", "https", "quic", "system" or "".
	Transport string
}

// DnsLeakInput configures one DNS leak check run.
type DnsLeakInput struct {
	// TunnelResolvers are the resolvers the session routes DNS through,
	// taken from the session plan.
	TunnelResolvers []TunnelResolver
	// DnsHijacked reports whether the tunnel captures plain DNS traffic,
	// so OS resolvers cannot leak around it.
	DnsHijacked bool
	// KillSwitchArmed reports whether the firewall currently blocks
	// non-tunnel traffic, including DNS.
	KillSwitchArmed bool
	// SystemResolvers overrides OS detection (tests). Nil means detect.
	SystemResolvers []string
	// CanaryHost overrides the default canary (tests).
	CanaryHost string
	// ResolveTimeout bounds one canary query; zero selects the default.
	ResolveTimeout time.Duration
	// Resolve probes host through resolverAddr ("ip" or "ip:port"); nil
	// selects the stdlib prober. Tests inject failures here.
	Resolve func(ctx context.Context, resolverAddr, host string) ([]string, error)
}

// DnsLeakCheck is one check result. Label and FixHint are localization keys
// for the UI, never free text; Expected and Actual carry raw values.
type DnsLeakCheck struct {
	ID       string
	Label    string
	Expected string
	Actual   string
	Leaked   bool
	FixHint  string
}

// normalizeResolver canonicalizes a resolver for display and comparison:
// bare IPs are normalized, "ip:port" keeps a non-default port, bracketed
// IPv6 is unwrapped.
func normalizeResolver(s string) string {
	s = strings.TrimSpace(s)
	if s == "" {
		return ""
	}
	host, port := s, ""
	if h, p, err := net.SplitHostPort(s); err == nil {
		host, port = h, p
	} else if strings.HasPrefix(s, "[") && strings.HasSuffix(s, "]") {
		host = s[1 : len(s)-1]
	}
	if ip, err := netip.ParseAddr(host); err == nil {
		if port == "" || port == "53" {
			return ip.String()
		}
		return net.JoinHostPort(ip.String(), port)
	}
	return s
}

// displayList joins values for display; "(none)" marks an empty set so the
// UI never shows a blank row.
func displayList(values []string) string {
	if len(values) == 0 {
		return "(none)"
	}
	return strings.Join(values, ", ")
}

// CheckDnsLeaks compares the session's DNS path against the OS resolvers and
// the kill switch state. It performs no network I/O except a single canary
// query through the tunnel resolver to sanity-probe that path.
func CheckDnsLeaks(ctx context.Context, in DnsLeakInput) []DnsLeakCheck {
	if in.CanaryHost == "" {
		in.CanaryHost = canaryHost
	}
	if in.ResolveTimeout <= 0 {
		in.ResolveTimeout = defaultResolveTimeout
	}
	resolve := in.Resolve
	if resolve == nil {
		resolve = resolveVia
	}

	tunnel := make([]string, 0, len(in.TunnelResolvers))
	for _, r := range in.TunnelResolvers {
		if n := normalizeResolver(r.Address); n != "" {
			tunnel = append(tunnel, n)
		}
	}
	system := in.SystemResolvers
	if system == nil {
		system = SystemResolvers()
	}
	normalizedSystem := make([]string, 0, len(system))
	for _, s := range system {
		if n := normalizeResolver(s); n != "" {
			normalizedSystem = append(normalizedSystem, n)
		}
	}

	checks := make([]DnsLeakCheck, 0, 3)
	checks = append(checks, checkTunnelDNS(ctx, in, tunnel, resolve))
	checks = append(checks, checkSystemResolvers(tunnel, normalizedSystem, in.DnsHijacked, in.KillSwitchArmed))
	checks = append(checks, checkKillSwitchDNS(in.KillSwitchArmed))
	return checks
}

// checkTunnelDNS verifies the session configures its own resolvers and
// sanity-probes the tunnel DNS path with the canary host.
func checkTunnelDNS(ctx context.Context, in DnsLeakInput, tunnel []string, resolve func(context.Context, string, string) ([]string, error)) DnsLeakCheck {
	check := DnsLeakCheck{
		ID:       DnsLeakTunnelDNS,
		Label:    DnsLeakLabelTunnelDNS,
		Expected: displayList(tunnel),
	}
	if len(tunnel) == 0 {
		check.Actual = "(none)"
		check.Leaked = true
		check.FixHint = DnsLeakFixConfigureTunnel
		return check
	}
	probeAddr, probed := canaryResolver(in.TunnelResolvers)
	timeout := in.ResolveTimeout
	if deadline, ok := ctx.Deadline(); ok {
		if left := time.Until(deadline); left < timeout {
			timeout = left
		}
	}
	if timeout <= 0 {
		check.Actual = "canary skipped: no time left"
		return check
	}
	if !probed {
		check.Actual = displayList(tunnel) + " (canary not probed: encrypted transport)"
		return check
	}
	qctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	ips, err := resolve(qctx, probeAddr, in.CanaryHost)
	if err != nil {
		// A failing tunnel resolver is an outage, not a leak: report it
		// honestly without raising the leak flag.
		check.Actual = "canary " + in.CanaryHost + " via " + probeAddr + ": unreachable"
		return check
	}
	check.Actual = "canary " + in.CanaryHost + " via " + probeAddr + ": " + displayList(ips)
	return check
}

// canaryResolver picks a tunnel resolver that can be probed with a plain
// DNS query. Encrypted transports are reported, not probed.
func canaryResolver(resolvers []TunnelResolver) (addr string, probed bool) {
	for _, r := range resolvers {
		switch strings.ToLower(strings.TrimSpace(r.Transport)) {
		case "", "udp", "tcp", "system":
		default:
			continue
		}
		host := strings.TrimSpace(r.Address)
		if strings.HasPrefix(host, "[") && strings.HasSuffix(host, "]") {
			host = host[1 : len(host)-1]
		}
		if host == "" {
			continue
		}
		if ip, err := netip.ParseAddr(host); err == nil {
			host = ip.String()
		}
		if r.Port != 0 && r.Port != 53 {
			host = net.JoinHostPort(host, strconv.Itoa(int(r.Port)))
		}
		return host, true
	}
	return "", false
}

// checkSystemResolvers flags OS resolvers that would answer outside the
// tunnel. Hijacked DNS or an armed kill switch makes OS resolvers unable
// to leak, so the check passes with the observed values still reported.
func checkSystemResolvers(tunnel, system []string, hijacked, killSwitchArmed bool) DnsLeakCheck {
	check := DnsLeakCheck{
		ID:       DnsLeakSystemResolvers,
		Label:    DnsLeakLabelSystemResolvers,
		Expected: displayList(tunnel),
		Actual:   displayList(system),
	}
	if len(system) == 0 {
		// Detection failed; say so instead of guessing.
		check.Actual = "(unknown: OS resolvers not detected)"
		return check
	}
	if hijacked || killSwitchArmed {
		return check
	}
	inTunnel := make(map[string]bool, len(tunnel))
	for _, t := range tunnel {
		inTunnel[t] = true
	}
	var outside []string
	for _, s := range system {
		if !inTunnel[s] {
			outside = append(outside, s)
		}
	}
	if len(outside) > 0 {
		check.Leaked = true
		check.FixHint = DnsLeakFixReviewResolvers
	}
	return check
}

// checkKillSwitchDNS reports whether the kill switch covers DNS. An
// unarmed kill switch is a warning, not a leak.
func checkKillSwitchDNS(armed bool) DnsLeakCheck {
	check := DnsLeakCheck{
		ID:       DnsLeakKillSwitchDNS,
		Label:    DnsLeakLabelKillSwitchDNS,
		Expected: "armed",
		Actual:   "armed",
	}
	if !armed {
		check.Actual = "not armed"
		check.FixHint = DnsLeakFixEnableKillSwitch
	}
	return check
}

// resolveVia performs a plain DNS query for host through resolverAddr
// ("ip" or "ip:port", default port 53) using only the standard library.
func resolveVia(ctx context.Context, resolverAddr, host string) ([]string, error) {
	addr := resolverAddr
	if _, _, err := net.SplitHostPort(addr); err != nil {
		// Bare address: JoinHostPort adds brackets for IPv6 itself.
		addr = net.JoinHostPort(strings.Trim(addr, "[]"), "53")
	}
	r := &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
			d := &net.Dialer{}
			return d.DialContext(ctx, "udp", addr)
		},
	}
	addrs, err := r.LookupIPAddr(ctx, host)
	if err != nil {
		return nil, err
	}
	ips := make([]string, 0, len(addrs))
	for _, a := range addrs {
		ips = append(ips, a.IP.String())
	}
	return ips, nil
}
