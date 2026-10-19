package tune

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/profiles"
)

// CacheTTL is how long a remembered strategy stays valid for a network.
const CacheTTL = 30 * 24 * time.Hour

// cacheFileName is the cache location inside the data directory.
const cacheFileName = "tune/cache.json"

// cacheVersion lets a future format migrate instead of misreading.
const cacheVersion = 1

type cacheEntry struct {
	StrategyID string    `json:"strategy_id"`
	At         time.Time `json:"at"`
}

type cacheFile struct {
	Version int                   `json:"version"`
	Entries map[string]cacheEntry `json:"entries"`
}

// Cache remembers the working obfuscation strategy per network fingerprint.
// It is advisory: a missing or corrupt file simply starts empty, and a
// failed write never fails a tuning run.
type Cache struct {
	mu      sync.Mutex
	path    string
	entries map[string]cacheEntry
}

// NewCache opens the cache under dir (tune/cache.json).
func NewCache(dir string) *Cache {
	c := &Cache{path: filepath.Join(dir, cacheFileName), entries: map[string]cacheEntry{}}
	c.load()
	return c
}

// Path reports where the cache is persisted. Useful for diagnostics.
func (c *Cache) Path() string { return c.path }

func (c *Cache) load() {
	data, err := os.ReadFile(c.path)
	if err != nil {
		return
	}
	var f cacheFile
	if err := json.Unmarshal(data, &f); err != nil || f.Version != cacheVersion {
		return
	}
	now := time.Now()
	for k, e := range f.Entries {
		if e.StrategyID == "" || now.Sub(e.At) > CacheTTL {
			continue
		}
		c.entries[k] = e
	}
}

// networkKey builds the cache key from the F5 fingerprint. SSID, gateway
// and ASN identify the network attachment; the interface-address string is
// display data that churns under DHCP/SLAAC, so it is intentionally
// excluded — a missed cache hit only costs the default try-order, while a
// wrong hit would apply a stale strategy.
func networkKey(fp profiles.Fingerprint) string {
	return strings.Join([]string{fp.SSID, fp.Gateway, fp.ASN}, "\x1f")
}

// Lookup returns the strategy remembered for the fingerprint's network when
// the entry exists, is younger than CacheTTL and still resolves to a known
// strategy.
func (c *Cache) Lookup(fp profiles.Fingerprint) (Strategy, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	e, ok := c.entries[networkKey(fp)]
	if !ok || time.Since(e.At) > CacheTTL {
		return Strategy{}, false
	}
	s, ok := Lookup(e.StrategyID)
	if !ok {
		return Strategy{}, false
	}
	return s, true
}

// Remember stores the winning strategy for the fingerprint's network and
// persists the cache with mode 0600. Expired entries are pruned so the file
// does not grow forever. A persistence failure is returned but never
// invalidates the in-memory entry.
func (c *Cache) Remember(fp profiles.Fingerprint, s Strategy) error {
	c.mu.Lock()
	c.entries[networkKey(fp)] = cacheEntry{StrategyID: s.ID, At: time.Now().UTC()}
	for k, e := range c.entries {
		if time.Since(e.At) > CacheTTL {
			delete(c.entries, k)
		}
	}
	data, err := json.MarshalIndent(cacheFile{Version: cacheVersion, Entries: c.entries}, "", "  ")
	c.mu.Unlock()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(c.path), 0o700); err != nil {
		return err
	}
	// OpenFile + Chmod instead of WriteFile: WriteFile leaves the mode of
	// an existing file untouched, and the cache must stay 0600.
	f, err := os.OpenFile(c.path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0o600)
	if err != nil {
		return err
	}
	defer f.Close()
	if _, err := f.Write(data); err != nil {
		return err
	}
	return f.Chmod(0o600)
}
