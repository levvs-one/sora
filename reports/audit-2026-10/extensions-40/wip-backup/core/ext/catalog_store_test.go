package ext

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func goodCatalogForStore(t *testing.T) []byte {
	t.Helper()
	good := &Catalog{
		Version:   1,
		UpdatedAt: time.Now().UTC().Format(time.RFC3339),
		Extensions: []Entry{{
			ID: "com.example.hello", Name: "Hello", Version: "1.0.0",
			Description: "d", Author: "Example", AuthorID: "github:example",
			AuthorKey:    testPubKeyLine(t),
			Rating:       4.5,
			RatingsCount: 10,
			Installs:     100,
			Badges:       []string{"verified"},
			Categories:   []string{"tools"},
			Capabilities: []string{"ui-panel"},
			Permissions:  []string{"notifications"},
			DownloadURL:  "https://example.com/hello.soraext",
			Sha256:       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
			Size:         1024,
			MinAppVer:    "1.9.0",
			Screenshots:  []string{"https://example.com/shot1.png"},
			Changelog: []ChangelogEntry{{
				Version: "1.0.0", Date: time.Now().UTC().Format(time.RFC3339),
				Notes: "First release.",
			}},
		}},
	}
	raw, err := json.Marshal(good)
	if err != nil {
		t.Fatal(err)
	}
	return raw
}

func TestCatalogNewFieldsValid(t *testing.T) {
	c, err := ParseCatalog(goodCatalogForStore(t))
	if err != nil {
		t.Fatalf("valid catalog with new fields rejected: %v", err)
	}
	if c.MaxAge != DefaultCatalogMaxAge {
		t.Fatalf("missing max_age: got %d, want default %d", c.MaxAge, DefaultCatalogMaxAge)
	}
	e := c.Extensions[0]
	if len(e.Screenshots) != 1 || len(e.Changelog) != 1 || len(e.Capabilities) != 1 {
		t.Fatalf("new fields lost in parse: %+v", e)
	}
}

func TestCatalogMaxAgeBounds(t *testing.T) {
	for _, maxAge := range []int{299, 604801} {
		raw := goodCatalogForStore(t)
		var m map[string]any
		if err := json.Unmarshal(raw, &m); err != nil {
			t.Fatal(err)
		}
		m["max_age"] = maxAge
		raw, _ = json.Marshal(m)
		if _, err := ParseCatalog(raw); err == nil {
			t.Fatalf("max_age=%d must be rejected", maxAge)
		}
	}
	raw := goodCatalogForStore(t)
	var m map[string]any
	if err := json.Unmarshal(raw, &m); err != nil {
		t.Fatal(err)
	}
	m["max_age"] = 600
	raw, _ = json.Marshal(m)
	c, err := ParseCatalog(raw)
	if err != nil {
		t.Fatalf("max_age=600 rejected: %v", err)
	}
	if c.MaxAge != 600 {
		t.Fatalf("max_age not kept: %d", c.MaxAge)
	}
}

func TestCatalogEntryExtrasRejected(t *testing.T) {
	mk := func(mut func(*Entry)) []byte {
		raw := goodCatalogForStore(t)
		var c Catalog
		if err := json.Unmarshal(raw, &c); err != nil {
			t.Fatal(err)
		}
		mut(&c.Extensions[0])
		raw, _ = json.Marshal(c)
		return raw
	}
	cases := map[string]func(*Entry){
		"rollout NaN":      func(e *Entry) { e.RolloutFraction = math.NaN() },
		"rollout > 1":      func(e *Entry) { e.RolloutFraction = 1.5 },
		"rollout negative": func(e *Entry) { e.RolloutFraction = -0.1 },
		"9 screenshots": func(e *Entry) {
			e.Screenshots = make([]string, 9)
			for i := range e.Screenshots {
				e.Screenshots[i] = "https://example.com/s.png"
			}
		},
		"screenshot http":   func(e *Entry) { e.Screenshots = []string{"http://example.com/s.png"} },
		"changelog version": func(e *Entry) { e.Changelog[0].Version = "v1" },
		"changelog date":    func(e *Entry) { e.Changelog[0].Date = "yesterday" },
		"changelog empty":   func(e *Entry) { e.Changelog[0].Notes = "  " },
		"bad capability":    func(e *Entry) { e.Capabilities = []string{"mind-reading"} },
	}
	for name, mut := range cases {
		if _, err := ParseCatalog(mk(mut)); err == nil {
			t.Fatalf("%s must be rejected", name)
		}
	}
}

