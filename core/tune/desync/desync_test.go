package desync

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/profiles"
)

func TestParamsIDStable(t *testing.T) {
	p := Params{Method: MethodDisorder, SplitPos: "2", Fooling: "badseq", Scope: ScopeTLS}
	if p.ID() != (Params{Method: MethodDisorder, SplitPos: "2", Fooling: "badseq", Scope: ScopeTLS}).ID() {
		t.Fatal("ID is not stable for equal params")
	}
	other := p
	other.SplitPos = "3"
	if p.ID() == other.ID() {
		t.Fatal("different params share an ID")
	}
}

func TestParamsRequiresNFQWS(t *testing.T) {
	tpwsOK := []Params{
		{Method: MethodSplit, SplitPos: "1", Scope: ScopeTLS},
		{Method: MethodDisorder, SplitPos: "2"},
		{Method: MethodOOB, SplitPos: "1"},
		{Method: MethodTLSRec, SplitPos: "sniext+1"},
		{Method: MethodHTTPShuffle, Scope: ScopeHTTP},
		{Method: MethodNone},
	}
	for _, p := range tpwsOK {
		if p.RequiresNFQWS() {
			t.Fatalf("%s wrongly requires nfqws", p.ID())
		}
		if p.Engine() != "tpws" {
			t.Fatalf("%s: engine = %q, want tpws", p.ID(), p.Engine())
		}
	}
	nfqwsOnly := []Params{
		{Method: MethodFake, FakeProto: "tls"},
		{Method: MethodSplit, Fooling: "badseq"},
		{Method: MethodSplit, TTL: 3},
		{Method: MethodSplit, AutoTTL: true},
		{Method: MethodFake, FakeProto: "tls", Repeats: 2},
	}
	for _, p := range nfqwsOnly {
		if !p.RequiresNFQWS() {
			t.Fatalf("%s should require nfqws", p.ID())
		}
	}
}

func TestParamsArgsTPWS(t *testing.T) {
	p := Params{Method: MethodDisorder, SplitPos: "2", Scope: ScopeTLS}
	args := p.Args()
	joined := strings.Join(args, " ")
	if !strings.Contains(joined, "--split-pos=2") || !strings.Contains(joined, "--disorder=tls") {
		t.Fatalf("args = %v, want split-pos and scoped disorder", args)
	}
	// tpws cannot express fooling: it must be dropped, not misrendered.
	nf := Params{Method: MethodSplit, SplitPos: "1", Fooling: "badseq"}
	for _, a := range nf.Args() {
		if strings.Contains(a, "badseq") {
			t.Fatalf("fooling leaked into tpws args: %v", nf.Args())
		}
	}
}

func TestGenePoolExecutable(t *testing.T) {
	pool := GenePool()
	if len(pool) == 0 {
		t.Fatal("empty gene pool")
	}
	ids := map[string]bool{}
	for _, s := range pool {
		if s.Note == "" {
			t.Fatalf("seed %s has no provenance note", s.Params.ID())
		}
		if ids[s.Params.ID()] {
			t.Fatalf("duplicate seed ID %s", s.Params.ID())
		}
		ids[s.Params.ID()] = true
	}
	for _, p := range ExecutableSeeds("tpws") {
		if p.RequiresNFQWS() {
			t.Fatalf("tpws seed %s requires nfqws", p.ID())
		}
	}
	if len(ExecutableSeeds("tpws")) == 0 {
		t.Fatal("no tpws-executable seeds")
	}
}

func TestScoreGates(t *testing.T) {
	good := ProbeReport{
		BlockedOK: true, BlockedLatency: 300 * time.Millisecond,
		ControlOK: true, ControlLatency: 100 * time.Millisecond,
		ControlBaseline: 100 * time.Millisecond,
	}
	if s := Score(good); s != 1 {
		t.Fatalf("perfect report scores %v, want 1", s)
	}
	blocked := good
	blocked.BlockedOK = false
	if Score(blocked) != 0 {
		t.Fatal("blocked fetch failed but score != 0")
	}
	rst := good
	rst.ControlRST = true
	if Score(rst) != 0 {
		t.Fatal("injected RST but score != 0: the TCP-breaking gate must be hard")
	}
	broken := good
	broken.ControlOK = false
	if Score(broken) != 0 {
		t.Fatal("control fetch failed but score != 0")
	}
	slow := good
	slow.ControlLatency = 400 * time.Millisecond
	if s := Score(slow); s != 0.25 {
		t.Fatalf("4x latency scores %v, want 0.25", s)
	}
	noisy := good
	noisy.ExtraPackets = 3
	if s := Score(noisy); s != 0.25 {
		t.Fatalf("3 extra packets score %v, want 0.25", s)
	}
	// Multiplicative: both penalties apply.
	both := slow
	both.ExtraPackets = 3
	if s := Score(both); s != 0.0625 {
		t.Fatalf("slow+noisy scores %v, want 0.0625", s)
	}
}

