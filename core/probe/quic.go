package probe

// QUIC reachability probing and residual-ban tracking.
//
// FOCI 2026 measured the TSPU QUIC censor precisely: it decrypts the QUIC
// Initial (RFC 9001 keys are public), extracts the SNI, and on a forbidden
// domain drops the packet plus every later packet of the same 4-tuple for
// ~420 seconds — each new packet resets the timer. If the first packet does
// not trigger, the rest of the connection is residually cleared (not
// inspected). Two consequences for the client:
//
//  1. Retrying a blocked QUIC handshake from the same UDP source port only
//     extends the ban. The BanTracker below remembers banned 4-tuples so
//     the dialer rotates the source port instead of hammering a dead one.
//  2. A blind TCP fallback hurts on some destinations (P04-6: YouTube over
//     TCP is worse than a working QUIC path, and a blocked QUIC path says
//     nothing about TCP quality). ProbeQUIC reports facts; the Advice
//     method tells the caller what they justify, which is never "just use
//     TCP".
//
// The reachability trick: an Initial with a reserved grease version
// (0x0a0a0a0a, RFC 9000 §6) forces any QUIC server to answer with a Version
// Negotiation packet. A VN reply proves the UDP path is open end to end;
// silence toward a host that serves QUIC, while TCP/443 answers, proves
// the censor dropped the Initial.
//
// Engine QUIC stacks (T049, verified 2026-10-20 against the go.mod of the
// engines.lock pins):
//   - sing-box-lx 1.14.3-lx.14: sagernet/quic-go v0.61.0-sing-box-mod.9
//   - Xray-core v26.3.27: apernet/quic-go v0.59.1-0.20260217092621 (fork)
//   - mihomo v1.19.32: metacubex/quic-go v0.61.1-0.20260727080200 (fork)
// Upstream quic-go v0.52.0 (Apr 2025, PR #5107) fragments the TLS
// ClientHello into multiple pieces by default ("complicating Deep Packet
// Inspection"); all three engine bases are newer, so the fragmentation
// reaches sora's QUIC outbounds unless a fork removed it. sora does not
// set QUIC_GO_DISABLE_CLIENTHELLO_SCRAMBLING, so the upstream default
// (on) applies wherever the fork kept it. The pre-Initial random UDP
// datagram exemption (the paper's other technique) is not a library
// behavior: it is an application-level trick, and the engines do not
// perform it. Honest limits: fork wire behavior is NOT verified here —
// the forks could diverge from upstream in the handshake path. Proving
// it needs the T026 pcap harness on a real engine build (QUICv2-canary
// and CRYPTO-reassembly field work, still open), not a go.mod read.
// The residual 420 s was reconfirmed for TSPU specifically by the FOCI
// 2026 Russia measurements: the censor drops the Initial and residually
// bans the 4-tuple for ~420 s; sending uncensored data first on the same
// 4-tuple exempts the flow. Sora deliberately does NOT exploit the
// fail-open (active overload is a legal risk, see T040): the exemption
// is measurement knowledge, not a shipped tactic.

import (
	"context"
	"crypto/rand"
	"encoding/binary"
	"errors"
	"fmt"
	"net"
	"strconv"
	"strings"
	"sync"
	"time"
)

// residualBanTTL is the FOCI-2026 measured residual ban: 420 seconds on
// the 4-tuple after a QUIC SNI drop, self-renewing while packets arrive.
const residualBanTTL = 420 * time.Second

// quicProbeTimeout bounds one reachability attempt.
const quicProbeTimeout = 3 * time.Second

// quicMinInitial is the minimum QUIC Initial datagram size (RFC 9000 §14);
// padding to it keeps the probe shaped like a real handshake.
const quicMinInitial = 1200

// Verdict names what the QUIC probe established about the path.
type Verdict int

const (
	// VerdictUnknown means the probe could not decide (e.g. no permission
	// to send, resolver failure unrelated to the path).
	VerdictUnknown Verdict = iota
	// VerdictOpen means a Version Negotiation arrived: UDP reaches a QUIC
	// server and comes back.
	VerdictOpen
	// VerdictBlocked means UDP/443 is silently dropped while TCP/443 to
	// the same host answers: the QUIC censor signature.
	VerdictBlocked
	// VerdictFiltered means the port actively refused (ICMP unreachable):
	// no QUIC server there, not necessarily censorship.
	VerdictFiltered
	// VerdictDown means neither QUIC nor TCP answered: host or network
	// down, not a QUIC-specific verdict.
	VerdictDown
)

