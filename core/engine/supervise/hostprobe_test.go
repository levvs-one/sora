package supervise

import (
	"os"
	"path/filepath"
	"testing"
)

// CENSOR-P4: host facts come from probing the filesystem, not from
// assuming a "normal" host: a char device at the TUN path and a
// module directory are the facts, and their absence is reported, not
// papered over.
func TestProbeHostFacts(t *testing.T) {
	dir := t.TempDir()
	// No TUN node, no module: both facts false, probe still "ran".
	facts := probeHost(hostPaths{
		tunDevice: filepath.Join(dir, "tun"),
		wgModule:  filepath.Join(dir, "wireguard"),
	})
	if !facts.Probed || facts.TUNDevice || facts.KernelWireGuard {
		t.Fatalf("empty host probe = %+v", facts)
	}
	// A regular file at the TUN path is NOT a TUN device.
	if err := os.WriteFile(filepath.Join(dir, "tun"), []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Mkdir(filepath.Join(dir, "wireguard"), 0o755); err != nil {
		t.Fatal(err)
	}
	facts = probeHost(hostPaths{
		tunDevice: filepath.Join(dir, "tun"),
		wgModule:  filepath.Join(dir, "wireguard"),
	})
	if facts.TUNDevice {
		t.Fatal("a regular file must not count as a TUN device")
	}
	if !facts.KernelWireGuard {
		t.Fatal("the module directory must count as kernel WireGuard")
	}
	// The real /dev/net/tun is a char device where it exists; /dev/null
	// stands in for the shape check.
	facts = probeHost(hostPaths{tunDevice: "/dev/null", wgModule: filepath.Join(dir, "wireguard")})
	if !facts.TUNDevice {
		t.Fatal("a char device at the TUN path must count as a TUN device")
	}
}
