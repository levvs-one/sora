package mihomo

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func TestRenderWSEarlyData(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Transport = engine.Transport{Type: "ws", Path: "/ws", Host: "example.com", EarlyData: 2048}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	if !strings.Contains(out, "max-early-data: 2048") {
		t.Fatalf("rendered config is missing max-early-data: 2048\n---\n%s", out)
	}
	p.Outbounds[0].Transport.EarlyData = 0
	out, err = Render(p, testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	if strings.Contains(out, "max-early-data") {
		t.Fatalf("max-early-data must be absent when disabled\n---\n%s", out)
	}
}
