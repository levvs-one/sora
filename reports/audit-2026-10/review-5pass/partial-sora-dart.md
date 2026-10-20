# Тотальное 5-проходное ревью: sora-dart (зона app/)

Дата: 2026-10-19. Ветка `bugfix/audit-2026-10-19` (не переключалась, не пушилась).
Ревьюер: сабагент depth 2/2. Тулчейна Dart/Flutter нет — компиляция невозможна, всё вычитано вручную.

## Охват

- **112 .dart-файлов** под `app/` (без `third_party`, без `generated_plugin_registrant`): каждый прочитан целиком, 5 проходов каждым файлом.
- **C++ раннеры**: `linux/runner/my_application.cc` (целиком), `main.cc`, `my_application.h`; `windows/runner/main.cpp` (целиком), остальные файлы раннеров — по релевантности.
- **Generated** (`src/generated/*.pb*.dart`, 4 файла): поверхностно + точечная проверка (обнаружено отсутствие `zapretWithVpn` — см. R5-SD-2-1).
- **Тесты**: `test/` (17 файлов) и `integration_test/` (2 файла) — skim, с проверкой покрытия новой логики.
- **l10n**: все 31 `strings_*.dart` — спот-чек новых ключей волны (все 370 геттеров на месте во всех локалях); кросс-чек «все используемые `s.<key>` существуют»; кросс-чек «все кидаемые `CoreFailure('…')` имеют маппинг в `describe()`».
- **Re-check новых коммитов**: стартовая точка зафиксирована (`1f2dfa3, 155a518, 0890338` + незакоммиченное); перед отчётом проверены `git log`/`git status` повторно. За время ревью волна фич добавила коммиты F8 (`9886a6b`), F9 (`b7f8870`), F10 (`4452141`, `499c850`), F11 (`b43677f`) и новые untracked-файлы — всё покрыто проходами 1/2/5 минимум, `ext/`+`ui/extensions/` — всеми пятью.
- Старые находки из `sora-audit.md` / `FIX-PLAN.md` / `FIX-REPORT.md` / `fixlog-sora-dart.md` не дублируются; все вычитанные чужие фиксы (H8, M17–M20, L22–L29) признаны корректными.

## Находки

Формат: `R5-SD-<проход>-<n>`, Severity, файл:строки, сценарий, как исправить.

### Проход 1 — Безопасность

**R5-SD-1-1 — Medium — `app/linux/runner/my_application.cc` (`open`/`forward_link`) — cold-start по D-Bus теряет ссылку (H8 чинит только тёплый путь).**
Сценарий: приложение закрыто → пользователь открывает `sora://…` (xdg-open) → `g_application_register` → `open()` → `forward_link(link)` дёргает method channel **до** того, как Dart поставил handler → сообщение дропается. `pending_link` в этом пути недостижим: `activate()` всегда создаёт канал раньше, чем обрабатывает `command_line`/`open`. Дополнительно очередь — один слот (перезапись при двух быстрых ссылках). Cold start через argv покрыт механизмом app_links (entrypoint-arguments) — исходников пакета нет, поведение плагина проверить не удалось.
Как исправить: в `open()` складывать ссылку в `pending_link`, а в Dart — забирать её после установки handler'а (или ждать готовности канала); очередь — хотя бы на 8 слотов. Владельцу: явно протестировать cold-start по `sora://` при закрытом приложении (пункт уже есть в owner actions, подтвердить).

