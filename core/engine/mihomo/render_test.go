package mihomo

import (
	"context"
	"net/netip"
	"os"
	"runtime"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func testPlan() *engine.Plan {
	return &engine.Plan{
		SessionID:  "session-1",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Outbounds: []engine.Outbound{
			{
				ID: "srv-1", Name: "Tokyo 01", Protocol: engine.ProtocolVLESS,
				Server: "jp.example.com", Port: 443, UUID: "11111111-2222-3333-4444-555555555555",
				Flow:      "xtls-rprx-vision",
				TLS:       engine.TLS{Enabled: true, ServerName: "jp.example.com", ALPN: []string{"h2", "http/1.1"}, Fingerprint: "chrome"},
				Transport: engine.Transport{Type: "tcp"},
			},
			{
				ID: "srv-2", Name: "Berlin H2", Protocol: engine.ProtocolHysteria2,
				Server: "de.example.com", Port: 8443, Password: "hunter2hunter2",
				TLS: engine.TLS{Enabled: true, ServerName: "de.example.com"},
			},
			{ID: "direct", Protocol: engine.ProtocolDirect},
		},
		Groups: []engine.Group{
			{Name: "Выбор сервера", Type: engine.GroupSelect, Outbounds: []string{"srv-1", "srv-2", "direct"}},
			{Name: "Авто", Type: engine.GroupURLTest, Outbounds: []string{"srv-1", "srv-2"}, Interval: 120},
		},
		Rules: []engine.Rule{
			{Type: engine.RuleGeoSite, Value: "ads", Target: "reject"},
			{Type: engine.RuleDomainSuffix, Value: "internal.local", Target: "direct"},
			{Type: engine.RuleIPCIDR, Value: "10.0.0.0/8", Target: "direct", NoResolve: true},
			{Type: engine.RuleIPCIDR, Value: "2001:db8::/32", Target: "srv-1"},
			{Type: engine.RuleMatchAll, Target: "srv-2"},
		},
		DNS: engine.DNS{
			Enabled: true, Mode: string(engine.DNSFakeIP),
			Servers: []engine.DNSServer{{Tag: "ali", Transport: engine.DNSTLS, Address: "223.5.5.5"}},
		},
		Tun:     engine.Tun{Enabled: true, Stack: "mixed", MTU: 1420, AutoRoute: true},
		Options: engine.Options{LogLevel: "warning", Mode: "rule", GeoData: true, TestURL: engine.TestURLProduction},
	}
}

func testRuntime(t *testing.T) Runtime {
	t.Helper()
	return Runtime{
		HomeDir:        t.TempDir(),
		ControllerAddr: "127.0.0.1:23456",
		Secret:         "c0ffee",
		MixedPort:      21000,
		TestURL:        engine.TestURLProduction,
	}
}

func TestRenderProducesEveryBlockTheEngineNeeds(t *testing.T) {
	out, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	wants := []string{
		"mixed-port: 21000",
		"external-controller: 127.0.0.1:23456",
		"secret: c0ffee",
		"type: vless",
		"flow: xtls-rprx-vision",
		"client-fingerprint: chrome",
		"type: hysteria2",
		"- direct",
		"type: direct",
		"type: select",
		"type: url-test",
		"url: " + engine.TestURLProduction,
		"interval: 120",
		"GEOSITE,ads,REJECT",
		"DOMAIN-SUFFIX,internal.local,DIRECT",
		"IP-CIDR,10.0.0.0/8,DIRECT,no-resolve",
		"IP-CIDR6,2001:db8::/32,Tokyo_01",
		"MATCH,Berlin_H2",
		"enhanced-mode: fake-ip",
		"fake-ip-range: 198.18.0.0/15",
		"stack: mixed",
		"mtu: 1420",
		"geox-url:",
		"store-selected: true",
	}
	for _, want := range wants {
		if !strings.Contains(out, want) {
			t.Errorf("rendered config is missing %q\n---\n%s", want, out)
		}
	}
}

func TestRenderKeepsThePlanRuleOrder(t *testing.T) {
	out, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	order := map[string]int{}
	for i, line := range strings.Split(out, "\n") {
		trimmed := strings.TrimSpace(line)
		switch {
		case strings.HasPrefix(trimmed, "- GEOSITE,ads"):
			order["geo"] = i
		case strings.HasPrefix(trimmed, "- DOMAIN-SUFFIX,internal.local"):
			order["domain"] = i
		case strings.HasPrefix(trimmed, "- IP-CIDR6"):
			order["v6"] = i
		case strings.HasPrefix(trimmed, "- MATCH,"):
			order["match"] = i
		}
	}
	if len(order) != 4 {
		t.Fatalf("rules not found as expected: %+v\n%s", order, out)
	}
	if order["geo"] >= order["domain"] || order["domain"] >= order["v6"] || order["v6"] >= order["match"] {
		t.Fatalf("rule order lost: %+v\n%s", order, out)
	}
}

func TestRenderIsDeterministic(t *testing.T) {
	first, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	second, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if first != second {
		t.Error("the same plan must render the same config")
	}
}

func TestRenderRefusesTunWithoutDNS(t *testing.T) {
	plan := testPlan()
	plan.DNS.Enabled = false
	if _, err := Render(plan, testRuntime(t)); err == nil {
		t.Fatal("a tun plan without a resolver must be refused before the engine is started")
	}
}

func TestTunUsesSeparateAddressesEvenWithoutFakeDNS(t *testing.T) {
	p := testPlan()
	p.Tun.IPv4 = netip.MustParsePrefix("192.0.2.5/30")
	p.Tun.IPv6 = netip.MustParsePrefix("2001:db8:5341::1/126")
	p.DNS.Mode = "redir-host"
	p.DNS.FakeIPRange = "198.18.0.0/16"
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	var c config
	if err := yaml.Unmarshal([]byte(out), &c); err != nil {
		t.Fatal(err)
	}
	if len(c.Listeners) != 1 {
		t.Fatal("missing TUN listener")
	}
	tun := c.Listeners[0]
	if c.DNS.FakeIPRange != "" || tun.Type != "tun" || tun.Inet4Address[0] != p.Tun.IPv4.String() || tun.Inet6Address[0] != p.Tun.IPv6.String() {
		t.Fatalf("DNS=%+v TUN=%+v", c.DNS, tun)
	}
	p.DNS.Mode = string(engine.DNSFakeIP)
	out, err = Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if err := yaml.Unmarshal([]byte(out), &c); err != nil {
		t.Fatal(err)
	}
	if c.DNS.FakeIPRange != p.DNS.FakeIPRange {
		t.Fatal("fake-IP pool changed to adapter pool")
	}
	if runtime.GOOS == "linux" && (*tun.AutoRoute || *tun.AutoDetectInterface) {
		t.Fatal("Linux routing must belong to the core")
	}
}

func TestRenderSendsProxyOnlyServersToTheProxyResolver(t *testing.T) {
	plan := testPlan()
	plan.DNS.Servers = []engine.DNSServer{
		{Tag: "lane", Transport: engine.DNSTLS, Address: "1.1.1.1", Port: 853, ProxyOnly: true},
		{Tag: "lan", Transport: engine.DNSPlain, Address: "192.168.1.1", Port: 53},
	}
	out, err := Render(plan, testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	begin := strings.Index(out, "proxy-server-nameserver:")
	end := strings.Index(out, "direct-nameserver:")
	if begin < 0 || end < begin {
		t.Fatalf("no proxy resolver block\n---\n%s", out)
	}
	block := out[begin:end]
	if !strings.Contains(block, "tls://1.1.1.1:853") {
		t.Errorf("the proxy-only server must resolve proxy hostnames, got %q", block)
	}
	if strings.Contains(block, "192.168.1.1") {
		t.Errorf("an ordinary server must not join the proxy resolver, got %q", block)
	}
}

func TestSanitizeNameNeutralizesEngineNameInjection(t *testing.T) {
	got := sanitizeName("a,Match,DIRECT\nname", "id-1")
	if strings.ContainsAny(got, ",\n ") {
		t.Fatalf("sanitized name still carries separators: %q", got)
	}
	if sanitizeName("", "") != "server" {
		t.Error("an empty name must fall back to a usable value")
	}
}

// TestEngineAcceptsRenderedPlans runs "mihomo -t" to check types and values.
// Unknown keys are ignored upstream, so proxy.go pins key names to engine
// source.
func TestEngineAcceptsRenderedPlans(t *testing.T) {
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to run mihomo against the rendered plans", Prober.EnvVar)
	}
	ctx := context.Background()
	binary, err := Prober.Probe(ctx, path)
	if err != nil {
		t.Fatal(err)
	}
	all := enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolVMess, engine.ProtocolTrojan,
		engine.ProtocolShadowsocks, engine.ProtocolHysteria2, engine.ProtocolTUIC,
		engine.ProtocolWireGuard, engine.ProtocolSOCKS5, engine.ProtocolHTTP, engine.ProtocolDirect)
	all.Outbounds = append(all.Outbounds, enginetest.AmneziaWG())
	xhttp := enginetest.Plan(engine.ProtocolVLESS)
	xhttp.Outbounds[0].Flow = ""
	xhttp.Outbounds[0].Transport = engine.Transport{Type: "xhttp", Path: "/x", Host: "cdn.example.com", Mode: "stream-one"}
	for name, p := range map[string]*engine.Plan{"all protocols and amneziawg": all, "xhttp": xhttp} {
		t.Run(name, func(t *testing.T) {
			rendered, err := Render(p, Runtime{ControllerAddr: "127.0.0.1:9090", Secret: "s", MixedPort: 7890})
			if err != nil {
				t.Fatal(err)
			}
			home := t.TempDir()
			rt := supervise.Runtime{HomeDir: home}
			if err := (driver{}).Prepare(rt, binary); err != nil {
				t.Fatal(err)
			}
			if err := supervise.Check(ctx, supervise.Spec{Name: "mihomo", Path: binary.Path, Args: driver{}.CheckArgs(rt), Dir: home, Config: []byte(rendered)}); err != nil {
				t.Fatal(err)
			}
			if name != "xhttp" && !strings.Contains(rendered, "amnezia-wg-option") {
				t.Fatal("the AmneziaWG block is missing")
			}
		})
	}
}

