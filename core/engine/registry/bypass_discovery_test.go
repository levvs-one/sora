package registry

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestPlatformProxyDiscoveryDoesNotRequireUnixExecutableBitsOnWindows(t *testing.T) {
	dir := t.TempDir()
	name := "tpws"
	if runtime.GOOS == "windows" {
		name = "byedpi.exe"
	}
	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, []byte("discovery fixture, never executed"), 0o600); err != nil {
		t.Fatal(err)
	}
	registry := Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir()})
	if runtime.GOOS == "windows" {
		if registry.bypassBinary != path {
			t.Fatalf("Windows proxy was not discovered: %q", registry.bypassBinary)
		}
	} else if registry.bypassBinary != "" {
		t.Fatal("a non-executable Unix file was accepted")
	}
}
