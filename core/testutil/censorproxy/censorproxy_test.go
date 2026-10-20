package censorproxy

import (
	"bytes"
	"crypto/rand"
	"encoding/binary"
	"net"
	"strings"
	"testing"
	"time"
)

// testClientHelloRecord builds a minimal TLS-record ClientHello carrying the
// given SNI and an X25519MLKEM768 key share, for detector tests. When
// includeSNI is false the server_name extension is omitted entirely.
func testClientHelloRecord(t *testing.T, sni string, includeSNI bool, includePQ bool) []byte {
	t.Helper()
	var body []byte
	body = append(body, 0x03, 0x03) // legacy_version TLS 1.2
	rb := make([]byte, 32)
	if _, err := rand.Read(rb); err != nil {
		t.Fatal(err)
	}
	body = append(body, rb...)
	body = append(body, 0x00)                   // session_id len
	body = append(body, 0x00, 0x02, 0x13, 0x01) // cipher_suites: TLS_AES_128_GCM_SHA256
	body = append(body, 0x01, 0x00)             // compression_methods

	var exts []byte
	if includeSNI {
		// server_name extension (0)
		name := []byte(sni)
		var snList []byte
		snList = append(snList, 0x00)
		snList = append(snList, byte(len(name)>>8), byte(len(name)))
		snList = append(snList, name...)
		var sniBody []byte
		sniBody = append(sniBody, byte(len(snList)>>8), byte(len(snList)))
		sniBody = append(sniBody, snList...)
		exts = append(exts, 0x00, 0x00, byte(len(sniBody)>>8), byte(len(sniBody)))
		exts = append(exts, sniBody...)
	}
	// key_share extension (51) with X25519MLKEM768 group
	if includePQ {
		ksEntry := []byte{0x11, 0xec, 0x00, 0x20}
		ksEntry = append(ksEntry, bytes.Repeat([]byte{0xAA}, 32)...)
		var ksBody []byte
		ksBody = append(ksBody, byte(len(ksEntry)>>8), byte(len(ksEntry)))
		ksBody = append(ksBody, ksEntry...)
		exts = append(exts, 0x00, 0x33, byte(len(ksBody)>>8), byte(len(ksBody)))
		exts = append(exts, ksBody...)
	}

	body = append(body, byte(len(exts)>>8), byte(len(exts)))
	body = append(body, exts...)

	hs := []byte{0x01, byte(len(body) >> 16), byte(len(body) >> 8), byte(len(body))}
	hs = append(hs, body...)
	rec := []byte{0x16, 0x03, 0x01, byte(len(hs) >> 8), byte(len(hs))}
	rec = append(rec, hs...)
	return rec
}

// mkFlow builds a flow of n packets; payloadFn(i, dir) returns the payload.
func mkFlow(n int, payloadFn func(i int, dir Direction) []byte, gap time.Duration) *Flow {
	f := &Flow{}
	for i := 0; i < n; i++ {
		dir := Outbound
		if i%2 == 1 {
			dir = Inbound
		}
		p := payloadFn(i, dir)
		f.Packets = append(f.Packets, Packet{
			Dir:     dir,
			Size:    len(p),
			At:      time.Duration(i) * gap,
			Payload: p,
		})
	}
	return f
}

func TestShortFlowIsInsufficientNotClean(t *testing.T) {
	f := mkFlow(10, func(i int, d Direction) []byte { return []byte("hello") }, time.Millisecond)
	v := Run(f, Config{})
	if !v.Insufficient {
		t.Fatalf("short flow must be insufficient, got level %v score %.3f", v.Level, v.Score)
	}
	if v.Level != LevelInsufficient {
		t.Fatalf("expected LevelInsufficient, got %v", v.Level)
	}
	if v.Score != 0 {
		t.Fatalf("insufficient verdict must carry score 0, got %.3f", v.Score)
	}
}

