package control

import (
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
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
	if via["a"] != "" || via["b"] != "a" || via["c"] != "b" {
		t.Fatalf("wrong chain links: %v", via)
	}
	if plan.Rules[len(plan.Rules)-1].Target != "c" {
		t.Fatalf("chain routes do not select the exit: %v", plan.Rules)
	}
	if !plan.RequiredFeatures()[engine.FeatureChains] {
		t.Fatal("a chained plan must require the chains feature")
	}
}

func TestPlanFromProtoRejectsBadChains(t *testing.T) {
	for _, chain := range [][]string{
		{"a"},                // too short
		{"a", "b", "c", "d"}, // too long
		{"a", "a"},           // repeat
		{"a", "ghost"},       // unknown
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
