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

// TestBypassMergeLongMatchNameShortened pins M1(a) at the merge: a
// layer staged behind the store's back with a match whose
// "ext: "+match name would exceed MaxNameBytes is still merged —
// with a deterministically shortened, hash-suffixed name — and the
// plan validates (Connect does not fail).
func TestBypassMergeLongMatchNameShortened(t *testing.T) {
	longMatch := "geosite:" + strings.Repeat("a", 300)
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "srv", Protocol: "direct"}},
		Routing:    &corev1.RoutingOptions{ProxyTarget: "srv"},
	}
	layers := []ext.LayerEntry{layerEntry("com.example.anti", ext.Layer{Bindings: []ext.Binding{
		{Match: longMatch, Strategy: tpwsProto()},
	}})}
	plan, prov, err := planFromProtoMerged(in, "s", nil, layers)
	if err != nil {
		t.Fatalf("planFromProtoMerged with an over-long match: %v", err)
	}
	if prov.Bindings != 1 {
		t.Fatalf("applied bindings = %d, want 1", prov.Bindings)
	}
	for _, o := range plan.Outbounds {
		if strings.HasPrefix(o.ID, "ext-bypass-") {
			if len(o.Name) > engine.MaxNameBytes {
				t.Errorf("merged outbound name is %d bytes, limit is %d", len(o.Name), engine.MaxNameBytes)
			}
			if !strings.HasPrefix(o.Name, "ext: geosite:aaaa") || !strings.Contains(o.Name, "-") {
				t.Errorf("shortened name = %q, want the ext: prefix, a truncated match and a hash suffix", o.Name)
			}
		}
	}
	// Deterministic: rebuilding names the outbound identically.
	plan2, _, err := planFromProtoMerged(in, "s", nil, layers)
	if err != nil {
		t.Fatal(err)
	}
	for i := range plan.Outbounds {
		if plan.Outbounds[i].Name != plan2.Outbounds[i].Name {
			t.Errorf("rebuild renamed an outbound: %q vs %q", plan.Outbounds[i].Name, plan2.Outbounds[i].Name)
		}
	}
}

// TestBypassMergeSkipsInvalidBinding pins M1(c): a binding whose own
// outbound does not validate is skipped, never a plan error.
func TestBypassMergeSkipsInvalidBinding(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "srv", Protocol: "direct"}},
		Routing:    &corev1.RoutingOptions{ProxyTarget: "srv"},
	}
	layers := []ext.LayerEntry{layerEntry("com.example.anti", ext.Layer{Bindings: []ext.Binding{
		{Match: "domain:empty.example.com", Strategy: &corev1.BypassStrategy{}}, // changes nothing
		{Match: "domain:bogus.example.com", Strategy: &corev1.BypassStrategy{Desync: []string{"bogus"}}},
		{Match: "domain:good.example.com", Strategy: tpwsProto()},
	}})}
	plan, prov, err := planFromProtoMerged(in, "s", nil, layers)
	if err != nil {
		t.Fatalf("planFromProtoMerged with invalid bindings: %v", err)
	}
	if prov.Bindings != 1 {
		t.Errorf("applied bindings = %d, want exactly 1 (the valid one)", prov.Bindings)
	}
	for _, o := range plan.Outbounds {
		if strings.HasPrefix(o.ID, "ext-bypass-") && o.Name != "ext: domain:good.example.com" {
			t.Errorf("an invalid binding reached the plan: %+v", o)
		}
	}
}

// TestBypassMergeXrayProfileSkipsAllBindings pins M1(b): an Xray
// profile runs alone, so the merge adds neither outbounds nor rules
// to a profile plan and the plan stays valid.
func TestBypassMergeXrayProfileSkipsAllBindings(t *testing.T) {
	plan := &engine.Plan{
		SessionID: "s",
		Outbounds: []engine.Outbound{{
			ID: "prof", Name: "Profile", Protocol: engine.ProtocolXrayProfile,
			Server: "example.com", Port: 443,
			Profile: []byte(`{"outbounds":[{"protocol":"vless"}]}`),
		}},
	}
	prov := &bypassProvenance{Source: "none"}
	layers := []ext.LayerEntry{layerEntry("com.example.anti", ext.Layer{Bindings: []ext.Binding{
		{Match: "domain:ads.example.com", Strategy: tpwsProto()},
	}})}
	mergeBypassBindings(plan, &corev1.SessionPlan{}, layers, prov)
	if len(plan.Outbounds) != 1 || len(plan.Rules) != 0 || prov.Bindings != 0 {
		t.Fatalf("profile plan after merge = %d outbounds, %d rules, %d bindings; want 1/0/0",
			len(plan.Outbounds), len(plan.Rules), prov.Bindings)
	}
	if err := plan.Validate(); err != nil {
		t.Errorf("profile plan with a bypass layer must stay valid: %v", err)
	}
}

