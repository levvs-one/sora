package control

import (
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// TestPlanFromProtoUsesCanonicalBuiltInTargets verifies that the control
// boundary shares engine's single source of truth for built-in targets
// (A20-18): pass/dns, accepted by the engine contract, now pass conversion,
// and block, accepted by control's old copy but renderable by no engine, is
// rejected fail-fast at the boundary with KeyPlanUnknownTarget instead of
// falling through to the engine.
func TestPlanFromProtoUsesCanonicalBuiltInTargets(t *testing.T) {
	base := func(target string) *corev1.SessionPlan {
		return &corev1.SessionPlan{
			TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
			Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
			Routes:     []*corev1.RoutingRule{{Destination: "domain:example.com", OutboundId: target}},
		}
	}
	for _, target := range []string{"direct", "reject", "pass", "dns", "a"} {
		if _, err := planFromProto(base(target), "s", nil); err != nil {
			t.Errorf("planFromProto with target %q = %v, want nil", target, err)
		}
	}
	for _, target := range []string{"block", "ghost"} {
		_, err := planFromProto(base(target), "s", nil)
		if errs.KeyOf(err) != errs.KeyPlanUnknownTarget {
			t.Errorf("planFromProto with target %q: key = %v, want %v", target, errs.KeyOf(err), errs.KeyPlanUnknownTarget)
		}
	}
}

// TestPlanFromProtoGroupMembersUseCanonicalBuiltInTargets covers the other
// built-in-target check on the control boundary: group membership.
func TestPlanFromProtoGroupMembersUseCanonicalBuiltInTargets(t *testing.T) {
	base := func(member string) *corev1.SessionPlan {
		return &corev1.SessionPlan{
			TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
			Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
			Groups:     []*corev1.GroupSpec{{Name: "g", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"a", member}}},
		}
	}
	for _, member := range []string{"direct", "reject", "pass", "dns"} {
		if _, err := planFromProto(base(member), "s", nil); err != nil {
			t.Errorf("planFromProto with group member %q = %v, want nil", member, err)
		}
	}
	for _, member := range []string{"block", "ghost"} {
		_, err := planFromProto(base(member), "s", nil)
		if errs.KeyOf(err) != errs.KeyPlanGroupsInvalid {
			t.Errorf("planFromProto with group member %q: key = %v, want %v", member, errs.KeyOf(err), errs.KeyPlanGroupsInvalid)
		}
	}
}
