package diagnostics

import (
	"context"
	"errors"
	"net"
	"net/netip"
	"sort"
	"strings"
)

// DNS spoofing detector (T014, CENSORSHIP-METER P0.2).
//
// A censor that cannot see inside the tunnel still sits on the DNS path:
// it answers canary queries itself with a sinkhole address, a sticky
// injection, or an NXDOMAIN for a name that provably exists. This
// detector compares the SAME canary query across every plain-DNS
// resolver the session can be made to use, two rounds each — the second
// round separates round-robin rotation (the resolver's pool repeats)
// from a sticky injection (one resolver consistently answers with
// something nobody else has).
//
// Verdicts are honest by construction: a lone mismatch names itself
// "inconsistent" (one resolver disagrees — evidence, not proof of who
// lied), a non-routable answer for a public canary is "bogus" (the
// sinkhole signature), and a total failure to resolve is "unresolved" —
// never dressed up as spoofing, because a dead network lies about
// nothing.
type DnsSpoofVerdict int

const (
	// DnsSpoofUnresolved means no resolver answered: a network outage,
	// not evidence of spoofing.
	DnsSpoofUnresolved DnsSpoofVerdict = iota
	// DnsSpoofOK means every resolver agrees on the canary's pool.
	DnsSpoofOK
	// DnsSpoofInconsistent means resolvers disagree about the canary.
	DnsSpoofInconsistent
	// DnsSpoofBogus means an answer contains a non-routable address for
	// a public canary: the censor sinkhole signature.
	DnsSpoofBogus
	// DnsSpoofNXDomain means every resolver claims the canary does not
	// exist.
	DnsSpoofNXDomain
)

// String renders the verdict for reports.
func (v DnsSpoofVerdict) String() string {
	switch v {
	case DnsSpoofOK:
		return "ok"
	case DnsSpoofInconsistent:
		return "inconsistent"
	case DnsSpoofBogus:
		return "bogus"
	case DnsSpoofNXDomain:
		return "nxdomain"
	default:
		return "unresolved"
	}
}

// DnsSpoofReport is the detector's answer.
type DnsSpoofReport struct {
	Verdict  DnsSpoofVerdict
	Evidence []string
	// Answers maps resolver -> the distinct canary answers seen across
	// the rounds.
	Answers map[string][]string
}

// SpoofTarget is one resolver to cross-check: the network shape the
// prober uses for it ("udp", "tcp") and its address.
type SpoofTarget struct {
	Network string
	Addr    string
}

// spoofProbeFunc resolves host through one resolver, mirroring the
// DnsLeakInput.Probe signature so the leak pipeline reuses its prober.
type spoofProbeFunc func(ctx context.Context, network, addr, host string) ([]string, error)

// DetectDnsSpoof queries canary through every target, rounds times each
// (default 2), and classifies the disagreement. Each target's answers
// are compared by resolver address; a second round that repeats the
// pool reads as round-robin, a pool nobody else shares reads as a
// sticky injection.
func DetectDnsSpoof(ctx context.Context, targets []SpoofTarget, canary string, rounds int, probe spoofProbeFunc) DnsSpoofReport {
	if rounds <= 0 {
		rounds = 2
	}
	if canary == "" {
		canary = canaryHost
	}
	// prior collects each target's answer pool from the first round
	// (rounds-1 further rounds run here).
	pools := map[string]map[string]bool{}
	rep := DnsSpoofReport{Answers: map[string][]string{}}
	var answered, nxdomain int
	for _, tgt := range targets {
		seen := map[string]bool{}
		for round := 0; round < rounds; round++ {
			ips, err := probe(ctx, tgt.Network, tgt.Addr, canary)
			if err != nil {
				var dnsErr *net.DNSError
				if errors.As(err, &dnsErr) && dnsErr.IsNotFound {
					nxdomain++
					continue
				}
				continue // failure is evidence of nothing beyond failure
			}
			if len(ips) == 0 {
				continue
			}
			answered++
			for _, s := range ips {
				seen[s] = true
			}
		}
		var list []string
		for ip := range seen {
			list = append(list, ip)
		}
		sort.Strings(list)
		rep.Answers[tgt.Addr] = list
		if len(list) > 0 {
			pools[tgt.Addr] = seen
		}
	}
	return classifySpoof(rep, pools, canary, rounds, answered, nxdomain, len(targets))
}

