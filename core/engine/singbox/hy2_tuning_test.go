package singbox

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// S4 (PASS1-DEEP-RESEARCH): sing-box 1.14 Hysteria2 fields must reach
// the render — bbr_profile and hop_interval_max — and the gecko obfs
// type must pass through like salamander.
func TestRenderHysteria2TuningFields(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolHysteria2)
	o := &p.Outbounds[0]
	o.HopPorts = "20000-30000"
	o.HopInterval = 30
	o.HopIntervalMax = 90
	o.BBRProfile = "conservative"
	cfg := render(t, p)
	hy2 := findOutbound(cfg, "hysteria2")
	if hy2 == nil {
		t.Fatal("no hysteria2 outbound rendered")
	}
	if hy2["hop_interval"] != "30s" || hy2["hop_interval_max"] != "90s" {
		t.Errorf("hop fields = %v/%v, want 30s/90s", hy2["hop_interval"], hy2["hop_interval_max"])
	}
	if hy2["bbr_profile"] != "conservative" {
		t.Errorf("bbr_profile = %v, want conservative", hy2["bbr_profile"])
	}
}

func TestRenderHysteria2BBRProfileSuppressedUnderBrutal(t *testing.T) {
	// With bandwidth caps the client runs Brutal, not BBR: emitting
	// bbr_profile would be dead config text.
	p := enginetest.Plan(engine.ProtocolHysteria2)
	o := &p.Outbounds[0]
	o.UpMbps, o.DownMbps = 50, 200
	o.BBRProfile = "aggressive"
	cfg := render(t, p)
	hy2 := findOutbound(cfg, "hysteria2")
	if _, ok := hy2["bbr_profile"]; ok {
		t.Errorf("bbr_profile emitted while brutal caps are set: %v", hy2)
	}
}

func TestRenderHysteria2GeckoObfs(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolHysteria2)
	o := &p.Outbounds[0]
	o.Obfs, o.ObfsParam = "gecko", "gecko-secret"
	cfg := render(t, p)
	hy2 := findOutbound(cfg, "hysteria2")
	obfs, _ := hy2["obfs"].(map[string]any)
	if obfs["type"] != "gecko" || obfs["password"] != "gecko-secret" {
		t.Errorf("obfs = %v, want gecko with its password", hy2["obfs"])
	}
}

// S6 (PASS1-DEEP-RESEARCH): sing-box removed AnyTLS client metadata by
// default (1.13.16/1.14.0-beta.5) because vendors profile users by it.
// The render must never grow a metadata field back.
func TestRenderAnyTLSHasNoMetadata(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolAnyTLS)
	cfg := render(t, p)
	at := findOutbound(cfg, "anytls")
	if at == nil {
		t.Fatal("no anytls outbound rendered")
	}
	allowed := map[string]bool{
		"type": true, "tag": true, "server": true, "server_port": true,
		"password": true, "tls": true, "idle_session_check_interval": true,
		"idle_session_timeout": true, "min_idle_session": true,
	}
	for k := range at {
		if strings.Contains(k, "metadata") || strings.Contains(k, "client") {
			t.Errorf("anytls outbound carries profiling field %q: %v", k, at)
		}
		if !allowed[k] {
			t.Errorf("anytls outbound has unexpected field %q: %v", k, at)
		}
	}
}

// TestRenderHy2TUICDeterministic pins the owner's determinism rule
// (CENSOR-P3 "мелочи"): the same hy2/tuic plan rendered twice is
// byte-identical — config churn between identical plans would churn
// engine restarts and defeat config diffing in diagnostics.
func TestRenderHy2TUICDeterministic(t *testing.T) {
	for _, proto := range []engine.Protocol{engine.ProtocolHysteria2, engine.ProtocolTUIC} {
		p := enginetest.Plan(proto)
		o := &p.Outbounds[0]
		o.HopPorts, o.HopInterval, o.HopIntervalMax = "20000-30000,40000", 30, 90
		o.UpMbps, o.DownMbps = 20, 100
		o.CongestionControl, o.UDPRelayMode, o.TUICHeartbeat = "cubic", "quic", 25
		first, err := Render(p, testRuntime)
		if err != nil {
			t.Fatal(err)
		}
		for i := 0; i < 3; i++ {
			again, err := Render(p, testRuntime)
			if err != nil {
				t.Fatal(err)
			}
			if string(again) != string(first) {
				t.Fatalf("%s render %d differs from the first:\n%s\n---\n%s", proto, i, again, first)
			}
		}
	}
}
