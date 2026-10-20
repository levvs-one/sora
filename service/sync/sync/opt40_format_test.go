package sync

// Format-pinning tests for the []byte payload representation: the
// stored file bytes and the wire bytes must stay exactly what the
// previous string-field representation produced, including for a
// payload whose base64 uses '+', '/' and '=' padding, and for an
// empty payload ("" — never JSON null).

import (
	"encoding/base64"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestStoredFileBytesUnchanged(t *testing.T) {
	payload := []byte{0xfb, 0xff, 0x00, 0x10, 0x83, 0xfe}
	store, err := NewDirStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	doc := Document{
		Meta:    Meta{Kind: "rules", Name: "fmt", UpdatedAt: 42, Hash: HashOf(payload)},
		Payload: payload, From: "old",
	}
	if _, err := store.Put(doc); err != nil {
		t.Fatal(err)
	}
	raw, err := os.ReadFile(filepath.Join(store.dir, "rules", "fmt.json"))
	if err != nil {
		t.Fatal(err)
	}
	want := `{"updated_at":42,"payload":"` + base64.StdEncoding.EncodeToString(payload) +
		`","from":"old","hash":"` + HashOf(payload) + `"}`
	if string(raw) != want {
		t.Fatalf("stored bytes changed:\n got %s\nwant %s", raw, want)
	}
}

func TestStoredEmptyPayloadStaysEmptyString(t *testing.T) {
	store, err := NewDirStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	doc := Document{Meta: Meta{Kind: "rules", Name: "empty", UpdatedAt: 1, Hash: HashOf(nil)}}
	if _, err := store.Put(doc); err != nil {
		t.Fatal(err)
	}
	raw, err := os.ReadFile(filepath.Join(store.dir, "rules", "empty.json"))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(raw), `"payload":""`) {
		t.Fatalf("empty payload must store as \"\", got %s", raw)
	}
	got, ok := store.Get("rules", "empty")
	if !ok || len(got.Payload) != 0 {
		t.Fatalf("get empty: ok=%v len=%d", ok, len(got.Payload))
	}
}

func TestWireBytesUnchanged(t *testing.T) {
	payload := []byte{0xfb, 0xff, 0x00, 0x10, 0x83, 0xfe}
	doc := Document{
		Meta:    Meta{Kind: "rules", Name: "fmt", UpdatedAt: 42, Hash: HashOf(payload)},
		Payload: payload, From: "old",
	}
	raw, err := json.Marshal(message{T: "doc", Doc: ptr(toWire(doc))})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(raw), `"payload":"`+base64.StdEncoding.EncodeToString(payload)+`"`) {
		t.Fatalf("wire payload encoding changed: %s", raw)
	}
	var m message
	if err := json.Unmarshal(raw, &m); err != nil {
		t.Fatal(err)
	}
	got, err := fromWire(*m.Doc)
	if err != nil || string(got.Payload) != string(payload) || got.Hash != HashOf(payload) {
		t.Fatalf("wire round trip: err=%v got=%+v", err, got)
	}
	// Empty payload stays "" on the wire.
	raw, err = json.Marshal(message{T: "doc", Doc: ptr(toWire(Document{}))})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(raw), `"payload":""`) {
		t.Fatalf("empty wire payload must be \"\", got %s", raw)
	}
	// A frame written by the old string-field form still decodes.
	legacy := []byte(`{"t":"doc","doc":{"kind":"k","name":"n","updated_at":7,"payload":"` +
		base64.StdEncoding.EncodeToString(payload) + `","from":"old"}}`)
	var lm message
	if err := json.Unmarshal(legacy, &lm); err != nil {
		t.Fatal(err)
	}
	lgot, err := fromWire(*lm.Doc)
	if err != nil || string(lgot.Payload) != string(payload) {
		t.Fatalf("legacy wire frame: err=%v got=%+v", err, lgot)
	}
}
