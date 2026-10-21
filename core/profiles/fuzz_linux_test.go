//go:build linux

package profiles

import "testing"

// FuzzRouteParsers drives the /proc and iw output parsers: both consume
// text produced outside the process (kernel tables, tool output that
// varies by distro and driver).
func FuzzRouteParsers(f *testing.F) {
	f.Add([]byte("Iface\tDestination\tGateway\neth0\t00000000\t0101A8C0\n"))
	f.Add([]byte("Connected to 00:11:22:33:44:55 (on wlan0)\n\tSSID: home\n"))
	f.Fuzz(func(_ *testing.T, b []byte) {
		_, _ = parseProcNetRoute(b)
		_ = parseIWLink(b)
	})
}
