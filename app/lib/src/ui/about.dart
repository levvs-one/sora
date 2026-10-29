import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoSearchTextField;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/logo.dart';
import '../design/theme.dart';
import '../desktop/desktop.dart';
import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import '../sora.dart';
import '../notifications.dart';
import '../updates.dart';
import 'kit.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  About? _about;
  late final AppUpdater _updates = SoraScope.read(context).updates;
  UpdateError? _reportedError;

  @override
  void initState() {
    super.initState();
    _updates.addListener(_updateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateChanged();
      unawaited(_load());
    });
  }

  @override
  void dispose() {
    _updates.removeListener(_updateChanged);
    super.dispose();
  }

  void _updateChanged() {
    final error = _updates.error;
    if (!mounted || error == _reportedError) return;
    _reportedError = error;
    if (error == null) return;
    final s = S.of(context);
    unawaited(
      SoraScope.read(context).recordNotification(
        AppNotification(
          time: DateTime.now(),
          title: s.updates,
          body: switch (error) {
            UpdateError.network => s.updateNetworkError,
            UpdateError.release => s.updateReleaseError,
            UpdateError.checksum => s.updateChecksumError,
            UpdateError.installation => s.updateInstallError,
            UpdateError.connecting => s.updateWaitConnection,
            UpdateError.unsupported => s.updateUnsupported,
            UpdateError.rollback => s.updateRollbackError,
            UpdateError.rollbackCache => s.updateRollbackCacheError,
          },
        ),
      ),
    );
  }

  Future<void> _load({FailureMode mode = FailureMode.background}) async {
    final link = SoraScope.read(context).link;
    if (link == null) return;
    try {
      final answer = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
      if (answer.hasError()) throw CoreFailure.fromWire(answer.error);
      if (mounted) {
        SoraScope.read(context).recovered('about');
        setState(() => _about = answer.about);
      }
    } catch (error) {
      if (mounted) SoraScope.read(context).reportFailure(error, source: 'about', mode: mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final about = _about;
    final sora = SoraScope.of(context);
    final updates = sora.updates;
    final release = updates.latest;
    final desktop = DesktopScope.maybeOf(context);
    final canInstall = !sora.busy && sora.phase != Phase.reconnecting && sora.phase != Phase.offline;
    final updateButton = TextButton.icon(
      key: const ValueKey('check-app-updates'),
      onPressed: updates.checking || updates.busy ? null : () => unawaited(updates.check(manual: true)),
      icon: updates.checking
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Symbols.system_update_alt_rounded, size: 20, weight: 600),
      label: Text(s.updateCheck),
    );
    final updateTitle = Text(
      updates.hasUpdate
          ? s.updateAvailable(release!.version)
          : updates.installed
          ? s.updateInstalled
          : s.updates,
      style: Styles.body.copyWith(color: palette.ink),
    );
    return Screen(
      title: s.about,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 32, 12, 32),
          child: Column(
            children: [
              SoraMark(size: 48, color: palette.ink),
              const SizedBox(height: 12),
              Text('Sora', style: Styles.title.copyWith(color: palette.ink)),
              const SizedBox(height: 4),
              Text(s.appVersion(updates.version), style: Styles.secondary.copyWith(color: palette.ink2)),
            ],
          ),
        ),
        Group(
          children: [
            // Persistent, non-alarming notice when the installed
            // version was recalled via the rollout policy's blocked_versions.
            if (updates.versionRevoked)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Text(s.updateVersionRevoked, style: Styles.secondary.copyWith(color: palette.ink)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: LayoutBuilder(
                builder: (_, constraints) => constraints.maxWidth >= 480
                    ? Row(
                        children: [
                          Expanded(child: updateTitle),
                          const SizedBox(width: 12),
                          updateButton,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [updateTitle, const SizedBox(height: 8), updateButton],
                      ),
              ),
            ),
            // A newer release exists but this install's cohort is not
            // included in the staged rollout yet: say so instead
            // of silently showing nothing.
            if (updates.rolloutPending && !updates.hasUpdate)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(s.updateRolloutPending, style: Styles.secondary.copyWith(color: palette.ink)),
              ),
            if (release != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.updateNotes(release.version), style: Styles.bodyStrong.copyWith(color: palette.ink)),
                    const SizedBox(height: 8),
                    if (release.notes.isEmpty)
                      Text(s.updateNoNotes, style: Styles.secondary.copyWith(color: palette.ink))
                    else
                      MarkdownBody(
                        key: const ValueKey('release-notes'),
                        data: release.notes,
                        selectable: true,
                        imageBuilder: (_, _, alt) =>
                            Text(alt ?? '', style: Styles.secondary.copyWith(color: palette.ink)),
                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                          p: Styles.secondary.copyWith(color: palette.ink),
                          a: Styles.secondary.copyWith(color: palette.ink, decoration: TextDecoration.underline),
                          h1: Styles.heading.copyWith(color: palette.ink),
                          h2: Styles.bodyStrong.copyWith(color: palette.ink),
                          h3: Styles.bodyStrong.copyWith(color: palette.ink),
                          listBullet: Styles.secondary.copyWith(color: palette.ink),
                          code: Styles.caption.copyWith(color: palette.ink),
                        ),
                        onTapLink: (_, href, _) {
                          if (href != null) unawaited(openLink(context, href));
                        },
                      ),
                  ],
                ),
              ),
            ],
            if (updates.hasUpdate)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      key: const ValueKey('install-update'),
                      label: s.refresh,
                      busy: updates.busy,
                      onTap: canInstall && desktop != null
                          ? () => unawaited(
                              updates.install(
                                confirmDrop: () {
                                  // The download can outlive this screen; ask
                                  // on the app-wide navigator so leaving About
                                  // mid-download no longer silently discards
                                  // the verified update (audit M19).
                                  final context = desktop.navigator.currentContext;
                                  if (context == null || !context.mounted) {
                                    return Future.value(false);
                                  }
                                  return confirm(
                                    context,
                                    question: s.updateDropWarning,
                                    action: s.refresh,
                                    destructive: false,
                                  );
                                },
                                launchWindows: desktop.launchUpdate,
                                restartLinux: desktop.restartAfterUpdate,
                                quit: desktop.quit,
                              ),
                            )
                          : null,
                    ),
                    if (updates.busy) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: updates.progress,
                        color: palette.ink,
                        backgroundColor: palette.field,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(switch (updates.stage) {
                              UpdateStage.checking => s.updateChecking,
                              UpdateStage.installing => s.updateInstalling,
                              _ => s.updateDownloading,
                            }, style: Styles.caption.copyWith(color: palette.ink)),
                          ),
                          if (updates.stage == UpdateStage.downloading || updates.stage == UpdateStage.checking)
                            Pressable(
                              onTap: updates.cancel,
                              radius: 8,
                              semanticButton: true,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(s.cancel, style: Styles.caption.copyWith(color: palette.ink)),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (!canInstall) ...[
                      const SizedBox(height: 8),
                      Text(s.updateWaitConnection, style: Styles.secondary.copyWith(color: palette.ink)),
                    ],
                  ],
                ),
              ),
            // Automatic rollback status. The notice survives the
            // restart the rollback performs (persisted in settings).
            if (updates.rollbackTarget case final target? when updates.rollbackBusy)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(s.updateRollbacking(target), style: Styles.secondary.copyWith(color: palette.ink)),
              ),
            if (updates.lastRollback case final notice?)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.updateRolledBack(notice.to, notice.from),
                      style: Styles.secondary.copyWith(color: palette.ink),
                    ),
                    const SizedBox(height: 8),
                    Pressable(
                      onTap: () => unawaited(updates.dismissRollbackNotice()),
                      radius: 8,
                      semanticButton: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(s.close, style: Styles.secondary.copyWith(color: palette.ink)),
                      ),
                    ),
                  ],
                ),
              ),
            if (updates.manualCommand case final command?)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Tile(title: s.updateManual),
                    const SizedBox(height: 8),
                    SelectableText(
                      command,
                      key: const ValueKey('update-command'),
                      style: Styles.caption.copyWith(color: palette.ink),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: command));
                      },
                      child: Text(s.updateCopyCommand),
                    ),
                  ],
                ),
              ),
            if (!updates.checking && release == null && !sora.settings.checkUpdates)
              Tile(title: s.updateChecksDisabled),
          ],
        ),
        BackgroundFailureState(
          source: 'about',
          retry: () => unawaited(_load(mode: FailureMode.action)),
        ),
        if (about != null) ...[
          Group(
            children: [
              Tile(title: s.engine, trailing: _value(context, 'Sora ${about.coreVersion}')),
              for (final e in about.engines)
                Tile(
                  title: switch (e.kind) {
                    'xray' => 'Xray',
                    _ => e.kind,
                  },
                  trailing: _value(context, e.installed ? e.version : s.notInstalled),
                ),
            ],
          ),
        ],
        Heading(s.projectLinks),
        Group(
          children: [
            LinkTile(
              title: s.githubReleases,
              value: 'GitHub',
              onTap: () => unawaited(openLink(context, 'https://github.com/levvs-one/sora/releases')),
            ),
            LinkTile(
              title: s.telegramChannel,
              value: '@sora_client',
              onTap: () => unawaited(openLink(context, 'https://t.me/sora_client')),
            ),
            LinkTile(
              title: s.sourceCode,
              value: 'GitHub',
              onTap: () => unawaited(openLink(context, 'https://github.com/levvs-one/sora')),
            ),
            // The issue form prefills its version field from the query.
            LinkTile(
              title: s.reportProblem,
              value: 'GitHub',
              onTap: () => unawaited(
                openLink(
                  context,
                  'https://github.com/levvs-one/sora/issues/new?template=01_bug_report.yml'
                  '&version=${Uri.encodeQueryComponent(updates.version)}',
                ),
              ),
            ),
          ],
        ),
        Heading(s.licenses),
        Group(
          children: [
            Tile(title: 'Sora', trailing: _value(context, 'GPL-3.0-only')),
            LinkTile(title: s.componentLicenses, onTap: () => unawaited(push(context, const _LicensesScreen()))),
          ],
        ),
      ],
    );
  }

  Widget _value(BuildContext context, String text) =>
      Text(text, style: Styles.secondary.copyWith(color: Palette.of(context).ink));
}

