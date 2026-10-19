package censor

import (
	"strings"
	"time"
)

// Confidence bounds. A single attempt never claims more than singleAttemptCap:
// certainty needs corroboration, and this package would rather understate.
const (
	// minClaimConfidence is the floor for naming a cause. Below it the
	// detector returns KindUnknown: an uncertain verdict must read as
	// uncertainty, never as a weak accusation.
	minClaimConfidence = 0.35
	// singleAttemptCap bounds what one attempt may claim.
	singleAttemptCap = 0.85
	// sniResetWindow bounds "right after the ClientHello": a reset inside
	// this window, with no server bytes, is the SNI-block tell. Wider
	// windows admit ordinary server resets and would manufacture claims.
	sniResetWindow = 3 * time.Second
)

// Detector classifies failed connection attempts. It is stateless and safe
// for concurrent use.
type Detector struct{}

// candidate is one rule's reading of the attempt.
type candidate struct {
	kind       Kind
	confidence float64
	evidence   []string
}

// Detect classifies the attempt and returns the verdict. Sparse or
// contradictory input yields KindUnknown with low confidence and an
// explanation that says the evidence was insufficient.
func (Detector) Detect(a Attempt) Verdict {
	v := Verdict{At: time.Now().UTC()}
	best := candidate{kind: KindUnknown, confidence: 0.15,
		evidence: []string{"not enough was observed about this attempt to name a cause"}}

	for _, rule := range rules {
		if c, ok := rule(a); ok && c.confidence > best.confidence {
			best = c
		}
	}
	if best.confidence > singleAttemptCap {
		best.confidence = singleAttemptCap
	}
	if best.confidence < minClaimConfidence {
		return Verdict{
			Kind:        KindUnknown,
			Confidence:  best.confidence,
			Explanation: "The connection failed, but what was observed isn't enough to tell interference apart from an ordinary failure.",
			Evidence:    best.evidence,
			At:          v.At,
		}
	}
	profile, hasProfile := RecommendedProfile(best.kind)
	return Verdict{
		Kind:        best.kind,
		Confidence:  best.confidence,
		Profile:     profile,
		HasProfile:  hasProfile,
		Explanation: explain(best.kind, best.confidence),
		Evidence:    best.evidence,
		At:          v.At,
	}
}

// rule reads the attempt and reports a candidate classification.
type rule func(Attempt) (candidate, bool)

// rules are tried in any order; the most confident candidate wins. Each rule
// is narrow on purpose: a signature that also matches ordinary failures must
// not produce a confident claim.
var rules = []rule{
	dnsPoisoningRule,
	tcpRefusedRule,
	ipBlockingRule,
	tcpResetRule,
	sniBlockingRule,
	tlsAlertRule,
	handshakeTimeoutRule,
	certRule,
	appResetRule,
	dataResetRule,
}

// failureScan reduces the event log to what the rules need: the first
// terminal event, the furthest stage reached, and byte/time context.
type failureScan struct {
	terminal   *Event
	furthest   Stage
	timeToFail time.Duration
	// sawBytesIn reports whether the far end ever sent payload bytes.
	sawBytesIn bool
	// resolvedTo records the last resolved address, if observed.
	resolvedTo string
}

func scan(a Attempt) failureScan {
	s := failureScan{}
	for i, e := range a.Events {
		if e.Stage > s.furthest && e.What != WhatUnknown {
			s.furthest = e.Stage
		}
		if e.BytesIn > 0 {
			s.sawBytesIn = true
		}
		if e.Stage == StageDNS && e.What == WhatResolved && e.Detail != "" {
			s.resolvedTo = e.Detail
		}
		if s.terminal == nil && isTerminal(e.What) {
			ev := a.Events[i]
			s.terminal = &ev
			if !a.StartedAt.IsZero() && !ev.At.IsZero() {
				s.timeToFail = ev.At.Sub(a.StartedAt)
			}
		}
	}
	return s
}

func isTerminal(w What) bool {
	switch w {
	case WhatRemoteReset, WhatRemoteClose, WhatLocalTimeout, WhatTLSAlert, WhatError:
		return true
	default:
		return false
	}
}

func offset(a Attempt, e *Event) time.Duration {
	if a.StartedAt.IsZero() || e.At.IsZero() {
		return 0
	}
	return e.At.Sub(a.StartedAt)
}

