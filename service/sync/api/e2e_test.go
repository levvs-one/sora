package api

import (
	"context"
	"fmt"
	"net"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/sync/pairing"
	syncpkg "github.com/levvs-one/sora-client/sync/sync"
	"github.com/levvs-one/sora-client/sync/transport"
)

// TestDaemonPairingEndToEnd pairs two daemons over the real pairing path:
// QR generation, TCP dial to the pairing port, Noise handshake, token
// confirmation, and the first sync. mDNS is bypassed (the sandbox has no
// multicast); the port comes from the QR as in production.
func TestDaemonPairingEndToEnd(t *testing.T) {
	a, err := New(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(a.Shutdown)
	b, err := New(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(b.Shutdown)

	// Seed divergent documents.
	seed := func(d *Daemon, kind, name string, at int64, payload string) {
		t.Helper()
		changed, err := d.store.Put(syncpkg.Document{
			Meta:    syncpkg.Meta{Kind: kind, Name: name, UpdatedAt: at, Hash: syncpkg.HashOf([]byte(payload))},
			Payload: []byte(payload),
			From:    d.identity.ID,
		})
		if err != nil || !changed {
			t.Fatalf("seed %s/%s: %v %v", kind, name, changed, err)
		}
	}
	seed(a, "subscription", "main", 200, "sub-from-a")
	seed(b, "rules", "custom", 300, "rules-from-b")

	qr, _, err := a.StartPairing()
	if err != nil {
		t.Fatal(err)
	}
	inv, err := pairing.Decode(qr)
	if err != nil {
		t.Fatal(err)
	}
	self, err := b.transportSelf()
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	netConn, err := (&net.Dialer{}).DialContext(ctx, "tcp", fmt.Sprintf("127.0.0.1:%d", inv.Port))
	if err != nil {
		t.Fatal(err)
	}
	c, err := transport.Dial(ctx, netConn, inv, self)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer c.Close()
	if _, err := syncpkg.Sync(ctx, c, b.identity.ID, b.store, true); err != nil {
		t.Fatalf("sync: %v", err)
	}
	// Give the responder side a moment to finish its sync and upsert.
	deadline := time.Now().Add(5 * time.Second)
	for {
		peers := a.Peers()
		if len(peers) == 1 && peers[0].ID == b.identity.ID {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("a did not pair with b: %+v", peers)
		}
		time.Sleep(50 * time.Millisecond)
	}
	// Documents converged on both sides.
	for _, d := range []*Daemon{a, b} {
		sub, ok := d.store.Get("subscription", "main")
		if !ok || string(sub.Payload) != "sub-from-a" {
			t.Fatalf("subscription did not converge on %s", d.identity.ID)
		}
		rules, ok := d.store.Get("rules", "custom")
		if !ok || string(rules.Payload) != "rules-from-b" {
			t.Fatalf("rules did not converge on %s", d.identity.ID)
		}
	}
}
