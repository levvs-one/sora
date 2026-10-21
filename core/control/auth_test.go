package control_test

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/control"
)

// TestRotatePersistsTheToken: rotation must survive a restart.
// After Rotate, the new token verifies and the old one does not, both in
// memory and after reloading from disk.
func TestRotatePersistsTheToken(t *testing.T) {
	dir := t.TempDir()
	auth, err := control.LoadOrCreateToken(dir)
	if err != nil {
		t.Fatalf("LoadOrCreateToken() error = %v", err)
	}
	old := auth.Token()
	fresh, err := auth.Rotate()
	if err != nil {
		t.Fatalf("Rotate() error = %v", err)
	}
	if !auth.Verify(fresh) {
		t.Error("Rotate() token does not verify in memory")
	}
	if auth.Verify(old) {
		t.Error("the old token still verifies after rotation")
	}
	reloaded, err := control.LoadOrCreateToken(dir)
	if err != nil {
		t.Fatalf("LoadOrCreateToken() after rotation error = %v", err)
	}
	if !reloaded.Verify(fresh) {
		t.Error("the rotated token does not verify after reload")
	}
	if reloaded.Verify(old) {
		t.Error("the old token verifies after reload; the rotation did not persist")
	}
	info, err := os.Stat(filepath.Join(dir, "control.token"))
	if err != nil {
		t.Fatalf("stat token file: %v", err)
	}
	// Windows has no POSIX mode bits; Go reports 0666 for any writable file
	// there, so only Unix can observe the 0600 the writer requests.
	if mode := info.Mode().Perm(); runtime.GOOS != "windows" && mode != 0o600 {
		t.Errorf("token file mode = %o, want 600", mode)
	}
}

// TestRotateWithoutAFileFailsClosed ensures an authenticator built from a
// bare token cannot rotate into a memory/disk split.
func TestRotateWithoutAFileFailsClosed(t *testing.T) {
	auth, err := control.NewAuthenticator(make([]byte, control.TokenLen))
	if err != nil {
		t.Fatalf("NewAuthenticator() error = %v", err)
	}
	if _, err := auth.Rotate(); err == nil {
		t.Error("Rotate() on a file-less authenticator succeeded; want an error")
	}
}
