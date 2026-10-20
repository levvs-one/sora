package diagnostics

import (
	"context"
	"encoding/binary"
	"errors"
	"fmt"
	"math/rand"
	"net"
	"strings"
	"time"
)

// DNS interception/injection runtime probe (T010, P15-5).
//
// Field method (angry_agent, 08.2026): since 26.08.2026 TSPU DNAT-intercepts
// plain UDP/53 to 8.8.8.8 and 1.1.1.1, redirecting it to NSDI (195.208.5.1),
// which answers censored domains with NXDOMAIN and impersonates Google.
// The impersonation is detectable on the wire:
//
//   - NXDOMAIN with the authoritative (aa) flag: a recursive resolver never
//     answers authoritatively — someone on the path answered instead.
//   - UDP answer diverging from the TCP/53 answer to the same server:
//     on 27.08.2026 the intercept covered UDP only, TCP reached the real
//     Google.
//   - answers carrying known censor markers (188.186.146.208 — OONI,
//     "Russia blocked Bluesky"; 127.0.0.1 / 0.0.0.0) for a name that must
//     resolve: classic injection winning the TXID race.
//
// The probe is one shot and network-dependent; a positive verdict should be
// re-run before the UI escalates it. Everything runs locally; the only
// traffic is two DNS queries to the configured server.

// InterceptVerdict is the outcome of one interception-probe run.
type InterceptVerdict int

const (
	// InterceptOK means the server answered consistently: no sign of a
	// middlebox impersonating it on this probe.
	InterceptOK InterceptVerdict = iota
	// Intercepted means the path impersonates the resolver: NXDOMAIN with
	// the aa flag, or UDP/TCP answers that disagree.
	Intercepted
	// Injected means the answer carried a censor marker address for a name
	// that must resolve: a forged answer won the race.
	Injected
	// InterceptUnresolved means no usable answer arrived at all: the
	// network or the server is down, which is an outage, not a claim.
	InterceptUnresolved
)

// String renders the verdict for logs and the meter UI.
func (v InterceptVerdict) String() string {
	switch v {
	case InterceptOK:
		return "ok"
	case Intercepted:
		return "intercepted"
	case Injected:
		return "injected"
	default:
		return "unresolved"
	}
}

// DNSAnswer is one decoded DNS response.
type DNSAnswer struct {
	IPs           []string
	NXDomain      bool
	Authoritative bool // the aa flag: set only by someone answering as authority
	RTT           time.Duration
}

// InterceptInput configures one interception-probe run.
type InterceptInput struct {
	// Server is the resolver to probe, "ip" or "ip:port". Default 8.8.8.8:
	// the address TSPU is documented to DNAT-intercept.
	Server string
	// Canary is a name that exists globally but is censored in RU.
	// Default youtube.com (removed from NSDI 02.2026): an honest resolver
	// returns addresses, an intercepting one NXDOMAIN.
	Canary string
	// Timeout bounds one query. DoH-style silent blackholes hang forever;
	// P15-2 demands aggressive short budgets. Zero selects the default.
	Timeout time.Duration
	// Query performs one query; network is "udp" or "tcp". Nil selects the
	// stdlib-free wire implementation below. Tests inject failures here.
	Query func(ctx context.Context, network, server, host string) (DNSAnswer, error)
}

// InterceptReport is the probe outcome. Evidence is ordered, most telling
// first; UDP/TCP carry the raw answers when obtained.
type InterceptReport struct {
	Verdict  InterceptVerdict
	Evidence []string
	UDP      *DNSAnswer
	TCP      *DNSAnswer
}

// dnsProbeResult is one transport's answer of the interception probe.
type dnsProbeResult struct {
	ans DNSAnswer
	err error
}

// defaultInterceptServer is the documented DNAT-intercept target.
const defaultInterceptServer = "8.8.8.8"

// defaultInterceptCanary must resolve globally and be censored in RU.
const defaultInterceptCanary = "youtube.com"

// defaultInterceptTimeout bounds one query: blackholed queries must fail
// fast instead of hanging the diagnostics (P15-2).
const defaultInterceptTimeout = 3 * time.Second

// censorMarkers are addresses observed in forged DNS answers in RU
// (OONI "Russia blocked Bluesky" and historical registry blocks).
var censorMarkers = map[string]bool{
	"188.186.146.208": true,
	"127.0.0.1":       true,
	"0.0.0.0":         true,
	"::":              true,
}

