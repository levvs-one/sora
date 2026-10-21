package control

// Pins for the Anti-DPI layer merge (contract 1.14): the zapret global
// fills only an empty request strategy, user rules always win over
// layer bindings, a disabled extension's layer never reaches a plan,
// and GetBypassState's provenance reflects the last built plan.

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/ext"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/tune/desync"
)

func tpwsProto() *corev1.BypassStrategy {
	return &corev1.BypassStrategy{SplitPos: []string{"2"}, Disorder: true}
}

func layerEntry(id string, layer ext.Layer) ext.LayerEntry {
	if layer.UpdatedAt.IsZero() {
		layer.UpdatedAt = time.Date(2026, 10, 21, 0, 0, 0, 0, time.UTC)
	}
	return ext.LayerEntry{ID: id, Layer: layer}
}

func zapretPlan(strategy *corev1.BypassStrategy) *corev1.SessionPlan {
	return &corev1.SessionPlan{
		TunnelMode:     corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:      []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
		Routes:         []*corev1.RoutingRule{{Destination: "domain:example.com", OutboundId: "direct"}},
		ZapretWithVpn:  true,
		ZapretStrategy: strategy,
	}
}

func zapretOutbound(t *testing.T, plan *engine.Plan) engine.Outbound {
	t.Helper()
	for _, o := range plan.Outbounds {
		if o.ID == zapretDirectOutboundID {
			return o
		}
	}
	t.Fatalf("plan has no zapret outbound: %+v", plan.Outbounds)
	return engine.Outbound{}
}

func TestBypassMergeZapretGlobalFromLayer(t *testing.T) {
	layers := []ext.LayerEntry{layerEntry("com.example.anti", ext.Layer{Global: tpwsProto()})}
	for name, req := range map[string]*corev1.BypassStrategy{"nil strategy": nil, "empty strategy": {}} {
		plan, prov, err := planFromProtoMerged(zapretPlan(req), "s", nil, layers)
		if err != nil {
			t.Fatalf("%s: %v", name, err)
		}
		o := zapretOutbound(t, plan)
		if o.Bypass == nil || len(o.Bypass.SplitPos) != 1 || o.Bypass.SplitPos[0] != "2" {
			t.Errorf("%s: zapret strategy = %+v, want the layer's", name, o.Bypass)
		}
		if prov.Source != "extension" || prov.From != "com.example.anti" {
			t.Errorf("%s: provenance = %+v, want extension/com.example.anti", name, prov)
		}
	}
}

func TestBypassMergeZapretUserStrategyWins(t *testing.T) {
	user := &corev1.BypassStrategy{SplitPos: []string{"3"}}
	layers := []ext.LayerEntry{layerEntry("com.example.anti", ext.Layer{Global: tpwsProto()})}
	plan, prov, err := planFromProtoMerged(zapretPlan(user), "s", nil, layers)
	if err != nil {
		t.Fatal(err)
	}
	o := zapretOutbound(t, plan)
	if o.Bypass == nil || len(o.Bypass.SplitPos) != 1 || o.Bypass.SplitPos[0] != "3" {
		t.Errorf("zapret strategy = %+v, want the user's", o.Bypass)
	}
	if prov.Source != "user" {
		t.Errorf("provenance = %+v, want user", prov)
	}
}

func TestBypassMergeZapretCoreDefaultWithoutLayer(t *testing.T) {
	plan, prov, err := planFromProtoMerged(zapretPlan(nil), "s", nil, nil)
	if err != nil {
		t.Fatal(err)
	}
	o := zapretOutbound(t, plan)
	if o.Bypass == nil || len(o.Bypass.Desync) == 0 {
		t.Errorf("zapret strategy = %+v, want the core default (nfqws set)", o.Bypass)
	}
	if prov.Source != "core_default" {
		t.Errorf("provenance = %+v, want core_default", prov)
	}
}

