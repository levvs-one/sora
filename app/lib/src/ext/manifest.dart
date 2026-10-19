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
    this.networkHosts = const [],
    this.backgroundTask,
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

  /// Host allowlist for the `net.fetch` permission (runtime v2): the
  /// extension may fetch only these hosts. Declared by the manifest so the
  /// install prompt can show the exact list before anything is granted.
  /// Empty when the manifest declares none. Stored lowercase, mirroring
  /// core/ext's normalization.
  final List<String> networkHosts;

  /// The declared background task (runtime v2): the author's wished
  /// interval and the worker script. Null when not declared. The runtime
  /// clamps the interval; the user can override it in the extension
  /// settings.
  final ExtBackgroundTask? backgroundTask;

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
      'network_hosts', 'background_task',
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
      networkHosts: _parseNetworkHosts(decoded['network_hosts']),
      backgroundTask: _parseBackgroundTask(decoded['background_task']),
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
    if (networkHosts.isNotEmpty && !permissions.contains('net.fetch')) {
      throw ManifestError('network_hosts requires the "net.fetch" permission');
    }
    final seenHosts = <String>{};
    for (final h in networkHosts) {
      if (!_networkHostPattern.hasMatch(h) || _isIpLiteral(h)) {
        throw ManifestError('bad network host "$h"');
      }
      if (!seenHosts.add(h)) {
        throw ManifestError('duplicate network host "$h"');
      }
    }
    backgroundTask?.validate(this);
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
        if (networkHosts.isNotEmpty) 'network_hosts': networkHosts,
        if (backgroundTask != null) 'background_task': backgroundTask!.toJson(),
      };
}

/// One declared background task (runtime v2, mirrors core/ext's
/// BackgroundTask): the author's wished interval and the worker script
/// inside the package. The runtime clamps the interval; the user override
/// lives in the extension settings, not here.
class ExtBackgroundTask {
  ExtBackgroundTask({required this.intervalMinutes, required this.entry});
  final int intervalMinutes;
  final String entry;

  /// Largest declarable interval: 7 days (mirrors core/ext).
  static const int maxIntervalMinutes = 7 * 24 * 60;

  factory ExtBackgroundTask.fromJson(Map<String, dynamic> json) {
    const known = {'interval_minutes', 'entry'};
    for (final key in json.keys) {
      if (!known.contains(key)) throw ManifestError('unknown background_task field "$key"');
    }
    final interval = json['interval_minutes'];
    if (interval is! int) throw ManifestError('background_task interval_minutes must be an integer');
    final entry = (json['entry'] as String? ?? '').trim();
    return ExtBackgroundTask(intervalMinutes: interval, entry: entry);
  }

  /// Cross-checks against the manifest: the task needs the `background`
  /// capability and permission, a sane interval and a safe script path.
  void validate(ExtManifest m) {
    if (!m.capabilities.contains('background')) {
      throw ManifestError('background_task requires the "background" capability');
    }
    if (!m.permissions.contains('background')) {
      throw ManifestError('background_task requires the "background" permission');
    }
    if (intervalMinutes < 1 || intervalMinutes > maxIntervalMinutes) {
      throw ManifestError(
          'background_task interval_minutes must be 1..$maxIntervalMinutes');
    }
    if (!_workerEntryPattern.hasMatch(entry) ||
        entry.contains('..') ||
        entry.startsWith('/')) {
      throw ManifestError(
          'background_task entry "$entry" must be a relative .js path without traversal');
    }
  }

  Map<String, dynamic> toJson() =>
      {'interval_minutes': intervalMinutes, 'entry': entry};
}

/// Worker script names: relative .js path, no traversal (mirrors core/ext).
final _workerEntryPattern =
    RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_./-]{0,255}\.js$');

ExtBackgroundTask? _parseBackgroundTask(dynamic raw) {
  if (raw == null) return null;
  if (raw is! Map<String, dynamic>) {
    throw ManifestError('background_task must be an object');
  }
  return ExtBackgroundTask.fromJson(raw);
}

/// Host allowlist for `net.fetch`: plain or wildcard (`*.example.com`)
/// DNS names, at most 64 entries.
final _networkHostPattern = RegExp(
    r'^(\*\.)?([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$');

List<String> _parseNetworkHosts(dynamic raw) {
  if (raw == null) return const [];
  if (raw is! List) throw ManifestError('network_hosts must be a list');
  if (raw.length > 64) throw ManifestError('network_hosts exceeds 64 entries');
  final out = <String>[];
  for (final e in raw) {
    // Normalized to lowercase like core/ext: the allowlist is DNS names
    // only, and matching is case-insensitive.
    final h = e.toString().trim().toLowerCase();
    if (h.isEmpty || h.length > 253) throw ManifestError('bad network host "$h"');
    out.add(h);
  }
  return out;
}

/// True for IPv4 literals, which the allowlist rejects: they are DNS names
/// only (mirrors core/ext's isIPLiteral; IPv6 cannot pass the host pattern
/// since ':' is not allowed there).
bool _isIpLiteral(String h) {
  final parts = h.split('.');
  if (parts.length != 4) return false;
  for (final p in parts) {
    if (p.isEmpty || p.length > 3) return false;
    final n = int.tryParse(p);
    if (n == null || n > 255) return false;
  }
  return true;
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
