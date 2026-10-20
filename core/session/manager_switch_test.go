package session

import (
	"context"
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// switchGuard is a Guard that models the physical kill-switch block and
// implements BlockHolder the way core/guard.Guard does: a Restore under
// a hold clears ownership but leaves the block in force, and releasing
// the last hold drops the block only when no session re-applied it. It
// records every transition so switch tests can prove there was never a
// moment with the block down while a hold was outstanding.
type switchGuard struct {
	mu             sync.Mutex
	current        Settings
	blocked        bool
	holds          int
	seq            []string
	violated       bool
	applyFailures  int
	applyErr       error
	restoreEr      error
	blockedProbeEr error
	releaseErr     error
}

func (g *switchGuard) setBlockedLocked(v bool) {
	if g.holds > 0 && !v {
		g.violated = true
	}
	g.blocked = v
}

func (g *switchGuard) Apply(_ context.Context, s Settings) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.applyFailures > 0 {
		g.applyFailures--
		g.seq = append(g.seq, "apply-error")
		return errors.New("guard apply refused")
	}
	if g.applyErr != nil {
		return g.applyErr
	}
	g.current = s
	g.setBlockedLocked(s.KillSwitch)
	g.seq = append(g.seq, fmt.Sprintf("apply ks=%v blocked=%v", s.KillSwitch, g.blocked))
	return nil
}

func (g *switchGuard) Restore(context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	if g.restoreEr != nil {
		return g.restoreEr
	}
	if g.holds > 0 {
		g.current = Settings{}
		g.seq = append(g.seq, fmt.Sprintf("restore-held blocked=%v", g.blocked))
		return nil
	}
	g.current = Settings{}
	g.setBlockedLocked(false)
	g.seq = append(g.seq, "restore blocked=false")
	return nil
}

func (g *switchGuard) Current() Settings {
	g.mu.Lock()
	defer g.mu.Unlock()
	return g.current
}

func (g *switchGuard) Blocked(context.Context) (bool, error) {
	g.mu.Lock()
	defer g.mu.Unlock()
	return g.blocked, g.blockedProbeEr
}

func (g *switchGuard) Name() string { return "switch" }

func (g *switchGuard) HoldBlock(context.Context) (func(context.Context) error, error) {
	g.mu.Lock()
	g.holds++
	g.seq = append(g.seq, fmt.Sprintf("hold blocked=%v", g.blocked))
	g.mu.Unlock()
	var once sync.Once
	var relErr error
	return func(context.Context) error {
		once.Do(func() {
			g.mu.Lock()
			defer g.mu.Unlock()
			if g.holds > 0 {
				g.holds--
			}
			if g.holds == 0 && !g.current.KillSwitch {
				// Direct assignment, not setBlockedLocked: the hold is
				// being released, so dropping the block is the point.
				g.blocked = false
			}
			g.seq = append(g.seq, fmt.Sprintf("release blocked=%v", g.blocked))
			relErr = g.releaseErr
		})
		return relErr
	}, nil
}

func (g *switchGuard) snapshot() (seq []string, blocked, violated bool, holds int) {
	g.mu.Lock()
	defer g.mu.Unlock()
	return append([]string(nil), g.seq...), g.blocked, g.violated, g.holds
}

// switchRig builds a manager whose factory hands out a fresh fake
// engine per attempt, with per-plan, per-attempt Apply failures.
type switchRig struct {
	mu         sync.Mutex
	guard      *switchGuard
	manager    *Manager
	attempts   map[string]int
	applyErrs  map[string][]error // plan id -> error for attempt 1, 2, ... (nil = succeed)
	factoryErr map[string]error
	validateEr map[string]error
	engines    []*fakeEngine
}

func newSwitchRig() *switchRig {
	rig := &switchRig{
		guard:      &switchGuard{},
		attempts:   map[string]int{},
		applyErrs:  map[string][]error{},
		factoryErr: map[string]error{},
		validateEr: map[string]error{},
	}
	rig.manager = NewManager(ManagerConfig{
		Factory: func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
			rig.mu.Lock()
			defer rig.mu.Unlock()
			if err := rig.factoryErr[p.SessionID]; err != nil {
				return nil, err
			}
			eng := newFakeEngine()
			eng.validate = rig.validateEr[p.SessionID]
			attempt := rig.attempts[p.SessionID]
			rig.attempts[p.SessionID] = attempt + 1
			if errsForPlan := rig.applyErrs[p.SessionID]; attempt < len(errsForPlan) && errsForPlan[attempt] != nil {
				eng.apply = errsForPlan[attempt]
			}
			rig.engines = append(rig.engines, eng)
			return eng, nil
		},
		Guard: rig.guard,
	})
	return rig
}

