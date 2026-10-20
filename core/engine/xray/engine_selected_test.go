package xray

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

func selectedPlan() *engine.Plan {
	a := enginetest.Outbound(engine.ProtocolVLESS)
	a.ID, a.Name = "a", "a"
	b := enginetest.Outbound(engine.ProtocolTrojan)
	b.ID, b.Name = "b", "b"
	return &engine.Plan{
		SessionID:  "selected",
		LocalProxy: engine.LocalProxy{Enabled: true},
		Options:    engine.Options{LogLevel: "warning", Mode: "rule", TestURL: engine.TestURLProduction},
		Outbounds:  []engine.Outbound{a, b},
		Groups: []engine.Group{
			{Name: "pick", Type: engine.GroupSelect, Outbounds: []string{"a", "b"}, Selected: "b"},
		},
		Rules: []engine.Rule{{Type: engine.RuleMatchAll, Target: "pick"}},
	}
}

// TestDriverSeedsSelectionFromThePlan pins the fast-switch invariant
// for Xray: seeding from the plan makes the render route the select
// group through Group.Selected instead of its first member.
func TestDriverSeedsSelectionFromThePlan(t *testing.T) {
	p := selectedPlan()
	d := &driver{sel: Selection{}}
	d.seedPlanSelection(p)
	if got := d.selection()["pick"]; got != "b" {
		t.Fatalf("seeded selection = %q, want b", got)
	}
	raw, err := Render(p, testRuntime, d.selection())
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	// Outbound tags are positional (o0001, o0002 in enginetest order):
	// the default route must land on b's tag.
	if !strings.Contains(string(raw), `"outboundTag":"o0002"`) {
		t.Fatalf("the seeded render does not route through b: %s", raw)
	}
}

// TestDriverSeedKeepsARuntimeSelection: a selection the user made at
// runtime lives in the same map; re-seeding on a reconnect Apply must
// not undo it with the plan's starting member.
func TestDriverSeedKeepsARuntimeSelection(t *testing.T) {
	p := selectedPlan()
	d := &driver{sel: Selection{"pick": "a"}}
	d.seedPlanSelection(p)
	if got := d.selection()["pick"]; got != "a" {
		t.Fatalf("selection after re-seed = %q, want the runtime choice a", got)
	}
}

// TestDriverSeedIgnoresNonMembers: a Selected that is not a member
// (validation rejects such plans, but the driver must not pin garbage
// if one slips through) leaves the group unseeded.
func TestDriverSeedIgnoresNonMembers(t *testing.T) {
	p := selectedPlan()
	p.Groups[0].Selected = "nope"
	d := &driver{sel: Selection{}}
	d.seedPlanSelection(p)
	if _, ok := d.selection()["pick"]; ok {
		t.Fatalf("seeded a non-member: %v", d.selection())
	}
}
