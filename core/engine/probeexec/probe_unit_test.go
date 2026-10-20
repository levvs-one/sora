package probeexec

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// TestProbeFakeBinary: orchestration against a fake engine that
// passes config checks but dies on run. Every measurement must
// degrade to a named failure (no fabricated verdicts, no hang past
// the capture budget).
func TestProbeFakeBinary(t *testing.T) {
	dir := t.TempDir()
	script := "#!/bin/sh\ncase \" $* \" in *\" check \"*|*\" -t \"*|*\" -test \"*) exit 0;; *) echo fake-engine-boom >&2; exit 1;; esac\n"
	for _, name := range []string{"sing-box", "mihomo", "xray"} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(script), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	r := Runner{Dir: dir, CaptureTimeout: 2 * time.Second}
	// ConfigCheck passes against the fake.
	p := echPlan()
	p.Outbounds[0].Port = 443
	if err := r.ConfigCheck(engine.KindMihomo, []byte("proxies: []\n")); err != nil {
		t.Errorf("fake config check must pass, got %v", err)
	}
	// A capture against the dying fake fails fast with the cause
	// named, bounded by the capture budget.
	start := time.Now()
	if _, err := r.capture(context.Background(), engine.KindMihomo, echPlan()); err == nil {
		t.Error("capture against a dying binary must fail")
	}
	if elapsed := time.Since(start); elapsed > 15*time.Second {
		t.Errorf("capture took %v, want it bounded near the 2s budget", elapsed)
	}
}
