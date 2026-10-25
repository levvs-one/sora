import 'dart:convert';

import 'package:flutter/foundation.dart' show listEquals;

class ReleaseArtifactMetadata {
  const ReleaseArtifactMetadata(this.name, this.os, this.arch, this.size, this.sha256);

  final String name;
  final String os;
  final String arch;
  final int size;
  final String sha256;
}

/// Schema 1 from packaging/install/release_manifest.py, after authentication.
class ReleaseMetadata {
  const ReleaseMetadata._(this.artifacts);

  static const filename = 'release.json';
  static const maxBytes = 1024 * 1024;
  static const maxArtifactBytes = 2 * 1024 * 1024 * 1024;
  final Map<String, ReleaseArtifactMetadata> artifacts;

  /// Presence is decided by the signed checksum payload, never the API list.
  static bool referenced(String manifest) =>
      const LineSplitter().convert(manifest).any((line) => line.endsWith(' $filename') || line.endsWith('*$filename'));

  static ReleaseMetadata parse(List<int> bytes, String version) {
    if (bytes.isEmpty ||
        bytes.length > maxBytes ||
        version.length > 64 ||
        !RegExp(r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$').hasMatch(version)) {
      throw const FormatException('Invalid release metadata size or version');
    }
    final document = jsonDecode(utf8.decode(bytes));
    if (document is! Map<String, dynamic> ||
        document['schema'] is! int ||
        document['schema'] != 1 ||
        document['version'] != version) {
      throw const FormatException('Unsupported release metadata');
    }
    final values = document['artifacts'];
    if (values is! List || values.isEmpty || values.length > 128) {
      throw const FormatException('Invalid release artifact count');
    }
    final artifacts = <String, ReleaseArtifactMetadata>{};
    final canonicalArtifacts = <Map<String, Object>>[];
    var previous = '';
    for (final value in values) {
      if (value is! Map<String, dynamic>) throw const FormatException('Invalid release artifact');
      final name = value['name'], os = value['os'], arch = value['arch'];
      final size = value['size'], digest = value['sha256'];
      if (name is! String ||
          os is! String ||
          arch is! String ||
          size is! int ||
          size < 1 ||
          size > maxArtifactBytes ||
          digest is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(digest) ||
          name.compareTo(previous) <= 0 ||
          _target(name, version) != (os, arch)) {
        throw const FormatException('Invalid release artifact metadata');
      }
      previous = name;
      artifacts[name] = ReleaseArtifactMetadata(name, os, arch, size, digest);
      canonicalArtifacts.add({'arch': arch, 'name': name, 'os': os, 'sha256': digest, 'size': size});
    }
    // Re-encoding rejects duplicate/unknown keys, alternative encodings and order.
    final canonical = utf8.encode(
      '${jsonEncode({'artifacts': canonicalArtifacts, 'schema': 1, 'version': version})}\n',
    );
    if (!listEquals(bytes, canonical)) throw const FormatException('Noncanonical release metadata');
    return ReleaseMetadata._(Map.unmodifiable(artifacts));
  }

  String checksumManifest(String metadataHash) {
    final hashes = {for (final entry in artifacts.values) entry.name: entry.sha256, filename: metadataHash};
    final names = hashes.keys.toList()..sort();
    return [for (final name in names) '${hashes[name]}  $name\n'].join();
  }

  static (String, String)? _target(String name, String version) {
    if (name == 'Sora-Setup-$version-x64.exe') return ('windows', 'amd64');
    if (name == 'install.ps1') return ('windows', 'any');
    if (name == 'install.sh') return ('linux', 'any');
    for (final (arch, machine) in [('amd64', 'x86_64'), ('arm64', 'aarch64')]) {
      for (final package in ['sora-core', 'sora']) {
        if (package == 'sora' && arch == 'arm64') continue;
        if (name == '${package}_${version}_$arch.deb' ||
            name == '$package-$version-1.$machine.rpm' ||
            name == '$package-$version-1-$machine.pkg.tar.zst') {
          return ('linux', arch);
        }
      }
    }
    return null;
  }
}
