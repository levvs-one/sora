package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLegacyKeepsOrdinaryProfileSeparate(t *testing.T) {
	t.Setenv("SORA_DATA_DIR", filepath.Join(t.TempDir(), "ordinary"))
	t.Setenv("SORA_LEGACY_DATA_DIR", "")
	config, err := os.UserConfigDir()
	if err != nil {
		t.Fatal(err)
	}
	if got, want := defaultDataDir(), filepath.Join(config, "sora-legacy", "core"); got != want {
		t.Fatalf("legacy profile = %s, want %s", got, want)
	}
	legacy := filepath.Join(t.TempDir(), "legacy")
	t.Setenv("SORA_LEGACY_DATA_DIR", legacy)
	if got := defaultDataDir(); got != legacy {
		t.Fatalf("explicit legacy profile = %s, want %s", got, legacy)
	}
}
