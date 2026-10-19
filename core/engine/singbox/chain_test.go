package singbox

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func TestRenderChainSetsDialerProxy(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolTrojan)
	p.Outbounds[0].Via = p.Outbounds[1].ID
	cfg := render(t, p)
	outbounds, ok := cfg["outbounds"].([]any)
	if !ok {
		t.Fatal("rendered config has no outbounds")
	}
	var via string
	for _, raw := range outbounds {
		ob, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if dp, ok := ob["dialer_proxy"].(string); ok {
			via = dp
		}
	}
	if via == "" {
		t.Fatal("no outbound carries dialer_proxy")
	}
	// The dialer proxy must name the tag of the second outbound.
	found := false
	for _, raw := range outbounds {
		ob, _ := raw.(map[string]any)
		if ob["tag"] == via {
			found = true
		}
	}
	if !found {
		t.Fatalf("dialer_proxy %q names no rendered outbound", via)
	}
}

func TestRenderChainlessPlanHasNoDialerProxy(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolTrojan)
	cfg := render(t, p)
	outbounds, _ := cfg["outbounds"].([]any)
	for _, raw := range outbounds {
		if ob, ok := raw.(map[string]any); ok {
			if _, has := ob["dialer_proxy"]; has {
				t.Fatalf("outbound %v has dialer_proxy without a chain", ob["tag"])
			}
		}
	}
}
