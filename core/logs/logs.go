// Package logs provides a bounded in-memory log for the core and engines, with
// query, watch, filter, and export operations. It never writes to disk to avoid
// persisting destinations and server identities. Entries and bytes are bounded;
// export is explicit.
package logs

import (
	"regexp"
	"slices"
	"strings"
	"sync"
	"time"
	"unicode"
	"unicode/utf8"
)

// Level is the severity of an entry. The zero value is not a level.
type Level int8

// Severities in increasing order.
const (
	LevelDebug Level = iota + 1
	LevelInfo
	LevelWarning
	LevelError
)

var levelNames = map[Level]string{LevelDebug: "debug", LevelInfo: "info", LevelWarning: "warning", LevelError: "error"}

func (l Level) String() string {
	if n, ok := levelNames[l]; ok {
		return n
	}
	return "unknown"
}

// ParseLevel accepts the level names the engines and the core use.
func ParseLevel(s string) (Level, bool) {
	// Fast path for the exact spellings the engines emit (sing-box shouts,
	// mihomo whispers, Xray capitalizes), so the per-line parse does not pay
	// for the allocating lowercase copy below. Any other spelling falls
	// through to the original case- and space-insensitive match.
	switch s {
	case "trace", "TRACE", "Trace", "debug", "DEBUG", "Debug", "dbg", "DBG", "Dbg":
		return LevelDebug, true
	case "info", "INFO", "Info", "information", "INFORMATION", "Information",
		"notice", "NOTICE", "Notice":
		return LevelInfo, true
	case "warn", "WARN", "Warn", "warning", "WARNING", "Warning":
		return LevelWarning, true
	case "error", "ERROR", "Error", "err", "ERR", "Err", "fatal", "FATAL", "Fatal",
		"panic", "PANIC", "Panic", "critical", "CRITICAL", "Critical":
		return LevelError, true
	}
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "trace", "debug", "dbg":
		return LevelDebug, true
	case "info", "information", "notice":
		return LevelInfo, true
	case "warn", "warning":
		return LevelWarning, true
	case "error", "err", "fatal", "panic", "critical":
		return LevelError, true
	}
	return 0, false
}

// SourceCore names entries the core service itself wrote. Engine entries carry
// the engine kind.
const SourceCore = "core"

// SourceSubscription identifies events containing only operation names, error keys and local IDs.
const SourceSubscription = "subscription"

// Entry is one log record. Message is already masked when it is stored.
type Entry struct {
	Seq     uint64
	Time    time.Time
	Level   Level
	Source  string
	Message string
	// Repeat counts identical consecutive messages folded into this entry;
	// 1
	// for a message seen once. Time is the time of the latest one.
	Repeat uint32
}

func (e Entry) size() int { return len(e.Message) + len(e.Source) + 48 }

// Settings applies runtime log changes starting with the next entry.
type Settings struct {
	// CaptureLevel filters entries before storage. Engines stay at debug
	// level, so changes require no restart.
	CaptureLevel Level
	// RecordDestinations retains visited hosts and addresses. When
	// disabled, they are masked before storage.
	RecordDestinations bool
	// MaxEntries and MaxBytes bound the record; the oldest entries go
	// first.
	MaxEntries int
	MaxBytes   int
}

// MaxBytes counts message bytes and fixed entry overhead to bound floods of
// short lines too.
const (
	DefaultMaxEntries = 20000
	DefaultMaxBytes   = 8 << 20
	MaxMessageBytes   = 4 << 10
	// foldWindow limits how long identical consecutive messages share an
	// entry.
	foldWindow = 30 * time.Second
)

// DefaultSettings captures info and higher levels, including destinations.
func DefaultSettings() Settings {
	return Settings{CaptureLevel: LevelInfo, RecordDestinations: true, MaxEntries: DefaultMaxEntries, MaxBytes: DefaultMaxBytes}
}

func (s Settings) normalized() Settings {
	if _, ok := levelNames[s.CaptureLevel]; !ok {
		s.CaptureLevel = LevelInfo
	}
	if s.MaxEntries <= 0 {
		s.MaxEntries = DefaultMaxEntries
	}
	if s.MaxBytes <= 0 {
		s.MaxBytes = DefaultMaxBytes
	}
	return s
}

