package control

// End-to-end proof for the Anti-DPI extension (contract 1.14), wired
// exactly as production main.go wires it (mountControlServices):
//
//	one ext.Store (the real signed extensions/anti-dpi/anti-dpi.soraext,
//	sideloaded with the dev key the package ships) + ONE ext.LayerStore
//	shared by the extension host and this server's plan merge + the
//	production provider filter (installed+enabled+granted bypass.write)
//	+ ext.Host over Server.ExtHostDeps with GrantedPermissions closing
//	the mint hole the way main does.
//
// Everything below drives the real surfaces — Host.MintToken,
// Host.ApplyBypassLayer/GetBypassLayer/GetBypassCapabilities/
// GetBypassState/TuneDesync, Server.buildPlan (Connect's plan path) —
// and the real bypass argv renderers. No layer, plan or strategy is
// hand-staged behind the host's back.
//
// Disabled-extension token semantics, as measured by
// TestAntiDPIE2EDisableRevokesTokensAndDropsLayer (NOT a defect):
// Store.SetEnabled(false) revokes the extension's tokens at the issuer
// (ext.Store.SetEnabled → RevokeByExtension), MintToken after disable
// is refused by the GrantedPermissions dep (NotFound), and the plan
// provider drops the layer — writes after disable fail closed on
// every surface. The LayerStore itself deliberately remembers the
// layer, so re-enabling the extension restores it (documented store
// semantics: "the store remembers, the wiring decides who is
// currently trusted").

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
	"github.com/levvs-one/sora-client/core/ext"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	extv1 "github.com/levvs-one/sora-client/core/gen/sora/ext/v1"
	"github.com/levvs-one/sora-client/core/session"
	"github.com/levvs-one/sora-client/core/tune/desync"
)

const antiDPIExtID = "org.sora.anti-dpi"

type antiDPIPreset struct {
	ID       string          `json:"id"`
	Backends []string        `json:"backends"`
	Strategy json.RawMessage `json:"strategy"`
}

func antiDPIPresets(t *testing.T) []antiDPIPreset {
	t.Helper()
	raw, err := os.ReadFile(filepath.Join("..", "..", "extensions", "anti-dpi", "presets.json"))
	if err != nil {
		t.Fatalf("read presets.json: %v", err)
	}
	var file struct {
		Presets []antiDPIPreset `json:"presets"`
	}
	if err := json.Unmarshal(raw, &file); err != nil {
		t.Fatalf("parse presets.json: %v", err)
	}
	if len(file.Presets) == 0 {
		t.Fatal("presets.json carries no presets")
	}
	return file.Presets
}

func antiDPIPresetStrategy(t *testing.T, id string) *corev1.BypassStrategy {
	t.Helper()
	for _, p := range antiDPIPresets(t) {
		if p.ID == id {
			s := &corev1.BypassStrategy{}
			if err := protojson.Unmarshal(p.Strategy, s); err != nil {
				t.Fatalf("preset %s strategy does not parse as protojson: %v", id, err)
			}
			return s
		}
	}
	t.Fatalf("preset %q not found in presets.json", id)
	return nil
}

type antiDPIFixture struct {
	srv         *Server
	host        *ext.Host
	extStore    *ext.Store
	layerStore  *ext.LayerStore
	controlTok  []byte
	granted     []string
}

