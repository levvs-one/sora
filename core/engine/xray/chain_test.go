package xray

import (
	"encoding/json"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func TestRenderChainSetsDialerProxy(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolTrojan)
	// Xray rejects h2 ALPN on trojan in its own way; keep the plan minimal.
	for i := range p.Outbounds {
		p.Outbounds[i].TLS.ALPN = nil
	}
	p.Outbounds[0].Via = p.Outbounds[1].ID
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	var cfg struct {
		Outbounds []map[string]any `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatalf("rendered config is not JSON: %v", err)
	}
	var via string
	tags := map[string]bool{}
	for _, ob := range cfg.Outbounds {
		if tag, ok := ob["tag"].(string); ok {
			tags[tag] = true
		}
		stream, _ := ob["streamSettings"].(map[string]any)
		sockopt, _ := stream["sockopt"].(map[string]any)
		if dp, ok := sockopt["dialerProxy"].(string); ok {
			via = dp
		}
	}
	if via == "" {
		t.Fatal("no outbound carries dialerProxy")
	}
	if !tags[via] {
		t.Fatalf("dialerProxy %q names no rendered outbound", via)
	}
}