func TestVerdictThresholdConstants(t *testing.T) {
	if BlockerThreshold != 0.7 || WarningThreshold != 0.4 {
		t.Fatalf("thresholds moved without a dedicated commit: blocker=%.2f warning=%.2f",
			BlockerThreshold, WarningThreshold)
	}
	var wsum float64
	for _, d := range detectorWeights {
		wsum += d.weight
	}
	if wsum != 1.0 {
		t.Fatalf("detector weights must sum to 1.0, got %.4f", wsum)
	}
}

func TestEntropyDetector(t *testing.T) {
	// TLS-like: structured, low-entropy payload.
	structured := bytes.Repeat([]byte{0x16, 0x03, 0x01, 0x02}, 100)
	f := mkFlow(60, func(i int, d Direction) []byte {
		if d == Outbound && i < 20 {
			return structured
		}
		return []byte("data")
	}, time.Millisecond)
	r := firstPacketEntropy(f, Config{})
	if r.Insufficient || r.Score != 0 {
		t.Fatalf("structured hello: expected score 0, got %+v", r)
	}

	// Tunnel-like: first packets indistinguishable from random.
	f2 := mkFlow(60, func(i int, d Direction) []byte {
		if d == Outbound && i < 20 {
			b := make([]byte, 300)
			if _, err := rand.Read(b); err != nil {
				t.Fatal(err)
			}
			return b
		}
		return []byte("data")
	}, time.Millisecond)
	r2 := firstPacketEntropy(f2, Config{})
	if r2.Score < 0.9 {
		t.Fatalf("random payload: expected high score, got %+v", r2)
	}
	if !strings.Contains(r2.Explain, "бит/байт") {
		t.Fatalf("explain must carry the entropy value, got %q", r2.Explain)
	}
}

func TestHandshakeSizesDetector(t *testing.T) {
	f := mkFlow(60, func(i int, d Direction) []byte {
		if i == 0 {
			return bytes.Repeat([]byte{0xAB}, 300)
		}
		return []byte("x")
	}, time.Millisecond)
	if r := handshakeSizes(f, Config{}); r.Score != 0 {
		t.Fatalf("300-byte first packet: expected 0, got %+v", r)
	}

	f2 := mkFlow(60, func(i int, d Direction) []byte {
		if i == 0 {
			return bytes.Repeat([]byte{0xAB}, 40)
		}
		return []byte("x")
	}, time.Millisecond)
	if r := handshakeSizes(f2, Config{}); r.Score < 0.9 {
		t.Fatalf("40-byte first packet: expected ~1.0, got %+v", r)
	}
}

func TestInOutBalanceDetector(t *testing.T) {
	// Balanced browsing-like flow.
	f := mkFlow(60, func(i int, d Direction) []byte {
		if d == Inbound {
			return bytes.Repeat([]byte{0x1}, 500)
		}
		return bytes.Repeat([]byte{0x2}, 100)
	}, time.Millisecond)
	if r := inOutBalance(f, Config{}); r.Score != 0 {
		t.Fatalf("inbound-heavy: expected 0, got %+v", r)
	}
	// One-way outbound tunnel.
	f2 := &Flow{}
	for i := 0; i < 60; i++ {
		f2.Packets = append(f2.Packets, Packet{Dir: Outbound, Size: 100, At: time.Duration(i) * time.Millisecond})
	}
	if r := inOutBalance(f2, Config{}); r.Score != 1.0 {
		t.Fatalf("one-way outbound: expected 1.0, got %+v", r)
	}
}