func (r *switchRig) attemptCount(id string) int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.attempts[id]
}

var (
	errSwitchEngine   = errors.New("switch target engine refused to start")
	errRollbackEngine = errors.New("rollback engine refused to start")
)

// (a) The new engine's Apply fails after the previous session was
// stopped: the previous session is rebuilt and started from the
// remembered plan, the caller gets the original switch error, and the
// manager reports connected on the previous plan.
func TestManagerSwitchRollsBackWhenTheNewEngineWillNotStart(t *testing.T) {
	rig := newSwitchRig()
	rig.applyErrs["new"] = []error{errSwitchEngine}
	ctx := context.Background()
	first, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true})
	if err != nil {
		t.Fatal(err)
	}
	returned, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true})
	if !errors.Is(err, errSwitchEngine) {
		t.Fatalf("switch error = %v, want the original switch failure", err)
	}
	if returned != nil {
		t.Error("a failed switch returned a session together with the error")
	}
	current := rig.manager.Current()
	if current == nil {
		t.Fatal("the failed switch left no session: the previous one was not restored")
	}
	if current == first {
		t.Error("rollback restarted the stopped session object; sessions are single-use")
	}
	if current.ID() != "prev" || current.State() != StateConnected {
		t.Errorf("current = %s/%s, want prev/connected", current.ID(), current.State())
	}
	if status := rig.manager.Status(); status.State != StateConnected || status.SessionID != "prev" {
		t.Errorf("status = %s/%s, want connected/prev", status.State, status.SessionID)
	}
	found := false
	for _, ev := range current.Journal().Since(0, 64) {
		if ev.Kind == EventLog && strings.Contains(ev.LogLine, "rollback") {
			found = true
		}
	}
	if !found {
		t.Error("the restored session's journal has no rollback entry")
	}
	if err := rig.manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
}

// (a') Same rollback when the failure is the guard Apply inside the new
// session's Start, staged as a one-shot guard refusal so the rollback's
// own Apply can succeed.
func TestManagerSwitchRollsBackWhenTheNewGuardApplyFails(t *testing.T) {
	rig := newSwitchRig()
	ctx := context.Background()
	if _, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	rig.guard.mu.Lock()
	rig.guard.applyFailures = 1
	rig.guard.mu.Unlock()
	if _, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); errs.KeyOf(err) != errs.KeyGuardFirewallFail {
		t.Fatalf("switch error = %v, want the guard refusal", err)
	}
	current := rig.manager.Current()
	if current == nil || current.ID() != "prev" || current.State() != StateConnected {
		t.Fatalf("current = %v, want the previous session restored", current)
	}
	if err := rig.manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
}

// (b) Without a previous session there is nothing to roll back to: one
// factory attempt, no current session, the failure status stays.
func TestManagerFailedFirstConnectHasNoRollback(t *testing.T) {
	rig := newSwitchRig()
	rig.applyErrs["new"] = []error{errSwitchEngine, errSwitchEngine}
	if _, err := rig.manager.Connect(context.Background(), testPlan("new"), Settings{KillSwitch: true}); !errors.Is(err, errSwitchEngine) {
		t.Fatalf("Connect() = %v", err)
	}
	if rig.attemptCount("new") != 1 {
		t.Errorf("factory attempts = %d, want 1 (no rollback without a previous session)", rig.attemptCount("new"))
	}
	if rig.manager.Current() != nil {
		t.Error("a failed first connect left a current session")
	}
	if status := rig.manager.Status(); status.State != StateFailed {
		t.Errorf("status = %s, want failed", status.State)
	}
}

