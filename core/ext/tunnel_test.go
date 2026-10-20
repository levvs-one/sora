package ext

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
)

var _ = net.IPv4len // documented: net is used by the test server helpers

// fakeProxy is a minimal forward HTTP proxy for tests: it forwards the
// absolute-URI request to the target, stamps a header so the origin can
// prove the request arrived through the proxy, and counts requests.
type fakeProxy struct {
	t        *testing.T
	srv      *httptest.Server
	requests atomic.Int64
}

func newFakeProxy(t *testing.T) *fakeProxy {
	t.Helper()
	p := &fakeProxy{t: t}
	p.srv = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		p.requests.Add(1)
		if !r.URL.IsAbs() {
			http.Error(w, "proxy needs an absolute URI", http.StatusBadRequest)
			return
		}
		out, err := http.NewRequestWithContext(context.Background(), r.Method, r.URL.String(), r.Body)
		if err != nil {
			http.Error(w, "bad request", http.StatusBadRequest)
			return
		}
		out.Header.Set("X-Via-Ext-Test", "tunnel")
		for k, vv := range r.Header {
			if k == "X-Via-Ext-Test" {
				continue
			}
			out.Header[k] = vv
		}
		resp, err := http.DefaultTransport.RoundTrip(out)
		if err != nil {
			http.Error(w, "forward failed", http.StatusBadGateway)
			return
		}
		defer func() { _ = resp.Body.Close() }()
		for k, vv := range resp.Header {
			w.Header()[k] = vv
		}
		w.WriteHeader(resp.StatusCode)
		_, _ = io.Copy(w, resp.Body)
	}))
	t.Cleanup(p.srv.Close)
	return p
}

func proxyAddr(s *httptest.Server) string {
	return strings.TrimPrefix(s.URL, "http://")
}

// TestProxyRoundTripperRoutesThroughProxy proves the e2e property the
// whole mechanism exists for: with a tunnel proxy address, the request
// reaches the origin THROUGH the proxy (the origin sees the stamp), and
// the proxy observed the request.
func TestProxyRoundTripperRoutesThroughProxy(t *testing.T) {
	origin := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("X-Via-Ext-Test") != "tunnel" {
			http.Error(w, "did not arrive through the proxy", http.StatusTeapot)
			return
		}
		_, _ = fmt.Fprint(w, "hello")
	}))
	t.Cleanup(origin.Close)
	proxy := newFakeProxy(t)

	rt, err := ProxyRoundTripper(proxyAddr(proxy.srv))
	if err != nil {
		t.Fatalf("ProxyRoundTripper: %v", err)
	}
	resp, err := rt.RoundTrip(mustReq(t, "GET", origin.URL))
	if err != nil {
		t.Fatalf("RoundTrip: %v", err)
	}
	defer func() { _ = resp.Body.Close() }()
	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK || string(body) != "hello" {
		t.Fatalf("got %d %q", resp.StatusCode, body)
	}
	if n := proxy.requests.Load(); n != 1 {
		t.Fatalf("proxy saw %d requests, want 1", n)
	}
}

// TestProxyRoundTripperRejectsNonLoopback is the anti-miswire pin: an
// extension fetch must never be handed to a remote proxy.
func TestProxyRoundTripperRejectsNonLoopback(t *testing.T) {
	for _, addr := range []string{"203.0.113.7:8080", "example.com:8080", "10.0.0.1:1080", "[::1", ":8080"} {
		if _, err := ProxyRoundTripper(addr); err == nil {
			t.Errorf("ProxyRoundTripper(%q) accepted a non-loopback address", addr)
		}
	}
	for _, addr := range []string{"127.0.0.1:8080", "127.0.0.2:1080", "[::1]:7890"} {
		if _, err := ProxyRoundTripper(addr); err != nil {
			t.Errorf("ProxyRoundTripper(%q) rejected a loopback address: %v", addr, err)
		}
	}
}