func TestRenderAnyTLSProxy(t *testing.T) {
	p := testPlan()
	p.Outbounds[0] = engine.Outbound{
		ID: "srv-1", Name: "AnyTLS 01", Protocol: engine.ProtocolAnyTLS,
		Server: "at.example.com", Port: 443, Password: "anytls-test-password",
		TLS: engine.TLS{Enabled: true, ServerName: "at.example.com", Fingerprint: "chrome"},
	}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"type: anytls", "password: anytls-test-password", "client-fingerprint: chrome", "tls: true"} {
		if !strings.Contains(out, want) {
			t.Fatalf("rendered mihomo config must contain %q, got:\n%s", want, out)
		}
	}
	var cfg struct {
		Proxies []map[string]any `yaml:"proxies"`
	}
	if err := yaml.Unmarshal([]byte(out), &cfg); err != nil {
		t.Fatal(err)
	}
	for _, px := range cfg.Proxies {
		if px["type"] != "anytls" {
			continue
		}
		if _, ok := px["network"]; ok {
			t.Fatalf("anytls has no stream transport, got network: %v", px["network"])
		}
		return
	}
	t.Fatal("anytls proxy is missing from the rendered config")
}

func TestRenderECHProxyToggle(t *testing.T) {
	p := testPlan()
	p.Outbounds[0].TLS.ECH = engine.ECHConfig{Enabled: true}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out, "ech-opts:") || !strings.Contains(out, "enable: true") {
		t.Fatalf("rendered mihomo config must enable ech via ech-opts, got:\n%s", out)
	}
	if strings.Contains(out, "\n    ech: true") {
		t.Fatalf("the legacy flat ech toggle must not be emitted anymore:\n%s", out)
	}
}

