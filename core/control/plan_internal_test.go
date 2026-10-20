package control

import (
	"context"
	"errors"
	"os"
	"testing"

	"google.golang.org/protobuf/proto"

	"github.com/levvs-one/sora-client/core/censor"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/parser"
	"github.com/levvs-one/sora-client/core/session"
)

// TestRealityAndTransportSurviveTheVault checks that REALITY keys, transport
// paths, and XHTTP mode survive import and credential resolution.
func TestRealityAndTransportSurviveTheVault(t *testing.T) {
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?type=xhttp&security=reality" +
		"&pbk=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw&sid=6ba85179e30d4fc2&sni=www.example.com&fp=chrome" +
		"&path=%2Fx&host=cdn.example.com&mode=stream-one&encryption=none&alpn=h2,http%2F1.1#Edge"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	document, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	values, err := parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}

	if !o.TLS.Reality || o.TLS.RealityPublicKey != "Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw" || o.TLS.RealityShortID != "6ba85179e30d4fc2" {
		t.Errorf("REALITY lost on the way to the engine: %+v", o.TLS)
	}
	if o.Transport.Path != "/x" || o.Transport.Host != "cdn.example.com" || o.Transport.Mode != "stream-one" {
		t.Errorf("transport lost on the way to the engine: %+v", o.Transport)
	}
	if len(o.TLS.ALPN) != 2 || o.Encryption != "none" {
		t.Errorf("alpn %v and encryption %q must survive", o.TLS.ALPN, o.Encryption)
	}
}

func TestRuleDestinationsFollowTheXrayVocabulary(t *testing.T) {
	for destination, want := range map[string]engine.Rule{
		"domain:example.com": {Type: engine.RuleDomainSuffix, Value: "example.com"},
		"full:example.com":   {Type: engine.RuleDomain, Value: "example.com"},
		"geosite:ru":         {Type: engine.RuleGeoSite, Value: "ru"},
		"geoip:private":      {Type: engine.RuleGeoIP, Value: "private"},
	} {
		kind := ruleTypeOf(destination)
		if got := (engine.Rule{Type: kind, Value: ruleValue(kind, destination)}); got != want {
			t.Errorf("%s -> %+v, want %+v", destination, got, want)
		}
	}
}

func TestWireGuardSurvivesTheVault(t *testing.T) {
	for name, source := range map[string]string{
		"conf": "[Interface]\nPrivateKey = cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=\nAddress = 10.7.0.2, fd00::2/128\n\n" +
			"[Peer]\nPublicKey = Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw=\nEndpoint = 198.51.100.7:51820\nAllowedIPs = 0.0.0.0/0, ::/0\n",
		"link": "wireguard://cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk%3D@198.51.100.7:51820" +
			"?publickey=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw%3D&address=10.7.0.2%2C2001%3Adb8%3A%3A2#WG",
	} {
		t.Run(name, func(t *testing.T) {
			result, err := parser.LinkParser{}.Parse([]byte(source))
			if err != nil || len(result.Servers) != 1 {
				t.Fatalf("Parse = %+v, %v", result, err)
			}
			document, err := credentialDocument(result.Servers[0])
			if err != nil {
				t.Fatal(err)
			}
			var o engine.Outbound
			values, err := parseCredential(document)
			if err != nil {
				t.Fatal(err)
			}
			if err := applyCredential(&o, values); err != nil {
				t.Fatal(err)
			}
			if o.PrivateKey != "cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=" {
				t.Errorf("private key = %q", o.PrivateKey)
			}
			if len(o.Addresses) != 2 || o.Addresses[0] != "10.7.0.2/32" {
				t.Errorf("addresses = %v", o.Addresses)
			}
			if len(o.Peers) != 1 || o.Peers[0].Endpoint != "198.51.100.7:51820" || o.Peers[0].PublicKey == "" {
				t.Errorf("peers = %+v", o.Peers)
			}
		})
	}
}

