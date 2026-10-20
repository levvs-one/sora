package engine

import (
	"runtime"
	"strings"
	"testing"
)

func validPlan() *Plan {
	return &Plan{
		SessionID: "s-1",
		Outbounds: []Outbound{
			{ID: "a", Name: "A", Protocol: ProtocolVMess, Server: "a.example.com", Port: 443, UUID: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"},
			{ID: "b", Name: "B", Protocol: ProtocolHysteria2, Server: "b.example.com", Port: 8443, Password: "secret-pass"},
		},
		Groups: []Group{{Name: "Proxy", Type: GroupSelect, Outbounds: []string{"a", "b"}}},
		Rules:  []Rule{{Type: RuleMatchAll, Target: "a"}},
	}
}

func TestPlanValidateAcceptsAGoodPlan(t *testing.T) {
	if err := validPlan().Validate(); err != nil {
		t.Fatalf("good plan rejected: %v", err)
	}
}

func TestPlanValidateReportsEveryProblem(t *testing.T) {
	plan := validPlan()
	plan.SessionID = ""
	plan.Outbounds[1].ID = plan.Outbounds[0].ID
	plan.Outbounds[1].Server = "https://wrong.example.com/"
	plan.Groups[0].Outbounds = append(plan.Groups[0].Outbounds, "missing")
	plan.Rules = append(plan.Rules, Rule{Type: RuleIPCIDR, Value: "not-a-cidr", Target: "nope"})

	err := plan.Validate()
	if err == nil {
		t.Fatal("a broken plan must not validate")
	}
	text := err.Error()
	for _, want := range []string{"empty session id", "duplicate outbound id", "bare host", "unknown outbound", "not a CIDR", "unknown target"} {
		if !strings.Contains(text, want) {
			t.Errorf("error does not report %q:\n%s", want, text)
		}
	}
}

func TestPlanRejectsUntrustedDisplayNames(t *testing.T) {
	for _, name := range []string{"with\nnewline", "with\ttab", " padded ", strings.Repeat("x", MaxNameBytes+1)} {
		plan := validPlan()
		plan.Outbounds[0].Name = name
		if err := plan.Validate(); err == nil {
			t.Errorf("display name %q must be rejected", name)
		}
	}
	good := validPlan()
	good.Outbounds[0].Name = "Токио 01 (JP)"
	if err := good.Validate(); err != nil {
		t.Errorf("an ordinary localized name must be accepted: %v", err)
	}
}

func TestPlanRequiresAProbeTargetForAutomaticGroups(t *testing.T) {
	plan := validPlan()
	plan.Groups[0] = Group{Name: "Auto", Type: GroupURLTest, Outbounds: []string{"a"}}
	if err := plan.Validate(); err == nil || !strings.Contains(err.Error(), "test url") {
		t.Fatalf("an auto group without any probe url must fail: %v", err)
	}
	plan.Options.TestURL = TestURLProduction
	if err := plan.Validate(); err != nil {
		t.Fatalf("the plan level probe must satisfy the group: %v", err)
	}
}

func TestSecretsAndWarnings(t *testing.T) {
	plan := validPlan()
	secrets := plan.Secrets()
	if len(secrets) != 2 {
		t.Fatalf("expected the uuid and the password, got %v", secrets)
	}
	plan.Outbounds[0].TLS = TLS{Enabled: true}
	if warnings := plan.Outbounds[0].Warnings(); len(warnings) != 1 || warnings[0] != "tls-server-name-missing" {
		t.Errorf("unexpected warnings: %v", warnings)
	}
}

func TestSelectEnginePicksByCapability(t *testing.T) {
	plan := validPlan()
	plan.Outbounds = append(plan.Outbounds, Outbound{
		ID: "c", Name: "C", Protocol: ProtocolTUIC, Server: "c.example.com", Port: 9443,
		UUID: "cccccccc-1111-2222-3333-444444444444", Password: "another-secret",
	})
	available := []Availability{
		{Kind: KindXray, Usable: true, Version: mustVersion(t, "26.3.27")},
		{Kind: KindMihomo, Usable: true, Version: mustVersion(t, "1.19.32")},
		{Kind: KindSingBox, Usable: false, Reason: "binary missing"},
	}

	sel, err := SelectEngine(plan, available, []Kind{KindXray, KindMihomo, KindSingBox})
	if err != nil {
		t.Fatalf("selection failed: %v", err)
	}
	if sel.Kind != KindMihomo {
		t.Errorf("only mihomo carries tuic, got %s (%s)", sel.Kind, sel.Reason)
	}
	if !strings.Contains(strings.Join(sel.Rejected, ";"), "protocol tuic") {
		t.Errorf("the rejection reason must name the missing protocol: %v", sel.Rejected)
	}
}

func TestSelectEngineRefusesWhenNothingCanCarryThePlan(t *testing.T) {
	plan := validPlan()
	plan.Tun = Tun{Enabled: true}
	_, err := SelectEngine(plan, []Availability{{Kind: KindXray, Usable: false, Reason: "not installed"}}, []Kind{KindXray})
	if err == nil || !strings.Contains(err.Error(), "not installed") {
		t.Fatalf("expected a readable reason, got %v", err)
	}
}

func TestSelectEngineRespectsMinimumVersion(t *testing.T) {
	_, err := SelectEngine(validPlan(), []Availability{
		{Kind: KindMihomo, Usable: true, Version: mustVersion(t, "1.18.0")},
	}, []Kind{KindMihomo})
	if err == nil || !strings.Contains(err.Error(), "older than") {
		t.Fatalf("an outdated engine must be rejected: %v", err)
	}
}

func TestSingBoxCapabilitiesFollowTheBuildRatherThanTheName(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Outbounds[0].Transport.Type = "xhttp"
	for _, tc := range []struct {
		version string
		tags    []string
		want    bool
	}{
		{"1.14.3", []string{"with_xhttp"}, false},
		{"1.14.3-lx.14", nil, false},
		{"1.14.3-lx.14", []string{"with_xhttp", "with_awg"}, true},
		{"1.14.2-lx.14", []string{"with_xhttp"}, false},
	} {
		version := mustVersion(t, tc.version)
		_, err := SelectEngine(p, []Availability{{Kind: KindSingBox, Usable: true, Version: version, BuildTags: tc.tags}}, []Kind{KindSingBox})
		if (err == nil) != tc.want {
			t.Errorf("version %s, tags %v: %v", tc.version, tc.tags, err)
		}
	}
	if Catalog[KindSingBox].Supports(FeatureXHTTP) {
		t.Fatal("discovering a fork changed upstream capabilities")
	}
	p.Outbounds[0].Transport.Type = "tcp"
	p.Outbounds[0].Amnezia = &AmneziaWG{J1: "legacy"}
	caps := BuildCapabilities(KindSingBox, mustVersion(t, "1.14.3-lx.14"), []string{"with_awg"})
	if len(caps.Missing(p)) == 0 {
		t.Fatal("legacy AWG fields must not be silently discarded")
	}
}

// TestSingBoxFloorKeepsTheLXFork: the sing-box floor (upstream stable
// 1.14.3 — 1.15 exists only as alpha as of 2026-10-20) accepts both the
// current upstream stable and the shipped lx. fork, which tracks the
// same 1.14 base. Renders were validated with `sing-box check` against
// v1.14.2 upstream, so a 1.15 floor would only accept prereleases: it
// is not kept.
func TestSingBoxFloorKeepsTheLXFork(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	for _, tc := range []struct {
		version string
		tags    []string
		want    bool
	}{
		{"1.14.3", nil, true}, // current upstream stable
		{"1.14.2", nil, false},
		{"1.15.0", nil, true}, // a future stable stays accepted
		// Less ignores the pre-release, like the fork floor does.
		{"1.15.0-alpha.12", nil, true},
		{"1.14.3-lx.14", []string{"with_awg"}, true},  // shipped fork
		{"1.14.2-lx.14", []string{"with_awg"}, false}, // fork below its own floor
	} {
		_, err := SelectEngine(p, []Availability{{
			Kind: KindSingBox, Usable: true,
			Version:   mustVersion(t, tc.version),
			BuildTags: tc.tags,
		}}, []Kind{KindSingBox})
		if (err == nil) != tc.want {
			t.Errorf("version %s, tags %v: selected=%v, want %v (err=%v)", tc.version, tc.tags, err == nil, tc.want, err)
		}
	}
}

// TestTunStackNeverSilentlyDroppedOnSingBox115: sing-box 1.15+ ignores the
// TUN stack option, so an explicit stack must be reported missing rather
// than silently dropped; the 1.14-based lx. fork still honors it (except
// "mips", which no sing-box build knows).
func TestTunStackNeverSilentlyDroppedOnSingBox115(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Tun.Enabled = true
	for _, tc := range []struct {
		version     string
		stack       string
		wantMissing bool
	}{
		{"1.15.0", "gvisor", true},
		{"1.15.0", "mixed", true},
		{"1.15.0", "", false},
		{"1.14.3-lx.14", "gvisor", false},
		{"1.14.3-lx.14", "mips", true},
		{"1.14.3-lx.14", "", false},
	} {
		p.Tun.Stack = tc.stack
		caps := BuildCapabilities(KindSingBox, mustVersion(t, tc.version), nil)
		missing := caps.MissingFor(p, mustVersion(t, tc.version))
		if got := len(missing) != 0; got != tc.wantMissing {
			t.Errorf("version %s stack %q: missing=%v, want missing=%v (%v)",
				tc.version, tc.stack, got, tc.wantMissing, missing)
		}
	}
}

func TestXrayPlaintextVLESSVersionGate(t *testing.T) {
	mk := func(proto Protocol, tls TLS, encryption string) *Plan {
		return &Plan{
			SessionID: "s-1",
			Outbounds: []Outbound{{
				ID: "o1", Name: "O1", Protocol: proto,
				Server: "x.example.com", Port: 443, UUID: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", TLS: tls,
				Encryption: encryption,
			}},
		}
	}
	tls := TLS{Enabled: true, ServerName: "x.example.com"}
	reality := TLS{Reality: true, RealityPublicKey: "pubkey"}
	for _, tc := range []struct {
		name        string
		kind        Kind
		proto       Protocol
		tls         TLS
		encryption  string
		version     string // "" = unknown build
		wantMissing bool
	}{
		{"shipped pin keeps plaintext VLESS", KindXray, ProtocolVLESS, TLS{}, "", "26.3.27", false},
		{"cutoff refuses plaintext VLESS", KindXray, ProtocolVLESS, TLS{}, "", "26.7.11", true},
		{"newer build refuses plaintext VLESS", KindXray, ProtocolVLESS, TLS{}, "", "26.8.0", true},
		{"TLS VLESS survives the cutoff", KindXray, ProtocolVLESS, tls, "", "26.7.11", false},
		{"REALITY VLESS survives the cutoff", KindXray, ProtocolVLESS, reality, "", "26.7.11", false},
		{"VLESS Encryption survives the cutoff", KindXray, ProtocolVLESS, TLS{}, "mlkem768x25519plus.native.600s", "26.7.11", false},
		{"VLESS Encryption=none is still plaintext", KindXray, ProtocolVLESS, TLS{}, "none", "26.7.11", true},
		{"shipped pin keeps Trojan", KindXray, ProtocolTrojan, TLS{}, "", "26.3.27", false},
		{"Trojan without explicit TLS survives the cutoff (the xray renderer always sets security tls)", KindXray, ProtocolTrojan, TLS{}, "", "26.7.11", false},
		{"TLS Trojan survives the cutoff", KindXray, ProtocolTrojan, tls, "", "26.7.11", false},
		{"cutoff does not touch VMess", KindXray, ProtocolVMess, TLS{}, "", "26.7.11", false},
		{"other engines are a no-op", KindSingBox, ProtocolVLESS, TLS{}, "", "26.7.11", false},
		// Unknown (zero) version is fail-closed: treated as the cutoff
		// build or newer rather than as the shipped pin.
		{"unknown version fails closed on plaintext VLESS", KindXray, ProtocolVLESS, TLS{}, "", "", true},
		{"unknown version keeps TLS VLESS", KindXray, ProtocolVLESS, tls, "", "", false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var v Version
			if tc.version != "" {
				v = mustVersion(t, tc.version)
			}
			missing := Catalog[tc.kind].XrayPlaintextMissing(mk(tc.proto, tc.tls, tc.encryption), v)
			if got := len(missing) != 0; got != tc.wantMissing {
				t.Errorf("version %q: missing=%v, want missing=%v (%v)",
					tc.version, got, tc.wantMissing, missing)
			}
			if tc.wantMissing {
				joined := strings.Join(missing, "; ")
				if !strings.Contains(joined, "enable TLS or REALITY") {
					t.Errorf("version %q: error must say how to fix it, got %q", tc.version, joined)
				}
			}
		})
	}
}

