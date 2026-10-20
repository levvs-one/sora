import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/overrides.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

/// C3 closure: the routing layers the core holds for a subscription
/// (F6 extra rules + C3 provider routing, fetched by Sora through
/// GetSubscriptionOverride) must reach the session plan. Before the
/// closure nothing called that RPC and buildPlan never saw the rules:
/// these tests pin the merge — sentinel substitution, ordering and
/// per-subscription gating.
void main() {
  final servers = [
    OutboundSpec(id: 'a', displayName: 'A', protocol: 'vless'),
    OutboundSpec(id: 'b', displayName: 'B', protocol: 'vless'),
    OutboundSpec(id: 'custom/x', displayName: 'Mine', protocol: 'vless'),
  ];
  const serverSubscription = {'a': 'subA', 'b': 'subB'};
  const layerA = CoreSubscriptionRules(
    extraRules: [
      (destination: 'domain:extra.example', outboundId: 'proxy'),
      (destination: 'domain:extra-direct.example', outboundId: 'direct'),
    ],
    providerRules: [
      (destination: 'geosite:youtube', outboundId: 'proxy'),
      (destination: 'domain:bank.example', outboundId: 'direct'),
      (destination: 'domain:ads.example', outboundId: 'reject'),
    ],
  );

  late Settings settings;
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    settings = await Settings.load();
    settings.failover = false;
    settings.rules = ['proxy domain:user.example'];
  });

  List<String> routesOf(SessionPlan plan) => [for (final r in plan.routes) '${r.destination} -> ${r.outboundId}'];

  test('a picked server merges its subscription layer after the user rules, sentinel resolved', () {
    final plan = buildPlan(
      servers: servers,
      choice: 'a',
      settings: settings,
      coreRules: const {'subA': layerA},
      serverSubscription: serverSubscription,
    );
    // The pick rides the pick group (API 1.12): proxy rules — the
    // user's, the extra rule's sentinel and the provider rule's
    // sentinel — all resolve to it; direct/reject stay built-in.
    expect(routesOf(plan), [
      'domain:user.example -> ${Sora.pickGroup}',
      'domain:extra.example -> ${Sora.pickGroup}',
      'domain:extra-direct.example -> direct',
      'geosite:youtube -> ${Sora.pickGroup}',
      'domain:bank.example -> direct',
      'domain:ads.example -> reject',
    ]);
    expect(plan.routes.any((r) => r.outboundId == 'proxy'), isFalse, reason: 'the sentinel must never reach the plan');
  });

  test('a server of another subscription gets no layer', () {
    final plan = buildPlan(
      servers: servers,
      choice: 'b',
      settings: settings,
      coreRules: const {'subA': layerA},
      serverSubscription: serverSubscription,
    );
    expect(routesOf(plan), ['domain:user.example -> ${Sora.pickGroup}']);
  });

  test('a custom server gets no layer', () {
    final plan = buildPlan(
      servers: servers,
      choice: 'custom/x',
      settings: settings,
      coreRules: const {'subA': layerA},
      serverSubscription: serverSubscription,
    );
    expect(routesOf(plan), ['domain:user.example -> ${Sora.pickGroup}']);
  });

  test('auto merges every subscription in the plan, extra rules above provider rules', () {
    const layerB = CoreSubscriptionRules(
      extraRules: [(destination: 'domain:b-extra.example', outboundId: 'direct')],
      providerRules: [(destination: 'domain:b-provider.example', outboundId: 'proxy')],
    );
    final plan = buildPlan(
      servers: servers,
      choice: 'auto',
      settings: settings,
      coreRules: const {'subA': layerA, 'subB': layerB},
      serverSubscription: serverSubscription,
    );
    expect(routesOf(plan), [
      'domain:user.example -> ${Sora.autoGroup}',
      'domain:extra.example -> ${Sora.autoGroup}',
      'domain:extra-direct.example -> direct',
      'domain:b-extra.example -> direct',
      'geosite:youtube -> ${Sora.autoGroup}',
      'domain:bank.example -> direct',
      'domain:ads.example -> reject',
      'domain:b-provider.example -> ${Sora.autoGroup}',
    ]);
  });

  test('without fetched layers the plan is exactly the pre-closure plan', () {
    final plan = buildPlan(servers: servers, choice: 'a', settings: settings);
    expect(routesOf(plan), ['domain:user.example -> ${Sora.pickGroup}']);
  });
}
