/// Extension manifest v1 model (mirrors core/ext/manifest.go).
///
/// The app is the trust boundary for installs, so it parses and validates
/// the manifest itself instead of trusting the core or the network.
library;

import 'dart:convert';

import 'permissions.dart';

/// Thrown when a manifest is malformed or violates the v1 rules. The message
/// is a developer-facing detail; the UI maps failures to localized text.
class ManifestError implements Exception {
  ManifestError(this.message);
  final String message;
  @override
  String toString() => 'ManifestError: $message';
}

class ExtAuthor {
  ExtAuthor({required this.name, required this.identity, required this.publicKey});
  final String name;
  final String identity;
  final String publicKey;

  factory ExtAuthor.fromJson(Map<String, dynamic> json) {
    return ExtAuthor(
      name: (json['name'] as String? ?? '').trim(),
      identity: (json['identity'] as String? ?? '').trim(),
      publicKey: (json['public_key'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'identity': identity, 'public_key': publicKey};
}

class ExtPanel {
  ExtPanel({required this.id, required this.title, required this.entry});
  final String id;
  final String title;
  final String entry;

  factory ExtPanel.fromJson(Map<String, dynamic> json) {
    return ExtPanel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      entry: json['entry'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'entry': entry};
}

class ExtManifest {
  ExtManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.minAppVersion,
    required this.description,
    required this.author,
    required this.permissions,
    required this.capabilities,
    required this.panels,
    this.settingsSchema,
  });

  final String id;
  final String name;
  final String version;
  final String minAppVersion;
  final String description;
  final ExtAuthor author;
  final List<String> permissions;
  final List<String> capabilities;
  final List<ExtPanel> panels;
  final Map<String, dynamic>? settingsSchema;

  static final _idPattern = RegExp(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$');
  static final _panelIdPattern = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final _semverPattern =
      RegExp(r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)([-+][0-9A-Za-z.-]+)?$');

  /// Parses and validates sora-extension.json. Throws [ManifestError].
  factory ExtManifest.parse(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      throw ManifestError('not valid JSON: $e');
    }
    if (decoded is! Map<String, dynamic>) {
      throw ManifestError('top level must be an object');
    }
    const known = {
      'manifest_version', 'id', 'name', 'version', 'min_app_version',
      'description', 'author', 'permissions', 'capabilities', 'ui', 'settings_schema',
    };
    for (final key in decoded.keys) {
      if (!known.contains(key)) throw ManifestError('unknown field "$key"');
    }
    if (decoded['manifest_version'] != 1) {
      throw ManifestError('unsupported manifest_version ${decoded['manifest_version']}');
    }
    final m = ExtManifest(
      id: decoded['id'] as String? ?? '',
      name: decoded['name'] as String? ?? '',
      version: decoded['version'] as String? ?? '',
      minAppVersion: decoded['min_app_version'] as String? ?? '',
      description: decoded['description'] as String? ?? '',
      author: ExtAuthor.fromJson(decoded['author'] as Map<String, dynamic>? ?? {}),
      permissions: (decoded['permissions'] as List? ?? []).map((e) => e.toString()).toList(),
      capabilities: (decoded['capabilities'] as List? ?? []).map((e) => e.toString()).toList(),
      panels: (((decoded['ui'] as Map<String, dynamic>?)?['panels'] as List?) ?? [])
          .map((e) => ExtPanel.fromJson(e as Map<String, dynamic>))
          .toList(),
      settingsSchema: decoded['settings_schema'] as Map<String, dynamic>?,
    );
    m.validate();
    return m;
  }

  /// Validates every field against the v1 rules. Throws [ManifestError].
  void validate() {
    if (!_idPattern.hasMatch(id)) {
      throw ManifestError('id "$id" must be reverse-DNS (e.g. com.example.stats)');
    }
    final n = name.trim();
    if (n.isEmpty || n.length > 80) throw ManifestError('name must be 1..80 characters');
    if (!_semverPattern.hasMatch(version)) throw ManifestError('version "$version" must be semver');
    if (!_semverPattern.hasMatch(minAppVersion)) {
      throw ManifestError('min_app_version "$minAppVersion" must be semver');
    }
    if (description.length > 2000) throw ManifestError('description exceeds 2000 characters');
    if (author.name.trim().isEmpty || author.name.length > 80) {
      throw ManifestError('author name must be 1..80 characters');
    }
    if (author.identity.trim().isEmpty || author.identity.length > 160) {
      throw ManifestError('author identity must be 1..160 characters');
    }
    if (author.publicKey.isEmpty) throw ManifestError('author public key is required');
    final seen = <String>{};
    for (final p in permissions) {
      if (!isKnownPermission(p)) throw ManifestError('unknown permission "$p"');
      if (!seen.add(p)) throw ManifestError('duplicate permission "$p"');
    }
    for (final c in capabilities) {
      if (!isKnownCapability(c)) throw ManifestError('unknown capability "$c"');
    }
    final panelIds = <String>{};
    for (final p in panels) {
      if (!_panelIdPattern.hasMatch(p.id)) throw ManifestError('bad panel id "${p.id}"');
      if (!panelIds.add(p.id)) throw ManifestError('duplicate panel id "${p.id}"');
      final t = p.title.trim();
      if (t.isEmpty || t.length > 60) throw ManifestError('panel "${p.id}" needs a title of 1..60 characters');
      if (!isSafeEntry(p.entry)) {
        throw ManifestError('panel "${p.id}" has an unsafe entry "${p.entry}"');
      }
    }
    if (settingsSchema != null) validateSettingsSchema(settingsSchema!);
  }

  Map<String, dynamic> toJson() => {
        'manifest_version': 1,
        'id': id,
        'name': name,
        'version': version,
        'min_app_version': minAppVersion,
        'description': description,
        'author': author.toJson(),
        'permissions': permissions,
        'capabilities': capabilities,
        'ui': {
          'panels': [for (final p in panels) p.toJson()],
        },
        if (settingsSchema != null) 'settings_schema': settingsSchema,
      };
}

/// Allows only relative .html paths without traversal.
bool isSafeEntry(String entry) {
  if (entry.isEmpty || entry.length > 256) return false;
  if (!entry.toLowerCase().endsWith('.html')) return false;
  if (entry.contains('..') || entry.startsWith('/') || entry.startsWith('\\')) return false;
  for (final part in entry.split('/')) {
    if (part.isEmpty || part == '.') return false;
  }
  return true;
}

const _knownCapabilities = {'theme', 'network-hook', 'routing', 'ui-panel', 'background', 'widget'};

bool isKnownCapability(String c) => _knownCapabilities.contains(c);

/// Validates the settings_schema subset (object with typed properties).
void validateSettingsSchema(Map<String, dynamic> schema) {
  final type = schema['type'] as String?;
  if (type != null && type != 'object') {
    throw ManifestError('settings_schema type must be "object"');
  }
  final props = schema['properties'] as Map<String, dynamic>?;
  if (props == null) return;
  for (final e in props.entries) {
    if (e.key.isEmpty || e.key.length > 64) {
      throw ManifestError('bad settings property name "${e.key}"');
    }
    final prop = e.value as Map<String, dynamic>?;
    if (prop == null) throw ManifestError('settings property "${e.key}" must be an object');
    switch (prop['type'] as String?) {
      case 'string':
      case 'integer':
      case 'number':
      case 'boolean':
        break;
      case null:
        throw ManifestError('settings property "${e.key}" needs a type');
      default:
        throw ManifestError('settings property "${e.key}" has unsupported type "${prop['type']}"');
    }
  }
}

/// Compares two semver strings: -1, 0, +1.
int compareVersions(String a, String b) {
  List<int> parts(String v) {
    final core = v.split(RegExp(r'[-+]')).first;
    final out = [0, 0, 0];
    final segs = core.split('.');
    for (var i = 0; i < 3 && i < segs.length; i++) {
      out[i] = int.tryParse(segs[i]) ?? 0;
    }
    return out;
  }

  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    if (pa[i] != pb[i]) return pa[i] < pb[i] ? -1 : 1;
  }
  return 0;
}
