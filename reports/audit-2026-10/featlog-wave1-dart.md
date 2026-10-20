# Wave 1 UI (Dart) — featlog

Ветка: `bugfix/audit-2026-10-19`. Пути: только `sora/app`.
Flutter SDK в окружении нет — код вычитан вручную (многопроходно), сборка невозможна.

## F1: QR-шеринг и QR-сканирование — DONE

- `pubspec.yaml`: `qr_flutter: ^4.1.0`, `mobile_scanner: ^5.2.3`.
- `app/lib/src/ui/qr.dart` (новый): `QrShareScreen` (QR с коррекцией ошибок H,
  белая quiet zone, копирование ссылки с состоянием «скопировано», ссылка скрыта
  по умолчанию + переключатель показать/скрыть, предупреждение) и `QrScanScreen`
  (`MobileScanner` + переключатель фонарика + вставка из буфера + аккуратный экран
  при отсутствии камеры + инлайн-сообщение о невалидном QR нейтральным цветом,
  без красного). Результат сканирования идёт в существующий `parseImportLink` →
  `showSubscriptionSheet`, новых парсеров нет.
- `app/lib/src/ui/servers.dart`: кнопка сканирования в actions + пункт меню
  подписки «Поделиться QR-кодом» через новый `Sora.fetchSubscriptionLink(id)`
  (переиспользует `GetSubscriptionLink`, паттерн ошибок как у соседних RPC).
- **Пропущено**: QR-шеринг отдельного сервера — нет RPC `ExportServerLink`,
  формат ссылки выдумывать запрещено планом. Декодирование QR из файла
  изображения — план разрешал пропустить, риск `zxing2` без возможности тестов.

## F4: экран активных соединений — DONE

- `app/lib/src/ui/connections.dart` (переписан): шапка статистики (скорость ↑/↓
  через существующий `sora.readStats()` на 1-секундном таймере только пока экран
  открыт — урок M17; счётчик активных), переключатель «списком / по процессам»
  (`Segments`), сворачиваемые группы процессов по трафику, контекстное меню
  строки (Закрыть / Скопировать хост / Добавить правило), one-tap закрытие
  сохранено.
- `app/lib/src/ui/rules_screen.dart`: `addRuleSheet(context, {initialDestination})`
  вынесена на верхний уровень для предзаполнения из соединений.

## F3: DNS-менеджер (UI) + привязка к backend CheckDnsLeaks — DONE

Backend (параллельный Go-агент): RPC `CheckDnsLeaks` в proto, API 1.7 → 1.8.
Dart-codegen перегенерировать нечем — обёртка написана вручную строго по паттерну
существующего сгенерированного кода:

- `app/lib/src/core/link.dart`: `apiVersion` 1.7 → 1.8.
- `core_control.pb.dart`: классы `DnsLeakCheck` (6 полей: id/label/expected/
  actual/leaked/fix_hint), `CheckDnsLeaksRequest` (api_version/
  control_authenticator/session_id), `CheckDnsLeaksResponse` (repeated checks,
  error). Индексы полей (`$_getSZ`/`$_getBF`/`$_setBool` и т.д.) сверены с
  соседними классами.
- `core_control.pbgrpc.dart`: клиентский метод `checkDnsLeaks` + дескриптор
  `_$checkDnsLeaks` + серверные абстракты `checkDnsLeaks_Pre`/`checkDnsLeaks` +
  `$addMethod` (порядок — как в proto, метод последний в сервисе).
- `core_control.pbjson.dart`: `$json`-константы и base64-дескрипторы для трёх
  сообщений. Энкодер самопроверен: перекодировка существующего дескриптора
  `GetSubscriptionLinkResponse` совпала побайтово; поля в новых дескрипторах
  сверены парсингом. Файл никем не импортируется (только reflection), но оставлен
  консистентным.
- `app/lib/src/sora.dart`: `Sora.checkDnsLeaks()` → `({List<DnsLeakCheck> checks,
  CoreFailure? failure})`; паттерн `_link`/`sessionId`/`controlAuthenticator`
  как у соседних RPC; смена сессии mid-flight трактуется как недоступность;
  ошибки только через `CoreFailure`.
