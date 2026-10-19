package tune

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/profiles"
)

func testFP() profiles.Fingerprint {
	return profiles.Fingerprint{SSID: "HomeNet", Gateway: "192.168.1.1", ASN: "AS12345"}
}

func failWith(err error) AttemptFunc {
	return func(ctx context.Context, s Strategy) error { return err }
}

func succeedOn(ids ...string) AttemptFunc {
	want := map[string]bool{}
	for _, id := range ids {
		want[id] = true
	}
	return func(ctx context.Context, s Strategy) error {
		if want[s.ID] {
			return nil
		}
		return errors.New("dpi blocked")
	}
}

func TestTuneFirstSuccess(t *testing.T) {
	dir := t.TempDir()
	tuner := New(DefaultOptions(), NewCache(dir))
	res, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(), succeedOn("current"))
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	if !res.Succeeded() || res.Winner.ID != "current" {
		t.Fatalf("winner = %+v, want current", res.Winner)
	}
	if len(res.Attempts) != 1 {
		t.Fatalf("attempts = %d, want 1", len(res.Attempts))
	}
	// The winner must be remembered for this network.
	if s, ok := NewCache(dir).Lookup(testFP()); !ok || s.ID != "current" {
		t.Fatalf("cache lookup = %+v, %v; want current, true", s, ok)
	}
}

func TestTuneFallsThroughToPreset(t *testing.T) {
	tuner := New(DefaultOptions(), NewCache(t.TempDir()))
	res, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(), succeedOn("preset/balanced"))
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	if res.Winner.ID != "preset/balanced" {
		t.Fatalf("winner = %q, want preset/balanced", res.Winner.ID)
	}
	if len(res.Attempts) != 2 || res.Attempts[0].Strategy.ID != "current" {
		t.Fatalf("attempt order = %v, want [current preset/balanced]", ids(res.Attempts))
	}
	if !strings.Contains(res.Summary(), `"preset/balanced"`) {
		t.Fatalf("summary = %q, want it to name the winner", res.Summary())
	}
}

func TestTuneAllFail(t *testing.T) {
	tuner := New(DefaultOptions(), NewCache(t.TempDir()))
	res, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(), failWith(errors.New("dpi blocked")))
	if !errors.Is(err, ErrNoStrategy) {
		t.Fatalf("err = %v, want ErrNoStrategy", err)
	}
	if res.Succeeded() {
		t.Fatal("result succeeded, want failure")
	}
	if len(res.Attempts) != 11 {
		t.Fatalf("attempts = %d, want 11 (current + 2 presets + 8 zapret)", len(res.Attempts))
	}
	msg := err.Error()
	for _, want := range []string{"tried 11", "current", "preset/balanced", "preset/max", "zapret/disorder", "dpi blocked"} {
		if !strings.Contains(msg, want) {
			t.Fatalf("error %q does not mention %q", msg, want)
		}
	}
	if !strings.Contains(res.Summary(), "no working strategy") {
		t.Fatalf("summary = %q, want failure wording", res.Summary())
	}
}

func TestTuneKnownNetworkStartsFromCached(t *testing.T) {
	dir := t.TempDir()
	cache := NewCache(dir)
	if err := cache.Remember(testFP(), ObfsMax()); err != nil {
		t.Fatalf("Remember: %v", err)
	}
	tuner := New(DefaultOptions(), cache)
	res, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(), succeedOn("preset/max"))
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	if !res.KnownNetwork {
		t.Fatal("KnownNetwork = false, want true")
	}
	// Priority order holds: current first, the remembered strategy seeds
	// position two instead of starting from the bare default list.
	if got := ids(res.Attempts); len(got) < 2 || got[0] != "current" || got[1] != "preset/max" {
		t.Fatalf("attempt order = %v, want [current preset/max ...]", got)
	}
	if res.Winner.ID != "preset/max" {
		t.Fatalf("winner = %q, want preset/max", res.Winner.ID)
	}
}