// newAntiDPIFixture installs the real package and wires the seam the
// way main.go does. localProxyPort mirrors Config.LocalProxyPort
// (0 = unconfigured core, as in bypassTestServer).
func newAntiDPIFixture(t *testing.T, localProxyPort int) *antiDPIFixture {
	t.Helper()
	ctx := context.Background()
	_ = ctx
	dataDir := t.TempDir()
	extDir := filepath.Join(dataDir, "extensions")

	extStore, err := ext.OpenStore(extDir)
	if err != nil {
		t.Fatalf("OpenStore: %v", err)
	}
	raw, err := os.ReadFile(filepath.Join("..", "..", "extensions", "anti-dpi", "anti-dpi.soraext"))
	if err != nil {
		t.Fatalf("read anti-dpi.soraext: %v", err)
	}
	pkg, err := ext.OpenBytes(raw)
	if err != nil {
		t.Fatalf("OpenBytes(anti-dpi.soraext): %v", err)
	}
	if pkg.Manifest.ID != antiDPIExtID {
		t.Fatalf("package id = %q, want %q", pkg.Manifest.ID, antiDPIExtID)
	}
	// Sideload consent facts, as the install prompt builds them: the
	// signature is the author's own (dev key until the key ceremony).
	facts, err := ext.SideloadConsent(pkg.Manifest)
	if err != nil {
		t.Fatalf("SideloadConsent: %v", err)
	}
	if facts.ID != antiDPIExtID || !facts.SelfAttested {
		t.Fatalf("consent facts = %+v, want the self-attested anti-dpi facts", facts)
	}
	granted := append([]string(nil), pkg.Manifest.Permissions...)
	if _, err := extStore.Install(pkg, ext.SourceSideload, granted, ""); err != nil {
		t.Fatalf("Install(sideload): %v", err)
	}
	if err := extStore.SetEnabled(antiDPIExtID, true); err != nil {
		t.Fatalf("SetEnabled(true): %v", err)
	}
	inst, ok := extStore.Get(antiDPIExtID)
	if !ok || !inst.Enabled || inst.Source != ext.SourceSideload {
		t.Fatalf("installed state = %+v ok=%v, want an enabled sideload", inst, ok)
	}

	auth, err := NewAuthenticator(make([]byte, TokenLen))
	if err != nil {
		t.Fatal(err)
	}
	sessions := session.NewManager(session.ManagerConfig{
		TunUp: func(context.Context, string) error { return nil },
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return &quietEngine{bus: engine.NewEventBus(8)}, nil
		},
	})
	srv, err := New(Config{Authenticator: auth, Sessions: sessions, LocalProxyPort: localProxyPort})
	if err != nil {
		t.Fatal(err)
	}

	layerStore, err := ext.NewLayerStore(extDir)
	if err != nil {
		t.Fatalf("NewLayerStore: %v", err)
	}
	// The production provider filter, verbatim from main.go.
	srv.SetBypassLayerStore(layerStore, func(id string) bool {
		inst, ok := extStore.Get(id)
		if !ok || !inst.Enabled {
			return false
		}
		for _, p := range inst.Granted {
			if p == "bypass.write" {
				return true
			}
		}
		return false
	})
	// Measured capabilities, built the way main builds them: the
	// bypass package's platform probe gated per backend. No binaries
	// are handed to the probe here, so both backends must report
	// unavailable with the gate's own reason — honest, not assumed.
	srv.SetBypassCapabilities(func(ctx context.Context) (string, []ext.BackendState, error) {
		caps := bypass.ProbeCapabilities(ctx, bypass.Binaries{})
		backend := func(kind string, strat engine.BypassStrategy) ext.BackendState {
			st := ext.BackendState{Kind: kind, Available: true}
			if err := caps.Gate(strat); err != nil {
				st.Available, st.Reason = false, err.Error()
			}
			return st
		}
		return caps.Platform, []ext.BackendState{
			backend("tpws", engine.BypassStrategy{SplitPos: []string{"1"}}),
			backend("nfqws", bypass.DefaultStrategy()),
		}, nil
	})

	deps := srv.ExtHostDeps()
	deps.BypassLayers = layerStore
	deps.GrantedPermissions = func(id string) ([]string, bool) {
		inst, ok := extStore.Get(id)
		if !ok || !inst.Enabled {
			return nil, false
		}
		return inst.Granted, true
	}
	host := ext.NewHost(extStore.Issuer(), deps)
	return &antiDPIFixture{
		srv: srv, host: host, extStore: extStore, layerStore: layerStore,
		controlTok: make([]byte, TokenLen), granted: granted,
	}
}

func (f *antiDPIFixture) mint(t *testing.T, perms ...string) []byte {
	t.Helper()
	resp, err := f.host.MintToken(context.Background(), &extv1.MintTokenRequest{
		ControlToken: f.controlTok, ExtensionId: antiDPIExtID, Permissions: perms,
	})
	if err != nil {
		t.Fatalf("MintToken(%v): %v", perms, err)
	}
	if len(resp.GetExtensionToken()) == 0 {
		t.Fatal("MintToken returned an empty token")
	}
	return resp.GetExtensionToken()
}

