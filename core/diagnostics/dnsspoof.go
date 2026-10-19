package diagnostics

import (
	"context"
	"errors"
	"net"
	"net/netip"
	"sort"
	"strings"
	"sync"
	"time"
)

// DNS-spoof detection. CheckDnsLeaks verifies the tunnel DNS path with a
// canary query but never asks whether the answers it gets are honest. This
// detector does: it resolves one name through the OS resolvers and through
// the tunnel resolver and compares the answers the way OONI's DNSCheck and
// Iris compare vantage points — inconsistent answers, non-routable IPs for
// a public name, and NXDOMAIN for a name known to exist are the three
// classic spoof signatures. Everything runs locally; no measurement leaves
// the machine.
//
// Methodology note: one query per resolver cannot separate DNS round-robin
// rotation (different slices of the same honest set) from a sticky injected
// answer. Each resolver is therefore queried twice and the union is
// compared; then an address seen by only one resolver while the others
// agree without it is flagged. That is the single-run compression of
// OONI's "examine anomalies in aggregate over time" rule.

// SpoofVerdict is the outcome of one spoof-detection run.
type SpoofVerdict int

const (
	// SpoofOK means every resolver that answered agreed, and the answers
	// look sane.
	SpoofOK SpoofVerdict = iota
	// SpoofUnresolved means no resolver answered at all: the network is
	// down or the resolvers are unreachable, which is an outage, not a
	// spoof signal.
	SpoofUnresolved
	// SpoofInconsistent means resolvers that answered disagreed on the
	// address set: at least one side is not telling the truth.
	SpoofInconsistent
	// SpoofBogus means an answer carried a non-routable address (private,
	// loopback, link-local, unspecified) for a public name. No legitimate
	// resolver does this.
	SpoofBogus
	// SpoofNXDomain means a name known to exist drew NXDOMAIN from one
	// side while another side resolved it: selective NXDOMAIN forgery.
	SpoofNXDomain
)

// String renders the verdict for logs and the meter UI.
func (v SpoofVerdict) String() string {
	switch v {
	case SpoofOK:
		return "ok"
	case SpoofUnresolved:
		return "unresolved"
	case SpoofInconsistent:
		return "inconsistent"
	case SpoofBogus:
		return "bogus"
	case SpoofNXDomain:
		return "nxdomain"
	default:
		return "unknown"
	}
}

// SpoofInput configures one spoof-detection run.
type SpoofInput struct {
	// Host is the name to test. Empty selects the canary host shared with
	// CheckDnsLeaks, a stable public anycast name with documented
	// answers, which additionally enables the expected-answer check.
	Host string
	// SystemResolvers are the OS resolvers to test; nil means detect them.
	SystemResolvers []string
	// TunnelResolvers are the session's resolvers; only plain
	// UDP/TCP transports are probed, exactly like the canary check.
	TunnelResolvers []TunnelResolver
	// Probe probes host through resolverAddr ("ip" or "ip:port"); nil
	// selects the standard probers. Tests inject failures here. Only
	// plain UDP/TCP probes are used: the spoof detector compares plain
	// answers, and an encrypted tunnel path is covered by the leak
	// check's own canary.
	Probe func(ctx context.Context, network, resolverAddr, host string) ([]string, error)
	// Timeout bounds one resolver query; zero selects the default.
	Timeout time.Duration
}

// SpoofAnswer is what one resolver said across its query rounds.
type SpoofAnswer struct {
	// Resolver is the normalized resolver address that was queried.
	Resolver string
	// Side is "system" or "tunnel".
	Side string
	// IPs is the union of the answers across rounds.
	IPs []string
	// NXDomain reports that every answered round was NXDOMAIN.
	NXDomain bool
}

// SpoofReport is the outcome of one spoof-detection run. Detail is free
// diagnostic text in the same style as DnsLeakCheck.Actual.
type SpoofReport struct {
	Verdict SpoofVerdict
	Answers []SpoofAnswer
	Detail  string
}

