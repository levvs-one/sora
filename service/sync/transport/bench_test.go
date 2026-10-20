package transport

// Benchmarks for the Noise_XX transport hot paths: packet encryption,
// decryption, and the full write+read round trip of a 1 KiB application
// message. The wire format is unchanged; these measure only the cost of
// framing, allocations, and the cipher.

import (
	"context"
	"crypto/rand"
	"encoding/binary"
	"io"
	"net"
	"sync"
	"testing"
	"time"

	"github.com/flynn/noise"

	"github.com/levvs-one/sora-client/sync/pairing"
)

// benchDiscardConn is a net.Conn that swallows writes: it isolates the
// encryption+framing cost from network I/O.
type benchDiscardConn struct{}

func (benchDiscardConn) Read(b []byte) (int, error)         { return 0, io.EOF }
func (benchDiscardConn) Write(b []byte) (int, error)        { return len(b), nil }
func (benchDiscardConn) Close() error                       { return nil }
func (benchDiscardConn) LocalAddr() net.Addr                { return nil }
func (benchDiscardConn) RemoteAddr() net.Addr               { return nil }
func (benchDiscardConn) SetDeadline(time.Time) error        { return nil }
func (benchDiscardConn) SetReadDeadline(time.Time) error    { return nil }
func (benchDiscardConn) SetWriteDeadline(time.Time) error   { return nil }

// benchReplayConn serves a pre-recorded byte stream: it isolates the
// read+decryption cost.
type benchReplayConn struct {
	data []byte
	pos  int
}

func (c *benchReplayConn) Read(b []byte) (int, error) {
	if c.pos >= len(c.data) {
		return 0, io.EOF
	}
	n := copy(b, c.data[c.pos:])
	c.pos += n
	return n, nil
}
func (c *benchReplayConn) Write(b []byte) (int, error)     { return len(b), nil }
func (c *benchReplayConn) Close() error                   { return nil }
func (c *benchReplayConn) LocalAddr() net.Addr             { return nil }
func (c *benchReplayConn) RemoteAddr() net.Addr            { return nil }
func (c *benchReplayConn) SetDeadline(time.Time) error     { return nil }
func (c *benchReplayConn) SetReadDeadline(time.Time) error { return nil }
func (c *benchReplayConn) SetWriteDeadline(time.Time) error { return nil }

// benchCipherPair runs one Noise_XX handshake and returns a matched
// encrypt/decrypt cipher-state pair (initiator encrypt == responder decrypt,
// nonces aligned at zero).
func benchCipherPair(tb testing.TB) (enc, dec *noise.CipherState) {
	tb.Helper()
	var ipriv, rpriv [32]byte
	if _, err := rand.Read(ipriv[:]); err != nil {
		tb.Fatal(err)
	}
	if _, err := rand.Read(rpriv[:]); err != nil {
		tb.Fatal(err)
	}
	ihs, err := newState(true, ipriv)
	if err != nil {
		tb.Fatal(err)
	}
	rhs, err := newState(false, rpriv)
	if err != nil {
		tb.Fatal(err)
	}
	a, c := net.Pipe()
	var ires, rres *handshakeResult
	var ierr, rerr error
	var wg sync.WaitGroup
	wg.Add(2)
	go func() { defer wg.Done(); ires, ierr = runHandshake(a, ihs, true) }()
	go func() { defer wg.Done(); rres, rerr = runHandshake(c, rhs, false) }()
	wg.Wait()
	_ = a.Close()
	_ = c.Close()
	if ierr != nil || rerr != nil {
		tb.Fatalf("handshake: %v %v", ierr, rerr)
	}
	return ires.encrypt, rres.decrypt
}

// benchPayload returns a deterministic 1 KiB payload.
func benchPayload() []byte {
	p := make([]byte, 1024)
	for i := range p {
		p[i] = byte(i * 31)
	}
	return p
}

