package desync

import (
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// The tuner's invariant, stated once and pinned by the tests in this
// file: a genome the tuner can produce must never convert to a strategy
// plan validation rejects. Conversion is faithful or it refuses
// (ok=false) — producing a strategy that fails closed at Apply time
// makes a whole class of genomes silently unusable (WAVE-SEAMS §6:
// split/disorder genomes carrying a FakeProto converted to split2 /
// disorder2 strategies holding a fake payload but no fake method, and
// validation rejects exactly that combination).

// assertConvertsValidly checks one genome the tuner is expected to be
// able to run: it must convert, and the strategy must validate.
func assertConvertsValidly(t *testing.T, p Params) {
	t.Helper()
	s, ok := p.BypassStrategy()
	if !ok {
		t.Errorf("genome %s does not convert; a produced genome must run", p.ID())
		return
	}
	o := engine.Outbound{ID: "tune", Protocol: engine.ProtocolBypass, Bypass: &s}
	if err := o.Validate(); err != nil {
		t.Errorf("genome %s converted to a strategy validation rejects: %v", p.ID(), err)
	}
}

// Every seed in the curated pool must convert and validate, not only
// the nfqws ones (TestSeedPoolNFQWSGenomesConvertAndValidate covers
// those through the same path).
func TestSeedGenomesConvertAndValidate(t *testing.T) {
	seeds := SeedParams()
	if len(seeds) == 0 {
		t.Fatal("empty gene pool")
	}
	for _, p := range seeds {
		assertConvertsValidly(t, p)
	}
}

// Every child the mutation generator emits must convert and validate:
// a mutation that can only fail closed wastes a live probe against the
// censor and can never win, so mutate must not emit it.
func TestMutatedGenomesConvertAndValidate(t *testing.T) {
	children := 0
	for _, seed := range SeedParams() {
		for _, child := range mutate(seed, 100) {
			children++
			assertConvertsValidly(t, child)
		}
	}
	if children == 0 {
		t.Fatal("mutate produced no children; the invariant is untested")
	}
}

// The bounded genome space: every axis value the seeds and the mutation
// pools use, crossed with every other. For every combination,
// conversion must be faithful-or-refuse — it may refuse (ok=false),
// but a converted strategy must always pass plan validation.
func TestGenomeSpaceConversionNeverYieldsInvalidStrategy(t *testing.T) {
	methods := []Method{MethodNone, MethodSplit, MethodDisorder, MethodOOB, MethodTLSRec, MethodFake, MethodHTTPShuffle}
	splitPoss := []string{"", "1", "2", "sniext+1", "midsld+2", "method+1"}
	foolings := []string{"", "badseq", "md5sig", "ts"}
	fakeProtos := []string{"", "tls", "quic"}
	ttls := []int{0, 3}
	autoTTLs := []bool{false, true}
	repeats := []int{0, 2}
	scopes := []Scope{"", ScopeTLS, ScopeHTTP, ScopeQUIC}

	total, converted, invalid, fakeProtoLeaks := 0, 0, 0, 0
	for _, m := range methods {
		for _, sp := range splitPoss {
			for _, f := range foolings {
				for _, fp := range fakeProtos {
					for _, ttl := range ttls {
						for _, at := range autoTTLs {
							for _, rp := range repeats {
								for _, sc := range scopes {
									p := Params{Method: m, SplitPos: sp, Fooling: f, FakeProto: fp, TTL: ttl, AutoTTL: at, Repeats: rp, Scope: sc}
									total++
									s, ok := p.BypassStrategy()
									if !ok {
										continue
									}
									converted++
									// The reported defect class, pinned
									// directly: a fake payload may only
									// ever appear alongside the fake
									// desync method.
									if fp != "" && m != MethodFake {
										fakeProtoLeaks++
									}
									o := engine.Outbound{ID: "tune", Protocol: engine.ProtocolBypass, Bypass: &s}
									if err := o.Validate(); err != nil {
										invalid++
										t.Errorf("genome %s converted to a strategy validation rejects: %v", p.ID(), err)
									}
								}
							}
						}
					}
				}
			}
		}
	}
	if total == 0 || converted == 0 {
		t.Fatalf("enumeration degenerated: total=%d converted=%d", total, converted)
	}
	if fakeProtoLeaks > 0 {
		t.Errorf("%d converted genomes carry a FakeProto without the fake method", fakeProtoLeaks)
	}
	// The exact size of the space and of the converted class is
	// pinned, not just the invariant: an earlier blanket guard
	// refused every position-less split/disorder/OOB genome and
	// silently shrank the converted class by 24 — the position-less
	// split/disorder genomes carrying fooling, which convert to
	// valid split2/disorder2 strategies
	// (TestSplitDisorderWithFoolingNoSplitPosConvertAndValidate).
	// If an axis above gains a value, recompute both numbers
	// deliberately instead of letting the space drift.
	if total != 16128 {
		t.Errorf("enumerated %d genomes, want 16128 (7 methods x 6 positions x 4 foolings x 3 fake protos x 2 ttls x 2 autottls x 2 repeats x 4 scopes)", total)
	}
	if converted != 1980 {
		t.Errorf("converted %d genomes, want 1980", converted)
	}
	if invalid != 0 {
		t.Errorf("%d converted genomes failed validation, want 0", invalid)
	}
}

// A position-less split/disorder genome carrying fooling is NOT
// empty: fooling forces the nfqws rendering, where the method
// becomes a split2/disorder2 desync method, validation accepts a
// desync method without a split position, and the executor applies
// its default position. Every such genome in the bounded space —
// 2 methods x 3 foolings x 4 scopes, with the remaining axes at
// their zero values (any FakeProto/TTL/autottl/repeats>1 refuses
// independently for non-fake methods) — must convert and validate,
// rendered as exactly its desync method with its fooling and no
// split position. This is the class a blanket "no SplitPos"
// refusal over-refused.
func TestSplitDisorderWithFoolingNoSplitPosConvertAndValidate(t *testing.T) {
	wantDesync := map[Method]string{MethodSplit: "split2", MethodDisorder: "disorder2"}
	checked := 0
	for m, desync := range wantDesync {
		for _, f := range []string{"badseq", "md5sig", "ts"} {
			for _, sc := range []Scope{"", ScopeTLS, ScopeHTTP, ScopeQUIC} {
				p := Params{Method: m, Fooling: f, Scope: sc} // SplitPos deliberately empty
				checked++
				s, ok := p.BypassStrategy()
				if !ok {
					t.Errorf("genome %s does not convert; fooling makes a position-less %s a valid nfqws strategy", p.ID(), m)
					continue
				}
				if len(s.Desync) != 1 || s.Desync[0] != desync {
					t.Errorf("genome %s converted to desync %v, want [%s]", p.ID(), s.Desync, desync)
				}
				if s.Fooling != f {
					t.Errorf("genome %s converted with fooling %q, want %q", p.ID(), s.Fooling, f)
				}
				if len(s.SplitPos) != 0 {
					t.Errorf("genome %s converted with split positions %v, want none (executor default applies)", p.ID(), s.SplitPos)
				}
				o := engine.Outbound{ID: "tune", Protocol: engine.ProtocolBypass, Bypass: &s}
				if err := o.Validate(); err != nil {
					t.Errorf("genome %s converted to a strategy validation rejects: %v", p.ID(), err)
				}
			}
		}
	}
	if checked != 24 {
		t.Fatalf("checked %d position-less fooling genomes, want 24", checked)
	}
}

// The other side of the narrowed guard: a position-less
// split/disorder/OOB genome with no fooling either renders nothing
// at all (split) or a Disorder/OOB flag validation refuses without
// a split position, at every scope — conversion must refuse all
// 3 methods x 4 scopes.
func TestNoSplitPosNoFoolingRefuse(t *testing.T) {
	checked := 0
	for _, m := range []Method{MethodSplit, MethodDisorder, MethodOOB} {
		for _, sc := range []Scope{"", ScopeTLS, ScopeHTTP, ScopeQUIC} {
			p := Params{Method: m, Scope: sc} // SplitPos and Fooling deliberately empty
			checked++
			if _, ok := p.BypassStrategy(); ok {
				t.Errorf("genome %s converted; want a refusal (no split position and no fooling changes nothing)", p.ID())
			}
		}
	}
	if checked != 12 {
		t.Fatalf("checked %d position-less fooling-less genomes, want 12", checked)
	}
}

// OOB carrying fooling refuses at every scope, with or without a
// position — but NOT via the position guard: fooling is nfqws-only
// and nfqws has no OOB byte, while OOB itself is a tpws-only flag
// validation will not mix with a desync method, so no faithful
// rendering exists. (The with-position case is also in
// convert_test.go's TestUnfaithfulGenomesRefuse.)
func TestOOBWithFoolingRefuse(t *testing.T) {
	for _, f := range []string{"badseq", "md5sig", "ts"} {
		for _, sc := range []Scope{"", ScopeTLS, ScopeHTTP, ScopeQUIC} {
			p := Params{Method: MethodOOB, Fooling: f, Scope: sc} // SplitPos deliberately empty
			if _, ok := p.BypassStrategy(); ok {
				t.Errorf("genome %s converted; want a refusal (nfqws has no OOB byte)", p.ID())
			}
		}
	}
}

// The defect class itself: split/disorder genomes carrying a fake
// payload have no faithful rendering — the payload belongs to a fake
// packet these methods never send — so conversion must refuse them
// rather than emit a strategy validation rejects.
func TestSplitDisorderWithFakeProtoRefuse(t *testing.T) {
	for _, m := range []Method{MethodSplit, MethodDisorder} {
		for _, fp := range []string{"tls", "quic"} {
			for _, sc := range []Scope{"", ScopeTLS, ScopeHTTP, ScopeQUIC} {
				p := Params{Method: m, SplitPos: "2", FakeProto: fp, Scope: sc}
				if _, ok := p.BypassStrategy(); ok {
					t.Errorf("genome %s converted; want a refusal (FakeProto needs the fake method)", p.ID())
				}
			}
		}
	}
}
