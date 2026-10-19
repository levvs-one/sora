package mihomo

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestDNSUsesTheRequestedTransportAndOutbound(t *testing.T) {
	d := engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "remote", Address: "1.1.1.1",
		Transport: engine.DNSTCP, Dialer: "private-link", ProxyOnly: true}}}
	cfg, err := buildDNS(d, engine.Options{}, map[string]string{"private-link": "private_link"})
	if err != nil {
		t.Fatal(err)
	}
	if len(cfg.Nameserver) != 1 || cfg.Nameserver[0] != "tcp://1.1.1.1#private_link" {
		t.Fatalf("remote-only DNS lost its TCP transport or dialer: %+v", cfg.Nameserver)
	}
	for _, server := range cfg.DefaultNameserver {
		if strings.Contains(server, "#") {
			t.Fatal("bootstrap DNS must not depend on the proxy it resolves")
		}
	}
	if _, err := buildDNS(d, engine.Options{}, nil); err == nil {
		t.Fatal("unknown DNS outbound silently became direct")
	}
}

// TestDNSH3ForcesHTTP3 locks the DoH3 rendering: an explicit h3:// choice
// must reach mihomo as a forced-H3 nameserver, never silently downgraded
// to HTTP/2 DoH.
func TestDNSH3ForcesHTTP3(t *testing.T) {
	d := engine.DNS{Enabled: true, Servers: []engine.DNSServer{{Tag: "doh3", Address: "1.1.1.1", Transport: engine.DNSH3}}}
	cfg, err := buildDNS(d, engine.Options{}, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(cfg.Nameserver) != 1 || cfg.Nameserver[0] != "https://1.1.1.1/dns-query?h3=true" {
		t.Fatalf("h3 must force HTTP/3 on the nameserver URL, got %+v", cfg.Nameserver)
	}
}

// TestFakeIPRendersFilterAndTTL locks the fake-ip tuning surface: the plan
// filter list replaces the built-in default, and FakeIPTTL reaches
// fake-ip-ttl instead of being silently dropped.
func TestFakeIPRendersFilterAndTTL(t *testing.T) {
	d := engine.DNS{Enabled: true, Mode: string(engine.DNSFakeIP)}
	cfg, err := buildDNS(d, engine.Options{}, nil)
	if err != nil {
		t.Fatal(err)
	}
	if cfg.EnhancedMode != "fake-ip" {
		t.Fatalf("mode = %q, want fake-ip", cfg.EnhancedMode)
	}
	if len(cfg.FakeIPFilter) != len(engine.DefaultFakeIPFilter) {
		t.Fatalf("default fake-ip-filter = %v, want the shared defaults", cfg.FakeIPFilter)
	}
	// S7: the defaults must carry the expanded NTP list and the STUN
	// wildcard; mihomo matches both natively.
	seen := map[string]bool{}
	for _, f := range cfg.FakeIPFilter {
		seen[f] = true
	}
	for _, want := range []string{"time.windows.com", "+.pool.ntp.org", "ntp.*.com", "+.stun.*.*"} {
		if !seen[want] {
			t.Errorf("default fake-ip-filter missing %q: %v", want, cfg.FakeIPFilter)
		}
	}
	// S7: the pool is unified across renderers — mihomo must render the
	// same default the sing-box renderer and the TUN preparer use.
	if cfg.FakeIPRange != engine.DefaultFakeIPRange {
		t.Fatalf("fake-ip-range = %q, want the shared default %q", cfg.FakeIPRange, engine.DefaultFakeIPRange)
	}
	if cfg.FakeIPTTL != nil {
		t.Fatalf("zero TTL must not render fake-ip-ttl, got %d", *cfg.FakeIPTTL)
	}
	d.FakeIPFilter = []string{"*.corp.example"}
	d.FakeIPTTL = 30
	cfg, err = buildDNS(d, engine.Options{}, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(cfg.FakeIPFilter) != 1 || cfg.FakeIPFilter[0] != "*.corp.example" {
		t.Fatalf("plan filter lost: %v", cfg.FakeIPFilter)
	}
	if cfg.FakeIPTTL == nil || *cfg.FakeIPTTL != 30 {
		t.Fatalf("fake-ip-ttl not rendered: %+v", cfg.FakeIPTTL)
	}
}

// TestDNSSkipVerifyAppendsCertParam covers the corporate-MITM escape hatch:
// DoT/DoH/DoQ upstreams with SkipVerify carry ?skip-cert-verify=true, plain
// UDP resolvers are unaffected.
func TestDNSSkipVerifyAppendsCertParam(t *testing.T) {
	d := engine.DNS{Enabled: true, Servers: []engine.DNSServer{
		{Tag: "dot", Address: "9.9.9.9", Transport: engine.DNSTLS, SkipVerify: true},
		{Tag: "doh", Address: "1.1.1.1", Transport: engine.DNSHTTPS, SkipVerify: true},
		{Tag: "plain", Address: "8.8.8.8", Transport: engine.DNSPlain, SkipVerify: true},
	}}
	cfg, err := buildDNS(d, engine.Options{}, nil)
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]bool{
		"tls://9.9.9.9?skip-cert-verify=true":             false,
		"https://1.1.1.1/dns-query?skip-cert-verify=true": false,
	}
	for _, ns := range cfg.Nameserver {
		if _, ok := want[ns]; ok {
			want[ns] = true
		}
		if strings.HasPrefix(ns, "8.8.8.8") && strings.Contains(ns, "skip-cert-verify") {
			t.Fatalf("plain UDP resolver must not carry skip-cert-verify: %q", ns)
		}
	}
	for ns, seen := range want {
		if !seen {
			t.Fatalf("nameserver %q missing from %v", ns, cfg.Nameserver)
		}
	}
}
