# Final audit — partial-08: Dart UI/UX/i18n/a11y (финальный проход)

**Зона:** `app/` (Flutter/Dart), ветка `bugfix/audit-2026-10-19`.
**Метод:** вычитка + скриптовые сверки (python/grep) по всему `app/lib/` (79 .dart вне generated, ~18,3 тыс. строк в `src/`), сверка с POWER-RUN / REVIEW-5PASS / FEATURE-REPORT.
**Оговорка про тулчейн (обязательная):** Flutter/Dart SDK на машине НЕТ. Компиляция, `flutter analyze`, `flutter test` НЕ выполнялись. Всё ниже — статические сверки и вычитка; перед мержем на dev-машине обязательны `flutter analyze` + `flutter build` + ручной прогон экранов.
**Дерево:** на момент аудита грязное чужим WIP (в т.ч. `app/lib/src/ext/*`, `app/lib/src/ui/extensions/*`, `app/lib/src/updates.dart`, `app/lib/src/ui/about.dart` — незакоммиченные правки смежников). Эти файлы только читались; выводы по ним относятся к рабочему дереву, а не к HEAD.

---

## 1. i18n полнота — таблицы

### 1.1 Структура (факт, уточняет «31 локаль» из задания)

| Единица | Количество |
|---|---|
| Абстрактных ключей в `S` (`app/lib/l10n/strings.dart`, template — `app_ru.arb`, см. `l10n.yaml`) | **661** (все — `String`, getters + методы с параметрами) |
| ARB-файлов `app_*.arb` | **32** |
| Записей в `S.supportedLocales` | **32** (30 языков + `zh` + `zh_Hans` + `zh_Hant`) |
| Сгенерированных `strings_*.dart` | **30** файлов; `strings_zh.dart` содержит 3 класса: `SZh` (полный, 661/661), `SZhHans` (315 оверрайдов поверх `SZh`), `SZhHant` (407 оверрайдов поверх `SZh`) — эффективная полнота Hans/Hant = 661/661 через наследование |

### 1.2 Полнота по локалям (ARB и generated Dart сверены независимо)

Для каждой локали: ключей = 661, missing = 0, ключей-сирот = 0, пустых значений = 0.
Плейсхолдеры: сверка по верхнеуровневым ICU-плейсхолдерам (`{name}`, `{count}`, `{days,...}` — с корректным парсингом plural-блоков) — **расхождений 0 во всех 32 ARB**. (Наивный regex даёт ложные «расхождения» на `groupOrdered`/`groupBest`/`expiresIn`/`leakTestFound` — это слова внутри plural-вариантов, не плейсхолдеры; в отчёте POWER-эпохи такие ложные срабатывания не разделялись.)

| Локаль | Ключей | Missing | Сироты | Пустые | Плейсхолдеры ≠ en | Совпадает с en (EN-fallback) |
|---|---|---|---|---|---|---|
| en | 661 | 0 | 0 | 0 | — | — (источник) |
| ru | 661 | 0 | 0 | 0 | 0 | **13** — все легитимны (см. 1.4) |
| ar | 661 | 0 | 0 | 0 | 0 | 391 |
| az | 661 | 0 | 0 | 0 | 0 | 405 |
| be | 661 | 0 | 0 | 0 | 0 | 393 |
| bn | 661 | 0 | 0 | 0 | 0 | 396 |
| de | 661 | 0 | 0 | 0 | 0 | 410 |
| es | 661 | 0 | 0 | 0 | 0 | 403 |
| fa | 661 | 0 | 0 | 0 | 0 | 397 |
| fr | 661 | 0 | 0 | 0 | 0 | 407 |
| hi | 661 | 0 | 0 | 0 | 0 | 392 |
| hy | 661 | 0 | 0 | 0 | 0 | 394 |
| id | 661 | 0 | 0 | 0 | 0 | 398 |
| it | 661 | 0 | 0 | 0 | 0 | 405 |
| ja | 661 | 0 | 0 | 0 | 0 | 396 |
| ka | 661 | 0 | 0 | 0 | 0 | 396 |
| kk | 661 | 0 | 0 | 0 | 0 | 393 |
| ko | 661 | 0 | 0 | 0 | 0 | 394 |
| ky | 661 | 0 | 0 | 0 | 0 | 399 |
| pl | 661 | 0 | 0 | 0 | 0 | 400 |
| pt | 661 | 0 | 0 | 0 | 0 | 401 |
| tg | 661 | 0 | 0 | 0 | 0 | 393 |
| th | 661 | 0 | 0 | 0 | 0 | 395 |
| tk | 661 | 0 | 0 | 0 | 0 | 399 |
| tr | 661 | 0 | 0 | 0 | 0 | 400 |
| uk | 661 | 0 | 0 | 0 | 0 | 399 |
| ur | 661 | 0 | 0 | 0 | 0 | 399 |
| uz | 661 | 0 | 0 | 0 | 0 | 402 |
| vi | 661 | 0 | 0 | 0 | 0 | 402 |
| zh | 661 | 0 | 0 | 0 | 0 | 394 |
| zh_Hans | 661 | 0 | 0 | 0 | 0 | 394 |
| zh_Hant | 661 | 0 | 0 | 0 | 0 | 394 |