func (f *antiDPIFixture) applyPresetLayer(t *testing.T, tok []byte) {
	t.Helper()
	global := antiDPIPresetStrategy(t, "sni_block/fake-autottl-badseq")
	binding := antiDPIPresetStrategy(t, "sni_block/tlsrec")
	if _, err := f.host.ApplyBypassLayer(context.Background(), &extv1.ApplyBypassLayerRequest{
		ExtensionToken: tok, HasGlobal: true, Global: global,
		Bindings: []*extv1.BypassBinding{{Match: "domain:example.org", Strategy: binding}},
	}); err != nil {
		t.Fatalf("ApplyBypassLayer: %v", err)
	}
}

func wantCode(t *testing.T, err error, code codes.Code, what string) {
	t.Helper()
	if err == nil {
		t.Fatalf("%s: succeeded, want %s", what, code)
	}
	if got := status.Code(err); got != code {
		t.Fatalf("%s: code = %s (%v), want %s", what, got, err, code)
	}
}

func TestAntiDPIE2ECapabilitiesAndLayerRoundTrip(t *testing.T) {
	f := newAntiDPIFixture(t, 0)
	ctx := context.Background()
	tok := f.mint(t, f.granted...)

	caps, err := f.host.GetBypassCapabilities(ctx, &extv1.GetBypassCapabilitiesRequest{ExtensionToken: tok})
	if err != nil {
		t.Fatalf("GetBypassCapabilities: %v", err)
	}
	if caps.GetPlatform() == "" || len(caps.GetBackends()) != 2 {
		t.Fatalf("capabilities = %+v, want a platform and two backends", caps)
	}
	kinds := map[string]bool{}
	for _, b := range caps.GetBackends() {
		kinds[b.GetKind()] = true
		// Honesty: this fixture hands the probe no zapret binaries, so
		// a backend claiming availability would be an assumption,
		// not a measurement.
		if b.GetAvailable() || b.GetReason() == "" {
			t.Errorf("backend %+v claims availability with no binaries probed", b)
		}
		if !strings.Contains(b.GetReason(), "not installed") {
			t.Errorf("backend %s reason = %q, want the gate's binary-missing reason", b.GetKind(), b.GetReason())
		}
	}
	if !kinds["tpws"] || !kinds["nfqws"] {
		t.Errorf("backend kinds = %v, want tpws+nfqws", kinds)
	}

	f.applyPresetLayer(t, tok)

	got, err := f.host.GetBypassLayer(ctx, &extv1.GetBypassLayerRequest{ExtensionToken: tok})
	if err != nil {
		t.Fatalf("GetBypassLayer: %v", err)
	}
	if !got.GetHasGlobal() || got.GetUpdatedAtUnix() == 0 {
		t.Fatalf("layer after Apply = %+v, want a global and a timestamp", got)
	}
	if want := antiDPIPresetStrategy(t, "sni_block/fake-autottl-badseq"); !proto.Equal(got.GetGlobal(), want) {
		t.Errorf("global round-trip = %v, want preset %v", got.GetGlobal(), want)
	}
	if len(got.GetBindings()) != 1 || got.GetBindings()[0].GetMatch() != "domain:example.org" {
		t.Fatalf("bindings round-trip = %+v, want one domain:example.org binding", got.GetBindings())
	}
	if want := antiDPIPresetStrategy(t, "sni_block/tlsrec"); !proto.Equal(got.GetBindings()[0].GetStrategy(), want) {
		t.Errorf("binding strategy round-trip = %v, want preset %v", got.GetBindings()[0].GetStrategy(), want)
	}

	// Before any plan is built the layer is pending; the state RPC
	// (bypass.read) must say so.
	state, err := f.host.GetBypassState(ctx, &extv1.GetBypassStateRequest{ExtensionToken: tok})
	if err != nil {
		t.Fatalf("GetBypassState: %v", err)
	}
	if !state.GetPendingApply() || state.GetGlobalSource() != "none" {
		t.Errorf("state before any plan = %+v, want pending + source none", state)
	}
}

