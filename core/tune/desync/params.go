package desync

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
)

// Method is one desync primitive the tuner can combine. The set mirrors
// what sora's executors can do today (tpws) plus what nfqws adds, so the
// genome stays executable instead of aspirational.
type Method uint8

const (
	// MethodNone sends the handshake untouched: the control arm.
	MethodNone Method = iota
	// MethodSplit segments the handshake at SplitPos (--split-pos).
	MethodSplit
	// MethodDisorder sends the second part of a split first (--disorder).
	MethodDisorder
	// MethodOOB attaches an out-of-band byte to the split (--oob).
	MethodOOB
	// MethodTLSRec re-splits the ClientHello into two TLS records (--tlsrec).
	MethodTLSRec
	// MethodFake injects a fake packet before the real one (nfqws
	// --dpi-desync=fake). Needs nfqws; tpws cannot do this.
	MethodFake
	// MethodHTTPShuffle reshapes plain-HTTP requests (hostcase, hostdot,
	// method spacing). TLS-only censors ignore it; HTTP keyword censors
	// react to it.
	MethodHTTPShuffle
)

// String renders the method for logs and stable IDs.
func (m Method) String() string {
	switch m {
	case MethodNone:
		return "none"
	case MethodSplit:
		return "split"
	case MethodDisorder:
		return "disorder"
	case MethodOOB:
		return "oob"
	case MethodTLSRec:
		return "tlsrec"
	case MethodFake:
		return "fake"
	case MethodHTTPShuffle:
		return "httpshuffle"
	default:
		return "unknown"
	}
}

// Scope limits the trick to one application layer, like nfqws --filter-l7.
// Empty means the executor's default (usually both TLS and HTTP for tpws).
type Scope string

const (
	ScopeTLS  Scope = "tls"
	ScopeHTTP Scope = "http"
	ScopeQUIC Scope = "quic"
)

// Params is one genome: a bounded point in desync-parameter space.
//
// The fields are deliberately coarse. Geneva's full action trees are
// expressive but unsearchable on a user's machine; a bounded grid over
// the axes blockcheck walks manually (method, split-pos, fooling, fake
// variant, TTL/autottl, repeats) finds working strategies in practice
// while staying quiet and fast.
type Params struct {
	Method Method
	// SplitPos positions the split: "1", "2", "sniext+1", "midsld+2",
	// "method+1", "host+1". Used by Split, Disorder, OOB and Fake.
	SplitPos string
	// Fooling degrades the fake/disorder packet so the censor's stack
	// drops it while the real server tolerates it: "badseq", "md5sig",
	// "ts". nfqws-only; tpws has no fooling.
	Fooling string
	// FakeProto selects the fake payload: "tls" (ClientHello) or "quic"
	// (Initial). Only meaningful with MethodFake; nfqws-only.
	FakeProto string
	// TTL sets a fixed TTL on the fake packet so it dies before the
	// server. 0 means unset. nfqws-only.
	TTL int
	// AutoTTL derives the fake TTL from the path instead of fixing it
	// (nfqws --dpi-desync-ttl=auto). nfqws-only.
	AutoTTL bool
	// Repeats duplicates the fake injection. Values >1 are nfqws-only.
	Repeats int
	// Scope limits the trick to one application layer.
	Scope Scope
}

// RequiresNFQWS reports whether any field needs nfqws. tpws cannot
// express those fields; before the nfqws executor landed
// (core/engine/bypass) such candidates had to wait — now they run
// through BypassStrategy/NFQWSArgs below. Callers must still check:
// feeding an nfqws-only genome to the tpws subset (Args) drops the
// fields silently.
func (p Params) RequiresNFQWS() bool {
	return p.Method == MethodFake ||
		p.Fooling != "" ||
		p.FakeProto != "" ||
		p.TTL > 0 ||
		p.AutoTTL ||
		p.Repeats > 1
}

// Engine names the executor that can run these params.
func (p Params) Engine() string {
	if p.RequiresNFQWS() {
		return "nfqws"
	}
	return "tpws"
}

