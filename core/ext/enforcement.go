package ext

// Permission enforcement as code: the single machine-readable statement of
// which v1 permissions are actually enforced, where, and which are not.
//
// Why this exists: the registry (permissions.go) says what a permission
// *means*; the threat model (docs/extensions/threat-model.md) describes the
// enforcement in prose. Prose drifts. This table is the contract the UI,
// the CLI (sora-ext) and the docs all read, and the tests pin the enforced
// rows against the code that performs the check - a row that claims
// "enforced" must point at a real gate, and a row that is not enforced
// must say so in exactly these words, so nobody (including a future
// contributor) can quietly upgrade the claim.
//
// Statuses:
//
//   - Enforced: a real check runs on every call path.
//   - InstallTime: validated at install/load; there is no runtime call
//     path beyond that gate to check.
//   - Inert: no API exposes the asset at all; granting changes nothing.
//   - Unimplemented: the runtime consumer is not built yet; granting
//     changes nothing. Network hooks remain here.

// EnforcementStatus classifies one permission's real enforcement.
type EnforcementStatus int

const (
	// EnforcementEnforced checked in code on every call path.
	EnforcementEnforced EnforcementStatus = iota
	// EnforcementInstallTime gated at install/load only.
	EnforcementInstallTime
	// EnforcementInert no API exists for the asset; the permission is a
	// no-op today by construction, not by oversight.
	EnforcementInert
	// EnforcementUnimplemented the feature is designed but not built;
	// the permission is a no-op today and granting it grants nothing.
	EnforcementUnimplemented
)

// EnforcementRow is one permission's audited enforcement state.
type EnforcementRow struct {
	// ID is the registry permission id.
	ID string
	// Status is what the code actually enforces.
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
		Where:  "core/ext/worker_host.go workerBridgeCall + app/lib/src/ext/bridge.dart _methodPermission",
		Note:   "getConnections is permission-checked by the worker bridge and app bridge",
	},
	{
		ID:     "servers.read",
		Status: EnforcementEnforced,
		Where:  "core/ext/worker_host.go workerBridgeCall + app/lib/src/ext/bridge.dart _methodPermission",
		Note:   "getServers is permission-checked by the worker bridge and app bridge",
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
		Where:  "core/ext/worker_host.go workerBridgeCall + app/lib/src/ext/bridge.dart _methodPermission",
		Note:   "notify is permission-checked; title/body are size-capped in the app bridge",
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
		ID: "theme.apply", Status: EnforcementEnforced,
		Where: "app/lib/src/ext/store.dart activeTheme + assets.dart ExtensionTheme.parse",
		Note:  "enabled grants only; one conflict winner; color and contrast validation; immediate default restore",
	},
	{
		ID: "routing.rules", Status: EnforcementEnforced,
		Where: "app/lib/src/ext/store.dart routingRules + assets.dart ExtensionRouting.parse + sora.dart buildPlan",
		Note:  "enabled grants only; shared user match parser; direct/proxy/block only; ordered after user rules",
	},
	{
		ID:     "net.hooks",
		Status: EnforcementUnimplemented,
		Note:   "RiskDangerous with zero enforcement code: no hook consumer runs extension code on the traffic path yet. Enforcement and consent must land together before this row moves",
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
		Where:  "core/ext/worker.go Scheduler.RegisterConfig (capability + permission), interval clamp, overlap guard, circuit breaker, kill-switch pause + core/ext/javascript.go process isolation",
		Note:   "goja runs in a disposable process: 2 CPU seconds, 128 MiB committed memory, 30-second wall timeout; app stream cancellation stops the worker",
	},
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
