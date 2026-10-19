package xraytun

import (
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

func TestBridgeDoesNotSilentlyDiscardProcessRouting(t *testing.T) {
	e := &Engine{port: 12345, password: "test-private-password", xrayName: "xray.exe"}
	p := &engine.Plan{SessionID: "bridge-test",
		Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolDirect}},
		Tun:       engine.Tun{Enabled: true, Stack: "mixed"},
		DNS:       engine.DNS{Enabled: true, Mode: string(engine.DNSFakeIP)},
		Rules: []engine.Rule{{Type: engine.RuleProcess, Value: "telegram.exe", Target: "out"},
			{Type: engine.RuleMatchAll, Target: "direct"}}}
	if _, _, err := e.plans(p); errs.KeyOf(err) != errs.KeyPlanEngineUnsupported {
		t.Fatalf("a process cannot be recovered from SOCKS: %v", err)
	}
	for _, target := range []string{"direct", "reject"} {
		p.Rules[0].Target = target
		x, packet, err := e.plans(p)
		if runtime.GOOS != "windows" {
			if errs.KeyOf(err) != errs.KeyPlanEngineUnsupported {
				t.Fatalf("Linux bridge requires native process routing: %v", err)
			}
			continue
		}
		if err != nil {
			t.Fatal(err)
		}
		if packet.Rules[0].Type != engine.RuleProcess || packet.Rules[0].Value != "xray.exe" ||
			packet.Rules[0].Target != "direct" || packet.Rules[1] != p.Rules[0] {
			t.Fatal("the packet engine lost an engine exclusion or process rule")
		}
		if x.Tun.Enabled || x.DNS.Mode == string(engine.DNSFakeIP) || !p.Tun.Enabled ||
			p.DNS.Mode != string(engine.DNSFakeIP) {
			t.Fatal("packet settings must belong to one engine without changing the original plan")
		}
	}
}

// TestBridgeDowngradesDoH3ForTheXrayLeg locks the h3 split: the packet
// engine keeps answering client queries over HTTP/3, while Xray's own
// leg (proxy hostnames only) steps down to DoH — Xray has no H3 DNS
// transport and would fail Validate on h3:// otherwise. The original
// plan must stay untouched.
func TestBridgeDowngradesDoH3ForTheXrayLeg(t *testing.T) {
	e := &Engine{port: 12345, password: "test-private-password", xrayName: "xray"}
	p := &engine.Plan{SessionID: "bridge-doh3",
		Outbounds: []engine.Outbound{{ID: "out", Protocol: engine.ProtocolDirect}},
		Tun:       engine.Tun{Enabled: true, Stack: "mixed"},
		DNS: engine.DNS{Enabled: true, Servers: []engine.DNSServer{
			{Tag: "dns-1", Transport: engine.DNSH3, Address: "1.1.1.1"},
			{Tag: "dns-2", Transport: engine.DNSHTTPS, Address: "8.8.8.8"},
		}},
		Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "out"}}}
	x, packet, err := e.plans(p)
	if err != nil {
		t.Fatalf("plans: %v", err)
	}
	if got := x.DNS.Servers[0].Transport; got != engine.DNSHTTPS {
		t.Fatalf("xray leg transport = %q, want https (downgraded from h3)", got)
	}
	if got := x.DNS.Servers[1].Transport; got != engine.DNSHTTPS {
		t.Fatalf("xray leg must leave https alone, got %q", got)
	}
	if got := packet.DNS.Servers[0].Transport; got != engine.DNSH3 {
		t.Fatalf("packet-engine leg transport = %q, want h3 (kept)", got)
	}
	if p.DNS.Servers[0].Transport != engine.DNSH3 {
		t.Fatal("plans() mutated the caller's plan: h3 downgrade leaked out")
	}
}
