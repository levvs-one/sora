import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/ext/verifier.dart';
import 'package:sora/src/release_metadata.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/updates.dart';

final fixtures = jsonDecode(File('test/fixtures/releases/metadata.json').readAsStringSync()) as Map<String, dynamic>;
final fixtureKey = fixtures['public_key'] as String;
final records = <String, dynamic>{
  ...fixtures['releases'] as Map<String, dynamic>,
  ...fixtures['cases'] as Map<String, dynamic>,
}.map((name, value) => MapEntry(name, (value as Map<String, dynamic>).cast<String, String>()));
const executable = '/usr/lib/sora/app/sora';

Map<String, List<int>> releaseData(String version, Map<String, String> record) {
  final original = jsonDecode(records[version]!['metadata']!) as Map<String, dynamic>;
  return {
    for (final entry in original['artifacts'] as List)
      (entry as Map<String, dynamic>)['name'] as String: utf8.encode('abc'),
    'SHA256SUMS': utf8.encode(record['manifest']!),
    'SHA256SUMS.minisig': utf8.encode(record['signature']!),
    ReleaseMetadata.filename: utf8.encode(record['metadata']!),
  };
}

Map<String, ReleaseAsset> releaseAssets(String version, Map<String, List<int>> data) => {
  for (final entry in data.entries)
    entry.key: ReleaseAsset(
      entry.key,
      Uri.parse('$releaseRepository/releases/download/v$version/${entry.key}'),
      entry.value.length,
    ),
};

