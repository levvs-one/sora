package singbox

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func TestRenderAmneziaWG3(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolWireGuard)
	p.Outbounds[0].Amnezia = enginetest.AmneziaWG3().Amnezia
	cfg := render(t, p)
	var ep map[string]any
	for _, e := range cfg["endpoints"].([]any) {
		m := e.(map[string]any)
		if m["type"] == "wireguard" {
			ep = m
		}
	}
	if ep == nil {
		t.Fatal("no wireguard endpoint rendered")
	}
	key := enginetest.AmneziaWG3().Amnezia.HeaderProtectionKey
	if ep["header_protection_key"] != key {
		t.Fatalf("header_protection_key = %v, want the plan key", ep["header_protection_key"])
	}
	if ep["content_padding_addition"] != "32-96" {
		t.Fatalf("content_padding_addition = %v, want %q", ep["content_padding_addition"], "32-96")
	}
	if ep["rekey_timeout"] != float64(5) {
		t.Fatalf("rekey_timeout = %v (%T), want number 5", ep["rekey_timeout"], ep["rekey_timeout"])
	}
	if ep["rekey_after_time"] != "100-140" {
		t.Fatalf("rekey_after_time = %v, want %q", ep["rekey_after_time"], "100-140")
	}
	if ep["random_trailers"] != true {
		t.Fatalf("random_trailers = %v, want true", ep["random_trailers"])
	}
	if ep["disable_cookies"] != true {
		t.Fatalf("disable_cookies = %v, want true", ep["disable_cookies"])
	}
	if ep["id"] != "www.google.com" || ep["ip"] != "quic" || ep["ib"] != "chrome" {
		t.Fatalf("masquerade id/ip/ib = %v/%v/%v, want www.google.com/quic/chrome", ep["id"], ep["ip"], ep["ib"])
	}
}

// TestAwgRangeShapes pins awgRange's number-vs-string decision for every
// input shape the Atoi-based original distinguished, so the [opt40]
// plain-int fast path (which skips Atoi's error allocation on ranges)
// cannot drift from it: plain and signed ints and int-shaped values with
// surrounding space stay numbers; ranges, junk and overflowing digit
// strings stay strings, verbatim and untrimmed.
func TestAwgRangeShapes(t *testing.T) {
	for _, tc := range []struct {
		raw  string
		want any
	}{
		{"5", 5},
		{"+5", 5},
		{"-5", -5},
		{"007", 7},
		{" 42 ", 42},
		{"32-96", "32-96"},
		{"100-140", "100-140"},
		{" 32-96 ", " 32-96 "},
		{"abc", "abc"},
		{"+", "+"},
		{"-", "-"},
		{"99999999999999999999999999", "99999999999999999999999999"},
	} {
		out := obj{}
		awgRange(out, "k", tc.raw)
		if got := out["k"]; got != tc.want {
			t.Errorf("awgRange(%q) = %v (%T), want %v (%T)", tc.raw, got, got, tc.want, tc.want)
		}
	}
	empty := obj{}
	awgRange(empty, "k", "")
	if _, ok := empty["k"]; ok {
		t.Error("awgRange(\"\") must leave the key unset")
	}
}

func TestRenderWSEarlyData(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Transport = engine.Transport{Type: "ws", Path: "/ws", Host: "example.com", EarlyData: 2048}
	wsTransport := func() map[string]any {
		cfg := render(t, p)
		for _, o := range cfg["outbounds"].([]any) {
			m := o.(map[string]any)
			if m["type"] == "vless" {
				tr, ok := m["transport"].(map[string]any)
				if !ok {
					t.Fatal("vless outbound has no ws transport")
				}
				return tr
			}
		}
		t.Fatal("no vless outbound rendered")
		return nil
	}
	if tr := wsTransport(); tr["max_early_data"] != float64(2048) {
		t.Fatalf("max_early_data = %v, want 2048", tr["max_early_data"])
	}
	p.Outbounds[0].Transport.EarlyData = 0
	if tr := wsTransport(); tr["max_early_data"] != nil {
		t.Fatalf("max_early_data = %v, want absent when disabled", tr["max_early_data"])
	}
}
