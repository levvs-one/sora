package engine

import (
	"strings"
	"testing"
)

func TestNormalizeFingerprint(t *testing.T) {
	cases := map[string]string{
		"chrome":   "chrome",
		"Chrome":   "chrome",
		" CHROME ": "chrome",
		"iOS":      "ios",
		"":         "",
		"  ":       "",
	}
	for in, want := range cases {
		if got := NormalizeFingerprint(in); got != want {
			t.Errorf("NormalizeFingerprint(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestIsKnownFingerprint(t *testing.T) {
	for _, known := range KnownFingerprints {
		if !IsKnownFingerprint(known) {
			t.Errorf("IsKnownFingerprint(%q) = false, want true", known)
		}
	}
	// Empty means "not configured" and is valid.
	if !IsKnownFingerprint("") {
		t.Error("IsKnownFingerprint(\"\") = false, want true")
	}
	for _, unknown := range []string{"opera", "hellochrome_155", "randomized", "chrome133"} {
		if IsKnownFingerprint(unknown) {
			t.Errorf("IsKnownFingerprint(%q) = true, want false", unknown)
		}
	}
}

func TestIsVersionedParrot(t *testing.T) {
	for _, v := range []string{"hellochrome_155", "HelloChrome_131", "hellofirefox_120", "helloios_auto"} {
		if !IsVersionedParrot(v) {
			t.Errorf("IsVersionedParrot(%q) = false, want true", v)
		}
	}
	for _, v := range []string{"chrome", "random", "hellochrome_", "hellonokia_3310"} {
		if IsVersionedParrot(v) {
			t.Errorf("IsVersionedParrot(%q) = true, want false", v)
		}
	}
}

func TestFingerprintWarning(t *testing.T) {
	if w := FingerprintWarning(""); w != "" {
		t.Errorf("empty fingerprint should not warn, got %q", w)
	}
	if w := FingerprintWarning("chrome"); w != "" {
		t.Errorf("known fingerprint should not warn, got %q", w)
	}
	if w := FingerprintWarning("hellochrome_131"); w == "" {
		t.Error("stale versioned parrot should warn")
	}
	if w := FingerprintWarning("hellochrome_131"); !strings.Contains(w, "stale") {
		t.Errorf("stale parrot warning should say stale, got %q", w)
	}
	if w := FingerprintWarning("hellochrome_155"); w == "" {
		t.Error("engine-specific current parrot should still note engine-specificity")
	}
	if w := FingerprintWarning("definitely-not-a-fingerprint"); w == "" {
		t.Error("unknown fingerprint should warn")
	}
}

func TestParrotFreshness(t *testing.T) {
	// Aliases carry no version: their bytes depend on the engine's uTLS.
	for _, alias := range []string{"chrome", "firefox", "hellochrome_auto", ""} {
		if v := ParrotVersion(alias); v != 0 {
			t.Errorf("ParrotVersion(%q) = %d, want 0 (alias/unknown)", alias, v)
		}
		if IsStaleParrot(alias) {
			t.Errorf("IsStaleParrot(%q) = true, want false (cannot know)", alias)
		}
	}
	stale := map[string]int{"hellochrome_120": 120, "hellochrome_131": 131, "HelloChrome_133": 133}
	for name, want := range stale {
		if v := ParrotVersion(name); v != want {
			t.Errorf("ParrotVersion(%q) = %d, want %d", name, v, want)
		}
		if !IsStaleParrot(name) {
			t.Errorf("IsStaleParrot(%q) = false, want true", name)
		}
	}
	if v := ParrotVersion("hellochrome_155"); v != CurrentChromeVersion {
		t.Errorf("ParrotVersion(hellochrome_155) = %d, want %d", v, CurrentChromeVersion)
	}
	if IsStaleParrot("hellochrome_155") {
		t.Error("IsStaleParrot(hellochrome_155) = true, want false (current)")
	}
	// The Xray default must name the auto parrot, never a pinned version.
	if DefaultXrayFingerprint != "hellochrome_auto" {
		t.Errorf("DefaultXrayFingerprint = %q, want hellochrome_auto", DefaultXrayFingerprint)
	}
}

func TestKnownMissingPQKeyShare(t *testing.T) {
	// Only an explicit pre-131 Chrome parrot is a proven-missing key
	// share. Everything else — aliases resolving to current parrots,
	// Chrome 131+, and names sora cannot judge — is "no claim", false.
	if !KnownMissingPQKeyShare("hellochrome_120") {
		t.Error(`KnownMissingPQKeyShare("hellochrome_120") = false, want true (pre-PQ parrot)`)
	}
	for _, name := range []string{"chrome", "hellochrome_auto", "hellochrome_131", "hellochrome_133", "hellochrome_155", "firefox", "safari", "random", "hellochrome_999", "not-a-fingerprint"} {
		if KnownMissingPQKeyShare(name) {
			t.Errorf("KnownMissingPQKeyShare(%q) = true, want false (no claim)", name)
		}
	}
}

func TestIsRandomizedFingerprint(t *testing.T) {
	for _, name := range []string{"random", "randomized", "Randomized", "hellorandomizedalpn"} {
		if !IsRandomizedFingerprint(name) {
			t.Errorf("IsRandomizedFingerprint(%q) = false, want true", name)
		}
	}
	for _, name := range []string{"chrome", "firefox", "hellochrome_155", ""} {
		if IsRandomizedFingerprint(name) {
			t.Errorf("IsRandomizedFingerprint(%q) = true, want false", name)
		}
	}
}
