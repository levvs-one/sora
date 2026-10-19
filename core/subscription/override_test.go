package subscription

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
)

func TestOverrideRoundTrip(t *testing.T) {
	s := NewOverrideStore(t.TempDir())
	o := &Override{
		Renames:     map[string]string{"u1_abc": "Home"},
		Hidden:      []string{"u1_def"},
		ExtraRules:  []OverrideRule{{Destination: "domain:example.com", OutboundID: "u1_abc"}},
		PinnedOrder: []string{"u1_abc"},
	}
	if err := s.Save("0123456789abcdef", o); err != nil {
		t.Fatal(err)
	}
	got, err := s.Load("0123456789abcdef")
	if err != nil {
		t.Fatal(err)
	}
	if got.Renames["u1_abc"] != "Home" || len(got.Hidden) != 1 || len(got.ExtraRules) != 1 || len(got.PinnedOrder) != 1 {
		t.Fatalf("round trip mismatch: %+v", got)
	}
}

func TestOverrideMissingIsEmpty(t *testing.T) {
	s := NewOverrideStore(t.TempDir())
	got, err := s.Load("0123456789abcdef")
	if err != nil {
		t.Fatal(err)
	}
	if len(got.Renames) != 0 || len(got.Hidden) != 0 {
		t.Fatalf("expected empty override: %+v", got)
	}
}

func TestOverrideCorruptIsNotFatal(t *testing.T) {
	dir := t.TempDir()
	s := NewOverrideStore(dir)
	path := filepath.Join(dir, "overrides", "0123456789abcdef.json")
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte("{broken"), 0o600); err != nil {
		t.Fatal(err)
	}
	got, err := s.Load("0123456789abcdef")
	if !errors.Is(err, ErrOverrideCorrupt) {
		t.Fatalf("expected ErrOverrideCorrupt, got %v", err)
	}
	if len(got.Renames) != 0 {
		t.Fatal("corrupt override must load as empty")
	}
}

func TestOverrideBadIDRejected(t *testing.T) {
	s := NewOverrideStore(t.TempDir())
	for _, id := range []string{"", "../evil", "0123456789abcdef.json", "UPPERCASE1234567"} {
		if _, err := s.Load(id); err == nil {
			t.Fatalf("expected rejection for id %q", id)
		}
		if err := s.Save(id, &Override{Renames: map[string]string{"a": "b"}}); err == nil {
			t.Fatalf("expected save rejection for id %q", id)
		}
		if err := s.Delete(id); err == nil {
			t.Fatalf("expected delete rejection for id %q", id)
		}
	}
}

func TestOverrideEmptySaveRemovesFile(t *testing.T) {
	dir := t.TempDir()
	s := NewOverrideStore(dir)
	if err := s.Save("0123456789abcdef", &Override{Renames: map[string]string{"a": "b"}}); err != nil {
		t.Fatal(err)
	}
	if err := s.Save("0123456789abcdef", &Override{}); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(dir, "overrides", "0123456789abcdef.json")
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatal("empty override must remove the file")
	}
}

func TestOverrideEmptySaveWithoutAFileIsFine(t *testing.T) {
	s := NewOverrideStore(t.TempDir())
	// Clearing overrides that were never stored must not fail: there is
	// simply no file to remove.
	if err := s.Save("0123456789abcdef", &Override{}); err != nil {
		t.Fatalf("Save(empty) without a file = %v", err)
	}
	if err := s.Save("0123456789abcdef", nil); err != nil {
		t.Fatalf("Save(nil) without a file = %v", err)
	}
}

func TestOverrideNilStoreSafe(t *testing.T) {
	var s *OverrideStore
	if _, err := s.Load("0123456789abcdef"); err == nil {
		t.Fatal("nil store load must fail")
	}
	if err := s.Save("0123456789abcdef", &Override{}); err == nil {
		t.Fatal("nil store save must fail")
	}
}
