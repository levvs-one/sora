package control_test

// Tests for the obfuscation suite control plane (sora.obfs.v1): profile
// validation, engine compatibility, the plan merge and persistence.

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/levvs-one/sora-client/core/control"
	"github.com/levvs-one/sora-client/core/engine"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
	"github.com/levvs-one/sora-client/core/secret"
	"github.com/levvs-one/sora-client/core/session"
	"google.golang.org/protobuf/encoding/protojson"
)

func applyReq(p *obfsv1.ObfuscationProfile) *obfsv1.ApplyObfsProfileRequest {
	return &obfsv1.ApplyObfsProfileRequest{ApiVersion: clientVersion(), Profile: p}
}

func TestApplyObfsProfilePresetExpansion(t *testing.T) {
	server, _ := newTestServer(t)
	res, err := server.ApplyObfsProfile(context.Background(), applyReq(&obfsv1.ObfuscationProfile{
		Preset: obfsv1.ObfsPreset_OBFS_PRESET_BALANCED,
	}))
	if err != nil {
		t.Fatalf("ApplyObfsProfile() error = %v", err)
	}
	if res.GetError() != nil {
		t.Fatalf("ApplyObfsProfile() wire error = %v", res.GetError())
	}
	got := res.GetApplied()
	if got.GetUtlsProfile() != obfsv1.UtlsProfile_UTLS_PROFILE_CHROME {
		t.Errorf("UtlsProfile = %v, want CHROME", got.GetUtlsProfile())
	}
	if len(got.GetFragSizes()) != 2 || got.GetFragDelayMs() != 10 || got.GetJitterMs() != 10 {
		t.Errorf("preset not expanded: %+v", got)
	}
	// BALANCED needs fragment params + jitter: only xray carries it all.
	if len(res.GetCompatibleEngines()) != 1 || res.GetCompatibleEngines()[0] != "xray" {
		t.Errorf("CompatibleEngines = %v, want [xray]", res.GetCompatibleEngines())
	}
	if len(res.GetWarnings()) == 0 {
		t.Error("expected warnings for the engines that drop features")
	}
}

func TestApplyObfsProfileExplicitOverridesPreset(t *testing.T) {
	server, _ := newTestServer(t)
	res, err := server.ApplyObfsProfile(context.Background(), applyReq(&obfsv1.ObfuscationProfile{
		Preset:      obfsv1.ObfsPreset_OBFS_PRESET_LIGHT,
		UtlsProfile: obfsv1.UtlsProfile_UTLS_PROFILE_FIREFOX,
	}))
	if err != nil {
		t.Fatalf("ApplyObfsProfile() error = %v", err)
	}
	if got := res.GetApplied().GetUtlsProfile(); got != obfsv1.UtlsProfile_UTLS_PROFILE_FIREFOX {
		t.Errorf("UtlsProfile = %v, want FIREFOX (explicit wins)", got)
	}
	// The preset's fragmentation survives alongside the override.
	if len(res.GetApplied().GetFragSizes()) == 0 {
		t.Error("preset frag_sizes lost when overriding another field")
	}
}

func TestApplyObfsProfileOffClears(t *testing.T) {
	server, _ := newTestServer(t)
	ctx := context.Background()
	if _, err := server.ApplyObfsProfile(ctx, applyReq(&obfsv1.ObfuscationProfile{
		Preset: obfsv1.ObfsPreset_OBFS_PRESET_AGGRESSIVE,
	})); err != nil {
		t.Fatalf("ApplyObfsProfile() error = %v", err)
	}
	res, err := server.ApplyObfsProfile(ctx, applyReq(&obfsv1.ObfuscationProfile{
		Preset: obfsv1.ObfsPreset_OBFS_PRESET_OFF,
	}))
	if err != nil {
		t.Fatalf("ApplyObfsProfile() error = %v", err)
	}
	if res.GetError() != nil {
		t.Fatalf("wire error = %v", res.GetError())
	}
	if res.GetApplied().GetPreset() != obfsv1.ObfsPreset_OBFS_PRESET_OFF {
		t.Errorf("Applied.Preset = %v, want OFF", res.GetApplied().GetPreset())
	}
	if len(res.GetCompatibleEngines()) != 0 {
		t.Errorf("CompatibleEngines = %v, want empty for OFF", res.GetCompatibleEngines())
	}
}

