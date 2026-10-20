import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

/// Dart's List.sort is not stable, so every comparator the servers
/// screen sorts with must be a total order: equal metric keys fall
/// back to the server id. These tests pin that property directly —
/// the same set of servers with equal ping / speed / name, fed in
/// different input orders, must always come out in the same order.
void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('compareAutoSelect tie-breaks', () {
    final latency = <String, int?>{'a': 100, 'b': 100, 'c': 100};
    final now = DateTime.now();
    final bandwidth = <String, ({int bps, DateTime at})>{
      'a': (bps: 5000, at: now),
      'b': (bps: 5000, at: now),
      'c': (bps: 5000, at: now),
    };

    test('equal ping sorts by id whatever the input order', () {
      for (final input in [
        ['c', 'a', 'b'],
        ['b', 'c', 'a'],
        ['a', 'b', 'c'],
      ]) {
        final sorted = [...input]..sort((x, y) => compareAutoSelect(x, y, 'ping', latency, const {}));
        expect(sorted, ['a', 'b', 'c'], reason: 'input $input');
      }
    });

    test('equal speed sorts by id whatever the input order', () {
      final sorted = ['c', 'a', 'b']..sort((x, y) => compareAutoSelect(x, y, 'speed', latency, bandwidth));
      expect(sorted, ['a', 'b', 'c']);
    });

    test('equal smart score sorts by id whatever the input order', () {
      final sorted = ['b', 'c', 'a']..sort((x, y) => compareAutoSelect(x, y, 'smart', latency, bandwidth));
      expect(sorted, ['a', 'b', 'c']);
    });

    test('a real metric difference still wins over the id tie-break', () {
      final sorted = ['a', 'b']..sort((x, y) => compareAutoSelect(x, y, 'ping', {'a': 200, 'b': 50}, const {}));
      expect(sorted, ['b', 'a'], reason: 'lower ping first, ids do not override metrics');
    });
  });

  test('compareServers: equal display names tie-break by id; equal ping too', () async {
    final settings = await Settings.load();
    final sora = _SortSora(settings);
    addTearDown(sora.dispose);
    // Two servers share one display name; a third is measured with
    // the same latency as the first.
    expect(sora.compareServers('srv-b', 'srv-a', 'name'), greaterThan(0));
    expect(sora.compareServers('srv-a', 'srv-b', 'name'), lessThan(0));
    sora.latency['srv-a'] = 100;
    sora.latency['srv-b'] = 100;
    final sorted = ['srv-b', 'srv-a']..sort((x, y) => sora.compareServers(x, y, 'ping'));
    expect(sorted, ['srv-a', 'srv-b']);
  });
}

OutboundSpec _server(String id, String name) => OutboundSpec(id: id, displayName: name, protocol: 'vless');

class _SortSora extends Sora {
  _SortSora(super.settings);

  static final _outbounds = [_server('srv-a', 'Same'), _server('srv-b', 'Same'), _server('srv-c', 'Other')];

  @override
  List<OutboundSpec> get servers => _outbounds;
}
