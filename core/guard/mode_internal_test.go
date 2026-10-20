// Internal tests for the kill-switch modes. Strict mode (a persistent
// block across crashes and reboots) is deliberately absent from the
// public API — enabling it is a product decision the owner has not
// taken — but the machinery stays here, tested, in case it is switched
// on later. These tests live in the package so they can reach the
// internal mode, parseMode, strictWanted, reconcile and strictIntent.
package guard

import (
	"context"
	"net/netip"
	"os"
	"path/filepath"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/session"
)

// modeTestFirewall records firewall calls without modifying the host.
type modeTestFirewall struct {
	armed    bool
	arms     int
	disarms  int
	ports    []uint16
	armErr   error
	networks []netip.Prefix
	blocked  []netip.Prefix
}

func (f *modeTestFirewall) Arm(_ context.Context, ports []uint16) error {
	if f.armErr != nil {
		return f.armErr
	}
	f.arms++
	f.armed = true
	f.ports = append([]uint16(nil), ports...)
	return nil
}

func (f *modeTestFirewall) Disarm(context.Context) error {
	f.disarms++
	f.armed = false
	return nil
}

func (f *modeTestFirewall) Armed(context.Context) (bool, error) { return f.armed, nil }

func (f *modeTestFirewall) SetTunNetworks(networks []netip.Prefix) {
	f.networks = append([]netip.Prefix(nil), networks...)
}

func (f *modeTestFirewall) SetBlockedNetworks(networks []netip.Prefix) {
	f.blocked = append([]netip.Prefix(nil), networks...)
}

func TestParseModeRoundTrip(t *testing.T) {
	for _, name := range []string{"off", "standard", "strict"} {
		mode, err := parseMode(name)
		if err != nil {
			t.Fatalf("parseMode(%q) error = %v", name, err)
		}
		if mode.String() != name {
			t.Errorf("Mode.String() = %q, want %q", mode.String(), name)
		}
	}
	// Config-facing parsing tolerates case and whitespace.
	if mode, err := parseMode("  STRICT "); err != nil || mode != modeStrict {
		t.Errorf("parseMode(\"  STRICT \") = %v, %v", mode, err)
	}
}

func TestParseModeRejectsTypos(t *testing.T) {
	// A typo must fail closed: it can never silently pick a weaker mode.
	for _, name := range []string{"stric", "standart", "always", "", "on"} {
		if mode, err := parseMode(name); err == nil {
			t.Errorf("parseMode(%q) = %v, want an error", name, mode)
		} else if errs.CodeOf(err) != errs.CodeInvalidArgument {
			t.Errorf("parseMode(%q) code = %v, want invalid argument", name, errs.CodeOf(err))
		}
	}
}

func TestNewRejectsStrictWithoutStateDir(t *testing.T) {
	if _, err := New(Options{EnginePorts: []uint16{7890}, Mode: modeStrict}, nil); err == nil {
		t.Fatal("New() accepted strict mode without a state directory; the marker could not survive a reboot")
	}
}

func TestNewRejectsUnknownMode(t *testing.T) {
	if _, err := New(Options{EnginePorts: []uint16{7890}, Mode: Mode(42)}, nil); err == nil {
		t.Fatal("New() accepted an unknown kill-switch mode")
	}
}

