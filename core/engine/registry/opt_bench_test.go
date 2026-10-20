package registry

import (
	"context"
	"fmt"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// BenchmarkFactoryAdmit200 measures the connect admit path for a large
// plan with no engines installed: capability selection runs in full and
// the plan is rejected only at the missing-binary check.
func BenchmarkFactoryAdmit200(b *testing.B) {
	r := Discover(context.Background(), "", supervise.Config{})
	factory := r.Factory()
	plan := &engine.Plan{SessionID: "bench"}
	for i := 0; i < 200; i++ {
		plan.Outbounds = append(plan.Outbounds, engine.Outbound{
			ID:       fmt.Sprintf("srv-%d", i),
			Protocol: engine.ProtocolDirect,
		})
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, err := factory(context.Background(), plan); err == nil {
			b.Fatal("no engines installed: admit must fail")
		}
	}
}

// BenchmarkFactoryAdmit200Bypass is the control for BenchmarkFactoryAdmit200:
// the same 200-outbound plan, but every outbound is a bypass outbound and
// tpws is present, so the admit path must rewrite the plan to SOCKS5
// exactly as before.
func BenchmarkFactoryAdmit200Bypass(b *testing.B) {
	r := &Registry{
		binaries:   map[engine.Kind]supervise.Binary{},
		preference: engine.DefaultPreference,
		tpws:       "/tpws",
	}
	factory := r.Factory()
	strategy := &engine.BypassStrategy{SplitPos: []string{"1"}}
	plan := &engine.Plan{SessionID: "bench"}
	for i := 0; i < 200; i++ {
		plan.Outbounds = append(plan.Outbounds, engine.Outbound{
			ID:       fmt.Sprintf("srv-%d", i),
			Protocol: engine.ProtocolBypass,
			Bypass:   strategy,
		})
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, err := factory(context.Background(), plan); err == nil {
			b.Fatal("no engines installed: admit must fail")
		}
	}
}