- `app/lib/src/ui/dns.dart` (переписан на реальный RPC): пресеты резолверов,
  редактор custom-списка, кнопка проверки. Стаб `DnsLeakReport`/`checkDnsLeaks`
  удалён (конфликтовал бы именем с generated-классом).
  - `label`/`fix_hint` — ключи локализации (`dnsLeak.check.*`, `dnsLeak.fix.*`),
    резолвятся в `_checkLabel`/`_checkHint`; неизвестные ключи показываются
    как есть (не blank), пустой `fix_hint` = подсказки нет.
  - `fix_hint` при `leaked=false` — предупреждение: иконка warning в спокойных
    ink-цветах, НЕ красная ошибка (требование parent + правило пользователя
    «без красного в интерфейсе»). Утечка (`leaked=true`) — warning-иконка и
    заголовок «Обнаружена утечка», тоже без красного.
  - Состояния: проверка не запущена (phase != connected) → нейтральная заметка
    «сначала подключитесь»; ошибка RPC → нейтральная заметка через
    `describe()`; loading — индикатор; empty быть не может (ядро всегда
    возвращает 3 проверки).
  - Дата последней проверки — `DateFormat.yMMMd(locale).add_Hm()` вместо
    сырого `toString()`.
- l10n: добавлены `dnsLeakCheckTunnelDns`, `dnsLeakCheckSystemResolvers`,
  `dnsLeakCheckKillSwitchDns`, `dnsLeakFixConfigureTunnelDns`,
  `dnsLeakFixReviewSystemResolvers`, `dnsLeakFixEnableKillSwitch`,
  `dnsCheckNeedsConnection`, `dnsExpected`, `dnsActual` (ru — русский, остальные
  29 — английский фолбэк для пайплайна перевода). Удалены ставшие ненужными
  `dnsFix`, `dnsCheckPending`, `dnsDetails` (проверено: ссылок не осталось).
  Консистентность проверена скриптом: arb — валидный JSON, все 30
  `strings_*.dart` реализуют все 292 геттера.

## F0: UX-аудит split-tunneling — DONE (без нового кода)

- Отчёт: `~/workspace/bug-hunt/reports/split-tunnel-ux.md` (вердикт: хорошо;
  композиция сценария 3 недокументирована — кандидат на будущую подсказку).
- Поправлен один «кривой момент»: пустое состояние program_picker было голой
  кнопкой Refresh — теперь поясняющий текст + кнопка (только существующие ключи).

## Прочие чистки (ревью-проход)

- `qr.dart`: удалён неиспользуемый `import '../sora.dart'`.
- `dns.dart`: удалён самоприсваивающий `_fix()` эпохи стаба — теперь подсказки
  ядра ведут пользователя, авто-«исправление» не выдумывает действия.

## Коммиты (все `[feature][sora-dart]`, пуша нет)

- `ec46bf4` l10n: 32 ключа F1/F3/F4 (31 язык)
- `ea2a0d3` F1: экраны QR-шеринга/сканирования
- `49dda8d` F1: точки входа QR в servers.dart + fetchSubscriptionLink
- `9852eff` F3: экран DNS-менеджера (первая версия, на стабе)
- `c9a66aa` F4: экран соединений
- `77337f4` F0: empty-state program_picker + отчёт аудита
- `9ae231e` F3: привязка к CheckDnsLeaks (API 1.8, ручная Dart-обёртка) + чистки

## Требует проверки на dev-машине (Flutter SDK)

1. `flutter analyze` — ноль предупреждений (особенно: неиспользуемые импорты в
   dns.dart, корректность `_$checkDnsLeaks`-дескриптора, switch-expressions).
2. `flutter build` (или `pub get` + запуск) — резолв `qr_flutter`/`mobile_scanner`.
3. Ручной QR-раундтрип: поделиться подпиской → сканировать → импорт через
   существующий флоу.
4. Ручной проход DNS-экрана: пресет → custom-редактор (валидация) → проверка
   при подключении (3 карточки, expected/actual, hint) → проверка без
   подключения (заметка) → killswitch-hint как warning, не ошибка.
5. Ручной регресс диплинков (sora://) — не должен был затронуться, но рядом.
6. Сверить имена иконок (`qr_code_scanner_rounded`, `flashlight_on_rounded`,
   `warning_rounded`, `info_rounded`, `more_vert_rounded`) и API
   `mobile_scanner` v5 / `qr_flutter` v4 (`MobileScannerController()`,
   `MobileScanner(controller:, onDetect: (BarcodeCapture), errorBuilder:)`,
   `toggleTorch()`, `QrImageView(data:, version: QrVersions.auto,
   errorCorrectionLevel: QrErrorCorrectLevel.H, size:)`).
7. При первой возможности — перегенерировать Dart-codegen через protoc-gen-dart
   и сдиффить с ручной обёрткой (ожидается совпадение).
