package wgobfusc

import (
	"encoding/base64"
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

func TestReaderError(t *testing.T) {
	bad := &failingReader{}
	if _, err := GenerateWith(bad, PresetQUIC); err == nil {
		t.Fatal("expected error from failing RNG")
	}
}

type failingReader struct{}

func (failingReader) Read([]byte) (int, error) { return 0, io.ErrUnexpectedEOF }
