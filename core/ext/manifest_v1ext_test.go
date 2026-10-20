package ext

import (
	"encoding/json"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
)

// rawManifestWith marshals m and merges extra top-level keys, so tests can
// exercise the v2-runtime fields without touching manifest.go's struct.
func rawManifestWith(t *testing.T, m *Manifest, extra map[string]any) []byte {
	t.Helper()
	raw, err := json.Marshal(m)
	if err != nil {
		t.Fatal(err)
	}
	var obj map[string]any
	if err := json.Unmarshal(raw, &obj); err != nil {
		t.Fatal(err)
	}
	for k, v := range extra {
		obj[k] = v
	}
	out, err := json.Marshal(obj)
	if err != nil {
		t.Fatal(err)
	}
	return out
}

// bgManifest returns a manifest entitled to background workers + net.fetch.
// It has no panels (a worker-only extension embeds no UI, so it needs
// neither the ui-panel capability nor the ui.panel permission — see the
// panels gate in manifest.go Validate).
func bgManifest(t *testing.T) *Manifest {
	t.Helper()
	m := testManifest(t)
	m.Permissions = []string{"background", "net.fetch"}
	m.Capabilities = []string{"background"}
	m.UI = nil
	return m
}

func codeOf(t *testing.T, err error) errs.Code {
	t.Helper()
	e, ok := err.(*errs.Error)
	if !ok {
		t.Fatalf("want *errs.Error, got %T (%v)", err, err)
	}
	return e.Code()
}

func TestParseManifestFullBackgroundOK(t *testing.T) {
	raw := rawManifestWith(t, bgManifest(t), map[string]any{
		"background_task": map[string]any{"interval_minutes": 60, "entry": "worker.js"},
		"network_hosts":   []string{"api.example.com", "*.cdn.example.com"},
	})
	m, x, err := ParseManifestFull(raw)
	if err != nil {
		t.Fatalf("ParseManifestFull: %v", err)
	}
	if x.Background == nil || x.Background.IntervalMinutes != 60 || x.Background.Entry != "worker.js" {
		t.Fatalf("bad background: %+v", x.Background)
	}
	if len(x.NetworkHosts) != 2 || m.ID != "com.example.hello" {
		t.Fatalf("bad ext fields: %+v / %s", x.NetworkHosts, m.ID)
	}
}

func TestParseManifestFullOldManifest(t *testing.T) {
	m := testManifest(t)
	raw, _ := json.Marshal(m)
	got, x, err := ParseManifestFull(raw)
	if err != nil {
		t.Fatalf("old manifest must keep parsing: %v", err)
	}
	if x.Background != nil || len(x.NetworkHosts) != 0 {
		t.Fatalf("old manifest must yield empty ext: %+v", x)
	}
	if got.ID != m.ID {
		t.Fatalf("id changed: %s", got.ID)
	}
}

func TestParseManifestFullBackgroundNeedsCapability(t *testing.T) {
	m := bgManifest(t)
	m.Capabilities = []string{"ui-panel"}
	raw := rawManifestWith(t, m, map[string]any{
		"background_task": map[string]any{"interval_minutes": 30, "entry": "worker.js"},
	})
	_, _, err := ParseManifestFull(raw)
	if err == nil {
		t.Fatal("background_task without the background capability must be rejected")
	}
	if codeOf(t, err) != errs.CodeInvalidArgument {
		t.Fatalf("want invalid_argument, got %v", err)
	}
}

func TestParseManifestFullBackgroundNeedsPermission(t *testing.T) {
	m := bgManifest(t)
	m.Permissions = []string{"net.fetch"} // background permission missing
	raw := rawManifestWith(t, m, map[string]any{
		"background_task": map[string]any{"interval_minutes": 30, "entry": "worker.js"},
	})
	if _, _, err := ParseManifestFull(raw); err == nil {
		t.Fatal("background_task without the background permission must be rejected")
	}
}

func TestParseManifestFullBadIntervals(t *testing.T) {
	for _, minutes := range []int{0, -5, MaxBackgroundIntervalMinutes + 1} {
		raw := rawManifestWith(t, bgManifest(t), map[string]any{
			"background_task": map[string]any{"interval_minutes": minutes, "entry": "worker.js"},
		})
		if _, _, err := ParseManifestFull(raw); err == nil {
			t.Fatalf("interval_minutes=%d must be rejected", minutes)
		}
	}
}

func TestParseManifestFullBadEntry(t *testing.T) {
	for _, entry := range []string{"", "../evil.js", "/abs.js", "worker.html", "worker.JS ",
		"sub\\worker.js", "..\\evil.js", "C:\\evil.js"} {
		raw := rawManifestWith(t, bgManifest(t), map[string]any{
			"background_task": map[string]any{"interval_minutes": 30, "entry": entry},
		})
		if _, _, err := ParseManifestFull(raw); err == nil {
			t.Fatalf("entry %q must be rejected", entry)
		}
	}
}

func TestParseManifestFullNetworkHostsNeedsPermission(t *testing.T) {
	m := testManifest(t) // no net.fetch
	raw := rawManifestWith(t, m, map[string]any{
		"network_hosts": []string{"api.example.com"},
	})
	if _, _, err := ParseManifestFull(raw); err == nil {
		t.Fatal("network_hosts without the net.fetch permission must be rejected")
	}
}

