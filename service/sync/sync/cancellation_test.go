package sync

import (
	"context"
	"testing"
	"time"
)

func TestSyncBlockedWriteHonorsContext(t *testing.T) {
	for _, mode := range []string{"timeout", "cancel"} {
		t.Run(mode, func(t *testing.T) {
			ic, rc := linkedConns(t)
			defer func() { _ = ic.Close(); _ = rc.Close() }()
			store, err := NewDirStore(t.TempDir())
			if err != nil {
				t.Fatal(err)
			}
			var ctx context.Context
			var cancel context.CancelFunc
			if mode == "timeout" {
				ctx, cancel = context.WithTimeout(context.Background(), 50*time.Millisecond)
			} else {
				ctx, cancel = context.WithCancel(context.Background())
			}
			defer cancel()
			done := make(chan error, 1)
			go func() { _, err := Sync(ctx, ic, "sender", store, true); done <- err }()
			if mode == "cancel" {
				cancel()
			}
			select {
			case err := <-done:
				if err == nil {
					t.Fatal("blocked exchange succeeded")
				}
			case <-time.After(time.Second):
				_ = rc.Close()
				<-done
				t.Fatal("blocked write ignored context")
			}
		})
	}
}

func TestSyncBlockedDocumentWriteHonorsCancellation(t *testing.T) {
	ic, rc := linkedConns(t)
	defer func() { _ = ic.Close(); _ = rc.Close() }()
	store, err := NewDirStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	payload := make([]byte, 1<<20)
	if _, err := store.Put(Document{Meta: Meta{Kind: "settings", Name: "large", UpdatedAt: 1, Hash: HashOf(payload)}, Payload: payload}); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	done := make(chan error, 1)
	go func() { _, err := Sync(ctx, rc, "responder", store, false); done <- err }()
	peer := &session{conn: ic}
	for _, frame := range []message{{T: "hello", Device: "requester"}, {T: "inv"}} {
		if err := peer.send(frame); err != nil {
			t.Fatal(err)
		}
		if _, err := peer.recv(context.Background()); err != nil {
			t.Fatal(err)
		}
	}
	if err := peer.send(message{T: "get", Kind: "settings", DocName: "large"}); err != nil {
		t.Fatal(err)
	}
	cancel()
	select {
	case err := <-done:
		if err == nil {
			t.Fatal("blocked document write succeeded")
		}
	case <-time.After(time.Second):
		_ = ic.Close()
		<-done
		t.Fatal("document write ignored cancellation")
	}
}
