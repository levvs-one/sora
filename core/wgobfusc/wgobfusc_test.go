package wgobfusc

import (
	"strings"
	"testing"
)

func TestCatalogIsComplete(t *testing.T) {
	c := Catalog()
	if len(c) < 8 {
		t.Fatalf("catalog should hold the full technique set, got %d", len(c))
	}
	seen := map[string]bool{}
	for _, tech := range c {
		if tech.ID == "" || tech.Name == "" || tech.Summary == "" {
			t.Errorf("technique has empty ID/name/summary: %+v", tech)
		}
		if seen[tech.ID] {
			t.Errorf("duplicate technique ID %q", tech.ID)
		}
		seen[tech.ID] = true
		if len(tech.Sources) == 0 {
			t.Errorf("technique %q has no public sources", tech.ID)
		}
		for _, s := range tech.Sources {
			if !strings.HasPrefix(s, "https://") {
				t.Errorf("technique %q source %q is not an https URL", tech.ID, s)
			}
		}
		// Every engine must have an explicit verdict; silence would be
		// read as "unknown" by consumers.
		for _, e := range Engines() {
			if _, ok := tech.Support[e]; !ok {
				t.Errorf("technique %q has no verdict for engine %q", tech.ID, e)
			}
		}
		if tech.Note == "" {
			t.Errorf("technique %q should explain its engine verdicts", tech.ID)
		}
	}
}

func TestByID(t *testing.T) {
	for _, c := range Catalog() {
		got := ByID(c.ID)
		if got == nil || got.Name != c.Name {
			t.Errorf("ByID(%q) did not round-trip", c.ID)
		}
	}
	if ByID("no-such-technique") != nil {
		t.Error("ByID of unknown ID should return nil")
	}
}

func TestClientSideOnlyNeedsNoServer(t *testing.T) {
	for _, tech := range ClientSideOnly() {
		if tech.NeedsServerSide {
			t.Errorf("ClientSideOnly returned server-side technique %q", tech.ID)
		}
	}
	// Multihop chains are the honest client-side win: both ends of the
	// trick are under sora's control.
	found := false
	for _, tech := range ClientSideOnly() {
		if tech.ID == "multihop-wg" {
			found = true
		}
	}
	if !found {
		t.Error("multihop-wg should be client-side only")
	}
}

func TestExpressibleOnSingBox(t *testing.T) {
	full := ExpressibleOn(EngineSingBox, Supported)
	ids := map[string]bool{}
	for _, tech := range full {
		ids[tech.ID] = true
	}
	for _, want := range []string{"wg-over-shadowsocks", "multihop-wg", "port-agility"} {
		if !ids[want] {
			t.Errorf("sing-box should fully express %q", want)
		}
	}
	// QUIC/MASQUE wrapping and DAITA-style shaping are out of reach of
	// every engine with config alone.
	for _, e := range Engines() {
		full := ExpressibleOn(e, Supported)
		for _, tech := range full {
			if tech.ID == "wg-in-quic-masque" || tech.ID == "traffic-shaping" {
				t.Errorf("engine %q must not claim to express %q", e, tech.ID)
			}
		}
	}
}

func TestEnginesListMatchesConstants(t *testing.T) {
	if len(Engines()) != 3 {
		t.Fatalf("expected 3 engines, got %d", len(Engines()))
	}
}
