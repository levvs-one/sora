package probe

// Regression control for the [opt40] QUIC result rendering:
// QUICResult.Advice rendered the local port with fmt.Sprint (3 allocs
// for the blocked verdict). It now uses strconv.Itoa, the same
// treatment banKey already had: 253 B/op, 3 allocs -> 229 B/op,
// 2 allocs, byte-identical output (pinned by the test below).

import "testing"

func BenchmarkQUICAdviceBlocked(b *testing.B) {
	r := &QUICResult{Verdict: VerdictBlocked, LocalPort: 45678}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = r.Advice()
	}
}

// TestQUICAdviceBlockedRendering pins the exact blocked-verdict text
// so the fmt.Sprint -> strconv.Itoa swap cannot drift the output.
func TestQUICAdviceBlockedRendering(t *testing.T) {
	r := &QUICResult{Verdict: VerdictBlocked, LocalPort: 45678}
	want := "QUIC is dropped on this path while TCP answers: do not retry QUIC from UDP source port " +
		"45678 for 420s (the ban self-renews); rotate the source port for the next attempt, " +
		"and measure TCP quality before falling back to it."
	if got := r.Advice(); got != want {
		t.Fatalf("Advice() = %q, want %q", got, want)
	}
}