func TestInterArrivalDetector(t *testing.T) {
	// Machine-regular keepalives.
	f := &Flow{}
	for i := 0; i < 60; i++ {
		dir := Outbound
		if i%2 == 1 {
			dir = Inbound
		}
		f.Packets = append(f.Packets, Packet{Dir: dir, Size: 50, At: time.Duration(i) * 100 * time.Millisecond})
	}
	if r := interArrival(f, Config{}); r.Score < 0.5 {
		t.Fatalf("regular timing: expected high score, got %+v", r)
	}
	// Jittered human-like timing.
	f2 := &Flow{}
	gaps := []int64{3, 47, 12, 89, 5, 210, 33, 8, 150, 19, 64, 41, 7, 95, 28}
	at := int64(0)
	for i := 0; i < 60; i++ {
		dir := Outbound
		if i%2 == 1 {
			dir = Inbound
		}
		at += gaps[i%len(gaps)]
		f2.Packets = append(f2.Packets, Packet{Dir: dir, Size: 50, At: time.Duration(at) * time.Millisecond})
	}
	if r := interArrival(f2, Config{}); r.Score != 0 {
		t.Fatalf("jittered timing: expected 0, got %+v", r)
	}
}

func TestJA4DetectorReusesDiagnostics(t *testing.T) {
	hello := testClientHelloRecord(t, "example.com", true, true)
	f := &Flow{Packets: []Packet{
		{Dir: Outbound, Size: len(hello), At: 0, Payload: hello},
	}}
	cfg := Config{Profile: "chrome", DestHost: "example.com"}
	r := ja4Freshness(f, cfg)
	if r.Insufficient {
		t.Fatalf("expected a JA4 verdict, got insufficient: %q", r.Explain)
	}
	if !strings.Contains(r.Explain, "JA4 ") {
		t.Fatalf("explain must carry the JA4 fingerprint, got %q", r.Explain)
	}
	// Unknown fingerprint with PQ key share: diagnostics reports Fresh
	// (not in the stale set, modern key share) -> score 0.
	if r.Score != 0 {
		t.Fatalf("expected score 0 for fresh-via-diagnostics fingerprint, got %.2f (%q)", r.Score, r.Explain)
	}

	// Hello without the PQ key share contradicts a modern browser
	// fingerprint -> 0.7.
	noPQ := testClientHelloRecord(t, "example.com", true, false)
	fNoPQ := &Flow{Packets: []Packet{
		{Dir: Outbound, Size: len(noPQ), At: 0, Payload: noPQ},
	}}
	rNoPQ := ja4Freshness(fNoPQ, cfg)
	if rNoPQ.Score != 0.7 {
		t.Fatalf("expected score 0.7 for hello without PQ key share, got %.2f (%q)", rNoPQ.Score, rNoPQ.Explain)
	}

	// No ClientHello at all -> insufficient, never "clean".
	f2 := &Flow{Packets: []Packet{{Dir: Outbound, Size: 100, At: 0, Payload: bytes.Repeat([]byte{0xFF}, 100)}}}
	r2 := ja4Freshness(f2, cfg)
	if !r2.Insufficient {
		t.Fatalf("flow without ClientHello must be insufficient, got %+v", r2)
	}
}

func TestSNIConsistencyDetector(t *testing.T) {
	hello := testClientHelloRecord(t, "Example.COM", true, true)
	mk := func(h []byte) *Flow {
		return &Flow{Packets: []Packet{{Dir: Outbound, Size: len(h), At: 0, Payload: h}}}
	}
	if r := sniConsistency(mk(hello), Config{DestHost: "example.com"}); r.Score != 0 || r.Insufficient {
		t.Fatalf("matching SNI: expected 0, got %+v", r)
	}
	if r := sniConsistency(mk(hello), Config{DestHost: "other.example"}); r.Score != 1.0 {
		t.Fatalf("mismatched SNI: expected 1.0, got %+v", r)
	}
	if r := sniConsistency(mk(hello), Config{}); !r.Insufficient {
		t.Fatalf("empty DestHost: expected insufficient, got %+v", r)
	}
	// Hello without an SNI extension at all -> 0.5.
	noSNI := testClientHelloRecord(t, "", false, true)
	if r := sniConsistency(mk(noSNI), Config{DestHost: "example.com"}); r.Score != 0.5 {
		t.Fatalf("hello without SNI: expected 0.5, got %+v", r)
	}
}

