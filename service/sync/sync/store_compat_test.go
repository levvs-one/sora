package sync

// TestLegacyFileWithoutHash: files written before the cached "hash" field
// existed must still list and load with a computed hash.
import (
	"encoding/base64"
	"os"
	"path/filepath"
	"testing"
)

func TestLegacyFileWithoutHash(t *testing.T) {
	dir := t.TempDir()
	store, err := NewDirStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	payload := []byte("legacy-payload")
	raw := []byte(`{"updated_at":42,"payload":"` + base64.StdEncoding.EncodeToString(payload) + `","from":"old"}`)
	p := filepath.Join(dir, "rules", "old.json")
	if err := os.MkdirAll(filepath.Dir(p), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, raw, 0o600); err != nil {
		t.Fatal(err)
	}
	metas := store.List()
	if len(metas) != 1 || metas[0].Hash != HashOf(payload) || metas[0].UpdatedAt != 42 {
		t.Fatalf("list legacy: %+v", metas)
	}
	doc, ok := store.Get("rules", "old")
	if !ok || string(doc.Payload) != "legacy-payload" || doc.Hash != HashOf(payload) || doc.From != "old" {
		t.Fatalf("get legacy: %+v ok=%v", doc, ok)
	}
}
