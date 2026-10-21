import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/src/desktop/desktop.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/about.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/settings_screen.dart';
import 'package:sora/src/updates.dart';

import 'desktop_shell_test.dart' show section, size;

final recorded = File('test/fixtures/releases/latest.json').readAsStringSync();
final release = SoraRelease.parse(recorded);
const executable = '/usr/lib/sora/app/sora';

Future<ProcessResult> packageQuery(String manager, String exe, List<String> args) async {
  final answer = switch ((manager, exe, args.first)) {
    ('deb', 'dpkg-query', '-S') => 'sora: $executable\n',
    ('deb', 'dpkg-query', '-W') => 'sora\tinstalled\nsora-core\tinstalled\n',
    ('rpm', 'rpm', '-qf') || ('zypper', 'rpm', '-qf') => 'sora\n',
    ('rpm', 'rpm', '-q') || ('zypper', 'rpm', '-q') => 'sora\nsora-core\n',
    ('rpm', 'dnf', '--version') => '4.21.1\n',
    ('zypper', 'zypper', '--version') => 'zypper 1.14.78\n',
    ('arch', 'pacman', '-Qoq') => 'sora\n',
    ('arch', 'pacman', '-Qq') => 'sora\nsora-core\n',
    _ => null,
  };
  return ProcessResult(1, answer == null ? 1 : 0, answer ?? '', '');
}

