package registry

import (
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestExplicitByeDPIRequiresItsOwnHostBinary(t *testing.T) {
	r := &Registry{
		binaries:     map[engine.Kind]supervise.Binary{engine.KindSingBox: {Path: filepath.Join(t.TempDir(), "not-executed")}},
		availability: []engine.Availability{{Kind: engine.KindSingBox, Usable: true, Version: engine.Version{Major: 1, Minor: 14, Patch: 3}}},
		base:         supervise.Config{HomeDir: t.TempDir()}, preference: []engine.Kind{engine.KindSingBox},
		bypassBinary: filepath.Join(t.TempDir(), "tpws"),
	}
	p := &engine.Plan{SessionID: "byedpi", Outbounds: []engine.Outbound{{ID: "dpi", Protocol: engine.ProtocolByeDPI,
		Bypass: &engine.BypassStrategy{SplitPos: []string{"1"}}}}}
	if r.ByeDPIAvailable() {
		t.Fatal("the existing proxy must not advertise an absent ByeDPI binary")
	}
	if _, err := r.Factory()(t.Context(), p); err == nil {
		t.Fatal("missing ByeDPI silently fell back to the other proxy")
	}
	r.byedpiBinary = filepath.Join(t.TempDir(), "byedpi")
	if !r.ByeDPIAvailable() {
		t.Fatal("an installed ByeDPI was not advertised")
	}
	e, err := r.Factory()(t.Context(), p)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := e.Close(); err != nil {
			t.Error(err)
		}
	}()
	if _, ok := e.(*bypass.Engine); !ok {
		t.Fatalf("expected the owned proxy wrapper, got %T", e)
	}
}

func TestLinuxByeDPIDiscoveryRequiresExecutableHostFile(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("Linux executable permissions")
	}
	t.Setenv("PATH", t.TempDir())
	dir := t.TempDir()
	path := filepath.Join(dir, "byedpi")
	if err := os.WriteFile(path, []byte("discovery fixture, never executed"), 0o600); err != nil {
		t.Fatal(err)
	}
	r := Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir()})
	if r.byedpiBinary != "" {
		t.Fatal("a non-executable file was accepted")
	}
	if err := os.Chmod(path, 0o700); err != nil {
		t.Fatal(err)
	}
	r = Discover(t.Context(), dir, supervise.Config{HomeDir: t.TempDir()})
	if r.byedpiBinary != path {
		t.Fatalf("host binary was not discovered: %q", r.byedpiBinary)
	}
}
