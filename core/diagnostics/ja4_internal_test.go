package diagnostics

import (
	"context"
	"strings"
	"testing"
	"time"

	utls "github.com/refraction-networking/utls"
)

// TestJA4_ChromeCaptureMatchesDocumented is the end-to-end proof that the
// capture → parse → hash chain is correct: the real ClientHello of the
// explicit "chrome 133" parrot must hash to the JA4 documented in
// core/engine/fingerprint.go, byte for byte. The explicit parrot (not
// Auto) keeps this proof stable across uTLS bumps.
func TestJA4_ChromeCaptureMatchesDocumented(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	raw, err := captureHello(ctx, utls.HelloChrome_133, "example.com", []string{"h2"}, 5*time.Second)
	if err != nil {
		t.Fatalf("capture failed: %v", err)
	}
	hello, err := parseCapturedHello(raw)
	if err != nil {
		t.Fatalf("parse failed: %v", err)
	}
	const want = "t13d1516h2_8daaf6152771_d8a2da3f94cd"
	if got := ja4Of(hello); got != want {
		t.Errorf("JA4 = %q, want documented %q", got, want)
	}
}

// TestCapturedHello_PQKeyShare is the S8 wire audit made executable: the
// pinned uTLS must really emit the X25519MLKEM768 hybrid key share everywhere
// sora promises a modern browser fingerprint. The pre-PQ Chrome 120 parrot
// is the negative control: it must NOT have the share, proving the parser
// discriminates instead of always answering true.
func TestCapturedHello_PQKeyShare(t *testing.T) {
	withPQ := map[string]utls.ClientHelloID{
		"HelloChrome_Auto":  utls.HelloChrome_Auto,
		"HelloChrome_131":   utls.HelloChrome_131,
		"HelloChrome_155":   utls.HelloChrome_155,
		"HelloFirefox_Auto": utls.HelloFirefox_Auto,
		"HelloSafari_Auto":  utls.HelloSafari_Auto,
	}
	for name, id := range withPQ {
		raw := mustCapture(t, id)
		hello, err := parseCapturedHello(raw)
		if err != nil {
			t.Fatalf("%s: parse failed: %v", name, err)
		}
		if !hasPQKeyShare(hello) {
			t.Errorf("%s: ClientHello has no X25519MLKEM768 key share (groups=%#v); "+
				"a modern-browser fingerprint without PQ is a DPI-visible contradiction", name, hello.keyShareGroups)
		}
	}
	raw := mustCapture(t, utls.HelloChrome_120)
	hello, err := parseCapturedHello(raw)
	if err != nil {
		t.Fatalf("HelloChrome_120: parse failed: %v", err)
	}
	if hasPQKeyShare(hello) {
		t.Errorf("HelloChrome_120: unexpected X25519MLKEM768 key share (groups=%#v); "+
			"the negative control must stay negative", hello.keyShareGroups)
	}
}

func mustCapture(t *testing.T, id utls.ClientHelloID) []byte {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	raw, err := captureHello(ctx, id, "example.com", []string{"h2"}, 5*time.Second)
	if err != nil {
		t.Fatalf("capture failed: %v", err)
	}
	return raw
}

// TestAssessJA4_MissingPQKeyShareNotFresh locks the S8 detect-signal: a
// captured hello without the hybrid share (here a real pre-PQ Chrome 120
// capture) must not be reported fresh, and the detail must name the
// missing X25519MLKEM768 share.
func TestAssessJA4_MissingPQKeyShareNotFresh(t *testing.T) {
	raw := mustCapture(t, utls.HelloChrome_120)
	rep := AssessJA4(context.Background(), JA4Input{
		Fingerprint: "chrome",
		Hello: func(context.Context) ([]byte, error) {
			return raw, nil
		},
	})
	if rep.Fresh {
		t.Errorf("pre-PQ hello must not be fresh, got %+v", rep)
	}
	if !strings.Contains(rep.Detail, "X25519MLKEM768") {
		t.Errorf("detail must name the missing PQ key share, got %q", rep.Detail)
	}
}

// TestAssessJA4_PQShareCountsAsFresh is the positive end of the S8
// detect-signal: a hello that offers the hybrid share but matches no
// documented JA4 (here a real Chrome 131 capture, on the unknown-JA4 path)
// must be reported fresh, with the detail confirming the PQ share.
// Chrome 131 is chosen deliberately: its JA4 is in neither the stale nor
// the known-good set, so this exercises the path the Fresh flip changed.
func TestAssessJA4_PQShareCountsAsFresh(t *testing.T) {
	raw := mustCapture(t, utls.HelloChrome_131)
	rep := AssessJA4(context.Background(), JA4Input{
		Fingerprint: "chrome",
		Hello: func(context.Context) ([]byte, error) {
			return raw, nil
		},
	})
	if !rep.Fresh {
		t.Errorf("hello offering the PQ key share must be fresh, got %+v", rep)
	}
	if !strings.Contains(rep.Detail, "offers X25519MLKEM768 PQ key share") {
		t.Errorf("detail must confirm the PQ key share, got %q", rep.Detail)
	}
}

// Chrome 133 capture must be judged stale even though the default chrome
// parrot is fresh after the utls bump. The 133 vector is injected so the
// test does not depend on the vendored Auto parrot.
func TestAssessJA4_StaleParrotFlagged(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	raw, err := captureHello(ctx, utls.HelloChrome_133, "example.com", []string{"h2"}, 5*time.Second)
	if err != nil {
		t.Fatalf("capture failed: %v", err)
	}
	rep := AssessJA4(context.Background(), JA4Input{
		Fingerprint: "chrome",
		Hello: func(context.Context) ([]byte, error) {
			return raw, nil
		},
	})
	if rep.Fingerprint != "chrome" {
		t.Errorf("Fingerprint = %q", rep.Fingerprint)
	}
	if rep.JA4 == "" {
		t.Fatal("no JA4 captured")
	}
	if rep.Fresh {
		t.Errorf("JA4 %s must be reported stale", rep.JA4)
	}
	if !strings.Contains(strings.ToLower(rep.Detail), "stale") {
		t.Errorf("detail should say stale, got %q", rep.Detail)
	}
}

