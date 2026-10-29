// Requires SORA_TUNNEL_LIVE to identify a local Windows VLESS server, as
// configured after installation in CI. Its access log verifies real traffic
// through both the tunnel and system proxy.
import 'dart:io';

import 'package:flutter/widgets.dart' show SizedBox, ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/desktop/system_proxy.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

// The import comes from the installed core's parser and encrypted credential
// store; the UI can exercise reset without creating a provider subscription.
class _ImportedSora extends Sora {
  _ImportedSora(super.settings, this.source);

  final List<OutboundSpec> source;

  @override
  List<OutboundSpec> get servers => source;
}

void main() {
  final server = Platform.environment['SORA_TUNNEL_LIVE'];
  final log = Platform.environment['SORA_TUNNEL_LOG'] ?? '';
  final skip = server == null ? 'set SORA_TUNNEL_LIVE to a vless:// link of a local server' : false;

  late CoreLink link;
  late SessionPlan imported;

  setUpAll(() async {
    if (server == null) return;
    link = await CoreLink.open().timeout(const Duration(seconds: 30));
    final answer = await link.stub.parseImport(ParseImportRequest(apiVersion: apiVersion, payload: server.codeUnits));
    expect(answer.hasError(), isFalse, reason: answer.error.detailRedacted);
    imported = answer.sessionPlan;
  });

  tearDownAll(() async {
    if (server != null) await link.close();
  });

  /// Connects the imported server in [mode] and returns time to connected
  /// state.
  Future<Duration> connect(TunnelMode mode, {bool killSwitch = false, String? engine, String? stack}) async {
    final out = imported.outbounds.single;
    final plan = SessionPlan(
      tunnelMode: mode,
      outbounds: [out],
      engines: engine == null ? [] : [engine],
      tunStack: stack,
      // Route the local server process directly to avoid looping its outbound
      // traffic back through its own tunnel.
      routes: [RoutingRule(destination: 'process:xray.exe', outboundId: 'direct')],
      routing: RoutingOptions(preset: 'global', proxyTarget: out.id),
    );
    final clock = Stopwatch()..start();
    final answer = await link.stub.connect(
      ConnectRequest(
        apiVersion: apiVersion,
        sessionPlan: plan,
        controlAuthenticator: link.token,
        killSwitch: killSwitch,
      ),
    );
    expect(answer.hasError(), isFalse, reason: '${answer.error.userMessageKey} ${answer.error.detailRedacted}');
    for (var i = 0; i < 300; i++) {
      final status = await link.stub.getStatus(GetStatusRequest(apiVersion: apiVersion));
      final value = status.status.connection.value;
      if (value == ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED) return clock.elapsed;
      expect(value, isNot(ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    fail('the session did not come up in 30 seconds');
  }

  Future<void> disconnect() async {
    await link.stub.disconnect(DisconnectRequest(apiVersion: apiVersion, controlAuthenticator: link.token));
  }

  /// Checks whether the access log contains [host], polling for delayed writes.
  Future<bool> serverSaw(String host) async {
    for (var i = 0; i < 20; i++) {
      if (File(log).existsSync() && File(log).readAsStringSync().contains(host)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  Future<String> fetch(String url) async {
    final curl = await Process.run('curl.exe', ['-s', '-o', 'NUL', '-m', '20', '-w', '%{http_code}', url]);
    return '${curl.stdout}${curl.stderr}';
  }

  for (final stack in ['gvisor', 'system', 'mixed', 'mips']) {
    test(
      'Xray carries a real Windows request through the $stack TUN stack',
      () async {
        await connect(TunnelMode.TUNNEL_MODE_SYSTEM, engine: 'xray', stack: stack);
        try {
          expect(await fetch('https://example.com/'), '200');
          expect(await serverSaw('example.com'), isTrue);
        } finally {
          await disconnect();
        }
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }

  for (final initiallyConnected in [false, true]) {
    testWidgets(
      'installed Windows service accepts the orb after reset while ${initiallyConnected ? "connected" : "disconnected"}',
      (tester) async {
        SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
        final settings = await Settings.load();
        await settings.completeTour();
        settings
          ..animations = false
          ..rules = ['direct process:xray.exe'];
        final sora = _ImportedSora(settings, imported.outbounds);
        late Future<void> running;
        Future<void> until(Phase expected) async {
          final limit = DateTime.now().add(const Duration(seconds: 30));
          while (sora.phase != expected) {
            if (DateTime.now().isAfter(limit)) fail('expected $expected, got ${sora.phase}, ${sora.failure}');
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        try {
          await tester.runAsync(() async {
            running = sora.run();
            final limit = DateTime.now().add(const Duration(seconds: 30));
            while (sora.link == null || sora.phase != Phase.off) {
              if (DateTime.now().isAfter(limit)) fail('the installed service did not answer');
              await Future<void>.delayed(const Duration(milliseconds: 50));
            }
            if (initiallyConnected) await sora.connect();
          });
          if (initiallyConnected) await until(Phase.connected);
          await tester.pumpWidget(SoraApp(sora: sora));
          await tester.pump();
          await tester.runAsync(sora.reset);
          await tester.pump(const Duration(milliseconds: 250));
          final orb = find.byKey(const ValueKey('connect-control'));
          expect(orb, findsOneWidget);
          await tester.runAsync(() => tester.tap(orb));
          await until(initiallyConnected ? Phase.off : Phase.connected);
          expect(settings.tourDone, isTrue);
          if (initiallyConnected) {
            await tester.runAsync(() => tester.tap(orb));
            await until(Phase.connected);
          }
          expect(tester.takeException(), isNull);
        } finally {
          await tester.runAsync(sora.disconnect);
          await tester.pumpWidget(const SizedBox());
          // Unmounting dismisses visible toasts; toastification always
          // schedules its overlay cleanup, which must elapse before the test ends.
          await tester.pump(const Duration(seconds: 1));
          sora.dispose();
          await tester.runAsync(() => running.timeout(const Duration(seconds: 10)));
        }
      },
      skip: server == null,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }

  test(
    'the tunnel carries a program that knows nothing about proxies',
    () async {
      final took = await connect(TunnelMode.TUNNEL_MODE_SYSTEM);
      // ignore: avoid_print
      print('tunnel connected in ${took.inMilliseconds} ms');
      try {
        final curl = await Process.run('curl.exe', [
          '-s',
          '-o',
          'NUL',
          '-m',
          '20',
          '-w',
          '%{http_code}',
          'https://example.com/',
        ]);
        expect(curl.stdout, '200', reason: 'curl: ${curl.stderr}');
        expect(
          await serverSaw('example.com'),
          isTrue,
          reason: 'the server never saw the request: it went around the tunnel',
        );
      } finally {
        await disconnect();
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a kill switch armed with Connect lets the tunnel through and leaves with the session',
    () async {
      await connect(TunnelMode.TUNNEL_MODE_SYSTEM, killSwitch: true);
      try {
        expect(await fetch('https://example.net/'), '200');
        expect(await serverSaw('example.net'), isTrue, reason: 'the request went around the tunnel');
      } finally {
        await disconnect();
      }
      expect(await fetch('https://www.example.com/'), '200', reason: 'the block outlived the session');
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'the system proxy carries the programs that honour it, and is put back after',
    () async {
      final about = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
      expect(about.about.hasLocalProxy(), isTrue);
      final local = about.about.localProxy;
      final proxy = SystemProxy.forThisDesktop()!;
      Future<String> setting() async =>
          (await Process.run('reg', [
                'query',
                r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
                '/v',
                'ProxyEnable',
              ])).stdout
              as String;
      final before = await setting();

      final took = await connect(TunnelMode.TUNNEL_MODE_APPLICATION);
      // ignore: avoid_print
      print('proxy mode connected in ${took.inMilliseconds} ms');
      final saved = await proxy.read();
      await proxy.point(local.host, local.port);
      try {
        expect(await setting(), contains('0x1'));
        expect(await proxy.pointsAt(local.host, local.port), isTrue);
        // PowerShell's .NET request uses WinINet system proxy settings, like
        // browsers.
        final web = await Process.run('powershell.exe', [
          '-NoProfile',
          '-Command',
          '(Invoke-WebRequest -UseBasicParsing -TimeoutSec 20 https://example.org/).StatusCode',
        ]);
        expect((web.stdout as String).trim(), '200', reason: 'Invoke-WebRequest: ${web.stderr}');
        expect(
          await serverSaw('example.org'),
          isTrue,
          reason: 'the server never saw the request: the proxy was not used',
        );
      } finally {
        await proxy.restore(saved);
        await disconnect();
      }
      expect(await setting(), before, reason: 'the system proxy was not put back as it was');
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
