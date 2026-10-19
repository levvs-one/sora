//go:build windows

package profiles

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// systemBinDir is the only trusted location for helper binaries on Windows.
var systemBinDir = filepath.Join(os.Getenv("SystemRoot"), "System32")

// defaultRoute returns the default interface name (empty, unused on Windows)
// and gateway from the routing table.
func defaultRoute() (iface, gateway string) {
	route := filepath.Join(systemBinDir, "route.exe")
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	//nolint:gosec // the binary comes from the trusted system directory
	out, err := exec.CommandContext(ctx, route, "print", "-4").Output()
	if err != nil {
		return "", ""
	}
	return "", parseRoutePrint(out)
}

// parseRoutePrint extracts the gateway of the 0.0.0.0 route.
func parseRoutePrint(out []byte) string {
	for _, line := range strings.Split(string(out), "\n") {
		fields := strings.Fields(line)
		if len(fields) >= 3 && fields[0] == "0.0.0.0" && fields[1] == "0.0.0.0" {
			return fields[2]
		}
	}
	return ""
}

// currentSSID asks netsh for the connected Wi-Fi SSID. Empty means wired,
// disconnected, or unreadable — never an error.
func currentSSID(iface string) string {
	netsh := filepath.Join(systemBinDir, "netsh.exe")
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	//nolint:gosec // the binary comes from the trusted system directory
	out, err := exec.CommandContext(ctx, netsh, "wlan", "show", "interfaces").Output()
	if err != nil {
		return ""
	}
	return parseNetshWLAN(out)
}

// parseNetshWLAN extracts the SSID from `netsh wlan show interfaces` output.
func parseNetshWLAN(out []byte) string {
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "SSID") {
			if i := strings.Index(line, ":"); i >= 0 {
				return strings.TrimSpace(line[i+1:])
			}
		}
	}
	return ""
}
