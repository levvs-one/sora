package diagnostics_test

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/diagnostics"
)

func leakInput() diagnostics.DnsLeakInput {
	return diagnostics.DnsLeakInput{
		TunnelResolvers: []diagnostics.TunnelResolver{
			{Address: "1.1.1.1", Transport: "udp"},
		},
		SystemResolvers:    []string{"1.1.1.1"},
		SystemEncryptedDNS: []string{},
		CanaryHost:         "canary.example",
		Probe: func(ctx context.Context, network, addr, host string) ([]string, error) {
			return []string{"203.0.113.7"}, nil
		},
	}
}

func findCheck(checks []diagnostics.DnsLeakCheck, id string) *diagnostics.DnsLeakCheck {
	for i := range checks {
		if checks[i].ID == id {
			return &checks[i]
		}
	}
	return nil
}

func TestCheckDnsLeaks_Clean(t *testing.T) {
	checks := diagnostics.CheckDnsLeaks(context.Background(), leakInput())
	if len(checks) != 4 {
		t.Fatalf("expected 4 checks, got %d", len(checks))
	}
	for _, c := range checks {
		if c.Leaked {
			t.Errorf("check %q unexpectedly leaked (actual %q)", c.ID, c.Actual)
		}
		if c.Label == "" || c.ID == "" {
			t.Errorf("check %+v misses ID or label", c)
		}
	}
	tunnel := findCheck(checks, diagnostics.DnsLeakTunnelDNS)
	if tunnel == nil || !strings.Contains(tunnel.Actual, "203.0.113.7") {
		t.Errorf("tunnel-dns should report the canary answer, got %+v", tunnel)
	}
	if enc := findCheck(checks, diagnostics.DnsLeakEncryptedDNS); enc == nil {
		t.Error("missing encrypted-dns check")
	}
}

func TestCheckDnsLeaks_LeakDetected(t *testing.T) {
	in := leakInput()
	in.SystemResolvers = []string{"192.0.2.53"} // ISP resolver, outside the tunnel.
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	sys := findCheck(checks, diagnostics.DnsLeakSystemResolvers)
	if sys == nil {
		t.Fatal("missing system-resolvers check")
	}
	if !sys.Leaked {
		t.Errorf("expected leak for outside resolver, got %+v", sys)
	}
	if sys.FixHint != diagnostics.DnsLeakFixReviewResolvers {
		t.Errorf("expected review hint, got %q", sys.FixHint)
	}
	if !strings.Contains(sys.Expected, "1.1.1.1") || !strings.Contains(sys.Actual, "192.0.2.53") {
		t.Errorf("expected/actual not reported, got %+v", sys)
	}
}

func TestCheckDnsLeaks_HijackSuppressesLeak(t *testing.T) {
	in := leakInput()
	in.SystemResolvers = []string{"192.0.2.53"}
	in.DnsHijacked = true
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	sys := findCheck(checks, diagnostics.DnsLeakSystemResolvers)
	if sys == nil || sys.Leaked {
		t.Errorf("hijacked DNS must not report a leak, got %+v", sys)
	}
}

func TestCheckDnsLeaks_KillSwitchSuppressesLeak(t *testing.T) {
	in := leakInput()
	in.SystemResolvers = []string{"192.0.2.53"}
	in.KillSwitchArmed = true
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	sys := findCheck(checks, diagnostics.DnsLeakSystemResolvers)
	if sys == nil || sys.Leaked {
		t.Errorf("armed kill switch must not report a leak, got %+v", sys)
	}
	ks := findCheck(checks, diagnostics.DnsLeakKillSwitchDNS)
	if ks == nil || ks.Leaked || ks.FixHint != "" {
		t.Errorf("armed kill switch check should be clean, got %+v", ks)
	}
}

func TestCheckDnsLeaks_KillSwitchWarning(t *testing.T) {
	checks := diagnostics.CheckDnsLeaks(context.Background(), leakInput())
	ks := findCheck(checks, diagnostics.DnsLeakKillSwitchDNS)
	if ks == nil {
		t.Fatal("missing killswitch-dns check")
	}
	if ks.Leaked {
		t.Errorf("unarmed kill switch is a warning, not a leak: %+v", ks)
	}
	if ks.FixHint != diagnostics.DnsLeakFixEnableKillSwitch {
		t.Errorf("expected enable hint, got %q", ks.FixHint)
	}
}

func TestCheckDnsLeaks_NoTunnelResolvers(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = nil
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	tunnel := findCheck(checks, diagnostics.DnsLeakTunnelDNS)
	if tunnel == nil || !tunnel.Leaked {
		t.Errorf("missing tunnel DNS must leak, got %+v", tunnel)
	}
	if tunnel.FixHint != diagnostics.DnsLeakFixConfigureTunnel {
		t.Errorf("expected configure hint, got %+v", tunnel)
	}
}

