package ext

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// bgPair builds a manifest + ext pair declaring a background task.
func bgPair(t *testing.T, minutes int) (*Manifest, *ManifestExt) {
	t.Helper()
	raw := rawManifestWith(t, bgManifest(t), map[string]any{
		"background_task": map[string]any{"interval_minutes": minutes, "entry": "worker.js"},
		"network_hosts":   []string{"api.example.com"},
	})
	m, x, err := ParseManifestFull(raw)
	if err != nil {
		t.Fatal(err)
	}
	return m, x
}

func okRun(ctx context.Context, env *WorkerEnv) error {
	env.Logf("worker did its thing")
	return nil
}

func TestRegisterClampsIntervalTo15Min(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 1) // 1 minute declared: must clamp to 15
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatalf("Register: %v", err)
	}
	task, ok := s.Task(m.ID)
	if !ok {
		t.Fatal("task not registered")
	}
	if task.Interval != MinWorkerInterval {
		t.Fatalf("interval = %s, want %s (clamped)", task.Interval, MinWorkerInterval)
	}
}

func TestRegisterHonorsDeclaredInterval(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 120)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatalf("Register: %v", err)
	}
	task, _ := s.Task(m.ID)
	if task.Interval != 2*time.Hour {
		t.Fatalf("interval = %s, want 2h", task.Interval)
	}
}

func TestRegisterRequiresCapabilityAndPermission(t *testing.T) {
	s := NewScheduler(nil)
	_, x := bgPair(t, 30)

	noCap := bgManifest(t)
	noCap.Capabilities = []string{"ui-panel"}
	if err := s.Register(noCap, x, okRun); err == nil {
		t.Fatal("register without the background capability must fail")
	} else if codeOf(t, err) != errs.CodeInvalidArgument {
		t.Fatalf("want invalid_argument, got %v", err)
	}

	noPerm := bgManifest(t)
	noPerm.Permissions = []string{"net.fetch"}
	if err := s.Register(noPerm, x, okRun); err == nil {
		t.Fatal("register without the background permission must fail")
	} else if codeOf(t, err) != errs.CodePermissionDenied {
		t.Fatalf("want permission_denied, got %v", err)
	}

	if err := s.Register(bgManifest(t), &ManifestExt{}, okRun); err == nil {
		t.Fatal("register without a background_task must fail")
	}
	if err := s.Register(bgManifest(t), nil, okRun); err == nil {
		t.Fatal("register with nil ext must fail")
	}
}

func TestWorkerRunLogsSuccess(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	s.runOnce(task)

	var msgs []string
	for _, e := range s.Hub().Log(m.ID).Entries() {
		msgs = append(msgs, e.Message)
	}
	joined := strings.Join(msgs, "\n")
	if !strings.Contains(joined, "worker did its thing") {
		t.Fatalf("worker log output missing: %q", joined)
	}
	if !strings.Contains(joined, "run ok") {
		t.Fatalf("run-ok outcome missing: %q", joined)
	}
}

func TestWorkerRunLogsFailure(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	boom := errors.New("kaput")
	if err := s.Register(m, x, func(ctx context.Context, env *WorkerEnv) error { return boom }); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	s.runOnce(task)

	found := false
	for _, e := range s.Hub().Log(m.ID).Entries() {
		if e.Level == LogError && strings.Contains(e.Message, "kaput") {
			found = true
		}
	}
	if !found {
		t.Fatal("failed run must be logged as an error with the reason")
	}
}

func TestWorkerRunRecoversPanic(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	if err := s.Register(m, x, func(ctx context.Context, env *WorkerEnv) error {
		panic("exploded")
	}); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	func() {
		defer func() {
			if r := recover(); r != nil {
				t.Fatalf("panic escaped runOnce: %v", r)
			}
		}()
		s.runOnce(task)
	}()

	found := false
	for _, e := range s.Hub().Log(m.ID).Entries() {
		if e.Level == LogError && strings.Contains(e.Message, "panicked") {
			found = true
		}
	}
	if !found {
		t.Fatal("panicking run must be recovered and logged")
	}
}