// Center is the log record. It is safe for concurrent use, and Append never
// blocks on a reader.
type Center struct {
	mu       sync.Mutex
	settings Settings
	entries  []Entry // oldest first; a view into backing starting at head
	// backing is the allocation entries views into, and head is the number
	// of leading slots eviction has slid past. Keeping both lets Write
	// compact the view back to the front of the same allocation instead
	// of paying for a fresh copying allocation every time the view runs
	// off the end — the steady state of a full log, where every write
	// evicts one entry.
	backing  []Entry
	head     int
	bytes    int
	next     uint64
	dropped  uint64 // entries evicted by the bounds
	watchers map[*watcher]struct{}
	now      func() time.Time
}

// New returns an empty log center.
func New(settings Settings) *Center {
	return &Center{settings: settings.normalized(), next: 1, watchers: map[*watcher]struct{}{}, now: time.Now}
}

// Settings returns the current log settings.
func (c *Center) Settings() Settings {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.settings
}

// SetSettings applies changes and immediately evicts entries beyond reduced
// bounds.
func (c *Center) SetSettings(s Settings) Settings {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.settings = s.normalized()
	c.evict()
	return c.settings
}

// truncateUTF8 cuts s to at most n bytes at a UTF-8 rune boundary, so the
// result is always valid UTF-8 (SORA-L15).
func truncateUTF8(s string, n int) string {
	if len(s) <= n {
		return s
	}
	s = s[:n]
	for !utf8.ValidString(s) {
		s = s[:len(s)-1]
	}
	return s
}

// Write records core or engine messages. Callers must redact credentials before
// writing.
func (c *Center) Write(at time.Time, level Level, source, message string) {
	message = strings.TrimRight(message, "\r\n")
	if message == "" {
		return
	}
	if len(message) > MaxMessageBytes {
		// Cut at a rune boundary so the stored text stays valid UTF-8
		// (SORA-L15).
		message = truncateUTF8(message, MaxMessageBytes) + " [cut]"
	}
	if at.IsZero() {
		at = c.now()
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if level < c.settings.CaptureLevel {
		return
	}
	if !c.settings.RecordDestinations && source != SourceCore && source != SourceSubscription {
		message = HideDestinations(message)
	}
	if n := len(c.entries); n > 0 {
		last := &c.entries[n-1]
		if last.Source == source && last.Level == level && last.Message == message && at.Sub(last.Time) < foldWindow {
			last.Repeat++
			last.Time = at
			c.notify(*last)
			return
		}
	}
	e := Entry{Seq: c.next, Time: at, Level: level, Source: source, Message: message, Repeat: 1}
	c.next++
	grew := false
	if len(c.entries) == cap(c.entries) {
		if c.backing != nil && c.head > 0 {
			// The view ran off the end of its allocation, but eviction
			// left dead slide space in front of it: move the live
			// entries back to the front and clear the stale copies the
			// move leaves behind, so appending reuses the allocation.
			// The move copies exactly what the realloc it replaces
			// would have copied; only the allocation is saved.
			n := copy(c.backing, c.entries)
			clear(c.backing[n : c.head+n])
			c.entries = c.backing[:n]
			c.head = 0
		} else {
			grew = true // append is about to allocate a fresh backing
		}
	}
	c.entries = append(c.entries, e)
	if grew || c.backing == nil {
		c.backing = c.entries[:cap(c.entries)]
		c.head = 0
	}
	c.bytes += e.size()
	c.evict()
	c.notify(e)
}

func (c *Center) evict() {
	drop := 0
	for drop < len(c.entries) && (len(c.entries)-drop > c.settings.MaxEntries || c.bytes > c.settings.MaxBytes) {
		c.bytes -= c.entries[drop].size()
		drop++
	}
	if drop == 0 {
		return
	}
	c.dropped += uint64(drop)
	// Release discarded messages without copying the full log on every write.
	clear(c.entries[:drop])
	c.entries = c.entries[drop:]
	c.head += drop
}

// Clear removes entries without resetting sequence numbers, preserving cursor
// uniqueness.
func (c *Center) Clear() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.entries = nil
	c.backing = nil
	c.head = 0
	c.bytes = 0
}

// Filter selects entries. Zero values select everything.
type Filter struct {
	MinLevel Level
	Sources  []string
	// Contains matches the message case-insensitively.
	Contains string
	// Pattern matches messages with Go's linear-time regular expressions to
	// prevent expensive untrusted filters.
	Pattern *regexp.Regexp
	Since   time.Time
	Until   time.Time
}