func TestBypassMergeBindings(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode:     corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:      []*corev1.OutboundSpec{{Id: "srv", Protocol: "direct"}},
		Routes:         []*corev1.RoutingRule{{Destination: "domain:user.example.com", OutboundId: "direct"}},
		Routing:        &corev1.RoutingOptions{ProxyTarget: "srv"},
		BypassSettings: &corev1.BypassSettings{Rules: []string{"domain:settings.example.com"}},
	}
	layers := []ext.LayerEntry{layerEntry("com.example.anti", ext.Layer{Bindings: []ext.Binding{
		{Match: "domain:ads.example.com", Strategy: tpwsProto()},
		{Match: "domain:user.example.com", Strategy: tpwsProto()},     // conflicts with a user rule
		{Match: "domain:settings.example.com", Strategy: tpwsProto()}, // conflicts with BypassSettings
		{Match: "203.0.113.0/24", Strategy: tpwsProto()},
	}})}
	plan, prov, err := planFromProtoMerged(in, "s", nil, layers)
	if err != nil {
		t.Fatal(err)
	}
	if prov.Bindings != 2 {
		t.Errorf("applied bindings = %d, want 2 (two conflicts skipped)", prov.Bindings)
	}
	var extOutbounds int
	for _, o := range plan.Outbounds {
		if strings.HasPrefix(o.ID, "ext-bypass-") {
			extOutbounds++
			if o.Protocol != engine.ProtocolBypass || o.Bypass == nil {
				t.Errorf("binding outbound %+v is not a bypass outbound with a strategy", o)
			}
			if !strings.HasPrefix(o.Name, "ext: ") {
				t.Errorf("binding outbound name = %q, want the ext: prefix", o.Name)
			}
		}
	}
	if extOutbounds != 2 {
		t.Fatalf("ext outbounds = %d, want 2", extOutbounds)
	}
	// The binding rules sit after the user rule and before the final
	// catch-all proxy-target rule.
	last := plan.Rules[len(plan.Rules)-1]
	if last.Type != engine.RuleMatchAll || last.Target != "srv" {
		t.Fatalf("final rule = %+v, want the catch-all to srv", last)
	}
	found := map[string]bool{}
	for _, r := range plan.Rules[:len(plan.Rules)-1] {
		found[ruleDestination(r)] = true
	}
	for _, want := range []string{"domain:ads.example.com", "203.0.113.0/24", "domain:user.example.com"} {
		if !found[want] {
			t.Errorf("rule %q missing before the catch-all", want)
		}
	}
	count := 0
	for _, r := range plan.Rules {
		if ruleDestination(r) == "domain:user.example.com" {
			count++
		}
	}
	if count != 1 {
		t.Errorf("user destination routed %d times, want exactly 1 (the user's rule)", count)
	}
}

func bypassTestServer(t *testing.T) *Server {
	t.Helper()
	auth, err := NewAuthenticator(make([]byte, TokenLen))
	if err != nil {
		t.Fatal(err)
	}
	sessions := session.NewManager(session.ManagerConfig{
		TunUp: func(context.Context, string) error { return nil },
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return nil, errors.New("bypass tests start no session")
		},
	})
	srv, err := New(Config{Authenticator: auth, Sessions: sessions})
	if err != nil {
		t.Fatal(err)
	}
	return srv
}

func TestBypassLayerProviderFiltersDisabledExtensions(t *testing.T) {
	srv := bypassTestServer(t)
	store, err := ext.NewLayerStore("")
	if err != nil {
		t.Fatal(err)
	}
	if err := store.Set("com.example.anti", ext.Layer{Bindings: []ext.Binding{
		{Match: "domain:ads.example.com", Strategy: tpwsProto()},
	}}); err != nil {
		t.Fatal(err)
	}
	enabled := false
	srv.SetBypassLayerStore(store, func(string) bool { return enabled })
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "srv", Protocol: "direct"}},
	}
	plan, err := srv.buildPlan(in, "s")
	if err != nil {
		t.Fatal(err)
	}
	for _, o := range plan.Outbounds {
		if strings.HasPrefix(o.ID, "ext-bypass-") {
			t.Fatalf("a disabled extension's binding reached the plan: %+v", o)
		}
	}
	enabled = true
	plan, err = srv.buildPlan(in, "s")
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, o := range plan.Outbounds {
		if strings.HasPrefix(o.ID, "ext-bypass-") {
			found = true
		}
	}
	if !found {
		t.Fatal("an enabled extension's binding did not reach the plan")
	}
}