// QUICResult is one reachability verdict with the 4-tuple it was measured
// on, so the caller can feed the ban tracker exactly.
type QUICResult struct {
	Host      string
	Port      int
	Verdict   Verdict
	RTT       time.Duration
	LocalPort int
	Remote    string
}

// Advice renders what the verdict justifies. It never recommends a blind
// TCP fallback: a blocked QUIC path says nothing about TCP quality, and on
// some destinations (YouTube) the fallback is worse than trying QUIC from
// a fresh source port.
func (r *QUICResult) Advice() string {
	switch r.Verdict {
	case VerdictOpen:
		return "QUIC reaches the host: prefer it, no fallback needed."
	case VerdictBlocked:
		return "QUIC is dropped on this path while TCP answers: do not retry QUIC from UDP source port " +
			strconv.Itoa(r.LocalPort) + " for 420s (the ban self-renews); rotate the source port for the next attempt, and measure TCP quality before falling back to it."
	case VerdictFiltered:
		return "the port refused the probe: no QUIC server there, or a firewall answered; not a censorship verdict."
	case VerdictDown:
		return "neither QUIC nor TCP answered: the host or the network is down, not a QUIC-specific problem."
	default:
		return "the probe could not decide; treat as unknown, not as blocked."
	}
}

// ProbeQUIC checks whether a QUIC handshake can reach host:port over UDP.
// It sends one Initial with a grease version and waits for Version
// Negotiation; no real handshake is performed and nothing is retransmitted,
// so a lost probe never extends a residual ban by itself.
//
// NOT WIRED: no RPC or diagnostic path calls ProbeQUIC yet — it is a
// tested primitive waiting for a client trigger (spec
// 31-quic-residual-ban.md). The BanTracker from the same module IS wired
// through DialQUIC into the probe dials.
func ProbeQUIC(ctx context.Context, host string, port int) (*QUICResult, error) {
	return ProbeQUICWithTracker(ctx, host, port, nil)
}

// ProbeQUICWithTracker is ProbeQUIC with a residual-ban tracker (T008/31):
// the dial rotates away from banned source ports instead of hammering a
// dead 4-tuple, and a Blocked verdict records the tuple so the next dial —
// probe or pre-flight — does not extend the ban. A nil tracker behaves
// exactly like ProbeQUIC.
func ProbeQUICWithTracker(ctx context.Context, host string, port int, tracker *BanTracker) (*QUICResult, error) {
	if host == "" {
		return nil, errors.New("probe: quic probe needs a host")
	}
	if port <= 0 || port > 65535 {
		return nil, fmt.Errorf("probe: %d is not a port", port)
	}
	raddr, err := resolveUDP(ctx, host, port)
	if err != nil {
		return nil, err
	}
	conn, err := DialQUIC(ctx, raddr, tracker)
	if err != nil {
		return nil, err
	}
	defer conn.Close()
	laddr, ok := conn.LocalAddr().(*net.UDPAddr)
	if !ok {
		return nil, errors.New("probe: udp socket has no udp address")
	}
	localPort := laddr.Port
	remote := raddr.String()

	pkt, err := greaseInitial()
	if err != nil {
		return nil, err
	}
	deadline := time.Now().Add(quicProbeTimeout)
	if dl, ok := ctx.Deadline(); ok && dl.Before(deadline) {
		deadline = dl
	}
	_ = conn.SetDeadline(deadline)
	start := time.Now()
	if _, err := conn.Write(pkt); err != nil {
		return nil, fmt.Errorf("probe: send initial: %w", err)
	}
	res := &QUICResult{Host: host, Port: port, LocalPort: localPort, Remote: remote}
	buf := make([]byte, 1500)
	for {
		n, err := conn.Read(buf)
		if err != nil {
			if ctx.Err() != nil {
				return nil, ctx.Err()
			}
			if isICMPUnreachable(err) {
				res.Verdict = VerdictFiltered
				return res, nil
			}
			if isTimeout(err) {
				out, cerr := res.withControl(ctx, host, port)
				if cerr == nil && out.Verdict == VerdictBlocked && tracker != nil {
					// Feed the tracker: this 4-tuple just ate a drop, so
					// the next dial must rotate away from it (T008).
					tracker.NoteBlocked(localPort, remote)
				}
				return out, cerr
			}
			res.Verdict = VerdictUnknown
			return res, nil
		}
		if isVersionNegotiation(buf[:n]) {
			res.Verdict = VerdictOpen
			res.RTT = time.Since(start)
			return res, nil
		}
		// Not a VN packet (stray traffic): keep waiting for the real
		// answer until the deadline.
	}
}

