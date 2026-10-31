//go:build linux && !android

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
	"sync"
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
// wired, disconnected, or unreadable - never an error.
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

// parseIWBSSID extracts the associated access point's BSSID from
// `iw dev <iface> link` output, e.g. "Connected to 12:34:56:78:9a:bc (on
// wlan0)". Empty when not associated.
func parseIWBSSID(out []byte) string {
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if !strings.HasPrefix(line, "Connected to ") {
			continue
		}
		fields := strings.Fields(line)
		if len(fields) >= 3 {
			return fields[2]
		}
	}
	return ""
}

// wifiSecCache memoizes the last scan result: a scan takes seconds and
// needs privileges, and the authentication family does not change while
// the SSID/BSSID stay the same.
var wifiSecCache = struct {
	sync.Mutex
	ssid  string
	bssid string
	sec   Security
}{}

// currentSecurity reports the Wi-Fi authentication family of the default
// interface's association, best-effort. An empty interface means offline,
// an empty SSID means wired; anything unreadable is SecurityUnknown.
func currentSecurity(iface, ssid string) Security {
	if iface == "" {
		return SecurityUnknown
	}
	if ssid == "" {
		return SecurityWired
	}
	return wifiSecurityLinux(iface, ssid)
}

// wifiSecurityLinux finds the associated BSS in `iw` scan output and reads
// its authentication suites: RSN/WPA information elements mean WPA-family
// auth, a set privacy bit without them means WEP, neither means open.
// Every failure - no iw, no privileges, BSS absent - is SecurityUnknown,
// never a guess.
func wifiSecurityLinux(iface, ssid string) Security {
	iw, err := resolveSystemBin("iw")
	if err != nil {
		return SecurityUnknown
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	//nolint:gosec // the binary comes from the trusted system directories and the interface name from the kernel table
	link, err := exec.CommandContext(ctx, iw, "dev", iface, "link").Output()
	if err != nil {
		return SecurityUnknown
	}
	bssid := parseIWBSSID(link)
	if bssid == "" {
		return SecurityUnknown
	}
	wifiSecCache.Lock()
	if wifiSecCache.ssid == ssid && wifiSecCache.bssid == bssid {
		sec := wifiSecCache.sec
		wifiSecCache.Unlock()
		return sec
	}
	wifiSecCache.Unlock()

	scanCtx, scanCancel := context.WithTimeout(context.Background(), 6*time.Second)
	defer scanCancel()
	//nolint:gosec // the binary comes from the trusted system directories and the interface name from the kernel table
	out, err := exec.CommandContext(scanCtx, iw, "dev", iface, "scan").Output()
	sec := SecurityUnknown
	if err == nil {
		sec = securityFromIWScan(bssid, out)
	}
	wifiSecCache.Lock()
	wifiSecCache.ssid, wifiSecCache.bssid, wifiSecCache.sec = ssid, bssid, sec
	wifiSecCache.Unlock()
	return sec
}

// securityFromIWScan reads the authentication family of one BSS from
// `iw dev <iface> scan` output. The decision is made per BSS block: auth
// suites present mean WPA-family, a set privacy capability without RSN/WPA
// elements means WEP, neither means open. A BSS that is absent from the
// scan is SecurityUnknown.
func securityFromIWScan(bssid string, out []byte) Security {
	want := strings.ToLower(strings.TrimSpace(bssid))
	var inBlock, auth, privacy bool
	decide := func() (Security, bool) {
		if !inBlock {
			return SecurityUnknown, false
		}
		switch {
		case auth:
			return SecurityWPA, true
		case privacy:
			return SecurityWEP, true
		default:
			return SecurityOpen, true
		}
	}
	for _, line := range strings.Split(string(out), "\n") {
		if strings.HasPrefix(line, "BSS ") {
			if sec, done := decide(); done {
				return sec
			}
			inBlock = strings.Contains(strings.ToLower(line), want)
			auth, privacy = false, false
			continue
		}
		if !inBlock {
			continue
		}
		t := strings.TrimSpace(line)
		switch {
		case strings.HasPrefix(t, "RSN:"),
			strings.HasPrefix(t, "WPA:"),
			strings.HasPrefix(t, "Authentication suites:"):
			auth = true
		case strings.HasPrefix(t, "capability:") && strings.Contains(t, "Privacy"):
			privacy = true
		}
	}
	if sec, done := decide(); done {
		return sec
	}
	return SecurityUnknown
}
