package singbox

import (
	"context"
	"encoding/json"
	"net/netip"
	"os"
	"regexp"
	"runtime"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

var allProtocols = []engine.Protocol{
	engine.ProtocolVLESS, engine.ProtocolVMess, engine.ProtocolTrojan, engine.ProtocolShadowsocks,
	engine.ProtocolHysteria2, engine.ProtocolTUIC, engine.ProtocolAnyTLS, engine.ProtocolWireGuard,
	engine.ProtocolSOCKS5, engine.ProtocolHTTP, engine.ProtocolDirect,
}

var testRuntime = supervise.Runtime{LocalPort: 7890, ControlAddr: "127.0.0.1:9090", Secret: "secret", ProbeURL: engine.TestURLProduction}

func render(t *testing.T, p *engine.Plan) map[string]any {
	t.Helper()
	raw, err := Render(p, testRuntime)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	var out map[string]any
	if err := json.Unmarshal(raw, &out); err != nil {
		t.Fatalf("rendered config is not JSON: %v", err)
	}
	return out
}

func TestRenderPlacesWireGuardInEndpoints(t *testing.T) {
	cfg := render(t, enginetest.Plan(engine.ProtocolWireGuard, engine.ProtocolVLESS))
	endpoints, _ := cfg["endpoints"].([]any)
	if len(endpoints) != 1 || endpoints[0].(map[string]any)["type"] != "wireguard" {
		t.Fatalf("wireguard must be an endpoint since sing-box 1.13, got %v", cfg["endpoints"])
	}
	for _, o := range cfg["outbounds"].([]any) {
		if o.(map[string]any)["type"] == "wireguard" {
			t.Fatal("wireguard must not be rendered as an outbound")
		}
	}
}

func TestRenderTurnsGeoRulesIntoRuleSets(t *testing.T) {
	cfg := render(t, enginetest.Plan(engine.ProtocolVLESS))
	route := cfg["route"].(map[string]any)
	sets, _ := route["rule_set"].([]any)
	if len(sets) != 1 || !strings.Contains(sets[0].(map[string]any)["url"].(string), "geosite-category-ads-all.srs") {
		t.Fatalf("geosite must become a remote rule set, got %v", route["rule_set"])
	}
	if route["final"] != "Proxy" {
		t.Errorf("final = %v, want the group of the match-all rule", route["final"])
	}
	raw, _ := json.Marshal(route["rules"])
	if !strings.Contains(string(raw), `"ip_is_private":true`) {
		t.Errorf("geoip:private must use ip_is_private, rules: %s", raw)
	}
}

func TestRenderFragmentSkipsQUIC(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan, engine.ProtocolHysteria2)
	p.Options.Fragment.Enabled = true
	raw, err := Render(p, testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Count(string(raw), `"fragment":true`) != 1 {
		t.Fatalf("fragment must be set on the TCP outbound only: %s", raw)
	}
}

func TestRenderRefusesWhatSingBoxCannotCarry(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Transport = engine.Transport{Type: "not-a-transport"}
	if _, err := Render(p, testRuntime); err == nil {
		t.Fatal("unknown transports must be refused")
	}
	p = enginetest.Plan(engine.ProtocolVLESS)
	p.Groups[0].Type = engine.GroupFallback
	if _, err := Render(p, testRuntime); err == nil {
		t.Fatal("fallback groups must be refused")
	}
}

func tunInbound(t *testing.T, cfg map[string]any) map[string]any {
	t.Helper()
	for _, in := range cfg["inbounds"].([]any) {
		if in.(map[string]any)["type"] == "tun" {
			return in.(map[string]any)
		}
	}
	t.Fatal("no tun inbound rendered")
	return nil
}

// TestTunDropsDeprecatedStack: sing-box 1.15 deprecated `stack` (removed in
// 1.17); the migration is to drop it and use sing-tun's own fast TCP/IP
// stack. Even an explicit plan stack must not reach the config of a 1.15+
// build. Older builds (the 1.14-based lx. fork) still need the option: see
// TestTunStackFollowsEngineVersion.
func TestTunDropsDeprecatedStack(t *testing.T) {
	ver, err := engine.ParseVersion("1.15.0")
	if err != nil {
		t.Fatal(err)
	}
	for _, stack := range []string{"", "mixed", "system", "gvisor"} {
		p := enginetest.Plan(engine.ProtocolVLESS)
		p.Tun = engine.Tun{Enabled: true, Stack: stack}
		raw, err := renderVersioned(p, testRuntime, ver)
		if err != nil {
			t.Fatalf("renderVersioned: %v", err)
		}
		var cfg map[string]any
		if err := json.Unmarshal(raw, &cfg); err != nil {
			t.Fatalf("rendered config is not JSON: %v", err)
		}
		inbound := tunInbound(t, cfg)
		if _, ok := inbound["stack"]; ok {
			t.Fatalf("stack %q: deprecated `stack` must not be rendered on 1.15+, got %v", stack, inbound["stack"])
		}
	}
}

// TestTunMTUDefaultsSane: the jumbo 9000 default lets apps negotiate MSS
// 8960, fragmenting or black-holing proxied paths. Default is 1500; an
// explicit plan MTU still wins; garbage falls back to the default.
func TestTunMTUDefaultsSane(t *testing.T) {
	for mtu, want := range map[int]int{0: 1500, -1: 1500, 1400: 1400, 1280: 1280} {
		p := enginetest.Plan(engine.ProtocolVLESS)
		p.Tun = engine.Tun{Enabled: true, MTU: mtu}
		inbound := tunInbound(t, render(t, p))
		if got, ok := inbound["mtu"].(float64); !ok || int(got) != want {
			t.Fatalf("plan MTU %d: rendered mtu = %v, want %d", mtu, inbound["mtu"], want)
		}
	}
}

func TestTunUsesSessionAddressesAndLinuxPolicyRouting(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Tun = engine.Tun{Enabled: true, IPv4: netip.MustParsePrefix("172.20.0.1/30"), IPv6: netip.MustParsePrefix("fdfe:dcba:9877::1/126")}
	cfg := render(t, p)
	var inbound map[string]any
	for _, in := range cfg["inbounds"].([]any) {
		if in.(map[string]any)["type"] == "tun" {
			inbound = in.(map[string]any)
		}
	}
	addresses := inbound["address"].([]any)
	if addresses[0] != p.Tun.IPv4.String() || addresses[1] != p.Tun.IPv6.String() {
		t.Fatalf("TUN addresses = %v", addresses)
	}
	if runtime.GOOS == "linux" {
		if inbound["auto_route"] != false || cfg["route"].(map[string]any)["auto_detect_interface"] != false {
			t.Fatal("Linux routing must belong to the core")
		}
	}
}

func TestTunRendersRouteAddressSets(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Tun = engine.Tun{Enabled: true, RouteAddressSets: []string{"10.0.0.0/8", "fd00::/8"}}
	cfg := render(t, p)
	var inbound map[string]any
	for _, in := range cfg["inbounds"].([]any) {
		if in.(map[string]any)["type"] == "tun" {
			inbound = in.(map[string]any)
		}
	}
	addrs, _ := inbound["route_address"].([]any)
	if len(addrs) != 2 || addrs[0] != "10.0.0.0/8" || addrs[1] != "fd00::/8" {
		t.Fatalf("route_address = %v, want the plan's RouteAddressSets", inbound["route_address"])
	}
	// Empty sets must stay unset so auto_route keeps installing the
	// default route.
	p.Tun.RouteAddressSets = nil
	cfg = render(t, p)
	for _, in := range cfg["inbounds"].([]any) {
		if in.(map[string]any)["type"] == "tun" {
			inbound = in.(map[string]any)
		}
	}
	if _, ok := inbound["route_address"]; ok {
		t.Fatalf("route_address must be omitted when unset, got %v", inbound["route_address"])
	}
}

// TestEngineAcceptsRenderedPlans checks rendered grammar with "sing-box check"
// whenever a binary is available.
func TestEngineAcceptsRenderedPlans(t *testing.T) {
	path := os.Getenv(Prober.EnvVar)
	if path == "" {
		t.Skipf("set %s to run sing-box against the rendered plans", Prober.EnvVar)
	}
	ctx := context.Background()
	binary, err := Prober.Probe(ctx, path)
	if err != nil {
		t.Fatal(err)
	}
	fake := enginetest.Plan(engine.ProtocolVLESS)
	fake.DNS.Mode = string(engine.DNSFakeIP)
	fragment := enginetest.Plan(allProtocols...)
	fragment.Options.Fragment.Enabled = true
	plans := map[string]*engine.Plan{"all protocols": enginetest.Plan(allProtocols...), "fake-ip": fake, "fragment": fragment}
	caps := engine.BuildCapabilities(binary.Kind, binary.Version, binary.BuildTags)
	if caps.Supports(engine.FeatureXHTTP) {
		for _, mode := range []string{"auto", "packet-up", "stream-up", "stream-one"} {
			p := enginetest.Plan(engine.ProtocolVLESS)
			p.Outbounds[0].Flow = ""
			p.Outbounds[0].Transport = engine.Transport{Type: "xhttp", Path: "/x?provider=1", Host: "cdn.example.com", Mode: mode, Headers: map[string]string{"User-Agent": "Sora-interop"}}
			plans["xhttp-"+mode] = p
		}
		p := enginetest.Plan(engine.ProtocolVLESS)
		p.Outbounds[0].Encryption = "mlkem768x25519plus.native.0rtt.Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw"
		plans["vless-encryption"] = p
	}
	if caps.Supports(engine.FeatureAmneziaWG) {
		p := enginetest.Plan(engine.ProtocolWireGuard)
		p.Outbounds[0].Amnezia = enginetest.AmneziaWG().Amnezia
		plans["amneziawg"] = p
	}
	if caps.Supports(engine.FeatureAmneziaWG3) {
		// S5 risk flag: the lx fork's public description says
		// "AmneziaWG 2.0", while BuildCapabilities claims its with_awg
		// stack applies the 3.1 parameters. sing-box rejects unknown
		// config keys at check time, so a build that silently cut the
		// 3.1 fields (header_protection_key, random_trailers, ranged
		// timings) fails here instead of passing a hollow render.
		p := enginetest.Plan(engine.ProtocolWireGuard)
		p.Outbounds[0].Amnezia = enginetest.AmneziaWG3().Amnezia
		plans["amneziawg3"] = p
	}
	for name, p := range plans {
		t.Run(name, func(t *testing.T) {
			raw, err := Render(p, testRuntime)
			if err != nil {
				t.Fatal(err)
			}
			home := t.TempDir()
			rt := testRuntime
			rt.HomeDir = home
			if err := supervise.Check(ctx, supervise.Spec{Name: "sing-box", Path: binary.Path, Args: driver{}.CheckArgs(rt), Dir: home, Config: raw}); err != nil {
				t.Fatal(err)
			}
		})
	}
}

func trojanOutbound(t *testing.T, cfg map[string]any) map[string]any {
	t.Helper()
	for _, ob := range cfg["outbounds"].([]any) {
		m := ob.(map[string]any)
		if m["type"] == "trojan" {
			return m
		}
	}
	t.Fatal("no trojan outbound rendered")
	return nil
}

// TestRuleSetDownloadDetourUsesProxyWhenFinalIsDirect: with a direct
// default route, rule-set downloads must still go through a proxy when
// the plan has one, or geo data never downloads where the direct path
// to GitHub raw is filtered.
func TestRuleSetDownloadDetourUsesProxyWhenFinalIsDirect(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Rules = []engine.Rule{
		{Type: engine.RuleGeoSite, Value: "category-ads-all", Target: "reject"},
		{Type: engine.RuleMatchAll, Target: "direct"},
	}
	cfg := render(t, p)
	route := cfg["route"].(map[string]any)
	if route["final"] != "direct" {
		t.Fatalf("final = %v, want direct", route["final"])
	}
	sets, _ := route["rule_set"].([]any)
	if len(sets) != 1 {
		t.Fatalf("want one rule set, got %v", route["rule_set"])
	}
	rs := sets[0].(map[string]any)
	if detour, _ := rs["download_detour"].(string); detour != "Test vless" {
		t.Fatalf("download_detour = %q, want the proxy outbound tag", detour)
	}
}

// TestRuleSetDownloadDetourOmittedWithoutProxies: a plan with no proxies
// must not render a detour at all (direct is the engine default).
func TestRuleSetDownloadDetourOmittedWithoutProxies(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolDirect)
	p.Rules = []engine.Rule{
		{Type: engine.RuleGeoSite, Value: "category-ads-all", Target: "reject"},
		{Type: engine.RuleMatchAll, Target: "direct"},
	}
	route := render(t, p)["route"].(map[string]any)
	sets, _ := route["rule_set"].([]any)
	if len(sets) != 1 {
		t.Fatalf("want one rule set, got %v", route["rule_set"])
	}
	if _, ok := sets[0].(map[string]any)["download_detour"]; ok {
		t.Fatalf("download_detour must be omitted with no proxies, got %v", sets[0])
	}
}