// withControl runs the TCP/443 control after UDP silence: TCP answering
// while QUIC stays silent is the censor signature; both silent is a down
// host or network.
func (r *QUICResult) withControl(ctx context.Context, host string, port int) (*QUICResult, error) {
	if ctx.Err() != nil {
		return nil, ctx.Err()
	}
	d := net.Dialer{Timeout: quicProbeTimeout}
	tcpAddr := net.JoinHostPort(host, strconv.Itoa(port))
	c, err := d.DialContext(ctx, "tcp", tcpAddr)
	if err != nil {
		r.Verdict = VerdictDown
		return r, nil
	}
	_ = c.Close()
	r.Verdict = VerdictBlocked
	return r, nil
}

func resolveUDP(ctx context.Context, host string, port int) (*net.UDPAddr, error) {
	r := net.Resolver{}
	addrs, err := r.LookupIP(ctx, "ip", host)
	if err != nil || len(addrs) == 0 {
		return nil, fmt.Errorf("probe: resolve %s: %w", host, err)
	}
	return &net.UDPAddr{IP: addrs[0], Port: port}, nil
}

// greaseInitial builds a minimal QUIC Initial with a reserved version so
// the server must answer Version Negotiation. The packet is well-formed
// (long header, DCID, empty token, padding to 1200 bytes) but carries no
// CRYPTO: it can never complete a handshake, which is the point — the
// probe measures the path, not the server.
func greaseInitial() ([]byte, error) {
	dcid := make([]byte, 8)
	if _, err := rand.Read(dcid); err != nil {
		return nil, fmt.Errorf("probe: random dcid: %w", err)
	}
	// Build the packet at its final size in one allocation: the body is
	// zeros (empty SCID, empty token, packet number 0, PADDING frames),
	// so only the header fields need writing.
	pkt := make([]byte, quicMinInitial)
	pkt[0] = 0xC3 // long header, fixed bit, Initial, 1-byte packet number
	pkt[1], pkt[2], pkt[3], pkt[4] = 0x0A, 0x0A, 0x0A, 0x0A
	pkt[5] = byte(len(dcid))
	copy(pkt[6:], dcid)
	// Length (bytes 16–17) covers the packet number plus the payload;
	// the header through the packet number is 19 bytes.
	length := 1 + (quicMinInitial - 19)
	pkt[16] = 0x40 | byte(length>>8)
	pkt[17] = byte(length)
	return pkt, nil
}

// isVersionNegotiation reports a QUIC Version Negotiation packet: long
// header with the version field zeroed (RFC 9000 §6.1).
func isVersionNegotiation(pkt []byte) bool {
	return len(pkt) >= 6 && pkt[0]&0x80 != 0 && binary.BigEndian.Uint32(pkt[1:5]) == 0
}

// isICMPUnreachable reports the ECONNREFUSED a connected UDP socket gets
// when an ICMP port-unreachable arrives: the far port is closed, not
// silently dropped.
func isICMPUnreachable(err error) bool {
	return strings.Contains(err.Error(), "connection refused")
}

func isTimeout(err error) bool {
	var netErr net.Error
	return errors.As(err, &netErr) && netErr.Timeout()
}

// BanTracker remembers 4-tuples in residual ban so the QUIC dialer rotates
// the UDP source port instead of reusing a banned one. A banned tuple
// self-renews while packets arrive at the censor, so the client must not
// "wait it out" on the same port: rotate, don't retry.
type BanTracker struct {
	mu    sync.Mutex
	until map[string]time.Time
	ttl   time.Duration
	now   func() time.Time
}