func TestCheckDnsLeaks_CanaryFailureIsNotALeak(t *testing.T) {
	in := leakInput()
	in.Probe = func(ctx context.Context, network, addr, host string) ([]string, error) {
		return nil, errors.New("no route to host")
	}
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	tunnel := findCheck(checks, diagnostics.DnsLeakTunnelDNS)
	if tunnel == nil || tunnel.Leaked {
		t.Errorf("canary failure is an outage, not a leak: %+v", tunnel)
	}
	if !strings.Contains(tunnel.Actual, "unreachable") {
		t.Errorf("canary failure should be reported honestly, got %q", tunnel.Actual)
	}
}

func TestCheckDnsLeaks_CanaryHonorsTransport(t *testing.T) {
	for _, tc := range []struct {
		transport, network, addr string
	}{
		{"udp", "udp", "9.9.9.9"},
		{"tcp", "tcp", "9.9.9.9"},
		{"tls", "tls", "9.9.9.9"},
		{"https", "https", "https://dns.example/dns-query"},
	} {
		in := leakInput()
		in.TunnelResolvers = []diagnostics.TunnelResolver{
			{Address: tc.addr, Transport: tc.transport},
		}
		var gotNetwork, gotAddr string
		in.Probe = func(ctx context.Context, network, addr, host string) ([]string, error) {
			gotNetwork, gotAddr = network, addr
			return []string{"203.0.113.7"}, nil
		}
		diagnostics.CheckDnsLeaks(context.Background(), in)
		if gotNetwork != tc.network {
			t.Errorf("transport %q: probe network = %q, want %q", tc.transport, gotNetwork, tc.network)
		}
		if !strings.Contains(gotAddr, strings.TrimPrefix(strings.TrimPrefix(tc.addr, "https://"), "http://")) {
			t.Errorf("transport %q: probe addr = %q, want it to carry %q", tc.transport, gotAddr, tc.addr)
		}
	}
}

// TestCheckDnsLeaks_ProbesEveryResolver locks the completeness fix: a
// broken second resolver behind a working first one must show up in the
// report instead of passing silently.
func TestCheckDnsLeaks_ProbesEveryResolver(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "1.1.1.1", Transport: "udp"},
		{Address: "9.9.9.9", Transport: "udp"},
	}
	var probed []string
	in.Probe = func(ctx context.Context, network, addr, host string) ([]string, error) {
		probed = append(probed, addr)
		if addr == "9.9.9.9" {
			return nil, errors.New("refused")
		}
		return []string{"203.0.113.7"}, nil
	}
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	tunnel := findCheck(checks, diagnostics.DnsLeakTunnelDNS)
	if tunnel == nil {
		t.Fatal("missing tunnel-dns check")
	}
	if len(probed) != 2 {
		t.Errorf("expected both resolvers probed, got %q", probed)
	}
	if !strings.Contains(tunnel.Actual, "1.1.1.1: 203.0.113.7") || !strings.Contains(tunnel.Actual, "9.9.9.9: unreachable") {
		t.Errorf("per-resolver results not reported, got %q", tunnel.Actual)
	}
	if tunnel.Leaked {
		t.Errorf("probe failure is an outage, not a leak: %+v", tunnel)
	}
}

func TestCheckDnsLeaks_CanaryUsesNonDefaultPort(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "9.9.9.9", Port: 5353, Transport: "udp"},
	}
	var gotAddr, gotHost string
	in.Probe = func(ctx context.Context, network, addr, host string) ([]string, error) {
		gotAddr, gotHost = addr, host
		return []string{"203.0.113.7"}, nil
	}
	diagnostics.CheckDnsLeaks(context.Background(), in)
	if gotAddr != "9.9.9.9:5353" {
		t.Errorf("canary should use first plain resolver with port, got %q", gotAddr)
	}
	if gotHost != "canary.example" {
		t.Errorf("canary host not passed through, got %q", gotHost)
	}
}

// TestCheckDnsLeaks_DoHIsProbed locks the encrypted-transport fix: a DoH
// tunnel resolver gets a real probe, not a silent "not probed" pass.
func TestCheckDnsLeaks_DoHIsProbed(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "https://dns.example/dns-query", Transport: "https"},
	}
	probed := false
	in.Probe = func(ctx context.Context, network, addr, host string) ([]string, error) {
		if network != "https" {
			t.Errorf("DoH resolver must be probed as https, got %q", network)
		}
		probed = true
		return []string{"203.0.113.7"}, nil
	}
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	if !probed {
		t.Error("DoH tunnel resolver was not probed")
	}
	tunnel := findCheck(checks, diagnostics.DnsLeakTunnelDNS)
	if tunnel == nil || tunnel.Leaked {
		t.Errorf("working DoH resolver is not a leak: %+v", tunnel)
	}
	if !strings.Contains(tunnel.Actual, "203.0.113.7") {
		t.Errorf("DoH canary answer not reported, got %q", tunnel.Actual)
	}
}

func TestCheckDnsLeaks_BrokenDoHIsOutageNotLeak(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "https://dns.example/dns-query", Transport: "https"},
	}
	in.Probe = func(ctx context.Context, network, addr, host string) ([]string, error) {
		return nil, errors.New("500")
	}
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	tunnel := findCheck(checks, diagnostics.DnsLeakTunnelDNS)
	if tunnel == nil || tunnel.Leaked {
		t.Errorf("broken DoH is an outage, not a leak: %+v", tunnel)
	}
	if !strings.Contains(tunnel.Actual, "unreachable") {
		t.Errorf("broken DoH should be reported honestly, got %q", tunnel.Actual)
	}
}