func TestAntiDPIE2EPlanMerge(t *testing.T) {
	f := newAntiDPIFixture(t, 0)
	ctx := context.Background()
	tok := f.mint(t, f.granted...)
	f.applyPresetLayer(t, tok)

	// (a) zapret_with_vpn + empty request strategy: the preset fills
	// the slot, provenance names the extension, pending clears.
	plan, err := f.srv.buildPlan(zapretPlan(nil), "s")
	if err != nil {
		t.Fatalf("buildPlan (a): %v", err)
	}
	o := zapretOutbound(t, plan)
	wantGlobal := ext.ProtoToEngineStrategy(antiDPIPresetStrategy(t, "sni_block/fake-autottl-badseq"))
	if o.Bypass == nil || !proto.Equal(ext.EngineToProtoStrategy(*o.Bypass), ext.EngineToProtoStrategy(wantGlobal)) {
		t.Errorf("(a) zapret strategy = %+v, want the preset's %+v", o.Bypass, wantGlobal)
	}
	// (c) the binding is in the same plan: ext-bypass outbound + rule.
	assertBindingInPlan(t, plan, "domain:example.org")
	state, err := f.host.GetBypassState(ctx, &extv1.GetBypassStateRequest{ExtensionToken: tok})
	if err != nil {
		t.Fatalf("GetBypassState (a): %v", err)
	}
	if state.GetGlobalSource() != "extension" || state.GetGlobalFrom() != antiDPIExtID {
		t.Errorf("(a) state = %+v, want global_source=extension from %s", state, antiDPIExtID)
	}
	if state.GetPendingApply() {
		t.Errorf("(a) state = %+v, pending_apply must clear once the plan is built", state)
	}
	if state.GetBindingsCount() != 1 {
		t.Errorf("(a) bindings_count = %d, want 1", state.GetBindingsCount())
	}

	// (b) a non-empty user strategy always wins.
	user := &corev1.BypassStrategy{SplitPos: []string{"3"}}
	plan, err = f.srv.buildPlan(zapretPlan(user), "s")
	if err != nil {
		t.Fatalf("buildPlan (b): %v", err)
	}
	o = zapretOutbound(t, plan)
	if o.Bypass == nil || len(o.Bypass.SplitPos) != 1 || o.Bypass.SplitPos[0] != "3" {
		t.Errorf("(b) zapret strategy = %+v, want the user's split 3", o.Bypass)
	}
	state, _ = f.host.GetBypassState(ctx, &extv1.GetBypassStateRequest{ExtensionToken: tok})
	if state.GetGlobalSource() != "user" {
		t.Errorf("(b) state = %+v, want global_source=user", state)
	}

	// (c-conflict) a pre-existing user rule on the binding's
	// destination skips the binding; the user's rule stays singular.
	conflict := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "srv", Protocol: "direct"}},
		Routes:     []*corev1.RoutingRule{{Destination: "domain:example.org", OutboundId: "direct"}},
		Routing:    &corev1.RoutingOptions{ProxyTarget: "srv"},
	}
	plan, err = f.srv.buildPlan(conflict, "s")
	if err != nil {
		t.Fatalf("buildPlan (c-conflict): %v", err)
	}
	for _, ob := range plan.Outbounds {
		if strings.HasPrefix(ob.ID, "ext-bypass-") {
			t.Errorf("(c-conflict) binding outbound reached the plan despite the user rule: %+v", ob)
		}
	}
	count := 0
	for _, r := range plan.Rules {
		if ruleDestination(r) == "domain:example.org" {
			count++
			if r.Target != "direct" {
				t.Errorf("(c-conflict) example.org rule target = %q, want the user's direct", r.Target)
			}
		}
	}
	if count != 1 {
		t.Errorf("(c-conflict) example.org routed %d times, want exactly 1", count)
	}
}

func assertBindingInPlan(t *testing.T, plan *engine.Plan, dest string) {
	t.Helper()
	var outbound *engine.Outbound
	for i := range plan.Outbounds {
		if strings.HasPrefix(plan.Outbounds[i].ID, "ext-bypass-") {
			outbound = &plan.Outbounds[i]
		}
	}
	if outbound == nil {
		t.Fatalf("plan has no ext-bypass outbound: %+v", plan.Outbounds)
	}
	if outbound.Protocol != engine.ProtocolBypass || outbound.Bypass == nil || outbound.Bypass.TLSRecord != "sniext+1" {
		t.Errorf("binding outbound = %+v, want a bypass outbound carrying the tlsrec preset", outbound)
	}
	found := false
	for _, r := range plan.Rules {
		if ruleDestination(r) == dest && r.Target == outbound.ID {
			found = true
		}
	}
	if !found {
		t.Errorf("plan has no rule %s -> %s: %+v", dest, outbound.ID, plan.Rules)
	}
}

