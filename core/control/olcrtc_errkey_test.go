package control_test

// Wire-level pins for the olcrtc connect-gate keys (INTEROP.md
// observation): a live Connect refused by an olcrtc gate used to
// answer with the generic core.plan.outbounds_invalid key (and the
// invalid_argument code even for failed-precondition gates), the
// specific key visible only inside DetailRedacted. The factory
// below wraps the stub engine in olcwrap exactly as the registry
// does, so the whole production path — plan building, session
// validation, wire conversion — is exercised.

import (
	"context"
	"fmt"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/olcwrap"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
)

func newOlcrtcGateServer(t *testing.T) (*control.Server, *secret.Store) {
	t.Helper()
	store, err := secret.Open(secretTestDir(t), secret.Options{Protector: secret.FileProtector{}})
	if err != nil {
		t.Fatalf("opening the secret store: %v", err)
	}
	t.Cleanup(func() { _ = store.Close() })
	auth, err := control.NewAuthenticator(testToken)
	if err != nil {
		t.Fatalf("NewAuthenticator() error = %v", err)
	}
	manager := session.NewManager(session.ManagerConfig{
		TunUp: noAdapter,
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return olcwrap.Wrap(newStubEngine(), "/bin/true", t.TempDir(), nil), nil
		},
	})
	server, err := control.New(control.Config{
		Version:       control.Version{Major: 1, Minor: 2, MinSupportedMinor: 1},
		Authenticator: auth,
		Sessions:      manager,
		Secrets:       store,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return server, store
}

func olcrtcWirePlan(t *testing.T, store *secret.Store, doc string) *corev1.SessionPlan {
	t.Helper()
	reference, err := secret.NewReference()
	if err != nil {
		t.Fatalf("NewReference() error = %v", err)
	}
	if err := store.Put(reference, []byte(doc)); err != nil {
		t.Fatalf("seeding the store: %v", err)
	}
	return &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{{
			Id:          "out-1",
			DisplayName: "OpenLibre",
			Protocol:    "olcrtc",
			Transport:   "datachannel",
			Endpoint:    &corev1.Endpoint{Host: "room-01"},
			Credentials: &corev1.CredentialsRef{Reference: reference},
		}},
	}
}

func TestConnectOlcrtcGatesSurfaceTheirOwnKeys(t *testing.T) {
	server, store := newOlcrtcGateServer(t)
	key := strings.Repeat("a", 64)
	doc := func(fields string) string {
		return fmt.Sprintf(`{"password":%q,%s}`, key, fields)
	}
	tests := []struct {
		name       string
		doc        string
		key        errs.Key
		code       corev1.SoraErrorCode
		detailPart string
	}{
		{
			name:       "wbstream datachannel without a token",
			doc:        doc(`"olcrtc_provider":"wbstream","olcrtc_transport":"datachannel","olcrtc_room":"room-01"`),
			key:        errs.KeyOlcrtcTokenRequired,
			code:       corev1.SoraErrorCode_SORA_ERROR_CODE_FAILED_PRECONDITION,
			detailPart: "wbstream datachannel needs a provider account token",
		},
		{
			name:       "provider none from a link",
			doc:        doc(`"olcrtc_provider":"none","olcrtc_transport":"datachannel"`),
			key:        errs.KeyOlcrtcNotConnectable,
			code:       corev1.SoraErrorCode_SORA_ERROR_CODE_FAILED_PRECONDITION,
			detailPart: "direct engine URL and token",
		},
		{
			name:       "server mode through the vault",
			doc:        doc(`"olcrtc_provider":"jitsi","olcrtc_transport":"datachannel","olcrtc_room":"room-01","olcrtc_mode":"srv"`),
			key:        errs.KeyOlcrtcServerMode,
			code:       corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT,
			detailPart: "sora is a client only",
		},
		{
			name:       "telemost datachannel combination",
			doc:        doc(`"olcrtc_provider":"telemost","olcrtc_transport":"datachannel","olcrtc_room":"room-01"`),
			key:        errs.KeyOlcrtcCombination,
			code:       corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT,
			detailPart: "cannot carry the",
		},
		{
			name:       "malformed encryption key",
			doc:        `{"password":"abc","olcrtc_provider":"jitsi","olcrtc_transport":"datachannel","olcrtc_room":"room-01"}`,
			key:        errs.KeyOlcrtcInvalid,
			code:       corev1.SoraErrorCode_SORA_ERROR_CODE_INVALID_ARGUMENT,
			detailPart: "encryption key is not usable",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			response, err := server.Connect(context.Background(), &corev1.ConnectRequest{
				ApiVersion:           clientVersion(),
				SessionPlan:          olcrtcWirePlan(t, store, tt.doc),
				ControlAuthenticator: testToken,
			})
			if err != nil {
				t.Fatalf("Connect() error = %v, want a failure inside the answer", err)
			}
			failure := response.GetError()
			if failure == nil {
				t.Fatal("Connect() accepted a gated olcrtc plan")
			}
			if failure.GetUserMessageKey() != string(tt.key) {
				t.Errorf("key = %q, want %q (detail %q)", failure.GetUserMessageKey(), tt.key, failure.GetDetailRedacted())
			}
			if failure.GetCode() != tt.code {
				t.Errorf("code = %v, want %v", failure.GetCode(), tt.code)
			}
			if !strings.Contains(failure.GetDetailRedacted(), tt.detailPart) {
				t.Errorf("detail = %q, want it to name %q", failure.GetDetailRedacted(), tt.detailPart)
			}
			if strings.Contains(failure.GetDetailRedacted(), "core.plan.outbounds_invalid") {
				t.Errorf("detail = %q, the specific key is demoted into the generic detail again", failure.GetDetailRedacted())
			}
		})
	}
}

func TestConnectBrokenVlessStillReportsOutboundsInvalid(t *testing.T) {
	server, _ := newOlcrtcGateServer(t)
	// The generic plan key is unchanged for non-olcrtc refusals:
	// a vless outbound with an impossible port is refused by plan
	// building with core.plan.outbounds_invalid, as before.
	response, err := server.Connect(context.Background(), &corev1.ConnectRequest{
		ApiVersion: clientVersion(),
		SessionPlan: &corev1.SessionPlan{
			TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
			Outbounds: []*corev1.OutboundSpec{{
				Id:       "out-1",
				Protocol: "vless",
				Endpoint: &corev1.Endpoint{Host: "de1.example.com", Port: 70000},
			}},
		},
		ControlAuthenticator: testToken,
	})
	if err != nil {
		t.Fatalf("Connect() error = %v", err)
	}
	if got := response.GetError().GetUserMessageKey(); got != string(errs.KeyPlanOutbounds) {
		t.Errorf("key = %q, want %q (detail %q)", got, errs.KeyPlanOutbounds, response.GetError().GetDetailRedacted())
	}
}
