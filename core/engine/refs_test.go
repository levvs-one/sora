package engine

import "testing"

// TestIsBuiltInTargetCanonicalSet locks the single source of truth for
// built-in rule targets (A20-18). {direct, reject, pass, dns} is the
// canonical set; in particular "block" is not one: no engine renderer maps
// it from a plan rule, so accepting it only deferred the failure to render
// time.
func TestIsBuiltInTargetCanonicalSet(t *testing.T) {
	for _, target := range []string{"direct", "reject", "pass", "dns"} {
		if !IsBuiltInTarget(target) {
			t.Errorf("IsBuiltInTarget(%q) = false, want true", target)
		}
	}
	for _, target := range []string{"", "block", "proxy", "DIRECT", "Pass", " dns", "out-1", "Proxy"} {
		if IsBuiltInTarget(target) {
			t.Errorf("IsBuiltInTarget(%q) = true, want false", target)
		}
	}
}

// TestPlanValidateBuiltInRuleTargets runs both the old control set and the
// old engine set through Plan.Validate so the unification cannot weaken
// plan validation: pass/dns are accepted, block is rejected fail-fast,
// unknown names are still rejected.
func TestPlanValidateBuiltInRuleTargets(t *testing.T) {
	base := func(target string) *Plan {
		return &Plan{
			SessionID: "target-test",
			Outbounds: []Outbound{{ID: "out", Protocol: ProtocolDirect}},
			Rules:     []Rule{{Type: RuleDomainSuffix, Value: "example.com", Target: target}},
		}
	}
	for _, target := range []string{"direct", "reject", "pass", "dns", "out"} {
		if err := base(target).Validate(); err != nil {
			t.Errorf("Validate with target %q = %v, want nil", target, err)
		}
	}
	for _, target := range []string{"block", "ghost"} {
		if err := base(target).Validate(); err == nil {
			t.Errorf("Validate with target %q = nil, want an error", target)
		}
	}
}