func TestBypassStateReflectsProvenanceAndPending(t *testing.T) {
	srv := bypassTestServer(t)
	store, err := ext.NewLayerStore("")
	if err != nil {
		t.Fatal(err)
	}
	srv.SetBypassLayerStore(store, func(string) bool { return true })
	// No plan yet, no layers: source "none", nothing pending.
	info, err := srv.bypassState(context.Background(), "com.example.anti")
	if err != nil {
		t.Fatal(err)
	}
	if info.GlobalSource != "none" || info.PendingApply || info.SessionActive {
		t.Errorf("fresh state = %+v, want none/not pending/no session", info)
	}
	if err := store.Set("com.example.anti", ext.Layer{Global: tpwsProto()}); err != nil {
		t.Fatal(err)
	}
	// A layer exists but no plan was built: it is pending.
	info, _ = srv.bypassState(context.Background(), "com.example.anti")
	if !info.PendingApply {
		t.Errorf("state before any plan = %+v, want pending", info)
	}
	if _, err := srv.buildPlan(zapretPlan(nil), "s"); err != nil {
		t.Fatal(err)
	}
	info, _ = srv.bypassState(context.Background(), "com.example.anti")
	if info.GlobalSource != "extension" || info.GlobalFrom != "com.example.anti" {
		t.Errorf("state after build = %+v, want the layer as the global source", info)
	}
	if info.PendingApply {
		t.Errorf("state after build = %+v, the just-built plan must not be pending", info)
	}
	// A newer layer after the build makes the state pending again.
	time.Sleep(10 * time.Millisecond)
	if err := store.Set("com.example.anti", ext.Layer{Global: tpwsProto()}); err != nil {
		t.Fatal(err)
	}
	info, _ = srv.bypassState(context.Background(), "com.example.anti")
	if !info.PendingApply {
		t.Errorf("state after a newer layer = %+v, want pending", info)
	}
}

func TestBypassCapabilitiesUnwiredAreHonest(t *testing.T) {
	srv := bypassTestServer(t)
	platform, backends, err := srv.bypassCapabilities(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if platform == "" || len(backends) != 2 {
		t.Fatalf("capabilities = %q, %v", platform, backends)
	}
	for _, b := range backends {
		if b.Available || b.Reason == "" {
			t.Errorf("unwired backend %+v must report unavailable with a reason", b)
		}
	}
}

func TestWinnerStrategyResolution(t *testing.T) {
	// Registry profile id: sni_block/tlsrec renders its TLS record.
	prof, ok := desync.LookupProfile("sni_block/tlsrec")
	if !ok {
		t.Fatal("registry profile sni_block/tlsrec missing")
	}
	params, err := prof.ResolveFor(desync.BlockedCanary.SNI)
	if err != nil {
		t.Fatal(err)
	}
	got := winnerStrategy(&desyncTuneResult{WinnerID: "sni_block/tlsrec", WinnerParams: params})
	if got == nil || got.GetTlsRecord() == "" {
		t.Errorf("registry winner strategy = %+v, want a TLS-record strategy", got)
	}
	// Genome id: the run's own params convert.
	genome := desync.Params{Method: desync.MethodFake, SplitPos: "2", FakeProto: "tls",
		AutoTTL: true, Scope: desync.ScopeTLS}
	got = winnerStrategy(&desyncTuneResult{WinnerID: genome.ID(), WinnerParams: genome})
	if got == nil || len(got.GetDesync()) != 1 || got.GetDesync()[0] != "fake" || got.GetFakeTls() != "tls" {
		t.Errorf("genome winner strategy = %+v, want the fake strategy", got)
	}
	// A genome with no faithful rendering (the none control arm)
	// resolves to no strategy, honestly.
	got = winnerStrategy(&desyncTuneResult{WinnerID: "d/none", WinnerParams: desync.Params{Method: desync.MethodNone}})
	if got != nil {
		t.Errorf("none-genome strategy = %+v, want nil", got)
	}
}

func TestBypassEventOfFiltersJournal(t *testing.T) {
	if _, keep := bypassEventOf(session.Event{Kind: session.EventLog}); keep {
		t.Error("a log event must not reach the bypass stream")
	}
	ev, keep := bypassEventOf(session.Event{Kind: session.EventState})
	if !keep || ev.Kind != "session" {
		t.Errorf("state event = %+v, keep=%v; want a session event", ev, keep)
	}
}
