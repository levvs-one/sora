package bypass

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// Runtime capability probing for the desync executors.
//
// A strategy must adapt to what THIS host can actually do, measured at
// Apply time — never to assumptions baked in per-OS. Before any state
// changes, Apply probes the host once (cached briefly): is the
// nfnetlink_queue kernel path usable, is nft present and new enough,
// does the process hold the privilege the queue rules need (root or
// CAP_NET_ADMIN, or the privileged helper path), are the NFQUEUE
// numbers sora hands out already taken by someone else? The probe
// result is DATA: Gate consumes it as a decision table over the
// strategy, so tests drive every row with fake probes and the live
// path and the test path are the same code.
//
// A missing capability is an honest refusal at Apply, naming the
// capability and the remedy — never a silent skip of the obfuscation
// and never a fallback to direct.

// Capability names one host capability a backend depends on.
type Capability string

const (
	CapTPWSBinary   Capability = "tpws binary"
	CapNFQWSBinary  Capability = "nfqws binary"
	CapNFT          Capability = "nftables (nft)"
	CapNFQueue      Capability = "nfnetlink_queue kernel module"
	CapPrivilege    Capability = "privilege (root / CAP_NET_ADMIN)"
	CapQueueFree    Capability = "a free NFQUEUE number"
	CapPlatformExec Capability = "platform executor"
)

// CapabilityError is a fail-closed Apply refusal: the named capability
// is missing on this host. Reason tells the user what to do about it.
type CapabilityError struct {
	Capability Capability
	Reason     string
}

func (e *CapabilityError) Error() string {
	return fmt.Sprintf("bypass: this host lacks %s: %s", e.Capability, e.Reason)
}

// Capabilities is one probe snapshot. Every field is measured, not
// assumed; the zero value means "nothing probed yet" and gates closed.
type Capabilities struct {
	// Platform is the executor family ("linux-nfqueue", "windows-windivert-pending", ...).
	Platform string
	// TPWSBinary / NFQWSBinary report the discovered binaries are
	// present and executable (set by the Engine from its Binaries,
	// not by the platform probe).
	TPWSBinary  bool
	NFQWSBinary bool
	// NFTVersion is the probed nft version ("" when nft is absent).
	NFTVersion string
	// NFTUsable reports a dry-run ruleset check passed: nft can talk
	// to the kernel's nf_tables. Distinct from presence — a binary
	// can exist on a kernel without nf_tables.
	NFTUsable bool
	// NFQueue reports the kernel can queue packets to userspace:
	// nfnetlink_queue is loaded/available and a dry-run queue rule
	// validates.
	NFQueue bool
	// Privileged reports the process can install queue rules:
	// euid 0, CAP_NET_ADMIN, or the privileged helper path.
	Privileged bool
	// PrivilegeVia names how Privileged holds ("root", "CAP_NET_ADMIN",
	// "polkit helper"), for logs and honest errors.
	PrivilegeVia string
	// QueuesBusy lists NFQUEUE numbers in sora's range already bound
	// by another process (from /proc/net/nfnetlink_queue).
	QueuesBusy []int
	// ProbedAt is when the snapshot was taken.
	ProbedAt time.Time
}

// nftUsable reports whether the nft capability holds.
func (c Capabilities) nftOK() bool { return c.NFTVersion != "" && c.NFTUsable }

// freeQueues counts sora's queue range not reported busy.
func (c Capabilities) freeQueues() int {
	busy := make(map[int]bool, len(c.QueuesBusy))
	for _, q := range c.QueuesBusy {
		busy[q] = true
	}
	free := 0
	for i := 0; i < queueCount; i++ {
		if !busy[queueBase+i] {
			free++
		}
	}
	return free
}

// Gate decides, from the probed capabilities alone, whether the host
// can run strategy s on its backend. It is the single decision table
// for backend capability: Apply calls it before touching any state,
// and the tuner calls it to filter candidates it would be pointless to
// probe. A nil return means "capable"; anything else is a
// *CapabilityError naming the first missing capability.
func (c Capabilities) Gate(s engine.BypassStrategy) error {
	switch BackendOf(s) {
	case BackendTPWS:
		if !c.TPWSBinary {
			return &CapabilityError{CapTPWSBinary,
				"tpws is not installed in the engines directory (or is not executable); install the zapret helpers or remove the strategy"}
		}
		return nil
	case BackendNFQWS:
		if !c.NFQWSBinary {
			return &CapabilityError{CapNFQWSBinary,
				"nfqws is not installed in the engines directory (or is not executable); install the zapret helpers"}
		}
		if c.Platform != "" && c.Platform != "linux-nfqueue" {
			return &CapabilityError{CapPlatformExec, platformExecutorNote()}
		}
		if !c.nftOK() {
			if c.NFTVersion == "" {
				return &CapabilityError{CapNFT,
					"nft was not found in the system directories; install nftables to run nfqws strategies"}
			}
			return &CapabilityError{CapNFT,
				fmt.Sprintf("nft %s is present but cannot talk to the kernel's nf_tables (dry-run check failed); the kernel may lack nf_tables or the binary is too old", c.NFTVersion)}
		}
		if !c.NFQueue {
			return &CapabilityError{CapNFQueue,
				"the kernel cannot queue packets to userspace (nfnetlink_queue is not loaded and a queue rule does not validate); load the module (modprobe nfnetlink_queue) or choose a tpws strategy"}
		}
		if !c.Privileged {
			return &CapabilityError{CapPrivilege,
				"installing NFQUEUE rules needs root or CAP_NET_ADMIN; run the core as the privileged service (or via its polkit helper) or choose a tpws strategy"}
		}
		if c.freeQueues() == 0 {
			return &CapabilityError{CapQueueFree,
				fmt.Sprintf("every NFQUEUE number in sora's range %d-%d is already bound by another process", queueBase, queueBase+queueCount-1)}
		}
		return nil
	}
	return nil
}

