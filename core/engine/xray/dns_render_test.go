package xray

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// dnsServers renders a plan carrying exactly the given resolvers and
// returns the dns.servers strings of the Xray config.
func dnsServers(t *testing.T, servers []engine.DNSServer) []string {
	t.Helper()
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS = engine.DNS{Enabled: true, Servers: servers}
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		DNS struct {
			Servers []string `json:"servers"`
		} `json:"dns"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	return cfg.DNS.Servers
}

// TestRenderDNSResolverTable pins the CENSOR-LEAK E1 invariant: on
// the Xray engine every resolver follows the plan's routing, for
// every transport and regardless of ProxyOnly. Xray's "+local"
// forms bypass routing and dial directly through Freedom, so no
// ordinary resolver may carry one; the single exception is DoQ,
// which the pinned Xray (26.10.17) implements only in local mode
// (DOQL) — a routed "quic://" spelling is not a DoQ client there.
// Resolvers that were routed before the fix (plain, tls, system and
// every ProxyOnly resolver) keep their exact pre-fix spelling.
func TestRenderDNSResolverTable(t *testing.T) {
	cases := []struct {
		name   string
		server engine.DNSServer
		want   string
	}{
		{"system", engine.DNSServer{Tag: "s", Transport: engine.DNSSystem, Address: "system"}, "localhost"},
		{"plain", engine.DNSServer{Tag: "s", Transport: engine.DNSPlain, Address: "1.1.1.1"}, "1.1.1.1"},
		{"plain unset transport", engine.DNSServer{Tag: "s", Address: "1.1.1.1"}, "1.1.1.1"},
		{"tcp", engine.DNSServer{Tag: "s", Transport: engine.DNSTCP, Address: "1.1.1.1", Port: 5353}, "tcp://1.1.1.1:5353"},
		// The pin has no DNS-over-TLS nameserver client at all; the
		// spelling is pinned as-is (and never with "+local") pending
		// the DoT decision recorded in the E1 fix report.
		{"tls", engine.DNSServer{Tag: "s", Transport: engine.DNSTLS, Address: "1.1.1.1", Port: 853}, "tls://1.1.1.1:853"},
		{"https", engine.DNSServer{Tag: "s", Transport: engine.DNSHTTPS, Address: "1.1.1.1", Port: 443}, "https://1.1.1.1:443/dns-query"},
		// Pin exception: DoQ exists on the pin only as DOQL.
		{"quic", engine.DNSServer{Tag: "s", Transport: engine.DNSQUIC, Address: "9.9.9.9", Port: 853}, "quic+local://9.9.9.9:853"},
	}
	for _, tc := range cases {
		for _, proxyOnly := range []bool{false, true} {
			s := tc.server
			s.ProxyOnly = proxyOnly
			got := dnsServers(t, []engine.DNSServer{s})
			if len(got) != 1 || got[0] != tc.want {
				t.Errorf("%s (ProxyOnly=%v): servers = %v, want [%s]", tc.name, proxyOnly, got, tc.want)
			}
			if strings.Contains(got[0], "+local") && tc.server.Transport != engine.DNSQUIC {
				t.Errorf("%s (ProxyOnly=%v): %q carries +local (direct dialing) outside the DoQ pin exception", tc.name, proxyOnly, got[0])
			}
		}
	}
}

// TestBinaryAcceptsDNSResolverTable is the `xray run -test`
// acceptance for the E1 table: one render carrying every transport
// in both ProxyOnly states must be accepted by the pinned binary.
func TestBinaryAcceptsDNSResolverTable(t *testing.T) {
	bin := os.Getenv("SORA_XRAY_BIN")
	if bin == "" {
		dir := os.Getenv("SORA_ENGINES_DIR")
		if dir == "" {
			t.Skip("set SORA_ENGINES_DIR or SORA_XRAY_BIN to check the render with Xray")
		}
		bin = filepath.Join(dir, "xray")
	}
	var servers []engine.DNSServer
	for _, proxyOnly := range []bool{false, true} {
		servers = append(servers,
			engine.DNSServer{Tag: "sys", Transport: engine.DNSSystem, Address: "system", ProxyOnly: proxyOnly},
			engine.DNSServer{Tag: "plain", Transport: engine.DNSPlain, Address: "1.1.1.1", ProxyOnly: proxyOnly},
			engine.DNSServer{Tag: "tcp", Transport: engine.DNSTCP, Address: "1.1.1.1", Port: 5353, ProxyOnly: proxyOnly},
			engine.DNSServer{Tag: "tls", Transport: engine.DNSTLS, Address: "1.1.1.1", Port: 853, ProxyOnly: proxyOnly},
			engine.DNSServer{Tag: "https", Transport: engine.DNSHTTPS, Address: "1.1.1.1", Port: 443, ProxyOnly: proxyOnly},
			engine.DNSServer{Tag: "quic", Transport: engine.DNSQUIC, Address: "9.9.9.9", Port: 853, ProxyOnly: proxyOnly},
		)
	}
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS = engine.DNS{Enabled: true, Servers: servers}
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	cfg := filepath.Join(t.TempDir(), "config.json")
	if err := os.WriteFile(cfg, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	if out, err := exec.CommandContext(t.Context(), bin, "run", "-test", "-c", cfg).CombinedOutput(); err != nil {
		t.Fatalf("xray refused the E1 DNS table render: %v\n%s\n--- render ---\n%s", err, out, raw)
	}
}
