import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/desktop/desktop.dart';
import 'package:sora/src/ui/home.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/addserver.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/subscription_sheet.dart';
import 'package:sora/src/ui/toasts.dart';
import 'package:sora/src/ui/settings_screen.dart';

void main() {
  late Directory work;
  late Sora sora;
  final navigator = GlobalKey<NavigatorState>();
  final capture = GlobalKey();

  setUp(() async {
    work = await Directory.systemTemp.createTemp('sora-ui-feedback-');
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = await Settings.load();
    settings
      ..language = 'ru'
      ..animations = false;
    sora = Sora(settings, extensions: ExtensionStore(dir: '${work.path}/extensions'));
  });
  tearDown(() async {
    sora.dispose();
    await work.delete(recursive: true);
  });

  Future<void> mount(
    WidgetTester tester,
    WidgetBuilder builder, {
    double width = 1000,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: SoraScope(
          sora: sora,
          child: MotionScope(
            enabled: false,
            child: NotificationToasts(
              sora: sora,
              navigator: navigator,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorKey: navigator,
                theme: buildTheme(brightness),
                locale: const Locale('ru'),
                supportedLocales: S.supportedLocales,
                localizationsDelegates: S.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(body: Builder(builder: builder)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  Future<void> shot(WidgetTester tester, String name) async {
    if (Platform.environment['SORA_SHOTS'] == null) return;
    final output = Directory('${Platform.environment['HOME']}/.local/share/sora-dev/shots/ui-feedback');
    final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      await output.create(recursive: true);
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      image.dispose();
    });
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'packages/material_symbols_icons/MaterialSymbolsRounded',
    )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
  });

  for (final brightness in Brightness.values) {
    testWidgets('help is opt-in, contrast ink, does not toggle, Escape restores focus $brightness', (tester) async {
      var toggles = 0;
      await mount(
        tester,
        (context) => Center(
          child: SizedBox(
            width: 840,
            child: Group(
              children: [
                SwitchTile(
                  title: S.of(context).autoSwitchOnDegrade,
                  info: S.of(context).autoSwitchOnDegradeDetail,
                  value: false,
                  onChanged: (_) => toggles++,
                ),
              ],
            ),
          ),
        ),
        brightness: brightness,
      );
      final s = sora.strings;
      expect(find.text(s.autoSwitchOnDegradeDetail), findsNothing);
      await shot(tester, 'settings-${brightness.name}');
      await tester.tap(find.byType(InfoButton));
      await tester.pumpAndSettle();
      expect(toggles, 0);
      expect(find.text(s.autoSwitchOnDegradeDetail), findsOneWidget);
      final text = tester.widget<Text>(find.text(s.autoSwitchOnDegradeDetail));
      expect(text.style!.color, brightness == Brightness.light ? Palette.light.ink : Palette.dark.ink);
      await shot(tester, 'info-${brightness.name}');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('feature-info-dialog')), findsNothing);
      await tester.tap(find.text(s.autoSwitchOnDegrade));
      await tester.pumpAndSettle();
      expect(toggles, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('actual settings keep explanations behind info $brightness', (tester) async {
      await mount(tester, (_) => const SettingsScreen(), brightness: brightness);
      final s = sora.strings;
      expect(find.text(s.autoSwitchOnDegradeDetail), findsNothing);
      final info = find.byKey(ValueKey('info-${s.autoSwitchOnDegrade}'));
      await tester.scrollUntilVisible(info, 240, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await shot(tester, 'settings-full-${brightness.name}');
      await tester.tap(info);
      await tester.pumpAndSettle();
      expect(find.text(s.autoSwitchOnDegradeDetail), findsOneWidget);
      expect(sora.settings.autoSwitchOnDegrade, isFalse);
      await shot(tester, 'settings-info-${brightness.name}');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('server form labels and input fit with no inline errors $brightness', (tester) async {
      await mount(
        tester,
        (context) => TextButton(onPressed: () => showAddServerSheet(context), child: const Text('open')),
        brightness: brightness,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, isNotEmpty);
      for (final field in fields) {
        expect(field.decoration!.hintText, isNull);
        expect(field.decoration!.errorText, isNull);
        expect(field.textAlign, TextAlign.start);
      }
      await shot(tester, 'server-${brightness.name}');
      await tester.enterText(find.byKey(const ValueKey('custom-address')), 'bad address');
      await tester.pumpAndSettle();
      expect(find.text(sora.strings.customServerAddressInvalid), findsNothing);
      final field = tester.widget<TextField>(find.byKey(const ValueKey('custom-address')));
      expect(
        field.decoration!.enabledBorder!.borderSide.color,
        brightness == Brightness.light ? Palette.light.danger : Palette.dark.danger,
      );
      await shot(tester, 'server-invalid-${brightness.name}');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('small window and large type keep form and help scrollable', (tester) async {
    await mount(
      tester,
      (context) => TextButton(onPressed: () => showAddServerSheet(context), child: const Text('open')),
      width: 320,
      scale: 1.6,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final info = find.byKey(ValueKey('info-${sora.strings.customServerOptions}'));
    await tester.ensureVisible(info);
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(find.text(sora.strings.customServerOptionsInfo), findsOneWidget);
    await shot(tester, 'info-narrow-large');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AddServerScreen), findsOneWidget);
    await shot(tester, 'server-narrow-large');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AddServerScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop launch help is opt-in and reconnect banner is absent everywhere', (tester) async {
    sora.needsReconnect = true;
    await mount(tester, (_) => DesktopScope(desktop: Desktop(sora, navigator), child: const SettingsScreen()));
    final s = sora.strings;
    expect(find.text(s.launchAtLoginDetail), findsNothing);
    expect(find.byKey(const ValueKey('apply-connection-changes')), findsNothing);
    expect(find.text('Чтобы применить изменения, переподключитесь.'), findsNothing);
    expect(find.text('Применить и переподключить'), findsNothing);
    await shot(tester, 'settings-no-reconnect-desktop');
    await tester.tap(find.byKey(ValueKey('info-${s.launchAtLogin}')));
    await tester.pumpAndSettle();
    expect(find.text(s.launchAtLoginDetail), findsOneWidget);
    expect(tester.widget<Text>(find.text(s.launchAtLoginDetail)).style!.color, Palette.light.ink);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.modes));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mode-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('apply-connection-changes')), findsNothing);
    expect(find.text('Применить и переподключить'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await mount(tester, (_) => const HomeScreen());
    expect(find.byKey(const ValueKey('apply-connection-changes')), findsNothing);
    expect(find.text('Чтобы применить изменения, переподключитесь.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('field-sheet refusal is one notification and border, editing clears border', (tester) async {
    await mount(
      tester,
      (context) => TextButton(
        onPressed: () => showFieldSheet(
          context,
          title: 'Адрес проверки',
          hint: 'Адрес',
          initial: 'bad',
          action: 'Сохранить',
          submit: (_) async => sora.strings.invalidValue,
        ),
        child: const Text('open'),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(sora.history.where((notice) => notice.body == sora.strings.invalidValue), hasLength(1));
    expect(find.text(sora.strings.invalidValue), findsOneWidget); // The toast is the only visible copy.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.errorText, isNull);
    expect(field.decoration!.enabledBorder!.borderSide.color, Palette.light.danger);
    await shot(tester, 'field-notification');
    await tester.enterText(find.byType(TextField), 'good');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.enabledBorder!.borderSide.color,
      Colors.transparent,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  });
}
