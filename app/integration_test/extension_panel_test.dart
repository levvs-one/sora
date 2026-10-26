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
  testWidgets('signed Hello Panel opens twice and exchanges native bridge messages without a core', (tester) async {
    const root = String.fromEnvironment('SORA_PANEL_FIXTURE_ROOT');
    expect(root, isNotEmpty, reason: 'Pass the repository path as SORA_PANEL_FIXTURE_ROOT.');
    const id = 'org.sora.hello-panel';
    final work = await Directory.systemTemp.createTemp('sora-native-panel-');
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final store = ExtensionStore(dir: work.path);
    await store.load();
    final package = ExtPackage.open(await File('$root/extensions/packages/hello-panel-1.0.0.soraext').readAsBytes());
    final catalog = ExtensionCatalog.parse(await File('$root/extensions/catalog.json').readAsBytes());
    await store.install(
      package,
      source: 'catalog',
      granted: package.manifest.permissions,
      authorKeyPin: catalog.entries.singleWhere((entry) => entry.id == id).authorKey,
    );
    final sora = Sora(await Settings.load(), extensions: store);
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
          fail('Native panel did not satisfy $expression; last error: $lastError');
        }

        // No core is started: the real API must report its not-connected code,
        // rather than leave the signed page waiting on an unresolved promise.
        await until("document.getElementById('content')?.textContent.includes('not-connected') === true");
        await controller.runJavaScript("""
          window.nativePanelProof = null;
          (async () => {
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
          'Native signed panel cycle $cycle: initial rejection, settings, permission gate and notification passed',
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 300));
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      sora.dispose();
      await work.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
