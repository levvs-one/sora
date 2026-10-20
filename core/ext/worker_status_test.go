package ext

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

// blockingRun returns a WorkerFunc that signals it started and then waits
// for its context to end, like a well-behaved worker stuck on I/O.
func blockingRun(started chan<- struct{}) WorkerFunc {
	return func(ctx context.Context, _ *WorkerEnv) error {
		close(started)
		<-ctx.Done()
		return ctx.Err()
	}
}

func TestUnregisterAbortsInflightRun(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	started := make(chan struct{})
	if err := s.Register(m, x, blockingRun(started)); err != nil {
		t.Fatal(err)
	}
	s.Start(context.Background())
	defer s.Stop()
	task, _ := s.Task(m.ID)
	done := make(chan struct{})
	go func() { defer close(done); s.runOnce(task) }()
	select {
	case <-started:
	case <-time.After(2 * time.Second):
		t.Fatal("run did not start")
	}
	s.Unregister(m.ID)
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("in-flight run was not aborted by Unregister")
	}
	if n := task.fails.Load(); n != 0 {
		t.Fatalf("run aborted by Unregister counted toward the circuit breaker: fails=%d", n)
	}
	if !task.hasRun.Load() || !task.lastRunInterrupted.Load() || task.lastRunOK.Load() {
		t.Fatal("aborted run must be recorded as interrupted, not ok, not missing")
	}
	if got := logText(s, m.ID); !strings.Contains(got, "interrupted: the task was stopped") {
		t.Fatalf("want a stopped-interruption log line, got:\n%s", got)
	}
}

func TestSchedulerStopAbortsInflightRun(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	started := make(chan struct{})
	if err := s.Register(m, x, blockingRun(started)); err != nil {
		t.Fatal(err)
	}
	s.Start(context.Background())
	task, _ := s.Task(m.ID)
	done := make(chan struct{})
	go func() { defer close(done); s.runOnce(task) }()
	select {
	case <-started:
	case <-time.After(2 * time.Second):
		t.Fatal("run did not start")
	}
	stopped := make(chan struct{})
	go func() { defer close(stopped); s.Stop() }()
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("in-flight run was not aborted by Stop")
	}
	select {
	case <-stopped:
	case <-time.After(2 * time.Second):
		t.Fatal("Stop hung behind the in-flight run")
	}
	if n := task.fails.Load(); n != 0 {
		t.Fatalf("run aborted by Stop counted toward the circuit breaker: fails=%d", n)
	}
}

func TestWorkerStatusSnapshot(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	fail := false
	run := func(_ context.Context, _ *WorkerEnv) error {
		if fail {
			return errors.New("kaput")
		}
		return nil
	}
	if err := s.Register(m, x, run); err != nil {
		t.Fatal(err)
	}
	st, ok := s.Status(m.ID)
	if !ok {
		t.Fatal("status of a registered task must exist")
	}
	if st.ExtensionID != m.ID || st.Entry != "worker.js" || st.Interval != 30*time.Minute {
		t.Fatalf("identity fields wrong: %+v", st)
	}
	if st.Disabled || st.Running || st.Paused || st.HasRun || st.ConsecutiveFailures != 0 {
		t.Fatalf("fresh task must be idle with no runs: %+v", st)
	}
	if st.Fetch == nil {
		t.Fatal("a task granted net.fetch must expose fetch stats")
	}
	if _, ok := s.Status("com.example.absent"); ok {
		t.Fatal("status of an unknown task must report ok=false")
	}

	task, _ := s.Task(m.ID)
	s.runOnce(task)
	st, _ = s.Status(m.ID)
	if !st.HasRun || !st.LastRunOK || st.LastRunInterrupted || st.LastRunAt.IsZero() {
		t.Fatalf("after a successful run: %+v", st)
	}
	fail = true
	s.runOnce(task)
	st, _ = s.Status(m.ID)
	if !st.HasRun || st.LastRunOK || st.LastRunInterrupted || st.ConsecutiveFailures != 1 {
		t.Fatalf("after a failed run: %+v", st)
	}

	s.SetKillSwitch(true)
	st, _ = s.Status(m.ID)
	if !st.Paused {
		t.Fatal("status must report the kill-switch pause")
	}
	s.SetKillSwitch(false)
}

func TestWorkerStatusDisabledAndSorted(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 30)
	cfg := BackgroundDefaults(x)
	cfg.Enabled = false
	if err := s.RegisterConfig(m, x, cfg, okRun); err != nil {
		t.Fatal(err)
	}
	m2 := bgManifest(t)
	m2.ID = "com.example.aaa"
	raw := rawManifestWith(t, m2, map[string]any{
		"background_task": map[string]any{"interval_minutes": 45, "entry": "worker.js"},
		"network_hosts":   []string{"api.example.com"},
	})
	pm, px, err := ParseManifestFull(raw)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Register(pm, px, okRun); err != nil {
		t.Fatal(err)
	}
	st, ok := s.Status(m.ID)
	if !ok || !st.Disabled {
		t.Fatalf("user-disabled task must report Disabled: %+v ok=%v", st, ok)
	}
	all := s.Statuses()
	if len(all) != 2 || all[0].ExtensionID != "com.example.aaa" || all[1].ExtensionID != m.ID {
		t.Fatalf("Statuses must be sorted by id: %+v", all)
	}
}
