package api

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	syncpkg "github.com/levvs-one/sora-client/sync/sync"
)

// benchDocDaemon returns a daemon whose store holds one document with a
// payload of payloadSize bytes, plus that payload.
func benchDocDaemon(b *testing.B, payloadSize int) (*Daemon, []byte) {
	b.Helper()
	payload := make([]byte, payloadSize)
	for i := range payload {
		payload[i] = byte(i)
	}
	store, err := syncpkg.NewDirStore(b.TempDir())
	if err != nil {
		b.Fatal(err)
	}
	if _, err := store.Put(syncpkg.Document{
		Meta:    syncpkg.Meta{Kind: "subscription", Name: "big", UpdatedAt: 1000, Hash: syncpkg.HashOf(payload)},
		Payload: payload, From: "bench",
	}); err != nil {
		b.Fatal(err)
	}
	d := &Daemon{
		identity: &Identity{ID: "device-bench", Name: "Bench"},
		store:    store,
		peers:    benchPeers(5),
	}
	return d, payload
}

// BenchmarkHandleStatus measures one GET /v1/status poll (the UI polls
// this while pairing/syncing) with a realistic 5-peer registry.
func BenchmarkHandleStatus(b *testing.B) {
	d, _ := benchDocDaemon(b, 1024)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		rec := httptest.NewRecorder()
		d.handleStatus(rec, httptest.NewRequest(http.MethodGet, "/v1/status", nil))
		if rec.Code != http.StatusOK {
			b.Fatalf("status: %d", rec.Code)
		}
	}
}

// BenchmarkHandleDocGet256KiB measures one GET of a 256 KiB document
// (a large subscription) through the localhost API.
func BenchmarkHandleDocGet256KiB(b *testing.B) {
	d, _ := benchDocDaemon(b, 256<<10)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/v1/documents/subscription/big", nil)
		req.SetPathValue("kind", "subscription")
		req.SetPathValue("name", "big")
		d.handleDocGet(rec, req)
		if rec.Code != http.StatusOK {
			b.Fatalf("get: %d", rec.Code)
		}
	}
}

// BenchmarkHandleDocPut256KiB measures one PUT of a 256 KiB document
// through the localhost API: JSON decode, base64 decode, store write.
func BenchmarkHandleDocPut256KiB(b *testing.B) {
	d, payload := benchDocDaemon(b, 256<<10)
	body, err := json.Marshal(map[string]any{
		"payload":    base64.StdEncoding.EncodeToString(payload),
		"updated_at": 1000,
	})
	if err != nil {
		b.Fatal(err)
	}
	var updatedAt int64 = 1000
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		updatedAt++
		// Rebuild the body with a fresh timestamp so every PUT stores.
		body = fmt.Appendf(nil, `{"payload":%q,"updated_at":%d}`,
			base64.StdEncoding.EncodeToString(payload), updatedAt)
		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodPut, "/v1/documents/subscription/big", bytes.NewReader(body))
		req.SetPathValue("kind", "subscription")
		req.SetPathValue("name", "big")
		d.handleDocPut(rec, req)
		if rec.Code != http.StatusOK {
			b.Fatalf("put: %d", rec.Code)
		}
	}
}
