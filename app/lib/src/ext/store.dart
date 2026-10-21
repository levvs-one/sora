/// Installed-extension lifecycle owned by the app.
///
/// Layout under the data dir:
///   extensions/installed.json          # registry
///   extensions/{id}@{version}/...      # extracted content
///   extensions/{id}.settings.json      # per-extension settings
///
/// The previous version directory is kept for one-tap rollback.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'catalog.dart';
import 'assets.dart';
import 'conflicts.dart';
import 'manifest.dart';
import 'package.dart';
import 'permissions.dart';
import 'revocations.dart';

class ExtAssetError extends ExtStoreError {
  ExtAssetError(super.message);
}

class ExtStoreError implements Exception {
  ExtStoreError(this.message);
  final String message;
  @override
  String toString() => 'ExtStoreError: $message';
}

/// Where installed extensions live.
String extensionsDir() {
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return '$appData\\sora\\extensions';
    }
  }
  final home = Platform.environment['HOME'];
  final xdg = Platform.environment['XDG_DATA_HOME'];
  final base = (xdg != null && xdg.isNotEmpty)
      ? xdg
      : (home != null && home.isNotEmpty ? '$home/.local/share' : Directory.systemTemp.path);
  return '$base/sora/extensions';
}

class InstalledExtension {
  InstalledExtension({
    required this.manifest,
    required this.enabled,
    required this.source,
    required this.installedAt,
    required this.granted,
    this.previous,
    this.authorKey,
  });

  final ExtManifest manifest;
  final bool enabled;
  final String source; // catalog | sideload | url
  final DateTime installedAt;
  final List<String> granted;
  final String? previous; // N-1 version kept for rollback

  /// Pinned author public key (minisign .pub line): the catalog-pinned key
  /// for catalog installs, the manifest's self-attested key otherwise
  /// (trust on first use). Updates must carry the same key: a changed key
  /// is refused, never silently adopted. Null in registries written before
  /// pinning; readers fall back to the manifest's key for those.
  final String? authorKey;

  String get id => manifest.id;
  String get version => manifest.version;

  InstalledExtension copyWith({
    bool? enabled,
    String? previous,
    ExtManifest? manifest,
    List<String>? granted,
    String? authorKey,
  }) {
    return InstalledExtension(
      manifest: manifest ?? this.manifest,
      enabled: enabled ?? this.enabled,
      source: source,
      installedAt: installedAt,
      granted: granted ?? this.granted,
      previous: previous ?? this.previous,
      authorKey: authorKey ?? this.authorKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'manifest': manifest.toJson(),
    'enabled': enabled,
    'source': source,
    'installed_at': installedAt.toIso8601String(),
    'granted': granted,
    if (previous != null) 'previous': previous,
    if (authorKey != null) 'author_key': authorKey,
  };

  static InstalledExtension fromJson(Map<String, dynamic> json) {
    return InstalledExtension(
      manifest: ExtManifest.parse(jsonEncode(json['manifest'])),
      enabled: json['enabled'] as bool? ?? true,
      source: json['source'] as String? ?? 'sideload',
      installedAt: DateTime.tryParse(json['installed_at'] as String? ?? '') ?? DateTime.now(),
      granted: (json['granted'] as List? ?? []).map((e) => e.toString()).toList(),
      previous: json['previous'] as String?,
      authorKey: json['author_key'] as String?,
    );
  }
}

/// Compares two minisign .pub lines for the author-key continuity check.
/// Only surrounding whitespace is forgiven: base64 is case-sensitive, so
/// key content is never normalized.
bool _sameAuthorKey(String a, String? b) => b != null && a.trim() == b.trim();

/// App-side extension store. One instance per Extensions section subtree,
/// provided through [ExtScope].
class ExtensionStore extends ChangeNotifier {
  ExtensionStore({String? dir}) : _dir = dir ?? extensionsDir();

  final String _dir;
  final _installed = <String, InstalledExtension>{};
  bool _loaded = false;
  bool _disposed = false;
  final logChanges = ChangeNotifier();