func TestAntiDPIE2EDisableRevokesTokensAndDropsLayer(t *testing.T) {
	f := newAntiDPIFixture(t, 0)
	ctx := context.Background()
	tok := f.mint(t, f.granted...)
	f.applyPresetLayer(t, tok)
	if _, err := f.srv.buildPlan(zapretPlan(nil), "s"); err != nil {
		t.Fatal(err)
	}

	if err := f.extStore.SetEnabled(antiDPIExtID, false); err != nil {
		t.Fatalf("SetEnabled(false): %v", err)
	}

	// FACT (safe semantics, not a defect): the token minted before
	// the disable is revoked by the store, so every host call with it
	// — reads AND the ApplyBypassLayer write — fails Unauthenticated.
	_, err := f.host.GetBypassLayer(ctx, &extv1.GetBypassLayerRequest{ExtensionToken: tok})
	wantCode(t, err, codes.Unauthenticated, "GetBypassLayer with a pre-disable token")
	_, err = f.host.ApplyBypassLayer(ctx, &extv1.ApplyBypassLayerRequest{
		ExtensionToken: tok, HasGlobal: true, Global: antiDPIPresetStrategy(t, "sni_block/tlsrec"),
	})
	wantCode(t, err, codes.Unauthenticated, "ApplyBypassLayer with a pre-disable token")

	// FACT: minting for a disabled extension is refused outright.
	_, err = f.host.MintToken(ctx, &extv1.MintTokenRequest{
		ControlToken: f.controlTok, ExtensionId: antiDPIExtID, Permissions: f.granted,
	})
	wantCode(t, err, codes.NotFound, "MintToken after disable")

	// The safe invariant the task pins: a new plan carries no layer
	// of the disabled extension — the core is back to its own state
	// (zapret falls back to the core default, no binding outbound).
	plan, err := f.srv.buildPlan(zapretPlan(nil), "s")
	if err != nil {
		t.Fatalf("buildPlan after disable: %v", err)
	}
	for _, ob := range plan.Outbounds {
		if strings.HasPrefix(ob.ID, "ext-bypass-") {
			t.Errorf("disabled extension's binding reached a new plan: %+v", ob)
		}
	}
	o := zapretOutbound(t, plan)
	if o.Bypass == nil || len(o.Bypass.Desync) == 0 {
		t.Errorf("zapret after disable = %+v, want the core default strategy", o.Bypass)
	}
	provState, err := f.srv.bypassState(ctx, antiDPIExtID)
	if err != nil {
		t.Fatal(err)
	}
	if provState.GlobalSource != "core_default" || provState.BindingsCount != 0 {
		t.Errorf("state after disable build = %+v, want core_default + 0 bindings", provState)
	}
	// The store remembers the layer (documented semantics); only the
	// wiring's trust filter changed. Re-enabling restores it.
	if _, ok := f.layerStore.Get(antiDPIExtID); !ok {
		t.Error("LayerStore dropped the layer on disable; want it remembered")
	}
}