func TestApplyObfsProfileRejects(t *testing.T) {
	server, _ := newTestServer(t)
	ctx := context.Background()
	cases := map[string]*obfsv1.ObfuscationProfile{
		"nil profile":          nil,
		"empty profile":        {},
		"off with fields":      {Preset: obfsv1.ObfsPreset_OBFS_PRESET_OFF, FragSizes: []uint32{100}},
		"unknown preset":       {Preset: obfsv1.ObfsPreset(99), FragSizes: []uint32{100}},
		"unknown utls":         {UtlsProfile: obfsv1.UtlsProfile(99), FragSizes: []uint32{100}},
		"too many sizes":       {FragSizes: make([]uint32, 17)},
		"zero size":            {FragSizes: []uint32{0}},
		"oversize fragment":    {FragSizes: []uint32{20000}},
		"delay without frag":   {FragDelayMs: 10},
		"jitter without delay": {FragSizes: []uint32{100}, JitterMs: 5},
		"delay too large":      {FragSizes: []uint32{100}, FragDelayMs: 20000},
		"bad fake sni":         {FakeSni: "not a hostname!"},
		"fake sni too long":    {FakeSni: strings.Repeat("a", 254)},
	}
	for name, p := range cases {
		t.Run(name, func(t *testing.T) {
			res, err := server.ApplyObfsProfile(ctx, applyReq(p))
			if err != nil {
				t.Fatalf("transport error = %v, want a wire error", err)
			}
			if res.GetError() == nil {
				t.Fatalf("ApplyObfsProfile(%v) = no error, want rejection", p)
			}
		})
	}
}

func TestApplyObfsProfileVersionMismatch(t *testing.T) {
	server, _ := newTestServer(t)
	if _, err := server.ApplyObfsProfile(context.Background(), applyReq(
		&obfsv1.ObfuscationProfile{Preset: obfsv1.ObfsPreset_OBFS_PRESET_LIGHT},
	)); err != nil {
		t.Fatalf("ApplyObfsProfile() error = %v", err)
	}
	// A client that cannot negotiate with the core fails at the transport.
	bad := applyReq(&obfsv1.ObfuscationProfile{Preset: obfsv1.ObfsPreset_OBFS_PRESET_LIGHT})
	bad.ApiVersion.Major = 9
	if _, err := server.ApplyObfsProfile(context.Background(), bad); err == nil {
		t.Fatal("ApplyObfsProfile() with major 9 = nil, want transport error")
	}
}

func TestGetObfsCapabilitiesHonest(t *testing.T) {
	server, _ := newTestServer(t)
	res, err := server.GetObfsCapabilities(context.Background(), &obfsv1.GetObfsCapabilitiesRequest{
		ApiVersion: clientVersion(),
	})
	if err != nil {
		t.Fatalf("GetObfsCapabilities() error = %v", err)
	}
	if len(res.GetEngines()) != 3 {
		t.Fatalf("engines = %d, want 3", len(res.GetEngines()))
	}
	byName := map[string]*obfsv1.EngineObfsCapabilities{}
	for _, e := range res.GetEngines() {
		byName[e.GetEngine()] = e
	}
	// Verified against the renderers: sing-box fragments with a bare
	// switch, xray takes packets/length/interval, mihomo cannot fragment.
	if !byName["sing-box"].GetFragmentation() || byName["sing-box"].GetFragmentParams() {
		t.Error("sing-box: want fragmentation without params")
	}
	if byName["sing-box"].GetJitter() {
		t.Error("sing-box: want no jitter knob")
	}
	xray := byName["xray"]
	if !xray.GetFragmentation() || !xray.GetFragmentParams() || !xray.GetJitter() {
		t.Error("xray: want fragmentation with params and jitter")
	}
	if !xray.GetSupportsVersionedParrots() {
		t.Error("xray: want versioned parrots")
	}
	mihomo := byName["mihomo"]
	if mihomo.GetFragmentation() {
		t.Error("mihomo: want no fragmentation")
	}
	for _, p := range mihomo.GetUtlsProfiles() {
		if p == "randomized" {
			t.Error("mihomo: must not list randomized")
		}
	}
}

