package profiles

import (
	"net"
	"net/netip"
	"slices"
	"strings"
)

// Current returns the machine's current network fingerprint. It never fails:
// the parts it cannot read stay empty, and an empty gateway means offline.
func Current() Fingerprint {
	iface, gateway := defaultRoute()
	ssid := currentSSID(iface)
	return Fingerprint{
		SSID:        ssid,
		Gateway:     gateway,
		Security:    currentSecurity(iface, ssid),
		Fingerprint: interfaceFingerprint(),
	}
}

// Fingerprint returns the current fingerprint with the ASN resolved from the
// store's optional local table.
func (s *Store) Fingerprint() Fingerprint {
	fp := Current()
	fp.ASN = s.asnFor(fp.Gateway)
	return fp
}

// interfaceFingerprint lists up non-loopback interfaces other than Sora's
// adapter with their addresses, like the session's network watch, so the
// string is stable while the network stays the same.
func interfaceFingerprint() string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return ""
	}
	var parts []string
	for _, iface := range interfaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 || iface.Name == "sora0" {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, a := range addrs {
			network, ok := a.(*net.IPNet)
			if !ok {
				continue
			}
			addr, ok := netip.AddrFromSlice(network.IP)
			if !ok {
				continue
			}
			addr = addr.Unmap()
			switch {
			case addr.Is4():
				parts = append(parts, iface.Name+" "+addr.String())
			case addr.IsGlobalUnicast():
				prefix, _ := addr.Prefix(64)
				parts = append(parts, iface.Name+" "+prefix.String())
			}
		}
	}
	slices.Sort(parts)
	return strings.Join(slices.Compact(parts), ",")
}