// DetectDNSIntercept probes whether the path to server impersonates the
// resolver or injects forged answers. UDP and TCP queries race with short
// budgets; the verdict is derived from their agreement, flags and content.
//
// NOT WIRED: no RPC or diagnostic flow calls this yet — it is a tested
// probe primitive waiting for a client trigger (T010).
func DetectDNSIntercept(ctx context.Context, in InterceptInput) InterceptReport {
	server := in.Server
	if server == "" {
		server = defaultInterceptServer
	}
	canary := in.Canary
	if canary == "" {
		canary = defaultInterceptCanary
	}
	timeout := in.Timeout
	if timeout <= 0 {
		timeout = defaultInterceptTimeout
	}
	query := in.Query
	if query == nil {
		query = queryDNSWire
	}

	udpCh := make(chan dnsProbeResult, 1)
	tcpCh := make(chan dnsProbeResult, 1)
	go func() {
		qctx, cancel := context.WithTimeout(ctx, timeout)
		defer cancel()
		start := time.Now()
		ans, err := query(qctx, "udp", server, canary)
		ans.RTT = time.Since(start)
		udpCh <- dnsProbeResult{ans, err}
	}()
	go func() {
		qctx, cancel := context.WithTimeout(ctx, timeout)
		defer cancel()
		start := time.Now()
		ans, err := query(qctx, "tcp", server, canary)
		ans.RTT = time.Since(start)
		tcpCh <- dnsProbeResult{ans, err}
	}()

	rep := InterceptReport{}
	udp, udpErr := awaitResult(ctx, udpCh)
	tcp, tcpErr := awaitResult(ctx, tcpCh)
	if udpErr == nil {
		rep.UDP = &udp
	}
	if tcpErr == nil {
		rep.TCP = &tcp
	}
	if udpErr != nil && tcpErr != nil {
		rep.Verdict = InterceptUnresolved
		rep.Evidence = []string{
			"no answer from " + server + " over udp or tcp: the network or the server is down, not a proven intercept",
		}
		return rep
	}

	// Injection markers win over everything: a forged answer is the
	// strongest signal and it is visible on either transport.
	for _, a := range []*DNSAnswer{rep.UDP, rep.TCP} {
		if a == nil {
			continue
		}
		for _, ip := range a.IPs {
			if censorMarkers[ip] {
				rep.Verdict = Injected
				rep.Evidence = []string{
					"the answer for " + canary + " carries the censor marker " + ip,
				}
				return rep
			}
		}
	}

	// NXDOMAIN with the aa flag: a recursive resolver never claims
	// authority. Someone on the path answered in its name (P15-5).
	for _, a := range []*DNSAnswer{rep.UDP, rep.TCP} {
		if a != nil && a.NXDomain && a.Authoritative {
			rep.Verdict = Intercepted
			rep.Evidence = []string{
				"NXDOMAIN for " + canary + " arrived with the authoritative flag: a recursive resolver never answers authoritatively, the path impersonates " + server,
			}
			return rep
		}
	}

	// UDP/TCP divergence: the documented intercept covered UDP only, so a
	// TCP answer disagreeing with UDP exposes the middlebox.
	if rep.UDP != nil && rep.TCP != nil && answersDiverge(*rep.UDP, *rep.TCP) {
		rep.Verdict = Intercepted
		rep.Evidence = []string{
			"udp and tcp answers from " + server + " disagree for " + canary + ": udp=" + describeAnswer(*rep.UDP) + " tcp=" + describeAnswer(*rep.TCP),
		}
		return rep
	}
	// UDP silent while TCP answers: the weaker form of the same split.
	// UDP loss happens, so this stays evidence-graded, not a hard claim —
	// but on a single probe it is exactly the documented intercept shape.
	if rep.UDP == nil && rep.TCP != nil {
		rep.Verdict = Intercepted
		rep.Evidence = []string{
			"udp to " + server + " timed out while tcp answered for " + canary + ": matches the documented udp-only intercept; re-run to rule out packet loss",
		}
		return rep
	}

	rep.Verdict = InterceptOK
	rep.Evidence = []string{
		server + " answered consistently for " + canary + " on this probe",
	}
	return rep
}

func awaitResult(ctx context.Context, ch <-chan dnsProbeResult) (DNSAnswer, error) {
	select {
	case r := <-ch:
		return r.ans, r.err
	case <-ctx.Done():
		return DNSAnswer{}, ctx.Err()
	}
}

// answersDiverge reports whether two answers to the same question cannot
// both be honest: one NXDOMAIN while the other resolves, or disjoint
// address sets.
func answersDiverge(a, b DNSAnswer) bool {
	if a.NXDomain != b.NXDomain {
		return true
	}
	if a.NXDomain {
		return false
	}
	set := make(map[string]bool, len(a.IPs))
	for _, ip := range a.IPs {
		set[ip] = true
	}
	for _, ip := range b.IPs {
		if set[ip] {
			return false
		}
	}
	return len(a.IPs) > 0 || len(b.IPs) > 0
}