// defaultSpoofTimeout bounds one resolver query.
const defaultSpoofTimeout = 3 * time.Second

// spoofRounds is the number of queries per resolver. Two rounds separate
// rotation (the union converges) from sticky injection (the fake address
// repeats).
const spoofRounds = 2

// canaryExpectedAnswers is the documented answer set for the default
// canary (one.one.one.one → Cloudflare's public anycast addresses). Used
// only when Host is the default canary and every resolver agreed: a
// unanimous but unexpected answer means every path is tampered with.
var canaryExpectedAnswers = map[string]bool{
	"1.1.1.1": true,
	"1.0.0.1": true,
}

// DetectDnsSpoof resolves one name through the system resolvers and the
// tunnel resolver and compares the answers. It performs plain-DNS queries
// only, issues no other traffic, and never reports addresses beyond the
// diagnostic Detail string.
func DetectDnsSpoof(ctx context.Context, in SpoofInput) SpoofReport {
	host := in.Host
	if host == "" {
		host = canaryHost
	}
	probe := in.Probe
	if probe == nil {
		probe = probeVia
	}
	timeout := in.Timeout
	if timeout <= 0 {
		timeout = defaultSpoofTimeout
	}
	if deadline, ok := ctx.Deadline(); ok {
		if left := time.Until(deadline); left < timeout {
			timeout = left
		}
	}

	type target struct {
		side, addr, network string
	}
	var targets []target
	system := in.SystemResolvers
	if system == nil {
		system = SystemResolvers()
	}
	for _, s := range system {
		if n := normalizeResolver(s); n != "" {
			targets = append(targets, target{side: "system", addr: n})
		}
	}
	for _, r := range in.TunnelResolvers {
		network, addr, _ := canaryTarget(r)
		if network != "udp" && network != "tcp" {
			continue
		}
		targets = append(targets, target{side: "tunnel", addr: addr, network: network})
		break
	}
	if len(targets) == 0 {
		return SpoofReport{Verdict: SpoofUnresolved, Detail: "no resolvers to probe"}
	}
	if timeout <= 0 {
		return SpoofReport{Verdict: SpoofUnresolved, Detail: "no time left"}
	}

	answers := make([]SpoofAnswer, len(targets))
	var wg sync.WaitGroup
	for i, tg := range targets {
		wg.Add(1)
		go func(i int, tg target) {
			defer wg.Done()
			answers[i] = queryRounds(ctx, probe, timeout, tg.network, tg.side, tg.addr, host)
		}(i, tg)
	}
	wg.Wait()

	return judgeSpoof(host, answers)
}

// queryRounds queries one resolver spoofRounds times and unions the
// answers, so round-robin rotation converges instead of looking like
// disagreement.
func queryRounds(ctx context.Context, probe func(context.Context, string, string, string) ([]string, error), timeout time.Duration, network, side, addr, host string) SpoofAnswer {
	answer := SpoofAnswer{Resolver: addr, Side: side}
	union := map[string]bool{}
	nxRounds, answered := 0, 0
	for range spoofRounds {
		qctx, cancel := context.WithTimeout(ctx, timeout)
		ips, err := probe(qctx, network, addr, host)
		cancel()
		var dnsErr *net.DNSError
		switch {
		case err == nil:
			answered++
			for ip := range answerSet(ips) {
				union[ip] = true
			}
		case errors.As(err, &dnsErr) && dnsErr.IsNotFound:
			answered++
			nxRounds++
		}
	}
	answer.NXDomain = answered > 0 && nxRounds == answered
	for ip := range union {
		answer.IPs = append(answer.IPs, ip)
	}
	sort.Strings(answer.IPs)
	return answer
}

