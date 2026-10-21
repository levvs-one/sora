/// The extensions section: catalog and installed tabs, search, categories,
/// one-tap install / enable / update. Replaces the "coming soon" stub.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'dart:math' as math;

import '../../../l10n/strings.dart';
import '../../design/theme.dart';
import '../kit.dart';
import '../../ext/catalog.dart';
import '../../ext/conflicts.dart';
import '../../ext/manifest.dart';
import '../../ext/package.dart';
import '../../ext/permissions.dart';
import '../../ext/store.dart';
import '../../ext/verifier.dart';
import '../../updates.dart';
import 'conflicts_sheet.dart';
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
        fill: _ready ? const _ExtensionsBody() : const Center(child: CircularProgressIndicator()),
        children: const [],
      ),
    );
  }

  Future<void> _installFromFile(BuildContext context) async {
    final typeGroup = const XTypeGroup(label: 'soraext', extensions: ['soraext']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !context.mounted) return;
    final data = await file.readAsBytes();
    if (!context.mounted) return;
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
                  PrimaryButton(label: s.extDownload, onTap: () => Navigator.pop(context, controller.text.trim())),
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
      final client = http.Client();
      try {
        final data = await _downloadCapped(
          client,
          Uri.parse(url),
          limit: maxPackageBytes,
        ).timeout(const Duration(seconds: 60));
        if (!context.mounted) return;
        await _installBytes(context, data, source: 'url', expectedSha256: null);
      } finally {
        client.close();
      }
    } catch (_) {
      if (context.mounted) _showError(context, s.extErrNetwork);
    }
  }

  /// Downloads a .soraext with a hard byte cap enforced while streaming, so
  /// a rogue URL cannot exhaust memory before [ExtPackage.open] runs its own
  /// structural checks. Throws on HTTP errors, timeouts and over-limit
  /// bodies; callers map every failure to a network error. Closing [client]
  /// aborts the download (used by the cancel button).
  static Future<Uint8List> _downloadCapped(http.Client client, Uri url, {required int limit}) async {
    final response = await client.send(http.Request('GET', url));
    if (response.statusCode != 200) throw Exception('http ${response.statusCode}');
    final body = <int>[];
    await for (final chunk in response.stream) {
      body.addAll(chunk);
      if (body.length > limit) throw Exception('download exceeds $limit bytes');
    }
    return Uint8List.fromList(body);
  }

  /// Verifies and installs raw .soraext bytes with the permission prompt.
  ///
  /// [changelog] lists the new versions' notes newest-first; shown on the
  /// update prompt so the user knows why before approving. Null when
  /// unknown (file/URL installs).
  /// Returns true when the new version was installed.
  Future<bool> _installBytes(
    BuildContext context,
    Uint8List data, {
    required String source,
    required String? expectedSha256,
    List<CatalogChangelogEntry>? changelog,
    String? authorKeyPin,
  }) async {
    final s = S.of(context);
    if (!context.mounted) return false;
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

    // Whether the previous version stays in place if this fails. True for
    // every failure path below: the registry is only rewritten after the
    // new content is fully extracted, so a failed update never leaves the
    // user without the working version.
    var isUpdate = false;
    void showFailure(BuildContext context, String message) {
      hideProgress();
      if (context.mounted) {
        _showError(context, isUpdate ? '$message\n\n${s.extUpdateFailedKept}' : message);
      }
    }

    showProgress(s.extVerifying);
    try {
      if (expectedSha256 != null) {
        final ok = _sha256Hex(data) == expectedSha256.toLowerCase();
        if (!ok) throw PackageError('download does not match the catalog sha256');
      }
      final pkg = ExtPackage.open(data);
      // Catalog installs verify against the catalog-pinned author key,
      // never against the manifest's self-attested one.
      await pkg.verify(authorKeyLine: authorKeyPin);
      // min_app_version gate against the running app.
      if (_appVersion.isNotEmpty && compareVersions(pkg.manifest.minAppVersion, _appVersion) > 0) {
        throw PackageError('needs app ${pkg.manifest.minAppVersion}');
      }
      isUpdate = _store.get(pkg.manifest.id) != null;
      hideProgress();
      if (!context.mounted) return false;
      // A widening update shows exactly what is new — with the honest
      // "Update" title — instead of the full list under "Install". Dropped
      // permissions are shown too: losing access deserves the same honesty.
      final existing = _store.get(pkg.manifest.id);
      final diff = existing == null ? null : diffPermissions(existing.granted, pkg.manifest.permissions);
      // Null for a fresh install; empty list for an update with no
      // additions (the prompt still titles itself "Update").
      final added = diff?.added;
      final removed = diff == null || diff.removed.isEmpty ? null : diff.removed;
      final granted = await showInstallPrompt(
        context,
        manifest: pkg.manifest,
        sideload: source != 'catalog',
        addedPermissions: added,
        removedPermissions: removed,
        changelog: changelog,
      );
      if (granted == null || !context.mounted) return false;
      showProgress(s.extInstalling);
      try {
        await _store.install(pkg, source: source, granted: granted, authorKeyPin: authorKeyPin);
      } finally {
        hideProgress();
      }
      return true;
    } on PackageError catch (e) {
      if (context.mounted) showFailure(context, _mapInstallError(context, e.message));
    } on SignatureError {
      if (context.mounted) showFailure(context, s.extErrSignature);
    } on ManifestError {
      if (context.mounted) showFailure(context, s.extErrManifest);
    } catch (_) {
      if (context.mounted) showFailure(context, s.extErrGeneric);
    }
    return false;
  }

  String _mapInstallError(BuildContext context, String message) {
    final s = S.of(context);
    if (message.contains('sha256')) return s.extErrHash;
    if (message.contains('signature') || message.contains('checksums')) return s.extErrSignature;
    if (message.contains('author key changed')) return s.extErrAuthorKeyChanged;
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

  /// Like [_showProgress] but with a Cancel button. Tapping it pops the
  /// dialog and runs [onCancel] (the caller aborts the work, e.g. closes
  /// the download client). A cancelled operation is not an error: the
  /// caller must stay silent instead of showing a failure dialog.
  void _showProgressWithCancel(BuildContext context, String label, VoidCallback onCancel) {
    final palette = Palette.of(context);
    final s = S.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: palette.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: Styles.body.copyWith(color: palette.ink)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onCancel();
                },
                child: Text(s.extCancel, style: TextStyle(color: palette.ink2)),
              ),
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
                      child: Text(s.extInstallFailed, style: Styles.title.copyWith(color: palette.ink)),
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

