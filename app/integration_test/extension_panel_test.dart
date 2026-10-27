import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ext/catalog.dart';
import 'package:sora/src/ext/package.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/extensions/panel_screen.dart';
import 'package:webview_all/webview_all.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final useSource in [false, true]) {
    testWidgets(
      'signed Hello Panel ${useSource ? 'current source' : 'published package'} opens twice and exchanges native bridge messages without a core',
      (tester) async {
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
        late String authorPin;
        if (useSource) {
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
          package = ExtPackage.open(await File(output).readAsBytes());
        } else {
          package = ExtPackage.open(await File('$root/extensions/packages/hello-panel-1.0.0.soraext').readAsBytes());
          final catalog = ExtensionCatalog.parse(await File('$root/extensions/catalog.json').readAsBytes());
          authorPin = catalog.entries.singleWhere((entry) => entry.id == id).authorKey;
        }
        await store.install(package, source: 'catalog', granted: package.manifest.permissions, authorKeyPin: authorPin);
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
                      "JSON.stringify({url:location.href,state:document.readyState,api:typeof window.soraExt,host:typeof window.SoraExtHost,content:document.getElementById('content')?.textContent,aboutOpen:document.getElementById('about')?.open,focus:document.activeElement?.id,proof:window.nativePanelProof})",
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
              useSource
                  ? "document.getElementById('content')?.textContent.includes('Connect Sora') === true"
                  : "document.getElementById('content')?.textContent.includes('not-connected') === true",
            );
            if (useSource) {
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
              'Native signed panel source=$useSource cycle $cycle: initial rejection, settings, permission gate and notification passed',
            );
            if (cycle == 1) {
              if (useSource) {
                final project = Directory('${work.path}/source');
                final manifestFile = File('${project.path}/sora-extension.json');
                final manifest = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
                manifest['version'] = '1.0.2';
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
                expect(store.get(id)!.version, '1.0.2');
              } else {
                await store.setEnabled(id, false);
              }
              await tester.pump(const Duration(milliseconds: 300));
              expect(find.byType(WebViewWidget), findsNothing);
              expect(find.byType(CircularProgressIndicator), findsNothing);
              debugPrint(
                'Native panel source=$useSource: disable or signed permission-reducing update removed the surface',
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
