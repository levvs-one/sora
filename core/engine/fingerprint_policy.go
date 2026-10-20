package engine

import (
	"fmt"
	"strings"
)

// Fingerprint policy as data (CENSOR-FP).
//
// Before this file, the choice of uTLS fingerprint was scattered as
// hardcoded fallbacks inside three renderers: sing-box and mihomo
// passed the plan's spelling through unnormalized, Xray normalized,
// each had its own default, and the Xray probe rotation lived as a
// private slice in the Xray renderer. The same plan could therefore
// put a different ClientHello on the wire depending on which engine
// carried it — "Chrome" reached mihomo verbatim, Xray lowercased,
// and a versioned Xray parrot name reached sing-box, which rejects it
// at load (probed on the pinned lx.22 binary: "unknown uTLS
// fingerprint: hellochrome_133").
//
// The policy below is the single source: a plan carries it in
// Options.Fingerprint, every renderer resolves through
// ResolveFingerprint, and the rotation order for probe retries is
// data here, not a renderer private. The zero policy reproduces the
// historic behaviour exactly: an explicit plan fingerprint wins, a
// REALITY outbound gets the canonical default, plain TLS emits no
// fingerprint unless the plan pins one.

// FingerprintMode selects how ResolveFingerprint and the probe retry
// paths treat the policy's profile list.
type FingerprintMode string

// Fingerprint selection modes.
const (
	// FingerprintFixed pins one profile for the whole session: the
	// first of Profiles, or Default. It is the zero value ("").
	FingerprintFixed FingerprintMode = "fixed"
	// FingerprintRotate walks Profiles in order across probe attempts
	// and sessions, so one blocked template does not mark a working
	// server dead. Randomized profiles stay last (see
	// IsRandomizedFingerprint): they match no real browser population.
	FingerprintRotate FingerprintMode = "rotate"
)

// FingerprintPolicy is the plan-level fingerprint selection policy.
// Every field is data: profiles and subscriptions may carry it, the
// renderers only resolve it.
type FingerprintPolicy struct {
	// Mode is "fixed" (default) or "rotate".
	Mode FingerprintMode
	// Default is the profile applied when an outbound pins none and a
	// fingerprint is emitted. Empty keeps the canonical per-engine
	// default (DefaultFingerprint, or DefaultXrayFingerprint for Xray
	// REALITY).
	Default string
	// Profiles is the ordered candidate list for rotation and for
	// probe retries. Empty selects the canonical rotation for the
	// engine (CanonicalRotation).
	Profiles []string
	// PerProtocol overrides Default for one protocol, e.g. a REALITY
	// (vless) profile distinct from the trojan one.
	PerProtocol map[Protocol]string
}

// DefaultFingerprintPolicy is the canonical zero-behaviour policy:
// fixed mode, engine defaults, canonical rotation.
var DefaultFingerprintPolicy = FingerprintPolicy{Mode: FingerprintFixed}

// CanonicalRotation is the uTLS fingerprint try-order for probes,
// shared by every engine's retry path. Index 0 is the render default;
// real browser templates go first, the TSPU-flagged pinned "chrome"
// (Chrome 133 on Xray) and the randomized templates — which match no
// browser population — stay last. The Xray spelling is the canonical
// one; spellingForEngine adapts it per engine.
var CanonicalRotation = []string{
	DefaultXrayFingerprint, // hellochrome_auto
	"firefox",
	"safari",
	"chrome",
	"randomized",
}

// spellingForEngine adapts a canonical fingerprint name to the name an
// engine accepts. sing-box and mihomo take the union aliases only:
// versioned parrots ("hellochrome_133") are Xray-only (probed:
// sing-box lx.22 rejects them at load), so on those engines an auto
// parrot collapses to its alias and a pinned versioned parrot has no
// spelling at all — ResolveFingerprint reports that honestly by
// returning the alias of the same browser when one exists, and
// FingerprintSpellingOK exposes the loss to gates.
func spellingForEngine(kind Kind, name string) string {
	name = NormalizeFingerprint(name)
	if kind == KindXray {
		return name
	}
	switch name {
	case "hellochrome_auto":
		return "chrome"
	case "hellofirefox_auto":
		return "firefox"
	case "hellosafari_auto":
		return "safari"
	case "helloios_auto":
		return "ios"
	case "helloedge_auto":
		return "edge"
	case "hellorandomized", "hellorandomizedalpn", "hellorandomizednoalpn":
		return "randomized"
	}
	if IsVersionedParrot(name) {
		// A pinned version (hellochrome_133) has no per-version
		// spelling outside Xray; the same browser's alias is the
		// closest honest spelling. Callers that must not substitute
		// check FingerprintSpellingOK instead of resolving.
		if b := versionedBrowser(name); b != "" {
			return b
		}
	}
	return name
}

