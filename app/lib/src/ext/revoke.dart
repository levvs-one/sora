/// Signed revocation list: the emergency brake for malicious or broken
/// extensions (mirrors core/ext/revoke.go and revocation_cache.go).
///
/// Format: revocations.json plus revocations.json.minisig (minisign, team
/// key — the same trust root as the catalog, and the same fail-closed rule
/// while the key ceremony is pending). The trusted comment is
/// "timestamp:..\tfile:revocations.json\tsha256:..".
///
/// Enforcement policy (honest, no theater — identical to core/ext):
///   - Install/Update of a revoked id@version is refused.
///   - Enabling a revoked extension is refused.
///   - No cached list: installs proceed. The catalog signature is the
///     primary gate; a missing list must not brick installs on first run
///     or before the team publishes one.
///   - Expired cached list: new installs, updates and enabling are refused
///     (fail closed — stale intel is worse than none), already-installed
///     extensions keep running. An offline device cannot receive a kill
///     order; pretending otherwise would be theater.
///   - Emergency kill is an entry with "versions": "*". The store
///     re-checks the list on every load and refresh and disables matches.
///
/// The cache lives in the app's own extensions directory (the Dart
/// registry): the core's `<dataDir>/extensions` belongs to a different
/// service account and is not readable from the app.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'catalog.dart';
import 'manifest.dart';
import 'verifier.dart';

/// Placeholder until the team publishes the revocation endpoint,
/// mirroring core/ext's DefaultRevocationURL.
const String defaultRevocationUrl =
    'https://extensions.sora.example/v1/revocations.json';

/// Revocation format version and limits (core/ext revoke.go).
const int revocationVersion = 1;
const int maxRevocationBytes = 64 << 10; // 64 KiB is plenty for an id list
const int _maxRevocationEntries = 4096;

/// Why a revocation operation failed. The UI maps [revoked] and [expired]
/// to their own localized messages; the rest collapse to the generic
/// install error, exactly like the other ext failure kinds.
enum RevocationErrorKind { invalid, revoked, expired, unconfigured, unavailable }

/// Thrown when a revocation list is malformed, untrusted, or blocks an
/// operation. The message is developer-facing; the UI maps failures to
/// localized text.
class RevocationError implements Exception {
  RevocationError(this.message, {this.kind = RevocationErrorKind.invalid});
  final String message;
  final RevocationErrorKind kind;
  @override
  String toString() => 'RevocationError: $message';
}

