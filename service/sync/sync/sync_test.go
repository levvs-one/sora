package sync

import (
	"context"
	"net"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/sync/pairing"
	"github.com/levvs-one/sora-client/sync/transport"
)

// linkedConns returns a paired initiator/responder transport connection over
// an in-memory pipe.
func linkedConns(t *testing.T) (initiator, responder *transport.Conn) {
	t.Helper()
	inv, epriv, err := pairing.Generate("device-a")
	if err != nil {
		t.Fatal(err)
	}
	a, b := net.Pipe()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	type result struct {
		c   *transport.Conn
		err error
	}
	resCh := make(chan result, 1)
	go func() {
		c, err := transport.Accept(ctx, a, epriv, inv.Token, transport.Identity{DeviceID: "device-a"})
		resCh <- result{c, err}
	}()
	dialCh := make(chan result, 1)
	go func() {
		c, err := transport.Dial(ctx, b, inv, transport.Identity{DeviceID: "device-b"})
		dialCh <- result{c, err}
	}()
	ar := <-resCh
	dr := <-dialCh
	if ar.err != nil || dr.err != nil {
		t.Fatalf("pairing: %v %v", ar.err, dr.err)
	}
	return dr.c, ar.c
}

func putDoc(t *testing.T, s Store, kind, name string, updatedAt int64, payload string) {
	t.Helper()
	changed, err := s.Put(Document{
		Meta:    Meta{Kind: kind, Name: name, UpdatedAt: updatedAt, Hash: HashOf([]byte(payload))},
		Payload: []byte(payload),
		From:    "test",
	})
	if err != nil || !changed {
		t.Fatalf("put %s/%s: changed=%v err=%v", kind, name, changed, err)
	}
}

func TestSyncConverges(t *testing.T) {
	a, err := NewDirStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	b, err := NewDirStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	// A has the newest subscription, B the newest rules; both have an old
	// copy of the other's document.
	putDoc(t, a, "subscription", "main", 200, "sub-v2")
	putDoc(t, b, "subscription", "main", 100, "sub-v1")
	putDoc(t, b, "rules", "custom", 300, "rules-v2")
	putDoc(t, a, "rules", "custom", 100, "rules-v1")

	ic, rc := linkedConns(t)
	defer ic.Close()
	defer rc.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	initDone := make(chan error, 1)
	go func() {
		_, err := Sync(ctx, ic, "device-b", a, true)
		initDone <- err
	}()
	rep, err := Sync(ctx, rc, "device-a", b, false)
	if err != nil {
		t.Fatalf("responder: %v", err)
	}
	if err := <-initDone; err != nil {
		t.Fatalf("initiator: %v", err)
	}
	// Both sides converge on the newest versions.
	for _, s := range []Store{a, b} {
		sub, ok := s.Get("subscription", "main")
		if !ok || string(sub.Payload) != "sub-v2" || sub.UpdatedAt != 200 {
			t.Fatalf("subscription did not converge: %+v", sub)
		}
		rules, ok := s.Get("rules", "custom")
		if !ok || string(rules.Payload) != "rules-v2" || rules.UpdatedAt != 300 {
			t.Fatalf("rules did not converge: %+v", rules)
		}
	}
	if len(rep.Pulled) != 1 || rep.Pulled[0].Name != "main" {
		t.Fatalf("responder should have pulled the subscription, got %+v", rep.Pulled)
	}
}

func TestSyncSkipsEqualDocuments(t *testing.T) {
	a, err := NewDirStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	b, err := NewDirStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	putDoc(t, a, "settings", "ui", 100, "same")
	putDoc(t, b, "settings", "ui", 100, "same")

	ic, rc := linkedConns(t)
	defer ic.Close()
	defer rc.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	initDone := make(chan error, 1)
	var initRep Report
	go func() {
		rep, err := Sync(ctx, ic, "device-b", a, true)
		initRep = rep
		initDone <- err
	}()
	respRep, err := Sync(ctx, rc, "device-a", b, false)
	if err != nil {
		t.Fatal(err)
	}
	if err := <-initDone; err != nil {
		t.Fatal(err)
	}
	if len(initRep.Pulled)+len(initRep.Pushed)+len(respRep.Pulled)+len(respRep.Pushed) != 0 {
		t.Fatalf("equal documents must not move: %+v %+v", initRep, respRep)
	}
}

func TestStoreRejectsUnsafeNames(t *testing.T) {
	s, err := NewDirStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"../evil", "a/b", "", ".", ".."} {
		if _, err := s.Put(Document{Meta: Meta{Kind: "k", Name: name, UpdatedAt: 1}}); err == nil {
			t.Errorf("name %q must be rejected", name)
		}
		if _, ok := s.Get("k", name); ok {
			t.Errorf("name %q must not be readable", name)
		}
	}
}
