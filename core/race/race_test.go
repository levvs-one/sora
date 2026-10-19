package race_test

import (
	"context"
	"errors"
	"net"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/race"
)

// fake is a scripted dialer: it succeeds after delay, fails with err, or
// blocks until ctx dies. Counters let tests prove cancellation and the
// absence of goroutine leaks: every started dial must return.
type fake struct {
	delay time.Duration
	err   error

	starts   atomic.Int32
	cancels  atomic.Int32
	returned chan struct{}
	once     sync.Once
}

func newFake(delay time.Duration, err error) *fake {
	return &fake{delay: delay, err: err, returned: make(chan struct{})}
}

func (f *fake) dial(ctx context.Context) (net.Conn, error) {
	f.starts.Add(1)
	defer f.once.Do(func() { close(f.returned) })
	timer := time.NewTimer(f.delay)
	defer timer.Stop()
	select {
	case <-timer.C:
	case <-ctx.Done():
		f.cancels.Add(1)
		return nil, ctx.Err()
	}
	if f.err != nil {
		return nil, f.err
	}
	client, server := net.Pipe()
	_ = server.Close()
	return client, nil
}

// awaitReturn fails the test unless every started fake's dial returned: a
// dial still running after Race returned is a goroutine leak. Fakes the
// race never started (a fast winner pre-empted the stagger) are skipped.
func awaitReturn(t *testing.T, fakes ...*fake) {
	t.Helper()
	timeout := time.After(5 * time.Second)
	for i, f := range fakes {
		if f.starts.Load() == 0 {
			continue
		}
		select {
		case <-f.returned:
		case <-timeout:
			t.Fatalf("fake %d dial did not return after the race ended: goroutine leak", i)
		}
	}
}

func candidate(label string, f *fake) race.Candidate {
	return race.Candidate{Label: label, Dial: f.dial}
}

// TestRaceFastestCandidateWinsAndSlowIsCancelled is the Happy Eyeballs
// core: the fast dial wins, and the slow loser observes cancellation.
func TestRaceFastestCandidateWinsAndSlowIsCancelled(t *testing.T) {
	fast := newFake(20*time.Millisecond, nil)
	slow := newFake(30*time.Second, nil)
	res, err := race.Race(context.Background(),
		[]race.Candidate{candidate("fast", fast), candidate("slow", slow)},
		race.Options{Concurrency: 2, Stagger: 5 * time.Millisecond})
	if err != nil {
		t.Fatalf("Race() error = %v", err)
	}
	_ = res.Conn.Close()
	if res.Index != 0 || res.Label != "fast" {
		t.Errorf("winner = index %d label %q, want index 0 label fast", res.Index, res.Label)
	}
	if res.Latency <= 0 || res.Latency > 5*time.Second {
		t.Errorf("latency = %v, want a small positive duration", res.Latency)
	}
	awaitReturn(t, fast, slow)
	if got := slow.cancels.Load(); got != 1 {
		t.Errorf("slow dial saw %d cancellations, want 1", got)
	}
	if got := fast.starts.Load(); got != 1 {
		t.Errorf("fast dial started %d times, want 1", got)
	}
}

// TestRacePreferenceOrderIsDeterministic checks that with equal dial
// latency the lower index always wins: the preference order is the slice
// order, never a coin flip.
func TestRacePreferenceOrderIsDeterministic(t *testing.T) {
	for i := 0; i < 25; i++ {
		a := newFake(50*time.Millisecond, nil)
		b := newFake(50*time.Millisecond, nil)
		res, err := race.Race(context.Background(),
			[]race.Candidate{candidate("a", a), candidate("b", b)},
			race.Options{Concurrency: 2, Stagger: 100 * time.Millisecond})
		if err != nil {
			t.Fatalf("iteration %d: Race() error = %v", i, err)
		}
		_ = res.Conn.Close()
		if res.Index != 0 {
			t.Fatalf("iteration %d: winner index = %d, want 0 (deterministic preference)", i, res.Index)
		}
		awaitReturn(t, a, b)
	}
}

// TestRaceSingleCandidateDialsDirectly checks the no-overhead path: one
// candidate dials without racing, and its error is not wrapped in an
// aggregate.
func TestRaceSingleCandidateDialsDirectly(t *testing.T) {
	sentinel := errors.New("boom")
	f := newFake(10*time.Millisecond, sentinel)
	_, err := race.Race(context.Background(),
		[]race.Candidate{candidate("only", f)},
		race.Options{Concurrency: 2, Stagger: time.Millisecond})
	if !errors.Is(err, sentinel) {
		t.Fatalf("Race() error = %v, want the dial error unwrapped", err)
	}
	awaitReturn(t, f)

	ok := newFake(10*time.Millisecond, nil)
	res, err := race.Race(context.Background(),
		[]race.Candidate{candidate("only", ok)},
		race.Options{})
	if err != nil {
		t.Fatalf("Race() error = %v", err)
	}
	_ = res.Conn.Close()
	if res.Index != 0 {
		t.Errorf("winner index = %d, want 0", res.Index)
	}
	awaitReturn(t, ok)
}

