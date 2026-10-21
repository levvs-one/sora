package engine

import (
	"strings"
	"testing"
)

func olcrtcOutbound() Outbound {
	return Outbound{
		ID: "olc", Name: "olc", Protocol: ProtocolOLCRTC, Server: "room-01",
		Password: strings.Repeat("a", 64),
		Olcrtc:   &OlcrtcConfig{Provider: "jitsi", Transport: "datachannel", Room: "room-01"},
	}
}

func TestOlcrtcOutboundValidates(t *testing.T) {
	if err := olcrtcOutbound().Validate(); err != nil {
		t.Fatalf("valid olcrtc outbound refused: %v", err)
	}
	// A jitsi room is a URL: it is a room, not a host, and must not
	// be judged by the host rules.
	o := olcrtcOutbound()
	o.Server = "https://meet.example.org/myroom"
	o.Olcrtc.Room = o.Server
	o.Olcrtc.Provider = "jitsi"
	if err := o.Validate(); err != nil {
		t.Fatalf("URL room refused: %v", err)
	}
}

func TestOlcrtcOutboundValidationRefusals(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(*Outbound)
	}{
		{"server mode", func(o *Outbound) { o.Olcrtc.Mode = "srv" }},
		{"unknown mode", func(o *Outbound) { o.Olcrtc.Mode = "gen" }},
		{"no config", func(o *Outbound) { o.Olcrtc = nil }},
		{"unknown provider", func(o *Outbound) { o.Olcrtc.Provider = "zoom" }},
		{"unknown transport", func(o *Outbound) { o.Olcrtc.Transport = "smokechannel" }},
		{"missing room", func(o *Outbound) { o.Olcrtc.Room = "" }},
		{"wbstream placeholder room", func(o *Outbound) { o.Olcrtc.Provider, o.Olcrtc.Room = "wbstream", "any" }},
		{"short key", func(o *Outbound) { o.Password = "abc" }},
		{"non-hex key", func(o *Outbound) { o.Password = strings.Repeat("z", 64) }},
		{"udp promised", func(o *Outbound) { o.SOCKSUDP = true }},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			o := olcrtcOutbound()
			tc.mutate(&o)
			if err := o.Validate(); err == nil {
				t.Fatalf("%s: validated, want refusal", tc.name)
			}
		})
	}
	// Provider none needs no room (its refusal is a connection
	// property, applied by the sidecar wrapper, not plan shape).
	o := olcrtcOutbound()
	o.Olcrtc.Provider, o.Olcrtc.Room, o.Server = "none", "", ""
	if err := o.Validate(); err != nil {
		t.Fatalf("provider none shape refused: %v", err)
	}
}

func TestOlcrtcWarningsAreTheHonestV1Labels(t *testing.T) {
	got := olcrtcOutbound().Warnings()
	if len(got) != 2 || got[0] != "olcrtc-tcp-only" || got[1] != "olcrtc-ipv4-only" {
		t.Fatalf("warnings = %v, want [olcrtc-tcp-only olcrtc-ipv4-only]", got)
	}
	if w := (Outbound{Protocol: ProtocolDirect}).Warnings(); len(w) != 0 {
		t.Fatalf("direct warnings = %v", w)
	}
}

func TestOlcrtcSecretsAndIdentifiers(t *testing.T) {
	o := olcrtcOutbound()
	o.Olcrtc.AuthToken = "wbstream-token-1234"
	secrets := strings.Join(o.Secrets(), "\x00")
	if !strings.Contains(secrets, o.Password) || !strings.Contains(secrets, "wbstream-token-1234") {
		t.Fatalf("secrets miss the key or the provider token: %q", secrets)
	}
	if ids := strings.Join(o.Identifiers(), "\x00"); !strings.Contains(ids, "room-01") {
		t.Fatalf("identifiers miss the room: %q", ids)
	}
}
