package control

// B1-fix regression tests for the independent review of 91e50755.
//
// R1: outboundFromProto erased Transport.Type for WireGuard
// unconditionally, so wireguard/"bogus" (and "ws"/"grpc") silently
// became a valid plan. Only the spellings real producers emit — the
// parser's "udp", the custom path's "" (the "tcp" default) — may be
// normalized; anything else must fail plan building honestly.
//
// R2: customCredentialDocument split a Shadowsocks credential on the
// first colon without checking the prefix is a real cipher, despite
// its own comment, so "my:secret" was stored as method "my" and a
// bare password containing a colon was unrepresentable. The prefix
// counts as a method only when engine's cipher list knows it.

import (
	"encoding/json"
	"testing"

	"github.com/levvs-one/sora-client/core/custom"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func wireGuardPlan(t *testing.T, transport string) error {
	t.Helper()
	spec := &corev1.OutboundSpec{
		Id: "wg1", DisplayName: "WG", Protocol: "wireguard",
		Transport: transport, Security: "none",
		Endpoint: &corev1.Endpoint{Host: "198.51.100.7", Port: 51820},
	}
	plan, err := planFromProto(&corev1.SessionPlan{
		TunnelMode: corev1.TunnelMode_TUNNEL_MODE_SYSTEM,
		Outbounds:  []*corev1.OutboundSpec{spec},
	}, "sess-b1-fix", nil)
	if err != nil {
		return err
	}
	if got := plan.Outbounds[0].Transport.Type; got != "" {
		t.Fatalf("transport %q: built plan carries transport %q, want \"\" (WireGuard has none)", transport, got)
	}
	return plan.Validate()
}

// TestWireGuardTransportNormalizationIsStrict is the R1 probe:
// bogus (and ws/grpc, which are valid transports only for other
// protocols) must fail, while the producer spellings build.
func TestWireGuardTransportNormalizationIsStrict(t *testing.T) {
	for _, transport := range []string{"bogus", "ws", "grpc", "xhttp", "quic"} {
		if err := wireGuardPlan(t, transport); err == nil {
			t.Errorf("wireguard/%q: plan built, want an honest validation failure", transport)
		}
	}
	for _, transport := range []string{"udp", "", "tcp"} {
		if err := wireGuardPlan(t, transport); err != nil {
			t.Errorf("wireguard/%q: plan failed: %v, want it to build with no transport", transport, err)
		}
	}
}

// TestCustomShadowsocksCredentialSplitNeedsKnownCipher is the R2
// probe: an unknown prefix makes the whole string a bare password; a
// known cipher (legacy AEAD, SIP022, a deprecated stream cipher from
// the same engine list) splits into method+password, including the
// empty-password form.
func TestCustomShadowsocksCredentialSplitNeedsKnownCipher(t *testing.T) {
	for _, tc := range []struct {
		name         string
		cred         string
		wantMethod   string
		wantPassword string
	}{
		{"unknown prefix is a bare password", "my:secret", "", "my:secret"},
		{"unknown prefix with more colons", "secret:with:colons", "", "secret:with:colons"},
		{"bare password without colon", "secret", "", "secret"},
		{"legacy aead", "aes-256-gcm:pw", "aes-256-gcm", "pw"},
		{"chacha aead", "chacha20-ietf-poly1305:pw", "chacha20-ietf-poly1305", "pw"},
		{"sip022", "2022-blake3-aes-128-gcm:pw", "2022-blake3-aes-128-gcm", "pw"},
		{"sip022 chacha", "2022-blake3-chacha20-poly1305:pw", "2022-blake3-chacha20-poly1305", "pw"},
		{"stream cipher from the engine list", "aes-256-cfb:pw", "aes-256-cfb", "pw"},
		{"known method with empty password", "aes-256-gcm:", "aes-256-gcm", ""},
		{"password keeps its colons", "aes-256-gcm:p:w", "aes-256-gcm", "p:w"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			doc := customCredentialDocument(custom.ProtocolShadowsocks, []byte(tc.cred))
			if doc == nil {
				t.Fatalf("customCredentialDocument(%q) = nil, want a document", tc.cred)
			}
			var values map[string]string
			if err := json.Unmarshal(doc, &values); err != nil {
				t.Fatalf("document %q does not parse: %v", doc, err)
			}
			if values["method"] != tc.wantMethod || values["password"] != tc.wantPassword {
				t.Fatalf("customCredentialDocument(%q) = method %q password %q, want method %q password %q",
					tc.cred, values["method"], values["password"], tc.wantMethod, tc.wantPassword)
			}
			if tc.wantMethod == "" {
				if _, ok := values["method"]; ok {
					t.Fatalf("customCredentialDocument(%q) carries a method key %q, want a bare password only",
						tc.cred, values["method"])
				}
			}
		})
	}
}
