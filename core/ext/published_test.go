package ext

import (
	"crypto/sha256"
	"encoding/hex"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// TestPublishedTeamDocumentsVerify checks the files the app downloads from
// extensions/ in the repository: both signatures verify with TeamPublicKey,
// the catalog points at the committed package with its real size and hash,
// and the revocation list has not expired.
func TestPublishedTeamDocumentsVerify(t *testing.T) {
	dir := filepath.Join("..", "..", "extensions")
	read := func(name string) []byte {
		t.Helper()
		b, err := os.ReadFile(filepath.Join(dir, name))
		if err != nil {
			t.Fatal(err)
		}
		return b
	}
	catalogJSON := read("catalog.json")
	if err := VerifyCatalogSignature(string(read("catalog.json.minisig")), catalogJSON); err != nil {
		t.Fatalf("catalog signature: %v", err)
	}
	catalog, err := ParseCatalog(catalogJSON)
	if err != nil {
		t.Fatalf("catalog: %v", err)
	}
	for _, e := range catalog.Extensions {
		pkg := read(filepath.Join("packages", filepath.Base(e.DownloadURL)))
		sum := sha256.Sum256(pkg)
		if hex.EncodeToString(sum[:]) != e.Sha256 || int64(len(pkg)) != e.Size {
			t.Errorf("%s: catalog hash or size does not match the committed package", e.ID)
		}
	}
	list, err := VerifyRevocationList(string(read("revocations.json.minisig")), read("revocations.json"))
	if err != nil {
		t.Fatalf("revocation list: %v", err)
	}
	if list.Expired(time.Now().Add(14 * 24 * time.Hour)) {
		t.Errorf("revocation list expires at %s, re-sign it (extensions/README.md)", list.ExpiresAt)
	}
}
