package transport

import (
	"context"
	"crypto/rand"
	"encoding/binary"
	"io"
	"net"
	"strings"
	"sync"
	"testing"
	"time"

	"golang.org/x/crypto/curve25519"

	"github.com/levvs-one/sora-client/sync/pairing"
)

func testIdentity(id, name string) Identity {
	var pub [32]byte
	for i := range pub {
		pub[i] = byte(i + 1)
	}
	return Identity{DeviceID: id, DeviceName: name, PublicKey: pub}
}

func TestPairHandshakeAndMessages(t *testing.T) {
	inv, epriv, err := pairing.Generate("device-a")
	if err != nil {
		t.Fatal(err)
	}
	a, b := net.Pipe()
	defer a.Close()
	defer b.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	type result struct {
		c   *Conn
		err error
	}
	acceptCh := make(chan result, 1)
	go func() {
		c, err := Accept(ctx, a, epriv, inv.Token, testIdentity("device-a", "Laptop"))
		acceptCh <- result{c, err}
	}()
	dialCh := make(chan result, 1)
	go func() {
		c, err := Dial(ctx, b, inv, testIdentity("device-b", "Phone"))
		dialCh <- result{c, err}
	}()
	ar := <-acceptCh
	dr := <-dialCh
	if ar.err != nil {
		t.Fatalf("accept: %v", ar.err)
	}
	if dr.err != nil {
		t.Fatalf("dial: %v", dr.err)
	}
	if ar.c.Peer.DeviceID != "device-b" || dr.c.Peer.DeviceID != "device-a" {
		t.Fatalf("identities not exchanged: %+v %+v", ar.c.Peer, dr.c.Peer)
	}
	// Small and large messages round-trip. net.Pipe is synchronous, so the
	// writer runs in its own goroutine.
	for _, msg := range [][]byte{[]byte("hello"), make([]byte, 100*1024)} {
		for i := range msg {
			msg[i] = byte(i)
		}
		writeErr := make(chan error, 1)
		go func() { writeErr <- dr.c.WriteMsg(msg) }()
		got, err := ar.c.ReadMsg()
		if err != nil {
			t.Fatalf("read: %v", err)
		}
		if err := <-writeErr; err != nil {
			t.Fatalf("write: %v", err)
		}
		if len(got) != len(msg) {
			t.Fatalf("message length changed: %d -> %d", len(msg), len(got))
		}
		for i := range msg {
			if got[i] != msg[i] {
				t.Fatal("message corrupted")
			}
		}
	}
	// Empty message round-trips.
	writeErr := make(chan error, 1)
	go func() { writeErr <- dr.c.WriteMsg(nil) }()
	got, err := ar.c.ReadMsg()
	if err != nil {
		t.Fatalf("read empty: %v", err)
	}
	if err := <-writeErr; err != nil {
		t.Fatalf("write empty: %v", err)
	}
	if len(got) != 0 {
		t.Fatalf("empty message came back with %d bytes", len(got))
	}
}

func TestPairRejectsWrongToken(t *testing.T) {
	inv, epriv, err := pairing.Generate("device-a")
	if err != nil {
		t.Fatal(err)
	}
	a, b := net.Pipe()
	defer a.Close()
	defer b.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	errCh := make(chan error, 1)
	go func() {
		_, err := Accept(ctx, a, epriv, inv.Token, testIdentity("device-a", "Laptop"))
		errCh <- err
	}()
	bad := *inv
	bad.Token[0] ^= 0xff
	_, derr := Dial(ctx, b, &bad, testIdentity("device-b", "Phone"))
	if derr == nil {
		t.Fatal("dial with a wrong token must fail")
	}
	if aerr := <-errCh; aerr == nil {
		t.Fatal("accept with a wrong token must fail")
	}
}

func TestPairRejectsImpostor(t *testing.T) {
	// An attacker shows their own QR but the joiner scanned the victim's:
	// the static key check must catch it.
	victimInv, _, err := pairing.Generate("victim")
	if err != nil {
		t.Fatal(err)
	}
	attackerInv, attackerPriv, err := pairing.Generate("attacker")
	if err != nil {
		t.Fatal(err)
	}
	_ = victimInv
	a, b := net.Pipe()
	defer a.Close()
	defer b.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	errCh := make(chan error, 1)
	go func() {
		_, err := Accept(ctx, a, attackerPriv, attackerInv.Token, testIdentity("attacker", "Evil"))
		errCh <- err
	}()
	// The joiner scanned the victim's QR but connected to the attacker.
	if _, err := Dial(ctx, b, victimInv, testIdentity("device-b", "Phone")); err == nil {
		t.Fatal("dial to an impostor must fail the static key check")
	}
	<-errCh
}

