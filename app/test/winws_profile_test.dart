import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/ext/bypass.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> source() =>
      jsonDecode(File('../extensions/sources/zapret/hook.json').readAsStringSync()) as Map<String, dynamic>;

  test('one signed-source descriptor chooses Linux TPWS or Windows Winws explicitly', () {
    final raw = jsonEncode(source());
    final linux = ExtensionBypass.parse(raw, operatingSystem: 'linux');
    final windows = ExtensionBypass.parse(raw, operatingSystem: 'windows');
    expect(linux.backend, 'tpws');
    expect(windows.backend, 'winws');
    expect(linux.select({'profile': 'TCP+TLS'}).tlsRecord, '1');
    expect(windows.select({'profile': 'TCP+TLS'}).tlsRecord, isEmpty);
    expect(windows.profiles, hasLength(3));
    expect(() => ExtensionBypass.parse(raw, operatingSystem: 'android'), throwsFormatException);
    windows.select({'profile': 'TLS'}).splitPos.clear();
    expect(windows.select({'profile': 'TLS'}).splitPos, ['1']);
  });

  test('Windows scope, OS pairing, protobuf fields and supported strategies are mandatory', () {
    final original = source();
    final platforms = original['platforms'] as Map<String, dynamic>;
    final windows = platforms['windows'] as Map<String, dynamic>;
    final profiles = windows['profiles'] as Map<String, dynamic>;
    final tls = profiles['TLS'] as Map<String, dynamic>;
    final variants = [
      {...windows, 'scope': 'all'},
      Map<String, dynamic>.of(windows)..remove('scope'),
      {...windows, 'executable': 'winws.exe'},
      for (final field in [
        {'oob': true},
        {'tlsRecord': '1'},
        {'nativePath': 'winws.exe'},
      ])
        {
          ...windows,
          'profiles': {
            ...profiles,
            'TLS': {...tls, ...field},
          },
        },
    ];
    for (final doc in [
      {...original, 'path': '/bin/sh'},
      {
        ...original,
        'platforms': {...platforms, 'android': <String, dynamic>{}},
      },
      {
        ...original,
        'platforms': {...platforms, 'linux': windows},
      },
      for (final variant in variants)
        {
          ...original,
          'platforms': {...platforms, 'windows': variant},
        },
    ]) {
      expect(() => ExtensionBypass.parse(jsonEncode(doc), operatingSystem: 'windows'), throwsFormatException);
    }
  });

  test('Winws remains a distinct wire protocol; manual SOCKS settings are retained', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = await Settings.load();
    settings.splitPos = ['3'];
    settings.tlsRecord = '2';
    final descriptor = ExtensionBypass.parse(jsonEncode(source()), operatingSystem: 'windows');
    final profile = ExtensionBypassProfile(
      extensionId: 'org.sora.zapret',
      name: 'Zapret',
      backend: descriptor.backend,
      strategy: descriptor.select({'profile': 'TCP+TLS'}),
    );
    final plan = buildPlan(servers: [], choice: profile.choiceId, settings: settings, bypassProfile: profile);
    expect(plan.outbounds.single.protocol, 'winws');
    expect(plan.outbounds.single.bypass.splitPos, ['1', 'midsld']);
    expect(plan.outbounds.single.bypass.tlsRecord, isEmpty);
    expect(settings.splitPos, ['3']);
    expect(settings.tlsRecord, '2');
  });

  test('ByeDPI descriptor must name each supported platform explicitly', () {
    final variant = {
      'backend': 'byedpi',
      'profiles': {
        'TCP': {
          'splitPos': ['1'],
        },
      },
    };
    final raw = jsonEncode({
      'hook_version': 3,
      'platforms': {'linux': variant, 'windows': variant},
    });
    final linux = ExtensionBypass.parse(raw, operatingSystem: 'linux');
    final windows = ExtensionBypass.parse(raw, operatingSystem: 'windows');
    expect(linux.backend, 'byedpi');
    expect(linux.supports('linux'), isTrue);
    expect(linux.supports('windows'), isFalse);
    expect(windows.supports('windows'), isTrue);
    expect(windows.supports('linux'), isFalse);
    final legacy = ExtensionBypass.parse(jsonEncode({'hook_version': 2, ...variant}));
    expect(legacy.supports('windows'), isTrue);
    expect(legacy.supports('linux'), isFalse);
  });

  test('Linux ByeDPI plans cannot silently select the TPWS backend', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = await Settings.load();
    final descriptor = ExtensionBypass.parse(
      jsonEncode({
        'hook_version': 2,
        'backend': 'byedpi',
        'profiles': {
          'TCP': {
            'splitPos': ['1'],
          },
        },
      }),
    );
    final profile = ExtensionBypassProfile(
      extensionId: 'org.sora.byedpi',
      name: 'ByeDPI',
      backend: 'byedpi',
      strategy: descriptor.select({'profile': 'TCP'}),
    );
    final plan = buildPlan(servers: [], choice: profile.choiceId, settings: settings, bypassProfile: profile);
    expect(plan.outbounds.single.protocol, Platform.isLinux ? 'byedpi' : 'bypass');
  });

  test('Linux ByeDPI requires its own advertised core capability', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final settings = await Settings.load();
    final descriptor = ExtensionBypass.parse(
      jsonEncode({
        'hook_version': 2,
        'backend': 'byedpi',
        'profiles': {
          'TCP': {
            'splitPos': ['1'],
          },
        },
      }),
    );
    final profile = ExtensionBypassProfile(
      extensionId: 'org.sora.byedpi',
      name: 'ByeDPI',
      backend: 'byedpi',
      strategy: descriptor.select({'profile': 'TCP'}),
    );
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    sora.serverlessAvailable = true;
    expect(sora.bypassProfileAvailable(profile), !Platform.isLinux);
    sora.coreCapabilities = {'serverless-bydpi'};
    expect(sora.bypassProfileAvailable(profile), isTrue);
    sora.serverlessAvailable = false;
    expect(sora.bypassProfileAvailable(profile), Platform.isLinux);
  });
}
