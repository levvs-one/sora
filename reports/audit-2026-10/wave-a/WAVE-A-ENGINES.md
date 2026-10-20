# WAVE A — бампы движков с валидацией на реальных бинарях

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`, без пуша (родитель
батчами). Все вердикты — по фактическим запускам скачанных бинарей
(Linux amd64), а не по релиз-нотам.

## Итог пинов

| Движок | Было | Стало | Дайджест: источник → сверка по факту |
|---|---|---|---|
| sing-box-lx | v1.14.3-lx.14 | **v1.14.3-lx.22** | GitHub API asset digest → sha256 скачанных архивов, все 4 арки совпали |
| Xray | v26.3.27 | **v26.10.17** | официальный `.dgst` релиза → sha256 скачанных архивов, все 4 арки совпали |
| mihomo | v1.19.32 | v1.19.32 (без изменений) | новее стабильного нет: выше только `Prerelease-Alpha`, пререлиз в пин не берётся |

`fetch.sh amd64` на новых пинах: зелёный полностью — sing-box
verified, xray «lock digest matches upstream .dgst» + verified,
mihomo verified; `engines.digests` выпускается как прежде. Версии
бинарей по факту: `sing-box version 1.14.3-lx.22` (теги with_xhttp,
with_awg, with_quic, with_wireguard на месте), `Xray 26.10.17`,
`Mihomo Meta v1.19.32`.

## sing-box-lx lx.14 → lx.22

- Закрыт релизный флаг прохода 3: в пине больше нет lx.14 с критичным
  **GHSA-p77j-4mvh-x3m3** (gRPC auth-bypass, фикс в lx.15) и падением
  на win7-386; lx.22 — актуальный верхний релиз форка на день бампа
  (форк ушёл дальше lx.21 из исследования WEB-RESEARCH-5).
- Гейт форка в `BuildCapabilities` (prerelease `lx.*`, база ≥ 1.14.3,
  теги with_xhttp/with_awg) перевалидирован на реальном бинаре: теги
  присутствуют, способности строятся.
- **Сценарий фикса lx.15 проверен сквозным трафиком**: клиент
  sing-box lx.22 с фингерпринтами `randomized` и `random` против
  REALITY-сервера Xray 26.10.17 (≥26.9.8) — 8/8 успешных запросов
  через туннель (по 4 рестарта процесса на фингерпринт). На lx.14 эта
  связка умирала в ~25–40% процессов (монетки ALPN / гибридного
  key share).
- Рендеры и deprecation-логика по базовой версии не изменились: база
  форка по-прежнему 1.14.3, stack/multi_queue-гейты (`< 1.15`) ведут
  себя как прежде; коммент в render.go обновлён lx.14 → lx.22.

## Xray 26.3.27 → 26.10.17

- **Порог отказа от plaintext перепроверен на бинаре**: plaintext
  VLESS на публичный адрес — `Failed to load config ... vless without
  TLS or other encryption is prohibited unless the server address is
  a private IP or domain`; тот же конфиг на loopback загружается.
  Гейт `xrayCutsPlaintext`/`XrayPlaintextMissing` (cutoff 26.7.11)
  теперь жив и для поставляемого пина; комменты в catalog.go,
  утверждавшие «пин предшествует cutoff, гейт — no-op», переписаны.
  Нюанс зафиксирован в коде: upstream разрешает plaintext на
  приватные адреса, sora остаётся строже (fail closed) — осознанно,
  не расхождение ради расхождения.
- `allowInsecure` в 26.10.17 **удалён** (миграция на
  pinnedPeerCertSha256/verifyPeerCertByName). Рендерер sora его не
  эмитит (pinned тестом), план-гейт уже отклонял такие планы от Xray —
  ломать нечего, подтверждено загрузкой конфигов.
- **Фингерпринт: посылка задачи опровергнута измерением.**
  Утверждение «v26.10.17 вышел с hellochrome_155» на бинаре НЕ
  подтвердилось:
  - явное имя `hellochrome_155` отклоняется при загрузке конфига
    (`unknown "fingerprint"`) — и в tlsSettings, и в realitySettings;
    именованные Chrome-попугаи заканчиваются на hellochrome_133
    (hellofirefox_148 при этом существует);
  - захват ClientHello на проводе: `chrome`, `hellochrome_auto` и
    `hellochrome_133` шлют **один и тот же** JA4
    `t13d1516h2_8daaf6152771_d8a2da3f94cd` — это Chrome 133 (гибридный
    X25519MLKEM768 key share в hello есть).
  Вывод: бамп Xray НЕ чинит замороженный Chrome-133 — ценность бампа
  в остальном (plaintext-отказ, удаление allowInsecure, фиксы
  Hysteria2/XHTTP/VLESS Encryption). Тексты в `fingerprint.go`
  (landscape и `FingerprintWarning`) переписаны с «pinned 26.3.27,
  коммит в main, релиза нет» на измеренный факт по пину 26.10.17;
  предупреждение для явного hellochrome_155 сохранено — оно остаётся
  правдой. `DefaultXrayFingerprint = hellochrome_auto` не тронут.
- `Catalog[KindXray].MinVersion` оставлен «26.3.27» как capability
  floor (старейшая проверенная для Hysteria2/XHTTP/VLESS Encryption
  рендеров сборка); коммент переписан — раньше он неверно называл
  пол «поставляемой сборкой».

## mihomo: клеймы XHTTP перевёрнуты по `mihomo -t`

Каталог сознательно не давал mihomo `FeatureXHTTPDownloadSplit` и
`FeatureXHTTPXmux` до бинарной проверки форм download-settings /
reuse-settings. Проверка выполнена на пине 1.19.32: новый постоянный
тест `mihomo.TestBinaryAcceptsXHTTPDownloadSettings` рендерит split-
план (download-settings со своим reuse-settings + настроенный
reuse на аплинке) и гоняет `mihomo -t` на реальном бинаре — PASS
(геоданные в home теста сеются из engines-dir, как в проде, иначе -t
лезет качать GeoIP.dat из сети). Клеймы перевёрнуты в том же коммите,
как предписывал коммент каталога; заодно переписаны:
`TestCatalogXmuxClaimMatchesRenderers` (паритет клейм↔рендерер в
пост-верификационном состоянии), комменты в catalog.go (обе записи),
plan.go и engine.go. Xmux/split-планы теперь честно маршрутизируются
на mihomo вместо «missing на всех движках».

## Сквозные прогоны (SORA_ENGINES_DIR на новых бинарях)

- `go test ./engine/...` — зелёные на новых бинарях (engine,
  engine/mihomo, engine/singbox, engine/xray с `-count=1`).
- **Interop: найдена и починена реальная поломка от бампа Xray.**
  После бампа вся трафик-матрица `TestEveryEngineCarriesTraffic...`
  умирала по таймаутам (~30 с/кейс). Изоляция (старый/новый
  клиент×сервер) указала на сервер Xray 26.10.17; debug-лог сервера
  дал строку `proxy/freedom: blocked target: tcp:127.0.0.1:<port>,
  blackholing connection for 1m17s`. Причина — в исходнике
  v26.10.17 (`proxy/freedom/freedom.go`, `getDefaultFinalRule` /
  `defaultBlockPrivateRule`): freedom без явных `finalRules`
  тарпит на 30–90 с все приватные адреса (включая loopback), если
  запрос пришёл с vless/vmess/trojan/hysteria/wireguard/
  shadowsocks-инбаунда — новая upstream-защита от SSRF для
  публичных серверов. Тестовый сервер harness — ровно этот паттерн
  (vless→freedom→loopback-цель). Продуктовый код sora так не делает
  (клиентские инбаунды — socks/mixed/tun; правило к ним не
  применяется), поэтому фикс — в harness: freedom тестового
  сервера получил явный `finalRules: [{action: allow}]` с
  комментом-обоснованием (коммит 589e56b8). Итог на новых бинарях:
  **0 таймаутов во всей матрице**, трафик идёт через все три движка.
  - Отдельно честно: XHTTP-TLS-кейсы матрицы (12 шт., все три
    клиента) по-прежнему падают быстрым 502 — та же CA-сигнатура,
    что на старых пинах (см. ниже); пин mihomo не менялся, так что
    и его 4 кейса не могут быть регрессией бампа. REALITY-сценарий
    freedom-тарпит НЕ трогает: sing-box lx.22 c `randomized` и
    `random` против REALITY-сервера Xray 26.10.17 — 8/8 + чистый
    повтор 4/4, 0 blackhole-строк в серверном логе (сценарий фикса
    GHSA-класса из lx.15 жив на новой связке).
  - Урок процесса: часть промежуточных ручных проб в ходе изоляции
    оказалась загрязнена осиротевшими процессами движков от убитых
    прогонов (ответы приходили не от поднятого стенда). Решающими
    были только пробы с серверным debug-логом на свежих портах и
    чтение исходника — в отчёте опираемся только на них.
- Известный артефакт окружения, НЕ регрессия бампа:
  `registry.TestMeasureRoutesEachServerToAnEngine` (delay-тест через
  clashapi к локальному HTTPS с тестовой CA) падает на sing-box и
  mihomo **идентично на старых (lx.14/26.3.27) и новых бинарях** —
  сигнатура совпадает байт-в-байт (503 + «bad certificate» в логе
  тестового сервера); xray-подтест проходит в обоих мирах.
  Проверено контрольным прогоном на отдельно скачанных старых пинах.

## Коммиты (ветка bugfix/audit-2026-10-19, все — temp-index+CAS)

- `7320f1a0` — `[engines]` engines.lock: sing-box-lx lx.14→lx.22,
  Xray 26.3.27→26.10.17 (все арки, дайджесты по факту скачивания).
- `fffd20b0` — `[engines]` перевалидация гейтов и фингерпринтов на
  новых пинах (catalog.go, fingerprint.go, engine_test.go,
  README).
- `3e2f738c` — `[engines] repair fffd20b0`: форвард-фикс — из
  fffd20b0 убраны два ханка, попавшие при экстракции патча из
  общего worktree: чужой WIP (selector default в singbox/render.go,
  остался в worktree за своим отделом) и parity-тест xmux,
  переехавший в коммит клеймов ниже.
- `ba4c3642` — `[engines]` коммент render.go: валидационная сборка
  multi-queue — lx.22 (возвращён после repair выше).
- `dadf16d2` — `[engines]` клеймы mihomo XHTTP split/xmux после
  `mihomo -t`: catalog.go, engine.go, plan.go, parity-тест,
  новый `mihomo/binary_xhttp_test.go`.
- `589e56b8` — `[interop]` freedom тестового сервера: явный
  finalRules-allow (фикс блэкхола Xray 26.10.17, см. выше).

Финальная верификация — в чистом worktree от HEAD (без чужого WIP):
`go build ./... && go vet ./...` чисто; `go test ./...` — 37
пакетов ok, единственный фейл — известный артефакт длины пути
unix-сокета (`TestDetectCensorshipEventsWithoutOffsetsStayUnknown`,
падает при длинном TMPDIR и зелёный при `TMPDIR=/tmp`; к бампу
отношения не имеет). `control/` и `routing/` с SORA_ENGINES_DIR
на новых бинарях — зелёные, кроме того же сокет-артефакта.

## Осталось / не входило

- Арки arm64/windows/win7-386: дайджесты сверены по факту скачивания
  всех 8 архивов; запускаются только amd64-бинари (машина amd64) —
  как и предписывала постановка.
- Social-preview/скриншоты и dev-машинная верификация Dart/C# — зоны
  других отделов волны A.