class UpdateSora extends Sora {
  UpdateSora(super.settings, {String? response, this.current = '1.0.4'}) : response = response ?? recorded;
  final String response;
  final String current;
  int requests = 0;
  @override
  AppUpdater get updates => _updates;
  late final AppUpdater _updates = AppUpdater(
    settings,
    version: current,
    connection: () => phase == Phase.connected
        ? UpdateConnection.connected
        : phase == Phase.off
        ? UpdateConnection.idle
        : UpdateConnection.changing,
    client: () => MockClient((request) async {
      requests++;
      // S11a: the rollout policy feed gets a valid policy; the release API
      // gets the recorded release JSON.
      if (request.url.toString() == rolloutPolicyUrl) {
        return http.Response(
          '{"format":1,"rollout":{"version":"1.0.5","percent":100},"blocked_versions":[]}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      expect(request.url.path, '/repos/levvs-one/sora/releases/latest');
      return http.Response(response, 200, headers: {'content-type': 'application/json; charset=utf-8'});
    }),
    available: (release) => recordNotification(
      AppNotification(
        time: DateTime.now(),
        title: strings.updateAvailable(release.version),
        body: strings.updateOpenAbout,
        action: 'update',
      ),
    ),
  )..addListener(notifyListeners);
}

class RecordingDesktop extends Desktop {
  RecordingDesktop(Sora sora) : super(sora, GlobalKey<NavigatorState>());
  @override
  Future<void> launchUpdate(File installer) async => throw StateError('UI test must not launch an installer');
  @override
  Future<void> restartAfterUpdate() async => throw StateError('UI test must not restart');
  @override
  Future<void> quit({bool disconnect = true}) async => throw StateError('UI test must not quit');
}

Future<void> finishCheck(WidgetTester tester, AppUpdater updater) async {
  for (var attempt = 0; attempt < 30 && updater.checking; attempt++) {
    // Stream timeout cancellation completes on the real event loop.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  expect(updater.checking, isFalse);
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('release comparison uses numeric semver and ignores build metadata', () {
    for (final (next, current, newer) in [
      ('v1.10.0', '1.9.9', true),
      ('2.0.0', '1.999.999', true),
      ('1.0.5', '1.0.5+6', false),
      ('1.0.4', '1.0.5', false),
      ('1.0.5', '1.0.5-rc.2', true),
      ('1.0.6-beta.1', '1.0.5', false),
      ('1.0.5', 'dev', false),
      ('garbage', '1.0.5', false),
    ]) {
      expect(newerRelease(next, current), newer, reason: '$next / $current');
    }
  });

  test('recorded published release parses notes and complete platform assets', () {
    expect(release.version, '1.0.5');
    expect(release.notes, contains('## Что нового'));
    expect(release.asset('SHA256SUMS').size, greaterThan(0));
    for (final format in PackageFormat.values) {
      for (final name in LinuxInstallation(format, '').filenames(release.version)) {
        expect(release.asset(name).url.host, 'github.com');
      }
    }
    expect(release.asset('Sora-Setup-1.0.5-x64.exe').url.scheme, 'https');
  });

  test('reject drafts, prereleases, malformed fields, duplicates and foreign URLs', () {
    final original = jsonDecode(recorded) as Map<String, dynamic>;
    for (final field in ['draft', 'prerelease']) {
      expect(() => SoraRelease.parse(jsonEncode({...original, field: true})), throwsA(isA<UpdateFailure>()));
    }
    for (final tag in ['v1.0.6-rc.1', '../../oops', '1.0', 'v01.2.3']) {
      expect(() => SoraRelease.parse(jsonEncode({...original, 'tag_name': tag})), throwsA(isA<UpdateFailure>()));
    }
    final assets = original['assets'] as List;
    expect(
      () => SoraRelease.parse(
        jsonEncode({
          ...original,
          'assets': [...assets, assets.first],
        }),
      ),
      throwsA(isA<UpdateFailure>()),
    );
    expect(
      () => SoraRelease.parse(
        jsonEncode({
          ...original,
          'assets': [
            {...assets.first as Map, 'browser_download_url': 'https://example.org/setup.exe'},
          ],
        }),
      ),
      throwsA(isA<UpdateFailure>()),
    );
    expect(() => SoraRelease.parse('{}'), throwsA(isA<UpdateFailure>()));
    expect(() => SoraRelease.parse('not json'), throwsA(isA<UpdateFailure>()));
    expect(
      () => SoraRelease.parse(recorded.replaceAll('/levvs-one/sora/', '/levvs-one/sora-legacy/')),
      throwsA(isA<UpdateFailure>()),
    );
  });

  test('recorded release script matches SHA256SUMS, corruption and ambiguity fail', () async {
    final sums = File('test/fixtures/releases/SHA256SUMS').readAsStringSync();
    final script = File('test/fixtures/releases/install.sh');
    await verifyUpdateFile(script, sums, 'install.sh');
    expect(
      expectedHash(
        sums.replaceAll('  install.sh', ' *install.sh').toUpperCase().replaceAll('INSTALL.SH', 'install.sh'),
        'install.sh',
      ),
      expectedHash(sums, 'install.sh'),
    );
    final work = await Directory.systemTemp.createTemp('sora-hash-test-');
    addTearDown(() => work.delete(recursive: true));
    final changed = await File('${work.path}/install.sh').writeAsString('${script.readAsStringSync()}corrupted');
    await expectLater(verifyUpdateFile(changed, sums, 'install.sh'), throwsA(isA<UpdateFailure>()));
    expect(() => expectedHash(sums, 'missing'), throwsA(isA<UpdateFailure>()));
    expect(
      () => expectedHash('$sums${expectedHash(sums, 'install.sh')}  install.sh\n', 'install.sh'),
      throwsA(isA<UpdateFailure>()),
    );
  });

  for (final (manager, format) in [
    ('deb', PackageFormat.deb),
    ('rpm', PackageFormat.rpm),
    ('zypper', PackageFormat.rpm),
    ('arch', PackageFormat.arch),
  ]) {
    test('detect installed executable ownership with $manager', () async {
      final detected = await LinuxInstallation.detect((exe, args) => packageQuery(manager, exe, args), executable);
      expect(detected!.format, format);
      expect(detected.filenames(release.version).length, 2);
      expect(detected.manager, switch (manager) {
        'deb' => 'apt-get',
        'rpm' => 'dnf',
        'arch' => 'pacman',
        _ => manager,
      });
    });
  }

  test('unowned executable and missing core never select a package manager', () async {
    expect(await LinuxInstallation.detect((exe, args) async => ProcessResult(1, 1, '', ''), executable), isNull);
    expect(
      await LinuxInstallation.detect((exe, args) async {
        if (exe == 'pacman' && args.first == '-Qoq') return ProcessResult(1, 0, 'sora\n', '');
        if (exe == 'pacman' && args.first == '-Qq') return ProcessResult(1, 0, 'sora\n', '');
        return ProcessResult(1, 1, '', '');
      }, executable),
      isNull,
    );
    expect(shellQuote("/tmp/a'b c"), "'/tmp/a'\\''b c'");
  });

  test('automatic failures stay quiet, explicit failures are visible', () async {
    final settings = await Settings.load();
    var notices = 0;
    final updater = AppUpdater(
      settings,
      connection: () => UpdateConnection.idle,
      available: (_) async {
        notices++;
      },
      client: () => MockClient((_) async => http.Response('{"message":"rate limit"}', 403)),
    );
    addTearDown(updater.dispose);
    await updater.check();
    expect(updater.error, isNull);
    expect(notices, 0);
    await updater.check(manual: true);
    expect(updater.error, UpdateError.network);
    expect(updater.checking, isFalse);
  });

  test('automatic success publishes the recorded release', () async {
    final settings = await Settings.load();
    var notices = 0;
    final updater = AppUpdater(
      settings,
      version: '1.0.4',
      connection: () => UpdateConnection.idle,
      available: (_) async {
        notices++;
      },
      client: () => MockClient((request) async {
        // S11a: a valid policy for the rollout feed, the recorded release
        // for everything else. Serving the release JSON on the rollout URL
        // would fail RolloutPolicy.parse and withhold the update.
        if (request.url.toString() == rolloutPolicyUrl) {
          return http.Response(
            '{"format":1,"rollout":{"version":"1.0.5","percent":100},"blocked_versions":[]}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response.bytes(utf8.encode(recorded), 200);
      }),
    );
    addTearDown(updater.dispose);
    await updater.check(manual: true).timeout(const Duration(seconds: 2));
    expect(updater.error, isNull);
    expect(updater.latest, isNotNull);
    expect(notices, 1);
  });

  testWidgets('start and twelve-hour checks obey settings and persist one notice per version', (tester) async {
    final settings = await Settings.load();
    var checks = 0, notices = 0;
    final updater = AppUpdater(
      settings,
      version: '1.0.4',
      connection: () => UpdateConnection.idle,
      available: (_) async {
        notices++;
      },
      client: () => MockClient((request) async {
        // S11a: the rollout feed gets a valid policy; only release-API
        // fetches count as update checks.
        if (request.url.toString() == rolloutPolicyUrl) {
          return http.Response(
            '{"format":1,"rollout":{"version":"1.0.5","percent":100},"blocked_versions":[]}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        checks++;
        return http.Response(recorded, 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
    updater.start();
    await finishCheck(tester, updater);
    expect(checks, 1);
    expect(notices, 1);
    await tester.pump(const Duration(hours: 12));
    await finishCheck(tester, updater);
    expect(checks, 2);
    expect(notices, 1);
    await updater.setChecking(false);
    await tester.pump(const Duration(hours: 24));
    expect(checks, 2);
    expect((await Settings.load()).checkUpdates, isFalse);
    await updater.setChecking(true);
    await finishCheck(tester, updater);
    expect(checks, 3);
    expect(notices, 1);
    updater.dispose();
    final reloaded = AppUpdater(
      await Settings.load(),
      version: '1.0.4',
      connection: () => UpdateConnection.idle,
      available: (_) async {
        notices++;
      },
      client: () => MockClient((request) async {
        // S11a: the rollout feed gets a valid policy, like in the updater
        // above; the notices stay at 1 either way because the version was
        // already announced.
        if (request.url.toString() == rolloutPolicyUrl) {
          return http.Response(
            '{"format":1,"rollout":{"version":"1.0.5","percent":100},"blocked_versions":[]}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(recorded, 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
    final checked = reloaded.check();
    await finishCheck(tester, reloaded);
    await checked;
    expect(notices, 1);
    reloaded.dispose();
  });

  for (final manager in ['deb', 'rpm', 'zypper', 'arch', 'windows']) {
    for (final scenario in ['success', 'hash', 'connecting', 'changed', 'cancel', 'manual', 'denied', 'missing']) {
      if (manager == 'windows' && ['manual', 'denied'].contains(scenario)) continue;
      test('$manager install: $scenario', () async {
        final settings = await Settings.load();
        var state = scenario == 'connecting' ? UpdateConnection.changing : UpdateConnection.connected;
        final order = <String>[];
        final requests = <String>[];
        String? downloadDirectory;
        final data = <String, List<int>>{};
        final names = manager == 'windows'
            ? ['Sora-Setup-1.0.5-x64.exe']
            : LinuxInstallation(
                manager == 'deb'
                    ? PackageFormat.deb
                    : manager == 'arch'
                    ? PackageFormat.arch
                    : PackageFormat.rpm,
                '',
              ).filenames('1.0.5');
        for (final name in names) {
          data[name] = utf8.encode('Test bytes for $name');
        }
        data['SHA256SUMS'] = utf8.encode([for (final name in names) '${sha256.convert(data[name]!)}  $name\n'].join());
        final assets = {
          for (final name in [...names, 'SHA256SUMS'])
            name: ReleaseAsset(name, release.asset(name).url, data[name]!.length),
        };
        if (scenario == 'missing') assets.remove(names.last);
        // S11b: the previous release the rollback cache is built from.
        final oldInstall = manager == 'windows'
            ? null
            : LinuxInstallation(
                manager == 'deb'
                    ? PackageFormat.deb
                    : manager == 'arch'
                    ? PackageFormat.arch
                    : PackageFormat.rpm,
                '',
              );
        final oldNames = oldInstall?.filenames('1.0.4') ?? <String>[];
        final oldData = <String, List<int>>{};
        for (final name in oldNames) {
          oldData[name] = utf8.encode('Old bytes for $name');
        }
        oldData['SHA256SUMS'] = utf8.encode(
          [for (final name in oldNames) '${sha256.convert(oldData[name]!)}  $name\n'].join(),
        );
        final oldReleaseJson = jsonEncode({
          'tag_name': 'v1.0.4',
          'draft': false,
          'prerelease': false,
          'body': 'old release',
          'assets': [
            for (final name in [...oldNames, 'SHA256SUMS'])
              {
                'name': name,
                'browser_download_url': 'https://github.com/levvs-one/sora/releases/download/v1.0.4/$name',
                'size': oldData[name]!.length,
              },
          ],
        });
        // S11b: point the rollback cache at a temp dir, never the real cache.
        final rollbackRoot = await Directory.systemTemp.createTemp('sora-rollback-test-');
        addTearDown(() => rollbackRoot.delete(recursive: true));
        final updater = AppUpdater(
          settings,
          version: '1.0.4',
          executable: executable,
          windows: manager == 'windows',
          connection: () => state,
          available: (_) async {
            order.add('notice');
          },
          canElevate: () async => scenario != 'manual',
          rollbackDir: (v) => Directory('${rollbackRoot.path}/$v'),
          client: () => MockClient((request) async {
            final path = request.url.path;
            // S11b: the rollback cache is built from the previous release.
            if (path.endsWith('/releases/tags/v1.0.4')) {
              requests.add('old-release');
              return http.Response(oldReleaseJson, 200, headers: {'content-type': 'application/json; charset=utf-8'});
            }
            final name = request.url.pathSegments.last;
            requests.add(name);
            if (scenario == 'changed' && name == names.last) state = UpdateConnection.changing;
            final old = path.contains('/download/v1.0.4/');
            final bytes = (old ? oldData[name] : data[name])!;
            return http.Response.bytes(
              scenario == 'hash' && !old && name == names.last ? List<int>.filled(bytes.length, 0) : bytes,
              200,
            );
          }),
          run: (exe, args) async {
            if (exe != '/usr/bin/pkexec') return packageQuery(manager, exe, args);
            order.add('install');
            downloadDirectory = args.last;
            expect(args.take(3), [
              updateHelper,
              manager == 'deb'
                  ? 'deb'
                  : manager == 'arch'
                  ? 'arch'
                  : 'rpm',
              '1.0.5',
            ]);
            for (final name in names) {
              await verifyUpdateFile(File('${args.last}/$name'), utf8.decode(data['SHA256SUMS']!), name);
            }
            expect(settings.resumeAfterUpdate, isTrue);
            return ProcessResult(1, scenario == 'denied' ? 126 : 0, '', '');
          },
        );
        addTearDown(updater.dispose);
        updater.latest = SoraRelease('1.0.5', release.notes, assets);
        await updater.install(
          confirmDrop: () async {
            order.add('warn');
            return scenario != 'cancel';
          },
          launchWindows: (file) async {
            order.add('install');
            downloadDirectory = file.parent.path;
            expect(await file.exists(), isTrue);
            expect(settings.resumeAfterUpdate, isTrue);
          },
          restartLinux: () async {
            order.add('restart');
          },
          quit: () async {
            order.add('quit');
          },
        );
        expect(updater.busy, isFalse);
        if (scenario == 'success') {
          expect(order, manager == 'windows' ? ['warn', 'install', 'quit'] : ['warn', 'install', 'restart', 'quit']);
          expect(updater.error, isNull);
          if (manager != 'windows') {
            // S11b: the health-check marker names the handoff, and the
            // rollback cache holds verified copies of the old packages.
            final marker = PendingUpdate.parse(settings.pendingUpdate);
            expect(marker?.from, '1.0.4');
            expect(marker?.to, '1.0.5');
            final cache = Directory('${rollbackRoot.path}/1.0.4');
            for (final name in [...oldNames, 'SHA256SUMS']) {
              expect(await File('${cache.path}/$name').exists(), isTrue, reason: name);
            }
            for (final name in oldNames) {
              await verifyUpdateFile(File('${cache.path}/$name'), utf8.decode(oldData['SHA256SUMS']!), name);
            }
          } else {
            expect(settings.pendingUpdate, isEmpty);
          }
        } else if (scenario == 'manual' || scenario == 'denied') {
          expect(updater.manualCommand, contains('sora-core'));
          expect(updater.manualCommand, contains(names.last));
          expect(order, scenario == 'manual' ? ['warn'] : ['warn', 'install']);
          expect(settings.resumeAfterUpdate, isFalse);
          // No handoff happened (manual) or it failed (denied): no marker.
          expect(settings.pendingUpdate, isEmpty);
        } else {
          expect(order, scenario == 'cancel' ? ['warn'] : isEmpty);
          expect(updater.error, switch (scenario) {
            'hash' => UpdateError.checksum,
            'connecting' || 'changed' => UpdateError.connecting,
            'missing' => UpdateError.release,
            _ => null,
          });
          if (['connecting', 'missing'].contains(scenario)) expect(requests, isEmpty);
          expect(settings.resumeAfterUpdate, isFalse);
          expect(settings.pendingUpdate, isEmpty);
        }
        // Test artifacts remain only when the product intentionally keeps a
        // downloaded installer or a manual-install pair.
        if (updater.manualCommand != null) {
          final core = RegExp("'([^']+/sora-core[^']+)'").firstMatch(updater.manualCommand!);
          downloadDirectory ??= File(core![1]!).parent.path;
        }
        if (downloadDirectory != null && Directory(downloadDirectory!).existsSync()) {
          await Directory(downloadDirectory!).delete(recursive: true);
        }
      });
    }
  }

  group('post-update health check and automatic rollback (S11b)', () {
    AppUpdater makeUpdater(
      Settings settings, {
      required Directory rollbackRoot,
      required UpdateProcess run,
      String version = '1.0.5',
    }) {
      final updater = AppUpdater(
        settings,
        version: version,
        executable: executable,
        windows: false,
        connection: () => UpdateConnection.idle,
        available: (_) async {},
        canElevate: () async => true,
        rollbackDir: (v) => Directory('${rollbackRoot.path}/$v'),
        run: run,
      );
      addTearDown(updater.dispose);
      return updater;
    }

    /// Builds a hash-verified rollback cache for 1.0.4 under [root].
    Future<Directory> makeCache(Directory root, {bool tamper = false}) async {
      final cache = Directory('${root.path}/1.0.4');
      await cache.create(recursive: true);
      final names = const LinuxInstallation(PackageFormat.deb, '').filenames('1.0.4');
      final manifest = StringBuffer();
      for (final name in names) {
        final bytes = utf8.encode('Old bytes for $name');
        await File('${cache.path}/$name')
            .writeAsBytes(tamper && name == names.last ? List<int>.filled(bytes.length, 0) : bytes, flush: true);
        manifest.writeln('${sha256.convert(bytes)}  $name');
      }
      await File('${cache.path}/SHA256SUMS').writeAsString(manifest.toString(), flush: true);
      return cache;
    }

    Future<Directory> makeRoot() async {
      final root = await Directory.systemTemp.createTemp('sora-rollback-test-');
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      return root;
    }

    Future<void> saveMarker(Settings settings, {required int atMs}) =>
        settings.savePendingUpdate(PendingUpdate(from: '1.0.4', to: '1.0.5', atMs: atMs).encode());

    test('marker parsing is strict', () {
      expect(PendingUpdate.parse(''), isNull);
      expect(PendingUpdate.parse('not json'), isNull);
      expect(PendingUpdate.parse('{}'), isNull);
      expect(PendingUpdate.parse(jsonEncode({'from': '1.0.4', 'to': '1.0.5'})), isNull);
      expect(PendingUpdate.parse(jsonEncode({'from': '1.0.4', 'to': 'bogus', 'atMs': 1})), isNull);
      final marker = PendingUpdate.parse(jsonEncode({'from': 'v1.0.4', 'to': '1.0.5', 'atMs': 42}))!;
      expect(marker.from, '1.0.4');
      expect(marker.to, '1.0.5');
      expect(marker.atMs, 42);
      final roundTrip = PendingUpdate.parse(marker.encode())!;
      expect(roundTrip.from, marker.from);
      expect(roundTrip.to, marker.to);
      expect(roundTrip.atMs, marker.atMs);
    });

    test('absent marker is a no-op', () async {
      final settings = await Settings.load();
      var restarted = false;
      var didQuit = false;
      final updater = makeUpdater(
        settings,
        rollbackRoot: await makeRoot(),
        run: (exe, args) async => throw StateError('must not elevate'),
      );
      await updater.checkPendingUpdate(
        coreHealthy: () => false,
        restart: () async => restarted = true,
        quit: () async => didQuit = true,
      );
      expect(restarted, isFalse);
      expect(didQuit, isFalse);
      expect(updater.error, isNull);
    });

    test('marker for another build is cleared silently', () async {
      final settings = await Settings.load();
      await saveMarker(settings, atMs: DateTime.now().millisecondsSinceEpoch);
      final updater = makeUpdater(
        settings,
        rollbackRoot: await makeRoot(),
        version: '1.0.6',
        run: (exe, args) async => throw StateError('must not elevate'),
      );
      var rolledBack = false;
      await updater.checkPendingUpdate(
        coreHealthy: () => false,
        restart: () async => rolledBack = true,
        quit: () async {},
      );
      expect(rolledBack, isFalse);
      expect(settings.pendingUpdate, isEmpty);
      expect(updater.error, isNull);
    });

    test('healthy core clears a fresh marker without rollback', () async {
      final settings = await Settings.load();
      await saveMarker(settings, atMs: DateTime.now().millisecondsSinceEpoch);
      final updater = makeUpdater(
        settings,
        rollbackRoot: await makeRoot(),
        run: (exe, args) async => throw StateError('must not elevate'),
      );
      await updater.checkPendingUpdate(
        coreHealthy: () => true,
        restart: () async => throw StateError('must not restart'),
        quit: () async => throw StateError('must not quit'),
      );
      expect(settings.pendingUpdate, isEmpty);
      expect(updater.error, isNull);
    });

    test('core answering inside the window disarms the rollback', () async {
      final settings = await Settings.load();
      await saveMarker(settings, atMs: DateTime.now().millisecondsSinceEpoch);
      var elevated = false;
      final updater = makeUpdater(
        settings,
        rollbackRoot: await makeRoot(),
        run: (exe, args) async {
          elevated = true;
          return ProcessResult(1, 0, '', '');
        },
      );
      // Arming runs synchronously: no await precedes it in checkPendingUpdate.
      unawaited(
        updater.checkPendingUpdate(
          coreHealthy: () => false,
          restart: () async => throw StateError('must not restart'),
          quit: () async => throw StateError('must not quit'),
        ),
      );
      await updater.noteCoreHealthy();
      expect(settings.pendingUpdate, isEmpty);
      expect(elevated, isFalse);
      expect(updater.error, isNull);
    });

    test('stale marker rolls back through the helper with --allow-downgrade', () async {
      final settings = await Settings.load();
      final root = await makeRoot();
      final cache = await makeCache(root);
      await saveMarker(settings, atMs: DateTime.now().millisecondsSinceEpoch - 61 * 1000);
      final pkexecArgs = <List<String>>[];
      var restarted = false;
      var didQuit = false;
      final updater = makeUpdater(
        settings,
        rollbackRoot: root,
        run: (exe, args) async {
          if (exe == '/usr/bin/pkexec') {
            pkexecArgs.add(args);
            return ProcessResult(1, 0, '', '');
          }
          return packageQuery('deb', exe, args);
        },
      );
      await updater.checkPendingUpdate(
        coreHealthy: () => false,
        restart: () async => restarted = true,
        quit: () async => didQuit = true,
      );
      expect(pkexecArgs, hasLength(1));
      expect(pkexecArgs.single, [updateHelper, 'deb', '1.0.4', cache.path, '--allow-downgrade']);
      expect(settings.pendingUpdate, isEmpty);
      expect(restarted, isTrue);
      expect(didQuit, isTrue);
      expect(updater.error, isNull);
      final notice = updater.lastRollback;
      expect(notice?.from, '1.0.4');
      expect(notice?.to, '1.0.5');
      await updater.dismissRollbackNotice();
      expect(settings.lastRollback, isEmpty);
      expect(updater.lastRollback, isNull);
    });

    test('tampered rollback cache refuses the downgrade (fail-closed)', () async {
      final settings = await Settings.load();
      final root = await makeRoot();
      await makeCache(root, tamper: true);
      await saveMarker(settings, atMs: DateTime.now().millisecondsSinceEpoch - 61 * 1000);
      var elevated = false;
      final updater = makeUpdater(
        settings,
        rollbackRoot: root,
        run: (exe, args) async {
          if (exe == '/usr/bin/pkexec') {
            elevated = true;
            return ProcessResult(1, 0, '', '');
          }
          return packageQuery('deb', exe, args);
        },
      );
      await updater.checkPendingUpdate(
        coreHealthy: () => false,
        restart: () async => throw StateError('must not restart'),
        quit: () async => throw StateError('must not quit'),
      );
      expect(elevated, isFalse);
      expect(updater.error, UpdateError.rollback);
      // Tampered files must not be offered for manual install either.
      expect(updater.manualCommand, isNull);
      expect(settings.pendingUpdate, isEmpty);
    });

    test('failed helper run surfaces the error and a manual command', () async {
      final settings = await Settings.load();
      final root = await makeRoot();
      await makeCache(root);
      await saveMarker(settings, atMs: DateTime.now().millisecondsSinceEpoch - 61 * 1000);
      final updater = makeUpdater(
        settings,
        rollbackRoot: root,
        run: (exe, args) async {
          if (exe == '/usr/bin/pkexec') return ProcessResult(1, 1, '', 'denied');
          return packageQuery('deb', exe, args);
        },
      );
      await updater.checkPendingUpdate(
        coreHealthy: () => false,
        restart: () async => throw StateError('must not restart'),
        quit: () async => throw StateError('must not quit'),
      );
      expect(updater.error, UpdateError.rollback);
      // The verified cache is safe to reinstall by hand.
      expect(updater.manualCommand, contains('sora-core_1.0.4_amd64.deb'));
      expect(settings.pendingUpdate, isEmpty);
    });

    test('install aborts when the rollback cache cannot be prepared', () async {
      final settings = await Settings.load();
      final data = <String, List<int>>{};
      final names = const LinuxInstallation(PackageFormat.deb, '').filenames('1.0.5');
      for (final name in names) {
        data[name] = utf8.encode('Test bytes for $name');
      }
      data['SHA256SUMS'] = utf8.encode([for (final name in names) '${sha256.convert(data[name]!)}  $name\n'].join());
      final assets = {
        for (final name in [...names, 'SHA256SUMS'])
          name: ReleaseAsset(name, release.asset(name).url, data[name]!.length),
      };
      final root = await makeRoot();
      final updater = AppUpdater(
        settings,
        version: '1.0.4',
        executable: executable,
        windows: false,
        connection: () => UpdateConnection.connected,
        available: (_) async {},
        canElevate: () async => true,
        rollbackDir: (v) => Directory('${root.path}/$v'),
        client: () => MockClient((request) async {
          // The previous release is gone: no rollback cache can be built.
          if (request.url.path.endsWith('/releases/tags/v1.0.4')) {
            return http.Response('not found', 404);
          }
          return http.Response.bytes(data[request.url.pathSegments.last]!, 200);
        }),
        run: (exe, args) async {
          if (exe == '/usr/bin/pkexec') return ProcessResult(1, 0, '', '');
          return packageQuery('deb', exe, args);
        },
      );
      addTearDown(updater.dispose);
      updater.latest = SoraRelease('1.0.5', release.notes, assets);
      await updater.install(
        confirmDrop: () async => true,
        launchWindows: (_) async => throw StateError('must not launch'),
        restartLinux: () async => throw StateError('must not restart'),
        quit: () async {},
      );
      // Fail-closed: the update is refused because the safety net is unavailable.
      expect(updater.error, UpdateError.rollbackCache);
      expect(updater.installed, isFalse);
      expect(settings.pendingUpdate, isEmpty);
    });
  });

  Future<UpdateSora> showApp(WidgetTester tester, {double width = 1440}) async {
    size(tester, width, 900);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings
      ..language = 'ru'
      ..animations = false;
    final sora = UpdateSora(settings)..phase = Phase.off;
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora, desktop: RecordingDesktop(sora)));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
    return sora;
  }

  testWidgets('one update toast opens About with recorded markdown and navigation badge', (tester) async {
    final sora = await showApp(tester);
    final checked = sora.updates.check();
    await finishCheck(tester, sora.updates);
    await checked;
    await tester.pumpAndSettle();
    expect(find.text('Доступна версия 1.0.5'), findsOneWidget);
    expect(sora.history.single.action, 'update');
    final sidebar = find.byKey(const ValueKey('sidebar'));
    final badges = tester.widgetList<Badge>(find.descendant(of: sidebar, matching: find.byType(Badge)));
    expect(badges.where((b) => b.isLabelVisible).length, 1);
    final repeated = sora.updates.check();
    await finishCheck(tester, sora.updates);
    await repeated;
    await tester.pumpAndSettle();
    expect(sora.history.length, 1);
    await tester.tap(find.text('Доступна версия 1.0.5'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Версия 1.0.4'), findsOneWidget);
    final markdown = tester.widget<MarkdownBody>(find.byKey(const ValueKey('release-notes')));
    expect(markdown.data, release.notes);
    expect(markdown.selectable, isTrue);
    expect(markdown.onTapLink, isNotNull);
    expect(tester.widget<PrimaryButton>(find.byKey(const ValueKey('install-update'))).onTap, isNotNull);
    sora.phase = Phase.connecting;
    sora.notifyListeners();
    await tester.pumpAndSettle();
    expect(tester.widget<PrimaryButton>(find.byKey(const ValueKey('install-update'))).onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final width in [1000.0, 420.0]) {
    testWidgets('About markdown fits at $width and settings persist update checks', (tester) async {
      final sora = await showApp(tester, width: width);
      final checked = sora.updates.check();
      await finishCheck(tester, sora.updates);
      await checked;
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await section(tester, 8);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('install-update')),
        300,
        scrollable: find.descendant(of: find.byType(AboutScreen), matching: find.byType(Scrollable)).first,
      );
      expect(tester.takeException(), isNull);
      await section(tester, 6);
      await tester.scrollUntilVisible(
        find.text('Проверять обновления'),
        -300,
        scrollable: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)).first,
      );
      await tester.tap(find.text('Проверять обновления'));
      await tester.pumpAndSettle();
      expect(sora.settings.checkUpdates, isFalse);
      expect((await Settings.load()).checkUpdates, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