// (c) The rollback itself fails: the caller still gets the original
// switch error (never the rollback's) and no session is current.
func TestManagerSwitchReturnsTheOriginalErrorWhenRollbackFails(t *testing.T) {
	rig := newSwitchRig()
	rig.applyErrs["new"] = []error{errSwitchEngine}
	rig.applyErrs["prev"] = []error{nil, errRollbackEngine} // first connect ok, rollback attempt fails
	ctx := context.Background()
	if _, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	_, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true})
	if !errors.Is(err, errSwitchEngine) || errors.Is(err, errRollbackEngine) {
		t.Fatalf("switch error = %v, want only the original switch failure", err)
	}
	if rig.manager.Current() != nil {
		t.Error("a failed rollback left a current session")
	}
	if status := rig.manager.Status(); status.State != StateFailed {
		t.Errorf("status = %s, want failed", status.State)
	}
	_, blocked, _, _ := rig.guard.snapshot()
	if blocked {
		t.Error("the block stayed up after a failed switch with no session running")
	}
}

// (d) Factory and Validate failures of the replacement never touch the
// running session — the existing behaviour, pinned against the new
// rollback/hold code paths (no stop, no hold, no rollback attempt).
func TestManagerSwitchBuildFailuresKeepThePreviousSession(t *testing.T) {
	rig := newSwitchRig()
	rig.factoryErr["bad-factory"] = errs.Newf(errs.CodeNotFound, errs.KeyEngineBinaryMissing, "no engine")
	rig.validateEr["bad-validate"] = errors.New("invalid replacement configuration")
	ctx := context.Background()
	first, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = rig.manager.Disconnect(ctx) })
	for _, id := range []string{"bad-factory", "bad-validate"} {
		if _, err := rig.manager.Connect(ctx, testPlan(id), Settings{KillSwitch: true}); err == nil {
			t.Fatalf("switch to %s succeeded", id)
		}
		if rig.manager.Current() != first || first.State() != StateConnected {
			t.Fatalf("a rejected switch to %s lost the running session", id)
		}
	}
	seq, _, _, _ := rig.guard.snapshot()
	for _, entry := range seq {
		if strings.HasPrefix(entry, "hold") || strings.HasPrefix(entry, "restore") {
			t.Errorf("a build failure touched the guard: %q in %v", entry, seq)
		}
	}
}

// Rollback also works with a guard that has no BlockHolder: continuity
// is best-effort, restoration is not.
func TestManagerSwitchRollsBackWithAPlainGuard(t *testing.T) {
	guard := &fakeGuard{}
	bad := newFakeEngine()
	bad.apply = errSwitchEngine
	good := newFakeEngine()
	calls := 0
	manager := NewManager(ManagerConfig{
		Factory: func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
			calls++
			if p.SessionID == "new" {
				return bad, nil
			}
			if calls > 1 {
				return newFakeEngine(), nil
			}
			return good, nil
		},
		Guard: guard,
	})
	ctx := context.Background()
	if _, err := manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); !errors.Is(err, errSwitchEngine) {
		t.Fatalf("switch = %v", err)
	}
	if current := manager.Current(); current == nil || current.ID() != "prev" || current.State() != StateConnected {
		t.Fatalf("current = %v, want prev restored behind a plain guard", current)
	}
	if err := manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
}

// Kill-switch continuity: with the switch wanted on both sides of a
// successful switch, the guard's block never drops — the previous
// Restore runs under the hold and the release happens after the new
// session applied.
func TestManagerSwitchHoldsTheKillSwitchBlock(t *testing.T) {
	rig := newSwitchRig()
	ctx := context.Background()
	if _, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	seq, blocked, violated, holds := rig.guard.snapshot()
	if violated {
		t.Errorf("the block dropped while a hold was outstanding: %v", seq)
	}
	if !blocked {
		t.Error("the block is down after a switch that wanted it up")
	}
	if holds != 0 {
		t.Errorf("holds = %d after the switch, want 0 (release leaked)", holds)
	}
	var sawHold, sawHeldRestore, sawRelease bool
	for _, entry := range seq {
		switch {
		case strings.HasPrefix(entry, "hold"):
			sawHold = true
		case strings.HasPrefix(entry, "restore-held"):
			sawHeldRestore = true
		case strings.HasPrefix(entry, "release"):
			sawRelease = true
		}
	}
	if !sawHold || !sawHeldRestore || !sawRelease {
		t.Errorf("sequence = %v, want hold, a restore under the hold, and a release", seq)
	}
	if err := rig.manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
}

