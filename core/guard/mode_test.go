package guard_test

import (
	"context"
	"os"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/guard"
	"github.com/levvs-one/sora-client/core/session"
)

func TestParseModeRoundTrip(t *testing.T) {
	for _, name := range []string{"off", "standard", "strict"} {
		mode, err := guard.ParseMode(name)
		if err != nil {
			t.Fatalf("ParseMode(%q) error = %v", name, err)
		}
		if mode.String() != name {
			t.Errorf("Mode.String() = %q, want %q", mode.String(), name)
		}
	}
	// Config-facing parsing tolerates case and whitespace.
	if mode, err := guard.ParseMode("  STRICT "); err != nil || mode != guard.ModeStrict {
		t.Errorf("ParseMode(\"  STRICT \") = %v, %v", mode, err)
	}
}

func TestParseModeRejectsTypos(t *testing.T) {
	// A typo must fail closed: it can never silently pick a weaker mode.
	for _, name := range []string{"stric", "standart", "always", "", "on"} {
		if mode, err := guard.ParseMode(name); err == nil {
			t.Errorf("ParseMode(%q) = %v, want an error", name, mode)
		} else if errs.CodeOf(err) != errs.CodeInvalidArgument {
			t.Errorf("ParseMode(%q) code = %v, want invalid argument", name, errs.CodeOf(err))
		}
	}
}

func TestNewRejectsStrictWithoutStateDir(t *testing.T) {
	if _, err := guard.New(guard.Options{EnginePorts: []uint16{7890}, Mode: guard.ModeStrict}, nil); err == nil {
		t.Fatal("New() accepted strict mode without a state directory; the marker could not survive a reboot")
	}
}

func TestNewRejectsUnknownMode(t *testing.T) {
	if _, err := guard.New(guard.Options{EnginePorts: []uint16{7890}, Mode: guard.Mode(42)}, nil); err == nil {
		t.Fatal("New() accepted an unknown kill-switch mode")
	}
}