// ID is the stable identity of a genome: what the cache, the rotator and
// the journal store. Two Params with the same ID are the same strategy.
func (p Params) ID() string {
	var b strings.Builder
	b.WriteString("d/")
	b.WriteString(p.Method.String())
	if p.SplitPos != "" {
		b.WriteString(":")
		b.WriteString(p.SplitPos)
	}
	if p.Fooling != "" {
		b.WriteString("|fool:")
		b.WriteString(p.Fooling)
	}
	if p.FakeProto != "" {
		b.WriteString("|fake:")
		b.WriteString(p.FakeProto)
	}
	if p.TTL > 0 {
		b.WriteString("|ttl:")
		b.WriteString(strconv.Itoa(p.TTL))
	}
	if p.AutoTTL {
		b.WriteString("|autottl")
	}
	if p.Repeats > 1 {
		b.WriteString("|rep:")
		b.WriteString(strconv.Itoa(p.Repeats))
	}
	if p.Scope != "" {
		b.WriteString("|")
		b.WriteString(string(p.Scope))
	}
	return b.String()
}

// Args renders the tpws-supported subset as command-line arguments, in the
// style of core/engine/bypass.Args. Fields tpws cannot express (fooling,
// fake payloads, TTL, autottl, repeats>1) are silently dropped — call
// RequiresNFQWS first and never feed an nfqws-only genome to tpws.
func (p Params) Args() []string {
	var args []string
	if p.SplitPos != "" {
		args = append(args, "--split-pos="+p.SplitPos)
	}
	switch p.Method {
	case MethodDisorder:
		dis := "--disorder"
		if p.Scope == ScopeTLS || p.Scope == ScopeHTTP {
			dis += "=" + string(p.Scope)
		}
		args = append(args, dis)
	case MethodOOB:
		oob := "--oob"
		if p.Scope == ScopeTLS || p.Scope == ScopeHTTP {
			oob += "=" + string(p.Scope)
		}
		args = append(args, oob)
	case MethodTLSRec:
		rec := "sniext+1"
		if p.SplitPos != "" {
			rec = p.SplitPos
		}
		args = append(args, "--tlsrec="+rec)
	case MethodHTTPShuffle:
		args = append(args, "--hostcase", "--hostdot")
	}
	return args
}

// Describe renders one human line for the journal and the UI: method,
// position, engine, and the nfqws caveat when it applies.
func (p Params) Describe() string {
	var b strings.Builder
	b.WriteString(p.Method.String())
	if p.SplitPos != "" {
		fmt.Fprintf(&b, " @%s", p.SplitPos)
	}
	if p.Scope != "" {
		fmt.Fprintf(&b, " [%s]", p.Scope)
	}
	if p.RequiresNFQWS() {
		b.WriteString(" (needs nfqws)")
	}
	return b.String()
}