// judgeSpoof reduces per-resolver answers to a verdict. It is a pure
// function so the verdict table stays testable without network fakes.
func judgeSpoof(host string, answers []SpoofAnswer) SpoofReport {
	report := SpoofReport{Answers: answers}
	var resolved, nx []SpoofAnswer
	for _, a := range answers {
		switch {
		case a.NXDomain:
			nx = append(nx, a)
		case len(a.IPs) > 0:
			resolved = append(resolved, a)
		}
	}
	if len(resolved) == 0 {
		report.Verdict = SpoofUnresolved
		report.Detail = "no resolver answered for " + host
		return report
	}
	for _, a := range resolved {
		if bogus := bogusIPs(a.IPs); len(bogus) > 0 {
			report.Verdict = SpoofBogus
			report.Detail = "resolver " + a.Resolver + " (" + a.Side + ") answered non-routable " +
				strings.Join(bogus, ", ") + " for " + host
			return report
		}
	}
	if len(nx) > 0 {
		report.Verdict = SpoofNXDomain
		var from []string
		for _, a := range nx {
			from = append(from, a.Resolver+" ("+a.Side+")")
		}
		report.Detail = "NXDOMAIN for " + host + " from " + strings.Join(from, ", ") +
			" while other resolvers resolved it"
		return report
	}
	if len(resolved) >= 2 {
		// An address seen by only one resolver while the others agree
		// without it is a sticky injection, not rotation: rotation
		// addresses are shared across resolvers.
		freq := map[string]int{}
		for _, a := range resolved {
			for ip := range answerSet(a.IPs) {
				freq[ip]++
			}
		}
		for _, a := range resolved {
			var unique []string
			for ip := range answerSet(a.IPs) {
				if freq[ip] < 2 {
					unique = append(unique, ip)
				}
			}
			if len(unique) > 0 {
				sort.Strings(unique)
				report.Verdict = SpoofInconsistent
				report.Detail = "resolver " + a.Resolver + " (" + a.Side + ") alone answers " +
					strings.Join(unique, ", ") + " for " + host + ": the others disagree"
				return report
			}
		}
	}
	union := map[string]bool{}
	for _, a := range resolved {
		for ip := range answerSet(a.IPs) {
			union[ip] = true
		}
	}
	if host == canaryHost && !intersectsExpected(union) {
		report.Verdict = SpoofInconsistent
		report.Detail = "every resolver agreed on " + strings.Join(sortedSet(union), ", ") +
			" for " + host + ", which is outside the documented canary answer set: all paths look tampered"
		return report
	}
	report.Verdict = SpoofOK
	report.Detail = "all resolvers agree on " + host + ": " + strings.Join(sortedSet(union), ", ")
	return report
}

// bogusIPs returns the answers that can never be legitimate for a public
// name: private, loopback, link-local, multicast, unspecified, and other
// reserved ranges. A censor sinkhole (e.g. 10.0.0.0/8, 127.0.0.1) shows up
// here.
func bogusIPs(ips []string) []string {
	var out []string
	for _, s := range ips {
		addr, err := netip.ParseAddr(strings.TrimSpace(s))
		if err != nil {
			continue
		}
		if !addr.IsGlobalUnicast() || addr.IsPrivate() {
			out = append(out, addr.String())
		}
	}
	return out
}

// answerSet canonicalizes an answer list into a set for comparison.
func answerSet(ips []string) map[string]bool {
	set := make(map[string]bool, len(ips))
	for _, s := range ips {
		if addr, err := netip.ParseAddr(strings.TrimSpace(s)); err == nil {
			set[addr.String()] = true
		} else if s = strings.TrimSpace(s); s != "" {
			set[s] = true
		}
	}
	return set
}

func sortedSet(set map[string]bool) []string {
	out := make([]string, 0, len(set))
	for k := range set {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// intersectsExpected reports whether any answer belongs to the documented
// canary set.
func intersectsExpected(set map[string]bool) bool {
	for k := range set {
		if canaryExpectedAnswers[k] {
			return true
		}
	}
	return false
}