func TestPlanCarriesDefencesAndEnginePin(t *testing.T) {
	in := &corev1.SessionPlan{
		Outbounds:      []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
		AntiCensorship: &corev1.AntiCensorship{TlsFragment: true, FragmentLength: "50-100"},
		Engines:        []string{"xray"},
		TunnelMode:     corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if !p.Options.Fragment.Enabled || p.Options.Fragment.Length != "50-100" || len(p.Engines) != 1 || p.Engines[0] != engine.KindXray {
		t.Fatalf("defences or engine preference lost: %+v %v", p.Options.Fragment, p.Engines)
	}
}

func TestAmneziaWGSurvivesTheVault(t *testing.T) {
	conf := "[Interface]\nPrivateKey = cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=\nAddress = 10.8.0.2/32\n" +
		"Jc = 4\nJmin = 40\nJmax = 70\nS1 = 15\nS2 = 25\nS3 = 10\nS4 = 5\nH1 = 100000-100100\nH2 = 200000\nH3 = 300000\nH4 = 400000\n" +
		"I1 = <b 0xf6ab3267fa><c><t><r 10>\n\n[Peer]\nPublicKey = Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw=\nEndpoint = 198.51.100.7:51820\nAllowedIPs = 0.0.0.0/0\n"
	result, err := parser.LinkParser{}.Parse([]byte(conf))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	document, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	values, err := parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	want := engine.AmneziaWG{Jc: 4, Jmin: 40, Jmax: 70, S1: 15, S2: 25, S3: 10, S4: 5,
		H1: "100000-100100", H2: "200000", H3: "300000", H4: "400000", I1: "<b 0xf6ab3267fa><c><t><r 10>"}
	if o.Amnezia == nil || *o.Amnezia != want {
		t.Fatalf("amneziawg = %+v, want %+v", o.Amnezia, want)
	}

	if err := applyCredential(&o, map[string]string{"amneziawg": `{"jc":"four"}`}); err == nil {
		t.Fatal("a parameter that is not a number must fail the plan")
	}
}

func TestPlanKeepsEngineControlAndTheLocalProxyPrivate(t *testing.T) {
	base := func(mode corev1.TunnelMode, lp *corev1.LocalProxy) *corev1.SessionPlan {
		return &corev1.SessionPlan{TunnelMode: mode, LocalProxy: lp,
			Outbounds: []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}}}
	}
	p, err := planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_SYSTEM, nil), "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if !p.PrivateControl || p.LocalProxy.Enabled {
		t.Errorf("by default a tun session has private control and no listener: %+v %+v", p.PrivateControl, p.LocalProxy)
	}
	p, err = planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_APPLICATION, nil), "s", nil)
	if err != nil || !p.LocalProxy.Enabled {
		t.Errorf("the system proxy mode needs its listener: %+v, %v", p.LocalProxy, err)
	}
	login := &corev1.LocalProxy{Enabled: true, Username: "me", Password: "local-proxy-password"}
	if p, err = planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_SYSTEM, login), "s", nil); err != nil || p.LocalProxy.Username != "me" {
		t.Errorf("a tun session may share a locked listener: %+v, %v", p.LocalProxy, err)
	}
	if _, err := planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_APPLICATION, login), "s", nil); err == nil {
		t.Error("a login the system proxy cannot carry must be refused")
	}
	if _, err := planFromProto(base(corev1.TunnelMode_TUNNEL_MODE_SYSTEM, &corev1.LocalProxy{Enabled: true, Username: "me"}), "s", nil); err == nil {
		t.Error("half a login must be refused")
	}
}

func TestPlanCarriesGroupsAndAppliesThePreset(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}, {Id: "b", Protocol: "direct"}},
		Groups: []*corev1.GroupSpec{
			{Name: "Proxy", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"Auto", "a", "b"}},
			{Name: "Auto", Type: corev1.GroupType_GROUP_TYPE_URL_TEST, Members: []string{"a", "b"}},
		},
		Routes:  []*corev1.RoutingRule{{Destination: "domain:example.org", OutboundId: "b"}},
		Routing: &corev1.RoutingOptions{Preset: "ru", ProxyTarget: "Proxy", BlockAds: true},
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(p.Groups) != 2 || p.Groups[0].Outbounds[0] != "Auto" {
		t.Fatalf("groups = %+v: a group may hold a group listed after it", p.Groups)
	}
	if p.Rules[0].Value != "example.org" || p.Rules[1].Target != "reject" {
		t.Fatalf("the user's route first, then the ad block: %+v", p.Rules[:2])
	}
	if last := p.Rules[len(p.Rules)-1]; last.Type != engine.RuleMatchAll || last.Target != "Proxy" {
		t.Fatalf("the rest goes to the group: %+v", last)
	}

	for name, mutate := range map[string]func(*corev1.SessionPlan){
		"cycle":            func(sp *corev1.SessionPlan) { sp.Groups[1].Members = []string{"Proxy"} },
		"unknown member":   func(sp *corev1.SessionPlan) { sp.Groups[1].Members = []string{"ghost"} },
		"group named a":    func(sp *corev1.SessionPlan) { sp.Groups[1].Name = "a" },
		"unknown target":   func(sp *corev1.SessionPlan) { sp.Routing.ProxyTarget = "ghost" },
		"unknown preset":   func(sp *corev1.SessionPlan) { sp.Routing.Preset = "mars" },
		"type not set":     func(sp *corev1.SessionPlan) { sp.Groups[0].Type = corev1.GroupType_GROUP_TYPE_UNSPECIFIED },
		"duplicate groups": func(sp *corev1.SessionPlan) { sp.Groups[1].Name = "Proxy" },
	} {
		broken := proto.Clone(in).(*corev1.SessionPlan)
		mutate(broken)
		if _, err := planFromProto(broken, "s", nil); err == nil {
			t.Errorf("%s must be refused", name)
		}
	}
}