/// Reverse-DNS id pattern — the same shape core/ext pins (idPattern in
/// core/ext/manifest.go), also used by the Dart catalog parser.
final _revocationIdPattern =
    RegExp(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$');

/// Semver pattern — the same shape core/ext pins (semverPattern).
final _revocationSemverPattern =
    RegExp(r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([-+][0-9A-Za-z.-]+)?$');

/// One revocation entry: some versions of one extension id.
class RevocationEntry {
  const RevocationEntry({required this.id, required this.versions, required this.reason});
  final String id;

  /// Version constraint: "*", "=1.2.3", "<1.2.3" or "<=1.2.3".
  final String versions;
  final String reason;
}

/// A parsed revocations.json.
class RevocationList {
  const RevocationList({
    required this.version,
    required this.updatedAt,
    required this.expiresAt,
    required this.entries,
  });

  final int version;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final List<RevocationEntry> entries;

  /// Whether the list is past expires_at (core/ext: !ExpiresAt.After(now)).
  bool expired(DateTime now) => !expiresAt.isAfter(now);

  /// Whether id@version is revoked by this list.
  bool isRevoked(String id, String version) {
    for (final e in entries) {
      if (e.id != id) continue;
      if (versionMatches(e.versions, version)) return true;
    }
    return false;
  }

  /// Evaluates the tiny constraint language: "*" matches every version;
  /// otherwise "=x.y.z", "<x.y.z", "<=x.y.z" compare semver. Mirrors
  /// core/ext versionMatches, including "unsupported operator or missing
  /// operator never matches".
  static bool versionMatches(String constraint, String version) {
    if (constraint == '*') return true;
    final String op;
    final String want;
    if (constraint.startsWith('<=')) {
      op = '<=';
      want = constraint.substring(2);
    } else if (constraint.startsWith('<')) {
      op = '<';
      want = constraint.substring(1);
    } else if (constraint.startsWith('=')) {
      op = '=';
      want = constraint.substring(1);
    } else {
      return false;
    }
    final cmp = compareVersions(version, want);
    switch (op) {
      case '=':
        return cmp == 0;
      case '<':
        return cmp < 0;
      case '<=':
        return cmp <= 0;
    }
    return false;
  }

  /// Rejects anything outside the tiny constraint language above.
  static void _checkVersionConstraint(String c) {
    if (c == '*') return;
    var rest = c;
    for (final p in const ['<=', '<', '=']) {
      if (rest.startsWith(p)) {
        rest = rest.substring(p.length);
        break;
      }
    }
    if (rest == c) {
      throw RevocationError(
          'ext: bad version constraint "$c" (want "*", "=x.y.z", "<x.y.z" or "<=x.y.z")');
    }
    if (!_revocationSemverPattern.hasMatch(rest)) {
      throw RevocationError('ext: bad version "$rest" in constraint "$c"');
    }
  }

  static DateTime _parseTimestamp(dynamic raw, String what) {
    if (raw is! String) {
      throw RevocationError('ext: the revocation list needs $what');
    }
    try {
      return parseCatalogTimestamp(raw, 'revocation list $what');
    } on CatalogError catch (e) {
      throw RevocationError('ext: the revocation list has a bad $what: ${e.message}');
    }
  }

  /// Parses and validates revocations.json (no signature check; use
  /// [verifyRevocationList] for the trusted path). Mirrors core/ext
  /// ParseRevocationList, including its unknown-field, size, entry-count,
  /// duplicate and reason-length rules. Throws [RevocationError].
  static RevocationList parse(Uint8List data) {
    if (data.isEmpty || data.length > maxRevocationBytes) {
      throw RevocationError(
          'ext: the revocation list has a bad size (${data.length} bytes)');
    }
    // Go's json.Decoder rejects a UTF-8 BOM (it is not JSON whitespace)
    // while Dart's utf8.decode silently strips one — refuse it on the
    // raw bytes so both parsers accept exactly the same payloads.
    if (data.length >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
      throw RevocationError('ext: the revocation list must not start with a UTF-8 BOM');
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(data));
    } catch (e) {
      throw RevocationError('ext: the revocation list is not valid JSON: $e');
    }
    if (decoded is! Map<String, dynamic>) {
      throw RevocationError('ext: the revocation list top level must be an object');
    }
    const topKnown = {'revocation_version', 'updated_at', 'expires_at', 'entries'};
    for (final key in decoded.keys) {
      if (!topKnown.contains(key)) {
        throw RevocationError('ext: unknown revocation list field "$key"');
      }
    }
    // Strictly the JSON integer 1: Go's decoder refuses a "1.0" double
    // for the int field, and so does the Dart catalog parser.
    final version = decoded['revocation_version'];
    if (version is! int || version != revocationVersion) {
      throw RevocationError('ext: unsupported revocation_version $version (want $revocationVersion)');
    }
    final updatedAt = _parseTimestamp(decoded['updated_at'], 'updated_at');
    final expiresAt = _parseTimestamp(decoded['expires_at'], 'expires_at');
    if (!expiresAt.isAfter(updatedAt)) {
      throw RevocationError('ext: the revocation list expires before it was updated');
    }
    final rawEntries = decoded['entries'];
    if (rawEntries != null && rawEntries is! List) {
      throw RevocationError('ext: the revocation list entries must be a list');
    }
    final rows = (rawEntries as List?) ?? const [];
    if (rows.length > _maxRevocationEntries) {
      throw RevocationError('ext: the revocation list has too many entries (${rows.length})');
    }
    final entries = <RevocationEntry>[];
    final seen = <String>{};
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row is! Map<String, dynamic>) {
        throw RevocationError('ext: revocation entry $i is not an object');
      }
      const entryKnown = {'id', 'versions', 'reason'};
      for (final key in row.keys) {
        if (!entryKnown.contains(key)) {
          throw RevocationError('ext: unknown revocation entry field "$key"');
        }
      }
      final id = row['id'];
      final versions = row['versions'];
      final reason = row['reason'];
      if (id is! String || versions is! String || (reason != null && reason is! String)) {
        throw RevocationError('ext: revocation entry $i has non-string fields');
      }
      final reasonText = (reason as String?) ?? '';
      if (!_revocationIdPattern.hasMatch(id)) {
        throw RevocationError('ext: revocation entry $i has a bad id "$id"');
      }
      try {
        _checkVersionConstraint(versions);
      } on RevocationError catch (e) {
        throw RevocationError('ext: revocation entry $i ($id): ${e.message}');
      }
      // Go measures the reason with len() — UTF-8 bytes, not code units.
      if (utf8.encode(reasonText).length > 280) {
        throw RevocationError('ext: revocation entry $i ($id) has too long a reason');
      }
      if (!seen.add('$id\u0000$versions')) {
        throw RevocationError('ext: duplicate revocation entry for $id $versions');
      }
      entries.add(RevocationEntry(id: id, versions: versions, reason: reasonText));
    }
    return RevocationList(
        version: version, updatedAt: updatedAt, expiresAt: expiresAt, entries: entries);
  }
}