Та же полнота подтверждена по generated Dart: в каждом `strings_*.dart` присутствуют все 661 имён (getters и методы), пустых (`''`) реализаций нет.

### 1.3 EN-fallback — осознанная политика, не дыра (Info)

388 ключей идентичны en-тексту **во всех** 30 не-en/ru локалях; ещё ~20–25 ключей на локаль — совпадения сверх этого ядра (короткие/технические строки). Непереведёнными (кроме en/ru) остаются целые группы новых фич:

| Группа ключей | Не переведено / всего |
|---|---|
| `ext*` | 132 / 133 |
| `sync*` | 48 / 48 |
| `customServer*` | 21 / 21 |
| `censor*` | 20 / 20 |
| `profile*` | 20 / 20 |
| `chain*` | 18 / 20 |
| `obfs*` | 18 / 18 |
| `leak*` | 17 / 17 |
| `dns*` | 23 / 24 |
| `benchmark*` | 2 / 2 |

Это прямое следствие фильтра слопа из POWER-RUN («машинный перевод — фейковое качество; EN-fallback лучше»): ключи присутствуют во всех локалях с английским текстом, падения/пустот нет. Полноценный перевод 29 локалей — работа переводчиков, не кодовый фикс. **Вердикт: не дефект полноты; зафиксирован как известный, осознанный объём.**

### 1.4 Исправлено в этом проходе — ru-дыра в rollback-строках (была Medium)

В ru-локали 4 строки обновлений оставались на английском (показываются в `about.dart:259–277` при откате обновления — пользовательский, тревожный сценарий):

- `updateRollbacking`, `updateRolledBack`, `updateRollbackError`, `updateRollbackCacheError`

**Фикс:** коммит `1c71376` `[final-audit]` — переводы добавлены синхронно в `app/lib/l10n/app_ru.arb` и в generated `strings_ru.dart` (плейсхолдеры `{version}`/`{fromVersion}` сохранены, JSON валиден, баланс скобок/кавычек проверен скриптом). После фикса в ru осталось 13 совпадений с en — все легитимные: `IPv6`, `DNS`, `User-Agent`, `ICMP echo`, бренды пресетов (Cloudflare/Google/Quad9/AdGuard), хинты (`443`, `https://…/extension.soraext`), трей-тултипы `Sora: {state}` (состояние подставляется локализованным).

В en дыр не найдено (en — источник). Для остальных локалей «недостающих» ключей нет — есть только EN-текст по п. 1.3, что паттерн локалей допускает по построению (каждый класс локали реализует все ключи; runtime-фолбэка gen_l10n не требуется).

---

## 2. Хардкод

