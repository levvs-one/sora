package engine

import "testing"

func TestResolveFingerprintDefaults(t *testing.T) {
	reality := Outbound{TLS: TLS{Reality: true}}
	// REALITY needs a parrot on every engine; the defaults differ per
	// engine by design (Xray's "chrome" is the stale Chrome 133).
	if got := ResolveFingerprint(KindXray, reality, FingerprintPolicy{}); got != DefaultXrayFingerprint {
		t.Errorf("xray reality default = %q, want %q", got, DefaultXrayFingerprint)
	}
	for _, k := range []Kind{KindSingBox, KindMihomo} {
		if got := ResolveFingerprint(k, reality, FingerprintPolicy{}); got != DefaultFingerprint {
			t.Errorf("%s reality default = %q, want %q", k, got, DefaultFingerprint)
		}
	}
	// Plain TLS without a policy names no fingerprint: the engines'
	// own stacks apply.
	plain := Outbound{TLS: TLS{Enabled: true}}
	if got := ResolveFingerprint(KindSingBox, plain, FingerprintPolicy{}); got != "" {
		t.Errorf("plain TLS default = %q, want empty", got)
	}
}

func TestResolveFingerprintExplicitAndPolicy(t *testing.T) {
	o := Outbound{Protocol: ProtocolVLESS, TLS: TLS{Reality: true, Fingerprint: " HelloChrome_133 "}}
	if got := ResolveFingerprint(KindXray, o, FingerprintPolicy{}); got != "hellochrome_133" {
		t.Errorf("explicit normalized = %q, want hellochrome_133", got)
	}
	// The same explicit versioned parrot on sing-box degrades to the
	// browser alias (the binary rejects versioned names, probed).
	if got := ResolveFingerprint(KindSingBox, o, FingerprintPolicy{}); got != "chrome" {
		t.Errorf("sing-box spelling of versioned parrot = %q, want chrome alias", got)
	}
	pol := FingerprintPolicy{Default: "safari", PerProtocol: map[Protocol]string{ProtocolVLESS: "firefox"}}
	if got := ResolveFingerprint(KindMihomo, o, pol); got != "chrome" {
		t.Errorf("explicit must beat policy, got %q", got)
	}
	o.TLS.Fingerprint = ""
	if got := ResolveFingerprint(KindMihomo, o, pol); got != "firefox" {
		t.Errorf("per-protocol profile = %q, want firefox", got)
	}
	o.Protocol = ProtocolTrojan
	if got := ResolveFingerprint(KindMihomo, o, pol); got != "safari" {
		t.Errorf("policy default = %q, want safari", got)
	}
	// "hellochrome_auto" on a non-Xray engine spells as its alias.
	auto := Outbound{TLS: TLS{Reality: true, Fingerprint: "hellochrome_auto"}}
	if got := ResolveFingerprint(KindSingBox, auto, FingerprintPolicy{}); got != "chrome" {
		t.Errorf("auto on sing-box = %q, want chrome", got)
	}
	rnd := Outbound{TLS: TLS{Reality: true, Fingerprint: "hellorandomized"}}
	if got := ResolveFingerprint(KindSingBox, rnd, FingerprintPolicy{}); got != "randomized" {
		t.Errorf("hellorandomized on sing-box = %q, want randomized", got)
	}
}

func TestFingerprintPolicyValidate(t *testing.T) {
	if err := (FingerprintPolicy{}).Validate(); err != nil {
		t.Errorf("zero policy must validate, got %v", err)
	}
	if err := (FingerprintPolicy{Mode: "spin"}).Validate(); err == nil {
		t.Error("unknown mode must be rejected")
	}
	// Rotate without profiles is valid data: the canonical rotation
	// applies (Profiles documents the empty case as such).
	if err := (FingerprintPolicy{Mode: FingerprintRotate}).Validate(); err != nil {
		t.Errorf("rotate without profiles must validate (canonical rotation), got %v", err)
	}
	if err := (FingerprintPolicy{Mode: FingerprintRotate, Profiles: []string{"chrome", "bogus"}}).Validate(); err == nil {
		t.Error("unknown rotation profile must be rejected")
	}
	if err := (FingerprintPolicy{Mode: FingerprintRotate, Profiles: CanonicalRotation}).Validate(); err != nil {
		t.Errorf("canonical rotation must validate, got %v", err)
	}
	if err := (FingerprintPolicy{PerProtocol: map[Protocol]string{"nope": "chrome"}}).Validate(); err == nil {
		t.Error("unknown protocol must be rejected")
	}
}

func TestRotationForSpelling(t *testing.T) {
	rot := RotationFor(KindSingBox, FingerprintPolicy{})
	if len(rot) == 0 || rot[0] != DefaultFingerprint {
		t.Errorf("sing-box rotation = %v, want it to start at the canonical default %q", rot, DefaultFingerprint)
	}
	for _, fp := range rot {
		if IsVersionedParrot(fp) {
			t.Errorf("sing-box rotation carries versioned parrot %q the binary rejects", fp)
		}
	}
	xr := RotationFor(KindXray, FingerprintPolicy{})
	if len(xr) == 0 || xr[0] != DefaultXrayFingerprint {
		t.Errorf("xray rotation = %v, want it to start at %q", xr, DefaultXrayFingerprint)
	}
}
