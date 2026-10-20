package control

// Provider routing (C3): a subscription whose fetch carried a Happ
// happRouting payload gets the converted rules stored in its
// override file's provider layer. Refreshes replace the layer
// wholesale, a payload that stops arriving clears it, and deleting
// the subscription deletes the file as before — while user edits in
// the same file (renames, hides, pins, extra rules) are preserved
// untouched, because the layer is replaced by field, never by file.

import (
	"fmt"

	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/subscription"
)

// applyProviderRoutingLocked folds one fetch's happRouting payload
// into the subscription's stored provider layer. Callers hold b.mu.
// A payload that fails to decode keeps the previous layer: a
// provider's broken update must not wipe working rules, and the
// failure is logged instead of failing the refresh that already
// delivered new servers.
func (b *subscriptionBook) applyProviderRoutingLocked(id, payload string) {
	if b.overrides == nil {
		return
	}
	existing := b.loadOverride(id)
	if payload == "" {
		if existing.ProviderRouting == nil {
			return
		}
		existing.ProviderRouting = nil
		if err := b.overrides.Save(id, existing); err != nil {
			b.logRoutingLocked(id, logs.LevelWarning, "provider routing cleanup failed: "+err.Error())
			return
		}
		b.logRoutingLocked(id, logs.LevelInfo, "provider routing removed: the subscription no longer carries it")
		return
	}
	provider, err := subscription.ProviderRoutingFromPayload(payload)
	if err != nil {
		b.logRoutingLocked(id, logs.LevelWarning, "provider routing ignored: the payload is not a valid Happ routing profile")
		return
	}
	existing.ProviderRouting = provider
	if err := b.overrides.Save(id, existing); err != nil {
		b.logRoutingLocked(id, logs.LevelWarning, "provider routing store failed: "+err.Error())
		return
	}
	b.logRoutingLocked(id, logs.LevelInfo, fmt.Sprintf("provider routing updated: %d rules from %q", len(provider.Rules), provider.Name))
}

func (b *subscriptionBook) logRoutingLocked(id string, level logs.Level, message string) {
	if b.srv.logs != nil {
		b.srv.logs.Write(b.now(), level, logs.SourceSubscription, message+" id="+id)
	}
}
