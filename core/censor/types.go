package censor

import (
	"time"

	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
)

// Kind names the classified cause of a failed connection attempt.
type Kind int

const (
	// KindUnknown means the evidence does not support any classification.
	// This is the honest answer for sparse or ambiguous input, and callers
	// must treat it as "no claim", not as a weak claim.
	KindUnknown Kind = iota
	// KindNoInterference means the failure carries evidence against
	// censorship: the far end answered and refused, or presented a bad
	// certificate. The server or its configuration is at fault, not the path.
	KindNoInterference
	// KindRSTInjection means an established or in-progress connection was
	// torn down by a forged RST: mid-stream resets, or a reset immediately
	// after the TCP connect, before any application bytes.
	KindRSTInjection
	// KindHandshakeTimeout means the handshake stalled: packets flowed, then
	// silence until our own deadline. The classic DPI stall signature.
	KindHandshakeTimeout
	// KindDNSPoisoning means the resolver lied: NXDOMAIN for a name known to
	// exist, or an answer that does not match the expected address.
	KindDNSPoisoning
	// KindSNIBlocking means the connection died right after the ClientHello,
	// before any server bytes: the path reacted to the handshake itself,
	// almost always to the SNI.
	KindSNIBlocking
	// KindIPBlocking means the SYN went unanswered: the address:port is
	// unreachable from here, whether filtered or simply down.
	KindIPBlocking
)

// String renders the kind for logs and UI.
func (k Kind) String() string {
	switch k {
	case KindNoInterference:
		return "no_interference"
	case KindRSTInjection:
		return "rst_injection"
	case KindHandshakeTimeout:
		return "handshake_timeout"
	case KindDNSPoisoning:
		return "dns_poisoning"
	case KindSNIBlocking:
		return "sni_blocking"
	case KindIPBlocking:
		return "ip_blocking"
	default:
		return "unknown"
	}
}

// Stage is the connection-stack step an event belongs to.
type Stage int

const (
	// StageUnknown is for events that cannot be attributed to a step.
	StageUnknown Stage = iota
	// StageDNS covers name resolution.
	StageDNS
	// StageTCP covers the SYN/connect leg.
	StageTCP
	// StageTLS covers the TLS handshake after TCP connect.
	StageTLS
	// StageApp covers the VPN protocol handshake inside (or without) TLS.
	StageApp
	// StageData covers the established session carrying traffic.
	StageData
)

// What names what happened at a stage: how far the attempt got and who
// closed it. "Who closed" is the most discriminating signal the detector has:
// a remote RST is someone else's decision; a local timeout is ours.
type What int

const (
	WhatUnknown What = iota
	// WhatResolved marks a completed DNS lookup.
	WhatResolved
	// WhatConnected marks a completed TCP connect.
	WhatConnected
	// WhatSent marks bytes handed to the path (e.g. the ClientHello).
	WhatSent
	// WhatReceived marks bytes arriving from the far end.
	WhatReceived
	// WhatRemoteReset marks a RST from the path: the connection was torn
	// down by someone other than us.
	WhatRemoteReset
	// WhatRemoteClose marks an orderly FIN close by the far end.
	WhatRemoteClose
	// WhatLocalTimeout marks our own deadline expiring: silence, not an
	// answer.
	WhatLocalTimeout
	// WhatTLSAlert marks a TLS alert aborting the handshake.
	WhatTLSAlert
	// WhatError marks any other terminal failure; Detail carries the cause.
	WhatError
)

// Event is one instrumented observation of a connection attempt.
type Event struct {
	// At is the time of the event; offsets from the attempt start are what
	// the signatures use.
	At time.Time
	// Stage is the connection-stack step.
	Stage Stage
	// What is what happened.
	What What
	// BytesIn and BytesOut are the cumulative payload bytes in each
	// direction when known. Zero inbound bytes at a reset is the SNI-block
	// tell: the path killed the connection before the server could speak.
	BytesIn, BytesOut int64
	// Detail carries the cause for WhatError/WhatTLSAlert ("refused",
	// "nxdomain", "handshake_failure", ...).
	Detail string
}

// Target is the endpoint an attempt is made against.
type Target struct {
	Host string
	Port int
	// SNI is the server name sent in the ClientHello, if any.
	SNI string
	// TLS reports whether the attempt performs a TLS handshake.
	TLS bool
	// Protocol is the VPN protocol name (vless, vmess, ss, ...) for context.
	Protocol string
}

// Attempt is one failed connection attempt with its wire observations.
type Attempt struct {
	// ServerID identifies the server in the client's bookkeeping.
	ServerID string
	Target   Target
	// KnownGoodHost reports that this host resolved and/or connected before,
	// so a sudden NXDOMAIN or silence is surprising. It is the cheapest
	// strong signal against "the name never existed".
	KnownGoodHost bool
	// ExpectedIP, when set, is the address the name resolved to last time it
	// worked; a different answer is DNS interference, not a guess.
	ExpectedIP string
	// StartedAt anchors event offsets.
	StartedAt time.Time
	// Events are the instrumented observations, oldest first.
	Events []Event
}

// ProfileRef points at an obfuscation preset that may route around the
// detected interference. Preset is the sora.obfs.v1.ObfsPreset contract, so
// the client can apply it directly; DisplayName and Why are the
// human-readable account shown next to the suggestion.
type ProfileRef struct {
	// Preset is the obfuscation preset to suggest.
	Preset obfsv1.ObfsPreset
	// DisplayName is the human-readable preset name.
	DisplayName string
	// Why explains the strategy in one line: what the preset changes about
	// the connection's appearance on the wire.
	Why string
}

// Verdict is the detector's answer about one failed attempt.
type Verdict struct {
	Kind Kind
	// Confidence is 0..1. Below 0.35 the detector refuses to name a cause
	// and returns KindUnknown instead: an uncertain verdict must read as
	// uncertainty, never as a weak accusation.
	Confidence float64
	// Profile suggests the obfuscation preset most likely to help. It is
	// set only for actionable kinds; Unknown and NoInterference carry none.
	Profile ProfileRef
	// HasProfile reports whether Profile names a real suggestion.
	HasProfile bool
	// Explanation is a plain-language, user-facing account of what happened
	// and what helps. It never overstates the evidence.
	Explanation string
	// Evidence lists the observations the verdict rests on, most telling
	// first.
	Evidence []string
	// At is when the verdict was produced.
	At time.Time
}

// Band groups confidence for UI presentation.
func (v Verdict) Band() string {
	switch {
	case v.Confidence >= 0.75:
		return "high"
	case v.Confidence >= 0.5:
		return "medium"
	default:
		return "low"
	}
}
