/// Install prompt: the permission screen shown before an extension is
/// installed or when an update widens permissions.
///
/// Least privilege, stated plainly: every permission is rendered as a
/// human-readable "will be able to" line with its risk tier.
/// Dangerous permissions are highlighted and need an explicit confirmation
/// checkbox. A widening update shows only what is new (plus what the
/// update drops), with the changelog on top so the user knows why.
library;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/strings.dart';
import '../../design/theme.dart';
import '../kit.dart';
import '../../ext/catalog.dart';
import '../../ext/enforcement.dart';
import '../../ext/manifest.dart';
import '../../ext/permissions.dart';
import 'widgets.dart';

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
    case 'net.fetch':
      return s.extPermNetworkDetail;
    default:
      return null;
  }
}

class InstallPermissionPrompt extends StatefulWidget {
  const InstallPermissionPrompt({
    super.key,
    required this.manifest,
    required this.sideload,
    this.addedPermissions,
    this.removedPermissions,
    this.changelog,
    this.onDecision,
    this.verified = false,
  });
  final ExtManifest manifest;
  final bool sideload;
  final List<String>? addedPermissions;
  final List<String>? removedPermissions;
  final List<CatalogChangelogEntry>? changelog;
  final ValueChanged<List<String>?>? onDecision;
  final bool verified;

  @override
  State<InstallPermissionPrompt> createState() => _InstallPromptState();
}

class _InstallPromptState extends State<InstallPermissionPrompt> {
  bool _dangerousAck = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final m = widget.manifest;
    // Three states: fresh install (null) shows the full list under
    // "Install"; an update shows the delta under "Update"; an update with
    // no additions falls back to the full list with the neutral intro.
    final isUpdate = widget.addedPermissions != null;
    final showDelta = isUpdate && widget.addedPermissions!.isNotEmpty;
    final perms = showDelta ? widget.addedPermissions! : m.permissions;
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
                        ExtensionName(name: m.name, verified: widget.verified),
                        const SizedBox(height: 2),
                        Text(s.extByAuthor(m.author.name), style: Styles.caption.copyWith(color: palette.ink2)),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.sideload) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Symbols.warning_rounded, size: 18, color: palette.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.extSideloadWarning, style: Styles.secondary.copyWith(color: palette.ink2)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              if (widget.changelog != null && widget.changelog!.isNotEmpty) ...[
                Text(s.extChangelog, style: Styles.bodyStrong.copyWith(color: palette.ink)),
                const SizedBox(height: 4),
                for (final c in widget.changelog!) ...[
                  Text(
                    c.version,
                    style: Styles.caption.copyWith(color: palette.ink, fontWeight: FontWeight.w600),
                  ),
                  Text(c.notes, style: Styles.caption.copyWith(color: palette.ink2)),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 4),
              ],
              Text(
                showDelta ? s.extPermissionsWidened : s.extPermissionsTitle,
                style: Styles.body.copyWith(color: palette.ink),
              ),
              const SizedBox(height: 4),
              for (final p in perms) ...[
                PermissionRow(blurb: permissionBlurb(context, p), risk: lookupPermission(p)?.risk ?? ExtRisk.normal),
                _permissionExtra(context, m, p),
              ],
              if (widget.removedPermissions != null && widget.removedPermissions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(s.extPermissionsRemoved, style: Styles.body.copyWith(color: palette.ink)),
                const SizedBox(height: 4),
                for (final p in widget.removedPermissions!) _RemovedPermissionRow(blurb: permissionBlurb(context, p)),
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
                            _dangerousAck ? Symbols.check_box_rounded : Symbols.check_box_outline_blank_rounded,
                            color: _dangerousAck ? palette.ink : palette.ink3,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s.extDangerousAck, style: Styles.body.copyWith(color: palette.ink)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: isUpdate ? s.extUpdate : s.extInstall,
                onTap: canInstall ? () => _decide(List.of(m.permissions)) : null,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _decide(null),
                child: Text(s.extCancel, style: TextStyle(color: palette.ink2)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _decide(List<String>? granted) {
    if (widget.onDecision != null) {
      widget.onDecision!(granted);
    } else {
      Navigator.pop(context, granted);
    }
  }

  /// The plain-language explanation (and, for network access, the exact
  /// host allowlist) rendered under a permission row. Also carries the
  /// "not yet active" marker for permissions whose runtime is not
  /// built (enforcement.dart is the source of truth): the prompt must
  /// never present an inert or unimplemented grant as live protection.
  /// Network hooks also need a profile entry in the verified manifest.
  /// Empty when the blurb says it all.
  Widget _permissionExtra(BuildContext context, ExtManifest m, String permission) {
    final detail = permissionDetail(context, permission);
    final hosts = isNetworkPermission(permission) ? m.networkHosts : const <String>[];
    final notYetActive = isNotYetActive(permission) || (permission == 'net.hooks' && m.networkHookEntry == null);
    if (detail == null && hosts.isEmpty && !notYetActive) {
      return const SizedBox.shrink();
    }
    final s = S.of(context);
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail != null) Text(detail, style: Styles.caption.copyWith(color: palette.ink2)),
          if (notYetActive) ...[
            if (detail != null) const SizedBox(height: 2),
            Text(s.extPermNotYetActive, style: Styles.caption.copyWith(color: palette.ink2)),
          ],
          if (hosts.isNotEmpty) ...[const SizedBox(height: 4), NetworkHostsList(hosts: hosts)],
        ],
      ),
    );
  }
}

/// A permission the update drops. Rendered quieter than the granted rows:
/// the point is "you are losing access", not an alarm.
class _RemovedPermissionRow extends StatelessWidget {
  const _RemovedPermissionRow({required this.blurb});
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.remove_circle_rounded, size: 18, color: palette.ink3),
          const SizedBox(width: 10),
          Expanded(
            child: Text(blurb, style: Styles.body.copyWith(color: palette.ink2)),
          ),
        ],
      ),
    );
  }
}
