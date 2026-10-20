package control

import (
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func chainTestPlan() *corev1.SessionPlan {
	return &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{
			{Id: "a", DisplayName: "A", Protocol: "vless", Endpoint: &corev1.Endpoint{Host: "a.example.com", Port: 443}},
			{Id: "b", DisplayName: "B", Protocol: "vless", Endpoint: &corev1.Endpoint{Host: "b.example.com", Port: 443}},
			{Id: "c", DisplayName: "C", Protocol: "vless", Endpoint: &corev1.Endpoint{Host: "c.example.com", Port: 443}},
		},
		Routes: []*corev1.RoutingRule{{Destination: "all", OutboundId: "a"}},
	}
}

func TestPlanFromProtoBuildsChain(t *testing.T) {
	in := chainTestPlan()
	in.Chain = []string{"a", "b", "c"}
	plan, err := planFromProto(in, "s-1", nil)
	if err != nil {
		t.Fatalf("planFromProto: %v", err)
	}
	via := map[string]string{}
	for _, o := range plan.Outbounds {
		via[o.ID] = o.Via
	}
	if via["a"] != "b" || via["b"] != "c" || via["c"] != "" {
		t.Fatalf("wrong chain links: %v", via)
	}
	if !plan.RequiredFeatures()[engine.FeatureChains] {
		t.Fatal("a chained plan must require the chains feature")
	}
}

func TestPlanFromProtoRejectsBadChains(t *testing.T) {
	for _, chain := range [][]string{
		{"a"},                         // too short
		{"a", "b", "c", "d"},          // too long
		{"a", "a"},                    // repeat
		{"a", "ghost"},                // unknown
	} {
		in := chainTestPlan()
		in.Chain = chain
		if _, err := planFromProto(in, "s-1", nil); err == nil {
			t.Errorf("chain %v must be rejected", chain)
		}
	}
}

func TestPlanFromProtoZapretWithVPN(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("zapret_with_vpn is Linux-only")
	}
	in := chainTestPlan()
	in.Routes = []*corev1.RoutingRule{
		{Destination: "domain:example.com", OutboundId: "direct"},
		{Destination: "all", OutboundId: "a"},
	}
	in.ZapretWithVpn = true
	in.ZapretStrategy = &corev1.BypassStrategy{SplitPos: []string{"2"}, Disorder: true}
	plan, err := planFromProto(in, "s-1", nil)
	if err != nil {
		t.Fatalf("planFromProto: %v", err)
	}
	var zb *engine.Outbound
	for i := range plan.Outbounds {
		if plan.Outbounds[i].ID == zapretDirectOutboundID {
			zb = &plan.Outbounds[i]
		}
	}
	if zb == nil {
		t.Fatal("no zapret direct outbound was added")
	}
	if zb.Protocol != engine.ProtocolBypass {
		t.Fatalf("zapret outbound protocol = %q, want bypass", zb.Protocol)
	}
	for _, r := range plan.Rules {
		if r.Target == "direct" {
			t.Fatalf("rule %v still targets direct", r)
		}
	}
	found := false
	for _, r := range plan.Rules {
		if r.Target == zapretDirectOutboundID {
			found = true
		}
	}
	if !found {
		t.Fatal("no rule targets the zapret outbound")
	}
}

func TestPlanFromProtoZapretWithVPNNeedsTun(t *testing.T) {
	in := chainTestPlan()
	in.TunnelMode = corev1.TunnelMode_TUNNEL_MODE_APPLICATION
	in.ZapretWithVpn = true
	if _, err := planFromProto(in, "s-1", nil); err == nil {
		t.Fatal("zapret_with_vpn without TUN must be rejected")
	}
}

// TestPlanFromProtoZapretWithVPNDefaultStrategy pins the nfqws path of
// F11: with no strategy from the client, the plan carries the built-in
// nfqws set on the synthetic outbound, and the rules keep targeting
// "direct" — nfqws desyncs at the packet layer, there is no proxy to
// retarget to.
func TestPlanFromProtoZapretWithVPNDefaultStrategy(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("zapret_with_vpn is Linux-only")
	}
	in := chainTestPlan()
	in.Routes = []*corev1.RoutingRule{
		{Destination: "domain:example.com", OutboundId: "direct"},
		{Destination: "all", OutboundId: "a"},
	}
	in.ZapretWithVpn = true
	in.ZapretStrategy = nil
	plan, err := planFromProto(in, "s-1", nil)
	if err != nil {
		t.Fatalf("planFromProto: %v", err)
	}
	var zb *engine.Outbound
	for i := range plan.Outbounds {
		if plan.Outbounds[i].ID == zapretDirectOutboundID {
			zb = &plan.Outbounds[i]
		}
	}
	if zb == nil || zb.Bypass == nil {
		t.Fatal("no zapret outbound with the default strategy was added")
	}
	if got := bypass.BackendOf(*zb.Bypass); got != bypass.BackendNFQWS {
		t.Fatalf("default zapret strategy runs on backend %v, want nfqws", got)
	}
	direct := false
	for _, r := range plan.Rules {
		if r.Target == zapretDirectOutboundID {
			t.Fatal("a rule targets the zapret outbound; nfqws rules must stay on direct")
		}
		if r.Target == "direct" {
			direct = true
		}
	}
	if !direct {
		t.Fatal("the direct rule vanished; nfqws desyncs direct traffic at the packet layer")
	}
}