func TestKnownPeerHandshake(t *testing.T) {
	newKey := func() (priv, pub [32]byte) {
		if _, err := rand.Read(priv[:]); err != nil {
			t.Fatal(err)
		}
		p, err := curve25519.X25519(priv[:], curve25519.Basepoint)
		if err != nil {
			t.Fatal(err)
		}
		copy(pub[:], p)
		return priv, pub
	}
	privA, pubA := newKey()
	privB, pubB := newKey()

	a, b := net.Pipe()
	defer a.Close()
	defer b.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	type result struct {
		c   *Conn
		err error
	}
	acceptCh := make(chan result, 1)
	go func() {
		c, err := AcceptKnown(ctx, a, privB,
			Identity{DeviceID: "b", PublicKey: pubB},
			func(k [32]byte) bool { return k == pubA })
		acceptCh <- result{c, err}
	}()
	dialCh := make(chan result, 1)
	go func() {
		c, err := DialKnown(ctx, b, pubB, privA, Identity{DeviceID: "a", PublicKey: pubA})
		dialCh <- result{c, err}
	}()
	ar := <-acceptCh
	dr := <-dialCh
	if ar.err != nil || dr.err != nil {
		t.Fatalf("known-peer handshake: %v %v", ar.err, dr.err)
	}
	if ar.c.Peer.DeviceID != "a" || dr.c.Peer.DeviceID != "b" {
		t.Fatal("identities not exchanged")
	}
	// Messages flow on the known-peer channel too.
	writeErr := make(chan error, 1)
	go func() { writeErr <- dr.c.WriteMsg([]byte("ping")) }()
	got, err := ar.c.ReadMsg()
	if err != nil || string(got) != "ping" {
		t.Fatalf("message: %v %q", err, got)
	}
	if err := <-writeErr; err != nil {
		t.Fatal(err)
	}
}

func TestKnownPeerRejectsUnknown(t *testing.T) {
	newKey := func() (priv, pub [32]byte) {
		if _, err := rand.Read(priv[:]); err != nil {
			t.Fatal(err)
		}
		p, _ := curve25519.X25519(priv[:], curve25519.Basepoint)
		copy(pub[:], p)
		return priv, pub
	}
	_, pubA := newKey()
	privB, pubB := newKey()
	privEvil, pubEvil := newKey()

	a, b := net.Pipe()
	defer a.Close()
	defer b.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	errCh := make(chan error, 1)
	go func() {
		// Only A is paired; evil must be rejected.
		_, err := AcceptKnown(ctx, a, privB,
			Identity{DeviceID: "b", PublicKey: pubB},
			func(k [32]byte) bool { return k == pubA })
		errCh <- err
	}()
	_, derr := DialKnown(ctx, b, pubB, privEvil, Identity{DeviceID: "evil", PublicKey: pubEvil})
	if derr != nil {
		t.Logf("dial failed (also fine): %v", derr)
	}
	if aerr := <-errCh; aerr == nil {
		t.Fatal("accept must reject the unpaired device")
	}
}

// tamperProxy copies length-prefixed frames between two conns, flipping one
// byte in the n-th frame flowing from src to dst. It models a LAN attacker
// who can modify ciphertext but not break the Noise channel.
func tamperProxy(t *testing.T, src, dst net.Conn, tamperNth int) {
	t.Helper()
	go func() {
		defer src.Close()
		defer dst.Close()
		var hdr [2]byte
		n := 0
		for {
			if _, err := io.ReadFull(src, hdr[:]); err != nil {
				return
			}
			l := int(binary.BigEndian.Uint16(hdr[:]))
			frame := make([]byte, l)
			if _, err := io.ReadFull(src, frame); err != nil {
				return
			}
			n++
			if n == tamperNth && l > 4 {
				frame[4] ^= 0xff
			}
			if _, err := dst.Write(hdr[:]); err != nil {
				return
			}
			if _, err := dst.Write(frame); err != nil {
				return
			}
		}
	}()
}

