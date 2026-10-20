package subscription_test

import (
	"context"
	"net/http"
	"strings"
	"sync"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/subscription"
)

// capture records the device headers of every request it answers.
type capture struct {
	mu   sync.Mutex
	seen []http.Header
}

func (c *capture) handler(status int) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		c.mu.Lock()
		c.seen = append(c.seen, r.Header.Clone())
		c.mu.Unlock()
		if status != http.StatusOK {
			w.WriteHeader(status)
			return
		}
		_, _ = w.Write([]byte(body))
	}
}

func (c *capture) all() []http.Header {
	c.mu.Lock()
	defer c.mu.Unlock()
	return append([]http.Header(nil), c.seen...)
}

var testDevice = subscription.DeviceHeaders{
	HWID:        "123e4567-e89b-42d3-a456-426614174000",
	DeviceOS:    "Linux",
	VersionOS:   "6.8",
	DeviceModel: "Testbox 3000",
}

// (а) A fetch with the identity enabled carries x-hwid and its
// companions, and the value is stable between two fetches.
func TestFetchCarriesDeviceHeadersStably(t *testing.T) {
	cap := &capture{}
	fetcher, url := newServer(t, cap.handler(http.StatusOK))
	for i := 0; i < 2; i++ {
		if _, err := fetcher.Fetch(context.Background(), url, subscription.FetchOptions{Device: testDevice}); err != nil {
			t.Fatalf("Fetch() error = %v", err)
		}
	}
	seen := cap.all()
	if len(seen) != 2 {
		t.Fatalf("requests = %d, want 2", len(seen))
	}
	for i, h := range seen {
		if got := h.Get("x-hwid"); got != testDevice.HWID {
			t.Errorf("request %d: x-hwid = %q, want the stable identity", i, got)
		}
		if got := h.Get("x-device-os"); got != "Linux" {
			t.Errorf("request %d: x-device-os = %q", i, got)
		}
		if got := h.Get("x-ver-os"); got != "6.8" {
			t.Errorf("request %d: x-ver-os = %q", i, got)
		}
		if got := h.Get("x-device-model"); got != "Testbox 3000" {
			t.Errorf("request %d: x-device-model = %q", i, got)
		}
	}
}

// The identity rides every redirect hop, like the User-Agent: a
// provider that redirects first must still see it at the final hop.
func TestFetchCarriesDeviceHeadersAcrossRedirects(t *testing.T) {
	finalCap := &capture{}
	_, finalURL := newServer(t, finalCap.handler(http.StatusOK))
	first, firstURL := newServer(t, func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Location", finalURL)
		w.WriteHeader(http.StatusFound)
	})
	if _, err := first.Fetch(context.Background(), firstURL, subscription.FetchOptions{Device: testDevice}); err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	seen := finalCap.all()
	if len(seen) != 1 || seen[0].Get("x-hwid") != testDevice.HWID {
		t.Errorf("final hop headers = %v, want x-hwid on the redirected request", seen)
	}
}

// (б) The zero header set (opt-out) sends no device headers at all —
// not even the companion fields alone.
func TestFetchWithoutDeviceSendsNoDeviceHeaders(t *testing.T) {
	cap := &capture{}
	fetcher, url := newServer(t, cap.handler(http.StatusOK))
	if _, err := fetcher.Fetch(context.Background(), url, subscription.FetchOptions{}); err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	// A set carrying companions but no HWID collapses to nothing too.
	if _, err := fetcher.Fetch(context.Background(), url, subscription.FetchOptions{
		Device: subscription.DeviceHeaders{DeviceOS: "Linux"},
	}); err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	for i, h := range cap.all() {
		for _, name := range []string{"x-hwid", "x-device-os", "x-ver-os", "x-device-model"} {
			if got := h.Get(name); got != "" {
				t.Errorf("request %d: %s = %q, want absent", i, name, got)
			}
		}
	}
}

// (г) The fallback fetch carries the same identity as the primary.
func TestFallbackFetchCarriesDeviceHeaders(t *testing.T) {
	primaryCap, fallbackCap := &capture{}, &capture{}
	primary, primaryURL := newServer(t, primaryCap.handler(http.StatusForbidden))
	backup, backupURL := newServer(t, fallbackCap.handler(http.StatusOK))
	_ = primary
	_ = backup
	got, err := primary.Fetch(context.Background(), primaryURL, subscription.FetchOptions{
		Device:      testDevice,
		FallbackURL: backupURL,
	})
	if err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	if !got.UsedFallback {
		t.Fatal("UsedFallback = false, want the fallback body")
	}
	for name, cap := range map[string]*capture{"primary": primaryCap, "fallback": fallbackCap} {
		seen := cap.all()
		if len(seen) != 1 || seen[0].Get("x-hwid") != testDevice.HWID {
			t.Errorf("%s request headers = %v, want x-hwid present", name, seen)
		}
	}
}

