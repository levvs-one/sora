package desync

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine/bypass"
)

func TestRegistryIsValidAndComplete(t *testing.T) {
	if err := ValidateRegistry(); err != nil {
		t.Fatalf("the shipped registry must validate: %v", err)
	}
	// Every cascade class the mandate names carries at least one
	// profile — a class with no data is a promise the tuner cannot keep.
	for _, class := range []Class{ClassSNIBlock, ClassStall, ClassQUICThrottle, ClassKZ} {
		if len(ProfilesForClass(class)) == 0 {
			t.Errorf("class %s has no profiles", class)
		}
	}
}

func TestRegistryProfilesAreData(t *testing.T) {
	ids := map[string]bool{}
	for _, p := range Profiles() {
		if ids[p.ID] {
			t.Fatalf("duplicate profile id %s", p.ID)
		}
		ids[p.ID] = true
		if p.Note == "" {
			t.Fatalf("profile %s has no provenance/honest-limit note", p.ID)
		}
		got, ok := LookupProfile(p.ID)
		if !ok || got.ID != p.ID {
			t.Fatalf("LookupProfile(%s) = %v, %v", p.ID, got.ID, ok)
		}
	}
	if _, ok := LookupProfile("sni_block/nope"); ok {
		t.Fatal("an unknown profile id resolved")
	}
}

func TestRegistryQUICProfilesRenderQUICDesync(t *testing.T) {
	// QUIC-Initial desync, end to end: every quic_throttle profile
	// must render nfqws argv that fakes or splits the QUIC Initial on
	// UDP/443 — through the same renderer the executor uses.
	for _, prof := range ProfilesForClass(ClassQUICThrottle) {
		resolved, err := prof.ResolveFor("example.com")
		if err != nil {
			t.Fatalf("%s: %v", prof.ID, err)
		}
		args, ok := resolved.NFQWSArgs("/zapret")
		if !ok {
			t.Fatalf("%s: no nfqws rendering", prof.ID)
		}
		joined := strings.Join(args, " ")
		if !strings.Contains(joined, "--filter-udp=443") || !strings.Contains(joined, "--filter-l7=quic") {
			t.Errorf("%s: argv %v does not select QUIC on UDP/443", prof.ID, args)
		}
		if resolved.FakeProto == "quic" && !strings.Contains(joined, "--dpi-desync-fake-quic=") {
			t.Errorf("%s: argv %v carries no fake QUIC Initial", prof.ID, args)
		}
	}
}

func TestRegistryMarkerProfilesResolve(t *testing.T) {
	for _, prof := range Profiles() {
		if prof.Params.SplitPos != bypass.MidSNIMarker {
			continue
		}
		resolved, err := prof.ResolveFor("example.com")
		if err != nil {
			t.Fatalf("%s: %v", prof.ID, err)
		}
		// MidSNISplit("example.com") = sniext+14 (pinned in bypass).
		if resolved.SplitPos != "sniext+14" {
			t.Fatalf("%s: resolved split = %q, want sniext+14", prof.ID, resolved.SplitPos)
		}
		if _, err := prof.ResolveFor(""); err == nil {
			t.Fatalf("%s: resolving without an SNI must fail", prof.ID)
		}
	}
}

func TestValidateProfileFailClosed(t *testing.T) {
	bad := []Profile{
		{ID: "", Class: ClassSNIBlock, Params: Params{Method: MethodSplit, SplitPos: "1"}, Note: "x"},
		{ID: "stall/x", Class: ClassSNIBlock, Params: Params{Method: MethodSplit, SplitPos: "1"}, Note: "x"},                       // class/id disagree
		{ID: "sni_block/x", Class: ClassSNIBlock, Params: Params{Method: MethodNone}, Note: "x"},                                   // control arm is not a strategy
		{ID: "sni_block/x", Class: ClassSNIBlock, Params: Params{Method: MethodSplit, SplitPos: "1"}},                              // no note
		{ID: "nope/x", Class: Class("nope"), Params: Params{Method: MethodSplit, SplitPos: "1"}, Note: "x"},                        // unknown class
		{ID: "quic_throttle/x", Class: ClassQUICThrottle, Params: Params{Method: MethodFake, FakeProto: "tls", TTL: 3}, Note: "x"}, // tls fake in a quic profile still renders — but as TCP; caught below by class check? no: renders validly, so not in this list
	}
	for i, p := range bad[:5] {
		if err := ValidateProfile(p); err == nil {
			t.Errorf("bad profile %d (%s) validated", i, p.ID)
		}
	}
	_ = bad[5] // documented above: rendering validity is necessary, class coherence is the ID/note's job
}

// TestRegistryTTLValuesAreDataBounded pins the fixed TTLs the
// registry and the gene pool carry: every one must sit inside the
// FakeTTL usable window for a typical measured path — at least the
// minimum a fake needs to pass the censor (2, bypass.minFakeTTL) and
// small enough to die well before a 10+ hop server even with no
// delta. A fixed TTL outside [2,8] is round magic, not data: paths
// shorter than the window are the autottl profiles' job.
func TestRegistryTTLValuesAreDataBounded(t *testing.T) {
	check := func(id string, ttl int) {
		if ttl != 0 && (ttl < 2 || ttl > 8) {
			t.Errorf("%s: fixed TTL %d outside the data-bounded window [2,8]", id, ttl)
		}
	}
	for _, p := range Profiles() {
		check(p.ID, p.Params.TTL)
	}
	for _, s := range GenePool() {
		check(s.Params.ID(), s.Params.TTL)
	}
	// And every AutoTTL profile that wants a calibrated fixed point
	// leaves the delta to the resolver (profiles carry no delta: the
	// delta is a path measurement, not a strategy constant).
	for _, p := range Profiles() {
		if p.Params.AutoTTL && p.Params.TTL != 0 {
			t.Errorf("%s: autottl and a fixed TTL are mutually exclusive", p.ID)
		}
	}
}

func TestSummaryIsUniformAndContentFree(t *testing.T) {
	win := SearchResult{Best: Scored{Params: Params{Method: MethodFake, FakeProto: "tls"}, Score: 0.5}, Attempts: 7}
	if got := win.Summary(); got != `desync: strategy "d/fake|fake:tls" worked after 7 attempt(s)` {
		t.Fatalf("summary = %q", got)
	}
	lose := SearchResult{Attempts: 3}
	if got := lose.Summary(); got != "desync: no working strategy after 3 attempt(s)" {
		t.Fatalf("summary = %q", got)
	}
	// The journal line must never carry probe content: no canary
	// hostnames, no SNI, no latencies.
	for _, leak := range []string{"youtube", "one.one", "ms", "192."} {
		if strings.Contains(win.Summary(), leak) {
			t.Fatalf("summary leaks probe content %q: %s", leak, win.Summary())
		}
	}
}

func TestCandidateParamsDedupesRegistryAndSeeds(t *testing.T) {
	cands := CandidateParams()
	seen := map[string]bool{}
	for _, p := range cands {
		if seen[p.ID()] {
			t.Fatalf("duplicate candidate %s", p.ID())
		}
		seen[p.ID()] = true
	}
	if len(cands) < len(Profiles()) {
		t.Fatal("candidates must cover the whole registry")
	}
}
