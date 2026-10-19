//go:build windows

package guard

import (
	"net/netip"
	"strings"
	"testing"

	"github.com/tailscale/wf"
)

// TestWFPWeightHierarchy locks the kill-switch rule precedence so a future
// weight edit cannot silently invert it: the final block-all must stay the
// unique minimum (otherwise a permit could be shadowed), every permit must
// outrank it, the tunnel-destination block must outrank the DNS block (a
// tunnel destination must never leak, not even via DNS), and the tunnel
// permit must stay the unique maximum. The ladder mirrors WireGuard's:
// service > DNS > loopback > TUN interface > DHCP > block-all.
func TestWFPWeightHierarchy(t *testing.T) {
	if !(weightBlock < weightPermit && weightPermit < weightTunnelBlock && weightTunnelBlock < weightTunnelPermit) {
		t.Fatalf("weight ladder inverted: block=%d permit=%d tunnelBlock=%d tunnelPermit=%d",
			weightBlock, weightPermit, weightTunnelBlock, weightTunnelPermit)
	}

	networks := []netip.Prefix{netip.MustParsePrefix("192.0.2.0/30"), netip.MustParsePrefix("2001:db8:5340::/126")}
	w := &WFP{enginesDir: t.TempDir(), tunNetworks: networks, bypass: []netip.Prefix{netip.MustParsePrefix("0.0.0.0/0")}}
	var rules []*wf.Rule
	if err := w.rules(func(rule *wf.Rule) error { rules = append(rules, rule); return nil }, wf.SublayerID{}); err != nil {
		t.Fatal(err)
	}

	var (
		finalBlocks, dnsBlocks, tunnelBlocks, tunnelPermits int
		maxWeight                                           uint64
	)
	for _, rule := range rules {
		if rule.Weight > maxWeight {
			maxWeight = rule.Weight
		}
		switch {
		case rule.Name == "Sora: everything else":
			finalBlocks++
			if rule.Action != wf.ActionBlock || rule.Weight != weightBlock {
				t.Fatalf("final rule must be the weight-%d block-all, got action=%v weight=%d", weightBlock, rule.Action, rule.Weight)
			}
		case strings.HasPrefix(rule.Name, "Sora: DNS outside the tunnel"):
			dnsBlocks++
			if rule.Action != wf.ActionBlock {
				t.Fatalf("DNS rule must block, got %v", rule.Action)
			}
		case strings.HasPrefix(rule.Name, "Sora: tunnel destination outside the tunnel"):
			tunnelBlocks++
			if rule.Action != wf.ActionBlock || rule.Weight != weightTunnelBlock {
				t.Fatalf("tunnel-destination block must be weight %d, got %d", weightTunnelBlock, rule.Weight)
			}
		case strings.Contains(rule.Name, "through the tunnel"):
			tunnelPermits++
			if rule.Action != wf.ActionPermit || rule.Weight != weightTunnelPermit {
				t.Fatalf("tunnel permit must be weight %d, got %d", weightTunnelPermit, rule.Weight)
			}
		}
		if rule.Action == wf.ActionPermit && rule.Weight <= weightBlock {
			t.Fatalf("permit %q does not outrank the final block-all (weight %d)", rule.Name, rule.Weight)
		}
	}
	// Two outbound layers (v4/v6): one final block-all and one DNS block
	// each, one tunnel-destination block per v4 layer, two tunnel permits
	// (outgoing + reauthorize) per tun network.
	if finalBlocks != len(outbound) {
		t.Fatalf("want %d final block-all rules, got %d", len(outbound), finalBlocks)
	}
	if dnsBlocks != len(outbound) {
		t.Fatalf("want %d DNS block rules, got %d", len(outbound), dnsBlocks)
	}
	if tunnelPermits != 2*len(networks) {
		t.Fatalf("want %d tunnel permits, got %d", 2*len(networks), tunnelPermits)
	}
	if maxWeight != weightTunnelPermit {
		t.Fatalf("tunnel permit must be the unique maximum weight, max=%d want=%d", maxWeight, weightTunnelPermit)
	}
}
