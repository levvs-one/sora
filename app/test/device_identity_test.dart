// Widget/unit tests for the device identity section (C1, contract
// 1.13) on the subscriptions screen: the section renders the identity
// from GetDeviceIdentity, loading it fires exactly one background
// companion sync (Set with the loaded enabled value, reset=false),
// the toggle calls SetDeviceIdentity with the new value (and
// reset=false), and the reset action confirms first, then calls Set
// with reset=true and shows the NEW hwid the core answered with. The
// core is faked by overriding the two Sora methods — the
// DesktopState pattern used across the app tests.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/subscription.dart';

import 'fixtures/desktop_state.dart';

class _DeviceSora extends DesktopState {
  _DeviceSora(super.settings);

  static const firstHwid = '123e4567-e89b-42d3-a456-426614174000';
  static const resetHwid = '223e4567-e89b-42d3-a456-426614174001';

  ({String hwid, bool enabled}) identity = (hwid: firstHwid, enabled: true);
  final calls = <({bool enabled, bool reset, String verOs, String deviceModel})>[];
  int gets = 0;

  @override
  Future<({String hwid, bool enabled})?> getDeviceIdentity() async {
    gets++;
    return identity;
  }

  @override
  Future<({String hwid, bool enabled})?> setDeviceIdentity({required bool enabled, bool reset = false}) async {
    // Mirrors the wire companions the real Sora.setDeviceIdentity
    // builds into every SetDeviceIdentityRequest (verOs:
    // deviceVerOs(), deviceModel: ''), so tests can pin them.
    calls.add((enabled: enabled, reset: reset, verOs: deviceVerOs(), deviceModel: ''));
    identity = (hwid: reset ? resetHwid : identity.hwid, enabled: enabled);
    return identity;
  }
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  Future<_DeviceSora> start(WidgetTester tester, {bool initialEnabled = true}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 900);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.animations = false;
    final sora = _DeviceSora(settings)..identity = (hwid: _DeviceSora.firstHwid, enabled: initialEnabled);
    addTearDown(sora.dispose);
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: const SubscriptionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
    return sora;
  }

  testWidgets('section shows the identity from Get and the toggle calls Set with the new value', (tester) async {
    final sora = await start(tester);
    expect(sora.gets, 1);
    expect(find.text('Device identity'), findsOneWidget);
    expect(find.text(_DeviceSora.firstHwid), findsOneWidget);
    expect(find.text('Send device identifier to subscription providers'), findsOneWidget);
    // Loading the section already fired its one companion sync.
    expect(sora.calls, [(enabled: true, reset: false, verOs: deviceVerOs(), deviceModel: '')]);

    await tester.tap(find.text('Send device identifier to subscription providers'));
    await tester.pumpAndSettle();
    expect(sora.calls, [
      (enabled: true, reset: false, verOs: deviceVerOs(), deviceModel: ''),
      (enabled: false, reset: false, verOs: deviceVerOs(), deviceModel: ''),
    ]);
    expect(sora.identity.enabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading the section syncs companions once with the loaded enabled value and keeps the HWID', (
    tester,
  ) async {
    // A disabled identity is the telling case: the sync must carry
    // the value Get returned (false), not any default.
    final sora = await start(tester, initialEnabled: false);
    expect(sora.gets, 1);
    expect(sora.calls, [(enabled: false, reset: false, verOs: deviceVerOs(), deviceModel: '')]);
    expect(sora.identity, (hwid: _DeviceSora.firstHwid, enabled: false));
    expect(find.text(_DeviceSora.firstHwid), findsOneWidget);
    expect(find.text(_DeviceSora.resetHwid), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset confirms with the new-device warning, then calls Set with reset=true', (tester) async {
    final sora = await start(tester);
    await tester.tap(find.text('Reset identifier'));
    await tester.pumpAndSettle();
    // The confirmation carries the warning that the provider counts a
    // reset as a new device; nothing beyond the load sync is sent
    // before it is accepted.
    expect(find.textContaining('count this as a new device'), findsOneWidget);
    expect(sora.calls, [(enabled: true, reset: false, verOs: deviceVerOs(), deviceModel: '')]);

    final actions = find.text('Reset identifier');
    expect(actions, findsNWidgets(2)); // the row and the dialog action
    await tester.tap(actions.last);
    await tester.pumpAndSettle();
    expect(sora.calls, [
      (enabled: true, reset: false, verOs: deviceVerOs(), deviceModel: ''),
      (enabled: true, reset: true, verOs: deviceVerOs(), deviceModel: ''),
    ]);
    expect(find.text(_DeviceSora.resetHwid), findsOneWidget);
    expect(find.text(_DeviceSora.firstHwid), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('deviceVerOs is header-shaped: printable ASCII, at most 128 characters', () {
    final value = deviceVerOs();
    expect(value.length, lessThanOrEqualTo(128));
    expect(value.codeUnits.every((c) => c >= 0x20 && c <= 0x7e), isTrue, reason: value);
  });
}
