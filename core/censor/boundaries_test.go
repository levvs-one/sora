package censor

import (
	"fmt"
	"testing"
)

// Boundary tests for the SNI pool: sizes 0 and 1, the deterministic
// rotation order (profile order is the priority — with no other
// signal, equal candidates rotate strictly in the order the profile
// listed them, every run, so a rotation is replayable in a test and
// predictable in a postmortem), and a large pool cycling fully
// before repeating.
func TestSNIPoolBoundaries(t *testing.T) {
	t.Run("empty pool", func(t *testing.T) {
		p := NewSNIPool(nil)
		if p.Len() != 0 || p.Current() != "" || p.Rotate() != "" || p.BurnAndRotate("a.test") != "" {
			t.Fatal("an empty pool must answer empty everywhere, never invent a member")
		}
	})
	t.Run("single member", func(t *testing.T) {
		p := NewSNIPool([]string{"only.test"})
		if p.Current() != "only.test" {
			t.Fatal("the single member is current")
		}
		if got := p.Rotate(); got != "only.test" {
			t.Fatalf("rotating a 1-pool returns its member, got %q", got)
		}
		if got := p.BurnAndRotate("only.test"); got != "" {
			t.Fatalf("burning the only member must exhaust the pool, got %q", got)
		}
	})
	t.Run("rotation order is the profile order, deterministically", func(t *testing.T) {
		want := []string{"b.test", "c.test", "a.test", "b.test", "c.test", "a.test"}
		for run := 0; run < 2; run++ {
			p := NewSNIPool([]string{"a.test", "b.test", "c.test"})
			for i, w := range want {
				if got := p.Rotate(); got != w {
					t.Fatalf("run %d step %d: Rotate = %q, want %q (rotation must be deterministic)", run, i, got, w)
				}
			}
		}
	})
	t.Run("large pool cycles fully before repeating", func(t *testing.T) {
		const n = 300
		names := make([]string, n)
		for i := range names {
			names[i] = fmt.Sprintf("dest-%03d.test", i)
		}
		p := NewSNIPool(names)
		if p.Len() != n {
			t.Fatalf("Len = %d, want %d", p.Len(), n)
		}
		seen := map[string]bool{}
		for i := 0; i < n; i++ {
			s := p.Rotate()
			if seen[s] {
				t.Fatalf("member %q repeated after %d rotations of a %d-pool", s, i, n)
			}
			seen[s] = true
		}
	})
	t.Run("duplicate and empty candidates collapse", func(t *testing.T) {
		p := NewSNIPool([]string{"A.test.", "a.test", "", "  ", "b.test"})
		if p.Len() != 2 {
			t.Fatalf("Len = %d, want 2 after normalization/dedup", p.Len())
		}
	})
}
