package engine

import (
	"strings"
	"testing"
)

// TestXPaddingBytesRequiresXmuxCapability pins the S2 seams fix: a plan
// that sets only XPaddingBytes (no xmux tuning fields) must still
// require FeatureXHTTPXmux. Only the mihomo renderer emits
// x-padding-bytes; the Xray and sing-box renderers drop the value at
// render time, so without this gate a padding-only plan routed to
// either of them silently lost its padding while validation passed —
// the same silent-loss class the xmux gate closed for the tuning
// fields (PASS3 deep S1).
func TestXPaddingBytesRequiresXmuxCapability(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Outbounds[0].Transport = Transport{Type: "xhttp", Path: "/x", XPaddingBytes: "100-1000"}

	if !p.RequiredFeatures()[FeatureXHTTPXmux] {
		t.Fatal("a padding-only xhttp plan must require FeatureXHTTPXmux")
	}
	// The two renderers that emit no x-padding-bytes must report the
	// feature missing, whatever the catalog's mihomo claim state is.
	for _, kind := range []Kind{KindXray, KindSingBox} {
		missing := strings.Join(Catalog[kind].Missing(p), " ")
		if !strings.Contains(missing, string(FeatureXHTTPXmux)) {
			t.Errorf("%s: padding-only plan must report %s missing, got %q", kind, FeatureXHTTPXmux, missing)
		}
	}
	// A plain xhttp plan without padding or xmux tuning must not
	// suddenly require the feature.
	plain := validPlan()
	plain.Outbounds = plain.Outbounds[:1]
	plain.Outbounds[0].Transport = Transport{Type: "xhttp", Path: "/x"}
	if plain.RequiredFeatures()[FeatureXHTTPXmux] {
		t.Error("an untuned xhttp plan must not require FeatureXHTTPXmux")
	}
}