// BenchmarkEncrypt1KB measures WriteMsg of a 1 KiB message: chunk framing,
// Noise encryption, and (discarded) writes.
func BenchmarkEncrypt1KB(b *testing.B) {
	enc, _ := benchCipherPair(b)
	c := &Conn{Conn: benchDiscardConn{}, encrypt: enc}
	payload := benchPayload()
	b.SetBytes(int64(len(payload)))
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if err := c.WriteMsg(payload); err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkDecrypt1KB measures ReadMsg of a 1 KiB message: framing and
// Noise decryption of pre-recorded ciphertext.
func BenchmarkDecrypt1KB(b *testing.B) {
	payload := benchPayload()
	plain := make([]byte, 0, len(payload)+1)
	plain = append(plain, 1)
	plain = append(plain, payload...)

	const batch = 4096
	newBatch := func() (*Conn, int) {
		enc, dec := benchCipherPair(b)
		frames := make([]byte, 0, batch*(2+len(plain)+16))
		var hdr [2]byte
		for i := 0; i < batch; i++ {
			ct, err := enc.Encrypt(nil, nil, plain)
			if err != nil {
				b.Fatal(err)
			}
			binary.BigEndian.PutUint16(hdr[:], uint16(len(ct)))
			frames = append(frames, hdr[:]...)
			frames = append(frames, ct...)
		}
		return &Conn{Conn: &benchReplayConn{data: frames}, decrypt: dec}, len(frames)
	}

	c, _ := newBatch()
	b.SetBytes(int64(len(payload)))
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if i%batch == 0 {
			b.StopTimer()
			c, _ = newBatch()
			b.StartTimer()
		}
		got, err := c.ReadMsg()
		if err != nil {
			b.Fatal(err)
		}
		if len(got) != len(payload) || got[0] != payload[0] {
			b.Fatal("decrypted payload mismatch")
		}
	}
}

// benchRoundTripPair returns a fully handshaked initiator/responder pair
// over TCP loopback.
func benchRoundTripPair(tb testing.TB) (initiator, responder *Conn) {
	tb.Helper()
	inv, epriv, err := pairing.Generate("device-a")
	if err != nil {
		tb.Fatal(err)
	}
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		tb.Fatal(err)
	}
	defer ln.Close()
	acceptCh := make(chan net.Conn, 1)
	go func() {
		c, err := ln.Accept()
		if err == nil {
			acceptCh <- c
		}
	}()
	raw, err := net.Dial("tcp", ln.Addr().String())
	if err != nil {
		tb.Fatal(err)
	}
	peerRaw := <-acceptCh
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	type result struct {
		c   *Conn
		err error
	}
	resCh := make(chan result, 1)
	go func() {
		c, err := Accept(ctx, peerRaw, epriv, inv.Token, testIdentity("device-a", "A"))
		resCh <- result{c, err}
	}()
	dialCh := make(chan result, 1)
	go func() {
		c, err := Dial(ctx, raw, inv, testIdentity("device-b", "B"))
		dialCh <- result{c, err}
	}()
	ar := <-resCh
	dr := <-dialCh
	if ar.err != nil || dr.err != nil {
		tb.Fatalf("handshake: %v %v", ar.err, dr.err)
	}
	return dr.c, ar.c
}

// BenchmarkTransportRoundTrip1KB measures the full path of one 1 KiB
// application message: encrypt + frame + write, then read + decrypt. The
// reader runs on a separate goroutine draining as fast as it can.
func BenchmarkTransportRoundTrip1KB(b *testing.B) {
	w, r := benchRoundTripPair(b)
	defer w.Close()
	defer r.Close()
	payload := benchPayload()
	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			if _, err := r.ReadMsg(); err != nil {
				return
			}
		}
	}()
	b.SetBytes(int64(len(payload)))
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if err := w.WriteMsg(payload); err != nil {
			b.Fatal(err)
		}
	}
	b.StopTimer()
	_ = w.Close()
	<-done
}
