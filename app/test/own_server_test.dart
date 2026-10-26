import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/generated/sora/custom/v1/custom.pbgrpc.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/addserver.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/servers.dart';

void main() {
  final binary = Platform.environment['SORA_CORE_BIN'];
  final live = binary != null && Platform.environment['SORA_CORE_SOCKET'] != null;
  late Directory work;
  Process? core;
  CoreLink? link;
  String clipboard = '';

  setUpAll(() async {
    work = await Directory.systemTemp.createTemp('sora-own-');
    if (!live) return;
    core = await Process.start(binary, [
      '-socket',
      CoreLink.socketPath,
      '-data-dir',
      '${work.path}/data',
      '-engines-dir',
      '${work.path}/engines',
      '-allow-file-keys',
    ]);
    unawaited(core!.stdout.drain<void>());
    unawaited(core!.stderr.drain<void>());
    link = await CoreLink.open().timeout(const Duration(seconds: 20));
  });
  tearDownAll(() async {
    await link?.close();
    core?.kill();
    await core?.exitCode;
    await work.delete(recursive: true);
  });
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData' ? {'text': clipboard} : null,
    );
  });

  Future<Sora> mount(WidgetTester tester, {bool connect = false, double width = 800}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    settings
      ..language = 'en'
      ..animations = false;
    final sora = Sora(settings, extensions: ExtensionStore(dir: '${work.path}/extensions'));
    Future<void>? running;
    if (connect) {
      await tester.runAsync(() async {
        final listed = await link!.custom.listCustomServers(
          ListCustomServersRequest(apiVersion: apiVersion, controlAuthenticator: link!.token),
        );
        for (final server in listed.servers) {
          await link!.custom.deleteCustomServer(
            DeleteCustomServerRequest(apiVersion: apiVersion, controlAuthenticator: link!.token, id: server.id),
          );
        }
        running = sora.run();
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (!sora.coreHandshakeDone) {
          if (DateTime.now().isAfter(deadline)) fail('Core handshake timed out');
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await sora.loadCustomServers();
      });
    }
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('en'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: const ServersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        sora.dispose();
        await running?.timeout(const Duration(seconds: 10));
      });
    });
    return sora;
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('add-own-server')));
    await tester.pumpAndSettle();
    expect(find.byType(AddServerScreen), findsOneWidget);
  }

  Future<void> settleIo(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  String value(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.byKey(ValueKey('custom-$key'))).controller!.text;
  bool saveEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byKey(const ValueKey('custom-save'))).onTap != null;

  testWidgets('empty own servers have one compact add action and no group', (tester) async {
    await mount(tester);
    expect(find.byKey(const ValueKey('own-servers-group')), findsNothing);
    expect(find.text('My servers'), findsNothing);
    expect(find.byKey(const ValueKey('add-own-server')), findsOneWidget);
    expect(find.byTooltip('Add custom server'), findsOneWidget);
    await open(tester);
    expect(tester.getSize(find.byKey(const ValueKey('custom-server-sheet'))).width, 520);
    expect(saveEnabled(tester), isFalse);
    await tester.tap(find.bySemanticsLabel('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AddServerScreen), findsNothing);
  });

  testWidgets('field borders validate without inline errors and Esc closes with field focus', (tester) async {
    await mount(tester, width: 420);
    await open(tester);
    expect(tester.getSize(find.byKey(const ValueKey('custom-server-sheet'))).width, 388);
    for (final entry in {'name': 'Home', 'address': 'bad address', 'port': '70000', 'credentials': 'secret'}.entries) {
      await tester.enterText(find.byKey(ValueKey('custom-${entry.key}')), entry.value);
    }
    await tester.pumpAndSettle();
    expect(find.text('Invalid address'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('custom-address')))
          .decoration!
          .enabledBorder!
          .borderSide
          .color,
      Palette.light.danger,
    );
    expect(find.text('Port must be a number from 1 to 65535'), findsNothing);
    expect(
      tester.widget<TextField>(find.byKey(const ValueKey('custom-port'))).decoration!.enabledBorder!.borderSide.color,
      Palette.light.danger,
    );
    expect(saveEnabled(tester), isFalse);
    await tester.enterText(find.byKey(const ValueKey('custom-address')), 'vpn.example.com');
    await tester.enterText(find.byKey(const ValueKey('custom-port')), '443');
    await tester.pumpAndSettle();
    expect(saveEnabled(tester), isTrue);
    await tester.enterText(find.byKey(const ValueKey('custom-name')), '');
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsNothing);
    expect(saveEnabled(tester), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AddServerScreen), findsNothing);
  });

  testWidgets('WireGuard and Shadowsocks fields follow protocol with field errors', (tester) async {
    await mount(tester);
    await open(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('custom-protocol')));
    await tester.tap(find.byKey(const ValueKey('custom-protocol')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WIREGUARD'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('custom-addresses')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('custom-credentials')), 'short');
    await tester.pumpAndSettle();
    expect(find.text('The key must be 32 bytes of base64, as wg genkey prints.'), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('custom-protocol')));
    expect(saveEnabled(tester), isFalse);
    await tester.ensureVisible(find.byKey(const ValueKey('custom-protocol')));
    await tester.tap(find.byKey(const ValueKey('custom-protocol')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SHADOWSOCKS'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('custom-addresses')), findsNothing);
    expect(find.byKey(const ValueKey('custom-method')), findsOneWidget);
  });

  testWidgets('pasted links fill every supported protocol through the real parser', (tester) async {
    final sora = await mount(tester, connect: true);
    final fixtures =
        jsonDecode((await tester.runAsync(() => File('../core/parser/testdata/imports.json').readAsString()))!) as List;
    final names = [
      'vless',
      'vmess url',
      'vmess base64',
      'trojan',
      'shadowsocks',
      'hysteria2',
      'hy2',
      'tuic',
      'socks',
      'socks5',
      'https',
      'wireguard url',
      'wg url',
    ];
    for (final name in names) {
      final fixture = fixtures.cast<Map<String, dynamic>>().firstWhere((f) => f['name'] == name);
      await open(tester);
      clipboard = fixture['input'] as String;
      await tester.ensureVisible(find.byKey(const ValueKey('custom-paste')));
      await tester.ensureVisible(find.byKey(const ValueKey('custom-paste')));
      await tester.tap(find.byKey(const ValueKey('custom-paste')));
      await settleIo(tester);
      expect(
        value(tester, 'address'),
        fixture['protocol'] == 'wireguard' ? '198.51.100.7' : 'example.com',
        reason: name,
      );
      expect(find.text((fixture['protocol'] as String).toUpperCase()), findsOneWidget, reason: name);
      if (name == 'trojan' || name == 'hysteria2' || name == 'hy2') expect(value(tester, 'credentials'), 'secret');
      if (name == 'shadowsocks') {
        expect(value(tester, 'method'), 'aes-256-gcm');
        expect(value(tester, 'credentials'), 'pass');
      }
      if (name == 'tuic') expect(value(tester, 'password'), 'pass');
      if (name == 'socks') expect(value(tester, 'user'), 'user');
      if (fixture['protocol'] == 'wireguard') {
        expect(value(tester, 'addresses'), '10.7.0.2/32');
        await tester.ensureVisible(find.byKey(const ValueKey('custom-wg-section')));
        await tester.tap(find.text('Peer'));
        await tester.pumpAndSettle();
        expect(value(tester, 'peerKey'), 'Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw=');
      }
      expect(saveEnabled(tester), isTrue, reason: name);
      await tester.tap(find.byKey(const ValueKey('custom-save')));
      await tester.pump();
      expect(saveEnabled(tester), isFalse);
      expect(tester.widget<TextField>(find.byKey(const ValueKey('custom-name'))).enabled, isFalse);
      await settleIo(tester);
      expect(find.byType(AddServerScreen), findsNothing, reason: name);
      expect(sora.customServers.last.credentials, isEmpty);
      expect(sora.servers.map((o) => o.id), contains('custom/${sora.customServers.last.id}'));
    }
    expect(sora.customServers.length, names.length);
    expect(sora.subscriptions, isEmpty);
    expect(find.byKey(const ValueKey('own-servers-group')), findsOneWidget);
  }, skip: !live);

  testWidgets('edit keeps the id, order and write-only secret, invalid paste keeps the draft', (tester) async {
    final sora = await mount(tester, connect: true);
    await open(tester);
    clipboard = 'vless://123e4567-e89b-12d3-a456-426614174000@example.com:443?security=tls&type=ws&path=%2Fvpn#Home';
    await tester.ensureVisible(find.byKey(const ValueKey('custom-paste')));
    await tester.tap(find.byKey(const ValueKey('custom-paste')));
    await settleIo(tester);
    final draftName = value(tester, 'name');
    clipboard = 'not a link';
    await tester.ensureVisible(find.byKey(const ValueKey('custom-paste')));
    await tester.tap(find.byKey(const ValueKey('custom-paste')));
    await settleIo(tester);
    expect(value(tester, 'name'), draftName);
    expect(find.text('Invalid server link'), findsNothing);
    expect(sora.history.first.body, 'Invalid server link');
    await tester.tap(find.byKey(const ValueKey('custom-save')));
    await settleIo(tester);
    final id = sora.customServers.single.id;
    await open(tester);
    clipboard = 'trojan://second-secret@example.com:8443#Second';
    await tester.ensureVisible(find.byKey(const ValueKey('custom-paste')));
    await tester.tap(find.byKey(const ValueKey('custom-paste')));
    await settleIo(tester);
    await tester.tap(find.byKey(const ValueKey('custom-save')));
    await settleIo(tester);
    final order = sora.customServers.map((server) => server.id).toList();
    await tester.tap(find.byKey(ValueKey('edit-own-server-$id')));
    await tester.pumpAndSettle();
    expect(value(tester, 'name'), draftName);
    expect(value(tester, 'credentials'), isEmpty);
    expect(saveEnabled(tester), isTrue);
    await tester.enterText(find.byKey(const ValueKey('custom-name')), 'Updated');
    await tester.tap(find.byKey(const ValueKey('custom-save')));
    await settleIo(tester);
    expect(sora.customServers.map((server) => server.id), order);
    expect(sora.customServers.first.name, 'Updated');
    expect(sora.customServers.first.hasCredentials_7, isTrue);
    expect(sora.customServers.last.name, 'Second');
    await tester.runAsync(sora.loadCustomServers);
    await settleIo(tester);
    expect(sora.customServers.map((server) => server.id), order);
    expect(sora.customServers.first.name, 'Updated');
    expect(sora.customServers.first.credentials, isEmpty);
  }, skip: !live);
}
