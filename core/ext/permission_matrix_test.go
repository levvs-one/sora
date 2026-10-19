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
	// The extension-served RPCs must all be present: an RPC missing from
	// the closed map is denied, which would be a silent outage, not a
	// vulnerability — but the test pins the intended shape either way.
	// MintToken/RevokeToken are app-only (control-token gated) and are
	// correctly absent from the extension-token map.
	for _, m := range []string{"GetConnections", "GetServers", "Notify", "WatchExtensionEvents"} {
		if _, ok := rpcPermissions[m]; !ok {
			t.Errorf("served RPC %q is missing from rpcPermissions", m)
		}
	}
	for _, m := range []string{"MintToken", "RevokeToken"} {
		if _, ok := rpcPermissions[m]; ok {
			t.Errorf("app-only RPC %q must not be in the extension-token map", m)
		}
	}
}
