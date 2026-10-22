import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/qr.dart';
import 'package:sora/src/ui/subscription.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/ui/servers.dart';
import 'package:sora/src/ui/home.dart';
import 'package:sora/src/ui/shell.dart';

import 'desktop_shell_test.dart' show section, size;
import 'fixtures/desktop_state.dart';
import 'extension_ui_test.dart' show extensionScreenshots;

void main() {
  extensionScreenshots();
  testWidgets('desktop section screenshots', (tester) async {
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      final output = '${Platform.environment['HOME']!}/.local/share/sora-dev/shots';
      await tester.runAsync(() async {
        final inter = FontLoader('Inter')
          ..addFont(Future.value(ByteData.sublistView(await File('assets/fonts/InterVariable.ttf').readAsBytes())));
        await inter.load();
        for (final family in ['Arabic', 'Bengali', 'Devanagari', 'Thai', 'Armenian', 'Georgian']) {
          await (FontLoader(
            'Noto Sans $family',
          )..addFont(rootBundle.load('assets/fonts/NotoSans$family-Regular.ttf'))).load();
        }
        await (FontLoader('Sora CJK')..addFont(rootBundle.load('assets/fonts/SoraCJK.otf'))).load();
        final emoji = FontLoader('Noto Color Emoji')
          ..addFont(
            Future.value(ByteData.sublistView(await File('/usr/share/fonts/noto/NotoColorEmoji.ttf').readAsBytes())),
          );
        await emoji.load();
        final symbols = FontLoader('packages/material_symbols_icons/MaterialSymbolsRounded')
          ..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'));
        await symbols.load();
        await (FontLoader(
          'packages/cupertino_icons/CupertinoIcons',
        )..addFont(rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'))).load();
        await Directory(output).create(recursive: true);
      });
      final capture = GlobalKey();
      Future<void> save(String path) async {
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate()) {
            await precacheImage((element.widget as Image).image, element);
          }
        });
        await tester.pumpAndSettle();
        final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final rendered = await boundary.toImage(pixelRatio: 1);
          final png = (await rendered.toByteData(format: ui.ImageByteFormat.png))!;
          await File(path).writeAsBytes(png.buffer.asUint8List());
          rendered.dispose();
        });
        debugPrint(path);
      }

      addTearDown(tester.view.reset);
      const sections = [
        (0, 'home'),
        (6, 'speedtest'),
        (8, 'extensions'),
        (4, 'notifications'),
        (1, 'rules'),
        (3, 'logs'),
        (5, 'settings'),
        (7, 'about'),
      ];
      for (final theme in ['light', 'dark']) {
        for (final (width, height) in [(1440.0, 900.0), (1000.0, 720.0), (420.0, 800.0)]) {
          SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
          final settings = await Settings.load();
          await settings.completeTour();
          settings
            ..language = Platform.environment['SORA_SHOTS_LANG'] ?? 'ru'
            ..theme = theme
            ..animations = false;
          // The published team catalog, served from the offline cache: the
          // test binding answers every HTTP request with 400.
          final extensions = await tester.runAsync(() async {
            final dir = await Directory.systemTemp.createTemp('sora-shots-ext-');
            addTearDown(() => dir.delete(recursive: true));
            final store = ExtensionStore(dir: dir.path);
            await store.catalogCache.store(await File('../extensions/catalog.json').readAsBytes());
            await store.load();
            return store;
          });
          final sora = DesktopState(settings, extensions: extensions);
          size(tester, width, height);
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: SoraApp(sora: sora),
            ),
          );
          await tester.pumpAndSettle();
          for (final (id, name) in sections) {
            tester.widget<ShellScope>(find.byType(ShellScope)).select(id);
            if (name == 'extensions') {
              // Store load and catalog cache read are real file IO that only
              // completes outside the fake clock; settling first would fire
              // the catalog's 45 s timeout instead.
              await tester.pump();
              for (var i = 0; i < 50 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
                await tester.pump(const Duration(milliseconds: 100));
                await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
              }
            }
            await tester.pump(const Duration(seconds: 6));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$name $theme $width');
            final path = '$output/$name-${width.toInt()}x${height.toInt()}-$theme.png';
            await save(path);
          }
          await section(tester, 1);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('description-subscription-travel')),
            180,
            scrollable: width == 420
                ? find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first
                : find.descendant(of: find.byType(ServersScreen), matching: find.byType(Scrollable)).first,
          );
          await save('$output/announcement-expanded-${width.toInt()}x${height.toInt()}-$theme.png');
          await tester.tap(find.byKey(const ValueKey('description-subscription-travel')));
          await tester.pumpAndSettle();
          if (width == 420) {
            await tester.scrollUntilVisible(
              find.text('VLESS | XHTTP | REALITY | JSON'),
              180,
              scrollable: find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first,
            );
            await save('$output/servers-${width.toInt()}x${height.toInt()}-$theme.png');
            await section(tester, 2);
            await section(tester, 1);
          }
          if (width >= 1000) {
            await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
            await tester.pumpAndSettle();
            await save('$output/sidebar-expanded-${width.toInt()}x${height.toInt()}-$theme.png');
            await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
            await tester.pumpAndSettle();
          } else if (width == 420) {
            await tester.tap(find.byKey(const ValueKey('drawer-button')));
            await tester.pumpAndSettle();
            await save('$output/sidebar-expanded-${width.toInt()}x${height.toInt()}-$theme.png');
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byKey(const ValueKey('language-button')).first);
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const ValueKey('language-search')), 'IND');
          await tester.pumpAndSettle();
          await save('$output/languages-${width.toInt()}x${height.toInt()}-$theme.png');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('mode-button')));
          await tester.pumpAndSettle();
          await save('$output/modes-${width.toInt()}x${height.toInt()}-$theme.png');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          for (final notice in [
            const ConnectionLost(),
            const ConnectionFailed(CoreFailure('core.engine.start_failed')),
          ]) {
            await sora.recordNotification(sora.notificationFor(notice));
          }
          await tester.pumpAndSettle();
          await save('$output/toast-${width.toInt()}x${height.toInt()}-$theme.png');
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          sora.dispose();
        }
      }
      for (final theme in ['light', 'dark']) {
        for (final (width, height) in [(1440.0, 900.0), (1000.0, 720.0), (420.0, 800.0)]) {
          SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
          final settings = await Settings.load();
          settings
            ..language = 'ru'
            ..theme = theme
            ..animations = false;
          final sora = Sora(settings);
          size(tester, width, height);
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: SoraApp(sora: sora),
            ),
          );
          await tester.pumpAndSettle();
          for (var step = 1; step <= 5; step++) {
            expect(find.text('Шаг $step из 5'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await save('$output/tour-$step-${width.toInt()}x${height.toInt()}-$theme.png');
            await tester.tap(find.text(step == 5 ? 'Готово' : 'Далее'));
            await tester.pumpAndSettle();
          }
          sora.phase = Phase.off;
          sora.serverlessAvailable = true;
          sora.notifyListeners();
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('connect-control')));
          await tester.pumpAndSettle();
          expect(find.byType(Dialog), findsOneWidget);
          await save('$output/empty-connect-${width.toInt()}x${height.toInt()}-$theme.png');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          sora.dispose();
        }
      }
    } finally {
      debugDisableShadows = previousShadows;
    }
  }, skip: Platform.environment['SORA_SHOTS'] == null);

  testWidgets(
    'live subscription order and sharing screenshots',
    (tester) async {
      final output = '${Platform.environment['HOME']!}/.local/share/sora-dev/shots';
      final binary = Platform.environment['SORA_CORE_BIN']!;
      final socket = Platform.environment['SORA_CORE_SOCKET']!;
      final dir = await tester.runAsync(() => Directory.systemTemp.createTemp('sora-share-'));
      final work = dir!;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
        await (FontLoader(
          'packages/material_symbols_icons/MaterialSymbolsRounded',
        )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
        await Directory(output).create(recursive: true);
        final result = await Process.run('openssl', [
          'req',
          '-x509',
          '-newkey',
          'rsa:2048',
          '-nodes',
          '-days',
          '1',
          '-subj',
          '/CN=127.0.0.1',
          '-addext',
          'subjectAltName=IP:127.0.0.1',
          '-keyout',
          '${work.path}/key.pem',
          '-out',
          '${work.path}/cert.pem',
        ]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
      });
      final tls = SecurityContext()
        ..useCertificateChain('${work.path}/cert.pem')
        ..usePrivateKey('${work.path}/key.pem');
      final provider = (await tester.runAsync(() => HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, tls)))!;
      final fixtures = jsonDecode(
        await tester.runAsync(() => File('../core/parser/testdata/imports.json').readAsString()) ?? '',
      ) as List;
      final template =
          (fixtures.cast<Map<String, dynamic>>().firstWhere((f) => f['name'] == 'trojan')['input'] as String)
              .split('#')
              .first;
      final body = [
        for (final (index, name) in ['Zulu', 'Alpha', 'Middle'].indexed)
          '${template.replaceFirst('example.com:443', '127.0.0.1:${48001 + index}')}#$name',
      ].join('\n');
      final serving = (await tester.runAsync(
        () async => provider.listen((request) async {
          request.response.write(body);
          await request.response.close();
        }),
      ))!;
      final core = (await tester.runAsync(
        () => Process.start(
          binary,
          [
            '-socket',
            socket,
            '-data-dir',
            '${work.path}/data',
            '-engines-dir',
            '${work.path}/engines',
            '-allow-file-keys',
          ],
          environment: {'SSL_CERT_FILE': '${work.path}/cert.pem'},
        ),
      ))!;
      unawaited(core.stdout.drain<void>());
      unawaited(core.stderr.drain<void>());
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final settings = await Settings.load();
      await settings.completeTour();
      settings
        ..animations = false
        ..probeMethod = 'connect';
      final sora = (await tester.runAsync(
        () async => Sora(settings, extensions: ExtensionStore(dir: '${work.path}/extensions')),
      ))!;
      late Future<void> running;
      final prefix = 'https://127.0.0.1:${provider.port}/subscription/';
      final url = '$prefix${List.filled(600 - prefix.length, 'x').join()}';
      try {
        await tester.runAsync(() async {
          running = sora.run();
          final deadline = DateTime.now().add(const Duration(seconds: 20));
          while (!sora.coreHandshakeDone) {
            if (DateTime.now().isAfter(deadline)) fail('Live core handshake timed out');
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          expect(await sora.addSubscription(url, name: 'Travel'), isNull);
          while (sora.subscriptions.isEmpty || sora.subscriptions.first.outbounds.length != 3) {
            if (DateTime.now().isAfter(deadline)) {
              fail('Live subscription fetch timed out: ${sora.history.map((n) => n.body)}');
            }
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        expect(sora.subscriptions.single.outbounds.map((o) => o.displayName), ['Zulu', 'Alpha', 'Middle']);
        final id = sora.subscriptions.single.settings.id;
        final capture = GlobalKey();
        Future<void> settleLive() async {
          for (var i = 0; i < 5; i++) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
            await tester.pump();
          }
          await tester.pumpAndSettle();
        }

        Future<void> save(String name, String language, String theme) async {
          expect(tester.takeException(), isNull);
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
            final path = '$output/$name-$language-$theme.png';
            await File(path).writeAsBytes(png);
            image.dispose();
            debugPrint(path);
          });
        }

        size(tester, 1440, 900);
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: SoraApp(sora: sora),
          ),
        );
        await settleLive();
        for (final language in ['ru', 'en']) {
          for (final theme in ['light', 'dark']) {
            await sora.change(
              (s) => s
                ..language = language
                ..theme = theme,
              replan: false,
            );
            await settleLive();
            final navigator = Navigator.of(tester.element(find.byType(ServersScreen)));
            final s = S.of(tester.element(find.byType(ServersScreen)));
            final share = find.byKey(ValueKey('share-subscription-$id'));
            expect(share, findsOneWidget);
            final last = find.byKey(ValueKey(sora.subscriptions.single.outbounds.last.id));
            expect(tester.getTopLeft(find.text(s.customServers)).dy, greaterThan(tester.getBottomLeft(last).dy));
            await tester.ensureVisible(share);
            await save('subscription-share-header', language, theme);
            await tester.tap(
              find.byWidgetPredicate((w) => w is RoundButton && (w.label?.startsWith(s.sortBy) ?? false)),
            );
            await tester.pumpAndSettle();
            expect(find.text(s.sortSubscription), findsOneWidget);
            expect(
              tester.getTopLeft(find.text(s.sortSubscription)).dy,
              lessThan(tester.getTopLeft(find.text(s.sortPing)).dy),
            );
            await save('subscription-sort-menu', language, theme);
            await tester.tap(
              find.byWidgetPredicate((w) => w is RoundButton && (w.label?.startsWith(s.sortBy) ?? false)),
            );
            await tester.pumpAndSettle();
            await tester.tap(share);
            await settleLive();
            expect(find.byType(QrShareScreen), findsOneWidget);
            expect(tester.widget<QrShareScreen>(find.byType(QrShareScreen)).payload, url);
            await save('subscription-share-qr', language, theme);
            navigator.pop();
            await tester.pumpAndSettle();
            unawaited(navigator.push<void>(MaterialPageRoute(builder: (_) => SubscriptionScreen(id: id))));
            await tester.pumpAndSettle();
            await save('subscription-share-sheet', language, theme);
            await tester.tap(find.byKey(ValueKey('share-subscription-sheet-$id')));
            await settleLive();
            expect(find.byType(QrShareScreen), findsOneWidget);
            expect(tester.widget<QrShareScreen>(find.byType(QrShareScreen)).payload, url);
            navigator.pop();
            await tester.pumpAndSettle();
            navigator.pop();
            await tester.pumpAndSettle();
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      } finally {
        await tester.runAsync(() async {
          sora.dispose();
          await running.timeout(const Duration(seconds: 10));
          core.kill();
          await core.exitCode;
          await serving.cancel();
          await provider.close(force: true);
          await work.delete(recursive: true);
        });
      }
    },
    skip:
        Platform.environment['SORA_SHOTS'] == null ||
        Platform.environment['SORA_CORE_BIN'] == null ||
        Platform.environment['SORA_CORE_SOCKET'] == null,
  );
}