/// The running app version for the min_app_version gate. Release builds
/// carry x.y.z in SORA_VERSION; dev and untagged CI builds (dev, 0.0.0.N)
/// have no comparable version, so the gate is skipped there rather than
/// enforced against a guess.
final String _appVersion = RegExp(r'^\d+\.\d+\.\d+$').hasMatch(appVersion) ? appVersion : '';

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

  /// Catalog search input. The result list below listens to it through a
  /// ValueListenableBuilder, so typing rebuilds only the list, not the tab
  /// switch, search field, filter chips and sort row.
  final _catalogSearch = TextEditingController();
  String _category = 'all';
  String _capability = 'all';
  int _sort = 0; // 0 popular, 1 rating, 2 name, 3 relevance

  /// Bumped on every catalog refresh; part of the [_filtered] memo key.
  int _catalogRevision = 0;
  String _filteredKey = '';
  List<CatalogEntry>? _filteredCache;

  /// When the catalog came from the offline cache, the UI must say so
  /// (with the fetch date) instead of silently serving stale data.
  DateTime? _cachedAt;

  CatalogCache? _cache;
  bool _depsReady = false;

  @override
  void dispose() {
    _catalogSearch.dispose();
    _installedSearch.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _depsReady = true;
    _cache = ExtScope.of(context).catalogCache;
    _refreshCatalog();
  }

  Future<void> _refreshCatalog() async {
    // Any refresh invalidates the memoized filter, whatever the outcome.
    _catalogRevision++;
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
      final ExtensionCatalog catalog;
      final bool fromCache;
      final DateTime fetchedAt;
      final cache = _cache;
      if (cache == null) {
        catalog = await fetchCatalog().timeout(const Duration(seconds: 45));
        fromCache = false;
        fetchedAt = DateTime.now().toUtc();
      } else {
        final r = await cache.refresh().timeout(const Duration(seconds: 45));
        catalog = r.catalog;
        fromCache = r.fromCache;
        fetchedAt = r.fetchedAt;
      }
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _cachedAt = fromCache ? fetchedAt : null;
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
        Expanded(child: _tab == 0 ? _buildCatalog(context) : _buildInstalled(context)),
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
            Text(
              s.extCatalogSoonTitle,
              style: Styles.title.copyWith(color: palette.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                s.extCatalogSoonBody,
                style: Styles.body.copyWith(color: palette.ink2),
                textAlign: TextAlign.center,
              ),
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
    return AnimatedBuilder(animation: ExtScope.of(context), builder: (context, _) => _catalogList(context));
  }

  Widget _catalogList(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final cachedAt = _cachedAt;
    return Column(
      children: [
        if (cachedAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Symbols.history_rounded, size: 14, color: palette.ink3),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.extCatalogCached(_formatDate(context, cachedAt)),
                    style: Styles.caption.copyWith(color: palette.ink2),
                  ),
                ),
                TextButton(
                  onPressed: _refreshCatalog,
                  child: Text(s.extRetry, style: TextStyle(color: palette.ink2)),
                ),
              ],
            ),
          ),
        TextField(
          controller: _catalogSearch,
          // No onChanged setState: the list below listens through
          // ValueListenableBuilder, so typing rebuilds only the list.
          decoration: InputDecoration(
            hintText: s.extSearchHint,
            prefixIcon: const Icon(Symbols.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
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
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(s.extCapFilterTitle, style: Styles.caption.copyWith(color: palette.ink3)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in _capabilities())
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(_capabilityLabel(context, c)),
                    selected: _capability == c,
                    onSelected: (_) => setState(() => _capability = c),
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
                PopupMenuItem(value: 3, child: Text(s.extSortRelevance)),
              ],
            ),
          ],
        ),
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _catalogSearch,
            builder: (context, value, _) {
              final entries = _filtered(value.text.trim().toLowerCase());
              return entries.isEmpty
                  ? Center(
                      child: Text(s.extEmptySearch, style: Styles.body.copyWith(color: palette.ink2)),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshCatalog,
                      child: ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _catalogCard(context, entries[i]),
                      ),
                    );
            },
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

  /// Capability filter values: 'all' plus the manifest capability registry
  /// ids. Labels come from l10n (extCap*).
  List<String> _capabilities() => const ['all', 'theme', 'network-hook', 'routing', 'ui-panel', 'background', 'widget'];

  String _capabilityLabel(BuildContext context, String c) {
    final s = S.of(context);
    switch (c) {
      case 'all':
        return s.extCatAll;
      case 'theme':
        return s.extCapTheme;
      case 'network-hook':
        return s.extCapNetHook;
      case 'routing':
        return s.extCapRouting;
      case 'ui-panel':
        return s.extCapPanel;
      case 'background':
        return s.extCapBackground;
      case 'widget':
        return s.extCapWidget;
      default:
        return c;
    }
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

  List<CatalogEntry> _filtered(String query) {
    // Memoized: filtering + sorting a few hundred entries is cheap, but
    // rebuilding the whole section on every store notification (install
    // finishes, switch toggled) would redo it for nothing. The key covers
    // every input; a miss recomputes once.
    final key = '$_catalogRevision|$query|$_category|$_capability|$_sort';
    final cached = _filteredCache;
    if (key == _filteredKey && cached != null) return cached;
    // Copy first: sorting must never mutate the catalog's own list.
    var list = List.of(_catalog?.entries ?? const <CatalogEntry>[]);
    if (_category != 'all') {
      list = list.where((e) => e.categories.contains(_category)).toList();
    }
    if (_capability != 'all') {
      list = list.where((e) => e.capabilities.contains(_capability)).toList();
    }
    if (query.isNotEmpty) {
      list = list
          .where(
            (e) =>
                e.name.toLowerCase().contains(query) ||
                e.author.toLowerCase().contains(query) ||
                e.description.toLowerCase().contains(query),
          )
          .toList();
    }
    switch (_sort) {
      case 1:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case 2:
        list.sort((a, b) => a.name.compareTo(b.name));
      case 3:
        {
          // Relevance keys are computed once per filter pass, not per
          // comparison: _relevance lowercases three fields and takes two
          // logarithms per call, so the comparator made sorting
          // O(n log n) relevance evaluations (the benchmark screen's
          // sort-keys pattern). The values are pure in the entry and the
          // query, so the order is identical.
          final relevance = {for (final e in list) e: _relevance(e, query)};
          list.sort((a, b) => relevance[b]!.compareTo(relevance[a]!));
        }
      default:
        list.sort((a, b) => b.installs.compareTo(a.installs));
    }
    _filteredKey = key;
    _filteredCache = list;
    return list;
  }

  /// Relevance for sort-by-relevance: text match first (name > author >
  /// description), then the honest rating, then a logarithmic installs
  /// term. Log installs break ties without letting a huge install base
  /// bury a better-rated newcomer.
  double _relevance(CatalogEntry e, String query) {
    double text = 0.5; // neutral when there is no query
    if (query.isNotEmpty) {
      final name = e.name.toLowerCase();
      final author = e.author.toLowerCase();
      final desc = e.description.toLowerCase();
      if (name.contains(query)) {
        text = 1.0;
      } else if (author.contains(query)) {
        text = 0.7;
      } else if (desc.contains(query)) {
        text = 0.4;
      } else {
        text = 0.0;
      }
    }
    final rating = (e.rating / 5).clamp(0.0, 1.0);
    final installs = (math.log(e.installs + 1) / math.log(1000001)).clamp(0.0, 1.0);
    return text * 0.55 + rating * 0.3 + installs * 0.15;
  }

  static String _formatDate(BuildContext context, DateTime date) {
    return DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(date.toLocal());
  }

  Widget _catalogCard(BuildContext context, CatalogEntry e) {
    final store = ExtScope.of(context);
    final installed = store.get(e.id);
    final s = S.of(context);
    // Staged rollout: the update button appears only for installs inside
    // this version's bucket. The listing itself is never gated: hiding a
    // published version from the catalog would be dishonest.
    final needsUpdate =
        installed != null && compareVersions(e.version, installed.version) > 0 && e.rolloutEligible(store.installId);
    return ExtensionCard(
      key: ValueKey(e.id),
      title: e.name,
      author: e.author,
      rating: e.rating,
      installs: e.installs,
      badges: catalogBadges(context, e),
      subtitle: e.description,
      permissions: e.permissions,
      onTap: () => push<void>(
        context,
        ExtensionDetailScreen(entry: e, onInstall: (entry) => _installFromCatalog(context, entry)),
      ),
      trailing: installed == null
          ? PrimaryButton(label: s.extInstall, onTap: () => _installFromCatalog(context, e))
          : needsUpdate
          ? PrimaryButton(label: s.extUpdate, onTap: () => _installFromCatalog(context, e))
          : null,
    );
  }

  /// Installs one catalog entry. Returns true when the new version is
  /// installed; false on cancel or failure (the failure dialog is shown
  /// by [_installBytes], so callers must not add their own noise).
  Future<bool> _installFromCatalog(BuildContext context, CatalogEntry e) async {
    final s = S.of(context);
    final state = context.findAncestorStateOfType<_ExtensionsScreenState>();
    if (state == null || !context.mounted) return false;
    // The download is cancellable: closing the client aborts the stream.
    // A user-cancelled download is not an error — stay silent.
    final client = http.Client();
    var cancelled = false;
    var dialogOpen = false;
    void closeDialog() {
      if (dialogOpen && context.mounted) {
        dialogOpen = false;
        Navigator.of(context).pop();
      }
    }

    dialogOpen = true;
    state._showProgressWithCancel(context, s.extDownloading, () {
      cancelled = true;
      closeDialog();
      client.close();
    });
    try {
      // The catalog entry carries the expected size; anything beyond it is
      // not the advertised package.
      final data = await _ExtensionsScreenState._downloadCapped(
        client,
        Uri.parse(e.downloadUrl),
        limit: e.size,
      ).timeout(const Duration(seconds: 120));
      closeDialog();
      if (!context.mounted) return false;
      // Changelog rows newer than the installed version, newest first.
      // A fresh install sees the whole history.
      final installedVersion = state._store.get(e.id)?.version;
      final changelog = [
        for (final c in e.changelog)
          if (installedVersion == null || compareVersions(c.version, installedVersion) > 0) c,
      ];
      return await state._installBytes(
        context,
        data,
        source: 'catalog',
        expectedSha256: e.sha256,
        authorKeyPin: e.authorKey,
        changelog: changelog.isEmpty ? null : changelog,
      );
    } catch (_) {
      closeDialog();
      if (!cancelled && context.mounted) {
        state._showError(context, s.extErrNetwork);
      }
      return false;
    } finally {
      client.close();
    }
  }

  Widget _buildInstalled(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _installedSearch,
          // No onChanged setState: the list below listens through
          // ValueListenableBuilder, so typing rebuilds only the list, not
          // the tab switch and search field.
          decoration: InputDecoration(
            hintText: S.of(context).extSearchInstalled,
            prefixIcon: const Icon(Symbols.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: AnimatedBuilder(
            animation: ExtScope.of(context),
            builder: (context, _) => ValueListenableBuilder<TextEditingValue>(
              valueListenable: _installedSearch,
              builder: (context, value, _) =>
                  _installedList(context, ExtScope.of(context), value.text.trim().toLowerCase()),
            ),
          ),
        ),
      ],
    );
  }

  /// Update-all in flight: the button shows progress and ignores taps.
  bool _updatingAll = false;

  /// Installed-tab search input; same builder isolation as [_catalogSearch].
  final _installedSearch = TextEditingController();

  bool _needsUpdate(ExtensionStore store, InstalledExtension inst) {
    final catalogEntry = _catalog?.find(inst.id);
    return catalogEntry != null &&
        compareVersions(catalogEntry.version, inst.version) > 0 &&
        catalogEntry.rolloutEligible(store.installId);
  }

  Widget _installedList(BuildContext context, ExtensionStore store, String query) {
    final s = S.of(context), palette = Palette.of(context);
    final q = query;
    var list = store.installed;
    if (q.isNotEmpty) {
      list = list
          .where(
            (inst) =>
                inst.manifest.name.toLowerCase().contains(q) || inst.manifest.author.name.toLowerCase().contains(q),
          )
          .toList();
    }
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.extension_off_rounded, size: 40, color: palette.ink3),
            const SizedBox(height: 12),
            Text(
              q.isEmpty ? s.extEmptyInstalled : s.extEmptySearch,
              style: Styles.body.copyWith(color: palette.ink2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    final updates = [
      for (final inst in store.installed)
        if (_needsUpdate(store, inst)) inst,
    ];
    return Column(
      children: [
        _ConflictBanner(store: store),
        if (updates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.extUpdatesAvailable(updates.length),
                    style: Styles.bodyStrong.copyWith(color: palette.ink),
                  ),
                ),
                const SizedBox(width: 8),
                PrimaryButton(
                  label: s.extUpdateAll,
                  busy: _updatingAll,
                  onTap: _updatingAll ? null : () => _updateAll(context, updates),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            // Lazily built: only visible cards exist, even with 100+.
            addAutomaticKeepAlives: false,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final inst = list[i];
              final needsUpdate = _needsUpdate(store, inst);
              return ExtensionCard(
                key: ValueKey(inst.id),
                title: inst.manifest.name,
                author: inst.manifest.author.name,
                badges: [
                  if (inst.source != 'catalog')
                    ExtBadge(label: s.extSideloadShort, tone: ExtBadgeTone.warn, icon: Symbols.warning_rounded),
                  if (needsUpdate) ExtBadge(label: s.extUpdateAvailable),
                  if (!inst.enabled) ExtBadge(label: s.extDisabled),
                  // Honest signal, not the form itself: the full
                  // settings form lives on the detail screen, one tap away.
                  if (inst.manifest.settingsSchema != null)
                    ExtBadge(label: s.extSettings, icon: Symbols.settings_rounded),
                ],
                subtitle: s.extVersionLabel(inst.version),
                enabled: inst.enabled,
                capabilities: inst.manifest.capabilities,
                permissions: inst.granted,
                networkHosts: inst.manifest.networkHosts,
                onTap: () => push<void>(context, ExtensionDetailScreen(installed: inst)),
                // The switch alone announces only on/off; the label names
                // the extension it toggles.
                trailing: Semantics(
                  label: s.extToggleEnabled(inst.manifest.name),
                  child: Switch(value: inst.enabled, onChanged: (v) => store.setEnabled(inst.id, v)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Updates every outdated extension in sequence. Each widening update
  /// still asks its own permission question; failures show their dialog
  /// and the run continues. The snackbar at the end counts only real
  /// successes — silence would let a half-finished run look complete.
  Future<void> _updateAll(BuildContext context, List<InstalledExtension> updates) async {
    final s = S.of(context);
    setState(() => _updatingAll = true);
    var done = 0;
    try {
      for (final inst in updates) {
        if (!context.mounted) return;
        final store = ExtScope.of(context);
        final entry = _catalog?.find(inst.id);
        // Re-check per item: the user may have updated or removed one
        // while this run was in flight.
        final current = store.get(inst.id);
        if (entry == null || current == null || compareVersions(entry.version, current.version) <= 0) {
          continue;
        }
        if (await _installFromCatalog(context, entry)) done++;
      }
    } finally {
      if (mounted) setState(() => _updatingAll = false);
    }
    if (!context.mounted) return;
    if (done > 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.extUpdatedCount(done))));
    }
  }
}

/// Banner over the installed list when extensions fight over an exclusive
/// permission (routing rules, theme, network hooks). Tapping it opens the
/// resolution sheet; the banner disappears once every conflict is decided.
///
/// Self-contained: it listens to the store itself, so enable/disable,
/// install and uninstall all re-evaluate the conflicts.
class _ConflictBanner extends StatefulWidget {
  const _ConflictBanner({required this.store});
  final ExtensionStore store;

  @override
  State<_ConflictBanner> createState() => _ConflictBannerState();
}

class _ConflictBannerState extends State<_ConflictBanner> {
  List<ExtConflict> _conflicts = const [];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final winners = await widget.store.conflictWinners();
    if (!mounted) return;
    setState(() {
      _conflicts = unresolvedConflicts(widget.store.installed, (k) => winners[k]);
      _ready = true;
    });
  }

  Future<void> _openSheet() async {
    final saved = await showConflictsSheet(context, conflicts: _conflicts, store: widget.store);
    if (saved) unawaited(_refresh());
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _conflicts.isEmpty) return const SizedBox.shrink();
    final s = S.of(context), palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: s.extConflictsCount(_conflicts.length),
        excludeSemantics: true,
        onTap: _openSheet,
        child: Pressable(
          onTap: _openSheet,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Symbols.warning_rounded, size: 20, color: palette.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.extConflictsCount(_conflicts.length),
                    style: Styles.bodyStrong.copyWith(color: palette.ink),
                  ),
                ),
                const SizedBox(width: 8),
                Text(s.extConflictsResolve, style: Styles.bodyStrong.copyWith(color: palette.danger)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