func TestParseManifestFullBadHosts(t *testing.T) {
	m := bgManifest(t)
	bad := []string{
		"https://api.example.com", // scheme
		"api.example.com:443",     // port
		"1.2.3.4",                 // IP literal
		"*.example.com.",          // trailing dot: empty label
		"a..b",                    // empty label
		"-bad.com",                // leading hyphen
		"*.*.example.com",         // double wildcard
		"exa mple.com",            // space
	}
	for _, h := range bad {
		raw := rawManifestWith(t, m, map[string]any{"network_hosts": []string{h}})
		if _, _, err := ParseManifestFull(raw); err == nil {
			t.Fatalf("network_hosts entry %q must be rejected", h)
		}
	}
}

func TestParseManifestFullDuplicateHosts(t *testing.T) {
	raw := rawManifestWith(t, bgManifest(t), map[string]any{
		"network_hosts": []string{"API.example.com", "api.example.com"},
	})
	if _, _, err := ParseManifestFull(raw); err == nil {
		t.Fatal("duplicate network_hosts (case-insensitive) must be rejected")
	}
}

func TestParseManifestFullWildcardOK(t *testing.T) {
	raw := rawManifestWith(t, bgManifest(t), map[string]any{
		"network_hosts": []string{"*.Example.COM"},
	})
	_, x, err := ParseManifestFull(raw)
	if err != nil {
		t.Fatalf("wildcard must be accepted: %v", err)
	}
	_ = x
}

func TestParseManifestFullUnknownFieldsRejected(t *testing.T) {
	// Unknown field inside background_task.
	raw := rawManifestWith(t, bgManifest(t), map[string]any{
		"background_task": map[string]any{"interval_minutes": 30, "entry": "w.js", "cron": "* * * * *"},
	})
	if _, _, err := ParseManifestFull(raw); err == nil {
		t.Fatal("unknown field inside background_task must be rejected")
	}
	// Unknown top-level field (frozen v1 decoder).
	raw = rawManifestWith(t, bgManifest(t), map[string]any{"future_field": 1})
	if _, _, err := ParseManifestFull(raw); err == nil {
		t.Fatal("unknown top-level field must be rejected")
	}
}

func TestParseManifestFullEmpty(t *testing.T) {
	if _, _, err := ParseManifestFull(nil); err == nil {
		t.Fatal("empty manifest must be rejected")
	}
}

func TestClampWorkerInterval(t *testing.T) {
	cases := []struct {
		in   int
		want string
	}{
		{1, "15m0s"},        // below the floor: clamped up
		{14, "15m0s"},       // below the floor: clamped up
		{15, "15m0s"},       // exactly the floor
		{60, "1h0m0s"},      // normal
		{10080, "168h0m0s"}, // ceiling
		{20000, "168h0m0s"}, // above the ceiling: clamped down
	}
	for _, c := range cases {
		if got := ClampWorkerInterval(c.in).String(); got != c.want {
			t.Fatalf("ClampWorkerInterval(%d) = %s, want %s", c.in, got, c.want)
		}
	}
}

func TestParseManifestFullThemeOK(t *testing.T) {
	m := testManifest(t)
	m.Permissions = []string{"theme.apply"}
	m.Capabilities = []string{"theme"}
	m.UI = nil // a theme extension embeds no panels
	raw := rawManifestWith(t, m, map[string]any{
		"theme": map[string]any{"entry": "theme.json"},
	})
	_, x, err := ParseManifestFull(raw)
	if err != nil {
		t.Fatalf("ParseManifestFull: %v", err)
	}
	if x.Theme == nil || x.Theme.Entry != "theme.json" {
		t.Fatalf("bad theme: %+v", x.Theme)
	}
}

func TestParseManifestFullThemeNeedsCapabilityAndPermission(t *testing.T) {
	m := testManifest(t) // no theme capability/permission
	raw := rawManifestWith(t, m, map[string]any{
		"theme": map[string]any{"entry": "theme.json"},
	})
	if _, _, err := ParseManifestFull(raw); err == nil {
		t.Fatal("theme without the capability must be rejected")
	}
	m.Permissions = []string{"theme.apply"}
	m.Capabilities = []string{"theme"}
	m.UI = nil // keep the panels gate out of this test's way
	raw = rawManifestWith(t, m, map[string]any{
		"theme": map[string]any{"entry": "../evil.json"},
	})
	if _, _, err := ParseManifestFull(raw); err == nil {
		t.Fatal("theme entry with traversal must be rejected")
	}
}

func TestParseManifestFullNetworkHookAndRoutingOK(t *testing.T) {
	m := testManifest(t)
	m.Permissions = []string{"net.hooks", "routing.rules"}
	m.Capabilities = []string{"network-hook", "routing"}
	m.UI = nil // a hooks/routing extension embeds no panels
	raw := rawManifestWith(t, m, map[string]any{
		"network_hook": map[string]any{"entry": "hook.json"},
		"routing":      map[string]any{"entry": "rules.json"},
	})
	_, x, err := ParseManifestFull(raw)
	if err != nil {
		t.Fatalf("ParseManifestFull: %v", err)
	}
	if x.NetworkHook == nil || x.Routing == nil {
		t.Fatalf("bad contracts: %+v", x)
	}
	// Missing permission for routing.
	m2 := testManifest(t)
	m2.Permissions = []string{"net.hooks"}
	m2.Capabilities = []string{"network-hook", "routing"}
	raw = rawManifestWith(t, m2, map[string]any{
		"routing": map[string]any{"entry": "rules.json"},
	})
	if _, _, err := ParseManifestFull(raw); err == nil {
		t.Fatal("routing without the permission must be rejected")
	}
}
