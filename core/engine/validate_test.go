package engine

import (
	"strings"
	"testing"
)

func goodAmnezia() *AmneziaWG {
	return &AmneziaWG{
		Jc: 8, Jmin: 40, Jmax: 70,
		S1: 15, S2: 25, S3: 10, S4: 5,
		H1: "100000-800000", H2: "1000000-8000000",
		H3: "10000000-80000000", H4: "100000000-800000000",
		I1: "<b 0xc000000001><r 64><t>",
	}
}

func wireguardWithAmnezia(a *AmneziaWG) Outbound {
	return Outbound{
		ID:       "wg1",
		Protocol: ProtocolWireGuard,
		Server:   "198.51.100.7",
		Port:     51820,
		Amnezia:  a,
	}
}

func TestValidateAcceptsSaneAmneziaWG(t *testing.T) {
	if err := wireguardWithAmnezia(goodAmnezia()).Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
}

func TestValidateAcceptsDisabledAmneziaWG(t *testing.T) {
	// All-zero parameters: the struct marks "obfuscated WG" but every knob
	// is off, so the engine falls back to stock WireGuard behavior.
	if err := wireguardWithAmnezia(&AmneziaWG{}).Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
	if err := wireguardWithAmnezia(nil).Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
}

func TestValidateRejectsBadAmneziaWG(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(a *AmneziaWG)
		want   string
	}{
		{"jc too large", func(a *AmneziaWG) { a.Jc = 129 }, "jc 129"},
		{"jc negative", func(a *AmneziaWG) { a.Jc = -1 }, "jc -1"},
		{"jmin above jmax", func(a *AmneziaWG) { a.Jmin = 100 }, "jmin 100 exceeds jmax 70"},
		{"jmax fragments", func(a *AmneziaWG) { a.Jmax = 1500 }, "jmax 1500"},
		{"s1 over cap", func(a *AmneziaWG) { a.S1 = 1200 }, "s1 1200"},
		{"s2 over cap", func(a *AmneziaWG) { a.S2 = 1300 }, "s2 1300"},
		{"s4 over cap", func(a *AmneziaWG) { a.S4 = 64 }, "s4 64"},
		{"s1+56 collides with s2", func(a *AmneziaWG) { a.S1, a.S2 = 15, 71 }, "s1+56 must not equal s2"},
		{"h below floor", func(a *AmneziaWG) { a.H1 = "4" }, "h1"},
		{"h range reversed", func(a *AmneziaWG) { a.H2 = "900-100" }, "h2"},
		{"h not a number", func(a *AmneziaWG) { a.H3 = "abc" }, "h3"},
		{"h ranges overlap", func(a *AmneziaWG) { a.H4 = "50000-2000000" }, "overlap"},
		{"h singles equal", func(a *AmneziaWG) { a.H1, a.H2 = "12345", "12345" }, "overlap"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a := goodAmnezia()
			tc.mutate(a)
			err := wireguardWithAmnezia(a).Validate()
			if err == nil {
				t.Fatalf("Validate = nil, want error containing %q", tc.want)
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Validate = %v, want error containing %q", err, tc.want)
			}
		})
	}
}

func TestValidateRejectsAmneziaWGOnNonWireGuard(t *testing.T) {
	o := wireguardWithAmnezia(goodAmnezia())
	o.Protocol = ProtocolVLESS
	err := o.Validate()
	if err == nil || !strings.Contains(err.Error(), "require the wireguard protocol") {
		t.Fatalf("Validate = %v, want wireguard-protocol error", err)
	}
}

func goodAmnezia31() *AmneziaWG {
	a := goodAmnezia()
	a.S1, a.S2, a.S3, a.S4 = 15, 25, 20, 12
	a.H1, a.H2, a.H3, a.H4 = "1", "2", "3", "4"
	a.HeaderProtectionKey = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
	a.ContentPaddingAddition = "10-100"
	a.RekeyAfterTime = "100-140"
	a.RekeyTimeout = "5-10"
	a.RejectAfterTime = "170-190"
	a.KeepaliveTimeout = "20-30"
	a.MaxHandshakeAttempts = "3"
	a.RandomTrailers = true
	a.DisableCookies = true
	return a
}

func TestValidateAcceptsAmneziaWG31(t *testing.T) {
	if err := wireguardWithAmnezia(goodAmnezia31()).Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
}

