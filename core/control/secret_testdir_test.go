package control_test

import (
	"os"
	"testing"
)

// secretTestDir returns a temp dir with owner-only permissions, like a real
// data directory: the secret store fails closed on weakened permissions
// (SORA-L3), and testing.TempDir subdirs inherit the process umask.
func secretTestDir(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	if err := os.Chmod(dir, 0o700); err != nil {
		t.Fatal(err)
	}
	return dir
}
