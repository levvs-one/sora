/// Extension manifest v1 model (mirrors core/ext/manifest.go).
///
/// The app is the trust boundary for installs, so it parses and validates
/// the manifest itself instead of trusting the core or the network.
library;

import 'dart:convert';

import 'permissions.dart';
import 'verifier.dart';

/// Length in UTF-8 bytes. Go's validators measure with len(), so a
/// Cyrillic name counts double there; measuring Dart code units here
/// let manifests through that core/ext then rejected.
int _utf8Len(String s) => utf8.encode(s).length;

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
    // Mirrors core/ext's DisallowUnknownFields: a stray key in a nested
    // object is a malformed manifest, not something to silently drop.
    const known = {'name', 'identity', 'public_key'};
    for (final key in json.keys) {
      if (!known.contains(key)) throw ManifestError('unknown author field "$key"');
    }
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
    const known = {'id', 'title', 'entry'};
    for (final key in json.keys) {
      if (!known.contains(key)) throw ManifestError('unknown panel field "$key"');
    }
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
    this.themeEntry,
    this.networkHookEntry,
    this.routingEntry,
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

  /// Capability contract pointers (v0, proposed — mirrors core/ext's
  /// ManifestExt): entry files for the theme / network-hook / routing
  /// contracts. Null when not declared. Only the pointer (capability +
  /// permission cross-check, safe path) is validated here; the asset
  /// files' own schemas are proposals, see docs/extensions.md.
  final String? themeEntry;
  final String? networkHookEntry;
  final String? routingEntry;

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
      'network_hosts', 'background_task', 'theme', 'network_hook', 'routing',
    };
    for (final key in decoded.keys) {
      if (!known.contains(key)) throw ManifestError('unknown field "$key"');
    }
    // Strictly the JSON integer 1: a "1.0" double compares equal to 1
    // in Dart but Go's decoder refuses it for the int field.
    final manifestVersion = decoded['manifest_version'];
    if (manifestVersion is! int || manifestVersion != 1) {
      throw ManifestError('unsupported manifest_version $manifestVersion');
    }
    final uiRaw = decoded['ui'];
    if (uiRaw is Map<String, dynamic>) {
      const uiKnown = {'panels'};
      for (final key in uiRaw.keys) {
        if (!uiKnown.contains(key)) throw ManifestError('unknown ui field "$key"');
      }
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
      themeEntry: _parseAssetRef(decoded['theme'], 'theme'),
      networkHookEntry: _parseAssetRef(decoded['network_hook'], 'network_hook'),
      routingEntry: _parseAssetRef(decoded['routing'], 'routing'),
    );
    m.validate();
    return m;
  }

  /// Validates every field against the v1 rules. Throws [ManifestError].
  void validate() {
    if (!_idPattern.hasMatch(id)) {
      throw ManifestError('id "$id" must be reverse-DNS (e.g. com.example.stats)');
    }
    // Length limits mirror Go exactly: emptiness is judged on the
    // trimmed value, the limit on the raw value's UTF-8 byte length.
    if (name.trim().isEmpty || _utf8Len(name) > 80) {
      throw ManifestError('name must be 1..80 characters');
    }
    if (!_semverPattern.hasMatch(version)) throw ManifestError('version "$version" must be semver');
    if (!_semverPattern.hasMatch(minAppVersion)) {
      throw ManifestError('min_app_version "$minAppVersion" must be semver');
    }
    if (_utf8Len(description) > 2000) throw ManifestError('description exceeds 2000 characters');
    if (author.name.trim().isEmpty || _utf8Len(author.name) > 80) {
      throw ManifestError('author name must be 1..80 characters');
    }
    if (author.identity.trim().isEmpty || _utf8Len(author.identity) > 160) {
      throw ManifestError('author identity must be 1..160 characters');
    }
    if (author.publicKey.isEmpty) throw ManifestError('author public key is required');
    // Go additionally requires the key to be a real minisign key
    // (ParsePublicKey: 42-byte "Ed" envelope); a garbage string passed
    // here and only failed later, at signature verification, with the
    // two parsers disagreeing about the manifest itself until then.
    try {
      parsePublicKey(author.publicKey);
    } on SignatureError catch (e) {
      throw ManifestError('author public key is not a minisign key: ${e.message}');
    }
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
      if (!_networkHostPattern.hasMatch(h) || _isIpLike(h)) {
        throw ManifestError('bad network host "$h"');
      }
      if (!seenHosts.add(h)) {
        throw ManifestError('duplicate network host "$h"');
      }
    }
    backgroundTask?.validate(this);
    _checkAssetRef('theme', themeEntry, 'theme', 'theme.apply');
    _checkAssetRef('network_hook', networkHookEntry, 'network-hook', 'net.hooks');
    _checkAssetRef('routing', routingEntry, 'routing', 'routing.rules');
    final panelIds = <String>{};
    for (final p in panels) {
      if (!_panelIdPattern.hasMatch(p.id)) throw ManifestError('bad panel id "${p.id}"');
      if (!panelIds.add(p.id)) throw ManifestError('duplicate panel id "${p.id}"');
      if (p.title.trim().isEmpty || _utf8Len(p.title) > 60) {
        throw ManifestError('panel "${p.id}" needs a title of 1..60 characters');
      }
      if (!isSafeEntry(p.entry)) {
        throw ManifestError('panel "${p.id}" has an unsafe entry "${p.entry}"');
      }
    }
    // Panels embed the extension's UI inside the app: they require the
    // "ui-panel" capability and the "ui.panel" permission, mirroring
    // core/ext's manifest validation, so the install prompt always
    // consents to UI embedding when a panel exists.
    if (panels.isNotEmpty) {
      if (!capabilities.contains('ui-panel')) {
        throw ManifestError('panels require the "ui-panel" capability');
      }
      if (!permissions.contains('ui.panel')) {
        throw ManifestError('panels require the "ui.panel" permission');
      }
    }
    if (settingsSchema != null) validateSettingsSchema(settingsSchema!);
  }

  /// Cross-checks one capability contract pointer (theme / network_hook /
  /// routing): the matching capability and permission must be declared and
  /// the entry must be a safe relative .json path. Mirrors core/ext's
  /// validateAssetRef.
  void _checkAssetRef(String field, String? entry, String capability, String permission) {
    if (entry == null) return;
    if (!capabilities.contains(capability)) {
      throw ManifestError('$field requires the "$capability" capability');
    }
    if (!permissions.contains(permission)) {
      throw ManifestError('$field requires the "$permission" permission');
    }
    if (!_assetEntryPattern.hasMatch(entry) ||
        entry.contains('..') ||
        entry.startsWith('/')) {
      throw ManifestError(
          '$field entry "$entry" must be a relative .json path without traversal');
    }
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
        if (themeEntry != null) 'theme': {'entry': themeEntry},
        if (networkHookEntry != null) 'network_hook': {'entry': networkHookEntry},
        if (routingEntry != null) 'routing': {'entry': routingEntry},
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

/// Capability-contract asset names: relative .json path, no traversal
/// (mirrors core/ext's isSafeAssetPath).
final _assetEntryPattern =
    RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_./-]{0,255}\.json$');