// TestEveryEngineAcceptsAPlanWithGroupsAndAPreset follows a contract plan with
// a select group, an automatic group and a preset to each engine's validator.
func TestEveryEngineAcceptsAPlanWithGroupsAndAPreset(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray, mihomo and the geo databases")
	}
	ctx := context.Background()
	reg := registry.Discover(ctx, dir, supervise.Config{HomeDir: t.TempDir()})
	for _, kind := range []string{"sing-box", "xray", "mihomo"} {
		t.Run(kind, func(t *testing.T) {
			in := &corev1.SessionPlan{
				TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
				Engines:    []string{kind},
				// sing-box and Xray are controlled over
				// loopback ports only.
				NetworkControlAllowed: kind != "mihomo",
				Outbounds:             []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}, {Id: "b", Protocol: "direct"}},
				Groups: []*corev1.GroupSpec{
					{Name: "Proxy", Type: corev1.GroupType_GROUP_TYPE_SELECT, Members: []string{"Auto", "a", "b"}},
					{Name: "Auto", Type: corev1.GroupType_GROUP_TYPE_URL_TEST, Members: []string{"a", "b"}},
				},
				Routing: &corev1.RoutingOptions{Preset: "ru", ProxyTarget: "Proxy", BlockAds: true},
			}
			p, err := planFromProto(in, "s", nil)
			if err != nil {
				t.Fatal(err)
			}
			eng, err := reg.Factory()(ctx, p)
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = eng.Close() }()
			if err := eng.Validate(ctx, p); err != nil {
				t.Fatal(err)
			}
		})
	}
}

func TestPlanCarriesABypassOutbound(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{{Id: "zapret", Protocol: "bypass",
			Bypass: &corev1.BypassStrategy{SplitPos: []string{"1", "midsld"}, Disorder: true}}},
		Routes: []*corev1.RoutingRule{{Destination: "geosite:youtube", OutboundId: "zapret"}},
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if b := p.Outbounds[0].Bypass; b == nil || !b.Disorder || len(b.SplitPos) != 2 {
		t.Fatalf("bypass = %+v", p.Outbounds[0])
	}
	in.Outbounds[0].Bypass = &corev1.BypassStrategy{SplitPos: []string{"1 --debug=@/tmp/x"}}
	if _, err := planFromProto(in, "s", nil); err == nil {
		t.Fatal("a split position carrying an option must be refused")
	}
}

func TestTunPlanGetsResolversWhenItNamesNone(t *testing.T) {
	plan := func(mode corev1.TunnelMode, servers ...string) *corev1.SessionPlan {
		return &corev1.SessionPlan{
			TunnelMode: mode,
			Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
			DnsPolicy:  &corev1.DnsPolicy{Servers: servers},
		}
	}
	p, err := planFromProto(plan(corev1.TunnelMode_TUNNEL_MODE_SYSTEM), "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if !p.DNS.Enabled || len(p.DNS.Servers) != 2 || p.DNS.Servers[0].Transport != engine.DNSHTTPS {
		t.Fatalf("a tun plan without resolvers must get the defaults: %+v", p.DNS)
	}
	p, err = planFromProto(plan(corev1.TunnelMode_TUNNEL_MODE_SYSTEM, "tls://dns.example:853"), "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(p.DNS.Servers) != 1 || p.DNS.Servers[0].Address != "dns.example" {
		t.Fatalf("the person's resolver replaces the defaults: %+v", p.DNS)
	}
	p, err = planFromProto(plan(corev1.TunnelMode_TUNNEL_MODE_APPLICATION), "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if p.DNS.Enabled {
		t.Fatalf("a proxy plan resolves through the system unless asked: %+v", p.DNS)
	}
}

