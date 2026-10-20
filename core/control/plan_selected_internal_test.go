package control

import (
	"strings"
	"testing"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// TestPlanFromProtoCarriesGroupSelected pins the 1.12 conversion: the
// starting member of a select group reaches the engine plan, and a
// selected value that is not a member is refused at the boundary
// instead of reaching an engine that would drop or misapply it.
func TestPlanFromProtoCarriesGroupSelected(t *testing.T) {
	plan := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{
			{Id: "out-1", Protocol: "socks5", Endpoint: &corev1.Endpoint{Host: "198.51.100.1", Port: 1080}},
			{Id: "out-2", Protocol: "socks5", Endpoint: &corev1.Endpoint{Host: "198.51.100.2", Port: 1080}},
		},
		Groups: []*corev1.GroupSpec{
			{Name: "sora:pick", Type: corev1.GroupType_GROUP_TYPE_SELECT,
				Members: []string{"out-1", "out-2"}, Selected: "out-2"},
		},
		Routing: &corev1.RoutingOptions{ProxyTarget: "sora:pick"},
	}
	got, err := planFromProto(plan, "s_test", nil)
	if err != nil {
		t.Fatalf("planFromProto: %v", err)
	}
	if len(got.Groups) != 1 || got.Groups[0].Selected != "out-2" {
		t.Fatalf("engine groups = %+v, want one group with Selected out-2", got.Groups)
	}

	plan.Groups[0].Selected = "out-99"
	if _, err := planFromProto(plan, "s_test", nil); err == nil ||
		!strings.Contains(err.Error(), "out-99") {
		t.Fatalf("planFromProto with a non-member selected = %v, want a refusal naming it", err)
	}

	// A starting member on an automatic group is meaningless and is
	// refused too: no engine could honour it.
	plan.Groups[0].Selected = "out-2"
	plan.Groups[0].Type = corev1.GroupType_GROUP_TYPE_URL_TEST
	if _, err := planFromProto(plan, "s_test", nil); err == nil {
		t.Fatal("planFromProto accepted a selected member on a url-test group")
	}
}