func describeAnswer(a DNSAnswer) string {
	if a.NXDomain {
		if a.Authoritative {
			return "NXDOMAIN(aa)"
		}
		return "NXDOMAIN"
	}
	if len(a.IPs) == 0 {
		return "noerror-empty"
	}
	return strings.Join(a.IPs, ",")
}

// queryDNSWire performs one plain DNS A-query using only the standard
// library: hand-rolled wire format, no external DNS dependency.
func queryDNSWire(ctx context.Context, network, server, host string) (DNSAnswer, error) {
	addr := server
	if _, _, err := net.SplitHostPort(addr); err != nil {
		addr = net.JoinHostPort(strings.Trim(addr, "[]"), "53")
	}
	dialer := &net.Dialer{}
	conn, err := dialer.DialContext(ctx, network, addr)
	if err != nil {
		return DNSAnswer{}, err
	}
	defer conn.Close()
	if deadline, ok := ctx.Deadline(); ok {
		_ = conn.SetDeadline(deadline)
	}
	msg := encodeDNSQuery(host)
	if network == "tcp" {
		var prefix [2]byte
		binary.BigEndian.PutUint16(prefix[:], uint16(len(msg)))
		msg = append(prefix[:], msg...)
	}
	if _, err := conn.Write(msg); err != nil {
		return DNSAnswer{}, err
	}
	buf := make([]byte, 4096)
	n, err := conn.Read(buf)
	if err != nil {
		return DNSAnswer{}, err
	}
	raw := buf[:n]
	if network == "tcp" {
		if n < 2 {
			return DNSAnswer{}, errors.New("diagnostics: truncated tcp dns response")
		}
		raw = raw[2:]
	}
	return decodeDNSAnswer(raw)
}

// encodeDNSQuery builds a minimal recursive A-query.
func encodeDNSQuery(host string) []byte {
	id := uint16(rand.Intn(1 << 16)) //nolint:gosec // TXID needs unpredictability, not crypto strength
	msg := []byte{byte(id >> 8), byte(id), 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	for _, label := range strings.Split(strings.TrimSuffix(host, "."), ".") {
		msg = append(msg, byte(len(label)))
		msg = append(msg, label...)
	}
	msg = append(msg, 0x00, 0x00, 0x01, 0x00, 0x01) // QTYPE=A, QCLASS=IN
	return msg
}

// decodeDNSAnswer parses flags, RCODE and A/AAAA records. It is deliberately
// narrow: anything it cannot parse is an error, never a silent verdict.
func decodeDNSAnswer(raw []byte) (DNSAnswer, error) {
	var ans DNSAnswer
	if len(raw) < 12 {
		return ans, errors.New("diagnostics: dns response too short")
	}
	flags := binary.BigEndian.Uint16(raw[2:4])
	ans.Authoritative = flags&0x0400 != 0
	rcode := flags & 0x000f
	qdcount := int(binary.BigEndian.Uint16(raw[4:6]))
	ancount := int(binary.BigEndian.Uint16(raw[6:8]))
	if rcode == 3 {
		ans.NXDomain = true
		return ans, nil
	}
	if rcode != 0 {
		return ans, fmt.Errorf("diagnostics: dns rcode %d", rcode)
	}
	off := 12
	for i := 0; i < qdcount; i++ {
		var err error
		off, err = skipName(raw, off)
		if err != nil {
			return ans, err
		}
		off += 4 // QTYPE + QCLASS
	}
	for i := 0; i < ancount; i++ {
		var err error
		off, err = skipName(raw, off)
		if err != nil {
			return ans, err
		}
		if off+10 > len(raw) {
			return ans, errors.New("diagnostics: truncated dns rr header")
		}
		typ := binary.BigEndian.Uint16(raw[off : off+2])
		rdlen := int(binary.BigEndian.Uint16(raw[off+8 : off+10]))
		off += 10
		if off+rdlen > len(raw) {
			return ans, errors.New("diagnostics: truncated dns rdata")
		}
		rdata := raw[off : off+rdlen]
		off += rdlen
		switch {
		case typ == 1 && rdlen == 4:
			ans.IPs = append(ans.IPs, net.IP(rdata).String())
		case typ == 28 && rdlen == 16:
			ans.IPs = append(ans.IPs, net.IP(rdata).String())
		}
	}
	return ans, nil
}

// skipName advances past a possibly compressed domain name.
func skipName(raw []byte, off int) (int, error) {
	for {
		if off >= len(raw) {
			return 0, errors.New("diagnostics: truncated dns name")
		}
		b := raw[off]
		switch {
		case b&0xc0 == 0xc0:
			if off+1 >= len(raw) {
				return 0, errors.New("diagnostics: truncated dns pointer")
			}
			return off + 2, nil
		case b == 0:
			return off + 1, nil
		default:
			off += 1 + int(b)
		}
	}
}