func TestPlanCarriesTheIPv6Choice(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
		Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if p.Options.IPv6 {
		t.Fatal("IPv6 is off unless asked for")
	}
	in.Ipv6 = true
	if p, _ = planFromProto(in, "s", nil); !p.Options.IPv6 {
		t.Fatal("the IPv6 choice must reach the engine options")
	}
}

func TestTunStackReachesTheEngineAndRejectsInvalidChoices(t *testing.T) {
	in := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds: []*corev1.OutboundSpec{{Id: "out", Protocol: "direct"}}}
	for _, stack := range []string{"", "system", "gvisor", "mixed", "mips"} {
		in.TunStack = stack
		p, err := planFromProto(in, "stack", nil)
		if err != nil || p.Tun.Stack != stack {
			t.Fatalf("stack %q was lost: %+v, %v", stack, p, err)
		}
	}
	in.TunStack = "unknown"
	if _, err := planFromProto(in, "stack", nil); err == nil {
		t.Fatal("an unknown stack must be refused")
	}
	in.TunStack, in.TunnelMode = "system", corev1.TunnelMode_TUNNEL_MODE_APPLICATION
	if _, err := planFromProto(in, "stack", nil); err == nil {
		t.Fatal("a stack cannot be silently ignored in proxy mode")
	}
}

func TestAProfileSurvivesTheVault(t *testing.T) {
	profile := `{"remarks":"x","outbounds":[{"protocol":"vless","tag":"proxy"}],"routing":{"rules":[]}}`
	packed, err := packProfile(profile)
	if err != nil {
		t.Fatal(err)
	}
	back, err := unpackProfile(packed)
	if err != nil || string(back) != profile {
		t.Fatalf("round trip = %q, %v", back, err)
	}
	if _, err := unpackProfile("not base64"); err == nil {
		t.Fatal("an unreadable profile must be refused")
	}
}

func TestARuleCanNameAProgram(t *testing.T) {
	in := &corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{{Id: "a", Protocol: "direct"}},
		Routes:     []*corev1.RoutingRule{{Destination: "process:telegram-desktop", OutboundId: "direct"}},
	}
	p, err := planFromProto(in, "s", nil)
	if err != nil {
		t.Fatal(err)
	}
	if r := p.Rules[0]; r.Type != engine.RuleProcess || r.Value != "telegram-desktop" {
		t.Fatalf("rule = %+v", r)
	}
}

func TestConnectCarriesTheKillSwitchToTheSession(t *testing.T) {
	plan := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION}
	if got := sessionSettings(&corev1.ConnectRequest{SessionPlan: plan, KillSwitch: true}); !got.KillSwitch || got.TunnelMode != "application" {
		t.Errorf("settings = %+v, want the kill switch armed in application mode", got)
	}
	if sessionSettings(&corev1.ConnectRequest{SessionPlan: plan}).KillSwitch {
		t.Error("a Connect without the flag must leave the kill switch off")
	}
}

func TestGroupSwitchReachesTheWire(t *testing.T) {
	out := toWireEvent(session.Event{Sequence: 7, Kind: session.EventGroup,
		Switch: &session.GroupSwitch{Group: "auto", Previous: "out-1", Selected: "out-2"}}, nil)
	moved := out.GetGroupSwitched()
	if moved.GetGroup() != "auto" || moved.GetPrevious() != "out-1" || moved.GetSelected() != "out-2" || out.GetSequence() != 7 {
		t.Errorf("event = %v", out)
	}
}

