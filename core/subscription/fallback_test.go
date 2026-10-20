package subscription_test

import (
	"context"
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/subscription"
)

const fallbackBody = "vless://22222222-2222-4222-8222-222222222222@backup.example.com:443?security=tls#Backup"

// fallbackFetcher returns a fetcher trusting every test server in this
// file. Each test spins up real TLS providers so the fallback path runs
// the production hop and redirect logic, not a stub of it.
func fallbackFetcher(t *testing.T, opts subscription.Options) *subscription.Fetcher {
	t.Helper()
	opts.HTTPClient = &http.Client{
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Transport: &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}, //nolint:gosec // test servers with self signed certificates
	}
	if opts.Timeout <= 0 {
		opts.Timeout = 2 * time.Second
	}
	return subscription.New(opts)
}

func countingServer(t *testing.T, hits *atomic.Int32, handler http.HandlerFunc) *httptest.Server {
	t.Helper()
	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hits.Add(1)
		if strings.Contains(r.RequestURI, "#") || strings.Contains(r.RequestURI, "fallback-url") {
			t.Errorf("the fragment reached the server in the request URI %q", r.RequestURI)
		}
		handler(w, r)
	}))
	t.Cleanup(server.Close)
	return server
}

func TestFallbackIsNotTouchedWhenThePrimaryAnswers(t *testing.T) {
	var primaryHits, fallbackHits atomic.Int32
	primary := countingServer(t, &primaryHits, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(body))
	})
	backup := countingServer(t, &fallbackHits, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(fallbackBody))
	})
	fetcher := fallbackFetcher(t, subscription.Options{})
	reference := primary.URL + "/sub?token=primary#fallback-url=" + backup.URL + "/sub?token=backup"
	got, err := fetcher.Fetch(context.Background(), reference, subscription.FetchOptions{})
	if err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	if string(got.Body) != body || got.UsedFallback {
		t.Errorf("Fetch() = %q, UsedFallback = %v, want the primary body unmarked", got.Body, got.UsedFallback)
	}
	if primaryHits.Load() != 1 || fallbackHits.Load() != 0 {
		t.Errorf("hits = primary %d, fallback %d, want 1 and 0", primaryHits.Load(), fallbackHits.Load())
	}
}

func TestFallbackAnswersWhenThePrimaryFails(t *testing.T) {
	for name, fail := range map[string]http.HandlerFunc{
		"status 500": func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusInternalServerError) },
		"status 403": func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusForbidden) },
		"empty body": func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) },
	} {
		t.Run(name, func(t *testing.T) {
			var fallbackHits atomic.Int32
			primary := httptest.NewTLSServer(fail)
			t.Cleanup(primary.Close)
			backup := countingServer(t, &fallbackHits, func(w http.ResponseWriter, _ *http.Request) {
				_, _ = w.Write([]byte(fallbackBody))
			})
			fetcher := fallbackFetcher(t, subscription.Options{})
			reference := primary.URL + "/sub?token=primary#fallback-url=" + backup.URL + "/sub?token=backup"
			got, err := fetcher.Fetch(context.Background(), reference, subscription.FetchOptions{})
			if err != nil {
				t.Fatalf("Fetch() error = %v", err)
			}
			if string(got.Body) != fallbackBody || !got.UsedFallback {
				t.Errorf("Fetch() = %q, UsedFallback = %v, want the fallback body, marked", got.Body, got.UsedFallback)
			}
			if fallbackHits.Load() != 1 {
				t.Errorf("fallback hits = %d, want 1", fallbackHits.Load())
			}
		})
	}
}

func TestFallbackAnswersWhenThePrimaryIsUnreachable(t *testing.T) {
	dead := httptest.NewTLSServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	deadURL := dead.URL
	dead.Close() // the port now refuses connections

	var fallbackHits atomic.Int32
	backup := countingServer(t, &fallbackHits, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(fallbackBody))
	})
	fetcher := fallbackFetcher(t, subscription.Options{})
	got, err := fetcher.Fetch(context.Background(), deadURL+"/sub?token=primary",
		subscription.FetchOptions{FallbackURL: backup.URL + "/sub?token=backup"})
	if err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	if string(got.Body) != fallbackBody || !got.UsedFallback {
		t.Errorf("Fetch() = %q, UsedFallback = %v, want the fallback body, marked", got.Body, got.UsedFallback)
	}
}

