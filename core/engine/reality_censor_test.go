package engine

import (
	"strings"
	"testing"
)

// TestCensorP1SpiderXValidation pins the one spiderX shape rule the
// pinned Xray binary itself enforces (probed 2026-10-20): the value
// must start with "/". Spaces, query strings and multi-KB paths all
// load on the binary, so validation must not invent stricter rules
// that reject engine-valid configs.
func TestCensorP1SpiderXValidation(t *testing.T) {
	for _, ok := range []string{"", "/", "/spider", "/a b", "/a?x=1#y", "/" + strings.Repeat("a", 8000)} {
		o := realityOutbound()
		o.TLS.SpiderX = ok
		if err := o.ValidateReality(); err != nil {
			t.Errorf("SpiderX %q...: ValidateReality = %v, want nil", ok[:min(len(ok), 12)], err)
		}
	}
	for _, bad := range []string{"spider", "a/b", "https://example.com/"} {
		o := realityOutbound()
		o.TLS.SpiderX = bad
		err := o.ValidateReality()
		if err == nil || !strings.Contains(err.Error(), "spiderX must start with") {
			t.Errorf("SpiderX %q: ValidateReality = %v, want a spiderX error", bad, err)
		}
	}
	// The value is an identifier: it must not leak into the error
	// text (checked with a distinctive token the field name and the
	// message cannot contain by accident).
	o := realityOutbound()
	o.TLS.SpiderX = "leakme-no-leading-slash"
	if err := o.ValidateReality(); err == nil || strings.Contains(err.Error(), "leakme") {
		t.Errorf("spiderX error must not leak the value, got %v", err)
	}
}

// TestCensorP1RealityFingerprintWarnings pins the fingerprint half of
// RealityWarnings: the stale/randomized parrot mistakes the file's
// header lists were never surfaced as codes before CENSOR-P1.
func TestCensorP1RealityFingerprintWarnings(t *testing.T) {
	cases := []struct {
		fp       string
		want     []string
		wantNone []string
	}{
		{"random", []string{"reality-fingerprint-randomized"}, nil},
		{"randomized", []string{"reality-fingerprint-randomized"}, nil},
		{"hellochrome_120", []string{"reality-fingerprint-stale", "reality-fingerprint-no-pq-key-share"}, nil},
		{"hellochrome_133", []string{"reality-fingerprint-stale"}, []string{"reality-fingerprint-no-pq-key-share"}},
		{"hellochrome_155", nil, []string{"reality-fingerprint-stale", "reality-fingerprint-randomized"}},
		{"chrome", nil, []string{"reality-fingerprint-stale", "reality-fingerprint-randomized", "reality-fingerprint-no-pq-key-share"}},
		{"hellochrome_auto", nil, []string{"reality-fingerprint-stale", "reality-fingerprint-randomized", "reality-fingerprint-no-pq-key-share"}},
		{"", nil, []string{"reality-fingerprint-stale", "reality-fingerprint-randomized", "reality-fingerprint-no-pq-key-share"}},
	}
	for _, tc := range cases {
		o := realityOutbound()
		o.TLS.Fingerprint = tc.fp
		w := o.RealityWarnings()
		for _, want := range tc.want {
			if !contains(w, want) {
				t.Errorf("fp %q: warnings %v lack %q", tc.fp, w, want)
			}
		}
		for _, notWant := range tc.wantNone {
			if contains(w, notWant) {
				t.Errorf("fp %q: warnings %v must not contain %q", tc.fp, w, notWant)
			}
		}
	}
}

// TestCensorP1ShortIDBoundaries pins the shortId boundary values
// (мелочи): unset, the 1-byte minimum, the 8-byte maximum, and the
// shapes on the far side of each boundary — odd length, over-length,
// non-hex. The engine boundary agrees (probed: a 17-char shortId
// fails Xray's config load).
func TestCensorP1ShortIDBoundaries(t *testing.T) {
	for _, ok := range []string{"", "ab", "0123456789abcdef"} {
		o := realityOutbound()
		o.TLS.RealityShortID = ok
		if err := o.ValidateReality(); err != nil {
			t.Errorf("shortId %q: ValidateReality = %v, want nil", ok, err)
		}
	}
	for _, bad := range []string{"abc", "0123456789abcdef00", "zz", "0g"} {
		o := realityOutbound()
		o.TLS.RealityShortID = bad
		if err := o.ValidateReality(); err == nil {
			t.Errorf("shortId %q: ValidateReality = nil, want an error", bad)
		}
	}
}

// TestCensorP1RealityMuxExcludesXHTTP pins the mux fix proven by
// traffic in interop: XHTTP multiplexes itself (xmux), so the
// REALITY mux default must not layer outbound mux over it, while
// stream transports keep the default.
func TestCensorP1RealityMuxExcludesXHTTP(t *testing.T) {
	o := realityOutbound()
	o.Transport.Type = "xhttp"
	if RealityMux(o, MuxOptions{}) {
		t.Error("mux default must not apply over XHTTP (the transport multiplexes itself)")
	}
	for _, typ := range []string{"", "ws", "grpc", "httpupgrade"} {
		o.Transport.Type = typ
		if !RealityMux(o, MuxOptions{}) {
			t.Errorf("transport %q: REALITY mux default must stay", typ)
		}
	}
}

// TestCensorP1KeyShareGate pins the selection side of the KeyShare
// fix end-to-end: a plan pinning the share requires the feature, the
// two engines that spell it carry the plan, Xray reports it missing.
func TestCensorP1KeyShareGate(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Outbounds[0].TLS.KeyShare = "hybrid"
	if !p.RequiredFeatures()[FeatureRealityKeyShare] {
		t.Fatal("a plan pinning KeyShare must require FeatureRealityKeyShare")
	}
	for _, kind := range []Kind{KindSingBox, KindMihomo} {
		if missing := strings.Join(Catalog[kind].Missing(p), " "); strings.Contains(missing, string(FeatureRealityKeyShare)) {
			t.Errorf("%s spells key_share and must not report it missing: %q", kind, missing)
		}
	}
	if missing := strings.Join(Catalog[KindXray].Missing(p), " "); !strings.Contains(missing, string(FeatureRealityKeyShare)) {
		t.Errorf("xray must report %s missing, got %q", FeatureRealityKeyShare, missing)
	}
}
