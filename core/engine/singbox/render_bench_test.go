package singbox

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// benchSink keeps the compiler from optimizing rendered configs away.
var benchSink []byte

// BenchmarkRenderVLESSRealityMux renders the shared full plan: one
// VLESS+REALITY outbound (mux is on by default for REALITY), select and
// url-test groups, geo/domain rules and three DNS transports.
func BenchmarkRenderVLESSRealityMux(b *testing.B) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		raw, err := Render(p, testRuntime)
		if err != nil {
			b.Fatal(err)
		}
		benchSink = raw
	}
}

// BenchmarkRenderAllProtocols renders the plan carrying every protocol
// sing-box supports.
func BenchmarkRenderAllProtocols(b *testing.B) {
	p := enginetest.Plan(allProtocols...)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		raw, err := Render(p, testRuntime)
		if err != nil {
			b.Fatal(err)
		}
		benchSink = raw
	}
}

// BenchmarkRenderVersionedTun exercises the versioned gates: a TUN plan
// rendered for a 1.15 build (no legacy stack key, multi_queue on).
func BenchmarkRenderVersionedTun(b *testing.B) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	p.Tun = engine.Tun{Enabled: true, Stack: "mixed"}
	ver := engine.Version{Major: 1, Minor: 15}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		raw, err := renderVersioned(p, testRuntime, ver)
		if err != nil {
			b.Fatal(err)
		}
		benchSink = raw
	}
}

func BenchmarkBuildCapabilities(b *testing.B) {
	ver := engine.Version{Major: 1, Minor: 14, Patch: 3, PreRelease: "lx.14"}
	tags := []string{"with_xhttp", "with_awg"}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = engine.BuildCapabilities(engine.KindSingBox, ver, tags)
	}
}

func BenchmarkVersionLess(b *testing.B) {
	a := engine.Version{Major: 1, Minor: 14, Patch: 3}
	c := engine.Version{Major: 1, Minor: 15}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = a.Less(c)
	}
}
