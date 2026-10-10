import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sora/src/browser_diagnostics.dart';
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
}
