package registry

import (
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// CENSOR-P4 fix M4: discovery-time host facts must not stick for
// the process lifetime. Past hostFactsTTL, Availability re-probes
// and re-stamps; within the TTL it must not (the probe is cheap,
// but stamping on every call would churn shared state for nothing).
func TestAvailabilityReprobesHostFactsPastTTL(t *testing.T) {
	r := &Registry{
		availability: []engine.Availability{{Kind: engine.KindSingBox, Usable: true}},
		hostAt:       time.Now(),
	}
	// Poison the stamped facts with values the real probe cannot
	// produce together on this host (it is measured, not assumed):
	// within the TTL they must be served as-is.
	r.availability[0].HostProbed = false
	if got := r.Availability(); got[0].HostProbed {
		t.Fatal("within the TTL, stamped facts must be served unchanged")
	}
	// Age the stamp past the TTL: the next call re-probes, and on
	// Linux the probe always reports Probed=true.
	r.hostMu.Lock()
	r.hostAt = time.Now().Add(-hostFactsTTL - time.Second)
	r.hostMu.Unlock()
	got := r.Availability()
	want := supervise.ProbeHost()
	if got[0].HostProbed != want.Probed || got[0].TUNDevice != want.TUNDevice ||
		got[0].KernelWireGuard != want.KernelWireGuard {
		t.Fatalf("past the TTL, Availability = %+v, fresh probe = %+v", got[0], want)
	}
	if !got[0].HostProbed {
		t.Fatal("the Linux probe must report Probed after a re-probe")
	}
}
