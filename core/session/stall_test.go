package session

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// manualClock is a goroutine-safe fake clock for the stall detector.
type manualClock struct {
	mu sync.Mutex
	t  time.Time
}

func (c *manualClock) now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.t
}

func (c *manualClock) advance(d time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.t = c.t.Add(d)
}

func newStallWatchAt(t time.Time) (*stallWatch, *manualClock) {
	c := &manualClock{t: t}
	return &stallWatch{now: c.now, backoff: stallBackoffBase}, c
}

// A stalled tunnel — open connections, zero payload bytes for the whole
// window past warmup — must trip the detector.
func TestStallWatchDetectsZeroBytesWithDemand(t *testing.T) {
	w, c := newStallWatchAt(time.Now())
	w.markConnected()
	if w.observe(100, true) {
		t.Fatal("the baseline sample must not report a stall")
	}
	c.advance(stallWarmup + stallWindow)
	if !w.observe(100, true) {
		t.Fatal("zero bytes with demand past the window must report a stall")
	}
}

// Idle is not a stall: with no open connections the clock resets, and a
// later demand still needs a full fresh window.
func TestStallWatchIgnoresIdle(t *testing.T) {
	w, c := newStallWatchAt(time.Now())
	w.markConnected()
	w.observe(100, true)
	c.advance(stallWarmup + stallWindow)
	if w.observe(100, false) {
		t.Fatal("no open connections must not report a stall")
	}
	// Demand returned, but the idle tick reset the clock.
	if w.observe(100, true) {
		t.Fatal("demand right after idle must not report a stall")
	}
	c.advance(stallWindow - time.Second)
	if w.observe(100, true) {
		t.Fatal("a partial window after idle must not report a stall")
	}
	c.advance(2 * time.Second)
	if !w.observe(100, true) {
		t.Fatal("a full window of zero bytes with demand must report a stall")
	}
}

// The first seconds after establish are a warmup: zero bytes there must
// not trip the detector, and the stall clock must not accumulate during
// warmup either.
func TestStallWatchWarmup(t *testing.T) {
	w, c := newStallWatchAt(time.Now())
	w.markConnected()
	w.observe(0, true)
	c.advance(stallWarmup - time.Second)
	if w.observe(0, true) {
		t.Fatal("zero bytes inside warmup must not report a stall")
	}
	// Warmup just ended; the clock was frozen during warmup, so a full
	// window is still required.
	c.advance(2 * time.Second)
	if w.observe(0, true) {
		t.Fatal("warmup must not count towards the stall window")
	}
	c.advance(stallWindow)
	if !w.observe(0, true) {
		t.Fatal("a full window past warmup must report a stall")
	}
}

// Moving bytes are progress: the detector must stay quiet and a counter
// reset (engine restart) must re-baseline instead of tripping.
func TestStallWatchProgressAndCounterReset(t *testing.T) {
	w, c := newStallWatchAt(time.Now())
	w.markConnected()
	w.observe(100, true)
	c.advance(stallWarmup + stallWindow)
	if w.observe(200, true) {
		t.Fatal("moving bytes must not report a stall")
	}
	c.advance(stallWarmup + stallWindow)
	if w.observe(0, true) {
		t.Fatal("a counter reset must re-baseline, not report a stall")
	}
	c.advance(stallWindow)
	if !w.observe(0, true) {
		t.Fatal("zero bytes for a full window after the reset must report a stall")
	}
}

// Consecutive stalls without intervening traffic must back off
// exponentially so a wedged server cannot spin the reconnect loop.
func TestStallWatchBackoff(t *testing.T) {
	w, c := newStallWatchAt(time.Now())
	w.markConnected()
	w.observe(100, true)
	c.advance(stallWarmup + stallWindow)
	if !w.observe(100, true) {
		t.Fatal("the first stall must report")
	}
	// Inside the doubled backoff: suppressed.
	c.advance(stallBackoffBase)
	if w.observe(100, true) {
		t.Fatal("a stall inside the backoff must be suppressed")
	}
	c.advance(stallBackoffBase)
	if !w.observe(100, true) {
		t.Fatal("a stall past the backoff must report again")
	}
	// The backoff doubled again: twice the base is no longer enough.
	c.advance(2 * stallBackoffBase)
	if w.observe(100, true) {
		t.Fatal("the backoff must grow on consecutive stalls")
	}
	c.advance(2 * stallBackoffBase)
	if !w.observe(100, true) {
		t.Fatal("a stall past the grown backoff must report again")
	}
}