// pairWithProxy runs Dial/Accept with a tampering proxy between them.
// tamperNth counts initiator->responder frames; 0 disables tampering.
func pairWithProxy(t *testing.T, tamperNth int) (acc, dial *Conn) {
	t.Helper()
	inv, epriv, err := pairing.Generate("device-a")
	if err != nil {
		t.Fatal(err)
	}
	a1, a2 := net.Pipe()
	b1, b2 := net.Pipe()
	// Pipe (x1,x2): writes to x1 are read from x2. The dialer owns b2 and
	// the acceptor owns a1, so the proxies bridge b1->a2 and a2->b1.
	tamperProxy(t, b1, a2, tamperNth) // dialer -> acceptor
	tamperProxy(t, a2, b1, 0)         // acceptor -> dialer, clean
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	type result struct {
		c   *Conn
		err error
	}
	accCh := make(chan result, 1)
	go func() {
		c, err := Accept(ctx, a1, epriv, inv.Token, testIdentity("device-a", "A"))
		accCh <- result{c, err}
	}()
	dialCh := make(chan result, 1)
	go func() {
		c, err := Dial(ctx, b2, inv, testIdentity("device-b", "B"))
		dialCh <- result{c, err}
	}()
	ar := <-accCh
	dr := <-dialCh
	if ar.err != nil {
		t.Fatalf("accept: %v", ar.err)
	}
	if dr.err != nil {
		t.Fatalf("dial: %v", dr.err)
	}
	return ar.c, dr.c
}

func TestTamperedCiphertextFails(t *testing.T) {
	// Initiator->responder frames: 1=msg1, 2=msg3, 3=token MAC,
	// 4=identity JSON, 5=first application chunk. Tampering the
	// application chunk must fail ChaChaPoly authentication.
	acc, dial := pairWithProxy(t, 5)
	defer acc.Close()
	defer dial.Close()
	writeErr := make(chan error, 1)
	go func() { writeErr <- dial.WriteMsg([]byte("hello")) }()
	if _, err := acc.ReadMsg(); err == nil {
		t.Fatal("tampered ciphertext must fail authentication")
	}
	if err := <-writeErr; err != nil {
		t.Fatalf("write: %v", err)
	}
}

func TestHandshakeAbortedMidway(t *testing.T) {
	// The initiator sends one byte of the first frame and vanishes; the
	// acceptor must fail instead of hanging.
	inv, epriv, err := pairing.Generate("device-a")
	if err != nil {
		t.Fatal(err)
	}
	a, b := net.Pipe()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	errCh := make(chan error, 1)
	go func() {
		_, err := Accept(ctx, a, epriv, inv.Token, testIdentity("device-a", "A"))
		errCh <- err
	}()
	_, _ = b.Write([]byte{0x00})
	_ = b.Close()
	select {
	case err := <-errCh:
		if err == nil {
			t.Fatal("aborted handshake must fail")
		}
	case <-time.After(5 * time.Second):
		t.Fatal("aborted handshake hung")
	}
}

func TestHandshakeRejectsGarbageMessage(t *testing.T) {
	// XX msg1 is a cleartext ephemeral key, so any 32 bytes are
	// structurally valid there; the garbage goes into msg3, where the
	// responder must fail the decrypt.
	inv, epriv, err := pairing.Generate("device-a")
	if err != nil {
		t.Fatal(err)
	}
	a, b := net.Pipe()
	defer a.Close()
	defer b.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	errCh := make(chan error, 1)
	go func() {
		_, err := Accept(ctx, a, epriv, inv.Token, testIdentity("device-a", "A"))
		errCh <- err
	}()
	msg1 := make([]byte, 32)
	if _, err := rand.Read(msg1); err != nil {
		t.Fatal(err)
	}
	if err := writeFrame(b, msg1); err != nil {
		t.Fatal(err)
	}
	if _, err := readFrame(b); err != nil { // msg2 from the acceptor
		t.Fatal(err)
	}
	garbage := make([]byte, 48)
	if _, err := rand.Read(garbage[:]); err != nil {
		t.Fatal(err)
	}
	if err := writeFrame(b, garbage); err != nil { // bogus msg3
		t.Fatal(err)
	}
	select {
	case err := <-errCh:
		if err == nil {
			t.Fatal("garbage handshake message must fail")
		}
	case <-time.After(5 * time.Second):
		t.Fatal("garbage handshake hung")
	}
}

