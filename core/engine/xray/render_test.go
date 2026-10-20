package xray

import (
	"context"
	"encoding/json"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

var allProtocols = []engine.Protocol{
	engine.ProtocolVLESS, engine.ProtocolVMess, engine.ProtocolTrojan, engine.ProtocolShadowsocks,
	engine.ProtocolHysteria2, engine.ProtocolWireGuard, engine.ProtocolSOCKS5, engine.ProtocolHTTP,
	engine.ProtocolDirect,
}

var testRuntime = supervise.Runtime{LocalPort: 7890, ControlAddr: "127.0.0.1:9090", ProbeURL: engine.TestURLProduction}

func hysteriaWithoutObfs(p *engine.Plan) *engine.Plan {
	for i := range p.Outbounds {
		if p.Outbounds[i].Protocol == engine.ProtocolHysteria2 {
			p.Outbounds[i].Obfs, p.Outbounds[i].ObfsParam = "", ""
		}
	}
	return p
}

func TestRenderPinsSelectGroupAndBalancesAutoGroup(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolTrojan)
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Routing struct {
			Rules     []map[string]any `json:"rules"`
			Balancers []map[string]any `json:"balancers"`
		} `json:"routing"`
		Observatory map[string]any `json:"observatory"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	last := cfg.Routing.Rules[len(cfg.Routing.Rules)-1]
	// The selector resolves to its nested automatic group, requiring a
	// balancer tag.
	if last["balancerTag"] != "b-1" {
		t.Fatalf("default route = %v, want the balancer of Auto", last)
	}
	if len(cfg.Routing.Balancers) != 1 || cfg.Observatory == nil {
		t.Fatalf("an automatic group needs a balancer and the observatory: %s", raw)
	}

	raw, err = Render(p, testRuntime, Selection{"Proxy": "trojan"})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(raw), `{"network":"tcp,udp","outboundTag":"o0002"}`) {
		t.Fatalf("pinned member must become the default route: %s", raw)
	}
}

func TestRenderRoutesProxiesThroughFragment(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Options.Fragment = engine.Fragment{Enabled: true}
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{`"dialerProxy":"fragment"`, `"packets":"tlshello"`} {
		if !strings.Contains(string(raw), want) {
			t.Errorf("rendered config lacks %s", want)
		}
	}
}

func TestRenderRefusesUnreadableHysteriaObfs(t *testing.T) {
	if _, err := Render(enginetest.Plan(engine.ProtocolHysteria2), testRuntime, nil); err == nil {
		t.Fatal("hysteria2 obfs must be refused rather than silently dropped")
	}
}

func TestRenderRefusesUnsupportedTLSVerificationSetting(t *testing.T) {
	for _, protocol := range []engine.Protocol{engine.ProtocolVLESS, engine.ProtocolTrojan, engine.ProtocolHysteria2} {
		p := hysteriaWithoutObfs(enginetest.Plan(protocol))
		p.Outbounds[0].TLS = engine.TLS{Enabled: true, Insecure: true}
		if _, err := Render(p, testRuntime, nil); err == nil {
			t.Errorf("%s silently dropped disabled certificate verification", protocol)
		}
	}
	for _, tls := range []engine.TLS{{Insecure: true}, {Enabled: true, Reality: true, Insecure: true, RealityPublicKey: "public-key"}} {
		p := enginetest.Plan(engine.ProtocolVLESS)
		p.Outbounds[0].TLS = tls
		raw, err := Render(p, testRuntime, nil)
		if err != nil || strings.Contains(string(raw), "allowInsecure") {
			t.Errorf("an inactive TLS flag should not reject plaintext or REALITY: %s, %v", raw, err)
		}
	}
}

func TestTagsAreNeverPrefixesOfEachOther(t *testing.T) {
	seen := map[string]bool{}
	for i := 0; i < engine.MaxOutbounds; i++ {
		seen[outboundTag(i)] = true
	}
	for tag := range seen {
		for n := 1; n < len(tag); n++ {
			if seen[tag[:n]] {
				t.Fatalf("%s is a prefix of %s: a balancer would select both", tag[:n], tag)
			}
		}
	}
}

func binary(t *testing.T) supervise.Binary {
	t.Helper()
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to run Xray against the rendered plans", Prober.EnvVar)
	}
	b, err := Prober.Probe(context.Background(), path)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

// TestEngineAcceptsRenderedPlans runs "xray run -test". geoip.dat and
// geosite.dat must be next to the binary, as shipped by Sora.
func TestEngineAcceptsRenderedPlans(t *testing.T) {
	b := binary(t)
	xhttp := enginetest.Plan(engine.ProtocolVLESS)
	xhttp.Outbounds[0].Flow = ""
	xhttp.Outbounds[0].Transport = engine.Transport{Type: "xhttp", Path: "/x", Mode: "stream-one"}
	fragment := hysteriaWithoutObfs(enginetest.Plan(allProtocols...))
	fragment.Options.Fragment.Enabled = true
	for name, p := range map[string]*engine.Plan{
		"all protocols": hysteriaWithoutObfs(enginetest.Plan(allProtocols...)),
		"xhttp reality": xhttp,
		"fragment":      fragment,
	} {
		t.Run(name, func(t *testing.T) {
			raw, err := Render(p, testRuntime, nil)
			if err != nil {
				t.Fatal(err)
			}
			home := t.TempDir()
			if err := supervise.Check(context.Background(), supervise.Spec{Name: "xray", Path: b.Path, Args: (&driver{}).CheckArgs(testRuntime), Dir: home, Config: raw}); err != nil {
				t.Fatal(err)
			}
		})
	}
}

// TestLiveEngineLifecycle checks startup, metrics, counters, groups, selection
// restart, real tester-process latency, and shutdown.
func TestLiveEngineLifecycle(t *testing.T) {
	b := binary(t)
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	instance, err := New(supervise.Config{Binary: b, HomeDir: t.TempDir(), RestartBudget: 1})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = instance.Close() }()
	p := &engine.Plan{
		SessionID: "live",
		Outbounds: []engine.Outbound{
			{ID: "edge", Name: "Edge", Protocol: engine.ProtocolShadowsocks, Server: "127.0.0.1", Port: 8388, Password: "live-test-password", Cipher: "aes-256-gcm"},
			{ID: "out", Name: "Direct", Protocol: engine.ProtocolDirect},
		},
		Groups:  []engine.Group{{Name: "Sora", Type: engine.GroupSelect, Outbounds: []string{"edge", "out"}}},
		Rules:   []engine.Rule{{Type: engine.RuleMatchAll, Target: "Sora"}},
		Options: engine.Options{LogLevel: "warning"},
	}
	if err := instance.Apply(ctx, p); err != nil {
		t.Fatalf("Apply: %v", err)
	}
	if _, err := instance.Counters(ctx); err != nil {
		t.Fatalf("Counters: %v", err)
	}
	if err := instance.Select(ctx, "Sora", "Direct"); err != nil {
		t.Fatalf("Select: %v", err)
	}
	groups, err := instance.Groups(ctx)
	if err != nil || len(groups) != 1 || groups[0].Selected != "Direct" {
		t.Fatalf("Groups after Select = %+v, %v", groups, err)
	}
	if d, err := instance.Delay(ctx, "Direct", "", 5*time.Second); err != nil || d <= 0 {
		t.Fatalf("Delay through the direct outbound = %v, %v", d, err)
	}
	if _, err := instance.Delay(ctx, "Edge", "", 2*time.Second); err == nil {
		t.Error("a dead server must not report a latency")
	}
	if err := instance.Stop(ctx); err != nil {
		t.Fatalf("Stop: %v", err)
	}
}

func xhttpVLESS() *engine.Plan {
	p := enginetest.Plan(engine.ProtocolVLESS)
	o := &p.Outbounds[0]
	o.Flow = "" // XTLS Vision is TCP-only; it would (correctly) refuse xhttp.
	o.Transport = engine.Transport{
		Type: "xhttp", Path: "/up", Mode: "stream-up",
		DownloadAddress: "down.example.com", DownloadPort: 8443,
	}
	return p
}

// TestRenderXHTTPHeaders pins PASS3 deep A4: the XHTTP headers of
// the plan must reach xhttpSettings — Xray was the only one of the
// three renderers dropping them (sing-box and mihomo emit them), so
// CDN-fronted subscriptions lost their custom headers silently on
// this path. An empty header set must stay absent, not become {}.
func TestRenderXHTTPHeaders(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	o := &p.Outbounds[0]
	o.Flow = ""
	o.Transport = engine.Transport{Type: "xhttp", Path: "/x", Host: "cdn.example.com",
		Headers: map[string]string{"User-Agent": "test-agent", "X-Custom": "v1"}}
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Outbounds []struct {
			StreamSettings struct {
				XHTTP struct {
					Headers map[string]string `json:"headers"`
				} `json:"xhttpSettings"`
			} `json:"streamSettings"`
		} `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	got := cfg.Outbounds[0].StreamSettings.XHTTP.Headers
	if got["User-Agent"] != "test-agent" || got["X-Custom"] != "v1" || len(got) != 2 {
		t.Fatalf("xhttp headers = %v, want the plan headers verbatim", got)
	}

	o.Transport.Headers = nil
	raw, err = Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), `"headers"`) {
		t.Fatalf("no headers in the plan must render no headers key:\n%s", raw)
	}
}

