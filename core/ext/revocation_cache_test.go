package ext

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func revocationJSONForCache(t *testing.T, expires time.Time) []byte {
	t.Helper()
	return []byte(`{"revocation_version":1,` +
		`"updated_at":"2026-10-20T00:00:00Z",` +
		`"expires_at":"` + expires.UTC().Format(time.RFC3339) + `",` +
		`"entries":[{"id":"com.evil.miner","versions":"*","reason":"cryptominer"}]}`)
}

func TestRevocationCacheRoundtrip(t *testing.T) {
	rc, err := NewRevocationCache(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := rc.Load(); ok {
		t.Fatal("empty cache must report no list")
	}
	raw := revocationJSONForCache(t, time.Now().Add(24*time.Hour))
	if err := rc.Store(raw); err != nil {
		t.Fatalf("Store: %v", err)
	}
	l, ok := rc.Load()
	if !ok {
		t.Fatal("cache roundtrip lost the list")
	}
	if !l.IsRevoked("com.evil.miner", "9.9.9") {
		t.Fatal("cached list does not revoke what it should")
	}
	if l.IsRevoked("com.good.tool", "1.0.0") {
		t.Fatal("cached list revokes an unrelated extension")
	}
}

// TestRevocationCacheRefusesUnparseable pins the "cache only ever holds
// verified good bytes" rule at the parse level: garbage is never stored.
func TestRevocationCacheRefusesUnparseable(t *testing.T) {
	rc, err := NewRevocationCache(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	for _, bad := range [][]byte{
		[]byte("not json"),
		[]byte(`{"revocation_version":99}`),
		[]byte(strings.Repeat("x", maxRevocationBytes+1)),
	} {
		if err := rc.Store(bad); err == nil {
			t.Errorf("Store accepted %q...", bad[:min(20, len(bad))])
		}
	}
	if _, ok := rc.Load(); ok {
		t.Fatal("a refused Store left a loadable cache behind")
	}
}

// TestRevocationCacheCorruptIsNoCache: a damaged cache file degrades to
// "no list" instead of breaking startup.
func TestRevocationCacheCorruptIsNoCache(t *testing.T) {
	dir := t.TempDir()
	rc, err := NewRevocationCache(dir)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, revocationCacheFile), []byte("{corrupt"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, ok := rc.Load(); ok {
		t.Fatal("corrupt cache must be treated as no cache")
	}
}

// TestRevocationRefreshFallsBackToCache: while the team key ceremony is
// pending, verification fails closed - Refresh must serve the verified
// cache instead of erroring out or (worse) trusting the download.
func TestRevocationRefreshFallsBackToCache(t *testing.T) {
	rc, err := NewRevocationCache(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	raw := revocationJSONForCache(t, time.Now().Add(24*time.Hour))
	if err := rc.Store(raw); err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write(revocationJSONForCache(t, time.Now().Add(48*time.Hour)))
	}))
	t.Cleanup(srv.Close)
	if !strings.HasPrefix(srv.URL, "http://") {
		t.Fatal("test server must be plain http for this test")
	}
	l, fromCache, err := rc.Refresh(context.Background(), srv.Client(), strings.Replace(srv.URL, "http://", "https://", 1))
	if err != nil {
		t.Fatalf("Refresh: %v", err)
	}
	if !fromCache {
		t.Fatal("Refresh must fall back to the cache while verification cannot succeed")
	}
	if !l.IsRevoked("com.evil.miner", "1.0.0") {
		t.Fatal("fallback list lost its entries")
	}
}

// TestRevocationRefreshNoCacheReturnsError: with nothing cached and the
// endpoint unreachable, the honest result is the fetch error.
func TestRevocationRefreshNoCacheReturnsError(t *testing.T) {
	rc, err := NewRevocationCache(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusTeapot)
	}))
	t.Cleanup(srv.Close)
	_, fromCache, err := rc.Refresh(context.Background(), srv.Client(), strings.Replace(srv.URL, "http://", "https://", 1))
	if err == nil {
		t.Fatal("Refresh with no cache and a broken endpoint must error")
	}
	if fromCache {
		t.Fatal("fromCache must be false when there is no cache")
	}
}

// TestApplyRevocationCacheToStore wires the whole chain end to end:
// verified bytes → cache → store enforcement refuses the install.
func TestApplyRevocationCacheToStore(t *testing.T) {
	s := testStore(t)
	rc, err := NewRevocationCache(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	raw := revocationJSONForCache(t, time.Now().Add(24*time.Hour))
	if err := rc.Store(raw); err != nil {
		t.Fatal(err)
	}
	l, ok := rc.Load()
	if !ok {
		t.Fatal("no cached list")
	}
	if !ApplyToStore(s, l) {
		t.Fatal("ApplyToStore reported nothing applied")
	}
	// The hello fixture is not revoked, so installing it still works…
	installHello(t, s, "1.0.0")
	// …but an extension on the list cannot be enabled after the fact:
	// revoke the fixture id and try to re-enable it.
	l2, err := ParseRevocationList([]byte(`{"revocation_version":1,` +
		`"updated_at":"2026-10-20T00:00:00Z","expires_at":"2099-01-01T00:00:00Z",` +
		`"entries":[{"id":"com.example.hello","versions":"*","reason":"test"}]}`))
	if err != nil {
		t.Fatal(err)
	}
	ApplyToStore(s, l2)
	// Already enabled; disable then try to enable again - must be refused.
	if err := s.SetEnabled("com.example.hello", false); err != nil {
		t.Fatal(err)
	}
	if err := s.SetEnabled("com.example.hello", true); err == nil {
		t.Fatal("enabling a revoked extension must be refused")
	}
}
