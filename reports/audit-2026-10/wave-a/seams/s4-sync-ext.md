# S4: Core ↔ sync-демон + расширения

Кластер отдела совместимости стыков. Источники: `service/sync` (Go, модуль
`github.com/levvs-one/sora-client/sync`), контракт `service/sync/F9-SYNC-CONTRACT.md`,
Dart-клиент (`app/lib/src/sync*.dart`), расширения: JSON Schema
(`tools/sora-ext/schema/manifest.schema.json`), Go (`core/ext`), TS
(`tools/sora-ext/templates/shared/sora-ext.d.ts`), Dart (`app/lib/src/ext/`),
CLI (`tools/sora-ext`).

Вердикты: СОВМЕСТИМ (доказательство) / РАЗРЫВ (хеш или спека) /
НЕ ПРОВЕРЯЕМО ЗДЕСЬ (причина).

## 1. Sync-демон ↔ клиенты

### 1а. Виды документов (kinds) — СОВМЕСТИМ

- Контракт §4: `subscriptions`, `app_settings`, `overrides`, `profiles`,
  `chains`, `obfs`; имена: `list` для subscriptions, `main` для остальных.
- Dart `SyncDocKinds` (`app/lib/src/sync_docs.dart`): ровно те же 6 kind и
  то же правило `nameOf` (subscriptions→`list`, остальные→`main`).
- Go-демон kind не перечисляет и не должен: документы — непрозрачные блобы
  (`service/sync/sync/sync.go`), store проверяет только `safeName`
  (kind/name: `[A-Za-z0-9._-]`, без `..`, ≤128). Все 6 контрактных kind/name
  проходят `safeName`. Неизвестные kind Dart при применении игнорирует
  (forward compatibility, контракт §4) — семантика одна.

### 1б. Allowlist настроек — СОВМЕСТИМ (по построению)

- Единственный источник allowlist — Dart `Settings.syncableSettingsKeys`
  (`app/lib/src/settings.dart`, 38 ключей), он же именуется в контракте §4.
  Формат документа `{"<key>":{"t":"s"|"b"|"i"|"sl","v":...}}` совпадает с
  `exportSyncableSettings`/`importSyncableSettings` в том же файле; импорт
  фильтрует по allowlist и типам тегов, отсутствующие ключи не трогает
  (per-key merge — как в контракте).
- Go-сторона allowlist не имеет и иметь не должна: `app_settings` для
  демона — непрозрачный блоб. Расхождения «Go ↔ Dart» здесь невозможны
  по построению; дрейф возможен только контракт ↔ Dart, его нет.

### 1в. API-токен — СОВМЕСТИМ

- Go (`service/sync/api/daemon.go`): токен 32 случайных байта,
  base64url без паддинга (43 символа), файл `<data-dir>/api_token` (0600),
  проверка `Authorization: Bearer <token>` в `withAuth` для ВСЕХ эндпоинтов
  (`service/sync/api/http.go`), сравнение — constant-time
  (`checkToken`, `subtle.ConstantTimeCompare`). TTL нет (контракт §3).
- Dart (`app/lib/src/sync_api.dart`): тот же заголовок
  `Authorization: Bearer $_token` на каждый запрос; токен читается из того
  же файла (`sync_daemon.dart::_readToken`, trim), baseUrl — из
  `http_addr`. Формат/получение/заголовок идентичны.
- Единицы времени в ответах (контракт молчит — сверено по коду, совпадает):
  `pairing/start.expires_at` и `status.pairing_expires_at` — Unix
  **секунды** (Go `expiresAt.Unix()`), Dart умножает на 1000;
  `peers.paired_at/last_sync` и `documents.updated_at` — Unix
  **миллисекунды** (Go `UnixMilli`), Dart читает как миллисекунды.
  Ловушка на будущее: единицы разные внутри одного API и контрактом не
  зафиксированы; сегодня обе стороны согласны.

### 1г. mDNS — СОВМЕСТИМ

- Go (`service/sync/discovery/discovery.go`): type `_sora-sync._tcp`,
  instance `sora-sync-<deviceID>`, TXT ровно `id=<device-id>`, `v=1`.
- Dart сам mDNS не browsит (это делает демон внутри `Join`); в
  `app/lib/src/sync.dart` константа `syncMdnsService = '_sora-sync._tcp'`
  совпадает. Контракт §2 = код обеих сторон.