// CompareDnsSpoof is the pipeline form: prior carries the answer pools
// already collected by an earlier round (e.g. the tunnel check's own
// canary query); one verification round per target runs here. Nothing is
// probed twice more than it must be.
func CompareDnsSpoof(ctx context.Context, targets []SpoofTarget, canary string, prior map[string][]string, probe spoofProbeFunc) DnsSpoofReport {
	if canary == "" {
		canary = canaryHost
	}
	pools := map[string]map[string]bool{}
	rep := DnsSpoofReport{Answers: map[string][]string{}}
	var answered, nxdomain int
	for _, tgt := range targets {
		seen := map[string]bool{}
		for _, s := range prior[tgt.Addr] {
			seen[s] = true
		}
		ips, err := probe(ctx, tgt.Network, tgt.Addr, canary)
		if err != nil {
			var dnsErr *net.DNSError
			if errors.As(err, &dnsErr) && dnsErr.IsNotFound {
				nxdomain++
			}
		} else if len(ips) > 0 {
			answered++
			for _, s := range ips {
				seen[s] = true
			}
		}
		var list []string
		for ip := range seen {
			list = append(list, ip)
		}
		sort.Strings(list)
		rep.Answers[tgt.Addr] = list
		if len(list) > 0 {
			pools[tgt.Addr] = seen
		}
	}
	// The prior round counts as one round for the evidence text.
	return classifySpoof(rep, pools, canary, 2, answered, nxdomain, len(targets))
}

func classifySpoof(rep DnsSpoofReport, pools map[string]map[string]bool, canary string, rounds, answered, nxdomain, targets int) DnsSpoofReport {
	if answered == 0 {
		if nxdomain > 0 && targets > 0 {
			rep.Verdict = DnsSpoofNXDomain
			rep.Evidence = []string{"every resolver claims " + canary + " does not exist"}
			return rep
		}
		rep.Verdict = DnsSpoofUnresolved
		rep.Evidence = []string{"no resolver answered the canary query: a network outage proves nothing about spoofing"}
		return rep
	}
	// Bogus first: a non-routable answer for a public canary is the
	// strongest single signal (a censor sinkhole), whatever else differs.
	for r, list := range rep.Answers {
		for _, s := range list {
			ip, err := netip.ParseAddr(strings.TrimSpace(s))
			if err != nil {
				continue
			}
			if !ip.IsGlobalUnicast() && !ip.IsPrivate() {
				rep.Verdict = DnsSpoofBogus
				rep.Evidence = []string{"resolver " + r + " answered " + canary + " with " + s +
					", a non-routable address: the sinkhole signature"}
				return rep
			}
			if ip.IsPrivate() {
				rep.Verdict = DnsSpoofBogus
				rep.Evidence = []string{"resolver " + r + " answered the public canary " + canary +
					" with the private address " + s + ": a sinkhole or a misconfigured forwarder"}
				return rep
			}
		}
	}
	// Inconsistent: resolvers disagree on the pool. Round-robin within a
	// resolver is already absorbed (each resolver's pool is the union of
	// its rounds), so a difference here is resolver-vs-resolver.
	var ref string
	for r := range pools {
		ref = r
		break
	}
	for r, set := range pools {
		if r == ref || setEqual(set, pools[ref]) {
			continue
		}
		rep.Verdict = DnsSpoofInconsistent
		rep.Evidence = []string{"resolvers disagree about " + canary + ": " + ref +
			" says " + strings.Join(rep.Answers[ref], ", ") + "; " + r +
			" says " + strings.Join(rep.Answers[r], ", ")}
		return rep
	}
	rep.Verdict = DnsSpoofOK
	rep.Evidence = []string{"all resolvers agree on " + canary + " across " + itoa(rounds) + " rounds"}
	return rep
}

func setEqual(a, b map[string]bool) bool {
	if len(a) != len(b) {
		return false
	}
	for k := range a {
		if !b[k] {
			return false
		}
	}
	return true
}

// itoa is a tiny strconv-free formatter (dnsleak.go keeps its own for
// the same reason: diagnostics avoids pulling strconv for one call).
func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var b [4]byte
	i := len(b)
	for n > 0 {
		i--
		b[i] = byte('0' + n%10)
		n /= 10
	}
	return string(b[i:])
}
