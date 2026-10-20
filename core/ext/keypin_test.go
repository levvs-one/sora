package ext

import (
	"crypto/ed25519"
	"encoding/base64"
	"strings"
	"testing"
)

// testSeed2 is a second ed25519 identity: the "attacker's" key, distinct
// from testSeed.
var testSeed2 = []byte{
	0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
	0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
	0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
	0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
}

// pubKeyLineFor returns the minisign public key line for an arbitrary seed.
func pubKeyLineFor(t *testing.T, seed []byte) string {
	t.Helper()
	priv := ed25519.NewKeyFromSeed(seed)
	pub := priv.Public().(ed25519.PublicKey)
	raw := append([]byte{'E', 'd'}, make([]byte, 8)...)
	raw = append(raw, pub...)
	return base64.StdEncoding.EncodeToString(raw)
}

var testGranted = []string{"connections.read", "notifications"}

// openStoreForTest opens a fresh store in a temp dir.
func openStoreForTest(t *testing.T) *Store {
	t.Helper()
	s, err := OpenStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	return s
}

// manifestV2 clones the test manifest at version 2.0.0 with an explicit
// author key, for update-path tests.
func manifestV2(t *testing.T, keyLine string) *Manifest {
	t.Helper()
	m := testManifest(t)
	m.Version = "2.0.0"
	m.Author.PublicKey = keyLine
	return m
}

// mustOpen fails the test when the bytes are not a valid package.
func mustOpen(t *testing.T, data []byte) *Package {
	t.Helper()
	pkg, err := OpenBytes(data)
	if err != nil {
		t.Fatalf("OpenBytes: %v", err)
	}
	return pkg
}

// TestCatalogInstallVerifiesAgainstPin is the D1 regression test: a catalog
// install must verify the signature against the catalog-pinned key, not the
// manifest's self-attested one. The package below declares key1 in its
// manifest but is signed by key2; it installs only when pinned to key2.
func TestCatalogInstallVerifiesAgainstPin(t *testing.T) {
	key1 := testPubKeyLine(t)
	key2 := pubKeyLineFor(t, testSeed2)
	m := testManifest(t) // declares key1
	if m.Author.PublicKey != key1 {
		t.Fatal("test setup: manifest should declare key1")
	}
	data := buildPackageWithSeed(t, m, testSeed2, nil, nil)

	s := openStoreForTest(t)
	if _, err := s.Install(mustOpen(t, data), SourceCatalog, testGranted, key2); err != nil {
		t.Fatalf("catalog install with the signing (pinned) key: %v", err)
	}
	inst, ok := s.Get(m.ID)
	if !ok {
		t.Fatal("not installed")
	}
	if !sameAuthorKey(inst.AuthorKey, key2) {
		t.Fatalf("stored pin = %q, want the catalog key", inst.AuthorKey)
	}
}

// TestCatalogInstallRejectsMismatchedPin: the same package pinned to the
// manifest's self-attested key (key1) must fail — the real signer is key2.
func TestCatalogInstallRejectsMismatchedPin(t *testing.T) {
	key1 := testPubKeyLine(t)
	m := testManifest(t) // declares key1
	data := buildPackageWithSeed(t, m, testSeed2, nil, nil)

	s := openStoreForTest(t)
	if _, err := s.Install(mustOpen(t, data), SourceCatalog, testGranted, key1); err == nil {
		t.Fatal("install with a pin the package is not signed by must fail")
	}
	if _, ok := s.Get(m.ID); ok {
		t.Fatal("failed install must not register the extension")
	}
}

// TestCatalogInstallRequiresPin: a catalog install without the pin fails
// closed instead of falling back to the self-attested manifest key.
func TestCatalogInstallRequiresPin(t *testing.T) {
	m := testManifest(t)
	data := buildPackage(t, m, nil, nil)

	s := openStoreForTest(t)
	if _, err := s.Install(mustOpen(t, data), SourceCatalog, testGranted, ""); err == nil {
		t.Fatal("catalog install without a pin must fail")
	}
	if _, err := s.Install(mustOpen(t, data), SourceCatalog, testGranted, "   "); err == nil {
		t.Fatal("catalog install with a blank pin must fail")
	}
}

// TestSideloadPinsManifestKey: non-catalog installs pin the manifest's
// self-attested key (trust on first use); the pin argument is ignored.
func TestSideloadPinsManifestKey(t *testing.T) {
	m := testManifest(t)
	data := buildPackage(t, m, nil, nil)

	s := openStoreForTest(t)
	if _, err := s.Install(mustOpen(t, data), SourceSideload, testGranted, "ignored"); err != nil {
		t.Fatalf("sideload install: %v", err)
	}
	inst, _ := s.Get(m.ID)
	if !sameAuthorKey(inst.AuthorKey, m.Author.PublicKey) {
		t.Fatalf("stored pin = %q, want the manifest key", inst.AuthorKey)
	}
}

