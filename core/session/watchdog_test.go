package session

import (
	"context"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

func TestCrashWatchReportsOncePerEpisode(t *testing.T) {
	now := time.Now()
	w := &crashWatch{now: func() time.Time { return now }}
	for i := 0; i < maxCrashes-1; i++ {
		if w.note() {
			t.Fatalf("crash %d must not report yet", i+1)
		}
		now = now.Add(time.Second)
	}
	if !w.note() {
		t.Fatalf("crash %d in a minute must report instability", maxCrashes)
	}
	if w.note() {
		t.Fatal("must report only once per episode")
	}
}

func TestCrashWatchWindowSlides(t *testing.T) {
	now := time.Now()
	w := &crashWatch{now: func() time.Time { return now }}
	for i := 0; i < maxCrashes+1; i++ {
		w.note()
		now = now.Add(30 * time.Second) // 3 minutes total: window slides
	}
	// The notes span 3 minutes; the rolling 60s window never holds maxCrashes.
	if w.note() {
		t.Fatal("spread-out crashes must not report")
	}
}

func TestCrashWatchNewEpisodeAfterQuiet(t *testing.T) {
	now := time.Now()
	w := &crashWatch{now: func() time.Time { return now }}
	for i := 0; i < maxCrashes; i++ {
		w.note()
	}
	now = now.Add(2 * crashWindow)
	for i := 0; i < maxCrashes-1; i++ {
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
	for i := 0; i < maxCrashes-1; i++ {
		if w.note() {
			t.Fatalf("post-reset crash %d must not report yet", i+1)
		}
	}
	if !w.note() {
		t.Fatal("maxCrashes post-reset crashes must report")
	}
}

// TestCrashWatchBoundaryOldCrashPruned pins the rolling-window edge: the
// oldest crash falls exactly on the cutoff, so it must not count toward the
// threshold.
func TestCrashWatchBoundaryOldCrashPruned(t *testing.T) {
	now := time.Now()
	w := &crashWatch{now: func() time.Time { return now }}
	w.note() // at now: lands exactly on the cutoff of the last note below
	for i := 0; i < maxCrashes-1; i++ {
		// Four 15s steps put the last note exactly crashWindow after the
		// first one, so the first one is pruned at the boundary.
		now = now.Add(crashWindow / time.Duration(maxCrashes-1))
		if w.note() {
			t.Fatalf("crash %d must not report yet", i+2)
		}
	}
	// The last loop note sat exactly crashWindow after the first: without
	// pruning it would have been the 5th in-window crash and reported.
	// One more crash at the same instant fills the window to exactly
	// maxCrashes (the edge crash stays pruned) and must report.
	if !w.note() {
		t.Fatal("maxCrashes in-window crashes must report")
	}
}

func TestWatchdogCountsCrashesAcrossEngineRecoveries(t *testing.T) {
	eng := newFakeEngine()
	running, err := New(testConfig(eng, &fakeGuard{}))
	if err != nil {
		t.Fatal(err)
	}
	if err := running.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = running.Stop(context.Background()) }()
	for i := 0; i < maxCrashes; i++ {
		eng.bus.Publish(engine.Event{Kind: engine.EventEngineDown})
		waitFor(t, time.Second, func() bool { return running.State() == StateReconnecting })
		eng.bus.Publish(engine.Event{Kind: engine.EventState, State: engine.StateRunning})
		waitFor(t, time.Second, func() bool { return running.State() == StateConnected })
	}
	var warnings int
	for _, event := range running.Journal().Since(0, 0) {
		if event.Key == errs.KeyEngineUnstable {
			warnings++
		}
	}
	if warnings != 1 {
		t.Fatalf("instability warnings across recoveries: %d, want 1", warnings)
	}
}
