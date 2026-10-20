package bypass

import (
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// Byte-exact details: split boundaries, fake payload sizes, TTL
// bounds and argv determinism. These pin the small numbers the
// strategies are made of — the ones a reviewer cannot eyeball from
// the strategy names.

// TestMidSNISplitBoundaries walks the SNI-length boundaries: the
// shortest legal hostname, an even/odd midpoint, and the longest
// legal hostname (253 bytes). The cut is marker + 9 + len/2 by
// construction (split.go); each value here is computed by hand.
func TestMidSNISplitBoundaries(t *testing.T) {
	longest := strings.Repeat("a", 63) + "." + strings.Repeat("b", 63) + "." +
		strings.Repeat("c", 63) + "." + strings.Repeat("d", 61) // 253 bytes
	if len(longest) != 253 {
		t.Fatalf("fixture is %d bytes, want 253", len(longest))
	}
	for sni, want := range map[string]string{
		"x":           "sniext+9",   // 9 + 0: cut at the hostname's first byte
		"xy":          "sniext+10",  // 9 + 1
		"example.com": "sniext+14",  // 9 + 5
		longest:       "sniext+135", // 9 + 126
	} {
		got, err := MidSNISplit(sni)
		if err != nil || got != want {
			t.Errorf("MidSNISplit(len=%d) = %q, %v; want %q", len(sni), got, err, want)
		}
	}
	// One byte past the longest legal hostname is refused.
	if _, err := MidSNISplit(longest + "e"); err == nil {
		t.Error("a 254-byte SNI must be refused")
	}
}

// TestSplitPosBoundariesRender pins the boundary positions as argv:
// 0 (before the first byte), 1, an SNI-relative cut, and a position
// past the end of any real ClientHello (zapret clamps at send time;
// the renderer's job is to carry the value byte-exact, not to judge).
func TestSplitPosBoundariesRender(t *testing.T) {
	for _, pos := range []string{"0", "1", "sniext+9", "sniext+135", "-1", "4096"} {
		s := engine.BypassStrategy{SplitPos: []string{pos}}
		o := engine.Outbound{ID: "z", Protocol: engine.ProtocolBypass, Bypass: &s}
		if err := o.Validate(); err != nil {
			t.Fatalf("position %q must validate: %v", pos, err)
		}
		if args := Args(s, 1); !slices.Contains(args, "--split-pos="+pos) {
			t.Errorf("tpws args = %v, want --split-pos=%s byte-exact", args, pos)
		}
		nfq := engine.BypassStrategy{Desync: []string{"split2"}, SplitPos: []string{pos},
			FilterTCP: "443", FilterL7: "tls"}
		if args := NFQWSArgs(nfq, "/zapret"); !slices.Contains(args, "--dpi-desync-split-pos="+pos) {
			t.Errorf("nfqws args = %v, want --dpi-desync-split-pos=%s byte-exact", args, pos)
		}
	}
}

// TestFakePayloadSizes pins the shipped fake payloads the strategies
// name: the QUIC Initial must be exactly the RFC 9000 minimum
// datagram (1200 bytes — a shorter Initial is not a valid QUIC
// Initial and middleboxes know it), and the TLS ClientHello fake the
// default references must exist and be a plausible ClientHello size.
func TestFakePayloadSizes(t *testing.T) {
	fakeDir := filepath.Join("..", "..", "..", "third_party", "zapret", "files", "fake")
	quic, err := os.ReadFile(filepath.Join(fakeDir, defaultQUICFake))
	if err != nil {
		t.Fatalf("the default QUIC fake is not in the vendored tree: %v", err)
	}
	if len(quic) != 1200 {
		t.Fatalf("QUIC Initial fake = %d bytes, want exactly 1200 (RFC 9000 §14 minimum)", len(quic))
	}
	if quic[0]&0x80 == 0 {
		t.Fatal("the QUIC fake's first byte lacks the long-header bit: not an Initial")
	}
	tlsFake, err := os.ReadFile(filepath.Join(fakeDir, "tls_clienthello_www_google_com.bin"))
	if err != nil {
		t.Fatalf("the shipped TLS fake is missing: %v", err)
	}
	// A TLS ClientHello record: type 0x16, version 0x03xx, then a
	// length that must cover the rest of the file.
	if len(tlsFake) < 5 || tlsFake[0] != 0x16 || tlsFake[1] != 0x03 {
		t.Fatalf("the TLS fake does not start with a TLS record header: % x", tlsFake[:5])
	}
	recLen := int(tlsFake[3])<<8 | int(tlsFake[4])
	if recLen+5 != len(tlsFake) {
		t.Fatalf("TLS fake record length = %d, file = %d bytes: a truncated or padded fake", recLen, len(tlsFake))
	}
}

// TestFakeTTLBoundsProperty: for every plausible measured path, the
// calibrated TTL dies strictly before the server (>= 1 hop to spare
// by construction of the delta) and never below the usable minimum —
// the invariant the safety margin exists for, checked over the whole
// range instead of at sample points.
func TestFakeTTLBoundsProperty(t *testing.T) {
	for hops := minFakeTTL + DefaultTTLDelta; hops <= 64; hops++ {
		ttl, ok, err := FakeTTL(hops, DefaultTTLDelta)
		if err != nil || !ok {
			t.Fatalf("hops=%d: ok=%v err=%v", hops, ok, err)
		}
		if ttl < minFakeTTL || ttl >= hops {
			t.Fatalf("hops=%d: ttl=%d outside [%d, %d)", hops, ttl, minFakeTTL, hops)
		}
		if hops-ttl != DefaultTTLDelta {
			t.Fatalf("hops=%d: margin = %d, want the delta %d exactly", hops, hops-ttl, DefaultTTLDelta)
		}
	}
	// Below the window the answer is collapse, never a squeezed TTL.
	for hops := 1; hops < minFakeTTL+DefaultTTLDelta; hops++ {
		if _, ok, err := FakeTTL(hops, DefaultTTLDelta); err != nil || ok {
			t.Fatalf("hops=%d: ok=%v err=%v, want collapse (ok=false)", hops, ok, err)
		}
	}
}

// TestArgvDeterministic: rendering is a pure function of the
// strategy — the same strategy renders byte-identical argv on every
// call, for both binaries and through target resolution. The
// executor keys processes by the joined argv (key()/nfqKey), so a
// nondeterministic render would fork processes for one strategy.
func TestArgvDeterministic(t *testing.T) {
	strategies := []engine.BypassStrategy{
		DefaultStrategy(),
		{SplitPos: []string{"1", "sniext+14"}, Disorder: true, TLSRecord: "sniext+1", HostCase: true},
		{Desync: []string{"fake", "multisplit"}, SplitPos: []string{"2"}, Fooling: "badseq,ts",
			AutoTTL: true, AutoTTLDelta: 2, Repeats: 3, FakeTLS: "tls", FakeQUIC: "quic",
			FilterTCP: "80,443", FilterUDP: "443", FilterL7: "tls,quic"},
		{Desync: []string{"fake"}, SplitPos: []string{MidSNIMarker}, FakeQUIC: "quic",
			AutoTTL: true, AutoTTLDelta: 3, FilterUDP: "443", FilterL7: "quic"},
	}
	for i, s := range strategies {
		wantTPWS, wantNFQ := Args(s, 4242), NFQWSArgs(s, "/zapret")
		wantResolved, ok, err := NFQWSArgsForTarget(s, "/zapret", "example.com", 12)
		if err != nil {
			t.Fatalf("strategy %d: %v", i, err)
		}
		for n := 0; n < 50; n++ {
			if got := Args(s, 4242); !slices.Equal(got, wantTPWS) {
				t.Fatalf("strategy %d: tpws render drifted: %v vs %v", i, got, wantTPWS)
			}
			if got := NFQWSArgs(s, "/zapret"); !slices.Equal(got, wantNFQ) {
				t.Fatalf("strategy %d: nfqws render drifted: %v vs %v", i, got, wantNFQ)
			}
			got, gotOK, _ := NFQWSArgsForTarget(s, "/zapret", "example.com", 12)
			if gotOK != ok || !slices.Equal(got, wantResolved) {
				t.Fatalf("strategy %d: resolved render drifted", i)
			}
		}
	}
}
