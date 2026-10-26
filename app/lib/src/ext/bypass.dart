import 'dart:convert';

import '../generated/sora/core/v1/core_control.pb.dart';

const extensionBypassPrefix = 'sora:extension-bypass:';

/// A signed descriptor selects profiles for an already installed host backend.
/// It cannot supply native paths, flags, scripts, or engine config fragments.
class ExtensionBypass {
  ExtensionBypass._(this.backend, this.profiles);
  final String backend;
  final Map<String, BypassStrategy> profiles;

  static ExtensionBypass parse(String source) {
    final doc = jsonDecode(source);
    if (doc is! Map<String, dynamic> ||
        doc.keys.any((key) => !const {'hook_version', 'backend', 'profiles'}.contains(key)) ||
        doc['hook_version'] != 2 ||
        !const {'tpws', 'byedpi'}.contains(doc['backend'])) {
      throw const FormatException('unsupported bypass profile descriptor');
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
      strategy.freeze();
      profiles[entry.key] = strategy;
    }
    return ExtensionBypass._(doc['backend'] as String, Map.unmodifiable(profiles));
  }

  bool supports(String operatingSystem) =>
      (operatingSystem == 'linux' && backend == 'tpws') || (operatingSystem == 'windows' && backend == 'byedpi');

  BypassStrategy select(Map<String, dynamic> settings) {
    final profile = profiles[settings['profile']];
    if (profile == null) throw const FormatException('unknown bypass profile selection');
    return BypassStrategy.fromBuffer(profile.writeToBuffer());
  }
}

class ExtensionBypassProfile {
  ExtensionBypassProfile({required this.extensionId, required this.name, required BypassStrategy strategy})
    : _strategy = BypassStrategy.fromBuffer(strategy.writeToBuffer())..freeze();
  final String extensionId;
  final String name;
  final BypassStrategy _strategy;
  String get choiceId => '$extensionBypassPrefix$extensionId';
  BypassStrategy get strategy => BypassStrategy.fromBuffer(_strategy.writeToBuffer());
}