// TestRuleSetDownloadDetourFollowsProxyFinal locks the common case: the
// default route through a proxy carries the rule-set downloads.
func TestRuleSetDownloadDetourFollowsProxyFinal(t *testing.T) {
	route := render(t, enginetest.Plan(engine.ProtocolVLESS))["route"].(map[string]any)
	sets, _ := route["rule_set"].([]any)
	if len(sets) != 1 {
		t.Fatalf("want one rule set, got %v", route["rule_set"])
	}
	if detour, _ := sets[0].(map[string]any)["download_detour"].(string); detour != "Proxy" {
		t.Fatalf("download_detour = %q, want the final route tag", detour)
	}
}

// TestRenderDNSIPv6Strategy: the strategy must honor the plan's IPv6 flag.
// Rendering the engine default (prefer_ipv4) when the user enabled IPv6
// would deprioritize the family the flag just turned on.
func TestRenderDNSIPv6Strategy(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Options.IPv6 = true
	if s := render(t, p)["dns"].(map[string]any)["strategy"]; s != "prefer_ipv6" {
		t.Fatalf("strategy = %v with IPv6 enabled, want prefer_ipv6", s)
	}
	p.Options.IPv6 = false
	if s := render(t, p)["dns"].(map[string]any)["strategy"]; s != "ipv4_only" {
		t.Fatalf("strategy = %v with IPv6 disabled, want ipv4_only", s)
	}
}

