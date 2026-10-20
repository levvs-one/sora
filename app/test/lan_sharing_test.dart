import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

import 'fixtures/desktop_state.dart';

/// C7: LAN sharing of the connection. The switch lives in Settings, the
/// password is generated once and stored with it, and buildPlan carries
/// the credentials only for a TUN plan with sharing on.
void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  final servers = [
    OutboundSpec(id: 'a', displayName: 'A', protocol: 'vless'),
    OutboundSpec(id: 'b', displayName: 'B', protocol: 'shadowsocks'),
  ];

  group('settings LAN sharing', () {
    test('sharing is off by default and the password is generated once, at least 16 characters', () async {
      final settings = await Settings.load();
      expect(settings.allowLanSharing, isFalse);
      expect(settings.lanProxyPassword.length, greaterThanOrEqualTo(16));
      expect(Settings.lanProxyUsername, 'sora');
      final password = settings.lanProxyPassword;
      await Future<void>.delayed(Duration.zero);
      final reloaded = await Settings.load();
      expect(reloaded.lanProxyPassword, password, reason: 'the password survives a fresh Settings over the same store');
    });

    test('the switch round-trips across a fresh Settings', () async {
      final settings = await Settings.load();
      settings.allowLanSharing = true;
      await Future<void>.delayed(Duration.zero);
      final reloaded = await Settings.load();
      expect(reloaded.allowLanSharing, isTrue);
      expect(reloaded.lanProxyPassword, settings.lanProxyPassword);
    });

    test('sharing and its password stay out of the syncable settings document', () async {
      final settings = await Settings.load();
      settings.allowLanSharing = true;
      await Future<void>.delayed(Duration.zero);
      final doc = settings.exportSyncableSettings();
      expect(doc.keys, isNot(contains('allowLanSharing')));
      expect(doc.keys, isNot(contains('lanProxyPassword')));
    });
  });

  group('buildPlan LAN sharing', () {
    late Settings settings;
    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      settings = await Settings.load();
    });

    test('off keeps the plan without a LocalProxy, exactly as before', () {
      final plan = buildPlan(servers: servers, choice: 'a', settings: settings);
      expect(plan.hasLocalProxy(), isFalse);
    });

    test('on in TUN mode carries the locked LAN listener', () {
      settings.allowLanSharing = true;
      final plan = buildPlan(servers: servers, choice: 'a', settings: settings);
      expect(plan.hasLocalProxy(), isTrue);
      expect(plan.localProxy.enabled, isTrue);
      expect(plan.localProxy.allowLan, isTrue);
      expect(plan.localProxy.username, Settings.lanProxyUsername);
      expect(plan.localProxy.password, settings.lanProxyPassword);
      expect(plan.localProxy.password.length, greaterThanOrEqualTo(16));
    });

    test('on in the system proxy mode carries nothing: that listener cannot take a login', () {
      settings
        ..allowLanSharing = true
        ..tunnel = 'proxy';
      final plan = buildPlan(servers: servers, choice: 'a', settings: settings);
      expect(plan.hasLocalProxy(), isFalse);
    });

    test('the serverless bypass session has no connection to share', () {
      settings.allowLanSharing = true;
      final plan = buildPlan(servers: servers, choice: 'bypass', settings: settings);
      expect(plan.hasLocalProxy(), isFalse);
    });
  });

  testWidgets('the modes panel switch turns sharing on and reveals the credentials', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings
      ..language = 'en'
      ..animations = false;
    final sora = DesktopState(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    await tester.tap(find.byKey(const ValueKey('mode-button')));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('allow-lan-sharing'));
    expect(toggle, findsOneWidget);
    expect(find.byKey(const ValueKey('lan-sharing-password')), findsNothing);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.allowLanSharing, isTrue);
    expect((await Settings.load()).allowLanSharing, isTrue);
    final password = tester.widget<SelectableText>(find.byKey(const ValueKey('lan-sharing-password')));
    expect(password.data, settings.lanProxyPassword);
    final login = tester.widget<SelectableText>(find.byKey(const ValueKey('lan-sharing-login')));
    expect(login.data, Settings.lanProxyUsername);
    expect(tester.takeException(), isNull);
  });
}
