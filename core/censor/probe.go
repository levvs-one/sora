package censor

import (
	"context"
	"crypto/tls"
	"errors"
	"io"
	"net"
	"os"
	"strings"
	"syscall"
	"time"
)

// Default timeouts bound the active probe. A diagnosis must never become a
// hang: the whole probe fits inside probeBudget, and each leg has its own
// deadline so one stalled step cannot eat the others' time.
const (
	defaultDialTimeout      = 8 * time.Second
	defaultHandshakeTimeout = 10 * time.Second
	defaultResolveTimeout   = 5 * time.Second
	probeBudget             = 30 * time.Second
	// postConnectWatch bounds the read watching for an immediate
	// post-connect teardown on non-TLS targets. Middlebox resets are
	// immediate; a quietly-held connection is not a signal, so the wait
	// stays short.
	postConnectWatch = time.Second
)

// Prober performs the active measurement behind a verdict: one DNS lookup,
// one TCP connect, and — when the target uses TLS — one TLS handshake, each
// instrumented for stage, timing, byte counts, and who closed the connection.
// It is deliberately narrow. It does not compare resolvers, does not probe
// decoy ports, and does not speak the VPN protocol: the question is what the
// *path* does to the lower layers, and one clean attempt answers it.
type Prober struct {
	// DialTimeout bounds the TCP connect. Zero uses the default.
	DialTimeout time.Duration
	// HandshakeTimeout bounds the TLS handshake. Zero uses the default.
	HandshakeTimeout time.Duration
	// ResolveTimeout bounds DNS. Zero uses the default.
	ResolveTimeout time.Duration
	// Budget is the per-SNI handshake budget the TLS handshake
	// acquires from (T007): an active probe is a core-initiated dial,
	// and a burst of probes against one SNI must not itself trip the
	// freeze. Nil uses DefaultHandshakeBudget, shared across all
	// probers — the censor counts per SNI, not per caller.
	Budget *HandshakeLimiter
}

func (p *Prober) budget() *HandshakeLimiter {
	if p.Budget != nil {
		return p.Budget
	}
	return DefaultHandshakeBudget
}

func (p *Prober) dialTimeout() time.Duration {
	if p.DialTimeout > 0 {
		return p.DialTimeout
	}
	return defaultDialTimeout
}

func (p *Prober) handshakeTimeout() time.Duration {
	if p.HandshakeTimeout > 0 {
		return p.HandshakeTimeout
	}
	return defaultHandshakeTimeout
}

func (p *Prober) resolveTimeout() time.Duration {
	if p.ResolveTimeout > 0 {
		return p.ResolveTimeout
	}
	return defaultResolveTimeout
}

// Probe runs the instrumented attempt against the target and returns it for
// the Detector. It never returns an error: every outcome, including local
// failures, is recorded as events in the Attempt, because a failed probe is
// still a measurement.
func (p *Prober) Probe(ctx context.Context, t Target) Attempt {
	ctx, cancel := context.WithTimeout(ctx, probeBudget)
	defer cancel()
	start := time.Now().UTC()
	a := Attempt{Target: t, StartedAt: start}
	emit := func(stage Stage, what What, detail string) {
		a.Events = append(a.Events, Event{At: time.Now().UTC(), Stage: stage, What: what, Detail: detail})
	}

	rctx, rcancel := context.WithTimeout(ctx, p.resolveTimeout())
	ips, err := net.DefaultResolver.LookupIPAddr(rctx, t.Host)
	rcancel()
	if err != nil {
		emit(StageDNS, WhatError, dnsDetail(err))
		return a
	}
	if len(ips) == 0 {
		emit(StageDNS, WhatError, "no addresses returned")
		return a
	}
	emit(StageDNS, WhatResolved, ips[0].IP.String())

	d := net.Dialer{Timeout: p.dialTimeout()}
	conn, err := d.DialContext(ctx, "tcp", net.JoinHostPort(ips[0].IP.String(), itoa(t.Port)))
	if err != nil {
		emit(StageTCP, classifyConnError(err), connDetail(err))
		return a
	}
	emit(StageTCP, WhatConnected, "")
	tcpConn := conn

	if !t.TLS {
		// The TCP leg alone cannot see a post-connect RST: the connect may
		// succeed and the reset land a moment later. Watch briefly for an
		// immediate teardown — for non-TLS protocols that RST is the whole
		// signature. Do not improvise a handshake the server does not speak.
		if what, detail := peekClose(tcpConn, postConnectWatch); what != WhatUnknown {
			emit(StageTCP, what, detail)
		}
		_ = tcpConn.Close()
		return a
	}

	sni := t.SNI
	if sni == "" {
		sni = t.Host
	}
	// Take a handshake-budget slot for this SNI before the ClientHello
	// goes out. A refused acquisition is recorded as the attempt's TLS
	// outcome — the probe never errors out, and a budget refusal is
	// itself the measurement ("core dials are saturating this SNI").
	release, berr := p.budget().Acquire(ctx, sni)
	if berr != nil {
		emit(StageTLS, WhatError, "handshake budget: "+berr.Error())
		_ = tcpConn.Close()
		return a
	}
	defer release()
	tlsConn := tls.Client(tcpConn, &tls.Config{
		ServerName: sni,
		MinVersion: tls.VersionTLS12,
	})
	emit(StageTLS, WhatSent, "client_hello")
	hctx, hcancel := context.WithTimeout(ctx, p.handshakeTimeout())
	err = tlsConn.HandshakeContext(hctx)
	hcancel()
	// Byte counts are best-effort; the detector only needs "did the server
	// speak at all".
	cs := tlsConn.ConnectionState()
	if err != nil {
		emit(StageTLS, classifyTLSError(err), tlsDetail(err))
		_ = tcpConn.Close()
		return a
	}
	emit(StageTLS, WhatReceived, "handshake_complete:"+tls.VersionName(cs.Version))
	_ = tcpConn.Close()
	return a
}

