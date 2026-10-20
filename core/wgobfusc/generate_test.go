package wgobfusc

import (
	"encoding/base64"
	"encoding/hex"
	"io"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// lcg is a deterministic io.Reader for tests.
type lcg struct{ s uint64 }

func (l *lcg) Read(p []byte) (int, error) {
	for i := range p {
		l.s = l.s*6364136223846793005 + 1442695040888963407
		p[i] = byte(l.s >> 33)
	}
	return len(p), nil
}

func validOutbound(a engine.AmneziaWG) engine.Outbound {
	o := enginetest.Outbound(engine.ProtocolWireGuard)
	o.Amnezia = &a
	return o
}

func TestGeneratePassesValidation(t *testing.T) {
	// T012: every generated set must survive the real plan validator,
	// including the published-example tripwire.
	for _, preset := range []Preset{PresetQUIC, PresetDNS, PresetSIP} {
		a, err := GenerateWith(&lcg{s: uint64(preset) + 1}, preset)
		if err != nil {
			t.Fatalf("preset %d: %v", preset, err)
		}
		if err := validOutbound(a).Validate(); err != nil {
			t.Fatalf("preset %d: generated set rejected: %v", preset, err)
		}
		if a.UsesAWG31() {
			t.Fatalf("preset %d: 2.0 set must not claim 3.1", preset)
		}
	}
}

func TestGenerate31PassesValidation(t *testing.T) {
	rng := &lcg{s: 42}
	a, err := GenerateWith(rng, PresetQUIC)
	if err != nil {
		t.Fatal(err)
	}
	// 3.1 via the same deterministic stream.
	a31, err := func() (engine.AmneziaWG, error) {
		return generate(&lcg{s: 43}, PresetDNS, true)
	}()
	if err != nil {
		t.Fatal(err)
	}
	if !a31.UsesAWG31() {
		t.Fatal("3.1 set must report UsesAWG31")
	}
	raw, err := base64.StdEncoding.DecodeString(a31.HeaderProtectionKey)
	if err != nil || len(raw) != 32 {
		t.Fatalf("header protection key must be 32 bytes, got %d (%v)", len(raw), err)
	}
	if err := validOutbound(a31).Validate(); err != nil {
		t.Fatalf("3.1 set rejected: %v", err)
	}
	_ = a
}

func TestGenerateUnique(t *testing.T) {
	// Two runs must never produce the same set: uniqueness is the whole
	// point (published configs are censor-signatured).
	seen := map[string]bool{}
	for i := 0; i < 8; i++ {
		a, err := GenerateWith(&lcg{s: uint64(i) * 7919 + 13}, PresetQUIC)
		if err != nil {
			t.Fatal(err)
		}
		key := a.I1 + "|" + a.H1 + "|" + a.HeaderProtectionKey
		if seen[key] {
			t.Fatal("duplicate parameter set generated")
		}
		seen[key] = true
	}
}

func TestGenerateCryptoRand(t *testing.T) {
	// The public constructors must work on real entropy too.
	if _, err := Generate(); err != nil {
		t.Fatal(err)
	}
	a, err := Generate31()
	if err != nil {
		t.Fatal(err)
	}
	if err := validOutbound(a).Validate(); err != nil {
		t.Fatalf("Generate31 set rejected: %v", err)
	}
}

func TestPresetsDifferInShape(t *testing.T) {
	// The presets must be structurally distinct and none may be the
	// banned verbatim examples.
	seen := map[string]Preset{}
	for _, preset := range []Preset{PresetQUIC, PresetDNS, PresetSIP} {
		a, err := GenerateWith(&lcg{s: 7}, preset)
		if err != nil {
			t.Fatal(err)
		}
		if other, dup := seen[a.I1]; dup {
			t.Fatalf("presets %d and %d produced identical I1", other, preset)
		}
		seen[a.I1] = preset
		// The banned QUIC example must never appear, even as a prefix.
		if strings.Contains(a.I1, "c700000001") {
			t.Fatalf("preset %d emitted the banned example magic", preset)
		}
	}
}

// TestGeneratePresetPublic pins the public preset API and the
// fail-closed preset check (CENSOR-P4): a DNS/SIP shape the caller
// picked is the shape that renders, and an out-of-range preset is an
// error, never a silent QUIC.
func TestGeneratePresetPublic(t *testing.T) {
	for _, preset := range []Preset{PresetQUIC, PresetDNS, PresetSIP} {
		for _, v31 := range []bool{false, true} {
			a, err := GeneratePreset(preset, v31)
			if err != nil {
				t.Fatalf("preset %d v31=%v: %v", preset, v31, err)
			}
			if err := validOutbound(a).Validate(); err != nil {
				t.Fatalf("preset %d v31=%v rejected: %v", preset, v31, err)
			}
			if a.UsesAWG31() != v31 {
				t.Fatalf("preset %d v31=%v: UsesAWG31=%v", preset, v31, a.UsesAWG31())
			}
		}
	}
	if _, err := GenerateWith(&lcg{s: 1}, Preset(99)); err == nil {
		t.Fatal("an unknown preset must fail, not silently become QUIC")
	}
}

// parseCPSForTest decodes a CPS script into (tag, arg) pairs for the
// byte-exactness checks: <b 0xHEX> contributes len(HEX)/2 bytes,
// <r N>/<rc N>/<rd N> contribute N bytes each.
func parseCPSForTest(t *testing.T, script string) [][2]string {
	t.Helper()
	var out [][2]string
	rest := strings.TrimSpace(script)
	for rest != "" {
		end := strings.IndexByte(rest, '>')
		if end < 0 {
			t.Fatalf("unclosed tag in %q", script)
		}
		fields := strings.Fields(rest[1:end])
		arg := ""
		if len(fields) > 1 {
			arg = fields[1]
		}
		out = append(out, [2]string{fields[0], arg})
		rest = strings.TrimSpace(rest[end+1:])
	}
	return out
}

func bBytes(t *testing.T, hexArg string) int {
	t.Helper()
	if !strings.HasPrefix(hexArg, "0x") || len(hexArg[2:])%2 != 0 {
		t.Fatalf("<b> argument %q is not even-sized 0x hex", hexArg)
	}
	return len(hexArg[2:]) / 2
}

// TestPresetShapesByteExact pins "мелочи" §2: on generated values,
// each preset's I1 is byte-exactly the shape its name promises — the
// QUIC version field is exactly 4 bytes with an 8-byte connection-ID
// counter, the DNS preset is txid(2)+flags(2)+counts(6)+question, the
// SIP preset's static bytes decode to the literal request-line prefix
// — and every junk/size parameter lands inside the ranges the
// generator documents (which are exactly the validated ranges, so no
// generated value is ever silently clamped into validity).
func TestPresetShapesByteExact(t *testing.T) {
	for _, tc := range []struct {
		preset Preset
		check  func(t *testing.T, tags [][2]string)
	}{
		{PresetQUIC, func(t *testing.T, tags [][2]string) {
			if len(tags) != 4 || tags[0][0] != "b" || tags[1] != [2]string{"rc", "8"} || tags[2][0] != "t" {
				t.Fatalf("QUIC I1 shape = %v", tags)
			}
			if n := bBytes(t, tags[0][1]); n != 4 {
				t.Fatalf("QUIC version field = %d bytes, want exactly 4", n)
			}
			if tags[0][1] == "0xc700000001" {
				t.Fatal("QUIC preset must never emit the banned published magic")
			}
		}},
		{PresetDNS, func(t *testing.T, tags [][2]string) {
			if len(tags) != 5 {
				t.Fatalf("DNS I1 shape = %v", tags)
			}
			if n := bBytes(t, tags[0][1]); n != 2 {
				t.Fatalf("DNS txid = %d bytes, want 2", n)
			}
			if tags[1] != [2]string{"b", "0x0100"} {
				t.Fatalf("DNS flags = %v, want <b 0x0100>", tags[1])
			}
			if tags[2] != [2]string{"b", "0x000100000000"} {
				t.Fatalf("DNS counts = %v, want QD=1,AN=0,NS=0,AR=0", tags[2])
			}
			if n := bBytes(t, tags[3][1]); n < 12 || n > 24 {
				t.Fatalf("DNS question bytes = %d, want 12-24", n)
			}
		}},
		{PresetSIP, func(t *testing.T, tags [][2]string) {
			if len(tags) != 3 || tags[0][0] != "b" {
				t.Fatalf("SIP I1 shape = %v", tags)
			}
			// The static segment decodes to "INVITE sip:" + 8-16 URI bytes.
			decoded, err := hex.DecodeString(tags[0][1][2:])
			if err != nil {
				t.Fatalf("SIP static bytes do not decode: %v", err)
			}
			if !strings.HasPrefix(string(decoded), "INVITE sip:") {
				t.Fatalf("SIP static bytes = %q, want the INVITE sip: prefix", decoded)
			}
			if len(decoded) < 19 || len(decoded) > 27 {
				t.Fatalf("SIP static segment = %d bytes, want 11+(8..16)", len(decoded))
			}
		}},
	} {
		for seed := uint64(1); seed <= 5; seed++ {
			a, err := GenerateWith(&lcg{s: seed * 104729}, tc.preset)
			if err != nil {
				t.Fatal(err)
			}
			tc.check(t, parseCPSForTest(t, a.I1))
			// Filler I2..I5: <b 4-16B><rc 4-11><t><r 16-63>.
			for _, s := range []string{a.I2, a.I3, a.I4, a.I5} {
				tags := parseCPSForTest(t, s)
				if len(tags) != 4 || tags[0][0] != "b" || tags[1][0] != "rc" || tags[2][0] != "t" || tags[3][0] != "r" {
					t.Fatalf("filler shape = %v", tags)
				}
				if n := bBytes(t, tags[0][1]); n < 4 || n > 15 {
					t.Fatalf("filler static = %d bytes, want 4-15", n)
				}
			}
			// Junk/size parameters: exact generated ranges.
			if a.Jc < 3 || a.Jc > 8 || a.Jmin < 50 || a.Jmin > 200 ||
				a.Jmax < a.Jmin+100 || a.Jmax > 1280 ||
				a.S1 < 50 || a.S1 > 200 || a.S2 < 300 || a.S2 > 600 ||
				a.S3 < 50 || a.S3 > 200 || a.S4 < 15 || a.S4 > 30 {
				t.Fatalf("generated parameters out of their documented ranges: %+v", a)
			}
		}
	}
}

func TestReaderError(t *testing.T) {
	bad := &failingReader{}
	if _, err := GenerateWith(bad, PresetQUIC); err == nil {
		t.Fatal("expected error from failing RNG")
	}
}

type failingReader struct{}

func (failingReader) Read([]byte) (int, error) { return 0, io.ErrUnexpectedEOF }
