package control

import (
	"bytes"
	"context"
	"testing"
	"testing/synctest"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestSavedSubscriptionFetchStopsWithCoreLifetime(t *testing.T) {
	for _, stage := range []string{"saved-before-run", "saved-during-run", "pending-latest-link"} {
		t.Run(stage, func(t *testing.T) {
			synctest.Test(t, func(t *testing.T) {
				release := make(chan struct{})
				provider := &replacementProvider{blockAt: 1, release: release}
				srv, store := bookServer(t, t.TempDir(), provider)
				ctx, cancel := context.WithCancel(t.Context())
				defer cancel()
				runDone := make(chan struct{})
				run := func() {
					go func() {
						srv.Run(ctx)
						close(runDone)
					}()
					synctest.Wait()
				}
				if stage != "saved-before-run" {
					run()
				}
				state, err := srv.subs.save(&corev1.SubscriptionSettings{Url: "https://panel.example/old"})
				if err != nil {
					t.Fatal(err)
				}
				id := state.GetSettings().GetId()
				synctest.Wait()
				if got := provider.fetched(); len(got) != 1 || got[0] != "old" {
					t.Fatalf("live core did not admit the saved fetch: %v", got)
				}
				if !srv.subs.list()[0].GetUpdating() {
					t.Fatal("positive control never entered the provider")
				}
				if stage == "pending-latest-link" {
					if _, err := srv.subs.save(&corev1.SubscriptionSettings{
						Id: id, Url: "https://panel.example/latest",
					}); err != nil {
						t.Fatal(err)
					}
				}
				before := map[string][]byte{}
				for _, ref := range store.Refs() {
					raw, err := store.Get(ref)
					if err != nil {
						t.Fatal(err)
					}
					before[ref] = raw
				}
				if stage == "saved-before-run" {
					run()
				}
				cancel()
				<-runDone
				synctest.Wait()
				stopped := srv.subs.list()[0]
				if stopped.GetUpdating() {
					t.Error("saved fetch outlived the cancelled core lifetime")
				}
				if stopped.GetLastError() != nil {
					t.Error("shutdown was recorded as a provider failure")
				}
				// A late successful provider must not persist data or start the
				// queued saved-link replacement after the core has stopped.
				close(release)
				synctest.Wait()
				if got := provider.fetched(); len(got) != 1 {
					t.Errorf("shutdown launched another saved fetch: %v", got)
				}
				if len(store.Refs()) != len(before) {
					t.Error("shutdown changed the vault reference set")
				}
				for ref, want := range before {
					got, err := store.Get(ref)
					if err != nil || !bytes.Equal(got, want) {
						t.Error("late saved fetch changed the stored record/list/credentials")
					}
				}
				if after := srv.subs.list()[0]; after.GetUpdating() || after.GetLastError() != nil || len(after.GetOutbounds()) != 0 {
					t.Error("shutdown retained work or published a late result/failure")
				}
			})
		})
	}
}

func TestSavedSubscriptionDiscardsLateSuccessAfterCoreStop(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		release := make(chan struct{})
		defer func() {
			if release != nil {
				close(release)
			}
		}()
		provider := &panel{body: servers("late"), release: release}
		srv, store := bookServer(t, t.TempDir(), provider)
		ctx, cancel := context.WithCancel(t.Context())
		defer cancel()
		runDone := make(chan struct{})
		go func() {
			srv.Run(ctx)
			close(runDone)
		}()
		state, err := srv.subs.save(&corev1.SubscriptionSettings{Url: "https://panel.example/late"})
		if err != nil {
			t.Fatal(err)
		}
		id := state.GetSettings().GetId()
		synctest.Wait()
		if provider.calls.Load() != 1 {
			t.Fatal("positive control never entered the provider")
		}
		before, err := store.Get(recordRef(id))
		if err != nil {
			t.Fatal(err)
		}
		cancel()
		<-runDone
		// This fake deliberately ignores ctx.Done and returns valid data late.
		close(release)
		release = nil
		synctest.Wait()
		after, err := store.Get(recordRef(id))
		if err != nil || !bytes.Equal(before, after) || len(store.Refs()) != 1 {
			t.Error("late successful saved fetch replaced data after core cancellation")
		}
		got := srv.subs.list()[0]
		if got.GetUpdating() || got.GetLastError() != nil || len(got.GetOutbounds()) != 0 {
			t.Error("late successful saved fetch published results or provider failure after core cancellation")
		}
	})
}
