package engine

import (
	"strings"
	"testing"
)

// validRealityKey is a 32-byte key in base64url (43 chars).
const validRealityKey = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"

func realityOutbound() Outbound {
	return Outbound{
		ID: "r1", Protocol: ProtocolVLESS, Server: "203.0.113.7", Port: 443,
		TLS: TLS{Reality: true, ServerName: "www.example.com", RealityPublicKey: validRealityKey},
	}
}

func TestRealityWarnings(t *testing.T) {
	t.Run("vless reality without vision warns", func(t *testing.T) {
		w := realityOutbound().RealityWarnings()
		if !contains(w, "reality-without-vision") {
			t.Fatalf("expected reality-without-vision, got %v", w)
		}
	})
	t.Run("vision silences the warning", func(t *testing.T) {
		for _, flow := range []string{"xtls-rprx-vision", "xtls-rprx-vision-udp443"} {
			o := realityOutbound()
			o.Flow = flow
			if w := o.RealityWarnings(); contains(w, "reality-without-vision") {
				t.Fatalf("flow %q must silence the warning, got %v", flow, w)
			}
		}
	})
	t.Run("non-tcp transports are exempt from the vision rule", func(t *testing.T) {
		o := realityOutbound()
		o.Transport.Type = "xhttp"
		if w := o.RealityWarnings(); contains(w, "reality-without-vision") {
			t.Fatalf("xhttp is not the TLS-in-TLS case, got %v", w)
		}
	})
	t.Run("xhttp with vision warns about incompatibility", func(t *testing.T) {
		o := realityOutbound()
		o.Transport.Type = "xhttp"
		o.Flow = "xtls-rprx-vision"
		if w := o.RealityWarnings(); !contains(w, "reality-xhttp-vision") {
			t.Fatalf("expected reality-xhttp-vision, got %v", w)
		}
	})
	t.Run("IP dest is flagged", func(t *testing.T) {
		o := realityOutbound()
		o.TLS.ServerName = "203.0.113.7"
		if w := o.RealityWarnings(); !contains(w, "reality-dest-ip") {
			t.Fatalf("expected reality-dest-ip, got %v", w)
		}
	})
	t.Run("missing dest is flagged", func(t *testing.T) {
		o := realityOutbound()
		o.TLS.ServerName = ""
		o.Server = ""
		if w := o.RealityWarnings(); !contains(w, "reality-dest-missing") {
			t.Fatalf("expected reality-dest-missing, got %v", w)
		}
	})
	t.Run("no reality means no warnings", func(t *testing.T) {
		o := realityOutbound()
		o.TLS.Reality = false
		if w := o.RealityWarnings(); len(w) != 0 {
			t.Fatalf("expected no warnings, got %v", w)
		}
	})
	t.Run("ws transport is flagged", func(t *testing.T) {
		o := realityOutbound()
		o.Transport.Type = "ws"
		if w := o.RealityWarnings(); !contains(w, "reality-ws-transport") {
			t.Fatalf("expected reality-ws-transport, got %v", w)
		}
	})
	t.Run("spiderX is flagged as Xray-only", func(t *testing.T) {
		// PASS3 deep A2: only the Xray renderer honours SpiderX;
		// sing-box has no such field in its client REALITY schema
		// and mihomo's pinned reality-opts has none either, so the
		// loss on those paths must warn, not stay silent.
		o := realityOutbound()
		o.TLS.SpiderX = "/spider"
		if w := o.RealityWarnings(); !contains(w, "reality-spiderx-xray-only") {
			t.Fatalf("expected reality-spiderx-xray-only, got %v", w)
		}
		o.TLS.SpiderX = ""
		if w := o.RealityWarnings(); contains(w, "reality-spiderx-xray-only") {
			t.Fatalf("no SpiderX must not warn, got %v", w)
		}
	})
}

