package diagnostics

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"strings"
	"testing"
	"time"

	utls "github.com/refraction-networking/utls"
)

// TestAnalyzeHelloSynthetic pins JA3/JA4 byte semantics on a hello
// built byte by byte in the test: every field of HelloFacts is known
// by construction, so the expectations are computed from the same
// construction — no magic constants copied from anywhere.
func TestAnalyzeHelloSynthetic(t *testing.T) {
	raw := buildHello(t, helloSpec{
		ciphers: []uint16{0x0a0a, 0x1301, 0x1302, 0xc02b},
		extensions: []helloExt{{typ: 0, data: sniData("example.com")},
			{typ: 10, data: u16List(0x11ec, 0x001d)},
			{typ: 11, data: []byte{1, 0}},
			{typ: 16, data: alpnData("h2", "http/1.1")},
			{typ: 21, data: make([]byte, 64)},
			{typ: 43, data: []byte{2, 0x03, 0x04}},
			{typ: 51, data: keyShareData(0x11ec, 0x001d)}},
	})
	f, err := AnalyzeHello(raw)
	if err != nil {
		t.Fatal(err)
	}
	if f.SNI != "example.com" {
		t.Errorf("SNI = %q", f.SNI)
	}
	if f.PaddingLen != 64 {
		t.Errorf("PaddingLen = %d, want 64", f.PaddingLen)
	}
	if len(f.GREASECiphers) != 1 || f.GREASECiphers[0] != 0 {
		t.Errorf("GREASECiphers = %v, want [0]", f.GREASECiphers)
	}
	if !f.PQKeyShare {
		t.Error("key_share carries 0x11ec: PQKeyShare must be true")
	}
	if strings.Join(f.ALPN, ",") != "h2,http/1.1" {
		t.Errorf("ALPN = %v", f.ALPN)
	}
	// JA3 by hand: version 771 (0x0303), GREASE stripped everywhere.
	ja3str := "771,4865-4866-49195,0-10-11-16-21-43-51,4588-29,0"
	sum := md5.Sum([]byte(ja3str))
	if want := hex.EncodeToString(sum[:]); f.JA3 != want {
		t.Errorf("JA3 = %s, want %s (from %q)", f.JA3, want, ja3str)
	}
	if !strings.HasPrefix(f.JA4, "t13d") {
		t.Errorf("JA4 = %q, want a TLS1.3 desktop shape", f.JA4)
	}
}

// TestParrotFreshnessByFact is the watchdog: it measures the linked
// uTLS instead of trusting the review constants. While Auto measures
// as the reviewed reference parrot, the build is fresh; the day a
// uTLS bump moves Auto (or a newer constructible Chrome parrot
// appears whose JA4 is not the reference), this test fires and the
// review constants in engine must move with it (T056).
func TestParrotFreshnessByFact(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	facts, err := EnumerateParrots(ctx)
	if err != nil {
		t.Fatal(err)
	}
	byName := map[string]HelloFacts{}
	for _, p := range facts.Profiles {
		byName[p.Name] = p.Facts
		if p.Facts.JA4 == "" {
			t.Errorf("%s: no JA4 measured", p.Name)
		}
	}
	if !facts.AutoMatchesReference {
		t.Errorf("HelloChrome_Auto measures JA4 %s (identity: %q), want the reviewed reference — "+
			"the linked uTLS moved; re-review the parrot constants (engine.CurrentChromeParrot/ReferenceChromeJA4)",
			facts.AutoJA4, facts.AutoIs)
	}
	if facts.AutoIs != "HelloChrome_155" {
		t.Errorf("Auto identity by measurement = %q, want HelloChrome_155", facts.AutoIs)
	}
	// The PQ boundary across the enumerated Chrome line, by capture:
	// 120 predates hybrid key shares in Chrome parrots; 131+ carry it.
	if byName["HelloChrome_120"].PQKeyShare {
		t.Error("HelloChrome_120 measured WITH a PQ key share; Chrome 120 parrots predate it")
	}
	for _, n := range []string{"HelloChrome_131", "HelloChrome_133", "HelloChrome_155"} {
		if !byName[n].PQKeyShare {
			t.Errorf("%s measured WITHOUT a PQ key share; Chrome 131+ parrots carry X25519MLKEM768", n)
		}
	}
	// Determinism of shape: two captures of the same parrot must be
	// the same hello up to per-connection variance (random, GREASE,
	// key bytes, extension permutation) — SameShape encodes exactly
	// that allowance and nothing more.
	raw1, err := captureHello(ctx, utls.HelloChrome_155, ja4CanarySNI, []string{"h2"}, 5*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	raw2, err := captureHello(ctx, utls.HelloChrome_155, ja4CanarySNI, []string{"h2"}, 5*time.Second)
	if err != nil {
		t.Fatal(err)
	}
	f1, err := AnalyzeHello(raw1)
	if err != nil {
		t.Fatal(err)
	}
	f2, err := AnalyzeHello(raw2)
	if err != nil {
		t.Fatal(err)
	}
	if !SameShape(f1, f2) {
		t.Errorf("two HelloChrome_155 captures differ in shape:\n %+v\n %+v", f1, f2)
	}
	// Byte honesty: the two captures are NOT byte-identical (random
	// and key shares differ by construction) — if they ever are, the
	// capture path is replaying, not measuring.
	if string(raw1) == string(raw2) {
		t.Error("two captures are byte-identical: the capture path must be replaying a fixture")
	}
}