- Dial-gate: демон дозванивается только на loopback/RFC1918/link-local
  (`lanAddr` в `api/pairing.go`) — как в контракте.

### 1д. QR-пэйринг — РАЗРЫВ (критичный, Dart-декодер отвергает все валидные payload)

Формат (контракт §1, Go `pairing.Encode/Decode`, вектор T1): Go encode —
`url.Values.Encode` (ключи id, port, pub, token, v), pub =
RawURLEncoding 32 байта, token = RawURLEncoding 16 байт.
Round-trip Go: `TestInvitationRoundTrip`, `TestVectorT1Decodes`
(пере-encode(decoded T1) == T1 байт-в-байт) — зелёные
(`go test ./...` в service/sync: все пакеты ok).

Dart-декодер (`SyncPairing.decodePairPayload`, `app/lib/src/sync.dart`)
заявлен как «byte-exact mirror», но:

1. **КРИТИЧНО**: `_b64rawDecode` вызывает `base64Url.decode(s)` без
   `base64Url.normalize(s)`. Dart SDK требует длину, кратную 4, и бросает
   `FormatException` на непаддированном вводе. Валидные pub (43 символа)
   и token (22 символа) не кратны 4 → декодер возвращает null на **любом**
   валидном payload. Доказательство: собственный тест репозитория
   `app/test/sync_qr_test.dart` падает — 4 accept-кейса
   (`flutter test test/sync_qr_test.dart -r expanded`: T1 decode,
   uppercase scheme, surrounding whitespace, unknown extra keys —
   везде `Expected: not null, Actual: <null>`; 17 reject-кейсов проходят,
   часть — вакуумно). Последствие: экран сканирования
   (`app/lib/src/ui/sync.dart::_scan`) отвергает любой настоящий QR
   как «invalid» до демона; пэйринг по QR в приложении не работает.
   ФИКС: коммит `ba625cf3` — декодер переписан вручную под семантику
   Go RawURLEncoding (даже после `normalize()` стоковый Dart-декодер
   отвергал неканонические trailing-биты, которые Go молча отбрасывает;
   проверено пробой: pub `...Hh9` Go принимает, Dart до фикса — нет;
   теперь обе принимают и дают те же 32 байта).
2. **Длина id**: Go считает байты UTF-8 (`len(id) > 128`), Dart считал
   UTF-16 code units (`deviceId.length`). Id из 65 кириллических символов
   (130 байт): Go reject, Dart accept. ФИКС: тот же коммит (utf8.encode).
3. **Port**: Go `strconv.Atoi` не терпит пробелов; Dart `int.tryParse`
   терпит ведущие/хвостовые пробелы, а `+`/`%20` в query декодируются
   обеими сторонами. `port=%2012345`: Go reject, Dart accept.
   ФИКС: тот же коммит (строгая грамматика `^[+-]?[0-9]+$` —
   зеркалит Atoi: знак допустим, пробелы нет).
   Подтверждено спаренными пробами Go и Dart до фикса: все три случая
   расходились (Go: id 65 кир. — reject, 64 — accept; port с пробелами
   — reject). После фикса Dart даёт те же вердикты по всему корпусу.
4. Совпадают (проверено по исходникам и векторам с обеих сторон):
   фрагмент (в т.ч. пустой `#`), дубли ключей, версия только `1`,
   unknown keys игнорируются, scheme case-insensitive, host — только
   строчный `pair` (uppercase host обе стороны отвергают), pub/token —
   паддинг отвергается (Go RawURLEncoding; Dart — regex алфавита без `=`).

Семантика использования: Dart-декодер — только предпроверка UI; демон
декодирует канонически сам (`api.Join` → `pairing.Decode`). Поэтому
расхождения 2–3 — UX-расхождения (валидный код мог быть отвергнут/
принят UI вразрез с демоном), а расхождение 1 ломает сценарий целиком.

### 1е. Конфликты — СОВМЕСТИМ

- Go: last-write-wins по `updated_at` (мс), строгое `>`: инициатор тянет
  `pm.UpdatedAt > lm.UpdatedAt`, пушит `lm.UpdatedAt > pm.UpdatedAt`;
  `DirStore.Put` при `stored.UpdatedAt >= doc.UpdatedAt` хранит старую
  копию (при равенстве побеждает уже хранимая — тай-брейка по хешу нет,
  обе стороны это разделяют: Dart `syncDocsDiff` — `isAfter`, строго).
