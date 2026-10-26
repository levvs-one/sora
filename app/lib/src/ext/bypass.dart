import 'dart:convert';
import 'dart:io';

import '../generated/sora/core/v1/core_control.pb.dart';

const extensionBypassPrefix = 'sora:extension-bypass:';

/// A signed descriptor selects profiles for an already installed host backend.
/// It cannot supply native paths, flags, scripts, or engine config fragments.
class ExtensionBypass {
  ExtensionBypass._(this.backend, this.profiles);
  final String backend;
  final Map<String, BypassStrategy> profiles;

  static ExtensionBypass parse(String source, {String? operatingSystem}) {
    final doc = jsonDecode(source);
    if (doc is! Map<String, dynamic>) throw const FormatException('invalid bypass descriptor');
    if (doc['hook_version'] == 2) {
      if (doc.keys.any((key) => !const {'hook_version', 'backend', 'profiles'}.contains(key)) ||
          !const {'tpws', 'byedpi'}.contains(doc['backend'])) {
        throw const FormatException('unsupported bypass profile descriptor');
      }
      return _variant({'backend': doc['backend'], 'profiles': doc['profiles']});
    }
    if (doc['hook_version'] != 3 || doc.keys.any((key) => !const {'hook_version', 'platforms'}.contains(key))) {
      throw const FormatException('unsupported bypass profile descriptor');
    }
    final platforms = doc['platforms'];
    if (platforms is! Map<String, dynamic> || platforms.isEmpty || platforms.length > 2) {
      throw const FormatException('bypass descriptor requires 1..2 supported platforms');
    }
    final variants = <String, ExtensionBypass>{};
    for (final entry in platforms.entries) {
      if (!const {'linux', 'windows'}.contains(entry.key) || entry.value is! Map<String, dynamic>) {
        throw const FormatException('unsupported bypass platform');
      }
      final variant = _variant(entry.value as Map<String, dynamic>);
      if (!variant.supports(entry.key)) throw const FormatException('backend does not match its platform');
      variants[entry.key] = variant;
    }
    return variants[operatingSystem ?? Platform.operatingSystem] ??
        (throw const FormatException('bypass backend is unavailable on this platform'));
  }

  static ExtensionBypass _variant(Map<String, dynamic> doc) {
    if (doc.keys.any((key) => !const {'backend', 'profiles', 'scope'}.contains(key)) ||
        !const {'tpws', 'byedpi', 'winws'}.contains(doc['backend'])) {
      throw const FormatException('unsupported bypass backend');
    }
    if (doc['backend'] == 'winws' ? doc['scope'] != 'system-tcp-80-443' : doc.containsKey('scope')) {
      throw const FormatException('invalid bypass traffic scope');
    }
    final raw = doc['profiles'];
    if (raw is! Map<String, dynamic> || raw.isEmpty || raw.length > 16) {
      throw const FormatException('bypass profiles must contain 1..16 named strategies');
    }
    final profiles = <String, BypassStrategy>{};
    for (final entry in raw.entries) {
      if (entry.key.trim().isEmpty || utf8.encode(entry.key).length > 64 || entry.value is! Map<String, dynamic>) {
        throw const FormatException('invalid bypass profile');
      }
      final strategy = BypassStrategy()..mergeFromProto3Json(entry.value);
      if (doc['backend'] == 'winws' && (strategy.oob || strategy.tlsRecord.isNotEmpty)) {
        throw const FormatException('Winws does not support OOB or TLS-record splitting');
      }
      strategy.freeze();
      profiles[entry.key] = strategy;
    }
    return ExtensionBypass._(doc['backend'] as String, Map.unmodifiable(profiles));
  }

  bool supports(String operatingSystem) =>
      (operatingSystem == 'linux' && backend == 'tpws') ||
      (operatingSystem == 'windows' && const {'byedpi', 'winws'}.contains(backend));

  BypassStrategy select(Map<String, dynamic> settings) {
    final profile = profiles[settings['profile']];
    if (profile == null) throw const FormatException('unknown bypass profile selection');
    return BypassStrategy.fromBuffer(profile.writeToBuffer());
  }
}

class ExtensionBypassProfile {
  ExtensionBypassProfile({
    required this.extensionId,
    required this.name,
    required this.backend,
    required BypassStrategy strategy,
  }) : _strategy = BypassStrategy.fromBuffer(strategy.writeToBuffer())..freeze();
  final String extensionId;
  final String name;
  final String backend;
  bool get systemWide => backend == 'winws';
  final BypassStrategy _strategy;
  String get choiceId => '$extensionBypassPrefix$extensionId';
  BypassStrategy get strategy => BypassStrategy.fromBuffer(_strategy.writeToBuffer());
}