// (д) A failed fetch never leaks the identity into its error: not in
// the detail, not in the rendered error.
func TestFetchErrorNeverContainsTheHWID(t *testing.T) {
	cap := &capture{}
	fetcher, url := newServer(t, cap.handler(http.StatusInternalServerError))
	_, err := fetcher.Fetch(context.Background(), url, subscription.FetchOptions{Device: testDevice})
	if err == nil {
		t.Fatal("Fetch() succeeded against a 500 provider")
	}
	if strings.Contains(errs.Detail(err), testDevice.HWID) || strings.Contains(err.Error(), testDevice.HWID) {
		t.Errorf("fetch error leaks the device identifier: %v", err)
	}
}

// A malformed HWID is refused before any request is made, and the
// refusal does not echo the value back.
func TestFetchRefusesAMalformedHWIDBeforeRequesting(t *testing.T) {
	cap := &capture{}
	fetcher, url := newServer(t, cap.handler(http.StatusOK))
	bad := subscription.DeviceHeaders{HWID: "bad hwid!\nwith newline"}
	_, err := fetcher.Fetch(context.Background(), url, subscription.FetchOptions{Device: bad})
	if err == nil {
		t.Fatal("Fetch() accepted a malformed device identifier")
	}
	if strings.Contains(err.Error(), "bad hwid") {
		t.Errorf("the refusal echoes the identifier: %v", err)
	}
	if len(cap.all()) != 0 {
		t.Error("a request went out despite the malformed identifier")
	}
}

// The store: identity is generated once, survives a reopen, the
// opt-out hides it completely, and a reset replaces it.
func TestDeviceStoreLifecycle(t *testing.T) {
	dir := t.TempDir()
	store := subscription.NewDeviceStore(dir)

	first, err := store.Headers("Linux")
	if err != nil {
		t.Fatalf("Headers() error = %v", err)
	}
	if !subscription.ValidHWID(first.HWID) {
		t.Fatalf("generated HWID %q is outside the shape providers accept", first.HWID)
	}
	if first.DeviceOS != "Linux" {
		t.Errorf("DeviceOS = %q", first.DeviceOS)
	}

	// A fresh store on the same directory sees the same identity:
	// the value survives restarts.
	reopened := subscription.NewDeviceStore(dir)
	again, err := reopened.Headers("Linux")
	if err != nil {
		t.Fatalf("Headers() after reopen error = %v", err)
	}
	if again.HWID != first.HWID {
		t.Errorf("HWID changed across restarts: %q -> %q", first.HWID, again.HWID)
	}

	// (б) Opt-out: the header set collapses to zero.
	if err := reopened.SetEnabled(false); err != nil {
		t.Fatalf("SetEnabled(false) error = %v", err)
	}
	off, err := reopened.Headers("Linux")
	if err != nil {
		t.Fatalf("Headers() while disabled error = %v", err)
	}
	if off != (subscription.DeviceHeaders{}) {
		t.Errorf("Headers() while disabled = %+v, want the zero set", off)
	}
	// The identity itself is still there when the user re-enables.
	if err := reopened.SetEnabled(true); err != nil {
		t.Fatalf("SetEnabled(true) error = %v", err)
	}
	back, err := reopened.Headers("Linux")
	if err != nil || back.HWID != first.HWID {
		t.Errorf("Headers() after re-enable = %+v, %v; want the original HWID", back, err)
	}

	// (в) Reset: a new, valid, different identifier, persisted.
	fresh, err := reopened.Reset()
	if err != nil {
		t.Fatalf("Reset() error = %v", err)
	}
	if fresh == first.HWID || !subscription.ValidHWID(fresh) {
		t.Errorf("Reset() = %q, want a new valid identifier", fresh)
	}
	after, err := subscription.NewDeviceStore(dir).Headers("Linux")
	if err != nil || after.HWID != fresh {
		t.Errorf("Headers() after reset = %+v, %v; want the reset value", after, err)
	}
}

// A nil store (no data directory) disables the identity quietly.
func TestDeviceStoreNilIsDisabled(t *testing.T) {
	var store *subscription.DeviceStore
	got, err := store.Headers("Linux")
	if err != nil || got != (subscription.DeviceHeaders{}) {
		t.Errorf("nil store Headers() = %+v, %v; want zero, nil", got, err)
	}
	if subscription.NewDeviceStore("") != nil {
		t.Error("NewDeviceStore(\"\") != nil, want nil (identity disabled)")
	}
}