func TestValidateAcceptsDisabledMagicHeaders(t *testing.T) {
	// H1=1..H4=4 are the per-index "disabled" sentinels from the 3.1 spec,
	// recommended together with Header Protection.
	a := goodAmnezia()
	a.H1, a.H2, a.H3, a.H4 = "1", "2", "3", "4"
	if err := wireguardWithAmnezia(a).Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
}

func TestValidateRejectsBadAmneziaWG31(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(a *AmneziaWG)
		want   string
	}{
		{"key not 32 bytes", func(a *AmneziaWG) { a.HeaderProtectionKey = "AAAA" }, "headerprotectionkey"},
		{"key not decodable", func(a *AmneziaWG) { a.HeaderProtectionKey = "!!!not-a-key!!!" }, "headerprotectionkey"},
		{"key needs s1>=12", func(a *AmneziaWG) { a.S1 = 11 }, "requires s1 >= 12"},
		{"key needs s4>=12", func(a *AmneziaWG) { a.S4 = 0 }, "requires s4 >= 12"},
		{"padding range reversed", func(a *AmneziaWG) { a.ContentPaddingAddition = "100-10" }, "contentpaddingaddition"},
		{"padding over uint16", func(a *AmneziaWG) { a.ContentPaddingAddition = "70000" }, "contentpaddingaddition"},
		{"padding not a range", func(a *AmneziaWG) { a.ContentPaddingAddition = "lots" }, "contentpaddingaddition"},
		{"rekey range reversed", func(a *AmneziaWG) { a.RekeyAfterTime = "140-100" }, "rekeyaftertime"},
		{"keepalive negative", func(a *AmneziaWG) { a.KeepaliveTimeout = "-5" }, "keepalivetimeout"},
		{"wrong magic sentinel", func(a *AmneziaWG) { a.H1 = "2" }, "h1"},
		{"zero magic header", func(a *AmneziaWG) { a.H2 = "0" }, "h2"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a := goodAmnezia31()
			tc.mutate(a)
			err := wireguardWithAmnezia(a).Validate()
			if err == nil {
				t.Fatalf("Validate = nil, want error containing %q", tc.want)
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Validate = %v, want error containing %q", err, tc.want)
			}
		})
	}
}

func TestParseAWGRangeU16(t *testing.T) {
	lo, hi, err := parseAWGRangeU16("120-180")
	if err != nil || lo != 120 || hi != 180 {
		t.Fatalf("parseAWGRangeU16(range) = %d,%d,%v", lo, hi, err)
	}
	lo, hi, err = parseAWGRangeU16("25")
	if err != nil || lo != 25 || hi != 25 {
		t.Fatalf("parseAWGRangeU16(single) = %d,%d,%v", lo, hi, err)
	}
	for _, raw := range []string{"180-120", "65536", "-1", "abc", "1-", ""} {
		if _, _, err := parseAWGRangeU16(raw); err == nil {
			t.Fatalf("parseAWGRangeU16(%q) = nil, want error", raw)
		}
	}
}
func TestParseAmneziaMagic(t *testing.T) {
	lo, hi, err := parseAmneziaMagic("12345")
	if err != nil || lo != 12345 || hi != 12345 {
		t.Fatalf("parseAmneziaMagic(single) = %d,%d,%v", lo, hi, err)
	}
	lo, hi, err = parseAmneziaMagic("100-900")
	if err != nil || lo != 100 || hi != 900 {
		t.Fatalf("parseAmneziaMagic(range) = %d,%d,%v", lo, hi, err)
	}
	if _, _, err = parseAmneziaMagic("900-100"); err == nil {
		t.Fatal("parseAmneziaMagic(reversed) = nil, want error")
	}
	if _, _, err = parseAmneziaMagic("nope"); err == nil {
		t.Fatal("parseAmneziaMagic(garbage) = nil, want error")
	}
}

func TestValidateRejectsPublicExampleParameters(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(a *AmneziaWG)
		want   string
	}{
		{"docs CPS demo", func(a *AmneziaWG) { a.I1 = "<b 0xd100000001><rc 8><t><r 50>" }, "CPS syntax demo"},
		{"canonical QUIC preset", func(a *AmneziaWG) { a.I1 = "<b 0xc700000001><rc 8><t><r 50>" }, "canonical QUIC preset"},
		{"windows docs example", func(a *AmneziaWG) {
			a.Jc, a.Jmin, a.Jmax = 5, 40, 70
			a.S1, a.S2 = 30, 50
			a.H1, a.H2, a.H3, a.H4 = "2155318676", "1459039349", "988890009", "1862976214"
		}, "documentation example"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a := goodAmnezia()
			tc.mutate(a)
			err := wireguardWithAmnezia(a).Validate()
			if err == nil {
				t.Fatalf("Validate = nil, want error containing %q", tc.want)
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Validate = %v, want error containing %q", err, tc.want)
			}
		})
	}
}

