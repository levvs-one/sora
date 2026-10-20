package mihomo

import (
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
)

func TestRenderChainSetsDialerProxy(t *testing.T) {
	p := testPlan()
	p.Outbounds[0].Via = p.Outbounds[1].ID
	out, err := Render(p, testRuntime(t))
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	var c config
	if err := yaml.Unmarshal([]byte(out), &c); err != nil {
		t.Fatalf("rendered config is not YAML: %v", err)
	}
	var via string
	for _, px := range c.Proxies {
		if px.Dialer != "" {
			via = px.Dialer
		}
	}
	if via == "" {
		t.Fatal("no proxy carries dialer-proxy")
	}
	// The dialer proxy must name another rendered proxy.
	names := map[string]bool{}
	for _, px := range c.Proxies {
		names[px.Name] = true
	}
	if !names[via] {
		t.Fatalf("dialer-proxy %q names no rendered proxy", via)
	}
	if !strings.Contains(out, "dialer-proxy:") {
		t.Fatal("rendered YAML has no dialer-proxy key")
	}
}
