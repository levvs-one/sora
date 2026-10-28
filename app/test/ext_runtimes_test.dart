import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/main.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/ui/extensions/detail_screen.dart';
import 'package:sora/src/ext/bridge.dart';
import 'package:sora/src/ui/kit.dart' show SwitchTile;
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/ext/assets.dart';
import 'package:sora/src/ext/conflicts.dart';
import 'package:sora/src/ext/store.dart';
import 'package:sora/src/ext/manifest.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/rules.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

Future<InstalledExtension> seed(
  Directory dir,
  String example, {
  String? id,
  int? priority,
  String? installedAt,
  bool enabled = true,
}) async {
  final path = '../examples/$example';
  final manifest = jsonDecode(await File('$path/sora-extension.json').readAsString()) as Map<String, dynamic>;
  if (id != null) manifest['id'] = id;
  final m = ExtManifest.parse(jsonEncode(manifest));
  final inst = InstalledExtension(
    manifest: m,
    enabled: enabled,
    source: 'sideload',
    installedAt: DateTime.parse(installedAt ?? '2026-10-21T00:00:00Z'),
    granted: m.permissions,
  );
  final root = Directory('${dir.path}/${m.id}@${m.version}');
  await root.create();
  for (final entry in [m.themeEntry, m.routingEntry].nonNulls) {
    var source = await File('$path/$entry').readAsString();
    if (priority != null && m.routingEntry != null) {
      final data = jsonDecode(source) as Map<String, dynamic>..['priority'] = priority;
      source = jsonEncode(data);
    }
    await File('${root.path}/$entry').writeAsString(source);
  }
  final registry = File('${dir.path}/installed.json');
  final data = await registry.exists()
      ? jsonDecode(await registry.readAsString()) as Map<String, dynamic>
      : <String, dynamic>{};
  data[m.id] = inst.toJson();
  await registry.writeAsString(jsonEncode(data));
  return inst;
}

