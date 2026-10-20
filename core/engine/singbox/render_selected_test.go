package singbox

import (
	"encoding/json"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// TestRenderSelectorStartsOnThePlannedMember pins the fast-switch
// invariant for sing-box: a select group whose plan names a starting
// member renders that member as the selector's default, so the engine
// starts on it at Connect instead of on the first member.
func TestRenderSelectorStartsOnThePlannedMember(t *testing.T) {
	p := &engine.Plan{
		SessionID:  "selected",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Options:    engine.Options{LogLevel: "warning", Mode: "rule", TestURL: engine.TestURLProduction},
		Outbounds: []engine.Outbound{
			{ID: "a", Name: "a", Protocol: engine.ProtocolSOCKS5, Server: "198.51.100.1", Port: 1080, UserID: "u", Password: "p"},
			{ID: "b", Name: "b", Protocol: engine.ProtocolSOCKS5, Server: "198.51.100.2", Port: 1080, UserID: "u", Password: "p"},
		},
		Groups: []engine.Group{
			{Name: "pick", Type: engine.GroupSelect, Outbounds: []string{"a", "b"}, Selected: "b"},
		},
		Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "pick"}},
	}
	raw, err := Render(p, testRuntime)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	var cfg struct {
		Outbounds []map[string]any `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	for _, out := range cfg.Outbounds {
		if out["type"] != "selector" {
			continue
		}
		if out["default"] != "b" {
			t.Fatalf("selector default = %v, want b (the plan's Selected): %s", out["default"], raw)
		}
		return
	}
	t.Fatalf("no selector outbound rendered: %s", raw)
}

// TestRenderSelectorWithoutSelectedHasNoDefault keeps the pre-1.12
// shape for groups that name no starting member: no default field, the
// engine's own first-member behavior applies.
func TestRenderSelectorWithoutSelectedHasNoDefault(t *testing.T) {
	p := &engine.Plan{
		SessionID:  "unselected",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Options:    engine.Options{LogLevel: "warning", Mode: "rule", TestURL: engine.TestURLProduction},
		Outbounds: []engine.Outbound{
			{ID: "a", Name: "a", Protocol: engine.ProtocolSOCKS5, Server: "198.51.100.1", Port: 1080, UserID: "u", Password: "p"},
			{ID: "b", Name: "b", Protocol: engine.ProtocolSOCKS5, Server: "198.51.100.2", Port: 1080, UserID: "u", Password: "p"},
		},
		Groups: []engine.Group{
			{Name: "pick", Type: engine.GroupSelect, Outbounds: []string{"a", "b"}},
		},
		Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "pick"}},
	}
	raw, err := Render(p, testRuntime)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	var cfg struct {
		Outbounds []map[string]any `json:"outbounds"`
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	for _, out := range cfg.Outbounds {
		if out["type"] == "selector" {
			if _, present := out["default"]; present {
				t.Fatalf("selector without a planned member rendered a default: %s", raw)
			}
			return
		}
	}
	t.Fatalf("no selector outbound rendered: %s", raw)
}
