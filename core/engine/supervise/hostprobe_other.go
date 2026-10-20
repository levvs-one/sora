//go:build !linux

package supervise

// ProbeHost on platforms without /dev/net/tun + sysfs semantics
// (Windows uses wintun, macOS utun — different facts, probed by
// their own platform code when it lands) honestly reports "not
// probed": selection must not gate on facts nobody measured.
func ProbeHost() HostFacts {
	return HostFacts{Probed: false}
}