func TestRenderECHPinnedConfigAndQueryServerName(t *testing.T) {
	// PASS3 deep S4: the pinned config and the query name used to be
	// dropped (only `ech: true` was rendered). The plan stores PEM
	// lines; ech-opts.config is one base64 string.
	p := testPlan()
	p.Outbounds[0].TLS.ECH = engine.ECHConfig{
		Enabled: true,
		Config: []string{
			"-----BEGIN ECHCONFIG-----",
			"AE7+DQA8NwAgACBwaW5uZWQtZWNoLXRlc3QtY29uZmln",
			"-----END ECHCONFIG-----",
		},
		QueryServerName: "ech-query.example.com",
	}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		"config: AE7+DQA8NwAgACBwaW5uZWQtZWNoLXRlc3QtY29uZmln",
		"query-server-name: ech-query.example.com",
	} {
		if !strings.Contains(out, want) {
			t.Fatalf("rendered mihomo config is missing %q:\n%s", want, out)
		}
	}
	if strings.Contains(out, "BEGIN ECHCONFIG") {
		t.Fatalf("PEM armor must not reach ech-opts.config:\n%s", out)
	}
}

func TestRenderECHRejectsUnmergeablePinnedConfigs(t *testing.T) {
	p := testPlan()
	p.Outbounds[0].TLS.ECH = engine.ECHConfig{
		Enabled: true,
		Config: []string{
			"-----BEGIN ECHCONFIG-----", "QUJD", "-----END ECHCONFIG-----",
			"-----BEGIN ECHCONFIG-----", "REVG", "-----END ECHCONFIG-----",
		},
	}
	if _, err := Render(p, testRuntime(t)); err == nil {
		t.Fatal("two pinned ECHConfigLists cannot merge into mihomo's single config value and must be refused")
	}
	p.Outbounds[0].TLS.ECH.Config = []string{"not base64!!!"}
	if _, err := Render(p, testRuntime(t)); err == nil {
		t.Fatal("a non-base64 pinned ECH config must be refused, not rendered")
	}
}

