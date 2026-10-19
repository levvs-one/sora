package probe

// Failure-phase classification for dial errors.
//
// A bare "unreachable" tells the user nothing: a dead server, a dropped
// route, and an SNI-triggered reset all look alike at that level. OONI's
// Web Connectivity test resolves the same ambiguity by walking the
// connection stack step by step (DNS lookup, TCP connect, TLS handshake,
// HTTP request) and attributing each failure to its phase. This file is the
// local, offline equivalent for endpoint probes: it locates the failure in
// the stack and names the wire signature, so the client can tell
// "the server is down" from "something on the path is interfering".
//
// It classifies both raw dial errors and errs.Error wrappers: errs.Error
// unwraps to the redacted cause, so classify the RAW dial error, before
// errs.From redacts the operation — the phase signal does not survive
// wrapping. Callers (the prober, the future meter) must classify first and
// wrap second.

import (
	"context"
	"crypto/tls"
	"errors"
	"net"
	"os"
	"strings"
	"syscall"
)

// DialPhase is the connection-stack step a dial failed in.
type DialPhase int

const (
	// PhaseUnknown means the error could not be attributed to a step.
	PhaseUnknown DialPhase = iota
	// PhaseDNS means name resolution failed; the network path was never
	// touched. NXDOMAIN here can indicate DNS spoofing rather than a
	// missing name when the name is known to exist.
	PhaseDNS
	// PhaseTCP means the SYN/connect leg failed.
	PhaseTCP
	// PhaseTLS means TCP connected but the handshake failed. A reset in
	// this phase, right after the ClientHello, is the classic
	// SNI/DPI-interference signature.
	PhaseTLS
)

// String renders the phase for logs and the meter UI.
func (p DialPhase) String() string {
	switch p {
	case PhaseDNS:
		return "dns"
	case PhaseTCP:
		return "tcp"
	case PhaseTLS:
		return "tls"
	default:
		return "unknown"
	}
}

// DialSignature names how the failure looked on the wire.
type DialSignature int

const (
	// SignatureUnknown means the failure carried no recognizable signal.
	SignatureUnknown DialSignature = iota
	// SignatureRefused means the host answered the SYN with RST: the host
	// is alive and the port is closed. This is a dead or misconfigured
	// server, not censorship — a censor drops packets, it does not run a
	// connection-refusing stack.
	SignatureRefused
	// SignatureTimeout means nothing answered before the deadline: a
	// dropped SYN. IP-level blocking, a dead host, and a dead route all
	// look like this; further probes (ICMP, other ports) disambiguate.
	SignatureTimeout
	// SignatureReset means an established or in-progress connection was
	// torn down with RST. After a ClientHello this is the SNI-interference
	// signature; mid-stream it can be DPI throttling.
	SignatureReset
	// SignatureUnreachable means the network itself reported the host or
	// network unreachable: routing, not filtering.
	SignatureUnreachable
	// SignatureNXDomain means the resolver answered that the name does not
	// exist. For a name known to exist this is a DNS-spoof signal.
	SignatureNXDomain
	// SignatureHandshake means the TLS handshake aborted with an alert or
	// a protocol error before certificate verification.
	SignatureHandshake
	// SignatureCert means the peer presented a certificate that failed
	// verification: a hijacked endpoint, a captive portal, or a
	// misconfigured server.
	SignatureCert
)

// String renders the signature for logs and the meter UI.
func (s DialSignature) String() string {
	switch s {
	case SignatureRefused:
		return "refused"
	case SignatureTimeout:
		return "timeout"
	case SignatureReset:
		return "reset"
	case SignatureUnreachable:
		return "unreachable"
	case SignatureNXDomain:
		return "nxdomain"
	case SignatureHandshake:
		return "handshake"
	case SignatureCert:
		return "certificate"
	default:
		return "unknown"
	}
}

// DialFailure is the attributed outcome of one failed dial.
type DialFailure struct {
	Phase     DialPhase
	Signature DialSignature
}

// CensorshipLike reports whether the failure looks like path interference
// rather than a dead endpoint. Resets after connect, handshake aborts, and
// NXDOMAIN for names known to exist are not how servers die. Refusals are
// deliberately excluded: a censor drops packets, it does not answer SYNs
// with RST.
func (f DialFailure) CensorshipLike() bool {
	switch f.Signature {
	case SignatureReset, SignatureHandshake, SignatureNXDomain:
		return true
	default:
		return false
	}
}

// ClassifyDialError attributes a dial error to its connection-stack phase
// and wire signature. tlsAttempted reports whether a TLS handshake was
// attempted after TCP connect: with it set, post-connect failures (reads,
// writes, remote alerts) are attributed to PhaseTLS instead of PhaseTCP,
// because an SNI reset arrives as a TCP read RST inside the handshake.
//
// A nil error returns the zero DialFailure; classify real failures, not
// successes.
func ClassifyDialError(err error, tlsAttempted bool) DialFailure {
	if err == nil {
		return DialFailure{}
	}
	if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, os.ErrDeadlineExceeded) ||
		errors.Is(err, context.Canceled) {
		return DialFailure{Phase: PhaseUnknown, Signature: SignatureTimeout}
	}
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) {
		sig := SignatureUnknown
		switch {
		case dnsErr.IsNotFound:
			sig = SignatureNXDomain
		case dnsErr.IsTimeout:
			sig = SignatureTimeout
		}
		return DialFailure{Phase: PhaseDNS, Signature: sig}
	}
	var certErr *tls.CertificateVerificationError
	if errors.As(err, &certErr) {
		return DialFailure{Phase: PhaseTLS, Signature: SignatureCert}
	}
	var opErr *net.OpError
	if errors.As(err, &opErr) {
		phase := PhaseTCP
		if tlsAttempted && opErr.Op != "dial" {
			// The SYN leg succeeded (a handshake was attempted), so any
			// later failure happened inside the TLS exchange.
			phase = PhaseTLS
		}
		return DialFailure{Phase: phase, Signature: opSignature(opErr)}
	}
	if tlsHandshakeString(err) {
		return DialFailure{Phase: PhaseTLS, Signature: SignatureHandshake}
	}
	return DialFailure{}
}

// opSignature maps the errno (or timeout flag) inside a *net.OpError to the
// wire signature.
func opSignature(opErr *net.OpError) DialSignature {
	inner := opErr.Err
	if ne, ok := inner.(net.Error); ok && ne.Timeout() {
		return SignatureTimeout
	}
	switch {
	case errors.Is(inner, syscall.ECONNREFUSED):
		return SignatureRefused
	case errors.Is(inner, syscall.ECONNRESET):
		return SignatureReset
	case errors.Is(inner, syscall.ETIMEDOUT):
		return SignatureTimeout
	case errors.Is(inner, syscall.EHOSTUNREACH), errors.Is(inner, syscall.ENETUNREACH),
		errors.Is(inner, syscall.EHOSTDOWN), errors.Is(inner, syscall.ENETDOWN):
		return SignatureUnreachable
	default:
		return SignatureUnknown
	}
}

// tlsHandshakeString catches handshake aborts that the TLS stack returns
// as plain errors: "tls: first record does not look like a TLS handshake",
// "remote error: tls: handshake failure", alert texts, and the
// "unexpected message" family. Certificate failures are typed errors and
// are handled above, not here.
func tlsHandshakeString(err error) bool {
	msg := err.Error()
	for _, marker := range []string{"tls:", "handshake", "alert", "unexpected message", "first record"} {
		if strings.Contains(msg, marker) {
			return true
		}
	}
	return false
}
