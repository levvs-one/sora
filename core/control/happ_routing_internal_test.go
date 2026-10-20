package control

import (
	"context"
	"testing"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/subscription"
)

// happLinkV1 / happLinkV2 are happ://routing/add/ links whose JSON
// documents follow the reconstructed builder schema (see
// core/happrouting's golden vectors); V2 changes the rule set so a
// refresh replacement is observable.
const happLinkV1 = "happ://routing/add/eyJOYW1lIjoiUHJvdmlkZXIgUlUiLCJHbG9iYWxQcm94eSI6dHJ1ZSwiRmFrZUROUyI6ZmFsc2UsIlVzZUNodW5rRmlsZXMiOmZhbHNlLCJSZW1vdGVETlNUeXBlIjoiRG9IIiwiUmVtb3RlRE5TSVAiOiJodHRwczovL2Rucy5leGFtcGxlL2Rucy1xdWVyeSIsIkRvbWVzdGljRE5TVHlwZSI6IkRvVSIsIkRvbWVzdGljRE5TSVAiOiI3Ny44OC44LjgiLCJEaXJlY3RTaXRlcyI6WyJnZW9zaXRlOmNhdGVnb3J5LXJ1IiwiYmFuay5leGFtcGxlIl0sIkRpcmVjdElwIjpbImdlb2lwOnJ1IiwiMTAuMC4wLjAvOCJdLCJQcm94eVNpdGVzIjpbImdlb3NpdGU6eW91dHViZSIsInZpZGVvLmV4YW1wbGUiXSwiUHJveHlJcCI6WyIyMDMuMC4xMTMuNyJdLCJCbG9ja1NpdGVzIjpbImFkcy5leGFtcGxlIl0sIkJsb2NrSXAiOlsiMTk4LjUxLjEwMC4wLzI0Il0sIkRvbWFpblN0cmF0ZWd5IjoiSVBJZk5vbk1hdGNoIn0="

func setPanelRouting(p *panel, routing string) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.info.HappRouting = routing
}

func loadProviderRouting(t *testing.T, srv *Server, id string) *subscription.ProviderRouting {
	t.Helper()
	o, err := srv.subs.overrides.Load(id)
	if err != nil {
		t.Fatal(err)
	}
	return o.ProviderRouting
}

func TestRefreshStoresReplacesAndClearsProviderRouting(t *testing.T) {
	p := &panel{body: servers("tokyo"), info: subscription.Info{Title: "Provider", HappRouting: happLinkV1}}
	srv, _ := bookServer(t, t.TempDir(), p)
	srv.subs.overrides = subscription.NewOverrideStore(t.TempDir())
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc"})
	id := state.GetSettings().GetId()

	got := loadProviderRouting(t, srv, id)
	if got == nil {
		t.Fatal("the first fetch must store the provider routing layer")
	}
	if got.Name != "Provider RU" || len(got.Rules) != 9 {
		t.Fatalf("stored layer = %+v", got)
	}
	// Proxy rules carry the sentinel for the client's plan merge;
	// direct and block rules carry sora's built-in targets.
	targets := map[string]string{}
	for _, r := range got.Rules {
		targets[r.Destination] = r.OutboundID
	}
	if targets["domain:bank.example"] != "direct" || targets["domain:ads.example"] != "reject" ||
		targets["geosite:youtube"] != "proxy" || targets["203.0.113.7/32"] != "proxy" {
		t.Fatalf("rule targets = %v", targets)
	}
	if got.RemoteDNS != "DoH https://dns.example/dns-query" {
		t.Fatalf("remote dns recorded = %q", got.RemoteDNS)
	}

	// A user rename saved through the RPC must not wipe the layer.
	ver := &corev1.ApiVersion{Major: 1, Minor: 0}
	resp, err := srv.SaveSubscriptionOverride(context.Background(), &corev1.SaveSubscriptionOverrideRequest{
		ApiVersion: ver, ControlAuthenticator: make([]byte, TokenLen),
		SubscriptionId: id, Renames: map[string]string{"s1": "Home"},
	})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("save override: %v %v", err, resp.GetError())
	}
	if loadProviderRouting(t, srv, id) == nil {
		t.Fatal("a user override save wiped the provider routing layer")
	}

	// A refresh whose payload changed replaces the layer wholesale:
	// a profile with a single direct site leaves exactly one rule.
	setPanelRouting(p, "happ://routing/add/eyJOYW1lIjoiVjIiLCJEaXJlY3RTaXRlcyI6WyJvbmx5LmV4YW1wbGUiXX0=")
	if _, err := srv.subs.refresh(context.Background(), id); err != nil {
		t.Fatal(err)
	}
	got = loadProviderRouting(t, srv, id)
	if got == nil || got.Name != "V2" || len(got.Rules) != 1 || got.Rules[0].Destination != "domain:only.example" {
		t.Fatalf("replaced layer = %+v", got)
	}

	// A broken payload keeps the previous layer and the refresh
	// still succeeds on its servers.
	setPanelRouting(p, "happ://routing/add/!!!broken!!!")
	if _, err := srv.subs.refresh(context.Background(), id); err != nil {
		t.Fatal(err)
	}
	if got = loadProviderRouting(t, srv, id); got == nil || got.Name != "V2" {
		t.Fatalf("a broken payload must keep the previous layer, got %+v", got)
	}

	// A payload that stops arriving clears the layer; the user's
	// rename survives.
	setPanelRouting(p, "")
	if _, err := srv.subs.refresh(context.Background(), id); err != nil {
		t.Fatal(err)
	}
	if got = loadProviderRouting(t, srv, id); got != nil {
		t.Fatalf("a vanished payload must clear the layer, got %+v", got)
	}
	o, err := srv.subs.overrides.Load(id)
	if err != nil || o.Renames["s1"] != "Home" {
		t.Fatalf("user edits must survive routing churn: %+v %v", o, err)
	}

	// Deleting the subscription removes the override file entirely.
	if err := srv.subs.delete(id); err != nil {
		t.Fatal(err)
	}
	o, err = srv.subs.overrides.Load(id)
	if err != nil || o.ProviderRouting != nil || len(o.Renames) != 0 {
		t.Fatalf("delete must drop the whole override, got %+v %v", o, err)
	}
}
