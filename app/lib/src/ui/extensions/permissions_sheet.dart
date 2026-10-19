/// Install prompt: the permission screen shown before an extension is
/// installed or when an update widens permissions.
///
/// Least privilege, stated plainly: every permission is rendered as a
/// human-readable "will be able to" line. Dangerous permissions are
/// highlighted and need an explicit confirmation checkbox.
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../kit.dart';
import '../../ext/manifest.dart';
import '../../ext/permissions.dart';
import 'widgets.dart';

/// Shows the install prompt. Returns the granted permission ids, or null
/// when the user cancelled.
Future<List<String>?> showInstallPrompt(
  BuildContext context, {
  required ExtManifest manifest,
  required bool sideload,
  List<String>? addedPermissions,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => _InstallPrompt(
      manifest: manifest,
      sideload: sideload,
      addedPermissions: addedPermissions,
    ),
  );
}

String permissionBlurb(BuildContext context, String id) {
  final s = S.of(context);
  switch (id) {
    case 'connections.read':
      return s.extPermConnectionsRead;
    case 'servers.read':
      return s.extPermServersRead;
    case 'settings.read':
      return s.extPermSettingsRead;
    case 'settings.write':
      return s.extPermSettingsWrite;
    case 'notifications':
      return s.extPermNotifications;
    case 'tray':
      return s.extPermTray;
    case 'ui.panel':
      return s.extPermUiPanel;
    case 'theme.apply':
      return s.extPermThemeApply;
    case 'routing.rules':
      return s.extPermRoutingRules;
    case 'net.hooks':
      return s.extPermNetHooks;
    case 'net.fetch':
      return s.extPermNetFetch;
    case 'background':
      return s.extPermBackground;
    default:
      return id;
  }
}

/// Longer explanation shown under the short blurb on the install prompt,
/// for the permissions whose one-liner does not say enough. Null for
/// permissions whose blurb says it all.
String? permissionDetail(BuildContext context, String id) {
  final s = S.of(context);
  switch (id) {
    case 'background':
      return s.extPermBackgroundDetail;
    case 'net.fetch':
      return s.extPermNetworkDetail;
    default:
      return null;
  }
}

class _InstallPrompt extends StatefulWidget {
  const _InstallPrompt({
    required this.manifest,
    required this.sideload,
    this.addedPermissions,
  });
  final ExtManifest manifest;
  final bool sideload;
  final List<String>? addedPermissions;

  @override
  State<_InstallPrompt> createState() => _InstallPromptState();
}

class _InstallPromptState extends State<_InstallPrompt> {
  bool _dangerousAck = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final m = widget.manifest;
    final perms = widget.addedPermissions ?? m.permissions;
    final dangerous = perms.where(requiresExplicitConfirm).toList();
    final canInstall = dangerous.isEmpty || _dangerousAck;
    return Dialog(
      backgroundColor: palette.raised,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.field.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Symbols.extension_rounded, color: palette.ink2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.addedPermissions == null
                              ? s.extInstallTitle(m.name)
                              : s.extUpdateTitle(m.name),
                          style: Styles.title.copyWith(color: palette.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(s.extByAuthor(m.author.name),
                            style: Styles.caption.copyWith(color: palette.ink2)),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.sideload) ...[
                const SizedBox(height: 12),
                ExtBadge(
                  label: s.extSideloadWarning,
                  tone: ExtBadgeTone.warn,
                  icon: Symbols.warning_rounded,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                widget.addedPermissions == null
                    ? s.extPermissionsIntro
                    : s.extPermissionsWidened,
                style: Styles.body.copyWith(color: palette.ink),
              ),
              const SizedBox(height: 4),
              for (final p in perms) ...[
                PermissionRow(
                  blurb: permissionBlurb(context, p),
                  dangerous: requiresExplicitConfirm(p),
                ),
                _permissionExtra(context, m, p),
              ],
              if (dangerous.isNotEmpty) ...[
                const SizedBox(height: 8),
                // A custom checkbox: expose the checked state to screen
                // readers since the icon alone carries no semantics.
                Semantics(
                  checked: _dangerousAck,
                  onTap: () => setState(() => _dangerousAck = !_dangerousAck),
                  child: InkWell(
                    onTap: () => setState(() => _dangerousAck = !_dangerousAck),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _dangerousAck
                                ? Symbols.check_box_rounded
                                : Symbols.check_box_outline_blank_rounded,
                            color: _dangerousAck ? palette.ink : palette.ink3,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s.extDangerousAck,
                                style: Styles.body.copyWith(color: palette.ink)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: widget.addedPermissions == null ? s.extInstall : s.extUpdate,
                onTap: canInstall ? () => Navigator.pop(context, List.of(m.permissions)) : null,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s.extCancel, style: TextStyle(color: palette.ink2)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The plain-language explanation (and, for network access, the exact
  /// host allowlist) rendered under a permission row. Empty when the blurb
  /// says it all.
  Widget _permissionExtra(BuildContext context, ExtManifest m, String permission) {
    final detail = permissionDetail(context, permission);
    final hosts = isNetworkPermission(permission) ? m.networkHosts : const <String>[];
    if (detail == null && hosts.isEmpty) return const SizedBox.shrink();
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail != null)
            Text(detail, style: Styles.caption.copyWith(color: palette.ink2)),
          if (hosts.isNotEmpty) ...[
            const SizedBox(height: 4),
            NetworkHostsList(hosts: hosts),
          ],
        ],
      ),
    );
  }
}