func TestMergeObfsProfileIntoPlan(t *testing.T) {
	plan := &engine.Plan{
		Outbounds: []engine.Outbound{
			{ID: "vless", TLS: engine.TLS{Enabled: true, ServerName: "real.example.com", Fingerprint: "chrome"}},
			{ID: "reality", TLS: engine.TLS{Enabled: true, ServerName: "mimic.example.com", Reality: true}},
			{ID: "plain", TLS: engine.TLS{}},
		},
	}
	control.MergeObfsProfile(plan, &obfsv1.ObfuscationProfile{
		Preset:      obfsv1.ObfsPreset_OBFS_PRESET_UNSPECIFIED,
		UtlsProfile: obfsv1.UtlsProfile_UTLS_PROFILE_FIREFOX,
		FragSizes:   []uint32{100, 300},
		FragDelayMs: 10,
		JitterMs:    5,
		FakeSni:     "decoy.example.net",
	})
	if !plan.Options.Fragment.Enabled {
		t.Error("fragment not enabled")
	}
	if plan.Options.Fragment.Length != "100-300" {
		t.Errorf("Length = %q, want 100-300", plan.Options.Fragment.Length)
	}
	if plan.Options.Fragment.Interval != "10-15" {
		t.Errorf("Interval = %q, want 10-15", plan.Options.Fragment.Interval)
	}
	vless := plan.Outbounds[0]
	if vless.TLS.Fingerprint != "firefox" {
		t.Errorf("vless fingerprint = %q, want firefox", vless.TLS.Fingerprint)
	}
	if vless.TLS.ServerName != "decoy.example.net" {
		t.Errorf("vless SNI = %q, want the decoy", vless.TLS.ServerName)
	}
	// REALITY keeps its SNI: a decoy there breaks the handshake by design.
	if got := plan.Outbounds[1].TLS.ServerName; got != "mimic.example.com" {
		t.Errorf("reality SNI = %q, want untouched", got)
	}
	// Non-TLS outbounds are untouched.
	if got := plan.Outbounds[2].TLS.Fingerprint; got != "" {
		t.Errorf("plain fingerprint = %q, want empty", got)
	}
}

func TestMergeObfsProfileNoop(t *testing.T) {
	plan := &engine.Plan{}
	control.MergeObfsProfile(nil, &obfsv1.ObfuscationProfile{Preset: obfsv1.ObfsPreset_OBFS_PRESET_LIGHT})
	control.MergeObfsProfile(plan, nil)
	control.MergeObfsProfile(plan, &obfsv1.ObfuscationProfile{Preset: obfsv1.ObfsPreset_OBFS_PRESET_OFF})
	if plan.Options.Fragment.Enabled {
		t.Error("disabled profile must not touch the plan")
	}
}

// planRecorder captures the engine plan Connect hands to the engine.
type planRecorder struct {
	mu   sync.Mutex
	plan *engine.Plan
}

func (r *planRecorder) record(p *engine.Plan) { r.mu.Lock(); defer r.mu.Unlock(); r.plan = p }
func (r *planRecorder) get() *engine.Plan     { r.mu.Lock(); defer r.mu.Unlock(); return r.plan }

// newObfsTestServer builds a control plane like newTestServer but with a
// data dir and a plan-recording engine factory.
func newObfsTestServer(t *testing.T, dir string, rec *planRecorder) (*control.Server, *secret.Store) {
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
		Factory: func(_ context.Context, plan *engine.Plan) (engine.Engine, error) {
			rec.record(plan)
			return newStubEngine(), nil
		},
	})
	server, err := control.New(control.Config{
		Version:       control.Version{Major: 1, Minor: 11, MinSupportedMinor: 1},
		Authenticator: auth,
		Sessions:      manager,
		Secrets:       store,
		DataDir:       dir,
	})
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return server, store
}

func connectForObfs(t *testing.T, server *control.Server, store *secret.Store) {
	t.Helper()
	res, err := server.Connect(context.Background(), &corev1.ConnectRequest{
		ApiVersion:           clientVersion(),
		SessionPlan:          validPlan(t, store),
		ControlAuthenticator: testToken,
	})
	if err != nil {
		t.Fatalf("Connect() error = %v", err)
	}
	if res.GetError() != nil {
		t.Fatalf("Connect() wire error = %v", res.GetError())
	}
}

