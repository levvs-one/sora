//go:build !windows

package main

import (
	"context"
	"io"
	"log/slog"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/registry"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// fakeDiscover counts discovery calls and answers with a real discovery
// over an empty engines directory, which finds no engines instantly.
func fakeDiscover(t *testing.T, calls *atomic.Int64) func(ctx context.Context, dir string, base supervise.Config) *registry.Registry {
	t.Helper()
	empty := t.TempDir()
	return func(ctx context.Context, dir string, base supervise.Config) *registry.Registry {
		calls.Add(1)
		return registry.Discover(ctx, empty, base)
	}
}

func testLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

func TestLazyEnginesPinValidatedAtConstruction(t *testing.T) {
	ctx := t.Context()
	base := supervise.Config{}
	if _, err := newLazyEnginesWithDiscover(ctx, testLogger(), t.TempDir(), base, "bogus-kind",
		fakeDiscover(t, new(atomic.Int64))); err == nil {
		t.Fatal("unknown engine pin accepted at construction")
	}
	for _, pin := range []string{"", "sing-box", "xray", "mihomo"} {
		if _, err := newLazyEnginesWithDiscover(ctx, testLogger(), t.TempDir(), base,
			engine.Kind(pin), fakeDiscover(t, new(atomic.Int64))); err != nil {
			t.Fatalf("pin %q rejected: %v", pin, err)
		}
	}
}

func TestLazyEnginesDiscoversOnceUnderConcurrency(t *testing.T) {
	ctx := t.Context()
	var calls atomic.Int64
	l, err := newLazyEnginesWithDiscover(ctx, testLogger(), t.TempDir(), supervise.Config{},
		"", fakeDiscover(t, &calls))
	if err != nil {
		t.Fatal(err)
	}
	const getters = 16
	var wg sync.WaitGroup
	for i := 0; i < getters; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_ = l.Usable()
			_ = l.Availability()
			_ = l.Binaries()
			_ = l.BypassAvailable()
			_ = l.LastSelection()
		}()
	}
	wg.Wait()
	if n := calls.Load(); n != 1 {
		t.Fatalf("discovery ran %d times, want exactly 1", n)
	}
	if l.Usable() {
		t.Fatal("empty engines directory reported usable")
	}
	if got := l.Binaries(); len(got) != 0 {
		t.Fatalf("Binaries returned %d builds, want 0", len(got))
	}
}

// TestLazyEnginesWarmDiscoversWithoutAccessors checks the background
// warm-up started by the constructor finishes discovery on its own.
func TestLazyEnginesWarmDiscoversWithoutAccessors(t *testing.T) {
	ctx := t.Context()
	var calls atomic.Int64
	l, err := newLazyEnginesWithDiscover(ctx, testLogger(), t.TempDir(), supervise.Config{},
		"", fakeDiscover(t, &calls))
	if err != nil {
		t.Fatal(err)
	}
	deadline := time.Now().Add(5 * time.Second)
	for calls.Load() == 0 && time.Now().Before(deadline) {
		time.Sleep(5 * time.Millisecond)
	}
	if calls.Load() != 1 {
		t.Fatal("background warm-up did not run discovery")
	}
	// Accessors after warm-up must not trigger a second discovery.
	_ = l.Usable()
	if n := calls.Load(); n != 1 {
		t.Fatalf("discovery ran %d times after warm-up, want 1", n)
	}
}
