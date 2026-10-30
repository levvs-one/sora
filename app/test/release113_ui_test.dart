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
import 'package:sora/src/core/link.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/sync_daemon.dart';
import 'package:sora/src/ui/sync.dart';
import 'package:sora/src/ui/about.dart';
import 'package:sora/src/ui/benchmark.dart';
import 'package:sora/src/ui/chains.dart';
import 'package:sora/src/ui/dns.dart';
import 'package:sora/src/ui/leaktest.dart';
import 'package:sora/src/ui/profiles.dart';

class _ScreenSora extends Sora {
  _ScreenSora(super.settings, this.daemon);
  final SyncDaemon daemon;
  bool unstable = true;
  @override
  bool get watchUnstable => unstable;
  @override
  SyncDaemon get syncDaemon => daemon;
}

void main() {
  testWidgets('home status has one owner and hides actions during transitions', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = await Settings.load();
    await settings.completeTour();
    settings.animations = false;
    settings.sessionIntent = jsonEncode({'server': 'auto', 'at': DateTime.now().millisecondsSinceEpoch});
    final sora = _ScreenSora(settings, SyncDaemon())
      ..phase = Phase.off
      ..cleanupPending = true
      ..failure = const CoreFailure('core.guard.restore_failed')
      ..checkCrashIntent();
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('status-cleanup')), findsOneWidget);
    expect(find.byKey(const ValueKey('status-restore')), findsNothing);
    expect(find.byKey(const ValueKey('status-watch')), findsNothing);
    for (final phase in [Phase.connecting, Phase.reconnecting, Phase.disconnecting]) {
      sora.phase = phase;
      sora.notifyListeners();
      await tester.pumpAndSettle();
      for (final name in ['cleanup', 'restore', 'watch']) {
        expect(find.byKey(ValueKey('status-$name')), findsNothing);
      }
    }
    sora
      ..phase = Phase.off
      ..cleanupPending = false
      ..failure = null
      ..notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('status-restore')), findsOneWidget);
    expect(find.byKey(const ValueKey('status-watch')), findsNothing);
    sora.dismissCrashRestore();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('status-watch')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    sora.dispose();
  });

  testWidgets('release screens with real local device identity in both languages and themes', (tester) async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 720);
    final work = (await tester.runAsync(() => Directory.systemTemp.createTemp('sora-113-shots-')))!;
    final output = Directory('${Platform.environment['HOME']!}/.local/share/sora-dev/shots/release113');
    await tester.runAsync(() async {
      await output.create(recursive: true);
      await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
      await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader(
        'packages/cupertino_icons/CupertinoIcons',
      )..addFont(rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'))).load();
      await (FontLoader(
        'packages/material_symbols_icons/MaterialSymbolsRounded',
      )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
      final built = await Process.run('go', [
        'build',
        '-o',
        '${work.path}/sora-sync',
        './cmd/sora-sync',
      ], workingDirectory: '../service/sync');
      expect(built.exitCode, 0, reason: '${built.stderr}');
    });
    final daemon = SyncDaemon(binaryPath: '${work.path}/sora-sync', dataDir: '${work.path}/data');
    await tester.runAsync(daemon.ensureRunning);
    expect(daemon.state, SyncDaemonState.running, reason: daemon.errorDetail);
    final status = (await tester.runAsync(() => daemon.client!.status()))!;
    expect(status.deviceName, isNotEmpty);
    try {
      for (final language in ['ru', 'en']) {
        for (final theme in ['light', 'dark']) {
          SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
          final settings = await Settings.load();
          await settings.completeTour();
          settings
            ..language = language
            ..theme = theme
            ..animations = false;
          final sora = _ScreenSora(settings, daemon)
            ..phase = Phase.off
            ..serverlessAvailable = true;
          final capture = GlobalKey();
          final navigator = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            RepaintBoundary(
              key: capture,
              child: SoraApp(sora: sora, navigator: navigator),
            ),
          );
          await tester.pumpAndSettle();
          Future<void> save(String name) async {
            expect(tester.takeException(), isNull);
            final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
              await File('${output.path}/$name-$language-$theme.png').writeAsBytes(bytes);
              image.dispose();
            });
          }

          settings.sessionIntent = jsonEncode({'server': 'auto', 'at': DateTime.now().millisecondsSinceEpoch});
          sora
            ..cleanupPending = true
            ..failure = const CoreFailure('core.guard.restore_failed')
            ..checkCrashIntent();
          await tester.pumpAndSettle();
          await save('home-cleanup');
          sora
            ..cleanupPending = false
            ..failure = null
            ..notifyListeners();
          await tester.pumpAndSettle();
          await save('home-restore');
          sora.dismissCrashRestore();
          await tester.pumpAndSettle();
          await save('home-watch');
          sora.unstable = false;
          sora.notifyListeners();
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('mode-button')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const ValueKey('strict-kill-switch')));
          await tester.pumpAndSettle();
          await save('modes');
          await tester.tap(find.text(sora.strings.strictKillSwitch));
          await tester.pumpAndSettle();
          await save('strict-warning');
          navigator.currentState!.pop();
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
          unawaited(navigator.currentState!.push<void>(MaterialPageRoute(builder: (_) => const SyncScreen())));
          for (var i = 0; i < 50 && find.text(status.deviceName).evaluate().isEmpty; i++) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
            await tester.pump();
          }
          expect(find.text(status.deviceName), findsOneWidget);
          expect(find.textContaining(status.deviceId), findsNothing);
          await tester.pumpAndSettle();
          await save('sync');
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
          for (final (name, screen) in <(String, Widget)>[
            ('about', const AboutScreen()),
            ('benchmark', const BenchmarkScreen()),
            ('chains', const ChainsScreen()),
            ('dns', const DnsScreen()),
            ('leaktest', const LeakTestScreen()),
            ('profiles', const ProfilesScreen()),
          ]) {
            unawaited(navigator.currentState!.push<void>(MaterialPageRoute(builder: (_) => screen)));
            await tester.pumpAndSettle();
            await save(name);
            navigator.currentState!.pop();
            await tester.pumpAndSettle();
          }
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(daemon.stop);
          sora.dispose();
          if (language != 'en' || theme != 'dark') await tester.runAsync(daemon.ensureRunning);
        }
      }
    } finally {
      await tester.runAsync(() async {
        await daemon.stop();
        await work.delete(recursive: true);
      });
    }
  }, skip: Platform.environment['SORA_SHOTS'] == null);
}
