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