func TestTunePreappliedCachedStrategyTriedOnce(t *testing.T) {
	// The session pre-applies the remembered strategy on network
	// recognition; then current IS the remembered one and must be tried
	// exactly once, first.
	dir := t.TempDir()
	cache := NewCache(dir)
	if err := cache.Remember(testFP(), ObfsMax()); err != nil {
		t.Fatalf("Remember: %v", err)
	}
	tuner := New(DefaultOptions(), cache)
	res, err := tuner.Tune(context.Background(), testFP(), ObfsMax(), succeedOn("preset/max"))
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	if len(res.Attempts) != 1 || res.Attempts[0].Strategy.ID != "preset/max" {
		t.Fatalf("attempts = %v, want single preset/max", ids(res.Attempts))
	}
}

func TestTuneDedupesCachedStrategy(t *testing.T) {
	dir := t.TempDir()
	cache := NewCache(dir)
	if err := cache.Remember(testFP(), ObfsBalanced()); err != nil {
		t.Fatalf("Remember: %v", err)
	}
	// The plan already runs Balanced: it must be tried exactly once.
	tuner := New(DefaultOptions(), cache)
	res, err := tuner.Tune(context.Background(), testFP(), ObfsBalanced(), succeedOn("preset/max"))
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	n := 0
	for _, a := range res.Attempts {
		if a.Strategy.ID == "preset/balanced" {
			n++
		}
	}
	if n != 1 {
		t.Fatalf("preset/balanced tried %d times, want 1 (order %v)", n, ids(res.Attempts))
	}
}

func TestTuneCancelBeforeStart(t *testing.T) {
	tuner := New(DefaultOptions(), NewCache(t.TempDir()))
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	res, err := tuner.Tune(ctx, testFP(), CurrentStrategy(), succeedOn("current"))
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v, want context.Canceled", err)
	}
	if len(res.Attempts) != 0 {
		t.Fatalf("attempts = %d, want 0", len(res.Attempts))
	}
}

func TestTuneCancelMidRun(t *testing.T) {
	tuner := New(DefaultOptions(), NewCache(t.TempDir()))
	ctx, cancel := context.WithCancel(context.Background())
	started := make(chan struct{})
	done := make(chan error, 1)
	go func() {
		_, err := tuner.Tune(ctx, testFP(), CurrentStrategy(), func(ctx context.Context, s Strategy) error {
			close(started)
			<-ctx.Done()
			return ctx.Err()
		})
		done <- err
	}()
	<-started
	cancel()
	select {
	case err := <-done:
		if !errors.Is(err, context.Canceled) {
			t.Fatalf("err = %v, want context.Canceled", err)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("Tune did not return after cancel")
	}
}

func TestTuneBudgetExhausted(t *testing.T) {
	opts := Options{MaxStrategies: 32, AttemptTimeout: time.Second, TotalBudget: time.Second}
	tuner := New(opts, NewCache(t.TempDir()))
	block := func(ctx context.Context, s Strategy) error {
		<-ctx.Done()
		return ctx.Err()
	}
	start := time.Now()
	_, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(), block)
	if !errors.Is(err, ErrBudget) {
		t.Fatalf("err = %v, want ErrBudget", err)
	}
	if d := time.Since(start); d > 10*time.Second {
		t.Fatalf("run took %s, budget logic stuck", d)
	}
}

func TestTuneAttemptTimeout(t *testing.T) {
	opts := Options{MaxStrategies: 8, AttemptTimeout: time.Second, TotalBudget: 30 * time.Second}
	tuner := New(opts, NewCache(t.TempDir()))
	calls := 0
	res, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(),
		func(ctx context.Context, s Strategy) error {
			calls++
			if calls == 1 {
				<-ctx.Done()
				return ctx.Err()
			}
			return nil
		})
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	a := res.Attempts[0]
	if !errors.Is(a.Err, context.DeadlineExceeded) {
		t.Fatalf("first attempt err = %v, want context.DeadlineExceeded", a.Err)
	}
	if a.Duration < 900*time.Millisecond || a.Duration > 5*time.Second {
		t.Fatalf("first attempt took %s, want ~1s (per-attempt timeout)", a.Duration)
	}
	if res.Winner.ID != "preset/balanced" {
		t.Fatalf("winner = %q, want preset/balanced", res.Winner.ID)
	}
}

func TestTuneNilAttempt(t *testing.T) {
	tuner := New(DefaultOptions(), NewCache(t.TempDir()))
	if _, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(), nil); err == nil {
		t.Fatal("nil attempt func: want error")
	}
}

