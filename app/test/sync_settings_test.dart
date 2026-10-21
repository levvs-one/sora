import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('sync export handles stored bool, int and string list without typed getter failures', () async {
    final settings = await Settings.load();
    settings.theme = 'dark';
    settings.killSwitch = true;
    settings.probeTimeout = 2500;
    settings.dns = ['1.1.1.1', '9.9.9.9'];
    final exported = settings.exportSyncableSettings();
    expect(exported['theme'], {'t': 's', 'v': 'dark'});
    expect(exported['killSwitch'], {'t': 'b', 'v': true});
    expect(exported['probeTimeout'], {'t': 'i', 'v': 2500});
    expect(exported['dns'], {
      't': 'sl',
      'v': ['1.1.1.1', '9.9.9.9'],
    });
  });

  test('sync import rejects tags incompatible with each setting and unknown keys', () async {
    final settings = await Settings.load();
    for (final tagged in [
      {'t': 's', 'v': 'x'},
      {'t': 'i', 'v': 1},
      {
        't': 'sl',
        'v': ['x'],
      },
      {'t': 'b', 'v': 'true'},
      {'t': 'b', 'v': null},
    ]) {
      await settings.importSyncableSettings({'killSwitch': tagged});
      expect(settings.killSwitch, isFalse);
      expect((await Settings.load()).killSwitch, isFalse);
    }
    await settings.importSyncableSettings({
      'theme': {'t': 'b', 'v': true},
      'probeTimeout': {'t': 's', 'v': '500'},
      'dns': {'t': 's', 'v': '1.1.1.1'},
      'rules': {
        't': 'sl',
        'v': ['ok', 12],
      },
      'strictKillSwitch': {'t': 'b', 'v': true},
      'controlPort': {'t': 'b', 'v': true},
      'unknown': {'t': 's', 'v': 'x'},
    });
    expect(settings.theme, 'light');
    expect(settings.probeTimeout, 0);
    expect(settings.dns, isEmpty);
    expect(settings.rules, isEmpty);
    expect(settings.strictKillSwitch, isFalse);
    expect(settings.controlPort, isFalse);
  });

  test('sync import accepts each supported type and preserves absent keys', () async {
    final settings = await Settings.load();
    settings.language = 'ru';
    await settings.importSyncableSettings({
      'theme': {'t': 's', 'v': 'dark'},
      'killSwitch': {'t': 'b', 'v': true},
      'probeTimeout': {'t': 'i', 'v': 2500},
      'dns': {
        't': 'sl',
        'v': ['1.1.1.1'],
      },
    });
    final reloaded = await Settings.load();
    expect(reloaded.theme, 'dark');
    expect(reloaded.killSwitch, isTrue);
    expect(reloaded.probeTimeout, 2500);
    expect(reloaded.dns, ['1.1.1.1']);
    expect(reloaded.language, 'ru');
  });
}
