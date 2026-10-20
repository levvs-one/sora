package engine

import (
	"strings"
	"testing"
)

// TestXPaddingBytesGate is the S2 seams regression for XHTTP
// padding, updated for the CENSOR-P1 feature split: padding rides
// its OWN gate (FeatureXHTTPPadding), separate from the xmux tuning
// gate it shared while only one renderer emitted it. A padding-only
// plan requires FeatureXHTTPPadding and not FeatureXHTTPXmux; all
// three renderers emit the range now (mihomo x-padding-bytes, Xray
// xPaddingBytes, sing-box-lx x_padding_bytes — the sing-box claim
// rides the probed lx build, like FeatureXHTTP itself).
func TestXPaddingBytesGate(t *testing.T) {
	p := validPlan()
	p.Outbounds = p.Outbounds[:1]
	p.Outbounds[0].Transport.Type = "xhttp"
	p.Outbounds[0].Transport.XPaddingBytes = "100-1000"

	req := p.RequiredFeatures()
	if !req[FeatureXHTTPPadding] {
		t.Fatal("a plan setting XPaddingBytes must require FeatureXHTTPPadding")
	}
	if req[FeatureXHTTPXmux] {
		t.Fatal("a padding-only plan must not require the xmux feature (independent data, independent gate)")
	}
	for _, kind := range []Kind{KindMihomo, KindXray} {
		if missing := strings.Join(Catalog[kind].Missing(p), " "); strings.Contains(missing, string(FeatureXHTTPPadding)) {
			t.Errorf("%s renders the padding range, it must not report it missing: %q", kind, missing)
		}
	}
	lx := BuildCapabilities(KindSingBox,
		Version{Raw: "1.14.3-lx.22", Major: 1, Minor: 14, Patch: 3, PreRelease: "lx.22"},
		[]string{"with_xhttp"})
	if missing := strings.Join(lx.Missing(p), " "); strings.Contains(missing, string(FeatureXHTTPPadding)) {
		t.Errorf("the lx build renders x_padding_bytes, it must not report it missing: %q", missing)
	}
	if missing := strings.Join(Catalog[KindSingBox].Missing(p), " "); !strings.Contains(missing, string(FeatureXHTTPPadding)) {
		t.Errorf("upstream sing-box must report %s missing, got %q", FeatureXHTTPPadding, missing)
	}
}
