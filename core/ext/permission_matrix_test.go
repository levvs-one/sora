package ext

import "testing"

// TestRpcPermissionsCoverRegistry pins the permission-enforcement audit
// invariant: every RPC the host serves to extensions is listed in the
// closed rpcPermissions map (an unlisted RPC is denied), and every listed
// permission is a real registry permission, so a typo cannot silently
// grant token-only access.
func TestRpcPermissionsCoverRegistry(t *testing.T) {
	if len(rpcPermissions) == 0 {
		t.Fatal("rpcPermissions must not be empty")
	}
	for rpc, perm := range rpcPermissions {
		if perm == "" {
			continue // explicitly token-only
		}
		if !IsKnownPermission(perm) {
			t.Errorf("rpcPermissions[%q] = %q: not a known permission", rpc, perm)
		}
	}
	// The extension-served RPCs must all be present, each demanding
	// exactly its intended permission: an RPC missing from the closed
	// map is denied, which would be a silent outage, not a
	// vulnerability — but the test pins the intended shape either way.
	// All ten RPCs are listed (M3): the four original ones plus the six
	// Anti-DPI bypass RPCs of contract 1.14.
	// MintToken/RevokeToken are app-only (control-token gated) and are
	// correctly absent from the extension-token map.
	want := map[string]string{
		"GetConnections":        "connections.read",
		"GetServers":            "servers.read",
		"Notify":                "notifications",
		"WatchExtensionEvents":  "",
		"GetBypassCapabilities": "bypass.read",
		"GetBypassState":        "bypass.read",
		"GetBypassLayer":        "bypass.read",
		"WatchBypassEvents":     "bypass.read",
		"ApplyBypassLayer":      "bypass.write",
		"TuneDesync":            "bypass.tune",
	}
	if len(rpcPermissions) != len(want) {
		t.Errorf("rpcPermissions has %d entries, want exactly the %d served extension RPCs", len(rpcPermissions), len(want))
	}
	for m, perm := range want {
		got, ok := rpcPermissions[m]
		if !ok {
			t.Errorf("served RPC %q is missing from rpcPermissions", m)
			continue
		}
		if got != perm {
			t.Errorf("rpcPermissions[%q] = %q, want %q", m, got, perm)
		}
	}
	for _, m := range []string{"MintToken", "RevokeToken"} {
		if _, ok := rpcPermissions[m]; ok {
			t.Errorf("app-only RPC %q must not be in the extension-token map", m)
		}
	}
}
