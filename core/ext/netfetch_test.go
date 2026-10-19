package ext

import (
	"context"
	"crypto/tls"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
)

// testTransport returns an *http.Transport that sends every connection to the
// test TLS server, skipping certificate verification (test-only).
func testTransport(t *testing.T, srv *httptest.Server) *http.Transport {
	t.Helper()
	u, err := url.Parse(srv.URL)
	if err != nil {
		t.Fatal(err)
	}
	_, port, err := net.SplitHostPort(u.Host)
	if err != nil {
		t.Fatal(err)
	}
	return &http.Transport{
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			return (&net.Dialer{}).DialContext(ctx, network, net.JoinHostPort("127.0.0.1", port))
		},
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, // test-only
	}
}

// testFetcher builds a Fetcher whose transport is rewired to srv.
func testFetcher(t *testing.T, srv *httptest.Server, hosts []string, limits FetchLimits) *Fetcher {
	t.Helper()
	hub := NewLogHub()
	f, err := NewFetcherForExtension("com.example.hello", &ManifestExt{NetworkHosts: hosts}, limits, hub)
	if err != nil {
		t.Fatal(err)
	}
	f.client.Transport = testTransport(t, srv)
	return f
}

func TestFetchAllowedExactHost(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("pong"))
	}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"api.example.com"}, FetchLimits{})

	resp, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://api.example.com/ping"})
	if err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	if resp.Status != 200 || string(resp.Body) != "pong" {
		t.Fatalf("bad response: %+v", resp)
	}
	if n := f.hub.Log("com.example.hello").Len(); n == 0 {
		t.Fatal("allowed fetch must be logged")
	}
}

func TestFetchDeniedHostNotAllowlisted(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("server must not be hit for a denied host")
	}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"api.example.com"}, FetchLimits{})

	_, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://evil.example.net/steal"})
	if err == nil {
		t.Fatal("fetch to a non-allowlisted host must be denied")
	}
	if codeOf(t, err) != errs.CodePermissionDenied {
		t.Fatalf("want permission_denied, got %v", err)
	}
}

func TestFetchSubdomainStrictByDefault(t *testing.T) {
	hits := 0
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hits++
	}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"example.com"}, FetchLimits{})

	// Exact host is allowed.
	if _, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://example.com/"}); err != nil {
		t.Fatalf("exact host must be allowed: %v", err)
	}
	// Subdomain of an exact entry is NOT allowed (strict match).
	if _, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://sub.example.com/"}); err == nil {
		t.Fatal("subdomain of an exact allowlist entry must be denied")
	}
	if hits != 1 {
		t.Fatalf("server hit %d times, want exactly the 1 allowed request", hits)
	}
}

func TestFetchWildcard(t *testing.T) {
	hit := 0
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hit++
		w.Write([]byte("ok"))
	}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"*.example.com"}, FetchLimits{})

	// Subdomain matches.
	if _, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://a.b.example.com/x"}); err != nil {
		t.Fatalf("wildcard must match subdomains: %v", err)
	}
	// Bare domain does NOT match the wildcard.
	if _, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://example.com/"}); err == nil {
		t.Fatal("wildcard must not match the bare domain")
	}
	// Suffix trick: evilexample.com is not a subdomain.
	if _, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://evilexample.com/"}); err == nil {
		t.Fatal("wildcard must not match a suffix lookalike")
	}
	if hit != 1 {
		t.Fatalf("server hit %d times, want 1", hit)
	}
}

func TestFetchRejectsBadURLs(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("server must not be hit")
	}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"example.com"}, FetchLimits{})

	for _, raw := range []string{
		"http://example.com/",              // not https
		"https://user:pass@example.com/",   // userinfo
		"https://127.0.0.1/",               // IP literal
		"https://[::1]/",                   // IPv6 literal
		"https://example.com:8443/",        // explicit port
		"ftp://example.com/",               // wrong scheme
		"https://sub.example.com.evil.com", // lookalike
	} {
		if _, err := f.Fetch(context.Background(),
			FetchRequest{URL: raw}); err == nil {
			t.Fatalf("URL %q must be rejected", raw)
		}
	}
}

func TestFetchRedirectRechecked(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/hop":
			http.Redirect(w, r, "https://notallowed.test/final", http.StatusFound)
		case "/ok-hop":
			http.Redirect(w, r, "https://api.example.com/final", http.StatusFound)
		default:
			w.Write([]byte("final"))
		}
	}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"api.example.com"}, FetchLimits{})

	// Redirect off the allowlist is denied (and never followed).
	if _, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://api.example.com/hop"}); err == nil {
		t.Fatal("redirect to a non-allowlisted host must be denied")
	} else if codeOf(t, err) != errs.CodePermissionDenied {
		t.Fatalf("want permission_denied, got %v", err)
	}
	// Redirect staying on the allowlist works.
	resp, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://api.example.com/ok-hop"})
	if err != nil {
		t.Fatalf("on-allowlist redirect must work: %v", err)
	}
	if string(resp.Body) != "final" {
		t.Fatalf("bad body: %q", resp.Body)
	}
}

