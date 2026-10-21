package validate

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/ext"
)

// The JSON Schema (tools/sora-ext/schema) and the TypeScript definitions
// (templates/shared/sora-ext.d.ts) are hand-maintained mirrors of the
// real contracts in core/ext and app/lib/src/ext/bridge.dart. They have
// drifted before (pass 2 fixed the bridge error contract; pass 3 found
// the schema demanding permissions/capabilities that both real parsers
// treat as optional). These tests pin the mirrors to the registry and
// to the parser's actual behavior, so the next drift fails CI instead
// of an extension author's editor.

func loadSchema(t *testing.T) map[string]any {
	t.Helper()
	raw, err := os.ReadFile(filepath.Join("..", "..", "schema", "manifest.schema.json"))
	if err != nil {
		t.Fatalf("read schema: %v", err)
	}
	var schema map[string]any
	if err := json.Unmarshal(raw, &schema); err != nil {
		t.Fatalf("schema is not valid JSON: %v", err)
	}
	return schema
}

func schemaEnum(t *testing.T, schema map[string]any, field string) []string {
	t.Helper()
	props, _ := schema["properties"].(map[string]any)
	prop, _ := props[field].(map[string]any)
	items, _ := prop["items"].(map[string]any)
	rawEnum, _ := items["enum"].([]any)
	out := make([]string, 0, len(rawEnum))
	for _, v := range rawEnum {
		s, _ := v.(string)
		out = append(out, s)
	}
	sort.Strings(out)
	return out
}

func TestSchemaPermissionEnumMatchesRegistry(t *testing.T) {
	schema := loadSchema(t)
	got := schemaEnum(t, schema, "permissions")
	want := make([]string, 0, len(ext.AllPermissions))
	for _, p := range ext.AllPermissions {
		want = append(want, p.ID)
	}
	sort.Strings(want)
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Errorf("schema permissions enum = %v, registry = %v", got, want)
	}
}

func TestSchemaCapabilityEnumMatchesRegistry(t *testing.T) {
	schema := loadSchema(t)
	got := schemaEnum(t, schema, "capabilities")
	want := []string{"background", "network-hook", "routing", "theme", "ui-panel", "widget"}
	sort.Strings(want)
	if strings.Join(got, ",") != strings.Join(want, ",") {
		t.Errorf("schema capabilities enum = %v, want %v", got, want)
	}
	for _, c := range got {
		m := minimalManifest()
		m["capabilities"] = []string{c}
		if err := parseMap(t, m); err != nil {
			t.Errorf("schema capability %q is rejected by the core parser: %v", c, err)
		}
	}
}

// minimalManifest is a complete, valid manifest with no permissions and
// no capabilities keys at all: both real parsers treat a missing list
// as empty, so the schema must not require the keys either.
func minimalManifest() map[string]any {
	return map[string]any{
		"manifest_version": 1,
		"id":               "com.example.minimal",
		"name":             "Minimal",
		"version":          "1.0.0",
		"min_app_version":  "1.0.0",
		"author": map[string]any{
			"name":       "Jane Doe",
			"identity":   "github:janedoe",
			"public_key": "RWQAAAAAAAAAAHd26HC5M1TyoLJMI/KjbMToDiIyGMG5eSb90Bg5aiub",
		},
	}
}

func parseMap(t *testing.T, m map[string]any) error {
	t.Helper()
	raw, err := json.Marshal(m)
	if err != nil {
		t.Fatal(err)
	}
	_, _, err = ext.ParseManifestFull(raw)
	return err
}

func TestSchemaRequiredFieldsAreReallyRequired(t *testing.T) {
	if err := parseMap(t, minimalManifest()); err != nil {
		t.Fatalf("minimal manifest (no permissions/capabilities keys) must parse: %v", err)
	}
	schema := loadSchema(t)
	rawReq, _ := schema["required"].([]any)
	if len(rawReq) == 0 {
		t.Fatal("schema has no required list")
	}
	for _, rv := range rawReq {
		field, _ := rv.(string)
		m := minimalManifest()
		delete(m, field)
		if err := parseMap(t, m); err == nil {
			t.Errorf("schema requires %q, but the real parser accepts a manifest without it - the schema is stricter than the contract", field)
		}
	}
	// And the converse direction for the two list fields: the parser
	// accepts their omission, so the schema must not demand them.
	for _, field := range []string{"permissions", "capabilities"} {
		for _, rv := range rawReq {
			if rv == field {
				t.Errorf("schema requires %q, but both real parsers treat a missing list as empty (pass-3 drift)", field)
			}
		}
	}
	// Author subfields are genuinely required by the parser; pin them too.
	author, _ := loadSchema(t)["properties"].(map[string]any)["author"].(map[string]any)
	for _, rv := range author["required"].([]any) {
		field, _ := rv.(string)
		m := minimalManifest()
		delete(m["author"].(map[string]any), field)
		if err := parseMap(t, m); err == nil {
			t.Errorf("schema requires author.%q, but the real parser accepts its omission", field)
		}
	}
}

func TestTypeScriptDefsMatchBridgeContract(t *testing.T) {
	raw, err := os.ReadFile(filepath.Join("..", "..", "templates", "shared", "sora-ext.d.ts"))
	if err != nil {
		t.Fatalf("read d.ts: %v", err)
	}
	dts := string(raw)
	// Every bridge method (app/lib/src/ext/bridge.dart _dispatch) and
	// every documented error code / event kind must be named in the
	// definitions panels are scaffolded with.
	for _, want := range []string{
		"getConnections", "getServers", "notify", "getSettings", "setSettings",
		"'permission-denied'", "'invalid-argument'", "'not-connected'", "'internal'",
		"'session.connected'", "'session.disconnected'", "'network.changed'", "'extension.disabled'",
		"up_bytes", "down_bytes", "latency_ms",
	} {
		if !strings.Contains(dts, want) {
			t.Errorf("sora-ext.d.ts does not mention %s: the TS mirror drifted from the bridge contract", want)
		}
	}
}
