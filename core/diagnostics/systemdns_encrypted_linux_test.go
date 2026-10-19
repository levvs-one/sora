//go:build linux

package diagnostics

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func writeResolvedConf(t *testing.T, dir, name, content string) string {
	t.Helper()
	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func withResolvedPaths(t *testing.T, conf, dropinDir string) {
	t.Helper()
	oldConf, oldDir := resolvedConfPath, resolvedConfDropinDir
	resolvedConfPath, resolvedConfDropinDir = conf, dropinDir
	t.Cleanup(func() { resolvedConfPath, resolvedConfDropinDir = oldConf, oldDir })
}

func TestSystemEncryptedDNS_DotEnabled(t *testing.T) {
	dir := t.TempDir()
	main := writeResolvedConf(t, dir, "resolved.conf",
		"# comment\n[Resolve]\nDNS=192.0.2.53 2001:db8::53\nDNSOverTLS=yes\n\n[Other]\nDNS=198.51.100.1\n")
	withResolvedPaths(t, main, filepath.Join(dir, "dropins"))
	got := SystemEncryptedDNS()
	want := []string{"192.0.2.53", "2001:db8::53"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestSystemEncryptedDNS_Disabled(t *testing.T) {
	dir := t.TempDir()
	main := writeResolvedConf(t, dir, "resolved.conf", "[Resolve]\nDNS=192.0.2.53\nDNSOverTLS=no\n")
	withResolvedPaths(t, main, filepath.Join(dir, "dropins"))
	got := SystemEncryptedDNS()
	if got == nil || len(got) != 0 {
		t.Errorf("disabled DoT should yield empty non-nil, got %#v", got)
	}
}

func TestSystemEncryptedDNS_DropinOverride(t *testing.T) {
	dir := t.TempDir()
	main := writeResolvedConf(t, dir, "resolved.conf", "[Resolve]\nDNSOverTLS=no\n")
	dropDir := filepath.Join(dir, "resolved.conf.d")
	if err := os.Mkdir(dropDir, 0o755); err != nil {
		t.Fatal(err)
	}
	writeResolvedConf(t, dropDir, "10-dot.conf", "[Resolve]\nDNSOverTLS=opportunistic\nDNS=203.0.113.53\n")
	withResolvedPaths(t, main, dropDir)
	got := SystemEncryptedDNS()
	want := []string{"203.0.113.53"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestSystemEncryptedDNS_NoFile(t *testing.T) {
	dir := t.TempDir()
	withResolvedPaths(t, filepath.Join(dir, "nope.conf"), filepath.Join(dir, "nodropins"))
	got := SystemEncryptedDNS()
	if got == nil || len(got) != 0 {
		t.Errorf("missing config should yield empty non-nil, got %#v", got)
	}
}