void main() {
  late Directory dir;
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    dir = await Directory.systemTemp.createTemp('sora-ext-runtime-');
  });
  tearDown(() => dir.delete(recursive: true));

  testWidgets('enabled theme changes the app palette and disable and uninstall restore it instantly', (tester) async {
    late InstalledExtension inst;
    late ExtensionStore store;
    late Settings settings;
    await tester.runAsync(() async {
      inst = await seed(dir, 'theme-midnight');
      store = ExtensionStore(dir: dir.path);
      await store.load();
      settings = await Settings.load();

      settings.animations = false;
    });
    final sora = Sora(settings, extensions: store);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    Palette palette() => Theme.of(tester.element(find.byType(Scaffold).first)).extension<Palette>()!;
    expect(palette().background, const Color(0xff121820));
    expect(palette().glowColors, Palette.spectrum);
    await tester.runAsync(() => store.setEnabled(inst.id, false));
    await tester.pump();
    expect(palette().background, Palette.light.background);
    await tester.runAsync(() => store.setEnabled(inst.id, true));
    await tester.pump();
    expect(palette().background, const Color(0xff121820));
    await tester.runAsync(() => store.uninstall(inst.id));
    await tester.pump();
    expect(palette().background, Palette.light.background);
    expect(tester.takeException(), isNull);
  });

  test('themes reject colors, unknown tokens and low contrast; accent is optional', () {
    final source = File('../examples/theme-midnight/theme.json').readAsStringSync();
    for (final token in ['red', '#00000000', 'url(https://example.org)', '#121820']) {
      final data = jsonDecode(source) as Map<String, dynamic>;
      (data['css_variables'] as Map<String, dynamic>)['--sora-text'] = token;
      expect(() => ExtensionTheme.parse(jsonEncode(data)), throwsFormatException);
    }
    final data = jsonDecode(source) as Map<String, dynamic>;
    (data['css_variables'] as Map<String, dynamic>)['--sora-accent'] = '#AABBCC';
    expect(ExtensionTheme.parse(jsonEncode(data)).palette.glowColors.toSet(), {const Color(0xffaabbcc)});
    (data['css_variables'] as Map<String, dynamic>)['--unknown'] = '#FFFFFF';
    expect(() => ExtensionTheme.parse(jsonEncode(data)), throwsFormatException);
  });

  test('only the chosen theme applies and grants gate both declarative runtimes', () async {
    final one = await seed(dir, 'theme-midnight', id: 'org.sora.one');
    final two = await seed(dir, 'theme-midnight', id: 'org.sora.two');
    final routing = await seed(dir, 'routing-split');
    final registry = File('${dir.path}/installed.json');
    final data = jsonDecode(await registry.readAsString()) as Map<String, dynamic>;
    (data[routing.id] as Map<String, dynamic>)['granted'] = <String>[];
    await registry.writeAsString(jsonEncode(data));
    final store = ExtensionStore(dir: dir.path);
    addTearDown(store.dispose);
    await store.load();
    expect(store.activeTheme, isNull);
    expect(store.routingRules, isEmpty);
    final conflict = findConflicts(store.installed).single;
    await store.setConflictWinner(conflict.key, two.id);
    expect(store.activeTheme, isNotNull);
    await store.setEnabled(two.id, false);
    expect(store.activeTheme, isNotNull);
    await store.setEnabled(one.id, false);
    expect(store.activeTheme, isNull);
  });

  test('extension plan order, selected proxy, overlap log and disabled rules', () async {
    await seed(dir, 'routing-split', id: 'org.sora.z', priority: 5);
    await seed(dir, 'routing-split', id: 'org.sora.c', priority: 10);
    final winner = await seed(dir, 'routing-split', id: 'org.sora.a', priority: 10);
    await seed(dir, 'routing-split', id: 'org.sora.b', priority: 10, installedAt: '2026-10-22T00:00:00Z');
    final store = ExtensionStore(dir: dir.path);
    addTearDown(store.dispose);
    await store.load();
    expect(store.routingRules.map((r) => r.extensionId).toList(), [
      for (final id in ['org.sora.a', 'org.sora.c', 'org.sora.b', 'org.sora.z']) ...List.filled(3, id),
    ]);
    expect(findConflicts(store.installed), isEmpty);
    final settings = await Settings.load();
    settings.rules = ['block domain:example.org'];
    final plan = buildPlan(
      servers: [OutboundSpec(id: 'chosen', protocol: 'vless')],
      choice: 'chosen',
      settings: settings,
      extensionRules: [for (final r in store.routingRules) r.rule],
    );
    expect(plan.routes.first.outboundId, 'reject');
    expect(plan.routes[3].outboundId, 'chosen');
    expect(plan.routes[1].outboundId, 'direct');
    store.logRoutingOverlaps(['domain:example.org']);
    expect(store.runtimeLog(winner.id).join('\n'), contains('routing overlap'));
    expect(routingMatchesOverlap('10.0.0.0/8', '10.20.0.0/16'), isTrue);
    expect(routingMatchesOverlap('domain:example.org', 'domain:api.example.org'), isTrue);
    await store.setEnabled(winner.id, false);
    expect(store.routingRules.any((r) => r.extensionId == winner.id), isFalse);
  });

  test('routing rejects invalid actions and matches using the user parser', () {
    for (final action in ['chosen-server', 'reject', '']) {
      expect(
        () => ExtensionRouting.parse(
          'org.sora.rules',
          jsonEncode({
            'rules': [
              {'match': 'example.org', 'action': action},
            ],
          }),
        ),
        throwsFormatException,
      );
    }
    for (final match in ['1.2.3.4/99', '10.0.0.0/8/evil', 'bad host', '../escape']) {
      expect(UserRule.destinationOf(match), isNull);
      expect(
        () => ExtensionRouting.parse(
          'org.sora.rules',
          jsonEncode({
            'rules': [
              {'match': match, 'action': 'direct'},
            ],
          }),
        ),
        throwsFormatException,
      );
    }
    expect(
      ExtensionRouting.parse(
        'org.sora.rules',
        '{"rules":[{"match":"domain:example.org","action":"block"}]}',
      ).rules.single.rule.destination,
      'domain:example.org',
    );
  });
  testWidgets('extension details show active routing matches and remove them on disable', (tester) async {
    late InstalledExtension inst;
    late ExtensionStore store;
    await tester.runAsync(() async {
      inst = await seed(dir, 'routing-split');
      store = ExtensionStore(dir: dir.path);
      await store.load();
    });
    addTearDown(store.dispose);
    await tester.pumpWidget(
      ExtScope(
        store: store,
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: ExtensionDetailScreen(installed: inst),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('example.org'), findsOneWidget);
    expect(find.text('Use the currently selected proxy; no server ID is embedded'), findsOneWidget);
    await tester.runAsync(() => store.setEnabled(inst.id, false));
    await tester.pumpAndSettle();
    expect(find.text('example.org'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('worker callbacks reuse PanelBridge settings, grants and error codes', () async {
    final inst = await seed(dir, 'routing-split');
    final store = ExtensionStore(dir: dir.path);
    addTearDown(store.dispose);
    await store.load();
    final bridge = PanelBridge(
      extensionId: inst.id,
      granted: {},
      getConnections: () => throw StateError('refused API reached core'),
      servers: () => throw StateError('refused API reached core'),
      notify: (_, _) => throw StateError('refused API delivered notification'),
      getSettings: () => store.getSettings(inst.id),
      setSettings: (values) async {
        try {
          await store.setSettings(inst.id, values);
        } on ExtStoreError catch (e) {
          throw BridgeError('invalid-argument', e.message);
        }
      },
    );
    final allowed = jsonDecode(await bridge.handle('{"id":1,"method":"getSettings"}')) as Map<String, dynamic>;
    expect(allowed['ok'], isTrue);
    expect(allowed['result'], isEmpty);
    for (final method in ['getServers', 'getConnections', 'notify']) {
      final reply = jsonDecode(await bridge.handle(jsonEncode({'id': 2, 'method': method}))) as Map<String, dynamic>;
      expect(reply['error'], 'permission-denied');
    }
    final refused =
        jsonDecode(await bridge.handle('{"id":3,"method":"setSettings","args":{"unknown":1}}')) as Map<String, dynamic>;
    expect(refused['error'], 'invalid-argument');
    for (final malformed in ['[]', '{"method":1}', '{"method":"getSettings","args":[]}']) {
      final reply = jsonDecode(await bridge.handle(malformed)) as Map<String, dynamic>;
      expect(reply['error'], 'invalid-argument');
    }
  });
  testWidgets('an unreadable theme is refused with a localized toast', (tester) async {
    late InstalledExtension inst;
    late ExtensionStore store;
    await tester.runAsync(() async {
      inst = await seed(dir, 'theme-midnight', enabled: false);
      final asset = File('${dir.path}/${inst.id}@${inst.version}/theme.json');
      final data = jsonDecode(await asset.readAsString()) as Map<String, dynamic>;
      (data['css_variables'] as Map<String, dynamic>)['--sora-text'] = '#121820';
      await asset.writeAsString(jsonEncode(data));
      store = ExtensionStore(dir: dir.path);
      await store.load();
    });
    addTearDown(store.dispose);
    await tester.pumpWidget(
      ExtScope(
        store: store,
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: ExtensionDetailScreen(installed: inst),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(SwitchTile), 250, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byType(SwitchTile));
    await tester.pump();
    expect(find.text(lookupS(const Locale('en')).extAssetRejected), findsOneWidget);
    expect(store.isEnabled(inst.id), isFalse);
    expect(store.activeTheme, isNull);
    expect(tester.takeException(), isNull);
  });
  test('changing user rules logs overlaps with enabled extension contributions', () async {
    final inst = await seed(dir, 'routing-split');
    final store = ExtensionStore(dir: dir.path);
    await store.load();
    final sora = Sora(await Settings.load(), extensions: store);
    addTearDown(sora.dispose);
    expect(store.runtimeLog(inst.id), isEmpty);
    await sora.change((s) => s.rules = ['block domain:example.org']);
    expect(store.runtimeLog(inst.id).join('\n'), contains('routing overlap'));
  });

  // Published examples, scaffold templates and the manifest guide must stay
  // installable by this release and never claim support before 1.1.0,
  // the first version with extensions.
  test('documented min_app_version stays between 1.1.0 and this release', () {
    final release = RegExp(
      r'^version: (\d+\.\d+\.\d+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;
    List<File> manifests(String dir, String name) => [
      for (final entry in Directory(dir).listSync().whereType<Directory>())
        if (File('${entry.path}/$name').existsSync()) File('${entry.path}/$name'),
    ];
    final files = [
      ...manifests('../examples', 'sora-extension.json'),
      ...manifests('../tools/sora-ext/templates', 'sora-extension.json.tmpl'),
      File('../docs/extensions.md'),
    ];
    var checked = 0;
    for (final file in files) {
      for (final match in RegExp(r'"min_app_version":\s*"([^"]+)"').allMatches(file.readAsStringSync())) {
        final version = match.group(1)!;
        expect(compareVersions(version, '1.1.0'), greaterThanOrEqualTo(0), reason: '${file.path}: $version');
        expect(compareVersions(version, release), lessThanOrEqualTo(0), reason: '${file.path}: $version > $release');
        checked++;
      }
    }
    expect(checked, greaterThanOrEqualTo(files.length));
  });
}
