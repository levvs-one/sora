package ext

import (
	"encoding/json"
	"os"
	"testing"
)

// TestSetSettingsMerges pins the documented panel contract: a setSettings
// call writes only the keys it names (docs/extensions.md shows
// setSettings({refresh_seconds: 10}) as a one-key write, and the sora-ext
// mock has always merged). Before pass 3 the Go store — like the Dart
// one — replaced the whole stored document, so a panel updating one key
// silently dropped every other stored key, including values the user
// set in the app settings form. Rejected values must still write nothing.
func TestSetSettingsMerges(t *testing.T) {
	s := testStore(t)
	m := testManifest(t)
	m.SettingsSchema = json.RawMessage(`{"type":"object","properties":{
		"theme":{"type":"string","enum":["dark","light"],"default":"dark"},
		"refresh":{"type":"integer","minimum":1,"maximum":60,"default":5},
		"show_bytes":{"type":"boolean","default":true}}}`)
	data := buildPackage(t, m, nil, nil)
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications", "ui.panel"}, ""); err != nil {
		t.Fatal(err)
	}
	id := "com.example.hello"

	if err := s.SetSettings(id, map[string]any{"theme": "light"}); err != nil {
		t.Fatalf("first save: %v", err)
	}
	// One-key write: the previously stored key must survive.
	if err := s.SetSettings(id, map[string]any{"refresh": float64(30)}); err != nil {
		t.Fatalf("second save: %v", err)
	}
	got, err := s.GetSettings(id)
	if err != nil {
		t.Fatal(err)
	}
	if got["theme"] != "light" || got["refresh"] != float64(30) || got["show_bytes"] != true {
		t.Fatalf("merged settings = %v, want theme=light refresh=30 show_bytes=true(default)", got)
	}
	// Overwriting one key keeps the others.
	if err := s.SetSettings(id, map[string]any{"theme": "dark"}); err != nil {
		t.Fatalf("overwrite save: %v", err)
	}
	got, err = s.GetSettings(id)
	if err != nil {
		t.Fatal(err)
	}
	if got["theme"] != "dark" || got["refresh"] != float64(30) {
		t.Fatalf("after overwrite = %v, want theme=dark refresh=30", got)
	}
	// A rejected write changes nothing (validation runs before the merge).
	if err := s.SetSettings(id, map[string]any{"refresh": float64(999)}); err == nil {
		t.Fatal("out-of-range save accepted")
	}
	got, err = s.GetSettings(id)
	if err != nil {
		t.Fatal(err)
	}
	if got["refresh"] != float64(30) {
		t.Fatalf("rejected write leaked into the store: %v", got)
	}
}

// TestSetSettingsMergesOverNullStoredFile pins the repair contract for a
// stored settings file whose content is the JSON literal "null": valid
// JSON, but not a settings object. json.Unmarshal("null") succeeds and
// leaves the destination map nil, so the merge must treat it like
// corruption (start from empty) — assigning into the nil map panics
// (found by the pass-3 audit's adversarial vector; the Dart mirror's
// cast-and-catch already repairs this shape to empty).
func TestSetSettingsMergesOverNullStoredFile(t *testing.T) {
	s := testStore(t)
	m := testManifest(t)
	m.SettingsSchema = json.RawMessage(`{"type":"object","properties":{
		"theme":{"type":"string","enum":["dark","light"],"default":"dark"}}}`)
	data := buildPackage(t, m, nil, nil)
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications", "ui.panel"}, ""); err != nil {
		t.Fatal(err)
	}
	id := "com.example.hello"
	if err := os.WriteFile(s.settingsPath(id), []byte("null"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := s.SetSettings(id, map[string]any{"theme": "light"}); err != nil {
		t.Fatalf("save over a stored null file: %v", err)
	}
	got, err := s.GetSettings(id)
	if err != nil {
		t.Fatal(err)
	}
	if got["theme"] != "light" {
		t.Fatalf("settings after null repair = %v, want theme=light", got)
	}
}