// TestRenderXHTTPReuseSettings pins PASS3 deep A1: without
// reuse-settings mihomo disables connection reuse entirely (no
// default value upstream — every request opens a new connection),
// so the block is always rendered: the docs' example default when
// the plan tunes nothing, the plan's tuning when it does.
func TestRenderXHTTPReuseSettings(t *testing.T) {
	xhttpPlan := func(mut func(*engine.Transport)) *engine.Plan {
		p := enginetest.Plan(engine.ProtocolVLESS)
		p.Outbounds[0].Flow = ""
		tr := engine.Transport{Type: "xhttp", Path: "/x", Host: "cdn.example.com"}
		if mut != nil {
			mut(&tr)
		}
		p.Outbounds[0].Transport = tr
		return p
	}
	render := func(p *engine.Plan) string {
		out, err := Render(p, testRuntime(t))
		if err != nil {
			t.Fatal(err)
		}
		return out
	}

	out := render(xhttpPlan(nil))
	if !strings.Contains(out, "reuse-settings:") || !strings.Contains(out, "16-32") {
		t.Fatalf("an untuned xhttp plan must still render reuse-settings with the docs default:\n%s", out)
	}

	out = render(xhttpPlan(func(tr *engine.Transport) {
		tr.XmuxMaxConnections = 4
		tr.XmuxMaxReuseTimes = 10
		tr.XmuxMaxRequestTimes = 600
		tr.XPaddingBytes = "100-1000"
	}))
	for _, want := range []string{"max-connections:", "c-max-reuse-times:", "h-max-request-times:", "x-padding-bytes: 100-1000"} {
		if !strings.Contains(out, want) {
			t.Fatalf("tuned xhttp render is missing %q:\n%s", want, out)
		}
	}
	if strings.Contains(out, "max-concurrency") {
		t.Fatalf("a tuned plan must not grow the default max-concurrency (it conflicts with max-connections):\n%s", out)
	}

	// mode: auto is a documented mihomo mode value and must pass
	// through verbatim (PASS3 deep A1 sub-check, resolved by docs).
	out = render(xhttpPlan(func(tr *engine.Transport) { tr.Mode = "auto" }))
	if !strings.Contains(out, "mode: auto") {
		t.Fatalf("mode auto must render verbatim:\n%s", out)
	}
}

