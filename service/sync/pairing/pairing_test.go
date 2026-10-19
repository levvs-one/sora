package pairing

import (
	"strings"
	"testing"
)

func TestInvitationRoundTrip(t *testing.T) {
	in, priv, err := Generate("device-a")
	if err != nil {
		t.Fatal(err)
	}
	var zero [32]byte
	if priv == zero {
		t.Fatal("private key must not be zero")
	}
	in.Port = 41234
	enc := in.Encode()
	if !strings.HasPrefix(enc, "sora-sync://pair?") {
		t.Fatalf("bad scheme: %q", enc)
	}
	// No secret material in the clear: the private key never appears.
	back, err := Decode(enc)
	if err != nil {
		t.Fatal(err)
	}
	if back.DeviceID != "device-a" || back.PublicKey != in.PublicKey || back.Token != in.Token || back.Port != 41234 {
		t.Fatal("invitation did not survive the round trip")
	}
	// Two invitations differ in keys and tokens.
	in2, _, err := Generate("device-a")
	if err != nil {
		t.Fatal(err)
	}
	if in2.PublicKey == in.PublicKey || in2.Token == in.Token {
		t.Fatal("invitations must use fresh randomness")
	}
}

func TestDecodeRejectsGarbage(t *testing.T) {
	for _, s := range []string{
		"",
		"https://example.com/",
		"sora-sync://pair?v=2&id=a&pub=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&token=AAAAAAAAAAAAAAAAAAAAAA",
		"sora-sync://pair?v=1&id=a&pub=short&token=AAAAAAAAAAAAAAAAAAAAAA",
		"sora-sync://pair?v=1&id=a&pub=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&token=short",
		"sora-sync://pair?v=1&pub=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&token=AAAAAAAAAAAAAAAAAAAAAA",
		"sora-sync://pair?v=1&id=a&pub=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&token=AAAAAAAAAAAAAAAAAAAAAA",
		"sora-sync://pair?v=1&id=a&pub=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&token=AAAAAAAAAAAAAAAAAAAAAA&port=0",
		"sora-sync://pair?v=1&id=a&pub=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&token=AAAAAAAAAAAAAAAAAAAAAA&port=99999",
	} {
		if _, err := Decode(s); err == nil {
			t.Errorf("payload %q must be rejected", s)
		}
	}
}

func TestGenerateRejectsEmptyDeviceID(t *testing.T) {
	if _, _, err := Generate("  "); err == nil {
		t.Fatal("empty device id must be rejected")
	}
}