func TestBothDownReturnsThePrimaryError(t *testing.T) {
	primary := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusForbidden)
	}))
	defer primary.Close()
	backup := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer backup.Close()
	fetcher := fallbackFetcher(t, subscription.Options{})
	reference := primary.URL + "/sub?token=primary#fallback-url=" + backup.URL + "/sub?token=backup"
	_, err := fetcher.Fetch(context.Background(), reference, subscription.FetchOptions{})
	if errs.KeyOf(err) != errs.KeySubscriptionStatus || !strings.Contains(errs.Detail(err), "403") {
		t.Fatalf("both down = %v, want the primary's 403, not the fallback's 500", err)
	}
	for _, secret := range []string{"token=primary", "token=backup"} {
		if strings.Contains(errs.Detail(err), secret) {
			t.Errorf("the primary error leaks %q", secret)
		}
	}
}

func TestFallbackOverPlainHTTPIsRefusedLikeAPrimary(t *testing.T) {
	var primaryHits atomic.Int32
	primary := countingServer(t, &primaryHits, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(body))
	})
	fetcher := fallbackFetcher(t, subscription.Options{})
	cases := map[string]string{
		"fragment form": primary.URL + "/sub?token=primary#fallback-url=http://backup.example/sub?token=backup",
		"options form":  primary.URL + "/sub?token=primary",
	}
	for name, reference := range cases {
		opts := subscription.FetchOptions{}
		if name == "options form" {
			opts.FallbackURL = "http://backup.example/sub?token=backup"
		}
		_, err := fetcher.Fetch(context.Background(), reference, opts)
		if errs.KeyOf(err) != errs.KeySubscriptionScheme {
			t.Errorf("%s: a plain http fallback = %v, key = %q, want the scheme refusal", name, err, errs.KeyOf(err))
		}
	}
	// The refusal is fail-closed at validation, before any request.
	if primaryHits.Load() != 0 {
		t.Errorf("the primary was asked %d times despite the refused fallback", primaryHits.Load())
	}
	_, err := fetcher.Fetch(context.Background(), primary.URL+"/sub?token=primary#fallback-url=https://user:pass@backup.example/sub", subscription.FetchOptions{})
	if errs.KeyOf(err) != errs.KeySubscriptionScheme {
		t.Errorf("a fallback with credentials = %v, key = %q", err, errs.KeyOf(err))
	}
}

func TestFallbackRedirectsShareTheHopLimit(t *testing.T) {
	primary := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer primary.Close()
	var fallbackHits atomic.Int32
	backup := countingServer(t, &fallbackHits, func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/again", http.StatusFound)
	})
	fetcher := fallbackFetcher(t, subscription.Options{MaxRedirects: 2})
	reference := primary.URL + "/sub?token=primary#fallback-url=" + backup.URL + "/sub?token=backup"
	_, err := fetcher.Fetch(context.Background(), reference, subscription.FetchOptions{})
	if errs.KeyOf(err) != errs.KeySubscriptionStatus {
		t.Fatalf("primary 500 + fallback redirect loop = %v, want the primary error back", err)
	}
	if fallbackHits.Load() != 3 {
		t.Errorf("fallback hits = %d, want MaxRedirects+1 = 3: the fallback gets the same hop budget, no more", fallbackHits.Load())
	}
}

func TestFallbackFollowsItsOwnRedirect(t *testing.T) {
	primary := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
	}))
	defer primary.Close()
	final := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(fallbackBody))
	}))
	defer final.Close()
	backup := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, final.URL+"/moved", http.StatusFound)
	}))
	defer backup.Close()
	fetcher := fallbackFetcher(t, subscription.Options{})
	reference := primary.URL + "/sub?token=primary#fallback-url=" + backup.URL + "/sub?token=backup"
	got, err := fetcher.Fetch(context.Background(), reference, subscription.FetchOptions{})
	if err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	if string(got.Body) != fallbackBody || !got.UsedFallback {
		t.Errorf("Fetch() = %q, UsedFallback = %v, want the redirected fallback body, marked", got.Body, got.UsedFallback)
	}
}