// TestXrayPlaintextGateInEngineSelection locks the end-to-end behavior:
// the shipped 26.3.27 pin still carries plaintext VLESS, while a 26.7.11
// build rejects the plan with an actionable message.
func TestXrayPlaintextGateInEngineSelection(t *testing.T) {
	p := &Plan{
		SessionID: "s-1",
		Outbounds: []Outbound{{
			ID: "o1", Name: "O1", Protocol: ProtocolVLESS,
			Server: "x.example.com", Port: 443, UUID: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
		}},
	}
	for _, tc := range []struct {
		version    string
		wantSelect bool
	}{
		{"26.3.27", true},
		{"26.7.11", false},
	} {
		sel, err := SelectEngine(p,
			[]Availability{{Kind: KindXray, Usable: true, Version: mustVersion(t, tc.version)}},
			[]Kind{KindXray})
		if (err == nil) != tc.wantSelect {
			t.Errorf("version %s: selected=%v, want %v (err=%v)", tc.version, err == nil, tc.wantSelect, err)
		}
		if tc.wantSelect && sel.Kind != KindXray {
			t.Errorf("version %s: selected %s, want xray", tc.version, sel.Kind)
		}
		if !tc.wantSelect && (err == nil || !strings.Contains(err.Error(), "enable TLS or REALITY")) {
			t.Errorf("version %s: rejection must say how to fix it, got %v", tc.version, err)
		}
	}
}

