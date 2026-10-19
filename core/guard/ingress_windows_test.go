//go:build windows

package guard

import (
	"net/netip"
	"strings"
	"testing"

	"github.com/tailscale/wf"
)

// TestWFPIngressRules checks the receive-path rules without touching the
// host firewall: only the ALE_AUTH_RECV_ACCEPT layers, permits for
// loopback/tunnel/endpoints/LAN, and a final block that every permit
// outranks.
func TestWFPIngressRules(t *testing.T) {
	endpoints, err := parseIngressEndpoints([]string{"203.0.113.7:443", "[2001:db8::7]:443"})
	if err != nil {
		t.Fatalf("parseIngressEndpoints() error = %v", err)
	}
	b := &wfpIngressBackend{
		cfg:    DefaultIngressConfig(),
		bypass: []netip.Prefix{netip.MustParsePrefix("192.168.0.0/16")},
	}
	var rules []*wf.Rule
	if err := b.rules(func(rule *wf.Rule) error { rules = append(rules, rule); return nil }, wf.SublayerID{}, endpoints); err != nil {
		t.Fatal(err)
	}
	if len(rules) == 0 {
		t.Fatal("no ingress rules were generated")
	}
	var loopback, tunnel, v4endpoint, v6endpoint, lan, block int
	for _, rule := range rules {
		// Ingress rules must never land on the outbound layers.
		for _, layer := range outbound {
			if rule.Layer == layer {
				t.Fatalf("ingress rule %q targets outbound layer %v", rule.Name, layer)
			}
		}
		onRecv := rule.Layer == wf.LayerALEAuthRecvAcceptV4 || rule.Layer == wf.LayerALEAuthRecvAcceptV6
		if !onRecv {
			t.Fatalf("ingress rule %q targets unexpected layer %v", rule.Name, rule.Layer)
		}
		if !strings.HasPrefix(rule.Name, "Sora ingress: ") {
			t.Errorf("ingress rule %q misses its name prefix", rule.Name)
		}
		switch {
		case strings.Contains(rule.Name, "loopback"):
			loopback++
			if rule.Action != wf.ActionPermit || rule.Weight != weightPermit {
				t.Errorf("loopback rule has wrong action/weight: %+v", rule)
			}
		case strings.Contains(rule.Name, "through the tunnel"):
			tunnel++
			if rule.Action != wf.ActionPermit || rule.Weight != weightTunnelPermit {
				t.Errorf("tunnel rule has wrong action/weight: %+v", rule)
			}
		case strings.Contains(rule.Name, "VPN server endpoint"):
			if rule.Action != wf.ActionPermit {
				t.Errorf("endpoint rule must permit: %+v", rule)
			}
			for _, c := range rule.Conditions {
				if c.Field == wf.FieldIPRemoteAddress {
					if prefix, ok := c.Value.(netip.Prefix); ok {
						if prefix.Addr().String() == "203.0.113.7" {
							if rule.Layer != wf.LayerALEAuthRecvAcceptV4 {
								t.Error("IPv4 endpoint landed on the v6 layer")
							}
							v4endpoint++
						}
						if prefix.Addr().String() == "2001:db8::7" {
							if rule.Layer != wf.LayerALEAuthRecvAcceptV6 {
								t.Error("IPv6 endpoint landed on the v4 layer")
							}
							v6endpoint++
						}
					}
				}
			}
		case strings.Contains(rule.Name, "local network"):
			lan++
			if rule.Action != wf.ActionPermit {
				t.Errorf("LAN rule must permit: %+v", rule)
			}
		case strings.Contains(rule.Name, "everything else"):
			block++
			if rule.Action != wf.ActionBlock {
				t.Fatalf("the final rule must block: %+v", rule)
			}
			if rule.Weight != weightBlock {
				t.Errorf("the final block must have the lowest weight, got %d", rule.Weight)
			}
			if len(rule.Conditions) != 0 {
				t.Errorf("the final block must be unconditional, got %+v", rule.Conditions)
			}
		default:
			t.Errorf("unexpected ingress rule %q", rule.Name)
		}
		// Every permit must outrank the final block so the drop can never
		// shadow an exception.
		if rule.Action == wf.ActionPermit && rule.Weight <= weightBlock {
			t.Errorf("permit %q does not outrank the block", rule.Name)
		}
	}
	// Each rule is duplicated per matching layer: loopback and tunnel on
	// both, each endpoint on its family layer, LAN on v4 only here.
	if loopback != 2 || tunnel != 2 || v4endpoint != 1 || v6endpoint != 1 || lan != 1 || block != 2 {
		t.Errorf("loopback=%d tunnel=%d v4endpoint=%d v6endpoint=%d lan=%d block=%d",
			loopback, tunnel, v4endpoint, v6endpoint, lan, block)
	}
}

// TestWFPIngressRulesWithoutLANSkipsLocalPermits locks AllowLAN=false on
// the receive path: only loopback, tunnel, and endpoints stay permitted.
func TestWFPIngressRulesWithoutLANSkipsLocalPermits(t *testing.T) {
	cfg := DefaultIngressConfig()
	cfg.AllowLAN = false
	b := &wfpIngressBackend{cfg: cfg, bypass: []netip.Prefix{netip.MustParsePrefix("192.168.0.0/16")}}
	var rules []*wf.Rule
	if err := b.rules(func(rule *wf.Rule) error { rules = append(rules, rule); return nil }, wf.SublayerID{}, nil); err != nil {
		t.Fatal(err)
	}
	for _, rule := range rules {
		if strings.Contains(rule.Name, "local network") {
			t.Errorf("LAN permit leaked into a config with AllowLAN=false: %+v", rule)
		}
	}
}
