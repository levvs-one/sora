package control

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestCommunityLocalImportsPersistPrivateProtocolOptions(t *testing.T) {
	for _, link := range []string{
		"mierus://alice:private-password@127.0.0.1?profile=Community&port=4200-4202&protocol=UDP&multiplexing=MULTIPLEXING_HIGH",
		"naive+quic://alice:private-password@127.0.0.1:443/?extra-headers=X-Test%3A%20private-header#Community",
	} {
		srv, store := bookServer(t, t.TempDir(), nil)
		state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: link, AutoUpdate: true})
		if state.GetLastError() != nil || len(state.GetOutbounds()) != 1 || state.GetSettings().GetAutoUpdate() {
			t.Fatalf("local link: %v", state.GetLastError())
		}
		raw, _ := json.Marshal(state)
		if strings.Contains(string(raw), "private-password") || strings.Contains(string(raw), "private-header") || strings.Contains(string(raw), "alice") {
			t.Fatal("private protocol options exposed in state")
		}
		plan, err := planFromProto(&corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION, Outbounds: state.GetOutbounds()}, "community", store)
		if err != nil {
			t.Fatal(err)
		}
		o := plan.Outbounds[0]
		if o.UserID != "alice" || o.Password != "private-password" || o.Transport.Type != "udp" {
			t.Fatal("credential roundtrip lost fields")
		}
		if o.Protocol == engine.ProtocolMieru && (o.Mieru == nil || o.Mieru.PortRange != "4200-4202" || o.Mieru.Multiplexing != "MULTIPLEXING_HIGH") {
			t.Fatal("mieru roundtrip lost fields")
		}
		if o.Protocol == engine.ProtocolNaive && (o.Naive == nil || !o.Naive.QUIC || o.Naive.ExtraHeaders["X-Test"] != "private-header") {
			t.Fatal("naive roundtrip lost fields")
		}
		if got := newSubscriptionBook(srv).list(); len(got) != 1 || len(got[0].GetOutbounds()) != 1 {
			t.Fatal("restart lost local import")
		}
	}
	for _, link := range []string{"mierus://alice:@127.0.0.1?profile=A&port=443&protocol=TCP", "naive+https://alice:password@127.0.0.1/?insecure=1"} {
		if _, err := normalizedLink(link); errs.KeyOf(err) != errs.KeySubscriptionFormat {
			t.Fatalf("invalid server URI error key: %v", err)
		}
	}
}
