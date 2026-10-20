package singbox

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// CENSOR-FP: the REALITY key-share choice renders as
// tls.reality.key_share on sing-box (the third leg of PASS2 S3), and
// the fingerprint resolves through the shared policy — a versioned
// Xray parrot name degrades to the browser alias this binary accepts
// instead of failing its config load.
func TestRenderRealityKeyShareAndPolicySpelling(t *testing.T) {
	first := func(cfg map[string]any) map[string]any {
		return cfg["outbounds"].([]any)[0].(map[string]any)
	}
	p := enginetest.Plan(engine.ProtocolVLESS)
	o := &p.Outbounds[0]
	o.TLS.KeyShare = "classical"
	o.TLS.Fingerprint = "hellochrome_133"
	tls := first(render(t, p))["tls"].(map[string]any)
	reality := tls["reality"].(map[string]any)
	if reality["key_share"] != "classical" {
		t.Errorf("reality.key_share = %v, want classical", reality["key_share"])
	}
	utls := tls["utls"].(map[string]any)
	if utls["fingerprint"] != "chrome" {
		t.Errorf("utls.fingerprint = %v, want the chrome alias (versioned names are refused by this binary)", utls["fingerprint"])
	}
	// Unset key share renders no key at all (engine default).
	reality2 := first(render(t, enginetest.Plan(engine.ProtocolVLESS)))["tls"].(map[string]any)["reality"].(map[string]any)
	if _, has := reality2["key_share"]; has {
		t.Errorf("key_share must be absent when the plan does not pin it, got %v", reality2)
	}
}
