package engine

import "testing"

func TestAmneziaWG31NeedsACapableEngine(t *testing.T) {
	// A 3.1 plan must never land on mihomo: its AmneziaWG stack only
	// knows the 1.x/2.0 keys, so the 3.1 parameters would be silently
	// dropped while the UI promises obfuscation.
	a31 := goodAmnezia31()
	if !a31.UsesAWG31() {
		t.Fatal("goodAmnezia31 must need AWG 3.x")
	}
	plan := &Plan{Outbounds: []Outbound{{
		ID: "wg", Name: "WG", Protocol: ProtocolWireGuard,
		Server: "198.51.100.7", Port: 51820,
		Addresses: []string{"10.7.0.2/32"},
		Peers:     []WireGuardPeer{{Endpoint: "198.51.100.7:51820"}},
		Amnezia:   a31,
	}}}
	if !plan.RequiredFeatures()[FeatureAmneziaWG3] {
		t.Fatal("a 3.1 plan must require feature amneziawg3")
	}
	if missing := Catalog[KindMihomo].Missing(plan); len(missing) == 0 {
		t.Fatal("mihomo must miss amneziawg3 for a 3.1 plan")
	}
	lx := BuildCapabilities(KindSingBox, mustVersion(t, "1.14.3-lx.14"), []string{"with_awg"})
	if missing := lx.Missing(plan); len(missing) != 0 {
		t.Fatalf("sing-box-lx with_awg must carry a 3.1 plan, missing %v", missing)
	}
	upstream := BuildCapabilities(KindSingBox, mustVersion(t, "1.14.3"), nil)
	if missing := upstream.Missing(plan); len(missing) == 0 {
		t.Fatal("upstream sing-box must miss amneziawg3 for a 3.1 plan")
	}
	available := []Availability{
		{Kind: KindMihomo, Usable: true, Version: mustVersion(t, "1.19.32")},
		{Kind: KindSingBox, Usable: true, Version: mustVersion(t, "1.14.3-lx.14"), BuildTags: []string{"with_awg"}},
	}
	sel, err := SelectEngine(plan, available, []Kind{KindMihomo, KindSingBox})
	if err != nil {
		t.Fatalf("selection failed: %v", err)
	}
	if sel.Kind != KindSingBox {
		t.Fatalf("a 3.1 plan must select sing-box-lx, got %s (%s)", sel.Kind, sel.Reason)
	}
}

func TestAmneziaMasqueradeNeedsACapableEngine(t *testing.T) {
	a := &AmneziaWG{MasqueradeProtocol: "dns"}
	if !a.UsesMasquerade() {
		t.Fatal("masquerade protocol must be detected")
	}
	plan := &Plan{Outbounds: []Outbound{{
		ID: "wg", Name: "WG", Protocol: ProtocolWireGuard,
		Server: "198.51.100.7", Port: 51820,
		Addresses: []string{"10.7.0.2/32"},
		Peers:     []WireGuardPeer{{Endpoint: "198.51.100.7:51820"}},
		Amnezia:   a,
	}}}
	if !plan.RequiredFeatures()[FeatureAmneziaMasquerade] {
		t.Fatal("a masquerade plan must require feature amneziawg-masquerade")
	}
	if missing := Catalog[KindMihomo].Missing(plan); len(missing) == 0 {
		t.Fatal("mihomo must miss amneziawg-masquerade for a masquerade plan")
	}
	lx := BuildCapabilities(KindSingBox, mustVersion(t, "1.14.3-lx.14"), []string{"with_awg"})
	if missing := lx.Missing(plan); len(missing) != 0 {
		t.Fatalf("sing-box-lx with_awg must carry a masquerade plan, missing %v", missing)
	}
}
