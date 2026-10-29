import 'dart:convert';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/main.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/ui/language.dart';
import 'package:sora/src/ui/servers.dart';

import 'fixtures/desktop_state.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());
  test('every language preserves localization keys, placeholders, guide links and technical names', () {
    final base = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final keys = base.keys.where((k) => !k.startsWith('@')).toSet();
    final links = RegExp(r'https?://[^\s)]+').allMatches(base['modesGuide'] as String).map((m) => m.group(0)!).toSet();
    for (final language in appLanguages) {
      final data = jsonDecode(File('lib/l10n/app_${language.code}.arb').readAsStringSync()) as Map<String, dynamic>;
      expect(data.keys.where((k) => !k.startsWith('@')).toSet(), keys, reason: language.code);
      for (final key in keys) {
        expect(data[key], isNotEmpty, reason: '${language.code}: $key');
        expect(data[key], isNot(contains('ZXQ')), reason: '${language.code}: $key');
        for (final match in RegExp(r'\{\w+\}').allMatches(base[key] as String)) {
          expect(data[key], contains(match.group(0)), reason: '${language.code}: $key');
        }
      }
      for (final url in links) {
        expect(
          data['modesGuide'],
          contains(language.code == 'ru' ? url.replaceFirst('lx-config.md', 'lx-config.ru.md') : url),
          reason: language.code,
        );
      }
      for (final protocol in [
        'VLESS',
        'VMess',
        'Trojan',
        'Shadowsocks',
        'Hysteria2',
        'TUIC',
        'AnyTLS',
        'WireGuard',
        'AmneziaWG',
      ]) {
        expect(data['modesGuide'], contains(protocol), reason: language.code);
      }
    }
  });
  for (final language in appLanguages) {
    testWidgets('${language.code}: localized home and subscription metadata fit a small window', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(420, 800);
      addTearDown(tester.view.reset);
      final settings = await Settings.load();
      await settings.completeTour();
      settings.language = language.code;
      settings.animations = false;
      final sora = DesktopState(settings);
      addTearDown(sora.dispose);
      await tester.pumpWidget(SoraApp(sora: sora));
      await tester.pumpAndSettle();
      final strings = S.of(tester.element(find.byType(LanguageButton)));
      expect(find.text(language.native), findsOneWidget);
      expect(formatBytes(strings, Int64(2048), settings.locale!.toLanguageTag()), isNotEmpty);
      for (final count in [0, 1, 2, 5, 20]) {
        expect(strings.expiresIn('Travel', count), contains('Travel'));
        expect(strings.groupBest(count), isNotEmpty);
      }
      final rich = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Нидерланды, Амстердам'),
      );
      expect(rich, findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
  testWidgets('language search accepts native names, English, Russian and country aliases and highlights matches', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.reset);
    final settings = await Settings.load();
    await settings.completeTour();
    settings.language = 'ru';
    settings.animations = false;
    final sora = DesktopState(settings);
    addTearDown(sora.dispose);
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-button')));
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('language-search'));
    for (final (query, code) in [
      ('IND', 'hi'),
      ('Indonesia', 'id'),
      ('Китайский', 'zh_Hans'),
      ('繁體', 'zh_Hant'),
      ('Кыргыз', 'ky'),
      ('Japanese', 'ja'),
    ]) {
      await tester.enterText(search, query);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('language-$code')), findsOneWidget, reason: query);
      final texts = find.descendant(of: find.byKey(ValueKey('language-$code')), matching: find.byType(RichText));
      var highlighted = false;
      for (final element in texts.evaluate()) {
        (element.widget as RichText).text.visitChildren((span) {
          if (span is TextSpan && span.style?.fontWeight == FontWeight.w700) highlighted = true;
          return true;
        });
      }
      expect(highlighted, isTrue, reason: query);
    }
    await tester.enterText(search, '繁體');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-zh_Hant')));
    await tester.pumpAndSettle();
    expect(settings.language, 'zh_Hant');
    expect(settings.locale, const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
    expect(find.text('繁體中文'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