- Слияния по видам (контракт §4 = `sync_docs.dart::_apply*`):
  subscriptions — additive by URL, удаления не распространяются;
  app_settings — per-key; overrides/profiles/chains/obfs — whole-value
  replace. Идентично с обеих сторон.

### 1ж. Прочее по sync

- РАЗРЫВ (минорный, спека без фикса): default data-dir демона
  (Go `cmd/sora-sync/main.go::defaultDataDir`: Linux
  `$XDG_DATA_HOME/sora-sync`, Windows `%LOCALAPPDATA%\sora-sync`) ≠
  data-dir приложения (`sync_daemon.dart::syncDaemonDataDir`: Linux
  `$XDG_DATA_HOME/sora/sync`, Windows `%APPDATA%\sora\sync`).
  Приложение всегда передаёт `--data-dir`, поэтому штатный сценарий не
  страдает; страдает только reuse вручную запущенного демона (приложение
  не найдёт его `http_addr`/`api_token`). Фикс требует решения, какой
  путь канонический (у обоих путей могут быть существующие установки) —
  оставлено владельцу/родителю.
- Пути API: все 10 роутов Go (`http.go`) 1:1 вызываются Dart-клиентом
  (status, pairing start/stop/join, peers GET/DELETE, peer sync,
  documents PUT/GET list/GET one), тела (`qr_payload`, `payload` base64,
  `updated_at`) и коды ошибок (401/404/409/502 в `describeSyncError`)
  совпадают.

## 2. Расширения: пять поверхностей manifest

Скриптовая сверка (извлечение полей/типов/required/enum из каждой
поверхности) — матрица:

| Поле / правило | Schema | Go core/ext | TS d.ts | Dart app | CLI |
|---|---|---|---|---|---|
| permissions enum (12) | = | = реестр | n/a | = реестр | через Go |
| Risk: connections.read=sensitive, servers.read=normal, settings.read=normal, settings.write=sensitive, notifications=normal, tray=normal, ui.panel=normal, theme.apply=sensitive, routing.rules=dangerous, net.hooks=dangerous, net.fetch=sensitive, background=sensitive | n/a | = | n/a | = (ExtRisk) | через Go |
| capabilities enum (6): theme, network-hook, routing, ui-panel, background, widget | = | = | n/a | = | через Go |
| top-level required: manifest_version, id, name, version, min_app_version, author | = | = | n/a | = | через Go |
| top-level unknown fields | reject (additionalProperties:false) | reject (DisallowUnknownFields) | n/a | reject (known set) | через Go |
| nested unknown fields (author, ui, panels) | reject | reject | n/a | **РАЗРЫВ: принимал** → фикс | через Go |
| author.public_key — формат minisign (42B, "Ed") | только minLength 1 (аппроксимация, задокументирована в самой схеме) | reject битый (ParsePublicKey) | n/a | **РАЗРЫВ: проверял только non-empty** → фикс | через Go |
| лимиты длин name/description/author/panel title (80/2000/80/160/60) | maxLength = code points | **байты UTF-8** | n/a | **было: UTF-16 units** → фикс на байты | через Go |
| manifest_version | const 1 | int == 1 | n/a | **РАЗРЫВ: `1.0` (double) принимался** → фикс (is int) | через Go |
| capabilities duplicate | разрешены (нет uniqueItems) | разрешены | n/a | разрешены | — |
| permissions duplicate | uniqueItems | reject | n/a | reject | — |
| background_task interval 1..10080, entry .js | = | = | n/a | = | через Go |
| network_hosts ≤64, unique после нормализации, без IP | maxItems/unique, без паттерна (аппроксимация) | = | n/a | = | через Go |
| theme/network_hook/routing: entry .json + capability+permission cross-check | только форма объекта | = | n/a | = | через Go |
| settings_schema property: type обязателен ∈ {string,integer,number,boolean} | = | = | n/a | = | через Go |
| панели требуют ui-panel + ui.panel | не выражает | = | n/a | = | через Go |
| bridge-методы панелей: getConnections, getServers, notify, getSettings, setSettings; ошибки permission-denied/invalid-argument/not-connected/internal; события session.connected/disconnected, network.changed, extension.disabled | n/a | host.go rpcPermissions (Go-тесты) | = | = bridge.dart _dispatch | mock = d.ts |

