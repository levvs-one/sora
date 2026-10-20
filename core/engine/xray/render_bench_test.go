package xray

import (
	"fmt"
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

// largePlan builds a subscription-shaped plan: 64 VLESS outbounds,
// two groups and 32 routing rules, for allocation-sensitive measurements.
func largePlan() *engine.Plan {
	p := enginetest.Plan(engine.ProtocolVLESS)
	base := p.Outbounds[0]
	base.Flow = ""
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
		raw, err := Render(p, testRuntime, nil)
		if err != nil {
			b.Fatal(err)
		}
		benchSink = raw
	}
}