func TestWorkerEnvFetchNeedsNetFetchPermission(t *testing.T) {
	s := NewScheduler(nil)
	m := bgManifest(t)
	m.Permissions = []string{"background"} // no net.fetch
	raw := rawManifestWith(t, m, map[string]any{
		"background_task": map[string]any{"interval_minutes": 30, "entry": "worker.js"},
	})
	pm, px, err := ParseManifestFull(raw)
	if err != nil {
		t.Fatal(err)
	}
	var envSeen *WorkerEnv
	if err := s.Register(pm, px, func(ctx context.Context, env *WorkerEnv) error {
		envSeen = env
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(pm.ID)
	s.runOnce(task)
	if envSeen == nil {
		t.Fatal("worker did not run")
	}
	if _, err := envSeen.Fetch(context.Background(), FetchRequest{URL: "https://api.example.com/"}); err == nil {
		t.Fatal("worker fetch without the net.fetch permission must fail closed")
	} else if codeOf(t, err) != errs.CodePermissionDenied {
		t.Fatalf("want permission_denied, got %v", err)
	}
}

func TestSchedulerUnregister(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	s.Unregister(m.ID)
	if _, ok := s.Task(m.ID); ok {
		t.Fatal("task must be gone after Unregister")
	}
}

func TestSchedulerStartStop(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	s.Start(ctx)
	s.Start(ctx) // idempotent
	cancel()
	s.Stop()
	s.Stop() // idempotent
}

func TestExtLogBounded(t *testing.T) {
	hub := NewLogHub()
	l := hub.Log("x")
	for i := 0; i < MaxLogEntries+50; i++ {
		l.Append(LogInfo, "line")
	}
	if l.Len() != MaxLogEntries {
		t.Fatalf("log holds %d entries, want cap %d", l.Len(), MaxLogEntries)
	}
	l.Append(LogInfo, strings.Repeat("z", MaxLogMessage+100))
	last := l.Entries()[len(l.Entries())-1]
	if len(last.Message) > MaxLogMessage {
		t.Fatalf("message not truncated: %d", len(last.Message))
	}
	hub.Drop("x")
	if hub.Log("x").Len() != 0 {
		t.Fatal("Drop must forget the log")
	}
}

func TestUnregisterStopsTaskLoop(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	s.Start(context.Background())
	defer s.Stop()
	task, ok := s.Task(m.ID)
	if !ok {
		t.Fatal("task not registered")
	}
	if task.ctx == nil {
		t.Fatal("running task must own a loop context")
	}
	s.Unregister(m.ID)
	select {
	case <-task.ctx.Done():
	case <-time.After(2 * time.Second):
		t.Fatal("task ticker loop was not stopped by Unregister")
	}
}

func TestRegisterReplacesTaskStopsOldLoop(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	s.Start(context.Background())
	defer s.Stop()
	old, _ := s.Task(m.ID)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	select {
	case <-old.ctx.Done():
	case <-time.After(2 * time.Second):
		t.Fatal("replaced task's ticker loop kept running: two loops would fire")
	}
	cur, _ := s.Task(m.ID)
	if cur == old {
		t.Fatal("expected a new task struct after re-register")
	}
	select {
	case <-cur.ctx.Done():
		t.Fatal("the replacement task's loop must keep running")
	default:
	}
}

func TestWorkerRunSkipsOverlap(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	entered := make(chan struct{})
	release := make(chan struct{})
	var calls atomic.Int32
	run := func(ctx context.Context, env *WorkerEnv) error {
		if calls.Add(1) == 1 {
			close(entered)
			<-release // hold the first run open
		}
		return nil
	}
	if err := s.Register(m, x, run); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)

	done := make(chan struct{})
	go func() { s.runOnce(task); close(done) }()
	<-entered       // first run is now in flight
	s.runOnce(task) // must skip, not pile up
	close(release)
	<-done

	if calls.Load() != 1 {
		t.Fatalf("overlapping run executed: calls = %d, want 1", calls.Load())
	}
	found := false
	for _, e := range s.Hub().Log(m.ID).Entries() {
		if e.Level == LogWarn && strings.Contains(e.Message, "still in flight") {
			found = true
		}
	}
	if !found {
		t.Fatal("skipped overlapping run must be logged as a warning")
	}
}

func TestWorkerCircuitBreakerStopsAfterConsecutiveFailures(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	boom := errors.New("always broken")
	if err := s.Register(m, x, func(ctx context.Context, env *WorkerEnv) error { return boom }); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	for i := 0; i < maxConsecutiveWorkerFailures; i++ {
		s.runOnce(task)
	}
	if _, ok := s.Task(m.ID); ok {
		t.Fatalf("task must be unregistered after %d consecutive failures", maxConsecutiveWorkerFailures)
	}
	found := false
	for _, e := range s.Hub().Log(m.ID).Entries() {
		if e.Level == LogError && strings.Contains(e.Message, "consecutive failures") {
			found = true
		}
	}
	if !found {
		t.Fatal("circuit breaker trip must be logged as an error")
	}
}

func TestWorkerFailureCounterResetsOnSuccess(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	fail := true
	if err := s.Register(m, x, func(ctx context.Context, env *WorkerEnv) error {
		if fail {
			return errors.New("kaput")
		}
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	s.runOnce(task) // 1 failure
	fail = false
	s.runOnce(task) // success resets the counter
	if task.fails.Load() != 0 {
		t.Fatalf("fails = %d after a successful run, want 0", task.fails.Load())
	}
	fail = true
	for i := 0; i < maxConsecutiveWorkerFailures-1; i++ {
		s.runOnce(task)
	}
	if _, ok := s.Task(m.ID); !ok {
		t.Fatal("task must survive: the counter was reset by the success in the middle")
	}
}

func TestSchedulerFetchTransportHook(t *testing.T) {
	s := NewScheduler(nil)
	sentinel := &http.Transport{}
	s.SetFetchTransport(func(extensionID string) http.RoundTripper {
		if extensionID != "com.example.hello" {
			t.Errorf("hook got extension %q", extensionID)
		}
		return sentinel
	})
	m, x := bgPair(t, 30) // bgPair's manifest holds the net.fetch permission
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	if task.fetcher == nil {
		t.Fatal("task with the net.fetch permission must own a fetcher")
	}
	if task.fetcher.client.Transport != sentinel {
		t.Fatal("scheduler must wire the configured transport into the worker fetcher")
	}
}

func TestSchedulerDefaultFetchTransportIsDirect(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	if task.fetcher.client.Transport != http.DefaultTransport {
		t.Fatal("without a hook the fetcher must dial direct (dev/test default)")
	}
}
