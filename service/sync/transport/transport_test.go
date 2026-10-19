package transport

import (
	"context"
	"crypto/rand"
	"net"
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