func TestCheckDnsLeaks_UnprobableTransportsReported(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "1.1.1.1", Transport: "h3"},
		{Address: "2.2.2.2", Transport: "fakeip"},
	}
	probed := false
	in.Probe = func(ctx context.Context, network, addr, host string) ([]string, error) {
		probed = true
		return []string{"203.0.113.7"}, nil
	}
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	if probed {
		t.Error("h3/fakeip transports must not be probed")
	}
	tunnel := findCheck(checks, diagnostics.DnsLeakTunnelDNS)
	if tunnel == nil || tunnel.Leaked {
		t.Errorf("unprobable transports are not a leak: %+v", tunnel)
	}
	if !strings.Contains(tunnel.Actual, "no QUIC prober") || !strings.Contains(tunnel.Actual, "synthetic answers") {
		t.Errorf("skip reasons must be reported, got %q", tunnel.Actual)
	}
}

func TestCheckDnsLeaks_RespectsContextDeadline(t *testing.T) {
	in := leakInput()
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()
	start := time.Now()
	diagnostics.CheckDnsLeaks(ctx, in)
	if elapsed := time.Since(start); elapsed > 5*time.Second {
		t.Errorf("check overran its deadline: %v", elapsed)
	}
}

func TestCheckDnsLeaks_BracketedIPv6(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "2001:db8::1", Transport: "udp"},
	}
	in.SystemResolvers = []string{"[2001:db8::1]"}
	var gotAddr string
	in.Probe = func(ctx context.Context, network, addr, host string) ([]string, error) {
		gotAddr = addr
		return []string{"203.0.113.7"}, nil
	}
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	sys := findCheck(checks, diagnostics.DnsLeakSystemResolvers)
	if sys == nil || sys.Leaked {
		t.Errorf("bracketed IPv6 must normalize equal: %+v", sys)
	}
	if gotAddr != "2001:db8::1" {
		t.Errorf("canary addr should be bare normalized IP, got %q", gotAddr)
	}
}

func TestCheckDnsLeaks_IPv6WithPort(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "2001:db8::1", Port: 5353, Transport: "udp"},
	}
	var gotAddr string
	in.Probe = func(ctx context.Context, network, addr, host string) ([]string, error) {
		gotAddr = addr
		return []string{"203.0.113.7"}, nil
	}
	diagnostics.CheckDnsLeaks(context.Background(), in)
	if gotAddr != "[2001:db8::1]:5353" {
		t.Errorf("IPv6 with port must be bracketed once, got %q", gotAddr)
	}
}

// TestCheckDnsLeaks_EncryptedBypassLeak locks the DoH-past-the-tunnel
// vector: OS-configured DoT bypasses plain-DNS hijacking, so DnsHijacked
// must not suppress this check.
func TestCheckDnsLeaks_EncryptedBypassLeak(t *testing.T) {
	in := leakInput()
	in.SystemEncryptedDNS = []string{"8.8.8.8"}
	in.DnsHijacked = true // hijack covers port 53 only; must not hide DoT
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	enc := findCheck(checks, diagnostics.DnsLeakEncryptedDNS)
	if enc == nil {
		t.Fatal("missing encrypted-dns check")
	}
	if !enc.Leaked {
		t.Errorf("OS DoT outside the tunnel must leak even with hijack: %+v", enc)
	}
	if enc.FixHint != diagnostics.DnsLeakFixReviewEncrypted {
		t.Errorf("expected encrypted review hint, got %q", enc.FixHint)
	}
}

func TestCheckDnsLeaks_EncryptedBypassCoveredByTunnel(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "8.8.8.8", Transport: "tls"},
	}
	in.SystemEncryptedDNS = []string{"8.8.8.8"}
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	enc := findCheck(checks, diagnostics.DnsLeakEncryptedDNS)
	if enc == nil || enc.Leaked {
		t.Errorf("tunnel's own DoT endpoint is not a bypass: %+v", enc)
	}
}

func TestCheckDnsLeaks_EncryptedBypassKillSwitch(t *testing.T) {
	in := leakInput()
	in.SystemEncryptedDNS = []string{"8.8.8.8"}
	in.KillSwitchArmed = true
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	enc := findCheck(checks, diagnostics.DnsLeakEncryptedDNS)
	if enc == nil || enc.Leaked {
		t.Errorf("armed kill switch blocks the bypass: %+v", enc)
	}
}

func TestCheckDnsLeaks_EncryptedNoneConfigured(t *testing.T) {
	in := leakInput()
	in.SystemEncryptedDNS = []string{}
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	enc := findCheck(checks, diagnostics.DnsLeakEncryptedDNS)
	if enc == nil || enc.Leaked {
		t.Errorf("no OS encrypted DNS must be clean: %+v", enc)
	}
	if !strings.Contains(enc.Actual, "(none)") {
		t.Errorf("empty encrypted DNS should show (none), got %q", enc.Actual)
	}
}
