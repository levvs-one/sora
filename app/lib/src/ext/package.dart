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

/// Hard cap for a .soraext download: anything larger is rejected before the
/// archive is even opened. Shared with the install UI so a rogue URL cannot
/// exhaust memory ahead of the structural checks in [ExtPackage.open].
const int maxPackageBytes = 64 * 1024 * 1024;
const int _maxUncompressedBytes = 256 * 1024 * 1024;
const int _maxPackageFiles = 4096;
const int _maxSingleFile = 32 * 1024 * 1024;

/// Maximum believable total compression ratio (declared uncompressed bytes
/// over compressed bytes). Ordinary text and code compress ~2-6x; a classic
/// zip bomb compresses thousands of times. 100 leaves ample headroom for
/// legitimate bundles while killing bombs before a single byte is inflated.
const int _maxCompressionRatio = 100;

const String manifestName = 'sora-extension.json';
const String checksumsName = 'checksums.txt';
const String signatureName = 'signature.minisig';

/// An opened, not yet trusted .soraext archive.
class ExtPackage {
  ExtPackage._(this.files, this.manifest);
  final Map<String, Uint8List> files;
  final ExtManifest manifest;

  /// Opens and structurally checks a .soraext. Call [verify] next.
  ///
  /// Zip-bomb defense, in three phases:
  /// 1. the central directory is read on its own — no inflation yet;
  /// 2. header-declared limits are enforced (file count, per-file declared
  ///    size, total declared size, overall compression ratio, no encrypted
  ///    entries, no exotic compression methods) so an obvious bomb fails
  ///    before it costs any CPU or RAM;
  /// 3. each file is inflated through a bounded sink: headers may lie, so
  ///    the per-file and total caps are re-enforced on the bytes that
  ///    actually come out of the decompressor.
  ///
  /// Any violation throws [PackageError] with no partial result: the
  /// package is either opened whole or not at all.
  static ExtPackage open(Uint8List data) {
    if (data.length > maxPackageBytes) {
      throw PackageError('package exceeds ${maxPackageBytes} bytes');
    }
    // Phase 1: central directory only. ZipDirectory.read parses the
    // directory at the end of the file and never inflates file content.
    final directory = ZipDirectory();
    try {
      directory.read(InputMemoryStream(data));
    } catch (e) {
      throw PackageError('not a zip archive: $e');
    }
    final headers = directory.fileHeaders;
    if (headers.length > _maxPackageFiles) {
      throw PackageError('too many files (${headers.length})');
    }
    // Phase 2: fail fast on declared sizes, before any inflation.
    var declaredTotal = 0;
    var compressedTotal = 0;
    for (final h in headers) {
      final name = h.filename;
      if (name.endsWith('/')) continue; // directory entry
      if (!_isSafePath(name)) throw PackageError('unsafe path "$name"');
      if (h.generalPurposeBitFlag & 0x1 != 0) {
        throw PackageError('file "$name" is encrypted');
      }
      // 0 = stored, 8 = deflated. Anything else the decoder may not even
      // understand; reject explicitly instead of hoping.
      if (h.compressionMethod != 0 && h.compressionMethod != 8) {
        throw PackageError('file "$name" uses an unsupported compression method');
      }
      final declared = h.uncompressedSize;
      if (declared < 0 || declared > _maxSingleFile) {
        throw PackageError('file "$name" declares $declared bytes (limit $_maxSingleFile)');
      }
      final compressed = h.compressedSize;
      if (compressed < 0) throw PackageError('file "$name" has a bad compressed size');
      declaredTotal += declared;
      if (declaredTotal > _maxUncompressedBytes) {
        throw PackageError('content declares more than $_maxUncompressedBytes bytes');
      }
      compressedTotal += compressed;
    }
    if (compressedTotal > 0 && declaredTotal > compressedTotal * _maxCompressionRatio) {
      throw PackageError('suspicious compression ratio '
          '(about ${declaredTotal ~/ compressedTotal}x, limit ${_maxCompressionRatio}x)');
    }
    // Phase 3: inflate through a bounded sink. ArchiveFile content is
    // inflated lazily, so decodeStream on its own is cheap; the caps below
    // are what actually bound memory, no matter what the headers claimed.
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(InputMemoryStream(data));
    } catch (e) {
      throw PackageError('not a zip archive: $e');
    }
    final files = <String, Uint8List>{};
    var total = 0;
    for (final f in archive.files) {
      if (!f.isFile) continue;
      final name = f.name;
      if (!_isSafePath(name)) throw PackageError('unsafe path "$name"');
      if (files.containsKey(name)) throw PackageError('duplicate path "$name"');
      final sink = _CappedOutput(_maxSingleFile, name);
      try {
        f.decompress(sink);
      } on PackageError {
        rethrow;
      } catch (e) {
        throw PackageError('cannot decompress "$name": $e');
      }
      final content = sink.getBytes();
      total += content.length;
      if (total > _maxUncompressedBytes) {
        throw PackageError('content exceeds $_maxUncompressedBytes bytes');
      }
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
  ///
  /// [authorKeyLine], when given, is the key the signature is checked
  /// against — the catalog-pinned key for catalog installs. Without it the
  /// manifest's self-attested key is used (sideload/URL trust on first
  /// use). A catalog install must always pass the pin: verifying against
  /// the manifest's own key would let a package smuggle in its own trust
  /// anchor.
  Future<void> verify({String? authorKeyLine}) async {
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
      await verifyPackageSignature(
          authorKeyLine ?? manifest.author.publicKey, sigText, checksumsRaw);
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

/// An [OutputMemoryStream] that throws [PackageError] instead of growing
/// past [limit] bytes. Every write path the inflater can use is capped —
/// including [writeBackReference], which is how deflate emits LZ77 matches
/// (the classic zip-bomb expansion vector: a tiny back-reference can
/// otherwise expand into gigabytes without a single [writeBytes] call).
class _CappedOutput extends OutputMemoryStream {
  _CappedOutput(this._limit, this._name);

  final int _limit;
  final String _name;
  var _written = 0;

  PackageError _tooBig() => PackageError('file "$_name" exceeds $_limit bytes');

  @override
  void writeByte(int value) {
    if (_written + 1 > _limit) throw _tooBig();
    _written += 1;
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    final n = length ?? bytes.length;
    if (_written + n > _limit) throw _tooBig();
    _written += n;
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeBackReference(int distance, int count) {
    if (_written + count > _limit) throw _tooBig();
    _written += count;
    super.writeBackReference(distance, count);
  }

  @override
  void writeStream(InputStream stream) {
    final n = stream.length;
    if (_written + n > _limit) throw _tooBig();
    _written += n;
    super.writeStream(stream);
  }
}
