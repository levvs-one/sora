package guard_test

import (
	"context"
	"errors"
	"testing"

	"github.com/levvs-one/sora-client/core/guard"
	"github.com/levvs-one/sora-client/core/session"
)

// The block hold spans a server switch: Restore under the hold clears
// the guard's ownership but does not disarm the firewall, a re-Apply
// for the replacement session keeps it armed, and releasing the hold
// after that changes nothing. Only the final Restore disarms.
func TestGuardHoldBlockKeepsBlockAcrossRestore(t *testing.T) {
	firewall := &memoryFirewall{}
	system, err := guard.New(testOptions(), firewall)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	settings := session.Settings{KillSwitch: true}
	if err := system.Apply(ctx, settings); err != nil {
		t.Fatal(err)
	}
	release, err := system.HoldBlock(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if err := system.Restore(ctx); err != nil {
		t.Fatal(err)
	}
	if !firewall.armed || firewall.disarms != 0 {
		t.Fatalf("restore under a hold disarmed the block: armed=%v disarms=%d", firewall.armed, firewall.disarms)
	}
	if system.Current().KillSwitch {
		t.Error("restore under a hold must still clear the session's ownership")
	}
	if err := system.Apply(ctx, settings); err != nil {
		t.Fatal(err)
	}
	if err := release(ctx); err != nil {
		t.Fatal(err)
	}
	if !firewall.armed || firewall.disarms != 0 {
		t.Fatalf("releasing the hold dropped a re-applied block: armed=%v disarms=%d", firewall.armed, firewall.disarms)
	}
	if err := system.Restore(ctx); err != nil {
		t.Fatal(err)
	}
	if firewall.armed || firewall.disarms != 1 {
		t.Fatalf("final restore: armed=%v disarms=%d, want disarmed once", firewall.armed, firewall.disarms)
	}
}

// When nothing re-applies the switch while it is held (the switch and
// its rollback both failed), releasing the last hold drops the block so
// a dead switch does not leave the machine blocked forever.
func TestGuardHoldBlockReleaseDropsAnUnreappliedBlock(t *testing.T) {
	firewall := &memoryFirewall{}
	system, err := guard.New(testOptions(), firewall)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	if err := system.Apply(ctx, session.Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	release, err := system.HoldBlock(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if err := system.Restore(ctx); err != nil {
		t.Fatal(err)
	}
	if err := release(ctx); err != nil {
		t.Fatal(err)
	}
	if firewall.armed || firewall.disarms != 1 {
		t.Fatalf("release: armed=%v disarms=%d, want the block dropped once", firewall.armed, firewall.disarms)
	}
	// The release is idempotent: a second call must not disarm again.
	if err := release(ctx); err != nil {
		t.Fatal(err)
	}
	if firewall.disarms != 1 {
		t.Fatalf("second release disarmed again: disarms=%d", firewall.disarms)
	}
}

// A defensive hold taken with nothing applied arms the block for the
// duration of the hold and drops it on release.
func TestGuardHoldBlockArmsWhenNothingApplied(t *testing.T) {
	firewall := &memoryFirewall{}
	system, err := guard.New(testOptions(), firewall)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	release, err := system.HoldBlock(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if !firewall.armed {
		t.Fatal("a hold with nothing applied did not arm the block")
	}
	if err := release(ctx); err != nil {
		t.Fatal(err)
	}
	if firewall.armed {
		t.Fatal("releasing the defensive hold left the block armed")
	}
}

// flakyDisarmFirewall fails Disarm while disarmFailing is set, staging
// a transient firewall refusal ("nftables busy").
type flakyDisarmFirewall struct {
	armed         bool
	disarmCalls   int
	disarmFailing bool
}

func (f *flakyDisarmFirewall) Arm(context.Context, []uint16) error { f.armed = true; return nil }

func (f *flakyDisarmFirewall) Disarm(context.Context) error {
	f.disarmCalls++
	if f.disarmFailing {
		return errors.New("nftables busy")
	}
	f.armed = false
	return nil
}

func (f *flakyDisarmFirewall) Armed(context.Context) (bool, error) { return f.armed, nil }

// Regression (review of the switch/hold change): a failed Disarm
// inside a hold release must be retryable. The release used to
// decrement the hold count before Disarm and cache the outcome
// through a sync.Once, so a transient failure stuck the block armed
// forever: the second release never re-attempted the Disarm and
// Restore was a no-op. Now the state is not finalised on failure, and
// a retry of the same release drops the block.
func TestGuardReleaseDisarmFailureIsRetryable(t *testing.T) {
	fw := &flakyDisarmFirewall{}
	system, err := guard.New(testOptions(), fw)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	if err := system.Apply(ctx, session.Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	release, err := system.HoldBlock(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if err := system.Restore(ctx); err != nil {
		t.Fatal(err)
	}
	fw.disarmFailing = true
	if err := release(ctx); err == nil {
		t.Fatal("release with a failing Disarm returned nil")
	}
	if !fw.armed {
		t.Fatal("the block dropped although its Disarm failed")
	}
	fw.disarmFailing = false
	if err := release(ctx); err != nil {
		t.Fatalf("retrying the failed release: %v", err)
	}
	if fw.armed {
		t.Errorf("block stuck armed after a transient Disarm failure: disarmCalls=%d (no retry ever attempted)", fw.disarmCalls)
	}
	// A successful release is final: another call must not disarm again.
	calls := fw.disarmCalls
	if err := release(ctx); err != nil {
		t.Fatal(err)
	}
	if fw.disarmCalls != calls {
		t.Errorf("a duplicate release after success disarmed again: calls %d -> %d", calls, fw.disarmCalls)
	}
}

// The Restore path is the other retry for a failed hold release: the
// guard keeps the pending disarm, so a Restore after the failure drops
// the block even though a hold count is still outstanding, and the
// original release afterwards is a no-op success.
func TestGuardRestoreRetriesAFailedHoldReleaseDisarm(t *testing.T) {
	fw := &flakyDisarmFirewall{}
	system, err := guard.New(testOptions(), fw)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	if err := system.Apply(ctx, session.Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	release, err := system.HoldBlock(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if err := system.Restore(ctx); err != nil {
		t.Fatal(err)
	}
	fw.disarmFailing = true
	if err := release(ctx); err == nil {
		t.Fatal("release with a failing Disarm returned nil")
	}
	fw.disarmFailing = false
	if err := system.Restore(ctx); err != nil {
		t.Fatalf("Restore retrying the pending disarm: %v", err)
	}
	if fw.armed {
		t.Error("Restore did not retry the disarm a failed hold release left pending")
	}
	calls := fw.disarmCalls
	if err := release(ctx); err != nil {
		t.Fatal(err)
	}
	if fw.disarmCalls != calls {
		t.Errorf("release after the Restore retry disarmed again: calls %d -> %d", calls, fw.disarmCalls)
	}
}

// Regression (review of the switch/hold change): two independent
// holds — releasing the first twice must not consume the second hold,
// and the block must survive until the last real release.
func TestGuardDoubleReleaseDoesNotConsumeAnotherHold(t *testing.T) {
	fw := &flakyDisarmFirewall{}
	system, err := guard.New(testOptions(), fw)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	if err := system.Apply(ctx, session.Settings{KillSwitch: true}); err != nil {
		t.Fatal(err)
	}
	rel1, err := system.HoldBlock(ctx)
	if err != nil {
		t.Fatal(err)
	}
	rel2, err := system.HoldBlock(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if err := system.Restore(ctx); err != nil {
		t.Fatal(err)
	}
	if err := rel1(ctx); err != nil {
		t.Fatal(err)
	}
	if err := rel1(ctx); err != nil { // duplicate release of hold #1
		t.Fatal(err)
	}
	if !fw.armed {
		t.Error("duplicate release of hold #1 dropped the block while hold #2 was still outstanding")
	}
	if err := rel2(ctx); err != nil {
		t.Fatal(err)
	}
	if fw.armed {
		t.Error("block still armed after the last hold was released and nothing re-applied")
	}
}
