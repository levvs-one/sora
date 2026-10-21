/// Team revocation list for extensions, the app-side mirror of
/// core/ext/revoke.go.
///
/// revocations.json plus revocations.json.minisig, signed with the team key
/// for the role "revocations.json". Policy, the same as the core:
/// - installing, updating, rolling back to or enabling a revoked id@version
///   is refused, and an installed match is disabled;
/// - no list yet: installs proceed, the catalog signature is the primary
///   gate;
/// - an expired list: new installs and updates are refused, installed
///   extensions keep running, because a device that cannot fetch a fresh
///   list cannot receive a kill order either.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'catalog.dart';
import 'manifest.dart';
import 'verifier.dart';

const _maxRevocationBytes = 64 * 1024;
const _maxRevocationEntries = 4096;
final _constraintVersion = RegExp(r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$');

class RevocationError implements Exception {
  RevocationError(this.message);
  final String message;
  @override
  String toString() => 'RevocationError: $message';
}

class RevocationEntry {
  const RevocationEntry({required this.id, required this.versions, required this.reason});
  final String id;

  /// "*", "=x.y.z", "<x.y.z" or "<=x.y.z".
  final String versions;
  final String reason;

  bool matches(String version) {
    if (versions == '*') return true;
    final (op, want) = _split(versions);
    final cmp = compareVersions(version, want);
    return switch (op) {
      '=' => cmp == 0,
      '<' => cmp < 0,
      '<=' => cmp <= 0,
      _ => false,
    };
  }

  static (String, String) _split(String c) {
    for (final op in ['<=', '<', '=']) {
      if (c.startsWith(op)) return (op, c.substring(op.length));
    }
    return ('', c);
  }
}

class RevocationList {
  RevocationList({required this.updatedAt, required this.expiresAt, required this.entries});
  final DateTime updatedAt;
  final DateTime expiresAt;
  final List<RevocationEntry> entries;

  bool expired(DateTime now) => !expiresAt.isAfter(now);

  RevocationEntry? revocationOf(String id, String version) {
    for (final e in entries) {
      if (e.id == id && e.matches(version)) return e;
    }
    return null;
  }

  /// Parses and strictly validates a list, like ParseRevocationList in Go.
  static RevocationList parse(Uint8List raw) {
    if (raw.length > _maxRevocationBytes) throw RevocationError('revocation list is too large');
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(raw));
    } on FormatException catch (e) {
      throw RevocationError('revocation list is not JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) throw RevocationError('revocation list must be an object');
    if (decoded['revocation_version'] != 1) throw RevocationError('unsupported revocation_version');
    final updatedAt = DateTime.tryParse(decoded['updated_at'] as String? ?? '');
    final expiresAt = DateTime.tryParse(decoded['expires_at'] as String? ?? '');
    if (updatedAt == null || expiresAt == null) {
      throw RevocationError('revocation list needs updated_at and expires_at');
    }
    if (!expiresAt.isAfter(updatedAt)) throw RevocationError('revocation list expires before it was updated');
    final rawEntries = decoded['entries'];
    if (rawEntries is! List) throw RevocationError('revocation list needs an entries array');
    if (rawEntries.length > _maxRevocationEntries) throw RevocationError('revocation list has too many entries');
    final entries = <RevocationEntry>[];
    for (final e in rawEntries) {
      if (e is! Map<String, dynamic>) throw RevocationError('revocation entry must be an object');
      final id = e['id'];
      final versions = e['versions'];
      if (id is! String || id.isEmpty) throw RevocationError('revocation entry needs an id');
      if (versions is! String || !_validConstraint(versions)) {
        throw RevocationError('revocation entry "$id" has a bad version constraint');
      }
      entries.add(RevocationEntry(id: id, versions: versions, reason: e['reason'] as String? ?? ''));
    }
    return RevocationList(updatedAt: updatedAt, expiresAt: expiresAt, entries: entries);
  }

  static bool _validConstraint(String c) {
    if (c == '*') return true;
    final (op, want) = RevocationEntry._split(c);
    return op.isNotEmpty && _constraintVersion.hasMatch(want);
  }
}

/// Verifies a signed list and parses it.
Future<RevocationList> verifyRevocationList(String sigText, Uint8List payload) async {
  if (!teamSigningConfigured) throw RevocationError('team signing is not configured');
  try {
    await verifyPayload(teamPublicKey, sigText, 'revocations.json', payload);
  } on SignatureError catch (e) {
    throw RevocationError(e.message);
  }
  return RevocationList.parse(payload);
}

/// The last verified list on disk. Both files are kept so the signature is
/// checked again on every load: the cache lives on user-writable disk.
class RevocationCache {
  RevocationCache(this.dir);
  final String dir;

  File get _raw => File('$dir${Platform.pathSeparator}revocations.json');
  File get _sig => File('$dir${Platform.pathSeparator}revocations.json.minisig');

  Future<RevocationList?> load() async {
    try {
      return await verifyRevocationList(await _sig.readAsString(), await _raw.readAsBytes());
    } catch (_) {
      // Missing or tampered cache is "no list", the same as a first run.
      return null;
    }
  }

  /// Downloads, verifies and stores the list. A failed fetch throws and
  /// leaves the cache untouched.
  Future<RevocationList> refresh({http.Client? client, String url = defaultRevocationUrl}) async {
    if (!url.startsWith('https://')) throw RevocationError('revocation URL must be https');
    final c = client ?? http.Client();
    try {
      final body = await _get(c, url);
      final sig = await _get(c, '$url.minisig');
      final list = await verifyRevocationList(utf8.decode(sig), body);
      await Directory(dir).create(recursive: true);
      for (final (file, bytes) in [(_raw, body), (_sig, sig)]) {
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsBytes(bytes, flush: true);
        await tmp.rename(file.path);
      }
      return list;
    } finally {
      if (client == null) c.close();
    }
  }

  static Future<Uint8List> _get(http.Client c, String url) async {
    final resp = await c.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) throw RevocationError('revocation list answered ${resp.statusCode}');
    if (resp.bodyBytes.length > _maxRevocationBytes) throw RevocationError('revocation list is too large');
    return resp.bodyBytes;
  }
}
