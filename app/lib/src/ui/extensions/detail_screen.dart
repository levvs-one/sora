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
import '../modes.dart';
import '../../ext/catalog.dart';
import '../../ext/enforcement.dart';
import '../../ext/manifest.dart';
import '../../ext/permissions.dart';
import '../../ext/store.dart';
import '../../rules.dart';
import '../../sora.dart';
import '../../ext/bypass.dart';
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
      publicKey: widget.entry!.authorKey,
    ),
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
    final installed = widget.installed ?? (entry != null ? store.get(entry.id) : null);
    final m = installed?.manifest ?? _syntheticManifest;
    return AnimatedBuilder(
      animation: Listenable.merge([store, store.logChanges]),
      builder: (context, _) {
        final live = store.get(m.id) ?? installed;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: RoundButton(
                      icon: Symbols.chevron_left_rounded,
                      label: MaterialLocalizations.of(context).backButtonTooltip,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        children: [
                          _header(context, m, entry),
                          const SizedBox(height: 24),
                          _actions(context, store, m, live, entry),
                          if (m.description.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(m.description, style: Styles.body.copyWith(fontSize: 14, color: palette.ink)),
                          ],
                          _SectionHeading(s.extPermissionsTitle),
                          Group(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (m.permissions.isEmpty)
                                      Text(s.extNoPermissions, style: Styles.body.copyWith(color: palette.ink))
                                    else
                                      for (final p in m.permissions) ...[
                                        PermissionRow(
                                          blurb: permissionBlurb(context, p),
                                          risk: lookupPermission(p)?.risk ?? ExtRisk.normal,
                                        ),
                                        // Same marker as the install prompt: a
                                        // permission whose runtime is not built must say
                                        // so here too, not only before the grant.
                                        if (isNotYetActive(p) ||
                                            (p == 'net.hooks' &&
                                                live != null &&
                                                live.manifest.networkHookEntry == null))
                                          Padding(
                                            padding: const EdgeInsets.only(left: 28, bottom: 4),
                                            child: Text(
                                              s.extPermNotYetActive,
                                              style: Styles.caption.copyWith(color: palette.ink),
                                            ),
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
                            ],
                          ),
                          if (entry != null && entry.changelog.length > 1) ...[
                            _SectionHeading(s.extChangelog),
                            for (final c in entry.changelog)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.version,
                                          style: Styles.bodyStrong.copyWith(fontSize: 14, color: palette.ink),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
                                              .format(c.date.toLocal()),
                                          style: Styles.secondary.copyWith(color: palette.ink2),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(c.notes, style: Styles.body.copyWith(fontSize: 14, color: palette.ink)),
                                  ],
                                ),
                              ),
                          ],
                          if (entry != null && entry.screenshotUrls.isNotEmpty) ...[
                            _SectionHeading(s.extScreenshots),
                            _ScreenshotsCarousel(urls: entry.screenshotUrls),
                          ],
                          if (live != null && _hasBackgroundTask(live)) ...[
                            _SectionHeading(s.extBgTitle),
                            _BackgroundTaskSection(extensionId: live.id, interactive: live.enabled),
                          ],
                          if (live != null && m.routingEntry != null) ...[
                            _SectionHeading(s.extCapRouting),
                            Column(
                              children: [
                                for (final r in store.routingRules.where((r) => r.extensionId == live.id))
                                  Tile(
                                    title: r.rule.shown,
                                    detail: r.comment.isEmpty ? null : r.comment,
                                    trailing: Text(switch (r.rule.target) {
                                      RuleTarget.direct => s.ruleDirect,
                                      RuleTarget.proxy => s.ruleProxy,
                                      RuleTarget.block => s.ruleBlock,
                                    }, style: Styles.secondary.copyWith(color: palette.ink)),
                                  ),
                                Tile(
                                  title:
                                      live.enabled &&
                                          live.granted.contains('routing.rules') &&
                                          !store.runtimeErrors.containsKey(live.id)
                                      ? s.extEnabled
                                      : s.extDisabled,
                                ),
                              ],
                            ),
                          ],
                          if (live != null && store.runtimeLog(live.id).isNotEmpty) ...[
                            _SectionHeading(s.logs),
                            Column(
                              children: [
                                for (final line in store.runtimeLog(live.id))
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(line, style: Styles.caption.copyWith(color: palette.ink)),
                                  ),
                              ],
                            ),
                          ],
                          // Every declared panel gets its own row: with several panels a
                          // single "open" button would silently pick the first one.
                          if (live != null && live.enabled && m.panels.length > 1) ...[
                            _SectionHeading(s.extCapPanel),
                            Column(
                              children: [
                                for (final p in m.panels)
                                  LinkTile(
                                    title: p.title,
                                    onTap: () =>
                                        push<void>(context, ExtensionPanelScreen(extensionId: live.id, panelId: p.id)),
                                  ),
                              ],
                            ),
                          ],
                          if (live != null && _settings != null && m.settingsSchema != null) ...[
                            _SectionHeading(s.extSettings),
                            _SettingsForm(
                              manifest: m,
                              values: _settings!,
                              saving: _saving,
                              onChanged: (k, v) => setState(() => _settings![k] = v),
                              onSave: () => _saveSettings(m.id),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, ExtManifest m, CatalogEntry? entry) {
    final palette = Palette.of(context);
    final live = ExtScope.of(context).get(m.id) ?? widget.installed;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: palette.field, borderRadius: BorderRadius.circular(14)),
          child: Icon(Symbols.extension_rounded, color: palette.ink2, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExtensionName(
                name: m.name,
                verified: live == null ? (entry?.badges.contains('staff') ?? false) : isTeamExtension(live),
              ),
              const SizedBox(height: 4),
              Text('${m.author.name}, ${m.version}', style: Styles.secondary.copyWith(color: palette.ink2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actions(
    BuildContext context,
    ExtensionStore store,
    ExtManifest m,
    InstalledExtension? live,
    CatalogEntry? entry,
  ) {
    final s = S.of(context);
    final compatibility = entry == null ? null : catalogCompatibilityText(s, entry);
    if (live == null && compatibility != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(s.extInstall, style: Styles.bodyStrong.copyWith(color: Palette.of(context).ink)),
          ),
          InfoButton(title: s.extInstall, description: compatibility),
        ],
      );
    }
    if (live == null) {
      // Not installed: install straight from the detail screen.
      return PrimaryButton(label: s.extInstall, onTap: entry == null ? null : () => widget.onInstall?.call(entry));
    }
    final needsUpdate =
        entry != null && compareVersions(entry.version, live.version) > 0 && entry.rolloutEligible(store.installId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (needsUpdate) ...[
          const SizedBox(height: 8),
          if (compatibility != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    s.extUpdateTo(entry.version),
                    style: Styles.bodyStrong.copyWith(color: Palette.of(context).ink),
                  ),
                ),
                InfoButton(title: s.extUpdateTo(entry.version), description: compatibility),
              ],
            )
          else
            PrimaryButton(label: s.extUpdateTo(entry.version), onTap: () => widget.onInstall?.call(entry)),
        ],
        if (live.enabled && m.panels.length == 1) ...[
          if (needsUpdate)
            _QuietButton(
              label: s.extOpen,
              icon: Symbols.open_in_new_rounded,
              onTap: () => push<void>(context, ExtensionPanelScreen(extensionId: live.id, panelId: m.panels.single.id)),
            )
          else
            PrimaryButton(
              label: s.extOpen,
              onTap: () => push<void>(context, ExtensionPanelScreen(extensionId: live.id, panelId: m.panels.single.id)),
            ),
          const SizedBox(height: 12),
        ],
        if (store.bypassProfile('$extensionBypassPrefix${live.id}') != null) ...[
          PrimaryButton(label: s.trayConnect, busy: _saving, onTap: _saving ? null : () => _connectBypass(live.id)),
          const SizedBox(height: 12),
        ],
        SwitchTile(
          title: s.extEnabled,
          value: live.enabled,
          onChanged: (v) => toggleExtension(context, store, live.id, v),
        ),
        if (live.previous != null) ...[
          const SizedBox(height: 8),
          _QuietButton(
            label: s.extRollbackTo(live.previous!),
            icon: Symbols.history_rounded,
            onTap: () => _confirm(context, s.extRollbackConfirm(live.previous!), () => store.rollback(live.id)),
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

  Future<void> _confirm(BuildContext context, String message, Future<void> Function() action) async {
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
                PrimaryButton(label: s.extConfirm, onTap: () => Navigator.pop(context, true)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(s.extCancel, style: TextStyle(color: palette.ink)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      if (!context.mounted) return;
      try {
        final sora = context.getInheritedWidgetOfExactType<SoraScope>()?.notifier;
        await action();
        sora?.applyConnectionChanges();
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

  Future<void> _connectBypass(String id) async {
    final store = ExtScope.of(context);
    setState(() => _saving = true);
    try {
      if (!await ensureSystemFilterConsent(context, '$extensionBypassPrefix$id') || !mounted) return;
      await store.setSettings(id, _settings ?? await store.getSettings(id));
      final profile = store.bypassProfile('$extensionBypassPrefix$id');
      if (profile == null) throw ExtAssetError('bypass profile is unavailable');
      if (!mounted) return;
      final sora = SoraScope.read(context);
      await sora.change((settings) => settings.tunnel = 'tun', replan: false);
      await sora.select(profile.choiceId);
      sora.applyConnectionChanges();
      if (sora.selected == profile.choiceId && (sora.phase == Phase.off || sora.phase == Phase.offline)) {
        await sora.connect();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).extAssetRejected)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSettings(String id) async {
    final sora = context.getInheritedWidgetOfExactType<SoraScope>()?.notifier;
    final store = ExtScope.of(context);
    setState(() => _saving = true);
    try {
      await store.setSettings(id, _settings!);
      sora?.applyConnectionChanges();
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(text, style: Styles.bodyStrong.copyWith(fontSize: 14, color: Palette.of(context).ink)),
  );
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.label, required this.icon, required this.onTap, this.danger = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: danger ? palette.danger : palette.ink,
        minimumSize: const Size(44, 44),
        textStyle: Styles.secondary.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
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
    final s = S.of(context);
    final props = (manifest.settingsSchema?['properties'] as Map<String, dynamic>?) ?? {};
    return Column(
      children: [
        for (final e in props.entries) _field(context, e.key, e.value as Map<String, dynamic>),
        Padding(
          padding: const EdgeInsets.all(12),
          child: PrimaryButton(label: s.extSaveSettings, busy: saving, onTap: saving ? null : () => onSave()),
        ),
      ],
    );
  }

  Widget _field(BuildContext context, String key, Map<String, dynamic> prop) {
    final type = prop['type'] as String?;
    final value = values[key];
    final label = (prop['title'] as String?) ?? key;
    switch (type) {
      case 'boolean':
        return SwitchTile(title: label, value: value == true, onChanged: (v) => onChanged(key, v));
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
bool _hasBackgroundTask(InstalledExtension inst) => inst.manifest.backgroundTask != null;

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).extErrGeneric)));
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
    // instead of a blank row.
    choices.putIfAbsent(current, () => s.extBgMinutes(current));
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final config = _config;
    final editable = widget.interactive && !_busy;
    return Column(
      children: [
        if (config == null)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else ...[
          SwitchTile(
            title: s.extBgEnabled,
            value: config.enabled,
            onChanged: editable
                ? (v) => _apply(BackgroundTaskConfig(enabled: v, intervalMinutes: config.intervalMinutes))
                : null,
          ),
          _intervalTile(config, editable),
          if (!widget.interactive)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Text(s.extBgDisabledNote, style: Styles.caption.copyWith(color: palette.ink)),
            ),
        ],
      ],
    );
  }

  /// The run-interval row. [ChoiceTile.onChanged] is non-nullable, so a
  /// read-only section absorbs the taps instead of receiving a null
  /// callback; the note below explains why the controls are inert.
  Widget _intervalTile(BackgroundTaskConfig config, bool editable) {
    final tile = ChoiceTile<int>(
      title: S.of(context).extBgInterval,
      value: config.intervalMinutes,
      choices: _intervalChoices(context, config.intervalMinutes),
      onChanged: (v) => _apply(BackgroundTaskConfig(enabled: config.enabled, intervalMinutes: v)),
    );
    return editable ? tile : AbsorbPointer(child: tile);
  }
}

/// Screenshot carousel for the extension detail page: a horizontally
/// swipable strip of the catalog's screenshot URLs. A failed image is an
/// placeholder (extImageFailed), never a blank hole or a crash.
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
                      Text(s.extImageFailed, style: Styles.caption.copyWith(color: palette.ink)),
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
