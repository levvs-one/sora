import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/ui/modes.dart';
import 'package:window_manager/window_manager.dart';

import 'fixtures/desktop_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  final settings = await Settings.load();

  settings.language = 'ru';
  final sora = DesktopState(settings);
  final navigator = GlobalKey<NavigatorState>();
  final frames = <Map<String, Object>>[];
  final errors = <String>[];
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    errors.add(details.exceptionAsString());
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, _) {
    errors.add(error.toString());
    return false;
  };
  var scene = 'startup';
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final frame in timings) {
      frames.add({
        'scene': scene,
        'build_us': frame.buildDuration.inMicroseconds,
        'raster_us': frame.rasterDuration.inMicroseconds,
        'total_us': frame.totalSpan.inMicroseconds,
      });
    }
  });
  await windowManager.ensureInitialized();
  runApp(SoraApp(sora: sora, navigator: navigator));
  await Future<void>.delayed(const Duration(seconds: 2));
  for (final theme in ['light', 'dark']) {
    await sora.change((s) => s.theme = theme, replan: false);
    for (final dimensions in [const Size(1440, 900), const Size(1000, 720), const Size(420, 800)]) {
      scene = '$theme-${dimensions.width.toInt()}';
      await windowManager.setSize(dimensions);
      await Future<void>.delayed(const Duration(seconds: 2));
      await sora.change((s) => s.sidebarExpanded = true, replan: false);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await sora.change((s) => s.sidebarExpanded = false, replan: false);
      final panel = showModes(navigator.currentState!.overlay!.context);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      navigator.currentState!.pop();
      await panel;
      await sora.recordNotification(
        AppNotification(
          time: DateTime.now(),
          title: 'Соединение прервалось',
          body: 'Sora переподключается',
          action: 'logs',
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 6));
    }
  }
  await windowManager.setSize(const Size(1440, 900));
  await Future<void>.delayed(const Duration(seconds: 2));
  await File(Platform.environment['SORA_PROFILE_OUTPUT'] ?? '/tmp/sora-ui2-profile.json')
      .writeAsString(jsonEncode({'renderer': 'Flutter Linux profile on Xvfb', 'errors': errors, 'frames': frames}));
  exit(errors.isEmpty ? 0 : 1);
}
