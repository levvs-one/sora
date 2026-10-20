package engine

import "testing"

// TestAmneziaWG31NeedsACapableEngine pins the AWG 3.x routing matrix
// after PASS2 deep S1 / PASS3: the old claim "mihomo must miss
// amneziawg3" contradicted sora's own pin — mihomo implements AWG
// 3.0/3.1 since 1.19.30 (pin: 1.19.32) — so the gate is VERSIONED
// for mihomo, build-tagged for sing-box-lx, and closed for everyone
// else, including version-unknown lookups.
func TestAmneziaWG31NeedsACapableEngine(t *testing.T) {
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

	// The bare catalog entry has no version to judge by: fail closed.
	if missing := Catalog[KindMihomo].Missing(plan); len(missing) == 0 {
		t.Fatal("mihomo with an unknown version must miss amneziawg3 for a 3.1 plan")
	}
	// Below the floor the 3.x stack does not exist yet.
	old := BuildCapabilities(KindMihomo, mustVersion(t, "1.19.29"), nil)
	if missing := old.Missing(plan); len(missing) == 0 {
		t.Fatal("mihomo 1.19.29 must miss amneziawg3 for a 3.1 plan")
	}
	// The floor itself and the shipped pin carry it.
	for _, v := range []string{"1.19.30", "1.19.32"} {
		caps := BuildCapabilities(KindMihomo, mustVersion(t, v), nil)
		if missing := caps.Missing(plan); len(missing) != 0 {
			t.Fatalf("mihomo %s must carry a 3.1 plan, missing %v", v, missing)
		}
	}
	// Building mihomo capabilities must not leak the feature into the
	// shared catalog entry (the next version-less lookup depends on it).
	if Catalog[KindMihomo].Supports(FeatureAmneziaWG3) {
		t.Fatal("BuildCapabilities must clone, not mutate, the catalog features")
	}

	lx := BuildCapabilities(KindSingBox, mustVersion(t, "1.14.3-lx.14"), []string{"with_awg"})
	if missing := lx.Missing(plan); len(missing) != 0 {
		t.Fatalf("sing-box-lx with_awg must carry a 3.1 plan, missing %v", missing)
	}
	upstream := BuildCapabilities(KindSingBox, mustVersion(t, "1.14.3"), nil)
	if missing := upstream.Missing(plan); len(missing) == 0 {
		t.Fatal("upstream sing-box must miss amneziawg3 for a 3.1 plan")
	}

	// Selection: the pinned mihomo is now a valid failover route for
	// 3.1 plans, ahead of sing-box-lx when it is preferred first.
	available := []Availability{
		{Kind: KindMihomo, Usable: true, Version: mustVersion(t, "1.19.32")},
		{Kind: KindSingBox, Usable: true, Version: mustVersion(t, "1.14.3-lx.14"), BuildTags: []string{"with_awg"}},
	}
	sel, err := SelectEngine(plan, available, []Kind{KindMihomo, KindSingBox})
	if err != nil {
		t.Fatalf("selection failed: %v", err)
	}
	if sel.Kind != KindMihomo {
		t.Fatalf("a 3.1 plan must select the pinned mihomo when preferred, got %s (%s)", sel.Kind, sel.Reason)
	}
	// An old mihomo is skipped for the same plan and lx takes over.
	available[0].Version = mustVersion(t, "1.19.29")
	sel, err = SelectEngine(plan, available, []Kind{KindMihomo, KindSingBox})
	if err != nil {
		t.Fatalf("selection failed: %v", err)
	}
	if sel.Kind != KindSingBox {
		t.Fatalf("a 3.1 plan with mihomo 1.19.29 must fall back to sing-box-lx, got %s (%s)", sel.Kind, sel.Reason)
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
	// The AWG3 version gate must not leak into masquerade: even the
	// pinned mihomo has no id/ip/ib fields (PASS2 deep S1 boundary).
	pinned := BuildCapabilities(KindMihomo, mustVersion(t, "1.19.32"), nil)
	if missing := pinned.Missing(plan); len(missing) == 0 {
		t.Fatal("even mihomo 1.19.32 must miss amneziawg-masquerade")
	}
	lx := BuildCapabilities(KindSingBox, mustVersion(t, "1.14.3-lx.14"), []string{"with_awg"})
	if missing := lx.Missing(plan); len(missing) != 0 {
		t.Fatalf("sing-box-lx with_awg must carry a masquerade plan, missing %v", missing)
	}
}
