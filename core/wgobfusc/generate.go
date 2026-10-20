// Random AmneziaWG parameter generation (T012).
//
// Published AmneziaWG configurations are censor-signatured verbatim:
// docs.amnezia.org itself warns its CPS example "is not an example of a
// signature. Do not use it as the value". Every client/server pair must
// therefore run a unique generated set, and the plan validator
// (matchAWGPublicExample) rejects the canonical published examples.
//
// Generate produces such a set: cryptographically random, structurally
// valid (it passes Outbound.Validate), and never one of the banned
// examples. The I1 presets below give the first signature packet the
// shape of QUIC, DNS or SIP traffic; their magic bytes are always drawn
// from the caller's RNG, so a preset is a template, never a fixed value
// a censor could signature.
package wgobfusc

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"io"

	"github.com/levvs-one/sora-client/core/engine"
)

// Preset selects the traffic shape of the first signature packet (I1).
type Preset int

const (
	// PresetQUIC shapes I1 like a QUIC Initial: version, connection ID,
	// packet number, payload.
	PresetQUIC Preset = iota
	// PresetDNS shapes I1 like a DNS query: transaction ID, flags,
	// question section.
	PresetDNS
	// PresetSIP shapes I1 like a SIP request line: method, request URI,
	// version tag.
	PresetSIP
)

// Generate returns a random AmneziaWG 2.0 parameter set from crypto/rand.
// The set passes Outbound.Validate and matches no published example.
// Use Generate31 for the 3.1 mechanisms.
func Generate() (engine.AmneziaWG, error) {
	return generate(rand.Reader, PresetQUIC, false)
}

// Generate31 returns a random parameter set with the AmneziaWG 3.1
// mechanisms enabled (header protection, content padding, randomized
// timings). It needs an engine build with verified 3.1 support; without
// one, plans using these fields fail engine selection instead of
// rendering a silently unobfuscated tunnel.
func Generate31() (engine.AmneziaWG, error) {
	return generate(rand.Reader, PresetQUIC, true)
}

// GenerateWith is Generate over an explicit randomness source, for tests.
func GenerateWith(rng io.Reader, preset Preset) (engine.AmneziaWG, error) {
	return generate(rng, preset, false)
}

// GeneratePreset returns a random parameter set whose I1 carries the
// requested traffic-shape preset, in the 2.0 or the 3.1 variant. It is
// the public form of the preset choice Generate/Generate31 fix to
// QUIC: the UI's preset picker calls this so a DNS or SIP shape the
// user picked is the shape that renders, on every engine that carries
// AWG (the I1..I5 fields are data all AWG renderers emit verbatim).
func GeneratePreset(preset Preset, v31 bool) (engine.AmneziaWG, error) {
	return generate(rand.Reader, preset, v31)
}

func generate(rng io.Reader, preset Preset, v31 bool) (engine.AmneziaWG, error) {
	var a engine.AmneziaWG
	ri := &reader{rng: rng}

	// Junk: 3-8 packets, 50-1200 bytes. Jmin <= Jmax always.
	a.Jc = 3 + ri.n(6)
	a.Jmin = 50 + ri.n(151)
	a.Jmax = a.Jmin + 100 + ri.n(1000)
	if a.Jmax > 1280 {
		a.Jmax = 1280
	}

	// S1..S4: keep S1+56 != S2 so padded init and response packets never
	// collide, and S1..S4 >= 12 for the 3.1 ChaCha20 nonce.
	a.S1 = 50 + ri.n(151)
	a.S2 = 300 + ri.n(301)
	if a.S1+56 == a.S2 {
		a.S2++
	}
	a.S3 = 50 + ri.n(151)
	a.S4 = 15 + ri.n(16)

	// H1..H4: four non-overlapping magic intervals, well inside the
	// allowed range and far from the tiny disabled sentinels (1-4).
	base := int64(100000 + ri.n(900000))
	for i, dst := range []*string{&a.H1, &a.H2, &a.H3, &a.H4} {
		lo := base + int64(i)*50000 + int64(ri.n(10000))
		*dst = fmt.Sprintf("%d-%d", lo, lo+9999)
	}

	// I1..I5: CPS scripts. I1 carries the traffic-shape preset; the rest
	// are random filler scripts.
	i1, err := presetScript(ri, preset)
	if err != nil {
		return a, err
	}
	a.I1 = i1
	for _, dst := range []*string{&a.I2, &a.I3, &a.I4, &a.I5} {
		s, err := fillerScript(ri)
		if err != nil {
			return a, err
		}
		*dst = s
	}

	if v31 {
		key := make([]byte, 32)
		if _, err := io.ReadFull(rng, key); err != nil {
			return a, fmt.Errorf("wgobfusc: %w", err)
		}
		a.HeaderProtectionKey = base64.StdEncoding.EncodeToString(key)
		a.ContentPaddingAddition = fmt.Sprintf("%d-%d", 32+ri.n(64), 128+ri.n(128))
		// Timings: ranges the engine samples per arming, so sessions
		// stop looking repetitive. Values in seconds, sane defaults.
		a.RekeyAfterTime = fmt.Sprintf("%d-%d", 120+ri.n(120), 300+ri.n(300))
		a.RekeyTimeout = fmt.Sprintf("%d-%d", 5+ri.n(5), 10+ri.n(10))
		a.RejectAfterTime = fmt.Sprintf("%d-%d", 300+ri.n(300), 600+ri.n(600))
		a.KeepaliveTimeout = fmt.Sprintf("%d-%d", 10+ri.n(10), 20+ri.n(20))
		a.MaxHandshakeAttempts = fmt.Sprintf("%d-%d", 3+ri.n(3), 8+ri.n(4))
		a.RandomTrailers = true
		a.DisableCookies = ri.n(2) == 0
		// The 3.1 docs recommend S1==S2==S3==S4 alongside random
		// trailers so packet types stay distinguishable; keep them
		// distinct-but-safe instead: the validator only forbids
		// S1+56==S2, which still holds.
	}
	return a, ri.err
}

