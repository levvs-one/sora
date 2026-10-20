package guard_test

import (
	"context"
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
