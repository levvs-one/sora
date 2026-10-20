//go:build !windows

package diagnostics

import (
	"bufio"
	"os"
	"strings"
)

// resolvConfPath is the OS resolver configuration. It is a variable so
// tests can point it at a fixture.
var resolvConfPath = "/etc/resolv.conf"

// SystemResolvers returns the DNS resolvers the OS is configured to use.
// It never fails: undetectable resolvers yield an empty list, and callers
// report that honestly instead of guessing.
func SystemResolvers() []string {
	return systemResolversFromFile(resolvConfPath)
}

// systemResolversFromFile parses "nameserver" lines, skipping comments and
// blank lines. Order is preserved, duplicates are kept: the caller decides
// what they mean.
func systemResolversFromFile(path string) []string {
	f, err := os.Open(path) //nolint:gosec // path is the fixed OS resolver configuration or an injected test fixture.
	if err != nil {
		return nil
	}
	defer func() { _ = f.Close() }()
	var out []string
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 4096), 4096)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" || line[0] == '#' || line[0] == ';' {
			continue
		}
		fields := strings.Fields(line)
		if len(fields) >= 2 && strings.EqualFold(fields[0], "nameserver") {
			out = append(out, fields[1])
		}
	}
	return out
}
