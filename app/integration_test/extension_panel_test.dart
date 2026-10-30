import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/manifest.dart' show compareVersions;
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/ext/verifier.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/updates.dart' show appVersion;
import 'package:sora/src/ui/extensions/panel_screen.dart';
import 'package:webview_all/webview_all.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final scenario in ['published package', 'published versioned catalog', 'current source', 'candidate catalog']) {
    testWidgets(
      'signed Hello Panel $scenario opens twice in the native WebView and exchanges bridge messages without a running core or owner network',
      (tester) async {
        final useSource = scenario == 'current source';
        final useCandidate = scenario == 'candidate catalog';
        const root = String.fromEnvironment('SORA_PANEL_FIXTURE_ROOT');
        expect(root, isNotEmpty, reason: 'Pass the repository path as SORA_PANEL_FIXTURE_ROOT.');
        const id = 'org.sora.hello-panel';
        final work = await Directory.systemTemp.createTemp('sora-native-panel-');
        addTearDown(() async {
          if (await work.exists()) await work.delete(recursive: true);
        });
        SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
        final store = ExtensionStore(dir: work.path);
        await store.load();
        late ExtPackage package;
        late Uint8List packageBytes;
        late String authorPin;
        String? expectedSha256;
        if (useSource || useCandidate) {
          final tool = '${work.path}/sora-ext${Platform.isWindows ? '.exe' : ''}';
          final build = await Process.run('go', [
            'build',
            '-o',
            tool,
            './cmd/sora-ext',
          ], workingDirectory: '$root/tools/sora-ext');
          expect(build.exitCode, 0, reason: '${build.stderr}');
          final key = await Process.run(tool, ['keygen', '-o', '${work.path}/temporary-author']);
          expect(key.exitCode, 0, reason: '${key.stderr}');
          authorPin = (await File('${work.path}/temporary-author.pub').readAsLines()).last.trim();
          final project = await Directory('${work.path}/source').create();
          final original = Directory('$root/examples/hello-panel');
          await for (final entry in original.list(recursive: true, followLinks: false)) {
            if (entry is File) {
              final relative = entry.path.substring(original.path.length + 1);
              final target = File('${project.path}/$relative');
              await target.parent.create(recursive: true);
              await entry.copy(target.path);
            }
          }
          final manifestFile = File('${project.path}/sora-extension.json');
          final manifest = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
          (manifest['author'] as Map<String, dynamic>)['public_key'] = authorPin;
          await manifestFile.writeAsString(jsonEncode(manifest));
          final output = '${work.path}/hello-panel.soraext';
          for (final args in [
            ['pack', project.path, '-o', output],
            ['sign', '--key', '${work.path}/temporary-author.key', output],
          ]) {
            final result = await Process.run(tool, args);
            expect(result.exitCode, 0, reason: '${result.stderr}');
          }
          packageBytes = await File(output).readAsBytes();
          package = ExtPackage.open(packageBytes);
          if (useCandidate) {
            // Local test catalog only: the package has a temporary author
            // signature and does not use the production team signing key.
            final catalogDir = await Directory('${work.path}/candidate-catalog/packages').create(recursive: true);
            const name = 'hello-panel-candidate.soraext';
            await File('${catalogDir.path}/$name').writeAsBytes(packageBytes);
            final doc = jsonDecode(await File('$root/extensions/catalog.json').readAsString()) as Map<String, dynamic>;
            final oldEntry = (doc['extensions'] as List).cast<Map<String, dynamic>>().firstWhere(
              (entry) => entry['id'] == id,
            );
            doc['extensions'] = [
              {
                ...oldEntry,
                'version': package.manifest.version,
                'min_app_version': package.manifest.minAppVersion,
                'author_key': authorPin,
                'permissions': package.manifest.permissions,
                'capabilities': package.manifest.capabilities,
                'download_url': 'https://example.invalid/$name',
                'sha256': crypto.sha256.convert(packageBytes).toString(),
                'size': packageBytes.length,
              },
            ];
            await File('${work.path}/candidate-catalog/catalog.json').writeAsString(jsonEncode(doc));
          }
        }
        if (!useSource) {
          final catalogRoot = useCandidate ? '${work.path}/candidate-catalog' : '$root/extensions';
          final catalogName = scenario == 'published versioned catalog' ? 'catalog-1.1.3.json' : 'catalog.json';
          final catalogBytes = await File('$catalogRoot/$catalogName').readAsBytes();
          if (!useCandidate) {
            final signature = await File('$catalogRoot/$catalogName.minisig').readAsString();
            await verifyCatalogSignature(signature, catalogBytes);
          }
          final catalog = ExtensionCatalog.parse(catalogBytes);
          final entry = catalog.find(id)!;
          packageBytes = await File('$catalogRoot/packages/${entry.downloadUrl.split('/').last}').readAsBytes();
          package = ExtPackage.open(packageBytes);
          expect(packageBytes.length, entry.size);
          expect(package.manifest.id, entry.id);
          expect(package.manifest.version, entry.version);
          expect(package.manifest.minAppVersion, entry.minAppVersion);
          expect(package.manifest.permissions, unorderedEquals(entry.permissions));
          if (scenario == 'published versioned catalog') {
            expect(package.manifest.capabilities, unorderedEquals(entry.capabilities));
          }
          authorPin = entry.authorKey;
          expectedSha256 = entry.sha256;
        }
        final modernPanel = compareVersions(package.manifest.version, '1.0.1') >= 0;
        if (const bool.fromEnvironment('SORA_PANEL_CHECK_VERSION')) {
          expect(appVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
          expect(compareVersions(package.manifest.minAppVersion, appVersion), lessThanOrEqualTo(0));
        }
        await store.installBytes(
          packageBytes,
          source: 'catalog',
          granted: package.manifest.permissions,
          expectedSha256: expectedSha256,
          authorKeyPin: authorPin,
        );
        debugPrint('Native panel scenario=$scenario installed ${package.manifest.id}@${package.manifest.version}');
        final sora = Sora(await Settings.load(), extensions: store);
        var bodyFailed = false;
        try {
          for (var cycle = 0; cycle < 2; cycle++) {
            await tester.pumpWidget(
              SoraScope(
                sora: sora,
                child: ExtScope(
                  store: store,
                  child: MaterialApp(
                    theme: buildTheme(Brightness.light),
                    locale: const Locale('en'),
                    localizationsDelegates: S.localizationsDelegates,
                    supportedLocales: S.supportedLocales,
                    home: const ExtensionPanelScreen(extensionId: id),
                  ),
                ),
              ),
            );
            final clock = Stopwatch()..start();
            while (find.byType(WebViewWidget).evaluate().isEmpty && clock.elapsed < const Duration(seconds: 20)) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            expect(find.byType(WebViewWidget), findsOneWidget);
            expect(find.byType(CircularProgressIndicator), findsNothing);
            final controller = tester.widget<WebViewWidget>(find.byType(WebViewWidget)).platform.params.controller;
            Future<void> until(String expression) async {
              final deadline = Stopwatch()..start();
              Object? lastError;
              while (deadline.elapsed < const Duration(seconds: 20)) {
                await tester.pump(const Duration(milliseconds: 100));
                try {
                  final value = await controller
                      .runJavaScriptReturningResult(expression)
                      .timeout(const Duration(seconds: 2));
                  if (value == true || value == 'true') return;
                } catch (error) {
                  lastError = error;
                }
              }
              Object? document;
              try {
                document = await controller
                    .runJavaScriptReturningResult(
                      "JSON.stringify({url:location.href,state:document.readyState,api:typeof window.soraExt,host:typeof window.SoraExtHost,content:document.getElementById('content')?.textContent,aboutOpen:document.getElementById('about')?.open,focus:document.activeElement?.id,proof:window.nativePanelProof,sourceFailure:window.sourceFailureProof})",
                    )
                    .timeout(const Duration(seconds: 2));
              } catch (error) {
                document = '$error';
              }
              fail('Native panel did not satisfy $expression; document: $document; last error: $lastError');
            }

            // No core is started: the real API must report its not-connected code,
            // rather than leave the signed page waiting on an unresolved promise.
            await until(
              modernPanel
                  ? "document.getElementById('content')?.textContent.includes('Connect Sora') === true"
                  : "document.getElementById('content')?.textContent.includes('not-connected') === true",
            );
            if (modernPanel) {
              final noticesBeforeFailure = sora.history.length;
              await controller.runJavaScript("""
                window.sourceFailureProof = null;
                void (async () => {
                  const call = window.soraExt.call;
                  let proof = true;
                  try {
                    window.soraExt.call = (method, args) => method === 'getConnections'
                      ? Promise.resolve([{host: 'fixture.example', process: 'fixture', down_bytes: 1, up_bytes: 0}])
                      : call(method, args);
                    await load();
                    if (!content.textContent.includes('fixture.example')) throw new Error('positive rows missing');
                    for (const code of ['internal', 'permission-denied']) {
                      window.soraExt.call = (method, args) => method === 'getConnections'
                        ? Promise.reject(Object.assign(new Error('synthetic fixture'), {code}))
                        : call(method, args);
                      await load();
                      const text = content.textContent;
                      if (text.includes('fixture.example') || text.includes('No active connections')) {
                        throw new Error('failure retained rows or became empty');
                      }
                      if (!text.includes(code === 'internal' ? 'unavailable' : 'Allow connection access')) {
                        throw new Error('failure state missing');
                      }
                      if (refresh.disabled || refresh.getAttribute('aria-busy') !== 'false') {
                        throw new Error('refresh remained busy');
                      }
                    }
                  } catch (error) { proof = String(error); }
                  finally { window.soraExt.call = call; await load(); }
                  window.sourceFailureProof = proof;
                })();
              """);
              await until('window.sourceFailureProof === true');
              expect(sora.history, hasLength(noticesBeforeFailure));
              await until('document.fonts.status === "loaded" && document.fonts.check(\'15px "Inter"\')');
              await controller.runJavaScript("document.getElementById('info').click();");
              await until("document.getElementById('about').open === true");
              await until("getComputedStyle(document.getElementById('about-description')).opacity === '1'");
              await controller.runJavaScript("document.getElementById('close-info').click();");
              await until("document.getElementById('about').open === false && document.activeElement.id === 'info'");
              await controller.runJavaScript(
                "window.sourceRefreshDone = false; void load(true).then(() => { window.sourceRefreshDone = true; });",
              );
              await until('window.sourceRefreshDone === true');
              expect(find.byType(CircularProgressIndicator), findsNothing);
              expect(
                sora.history.where((notice) => notice.body == 'Connect Sora before refreshing connections.'),
                hasLength(cycle + 1),
              );
              expect(
                await controller.runJavaScriptReturningResult("document.querySelector('.err') === null"),
                isIn([true, 'true']),
              );
            }
            await controller.runJavaScript("""
          window.nativePanelProof = null;
          void (async () => {
            try {
              const before = await window.soraExt.call('getSettings');
              if (before.refresh_seconds !== ${cycle == 0 ? 5 : 7}) throw new Error('settings read mismatch');
              await window.soraExt.call('setSettings', {settings: {refresh_seconds: ${cycle + 7}}});
              const after = await window.soraExt.call('getSettings');
              if (after.refresh_seconds !== ${cycle + 7}) throw new Error('settings write mismatch');
              try {
                await window.soraExt.call('getServers');
                throw new Error('ungranted method succeeded');
              } catch (error) {
                if (error.code !== 'permission-denied') throw error;
              }
              await window.soraExt.call('notify', {title: 'Native bridge $cycle', body: 'Synthetic fixture only'});
              window.nativePanelProof = true;
            } catch (error) { window.nativePanelProof = String(error); }
          })();
        """);
            await until('window.nativePanelProof === true');
            expect(sora.history.where((notice) => notice.title == 'Hello Panel: Native bridge $cycle'), hasLength(1));
            expect((await store.getSettings(id))['refresh_seconds'], cycle + 7);
            expect(sora.link, isNull);
            expect(sora.sessionId, isNull);
            debugPrint(
              'Native signed panel scenario=$scenario cycle $cycle: initial rejection, settings, permission gate and notification passed',
            );
            if (cycle == 1) {
              if (useSource) {
                final project = Directory('${work.path}/source');
                final manifestFile = File('${project.path}/sora-extension.json');
                final manifest = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
                final version = package.manifest.version.split('.');
                final nextVersion = '${version[0]}.${version[1]}.${int.parse(version[2]) + 1}';
                manifest['version'] = nextVersion;
                (manifest['permissions'] as List).remove('notifications');
                await manifestFile.writeAsString(jsonEncode(manifest));
                final tool = '${work.path}/sora-ext${Platform.isWindows ? '.exe' : ''}';
                final output = '${work.path}/upgrade.soraext';
                for (final args in [
                  ['pack', project.path, '-o', output],
                  ['sign', '--key', '${work.path}/temporary-author.key', output],
                ]) {
                  final result = await Process.run(tool, args);
                  expect(result.exitCode, 0, reason: '${result.stderr}');
                }
                final upgrade = ExtPackage.open(await File(output).readAsBytes());
                await store.install(
                  upgrade,
                  source: 'catalog',
                  granted: upgrade.manifest.permissions,
                  authorKeyPin: authorPin,
                );
                expect(store.get(id)!.version, nextVersion);
              } else {
                await store.setEnabled(id, false);
              }
              await tester.pump(const Duration(milliseconds: 300));
              expect(find.byType(WebViewWidget), findsNothing);
              expect(find.byType(CircularProgressIndicator), findsNothing);
              debugPrint(
                'Native panel scenario=$scenario: disable or signed permission-reducing update removed the surface',
              );
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(milliseconds: 300));
          }
        } catch (error, stack) {
          bodyFailed = true;
          debugPrintStack(label: 'Native panel primary failure: $error', stackTrace: stack);
          rethrow;
        } finally {
          await tester.pumpWidget(const SizedBox());
          sora.dispose();
          try {
            await work.delete(recursive: true);
          } catch (error) {
            debugPrint('Native panel cleanup failure: $error');
            if (!bodyFailed) rethrow;
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}
