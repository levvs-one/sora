package ext

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

func errKey(t *testing.T, err error) errs.Key {
	t.Helper()
	e := &errs.Error{}
	ok := errors.As(err, &e)
	if !ok {
		t.Fatalf("want *errs.Error, got %T (%v)", err, err)
	}
	return e.Key()
}

func TestWaitWhilePausedBlocksAndResumes(t *testing.T) {
	s := NewScheduler(nil)
	s.SetKillSwitch(true)
	if !s.Paused() {
		t.Fatal("Paused must be true after SetKillSwitch(true)")
	}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	done := make(chan bool, 1)
	go func() { done <- s.waitWhilePaused(ctx) }()
	select {
	case <-done:
		t.Fatal("waitWhilePaused returned while paused")
	case <-time.After(100 * time.Millisecond):
	}
	s.SetKillSwitch(false)
	select {
	case ok := <-done:
		if !ok {
			t.Fatal("waitWhilePaused must return true on resume")
		}
	case <-time.After(2 * time.Second):
		t.Fatal("waitWhilePaused did not wake on resume")
	}
	if s.Paused() {
		t.Fatal("Paused must be false after SetKillSwitch(false)")
	}
}

func TestWaitWhilePausedCtxCancel(t *testing.T) {
	s := NewScheduler(nil)
	s.SetKillSwitch(true)
	defer s.SetKillSwitch(false)
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan bool, 1)
	go func() { done <- s.waitWhilePaused(ctx) }()
	time.Sleep(50 * time.Millisecond)
	cancel() // e.g. Unregister while a loop waits out the pause
	select {
	case ok := <-done:
		if ok {
			t.Fatal("waitWhilePaused must return false when the context ends")
		}
	case <-time.After(2 * time.Second):
		t.Fatal("waitWhilePaused did not return on context cancel")
	}
}

func TestSetKillSwitchAbortsInflightRun(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 60)
	started := make(chan struct{})
	var once sync.Once
	run := func(ctx context.Context, _ *WorkerEnv) error {
		once.Do(func() { close(started) })
		<-ctx.Done()
		return ctx.Err()
	}
	if err := s.Register(m, x, run); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	done := make(chan struct{})
	go func() {
		defer close(done)
		s.runOnce(task)
	}()
	select {
	case <-started:
	case <-time.After(2 * time.Second):
		t.Fatal("run did not start")
	}
	s.SetKillSwitch(true)
	defer s.SetKillSwitch(false)
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("in-flight run was not aborted by the pause")
	}
	if n := task.fails.Load(); n != 0 {
		t.Fatalf("interrupted run counted toward the circuit breaker: fails=%d", n)
	}
	if got := logText(s, m.ID); !strings.Contains(got, "interrupted by the kill-switch pause") {
		t.Fatalf("want an interruption log line, got:\n%s", got)
	}
}

func TestSetKillSwitchIdempotent(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 60)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	s.SetKillSwitch(true)
	s.SetKillSwitch(true) // no-op, must not deadlock or double-close
	if !s.Paused() {
		t.Fatal("still paused")
	}
	s.SetKillSwitch(false)
	s.SetKillSwitch(false) // no-op
	if s.Paused() {
		t.Fatal("still resumed")
	}
}

func TestStopWhilePaused(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 60)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	s.Start(context.Background())
	s.SetKillSwitch(true)
	done := make(chan struct{})
	go func() {
		defer close(done)
		s.Stop()
	}()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("Stop hung while a ticker loop waited out the pause")
	}
}