// presetScript builds the I1 signature packet for a traffic shape. The
// magic bytes are always random: the shape is recognizable, the value is
// not signatureable.
func presetScript(ri *reader, preset Preset) (string, error) {
	magic := func(n int) (string, error) {
		b := make([]byte, n)
		if _, err := io.ReadFull(ri.rng, b); err != nil {
			return "", err
		}
		const hexd = "0123456789abcdef"
		out := make([]byte, 2*n)
		for i, c := range b {
			out[2*i], out[2*i+1] = hexd[c>>4], hexd[c&15]
		}
		return string(out), nil
	}
	r := func(lo, hi int) int { return lo + ri.n(hi-lo+1) }
	switch preset {
	case PresetQUIC, PresetDNS, PresetSIP:
	default:
		// An out-of-range preset silently becoming QUIC would render
		// a different shape than the profile names — fail closed.
		return "", fmt.Errorf("wgobfusc: unknown preset %d", int(preset))
	}
	switch preset {
	case PresetDNS:
		// DNS query: random transaction ID, standard-query flags,
		// one question, then random question bytes.
		id, err := magic(2)
		if err != nil {
			return "", err
		}
		q, err := magic(r(12, 24))
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("<b 0x%s><b 0x0100><b 0x000100000000><b 0x%s><r %d>", id, q, r(16, 48)), nil
	case PresetSIP:
		// SIP request line: "INVITE sip:" + random user/host bytes,
		// then a tag and random filler.
		uri, err := magic(r(8, 16))
		if err != nil {
			return "", err
		}
		// "INVITE sip:" hex-encoded so the CPS <b> tag stays valid.
		return fmt.Sprintf("<b 0x494e56495445207369703a%s><r %d><t>", uri, r(24, 64)), nil
	default: // PresetQUIC
		// QUIC Initial: random version, 8-byte connection ID counter,
		// timestamp, random payload. Never the published 0xc700000001.
		ver, err := magic(4)
		if err != nil {
			return "", err
		}
		if ver == "c700000001"[:8] {
			ver = "d" + ver[1:]
		}
		return fmt.Sprintf("<b 0x%s><rc 8><t><r %d>", ver, r(32, 80)), nil
	}
}

// fillerScript builds a random I2..I5 filler: random bytes, a counter,
// a timestamp, random tail.
func fillerScript(ri *reader) (string, error) {
	b := make([]byte, 4+ri.n(12))
	if _, err := io.ReadFull(ri.rng, b); err != nil {
		return "", err
	}
	const hexd = "0123456789abcdef"
	hex := make([]byte, 2*len(b))
	for i, c := range b {
		hex[2*i], hex[2*i+1] = hexd[c>>4], hexd[c&15]
	}
	return fmt.Sprintf("<b 0x%s><rc %d><t><r %d>", hex, 4+ri.n(8), 16+ri.n(48)), nil
}

// reader is a tiny RNG helper that records the first I/O error.
type reader struct {
	rng io.Reader
	err error
}

func (ri *reader) n(max int) int {
	if ri.err != nil || max <= 0 {
		return 0
	}
	var b [1]byte
	if _, err := io.ReadFull(ri.rng, b[:]); err != nil {
		ri.err = err
		return 0
	}
	return int(b[0]) % max
}