// capsCacheTTL bounds how stale a capability snapshot may be when an
// Apply reuses it. Capabilities change (module loads, another process
// grabs a queue), so the cache is short; a fresh probe is a few local
// execs, cheap next to starting processes.
const capsCacheTTL = 30 * time.Second

// probeCapabilities is the platform probe (capability_linux.go /
// capability_other.go). It measures the kernel/tooling side only;
// binary presence is layered on by capabilities() from the Engine's
// discovered binaries.
var probeCapabilities = defaultProbeCapabilities

// capabilities returns the Engine's current snapshot, probing when
// the cache is stale. Test seams: capsOverride pins the snapshot,
// and an iceptOverride (the executor's own test seam) implies the
// kernel side is faked too, so the snapshot reports the platform
// executor as capable while binary presence still comes from the
// configured Binaries.
func (e *Engine) capabilities(ctx context.Context) Capabilities {
	e.capsMu.Lock()
	if e.capsOverride != nil {
		caps := *e.capsOverride
		e.capsMu.Unlock()
		return e.withBinaries(caps)
	}
	if e.caps != nil && time.Since(e.caps.ProbedAt) < capsCacheTTL {
		caps := *e.caps
		e.capsMu.Unlock()
		return e.withBinaries(caps)
	}
	e.capsMu.Unlock()

	var caps Capabilities
	if e.iceptOverride != nil {
		caps = Capabilities{Platform: "linux-nfqueue", NFTVersion: "test-seam", NFTUsable: true,
			NFQueue: true, Privileged: true, PrivilegeVia: "test seam", ProbedAt: time.Now()}
	} else {
		caps = probeCapabilities(ctx)
	}
	e.capsMu.Lock()
	e.caps = &caps
	e.capsMu.Unlock()
	return e.withBinaries(caps)
}

// withBinaries layers the discovered-binary facts onto a snapshot:
// the binaries come from the registry's digest-verified discovery,
// and a configured path that is not an executable file does not count
// as present (a stale path must gate closed, not fail later inside a
// supervisor restart loop).
func (e *Engine) withBinaries(c Capabilities) Capabilities {
	c.TPWSBinary = executableFile(e.tpws)
	c.NFQWSBinary = executableFile(e.nfqws)
	return c
}

func executableFile(path string) bool {
	if path == "" {
		return false
	}
	fi, err := os.Stat(path)
	return err == nil && !fi.IsDir() && fi.Mode()&0o111 != 0
}

// gateStrategies fails closed before any state changes when a needed
// strategy's backend capability is missing on this host. ids maps
// each strategy key to an outbound carrying it, for attribution.
func (e *Engine) gateStrategies(ctx context.Context, tpwsNeeded, nfqNeeded map[string]engine.BypassStrategy, tpwsIDs, nfqIDs map[string]string) error {
	if len(tpwsNeeded) == 0 && len(nfqNeeded) == 0 {
		return nil
	}
	caps := e.capabilities(ctx)
	for k, s := range nfqNeeded {
		if err := caps.Gate(s); err != nil {
			return fmt.Errorf("bypass: outbound %s: %w", nfqIDs[k], err)
		}
	}
	for k, s := range tpwsNeeded {
		if err := caps.Gate(s); err != nil {
			return fmt.Errorf("bypass: outbound %s: %w", tpwsIDs[k], err)
		}
	}
	return nil
}

// CapabilitiesNow exposes the Engine's current capability snapshot for
// diagnostics and for the tuner's candidate filtering: what this host
// can run, as data.
func (e *Engine) CapabilitiesNow(ctx context.Context) Capabilities {
	return e.capabilities(ctx)
}

// ProbeCapabilities measures a capability snapshot for the given
// binaries without an Engine: the platform probe (kernel, nft,
// privilege, queues) plus the same executable-file check withBinaries
// layers onto engine snapshots. It backs surfaces that must report
// measured availability without a live engine — the extension host's
// GetBypassCapabilities — with exactly the Gate semantics Apply uses,
// so a backend reported available here is one the gate would admit.
func ProbeCapabilities(ctx context.Context, bins Binaries) Capabilities {
	caps := probeCapabilities(ctx)
	caps.TPWSBinary = executableFile(bins.TPWS)
	caps.NFQWSBinary = executableFile(bins.NFQWS)
	return caps
}