func TestTuneNilCache(t *testing.T) {
	tuner := New(DefaultOptions(), nil)
	res, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(), succeedOn("current"))
	if err != nil || !res.Succeeded() {
		t.Fatalf("Tune = %+v, %v; want success without cache", res, err)
	}
}

func TestTuneTruncatesToMaxStrategies(t *testing.T) {
	opts := Options{MaxStrategies: 2, AttemptTimeout: time.Second, TotalBudget: 30 * time.Second}
	tuner := New(opts, NewCache(t.TempDir()))
	res, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(), failWith(errors.New("nope")))
	if !errors.Is(err, ErrNoStrategy) {
		t.Fatalf("err = %v, want ErrNoStrategy", err)
	}
	if len(res.Attempts) != 2 {
		t.Fatalf("attempts = %d, want 2 (MaxStrategies)", len(res.Attempts))
	}
}

func TestOptionsNormalize(t *testing.T) {
	cases := []struct {
		name string
		in   Options
		want Options
	}{
		{"zero is minimal", Options{}, Options{MaxStrategies: 1, AttemptTimeout: time.Second, TotalBudget: time.Second}},
		{"clamp strategies high", Options{MaxStrategies: 1000}, Options{MaxStrategies: 32, AttemptTimeout: time.Second, TotalBudget: time.Second}},
		{"clamp attempt", Options{AttemptTimeout: time.Hour}, Options{MaxStrategies: 1, AttemptTimeout: 2 * time.Minute, TotalBudget: 2 * time.Minute}},
		{"budget below attempt rises", Options{AttemptTimeout: time.Minute, TotalBudget: time.Millisecond}, Options{MaxStrategies: 1, AttemptTimeout: time.Minute, TotalBudget: time.Minute}},
		{"budget capped", Options{TotalBudget: time.Hour, AttemptTimeout: time.Second}, Options{MaxStrategies: 1, AttemptTimeout: time.Second, TotalBudget: 10 * time.Minute}},
	}
	for _, c := range cases {
		if got := c.in.Normalize(); got != c.want {
			t.Fatalf("%s: got %+v, want %+v", c.name, got, c.want)
		}
	}
}

func TestCandidatesOrder(t *testing.T) {
	max := ObfsMax()
	got := Candidates(CurrentStrategy(), &max)
	want := []string{"current", "preset/max", "preset/balanced", "zapret/tlsrec", "zapret/split", "zapret/disorder", "zapret/disorder-tls", "zapret/split-oob", "zapret/http-tamper", "zapret/http-eol", "zapret/mss-last"}
	if idsOf(got) != strings.Join(want, ",") {
		t.Fatalf("order = %v, want %v", idsOf(got), want)
	}
	// No cache: default order.
	got = Candidates(CurrentStrategy(), nil)
	if got[0].ID != "current" || got[1].ID != "preset/balanced" || got[2].ID != "preset/max" {
		t.Fatalf("default order = %v", idsOf(got))
	}
}

func TestLookup(t *testing.T) {
	if _, ok := Lookup("nope"); ok {
		t.Fatal("Lookup(unknown) = true, want false")
	}
	for _, id := range []string{"current", "preset/balanced", "preset/max", "zapret/tlsrec"} {
		if _, ok := Lookup(id); !ok {
			t.Fatalf("Lookup(%q) = false, want true", id)
		}
	}
}

func TestNetworkKey(t *testing.T) {
	a := testFP()
	b := testFP()
	b.Fingerprint = "wlan0 192.168.1.5, wlan0 fe80::/64"
	if networkKey(a) != networkKey(b) {
		t.Fatal("interface display string must not affect the cache key")
	}
	c := testFP()
	c.SSID = "OtherNet"
	if networkKey(a) == networkKey(c) {
		t.Fatal("different SSID must give a different cache key")
	}
}

