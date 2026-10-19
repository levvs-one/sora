package engine

import "testing"

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
	if w := FingerprintWarning("definitely-not-a-fingerprint"); w == "" {
		t.Error("unknown fingerprint should warn")
	}
}