func TestObfsProfileMergesAtConnectAndPersists(t *testing.T) {
	dir := t.TempDir()
	ctx := context.Background()

	rec1 := &planRecorder{}
	server1, store1 := newObfsTestServer(t, dir, rec1)
	res, err := server1.ApplyObfsProfile(ctx, applyReq(&obfsv1.ObfuscationProfile{
		Preset: obfsv1.ObfsPreset_OBFS_PRESET_LIGHT,
	}))
	if err != nil || res.GetError() != nil {
		t.Fatalf("ApplyObfsProfile() = %v, %v", err, res.GetError())
	}
	if _, err := os.Stat(filepath.Join(dir, "obfs_profile.json")); err != nil {
		t.Fatalf("profile file not written: %v", err)
	}
	connectForObfs(t, server1, store1)
	if got := rec1.get(); got == nil || !got.Options.Fragment.Enabled {
		t.Fatalf("Connect did not merge the profile into the plan: %+v", rec1.get())
	}

	// A fresh server on the same data dir restores the profile: the merge
	// happens without any new Apply call.
	rec2 := &planRecorder{}
	server2, store2 := newObfsTestServer(t, dir, rec2)
	connectForObfs(t, server2, store2)
	if got := rec2.get(); got == nil || !got.Options.Fragment.Enabled {
		t.Fatalf("restored server did not merge the profile: %+v", rec2.get())
	}
	if got := rec2.get().Outbounds[0].TLS.Fingerprint; got != "chrome" {
		t.Errorf("restored fingerprint = %q, want chrome", got)
	}

	// OFF clears the merge for later sessions.
	off, err := server2.ApplyObfsProfile(ctx, applyReq(&obfsv1.ObfuscationProfile{
		Preset: obfsv1.ObfsPreset_OBFS_PRESET_OFF,
	}))
	if err != nil || off.GetError() != nil {
		t.Fatalf("ApplyObfsProfile(OFF) = %v, %v", err, off.GetError())
	}
	rec3 := &planRecorder{}
	server3, store3 := newObfsTestServer(t, dir, rec3)
	connectForObfs(t, server3, store3)
	if got := rec3.get(); got != nil && got.Options.Fragment.Enabled {
		t.Error("OFF profile still merged into the plan")
	}
}

// TestApplyObfsProfileConcurrent hammers ApplyObfsProfile from several
// goroutines: the file write and the in-memory swap are serialized by the
// same mutex, so no call may deadlock, fail, or leave a half-written file.
func TestApplyObfsProfileConcurrent(t *testing.T) {
	dir := t.TempDir()
	rec := &planRecorder{}
	server, _ := newObfsTestServer(t, dir, rec)
	ctx := context.Background()
	presets := []obfsv1.ObfsPreset{
		obfsv1.ObfsPreset_OBFS_PRESET_LIGHT,
		obfsv1.ObfsPreset_OBFS_PRESET_AGGRESSIVE,
	}
	var wg sync.WaitGroup
	for g := 0; g < 8; g++ {
		wg.Add(1)
		go func(g int) {
			defer wg.Done()
			for i := 0; i < 25; i++ {
				res, err := server.ApplyObfsProfile(ctx, applyReq(&obfsv1.ObfuscationProfile{
					Preset: presets[(g+i)%2],
				}))
				if err != nil {
					t.Errorf("transport error = %v", err)
					return
				}
				if res.GetError() != nil {
					t.Errorf("wire error = %v", res.GetError())
					return
				}
			}
		}(g)
	}
	wg.Wait()
	raw, err := os.ReadFile(filepath.Join(dir, "obfs_profile.json"))
	if err != nil {
		t.Fatalf("reading the persisted profile: %v", err)
	}
	stored := &obfsv1.ObfuscationProfile{}
	if err := protojson.Unmarshal(raw, stored); err != nil {
		t.Fatalf("persisted profile does not parse: %v", err)
	}
	switch stored.GetPreset() {
	case obfsv1.ObfsPreset_OBFS_PRESET_LIGHT, obfsv1.ObfsPreset_OBFS_PRESET_AGGRESSIVE:
	default:
		t.Fatalf("persisted preset = %v, want one of the applied ones", stored.GetPreset())
	}
}
