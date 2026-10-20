/// Extension detail: description, creator rating, permissions in plain
/// language, settings auto-generated from settings_schema, and the
/// lifecycle actions (install / update / enable / disable / rollback /
/// remove / open panel).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';

import '../../../l10n/strings.dart';
import '../../design/theme.dart';
import '../kit.dart';
import '../../ext/catalog.dart';
import '../../ext/enforcement.dart';
import '../../ext/manifest.dart';
import '../../ext/permissions.dart';
import '../../ext/store.dart';
import 'panel_screen.dart';
import 'permissions_sheet.dart';
import 'widgets.dart';

class ExtensionDetailScreen extends StatefulWidget {
  const ExtensionDetailScreen({super.key, this.entry, this.installed, this.onInstall})
      : assert(entry != null || installed != null);

  final CatalogEntry? entry;
  final InstalledExtension? installed;

  /// Installs a catalog entry (wired by the catalog list). Null when the
  /// detail is opened for an installed extension.
  final Future<void> Function(CatalogEntry entry)? onInstall;

  @override
  State<ExtensionDetailScreen> createState() => _ExtensionDetailScreenState();
}

class _ExtensionDetailScreenState extends State<ExtensionDetailScreen> {
  Map<String, dynamic>? _settings;
  bool _saving = false;

  /// Synthetic manifest from a catalog entry, used only when the
  /// extension is not installed.
  ExtManifest get _syntheticManifest => ExtManifest(
        id: widget.entry!.id,
        name: widget.entry!.name,
        version: widget.entry!.version,
        minAppVersion: widget.entry!.minAppVersion,
        description: widget.entry!.description,
        author: ExtAuthor(
            name: widget.entry!.author,
            identity: widget.entry!.authorIdentity,
            publicKey: widget.entry!.authorKey),
        permissions: widget.entry!.permissions,
        capabilities: const [],
        panels: const [],
      );

