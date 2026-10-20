package mihomo

import (
	"fmt"
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

// largePlan builds a subscription-shaped plan: 64 VLESS outbounds,
// two groups and 32 routing rules, for allocation-sensitive measurements.
func largePlan() *engine.Plan {
	p := enginetest.Plan(engine.ProtocolVLESS)
	base := p.Outbounds[0]
	p.Outbounds = p.Outbounds[:0]
	for i := 0; i < 64; i++ {
		o := base
		o.ID = fmt.Sprintf("srv-%d", i)
		o.Name = fmt.Sprintf("Server %d", i)
		o.Server = fmt.Sprintf("edge-%d.example.com", i)
		p.Outbounds = append(p.Outbounds, o)
	}
	ids := make([]string, 0, 64)
	for _, o := range p.Outbounds {
		ids = append(ids, o.ID)
	}
	p.Groups = []engine.Group{
		{Name: "Auto", Type: engine.GroupURLTest, Outbounds: ids, Interval: 300, Tolerance: 50},
		{Name: "Proxy", Type: engine.GroupSelect, Outbounds: append([]string{"Auto"}, ids...)},
	}
	p.Rules = p.Rules[:0]
	for i := 0; i < 32; i++ {
		p.Rules = append(p.Rules, engine.Rule{Type: engine.RuleDomainSuffix, Value: fmt.Sprintf("zone-%d.example", i), Target: "Proxy"})
	}
	p.Rules = append(p.Rules, engine.Rule{Type: engine.RuleMatchAll, Target: "Proxy"})
	return p
}

// BenchmarkRenderLargePlan renders a subscription-shaped plan (64
// outbounds, 32 rules): the workload where pre-sized render buffers pay
// off most.
func BenchmarkRenderLargePlan(b *testing.B) {
	p := largePlan()
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