func TestValidateAcceptsNonExampleParameters(t *testing.T) {
	// The ban is a tripwire for verbatim public examples, not a uniqueness
	// proof: ordinary generated sets must keep validating.
	if err := wireguardWithAmnezia(goodAmnezia()).Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
	if err := wireguardWithAmnezia(goodAmnezia31()).Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
}

func TestValidateAcceptsMasquerade(t *testing.T) {
	for _, tc := range []struct {
		name                   string
		proto, domain, browser string
	}{
		{"quic chrome", "quic", "www.google.com", "chrome"},
		{"quic no browser", "quic", "example.com", ""},
		{"dns with domain", "dns", "example.com", ""},
		{"dns pseudo domain", "dns", "", ""},
		{"stun", "stun", "", ""},
		{"sip", "sip", "", ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			a := goodAmnezia()
			a.I1 = ""
			a.MasqueradeProtocol, a.MasqueradeDomain, a.MasqueradeBrowser = tc.proto, tc.domain, tc.browser
			if err := wireguardWithAmnezia(a).Validate(); err != nil {
				t.Fatalf("Validate = %v, want nil", err)
			}
		})
	}
}

func TestValidateRejectsBadMasquerade(t *testing.T) {
	cases := []struct {
		name                   string
		proto, domain, browser string
		i1                     string
		want                   string
	}{
		{"unknown protocol", "ftp", "example.com", "", "", "unknown masquerade protocol"},
		{"id without ip", "", "example.com", "", "", "ip (masquerade protocol) is required"},
		{"ib without ip", "", "", "chrome", "", "ip (masquerade protocol) is required"},
		{"quic without id", "quic", "", "", "", "id (masquerade domain) is required for ip=quic"},
		{"unknown browser", "quic", "example.com", "safari", "", "unknown masquerade browser"},
		{"browser with dns", "dns", "example.com", "chrome", "", "only meaningful with ip=quic"},
		{"experimental browser", "quic", "example.com", "chrome-full", "", "experimental"},
		{"masquerade with i1", "quic", "example.com", "", "<b 0x01>", "conflicts with an explicit i1"},
		{"injection domain", "quic", "exa;mple.com", "", "", "invalid masquerade domain"},
		{"newline domain", "dns", "exa\nmple.com", "", "", "invalid masquerade domain"},
		{"leading hyphen label", "dns", "-example.com", "", "", "leading or trailing hyphen"},
		{"leading dot", "dns", ".example.com", "", "", "leading dot"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a := goodAmnezia()
			a.I1 = tc.i1
			a.MasqueradeProtocol, a.MasqueradeDomain, a.MasqueradeBrowser = tc.proto, tc.domain, tc.browser
			err := wireguardWithAmnezia(a).Validate()
			if err == nil {
				t.Fatalf("Validate = nil, want error containing %q", tc.want)
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Validate = %v, want error containing %q", err, tc.want)
			}
		})
	}
}

func TestValidateAWGCPS(t *testing.T) {
	for _, raw := range []string{
		"<b 0xc000000001><r 64><t>",
		"<b 0xf6ab3267fa><c><b 0xf6ab><t><r 10><wt 10>",
		"<rc 8><rd 5><r 1000>",
		"  <t>  <b 0x00>  ",
	} {
		if err := validateAWGCPS(raw); err != nil {
			t.Errorf("validateAWGCPS(%q) = %v, want nil", raw, err)
		}
	}
	for _, tc := range []struct {
		raw  string
		want string
	}{
		{"<b 0xc000000001", "unclosed"},
		{"<b 0xzz>", "non-hex"},
		{"<b 0xabc>", "even-sized"},
		{"<b>", "0x-prefixed"},
		{"<r>", "size"},
		{"<r 1001>", "0-1000"},
		{"<r -5>", "0-1000"},
		{"<t 5>", "no arguments"},
		{"plain text", "outside"},
		{"<>", "empty"},
	} {
		if err := validateAWGCPS(tc.raw); err == nil {
			t.Errorf("validateAWGCPS(%q) = nil, want error containing %q", tc.raw, tc.want)
		} else if !strings.Contains(err.Error(), tc.want) {
			t.Errorf("validateAWGCPS(%q) = %v, want error containing %q", tc.raw, err, tc.want)
		}
	}
}