// TestAssessJA4_RandomizedDistinct uses real parrot hellos as the
// injected captures: three different parrots must yield a fresh verdict.
func TestAssessJA4_RandomizedDistinct(t *testing.T) {
	parrots := []utls.ClientHelloID{utls.HelloChrome_Auto, utls.HelloFirefox_Auto, utls.HelloSafari_Auto}
	i := 0
	in := JA4Input{
		Fingerprint: "randomized",
		Hello: func(ctx context.Context) ([]byte, error) {
			p := parrots[i%len(parrots)]
			i++
			return captureHello(ctx, p, "example.com", []string{"h2"}, 5*time.Second)
		},
	}
	rep := AssessJA4(context.Background(), in)
	if !rep.Fresh {
		t.Errorf("distinct hellos must be fresh: %+v", rep)
	}
	if !strings.Contains(rep.Detail, "3 distinct") {
		t.Errorf("detail should report distinct count, got %q", rep.Detail)
	}
}

// TestAssessJA4_RandomizedBroken locks the negative case: a "randomized"
// profile emitting identical hellos has broken randomization.
func TestAssessJA4_RandomizedBroken(t *testing.T) {
	var once []byte
	in := JA4Input{
		Fingerprint: "randomized",
		Hello: func(ctx context.Context) ([]byte, error) {
			if once == nil {
				var err error
				once, err = captureHello(ctx, utls.HelloChrome_Auto, "example.com", []string{"h2"}, 5*time.Second)
				if err != nil {
					return nil, err
				}
			}
			return once, nil
		},
	}
	rep := AssessJA4(context.Background(), in)
	if rep.Fresh {
		t.Errorf("identical hellos must not be fresh: %+v", rep)
	}
	if !strings.Contains(rep.Detail, "identical") {
		t.Errorf("detail should say identical, got %q", rep.Detail)
	}
}

// TestAssessJA4_RealRandomizedVaries checks the actual randomized parrot:
// consecutive real captures should not all collide. This exercises the
// default capture path for "randomized".
func TestAssessJA4_RealRandomizedVaries(t *testing.T) {
	rep := AssessJA4(context.Background(), JA4Input{Fingerprint: "randomized"})
	t.Logf("JA4=%s fresh=%v detail=%q", rep.JA4, rep.Fresh, rep.Detail)
	if rep.JA4 == "" {
		t.Fatal("no JA4 captured")
	}
	if !rep.Fresh {
		t.Errorf("real randomized captures should vary: %+v", rep)
	}
}

func TestAssessJA4_Disabled(t *testing.T) {
	for _, name := range []string{"", "none"} {
		rep := AssessJA4(context.Background(), JA4Input{Fingerprint: name})
		if rep.JA4 != "" || rep.Fresh {
			t.Errorf("fingerprint %q: expected empty dishonest report, got %+v", name, rep)
		}
		if !strings.Contains(rep.Detail, "disabled") {
			t.Errorf("fingerprint %q: detail should say disabled, got %q", name, rep.Detail)
		}
	}
}

func TestAssessJA4_Unknown(t *testing.T) {
	rep := AssessJA4(context.Background(), JA4Input{Fingerprint: "bogus-parrot"})
	if rep.Fresh || rep.JA4 != "" {
		t.Errorf("unknown fingerprint must not be fresh: %+v", rep)
	}
	if !strings.Contains(rep.Detail, "unknown") {
		t.Errorf("detail should say unknown, got %q", rep.Detail)
	}
}

func TestAssessJA4_CorruptCapture(t *testing.T) {
	in := JA4Input{
		Fingerprint: "chrome",
		Hello:       func(ctx context.Context) ([]byte, error) { return []byte{0x16, 0x03}, nil },
	}
	rep := AssessJA4(context.Background(), in)
	if rep.Fresh || rep.JA4 != "" {
		t.Errorf("corrupt capture must not be fresh: %+v", rep)
	}
}

func TestAssessJA4_CaptureError(t *testing.T) {
	in := JA4Input{
		Fingerprint: "chrome",
		Hello:       func(ctx context.Context) ([]byte, error) { return nil, context.DeadlineExceeded },
	}
	rep := AssessJA4(context.Background(), in)
	if rep.Fresh {
		t.Errorf("failed capture must not be fresh: %+v", rep)
	}
	if !strings.Contains(rep.Detail, "capture failed") {
		t.Errorf("detail should report the failure, got %q", rep.Detail)
	}
}

func TestIsGREASE(t *testing.T) {
	for _, v := range []uint16{0x0a0a, 0x1a1a, 0x2a2a, 0xfafa} {
		if !isGREASE(v) {
			t.Errorf("%04x should be GREASE", v)
		}
	}
	for _, v := range []uint16{0x1301, 0x002f, 0x0000, 0x0a0b} {
		if isGREASE(v) {
			t.Errorf("%04x should not be GREASE", v)
		}
	}
}

func TestParseClientHello_Truncated(t *testing.T) {
	for _, raw := range [][]byte{
		nil,
		{0x16, 0x03, 0x01},
		{0x16, 0x03, 0x01, 0x00, 0x05, 0x01, 0x00, 0x00, 0x01, 0x00}, // claims hello, truncated
	} {
		if _, err := parseCapturedHello(raw); err == nil {
			t.Errorf("expected error for %x", raw)
		}
	}
}