Future<ProcessResult> ownershipQuery(
  String command,
  List<String> arguments, {
  PackageFormat format = PackageFormat.deb,
  String? ownerArchitecture,
}) async {
  if (command == 'dpkg-query' && format == PackageFormat.deb) {
    final owner = ownerArchitecture == null ? 'sora' : 'sora:$ownerArchitecture';
    final answer = arguments.first == '-S' ? '$owner: $executable\n' : 'sora\tinstalled\nsora-core\tinstalled\n';
    return ProcessResult(0, 0, answer, '');
  }
  if (command == 'rpm' && format == PackageFormat.rpm) {
    return ProcessResult(0, 0, arguments.first == '-qf' ? 'sora\n' : 'sora\nsora-core\n', '');
  }
  if (command == 'dnf' && format == PackageFormat.rpm) return ProcessResult(0, 0, 'fixture dnf', '');
  if (command == 'pacman' && format == PackageFormat.arch) {
    return ProcessResult(0, 0, arguments.first == '-Qoq' ? 'sora\n' : 'sora\nsora-core\n', '');
  }
  return ProcessResult(0, 1, '', '');
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('Python producer bytes and checksums round-trip through the strict Dart schema', () {
    final record = records['1.0.5']!;
    final bytes = utf8.encode(record['metadata']!);
    final metadata = ReleaseMetadata.parse(bytes, '1.0.5');
    expect(metadata.artifacts.length, 15);
    expect(metadata.checksumManifest(sha256.convert(bytes).toString()), record['manifest']);
    expect(ReleaseMetadata.referenced(record['manifest']!), isTrue);
    expect(ReleaseMetadata.referenced('${'a' * 64}  install.sh\n'), isFalse);
    for (final entry in metadata.artifacts.values) {
      expect(entry.size, 3);
    }
  });

  for (final name in records.keys.where(
    (name) => !['1.0.4', '1.0.5', 'previous-matrix', 'wrong-size', 'duplicate-checksum'].contains(name),
  )) {
    test('strict metadata parser rejects signed malformed $name', () {
      expect(() => ReleaseMetadata.parse(utf8.encode(records[name]!['metadata']!), '1.0.5'), throwsFormatException);
    });
  }

  for (final (windows, abi, format) in [
    (true, Abi.windowsX64, PackageFormat.deb),
    (false, Abi.linuxX64, PackageFormat.deb),
    (false, Abi.linuxArm64, PackageFormat.deb),
    (false, Abi.linuxArm64, PackageFormat.rpm),
    (false, Abi.linuxArm64, PackageFormat.arch),
  ]) {
    final architecture = ReleaseArchitecture.forAbi(abi)!;
    for (final scenario in [
      'success',
      'api-small',
      'api-large',
      'missing',
      'other-architecture-only',
      if (!windows && format == PackageFormat.deb) 'wrong-installed-architecture',
      'tamper',
      'chunked-overflow',
      'oversize-stream',
      'oversize-api',
      ...records.keys.where((name) => !['1.0.4', '1.0.5'].contains(name)),
    ]) {
      test(
        '${windows ? 'Windows' : 'Linux'} ${architecture.name} ${format.name} authenticated metadata: $scenario',
        () async {
          final record = records[scenario] ?? records['1.0.5']!;
          // Prove malformed catalogs really carry valid signatures, independently
          // of the updater's error classification and mocked OS handoff.
          await verifyPayload(
            fixtureKey,
            record['signature']!,
            'release:v1.0.5:SHA256SUMS',
            Uint8List.fromList(utf8.encode(record['manifest']!)),
          );
          final settings = await Settings.load();
          final data = releaseData('1.0.5', record);
          final previous = releaseData('1.0.4', records['1.0.4']!);
          final names = windows
              ? ['Sora-Setup-1.0.5-x64.exe']
              : LinuxInstallation(
                  format,
                  {PackageFormat.deb: 'apt-get', PackageFormat.rpm: 'dnf', PackageFormat.arch: 'pacman'}[format]!,
                  architecture: architecture,
                ).filenames('1.0.5');
          final assets = releaseAssets('1.0.5', data);
          if (scenario == 'missing') assets.remove(ReleaseMetadata.filename);
          if (scenario == 'other-architecture-only') {
            for (final name in names) {
              assets.remove(name);
            }
          }

          if (scenario == 'oversize-api') {
            final asset = assets[ReleaseMetadata.filename]!;
            assets[asset.name] = ReleaseAsset(asset.name, asset.url, ReleaseMetadata.maxBytes + 1);
          }
          if (scenario == 'api-small' || scenario == 'api-large') {
            for (final name in names) {
              assets[name] = ReleaseAsset(
                name,
                assets[name]!.url,
                scenario == 'api-small' ? 1 : ReleaseMetadata.maxArtifactBytes + 1,
              );
            }
          }
          if (scenario == 'tamper') {
            data[ReleaseMetadata.filename] = [...data[ReleaseMetadata.filename]!, 32];
            final asset = assets[ReleaseMetadata.filename]!;
            assets[asset.name] = ReleaseAsset(asset.name, asset.url, data[asset.name]!.length);
          }
          if (scenario == 'oversize-stream') {
            data[ReleaseMetadata.filename] = List<int>.filled(ReleaseMetadata.maxBytes + 1, 65);
          }
          final root = await Directory.systemTemp.createTemp('sora-metadata-test-');
          addTearDown(() async {
            if (await root.exists()) await root.delete(recursive: true);
          });
          final requests = <String>[];
          final retained = <Directory>[];
          addTearDown(() async {
            for (final directory in retained) {
              if (await directory.exists()) await directory.delete(recursive: true);
            }
          });
          var handedOff = false;
          var didQuit = false;
          var restarted = false;
          final updater = AppUpdater(
            settings,
            version: '1.0.4',
            signingPublicKey: fixtureKey,
            windows: windows,
            abi: abi,
            executable: executable,
            connection: () => UpdateConnection.idle,
            available: (_) async => fail('install test must not publish an update notification'),
            canElevate: () async => true,
            rollbackDir: (version) => Directory('${root.path}/rollback/$version'),
            client: () => MockClient.streaming((request, _) async {
              if (request.url.host == 'api.github.com') {
                final body = utf8.encode(
                  jsonEncode({
                    'tag_name': 'v1.0.4',
                    'draft': false,
                    'prerelease': false,
                    'assets': [
                      for (final asset in releaseAssets('1.0.4', previous).values)
                        {'name': asset.name, 'browser_download_url': asset.url.toString(), 'size': asset.size},
                    ],
                  }),
                );
                return http.StreamedResponse(Stream.value(body), 200);
              }
              final name = request.url.pathSegments.last;
              requests.add(name);
              final old = request.url.path.contains('/v1.0.4/');
              var bytes = (old ? previous : data)[name]!;
              if (!old && scenario == 'chunked-overflow' && names.contains(name)) bytes = [...bytes, 33];
              return http.StreamedResponse(Stream.fromIterable([bytes.take(2).toList(), bytes.skip(2).toList()]), 200);
            }),
            run: (command, arguments) async {
              if (command != '/usr/bin/pkexec') {
                return ownershipQuery(
                  command,
                  arguments,
                  format: format,
                  ownerArchitecture: scenario == 'wrong-installed-architecture'
                      ? (architecture == ReleaseArchitecture.arm64 ? 'amd64' : 'arm64')
                      : architecture.name,
                );
              }
              handedOff = true;
              final directory = Directory(arguments[3]);
              expect(await File('${directory.path}/${ReleaseMetadata.filename}').readAsString(), record['metadata']);
              for (final name in names) {
                await verifyUpdateFile(File('${directory.path}/$name'), record['manifest']!, name, size: 3);
              }
              return ProcessResult(0, 0, '', '');
            },
          )..latest = SoraRelease('1.0.5', '', assets);
          addTearDown(updater.dispose);
          await updater.install(
            confirmDrop: () async => true,
            launchWindows: (file) async {
              handedOff = true;
              retained.add(file.parent);
              expect(await File('${file.parent.path}/${ReleaseMetadata.filename}').readAsString(), record['metadata']);
              await verifyUpdateFile(file, record['manifest']!, names.single, size: 3);
            },
            restartLinux: () async => restarted = true,
            quit: () async => didQuit = true,
          );
          final successful =
              ['success', 'previous-matrix', 'api-small', 'api-large'].contains(scenario) &&
              !(architecture == ReleaseArchitecture.arm64 && scenario == 'previous-matrix');
          expect(handedOff, successful);
          expect(didQuit, successful);
          if (successful) {
            expect(requests.where(names.contains), orderedEquals(names));
            expect(updater.error, isNull);
            if (!windows) {
              expect(restarted, isTrue);
              expect(
                await File('${root.path}/rollback/1.0.4/${ReleaseMetadata.filename}').readAsString(),
                records['1.0.4']!['metadata'],
              );
            }
          } else {
            expect(updater.error, switch (scenario) {
              'tamper' || 'duplicate-checksum' => UpdateError.checksum,
              'wrong-size' || 'chunked-overflow' || 'oversize-stream' => UpdateError.network,
              'wrong-installed-architecture' => UpdateError.unsupported,
              _ => UpdateError.release,
            });
            expect(updater.manualCommand, isNull);
            expect(settings.pendingUpdate, isEmpty);
            if (!['wrong-size', 'chunked-overflow'].contains(scenario)) {
              expect(requests.where(names.contains), isEmpty);
            }
          }
        },
      );
    }
  }

  for (final (abi, format) in [
    (Abi.linuxX64, PackageFormat.deb),
    (Abi.linuxArm64, PackageFormat.deb),
    (Abi.linuxArm64, PackageFormat.rpm),
    (Abi.linuxArm64, PackageFormat.arch),
  ]) {
    final architecture = ReleaseArchitecture.forAbi(abi)!;
    for (final attack in ['valid', 'missing', 'tamper', 'oversize', 'package-length']) {
      test('offline rollback ${architecture.name} ${format.name} reauthenticates metadata: $attack', () async {
        final root = await Directory.systemTemp.createTemp('sora-metadata-rollback-');
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        final cache = await Directory('${root.path}/1.0.4').create();
        final record = records['1.0.4']!;
        final data = releaseData('1.0.4', record);
        for (final name in [
          ...LinuxInstallation(
            format,
            {PackageFormat.deb: 'apt-get', PackageFormat.rpm: 'dnf', PackageFormat.arch: 'pacman'}[format]!,
            architecture: architecture,
          ).filenames('1.0.4'),
          'SHA256SUMS',
          'SHA256SUMS.minisig',
          ReleaseMetadata.filename,
        ]) {
          await File('${cache.path}/$name').writeAsBytes(data[name]!);
        }
        final metadata = File('${cache.path}/${ReleaseMetadata.filename}');
        if (attack == 'missing') await metadata.delete();
        if (attack == 'tamper') await metadata.writeAsString('${record['metadata']} ');
        if (attack == 'oversize') await metadata.writeAsBytes(List<int>.filled(ReleaseMetadata.maxBytes + 1, 65));
        if (attack == 'package-length') {
          final package = LinuxInstallation(format, 'apt-get', architecture: architecture).filenames('1.0.4').first;
          await File('${cache.path}/$package').writeAsString('abcd');
        }
        final settings = await Settings.load();
        await settings.savePendingUpdate(
          PendingUpdate(from: '1.0.4', to: '1.0.5', atMs: DateTime.now().millisecondsSinceEpoch - 120000).encode(),
        );
        var handedOff = false;
        var restarted = false;
        final updater = AppUpdater(
          settings,
          version: '1.0.5',
          signingPublicKey: fixtureKey,
          windows: false,
          abi: abi,
          executable: executable,
          connection: () => UpdateConnection.idle,
          available: (_) async => fail('offline rollback cannot notify'),
          rollbackDir: (version) => Directory('${root.path}/$version'),
          canElevate: () async => true,
          client: () => MockClient((_) async => throw StateError('rollback must stay offline')),
          run: (command, arguments) async {
            if (command != '/usr/bin/pkexec') {
              return ownershipQuery(command, arguments, format: format, ownerArchitecture: architecture.name);
            }
            handedOff = true;
            expect(arguments, contains('--allow-downgrade'));
            return ProcessResult(0, 0, '', '');
          },
        );
        addTearDown(updater.dispose);
        await updater.checkPendingUpdate(
          coreHealthy: () => false,
          restart: () async => restarted = true,
          quit: () async => expect(handedOff, isTrue),
        );
        expect(handedOff, attack == 'valid');
        expect(restarted, attack == 'valid');
        expect(updater.error, attack == 'valid' ? isNull : UpdateError.rollback);
        expect(settings.pendingUpdate, isEmpty);
      });
    }
  }

  for (final abi in [Abi.linuxIA32, Abi.linuxRiscv64, Abi.windowsArm64]) {
    test('unsupported ABI $abi installer path never fetches or hands off', () async {
      final settings = await Settings.load();
      final updater = AppUpdater(
        settings,
        version: '1.0.4',
        windows: abi == Abi.windowsArm64,
        abi: abi,
        connection: () => UpdateConnection.idle,
        available: (_) async => fail('unsupported install cannot notify'),
        client: () => MockClient((_) async => throw StateError('unsupported ABI must not fetch')),
        run: (_, _) async => throw StateError('unsupported ABI must not query or elevate'),
      );
      addTearDown(updater.dispose);
      updater.latest = const SoraRelease('1.0.5', '', {});
      await updater.install(
        confirmDrop: () async => fail('unsupported install cannot confirm'),
        launchWindows: (_) async => fail('unsupported install cannot launch'),
        restartLinux: () async => fail('unsupported install cannot restart'),
        quit: () async => fail('unsupported install cannot quit'),
      );
      expect(updater.error, UpdateError.unsupported);
      expect(updater.installed, isFalse);
    });
  }
}
