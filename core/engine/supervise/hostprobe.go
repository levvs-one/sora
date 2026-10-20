package supervise

import (
	"os"
)

// HostFacts are the host capabilities sora PROBES at discovery time
// instead of assuming from the shipped pins (CENSOR-P4, owner review
// criterion: adaptivity to the system). Engine selection consumes
// these facts — a plan that needs a capability the probed host does
// not have is refused at selection with the missing fact named,
// instead of dying inside an engine start with an opaque error.
//
// The WireGuard facts record WHICH implementation would serve a
// WireGuard/AmneziaWG plan on this host: both AWG-capable engines
// (sing-box-lx with_awg, mihomo >= 1.19.30) implement WireGuard in
// userspace (amneziawg-go), so kernel WireGuard is never required —
// but the fact is probed and reported, because a future kernel-backed
// path must gate on the probed module, never on the assumption that
// a "normal" Linux has one. This VM is the standing counterexample:
// it has no kernel WireGuard and no /dev/net/tun, yet userspace AWG
// works.
type HostFacts struct {
	// Probed reports whether the probe ran on a platform it knows
	// how to read. When false, every other field is meaningless and
	// selection must not gate on them.
	Probed bool
	// TUNDevice reports a usable TUN device node (/dev/net/tun on
	// Linux). TUN plans need it on every engine.
	TUNDevice bool
	// KernelWireGuard reports the kernel WireGuard module
	// (/sys/module/wireguard on Linux).
	KernelWireGuard bool
}

// hostPaths names the filesystem facts probeHost reads, injectable
// for tests.
type hostPaths struct {
	tunDevice string
	wgModule  string
}

func probeHost(p hostPaths) HostFacts {
	facts := HostFacts{Probed: true}
	if info, err := os.Stat(p.tunDevice); err == nil && info.Mode()&os.ModeCharDevice != 0 {
		facts.TUNDevice = true
	}
	if info, err := os.Stat(p.wgModule); err == nil && info.IsDir() {
		facts.KernelWireGuard = true
	}
	return facts
}
