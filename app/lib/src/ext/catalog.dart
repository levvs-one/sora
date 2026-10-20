/// Team extension catalog: model, fetch and signature verification.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;

import 'manifest.dart';
import 'permissions.dart';
import 'verifier.dart';

class CatalogError implements Exception {
  CatalogError(this.message);
  final String message;
  @override
  String toString() => 'CatalogError: $message';
}

/// Placeholder until the team publishes the catalog endpoint.
const String defaultCatalogUrl = 'https://extensions.sora.example/v1/catalog.json';

const Set<String> catalogBadges = {'verified', 'top', 'new', 'staff'};

/// Reverse-DNS id and semver patterns — the same shapes core/ext pins
/// (idPattern / semverPattern in core/ext/manifest.go). The catalog is
/// team-signed, but the app validates it exactly like the core does: a
/// catalog the core would reject must not slip through the store.
final _catalogIdPattern =
    RegExp(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$');
final _catalogSemverPattern =
    RegExp(r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([-+][0-9A-Za-z.-]+)?$');

final _rfc3339Pattern = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|[+-]\d{2}:\d{2})$');

/// Parses a timestamp with Go's `time.Parse(time.RFC3339)` strictness:
/// Dart's DateTime.tryParse accepts date-only and space-separated
/// forms and silently rolls overflow days into the next month, all of
/// which the Go catalog parser rejects. Throws [CatalogError].
DateTime parseCatalogTimestamp(String s, String what) {
  final m = _rfc3339Pattern.firstMatch(s);
  if (m == null) throw CatalogError('$what is not RFC3339: "$s"');
  final year = int.parse(m[1]!), month = int.parse(m[2]!), day = int.parse(m[3]!);
  final hour = int.parse(m[4]!), minute = int.parse(m[5]!), second = int.parse(m[6]!);
  if (month < 1 || month > 12 || hour > 23 || minute > 59 || second > 59) {
    throw CatalogError('$what is not RFC3339: "$s"');
  }
  // Day must exist in the month (Go rejects Feb 31; DateTime.parse
  // would roll it over).
  if (day < 1 || day > DateTime.utc(year, month + 1, 0).day) {
    throw CatalogError('$what is not RFC3339: "$s"');
  }
  final parsed = DateTime.tryParse(s);
  if (parsed == null) throw CatalogError('$what is not RFC3339: "$s"');
  return parsed;
}

class CatalogEntry {
  CatalogEntry({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.authorIdentity,
    required this.authorKey,
    required this.iconUrl,
    required this.rating,
    required this.ratingsCount,
    required this.installs,
    required this.badges,
    required this.categories,
    required this.capabilities,
    required this.permissions,
    required this.downloadUrl,
    required this.sha256,
    required this.size,
    required this.minAppVersion,
    required this.rolloutFraction,
    required this.screenshotUrls,
    required this.changelog,
  });

  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final String authorIdentity;
  final String authorKey;
  final String iconUrl;
  final double rating;
  final int ratingsCount;
  final int installs;
  final List<String> badges;
  final List<String> categories;

  /// Manifest capabilities (theme, network-hook, routing, ui-panel,
  /// background, widget): the store filters on these.
  final List<String> capabilities;

  final List<String> permissions;
  final String downloadUrl;
  final String sha256;
  final int size;
  final String minAppVersion;

  /// Staged-rollout fraction 0..1; 0 (or absent) means fully rolled out.
  final double rolloutFraction;

  /// https screenshot URLs (<= 8) for the detail page.
  final List<String> screenshotUrls;

  /// Recent versions, newest first.
  final List<CatalogChangelogEntry> changelog;

  factory CatalogEntry.fromJson(Map<String, dynamic> json) {
    return CatalogEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? '',
      authorIdentity: json['author_identity'] as String? ?? '',
      authorKey: json['author_key'] as String? ?? '',
      iconUrl: json['icon_url'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      ratingsCount: (json['ratings_count'] as num? ?? 0).toInt(),
      installs: (json['installs'] as num? ?? 0).toInt(),
      badges: (json['badges'] as List? ?? []).map((e) => e.toString()).toList(),
      categories: (json['categories'] as List? ?? []).map((e) => e.toString()).toList(),
      capabilities: (json['capabilities'] as List? ?? []).map((e) => e.toString()).toList(),
      permissions: (json['permissions'] as List? ?? []).map((e) => e.toString()).toList(),
      downloadUrl: json['download_url'] as String? ?? '',
      sha256: (json['sha256'] as String? ?? '').toLowerCase(),
      size: (json['size'] as num? ?? 0).toInt(),
      minAppVersion: json['min_app_version'] as String? ?? '',
      rolloutFraction: (json['rollout_fraction'] as num? ?? 0).toDouble(),
      screenshotUrls: (json['screenshots'] as List? ?? []).map((e) => e.toString()).toList(),
      changelog: [
        for (final r in (json['changelog'] as List? ?? []))
          CatalogChangelogEntry.fromJson(_changelogRow(r)),
      ],
    );
  }

  /// A changelog row must be an object; a malformed row fails the whole
  /// entry rather than silently disappearing (the Go validator is strict
  /// too — a team-signed catalog with a broken row is a team bug that
  /// must surface).
  static Map<String, dynamic> _changelogRow(dynamic r) {
    if (r is Map<String, dynamic>) return r;
    throw CatalogError('changelog row is not an object');
  }

  bool get isVerified => badges.contains('verified');

  /// Effective rollout fraction: 1 when the catalog omits it or sets <= 0.
  double get effectiveRollout => rolloutFraction <= 0 ? 1.0 : rolloutFraction;

  /// Whether [installId] falls inside this version's staged-rollout bucket.
  /// Mirrors core/ext RolloutEligible: sha256(installId | id | version)
  /// with NUL separators, big-endian first 8 bytes mod 10000
  /// < fraction * 10000. Deterministic per device, so eligibility never
  /// flaps between catalog syncs. The modulo is folded incrementally to
  /// stay exact on 64-bit signed ints. The Go side pins this byte format
  /// with fixed vectors (TestRolloutEligiblePinnedVectors); both sides
  /// must give the same answers for those inputs.
  bool rolloutEligible(String installId) {
    final f = effectiveRollout;
    if (f >= 1) return true;
    // The separator is a literal NUL byte, exactly as in core/ext. It is
    // spelled \u0000 because Dart has no \x escape: in a Dart string
    // '\x00' is not NUL (an unrecognized escape degrades to the escaped
    // character, so the hashed bytes were "x00"), which silently
    // bucketed this side differently from the Go implementation.
    // crypto.sha256 must stay prefixed: the bare name `sha256` inside
    // this class resolves to the entry's own sha256 field (a String),
    // which shadowed the hash function and broke compilation.
    final digest = crypto.sha256
        .convert(utf8.encode('$installId\u0000$id\u0000$version'))
        .bytes;
    var mod = 0;
    for (var i = 0; i < 8; i++) {
      mod = (mod * 256 + digest[i]) % 10000;
    }
    return mod < (f * 10000).floor();
  }
}

/// One changelog row: a released version and its notes.
class CatalogChangelogEntry {
  CatalogChangelogEntry({required this.version, required this.date, required this.notes});
  final String version;
  final DateTime date;
  final String notes;

  factory CatalogChangelogEntry.fromJson(Map<String, dynamic> json) {
    const known = {'version', 'date', 'notes'};
    for (final key in json.keys) {
      if (!known.contains(key)) throw CatalogError('unknown changelog field "$key"');
    }
    return CatalogChangelogEntry(
      version: json['version'] as String? ?? '',
      // Go rejects a bad changelog date; the old code silently mapped
      // it to the epoch, which hid a broken (team-signed) catalog.
      date: parseCatalogTimestamp(json['date'] as String? ?? '', 'changelog date'),
      notes: json['notes'] as String? ?? '',
    );
  }
}

class ExtensionCatalog {
  ExtensionCatalog({required this.updatedAt, required this.entries, required this.maxAge});
  final DateTime updatedAt;
  final List<CatalogEntry> entries;

  /// Server's freshness promise, seconds (default 3600 when omitted).
  final int maxAge;

  CatalogEntry? find(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// True while the catalog is within its max_age freshness promise.
  bool fresh(DateTime fetchedAt, DateTime now) =>
      !now.isAfter(fetchedAt.add(Duration(seconds: maxAge)));

  static ExtensionCatalog parse(Uint8List data) {
    if (data.isEmpty || data.length > 4 * 1024 * 1024) {
      throw CatalogError('catalog has a bad size (${data.length} bytes)');
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(data));
    } catch (e) {
      throw CatalogError('catalog is not valid JSON: $e');
    }
    if (decoded is! Map<String, dynamic>) throw CatalogError('catalog top level must be an object');
    // The Go parser (ParseCatalog) rejects unknown fields everywhere
    // (DisallowUnknownFields) and non-integer values in integer fields;
    // mirror both, so one catalog gets one verdict on both sides.
    const topKnown = {'catalog_version', 'updated_at', 'extensions', 'max_age'};
    for (final key in decoded.keys) {
      if (!topKnown.contains(key)) throw CatalogError('unknown catalog field "$key"');
    }
    final catalogVersion = decoded['catalog_version'];
    if (catalogVersion is! int || catalogVersion != 1) {
      throw CatalogError('unsupported catalog_version $catalogVersion');
    }
    final updatedAt =
        parseCatalogTimestamp(decoded['updated_at'] as String? ?? '', 'catalog updated_at');
    final maxAgeRaw = decoded['max_age'];
    if (maxAgeRaw != null && maxAgeRaw is! int) {
      throw CatalogError('catalog max_age must be an integer');
    }
    final maxAge = maxAgeRaw as int?;
    if (maxAge != null && (maxAge < 300 || maxAge > 604800)) {
      throw CatalogError('catalog max_age is outside 300..604800');
    }
    final entries = <CatalogEntry>[];
    final seen = <String>{};
    for (final raw in (decoded['extensions'] as List? ?? [])) {
      final row = raw as Map<String, dynamic>;
      _checkEntryShape(row);
      final e = CatalogEntry.fromJson(row);
      _validateEntry(e);
      if (!seen.add(e.id)) throw CatalogError('catalog lists "${e.id}" twice');
      entries.add(e);
    }
    return ExtensionCatalog(
        updatedAt: updatedAt,
        entries: entries,
        maxAge: maxAge ?? 3600);
  }

  /// Raw-shape checks that must happen before [CatalogEntry.fromJson]
  /// converts values: unknown fields, and integer-typed fields that a
  /// JSON float would otherwise be silently truncated from.
  static void _checkEntryShape(Map<String, dynamic> json) {
    const known = {
      'id', 'name', 'version', 'description', 'author', 'author_identity',
      'author_key', 'icon_url', 'rating', 'ratings_count', 'installs',
      'badges', 'categories', 'capabilities', 'permissions', 'download_url',
      'sha256', 'size', 'min_app_version', 'rollout_fraction', 'screenshots',
      'changelog',
    };
    for (final key in json.keys) {
      if (!known.contains(key)) throw CatalogError('unknown catalog entry field "$key"');
    }
    for (final field in const ['ratings_count', 'installs', 'size']) {
      final v = json[field];
      if (v != null && v is! int) {
        throw CatalogError('catalog entry field "$field" must be an integer');
      }
    }
  }

  static void _validateEntry(CatalogEntry e) {
    if (!_catalogIdPattern.hasMatch(e.id)) {
      throw CatalogError('catalog entry has a bad id "${e.id}"');
    }
    if (e.name.trim().isEmpty || e.author.trim().isEmpty) {
      throw CatalogError('catalog entry needs id, name and author');
    }
    if (!_catalogSemverPattern.hasMatch(e.version) ||
        !_catalogSemverPattern.hasMatch(e.minAppVersion)) {
      throw CatalogError('entry "${e.id}" has a bad version');
    }
    if (e.rating < 0 || e.rating > 5) throw CatalogError('entry "${e.id}" has a bad rating');
    for (final b in e.badges) {
      if (!catalogBadges.contains(b)) throw CatalogError('entry "${e.id}" has unknown badge "$b"');
    }
    for (final u in [e.downloadUrl, e.iconUrl]) {
      if (u.isNotEmpty && !u.startsWith('https://')) {
        throw CatalogError('entry "${e.id}" has a non-https URL');
      }
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(e.sha256)) {
      throw CatalogError('entry "${e.id}" has a bad sha256');
    }
    if (e.size <= 0 || e.size > 64 * 1024 * 1024) {
      throw CatalogError('entry "${e.id}" has a bad size');
    }
    try {
      parsePublicKey(e.authorKey);
    } on SignatureError catch (err) {
      throw CatalogError('entry "${e.id}" has a bad author key: ${err.message}');
    }
    for (final p in e.permissions) {
      if (!isKnownPermission(p)) throw CatalogError('entry "${e.id}" wants unknown permission "$p"');
    }
    if (e.rolloutFraction.isNaN || e.rolloutFraction < 0 || e.rolloutFraction > 1) {
      throw CatalogError('entry "${e.id}" has a bad rollout_fraction');
    }
    if (e.screenshotUrls.length > 8) {
      throw CatalogError('entry "${e.id}" lists too many screenshots');
    }
    for (final u in e.screenshotUrls) {
      if (u.isEmpty || !u.startsWith('https://')) {
        throw CatalogError('entry "${e.id}" has a non-https screenshot');
      }
    }
    for (final c in e.changelog) {
      // Go checks the changelog version as semver and the notes length
      // in bytes; the date is already enforced as RFC3339 at parse time.
      if (!_catalogSemverPattern.hasMatch(c.version) ||
          c.notes.trim().isEmpty ||
          utf8.encode(c.notes).length > 2000) {
        throw CatalogError('entry "${e.id}" has a bad changelog row');
      }
    }
    for (final c in e.capabilities) {
      if (!isKnownCapability(c)) throw CatalogError('entry "${e.id}" has unknown capability "$c"');
    }
  }
}

/// Downloads catalog.json and its .minisig, verifies the team signature and
/// returns the parsed catalog. https only.
Future<ExtensionCatalog> fetchCatalog({http.Client? client, String url = defaultCatalogUrl}) async {
  final raw = await fetchRawCatalog(client: client, url: url);
  return ExtensionCatalog.parse(raw);
}

/// Downloads catalog.json and its .minisig and verifies the team
/// signature, returning the raw verified bytes (for the offline cache).
Future<Uint8List> fetchRawCatalog({http.Client? client, String url = defaultCatalogUrl}) async {
  if (!url.startsWith('https://')) throw CatalogError('catalog URL must be https');
  final c = client ?? http.Client();
  final owned = client == null;
  try {
    final body = await _get(c, url);
    final sig = await _get(c, '$url.minisig');
    try {
      await verifyCatalogSignature(utf8.decode(sig), body);
    } on SignatureError catch (e) {
      throw CatalogError(e.message);
    }
    return body;
  } finally {
    if (owned) c.close();
  }
}

Future<Uint8List> _get(http.Client c, String url) async {
  final resp = await c.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
  if (resp.statusCode != 200) throw CatalogError('catalog answered ${resp.statusCode}');
  if (resp.bodyBytes.length > 4 * 1024 * 1024) throw CatalogError('catalog is too large');
  return resp.bodyBytes;
}

/// Offline catalog cache: the last verified catalog.json plus its fetch
/// time, under [dir]. Served when the network or the signature check fails;
/// the UI shows the "cached - <date>" state instead of an error. Only
/// verified bytes are ever stored.
class CatalogCache {
  CatalogCache(this.dir);
  final String dir;

  File get _rawFile => File('$dir${Platform.pathSeparator}catalog.json');
  File get _metaFile => File('$dir${Platform.pathSeparator}catalog.json.meta');

  /// Stores verified catalog bytes (parse-checked before writing).
  Future<void> store(Uint8List raw) async {
    ExtensionCatalog.parse(raw); // throws when not a valid catalog
    await Directory(dir).create(recursive: true);
    final tmp = File('${_rawFile.path}.tmp');
    await tmp.writeAsBytes(raw, flush: true);
    await tmp.rename(_rawFile.path);
    await _metaFile.writeAsString(
        jsonEncode({'fetched_at': DateTime.now().toUtc().toIso8601String()}),
        flush: true);
  }

  /// Loads the cached catalog, or null when absent or corrupt (a corrupt
  /// cache is "no cache", never a crash).
  Future<({ExtensionCatalog catalog, DateTime fetchedAt})?> load() async {
    try {
      final raw = await _rawFile.readAsBytes();
      final catalog = ExtensionCatalog.parse(raw);
      final meta = jsonDecode(await _metaFile.readAsString()) as Map<String, dynamic>;
      final fetchedAt = DateTime.tryParse(meta['fetched_at'] as String? ?? '');
      if (fetchedAt == null) return null;
      return (catalog: catalog, fetchedAt: fetchedAt);
    } catch (_) {
      return null;
    }
  }

  /// Fetches the team catalog and updates the cache. On any fetch or
  /// verification failure falls back to the cached catalog when one exists
  /// ([fromCache] is then true and the UI must say so). With no network
  /// and no cache, the fetch error is rethrown.
  Future<({ExtensionCatalog catalog, bool fromCache, DateTime fetchedAt})> refresh(
      {http.Client? client, String url = defaultCatalogUrl}) async {
    try {
      final raw = await fetchRawCatalog(client: client, url: url);
      final catalog = ExtensionCatalog.parse(raw);
      try {
        await store(raw);
      } catch (_) {
        // A cache write failure must not fail the refresh.
      }
      return (catalog: catalog, fromCache: false, fetchedAt: DateTime.now().toUtc());
    } catch (_) {
      final cached = await load();
      if (cached != null) {
        return (catalog: cached.catalog, fromCache: true, fetchedAt: cached.fetchedAt);
      }
      rethrow;
    }
  }
}