func TestCensorVerdictReachesTheWire(t *testing.T) {
	// SW4: a journal censor verdict must reach the client as the
	// structured CensorshipDetected payload, not only as a free-text
	// log line.
	verdict := &censor.Verdict{
		Kind:        censor.KindDataStall,
		Confidence:  0.7,
		Explanation: "session went silent after data flowed",
		Evidence:    []string{"16 KiB received, then 8s of silence"},
	}
	out := toWireEvent(session.Event{Sequence: 9, Kind: session.EventCensor,
		Detail: "censorship check: session went silent after data flowed", Censor: verdict}, nil)
	got := out.GetCensorshipDetected()
	if got == nil {
		t.Fatalf("payload = %T, want CensorshipDetected", out.GetPayload())
	}
	if got.GetKind() != "data_stall" || got.GetConfidence() != 0.7 ||
		got.GetExplanation() != "session went silent after data flowed" ||
		len(got.GetEvidence()) != 1 || got.GetEvidence()[0] != "16 KiB received, then 8s of silence" {
		t.Errorf("verdict = %+v", got)
	}
	if out.GetSequence() != 9 {
		t.Errorf("sequence = %d, want 9", out.GetSequence())
	}
	// A censor event without a verdict keeps the free-text line.
	out = toWireEvent(session.Event{Kind: session.EventCensor, Detail: "censorship check: something"}, nil)
	if lines := out.GetLogBatch().GetLines(); len(lines) != 1 || lines[0] != "censorship check: something" {
		t.Errorf("verdictless censor event = %v, want the text line", out.GetLogBatch())
	}
}

func TestProfileDisplayMetadataKeepsAdapterAndCredentialsPrivate(t *testing.T) {
	payload := `{"remarks":"Edge","outbounds":[{"protocol":"vless","settings":{"vnext":[{"address":"edge.example.com","port":443,"users":[{"id":"b831381d-6324-4d53-ad4f-8cda48b30811"}]}]},"streamSettings":{"network":"xhttp","security":"reality"}},{"protocol":"freedom"}]}`
	result, err := parser.LinkParser{}.Parse([]byte(payload))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	wire := outboundToProto(result.Servers[0], "vault:edge")
	if wire.Protocol != "xray-profile" || wire.DisplayProtocol != "vless" || wire.Transport != "xhttp" || wire.Security != "reality" {
		t.Fatalf("display metadata = %v", wire)
	}
	if wire.Credentials.Reference != "vault:edge" {
		t.Fatal("the display model must retain only the credential reference")
	}
	encoded, err := proto.Marshal(wire)
	if err != nil {
		t.Fatal(err)
	}
	var decoded corev1.OutboundSpec
	if err := proto.Unmarshal(encoded, &decoded); err != nil || !proto.Equal(wire, &decoded) {
		t.Fatalf("display metadata round trip: %v, %v", &decoded, err)
	}
}

// TestParseCredentialRejectsForeignMaterial locks SORA-M8: only the JSON
// credential document is accepted; raw proxy URLs, empty or truncated
// bytes fail closed instead of producing an empty credential.
func TestParseCredentialRejectsForeignMaterial(t *testing.T) {
	for name, material := range map[string][]byte{
		"empty":         {},
		"whitespace":    []byte("  \n "),
		"proxy URL":     []byte("vless://11111111-1111-1111-1111-111111111111@example.com:443?security=reality#x"),
		"truncated":     []byte(`{"uuid": "11111111-`),
		"not an object": []byte(`["uuid"]`),
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := parseCredential(material); err == nil {
				t.Fatalf("parseCredential(%q) = nil, want an error", material)
			}
		})
	}
	if _, err := parseCredential([]byte(`{"uuid":"ok"}`)); err != nil {
		t.Fatalf("parseCredential(valid document) = %v, want nil", err)
	}
}

// TestSplitDNSServerParsesPortsSafely locks SORA-M13: host:port and
// [ipv6]:port go through net.SplitHostPort, and bare IPv6 literals are
// never split on a colon.
func TestSplitDNSServerParsesPortsSafely(t *testing.T) {
	for _, tc := range []struct {
		in        string
		host      string
		port      uint16
		transport engine.DNSTransport
	}{
		{"1.1.1.1", "1.1.1.1", 0, engine.DNSPlain},
		{"1.1.1.1:53", "1.1.1.1", 53, engine.DNSPlain},
		{"tls://dns.example.com:853", "dns.example.com", 853, engine.DNSTLS},
		{"https://1.1.1.1/dns-query", "1.1.1.1", 0, engine.DNSHTTPS},
		{"h3://1.1.1.1/dns-query", "1.1.1.1", 0, engine.DNSH3},
		{"h3://dns.example.com:443/dns-query", "dns.example.com", 443, engine.DNSH3},
		{"[2001:db8::1]:853", "2001:db8::1", 853, engine.DNSPlain},
		{"tls://[2001:db8::1]:853", "2001:db8::1", 853, engine.DNSTLS},
		{"2001:db8::1", "2001:db8::1", 0, engine.DNSPlain},
		{"2001:db8::53", "2001:db8::53", 0, engine.DNSPlain},
		{"dns.example.com:notaport", "dns.example.com:notaport", 0, engine.DNSPlain},
	} {
		t.Run(tc.in, func(t *testing.T) {
			host, port, transport := splitDNSServer(tc.in)
			if host != tc.host || port != tc.port || transport != tc.transport {
				t.Errorf("splitDNSServer(%q) = %q, %d, %q; want %q, %d, %q",
					tc.in, host, port, transport, tc.host, tc.port, tc.transport)
			}
		})
	}
}

