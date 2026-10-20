# Аналитик №9 — device sync (F9)

Read-only анализ ветки `bugfix/audit-2026-10-19`, зона `service/sync/` + `app/lib/src/ui/sync.dart` + `app/lib/src/sync.dart` + `docs/sync-threat-model.md`.
Проверено инструментально: `go build ./...` — чисто, `go vet ./...` — чисто, `go test ./...` — все 5 пакетов `ok`.

---

## Вердикт

**Фундамент крепкий, фасад — театр. F9 нельзя считать done.**

Go-сервис (`service/sync`, ~3000 строк) — редкий случай честной криптографической инженерии: настоящий `Noise_XX_25519_ChaChaPoly_SHA256` (flynn/noise), привязка шифрованного канала к факту видения QR через `HMAC(token, handshake_hash)`, порядок «сначала token-confirmation, потом обмен long-term identity», гигиена хранения (0600, constant-time сравнение bearer-токена, атомарные записи, лимиты везде). Threat model (`docs/sync-threat-model.md`) необычно честен: явно фиксирует статус «app не wired», out-of-scope и accepted risks.

Но по главному критерию этой зоны — **никакого театра** — провал на стороне приложения, и он до сих пор в дереве:

- Экран показывает «Канал защищён сквозным шифрованием», хотя никакого канала нет (`app/lib/src/ui/sync.dart:166,249`).
- «Device paired» показывается после сканирования QR без какого-либо handshake (`app/lib/src/ui/sync.dart:54-77`).
- QR-форматы приложения и демона несовместимы (POWER-RUN это уже находил — не исправлено).
- Комментарии в UI-коде содержат **ложные** утверждения про скриншоты, прямо противоречащие threat model.
- Заявление «the loser is reported» в `service/sync/sync/sync.go:4` — неправда: механизм репорта конфликтов отсутствует.
- Threat model замалчивает два реальных свойства Noise_XX: раскрытие long-term identity public key неаутентифицированной стороне в LAN (и при спуфинге mDNS, и простым коннектом к sync-порту). Формулировка «spoofed mDNS answer can at most redirect… who then fails the cryptographic checks» вводит в заблуждение.

Итого: криптографическое ядро — зачёт; честность заявлений — незачёт. Ранжированные рекомендации ниже, P0 — блокеры для любых заявлений о готовности F9.

---

## Сильные стороны

1. **Пэйринг криптографически sound.** XX выполняется с эфемерным ключом в роли static с обеих сторон (`service/sync/transport/transport.go:196-216`, `service/sync/api/pairing.go:97-142`) — long-term ключи вообще не участвуют в пэйринге и не светятся. Joiner проверяет `peerKey == QR.pubkey` (`transport.go:200-206`); затем обе стороны обмениваются `HMAC-SHA256(token, handshake_hash)` (`transport.go:130-162`). Привязка к handshake hash делает бесполезным relay-MITM между двумя ногами (binding разный), а проверка ключа — подмену QR-ключа.
2. **Токен подтверждается ПОСЛЕ handshake по шифрованному каналу** — 16-байтный rendezvous-токен никогда не уходит в сеть открытым текстом.
3. **Порядок на стороне inviter: token-confirmation ДО exchangeIdentities** (`transport.go:322-343`). Неаутентифицированный пир, подключившийся к пэйринг-порту, не получает long-term identity инвайтера — handshake просто не доходит до обмена identity.
4. **Хранение ключей и токенов аккуратное:** `identity.json` (приватный ключ, base64) — 0600, атомарная запись (`service/sync/api/daemon.go:190-232`); `api_token` — 32 случайных байта, 0600 (`daemon.go:234-253`); сравнение bearer — `subtle.ConstantTimeCompare` (`daemon.go:256-263`); `http_addr` — 0600 (`cmd/sora-sync/main.go:66-68`).
5. **LAN-гейт против увода dial в интернет.** `lanAddr()` (`service/sync/api/pairing.go:60-66`) не даёт спуфнутому mDNS-ответу заставить демона выполнить XX с long-term ключом против интернет-стороны; комментарий честно фиксирует, что внутри LAN это свойство XX неустранимо. Проверки стоят и в `Join` (:215), и в `SyncPeer` (`service/sync/api/syncloop.go:100`).
6. **Лимиты везде, без дыр:** handshake 30s (`transport.go:33`), семафоры 4 (пэйринг) / 8 (sync), фреймы ≤64KB (`transport.go:75-90`), сообщение ≤64MiB, документ ≤16MiB (`sync/sync.go:64-67`), body API ≤17MiB (`api/http.go:11`).
7. **Защита от path traversal:** `safeName` (`service/sync/sync/store.go:40-51`) — только `[A-Za-z0-9._-]`, ≤128 символов, до обращения к файловой системе; записи атомарны через `.tmp` + rename, 0600.
8. **Случайная, но важная безопасность:** `upsertPeer` для уже известных пиров обновляет только `Name`/`LastSync`, но НЕ `IdentityKey` (`service/sync/api/daemon.go:287-303`). Скомпрометированный или врущий спаренный пир не может подменить хранимый identity key через поле `public_key` в самопровозглашённом JSON identity.
9. **Детерминированный tie-break в LWW:** `Put` — `sd.UpdatedAt >= doc.UpdatedAt → stored wins` (`service/sync/sync/store.go:133-137`). Без недетерминизма при равных метках.
10. **Тесты нетривиальные и зелёные:** e2e-пэйринг двух демонов через реальный путь QR→TCP→Noise→token→sync (`api/e2e_test.go`), regression-тест «stale TTL watcher не убивает новую сессию» (`api/pairing_concurrency_test.go`), тесты transport/sync/pairing.
11. **Threat model фиксирует обязательства приложения** («What the app must do», `docs/sync-threat-model.md:121-130`) и честно помечает их как design requirements, а не текущее поведение.

