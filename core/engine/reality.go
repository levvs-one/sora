package engine

import (
	"encoding/base64"
	"fmt"
	"net/netip"
	"strings"

	"golang.org/x/net/idna"
	"golang.org/x/net/publicsuffix"
)

// REALITY hardening: validation and warnings (T002).
//
// The field data is unambiguous: REALITY has no protocol-level detector in
// the wild, but deployments are classified as proxies through four
// mistakes — no vision (TLS-in-TLS, a detectable signal), stale uTLS,
// SNI↔ASN mismatch, shortId leaks. This file turns the client-checkable
// half of that into plan validation and user-facing warnings.
//
// Warnings (RealityWarnings) never block: they surface in the UI next to
// the server, and the UI may additionally offer a hard block for
// reality-without-vision (see the spec). Errors (ValidateReality) block:
// they name configurations that cannot work or that leak identity.
// realityDest is the EFFECTIVE SNI: the value that actually goes on
// the wire as the ClientHello server name. Every renderer passes
// TLS.ServerName verbatim — sing-box's generic TLS block sets
// server_name from it (omitting the key when empty), Xray's
// realitySettings does the same, and mihomo sets sni/servername only
// when it is non-empty — and for an empty ServerName each engine
// falls back to the server address it dials (sing-box spells that
// fallback explicitly on the naive path: orDefault(ServerName,
// Server); mihomo's adapter comment in proxy.go records the same
// dial-address fallback). So the effective SNI is ServerName when
// set, otherwise Server, and any check that means "the name the
// censor will see" must validate this value, not ServerName alone
// (CENSOR-SURV review, Medium 1).
func (o Outbound) realityDest() string {
	if o.TLS.ServerName != "" {
		return o.TLS.ServerName
	}
	return o.Server
}

// IsVisionFlow reports whether flow is an XTLS vision variant. Vision
// changes what the censor can see inside the TLS stream, so several
// REALITY rules key off it.
func IsVisionFlow(flow string) bool {
	return flow == "xtls-rprx-vision" || flow == "xtls-rprx-vision-udp443"
}

// DefaultSpiderX is the spider path every renderer falls back to
// when the plan carries no SpiderX: the documented safe default of
// the one engine that spells the field (Xray). One constant, so the
// main stream leg and the XHTTP download leg can never drift to
// different defaults (CENSOR-P1).
const DefaultSpiderX = "/"