// TestRenderXHTTPDownloadSettings pins the download-settings leg of
// PASS3 deep A1: a split plan renders the separate downlink server
// with its own reuse-settings; unset items inherit the uplink.
func TestRenderXHTTPDownloadSettings(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Flow = ""
	p.Outbounds[0].Transport = engine.Transport{
		Type: "xhttp", Path: "/x", Host: "cdn.example.com", Mode: "stream-up",
		DownloadAddress: "dl.example.com", DownloadPort: 8443,
	}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"download-settings:", "server: dl.example.com", "port: 8443"} {
		if !strings.Contains(out, want) {
			t.Fatalf("split xhttp render is missing %q:\n%s", want, out)
		}
	}
}

func TestRenderOmitsECHByDefault(t *testing.T) {
	out, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out, "ech-opts") {
		t.Fatalf("rendered mihomo config must not mention ech unless enabled, got:\n%s", out)
	}
}

func TestRenderHysteria2OmitsZeroBandwidth(t *testing.T) {
	// No caps: the engine stays on BBR and no up/down keys may appear.
	out, err := Render(testPlan(), testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	for _, line := range strings.Split(out, "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "up:") || strings.HasPrefix(trimmed, "down:") {
			t.Fatalf("rendered hysteria2 proxy must not carry zero bandwidth caps, got %q", trimmed)
		}
	}
}

func TestRenderHysteria2BandwidthAndHopping(t *testing.T) {
	p := testPlan()
	p.Outbounds[1].UpMbps, p.Outbounds[1].DownMbps = 20, 100
	p.Outbounds[1].HopPorts = "20000-30000"
	p.Outbounds[1].HopInterval = 30
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"up: 20 Mbps", "down: 100 Mbps", "ports: 20000-30000", "hop-interval: 30"} {
		if !strings.Contains(out, want) {
			t.Fatalf("rendered mihomo config is missing %q:\n%s", want, out)
		}
	}
}

func TestRenderTUICTuning(t *testing.T) {
	p := testPlan()
	p.Outbounds = append(p.Outbounds, engine.Outbound{
		ID: "srv-3", Name: "TUIC", Protocol: engine.ProtocolTUIC,
		Server: "tu.example.com", Port: 443,
		UUID: "11111111-2222-3333-4444-555555555555", Password: "tuic-test-password",
		CongestionControl: "cubic", UDPRelayMode: "quic", Token: "v4-token",
		TLS: engine.TLS{Enabled: true, ServerName: "tu.example.com"},
	})
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"type: tuic", "congestion-controller: cubic", "udp-relay-mode: quic", "token: v4-token"} {
		if !strings.Contains(out, want) {
			t.Fatalf("rendered mihomo config is missing %q:\n%s", want, out)
		}
	}
}