// The hold also spans a rollback: a failed switch that restores the
// previous session never drops the block either.
func TestManagerSwitchHoldsTheBlockAcrossARollback(t *testing.T) {
	rig := newSwitchRig()
	rig.applyErrs["new"] = []error{errSwitchEngine}
	ctx := context.Background()
	if _, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); !errors.Is(err, errSwitchEngine) {
		t.Fatal(err)
	}
	_, blocked, violated, holds := rig.guard.snapshot()
	if violated || !blocked {
		t.Errorf("after rollback: blocked=%v violated=%v, want the block held throughout", blocked, violated)
	}
	if holds != 0 {
		t.Errorf("holds = %d after the rollback, want 0", holds)
	}
	if err := rig.manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
}

// With the kill switch wanted on only one side there is nothing to hold
// continuous: no hold is taken and the block follows the new settings.
func TestManagerSwitchTakesNoHoldWhenOnlyOneSideWantsTheSwitch(t *testing.T) {
	for _, tc := range []struct {
		name        string
		prevKS      bool
		newKS       bool
		wantBlocked bool
	}{
		{"off to on", false, true, true},
		{"on to off", true, false, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			rig := newSwitchRig()
			ctx := context.Background()
			if _, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: tc.prevKS}); err != nil {
				t.Fatal(err)
			}
			if _, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: tc.newKS}); err != nil {
				t.Fatal(err)
			}
			seq, blocked, _, _ := rig.guard.snapshot()
			for _, entry := range seq {
				if strings.HasPrefix(entry, "hold") {
					t.Errorf("a hold was taken for a one-sided switch: %v", seq)
				}
			}
			if blocked != tc.wantBlocked {
				t.Errorf("blocked = %v, want %v", blocked, tc.wantBlocked)
			}
			if err := rig.manager.Disconnect(ctx); err != nil {
				t.Fatal(err)
			}
		})
	}
}

// A composite of holding guards holds every part; a composite of plain
// guards reports unsupported and the manager switches the old way.
func TestManagerSwitchHoldsThroughACompositeGuard(t *testing.T) {
	first, second := &switchGuard{}, &switchGuard{}
	manager := NewManager(ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newFakeEngine(), nil },
		Guard:   NewCompositeGuard(first, second),
	})
	ctx := context.Background()
	if _, err := manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	for name, part := range map[string]*switchGuard{"first": first, "second": second} {
		_, blocked, violated, holds := part.snapshot()
		if violated || !blocked || holds != 0 {
			t.Errorf("part %s: blocked=%v violated=%v holds=%d, want held throughout and released", name, blocked, violated, holds)
		}
	}
	if err := manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}

	plain := NewManager(ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return newFakeEngine(), nil },
		Guard:   NewCompositeGuard(&fakeGuard{}, &fakeGuard{}),
	})
	if _, err := plain.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := plain.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); err != nil {
		t.Fatalf("a composite without holders must still switch: %v", err)
	}
	if err := plain.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
}

// Timing budget: cold connects and switches over a live session on the
// fake engine must stay far under a generous 2 s median budget, so a
// real regression (a stray sleep, a lock convoy) trips this test
// without flaking on a loaded two-core machine. The measured medians
// are logged for the report.
func TestManagerConnectTimingBudget(t *testing.T) {
	const (
		runs   = 15
		budget = 2 * time.Second
	)
	ctx := context.Background()

	cold := make([]time.Duration, 0, runs)
	for i := 0; i < runs; i++ {
		rig := newSwitchRig()
		start := time.Now()
		if _, err := rig.manager.Connect(ctx, testPlan("cold"), Settings{KillSwitch: true}); err != nil {
			t.Fatal(err)
		}
		cold = append(cold, time.Since(start))
		if err := rig.manager.Disconnect(ctx); err != nil {
			t.Fatal(err)
		}
	}

	rig := newSwitchRig()
	if _, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	switches := make([]time.Duration, 0, runs)
	ids := []string{"new", "prev"}
	for i := 0; i < runs; i++ {
		start := time.Now()
		if _, err := rig.manager.Connect(ctx, testPlan(ids[i%2]), Settings{KillSwitch: true}); err != nil {
			t.Fatal(err)
		}
		switches = append(switches, time.Since(start))
	}
	if err := rig.manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}

	median := func(ds []time.Duration) time.Duration {
		sorted := append([]time.Duration(nil), ds...)
		sort.Slice(sorted, func(i, j int) bool { return sorted[i] < sorted[j] })
		return sorted[len(sorted)/2]
	}
	t.Logf("cold connect median %v over %d runs; switch median %v over %d runs", median(cold), runs, median(switches), runs)
	if median(cold) > budget {
		t.Errorf("cold connect median %v exceeds the %v budget", median(cold), budget)
	}
	if median(switches) > budget {
		t.Errorf("switch median %v exceeds the %v budget", median(switches), budget)
	}
}

