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

	total, converted, fakeProtoLeaks := 0, 0, 0
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
