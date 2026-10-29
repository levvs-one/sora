package session

import (
	"context"
	"errors"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// sequence answers a fixed run of fingerprints, then keeps the last one.
func sequence(values ...string) func() string {
	var mu sync.Mutex
	return func() string {
		mu.Lock()
		defer mu.Unlock()
		v := values[0]
		if len(values) > 1 {
			values = values[1:]
		}
		return v
	}
}

func TestNetworkWatchSeesAnotherNetworkAndAReturn(t *testing.T) {
	// A move counts only after two consecutive polls agree on it.
	w := newNetworkWatch(sequence("wifi-a", "wifi-a", "wifi-b", "wifi-b", "wifi-b"), time.Hour)
	var got []string
	for range 4 {
		got = append(got, w.changed())
	}
	want := []string{"", "", "the network changed", ""}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("look %d = %q, want %q", i+1, got[i], want[i])
		}
	}
}

// TestNetworkWatchDebouncesAFlappingInterface: a transient
// fingerprint that flips back before confirmation must not renew
// connections.
func TestNetworkWatchDebouncesAFlappingInterface(t *testing.T) {
	w := newNetworkWatch(sequence("a", "b", "a", "b", "b"), time.Hour)
	var got []string
	for range 4 {
		got = append(got, w.changed())
	}
	// b, a, b: none confirmed. The final b,b pair confirms the move.
	want := []string{"", "", "", "the network changed"}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("look %d = %q, want %q", i+1, got[i], want[i])
		}
	}
}

func TestNetworkWatchSeesASleep(t *testing.T) {
	w := newNetworkWatch(sequence("wifi-a"), time.Second)
	// A sleep: an hour on the wall clock between two looks, none on the
	// monotonic one.
	w.lastWall = w.lastWall.Add(-time.Hour)
	if why := w.changed(); why != "the machine woke from sleep" {
		t.Errorf("after an hour away: %q", why)
	}
	if why := w.changed(); why != "" {
		t.Errorf("right after: %q", why)
	}
}

func TestALateLookIsNoSleep(t *testing.T) {
	w := newNetworkWatch(sequence("wifi-a"), time.Second)
	// A minute on both clocks: the session was busy, the machine was awake.
	w.lastWall = w.lastWall.Add(-time.Minute)
	w.lastMono = w.lastMono.Add(-time.Minute)
	if why := w.changed(); why != "" {
		t.Errorf("a late look counted as %q", why)
	}
}

func TestNetworkFingerprintLeavesOutLoopbackAndTheTunnel(t *testing.T) {
	fp := NetworkFingerprint()
	for _, unwanted := range []string{"127.0.0.1", engine.TunDevice + " "} {
		if strings.Contains(fp, unwanted) {
			t.Errorf("the fingerprint %q holds %q", fp, unwanted)
		}
	}
}

// trackingEngine is the fake engine that can also drop every connection.
type trackingEngine struct {
	*fakeEngine
	resets atomic.Int32
}

func (e *trackingEngine) Connections(context.Context) ([]engine.Connection, error) { return nil, nil }
func (e *trackingEngine) CloseConnection(context.Context, string) error            { return nil }
func (e *trackingEngine) CloseConnections(context.Context) error {
	e.resets.Add(1)
	return nil
}

func TestASessionDropsConnectionsWhenTheNetworkChanges(t *testing.T) {
	eng := &trackingEngine{fakeEngine: newFakeEngine()}
	cfg := testConfig(eng, &fakeGuard{})
	cfg.Network = sequence("wifi-a", "wifi-a", "wifi-b")
	cfg.NetworkInterval = 5 * time.Millisecond
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = s.Stop(context.Background()) })
	deadline := time.Now().Add(2 * time.Second)
	for eng.resets.Load() == 0 && time.Now().Before(deadline) {
		time.Sleep(5 * time.Millisecond)
	}
	if n := eng.resets.Load(); n != 1 {
		t.Errorf("connections were dropped %d times, want once", n)
	}
	if applies, _, _ := eng.counts(); applies != 1 {
		t.Errorf("the engine was applied %d times; an engine that can drop connections is not restarted", applies)
	}
}

func TestAnEngineThatCannotDropConnectionsStartsOver(t *testing.T) {
	eng := newFakeEngine()
	cfg := testConfig(eng, &fakeGuard{})
	cfg.Network = sequence("wifi-a", "wifi-b")
	cfg.NetworkInterval = 5 * time.Millisecond
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = s.Stop(context.Background()) })
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		if applies, _, _ := eng.counts(); applies >= 2 {
			return
		}
		time.Sleep(5 * time.Millisecond)
	}
	t.Error("the engine was not moved onto the plan again after the network changed")
}

