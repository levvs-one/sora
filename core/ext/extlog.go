// Extension log: a bounded per-extension ring buffer that both the
// background worker scheduler and net.fetch write to. The app surfaces it
// in the extension details screen ("Logs"); entries are also the audit trail
// for every network request an extension makes.
package ext

import (
	"sync"
	"time"
)

// LogLevel is the severity of one extension log entry.
type LogLevel int

const (
	// LogInfo is routine operational output (worker results, fetch summary).
	LogInfo LogLevel = iota
	// LogWarn is a denied or degraded operation.
	LogWarn
	// LogError is a failed operation.
	LogError
)

// MaxLogEntries bounds one extension's log; MaxLogMessage bounds one entry.
// Both keep a misbehaving extension from growing memory without limit.
const (
	MaxLogEntries = 256
	MaxLogMessage = 1024
)

// LogEntry is one line in an extension's log.
type LogEntry struct {
	At      time.Time
	Level   LogLevel
	Message string
}

// ExtLog is a thread-safe ring buffer of log entries for one extension.
type ExtLog struct {
	mu      sync.Mutex
	entries []LogEntry
}

// Append adds one entry, dropping the oldest when the buffer is full.
func (l *ExtLog) Append(level LogLevel, msg string) {
	if len(msg) > MaxLogMessage {
		msg = msg[:MaxLogMessage]
	}
	l.mu.Lock()
	defer l.mu.Unlock()
	l.entries = append(l.entries, LogEntry{At: time.Now().UTC(), Level: level, Message: msg})
	if len(l.entries) > MaxLogEntries {
		copy(l.entries, l.entries[len(l.entries)-MaxLogEntries:])
		l.entries = l.entries[:MaxLogEntries]
	}
}

// Entries returns a copy of the buffered entries, oldest first.
func (l *ExtLog) Entries() []LogEntry {
	l.mu.Lock()
	defer l.mu.Unlock()
	out := make([]LogEntry, len(l.entries))
	copy(out, l.entries)
	return out
}

// Len reports the number of buffered entries.
func (l *ExtLog) Len() int {
	l.mu.Lock()
	defer l.mu.Unlock()
	return len(l.entries)
}

// LogHub owns the per-extension logs. It is the single sink the runtime
// (workers, net.fetch) writes to, and the app reads from for display.
type LogHub struct {
	mu   sync.Mutex
	logs map[string]*ExtLog
}

// NewLogHub returns an empty hub.
func NewLogHub() *LogHub {
	return &LogHub{logs: map[string]*ExtLog{}}
}

// Log returns the log for extID, creating it on first use.
func (h *LogHub) Log(extID string) *ExtLog {
	h.mu.Lock()
	defer h.mu.Unlock()
	l, ok := h.logs[extID]
	if !ok {
		l = &ExtLog{}
		h.logs[extID] = l
	}
	return l
}

// Drop forgets the log for extID (extension uninstalled).
func (h *LogHub) Drop(extID string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	delete(h.logs, extID)
}
