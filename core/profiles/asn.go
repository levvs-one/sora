package profiles

import (
	"encoding/json"
	"net/netip"
	"os"
	"path/filepath"
)

// loadASNTable reads the optional CIDR-to-ASN mapping from the data
// directory. The table lets ASN triggers work without any network requests;
// when it is absent or unreadable, ASN matching simply never fires. A
// corrupt table is ignored rather than breaking startup: the ASN is a
// heuristic, documented as such. It runs on the first ASN lookup, not at
// store construction (see Store.asnDir): the result is not needed before
// the first network fingerprint, and the load never fails - absent or
// corrupt yields an empty table either way, so deferring it changes no
// observable behaviour, only when the parsing cost is paid.
func loadASNTable(dir string) (nets []netip.Prefix, asns []string) {
	if dir == "" {
		return nil, nil
	}
	raw, err := os.ReadFile(filepath.Join(dir, asnTableName)) //nolint:gosec // Fixed filename under the configured core data directory.
	if err != nil || len(raw) > maxFileBytes {
		return nil, nil
	}
	var table map[string]string
	if err := json.Unmarshal(raw, &table); err != nil {
		return nil, nil
	}
	// Pre-size from the decoded entry count: growing both slices by
	// append doubling copies ~2x their final size again on large tables.
	nets = make([]netip.Prefix, 0, len(table))
	asns = make([]string, 0, len(table))
	for cidr, asn := range table {
		p, err := netip.ParsePrefix(cidr)
		if err != nil || asn == "" {
			continue
		}
		nets = append(nets, p)
		asns = append(asns, asn)
	}
	return nets, asns
}

// asnFor resolves the ASN of an address through the store's local table.
func (s *Store) asnFor(addr string) string {
	ip, err := netip.ParseAddr(addr)
	if err != nil {
		return ""
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if !s.asnLoaded {
		s.asnNets, s.asnValues = loadASNTable(s.asnDir)
		s.asnLoaded = true
	}
	for i, p := range s.asnNets {
		if p.Contains(ip) {
			return s.asnValues[i]
		}
	}
	return ""
}
