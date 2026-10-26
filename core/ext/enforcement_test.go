package ext

import (
	"strings"
	"testing"
)

// TestEnforcementTableCoversRegistry pins the matrix to the permission
// registry: every registry permission has exactly one row, in registry
// order, and there are no rows for nonexistent permissions.
func TestEnforcementTableCoversRegistry(t *testing.T) {
	table := enforcementTable
	if len(table) != len(AllPermissions) {
		t.Fatalf("table has %d rows, registry has %d permissions", len(table), len(AllPermissions))
	}
	for i, p := range AllPermissions {
		if table[i].ID != p.ID {
			t.Errorf("row %d is %q, registry order expects %q", i, table[i].ID, p.ID)
		}
		if table[i].Note == "" {
			t.Errorf("row %q has no note: the caveat is part of the contract", p.ID)
		}
	}
}

// TestEnforcementRowsAreTruthful pins the wording rules of the matrix
// itself: a row that claims enforcement must name the check; a row that
// admits none must not point at code as if it did.
func TestEnforcementRowsAreTruthful(t *testing.T) {
	for _, row := range enforcementTable {
		switch row.Status {
		case EnforcementEnforced, EnforcementInstallTime:
			if row.Where == "" {
				t.Errorf("%q claims %v but names no code location", row.ID, row.Status)
			}
		case EnforcementInert, EnforcementUnimplemented:
			if row.Where != "" {
				t.Errorf("%q is %v but names code (%q): an unenforced row must not borrow credibility",
					row.ID, row.Status, row.Where)
			}
		default:
			t.Errorf("%q has unknown status %v", row.ID, row.Status)
		}
	}
}

// TestEnforcementBackgroundGateIsReal verifies the background row's claim
// by exercising the gate: registration without the permission is refused.
func TestEnforcementBackgroundGateIsReal(t *testing.T) {
	row, ok := EnforcementOf("background")
	if !ok || row.Status != EnforcementEnforced {
		t.Fatalf("matrix background row = %v, want Enforced", row.Status)
	}
	s := NewScheduler(nil)
	_, x := bgPair(t, 30)
	noPerm := bgManifest(t)
	noPerm.Permissions = []string{"net.fetch"}
	if err := s.Register(noPerm, x, okRun); err == nil {
		t.Fatal("Register without the background permission succeeded: the matrix claim is false")
	}
}

// Runtime selection, conflicts and disconnect behavior are exercised by
// app/test/extension_bypass_test.dart over a private authenticated gRPC socket.
// The Go contract must not imply a core-side extension executable loader.
func TestEnforcementBypassProfilesScope(t *testing.T) {
	row, ok := EnforcementOf("net.hooks")
	perm, _ := LookupPermission("net.hooks")
	if !ok || row.Status != EnforcementEnforced || perm.Risk != RiskDangerous {
		t.Fatal("bypass profiles require an enforced dangerous permission")
	}
	if !strings.Contains(row.Where, "app/lib/src/ext/store.dart") ||
		!strings.Contains(row.Note, "profiles") || !strings.Contains(row.Note, "no native paths") {
		t.Fatal("the claim must stay scoped to the app's declarative profile consumer")
	}
}

// TestEnforcementSettingsAreInert pins the settings rows: the only settings
// surface is the extension's own settings (bridge getSettings/setSettings,
// permissionless by design), so the app-settings permissions stay Inert.
func TestEnforcementSettingsAreInert(t *testing.T) {
	for _, id := range []string{"settings.read", "settings.write"} {
		row, _ := EnforcementOf(id)
		if row.Status != EnforcementInert {
			t.Errorf("%q status = %v, want Inert (no app-settings API exists)", id, row.Status)
		}
	}
}
