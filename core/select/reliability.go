package serversel

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Reliability persistence lives next to the probe history and shares its
// conventions: one JSON file, owner-only permissions, atomic write, corrupt
// files dropped instead of fatal.
const (
	reliabilityDir          = "probe"
	reliabilityFile         = "reliability.json"
	maxReliabilityFileBytes = 1 << 20
)

// ReliabilityConfig tunes the connection-outcome journal. The zero value is
// usable: 30-day TTL, no Beta prior (pure empirical rates; unknown servers
// still score 0.5), in-memory only. Empty DataDir disables persistence.
type ReliabilityConfig struct {
	// DataDir anchors probe/reliability.json. Empty disables persistence
	// (in-memory only).
	DataDir string
	// TTL is how long an entry counts after its last outcome. Expired
	// entries fall back to the prior rate and are pruned on save.
	// Clamped to [1h, 8760h]; zero means the default.
	TTL time.Duration
	// PriorSuccess and PriorFailure are the Beta prior pseudo-counts, so a
	// server with a couple of samples is not trusted blindly. Zero
	// disables the prior (pure empirical rate). Clamped to [0, 1000].
	PriorSuccess float64
	PriorFailure float64
	// Now is overridden in tests.
	Now func() time.Time
}

// DefaultReliabilityConfig returns the reference tuning.
func DefaultReliabilityConfig() ReliabilityConfig {
	return ReliabilityConfig{
		TTL:          30 * 24 * time.Hour,
		PriorSuccess: 1,
		PriorFailure: 1,
	}
}

func (c ReliabilityConfig) clamped() ReliabilityConfig {
	if c.TTL == 0 {
		c.TTL = DefaultReliabilityConfig().TTL
	}
	if c.TTL < time.Hour {
		c.TTL = time.Hour
	}
	if c.TTL > 8760*time.Hour {
		c.TTL = 8760 * time.Hour
	}
	c.PriorSuccess = clampFloat(c.PriorSuccess, 0, 1000)
	c.PriorFailure = clampFloat(c.PriorFailure, 0, 1000)
	return c
}

// priorRate is the success rate assumed for unknown or expired servers: the
// Beta prior mean, or neutral 0.5 when the prior is disabled.
func priorRate(priorSuccess, priorFailure float64) float64 {
	sum := priorSuccess + priorFailure
	if sum <= 0 {
		return neutralComponent
	}
	return clamp01(priorSuccess / sum)
}

// reliabilityEntry is one server's outcome journal.
type reliabilityEntry struct {
	Successes uint32    `json:"successes"`
	Failures  uint32    `json:"failures"`
	LastSeen  time.Time `json:"last_seen"`
}

// expired reports whether the entry is older than the TTL as of now.
func (e reliabilityEntry) expired(now time.Time, ttl time.Duration) bool {
	return now.Sub(e.LastSeen) > ttl
}

// ReliabilityStore journals per-server connection outcomes and turns them
// into a success rate with a Beta prior. It is safe for concurrent use.
type ReliabilityStore struct {
	cfg ReliabilityConfig
	now func() time.Time

	mu      sync.Mutex
	entries map[string]reliabilityEntry
}

// NewReliabilityStore clamps the config and loads persisted entries.
// A missing or corrupt file starts an empty store; it is never fatal.
func NewReliabilityStore(cfg ReliabilityConfig) *ReliabilityStore {
	cfg = cfg.clamped()
	now := cfg.Now
	if now == nil {
		now = time.Now
	}
	s := &ReliabilityStore{
		cfg:     cfg,
		now:     now,
		entries: map[string]reliabilityEntry{},
	}
	s.load()
	return s
}

// Config returns the clamped configuration in effect.
func (s *ReliabilityStore) Config() ReliabilityConfig { return s.cfg }

// Record journals one connection outcome for the server. Empty ids are
// ignored; counters saturate instead of wrapping.
func (s *ReliabilityStore) Record(id string, ok bool) {
	if id == "" {
		return
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	e := s.entries[id]
	if ok {
		if e.Successes < ^uint32(0) {
			e.Successes++
		}
	} else {
		if e.Failures < ^uint32(0) {
			e.Failures++
		}
	}
	e.LastSeen = s.now()
	s.entries[id] = e
	s.saveLocked()
}

// Rate returns the connection success rate in [0, 1]: the Beta posterior
// mean with the configured prior. Unknown or expired servers return the
// prior rate.
func (s *ReliabilityStore) Rate(id string) float64 {
	s.mu.Lock()
	defer s.mu.Unlock()
	e, ok := s.entries[id]
	if !ok || e.expired(s.now(), s.cfg.TTL) {
		return priorRate(s.cfg.PriorSuccess, s.cfg.PriorFailure)
	}
	total := float64(e.Successes) + float64(e.Failures) + s.cfg.PriorSuccess + s.cfg.PriorFailure
	if total <= 0 {
		return neutralComponent
	}
	return clamp01((float64(e.Successes) + s.cfg.PriorSuccess) / total)
}

// Stats returns the raw counters. found is false for unknown or expired ids.
func (s *ReliabilityStore) Stats(id string) (successes, failures uint32, found bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	e, ok := s.entries[id]
	if !ok || e.expired(s.now(), s.cfg.TTL) {
		return 0, 0, false
	}
	return e.Successes, e.Failures, true
}

// Prune drops expired entries and returns how many were removed.
func (s *ReliabilityStore) Prune() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	now := s.now()
	removed := 0
	for id, e := range s.entries {
		if e.expired(now, s.cfg.TTL) {
			delete(s.entries, id)
			removed++
		}
	}
	if removed > 0 {
		s.saveLocked()
	}
	return removed
}

func (s *ReliabilityStore) path() string {
	if s.cfg.DataDir == "" {
		return ""
	}
	return filepath.Join(s.cfg.DataDir, reliabilityDir, reliabilityFile)
}

func (s *ReliabilityStore) load() {
	path := s.path()
	if path == "" {
		return
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return // Absent history is not an error.
	}
	if len(raw) > maxReliabilityFileBytes {
		return // Absurd file: drop, never fatal.
	}
	var stored map[string]reliabilityEntry
	if err := json.Unmarshal(raw, &stored); err != nil {
		return // Corrupt history is dropped, never fatal.
	}
	now := s.now()
	for id, e := range stored {
		if id == "" || e.expired(now, s.cfg.TTL) {
			continue
		}
		s.entries[id] = e
	}
}

// saveLocked persists atomically: write temp, then rename. Expired
// entries are pruned from the file (never from the in-memory map, where
// Rate/Stats already treat them as expired), so the history cannot grow
// past the size cap with dead entries.
func (s *ReliabilityStore) saveLocked() {
	path := s.path()
	if path == "" {
		return
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return
	}
	now := s.now()
	kept := make(map[string]reliabilityEntry, len(s.entries))
	for id, e := range s.entries {
		if e.expired(now, s.cfg.TTL) {
			continue
		}
		kept[id] = e
	}
	raw, err := json.Marshal(kept)
	if err != nil {
		return
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o600); err != nil {
		return
	}
	_ = os.Rename(tmp, path)
}
