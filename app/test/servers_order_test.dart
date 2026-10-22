import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/groups.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/servers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('provider order is the default for new and upgraded installs without a choice', () async {
    expect((await Settings.load()).serverSortMode, 'subscription');
    await SharedPreferencesAsync().setInt('format', 1);
    await SharedPreferencesAsync().setString('theme', 'dark');
    expect((await Settings.load()).serverSortMode, 'subscription');
  });

  for (final mode in ['ping', 'speed', 'name', 'subscription']) {
    test('saved $mode choice survives loading', () async {
      await SharedPreferencesAsync().setString('serverSortMode', mode);
      expect((await Settings.load()).serverSortMode, mode);
    });
  }

  final nodes = [
    for (var i = 0; i < 160; i++)
      OutboundSpec(id: 'node-${160 - i}', displayName: 'Node ${160 - i}', protocol: 'vless'),
  ];
  List<Entry> entries(List<OutboundSpec> nodes) => [
    for (final node in nodes) entriesOf(SubscriptionState(outbounds: [node])).single,
  ];
  final now = DateTime.now();
  for (final mode in ['subscription', 'ping', 'speed', 'name']) {
    for (final measured in [false, true]) {
      test('$mode retains provider order for ${measured ? 'equal' : 'missing'} keys', () async {
        final settings = await Settings.load()
          ..serverSortMode = mode;
        final sora = Sora(settings);
        addTearDown(sora.dispose);
        // Same labels in separate entries exercise List.sort's unstable
        // partitions even for name mode, without grouping them first.
        final equal = [for (final node in nodes) node.deepCopy()..displayName = 'Equal'];
        if (measured) {
          sora.latency.addAll({for (final node in equal) node.id: 50});
          sora.bandwidth.addAll({for (final node in equal) node.id: (bps: 1000000, at: now)});
        }
        final sorted = sortServerEntries(entries(equal).reversed.toList(), sora, equal);
        expect(sorted.map((e) => e.id), equal.map((n) => n.id));
      });
    }
  }

  test('sort keys win before provider positions and speed ties ignore ping', () async {
    final settings = await Settings.load();
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    final list = [
      OutboundSpec(id: 'z', displayName: 'Zulu'),
      OutboundSpec(id: 'a', displayName: 'Alpha'),
      OutboundSpec(id: 'm', displayName: 'Middle'),
    ];
    sora.latency.addAll({'z': 90, 'a': 20, 'm': 20});
    sora.bandwidth.addAll({'z': (bps: 300, at: now), 'a': (bps: 100, at: now), 'm': (bps: 300, at: now)});
    for (final (mode, expected) in [
      ('subscription', ['z', 'a', 'm']),
      ('ping', ['a', 'm', 'z']),
      ('speed', ['z', 'm', 'a']),
      ('name', ['a', 'm', 'z']),
    ]) {
      settings.serverSortMode = mode;
      expect(sortServerEntries(entries(list), sora, list).map((e) => e.id), expected, reason: mode);
    }
  });

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

  test('overrides retain source positions when splitting or hiding group members', () async {
    final list = [
      OutboundSpec(id: 'z', displayName: 'Group'),
      OutboundSpec(id: 'a', displayName: 'Alpha'),
      OutboundSpec(id: 'm', displayName: 'Group'),
    ];
    final original = entriesOf(
      SubscriptionState(
        settings: SubscriptionSettings(id: 'sub'),
        outbounds: list,
      ),
    );
    final sora = Sora(await Settings.load());
    addTearDown(sora.dispose);
    final split = [
      for (final e in original) ...e.applyRenames({'z': 'Renamed'}),
    ];
    expect(sortServerEntries(split, sora, list).map((e) => e.members.first.id), ['z', 'a', 'm']);
    final hidden = original.map((e) => e.withoutHidden({'z'})).nonNulls.toList();
    expect(sortServerEntries(hidden, sora, list).map((e) => e.members.first.id), ['a', 'm']);
    expect(list.map((o) => o.id), ['z', 'a', 'm']);
  });

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
