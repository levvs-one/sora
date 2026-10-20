package obfs

import (
	"reflect"
	"strings"
	"testing"
	"time"

	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
)

func TestProfileFromProto(t *testing.T) {
	// A normalized BALANCED profile: preset expanded, explicit fields won.
	balanced := &obfsv1.ObfuscationProfile{
		Preset:      obfsv1.ObfsPreset_OBFS_PRESET_BALANCED,
		UtlsProfile: obfsv1.UtlsProfile_UTLS_PROFILE_CHROME,
		FragSizes:   []uint32{100, 300},
		FragDelayMs: 10,
		JitterMs:    10,
	}
	got, err := ProfileFromProto(balanced)
	if err != nil {
		t.Fatalf("ProfileFromProto: %v", err)
	}
	want := Profile{
		UTLS:      UTLSChrome,
		FragSizes: []int{100, 300},
		FragDelay: 10 * time.Millisecond,
		Jitter:    10 * time.Millisecond,
	}
	if got.UTLS != want.UTLS || len(got.FragSizes) != 2 || got.FragSizes[0] != 100 ||
		got.FragSizes[1] != 300 || got.FragDelay != want.FragDelay || got.Jitter != want.Jitter ||
		got.FakeSNI != "" {
		t.Errorf("ProfileFromProto = %+v, want %+v", got, want)
	}

	// Preset OFF disables the suite.
	off, err := ProfileFromProto(&obfsv1.ObfuscationProfile{
		Preset: obfsv1.ObfsPreset_OBFS_PRESET_OFF,
	})
	if err != nil {
		t.Fatalf("OFF: %v", err)
	}
	if !reflect.DeepEqual(off, Profile{}) {
		t.Errorf("OFF = %+v, want zero profile", off)
	}

	// Nil is a caller bug, not a disabled profile.
	if _, err := ProfileFromProto(nil); err == nil {
		t.Error("nil profile: want error")
	}
}

func TestProfileFromProtoUTLS(t *testing.T) {
	cases := map[obfsv1.UtlsProfile]string{
		obfsv1.UtlsProfile_UTLS_PROFILE_UNSPECIFIED: "",
		obfsv1.UtlsProfile_UTLS_PROFILE_CHROME:      UTLSChrome,
		obfsv1.UtlsProfile_UTLS_PROFILE_FIREFOX:     UTLSFirefox,
		obfsv1.UtlsProfile_UTLS_PROFILE_SAFARI:      UTLSSafari,
		obfsv1.UtlsProfile_UTLS_PROFILE_RANDOMIZED:  UTLSRandomized,
	}
	for in, want := range cases {
		p, err := ProfileFromProto(&obfsv1.ObfuscationProfile{UtlsProfile: in})
		if err != nil {
			t.Errorf("%s: %v", in, err)
			continue
		}
		if p.UTLS != want {
			t.Errorf("%s: UTLS = %q, want %q", in, p.UTLS, want)
		}
		if _, err := p.FingerprintID(); want != "" && err != nil {
			t.Errorf("%s: converted profile has no parrot: %v", in, err)
		}
	}
	// Engine-only parrots have no internal rendering: honest error, never
	// a silent substitution.
	for _, in := range []obfsv1.UtlsProfile{
		obfsv1.UtlsProfile_UTLS_PROFILE_IOS,
		obfsv1.UtlsProfile_UTLS_PROFILE_ANDROID,
		obfsv1.UtlsProfile_UTLS_PROFILE_EDGE,
		obfsv1.UtlsProfile_UTLS_PROFILE_360,
		obfsv1.UtlsProfile_UTLS_PROFILE_QQ,
		obfsv1.UtlsProfile_UTLS_PROFILE_RANDOM,
	} {
		if _, err := ProfileFromProto(&obfsv1.ObfuscationProfile{UtlsProfile: in}); err == nil {
			t.Errorf("%s: want error for unrenderable parrot", in)
		}
	}
}

func TestProfileFromProtoClampsDelays(t *testing.T) {
	// The control plane allows up to 10s; the internal wrapper clamps to
	// its own maxima instead of rejecting.
	p, err := ProfileFromProto(&obfsv1.ObfuscationProfile{
		UtlsProfile: obfsv1.UtlsProfile_UTLS_PROFILE_CHROME,
		FragSizes:   []uint32{64},
		FragDelayMs: 9000,
		JitterMs:    9000,
	})
	if err != nil {
		t.Fatalf("ProfileFromProto: %v", err)
	}
	if p.FragDelay != MaxFragDelay {
		t.Errorf("FragDelay = %s, want clamp to %s", p.FragDelay, MaxFragDelay)
	}
	if p.Jitter != MaxJitter {
		t.Errorf("Jitter = %s, want clamp to %s", p.Jitter, MaxJitter)
	}
}

func TestProfileFromProtoRejectsGarbage(t *testing.T) {
	if _, err := ProfileFromProto(&obfsv1.ObfuscationProfile{
		FragSizes: []uint32{0},
	}); err == nil || !strings.Contains(err.Error(), "fragment size") {
		t.Errorf("zero frag size: want range error, got %v", err)
	}
	if _, err := ProfileFromProto(&obfsv1.ObfuscationProfile{
		FakeSni: "not a hostname!!",
	}); err == nil {
		t.Error("bad fake_sni: want error")
	}
}