func BenchmarkManagerConnectCold(b *testing.B) {
	ctx := context.Background()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		rig := newSwitchRig()
		if _, err := rig.manager.Connect(ctx, testPlan("cold"), Settings{KillSwitch: true}); err != nil {
			b.Fatal(err)
		}
		if err := rig.manager.Disconnect(ctx); err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkManagerConnectSwitch(b *testing.B) {
	ctx := context.Background()
	rig := newSwitchRig()
	if _, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		b.Fatal(err)
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		id := "new"
		if i%2 == 1 {
			id = "prev"
		}
		if _, err := rig.manager.Connect(ctx, testPlan(id), Settings{KillSwitch: true}); err != nil {
			b.Fatal(err)
		}
	}
	b.StopTimer()
	_ = rig.manager.Disconnect(ctx)
}

// panicApplyEngine panics inside Apply, standing in for a third-party
// engine bug on the switch path.
type panicApplyEngine struct{ *fakeEngine }

func (panicApplyEngine) Apply(context.Context, *engine.Plan) error { panic("engine boom") }

// Regression (review of the switch/hold change): a panic mid-switch
// must not leak the kill-switch hold. releaseBlock used to run only on
// the enumerated return paths, so the panic left holds=1 forever and
// Disconnect could never lift the block. The deferred release must
// also fire exactly once alongside the explicit releases on the
// ordinary paths (no double release).
func TestManagerSwitchPanicInEngineApplyReleasesHold(t *testing.T) {
	guard := &switchGuard{}
	manager := NewManager(ManagerConfig{
		Factory: func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
			if p.SessionID == "new" {
				return panicApplyEngine{newFakeEngine()}, nil
			}
			return newFakeEngine(), nil
		},
		Guard: guard,
	})
	ctx := context.Background()
	if _, err := manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	func() {
		defer func() { _ = recover() }()
		_, _ = manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true})
	}()
	_, _, _, holds := guard.snapshot()
	if holds != 0 {
		t.Errorf("holds = %d after a panicking switch, want 0 (hold leaked; block can never be restored)", holds)
	}
	done := make(chan error, 1)
	go func() { done <- manager.Disconnect(ctx) }()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		t.Fatal("Disconnect wedged after the panic")
	}
	_, blocked, _, _ := guard.snapshot()
	if blocked {
		t.Error("block still armed after Disconnect following the panicking switch")
	}

	// Exactly one release per switch on the ordinary path too: the
	// explicit release and the deferred one must not both fire.
	rig := newSwitchRig()
	if _, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	seq, _, _, _ := rig.guard.snapshot()
	releases := 0
	for _, entry := range seq {
		if strings.HasPrefix(entry, "release") {
			releases++
		}
	}
	if releases != 1 {
		t.Errorf("release entries = %d in %v, want exactly 1 per switch", releases, seq)
	}
	if err := rig.manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
}

