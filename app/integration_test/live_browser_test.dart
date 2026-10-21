import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sora/main.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:webview_all/webview_all.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real websites survive repeated service changes and browser reopening', (tester) async {
    Future<Set<int>> browserProcesses() async {
      final processes = await Process.run('powershell.exe', [
        '-NoProfile',
        '-Command',
        "ConvertTo-Json -Compress -InputObject @(Get-Process msedgewebview2 -ErrorAction SilentlyContinue | Select-Object Id,WorkingSet64)",
      ]);
      expect(processes.exitCode, 0);
      final values = jsonDecode('${processes.stdout}') as List;
      debugPrint('WebView2 processes: $values');
      return values.map((value) => (value as Map)['Id'] as int).toSet();
    }

    final baseline = Platform.isWindows ? await browserProcesses() : <int>{};
    final settings = await Settings.load();
    await settings.completeTour();
    settings.animations = false;
    settings.language = 'ru';
    final sora = Sora(settings);
    try {
      await tester.pumpWidget(SoraApp(sora: sora));
      for (var reopen = 0; reopen < 3; reopen++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
        Object? previous;
        var loadedSites = 0;
        for (final url in ['https://www.speedtest.net/', 'https://yandex.ru/internet']) {
          final selectedAt = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
          await tester.tap(find.byKey(ValueKey('speedtest-service-$url')));
          var loaded = false;
          var recovered = false;
          String? document;
          final deadline = Stopwatch()..start();
          while (deadline.elapsed < const Duration(seconds: 150)) {
            await tester.pump(const Duration(milliseconds: 250));
            if (find.byKey(const ValueKey('speedtest-reload')).evaluate().isNotEmpty) break;
            final views = find.byType(WebViewWidget);
            if (views.evaluate().isEmpty) {
              recovered = true;
              continue;
            }
            final controller = tester.widget<WebViewWidget>(views.first).platform.params.controller;
            String? current;
            var complete = false;
            try {
              final snapshot = await controller
                  .runJavaScriptReturningResult(
                    'JSON.stringify({url:location.href,title:document.title,state:document.readyState,text:document.body?.innerText.slice(0,240)})',
                  )
                  .timeout(const Duration(seconds: 5));
              if (snapshot != document) {
                document = '$snapshot';
                debugPrint('Browser navigation: $document');
              }
              final result = await controller
                  .runJavaScriptReturningResult(
                    "location.hostname === ${jsonEncode(Uri.parse(url).host)} && document.readyState === 'complete' && document.body.innerText.length > 40",
                  )
                  .timeout(const Duration(seconds: 5));
              current = await controller.currentUrl();
              complete =
                  (result == true || result == 'true') && Uri.tryParse(current ?? '')?.host == Uri.parse(url).host;
            } catch (error) {
              debugPrint('Waiting for the website: $error');
            }
            if (complete) {
              if (previous != null && !recovered) expect(identical(controller, previous), isTrue);
              previous = controller;
              final title = await controller.getTitle();
              debugPrint('Browser cycle $reopen: $current: $title');
              if (Platform.isLinux && reopen == 0 && Platform.environment['SORA_SHOTS'] != null) {
                final output = '${Platform.environment['HOME']!}/.local/share/sora-dev/shots';
                await Directory(output).create(recursive: true);
                final capture = await Process.run('ffmpeg', [
                  '-loglevel',
                  'error',
                  '-y',
                  '-f',
                  'x11grab',
                  '-draw_mouse',
                  '0',
                  '-video_size',
                  '1120x760',
                  '-i',
                  Platform.environment['DISPLAY']!,
                  '-frames:v',
                  '1',
                  '$output/browser-native-${Uri.parse(url).host}.png',
                ]);
                expect(capture.exitCode, 0, reason: '${capture.stderr}');
              }
              loaded = true;
              break;
            }
          }
          if (loaded) {
            loadedSites++;
          } else {
            expect(find.byKey(const ValueKey('speedtest-reload')), findsOneWidget);
            expect(find.byKey(const ValueKey('speedtest-fallback')), findsOneWidget);
            expect(find.byType(WebViewWidget), findsNothing);
            final har = jsonDecode(utf8.decode(sora.browserDiagnostics.export())) as Map;
            final failures = ((har['log'] as Map)['entries'] as List).cast<Map<dynamic, dynamic>>().where((entry) {
              final request = entry['request'] as Map;
              return Uri.tryParse('${request['url']}')?.host == Uri.parse(url).host &&
                  DateTime.parse('${entry['startedDateTime']}').isAfter(selectedAt) &&
                  (entry['_error'] != null || ((entry['response'] as Map)['status'] as num) >= 400);
            }).toList();
            expect(
              failures,
              isNotEmpty,
              reason: 'A failed website needs a native HTTP/network cause; last document: $document',
            );
            debugPrint(
              'Browser cycle $reopen: $url failed remotely; ${failures.length} native failures; ${failures.last['_error']}',
            );
            previous = null;
          }
        }
        expect(loadedSites, greaterThan(0), reason: 'Each browser reopening must load a real speed-test website.');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(WebViewWidget), findsNothing);
        if (Platform.isWindows) {
          final deadline = Stopwatch()..start();
          var remaining = await browserProcesses();
          while (remaining.difference(baseline).isNotEmpty && deadline.elapsed < const Duration(seconds: 20)) {
            await tester.pump(const Duration(milliseconds: 250));
            remaining = await browserProcesses();
          }
          expect(remaining.difference(baseline), isEmpty, reason: 'Closing the browser must release its processes.');
        }
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      sora.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
