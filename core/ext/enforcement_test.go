package ext

import (
	"strings"
	"testing"
)

// TestEnforcementTableCoversRegistry pins the matrix to the permission
// registry: every registry permission has exactly one row, in registry
// order, and there are no rows for nonexistent permissions.
func TestEnforcementTableCoversRegistry(t *testing.T) {
	table := EnforcementTable()
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

// TestEnforcementRowsAreHonestShape pins the honesty rules of the matrix
// itself: a row that claims enforcement must name the check; a row that
// admits none must not point at code as if it did.
func TestEnforcementRowsAreHonestShape(t *testing.T) {
	for _, row := range EnforcementTable() {
		switch row.Status {
		case EnforcementEnforced, EnforcementInstallTime:
			if row.Where == "" {
				t.Errorf("%q claims %s but names no code location", row.ID, row.Status)
			}
		case EnforcementInert, EnforcementUnimplemented:
			if row.Where != "" {
				t.Errorf("%q is %s but names code (%q): an unenforced row must not borrow credibility",
					row.ID, row.Status, row.Where)
			}
		default:
			t.Errorf("%q has unknown status %v", row.ID, row.Status)
		}
	}
}

// TestEnforcementRPCClaimsMatchHost verifies the Enforced rows for the
// host RPC permissions against the actual gate: the closed rpcPermissions
// map must demand exactly them.
func TestEnforcementRPCClaimsMatchHost(t *testing.T) {
	want := map[string]string{
		"GetConnections": "connections.read",
		"GetServers":     "servers.read",
		"Notify":         "notifications",
	}
	for rpc, perm := range want {
		if got := rpcPermissions[rpc]; got != perm {
			t.Errorf("rpcPermissions[%q] = %q, the matrix claims %q is enforced there", rpc, got, perm)
		}
		row, ok := EnforcementOf(perm)
		if !ok || row.Status != EnforcementEnforced {
			t.Errorf("matrix says %q is %v, but the host enforces it", perm, row.Status)
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

// TestEnforcementDangerousAreNotClaimedEnforced is the load-bearing
// honesty pin: net.hooks has zero enforcement code today, and the matrix
// must say so. Flipping it to Enforced
// requires a behavior pin in this test proving a real gate exists -
// a docs edit must never be able to upgrade the claim on its own.
func TestEnforcementDangerousAreNotClaimedEnforced(t *testing.T) {
	for _, id := range []string{"net.hooks"} {
		row, ok := EnforcementOf(id)
		if !ok {
			t.Fatalf("no enforcement row for %q", id)
		}
		perm, _ := LookupPermission(id)
		if perm.Risk != RiskDangerous {
			t.Fatalf("%q risk = %v in the registry, want RiskDangerous", id, perm.Risk)
		}
		if row.Status == EnforcementEnforced || row.Status == EnforcementInstallTime {
			t.Errorf("%q is claimed %s, but no enforcement point exists; "+
				"if one landed, add a behavior pin here in the same commit", id, row.Status)
		}
		if !strings.Contains(row.Note, "zero enforcement code") {
			t.Errorf("%q note must stay blunt until a real gate lands: %q", id, row.Note)
		}
		if Enforced(id) {
			t.Errorf("Enforced(%q) = true, want false while unimplemented", id)
		}
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
		if Enforced(id) {
			t.Errorf("Enforced(%q) = true, want false", id)
		}
	}
}