func TestRunBlockerAndOK(t *testing.T) {
	// Blocker: random first packets (entropy 1.0), tiny first packet is
	// covered by entropy; one-way outbound (in/out 1.0); regular timing.
	f := &Flow{}
	for i := 0; i < 60; i++ {
		b := make([]byte, 300)
		if _, err := rand.Read(b); err != nil {
			t.Fatal(err)
		}
		f.Packets = append(f.Packets, Packet{
			Dir: Outbound, Size: len(b),
			At:      time.Duration(i) * 100 * time.Millisecond,
			Payload: b,
		})
	}
	v := Run(f, Config{})
	if v.Level != LevelBlocker {
		t.Fatalf("expected BLOCKER, got %v (score %.3f): %+v", v.Level, v.Score, v.Results)
	}

	// OK: TLS-like handshake, balanced, jittered, fresh-ish JA4, SNI match.
	hello := testClientHelloRecord(t, "example.com", true, true)
	f2 := &Flow{}
	gaps := []int64{3, 47, 12, 89, 5, 210, 33, 8, 150, 19, 64, 41, 7, 95, 28}
	at := int64(0)
	for i := 0; i < 60; i++ {
		dir := Outbound
		if i%2 == 1 {
			dir = Inbound
		}
		at += gaps[i%len(gaps)]
		var p []byte
		if i == 0 {
			p = hello
		} else if dir == Inbound {
			p = bytes.Repeat([]byte{0x17}, 600)
		} else {
			p = bytes.Repeat([]byte{0x17}, 120)
		}
		f2.Packets = append(f2.Packets, Packet{Dir: dir, Size: len(p), At: time.Duration(at) * time.Millisecond, Payload: p})
	}
	v2 := Run(f2, Config{DestHost: "example.com"})
	if v2.Level != LevelOK {
		t.Fatalf("expected OK, got %v (score %.3f): %+v", v2.Level, v2.Score, v2.Results)
	}
}

// testPcap builds a minimal classic-pcap (LE, Ethernet, IPv4/TCP) in memory.
func testPcap(t *testing.T, pkts ...[]byte) *bytes.Buffer {
	t.Helper()
	var buf bytes.Buffer
	hdr := make([]byte, 24)
	binary.LittleEndian.PutUint32(hdr[0:4], 0xd4c3b2a1)
	binary.LittleEndian.PutUint16(hdr[4:6], 2)
	binary.LittleEndian.PutUint16(hdr[6:8], 4)
	binary.LittleEndian.PutUint32(hdr[20:24], 1) // Ethernet
	buf.Write(hdr)
	for i, payload := range pkts {
		frame := buildEthernetTCP(t, i%2 == 0, payload)
		ph := make([]byte, 16)
		binary.LittleEndian.PutUint32(ph[0:4], uint32(1_700_000_000+i))
		binary.LittleEndian.PutUint32(ph[8:12], uint32(len(frame)))
		binary.LittleEndian.PutUint32(ph[12:16], uint32(len(frame)))
		buf.Write(ph)
		buf.Write(frame)
	}
	return &buf
}

func buildEthernetTCP(t *testing.T, fromClient bool, payload []byte) []byte {
	t.Helper()
	src := net.ParseIP("10.0.0.2").To4()
	dst := net.ParseIP("93.184.216.34").To4()
	if !fromClient {
		src, dst = dst, src
	}
	frame := make([]byte, 14)
	frame[12], frame[13] = 0x08, 0x00 // IPv4
	ip := make([]byte, 20)
	ip[0] = 0x45
	total := 20 + 20 + len(payload)
	binary.BigEndian.PutUint16(ip[2:4], uint16(total))
	ip[8] = 64
	ip[9] = 6 // TCP
	copy(ip[12:16], src)
	copy(ip[16:20], dst)
	tcp := make([]byte, 20)
	tcp[12] = 0x50 // data offset 5
	frame = append(frame, ip...)
	frame = append(frame, tcp...)
	frame = append(frame, payload...)
	return frame
}

