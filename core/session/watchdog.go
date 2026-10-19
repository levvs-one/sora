package session

// Engine crash watchdog (F7). The supervisor restarts crashed engines with
// backoff inside its own budget; this watchdog watches from the session
// side and reports instability once: more than maxCrashes engine crashes
// within crashWindow. The client shows an "engine unstable" banner with a
// diagnostics shortcut on that signal.

import (
	"sync"
	"time"
)

const (
	crashWindow = 60 * time.Second
	maxCrashes  = 5
)

// crashWatch counts engine crashes in a rolling window. note returns true
// exactly once per instability episode: when the threshold is crossed.
// The episode resets after a quiet window.
type crashWatch struct {
	mu       sync.Mutex
	at       []time.Time
	now      func() time.Time
	reported bool
}

func newCrashWatch() *crashWatch {
	return &crashWatch{now: time.Now}
}

// note records one engine crash. It reports true the first time the crash
// count inside the rolling window exceeds maxCrashes.
func (w *crashWatch) note() bool {
	w.mu.Lock()
	defer w.mu.Unlock()
	now := w.now()
	cutoff := now.Add(-crashWindow)
	kept := w.at[:0]
	for _, t := range w.at {
		if t.After(cutoff) {
			kept = append(kept, t)
		}
	}
	if len(kept) == 0 {
		// A quiet window passed: a new episode may report again.
		w.reported = false
	}
	w.at = append(kept, now)
	if len(w.at) <= maxCrashes {
		return false
	}
	if w.reported {
		return false
	}
	w.reported = true
	return true
}

// reset clears the crash history, e.g. after a clean reconnect.
func (w *crashWatch) reset() {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.at = nil
	w.reported = false
}