func TestTLSVerificationSettingSelectsCompatibleEngine(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Outbounds[0].TLS = TLS{Enabled: true, Insecure: true}
	available := []Availability{
		{Kind: KindXray, Usable: true, Version: mustVersion(t, "26.3.27")},
		{Kind: KindSingBox, Usable: true, Version: mustVersion(t, "1.14.3-lx.14"), BuildTags: []string{"with_xhttp"}},
	}
	if _, err := SelectEngine(p, available, []Kind{KindXray}); err == nil || !strings.Contains(err.Error(), "TLS verification") {
		t.Fatalf("manual Xray must reject an unsupported setting before switching: %v", err)
	}
	selection, err := SelectEngine(p, available, []Kind{KindXray, KindSingBox})
	if err != nil || selection.Kind != KindSingBox {
		t.Fatalf("automatic selection should preserve the setting: %+v, %v", selection, err)
	}
	for _, tls := range []TLS{{Insecure: true}, {Enabled: true, Reality: true, Insecure: true}} {
		p.Outbounds[0].TLS = tls
		if _, err := SelectEngine(p, available, []Kind{KindXray}); err != nil {
			t.Fatalf("an unused TLS flag rejected plaintext or REALITY: %v", err)
		}
	}
}

func TestTunStackNeverSilentlyChangesWithTheEngine(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Tun.Enabled = true
	for _, stack := range []string{"system", "gvisor", "mixed", "mips"} {
		p.Tun.Stack = stack
		for _, kind := range []Kind{KindXray, KindSingBox, KindMihomo} {
			want := (kind != KindXray || (runtime.GOOS == "linux" && stack == "gvisor")) && (kind != KindSingBox || stack != "mips")
			if got := len(Catalog[kind].Missing(p)) == 0; got != want {
				t.Errorf("%s stack %s: supported %t, want %t", kind, stack, got, want)
			}
		}
	}
}

