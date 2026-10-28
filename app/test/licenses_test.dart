import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/l10n/strings_ru.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/shell.dart';

Future<void> loaded(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100 && finder.evaluate().isEmpty; attempt++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  expect(finder, findsOneWidget);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('component licenses keep search, full texts and readable sizing', (tester) async {
    for (final theme in ['light', 'dark']) {
      for (final width in [1440.0, 420.0]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);
        SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
        final settings = await Settings.load();

        settings
          ..theme = theme
          ..language = 'ru'
          ..animations = false;
        final sora = Sora(settings);
        addTearDown(sora.dispose);
        final capture = GlobalKey();
        await tester.runAsync(() async {
          await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
          await (FontLoader(
            'packages/cupertino_icons/CupertinoIcons',
          )..addFont(rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'))).load();
          await (FontLoader(
            'packages/material_symbols_icons/MaterialSymbolsRounded',
          )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
        });
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: SoraApp(sora: sora),
          ),
        );
        await tester.pumpAndSettle();
        tester.widget<ShellScope>(find.byType(ShellScope)).select(7);
        await tester.pumpAndSettle();
        final componentLink = find.text('Лицензии компонентов');
        await tester.ensureVisible(componentLink);
        await tester.tap(componentLink);
        await loaded(tester, find.byKey(const ValueKey('license-components')));
        expect(find.text('Powered by Flutter'), findsNothing);
        if (width < 720) {
          expect(
            tester.getRect(find.byKey(const ValueKey('license-components'))).bottom,
            lessThanOrEqualTo(tester.getRect(find.byKey(const ValueKey('drawer-button'))).top),
          );
        }

        Future<void> shot(String name) async {
          final output = Platform.environment['SORA_LICENSE_SHOTS'];
          if (output == null) return;
          await tester.runAsync(() async {
            final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
            await Directory(output).create(recursive: true);
            await File('$output/$name-${width.toInt()}-$theme.png').writeAsBytes(png.buffer.asUint8List());
            image.dispose();
          });
        }

        await shot('licenses');
        final search = find.byKey(const ValueKey('license-search'));
        await tester.enterText(search, 'sOrA');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('license-Sora')), findsOneWidget);
        expect(find.byKey(const ValueKey('license-Xray')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('license-Sora')));
        await loaded(tester, find.byKey(const ValueKey('license-text')));
        expect(find.textContaining('GNU GENERAL PUBLIC LICENSE'), findsOneWidget);
        if (width < 720) {
          expect(
            tester.getRect(find.byKey(const ValueKey('license-text'))).bottom,
            lessThanOrEqualTo(tester.getRect(find.byKey(const ValueKey('drawer-button'))).top),
          );
        }
        await shot('license-text');
        final list = tester.widget<ListView>(find.byKey(const ValueKey('license-text')));
        expect(list.semanticChildCount, greaterThan(100), reason: 'The full GPL must remain accessible.');
        final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
        navigator.pop();
        await tester.pumpAndSettle();
        expect(tester.widget<EditableText>(find.byType(EditableText).first).controller.text, 'sOrA');
        await tester.enterText(search, 'no-such-component');
        await tester.pumpAndSettle();
        expect(find.text(SRu().speedtestEmpty), findsOneWidget);
        await tester.enterText(search, 'Xray');
        await tester.pumpAndSettle();
        for (var cycle = 0; cycle < 3; cycle++) {
          await tester.tap(find.byKey(const ValueKey('license-Xray')));
          await loaded(tester, find.byKey(const ValueKey('license-text')));
          navigator.pop();
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('license-Xray')), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    }
  });
}