func TestValidateReality(t *testing.T) {
	t.Run("well-formed passes", func(t *testing.T) {
		o := realityOutbound()
		o.TLS.RealityShortID = "abcdef123456"
		if err := o.ValidateReality(); err != nil {
			t.Fatal(err)
		}
	})
	t.Run("missing public key fails", func(t *testing.T) {
		o := realityOutbound()
		o.TLS.RealityPublicKey = ""
		if err := o.ValidateReality(); err == nil {
			t.Fatal("expected error for missing public key")
		}
	})
	t.Run("malformed public key fails", func(t *testing.T) {
		for _, key := range []string{"short", validRealityKey + "!", strings.Repeat("A", 44)} {
			o := realityOutbound()
			o.TLS.RealityPublicKey = key
			if err := o.ValidateReality(); err == nil {
				t.Fatalf("expected error for key %q", key)
			}
		}
	})
	t.Run("malformed shortId fails", func(t *testing.T) {
		for _, id := range []string{"xyz", "abc", strings.Repeat("ab", 9)} {
			o := realityOutbound()
			o.TLS.RealityShortID = id
			if err := o.ValidateReality(); err == nil {
				t.Fatalf("expected error for shortId %q", id)
			}
		}
	})
	t.Run("non-reality is untouched", func(t *testing.T) {
		o := realityOutbound()
		o.TLS.Reality = false
		o.TLS.RealityPublicKey = ""
		if err := o.ValidateReality(); err != nil {
			t.Fatal(err)
		}
	})
	t.Run("Validate surfaces reality errors", func(t *testing.T) {
		o := realityOutbound()
		o.TLS.RealityPublicKey = "bogus"
		if err := o.Validate(); err == nil {
			t.Fatal("expected plan validation to reject a malformed reality key")
		}
	})
	t.Run("Warnings surfaces reality warnings", func(t *testing.T) {
		if w := realityOutbound().Warnings(); !contains(w, "reality-without-vision") {
			t.Fatalf("expected Warnings to include reality-without-vision, got %v", w)
		}
	})
}

func TestRealityMux(t *testing.T) {
	o := realityOutbound()
	if !RealityMux(o, MuxOptions{}) {
		t.Fatal("mux must default on for REALITY")
	}
	if RealityMux(o, MuxOptions{Disabled: true}) {
		t.Fatal("Disabled must turn the default off")
	}
	o.TLS.Reality = false
	if RealityMux(o, MuxOptions{}) {
		t.Fatal("mux default applies to REALITY only")
	}
	if got := MuxConcurrency(MuxOptions{}); got != 8 {
		t.Fatalf("default concurrency should be 8, got %d", got)
	}
	if got := MuxConcurrency(MuxOptions{Concurrency: 16}); got != 16 {
		t.Fatalf("configured concurrency should win, got %d", got)
	}
	if got := MuxConcurrency(MuxOptions{Concurrency: 1000}); got != 128 {
		t.Fatalf("concurrency should clamp at 128, got %d", got)
	}
}

// TestValidateKeyShare pins the plan knob behind PASS3 deep S2:
// only "classical"/"hybrid", and only on a REALITY outbound.
func TestValidateKeyShare(t *testing.T) {
	for _, ks := range []string{"", "classical", "hybrid"} {
		o := realityOutbound()
		o.TLS.KeyShare = ks
		if err := o.Validate(); err != nil {
			t.Errorf("KeyShare %q on REALITY: Validate = %v, want nil", ks, err)
		}
	}
	o := realityOutbound()
	o.TLS.KeyShare = "post-quantum-ish"
	if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "key_share") {
		t.Errorf("unknown KeyShare: Validate = %v, want a key_share error", err)
	}
	o = realityOutbound()
	o.TLS.Reality = false
	o.TLS.KeyShare = "hybrid"
	if err := o.Validate(); err == nil || !strings.Contains(err.Error(), "key_share needs REALITY") {
		t.Errorf("KeyShare without REALITY: Validate = %v, want a key_share error", err)
	}
}

func TestIsVisionFlow(t *testing.T) {
	for _, f := range []string{"xtls-rprx-vision", "xtls-rprx-vision-udp443"} {
		if !IsVisionFlow(f) {
			t.Fatalf("%q should be a vision flow", f)
		}
	}
	for _, f := range []string{"", "none", "xtls-rprx-vision-udp443x"} {
		if IsVisionFlow(f) {
			t.Fatalf("%q should not be a vision flow", f)
		}
	}
}

func contains(ss []string, s string) bool {
	for _, x := range ss {
		if x == s {
			return true
		}
	}
	return false
}