func TestRenderPassesXHTTPDownloadSettings(t *testing.T) {
	raw, err := Render(xhttpVLESS(), testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Outbounds []struct {
			StreamSettings struct {
				XHTTP struct {
					Download struct {
						Address       string `json:"address"`
						Port          int    `json:"port"`
						Network       string `json:"network"`
						Security      string `json:"security"`
						XHTTPSettings struct {
							Path string `json:"path"`
						} `json:"xhttpSettings"`
						RealitySettings struct {
							ServerName string `json:"serverName"`
						} `json:"realitySettings"`
					} `json:"downloadSettings"`
				} `json:"xhttpSettings"`
			} `json:"streamSettings"`
		} `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	d := cfg.Outbounds[0].StreamSettings.XHTTP.Download
	if d.Address != "down.example.com" || d.Port != 8443 {
		t.Errorf("downloadSettings = %+v, want down.example.com:8443", d)
	}
	if d.Network != "xhttp" || d.Security != "reality" {
		t.Errorf("downloadSettings = %+v, want an xhttp stream mirroring the main security", d)
	}
	if d.XHTTPSettings.Path != "/up" {
		t.Errorf("downlink path = %q, want the uplink path", d.XHTTPSettings.Path)
	}
	// The downlink SNI must name the downlink host, not the uplink one.
	if d.RealitySettings.ServerName != "down.example.com" {
		t.Errorf("downlink SNI = %q, want down.example.com", d.RealitySettings.ServerName)
	}
}

func TestRenderRefusesBrokenXHTTPDownloadSettings(t *testing.T) {
	cases := map[string]func(*engine.Transport){
		"address without port": func(tr *engine.Transport) { tr.DownloadPort = 0 },
		"port without address": func(tr *engine.Transport) { tr.DownloadAddress = "" },
		"stream-one mode":      func(tr *engine.Transport) { tr.Mode = "stream-one" },
	}
	for name, mutate := range cases {
		p := xhttpVLESS()
		mutate(&p.Outbounds[0].Transport)
		if _, err := Render(p, testRuntime, nil); err == nil {
			t.Errorf("%s: must be refused, not rendered", name)
		}
	}
	// Download fields on a non-XHTTP transport must not be silently dropped.
	p := xhttpVLESS()
	tr := p.Outbounds[0].Transport
	tr.Type = "ws"
	p.Outbounds[0].Transport = tr
	if _, err := Render(p, testRuntime, nil); err == nil {
		t.Error("downloadSettings on websocket: must be refused, not silently dropped")
	}
}

// xhttpPlanWithFingerprint builds an XHTTP plan with a download detour and
// the given plan fingerprint; tlsOnly switches the security from REALITY
// to plain TLS so both downlink branches are covered.
func xhttpPlanWithFingerprint(fp string, tlsOnly bool) *engine.Plan {
	p := xhttpVLESS()
	o := &p.Outbounds[0]
	if tlsOnly {
		o.TLS.Reality = false
		o.TLS.Enabled = true
		o.TLS.ServerName = "up.example.com"
	}
	o.TLS.Fingerprint = fp
	return p
}

// xhttpFingerprints extracts the uTLS fingerprints of the uplink stream and
// the downloadSettings downlink from a rendered config.
func xhttpFingerprints(t *testing.T, raw []byte) (uplink, downlink string) {
	t.Helper()
	var cfg struct {
		Outbounds []struct {
			StreamSettings struct {
				RealitySettings struct {
					Fingerprint string `json:"fingerprint"`
				} `json:"realitySettings"`
				TLSSettings struct {
					Fingerprint string `json:"fingerprint"`
				} `json:"tlsSettings"`
				XHTTP struct {
					Download struct {
						RealitySettings struct {
							Fingerprint string `json:"fingerprint"`
						} `json:"realitySettings"`
						TLSSettings struct {
							Fingerprint string `json:"fingerprint"`
						} `json:"tlsSettings"`
					} `json:"downloadSettings"`
				} `json:"xhttpSettings"`
			} `json:"streamSettings"`
		} `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	if len(cfg.Outbounds) == 0 {
		t.Fatal("rendered config has no outbounds")
	}
	s := cfg.Outbounds[0].StreamSettings
	uplink = s.RealitySettings.Fingerprint
	if uplink == "" {
		uplink = s.TLSSettings.Fingerprint
	}
	d := s.XHTTP.Download
	downlink = d.RealitySettings.Fingerprint
	if downlink == "" {
		downlink = d.TLSSettings.Fingerprint
	}
	return uplink, downlink
}

func TestRenderXHTTPDownloadFingerprintMirrorsUplink(t *testing.T) {
	// The downlink must carry exactly the uplink's fingerprint: any
	// divergence between the two ClientHellos of one config is a detect
	// signal. The pinned "chrome" alias renders as-is (explicit is
	// explicit); hellochrome_auto and versioned parrots must pass through.
	cases := map[string]string{
		"pinned chrome alias": "chrome",
		"auto parrot":         "hellochrome_auto",
		"explicit versioned":  "hellochrome_155",
		"case-insensitive":    " HelloChrome_Auto ",
	}
	for _, tlsOnly := range []bool{false, true} {
		for name, fp := range cases {
			raw, err := Render(xhttpPlanWithFingerprint(fp, tlsOnly), testRuntime, nil)
			if err != nil {
				t.Fatalf("%s (tlsOnly=%v): must render, got %v", name, tlsOnly, err)
			}
			up, down := xhttpFingerprints(t, raw)
			want := engine.NormalizeFingerprint(fp)
			if up != want || down != want {
				t.Errorf("%s (tlsOnly=%v): uplink=%q downlink=%q, want both %q", name, tlsOnly, up, down, want)
			}
		}
	}
}

func TestRenderXHTTPDownloadFingerprintProbeHintInherited(t *testing.T) {
	// With no explicit plan fingerprint, the downlink inherits the
	// outbound's own probe-discovered hint — the same source the uplink
	// reality fingerprint resolves from — so the two legs stay identical.
	p := xhttpPlanWithFingerprint("", false)
	raw, err := render(p, testRuntime, nil, map[string]string{p.Outbounds[0].ID: "firefox"})
	if err != nil {
		t.Fatal(err)
	}
	up, down := xhttpFingerprints(t, raw)
	if down != "firefox" {
		t.Errorf("downlink fingerprint = %q, want the probe hint %q", down, "firefox")
	}
	if up != down {
		t.Errorf("uplink=%q downlink=%q: the two legs must not diverge", up, down)
	}
}

func TestRenderXHTTPDownloadFingerprintProbeHintNormalized(t *testing.T) {
	// A probe hint that is not already normalized (case/whitespace) must
	// still land identically on both legs: the uplink normalizes the hint
	// exactly like the downlink, so the two ClientHellos cannot diverge.
	p := xhttpPlanWithFingerprint("", false)
	raw, err := render(p, testRuntime, nil, map[string]string{p.Outbounds[0].ID: " HelloChrome_Auto "})
	if err != nil {
		t.Fatal(err)
	}
	up, down := xhttpFingerprints(t, raw)
	if up != "hellochrome_auto" || down != "hellochrome_auto" {
		t.Errorf("uplink=%q downlink=%q: both legs must render the normalized hint %q", up, down, "hellochrome_auto")
	}
}

func TestRenderXHTTPDownloadFingerprintRefused(t *testing.T) {
	// Empty or Xray-unknown fingerprints must fail at render time with a
	// named error — never a silent default or a name Xray would reject at
	// startup.
	cases := map[string]string{
		"empty":               "",
		"whitespace":          "   ",
		"unknown fingerprint": "not-a-parrot",
		"typo of chrome":      "chorme",
	}
	for _, tlsOnly := range []bool{false, true} {
		for name, fp := range cases {
			if _, err := Render(xhttpPlanWithFingerprint(fp, tlsOnly), testRuntime, nil); err == nil {
				t.Errorf("%s (tlsOnly=%v): must be refused, not silently rendered", name, tlsOnly)
			}
		}
	}
}

func TestRenderRefusesIncompatibleTransportPairs(t *testing.T) {
	// REALITY is documented as unsupported with websocket and httpupgrade;
	// XTLS Vision only under TCP+TLS/REALITY.
	// https://xtls.github.io/en/config/transport.html
	// https://xtls.github.io/en/config/outbounds/vless.html
	cases := map[string]func(*engine.Plan){
		"websocket+reality": func(p *engine.Plan) {
			p.Outbounds[0].Flow = ""
			p.Outbounds[0].Transport = engine.Transport{Type: "ws", Path: "/ws"}
		},
		"httpupgrade+reality": func(p *engine.Plan) {
			p.Outbounds[0].Flow = ""
			p.Outbounds[0].Transport = engine.Transport{Type: "httpupgrade", Path: "/up"}
		},
		"xhttp+vision": func(p *engine.Plan) {
			p.Outbounds[0].Transport = engine.Transport{Type: "xhttp", Path: "/x"}
		},
		"grpc+vision": func(p *engine.Plan) {
			p.Outbounds[0].Transport = engine.Transport{Type: "grpc", Service: "tun"}
		},
	}
	for name, mutate := range cases {
		p := enginetest.Plan(engine.ProtocolVLESS) // reality + vision by default
		mutate(p)
		if _, err := Render(p, testRuntime, nil); err == nil {
			t.Errorf("%s: must be refused instead of rendering a config that fails at runtime", name)
		}
	}
}

func TestRenderAcceptsCompatibleTransportPairs(t *testing.T) {
	// Positive controls for the refusals above: these pairs are supported.
	cases := map[string]func(*engine.Plan){
		"xhttp+reality": func(p *engine.Plan) {
			p.Outbounds[0].Flow = ""
			p.Outbounds[0].Transport = engine.Transport{Type: "xhttp", Path: "/x"}
		},
		"grpc+reality": func(p *engine.Plan) {
			p.Outbounds[0].Flow = ""
			p.Outbounds[0].Transport = engine.Transport{Type: "grpc", Service: "tun"}
		},
		"websocket+tls": func(p *engine.Plan) {
			o := &p.Outbounds[0]
			o.Flow, o.TLS.Reality = "", false
			o.TLS = engine.TLS{Enabled: true, ServerName: "cdn.example.com"}
			o.Transport = engine.Transport{Type: "ws", Path: "/ws"}
		},
		"tcp+vision+reality": func(p *engine.Plan) {},
		"xhttp+vision+vless-encryption": func(p *engine.Plan) {
			// PASS3 deep S3b: under VLESS Encryption XTLS has no
			// underlying transport restrictions, so the panels'
			// encryption+xhttp+vision combination must render.
			o := &p.Outbounds[0]
			o.Encryption = "mlkem768x25519plus.native.0rtt.Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw"
			o.Transport = engine.Transport{Type: "xhttp", Path: "/x", Mode: "packet-up"}
		},
		"grpc+vision+vless-encryption": func(p *engine.Plan) {
			o := &p.Outbounds[0]
			o.Encryption = "mlkem768x25519plus.native.0rtt.Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw"
			o.Transport = engine.Transport{Type: "grpc", Service: "tun"}
		},
	}
	for name, mutate := range cases {
		p := enginetest.Plan(engine.ProtocolVLESS)
		mutate(p)
		if _, err := Render(p, testRuntime, nil); err != nil {
			t.Errorf("%s: supported pair must render, got %v", name, err)
		}
	}
}

func TestRenderECH(t *testing.T) {
	// CENSOR-FP: the PASS3 refusal is superseded by a wire probe on
	// the pinned 26.10.17 binary — with echConfigList set, the outer
	// SNI of the captured ClientHello becomes the list's public_name
	// (real ECH, not GREASE). The renderer now emits the pinned list
	// as one base64 string, or echForceQuery "full" when unpinned,
	// and still refuses the one shape Xray cannot spell: a distinct
	// query_server_name override.
	mk := func(ech engine.ECHConfig) *engine.Plan {
		p := enginetest.Plan(engine.ProtocolVLESS)
		o := &p.Outbounds[0]
		o.Flow, o.TLS.Reality = "", false
		o.TLS = engine.TLS{Enabled: true, ServerName: "cdn.example.com", ECH: ech}
		return p
	}
	tlsSettings := func(t *testing.T, raw []byte) map[string]any {
		t.Helper()
		var cfg struct {
			Outbounds []struct {
				StreamSettings struct {
					TLSSettings map[string]any `json:"tlsSettings"`
				} `json:"streamSettings"`
			} `json:"outbounds"`
		}
		if err := json.Unmarshal(raw, &cfg); err != nil {
			t.Fatal(err)
		}
		return cfg.Outbounds[0].StreamSettings.TLSSettings
	}
	// Pinned: the canonical base64 of the plan's list.
	pinned := []string{"-----BEGIN ECHCONFIG-----", "QUJD", "-----END ECHCONFIG-----"}
	raw, err := Render(mk(engine.ECHConfig{Enabled: true, Config: pinned}), testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if got := tlsSettings(t, raw)["echConfigList"]; got != "QUJD" {
		t.Errorf("echConfigList = %v, want the canonical base64 QUJD", got)
	}
	// Unpinned: Xray fetches the list itself.
	raw, err = Render(mk(engine.ECHConfig{Enabled: true}), testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if got := tlsSettings(t, raw)["echForceQuery"]; got != "full" {
		t.Errorf("echForceQuery = %v, want full", got)
	}
	// QueryServerName has no Xray spelling: named refusal.
	if _, err := Render(mk(engine.ECHConfig{Enabled: true, QueryServerName: "ech.example.com"}), testRuntime, nil); err == nil || !strings.Contains(err.Error(), "query_server_name") {
		t.Fatalf("ECH query_server_name on the Xray path must be refused with a named error, got %v", err)
	}
}

func TestRenderPinsHysteria2NativeMapping(t *testing.T) {
	// Xray's "hysteria" outbound IS the native Hysteria2 implementation
	// (upstream requires settings.version == 2); this pins the mapping so it
	// can never silently regress to a legacy wrapper.
	p := hysteriaWithoutObfs(enginetest.Plan(engine.ProtocolHysteria2))
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Outbounds []struct {
			Protocol string `json:"protocol"`
			Settings struct {
				Version int    `json:"version"`
				Address string `json:"address"`
				Port    int    `json:"port"`
			} `json:"settings"`
		} `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	ob := cfg.Outbounds[0]
	if ob.Protocol != "hysteria" {
		t.Errorf("protocol = %q, want hysteria", ob.Protocol)
	}
	if ob.Settings.Version != 2 || ob.Settings.Address != "edge.example.com" || ob.Settings.Port != 443 {
		t.Errorf("settings = %+v, want version 2 on edge.example.com:443", ob.Settings)
	}
}

func TestRenderPassesHysteria2BandwidthToBrutal(t *testing.T) {
	p := hysteriaWithoutObfs(enginetest.Plan(engine.ProtocolHysteria2))
	p.Outbounds[0].UpMbps, p.Outbounds[0].DownMbps = 100, 500
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Outbounds []struct {
			StreamSettings struct {
				HysteriaSettings map[string]any `json:"hysteriaSettings"`
			} `json:"streamSettings"`
		} `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	hy := cfg.Outbounds[0].StreamSettings.HysteriaSettings
	if hy["up_mbps"] != float64(100) || hy["down_mbps"] != float64(500) {
		t.Errorf("hysteriaSettings = %v, want up_mbps=100 down_mbps=500 (brutal CC)", hy)
	}

	// Zero caps must stay absent: an explicit 0 would pin brutal to
	// nothing; the engine default (BBR) applies instead.
	p = hysteriaWithoutObfs(enginetest.Plan(engine.ProtocolHysteria2))
	raw, err = Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), "up_mbps") || strings.Contains(string(raw), "down_mbps") {
		t.Errorf("zero bandwidth caps must not render: %s", raw)
	}
}

func realityFingerprintOf(t *testing.T, raw []byte) string {
	t.Helper()
	var cfg struct {
		Outbounds []struct {
			StreamSettings struct {
				RealitySettings struct {
					Fingerprint string `json:"fingerprint"`
				} `json:"realitySettings"`
			} `json:"streamSettings"`
		} `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	if len(cfg.Outbounds) == 0 {
		t.Fatal("rendered config has no outbounds")
	}
	return cfg.Outbounds[0].StreamSettings.RealitySettings.Fingerprint
}

func TestRenderRealityFingerprintDefaultsToAuto(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].TLS.Fingerprint = ""
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	fp := realityFingerprintOf(t, raw)
	if fp != engine.DefaultXrayFingerprint {
		t.Fatalf("reality fingerprint = %q, want the auto default %q", fp, engine.DefaultXrayFingerprint)
	}
	if fp == "chrome" {
		t.Fatal("the pinned chrome alias (Chrome 133, TSPU-blocked) must not be the default")
	}
}

func TestRenderRealityFingerprintExplicitWins(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].TLS.Fingerprint = "firefox"
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if fp := realityFingerprintOf(t, raw); fp != "firefox" {
		t.Fatalf("reality fingerprint = %q, want the explicit %q", fp, "firefox")
	}
}

func TestRenderNormalizesFingerprintCase(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].TLS.Fingerprint = "HelloChrome_Auto"
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if fp := realityFingerprintOf(t, raw); fp != "hellochrome_auto" {
		t.Fatalf("reality fingerprint = %q, want normalized %q", fp, "hellochrome_auto")
	}
}

func TestRenderAppliesFingerprintHint(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].TLS.Fingerprint = ""
	raw, err := render(p, testRuntime, nil, map[string]string{"vless": "safari"})
	if err != nil {
		t.Fatal(err)
	}
	if fp := realityFingerprintOf(t, raw); fp != "safari" {
		t.Fatalf("reality fingerprint = %q, want the probe-discovered hint %q", fp, "safari")
	}

	// An explicit plan fingerprint still beats a stale hint.
	p.Outbounds[0].TLS.Fingerprint = "firefox"
	raw, err = render(p, testRuntime, nil, map[string]string{"vless": "safari"})
	if err != nil {
		t.Fatal(err)
	}
	if fp := realityFingerprintOf(t, raw); fp != "firefox" {
		t.Fatalf("reality fingerprint = %q, want the explicit %q over the hint", fp, "firefox")
	}
}

func TestRealityWithoutVision(t *testing.T) {
	cases := []struct {
		name string
		o    engine.Outbound
		want bool
	}{
		{"vless reality without flow", engine.Outbound{Protocol: engine.ProtocolVLESS, TLS: engine.TLS{Reality: true}}, true},
		{"vless reality with vision", engine.Outbound{Protocol: engine.ProtocolVLESS, Flow: "xtls-rprx-vision", TLS: engine.TLS{Reality: true}}, false},
		{"vless reality with vision-udp443", engine.Outbound{Protocol: engine.ProtocolVLESS, Flow: "xtls-rprx-vision-udp443", TLS: engine.TLS{Reality: true}}, false},
		{"vless tls without flow", engine.Outbound{Protocol: engine.ProtocolVLESS, TLS: engine.TLS{Enabled: true}}, false},
		{"vmess reality without flow", engine.Outbound{Protocol: engine.ProtocolVMess, TLS: engine.TLS{Reality: true}}, false},
		{"vless without reality", engine.Outbound{Protocol: engine.ProtocolVLESS}, false},
	}
	for _, tc := range cases {
		if got := realityWithoutVision(tc.o); got != tc.want {
			t.Errorf("%s: realityWithoutVision = %v, want %v", tc.name, got, tc.want)
		}
	}
}

// TestRenderRejectsDoH3WithGuidance locks the honest failure: Xray has no
// DNS-over-HTTP/3 transport, so an h3:// resolver must fail the render
// with an actionable message instead of a bare "not supported".
func TestRenderRejectsDoH3WithGuidance(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS = engine.DNS{Enabled: true, Servers: []engine.DNSServer{
		{Tag: "dns-1", Transport: engine.DNSH3, Address: "1.1.1.1"},
	}}
	_, err := Render(p, testRuntime, nil)
	if err == nil || !strings.Contains(err.Error(), "DNS-over-HTTP/3") {
		t.Fatalf("h3 render must fail naming DNS-over-HTTP/3, got: %v", err)
	}
}

func TestRenderRefusesAmneziaWG(t *testing.T) {
	// T012: Xray cannot apply AmneziaWG obfuscation at all. Rendering the
	// outbound anyway would put plain WireGuard on the wire while the plan
	// promises obfuscation - the exact silent no-op this fails closed on.
	p := enginetest.Plan(engine.ProtocolWireGuard)
	p.Outbounds[0].Amnezia = enginetest.AmneziaWG().Amnezia
	_, err := Render(p, testRuntime, nil)
	if err == nil || !strings.Contains(err.Error(), "AmneziaWG") {
		t.Fatalf("xray Render must refuse AmneziaWG parameters, got: %v", err)
	}
}

// TestRenderRejectsVisionOnNonTCP locks the S2 validation contract:
// vision on a non-TCP transport cannot work, so the render fails hard
// instead of emitting a config Xray would reject at runtime. Auto-vision
// never produces this combination (it only fires on TCP); this guards
// the manual-flow path.
func TestRenderRejectsVisionOnNonTCP(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Transport.Type = "ws"
	p.Outbounds[0].Transport.Path = "/x"
	p.Outbounds[0].TLS = engine.TLS{Enabled: true}
	p.Outbounds[0].Flow = "xtls-rprx-vision"
	if _, err := Render(p, testRuntime, nil); err == nil ||
		!strings.Contains(err.Error(), "requires the TCP transport") {
		t.Fatalf("vision+ws render must fail naming the TCP requirement, got: %v", err)
	}
}

// TestRenderLocalProxyListenFollowsAllowLAN locks C7 in the Xray render:
// the socks inbound binds every interface only for a LAN-shared plan
// carrying a login; anything else stays on loopback.
func TestRenderLocalProxyListenFollowsAllowLAN(t *testing.T) {
	listen := func(p *engine.Plan) (string, map[string]any) {
		raw, err := Render(p, testRuntime, nil)
		if err != nil {
			t.Fatal(err)
		}
		var cfg struct {
			Inbounds []map[string]any `json:"inbounds"`
		}
		if err := json.Unmarshal(raw, &cfg); err != nil {
			t.Fatal(err)
		}
		for _, in := range cfg.Inbounds {
			if in["protocol"] == "socks" {
				settings, _ := in["settings"].(map[string]any)
				got, _ := in["listen"].(string)
				return got, settings
			}
		}
		t.Fatalf("no socks inbound in %s", raw)
		return "", nil
	}
	p := enginetest.Plan(engine.ProtocolVLESS)
	if got, _ := listen(p); got != "127.0.0.1" {
		t.Errorf("default listen = %q, want loopback", got)
	}
	p.Options.AllowLAN = true
	p.LocalProxy.Username, p.LocalProxy.Password = "sora", "lan-sharing-password"
	got, settings := listen(p)
	if got != "0.0.0.0" {
		t.Errorf("LAN listen = %q, want 0.0.0.0", got)
	}
	if settings["auth"] != "password" {
		t.Errorf("the LAN listener must require the login: %v", settings)
	}
}