// TestRenderNeverEmitsMultiplex: plans have no mux knob, so the renderer
// must never emit one — including for QUIC outbounds, where multiplexing
// is invalid and would fail silently or loudly downstream.
func TestRenderNeverEmitsMultiplex(t *testing.T) {
	raw, err := Render(enginetest.Plan(allProtocols...), testRuntime)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), "multiplex") {
		t.Fatal("rendered config must never contain multiplex")
	}
}

func TestRenderECHOutboundTLS(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].TLS.ECH = engine.ECHConfig{
		Enabled: true,
		Config:  []string{"AE7+DQA8NwAgACBwaW5uZWQtZWNoLXRlc3QtY29uZmln"},
	}
	tls, ok := trojanOutbound(t, render(t, p))["tls"].(map[string]any)
	if !ok {
		t.Fatal("trojan outbound must carry a tls block")
	}
	ech, ok := tls["ech"].(map[string]any)
	if !ok {
		t.Fatal("tls block must carry ech when ECH is enabled")
	}
	if ech["enabled"] != true {
		t.Fatalf("ech.enabled = %v, want true", ech["enabled"])
	}
	got, _ := ech["config"].([]any)
	if len(got) != 1 || got[0] != "AE7+DQA8NwAgACBwaW5uZWQtZWNoLXRlc3QtY29uZmln" {
		t.Fatalf("ech.config = %v, want the pinned ECHConfigList", ech["config"])
	}
}

