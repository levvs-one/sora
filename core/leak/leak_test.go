package leak

import (
	"context"
	"errors"
	"net"
	"strings"
	"testing"
	"time"
)

// openProbe simulates a leak: the direct path answered.
func openProbe(context.Context, string) Outcome { return OutcomeOpen }

// blockedProbe simulates a holding kill switch: no answer.
func blockedProbe(context.Context, string) Outcome { return OutcomeBlocked }

// unknownProbe simulates a probe that could not run.
func unknownProbe(context.Context, string) Outcome { return OutcomeUnknown }

func baseInput() Input {
	return Input{
		KillSwitchArmed: true,
		TunnelResolvers: []string{"10.0.0.1"},
		SystemResolvers: []string{"10.0.0.1"},
		ProbeDirectDNS:  blockedProbe,
		ProbeIPv6:       blockedProbe,
		ProbeICMP:       blockedProbe,
	}
}

func runSingle(t *testing.T, in Input, id string) Result {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	results, err := Run(ctx, in, []string{id})
	if err != nil {
		t.Fatalf("Run(%s) = %v", id, err)
	}
	if len(results) != 1 {
		t.Fatalf("Run(%s) returned %d results", id, len(results))
	}
	return results[0]
}

func TestDirectDNSDetectsOpenLeak(t *testing.T) {
	in := baseInput()
	in.ProbeDirectDNS = openProbe
	res := runSingle(t, in, TestDirectDNS)
	if res.Pass {
		t.Fatalf("direct-dns passed with an open direct path and armed kill switch: %+v", res)
	}
	if !strings.Contains(res.Details, "kill switch is armed") {
		t.Fatalf("details do not name the armed kill switch: %q", res.Details)
	}
}

func TestDirectDNSPassesWhenBlocked(t *testing.T) {
	res := runSingle(t, baseInput(), TestDirectDNS)
	if !res.Pass || res.Skipped {
		t.Fatalf("direct-dns should pass when blocked: %+v", res)
	}
}

func TestDirectDNSOpenWithoutKillSwitchStillFails(t *testing.T) {
	// Without the kill switch an open direct path is unprotected egress,
	// not a false alarm: the test must say so instead of passing.
	in := baseInput()
	in.KillSwitchArmed = false
	in.ProbeDirectDNS = openProbe
	res := runSingle(t, in, TestDirectDNS)
	if res.Pass {
		t.Fatalf("direct-dns passed with an open path and disarmed kill switch: %+v", res)
	}
	if !strings.Contains(res.Details, "disarmed") {
		t.Fatalf("details do not explain the disarmed kill switch: %q", res.Details)
	}
}

func TestDirectDNSSkippedWhenTunnelCaptures(t *testing.T) {
	// While the tunnel is up in TUN mode a direct query travels inside the
	// tunnel, so the probe cannot distinguish a leak: it must skip, not
	// pass or fail.
	called := false
	in := baseInput()
	in.TunnelUp = true
	in.DirectCaptured = true
	in.ProbeDirectDNS = func(_ context.Context, _ string) Outcome {
		called = true
		return OutcomeOpen
	}
	res := runSingle(t, in, TestDirectDNS)
	if !res.Pass || !res.Skipped {
		t.Fatalf("direct-dns should skip while the tunnel captures: %+v", res)
	}
	if called {
		t.Fatal("probe ran even though the test skipped it")
	}
}

func TestDirectDNSUnknownProbeFails(t *testing.T) {
	in := baseInput()
	in.ProbeDirectDNS = unknownProbe
	res := runSingle(t, in, TestDirectDNS)
	if res.Pass {
		t.Fatalf("direct-dns passed with an unverified path: %+v", res)
	}
}

func TestIPv6DetectsOpenLeak(t *testing.T) {
	in := baseInput()
	in.ProbeIPv6 = openProbe
	res := runSingle(t, in, TestIPv6)
	if res.Pass {
		t.Fatalf("ipv6 passed with an open IPv6 path on an IPv4-only tunnel: %+v", res)
	}
}

func TestIPv6PassesWhenBlocked(t *testing.T) {
	res := runSingle(t, baseInput(), TestIPv6)
	if !res.Pass || res.Skipped {
		t.Fatalf("ipv6 should pass when blocked: %+v", res)
	}
}