**Итог: пользовательского хардкода практически нет.** Полный скриптовый проход по `app/lib/src/ui/**` (Text/title/hint/label/tooltip/SnackBar/dialog/throw-строки с буквенным текстом):

- Снеки (`SnackBar`) — все через `S.of(...)` либо через переменную с локализованным сообщением (`chains.dart`, `profiles.dart`, `sync.dart`, `extensions/*`).
- Тосты — заголовки/тела приходят из `AppNotification`, которые строятся через `describe()`/локализованные ключи (см. §3).
- Единственные литералы в UI: бренд `Sora` (`shell.dart:432`, `about.dart:86,361`), лицензия `GPL-3.0-only`, разделитель `—` (`benchmark.dart:177`), технические хинты полей (`tlshello`, пример URL `https://www.gstatic.com/generate_204` в `settings_screen.dart`), файловый фильтр `Windows application`/`soraext` (подписи системных диалогов выбора файла, `program_picker.dart:120`, `store_screen.dart:83`). Всё перечисленное — не проза для перевода; замечание уровня Trivial.

**Цвета ошибок:** `Colors.red*` / сырых цветов ошибок в UI нет. Все ошибки — через `Palette.danger` / `Styles.dangerCaption|dangerSecondary|dangerStrong`. Сырые `Color(0x…)` остались только внутри самой палитры (`design/theme.dart`) и в двух легитимных местах: белый фон под QR-код (`qr.dart:51`, `sync.dart:838` — QR требует белого) и `overlayColor: Colors.black` в туре (`tour.dart:51`).

**Сырые `exception.toString()` в UI:** не найдены. Все `catch`-пути в UI либо вызывают `describe(s, failure)` / `reportFailure(...)`, либо `describeSyncError(...)`, либо показывают `s.extErrGeneric` / `s.errGeneric`. `debugPrint(... $error)` — только в cleanup-пути спидтеста (`speedtest.dart`), в UI не попадает.

---

## 3. Состояния экранов и путь ошибок

**Путь ошибок — единый и правильный:** `GrpcError`/`answer.error.userMessageKey` → `CoreFailure` (`core/link.dart`) → `describe(S, CoreFailure)` (`ui/kit.dart:689`, полный switch по каталогу ключей ядра, включая `chainUnsupported`/`chainHopMissing`/…, fallback — `s.errGeneric`) → тост/нотификация/инлайн-нота. `Sora.reportFailure` дедуплицирует по источнику и пишет `AppNotification(title: errGeneric, body: describe(...))`.

| Экран | Loading | Error | Empty | Как ошибка показана |
|---|---|---|---|---|
| home | состояние фазы ядра | баннер/фаза `coreMissing`/`stateFailed` через `Sora.failure` | пустой список подписок → CTA добавления | `describe()` через уведомления |
| servers | спиннер probe/update на подписку (`CupertinoActivityIndicator`) | через `reportFailure` | пустые группы/серверы обработаны | уведомления |
| connections | первичная загрузка без «вечного пустого экрана» (комментарий+код, `connections.dart:84–87`) | `reportFailure(source: 'connections')` | `s.connEmpty` (`connections.dart:143`) | уведомления |
| dns | `_checking` + busy-кнопка | `_failure: CoreFailure?` → `_note(..., describe(s, _failure!))` | n/a (пресеты всегда есть) | инлайн-нота, спокойная (не красная) — осознанно |
| profiles | спиннер refresh fingerprint | состояние из `SoraScope` (fingerprint `known=false` → `s.networkUnknown`) | `s.profilesEmpty` с иконкой | состояние модели |
| chains | n/a (данные синхронны) | `connectChain` → `reportFailure('chain-connect')`; валидация хопов → локализованный switch в SnackBar | пустой список → заглушка; `chainUnsupported`-нота при отсутствии capability | уведомления + SnackBar (локализ.) |
| benchmark | прогресс `LinearProgressIndicator` + `benchmarkProgress(done,total)` текстом | недоступность → `s.errBenchmarkUnsupported` через CoreFailure-путь | `s.errNoServers` при пустом списке | локализовано |
| extensions store | `CircularProgressIndicator`; прогресс-диалог установки | каталог → `s.extCatalogError` + Retry (сырой `e.message` хранится в `_catalogError`, но **не показывается**); установка → `_mapInstallError` → `extErr*`-ключи | `extEmptySearch`/`extEmptyInstalled`; отдельное «catalog soon» состояние | локализовано |
| extensions detail | спиннеры действий | все `catch` → `s.extErrGeneric` SnackBar | пустые permissions — текст-заглушка | локализовано |
| sync | спиннеры статуса/операций (`_status == null` → progress) | `_opError = describeSyncError(...)`; отдельное `_error` на экране пейринга | `s.syncEmpty` при отсутствии пиров | локализованный заголовок (+ см. Low-2) |
| settings | n/a | log-settings → `reportFailure('log-settings')` | n/a | уведомления |
| about / updates | `checking`/стадии `UpdateStage` текстом | полный switch `UpdateError → update*Error`-ключи, включая исправленные rollback-строки | «нет релиза и проверки выкл.» — состояние обработано (`about.dart:319`) | локализовано |
| speedtest (доп.) | webview-загрузка с дедлайном/ретраями | `_failure` только из `s.speedtestPageFailed`/`s.speedtestUnavailable`, есть reload + «открыть в браузере» | n/a | локализовано |
| leaktest / obfs / censor (доп.) | `_checking`/busy | `CoreFailure` → `describe()` в нотах | история censor — empty-состояние | локализовано |