// TestRuleTypeOfDetectsIPAddresses locks SORA-M14: IPv6 literals contain
// colons but are IP rules, not ports.
func TestRuleTypeOfDetectsIPAddresses(t *testing.T) {
	for destination, want := range map[string]engine.RuleType{
		"2001:db8::1":        engine.RuleIPCIDR,
		"::1":                engine.RuleIPCIDR,
		"1.2.3.4":            engine.RuleIPCIDR,
		"10.0.0.0/8":         engine.RuleIPCIDR,
		"2001:db8::/32":      engine.RuleIPCIDR,
		"443":                engine.RulePort,
		"example.com":        engine.RuleDomainKeyword,
		"domain:example.com": engine.RuleDomainSuffix,
		"geosite:google":     engine.RuleGeoSite,
	} {
		t.Run(destination, func(t *testing.T) {
			if got := ruleTypeOf(destination); got != want {
				t.Errorf("ruleTypeOf(%q) = %q, want %q", destination, got, want)
			}
		})
	}
}

// TestApplyCredentialRejectsBrokenPeerJSON locks SORA-L17: a broken
// WireGuard peer document must fail plan building, not silently produce a
// peerless outbound.
func TestApplyCredentialRejectsBrokenPeerJSON(t *testing.T) {
	var o engine.Outbound
	if err := applyCredential(&o, map[string]string{"peers": `[{broken`}); err == nil {
		t.Fatal("broken peer JSON must fail the plan")
	}
	var ok engine.Outbound
	if err := applyCredential(&ok, map[string]string{"peers": `[{"public_key":"abc=","allowed_ips":["0.0.0.0/0"]}]`}); err != nil {
		t.Fatalf("valid peer JSON was rejected: %v", err)
	}
	if len(ok.Peers) != 1 {
		t.Fatalf("got %d peers, want 1", len(ok.Peers))
	}
}

func TestShadowsocksPluginSurvivesTheVault(t *testing.T) {
	link := "ss://YWVzLTI1Ni1nY206cGFzcw@example.com:8388?plugin=v2ray-plugin%3Btls%3Bhost%3Dexample.com#SS"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	document, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	values, err := parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	if o.Plugin != "v2ray-plugin" || o.PluginOpts != "tls;host=example.com" {
		t.Errorf("plugin lost on the way to the engine: %q %q", o.Plugin, o.PluginOpts)
	}
	// Secrets: plugin options must be masked like the other credentials.
	masked := false
	for _, s := range o.Secrets() {
		if s == "tls;host=example.com" {
			masked = true
		}
	}
	if !masked {
		t.Error("plugin_opts must be in the redaction set")
	}
}

// testSecrets is a minimal resolver fake for plan-building tests.
type testSecrets map[string][]byte

func (m testSecrets) Get(reference string) ([]byte, error) {
	if b, ok := m[reference]; ok {
		return b, nil
	}
	return nil, errors.New("control: no such secret " + reference)
}

// planOutboundFromLink runs the full import path for one link: parse,
// credential document, proto spec, plan-level outbound assembly.
func planOutboundFromLink(t *testing.T, link string) engine.Outbound {
	t.Helper()
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	spec := result.Servers[0]
	document, err := credentialDocument(spec)
	if err != nil {
		t.Fatal(err)
	}
	reference, err := referenceOf(spec)
	if err != nil {
		t.Fatal(err)
	}
	outbound, err := outboundFromProto(0, outboundToProto(spec, reference),
		testSecrets{reference: document})
	if err != nil {
		t.Fatal(err)
	}
	return outbound
}

