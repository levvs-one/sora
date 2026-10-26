/// The extensions section: catalog and installed tabs, search, categories,
/// one-tap install / enable / update.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart' show CupertinoSearchTextField, CupertinoSwitch;
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
import '../../sora.dart';
import 'conflicts_sheet.dart';
import 'detail_screen.dart';
import 'permissions_sheet.dart';
import 'progress_window.dart';
import 'widgets.dart';

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen> {
  late final ExtensionStore _store = SoraScope.read(context).extensions;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // An unreadable data directory must end the spinner, not leave it
    // turning forever.
    _store.load().then(
      (_) {
        if (mounted) setState(() => _ready = true);
        unawaited(_refreshRevocations());
      },
      onError: (Object _) {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  /// Fetches the team revocation list; a fetch failure keeps the cached
  /// list and stays quiet, a disabled extension is always announced.
  Future<void> _refreshRevocations() async {
    try {
      final disabled = await _store.refreshRevocations();
      if (!mounted || disabled.isEmpty) return;
      final s = S.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.extRevokedDisabled(disabled.map((e) => e.manifest.name).join(', ')))));
    } catch (e) {
      debugPrint('[ext] revocation list not refreshed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ExtScope(
      store: _store,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.extensions,
                            style: Styles.heading.copyWith(fontSize: 22, color: Palette.of(context).ink),
                          ),
                        ),
                        RoundButton(
                          icon: Symbols.install_desktop_rounded,
                          label: s.extInstallFromFile,
                          onTap: _ready ? () => _installFromFile(context) : null,
                        ),
                        const SizedBox(width: 8),
                        RoundButton(
                          icon: Symbols.link_rounded,
                          label: s.extInstallFromUrl,
                          onTap: _ready ? () => _installFromUrl(context) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _ready
                          ? const _ExtensionsBody()
                          : _failed
                          ? Center(
                              child: Text(
                                s.extErrGeneric,
                                style: Styles.body.copyWith(color: Palette.of(context).ink2),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<String>(
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
                  Text(s.extInstallFromUrl, style: Styles.heading.copyWith(fontSize: 22, color: palette.ink)),
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
    final url = await navigator.push(route);
    await route.completed;
    controller.dispose();
    if (url == null || url.isEmpty || !context.mounted) return;
    if (!url.startsWith('https://')) {
      await _showError(context, s.extErrHttpsOnly);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      await _showError(context, s.extErrNetwork);
      return;
    }
    await _downloadAndInstall(context, uri, source: 'url');
  }

  Future<bool> _downloadAndInstall(BuildContext context, Uri url, {required String source, CatalogEntry? entry}) async {
    final s = S.of(context);
    final client = http.Client();
    var cancelled = false;
    late final ExtensionInstallDialog window;
    void progress(int received, int? total) {
      window.show(
        InstallProgressWindow(
          stage: InstallStage.download,
          received: received,
          total: total,
          onCancel: () {
            cancelled = true;
            client.close();
            unawaited(window.close());
          },
        ),
      );
    }

    window = ExtensionInstallDialog(context, const InstallProgressWindow(stage: InstallStage.download));
    progress(0, entry?.size);
    try {
      final data = await _downloadCapped(
        client,
        url,
        limit: entry == null ? maxPackageBytes : math.min(entry.size, maxPackageBytes),
        expectedSize: entry?.size,
        onProgress: progress,
      ).timeout(Duration(seconds: entry == null ? 60 : 120));
      if (cancelled || !context.mounted) return false;
      final installedVersion = entry == null ? null : _store.get(entry.id)?.version;
      final changelog = entry?.changelog
          .where((c) => installedVersion == null || compareVersions(c.version, installedVersion) > 0)
          .toList();
      return await _installBytes(
        context,
        data,
        source: source,
        expectedSha256: entry?.sha256,
        authorKeyPin: entry?.authorKey,
        changelog: changelog,
        window: window,
        verified: entry?.badges.contains('staff') ?? false,
      );
    } catch (_) {
      client.close();
      await window.close();
      if (!cancelled && context.mounted) await _showError(context, s.extErrNetwork);
      return false;
    } finally {
      client.close();
      await window.close();
    }
  }

  static Future<Uint8List> _downloadCapped(
    http.Client client,
    Uri url, {
    required int limit,
    int? expectedSize,
    required void Function(int received, int? total) onProgress,
  }) async {
    final response = await client.send(http.Request('GET', url));
    if (response.statusCode != 200) throw Exception('http ${response.statusCode}');
    final total = expectedSize ?? response.contentLength;
    if (total != null && total > limit) throw Exception('download exceeds $limit bytes');
    final body = BytesBuilder(copy: false);
    onProgress(0, total);
    await for (final chunk in response.stream) {
      if (body.length + chunk.length > limit) throw Exception('download exceeds $limit bytes');
      body.add(chunk);
      onProgress(body.length, total);
    }
    return body.takeBytes();
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
    ExtensionInstallDialog? window,
    bool verified = false,
  }) async {
    final s = S.of(context);
    if (!context.mounted) return false;
    final progress = window ?? ExtensionInstallDialog(context, const InstallProgressWindow(stage: InstallStage.verify));
    var isUpdate = false;
    Future<void> showFailure(String message) async {
      await progress.close();
      if (context.mounted) {
        await _showError(context, isUpdate ? '$message\n\n${s.extUpdateFailedKept}' : message);
      }
    }

    progress.show(const InstallProgressWindow(stage: InstallStage.verify));
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
      if (!context.mounted) return false;
      // A widening update shows exactly what is new, under the "Update"
      // title, instead of the full list under "Install". Dropped
      // permissions are shown too: the user should see lost access as well.
      final existing = _store.get(pkg.manifest.id);
      final diff = existing == null ? null : diffPermissions(existing.granted, pkg.manifest.permissions);
      // Null for a fresh install; empty list for an update with no
      // additions (the prompt still titles itself "Update").
      final added = diff?.added;
      final removed = diff == null || diff.removed.isEmpty ? null : diff.removed;
      final decision = Completer<List<String>?>();
      progress.show(
        InstallPermissionPrompt(
          manifest: pkg.manifest,
          sideload: source != 'catalog',
          addedPermissions: added,
          removedPermissions: removed,
          changelog: changelog,
          verified: verified || pkg.manifest.author.publicKey.trim() == teamPublicKey,
          onDecision: (granted) {
            if (!decision.isCompleted) decision.complete(granted);
          },
        ),
      );
      final granted = await decision.future;
      if (granted == null || !context.mounted) return false;
      progress.show(const InstallProgressWindow(stage: InstallStage.install));
      await _store.install(pkg, source: source, granted: granted, authorKeyPin: authorKeyPin);
      return true;
    } on ExtAssetError {
      await progress.close();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.extAssetRejected)));
    } on PackageError catch (e) {
      if (context.mounted) await showFailure(_mapInstallError(context, e.message));
    } on SignatureError {
      if (context.mounted) await showFailure(s.extErrSignature);
    } on ManifestError {
      if (context.mounted) await showFailure(s.extErrManifest);
    } on ExtStoreError catch (e) {
      if (context.mounted) await showFailure(extStoreErrorText(s, e));
    } catch (_) {
      if (context.mounted) await showFailure(s.extErrGeneric);
    } finally {
      await progress.close();
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

  Future<void> _showError(BuildContext context, String message) async {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    setState(() {
      _loading = true;
      _catalogError = null;
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
    final categories = _categories(), capabilities = _capabilities();
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
        Row(
          children: [
            Expanded(
              child: _SearchField(controller: _catalogSearch, placeholder: s.extSearchHint),
            ),
            const SizedBox(width: 8),
            MenuAnchor(
              menuChildren: [
                for (final (value, label) in [
                  (0, s.extSortPopular),
                  (1, s.extSortRating),
                  (2, s.extSortName),
                  (3, s.extSortRelevance),
                ])
                  MenuItemButton(
                    onPressed: () => setState(() => _sort = value),
                    leadingIcon: _sort == value
                        ? Icon(Symbols.check_rounded, size: 18, color: palette.ink)
                        : const SizedBox(width: 18),
                    child: Text(label),
                  ),
              ],
              builder: (context, controller, _) => RoundButton(
                icon: Symbols.sort_rounded,
                label: s.extSortBy,
                onTap: () => controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          ],
        ),
        // A filter with a single choice filters nothing, so its row stays
        // hidden until the catalog offers at least two.
        if (categories.length > 2 || capabilities.length > 2) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (categories.length > 2)
                  for (final c in categories)
                    _FilterPill(
                      label: _categoryLabel(context, c),
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                if (categories.length > 2 && capabilities.length > 2) const SizedBox(width: 8),
                if (capabilities.length > 2)
                  for (final c in capabilities)
                    if (c != 'all' || categories.length <= 2)
                      _FilterPill(
                        label: _capabilityLabel(context, c),
                        selected: _capability == c,
                        onTap: () => setState(() => _capability = _capability == c ? 'all' : c),
                      ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
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

  /// Capability filter values: 'all' plus the capabilities the catalog's
  /// entries declare. Labels come from l10n (extCap*).
  List<String> _capabilities() {
    final set = <String>{'all'};
    for (final e in _catalog?.entries ?? const <CatalogEntry>[]) {
      set.addAll(e.capabilities);
    }
    return set.toList();
  }

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
  /// description), then the rating, then a logarithmic installs
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
    // published version from the catalog would be misleading.
    final needsUpdate =
        installed != null && compareVersions(e.version, installed.version) > 0 && e.rolloutEligible(store.installId);
    return ExtensionCard(
      key: ValueKey(e.id),
      title: e.name,
      author: e.author,
      rating: e.rating,
      installs: e.installs,
      verified: e.badges.contains('staff'),
      subtitle: e.description,
      permissions: e.permissions,
      onTap: () => push<void>(
        context,
        ExtensionDetailScreen(entry: e, onInstall: (entry) => _installFromCatalog(context, entry)),
      ),
      trailing: installed == null
          ? PillButton(label: s.extInstall, onTap: () => _installFromCatalog(context, e))
          : needsUpdate
          ? PillButton(label: s.extUpdate, onTap: () => _installFromCatalog(context, e))
          : null,
    );
  }

  /// Installs one catalog entry. Returns true when the new version is
  /// installed; false on cancel or failure (the failure dialog is shown
  /// by [_installBytes], so callers must not add their own noise).
  Future<bool> _installFromCatalog(BuildContext context, CatalogEntry e) async {
    final state = context.findAncestorStateOfType<_ExtensionsScreenState>();
    if (state == null || !context.mounted) return false;
    return state._downloadAndInstall(context, Uri.parse(e.downloadUrl), source: 'catalog', entry: e);
  }

  Widget _buildInstalled(BuildContext context) {
    return Column(
      children: [
        // No onChanged setState: the list below listens through
        // ValueListenableBuilder, so typing rebuilds only the list, not the
        // tab switch and search field.
        _SearchField(controller: _installedSearch, placeholder: S.of(context).extSearchInstalled),
        const SizedBox(height: 12),
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
                verified: isTeamExtension(inst),
                sideload: inst.source != 'catalog',
                subtitle: s.extVersionLabel(inst.version),
                enabled: inst.enabled,
                capabilities: inst.manifest.capabilities,
                permissions: inst.granted,
                networkHosts: inst.manifest.networkHosts,
                onTap: () => push<void>(context, ExtensionDetailScreen(installed: inst)),
                // The switch alone announces only on/off; the label names
                // the extension it toggles.
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (needsUpdate) ...[
                      PillButton(
                        label: s.extUpdate,
                        onTap: () => _installFromCatalog(context, _catalog!.find(inst.id)!),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Semantics(
                      label: s.extToggleEnabled(inst.manifest.name),
                      child: CupertinoSwitch(
                        value: inst.enabled,
                        onChanged: (v) => toggleExtension(context, store, inst.id, v),
                        activeTrackColor: palette.ink,
                        inactiveTrackColor: palette.field,
                        thumbColor: palette.surface,
                      ),
                    ),
                  ],
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
  /// successes: silence would let a half-finished run look complete.
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
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.field),
            ),
            child: Row(
              children: [
                Icon(Symbols.warning_rounded, size: 20, color: palette.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.extConflictsCount(_conflicts.length),
                    style: Styles.bodyStrong.copyWith(color: palette.ink),
                  ),
                ),
                const SizedBox(width: 8),
                Text(s.extConflictsResolve, style: Styles.bodyStrong.copyWith(color: palette.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's search field (see the servers and licenses screens).
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.placeholder});

  final TextEditingController controller;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return CupertinoSearchTextField(
      controller: controller,
      placeholder: placeholder,
      style: Styles.body.copyWith(color: palette.ink),
      placeholderStyle: Styles.body.copyWith(color: palette.ink3),
      backgroundColor: palette.field,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      itemColor: palette.ink3,
    );
  }
}

/// A filter choice in the catalog's single row: ink when selected, like
/// [Segments], quiet field color otherwise.
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: Pressable(
          onTap: onTap,
          radius: 16,
          wash: false,
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.fast),
            height: 32,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? palette.ink : palette.field,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(label, style: Styles.secondary.copyWith(color: selected ? palette.surface : palette.ink2)),
          ),
        ),
      ),
    );
  }
}