// dnsPoisoningRule fires on resolver lies: NXDOMAIN for a name known to have
// existed, or an answer that contradicts the last known-good address. An
// NXDOMAIN for a name never seen working is only weak evidence — names die —
// so without KnownGoodHost or an ExpectedIP mismatch it stays below the claim
// floor and the verdict remains Unknown.
func dnsPoisoningRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.Stage != StageDNS {
		return candidate{}, false
	}
	d := strings.ToLower(t.Detail)
	isNX := strings.Contains(d, "nxdomain") || strings.Contains(d, "no such host")
	if s.resolvedTo != "" && a.ExpectedIP != "" && s.resolvedTo != a.ExpectedIP {
		return candidate{KindDNSPoisoning, 0.8, []string{
			"the name resolved to " + s.resolvedTo + ", but it used to resolve to " + a.ExpectedIP,
		}}, true
	}
	if isNX {
		if a.KnownGoodHost {
			return candidate{KindDNSPoisoning, 0.8, []string{
				"the resolver says this name does not exist, but it resolved before",
			}}, true
		}
		return candidate{KindDNSPoisoning, 0.3, []string{
			"the resolver says this name does not exist, but it was never seen working",
		}}, true
	}
	return candidate{}, false
}

// tcpRefusedRule: a SYN answered with RST means the host is alive and the
// port is closed. That is a dead or misconfigured server — a censor drops
// packets, it does not run a connection-refusing stack. Evidence *against*
// censorship, reported confidently so the user stops blaming the path.
func tcpRefusedRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.Stage != StageTCP || t.What != WhatError {
		return candidate{}, false
	}
	if !strings.Contains(strings.ToLower(t.Detail), "refus") {
		return candidate{}, false
	}
	return candidate{KindNoInterference, 0.85, []string{
		"the server answered the connection attempt and refused it: the host is up, the port is closed",
	}}, true
}

// ipBlockingRule: the SYN went unanswered until our deadline. IP-level
// filtering, a dead host, and a dead route all look like this, so the claim
// stays medium no matter what — the explanation says so.
func ipBlockingRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.Stage != StageTCP || t.What != WhatLocalTimeout {
		return candidate{}, false
	}
	return candidate{KindIPBlocking, 0.55, []string{
		"the server did not answer the connection attempt before the deadline",
		"no reset or refusal arrived: the packets went unanswered",
	}}, true
}

// tcpResetRule: RST immediately after connect, before any handshake bytes.
// Middleboxes inject these; a real server stack rarely RSTs a fresh
// connection it just accepted.
func tcpResetRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.Stage != StageTCP || t.What != WhatRemoteReset {
		return candidate{}, false
	}
	if offset(a, t) > sniResetWindow {
		return candidate{}, false
	}
	return candidate{KindRSTInjection, 0.6, []string{
		"the connection was reset right after it was established, before any handshake bytes",
	}}, true
}

// sniBlockingRule: the tell this package exists for. TCP connected, the
// ClientHello went out, and the path tore the connection down before a single
// server byte arrived. Servers do not do this; filters reacting to the
// handshake — almost always the SNI — do.
func sniBlockingRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.Stage != StageTLS || !a.Target.TLS {
		return candidate{}, false
	}
	if t.What != WhatRemoteReset && t.What != WhatRemoteClose {
		return candidate{}, false
	}
	if s.sawBytesIn || t.BytesIn > 0 {
		return candidate{}, false
	}
	sent := false
	for _, e := range a.Events {
		if e.Stage == StageTLS && e.What == WhatSent {
			sent = true
		}
	}
	if !sent {
		return candidate{}, false
	}
	if offset(a, t) > sniResetWindow {
		// Late reset with no server bytes at all is stranger than SNI
		// blocking; do not claim it.
		return candidate{}, false
	}
	conf := 0.8
	ev := []string{
		"the connection was torn down right after the TLS handshake started, before the server sent anything",
	}
	if a.Target.SNI != "" {
		ev = append(ev, "the handshake carried SNI "+a.Target.SNI)
	}
	return candidate{KindSNIBlocking, conf, ev}, true
}

