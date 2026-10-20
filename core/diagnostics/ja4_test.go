package diagnostics

import (
	"context"
	"testing"
	"time"

	utls "github.com/refraction-networking/utls"
)

// captureForTest runs the real ClientHello capture for one uTLS parrot.
func captureForTest(t *testing.T, id utls.ClientHelloID) []byte {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	raw, err := captureHello(ctx, id, ja4CanarySNI, []string{"h2"}, 10*time.Second)
	if err != nil {
		t.Fatalf("captureHello: %v", err)
	}
	if len(raw) == 0 {
		t.Fatal("captureHello returned no bytes")
	}
	return raw
}

// TestJA4PQKeyShare pins the post-quantum key share boundary: Chrome 133
// (and everything newer) must offer X25519MLKEM768, Chrome 120 must not.
// This is the regression guard for "mandatory PQ key share" (T001): if a
// future uTLS bump ever drops the hybrid key share from the auto parrot,
// this fails.
func TestJA4PQKeyShare(t *testing.T) {
	for id, want := range map[utls.ClientHelloID]bool{
		utls.HelloChrome_133: true,
		utls.HelloChrome_131: true,
		utls.HelloChrome_120: false,
	} {
		raw := captureForTest(t, id)
		h, err := parseCapturedHello(raw)
		if err != nil {
			t.Fatalf("parseCapturedHello: %v", err)
		}
		if got := hasPQKeyShare(h); got != want {
			t.Errorf("hasPQKeyShare(%s) = %v, want %v (groups: %x)", id.Client, got, want, h.keyShareGroups)
		}
	}
}

// TestCoreUTLSFreshnessGate is the CI JA4 self-test for T001: the core's
// own vendored uTLS (used for probing, DoH, subscription fetch) must emit
// a ClientHello whose JA4 matches the documented current Chrome parrot.
// It FAILS while the vendored utls predates HelloChrome_155 — that failure
// is the signal to bump github.com/refraction-networking/utls.
//
// When upstream uTLS adds a newer verified parrot (e.g. HelloChrome_156),
// update the reference below AND engine.CurrentChromeParrot together;
// the failure is the freshness-monitoring process working as intended.
func TestCoreUTLSFreshnessGate(t *testing.T) {
	rep := AssessJA4(context.Background(), JA4Input{Fingerprint: "chrome"})
	if rep.JA4 == "" {
		t.Fatalf("no JA4 captured: %s", rep.Detail)
	}
	const wantJA4 = "t13d1517h2_8daaf6152771_cb7bf5808d99" // real Chrome 155
	if rep.JA4 != wantJA4 {
		t.Errorf("core uTLS freshness gate: JA4 = %q, want current Chrome %q\n%s\nBump github.com/refraction-networking/utls past the HelloChrome_155 commit.",
			rep.JA4, wantJA4, rep.Detail)
	}
	raw := captureForTest(t, utls.HelloChrome_Auto)
	h, err := parseCapturedHello(raw)
	if err != nil {
		t.Fatalf("parseCapturedHello: %v", err)
	}
	if !hasPQKeyShare(h) {
		t.Error("HelloChrome_Auto does not offer X25519MLKEM768: PQ key share regressed")
	}
}

// TestParseCapturedHelloNegative pins failure modes beyond the truncated
// cases: wrong handshake type, non-ClientHello first message, and body
// overruns must error, never panic or misparse.
func TestParseCapturedHelloNegative(t *testing.T) {
	for name, raw := range map[string][]byte{
		"not handshake":   {21, 3, 3, 0, 1, 0},
		"not clienthello": {22, 3, 3, 0, 4, 2, 0, 0, 0},
		"overrun body":    {22, 3, 3, 0, 8, 1, 0, 0, 4, 3, 3},
	} {
		if _, err := parseCapturedHello(raw); err == nil {
			t.Errorf("parseCapturedHello(%s) = nil error, want failure", name)
		}
	}
}
