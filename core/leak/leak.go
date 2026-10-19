// Package leak implements the core's egress self-tests: active probes that
// verify no byte leaves the machine outside the tunnel.
//
// Every test is a pure judge over an injected probe outcome, plus a default
// prober that performs the real network attempt. Unit tests inject outcomes
// to prove the judges detect an open leak as well as a blocked path, and
// point the real probers at loopback fixtures to prove they observe replies.
//
// A probe reports one of three outcomes: Open (a reply arrived, so the path
// is not blocked), Blocked (no reply: timeout, refused, unreachable), or
// Unknown (the probe could not run, for example without the privileges for
// raw sockets). Unknown never passes: a self-test must not claim protection
// it could not verify.
package leak

import (
	"context"
	"fmt"
	"net"
	"strings"
	"time"

	"golang.org/x/net/icmp"
	"golang.org/x/net/ipv4"

	"github.com/levvs-one/sora-client/core/diagnostics"
)

// Test IDs. They are a stable contract with the UI: the interface switches
// on them, never on free text.
const (
	// TestDirectDNS sends a DNS query straight at a public resolver,
	// bypassing the tunnel configuration. With the kill switch armed it
	// must not get an answer.
	TestDirectDNS = "direct-dns"
	// TestIPv6 tries to reach an IPv6 resolver directly. With an IPv4-only
	// tunnel an answer means IPv6 escapes the tunnel.
	TestIPv6 = "ipv6"
	// TestICMPEcho sends an ICMP echo request directly. The kill switch
	// must block it like any other non-tunnel traffic.
	TestICMPEcho = "icmp-echo"
	// TestSystemResolvers verifies the OS resolvers point into the tunnel.
	TestSystemResolvers = "system-resolvers"
)

// Localization keys for the test titles shown in the UI.
const (
	LabelDirectDNS       = "leakTest.check.directDns"
	LabelIPv6            = "leakTest.check.ipv6"
	LabelICMPEcho        = "leakTest.check.icmpEcho"
	LabelSystemResolvers = "leakTest.check.systemResolvers"
)

// Outcome is what one direct probe observed on the wire.
type Outcome int

const (
	// OutcomeOpen means a reply arrived: the path is not blocked.
	OutcomeOpen Outcome = iota
	// OutcomeBlocked means no reply arrived: timeout, refusal, or no route.
	OutcomeBlocked
	// OutcomeUnknown means the probe could not run at all.
	OutcomeUnknown
)

// DefaultProbeTimeout bounds one network probe.
const DefaultProbeTimeout = 4 * time.Second

// canaryHost is the fixed, documented name the DNS probes ask for. It is a
// stable public anycast name; resolving it issues a single DNS query and no
// other traffic.
const canaryHost = "one.one.one.one"

// Input configures one self-test run.
type Input struct {
	// KillSwitchArmed reports whether the firewall blocks non-tunnel
	// traffic, including while the engine is down.
	KillSwitchArmed bool
	// TunnelUp reports whether the engine is connected and carrying
	// traffic.
	TunnelUp bool
	// DirectCaptured reports whether plain sockets are captured by the
	// tunnel while it is up (the system/TUN mode). In application (proxy)
	// mode direct sockets bypass the tunnel.
	DirectCaptured bool
	// TunnelIPv6 reports whether the tunnel itself carries IPv6.
	TunnelIPv6 bool
	// DnsHijacked reports whether the tunnel captures plain DNS traffic.
	DnsHijacked bool
	// TunnelResolvers are the resolver addresses the session routes DNS
	// through.
	TunnelResolvers []string
	// SystemResolvers overrides OS resolver detection. Nil detects the
	// resolvers the way the diagnostics package does. Tests inject
	// fixtures here.
	SystemResolvers []string
	// ProbeTimeout bounds one network probe; zero selects
	// DefaultProbeTimeout.
	ProbeTimeout time.Duration

	// DirectDNSTarget is the "ip:port" the direct DNS probe queries.
	// Empty selects the public default. Tests point it at a loopback
	// fixture.
	DirectDNSTarget string
	// IPv6Target is the "ip:port" the IPv6 probe queries. Empty selects
	// the public default.
	IPv6Target string
	// ICMPHost is the host the ICMP probe pings. Empty selects the public
	// default.
	ICMPHost string

	// ProbeDirectDNS performs the direct DNS attempt. Nil selects the
	// real network prober. Tests inject fixed outcomes here.
	ProbeDirectDNS func(ctx context.Context, target string) Outcome
	// ProbeIPv6 performs the direct IPv6 attempt. Nil selects the real
	// network prober.
	ProbeIPv6 func(ctx context.Context, target string) Outcome
	// ProbeICMP performs the direct ICMP attempt. Nil selects the real
	// network prober.
	ProbeICMP func(ctx context.Context, host string) Outcome
}

