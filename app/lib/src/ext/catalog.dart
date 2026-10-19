/// Team extension catalog: model, fetch and signature verification.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

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
    required this.permissions,
    required this.downloadUrl,
    required this.sha256,
    required this.size,
    required this.minAppVersion,
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
  final List<String> permissions;
  final String downloadUrl;
  final String sha256;
  final int size;
  final String minAppVersion;

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
      permissions: (json['permissions'] as List? ?? []).map((e) => e.toString()).toList(),
      downloadUrl: json['download_url'] as String? ?? '',
      sha256: (json['sha256'] as String? ?? '').toLowerCase(),
      size: (json['size'] as num? ?? 0).toInt(),
      minAppVersion: json['min_app_version'] as String? ?? '',
    );
  }

  bool get isVerified => badges.contains('verified');
}

class ExtensionCatalog {
  ExtensionCatalog({required this.updatedAt, required this.entries});
  final DateTime updatedAt;
  final List<CatalogEntry> entries;

  CatalogEntry? find(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

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
    if (decoded['catalog_version'] != 1) {
      throw CatalogError('unsupported catalog_version ${decoded['catalog_version']}');
    }
    final updatedAt = DateTime.tryParse(decoded['updated_at'] as String? ?? '');
    if (updatedAt == null) throw CatalogError('catalog updated_at is not a date');
    final entries = <CatalogEntry>[];
    final seen = <String>{};
    for (final raw in (decoded['extensions'] as List? ?? [])) {
      final e = CatalogEntry.fromJson(raw as Map<String, dynamic>);
      _validateEntry(e);
      if (!seen.add(e.id)) throw CatalogError('catalog lists "${e.id}" twice');
      entries.add(e);
    }
    return ExtensionCatalog(updatedAt: updatedAt, entries: entries);
  }

  static void _validateEntry(CatalogEntry e) {
    if (e.id.isEmpty || e.name.trim().isEmpty || e.author.trim().isEmpty) {
      throw CatalogError('catalog entry needs id, name and author');
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
  }
}

/// Downloads catalog.json and its .minisig, verifies the team signature and
/// returns the parsed catalog. https only.
Future<ExtensionCatalog> fetchCatalog({http.Client? client, String url = defaultCatalogUrl}) async {
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
    return ExtensionCatalog.parse(body);
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
