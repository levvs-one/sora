package control

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestOLCRTCImportPersistenceKeepsSessionMaterialInsideCore(t *testing.T) {
	const key = "d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799"
	link := "olcrtc://jitsi?vp8channel<vp8-fps=60&vp8-batch=64>@https://meet.example.org/room#" + key + "$Community"
	srv, store := bookServer(t, t.TempDir(), nil)
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: link, AutoUpdate: true})
	if state.GetLastError() != nil || len(state.GetOutbounds()) != 1 || state.GetDisplayName() != "Community" || state.GetSettings().GetAutoUpdate() {
		t.Fatalf("single link import did not complete: %v", state.GetLastError())
	}
	raw, err := json.Marshal(state)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), key) || strings.Contains(string(raw), "/room") || strings.Contains(string(raw), "vp8-fps") {
		t.Fatal("state exposed session configuration")
	}
	plan, err := planFromProto(&corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION, Outbounds: state.GetOutbounds()}, "olc", store)
	if err != nil {
		t.Fatal(err)
	}
	out := plan.Outbounds[0]
	if out.Protocol != engine.ProtocolOLCRTC || out.Password != key || out.OLCRTC == nil || out.OLCRTC.Parameters["vp8-batch"] != "64" {
		t.Fatal("stored credential lost transport fields")
	}
	reloaded := newSubscriptionBook(srv)
	if got := reloaded.list(); len(got) != 1 || len(got[0].GetOutbounds()) != 1 {
		t.Fatal("restart lost the local import")
	}
	id := state.GetSettings().GetId()
	if _, err := srv.subs.refresh(t.Context(), id); err != nil {
		t.Fatal(err)
	}
	if err := srv.subs.delete(id); err != nil {
		t.Fatal(err)
	}
	if store.Has(state.GetOutbounds()[0].GetCredentials().GetReference()) {
		t.Fatal("delete retained the key")
	}
	if _, err := normalizedLink("olcrtc://broken"); err == nil {
		t.Fatal("malformed URI saved")
	}
}