  @override
  void dispose() {
    _disposed = true;
    logChanges.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  final _themes = <String, ExtensionTheme>{};
  final _routing = <String, ExtensionRouting>{};
  final _runtimeLogs = <String, List<String>>{};
  final runtimeErrors = <String, String>{};

  void appendLog(String id, String message) {
    if (_disposed) return;
    final lines = _runtimeLogs.putIfAbsent(id, () => []);
    lines.add(message.length > 1024 ? message.substring(0, 1024) : message);
    if (lines.length > 256) lines.removeAt(0);
    logChanges.notifyListeners();
  }

  List<String> runtimeLog(String id) => List.unmodifiable(_runtimeLogs[id] ?? const []);

  ExtensionTheme? get activeTheme {
    final candidates = installed
        .where((e) => e.enabled && e.granted.contains('theme.apply') && _themes.containsKey(e.id))
        .toList();
    if (candidates.length == 1) return _themes[candidates.single.id];
    if (candidates.isEmpty) return null;
    final conflict = ExtConflict(kind: ExtConflictKind.themeApply, extensionIds: candidates.map((e) => e.id).toList());
    final winner = _conflictWinners[conflict.key];
    return candidates.any((e) => e.id == winner) ? _themes[winner] : null;
  }

  List<ExtensionRoutingRule> get routingRules {
    final sources =
        installed.where((e) => e.enabled && e.granted.contains('routing.rules') && _routing.containsKey(e.id)).toList()
          ..sort((a, b) {
            final priority = _routing[b.id]!.priority.compareTo(_routing[a.id]!.priority);
            if (priority != 0) return priority;
            final time = a.installedAt.compareTo(b.installedAt);
            return time == 0 ? a.id.compareTo(b.id) : time;
          });
    return [for (final e in sources) ..._routing[e.id]!.rules];
  }

  void logRoutingOverlaps(List<String> userDestinations) {
    final before = [...userDestinations];
    for (final r in routingRules) {
      for (final earlier in before) {
        if (routingMatchesOverlap(earlier, r.rule.destination)) {
          appendLog(r.extensionId, 'routing overlap: $earlier precedes ${r.rule.destination}');
        }
      }
      before.add(r.rule.destination);
    }
  }

  void _validateAssets(ExtManifest m, String Function(String) read) {
    if (m.themeEntry != null) ExtensionTheme.parse(read(m.themeEntry!));
    if (m.routingEntry != null) ExtensionRouting.parse(m.id, read(m.routingEntry!));
  }

  Future<void> _loadRuntimeAssets() async {
    _themes.clear();
    _routing.clear();
    runtimeErrors.clear();
    for (final inst in installed) {
      try {
        final root = contentDir(inst.id), m = inst.manifest;
        Future<String> read(String entry) async {
          final f = File('$root/$entry');
          if (await f.length() > 1 << 20) throw const FormatException('extension asset exceeds 1 MiB');
          return f.readAsString();
        }

        if (m.themeEntry != null) _themes[inst.id] = ExtensionTheme.parse(await read(m.themeEntry!));
        if (m.routingEntry != null) _routing[inst.id] = ExtensionRouting.parse(inst.id, await read(m.routingEntry!));
      } catch (e) {
        runtimeErrors[inst.id] = e.toString();
        appendLog(inst.id, 'asset rejected: $e');
      }
    }
  }

  bool get loaded => _loaded;
  List<InstalledExtension> get installed =>
      _installed.values.toList()..sort((a, b) => a.manifest.name.compareTo(b.manifest.name));
  InstalledExtension? get(String id) => _installed[id];
  bool isInstalled(String id) => _installed.containsKey(id);
  bool isEnabled(String id) => _installed[id]?.enabled ?? false;

  /// Stable install-scoped random id for staged-rollout bucketing. Created
  /// once, stored next to the registry. Not a hardware id and never leaves
  /// the device: it only feeds the local rollout hash.
  String get installId => _installId;
  String _installId = '';

  /// Last verified team revocation list; null until one was fetched.
  late final RevocationCache revocationCache = RevocationCache(_dir);
  RevocationList? _revocations;

  /// Why [id] at its installed version was revoked, or null.
  RevocationEntry? revocationOf(String id) {
    final inst = _installed[id];
    return inst == null ? null : _revocations?.revocationOf(id, inst.version);
  }

  /// Fetches the team revocation list and disables installed matches.
  /// Returns the extensions it disabled so the UI can tell the user.
  Future<List<InstalledExtension>> refreshRevocations({http.Client? client}) async {
    _revocations = await revocationCache.refresh(client: client);
    return _enforceRevocations();
  }

  Future<List<InstalledExtension>> _enforceRevocations() async {
    final list = _revocations;
    if (list == null) return const [];
    final disabled = <InstalledExtension>[];
    for (final inst in _installed.values.toList()) {
      if (inst.enabled && list.revocationOf(inst.id, inst.version) != null) {
        final off = inst.copyWith(enabled: false);
        _installed[inst.id] = off;
        disabled.add(off);
      }
    }
    if (disabled.isNotEmpty) {
      await _save();
      notifyListeners();
    }
    return disabled;
  }

  /// The core's policy (core/ext checkRevocationsLocked): a revoked
  /// id@version is never installed or enabled, and an expired list blocks
  /// new installs because it can no longer be trusted to be complete.
  void _checkRevocation(String id, String version, {required bool installing}) {
    final list = _revocations;
    if (list == null) return;
    if (installing && list.expired(DateTime.now())) {
      throw ExtStoreError('the revocation list expired and could not be renewed; installs are blocked until it is');
    }
    final hit = list.revocationOf(id, version);
    if (hit != null) throw ExtStoreError('$id@$version was revoked by the Sora team: ${hit.reason}');
  }

  /// Offline team-catalog cache (verified bytes + fetch time).
  late final CatalogCache catalogCache = CatalogCache('$_dir${Platform.pathSeparator}catalog_cache');

  String _contentDir(String id, String version) => '$_dir${Platform.pathSeparator}$id@$version';

  String contentDir(String id) {
    final inst = _installed[id];
    if (inst == null) return '';
    return _contentDir(id, inst.version);
  }

  /// Loads the registry. Call once before use.
  Future<void>? _loading;
  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final d = Directory(_dir);
    await d.create(recursive: true);
    _installId = await _loadOrCreateInstallId();
    final reg = File('$_dir${Platform.pathSeparator}installed.json');
    if (await reg.exists()) {
      try {
        final raw = jsonDecode(await reg.readAsString()) as Map<String, dynamic>;
        for (final e in raw.entries) {
          try {
            _installed[e.key] = InstalledExtension.fromJson(e.value as Map<String, dynamic>);
          } catch (_) {
            // One corrupt entry must not brick the whole registry.
          }
        }
      } catch (_) {
        // Corrupt registry: start empty rather than crash the section.
      }
    }
    _revocations = await revocationCache.load();
    await _enforceRevocations();
    await _loadConflicts();
    await _loadRuntimeAssets();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final reg = File('$_dir${Platform.pathSeparator}installed.json');
    final tmp = File('${reg.path}.tmp');
    await tmp.writeAsString(jsonEncode({for (final e in _installed.entries) e.key: e.value.toJson()}), flush: true);
    await tmp.rename(reg.path);
  }

