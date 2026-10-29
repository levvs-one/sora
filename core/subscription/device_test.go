package subscription_test

import (
	"context"
	"encoding/base64"
	"net/http"
	"net/http/httptest"
	"regexp"
	"sync"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/hwid"
	"github.com/levvs-one/sora-client/core/subscription"
)

// remnawave reproduces the device limit of remnawave/backend 3.4.7
// (subscription.service.ts, checkHwidDeviceLimit): a refused device gets 200
// with an empty body and marker headers, never an HTTP error.
type remnawave struct {
	limit int
	mu    sync.Mutex
	known map[string]bool
}

var remnawaveHWID = regexp.MustCompile(`^[a-zA-Z0-9=-]{10,64}$`)

func (p *remnawave) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	refuse := func(marker string) {
		w.Header().Set("subscription-userinfo", "upload=0; download=0; total=0; expire=0")
		w.Header().Set("x-hwid-active", "true")
		w.Header().Set(marker, "true")
		w.Header().Set("x-hwid-limit", "true")
		if marker == "x-hwid-max-devices-reached" {
			w.Header().Set("announce", "base64:"+base64.StdEncoding.EncodeToString([]byte("Лимит устройств")))
		}
		w.Header().Set("Content-Type", "text/plain")
		w.WriteHeader(http.StatusOK)
	}
	id := r.Header.Get("x-hwid")
	if !remnawaveHWID.MatchString(id) {
		refuse("x-hwid-not-supported")
		return
	}
	p.mu.Lock()
	allowed := p.known[id] || len(p.known) < p.limit
	if allowed {
		p.known[id] = true
	}
	p.mu.Unlock()
	if !allowed {
		refuse("x-hwid-max-devices-reached")
		return
	}
	_, _ = w.Write([]byte(body))
}

func device(id string) *hwid.Identity {
	identity := hwid.For(id)
	return &identity
}

func TestARemnawaveLimitAdmitsKnownDevicesAndNamesTheRefusal(t *testing.T) {
	panel := &remnawave{limit: 1, known: map[string]bool{}}
	fetcher, url := newServer(t, panel.ServeHTTP)
	ctx := context.Background()

	_, err := fetcher.Fetch(ctx, url, subscription.FetchOptions{})
	if errs.KeyOf(err) != errs.KeySubscriptionDeviceRequired {
		t.Fatalf("without an identifier = %v, key %q", err, errs.KeyOf(err))
	}
	first := device("0123456789abcdef0123456789abcdef")
	for range 2 {
		got, err := fetcher.Fetch(ctx, url, subscription.FetchOptions{Device: first})
		if err != nil || string(got.Body) != body {
			t.Fatalf("the counted device = %q, %v", got.Body, err)
		}
	}
	_, err = fetcher.Fetch(ctx, url, subscription.FetchOptions{Device: device("fedcba9876543210fedcba9876543210")})
	if errs.KeyOf(err) != errs.KeySubscriptionDeviceLimit {
		t.Fatalf("a second device past the limit = %v, key %q", err, errs.KeyOf(err))
	}
	if errs.Retryable(err) {
		t.Error("the panel keeps refusing until a device is removed, so retrying hides the cause")
	}
}

func TestDeviceHeadersFollowRedirectsAndStayOffWhenNotAsked(t *testing.T) {
	var mu sync.Mutex
	seen := map[string]string{}
	final := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		seen["final"] = r.Header.Get("x-hwid")
		mu.Unlock()
		_, _ = w.Write([]byte(body))
	}))
	defer final.Close()
	fetcher, url := newServer(t, func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		seen["first"] = r.Header.Get("x-hwid")
		mu.Unlock()
		http.Redirect(w, r, final.URL+"/moved", http.StatusFound)
	})
	id := "0123456789abcdef0123456789abcdef"
	if _, err := fetcher.Fetch(context.Background(), url, subscription.FetchOptions{Device: device(id)}); err != nil {
		t.Fatal(err)
	}
	if seen["first"] != id || seen["final"] != id {
		t.Fatalf("x-hwid on the hops = %v", seen)
	}
	if _, err := fetcher.Fetch(context.Background(), url, subscription.FetchOptions{}); err != nil {
		t.Fatal(err)
	}
	if seen["first"] != "" || seen["final"] != "" {
		t.Fatalf("a fetch without a device sent %v", seen)
	}
}
