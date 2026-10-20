package xray

import (
	"encoding/base64"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// mldsa65Verify is a shape-valid ML-DSA-65 verification key (1952
// bytes, raw base64url). The binary test below replaces it with a
// generated key; render tests only pin where the value lands.
var mldsa65Verify = base64.RawURLEncoding.EncodeToString(make([]byte, 1952))

// TestRenderMLDSA65Verify pins the Xray render of the plan's pinned
// ML-DSA-65 key (CENSOR-P1): realitySettings.mldsa65Verify on the
// main stream.
func TestRenderMLDSA65Verify(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].TLS.RealityMLDSA65Verify = mldsa65Verify
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(raw), `"mldsa65Verify":"`+mldsa65Verify+`"`) {
		t.Fatalf("render must carry mldsa65Verify:\n%s", raw)
	}
}

// TestRenderMLDSA65VerifyOnDownloadLeg pins the split-XHTTP leg: the
// downlink dials its own REALITY stream, so it must verify the same
// ML-DSA-65 key — a leg without it would be a weaker handshake to a
// different server.
func TestRenderMLDSA65VerifyOnDownloadLeg(t *testing.T) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	o := &p.Outbounds[0]
	o.Flow = "" // vision needs TCP or VLESS Encryption; this leg is XHTTP
	o.TLS.RealityMLDSA65Verify = mldsa65Verify
	o.Transport = engine.Transport{Type: "xhttp", Path: "/x", Mode: "stream-up",
		DownloadAddress: "dl.example.com", DownloadPort: 8443}
	raw, err := Render(p, testRuntime, nil)
	if err != nil {
		t.Fatal(err)
	}
	if n := strings.Count(string(raw), `"mldsa65Verify":"`+mldsa65Verify+`"`); n != 2 {
		t.Fatalf("mldsa65Verify must render on both XHTTP legs, found %d:\n%s", n, raw)
	}
}