// TestAmneziaOptionsRenders31 pins the corrected AWG matrix (PASS2
// deep S1, PASS3): the pinned mihomo implements AWG 3.x since
// 1.19.30, so a 3.1 parameter set renders — with version: 3, without
// which mihomo would build the legacy device and silently ignore
// every 3.x key. The enginetest 3.1 vector also carries masquerade
// sugar, which mihomo has no fields for: that combination, and
// 3.x + v1.5-only J*/Itime, still fail closed.
func TestAmneziaOptionsRenders31(t *testing.T) {
	a := *enginetest.AmneziaWG3().Amnezia
	a.MasqueradeProtocol, a.MasqueradeDomain, a.MasqueradeBrowser = "", "", ""
	opts, err := amneziaOptions(&a)
	if err != nil {
		t.Fatalf("amneziaOptions(3.1) = %v, want nil", err)
	}
	if opts["version"] != 3 {
		t.Fatalf("version = %v, want 3 (without it the 3.x keys are ignored)", opts["version"])
	}
	for key, want := range map[string]string{
		"header-protection-key":    a.HeaderProtectionKey,
		"content-padding-addition": "32-96",
		"rekey-after-time":         "100-140",
		"rekey-timeout":            "5",
		"reject-after-time":        "170-190",
		"keepalive-timeout":        "8-12",
		"max-handshake-attempts":   "16-20",
	} {
		if opts[key] != want {
			t.Errorf("opts[%q] = %v, want %q", key, opts[key], want)
		}
	}
	if opts["random-trailers"] != true || opts["disable-cookies"] != true {
		t.Errorf("trailers/cookies = %v/%v, want true/true", opts["random-trailers"], opts["disable-cookies"])
	}
	// The 1.x/2.0 base keys ride along unchanged.
	if opts["jc"] != 8 || opts["h3"] != int64(3) {
		t.Errorf("base keys must keep rendering under v3: %v", opts)
	}

	// Full render: the YAML carries the v3 block end to end.
	p := enginetest.Plan(engine.ProtocolWireGuard)
	p.Outbounds[0].Amnezia = &a
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{"version: 3", "header-protection-key:", "content-padding-addition: 32-96", "random-trailers: true", "disable-cookies: true"} {
		if !strings.Contains(out, want) {
			t.Fatalf("rendered mihomo config is missing %q:\n%s", want, out)
		}
	}

	// Masquerade sugar has no mihomo fields: fail closed, never drop.
	if _, err := amneziaOptions(enginetest.AmneziaWG3().Amnezia); err == nil {
		t.Fatal("amneziaOptions must refuse masquerade sugar for mihomo")
	}
	// J1 is v1.5-only and incompatible with version 3: fail closed.
	b := a
	b.J1 = "<b 0x00>"
	if _, err := amneziaOptions(&b); err == nil {
		t.Fatal("amneziaOptions must refuse 3.x + J1 for mihomo")
	}
	// 2.0 sets keep rendering exactly as before, with no version key.
	opts, err = amneziaOptions(enginetest.AmneziaWG().Amnezia)
	if err != nil {
		t.Fatalf("amneziaOptions(2.0) = %v, want nil", err)
	}
	if opts["jc"] != 4 || opts["h3"] != int64(300000) {
		t.Fatalf("2.0 parameters must keep rendering: %v", opts)
	}
	if _, ok := opts["version"]; ok {
		t.Fatalf("a 2.0 set must not gain a version key: %v", opts)
	}
}

