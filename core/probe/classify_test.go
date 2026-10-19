package probe_test

import (
	"context"
	"crypto/tls"
	"errors"
	"net"
	"os"
	"syscall"
	"testing"

	"github.com/levvs-one/sora-client/core/probe"
)

// opError builds the *net.OpError shape the dialer returns: Op names the
// leg, Err carries the errno.
func opError(op string, inner error) error {
	return &net.OpError{Op: op, Net: "tcp", Err: inner}
}

func TestClassifyDialError(t *testing.T) {
	certVerify := &tls.CertificateVerificationError{Err: errors.New("unknown authority")}
	dnsNotFound := &net.DNSError{Err: "no such host", Name: "example.invalid", IsNotFound: true}
	dnsTimeout := &net.DNSError{Err: "server misbehaving", IsTimeout: true}

	tests := []struct {
		name         string
		err          error
		tlsAttempted bool
		phase        probe.DialPhase
		signature    probe.DialSignature
	}{
		{"nil", nil, false, probe.PhaseUnknown, probe.SignatureUnknown},
		{"refused on dial", opError("dial", syscall.ECONNREFUSED), false, probe.PhaseTCP, probe.SignatureRefused},
		{"timeout on dial", opError("dial", syscall.ETIMEDOUT), false, probe.PhaseTCP, probe.SignatureTimeout},
		{"reset on dial", opError("dial", syscall.ECONNRESET), false, probe.PhaseTCP, probe.SignatureReset},
		{"host unreachable", opError("dial", syscall.EHOSTUNREACH), false, probe.PhaseTCP, probe.SignatureUnreachable},
		{"net unreachable", opError("dial", syscall.ENETUNREACH), false, probe.PhaseTCP, probe.SignatureUnreachable},
		// A read RST inside a TLS handshake is the SNI-interference
		// signature, not a TCP problem.
		{"reset during handshake", opError("read", syscall.ECONNRESET), true, probe.PhaseTLS, probe.SignatureReset},
		{"read rst without tls", opError("read", syscall.ECONNRESET), false, probe.PhaseTCP, probe.SignatureReset},
		{"dns nxdomain", dnsNotFound, false, probe.PhaseDNS, probe.SignatureNXDomain},
		{"dns timeout", dnsTimeout, false, probe.PhaseDNS, probe.SignatureTimeout},
		{"cert failure", certVerify, true, probe.PhaseTLS, probe.SignatureCert},
		{"tls alert string", errors.New("remote error: tls: handshake failure"), true, probe.PhaseTLS, probe.SignatureHandshake},
		{"not a tls handshake", errors.New("tls: first record does not look like a TLS handshake"), true, probe.PhaseTLS, probe.SignatureHandshake},
		{"context deadline", context.DeadlineExceeded, false, probe.PhaseUnknown, probe.SignatureTimeout},
		{"os deadline", os.ErrDeadlineExceeded, false, probe.PhaseUnknown, probe.SignatureTimeout},
		{"unrecognized", errors.New("some odd failure"), false, probe.PhaseUnknown, probe.SignatureUnknown},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := probe.ClassifyDialError(tc.err, tc.tlsAttempted)
			if got.Phase != tc.phase || got.Signature != tc.signature {
				t.Errorf("ClassifyDialError(%v, tls=%v) = %s/%s, want %s/%s",
					tc.err, tc.tlsAttempted, got.Phase, got.Signature, tc.phase, tc.signature)
			}
			// NOTE: errs.From-wrapped errors intentionally do NOT
			// classify the same: wrapping redacts the operation, so the
			// phase signal is lost. Classify raw dial errors.
		})
	}
}

func TestDialFailureCensorshipLike(t *testing.T) {
	like := []probe.DialSignature{probe.SignatureReset, probe.SignatureHandshake, probe.SignatureNXDomain}
	for _, sig := range like {
		if !(probe.DialFailure{Phase: probe.PhaseTLS, Signature: sig}).CensorshipLike() {
			t.Errorf("signature %s should read as censorship-like", sig)
		}
	}
	notLike := []probe.DialSignature{
		probe.SignatureRefused, probe.SignatureTimeout,
		probe.SignatureUnreachable, probe.SignatureCert, probe.SignatureUnknown,
	}
	for _, sig := range notLike {
		if (probe.DialFailure{Phase: probe.PhaseTCP, Signature: sig}).CensorshipLike() {
			t.Errorf("signature %s should not read as censorship-like", sig)
		}
	}
}

func TestDialPhaseAndSignatureStrings(t *testing.T) {
	if probe.PhaseDNS.String() != "dns" || probe.PhaseTCP.String() != "tcp" ||
		probe.PhaseTLS.String() != "tls" || probe.PhaseUnknown.String() != "unknown" {
		t.Error("phase strings changed")
	}
	if probe.SignatureRefused.String() != "refused" || probe.SignatureReset.String() != "reset" ||
		probe.SignatureNXDomain.String() != "nxdomain" || probe.SignatureCert.String() != "certificate" {
		t.Error("signature strings changed")
	}
}