func TestRenderOmitsECHByDefault(t *testing.T) {
	tls, ok := trojanOutbound(t, render(t, enginetest.Plan(engine.ProtocolTrojan)))["tls"].(map[string]any)
	if !ok {
		t.Fatal("trojan outbound must carry a tls block")
	}
	if _, has := tls["ech"]; has {
		t.Fatal("ech must not be rendered unless explicitly enabled")
	}
}

// TestRenderDNSH3UsesAddressForm locks the DoH3 rendering: sing-box has no
// legacy "type" spelling for HTTP/3, so an h3 server must be emitted in the
// address form with the h3:// prefix (its DoH3 transport selector).
func TestRenderDNSH3UsesAddressForm(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS.Servers = []engine.DNSServer{{Tag: "doh3", Transport: engine.DNSH3, Address: "1.1.1.1"}}
	out := render(t, p)
	dns, ok := out["dns"].(map[string]any)
	if !ok {
		t.Fatal("rendered config has no dns section")
	}
	servers, _ := dns["servers"].([]any)
	for _, s := range servers {
		m, _ := s.(map[string]any)
		if m["tag"] != "doh3" {
			continue
		}
		if m["address"] != "h3://1.1.1.1:443/dns-query" {
			t.Fatalf("h3 server must use the address form, got %v", m)
		}
		if _, hasType := m["type"]; hasType {
			t.Fatalf("h3 server must not carry a legacy type: %v", m)
		}
		return
	}
	t.Fatalf("h3 server missing from rendered dns: %v", servers)
}

func findOutbound(cfg map[string]any, typ string) map[string]any {
	for _, o := range cfg["outbounds"].([]any) {
		m := o.(map[string]any)
		if m["type"] == typ {
			return m
		}
	}
	return nil
}

func TestRenderHysteria2BandwidthAndHopping(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolHysteria2)
	o := &p.Outbounds[0]
	o.UpMbps, o.DownMbps = 20, 100
	o.HopPorts = "20000-30000,40000"
	o.HopInterval = 30
	cfg := render(t, p)
	hy2 := findOutbound(cfg, "hysteria2")
	if hy2 == nil {
		t.Fatal("no hysteria2 outbound rendered")
	}
	// up/down switch the engine from BBR to Brutal congestion control.
	if hy2["up_mbps"] != float64(20) || hy2["down_mbps"] != float64(100) {
		t.Fatalf("bandwidth caps not rendered: %v", hy2)
	}
	ports, ok := hy2["server_ports"].([]any)
	if !ok || len(ports) != 2 || ports[0] != "20000-30000" || ports[1] != "40000" {
		t.Fatalf("hop ports not rendered: %v", hy2["server_ports"])
	}
	if hy2["hop_interval"] != "30s" {
		t.Fatalf("hop interval not rendered: %v", hy2["hop_interval"])
	}
	// Salamander obfuscation still renders alongside the tuning fields.
	if obfs, ok := hy2["obfs"].(map[string]any); !ok || obfs["type"] != "salamander" {
		t.Fatalf("obfs not rendered: %v", hy2["obfs"])
	}
}

// TestRenderHysteria2OmitsZeroBandwidth: unset caps mean BBR, so the
// renderer must not emit zero up_mbps/down_mbps and accidentally switch
// the engine to Brutal congestion control.
func TestRenderHysteria2OmitsZeroBandwidth(t *testing.T) {
	hy2 := findOutbound(render(t, enginetest.Plan(engine.ProtocolHysteria2)), "hysteria2")
	if hy2 == nil {
		t.Fatal("no hysteria2 outbound rendered")
	}
	if _, ok := hy2["up_mbps"]; ok {
		t.Fatalf("zero up_mbps must be omitted: %v", hy2)
	}
	if _, ok := hy2["down_mbps"]; ok {
		t.Fatalf("zero down_mbps must be omitted: %v", hy2)
	}
}

func TestRenderNaiveOutbound(t *testing.T) {
	p := enginetest.Plan(protocolNaive)
	o := &p.Outbounds[0]
	o.UserID, o.Password = "naive-user", "naive-test-password"
	// Fingerprint and ALPN are valid plan knobs for other protocols;
	// Cronet rejects them on naive, so they must not reach the config.
	o.TLS = engine.TLS{Enabled: true, ServerName: "naive.example.com", Fingerprint: "chrome", ALPN: []string{"h2"}}
	cfg := render(t, p)
	nv := findOutbound(cfg, "naive")
	if nv == nil {
		t.Fatal("no naive outbound rendered")
	}
	if nv["username"] != "naive-user" || nv["password"] != "naive-test-password" {
		t.Fatalf("credentials not rendered: %v", nv)
	}
	tls, ok := nv["tls"].(map[string]any)
	if !ok || tls["enabled"] != true || tls["server_name"] != "naive.example.com" {
		t.Fatalf("naive must carry a minimal tls block: %v", nv["tls"])
	}
	for _, key := range []string{"utls", "alpn", "insecure", "reality", "fragment"} {
		if _, ok := tls[key]; ok {
			t.Fatalf("naive must not render tls.%s (Cronet owns the handshake): %v", key, tls)
		}
	}
	uot, ok := nv["udp_over_tcp"].(map[string]any)
	if !ok || uot["enabled"] != true || uot["version"] != float64(2) {
		t.Fatalf("naive must enable UDP-over-TCP v2: %v", nv["udp_over_tcp"])
	}
	if _, ok := nv["transport"]; ok {
		t.Fatalf("naive carries no transport: %v", nv)
	}
}

