package control

import (
	"context"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestSubscriptionFailureAgeSurvivesRestartAndClearsOnRecovery(t *testing.T) {
	dir := t.TempDir()
	provider := &panel{body: servers("test")}
	srv, store := bookServer(t, dir, provider)
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/test"})
	id := state.GetSettings().GetId()
	first := time.Date(2026, 10, 10, 12, 0, 0, 0, time.UTC)
	srv.subs.now = func() time.Time { return first }
	provider.set("", errs.New(errs.CodeTimeout, errs.KeyNetworkTimeout, nil))
	state, err := srv.subs.refresh(context.Background(), id)
	if err == nil || !state.GetFailureSince().AsTime().Equal(first) {
		t.Fatalf("failure streak did not start: %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatal(err)
	}
	restarted, _ := bookServer(t, dir, provider)
	restarted.subs.now = func() time.Time { return first.Add(25 * time.Hour) }
	state, err = restarted.subs.refresh(context.Background(), id)
	if err == nil || !state.GetFailureSince().AsTime().Equal(first) {
		t.Fatalf("restart or repeat reset failure age: %v", err)
	}
	provider.set(servers("test"), nil)
	state, err = restarted.subs.refresh(context.Background(), id)
	if err != nil || state.GetFailureSince() != nil || state.GetLastError() != nil {
		t.Fatalf("recovery left stale failure state: %v", err)
	}
}
