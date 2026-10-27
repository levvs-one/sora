package validate

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestBypassSourceContracts(t *testing.T) {
	for _, name := range []string{"zapret", "byedpi"} {
		dir := filepath.Join("..", "..", "..", "..", "extensions", "sources", name)
		result := ValidateProject(dir)
		if !result.OK() {
			t.Fatalf("%s: %+v", name, result.Issues)
		}
	}
}
func TestBypassDescriptorRejectsUnrelatedAuthority(t *testing.T) {
	const base = `{"hook_version":2,"backend":"tpws","profiles":{"TCP":{"splitPos":["1"]}}}`
	for _, raw := range []string{
		strings.Replace(base, `"hook_version":2`, `"hook_version":1`, 1),
		strings.Replace(base, `"tpws"`, `"winws"`, 1),
		strings.Replace(base, `"splitPos":["1"]`, `"executable":"/bin/sh"`, 1),
		strings.Replace(base, `"splitPos":["1"]`, `"splitPos":true`, 1),
		strings.Replace(base, `"hook_version":2`, `"path":"/bin/sh","hook_version":2`, 1),
		base + "{}", `{"hook_version":2,"backend":"tpws","profiles":{}}`,
	} {
		if err := validateBypassAsset([]byte(raw)); err == nil {
			t.Fatalf("accepted %s", raw)
		}
	}
	doc := map[string]any{"hook_version": 2, "backend": "tpws", "profiles": map[string]any{
		"TCP": map[string]any{"splitPos": []string{"1"}},
	}}
	raw, err := json.Marshal(doc)
	if err != nil {
		t.Fatal(err)
	}
	if err := validateBypassAsset(raw); err != nil {
		t.Fatal(err)
	}
}
func TestBypassProjectInvalidDescriptorFailsBeforePack(t *testing.T) {
	dir := t.TempDir()
	src := filepath.Join("..", "..", "..", "..", "extensions", "sources", "zapret", "sora-extension.json")
	raw, err := os.ReadFile(src)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "sora-extension.json"), raw, 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "hook.json"), []byte(`{"hook_version":1}`), 0o600); err != nil {
		t.Fatal(err)
	}
	result := ValidateProject(dir)
	if result.OK() || result.Issues[0].Code != "invalid-bypass-profile" {
		t.Fatalf("%+v", result)
	}
}

func TestPlatformBypassScopeAndBackendPairing(t *testing.T) {
	base := map[string]any{"hook_version": 3, "platforms": map[string]any{
		"linux":   map[string]any{"backend": "tpws", "profiles": map[string]any{"TCP": map[string]any{"splitPos": []string{"1"}}}},
		"windows": map[string]any{"backend": "winws", "scope": "system-tcp-80-443", "profiles": map[string]any{"TCP": map[string]any{"splitPos": []string{"1"}}}},
	}}
	raw, err := json.Marshal(base)
	if err != nil {
		t.Fatal(err)
	}
	if err := validateBypassAsset(raw); err != nil {
		t.Fatal(err)
	}
	for _, mutate := range []func(map[string]any){
		func(d map[string]any) { d["backend"] = "tpws" },
		func(d map[string]any) { d["platforms"].(map[string]any)["android"] = map[string]any{} },
		func(d map[string]any) { d["platforms"].(map[string]any)["windows"].(map[string]any)["scope"] = "all" },
		func(d map[string]any) { delete(d["platforms"].(map[string]any)["windows"].(map[string]any), "scope") },
		func(d map[string]any) { d["platforms"].(map[string]any)["linux"].(map[string]any)["backend"] = "winws" },
		func(d map[string]any) {
			d["platforms"].(map[string]any)["windows"].(map[string]any)["executable"] = "winws.exe"
		},
		func(d map[string]any) {
			d["platforms"].(map[string]any)["windows"].(map[string]any)["profiles"].(map[string]any)["TCP"].(map[string]any)["oob"] = true
		},
		func(d map[string]any) {
			d["platforms"].(map[string]any)["windows"].(map[string]any)["profiles"].(map[string]any)["TCP"].(map[string]any)["tlsRecord"] = "1"
		},
	} {
		var doc map[string]any
		if err := json.Unmarshal(raw, &doc); err != nil {
			t.Fatal(err)
		}
		mutate(doc)
		bad, err := json.Marshal(doc)
		if err != nil {
			t.Fatal(err)
		}
		if err := validateBypassAsset(bad); err == nil {
			t.Fatalf("accepted %s", bad)
		}
	}
}

func TestLinuxByeDPIRequiresExplicitPlatformVariant(t *testing.T) {
	valid := []byte(`{"hook_version":3,"platforms":{"linux":{"backend":"byedpi","profiles":{"TCP":{"splitPos":["1"]}}},"windows":{"backend":"byedpi","profiles":{"TCP":{"splitPos":["1"]}}}}}`)
	if err := validateBypassAsset(valid); err != nil {
		t.Fatalf("Linux ByeDPI variant rejected: %v", err)
	}
}
