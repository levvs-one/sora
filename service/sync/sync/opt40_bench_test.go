package sync

import (
	"encoding/json"
	"testing"
)

// BenchmarkDirStoreGet1MiB measures reading one 1 MiB document back:
// file read, JSON unmarshal, and the payload decode behind every
// GET /v1/documents/{kind}/{name} and every push-side store.Get.
func BenchmarkDirStoreGet1MiB(b *testing.B) {
	payload := make([]byte, 1<<20)
	for i := range payload {
		payload[i] = byte(i)
	}
	store, err := NewDirStore(b.TempDir())
	if err != nil {
		b.Fatal(err)
	}
	if _, err := store.Put(Document{
		Meta:    Meta{Kind: "subscription", Name: "big", UpdatedAt: 1000, Hash: HashOf(payload)},
		Payload: payload, From: "bench",
	}); err != nil {
		b.Fatal(err)
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		doc, ok := store.Get("subscription", "big")
		if !ok || len(doc.Payload) != len(payload) {
			b.Fatalf("get: ok=%v len=%d", ok, len(doc.Payload))
		}
	}
}

// BenchmarkDirStorePutUpdate1MiB measures overwriting a stored 1 MiB
// document with a newer copy: the existence check reads the stored
// file, then the new copy is encoded and written atomically.
func BenchmarkDirStorePutUpdate1MiB(b *testing.B) {
	payload := make([]byte, 1<<20)
	for i := range payload {
		payload[i] = byte(i)
	}
	store, err := NewDirStore(b.TempDir())
	if err != nil {
		b.Fatal(err)
	}
	doc := Document{
		Meta:    Meta{Kind: "subscription", Name: "big", UpdatedAt: 1000, Hash: HashOf(payload)},
		Payload: payload, From: "bench",
	}
	if _, err := store.Put(doc); err != nil {
		b.Fatal(err)
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		doc.UpdatedAt++
		changed, err := store.Put(doc)
		if err != nil || !changed {
			b.Fatalf("put: changed=%v err=%v", changed, err)
		}
	}
}

// BenchmarkWireDoc1MiB measures one document crossing the sync channel:
// toWire + JSON marshal on the sender, JSON unmarshal + fromWire on
// the receiver — the per-document merge-path cost of a sync round.
func BenchmarkWireDoc1MiB(b *testing.B) {
	payload := make([]byte, 1<<20)
	for i := range payload {
		payload[i] = byte(i)
	}
	doc := Document{
		Meta:    Meta{Kind: "subscription", Name: "big", UpdatedAt: 1000, Hash: HashOf(payload)},
		Payload: payload, From: "bench",
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		raw, err := json.Marshal(message{T: "doc", Doc: ptr(toWire(doc))})
		if err != nil {
			b.Fatal(err)
		}
		var m message
		if err := json.Unmarshal(raw, &m); err != nil {
			b.Fatal(err)
		}
		got, err := fromWire(*m.Doc)
		if err != nil || len(got.Payload) != len(payload) {
			b.Fatalf("fromWire: err=%v len=%d", err, len(got.Payload))
		}
	}
}