// TestRenderNaiveFallsBackToServerName: a naive+https link without an
// explicit sni still needs SNI for Cronet's verification.
func TestRenderNaiveFallsBackToServerName(t *testing.T) {
	p := enginetest.Plan(protocolNaive)
	o := &p.Outbounds[0]
	o.UserID, o.Password = "naive-user", "naive-test-password"
	tls := findOutbound(render(t, p), "naive")["tls"].(map[string]any)
	if tls["server_name"] != "edge.example.com" {
		t.Fatalf("server_name = %v, want the outbound server", tls["server_name"])
	}
}

// TestRenderNaiveRefusesInsecureTLS: Cronet cannot skip verification, and
// sing-box refuses the option, so the plan must be rejected at render
// time instead of producing a config the engine cannot start.
func TestRenderNaiveRefusesInsecureTLS(t *testing.T) {
	p := enginetest.Plan(protocolNaive)
	o := &p.Outbounds[0]
	o.UserID, o.Password = "naive-user", "naive-test-password"
	o.TLS = engine.TLS{Enabled: true, Insecure: true}
	if _, err := Render(p, testRuntime); err == nil {
		t.Fatal("naive with insecure TLS must be refused")
	}
}

func TestRenderTUICTuning(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTUIC)
	p.Outbounds[0].CongestionControl = "cubic"
	p.Outbounds[0].UDPRelayMode = "quic"
	cfg := render(t, p)
	tuic := findOutbound(cfg, "tuic")
	if tuic == nil {
		t.Fatal("no tuic outbound rendered")
	}
	if tuic["congestion_control"] != "cubic" || tuic["udp_relay_mode"] != "quic" {
		t.Fatalf("tuic tuning not rendered: %v", tuic)
	}
	// Default stays BBR, as before.
	cfg = render(t, enginetest.Plan(engine.ProtocolTUIC))
	if findOutbound(cfg, "tuic")["congestion_control"] != "bbr" {
		t.Fatal("tuic default congestion control must stay bbr")
	}
}

// dnsRules extracts the rendered DNS rules in order.
func dnsRules(t *testing.T, p *engine.Plan) []map[string]any {
	t.Helper()
	cfg := render(t, p)
	dns, ok := cfg["dns"].(map[string]any)
	if !ok {
		t.Fatal("rendered config has no dns block")
	}
	raw, ok := dns["rules"].([]any)
	if !ok {
		t.Fatal("dns block has no rules")
	}
	out := make([]map[string]any, 0, len(raw))
	for _, r := range raw {
		m, ok := r.(map[string]any)
		if !ok {
			t.Fatal("dns rule is not an object")
		}
		out = append(out, m)
	}
	return out
}

// TestFakeIPExcludesLANAndLocalDomains locks the sing-box equivalent of
// mihomo's fake-ip-filter: default filter suffixes resolve through the real
// resolver before the fakeip catch-all, so LAN names never get fake answers.
func TestFakeIPExcludesLANAndLocalDomains(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS.Mode = string(engine.DNSFakeIP)
	rules := dnsRules(t, p)
	fakeIdx := -1
	for i, r := range rules {
		if r["server"] == "fakeip" {
			fakeIdx = i
		}
	}
	if fakeIdx < 0 {
		t.Fatal("no fakeip catch-all rule rendered")
	}
	seen := map[string]bool{}
	for _, r := range rules[:fakeIdx] {
		suffixes, ok := r["domain_suffix"].([]any)
		if !ok || r["server"] == "fakeip" {
			continue
		}
		for _, s := range suffixes {
			seen[s.(string)] = true
		}
	}
	for _, want := range []string{"lan", "local", "home.arpa", "invalid", "localhost", "msftconnecttest.com", "msftncsi.com",
		"time.windows.com", "time.google.com", "time.cloudflare.com", "time.apple.com", "pool.ntp.org",
		"stun.l.google.com", "stun1.l.google.com", "stun.stunprotocol.org"} {
		if !seen[want] {
			t.Errorf("default fake-ip exclusion for %q missing before the fakeip rule", want)
		}
	}
	// Interior wildcards (ntp.*.com, +.stun.*.*) must be expanded to
	// domain_regex, never silently dropped (S7).
	regexes := map[string]bool{}
	for _, r := range rules[:fakeIdx] {
		if res, ok := r["domain_regex"].([]any); ok && r["server"] != "fakeip" {
			for _, re := range res {
				regexes[re.(string)] = true
			}
		}
	}
	for _, want := range []string{`(?i)^ntp\..+\.com$`, `(?i)^(.+\.)?stun\..+\..+$`} {
		if !regexes[want] {
			t.Errorf("interior wildcard not expanded to domain_regex: want %q, got %v", want, regexes)
		}
	}
	for _, r := range rules {
		if suffixes, ok := r["domain_suffix"].([]any); ok {
			for _, s := range suffixes {
				if strings.Contains(s.(string), "*") {
					t.Errorf("unrenderable wildcard reached sing-box: %q", s)
				}
			}
		}
	}
}