func TestCacheRoundTrip(t *testing.T) {
	dir := t.TempDir()
	c := NewCache(dir)
	if err := c.Remember(testFP(), ObfsMax()); err != nil {
		t.Fatalf("Remember: %v", err)
	}
	// A fresh instance reads the persisted file.
	c2 := NewCache(dir)
	s, ok := c2.Lookup(testFP())
	if !ok || s.ID != "preset/max" {
		t.Fatalf("lookup = %+v, %v; want preset/max, true", s, ok)
	}
	// Zapret alternatives round-trip with their parameters intact. Look the
	// strategy up by ID: pool order is not a contract.
	alts := ZapretAlternatives()
	var disorder Strategy
	for _, s := range alts {
		if s.ID == "zapret/disorder" {
			disorder = s
		}
	}
	if disorder.ID == "" {
		t.Fatal("pool lost zapret/disorder")
	}
	if err := c2.Remember(testFP(), disorder); err != nil {
		t.Fatalf("Remember: %v", err)
	}
	s, ok = NewCache(dir).Lookup(testFP())
	if !ok || s.ID != "zapret/disorder" {
		t.Fatalf("lookup = %+v, %v; want zapret/disorder, true", s, ok)
	}
	if !s.HasBypass || !s.Bypass.Disorder {
		t.Fatalf("restored strategy lost its params: %+v", s)
	}
	if _, ok := c2.Lookup(profiles.Fingerprint{SSID: "Elsewhere"}); ok {
		t.Fatal("unknown network must miss")
	}
	if want := filepath.Join(dir, "tune", "cache.json"); c.Path() != want {
		t.Fatalf("path = %q, want %q", c.Path(), want)
	}
}

func TestPresetsAreObfsReferences(t *testing.T) {
	// The tuner must not duplicate core/obfs contents: presets travel by ID
	// and carry no zapret parameters of their own.
	for _, s := range []Strategy{ObfsBalanced(), ObfsMax()} {
		if s.HasBypass {
			t.Fatalf("%q carries zapret params; presets are obfs references", s.ID)
		}
		got, ok := Lookup(s.ID)
		if !ok || got.ID != s.ID {
			t.Fatalf("Lookup(%q) failed", s.ID)
		}
	}
}

func TestCacheTTLExpiry(t *testing.T) {
	dir := t.TempDir()
	c := NewCache(dir)
	if err := c.Remember(testFP(), ObfsMax()); err != nil {
		t.Fatalf("Remember: %v", err)
	}
	// Backdate the entry past the TTL.
	data, err := os.ReadFile(c.Path())
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	var f cacheFile
	if err := json.Unmarshal(data, &f); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	for k, e := range f.Entries {
		e.At = time.Now().Add(-CacheTTL - time.Hour)
		f.Entries[k] = e
	}
	data, _ = json.Marshal(f)
	if err := os.WriteFile(c.Path(), data, 0o600); err != nil {
		t.Fatalf("write: %v", err)
	}
	if _, ok := NewCache(dir).Lookup(testFP()); ok {
		t.Fatal("expired entry must miss")
	}
}