  // --- Conflict resolutions (which extension wins a contested surface) ---
  //
  // Stored separately from installed.json: resolutions change rarely and
  // must survive registry rewrites untouched.

  final _conflictWinners = <String, String>{};
  Future<void>? _conflictsLoad;

  String _conflictsFile() => '$_dir${Platform.pathSeparator}conflicts.json';

  /// Loads once; concurrent callers share the same future.
  Future<void> _loadConflicts() => _conflictsLoad ??= _doLoadConflicts();

  Future<void> _doLoadConflicts() async {
    final f = File(_conflictsFile());
    if (!await f.exists()) return;
    try {
      final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      for (final e in raw.entries) {
        final v = e.value;
        if (v is String && v.isNotEmpty) _conflictWinners[e.key] = v;
      }
    } catch (_) {
      // Corrupt resolutions fall back to "undecided": the banner reappears
      // and the user decides again. Never crash the section over this.
    }
  }

  Future<void> _saveConflicts() async {
    final f = File(_conflictsFile());
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(_conflictWinners), flush: true);
    await tmp.rename(f.path);
  }

  /// The winning extension id for [conflictKey], or null when undecided.
  /// Loads the file on first use; call after [load].
  Future<String?> conflictWinner(String conflictKey) async {
    await _loadConflicts();
    return _conflictWinners[conflictKey];
  }

