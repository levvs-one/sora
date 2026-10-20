package session

import (
	"context"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/censor"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// TestHandshakeAtSetOnStart: Start records the transport handshake time —
// the T017 age baseline. A session that never started has none.
func TestHandshakeAtSetOnStart(t *testing.T) {
	s, err := New(testConfig(newFakeEngine(), &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if !s.HandshakeAt().IsZero() {
		t.Fatal("HandshakeAt before Start must be zero")
	}
	ctx := context.Background()
	if err := s.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = s.Stop(ctx) }()
	if s.HandshakeAt().IsZero() {
		t.Fatal("HandshakeAt after Start must be set")
	}
}

// TestFrozenRecently pins the T017 §3.5 deferral: fresh interference
// verdicts defer a planned re-handshake; stale or benign verdicts do not.
func TestFrozenRecently(t *testing.T) {
	s, err := New(testConfig(newFakeEngine(), &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	now := time.Now()
	if frozenRecently(s, now) {
		t.Fatal("empty journal must not report recent interference")
	}
	appendVerdict := func(kind censor.Kind, at time.Time) {
		v := censor.Verdict{Kind: kind, At: at}
		s.Journal().Append(Event{Kind: EventCensor, Censor: &v})
	}
	appendVerdict(censor.KindNoInterference, now)
	if frozenRecently(s, now) {
		t.Fatal("no-interference verdict is not interference")
	}
	appendVerdict(censor.KindUnknown, now)
	if frozenRecently(s, now) {
		t.Fatal("unknown verdict is not interference")
	}
	appendVerdict(censor.KindSNIBlocking, now.Add(-10*time.Minute))
	if frozenRecently(s, now) {
		t.Fatal("a 10-minute-old verdict is outside the deferral window")
	}
	appendVerdict(censor.KindSNIBlocking, now.Add(-time.Minute))
	if !frozenRecently(s, now) {
		t.Fatal("a fresh SNI-blocking verdict must defer the re-handshake")
	}
}

// TestRehandshakeLoopDisabledNeverRuns: the zero policy is fail-closed —
// the worker exits immediately instead of ticking against a live session.
func TestRehandshakeLoopDisabledNeverRuns(t *testing.T) {
	m := NewManager(ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return newFakeEngine(), nil
		},
	})
	s, err := New(testConfig(newFakeEngine(), &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	done := make(chan struct{})
	go func() {
		m.rehandshakeLoop(s)
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("disabled re-handshake policy must exit at once")
	}
}

// TestRehandshakeSupersededTarget: restarting anything but the current
// session (or with no remembered plan) is refused.
func TestRehandshakeSupersededTarget(t *testing.T) {
	m := NewManager(ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) {
			return newFakeEngine(), nil
		},
	})
	s, err := New(testConfig(newFakeEngine(), &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := m.rehandshake(s); err == nil {
		t.Fatal("rehandshake without a remembered plan must fail")
	}
}

// TestWatcherFiresCensorshipHook: a published verdict reaches the hook
// with the failed server's id — the T042 trigger input.
func TestWatcherFiresCensorshipHook(t *testing.T) {
	s, err := New(testConfig(newFakeEngine(), &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	ctx := context.Background()
	if err := s.Start(ctx); err != nil {
		t.Fatalf("Start() error = %v", err)
	}
	defer func() { _ = s.Stop(ctx) }()

	type call struct {
		kind     censor.Kind
		serverID string
	}
	calls := make(chan call, 1)
	s.censorHook = func(v censor.Verdict, serverID string) {
		calls <- call{kind: v.Kind, serverID: serverID}
	}
	s.WatchCensorshipFailures(&censor.Detector{}, &censor.Prober{})
	// A refused connection is answered directly, without a probe.
	s.Journal().Append(Event{
		Kind:   EventError,
		Reason: errs.CodeUnavailable,
		Key:    errs.KeyConnectionRefused,
		Detail: "connection refused",
	})
	select {
	case c := <-calls:
		if c.kind != censor.KindNoInterference {
			t.Fatalf("hook kind = %v, want no_interference", c.kind)
		}
		if c.serverID != "out-1" {
			t.Fatalf("hook serverID = %q, want out-1 (the plan's first outbound)", c.serverID)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("hook did not fire on a published verdict")
	}
}