// versionedBrowser extracts the browser alias from a versioned parrot
// name ("hellochrome_133" -> "chrome"), or "".
func versionedBrowser(name string) string {
	rest := strings.TrimPrefix(NormalizeFingerprint(name), "hello")
	if i := strings.LastIndex(rest, "_"); i > 0 {
		return rest[:i]
	}
	return ""
}

// FingerprintSpellingOK reports whether name can be spelled exactly on
// kind: the name the operator pinned is the name the engine loads, with
// no alias substitution. A versioned parrot is exact only on Xray.
func FingerprintSpellingOK(kind Kind, name string) bool {
	name = NormalizeFingerprint(name)
	if name == "" {
		return true
	}
	if kind == KindXray {
		return IsKnownFingerprint(name) || IsRandomizedFingerprint(name) || IsVersionedParrot(name)
	}
	if IsVersionedParrot(name) {
		return false
	}
	if IsKnownFingerprint(name) {
		return true
	}
	// sing-box additionally spells "randomized"; mihomo does not.
	return kind == KindSingBox && name == "randomized"
}

// ResolveFingerprint returns the fingerprint name to render for one
// outbound on one engine under the plan's policy. It is the ONLY
// resolution path the renderers use, so a plan means the same
// ClientHello shape on every engine that can spell it:
//
//  1. an explicit plan fingerprint (normalized) wins;
//  2. the policy's per-protocol profile;
//  3. for REALITY: the policy default, else the canonical default
//     (DefaultXrayFingerprint on Xray, DefaultFingerprint elsewhere);
//  4. for plain TLS: the policy default when the policy pins one,
//     otherwise "" (no fingerprint emitted, as before).
func ResolveFingerprint(kind Kind, o Outbound, policy FingerprintPolicy) string {
	if fp := NormalizeFingerprint(o.TLS.Fingerprint); fp != "" {
		return spellingForEngine(kind, fp)
	}
	if fp, ok := policy.PerProtocol[o.Protocol]; ok && NormalizeFingerprint(fp) != "" {
		return spellingForEngine(kind, fp)
	}
	def := NormalizeFingerprint(policy.Default)
	if o.TLS.Reality {
		if def != "" {
			return spellingForEngine(kind, def)
		}
		if kind == KindXray {
			return DefaultXrayFingerprint
		}
		return DefaultFingerprint
	}
	if def != "" {
		return spellingForEngine(kind, def)
	}
	return ""
}

// RotationFor returns the ordered fingerprint candidates a probe or a
// rotating session tries for kind: the policy's list when it pins one,
// else CanonicalRotation, each adapted to the engine's spelling with
// duplicates removed.
func RotationFor(kind Kind, policy FingerprintPolicy) []string {
	src := policy.Profiles
	if len(src) == 0 {
		src = CanonicalRotation
	}
	out := make([]string, 0, len(src))
	seen := map[string]bool{}
	for _, name := range src {
		s := spellingForEngine(kind, name)
		if s == "" || seen[s] {
			continue
		}
		seen[s] = true
		out = append(out, s)
	}
	return out
}

// Validate checks the policy's shape at plan validation time, so a
// profile no engine can spell fails before any renderer sees it.
func (p FingerprintPolicy) Validate() error {
	switch p.Mode {
	case "", FingerprintFixed, FingerprintRotate:
	default:
		return fmt.Errorf("fingerprint policy: unknown mode %q (fixed or rotate)", p.Mode)
	}
	check := func(what, name string) error {
		n := NormalizeFingerprint(name)
		if n == "" {
			return nil
		}
		if !IsKnownFingerprint(n) && !IsRandomizedFingerprint(n) && !IsVersionedParrot(n) {
			return fmt.Errorf("fingerprint policy: %s %q is not a known uTLS fingerprint", what, name)
		}
		return nil
	}
	if err := check("default", p.Default); err != nil {
		return err
	}
	for _, name := range p.Profiles {
		if err := check("profile", name); err != nil {
			return err
		}
	}
	for proto, name := range p.PerProtocol {
		if !validProtocols[proto] {
			return fmt.Errorf("fingerprint policy: unknown protocol %q", proto)
		}
		if err := check("per-protocol", name); err != nil {
			return err
		}
	}
	return nil
}