func TestReadPcap(t *testing.T) {
	buf := testPcap(t, []byte("client-hello"), []byte("server-reply"))
	flow, err := ReadPcap(buf)
	if err != nil {
		t.Fatalf("ReadPcap: %v", err)
	}
	if len(flow.Packets) != 2 {
		t.Fatalf("expected 2 packets, got %d", len(flow.Packets))
	}
	if flow.Packets[0].Dir != Outbound || flow.Packets[1].Dir != Inbound {
		t.Fatalf("wrong directions: %+v", flow.Packets)
	}
	if flow.Packets[0].Size != len("client-hello") {
		t.Fatalf("wrong payload size: %d", flow.Packets[0].Size)
	}
	if !bytes.Equal(flow.Packets[0].Payload, []byte("client-hello")) {
		t.Fatalf("wrong payload: %q", flow.Packets[0].Payload)
	}
	if flow.Packets[1].At <= 0 {
		t.Fatalf("timestamps must be relative and increasing: %v", flow.Packets[1].At)
	}
	if _, err := ReadPcap(bytes.NewReader([]byte("garbage"))); err == nil {
		t.Fatal("expected error on garbage input")
	}
}

// testPcapFrac builds a classic-pcap (LE) with the given magic and per-packet
// timestamp fractions; both packets share the same tsSec so the gap is
// exactly the fraction difference.
func testPcapFrac(t *testing.T, magic uint32, fracs []uint32, pkts ...[]byte) *bytes.Buffer {
	t.Helper()
	if len(fracs) != len(pkts) {
		t.Fatal("fracs/pkts length mismatch")
	}
	var buf bytes.Buffer
	hdr := make([]byte, 24)
	binary.LittleEndian.PutUint32(hdr[0:4], magic)
	binary.LittleEndian.PutUint16(hdr[4:6], 2)
	binary.LittleEndian.PutUint16(hdr[6:8], 4)
	binary.LittleEndian.PutUint32(hdr[20:24], 1) // Ethernet
	buf.Write(hdr)
	for i, payload := range pkts {
		frame := buildEthernetTCP(t, i%2 == 0, payload)
		ph := make([]byte, 16)
		binary.LittleEndian.PutUint32(ph[0:4], uint32(1_700_000_000))
		binary.LittleEndian.PutUint32(ph[4:8], fracs[i])
		binary.LittleEndian.PutUint32(ph[8:12], uint32(len(frame)))
		binary.LittleEndian.PutUint32(ph[12:16], uint32(len(frame)))
		buf.Write(ph)
		buf.Write(frame)
	}
	return &buf
}

// TestReadPcapNanosecTimestamps checks that nanosec-magic pcaps get
// nanosecond (not microsecond*1000) timestamp fractions: a 20ms gap must
// read as 20ms, otherwise inter-arrival gaps inflate 1000x and the timing
// heuristic flags every flow as "quiet".
func TestReadPcapNanosecTimestamps(t *testing.T) {
	cases := []struct {
		name    string
		magic   uint32
		nanosec bool
	}{
		{"microsec", 0xd4c3b2a1, false},
		{"nanosec", 0x4d3c2ba1, true},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			frac := uint32(20_000) // 20ms in microseconds
			if c.nanosec {
				frac = 20_000_000 // 20ms in nanoseconds
			}
			buf := testPcapFrac(t, c.magic, []uint32{0, frac},
				[]byte("one"), []byte("two"))
			flow, err := ReadPcap(buf)
			if err != nil {
				t.Fatalf("ReadPcap: %v", err)
			}
			if len(flow.Packets) != 2 {
				t.Fatalf("expected 2 packets, got %d", len(flow.Packets))
			}
			gap := flow.Packets[1].At - flow.Packets[0].At
			if gap != 20*time.Millisecond {
				t.Fatalf("gap = %v, want 20ms", gap)
			}
		})
	}
}
