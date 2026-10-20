//go:build !windows

package main

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

// BenchmarkNewCold measures full App construction on a fresh data dir with
// no engines installed: the cold path a first service start takes.
func BenchmarkNewCold(b *testing.B) {
	ctx := context.Background()
	for i := 0; i < b.N; i++ {
		dir, err := os.MkdirTemp("", "sora-bench-")
		if err != nil {
			b.Fatal(err)
		}
		app, err := New(ctx, Options{
			DataDir:    dir,
			EnginesDir: filepath.Join(dir, "engines"),
			Socket:     filepath.Join(dir, "core.sock"),
		})
		if err != nil {
			b.Fatal(err)
		}
		if err := app.Close(); err != nil {
			b.Fatal(err)
		}
		_ = os.RemoveAll(dir)
	}
}
