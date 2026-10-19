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
		SystemResolvers: []string{"1.1.1.1"},
		CanaryHost:      "canary.example",
		Resolve: func(ctx context.Context, resolverAddr, host string) ([]string, error) {
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
	if len(checks) != 3 {
		t.Fatalf("expected 3 checks, got %d", len(checks))
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
		t.Errorf("expected configure hint, got %q", tunnel.FixHint)
	}
}

func TestCheckDnsLeaks_CanaryFailureIsNotALeak(t *testing.T) {
	in := leakInput()
	in.Resolve = func(ctx context.Context, resolverAddr, host string) ([]string, error) {
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

func TestCheckDnsLeaks_CanaryUsesFirstPlainResolver(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "9.9.9.9", Port: 5353, Transport: "udp"},
		{Address: "1.1.1.1", Transport: "udp"},
	}
	var gotAddr, gotHost string
	in.Resolve = func(ctx context.Context, resolverAddr, host string) ([]string, error) {
		gotAddr, gotHost = resolverAddr, host
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

func TestCheckDnsLeaks_EncryptedTransportNotProbed(t *testing.T) {
	in := leakInput()
	in.TunnelResolvers = []diagnostics.TunnelResolver{
		{Address: "https://dns.google/dns-query", Transport: "https"},
	}
	probed := false
	in.Resolve = func(ctx context.Context, resolverAddr, host string) ([]string, error) {
		probed = true
		return []string{"203.0.113.7"}, nil
	}
	checks := diagnostics.CheckDnsLeaks(context.Background(), in)
	if probed {
		t.Error("encrypted transports must not be probed with plain DNS")
	}
	tunnel := findCheck(checks, diagnostics.DnsLeakTunnelDNS)
	if tunnel == nil || tunnel.Leaked {
		t.Errorf("configured (if unprobable) tunnel DNS is not a leak: %+v", tunnel)
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
	in.Resolve = func(ctx context.Context, resolverAddr, host string) ([]string, error) {
		gotAddr = resolverAddr
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
	in.Resolve = func(ctx context.Context, resolverAddr, host string) ([]string, error) {
		gotAddr = resolverAddr
		return []string{"203.0.113.7"}, nil
	}
	diagnostics.CheckDnsLeaks(context.Background(), in)
	if gotAddr != "[2001:db8::1]:5353" {
		t.Errorf("IPv6 with port must be bracketed once, got %q", gotAddr)
	}
}
