package probe

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

// BenchmarkDownloadGoodput measures the goodput aggregator against a
// loopback stub for 30 ms with the default pair of workers. Before the
// worker buffers were pooled, each call allocated 309 171 B/op (the
// two 128 KB read buffers were 85% of it); pooling leaves 63 008 B/op,
// the HTTP machinery's own allocations (plus the stub server's, which
// share this process).
func BenchmarkDownloadGoodput(b *testing.B) {
	payload := make([]byte, 64*1024)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Length", "1048576")
		for {
			if _, err := w.Write(payload); err != nil {
				return
			}
			if f, ok := w.(http.Flusher); ok {
				f.Flush()
			}
		}
	}))
	defer srv.Close()
	proxyAddr := strings.TrimPrefix(srv.URL, "http://")
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		bps, err := downloadGoodput(context.Background(), proxyAddr, "http://speed.cloudflare.com/__down?bytes=100000000", 30*time.Millisecond, 2, func(uint32) {})
		if err != nil {
			b.Fatal(err)
		}
		if bps == 0 {
			b.Fatal("zero bps")
		}
	}
}