func TestFetchPausedFailsFast(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 60)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	if task.fetcher == nil {
		t.Fatal("bg pair must build a fetcher")
	}
	var hits atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		hits.Add(1)
	}))
	defer srv.Close()

	s.SetKillSwitch(true)
	_, err := task.fetcher.Fetch(context.Background(), FetchRequest{Method: "GET", URL: srv.URL + "/x"})
	if err == nil {
		t.Fatal("fetch must fail while paused")
	}
	if k := errKey(t, err); k != KeyNetFetchPaused {
		t.Fatalf("error key = %q, want %q", k, KeyNetFetchPaused)
	}
	if codeOf(t, err) != errs.CodeUnavailable {
		t.Fatalf("paused fetch must be CodeUnavailable, got %v", codeOf(t, err))
	}
	if hits.Load() != 0 {
		t.Fatalf("paused fetch attempted %d requests", hits.Load())
	}
	if got := logText(s, m.ID); !strings.Contains(got, "kill switch paused background network") {
		t.Fatalf("want a pause audit line, got:\n%s", got)
	}

	s.SetKillSwitch(false)
	// The gate is lifted: the request now proceeds to normal policy checks
	// (the plain-http test URL is rejected by the https-only rule - the
	// point is it is no longer the pause that refuses it).
	_, err = task.fetcher.Fetch(context.Background(), FetchRequest{Method: "GET", URL: srv.URL + "/x"})
	if err == nil {
		t.Fatal("plain http must still be rejected after resume")
	}
	if k := errKey(t, err); k == KeyNetFetchPaused {
		t.Fatal("pause key must be gone after resume")
	}
	if hits.Load() != 0 {
		t.Fatalf("no request may reach the network: hits=%d", hits.Load())
	}
}

func TestStandaloneFetcherNeverPauses(t *testing.T) {
	// Fetchers built outside the scheduler have no pause gate wired: their
	// behavior is unchanged.
	m, x := bgPair(t, 60)
	f, err := NewFetcherForExtension(m.ID, x, FetchLimits{}, NewLogHub())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := f.Fetch(context.Background(), FetchRequest{URL: "http://example.com/"}); err == nil {
		t.Fatal("http must be rejected by policy")
	} else if k := errKey(t, err); k == KeyNetFetchPaused {
		t.Fatal("standalone fetcher must not report the pause key")
	}
}

func TestWaitWhilePausedRePauseBeforeWakeup(t *testing.T) {
	// A tick that fires during pause #1 must not start a run when a
	// resume→re-pause toggle lands before the waiter is scheduled: the
	// wakeup on the closed first channel must be re-checked against the
	// current pause state.
	s := NewScheduler(nil)
	// Warmup: shake off cold-start goroutine scheduling latency so the
	// settle sleep below reliably means "the waiter is blocked".
	s.SetKillSwitch(true)
	warmCtx, warmCancel := context.WithCancel(context.Background())
	warmDone := make(chan bool, 1)
	go func() { warmDone <- s.waitWhilePaused(warmCtx) }()
	time.Sleep(200 * time.Millisecond)
	s.SetKillSwitch(false)
	select {
	case <-warmDone:
	case <-time.After(2 * time.Second):
		t.Fatal("warmup waiter did not wake on resume")
	}
	warmCancel()

	s.SetKillSwitch(true)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	done := make(chan bool, 1)
	go func() { done <- s.waitWhilePaused(ctx) }()
	time.Sleep(200 * time.Millisecond) // let the waiter block on the pause channel
	s.SetKillSwitch(false)
	s.SetKillSwitch(true) // re-pause before the waiter wakes
	select {
	case ok := <-done:
		t.Fatalf("waitWhilePaused returned %v during the second pause; a tick must not start a run while the kill switch is active", ok)
	case <-time.After(200 * time.Millisecond):
	}
	s.SetKillSwitch(false)
	select {
	case ok := <-done:
		if !ok {
			t.Fatal("waitWhilePaused must return true after the final resume")
		}
	case <-time.After(2 * time.Second):
		t.Fatal("waitWhilePaused did not wake on the final resume")
	}
	if s.Paused() {
		t.Fatal("Paused must be false after the final resume")
	}
}

func TestKillSwitchToggleRace(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 60)
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	s.Start(context.Background())
	defer s.Stop()
	var wg sync.WaitGroup
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			for j := 0; j < 25; j++ {
				s.SetKillSwitch((i+j)%2 == 0)
				_ = s.Paused()
				// Direct runOnce while toggling: must never race on the
				// pause state, the task fields, or the fetcher gate.
				s.runOnce(task)
				_, _ = task.fetcher.Fetch(context.Background(),
					FetchRequest{Method: "GET", URL: "https://api.example.com/"})
			}
		}(i)
	}
	wg.Wait()
	s.SetKillSwitch(false)
}
