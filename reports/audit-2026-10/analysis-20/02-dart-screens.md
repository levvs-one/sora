# Аналитик №2: Dart-экраны sora — отчёт

**Зона:** `app/lib/src/ui/` (35 файлов, ~12600 строк). **Ветка:** `bugfix/audit-2026-10-19`.
**Метод:** read-only, файл за файлом; находки POWER-RUN/REVIEW-5PASS не дублируются (проверено по обоим отчётам и partials).
**Оговорка:** во время анализа смежный агент начал переписывать `sync.dart` в рабочем дереве (F9-переделка по заказу владельца: 256 → 740 строк, незакоммичено). Номера строк ниже — по коммиту, если не сказано иное; пункт про F9 помечен отдельно.

---

## Вердикт

Фундамент сильный: `kit.dart` — образцовый дизайн-системный набор (Pressable/Tile/SwitchTile/ChoiceTile/LinkTile/Segments/Screen/Group/confirm/push/describe), loading/error/empty есть везде, l10n покрыт, a11y продумана. Но волны фич F1–F11 оставили три класса слопа:

1. **Навигационная регрессия** — F10-коммит выкинул экран «Соединения» из сайдбара, оставив мёртвый слот в `pages`.
2. **Копипаста виджетов** — один и тот же стиль пунктов меню скопирован 6 раз, `_note` ×4, empty-state ×5.
3. **Фрагментация каналов обратной связи** — сырой `SnackBar` в 4 экранах мимо фирменного тост-пайплайна, 3 семейства диалогов, 5 стилей кнопок.

Ничего архитектурного, но пункт 1 — это «экран ≠ реализовано», главный враг по критериям.

---

## Сильные стороны

- **kit.dart (722 строки) — лучший файл зоны.** Единые Pressable (hover/press/focus, клавиатура), Tile/SwitchTile/ChoiceTile/LinkTile, Segments с анимированным индикатором, Screen с back-кнопкой и ограничением ширины 880, `confirm()` с destructive-вариантом, `push()` с уважением к Motion, `describe()` — семантический маппинг всех CoreFailure. Экраны, которые им пользуются (dns, obfs, leaktest, chains), выглядят и ведут себя одинаково.
- **Честные фолбэки для ключей ядра:** `_checkLabel`/`_checkHint` (dns.dart:29), `_testLabel` (leaktest.dart:20), `_reasonText` (censor.dart:19), `_categoryLabel` (store_screen.dart:470) — неизвестный ключ нового ядра никогда не рендерит пустую строку.
- **Спокойные ошибки как философия:** dns/leaktest/obfs/censor сознательно не красят ошибки в красное, используют нейтральный ink2 (комментарии «never shown raw or in red» — dns.dart:206, leaktest.dart:212). Нейтральный `_note` вместо красного алерта — продуманное решение.
- **Состояния везде:** loading/error/empty/«needs connection» разобраны на dns, obfs, leaktest, logs, benchmark, connections, panel (честный `extPanelUnavailable`).
- **Дисциплина mounted/revision:** `logs.dart` — revision-счётчик против гонок `_reload`/`_older`, `_arrive` с O(1)-дедупом; connections — `!mounted`-гарды в поллинге.
- **l10n:** пользовательских строк мимо `S.of` почти нет (найденные единицы — ниже, пункт 14).

---

## Слоп/проблемы

### HIGH

**H1. Мёртвый слот навигации: ConnectionsScreen выкинут из сайдбара, `pages[2]` недостижим**
- `shell.dart:47` — `static const _sectionOrder = [0, 6, 8, 4, 1, 3, 5, 7];` — индекса 2 нет.
- `shell.dart:264` — `pages[2]` = `const ConnectionsScreen()` всё ещё в списке.
- `_select()` вызывается только с членами `_sectionOrder` (shell.dart:230, 467) или литералом 5 (shell.dart:238); `_section` (shell.dart:53, 106, 166) никогда не равен 2.
- История: в релизе 1.0.7 (`0f56848`) было `_sectionOrder = [0, 6, 4, 1, 3, 5, 7, 2]` — «Соединения» были 8-м пунктом (Ctrl+8). F10-коммит `4452141` добавил Extensions на индекс 8 и **молча выкинул 2**, чтобы уместиться в 8 цифр клавиатуры.
- Почему плохо: 372-строчный экран после реворка F4 (статистика, группировка по процессам, контекстное меню) существует, но недоступен из главной навигации; единственный путь — Настройки → секция лога → «Соединения» (`settings_screen.dart:398`). Это ровно «экран ≠ реализовано». POWER-RUN №2 заявлял «проверено 32 флоу, все экраны» — и пропустил это.
- Чинить: либо вернуть 9-й пункт навигации (Ctrl+9, сайдбар уже скроллится), либо удалить мёртвый `pages[2]`.

### MEDIUM

