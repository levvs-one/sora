// Joins sing-box's Clash API when packaging/android/natives.sh builds it. A port
// on a phone's loopback is open to every other app, which could then tell a VPN
// client runs here, so the core talks to the engine over a socket in the app's
// private directory.
package clashapi

import "strings"

func controlNetwork(address string) string {
	if strings.HasPrefix(address, "/") {
		return "unix"
	}
	return "tcp"
}