// peekClose watches a fresh connection briefly for an immediate teardown:
// a RST (RemoteReset) or an orderly FIN (RemoteClose). A server that simply
// holds the connection yields WhatUnknown — holding still is not a signal,
// and the probe must not stall on it.
func peekClose(conn net.Conn, wait time.Duration) (What, string) {
	defer conn.SetReadDeadline(time.Time{})
	_ = conn.SetReadDeadline(time.Now().Add(wait))
	var b [1]byte
	if _, err := conn.Read(b[:]); err == nil {
		return WhatReceived, "server sent data first"
	} else if isReset(err) {
		return WhatRemoteReset, ""
	} else if errors.Is(err, io.EOF) || errors.Is(err, io.ErrUnexpectedEOF) {
		return WhatRemoteClose, ""
	} else if isTimeout(err) {
		return WhatUnknown, ""
	} else {
		return WhatUnknown, ""
	}
}

func isTimeout(err error) bool {
	if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, os.ErrDeadlineExceeded) {
		return true
	}
	var opErr *net.OpError
	return errors.As(err, &opErr) && opErr.Timeout()
}

// classifyConnError maps a dial error to who-closed semantics: a timeout is
// our deadline (silence), a reset is the path's decision, a refusal is the
// server's answer.
func classifyConnError(err error) What {
	var opErr *net.OpError
	if errors.As(err, &opErr) {
		if opErr.Timeout() {
			return WhatLocalTimeout
		}
	}
	if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled) {
		return WhatLocalTimeout
	}
	if isReset(err) {
		return WhatRemoteReset
	}
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) {
		return WhatError
	}
	return WhatError
}

// classifyTLSError maps a handshake error the same way. A TLS alert is the
// far end speaking; a reset mid-handshake is the path interfering.
func classifyTLSError(err error) What {
	if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled) {
		return WhatLocalTimeout
	}
	var opErr *net.OpError
	if errors.As(err, &opErr) && opErr.Timeout() {
		return WhatLocalTimeout
	}
	if isReset(err) {
		return WhatRemoteReset
	}
	if errors.Is(err, io.EOF) || errors.Is(err, io.ErrUnexpectedEOF) {
		return WhatRemoteClose
	}
	var alertErr tls.RecordHeaderError
	if errors.As(err, &alertErr) {
		return WhatTLSAlert
	}
	// crypto/tls surfaces received alerts as plain errors containing
	// "alert"; treat them as the far end's voice, not as noise.
	if strings.Contains(strings.ToLower(err.Error()), "alert") {
		return WhatTLSAlert
	}
	return WhatError
}

func isReset(err error) bool {
	for err != nil {
		if errors.Is(err, syscall.ECONNRESET) || errors.Is(err, syscall.EPIPE) {
			return true
		}
		var opErr *net.OpError
		if errors.As(err, &opErr) {
			err = opErr.Err
			continue
		}
		var sysErr *os.SyscallError
		if errors.As(err, &sysErr) {
			err = sysErr.Err
			continue
		}
		break
	}
	return false
}

func dnsDetail(err error) string {
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) && dnsErr.IsNotFound {
		return "nxdomain"
	}
	return "resolve failed: " + firstLine(err.Error())
}

func connDetail(err error) string {
	s := strings.ToLower(err.Error())
	switch {
	case strings.Contains(s, "refused"):
		return "refused"
	case strings.Contains(s, "unreachable"):
		return "unreachable"
	case strings.Contains(s, "timeout") || strings.Contains(s, "deadline"):
		return "timeout"
	default:
		return "dial failed: " + firstLine(err.Error())
	}
}

func tlsDetail(err error) string {
	s := err.Error()
	low := strings.ToLower(s)
	switch {
	case strings.Contains(low, "certificate"):
		return "certificate: " + firstLine(s)
	case strings.Contains(low, "alert"):
		return "alert: " + firstLine(s)
	case strings.Contains(low, "reset"):
		return "reset during handshake"
	default:
		return "handshake failed: " + firstLine(s)
	}
}

func firstLine(s string) string {
	if i := strings.IndexByte(s, '\n'); i >= 0 {
		s = s[:i]
	}
	s = strings.TrimSpace(s)
	if len(s) > 160 {
		s = s[:160] + "…"
	}
	return s
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	neg := n < 0
	if neg {
		n = -n
	}
	var b [8]byte
	i := len(b)
	for n > 0 {
		i--
		b[i] = byte('0' + n%10)
		n /= 10
	}
	if neg {
		i--
		b[i] = '-'
	}
	return string(b[i:])
}
