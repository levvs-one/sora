package control

import (
	"testing"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// TestResolveBenchmarkServersSemantics pins the contract the inverted
// index must preserve from the old full-book index: results follow
// request order, duplicate ids are answered per occurrence, unknown ids
// land in missing in request order, and when two lists carry the same
// id the later list's spec wins.
func TestResolveBenchmarkServersSemantics(t *testing.T) {
	first := &corev1.OutboundSpec{Id: "srv-1", DisplayName: "first"}
	second := &corev1.OutboundSpec{Id: "srv-1", DisplayName: "second"}
	other := &corev1.OutboundSpec{Id: "srv-2", DisplayName: "other"}
	srv := &Server{subs: &subscriptionBook{lists: map[string][]*corev1.OutboundSpec{
		"a": {first, other},
		"b": {second},
	}}}

	found, missing := srv.resolveBenchmarkServers([]string{"srv-2", "gone", "srv-1", "srv-1", "gone"})
	if len(found) != 3 || len(missing) != 2 {
		t.Fatalf("found %d, missing %d; want 3 and 2", len(found), len(missing))
	}
	if found[0] != other {
		t.Fatalf("found[0] = %v, want the srv-2 spec", found[0].GetDisplayName())
	}
	if found[1] != second || found[2] != second {
		t.Fatalf("duplicate srv-1 resolved to %q/%q, want the later list's spec both times",
			found[1].GetDisplayName(), found[2].GetDisplayName())
	}
	if missing[0] != "gone" || missing[1] != "gone" {
		t.Fatalf("missing = %v, want [gone gone]", missing)
	}
}

// TestResolveBenchmarkServersAfterRestartBeforeAnyStateSnapshot is the
// regression test for the lazy-list startup (69535742): after a restart
// every stored list sits in pendingLists, unparsed, until the first
// state snapshot. A BenchmarkServers RPC that arrives before any
// snapshot must still find the stored servers — resolveBenchmarkServers
// has to force the pending parses itself (ensureListsLocked), exactly
// like subscriptionsOf does, instead of scanning the still-empty
// lists map and reporting every saved server as unknown.
func TestResolveBenchmarkServersAfterRestartBeforeAnyStateSnapshot(t *testing.T) {
	dir := t.TempDir()
	srv, store := bookServer(t, dir, &panel{body: servers("tokyo", "berlin")})
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/abc"})
	subID := state.GetSettings().GetId()
	outbounds := state.GetOutbounds()
	if len(outbounds) != 2 {
		t.Fatalf("saved subscription has %d servers, want 2", len(outbounds))
	}
	ids := []string{outbounds[0].GetId(), outbounds[1].GetId()}
	_ = store.Close()

	restarted, _ := bookServer(t, dir, &panel{body: servers("unused")})

	// Precondition: the restarted book has not parsed the list yet — no
	// state snapshot, list, or refresh has been requested from it.
	restarted.subs.mu.Lock()
	pending := restarted.subs.pendingLists[subID]
	_, parsed := restarted.subs.lists[subID]
	restarted.subs.mu.Unlock()
	if !pending || parsed {
		t.Fatalf("precondition broken: pending=%v parsed=%v, want the list still pending and unparsed", pending, parsed)
	}

	// Resolve before any state request, in reverse storage order so the
	// result order also proves answers follow the request, not the list.
	found, missing := restarted.resolveBenchmarkServers([]string{ids[1], ids[0]})
	if len(missing) != 0 {
		t.Fatalf("missing = %v, want none: stored servers must resolve from the pending list", missing)
	}
	if len(found) != 2 || found[0].GetId() != ids[1] || found[1].GetId() != ids[0] {
		t.Fatalf("found = %v, want the two stored servers in request order", found)
	}
}
