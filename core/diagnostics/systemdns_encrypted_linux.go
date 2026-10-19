//go:build linux

package diagnostics

import (
	"bufio"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// Paths are variables so tests can point them at fixtures.
var (
	resolvedConfPath      = "/etc/systemd/resolved.conf"
	resolvedConfDropinDir = "/etc/systemd/resolved.conf.d"
)

// SystemEncryptedDNS returns the OS-configured encrypted DNS endpoints.
// On Linux it reads systemd-resolved configuration: when DNSOverTLS is
// enabled, the configured DNS servers are used over TLS and bypass
// plain-DNS hijacking.
//
// It never fails: an empty non-nil slice means detection ran and found
// nothing configured; nil is reserved for platforms without detection
// (see systemdns_encrypted_other.go).
func SystemEncryptedDNS() []string {
	keys := map[string][]string{}
	applyFile(resolvedConfPath, keys)
	dropins, _ := filepath.Glob(filepath.Join(resolvedConfDropinDir, "*.conf"))
	sort.Strings(dropins)
	for _, d := range dropins {
		applyFile(d, keys)
	}
	dot := false
	for _, v := range keys["dnsovertls"] {
		switch strings.ToLower(v) {
		case "yes", "true", "opportunistic":
			dot = true
		}
	}
	if !dot {
		return []string{}
	}
	servers := keys["dns"]
	if len(servers) == 0 {
		// No explicit DNS= servers: resolved upgrades the link's DNS
		// servers opportunistically, so the encrypted endpoints are the
		// system resolvers themselves.
		servers = SystemResolvers()
	}
	return servers
}

// applyFile merges the [Resolve] section of one resolved.conf-style file
// into keys (lowercased). Later files override earlier ones per key,
// mirroring systemd's drop-in semantics.
func applyFile(path string, keys map[string][]string) {
	f, err := os.Open(path)
	if err != nil {
		return
	}
	defer f.Close()
	inResolve := false
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 4096), 4096)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" || line[0] == '#' || line[0] == ';' {
			continue
		}
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			inResolve = strings.EqualFold(strings.Trim(line, "[]"), "Resolve")
			continue
		}
		if !inResolve {
			continue
		}
		k, v, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		keys[strings.ToLower(strings.TrimSpace(k))] = strings.Fields(v)
	}
}