**M1. Театр F9 на уровне экрана (зафиксировано по коммиту; в рабочем дереве уже чинится)**
- `sync.dart:26` (коммит): строки обещают несуществующее — `syncSecureNote` = «End-to-end encrypted channel. No accounts, no cloud servers», `syncWhatBody` = «Subscriptions, rules, settings and network profiles», `syncEmpty` = «…keep subscriptions, rules and settings in sync».
- `sync.dart:197-216` (коммит): `SyncShowCodeScreen` показывает **вечный спиннер** «Waiting for the other device…», который не может завершиться никогда — демона нет. Док-комментарий в коде честно признаёт unwired-статус, но пользователь видит обещания, а не комментарий.
- Это не дубль POWER-RUN №4 (там — контрактный уровень); здесь — конкретные dummy-аффордансы экрана.
- Статус: смежный агент прямо сейчас ведёт F9-переделку в рабочем дереве (файл 256 → 740 строк, `sync_daemon.dart`, health-check localhost API, честные состояния). После мержа перепроверить; до мержа — не трогать.

**M2. Стиль пунктов меню скопипащен 6 раз, ширина уже разъехалась (190/200/220)**
- `kit.dart:447` (`ChoiceTile`, `Size(220, 40)`), `servers.dart:100` (190×40), `servers.dart:601` (`_item`, 190×40), `connections.dart:356` (`_menuItem`, 190×40), `logs.dart:364,383` (190×40), `rules_screen.dart:125` (`style()`, 200×40).
- Один и тот же `ButtonStyle(minimumSize, shape r9, overlayColor hover, padding)` — шесть копий, три ширины. Любая правка ховера/радиуса потребует шести правок.

**M3. `_note` — один виджет, четыре копии**
- `dns.dart:211`, `obfs.dart:123`, `leaktest.dart:203` — идентичны до строки (Group > Padding 12 > иконка 18 ink2 + текст secondary ink2).
- `addserver.dart:195` — та же структура, но **без** Group и с другими отступами (12,8,12,12). Копии уже дрейфуют.

**M4. Empty-state — один виджет, пять копий**
- `profiles.dart:91`, `sync.dart:105` (коммит), `chains.dart:76` — Group > Padding 24 > Icon(size 40, weight 400, ink3) + 12 + центрированный текст.
- `censor.dart:68` (`_EmptyState`) — тот же силуэт, но Padding vertical 48 и `weight` не задан.
- `extensions/panel_screen.dart:343` — failure-вариант той же формы.
- Пять мест, где «пусто» выглядит чуть-чуть по-разному без причины.

**M5. Сырой `SnackBar` в обход фирменного тост-пайплайна**
- `chains.dart:234,247`, `profiles.dart:252,261,267`, `extensions/detail_screen.dart:325,343,545`, `sync.dart:43,76` (коммит).
- В приложении есть канонический канал: `sora.recordNotification(AppNotification(...))` → `NotificationToasts` (toastification, топ-справа) + история в «Уведомлениях». Сырые снекбары — второй визуальный язык, без истории, без экшенов. Успех/инфо-фидбек должен идти тем же путём, что ошибки.

**M6. Три семейства диалогов**
- `confirm()` / `showFieldSheet()` (kit.dart:252, subscription_sheet.dart:37) — r26, `palette.raised`, фирменные кнопки.
- Сырой `Dialog` r16: `modes.dart:31`, `store_screen.dart:96,219,262` (прогресс/ошибка/URL), `subscription.dart:318` (`_ServerPicker`), `detail_screen.dart:293` (`_confirm`).
- У `_confirm` свой `extCancel` вместо `s.cancel` (см. M8). Хром диалогов разъезжается: r26 vs r16, raised vs surface.

**M7. Пять стилей кнопок и два — свитчей**
- `PrimaryButton` (kit), `_QuietButton` (detail_screen.dart:380, outlined-пилюля только для расширений), `_FixButton` (leaktest.dart:346, «компактный PrimaryButton» r18), Material `TextButton`/`OutlinedButton` (modes.dart:89,115; about.dart:57,190).
- `store_screen.dart:651` — Material `Switch` в списке установленных расширений, тогда как весь остальной апп — `CupertinoSwitch` через `SwitchTile`. Два разных тумблера в одном приложении.

**M8. Дублирующийся l10n-ключ `extCancel`**
- `app_en.arb:377` `"extCancel": "Cancel"` — дословный дубль `app_en.arb:21` `"cancel": "Cancel"`. Используется только в `detail_screen.dart:305`. ×31 локаль мусора.

**M9. Чужие ключи в empty-состояниях (работает случайно)**
- `connections.dart:138` — пустой экран соединений показывает `s.logsEmpty` («Nothing here»).
- `language.dart:362` — пустой поиск языка показывает `s.speedtestEmpty` («No matches. Change the search»).
- Текст в EN подходит, но ключи семантически чужие: правка копии для логов сломает экран соединений. Нужен общий `emptySearch`/`emptyHere` или свои ключи.

### LOW

