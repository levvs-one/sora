package engine

import (
	"testing"
)

var redactLines = []string{
	"2026-10-20T05:30:00Z INF [outbound] vless://node1: connected, latency 45ms",
	`2026-10-20T05:30:01Z DBG [sing-box] dns query: { "server": "1.1.1.1", "type": "https" }`,
	`2026-10-20T05:30:02Z INF [session] token: "my secret value" accepted`,
	"2026-10-20T05:30:03Z INF [tun] interface sora0 up, mtu 9000, route 0.0.0.0/0",
}

// BenchmarkRedactLines measures the per-line cost of engine-log redaction
// on typical (mostly secret-free) engine output.
func BenchmarkRedactLines(b *testing.B) {
	r := NewRedactor("supersecretpassword123")
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = r.String(redactLines[i%len(redactLines)])
	}
}