func TestAntiDPIE2EGatingAndValidation(t *testing.T) {
	f := newAntiDPIFixture(t, 0)
	ctx := context.Background()

	readOnly := f.mint(t, "bypass.read")
	_, err := f.host.ApplyBypassLayer(ctx, &extv1.ApplyBypassLayerRequest{
		ExtensionToken: readOnly, HasGlobal: true, Global: antiDPIPresetStrategy(t, "sni_block/tlsrec"),
	})
	wantCode(t, err, codes.PermissionDenied, "ApplyBypassLayer with a bypass.read-only token")

	writeOnly := f.mint(t, "bypass.write")
	_, err = f.host.GetBypassState(ctx, &extv1.GetBypassStateRequest{ExtensionToken: writeOnly})
	wantCode(t, err, codes.PermissionDenied, "GetBypassState with a bypass.write-only token")
	_, err = f.host.GetBypassCapabilities(ctx, &extv1.GetBypassCapabilitiesRequest{ExtensionToken: writeOnly})
	wantCode(t, err, codes.PermissionDenied, "GetBypassCapabilities with a bypass.write-only token")

	// LayerStore validation through the host: ttl and auto_ttl are
	// mutually exclusive, so this strategy must fail InvalidArgument
	// and leave no layer behind.
	full := f.mint(t, f.granted...)
	bad := &corev1.BypassStrategy{
		Desync: []string{"fake"}, FakeTls: "tls", Ttl: 5, AutoTtl: true,
		FilterTcp: "80,443", FilterL7: "tls",
	}
	_, err = f.host.ApplyBypassLayer(ctx, &extv1.ApplyBypassLayerRequest{
		ExtensionToken: full, HasGlobal: true, Global: bad,
	})
	wantCode(t, err, codes.InvalidArgument, "ApplyBypassLayer with ttl+auto_ttl")
	if _, ok := f.layerStore.Get(antiDPIExtID); ok {
		t.Error("an invalid layer was stored")
	}

	// Minting beyond the granted set is refused by the
	// GrantedPermissions dep, exactly as in production wiring.
	_, err = f.host.MintToken(ctx, &extv1.MintTokenRequest{
		ControlToken: f.controlTok, ExtensionId: antiDPIExtID,
		Permissions: []string{"bypass.read", "routing.rules"},
	})
	wantCode(t, err, codes.PermissionDenied, "MintToken beyond the granted set")
}

// TestAntiDPIE2ETuneDesyncHonestNegative drives TuneDesync through
// the Host with the real tuner Service substituted via
// control.DesyncServiceForTest. The seam substitutes the Service,
// not its result: runDesyncTune still probes through the control
// plane's own session prober, whose canary handshakes are refused
// instantly by the discard port (the desync_tune_test.go stand). The
// honest outcome in this sandbox is therefore a completed search
// with attempts > 0 and no winner — asserted as such, never dressed
// up as a win. Winner→strategy resolution itself is pinned by
// TestWinnerStrategyResolution in bypass_ext_internal_test.go.
func TestAntiDPIE2ETuneDesyncHonestNegative(t *testing.T) {
	f := newAntiDPIFixture(t, 9)
	ctx := context.Background()

	store, err := desync.NewBindingStore("")
	if err != nil {
		t.Fatal(err)
	}
	svc, err := desync.NewService(store, nil)
	if err != nil {
		t.Fatal(err)
	}
	DesyncServiceForTest = svc
	t.Cleanup(func() { DesyncServiceForTest = nil })

	tok := f.mint(t, f.granted...)
	resp, err := f.host.TuneDesync(ctx, &extv1.TuneDesyncRequest{ExtensionToken: tok, Engine: "nfqws"})
	if err != nil {
		t.Fatalf("TuneDesync: %v", err)
	}
	if resp.GetAttempts() == 0 {
		t.Error("TuneDesync reported no attempts: the search never ran")
	}
	if resp.GetWinnerId() != "" || resp.GetHasStrategy() || resp.GetStrategy() != nil {
		t.Errorf("TuneDesync = %+v, want no winner when every canary handshake is refused", resp)
	}

	// An unknown engine is refused by name before any probing.
	_, err = f.host.TuneDesync(ctx, &extv1.TuneDesyncRequest{ExtensionToken: tok, Engine: "winws-magic"})
	wantCode(t, err, codes.InvalidArgument, "TuneDesync with an unknown engine")

	// bypass.tune is its own gate.
	noTune := f.mint(t, "bypass.read", "bypass.write")
	_, err = f.host.TuneDesync(ctx, &extv1.TuneDesyncRequest{ExtensionToken: noTune, Engine: "nfqws"})
	wantCode(t, err, codes.PermissionDenied, "TuneDesync without bypass.tune")
}