// TestPlanValidateRejectsUnknownProtocolAndTransport locks SORA-L16: an
// unknown protocol or transport must fail plan validation with a clear
// error, not surface late at eng.Apply.
func TestPlanValidateRejectsUnknownProtocolAndTransport(t *testing.T) {
	plan := validPlan()
	plan.Outbounds[0].Protocol = "foobar"
	plan.Outbounds[0].Transport.Type = "quic"
	err := plan.Validate()
	if err == nil {
		t.Fatal("a plan with an unknown protocol must not validate")
	}
	for _, want := range []string{`unknown protocol "foobar"`, `unknown transport "quic"`} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error does not report %q:\n%s", want, err)
		}
	}
	good := validPlan()
	if err := good.Validate(); err != nil {
		t.Fatalf("good plan rejected: %v", err)
	}
}

// TestDoH3ResolverRequiresDoH3Feature locks the DoH3 gate: a plan naming
// an h3:// resolver requires FeatureDoH3, so automatic selection routes it
// to sing-box/mihomo and never to Xray (whose render cannot speak H3).
func TestDoH3ResolverRequiresDoH3Feature(t *testing.T) {
	p := validPlan()
	p.DNS = DNS{Enabled: true, Servers: []DNSServer{
		{Tag: "dns-1", Transport: DNSH3, Address: "1.1.1.1"},
	}}
	if !p.RequiredFeatures()[FeatureDoH3] {
		t.Fatal("an h3:// resolver must require FeatureDoH3")
	}
	p.DNS.Servers[0].Transport = DNSHTTPS
	if p.RequiredFeatures()[FeatureDoH3] {
		t.Fatal("a plain DoH resolver must not require FeatureDoH3")
	}
}

