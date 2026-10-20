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
