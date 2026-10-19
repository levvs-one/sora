package engine

import (
	"regexp"
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
const DefaultFingerprint = "chrome"

// CurrentChromeParrot is the newest Chrome ClientHello parrot known to
// exist upstream. Compare against the pinned engines' vendored uTLS; bump
// this (and engines.lock) when upstream adds a newer verified parrot.
const CurrentChromeParrot = "HelloChrome_155"

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
		return "fingerprint: versioned parrot " + normalized + " is engine-specific (Xray only) and may be stale; current upstream is " + CurrentChromeParrot
	}
	return "fingerprint: " + name + " is not a known uTLS fingerprint; the engine may reject the config"
}
