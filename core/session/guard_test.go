package session

import (
	"context"
	"errors"
	"testing"
)

func TestCompositeGuardRetriesEveryOwnedPartAfterRestorationFailure(t *testing.T) {
	first, last := &fakeGuard{}, &fakeGuard{}
	guard := NewCompositeGuard(first, last)
	ctx := context.Background()
	if err := guard.Apply(ctx, Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	last.restoreEr = errors.New("temporary firewall error")
	if err := guard.Restore(ctx); err == nil {
		t.Fatal("restoration failure was hidden")
	}
	if first.Current().KillSwitch || !last.Current().KillSwitch {
		t.Fatal("failed part or remaining cleanup was lost")
	}
	last.restoreEr = nil
	if err := guard.Restore(ctx); err != nil {
		t.Fatal(err)
	}
	if last.Current().KillSwitch {
		t.Fatal("retry did not release the failed part")
	}
}

func TestPartialApplyKeepsOwnershipWhenRollbackFails(t *testing.T) {
	first := &fakeGuard{restoreEr: errors.New("rollback failed")}
	last := &fakeGuard{applyErr: errors.New("proxy apply failed")}
	guard := NewCompositeGuard(first, last)
	ctx := context.Background()
	manager, _ := testManager(t, guard)
	if _, err := manager.Connect(ctx, testPlan("partial"), Settings{KillSwitch: true}); err == nil {
		t.Fatal("partial failure was hidden")
	}
	if manager.Current() == nil || !first.Current().KillSwitch {
		t.Fatal("partial guard apply lost cleanup ownership")
	}
	first.restoreEr = nil
	if err := manager.Disconnect(ctx); err != nil {
		t.Fatal(err)
	}
	if first.Current().KillSwitch {
		t.Fatal("retry did not restore partially applied settings")
	}
}

// TestCompositeGuardBlockedReportsAnyPart: a block owned by any part
// still blocks traffic, and a probe failure stays unknown instead of a
// guessed answer.
func TestCompositeGuardBlockedReportsAnyPart(t *testing.T) {
	first, last := &fakeGuard{}, &fakeGuard{}
	guard := NewCompositeGuard(first, last)
	ctx := context.Background()
	last.blocked = true
	blocked, err := guard.Blocked(ctx)
	if err != nil || !blocked {
		t.Fatalf("Blocked() = %v, %v, want true from the blocked part", blocked, err)
	}
	last.blocked = false
	last.blockedErr = errors.New("probe failed")
	if _, err := guard.Blocked(ctx); err == nil {
		t.Fatal("a probe failure was hidden")
	}
	if blocked, err := (NoopGuard{}).Blocked(ctx); err != nil || blocked {
		t.Fatalf("NoopGuard.Blocked() = %v, %v, want false", blocked, err)
	}
}

// flakyHoldGuard is a BlockHolder whose release fails its first
// attempt, staging a transient disarm failure in one composite part.
type flakyHoldGuard struct {
	fakeGuard
	attempts int
	released int
}

func (g *flakyHoldGuard) HoldBlock(context.Context) (func(context.Context) error, error) {
	return func(context.Context) error {
		g.attempts++
		if g.attempts == 1 {
			return errors.New("nftables busy")
		}
		g.released++
		return nil
	}, nil
}

// The composite release must be retryable the way its parts are: it
// used to cache the joined result through a sync.Once, so one part's
// transient failure made every composite retry return the cached
// error without ever re-calling the failed part.
func TestCompositeHoldReleaseRetriesAFailedPart(t *testing.T) {
	part := &flakyHoldGuard{}
	guard := NewCompositeGuard(part, &fakeGuard{})
	release, err := guard.(BlockHolder).HoldBlock(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if err := release(context.Background()); err == nil {
		t.Fatal("the part's failure was hidden by the composite release")
	}
	if err := release(context.Background()); err != nil {
		t.Fatalf("retrying the composite release: %v", err)
	}
	if part.released != 1 {
		t.Errorf("the failed part was released %d times, want 1 (its failure was never retried)", part.released)
	}
	// Success is final: a duplicate release must not call the part again.
	attempts := part.attempts
	if err := release(context.Background()); err != nil {
		t.Fatal(err)
	}
	if part.attempts != attempts {
		t.Error("a duplicate composite release after success re-called the part")
	}
}
