package xray

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// TestCensorP1XrayRefusesKeyShare pins the render-side fail-closed
// behind the FeatureRealityKeyShare gate: Xray has no key_share knob,
// so a direct render must refuse instead of silently offering the
// parrot's default shares.
func TestCensorP1XrayRefusesKeyShare(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].TLS.KeyShare = "classical"
	if _, err := Render(p, testRuntime, nil); err == nil || !strings.Contains(err.Error(), "key_share") {
		t.Fatalf("Render = %v, want a key_share refusal", err)
	}
}

// TestCensorP1SpiderXDefault pins the unified default: an unset
// SpiderX renders the shared engine.DefaultSpiderX on the wire, an
// explicit one wins verbatim.
func TestCensorP1SpiderXDefault(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(raw), `"spiderX":"`+engine.DefaultSpiderX+`"`) {
		t.Fatalf("unset spiderX must render the shared default %q:\n%s", engine.DefaultSpiderX, raw)
	}
	p.Outbounds[0].TLS.SpiderX = "/custom-spider"
	raw, err = Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(raw), `"spiderX":"/custom-spider"`) {
		t.Fatalf("explicit spiderX must win:\n%s", raw)
	}
}