// TestFakeIPHonorsPlanFilter ensures a plan filter replaces the defaults in
// the sing-box renderer instead of being silently dropped.
func TestFakeIPHonorsPlanFilter(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS.Mode = string(engine.DNSFakeIP)
	p.DNS.FakeIPFilter = []string{"*.corp.example"}
	rules := dnsRules(t, p)
	found, lan := false, false
	for _, r := range rules {
		if r["server"] == "fakeip" {
			continue
		}
		suffixes, ok := r["domain_suffix"].([]any)
		if !ok {
			continue
		}
		for _, s := range suffixes {
			switch s.(string) {
			case "corp.example":
				found = true
			case "lan":
				lan = true
			}
		}
	}
	if !found {
		t.Error("plan fake-ip filter *.corp.example not rendered")
	}
	if lan {
		t.Error("default filter leaked in despite a plan filter")
	}
}

// TestFakeIPFilterPatternConversion pins the mihomo-syntax to sing-box
// conversion: plain suffixes collapse, interior wildcards become anchored
// regexes, and nothing is ever silently dropped (S7).
func TestFakeIPFilterPatternConversion(t *testing.T) {
	for _, tc := range []struct {
		pattern    string
		wantSuffix string
		wantRegex  string
	}{
		{"*.lan", "lan", ""},
		{"+.msftconnecttest.com", "msftconnecttest.com", ""},
		{".example.com", "example.com", ""},
		{"localhost", "localhost", ""},
		{"time.windows.com", "time.windows.com", ""},
		{"ntp.*.com", "", `(?i)^ntp\..+\.com$`},
		{"+.stun.*.*", "", `(?i)^(.+\.)?stun\..+\..+$`},
		{"*.stun.*.*", "", `(?i)^(.+\.)stun\..+\..+$`},
		{"", "", ""},
		{"   ", "", ""},
	} {
		suffix, regex := fakeIPFilterPattern(tc.pattern)
		if suffix != tc.wantSuffix || regex != tc.wantRegex {
			t.Errorf("fakeIPFilterPattern(%q) = (%q, %q), want (%q, %q)",
				tc.pattern, suffix, regex, tc.wantSuffix, tc.wantRegex)
		}
		if regex != "" {
			if _, err := regexp.Compile(regex); err != nil {
				t.Errorf("fakeIPFilterPattern(%q) produced an invalid regex %q: %v", tc.pattern, regex, err)
			}
		}
	}
}

// TestFakeIPWildcardMatchesHostsAndNotStrangers is the behavioral half of
// the S7 expansion: the emitted matchers must catch real NTP/STUN hosts
// and must not catch an unrelated domain.
func TestFakeIPWildcardMatchesHostsAndNotStrangers(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS.Mode = string(engine.DNSFakeIP)
	p.DNS.FakeIPFilter = []string{"ntp.*.com", "+.stun.*.*", "time.windows.com"}
	rules := dnsRules(t, p)
	var regexes []*regexp.Regexp
	suffixes := map[string]bool{}
	for _, r := range rules {
		if r["server"] == "fakeip" {
			continue
		}
		if ss, ok := r["domain_suffix"].([]any); ok {
			for _, s := range ss {
				suffixes[s.(string)] = true
			}
		}
		if rs, ok := r["domain_regex"].([]any); ok {
			for _, re := range rs {
				compiled, err := regexp.Compile(re.(string))
				if err != nil {
					t.Fatalf("invalid domain_regex %q: %v", re, err)
				}
				regexes = append(regexes, compiled)
			}
		}
	}
	if len(regexes) != 2 {
		t.Fatalf("interior wildcards dropped: got %d domain_regex rules, want 2", len(regexes))
	}
	if !suffixes["time.windows.com"] {
		t.Error("time.windows.com not rendered as a suffix rule")
	}
	match := func(host string) bool {
		for _, re := range regexes {
			if re.MatchString(host) {
				return true
			}
		}
		return false
	}
	for _, host := range []string{"ntp.vendor.com", "a.stun.example.com", "stun.l.google.com"} {
		if !match(host) {
			t.Errorf("filter must match %q", host)
		}
	}
	// NOTE: `*` compiles to `.+` (documented superset of mihomo's label
	// wildcard), so ntp.evil.com.attacker.com still matches the ntp
	// pattern — over-matching a filter entry is harmless, it only
	// resolves for real.
	for _, host := range []string{"example.com", "evilntp.com", "ntp.evil.org", "notstun.example.com"} {
		if match(host) {
			t.Errorf("filter must not match unrelated host %q", host)
		}
	}
	// stun1.l.google.com is NOT matched by +.stun.*.* — the wildcard's
	// first label is exactly "stun", not "stun1". The numbered Google
	// hosts are covered by explicit entries in DefaultFakeIPFilter
	// instead; this pins that contract.
	if match("stun1.l.google.com") {
		t.Error("+.stun.*.* must not match the stun1 label")
	}
}