class _LicensesScreen extends StatefulWidget {
  const _LicensesScreen();

  @override
  State<_LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<_LicensesScreen> {
  final _search = TextEditingController();
  late Future<Map<String, List<LicenseEntry>>> _licenses = _load();

  Future<Map<String, List<LicenseEntry>>> _load() =>
      LicenseRegistry.licenses.fold(<String, List<LicenseEntry>>{}, (components, entry) {
        for (final name in entry.packages) {
          (components[name] ??= []).add(entry);
        }
        return components;
      });

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    return Screen(
      title: s.componentLicenses,
      fill: FutureBuilder(
        future: _licenses,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _licenses = _load()),
                icon: const Icon(Symbols.refresh_rounded),
                label: Text('${s.errGeneric}. ${s.refresh}'),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          // The component list listens to the search field through a
          // ValueListenableBuilder, so typing rebuilds only the list, not
          // the whole licenses screen (the program-picker pattern).
          return ValueListenableBuilder<TextEditingValue>(
            valueListenable: _search,
            builder: (context, value, _) {
              final query = value.text.trim().toLowerCase();
              // Lowercased keys are computed once per pass, not once per
              // filter candidate and again per sort comparison (the
              // benchmark screen's sort-keys pattern). The comparator's
              // values are unchanged, so the order (Sora first, then
              // case-insensitive) is identical.
              final lower = {for (final name in data.keys) name: name.toLowerCase()};
              final names = data.keys.where((name) => lower[name]!.contains(query)).toList()
                ..sort(
                  (a, b) => a == b
                      ? 0
                      : a == 'Sora'
                      ? -1
                      : b == 'Sora'
                      ? 1
                      : lower[a]!.compareTo(lower[b]!),
                );
              if (names.isEmpty) {
                return Center(
                  child: Text(s.speedtestEmpty, style: Styles.secondary.copyWith(color: palette.ink)),
                );
              }
              return Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).width < 720 ? 72 : 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: palette.surface,
                    child: ListView.separated(
                      key: const ValueKey('license-components'),
                      padding: const EdgeInsets.all(4),
                      itemCount: names.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, thickness: 0.5, indent: 12, endIndent: 12, color: palette.field),
                      itemBuilder: (_, i) => LinkTile(
                        key: ValueKey('license-${names[i]}'),
                        title: names[i],
                        onTap: () => unawaited(push(context, _LicenseText(name: names[i], entries: data[names[i]]!))),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      children: [
        CupertinoSearchTextField(
          key: const ValueKey('license-search'),
          controller: _search,
          placeholder: s.search,
          style: Styles.body.copyWith(color: palette.ink),
          placeholderStyle: Styles.body.copyWith(color: palette.ink3),
          backgroundColor: palette.field,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          itemColor: palette.ink3,
          // No onChanged setState: the list above listens through
          // ValueListenableBuilder on [_search].
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _LicenseText extends StatefulWidget {
  const _LicenseText({required this.name, required this.entries});
  final String name;
  final List<LicenseEntry> entries;

  @override
  State<_LicenseText> createState() => _LicenseTextState();
}

class _LicenseTextState extends State<_LicenseText> {
  // Long GPL/MPL texts are parsed off the UI isolate, only after selection.
  static List<LicenseParagraph> _paragraphs(List<LicenseEntry> entries) => [
    for (final entry in entries) ...entry.paragraphs,
  ];

  late final _text = compute(_paragraphs, widget.entries);

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Screen(
      title: widget.name,
      fill: FutureBuilder(
        future: _text,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(S.of(context).errGeneric, style: Styles.body));
          final paragraphs = snapshot.data;
          if (paragraphs == null) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).width < 720 ? 72 : 20),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SelectionArea(
                  child: ListView.separated(
                    key: const ValueKey('license-text'),
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
                    itemCount: paragraphs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final paragraph = paragraphs[i];
                      final centered = paragraph.indent == LicenseParagraph.centeredIndent;
                      return Padding(
                        padding: EdgeInsetsDirectional.only(start: centered ? 0 : paragraph.indent.clamp(0, 4) * 12.0),
                        child: Text(
                          paragraph.text,
                          textAlign: centered ? TextAlign.center : TextAlign.start,
                          style: Styles.secondary.copyWith(color: palette.ink, height: 1.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
      children: const [],
    );
  }
}
