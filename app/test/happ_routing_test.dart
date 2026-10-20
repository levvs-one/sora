import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/desktop/happ_routing.dart';
import 'package:sora/src/desktop/links.dart';

/// Golden vector shared with core/happrouting's tests: a routing
/// document assembled field by field from the reconstructed
/// HappRoutingData schema, base64-encoded in the builder's transport
/// form (standard alphabet, padded) independently of this converter.
const goldenBase64 =
    'eyJOYW1lIjoiUHJvdmlkZXIgUlUiLCJHbG9iYWxQcm94eSI6dHJ1ZSwiRmFrZUROUyI6ZmFsc2UsIlVzZUNodW5rRmlsZXMiOmZhbHNlLCJSZW1vdGVETlNUeXBlIjoiRG9IIiwiUmVtb3RlRE5TSVAiOiJodHRwczovL2Rucy5leGFtcGxlL2Rucy1xdWVyeSIsIkRvbWVzdGljRE5TVHlwZSI6IkRvVSIsIkRvbWVzdGljRE5TSVAiOiI3Ny44OC44LjgiLCJEaXJlY3RTaXRlcyI6WyJnZW9zaXRlOmNhdGVnb3J5LXJ1IiwiYmFuay5leGFtcGxlIl0sIkRpcmVjdElwIjpbImdlb2lwOnJ1IiwiMTAuMC4wLjAvOCJdLCJQcm94eVNpdGVzIjpbImdlb3NpdGU6eW91dHViZSIsInZpZGVvLmV4YW1wbGUiXSwiUHJveHlJcCI6WyIyMDMuMC4xMTMuNyJdLCJCbG9ja1NpdGVzIjpbImFkcy5leGFtcGxlIl0sIkJsb2NrSXAiOlsiMTk4LjUxLjEwMC4wLzI0Il0sIkRvbWFpblN0cmF0ZWd5IjoiSVBJZk5vbk1hdGNoIn0=';

void main() {
  group('routing deep links', () {
    test('happ://routing/add carries its payload verbatim', () {
      final link = parseImportLink('happ://routing/add/$goldenBase64');
      expect(link, isA<AddRouting>());
      expect((link! as AddRouting).payload, goldenBase64);
      expect(parseImportLink('sora://routing/add/$goldenBase64'), isA<AddRouting>());
    });

    test('a routing link is never a subscription, and an empty one is refused', () {
      expect(parseImportLink('happ://routing/add/'), isNull);
      expect(parseImportLink('happ://routing/add/$goldenBase64'), isNot(isA<AddSubscription>()));
    });
  });

  group('happ routing conversion', () {
    test('the golden profile converts to the rules the Go converter produces', () {
      final imported = convertHappRouting(goldenBase64)!;
      expect(imported.name, 'Provider RU');
      expect(imported.globalProxy, isTrue);
      expect(imported.remoteDns, 'DoH https://dns.example/dns-query');
      expect(imported.domesticDns, 'DoU 77.88.8.8');
      expect(imported.rules.map((r) => r.stored), [
        'block domain:ads.example',
        'block 198.51.100.0/24',
        'direct geosite:category-ru',
        'direct domain:bank.example',
        'direct geoip:ru',
        'direct 10.0.0.0/8',
        'proxy geosite:youtube',
        'proxy domain:video.example',
        'proxy 203.0.113.7/32',
      ]);
      // DNS and DomainStrategy are accounted for as not applied.
      final recorded = imported.notes.where((n) => !n.applied).map((n) => n.field);
      expect(recorded, containsAll(['RemoteDNS', 'DomesticDNS', 'DomainStrategy']));
    });

    test('url-safe unpadded base64 and the RemoteDNSIp spelling are accepted', () {
      final doc = {
        'name': 'x',
        'RemoteDNSIp': '1.1.1.1',
        'DirectSites': ['a.example'],
      };
      final urlSafe = base64UrlEncode(utf8.encode(jsonEncode(doc))).replaceAll('=', '');
      final imported = convertHappRouting(urlSafe)!;
      expect(imported.remoteDns, '1.1.1.1');
      expect(imported.rules.single.destination, 'domain:a.example');
    });

    test('entries classify by shape and unclassifiable ones are counted', () {
      final doc = {
        'DirectSites': ['*.wild.example', 'https://url.example/path', 'single-label', 'bad entry'],
        'DirectIp': ['2001:db8::1', 'domain-in-ip-list.example'],
      };
      final imported = convertHappRouting(base64Encode(utf8.encode(jsonEncode(doc))))!;
      expect(imported.rules.map((r) => r.destination), [
        'domain:wild.example',
        'domain:url.example',
        '2001:db8::1/128',
        'domain:domain-in-ip-list.example',
      ]);
      expect(imported.skipped, 2);
    });

    test('GlobalProxy=false is recorded, not applied', () {
      final doc = {
        'GlobalProxy': false,
        'ProxySites': ['p.example'],
      };
      final imported = convertHappRouting(base64Encode(utf8.encode(jsonEncode(doc))))!;
      expect(imported.globalProxy, isFalse);
      final note = imported.notes.singleWhere((n) => n.field == 'GlobalProxy');
      expect(note.applied, isFalse);
    });

    test('broken payloads fail honestly', () {
      for (final payload in [
        '',
        '!!!not-a-payload!!!',
        base64Encode(utf8.encode('just some servers')),
        base64Encode(utf8.encode('["vless://x"]')),
        goldenBase64.substring(0, goldenBase64.length - 7),
      ]) {
        expect(convertHappRouting(payload), isNull, reason: payload);
      }
    });
  });
}
