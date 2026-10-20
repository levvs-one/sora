//go:build linux

package tunroute

import (
	"context"
	"testing"
)

// BenchmarkCleanupNoStaleState measures startup's stale-route cleanup on
// a machine with nothing to remove — the common case, whose cost is the
// ip process spawns themselves. unroute fetches both families' rules and
// tables concurrently; the sequential version measured ~3x this on the
// audit VM (~120 ms vs ~37 ms for Cleanup).
func BenchmarkCleanupNoStaleState(b *testing.B) {
	ctx := context.Background()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		if err := Cleanup(ctx); err != nil {
			b.Fatal(err)
		}
	}
}
