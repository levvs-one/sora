package desync

import (
	"fmt"
	"strconv"
	"strings"
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

// RequiresNFQWS reports whether any field needs nfqws. sora executes
// bypass through tpws today (core/engine/bypass); a candidate that
// requires nfqws must wait for the nfqws executor instead of failing
// silently under tpws.
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