// TestRaceAggregatesAllFailures checks that when every candidate fails
// the error carries each attempt's failure.
func TestRaceAggregatesAllFailures(t *testing.T) {
	innerA := syscall.ECONNREFUSED
	innerB := &timeoutError{}
	a := newFake(time.Millisecond, &net.OpError{Op: "dial", Err: innerA})
	b := newFake(time.Millisecond, &net.OpError{Op: "dial", Err: innerB})
	_, err := race.Race(context.Background(),
		[]race.Candidate{candidate("a", a), candidate("b", b)},
		race.Options{Concurrency: 2, Stagger: time.Millisecond})
	if err == nil {
		t.Fatal("Race() error = nil, want aggregated failures")
	}
	// The redaction pipeline strips *net.OpError wrappers by design;
	// the inner causes must stay findable.
	if !errors.Is(err, innerA) || !errors.Is(err, innerB) {
		t.Errorf("aggregated error = %v, want both candidate failures findable", err)
	}
	msg := err.Error()
	if !strings.Contains(msg, "candidate 0") || !strings.Contains(msg, "candidate 1") {
		t.Errorf("aggregated error = %q, want per-candidate attribution", msg)
	}
	if got := errs.CodeOf(err); got != errs.CodeUnavailable {
		t.Errorf("code = %q, want %q", got, errs.CodeUnavailable)
	}
	awaitReturn(t, a, b)
}

// TestRaceUnanimousFailuresKeepTheirCode checks that when every attempt
// fails the same way the aggregate keeps that code instead of a generic
// one.
func TestRaceUnanimousFailuresKeepTheirCode(t *testing.T) {
	timeoutErr := &net.OpError{Op: "dial", Err: &timeoutError{}}
	a := newFake(time.Millisecond, timeoutErr)
	b := newFake(time.Millisecond, timeoutErr)
	_, err := race.Race(context.Background(),
		[]race.Candidate{candidate("a", a), candidate("b", b)},
		race.Options{Concurrency: 2, Stagger: time.Millisecond})
	if err == nil {
		t.Fatal("Race() error = nil, want aggregated failures")
	}
	if got := errs.CodeOf(err); got != errs.CodeTimeout {
		t.Errorf("code = %q, want %q (unanimous timeout)", got, errs.CodeTimeout)
	}
	awaitReturn(t, a, b)
}

type timeoutError struct{}

func (timeoutError) Error() string   { return "i/o timeout" }
func (timeoutError) Timeout() bool   { return true }
func (timeoutError) Temporary() bool { return true }

// TestRaceParentCancellationStopsAttempts checks that a dying parent
// context ends the race promptly and every attempt observes it.
func TestRaceParentCancellationStopsAttempts(t *testing.T) {
	a := newFake(30*time.Second, nil)
	b := newFake(30*time.Second, nil)
	ctx, cancel := context.WithCancel(context.Background())
	time.AfterFunc(50*time.Millisecond, cancel)
	start := time.Now()
	_, err := race.Race(ctx,
		[]race.Candidate{candidate("a", a), candidate("b", b)},
		race.Options{Concurrency: 2, Stagger: 5 * time.Millisecond})
	if elapsed := time.Since(start); elapsed > 5*time.Second {
		t.Errorf("Race() took %v after cancellation, want a prompt return", elapsed)
	}
	if err == nil {
		t.Fatal("Race() error = nil, want cancellation")
	}
	if got := errs.CodeOf(err); got != errs.CodeCancelled {
		t.Errorf("code = %q, want %q", got, errs.CodeCancelled)
	}
	awaitReturn(t, a, b)
	if got := a.cancels.Load() + b.cancels.Load(); got != 2 {
		t.Errorf("saw %d cancellations, want 2", got)
	}
}

