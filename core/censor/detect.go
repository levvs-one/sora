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

	// One scan serves every rule: scan is a pure reduction of the
	// event log, so sharing it cannot change any rule's reading —
	// it only stops the detector from re-walking the log per rule.
	s := scan(a)
	for _, rule := range rules {
		if c, ok := rule(a, s); ok && c.confidence > best.confidence {
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

// rule reads the attempt and reports a candidate classification. The
// failureScan is computed once by Detect and shared by all rules.
type rule func(Attempt, failureScan) (candidate, bool)

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
	clientHelloStallRule,
	certRule,
	appResetRule,
	dataResetRule,
	dataStallRule,
}

// failureScan reduces the event log to what the rules need: the first
// terminal event, the furthest stage reached, byte context, and the timing
// anchors the time-windowed rules measure against.
type failureScan struct {
	terminal *Event
	furthest Stage
	// tcpConnectedAt is when the last TCP connect completed; tlsSentAt is
	// when the last ClientHello went out. The "immediate reset" rules
	// anchor on these, not on the attempt start: "immediate" means right
	// after the connect or the ClientHello. When the attempt carries no
	// timestamps the anchors stay zero and those rules stay silent — a
	// missing clock must never read as "instant".
	tcpConnectedAt time.Time
	tlsSentAt      time.Time
	// sawBytesIn reports whether the far end ever sent anything: counted
	// payload bytes, or an observed RECEIVED event. Zero inbound bytes at
	// a reset is the SNI-block tell.
	sawBytesIn bool
	// resolvedTo records the last resolved address, if observed.
	resolvedTo string
	// terminalDetail is the terminal event's Detail, lowercased once:
	// three rules match on it case-insensitively and each used to pay
	// for its own strings.ToLower.
	terminalDetail string
	// sawTLSSent reports whether any TLS-stage SENT event was observed,
	// regardless of timestamps (clientHelloStallRule's "the ClientHello
	// went out" check; tlsSentAt alone only records timed sends).
	sawTLSSent bool
	// maxBytesIn is the largest BytesIn any event reported
	// (dataStallRule's fallback when the terminal event has no count).
	maxBytesIn int64
}

func scan(a Attempt) failureScan {
	s := failureScan{}
	for i, e := range a.Events {
		if e.Stage > s.furthest && e.What != WhatUnknown {
			s.furthest = e.Stage
		}
		if i == 0 || e.BytesIn > s.maxBytesIn {
			s.maxBytesIn = e.BytesIn
		}
		if e.BytesIn > 0 || e.What == WhatReceived {
			s.sawBytesIn = true
		}
		if e.Stage == StageTLS && e.What == WhatSent {
			s.sawTLSSent = true
		}
		if e.Stage == StageDNS && e.What == WhatResolved && e.Detail != "" {
			s.resolvedTo = e.Detail
		}
		if e.Stage == StageTCP && e.What == WhatConnected && !e.At.IsZero() {
			s.tcpConnectedAt = e.At
		}
		if e.Stage == StageTLS && e.What == WhatSent && !e.At.IsZero() {
			s.tlsSentAt = e.At
		}
		if s.terminal == nil && isTerminal(e.What) {
			ev := a.Events[i]
			s.terminal = &ev
		}
	}
	if s.terminal != nil {
		s.terminalDetail = strings.ToLower(s.terminal.Detail)
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

// dnsPoisoningRule fires on resolver lies: NXDOMAIN for a name known to have
// existed, or an answer that contradicts the last known-good address. An
// NXDOMAIN for a name never seen working is only weak evidence — names die —
// so without KnownGoodHost or an ExpectedIP mismatch it stays below the claim
// floor and the verdict remains Unknown.
func dnsPoisoningRule(a Attempt, s failureScan) (candidate, bool) {
	t := s.terminal
	if t == nil || t.Stage != StageDNS {
		return candidate{}, false
	}
	d := s.terminalDetail
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
func tcpRefusedRule(a Attempt, s failureScan) (candidate, bool) {
	t := s.terminal
	if t == nil || t.Stage != StageTCP || t.What != WhatError {
		return candidate{}, false
	}
	if !strings.Contains(s.terminalDetail, "refus") {
		return candidate{}, false
	}
	return candidate{KindNoInterference, 0.85, []string{
		"the server answered the connection attempt and refused it: the host is up, the port is closed",
	}}, true
}

// ipBlockingRule: the SYN went unanswered until our deadline. IP-level
// filtering, a dead host, and a dead route all look like this, so the claim
// stays medium no matter what — the explanation says so.
func ipBlockingRule(a Attempt, s failureScan) (candidate, bool) {
	t := s.terminal
	if t == nil || t.Stage != StageTCP || t.What != WhatLocalTimeout {
		return candidate{}, false
	}
	return candidate{KindIPBlocking, 0.55, []string{
		"the server did not answer the connection attempt before the deadline",
		"no reset or refusal arrived: the packets went unanswered",
	}}, true
}

// tcpResetRule: RST around the TCP leg. Two readings, kept apart on purpose:
// a reset that lands while the dial is still in flight never saw an
// established connection — that is weak evidence (a filtered port answers
// this way too), so it claims little. A reset right after the connect, before
// any handshake bytes, is the middlebox signature: a real server stack
// rarely RSTs a fresh connection it just accepted.
func tcpResetRule(a Attempt, s failureScan) (candidate, bool) {
	t := s.terminal
	if t == nil || t.Stage != StageTCP || t.What != WhatRemoteReset {
		return candidate{}, false
	}
	if s.tcpConnectedAt.IsZero() || t.At.IsZero() {
		// The reset landed during the dial: the connection was never
		// established, so "right after connect" cannot be claimed.
		return candidate{KindRSTInjection, 0.45, []string{
			"the connection attempt was reset while connecting, before it was established",
			"a filtered or closed port can also answer with a reset, so this is only suggestive",
		}}, true
	}
	if dt := t.At.Sub(s.tcpConnectedAt); dt < 0 || dt > sniResetWindow {
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
func sniBlockingRule(a Attempt, s failureScan) (candidate, bool) {
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
	sent := !s.tlsSentAt.IsZero()
	if !sent || t.At.IsZero() {
		// Without a timed ClientHello there is no "right after the
		// ClientHello": the window cannot be checked, so the rule stays
		// silent instead of claiming on ordering alone.
		return candidate{}, false
	}
	if dt := t.At.Sub(s.tlsSentAt); dt < 0 || dt > sniResetWindow {
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
func tlsAlertRule(a Attempt, s failureScan) (candidate, bool) {
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
func handshakeTimeoutRule(a Attempt, s failureScan) (candidate, bool) {
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

// clientHelloStallRule: the ClientHello went out and then silence until
// our own deadline, with zero bytes from the server. This is the
// KZ-measured signature (OONI 2023-2024: sessions time out after the
// ClientHello): the path read the handshake and stalled instead of
// answering. Narrower and more confident than the generic
// handshake-timeout rule — ordinary congestion usually still lets some
// server bytes through, or stalls before the ClientHello is even sent.
func clientHelloStallRule(a Attempt, s failureScan) (candidate, bool) {
	t := s.terminal
	if t == nil || t.What != WhatLocalTimeout || t.Stage != StageTLS {
		return candidate{}, false
	}
	if s.sawBytesIn || t.BytesIn > 0 {
		return candidate{}, false
	}
	if !s.sawTLSSent {
		return candidate{}, false
	}
	ev := []string{
		"the client hello was sent and the server never answered: the path stalled right after the handshake started",
	}
	if a.Target.SNI != "" {
		ev = append(ev, "the handshake carried SNI "+a.Target.SNI)
	}
	return candidate{KindHandshakeTimeout, 0.7, ev}, true
}

// certRule: a certificate failure is *not* claimed as censorship. It is a
// captive portal, a corporate MITM, or a misconfigured server — and this
// package cannot tell which. Naming it interference would be a lie, so it
// stays below the claim floor and surfaces as Unknown with an honest note.
func certRule(a Attempt, s failureScan) (candidate, bool) {
	t := s.terminal
	if t == nil || t.What != WhatError {
		return candidate{}, false
	}
	d := s.terminalDetail
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
func appResetRule(a Attempt, s failureScan) (candidate, bool) {
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
func dataResetRule(a Attempt, s failureScan) (candidate, bool) {
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
	case KindDataStall:
		return "The connection worked at first, then froze mid-transfer: data arrived, then nothing until the timeout, with no reset. This is the throttling signature — the path holds the session instead of cutting it." + hedge + " A different server or transport usually helps; reshaping the handshake does not, the handshake already succeeded."
	default:
		return "The connection failed, but what was observed isn't enough to tell interference apart from an ordinary failure."
	}
}
