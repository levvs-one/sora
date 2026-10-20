package engine

import "testing"

// TestValidateRealityEffectiveSNI pins CENSOR-SURV review Medium 1:
// ValidateReality must validate the EFFECTIVE SNI (realityDest —
// ServerName, else Server), because with an empty ServerName every
// engine puts Server on the wire as the SNI. The reviewer's vector
// (Server="my_site.example.com", SNI="") passed validation before
// this fix while RealityWarnings already named the dest malformed.
func TestValidateRealityEffectiveSNI(t *testing.T) {
	cases := []struct {
		name    string
		server  string
		sni     string
		wantErr bool
	}{
		{"reviewer vector: malformed server, empty SNI", "my_site.example.com", "", true},
		{"malformed explicit SNI still blocked", "203.0.113.7", "my_site.example.com", true},
		{"quasi-IP explicit SNI blocked", "203.0.113.7", "123.456.78", true},
		{"quasi-IP server fallback blocked", "123.456.78", "", true},
		{"valid server domain fallback passes", "edge.provider.net", "", false},
		{"IP server fallback stays a warning, not a block", "203.0.113.7", "", false},
		{"IP literal SNI stays a warning, not a block", "203.0.113.7", "198.51.100.9", false},
		{"valid U-label IDN SNI is not hard-blocked", "203.0.113.7", "bücher.example.de", false},
		{"valid U-label IDN server fallback is not hard-blocked", "bücher.example.de", "", false},
		{"punycode SNI passes", "203.0.113.7", "xn--bcher-kva.example.de", false},
		{"ordinary dest passes", "203.0.113.7", "www.microsoft.com", false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			o := realityOutbound()
			o.Server = tc.server
			o.TLS.ServerName = tc.sni
			err := o.ValidateReality()
			if tc.wantErr && err == nil {
				t.Fatalf("ValidateReality(server=%q sni=%q) = nil, want an error", tc.server, tc.sni)
			}
			if !tc.wantErr && err != nil {
				t.Fatalf("ValidateReality(server=%q sni=%q) = %v, want nil", tc.server, tc.sni, err)
			}
		})
	}
}

// TestRealityHygieneCoverageGaps pins the coverage gaps from
// CENSOR-SURV review §1: sni-is-server for parent/subdomain pairs,
// the home.arpa/.onion/.localdomain not-public suffixes, quasi-IP
// dests, U-label IDN (no malformed flag), and the widened
// low-entropy shortId patterns — with no false positives on the
// legitimate CDN dests the review used.
func TestRealityHygieneCoverageGaps(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(*Outbound)
		want   string // code that must fire; "" = the hygiene family must stay silent
	}{
		{"sni is subdomain of server", func(o *Outbound) { o.Server = "example.com"; o.TLS.ServerName = "cdn.example.com" }, "reality-sni-is-server"},
		{"server is subdomain of sni", func(o *Outbound) { o.Server = "vpn.example.com"; o.TLS.ServerName = "www.example.com" }, "reality-sni-is-server"},
		{"server is parent of sni", func(o *Outbound) { o.Server = "example.com"; o.TLS.ServerName = "www.example.com" }, "reality-sni-is-server"},
		{"sni equals server", func(o *Outbound) { o.Server = "cdn.example.com"; o.TLS.ServerName = "cdn.example.com" }, "reality-sni-is-server"},
		{"same registrable domain under co.uk", func(o *Outbound) { o.Server = "vpn.example.co.uk"; o.TLS.ServerName = "cdn.example.co.uk" }, "reality-sni-is-server"},
		{"idn parent/subdomain pair", func(o *Outbound) { o.Server = "vpn.bücher.example.de"; o.TLS.ServerName = "www.bücher.example.de" }, "reality-sni-is-server"},
		{"unrelated registrable domains stay silent", func(o *Outbound) { o.Server = "edge.provider.net"; o.TLS.ServerName = "www.example.com" }, ""},
		{"different co.uk owners stay silent", func(o *Outbound) { o.Server = "vpn.one.co.uk"; o.TLS.ServerName = "cdn.two.co.uk" }, ""},
		{"home.arpa dest is not public", func(o *Outbound) { o.TLS.ServerName = "router.home.arpa" }, "reality-dest-not-public"},
		{"bare home.arpa is not public", func(o *Outbound) { o.TLS.ServerName = "home.arpa" }, "reality-dest-not-public"},
		{"onion dest is not public", func(o *Outbound) { o.TLS.ServerName = "abcdef.onion" }, "reality-dest-not-public"},
		{"localdomain dest is not public", func(o *Outbound) { o.TLS.ServerName = "host.localdomain" }, "reality-dest-not-public"},
		{"quasi-IP dest is malformed", func(o *Outbound) { o.TLS.ServerName = "123.456.78" }, "reality-dest-malformed"},
		{"quasi-IP four-part dest is malformed", func(o *Outbound) { o.TLS.ServerName = "999.1.2.3" }, "reality-dest-malformed"},
		{"U-label IDN dest is not malformed", func(o *Outbound) { o.TLS.ServerName = "bücher.example.de" }, ""},
		{"punycode dest stays clean", func(o *Outbound) { o.TLS.ServerName = "xn--bcher-kva.example.de" }, ""},
		{"cdn dest jsdelivr stays clean", func(o *Outbound) { o.TLS.ServerName = "cdn.jsdelivr.net" }, ""},
		{"cdn dest microsoft stays clean", func(o *Outbound) { o.TLS.ServerName = "www.microsoft.com" }, ""},
		{"periodic shortId abcdabcd", func(o *Outbound) { o.TLS.RealityShortID = "abcdabcdabcdabcd" }, "reality-shortid-low-entropy"},
		{"periodic shortId deadbeef repeated", func(o *Outbound) { o.TLS.RealityShortID = "deadbeefdeadbeef" }, "reality-shortid-low-entropy"},
		{"single deadbeef shortId", func(o *Outbound) { o.TLS.RealityShortID = "deadbeef" }, "reality-shortid-low-entropy"},
		{"periodic shortId aabbccdd tiled", func(o *Outbound) { o.TLS.RealityShortID = "aabbccddaabbccdd" }, "reality-shortid-low-entropy"},
		{"real shortId 6 bytes stays clean", func(o *Outbound) { o.TLS.RealityShortID = "6ba85179e30d" }, ""},
		{"real shortId 8 bytes stays clean", func(o *Outbound) { o.TLS.RealityShortID = "6ba85179e30d4fc2" }, ""},
	}
	hygiene := []string{"reality-dest-malformed", "reality-dest-not-public",
		"reality-sni-is-server", "reality-shortid-short", "reality-shortid-low-entropy"}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			o := realityOutbound()
			tc.mutate(&o)
			w := o.RealityWarnings()
			if tc.want == "" {
				for _, c := range hygiene {
					if contains(w, c) {
						t.Fatalf("warning %s must not fire, got %v", c, w)
					}
				}
				return
			}
			if !contains(w, tc.want) {
				t.Fatalf("expected %s, got %v", tc.want, w)
			}
		})
	}
}
