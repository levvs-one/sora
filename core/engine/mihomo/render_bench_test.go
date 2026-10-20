package mihomo

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/enginetest"
)

// benchSink keeps the compiler from optimizing rendered configs away.
var benchSink string

var benchRuntime = Runtime{
	ControllerAddr: "127.0.0.1:23456",
	Secret:         "c0ffee",
	MixedPort:      21000,
	TestURL:        engine.TestURLProduction,
}

// BenchmarkRenderVLESSRealityMux renders the shared full plan: one
// VLESS+REALITY outbound (smux is on by default for REALITY), select and
// url-test groups, geo/domain rules and three DNS transports.
func BenchmarkRenderVLESSRealityMux(b *testing.B) {
	p := enginetest.Plan(engine.ProtocolVLESS)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		out, err := Render(p, benchRuntime)
		if err != nil {
			b.Fatal(err)
		}
		benchSink = out
	}
}

// BenchmarkRenderAllProtocols renders the package's own full plan (VLESS,
// Hysteria2, direct; groups, rules, fake-IP DNS and TUN).
func BenchmarkRenderAllProtocols(b *testing.B) {
	p := testPlan()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		out, err := Render(p, benchRuntime)
		if err != nil {
			b.Fatal(err)
		}
		benchSink = out
	}
}

func BenchmarkBuildCapabilities(b *testing.B) {
	ver := engine.Version{Major: 1, Minor: 19, Patch: 32}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = engine.BuildCapabilities(engine.KindMihomo, ver, nil)
	}
}

func BenchmarkVersionLess(b *testing.B) {
	a := engine.Version{Major: 1, Minor: 19, Patch: 32}
	c := engine.Version{Major: 1, Minor: 20}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = a.Less(c)
	}
}
