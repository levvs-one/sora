package desync

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/profiles"
)

// Regression tests for the CENSOR-DESYNC review findings M2, M3, M4
// and M6: each test is the reviewer's probe, inverted.

// M2: the marker profiles' resolved genomes must bind back to a
// registry profile. Before the fix, profileForParams compared the
// resolved winner against the unresolved registry and 3 of the 11
// profiles could never bind.
func TestProfileForParamsBindsMarkerProfiles(t *testing.T) {
	for _, id := range []string{"sni_block/split-midsni", "sni_block/disorder-midsni", "kz_variant/split-midsni"} {
		prof, ok := LookupProfile(id)
		if !ok {
			t.Fatalf("registry lost profile %s", id)
		}
		resolved, err := prof.ResolveFor(BlockedCanary.SNI)
		if err != nil {
			t.Fatalf("%s does not resolve: %v", id, err)
		}
		bound, ok := profileForParams(resolved)
		if !ok {
			t.Fatalf("the resolved winner of %s binds to no profile (ProfileID would be empty)", id)
		}
		// The bound profile must be the same genome in resolved
		// space. (kz_variant/split-midsni is genome-identical to
		// sni_block/split-midsni, so it binds to that entry — the
		// genome, not the label, is what F5 runs.)
		boundResolved, err := bound.ResolveFor(BlockedCanary.SNI)
		if err != nil || boundResolved.ID() != resolved.ID() {
			t.Fatalf("%s bound to %s, a different resolved genome", id, bound.ID)
		}
	}
}

// M2 end to end: a tune won by the marker profile verbatim must call
// the F5 binder with its registry ID (the reviewer's probe observed
// zero binder calls and an empty bound_profile_id).
func TestServiceTuneBindsMarkerWinner(t *testing.T) {
	prof, _ := LookupProfile("sni_block/split-midsni")
	resolved, err := prof.ResolveFor(BlockedCanary.SNI)
	if err != nil {
		t.Fatal(err)
	}
	binder := &fakeBinder{}
	svc := newTestService(t, binder)
	probe := func(ctx context.Context, p Params) ProbeReport {
		return ProbeReport{
			BlockedOK: p.ID() == resolved.ID(),
			ControlOK: true, ControlLatency: 100 * time.Millisecond,
			ControlBaseline: 100 * time.Millisecond,
		}
	}
	res, err := svc.Tune(context.Background(), testFP, "nfqws", probe)
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	if res.Best.Params.ID() != resolved.ID() {
		t.Fatalf("winner = %s, want the resolved marker genome %s", res.Best.Params.ID(), resolved.ID())
	}
	if len(binder.calls) != 1 || binder.calls[0] != "sni_block/split-midsni" {
		t.Fatalf("binder calls = %v, want the marker profile bound to F5", binder.calls)
	}
	b, ok := svc.Store.Lookup(testFP)
	if !ok || b.ProfileID != "sni_block/split-midsni" {
		t.Fatalf("binding = %+v ok=%v, want ProfileID set", b, ok)
	}
}

// M3 probe (a): a stored winner that cannot convert (fake + fixed
// TTL + autottl — a combination with no faithful rendering) must not
// be served, even under the current data versions, and the refusal
// must surface as an event.
func TestCurrentRefusesUnconvertibleWinner(t *testing.T) {
	svc := newTestService(t, nil)
	var refused []string
	svc.OnRefuse = func(_ profiles.Fingerprint, reason string) { refused = append(refused, reason) }
	b := Binding{
		Winner:          Params{Method: MethodFake, FakeProto: "tls", TTL: 5, AutoTTL: true},
		Score:           1,
		At:              time.Now(),
		RegistryVersion: RegistryVersion,
		GenePoolVersion: GenePoolVersion,
	}
	if err := svc.Store.Bind(testFP, b); err != nil {
		t.Fatal(err)
	}
	if _, _, ok := svc.Current(testFP); ok {
		t.Fatal("Current served a winner that cannot convert to a strategy")
	}
	if len(refused) != 1 || refused[0] == "" {
		t.Fatalf("refusals = %v, want exactly one event with a reason", refused)
	}
}

// M3 probe (b): a winner recorded under a foreign gene-pool version
// must not be served either — Current used to check only the
// registry version.
func TestCurrentRefusesStaleGenePoolVersion(t *testing.T) {
	svc := newTestService(t, nil)
	var refused []string
	svc.OnRefuse = func(_ profiles.Fingerprint, reason string) { refused = append(refused, reason) }
	want, _ := winnerProbe()
	b := Binding{
		Winner:          want,
		Score:           1,
		At:              time.Now(),
		RegistryVersion: RegistryVersion,
		GenePoolVersion: GenePoolVersion + 99,
	}
	if err := svc.Store.Bind(testFP, b); err != nil {
		t.Fatal(err)
	}
	if _, _, ok := svc.Current(testFP); ok {
		t.Fatal("Current served a winner from a foreign gene-pool version")
	}
	if len(refused) != 1 {
		t.Fatalf("refusals = %v, want one event", refused)
	}
}