// TestRealityHygieneWarnings pins the [censor] dest/shortId hygiene
// warnings: each fires on its exact shape and stays silent on plausible
// production configs (no false positives on the common shapes).
func TestRealityHygieneWarnings(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(*Outbound)
		want   string // "" means the warning must NOT fire
	}{
		{"malformed dest: port", func(o *Outbound) { o.TLS.ServerName = "example.com:443" }, "reality-dest-malformed"},
		{"malformed dest: underscore", func(o *Outbound) { o.TLS.ServerName = "my_site.example.com" }, "reality-dest-malformed"},
		{"malformed dest: wildcard", func(o *Outbound) { o.TLS.ServerName = "*.example.com" }, "reality-dest-malformed"},
		{"malformed dest: empty label", func(o *Outbound) { o.TLS.ServerName = "example..com" }, "reality-dest-malformed"},
		{"lan dest", func(o *Outbound) { o.TLS.ServerName = "router.lan" }, "reality-dest-not-public"},
		{"single-label dest", func(o *Outbound) { o.TLS.ServerName = "decoy" }, "reality-dest-not-public"},
		{"localhost dest", func(o *Outbound) { o.TLS.ServerName = "localhost" }, "reality-dest-not-public"},
		{"mdns dest", func(o *Outbound) { o.TLS.ServerName = "printer.local" }, "reality-dest-not-public"},
		{"sni equals server name", func(o *Outbound) { o.Server = "cdn.example.com"; o.TLS.ServerName = "CDN.Example.COM." }, "reality-sni-is-server"},
		{"sni differs from server name", func(o *Outbound) { o.Server = "edge.provider.net" }, ""},
		{"short shortId 1 byte", func(o *Outbound) { o.TLS.RealityShortID = "ab" }, "reality-shortid-short"},
		{"short shortId 2 bytes", func(o *Outbound) { o.TLS.RealityShortID = "abcd" }, "reality-shortid-short"},
		{"zero shortId", func(o *Outbound) { o.TLS.RealityShortID = "0000000000000000" }, "reality-shortid-low-entropy"},
		{"repeated-byte shortId", func(o *Outbound) { o.TLS.RealityShortID = "aaaaaaaaaa" }, "reality-shortid-low-entropy"},
		{"real shortId 6 bytes", func(o *Outbound) { o.TLS.RealityShortID = "6ba85179e30d" }, ""},
		{"real shortId 8 bytes", func(o *Outbound) { o.TLS.RealityShortID = "6ba85179e30d4fc2" }, ""},
		{"empty shortId is not flagged", func(o *Outbound) { o.TLS.RealityShortID = "" }, ""},
		{"plausible dest stays clean", func(o *Outbound) { o.TLS.ServerName = "www.microsoft.com" }, ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			o := realityOutbound()
			tc.mutate(&o)
			w := o.RealityWarnings()
			code := tc.want
			if code == "" {
				// The "" cases pin absence of the hygiene family.
				for _, c := range []string{"reality-dest-malformed", "reality-dest-not-public",
					"reality-sni-is-server", "reality-shortid-short", "reality-shortid-low-entropy"} {
					if contains(w, c) {
						t.Fatalf("warning %s must not fire, got %v", c, w)
					}
				}
				return
			}
			if !contains(w, code) {
				t.Fatalf("expected %s, got %v", code, w)
			}
		})
	}
	// A short low-entropy id reports exactly one of the two codes:
	// "00" is short; the low-entropy code is reserved for full-length
	// stock defaults, so the UI never double-counts one defect.
	o := realityOutbound()
	o.TLS.RealityShortID = "00"
	w := o.RealityWarnings()
	if !contains(w, "reality-shortid-short") || contains(w, "reality-shortid-low-entropy") {
		t.Fatalf("short id codes = %v, want only reality-shortid-short", w)
	}
}

func TestValidateRealityDestShape(t *testing.T) {
	for _, sni := range []string{"example.com:443", "https://example.com", "my_site.example.com", "*.example.com", "exa mple.com", "example..com", "-bad.com"} {
		o := realityOutbound()
		o.TLS.ServerName = sni
		if err := o.ValidateReality(); err == nil {
			t.Errorf("SNI %q: expected a validation error", sni)
		}
	}
	for _, sni := range []string{"www.example.com", "example.com.", "a.b.c.d-example.org", "203.0.113.7"} {
		o := realityOutbound()
		o.TLS.ServerName = sni
		if err := o.ValidateReality(); err != nil {
			t.Errorf("SNI %q: unexpected error %v (IP literals and valid names stay warnings, not blocks)", sni, err)
		}
	}
}
