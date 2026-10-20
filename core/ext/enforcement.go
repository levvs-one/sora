// Permission enforcement as code: the single machine-readable statement of
// which v1 permissions are actually enforced, where, and which are not.
//
// Why this exists: the registry (permissions.go) says what a permission
// *means*; the threat model (docs/extensions/threat-model.md) describes the
// enforcement in prose. Prose drifts. This table is the contract the UI,
// the CLI (sora-ext) and the docs all read, and the tests pin the enforced
// rows against the code that performs the check — a row that claims
// "enforced" must point at a real gate, and a row that is not enforced
// must say so in exactly these words, so nobody (including a future
// contributor) can quietly upgrade the claim.
//
// Honest statuses (2026-10-20, pass-1 audit):
//
//   - Enforced: a real check runs on every call path.
//   - InstallTime: validated at install/load; there is no runtime call
//     path beyond that gate to check.
//   - Inert: no API exposes the asset at all; granting changes nothing.
//   - Unimplemented: the runtime consumer is not built yet; granting
//     changes nothing. Both Dangerous permissions are here today.
package ext

// EnforcementStatus classifies one permission's real enforcement.
type EnforcementStatus int

const (
	// Enforced: checked in code on every call path.
	EnforcementEnforced EnforcementStatus = iota
	// EnforcementInstallTime: gated at install/load only.
	EnforcementInstallTime
	// EnforcementInert: no API exists for the asset; the permission is a
	// no-op today by construction, not by oversight.
	EnforcementInert
	// EnforcementUnimplemented: the feature is designed but not built;
	// the permission is a no-op today and granting it grants nothing.
	EnforcementUnimplemented
)

// String renders the status for logs, docs and the CLI.
func (s EnforcementStatus) String() string {
	switch s {
	case EnforcementEnforced:
		return "enforced"
	case EnforcementInstallTime:
		return "install-time"
	case EnforcementInert:
		return "inert"
	case EnforcementUnimplemented:
		return "unimplemented"
	}
	return "unknown"
}

// EnforcementRow is one permission's audited enforcement state.
type EnforcementRow struct {
	// ID is the registry permission id.
	ID string
	// Status is the honest classification.
	Status EnforcementStatus
	// Where names the code that performs the check. It is set exactly
	// when Status is Enforced or InstallTime; an unenforced row must not
	// borrow credibility by pointing at a file that does not check it.
	Where string
	// Note is the plain-language caveat the prompt/docs must not hide.
	Note string
}

// enforcementTable is the audited matrix. Keep it in registry order
// (AllPermissions) so diffs against the registry are obvious; the test
// pins the two sets equal.
var enforcementTable = []EnforcementRow{
	{
		ID:     "connections.read",
		Status: EnforcementEnforced,
		Where:  "core/ext/host.go Host.check (rpcPermissions) + app/lib/src/ext/bridge.dart _methodPermission",
		Note:   "every GetConnections call is token- and permission-checked",
	},
	{
		ID:     "servers.read",
		Status: EnforcementEnforced,
		Where:  "core/ext/host.go Host.check (rpcPermissions) + app/lib/src/ext/bridge.dart _methodPermission",
		Note:   "every GetServers call is token- and permission-checked",
	},
	{
		ID:     "settings.read",
		Status: EnforcementInert,
		Note:   "no API exposes app settings to extensions; getSettings returns only the extension's own settings, which are permissionless by design. Granting this changes nothing today",
	},
	{
		ID:     "settings.write",
		Status: EnforcementInert,
		Note:   "no API exposes app settings to extensions; setSettings writes only the extension's own settings, which are permissionless by design. Granting this changes nothing today",
	},
	{
		ID:     "notifications",
		Status: EnforcementEnforced,
		Where:  "core/ext/host.go Host.check (rpcPermissions) + Notify text caps + app/lib/src/ext/bridge.dart _methodPermission",
		Note:   "every Notify call is checked; title/body are size-capped in the host",
	},
	{
		ID:     "tray",
		Status: EnforcementUnimplemented,
		Note:   "no tray API exists for extensions yet; granting this changes nothing today",
	},
	{
		ID:     "ui.panel",
		Status: EnforcementInstallTime,
		Where:  "core/ext/manifest.go Validate + app/lib/src/ext/manifest.dart validate: declared panels require the ui-panel capability and the ui.panel permission; the panel loader only serves declared panels",
		Note:   "the prompt always mentions UI embedding now, because a manifest cannot declare a panel without this permission; there is no runtime call to check beyond the bridge, whose methods are individually permission-gated",
	},
	{
		ID:     "theme.apply",
		Status: EnforcementUnimplemented,
		Note:   "the theme runtime is designed (contract pointer in manifest_v1ext.go, example examples/theme-midnight) but no consumer applies themes yet; granting this changes nothing today",
	},
	{
		ID:     "routing.rules",
		Status: EnforcementUnimplemented,
		Note:   "RiskDangerous with zero enforcement code: no routing consumer reads extension rules yet. The day one lands, this permission hands the extension the traffic path; it must ship with the strongest consent language and catalog review, and this row must move to Enforced in the same commit",
	},
	{
		ID:     "net.hooks",
		Status: EnforcementUnimplemented,
		Note:   "RiskDangerous with zero enforcement code: no hook consumer runs extension code on the traffic path yet. Same rule as routing.rules: enforcement and consent land together, or this row does not move",
	},
	{
		ID:     "net.fetch",
		Status: EnforcementEnforced,
		Where:  "core/ext/worker.go Scheduler.RegisterConfig builds the Fetcher only when granted; core/ext/netfetch.go Fetcher.checkURL per request; core/ext/tunnel.go routes through the VPN or fails closed",
		Note:   "the gate is at construction plus a per-request allowlist/protocol/rate/size check; disabling the extension unregisters its worker and drops the Fetcher",
	},
	{
		ID:     "background",
		Status: EnforcementEnforced,
		Where:  "core/ext/worker.go Scheduler.RegisterConfig (capability + permission), interval clamp, overlap guard, circuit breaker, kill-switch pause",
		Note:   "the permission gate and the scheduler machinery are real and unit-tested; the worker executor (a JS runner) is NOT wired in production yet, so no extension code actually runs — see the pass-1 report",
	},
}

// EnforcementTable returns a copy of the audited enforcement matrix, in
// registry order.
func EnforcementTable() []EnforcementRow {
	out := make([]EnforcementRow, len(enforcementTable))
	copy(out, enforcementTable)
	return out
}

// EnforcementOf returns the enforcement row for one permission id.
func EnforcementOf(id string) (EnforcementRow, bool) {
	for _, r := range enforcementTable {
		if r.ID == id {
			return r, true
		}
	}
	return EnforcementRow{}, false
}

// Enforced reports whether the permission has a real runtime check today.
// The CLI and the docs use it to avoid presenting a declared-only
// permission as a protection.
func Enforced(id string) bool {
	r, ok := EnforcementOf(id)
	return ok && (r.Status == EnforcementEnforced || r.Status == EnforcementInstallTime)
}