  bool _depsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _depsReady = true;
    if (widget.installed != null) _loadSettings();
  }

  Future<void> _loadSettings() async {
    final store = ExtScope.of(context);
    final id = widget.installed?.id ?? widget.entry?.id;
    if (id == null) return;
    try {
      final s = await store.getSettings(id);
      if (mounted) setState(() => _settings = s);
    } catch (_) {
      // Settings are optional; the form simply stays hidden.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final store = ExtScope.of(context);
    final entry = widget.entry;
    final installed =
        widget.installed ?? (entry != null ? store.get(entry.id) : null);
    final m = installed?.manifest ?? _syntheticManifest;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final live = store.get(m.id) ?? installed;
        return Screen(
          title: m.name,
          children: [
            _header(context, m, entry),
            const SizedBox(height: 16),
            Group(children: [
              Tile(
                title: s.extAuthor,
                trailing: Text(m.author.name, style: Styles.body.copyWith(color: palette.ink2)),
              ),
              if (entry != null) ...[
                // Like the cards: missing data is no row, never a fake
                // 0.0 rating or a "0 installs" line.
                if (entry.rating > 0)
                  Tile(
                    title: s.extRating,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StarRating(rating: entry.rating),
                        const SizedBox(width: 6),
                        Icon(Symbols.info_rounded,
                            size: 16, color: palette.ink3),
                      ],
                    ),
                    // The published rating methodology, in plain language.
                    onTap: () => showRatingHowDialog(context),
                  ),
                if (entry.installs > 0)
                  Tile(
                    title: s.extInstalls,
                    trailing: Text('${entry.installs}',
                        style: Styles.body.copyWith(color: palette.ink2)),
                  ),
              ],
              Tile(
                title: s.extVersion,
                trailing:
                    Text(m.version, style: Styles.body.copyWith(color: palette.ink2)),
              ),
            ]),
            if (entry != null && entry.screenshotUrls.isNotEmpty) ...[
              Heading(s.extScreenshots),
              _ScreenshotsCarousel(urls: entry.screenshotUrls),
              const SizedBox(height: 16),
            ],
            if (entry != null && entry.changelog.isNotEmpty) ...[
              Heading(s.extChangelog),
              Group(children: [
                for (final c in entry.changelog)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(c.version,
                                style: Styles.bodyStrong
                                    .copyWith(color: palette.ink)),
                            const SizedBox(width: 8),
                            Text(
                                DateFormat.yMMMd(Localizations.localeOf(context)
                                        .toLanguageTag())
                                    .format(c.date.toLocal()),
                                style: Styles.caption
                                    .copyWith(color: palette.ink3)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(c.notes,
                            style:
                                Styles.body.copyWith(color: palette.ink2)),
                      ],
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
            ],
            if (m.description.isNotEmpty) ...[
              Heading(s.extAbout),
              Group(children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(m.description,
                      style: Styles.body.copyWith(color: palette.ink)),
                ),
              ]),
            ],
            Heading(s.extPermissionsTitle),
            Group(children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.permissions.isEmpty)
                      Text(s.extNoPermissions,
                          style: Styles.body.copyWith(color: palette.ink2))
                    else
                      for (final p in m.permissions) ...[
                        PermissionRow(
                          blurb: permissionBlurb(context, p),
                          risk: lookupPermission(p)?.risk ?? ExtRisk.normal,
                        ),
                        // Same honesty marker as the install prompt: a
                        // permission whose runtime is not built must say
                        // so here too, not only before the grant.
                        if (isNotYetActive(p))
                          Padding(
                            padding: const EdgeInsets.only(left: 28, bottom: 4),
                            child: Text(s.extPermNotYetActive,
                                style: Styles.caption
                                    .copyWith(color: palette.ink2)),
                          ),
                        if (isNetworkPermission(p) && m.networkHosts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 28, bottom: 4),
                            child: NetworkHostsList(hosts: m.networkHosts),
                          ),
                      ],
                  ],
                ),
              ),
            ]),
            if (live != null && _hasBackgroundTask(live)) ...[
              Heading(s.extBgTitle),
              _BackgroundTaskSection(extensionId: live.id, interactive: live.enabled),
            ],
            // Every declared panel gets its own row: with several panels a
            // single "open" button would silently pick the first one.
            if (live != null && live.enabled && m.panels.isNotEmpty) ...[
              Heading(s.extCapPanel),
              Group(children: [
                for (final p in m.panels)
                  LinkTile(
                    title: p.title,
                    onTap: () => push<void>(
                        context,
                        ExtensionPanelScreen(
                            extensionId: live.id, panelId: p.id)),
                  ),
              ]),
            ],
            if (live != null && _settings != null && m.settingsSchema != null) ...[
              Heading(s.extSettings),
              _SettingsForm(
                manifest: m,
                values: _settings!,
                saving: _saving,
                onChanged: (k, v) => setState(() => _settings![k] = v),
                onSave: () => _saveSettings(m.id),
              ),
            ],
            const SizedBox(height: 8),
            _actions(context, store, m, live, entry),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context, ExtManifest m, CatalogEntry? entry) {
    final s = S.of(context), palette = Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.field),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: palette.field.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Symbols.extension_rounded, color: palette.ink2, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: Styles.heading.copyWith(color: palette.ink)),
                const SizedBox(height: 2),
                Text(s.extByAuthor(m.author.name),
                    style: Styles.caption.copyWith(color: palette.ink2)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (entry != null) ...[
                      if (entry.rating > 0) StarRating(rating: entry.rating),
                      ...catalogBadges(context, entry),
                    ] else if (widget.installed?.source != 'catalog')
                      ExtBadge(
                          label: s.extSideloadShort,
                          tone: ExtBadgeTone.warn,
                          icon: Symbols.warning_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, ExtensionStore store, ExtManifest m,
      InstalledExtension? live, CatalogEntry? entry) {
    final s = S.of(context);
    if (live == null) {
      // Not installed: install straight from the detail screen.
      return PrimaryButton(
        label: s.extInstall,
        onTap: entry == null ? null : () => widget.onInstall?.call(entry),
      );
    }
    final needsUpdate = entry != null &&
        compareVersions(entry.version, live.version) > 0 &&
        entry.rolloutEligible(store.installId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (needsUpdate) ...[
          const SizedBox(height: 8),
          PrimaryButton(
            label: s.extUpdateTo(entry.version),
            onTap: () => widget.onInstall?.call(entry),
          ),
        ],
        const SizedBox(height: 8),
        SwitchTile(
          title: s.extEnabled,
          value: live.enabled,
          onChanged: (v) => store.setEnabled(live.id, v),
        ),
        if (live.previous != null) ...[
          const SizedBox(height: 8),
          _QuietButton(
            label: s.extRollbackTo(live.previous!),
            icon: Symbols.history_rounded,
            onTap: () => _confirm(context, s.extRollbackConfirm(live.previous!),
                () => store.rollback(live.id)),
          ),
        ],
        const SizedBox(height: 8),
        _QuietButton(
          label: s.extUninstall,
          icon: Symbols.delete_rounded,
          danger: true,
          onTap: () => _confirm(context, s.extUninstallConfirm(m.name), () async {
            await store.uninstall(live.id);
            if (context.mounted) Navigator.pop(context);
          }),
        ),
      ],
    );
  }

  Future<void> _confirm(
      BuildContext context, String message, Future<void> Function() action) async {
    final s = S.of(context), palette = Palette.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: palette.raised,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(message, style: Styles.body.copyWith(color: palette.ink)),
                const SizedBox(height: 16),
                PrimaryButton(
                    label: s.extConfirm, onTap: () => Navigator.pop(context, true)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(s.extCancel, style: TextStyle(color: palette.ink2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      try {
        await action();
      } catch (_) {
        // Lifecycle edge cases (disk, registry) must not fail silently: the
        // confirm dialog is already gone, so say what happened.
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(s.extErrGeneric)));
        }
      }
    }
  }

  Future<void> _saveSettings(String id) async {
    final store = ExtScope.of(context);
    setState(() => _saving = true);
    try {
      await store.setSettings(id, _settings!);
    } catch (_) {
      // The form only produces type-correct values, so this is a persistence
      // failure: say so and re-read the stored values instead of leaving the
      // form showing values that were never saved.
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(S.of(context).extErrGeneric)));
        unawaited(_loadSettings());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton(
      {required this.label, required this.icon, required this.onTap, this.danger = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    // Button role for screen readers; the visible text is the label.
    return Semantics(
      button: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          // minHeight keeps large text scales from clipping the label.
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: palette.field),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: danger ? palette.danger : palette.ink2),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    style: danger ? Styles.dangerStrong(context) : Styles.bodyStrong),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings form auto-generated from settings_schema.
class _SettingsForm extends StatelessWidget {
  const _SettingsForm({
    required this.manifest,
    required this.values,
    required this.saving,
    required this.onChanged,
    required this.onSave,
  });
  final ExtManifest manifest;
  final Map<String, dynamic> values;
  final bool saving;
  final void Function(String key, dynamic value) onChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final props =
        (manifest.settingsSchema?['properties'] as Map<String, dynamic>?) ?? {};
    return Group(children: [
      for (final e in props.entries) _field(context, e.key, e.value as Map<String, dynamic>),
      Padding(
        padding: const EdgeInsets.all(12),
        child: PrimaryButton(label: s.extSaveSettings, onTap: saving ? null : () => onSave()),
      ),
      if (saving)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Center(
              child: Text(s.extSaving, style: Styles.caption.copyWith(color: palette.ink2))),
        ),
    ]);
  }

  Widget _field(BuildContext context, String key, Map<String, dynamic> prop) {
    final type = prop['type'] as String?;
    final value = values[key];
    final label = (prop['title'] as String?) ?? key;
    switch (type) {
      case 'boolean':
        return SwitchTile(
          title: label,
          value: value == true,
          onChanged: (v) => onChanged(key, v),
        );
      case 'string':
        final en = prop['enum'] as List?;
        if (en != null) {
          final current = value?.toString() ?? '';
          return ChoiceTile<String>(
            title: label,
            value: current,
            choices: {for (final o in en) o.toString(): o.toString()},
            onChanged: (v) => onChanged(key, v),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: TextFormField(
            key: ValueKey('ext-setting-$key'),
            initialValue: value?.toString() ?? '',
            decoration: InputDecoration(labelText: label),
            onChanged: (v) => onChanged(key, v),
          ),
        );
      case 'integer':
      case 'number':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: TextFormField(
            key: ValueKey('ext-setting-$key'),
            initialValue: value?.toString() ?? '',
            decoration: InputDecoration(labelText: label),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final n = type == 'integer' ? int.tryParse(v) : double.tryParse(v);
              if (n != null) onChanged(key, n);
            },
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// True when the extension declares a background task. Only then can the
/// runtime actually schedule one: it needs the `background` capability and
/// permission plus a declared `background_task`, which the manifest
/// validator already ties together. Gating on the declaration (rather than
/// the capability/permission alone) keeps the section from offering
/// controls for a task that could never run.
bool _hasBackgroundTask(InstalledExtension inst) =>
    inst.manifest.backgroundTask != null;

/// Background task management for one installed extension: on/off plus the
/// run interval, clamped by [BackgroundTaskConfig] to what the platform
/// allows. Applies immediately, like the enable switch above it.
class _BackgroundTaskSection extends StatefulWidget {
  const _BackgroundTaskSection({required this.extensionId, required this.interactive});
  final String extensionId;

  /// False when the extension itself is disabled: the task cannot run, so
  /// the controls are read-only until it is enabled again.
  final bool interactive;

  @override
  State<_BackgroundTaskSection> createState() => _BackgroundTaskSectionState();
}

class _BackgroundTaskSectionState extends State<_BackgroundTaskSection> {
  BackgroundTaskConfig? _config;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_config == null) _load();
  }

  Future<void> _load() async {
    final store = ExtScope.of(context);
    try {
      final c = await store.getBackgroundTask(widget.extensionId);
      if (mounted) setState(() => _config = c);
    } catch (_) {
      // A missing config simply means defaults; the section stays usable.
      if (mounted) setState(() => _config = BackgroundTaskConfig.defaults());
    }
  }

  Future<void> _apply(BackgroundTaskConfig next) async {
    final store = ExtScope.of(context);
    final prev = _config;
    setState(() {
      _config = next;
      _busy = true;
    });
    try {
      await store.setBackgroundTask(widget.extensionId, next);
    } catch (_) {
      // Revert the optimistic update and say so; a silent failure would
      // leave the user believing the task was reconfigured.
      if (!mounted) return;
      setState(() {
        _config = prev;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).extErrGeneric)),
      );
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  Map<int, String> _intervalChoices(BuildContext context, int current) {
    final s = S.of(context);
    final choices = <int, String>{
      15: s.extBgMinutes(15),
      30: s.extBgMinutes(30),
      60: s.extBgHours(1),
      360: s.extBgHours(6),
      720: s.extBgHours(12),
      1440: s.extBgHours(24),
    };
    // A hand-edited config file may hold a non-preset interval; show it
    // honestly instead of a blank row.
    choices.putIfAbsent(current, () => s.extBgMinutes(current));
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final config = _config;
    final editable = widget.interactive && !_busy;
    return Group(children: [
      // Honest status, not a fake runner: the switch below persists the
      // user's schedule (<id>.background.json, the runtime contract), but
      // no background runtime executes it in this build — the scheduler is
      // never started and the worker script has no executor yet. The badge
      // says so instead of letting the toggle pretend otherwise.
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ExtBadge(
            label: s.extBgRuntimeBadge,
            tone: ExtBadgeTone.warn,
            icon: Symbols.info_rounded,
          ),
        ),
      ),
      if (config == null)
        const Padding(
          padding: EdgeInsets.all(14),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        )
      else ...[
        SwitchTile(
          title: s.extBgEnabled,
          value: config.enabled,
          onChanged: editable
              ? (v) => _apply(BackgroundTaskConfig(
                  enabled: v, intervalMinutes: config.intervalMinutes))
              : null,
        ),
        _intervalTile(config, editable),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
          child: Text(
            widget.interactive ? s.extBgNote : s.extBgDisabledNote,
            style: Styles.caption.copyWith(color: palette.ink2),
          ),
        ),
      ],
    ]);
  }

  /// The run-interval row. [ChoiceTile.onChanged] is non-nullable, so a
  /// read-only section absorbs the taps instead of receiving a null
  /// callback; the note below explains why the controls are inert.
  Widget _intervalTile(BackgroundTaskConfig config, bool editable) {
    final tile = ChoiceTile<int>(
      title: S.of(context).extBgInterval,
      value: config.intervalMinutes,
      choices: _intervalChoices(context, config.intervalMinutes),
      onChanged: (v) => _apply(BackgroundTaskConfig(
          enabled: config.enabled, intervalMinutes: v)),
    );
    return editable ? tile : AbsorbPointer(child: tile);
  }
}

/// Screenshot carousel for the extension detail page: a horizontally
/// swipable strip of the catalog's screenshot URLs. A failed image is an
/// honest placeholder (extImageFailed), never a blank hole or a crash.
class _ScreenshotsCarousel extends StatefulWidget {
  const _ScreenshotsCarousel({required this.urls});
  final List<String> urls;

  @override
  State<_ScreenshotsCarousel> createState() => _ScreenshotsCarouselState();
}

class _ScreenshotsCarouselState extends State<_ScreenshotsCarousel> {
  final _controller = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context), s = S.of(context);
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.urls.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: palette.field.withValues(alpha: 0.6),
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.broken_image_rounded, color: palette.ink3),
                      const SizedBox(height: 6),
                      Text(s.extImageFailed,
                          style:
                              Styles.caption.copyWith(color: palette.ink2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