---

## Слоп / проблемы

### Блок A. Театр (главный критерий зоны)

**A1. Экран обещает сквозное шифрование, которого нет.**
`app/lib/src/ui/sync.dart:166` и `:249` рендерят `s.syncSecureNote` — «Канал защищён сквозным шифрованием. Никаких аккаунтов и облачных серверов.» (`app/lib/l10n/app_ru.arb:776`, en:630). Тот же файл в doc-комментарии (`:12-20`) честно признаёт: «no pairing handshake or document sync happens here». Пользователь видит обещание E2E на экране, где E2E нет. Это ровно тот театр, который находил POWER-RUN.

**A2. Ложное «Device paired».**
`_nameAndAdd` (`app/lib/src/ui/sync.dart:54-77`): сканирование QR → добавление в локальный Dart-реестр → снекбар `syncPaired` («Device paired», `app_en.arb:627`). Никакого handshake, никакого обмена ключами. Слово «paired» здесь — вымысел.

**A3. QR-форматы приложения и демона несовместимы (не исправлено с POWER-RUN).**
Dart генерирует `sora-sync://pair?v=1&token=<hex>` без `pub`/`port`/`id` (`app/lib/src/sync.dart:69-79`); `pairing.Decode` в демоне требует `pub` (32 байта), `token` (16 байт), `port`, `id` и отвергнет такой payload (`service/sync/pairing/pairing.go:74-110`). Комментарий в Dart («ключ приложит Go-сервис, когда он приземлится») — честное признание, но в дереве рядом живут два несовместимых формата, и UI-вариант — театр.

**A4. Ложные комментарии про скриншоты — противоречат threat model.**
`app/lib/src/ui/sync.dart:191`: «One token per shown code; rescanning a stale screenshot pairs nothing.» — неправда: QR содержит токен целиком; пересканирование скриншота в пределах TTL спарит устройство (в реальном флоу) либо добавит его в реестр (в текущем театре, `:54-77`). Там же `:208-212`: «the token is intentionally not exposed as text (a screenshot must not be pairable)». Threat model говорит обратное: «Anyone who captures the QR during the 5-minute window can pair» (`docs/sync-threat-model.md`, Out of scope). Комментарии в коде утверждают противоположное документу угроз.

**A5. «Спаренное» устройство, которое никого не спаривало.**
`app/lib/src/sync.dart:26-28`: «A device paired for end-to-end encrypted sync (F9)» — про `SyncedDevice`, запись в локальном JSON-реестре настроек, не участвовавшую ни в каком пэйринге.

**A6. Обещания про «что синкается» без механизма.**
`app/lib/l10n/app_en.arb:616` (`syncEmpty`): «Pair another device to keep subscriptions, rules and settings in sync» — ничего не синкается. `:625` (`syncWhatBody`): «Never synced: local logs, IPC tokens» — в демоне **нет фильтрации по kind**: документы — opaque blobs, и если app-слой сделает `PUT /v1/documents/ipc-token/x`, это уедет пиру (`service/sync/api/http.go:156-190`). Заявление без enforcement — театр.

