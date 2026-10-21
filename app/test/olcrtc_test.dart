import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings_en.dart';
import 'package:sora/l10n/strings_ru.dart';
import 'package:sora/main.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/desktop/links.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/kit.dart';
import 'package:sora/src/ui/servers.dart';

/// A Sora whose only subscription carries one olcrtc server, the shape the
/// core streams after an olcrtc link or subscription import.
class _OlcrtcState extends Sora {
  _OlcrtcState(super.settings) {
    phase = Phase.connected;
  }

  final subscription = SubscriptionState(
    settings: SubscriptionSettings(id: 'olc', name: 'OpenLibre', autoUpdate: true),
    displayName: 'OpenLibre',
    outbounds: [
      OutboundSpec(
        id: 'olc-ru-1',
        displayName: 'RU-1',
        protocol: 'olcrtc',
        transport: 'datachannel',
        security: 'olc2',
        endpoint: Endpoint(host: 'room-01', port: 0),
      ),
      OutboundSpec(id: 'olc-nl-1', displayName: 'NL-1', protocol: 'vless', transport: 'tcp', security: 'tls'),
    ],
  );

  @override
  List<SubscriptionState> get subscriptions => [subscription];
  @override
  List<OutboundSpec> get servers => subscription.outbounds;
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('every olcrtc core failure has its own localized words', () {
    for (final s in [SRu(), SEn()]) {
      final expected = <String, String>{
        'core.olcrtc.invalid': s.errOlcrtcInvalid,
        'core.olcrtc.combination_unsupported': s.errOlcrtcCombination,
        'core.olcrtc.token_required': s.errOlcrtcTokenRequired,
        'core.olcrtc.not_connectable': s.errOlcrtcNotConnectable,
        'core.olcrtc.server_mode_refused': s.errOlcrtcServerMode,
      };
      for (final entry in expected.entries) {
        final text = describe(s, CoreFailure(entry.key));
        expect(text, entry.value, reason: entry.key);
        expect(text, isNot(s.errGeneric), reason: entry.key);
        expect(text, isNot(contains('core.')), reason: entry.key);
        expect(text, contains('olcRTC'), reason: entry.key);
      }
    }
  });

  test('olcrtc warning codes localize and unknown codes stay hidden', () {
    final s = SRu();
    expect(warningLabel(s, 'olcrtc-tcp-only'), s.olcrtcTcpOnly);
    expect(warningLabel(s, 'olcrtc-ipv4-only'), s.olcrtcIpv4Only);
    expect(warningLabel(s, 'some-future-code'), isNull);
  });

  test('olcrtc servers carry the honest TCP/IPv4-only limits line', () {
    final s = SRu();
    final olc = OutboundSpec(protocol: 'olcrtc', transport: 'datachannel', security: 'olc2');
    expect(olcrtcLimits(s, olc), '${s.olcrtcTcpOnly} · ${s.olcrtcIpv4Only}');
    expect(protocolLine(olc), 'OLCRTC | DATACHANNEL | OLC2');
    expect(olcrtcLimits(s, OutboundSpec(protocol: 'vless')), isNull);
  });

  test('pasting an olcrtc link into import never throws and never routes raw', () {
    const link =
        'olcrtc://wbstream?seichannel<fps=60&batch=64>@room-01#d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799\$RU-1';
    // A bare server link is not a subscription URL: the router declines it
    // calmly (the QR/paste surface answers with its localized invalid-link
    // note), while the same link inside a subscription body is the core's
    // import path.
    expect(parseImportLink(link), isNull);
    expect(parseImportLink('https://example.org/sub'), isA<AddSubscription>());
  });

  testWidgets('servers list shows the olcrtc limits next to the server', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.language = 'ru';
    settings.animations = false;
    final sora = _OlcrtcState(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    final servers = find.byType(ServersScreen);
    expect(servers, findsWidgets);
    final detail = find.descendant(of: servers, matching: find.textContaining('Только TCP'));
    expect(detail, findsOneWidget);
    expect(find.descendant(of: servers, matching: find.textContaining('Только IPv4')), findsOneWidget);
    // The plain vless row must not inherit the olcrtc limits.
    expect(find.descendant(of: servers, matching: find.textContaining('olcrtc-tcp-only')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
