package ext

import (
	"strings"
	"testing"
	"time"
)

// testRevocationJSON builds a minimal revocations.json for tests.
func testRevocationJSON(entries string) string {
	return `{"revocation_version":1,` +
		`"updated_at":"2026-10-20T00:00:00Z",` +
		`"expires_at":"2026-10-27T00:00:00Z",` +
		`"entries":[` + entries + `]}`
}

func TestParseRevocationListValid(t *testing.T) {
	l, err := ParseRevocationList([]byte(testRevocationJSON(
		`{"id":"com.evil.miner","versions":"*","reason":"cryptominer"},` +
			`{"id":"com.buggy.sync","versions":"<=1.2.0","reason":"deletes user data"}`)))
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if !l.IsRevoked("com.evil.miner", "9.9.9") {
		t.Error("* should revoke every version")
	}
	if !l.IsRevoked("com.buggy.sync", "1.2.0") || !l.IsRevoked("com.buggy.sync", "1.0.0") {
		t.Error("<=1.2.0 should revoke 1.2.0 and below")
	}
	if l.IsRevoked("com.buggy.sync", "1.2.1") {
		t.Error("<=1.2.0 must not revoke 1.2.1")
	}
	if l.IsRevoked("com.clean.app", "1.0.0") {
		t.Error("unlisted id must not be revoked")
	}
	if l.Expired(time.Now()) {
		t.Error("fresh list must not be expired")
	}
}

func TestVersionMatches(t *testing.T) {
	cases := []struct {
		constraint, version string
		want                bool
	}{
		{"*", "1.0.0", true},
		{"*", "99.0.0-alpha", true},
		{"=1.2.3", "1.2.3", true},
		{"=1.2.3", "1.2.4", false},
		{"<1.2.3", "1.2.2", true},
		{"<1.2.3", "1.2.3", false},
		{"<=1.2.3", "1.2.3", true},
		{"<=1.2.3", "1.2.4", false},
		{">=1.2.3", "1.2.3", false}, // unsupported operator
		{"1.2.3", "1.2.3", false},   // missing operator
		{"", "1.2.3", false},
	}
	for _, c := range cases {
		if got := versionMatches(c.constraint, c.version); got != c.want {
			t.Errorf("versionMatches(%q, %q) = %v, want %v", c.constraint, c.version, got, c.want)
		}
	}
}

func TestParseRevocationListRejects(t *testing.T) {
	cases := []struct {
		name    string
		entries string
		raw     string // when useRaw, used verbatim instead of entries
		useRaw  bool
	}{
		{"bad version", `{"id":"com.a.b","versions":"v1","reason":"x"}`, "", false},
		{"range op", `{"id":"com.a.b","versions":">=1.0.0","reason":"x"}`, "", false},
		{"bad id", `{"id":"not an id!","versions":"*","reason":"x"}`, "", false},
		{"bad semver", `{"id":"com.a.b","versions":"<=1.0","reason":"x"}`, "", false},
		{"duplicate", `{"id":"com.a.b","versions":"*","reason":"x"},{"id":"com.a.b","versions":"*","reason":"y"}`, "", false},
		{"long reason", `{"id":"com.a.b","versions":"*","reason":"` + strings.Repeat("x", 281) + `"}`, "", false},
		{"unknown field", `{"id":"com.a.b","versions":"*","reason":"x","extra":1}`, "", false},
		{"expires before updated", "", `{"revocation_version":1,"updated_at":"2026-10-27T00:00:00Z","expires_at":"2026-10-20T00:00:00Z","entries":[]}`, true},
		{"bad list version", "", `{"revocation_version":2,"updated_at":"2026-10-20T00:00:00Z","expires_at":"2026-10-27T00:00:00Z","entries":[]}`, true},
		{"empty", "", ``, true},
		{"not json", "", `definitely not json`, true},
	}
	for _, c := range cases {
		raw := c.raw
		if !c.useRaw {
			raw = testRevocationJSON(c.entries)
		}
		if _, err := ParseRevocationList([]byte(raw)); err == nil {
			t.Errorf("%s: expected rejection", c.name)
		}
	}
}

