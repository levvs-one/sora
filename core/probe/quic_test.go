package probe

import (
	"context"
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