- Enforcement matrix: Go `enforcement.go` ↔ Dart `enforcement.dart`
  пиннится существующим `enforcement_dart_parity_test.go` (зелёный);
  permissions/Risk пиннятся `permission_matrix_test.go` и
  `tools/sora-ext/internal/validate/schema_sync_test.go`
  (schema enum ↔ реестр, required ↔ парсер, d.ts ↔ bridge). Не дублировал;
  дыры, которые эти тесты не закрывали, — ровно пункты «РАЗРЫВ» выше
  (Dart manifest nested-unknown/public_key/длины/manifest_version и
  битый base64 в sync): они были вне существующих пиннов.
- Прогон: `go test ./ext/` (core) — ok; `go test ./...`
  (tools/sora-ext, incl. schema_sync_test, pack) — ok. (Первый прогон
  tools дал FAIL по пакету cmd/sora-ext, при повторе всё зелёное и у
  пакета «no test files» — не воспроизвелось, вероятно чужой транзиентный
  churn дерева; зафиксировано честно.)

## 3. Revocation и catalog

### Catalog — РАЗРЫВ ×3 (Dart-валидация слабее Go; плюс Dart-файл не компилировался)

Формат один: `catalog.json` + `catalog.json.minisig`, team key,
trusted comment `timestamp:..\tfile:catalog.json\tsha256:..`
(Go `sign.go`: sigFileCatalog="catalog.json"; Dart `verifier.dart`:
verifyPayload(..., 'catalog.json', ...) — совпадает, проверка подписи
одна: sha256 payload в trusted comment + ed25519 по trusted comment;
placeholder ключа → fail-closed с обеих сторон).

1. **Dart `catalog.dart` не компилировался**: в
   `CatalogEntry.rolloutEligible` голое `sha256.convert(...)` резолвится
   в собственное поле записи `sha256` (String) — поле затеняет
   top-level `sha256` из `package:crypto`. `flutter analyze`:
   2 error (`undefined_method` :147, `invalid_assignment` :151) +
   warning unused import. ФИКС: префикс `crypto.` (коммит ниже).
   После фикса rollout-семантика Dart = Go (NUL-сепараторы, BE u64,
   mod 10000) — как пиннится Go `TestRolloutEligiblePinnedVectors`.
2. **Валидация записи каталога Dart принимала то, что Go отвергает**
   (пробы на одном и том же JSON): id без reverse-DNS паттерна
   (Dart: только non-empty; Go: idPattern), `version`/`min_app_version`
   не-semver (Dart не проверял вовсе), changelog version не-semver и
   date не-RFC3339 (Dart: tryParse → epoch 0 молча), unknown поля
   top-level/записи/changelog (Go: DisallowUnknownFields),
   `catalog_version: 1.0` (Dart принимал как ==1), `updated_at` не
   RFC3339 (Dart tryParse принимает даже `2026-10-20`).
   ФИКС: тот же Dart-коммит (зеркалит Go Validate/ParseCatalog).
3. Совпадают без фикса: badges {verified,top,new,staff}, https-only URL,
   sha256 64 hex (Dart нормализует в lowercase, Go принимает оба
   регистра), size 1..64MiB (Go maxPackageBytes=64<<20 = Dart),
   rating 0..5, rollout 0..1, screenshots ≤8 https, max_age 300..604800
   (default 3600), дубли id, author_key — ParsePublicKey с обеих сторон.

### Revocation — РАЗРЫВ (в Dart отсутствует целиком; спека)

- Go: полный стек — формат `revocations.json`
  (`revocation_version`, `updated_at`, `expires_at`, entries
  `{id, versions, reason}`, constraint-язык `* | =x.y.z | <x.y.z | <=x.y.z`,
  лимиты 64KiB/4096 записей/reason ≤280, дубли reject) в `revoke.go`;
  подпись team key (`VerifyRevocationList`, fail-closed до церемонии);
  транспорт+кэш `revocation_cache.go`; enforcement `Store`:
  install/update и enable отказывают отозванным, просроченный кэш —
  fail-closed для install/update; `cmd/sora-core/main.go` армяет кэш в
  Go-store при старте ядра.
