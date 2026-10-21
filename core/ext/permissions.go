package ext

// Risk describes how sensitive a permission is. It drives the install-time
// prompt: normal permissions are listed, sensitive ones are highlighted, and
// dangerous ones require an explicit confirmation.
type Risk int

const (
	// RiskNormal is read-only, non-identifying access.
	RiskNormal Risk = iota
	// RiskSensitive can change behavior or see where the user goes.
	RiskSensitive
	// RiskDangerous touches credentials or the network path itself.
	RiskDangerous
)

// Permission is one entry of the v1 permission registry.
type Permission struct {
	// ID is the manifest string, e.g. "connections.read".
	ID string
	// BlurbKey is the localization key the app uses for the human-readable
	// description shown on the install prompt ("will see: ...").
	BlurbKey string
	Risk     Risk
}

// AllPermissions is the closed v1 registry. Manifests may only use these.
var AllPermissions = []Permission{
	{ID: "connections.read", BlurbKey: "extPerm.connectionsRead", Risk: RiskSensitive},
	{ID: "servers.read", BlurbKey: "extPerm.serversRead", Risk: RiskNormal},
	{ID: "settings.read", BlurbKey: "extPerm.settingsRead", Risk: RiskNormal},
	{ID: "settings.write", BlurbKey: "extPerm.settingsWrite", Risk: RiskSensitive},
	{ID: "notifications", BlurbKey: "extPerm.notifications", Risk: RiskNormal},
	{ID: "tray", BlurbKey: "extPerm.tray", Risk: RiskNormal},
	{ID: "ui.panel", BlurbKey: "extPerm.uiPanel", Risk: RiskNormal},
	{ID: "theme.apply", BlurbKey: "extPerm.themeApply", Risk: RiskSensitive},
	{ID: "routing.rules", BlurbKey: "extPerm.routingRules", Risk: RiskDangerous},
	{ID: "net.hooks", BlurbKey: "extPerm.netHooks", Risk: RiskDangerous},
	{ID: "net.fetch", BlurbKey: "extPerm.netFetch", Risk: RiskSensitive},
	{ID: "background", BlurbKey: "extPerm.background", Risk: RiskSensitive},
	// Anti-DPI (bypass) permissions, since the ExtensionHost bypass seam
	// (contract 1.14). Reading the effective bypass state is sensitive —
	// it reveals how the user's traffic evades censorship; writing a
	// layer or running the tuner changes the network path itself, so
	// both are dangerous.
	{ID: "bypass.read", BlurbKey: "extPerm.bypassRead", Risk: RiskSensitive},
	{ID: "bypass.write", BlurbKey: "extPerm.bypassWrite", Risk: RiskDangerous},
	{ID: "bypass.tune", BlurbKey: "extPerm.bypassTune", Risk: RiskDangerous},
}

// permissionIndex is built once for O(1) lookups.
var permissionIndex = func() map[string]Permission {
	m := make(map[string]Permission, len(AllPermissions))
	for _, p := range AllPermissions {
		m[p.ID] = p
	}
	return m
}()

// IsKnownPermission reports whether id is in the v1 registry.
func IsKnownPermission(id string) bool {
	_, ok := permissionIndex[id]
	return ok
}

// LookupPermission returns the registry entry for id.
func LookupPermission(id string) (Permission, bool) {
	p, ok := permissionIndex[id]
	return p, ok
}

// DiffPermissions splits wanted into added and removed relative to granted,
// so an update that widens permissions can re-prompt the user.
func DiffPermissions(granted, wanted []string) (added, removed []string) {
	have := make(map[string]bool, len(granted))
	for _, p := range granted {
		have[p] = true
	}
	want := make(map[string]bool, len(wanted))
	for _, p := range wanted {
		want[p] = true
		if !have[p] {
			added = append(added, p)
		}
	}
	for _, p := range granted {
		if !want[p] {
			removed = append(removed, p)
		}
	}
	return added, removed
}