**R5-SD-1-2 — Low — `app/lib/src/ext/package.dart` (`_isSafePath`) — обратный слэш обходит проверку `..`.**
Сценарий: `_isSafePath` проверяет части пути по `/` на равенство `'..'`, поэтому `sub\..\..\evil` проходит (а `isSafeEntry` в manifest.dart использует более строгий `contains('..')` — несогласованность). На практике backstop есть: `ExtensionStore.install` сверяет канонический путь с `startsWith(dst + separator)`. Как исправить: в `_isSafePath` тоже отклонить `\` или использовать `contains('..')`.

**R5-SD-1-3 — Info — `app/lib/src/ext/verifier.dart` — формат НЕ стандартный minisign.**
Сценарий: docstring говорит «Minisign signature verification», но формат кастомный: blob второй строки = `sig(64) ‖ trusted_comment`, trusted comment несёт `timestamp/file/sha256` (у настоящего minisign вторая строка — `Ed‖key_id‖sig`, trusted comment — отдельная текстовая строка без sha256). Криптографически схема sound (подпись связывает timestamp+file+sha256, sha256 связывает payload, сравнение — constant-time). Но интероп с `core/ext/sign.go` надо подтвердить на стороне Go — иначе подписи, сделанные одной стороной, не пройдут у другой. Флаг core-агенту/владельцу.

**R5-SD-1-4 — Info — `app/lib/src/ext/catalog.dart` / `verifier.dart` — нет защиты от replay старого каталога.**
Сценарий: timestamp из trusted comment парсится, но нигде не проверяется; `fetchCatalog` не проверяет свежесть `updatedAt`. Пока key ceremony не завершён — `verifyCatalogSignature` fail-closed, угроза неактуальна. После церемонии: добавить max-age на `updatedAt` (например, отказ при каталоге старше N дней с понятной ошибкой).

Проверено и признано корректным (не находки): QR-шеринг скрывает сырую ссылку по умолчанию + warning; deeplink-парсер строгий; `openLink` — только https/http/tg; WebView панелей — навигация залочена на loopback-origin с эфемерным портом, `javascriptCanOpenWindowsAutomatically: false`; JS-мост — allow-list методов против granted permissions, `setSettings` скоупирован на файл настроек расширения (app-настройки недоступны); подпись пакета — sha256 каждого файла + подпись author-ключом поверх checksums.txt; downgrade версий заблокирован; извлечение — через канонический путь + staging dir; `installBytes` всегда вызывает `verify()`; обновления — запиненные URL + SHA256-манифест; секреты не оседают в стейте; `pipe.dart` проверяет PID через SCM; `Process.run` без shell.

### Проход 2 — Корректность

**R5-SD-2-1 — High — `app/lib/src/sora.dart` (`buildPlan`) + `app/lib/src/generated/.../core_control.pb.dart` — тоггл F11 `zapretWithVpn` мёртвый.**
Сценарий: F11 добавил `settings.zapretWithVpn` и тоггл в `modes.dart`, Go-ядро (`core/control/plan.go:269`) и proto (`zapret_with_vpn = 16`) — готовы. Но Dart `buildPlan()` поле в `SessionPlan` не выставляет, а сгенерированный Dart-protobuf поля вообще не содержит. Пользователь включает тоггл — ничего не происходит. Как исправить: перегенерировать Dart-protobuf из `proto/sora/core/v1/core_control.proto` (тулчейна здесь нет — на dev-машине) + одна строка в `buildPlan` (`..zapretWithVpn = settings.zapretWithVpn`, с учётом Linux/TUN-гейтов ядра).

**R5-SD-2-2 — Medium — `app/lib/src/ui/extensions/store_screen.dart` (`_appVersion = '1.9.0'`) — захардкожена и уже неверна.**
Сценарий: `min_app_version`-гейт сравнивает с константой `'1.9.0'`, а реальная версия в pubspec — `1.0.12+13`. Расширение с `min_app_version: 1.1.0` будет установлено на 1.0.12 и сломается. Как исправить: брать версию из `PackageInfo` (как уже делает `updates.dart`), один источник истины.

**R5-SD-2-3 — Medium-Low — `app/lib/src/ui/extensions/store_screen.dart` (`_installFromCatalog`, `_installBytes`) — зависший немодальный диалог прогресса.**
Сценарий: `_installFromCatalog`: после `await http.get(...)` стоит `if (!context.mounted) return;` — но модальный (`barrierDismissible: false`) диалог прогресса уже показан и никем не закрыт → приложение выглядит замороженным. Аналогично `hideProgress()` в `_installBytes` закрывает диалог только при `context.mounted`. Воспроизводится уходом с экрана во время 120-секундной загрузки. Как исправить: захватывать BuildContext самого диалога в builder'е `showDialog` и закрывать через него (валиден для pop своего роута и после unmount вызывающего виджета).

**R5-SD-2-4 — Low — `app/lib/src/ui/settings_screen.dart` — `Uri.parse(settings.probeUrl).host` в `build`.**
Сценарий: битое stored-значение (наследие старых версий) → `FormatException` → падение билда экрана. Сеттер валидирует через `_web`, но stored-данные могут прийти из старой версии. Как исправить: `Uri.tryParse(...)?.host` с фолбэком на сырое значение. Не правлю сам: файл с чужими незакоммиченными правками.

**R5-SD-2-5 — Low — `app/lib/src/ext/bridge.dart` (`PanelBridge.handle`) — сырые `as`-касты.**
Сценарий: панель постит JSON-массив → `decoded as Map<String, dynamic>?` кидает TypeError (вне try/catch — обёрнут только `jsonDecode`); то же для `msg?['args'] as Map<…>`. На уровне JS-канала в `panel_screen.dart` перехвачено (→ 'internal'), но сам мост должен быть тотальным. Как исправить: `decoded is Map<String, dynamic> ? decoded : null` и аналогично для args.

**R5-SD-2-6 — Low — `app/lib/src/ext/manifest.dart` (`ExtManifest.parse`) — TypeError вместо ManifestError.**
Сценарий: в try/catch обёрнут только `jsonDecode`; `decoded['author'] as Map<String, dynamic>?`, `decoded['permissions'] as List?`, `e as Map<String, dynamic>` для панелей кидают сырой TypeError при неверных типах — UI, ожидающий `ManifestError`, отмаппит иначе. Как исправить: обернуть извлечение полей в try/catch на TypeError → `ManifestError`.

**R5-SD-2-7 — Low — `app/lib/src/sora.dart` (`_watchSession`) — сброс watchdog-флага без `notifyListeners()`.**
Сценарий: healthy event сбрасывает `failure = 'app.core_watch_unstable'` внутри ветки без notify (notify только для stateChanged) → UI может показать устаревшую ошибку до следующего state-события. Путь почти мёртвый (к моменту unstable подписка уже мертва), поэтому Low.

**R5-SD-2-8 — Low — `app/lib/src/ui/chains.dart` (`_save`) — недостижимая ветка SnackBar для `storeError`.**
Сценарий: двойная валидация — после `validateHops` ветка показа ошибки недостижима (мёртвый код). Файл untracked (волна) — спекой.

**R5-SD-2-9 — Low — `app/lib/src/chains.dart` (`validateHops`) — не проверяет пустые hop-id.**
Сценарий: `_validHops` (в `_load`) пустые id отфильтровывает, а `validateHops` — нет; несогласованность. Файл untracked (волна) — спекой.

**R5-SD-2-10 — Low — `app/lib/src/ui/extensions/detail_screen.dart` (`_confirm`) — тихое глотание ошибок uninstall/rollback.**
Сценарий: `catch (_) {}` без фидбэка — при ошибке пользователь не узнает, что удаление/откат не произошло. Как исправить: показать тост/диалог с `extErrGeneric`.

**R5-SD-2-11 — Low — `app/lib/src/ext/catalog.dart` — `as`-касты вместо `CatalogError`.**
Сценарий: `raw as Map<String, dynamic>`, `(json['rating'] as num?)` и т.п. при неверных типах кидают TypeError. Риск низкий (каталог подписан командой), но для консистентности обернуть в `CatalogError`.

Проверено и признано корректным: `_connectionWork`/`_connectQueued` (нет висящих connect), `confirmDrop` на app-wide navigator (M19), троттлинг 300мс применён и к benchmark (M20), generation stamp (L22), `_pipe?.closed` (L26), `Platform.resolvedExecutable` (L28), Windows retry/mutex (L29); protobuf `==` — value-based (баннер needsReconnect корректен); `pickMember`/`smartScoreOf`/`compareAutoSelect`/`freshBandwidthOf` — математика сошлась с комментариями; отмена benchmark/speedtest/probe — без висящих процессов.

### Проход 3 — Живучесть

Новых находок нет. Проверено: dispose подписок/таймеров/контроллеров везде (qr, logs, toasts, speedtest с generation-счётчиком, servers, program_picker, shell, connections, `_Elapsed`, `Sora.dispose`, `AppUpdater.dispose`, `ExtensionPanelScreen` — остановка loopback-сервера и teardown WebView при disable/uninstall, `_LocalPanelServer.stop(force: true)`); `_watchSession` — resubscribe с backoff 1/2/4/8с и остановкой после 5 падений; `cancelBenchmark`/`cancel` в updates — без висящих загрузок; обрыв сети — `reportFailure` + тосты с ретраем.

### Проход 4 — Качество кода

**R5-SD-4-1 — Low — `app/lib/src/ext/permissions.dart` — мёртвое поле `ExtPermission.blurbKey`.**
Сценарий: UI использует собственный `permissionBlurb`-switch в `permissions_sheet.dart`, поле реестра нигде не читается. Как исправить: использовать поле реестра (убрать дублирующий switch) или удалить поле.

**R5-SD-4-2 — Trivial — `app/lib/src/ui/servers.dart` — двойной пробел `async {  final`.**
Исправлено сразу (коммит `77bac69`).

**R5-SD-4-3 — Low — нет юнит-тестов новой логики волны.**
Сценарий: `smartScoreOf`, `compareAutoSelect`, `freshBandwidthOf`, `pickMember`, watchdog-бэкoff, crash-intent, `verifyPayload`/`ExtPackage` — чистые функции, идеально тестируемые, но тестов нет (`test/app_test.dart` покрывает только `buildPlan`). Как исправить: добавить тесты в `test/app_test.dart` / новый `test/ext_verify_test.dart` (нужен тулчейн — на dev-машине).

**R5-SD-4-4 — Low — несогласованные `autoSelect`-режимы в точках вызова `pickMember`.**
Сценарий: `connect()` — дефолт `'ping'`; `_sortEntries` — `serverSortMode`; `_ServerRow` — `settings.autoSelectMode`; `_ServerCard` (home) — дефолт `'ping'`. Отображаемая задержка группы может не совпадать с реально выбранным участником. Как исправить: продуктовое решение — единый семантический режим (вероятно, `autoSelectMode` везде, включая `connect()`).

### Проход 5 — Системы и UX

Проверено и признано соответствующим стандарту: захардкоженных UI-строк нет (сканы `Text('`/`Text("` пустые); все 370 ключей × 31 локаль на месте, включая все новые ключи волны (`ext*`, `chain*`, `profile*`, `sync*`, `coreWatchUnstable`, `crashRestore*`, `zapretWithVpn*`); все используемые `s.<key>` резолвятся; все кидаемые `CoreFailure('…')` маппятся в `describe()` (после моего фикса) или осознанно падают в `errGeneric` (`core.internal.unexpected`); каждый экран имеет loading/error/empty; `maxLines`/`ellipsis` на месте; ошибки — через `palette.danger` (семантический цвет темы, не захардкоженный красный); dns-экран сознательно не красит ошибки в красное.

**R5-SD-5-1 — Low — `app/lib/src/ui/chains.dart` — захардкоженный суффикс `"ms"` (`'${ms}ms'`, `'${estimate}ms'`).**
Как исправить: `s.milliseconds(ms)`. Файл untracked (волна) — спекой.

**R5-SD-5-2 — Low — `app/lib/src/ui/profiles.dart` — висячий `" · "` в снапшоте при пустом engine.**
Сценарий: `'${tunnel} · ${preset} · ${engine}'` при `engine == ''` даёт `"tun · Balanced · "`. Как исправить: фильтровать пустые части. Файл untracked (волна) — спекой.

**R5-SD-5-3 — Low — `app/lib/src/ui/toasts.dart` — `direction: TextDirection.ltr` захардкожен.**
Сценарий: в RTL-локалях (ar/fa/ur) тосты всё равно LTR. Возможно, осознанно (таймстемпы) — подтвердить продуктово; иначе `Directionality.of(context)`.

**R5-SD-5-4 — Low — `app/lib/src/ui/notifications_screen.dart` — `DateFormat('dd.MM.yyyy  HH:mm')` захардкожен.**
Сценарий: не локализуется (в остальных местах — `DateFormat.yMMMd(locale)`). Файл с чужими незакоммиченными правками — спекой.

**R5-SD-5-5 — Low — `app/lib/src/ui/chains.dart` — `s.chainTooFew` как плейсхолдер пустого состояния.**
Сценарий: строка ошибки валидации используется вместо подсказки — неверная семантика для empty-state. Файл untracked (волна) — спекой.

**R5-SD-5-6 — Low — `app/lib/src/ui/extensions/widgets.dart` (`_compact`) — нелокализованные суффиксы 'K'/'M'.**
Сценарий: `1.2K`/`3.4M` не учитывают локаль. Мелочь; как исправить — `NumberFormat.compact(locale)`.

**R5-SD-5-7 — Info — `app/lib/src/ui/dns.dart` — неизвестные ключи ядра показываются сырыми.**
Сценарий: `_checkLabel`/`_checkHint` возвращают сырой `key`/`hint` как фолбэк — осознанный trade-off (автор пометил комментарием). Оставить, но залогировать неизвестные ключи для будущих маппингов.

## Сводная таблица

| ID | Проход | Severity | Файл | Статус |
|---|---|---|---|---|
| R5-SD-1-1 | 1 | Medium | linux/runner/my_application.cc | Спека |
| R5-SD-1-2 | 1 | Low | app/lib/src/ext/package.dart | Спека |
| R5-SD-1-3 | 1 | Info | app/lib/src/ext/verifier.dart | Флаг Go-стороне |
| R5-SD-1-4 | 1 | Info | app/lib/src/ext/catalog.dart | Спека (пост-церемония) |
| R5-SD-2-1 | 2 | **High** | app/lib/src/sora.dart + generated | Спека (нужен protoc) |
| R5-SD-2-2 | 2 | Medium | app/lib/src/ui/extensions/store_screen.dart | Спека |
| R5-SD-2-3 | 2 | Medium-Low | app/lib/src/ui/extensions/store_screen.dart | Спека |
| R5-SD-2-4 | 2 | Low | app/lib/src/ui/settings_screen.dart | Спека (чужой файл) |
| R5-SD-2-5 | 2 | Low | app/lib/src/ext/bridge.dart | Спека |
| R5-SD-2-6 | 2 | Low | app/lib/src/ext/manifest.dart | Спека |
| R5-SD-2-7 | 2 | Low | app/lib/src/sora.dart | Спека |
| R5-SD-2-8 | 2 | Low | app/lib/src/ui/chains.dart (untracked) | Спека |
| R5-SD-2-9 | 2 | Low | app/lib/src/chains.dart (untracked) | Спека |
| R5-SD-2-10 | 2 | Low | app/lib/src/ui/extensions/detail_screen.dart | Спека |
| R5-SD-2-11 | 2 | Low | app/lib/src/ext/catalog.dart | Спека |
| R5-SD-4-1 | 4 | Low | app/lib/src/ext/permissions.dart | Спека |
| R5-SD-4-2 | 4 | Trivial | app/lib/src/ui/servers.dart | **Исправлено (77bac69)** |
| R5-SD-4-3 | 4 | Low | test/ | Спека (рекомендация) |
| R5-SD-4-4 | 4 | Low | app/lib/src/sora.dart + ui | Спека (продуктовое решение) |
| R5-SD-5-1 | 5 | Low | app/lib/src/ui/chains.dart (untracked) | Спека |
| R5-SD-5-2 | 5 | Low | app/lib/src/ui/profiles.dart (untracked) | Спека |
| R5-SD-5-3 | 5 | Low | app/lib/src/ui/toasts.dart | Спека |
| R5-SD-5-4 | 5 | Low | app/lib/src/ui/notifications_screen.dart | Спека (чужой файл) |
| R5-SD-5-5 | 5 | Low | app/lib/src/ui/chains.dart (untracked) | Спека |
| R5-SD-5-6 | 5 | Low | app/lib/src/ui/extensions/widgets.dart | Спека |
| R5-SD-5-7 | 5 | Info | app/lib/src/ui/dns.dart | Наблюдение |
| describe chainUnsupported | 5 | Low | app/lib/src/ui/kit.dart | **Исправлено (77bac69)** |

Итого: 27 позиций (1 High, 2 Medium, 1 Medium-Low, 17 Low, 1 Trivial, 3 Info + 2 исправленных сразу).

## Топ-3

1. **R5-SD-2-1 (High)** — F11 `zapretWithVpn`: тоггл мёртвый. Dart-protobuf не содержит `zapret_with_vpn` (поле 16 есть в proto и Go-ядре), `buildPlan` его не выставляет. Нужна перегенерация protobuf на dev-машине + 1 строка.
2. **R5-SD-1-1 (Medium)** — Linux cold-start по `sora://` через D-Bus `open` теряет ссылку: H8 закрыл только тёплый путь. Нужен ручной тест при закрытом приложении.
3. **R5-SD-2-2 (Medium)** — extensions: `_appVersion = '1.9.0'` захардкожена и неверна (реально `1.0.12+13`) → гейт `min_app_version` пропускает несовместимые расширения. Брать из `PackageInfo`.

## Исправлено сразу

Коммит `77bac69` `[review-5pass] describe: map chainUnsupported to its l10n text; formatting nit in servers.dart`:
- `app/lib/src/ui/kit.dart`: `describe()` — `'chainUnsupported' => s.chainUnsupported` (раньше падение в `connectChain` показывало generic «Something went wrong», хотя точный локализованный текст «The current engine cannot build chains» уже существовал).
- `app/lib/src/ui/servers.dart`: убран двойной пробел в `deleteSubscription`.

Оба — только свои изменения, в файлах без чужих правок; правки вычитаны (null-safety/типы не затронуты).

## Осталось спекой

Всё из таблицы выше со статусом «Спека»: причины — (а) файлы принадлежат волне фич (untracked или чужие незакоммиченные правки — не трогаю и не коммичу); (б) требуется тулчейн (protoc, flutter analyze/test) или продуктовое решение; (в) риск правки без компиляции выше пользы. Крупное отдельно: R5-SD-2-1 (protoc-регенерация), R5-SD-1-1 (нативный код + ручной тест).

## Вердикт по UX-качеству нового кода волны фич (F1–F11)

Общее впечатление — высокое, явно выше среднего по индустрии для свежего кода: вся пользовательская строка — через `S.of` (31 локаль, ключи проверены скриптом — 100% покрытие), состояния loading/error/empty есть везде, `maxLines`/`ellipsis` на месте, опасные действия — через confirm-диалоги, dangerous permission — с явным чекбоксом, sideload — с warning-бейджем, подпись/verify-пайплайн расширений — грамотный (sha256 + author-sig + canonical-path + staging). Троттлинг M20 применён и к новому коду.

Что портит картину (всё — в списке спек выше): несколько «недожатых» деталей — захардкоженные `ms`/`K`/`M`/LTR/формат даты (R5-SD-5-1/3/4/6), плейсхолдер-ошибка вместо empty-state (R5-SD-5-5), висячий разделитель (R5-SD-5-2), мёртвый тоггл F11 (R5-SD-2-1), зависший прогресс-диалог при уходе с экрана (R5-SD-2-3), неверная константа версии (R5-SD-2-2). Ничего архитектурного; после зачистки списка — уровень «полишед».

## Открытые вопросы / follow-up

- Подтвердить `flutter analyze` + `flutter build linux --release` + `flutter test` на dev-машине (тулчейна здесь нет; висит с fix-round 1).
- Интероп формата подписей расширений с `core/ext/sign.go` — флаг Go-агенту.
- Ручной тест cold-start `sora://` при закрытом приложении (Linux) и deeplink-тест из owner actions.
- Key ceremony (minisign) — после неё включить catalog max-age check (R5-SD-1-4).