func TestCacheCorruptFile(t *testing.T) {
	dir := t.TempDir()
	c := NewCache(dir)
	if err := os.MkdirAll(filepath.Dir(c.Path()), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(c.Path(), []byte("{not json"), 0o600); err != nil {
		t.Fatal(err)
	}
	c2 := NewCache(dir) // must not panic or fail
	if _, ok := c2.Lookup(testFP()); ok {
		t.Fatal("corrupt cache must behave as empty")
	}
}

func TestCacheFilePerms(t *testing.T) {
	dir := t.TempDir()
	c := NewCache(dir)
	// Pre-create with lax perms: Remember must tighten them.
	if err := os.MkdirAll(filepath.Dir(c.Path()), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(c.Path(), []byte("{}"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := c.Remember(testFP(), ObfsBalanced()); err != nil {
		t.Fatalf("Remember: %v", err)
	}
	fi, err := os.Stat(c.Path())
	if err != nil {
		t.Fatal(err)
	}
	if perm := fi.Mode().Perm(); perm != 0o600 {
		t.Fatalf("cache file mode = %o, want 600", perm)
	}
}

func ids(attempts []AttemptRecord) []string {
	out := make([]string, len(attempts))
	for i, a := range attempts {
		out[i] = a.Strategy.ID
	}
	return out
}

func idsOf(ss []Strategy) string {
	out := make([]string, len(ss))
	for i, s := range ss {
		out[i] = s.ID
	}
	return strings.Join(out, ",")
}

func TestTuneEmptyCurrentFallsBack(t *testing.T) {
	// A zero Strategy as "current" (plan carries no obfuscation config)
	// must retry as the "current" candidate, not vanish from the order.
	tuner := New(DefaultOptions(), NewCache(t.TempDir()))
	res, err := tuner.Tune(context.Background(), testFP(), Strategy{}, succeedOn("current"))
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	if !res.Succeeded() || res.Winner.ID != "current" {
		t.Fatalf("winner = %+v, want current (empty current must fall back)", res.Winner)
	}
	if len(res.Attempts) != 1 || res.Attempts[0].Strategy.ID != "current" {
		t.Fatalf("attempts = %v, want single current", ids(res.Attempts))
	}
}

func TestTuneCacheWriteFailureIsNonFatal(t *testing.T) {
	dir := t.TempDir()
	c := NewCache(dir)
	// Block the cache file path with a directory: persistence must fail,
	// but the tuning run must still succeed and record CacheErr.
	if err := os.MkdirAll(c.Path(), 0o755); err != nil {
		t.Fatal(err)
	}
	tuner := New(DefaultOptions(), c)
	res, err := tuner.Tune(context.Background(), testFP(), CurrentStrategy(), succeedOn("current"))
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	if !res.Succeeded() {
		t.Fatal("run must succeed even when the cache cannot be written")
	}
	if res.CacheErr == nil {
		t.Fatal("CacheErr = nil, want the persistence failure recorded")
	}
	if !strings.Contains(res.Summary(), "cache not saved") {
		t.Fatalf("summary = %q, want the cache failure mentioned", res.Summary())
	}
}

func TestCacheVersionMismatchBehavesEmpty(t *testing.T) {
	dir := t.TempDir()
	c := NewCache(dir)
	if err := os.MkdirAll(filepath.Dir(c.Path()), 0o700); err != nil {
		t.Fatal(err)
	}
	data, err := json.Marshal(cacheFile{Version: cacheVersion + 1, Entries: map[string]cacheEntry{
		"key": {StrategyID: "preset/max", At: time.Now()},
	}})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(c.Path(), data, 0o600); err != nil {
		t.Fatal(err)
	}
	if _, ok := NewCache(dir).Lookup(testFP()); ok {
		t.Fatal("newer-version cache must be ignored, not misread")
	}
}

func TestCacheConcurrentUse(t *testing.T) {
	c := NewCache(t.TempDir())
	var wg sync.WaitGroup
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			fp := testFP()
			_ = c.Remember(fp, ObfsMax())
			_, _ = c.Lookup(fp)
		}()
	}
	wg.Wait()
}

func TestSummaryOnCancelledRun(t *testing.T) {
	tuner := New(DefaultOptions(), NewCache(t.TempDir()))
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	res, err := tuner.Tune(ctx, testFP(), CurrentStrategy(), succeedOn("current"))
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v, want context.Canceled", err)
	}
	if !strings.Contains(res.Summary(), "no working strategy") {
		t.Fatalf("summary = %q, want failure wording", res.Summary())
	}
}

func TestZapretPoolIsValidAndOrdered(t *testing.T) {
	alts := ZapretAlternatives()
	if len(alts) < 8 {
		t.Fatalf("pool shrank to %d strategies", len(alts))
	}
	seen := map[string]bool{}
	for _, s := range alts {
		if !strings.HasPrefix(s.ID, "zapret/") || s.ID == "zapret/" {
			t.Errorf("bad strategy id %q", s.ID)
		}
		if seen[s.ID] {
			t.Errorf("duplicate strategy id %q", s.ID)
		}
		seen[s.ID] = true
		if !s.HasBypass {
			t.Errorf("%q carries no bypass params", s.ID)
		}
		o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s.Bypass}
		if err := o.Validate(); err != nil {
			t.Errorf("%q does not validate: %v", s.ID, err)
		}
		if _, ok := Lookup(s.ID); !ok {
			t.Errorf("Lookup(%q) failed", s.ID)
		}
	}
	// The MSS clamp slows every connection: it must stay the last resort.
	if last := alts[len(alts)-1]; last.ID != "zapret/mss-last" {
		t.Errorf("last strategy = %q, want zapret/mss-last", last.ID)
	}
}