/// Verifies revocations.json.minisig with the team key and parses the
/// list. Fails closed while the key ceremony is pending, exactly like the
/// catalog signature (core/ext VerifyRevocationList).
///
/// [teamKeyOverride] exists for tests: production callers never pass it,
/// so the placeholder gate always applies to the real team key.
Future<RevocationList> verifyRevocationList(String sigText, Uint8List payload,
    {String? teamKeyOverride}) async {
  if (teamKeyOverride == null && !teamSigningConfigured) {
    throw RevocationError(
        'ext: team signing is not configured yet: cannot trust a revocation list until the key ceremony is done.',
        kind: RevocationErrorKind.unconfigured);
  }
  try {
    await verifyPayload(
        teamKeyOverride ?? teamPublicKey, sigText, 'revocations.json', payload);
  } on SignatureError catch (e) {
    throw RevocationError(e.message);
  }
  return RevocationList.parse(payload);
}

/// Downloads revocations.json and its .minisig and verifies the team
/// signature, returning the raw verified bytes (for the cache). https
/// only. Mirrors core/ext fetchRawRevocations.
Future<Uint8List> fetchRawRevocations(
    {http.Client? client, String url = defaultRevocationUrl, String? teamKeyOverride}) async {
  if (!url.startsWith('https://')) {
    throw RevocationError('ext: the revocation list URL must be https');
  }
  final c = client ?? http.Client();
  final owned = client == null;
  try {
    final body = await _get(c, url);
    final sig = await _get(c, '$url.minisig');
    await verifyRevocationList(utf8.decode(sig), body, teamKeyOverride: teamKeyOverride);
    return body;
  } finally {
    if (owned) c.close();
  }
}

Future<Uint8List> _get(http.Client c, String url) async {
  final http.Response resp;
  try {
    resp = await c.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
  } catch (e) {
    throw RevocationError('ext: cannot reach the revocation list: $e',
        kind: RevocationErrorKind.unavailable);
  }
  if (resp.statusCode != 200) {
    throw RevocationError('ext: the revocation list answered ${resp.statusCode}',
        kind: RevocationErrorKind.unavailable);
  }
  if (resp.bodyBytes.length > maxRevocationBytes) {
    throw RevocationError('ext: the revocation list is too large');
  }
  return resp.bodyBytes;
}

/// Offline revocation list cache: the last verified revocations.json
/// under [dir] (the app's extensions directory). Only verified bytes are
/// ever stored; a corrupt or missing cache is "no list", never a crash —
/// the enforcement policy for a missing list is defined in revoke.dart's
/// library docs and mirrors core/ext's RevocationCache.
class RevocationCache {
  RevocationCache(this.dir);
  final String dir;

  File get _file => File('$dir${Platform.pathSeparator}revocations.json');

  /// Saves raw revocations.json bytes. The bytes must already be
  /// signature-verified AND parseable; the cache refuses anything else,
  /// so a corrupt or unverified file can never be persisted by accident.
  Future<void> store(Uint8List verifiedRaw) async {
    RevocationList.parse(verifiedRaw); // throws when not a valid list
    await Directory(dir).create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsBytes(verifiedRaw, flush: true);
    await tmp.rename(_file.path);
  }

  /// Loads the cached list, or null when absent or corrupt.
  Future<RevocationList?> load() async {
    try {
      return RevocationList.parse(await _file.readAsBytes());
    } catch (_) {
      return null;
    }
  }

  /// Fetches the team revocation list and updates the cache. On any fetch
  /// or verification failure it falls back to the cached list when one
  /// exists ([fromCache] is then true); with no network and no cache, the
  /// fetch error is thrown. A cache write failure does not fail the
  /// refresh: the list itself is good. Mirrors core/ext Refresh.
  Future<({RevocationList list, bool fromCache})> refresh(
      {http.Client? client, String url = defaultRevocationUrl, String? teamKeyOverride}) async {
    try {
      final raw = await fetchRawRevocations(
          client: client, url: url, teamKeyOverride: teamKeyOverride);
      final list = RevocationList.parse(raw);
      try {
        await store(raw);
      } catch (_) {
        // A cache write failure must not fail the refresh.
      }
      return (list: list, fromCache: false);
    } catch (_) {
      final cached = await load();
      if (cached != null) return (list: cached, fromCache: true);
      rethrow;
    }
  }
}