// fakeProbe scores 1 for genomes matching want, 0 otherwise, with a clean
// control fetch. It lets the search run fully offline.
func fakeProbe(want Params) ProbeFunc {
	return func(ctx context.Context, p Params) ProbeReport {
		ok := p.ID() == want.ID()
		return ProbeReport{
			BlockedOK: ok,
			ControlOK: true, ControlLatency: 100 * time.Millisecond,
			ControlBaseline: 100 * time.Millisecond,
		}
	}
}

func TestSearchFindsWinner(t *testing.T) {
	want := Params{Method: MethodTLSRec, SplitPos: "sniext+1", Scope: ScopeTLS}
	seeds := append(SeedParams(), want) // winner hidden among seeds
	opts := DefaultOptions()
	res, err := Search(context.Background(), seeds, opts, fakeProbe(want))
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if !res.Succeeded() || res.Best.Params.ID() != want.ID() {
		t.Fatalf("best = %s, want %s", res.Best.Params.ID(), want.ID())
	}
	if res.Best.Score != 1 {
		t.Fatalf("best score = %v, want 1", res.Best.Score)
	}
}

func TestSearchRespectsBudget(t *testing.T) {
	probes := 0
	probe := func(ctx context.Context, p Params) ProbeReport {
		probes++
		return ProbeReport{} // nothing ever works
	}
	opts := DefaultOptions()
	opts.MaxCandidates = 5
	_, err := Search(context.Background(), SeedParams(), opts, probe)
	if !errors.Is(err, ErrNoWorking) {
		t.Fatalf("err = %v, want ErrNoWorking", err)
	}
	if probes > 5 {
		t.Fatalf("probed %d candidates with MaxCandidates=5", probes)
	}
}

func TestSearchDedupesSeeds(t *testing.T) {
	probes := 0
	probe := func(ctx context.Context, p Params) ProbeReport {
		probes++
		return ProbeReport{BlockedOK: true, ControlOK: true}
	}
	dup := Params{Method: MethodSplit, SplitPos: "1", Scope: ScopeTLS}
	opts := DefaultOptions()
	opts.MutationsPerParent = 0 // no second generation: count pure dedupe
	_, err := Search(context.Background(), []Params{dup, dup, dup}, opts, probe)
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if probes != 1 {
		t.Fatalf("probed %d times for 3 identical seeds, want 1", probes)
	}
}

func TestSearchCancelled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	_, err := Search(ctx, SeedParams(), DefaultOptions(), fakeProbe(Params{}))
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v, want context.Canceled", err)
	}
}

func TestSearchNilProbe(t *testing.T) {
	if _, err := Search(context.Background(), SeedParams(), DefaultOptions(), nil); err == nil {
		t.Fatal("nil probe func must fail fast")
	}
}

func TestRotatorCirclesOnStreak(t *testing.T) {
	a := Scored{Params: Params{Method: MethodSplit, SplitPos: "1"}, Score: 0.9}
	b := Scored{Params: Params{Method: MethodDisorder, SplitPos: "2"}, Score: 0.7}
	dead := Scored{Params: Params{Method: MethodNone}, Score: 0}
	r := NewRotator([]Scored{a, b, dead}, 3, time.Hour)
	if r.Empty() {
		t.Fatal("dead entry should be dropped, not empty the ring")
	}
	cur, ok := r.Current()
	if !ok || cur.Params.ID() != a.Params.ID() {
		t.Fatalf("current = %v, want best-first", cur.Params.ID())
	}
	// Two lone failures: no rotation yet.
	for i := 0; i < 2; i++ {
		if _, rotated := r.Fail(); rotated {
			t.Fatal("rotated before maxFails")
		}
	}
	next, rotated := r.Fail()
	if !rotated || next.Params.ID() != b.Params.ID() {
		t.Fatalf("after 3 fails: rotated=%v next=%s, want b", rotated, next.Params.ID())
	}
	if r.Rotations() != 1 {
		t.Fatalf("rotations = %d, want 1", r.Rotations())
	}
	// Success resets the streak.
	r.Success()
	if _, rotated := r.Fail(); rotated {
		t.Fatal("single fail after success must not rotate")
	}
	// The ring wraps around.
	r.Fail()
	_, rotated = r.Fail()
	if !rotated {
		t.Fatal("expected rotation back to the start of the ring")
	}
	cur, _ = r.Current()
	if cur.Params.ID() != a.Params.ID() {
		t.Fatalf("ring did not wrap: current = %s", cur.Params.ID())
	}
}