// TestAntiDPIArgvFromBuiltPlan renders the strategies of a plan the
// merge actually built through the real bypass renderers: the nfqws
// argv must carry the fake preset's flags, the tpws argv the tlsrec
// binding's.
func TestAntiDPIArgvFromBuiltPlan(t *testing.T) {
	f := newAntiDPIFixture(t, 0)
	tok := f.mint(t, f.granted...)
	f.applyPresetLayer(t, tok)
	plan, err := f.srv.buildPlan(zapretPlan(nil), "s")
	if err != nil {
		t.Fatal(err)
	}

	zapret := zapretOutbound(t, plan)
	if zapret.Bypass == nil {
		t.Fatal("zapret outbound carries no strategy")
	}
	nfqArgs, ok, err := bypass.NFQWSArgsForTarget(*zapret.Bypass, "/zapret-home", "example.org", 0)
	if err != nil || !ok {
		t.Fatalf("NFQWSArgsForTarget: ok=%v err=%v", ok, err)
	}
	joined := strings.Join(nfqArgs, " ")
	for _, want := range []string{
		"--dpi-desync=fake", "--dpi-desync-autottl", "--dpi-desync-fooling=badseq",
		"--dpi-desync-split-pos=2", "--filter-tcp=80,443", "--filter-l7=tls",
	} {
		if !strings.Contains(joined, want) {
			t.Errorf("nfqws argv %q missing %q", joined, want)
		}
	}

	var binding *engine.Outbound
	for i := range plan.Outbounds {
		if strings.HasPrefix(plan.Outbounds[i].ID, "ext-bypass-") {
			binding = &plan.Outbounds[i]
		}
	}
	if binding == nil || binding.Bypass == nil {
		t.Fatal("plan has no ext-bypass outbound to render")
	}
	tpwsArgs, ok, err := bypass.ArgsForTarget(*binding.Bypass, 4242, "example.org", 0)
	if err != nil || !ok {
		t.Fatalf("ArgsForTarget: ok=%v err=%v", ok, err)
	}
	joined = strings.Join(tpwsArgs, " ")
	for _, want := range []string{"--socks", "--port=4242", "--tlsrec=sniext+1"} {
		if !strings.Contains(joined, want) {
			t.Errorf("tpws argv %q missing %q", joined, want)
		}
	}
}

// TestAntiDPIPresetSweep: every preset in presets.json must parse as
// protojson, be applicable through the plugin in its declared scope,
// name the backend its strategy actually selects, and render for
// that backend without error.
//
// The three presets whose split_pos is the registry marker "midsni"
// (sni_block/split-midsni, sni_block/disorder-midsni,
// kz_variant/split-midsni) are BINDING-scoped: the marker is sora's
// own, not an executor position (the vendored zapret parsers accept
// only method/host/endhost/sld/midsld/endsld/sniext, and the shipped
// tpws binary refuses --split-pos=midsni at parse time), so it can
// only ever resolve against a concrete target domain. The sweep
// pins the flipped semantics: as a global the marker strategy is
// still honestly refused (unresolved marker), as a binding to a
// plain domain it validates (ext.ValidateBypassBindingStrategy),
// on a tag binding it is refused again, and the merge-resolved form
// (bypass.ResolveStrategy against the binding domain) validates and
// renders for the declared backend. The other twelve presets are
// global-scoped and must pass plain strategy validation.
func TestAntiDPIPresetSweep(t *testing.T) {
	presets := antiDPIPresets(t)
	if len(presets) != 15 {
		t.Fatalf("presets.json carries %d presets, want 15", len(presets))
	}
	for _, p := range presets {
		s := &corev1.BypassStrategy{}
		if err := protojson.Unmarshal(p.Strategy, s); err != nil {
			t.Errorf("%s: protojson: %v", p.ID, err)
			continue
		}
		marker := false
		for _, pos := range s.GetSplitPos() {
			if pos == bypass.MidSNIMarker {
				marker = true
			}
		}
		if err := ext.ValidateBypassStrategy(s); err != nil {
			if marker && strings.Contains(err.Error(), "unresolved marker") {
				// Binding scope is this preset's declared scope:
				// on a plain-domain binding the marker strategy
				// must validate, on a tag binding it must not.
				if berr := ext.ValidateBypassBindingStrategy("domain:example.org", s); berr != nil {
					t.Errorf("%s: binding-scope validation on a plain domain: %v", p.ID, berr)
					continue
				}
				if berr := ext.ValidateBypassBindingStrategy("geosite:category-ads", s); berr == nil {
					t.Errorf("%s: marker strategy validated on a tag binding, want refusal", p.ID)
					continue
				}
				// The plan merge resolves the marker against
				// the binding's domain; that resolved form must
				// validate as a plain strategy.
				eng := ext.ProtoToEngineStrategy(s)
				resolved, ok, rerr := bypass.ResolveStrategy(eng, "example.org", 0)
				if rerr != nil || !ok {
					t.Errorf("%s: marker resolution ok=%v err=%v", p.ID, ok, rerr)
					continue
				}
				if verr := ext.ValidateBypassStrategy(ext.EngineToProtoStrategy(resolved)); verr != nil {
					t.Errorf("%s: resolved strategy validation: %v", p.ID, verr)
					continue
				}
				s = ext.EngineToProtoStrategy(resolved)
			} else {
				t.Errorf("%s: strategy validation: %v", p.ID, err)
				continue
			}
		} else if marker {
			t.Errorf("%s: a marker strategy passed global validation, want the unresolved-marker refusal", p.ID)
			continue
		}
		if len(p.Backends) != 1 {
			t.Errorf("%s: backends = %v, want exactly one", p.ID, p.Backends)
			continue
		}
		eng := ext.ProtoToEngineStrategy(s)
		var backend bypass.Backend
		switch p.Backends[0] {
		case "tpws":
			backend = bypass.BackendTPWS
		case "nfqws":
			backend = bypass.BackendNFQWS
		default:
			t.Errorf("%s: unknown backend %q", p.ID, p.Backends[0])
			continue
		}
		if got := bypass.BackendOf(eng); got != backend {
			t.Errorf("%s: strategy selects backend %v, preset declares %q", p.ID, got, p.Backends[0])
			continue
		}
		switch backend {
		case bypass.BackendTPWS:
			args, ok, err := bypass.ArgsForTarget(eng, 4242, "example.org", 0)
			if err != nil || !ok || len(args) < 4 {
				t.Errorf("%s: tpws render ok=%v err=%v args=%v", p.ID, ok, err, args)
			}
		case bypass.BackendNFQWS:
			args, ok, err := bypass.NFQWSArgsForTarget(eng, "/zapret-home", "example.org", 0)
			if err != nil || !ok || len(args) == 0 {
				t.Errorf("%s: nfqws render ok=%v err=%v args=%v", p.ID, ok, err, args)
			}
		}
	}
}

