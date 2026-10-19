package control

import (
	"context"
	"testing"
	"time"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// TestExpediteUpdate: during a block wave the hourly schedule is too
// slow; an explicit signal must pull the next refresh forward, at most
// once per cooldown, without overlapping a running fetch.
func TestExpediteUpdate(t *testing.T) {
	p := &panel{body: servers("a", "b")}
	srv, _ := bookServer(t, t.TempDir(), p)
	b := srv.subs
	now := time.Now()
	b.now = func() time.Time { return now }

	state := saveAndWait(t, b, &corev1.SubscriptionSettings{
		Url: "https://panel.example/sub/abc", AutoUpdate: true,
	})
	id := state.GetSettings().GetId()
	rec := b.records[id]

	// Sanity: without expedite the next update is a day away.
	if at := b.nextUpdate(rec); at.Sub(now) < 23*time.Hour {
		t.Fatalf("nextUpdate without expedite = %v, want ~24h away", at.Sub(now))
	}

	// Unknown ids and double-expedites are rejected.
	if b.ExpediteUpdate("no-such-id") {
		t.Error("ExpediteUpdate(unknown) = true, want false")
	}
	if !b.ExpediteUpdate(id) {
		t.Fatal("first ExpediteUpdate = false, want true")
	}
	if b.ExpediteUpdate(id) {
		t.Error("second ExpediteUpdate within cooldown = true, want false")
	}

	// The refresh is now due immediately.
	if at := b.nextUpdate(rec); at.After(now.Add(time.Minute)) {
		t.Errorf("nextUpdate after expedite = %v, want due now", at.Sub(now))
	}

	// Serve the refresh: the pending marker clears, the cooldown holds.
	if _, err := b.refresh(context.Background(), id); err != nil {
		t.Fatalf("refresh: %v", err)
	}
	if _, ok := b.expedited[id]; ok {
		t.Error("expedited marker must clear after the refresh runs")
	}
	if b.ExpediteUpdate(id) {
		t.Error("ExpediteUpdate right after a served expedite = true, want false (cooldown)")
	}

	// After the cooldown a new expedite is allowed.
	now = now.Add(expediteCooldown + time.Minute)
	if !b.ExpediteUpdate(id) {
		t.Error("ExpediteUpdate after cooldown = false, want true")
	}
	if at := b.nextUpdate(rec); at.After(now.Add(time.Minute)) {
		t.Errorf("nextUpdate after second expedite = %v, want due now", at.Sub(now))
	}
}

// TestExpediteUpdateWhileFetching: never overlap a running fetch.
func TestExpediteUpdateWhileFetching(t *testing.T) {
	p := &panel{body: servers("a"), release: make(chan struct{})}
	srv, _ := bookServer(t, t.TempDir(), p)
	b := srv.subs

	// Start a fetch and hold it inside the fetcher.
	state, err := b.save(&corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc", AutoUpdate: true})
	if err != nil {
		t.Fatal(err)
	}
	id := state.GetSettings().GetId()
	deadline := time.Now().Add(5 * time.Second)
	for {
		b.mu.Lock()
		updating := b.updating[id]
		b.mu.Unlock()
		if updating || time.Now().After(deadline) {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}
	if b.ExpediteUpdate(id) {
		t.Error("ExpediteUpdate during a running fetch = true, want false")
	}
	close(p.release)
}
