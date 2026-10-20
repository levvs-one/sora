import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/l10n/strings_ru.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/generated/sora/custom/v1/custom.pb.dart';
import 'package:sora/src/groups.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/servers.dart';

OutboundSpec _server(String id, String name) => OutboundSpec(id: id, displayName: name, protocol: 'vless');

SubscriptionState _sub(List<OutboundSpec> outbounds) => SubscriptionState(
  settings: SubscriptionSettings(id: 's1'),
  displayName: 'Sub',
  outbounds: outbounds,
);

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('settings favorites', () {
    test('toggle persists across a fresh Settings over the same store', () async {
      final settings = await Settings.load();
      expect(settings.favorites, isEmpty);
      expect(settings.isFavorite('b'), isFalse);
      expect(settings.toggleFavorite('b'), isTrue);
      expect(settings.isFavorite('b'), isTrue);
      await Future<void>.delayed(Duration.zero);
      final reloaded = await Settings.load();
      expect(reloaded.favorites, {'b'});
      expect(reloaded.isFavorite('b'), isTrue);
      expect(reloaded.toggleFavorite('b'), isFalse, reason: 'a second toggle unstars');
      await Future<void>.delayed(Duration.zero);
      expect((await Settings.load()).favorites, isEmpty);
    });

    test('several favorites round-trip as one set, stored canonically', () async {
      final settings = await Settings.load();
      settings.favorites = {'c', 'a', 'b'};
      await Future<void>.delayed(Duration.zero);
      final reloaded = await Settings.load();
      expect(reloaded.favorites, {'a', 'b', 'c'});
      expect(reloaded.favorites.toList(), ['a', 'b', 'c'], reason: 'the persisted list is sorted');
    });

    test('favorites stay out of the syncable settings document', () async {
      final settings = await Settings.load();
      settings
        ..favorites = {'a'}
        ..theme = 'dark';
      await Future<void>.delayed(Duration.zero);
      final doc = settings.exportSyncableSettings();
      expect(doc.keys, contains('theme'), reason: 'genuine preferences do sync');
      expect(doc.keys, isNot(contains('favoriteServers')), reason: 'server ids do not resolve on another device');
      // A peer document cannot smuggle the key in either.
      await settings.importSyncableSettings({
        'favoriteServers': {
          't': 'sl',
          'v': ['x'],
        },
      });
      expect(settings.favorites, {'a'});
    });
  });

  group('favorite entries', () {
    test('the favorites-only filter shows exactly the starred servers', () {
      final entries = entriesOf(_sub([_server('a', 'Alpha'), _server('b', 'Beta'), _server('c', 'Gamma')]));
      expect(favoriteEntries(entries, {'b'}).map((e) => e.id), ['b']);
      expect(favoriteEntries(entries, {'a', 'c'}).map((e) => e.id), ['a', 'c'], reason: 'order is kept');
      expect(favoriteEntries(entries, <String>{}), isEmpty);
      expect(favoriteEntries(entries, {'gone'}), isEmpty, reason: 'a favorite whose server vanished matches nothing');
    });

    test('favorites resolve after a subscription refresh rebuilds the list with the same ids', () {
      final before = entriesOf(_sub([_server('a', 'Alpha'), _server('b', 'Beta'), _server('c', 'Gamma')]));
      final favorites = {
        for (final e in favoriteEntries(before, {'b'})) e.id,
      };
      expect(favorites, {'b'});
      // A refresh replaces the whole subscription state: new objects, a
      // different order, one server added — the ids are the stable part.
      final refreshed = entriesOf(
        _sub([_server('c', 'Gamma'), _server('d', 'Delta'), _server('b', 'Beta'), _server('a', 'Alpha')]),
      );
      expect(favoriteEntries(refreshed, favorites).map((e) => e.id), ['b']);
    });

    test('a group is a favorite only when every member is starred; its star toggles all members', () {
      final entries = entriesOf(_sub([_server('a', 'NL (main)'), _server('b', 'NL (backup)'), _server('c', 'DE')]));
      final group = entries.first;
      expect(group.isGroup, isTrue);
      expect(isFavoriteEntry(group, {'a'}), isFalse, reason: 'a half-starred group is not a favorite');
      expect(isFavoriteEntry(group, {'a', 'b'}), isTrue);
      expect(favoriteEntries(entries, {'a'}), isEmpty);
      expect(favoriteEntries(entries, {'a', 'b'}).map((e) => e.id), [group.id]);
      final starred = toggledFavorites({'a'}, group);
      expect(starred, {'a', 'b'}, reason: 'starring the group stars the missing members too');
      expect(toggledFavorites(starred, group), isEmpty, reason: 'unstarring the group unstars every member');
      expect(toggledFavorites(<String>{}, entries.last), {'c'});
    });
  });

  testWidgets('star toggles a favorite, the filter shows only favorites, and a favorite still connects', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 700);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    settings.animations = false;
    final sora = _FavoritesSora(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: buildTheme(Brightness.light),
          home: const ServersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Finder row(String name) =>
        find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == name, description: 'row $name');
    expect(row('Alpha'), findsOneWidget);
    expect(row('Beta'), findsOneWidget);
    expect(row('Gamma'), findsOneWidget);
    // The star glyph is one codepoint; filled vs outline is the Icon fill
    // variation, like the shell's navigation icons.
    double starFill(String key) =>
        tester.widget<Icon>(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Icon))).fill!;
    expect(starFill('favorite-b'), 0);

    // Star Beta.
    await tester.tap(find.byKey(const ValueKey('favorite-b')));
    await tester.pumpAndSettle();
    expect(settings.isFavorite('b'), isTrue);
    expect(starFill('favorite-b'), 1);

    // The favorites filter narrows the list to exactly the starred server.
    await tester.tap(find.byKey(const ValueKey('favorites-filter')));
    await tester.pumpAndSettle();
    expect(row('Alpha'), findsNothing);
    expect(row('Beta'), findsOneWidget);
    expect(row('Gamma'), findsNothing);

    // Connecting from the favorites view is the ordinary selection.
    await tester.tap(row('Beta'));
    await tester.pumpAndSettle();
    expect(settings.server, 'b');

    // Unstarring from the filtered view empties it and the empty state speaks.
    await tester.tap(find.byKey(const ValueKey('favorite-b')));
    await tester.pumpAndSettle();
    expect(settings.favorites, isEmpty);
    expect(row('Beta'), findsNothing);
    expect(find.text(SRu().favoritesEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a lone favorite custom server suppresses the favorites empty hint', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 700);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    settings.animations = false;
    // The only favorite anywhere is the custom server, in its canonical
    // outbound id form — no subscription server is starred, so the
    // subscription sections are empty under the filter.
    settings.favorites = {'custom/abc'};
    final sora = _FavoritesSora(settings, customServers: [CustomServer(id: 'abc', name: 'Mine')]);
    addTearDown(sora.dispose);
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: buildTheme(Brightness.light),
          home: const ServersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('favorites-filter')));
    await tester.pumpAndSettle();
    // The custom card is a separate sliver above the subscription sections:
    // its starred row is visible, so the "no favorites" hint must not be.
    expect(find.text('Mine'), findsOneWidget);
    expect(find.text(SRu().favoritesEmpty), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

/// A Sora whose subscription carries three plain servers, with no core
/// attached: the servers screen renders from [subscriptions], and selection
/// still records the choice in settings.
class _FavoritesSora extends Sora {
  _FavoritesSora(super.settings, {this.customServers = const []});

  static final _outbounds = [_server('a', 'Alpha'), _server('b', 'Beta'), _server('c', 'Gamma')];

  @override
  final List<CustomServer> customServers;

  @override
  List<SubscriptionState> get subscriptions => [_sub(_outbounds)];

  @override
  List<OutboundSpec> get servers => _outbounds;
}