// Test describes one self-test for the wire contract.
type Test struct {
	ID    string
	Label string
}

// Tests lists every self-test in run order.
func Tests() []Test {
	return []Test{
		{ID: TestDirectDNS, Label: LabelDirectDNS},
		{ID: TestIPv6, Label: LabelIPv6},
		{ID: TestICMPEcho, Label: LabelICMPEcho},
		{ID: TestSystemResolvers, Label: LabelSystemResolvers},
	}
}

// Result is the verdict of one self-test. Details describe what the probe
// observed; they never carry secrets, only public canary addresses and
// resolver IPs.
type Result struct {
	ID       string
	Label    string
	Pass     bool
	Skipped  bool
	Details  string
	Duration time.Duration
}

// Run executes the requested tests in order, streaming nothing but
// returning one result per test. An empty ids runs every test; an unknown
// id is an error. Each test runs under ctx, so the caller bounds the whole
// run with a deadline.
func Run(ctx context.Context, in Input, ids []string) ([]Result, error) {
	catalog := Tests()
	byID := make(map[string]Test, len(catalog))
	for _, t := range catalog {
		byID[t.ID] = t
	}
	selected := catalog
	if len(ids) > 0 {
		selected = selected[:0]
		for _, id := range ids {
			t, ok := byID[id]
			if !ok {
				return nil, fmt.Errorf("leak: unknown test %q", id)
			}
			selected = append(selected, t)
		}
	}
	in = withDefaults(in)
	results := make([]Result, 0, len(selected))
	for _, t := range selected {
		start := time.Now()
		res := runOne(ctx, in, t)
		res.Duration = time.Since(start)
		results = append(results, res)
	}
	return results, nil
}

// withDefaults fills probe targets, the timeout, and the real probers.
func withDefaults(in Input) Input {
	if in.ProbeTimeout <= 0 {
		in.ProbeTimeout = DefaultProbeTimeout
	}
	if in.DirectDNSTarget == "" {
		in.DirectDNSTarget = "9.9.9.9:53"
	}
	if in.IPv6Target == "" {
		in.IPv6Target = "[2606:4700:4700::1111]:53"
	}
	if in.ICMPHost == "" {
		in.ICMPHost = "9.9.9.9"
	}
	if in.ProbeDirectDNS == nil {
		in.ProbeDirectDNS = probeDNSReply
	}
	if in.ProbeIPv6 == nil {
		in.ProbeIPv6 = probeDNSReply
	}
	if in.ProbeICMP == nil {
		in.ProbeICMP = probeICMPReply
	}
	return in
}

// runOne judges a single test.
func runOne(ctx context.Context, in Input, t Test) Result {
	res := Result{ID: t.ID, Label: t.Label}
	timeout := in.ProbeTimeout
	if deadline, ok := ctx.Deadline(); ok {
		if left := time.Until(deadline); left < timeout {
			timeout = left
		}
	}
	if timeout <= 0 {
		res.Details = "not run: no time left in the run deadline"
		return res
	}
	pctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	switch t.ID {
	case TestDirectDNS:
		if skip, why := directSkipped(in); skip {
			res.Pass, res.Skipped, res.Details = true, true, why
		} else {
			res.Pass, res.Skipped, res.Details = judgeDirect(in, in.ProbeDirectDNS(pctx, in.DirectDNSTarget), "DNS", in.DirectDNSTarget)
		}
	case TestIPv6:
		if skip, why := directSkipped(in); skip {
			res.Pass, res.Skipped, res.Details = true, true, why
		} else {
			res.Pass, res.Skipped, res.Details = judgeIPv6(pctx, in)
		}
	case TestICMPEcho:
		if skip, why := directSkipped(in); skip {
			res.Pass, res.Skipped, res.Details = true, true, why
		} else {
			res.Pass, res.Skipped, res.Details = judgeDirect(in, in.ProbeICMP(pctx, in.ICMPHost), "ICMP echo", in.ICMPHost)
		}
	case TestSystemResolvers:
		res.Pass, res.Skipped, res.Details = judgeSystemResolvers(in)
	}
	return res
}

