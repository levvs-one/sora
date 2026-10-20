package engine

import (
	"strings"
	"testing"
)

// testECHList is the CENSOR-FP probe fixture: one ECHConfig with
// public_name "public.example.com", config_id 7, X25519 — the list
// whose wire effect (outer SNI becomes the public_name) was captured
// on all three pinned binaries.
var testECHListLines = strings.Split(testECHListPEM, "\n")

var testECHListB64 = func() string {
	b, _ := ECHConfigListBase64(testECHListLines)
	return b
}()

const testECHListPEM = `-----BEGIN ECH CONFIGS-----
AEX+DQBBBwAgACAAAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHwAEAAEAAQAScHVibGlj
LmV4YW1wbGUuY29tAAA=
-----END ECH CONFIGS-----`

func TestECHConfigListBytesShapes(t *testing.T) {
	// The canonical label, the historical label, bare base64 and a
	// list split across lines all decode to the same bytes.
	want, err := ECHConfigListBytes(testECHListLines)
	if err != nil || len(want) == 0 {
		t.Fatalf("canonical PEM must decode, got %v (%d bytes)", err, len(want))
	}
	historical := strings.ReplaceAll(testECHListPEM, "ECH CONFIGS", "ECHCONFIG")
	if got, err := ECHConfigListBytes(strings.Split(historical, "\n")); err != nil || string(got) != string(want) {
		t.Errorf("historical label = %v / %x, want the same bytes", err, got)
	}
	joined := strings.Join(strings.Split(testECHListPEM, "\n")[1:3], "")
	if got, err := ECHConfigListBytes([]string{joined}); err != nil || string(got) != string(want) {
		t.Errorf("bare base64 = %v / %x, want the same bytes", err, got)
	}
	// No lines at all is "no pin", not an error: callers gate on
	// len(Config) before decoding.
	if got, err := ECHConfigListBytes(nil); err != nil || len(got) != 0 {
		t.Errorf("empty input = %v / %d bytes, want no error and no bytes", err, len(got))
	}
}

func TestECHConfigListBytesRejects(t *testing.T) {
	two := append(append([]string{}, testECHListLines...), testECHListLines...)
	for name, lines := range map[string][]string{
		"armor only":   {"-----BEGIN ECH CONFIGS-----", "-----END ECH CONFIGS-----"},
		"not base64":   {"!!! not a config !!!"},
		"two blocks":   two,
		"begin no end": {"-----BEGIN ECH CONFIGS-----", "QUJD"},
		"end no begin": {"QUJD", "-----END ECH CONFIGS-----"},
	} {
		if _, err := ECHConfigListBytes(lines); err == nil {
			t.Errorf("%s: must be rejected", name)
		}
	}
}

func TestECHConfigPEMCanonical(t *testing.T) {
	// Whatever label the plan arrived with, the canonical PEM uses
	// the label the pinned sing-box binary accepts ("ECH CONFIGS" —
	// the space is load-bearing, probed on lx.22) and round-trips.
	historical := strings.Split(strings.ReplaceAll(testECHListPEM, "ECH CONFIGS", "ECHCONFIG"), "\n")
	lines, err := ECHConfigPEM(historical)
	if err != nil {
		t.Fatal(err)
	}
	if lines[0] != "-----BEGIN ECH CONFIGS-----" || lines[len(lines)-1] != "-----END ECH CONFIGS-----" {
		t.Fatalf("canonical PEM armor = %v", lines)
	}
	back, err := ECHConfigListBytes(lines)
	if err != nil {
		t.Fatal(err)
	}
	want, _ := ECHConfigListBytes(testECHListLines)
	if string(back) != string(want) {
		t.Errorf("round trip changed the list bytes")
	}
	if testECHListB64 == "" {
		t.Error("base64 form must be non-empty")
	}
}
