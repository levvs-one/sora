package probe

// Trojan active-probe self-test (T022).
//
// A Trojan server without a perfect fallback is confirmed as a proxy by
// 1-2 active probes: unlike a real web server, it cannot answer a plain
// HTTP request. liuylv/trojan-prober defines five probe classes
// (H1-Close, H1-Incomplete, Overbuffer-Incomplete, H1-ALPN-h2,
// Short-ALPN-h2); this file replays them against the user's own server
// and classifies each response as web-like (pass) or proxy-like (fail).
//
// This is a client-side diagnostic for the server operator: it tells
// "your fallback would not survive an active prober" before a censor
// does. It cannot detect passive DPI and it never proves undetectability.

import (
	"bufio"
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"strings"
	"time"
)

// TrojanProbeClass is one active-probe class from trojan-prober.
type TrojanProbeClass int

const (
	// TrojanProbeH1Close sends a complete HTTP/1.1 request and closes the
	// write side. A real server answers with an HTTP response; a bare
	// Trojan server drops the connection.
	TrojanProbeH1Close TrojanProbeClass = iota
	// TrojanProbeH1Incomplete sends a truncated request (no terminating
	// blank line) and waits. A real server waits for the rest (or times
	// out with 408); a proxy-like server closes immediately.
	TrojanProbeH1Incomplete
	// TrojanProbeOverbufferIncomplete floods 64 KiB without CRLF. A real
	// server answers 414/431/400 or keeps waiting; a proxy-like server
	// resets.
	TrojanProbeOverbufferIncomplete
	// TrojanProbeH1ALPNH2 negotiates TLS with ALPN "h2" then speaks
	// HTTP/1.1. The TLS stack must behave like a web server's: complete
	// the handshake and handle (or cleanly reject) the mismatch instead
	// of resetting.
	TrojanProbeH1ALPNH2
	// TrojanProbeShortALPNH2 negotiates TLS with ALPN "h2", sends a
	// truncated request and half-closes. Like H1-Incomplete, but inside
	// TLS: a real server waits; a proxy-like one resets.
	TrojanProbeShortALPNH2
)

// String names the probe class for reports.
func (c TrojanProbeClass) String() string {
	switch c {
	case TrojanProbeH1Close:
		return "h1-close"
	case TrojanProbeH1Incomplete:
		return "h1-incomplete"
	case TrojanProbeOverbufferIncomplete:
		return "overbuffer-incomplete"
	case TrojanProbeH1ALPNH2:
		return "h1-alpn-h2"
	case TrojanProbeShortALPNH2:
		return "short-alpn-h2"
	}
	return "unknown"
}

// TrojanProbeResult is the verdict of one probe class.
type TrojanProbeResult struct {
	Class   TrojanProbeClass
	Pass    bool
	Detail  string // short machine-readable detail, e.g. "http-200", "reset", "timeout", "dial: ..."
	Latency time.Duration
}

// TrojanSelfTestReport aggregates the five probes against one target.
type TrojanSelfTestReport struct {
	Target  string
	Results []TrojanProbeResult
	// OK is true only when every probe passed: the fallback looks like a
	// real web server to all five classes. It never means "undetectable".
	OK      bool
	Summary string
}

// trojanProbeTimeout bounds one probe; the context bounds the whole run.
const trojanProbeTimeout = 8 * time.Second

// httpStatusLine reads one line and reports whether it opens an HTTP
// response.
func httpStatusLine(r *bufio.Reader) (string, bool) {
	line, err := r.ReadString('\n')
	if err != nil {
		return "", false
	}
	line = strings.TrimRight(line, "\r\n")
	if strings.HasPrefix(line, "HTTP/1.0 ") || strings.HasPrefix(line, "HTTP/1.1 ") {
		return line, true
	}
	return line, false
}

// dialTrojanTarget connects with a per-probe timeout; the error text is
// safe to surface (no credentials are involved).
func dialTrojanTarget(ctx context.Context, target string) (net.Conn, error) {
	d := net.Dialer{}
	ctx, cancel := context.WithTimeout(ctx, trojanProbeTimeout)
	defer cancel()
	return d.DialContext(ctx, "tcp", target)
}

func trojanHostOf(target string) string {
	h, _, err := net.SplitHostPort(target)
	if err != nil {
		return target
	}
	return h
}

