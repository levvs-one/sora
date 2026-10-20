package probe

import (
	"context"
	"fmt"
	"net"
	"strings"
	"testing"
	"time"
)

func TestGreaseInitialShape(t *testing.T) {
	pkt, err := greaseInitial()
	if err != nil {
		t.Fatalf("greaseInitial: %v", err)
	}
	if len(pkt) != quicMinInitial {
		t.Fatalf("len = %d, want %d", len(pkt), quicMinInitial)
	}
	if pkt[0] != 0xC3 {
		t.Fatalf("first byte = %#x, want long-header Initial", pkt[0])
	}
	if string(pkt[1:5]) != "\x0a\x0a\x0a\x0a" {
		t.Fatal("version is not the grease version")
	}
	if isVersionNegotiation(pkt) {
		t.Fatal("our own Initial must not parse as Version Negotiation")
	}
	// Two probes must not reuse the connection ID: a static DCID would
	// let the censor key on it.
	pkt2, _ := greaseInitial()
	if string(pkt[6:14]) == string(pkt2[6:14]) {
		t.Fatal("DCID reused across probes")
	}
}

func TestIsVersionNegotiation(t *testing.T) {
	vn := []byte{0x80 | 0x40, 0, 0, 0, 0, 8, 1, 2, 3, 4, 5, 6, 7, 8, 0x01, 0x02}
	if !isVersionNegotiation(vn) {
		t.Fatal("version-zero long header not recognized")
	}
	pkt, _ := greaseInitial()
	if isVersionNegotiation(pkt) {
		t.Fatal("Initial recognized as VN")
	}
	if isVersionNegotiation([]byte{0x80}) {
		t.Fatal("short packet recognized as VN")
	}
	if isVersionNegotiation([]byte{0x43, 0, 0, 0, 0, 0}) {
		t.Fatal("short header recognized as VN")
	}
}

func TestProbeQUICBadInput(t *testing.T) {
	ctx := context.Background()
	for name, tc := range map[string]struct {
		host string
		port int
	}{
		"empty host": {host: "", port: 443},
		"bad port":   {host: "example.com", port: 99999},
		"zero port":  {host: "example.com", port: 0},
	} {
		if _, err := ProbeQUIC(ctx, tc.host, tc.port); err == nil {
			t.Errorf("%s: expected an error", name)
		}
	}
	// Unresolvable names must fail fast, not hang the probe. An overlong
	// name fails in the local resolver without any network round-trip,
	// so the test holds even behind a hijacking DNS.
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	tooLong := strings.Repeat("a", 300) + ".invalid"
	if _, err := ProbeQUIC(ctx, tooLong, 443); err == nil {
		t.Error("unresolvable host: expected an error")
	}
}

func TestProbeQUICContextCancel(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	// 198.51.100.1 is TEST-NET-2: unroutable, so without cancellation the
	// probe would burn the full timeout; cancellation must win.
	if _, err := ProbeQUIC(ctx, "198.51.100.1", 443); err == nil {
		t.Fatal("canceled context: expected an error")
	} else if !strings.Contains(err.Error(), "canceled") && !strings.Contains(err.Error(), "cancel") {
		t.Fatalf("canceled context: got %v, want a cancellation", err)
	}
}

func TestBanTracker(t *testing.T) {
	b := NewBanTracker()
	if b.Banned(45678, "203.0.113.7:443") {
		t.Fatal("fresh tracker reports a ban")
	}
	b.NoteBlocked(45678, "203.0.113.7:443")
	if !b.Banned(45678, "203.0.113.7:443") {
		t.Fatal("ban not recorded")
	}
	if b.Banned(45679, "203.0.113.7:443") {
		t.Fatal("ban leaked to another source port")
	}
	if b.Banned(45678, "203.0.113.8:443") {
		t.Fatal("ban leaked to another remote")
	}
}

func TestBanTrackerExpiry(t *testing.T) {
	b := &BanTracker{until: map[string]time.Time{}, ttl: 50 * time.Millisecond, now: time.Now}
	b.NoteBlocked(45678, "203.0.113.7:443")
	if !b.Banned(45678, "203.0.113.7:443") {
		t.Fatal("ban not recorded")
	}
	time.Sleep(80 * time.Millisecond)
	if b.Banned(45678, "203.0.113.7:443") {
		t.Fatal("expired ban still reported")
	}
}

// TestBanTrackerNoteBlockedPrunesExpired pins the pruning
// NoteBlocked performs on write (CENSOR-P3): expired entries are
// removed at the only writer, so a long-lived tracker fed by many
// remotes cannot grow without bound. 500 expired entries plus one
// fresh write must leave exactly the fresh entry.
func TestBanTrackerNoteBlockedPrunesExpired(t *testing.T) {
	base := time.Now()
	clock := base
	b := NewBanTracker()
	b.now = func() time.Time { return clock }
	for i := 0; i < 500; i++ {
		b.NoteBlocked(20000+i, "203.0.113.7:443")
	}
	if len(b.until) != 500 {
		t.Fatalf("tracker holds %d entries after 500 writes, want 500", len(b.until))
	}
	clock = base.Add(residualBanTTL + time.Second)
	b.NoteBlocked(40000, "198.51.100.9:443")
	if len(b.until) != 1 {
		t.Fatalf("tracker holds %d entries after pruning write, want 1 (only the fresh entry)", len(b.until))
	}
	if !b.Banned(40000, "198.51.100.9:443") {
		t.Fatal("fresh entry must survive the pruning write")
	}
	if b.Banned(20000, "203.0.113.7:443") {
		t.Fatal("expired entry must be pruned by the write, not linger")
	}
}

