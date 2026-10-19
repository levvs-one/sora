package control

import (
	"testing"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/subscription"
)

func overrideSpecs() []*corev1.OutboundSpec {
	return []*corev1.OutboundSpec{
		{Id: "s1", DisplayName: "One"},
		{Id: "s2", DisplayName: "Two"},
		{Id: "s3", DisplayName: "Three"},
	}
}

func TestApplyOverrideNilIsNoop(t *testing.T) {
	in := overrideSpecs()
	if out := applySubscriptionOverride(in, nil); len(out) != 3 {
		t.Fatalf("nil override must pass through, got %d", len(out))
	}
}

func TestApplyOverrideRenameAndHide(t *testing.T) {
	in := overrideSpecs()
	out := applySubscriptionOverride(in, &subscription.Override{
		Renames: map[string]string{"s1": "Home"},
		Hidden:  []string{"s2"},
	})
	if len(out) != 2 {
		t.Fatalf("expected 2 servers, got %d", len(out))
	}
	if out[0].GetId() != "s1" || out[0].GetDisplayName() != "Home" {
		t.Fatalf("rename not applied: %+v", out[0])
	}
	// The stored spec keeps the provider name: clearing the rename
	// restores it.
	if in[0].GetDisplayName() != "One" {
		t.Fatalf("stored spec was mutated: %+v", in[0])
	}
	if len(in) != 3 {
		t.Fatal("input slice length must not change")
	}
}

func TestApplyOverridePinOrder(t *testing.T) {
	in := overrideSpecs()
	out := applySubscriptionOverride(in, &subscription.Override{
		PinnedOrder: []string{"s3", "s1"},
	})
	want := []string{"s3", "s1", "s2"}
	for i, id := range want {
		if out[i].GetId() != id {
			t.Fatalf("position %d: want %s, got %s", i, id, out[i].GetId())
		}
	}
}

func TestApplyOverridePinUnknownIgnored(t *testing.T) {
	in := overrideSpecs()
	out := applySubscriptionOverride(in, &subscription.Override{
		PinnedOrder: []string{"nope", "s2"},
		Hidden:      []string{"s2"},
	})
	// "nope" pins nothing; s2 is hidden, so it stays hidden.
	if len(out) != 2 || out[0].GetId() != "s1" || out[1].GetId() != "s3" {
		t.Fatalf("unexpected order: %v", out)
	}
}

func TestApplyOverrideKeepsProviderNameOnEmptyRename(t *testing.T) {
	in := overrideSpecs()
	out := applySubscriptionOverride(in, &subscription.Override{
		Renames: map[string]string{"s1": ""},
	})
	if out[0].GetDisplayName() != "One" {
		t.Fatalf("empty rename must keep provider name: %+v", out[0])
	}
}
