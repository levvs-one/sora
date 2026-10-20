package censor

// Regression benchmarks for the [opt40] HandshakeLimiter fast path:
// Acquire used to arm a time.NewTimer on every call (248 B / 3 allocs
// for the timer alone) even when a slot was free. The uncontended
// acquire now takes the slot without a timer:
//
//	clean SNI:   264 B/op, 4 allocs -> 16 B/op, 1 alloc
//	mixed case:  280 B/op, 5 allocs -> 32 B/op, 2 allocs (ToLower copy)
//
// The contended path (all slots busy) still arms the timer exactly as
// before; TestHandshakeLimiter covers its timeout and TestHandshake-
// LimiterCancelledContextFreeSlot below pins the cancelled-context
// pre-check the fast path added.

import (
	"context"
	"testing"
)

func BenchmarkHandshakeLimiterAcquireRelease(b *testing.B) {
	l := NewHandshakeLimiter(3, 0)
	ctx := context.Background()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		rel, err := l.Acquire(ctx, "example.com")
		if err != nil {
			b.Fatal(err)
		}
		rel()
	}
}

func BenchmarkHandshakeLimiterAcquireReleaseMixedCase(b *testing.B) {
	l := NewHandshakeLimiter(3, 0)
	ctx := context.Background()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		rel, err := l.Acquire(ctx, "Example.COM.")
		if err != nil {
			b.Fatal(err)
		}
		rel()
	}
}

func BenchmarkHandshakeLimiterInFlight(b *testing.B) {
	l := NewHandshakeLimiter(3, 0)
	ctx := context.Background()
	rel, err := l.Acquire(ctx, "example.com")
	if err != nil {
		b.Fatal(err)
	}
	defer rel()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = l.InFlight("example.com")
	}
}

// TestHandshakeLimiterCancelledContextFreeSlot: a caller whose context
// is already cancelled must not take a slot, even when one is free.
// Before the fast path, Acquire's three-way select made this outcome
// random; the pre-check makes the documented contract deterministic.
func TestHandshakeLimiterCancelledContextFreeSlot(t *testing.T) {
	l := NewHandshakeLimiter(2, 0)
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := l.Acquire(ctx, "a.example"); err != context.Canceled {
		t.Fatalf("Acquire with cancelled context = %v, want context.Canceled", err)
	}
	if got := l.InFlight("a.example"); got != 0 {
		t.Fatalf("cancelled acquire took a slot: in flight = %d", got)
	}
}
