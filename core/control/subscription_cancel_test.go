package control

import (
	"bytes"
	"context"
	"errors"
	"testing"
	"testing/synctest"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestCancelledRefreshPreservesVaultAndCanRetry(t *testing.T) {
	for _, stage := range []string{"already cancelled", "already expired", "response after cancellation"} {
		t.Run(stage, func(t *testing.T) {
			provider := &panel{body: servers("retained")}
			srv, store := bookServer(t, t.TempDir(), provider)
			state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/cancel"})
			id := state.GetSettings().GetId()
			before := map[string][]byte{}
			for _, ref := range store.Refs() {
				raw, err := store.Get(ref)
				if err != nil {
					t.Fatal(err)
				}
				before[ref] = raw
			}
			provider.set(servers("replacement"), nil)
			provider.calls.Store(0)
			var ctx context.Context
			var cancel context.CancelFunc
			if stage == "already expired" {
				ctx, cancel = context.WithDeadline(t.Context(), time.Now().Add(-time.Second))
			} else {
				ctx, cancel = context.WithCancel(t.Context())
			}
			defer cancel()
			if stage == "response after cancellation" {
				provider.release = make(chan struct{})
				done := make(chan error, 1)
				go func() { _, err := srv.subs.refresh(ctx, id); done <- err }()
				deadline := time.Now().Add(5 * time.Second)
				for provider.calls.Load() == 0 && time.Now().Before(deadline) {
					time.Sleep(time.Millisecond)
				}
				cancel()
				close(provider.release)
				if provider.calls.Load() == 0 {
					t.Fatal("fixture fetch was never entered")
				}
				if err := <-done; !errors.Is(err, context.Canceled) {
					t.Errorf("cancelled response was accepted: %v", err)
				}
			} else {
				cancel()
				_, err := srv.subs.refresh(ctx, id)
				want := context.Canceled
				if stage == "already expired" {
					want = context.DeadlineExceeded
				}
				if !errors.Is(err, want) {
					t.Errorf("cancelled refresh was accepted: %v", err)
				}
				if calls := provider.calls.Load(); calls != 0 {
					t.Errorf("cancelled refresh fetched %d times", calls)
				}
			}
			if refs := store.Refs(); len(refs) != len(before) {
				t.Error("cancelled refresh changed the reference set")
			}
			for ref, want := range before {
				got, err := store.Get(ref)
				if err != nil || !bytes.Equal(got, want) {
					t.Error("cancelled refresh changed retained record/list/credentials")
				}
			}
			if srv.subs.updating[id] {
				t.Error("cancelled refresh kept the updating slot")
			}
			provider.release = nil
			after, err := srv.subs.refresh(t.Context(), id)
			if err != nil || len(after.GetOutbounds()) != 1 || after.GetOutbounds()[0].GetDisplayName() != "replacement" {
				t.Fatalf("valid retry failed: %v", err)
			}
		})
	}
}

func TestRefreshOwnFetchDeadlineStillRecordsFailureAndBackoff(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		provider := &panel{body: servers("retained")}
		srv, _ := bookServer(t, t.TempDir(), provider)
		state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/timeout", AutoUpdate: true})
		id := state.GetSettings().GetId()
		provider.set(servers("replacement"), nil)
		provider.release = make(chan struct{})
		go func() {
			time.Sleep(subscriptionFetchLimit + time.Second)
			close(provider.release)
		}()
		state, err := srv.subs.refresh(t.Context(), id)
		if !errors.Is(err, context.DeadlineExceeded) || t.Context().Err() != nil {
			t.Fatalf("expected only the book's own deadline: %v", err)
		}
		if len(state.GetOutbounds()) != 1 || state.GetOutbounds()[0].GetDisplayName() != "retained" {
			t.Fatal("own fetch timeout replaced the last working list")
		}
		rec := srv.subs.records[id]
		if rec.Failures != 1 || rec.LastError == nil || srv.subs.updating[id] {
			t.Fatal("own fetch timeout lost failure bookkeeping or its updating slot")
		}
		if next := srv.subs.nextUpdate(rec); !next.After(time.Now()) {
			t.Fatal("own fetch timeout discarded retry backoff")
		}
	})
}
