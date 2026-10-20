package session

import (
	"context"
	"testing"
)

// Benchmarks for the session start path (zone H): plan coordination without
// a real engine, using the fakes from session_test.go.

func BenchmarkSessionStart(b *testing.B) {
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		eng, gd := newFakeEngine(), &fakeGuard{}
		s, err := New(testConfig(eng, gd))
		if err != nil {
			b.Fatal(err)
		}
		if err := s.Start(context.Background()); err != nil {
			b.Fatal(err)
		}
		if err := s.Stop(context.Background()); err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkSessionSettings(b *testing.B) {
	eng, gd := newFakeEngine(), &fakeGuard{}
	s, err := New(testConfig(eng, gd))
	if err != nil {
		b.Fatal(err)
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = s.settings()
	}
}

// BenchmarkJournalSinceShort is the censor-ingest shape: a caller asks
// for the journal cap's worth of events from a young journal holding
// only a few. Since must not reserve the full limit for them.
func BenchmarkJournalSinceShort(b *testing.B) {
	j := NewJournal(DefaultJournalCapacity)
	for i := 0; i < 8; i++ {
		j.Append(Event{Kind: EventLog, Detail: "line"})
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if evs := j.Since(0, 256); len(evs) != 8 {
			b.Fatalf("got %d events", len(evs))
		}
	}
}

// BenchmarkJournalSinceFull is the steady state: a full journal, a
// full-limit read — the reservation matches the copy.
func BenchmarkJournalSinceFull(b *testing.B) {
	j := NewJournal(DefaultJournalCapacity)
	for i := 0; i < DefaultJournalCapacity; i++ {
		j.Append(Event{Kind: EventLog, Detail: "line"})
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if evs := j.Since(0, 256); len(evs) != 256 {
			b.Fatalf("got %d events", len(evs))
		}
	}
}
