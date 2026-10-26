package registry

import (
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/winws"
)

func TestWinwsFactoryRequiresItsOwnBundleAndPreservesDedicatedWrapper(t *testing.T) {
	r := &Registry{binaries: map[engine.Kind]supervise.Binary{engine.KindSingBox: {Path: filepath.Join(t.TempDir(), "not-executed")}},
		availability: []engine.Availability{{Kind: engine.KindSingBox, Usable: true, Version: engine.Version{Major: 1, Minor: 14, Patch: 3}}},
		base:         supervise.Config{HomeDir: t.TempDir()}, preference: []engine.Kind{engine.KindSingBox}, bypassBinary: "installed-byedpi-is-not-winws"}
	p := &engine.Plan{SessionID: "filter", Outbounds: []engine.Outbound{{ID: "filter", Protocol: engine.ProtocolWinws,
		Bypass: &engine.BypassStrategy{SplitPos: []string{"1"}}}}}
	if _, err := r.Factory()(t.Context(), p); err == nil {
		t.Fatal("missing Winws fell back to installed ByeDPI")
	}
	r.winwsBinary = filepath.Join(t.TempDir(), "winws.exe")
	e, err := r.Factory()(t.Context(), p)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := e.Close(); err != nil {
			t.Error(err)
		}
	}()
	if _, ok := e.(*winws.Engine); !ok {
		t.Fatalf("filter ownership lost: %T", e)
	}
	if r.LastSelection().Kind != engine.KindSingBox {
		t.Fatal("direct projection was not selected")
	}
}
