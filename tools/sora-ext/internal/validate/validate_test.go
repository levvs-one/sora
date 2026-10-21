package validate

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const goodManifest = `{
  "manifest_version": 1,
  "id": "com.example.stats",
  "name": "Stats",
  "version": "1.2.0",
  "min_app_version": "1.9.0",
  "description": "Live connection statistics in a panel.",
  "author": {
    "name": "Jane Doe",
    "identity": "github:janedoe",
    "public_key": "RWQAAAAAAAAAAHd26HC5M1TyoLJMI/KjbMToDiIyGMG5eSb90Bg5aiub"
  },
  "permissions": ["connections.read", "notifications", "ui.panel"],
  "capabilities": ["ui-panel"],
  "ui": {"panels": [{"id": "main", "title": "Stats", "entry": "panel.html"}]},
  "settings_schema": {
    "type": "object",
    "properties": {
      "refresh_seconds": {"type": "integer", "minimum": 1, "maximum": 60, "default": 5}
    }
  }
}`

func writeProject(t *testing.T, manifest string) string {
	t.Helper()
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "sora-extension.json"), []byte(manifest), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "panel.html"), []byte("<html></html>"), 0o644); err != nil {
		t.Fatal(err)
	}
	return dir
}

func TestValidateGood(t *testing.T) {
	r := ValidateProject(writeProject(t, goodManifest))
	if !r.OK() {
		t.Fatalf("want OK, got %+v", r.Issues)
	}
	if r.Manifest == nil || r.Manifest.ID != "com.example.stats" {
		t.Fatalf("bad manifest: %+v", r.Manifest)
	}
}

func TestValidateUnknownPermission(t *testing.T) {
	m := strings.Replace(goodManifest, `"notifications"`, `"net.fech"`, 1)
	r := ValidateProject(writeProject(t, m))
	if r.OK() {
		t.Fatal("want error")
	}
	is := r.Issues[0]
	if is.Code != "unknown-permission" {
		t.Fatalf("code = %q", is.Code)
	}
	if is.Suggestion != "net.fetch" {
		t.Fatalf("suggestion = %q", is.Suggestion)
	}
	if is.Line == 0 || !strings.Contains(is.Snippet, "net.fech") {
		t.Fatalf("no position: %+v", is)
	}
	if !strings.Contains(is.Snippet, "net.fech") {
		t.Fatalf("snippet = %q", is.Snippet)
	}
}

func TestValidateBadID(t *testing.T) {
	m := strings.Replace(goodManifest, `"com.example.stats"`, `"bad id!"`, 1)
	r := ValidateProject(writeProject(t, m))
	if r.OK() {
		t.Fatal("want error")
	}
	is := r.Issues[0]
	if is.Code != "bad-id" {
		t.Fatalf("code = %q", is.Code)
	}
	if !strings.Contains(is.Snippet, `"id"`) {
		t.Fatalf("snippet = %q", is.Snippet)
	}
}

func TestValidateUnknownField(t *testing.T) {
	m := strings.Replace(goodManifest, `"manifest_version": 1,`, `"manifest_version": 1, "future_field": true,`, 1)
	r := ValidateProject(writeProject(t, m))
	if r.OK() {
		t.Fatal("want error")
	}
	if r.Issues[0].Code != "unknown-field" {
		t.Fatalf("code = %q", r.Issues[0].Code)
	}
}

func TestValidateBadJSON(t *testing.T) {
	r := ValidateProject(writeProject(t, `{"manifest_version": 1,`))
	if r.OK() {
		t.Fatal("want error")
	}
	is := r.Issues[0]
	if is.Code != "bad-json" {
		t.Fatalf("code = %q", is.Code)
	}
	if is.Line == 0 {
		t.Fatalf("want position, got %+v", is)
	}
}

func TestValidateMissingEntry(t *testing.T) {
	dir := t.TempDir()
	m := strings.Replace(goodManifest, `"panel.html"`, `"nope.html"`, 1)
	if err := os.WriteFile(filepath.Join(dir, "sora-extension.json"), []byte(m), 0o644); err != nil {
		t.Fatal(err)
	}
	r := ValidateProject(dir)
	if r.OK() {
		t.Fatal("want error")
	}
	if r.Issues[0].Code != "missing-entry" {
		t.Fatalf("code = %q", r.Issues[0].Code)
	}
}

func TestValidateThemeManifest(t *testing.T) {
	m := `{
  "manifest_version": 1,
  "id": "com.example.night",
  "name": "Night",
  "version": "0.1.0",
  "min_app_version": "1.9.0",
  "description": "A dark theme.",
  "author": {"name": "Jane Doe", "identity": "github:janedoe",
    "public_key": "RWQAAAAAAAAAAHd26HC5M1TyoLJMI/KjbMToDiIyGMG5eSb90Bg5aiub"},
  "permissions": ["theme.apply"],
  "capabilities": ["theme"],
  "theme": {"entry": "theme.json"}
}`
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "sora-extension.json"), []byte(m), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "theme.json"), []byte("{}"), 0o644); err != nil {
		t.Fatal(err)
	}
	r := ValidateProject(dir)
	if !r.OK() {
		t.Fatalf("want OK, got %+v", r.Issues)
	}
	// Without the permission, the contract pointer must fail.
	m2 := strings.Replace(m, `"theme.apply"`, `"notifications"`, 1)
	if err := os.WriteFile(filepath.Join(dir, "sora-extension.json"), []byte(m2), 0o644); err != nil {
		t.Fatal(err)
	}
	r = ValidateProject(dir)
	if r.OK() {
		t.Fatal("want error for theme without the permission")
	}
}
