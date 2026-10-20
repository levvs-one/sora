package serversel

import (
	"net/netip"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/probe"
)

type fakeJudge map[string]probe.SubnetState

func (f fakeJudge) State(addr netip.Addr) probe.SubnetState {
	p, ok := probe.SubnetOf(addr)
	if !ok {
		return probe.SubnetHealthy
	}
	if s, ok := f[p.String()]; ok {
		return s
	}
	return probe.SubnetHealthy
}

func candWithAddr(id, addr string, latency uint32) Candidate {
	c := Candidate{ID: id, LatencyMs: latency, HasLatency: true}
	if addr != "" {
		c.Addr = netip.MustParseAddr(addr)
	}
	return c
}

func TestPickRejectsBurnedSubnet(t *testing.T) {
	judge := fakeJudge{"203.0.113.0/24": probe.SubnetBurned}
	p := NewPicker(ScoreConfig{}, PickConfig{}, nil).WithSubnets(judge)
	pick, err := p.PickBest([]Candidate{
		candWithAddr("fast-but-burned", "203.0.113.7", 10),
		candWithAddr("slower-healthy", "198.51.100.7", 200),
	}, Constraints{})
	if err != nil {
		t.Fatalf("PickBest: %v", err)
	}
	if pick.Candidate.ID != "slower-healthy" {
		t.Fatalf("picked %q, want the healthy-subnet server", pick.Candidate.ID)
	}
	found := false
	for _, r := range pick.Rejected {
		if r.ID == "fast-but-burned" && strings.Contains(r.Reason, "carpet-banned") {
			found = true
		}
	}
	if !found {
		t.Fatalf("rejection must name the carpet ban, got %+v", pick.Rejected)
	}
}

func TestPickAllBurnedIsNoEligible(t *testing.T) {
	judge := fakeJudge{"203.0.113.0/24": probe.SubnetBurned}
	p := NewPicker(ScoreConfig{}, PickConfig{}, nil).WithSubnets(judge)
	_, err := p.PickBest([]Candidate{
		candWithAddr("a", "203.0.113.1", 10),
		candWithAddr("b", "203.0.113.2", 20),
	}, Constraints{})
	if err == nil {
		t.Fatal("all candidates in a burned subnet must be ineligible")
	}
}

func TestPickPinDoesNotOverrideBurnedSubnet(t *testing.T) {
	judge := fakeJudge{"203.0.113.0/24": probe.SubnetBurned}
	p := NewPicker(ScoreConfig{}, DefaultPickConfig(), nil).WithSubnets(judge)
	pick, err := p.PickBest([]Candidate{
		candWithAddr("pinned", "203.0.113.7", 10),
		candWithAddr("other", "198.51.100.7", 200),
	}, Constraints{Profile: ProfileHint{PreferredServerID: "pinned"}})
	if err != nil {
		t.Fatalf("PickBest: %v", err)
	}
	if pick.Candidate.ID != "other" || pick.Pinned {
		t.Fatalf("pin must not connect into a carpet ban, got %+v", pick.Candidate)
	}
}

func TestPickDegradedSubnetPenalized(t *testing.T) {
	judge := fakeJudge{"203.0.113.0/24": probe.SubnetDegraded}
	p := NewPicker(ScoreConfig{}, PickConfig{}, nil).WithSubnets(judge)
	// Near-identical candidates: the degraded one loses on the penalty.
	pick, err := p.PickBest([]Candidate{
		candWithAddr("degraded", "203.0.113.7", 100),
		candWithAddr("healthy", "198.51.100.7", 100),
	}, Constraints{})
	if err != nil {
		t.Fatalf("PickBest: %v", err)
	}
	if pick.Candidate.ID != "healthy" {
		t.Fatalf("picked %q, want the healthy-subnet peer", pick.Candidate.ID)
	}
}

func TestPickNoJudgeNoSubnetClaims(t *testing.T) {
	p := NewPicker(ScoreConfig{}, PickConfig{}, nil)
	pick, err := p.PickBest([]Candidate{
		candWithAddr("a", "203.0.113.7", 10),
	}, Constraints{})
	if err != nil || pick.Candidate.ID != "a" {
		t.Fatalf("without a judge the address must not matter: %+v %v", pick, err)
	}
}

func TestPickUnknownAddrUnaffected(t *testing.T) {
	judge := fakeJudge{"203.0.113.0/24": probe.SubnetBurned}
	p := NewPicker(ScoreConfig{}, PickConfig{}, nil).WithSubnets(judge)
	pick, err := p.PickBest([]Candidate{
		candWithAddr("noaddr", "", 10),
	}, Constraints{})
	if err != nil || pick.Candidate.ID != "noaddr" {
		t.Fatalf("unknown address must not be rejected: %+v %v", pick, err)
	}
}
