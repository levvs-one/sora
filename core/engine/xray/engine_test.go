package xray

import (
	"net/http"
	"testing"
)

// TestMetricsBypassTheProxy: the loopback metrics client must
// not honor HTTP_PROXY from the environment.
func TestMetricsBypassTheProxy(t *testing.T) {
	t.Setenv("HTTP_PROXY", "http://proxy.example:8080")
	t.Setenv("HTTPS_PROXY", "http://proxy.example:8080")
	t.Setenv("NO_PROXY", "")
	transport, ok := metricsClient.Transport.(*http.Transport)
	if !ok {
		t.Fatalf("metrics client transport is %T, want *http.Transport", metricsClient.Transport)
	}
	if transport.Proxy != nil {
		req, err := http.NewRequestWithContext(t.Context(), http.MethodGet, "http://127.0.0.1:12345/debug/vars", nil)
		if err != nil {
			t.Fatal(err)
		}
		proxyURL, err := transport.Proxy(req)
		if err != nil {
			t.Fatalf("Proxy() error = %v", err)
		}
		if proxyURL != nil {
			t.Errorf("metrics request would use proxy %v", proxyURL)
		}
	}
	// A nil Proxy func means direct connections.
}
