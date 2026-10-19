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

// Fixed wire vectors shared with the Dart side (see F9-SYNC-CONTRACT.md).
// The key material is the byte sequence 0..31 / 0..15, base64url without
// padding; these strings must decode byte-for-byte identically in Dart.
const (
	vectorPub32 = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8" // bytes 0..31
	vectorTok16 = "AAECAwQFBgcICQoLDA0ODw"                      // bytes 0..15
	vectorPub31 = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHg"  // bytes 0..30
	vectorTok15 = "AAECAwQFBgcICQoLDA0O"                        // bytes 0..14
)

// vectorT1 is the canonical positive payload, in the exact form Encode
// produces (query keys sorted by url.Values.Encode).
const vectorT1 = "sora-sync://pair?id=device-a&port=12345&pub=" + vectorPub32 +
	"&token=" + vectorTok16 + "&v=1"

func TestVectorT1Decodes(t *testing.T) {
	in, err := Decode(vectorT1)
	if err != nil {
		t.Fatalf("T1 must decode: %v", err)
	}
	if in.Version != 1 || in.DeviceID != "device-a" || in.Port != 12345 {
		t.Fatalf("T1 fields wrong: %+v", in)
	}
	for i := 0; i < 32; i++ {
		if in.PublicKey[i] != byte(i) {
			t.Fatalf("T1 pub byte %d: got %d, want %d", i, in.PublicKey[i], i)
		}
	}
	for i := 0; i < 16; i++ {
		if in.Token[i] != byte(i) {
			t.Fatalf("T1 token byte %d: got %d, want %d", i, in.Token[i], i)
		}
	}
	// Re-encoding the decoded invitation reproduces T1 exactly.
	if enc := in.Encode(); enc != vectorT1 {
		t.Fatalf("re-encode mismatch:\n got %q\nwant %q", enc, vectorT1)
	}
}

func TestVectorsReject(t *testing.T) {
	base := "sora-sync://pair?id=device-a&port=12345&pub=" + vectorPub32 +
		"&token=" + vectorTok16 + "&v=1"
	cases := map[string]string{
		"wrong scheme": "http://pair?id=device-a&port=12345&pub=" + vectorPub32 +
			"&token=" + vectorTok16 + "&v=1",
		"wrong host": "sora-sync://join?id=device-a&port=12345&pub=" + vectorPub32 +
			"&token=" + vectorTok16 + "&v=1",
		"v=2": "sora-sync://pair?id=device-a&port=12345&pub=" + vectorPub32 +
			"&token=" + vectorTok16 + "&v=2",
		"missing v": "sora-sync://pair?id=device-a&port=12345&pub=" + vectorPub32 +
			"&token=" + vectorTok16,
		"pub 31 bytes": "sora-sync://pair?id=device-a&port=12345&pub=" + vectorPub31 +
			"&token=" + vectorTok16 + "&v=1",
		"pub not base64": "sora-sync://pair?id=device-a&port=12345&pub=!!!not-base64!!!&token=" +
			vectorTok16 + "&v=1",
		"token 15 bytes": "sora-sync://pair?id=device-a&port=12345&pub=" + vectorPub32 +
			"&token=" + vectorTok15 + "&v=1",
		"token with padding": "sora-sync://pair?id=device-a&port=12345&pub=" + vectorPub32 +
			"&token=AAECAwQFBgcICQoLDA0ODw==&v=1",
		"port 0": "sora-sync://pair?id=device-a&port=0&pub=" + vectorPub32 +
			"&token=" + vectorTok16 + "&v=1",
		"port 65536": "sora-sync://pair?id=device-a&port=65536&pub=" + vectorPub32 +
			"&token=" + vectorTok16 + "&v=1",
		"port not a number": "sora-sync://pair?id=device-a&port=abc&pub=" + vectorPub32 +
			"&token=" + vectorTok16 + "&v=1",
		"empty id": "sora-sync://pair?id=&port=12345&pub=" + vectorPub32 +
			"&token=" + vectorTok16 + "&v=1",
		"missing id": "sora-sync://pair?port=12345&pub=" + vectorPub32 +
			"&token=" + vectorTok16 + "&v=1",
	}
	for name, payload := range cases {
		if _, err := Decode(payload); err == nil {
			t.Errorf("%s: payload %q must be rejected", name, payload)
		}
	}
	if _, err := Decode(base); err != nil {
		t.Fatalf("base vector must decode: %v", err)
	}
}
