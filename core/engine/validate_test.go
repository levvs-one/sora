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