// TestRenderRealityKeyShare pins PASS3 deep S2: the plan's KeyShare
// knob renders as reality-opts.support-x25519mlkem768 on mihomo —
// hybrid as explicit true, classical as explicit false, unset as
// absent (mihomo's own default is not confirmed from the pinned
// docs, so the renderer must not invent one).
func TestRenderRealityKeyShare(t *testing.T) {
	render := func(ks string) string {
		p := testPlan()
		p.Outbounds[0] = engine.Outbound{
			ID: "srv-1", Name: "Reality 01", Protocol: engine.ProtocolVLESS,
			Server: "re.example.com", Port: 443, UUID: "11111111-2222-3333-4444-555555555555",
			TLS: engine.TLS{Enabled: true, ServerName: "www.example.com",
				Reality: true, RealityPublicKey: "Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw",
				KeyShare: ks},
		}
		p.Groups = []engine.Group{{Name: "sel", Type: engine.GroupSelect, Outbounds: []string{"srv-1"}}}
		p.Rules = []engine.Rule{{Type: engine.RuleMatchAll, Target: "srv-1"}}
		out, err := Render(p, testRuntime(t))
		if err != nil {
			t.Fatal(err)
		}
		return out
	}
	if out := render("hybrid"); !strings.Contains(out, "support-x25519mlkem768: true") {
		t.Fatalf("hybrid must render support-x25519mlkem768: true:\n%s", out)
	}
	if out := render("classical"); !strings.Contains(out, "support-x25519mlkem768: false") {
		t.Fatalf("classical must render support-x25519mlkem768: false explicitly:\n%s", out)
	}
	if out := render(""); strings.Contains(out, "support-x25519mlkem768") {
		t.Fatalf("an unset KeyShare must omit the key entirely:\n%s", out)
	}
}

// TestRenderRealityForcesAClientFingerprint is the sora regression test
// for the mihomo REALITY gap (legacy detail-fix af8d343): sing-box and
// Xray fall back to a uTLS fingerprint for REALITY, while mihomo rendered
// reality-opts without any client-fingerprint when the plan carried
// none — leaving REALITY to whatever default the engine chose.
func TestRenderRealityForcesAClientFingerprint(t *testing.T) {
	reality := func(fp string) *engine.Plan {
		p := testPlan()
		p.Outbounds[0] = engine.Outbound{
			ID: "srv-1", Name: "Reality 01", Protocol: engine.ProtocolVLESS,
			Server: "re.example.com", Port: 443, UUID: "11111111-2222-3333-4444-555555555555",
			TLS: engine.TLS{Enabled: true, ServerName: "www.example.com", Fingerprint: fp,
				Reality: true, RealityPublicKey: "Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw"},
		}
		p.Groups = []engine.Group{{Name: "sel", Type: engine.GroupSelect, Outbounds: []string{"srv-1"}}}
		p.Rules = []engine.Rule{{Type: engine.RuleMatchAll, Target: "srv-1"}}
		return p
	}
	fingerprintOf := func(t *testing.T, out string) (string, bool) {
		t.Helper()
		var cfg struct {
			Proxies []map[string]any `yaml:"proxies"`
		}
		if err := yaml.Unmarshal([]byte(out), &cfg); err != nil {
			t.Fatal(err)
		}
		for _, px := range cfg.Proxies {
			if px["name"] == "Reality_01" {
				fp, ok := px["client-fingerprint"].(string)
				return fp, ok
			}
		}
		t.Fatal("reality proxy is missing from the rendered config")
		return "", false
	}

	// Positive: no fingerprint in the plan still renders one for REALITY.
	out, err := Render(reality(""), testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if fp, ok := fingerprintOf(t, out); !ok || fp != engine.DefaultFingerprint {
		t.Errorf("REALITY without a fingerprint must default to %q, got %q (present=%v)", engine.DefaultFingerprint, fp, ok)
	}

	// Negative: an explicit fingerprint wins over the default.
	out, err = Render(reality("firefox"), testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if fp, ok := fingerprintOf(t, out); !ok || fp != "firefox" {
		t.Errorf("an explicit REALITY fingerprint must be kept, got %q (present=%v)", fp, ok)
	}

	// Negative: plain TLS without REALITY and without a fingerprint stays
	// fingerprint-free.
	p := reality("")
	p.Outbounds[0].TLS.Reality = false
	out, err = Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if fp, ok := fingerprintOf(t, out); ok {
		t.Errorf("plain TLS must not gain a client-fingerprint, got %q", fp)
	}
}
