/// The extensions section: catalog and installed tabs, search, categories,
/// one-tap install / enable / update. Replaces the "coming soon" stub.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../kit.dart';
import '../../ext/catalog.dart';
import '../../ext/manifest.dart';
import '../../ext/package.dart';
import '../../ext/permissions.dart';
import '../../ext/store.dart';
import '../../ext/verifier.dart';
import 'detail_screen.dart';
import 'permissions_sheet.dart';
import 'widgets.dart';

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen> {
  late final ExtensionStore _store = ExtensionStore();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _store.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ExtScope(
      store: _store,
      child: Screen(
        title: s.extensions,
        actions: [
          RoundButton(
            icon: Symbols.install_desktop_rounded,
            label: s.extInstallFromFile,
            onTap: _ready ? () => _installFromFile(context) : null,
          ),
          RoundButton(
            icon: Symbols.link_rounded,
            label: s.extInstallFromUrl,
            onTap: _ready ? () => _installFromUrl(context) : null,
          ),
        ],
        fill: _ready
            ? const _ExtensionsBody()
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _installFromFile(BuildContext context) async {
    final typeGroup = XTypeGroup(label: 'soraext', extensions: ['soraext']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !context.mounted) return;
    final data = await file.readAsBytes();
    await _installBytes(context, data, source: 'sideload', expectedSha256: null);
  }

  Future<void> _installFromUrl(BuildContext context) async {
    final s = S.of(context);
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        final palette = Palette.of(context);
        return Dialog(
          backgroundColor: palette.raised,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(s.extInstallFromUrl, style: Styles.title.copyWith(color: palette.ink)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(hintText: s.extUrlHint),
                    onSubmitted: (_) => Navigator.pop(context, controller.text.trim()),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: s.extDownload,
                    onTap: () => Navigator.pop(context, controller.text.trim()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (url == null || url.isEmpty || !context.mounted) return;
    if (!url.startsWith('https://')) {
      _showError(context, s.extErrHttpsOnly);
      return;
    }
    try {
      final data = await _downloadCapped(Uri.parse(url), limit: maxPackageBytes)
          .timeout(const Duration(seconds: 60));
      if (!context.mounted) return;
      await _installBytes(context, data, source: 'url', expectedSha256: null);
    } catch (_) {
      if (context.mounted) _showError(context, s.extErrNetwork);
    }
  }

  /// Downloads a .soraext with a hard byte cap enforced while streaming, so
  /// a rogue URL cannot exhaust memory before [ExtPackage.open] runs its own
  /// structural checks. Throws on HTTP errors, timeouts and over-limit
  /// bodies; callers map every failure to a network error.
  static Future<Uint8List> _downloadCapped(Uri url, {required int limit}) async {
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', url));
      if (response.statusCode != 200) throw Exception('http ${response.statusCode}');
      final body = <int>[];
      await for (final chunk in response.stream) {
        body.addAll(chunk);
        if (body.length > limit) throw Exception('download exceeds $limit bytes');
      }
      return Uint8List.fromList(body);
    } finally {
      client.close();
    }
  }

  /// Verifies and installs raw .soraext bytes with the permission prompt.
  Future<void> _installBytes(BuildContext context, Uint8List data,
      {required String source, required String? expectedSha256}) async {
    final s = S.of(context);
    if (!context.mounted) return;
    var progressOpen = false;
    void showProgress(String label) {
      progressOpen = true;
      _showProgress(context, label);
    }

    void hideProgress() {
      if (progressOpen) {
        progressOpen = false;
        if (context.mounted) Navigator.of(context).pop();
      }
    }

    showProgress(s.extVerifying);
    try {
      if (expectedSha256 != null) {
        final ok = _sha256Hex(data) == expectedSha256.toLowerCase();
        if (!ok) throw PackageError('download does not match the catalog sha256');
      }
      final pkg = ExtPackage.open(data);
      await pkg.verify();
      // min_app_version gate against the running app.
      if (_appVersion.isNotEmpty && compareVersions(pkg.manifest.minAppVersion, _appVersion) > 0) {
        throw PackageError('needs app ${pkg.manifest.minAppVersion}');
      }
      hideProgress();
      if (!context.mounted) return;
      // A widening update shows exactly what is new — with the honest
      // "Update" title — instead of the full list under "Install".
      final existing = _store.get(pkg.manifest.id);
      final added = existing == null
          ? null
          : diffPermissions(existing.granted, pkg.manifest.permissions).added;
      final granted = await showInstallPrompt(context,
          manifest: pkg.manifest,
          sideload: source != 'catalog',
          addedPermissions: added == null || added.isEmpty ? null : added);
      if (granted == null || !context.mounted) return;
      showProgress(s.extInstalling);
      try {
        await _store.install(pkg, source: source, granted: granted);
      } finally {
        hideProgress();
      }
    } on PackageError catch (e) {
      hideProgress();
      if (context.mounted) _showError(context, _mapInstallError(context, e.message));
    } on SignatureError {
      hideProgress();
      if (context.mounted) _showError(context, s.extErrSignature);
    } on ManifestError {
      hideProgress();
      if (context.mounted) _showError(context, s.extErrManifest);
    } catch (_) {
      hideProgress();
      if (context.mounted) _showError(context, s.extErrGeneric);
    }
  }

  String _mapInstallError(BuildContext context, String message) {
    final s = S.of(context);
    if (message.contains('sha256')) return s.extErrHash;
    if (message.contains('signature') || message.contains('checksums')) return s.extErrSignature;
    if (message.contains('manifest')) return s.extErrManifest;
    if (message.contains('needs app')) {
      final version = message.replaceFirst('needs app ', '').trim();
      return s.extErrMinApp(version);
    }
    return s.extErrGeneric;
  }

  void _showProgress(BuildContext context, String label) {
    final palette = Palette.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: palette.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(label, style: Styles.body.copyWith(color: palette.ink)),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    final palette = Palette.of(context);
    final s = S.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: palette.raised,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Symbols.error_rounded, color: palette.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.extInstallFailed,
                          style: Styles.title.copyWith(color: palette.ink)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(message, style: Styles.body.copyWith(color: palette.ink2)),
                const SizedBox(height: 16),
                PrimaryButton(label: s.extOk, onTap: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _sha256Hex(Uint8List data) => crypto.sha256.convert(data).toString();
}

/// The running app version for the min_app_version gate, injected at build
/// time with --dart-define=APP_VERSION=x.y.z (see docs/extensions/manifest-v1.md).
/// Empty in dev builds: the gate is skipped rather than enforced against a
/// hardcoded guess.
const String _appVersion = String.fromEnvironment('APP_VERSION');

class _ExtensionsBody extends StatefulWidget {
  const _ExtensionsBody();

  @override
  State<_ExtensionsBody> createState() => _ExtensionsBodyState();
}

class _ExtensionsBodyState extends State<_ExtensionsBody> {
  int _tab = 0;
  ExtensionCatalog? _catalog;
  bool _loading = true;
  bool _catalogSoon = false;
  String? _catalogError;
  String _query = '';
  String _category = 'all';
  int _sort = 0; // 0 popular, 1 rating, 2 name

  @override
  void initState() {
    super.initState();
    _refreshCatalog();
  }

  Future<void> _refreshCatalog() async {
    // The team catalog URL and key are placeholders until the owner completes
    // the signing key ceremony. Show an honest "coming soon" state instead of
    // a permanent network error; sideloading stays fully working.
    if (!teamSigningConfigured) {
      setState(() {
        _loading = false;
        _catalogSoon = true;
        _catalogError = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _catalogError = null;
      _catalogSoon = false;
    });
    try {
      final catalog = await fetchCatalog().timeout(const Duration(seconds: 45));
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
    } on CatalogError catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogError = e.message;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _catalogError = 'timeout';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _catalogError = 'error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Segments<int>(
          value: _tab,
          choices: {0: s.extCatalog, 1: s.extInstalled},
          onChanged: (v) => setState(() => _tab = v),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _tab == 0 ? _buildCatalog(context) : _buildInstalled(context),
        ),
      ],
    );
  }

  Widget _buildCatalog(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_catalogSoon) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.store_rounded, size: 40, color: palette.ink3),
            const SizedBox(height: 12),
            Text(s.extCatalogSoonTitle,
                style: Styles.title.copyWith(color: palette.ink),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(s.extCatalogSoonBody,
                  style: Styles.body.copyWith(color: palette.ink2),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }
    if (_catalogError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.cloud_off_rounded, size: 40, color: palette.ink3),
            const SizedBox(height: 12),
            Text(s.extCatalogError, style: Styles.body.copyWith(color: palette.ink2)),
            const SizedBox(height: 12),
            PrimaryButton(label: s.extRetry, onTap: _refreshCatalog),
          ],
        ),
      );
    }
    // Rebuild cards when the store changes (install finishes, etc.).
    return AnimatedBuilder(
      animation: ExtScope.of(context),
      builder: (context, _) => _catalogList(context),
    );
  }

  Widget _catalogList(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final entries = _filtered();
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: s.extSearchHint,
            prefixIcon: const Icon(Symbols.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in _categories())
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(_categoryLabel(context, c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Spacer(),
            PopupMenuButton<int>(
              icon: const Icon(Symbols.sort_rounded),
              tooltip: s.extSortBy,
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => [
                PopupMenuItem(value: 0, child: Text(s.extSortPopular)),
                PopupMenuItem(value: 1, child: Text(s.extSortRating)),
                PopupMenuItem(value: 2, child: Text(s.extSortName)),
              ],
            ),
          ],
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(s.extEmptySearch,
                      style: Styles.body.copyWith(color: palette.ink2)))
              : RefreshIndicator(
                  onRefresh: _refreshCatalog,
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _catalogCard(context, entries[i]),
                  ),
                ),
        ),
      ],
    );
  }

  List<String> _categories() {
    final set = <String>{'all'};
    for (final e in _catalog?.entries ?? const <CatalogEntry>[]) {
      set.addAll(e.categories);
    }
    return set.toList();
  }

  String _categoryLabel(BuildContext context, String c) {
    final s = S.of(context);
    switch (c) {
      case 'all':
        return s.extCatAll;
      case 'tools':
        return s.extCatTools;
      case 'themes':
        return s.extCatThemes;
      case 'automation':
        return s.extCatAutomation;
      case 'stats':
        return s.extCatStats;
      case 'network':
        return s.extCatNetwork;
      default:
        return c;
    }
  }

  List<CatalogEntry> _filtered() {
    var list = _catalog?.entries ?? const <CatalogEntry>[];
    if (_category != 'all') {
      list = list.where((e) => e.categories.contains(_category)).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where((e) =>
              e.name.toLowerCase().contains(_query) ||
              e.author.toLowerCase().contains(_query) ||
              e.description.toLowerCase().contains(_query))
          .toList();
    }
    switch (_sort) {
      case 1:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case 2:
        list.sort((a, b) => a.name.compareTo(b.name));
      default:
        list.sort((a, b) => b.installs.compareTo(a.installs));
    }
    return list;
  }

  Widget _catalogCard(BuildContext context, CatalogEntry e) {
    final store = ExtScope.of(context);
    final installed = store.get(e.id);
    final s = S.of(context);
    final needsUpdate =
        installed != null && compareVersions(e.version, installed.version) > 0;
    return ExtensionCard(
      title: e.name,
      author: e.author,
      rating: e.rating,
      installs: e.installs,
      badges: catalogBadges(context, e),
      subtitle: e.description,
      permissions: e.permissions,
      onTap: () => push(
          context,
          ExtensionDetailScreen(
              entry: e, onInstall: (entry) => _installFromCatalog(context, entry))),
      trailing: installed == null
          ? PrimaryButton(
              label: s.extInstall,
              onTap: () => _installFromCatalog(context, e),
            )
          : needsUpdate
              ? PrimaryButton(
                  label: s.extUpdate,
                  onTap: () => _installFromCatalog(context, e),
                )
              : null,
    );
  }

  Future<void> _installFromCatalog(BuildContext context, CatalogEntry e) async {
    final s = S.of(context);
    final state = context.findAncestorStateOfType<_ExtensionsScreenState>();
    if (state == null || !context.mounted) return;
    var progressOpen = false;
    state._showProgress(context, s.extDownloading);
    progressOpen = true;
    try {
      // The catalog entry carries the expected size; anything beyond it is
      // not the advertised package.
      final data = await _ExtensionsScreenState._downloadCapped(Uri.parse(e.downloadUrl), limit: e.size)
          .timeout(const Duration(seconds: 120));
      if (!context.mounted) return;
      Navigator.of(context).pop();
      progressOpen = false;
      await state._installBytes(context, data,
          source: 'catalog', expectedSha256: e.sha256);
    } catch (_) {
      if (progressOpen && context.mounted) Navigator.of(context).pop();
      if (context.mounted) state._showError(context, s.extErrNetwork);
    }
  }

  Widget _buildInstalled(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final store = ExtScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final list = store.installed;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.extension_off_rounded, size: 40, color: palette.ink3),
                const SizedBox(height: 12),
                Text(s.extEmptyInstalled,
                    style: Styles.body.copyWith(color: palette.ink2),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final inst = list[i];
            final catalogEntry = _catalog?.find(inst.id);
            final needsUpdate = catalogEntry != null &&
                compareVersions(catalogEntry.version, inst.version) > 0;
            return ExtensionCard(
              title: inst.manifest.name,
              author: inst.manifest.author.name,
              badges: [
                if (inst.source != 'catalog')
                  ExtBadge(
                      label: s.extSideloadShort,
                      tone: ExtBadgeTone.warn,
                      icon: Symbols.warning_rounded),
                if (needsUpdate) ExtBadge(label: s.extUpdateAvailable),
                if (!inst.enabled) ExtBadge(label: s.extDisabled),
              ],
              subtitle: s.extVersionLabel(inst.version),
              enabled: inst.enabled,
              capabilities: inst.manifest.capabilities,
              permissions: inst.granted,
              networkHosts: inst.manifest.networkHosts,
              onTap: () => push(context, ExtensionDetailScreen(installed: inst)),
              trailing: Switch(
                value: inst.enabled,
                onChanged: (v) => store.setEnabled(inst.id, v),
              ),
            );
          },
        );
      },
    );
  }
}