// directSkipped reports whether direct probes are vacuous: while the tunnel
// is up in system (TUN) mode plain sockets are captured by the tunnel
// device, so a reply would travel inside the tunnel and the probe cannot
// tell a leak from normal operation. The test skips instead of guessing.
func directSkipped(in Input) (bool, string) {
	if in.TunnelUp && in.DirectCaptured {
		return true, "not applicable while the tunnel captures direct sockets; a reply would travel inside the tunnel"
	}
	return false, ""
}

// judgeDirect judges the probes that must be blocked by the kill switch.
// A reply is a real observation of unblocked direct traffic; without the
// kill switch it is reported as unprotected egress rather than passed.
func judgeDirect(in Input, outcome Outcome, kind, target string) (pass, skipped bool, details string) {
	host := target
	if h, _, err := net.SplitHostPort(target); err == nil {
		host = h
	}
	switch outcome {
	case OutcomeOpen:
		if in.KillSwitchArmed {
			return false, false, "direct " + kind + " query to " + host + " was answered while the kill switch is armed: traffic escapes the firewall"
		}
		return false, false, "direct " + kind + " query to " + host + " was answered (kill switch disarmed, so nothing blocks it)"
	case OutcomeBlocked:
		if in.KillSwitchArmed {
			return true, false, "direct " + kind + " query to " + host + " was blocked by the kill switch"
		}
		return true, false, "direct " + kind + " query to " + host + " received no answer"
	default:
		return false, false, "direct " + kind + " probe could not run; the path is unverified"
	}
}

// judgeIPv6 judges the IPv6 probe. A tunnel that carries IPv6 has no
// separate IPv6 path to block, so the test is skipped there. Anywhere else
// an IPv6 answer means IPv6 bypasses the tunnel.
func judgeIPv6(ctx context.Context, in Input) (pass, skipped bool, details string) {
	if in.TunnelIPv6 {
		return true, true, "tunnel carries IPv6; no separate IPv6 path to block"
	}
	switch in.ProbeIPv6(ctx, in.IPv6Target) {
	case OutcomeOpen:
		return false, false, "IPv6 query to " + in.IPv6Target + " was answered while the tunnel is IPv4-only: IPv6 escapes the tunnel"
	case OutcomeBlocked:
		return true, false, "direct IPv6 traffic to " + in.IPv6Target + " was blocked"
	default:
		return false, false, "IPv6 probe could not run; the IPv6 path is unverified"
	}
}

// judgeSystemResolvers verifies the OS resolvers point into the tunnel.
// Hijacked DNS or an armed kill switch keeps OS resolvers from leaking,
// so the test passes with the observed values still reported.
func judgeSystemResolvers(in Input) (pass, skipped bool, details string) {
	system := in.SystemResolvers
	if system == nil {
		system = diagnostics.SystemResolvers()
	}
	tunnel := normalizeAll(in.TunnelResolvers)
	observed := normalizeAll(system)
	actual := "system: " + displayList(observed) + "; tunnel: " + displayList(tunnel)
	if len(observed) == 0 {
		return false, false, "OS resolvers not detected; cannot verify (" + actual + ")"
	}
	if in.DnsHijacked || in.KillSwitchArmed {
		return true, false, actual + " (covered by DNS hijack or the kill switch)"
	}
	inTunnel := make(map[string]bool, len(tunnel))
	for _, t := range tunnel {
		inTunnel[t] = true
	}
	var outside []string
	for _, s := range observed {
		if !inTunnel[s] {
			outside = append(outside, s)
		}
	}
	if len(outside) > 0 {
		return false, false, "resolvers outside the tunnel: " + displayList(outside) + " (" + actual + ")"
	}
	return true, false, actual
}

