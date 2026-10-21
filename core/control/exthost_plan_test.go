package control

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestExtensionProxyUsesSelectedVPNOrChain(t *testing.T) {
	for _, chain := range [][]string{nil, {"a", "b", "c"}} {
		in := chainTestPlan()
		in.Routing = &corev1.RoutingOptions{ProxyTarget: "a"}
		in.Chain = chain
		in.Routes = []*corev1.RoutingRule{{Destination: "full:api.example.com", OutboundId: "direct"}}
		plan, err := planFromProto(in, "fetch", nil)
		if err != nil {
			t.Fatal(err)
		}
		if err := prepareExtensionProxy(plan, in); err != nil {
			t.Fatal(err)
		}
		want := "a"
		if len(chain) > 0 {
			want = "c"
		}
		x := plan.ExtensionProxy
		if x == nil || x.Target != want || x.Port == 0 || !plan.IsVPNTarget(x.Target) {
			t.Fatal("private listener did not select the VPN exit")
		}
		if err := plan.Validate(); err != nil {
			t.Fatal(err)
		}
		first := *x
		if err := prepareExtensionProxy(plan, in); err != nil {
			t.Fatal(err)
		}
		if first.Username == plan.ExtensionProxy.Username || first.Password == plan.ExtensionProxy.Password {
			t.Fatal("credentials were reused between sessions")
		}
	}
}

func TestExtensionProxyNotPreparedForServerlessSelection(t *testing.T) {
	for _, protocol := range []engine.Protocol{engine.ProtocolDirect, engine.ProtocolBypass, engine.ProtocolXrayProfile} {
		p := &engine.Plan{Outbounds: []engine.Outbound{{ID: "selection", Protocol: protocol}}, Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "selection"}}}
		if err := prepareExtensionProxy(p, &corev1.SessionPlan{}); err != nil {
			t.Fatal(err)
		}
		if p.ExtensionProxy != nil {
			t.Fatalf("opened private inbound for %s", protocol)
		}
	}
}
