package obfs

import (
	"encoding/binary"
	"io"
	"net"
	"strings"
	"testing"
	"time"
)

func TestSplitClientHello(t *testing.T) {
	rec := testClientHelloRecord(t, "example.com", true)
	sizes := []int{20, 30, 10}
	frags, err := SplitClientHello(rec, sizes)
	if err != nil {
		t.Fatalf("SplitClientHello: %v", err)
	}
	if len(frags) != len(sizes)+1 {
		t.Fatalf("got %d fragments, want %d", len(frags), len(sizes)+1)
	}
	payloadLen := len(rec) - recordHeaderLen
	var total int
	for _, s := range sizes {
		total += s
	}
	var payload []byte
	for i, f := range frags {
		if len(f) < recordHeaderLen || f[0] != recordTypeHandshake {
			t.Fatalf("fragment %d: bad record header", i)
		}
		// Legacy version bytes are preserved from the original record.
		if f[1] != rec[1] || f[2] != rec[2] {
			t.Fatalf("fragment %d: version changed", i)
		}
		n := int(binary.BigEndian.Uint16(f[3:5]))
		if recordHeaderLen+n != len(f) {
			t.Fatalf("fragment %d: length prefix mismatch", i)
		}
		want := payloadLen - total
		if i < len(sizes) {
			want = sizes[i]
		}
		if n != want {
			t.Fatalf("fragment %d: payload %d, want %d", i, n, want)
		}
		payload = append(payload, f[recordHeaderLen:]...)
	}
	// Reassembly yields the original ClientHello payload byte-for-byte, and
	// the handshake header (message type + length) is intact in fragment 0.
	if string(payload) != string(rec[recordHeaderLen:]) {
		t.Fatal("reassembled payload differs from original")
	}
	if frags[0][recordHeaderLen] != handshakeClientHello {
		t.Fatal("first fragment does not start with the handshake header")
	}
}

func TestSplitClientHelloNoSizes(t *testing.T) {
	rec := testClientHelloRecord(t, "example.com", false)
	frags, err := SplitClientHello(rec, nil)
	if err != nil {
		t.Fatalf("SplitClientHello(nil): %v", err)
	}
	if len(frags) != 1 || string(frags[0]) != string(rec) {
		t.Fatal("nil sizes must return the record unchanged")
	}
}

func TestSplitClientHelloErrors(t *testing.T) {
	rec := testClientHelloRecord(t, "example.com", false)
	payloadLen := len(rec) - recordHeaderLen

	cases := []struct {
		name   string
		record []byte
		sizes  []int
	}{
		{"not a handshake", append([]byte{21, 3, 1, 0, 5}, 1, 2, 3, 4, 5), []int{2}},
		{"not a clienthello", func() []byte { r := append([]byte(nil), rec...); r[recordHeaderLen] = 2; return r }(), []int{2}},
		{"truncated", rec[:10], []int{2}},
		{"length mismatch", append(rec, 0x00), []int{2}},
		{"zero size", rec, []int{0}},
		{"negative size", rec, []int{-1}},
		{"oversize", rec, []int{MaxFragmentSize + 1}},
		{"sizes cover all", rec, []int{payloadLen}},
		{"sizes exceed", rec, []int{payloadLen + 1}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if _, err := SplitClientHello(tc.record, tc.sizes); err == nil {
				t.Fatal("expected error, got nil")
			}
		})
	}
}

func TestParseTLSRecords(t *testing.T) {
	r1 := testClientHelloRecord(t, "a.example", false)
	r2 := testClientHelloRecord(t, "b.example", false)
	recs, err := parseTLSRecords(append(append([]byte(nil), r1...), r2...))
	if err != nil {
		t.Fatalf("parseTLSRecords: %v", err)
	}
	if len(recs) != 2 || string(recs[0]) != string(r1) || string(recs[1]) != string(r2) {
		t.Fatal("concatenated records not split correctly")
	}
	if _, err := parseTLSRecords(r1[:len(r1)-3]); err == nil {
		t.Fatal("expected error for truncated record")
	}
	if _, err := parseTLSRecords(r1[:3]); err == nil {
		t.Fatal("expected error for truncated header")
	}
}

func TestWriteFragmented(t *testing.T) {
	rec := testClientHelloRecord(t, "example.com", false)
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()

	sizes := []int{20, 20}
	const delay = 20 * time.Millisecond
	done := make(chan error, 1)
	go func() { done <- WriteFragmented(client, rec, sizes, delay) }()

	start := time.Now()
	var payload []byte
	for i := 0; i < len(sizes)+1; i++ {
		hdr := make([]byte, recordHeaderLen)
		if _, err := io.ReadFull(server, hdr); err != nil {
			t.Fatalf("fragment %d header: %v", i, err)
		}
		n := int(binary.BigEndian.Uint16(hdr[3:5]))
		body := make([]byte, n)
		if _, err := io.ReadFull(server, body); err != nil {
			t.Fatalf("fragment %d body: %v", i, err)
		}
		payload = append(payload, body...)
	}
	elapsed := time.Since(start)
	if err := <-done; err != nil {
		t.Fatalf("WriteFragmented: %v", err)
	}
	if string(payload) != string(rec[recordHeaderLen:]) {
		t.Fatal("reassembled payload differs")
	}
	// Two inter-fragment pauses of 20ms each.
	if elapsed < 2*delay {
		t.Fatalf("fragments arrived too fast: %s < %s", elapsed, 2*delay)
	}
	if elapsed > 10*delay {
		t.Fatalf("fragments suspiciously slow: %s", elapsed)
	}
}

func TestWriteFragmentedDelayClamped(t *testing.T) {
	rec := testClientHelloRecord(t, "example.com", false)
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()

	done := make(chan error, 1)
	go func() { done <- WriteFragmented(client, rec, []int{40}, 24*time.Hour) }()
	// Drain both fragments so the writer can finish.
	for i := 0; i < 2; i++ {
		hdr := make([]byte, recordHeaderLen)
		if _, err := io.ReadFull(server, hdr); err != nil {
			t.Fatal(err)
		}
		if _, err := io.ReadFull(server, make([]byte, int(binary.BigEndian.Uint16(hdr[3:5])))); err != nil {
			t.Fatal(err)
		}
	}
	if err := <-done; err != nil {
		t.Fatalf("WriteFragmented: %v", err)
	}
	// If the 24h delay were not clamped to MaxFragDelay, this test would
	// never finish. Reaching here proves the clamp.
}

func TestWriteFragmentedError(t *testing.T) {
	if err := WriteFragmented(io.Discard, []byte{1, 2, 3}, []int{1}, 0); err == nil {
		t.Fatal("expected error for bad record")
	}
	if !strings.Contains(func() string {
		_, err := SplitClientHello([]byte{1}, []int{1})
		return err.Error()
	}(), "too short") {
		t.Fatal("unexpected error text")
	}
}
