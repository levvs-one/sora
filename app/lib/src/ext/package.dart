/// .soraext package opening and verification (mirrors core/ext/package.go).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'manifest.dart';
import 'verifier.dart';

class PackageError implements Exception {
  PackageError(this.message);
  final String message;
  @override
  String toString() => 'PackageError: $message';
}

const int _maxPackageBytes = 64 * 1024 * 1024;
const int _maxUncompressedBytes = 256 * 1024 * 1024;
const int _maxPackageFiles = 4096;
const int _maxSingleFile = 32 * 1024 * 1024;

const String manifestName = 'sora-extension.json';
const String checksumsName = 'checksums.txt';
const String signatureName = 'signature.minisig';

/// An opened, not yet trusted .soraext archive.
class ExtPackage {
  ExtPackage._(this.files, this.manifest);
  final Map<String, Uint8List> files;
  final ExtManifest manifest;

  /// Opens and structurally checks a .soraext. Call [verify] next.
  static ExtPackage open(Uint8List data) {
    if (data.length > _maxPackageBytes) {
      throw PackageError('package exceeds ${_maxPackageBytes} bytes');
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(data);
    } catch (e) {
      throw PackageError('not a zip archive: $e');
    }
    if (archive.files.length > _maxPackageFiles) {
      throw PackageError('too many files (${archive.files.length})');
    }
    final files = <String, Uint8List>{};
    var total = 0;
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final name = f.name;
      if (!_isSafePath(name)) throw PackageError('unsafe path "$name"');
      final content = Uint8List.fromList(f.content as List<int>);
      if (content.length > _maxSingleFile) throw PackageError('file "$name" is too large');
      total += content.length;
      if (total > _maxUncompressedBytes) {
        throw PackageError('content exceeds ${_maxUncompressedBytes} bytes');
      }
      if (files.containsKey(name)) throw PackageError('duplicate path "$name"');
      files[name] = content;
    }
    for (final need in [manifestName, checksumsName, signatureName]) {
      if (!files.containsKey(need)) throw PackageError('missing "$need"');
    }
    final ExtManifest manifest;
    try {
      manifest = ExtManifest.parse(utf8.decode(files[manifestName]!));
    } on ManifestError catch (e) {
      throw PackageError(e.message);
    }
    return ExtPackage._(files, manifest);
  }

  /// Verifies integrity and authenticity:
  /// 1. every file's sha256 matches checksums.txt,
  /// 2. checksums.txt covers every content file exactly (except itself and
  ///    the signature, which cannot checksum themselves),
  /// 3. signature.minisig is a valid author signature over checksums.txt.
  Future<void> verify() async {
    final checksumsRaw = files[checksumsName]!;
    final sigText = utf8.decode(files[signatureName]!);
    final listed = _parseChecksums(utf8.decode(checksumsRaw));
    for (final e in files.entries) {
      if (e.key == signatureName || e.key == checksumsName) continue;
      final want = listed[e.key];
      if (want == null) {
        throw PackageError('file "${e.key}" is not covered by checksums.txt');
      }
      final sum = crypto.sha256.convert(e.value).toString();
      if (sum != want) {
        throw PackageError('file "${e.key}" does not match checksums.txt');
      }
    }
    for (final name in listed.keys) {
      if (name == signatureName || name == checksumsName) continue;
      if (!files.containsKey(name)) {
        throw PackageError('checksums.txt lists "$name" which is missing');
      }
    }
    try {
      await verifyPackageSignature(manifest.author.publicKey, sigText, checksumsRaw);
    } on SignatureError catch (e) {
      throw PackageError(e.message);
    }
  }

  static bool _isSafePath(String name) {
    if (name.isEmpty || name.length > 512) return false;
    if (name.startsWith('/') || name.startsWith('\\')) return false;
    final parts = name.split('/');
    for (final p in parts) {
      if (p.isEmpty || p == '.' || p == '..') return false;
    }
    return true;
  }

  static Map<String, String> _parseChecksums(String text) {
    final out = <String, String>{};
    final lines = text.replaceAll('\r\n', '\n').trim().split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final fields = line.split(RegExp(r'\s+'));
      if (fields.length != 2 || !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(fields[0])) {
        throw PackageError('checksums.txt line ${i + 1} is malformed');
      }
      if (!_isSafePath(fields[1])) {
        throw PackageError('checksums.txt line ${i + 1} has an unsafe path');
      }
      if (out.containsKey(fields[1])) {
        throw PackageError('checksums.txt lists "${fields[1]}" twice');
      }
      out[fields[1]] = fields[0].toLowerCase();
    }
    if (out.isEmpty) throw PackageError('checksums.txt is empty');
    return out;
  }
}