// TestAntiDPIE2EMidsniPresetAsBinding is the acceptance pin for the
// midsni presets' declared (binding) scope, end to end through the
// host: a marker preset applied to a plain-domain binding succeeds,
// the built plan carries the marker resolved against that domain
// (example.org -> sniext+14), and the same preset applied as the
// global strategy is refused InvalidArgument — no target exists to
// resolve it against there.
func TestAntiDPIE2EMidsniPresetAsBinding(t *testing.T) {
	f := newAntiDPIFixture(t, 0)
	ctx := context.Background()
	tok := f.mint(t, f.granted...)
	preset := antiDPIPresetStrategy(t, "sni_block/split-midsni")

	if _, err := f.host.ApplyBypassLayer(ctx, &extv1.ApplyBypassLayerRequest{
		ExtensionToken: tok, HasGlobal: true, Global: preset,
	}); err == nil {
		t.Fatal("midsni preset as global: ApplyBypassLayer succeeded, want refusal")
	} else {
		wantCode(t, err, codes.InvalidArgument, "midsni preset as global")
	}
	if _, err := f.host.ApplyBypassLayer(ctx, &extv1.ApplyBypassLayerRequest{
		ExtensionToken: tok,
		Bindings:       []*extv1.BypassBinding{{Match: "domain:example.org", Strategy: preset}},
	}); err != nil {
		t.Fatalf("midsni preset as a domain binding: ApplyBypassLayer: %v", err)
	}
	plan, err := f.srv.buildPlan(&corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "srv", Protocol: "direct"}},
		Routing:    &corev1.RoutingOptions{ProxyTarget: "srv"},
	}, "s")
	if err != nil {
		t.Fatalf("buildPlan: %v", err)
	}
	found := false
	for _, o := range plan.Outbounds {
		if !strings.HasPrefix(o.ID, "ext-bypass-") {
			continue
		}
		found = true
		if o.Bypass == nil || len(o.Bypass.SplitPos) != 1 || o.Bypass.SplitPos[0] != "sniext+14" {
			t.Errorf("merged marker outbound = %+v, want SplitPos [sniext+14] resolved against example.org", o)
		}
	}
	if !found {
		t.Fatal("the midsni binding did not reach the plan")
	}
}
