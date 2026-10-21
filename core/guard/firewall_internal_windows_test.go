//go:build windows

package guard

import (
	"net/netip"
	"testing"

	"github.com/tailscale/wf"
	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/session"
)

func TestWFPTunnelFiltersAllowInboundReauthorization(t *testing.T) {
	networks := []netip.Prefix{netip.MustParsePrefix("192.0.2.0/30"), netip.MustParsePrefix("2001:db8:5340::/126")}
	w := &WFP{enginesDir: t.TempDir(), tunNetworks: networks, bypass: []netip.Prefix{netip.MustParsePrefix("0.0.0.0/0")}}
	var rules []*wf.Rule
	if err := w.rules(func(rule *wf.Rule) error { rules = append(rules, rule); return nil }, wf.SublayerID{}); err != nil {
		t.Fatal(err)
	}
	for i, layer := range outbound {
		outgoing, incoming, legacyBlock := 0, 0, 0
		for _, rule := range rules {
			if rule.Layer != layer {
				continue
			}
			if rule.Name == "Sora: tunnel destination outside the tunnel" {
				for _, c := range rule.Conditions {
					if c.Value == netip.MustParsePrefix("172.19.0.0/16") {
						legacyBlock++
						if layer != wf.LayerALEAuthConnectV4 || rule.Action != wf.ActionBlock || rule.Weight <= weightPermit {
							t.Fatal("legacy IPv4 destination block has wrong family, action or precedence")
						}
					}
				}
			}
			if rule.Weight != weightTunnelPermit {
				continue
			}
			if rule.Action != wf.ActionPermit {
				t.Fatal("tunnel rule must permit")
			}
			var local, next, arrival, reauth bool
			for _, c := range rule.Conditions {
				switch c.Field {
				case wf.FieldIPLocalAddress:
					local = c.Op == wf.MatchTypeEqual && c.Value == networks[i]
				case wf.FieldNexthopInterfaceType:
					next = c.Op == wf.MatchTypeEqual && c.Value == uint32(53)
				case wf.FieldArrivalInterfaceType:
					arrival = c.Op == wf.MatchTypeEqual && c.Value == uint32(53)
				case wf.FieldFlags:
					reauth = c.Op == wf.MatchTypeFlagsAllSet && c.Value == wf.ConditionFlagIsReauthorize
				default:
					t.Fatalf("unexpected tunnel condition %v", c.Field)
				}
			}
			// On inbound reauthorization next-hop is FWP_EMPTY. The arrival
			// permit must stand alone and still require the selected local subnet.
			if local && next && !arrival && len(rule.Conditions) == 2 {
				outgoing++
			} else if local && arrival && reauth && !next && len(rule.Conditions) == 3 {
				incoming++
			} else {
				t.Fatalf("unsafe or unusable tunnel permit: %+v", rule.Conditions)
			}
		}
		if outgoing != 1 || incoming != 1 || (i == 0 && legacyBlock != 1) || (i == 1 && legacyBlock != 0) {
			t.Fatalf("%v: outgoing=%d incoming=%d legacy=%d", layer, outgoing, incoming, legacyBlock)
		}
	}
}

// TestWFPRefusesAnEmptyEnginesDir: an empty enginesDir must
// fail closed instead of globbing "*.exe" in the working directory.
func TestWFPRefusesAnEmptyEnginesDir(t *testing.T) {
	w := &WFP{enginesDir: ""}
	if _, err := w.executables(); err == nil {
		t.Fatal("an empty enginesDir must fail closed")
	}
	w = &WFP{enginesDir: "  "}
	if _, err := w.executables(); err == nil {
		t.Fatal("a blank enginesDir must fail closed")
	}
}

func TestWFPStrictRulesRequireExplicitExemptions(t *testing.T) {
	for _, reconnect := range []bool{false, true} {
		policy := session.Settings{StrictKillSwitch: true, Reconnect: reconnect, Endpoints: []netip.AddrPort{netip.MustParseAddrPort("203.0.113.2:443"), netip.MustParseAddrPort("[2001:db8::2]:8443")}}
		w := &WFP{enginesDir: t.TempDir(), bypass: []netip.Prefix{netip.MustParsePrefix("0.0.0.0/0")}, policy: policy}
		endpoints, blocks, apps := 0, 0, 0
		if err := w.rules(func(rule *wf.Rule) error {
			if rule.Persistent != reconnect {
				t.Fatal("reboot policy lost")
			}
			if rule.Name == "Sora: local network" {
				t.Fatal("LAN allowed without consent")
			}
			if rule.Name == "Sora: VPN endpoint" {
				endpoints++
				if len(rule.Conditions) != 2 || rule.Action != wf.ActionPermit {
					t.Fatal("endpoint is not restricted by address and port")
				}
				if !applies(rule.Layer, rule.Conditions) {
					t.Fatal("endpoint has wrong family")
				}
			}
			if rule.Name == "Sora: everything else" {
				blocks++
			}
			for _, condition := range rule.Conditions {
				if condition.Field == wf.FieldALEAppID {
					apps++
					dnsOnly := false
					for _, match := range rule.Conditions {
						if match.Field == wf.FieldIPRemotePort && match.Value == uint16(53) {
							dnsOnly = true
						}
					}
					if !dnsOnly {
						t.Fatal("strict mode allowed unrestricted application traffic")
					}
				}
			}
			return nil
		}, strictSublayer); err != nil {
			t.Fatal(err)
		}
		if endpoints != 2 || blocks != 2 || apps != 2 {
			t.Fatalf("endpoints=%d blocks=%d apps=%d", endpoints, blocks, apps)
		}
		w.policy.AllowLAN = true
		lan := 0
		if err := w.rules(func(rule *wf.Rule) error {
			if rule.Name == "Sora: local network" {
				lan++
			}
			return nil
		}, strictSublayer); err != nil {
			t.Fatal(err)
		}
		if lan != len(DefaultBypassNetworks()) {
			t.Fatal("explicit LAN permission lost")
		}
	}
}

// TestStrictFilterRecordRoundTrips pins the record Disarm relies on: the
// IDs written after installing strict filters are read back unchanged and
// clearing the record leaves nothing to delete.
func TestStrictFilterRecordRoundTrips(t *testing.T) {
	w := &WFP{stateDir: t.TempDir()}
	if ids, err := w.strictIDs(); err != nil || len(ids) != 0 {
		t.Fatalf("empty record = %v, %v", ids, err)
	}
	want := []wf.RuleID{
		wf.RuleID(windows.GUID{Data1: 1, Data2: 2, Data3: 3, Data4: [8]byte{4, 5, 6, 7, 8, 9, 10, 11}}),
		wf.RuleID(windows.GUID{Data1: 12}),
	}
	if err := w.saveStrictIDs(want); err != nil {
		t.Fatal(err)
	}
	got, err := w.strictIDs()
	if err != nil || len(got) != len(want) || got[0] != want[0] || got[1] != want[1] {
		t.Fatalf("record = %v, %v; want %v", got, err, want)
	}
	if err := w.saveStrictIDs(nil); err != nil {
		t.Fatal(err)
	}
	if ids, _ := w.strictIDs(); len(ids) != 0 {
		t.Fatalf("cleared record still lists %v", ids)
	}
}
