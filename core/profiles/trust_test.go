package profiles

import (
	"os"
	"path/filepath"
	"testing"
)

func TestTrustEffectiveDefaultsUntrusted(t *testing.T) {
	ts, err := NewTrustStore("")
	if err != nil {
		t.Fatal(err)
	}
	// A network the user never marked is untrusted - never trusted.
	if got := ts.Effective("Cafe_WiFi"); got != TrustUntrusted {
		t.Fatalf("new network must default to untrusted, got %v", got)
	}
	if got, ok := ts.Lookup("Cafe_WiFi"); ok || got != TrustNone {
		t.Fatalf("unmarked network must report (none, false), got (%v, %v)", got, ok)
	}
	// Empty SSID (wired/offline) carries no per-SSID opinion.
	if got := ts.Effective(""); got != TrustNone {
		t.Fatalf("empty SSID must report none, got %v", got)
	}
}

func TestTrustSetLookupAndRemove(t *testing.T) {
	ts, err := NewTrustStore("")
	if err != nil {
		t.Fatal(err)
	}
	if err := ts.Set("Home_Network", TrustTrusted); err != nil {
		t.Fatal(err)
	}
	if err := ts.Set("Evil_Twin", TrustUntrusted); err != nil {
		t.Fatal(err)
	}
	if got := ts.Effective("Home_Network"); got != TrustTrusted {
		t.Fatalf("trusted mark lost, got %v", got)
	}
	if got := ts.Effective("Evil_Twin"); got != TrustUntrusted {
		t.Fatalf("untrusted mark lost, got %v", got)
	}
	// TrustNone removes the mark: the network is new again, hence untrusted.
	if err := ts.Set("Evil_Twin", TrustNone); err != nil {
		t.Fatal(err)
	}
	if _, ok := ts.Lookup("Evil_Twin"); ok {
		t.Fatal("removed mark must not be found")
	}
	if got := ts.Effective("Evil_Twin"); got != TrustUntrusted {
		t.Fatalf("removed mark must fall back to untrusted, got %v", got)
	}
}

func TestTrustSetRejectsBadInput(t *testing.T) {
	ts, err := NewTrustStore("")
	if err != nil {
		t.Fatal(err)
	}
	for _, ssid := range []string{"", "a\nb", "a\tb", string(make([]byte, MaxTriggerLen+1))} {
		if err := ts.Set(ssid, TrustTrusted); err == nil {
			t.Fatalf("bad SSID %q must be rejected", ssid)
		}
	}
	if err := ts.Set("Home_Network", Trust(42)); err == nil {
		t.Fatal("unknown trust mark must be rejected")
	}
	// The rejected sets must not have stored anything.
	if _, ok := ts.Lookup("Home_Network"); ok {
		t.Fatal("rejected set must not store a mark")
	}
}

func TestTrustRoundTrip(t *testing.T) {
	dir := t.TempDir()
	ts, err := NewTrustStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	if err := ts.Set("Home_Network", TrustTrusted); err != nil {
		t.Fatal(err)
	}
	if err := ts.Set("Cafe_WiFi", TrustUntrusted); err != nil {
		t.Fatal(err)
	}
	raw, err := os.ReadFile(filepath.Join(dir, trustFileName))
	if err != nil {
		t.Fatalf("trust file must be written: %v", err)
	}
	if len(raw) == 0 {
		t.Fatal("trust file is empty")
	}
	// Reload from disk.
	ts2, err := NewTrustStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	if got := ts2.Effective("Home_Network"); got != TrustTrusted {
		t.Fatalf("trusted mark did not survive reload, got %v", got)
	}
	if got := ts2.Effective("Cafe_WiFi"); got != TrustUntrusted {
		t.Fatalf("untrusted mark did not survive reload, got %v", got)
	}
	if got := ts2.Effective("Unknown_Net"); got != TrustUntrusted {
		t.Fatalf("unknown network must still default to untrusted after reload, got %v", got)
	}
	// The file must be owner-only.
	if fi, err := os.Stat(filepath.Join(dir, trustFileName)); err != nil || fi.Mode().Perm() != 0o600 {
		t.Fatalf("trust file must be 0600, stat=%v mode=%v", err, fi.Mode())
	}
}

func TestTrustStoreRejectsCorruptFile(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, trustFileName), []byte("{nope"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := NewTrustStore(dir); err == nil {
		t.Fatal("a corrupt trust file must fail fast")
	}
}

func TestTrustStoreRejectsBadMarks(t *testing.T) {
	for _, body := range []string{
		`{"version":1,"marks":{"Home":"bogus"}}`,
		`{"version":1,"marks":{"":"trusted"}}`,
		`{"version":2,"marks":{"Home":"trusted"}}`,
	} {
		dir := t.TempDir()
		if err := os.WriteFile(filepath.Join(dir, trustFileName), []byte(body), 0o600); err != nil {
			t.Fatal(err)
		}
		if _, err := NewTrustStore(dir); err == nil {
			t.Fatalf("bad trust file %s must fail fast", body)
		}
	}
}

func TestStoreTrustIntegration(t *testing.T) {
	dir := t.TempDir()
	s, err := NewStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.SetTrust("Home_Network", TrustTrusted); err != nil {
		t.Fatal(err)
	}
	if got := s.NetworkTrust(Fingerprint{SSID: "Home_Network"}); got != TrustTrusted {
		t.Fatalf("got %v, want trusted", got)
	}
	if got := s.NetworkTrust(Fingerprint{SSID: "Cafe_WiFi"}); got != TrustUntrusted {
		t.Fatalf("new network must be untrusted, got %v", got)
	}
	if got := s.NetworkTrust(Fingerprint{}); got != TrustNone {
		t.Fatalf("wired fingerprint must be none, got %v", got)
	}
	// Marks live in the same data dir and survive a store reload.
	s2, err := NewStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	if got := s2.NetworkTrust(Fingerprint{SSID: "Home_Network"}); got != TrustTrusted {
		t.Fatalf("trust mark did not survive store reload, got %v", got)
	}
}

func TestTrustStringRoundTrip(t *testing.T) {
	for _, tc := range []struct {
		in   string
		want Trust
	}{
		{"trusted", TrustTrusted},
		{"untrusted", TrustUntrusted},
		{"none", TrustNone},
		{"", TrustNone},
		{" Trusted ", TrustTrusted},
	} {
		got, err := parseTrust(tc.in)
		if err != nil || got != tc.want {
			t.Fatalf("parseTrust(%q) = %v, %v; want %v", tc.in, got, err, tc.want)
		}
		if got.String() != tc.want.String() {
			t.Fatalf("String() mismatch for %v", got)
		}
	}
	if _, err := parseTrust("maybe"); err == nil {
		t.Fatal("unknown mark must be rejected")
	}
}