func TestFetchResponseSizeLimit(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(strings.Repeat("x", 1024)))
	}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"api.example.com"}, FetchLimits{MaxResponseBody: 16})

	if _, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://api.example.com/big"}); err == nil {
		t.Fatal("oversized response must be rejected")
	} else if codeOf(t, err) != errs.CodeResourceExhausted {
		t.Fatalf("want resource_exhausted, got %v", err)
	}
}

func TestFetchRequestBodyLimit(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"api.example.com"}, FetchLimits{MaxRequestBody: 8})

	_, err := f.Fetch(context.Background(),
		FetchRequest{Method: "POST", URL: "https://api.example.com/", Body: []byte("way too long")})
	if err == nil {
		t.Fatal("oversized request body must be rejected")
	}
}

func TestFetchRateLimit(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok"))
	}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"api.example.com"},
		FetchLimits{RatePerMinute: 600, RateBurst: 2})

	for i := 0; i < 2; i++ {
		if _, err := f.Fetch(context.Background(),
			FetchRequest{URL: "https://api.example.com/"}); err != nil {
			t.Fatalf("burst request %d: %v", i, err)
		}
	}
	if _, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://api.example.com/"}); err == nil {
		t.Fatal("request over the burst must be rate-limited")
	} else if codeOf(t, err) != errs.CodeResourceExhausted {
		t.Fatalf("want resource_exhausted, got %v", err)
	}
}

func TestFetchDeniedIsLogged(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	defer srv.Close()
	hub := NewLogHub()
	f, err := NewFetcherForExtension("com.example.hello",
		&ManifestExt{NetworkHosts: []string{"api.example.com"}}, FetchLimits{}, hub)
	if err != nil {
		t.Fatal(err)
	}
	f.client.Transport = testTransport(t, srv)

	_, _ = f.Fetch(context.Background(),
		FetchRequest{URL: "https://evil.test/"})
	entries := hub.Log("com.example.hello").Entries()
	if len(entries) == 0 {
		t.Fatal("denied fetch must be logged")
	}
	found := false
	for _, e := range entries {
		if strings.Contains(e.Message, "DENIED") && e.Level == LogWarn {
			found = true
		}
	}
	if !found {
		t.Fatalf("no DENIED warn entry in %v", entries)
	}
}

func TestNewFetcherRejectsBadAllowlist(t *testing.T) {
	hub := NewLogHub()
	if _, err := NewFetcherForExtension("com.example.hello",
		&ManifestExt{NetworkHosts: []string{"http://x"}}, FetchLimits{}, hub); err == nil {
		t.Fatal("bad allowlist entry must fail construction")
	}
	if _, err := NewFetcherForExtension("", nil, FetchLimits{}, hub); err == nil {
		t.Fatal("empty extension id must fail construction")
	}
	if _, err := NewFetcherForExtension("x", nil, FetchLimits{}, nil); err == nil {
		t.Fatal("nil hub must fail construction")
	}
}

func TestFetchQueryNotLogged(t *testing.T) {
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("ok"))
	}))
	defer srv.Close()
	hub := NewLogHub()
	f, err := NewFetcherForExtension("com.example.hello",
		&ManifestExt{NetworkHosts: []string{"api.example.com"}}, FetchLimits{}, hub)
	if err != nil {
		t.Fatal(err)
	}
	f.client.Transport = testTransport(t, srv)

	// Allowed request carrying secrets in the query: the audit log must not
	// retain them.
	if _, err := f.Fetch(context.Background(),
		FetchRequest{URL: "https://api.example.com/data?api_key=topsecret&token=abc123"}); err != nil {
		t.Fatalf("Fetch: %v", err)
	}
	// Denied request with a secret query: same rule.
	_, _ = f.Fetch(context.Background(),
		FetchRequest{URL: "https://evil.test/x?api_key=topsecret"})
	for _, e := range hub.Log("com.example.hello").Entries() {
		if strings.Contains(e.Message, "topsecret") || strings.Contains(e.Message, "abc123") {
			t.Fatalf("secret query leaked into log: %q", e.Message)
		}
	}
}

func TestFetchRejectsIPLikeHosts(t *testing.T) {
	// Non-standard IP notations: net.ParseIP misses them, but some system
	// resolvers (cgo/glibc inet_aton) still dial them as IPs.
	for _, h := range []string{"2130706433", "0x7f000001", "017700000001", "0x7f.1", "127.1"} {
		if _, err := normalizeHostPattern(h); err == nil {
			t.Errorf("normalizeHostPattern(%q) must reject IP-like host", h)
		}
	}
	srv := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("server must not be hit")
	}))
	defer srv.Close()
	f := testFetcher(t, srv, []string{"example.com"}, FetchLimits{})
	for _, raw := range []string{
		"https://2130706433/",
		"https://0x7f000001/",
	} {
		u, err := url.Parse(raw)
		if err != nil {
			t.Fatal(err)
		}
		if err := f.checkURL(u); err == nil {
			t.Errorf("checkURL(%q) must reject IP-like host", raw)
		}
	}
}