func TestSplitFallbackForms(t *testing.T) {
	const primary = "https://panel.example/sub/token-a"
	const backup = "https://backup.example/sub/token-b?region=eu&fast=1"
	cases := map[string]struct {
		reference string
		primary   string
		fallback  string
	}{
		"no fragment":                 {primary, primary, ""},
		"plain name":                  {primary + "#My VPN", primary, ""},
		"raw fallback":                {primary + "#fallback-url=" + backup, primary, backup},
		"encoded fallback":            {primary + "#fallback-url=https%3A%2F%2Fbackup.example%2Fsub%2Ftoken-b%3Fregion%3Deu%26fast%3D1", primary, backup},
		"named then fallback":         {primary + "#name=Mine&fallback-url=" + backup, primary, backup},
		"marker at fragment start":    {primary + "#fallback-url=" + backup, primary, backup},
		"marker after ampersand":      {primary + "#name=Mine&lang=en&fallback-url=" + backup, primary, backup},
		"marker inside a value":       {primary + "#name=fallback-url=" + backup, primary, ""},
		"marker inside a later value": {primary + "#name=Mine&note=fallback-url=" + backup, primary, ""},
		"empty fallback":              {primary + "#fallback-url=", primary, ""},
		"fallback with own fragment":  {primary + "#fallback-url=" + backup + "#name", primary, backup},
		// The fallback may be the primary itself: nothing in the form
		// forbids it, and the fetcher then simply retries the same
		// reference through the fallback hop.
		"fallback equals primary": {primary + "#fallback-url=" + primary, primary, primary},
		// Two markers: the FIRST boundary marker wins and everything
		// after it is its value, so the second marker's text rides
		// inside the first fallback's path instead of replacing it.
		"two markers, first wins": {
			primary + "#fallback-url=https://one.example/sub/a&fallback-url=https://two.example/sub/b",
			primary, "https://one.example/sub/a&fallback-url=https://two.example/sub/b",
		},
		// A primary with no fragment at all, plus a bare '#': the
		// empty fragment declares nothing and the reference is kept
		// byte-for-byte (the '#' is not stripped on this path).
		"bare hash only": {primary + "#", primary + "#", ""},
	}
	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			gotPrimary, gotFallback, err := subscription.SplitFallback(tc.reference)
			if err != nil {
				t.Fatalf("SplitFallback() error = %v", err)
			}
			if gotPrimary != tc.primary || gotFallback != tc.fallback {
				t.Errorf("SplitFallback() = (%q, %q), want (%q, %q)", gotPrimary, gotFallback, tc.primary, tc.fallback)
			}
		})
	}
	if _, _, err := subscription.SplitFallback(primary + "#fallback-url=http://backup.example/sub"); err == nil {
		t.Error("SplitFallback must refuse a plain http fallback")
	}
	// An empty marker value followed by '&' is NOT the empty-fallback
	// case: the marker owns the rest of the fragment, so the value is
	// "&name=Mine" — not a URL at all — and the split refuses with the
	// scheme key instead of silently dropping the declaration.
	if _, _, err := subscription.SplitFallback(primary + "#fallback-url=&name=Mine"); err == nil {
		t.Error("SplitFallback must refuse an empty marker value followed by more parameters")
	} else if errs.KeyOf(err) != errs.KeySubscriptionScheme {
		t.Errorf("empty marker before &: key = %q, want %q (err = %v)", errs.KeyOf(err), errs.KeySubscriptionScheme, err)
	}
	joined := subscription.JoinFallback(primary, backup)
	gotPrimary, gotFallback, err := subscription.SplitFallback(joined)
	if err != nil || gotPrimary != primary || gotFallback != backup {
		t.Errorf("JoinFallback round trip = (%q, %q, %v)", gotPrimary, gotFallback, err)
	}
}
