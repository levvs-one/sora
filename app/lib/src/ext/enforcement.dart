/// Permission enforcement state as code.
///
/// Mirrors core/ext/enforcement.go - the audited, test-pinned statement of
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
/// The UI renders these statuses with the l10n key `extPermNotYetActive`
/// for [ExtEnforcementStatus.inert] and [ExtEnforcementStatus.unimplemented]
/// rows - wired in the install prompt (permissions_sheet.dart) and in the
/// detail screen's permission list, so a grant that does nothing yet is
/// labelled at consent time and afterwards.
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
    'getConnections is permission-checked by the worker bridge and app bridge',
  ),
  ExtEnforcementRow(
    'servers.read',
    ExtEnforcementStatus.enforced,
    'getServers is permission-checked by the worker bridge and app bridge',
  ),
  ExtEnforcementRow(
    'settings.read',
    ExtEnforcementStatus.inert,
    'no API exposes app settings; granting changes nothing today',
  ),
  ExtEnforcementRow(
    'settings.write',
    ExtEnforcementStatus.inert,
    'no API exposes app settings; granting changes nothing today',
  ),
  ExtEnforcementRow(
    'notifications',
    ExtEnforcementStatus.enforced,
    'notify is permission-checked; text is size-capped in the app bridge',
  ),
  ExtEnforcementRow(
    'tray',
    ExtEnforcementStatus.unimplemented,
    'no tray API exists yet; granting changes nothing today',
  ),
  ExtEnforcementRow(
    'ui.panel',
    ExtEnforcementStatus.installTime,
    'declared panels require the ui.panel permission: the prompt always mentions UI embedding',
  ),
  ExtEnforcementRow(
    'theme.apply',
    ExtEnforcementStatus.enforced,
    'enabled grants, conflict winner, validated colors and contrast; restores defaults on disable',
  ),
  ExtEnforcementRow(
    'routing.rules',
    ExtEnforcementStatus.enforced,
    'enabled grants, user match parser, ordered after user rules, direct/proxy/block only',
  ),
  ExtEnforcementRow(
    'net.hooks',
    ExtEnforcementStatus.unimplemented,
    'RiskDangerous with zero enforcement code: no consumer runs extension hooks yet',
  ),
  ExtEnforcementRow(
    'net.fetch',
    ExtEnforcementStatus.enforced,
    'allowlist + https/IP/port/redirect/rate/size checks; rides the VPN or fails closed',
  ),
  ExtEnforcementRow(
    'background',
    ExtEnforcementStatus.enforced,
    'capability + permission gate, clamped scheduler, isolated goja process with CPU/memory/wall budgets',
  ),
];

final _enforcementIndex = {for (final r in extEnforcementTable) r.id: r};

ExtEnforcementRow? enforcementOf(String id) => _enforcementIndex[id];

/// True when the permission has a real check today (enforced or
/// install-time). The install prompt must never present a false value as
/// a protection.
bool isEnforced(String id) {
  final row = enforcementOf(id);
  return row != null && (row.status == ExtEnforcementStatus.enforced || row.status == ExtEnforcementStatus.installTime);
}

/// True for permissions that are honestly "granted but doing nothing yet":
/// inert or unimplemented. The prompt should say so in plain language.
bool isNotYetActive(String id) {
  final row = enforcementOf(id);
  return row != null && (row.status == ExtEnforcementStatus.inert || row.status == ExtEnforcementStatus.unimplemented);
}
