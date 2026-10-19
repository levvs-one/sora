package pairing

import (
	"strings"
	"testing"
)

// Detail-level strictness of Decode, beyond the vector tests in
// pairing_test.go: the canonical contract (F9-SYNC-CONTRACT.md) forbids
// fragments and duplicate query keys, and tolerates unknown keys.
func TestDecodeRejectsFragmentAndDuplicates(t *testing.T) {
	// Self-contained payloads: base64url of bytes 0..31 / 0..15.
	const (
		pub32 = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8"
		tok16 = "AAECAwQFBgcICQoLDA0ODw"
	)
	base := "sora-sync://pair?id=device-a&port=12345&pub=" + pub32 +
		"&token=" + tok16 + "&v=1"
	for name, payload := range map[string]string{
		"fragment":       base + "#note",
		"fragment empty": base + "#",
		"duplicate pub": "sora-sync://pair?id=device-a&port=12345&pub=" + pub32 +
			"&pub=" + pub32 + "&token=" + tok16 + "&v=1",
		"duplicate token": "sora-sync://pair?id=device-a&port=12345&pub=" + pub32 +
			"&token=" + tok16 + "&token=" + tok16 + "&v=1",
		"duplicate v": base + "&v=1",
		"duplicate id": "sora-sync://pair?id=device-a&id=device-b&port=12345&pub=" +
			pub32 + "&token=" + tok16 + "&v=1",
		"duplicate port": "sora-sync://pair?id=device-a&port=12345&port=12345&pub=" +
			pub32 + "&token=" + tok16 + "&v=1",
	} {
		if _, err := Decode(payload); err == nil {
			t.Errorf("%s: payload %q must be rejected", name, payload)
		} else if !strings.Contains(err.Error(), "fragment") && !strings.Contains(err.Error(), "repeats") {
			t.Errorf("%s: unexpected error %v", name, err)
		}
	}
}

func TestDecodeIgnoresUnknownKeys(t *testing.T) {
	const (
		pub32 = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8"
		tok16 = "AAECAwQFBgcICQoLDA0ODw"
	)
	in, err := Decode("sora-sync://pair?id=device-a&port=12345&pub=" + pub32 +
		"&token=" + tok16 + "&v=1&future_field=1")
	if err != nil {
		t.Fatalf("unknown keys must be ignored: %v", err)
	}
	if in.DeviceID != "device-a" || in.Port != 12345 || in.Version != 1 {
		t.Fatalf("fields corrupted by unknown key: %+v", in)
	}
}
