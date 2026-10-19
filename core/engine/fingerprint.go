package engine

import (
	"regexp"
	"strconv"
	"strings"
)

// Canonical uTLS fingerprint knowledge for the core (net-rd 6/20).
//
// The engines resolve fingerprint names inside their own vendored uTLS
// copies, so sora can only choose a name — never the ClientHello bytes.
// That makes fingerprint *freshness* a property of the pinned engine
// binaries (see packaging/engines/engines.lock), not of this code.
//
// Landscape as of 2026-10-19:
//   - refraction-networking/utls master added HelloChrome_155 on 2026-10-06
//     (commit 6ebdceb, verified against branded Chrome 155) and made it
//     HelloChrome_Auto. JA4 of the new parrot matches real Chrome 155:
//     t13d1517h2_8daaf6152771_cb7bf5808d99.
//   - Xray-core main (2026-10-11, issue XTLS/Xray-core#7131) still pins a
//     utls where "chrome" sends Chrome 133 (JA4
//     t13d1516h2_8daaf6152771_d8a2da3f94cd); TSPU blocking of that stale
//     fingerprint is reported in Russia.
//   - CVE-2026-27017 (fixed in utls 1.8.1): Chrome parrot + GREASE ECH
//     picked the ECH cipher suite inconsistently with the outer
//     ClientHello — a distinguisher impossible in real Chrome.
//   - Detection trend: JA3 is broadly considered obsolete; JA4/JA4+ is the
//     current standard (Wallarm, Vercel firewall, ngrok) — used for risk
//     scoring and bot classification, increasingly for hard blocking.
//   - mihomo's "random" generates a modern browser fingerprint weighted by
//     Cloudflare Radar data (mihomo-specific); sing-box/Xray "random"
//     picks uniformly among their own parrots. Semantics differ per engine.
//
// Per-engine accepted names (2026-10):
//   - sing-box tls.utls.fingerprint: chrome, firefox, edge, safari, ios,
//     android, 360, qq, random, randomized.
//   - Xray reality/tlsSettings fingerprint: the above plus randomized and
//     versioned/auto names (hellochrome_auto, hellochrome_120..155,
//     hellofirefox_*, helloios_*, hellosafari_*, helloedge_*, ...).
//   - mihomo client-fingerprint: chrome, firefox, safari, iOS, android,
//     edge, 360, qq, random. Since mihomo 1.19.20 a SNI/servername must
//     also be set when client-fingerprint is used.

// DefaultFingerprint is the uTLS name sora uses when the subscription does
// not provide one and the engine needs a fingerprint (REALITY today).
// In sing-box, mihomo and Xray this alias resolves to utls.HelloChrome_Auto
// — the newest verified Chrome parrot of the engine's vendored uTLS — so
// the *bytes* on the wire are a property of the pinned engine build (see
// packaging/engines/engines.lock), never of this string. A stale engine
// sends a stale Chrome here no matter what the name says.
const DefaultFingerprint = "chrome"

// DefaultXrayFingerprint is the uTLS name sora renders for Xray REALITY
// when the subscription provides none. It resolves to the same parrot as
// DefaultFingerprint in current Xray (both are utls.HelloChrome_Auto); the
// explicit auto spelling states the intent — always the newest verified
// Chrome ClientHello — and matches the field-test recommendation from
// XTLS/Xray-core#7131 (Oct 2026), where the pinned-Chrome-133 "chrome" was
// blocked by TSPU while the auto parrot passed.
const DefaultXrayFingerprint = "hellochrome_auto"

// CurrentChromeParrot is the newest Chrome ClientHello parrot known to
// exist upstream. Compare against the pinned engines' vendored uTLS; bump
// this (and engines.lock) when upstream adds a newer verified parrot.
const CurrentChromeParrot = "HelloChrome_155"

// ReferenceChromeJA4 is the JA4 of the real CurrentChromeParrot,
// measured against branded Chrome 155 (Linux) in Oct 2026:
// t13d1517h2_8daaf6152771_cb7bf5808d99. The CI freshness gate
// (obfs.TestCoreUTLSFreshnessGate) compares the vendored uTLS'
// HelloChrome_Auto against it: a mismatch means the vendored uTLS is
// stale and must be bumped. Update together with CurrentChromeParrot.
const ReferenceChromeJA4 = "t13d1517h2_8daaf6152771_cb7bf5808d99"

// CurrentChromeVersion is the Chrome release CurrentChromeParrot imitates.
// Explicit parrots older than this are stale: DPI already scores or blocks
// them (see the TSPU field tests in XTLS/Xray-core#7131).
const CurrentChromeVersion = 155

// minPQChromeVersion is the first Chrome release whose parrot carries the
// X25519MLKEM768 post-quantum hybrid key share. ~90% of real Chrome traffic
// had it in 2026; a "modern Chrome" ClientHello without it is a visible
// contradiction to DPI before any HTTP is exchanged.
const minPQChromeVersion = 131

// KnownFingerprints is the union of fingerprint names accepted by all
// three engines. Values outside this set are either engine-specific
// (e.g. Xray's versioned parrots) or invalid.
var KnownFingerprints = []string{
	"chrome", "firefox", "safari", "ios", "android", "edge", "360", "qq", "random",
}

// versionedParrot matches Xray-style explicit parrots such as
// "hellochrome_131" or "hellofirefox_120". sing-box and mihomo do not
// accept these names; they are passed through only for Xray.
var versionedParrot = regexp.MustCompile(`^hello(chrome|firefox|ios|safari|edge|android|360|qq)_(\d+(_\d+)?|auto)$`)