// MaxPatternLen bounds a filter expression.
const MaxPatternLen = 512

// CompilePattern checks and compiles a filter expression.
func CompilePattern(expr string) (*regexp.Regexp, error) {
	if expr == "" {
		return nil, nil
	}
	if len(expr) > MaxPatternLen {
		return nil, errPatternTooLong
	}
	return regexp.Compile("(?i)" + expr)
}

func (f Filter) match(e Entry) bool {
	if e.Level < f.MinLevel {
		return false
	}
	if len(f.Sources) > 0 && !slices.Contains(f.Sources, e.Source) {
		return false
	}
	if !f.Since.IsZero() && e.Time.Before(f.Since) {
		return false
	}
	if !f.Until.IsZero() && e.Time.After(f.Until) {
		return false
	}
	if f.Contains != "" && !foldContains(e.Message, f.Contains) {
		return false
	}
	return f.Pattern == nil || f.Pattern.MatchString(e.Message)
}

// foldContains reports whether s contains sub under Unicode lowercase
// folding. It is the comparison the Contains filter made through
// strings.ToLower copies of both sides — strings.ToLower maps each rune
// with unicode.ToLower, so folding rune by rune during the scan gives the
// same answer without allocating either copy (a query over a full center
// previously allocated a fresh pair of copies for every stored entry).
func foldContains(s, sub string) bool {
	if len(sub) == 0 {
		return true
	}
	for i := 0; i < len(s); {
		j, k := i, 0
		for j < len(s) && k < len(sub) {
			r1, size1 := utf8.DecodeRuneInString(s[j:])
			r2, size2 := utf8.DecodeRuneInString(sub[k:])
			if unicode.ToLower(r1) != unicode.ToLower(r2) {
				break
			}
			j += size1
			k += size2
		}
		if k == len(sub) {
			return true
		}
		_, size := utf8.DecodeRuneInString(s[i:])
		i += size
	}
	return false
}

// Page holds one Query result.
type Page struct {
	// Entries are newest first.
	Entries []Entry
	// Before is the cursor of the next, older page; zero when there is
	// none.
	Before uint64
	Stats  Stats
}

// Stats covers all entries, including those excluded by a filter.
type Stats struct {
	ByLevel  map[Level]int
	BySource map[string]int
	Total    int
	Bytes    int
	MaxBytes int
	// Dropped counts entries the bounds evicted since the core started.
	Dropped uint64
}

// MaxPage bounds one page.
const MaxPage = 1000

// Query returns up to limit matching entries older than before (zero: from the
// newest), newest first.
func (c *Center) Query(f Filter, before uint64, limit int) Page {
	if limit <= 0 || limit > MaxPage {
		limit = MaxPage
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	page := Page{Stats: c.stats(), Entries: make([]Entry, 0, min(limit, len(c.entries)))}
	for i := len(c.entries) - 1; i >= 0; i-- {
		e := c.entries[i]
		if before != 0 && e.Seq >= before {
			continue
		}
		if !f.match(e) {
			continue
		}
		if len(page.Entries) == limit {
			page.Before = page.Entries[len(page.Entries)-1].Seq
			break
		}
		page.Entries = append(page.Entries, e)
	}
	return page
}

// Matching returns every matching entry, oldest first, for an export.
func (c *Center) Matching(f Filter) []Entry {
	c.mu.Lock()
	defer c.mu.Unlock()
	// Count first, then fill one exact-size slice: growing by append made a
	// full-center export allocate roughly four times the result size in
	// discarded intermediate arrays.
	n := 0
	for _, e := range c.entries {
		if f.match(e) {
			n++
		}
	}
	if n == 0 {
		return nil
	}
	out := make([]Entry, 0, n)
	for _, e := range c.entries {
		if f.match(e) {
			out = append(out, e)
		}
	}
	return out
}

func (c *Center) stats() Stats {
	s := Stats{ByLevel: map[Level]int{}, BySource: map[string]int{}, Total: len(c.entries),
		Bytes: c.bytes, MaxBytes: c.settings.MaxBytes, Dropped: c.dropped}
	for _, e := range c.entries {
		s.ByLevel[e.Level]++
		s.BySource[e.Source]++
	}
	return s
}
