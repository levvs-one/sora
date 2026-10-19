//go:build linux

package profiles

import (
	"bufio"
	"bytes"
	"context"
	"encoding/binary"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// systemBinDirs are the trusted locations for helper binaries. Fingerprint
// helpers must not resolve through PATH: a planted binary would run with the
// core's privileges.
var systemBinDirs = []string{"/usr/sbin", "/sbin", "/usr/bin", "/bin"}

// resolveSystemBin returns the absolute path of a helper binary from the
// trusted system directories, failing closed when it is absent.
func resolveSystemBin(name string) (string, error) {
	for _, dir := range systemBinDirs {
		p := filepath.Join(dir, name)
		if fi, err := os.Stat(p); err == nil && !fi.IsDir() && fi.Mode()&0o111 != 0 {
			return p, nil
		}
	}
	return "", os.ErrNotExist
}

// defaultRoute returns the default interface and gateway from the kernel
// routing table. Empty strings mean offline or unreadable.
func defaultRoute() (iface, gateway string) {
	raw, err := os.ReadFile("/proc/net/route")
	if err != nil {
		return "", ""
	}
	return parseProcNetRoute(raw)
}

// parseProcNetRoute reads the interface and gateway of the default route.
// The gateway is little-endian hex, e.g. "0101A8C0" for 192.168.1.1.
func parseProcNetRoute(raw []byte) (iface, gateway string) {
	scanner := bufio.NewScanner(bytes.NewReader(raw))
	scanner.Buffer(make([]byte, 4096), 4096)
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) < 8 || fields[1] != "00000000" {
			continue
		}
		gw := strings.TrimSpace(fields[2])
		v, err := strconv.ParseUint(gw, 16, 32)
		if err != nil {
			continue
		}
		var b [4]byte
		binary.LittleEndian.PutUint32(b[:], uint32(v))
		ip := net.IP(b[:])
		if ip.IsUnspecified() {
			continue
		}
		return fields[0], ip.String()
	}
	return "", ""
}

// currentSSID asks iw for the SSID of the default interface. Empty means
// wired, disconnected, or unreadable — never an error.
func currentSSID(iface string) string {
	if iface == "" {
		return ""
	}
	iw, err := resolveSystemBin("iw")
	if err != nil {
		return ""
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	//nolint:gosec // the binary comes from the trusted system directories and the interface name from the kernel table
	out, err := exec.CommandContext(ctx, iw, "dev", iface, "link").Output()
	if err != nil {
		return ""
	}
	return parseIWLink(out)
}

// parseIWLink extracts the SSID from `iw dev <iface> link` output.
func parseIWLink(out []byte) string {
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "SSID:") {
			return strings.TrimSpace(strings.TrimPrefix(line, "SSID:"))
		}
	}
	return ""
}
