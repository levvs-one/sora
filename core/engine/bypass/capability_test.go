package bypass

import (
	"context"
	"errors"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// capableCaps is the all-green snapshot the gate matrix starts from;
// each row flips exactly one fact, mirroring how a host can really be
// deficient.
func capableCaps() Capabilities {
	return Capabilities{
		Platform: "linux-nfqueue", NFTVersion: "nftables v1.1.0", NFTUsable: true,
		NFQueue: true, Privileged: true, PrivilegeVia: "root",
		TPWSBinary: true, NFQWSBinary: true,
	}
}

func TestCapabilityGateMatrix(t *testing.T) {
	nfq := DefaultStrategy()
	tpwsStrat := engine.BypassStrategy{SplitPos: []string{"1"}}

	busyAll := capableCaps()
	for i := 0; i < queueCount; i++ {
		busyAll.QueuesBusy = append(busyAll.QueuesBusy, queueBase+i)
	}
	busySome := capableCaps()
	busySome.QueuesBusy = []int{queueBase, queueBase + 1}

	rows := []struct {
		name     string
		mutate   func(*Capabilities)
		strategy engine.BypassStrategy
		wantCap  Capability // "" means the gate passes
	}{
		{"nfqws all capable", nil, nfq, ""},
		{"nfqws binary missing", func(c *Capabilities) { c.NFQWSBinary = false }, nfq, CapNFQWSBinary},
		{"platform executor pending", func(c *Capabilities) { c.Platform = "unsupported" }, nfq, CapPlatformExec},
		{"nft absent", func(c *Capabilities) { c.NFTVersion = "" }, nfq, CapNFT},
		{"nft present but unusable", func(c *Capabilities) { c.NFTUsable = false }, nfq, CapNFT},
		{"kernel cannot queue", func(c *Capabilities) { c.NFQueue = false }, nfq, CapNFQueue},
		{"no privilege", func(c *Capabilities) { c.Privileged = false }, nfq, CapPrivilege},
		{"all queues busy", func(c *Capabilities) { *c = busyAll }, nfq, CapQueueFree},
		{"some queues busy still runs", func(c *Capabilities) { *c = busySome }, nfq, ""},
		{"tpws all capable", nil, tpwsStrat, ""},
		{"tpws binary missing", func(c *Capabilities) { c.TPWSBinary = false }, tpwsStrat, CapTPWSBinary},
		{"tpws ignores kernel deficiencies", func(c *Capabilities) {
			c.TPWSBinary, c.NFQueue, c.Privileged, c.NFTVersion = true, false, false, ""
		}, tpwsStrat, ""},
		{"nfqws deficiencies do not gate tpws facts", func(c *Capabilities) {
			c.TPWSBinary, c.NFQWSBinary = true, false
		}, tpwsStrat, ""},
	}
	for _, row := range rows {
		t.Run(row.name, func(t *testing.T) {
			caps := capableCaps()
			if row.mutate != nil {
				row.mutate(&caps)
			}
			err := caps.Gate(row.strategy)
			if row.wantCap == "" {
				if err != nil {
					t.Fatalf("gate refused a capable host: %v", err)
				}
				return
			}
			var ce *CapabilityError
			if !errors.As(err, &ce) {
				t.Fatalf("gate error = %v, want a CapabilityError", err)
			}
			if ce.Capability != row.wantCap {
				t.Fatalf("gate named %q, want %q (err: %v)", ce.Capability, row.wantCap, err)
			}
			if ce.Reason == "" {
				t.Fatal("a refusal without a remedy is not honest")
			}
		})
	}
}

// TestApplyGatesOnCapabilities drives the whole Apply path with fake
// probes: the capability table, exercised end to end. The interceptor
// is the package's fake; the binaries are scripts on disk.
func TestApplyGatesOnCapabilities(t *testing.T) {
	rows := []struct {
		name    string
		caps    Capabilities
		wantErr string // substring; "" means Apply succeeds
	}{
		{"capable", capableCaps(), ""},
		{"no queue module", Capabilities{Platform: "linux-nfqueue", NFTVersion: "v1", NFTUsable: true, Privileged: true}, "nfnetlink_queue"},
		{"no privilege", Capabilities{Platform: "linux-nfqueue", NFTVersion: "v1", NFTUsable: true, NFQueue: true}, "CAP_NET_ADMIN"},
		{"nft unusable", Capabilities{Platform: "linux-nfqueue", NFTVersion: "v1", NFQueue: true, Privileged: true}, "nf_tables"},
	}
	for _, row := range rows {
		t.Run(row.name, func(t *testing.T) {
			fi := &fakeInterceptor{}
			e := Wrap(stubEngine{}, Binaries{NFQWS: fakeNFQWS(t), Assets: fakeAssets(t)}, t.TempDir(), nil)
			e.iceptOverride = fi
			caps := row.caps
			e.capsOverride = &caps
			err := e.Apply(context.Background(), nfqPlan(DefaultStrategy()))
			if row.wantErr == "" {
				if err != nil {
					t.Fatalf("Apply on a capable host: %v", err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), row.wantErr) {
				t.Fatalf("Apply = %v, want a refusal naming %q", err, row.wantErr)
			}
			if !strings.Contains(err.Error(), "outbound a") {
				t.Fatalf("the refusal must name the outbound: %v", err)
			}
			// Fail-closed means fail-FIRST: no rules were installed
			// and no process was started for a refused strategy.
			if len(fi.syncs) != 0 {
				t.Fatalf("a refused Apply installed rules: %v", fi.syncs)
			}
		})
	}
}

// TestCapabilitiesProbeIsDataOnThisHost runs the real probe: whatever
// this host is, the snapshot must be internally consistent and the
// gate's verdict must follow from it (the sandbox lacks
// nfnetlink_queue, so an nfqws refusal here is the honest answer, not
// a test failure).
func TestCapabilitiesProbeIsDataOnThisHost(t *testing.T) {
	e := Wrap(stubEngine{}, Binaries{}, t.TempDir(), nil)
	caps := e.CapabilitiesNow(context.Background())
	if caps.ProbedAt.IsZero() {
		t.Fatal("the probe must stamp its snapshot")
	}
	if caps.Platform != "linux-nfqueue" {
		t.Fatalf("platform = %q on a Linux test host", caps.Platform)
	}
	gate := caps.Gate(DefaultStrategy())
	if caps.NFQueue && caps.Privileged && caps.nftOK() {
		// Binary is not configured on this Engine, so the gate must
		// stop at the binary row even on a fully capable kernel.
		var ce *CapabilityError
		if !errors.As(gate, &ce) || ce.Capability != CapNFQWSBinary {
			t.Fatalf("gate = %v, want the nfqws-binary row", gate)
		}
	}
}

// TestStopFiltersSweepsTableAfterStrategiesRemoved pins the cleanup
// symmetry: Apply a strategy, Apply it away, then Close — the table
// must be gone, with the final interceptor state empty.
func TestStopFiltersSweepsTableAfterStrategiesRemoved(t *testing.T) {
	fi := &fakeInterceptor{}
	e := Wrap(stubEngine{}, Binaries{NFQWS: fakeNFQWS(t), Assets: fakeAssets(t)}, t.TempDir(), nil)
	e.iceptOverride = fi
	caps := capableCaps()
	e.capsOverride = &caps
	if err := e.Apply(context.Background(), nfqPlan(DefaultStrategy())); err != nil {
		t.Fatal(err)
	}
	empty := &engine.Plan{Outbounds: []engine.Outbound{{ID: "d", Protocol: engine.ProtocolDirect}}}
	if err := e.Apply(context.Background(), empty); err != nil {
		t.Fatal(err)
	}
	if err := e.Close(); err != nil {
		t.Fatal(err)
	}
	if len(fi.syncs) == 0 {
		t.Fatal("the interceptor never synced")
	}
	if last := fi.syncs[len(fi.syncs)-1]; len(last) != 0 {
		t.Fatalf("the final interceptor state = %v, want empty (no leaked table)", last)
	}
	// Every sync after the first install must be a prefix-consistent
	// replacement: no sync may resurrect a queue the plan dropped.
	for _, sync := range fi.syncs {
		for _, spec := range sync {
			if spec.Queue < queueBase || spec.Queue >= queueBase+queueCount {
				t.Fatalf("sync carries an out-of-range queue: %+v", spec)
			}
		}
	}
}

// TestGateRejectsStaleBinaryPath: a configured path that is not an
// executable file gates closed instead of failing inside the
// supervisor's restart loop.
func TestGateRejectsStaleBinaryPath(t *testing.T) {
	e := Wrap(stubEngine{}, Binaries{TPWS: filepath.Join(t.TempDir(), "gone")}, t.TempDir(), nil)
	caps := capableCaps()
	e.capsOverride = &caps
	s := engine.BypassStrategy{SplitPos: []string{"1"}}
	p := &engine.Plan{Outbounds: []engine.Outbound{{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s}}}
	err := e.Apply(context.Background(), p)
	var ce *CapabilityError
	if !errors.As(err, &ce) || ce.Capability != CapTPWSBinary {
		t.Fatalf("Apply = %v, want the tpws-binary capability row", err)
	}
}