// A stall reconnect drops every flow, so the byte counters reset on the
// next tick. That reset must not relax the backoff: consecutive stalls
// without intervening traffic keep doubling, otherwise the loop
// protection degrades to a fixed cadence.
func TestStallWatchCounterResetKeepsBackoff(t *testing.T) {
	w, c := newStallWatchAt(time.Now())
	w.markConnected()
	w.observe(100, true)
	c.advance(stallWarmup + stallWindow)
	if !w.observe(100, true) {
		t.Fatal("the first stall must report")
	}
	// The stall reconnect dropped the flows: counters reset to zero.
	if w.observe(0, true) {
		t.Fatal("the post-reconnect counter reset must re-baseline, not report")
	}
	// The backoff doubled to 2m at the trigger and survived the reset:
	// one base interval of silence is not enough.
	c.advance(stallBackoffBase)
	if w.observe(0, true) {
		t.Fatal("the backoff must survive the post-reconnect counter reset")
	}
	c.advance(stallBackoffBase)
	if !w.observe(0, true) {
		t.Fatal("a stall past the surviving backoff must report again")
	}
}

// Traffic between stalls proves the tunnel alive and resets the backoff
// to the base.
func TestStallWatchProgressResetsBackoff(t *testing.T) {
	w, c := newStallWatchAt(time.Now())
	w.markConnected()
	w.observe(100, true)
	c.advance(stallWarmup + stallWindow)
	if !w.observe(100, true) {
		t.Fatal("the first stall must report")
	}
	// Bytes moved: the tunnel recovered, dropping the backoff to the
	// base. Without the reset the next stall would need 2m; with it,
	// the base 1m suffices.
	w.observe(101, true)
	c.advance(stallBackoffBase)
	if !w.observe(101, true) {
		t.Fatal("recovered traffic must reset the backoff to the base")
	}
	// ... and the backoff grows again from the base.
	c.advance(stallBackoffBase)
	if w.observe(101, true) {
		t.Fatal("the backoff must grow again after the reset")
	}
	c.advance(stallBackoffBase)
	if !w.observe(101, true) {
		t.Fatal("a stall past the grown backoff must report again")
	}
}

// stallFakeEngine adds per-connection visibility to fakeEngine so session
// tests can drive the stall detector end to end.
type stallFakeEngine struct {
	*fakeEngine
	mu        sync.Mutex
	conns     []engine.Connection
	closedAll int
}

func (f *stallFakeEngine) Connections(context.Context) ([]engine.Connection, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	return append([]engine.Connection(nil), f.conns...), nil
}

func (f *stallFakeEngine) CloseConnection(context.Context, string) error { return nil }

func (f *stallFakeEngine) CloseConnections(context.Context) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.closedAll++
	return nil
}

func (f *stallFakeEngine) closedAllCount() int {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.closedAll
}

func journalHasStall(s *Session) bool {
	for _, ev := range s.Journal().Since(0, 256) {
		if ev.Kind == EventError && ev.Key == errs.KeyEngineStalled {
			return true
		}
	}
	return false
}

// A stall must journal the event in the existing error style and reopen
// the flows through the shared reconnection mechanism, without moving the
// session out of connected: the engine process itself is healthy.
func TestSessionReopensFlowsOnStall(t *testing.T) {
	eng := &stallFakeEngine{
		fakeEngine: newFakeEngine(),
		conns:      []engine.Connection{{ID: "c1"}},
	}
	session, err := New(testConfig(eng, &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	clock := &manualClock{t: time.Now()}
	session.stall.now = clock.now
	if err := session.Start(context.Background()); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = session.Stop(context.Background()) }()

	// Baseline the detector at the current fake time first: the stall
	// window must be measured from live samples, not from a clock jump
	// the ticker has not observed yet.
	session.checkStall(context.Background())
	clock.advance(stallWarmup + stallWindow + time.Second)
	waitFor(t, 2*time.Second, func() bool { return eng.closedAllCount() > 0 })
	if !journalHasStall(session) {
		t.Fatal("the stall must be journaled as an error with the stalled key")
	}
	if state := session.State(); state != StateConnected {
		t.Fatalf("a stall reconnect must keep the session connected, got %s", state)
	}
}
