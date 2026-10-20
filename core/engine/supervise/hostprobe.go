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
// The probes are BY USE, not by path (CENSOR-P4 fix M4): a device
// node that merely exists can be a stale leftover of a driver that
// is long gone, so TUNDevice requires the node to be a character
// device AND to open; KernelWireGuard requires the kernel itself to
// answer a generic-netlink family query for "wireguard", not a
// sysfs directory to sit on disk.
//
// The WireGuard facts record WHICH implementation would serve a
// WireGuard/AmneziaWG plan on this host: both AWG-capable engines
// (sing-box-lx with_awg, mihomo >= 1.19.30) implement WireGuard in
// userspace (amneziawg-go), so kernel WireGuard is never required —
// but the fact is probed and reported, because a future kernel-backed
// path must gate on the probed module, never on the assumption that
// a "normal" Linux has one.
type HostFacts struct {
	// Probed reports whether the probe ran on a platform it knows
	// how to read. When false, every other field is meaningless and
	// selection must not gate on them.
	Probed bool
	// TUNDevice reports a usable TUN device (/dev/net/tun on
	// Linux): the node is a character device and opening it
	// succeeds. TUN plans need it on every engine.
	TUNDevice bool
	// KernelWireGuard reports that the kernel answered a
	// generic-netlink query for the "wireguard" family, i.e. the
	// WireGuard module is loaded — the same test `wg show` makes.
	KernelWireGuard bool
}

// hostProbe injects the probe's system contacts for tests: the TUN
// node path, how a device is opened, and how kernel WireGuard is
// asked. A nil openDevice means the real open-and-close; a nil
// kernelWireGuard means this platform has no kernel-WireGuard probe
// (the fact stays false, and Linux supplies the netlink probe).
type hostProbe struct {
	tunDevice       string
	openDevice      func(path string) error
	kernelWireGuard func() bool
}

// probeHost measures the facts once. The measurement is two cheap
// syscalls (an open, a netlink query) — cheap enough that the
// registry re-probes on a TTL instead of caching the result for
// the process lifetime (see registry.hostFactsTTL): a service can
// outlive the host state it started under, devices and modules
// come and go.
func probeHost(p hostProbe) HostFacts {
	facts := HostFacts{Probed: true}
	open := p.openDevice
	if open == nil {
		open = openAndClose
	}
	// Shape first (a regular file at the path is not a device, and
	// opening one would succeed vacuously), then the fact: the
	// open itself. A hanging node whose driver is gone fails the
	// open (ENODEV) and honestly reports no TUN.
	if info, err := os.Stat(p.tunDevice); err == nil && info.Mode()&os.ModeCharDevice != 0 {
		if err := open(p.tunDevice); err == nil {
			facts.TUNDevice = true
		}
	}
	if p.kernelWireGuard != nil && p.kernelWireGuard() {
		facts.KernelWireGuard = true
	}
	return facts
}

// openAndClose opens path and closes it immediately: the probe
// claims the device works, so it must have actually opened — but
// it configures nothing and holds nothing.
func openAndClose(path string) error {
	f, err := os.Open(path) //nolint:gosec // the path is the platform's fixed TUN node (or a test fixture), never plan data
	if err != nil {
		return err
	}
	return f.Close()
}