/// Parses one capability contract pointer ({entry: ...}). Null when the
/// field is absent. Rejects non-objects and unknown inner fields, mirroring
/// core/ext's DisallowUnknownFields.
String? _parseAssetRef(dynamic raw, String field) {
  if (raw == null) return null;
  if (raw is! Map<String, dynamic>) {
    throw ManifestError('$field must be an object');
  }
  const known = {'entry'};
  for (final key in raw.keys) {
    if (!known.contains(key)) throw ManifestError('unknown $field field "$key"');
  }
  return (raw['entry'] as String? ?? '').trim();
}

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
    // Mirrors core/ext (encoding/json rejects non-strings): entries must be
    // strings. Normalized to lowercase like core/ext — the allowlist is DNS
    // names only, and matching is case-insensitive.
    if (e is! String) throw ManifestError('network_hosts entries must be strings');
    final h = e.trim().toLowerCase();
    if (h.isEmpty || _utf8Len(h) > 253) throw ManifestError('bad network host "$h"');
    out.add(h);
  }
  return out;
}

/// True for IP-literal-like hosts, which the allowlist rejects: it holds DNS
/// names only. Mirrors core/ext's isIPLike — plain IPv4 literals plus the
/// notations some system resolvers still dial as IPs: hex (`0x7f000001`,
/// `0x7f.1`), octal (`017700000001`) and all-digit (`2130706433`) forms.
/// (IPv6 cannot pass the host pattern since ':' is not allowed there.)
/// The input must already be lowercased, as in core/ext's
/// normalizeHostPattern.
bool _isIpLike(String h) {
  if (_isIpv4Literal(h)) return true;
  for (final label in h.split('.')) {
    if (label.length > 2 && label.startsWith('0x')) {
      var allHex = true;
      for (var i = 2; i < label.length; i++) {
        final c = label.codeUnitAt(i);
        if (!((c >= 0x30 && c <= 0x39) || (c >= 0x61 && c <= 0x66))) {
          allHex = false;
          break;
        }
      }
      if (allHex) return true;
    }
  }
  final noDots = h.replaceAll('.', '');
  if (noDots.isEmpty) return false;
  for (var i = 0; i < noDots.length; i++) {
    final c = noDots.codeUnitAt(i);
    if (c < 0x30 || c > 0x39) return false;
  }
  return true;
}

/// Plain dotted-decimal IPv4 literal (`1.2.3.4`).
bool _isIpv4Literal(String h) {
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
    if (e.key.isEmpty || _utf8Len(e.key) > 64) {
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