// RealityWarnings returns human-readable warning codes for a REALITY
// outbound. Empty means nothing to warn about. The codes are stable UI
// contract: the app maps each to a localized message.
func (o Outbound) RealityWarnings() []string {
	if !o.TLS.Reality {
		return nil
	}
	var out []string
	transport := o.Transport.Type
	tcpish := transport == "" || transport == "tcp"
	if o.Protocol == ProtocolVLESS && tcpish && !IsVisionFlow(o.Flow) {
		// Without vision the inner TLS handshake is visible inside the
		// outer one: the TLS-in-TLS signal the censor already recognizes.
		out = append(out, "reality-without-vision")
	}
	if transport == "ws" {
		// WebSocket+REALITY is rejected by the Xray renderer; the warning
		// surfaces it earlier, at import/validation time.
		out = append(out, "reality-ws-transport")
	}
	if transport == "xhttp" && IsVisionFlow(o.Flow) && !o.HasVLESSEncryption() {
		// REALITY+XHTTP+vision without VLESS Encryption is not a legal
		// XTLS combination (REALITY is not Encryption); multiplexing
		// there is xmux's job, not vision's. With VLESS Encryption the
		// flow is legal on any transport, so no warning (PASS3 deep S3b).
		out = append(out, "reality-xhttp-vision")
	}
	if fp := o.TLS.Fingerprint; fp != "" {
		// The fingerprint half of the REALITY mistakes this file's
		// header lists — stale uTLS and shares no modern browser
		// offers — was never surfaced (CENSOR-P1): a randomized
		// parrot matches no browser population, a stale explicit
		// parrot is what TSPU already scores, and a pre-131 Chrome
		// parrot is KNOWN to lack the X25519MLKEM768 hybrid share
		// modern REALITY servers require (see fingerprint.go for
		// what each predicate can and cannot prove from a name).
		if IsRandomizedFingerprint(fp) {
			out = append(out, "reality-fingerprint-randomized")
		}
		if IsStaleParrot(fp) {
			out = append(out, "reality-fingerprint-stale")
		}
		if KnownMissingPQKeyShare(fp) {
			out = append(out, "reality-fingerprint-no-pq-key-share")
		}
	}
	if o.TLS.SpiderX != "" {
		// PASS3 deep A2: SpiderX is rendered only by Xray (both
		// stream legs). sing-box's client REALITY schema has no
		// spider field at all — the engine cannot honour it — and
		// mihomo's reality-opts in the pinned docs has none either,
		// so on those paths the parameter used to vanish silently.
		// Warn instead of dropping it quietly; the code is advisory
		// (RealityWarnings never block) and the app words it as
		// "honoured only by Xray".
		out = append(out, "reality-spiderx-xray-only")
	}
	if dest := o.realityDest(); dest != "" {
		if _, err := netip.ParseAddr(dest); err == nil {
			out = append(out, "reality-dest-ip")
		} else if strings.HasPrefix(dest, "http://") || strings.HasPrefix(dest, "https://") {
			out = append(out, "reality-dest-not-host")
		} else if !validDNSName(dest) {
			// Not a name a TLS stack can put in an SNI at all (port,
			// path, underscore, wildcard, empty label): the decoy is
			// malformed, not merely unfashionable. ValidateReality
			// blocks this shape; the warning exists so list views can
			// flag stored configs that predate the block.
			out = append(out, "reality-dest-malformed")
		} else if !isPublicDestName(dest) {
			// A single label or a private suffix (localhost, .lan,
			// .home, .local, ...) cannot be a real public website:
			// the censor's dest cascade resolves it nowhere, and the
			// mismatch is visible at a glance.
			out = append(out, "reality-dest-not-public")
		}
		// The decoy must be independent of the proxy: an SNI that is
		// the server's own name resolves to the server itself (the
		// probe's SNI-consistency check flags the same shape from the
		// wire side), so the "real site" and the proxy share one
		// infrastructure — exactly the correlation T006 warns about.
		// Exact equality is only the narrowest form: a parent/subdomain
		// pair (Server=vpn.example.com, SNI=www.example.com, or the
		// reverse) sits on the same registrable domain and the same
		// infrastructure, and the censor correlates it just as easily,
		// so the check compares registrable domains, not strings
		// (CENSOR-SURV review, §1).
		if o.TLS.ServerName != "" && o.Server != "" {
			if _, err := netip.ParseAddr(o.Server); err != nil &&
				sameSiteName(o.TLS.ServerName, o.Server) {
				out = append(out, "reality-sni-is-server")
			}
		}
	} else {
		out = append(out, "reality-dest-missing")
	}
	if id := o.TLS.RealityShortID; id != "" {
		if raw, err := hexBytes(id); err == nil {
			switch {
			case len(raw) <= shortIDShortBytes:
				// One or two bytes are brute-forceable in seconds
				// and, in the field, almost always a provider
				// default that thousands of unrelated servers
				// share — a correlation handle, not a secret.
				out = append(out, "reality-shortid-short")
			case lowEntropyShortID(raw, id):
				// 000000…, aaaaaa…, abcdabcd…, deadbeefdeadbeef…
				// and friends are the published example/default
				// shortIds: sending one announces "stock REALITY
				// config" to any observer who has read the same
				// examples.
				out = append(out, "reality-shortid-low-entropy")
			}
		}
	}
	return out
}

// shortIDShortBytes bounds "too short to be a secret": a shortId of at
// most this many bytes is a warning, not an error — the server may
// legitimately accept it, but it carries almost no entropy.
const shortIDShortBytes = 2

// normalizeDestName canonicalizes a dest/server name for comparison:
// case-insensitive, no trailing dot.
func normalizeDestName(s string) string {
	return strings.ToLower(strings.TrimSuffix(strings.TrimSpace(s), "."))
}

