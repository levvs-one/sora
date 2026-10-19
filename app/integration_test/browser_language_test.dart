import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/browser_diagnostics.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/speedtest_services.dart';
import 'package:sora/src/ui/speedtest.dart';
import 'package:webview_all/webview_all.dart';
import 'package:webview_all_linux/webview_all_linux.dart';
import 'package:webview_all_windows/webview_all_windows.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native browser language reaches HTTP and JavaScript; HAR contains real requests', (tester) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final received = <(String, String, String)>[];
    final listener = server.listen((request) async {
      received.add((request.method, request.uri.path, request.headers.value('accept-language') ?? ''));
      await request.drain<void>();
      request.response.headers.contentType = ContentType.html;
      if (request.uri.path == '/') {
        request.response.write(
          '<!doctype html><html><body>Native browser language test<script>fetch("/posted",{method:"POST",body:"body"}).then(()=>fetch("/missing?token=private-query")).then(()=>window.soraDone=true)</script></body></html>',
        );
      } else {
        request.response.statusCode = request.uri.path == '/missing' ? 404 : 201;
        request.response.write('Native response');
      }
      await request.response.close();
    });
    final diagnostics = BrowserDiagnostics();
    try {
      for (var cycle = 0; cycle < 3; cycle++) {
        final controller = Platform.isLinux
            ? WebViewController.fromPlatformCreationParams(
                const LinuxWebViewControllerCreationParams(pageCacheEnabled: false),
              )
            : WebViewController();
        StreamSubscription<Map<String, dynamic>>? network;
        try {
          await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
          switch (controller.platform) {
            case final LinuxWebViewController native:
              network = native.networkEvents.listen(diagnostics.webkit);
              await native.enableNetworkEvents();
            case final WindowsWebViewController native:
              network = native.networkEvents.listen((event) => diagnostics.webview2('$cycle', event));
              await native.enableNetworkEvents();
          }
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: WebViewWidget(controller: controller)),
            ),
          );
          for (final language in ['ru', 'zh-Hant', 'ar']) {
            final before = received.length;
            switch (controller.platform) {
              case final LinuxWebViewController native:
                await native.setPreferredLanguages([language, 'en']);
              case final WindowsWebViewController native:
                await native.setPreferredLanguages([language, 'en']);
            }
            await controller.loadRequest(Uri.parse('http://127.0.0.1:${server.port}/?cycle=$cycle&language=$language'));
            final clock = Stopwatch()..start();
            var done = false;
            while (clock.elapsed < const Duration(seconds: 15)) {
              await tester.pump(const Duration(milliseconds: 100));
              final value = await controller.runJavaScriptReturningResult('window.soraDone === true');
              if (value == true || value == 'true') {
                done = true;
                break;
              }
            }
            expect(done, isTrue);
            final js = await controller.runJavaScriptReturningResult('navigator.language');
            expect('$js', contains(language));
            final requests = received.skip(before).toList();
            expect(requests.map((r) => r.$2), containsAll(['/', '/posted', '/missing']));
            for (final request in requests) {
              expect(request.$3.toLowerCase(), startsWith(language.toLowerCase()));
            }
            await tester.pump(const Duration(milliseconds: 200));
            debugPrint('Native language $cycle/$language: JS=$js; HTTP=${requests.first.$3}');
          }
        } finally {
          await tester.pumpWidget(const SizedBox());
          await network?.cancel();
          diagnostics.detach('$cycle');
          switch (controller.platform) {
            case final LinuxWebViewController native:
              await native.dispose();
            case final WindowsWebViewController native:
              await native.dispose();
          }
        }
      }
      final text = utf8.decode(diagnostics.export());
      expect(text, isNot(contains('private-query')));
      final entries = (((jsonDecode(text) as Map)['log'] as Map)['entries'] as List).cast<Map<dynamic, dynamic>>();
      expect(entries, isNotEmpty);
      expect(
        entries.any((e) => (e['request'] as Map)['method'] == 'POST' && (e['response'] as Map)['status'] == 201),
        isTrue,
      );
      expect(entries.any((e) => (e['response'] as Map)['status'] == 404), isTrue);
      debugPrint('Native HAR: ${entries.length} requests, ${diagnostics.export().length} bytes');
    } finally {
      await listener.cancel();
      await server.close(force: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('native browser automatically recovers from HTTP failures and bounds retries', (tester) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String, int>{};
    final listener = server.listen((request) async {
      await request.drain<void>();
      final path = request.uri.path;
      final count = requests.update(path, (value) => value + 1, ifAbsent: () => 1);
      request.response.headers.contentType = ContentType.html;
      request.response.statusCode = path == '/recovery' && count >= 3 ? 200 : 503;
      request.response.write('<!doctype html><html><body>Native HTTP recovery response $count</body></html>');
      await request.response.close();
    });
    final settings = await Settings.load();
    settings.language = 'ru';
    final sora = Sora(settings);
    try {
      for (final path in ['/recovery', '/unavailable']) {
        final url = 'http://127.0.0.1:${server.port}$path';
        await tester.pumpWidget(
          SoraScope(
            sora: sora,
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              locale: const Locale('ru'),
              supportedLocales: S.supportedLocales,
              localizationsDelegates: S.localizationsDelegates,
              home: Scaffold(
                body: SpeedtestBrowser(
                  key: ValueKey(path),
                  service: SpeedtestService(
                    name: 'Native HTTP recovery',
                    url: url,
                    regions: const [],
                    measures: '',
                    operator: '',
                    note: '',
                  ),
                ),
              ),
            ),
          ),
        );
        final clock = Stopwatch()..start();
        var completed = false;
        while (clock.elapsed < const Duration(seconds: 30)) {
          await tester.pump(const Duration(milliseconds: 100));
          if (path == '/unavailable') {
            completed = find.byKey(const ValueKey('speedtest-reload')).evaluate().isNotEmpty;
          } else if (find.byType(WebViewWidget).evaluate().isNotEmpty) {
            final controller = tester.widget<WebViewWidget>(find.byType(WebViewWidget)).platform.params.controller;
            try {
              final result = await controller
                  .runJavaScriptReturningResult(
                    "location.pathname === '/recovery' && document.body.innerText.includes('response 3')",
                  )
                  .timeout(const Duration(seconds: 2));
              completed = result == true || result == 'true';
            } catch (error) {
              debugPrint('Waiting for native HTTP recovery: $error');
            }
          }
          if (completed) break;
        }
        expect(completed, isTrue, reason: '$path did not finish automatically');
        expect(requests[path], 3, reason: 'Two retries must recover or stop with usable actions.');
        if (path == '/unavailable') {
          expect(find.byKey(const ValueKey('speedtest-fallback')), findsOneWidget);
          expect(find.byType(WebViewWidget), findsNothing);
          await tester.pump(const Duration(seconds: 3));
          expect(requests[path], 3, reason: 'A permanent failure must not restart forever.');
        }
        debugPrint('Native HTTP $path: ${requests[path]} attempts, completed without a manual refresh');
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      }
      final har = jsonDecode(utf8.decode(sora.browserDiagnostics.export())) as Map;
      final entries = ((har['log'] as Map)['entries'] as List).cast<Map<dynamic, dynamic>>();
      expect(entries.where((e) => (e['response'] as Map)['status'] == 503).length, greaterThanOrEqualTo(5));
      expect(entries.any((e) => (e['response'] as Map)['status'] == 200), isTrue);
    } finally {
      await tester.pumpWidget(const SizedBox());
      sora.dispose();
      await listener.cancel();
      await server.close(force: true);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