// probeH1Close: complete request, then read. Pass = HTTP response.
func probeH1Close(ctx context.Context, target string) TrojanProbeResult {
	start := time.Now()
	res := TrojanProbeResult{Class: TrojanProbeH1Close}
	conn, err := dialTrojanTarget(ctx, target)
	if err != nil {
		res.Detail = "dial: " + shortNetErr(err)
		return res
	}
	defer conn.Close()
	host := trojanHostOf(target)
	fmt.Fprintf(conn, "GET / HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", host)
	conn.SetReadDeadline(time.Now().Add(trojanProbeTimeout))
	line, ok := httpStatusLine(bufio.NewReader(conn))
	res.Latency = time.Since(start)
	if ok {
		res.Pass = true
		res.Detail = "http-response: " + firstToken(line)
		return res
	}
	res.Detail = classifyClose(line)
	return res
}

// probeH1Incomplete: truncated request, then wait briefly. Pass = the
// server waits (no data, no close) or answers 408.
func probeH1Incomplete(ctx context.Context, target string) TrojanProbeResult {
	start := time.Now()
	res := TrojanProbeResult{Class: TrojanProbeH1Incomplete}
	conn, err := dialTrojanTarget(ctx, target)
	if err != nil {
		res.Detail = "dial: " + shortNetErr(err)
		return res
	}
	defer conn.Close()
	fmt.Fprintf(conn, "GET / HTTP/1.1\r\nHost: %s\r\n", trojanHostOf(target))
	conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	line, err2 := bufio.NewReader(conn).ReadString('\n')
	res.Latency = time.Since(start)
	if err2 != nil {
		// Timeout with no data = the server is waiting: web-like.
		if ne, ok := err2.(net.Error); ok && ne.Timeout() {
			res.Pass = true
			res.Detail = "waiting"
			return res
		}
		res.Detail = classifyClose("")
		return res
	}
	if status, ok := httpStatusLine(bufio.NewReader(strings.NewReader(line))); ok {
		res.Pass = true
		res.Detail = "http-response: " + firstToken(status)
		return res
	}
	res.Detail = "unexpected: " + firstToken(line)
	return res
}

// probeOverbufferIncomplete: 64 KiB without CRLF. Pass = HTTP error
// (414/431/400) or waiting; fail = reset/close.
func probeOverbufferIncomplete(ctx context.Context, target string) TrojanProbeResult {
	start := time.Now()
	res := TrojanProbeResult{Class: TrojanProbeOverbufferIncomplete}
	conn, err := dialTrojanTarget(ctx, target)
	if err != nil {
		res.Detail = "dial: " + shortNetErr(err)
		return res
	}
	defer conn.Close()
	junk := make([]byte, 64*1024)
	for i := range junk {
		junk[i] = 'A'
	}
	conn.SetWriteDeadline(time.Now().Add(trojanProbeTimeout))
	if _, err := conn.Write(junk); err != nil {
		res.Latency = time.Since(start)
		res.Detail = "write: " + shortNetErr(err)
		return res
	}
	conn.SetReadDeadline(time.Now().Add(2 * time.Second))
	line, err2 := bufio.NewReader(conn).ReadString('\n')
	res.Latency = time.Since(start)
	if err2 != nil {
		if ne, ok := err2.(net.Error); ok && ne.Timeout() {
			res.Pass = true
			res.Detail = "waiting"
			return res
		}
		res.Detail = classifyClose("")
		return res
	}
	if status, ok := httpStatusLine(bufio.NewReader(strings.NewReader(line))); ok {
		res.Pass = true
		res.Detail = "http-response: " + firstToken(status)
		return res
	}
	res.Detail = "unexpected: " + firstToken(line)
	return res
}

// trojanTLS dials TLS with ALPN h2. InsecureSkipVerify is intentional:
// the self-test classifies behavior, not identity; the target is the
// user's own server.
func trojanTLS(ctx context.Context, target string) (*tls.Conn, error) {
	raw, err := dialTrojanTarget(ctx, target)
	if err != nil {
		return nil, err
	}
	cfg := &tls.Config{
		ServerName:         trojanHostOf(target),
		NextProtos:         []string{"h2"},
		InsecureSkipVerify: true,
	}
	tc := tls.Client(raw, cfg)
	tc.SetDeadline(time.Now().Add(trojanProbeTimeout))
	if err := tc.HandshakeContext(ctx); err != nil {
		raw.Close()
		return nil, err
	}
	return tc, nil
}