// TestDNSSkipVerifyRendersInsecureTLS covers the corporate-MITM escape hatch
// on the sing-box side: encrypted upstreams with SkipVerify carry
// tls.insecure, plain resolvers are untouched.
func TestDNSSkipVerifyRendersInsecureTLS(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS.Servers = append(p.DNS.Servers, engine.DNSServer{
		Tag: "dot-skip", Transport: engine.DNSTLS, Address: "9.9.9.9", SkipVerify: true,
	})
	cfg := render(t, p)
	dns := cfg["dns"].(map[string]any)
	servers := dns["servers"].([]any)
	byTag := map[string]map[string]any{}
	for _, s := range servers {
		m := s.(map[string]any)
		byTag[m["tag"].(string)] = m
	}
	skip, ok := byTag["dot-skip"]
	if !ok {
		t.Fatal("dot-skip server missing")
	}
	tls, ok := skip["tls"].(map[string]any)
	if !ok || tls["insecure"] != true {
		t.Fatalf("dot-skip must carry tls.insecure, got %v", skip["tls"])
	}
	if _, ok := byTag["dot"]["tls"]; ok {
		t.Error("plain dot server must not carry tls options")
	}
}

// TestTunStackFollowsEngineVersion locks the 1.15 TUN rewrite handling:
// sing-box 1.15 deprecated the stack option (removed in 1.17), so the
// renderer must not emit it there; older builds, including the 1.14-based
// lx. fork, still honor an explicit stack and keep the "mixed" default.
// A silent stack change would reroute packets through the wrong TCP/IP
// stack, so both directions are asserted.
func TestTunStackFollowsEngineVersion(t *testing.T) {
	for _, tc := range []struct {
		name    string
		version string // "" means Render's legacy contract: unknown build
		stack   string
		want    string // "" means the stack key must be absent
	}{
		{"unknown build keeps legacy stack", "", "", "mixed"},
		{"fork honors explicit stack", "1.14.3-lx.14", "gvisor", "gvisor"},
		{"fork keeps mixed default", "1.14.3-lx.14", "", "mixed"},
		{"1.15 drops explicit stack", "1.15.0", "gvisor", ""},
		{"1.15 drops default stack", "1.15.0", "", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			p := enginetest.Plan(engine.ProtocolVLESS)
			p.Tun = engine.Tun{Enabled: true, Stack: tc.stack, IPv4: netip.MustParsePrefix("172.20.0.1/30")}
			ver := engine.Version{}
			if tc.version != "" {
				var err error
				if ver, err = engine.ParseVersion(tc.version); err != nil {
					t.Fatalf("ParseVersion(%q): %v", tc.version, err)
				}
			}
			raw, err := renderVersioned(p, testRuntime, ver)
			if err != nil {
				t.Fatalf("renderVersioned: %v", err)
			}
			var cfg map[string]any
			if err := json.Unmarshal(raw, &cfg); err != nil {
				t.Fatalf("rendered config is not JSON: %v", err)
			}
			var tun map[string]any
			for _, in := range cfg["inbounds"].([]any) {
				if in.(map[string]any)["type"] == "tun" {
					tun = in.(map[string]any)
				}
			}
			if tun == nil {
				t.Fatal("no tun inbound rendered")
			}
			got, ok := tun["stack"]
			if tc.want == "" {
				if ok {
					t.Fatalf("stack = %v on sing-box %q, want the key absent (deprecated)", got, tc.version)
				}
				return
			}
			if !ok || got != tc.want {
				t.Fatalf("stack = %v on sing-box %q, want %q", got, tc.version, tc.want)
			}
		})
	}
}

// TestRenderECHQueryServerName locks the 1.13+ ECH field: a configured
// override must reach the engine, an empty one must stay unset.
func TestRenderECHQueryServerName(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolTrojan)
	p.Outbounds[0].TLS.ECH = engine.ECHConfig{Enabled: true, QueryServerName: "ech-query.example.com"}
	ech, ok := trojanOutbound(t, render(t, p))["tls"].(map[string]any)["ech"].(map[string]any)
	if !ok {
		t.Fatal("tls block must carry ech when ECH is enabled")
	}
	if ech["query_server_name"] != "ech-query.example.com" {
		t.Fatalf("ech.query_server_name = %v, want the configured override", ech["query_server_name"])
	}

	p.Outbounds[0].TLS.ECH = engine.ECHConfig{Enabled: true}
	ech, ok = trojanOutbound(t, render(t, p))["tls"].(map[string]any)["ech"].(map[string]any)
	if !ok {
		t.Fatal("tls block must carry ech when ECH is enabled")
	}
	if _, has := ech["query_server_name"]; has {
		t.Fatal("ech.query_server_name must stay unset when empty")
	}
}