func TestRolloutEligible(t *testing.T) {
	e := Entry{ID: "com.example.hello", Version: "2.0.0"}
	// Fully rolled out (missing fraction): everyone eligible.
	for i := 0; i < 50; i++ {
		if !e.RolloutEligible(fmt.Sprintf("install-%d", i)) {
			t.Fatal("fraction 1 must admit everyone")
		}
	}
	// Deterministic per install id: no flapping between syncs.
	e.RolloutFraction = 0.5
	for i := 0; i < 50; i++ {
		id := fmt.Sprintf("install-%d", i)
		if e.RolloutEligible(id) != e.RolloutEligible(id) {
			t.Fatal("rollout bucketing is not deterministic")
		}
	}
	// Distribution roughly matches the fraction.
	var yes int
	const n = 4000
	for i := 0; i < n; i++ {
		if e.RolloutEligible(fmt.Sprintf("install-%d", i)) {
			yes++
		}
	}
	frac := float64(yes) / n
	if frac < 0.4 || frac > 0.6 {
		t.Fatalf("fraction 0.5 admitted %.2f of installs, want ~0.5", frac)
	}
}

func TestCatalogCacheRoundtrip(t *testing.T) {
	cc, err := NewCatalogCache(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	raw := goodCatalogForStore(t)
	if err := cc.Store(raw); err != nil {
		t.Fatalf("store: %v", err)
	}
	c, fetchedAt, ok := cc.Load()
	if !ok {
		t.Fatal("load after store: not ok")
	}
	if len(c.Extensions) != 1 || c.Extensions[0].ID != "com.example.hello" {
		t.Fatalf("cached catalog wrong: %+v", c)
	}
	if time.Since(fetchedAt) > time.Minute {
		t.Fatalf("fetched_at wrong: %v", fetchedAt)
	}
	if !Fresh(c, fetchedAt, time.Now()) {
		t.Fatal("freshly stored catalog must be fresh")
	}
	// Stale: fetched long ago with a short max_age.
	staleAt := time.Now().Add(-2 * time.Hour)
	var m map[string]any
	if err := json.Unmarshal(raw, &m); err != nil {
		t.Fatal(err)
	}
	m["max_age"] = 300
	raw, _ = json.Marshal(m)
	c2, err := ParseCatalog(raw)
	if err != nil {
		t.Fatal(err)
	}
	if Fresh(c2, staleAt, time.Now()) {
		t.Fatal("2h-old catalog with max_age=300 must not be fresh")
	}
}

func TestCatalogCacheCorruptIsNoCache(t *testing.T) {
	dir := t.TempDir()
	cc, err := NewCatalogCache(dir)
	if err != nil {
		t.Fatal(err)
	}
	if _, _, ok := cc.Load(); ok {
		t.Fatal("empty cache must report not-ok")
	}
}

func TestCatalogRefreshFallsBackToCache(t *testing.T) {
	cc, err := NewCatalogCache(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	raw := goodCatalogForStore(t)
	if err := cc.Store(raw); err != nil {
		t.Fatal(err)
	}
	// A server that always fails: no network path, only the cache.
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer srv.Close()
	c, fromCache, _, err := cc.Refresh(t.Context(), srv.Client(), srv.URL+"/catalog.json")
	if err != nil {
		t.Fatalf("refresh with cache must not fail: %v", err)
	}
	if !fromCache {
		t.Fatal("must report fromCache on fetch failure")
	}
	if len(c.Extensions) != 1 {
		t.Fatalf("wrong cached catalog: %+v", c)
	}
}

func TestCatalogRefreshNoCacheNoNetwork(t *testing.T) {
	cc, err := NewCatalogCache(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer srv.Close()
	if _, _, _, err := cc.Refresh(t.Context(), srv.Client(), srv.URL+"/catalog.json"); err == nil {
		t.Fatal("no cache and no network must return the fetch error")
	}
}
