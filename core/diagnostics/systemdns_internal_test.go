//go:build !windows

package diagnostics

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func writeResolvConf(t *testing.T, content string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "resolv.conf")
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestSystemResolversFromFile(t *testing.T) {
	path := writeResolvConf(t, "# comment\n; another comment\n\nnameserver 192.0.2.1\nnameserver 2001:db8::1\nsearch example.com\noptions ndots:1\nnameserver 192.0.2.1\n")
	got := systemResolversFromFile(path)
	want := []string{"192.0.2.1", "2001:db8::1", "192.0.2.1"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestSystemResolversFromFile_Missing(t *testing.T) {
	if got := systemResolversFromFile(filepath.Join(t.TempDir(), "nope.conf")); got != nil {
		t.Errorf("missing file should yield nil, got %q", got)
	}
}

func TestSystemResolversFromFile_Empty(t *testing.T) {
	path := writeResolvConf(t, "# only comments\n")
	if got := systemResolversFromFile(path); len(got) != 0 {
		t.Errorf("comment-only file should yield nothing, got %q", got)
	}
}