// TestBypassMergeCanonicalConflicts pins L2 at merge time: matches
// are compared in the canonical form ruleFromProto gives user rules,
// so case and IDNA spellings of a user-routed host conflict.
func TestBypassMergeCanonicalConflicts(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "srv", Protocol: "direct"}},
		Routes: []*corev1.RoutingRule{
			{Destination: "domain:EXAMPLE.com", OutboundId: "direct"},
			{Destination: "domain:xn--mnchen-3ya.de", OutboundId: "direct"},
		},
		Routing: &corev1.RoutingOptions{ProxyTarget: "srv"},
	}
	layers := []ext.LayerEntry{layerEntry("com.example.anti", ext.Layer{Bindings: []ext.Binding{
		{Match: "example.com", Strategy: tpwsProto()},        // bare + case variant of a user rule
		{Match: "domain:Example.COM", Strategy: tpwsProto()}, // case variant, prefixed
		{Match: "domain:münchen.de", Strategy: tpwsProto()},  // IDNA variant of a user rule
		{Match: "domain:free.example.org", Strategy: tpwsProto()},
	}})}
	plan, prov, err := planFromProtoMerged(in, "s", nil, layers)
	if err != nil {
		t.Fatal(err)
	}
	if prov.Bindings != 1 {
		t.Errorf("applied bindings = %d, want 1 (only the unrouted host)", prov.Bindings)
	}
	for _, o := range plan.Outbounds {
		if strings.HasPrefix(o.ID, "ext-bypass-") && o.Name != "ext: domain:free.example.org" {
			t.Errorf("a canonically conflicting binding reached the plan: %+v", o)
		}
	}
}

// TestBypassMergeSuffixConflicts pins L2's suffix rule: a user
// domain:example.com rule (likewise a BypassSettings domain entry)
// covers bindings for its subdomains in both domain: and full:
// forms; covered bindings are skipped and not counted.
func TestBypassMergeSuffixConflicts(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode:     corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:      []*corev1.OutboundSpec{{Id: "srv", Protocol: "direct"}},
		Routes:         []*corev1.RoutingRule{{Destination: "domain:example.com", OutboundId: "direct"}},
		Routing:        &corev1.RoutingOptions{ProxyTarget: "srv"},
		BypassSettings: &corev1.BypassSettings{Rules: []string{"domain:settings.org"}},
	}
	layers := []ext.LayerEntry{layerEntry("com.example.anti", ext.Layer{Bindings: []ext.Binding{
		{Match: "domain:sub.example.com", Strategy: tpwsProto()},
		{Match: "full:sub.example.com", Strategy: tpwsProto()},
		{Match: "full:example.com", Strategy: tpwsProto()},
		{Match: "domain:deep.sub.example.com", Strategy: tpwsProto()},
		{Match: "sub.settings.org", Strategy: tpwsProto()},
		{Match: "domain:notexample.com", Strategy: tpwsProto()},
		{Match: "domain:example.com.evil.org", Strategy: tpwsProto()},
	}})}
	plan, prov, err := planFromProtoMerged(in, "s", nil, layers)
	if err != nil {
		t.Fatal(err)
	}
	if prov.Bindings != 2 {
		t.Errorf("applied bindings = %d, want 2 (notexample.com and example.com.evil.org are not covered)", prov.Bindings)
	}
	for _, o := range plan.Outbounds {
		if !strings.HasPrefix(o.ID, "ext-bypass-") {
			continue
		}
		if o.Name != "ext: domain:notexample.com" && o.Name != "ext: domain:example.com.evil.org" {
			t.Errorf("a suffix-covered binding reached the plan: %+v", o)
		}
	}
}