// TestDoH3PlanAvoidsXray locks selection: with Xray pinned the h3 plan is
// rejected naming the missing feature; with a choice the selector prefers
// an engine that actually speaks DoH3.
func TestDoH3PlanAvoidsXray(t *testing.T) {
	p := validPlan()
	p.DNS = DNS{Enabled: true, Servers: []DNSServer{
		{Tag: "dns-1", Transport: DNSH3, Address: "1.1.1.1"},
	}}
	available := []Availability{
		{Kind: KindXray, Usable: true, Version: mustVersion(t, "26.3.27")},
		{Kind: KindSingBox, Usable: true, Version: mustVersion(t, "1.14.3-lx.14"), BuildTags: []string{"with_xhttp"}},
	}
	if _, err := SelectEngine(p, available, []Kind{KindXray}); err == nil || !strings.Contains(err.Error(), "doh3") {
		t.Fatalf("pinned Xray must reject the h3 plan naming doh3, got: %v", err)
	}
	sel, err := SelectEngine(p, available, []Kind{KindXray, KindSingBox})
	if err != nil || sel.Kind != KindSingBox {
		t.Fatalf("selection should route the h3 plan to sing-box: %+v, %v", sel, err)
	}
}

// TestFakeIPRange6Validation locks the IPv6 fake pool: it must be an IPv6
// CIDR when set, and a v4 CIDR or garbage fails plan validation.
func TestFakeIPRange6Validation(t *testing.T) {
	for _, tc := range []struct {
		name string
		pool string
		want string // "" means valid
	}{
		{"unset", "", ""},
		{"valid v6", "fd00::/48", ""},
		{"garbage", "not-a-cidr", "IPv6"},
		{"v4 in v6 field", "198.18.0.0/16", "IPv6"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			p := validPlan()
			p.DNS = DNS{Enabled: true, Mode: string(DNSFakeIP), FakeIPRange6: tc.pool}
			err := p.Validate()
			if tc.want == "" && err != nil {
				t.Fatalf("valid range rejected: %v", err)
			}
			if tc.want != "" && (err == nil || !strings.Contains(err.Error(), tc.want)) {
				t.Fatalf("range %q must fail validation naming %q, got: %v", tc.pool, tc.want, err)
			}
		})
	}
}