- Dart: **ничего** — grep `revoc` по `app/lib/src/ext` и UI расширений:
  нет парсера списка, нет fetch/кэша, `ExtensionStore.install()` и
  `setEnabled()` (`app/lib/src/ext/store.dart`) revocation не проверяют.
  Пользовательский путь установки/включения в приложении обходит
  Go-enforcement (Go-store — отдельный реестр ядра для токенов хоста).
- Спека фикса (не реализована здесь — это подсистема, а не точечный
  фикс): (1) порт `revoke.dart`: модель+парсер с той же валидацией, что
  `ParseRevocationList`; (2) проверка подписи через существующий
  `verifier.dart` (file: `revocations.json`, team key, fail-closed);
  (3) `RevocationCache` аналог Go: fetch `revocations.json[.minisig]`
  с каталогового origin, кэш verified bytes в ext dir, fallback на кэш;
  (4) enforcement в Dart `ExtensionStore.install/installBytes` и
  `setEnabled` + disable-матчей при старте/обновлении каталога, с той же
  политикой просроченного списка, что в `revoke.go`.

## 4. Пример расширения — СОВМЕСТИМ (все 4)

Прогон фактически, без сети (`sora-ext validate`, собран из
tools/sora-ext):

| Пример | Schema (py jsonschema, draft 2020-12) | Go/CLI проект | Go/CLI пакет .soraext |
|---|---|---|---|
| hello-panel | OK | ✓ valid | ✓ valid |
| net-hook-dpi | OK | ✓ valid (warnings: dangerous+unimplemented net.hooks) | ✓ valid (те же warnings) |
| routing-split | OK | ✓ valid (warnings по routing.rules) | ✓ valid (те же warnings) |
| theme-midnight | OK | ✓ valid (warning: unimplemented theme.apply) | ✓ valid (тот же warning) |

Пакетная валидация включает подпись и checksums (`ext.OpenBytes` +
`Verify`) — shipped `.soraext` проходят целиком. Дополнительно после
фиксов прогнана и Dart-поверхность: `ExtPackage.open` + manifest parse
+ `verify()` (подпись+checksums, Dart verifier) по всем четырём
`.soraext` — все OK (standalone-проба с `--packages` на package config
приложения; в репозитории Dart-теста на примеры нет).

## Мои коммиты

Ветка `bugfix/audit-2026-10-19`, все — temp-index + CAS, чужие staged
изменения не затронуты (`git show --stat` по каждому — только свои
файлы):

- `ba625cf3` [seams-s4] sync: Dart QR decoder rejected every valid
  pairing payload — `app/lib/src/sync.dart` (ручной base64url-декодер с
  семантикой Go RawURLEncoding; id — UTF-8 байты; port — грамматика
  Atoi) + `app/test/sync_qr_test.dart` (+8 векторов). Проверка:
  flutter test sync_qr 29/29 (было 17/4 fail).
- `d508247f` [seams-s4] ext/catalog: Dart catalog did not compile;
  validation looser than Go — `app/lib/src/ext/catalog.dart`
  (префикс `crypto.sha256`; паритет валидации каталога с Go).
  Проверка: flutter analyze — 0 errors; спаренные Go/Dart пробы по
  общему корпусу дают одинаковые вердикты по всем векторам.
- `7aa0819f` [seams-s4] ext/manifest: Dart manifest parser looser than
  core/ext — `app/lib/src/ext/manifest.dart` (minisign-формат
  public_key, nested unknown fields, байтовые лимиты, строгий int
  manifest_version). Проверка: flutter analyze — 0 errors; Dart проба
  совпала с Go пробой по всем векторам корпуса.

Go-код не менялся: расхождения были на Dart-стороне зеркал; Go пробы
гонялись отдельным модулем в /tmp с replace-директивами на
service/sync и core (репозиторий не загрязнялся).

## Не проверено здесь

- mDNS на живой сети (sandbox без multicast): сверено по коду и
  контракту, не по эфиру.
- Flutter-тесты приложения целиком: гонялся только `sync_qr_test.dart`
  (целевой) — остальной app/test вне кластера и дерево app частично
  грязное чужими правками (l10n, pubspec.lock).
