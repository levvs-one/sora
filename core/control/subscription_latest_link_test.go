package control

import (
	"context"
	"encoding/json"
	"errors"
	"slices"
	"strings"
	"sync"
	"testing"
	"testing/synctest"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/subscription"
)

type replacementProvider struct {
	mu          sync.Mutex
	calls       []string
	oldCalls    int
	blockAt     int
	release     <-chan struct{}
	oldError    error
	latestError error
}

func (p *replacementProvider) Fetch(ctx context.Context, reference string, _ subscription.FetchOptions) (subscription.Result, error) {
	name := strings.TrimPrefix(reference, "https://panel.example/")
	p.mu.Lock()
	p.calls = append(p.calls, name)
	block := false
	if name == "old" {
		p.oldCalls++
		block = p.oldCalls == p.blockAt
	}
	p.mu.Unlock()
	if block {
		select {
		case <-p.release:
		case <-ctx.Done():
			return subscription.Result{}, ctx.Err()
		}
		if p.oldError != nil {
			return subscription.Result{}, p.oldError
		}
	}
	if name == "latest" && p.latestError != nil {
		return subscription.Result{}, p.latestError
	}
	return subscription.Result{Body: []byte(servers(name))}, nil
}

func (p *replacementProvider) fetched() []string {
	p.mu.Lock()
	defer p.mu.Unlock()
	return slices.Clone(p.calls)
}

func TestSavedSubscriptionKeepsLatestLinkDuringRefresh(t *testing.T) {
	for _, scenario := range []string{"initial-success", "initial-failure", "cancelled-manual"} {
		t.Run(scenario, func(t *testing.T) {
			synctest.Test(t, func(t *testing.T) {
				release := make(chan struct{})
				p := &replacementProvider{blockAt: 1, release: release}
				if scenario == "initial-failure" {
					p.oldError = errors.New("fixture old request failed")
				}
				if scenario == "cancelled-manual" {
					p.blockAt = 2
				}
				srv, store := bookServer(t, t.TempDir(), p)
				saved, err := srv.subs.save(&corev1.SubscriptionSettings{Url: "https://panel.example/old"})
				if err != nil {
					t.Fatal(err)
				}
				id := saved.GetSettings().GetId()
				synctest.Wait()
				ctx, cancel := context.WithCancel(context.Background())
				defer cancel()
				manual := make(chan error, 1)
				wantCalls := []string{"old", "latest"}
				if scenario == "cancelled-manual" {
					go func() { _, err := srv.subs.refresh(ctx, id); manual <- err }()
					synctest.Wait()
					wantCalls = []string{"old", "old", "latest"}
				}
				for _, name := range []string{"middle", "latest"} {
					if _, err := srv.subs.save(&corev1.SubscriptionSettings{
						Id: id, Url: "https://panel.example/" + name, AutoUpdate: false,
					}); err != nil {
						t.Fatal(err)
					}
				}
				synctest.Wait()
				if got := p.fetched(); !slices.Equal(got, wantCalls[:len(wantCalls)-1]) {
					t.Fatalf("saved-link fetch overlapped the active request: %v", got)
				}
				if scenario == "cancelled-manual" {
					cancel()
				}
				close(release)
				synctest.Wait()
				if scenario == "cancelled-manual" {
					if err := <-manual; err == nil {
						t.Error("superseded manual refresh unexpectedly succeeded")
					}
				}
				if got := p.fetched(); !slices.Equal(got, wantCalls) {
					t.Errorf("fetches = %v, want latest saved intent %v", got, wantCalls)
				}
				state := srv.subs.list()[0]
				if state.GetUpdating() || state.GetLastError() != nil || len(state.GetOutbounds()) != 1 ||
					state.GetOutbounds()[0].GetDisplayName() != "latest" || state.GetSettings().GetAutoUpdate() {
					t.Fatalf("latest manual subscription was not populated: updating=%v servers=%d failure=%v",
						state.GetUpdating(), len(state.GetOutbounds()), state.GetLastError())
				}
				ref := state.GetOutbounds()[0].GetCredentials().GetReference()
				raw, err := store.Get(ref)
				if err != nil {
					t.Fatal(err)
				}
				var credential map[string]string
				if err := json.Unmarshal(raw, &credential); err != nil || credential["user"] != "password-latest" {
					t.Fatalf("latest credentials were not stored: %v", err)
				}
				if refs := store.Refs(); len(refs) != 3 {
					t.Errorf("vault references = %d, want record/list/latest credential only", len(refs))
				}
			})
		})
	}
}

func TestSavedSubscriptionPendingFetchLifecycle(t *testing.T) {
	for _, scenario := range []string{"deleted", "latest-fails", "metadata-only"} {
		t.Run(scenario, func(t *testing.T) {
			synctest.Test(t, func(t *testing.T) {
				release := make(chan struct{})
				p := &replacementProvider{blockAt: 1, release: release}
				if scenario == "latest-fails" {
					p.latestError = errors.New("fixture latest request failed")
				}
				srv, store := bookServer(t, t.TempDir(), p)
				saved, err := srv.subs.save(&corev1.SubscriptionSettings{Url: "https://panel.example/old"})
				if err != nil {
					t.Fatal(err)
				}
				id := saved.GetSettings().GetId()
				synctest.Wait()
				edit := &corev1.SubscriptionSettings{Id: id, Name: "Renamed"}
				if scenario != "metadata-only" {
					edit.Url = "https://panel.example/latest"
				}
				if _, err := srv.subs.save(edit); err != nil {
					t.Fatal(err)
				}
				if scenario == "deleted" {
					if err := srv.subs.delete(id); err != nil {
						t.Fatal(err)
					}
				}
				synctest.Wait()
				close(release)
				synctest.Wait()
				want := []string{"old"}
				if scenario == "latest-fails" {
					want = append(want, "latest")
				}
				if got := p.fetched(); !slices.Equal(got, want) {
					t.Fatalf("fetches = %v, want %v", got, want)
				}
				states := srv.subs.list()
				if scenario == "deleted" {
					if len(states) != 0 || len(store.Refs()) != 0 {
						t.Fatal("deleted subscription was fetched or persisted again")
					}
					return
				}
				state := states[0]
				if state.GetUpdating() || state.GetSettings().GetName() != "Renamed" || state.GetSettings().GetAutoUpdate() {
					t.Fatal("save settings or completed state were lost")
				}
				if scenario == "latest-fails" {
					if state.GetLastError() == nil || len(state.GetOutbounds()) != 0 || len(store.Refs()) != 1 {
						t.Fatal("latest failure did not preserve its failure state and record-only vault")
					}
				} else if state.GetLastError() != nil || len(state.GetOutbounds()) != 1 ||
					state.GetOutbounds()[0].GetDisplayName() != "old" {
					t.Fatal("metadata edit discarded the accepted result")
				}
			})
		})
	}
}
