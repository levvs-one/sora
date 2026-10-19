package subscription

// Redirects interact with the dial policy: an internet subscription must
// never be led into private address space, while a subscription that
// started on a private IP literal may follow local redirects.

import (
	"context"
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// dialingClient injects a test client that still enforces the production
// dial policy, unlike the plain test clients elsewhere.
func dialingClient() *http.Client {
	return &http.Client{
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, //nolint:gosec // a self signed test certificate
			DialContext:     dialChecked,
		},
	}
}

func TestFetchRefusesARedirectIntoPrivateAddresses(t *testing.T) {
	local := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte("must never arrive"))
	}))
	defer local.Close()
	// "localhost" is not an IP literal, so the subscription counts as an
	// internet one even though the test server listens locally.
	internet := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, local.URL+"/", http.StatusFound)
	}))
	defer internet.Close()
	reference := "https://localhost" + strings.TrimPrefix(internet.URL, "https://127.0.0.1") + "/sub"

	fetcher := New(Options{HTTPClient: dialingClient(), Timeout: 5 * time.Second})
	_, err := fetcher.Fetch(context.Background(), reference, FetchOptions{})
	if errs.KeyOf(err) != errs.KeySubscriptionRedirect {
		t.Fatalf("a redirect to a private address = %v, key = %q", err, errs.KeyOf(err))
	}
	if errs.Retryable(err) {
		t.Error("a redirect into private space will not heal by retrying")
	}
}

func TestFetchFollowsALocalRedirectFromAPrivateLiteral(t *testing.T) {
	target := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte("local-body"))
	}))
	defer target.Close()
	source := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, target.URL+"/", http.StatusFound)
	}))
	defer source.Close()

	// Both test servers listen on 127.0.0.1, a private IP literal, so the
	// dial policy permits the redirect.
	fetcher := New(Options{HTTPClient: dialingClient(), Timeout: 5 * time.Second})
	got, err := fetcher.Fetch(context.Background(), source.URL+"/sub", FetchOptions{})
	if err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	if string(got.Body) != "local-body" {
		t.Errorf("Fetch() = %q, want the redirected body", got.Body)
	}
}