  /// Synchronous read for UI code that already triggered a load (the
  /// conflicts banner resolves after the first frame anyway).
  String? conflictWinnerSync(String conflictKey) => _conflictWinners[conflictKey];

  /// All stored winners (conflict key -> extension id). Loads the file on
  /// first use; returns a copy.
  Future<Map<String, String>> conflictWinners() async {
    await _loadConflicts();
    return Map.of(_conflictWinners);
  }

  /// Records the user's decision. Throws [ExtStoreError] on I/O failure so
  /// the sheet can say the choice was not saved.
  Future<void> setConflictWinner(String conflictKey, String extensionId) async {
    await _loadConflicts();
    _conflictWinners[conflictKey] = extensionId;
    try {
      await _saveConflicts();
    } catch (_) {
      _conflictWinners.remove(conflictKey);
      throw ExtStoreError('could not save the conflict resolution');
    }
    notifyListeners();
  }

  /// Reads the install id, creating and persisting a fresh random one.
  /// A corrupt file is replaced, never fatal.
  Future<String> _loadOrCreateInstallId() async {
    final f = File('$_dir${Platform.pathSeparator}store_id');
    try {
      final existing = (await f.readAsString()).trim();
      if (RegExp(r'^[0-9a-f]{32}$').hasMatch(existing)) return existing;
    } catch (_) {
      // Missing or unreadable: create below.
    }
    final rnd = Random.secure();
    final id = List.generate(16, (_) => rnd.nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    try {
      await f.writeAsString(id, flush: true);
    } catch (_) {
      // Best effort: bucketing still works for this session.
    }
    return id;
  }

  /// Installs a verified package. Returns the permissions added relative to
  /// the previously installed version (empty for a fresh install) so the UI
  /// can re-prompt on widening updates.
  ///
  /// Installs an already-opened package.
  ///
  /// The signature and checksums are verified here. This is the single
  /// gate, so callers must not be relied upon to verify first.
  /// installs and is required then: the package signature is verified
  /// against the pin, never against the manifest's
  /// self-attested key, and the pin becomes the extension's trust anchor.
  /// For other sources the pin is ignored and the manifest's key is
  /// trusted on first use. An update whose author key differs from the
  /// pinned one is refused outright: key continuity, never a silent
  /// substitution.
  ///
  /// Throws [ExtStoreError] / [PackageError] with developer messages; the UI
  /// maps them to localized text.
  Future<List<String>> install(
    ExtPackage pkg, {
    required String source,
    required List<String> granted,
    String? authorKeyPin,
  }) async {
    final m = pkg.manifest;
    for (final g in granted) {
      if (!isKnownPermission(g)) throw ExtStoreError('unknown granted permission "$g"');
    }
    final missing = [
      for (final p in m.permissions)
        if (!granted.contains(p)) p,
    ];
    if (missing.isNotEmpty) {
      throw ExtStoreError('install does not grant required permissions: ${missing.join(", ")}');
    }
    _checkRevocation(m.id, m.version, installing: true);
    final cur = _installed[m.id];
    if (cur != null && compareVersions(m.version, cur.version) <= 0) {
      throw ExtStoreError('version ${m.version} is not newer than installed ${cur.version}');
    }
    // Author-key continuity: an update signed by a different key than the
    // pinned one is refused outright: a silent substitution of the trust
    // anchor (id squatting, catalog -> sideload cross-source swaps) must
    // never happen. The user can still get the new build by uninstalling
    // and installing it explicitly.
    final pinned = cur?.authorKey ?? cur?.manifest.author.publicKey;
    if (cur != null && !_sameAuthorKey(m.author.publicKey, pinned)) {
      throw ExtStoreError('author key changed for "${m.id}": refusing the update');
    }
    // The catalog pin is the trust anchor for catalog installs; without it
    // the install cannot prove it verified against the right key.
    if (source == 'catalog' && (authorKeyPin == null || authorKeyPin.trim().isEmpty)) {
      throw ExtStoreError('catalog install of "${m.id}" needs the catalog-pinned author key');
    }
    // Single verification gate: install() verifies the signature and
    // checksums itself instead of trusting every caller to have done it.
    // Callers may still verify earlier (e.g. to fail before showing the
    // install prompt), but no package reaches the disk unverified through
    // here. Throws [PackageError] on any integrity/authenticity failure.
    await pkg.verify(authorKeyLine: source == 'catalog' ? authorKeyPin : null);
    try {
      _validateAssets(m, (entry) {
        final bytes = pkg.files[entry]!;
        if (bytes.length > 1 << 20) throw const FormatException('extension asset exceeds 1 MiB');
        return utf8.decode(bytes);
      });
    } catch (e) {
      throw ExtAssetError('invalid extension asset: $e');
    }
    // Extract to a staging dir first; only touch the registry when the
    // content is fully on disk.
    final dst = _contentDir(m.id, m.version);
    await Directory(dst).create(recursive: true);
    try {
      for (final e in pkg.files.entries) {
        final target =
            '$_dir${Platform.pathSeparator}${m.id}@${m.version}${Platform.pathSeparator}${e.key.replaceAll('/', Platform.pathSeparator)}';
        final canonical = File(target).absolute.path;
        if (!canonical.startsWith('${Directory(dst).absolute.path}${Platform.pathSeparator}')) {
          throw ExtStoreError('unsafe extract path "${e.key}"');
        }
        await File(canonical).parent.create(recursive: true);
        await File(canonical).writeAsBytes(e.value, flush: true);
      }
    } catch (e) {
      await Directory(dst).delete(recursive: true);
      rethrow;
    }
    final added = cur == null ? <String>[] : diffPermissions(cur.granted, granted).added;
    // Drop the version that falls out of the N-1 window.
    if (cur?.previous != null) {
      final stale = Directory(_contentDir(m.id, cur!.previous!));
      if (await stale.exists()) await stale.delete(recursive: true);
    }
    // The trust anchor: the catalog pin for catalog installs, the
    // manifest's self-attested key otherwise (trust on first use). Updates
    // keep the previously pinned key; a changed key was refused above.
    // Registries written before pinning backfill from the previously
    // installed manifest on the next update.
    final String storedPin;
    if (cur != null) {
      storedPin = cur.authorKey ?? cur.manifest.author.publicKey;
    } else if (source == 'catalog') {
      storedPin = authorKeyPin!; // enforced non-empty above
    } else {
      storedPin = m.author.publicKey;
    }
    _installed[m.id] = InstalledExtension(
      manifest: m,
      enabled: cur?.enabled ?? true,
      source: source,
      installedAt: cur?.installedAt ?? DateTime.now(),
      granted: List.of(granted),
      previous: cur?.version,
      authorKey: storedPin,
    );
    await _save();
    await _loadRuntimeAssets();
    notifyListeners();
    return added;
  }

  /// Opens, verifies and installs raw .soraext bytes (file picker / download).
  ///
  /// [authorKeyPin] is the catalog-pinned author key for catalog installs:
  /// the signature is verified against it (never against the manifest's
  /// self-attested key) and it becomes the extension's trust anchor.
  Future<List<String>> installBytes(
    Uint8List data, {
    required String source,
    required List<String> granted,
    String? expectedSha256,
    String? authorKeyPin,
  }) async {
    if (expectedSha256 != null) {
      final sum = crypto.sha256.convert(data).toString();
      if (sum != expectedSha256.toLowerCase()) {
        throw ExtStoreError('download does not match the catalog sha256');
      }
    }
    final ExtPackage pkg;
    try {
      pkg = ExtPackage.open(data);
    } on PackageError catch (e) {
      throw ExtStoreError(e.message);
    }
    // Signature/checksum verification is the gate inside install(); wrap
    // its PackageError so this convenience entry point keeps reporting a
    // uniform ExtStoreError.
    try {
      return await install(pkg, source: source, granted: granted, authorKeyPin: authorKeyPin);
    } on PackageError catch (e) {
      throw ExtStoreError(e.message);
    }
  }

  /// One-tap enable/disable. Disabling takes effect immediately: the panel
  /// host tears the WebView down and drops the bridge.
  Future<void> setEnabled(String id, bool enabled) async {
    final cur = _installed[id];
    if (cur == null) throw ExtStoreError('"$id" is not installed');
    if (enabled) _checkRevocation(id, cur.version, installing: false);
    if (enabled && runtimeErrors.containsKey(id)) throw ExtAssetError(runtimeErrors[id]!);
    _installed[id] = cur.copyWith(enabled: enabled);
    notifyListeners();
    await _save();
  }

  /// Restores the N-1 version kept at install time.
  ///
  /// The previous version's signature and checksums are re-verified
  /// against the pinned author key before anything is touched: a tampered
  /// N-1 fails the rollback (fail closed) instead of becoming the served
  /// version.
  Future<void> rollback(String id) async {
    final cur = _installed[id];
    if (cur == null) throw ExtStoreError('"$id" is not installed');
    final prev = cur.previous;
    if (prev == null) throw ExtStoreError('"$id" has no previous version');
    _checkRevocation(id, prev, installing: false);
    final prevDir = Directory(_contentDir(id, prev));
    if (!await prevDir.exists()) throw ExtStoreError('previous version of "$id" is missing');
    // Re-read the previous manifest from disk (source of truth).
    final manFile = File('${prevDir.path}${Platform.pathSeparator}$manifestName');
    final prevManifest = ExtManifest.parse(await manFile.readAsString());
    if (prevManifest.id != id || prevManifest.version != prev) {
      throw ExtStoreError('previous manifest of "$id" does not match version "$prev"');
    }
    // Re-verify the on-disk files against the pinned author key (the trust
    // anchor), never against the on-disk manifest's self-attested key.
    final files = <String, Uint8List>{};
    final prefix = '${prevDir.path}${Platform.pathSeparator}';
    await for (final e in prevDir.list(recursive: true, followLinks: false)) {
      if (e is! File) continue;
      if (!e.path.startsWith(prefix)) continue; // paranoia: stay inside prevDir
      files[e.path.substring(prefix.length).replaceAll(Platform.pathSeparator, '/')] = await e.readAsBytes();
    }
    try {
      await ExtPackage.fromFiles(
        files,
        prevManifest,
      ).verify(authorKeyLine: cur.authorKey ?? cur.manifest.author.publicKey);
    } on PackageError catch (e) {
      throw ExtStoreError('previous version of "$id" failed its integrity re-check: ${e.message}');
    }
    _validateAssets(prevManifest, (entry) => utf8.decode(files[entry]!));
    await Directory(_contentDir(id, cur.version)).delete(recursive: true);
    _installed[id] = InstalledExtension(
      manifest: prevManifest,
      enabled: cur.enabled,
      source: cur.source,
      installedAt: cur.installedAt,
      granted: cur.granted,
      // The trust anchor survives the rollback: the previous version was
      // installed under the same pin.
      authorKey: cur.authorKey ?? cur.manifest.author.publicKey,
    );
    await _save();
    await _loadRuntimeAssets();
    notifyListeners();
  }

  Future<void> uninstall(String id) async {
    final cur = _installed[id];
    if (cur == null) throw ExtStoreError('"$id" is not installed');
    _installed[id] = cur.copyWith(enabled: false);
    notifyListeners();
    for (final v in [cur.version, if (cur.previous != null) cur.previous!]) {
      final d = Directory(_contentDir(id, v));
      if (await d.exists()) await d.delete(recursive: true);
    }
    final settings = File('$_dir${Platform.pathSeparator}$id.settings.json');
    if (await settings.exists()) await settings.delete();
    final background = File(_backgroundFile(id));
    if (await background.exists()) await background.delete();
    _installed.remove(id);
    _themes.remove(id);
    _routing.remove(id);
    _runtimeLogs.remove(id);
    runtimeErrors.remove(id);
    await _save();
    notifyListeners();
  }

  // --- Background task (runtime v2) ---

  String _backgroundFile(String id) => '$_dir${Platform.pathSeparator}$id.background.json';

  /// Reads the background task config. When never saved, the default seeds
  /// the interval from the manifest's declared `background_task` (the
  /// author's wish, clamped) so the settings show what the extension would
  /// do out of the box.
  Future<BackgroundTaskConfig> getBackgroundTask(String id) async {
    final inst = _installed[id];
    if (inst == null) throw ExtStoreError('"$id" is not installed');
    final f = File(_backgroundFile(id));
    if (await f.exists()) {
      try {
        final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        return BackgroundTaskConfig.fromJson(raw);
      } catch (_) {
        // Corrupt file falls back to defaults; the next save repairs it.
      }
    }
    final declared = inst.manifest.backgroundTask?.intervalMinutes;
    return BackgroundTaskConfig(
      enabled: true,
      intervalMinutes: BackgroundTaskConfig.clampInterval(declared ?? BackgroundTaskConfig.defaultIntervalMinutes),
    );
  }

  /// Saves the background task config, clamping the interval.
  Future<void> setBackgroundTask(String id, BackgroundTaskConfig config) async {
    if (!_installed.containsKey(id)) throw ExtStoreError('"$id" is not installed');
    final clamped = BackgroundTaskConfig(
      enabled: config.enabled,
      intervalMinutes: BackgroundTaskConfig.clampInterval(config.intervalMinutes),
    );
    await File(_backgroundFile(id)).writeAsString(jsonEncode(clamped.toJson()), flush: true);
    notifyListeners();
  }

  // --- Settings (validated against settings_schema) ---

  Map<String, dynamic> _schemaDefaults(ExtManifest m) {
    final out = <String, dynamic>{};
    final props = m.settingsSchema?['properties'] as Map<String, dynamic>?;
    if (props == null) return out;
    for (final e in props.entries) {
      final prop = e.value as Map<String, dynamic>?;
      if (prop != null && prop.containsKey('default')) out[e.key] = prop['default'];
    }
    return out;
  }

  Future<Map<String, dynamic>> getSettings(String id) async {
    final inst = _installed[id];
    if (inst == null) throw ExtStoreError('"$id" is not installed');
    final out = _schemaDefaults(inst.manifest);
    final f = File('$_dir${Platform.pathSeparator}$id.settings.json');
    if (await f.exists()) {
      try {
        final stored = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        out.addAll(stored);
      } catch (_) {
        // Corrupt settings fall back to defaults; the next save repairs.
      }
    }
    return out;
  }

  /// Merges [values] into the extension's stored settings: keys not
  /// mentioned keep their stored values. This is the documented panel
  /// contract (docs/extensions.md shows a one-key setSettings write, and
  /// the sora-ext mock has always merged) and matches the Go mirror
  /// (core/ext Store.SetSettings). The settings form passes the full
  /// form map, which merges to the same result. Validation runs first,
  /// so a rejected write changes nothing.
  Future<void> setSettings(String id, Map<String, dynamic> values) async {
    final inst = _installed[id];
    if (inst == null) throw ExtStoreError('"$id" is not installed');
    _validateSettingsValues(inst.manifest.settingsSchema, values);
    final f = File('$_dir${Platform.pathSeparator}$id.settings.json');
    final merged = <String, dynamic>{};
    if (await f.exists()) {
      try {
        merged.addAll(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt settings repair like getSettings: start from empty
        // rather than bricking every future save.
      }
    }
    merged.addAll(values);
    await f.writeAsString(jsonEncode(merged), flush: true);
    notifyListeners();
  }

  void _validateSettingsValues(Map<String, dynamic>? schema, Map<String, dynamic> values) {
    if (schema == null) {
      if (values.isNotEmpty) throw ExtStoreError('this extension has no settings');
      return;
    }
    final props = schema['properties'] as Map<String, dynamic>? ?? {};
    for (final e in values.entries) {
      final prop = props[e.key] as Map<String, dynamic>?;
      if (prop == null) throw ExtStoreError('unknown setting "${e.key}"');
      _checkValue(e.key, prop, e.value);
    }
  }

  void _checkValue(String name, Map<String, dynamic> prop, dynamic v) {
    switch (prop['type'] as String?) {
      case 'string':
        if (v is! String) throw ExtStoreError('setting "$name" must be a string');
        final min = (prop['minLength'] as num?)?.toInt();
        final max = (prop['maxLength'] as num?)?.toInt();
        if (min != null && v.length < min) throw ExtStoreError('setting "$name" is too short');
        if (max != null && v.length > max) throw ExtStoreError('setting "$name" is too long');
      case 'integer':
        if (v is! int) throw ExtStoreError('setting "$name" must be an integer');
        _checkRange(name, prop, (v as num).toDouble());
      case 'number':
        if (v is! num) throw ExtStoreError('setting "$name" must be a number');
        _checkRange(name, prop, v.toDouble());
      case 'boolean':
        if (v is! bool) throw ExtStoreError('setting "$name" must be true or false');
      default:
        throw ExtStoreError('setting "$name" has an unsupported type');
    }
    final en = prop['enum'] as List?;
    if (en != null && !en.any((e) => '$e' == '$v')) {
      throw ExtStoreError('setting "$name" has a disallowed value');
    }
  }

  void _checkRange(String name, Map<String, dynamic> prop, double f) {
    final min = (prop['minimum'] as num?)?.toDouble();
    final max = (prop['maximum'] as num?)?.toDouble();
    if (min != null && f < min) throw ExtStoreError('setting "$name" is too small');
    if (max != null && f > max) throw ExtStoreError('setting "$name" is too large');
  }
}

/// Background task configuration for an extension with the `background`
/// permission/capability (runtime v2).
///
/// The interval is clamped to [minIntervalMinutes]..[maxIntervalMinutes] on
/// both read and write, so a hand-edited file can never schedule runs more
/// often than the platform allows.
class BackgroundTaskConfig {
  const BackgroundTaskConfig({required this.enabled, required this.intervalMinutes});

  /// Shortest allowed interval: matches the platform background schedulers
  /// and the core worker runtime.
  static const int minIntervalMinutes = 15;

  /// Longest allowed interval: 7 days, mirroring the core worker runtime's
  /// MaxWorkerInterval.
  static const int maxIntervalMinutes = 7 * 24 * 60;

  static const int defaultIntervalMinutes = 60;

  final bool enabled;
  final int intervalMinutes;

  static int clampInterval(int v) => v.clamp(minIntervalMinutes, maxIntervalMinutes);

  factory BackgroundTaskConfig.defaults() =>
      const BackgroundTaskConfig(enabled: true, intervalMinutes: defaultIntervalMinutes);

  factory BackgroundTaskConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundTaskConfig(
      enabled: json['enabled'] as bool? ?? true,
      intervalMinutes: clampInterval((json['interval_minutes'] as num?)?.toInt() ?? defaultIntervalMinutes),
    );
  }

  Map<String, dynamic> toJson() => {'enabled': enabled, 'interval_minutes': intervalMinutes};
}

/// Provides the [ExtensionStore] to the extensions section subtree.
class ExtScope extends InheritedNotifier<ExtensionStore> {
  const ExtScope({super.key, required ExtensionStore store, required super.child}) : super(notifier: store);

  static ExtensionStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ExtScope>();
    assert(scope != null, 'ExtScope not found');
    return scope!.notifier!;
  }
}