// TestBypassStateDisabledExtensionLayerNotPending pins L1: the
// caller's own layer counts toward bypass state only through the
// provider filter (enabled + granted bypass.write). A disabled
// extension's stored layer makes nothing pending and is not the
// global source.
func TestBypassStateDisabledExtensionLayerNotPending(t *testing.T) {
	srv := bypassTestServer(t)
	store, err := ext.NewLayerStore("")
	if err != nil {
		t.Fatal(err)
	}
	if err := store.Set("com.example.anti", ext.Layer{Global: tpwsProto()}); err != nil {
		t.Fatal(err)
	}
	enabled := false
	srv.SetBypassLayerStore(store, func(string) bool { return enabled })
	info, err := srv.bypassState(context.Background(), "com.example.anti")
	if err != nil {
		t.Fatal(err)
	}
	if info.PendingApply {
		t.Errorf("state for a disabled extension = %+v, want pending_apply=false", info)
	}
	if info.GlobalSource == "extension" {
		t.Errorf("state for a disabled extension = %+v, global_source must not be extension on its account", info)
	}
	// Control: the same layer from an enabled+granted extension IS
	// pending (the filter, not the caller, decides).
	enabled = true
	info, _ = srv.bypassState(context.Background(), "com.example.anti")
	if !info.PendingApply {
		t.Errorf("state for an enabled extension = %+v, want pending_apply=true", info)
	}
}

// TestBypassMergeResolvesMidSNIMarker pins the merge half of the
// midsni semantics: a binding strategy carrying the marker is
// resolved against the binding's own domain — the same
// bypass.ResolveStrategy semantics the tuner uses — so the merged
// outbound carries the concrete "sniext+N" position (for
// example.com: sniext + 9 + 11/2 = sniext+14) and the plan
// validates; a marker binding on a non-domain destination is
// skipped, never a plan failure.
func TestBypassMergeResolvesMidSNIMarker(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "srv", Protocol: "direct"}},
		Routing:    &corev1.RoutingOptions{ProxyTarget: "srv"},
	}
	nfqMarker := &corev1.BypassStrategy{
		SplitPos: []string{"midsni"}, Desync: []string{"disorder2"},
		Fooling: "md5sig", FilterTcp: "80,443", FilterL7: "tls",
	}
	layers := []ext.LayerEntry{layerEntry("com.example.anti", ext.Layer{Bindings: []ext.Binding{
		{Match: "domain:example.com", Strategy: &corev1.BypassStrategy{SplitPos: []string{"midsni"}}},
		{Match: "domain:example.org", Strategy: nfqMarker},
		{Match: "geosite:category-ads", Strategy: &corev1.BypassStrategy{SplitPos: []string{"midsni"}}},
	}})}
	plan, prov, err := planFromProtoMerged(in, "s", nil, layers)
	if err != nil {
		t.Fatalf("planFromProtoMerged with marker bindings: %v", err)
	}
	if prov.Bindings != 2 {
		t.Errorf("applied bindings = %d, want 2 (the tag binding's marker cannot resolve and is skipped)", prov.Bindings)
	}
	byName := map[string]engine.Outbound{}
	for _, o := range plan.Outbounds {
		if strings.HasPrefix(o.ID, "ext-bypass-") {
			byName[o.Name] = o
		}
	}
	tpwsOut, ok := byName["ext: domain:example.com"]
	if !ok || tpwsOut.Bypass == nil || len(tpwsOut.Bypass.SplitPos) != 1 || tpwsOut.Bypass.SplitPos[0] != "sniext+14" {
		t.Errorf("tpws marker binding outbound = %+v, want SplitPos [sniext+14] (resolved against example.com)", tpwsOut)
	}
	nfqOut, ok := byName["ext: domain:example.org"]
	if !ok || nfqOut.Bypass == nil || len(nfqOut.Bypass.SplitPos) != 1 || nfqOut.Bypass.SplitPos[0] != "sniext+14" {
		t.Errorf("nfqws marker binding outbound = %+v, want SplitPos [sniext+14] (resolved against example.org)", nfqOut)
	}
	for _, o := range plan.Outbounds {
		if o.Bypass == nil {
			continue
		}
		for _, pos := range o.Bypass.SplitPos {
			if pos == "midsni" {
				t.Errorf("an unresolved marker reached the plan: %+v", o)
			}
		}
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