// NewBanTracker returns a tracker with the FOCI-measured 420s ban TTL.
func NewBanTracker() *BanTracker {
	return &BanTracker{until: map[string]time.Time{}, ttl: residualBanTTL, now: time.Now}
}

// NoteBlocked records that localPort→remote just ate a QUIC drop.
func (b *BanTracker) NoteBlocked(localPort int, remote string) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.until[banKey(localPort, remote)] = b.now().Add(b.ttl)
}

// Banned reports whether localPort→remote is still inside its residual
// ban. Expired entries are pruned on read.
func (b *BanTracker) Banned(localPort int, remote string) bool {
	key := banKey(localPort, remote)
	b.mu.Lock()
	defer b.mu.Unlock()
	until, ok := b.until[key]
	if !ok {
		return false
	}
	if !b.now().Before(until) {
		delete(b.until, key)
		return false
	}
	return true
}

func banKey(localPort int, remote string) string {
	// Plain concatenation: one allocation, no fmt.Sprintf machinery.
	return strconv.Itoa(localPort) + "->" + remote
}

// quicDialAttempts bounds the source-port rotation loop: a banned port is
// re-rolled, but an environment where every fresh port is banned is a
// signal to report, not a loop to spin in.
const quicDialAttempts = 4

// dialUDPFunc dials a connected UDP socket; it exists so tests can hand
// out sockets on chosen local ports. Production passes net.DialUDP.
type dialUDPFunc func(ctx context.Context, network string, laddr, raddr *net.UDPAddr) (*net.UDPConn, error)

// DialQUIC dials raddr over UDP for a QUIC handshake, rotating the local
// source port when tracker says the 4-tuple is inside its residual ban
// (T008, spec 31-quic-residual-ban.md). Each attempt binds a fresh
// ephemeral port; a banned socket is closed without a single packet
// sent, because a retry from a banned port only renews the ban. Attempts
// back off exponentially (100 ms, 200 ms, 400 ms) for the same reason.
// A nil tracker disables the rotation and dials once.
//
// Scope, honestly: this covers the QUIC dials sora's own code performs
// (reachability probes, pre-flight checks). The QUIC handshakes of the
// Hysteria2/TUIC outbounds happen inside the engine binaries and cannot
// be spliced from here; engines rotate source ports themselves or not at
// all — that gap is tracked in the spec, not hidden.
//
// Not applied, deliberately: the USENIX/FOCI 2026 QUIC-censorship paper
// reports the GFW skips QUIC packets whose source port is below the
// destination port. Binding a low source port is not something a
// userspace dialer can promise — ports below 1024 need privileges on
// most systems, and NAT rewrites the port after it leaves the host —
// so sora does not claim the property. It stays a measurement idea for
// the censor-proxy bench, not a shipped guarantee.
func DialQUIC(ctx context.Context, raddr *net.UDPAddr, tracker *BanTracker) (*net.UDPConn, error) {
	return dialQUIC(ctx, raddr, tracker, func(ctx context.Context, network string, laddr, raddr *net.UDPAddr) (*net.UDPConn, error) {
		var d net.Dialer
		conn, err := d.DialContext(ctx, network, raddr.String())
		if err != nil {
			return nil, err
		}
		udp, ok := conn.(*net.UDPConn)
		if !ok {
			_ = conn.Close()
			return nil, errors.New("probe: udp dial did not return a udp socket")
		}
		return udp, nil
	})
}

func dialQUIC(ctx context.Context, raddr *net.UDPAddr, tracker *BanTracker, dial dialUDPFunc) (*net.UDPConn, error) {
	remote := raddr.String()
	backoff := 100 * time.Millisecond
	for attempt := 0; ; attempt++ {
		conn, err := dial(ctx, "udp", nil, raddr)
		if err != nil {
			return nil, fmt.Errorf("probe: dial udp: %w", err)
		}
		lport := 0
		if la, ok := conn.LocalAddr().(*net.UDPAddr); ok {
			lport = la.Port
		}
		if tracker == nil || lport == 0 || !tracker.Banned(lport, remote) {
			return conn, nil
		}
		_ = conn.Close()
		if attempt+1 >= quicDialAttempts {
			return nil, fmt.Errorf("probe: %d fresh source ports to %s are all in residual ban", quicDialAttempts, remote)
		}
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-time.After(backoff):
		}
		backoff *= 2
	}
}
