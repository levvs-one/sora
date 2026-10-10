package control

import (
	"context"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/subscription"
)

func TestSubscriptionOperationsReachTheFilteredLogWithoutCredentials(t *testing.T) {
	provider := &panel{body: servers("tokyo"), info: subscription.Info{Title: "provider-secret-title"}}
	server, _ := bookServer(t, t.TempDir(), provider)
	center := logs.New(logs.Settings{CaptureLevel: logs.LevelInfo, RecordDestinations: false})
	server.logs = center
	state := saveAndWait(t, server.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/bearer-secret", Name: "private-name"})
	id := state.GetSettings().GetId()
	provider.set("", errs.Newf(errs.CodeUnavailable, errs.KeySubscriptionStatus, "https://panel.example/sub/bearer-secret failed"))
	if _, err := server.subs.refresh(context.Background(), id); err == nil {
		t.Fatal("provider failure was not reported")
	}
	if err := server.subs.delete(id); err != nil {
		t.Fatal(err)
	}
	entries := center.Query(logs.Filter{Sources: []string{"subscription"}}, 0, 20).Entries
	if len(entries) != 6 {
		t.Fatalf("subscription operations produced %d log entries", len(entries))
	}
	for _, entry := range entries {
		for _, secret := range []string{"bearer-secret", "private-name", "provider-secret-title", "panel.example"} {
			if strings.Contains(entry.Message, secret) {
				t.Fatalf("subscription log exposed %s", secret)
			}
		}
	}
	errors := center.Query(logs.Filter{Sources: []string{"subscription"}, MinLevel: logs.LevelError}, 0, 20).Entries
	if len(errors) != 1 || !strings.Contains(errors[0].Message, string(errs.KeySubscriptionStatus)) {
		t.Fatalf("filtered errors = %v", errors)
	}
}
