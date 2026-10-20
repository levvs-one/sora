package diagnostics

import (
	"context"
	"errors"
	"net"
	"strings"
	"testing"
)

// fakeSpoofProbe answers from a per-resolver table; missing resolvers
// fail, which is the outage shape.
func fakeSpoofProbe(answers map[string][]string) spoofProbeFunc {
	return func(_ context.Context, _, addr, _ string) ([]string, error) {
		if ips, ok := answers[addr]; ok {
			return ips, nil
		}
		return nil, errors.New("no route to resolver")
	}
}

func udpTargets(addrs ...string) []SpoofTarget {
	out := make([]SpoofTarget, len(addrs))
	for i, a := range addrs {
		out[i] = SpoofTarget{Network: "udp", Addr: a}
	}
	return out
}

func TestDetectDnsSpoofAgree(t *testing.T) {
	p := fakeSpoofProbe(map[string][]string{
		"1.1.1.1": {"1.1.1.1", "1.0.0.1"},
		"8.8.8.8": {"1.0.0.1", "1.1.1.1"},
	})
	rep := DetectDnsSpoof(context.Background(), udpTargets("1.1.1.1", "8.8.8.8"), "one.one.one.one", 2, p)
	if rep.Verdict != DnsSpoofOK {
		t.Fatalf("verdict = %v (%v), want ok", rep.Verdict, rep.Evidence)
	}
}

func TestDetectDnsSpoofRoundRobinAbsorbed(t *testing.T) {
	// Same pool, different rotation per round: must not read as a lie.
	rounds := 0
	p := func(_ context.Context, _, _, _ string) ([]string, error) {
		rounds++
		if rounds%2 == 1 {
			return []string{"1.1.1.1"}, nil
		}
		return []string{"1.0.0.1"}, nil
	}
	rep := DetectDnsSpoof(context.Background(), udpTargets("9.9.9.9"), "one.one.one.one", 2, p)
	if rep.Verdict != DnsSpoofOK {
		t.Fatalf("round-robin must be absorbed into one pool, got %v", rep.Verdict)
	}
}

func TestDetectDnsSpoofInconsistent(t *testing.T) {
	p := fakeSpoofProbe(map[string][]string{
		"1.1.1.1":     {"1.1.1.1"},
		"203.0.113.5": {"93.184.216.34"},
	})
	rep := DetectDnsSpoof(context.Background(), udpTargets("1.1.1.1", "203.0.113.5"), "one.one.one.one", 2, p)
	if rep.Verdict != DnsSpoofInconsistent {
		t.Fatalf("verdict = %v, want inconsistent", rep.Verdict)
	}
}

func TestDetectDnsSpoofBogusSinkhole(t *testing.T) {
	p := fakeSpoofProbe(map[string][]string{
		"1.1.1.1":     {"1.1.1.1"},
		"203.0.113.5": {"0.0.0.0"},
	})
	rep := DetectDnsSpoof(context.Background(), udpTargets("1.1.1.1", "203.0.113.5"), "one.one.one.one", 2, p)
	if rep.Verdict != DnsSpoofBogus {
		t.Fatalf("verdict = %v, want bogus (0.0.0.0 sinkhole)", rep.Verdict)
	}
	p2 := fakeSpoofProbe(map[string][]string{
		"203.0.113.5": {"192.168.1.1"},
	})
	rep = DetectDnsSpoof(context.Background(), udpTargets("203.0.113.5"), "one.one.one.one", 2, p2)
	if rep.Verdict != DnsSpoofBogus {
		t.Fatalf("private answer for a public canary: verdict = %v, want bogus", rep.Verdict)
	}
}

func TestDetectDnsSpoofUnresolvedIsNotSpoofing(t *testing.T) {
	p := fakeSpoofProbe(map[string][]string{})
	rep := DetectDnsSpoof(context.Background(), udpTargets("1.1.1.1"), "one.one.one.one", 2, p)
	if rep.Verdict != DnsSpoofUnresolved {
		t.Fatalf("a dead network must read unresolved, got %v", rep.Verdict)
	}
}

func TestDetectDnsSpoofNXDomain(t *testing.T) {
	p := func(_ context.Context, _, _, _ string) ([]string, error) {
		return nil, &net.DNSError{Err: "no such host", IsNotFound: true}
	}
	rep := DetectDnsSpoof(context.Background(), udpTargets("1.1.1.1"), "one.one.one.one", 2, p)
	if rep.Verdict != DnsSpoofNXDomain {
		t.Fatalf("verdict = %v, want nxdomain", rep.Verdict)
	}
}

func TestCheckDnsLeaksIncludesSpoofCheck(t *testing.T) {
	checks := CheckDnsLeaks(context.Background(), DnsLeakInput{
		TunnelResolvers: []TunnelResolver{{Address: "1.1.1.1", Transport: "udp"}},
		SystemResolvers: []string{"1.1.1.1"},
		Probe: func(_ context.Context, _, addr, _ string) ([]string, error) {
			return []string{"1.1.1.1"}, nil
		},
	})
	var spoof *DnsLeakCheck
	for i := range checks {
		if checks[i].ID == DnsLeakSpoofDNS {
			spoof = &checks[i]
		}
	}
	if spoof == nil {
		t.Fatalf("no dns-spoof check in %+v", checks)
	}
	if spoof.Leaked {
		t.Fatalf("agreeing resolvers must not leak-flag, got %+v", spoof)
	}
}

func TestCheckDnsLeaksSpoofFlagsSinkhole(t *testing.T) {
	checks := CheckDnsLeaks(context.Background(), DnsLeakInput{
		TunnelResolvers: []TunnelResolver{{Address: "1.1.1.1", Transport: "udp"}},
		SystemResolvers: []string{"1.1.1.1"},
		Probe: func(_ context.Context, _, _, _ string) ([]string, error) {
			return []string{"0.0.0.0"}, nil
		},
	})
	for _, c := range checks {
		if c.ID == DnsLeakSpoofDNS {
			if !c.Leaked || !strings.Contains(c.Actual, "sinkhole") {
				t.Fatalf("sinkhole answer must flag the check, got %+v", c)
			}
			return
		}
	}
	t.Fatal("dns-spoof check missing")
}
