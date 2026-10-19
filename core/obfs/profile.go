package obfs

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

// Fingerprint names accepted by Profile.UTLS. The empty string means "none".
const (
	UTLSNone       = "none"
	UTLSChrome     = "chrome"
	UTLSFirefox    = "firefox"
	UTLSSafari     = "safari"
	UTLSRandomized = "randomized"
)

// Hard limits. Delays above these are clamped (never rejected) so a
// misconfigured profile degrades gracefully instead of hanging forever.
const (
	// MaxFragDelay caps the pause between ClientHello fragments.
	MaxFragDelay = 2 * time.Second
	// MaxJitter caps the random inter-packet delay.
	MaxJitter = 5 * time.Second
	// MaxFragmentSize caps a single ClientHello fragment payload: a TLS
	// record payload never exceeds 2^14 bytes.
	MaxFragmentSize = 16 * 1024
)

// Profile describes one obfuscation setup for TLS handshakes the core
// initiates itself (probing, DoH, subscription fetches).
//
// A zero Profile is valid and means "no obfuscation".
type Profile struct {
	// UTLS selects the ClientHello fingerprint: "chrome", "firefox",
	// "safari", "randomized", "none" ("" is treated as "none").
	UTLS string

	// FragSizes enables ClientHello fragmentation when non-nil. Each entry
	// is the payload size of one leading fragment; the remainder of the
	// record forms the final fragment. A non-nil but empty slice is
	// rejected by Validate as ambiguous: use nil to disable.
	FragSizes []int

	// FragDelay is the pause between ClientHello fragments. Clamped to
	// MaxFragDelay.
	FragDelay time.Duration

	// Jitter is the maximum random delay inserted between handshake
	// packets. The actual delay per packet is uniform in [0, Jitter].
	// Clamped to MaxJitter.
	Jitter time.Duration

	// FakeSNI, when set, replaces the SNI in the initial ClientHello with
	// a decoy hostname. Only applied to handshakes the core initiates
	// itself, never to user traffic. The server must serve a certificate
	// valid for the fake name (or verification must be disabled for that
	// connection), otherwise the handshake will fail closed.
	FakeSNI string
}

// PresetFast is the lightest touch: a common browser fingerprint, no
// fragmentation, no artificial delays.
var PresetFast = Profile{UTLS: UTLSChrome}.Clamp()

// PresetBalanced adds modest fragmentation and jitter on top of a browser
// fingerprint. Suitable as the default for probing and subscription fetches.
var PresetBalanced = Profile{
	UTLS:      UTLSChrome,
	FragSizes: []int{64, 128},
	FragDelay: 10 * time.Millisecond,
	Jitter:    25 * time.Millisecond,
}.Clamp()

// PresetMax is the most aggressive masking: randomized fingerprint,
// aggressive fragmentation and noticeable jitter. Handshakes take longer.
var PresetMax = Profile{
	UTLS:      UTLSRandomized,
	FragSizes: []int{32, 64, 96},
	FragDelay: 50 * time.Millisecond,
	Jitter:    150 * time.Millisecond,
}.Clamp()

// Validate reports whether the profile is well-formed. Extreme but
// representable delays are not errors: they are normalized by Clamp.
func (p Profile) Validate() error {
	switch normalizeUTLS(p.UTLS) {
	case "", UTLSNone, UTLSChrome, UTLSFirefox, UTLSSafari, UTLSRandomized:
	default:
		return fmt.Errorf("obfs: unknown UTLS fingerprint %q", p.UTLS)
	}
	if p.FragSizes != nil && len(p.FragSizes) == 0 {
		return errors.New("obfs: FragSizes is non-nil but empty: use nil to disable fragmentation")
	}
	for i, s := range p.FragSizes {
		if s <= 0 {
			return fmt.Errorf("obfs: FragSizes[%d] = %d: must be positive", i, s)
		}
		if s > MaxFragmentSize {
			return fmt.Errorf("obfs: FragSizes[%d] = %d: exceeds max TLS record payload %d", i, s, MaxFragmentSize)
		}
	}
	if p.FragDelay < 0 {
		return fmt.Errorf("obfs: FragDelay = %s: must not be negative", p.FragDelay)
	}
	if p.Jitter < 0 {
		return fmt.Errorf("obfs: Jitter = %s: must not be negative", p.Jitter)
	}
	if p.FakeSNI != "" && !validHostname(p.FakeSNI) {
		return fmt.Errorf("obfs: FakeSNI %q is not a valid hostname", p.FakeSNI)
	}
	return nil
}

// Clamp returns a copy of the profile with delays limited to their maxima.
func (p Profile) Clamp() Profile {
	if p.FragDelay > MaxFragDelay {
		p.FragDelay = MaxFragDelay
	}
	if p.Jitter > MaxJitter {
		p.Jitter = MaxJitter
	}
	return p
}

// Fragmentation reports whether ClientHello fragmentation is enabled.
func (p Profile) Fragmentation() bool { return len(p.FragSizes) > 0 }

// UTLSEnabled reports whether a uTLS fingerprint is selected.
func (p Profile) UTLSEnabled() bool {
	switch normalizeUTLS(p.UTLS) {
	case UTLSChrome, UTLSFirefox, UTLSSafari, UTLSRandomized:
		return true
	}
	return false
}

func normalizeUTLS(s string) string {
	return strings.ToLower(strings.TrimSpace(s))
}

// validHostname reports whether s is a syntactically valid DNS hostname
// (LDH labels, no leading/trailing hyphen, total length within limits).
func validHostname(s string) bool {
	if len(s) == 0 || len(s) > 253 {
		return false
	}
	for _, label := range strings.Split(s, ".") {
		if len(label) == 0 || len(label) > 63 {
			return false
		}
		if label[0] == '-' || label[len(label)-1] == '-' {
			return false
		}
		for i := 0; i < len(label); i++ {
			c := label[i]
			if !(c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-') {
				return false
			}
		}
	}
	return true
}
