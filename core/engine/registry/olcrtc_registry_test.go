package registry

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/errs"
)

// writeOlcrtcEnginesDir lays out an engines directory holding one
// fake olcrtc binary and a digests manifest naming it with the
// given digest (the real one when correct is true).
func writeOlcrtcEnginesDir(t *testing.T, correct bool) string {
	t.Helper()
	dir := t.TempDir()
	body := []byte("#!/bin/sh\nexec sleep 3600\n")
	if err := os.WriteFile(filepath.Join(dir, "olcrtc"), body, 0o755); err != nil {
		t.Fatal(err)
	}
	sum := sha256.Sum256(body)
	digest := hex.EncodeToString(sum[:])
	if !correct {
		digest = hex.EncodeToString(make([]byte, 32))
	}
	if err := os.WriteFile(filepath.Join(dir, "engines.digests"), []byte(digest+"  olcrtc\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	return dir
}

func TestDiscoverOlcrtcDigestGate(t *testing.T) {
	// A sidecar whose digest matches engines.digests is available.
	r := Discover(context.Background(), writeOlcrtcEnginesDir(t, true), supervise.Config{})
	if !r.OlcrtcAvailable() {
		t.Fatal("digest-verified olcrtc not discovered")
	}
	// A tampered sidecar is not: SORA-H5 fail-closed, exactly like
	// tpws. The plan gate then names the missing binary.
	r = Discover(context.Background(), writeOlcrtcEnginesDir(t, false), supervise.Config{})
	if r.OlcrtcAvailable() {
		t.Fatal("digest-mismatched olcrtc was accepted")
	}
	key := strings.Repeat("a", 64)
	p := &engine.Plan{Outbounds: []engine.Outbound{{
		ID: "o", Protocol: engine.ProtocolOLCRTC, Password: key,
		Olcrtc: &engine.OlcrtcConfig{Provider: "jitsi", Transport: "datachannel", Room: "room-1"},
	}}}
	_, err := r.Factory()(context.Background(), p)
	var ce *errs.Error
	if err == nil || !errors.As(err, &ce) || ce.Key() != errs.KeyEngineBinaryMissing {
		t.Fatalf("factory error = %v, want key %s", err, errs.KeyEngineBinaryMissing)
	}
}
