import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/generated/sora/custom/v1/custom.pb.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/addserver.dart';
import 'package:sora/src/ui/kit.dart';

class _FormSora extends Sora {
  _FormSora(super.settings, {required super.extensions});
  final saved = <CustomServer>[];
  @override
  Future<CoreFailure?> addCustomServer(CustomServer server, {bool replaceCredentials = false}) async {
    saved.add(server.deepCopy());
    return null;
  }
}

void main() {
  const protocols = [
    'vless',
    'vmess',
    'trojan',
    'shadowsocks',
    'wireguard',
    'socks5',
    'http',
    'hysteria2',
    'tuic',
    'anytls',
    'mieru',
    'naive',
  ];
  final key = base64.encode(List.filled(32, 1));
  const uuid = '00000000-0000-4000-8000-000000000001';
  late Directory work;
  late _FormSora sora;
  final capture = GlobalKey();
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    work = await Directory.systemTemp.createTemp('sora-protocol-ui-');
    sora = _FormSora(await Settings.load(), extensions: ExtensionStore(dir: work.path))..customProtocols = protocols;
  });
  tearDown(() async {
    sora.dispose();
    await work.delete(recursive: true);
  });
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader('Noto Sans Arabic')..addFont(rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'))).load();
    await (FontLoader('Inter')..addFont(rootBundle.load('assets/fonts/InterVariable.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'packages/material_symbols_icons/MaterialSymbolsRounded',
    )..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf'))).load();
  });
  Future<void> mount(
    WidgetTester tester, {
    CustomServer? editing,
    double width = 1000,
    double scale = 1,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('ru'),
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
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(brightness),
              locale: locale,
              localizationsDelegates: S.localizationsDelegates,
              supportedLocales: S.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showAddServerSheet(context, server: editing),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  Future<void> choose(WidgetTester tester, String key, String value) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, value));
    await tester.pumpAndSettle();
  }

  Future<void> field(WidgetTester tester, String key, String value) async {
    final finder = find.byKey(ValueKey('custom-$key'));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

  Future<void> common(WidgetTester tester) async {
    await field(tester, 'name', 'Work');
    await field(tester, 'address', 'vpn.example.com');
    await field(tester, 'port', '443');
  }

  Future<void> options(WidgetTester tester, String protocol) async {
    final finder = find.byKey(ValueKey('custom-options-$protocol'));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final finder = find.byKey(const ValueKey('custom-save'));
    expect(tester.widget<PrimaryButton>(finder).onTap, isNotNull);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    if (Platform.environment['SORA_SHOTS'] == null) return;
    final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final dir = Directory('${Platform.environment['HOME']}/.local/share/sora-dev/shots/protocol-forms');
      await dir.create(recursive: true);
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${dir.path}/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final protocol in protocols) {
    testWidgets('$protocol exposes its own fields and saves the protocol credential document', (tester) async {
      await mount(tester);
      if (protocol != 'vless') await choose(tester, 'custom-protocol', protocol.toUpperCase());
      await common(tester);
      if (protocol == 'wireguard') {
        expect(find.byKey(const ValueKey('custom-peerKey')), findsNothing);
        await field(tester, 'credentials', key);
        await field(tester, 'addresses', '10.0.0.2/32');
        expect(tester.widget<PrimaryButton>(find.byKey(const ValueKey('custom-save'))).label, 'Далее');
        await shot(tester, 'wireguard-interface');
        await save(tester);
        expect(find.byKey(const ValueKey('custom-credentials')), findsNothing);
        await field(tester, 'peerKey', key);
        await field(tester, 'allowedIps', '0.0.0.0/0, ::/0');
        await shot(tester, 'wireguard-peer');
      } else {
        expect(find.byKey(const ValueKey('custom-peerKey')), findsNothing);
        if (['socks5', 'http', 'mieru', 'naive'].contains(protocol)) await field(tester, 'user', 'user');
        if (protocol == 'shadowsocks') await field(tester, 'method', 'aes-256-gcm');
        if (protocol == 'tuic') await field(tester, 'password', 'second-secret');
        await field(tester, 'credentials', ['vless', 'vmess', 'tuic'].contains(protocol) ? uuid : 'secret');
      }
      await save(tester);
      final saved = sora.saved.single;
      final values = jsonDecode(saved.credentials) as Map<String, dynamic>;
      expect(saved.protocolName, protocol);
      expect(saved.address, 'vpn.example.com');
      expect(saved.port, 443);
      expect(
        saved.security,
        ['shadowsocks', 'wireguard', 'socks5', 'http', 'mieru'].contains(protocol) ? 'none' : 'tls',
      );
      if (protocol == 'wireguard') {
        expect(values['private_key'], key);
        expect(values['addresses'], '10.0.0.2/32');
        expect(((jsonDecode(values['peers'] as String) as List).single as Map<String, dynamic>)['PublicKey'], key);
      } else if (['vless', 'vmess', 'tuic'].contains(protocol)) {
        expect(values['uuid'], uuid);
        if (protocol == 'tuic') expect(values['password'], 'second-secret');
      } else {
        expect(values['password'], 'secret');
      }
      if (protocol == 'shadowsocks') expect(values['method'], 'aes-256-gcm');
      if (protocol == 'mieru') expect(jsonDecode(values['mieru'] as String), {'PortRange': ''});
      if (protocol == 'naive') expect(jsonDecode(values['naive'] as String), {'QUIC': false});
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('VLESS REALITY and gRPC show relevant fields and bind them to the saved document', (tester) async {
    await mount(tester);
    await common(tester);
    await field(tester, 'credentials', uuid);
    await options(tester, 'vless');
    await choose(tester, 'custom-security', 'REALITY');
    expect(tester.widget<PrimaryButton>(find.byKey(const ValueKey('custom-save'))).onTap, isNull);
    await field(tester, 'public_key', key);
    await field(tester, 'short_id', 'deadbeef');
    await field(tester, 'server_name', 'sni.example.com');
    await choose(tester, 'custom-transport', 'GRPC');
    expect(find.byKey(const ValueKey('custom-path')), findsNothing);
    await field(tester, 'service_name', 'service');
    await save(tester);
    final saved = sora.saved.single, values = jsonDecode(sora.saved.single.credentials) as Map<String, dynamic>;
    expect(saved.security, 'reality');
    expect(saved.transport, 'grpc');
    expect(values['security'], 'reality');
    expect(values['server_name'], 'sni.example.com');
    expect(values['public_key'], key);
    expect(values['service_name'], 'service');
    expect(values['flow'], '');
  });

  testWidgets('editing write-only Naive options preserves the native document and stored password', (tester) async {
    await mount(
      tester,
      editing: CustomServer(
        id: 'stored',
        protocolName: 'naive',
        name: 'Work',
        address: 'vpn.example.com',
        port: 443,
        security: 'tls',
        transport: 'udp',
      ),
    );
    await options(tester, 'naive');
    expect(find.byKey(const ValueKey('custom-transport')), findsNothing);
    expect(find.byKey(const ValueKey('custom-fingerprint')), findsNothing);
    await field(tester, 'server_name', 'new-sni.example.com');
    await save(tester);
    expect(jsonDecode(sora.saved.single.credentials), {'server_name': 'new-sni.example.com'});
    expect(sora.saved.single.transport, 'udp');
  });

  testWidgets('protocol form remains usable at 320 pixels and large text', (tester) async {
    await mount(tester, width: 320, scale: 1.6, brightness: Brightness.dark);
    await common(tester);
    await field(tester, 'credentials', uuid);
    await shot(tester, 'vless-dark-320');
    await options(tester, 'vless');
    await choose(tester, 'custom-transport', 'WS');
    await field(tester, 'path', '/socket');
    await field(tester, 'host_header', 'web.example.com');
    await save(tester);
    final values = jsonDecode(sora.saved.single.credentials) as Map<String, dynamic>;
    expect(values['path'], '/socket');
    expect(values['host_header'], 'web.example.com');
    expect(tester.takeException(), isNull);
  });
  testWidgets('connection settings expose fields without help', (tester) async {
    await mount(tester);
    final group = find.byKey(const ValueKey('custom-options-vless'));
    await tester.ensureVisible(group);
    expect(find.byType(InfoButton), findsNothing);
    expect(find.byKey(const ValueKey('custom-server_name')), findsNothing);
    await tester.tap(group);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('custom-server_name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hysteria2 keeps the exact Salamander password including surrounding whitespace', (tester) async {
    await mount(tester);
    await choose(tester, 'custom-protocol', 'HYSTERIA2');
    await common(tester);
    await field(tester, 'credentials', 'secret');
    await options(tester, 'hysteria2');
    await field(tester, 'obfs_param', ' obfs secret ');
    await save(tester);
    final values = jsonDecode(sora.saved.single.credentials) as Map<String, dynamic>;
    expect(values['obfs'], 'salamander');
    expect(values['obfs_param'], ' obfs secret ');
  });
  testWidgets('WireGuard keeps its two-step flow usable with RTL and large type', (tester) async {
    await mount(tester, width: 320, scale: 1.6, locale: const Locale('ar'));
    await choose(tester, 'custom-protocol', 'WIREGUARD');
    await common(tester);
    await field(tester, 'credentials', key);
    await field(tester, 'addresses', '10.0.0.2/32');
    await save(tester);
    await field(tester, 'peerKey', key);
    await field(tester, 'allowedIps', '0.0.0.0/0');
    expect(find.byKey(const ValueKey('custom-presharedKey')), findsNothing);
    final tabs = find.byKey(const ValueKey('custom-wg-section'));
    final indicator = tester.getRect(find.descendant(of: tabs, matching: find.byType(FractionallySizedBox)));
    expect(indicator.contains(tester.getCenter(find.text(lookupS(const Locale('ar')).customServerWgPeer))), isTrue);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('custom-peerKey'))).textDirection, TextDirection.ltr);
    await shot(tester, 'wireguard-rtl-320');
    await save(tester);
    expect(sora.saved.single.protocolName, 'wireguard');
    expect(tester.takeException(), isNull);
  });
}
