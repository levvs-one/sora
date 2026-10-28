import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/main.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/ui/servers.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/notification_text.dart';
import 'package:sora/src/ui/shell.dart';

void main() {
  final en = lookupS(const Locale('en')), ru = lookupS(const Locale('ru'));
  final at = DateTime.utc(2026, 10, 26, 6);
  const name = 'Work: Amsterdam / 東京';

  test('message metadata survives storage and read changes without changing actions or parameters', () {
    final args = {'entry': name};
    final notice = AppNotification(
      time: at,
      title: name,
      body: en.noticeBackup,
      messageKey: 'notice.backup',
      messageArgs: args,
      action: 'logs',
      argument: 'retained-id',
    );
    args['entry'] = 'changed outside';
    final restored = AppNotification.parse(notice.markRead().stored)!;
    expect(restored.time, at);
    expect(restored.read, isTrue);
    expect(restored.action, 'logs');
    expect(restored.argument, 'retained-id');
    expect(notificationText(ru, restored), (title: name, body: ru.noticeBackup));
    expect(() => restored.messageArgs['entry'] = 'changed', throwsUnsupportedError);
  });

  test('malformed optional metadata keeps readable legacy data and unknown event kinds keep their fallback', () {
    final raw = {
      'time': at.toIso8601String(),
      'title': 'Extension supplied title',
      'body': 'Original external text',
      'messageKey': 'notice.future-kind',
      'messageArgs': {
        'field': ['invalid'],
      },
    };
    final malformed = AppNotification.parse(jsonEncode(raw))!;
    expect(malformed.messageKey, isEmpty);
    expect(notificationText(ru, malformed), (title: raw['title'], body: raw['body']));
    raw['messageArgs'] = {'field': 'valid future argument'};
    final future = AppNotification.parse(jsonEncode(raw))!;
    expect(future.messageKey, 'notice.future-kind');
    expect(notificationText(ru, future), (title: raw['title'], body: raw['body']));
  });

  test('legacy history from every supported locale renders errors and known events in the current locale', () {
    for (final locale in S.supportedLocales) {
      final old = lookupS(locale);
      final samples = <(AppNotification, String, String)>[
        (
          AppNotification(time: at, title: old.errHttpStatus(503), body: '', failureKey: 'core.subscription.status'),
          ru.errHttpStatus(503),
          '',
        ),
        (AppNotification(time: at, title: name, body: old.noticeBackup, action: 'logs'), name, ru.noticeBackup),
        (AppNotification(time: at, title: name, body: old.noticeNext, action: 'logs'), name, ru.noticeNext),
        (AppNotification(time: at, title: name, body: old.noticeMainBack), name, ru.noticeMainBack),
        (AppNotification(time: at, title: old.noticeRestored, body: name), ru.noticeRestored, name),
        (
          AppNotification(time: at, title: old.updateAvailable('1.2.3'), body: old.updateOpenAbout, action: 'update'),
          ru.updateAvailable('1.2.3'),
          '',
        ),
        (
          AppNotification(time: at, title: old.profileApplyAsk(name), body: '', action: 'apply-profile'),
          ru.profileApplyAsk(name),
          '',
        ),
        (
          AppNotification(time: at, title: old.profileApplied(name), body: '', action: 'undo-profile'),
          ru.profileApplied(name),
          '',
        ),
        (
          AppNotification(time: at, title: old.noticeInTray, body: 'Quit from the menu of its icon'),
          ru.noticeInTray,
          '',
        ),
        for (var days = 0; days < 3; days++)
          (
            AppNotification(
              time: at,
              title: old.noticeSubscription,
              body: old.expiresIn(name, days),
              action: 'subscription',
            ),
            ru.noticeSubscription,
            ru.expiresIn(name, days),
          ),
      ];
      for (final (notice, title, body) in samples) {
        final restored = AppNotification.parse(notice.stored)!;
        expect(notificationText(ru, restored), (title: title, body: body), reason: '$locale ${notice.action}');
        expect(restored.time, at);
      }
    }
  });

  test('automatic labels are translated only when their semantic mode is known', () {
    final automatic = AppNotification(
      time: at,
      title: en.noticeRestored,
      body: en.serverAuto,
      messageKey: 'notice.connectionRestored',
      messageArgs: {'entry': en.serverAuto, 'mode': 'auto'},
    );
    final named = AppNotification(
      time: at,
      title: en.noticeRestored,
      body: en.serverAuto,
      messageKey: 'notice.connectionRestored',
      messageArgs: {'entry': en.serverAuto},
    );
    expect(notificationText(ru, automatic).body, ru.serverAuto);
    expect(notificationText(ru, named).body, en.serverAuto);
  });

  test('subscription warnings freeze original values and relocalize quantities without duplicate identities', () {
    final sub = SubscriptionState(
      settings: SubscriptionSettings(id: 'retained'),
      displayName: name,
      info: SubscriptionInfo(hasUsage: true, totalBytes: Int64(10000000), downloadBytes: Int64(9900000)),
    );
    final english = subscriptionWarning(en, sub, 'en', at: at)!;
    final russian = subscriptionWarning(ru, sub, 'ru', at: at)!;
    expect(english.messageArgs, russian.messageArgs);
    expect(english.messageKey, 'notice.traffic');
    expect(notificationText(ru, AppNotification.parse(english.stored)!).body, russian.body);
    expect(notificationText(en, russian).body, english.body);
    expect(english.messageArgs['amount'], '97.7');
    expect(english.messageArgs['unit'], '1');
    sub.info.downloadBytes = Int64(9899999);
    final rounded = subscriptionWarning(en, sub, 'en', at: at)!;
    expect(rounded.messageArgs, english.messageArgs, reason: 'sub-byte changes must not create duplicate warnings');
    expect(english.time, at);
    sub.info.downloadBytes = Int64(9999999);
    expect(notificationText(ru, english).body, russian.body);
    for (final locale in S.supportedLocales) {
      final old = lookupS(locale);
      final legacy = AppNotification(
        time: at,
        title: old.noticeSubscription,
        action: 'subscription',
        body: old.trafficLow(name, formatBytes(old, Int64(100000), old.localeName)),
      );
      expect(notificationText(ru, legacy).body, russian.body, reason: '$locale');
    }
  });

  late Directory work;
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    work = await Directory.systemTemp.createTemp('sora-notice-language-');
  });
  tearDown(() async => work.delete(recursive: true));

  final capture = GlobalKey();
  Future<Sora> mount(WidgetTester tester, {bool history = true}) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1000, 900);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();

    settings
      ..language = 'en'
      ..animations = false;
    if (history) {
      await settings.saveNotificationHistory([
        AppNotification(
          time: at,
          title: en.errHttpStatus(503),
          body: '',
          failureKey: 'core.subscription.status',
          action: 'subscription',
          argument: 'kept-id',
        ),
        AppNotification(
          time: at.subtract(const Duration(minutes: 3)),
          title: name,
          body: en.noticeBackup,
          action: 'logs',
          read: true,
        ),
      ]);
    }
    final sora = Sora(await Settings.load(), extensions: ExtensionStore(dir: '${work.path}/extensions'));
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture,
        child: SoraApp(sora: sora),
      ),
    );
    await tester.pumpAndSettle();
    if (history) {
      tester.widget<ShellScope>(find.byType(ShellScope)).select(4);
      await tester.pumpAndSettle();
    }
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      sora.dispose();
    });
    return sora;
  }

  Future<void> shot(WidgetTester tester, String language) async {
    if (Platform.environment['SORA_SHOTS'] == null) return;
    final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final dir = Directory('${Platform.environment['HOME']}/.local/share/sora-dev/shots/notification-language');
      await dir.create(recursive: true);
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      await File('${dir.path}/$language.png').writeAsBytes(bytes);
      image.dispose();
    });
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final (family, asset) in [
      ('Inter', 'assets/fonts/InterVariable.ttf'),
      ('Sora CJK', 'assets/fonts/SoraCJK.otf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      (
        'packages/material_symbols_icons/MaterialSymbolsRounded',
        'packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf',
      ),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  testWidgets('stored English history changes language immediately and survives read/reload', (tester) async {
    final sora = await mount(tester);
    expect(find.text(en.errHttpStatus(503)), findsOneWidget);
    await shot(tester, 'en');
    await sora.change((settings) => settings.language = 'ru', replan: false);
    await tester.pumpAndSettle();
    expect(find.text(ru.errHttpStatus(503)), findsOneWidget);
    expect(find.text(en.errHttpStatus(503)), findsNothing);
    expect(find.text(ru.noticeBackup), findsOneWidget);
    expect(find.text(name), findsOneWidget);
    expect(sora.history, hasLength(2));
    await shot(tester, 'ru');
    await sora.markNotificationsRead(notices: [sora.history.first]);
    final persisted = (await Settings.load()).notificationHistory;
    expect(persisted.first.read, isTrue);
    expect(persisted.first.time, at);
    expect(persisted.first.argument, 'kept-id');
    expect(notificationText(ru, persisted.first).title, ru.errHttpStatus(503));
    expect(tester.takeException(), isNull);
  });

  testWidgets('active toast follows the locale without replaying the event or adding history', (tester) async {
    final sora = await mount(tester, history: false);
    sora.reportFailure(const CoreFailure('core.tls.certificate'), mode: FailureMode.action, source: 'language-test');
    await tester.pumpAndSettle();
    expect(find.text(en.errTls), findsOneWidget);
    await sora.change((settings) => settings.language = 'ru', replan: false);
    await tester.pumpAndSettle();
    expect(find.text(ru.errTls), findsOneWidget);
    expect(find.text(en.errTls), findsNothing);
    expect(find.byType(Dismissible), findsOneWidget);
    expect(sora.history, hasLength(1));
    expect(sora.history.single.messageKey, 'notice.failure');
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