func TestOffRefusesToArm(t *testing.T) {
	firewall := &modeTestFirewall{}
	system, err := New(Options{EnginePorts: []uint16{7890}, Mode: ModeOff}, firewall)
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
func strictSystem(t *testing.T, firewall *modeTestFirewall) (*Guard, string) {
	t.Helper()
	stateDir := t.TempDir()
	system, err := New(Options{
		EnginePorts: []uint16{7890},
		Mode:        modeStrict,
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
	firewall := &modeTestFirewall{}
	system, stateDir := strictSystem(t, firewall)
	ctx := context.Background()

	if err := system.Apply(ctx, session.Settings{KillSwitch: true}); err != nil {
		t.Fatalf("Apply() error = %v", err)
	}
	if !firewall.armed || !markerExists(stateDir) {
		t.Fatalf("strict arm: armed=%v marker=%v", firewall.armed, markerExists(stateDir))
	}

	// The crash: a new guard with no memory of the old one.
	crashed := &modeTestFirewall{}
	after, err := New(Options{
		EnginePorts: []uint16{7890},
		Mode:        modeStrict,
		StateDir:    stateDir,
	}, crashed)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if !after.strictIntent() {
		t.Fatal("strictIntent() = false after a crash with the marker present")
	}
	if !after.Current().KillSwitch {
		t.Error("Current() claims the traffic is open while the strict marker survives")
	}
	if blocked, err := after.Blocked(ctx); err != nil || blocked {
		t.Errorf("Blocked() = %v, %v with nothing armed in the new process", blocked, err)
	}
	// Startup recovery re-arms from the marker (idempotent: one Arm).
	if err := after.reconcile(ctx); err != nil {
		t.Fatalf("reconcile() error = %v", err)
	}
	if crashed.arms != 1 || !crashed.armed {
		t.Errorf("reconcile() did not re-arm: %+v", crashed)
	}
	if blocked, err := after.Blocked(ctx); err != nil || !blocked {
		t.Errorf("Blocked() = %v, %v after reconcile", blocked, err)
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
	firewall := &modeTestFirewall{}
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
		t.Error("the strict marker survived an explicit off; the next reconcile would re-arm behind the user's back")
	}
	if system.strictIntent() {
		t.Error("strictIntent() = true after an explicit off")
	}
	if system.Current().KillSwitch {
		t.Error("Current() still reports the switch after an explicit off")
	}
}

// TestStrictMarkerWriteFailureRollsBackArming: when the intent cannot be
// recorded, the block must not stay up unrecorded — a crash would then
// lose it silently. The Arm is rolled back and the error reported.
func TestStrictMarkerWriteFailureRollsBackArming(t *testing.T) {
	firewall := &modeTestFirewall{}
	blocker := t.TempDir() + "/not-a-dir"
	if err := os.WriteFile(blocker, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	system, err := New(Options{
		EnginePorts: []uint16{7890},
		Mode:        modeStrict,
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

// modeStaleFirewall records CleanupStale calls for reconcile tests.
type modeStaleFirewall struct {
	*modeTestFirewall
	cleanups int
}

func (f *modeStaleFirewall) CleanupStale(context.Context) error {
	f.cleanups++
	return nil
}

// TestReconcileCleansStaleWhenNotStrict: without a strict marker, reconcile
// keeps the old SORA-M4 behaviour of removing a crashed core's table.
func TestReconcileCleansStaleWhenNotStrict(t *testing.T) {
	firewall := &modeStaleFirewall{modeTestFirewall: &modeTestFirewall{}}
	system, err := New(Options{EnginePorts: []uint16{7890}}, firewall)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	if err := system.reconcile(context.Background()); err != nil {
		t.Fatalf("reconcile() error = %v", err)
	}
	if firewall.cleanups != 1 {
		t.Errorf("reconcile() ran %d stale cleanups, want 1", firewall.cleanups)
	}
	if firewall.arms != 0 {
		t.Errorf("reconcile() armed %d times without a strict marker", firewall.arms)
	}
}

// TestStrictWantedHelper covers the package-level marker probe used at
// startup before any guard exists.
func TestStrictWantedHelper(t *testing.T) {
	if strictWanted("") {
		t.Error("strictWanted(\"\") = true")
	}
	dir := t.TempDir()
	if strictWanted(dir) {
		t.Error("strictWanted() = true without a marker")
	}
	if err := os.WriteFile(filepath.Join(dir, "killswitch.strict"), []byte("sora-strict-v1\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if !strictWanted(dir) {
		t.Error("strictWanted() = false with the marker present")
	}
}