func TestStalledPeerDoesNotHang(t *testing.T) {
	// The responder announces a 64 KiB frame and then stalls (slowloris on
	// the pairing port). The dialer must give up on the context deadline,
	// not on the 30 s handshake timeout.
	inv, _, err := pairing.Generate("device-a")
	if err != nil {
		t.Fatal(err)
	}
	a, b := net.Pipe()
	defer a.Close()
	defer b.Close()
	go func() {
		// Read msg1, then stall: announce a huge frame, send nothing.
		hdr := make([]byte, 2)
		if _, err := io.ReadFull(a, hdr); err != nil {
			return
		}
		l := int(binary.BigEndian.Uint16(hdr))
		if _, err := io.ReadFull(a, make([]byte, l)); err != nil {
			return
		}
		_, _ = a.Write([]byte{0xff, 0xff})
		select {}
	}()
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	start := time.Now()
	_, err = Dial(ctx, b, inv, testIdentity("device-b", "B"))
	elapsed := time.Since(start)
	if err == nil {
		t.Fatal("stalled handshake must fail")
	}
	if elapsed > 10*time.Second {
		t.Fatalf("stalled handshake took %v, wanted ~2s", elapsed)
	}
}

func TestMessageTooLargeRejected(t *testing.T) {
	acc, dial := pairWithProxy(t, 0)
	defer acc.Close()
	defer dial.Close()
	big := make([]byte, 65<<20)
	for i := range big {
		big[i] = byte(i)
	}
	writeErr := make(chan error, 1)
	go func() { writeErr <- dial.WriteMsg(big) }()
	rerr := func() error { _, err := acc.ReadMsg(); return err }()
	// Unblock the writer: it is parked in the synchronous pipe with the
	// tail of the message that no one will read now.
	_ = acc.Close()
	_ = dial.Close()
	if rerr == nil || !strings.Contains(rerr.Error(), "exceeds 64 MiB") {
		t.Fatalf("oversized message must be rejected, got %v", rerr)
	}
	<-writeErr // the writer fails on the closed pipe; just reap it
}

func TestConcurrentBidirectionalTraffic(t *testing.T) {
	acc, dial := pairWithProxy(t, 0)
	defer acc.Close()
	defer dial.Close()
	const n = 100
	readAll := func(c *Conn, want int) map[string]bool {
		got := map[string]bool{}
		for i := 0; i < want; i++ {
			m, err := c.ReadMsg()
			if err != nil {
				t.Errorf("read: %v", err)
				return got
			}
			got[string(m)] = true
		}
		return got
	}
	var wg sync.WaitGroup
	for _, dir := range []struct {
		w, r *Conn
		tag  string
	}{
		{dial, acc, "d2a"},
		{acc, dial, "a2d"},
	} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := 0; i < n; i++ {
				msg := []byte(dir.tag + ":" + strings.Repeat("x", 100) + string(rune(i)))
				if err := dir.w.WriteMsg(msg); err != nil {
					t.Errorf("write: %v", err)
					return
				}
			}
		}()
	}
	gotA := readAll(acc, n)
	gotB := readAll(dial, n)
	wg.Wait()
	for i := 0; i < n; i++ {
		if !gotA["d2a:"+strings.Repeat("x", 100)+string(rune(i))] {
			t.Fatalf("message d2a:%d lost or corrupted", i)
		}
		if !gotB["a2d:"+strings.Repeat("x", 100)+string(rune(i))] {
			t.Fatalf("message a2d:%d lost or corrupted", i)
		}
	}
}

func TestDialRejectsNilInvitation(t *testing.T) {
	a, b := net.Pipe()
	defer b.Close() // b is closed by Dial on the nil path; double close is fine
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if _, err := Dial(ctx, a, nil, testIdentity("device-b", "B")); err == nil {
		t.Fatal("nil invitation must fail, not panic")
	}
	// The connection must be cleaned up, not leaked half-open.
	if _, err := b.Read(make([]byte, 1)); err == nil {
		t.Fatal("connection leaked after nil invitation")
	}
}
