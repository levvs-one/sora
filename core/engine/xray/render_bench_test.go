package xray

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// benchSink keeps the compiler from optimizing rendered configs away.
var benchSink []byte

// BenchmarkRenderVLESSRealityMux renders the shared full plan with one
// VLESS+REALITY outbound whose vision flow is cleared, so the mux block
// Xray skips under xtls-rprx-vision is exercised (mux is on by default
// for REALITY).
func BenchmarkRenderVLESSRealityMux(b *testing.B) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Outbounds[0].Flow = ""
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		raw, err := Render(p, testRuntime, nil)
		if err != nil {
			b.Fatal(err)
		}
		benchSink = raw
	}
}

// BenchmarkRenderVLESSRealityVision renders the shared full plan as-is:
// VLESS+REALITY with the vision flow (the common session shape).
func BenchmarkRenderVLESSRealityVision(b *testing.B) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		raw, err := Render(p, testRuntime, nil)
		if err != nil {
			b.Fatal(err)
		}
		benchSink = raw
	}
}

// BenchmarkRenderAllProtocols renders the plan carrying every protocol
// Xray supports.
func BenchmarkRenderAllProtocols(b *testing.B) {
	p := hysteriaWithoutObfs(enginetest.Plan(allProtocols...))
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		raw, err := Render(p, testRuntime, nil)
		if err != nil {
			b.Fatal(err)
		}
		benchSink = raw
	}
}

func BenchmarkBuildCapabilities(b *testing.B) {
	ver := engine.Version{Major: 26, Minor: 3, Patch: 27}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = engine.BuildCapabilities(engine.KindXray, ver, nil)
	}
}

// BenchmarkXrayPlaintextGate exercises the versioned plaintext cutoff:
// a build at or past 26.7.11 must scan the plan's VLESS/Trojan outbounds.
func BenchmarkXrayPlaintextGate(b *testing.B) {
	caps := engine.BuildCapabilities(engine.KindXray, engine.Version{Major: 26, Minor: 3, Patch: 27}, nil)
	p := enginetest.Plan(engine.ProtocolVLESS, engine.ProtocolTrojan)
	ver := engine.Version{Major: 26, Minor: 7, Patch: 11}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = caps.XrayPlaintextMissing(p, ver)
	}
}

func BenchmarkVersionLess(b *testing.B) {
	a := engine.Version{Major: 26, Minor: 3, Patch: 27}
	c := engine.Version{Major: 26, Minor: 7, Patch: 11}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = a.Less(c)
	}
}
