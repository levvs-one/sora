import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' show ClientException;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/main.dart';
import 'package:sora/src/ui/shell.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart' show SoraError;
import 'package:sora/src/settings.dart';
import 'package:sora/src/design/theme.dart';
import 'package:sora/src/sora.dart';
import 'package:sora/src/ui/kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  Future<Sora> start() async {
    final settings = await Settings.load();
    settings.language = 'ru';
    final sora = Sora(settings);
    addTearDown(sora.dispose);
    return sora;
  }

  test('every Go catalog key and app failure has an explicit localized mapping', () {
    final keys = <String>{};
    for (final file in Directory('../core/errs').listSync().whereType<File>()) {
      if (!file.path.endsWith('.go') || file.path.endsWith('_test.go')) continue;
      keys.addAll(RegExp(r'\bKey\s*=\s*"(core\.[a-z_.]+)"').allMatches(file.readAsStringSync()).map((m) => m[1]!));
    }
    expect(keys.length, greaterThan(60));
    for (final file in Directory('lib/src').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.contains('/generated/')) continue;
      keys.addAll(RegExp("['\"](app\\.[a-z_]+)['\"]").allMatches(file.readAsStringSync()).map((m) => m[1]!));
    }
    final mapping = File('lib/src/ui/kit.dart').readAsStringSync().split('String describe(').last;
    final explicit = RegExp("'((?:core|app)\\.[a-z_.]+)'").allMatches(mapping).map((m) => m[1]!).toSet();
    expect(keys.difference(explicit), isEmpty);
    for (final locale in S.supportedLocales) {
      final s = lookupS(locale);
      for (final key in keys) {
        final message = describe(s, CoreFailure(key));
        expect(message, isNotEmpty, reason: '$locale $key');
        expect(message, isNot(s.errGeneric), reason: '$locale $key');
        if (key != 'core.internal.unexpected') expect(message, isNot(s.errInternal), reason: '$locale $key');
      }
    }
  });

  test('every describe arm returns exactly one complete localization message', () {
    final source = File('lib/src/ui/kit.dart').readAsStringSync().split('String describe(').last;
    final body = source.split('return switch (key) {').last.split('};').first;
    final arms = body.split('=>').skip(1).map((arm) => arm.split(',').first.trim());
    expect(arms.length, greaterThan(50));
    final message = RegExp(r'^s\.[a-zA-Z]\w*(?:\(failure\.httpStatus \?\? 0\))?$');
    for (final arm in arms) {
      expect(message.hasMatch(arm), isTrue, reason: 'Use one l10n message, without concatenation: $arm');
    }
    final getters = arms.map((arm) => RegExp(r'^s\.(\w+)').firstMatch(arm)![1]!).toSet();
    final locales = Directory('lib/l10n').listSync().whereType<File>().where((f) => f.path.endsWith('.arb'));
    expect(locales.length, 32);
    for (final file in locales) {
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in getters) {
        expect(arb[key], isA<String>().having((s) => s.trim(), 'translation', isNotEmpty), reason: '${file.path} $key');
      }
    }
  });

  test('describe messages contain one cause without a second sentence in every locale', () {
    final source = File('lib/src/ui/kit.dart').readAsStringSync().split('String describe(').last;
    final keys = RegExp("'([a-zA-Z][a-zA-Z0-9_.]*)'").allMatches(source).map((m) => m[1]!).toSet()
      ..add('unknown.failure');
    final secondSentence = RegExp(r'[.!?。！？۔।։]\s*\S|[\r\n]');
    final thaiInstruction = RegExp(r' (โปรด|ลอง|ตรวจสอบ|เลือก|นำเข้า|อัปเดต|รีเฟรช|ลบ|ขอรับ|เปิด|โหลด|บันทึก)');
    for (final locale in S.supportedLocales) {
      final s = lookupS(locale);
      for (final key in keys) {
        for (final status in [null, 403, 503]) {
          final message = describe(s, CoreFailure(key, httpStatus: status));
          expect(secondSentence.hasMatch(message), isFalse, reason: '$locale $key: $message');
          if (locale.languageCode == 'th') {
            expect(thaiInstruction.hasMatch(message), isFalse, reason: '$locale $key: $message');
          }
        }
      }
    }
    expect(
      describe(lookupS(const Locale('ru')), const CoreFailure('core.network.timeout')),
      'Сервер не ответил вовремя',
    );
    expect(
      describe(lookupS(const Locale('ru')), const CoreFailure('core.subscription.empty')),
      'В подписке нет серверов',
    );
  });

  test('HTTP messages localize known and unknown status without a fabricated code', () {
    for (final locale in S.supportedLocales) {
      final s = lookupS(locale);
      for (final key in ['app.http_status', 'core.subscription.status']) {
        for (final status in [null, 400, 403, 429, 503]) {
          final text = describe(s, CoreFailure(key, httpStatus: status));
          expect(text, s.errHttpStatus(status ?? 0), reason: '$locale $key $status');
          expect(text, isNot(contains('{status}')));
          if (status == null) {
            expect(text, isNot(contains('HTTP 0')));
          } else {
            expect(text, contains('$status'));
          }
        }
      }
    }
  });

  test('native exceptions retain their class without exposing error details', () {
    final samples = <Object, String>{
      TimeoutException('private'): 'core.network.timeout',
      const SocketException('private'): 'core.network.failed',
      const HandshakeException('private'): 'core.tls.certificate',
      const CertificateException('private'): 'core.tls.certificate',
      const HttpException('private'): 'app.http_status',
      ClientException('private'): 'core.network.failed',
      const FileSystemException('private', '/private'): 'app.file_access',
      const FormatException('private'): 'core.request.invalid',
      const GrpcError.cancelled(): 'core.request.cancelled',
      const GrpcError.deadlineExceeded(): 'core.request.deadline_exceeded',
      const GrpcError.unavailable(): 'app.core_unavailable',
      const GrpcError.unimplemented(): 'core.api.version_mismatch',
      const GrpcError.resourceExhausted(): 'core.request.too_large',
      const GrpcError.resourceExhausted('resource_exhausted core.probe.too_many'): 'core.probe.too_many',
      const GrpcError.unavailable('unavailable core.engine.start_failed'): 'core.engine.start_failed',
      const GrpcError.invalidArgument('invalid_argument core.plan.dns_invalid'): 'core.plan.dns_invalid',
    };
    for (final entry in samples.entries) {
      expect(CoreFailure.from(entry.key).key, entry.value);
      expect(CoreFailure.from(entry.key).toString(), isNot(contains('private')));
    }
  });

  test('HTTP status is retained without copying redacted detail into a notification', () {
    final failure = CoreFailure.fromWire(
      SoraError(userMessageKey: 'core.subscription.status', detailRedacted: 'subscription: the provider answered 403'),
    );
    expect(failure.httpStatus, 403);
    expect(describe(lookupS(const Locale('ru')), failure), lookupS(const Locale('ru')).errHttpStatus(403));
  });

  testWidgets('transient background failures show state, stay silent and clear on recovery', (tester) async {
    final sora = await start();
    final notices = <Object>[];
    final subscription = sora.messages.listen(notices.add);
    addTearDown(subscription.cancel);
    for (final source in ['stats', 'probe', 'benchmark', 'logs', 'connections', 'extension-workers', 'profiles']) {
      sora.reportFailure(const SocketException('private'), mode: FailureMode.background, source: source);
      expect(sora.backgroundFailure(source)?.key, 'core.network.failed');
    }
    await tester.pumpWidget(
      SoraScope(
        sora: sora,
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: buildTheme(Brightness.light),
          home: const Scaffold(body: BackgroundFailureState(source: 'stats')),
        ),
      ),
    );
    expect(find.text(sora.strings.extErrNetwork), findsOneWidget);
    expect(sora.history, isEmpty);
    expect(notices, isEmpty);
    for (final source in ['stats', 'probe', 'benchmark', 'logs', 'connections', 'extension-workers', 'profiles']) {
      sora.recovered(source);
      expect(sora.backgroundFailure(source), isNull);
    }
    await tester.pump(const Duration(hours: 25));
    expect(find.text(sora.strings.extErrNetwork), findsNothing);
    expect(sora.history, isEmpty);
  });

  testWidgets('one failed measurement does not become a persistent outage just by aging', (tester) async {
    final sora = await start();
    const failed = CoreFailure('core.network.timeout');
    sora.reportFailure(failed, mode: FailureMode.background, source: 'probe');
    await tester.pump(const Duration(days: 2));
    expect(sora.history, isEmpty);
    sora.reportFailure(
      failed,
      mode: FailureMode.background,
      source: 'probe',
      since: DateTime.now().subtract(const Duration(minutes: 16)),
    );
    expect(sora.history, hasLength(1));
    sora.reportFailure(failed, mode: FailureMode.background, source: 'probe');
    expect(sora.history, hasLength(1));
    sora.recovered('probe');
  });

  testWidgets('one service outage across streams notifies after 15 seconds, once per reason', (tester) async {
    final sora = await start();
    for (final source in ['core', 'stats', 'logs', 'connections']) {
      sora.reportFailure(const GrpcError.unavailable(), mode: FailureMode.background, source: source);
    }
    await tester.pump(const Duration(seconds: 14));
    expect(sora.history, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(sora.history, hasLength(1));
    expect(sora.history.single.failureKey, 'app.core_unavailable');
    sora.reportFailure(CoreFailure.unavailable, mode: FailureMode.background, source: 'core');
    await tester.pump(const Duration(minutes: 2));
    expect(sora.history, hasLength(1));
    sora.recovered('core');
    expect(sora.backgroundFailure('core'), isNull);
    sora.reportFailure(CoreFailure.unavailable, mode: FailureMode.background, source: 'core');
    sora.recovered('core');
    await tester.pump(const Duration(seconds: 30));
    expect(sora.history, hasLength(1));
  });

  testWidgets('subscriptions wait 24 hours, survive restarts, deduplicate manual and watch failures', (tester) async {
    final sora = await start();
    const error = CoreFailure('core.subscription.fetch_failed');
    sora.reportFailure(
      error,
      mode: FailureMode.background,
      source: 'subscription:test',
      action: 'subscription',
      argument: 'test',
    );
    await tester.pump(const Duration(hours: 23));
    expect(sora.history, isEmpty);
    await tester.pump(const Duration(hours: 1));
    expect(sora.history, hasLength(1));
    sora.reportFailure(error, mode: FailureMode.background, source: 'subscription:test');
    expect(sora.history, hasLength(1));
    final resumed = Sora(sora.settings);
    addTearDown(resumed.dispose);
    resumed.reportFailure(error, mode: FailureMode.background, source: 'subscription:test');
    await tester.pump(const Duration(hours: 25));
    expect(resumed.history, hasLength(1));
    resumed.recovered('subscription:test');
    expect(jsonDecode(resumed.settings.subscriptionFailures), isEmpty);

    sora.recovered('subscription:test');
    sora.reportFailure(
      error,
      mode: FailureMode.background,
      source: 'subscription:test',
      action: 'subscription',
      argument: 'test',
    );
    sora.reportFailure(
      error,
      mode: FailureMode.action,
      source: 'subscription:test',
      action: 'subscription',
      argument: 'test',
    );
    expect(sora.history, hasLength(2));
    await tester.pump(const Duration(hours: 25));
    expect(sora.history, hasLength(2));
    expect(sora.history.first.action, 'subscription');
    sora.recovered('subscription:test');
  });

  testWidgets('explicit actions report immediately and repeated retry still reports', (tester) async {
    final sora = await start();
    final messages = <Object>[];
    final stream = sora.messages.listen(messages.add);
    addTearDown(stream.cancel);
    for (var i = 0; i < 2; i++) {
      sora.reportFailure(const HandshakeException('secret'), mode: FailureMode.action, source: 'save');
      expect(sora.history.length, 1);
      expect(sora.history.first.title, sora.strings.errTls);
    }
    await tester.pump();
    expect(messages, hasLength(2));
    sora.reportFailure(const GrpcError.cancelled(), mode: FailureMode.action);
    expect(sora.history, hasLength(1));
    sora.recovered('save');
  });

  testWidgets('repeated action failures keep one visible toast and one history entry', (tester) async {
    final sora = await start();
    await sora.settings.completeTour();
    sora.settings.animations = false;
    await tester.pumpWidget(SoraApp(sora: sora));
    await tester.pumpAndSettle();
    for (var i = 0; i < 20; i++) {
      sora.reportFailure(const CoreFailure('core.tls.certificate'), mode: FailureMode.action, source: 'save');
    }
    await tester.pumpAndSettle();
    expect(find.byType(Dismissible), findsOneWidget);
    expect(sora.history, hasLength(1));
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byType(Dismissible), findsNothing);
    sora.reportFailure(const CoreFailure('core.tls.certificate'), mode: FailureMode.action, source: 'save');
    await tester.pumpAndSettle();
    expect(find.byType(Dismissible), findsOneWidget);
    expect(sora.history, hasLength(1));
    sora.recovered('save');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('action toasts show the complete short cause in every locale', (tester) async {
    addTearDown(tester.view.reset);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(420, 900);
    for (final locale in S.supportedLocales) {
      final sora = await start();
      await sora.settings.completeTour();
      sora.settings
        ..language = locale.toString()
        ..animations = false;
      await tester.pumpWidget(SoraApp(sora: sora));
      await tester.pumpAndSettle();
      sora.reportFailure(
        const CoreFailure('core.subscription.status', httpStatus: 403),
        mode: FailureMode.action,
        source: 'subscription:test',
      );
      await tester.pumpAndSettle();
      final text = find.text(sora.strings.errHttpStatus(403));
      expect(text, findsOneWidget, reason: '$locale');
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: text, matching: find.byType(RichText)),
      );
      expect(paragraph.maxLines, isNull, reason: '$locale');
      expect(paragraph.didExceedMaxLines, isFalse, reason: '$locale');
      final frame = tester.getRect(find.byType(Dismissible));
      expect(tester.getRect(text).bottom, lessThanOrEqualTo(frame.bottom));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a persisted subscription failure older than a day reports once and reports a changed cause', (
    tester,
  ) async {
    final sora = await start();
    sora.settings.subscriptionFailures = jsonEncode({
      'subscription:test': {'since': DateTime.now().subtract(const Duration(hours: 25)).toIso8601String()},
    });
    for (final key in ['core.network.timeout', 'core.network.timeout', 'core.subscription.no_servers']) {
      sora.reportFailure(CoreFailure(key), mode: FailureMode.background, source: 'subscription:test');
    }
    expect(sora.history, hasLength(2));
    expect(sora.history.first.failureKey, 'core.subscription.no_servers');
    sora.recovered('subscription:test');
  });

  testWidgets('notifications and UI resolve unsupported and Chinese system locales identically', (tester) async {
    final sora = await start();
    await sora.settings.completeTour();
    sora.settings.language = 'system';
    await tester.pumpWidget(SoraApp(sora: sora));
    for (final locales in [
      [const Locale('xx'), const Locale('ru')],
      [const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')],
      [const Locale('xx')],
    ]) {
      tester.platformDispatcher.localesTestValue = locales;
      await tester.pumpAndSettle();
      expect(S.of(tester.element(find.byType(ShellScope))).localeName, sora.strings.localeName);
      if (locales.first.languageCode == 'xx') {
        expect(sora.locale.languageCode, locales.length == 2 ? 'ru' : 'en');
      }
    }
    await tester.pumpWidget(const SizedBox());
    tester.platformDispatcher.clearLocalesTestValue();
  });

  test('plural numbers render in every locale and background strings use the selected language', () async {
    final sora = await start();
    for (final locale in S.supportedLocales) {
      final s = lookupS(locale);
      for (final count in [0, 1, 2, 5, 21]) {
        for (final message in [
          s.expiresIn('Test', count),
          s.groupBest(count),
          s.connConnectionsCount(count),
          s.leakTestFound(count),
        ]) {
          expect(message, isNot(contains('#')), reason: '$locale $count');
        }
      }
    }
    sora.settings.language = 'zh_Hant';
    expect(describe(sora.strings, const CoreFailure('app.speedtest_page')), contains('頁面'));
    sora.settings.language = 'ru';
    expect(describe(sora.strings, const CoreFailure('app.speedtest_page')), startsWith('Страница'));
    expect(sora.strings.expiresIn('Test', 1), contains('1 день'));
  });
}