func TestAdviceNeverRecommendsBlindFallback(t *testing.T) {
	r := &QUICResult{Verdict: VerdictBlocked, LocalPort: 45678}
	advice := r.Advice()
	if !strings.Contains(advice, "420") {
		t.Fatalf("blocked advice %q does not name the residual ban window", advice)
	}
	if !strings.Contains(advice, "measure") {
		t.Fatalf("blocked advice %q must demand measurement before TCP fallback", advice)
	}
	if strings.Contains(strings.ToLower(advice), "switch to tcp") ||
		strings.Contains(strings.ToLower(advice), "use tcp instead") {
		t.Fatalf("blocked advice %q recommends a blind fallback", advice)
	}
}

// grabPort binds and releases a localhost UDP port so the test owns it for
// a moment; the fake dial below rebinds it deterministically.
func grabPort(t *testing.T) int {
	t.Helper()
	c, err := net.ListenUDP("udp", &net.UDPAddr{IP: net.ParseIP("127.0.0.1")})
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	p := c.LocalAddr().(*net.UDPAddr).Port
	_ = c.Close()
	return p
}

// TestDialQUICRotatesBannedPort: the first fresh port is banned, so dialQUIC
// must close it unsent and return a socket on the next port.
func TestDialQUICRotatesBannedPort(t *testing.T) {
	ctx := context.Background()
	p1, p2 := grabPort(t), grabPort(t)
	remote := "127.0.0.1:9999"
	raddr, _ := net.ResolveUDPAddr("udp", remote)
	tracker := NewBanTracker()
	tracker.NoteBlocked(p1, remote)

	queue := []int{p1, p2}
	fake := func(ctx context.Context, network string, laddr, raddr *net.UDPAddr) (*net.UDPConn, error) {
		if len(queue) == 0 {
			return nil, fmt.Errorf("fake dial ran dry")
		}
		p := queue[0]
		queue = queue[1:]
		return net.ListenUDP("udp", &net.UDPAddr{IP: net.ParseIP("127.0.0.1"), Port: p})
	}

	conn, err := dialQUIC(ctx, raddr, tracker, fake)
	if err != nil {
		t.Fatalf("dialQUIC: %v", err)
	}
	defer conn.Close()
	if got := conn.LocalAddr().(*net.UDPAddr).Port; got != p2 {
		t.Fatalf("dialQUIC returned port %d, want the unbanned %d", got, p2)
	}
	// The banned socket must have been closed without use: the port is
	// re-bindable immediately.
	if c, err := net.ListenUDP("udp", &net.UDPAddr{IP: net.ParseIP("127.0.0.1"), Port: p1}); err != nil {
		t.Fatalf("banned socket was not closed: %v", err)
	} else {
		_ = c.Close()
	}
}

// TestDialQUICExhaustion: every fresh port is banned — dialQUIC reports
// instead of spinning.
func TestDialQUICExhaustion(t *testing.T) {
	ctx := context.Background()
	remote := "127.0.0.1:9999"
	raddr, _ := net.ResolveUDPAddr("udp", remote)
	tracker := NewBanTracker()
	var ports []int
	for i := 0; i < quicDialAttempts; i++ {
		p := grabPort(t)
		ports = append(ports, p)
		tracker.NoteBlocked(p, remote)
	}
	fake := func(ctx context.Context, network string, laddr, raddr *net.UDPAddr) (*net.UDPConn, error) {
		p := ports[0]
		ports = ports[1:]
		return net.ListenUDP("udp", &net.UDPAddr{IP: net.ParseIP("127.0.0.1"), Port: p})
	}
	if _, err := dialQUIC(ctx, raddr, tracker, fake); err == nil {
		t.Fatalf("dialQUIC = nil, want exhaustion error")
	} else if !strings.Contains(err.Error(), "residual ban") {
		t.Fatalf("dialQUIC error %q does not name the residual ban", err)
	}
}

// TestDialQUICNilTracker dials once with no rotation bookkeeping.
func TestDialQUICNilTracker(t *testing.T) {
	ctx := context.Background()
	raddr, _ := net.ResolveUDPAddr("udp", "127.0.0.1:9999")
	var calls int
	fake := func(ctx context.Context, network string, laddr, raddr *net.UDPAddr) (*net.UDPConn, error) {
		calls++
		return net.ListenUDP("udp", &net.UDPAddr{IP: net.ParseIP("127.0.0.1")})
	}
	conn, err := dialQUIC(ctx, raddr, nil, fake)
	if err != nil {
		t.Fatalf("dialQUIC: %v", err)
	}
	_ = conn.Close()
	if calls != 1 {
		t.Fatalf("dialQUIC dialed %d times with nil tracker, want 1", calls)
	}
}

// TestDialQUICContextCancel: a cancelled context during backoff stops the
// rotation instead of sleeping through it.
func TestDialQUICContextCancel(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	remote := "127.0.0.1:9999"
	raddr, _ := net.ResolveUDPAddr("udp", remote)
	tracker := NewBanTracker()
	fake := func(ctx context.Context, network string, laddr, raddr *net.UDPAddr) (*net.UDPConn, error) {
		c, err := net.ListenUDP("udp", &net.UDPAddr{IP: net.ParseIP("127.0.0.1")})
		if err != nil {
			return nil, err
		}
		// Ban whatever port came out so the loop wants to back off.
		tracker.NoteBlocked(c.LocalAddr().(*net.UDPAddr).Port, remote)
		return c, nil
	}
	cancel()
	if _, err := dialQUIC(ctx, raddr, tracker, fake); !strings.Contains(err.Error(), "canceled") && err != context.Canceled {
		t.Fatalf("dialQUIC = %v, want context cancellation", err)
	}
}
