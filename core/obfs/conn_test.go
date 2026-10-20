package obfs

import (
	"context"
	"crypto/tls"
	"encoding/binary"
	"errors"
	"io"
	"net"
	"testing"
	"time"
)

// TestWrapConnFragmentAndSNI writes one ClientHello record through a fully
// featured WrapConn and verifies the peer receives the same fragments the
// splitter would produce, with the fake SNI applied.
func TestWrapConnFragmentAndSNI(t *testing.T) {
	rec := testClientHelloRecord(t, "example.com", true)
	p := Profile{
		UTLS:      "none",
		FragSizes: []int{30, 30},
		FakeSNI:   "decoy.test",
	}
	wantFrags, err := SplitClientHello(mustRewrite(t, rec, "decoy.test"), []int{30, 30})
	if err != nil {
		t.Fatalf("SplitClientHello: %v", err)
	}

	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()
	wrapped := p.WrapConn(client)

	writeErr := make(chan error, 1)
	go func() {
		_, err := wrapped.Write(rec)
		writeErr <- err
	}()

	for i, want := range wantFrags {
		got := make([]byte, len(want))
		if _, err := io.ReadFull(server, got); err != nil {
			t.Fatalf("fragment %d: %v", i, err)
		}
		if string(got) != string(want) {
			t.Fatalf("fragment %d differs from expected", i)
		}
	}
	if err := <-writeErr; err != nil {
		t.Fatalf("Write: %v", err)
	}
}

func mustRewrite(t *testing.T, rec []byte, fake string) []byte {
	t.Helper()
	out, err := RewriteClientHelloSNI(rec, fake)
	if err != nil {
		t.Fatalf("RewriteClientHelloSNI: %v", err)
	}
	return out
}

// TestWrapConnPassthrough verifies non-handshake writes go through
// untouched and report the original length.
func TestWrapConnPassthrough(t *testing.T) {
	p := Profile{UTLS: "chrome", FragSizes: []int{32}, Jitter: time.Millisecond, FakeSNI: "decoy.test"}
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()
	wrapped := p.WrapConn(client)

	// 0x17 = application data: not a ClientHello, must pass through.
	app := append([]byte{0x17, 0x03, 0x03, 0x00, 0x06}, []byte("secret")...)
	go func() {
		buf := make([]byte, len(app))
		if _, err := io.ReadFull(server, buf); err != nil {
			t.Errorf("read: %v", err)
		}
		if string(buf) != string(app) {
			t.Errorf("data corrupted: %q", buf)
		}
	}()
	if n, err := wrapped.Write(app); err != nil || n != len(app) {
		t.Fatalf("Write = %d, %v", n, err)
	}
}

// TestWrapConnIdentity checks that a zero profile returns the conn as-is.
func TestWrapConnIdentity(t *testing.T) {
	client, _ := net.Pipe()
	defer client.Close()
	if got := (Profile{}).WrapConn(client); got != client {
		t.Fatal("zero profile must not wrap the connection")
	}
	if (Profile{}).WrapConn(nil) != nil {
		t.Fatal("WrapConn(nil) must return nil")
	}
}

// TestWrapConnMonstrousDelays ensures WrapConn clamps instead of hanging.
func TestWrapConnMonstrousDelays(t *testing.T) {
	p := Profile{UTLS: "none", FragSizes: []int{40}, FragDelay: 24 * time.Hour, Jitter: 24 * time.Hour}
	rec := testClientHelloRecord(t, "example.com", false)
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()
	wrapped := p.WrapConn(client)

	done := make(chan error, 1)
	go func() {
		_, err := wrapped.Write(rec)
		done <- err
	}()
	// Drain the two fragments.
	for i := 0; i < 2; i++ {
		hdr := make([]byte, recordHeaderLen)
		if _, err := io.ReadFull(server, hdr); err != nil {
			t.Fatal(err)
		}
		if _, err := io.ReadFull(server, make([]byte, int(binary.BigEndian.Uint16(hdr[3:5])))); err != nil {
			t.Fatal(err)
		}
	}
	select {
	case err := <-done:
		if err != nil {
			t.Fatalf("Write: %v", err)
		}
	case <-time.After(30 * time.Second):
		t.Fatal("Write did not finish: delays were not clamped")
	}
}

