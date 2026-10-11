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