// TestRaceAttemptTimeoutBoundsOneCandidate checks the per-attempt
// deadline: a stalled dial does not eat the whole race budget.
func TestRaceAttemptTimeoutBoundsOneCandidate(t *testing.T) {
	f := newFake(30*time.Second, nil)
	start := time.Now()
	_, err := race.Race(context.Background(),
		[]race.Candidate{candidate("stalled", f)},
		race.Options{AttemptTimeout: 50 * time.Millisecond})
	if elapsed := time.Since(start); elapsed > 5*time.Second {
		t.Errorf("Race() took %v, want the attempt timeout to bound it", elapsed)
	}
	if err == nil {
		t.Fatal("Race() error = nil, want a timeout")
	}
	if got := errs.CodeOf(err); got != errs.CodeDeadlineExceeded {
		t.Errorf("code = %q, want %q", got, errs.CodeDeadlineExceeded)
	}
	awaitReturn(t, f)
	if got := f.cancels.Load(); got != 1 {
		t.Errorf("stalled dial saw %d cancellations, want 1", got)
	}
}

// TestRaceRespectsConcurrencyCap checks that never more than Concurrency
// attempts run at once, even with more candidates waiting.
func TestRaceRespectsConcurrencyCap(t *testing.T) {
	var current, maxSeen atomic.Int32
	blockers := make([]*fake, 4)
	candidates := make([]race.Candidate, 0, len(blockers))
	for i := range blockers {
		blockers[i] = newFake(30*time.Second, nil)
		f := blockers[i]
		candidates = append(candidates, race.Candidate{
			Label: "b",
			Dial: func(ctx context.Context) (net.Conn, error) {
				if n := current.Add(1); n > maxSeen.Load() {
					maxSeen.Store(n)
				}
				defer current.Add(-1)
				return f.dial(ctx)
			},
		})
	}
	ctx, cancel := context.WithCancel(context.Background())
	time.AfterFunc(300*time.Millisecond, cancel)
	_, err := race.Race(ctx, candidates, race.Options{Concurrency: 2, Stagger: 5 * time.Millisecond})
	if err == nil {
		t.Fatal("Race() error = nil, want cancellation")
	}
	awaitReturn(t, blockers...)
	if got := maxSeen.Load(); got > 2 {
		t.Errorf("max concurrent attempts = %d, want <= 2", got)
	}
	if got := maxSeen.Load(); got < 2 {
		t.Errorf("max concurrent attempts = %d, want 2 (both slots used)", got)
	}
}

// TestRaceStaggerSpacesCandidateStarts checks the connection-attempt
// delay: candidates start in slice order, spaced by the stagger.
func TestRaceStaggerSpacesCandidateStarts(t *testing.T) {
	var mu sync.Mutex
	starts := make([]time.Time, 0, 3)
	stamp := func() {
		mu.Lock()
		starts = append(starts, time.Now())
		mu.Unlock()
	}
	candidates := make([]race.Candidate, 0, 3)
	fakes := make([]*fake, 0, 3)
	for i := 0; i < 3; i++ {
		f := newFake(500*time.Millisecond, nil)
		fakes = append(fakes, f)
		candidates = append(candidates, race.Candidate{
			Label: "c",
			Dial: func(ctx context.Context) (net.Conn, error) {
				stamp()
				return f.dial(ctx)
			},
		})
	}
	res, err := race.Race(context.Background(), candidates,
		race.Options{Concurrency: 3, Stagger: 100 * time.Millisecond})
	if err != nil {
		t.Fatalf("Race() error = %v", err)
	}
	_ = res.Conn.Close()
	if res.Index != 0 {
		t.Errorf("winner index = %d, want 0 (started first)", res.Index)
	}
	awaitReturn(t, fakes...)
	mu.Lock()
	defer mu.Unlock()
	if len(starts) != 3 {
		t.Fatalf("started %d candidates, want 3", len(starts))
	}
	for i := 1; i < len(starts); i++ {
		if gap := starts[i].Sub(starts[i-1]); gap < 50*time.Millisecond {
			t.Errorf("start gap %d = %v, want >= 50ms (stagger respected)", i, gap)
		}
	}
}

// TestRaceNoCandidatesIsAnError checks the empty input contract.
func TestRaceNoCandidatesIsAnError(t *testing.T) {
	_, err := race.Race(context.Background(), nil, race.Options{})
	if err == nil {
		t.Fatal("Race() error = nil, want invalid argument")
	}
	if got := errs.CodeOf(err); got != errs.CodeInvalidArgument {
		t.Errorf("code = %q, want %q", got, errs.CodeInvalidArgument)
	}
}

// TestRaceAlreadyCancelledContextReturns checks a dead context short
// circuits before any dial starts.
func TestRaceAlreadyCancelledContextReturns(t *testing.T) {
	f := newFake(time.Millisecond, nil)
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	_, err := race.Race(ctx,
		[]race.Candidate{candidate("a", f), candidate("b", f)},
		race.Options{})
	if err == nil {
		t.Fatal("Race() error = nil, want cancellation")
	}
	if got := f.starts.Load(); got != 0 {
		t.Errorf("dial started %d times on a dead context, want 0", got)
	}
}
