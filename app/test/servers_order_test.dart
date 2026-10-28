import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sora/main.dart';
import 'package:sora/src/generated/sora/custom/v1/custom.pb.dart';
import 'package:sora/src/overrides.dart';

import 'desktop_shell_test.dart' show size;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/groups.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('old sort preferences are ignored by loading and sync', () async {
    await SharedPreferencesAsync().setString('serverSortMode', 'name');
    final settings = await Settings.load();
    expect(Settings.syncableSettingsKeys, isNot(contains('serverSortMode')));
    expect(settings.exportSyncableSettings(), isNot(contains('serverSortMode')));
    await settings.importSyncableSettings({
      'serverSortMode': {'t': 's', 'v': 'ping'},
    });
    expect(await SharedPreferencesAsync().getString('serverSortMode'), 'name');
  });

  for (final mode in ['ping', 'speed', 'name', 'subscription']) {
    testWidgets('provider order survives old $mode preference, measurements and search', (tester) async {
      await SharedPreferencesAsync().setString('serverSortMode', mode);
      final settings = await Settings.load();

      settings
        ..animations = false
        ..language = 'en';
      final sora = _OrderedSora(settings);
      addTearDown(sora.dispose);
      size(tester, 1440);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(SoraApp(sora: sora));
      await tester.pumpAndSettle();
      void expectOrder(List<String> ids) {
        final tops = [for (final id in ids) tester.getTopLeft(find.byKey(ValueKey(id))).dy];
        for (var i = 1; i < tops.length; i++) {
          expect(tops[i], greaterThan(tops[i - 1]), reason: ids.join(', '));
        }
      }

      expectOrder(['z', 'a', 'm', 'second', 'own']);
      sora.latency.addAll({'z': 900, 'a': 10, 'm': 80});
      final now = DateTime.now();
      sora.bandwidth.addAll({'z': (bps: 100, at: now), 'a': (bps: 10000000, at: now)});
      sora.notifyListeners();
      await tester.pumpAndSettle();
      expectOrder(['z', 'a', 'm', 'second', 'own']);
      expect(find.text('900 ms'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('server-search')), 'Node');
      await tester.pumpAndSettle();
      expectOrder(['z', 'a', 'm', 'own']);
      expect(find.byKey(const ValueKey('second')), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('server-search')), '');
      sora.first.outbounds.last.displayName = 'Zulu Node';
      final grouped = sora.first.deepCopy();
      sora.states[0] = grouped;
      sora.notifyListeners();
      await tester.pumpAndSettle();
      final group = entriesOf(grouped).first;
      expect(group.members.map((m) => m.id), ['z', 'm']);
      expectOrder([group.id, 'a', 'second', 'own']);
      expect(find.text('80 ms'), findsOneWidget);
      sora.overrides.put('first', const SubscriptionOverride(renames: {'z': 'Renamed'}));
      await tester.pumpAndSettle();
      expectOrder(['z', 'a', group.id, 'second', 'own']);
      expect(find.text('80 ms'), findsOneWidget);
      sora.overrides.put('first', const SubscriptionOverride(hidden: {'z'}));
      await tester.pumpAndSettle();
      expectOrder(['a', group.id, 'second', 'own']);
      expect(find.text('80 ms'), findsOneWidget);
      expect(sora.first.outbounds.map((o) => o.id), ['z', 'a', 'm']);
      await tester.pumpWidget(const SizedBox());
    });
  }

  final nodes = [
    for (var i = 0; i < 160; i++)
      OutboundSpec(id: 'node-${160 - i}', displayName: 'Node ${160 - i}', protocol: 'vless'),
  ];
  final now = DateTime.now();
  for (final mode in ['ping', 'speed', 'smart']) {
    test('$mode auto-selection and group members use provider order for ties', () async {
      final latency = {for (final node in nodes) node.id: 50};
      final bandwidth = {for (final node in nodes) node.id: (bps: 1000000, at: now)};
      final order = {for (var i = 0; i < nodes.length; i++) nodes[i].id: i};
      final ranked = nodes.reversed.toList()
        ..sort((a, b) => compareAutoSelect(a.id, b.id, mode, latency, bandwidth, providerOrder: order));
      expect(ranked.map((n) => n.id), nodes.map((n) => n.id));
      final group = entriesOf(
        SubscriptionState(outbounds: [for (final n in nodes) n.deepCopy()..displayName = 'Group']),
      ).single;
      expect(pickMember(group, {}, autoSelect: mode).id, nodes.first.id);
      expect(pickMember(group, latency, bandwidth: bandwidth, autoSelect: mode).id, nodes.first.id);
      expect(pickMember(group, {for (final n in nodes) n.id: null}, autoSelect: mode).id, nodes.first.id);
      expect(
        pickMember(group, {...latency, nodes.first.id: null}, bandwidth: bandwidth, autoSelect: mode).id,
        nodes[1].id,
      );
    });
  }

  for (final engine in ['mihomo', 'xray']) {
    test('$engine groups and tied fallback members retain provider order', () async {
      final settings = await Settings.load()
        ..engine = engine;
      final grouped = [for (final n in nodes) n.deepCopy()..displayName = 'Group'];
      final entry = entriesOf(SubscriptionState(outbounds: grouped)).single;
      final plan = buildPlan(servers: grouped, choice: entry.id, settings: settings, entry: entry);
      expect(plan.groups.single.members, grouped.map((n) => n.id));
      final pinned = buildPlan(servers: nodes, choice: nodes[50].id, settings: settings);
      if (engine == 'mihomo') {
        expect(pinned.groups.single.members, [
          nodes[50].id,
          ...nodes.where((n) => n.id != nodes[50].id).map((n) => n.id),
        ]);
      } else {
        expect(pinned.routing.proxyTarget, nodes[50].id);
      }
      final profiles = [for (final n in grouped) n.deepCopy()..protocol = 'xray-profile'];
      final profileEntry = entriesOf(SubscriptionState(outbounds: profiles)).single;
      final profilePlan = buildPlan(
        servers: profiles,
        choice: profileEntry.id,
        settings: settings,
        entry: profileEntry,
      );
      expect(profilePlan.outbounds.single.id, profiles.first.id);
    });
  }
}

class _OrderedSora extends Sora {
  _OrderedSora(super.settings);
  final states = [
    SubscriptionState(
      settings: SubscriptionSettings(id: 'first'),
      displayName: 'Zulu Provider',
      outbounds: [
        OutboundSpec(id: 'z', displayName: 'Zulu Node', protocol: 'trojan'),
        OutboundSpec(id: 'a', displayName: 'Alpha Node', protocol: 'trojan'),
        OutboundSpec(id: 'm', displayName: 'Middle Node', protocol: 'trojan'),
      ],
    ),
    SubscriptionState(
      settings: SubscriptionSettings(id: 'second-sub'),
      displayName: 'Alpha Provider',
      outbounds: [OutboundSpec(id: 'second', displayName: 'Other', protocol: 'trojan')],
    ),
  ];
  SubscriptionState get first => states.first;
  @override
  List<SubscriptionState> get subscriptions => states;
  @override
  List<OutboundSpec> get servers => states.expand((s) => s.outbounds).toList();
  @override
  List<CustomServer> get customServers => [CustomServer(id: 'own', name: 'Own Node', address: '127.0.0.1', port: 443)];
}
