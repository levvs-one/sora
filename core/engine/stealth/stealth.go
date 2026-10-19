// Package stealth grades how detectable a session plan looks to DPI.
//
// Every check encodes a public, documented DPI fact: fixed WireGuard header
// values and packet sizes, JA3-distinguishable default TLS ClientHello,
// Shadowsocks AEAD entropy heuristics, and so on. The score is a heuristic
// for the interface (0-100, higher means less detectable), not a security
// proof: a high score never means "undetectable".
package stealth

import (
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

// Severity ranks how much a finding helps a DPI box.
type Severity string

// Finding severities, from most to least helpful to an observer.
const (
	SeverityHigh   Severity = "high"
	SeverityMedium Severity = "medium"
	SeverityLow    Severity = "low"
	SeverityInfo   Severity = "info"
)

// Finding is one detectable feature of an outbound.
type Finding struct {
	OutboundID string
	Code       string
	Severity   Severity
	Summary    string
	Advice     string
}

// Report is the grading result of a whole plan.
type Report struct {
	// Score is 0-100; higher means less detectable. The plan scores as
	// its weakest selectable outbound: one leaky server is enough.
	Score    int
	Findings []Finding
}

// Deductions applied to an outbound score per severity.
const (
	deductHigh   = 20
	deductMedium = 8
	deductLow    = 3
)

// Grade evaluates every outbound of p and returns the plan report.
// A nil or empty plan has nothing on the wire and scores 100.
func Grade(p *engine.Plan) Report {
	rep := Report{Score: 100}
	if p == nil {
		return rep
	}
	fragment := p.Options.Fragment.Enabled
	for _, o := range p.Outbounds {
		if o.Protocol == engine.ProtocolDirect {
			continue
		}
		fs := gradeOutbound(o, fragment)
		score := 100
		for _, f := range fs {
			switch f.Severity {
			case SeverityHigh:
				score -= deductHigh
			case SeverityMedium:
				score -= deductMedium
			case SeverityLow:
				score -= deductLow
			}
		}
		if score < 0 {
			score = 0
		}
		if score < rep.Score {
			rep.Score = score
		}
		rep.Findings = append(rep.Findings, fs...)
	}
	return rep
}

// tlsProtocols are protocols whose stealth depends on their TLS layer.
func tlsProtocol(p engine.Protocol) bool {
	switch p {
	case engine.ProtocolVLESS, engine.ProtocolVMess, engine.ProtocolTrojan, engine.ProtocolAnyTLS:
		return true
	}
	return false
}

func gradeOutbound(o engine.Outbound, fragment bool) []Finding {
	var fs []Finding
	add := func(code string, sev Severity, summary, advice string) {
		fs = append(fs, Finding{OutboundID: o.ID, Code: code, Severity: sev, Summary: summary, Advice: advice})
	}
	// A chained outbound dials inside another tunnel: its own handshake is
	// not visible to DPI, only the outer leg is. This is the Mullvad bridge
	// pattern (WireGuard inside Shadowsocks).
	if o.Via != "" {
		add("chain/via", SeverityInfo,
			"outbound dials through another outbound; only the outer leg is visible to DPI",
			"harden the outer leg: it carries the whole fingerprint now")
		return fs
	}
	switch {
	case o.Protocol == engine.ProtocolWireGuard:
		gradeWireGuard(o, add)
	case tlsProtocol(o.Protocol):
		gradeTLS(o, fragment, add)
	case o.Protocol == engine.ProtocolShadowsocks:
		if o.Obfs == "" {
			add("ss/no-obfs", SeverityMedium,
				"plain Shadowsocks has known AEAD entropy and behaviour heuristics",
				"enable an obfs plugin (http or tls) so the stream mimics web traffic")
		} else {
			add("ss/obfs", SeverityInfo, "Shadowsocks wrapped in "+o.Obfs+" obfuscation", "")
		}
	case o.Protocol == engine.ProtocolHysteria2:
		if o.Obfs == "" {
			add("hy2/no-obfs", SeverityMedium,
				"bare Hysteria2 QUIC handshake is identifiable by active probing and heuristics",
				"enable the salamander obfs password or run it behind another layer")
		}
	case o.Protocol == engine.ProtocolTUIC:
		add("tuic/plain", SeverityMedium,
			"TUIC runs a custom UDP protocol with a recognizable handshake",
			"prefer TCP/443-based transports where DPI is aggressive")
	case o.Protocol == engine.ProtocolBypass:
		add("bypass/zapret", SeverityInfo,
			"zapret reshapes direct TLS/HTTP handshakes against DPI; it does not hide VPN protocols themselves",
			"use it for direct traffic alongside a hardened tunnel")
	}
	if o.Transport.Type == "xhttp" && o.TLS.Enabled {
		add("transport/xhttp", SeverityInfo,
			"XHTTP over TLS/443 uploads look like ordinary HTTPS traffic",
			"")
	}
	return fs
}

func gradeWireGuard(o engine.Outbound, add func(string, Severity, string, string)) {
	// Plain WireGuard is trivially fingerprinted: 32-bit message-type
	// headers (1-4) and fixed sizes (handshake init 148 bytes, response
	// 92 bytes). This is the documented reason AmneziaWG exists.
	if o.Amnezia == nil || amneziaZero(o.Amnezia) {
		add("wg/plain", SeverityHigh,
			"plain WireGuard handshake is trivially fingerprinted by DPI (fixed headers 1-4, fixed 148/92-byte packets)",
			"set AmneziaWG obfuscation parameters or chain WireGuard through a Shadowsocks outbound")
		return
	}
	// AmneziaWG 1.x used static header replacements; a patient DPI box
	// learns the new constants just like the original 1-4. Version 2.0
	// uses per-packet random values drawn from ranges instead.
	if staticHeaders(o.Amnezia) {
		add("wg/awg-static-headers", SeverityMedium,
			"AmneziaWG headers are static values, which DPI can learn over time (documented 1.x weakness)",
			"use AmneziaWG 2.0 header ranges so every packet carries a different value")
	}
	if o.Amnezia.Jc == 0 {
		add("wg/awg-no-junk", SeverityLow,
			"no junk packets precede the handshake; the session still opens with a handshake-shaped burst",
			"set Jc/Jmin/Jmax so the handshake is preceded by random-sized noise")
	}
}

// amneziaZero reports whether the parameters leave stock WireGuard
// behaviour: with everything at zero AmneziaWG speaks plain WireGuard.
// The 3.x compatibility sentinels (H1=1..H4=4) also mean "off".
func amneziaZero(a *engine.AmneziaWG) bool {
	hdrs := []string{a.H1, a.H2, a.H3, a.H4}
	for i, h := range hdrs {
		if h != "" && h != strconv.Itoa(i+1) {
			return false
		}
	}
	return a.Jc == 0 && a.Jmin == 0 && a.Jmax == 0 &&
		a.S1 == 0 && a.S2 == 0 && a.S3 == 0 && a.S4 == 0 &&
		a.I1 == "" && a.I2 == "" && a.I3 == "" && a.I4 == "" && a.I5 == "" &&
		a.J1 == "" && a.J2 == "" && a.J3 == "" && a.Itime == 0 &&
		a.HeaderProtectionKey == "" && a.ContentPaddingAddition == "" &&
		!a.RandomTrailers && !a.DisableCookies &&
		a.RekeyAfterTime == "" && a.RekeyTimeout == "" &&
		a.RejectAfterTime == "" && a.KeepaliveTimeout == "" &&
		a.MaxHandshakeAttempts == "" && !a.UsesMasquerade()
}

// staticHeaders reports whether any header is a single constant rather
// than a 2.0-style range ("100000-800000"). With 3.x header protection
// the type word is masked on the wire, so the header values (usually
// the 1-4 compatibility sentinels) stop mattering.
func staticHeaders(a *engine.AmneziaWG) bool {
	if a.HeaderProtectionKey != "" {
		return false
	}
	for i, h := range []string{a.H1, a.H2, a.H3, a.H4} {
		if h == "" || h == strconv.Itoa(i+1) {
			continue
		}
		if !strings.ContainsAny(h, "-,") {
			return true
		}
	}
	return false
}

func gradeTLS(o engine.Outbound, fragment bool, add func(string, Severity, string, string)) {
	fp := engine.NormalizeFingerprint(o.TLS.Fingerprint)
	if fp != "" {
		// An explicitly pinned old Chrome parrot is not "old but
		// working": per the Oct 2026 TSPU field tests, Chrome 133 and
		// older are actively blocked, so this is a likely cause of
		// connection failure, not a cosmetic issue.
		if engine.IsStaleParrot(fp) {
			add("tls/fp-stale", SeverityHigh,
				"uTLS fingerprint "+fp+" pins an outdated Chrome parrot (TSPU blocks Chrome 133 and older)",
				"use the fresh auto parrot (hellochrome_auto for Xray, chrome for sing-box/mihomo) instead of a pinned version")
		}
		// A "modern Chrome" ClientHello without the X25519MLKEM768 key
		// share is a contradiction visible to DPI before any HTTP.
		if !engine.HasPQKeyShare(fp) {
			add("tls/no-pq-keyshare", SeverityMedium,
				"uTLS fingerprint "+fp+" predates the post-quantum key share (Chrome 131+); ~90% of real Chrome traffic has it",
				"use a current Chrome parrot so the ClientHello offers X25519MLKEM768")
		}
		// Detector research (2025-2026) consensus: randomized TLS
		// fingerprints match no real browser population and make the
		// client more detectable, not less. Exact imitation of a
		// current browser beats randomization.
		if engine.IsRandomizedFingerprint(fp) {
			add("tls/fp-randomized", SeverityLow,
				"randomized uTLS fingerprint matches no real browser population (JA4 was designed to resist randomization)",
				"prefer exact imitation of a current browser; keep randomized only as a manual fallback")
		}
	}
	if o.TLS.Reality {
		// REALITY completes a genuine TLS handshake with the decoy site:
		// there is no proxy handshake on the wire at all.
		add("tls/reality", SeverityInfo, "REALITY shows no proxy handshake to DPI", "")
		return
	}
	if !o.TLS.Enabled && (o.Transport.Type == "" || o.Transport.Type == "tcp") {
		add("tls/plaintext", SeverityHigh,
			"protocol runs without TLS; its framing is directly fingerprintable",
			"enable TLS with a browser uTLS fingerprint")
		return
	}
	if !o.TLS.Enabled {
		return
	}
	if o.TLS.Fingerprint == "" {
		add("tls/no-utls", SeverityMedium,
			"TLS ClientHello uses the engine default, which JA3-style fingerprinting distinguishes from browsers",
			"set a current uTLS fingerprint (chrome = newest verified Chrome parrot); never pin an outdated version")
	}
	if !fragment {
		add("tls/no-fragment", SeverityMedium,
			"ClientHello (with SNI) goes out in one TCP segment and is trivially matched",
			"enable TLS fragmentation so the SNI is split across segments")
	}
}
