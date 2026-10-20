package subscription

import (
	"strings"
	"testing"
)

// TestUserAgentForHostPool pins the fetch-masking rules: the pick is
// pool data, never names the client, is stable for one provider host
// (a panel that formats by agent sees a consistent client), and
// spreads across hosts instead of forming one global fingerprint.
func TestUserAgentForHostPool(t *testing.T) {
	seen := map[string]bool{}
	for _, host := range []string{"panel-a.example", "panel-b.example", "panel-c.example", "panel-d.example", "panel-e.example", "panel-f.example", "panel-g.example", "panel-h.example"} {
		got := userAgentForHost(host)
		if strings.Contains(strings.ToLower(got), "sora") {
			t.Fatalf("agent for %s names the client: %q", host, got)
		}
		if again := userAgentForHost(strings.ToUpper(host)); again != got {
			t.Fatalf("agent pick must be stable and case-insensitive: %q vs %q", got, again)
		}
		seen[got] = true
	}
	if len(seen) < 2 {
		t.Fatalf("eight provider hosts mapped to a single agent: %v", seen)
	}
	if len(DefaultUserAgents) < 3 {
		t.Fatalf("pool has %d agents, want at least 3 for spread", len(DefaultUserAgents))
	}
}