// BypassStrategy converts the genome into the engine strategy the
// bypass executors run. The conversion is faithful or it refuses:
// ok=false means the genome has no exact rendering (a TTL without the
// fake method, OOB combined with nfqws-only fooling, the none control
// arm) and a caller must skip it rather than run an approximation.
//
// Genomes that need nfqws render through the desync fields: fake
// stays fake, split/disorder become their nfqws forms (split2,
// disorder2), and the filters are set from the genome's scope/proto
// so the executor queues exactly the traffic the genome targets —
// mirroring the reference set's filters in bypass.DefaultStrategy.
// Genomes tpws can express render through the legacy fields.
func (p Params) BypassStrategy() (engine.BypassStrategy, bool) {
	// TTL, autottl, repeats and the fake payload all ride on the fake
	// packet; without the fake method they are unexecutable (plan
	// validation agrees). FakeProto belongs in this list: it used to
	// leak into split2/disorder2 strategies as FakeTLS/FakeQUIC, which
	// validation then rejected ("fake payloads need the fake desync
	// method") — a converted genome that can only fail closed.
	if p.Method != MethodFake && (p.TTL > 0 || p.AutoTTL || p.Repeats > 1 || p.FakeProto != "") {
		return engine.BypassStrategy{}, false
	}
	// A fixed TTL and autottl are two answers to the same question;
	// plan validation treats them as mutually exclusive even on the
	// fake method, so the combination has no faithful rendering.
	if p.TTL > 0 && p.AutoTTL {
		return engine.BypassStrategy{}, false
	}
	// Split, disorder and OOB are defined by their position: without
	// one the tpws rendering changes nothing (or reorders nothing),
	// which validation rejects. TLSRec defaults its position below
	// and Fake/HTTPShuffle carry a strategy without one, so only
	// these three methods refuse.
	if p.SplitPos == "" && (p.Method == MethodSplit || p.Method == MethodDisorder || p.Method == MethodOOB) {
		return engine.BypassStrategy{}, false
	}
	var s engine.BypassStrategy
	if p.SplitPos != "" {
		s.SplitPos = []string{p.SplitPos}
	}
	nfq := p.RequiresNFQWS()
	switch p.Method {
	case MethodFake:
		s.Desync = []string{"fake"}
	case MethodSplit:
		if nfq {
			s.Desync = []string{"split2"}
		}
	case MethodDisorder:
		if nfq {
			s.Desync = []string{"disorder2"}
		} else {
			s.Disorder = true
		}
	case MethodOOB:
		if nfq {
			return engine.BypassStrategy{}, false // nfqws has no OOB byte
		}
		s.OOB = true
	case MethodTLSRec:
		if nfq {
			return engine.BypassStrategy{}, false
		}
		s.TLSRecord = "sniext+1"
		if p.SplitPos != "" {
			s.TLSRecord = p.SplitPos
		}
		s.SplitPos = nil
	case MethodHTTPShuffle:
		if nfq {
			return engine.BypassStrategy{}, false
		}
		s.HostCase, s.HostDot = true, true
	default: // MethodNone: the control arm carries no strategy at all.
		return engine.BypassStrategy{}, false
	}
	if len(s.Desync) == 0 {
		return s, true
	}
	s.Fooling = p.Fooling
	switch p.FakeProto {
	case "tls":
		s.FakeTLS = "tls"
	case "quic":
		s.FakeQUIC = "quic"
	}
	if p.Method == MethodFake {
		s.TTL, s.AutoTTL, s.Repeats = p.TTL, p.AutoTTL, p.Repeats
	}
	// Filters: the executor refuses unfiltered strategies, so a
	// genome that names no scope still gets the reference filter set
	// for its protocol family.
	switch {
	case p.FakeProto == "quic" || p.Scope == ScopeQUIC:
		s.FilterUDP, s.FilterL7 = "443", "quic"
	case p.Scope == ScopeHTTP:
		s.FilterTCP, s.FilterL7 = "80", "http"
	default:
		s.FilterTCP, s.FilterL7 = "80,443", "tls"
	}
	return s, true
}

// convertsValidly reports whether the genome converts faithfully to a
// strategy plan validation accepts. It is the tuner's production
// invariant in one place — every genome the search generates or mutates
// must satisfy it (genome_invariant_test.go pins it over the whole
// bounded space) — so generators filter through it instead of
// re-encoding the conversion rules and drifting from them.
func (p Params) convertsValidly() bool {
	s, ok := p.BypassStrategy()
	if !ok {
		return false
	}
	o := engine.Outbound{ID: "desync", Protocol: engine.ProtocolBypass, Bypass: &s}
	return o.Validate() == nil
}

// NFQWSArgs renders the full genome as nfqws arguments, through the
// same renderer the executor uses (bypass.NFQWSArgs), so a tuned
// strategy and a hand-written one can never drift apart. ok=false
// when the genome has no faithful nfqws rendering.
func (p Params) NFQWSArgs(home string) ([]string, bool) {
	s, ok := p.BypassStrategy()
	if !ok || bypass.BackendOf(s) != bypass.BackendNFQWS {
		return nil, false
	}
	return bypass.NFQWSArgs(s, home), true
}