// TestDialTLS runs a real TLS handshake through DialTLS against a local
// TLS server, exercising WrapConn under a live crypto/tls client.
func TestDialTLS(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	defer ln.Close()

	cert := testServerCert(t)
	const nConns = 2
	serverDone := make(chan error, nConns)
	go func() {
		for i := 0; i < nConns; i++ {
			raw, err := ln.Accept()
			if err != nil {
				serverDone <- err
				return
			}
			go func(c net.Conn) {
				defer c.Close()
				s := tls.Server(c, &tls.Config{Certificates: []tls.Certificate{cert}})
				defer s.Close()
				if err := s.Handshake(); err != nil {
					serverDone <- err
					return
				}
				buf := make([]byte, 4)
				if _, err := io.ReadFull(s, buf); err != nil {
					serverDone <- err
					return
				}
				if string(buf) != "ping" {
					serverDone <- errors.New("payload mismatch")
					return
				}
				serverDone <- nil
			}(raw)
		}
	}()

	for _, fp := range []string{"none", "chrome"} {
		t.Run(fp, func(t *testing.T) {
			p := Profile{UTLS: fp, FragSizes: []int{48}, FragDelay: time.Millisecond}
			conn, err := p.DialTLS(context.Background(), func(ctx context.Context, network, address string) (net.Conn, error) {
				var d net.Dialer
				return d.DialContext(ctx, network, address)
			}, "tcp", ln.Addr().String(), &tls.Config{
				ServerName:         "example.com",
				InsecureSkipVerify: true,
			})
			if err != nil {
				t.Fatalf("DialTLS: %v", err)
			}
			defer conn.Close()
			tlsConn, ok := conn.(interface{ Handshake() error })
			if !ok {
				t.Fatal("DialTLS did not return a TLS connection")
			}
			if err := tlsConn.Handshake(); err != nil {
				t.Fatalf("handshake: %v", err)
			}
			if _, err := conn.Write([]byte("ping")); err != nil {
				t.Fatalf("write: %v", err)
			}
		})
	}
	for i := 0; i < nConns; i++ {
		if err := <-serverDone; err != nil {
			t.Fatalf("server: %v", err)
		}
	}
}

func TestDialTLSErrors(t *testing.T) {
	p := Profile{UTLS: "chrome"}
	if _, err := p.DialTLS(context.Background(), nil, "tcp", "x", &tls.Config{}); err == nil {
		t.Error("expected error for nil dial")
	}
	dial := func(ctx context.Context, network, address string) (net.Conn, error) {
		c, _ := net.Pipe()
		return c, nil
	}
	if _, err := p.DialTLS(context.Background(), dial, "tcp", "x", nil); err == nil {
		t.Error("expected error for nil tls.Config")
	}
	if _, err := (Profile{UTLS: "opera"}).DialTLS(context.Background(), dial, "tcp", "x", &tls.Config{ServerName: "x", InsecureSkipVerify: true}); err == nil {
		t.Error("expected error for unknown fingerprint")
	}
}

// TestWrapConnFailsClosedOnRewriteError pins the CENSOR-LEAK
// fail-closed rule: when a ClientHello cannot be given the profile's
// fake SNI, Write must fail and NOTHING may reach the peer — the
// previous behaviour sent the original hello, putting the real SNI
// on the wire in plaintext on every rewrite error.
func TestWrapConnFailsClosedOnRewriteError(t *testing.T) {
	rec := testClientHelloRecord(t, "real.example", true)
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()
	// An invalid fake hostname makes RewriteClientHelloSNI fail.
	wrapped := (&fragConn{Conn: client, fakeSNI: "not a hostname!"})
	if _, err := wrapped.Write(rec); err == nil {
		t.Fatal("Write succeeded with an unrewritable ClientHello; want fail-closed error")
	}
	// Nothing may have been written: a read with a deadline must
	// time out, not return hello bytes.
	_ = server.SetReadDeadline(time.Now().Add(200 * time.Millisecond))
	buf := make([]byte, 1)
	if _, err := server.Read(buf); err == nil {
		t.Fatal("bytes reached the peer despite the rewrite failure")
	}
}

// TestWrapConnFailsClosedOnSplitError pins the same rule for
// fragmentation: a hello the profile wants fragmented is never sent
// whole when the splitter rejects the sizes.
func TestWrapConnFailsClosedOnSplitError(t *testing.T) {
	rec := testClientHelloRecord(t, "real.example", true)
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()
	wrapped := (&fragConn{Conn: client, sizes: []int{-5}})
	if _, err := wrapped.Write(rec); err == nil {
		t.Fatal("Write succeeded with unsplittable sizes; want fail-closed error")
	}
	_ = server.SetReadDeadline(time.Now().Add(200 * time.Millisecond))
	buf := make([]byte, 1)
	if _, err := server.Read(buf); err == nil {
		t.Fatal("bytes reached the peer despite the split failure")
	}
}

// TestWrapConnNoSNIPassesThrough pins the one deliberate exception:
// a well-formed ClientHello with no server_name extension carries no
// SNI to leak, so it is sent (fragmented if configured), not failed.
func TestWrapConnNoSNIPassesThrough(t *testing.T) {
	rec := testClientHelloRecordNoSNI(t)
	client, server := net.Pipe()
	defer client.Close()
	defer server.Close()
	wrapped := (&fragConn{Conn: client, fakeSNI: "decoy.test"})
	done := make(chan error, 1)
	go func() {
		_, err := wrapped.Write(rec)
		done <- err
	}()
	got := make([]byte, len(rec))
	if _, err := io.ReadFull(server, got); err != nil {
		t.Fatalf("read: %v", err)
	}
	if string(got) != string(rec) {
		t.Fatal("no-SNI hello was modified")
	}
	if err := <-done; err != nil {
		t.Fatalf("Write: %v", err)
	}
}
