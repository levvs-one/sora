package pack

import (
	"os"
	"path/filepath"
	"testing"
)

// Regression test for the 2026-10-20 audit finding (N1): the first
// shipped example .soraext packages embedded their author.key secret
// inside the archive. Collect must refuse loudly instead of packing
// key files silently.
func TestCollectRefusesKeyFiles(t *testing.T) {
	for _, keyName := range []string{"author.key", "author.secret.key", "some.key"} {
		dir := t.TempDir()
		if err := os.WriteFile(filepath.Join(dir, "sora-extension.json"), []byte("{}"), 0o644); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(dir, keyName), []byte("untrusted comment: key\n"), 0o600); err != nil {
			t.Fatal(err)
		}
		if _, err := Collect(dir); err == nil {
			t.Fatalf("Collect(%q) accepted the key file, want a refusal", keyName)
		}
	}
}

// Sanity: a normal project without key files still collects.
func TestCollectAcceptsCleanProject(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "panel.html"), []byte("<p>hi</p>"), 0o644); err != nil {
		t.Fatal(err)
	}
	files, err := Collect(dir)
	if err != nil {
		t.Fatalf("Collect failed on a clean project: %v", err)
	}
	if _, ok := files["panel.html"]; !ok {
		t.Fatalf("Collect dropped panel.html: %v", files)
	}
}
