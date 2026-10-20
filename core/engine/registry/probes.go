package registry

import (
	"context"
	"path/filepath"
	"sync"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/probeexec"
)

// Runtime fingerprint probes (CENSOR-FP): the capability overlay's
// fact source. Discover() stamps what the pins EXPECT; RefreshProbes
// measures what the installed binaries actually DO (ECH by captured
// outer SNI, key share by captured groups, spellings by hello
// arrival) and keeps the result for SelectEngineProbed callers.
//
// The store is package-level and keyed by Registry because the
// Registry struct is owned by the discovery code; the wiring that
// remains for the control plane is one call — RefreshProbes after
// Discover/rediscovery, and SelectEngineProbed in place of
// SelectEngine where a plan is routed (see reports/CENSOR-FP.md,
// escalations).

var probeStore sync.Map // *Registry -> map[engine.Kind]*engine.EngineProbe

// RefreshProbes measures every discovered binary with wire captures
// and stores the facts. It is deliberately NOT called from Discover:
// a full probe starts each binary ~15 times and belongs on an
// explicit refresh path (startup probe pass, settings "re-measure"),
// not on every rediscovery.
func (r *Registry) RefreshProbes(ctx context.Context) map[engine.Kind]*engine.EngineProbe {
	out := make(map[engine.Kind]*engine.EngineProbe)
	for _, b := range r.Binaries() {
		runner := probeexec.Runner{Dir: filepath.Dir(b.Path)}
		if pr, err := runner.Probe(ctx, b.Kind); err == nil {
			out[b.Kind] = pr
		}
	}
	probeStore.Store(r, out)
	return out
}

// Probes returns the facts from the last RefreshProbes, or nil when
// this registry was never measured (callers then judge by pin
// expectation alone — the pre-probe behaviour).
func (r *Registry) Probes() map[engine.Kind]*engine.EngineProbe {
	if v, ok := probeStore.Load(r); ok {
		return v.(map[engine.Kind]*engine.EngineProbe)
	}
	return nil
}

// SelectPlanProbed routes a plan with probe facts overlaid on the
// pin expectations: engines whose binaries measurably reject a plan
// requirement are skipped with the reason named, and a binary that
// measurably carries more than its pin claims is not refused for
// the claim's silence.
func (r *Registry) SelectPlanProbed(p *engine.Plan) (engine.Selection, error) {
	return engine.SelectEngineProbed(p, r.Availability(), r.preferenceSnapshot(), r.Probes())
}

// preferenceSnapshot copies the registry's engine order under its lock.
func (r *Registry) preferenceSnapshot() []engine.Kind {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]engine.Kind(nil), r.preference...)
}
