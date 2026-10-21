package profiles

import (
	"os"
	"path/filepath"
	"testing"
)

func goodProfile() Profile {
	return Profile{
		Name: "Home",
		Triggers: Triggers{
			SSIDs:    []string{"Home_Network"},
			Gateways: []string{"192.168.1.1"},
		},
		Apply: Apply{Mode: new("tun"), DNS: []string{"1.1.1.1"}, ServerID: new("srv-1"), Engine: new("sing-box")},
	}
}

func TestValidateAcceptsGoodProfile(t *testing.T) {
	if err := validate(goodProfile()); err != nil {
		t.Fatalf("good profile rejected: %v", err)
	}
}

func TestValidateRejectsBadProfiles(t *testing.T) {
	cases := []struct {
		name string
		mut  func(*Profile)
	}{
		{"empty name", func(p *Profile) { p.Name = "" }},
		{"name with newline", func(p *Profile) { p.Name = "a\nb" }},
		{"bad gateway", func(p *Profile) { p.Triggers.Gateways = []string{"not-an-ip"} }},
		{"bad mode", func(p *Profile) { p.Apply.Mode = new("turbo") }},
		{"bad engine", func(p *Profile) { p.Apply.Engine = new("wireguard-app") }},
		{"bad dns", func(p *Profile) { p.Apply.DNS = []string{"dns example"} }},
		{"bad id", func(p *Profile) { p.ID = "../evil" }},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			p := goodProfile()
			tc.mut(&p)
			if err := validate(p); err == nil {
				t.Fatal("invalid profile must be rejected")
			}
		})
	}
}

func TestMatchesSSIDAndGateway(t *testing.T) {
	p := goodProfile()
	if !p.matches(Fingerprint{SSID: "Home_Network", Gateway: "192.168.1.1"}) {
		t.Fatal("matching network must match")
	}
	if p.matches(Fingerprint{SSID: "Cafe", Gateway: "192.168.1.1"}) {
		t.Fatal("wrong SSID must not match")
	}
	if p.matches(Fingerprint{SSID: "Home_Network", Gateway: "10.0.0.1"}) {
		t.Fatal("wrong gateway must not match")
	}
}

func TestTriggerlessProfileNeverMatches(t *testing.T) {
	p := goodProfile()
	p.Triggers = Triggers{}
	if p.matches(Fingerprint{SSID: "x", Gateway: "1.2.3.4"}) {
		t.Fatal("a profile without triggers must never match")
	}
}

func TestStoreRoundTrip(t *testing.T) {
	dir := t.TempDir()
	s, err := NewStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	saved, err := s.Save(goodProfile())
	if err != nil {
		t.Fatal(err)
	}
	if saved.ID == "" {
		t.Fatal("saved profile must get an id")
	}
	list := s.List()
	if len(list) != 1 || list[0].ID != saved.ID {
		t.Fatalf("list shows %v", list)
	}
	// Reload from disk.
	s2, err := NewStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(s2.List()) != 1 {
		t.Fatal("profile must survive a reload")
	}
	// Update in place.
	saved.Name = "Home Renamed"
	if _, err := s2.Save(saved); err != nil {
		t.Fatal(err)
	}
	if got := s2.List()[0].Name; got != "Home Renamed" {
		t.Fatalf("rename did not persist, got %q", got)
	}
	if err := s2.Delete(saved.ID); err != nil {
		t.Fatal(err)
	}
	if len(s2.List()) != 0 {
		t.Fatal("delete must remove the profile")
	}
	if err := s2.Delete("missing-id"); err != nil {
		t.Fatal("deleting an unknown id must not fail")
	}
}

func TestStoreRejectsCorruptFile(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, fileName), []byte("{nope"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := NewStore(dir); err == nil {
		t.Fatal("a corrupt profiles file must fail fast")
	}
}

func TestStoreMatchesFirstProfile(t *testing.T) {
	dir := t.TempDir()
	s, err := NewStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	home := goodProfile()
	office := goodProfile()
	office.Name = "Office"
	office.Triggers = Triggers{SSIDs: []string{"Office_WiFi"}}
	if _, err := s.Save(home); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Save(office); err != nil {
		t.Fatal(err)
	}
	m := s.Match(Fingerprint{SSID: "Office_WiFi"})
	if m == nil || m.Name != "Office" {
		t.Fatalf("wrong match: %+v", m)
	}
	if m := s.Match(Fingerprint{SSID: "Unknown"}); m != nil {
		t.Fatalf("no profile should match, got %+v", m)
	}
}

func TestASNTableLookup(t *testing.T) {
	dir := t.TempDir()
	table := `{"203.0.113.0/24": "64500", "198.51.100.0/24": "64501"}`
	if err := os.WriteFile(filepath.Join(dir, asnTableName), []byte(table), 0o600); err != nil {
		t.Fatal(err)
	}
	s, err := NewStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	if got := s.asnFor("203.0.113.7"); got != "64500" {
		t.Fatalf("got ASN %q, want 64500", got)
	}
	if got := s.asnFor("192.0.2.1"); got != "" {
		t.Fatalf("unknown range must give empty ASN, got %q", got)
	}
	p := goodProfile()
	p.Triggers = Triggers{ASNs: []string{"64500"}}
	saved, err := s.Save(p)
	if err != nil {
		t.Fatal(err)
	}
	_ = saved
	fp := s.Fingerprint()
	_ = fp
	m := s.Match(Fingerprint{Gateway: "203.0.113.1", ASN: s.asnFor("203.0.113.1")})
	if m == nil {
		t.Fatal("ASN trigger must match through the local table")
	}
}