func TestIPv6SkippedWhenTunnelCaptures(t *testing.T) {
	// While the tunnel is up in TUN mode a direct IPv6 query travels
	// inside the tunnel like any other direct socket: a tunnel-side DNS
	// hijack would answer it and look like an IPv6 leak. The probe cannot
	// distinguish, so it must skip, not fail.
	called := false
	in := baseInput()
	in.TunnelUp = true
	in.DirectCaptured = true
	in.ProbeIPv6 = func(_ context.Context, _ string) Outcome {
		called = true
		return OutcomeOpen
	}
	res := runSingle(t, in, TestIPv6)
	if !res.Pass || !res.Skipped {
		t.Fatalf("ipv6 should skip while the tunnel captures: %+v", res)
	}
	if called {
		t.Fatal("probe ran even though the test skipped it")
	}
}

func TestIPv6SkippedWithIPv6Tunnel(t *testing.T) {
	called := false
	in := baseInput()
	in.TunnelIPv6 = true
	in.ProbeIPv6 = func(_ context.Context, _ string) Outcome {
		called = true
		return OutcomeOpen
	}
	res := runSingle(t, in, TestIPv6)
	if !res.Pass || !res.Skipped {
		t.Fatalf("ipv6 should skip with an IPv6 tunnel: %+v", res)
	}
	if called {
		t.Fatal("probe ran even though the test skipped it")
	}
}

func TestICMPDetectsOpenLeak(t *testing.T) {
	in := baseInput()
	in.ProbeICMP = openProbe
	res := runSingle(t, in, TestICMPEcho)
	if res.Pass {
		t.Fatalf("icmp-echo passed with an open ICMP path and armed kill switch: %+v", res)
	}
}

func TestICMPPassesWhenBlocked(t *testing.T) {
	res := runSingle(t, baseInput(), TestICMPEcho)
	if !res.Pass || res.Skipped {
		t.Fatalf("icmp-echo should pass when blocked: %+v", res)
	}
}

func TestSystemResolversPassWhenInsideTunnel(t *testing.T) {
	res := runSingle(t, baseInput(), TestSystemResolvers)
	if !res.Pass {
		t.Fatalf("system-resolvers should pass when the OS uses the tunnel resolver: %+v", res)
	}
}

func TestSystemResolversDetectsOutsideResolver(t *testing.T) {
	in := baseInput()
	in.KillSwitchArmed = false
	in.SystemResolvers = []string{"10.0.0.1", "8.8.8.8"}
	res := runSingle(t, in, TestSystemResolvers)
	if res.Pass {
		t.Fatalf("system-resolvers passed with 8.8.8.8 outside the tunnel: %+v", res)
	}
	if !strings.Contains(res.Details, "8.8.8.8") {
		t.Fatalf("details do not name the outside resolver: %q", res.Details)
	}
}

func TestSystemResolversCoveredByKillSwitch(t *testing.T) {
	in := baseInput()
	in.SystemResolvers = []string{"8.8.8.8"}
	res := runSingle(t, in, TestSystemResolvers)
	if !res.Pass {
		t.Fatalf("system-resolvers should pass when the kill switch covers the OS resolver: %+v", res)
	}
}

func TestSystemResolversCoveredByHijack(t *testing.T) {
	in := baseInput()
	in.KillSwitchArmed = false
	in.DNSHijacked = true
	in.SystemResolvers = []string{"8.8.8.8"}
	res := runSingle(t, in, TestSystemResolvers)
	if !res.Pass {
		t.Fatalf("system-resolvers should pass when DNS is hijacked into the tunnel: %+v", res)
	}
}

func TestSystemResolversUnknownFails(t *testing.T) {
	in := baseInput()
	in.SystemResolvers = []string{}
	res := runSingle(t, in, TestSystemResolvers)
	if res.Pass {
		t.Fatalf("system-resolvers passed with undetected OS resolvers: %+v", res)
	}
}

func TestRunRejectsUnknownID(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if _, err := Run(ctx, baseInput(), []string{"nope"}); err == nil {
		t.Fatal("Run accepted an unknown test id")
	}
}

