# Анализ №8: подсистема расширений (F10)

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`, репозиторий `~/workspace/bug-hunt/sora`.
Read-only анализ. Охвачено: `core/ext/` (все 16 файлов), `proto/sora/ext/v1/ext_host.proto`,
`core/control/exthost.go`, `core/cmd/sora-core/main.go` (wiring), `app/lib/src/ext/` (6 файлов),
`app/lib/src/ui/extensions/` (5 файлов), `docs/extensions.md`, `examples/hello-panel/`,
`reports/EXTENSIONS-VISION.md`, `reports/featlog-wave3-ext.md`.

## Вердикт

Фундамент (формат пакета, подписи, валидация манифеста, install/update/rollback в Dart, UI стора)
сделан крепко и честно. Но **«runtime v2» (background workers + net.fetch) — театр**:
UI показывает тумблер «Run in background» с текстом «Applies immediately», а выполнять
нечему — раннера нет ни в Dart, ни в Go (Go-версия зарегистрирована, но недостижима).
Из 12 разрешений реально работают 3; остальные 9 показываются в промпте как настоящие.
Из 6 capabilities работает 1 (ui-panel). Плюс две настоящие дыры модели доверия:
каталог не проверяет пакеты по закреплённому ключу автора (хотя дока §6 это обещает),
и обновление не проверяет непрерывность ключа автора (подмена расширения тем же id).
Оценка: **ядро — хорошо; v2 и часть модели доверия — недоделано и местами нечестно**.

Что честно уже сейчас: «каталог скоро» вместо вечной ошибки сети
(`store_screen.dart:334`), предупреждение о самоподписанном ключе сайдлоада
(`permissions_sheet.dart`, `extSideloadWarning`), fail-closed при незавершённой
церемонии ключей. Это сильные ходы — тем заметнее места, где честности не хватило.

---

## Сильные стороны

1. **Формат и криптография — образцовые.** `.soraext` (zip + `checksums.txt` + minisign
   поверх checksums, trusted comment `timestamp/file/sha256`): `core/ext/package.go`,
   `core/ext/sign.go`, Dart-зеркала `app/lib/src/ext/package.dart`, `verifier.dart`.
   Zip-slip закрыт в обеих реализациях, лимиты 64/256/32 МБ, дубли путей и
   `checksums.txt`-покрытие «ровно все файлы, ничего лишнего».
2. **Валидация манифеста строгая и симметричная Go↔Dart.** `DisallowUnknownFields`,
   reverse-DNS id, semver, замкнутый реестр разрешений, JSON-Schema-подмножество
   для настроек. Расхождений между реализациями не нашёл (кроме отмеченных ниже).
3. **Dart-стор — настоящий lifecycle.** `app/lib/src/ext/store.dart`: install через
   staging с откатом при ошибке, чистка выпадающей из N-1 окна версии (`:161-211`),
   rollback с перечитыванием манифеста с диска (`:246-266` — правильно, в отличие
   от Go-версии), удаление настроек и background-конфига при uninstall (`:268-290`).
4. **Промпт разрешений сделан по-взрослому.** `permissions_sheet.dart`: опасные
   разрешения требуют явного чекбокса, сайдлоад-бейдж с честным текстом про
   self-attested ключ, allowlist `network_hosts` показывается прямо под
   `net.fetch`. Риск-уровни (normal/sensitive/dangerous) консистентны Go↔Dart.
5. **Изоляция панели по навигации — правильная.** `panel_screen.dart`: локальный
   HTTP на 127.0.0.1 + эфемерный порт, `NavigationDelegate` режет всё кроме
   origin (`:~280`), путь проверяется на containment, bootstrap инжектится до
   скриптов страницы. Отключение расширения убивает панель мгновенно
   (`_onStoreChanged`).
6. **Fail-closed везде, где заявлен.** Плейсхолдер team-ключа роняет проверку
   каталога и в Go (`core/ext/sign.go: VerifyCatalogSignature`), и в Dart
   (`verifier.dart: verifyCatalogSignature`); UI вместо ошибки показывает
   «каталог скоро» (`store_screen.dart:334-358`).
7. **netfetch в Go — редкий пример продуманного allowlist-клиента.**
   `core/ext/netfetch.go`: https-only, без userinfo/IP/портов, редиректы
   перепроверяются (max 3), rate-limit, аудит-лог каждого запроса с вычищенными
   query-параметрами (`safeMethodURL`). Жаль, что недостижим (см. проблемы).

---

## Слоп / проблемы

Формат: `[S1]` — Severity 1 (критично для доверия/безопасности), `[S2]` — заметно,
`[S3]` — мелочь/полировка.

### Театр vs реальность (главный раздел)

**[S1] T1. Background tasks: UI есть, раннера нет.**
`detail_screen.dart:160-161, 493-621` — секция «Background task» с тумблером
«Run in background» и выбором интервала, подпись `extBgNote`:
«Applies immediately. The shortest allowed interval is 15 minutes.»
(`app/lib/l10n/strings_en.dart:1115`). По факту: тумблер пишет
`<id>.background.json`, который **не читает никто** — в `app/` нет ни workmanager,
ни планировщика (`grep BackgroundTaskConfig` за пределами `ext/store.dart` и
`detail_screen.dart` — пусто; в pubspec нет `workmanager`). Go-`Scheduler`
(`core/ext/worker.go`) вне тестов не инстанцируется никем. Пользователь
двигает тумблер, веря, что задача выполняется/останавливается, — это ложь UI.
`docs/extensions.md §7` описывает runtime как действующий
(«The worker runs in a deliberately small environment (WorkerEnv)…»).
Честный вариант: либо раннер, либо бейдж «скоро» как у каталога.

**[S1] T2. `net.fetch` в приложении не ограничивает ничего.**
Разрешение есть в реестре, allowlist `network_hosts` валидируется и красиво
показывается в промпте (`permissions_sheet.dart: _permissionExtra`), но:
Dart-бридж (`app/lib/src/ext/bridge.dart:15-19`) знает только
`getConnections/getServers/notify` (+ собственные настройки без разрешений) —
метода fetch нет; Go-`Fetcher`/`NewFetcherForExtension` вне тестов не вызывается.
Итого: пользователь даёт «доступ в интернет на эти хосты», а давать нечему.
Панельный `fetch()` при этом — известная открытая дыра (POWER-RUN, спека CSP
готова — не дублирую, фиксирую только контекст: разрешение `net.fetch` сегодня
не имеет отношения к реальному сетевому доступу панелей).

**[S2] T3. Из 12 разрешений работают 3, из 6 capabilities — 1.**
Реально enforced в `bridge.dart`: `connections.read`, `servers.read`,
`notifications`. Без эффекта: `settings.read`, `settings.write`, `tray`,
`ui.panel`, `theme.apply`, `routing.rules`, `net.hooks`, `net.fetch`,
`background`. Работающая capability: только `ui-panel`. `theme`/`network-hook`/
`routing`/`widget` не потребляются никем. Промпт при этом просит подтвердить
опасные `routing.rules`/`net.hooks` чекбоксом — подтверждение за доступ,
которого нет. Это приучает пользователя кликать «согласен» на страшных
экранах: когда доступ станет настоящим, рефлекс уже выработан.

**[S2] T4. Нет связки capability ↔ permission.**
Манифест с `ui.panels`, но без разрешения `ui.panel`, всё равно показывает
панели — бридж его не проверяет (`panel_screen.dart: didChangeDependencies`
смотрит только `inst.manifest.panels`). Аналогично capability `routing` без
`routing.rules` валидна. Модель «capability — грубая область, permission —
точный доступ» (`manifest.go`) декларирована, но не enforced нигде, кроме
`background_task`/`network_hosts` в `manifest_v1ext.go`.

**[S2] T5. Go-`core/ext` — наполовину витрина.**
`main.go:348-353` открывает `ext.OpenStore` и регистрирует `ExtensionHost`,
но: `Store.Install` не вызывается никем вне тестов; Dart-клиента для
`sora.ext.v1` не существует вообще (`app/lib/src/generated/sora/ext/v1/`
отсутствует, `grep MintToken|ExtensionHost app/lib` — пусто); `Scheduler`,
`Fetcher`, `TokenIssuer` вне тестов не используются. `core/ext/doc.go:15-17`
при этом утверждает: «an enabled extension only reaches the core through
ExtensionHost with a per-extension token» — неправда, панели идут через
Dart-бридж напрямую (`panel_screen.dart: _getConnections` с control-токеном
приложения). Featlog (`featlog-wave3-ext.md:14`) честно фиксирует решение
(«the app talks to panels via the WebView bridge»), а `doc.go` — нет.
~900 строк (`host.go` 236 + `worker.go` 294 + `netfetch.go` 379)
поддерживаемого и тестируемого, но недостижимого кода.

**[S2] T6. Go reference implementation не ставит v2-манифесты.**
`core/ext/package.go:137` — `readArchive` парсит через замороженный
`ParseManifest` с `DisallowUnknownFields`; манифест с `background_task` /
`network_hosts` отвергается. `ParseManifestFull` (`manifest_v1ext.go:80`)
используется только тестами. Плюс `Installed` (`store.go`) не персистит
`ManifestExt` — Go-стор после рестарта не смог бы восстановить ни воркеры,
нифетчеры. Дока §7 описывает это как рабочий runtime.

### Дыры модели доверия

**[S1] D1. Каталог не проверяет пакет по закреплённому ключу автора.**
`docs/extensions.md §6`: «Catalog packages are verified against the
catalog-pinned author key». Реальность: `_installFromCatalog`
(`store_screen.dart:590`) → `_installBytes` (`:161`) → `pkg.verify()` →
`verifyPackageSignature(manifest.author.publicKey, …)` (`package.dart`,
`verifier.dart:125`) — ключ берётся **из самоподписанного манифеста**.
`CatalogEntry.authorKey` (`app/lib/src/ext/catalog.dart:52`) парсится и
валидируется (`:150`), но для верификации не используется нигде (единственное
употребление — синтетический манифест для экрана деталей,
`detail_screen.dart:53`). Смысл пина — пережить компрометацию ключа автора
без обновления каталога — не работает. Пока каталог — плейсхолдер, impact
отложенный, но заявленное свойство безопасности ложно.

**[S1] D2. Обновление не проверяет непрерывность ключа автора (id squatting).**
Ни `Store.Install` (`core/ext/store.go:150`), ни `ExtensionStore.install`
(`app/lib/src/ext/store.dart:161`) не сверяют `author.public_key` обновления
с установленным. Пакет с тем же reverse-DNS `id`, но чужим ключом и старшей
версией, ставится как обычное обновление; кросс-источник (каталог → сайдлоад)
тоже молча меняет доверительный базис. Промпт покажет то же имя автора —
сигнала «ключ автора изменился» нет. Для self-attested сайдлоадов это
классический путь подмены доверенного расширения.

**[S2] D3. Отзыва нет даже в зачатке.**
Видение (принцип 3): «вредоносное — снимается с каталога с отзывом подписи
(revocation)». Дока §6 откладывает на «wave 4: OCSP-style revocation list».
Факт: снятие из каталога останавливает только новые установки; установленные
копии работают вечно, при старте blocklist не проверяется. Разрыв с видением
задокументирован честно — но это разрыв с видением.

**[S2] D4. Промпт — «всё или ничего», granular deny нет.**
`showInstallPrompt` (`permissions_sheet.dart:21, 208`) всегда возвращает
`List.of(m.permissions)` — либо все разрешения, либо отмена. Видение обещает
«permissions-модель как у мобильных ОС»; в мобильных ОС можно запретить
отдельное разрешение и продолжить. Здесь нельзя.

**[S2] D5. Панели делят одно WebView-хранилище.**
`panel_screen.dart:255` — голый `WebViewController()` без изоляции профиля.
На Android все WebView приложения делят app-data (localStorage, cookies,
IndexedDB); на iOS — дефолтный `WKWebsiteDataStore`. Панель расширения A
может читать `localStorage` панели расширения B. Изоляция «одна панель —
одна песочница» не достигнута на уровне хранилища (навигация и файлы —
достигнута). Требует проверки на dev-машине с двумя панелями, но механизм
платформенный, не гипотетический.

**[S2] D6. `granted` шире манифеста — молча.**
`install` (Go `:150`, Dart `:161`) требует `manifest.permissions ⊆ granted`,
но лишние разрешения в `granted` (не из манифеста) принимает без звука.
`PanelBridge(granted: inst.granted)` (`panel_screen.dart`) их чтит. UI всегда
передаёт ровно `m.permissions`, так что сейчас безопасно, — но контракт API
позволяет выдать больше, чем декларирует манифест. Fail-closed требовал бы
reject или пересечения. То же в Go `MintToken` — `permissions` free-form от
приложения (`host.go: MintToken`).

**[S3] D7. Rollback сохраняет расширенные гранты.**
Dart `rollback` (`store.dart:246-266`) перечитывает манифест — хорошо, но
оставляет `granted: cur.granted` — гранты более новой версии. Панель старой
версии получает разрешения, которых её манифест не декларировал. Гранты
следует откатывать вместе с версией (хранить `granted` на версию).

### Корректность / устойчивость

**[S2] C1. Dart-распаковка уязвима к zip-бомбе.**
`ExtPackage.open` (`app/lib/src/ext/package.dart:45`):
`ZipDecoder().decodeBytes(data)` распаковывает **всё в память до** проверок
`_maxSingleFile`/`_maxUncompressedBytes`. Архив ≤64 МБ из нулей → десятки ГБ
RAM, падение приложения. Go-версия (`package.go`) читает стримингом через
`io.LimitReader` с проверками до распаковки. Вектор: вредоносный `.soraext`
по URL/из файла — ровно тот вход, который рекламируется (`extInstallFromUrl`).

**[S2] C2. Go `Store.Rollback` не восстанавливает манифест.**
`core/ext/store.go:297-318`: откат делает `cur.Version = cur.Previous` и
`cur.Manifest.Version = cur.Version` — в реестре остаётся манифест **плохой**
версии (чужие permissions/panels/author), меняется только строка версии.
Тест (`store_test.go:106-128`) проверяет только `Version`/`Previous`.
Dart-версия этот баг не повторяет (перечитывает с диска). Go-стор в проде не
используется, но это «reference implementation» из `doc.go`.

**[S3] C3. Go `Install` копит мусор версий.**
При обновлении v1→v2→v3 каталог v1 остаётся на диске навсегда: `Install`
удаляет только текущую плохую версию при ошибке, а вытесненную из N-1 окна —
нет. `Uninstall` чистит лишь `Version`+`Previous`. Dart-версия чистит
(`store.dart: ~203-206`).

**[S3] C4. Несогласованные режимы отказа реестра.**
Dart `load()` пропускает битые записи (`store.dart`), Go `OpenStore`
падает на битом `installed.json` целиком. Две «зеркальные» реализации —
два разных контракта надёжности.

**[S3] C5. `_servers()` дрейфует от схемы.**
`panel_screen.dart:219-223` отдаёт `{id, name, displayName→name, protocol}`,
а proto `ExtensionServer` и дока §4 — `{id, name, country, latency_ms}`.
Панель, написанная по доке, получит не те поля.

### UX- и API-слоп

**[S3] U1. Мёртвая ветка «обновление с расширением прав».**
`install()` возвращает `added` (diff разрешений), `_installBytes`
возвращаемое значение игнорирует (`store_screen.dart:161-211`); в
`showInstallPrompt` `addedPermissions` не передаётся никогда — вариант
промпта `extUpdateTitle`/`extPermissionsWidened` недостижим, обновления всегда
показывают заголовок «Install». Половина задуманного UX висит мёртвым кодом.

**[S3] U2. Нет «что изменилось» при обновлении.**
Промпт показывает полные права новой версии, но не diff версий/changelog.
При