func TestValidateRejectsBadCPSInPlan(t *testing.T) {
	a := goodAmnezia()
	a.I2 = "<r 99999>"
	if err := wireguardWithAmnezia(a).Validate(); err == nil {
		t.Fatal("Validate = nil, want CPS error")
	} else if !strings.Contains(err.Error(), "i2") {
		t.Fatalf("Validate = %v, want error naming i2", err)
	}
}

// TestValidateRejectsLanSharingWithoutALogin locks C7 defense in depth:
// AllowLAN binds the local proxy on every interface, so a plan that asks
// for it with the listener enabled must carry a full login — whoever
// built the plan, not only plans arriving through the control layer.
func TestValidateRejectsLanSharingWithoutALogin(t *testing.T) {
	plan := validPlan()
	plan.Options.AllowLAN = true
	plan.LocalProxy = LocalProxy{Enabled: true}
	if err := plan.Validate(); err == nil || !strings.Contains(err.Error(), "local network") {
		t.Fatalf("LAN sharing without a login must be refused, got %v", err)
	}
	plan.LocalProxy = LocalProxy{Enabled: true, Username: "sora", Password: "lan-sharing-password"}
	if err := plan.Validate(); err != nil {
		t.Fatalf("LAN sharing with a login must validate: %v", err)
	}
	// Loopback-only plans are untouched by the gate: no login is fine
	// while AllowLAN stays off, and AllowLAN alone opens nothing while
	// the listener itself is disabled.
	plan.Options.AllowLAN = false
	plan.LocalProxy = LocalProxy{Enabled: true}
	if err := plan.Validate(); err != nil {
		t.Fatalf("a loopback listener without a login must validate: %v", err)
	}
	plan.Options.AllowLAN = true
	plan.LocalProxy = LocalProxy{}
	if err := plan.Validate(); err != nil {
		t.Fatalf("AllowLAN with no listener must validate: %v", err)
	}
}

func TestValidateEarlyData(t *testing.T) {
	ws := func() Outbound {
		o := wireguardWithAmnezia(nil)
		o.Protocol = ProtocolVLESS
		o.UUID = "11111111-1111-1111-1111-111111111111"
		return o
	}
	o := ws()
	o.Transport = Transport{Type: "ws", Path: "/ws", EarlyData: 2048}
	if err := o.Validate(); err != nil {
		t.Fatalf("Validate = %v, want nil", err)
	}
	o.Transport.EarlyData = -1
	if err := o.Validate(); err == nil {
		t.Fatal("Validate = nil, want negative early-data error")
	}
	o.Transport = Transport{Type: "grpc", Service: "s", EarlyData: 2048}
	if err := o.Validate(); err == nil {
		t.Fatal("Validate = nil, want non-ws early-data error")
	} else if !strings.Contains(err.Error(), "early data needs the ws transport") {
		t.Fatalf("Validate = %v, want ws-transport error", err)
	}
}

func TestOutboundSecretsIncludeHeaderProtectionKey(t *testing.T) {
	o := wireguardWithAmnezia(goodAmnezia31())
	key := goodAmnezia31().HeaderProtectionKey
	found := false
	for _, s := range o.Secrets() {
		if s == key {
			found = true
		}
	}
	if !found {
		t.Fatal("Secrets() does not include the header protection key")
	}
}

func TestUsesAWG31AndMasquerade(t *testing.T) {
	if (&AmneziaWG{}).UsesAWG31() {
		t.Fatal("empty AmneziaWG must not need AWG 3.x")
	}
	if !goodAmnezia31().UsesAWG31() {
		t.Fatal("3.1 parameters must need AWG 3.x")
	}
	a := goodAmnezia31()
	a.ContentPaddingAddition = "0-0"
	a.RekeyAfterTime, a.RekeyTimeout = "", ""
	a.RejectAfterTime, a.KeepaliveTimeout = "", ""
	a.MaxHandshakeAttempts = ""
	a.HeaderProtectionKey = ""
	a.RandomTrailers, a.DisableCookies = false, false
	if a.UsesAWG31() {
		t.Fatal("\"0-0\"/empty ranges must not need AWG 3.x")
	}
	if (&AmneziaWG{}).UsesMasquerade() {
		t.Fatal("empty AmneziaWG must not use masquerade")
	}
	m := &AmneziaWG{MasqueradeProtocol: "dns"}
	if !m.UsesMasquerade() {
		t.Fatal("masquerade protocol must be detected")
	}
}
