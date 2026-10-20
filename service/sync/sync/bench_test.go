package sync

// Benchmarks for the sync engine hot paths: applying 100 documents in one
// session, the DirStore write/read paths behind that application, and the
// payload hash every document carries.

import (
	"context"
	"fmt"
	"net"
	"sync"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/sync/pairing"
	"github.com/levvs-one/sora-client/sync/transport"
)

var benchKinds = []string{"subscription", "rules", "settings", "profiles", "chains", "extensions"}

// benchDocs returns n documents with deterministic 1 KiB payloads spread
// over the engine's document kinds.
func benchDocs(n int) []Document {
	docs := make([]Document, 0, n)
	for i := 0; i < n; i++ {
		payload := make([]byte, 1024)
		for j := range payload {
			payload[j] = byte(i + j)
		}
		docs = append(docs, Document{
			Meta: Meta{
				Kind:      benchKinds[i%len(benchKinds)],
				Name:      fmt.Sprintf("doc-%03d", i),
				UpdatedAt: int64(1000 + i),
				Hash:      HashOf(payload),
			},
			Payload: payload,
			From:    "bench",
		})
	}
	return docs
}

// benchMemStore is an in-memory Store with the same last-write-wins
// semantics as DirStore; it keeps the engine benchmark free of disk I/O.
type benchMemStore struct {
	mu   sync.Mutex
	docs map[[2]string]Document
}

func newBenchMemStore() *benchMemStore {
	return &benchMemStore{docs: map[[2]string]Document{}}
}

func (s *benchMemStore) List() []Meta {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]Meta, 0, len(s.docs))
	for _, d := range s.docs {
		out = append(out, d.Meta)
	}
	return out
}

func (s *benchMemStore) Get(kind, name string) (Document, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	d, ok := s.docs[[2]string{kind, name}]
	return d, ok
}

func (s *benchMemStore) Put(doc Document) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	k := [2]string{doc.Kind, doc.Name}
	if old, ok := s.docs[k]; ok && old.UpdatedAt >= doc.UpdatedAt {
		return false, nil
	}
	s.docs[k] = doc
	return true, nil
}

// benchLinkedConnsTCP returns a handshaked initiator/responder transport
// pair over TCP loopback for engine benchmarks.
func benchLinkedConnsTCP(tb testing.TB) (initiator, responder *transport.Conn) {
	tb.Helper()
	inv, epriv, err := pairing.Generate("device-a")
	if err != nil {
		tb.Fatal(err)
	}
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		tb.Fatal(err)
	}
	defer func() { _ = ln.Close() }()
	acceptCh := make(chan net.Conn, 1)
	go func() {
		c, err := ln.Accept()
		if err == nil {
			acceptCh <- c
		}
	}()
	raw, err := net.Dial("tcp", ln.Addr().String())
	if err != nil {
		tb.Fatal(err)
	}
	peerRaw := <-acceptCh
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	type result struct {
		c   *transport.Conn
		err error
	}
	resCh := make(chan result, 1)
	go func() {
		c, err := transport.Accept(ctx, peerRaw, epriv, inv.Token, transport.Identity{DeviceID: "device-a"})
		resCh <- result{c, err}
	}()
	dialCh := make(chan result, 1)
	go func() {
		c, err := transport.Dial(ctx, raw, inv, transport.Identity{DeviceID: "device-b"})
		dialCh <- result{c, err}
	}()
	ar := <-resCh
	dr := <-dialCh
	if ar.err != nil || dr.err != nil {
		tb.Fatalf("handshake: %v %v", ar.err, dr.err)
	}
	return dr.c, ar.c
}

// BenchmarkApply100Docs measures one full sync session that applies 100
// documents (1 KiB each) to an empty store - inventories, per-document
// fetch, decode, and store are all included.
func BenchmarkApply100Docs(b *testing.B) {
	docs := benchDocs(100)
	src := newBenchMemStore()
	for _, d := range docs {
		if _, err := src.Put(d); err != nil {
			b.Fatal(err)
		}
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		b.StopTimer()
		dst := newBenchMemStore()
		ic, rc := benchLinkedConnsTCP(b)
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		b.StartTimer()

		initDone := make(chan error, 1)
		go func() {
			_, err := Sync(ctx, rc, "device-a", src, false)
			initDone <- err
		}()
		rep, err := Sync(ctx, ic, "device-b", dst, true)
		if err != nil {
			b.Fatalf("initiator: %v", err)
		}
		if err := <-initDone; err != nil {
			b.Fatalf("responder: %v", err)
		}
		if len(rep.Pulled) != len(docs) {
			b.Fatalf("applied %d docs, want %d", len(rep.Pulled), len(docs))
		}

		b.StopTimer()
		_ = ic.Close()
		_ = rc.Close()
		cancel()
		b.StartTimer()
	}
}

// BenchmarkDirStorePut100Docs measures storing 100 fresh documents
// (the store side of applying them): JSON+base64 encode plus atomic write.
func BenchmarkDirStorePut100Docs(b *testing.B) {
	docs := benchDocs(100)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		b.StopTimer()
		store, err := NewDirStore(b.TempDir())
		if err != nil {
			b.Fatal(err)
		}
		b.StartTimer()
		for _, d := range docs {
			if _, err := store.Put(d); err != nil {
				b.Fatal(err)
			}
		}
	}
}

// BenchmarkDirStoreList100Docs measures one inventory scan over 100 stored
// documents - the list the engine exchanges at the start of every session
// and answers every GET /v1/documents with.
func BenchmarkDirStoreList100Docs(b *testing.B) {
	docs := benchDocs(100)
	store, err := NewDirStore(b.TempDir())
	if err != nil {
		b.Fatal(err)
	}
	for _, d := range docs {
		if _, err := store.Put(d); err != nil {
			b.Fatal(err)
		}
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		metas := store.List()
		if len(metas) != len(docs) {
			b.Fatalf("listed %d docs, want %d", len(metas), len(docs))
		}
	}
}

// BenchmarkHashOf1KB measures the per-document payload hash.
func BenchmarkHashOf1KB(b *testing.B) {
	payload := make([]byte, 1024)
	for i := range payload {
		payload[i] = byte(i)
	}
	b.SetBytes(int64(len(payload)))
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if h := HashOf(payload); len(h) != 64 {
			b.Fatal(h)
		}
	}
}