**L1. Валидация показывает заголовок поля вместо сообщения** — `chains.dart:235` `SnackBar(content: Text(s.chainName))`, `profiles.dart:262` `Text(s.profileName)`. Пользователь видит «Chain name» как текст ошибки — ноль информации.

**L2. Удалённая подписка → пустой тупик** — `subscription.dart:56-58`: `SubscriptionScreen` для несуществующего id рендерит пустой `Screen(title: s.subscriptions)`. Сценарий реален: открыть настройки подписки → удалить её из меню серверов → вернуться назад. Честно — auto-pop или состояние «удалено».

**L3. Двойной affordance закрытия соединения** — `connections.dart:340-349`: в строке есть и ⋮-меню с пунктом «Закрыть», и отдельная кнопка ✕ с тем же действием. Шум в каждой строке.

**L4. Захардкоженные отображаемые строки**
- `modes.dart:74` — `'TUN'` вместо `s.tunMode` (ключ существует).
- `logs.dart:461` — `'tun': 'TUN'`, `'dns': 'DNS'`, `'core': 'SoraCore'` вперемешку с l10n-значениями.
- `'—'` как плейсхолдер: `connections.dart:189,215`, `benchmark.dart:177`, `chains.dart:351`.
- `modes.dart:244,254` — карты подписей TUN-стеков продублированы, порядок разный (mihomo: mixed/system/gvisor/mips; xray: gvisor/system/mixed/mips) — дефолтный выбор визуально прыгает.

**L5. `Icons.` вместо `Symbols.`** — `settings_screen.dart:406` `Icons.chevron_right_rounded`; весь остальной апп на Material Symbols. Единственное место.

**L6. Три хрома поисковых полей** — filled r8 (`servers.dart:120`, `speedtest.dart`, `language.dart`), `CupertinoSearchTextField` r12 (connections, logs), outline r12 без заливки (`store_screen.dart:449`). Магазин расширений выбивается.

**L7. Раскол философии цвета ошибок** — валидация красная (`Styles.dangerCaption`: addserver.dart:239, subscription_sheet.dart:194), а сбои ядра сознательно нейтральные (dns/leaktest/obfs). Либо «спокойный апп без красного», либо нет.

**L8. Мёртвый `ShellScope.of`** — `shell.dart:35` определён, но вызовы идут через сырой `dependOnInheritedWidgetOfExactType<ShellScope>()` (`speedtest.dart:61`) и `getInheritedWidgetOfExactType` (`settings_screen.dart:250`).

**L9. Приватный доступ через границы стейтов** — `store_screen.dart:590-611`: `_ExtensionsBodyState._installFromCatalog` дёргает `state._showProgress` / `state._installBytes` — приватные члены чужого `State`. Либо вынести в хелпер, либо сделать API стора.

**L10 (подтверждение, не новое).** `notifications_screen.dart:52` — `DateFormat('dd.MM.yyyy  HH:mm')` захардкожен для всех локалей. Уже в REVIEW-5PASS как спека — подтверждаю, чинить вместе с остальными форматами.

---

## Ранжированные рекомендации

1. **Вернуть «Соединения» в навигацию (H1).** Добавить 9-й пункт (`_sectionOrder`, Ctrl+9) вместо тихого удаления. Мёртвый `pages[2]` — либо оживить, либо удалить. Это единственная High-находка; всё остальное — гигиена.
2. **Свести копипасту в kit (M2–M4, ~1 час работы):** `MenuItemButton`-стиль → `kit.dart` (один `menuItemStyle()`), `_note` → `InfoNote(icon, text)`, empty-state → `EmptyState(icon, message)`. Убрать 15+ дублирующихся блоков.
3. **Унифицировать фидбек (M5–M7):** снекбары → `recordNotification`; диалоги → r26-хром `confirm`/`showFieldSheet`; кнопки → PrimaryButton + один quiet-вариант в kit; `Switch` → `CupertinoSwitch`.
4. **Зачистить l10n (M8, M9, L4):** удалить `extCancel` (×31 локаль), дать свои ключи empty-состояниям, `'TUN'` → `s.tunMode`.
5. **Дождаться мержа F9-переделки и перепроверить M1** на новом `sync.dart` (вечный спиннер, строки обещаний, честные состояния демона).
6. **Мелочи (L1–L3, L5, L6, L8, L9):** осмысленные тексты валидации; auto-pop удалённой подписки; убрать дубль ✕ в строках соединений; `Symbols` в settings; единый стиль поиска; убрать `ShellScope.of` или перевести вызовы на него; распутать кросс-стейт в store_screen.

## Что сознательно не трогал

- `sora.dart`/`sync.dart` в рабочем дереве меняются смежным агентом — анализ только коммита.
- Подтверждённые чужие спеки (R5-SD-2-1 уже закрыт: поле 16 в Dart-protobuf есть; `BypassSettings`, CSP панелей, формат даты) — не дублирую.
- Отклонённое фильтром слопа POWER-RUN (машинный перевод, confirm на очистку логов) — не предлагаю повторно.
