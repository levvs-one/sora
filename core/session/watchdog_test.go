package session

import (
	"testing"
	"time"
)

func TestCrashWatchReportsOncePerEpisode(t *testing.T) {
	now := time.Now()
	w := &crashWatch{now: func() time.Time { return now }}
	for i := 0; i < 5; i++ {
		if w.note() {
			t.Fatalf("crash %d must not report yet", i+1)
		}
		now = now.Add(time.Second)
	}
	if !w.note() {
		t.Fatal("6th crash in a minute must report instability")
	}
	if w.note() {
		t.Fatal("must report only once per episode")
	}
}

func TestCrashWatchWindowSlides(t *testing.T) {
	now := time.Now()
	w := &crashWatch{now: func() time.Time { return now }}
	for i := 0; i < 6; i++ {
		w.note()
		now = now.Add(30 * time.Second) // 3 minutes total: window slides
	}
	// The 6 notes span 2.5 minutes; the rolling 60s window never holds >5.
	if w.note() {
		t.Fatal("spread-out crashes must not report")
	}
}

func TestCrashWatchNewEpisodeAfterQuiet(t *testing.T) {
	now := time.Now()
	w := &crashWatch{now: func() time.Time { return now }}
	for i := 0; i < 6; i++ {
		w.note()
	}
	now = now.Add(2 * crashWindow)
	for i := 0; i < 5; i++ {
		if w.note() {
			t.Fatalf("new episode crash %d must not report yet", i+1)
		}
	}
	if !w.note() {
		t.Fatal("new episode must report again after a quiet window")
	}
}

func TestCrashWatchReset(t *testing.T) {
	now := time.Now()
	w := &crashWatch{now: func() time.Time { return now }}
	for i := 0; i < 3; i++ {
		w.note()
	}
	w.reset()
	for i := 0; i < 5; i++ {
		if w.note() {
			t.Fatalf("post-reset crash %d must not report yet", i+1)
		}
	}
	if !w.note() {
		t.Fatal("6 post-reset crashes must report")
	}
}