// validDNSName reports whether s is a syntactically valid DNS name:
// labels of letters, digits and interior hyphens, 1–63 bytes each, the
// whole name at most 253 bytes. It makes no claim about existence or
// popularity — syntax only, so it never false-positives a real site.
//
// Two shapes need care (CENSOR-SURV review, §1):
//   - U-label IDN (bücher.example.de) is a legitimate dest a provider
//     may well hand out: the name is converted to its A-label
//     (punycode) form via IDNA and validated in that form, so a valid
//     IDN passes — it must never be a hard block. (The punycode form
//     itself is plain LDH and passes unchanged.) A name IDNA rejects
//     (underscore, space, wildcard, a label starting with a hyphen)
//     is not a DNS name at all.
//   - A dotted all-numeric name (123.456.78) is a quasi-IP, not a DNS
//     name: a top label of digits only is not a legal TLD (RFC 1123
//     relaxes the first label, never the last), and an observer reads
//     the shape as a broken IP literal. It is malformed here, so both
//     the warning and ValidateReality name it as such instead of
//     staying silent.
func validDNSName(s string) bool {
	s = strings.TrimSuffix(s, ".")
	if s == "" {
		return false
	}
	ascii, err := idna.Lookup.ToASCII(s)
	if err != nil {
		return false
	}
	if ascii == "" || len(ascii) > 253 {
		return false
	}
	labels := strings.Split(ascii, ".")
	for _, label := range labels {
		if label == "" || len(label) > 63 {
			return false
		}
		for i := 0; i < len(label); i++ {
			c := label[i]
			ok := c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-'
			if !ok {
				return false
			}
		}
		if label[0] == '-' || label[len(label)-1] == '-' {
			return false
		}
	}
	// Quasi-IP: the last label is all digits (see above).
	if isAllDigits(labels[len(labels)-1]) {
		return false
	}
	return true
}

// isAllDigits reports whether s is non-empty and all ASCII digits.
func isAllDigits(s string) bool {
	if s == "" {
		return false
	}
	for i := 0; i < len(s); i++ {
		if s[i] < '0' || s[i] > '9' {
			return false
		}
	}
	return true
}

// destASCIIName converts a dest name to its canonical ASCII form
// (IDNA A-labels, lower case, no trailing dot) for comparisons that
// must agree across spellings: "Bücher.example.de" and
// "xn--bcher-kva.example.de" are the same site. It returns "" when
// the name cannot be converted at all.
func destASCIIName(s string) string {
	ascii, err := idna.Lookup.ToASCII(strings.TrimSuffix(normalizeDestName(s), "."))
	if err != nil {
		return ""
	}
	return ascii
}

// sameSiteName reports whether two names are the same site for
// SNI↔server correlation: equal after normalization, or sharing one
// registrable domain (eTLD+1), so parent/subdomain pairs in either
// direction count. Names that cannot yield a registrable domain
// (single labels, bare TLDs, unconvertible IDN) fall back to the
// exact normalized comparison only — no guessed correlation.
func sameSiteName(a, b string) bool {
	if normalizeDestName(a) == normalizeDestName(b) {
		return true
	}
	ra, rb := registrableDomain(a), registrableDomain(b)
	return ra != "" && rb != "" && ra == rb
}

// registrableDomain returns the eTLD+1 of a name in canonical ASCII
// form, or "" when the name has none.
func registrableDomain(s string) string {
	ascii := destASCIIName(s)
	if ascii == "" {
		return ""
	}
	d, err := publicsuffix.EffectiveTLDPlusOne(ascii)
	if err != nil {
		return ""
	}
	return d
}

// privateDestSuffixes are suffixes that never name a public website:
// home/LAN conventions and reserved special-use names (RFC 6761/6762,
// home.arpa is RFC 8375, .onion is RFC 7686).
var privateDestSuffixes = []string{
	".local", ".lan", ".home", ".internal", ".intranet", ".corp",
	".localhost", ".invalid", ".example", ".test",
	".home.arpa", ".onion", ".localdomain",
}

