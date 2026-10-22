import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/notifications.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/notifications_screen.dart';
import 'package:sora/src/ui/logs.dart';
import 'package:sora/src/ui/subscription.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  Future<Sora> start(WidgetTester tester, List<AppNotification> history, {bool motion = false}) async {
    final settings = await Settings.load();
    settings.language = 'en';
    final sora = Sora(settings)..history = history;
    addTearDown(sora.dispose);
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: MotionScope(
          enabled: motion,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            theme: buildTheme(Brightness.light),
            home: const NotificationsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return sora;
  }

  AppNotification notice(
    DateTime time, {
    String action = '',
    String argument = '',
    String key = '',
    bool read = false,
  }) => AppNotification(
    time: time,
    title: 'Subscription',
    body: 'Update failed',
    action: action,
    argument: argument,
    failureKey: key,
    read: read,
  );

  testWidgets('short bursts collapse without combining other actions, causes, recipients or days', (tester) async {
    tester.view.physicalSize = const Size(1000, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 12);
    final yesterday = DateTime(now.year, now.month, now.day - 1, 23, 59, 30);
    final midnight = DateTime(now.year, now.month, now.day, 0, 0, 30);
    final sora = await start(tester, [
      notice(today),
      notice(today.subtract(const Duration(seconds: 30)), read: true),
      notice(today.subtract(const Duration(seconds: 60))),
      notice(today.subtract(const Duration(minutes: 3))),
      notice(today, action: 'logs'),
      notice(today, argument: 'other'),
      notice(today, key: 'different'),
      notice(midnight),
      notice(yesterday),
      notice(DateTime(now.year, now.month, now.day - 3)),
    ]);
    expect(find.byType(NotificationRow), findsNWidgets(8));
    expect(find.text('x3'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    final batch = find.byWidgetPredicate((w) => w is NotificationRow && w.notices.length == 3);
    await tester.tap(batch);
    await tester.pumpAndSettle();
    expect(sora.history.take(3).every((n) => n.read), isTrue);
    expect(sora.history.skip(3).every((n) => !n.read), isTrue);
    expect((await Settings.load()).notificationHistory.take(3).every((n) => n.read), isTrue);
    await tester.tap(find.byKey(const ValueKey('notifications-read-all')));
    await tester.pumpAndSettle();
    expect(sora.unreadCount, 0);
    expect((await Settings.load()).notificationHistory.every((n) => n.read), isTrue);
    await tester.tap(find.byKey(const ValueKey('notifications-clear')));
    await tester.pumpAndSettle();
    expect(find.text('No notifications'), findsOneWidget);
    expect(find.byType(NotificationRow), findsNothing);
    expect((await Settings.load()).notificationHistory, isEmpty);
    expect(tester.widget<TextButton>(find.byKey(const ValueKey('notifications-clear'))).onPressed, isNull);
  });

  for (final action in ['logs', 'subscription']) {
    testWidgets('$action uses the entire row as a keyboard-accessible action and marks it read', (tester) async {
      final sora = await start(tester, [notice(DateTime.now(), action: action, argument: 'test')]);
      final target = find.descendant(of: find.byType(NotificationRow), matching: find.byType(InkWell));
      if (action == 'logs') {
        await tester.tap(target);
      } else {
        for (var i = 0; i < 3; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      }
      await tester.pumpAndSettle();
      expect(sora.history.single.read, isTrue);
      if (action == 'logs') {
        expect(find.byType(LogsScreen), findsOneWidget);
      } else {
        expect(tester.widget<SubscriptionScreen>(find.byType(SubscriptionScreen)).id, 'test');
      }
    });
  }

  testWidgets('only rows inserted at the top animate and reduced motion is respected', (tester) async {
    final time = DateTime.now();
    final sora = await start(tester, [notice(time, read: true)], motion: true);
    Finder opacityFor(String title) => find.descendant(
      of: find.byType(TweenAnimationBuilder<double>),
      matching: find.byWidgetPredicate(
        (w) => w is Opacity && find.descendant(of: find.byWidget(w), matching: find.text(title)).evaluate().isNotEmpty,
      ),
    );
    sora.history = [
      AppNotification(time: time.add(const Duration(seconds: 1)), title: 'New', body: ''),
      ...sora.history,
    ];
    sora.notifyListeners();
    await tester.pump();
    expect(tester.widget<Opacity>(opacityFor('New')).opacity, 0);
    expect(tester.widget<Opacity>(opacityFor('Subscription')).opacity, 1);
    await tester.pump(Motion.fast);
    expect(tester.widget<Opacity>(opacityFor('New')).opacity, 1);
    sora.history = [
      AppNotification(time: time.add(const Duration(milliseconds: 1500)), title: 'New', body: ''),
      ...sora.history,
    ];
    sora.notifyListeners();
    await tester.pump();
    expect(find.text('x2'), findsOneWidget);
    expect(tester.widget<Opacity>(opacityFor('New')).opacity, 1);
    await sora.markNotificationsRead();
    await tester.pump();
    expect(tester.widget<Opacity>(opacityFor('New')).opacity, 1);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    sora.history = [
      AppNotification(time: time.add(const Duration(seconds: 2)), title: 'Reduced', body: ''),
      ...sora.history,
    ];
    sora.notifyListeners();
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(opacityFor('Reduced')).opacity, 1);
  });
}
