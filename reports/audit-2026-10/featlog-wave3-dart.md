# featlog-wave3-dart.md — Волна 3 UI (Dart)

Ветка `bugfix/audit-2026-10-19`, только `sora/app`. Коммиты `[feature][sora-dart]`, пуша нет.
Flutter SDK в окружении нет — весь код вычитан многопроходно: собственный лексер
проверил баланс скобок/строк/интерполяций во всех затронутых файлах, скрипты
проверили l10n (arb — валидный JSON, все 30 `strings_*.dart` реализуют все
абстрактные геттеры), вручную сверены сигнатуры виджетов (`Tile`, `LinkTile`,
`SwitchTile`, `Heading`, `RoundButton`, `Screen`, `showFieldSheet`, `confirm`).

## Коммиты

- `379d5e0` — l10n: 59 новых ключей (F5/F8/F9/F11 + общие `edit`/`remove`) в
  `app_en.arb`/`app_ru.arb`, абстрактном `S` и всех 30 `strings_*.dart`
  (ru переведено, остальные — английский фолбэк).
- `ac75f0b` — модели и проводка: `Settings`-ключи `networkProfiles`,
  `proxyChains`, `syncedDevices`, `zapretWithVpn`; `ProfilesStore`,
  `ChainsStore`, `SyncDevices` в `Sora` (паттерн `OverrideStore`);
  `applyProfile`/`applyProfileWithUndo`/`undoProfileApply`/`handleProfileMatched`/`refreshFingerprint`;
  `connectChain` (честная `CoreFailure('chainUnsupported')` до landing backend);
  `chainsSupported` (флаг `chainCapability`).
- `2dbf2a3` — F5 UI: `ui/profiles.dart` (список, строка «Сейчас: …»,
  редактор с триггерами SSID/шлюз/ASN, кнопка «запомнить текущие»,
  auto-apply); действия уведомлений `apply-profile`/`undo-profile`
  (спросить → применить → откат одним тапом).
- `9886a6b` — F8 UI: `ui/chains.dart` (список цепочек с оценкой задержки =
  сумма пингов; конструктор: мультиселект 2–3 серверов, drag-reorder,
  entry/exit-подписи, валидация `chainTooFew`/`chainTooMany`/`chainDuplicate`).
- `b7f8870` — F9 UI: `ui/sync.dart` («Мои устройства», показать/сканировать
  код, отозвать, время последнего синка, честный блок «что синхронизируется»);
  `QrScanScreen(onScanned:)` возвращает сырое значение вместо import-flow.
- `b43677f` — F11: тоггл «DPI-обход для прямого трафика» в `modes.dart`,
  виден только при `Platform.isLinux && serverlessAvailable` (иначе скрыт,
  не заглушка); навигация в `settings_screen.dart` (профили/цепочки/синк
  со счётчиками и бейджем активного профиля).

## Сознательные отклонения от спеки плана

- F8 «кнопка Проверить»: вместо неё — живая оценка задержки (сумма пингов),
  как требует Go-спека («отображать до подключения»). Отдельный probe всех
  серверов ради 2–3 хопов — расточительно; оценка обновляется при обычном
  probe с экрана серверов.
- F5 `GetNetworkFingerprint`/`ProfileMatched`: Go-сторона в работе у
  параллельного агента; Dart-приёмник готов (`refreshFingerprint`,
  `handleProfileMatched`), до landing показывает «Нет данных о сети», не гадает.
- F9: эфемерный X25519-ключ в QR-пейлоаде добавит Go sync-сервис
  (`encodePairPayload` принимает `key`, пока `null` — выдумывать ключевой
  материал в Dart было бы нечестно); формат `sora-sync://pair?v=1&token=…`
  зафиксирован и парсится обеими сторонами.

## Что проверить на dev-машине

1. `flutter analyze` — особенно новые файлы и правки `qr.dart`/`sora.dart`.
2. Флоу профилей: создать → триггеры → «запомнить текущие» → сохранить;
   уведомление «Применить?» → применить → «Отменить» (откат настроек).
3. Конструктор цепочек: выбор 2–3, drag-reorder, валидации, оценка задержки.
4. Синк: показать код → сканировать вторым устройством → имя → revoke;
   невалидный QR → аккуратная ошибка.
5. F11: тоггл виден только на Linux с доступным zapret; на других ОС —
   отсутствует (не disabled).
6. Иконки `wifi_rounded`, `link_rounded`, `devices_rounded`,
   `drag_handle_rounded`, `link_off_rounded` в material_symbols_icons.
