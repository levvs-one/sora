/// Extension permission registry (mirrors core/ext/permissions.go).
///
/// The single source of truth for the v1 permission set. The UI renders the
/// install prompt from this: [blurbKey] is the localization key for the
/// human-readable "will see / will be able to" line.
library;

enum ExtRisk { normal, sensitive, dangerous }

class ExtPermission {
  const ExtPermission(this.id, this.blurbKey, this.risk);
  final String id;
  final String blurbKey;
  final ExtRisk risk;
}

const List<ExtPermission> extPermissions = [
  ExtPermission('connections.read', 'extPermConnectionsRead', ExtRisk.sensitive),
  ExtPermission('servers.read', 'extPermServersRead', ExtRisk.normal),
  ExtPermission('settings.read', 'extPermSettingsRead', ExtRisk.normal),
  ExtPermission('settings.write', 'extPermSettingsWrite', ExtRisk.sensitive),
  ExtPermission('notifications', 'extPermNotifications', ExtRisk.normal),
  ExtPermission('tray', 'extPermTray', ExtRisk.normal),
  ExtPermission('ui.panel', 'extPermUiPanel', ExtRisk.normal),
  ExtPermission('theme.apply', 'extPermThemeApply', ExtRisk.sensitive),
  ExtPermission('routing.rules', 'extPermRoutingRules', ExtRisk.dangerous),
  ExtPermission('net.hooks', 'extPermNetHooks', ExtRisk.dangerous),
  ExtPermission('net.fetch', 'extPermNetFetch', ExtRisk.sensitive),
  ExtPermission('background', 'extPermBackground', ExtRisk.sensitive),
];

final _index = {for (final p in extPermissions) p.id: p};

bool isKnownPermission(String id) => _index.containsKey(id);

ExtPermission? lookupPermission(String id) => _index[id];

bool requiresExplicitConfirm(String id) => _index[id]?.risk == ExtRisk.dangerous;

/// True for the permission that grants internet access: `net.fetch`.
/// The manifest's host allowlist applies to it.
bool isNetworkPermission(String id) => id == 'net.fetch';

/// Splits [wanted] into added/removed relative to [granted].
({List<String> added, List<String> removed}) diffPermissions(List<String> granted, List<String> wanted) {
  final have = granted.toSet();
  final want = wanted.toSet();
  return (
    added: [
      for (final p in want)
        if (!have.contains(p)) p,
    ],
    removed: [
      for (final p in have)
        if (!want.contains(p)) p,
    ],
  );
}