// Regression (review of the switch/hold change): the hold decision
// must use the previous session's LIVE kill-switch state.
// Session.SetKillSwitch updates the session (and the guard) but not
// Manager.lastSettings, so deciding from lastSettings missed the hold
// for a live-armed session — its Stop really lifted the block for the
// switch window — and took a spurious hold for a live-disarmed one.
func TestManagerHoldDecisionUsesLiveKillSwitchState(t *testing.T) {
	ctx := context.Background()
	sawHold := func(seq []string) bool {
		for _, e := range seq {
			if strings.HasPrefix(e, "hold") {
				return true
			}
		}
		return false
	}

	t.Run("toggled on live", func(t *testing.T) {
		rig := newSwitchRig()
		first, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: false})
		if err != nil {
			t.Fatal(err)
		}
		if err := first.SetKillSwitch(ctx, true); err != nil {
			t.Fatal(err)
		}
		if _, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); err != nil {
			t.Fatal(err)
		}
		seq, blocked, violated, holds := rig.guard.snapshot()
		if !sawHold(seq) {
			t.Errorf("no hold taken although the live session had the kill switch ON (toggled): seq=%v", seq)
		}
		if violated || !blocked || holds != 0 {
			t.Errorf("after switch: blocked=%v violated=%v holds=%d, want held throughout and released", blocked, violated, holds)
		}
		if err := rig.manager.Disconnect(ctx); err != nil {
			t.Fatal(err)
		}
	})

	t.Run("toggled off live", func(t *testing.T) {
		rig := newSwitchRig()
		first, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true})
		if err != nil {
			t.Fatal(err)
		}
		if err := first.SetKillSwitch(ctx, false); err != nil {
			t.Fatal(err)
		}
		if _, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); err != nil {
			t.Fatal(err)
		}
		seq, blocked, _, _ := rig.guard.snapshot()
		if sawHold(seq) {
			t.Errorf("a hold was taken although the live session had the kill switch OFF (toggled): seq=%v", seq)
		}
		if !blocked {
			t.Error("block down after a switch to a session that wants it up")
		}
		if err := rig.manager.Disconnect(ctx); err != nil {
			t.Fatal(err)
		}
	})
}

// cancelApplyEngine fails Apply and cancels the caller's context on
// the way out, staging a switch whose RPC context dies with it.
type cancelApplyEngine struct {
	*fakeEngine
	cancel context.CancelFunc
}

func (e cancelApplyEngine) Apply(context.Context, *engine.Plan) error {
	e.cancel()
	return errSwitchEngine
}

// Regression (review of the switch/hold change): the rollback must
// build and start the restored session on the detached stop context,
// not on the switch's (cancelled) context — otherwise a switch that
// failed because its RPC went away can never roll back.
func TestManagerRollbackRunsOnTheDetachedContext(t *testing.T) {
	guard := &switchGuard{}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	manager := NewManager(ManagerConfig{
		Factory: func(_ context.Context, p *engine.Plan) (engine.Engine, error) {
			if p.SessionID == "new" {
				return cancelApplyEngine{fakeEngine: newFakeEngine(), cancel: cancel}, nil
			}
			return newFakeEngine(), nil
		},
		Guard: guard,
	})
	if _, err := manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	if _, err := manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true}); !errors.Is(err, errSwitchEngine) {
		t.Fatalf("switch error = %v, want the original switch failure", err)
	}
	current := manager.Current()
	if current == nil || current.ID() != "prev" || current.State() != StateConnected {
		t.Fatalf("current = %v, want prev restored despite the cancelled switch context", current)
	}
	if err := manager.Disconnect(context.Background()); err != nil {
		t.Fatal(err)
	}
}

// A failed hold release must not be swallowed by the manager: the
// switch result stands, but the failure lands in the journal of the
// session that is current after the switch.
func TestManagerJournalsAFailedHoldRelease(t *testing.T) {
	rig := newSwitchRig()
	ctx := context.Background()
	if _, err := rig.manager.Connect(ctx, testPlan("prev"), Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	rig.guard.mu.Lock()
	rig.guard.releaseErr = errors.New("nftables busy")
	rig.guard.mu.Unlock()
	created, err := rig.manager.Connect(ctx, testPlan("new"), Settings{KillSwitch: true})
	if err != nil {
		t.Fatalf("a failed hold release must not fail the switch itself: %v", err)
	}
	found := false
	for _, ev := range created.Journal().Since(0, 64) {
		if ev.Kind == EventError && strings.Contains(ev.LogLine, "kill-switch hold release failed") {
			found = true
		}
	}
	if !found {
		t.Error("the failed hold release left no journal entry on the new session")
	}
	if err := rig.manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
}