// NormalizeFingerprint trims and lowercases a fingerprint name coming from
// a subscription link (e.g. "Chrome" or " chrome "). Engine matching is
// case-sensitive in places (mihomo documents "iOS"), so every renderer
// should normalize before emitting.
func NormalizeFingerprint(name string) string {
	return strings.ToLower(strings.TrimSpace(name))
}

// IsKnownFingerprint reports whether name is accepted by every engine.
// An empty name is valid: it means "no fingerprint configured" and lets
// the caller apply its own default.
func IsKnownFingerprint(name string) bool {
	name = NormalizeFingerprint(name)
	if name == "" {
		return true
	}
	for _, known := range KnownFingerprints {
		if name == known {
			return true
		}
	}
	return false
}

// IsVersionedParrot reports whether name looks like an engine-specific
// explicit parrot (Xray: "hellochrome_155"). Such names bypass the union
// check and must only be routed to engines that understand them.
func IsVersionedParrot(name string) bool {
	return versionedParrot.MatchString(NormalizeFingerprint(name))
}

// FingerprintWarning returns a non-empty human-readable warning when name
// is suspicious: unknown to every engine, or a versioned parrot older
// than the current upstream one. Empty string means "no warning".
// Callers surface this in diagnostics; it never blocks a connection.
func FingerprintWarning(name string) string {
	normalized := NormalizeFingerprint(name)
	if normalized == "" {
		return ""
	}
	if IsKnownFingerprint(normalized) {
		return ""
	}
	if IsVersionedParrot(normalized) {
		if v := ParrotVersion(normalized); v != 0 && v < CurrentChromeVersion {
			return "fingerprint: versioned parrot " + normalized + " pins Chrome " + strconv.Itoa(v) +
				" and is stale (TSPU blocks Chrome 133 and older); current upstream is " + CurrentChromeParrot
		}
		return "fingerprint: versioned parrot " + normalized + " is engine-specific (Xray only); current upstream is " + CurrentChromeParrot
	}
	return "fingerprint: " + name + " is not a known uTLS fingerprint; the engine may reject the config"
}

// ParrotInfo describes one explicit versioned uTLS parrot: which browser
// release it imitates and whether it carries the post-quantum hybrid key
// share. It is knowledge about upstream uTLS, not a measurement of what an
// engine sends: alias names ("chrome", "firefox", ...) are deliberately
// absent, because their bytes are whatever the engine's vendored uTLS
// resolves Hello*_Auto to — which is the freshness question itself.
type ParrotInfo struct {
	// ChromeVersion is the imitated Chrome release; 0 for non-Chrome.
	ChromeVersion int
}

// KnownParrots maps explicit versioned parrot names (Xray spelling) to
// their browser release. Only parrots relevant to freshness decisions are
// listed: the PQ boundary (131), the TSPU-blocked 133, and the current 155.
var KnownParrots = map[string]ParrotInfo{
	"hellochrome_120": {ChromeVersion: 120},
	"hellochrome_131": {ChromeVersion: 131},
	"hellochrome_133": {ChromeVersion: 133},
	"hellochrome_155": {ChromeVersion: 155},
}

// ParrotVersion returns the Chrome release an explicit versioned parrot
// imitates, or 0 when the name is an alias (version unknown — depends on
// the engine's vendored uTLS) or not a Chrome parrot at all.
func ParrotVersion(name string) int {
	if info, ok := KnownParrots[NormalizeFingerprint(name)]; ok {
		return info.ChromeVersion
	}
	return 0
}

// IsStaleParrot reports whether name pins an explicit Chrome parrot older
// than the current upstream one. Stale parrots are not "old but working":
// per the Oct 2026 TSPU field tests, Chrome 133 is actively blocked, so
// anything older than CurrentChromeVersion is a likely cause of failure.
// Alias names ("chrome") return false — their staleness can only be decided
// by measuring the engine's actual ClientHello (see obfs JA4 self-check).
func IsStaleParrot(name string) bool {
	if v := ParrotVersion(name); v != 0 {
		return v < CurrentChromeVersion
	}
	return false
}

// HasPQKeyShare reports whether name is known to send the X25519MLKEM768
// post-quantum hybrid key share: true for Chrome parrots >= 131 and for
// the "chrome"/auto aliases (they resolve to a >= 131 parrot in every
// uTLS sora has ever pinned). It returns false only for explicit pre-131
// Chrome parrots — the one case where sora can know the key share is
// missing without measuring the wire.
func HasPQKeyShare(name string) bool {
	normalized := NormalizeFingerprint(name)
	if normalized == "chrome" || normalized == "hellochrome_auto" {
		return true
	}
	if v := ParrotVersion(normalized); v != 0 {
		return v >= minPQChromeVersion
	}
	// Unknown or non-Chrome names: no claim either way.
	return true
}

// IsRandomizedFingerprint reports whether name selects a randomized
// fingerprint ("random", "randomized"). Detector research (2025-2026)
// consensus: randomized TLS fingerprints match no real browser population
// and make the client *more* detectable, not less — exact imitation of a
// current browser beats randomization, and JA4 was designed to resist it.
// Useful as a manual fallback option, never as an anti-detect feature.
func IsRandomizedFingerprint(name string) bool {
	switch NormalizeFingerprint(name) {
	case "random", "randomized", "randomizednoalpn", "hellorandomized", "hellorandomizedalpn", "hellorandomizednoalpn":
		return true
	}
	return false
}
