package control

import "time"

// Expedited subscription refresh (T042).
//
// During a block wave the provider rotates endpoints (IPs, domains, SNI
// variants) and the client's hourly schedule is too slow: the user sits
// on a dead list for up to an hour. ExpediteUpdate lets a failure signal
// (dead active server, user report, wave detector) pull the next refresh
// forward without touching the regular cadence or hammering the
// provider: one expedited refresh per cooldown per subscription, never
// overlapping a running fetch, and the stored server list is still
// replaced atomically (see applyUpdateLocked).

// expediteCooldown bounds expedited refreshes: a block wave is not an
// excuse to DDoS the provider.
const expediteCooldown = 15 * time.Minute

// ExpediteUpdate schedules the next refresh of id as soon as possible.
// It returns false when there is nothing to expedite (unknown id, a
// fetch already running) or when the cooldown has not elapsed since the
// last expedited refresh. The trigger wiring (health signal, UI action)
// lives outside the core; this only shortens the wait.
func (b *subscriptionBook) ExpediteUpdate(id string) bool {
	b.mu.Lock()
	defer b.mu.Unlock()
	if _, ok := b.records[id]; !ok || b.updating[id] {
		return false
	}
	now := b.now()
	if last, ok := b.expediteLast[id]; ok && now.Sub(last) < expediteCooldown {
		return false
	}
	b.expedited[id] = now
	b.expediteLast[id] = now
	b.poke()
	return true
}

// expeditedDue reports whether id has a pending expedited refresh that
// beats the regular schedule.
func (b *subscriptionBook) expeditedDue(rec *subscriptionRecord, at time.Time) time.Time {
	if exp, ok := b.expedited[rec.ID]; ok && (at.IsZero() || exp.Before(at)) {
		return exp
	}
	return at
}

// subscriptionsOf returns the ids of subscriptions whose last known server
// list contains serverID. It is the T042 reverse lookup: a censorship
// verdict names the failed server, and the expedited refresh must pull
// the provider list that owns it — not every subscription. (rec.Servers
// holds secret-store refs, not server ids; the ids live on the parsed
// OutboundSpecs in lists.)
func (b *subscriptionBook) subscriptionsOf(serverID string) []string {
	if serverID == "" {
		return nil
	}
	b.mu.Lock()
	defer b.mu.Unlock()
	b.ensureListsLocked()
	var out []string
	for id, list := range b.lists {
		for _, ob := range list {
			if ob.GetId() == serverID {
				out = append(out, id)
				break
			}
		}
	}
	return out
}
