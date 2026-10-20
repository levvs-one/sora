package supervise

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
)

// CENSOR-P4 + fix M4: host facts come from probing BY USE, not from
// assuming a "normal" host and not from mere path existence: the
// TUN node must be a character device AND open, kernel WireGuard
// must be answered by the kernel probe — and their absence is
// reported, not papered over.
func TestProbeHostFacts(t *testing.T) {
	dir := t.TempDir()
	noWG := func() bool { return false }
	// No TUN node, no kernel WireGuard: both facts false, probe
	// still "ran".
	facts := probeHost(hostProbe{
		tunDevice:       filepath.Join(dir, "tun"),
		kernelWireGuard: noWG,
	})
	if !facts.Probed || facts.TUNDevice || facts.KernelWireGuard {
		t.Fatalf("empty host probe = %+v", facts)
	}
	// A regular file at the TUN path is NOT a TUN device, even
	// though opening one would succeed.
	if err := os.WriteFile(filepath.Join(dir, "tun"), []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	facts = probeHost(hostProbe{
		tunDevice:       filepath.Join(dir, "tun"),
		kernelWireGuard: func() bool { return true },
	})
	if facts.TUNDevice {
		t.Fatal("a regular file must not count as a TUN device")
	}
	if !facts.KernelWireGuard {
		t.Fatal("a positive kernel-WireGuard probe must be reported")
	}
	// A character device that opens counts. /dev/null stands in
	// for the shape: it is a character device and it opens.
	facts = probeHost(hostProbe{tunDevice: "/dev/null", kernelWireGuard: noWG})
	if !facts.TUNDevice {
		t.Fatal("a character device that opens must count as a TUN device")
	}
	// A character device whose OPEN fails (a hanging node with no
	// live driver behind it) must NOT count: existence is not the
	// fact, the open is.
	facts = probeHost(hostProbe{
		tunDevice: "/dev/null",
		openDevice: func(string) error {
			return errors.New("no such device")
		},
		kernelWireGuard: noWG,
	})
	if facts.TUNDevice {
		t.Fatal("a TUN node that does not open must not count as a TUN device")
	}
}

// The Linux netlink probe must agree with the kernel's own module
// state as far as the sandbox lets it run: where the wireguard
// module is not loaded (no /sys/module/wireguard), the family
// cannot be registered and the probe must answer false. Where the
// socket itself is denied the probe also answers false (documented
// behaviour), so this asserts only the one direction that can
// never legitimately differ.
func TestNetlinkWireGuardAbsentModule(t *testing.T) {
	if _, err := os.Stat("/sys/module/wireguard"); err == nil {
		t.Skip("wireguard module is loaded on this host; absence direction not testable")
	}
	if netlinkHasWireGuardFamily() {
		t.Fatal("netlink reports a wireguard family while the module is not loaded")
	}
}

// ProbeHost on this machine must return measured facts without
// panicking, whatever the sandbox allows.
func TestProbeHostRuns(t *testing.T) {
	facts := ProbeHost()
	if !facts.Probed {
		t.Fatal("the Linux probe must report Probed")
	}
}
