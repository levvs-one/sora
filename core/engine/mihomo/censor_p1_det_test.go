package mihomo

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// TestCensorP1RenderDeterministicXHTTP pins field-order determinism
// for the XHTTP+REALITY surface (мелочи): two renders of one plan
// are byte-identical. The mihomo renderer itself is unchanged by
// CENSOR-P1 (it already emitted the full XHTTP surface); this test
// extends the determinism guarantee to the exact plan shape the
// Xray and sing-box legs gained parity for.
func TestCensorP1RenderDeterministicXHTTP(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Flow = "" // XHTTP cannot carry Vision; REALITY stays
	p.Outbounds[0].Transport = engine.Transport{
		Type: "xhttp", Mode: "stream-up", Path: "/xh",
		XmuxMaxConcurrency: 16, XmuxMaxReuseTimes: 10,
		XPaddingBytes: "100-1000",
	}
	a, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	b, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatal(err)
	}
	if a != b {
		t.Fatal("two renders of one plan differ")
	}
}
