package diagnostics

import (
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"strconv"
	"strings"
)

// Byte-level ClientHello analysis (CENSOR-FP, "мелочи" standard).
//
// AssessJA4 answers "is this parrot fresh" from the core's own uTLS.
// AnalyzeHello answers the byte questions for ANY captured hello —
// in particular the ones the runtime probe (engine/probeexec) captures
// from the real engine binaries: total length, the padding extension's
// size, where the GREASE values sit, the extension order as written,
// the ALPN list, JA3 and JA4 side by side. Two captures of one claimed
// profile are compared on these facts, so "same profile, different
// hello" is a measured statement, not an impression.

// HelloFacts is the byte-level reading of one captured ClientHello.
type HelloFacts struct {
	// Length is the captured record bytes consumed by the hello.
	Length int
	// JA4 and JA3 fingerprints of the same bytes.
	JA4 string
	JA3 string
	// SNI is the outer server_name (for ECH hellos: the public_name).
	SNI string
	// ALPN in wire order.
	ALPN []string
	// Extensions in wire order, GREASE values included.
	Extensions []uint16
	// Ciphers in wire order, GREASE included.
	Ciphers []uint16
	// Groups is supported_groups (10) in wire order.
	Groups []uint16
	// KeyShareGroups is the key_share (51) group list in wire order.
	KeyShareGroups []uint16
	// SigAlgs is signature_algorithms (13) in wire order.
	SigAlgs []uint16
	// PaddingLen is the padding extension (21) data length in bytes,
	// -1 when the hello carries no padding extension.
	PaddingLen int
	// GREASE positions (indices) inside Ciphers / Extensions / Groups.
	GREASECiphers    []int
	GREASEExtensions []int
	GREASEGroups     []int
	// PQKeyShare: the X25519MLKEM768 hybrid group is among the key shares.
	PQKeyShare bool
	// HasECHExtension: extension 65037 is present. NOTE: every modern
	// parrot sends a GREASE ECH extension, so presence alone proves
	// nothing — real ECH is proven by SNI == the config's public_name.
	HasECHExtension bool
	// Version is the negotiated-max TLS version (JA4's version field).
	Version uint16
}

// AnalyzeHello parses raw captured TLS records (as a listener received
// them) into HelloFacts.
func AnalyzeHello(raw []byte) (HelloFacts, error) {
	h, err := parseCapturedHello(raw)
	if err != nil {
		return HelloFacts{}, err
	}
	f := HelloFacts{
		Length:         len(raw),
		JA4:            ja4Of(h),
		JA3:            ja3Of(h),
		SNI:            h.sni,
		ALPN:           h.alpn,
		Extensions:     h.extensions,
		Ciphers:        h.ciphers,
		Groups:         h.groups,
		KeyShareGroups: h.keyShareGroups,
		SigAlgs:        h.sigAlgs,
		PaddingLen:     h.paddingLen,
		PQKeyShare:     hasPQKeyShare(h),
		Version:        h.version,
	}
	f.GREASECiphers = greasePositions(h.ciphers)
	f.GREASEExtensions = greasePositions(h.extensions)
	f.GREASEGroups = greasePositions(h.groups)
	for _, e := range h.extensions {
		if e == 65037 {
			f.HasECHExtension = true
		}
	}
	return f, nil
}

func greasePositions(v []uint16) []int {
	var out []int
	for i, x := range v {
		if isGREASE(x) {
			out = append(out, i)
		}
	}
	return out
}

// ja3Of computes the classic JA3 string hash: GREASE values are
// stripped, the remaining values are decimal and hyphen-joined in
// wire order, fields comma-separated, md5 of the string. JA3 is
// order-sensitive, so a parrot that permutes extension order (Chrome
// 106+) yields varying JA3 across connections — a known JA3 weakness
// JA4 was designed to fix; both are reported so the variance is
// visible rather than hidden.
func ja3Of(h clientHello) string {
	join := func(v []uint16) string {
		parts := make([]string, 0, len(v))
		for _, x := range v {
			if isGREASE(x) {
				continue
			}
			parts = append(parts, strconv.Itoa(int(x)))
		}
		return strings.Join(parts, "-")
	}
	pf := make([]string, 0, len(h.pointFormats))
	for _, b := range h.pointFormats {
		pf = append(pf, strconv.Itoa(int(b)))
	}
	s := fmt.Sprintf("%d,%s,%s,%s,%s",
		h.legacyVersion, join(h.ciphers), join(h.extensions), join(h.groups), strings.Join(pf, "-"))
	sum := md5.Sum([]byte(s))
	return hex.EncodeToString(sum[:])
}

// SameShape reports whether two captures are the same ClientHello up
// to the fields that legitimately vary per connection: the random,
// the GREASE values, the key-share key bytes, and — for parrots with
// the extension shuffler (Chrome 106+) — the extension ORDER. JA4
// equality is the core of the comparison precisely because JA4 is
// defined to be stable under those variations; the remaining checks
// pin the sets and lists JA4 hashes coarsely.
func SameShape(a, b HelloFacts) bool {
	if a.JA4 != b.JA4 || a.SNI != b.SNI || a.PQKeyShare != b.PQKeyShare {
		return false
	}
	if strings.Join(a.ALPN, ",") != strings.Join(b.ALPN, ",") {
		return false
	}
	return sameSet(stripGREASE(a.KeyShareGroups), stripGREASE(b.KeyShareGroups)) && sameSet(stripGREASE(a.Extensions), stripGREASE(b.Extensions))
}

func stripGREASE(v []uint16) []uint16 {
	out := make([]uint16, 0, len(v))
	for _, x := range v {
		if !isGREASE(x) {
			out = append(out, x)
		}
	}
	return out
}

func sameSet(a, b []uint16) bool {
	if len(a) != len(b) {
		return false
	}
	count := make(map[uint16]int, len(a))
	for _, x := range a {
		count[x]++
	}
	for _, x := range b {
		count[x]--
		if count[x] < 0 {
			return false
		}
	}
	return true
}
