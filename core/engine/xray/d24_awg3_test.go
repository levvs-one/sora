package xray

import (
	"encoding/json"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func TestRenderWSEarlyData(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVMess)
	p.Outbounds[0].Transport.EarlyData = 2048
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Outbounds []struct {
			StreamSettings struct {
				WSSettings map[string]any `json:"wsSettings"`
			} `json:"streamSettings"`
		} `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatal(err)
	}
	if len(cfg.Outbounds) == 0 {
		t.Fatal("no outbounds rendered")
	}
	if got := cfg.Outbounds[0].StreamSettings.WSSettings["maxEarlyData"]; got != float64(2048) {
		t.Fatalf("maxEarlyData = %v, want 2048", got)
	}
}