// tlsAlertRule: the far end aborted the handshake with an alert. Alerts are
// the server's voice, but a handshake_failure to a known-good SNI right after
// the ClientHello is also how some filters answer. Medium at most.
func tlsAlertRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.Stage != StageTLS || t.What != WhatTLSAlert {
		return candidate{}, false
	}
	conf := 0.5
	if a.KnownGoodHost {
		conf = 0.6
	}
	return candidate{KindSNIBlocking, conf, []string{
		"the TLS handshake was aborted by the far end (" + t.Detail + ")",
	}}, true
}

// handshakeTimeoutRule: the handshake stalled — packets flowed, then silence
// until our deadline. The DPI stall signature. Kept medium: congested paths
// stall too.
func handshakeTimeoutRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.What != WhatLocalTimeout {
		return candidate{}, false
	}
	if t.Stage != StageTLS && t.Stage != StageApp {
		return candidate{}, false
	}
	return candidate{KindHandshakeTimeout, 0.6, []string{
		"the handshake started but stalled: no failure arrived, the deadline expired",
	}}, true
}

// certRule: a certificate failure is *not* claimed as censorship. It is a
// captive portal, a corporate MITM, or a misconfigured server — and this
// package cannot tell which. Naming it interference would be a lie, so it
// stays below the claim floor and surfaces as Unknown with an honest note.
func certRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.What != WhatError {
		return candidate{}, false
	}
	d := strings.ToLower(t.Detail)
	if !strings.Contains(d, "cert") && !strings.Contains(d, "tls") {
		return candidate{}, false
	}
	return candidate{KindUnknown, 0.25, []string{
		"the server presented a certificate that failed verification: this can be a portal, an intercepting middlebox, or a misconfigured server, and they are indistinguishable here",
	}}, true
}

// appResetRule: reset during the VPN protocol handshake, after TLS (or on a
// non-TLS port) completed. The path let the lower layers through and killed
// the application handshake: protocol-aware filtering.
func appResetRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.Stage != StageApp {
		return candidate{}, false
	}
	if t.What != WhatRemoteReset {
		return candidate{}, false
	}
	return candidate{KindRSTInjection, 0.7, []string{
		"the connection survived TCP and TLS but was reset during the VPN handshake: the path inspects past the transport layer",
	}}, true
}

// dataResetRule: reset mid-session after traffic flowed. Kept modest: long
// idle connections also die to NAT timeouts, and the explanation admits it.
func dataResetRule(a Attempt) (candidate, bool) {
	s := scan(a)
	t := s.terminal
	if t == nil || t.Stage != StageData || t.What != WhatRemoteReset {
		return candidate{}, false
	}
	if !s.sawBytesIn {
		return candidate{}, false
	}
	return candidate{KindRSTInjection, 0.5, []string{
		"an established session carrying traffic was reset by the path",
		"long-idle connections can also die to NAT timeouts, so this is suggestive, not conclusive",
	}}, true
}

// explain renders the user-facing account. Every string understates rather
// than overstates: the user must be able to trust these sentences.
func explain(k Kind, conf float64) string {
	hedge := ""
	if conf < 0.5 {
		hedge = " It is also possible this is an ordinary failure, so treat this as a lead, not a diagnosis."
	} else if conf < 0.75 {
		hedge = " This is a likely explanation, not a certain one."
	}
	switch k {
	case KindNoInterference:
		return "The server answered and refused the connection itself. It is reachable, so this does not look like censorship — the server or its configuration is at fault."
	case KindRSTInjection:
		return "Something on the path is forcibly resetting your connections." + hedge + " Fragmenting the handshake or disguising the protocol usually helps."
	case KindHandshakeTimeout:
		return "The handshake starts but then stalls until it times out, as if traffic is being held on the path." + hedge + " A different transport or TLS camouflage usually helps."
	case KindDNSPoisoning:
		return "Your DNS resolver gave a wrong answer for this server — the name is being spoofed on the path." + hedge + " Switching to an encrypted DNS resolver usually helps."
	case KindSNIBlocking:
		return "The connection is cut the moment the handshake reveals which server you are reaching. Your provider can see the destination and is blocking it." + hedge + " TLS camouflage or Encrypted Client Hello usually helps."
	case KindIPBlocking:
		return "The server does not answer at all. It may be down, or its address may be blocked from your network." + hedge + " Trying another server or port is the fastest next step."
	default:
		return "The connection failed, but what was observed isn't enough to tell interference apart from an ordinary failure."
	}
}
