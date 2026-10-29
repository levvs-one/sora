import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/l10n/strings_ru.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/subscription.dart';

/// Records what the screens ask the core for, without a core.
class _DeviceSora extends Sora {
  _DeviceSora(super.settings);

  SubscriptionSettings chosen = SubscriptionSettings(id: 'sub', autoUpdate: true);
  final saved = <SubscriptionSettings>[];
  final changes = <(bool, bool)>[];

  @override
  List<SubscriptionState> get subscriptions => [SubscriptionState(settings: chosen, displayName: 'Provider')];

  @override
  Future<CoreFailure?> saveSubscription(SubscriptionSettings next) async {
    saved.add(next.deepCopy());
    chosen = next;
    notifyListeners();
    return null;
  }

  void update(void Function() apply) {
    apply();
    notifyListeners();
  }

  @override
  Future<CoreFailure?> setDeviceIdentity({required bool enabled, bool regenerate = false}) async {
    changes.add((enabled, regenerate));
    deviceIdentity = DeviceIdentity(
      hwid: regenerate ? 'fedcba9876543210fedcba9876543210' : deviceIdentity!.hwid,
      enabled: enabled,
    );
    notifyListeners();
    return null;
  }
}

void main() {
  final s = SRu();
  late _DeviceSora sora;
  final clipboard = <String>[];

  Future<void> start(WidgetTester tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    sora = _DeviceSora(await Settings.load());
    addTearDown(sora.dispose);
    clipboard.clear();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard.add((call.arguments as Map)['text'] as String);
      return null;
    });
  }

  Widget screen(Widget child) => SoraScope(
    sora: sora,
    child: MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      theme: buildTheme(Brightness.light),
      home: child,
    ),
  );

  testWidgets('a core without the device identity shows none of it', (tester) async {
    await start(tester);
    await tester.pumpWidget(screen(const SubscriptionsScreen()));
    await tester.pumpAndSettle();
    expect(find.text(s.deviceIdentity), findsNothing);
    await tester.pumpWidget(screen(const SubscriptionScreen(id: 'sub')));
    await tester.pumpAndSettle();
    expect(find.text(s.deviceIdentity), findsNothing);
  });

  testWidgets('one subscription stops sending the identifier', (tester) async {
    await start(tester);
    sora.deviceIdentity = DeviceIdentity(hwid: '0123456789abcdef0123456789abcdef', enabled: true);
    await tester.pumpWidget(screen(const SubscriptionScreen(id: 'sub')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('subscription-device-identity-sub')));
    await tester.pumpAndSettle();
    expect(sora.saved.single.deviceIdentityOff, isTrue);
    expect(sora.saved.single.autoUpdate, isTrue, reason: 'the other settings stay');

    // With the identifier off everywhere the row shows it off and stays put.
    sora.update(() {
      sora.deviceIdentity = DeviceIdentity(hwid: '0123456789abcdef0123456789abcdef', enabled: false);
      sora.chosen = SubscriptionSettings(id: 'sub');
    });
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('subscription-device-identity-sub'));
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(sora.saved, hasLength(1));
  });

  testWidgets('the identifier copies, turns off everywhere and resets after a confirmation', (tester) async {
    await start(tester);
    sora.deviceIdentity = DeviceIdentity(hwid: '0123456789abcdef0123456789abcdef', enabled: true);
    await tester.pumpWidget(screen(const SubscriptionsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('0123456789abcdef0123456789abcdef'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('device-identity-value')));
    await tester.pump();
    expect(clipboard, ['0123456789abcdef0123456789abcdef']);
    expect(find.text(s.copied), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0123456789abcdef0123456789abcdef'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('device-identity')));
    await tester.pumpAndSettle();
    expect(sora.changes, [(false, false)]);

    await tester.tap(find.byKey(const ValueKey('device-identity-reset')));
    await tester.pumpAndSettle();
    expect(find.text(s.deviceIdentityResetConfirm), findsOneWidget);
    await tester.tap(find.text(s.resetAction).last);
    await tester.pumpAndSettle();
    expect(sora.changes.last, (false, true), reason: 'a reset keeps the switch where it was');
    expect(find.text('fedcba9876543210fedcba9876543210'), findsOneWidget);
  });

  test('a refused device reads as its cause only', () {
    expect(describe(s, const CoreFailure('core.subscription.device_limit')), 'Превышен лимит устройств');
    expect(
      describe(s, const CoreFailure('core.subscription.device_required')),
      'Провайдер требует идентификатор устройства',
    );
    for (final strings in S.supportedLocales.map(lookupS)) {
      for (final text in [strings.errSubDeviceLimit, strings.errSubDeviceRequired]) {
        expect(text.trim(), isNotEmpty);
        expect(RegExp(r'[.!。]\s*\S').hasMatch(text), isFalse, reason: 'one short cause: $text');
      }
    }
  });
}