// TestAutoVisionAtPlanLevel checks the S2 rule where it is implemented:
// a VLESS+TCP+REALITY link without a flow gets xtls-rprx-vision in the
// plan with FlowAuto set; a link with an explicit flow keeps it and
// never gets the auto badge.
func TestAutoVisionAtPlanLevel(t *testing.T) {
	const base = "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443" +
		"?type=tcp&security=reality&pbk=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw" +
		"&sid=6ba85179e30d4fc2&sni=www.example.com&fp=chrome&encryption=none"

	auto := planOutboundFromLink(t, base+"#Edge")
	if auto.Flow != engine.VisionFlow {
		t.Errorf("plan flow = %q, want auto-vision %q", auto.Flow, engine.VisionFlow)
	}
	if !auto.FlowAuto {
		t.Error("plan FlowAuto = false, want the auto badge recorded")
	}

	manual := planOutboundFromLink(t, base+"&flow=xtls-rprx-vision-udp443#Edge")
	if manual.Flow != "xtls-rprx-vision-udp443" {
		t.Errorf("manual plan flow = %q, want it respected", manual.Flow)
	}
	if manual.FlowAuto {
		t.Error("manual plan FlowAuto = true, want no auto badge")
	}
}

// TestAutoVisionSkipsNonTCPAtPlanLevel locks that the plan never assigns
// vision to a non-TCP transport: that combination stays a hard render
// error instead of being papered over.
func TestAutoVisionSkipsNonTCPAtPlanLevel(t *testing.T) {
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443" +
		"?type=ws&security=reality&pbk=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw" +
		"&sid=6ba85179e30d4fc2&sni=www.example.com&fp=chrome&encryption=none&path=%2Fx#Edge"
	o := planOutboundFromLink(t, link)
	if o.Flow != "" || o.FlowAuto {
		t.Errorf("ws plan flow = %q auto=%v, want untouched", o.Flow, o.FlowAuto)
	}
}

func TestAmneziaWG31SurvivesTheVault(t *testing.T) {
	// AmneziaWG 3.1 fields must survive the same vault round trip as the
	// 1.x/2.0 keys (TestAmneziaWGSurvivesTheVault): before this test the
	// import filter dropped every 3.1 key, so a 3.1 config silently
	// degraded to a plain 2.0 profile.
	conf := "[Interface]\nPrivateKey = cKE7LmCF61IhqqABGhvJ44jWXp8fKymcMAEVAzLDYVk=\nAddress = 10.8.0.2/32\n" +
		"Jc = 4\nS1 = 15\nS2 = 25\nS3 = 20\nS4 = 18\n" +
		"HeaderProtectionKey = AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\n" +
		"ContentPaddingAddition = 1-16\nRekeyAfterTime = 60-120\nRekeyTimeout = 5\n" +
		"RejectAfterTime = 180\nKeepaliveTimeout = 30\nMaxHandshakeAttempts = 10\n" +
		"RandomTrailers = true\nDisableCookies = 1\n" +
		"MasqueradeProtocol = dns\nMasqueradeDomain = dns.example\n\n" +
		"[Peer]\nPublicKey = Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw=\nEndpoint = 198.51.100.7:51820\nAllowedIPs = 0.0.0.0/0\n"
	result, err := parser.LinkParser{}.Parse([]byte(conf))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	document, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	values, err := parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	if o.Amnezia == nil {
		t.Fatal("amneziawg was lost on the way to the plan")
	}
	a := *o.Amnezia
	if a.HeaderProtectionKey != "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" ||
		a.ContentPaddingAddition != "1-16" || a.RekeyAfterTime != "60-120" ||
		a.RekeyTimeout != "5" || a.RejectAfterTime != "180" ||
		a.KeepaliveTimeout != "30" || a.MaxHandshakeAttempts != "10" {
		t.Fatalf("3.1 range/protection fields lost: %+v", a)
	}
	if !a.RandomTrailers || !a.DisableCookies {
		t.Fatalf("3.1 boolean fields lost: %+v", a)
	}
	if a.MasqueradeProtocol != "dns" || a.MasqueradeDomain != "dns.example" {
		t.Fatalf("masquerade fields lost: %+v", a)
	}
	if !a.UsesAWG31() {
		t.Fatal("restored config must report UsesAWG31 so engine selection keeps the 3.1 gate")
	}
}