// A failed restart must not leave a connected status when the engine is gone.
func TestFailedNetworkRenewalReportsFailureAndKeepsGuard(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	var moved atomic.Bool
	observed := make(chan struct{})
	var observedOnce sync.Once
	cfg := testConfig(eng, guard)
	cfg.Settings.KillSwitch = true
	cfg.NetworkInterval = 5 * time.Millisecond
	cfg.Network = func() string {
		if moved.Load() {
			return "wifi-b"
		}
		observedOnce.Do(func() { close(observed) })
		return "wifi-a"
	}
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = s.Stop(context.Background()) })
	select {
	case <-observed:
	case <-time.After(2 * time.Second):
		t.Fatal("network watcher did not establish its initial fingerprint")
	}
	eng.mu.Lock()
	eng.apply = errors.New("synthetic network renewal failure")
	eng.mu.Unlock()
	moved.Store(true)
	waitFor(t, 2*time.Second, func() bool { return s.State() == StateFailed })
	if status := s.Status(); status.Key != errs.KeyEngineStartFailed {
		t.Fatalf("failure key = %q, want %q", status.Key, errs.KeyEngineStartFailed)
	}
	select {
	case <-s.Done():
	case <-time.After(2 * time.Second):
		t.Fatal("supervision continued after the terminal renewal failure")
	}
	if !guard.Current().KillSwitch {
		t.Fatal("failed renewal released the kill switch before disconnect")
	}
	if err := s.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
	if guard.Current().KillSwitch {
		t.Fatal("disconnect did not restore the guard")
	}
}

type rejectedRenewalEngine struct {
	*fakeEngine
	attempts atomic.Int32
}

func (e *rejectedRenewalEngine) Apply(ctx context.Context, plan *engine.Plan) error {
	if e.attempts.Add(1) == 1 {
		return e.fakeEngine.Apply(ctx, plan)
	}
	// An error does not establish that the old engine is usable on the new path.
	return errors.New("synthetic renewal rejected")
}

func TestRejectedNetworkRenewalDoesNotRemainConnected(t *testing.T) {
	eng := &rejectedRenewalEngine{fakeEngine: newFakeEngine()}
	cfg := testConfig(eng, &fakeGuard{})
	cfg.Network = sequence("wifi-a", "wifi-b")
	cfg.NetworkInterval = 5 * time.Millisecond
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = s.Stop(context.Background()) })
	waitFor(t, 2*time.Second, func() bool { return s.State() == StateFailed })
	if eng.State() != engine.StateRunning {
		t.Fatal("test engine did not retain its previous running state")
	}
	if status := s.Status(); status.Key != errs.KeyEngineStartFailed {
		t.Fatalf("failure key = %q, want %q", status.Key, errs.KeyEngineStartFailed)
	}
}

type interruptibleRenewalEngine struct {
	*fakeEngine
	attempts atomic.Int32
	entered  chan struct{}
}

func (e *interruptibleRenewalEngine) Apply(ctx context.Context, plan *engine.Plan) error {
	if e.attempts.Add(1) == 1 {
		return e.fakeEngine.Apply(ctx, plan)
	}
	close(e.entered)
	<-ctx.Done()
	return ctx.Err()
}

func TestDisconnectDuringNetworkRenewalDoesNotReportFailure(t *testing.T) {
	eng := &interruptibleRenewalEngine{fakeEngine: newFakeEngine(), entered: make(chan struct{})}
	guard := &fakeGuard{}
	cfg := testConfig(eng, guard)
	cfg.Settings.KillSwitch = true
	cfg.Network = sequence("wifi-a", "wifi-b")
	cfg.NetworkInterval = 5 * time.Millisecond
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = s.Stop(context.Background()) })
	select {
	case <-eng.entered:
	case <-time.After(2 * time.Second):
		t.Fatal("network renewal did not begin")
	}
	if err := s.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
	select {
	case <-s.Done():
	case <-time.After(2 * time.Second):
		t.Fatal("supervision did not stop after disconnect")
	}
	if s.State() != StateDisconnected || guard.Current().KillSwitch {
		t.Fatal("disconnect did not restore the session and guard")
	}
	for _, event := range s.Journal().Since(0, 0) {
		if event.State == StateFailed || event.Kind == EventError {
			t.Fatalf("disconnect recorded a failure: %+v", event)
		}
	}
}

type interruptibleTracker struct {
	*fakeEngine
	entered chan struct{}
}

func (e *interruptibleTracker) Connections(context.Context) ([]engine.Connection, error) {
	return nil, nil
}
func (e *interruptibleTracker) CloseConnection(context.Context, string) error { return nil }
func (e *interruptibleTracker) CloseConnections(ctx context.Context) error {
	close(e.entered)
	<-ctx.Done()
	return ctx.Err()
}

func TestDisconnectDuringBulkCloseDoesNotRestartEngine(t *testing.T) {
	eng := &interruptibleTracker{fakeEngine: newFakeEngine(), entered: make(chan struct{})}
	cfg := testConfig(eng, &fakeGuard{})
	cfg.Network = sequence("wifi-a", "wifi-b")
	cfg.NetworkInterval = 5 * time.Millisecond
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = s.Stop(context.Background()) })
	select {
	case <-eng.entered:
	case <-time.After(2 * time.Second):
		t.Fatal("bulk connection close did not begin")
	}
	if err := s.Stop(context.Background()); err != nil {
		t.Fatal(err)
	}
	select {
	case <-s.Done():
	case <-time.After(2 * time.Second):
		t.Fatal("supervision did not stop after disconnect")
	}
	if applies, _, _ := eng.counts(); applies != 1 {
		t.Fatalf("engine applied %d times, want only the initial start", applies)
	}
	if s.State() != StateDisconnected {
		t.Fatalf("session state = %v, want disconnected", s.State())
	}
	for _, event := range s.Journal().Since(0, 0) {
		if event.State == StateFailed || event.Kind == EventError {
			t.Fatalf("disconnect recorded a failure: %+v", event)
		}
	}
}
