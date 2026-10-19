package mihomo

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

func ruleTargetMap() map[string]string {
	return map[string]string{"Proxy": "proxy-1"}
}

func TestBuildRulesRendersRemoteRuleProviders(t *testing.T) {
	rules := []engine.Rule{
		{Type: engine.RuleRuleSet, Value: "https://example.com/rules/ads.mrs", Target: "reject"},
		{Type: engine.RuleRuleSet, Value: "https://example.com/rules/ads.mrs", Target: "reject"},
		{Type: engine.RuleRuleSet, Value: "https://example.com/rules/cn.yaml", Target: "direct"},
	}
	rendered, providers, err := buildRules(rules, ruleTargetMap())
	if err != nil {
		t.Fatalf("buildRules: %v", err)
	}
	if len(providers) != 2 {
		t.Fatalf("expected 2 providers for 2 distinct URLs, got %d", len(providers))
	}
	if got := providers["sora-ruleset-1"]; got.URL != "https://example.com/rules/ads.mrs" || got.Format != "mrs" || got.Behavior != "classical" || got.Interval != defaultRuleSetInterval {
		t.Fatalf("bad mrs provider: %+v", got)
	}
	if got := providers["sora-ruleset-2"]; got.Format != "yaml" {
		t.Fatalf("expected yaml format for .yaml URL, got %+v", got)
	}
	want := []string{
		"RULE-SET,sora-ruleset-1,REJECT",
		"RULE-SET,sora-ruleset-1,REJECT",
		"RULE-SET,sora-ruleset-2,DIRECT",
		"MATCH,DIRECT",
	}
	if strings.Join(rendered, "\n") != strings.Join(want, "\n") {
		t.Fatalf("rules = %v, want %v", rendered, want)
	}
}

func TestBuildRulesStripsQueryFromRuleSetFormat(t *testing.T) {
	rules := []engine.Rule{
		// Versioned download links carry a query string; the wire format
		// still comes from the path extension.
		{Type: engine.RuleRuleSet, Value: "https://example.com/rules/ads.mrs?v=2", Target: "reject"},
		{Type: engine.RuleRuleSet, Value: "https://example.com/rules/ips.MRS", Target: "direct"},
		{Type: engine.RuleRuleSet, Value: "https://example.com/rules/plain", Target: "direct"},
	}
	_, providers, err := buildRules(rules, ruleTargetMap())
	if err != nil {
		t.Fatalf("buildRules: %v", err)
	}
	if got := providers["sora-ruleset-1"]; got.Format != "mrs" || got.Path != "./rules/sora-ruleset-1.mrs" {
		t.Fatalf("query string hid the mrs format: %+v", got)
	}
	if got := providers["sora-ruleset-2"]; got.Format != "mrs" {
		t.Fatalf("uppercase extension not recognized: %+v", got)
	}
	if got := providers["sora-ruleset-3"]; got.Format != "text" || got.Path != "./rules/sora-ruleset-3.txt" {
		t.Fatalf("extensionless URL must fall back to text: %+v", got)
	}
}

func TestBuildRulesRejectsSingBoxBinaryRuleSet(t *testing.T) {
	rules := []engine.Rule{
		{Type: engine.RuleRuleSet, Value: "https://example.com/rules/ads.srs", Target: "reject"},
	}
	_, _, err := buildRules(rules, ruleTargetMap())
	if err == nil {
		t.Fatal("expected an error for a sing-box .srs rule set mihomo cannot parse")
	}
	if !strings.Contains(err.Error(), ".mrs") {
		t.Fatalf("error should point at the mihomo format, got: %v", err)
	}
}

func TestBuildRulesRejectsNonHTTPSRuleSetURL(t *testing.T) {
	rules := []engine.Rule{
		{Type: engine.RuleRuleSet, Value: "http://example.com/rules/ads.yaml", Target: "reject"},
	}
	if _, _, err := buildRules(rules, ruleTargetMap()); err == nil {
		t.Fatal("expected an error for a plain-http rule set URL")
	}
	if _, _, err := buildRules([]engine.Rule{{Type: engine.RuleRuleSet, Value: "local-provider", Target: "reject"}}, ruleTargetMap()); err == nil {
		t.Fatal("expected an error for a bare provider name with no provider defined")
	}
}

func TestBuildRulesKeepsNonRuleSetRulesProviderFree(t *testing.T) {
	rules := []engine.Rule{
		{Type: engine.RuleGeoSite, Value: "category-ads-all", Target: "reject"},
		{Type: engine.RuleMatchAll, Value: "", Target: "Proxy"},
	}
	rendered, providers, err := buildRules(rules, ruleTargetMap())
	if err != nil {
		t.Fatalf("buildRules: %v", err)
	}
	if len(providers) != 0 {
		t.Fatalf("expected no providers, got %v", providers)
	}
	if rendered[0] != "GEOSITE,category-ads-all,REJECT" || rendered[1] != "MATCH,proxy-1" {
		t.Fatalf("unexpected rules: %v", rendered)
	}
}

func TestRenderEmitsRuleProvidersBlock(t *testing.T) {
	p := &engine.Plan{
		SessionID:  "session-ruleset",
		Outbounds:  []engine.Outbound{{ID: "direct", Protocol: engine.ProtocolDirect}},
		Rules: []engine.Rule{
			{Type: engine.RuleRuleSet, Value: "https://example.com/rules/ads.mrs", Target: "reject"},
			{Type: engine.RuleMatchAll, Target: "direct"},
		},
		Options: engine.Options{LogLevel: "warning", Mode: "rule"},
	}
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	if !strings.Contains(out, "rule-providers:") {
		t.Fatal("rendered config has no rule-providers block")
	}
	if !strings.Contains(out, "sora-ruleset-1:") {
		t.Fatal("rendered config has no sora-ruleset-1 provider")
	}
	if !strings.Contains(out, "RULE-SET,sora-ruleset-1,REJECT") {
		t.Fatalf("rendered rules do not reference the provider:\n%s", out)
	}
}
