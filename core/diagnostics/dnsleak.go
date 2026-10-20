package diagnostics

import (
	"context"
	"net"
	"net/netip"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Check IDs returned by CheckDnsLeaks. They are a stable contract with the
// UI: the interface switches on them, never on free text.
const (
	// DnsLeakTunnelDNS verifies the session routes DNS through its own
	// resolvers and canary-probes every probeable tunnel DNS path: plain
	// UDP/TCP as well as encrypted DoT and DoH.
	DnsLeakTunnelDNS = "tunnel-dns"
	// DnsLeakSystemResolvers compares the OS resolvers against the tunnel
	// resolvers. A mismatch outside the tunnel is a leak.
	DnsLeakSystemResolvers = "system-resolvers"
	// DnsLeakEncryptedDNS flags OS-configured encrypted DNS (DoT/DoH)
	// endpoints that bypass the tunnel's DNS path. Plain-DNS hijacking
	// does not cover them, so unlike system-resolvers this check is not
	// suppressed by DnsHijacked; only an armed kill switch does.
	DnsLeakEncryptedDNS = "encrypted-dns"
	// DnsLeakKillSwitchDNS reports whether the kill switch covers DNS. It
	// is a warning, never a leak by itself.
	DnsLeakKillSwitchDNS = "killswitch-dns"
	// DnsLeakSpoofDNS cross-checks the canary answer across the system
	// and tunnel resolvers (T014, CENSORSHIP-METER P0.2): a resolver that
	// answers with a sinkhole address or disagrees with everyone else is
	// a censor-shaped DNS lie.
	DnsLeakSpoofDNS = "dns-spoof"
)

// Localization keys for the check titles shown in the UI.
const (
	DnsLeakLabelTunnelDNS       = "dnsLeak.check.tunnelDns"
	DnsLeakLabelSystemResolvers = "dnsLeak.check.systemResolvers"
	DnsLeakLabelEncryptedDNS    = "dnsLeak.check.encryptedDns"
	DnsLeakLabelKillSwitchDNS   = "dnsLeak.check.killSwitchDns"
	DnsLeakLabelSpoofDNS        = "dnsLeak.check.dnsSpoof"
)

// Localization keys for the suggested fixes. A check may carry a hint
// without being a leak; the UI renders those as warnings.
const (
	DnsLeakFixConfigureTunnel  = "dnsLeak.fix.configureTunnelDns"
	DnsLeakFixReviewResolvers  = "dnsLeak.fix.reviewSystemResolvers"
	DnsLeakFixReviewEncrypted  = "dnsLeak.fix.reviewEncryptedDns"
	DnsLeakFixEnableKillSwitch = "dnsLeak.fix.enableKillSwitch"
	DnsLeakFixUseEncryptedDNS  = "dnsLeak.fix.useEncryptedDns"
)

// canaryHost is the fixed, documented name used to sanity-probe the tunnel
// DNS path. It is a stable public anycast name; resolving it issues DNS
// queries and no other network traffic.
const canaryHost = "one.one.one.one"

// defaultResolveTimeout bounds one canary probe. Probes run in parallel,
// so the whole tunnel-dns check costs about one timeout in the worst case,
// well inside the control plane's check budget.
const defaultResolveTimeout = 3 * time.Second

// TunnelResolver is one resolver the session routes DNS through.
type TunnelResolver struct {
	// Address is the resolver address as configured (IP, name, or a DoH URL).
	Address string
	// Port is the resolver port; 0 means the transport default (53/853/443).
	Port uint16
	// Transport is "udp", "tcp", "tls", "https", "quic", "h3", "system",
	// "fakeip" or "".
	Transport string
}

// DnsLeakInput configures one DNS leak check run.
type DnsLeakInput struct {
	// TunnelResolvers are the resolvers the session routes DNS through,
	// taken from the session plan.
	TunnelResolvers []TunnelResolver
	// DnsHijacked reports whether the tunnel captures plain DNS traffic,
	// so OS resolvers cannot leak around it. It covers port 53 only:
	// encrypted DNS bypasses it (see DnsLeakEncryptedDNS).
	DnsHijacked bool
	// KillSwitchArmed reports whether the firewall currently blocks
	// non-tunnel traffic, including DNS.
	KillSwitchArmed bool
	// SystemResolvers overrides OS detection (tests). Nil means detect.
	SystemResolvers []string
	// SystemEncryptedDNS overrides OS encrypted-DNS detection (tests).
	// Nil means detect; pass an empty slice for "detected, none".
	SystemEncryptedDNS []string
	// CanaryHost overrides the default canary (tests).
	CanaryHost string
	// ResolveTimeout bounds one canary probe; zero selects the default.
	ResolveTimeout time.Duration
	// Probe queries host through one tunnel resolver: network is "udp",
	// "tcp", "tls" (DoT) or "https" (DoH); addr is "ip", "ip:port", or a
	// DoH URL. It is called concurrently (one goroutine per resolver
	// target), so a Probe with state must be safe for concurrent use.
	// Nil selects the standard probers. Tests inject failures here.
	Probe func(ctx context.Context, network, addr, host string) ([]string, error)
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

// probeVia dispatches one canary probe to the prober for its network.
func probeVia(ctx context.Context, network, addr, host string) ([]string, error) {
	switch network {
	case "tcp":
		return resolveVia(ctx, "tcp", addr, host)
	case "tls":
		return dotVia(ctx, addr, host)
	case "https":
		return dohVia(ctx, addr, host)
	case "udp", "":
		return resolveVia(ctx, "udp", addr, host)
	default:
		return nil, &net.DNSError{Err: "diagnostics: no prober for network " + network, IsNotFound: true}
	}
}

// CheckDnsLeaks compares the session's DNS path against the OS resolvers and
// the kill switch state, and flags OS-level encrypted DNS that bypasses the
// tunnel. It performs DNS probes only: one canary query per probeable
// tunnel resolver, in parallel, plus one verification round per plain
// (UDP/TCP) tunnel resolver for the dns-spoof cross-check (T014).
func CheckDnsLeaks(ctx context.Context, in DnsLeakInput) []DnsLeakCheck {
	if in.CanaryHost == "" {
		in.CanaryHost = canaryHost
	}
	if in.ResolveTimeout <= 0 {
		in.ResolveTimeout = defaultResolveTimeout
	}
	probe := in.Probe
	if probe == nil {
		probe = probeVia
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

	checks := make([]DnsLeakCheck, 0, 5)
	tunnelCheck, firstRound := checkTunnelDNS(ctx, in, tunnel, probe)
	checks = append(checks, tunnelCheck)
	checks = append(checks, checkSystemResolvers(tunnel, normalizedSystem, in.DnsHijacked, in.KillSwitchArmed))
	checks = append(checks, checkEncryptedDNS(in))
	checks = append(checks, checkKillSwitchDNS(in.KillSwitchArmed))
	checks = append(checks, checkDnsSpoof(ctx, in, firstRound, probe))
	return checks
}

// checkDnsSpoof runs the T014 spoof comparison over the tunnel's
// plain-DNS resolvers: the tunnel check's own canary answers are the
// first round, and one verification round per resolver runs here, so
// the whole leak check adds exactly one query per plain resolver.
// Bogus and inconsistent verdicts are leaks of trust (the DNS path is
// lying); unresolved and NXDOMAIN are reported without the leak flag —
// no evidence, no accusation. System resolvers are deliberately not
// queried here: this pipeline's contract is tunnel-path probes only;
// cross-checking the system path is a separate, explicitly triggered
// measurement (DetectDnsSpoof).
func checkDnsSpoof(ctx context.Context, in DnsLeakInput, firstRound map[string][]string, probe func(context.Context, string, string, string) ([]string, error)) DnsLeakCheck {
	check := DnsLeakCheck{
		ID:       DnsLeakSpoofDNS,
		Label:    DnsLeakLabelSpoofDNS,
		Expected: "every tunnel resolver agrees on " + in.CanaryHost,
	}
	var targets []SpoofTarget
	for _, r := range in.TunnelResolvers {
		network, addr, skip := canaryTarget(r)
		if skip == "" && (network == "udp" || network == "tcp") {
			targets = append(targets, SpoofTarget{Network: network, Addr: addr})
		}
	}
	if len(targets) == 0 {
		check.Actual = "no plain-DNS tunnel resolver to cross-check"
		return check
	}
	rep := CompareDnsSpoof(ctx, targets, in.CanaryHost, firstRound, probe)
	if len(rep.Evidence) > 0 {
		check.Actual = rep.Evidence[0]
	} else {
		check.Actual = rep.Verdict.String()
	}
	switch rep.Verdict {
	case DnsSpoofBogus, DnsSpoofInconsistent:
		check.Leaked = true
		check.FixHint = DnsLeakFixUseEncryptedDNS
	}
	return check
}

// canaryTarget maps a tunnel resolver to the probe that can exercise it.
// A non-empty skip explains honestly why the resolver cannot be probed
// instead of silently passing it.
func canaryTarget(r TunnelResolver) (network, addr, skip string) {
	switch t := strings.ToLower(strings.TrimSpace(r.Transport)); t {
	case "", "udp", "system":
		return "udp", hostPort(r.Address, r.Port, 53), ""
	case "tcp":
		return "tcp", hostPort(r.Address, r.Port, 53), ""
	case "tls":
		return "tls", hostPort(r.Address, r.Port, 853), ""
	case "https":
		return "https", dohEndpoint(r), ""
	case "quic", "h3":
		return "", "", "no QUIC prober"
	case "fakeip":
		return "", "", "synthetic answers"
	default:
		return "", "", "unknown transport " + t
	}
}

// hostPort joins a resolver address with its port, applying the transport
// default when the port is 0 and omitting the default port for display.
func hostPort(address string, port, def uint16) string {
	host := strings.Trim(strings.TrimSpace(address), "[]")
	if ip, err := netip.ParseAddr(host); err == nil {
		host = ip.String()
	}
	if port == 0 {
		port = def
	}
	if port == def {
		return host
	}
	return net.JoinHostPort(host, strconv.Itoa(int(port)))
}

// dohEndpoint builds the DoH URL for a tunnel resolver: a configured URL
// is used as-is, a bare address becomes https://addr/dns-query.
func dohEndpoint(r TunnelResolver) string {
	a := strings.TrimSpace(r.Address)
	if strings.Contains(a, "://") {
		return a
	}
	host := strings.Trim(a, "[]")
	if ip, err := netip.ParseAddr(host); err == nil {
		host = ip.String()
	}
	if r.Port != 0 && r.Port != 443 {
		return "https://" + net.JoinHostPort(host, strconv.Itoa(int(r.Port))) + "/dns-query"
	}
	return "https://" + host + "/dns-query"
}

// checkTunnelDNS verifies the session configures its own resolvers and
// canary-probes every probeable one in parallel: a broken second resolver
// behind a working first one must not pass silently. Probe failures are
// outages, not leaks, and are reported as such without raising the flag.
func checkTunnelDNS(ctx context.Context, in DnsLeakInput, tunnel []string, probe func(context.Context, string, string, string) ([]string, error)) (DnsLeakCheck, map[string][]string) {
	check := DnsLeakCheck{
		ID:       DnsLeakTunnelDNS,
		Label:    DnsLeakLabelTunnelDNS,
		Expected: displayList(tunnel),
	}
	if len(tunnel) == 0 {
		check.Actual = "(none)"
		check.Leaked = true
		check.FixHint = DnsLeakFixConfigureTunnel
		return check, nil
	}
	type target struct {
		network, addr, name string
	}
	var targets []target
	var skipped []string
	for _, r := range in.TunnelResolvers {
		network, addr, skip := canaryTarget(r)
		name := strings.TrimSpace(r.Address)
		if name == "" {
			name = "(empty)"
		}
		switch {
		case skip != "":
			skipped = append(skipped, name+" (not probed: "+skip+")")
		case addr == "":
			skipped = append(skipped, name+" (not probed: empty address)")
		default:
			targets = append(targets, target{network: network, addr: addr, name: name})
		}
	}
	timeout := in.ResolveTimeout
	if deadline, ok := ctx.Deadline(); ok {
		if left := time.Until(deadline); left < timeout {
			timeout = left
		}
	}
	if timeout <= 0 {
		check.Actual = "canary skipped: no time left"
		return check, nil
	}
	if len(targets) == 0 {
		check.Actual = displayList(tunnel) + " (canary not probed: " + strings.Join(skipped, "; ") + ")"
		return check, nil
	}
	results := make([]string, len(targets))
	// firstRound carries each resolver's answers to the spoof
	// cross-check (T014): it is the first of its two rounds, the
	// verification round runs in checkDnsSpoof.
	firstRound := make(map[string][]string, len(targets))
	var wg sync.WaitGroup
	var firstMu sync.Mutex
	for i, tg := range targets {
		wg.Add(1)
		go func() {
			defer wg.Done()
			qctx, cancel := context.WithTimeout(ctx, timeout)
			defer cancel()
			ips, err := probe(qctx, tg.network, tg.addr, in.CanaryHost)
			if err != nil {
				// A failing tunnel resolver is an outage, not a leak:
				// report it honestly without raising the leak flag.
				results[i] = tg.name + ": unreachable"
				return
			}
			results[i] = tg.name + ": " + displayList(ips)
			firstMu.Lock()
			firstRound[tg.addr] = ips
			firstMu.Unlock()
		}()
	}
	wg.Wait()
	parts := append(results, skipped...)
	check.Actual = "canary " + in.CanaryHost + ": " + strings.Join(parts, "; ")
	return check, firstRound
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

// encryptedEndpoint normalizes one tunnel resolver's encrypted-DNS endpoint
// to a comparable form ("tls:1.1.1.1", "https:dns.google"), or "" when the
// transport is not encrypted DNS.
func encryptedEndpoint(r TunnelResolver) string {
	switch strings.ToLower(strings.TrimSpace(r.Transport)) {
	case "tls":
		host := strings.Trim(strings.TrimSpace(r.Address), "[]")
		if ip, err := netip.ParseAddr(host); err == nil {
			host = ip.String()
		}
		if r.Port != 0 && r.Port != 853 {
			return "tls:" + net.JoinHostPort(host, strconv.Itoa(int(r.Port)))
		}
		return "tls:" + host
	case "https":
		u := strings.TrimSpace(r.Address)
		if !strings.Contains(u, "://") {
			u = "https://" + strings.Trim(u, "[]")
		}
		h := u
		if i := strings.Index(h, "://"); i >= 0 {
			h = h[i+3:]
		}
		if i := strings.Index(h, "/"); i >= 0 {
			h = h[:i]
		}
		if hh, pp, err := net.SplitHostPort(h); err == nil && pp == "443" {
			h = hh
		}
		h = strings.ToLower(strings.Trim(h, "[]"))
		if ip, err := netip.ParseAddr(h); err == nil {
			h = ip.String()
		}
		return "https:" + h
	default:
		return ""
	}
}

// checkEncryptedDNS flags OS-configured encrypted DNS (DoT/DoH) endpoints
// that answer outside the tunnel's DNS path. Plain-DNS hijacking captures
// port 53 only, so DnsHijacked deliberately does not suppress this check:
// an OS with DNSOverTLS enabled leaks around a hijacked tunnel while
// system-resolvers reports clean. An armed kill switch blocks the bypass,
// so it suppresses the leak.
func checkEncryptedDNS(in DnsLeakInput) DnsLeakCheck {
	check := DnsLeakCheck{
		ID:    DnsLeakEncryptedDNS,
		Label: DnsLeakLabelEncryptedDNS,
	}
	var tunnelEnc []string
	for _, r := range in.TunnelResolvers {
		if e := encryptedEndpoint(r); e != "" {
			tunnelEnc = append(tunnelEnc, e)
		}
	}
	check.Expected = displayList(tunnelEnc)
	sys := in.SystemEncryptedDNS
	if sys == nil {
		sys = SystemEncryptedDNS()
	}
	if sys == nil {
		// Detection is not implemented on this OS; say so instead of
		// pretending the bypass does not exist.
		check.Actual = "(unknown: OS encrypted DNS not detected)"
		return check
	}
	normalized := make([]string, 0, len(sys))
	for _, s := range sys {
		if e := encryptedEndpoint(TunnelResolver{Address: s, Transport: "tls"}); e != "" {
			normalized = append(normalized, e)
		}
	}
	check.Actual = displayList(normalized)
	if len(normalized) == 0 || in.KillSwitchArmed {
		return check
	}
	inTunnel := make(map[string]bool, len(tunnelEnc))
	for _, t := range tunnelEnc {
		inTunnel[t] = true
	}
	var outside []string
	for _, s := range normalized {
		if !inTunnel[s] {
			outside = append(outside, s)
		}
	}
	if len(outside) > 0 {
		check.Leaked = true
		check.FixHint = DnsLeakFixReviewEncrypted
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
