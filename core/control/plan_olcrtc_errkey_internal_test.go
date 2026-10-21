package control

// Pins for the olcrtc connect-gate error keys (INTEROP.md
// observation): planFromProto used to let every olcrtc refusal fall
// into the generic plan wraps — the session layer's
// core.plan.outbounds_invalid for the connect gates proper, the
// groups wrap here for the structural ones — so the specific,
// localized key (all five are translated and mapped in the UI's
// describe) survived only as a substring of the generic error's
// detail. The gates are now probed on their own before the
// plan-wide validation, exactly like the bypass strategy above
// them, and their catalog errors return unwrapped.

import (
	"fmt"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func olcrtcGatePlan(doc string) (*corev1.SessionPlan, resolver) {
	plan := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{{
			Id:          "out-1",
			DisplayName: "OpenLibre",
			Protocol:    "olcrtc",
			Transport:   "datachannel",
			Endpoint:    &corev1.Endpoint{Host: "room-01"},
			Credentials: &corev1.CredentialsRef{Reference: "ref"},
		}},
	}
	return plan, stubResolver{"ref": []byte(doc)}
}

func TestPlanFromProtoOlcrtcGatesKeepTheirKeys(t *testing.T) {
	key := strings.Repeat("a", 64)
	doc := func(fields string) string {
		return fmt.Sprintf(`{"password":%q,%s}`, key, fields)
	}
	for name, tc := range map[string]struct {
		doc        string
		wantKey    errs.Key
		wantCode   errs.Code
		wantDetail string
	}{
		"wbstream datachannel without a token": {
			doc:        doc(`"olcrtc_provider":"wbstream","olcrtc_transport":"datachannel","olcrtc_room":"room-01"`),
			wantKey:    errs.KeyOlcrtcTokenRequired,
			wantCode:   errs.CodeFailedPrecondition,
			wantDetail: "wbstream datachannel needs a provider account token",
		},
		"provider none from a link": {
			doc:        doc(`"olcrtc_provider":"none","olcrtc_transport":"datachannel"`),
			wantKey:    errs.KeyOlcrtcNotConnectable,
			wantCode:   errs.CodeFailedPrecondition,
			wantDetail: "direct engine URL and token",
		},
		"server mode smuggled through the vault": {
			doc:        doc(`"olcrtc_provider":"jitsi","olcrtc_transport":"datachannel","olcrtc_room":"room-01","olcrtc_mode":"srv"`),
			wantKey:    errs.KeyOlcrtcServerMode,
			wantCode:   errs.CodeInvalidArgument,
			wantDetail: "sora is a client only",
		},
		"telemost datachannel combination": {
			doc:        doc(`"olcrtc_provider":"telemost","olcrtc_transport":"datachannel","olcrtc_room":"room-01"`),
			wantKey:    errs.KeyOlcrtcCombination,
			wantCode:   errs.CodeUnsupported,
			wantDetail: "cannot carry the",
		},
		"malformed encryption key": {
			doc:        `{"password":"abc","olcrtc_provider":"jitsi","olcrtc_transport":"datachannel","olcrtc_room":"room-01"}`,
			wantKey:    errs.KeyOlcrtcInvalid,
			wantCode:   errs.CodeInvalidArgument,
			wantDetail: "encryption key is not usable",
		},
	} {
		t.Run(name, func(t *testing.T) {
			plan, secrets := olcrtcGatePlan(tc.doc)
			_, err := planFromProto(plan, "s", secrets)
			if err == nil {
				t.Fatal("planFromProto accepted a gated olcrtc plan")
			}
			if got := errs.KeyOf(err); got != tc.wantKey {
				t.Fatalf("key = %v, want %v (err = %v)", got, tc.wantKey, err)
			}
			if got := errs.CodeOf(err); got != tc.wantCode {
				t.Fatalf("code = %v, want %v (err = %v)", got, tc.wantCode, err)
			}
			detail := errs.Detail(err)
			if !strings.Contains(detail, tc.wantDetail) {
				t.Fatalf("detail = %q, want it to name %q", detail, tc.wantDetail)
			}
			// The detail is the gate's own diagnostic text, not the
			// generic wrap's rendering of a nested catalog error.
			if strings.Contains(detail, "core.olcrtc.") || strings.Contains(detail, "core.plan.") {
				t.Fatalf("detail = %q, want no nested catalog rendering inside it", detail)
			}
		})
	}
}

func TestPlanFromProtoOlcrtcConnectablePlansPass(t *testing.T) {
	key := strings.Repeat("a", 64)
	for name, fields := range map[string]string{
		"jitsi datachannel guest":      `"olcrtc_provider":"jitsi","olcrtc_transport":"datachannel","olcrtc_room":"room-01"`,
		"wbstream datachannel token":   `"olcrtc_provider":"wbstream","olcrtc_transport":"datachannel","olcrtc_room":"room-01","olcrtc_auth_token":"tok-1"`,
		"wbstream seichannel guest":    `"olcrtc_provider":"wbstream","olcrtc_transport":"seichannel","olcrtc_room":"room-01"`,
		"telemost videochannel guest":  `"olcrtc_provider":"telemost","olcrtc_transport":"videochannel","olcrtc_room":"room-01"`,
		"explicit client mode is fine": `"olcrtc_provider":"jitsi","olcrtc_transport":"datachannel","olcrtc_room":"room-01","olcrtc_mode":"cnc"`,
	} {
		t.Run(name, func(t *testing.T) {
			doc := fmt.Sprintf(`{"password":%q,%s}`, key, fields)
			plan, secrets := olcrtcGatePlan(doc)
			if _, err := planFromProto(plan, "s", secrets); err != nil {
				t.Fatalf("planFromProto refused a connectable olcrtc plan: %v", err)
			}
		})
	}
}

func TestPlanFromProtoOlcrtcValidPlusBrokenGroupsKeepsGroupsKey(t *testing.T) {
	// The probe must not mask unrelated plan failures: a connectable
	// olcrtc outbound beside a genuinely broken group still fails
	// with the groups key, exactly as before.
	key := strings.Repeat("a", 64)
	doc := fmt.Sprintf(`{"password":%q,"olcrtc_provider":"jitsi","olcrtc_transport":"datachannel","olcrtc_room":"room-01"}`, key)
	plan, secrets := olcrtcGatePlan(doc)
	plan.Groups = []*corev1.GroupSpec{
		{Name: "g1", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"g2"}},
		{Name: "g2", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"g1"}},
	}
	_, err := planFromProto(plan, "s", secrets)
	if errs.KeyOf(err) != errs.KeyPlanGroupsInvalid {
		t.Fatalf("cyclic groups beside a valid olcrtc outbound: key = %v, want %v (err = %v)",
			errs.KeyOf(err), errs.KeyPlanGroupsInvalid, err)
	}
}