// isPublicDestName reports whether a syntactically valid dest name
// could be a real public site: at least two labels and no private
// suffix. "www.example.com" passes; the bare TLD-like single labels
// and LAN names do not.
func isPublicDestName(s string) bool {
	n := normalizeDestName(s)
	if n == "localhost" || n == "home.arpa" || !strings.Contains(n, ".") {
		return false
	}
	for _, suf := range privateDestSuffixes {
		if strings.HasSuffix(n, suf) {
			return false
		}
	}
	return true
}

// hexBytes decodes an even-length hex string (the shape isHexID has
// already accepted). It returns an error for anything else.
func hexBytes(s string) ([]byte, error) {
	if len(s)%2 != 0 {
		return nil, fmt.Errorf("odd hex length")
	}
	out := make([]byte, len(s)/2)
	for i := range out {
		hi, ok1 := hexNibble(s[2*i])
		lo, ok2 := hexNibble(s[2*i+1])
		if !ok1 || !ok2 {
			return nil, fmt.Errorf("not hex")
		}
		out[i] = hi<<4 | lo
	}
	return out, nil
}

func hexNibble(c byte) (byte, bool) {
	switch {
	case c >= '0' && c <= '9':
		return c - '0', true
	case c >= 'a' && c <= 'f':
		return c - 'a' + 10, true
	case c >= 'A' && c <= 'F':
		return c - 'A' + 10, true
	}
	return 0, false
}

// allBytesEqual reports whether every byte of b is the same.
func allBytesEqual(b []byte) bool {
	for _, x := range b[1:] {
		if x != b[0] {
			return false
		}
	}
	return len(b) > 0
}

// lowEntropyShortID reports whether a decoded shortId is a published
// placeholder shape rather than a random secret. The name of the
// warning promises "low entropy", so the check covers the shapes
// stock configs actually ship (CENSOR-SURV review, §1 — the earlier
// version caught only the all-same-byte shape):
//   - every byte the same (000000…, aaaaaa…);
//   - a short period repeated over the bytes or over the hex text
//     (abcdabcd…, deadbeefdeadbeef… — any tiling of a shorter block);
//   - a known placeholder word in the hex (deadbeef, cafebabe),
//     even once: a single deadbeef is a textbook default, not entropy.
//
// A genuinely random id matching any of these is vanishingly
// unlikely — and if one did, it really would be low-entropy.
func lowEntropyShortID(raw []byte, hexStr string) bool {
	if allBytesEqual(raw) {
		return true
	}
	if hasPeriod(raw) {
		return true
	}
	h := strings.ToLower(hexStr)
	if hasPeriod([]byte(h)) {
		return true
	}
	for _, word := range []string{"deadbeef", "cafebabe", "feedface"} {
		if strings.Contains(h, word) {
			return true
		}
	}
	return false
}

// hasPeriod reports whether b is a repetition of a shorter block:
// b[i] == b[i%p] for some period p < len(b).
func hasPeriod(b []byte) bool {
	for p := 1; p*2 <= len(b); p++ {
		ok := true
		for i := p; i < len(b); i++ {
			if b[i] != b[i%p] {
				ok = false
				break
			}
		}
		if ok {
			return true
		}
	}
	return false
}