func TestRunAllByDefault(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	results, err := Run(ctx, baseInput(), nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(results) != len(Tests()) {
		t.Fatalf("Run(nil) returned %d results, want %d", len(results), len(Tests()))
	}
	for _, r := range results {
		if r.ID == "" || r.Label == "" || r.Details == "" {
			t.Fatalf("result missing fields: %+v", r)
		}
	}
}

func TestDetailsCarryNoSecrets(t *testing.T) {
	// The leak package never sees credentials; assert the obvious: no
	// result may echo the control authenticator-shaped material it never
	// receives. This guards future edits that might thread secrets in.
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	results, err := Run(ctx, baseInput(), nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, r := range results {
		if strings.Contains(r.Details, "token") || strings.Contains(r.Details, "secret") || strings.Contains(r.Details, "authenticator") {
			t.Fatalf("details mention credentials: %q", r.Details)
		}
	}
}

// replyFixture serves one canned datagram reply per query. The reply goes
// to replyAddr: a side channel the test sets, because this sandbox delivers
// UDP only to listening sockets, so the fixture cannot rely on the query's
// source address the way a production resolver does.
func replyFixture(t *testing.T, replyAddr *net.UDPAddr) (target string, stop func()) {
	t.Helper()
	conn, err := (&net.ListenConfig{}).ListenPacket(context.Background(), "udp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	done := make(chan struct{})
	go func() {
		defer close(done)
		buf := make([]byte, 512)
		for {
			n, _, err := conn.ReadFrom(buf)
			if err != nil {
				return
			}
			back, err := (&net.Dialer{}).DialContext(context.Background(), "udp", replyAddr.String())
			if err != nil {
				continue
			}
			_, _ = back.Write(append([]byte{0xde, 0xad}, buf[:n]...))
			_ = back.Close()
		}
	}()
	return conn.LocalAddr().String(), func() {
		_ = conn.Close()
		<-done
	}
}

// loopbackDNSProbe mirrors probeDNSReply's classification (any datagram
// back means the path is open) but receives on a listening socket, which is
// the only UDP receiver this sandbox delivers to. The query bytes and the
// verdict logic are identical to the production prober.
func loopbackDNSProbe(recv *net.UDPConn) func(context.Context, string) Outcome {
	return func(ctx context.Context, target string) Outcome {
		send, err := (&net.Dialer{}).DialContext(ctx, "udp", target)
		if err != nil {
			return OutcomeBlocked
		}
		defer func() { _ = send.Close() }()
		if deadline, ok := ctx.Deadline(); ok {
			_ = recv.SetDeadline(deadline)
		}
		if _, err := send.Write(dnsQuery(canaryHost)); err != nil {
			return OutcomeBlocked
		}
		buf := make([]byte, 512)
		if _, _, err := recv.ReadFrom(buf); err != nil {
			return OutcomeBlocked
		}
		return OutcomeOpen
	}
}

func TestRealDNSProberDetectsOpenPath(t *testing.T) {
	recv, err := net.ListenUDP("udp", &net.UDPAddr{IP: net.ParseIP("127.0.0.1")})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = recv.Close() }()
	target, stop := replyFixture(t, recv.LocalAddr().(*net.UDPAddr))
	defer stop()
	in := baseInput()
	in.DirectDNSTarget = target
	in.ProbeDirectDNS = loopbackDNSProbe(recv)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if got := in.ProbeDirectDNS(ctx, target); got != OutcomeOpen {
		t.Fatalf("DNS prober reported %v for a replying fixture", got)
	}
	res := runSingle(t, in, TestDirectDNS)
	if res.Pass {
		t.Fatalf("direct-dns passed against a replying local fixture: %+v", res)
	}
}

func TestRealDNSProberDetectsBlockedPath(t *testing.T) {
	// Nothing listens here: the production prober must observe "blocked".
	ln, err := (&net.ListenConfig{}).ListenPacket(context.Background(), "udp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	target := ln.LocalAddr().String()
	_ = ln.Close()
	in := baseInput()
	in.DirectDNSTarget = target
	in.ProbeDirectDNS = nil // use the production prober
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if got := probeDNSReply(ctx, target); got != OutcomeBlocked {
		t.Fatalf("production DNS prober reported %v for a closed port", got)
	}
	res := runSingle(t, in, TestDirectDNS)
	if !res.Pass {
		t.Fatalf("direct-dns failed against a closed port: %+v", res)
	}
}

func TestRealICMPProberReturnsAnOutcome(t *testing.T) {
	// No internet is assumed: the prober must return a valid outcome,
	// never panic or hang past its deadline.
	in := baseInput()
	in.ProbeICMP = nil
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	switch got := probeICMPReply(ctx, "127.0.0.1"); got {
	case OutcomeOpen, OutcomeBlocked, OutcomeUnknown:
	default:
		t.Fatalf("real ICMP prober returned an invalid outcome %v", got)
	}
}

func TestNormalizeResolver(t *testing.T) {
	cases := map[string]string{
		"8.8.8.8":         "8.8.8.8",
		"8.8.8.8:53":      "8.8.8.8",
		"8.8.8.8:5353":    "8.8.8.8:5353",
		"[::1]":           "::1",
		"[::1]:53":        "::1",
		"  1.1.1.1  ":     "1.1.1.1",
		"dns.example.com": "dns.example.com",
		"":                "",
	}
	for in, want := range cases {
		if got := normalizeResolver(in); got != want {
			t.Errorf("normalizeResolver(%q) = %q, want %q", in, got, want)
		}
	}
}

// tunnelInput is a session whose plain sockets are captured by the tunnel:
// the only mode where a direct dial provably traverses the tunnel path.
func tunnelInput() Input {
	in := baseInput()
	in.TunnelUp = true
	in.DirectCaptured = true
	return in
}

func TestTunnelConnectivityPassesOnHandshake(t *testing.T) {
	in := tunnelInput()
	in.TunnelTarget = "203.0.11.1:443"
	in.ProbeTunnel = func(context.Context, string) (time.Duration, error) { return 84 * time.Millisecond, nil }
	res := runSingle(t, in, TestTunnelConnectivity)
	if !res.Pass || res.Skipped {
		t.Fatalf("tunnel-connectivity should pass on a handshake: %+v", res)
	}
	if !strings.Contains(res.Details, "through the tunnel") || !strings.Contains(res.Details, "84ms") {
		t.Fatalf("details do not report the tunnel path and the RTT: %q", res.Details)
	}
}

func TestTunnelConnectivityFailsWithRealCause(t *testing.T) {
	in := tunnelInput()
	in.ProbeTunnel = func(context.Context, string) (time.Duration, error) {
		return 0, errors.New("dial tcp 203.0.11.1:443: i/o timeout")
	}
	res := runSingle(t, in, TestTunnelConnectivity)
	if res.Pass {
		t.Fatalf("tunnel-connectivity passed on a failed dial: %+v", res)
	}
	for _, want := range []string{"i/o timeout", "connected does not mean traffic flows", troubleshootingURL} {
		if !strings.Contains(res.Details, want) {
			t.Fatalf("details %q do not name %q", res.Details, want)
		}
	}
}

func TestTunnelTestsSkippedInProxyMode(t *testing.T) {
	in := tunnelInput()
	in.DirectCaptured = false
	for _, id := range []string{TestTunnelConnectivity, TestTunnelDNS} {
		res := runSingle(t, in, id)
		if !res.Pass || !res.Skipped {
			t.Fatalf("%s should skip (passing) in proxy mode: %+v", id, res)
		}
		if !strings.Contains(res.Details, "proxy mode") {
			t.Fatalf("%s skip does not name proxy mode: %q", id, res.Details)
		}
	}
}

func TestTunnelTestsSkippedWhenTunnelDown(t *testing.T) {
	in := tunnelInput()
	in.TunnelUp = false
	for _, id := range []string{TestTunnelConnectivity, TestTunnelDNS} {
		res := runSingle(t, in, id)
		if !res.Pass || !res.Skipped {
			t.Fatalf("%s should skip when the tunnel is down: %+v", id, res)
		}
	}
}

func TestTunnelDNSSkippedWithoutResolvers(t *testing.T) {
	in := tunnelInput()
	in.TunnelResolvers = nil
	res := runSingle(t, in, TestTunnelDNS)
	if !res.Pass || !res.Skipped {
		t.Fatalf("tunnel-dns should skip without tunnel resolvers: %+v", res)
	}
}

func TestTunnelDNSPassesWithAnswers(t *testing.T) {
	in := tunnelInput()
	in.ProbeTunnelDNS = func(context.Context, string, string) ([]string, error) {
		return []string{"1.1.1.1", "1.0.0.1"}, nil
	}
	res := runSingle(t, in, TestTunnelDNS)
	if !res.Pass || res.Skipped {
		t.Fatalf("tunnel-dns should pass with answers: %+v", res)
	}
	if !strings.Contains(res.Details, "one.one.one.one") || !strings.Contains(res.Details, "10.0.0.1") {
		t.Fatalf("details do not name the canary and the resolver: %q", res.Details)
	}
}

func TestTunnelDNSFailsWithRealCause(t *testing.T) {
	in := tunnelInput()
	in.ProbeTunnelDNS = func(context.Context, string, string) ([]string, error) {
		return nil, errors.New("read udp 10.0.0.1:53: i/o timeout")
	}
	res := runSingle(t, in, TestTunnelDNS)
	if res.Pass {
		t.Fatalf("tunnel-dns passed on a failed query: %+v", res)
	}
	if !strings.Contains(res.Details, "i/o timeout") || !strings.Contains(res.Details, troubleshootingURL) {
		t.Fatalf("details do not name the cause and the doc: %q", res.Details)
	}
}

func TestTunnelDNSFailsOnEmptyAnswer(t *testing.T) {
	in := tunnelInput()
	in.ProbeTunnelDNS = func(context.Context, string, string) ([]string, error) { return nil, nil }
	res := runSingle(t, in, TestTunnelDNS)
	if res.Pass {
		t.Fatalf("tunnel-dns passed on an empty answer: %+v", res)
	}
}

func TestTunnelConnectivityEndToEndOnLoopback(t *testing.T) {
	ln, err := (&net.ListenConfig{}).Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = ln.Close() }()
	go func() {
		conn, err := ln.Accept()
		if err == nil {
			_ = conn.Close()
		}
	}()
	in := tunnelInput()
	in.TunnelTarget = ln.Addr().String()
	in.ProbeTunnel = nil // production prober through the real judge
	res := runSingle(t, in, TestTunnelConnectivity)
	if !res.Pass || res.Skipped {
		t.Fatalf("tunnel-connectivity should pass against a loopback listener: %+v", res)
	}
}

func TestTunnelTCPProberHandshakeOnLoopback(t *testing.T) {
	ln, err := (&net.ListenConfig{}).Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = ln.Close() }()
	go func() {
		conn, err := ln.Accept()
		if err == nil {
			_ = conn.Close()
		}
	}()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	rtt, err := probeTunnelTCP(ctx, ln.Addr().String())
	if err != nil {
		t.Fatalf("production TCP prober failed on loopback: %v", err)
	}
	if rtt <= 0 {
		t.Fatalf("production TCP prober reported non-positive RTT: %v", rtt)
	}
}

func TestTunnelTCPProberFailsOnClosedPort(t *testing.T) {
	ln, err := (&net.ListenConfig{}).Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	target := ln.Addr().String()
	_ = ln.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if _, err := probeTunnelTCP(ctx, target); err == nil {
		t.Fatal("production TCP prober succeeded on a closed port")
	}
}

func TestTunnelDNSProberFailsOnClosedPort(t *testing.T) {
	pc, err := (&net.ListenConfig{}).ListenPacket(context.Background(), "udp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	target := pc.LocalAddr().String()
	_ = pc.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if _, err := probeTunnelDNS(ctx, target, canaryHost); err == nil {
		t.Fatal("production tunnel-DNS prober succeeded on a closed port")
	}
}

// fakeDNSAnswer crafts a minimal response to query: one A record for ip,
// with the answer name as a compression pointer to the question.
func fakeDNSAnswer(query []byte, ip net.IP) []byte {
	resp := make([]byte, 12)
	copy(resp[:2], query[:2]) // ID
	resp[2], resp[3] = 0x81, 0x80
	resp[4], resp[5] = 0x00, 0x01
	resp[6], resp[7] = 0x00, 0x01
	resp = append(resp, query[12:]...)
	resp = append(resp, 0xC0, 0x0C)             // name: pointer to the question
	resp = append(resp, 0x00, 0x01)             // TYPE A
	resp = append(resp, 0x00, 0x01)             // CLASS IN
	resp = append(resp, 0x00, 0x00, 0x00, 0x3C) // TTL 60
	v4 := ip.To4()
	resp = append(resp, 0x00, byte(len(v4)))
	resp = append(resp, v4...)
	return resp
}

func TestDNSAnswerRoundTrip(t *testing.T) {
	query := dnsQuery(canaryHost)
	raw := fakeDNSAnswer(query, net.ParseIP("203.0.113.7"))
	got := dnsAddresses(raw)
	if len(got) != 1 || got[0] != "203.0.113.7" {
		t.Fatalf("dnsAddresses parsed %v from a crafted answer", got)
	}
}

func TestDNSAddressesRejectsGarbage(t *testing.T) {
	for _, raw := range [][]byte{nil, {}, {1, 2, 3}, make([]byte, 12), dnsQuery(canaryHost)} {
		if got := dnsAddresses(raw); len(got) != 0 {
			t.Fatalf("dnsAddresses(%d bytes) = %v, want empty", len(raw), got)
		}
	}
}
