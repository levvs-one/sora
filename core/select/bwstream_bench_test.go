package serversel

// Benchmarks for the history-driven selection path the bandwidth stream
// feeds: picking the best server out of a large candidate set, and
// journaling one more outcome into a large persisted reliability store.
// Baselines for the [opt40] bandwidth-stream pass; they must stay green
// alongside the correctness tests.
//
// Run with: go test -bench=. -benchtime=20x -run=NONE ./select/

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

func benchCandidates1000() []Candidate {
	cands := make([]Candidate, 0, 1000)
	now := time.Now()
	for i := 0; i < 1000; i++ {
		cands = append(cands, Candidate{
			ID:           fmt.Sprintf("srv-%d", i),
			Protocol:     engine.ProtocolVLESS,
			LatencyMs:    uint32(20 + i%300),
			HasLatency:   true,
			BandwidthBps: uint64(1_000_000 + i*7919),
			HasBandwidth: true,
			MeasuredAt:   now,
		})
	}
	return cands
}

// BenchmarkPickBest1000 picks one winner out of 1000 measured servers.
// The previous implementation copied the survivors twice and stable-
// sorted them: 543 247 B/op, 18 allocs. The best-scan needs 8 289 B/op.
func BenchmarkPickBest1000(b *testing.B) {
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), nil)
	cands := benchCandidates1000()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		pick, err := p.PickBest(cands, Constraints{})
		if err != nil {
			b.Fatal(err)
		}
		if pick.Candidate.ID == "" {
			b.Fatal("empty pick")
		}
	}
}

// BenchmarkPickBest1000WithStore is PickBest with a populated
// reliability store: every candidate's rate comes from its history.
func BenchmarkPickBest1000WithStore(b *testing.B) {
	rel := NewReliabilityStore(ReliabilityConfig{})
	now := time.Now()
	for i := 0; i < 1000; i++ {
		rel.entries[fmt.Sprintf("srv-%d", i)] = reliabilityEntry{Successes: 9, Failures: 1, LastSeen: now}
	}
	p := NewPicker(DefaultScoreConfig(), DefaultPickConfig(), rel)
	cands := benchCandidates1000()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		pick, err := p.PickBest(cands, Constraints{})
		if err != nil {
			b.Fatal(err)
		}
		if pick.Candidate.ID == "" {
			b.Fatal("empty pick")
		}
	}
}

func benchStore1000(b *testing.B, persisted bool) *ReliabilityStore {
	b.Helper()
	cfg := ReliabilityConfig{}
	if persisted {
		cfg.DataDir = b.TempDir()
	}
	s := NewReliabilityStore(cfg)
	now := time.Now()
	for i := 0; i < 1000; i++ {
		s.entries[fmt.Sprintf("srv-%d", i)] = reliabilityEntry{Successes: 9, Failures: 1, LastSeen: now}
	}
	return s
}

// BenchmarkReliabilityRecord1000Persisted journals one outcome into a
// 1000-entry store with persistence on: every Record rewrites the
// journal file. Copying the kept map plus a fresh json.Marshal cost
// 278 716 B/op and 1024 allocs per Record; the reused-buffer serializer
// brings that down to the file write itself.
func BenchmarkReliabilityRecord1000Persisted(b *testing.B) {
	s := benchStore1000(b, true)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		s.Record("srv-500", i%2 == 0)
	}
}

// TestReliabilitySaveMatchesJSONMarshal pins the persisted journal's
// bytes: saveLocked's hand-rolled serializer must produce exactly what
// json.Marshal of the pruned entry map produced before, for plain and
// adversarial ids alike, and must prune expired entries the same way.
func TestReliabilitySaveMatchesJSONMarshal(t *testing.T) {
	now := time.Date(2026, 10, 20, 12, 0, 0, 123456789, time.FixedZone("MSK", 3*3600))
	s := NewReliabilityStore(ReliabilityConfig{
		DataDir: t.TempDir(),
		TTL:     24 * time.Hour,
		Now:     func() time.Time { return now },
	})
	ids := []string{
		"srv-1", "srv-2", `quote"id`, `back\slash`, "html<>&", "ctrl\x01\x1f", "del\x7f",
		"кириллица", "emoji-🚀", "line sep", "invalid\xffutf8", "",
	}
	want := map[string]reliabilityEntry{}
	for i, id := range ids {
		e := reliabilityEntry{Successes: uint32(i), Failures: uint32(1000 - i), LastSeen: now.Add(-time.Duration(i) * time.Minute)}
		s.entries[id] = e
		want[id] = e
	}
	// One expired entry: it must be absent from the file, like before.
	s.entries["expired"] = reliabilityEntry{Successes: 1, LastSeen: now.Add(-48 * time.Hour)}

	s.mu.Lock()
	s.saveLocked()
	s.mu.Unlock()

	raw, err := os.ReadFile(s.filePath)
	if err != nil {
		t.Fatal(err)
	}
	wantRaw, err := json.Marshal(want)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(raw, wantRaw) {
		t.Fatalf("saved journal differs from json.Marshal:\n got %s\nwant %s", raw, wantRaw)
	}
	if _, ok := s.entries["expired"]; !ok {
		t.Fatal("expired entry must stay in memory; only the file prunes it")
	}
}

// TestReliabilitySaveSkipsOutOfRangeYear pins the error path: a
// timestamp encoding/json cannot marshal must leave the file unwritten,
// exactly as the old Marshal-error return did.
func TestReliabilitySaveSkipsOutOfRangeYear(t *testing.T) {
	now := time.Date(2026, 10, 20, 12, 0, 0, 0, time.UTC)
	s := NewReliabilityStore(ReliabilityConfig{
		DataDir: t.TempDir(),
		Now:     func() time.Time { return now },
	})
	s.entries["srv-1"] = reliabilityEntry{Successes: 1, LastSeen: time.Date(10000, 1, 1, 0, 0, 0, 0, time.UTC)}
	s.mu.Lock()
	s.saveLocked()
	s.mu.Unlock()
	if _, err := os.Stat(s.filePath); !os.IsNotExist(err) {
		t.Fatalf("file should not exist after an unmarshalable timestamp, stat err = %v", err)
	}
}