// fakeIPServer extracts the rendered fakeip DNS server.
func fakeIPServer(t *testing.T, p *engine.Plan) map[string]any {
	t.Helper()
	cfg := render(t, p)
	dns, ok := cfg["dns"].(map[string]any)
	if !ok {
		t.Fatal("rendered config has no dns block")
	}
	for _, s := range dns["servers"].([]any) {
		if m, ok := s.(map[string]any); ok && m["tag"] == "fakeip" {
			return m
		}
	}
	t.Fatal("no fakeip server rendered")
	return nil
}

// TestFakeIPRendersIPv6RangeWhenIPv6IsOn locks the mandatory inet6_range:
// with IPv6 enabled the fakeip server must answer AAAA from its own pool,
// otherwise IPv6-capable apps stall on resolution.
func TestFakeIPRendersIPv6RangeWhenIPv6IsOn(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS.Mode = string(engine.DNSFakeIP)
	p.Options.IPv6 = true
	srv := fakeIPServer(t, p)
	if srv["inet6_range"] != "fc00::/18" {
		t.Fatalf("default inet6_range = %v, want fc00::/18", srv["inet6_range"])
	}
	if srv["inet4_range"] != "198.18.0.0/15" {
		t.Fatalf("inet4_range = %v, want 198.18.0.0/15", srv["inet4_range"])
	}
	if srv["inet4_range"] != engine.DefaultFakeIPRange {
		t.Fatalf("inet4_range = %v, want the shared engine default %q", srv["inet4_range"], engine.DefaultFakeIPRange)
	}
	p.DNS.FakeIPRange6 = "fd00:face::/48"
	if srv := fakeIPServer(t, p); srv["inet6_range"] != "fd00:face::/48" {
		t.Fatalf("custom inet6_range = %v, want fd00:face::/48", srv["inet6_range"])
	}
}

// TestFakeIPOmitsIPv6RangeWhenIPv6IsOff locks the negative: with IPv6
// disabled a fake IPv6 pool would hand out unusable addresses, so the
// server must stay v4-only and AAAA must not be steered at it either
// (S7) — it resolves for real instead of stalling on NODATA.
func TestFakeIPOmitsIPv6RangeWhenIPv6IsOff(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS.Mode = string(engine.DNSFakeIP)
	p.Options.IPv6 = false
	srv := fakeIPServer(t, p)
	if _, ok := srv["inet6_range"]; ok {
		t.Fatalf("inet6_range must be omitted with IPv6 off, got %v", srv["inet6_range"])
	}
	for _, r := range dnsRules(t, p) {
		if r["server"] != "fakeip" {
			continue
		}
		types, ok := r["query_type"].([]any)
		if !ok {
			t.Fatal("fakeip rule lost its query_type")
		}
		for _, qt := range types {
			if qt.(string) == "AAAA" {
				t.Fatal("AAAA must not reach the fakeip server with IPv6 off")
			}
		}
	}
}

// TestFakeIPSteersAAAAWhenIPv6IsOn is the positive half of the S7 AAAA
// gate: with IPv6 enabled both query types reach the fakeip server,
// which then answers AAAA from its own pool.
func TestFakeIPSteersAAAAWhenIPv6IsOn(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.DNS.Mode = string(engine.DNSFakeIP)
	p.Options.IPv6 = true
	found := false
	for _, r := range dnsRules(t, p) {
		if r["server"] != "fakeip" {
			continue
		}
		found = true
		types, ok := r["query_type"].([]any)
		if !ok {
			t.Fatal("fakeip rule lost its query_type")
		}
		seen := map[string]bool{}
		for _, qt := range types {
			seen[qt.(string)] = true
		}
		if !seen["A"] || !seen["AAAA"] {
			t.Fatalf("fakeip query_type = %v, want [A AAAA] with IPv6 on", types)
		}
	}
	if !found {
		t.Fatal("no fakeip catch-all rule rendered")
	}
}

func TestRenderEmitsAmneziaWG31(t *testing.T) {
	// T012: the with_awg fork implements the 3.1 stack (snake_case keys),
	// so 3.1 parameters must reach the endpoint verbatim. A plan routed
	// here was selected for FeatureAmneziaWG3; dropping its fields would
	// be the silent no-op the fail-closed gates exist to prevent.
	p := enginetest.Plan(engine.ProtocolWireGuard)
	p.Outbounds[0].Amnezia = enginetest.AmneziaWG3().Amnezia
	cfg := render(t, p)
	raw, _ := json.Marshal(cfg["endpoints"])
	for _, want := range []string{`"header_protection_key"`, `"content_padding_addition"`, `"rekey_after_time"`, `"random_trailers":true`, `"disable_cookies":true`} {
		if !strings.Contains(string(raw), want) {
			t.Fatalf("3.1 parameter %s missing from endpoint: %s", want, raw)
		}
	}
}

func TestRenderKeepsAmneziaWG20(t *testing.T) {
	// The 2.0 parameters must keep reaching the endpoint: the fail-closed
	// gates above must not break what the fork demonstrably supports.
	p := enginetest.Plan(engine.ProtocolWireGuard)
	p.Outbounds[0].Amnezia = enginetest.AmneziaWG().Amnezia
	cfg := render(t, p)
	raw, _ := json.Marshal(cfg["endpoints"])
	if !strings.Contains(string(raw), `"jc":4`) {
		t.Fatalf("2.0 obfuscation parameters must reach the endpoint: %s", raw)
	}
}