// TestUpdateSameKeyOK: a same-key update installs and keeps the pin.
func TestUpdateSameKeyOK(t *testing.T) {
	key1 := testPubKeyLine(t)
	s := openStoreForTest(t)
	m1 := testManifest(t)
	if _, err := s.Install(mustOpen(t, buildPackage(t, m1, nil, nil)), SourceSideload, testGranted, ""); err != nil {
		t.Fatalf("v1 install: %v", err)
	}
	m2 := manifestV2(t, key1)
	if _, err := s.Install(mustOpen(t, buildPackage(t, m2, nil, nil)), SourceSideload, testGranted, ""); err != nil {
		t.Fatalf("same-key update: %v", err)
	}
	inst, _ := s.Get(m1.ID)
	if inst.Version != "2.0.0" {
		t.Fatalf("version = %q, want 2.0.0", inst.Version)
	}
	if !sameAuthorKey(inst.AuthorKey, key1) {
		t.Fatalf("pin after update = %q, want key1", inst.AuthorKey)
	}
}

// TestUpdateChangedKeyBlocked is the D2 regression test: an update whose
// author key differs from the pinned one is refused, and the installed
// version keeps working.
func TestUpdateChangedKeyBlocked(t *testing.T) {
	key1 := testPubKeyLine(t)
	key2 := pubKeyLineFor(t, testSeed2)
	s := openStoreForTest(t)
	m1 := testManifest(t)
	if _, err := s.Install(mustOpen(t, buildPackage(t, m1, nil, nil)), SourceSideload, testGranted, ""); err != nil {
		t.Fatalf("v1 install: %v", err)
	}
	// Same id, newer version, different author key, signed by the new key.
	m2 := manifestV2(t, key2)
	_, err := s.Install(mustOpen(t, buildPackageWithSeed(t, m2, testSeed2, nil, nil)), SourceSideload, testGranted, "")
	if err == nil {
		t.Fatal("key-changing update must be refused")
	}
	if !strings.Contains(err.Error(), "author key") {
		t.Fatalf("error should name the author key, got: %v", err)
	}
	inst, _ := s.Get(m1.ID)
	if inst.Version != "1.0.0" {
		t.Fatalf("failed update must leave v1 in place, got %q", inst.Version)
	}
	if !sameAuthorKey(inst.AuthorKey, key1) {
		t.Fatalf("pin after refused update = %q, want key1", inst.AuthorKey)
	}
}

// TestCatalogUpdateChangedKeyBlocked: the D2 catalog variant — even with
// the catalog pin supplied, an update carrying a different author key is
// refused. Rotating the trust anchor needs an explicit reinstall, never a
// silent adoption.
func TestCatalogUpdateChangedKeyBlocked(t *testing.T) {
	key1 := testPubKeyLine(t)
	key2 := pubKeyLineFor(t, testSeed2)
	s := openStoreForTest(t)
	m1 := testManifest(t)
	if _, err := s.Install(mustOpen(t, buildPackage(t, m1, nil, nil)), SourceCatalog, testGranted, key1); err != nil {
		t.Fatalf("v1 catalog install: %v", err)
	}
	m2 := manifestV2(t, key2)
	_, err := s.Install(mustOpen(t, buildPackageWithSeed(t, m2, testSeed2, nil, nil)), SourceCatalog, testGranted, key1)
	if err == nil {
		t.Fatal("key-changing catalog update must be refused")
	}
	inst, _ := s.Get(m1.ID)
	if inst.Version != "1.0.0" || !sameAuthorKey(inst.AuthorKey, key1) {
		t.Fatalf("refused update changed state: version=%q pin=%q", inst.Version, inst.AuthorKey)
	}
}

// TestKeyContinuityAcrossRollback: rollback to N-1 keeps the pin (the old
// version was installed under the same anchor).
func TestKeyContinuityAcrossRollback(t *testing.T) {
	key1 := testPubKeyLine(t)
	s := openStoreForTest(t)
	m1 := testManifest(t)
	if _, err := s.Install(mustOpen(t, buildPackage(t, m1, nil, nil)), SourceSideload, testGranted, ""); err != nil {
		t.Fatalf("v1 install: %v", err)
	}
	m2 := manifestV2(t, key1)
	if _, err := s.Install(mustOpen(t, buildPackage(t, m2, nil, nil)), SourceSideload, testGranted, ""); err != nil {
		t.Fatalf("v2 install: %v", err)
	}
	if err := s.Rollback(m1.ID); err != nil {
		t.Fatalf("rollback: %v", err)
	}
	inst, _ := s.Get(m1.ID)
	if inst.Version != "1.0.0" {
		t.Fatalf("version after rollback = %q", inst.Version)
	}
	if !sameAuthorKey(inst.AuthorKey, key1) {
		t.Fatalf("pin after rollback = %q, want key1", inst.AuthorKey)
	}
}

// TestSameAuthorKey: whitespace is forgiven, key bytes are not.
func TestSameAuthorKey(t *testing.T) {
	key1 := testPubKeyLine(t)
	key2 := pubKeyLineFor(t, testSeed2)
	if !sameAuthorKey("  "+key1+"\n", key1) {
		t.Fatal("surrounding whitespace should be forgiven")
	}
	if sameAuthorKey(key1, key2) {
		t.Fatal("different keys must not compare equal")
	}
	if sameAuthorKey(key1, strings.ToLower(key1)) && key1 != strings.ToLower(key1) {
		t.Fatal("base64 comparison must stay case-sensitive")
	}
}
