package obfs

import (
	"errors"
	"fmt"
	"time"

	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
)

// ProfileFromProto converts a normalized sora.obfs.v1.ObfuscationProfile
// into the internal Profile that masks handshakes the core initiates
// itself (probing, DoH, subscription fetches).
//
// The input must be normalized — the form ApplyObfsProfile stores, with
// the preset expanded and explicit fields winning. A raw preset-only
// profile converts by its explicit fields alone (which is empty for
// LIGHT/BALANCED/AGGRESSIVE), because preset expansion is the control
// plane's job and duplicating it here would let the two drift. Preset OFF
// converts to the zero Profile: disabled.
//
// uTLS profiles the internal wrapper cannot render (ios, android, edge,
// 360, qq, random) are an error, not a silent substitution: sending a
// chrome parrot while claiming an ios one would lie about the wire image.
// Delays are clamped to the internal maxima (see Clamp), which are
// stricter than the control plane's 10s ceiling; the result always passes
// Validate.
func ProfileFromProto(p *obfsv1.ObfuscationProfile) (Profile, error) {
	if p == nil {
		return Profile{}, errors.New("obfs: no profile to convert")
	}
	if p.GetPreset() == obfsv1.ObfsPreset_OBFS_PRESET_OFF {
		return Profile{}, nil
	}
	utls, err := protoUTLSName(p.GetUtlsProfile())
	if err != nil {
		return Profile{}, err
	}
	sizes := p.GetFragSizes()
	var frag []int
	if len(sizes) > 0 {
		frag = make([]int, 0, len(sizes))
		for _, s := range sizes {
			if s < 1 || s > MaxFragmentSize {
				return Profile{}, fmt.Errorf("obfs: fragment size %d is outside 1..%d", s, MaxFragmentSize)
			}
			frag = append(frag, int(s))
		}
	}
	out := Profile{
		UTLS:      utls,
		FragSizes: frag,
		FragDelay: time.Duration(p.GetFragDelayMs()) * time.Millisecond,
		Jitter:    time.Duration(p.GetJitterMs()) * time.Millisecond,
		FakeSNI:   p.GetFakeSni(),
	}.Clamp()
	if err := out.Validate(); err != nil {
		return Profile{}, err
	}
	return out, nil
}

// protoUTLSName maps the wire enum to the fingerprint name the internal
// wrapper renders. UNSPECIFIED means "no fingerprint", like the empty
// string.
func protoUTLSName(p obfsv1.UtlsProfile) (string, error) {
	switch p {
	case obfsv1.UtlsProfile_UTLS_PROFILE_UNSPECIFIED:
		return "", nil
	case obfsv1.UtlsProfile_UTLS_PROFILE_CHROME:
		return UTLSChrome, nil
	case obfsv1.UtlsProfile_UTLS_PROFILE_FIREFOX:
		return UTLSFirefox, nil
	case obfsv1.UtlsProfile_UTLS_PROFILE_SAFARI:
		return UTLSSafari, nil
	case obfsv1.UtlsProfile_UTLS_PROFILE_RANDOMIZED:
		return UTLSRandomized, nil
	default:
		return "", fmt.Errorf("obfs: uTLS profile %s has no internal parrot; the core-initiated wrapper renders chrome, firefox, safari and randomized only", p)
	}
}