// TestTunnelTransportFailsClosedWhenNoTunnel is the leak guard: with no
// tunnel proxy available the request is refused, not dialed direct.
func TestTunnelTransportFailsClosedWhenNoTunnel(t *testing.T) {
	tr := &TunnelTransport{Lookup: func() (string, bool) { return "", false }}
	resp, err := tr.RoundTrip(mustReq(t, "GET", "https://example.com/"))
	if resp != nil {
		_ = resp.Body.Close()
	}
	if err == nil {
		t.Fatal("RoundTrip succeeded without a tunnel proxy")
	}
	if !isNoTunnel(err) {
		t.Fatalf("error is not the no-tunnel fail-closed error: %v", err)
	}
	if k := errKey(t, err); k != KeyNetFetchNoTunnel {
		t.Fatalf("error key = %q, want %q", k, KeyNetFetchNoTunnel)
	}
}

// TestTunnelTransportReResolvesOnEveryRoundTrip proves the lookup is live:
// the session can change underneath, and the transport follows without
// being rebuilt.
func TestTunnelTransportReResolvesOnEveryRoundTrip(t *testing.T) {
	hit := func(name string) (*httptest.Server, *atomic.Int64) {
		var n atomic.Int64
		s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			n.Add(1)
			_, _ = fmt.Fprint(w, name)
		}))
		t.Cleanup(s.Close)
		return s, &n
	}
	one, n1 := hit("one")
	two, n2 := hit("two")
	proxies := []*fakeProxy{newFakeProxy(t), newFakeProxy(t)}
	current := atomic.Int64{} // index into proxies

	tr := &TunnelTransport{Lookup: func() (string, bool) {
		return proxyAddr(proxies[current.Load()].srv), true
	}}
	fetch := func(want string) {
		t.Helper()
		target := one
		if want == "two" {
			target = two
		}
		resp, err := tr.RoundTrip(mustReq(t, "GET", target.URL))
		if err != nil {
			t.Fatalf("RoundTrip: %v", err)
		}
		defer func() { _ = resp.Body.Close() }()
		body, _ := io.ReadAll(resp.Body)
		if string(body) != want {
			t.Fatalf("got %q, want %q", body, want)
		}
	}
	fetch("one")
	if got := n1.Load(); got != 1 {
		t.Fatalf("origin one saw %d requests, want 1", got)
	}
	current.Store(1) // the session moved: a different tunnel proxy
	fetch("two")
	if got := n2.Load(); got != 1 {
		t.Fatalf("origin two saw %d requests, want 1", got)
	}
}

// TestFetcherFailsClosedWithoutTunnel wires the mechanism into the
// production path: an extension Fetcher built on a TunnelTransport whose
// lookup reports no tunnel refuses the fetch with the honest key instead
// of dialing direct.
func TestFetcherFailsClosedWithoutTunnel(t *testing.T) {
	hub := NewLogHub()
	f, err := NewFetcherForExtensionWithTransport("com.example.hello",
		&ManifestExt{NetworkHosts: []string{"example.com"}},
		FetchLimits{},
		&TunnelTransport{Lookup: func() (string, bool) { return "", false }},
		hub)
	if err != nil {
		t.Fatalf("NewFetcherForExtensionWithTransport: %v", err)
	}
	_, err = f.Fetch(t.Context(), FetchRequest{Method: "GET", URL: "https://example.com/api"})
	if err == nil {
		t.Fatal("Fetch succeeded without a tunnel proxy")
	}
	if k := errKey(t, err); k != KeyNetFetchNoTunnel {
		t.Fatalf("error key = %q, want %q", k, KeyNetFetchNoTunnel)
	}
	// The denial is part of the audit trail, like every other refused fetch.
	if got := f.Stats().Denied; got != 1 {
		t.Fatalf("denied stats = %d, want 1", got)
	}
}

func mustReq(t *testing.T, method, rawURL string) *http.Request {
	t.Helper()
	req, err := http.NewRequestWithContext(context.Background(), method, rawURL, nil)
	if err != nil {
		t.Fatalf("NewRequest: %v", err)
	}
	return req
}
