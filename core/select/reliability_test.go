package serversel

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestReliabilityPriorForUnknown(t *testing.T) {
	s := NewReliabilityStore(ReliabilityConfig{})
	if got := s.Rate("nope"); got != 0.5 {
		t.Fatalf("unknown server must score the prior 0.5, got %v", got)
	}
	if _, _, found := s.Stats("nope"); found {
		t.Fatal("unknown server must not be found")
	}
}

func TestReliabilityRecordAndRate(t *testing.T) {
	s := NewReliabilityStore(ReliabilityConfig{PriorSuccess: 1, PriorFailure: 1})
	for i := 0; i < 8; i++ {
		s.Record("a", true)
	}
	for i := 0; i < 2; i++ {
		s.Record("a", false)
	}
	// (8+1)/(8+2+1+1) = 0.75 with the default 1/1 prior.
	if got := s.Rate("a"); got != 0.75 {
		t.Fatalf("rate = %v, want 0.75", got)
	}
	succ, fail, found := s.Stats("a")
	if !found || succ != 8 || fail != 2 {
		t.Fatalf("stats = %d/%d found=%v, want 8/2 true", succ, fail, found)
	}
	// All failures must drag the rate below the prior.
	for i := 0; i < 10; i++ {
		s.Record("b", false)
	}
	if got := s.Rate("b"); got >= 0.5 {
		t.Fatalf("failing server must score below prior, got %v", got)
	}
}

func TestReliabilityIgnoresEmptyID(t *testing.T) {
	s := NewReliabilityStore(ReliabilityConfig{})
	s.Record("", true)
	if _, _, found := s.Stats(""); found {
		t.Fatal("empty id must be ignored")
	}
}

func TestReliabilityTTLExpiry(t *testing.T) {
	now := time.Now()
	cur := now
	s := NewReliabilityStore(ReliabilityConfig{
		TTL:          time.Hour,
		PriorSuccess: 1,
		PriorFailure: 1,
		Now:          func() time.Time { return cur },
	})
	s.Record("a", true)
	if got := s.Rate("a"); got <= 0.5 {
		t.Fatalf("fresh success must beat prior, got %v", got)
	}
	cur = now.Add(2 * time.Hour)
	if got := s.Rate("a"); got != 0.5 {
		t.Fatalf("expired entry must fall back to prior, got %v", got)
	}
	if _, _, found := s.Stats("a"); found {
		t.Fatal("expired entry must not be found")
	}
	if n := s.Prune(); n != 1 {
		t.Fatalf("prune removed %d, want 1", n)
	}
}

func TestReliabilityPersistenceRoundTrip(t *testing.T) {
	dir := t.TempDir()
	s := NewReliabilityStore(ReliabilityConfig{DataDir: dir})
	s.Record("a", true)
	s.Record("a", false)
	want := s.Rate("a")

	s2 := NewReliabilityStore(ReliabilityConfig{DataDir: dir})
	if got := s2.Rate("a"); got != want {
		t.Fatalf("reloaded rate %v != saved %v", got, want)
	}
	if _, err := os.Stat(filepath.Join(dir, "probe", "reliability.json")); err != nil {
		t.Fatalf("history file missing: %v", err)
	}
}

func TestReliabilityCorruptFileIsDropped(t *testing.T) {
	dir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(dir, "probe"), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "probe", "reliability.json"), []byte("{nope"), 0o600); err != nil {
		t.Fatal(err)
	}
	s := NewReliabilityStore(ReliabilityConfig{DataDir: dir})
	if got := s.Rate("a"); got != 0.5 {
		t.Fatalf("corrupt file must start empty, got %v", got)
	}
	// Writing over the corrupt file must heal it.
	s.Record("a", true)
	s2 := NewReliabilityStore(ReliabilityConfig{DataDir: dir})
	if got := s2.Rate("a"); got <= 0.5 {
		t.Fatalf("healed file must keep the record, got %v", got)
	}
}

func TestReliabilityConfigClamps(t *testing.T) {
	s := NewReliabilityStore(ReliabilityConfig{TTL: -time.Hour, PriorSuccess: 5000})
	cfg := s.Config()
	if cfg.TTL != time.Hour {
		t.Fatalf("TTL not clamped: %v", cfg.TTL)
	}
	if cfg.PriorSuccess != 1000 {
		t.Fatalf("prior not clamped: %v", cfg.PriorSuccess)
	}
}