**Low-1 (даты):** два пользовательских формата даты захардкожены как `DateFormat('dd.MM.yyyy  HH:mm')` — `censor.dart:242` и `notifications_screen.dart:79`. Остальные экраны используют locale-aware `DateFormat.yMMMd(locale)` / `MMMMd` с `Intl.verifiedLocale`. Для en-US пользователя дата выглядит «по-европейски». Спека/фикс: заменить на `DateFormat.yMMMd(locale).add_Hm()` (паттерн уже есть в `sync.dart:379`). В фикс не брал: правка тривиальна, но оба файла вне l10n и визуальная сверка без тулчейна невозможна — риск нулевой, выгода косметическая; оставлено спекой по правилу «крупное/спорное — спека». `logs.dart` (`HH:mm:ss`, имена файлов `dd_MM_yyyy`) — технический журнал/имена файлов, не UI-локаль, замечанием не является.

**Low-2 (sync detail):** `describeSyncError` (`sync_api.dart:328`) для неизвестных HTTP-статусов возвращает `«{syncError}: {сырой английский текст демона}»`; аналогично `sync.dart:216` для `SyncBridgeException`. Это задокументированный в коде компромисс («daemon's raw message stays available as the error detail», `sync_api.dart:12`), не `exception.toString()`, но русскому пользователю в детали виден английский. Спека: показывать raw-текст только в развёрнутой детали/по тапу, заголовок — всегда локализованный.

---

## 4. a11y

### 4.1 Контраст danger — ЗАКРЫТО до этого прохода (не бренд-вопрос владельца)

POWER-RUN фиксировал светлый `danger` 4.34 < 4.5. Текущее состояние изменено коммитом `9e0f89d` `[detail-fix] danger AA contrast, onDanger token, semantic error text styles`:

| Токен | Было | Стало | Контраст (пересчитано WCAG в этом проходе) |
|---|---|---|---|
| light `danger` | `#E5332A` | **`#D02A22`** (`theme.dart:55`) | **5.20** vs `#FFFFFF`; **4.78** vs фон `#F5F5F7` — ≥ 4.5 ✅ |
| dark `danger` | `#FF5147` | `#FF5D52` (`theme.dart:70`) | 6.50 vs `#0B0B0C`; 5.62 vs surface `#1C1C1E` ✅ |
| `onDanger` | — | новый токен: белый на светлой, чёрный на тёмной; используется в destructive-кнопке (`kit.dart:297`) | ✅ |

Заодно пересчитаны вторичные тексты: light `ink2` 5.76 / `ink3` 5.36 vs белый (4.93 vs `#F5F5F7`), dark `ink2` 6.86 / `ink3` 6.50 vs фон — все ≥ 4.5. **Вывод: пункт «контраст — решение владельца» из POWER-RUN закрыт кодом; бренд-вопросом больше не является.** (Интересно: кандидат POWER-RUN `#D92D20` дал бы 4.44 vs `#F5F5F7` — выбранный `#D02A22` лучше.)

### 4.2 Semantics

- Базовые контролы в порядке: `Pressable` (фокус, Enter/Space, опция `semanticButton`), `RoundButton` — `Semantics(button:true, label:)`; все вызовы `RoundButton` на ключевых экранах передают label (скриптовая проверка «без label» дала только ложные срабатывания из-за скобок в интерполяциях — вычитаны вручную: collapse/probe/refresh/description в `servers.dart`, back в `speedtest.dart` — label везде есть).
- `Tile` — button/selected семантика; серверные строки — `Semantics(selected:, button:)` (`servers.dart:817`); секции сайдбара — `Semantics(selected:)` + Tooltip с `Ctrl+N` (`shell.dart:473`).
- Декоративный прогресс в benchmark исключён из семантики с комментарием-обоснованием (текст «done of total» рядом анонсируется) — `ExcludeSemantics` осознанно.
- Тосты: заголовок с действием — `Semantics(button:true, onTap:)`, кнопка закрытия — `Semantics(label: s.close)` (`toasts.dart`).
- Чекбокс опасных прав расширений — `Semantics(checked:)` (наследие POWER-RUN a11y, на месте).
- QR-экраны: код на белой карточке; текстовые альтернативы действий (буфер/ссылка) присутствуют.

### 4.3 Text scaling и размеры (Low-3)

- Фиксированных высот, режущих **многострочный** текст, не найдено. Остались фиксированные высоты одно-строчных контролов: `PrimaryButton` 52 (`kit.dart:647`), строка сервера/выбора на home 56 (`home.dart:371`, `servers.dart:817`), пункт навигации 40 (`shell.dart:473`), чип-лента стора 40 (`store_screen.dart:584`). Внутри — `maxLines: 1` + ellipsis, падений/переполнений не будет, но при системном масштабе текста 200% текст внутри не растёт вместе с контейнером и обрежется раньше, чем мог бы. Спека: заменить `height:` на `minHeight:` в этих четырёх местах (паттерн уже применён POWER-прогоном в других местах) + визуальная проверка на dev-машине. В фикс без тулчейна не брал — геометрия без сборки не верифицируется.
- Тап-цели: `RoundButton` 36×36 — ниже рекомендации 48dp (Material) / 44pt (Apple); для десктопного приложения приемлемо, фиксирую как Info.
- RTL: `toasts.dart:97` — `direction: TextDirection.ltr` у тостов (жест смахивания и выравнивание не следуют RTL-локалям ar/fa/ur). Наследованный пункт из REVIEW-5PASS («RTL для тостов» — владельцу). Остальной UI использует `EdgeInsetsDirectional`/`Alignment` корректно. Low-4.

---

## 5. Консистентность версий API

**Закрыто и консистентно.** POWER-RUN чинил «клиент заявлял 1.8 при ядре 1.10»; с тех пор обе стороны подняты до 1.11:

| Место | Значение |
|---|---|
| Клиент: `app/lib/src/core/link.dart:20` | `apiVersion = ApiVersion(major: 1, minor: 11, minSupportedMinor: 6)` — единственная клиентская константа, все запросы используют её |
| Ядро: `core/cmd/sora-core/main.go:51` | `Version = control.Version{Major: 1, Minor: 11, MinSupportedMinor: 1}` |

Гейты фич в клиенте согласованы с историей API из комментария в `link.dart` и не содержат устаревших констант: DNS-leak ≥ 8 (`sora.dart:384`), chains/zapret-with-VPN ≥ 10 (`sora.dart:1315`), obfs ≥ 11 (`obfsMinApiMinor = 11`, `obfs.dart:711`), tunStack ≥ 7 (`sora.dart:1307`). Других захардкоженных версий API в Dart не найдено (поиск по `minor`, `ApiVersion(`, `1.8`/`1.10` литералам — чисто).
Версия приложения для гейта расширений: `_appVersion = String.fromEnvironment('APP_VERSION')` (`store_screen.dart:380`) — хардкод `1.9.0` из REVIEW-5PASS убран; остаточное условие владельца прежнее: релизная сборка обязана передавать `--dart-define=APP_VERSION`, иначе гейт молча пропускается (`store_screen.dart:216`, проверка `isNotEmpty`).

---

## 6. Сводка находок

| # | Severity | Находка | Статус |
|---|---|---|---|
| F-08-1 | Medium | ru: 4 rollback-строки обновлений на английском (`updateRollbacking` и др.) | ✅ исправлено, коммит `1c71376` |
| F-08-2 | Info | 388/661 ключей — EN-текст во всех 30 не-en/ru локалях (целые группы ext/sync/censor/obfs/leak/profile/customServer) | осознанная политика EN-fallback (POWER-RUN фильтр слопа); перевод — не код |
| F-08-3 | закрыто ранее | Контраст light danger 4.34 < 4.5 | ✅ исправлено `9e0f89d` до этого прохода: `#D02A22` = 5.20/4.78; добавлен `onDanger` |
| F-08-4 | Low | Фиксированный формат даты `dd.MM.yyyy HH:mm` в `censor.dart:242`, `notifications_screen.dart:79` (остальные экраны locale-aware) | спека (§3, Low-1) |
| F-08-5 | Low | Sync-ошибки: сырой английский текст демона после локализованного заголовка (`sync_api.dart:328`, `sync.dart:216`) | спека (§3, Low-2), задокументированный компромисс в коде |
| F-08-6 | Low | Фиксированные высоты одно-строчных контролов (52/56/40) вместо `minHeight` — ограничение text scaling | спека (§4.3, Low-3) |
| F-08-7 | Low | Тосты жёстко LTR (`toasts.dart:97`) при RTL-локалях | спека (§4.3, Low-4), наследовано из REVIEW-5PASS |
| F-08-8 | Info | Тап-цель RoundButton 36×36 < 48dp | приемлемо для десктопа |
| — | чисто | Хардкод прозы / `Colors.red` / сырые `exception.toString()` в UI | не найдены (§2) |
| — | чисто | Полнота локалей, плейсхолдеры, сироты, пустые | 661/661 × 32, 0 расхождений (§1) |
| — | чисто | Версии API клиент ↔ ядро | 1.11 = 1.11, гейты согласованы (§5) |

## 7. Вердикт зоны

**Зона в хорошем состоянии; блокирующих находок нет.** i18n полна структурно (661×32, ноль дыр/сирот/расхождений плейсхолдеров); единственная реальная дыра перевода (ru rollback) исправлена в этом проходе. Ошибки идут единым локализованным конвейером `CoreFailure → describe()`, хардкода прозы и сырых цветов/исключений в UI нет, состояния loading/error/empty присутствуют на всех ключевых экранах, контраст danger — соответствующий WCAG AA (закрыт ранее, перепроверено расчётом), версии API клиент/ядро совпадают (1.11). Остаток — 4 Low косметики/полировки (даты, sync-detail, minHeight, RTL-тосты) спеками и один осознанный объём перевода на 29 локалей, который кодом не закрывается.

**Честная оговорка:** всё проверено статически — Flutter/Dart тулчейна на машине нет, `flutter analyze`/`flutter build` не запускались, визуальное поведение (text scaling, RTL, контраст в рендере) не наблюдалось. Перед мержем обязательна верификация на dev-машине: analyze + build + ручной проход ключевых экранов в en/ru/ar при масштабе текста 200%.
