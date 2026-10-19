package obfs

import (
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestPresetsValidate(t *testing.T) {
	for name, p := range map[string]Profile{
		"fast":     PresetFast,
		"balanced": PresetBalanced,
		"max":      PresetMax,
	} {
		if err := p.Validate(); err != nil {
			t.Errorf("preset %s: Validate: %v", name, err)
		}
		if got := p.Clamp(); !reflect.DeepEqual(got, p) {
			t.Errorf("preset %s: not clamp-idempotent: %+v -> %+v", name, p, got)
		}
	}
	if PresetFast.Fragmentation() {
		t.Error("PresetFast must not fragment")
	}
	if !PresetBalanced.Fragmentation() || !PresetMax.Fragmentation() {
		t.Error("PresetBalanced/PresetMax must fragment")
	}
}

func TestValidate(t *testing.T) {
	valid := []Profile{
		{},
		{UTLS: "chrome"},
		{UTLS: "Chrome"}, // case-insensitive
		{UTLS: " NONE "}, // surrounding whitespace tolerated
		{UTLS: "randomized", FragSizes: []int{64}, FragDelay: time.Second, Jitter: time.Second, FakeSNI: "decoy.example"},
		{UTLS: "safari", FakeSNI: "a.b-c.example.com"},
		{FragSizes: []int{1, MaxFragmentSize}},
		{Jitter: 24 * time.Hour}, // monstrous but clampable, not invalid
	}
	for i, p := range valid {
		if err := p.Validate(); err != nil {
			t.Errorf("valid[%d] (%+v): unexpected error: %v", i, p, err)
		}
	}

	invalid := []struct {
		name string
		p    Profile
		want string
	}{
		{"unknown fingerprint", Profile{UTLS: "opera"}, "unknown UTLS"},
		{"empty fingerprint gibberish", Profile{UTLS: "chr0me"}, "unknown UTLS"},
		{"empty non-nil frag sizes", Profile{FragSizes: []int{}}, "empty"},
		{"zero frag size", Profile{FragSizes: []int{0}}, "positive"},
		{"negative frag size", Profile{FragSizes: []int{-5}}, "positive"},
		{"oversize frag size", Profile{FragSizes: []int{MaxFragmentSize + 1}}, "exceeds"},
		{"negative frag delay", Profile{FragDelay: -time.Second}, "negative"},
		{"negative jitter", Profile{Jitter: -time.Millisecond}, "negative"},
		{"fake SNI empty label", Profile{FakeSNI: "a..example.com"}, "valid hostname"},
		{"fake SNI leading hyphen", Profile{FakeSNI: "-bad.example.com"}, "valid hostname"},
		{"fake SNI space", Profile{FakeSNI: "bad name.com"}, "valid hostname"},
		{"fake SNI too long", Profile{FakeSNI: strings.Repeat("a", 64) + ".com"}, "valid hostname"},
		{"fake SNI IPv4 literal", Profile{FakeSNI: "1.2.3.4"}, "valid hostname"},
		{"fake SNI IPv6 literal", Profile{FakeSNI: "::1"}, "valid hostname"},
	}
	for _, tc := range invalid {
		t.Run(tc.name, func(t *testing.T) {
			err := tc.p.Validate()
			if err == nil {
				t.Fatalf("expected error containing %q, got nil", tc.want)
			}
			if !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("error %q does not contain %q", err, tc.want)
			}
		})
	}
}

func TestClamp(t *testing.T) {
	p := Profile{FragDelay: 10 * time.Second, Jitter: time.Hour}.Clamp()
	if p.FragDelay != MaxFragDelay {
		t.Errorf("FragDelay = %s, want %s", p.FragDelay, MaxFragDelay)
	}
	if p.Jitter != MaxJitter {
		t.Errorf("Jitter = %s, want %s", p.Jitter, MaxJitter)
	}
	// Exact maxima are left alone; normal values untouched.
	p2 := Profile{FragDelay: MaxFragDelay, Jitter: 100 * time.Millisecond}.Clamp()
	if p2.FragDelay != MaxFragDelay || p2.Jitter != 100*time.Millisecond {
		t.Errorf("Clamp touched in-range values: %+v", p2)
	}
}

func TestUTLSEnabled(t *testing.T) {
	for _, name := range []string{"chrome", "firefox", "safari", "randomized"} {
		if !(Profile{UTLS: name}).UTLSEnabled() {
			t.Errorf("%s: expected UTLS enabled", name)
		}
	}
	for _, name := range []string{"", "none", "opera"} {
		if (Profile{UTLS: name}).UTLSEnabled() {
			t.Errorf("%s: expected UTLS disabled", name)
		}
	}
}