// probeH1ALPNH2: TLS/ALPN-h2, then a full HTTP/1.1 request. Pass = the
// handshake completes and the server answers HTTP or closes cleanly
// (close_notify); fail = reset/timeout mid-handshake.
func probeH1ALPNH2(ctx context.Context, target string) TrojanProbeResult {
	start := time.Now()
	res := TrojanProbeResult{Class: TrojanProbeH1ALPNH2}
	tc, err := trojanTLS(ctx, target)
	if err != nil {
		res.Detail = "tls: " + shortNetErr(err)
		return res
	}
	defer tc.Close()
	fmt.Fprintf(tc, "GET / HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", trojanHostOf(target))
	tc.SetReadDeadline(time.Now().Add(trojanProbeTimeout))
	line, ok := httpStatusLine(bufio.NewReader(tc))
	res.Latency = time.Since(start)
	if ok {
		res.Pass = true
		res.Detail = "http-response: " + firstToken(line)
		return res
	}
	res.Detail = classifyClose(line)
	return res
}

// probeShortALPNH2: TLS/ALPN-h2, truncated request, then wait. Pass =
// waiting (or an HTTP response); fail = reset/close.
func probeShortALPNH2(ctx context.Context, target string) TrojanProbeResult {
	start := time.Now()
	res := TrojanProbeResult{Class: TrojanProbeShortALPNH2}
	tc, err := trojanTLS(ctx, target)
	if err != nil {
		res.Detail = "tls: " + shortNetErr(err)
		return res
	}
	defer tc.Close()
	fmt.Fprintf(tc, "GET / HT")
	tc.SetReadDeadline(time.Now().Add(2 * time.Second))
	line, err2 := bufio.NewReader(tc).ReadString('\n')
	res.Latency = time.Since(start)
	if err2 != nil {
		if ne, ok := err2.(net.Error); ok && ne.Timeout() {
			res.Pass = true
			res.Detail = "waiting"
			return res
		}
		res.Detail = classifyClose("")
		return res
	}
	if status, ok := httpStatusLine(bufio.NewReader(strings.NewReader(line))); ok {
		res.Pass = true
		res.Detail = "http-response: " + firstToken(status)
		return res
	}
	res.Detail = "unexpected: " + firstToken(line)
	return res
}

// classifyClose maps a dead connection to a short detail.
func classifyClose(line string) string {
	if line == "" {
		return "closed-no-response"
	}
	return "unexpected: " + firstToken(line)
}

// firstToken keeps the detail short and log-safe.
func firstToken(s string) string {
	if i := strings.IndexAny(s, " \t\r\n"); i >= 0 {
		return s[:i]
	}
	if len(s) > 48 {
		return s[:48]
	}
	return s
}

// shortNetErr renders a dial/read error without addresses.
func shortNetErr(err error) string {
	s := err.Error()
	// Strip any address material that slipped into the error text.
	if i := strings.Index(s, ": "); i >= 0 {
		// Keep only the first sentence; addresses usually follow.
		if j := strings.Index(s, " "); j >= 0 && j < i {
			return s[:j]
		}
	}
	return firstToken(s)
}

// ProbeTrojanFallback runs the five trojan-prober classes against target
// ("host:port") and reports whether the server's fallback behaves like a
// real web server. A nil ctx uses Background. The probes are sequential:
// parallel connections from one client look like a scan, not like five
// independent prober sources, and would muddy the classification.
//
// NOT WIRED: no UI or RPC path triggers this yet — it is a tested
// primitive waiting for the trojan self-test checklist (T022).
func ProbeTrojanFallback(ctx context.Context, target string) (*TrojanSelfTestReport, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	if _, _, err := net.SplitHostPort(target); err != nil {
		return nil, fmt.Errorf("probe: invalid target %q: %w", target, err)
	}
	probes := []func(context.Context, string) TrojanProbeResult{
		probeH1Close, probeH1Incomplete, probeOverbufferIncomplete,
		probeH1ALPNH2, probeShortALPNH2,
	}
	rep := &TrojanSelfTestReport{Target: target, OK: true}
	var failed []string
	for _, p := range probes {
		r := p(ctx, target)
		rep.Results = append(rep.Results, r)
		if !r.Pass {
			rep.OK = false
			failed = append(failed, r.Class.String()+":"+r.Detail)
		}
		if ctx.Err() != nil {
			break
		}
	}
	if rep.OK {
		rep.Summary = "fallback behaves like a real web server on all 5 probe classes"
	} else {
		rep.Summary = "proxy-like behavior on: " + strings.Join(failed, ", ")
	}
	return rep, nil
}
