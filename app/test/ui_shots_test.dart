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
import 'package:sora/src/ui/addserver.dart';
import 'package:sora/src/ui/qr.dart';
import 'package:sora/src/ui/subscription.dart';
import 'package:sora/src/ui/notifications_screen.dart';
import 'package:sora/src/ui/connections.dart';
import 'package:sora/src/ui/logs.dart';
import 'package:sora/src/ui/settings_screen.dart';
import 'package:sora/src/ui/about.dart';
import 'package:sora/src/ui/program_picker.dart';
import 'package:sora/src/ui/speedtest.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/ui/servers.dart';
import 'package:sora/src/ui/home.dart';
import 'package:sora/src/ui/shell.dart';
import 'package:sora/src/ui/subscription_sheet.dart';

import 'desktop_shell_test.dart' show section, size;
import 'fixtures/desktop_state.dart';
import 'extension_ui_test.dart' show extensionScreenshots;

void main() {
  extensionScreenshots();
  testWidgets('error policy noisy day screenshots', (tester) async {
    addTearDown(tester.view.reset);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const icons = MethodChannel('xdg_icons'), iconEvents = MethodChannel('xdg_icons/events');
    messenger.setMockMethodCallHandler(icons, (call) async {
      expect(call.method, 'lookupIcon');
      return null;
    });
    messenger.setMockMethodCallHandler(iconEvents, (call) async => null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(icons, null);
      messenger.setMockMethodCallHandler(iconEvents, null);
    });
    size(tester, 1440, 900);
    final output = '${Platform.environment['HOME']!}/.local/share/sora-dev/shots';
    await tester.runAsync(() async {
      await Directory(output).create(recursive: true);
      await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
      await (FontLoader('Sora CJK')..addFont(rootBundle.load('assets/fonts/SoraCJK.otf'))).load();
      await (FontLoader(
        'packages/material_symbols_icons/MaterialSymbolsRounded',
      )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
    });
    for (final language in ['ru', 'en']) {
      for (final theme in ['light', 'dark']) {
        SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
        final settings = await Settings.load();
        await settings.completeTour();
        settings
          ..language = language
          ..theme = theme
          ..animations = false;
        final sora = DesktopState(settings);
        final s = sora.strings;
        final capture = GlobalKey();
        Future<void> save(String name) async {
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: name);
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
            final path = '$output/errors-$name-$language-$theme.png';
            await File(path).writeAsBytes(bytes);
            image.dispose();
            debugPrint(path);
          });
        }

        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: SoraApp(sora: sora),
          ),
        );
        await tester.pumpAndSettle();
        final navigator = Navigator.of(tester.element(find.byType(ServersScreen)));
        final now = DateTime.now();
        final old = <AppNotification>[];
        // Synthetic counts reproduce the reported classes, never the owner's history.
        for (var round = 0; round < 38; round++) {
          void add(String title, String body, String action) => old.add(
            AppNotification(
              time: now.subtract(Duration(minutes: round * 20)),
              title: title,
              body: body,
              action: action,
              argument: action == 'subscription' ? 'travel' : '',
            ),
          );
          add(s.errGeneric, s.errGeneric, 'logs');
          if (round < 20) add(s.noticeFailed, s.customServerLinkInvalid, 'connect');
          if (round < 30) add(s.errGeneric, [s.errSubFetch, s.errTimeout, s.errSubEmpty][round % 3], 'subscription');
          if (round < 6) add(s.errGeneric, s.errCore, 'logs');
        }
        old.insertAll(0, [
          AppNotification(
            time: now,
            title: s.subscription,
            body: s.expiresIn('Travel', 1).replaceAll('1', '#'),
            action: 'subscription',
            argument: 'travel',
          ),
          AppNotification(
            time: now,
            title: 'SpeedSmart',
            body: lookupS(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')).speedtestPageFailed,
            action: 'speedtest',
          ),
        ]);
        expect(old, hasLength(96));
        sora.history = old;
        sora.notifyListeners();
        unawaited(navigator.push<void>(MaterialPageRoute(builder: (_) => const NotificationsScreen())));
        await save('notifications-before');
        navigator.pop();
        await tester.pumpAndSettle();
        await sora.clearNotifications();
        for (var round = 0; round < 38; round++) {
          sora.reportFailure(
            const CoreFailure('core.internal.unexpected'),
            mode: FailureMode.background,
            source: 'logs',
          );
          if (round < 20) {
            sora.reportFailure(
              const CoreFailure('core.plan.outbounds_invalid'),
              mode: FailureMode.action,
              source: 'connect',
              action: 'connect',
            );
          }
          if (round < 30) {
            sora.reportFailure(
              CoreFailure(
                ['core.subscription.fetch_failed', 'core.network.timeout', 'core.subscription.no_servers'][round % 3],
              ),
              mode: FailureMode.background,
              source: 'subscription:travel',
              action: 'subscription',
              argument: 'travel',
            );
          }
          if (round < 6) {
            sora.reportFailure(CoreFailure.unavailable, mode: FailureMode.background, source: 'core');
            sora.recovered('core');
          }
        }
        expect(sora.history.length, 1);
        await save('action-toast');
        await sora.recordNotification(
          AppNotification(
            time: now,
            title: s.subscription,
            body: s.expiresIn('Travel', 1),
            action: 'subscription',
            argument: 'travel',
          ),
        );
        expect(sora.history, hasLength(2));
        sora.recovered('logs');
        sora.recovered('subscription:travel');
        // Existing servers remain visible while the latest provider refresh has failed.
        sora.subscription.lastError = SoraError(userMessageKey: 'core.network.timeout');
        sora.subscription.lastUpdate = Timestamp.fromDateTime(now.subtract(const Duration(days: 2)));
        sora.notifyListeners();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
        await save('subscription-row');
        unawaited(navigator.push<void>(MaterialPageRoute(builder: (_) => const SubscriptionsScreen())));
        await save('subscription-list');
        navigator.pop();
        await tester.pumpAndSettle();
        unawaited(navigator.push<void>(MaterialPageRoute(builder: (_) => const SubscriptionScreen(id: 'travel'))));
        await save('subscription-detail');
        navigator.pop();
        await tester.pumpAndSettle();
        unawaited(navigator.push<void>(MaterialPageRoute(builder: (_) => const NotificationsScreen())));
        await save('notifications-after');
        navigator.pop();
        await tester.pumpAndSettle();
        for (final entry in <(String, Widget)>[
          ('logs', const LogsScreen()),
          ('connections', const ConnectionsScreen()),
          ('settings', const SettingsScreen()),
          ('about', const AboutScreen()),
        ]) {
          final source = entry.$1 == 'settings' ? 'log-settings' : entry.$1;
          sora.reportFailure(const CoreFailure('core.network.timeout'), mode: FailureMode.background, source: source);
          unawaited(navigator.push<void>(MaterialPageRoute(builder: (_) => entry.$2)));
          await save(entry.$1);
          navigator.pop();
          sora.recovered(source);
          await tester.pumpAndSettle();
        }
        unawaited(navigator.push<void>(MaterialPageRoute(builder: (_) => const Scaffold(body: SpeedtestScreen()))));
        await tester.pumpAndSettle();
        await save('speedtest');
        navigator.pop();
        await tester.pumpAndSettle();
        unawaited(chooseProgram(navigator.context));
        await tester.pump();
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
          await tester.pump();
        }
        await save('program-picker');
        navigator.pop();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        sora.dispose();
        await tester.pumpAndSettle();
      }
    }
  }, skip: Platform.environment['SORA_SHOTS'] == null);

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
          await tester.ensureVisible(find.byKey(const ValueKey('modes-info')));
          await tester.tap(find.byKey(const ValueKey('modes-info')));
          await tester.pumpAndSettle();
          await Scrollable.ensureVisible(tester.element(find.text('mieru').first), alignment: 0.4);
          await save('$output/community-guide-${width.toInt()}x${height.toInt()}-$theme.png');
          await tester.ensureVisible(find.text('OLCRTC').last);
          await save('$output/olcrtc-guide-${width.toInt()}x${height.toInt()}-$theme.png');
          Navigator.of(tester.element(find.byKey(const ValueKey('modes-guide')))).pop();
          await tester.pumpAndSettle();
          final screenContext = tester.element(find.byType(ShellScope));
          unawaited(push<void>(screenContext, const QrScanScreen()));
          await tester.pumpAndSettle();
          await save('$output/olcrtc-qr-${width.toInt()}x${height.toInt()}-$theme.png');
          const olcrtcLink =
              'olcrtc://jitsi?datachannel@https://meet.example.org/myroom#'
              'd823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799'
              r'$RU / olc free sub';
          Navigator.of(tester.element(find.byType(QrScanScreen))).pop();
          await tester.pumpAndSettle();
          unawaited(showSubscriptionSheet(screenContext, link: olcrtcLink));
          await tester.pumpAndSettle();
          expect(
            find.byType(TextField).evaluate().any((e) => (e.widget as TextField).controller?.text == olcrtcLink),
            isTrue,
          );
          await save('$output/olcrtc-import-${width.toInt()}x${height.toInt()}-$theme.png');
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
      var clipboard = '';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => call.method == 'Clipboard.getData' ? {'text': clipboard} : null,
      );
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
            expect(find.byKey(const ValueKey('own-servers-group')), findsNothing);
            expect(find.byKey(const ValueKey('add-own-server')), findsOneWidget);
            await save('ownserver-list-empty', language, theme);
            await tester.tap(find.byKey(const ValueKey('add-own-server')));
            await tester.pumpAndSettle();
            expect(find.byType(AddServerScreen), findsOneWidget);
            await save('ownserver-form-empty', language, theme);
            clipboard = '$template#Home';
            await tester.tap(find.byKey(const ValueKey('custom-paste')));
            await settleLive();
            expect(tester.widget<TextField>(find.byKey(const ValueKey('custom-name'))).controller!.text, 'Home');
            await save('ownserver-form-pasted', language, theme);
            clipboard =
                fixtures.cast<Map<String, dynamic>>().firstWhere((f) => f['name'] == 'wireguard url')['input']
                    as String;
            await tester.tap(find.byKey(const ValueKey('custom-paste')));
            await settleLive();
            expect(find.byKey(const ValueKey('custom-peerKey')), findsOneWidget);
            await save('ownserver-form-wireguard', language, theme);
            await tester.tap(find.byKey(const ValueKey('custom-save')));
            await settleLive();
            expect(find.byType(AddServerScreen), findsNothing);
            expect(sora.customServers.length, 1);
            final last = find.byKey(
              ValueKey(sora.subscriptions.single.outbounds.where((o) => !o.id.startsWith('custom/')).last.id),
            );
            expect(tester.getTopLeft(find.text(s.customServers)).dy, greaterThan(tester.getBottomLeft(last).dy));
            await save('ownserver-list-filled', language, theme);
            await tester.runAsync(() => sora.deleteCustomServer(sora.customServers.single.id));
            await settleLive();
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