// ValidateReality rejects REALITY configurations that cannot work or that
// are malformed in ways the engines would silently misapply. A nil error
// means the cryptographic parameters are well-formed; it says nothing
// about whether the dest is a good decoy (see probe.CheckDest).
func (o Outbound) ValidateReality() error {
	if !o.TLS.Reality {
		return nil
	}
	if o.TLS.RealityPublicKey == "" {
		return fmt.Errorf("outbound %s: REALITY requires a public key", o.ID)
	}
	if v := o.TLS.RealityMLDSA65Verify; v != "" && !isMLDSA65VerifyKey(v) {
		// Probed on the pinned Xray (2026-10-20): a malformed
		// mldsa65Verify fails config load with `invalid
		// "mldsa65Verify"`, so the shape is a plan error here, not a
		// dead engine at connect time.
		return fmt.Errorf("outbound %s: REALITY mldsa65Verify is not a 1952-byte base64url ML-DSA-65 key", o.ID)
	}
	if sx := o.TLS.SpiderX; sx != "" && !strings.HasPrefix(sx, "/") {
		// Probed on the pinned Xray (2026-10-20): a spiderX without
		// the leading slash fails config load, while spaces, query
		// strings and multi-KB paths all load — the slash is the
		// engine's only shape rule, so it is the only one enforced
		// here. The value itself is an identifier (see Identifiers)
		// and stays out of the error text.
		return fmt.Errorf("outbound %s: REALITY spiderX must start with %q", o.ID, "/")
	}
	if !isX25519PublicKey(o.TLS.RealityPublicKey) {
		return fmt.Errorf("outbound %s: REALITY public key is not a 32-byte base64url X25519 key", o.ID)
	}
	if id := o.TLS.RealityShortID; id != "" && !isHexID(id, 8) {
		return fmt.Errorf("outbound %s: REALITY shortId must be hex, at most 8 bytes", o.ID)
	}
	// The SNI/dest goes on the wire verbatim in every ClientHello. A
	// value that is not a DNS name at all (scheme, port, path,
	// underscore, wildcard) cannot be a real decoy and makes the
	// engines fail or improvise — reject it at import/plan time, not
	// at connect time in front of the censor. An IP-literal SNI stays
	// a warning (reality-dest-ip): some engines accept it, and the
	// operator may be mid-migration.
	//
	// The value checked is the EFFECTIVE SNI (realityDest): with an
	// empty ServerName every engine falls back to the server address,
	// so a malformed Server is exactly what would go on the wire —
	// checking ServerName alone let Server="my_site.example.com" with
	// an empty SNI pass while the warnings (which use realityDest)
	// already named it malformed (CENSOR-SURV review, Medium 1). A
	// valid U-label IDN passes (validDNSName converts via IDNA): a
	// legitimate provider dest must not be hard-blocked for its
	// spelling.
	if sni := o.realityDest(); sni != "" {
		if _, err := netip.ParseAddr(sni); err != nil && !validDNSName(sni) {
			return fmt.Errorf("outbound %s: REALITY dest/SNI %q is not a valid DNS name", o.ID, sni)
		}
	}
	return nil
}

// isX25519PublicKey checks the textual shape of a REALITY public key:
// 43 base64url characters decoding to 32 bytes. It does not (and cannot)
// check that the key belongs to the server — that is established by the
// handshake itself.
func isX25519PublicKey(s string) bool {
	if len(s) != 43 {
		return false
	}
	raw, err := base64.RawURLEncoding.DecodeString(s)
	return err == nil && len(raw) == 32
}

// mldsa65VerifyKeyBytes is the size of an ML-DSA-65 verification key
// (FIPS 204, parameter set 65): the only size Xray's REALITY config
// accepts for mldsa65Verify (2603 base64url characters, probed on the
// pinned binary with keys from `xray mldsa65`).
const mldsa65VerifyKeyBytes = 1952

// isMLDSA65VerifyKey checks the textual shape of an mldsa65Verify
// value: base64url (raw or padded) decoding to exactly one ML-DSA-65
// verification key. Like isX25519PublicKey it cannot check that the
// key belongs to the server — the handshake's ML-DSA-65 signature
// check is exactly what the key enables.
func isMLDSA65VerifyKey(s string) bool {
	for _, enc := range []*base64.Encoding{base64.RawURLEncoding, base64.URLEncoding} {
		if raw, err := enc.DecodeString(s); err == nil {
			return len(raw) == mldsa65VerifyKeyBytes
		}
	}
	return false
}

// isHexID checks hex shape with a byte-length cap.
func isHexID(s string, maxBytes int) bool {
	if len(s) == 0 || len(s) > 2*maxBytes || len(s)%2 != 0 {
		return false
	}
	for _, c := range s {
		if !(c >= '0' && c <= '9' || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F') {
			return false
		}
	}
	return true
}
