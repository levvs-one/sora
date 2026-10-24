import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('a fresh or reset serverless plan uses positions supported by its platform', () async {
    final settings = await Settings.load();
    for (final reset in [false, true]) {
      if (reset) {
        settings.splitPos = ['2'];
        await settings.reset();
      }
      final plan = buildPlan(servers: [], choice: 'bypass', settings: settings);
      expect(plan.outbounds.single.protocol, 'bypass');
      final positions = plan.outbounds.single.bypass.splitPos;
      expect(positions, isNotEmpty);
      if (Platform.isWindows) {
        expect(positions.every((p) => int.tryParse(p) != null), isTrue);
      } else {
        expect(positions, contains('midsld'));
      }
      expect(plan.groups, isEmpty);
    }
  });
}