func TestOffRefusesToArm(t *testing.T) {
	firewall := &memoryFirewall{}
	system, err := guard.New(guard.Options{EnginePorts: []uint16{7890}, Mode: guard.ModeOff}, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	// Asking for the kill switch while it is off must fail loudly, not
	// report a block that is not there.
	if err := system.Apply(context.Background(), session.Settings{KillSwitch: true}); err == nil {
		t.Fatal("Apply() with KillSwitch=true succeeded in ModeOff")
	}
	if firewall.arms != 0 || firewall.armed {
		t.Errorf("ModeOff armed the firewall: %+v", firewall)
	}
	if system.Current().KillSwitch {
		t.Error("Current() reports a kill switch that was refused")
	}
	if err := system.Apply(context.Background(), session.Settings{}); err != nil {
		t.Errorf("Apply() without the switch in ModeOff error = %v", err)
	}
}

// strictSystem builds a strict-mode guard over a memory firewall with a
// fresh state directory.
func strictSystem(t *testing.T, firewall *memoryFirewall) (*guard.Guard, string) {
	t.Helper()
	stateDir := t.TempDir()
	system, err := guard.New(guard.Options{
		EnginePorts: []uint16{7890},
		Mode:        guard.ModeStrict,
		StateDir:    stateDir,
	}, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	return system, stateDir
}

func markerExists(stateDir string) bool {
	entries, err := os.ReadDir(stateDir)
	if err != nil {
		return false
	}
	for _, entry := range entries {
		if entry.Name() == "killswitch.strict" {
			return true
		}
	}
	return false
}

// TestStrictPersistsAcrossACrash is the core strict promise: arming writes
// a marker, and a fresh guard (as after a crash or a reboot) picks the
// intent back up, re-arms, and never reports the traffic as open.
func TestStrictPersistsAcrossACrash(t *testing.T) {
	firewall := &memoryFirewall{}
	system, stateDir := strictSystem(t, firewall)
	ctx := context.Background()

	if err := system.Apply(ctx, session.Settings{KillSwitch: true}); err != nil {
		t.Fatalf("Apply() error = %v", err)
	}
	if !firewall.armed || !markerExists(stateDir) {
		t.Fatalf("strict arm: armed=%v marker=%v", firewall.armed, markerExists(stateDir))
	}

	// The crash: a new guard with no memory of the old one.
	crashed := &memoryFirewall{}
	after, err := guard.New(guard.Options{
		EnginePorts: []uint16{7890},
		Mode:        guard.ModeStrict,
		StateDir:    stateDir,
	}, crashed)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if !after.StrictWanted() {
		t.Fatal("StrictWanted() = false after a crash with the marker present")
	}
	if !after.Current().KillSwitch {
		t.Error("Current() claims the traffic is open while the strict marker survives")
	}
	if blocked, err := after.Blocked(ctx); err != nil || blocked {
		t.Errorf("Blocked() = %v, %v with nothing armed in the new process", blocked, err)
	}
	// Startup recovery re-arms from the marker (idempotent: one Arm).
	if err := after.Recover(ctx); err != nil {
		t.Fatalf("Recover() error = %v", err)
	}
	if crashed.arms != 1 || !crashed.armed {
		t.Errorf("Recover() did not re-arm: %+v", crashed)
	}
	if blocked, err := after.Blocked(ctx); err != nil || !blocked {
		t.Errorf("Blocked() = %v, %v after Recover", blocked, err)
	}
	// A clean exit must not lift a strict block either.
	if err := after.Restore(ctx); err != nil {
		t.Fatalf("Restore() error = %v", err)
	}
	if !crashed.armed || !markerExists(stateDir) {
		t.Errorf("Restore() lifted a strict block: armed=%v marker=%v", crashed.armed, markerExists(stateDir))
	}
}

// TestStrictExplicitOffDisarmsAndClearsTheMarker locks the only way out of
// strict mode: an explicit Apply with the switch off.
func TestStrictExplicitOffDisarmsAndClearsTheMarker(t *testing.T) {
	firewall := &memoryFirewall{}
	system, stateDir := strictSystem(t, firewall)
	ctx := context.Background()

	if err := system.Apply(ctx, session.Settings{KillSwitch: true}); err != nil {
		t.Fatalf("Apply() error = %v", err)
	}
	if err := system.Apply(ctx, session.Settings{}); err != nil {
		t.Fatalf("Apply() without the switch error = %v", err)
	}
	if firewall.armed || firewall.disarms != 1 {
		t.Errorf("after explicit off: armed=%v disarms=%d", firewall.armed, firewall.disarms)
	}
	if markerExists(stateDir) {
		t.Error("the strict marker survived an explicit off; the next Recover would re-arm behind the user's back")
	}
	if system.StrictWanted() {
		t.Error("StrictWanted() = true after an explicit off")
	}
	if system.Current().KillSwitch {
		t.Error("Current() still reports the switch after an explicit off")
	}
}

// TestStrictMarkerWriteFailureRollsBackArming: when the intent cannot be
// recorded, the block must not stay up unrecorded — a crash would then
// lose it silently. The Arm is rolled back and the error reported.
func TestStrictMarkerWriteFailureRollsBackArming(t *testing.T) {
	firewall := &memoryFirewall{}
	blocker := t.TempDir() + "/not-a-dir"
	if err := os.WriteFile(blocker, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	system, err := guard.New(guard.Options{
		EnginePorts: []uint16{7890},
		Mode:        guard.ModeStrict,
		StateDir:    filepath.Join(blocker, "sub"),
	}, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := system.Apply(context.Background(), session.Settings{KillSwitch: true}); err == nil {
		t.Fatal("Apply() succeeded without a writable state directory")
	}
	if firewall.armed {
		t.Error("the firewall stayed armed while the strict intent was not recorded")
	}
	if firewall.arms != 1 || firewall.disarms != 1 {
		t.Errorf("expected one rolled-back Arm, got %+v", firewall)
	}
}

// staleFirewall records CleanupStale calls for Recover tests.
type staleFirewall struct {
	*memoryFirewall
	cleanups int
}

func (f *staleFirewall) CleanupStale(context.Context) error {
	f.cleanups++
	return nil
}

// TestRecoverCleansStaleWhenNotStrict: without a strict marker, Recover
// keeps the old SORA-M4 behaviour of removing a crashed core's table.
func TestRecoverCleansStaleWhenNotStrict(t *testing.T) {
	firewall := &staleFirewall{memoryFirewall: &memoryFirewall{}}
	system, err := guard.New(guard.Options{EnginePorts: []uint16{7890}}, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := system.Recover(context.Background()); err != nil {
		t.Fatalf("Recover() error = %v", err)
	}
	if firewall.cleanups != 1 {
		t.Errorf("Recover() ran %d stale cleanups, want 1", firewall.cleanups)
	}
	if firewall.arms != 0 {
		t.Errorf("Recover() armed %d times without a strict marker", firewall.arms)
	}
}

// TestStrictWantedHelper covers the package-level marker probe used at
// startup before any guard exists.
func TestStrictWantedHelper(t *testing.T) {
	if guard.StrictWanted("") {
		t.Error("StrictWanted(\"\") = true")
	}
	dir := t.TempDir()
	if guard.StrictWanted(dir) {
		t.Error("StrictWanted() = true without a marker")
	}
	if err := os.WriteFile(filepath.Join(dir, "killswitch.strict"), []byte("sora-strict-v1\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if !guard.StrictWanted(dir) {
		t.Error("StrictWanted() = false with the marker present")
	}
}

// TestBlockedReflectsTheFirewall: Blocked is the honest kernel-side state,
// not the guard's memory.
func TestBlockedReflectsTheFirewall(t *testing.T) {
	firewall := &memoryFirewall{}
	system, err := guard.New(guard.Options{EnginePorts: []uint16{7890}}, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	ctx := context.Background()
	if blocked, err := system.Blocked(ctx); err != nil || blocked {
		t.Errorf("Blocked() = %v, %v with nothing armed", blocked, err)
	}
	firewall.armed = true
	if blocked, err := system.Blocked(ctx); err != nil || !blocked {
		t.Errorf("Blocked() = %v, %v with the firewall armed behind the guard's back", blocked, err)
	}
}
