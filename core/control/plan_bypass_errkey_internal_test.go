package control

// Pins for the bypass-strategy error key (integration2 round-2 E2E):
// planFromProto wrapped every plan.Validate failure in
// KeyPlanGroupsInvalid, so a plan rejected for a broken zapret/bypass
// strategy told the user the groups were at fault while the detail named
// the strategy. A strategy failure now carries
// KeyPlanBypassStrategyInvalid; a genuinely broken group keeps
// KeyPlanGroupsInvalid.

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestPlanFromProtoBadBypassStrategyReportsBypassStrategyKey(t *testing.T) {
	bypassPlan := func(strategy *corev1.BypassStrategy) *corev1.SessionPlan {
		return &corev1.SessionPlan{
			TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
			Outbounds: []*corev1.OutboundSpec{{Id: "zapret", Protocol: "bypass",
				Bypass: strategy}},
			Routes: []*corev1.RoutingRule{{Destination: "geosite:youtube", OutboundId: "zapret"}},
		}
	}
	for name, tc := range map[string]struct {
		plan       *corev1.SessionPlan
		wantDetail string
	}{
		// The E2E vector: a split position carrying a tpws option is
		// refused by the engine's strategy validation.
		"split position carrying an option": {
			plan:       bypassPlan(&corev1.BypassStrategy{SplitPos: []string{"1 --debug=@/tmp/x"}}),
			wantDetail: "is not a split position",
		},
		"unknown desync method": {
			plan:       bypassPlan(&corev1.BypassStrategy{Desync: []string{"bogus"}}),
			wantDetail: "is not a dpi-desync method",
		},
		"strategy that changes nothing": {
			plan:       bypassPlan(&corev1.BypassStrategy{}),
			wantDetail: "the bypass strategy changes nothing",
		},
		"bypass outbound without a strategy": {
			plan:       bypassPlan(nil),
			wantDetail: "a bypass outbound needs a strategy",
		},
		// The zapret-with-VPN funnel: the strategy rides the plan, the
		// core appends the synthetic bypass outbound, and its broken
		// strategy must get the same key, not the groups one.
		"zapret with vpn strategy": {
			plan: &corev1.SessionPlan{
				TunnelMode:     corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
				Outbounds:      []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
				ZapretWithVpn:  true,
				ZapretStrategy: &corev1.BypassStrategy{SplitPos: []string{"bogus!!"}},
			},
			wantDetail: "is not a split position",
		},
	} {
		t.Run(name, func(t *testing.T) {
			_, err := planFromProto(tc.plan, "s", nil)
			if err == nil {
				t.Fatal("planFromProto accepted a broken bypass strategy")
			}
			if got := errs.KeyOf(err); got != errs.KeyPlanBypassStrategyInvalid {
				t.Fatalf("key = %v, want %v (err = %v)", got, errs.KeyPlanBypassStrategyInvalid, err)
			}
			if !strings.Contains(err.Error(), tc.wantDetail) {
				t.Fatalf("detail = %v, want it to name %q", err, tc.wantDetail)
			}
		})
	}
	// A sound strategy keeps passing.
	if _, err := planFromProto(bypassPlan(&corev1.BypassStrategy{
		SplitPos: []string{"1", "midsld"}, Disorder: true,
	}), "s", nil); err != nil {
		t.Fatalf("planFromProto with a sound bypass strategy = %v", err)
	}
	// The catalog entry exists and matches the code the site raises.
	entry, ok := errs.Lookup(errs.KeyPlanBypassStrategyInvalid)
	if !ok {
		t.Fatal("catalog has no entry for KeyPlanBypassStrategyInvalid")
	}
	if entry.Code != errs.CodeInvalidArgument {
		t.Fatalf("catalog code for the key = %v, want CodeInvalidArgument", entry.Code)
	}
}

func TestPlanFromProtoBadGroupStillReportsGroupsInvalid(t *testing.T) {
	// A cyclic group pair passes groupsFromProto (forward references are
	// allowed) and is rejected by plan validation; that failure is a
	// groups failure and keeps the groups key.
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
		Groups: []*corev1.GroupSpec{
			{Name: "g1", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"g2"}},
			{Name: "g2", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"g1"}},
		},
	}
	_, err := planFromProto(in, "s", nil)
	if errs.KeyOf(err) != errs.KeyPlanGroupsInvalid {
		t.Fatalf("cyclic groups: key = %v, want %v (err = %v)", errs.KeyOf(err), errs.KeyPlanGroupsInvalid, err)
	}
}
