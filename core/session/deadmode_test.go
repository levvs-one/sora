package session

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/censor"
	"github.com/levvs-one/sora-client/core/deadcheck"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// delayEngine overrides the engine's Delay primitive for dead-mode tests.
type delayEngine struct {
	engine.Engine
	delayFn func(ctx context.Context) (time.Duration, error)
}

func (e *delayEngine) Delay(ctx context.Context, _, _ string, _ time.Duration) (time.Duration, error) {
	return e.delayFn(ctx)
}

func deadSessionWithDelay(t *testing.T, fn func(ctx context.Context) (time.Duration, error)) *Session {
	t.Helper()
	base := newFakeEngine()
	s, err := New(testConfig(&delayEngine{Engine: base, delayFn: fn}, &fakeGuard{}))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return s
}

func TestPayloadProbeAlive(t *testing.T) {
	s := deadSessionWithDelay(t, func(context.Context) (time.Duration, error) {
		return 40 * time.Millisecond, nil
	})
	n, err := s.payloadProbe(context.Background())
	if err != nil || n <= 0 {
		t.Fatalf("probe = %d, %v; want payload flowed", n, err)
	}
	v := deadcheck.DetectDeadSession(context.Background(), deadcheck.DeadSessionInput{Probe: s.payloadProbe})
	if v.State != deadcheck.SessionAlive {
		t.Fatalf("verdict = %v, want alive", v.State)
	}
}

func TestPayloadProbeTimeoutIsNoTraffic(t *testing.T) {
	s := deadSessionWithDelay(t, func(ctx context.Context) (time.Duration, error) {
		<-ctx.Done() // the engine call consumes the whole budget
		return 0, ctx.Err()
	})
	v := deadcheck.DetectDeadSession(context.Background(), deadcheck.DeadSessionInput{
		Probe:   s.payloadProbe,
		Timeout: 200 * time.Millisecond,
	})
	if v.State != deadcheck.SessionNoTraffic {
		t.Fatalf("verdict = %v, want no_traffic (connected but dead)", v.State)
	}
}

func TestPayloadProbeEngineErrorIsUnknown(t *testing.T) {
	s := deadSessionWithDelay(t, func(context.Context) (time.Duration, error) {
		return 0, errors.New("controller exploded")
	})
	v := deadcheck.DetectDeadSession(context.Background(), deadcheck.DeadSessionInput{
		Probe:   s.payloadProbe,
		Timeout: time.Second,
	})
	if v.State != deadcheck.SessionUnknown {
		t.Fatalf("verdict = %v, want unknown: an engine error must not blame the network", v.State)
	}
}

func TestDeadRecentlyWindow(t *testing.T) {
	s := deadSessionWithDelay(t, func(context.Context) (time.Duration, error) { return 0, nil })
	now := time.Now()
	if s.deadRecently(now) {
		t.Fatal("no verdict yet: must not read as dead")
	}
	s.noteDead(now)
	if !s.deadRecently(now.Add(time.Minute)) {
		t.Fatal("a fresh no-traffic verdict must read as dead-mode")
	}
	if !s.DeadMode() {
		t.Fatal("DeadMode must reflect a fresh verdict")
	}
	if s.deadRecently(now.Add(deadFreshWindow + time.Minute)) {
		t.Fatal("a stale verdict must stop deferring")
	}
	s.clearDead()
	if s.deadRecently(now) {
		t.Fatal("a cleared verdict must not read as dead")
	}
}

func TestManagerSharesShutdownDetector(t *testing.T) {
	manager, _ := testManager(t, &fakeGuard{})
	if manager.shutdown == nil {
		t.Fatal("the manager must own the shared shutdown classifier")
	}
	ctx := context.Background()
	s, err := manager.Connect(ctx, testPlan("session-shutdown"), Settings{})
	if err != nil {
		t.Fatalf("Connect() error = %v", err)
	}
	defer func() { _ = manager.Disconnect(ctx) }()
	if s.shutdownDet != manager.shutdown {
		t.Fatal("the session must carry the manager-shared classifier")
	}
}

// hardDownAttempt is a recorded direct-path attempt whose SYN died
// silently — the shutdown tally's raw material.
func hardDownAttempt(host string) censor.Attempt {
	now := time.Now()
	return censor.Attempt{
		Target:    censor.Target{Host: host, Port: 443},
		StartedAt: now,
		Events: []censor.Event{
			{At: now, Stage: censor.StageDNS, What: censor.WhatResolved, Detail: "192.0.2.1"},
			{At: now, Stage: censor.StageTCP, What: censor.WhatLocalTimeout},
		},
	}
}

// TestWatcherPublishesShutdownWithoutExpedite: with two hard-down
// destinations already tallied and the session's own probe attempt also
// hard-down, the watcher must name the network mode and must NOT fire
// the censorship hook — refreshing subscriptions under a shutdown is a
// retry storm, not a strategy (T047). The probe comes from a recorded
// attempt: the sandbox's transparent proxy accepts every TCP connect,
// so a live network probe cannot produce this evidence here.
func TestWatcherPublishesShutdownWithoutExpedite(t *testing.T) {
	plan := testPlan("session-shutdown-mode")
	plan.Outbounds[0].Server = "dead.example"
	plan.Outbounds[0].Port = 443

	cfg := testConfig(newFakeEngine(), &fakeGuard{})
	cfg.Plan = plan
	s, err := New(cfg)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	det := censor.NewShutdownDetector()
	for _, host := range []string{"seed-a.example", "seed-b.example"} {
		det.Observe(hardDownAttempt(host))
	}
	s.shutdownDet = det
	s.censorProbeFn = func(_ context.Context, tgt censor.Target) censor.Attempt {
		return hardDownAttempt(tgt.Host)
	}
	hookFired := false
	s.censorHook = func(censor.Verdict, string) { hookFired = true }

	// No Start: the watcher reacts to journal events only and needs no
	// running session — same pattern as the other watcher tests.
	s.WatchCensorshipFailures(&censor.Detector{}, &censor.Prober{})
	cursor := s.Journal().Latest()
	s.Journal().Append(Event{
		Kind:   EventError,
		Reason: errs.CodeTimeout,
		Key:    errs.KeyNetworkTimeout,
		Detail: "dial timeout",
	})
	ev := waitForCensorEvent(t, s, cursor, 20*time.Second)
	if !strings.Contains(ev.Detail, "network mode") {
		t.Fatalf("verdict detail = %q, want a network-mode verdict", ev.Detail)
	}
	if !strings.Contains(ev.Detail, "Nothing reaches the network") {
		t.Fatalf("verdict detail = %q, want the shutdown explanation", ev.Detail)
	}
	if hookFired {
		t.Fatal("the T042 expedite hook must not fire under a shutdown verdict")
	}
}
