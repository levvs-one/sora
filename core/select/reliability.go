package serversel

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"sync"
	"time"
	"unicode/utf8"
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

	// filePath and tmpPath are cfg.DataDir resolved once: the config
	// never changes after construction, so saveLocked does not need to
	// re-join the path on every Record.
	filePath string
	tmpPath  string

	mu      sync.Mutex
	entries map[string]reliabilityEntry

	// Serialization scratch for saveLocked, reused across saves so a
	// Record on a large store does not allocate a fresh output buffer
	// and key slice every time. Only touched with mu held.
	saveBuf  []byte
	saveKeys []string
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
	if cfg.DataDir != "" {
		s.filePath = filepath.Join(cfg.DataDir, reliabilityDir, reliabilityFile)
		s.tmpPath = s.filePath + ".tmp"
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

func (s *ReliabilityStore) load() {
	path := s.filePath
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
//
// The write used to cost O(store) allocations per Record — a copied
// kept-map plus a fresh json.Marshal of the whole journal (~279 KB and
// ~1000 allocs per Record at 1000 entries, measured). Now the common
// no-expired case serializes the live map directly, and the serializer
// appends into buffers reused across saves: per-Record allocations are
// O(1) in the store size. The output is byte-identical to the old
// json.Marshal(kept) — sorted keys, same field order, same string and
// time encodings; a differential test pins that, including exotic ids,
// which fall back to encoding/json for their own encoding.
func (s *ReliabilityStore) saveLocked() {
	path := s.filePath
	if path == "" {
		return
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return
	}
	now := s.now()
	entries := s.entries
	for _, e := range entries {
		if e.expired(now, s.cfg.TTL) {
			// Something expired: build the pruned copy, as before.
			entries = make(map[string]reliabilityEntry, len(s.entries))
			for id, e := range s.entries {
				if !e.expired(now, s.cfg.TTL) {
					entries[id] = e
				}
			}
			break
		}
	}
	var ok bool
	s.saveBuf, s.saveKeys, ok = appendReliabilityJSON(s.saveBuf[:0], s.saveKeys[:0], entries)
	if !ok {
		return // Mirrors the old json.Marshal error path: write nothing.
	}
	if err := os.WriteFile(s.tmpPath, s.saveBuf, 0o600); err != nil {
		return
	}
	_ = os.Rename(s.tmpPath, path)
}

// appendReliabilityJSON renders the journal exactly as
// json.Marshal(map[string]reliabilityEntry) would: keys sorted, fields
// in struct order, times in RFC3339Nano. ok is false when a timestamp's
// year falls outside [0, 9999] — the one case where marshaling a
// time.Time errors out — so the caller writes nothing, as before.
// keys is caller-owned scratch, returned grown for reuse.
func appendReliabilityJSON(dst []byte, keys []string, entries map[string]reliabilityEntry) ([]byte, []string, bool) {
	keys = keys[:0]
	for id := range entries {
		keys = append(keys, id)
	}
	sort.Strings(keys)
	dst = append(dst, '{')
	for i, id := range keys {
		if i > 0 {
			dst = append(dst, ',')
		}
		e := entries[id]
		if y := e.LastSeen.Year(); y < 0 || y > 9999 {
			return dst, keys, false
		}
		dst = appendReliabilityKey(dst, id)
		dst = append(dst, `:{"successes":`...)
		dst = strconv.AppendUint(dst, uint64(e.Successes), 10)
		dst = append(dst, `,"failures":`...)
		dst = strconv.AppendUint(dst, uint64(e.Failures), 10)
		dst = append(dst, `,"last_seen":`...)
		dst = e.LastSeen.AppendFormat(dst, `"`+time.RFC3339Nano+`"`)
		dst = append(dst, '}')
	}
	dst = append(dst, '}')
	return dst, keys, true
}

// appendReliabilityKey appends id as a JSON object key, byte-identical
// to encoding/json with HTML escaping on. Plain server ids (printable
// ASCII without the JSON/HTML specials) append verbatim; anything more
// exotic is encoded by encoding/json itself, so the outputs cannot
// diverge.
func appendReliabilityKey(dst []byte, id string) []byte {
	if jsonKeySafe(id) {
		dst = append(dst, '"')
		dst = append(dst, id...)
		dst = append(dst, '"')
		return dst
	}
	raw, _ := json.Marshal(id)
	return append(dst, raw...)
}

// jsonKeySafe reports whether encoding/json would emit id's bytes
// unchanged between quotes: printable ASCII except `"`, `\` and the
// HTML-escaped `<`, `>`, `&`, valid UTF-8 throughout (an invalid byte
// would be replaced with U+FFFD), and no U+2028/U+2029 (the two
// non-ASCII runes encoding/json still escapes).
func jsonKeySafe(id string) bool {
	for i := 0; i < len(id); i++ {
		b := id[i]
		if b < 0x20 || b == '"' || b == '\\' || b == '<' || b == '>' || b == '&' {
			return false
		}
	}
	if !utf8.ValidString(id) {
		return false
	}
	for _, r := range id {
		if r == '\u2028' || r == '\u2029' {
			return false
		}
	}
	return true
}
