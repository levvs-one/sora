/// Permission enforcement state as code.
///
/// Mirrors core/ext/enforcement.go — the audited, test-pinned statement of
/// which v1 permissions are actually enforced and where. This file is the
/// contract the install prompt and the settings screens must read: it is
/// the only place that is allowed to claim a permission "does nothing yet".
///
/// The Go table is authoritative; this mirror must be updated in the same
/// commit whenever core/ext/enforcement.go changes. The statuses:
/// enforced (a real check on every call path), installTime (gated at
/// install/load), inert (no API exists; granting changes nothing),
/// unimplemented (runtime consumer not built; granting changes nothing).
///
/// When the UI renders these statuses in the user's language, use the l10n
/// key `extPermNotYetActive` (proposed; add alongside the extPerm* keys)
/// for [ExtEnforcementStatus.inert] and [ExtEnforcementStatus.unimplemented]
/// rows, and keep the prompt blunt: "granted silently today".
library;

enum ExtEnforcementStatus { enforced, installTime, inert, unimplemented }

class ExtEnforcementRow {
  const ExtEnforcementRow(this.id, this.status, this.note);
  final String id;
  final ExtEnforcementStatus status;

  /// Plain-language caveat, in English. Mirrors the Go row's Note; the
  /// user-facing text lives in l10n, not here.
  final String note;
}

const List<ExtEnforcementRow> extEnforcementTable = [
  ExtEnforcementRow(
      'connections.read',
      ExtEnforcementStatus.enforced,
      'every GetConnections call is token- and permission-checked'),
  ExtEnforcementRow(
      'servers.read',
      ExtEnforcementStatus.enforced,
      'every GetServers call is token- and permission-checked'),
  ExtEnforcementRow(
      'settings.read',
      ExtEnforcementStatus.inert,
      'no API exposes app settings; granting changes nothing today'),
  ExtEnforcementRow(
      'settings.write',
      ExtEnforcementStatus.inert,
      'no API exposes app settings; granting changes nothing today'),
  ExtEnforcementRow(
      'notifications',
      ExtEnforcementStatus.enforced,
      'every Notify call is checked; text is size-capped in the host'),
  ExtEnforcementRow('tray', ExtEnforcementStatus.unimplemented,
      'no tray API exists yet; granting changes nothing today'),
  ExtEnforcementRow(
      'ui.panel',
      ExtEnforcementStatus.installTime,
      'declared panels require the ui.panel permission: the prompt always mentions UI embedding'),
  ExtEnforcementRow(
      'theme.apply',
      ExtEnforcementStatus.unimplemented,
      'theme runtime not built yet; granting changes nothing today'),
  ExtEnforcementRow(
      'routing.rules',
      ExtEnforcementStatus.unimplemented,
      'RiskDangerous with zero enforcement code: no consumer reads extension rules yet'),
  ExtEnforcementRow(
      'net.hooks',
      ExtEnforcementStatus.unimplemented,
      'RiskDangerous with zero enforcement code: no consumer runs extension hooks yet'),
  ExtEnforcementRow(
      'net.fetch',
      ExtEnforcementStatus.enforced,
      'allowlist + https/IP/port/redirect/rate/size checks; rides the VPN or fails closed'),
  ExtEnforcementRow(
      'background',
      ExtEnforcementStatus.enforced,
      'capability + permission gate, interval clamp, overlap guard, circuit breaker; no worker executor wired yet'),
];

final _enforcementIndex = {
  for (final r in extEnforcementTable) r.id: r,
};

ExtEnforcementRow? enforcementOf(String id) => _enforcementIndex[id];

/// True when the permission has a real check today (enforced or
/// install-time). The install prompt must never present a false value as
/// a protection.
bool isEnforced(String id) {
  final row = enforcementOf(id);
  return row != null &&
      (row.status == ExtEnforcementStatus.enforced ||
          row.status == ExtEnforcementStatus.installTime);
}

/// True for permissions that are honestly "granted but doing nothing yet":
/// inert or unimplemented. The prompt should say so in plain language.
bool isNotYetActive(String id) {
  final row = enforcementOf(id);
  return row != null &&
      (row.status == ExtEnforcementStatus.inert ||
          row.status == ExtEnforcementStatus.unimplemented);
}