// TestVerifyRevocationListFailsClosed documents the key-ceremony gate: until
// the team key is real, no revocation list can be trusted, and verification
// must refuse instead of falling back to the unsigned payload.
func TestVerifyRevocationListFailsClosed(t *testing.T) {
	if SigningConfigured() {
		t.Skip("team key is configured; this test covers the pre-ceremony gate")
	}
	payload := []byte(testRevocationJSON(`{"id":"com.evil.miner","versions":"*","reason":"x"}`))
	sig, err := SignPayload(testPrivateKey(testSeed), "test key", sigFileRevocations, time.Now().Unix(), payload)
	if err != nil {
		t.Fatalf("sign: %v", err)
	}
	if _, err := VerifyRevocationList(sig, payload); err == nil {
		t.Fatal("expected fail-closed before the key ceremony")
	} else if !strings.Contains(err.Error(), "key ceremony") {
		t.Fatalf("expected a key-ceremony error, got: %v", err)
	}
}

func TestRevocationBlocksInstallAndEnable(t *testing.T) {
	dir := t.TempDir()
	s, err := OpenStore(dir)
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	l, err := ParseRevocationList([]byte(testRevocationJSON(
		`{"id":"com.example.hello","versions":"<=1.0.0","reason":"test"}`)))
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	s.SetRevocations(l)

	pkg, err := OpenBytes(buildPackage(t, testManifest(t), nil, nil))
	if err != nil {
		t.Fatalf("open package: %v", err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications", "ui.panel"}, ""); err == nil {
		t.Fatal("install of a revoked version must fail")
	}

	// A version outside the revoked range installs fine.
	m := testManifest(t)
	m.Version = "1.0.1"
	pkg2, err := OpenBytes(buildPackage(t, m, nil, nil))
	if err != nil {
		t.Fatalf("open package: %v", err)
	}
	if _, err := s.Install(pkg2, SourceSideload, []string{"connections.read", "notifications", "ui.panel"}, ""); err != nil {
		t.Fatalf("install of a non-revoked version: %v", err)
	}

	// Enabling a revoked id@version is refused.
	s.SetRevocations(mustParseRevocation(t, `{"id":"com.example.hello","versions":"*","reason":"kill"}`))
	if err := s.SetEnabled("com.example.hello", true); err == nil {
		t.Fatal("enabling a revoked extension must fail")
	}
	// ...but disabling still works (the kill path).
	if err := s.SetEnabled("com.example.hello", false); err != nil {
		t.Fatalf("disabling a revoked extension must work: %v", err)
	}
}

func TestExpiredRevocationListBlocksInstall(t *testing.T) {
	dir := t.TempDir()
	s, err := OpenStore(dir)
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	l := mustParseRevocation(t, `{"id":"com.example.hello","versions":"*","reason":"x"}`)
	l.ExpiresAt = time.Now().Add(-time.Hour) // stale cache, offline
	s.SetRevocations(l)

	m := testManifest(t)
	m.Version = "2.0.0"
	pkg, err := OpenBytes(buildPackage(t, m, nil, nil))
	if err != nil {
		t.Fatalf("open package: %v", err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications", "ui.panel"}, ""); err == nil {
		t.Fatal("an expired revocation list must fail installs closed")
	}
}

func TestNoRevocationListAllowsInstall(t *testing.T) {
	dir := t.TempDir()
	s, err := OpenStore(dir)
	if err != nil {
		t.Fatalf("open store: %v", err)
	}
	pkg, err := OpenBytes(buildPackage(t, testManifest(t), nil, nil))
	if err != nil {
		t.Fatalf("open package: %v", err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"connections.read", "notifications", "ui.panel"}, ""); err != nil {
		t.Fatalf("no list cached: install must proceed (catalog is the gate): %v", err)
	}
}

func mustParseRevocation(t *testing.T, entries string) *RevocationList {
	t.Helper()
	l, err := ParseRevocationList([]byte(testRevocationJSON(entries)))
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	return l
}