// normalizeAll canonicalizes resolver addresses for comparison.
func normalizeAll(values []string) []string {
	out := make([]string, 0, len(values))
	for _, v := range values {
		if n := normalizeResolver(v); n != "" {
			out = append(out, n)
		}
	}
	return out
}

// normalizeResolver canonicalizes one resolver: bare IPs are normalized,
// "ip:port" keeps a non-default port, bracketed IPv6 is unwrapped.
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
	if ip := net.ParseIP(host); ip != nil {
		if port == "" || port == "53" {
			return ip.String()
		}
		return net.JoinHostPort(ip.String(), port)
	}
	return s
}

// displayList joins values for display; "(none)" marks an empty set.
func displayList(values []string) string {
	if len(values) == 0 {
		return "(none)"
	}
	return strings.Join(values, ", ")
}

// probeDNSReply sends one DNS query straight at target ("ip:port") and
// reports whether any reply datagram arrived. Any reply means the direct
// path is open; anything else means it is blocked.
func probeDNSReply(ctx context.Context, target string) Outcome {
	conn, err := (&net.Dialer{}).DialContext(ctx, "udp", target)
	if err != nil {
		return OutcomeBlocked
	}
	defer func() { _ = conn.Close() }()
	if deadline, ok := ctx.Deadline(); ok {
		_ = conn.SetDeadline(deadline)
	}
	if _, err := conn.Write(dnsQuery(canaryHost)); err != nil {
		return OutcomeBlocked
	}
	buf := make([]byte, 512)
	if _, err := conn.Read(buf); err != nil {
		return OutcomeBlocked
	}
	return OutcomeOpen
}

// dnsQuery builds a minimal DNS A query for host.
func dnsQuery(host string) []byte {
	q := []byte{0x12, 0x34, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	for _, label := range strings.Split(host, ".") {
		q = append(q, byte(len(label)))
		q = append(q, label...)
	}
	q = append(q, 0x00, 0x00, 0x01, 0x00, 0x01)
	return q
}

// probeICMPReply sends one ICMP echo request straight at host and reports
// whether an echo reply arrived. It tries the unprivileged datagram socket
// first and falls back to a raw socket; when neither can be created the
// path is unverified rather than blocked.
func probeICMPReply(ctx context.Context, host string) Outcome {
	dst, err := net.ResolveIPAddr("ip4", host)
	if err != nil {
		return OutcomeUnknown
	}
	for _, network := range []string{"udp4", "ip4:icmp"} {
		if outcome, ok := icmpAttempt(ctx, network, dst); ok {
			return outcome
		}
	}
	return OutcomeUnknown
}

// icmpAttempt tries one ICMP socket type. The second return value reports
// whether the socket could be created at all.
func icmpAttempt(ctx context.Context, network string, dst *net.IPAddr) (Outcome, bool) {
	conn, err := icmp.ListenPacket(network, "0.0.0.0")
	if err != nil {
		return OutcomeUnknown, false
	}
	defer func() { _ = conn.Close() }()
	if deadline, ok := ctx.Deadline(); ok {
		_ = conn.SetDeadline(deadline)
	}
	req, err := (&icmp.Message{
		Type: ipv4.ICMPTypeEcho,
		Code: 0,
		Body: &icmp.Echo{ID: 0x5e4a, Seq: 1, Data: []byte("sora-leak")},
	}).Marshal(nil)
	if err != nil {
		return OutcomeUnknown, true
	}
	if _, err := conn.WriteTo(req, dst); err != nil {
		return OutcomeBlocked, true
	}
	reply := make([]byte, 512)
	for {
		n, _, err := conn.ReadFrom(reply)
		if err != nil {
			return OutcomeBlocked, true
		}
		msg, err := icmp.ParseMessage(1, reply[:n])
		if err != nil {
			continue
		}
		if msg.Type == ipv4.ICMPTypeEchoReply {
			return OutcomeOpen, true
		}
	}
}