func TestRotatorMaxAge(t *testing.T) {
	a := Scored{Params: Params{Method: MethodSplit, SplitPos: "1"}, Score: 0.9}
	b := Scored{Params: Params{Method: MethodDisorder, SplitPos: "2"}, Score: 0.7}
	r := NewRotator([]Scored{a, b}, 100, time.Nanosecond)
	time.Sleep(2 * time.Nanosecond)
	cur, ok := r.Current()
	if !ok || cur.Params.ID() != b.Params.ID() {
		t.Fatalf("expired strategy should rotate on read: current = %s", cur.Params.ID())
	}
}

func TestRotatorEmpty(t *testing.T) {
	r := NewRotator(nil, 3, time.Hour)
	if !r.Empty() {
		t.Fatal("want empty ring")
	}
	if _, ok := r.Current(); ok {
		t.Fatal("empty ring must not yield a strategy")
	}
	if _, rotated := r.Fail(); rotated {
		t.Fatal("empty ring must not rotate")
	}
}

func TestNetworkChanged(t *testing.T) {
	home := profiles.Fingerprint{SSID: "Home", Gateway: "192.168.1.1", ASN: "AS123"}
	if NetworkChanged(home, home) {
		t.Fatal("same network reported as changed")
	}
	mobile := profiles.Fingerprint{SSID: "", Gateway: "10.0.0.1", ASN: "AS456"}
	if !NetworkChanged(home, mobile) {
		t.Fatal("different network not detected")
	}
	// DHCP churn on the interface addresses must not count: NetworkKey
	// excludes them by design.
	a := profiles.Fingerprint{SSID: "Home", Gateway: "192.168.1.1", ASN: "AS123", Fingerprint: "addr1"}
	b := profiles.Fingerprint{SSID: "Home", Gateway: "192.168.1.1", ASN: "AS123", Fingerprint: "addr2"}
	if NetworkChanged(a, b) {
		t.Fatal("interface-address churn must not trigger re-tune")
	}
}

func TestHealthFailRate(t *testing.T) {
	h := NewHealth(0)
	if h.FailRate() != 0 {
		t.Fatal("empty window must score 0")
	}
	for i := 0; i < 6; i++ {
		h.Add(SignalSuccess)
	}
	for i := 0; i < 2; i++ {
		h.Add(SignalInjectedRST)
	}
	if r := h.FailRate(); r != 0.25 {
		t.Fatalf("fail rate = %v, want 0.25", r)
	}
	// Plain resets count at half weight.
	h2 := NewHealth(0)
	h2.Add(SignalReset)
	h2.Add(SignalSuccess)
	if r := h2.FailRate(); r != 0.25 {
		t.Fatalf("reset half-weight fail rate = %v, want 0.25", r)
	}
}

func TestNeedsRetune(t *testing.T) {
	if ok, _ := NeedsRetune(true, nil); !ok {
		t.Fatal("network change must trigger re-tune")
	}
	h := NewHealth(0)
	if ok, _ := NeedsRetune(false, h); ok {
		t.Fatal("healthy traffic must not trigger re-tune")
	}
	for i := 0; i < 4; i++ {
		h.Add(SignalSuccess)
	}
	for i := 0; i < 4; i++ {
		h.Add(SignalBlockPage)
	}
	ok, reason := NeedsRetune(false, h)
	if !ok || reason == "" {
		t.Fatal("dying strategy must trigger re-tune with a reason")
	}
	// Below MinSamples: not enough evidence.
	h2 := NewHealth(0)
	h2.Add(SignalInjectedRST)
	if ok, _ := NeedsRetune(false, h2); ok {
		t.Fatal("one bad connection must not trigger re-tune")
	}
}