**A7. «The loser is reported» — неправда.**
Пакетный комментарий `service/sync/sync/sync.go:4`: «Conflicts resolve last-write-wins by updated_at, and the loser is reported so the client can notify the user about what arrived». `Report` (`sync.go:98-103`) содержит только `Pulled`/`Pushed []Meta`, без флага «перезаписал локальную версию» и без `from` (в `Meta` поля `from` нет). Клиент физически не может выполнить обязательство threat model (`docs/sync-threat-model.md:127`: «notify the user with kind/name/from») — `from` в sync-отчёте отсутствует (он есть только в `GET /v1/documents/{kind}/{name}`, `api/http.go:193-207`). Локальная правка пользователя тихо затирается более новой версией пира, и UI не может об этом даже узнать.

### Блок B. Криптография и пробелы threat model

**B1. Threat model замалчивает раскрытие identity public key через XX.**
`docs/sync-threat-model.md:74`: «A spoofed mDNS answer can at most redirect the joiner to an attacker, who then fails the cryptographic checks». Это неполно. В Noise_XX сообщение 2 (`<- e, ee, s, es`) шифрует `s` ключом, выведенным только из `ee`, а сообщение 3 (`-> s, se`) — из `ee+es`; обе стороны, завершившие свою половину handshake, могут расшифровать чужой static key. Следствия:
- **Dial-сторона:** спуфнутый mDNS-ответ на известный пир → `SyncPeer` → `transport.DialKnown` с long-term ключом (`service/sync/api/syncloop.go:82-123`): атакующий-«респондер» расшифровывает сообщение 3 и получает long-term identity public key устройства до того, как проверка `peerKey` упадёт. Комментарий в `api/pairing.go:54-59` это честно признаёт («inherent to the XX pattern and cannot be fixed in the transport»), но threat model — нет.
- **Accept-сторона (хуже, нигде не задокументировано):** любой участник LAN может подключиться к постоянному sync-слушателю (`api/syncloop.go:20-58`, bind `0.0.0.0`) и из сообщения 2 извлечь identity public key без какой-либо аутентификации. `verify` в `AcceptKnown` срабатывает позже и ключ уже раскрыт.
Эффект — не компрометация (ключ публичный), а стабильный межсетевой трекинг-идентификатор устройства. Для продукта, заявляющего «no accounts, no cloud», это должно быть в accepted risks явно, иначе формулировка про «at most redirect» вводит в заблуждение.

**B2. Постоянный mDNS-маяк.**
`StartSyncListener` (`service/sync/api/syncloop.go:20-58`) рекламирует `sora-sync-<deviceID>` с TXT `id=<deviceID>` (`service/sync/discovery/discovery.go:28-48`) **всё время работы демона**. Device ID стабилен и совпадает с long-term identity ID — пассивное наблюдение за присутствием устройства в LAN любым участником сети. Пэйринг-реклама ограничена TTL 5 минут (правильно), sync-реклама — бессрочна. Приватность можно улучшить без потери функциональности.

**B3. Пэйринг-сессия не закрывается после успеха — QR многоразовый.**
`handlePairingConn` (`service/sync/api/pairing.go:146-168`) не останавливает сессию после успешного пэйринга+синка; `pairingLoop` продолжает принимать коннекты до истечения TTL. Сфотографировавший QR может спарить второе устройство в течение 5 минут. UI («Waiting for the other device…», `sync.dart:237`) подразумевает одноразовость. Это продуктовое решение, но сейчас оно принято молча.

### Блок C. Конфликты и потеря данных

**C1. LWW по часам пира без защиты от skew — тихая необратимая потеря.**
Пир с убежавшими вперёд часами (или злонамеренный спаренный — threat model доверяет пиру полностью, но часы плывут и без злого умысла) навсегда выигрывает конфликты: `Put` отбрасывает локальные правки (`service/sync/sync/store.go:133-137`), конфликтных копий нет, бэкапа затёртого нет, уведомления нет (см. A7). Для VPN-конфигов (подписки, правила) это сценарий «рабочая конфигурация молча заменена, пути назад нет».

**C2. Пир записывается в реестр до завершения синка, ошибка игнорируется.**
`service/sync/api/pairing.go:154-156`: `_ = d.upsertPeer(...)` до первого синка («Recorded early»). При нес
...[truncated 4419 chars]