// M4 probe: a winner bound an hour ago with a working runner-up must
// AGE-rotate on serve — the ring is born at Binding.At, not rebuilt
// fresh (born=now) on every Current() call. The same *Rotator must
// come back from repeated calls so failure counts accumulate.
func TestCurrentServesPersistentRingBornAtBindingTime(t *testing.T) {
	svc := newTestService(t, nil)
	winner, _ := winnerProbe()
	runnerUp := Params{Method: MethodSplit, SplitPos: "1", Scope: ScopeTLS}
	b := Binding{
		Winner:          winner,
		Score:           0.9,
		Ranked:          []Params{runnerUp},
		RankedScores:    []float64{0.8},
		At:              time.Now().Add(-time.Hour),
		RegistryVersion: RegistryVersion,
		GenePoolVersion: GenePoolVersion,
	}
	if err := svc.Store.Bind(testFP, b); err != nil {
		t.Fatal(err)
	}
	rot1, _, ok := svc.Current(testFP)
	if !ok {
		t.Fatal("Current refused a valid binding")
	}
	cur, ok := rot1.Current()
	if !ok || cur.Params.ID() != runnerUp.ID() {
		t.Fatalf("ring current = %v ok=%v, want the runner-up: a winner bound an hour ago must age-rotate", cur.Params.ID(), ok)
	}
	rot2, _, ok := svc.Current(testFP)
	if !ok || rot2 != rot1 {
		t.Fatal("Current must return the Service's persistent ring for the network, not a fresh one per call")
	}
}

// M4: passive bad signals fed through Observe accumulate in the same
// persistent ring Current serves: three censor-specific failures
// rotate the winner out without any new Current-side state.
func TestObserveDrivesPersistentRing(t *testing.T) {
	svc := newTestService(t, nil)
	winner, _ := winnerProbe()
	runnerUp := Params{Method: MethodSplit, SplitPos: "1", Scope: ScopeTLS}
	b := Binding{
		Winner:          winner,
		Score:           0.9,
		Ranked:          []Params{runnerUp},
		RankedScores:    []float64{0.8},
		At:              time.Now(),
		RegistryVersion: RegistryVersion,
		GenePoolVersion: GenePoolVersion,
	}
	if err := svc.Store.Bind(testFP, b); err != nil {
		t.Fatal(err)
	}
	rot, _, ok := svc.Current(testFP)
	if !ok {
		t.Fatal("Current refused a valid binding")
	}
	for i := 0; i < rotatorMaxFails; i++ {
		svc.Observe(testFP, SignalInjectedRST)
	}
	cur, ok := rot.Current()
	if !ok || cur.Params.ID() != runnerUp.ID() {
		t.Fatalf("after %d observed kills the ring serves %v, want the runner-up", rotatorMaxFails, cur.Params.ID())
	}
	// Plain resets are noise: they feed health, never the ring.
	svc2 := newTestService(t, nil)
	if err := svc2.Store.Bind(testFP, b); err != nil {
		t.Fatal(err)
	}
	rot2, _, _ := svc2.Current(testFP)
	for i := 0; i < 2*rotatorMaxFails; i++ {
		svc2.Observe(testFP, SignalReset)
	}
	if cur, _ := rot2.Current(); cur.Params.ID() != winner.ID() {
		t.Fatal("plain resets rotated the ring: noise must not count as a silent death")
	}
}

// M6: the Summary journal line must not interpolate the bind error —
// binder/store errors quote gateway addresses and SNI-shaped values.
// The reviewer's probe put both in BindErr and read both back out of
// the summary.
func TestSummarySanitizesBindErr(t *testing.T) {
	res := SearchResult{
		Best:     Scored{Params: Params{Method: MethodFake, FakeProto: "tls"}, Score: 0.5},
		Attempts: 2,
		BindErr:  errors.New(`profiles: gateway "192.168.1.1" is not an address (while probing youtube.com)`),
	}
	got := res.Summary()
	for _, leak := range []string{"192.168.1.1", "youtube.com", "gateway"} {
		if strings.Contains(got, leak) {
			t.Fatalf("summary leaks bind-error content %q: %s", leak, got)
		}
	}
	if !strings.Contains(got, "binding not saved:") {
		t.Fatalf("summary lost the bind warning entirely: %s", got)
	}
}
