# CENSOR-P2-FIX — Transport.Headers на gRPC/TCP (и h2): silent drop закрыт

Дата: 2026-10-21. Ветка `bugfix/audit-2026-10-19`, строго локально, пуша нет.
Коммит: `1ec55191` `[censor] P2 fix: Transport.Headers no longer drops
silently on grpc/tcp/h2 …` (13 файлов, +476/−0; посажен temp-index + CAS
поверх `5b0966e0`, staged-stat проверен непосредственно перед
write-tree — ровно мои 13 файлов; разработка и тесты велись в чистом
worktree от HEAD, общее дерево и чужие staged/WIP не тронуты).
Замечание: CENSOR-P2-REVIEW §3 (Minor вне мандатного списка P2) —
`Transport.Headers` на gRPC и TCP планом не гейтился: план с заголовками
для транспорта, где рендеры их не пишут, терял набор молча.

## 1. Карта по факту кода и пинов

Пины подтверждены на бинарях (`~/workspace/.engines-amd64`): sing-box
1.14.3-lx.22, Xray 26.10.17, mihomo 1.19.32. Пробы — ручные конфиги на
пинарях (не рендеры sora), UA `ProbeUA/1.0`:

| Транспорт | sing-box lx.22 | Xray 26.10.17 | mihomo 1.19.32 |
|---|---|---|---|
| ws | бинарь: headers ✅; рендер sora: ✅ (P2) | ✅ / ✅ (P2) | ✅ / ✅ |
| httpupgrade | ✅ / ✅ (P2) | ✅ / ✅ (P2) | ✅ (ws-opts) / ✅ |
| xhttp | ✅ / ✅ (P1) | ✅ / ✅ (P1) | ✅ (xhttp-opts) / ✅ |
| **h2** | бинарь: **headers ✅** (`check` принял; мусорный ключ отклонён — поле настоящее); рендер sora: ❌ писал только host/path → **silent drop** | транспорта h2 нет вообще (удалён; рендер sora именованно отказывает любому h2) | бинарь: h2-opts = {host, path}, **ключа headers нет**; рендер sora: ❌ не писал → **silent drop** |
| **grpc** | бинарь: ❌ (`check`: `json: unknown field "headers"`); рендер sora: ❌ не писал → **silent drop** | бинарь: ❌ (grpcSettings = serviceName/authority/multiMode/user_agent, generic headers нет); рендер sora: ❌ → **silent drop** | бинарь: ❌ (grpc-opts = service-name/user-agent); рендер sora: ❌ → **silent drop** |
| **tcp / "" (raw)** | бинарь: ❌ (нет handshake); рендер sora: ❌ → **silent drop** | ❌ / ❌ | ❌ / ❌ |

Методическая оговорка по пробам: `xray run -test` и `mihomo -t`
**принимают и мусорные ключи** (пробы с `bogusKeyZZZ`/`bogus-key-zzz` —
«Configuration OK»/«successful»), поэтому для Xray и mihomo принятие
конфига доказательством не является: факт «поля нет» для них — состав
их транспортов (grpcSettings/grpc-opts/h2-opts на пинах, как уже
зафиксировано ревью P2 для соседних полей). Для sing-box, наоборот,
принятие — доказательство: неизвестные ключи он отклоняет фатально.

Вывод карты: заголовки концептуально существуют только у
HTTP-handshake транспортов. На grpc generic-headers не пишет **ни
один** движок (кастомизация gRPC уже живёт в отдельных полях плана
GRPCAuthority/GRPCMultiMode/GRPCUserAgent со своими P2-гейтами); на
tcp/raw handshake нет в принципе. На h2 поддержка различается по
движкам — это ровно случай каталог-гейта по образцу P2.

## 2. Реализованное правило

Заголовки либо доезжают до рендера движка, который их реально пишет,
либо план именованно отклоняется. По уровням, в стиле P2:

1. **Валидация плана** (`core/engine/validate.go`,
   `validateTransportFields`): непустой `Headers` на транспорте вне
   {ws, httpupgrade, xhttp, h2} — ошибка
   `outbound <id>: headers need the ws, httpupgrade, xhttp or h2 transport, not "<type>"`
   (пустой тип именуется `tcp`). Ошибка называет транспорт и outbound,
   **не содержит ни ключей, ни значений заголовков** (значения могут
   быть секретами; закреплено тестом с `X-Auth: HeaderSecretValue`).
2. **Каталог-гейт для h2** (данные, не хардкод в рендерах): новая
   фича `FeatureH2Headers = "h2-headers"` (`engine.go`);
   `Plan.RequiredFeatures` требует её при `Type=="h2" && len(Headers)>0`
   (`refs.go`); в каталоге её заявляет только sing-box (`catalog.go`).
   На mihomo/Xray план с h2+headers получает `feature h2-headers` в
   Missing и не маршрутизируется туда. На ws/httpupgrade/xhttp гейт не
   нужен — пишут все три рендера.
3. **Рендер sing-box h2** (`singbox/render.go`): http-транспорт теперь
   эмитит `headers` (Host-поля это не касается: host остаётся своим
   списком, как пишет пин).
4. **Render-backstop'ы** (по образцу gRPC authority в P2): все три
   рендера именованно отказывают по headers на grpc и tcp; mihomo —
   дополнительно на h2 («sing-box-only»). Тексты не эхоят заголовки.

Документация поля `Transport.Headers` в `plan.go` обновлена под новое
правило. Детерминизм рендеров не тронут (map-маршал как раньше; есть
отдельный тест байт-идентичности h2-рендера с 4 заголовками).

## 3. Тесты

Новые файлы (все `*CensorP2Fix*` / `*Headers*`):

- `core/engine/censor_p2_headers_test.go` — каждый транспорт ×
  (пустые/отсутствующие headers — валиден; непустые — рендер-носители
  ок, grpc/tcp/"" — именованный отказ с транспортом и без утечки
  ключа/значения в текст ошибки); каталог-гейт h2-headers
  (RequiredFeatures + Missing по трём движкам, пустой набор — без гейта).
- `core/engine/singbox/censor_p2_headers_test.go` — h2 рендерит полный
  набор (Host не сворачивается в headers), grpc/tcp/"" — отказ,
  детерминизм.
- `core/engine/singbox/censor_p2_headers_binary_test.go` —
  `TestBinaryAcceptsCensorP2FixH2Headers`: реальный рендер h2+headers
  принят `sing-box check` на пине lx.22.
- `core/engine/xray/censor_p2_headers_test.go` — grpc/tcp/"" — отказ;
  регрессия P2: ws/httpupgrade/xhttp по-прежнему несут набор.
- `core/engine/mihomo/censor_p2_headers_test.go` — grpc/tcp/""/h2 —
  отказ; регрессия: ws и xhttp по-прежнему несут набор.

## 4. Прогоны

- `go build ./...` (core) — чисто; `go vet ./engine/... ./parser/...
  ./control/` — чисто; gofmt по тронутым файлам — чисто.
- `go test` (чистый worktree от HEAD `86c9c2a2`, затем повторно на
  landed-коммите `1ec55191`): пакеты `engine/singbox`, `engine/xray`,
  `engine/mihomo` — **полностью ok** (включая все binary-тесты на
  пинах: существующие `TestBinaryAcceptsCensorP2Transports` трёх
  движков и новый h2); `parser`, `engine/registry`, `engine/bypass`,
  `engine/supervise`, `engine/probeexec`, `engine/stealth` — ok.
- Чужие предсуществующие падения (проверено перепрогоном на чистом
  HEAD **без** моих правок — падают идентично; не чинил, чужие зоны):
  - `engine`: `TestCensorP1KeyShareGate` (P1; отмечен ещё ревью P2) и
    `TestCatalogXmuxClaimMatchesRenderers` (xmux claim vs render).
  - `control`: `TestCredentialDocumentMatchesLegacyMapForm` (xmux-поля
    credential document, зона P1 — та же, что эскалация §5).
  - Один широкий прогон (`./engine/... ./parser/... ./control/`
    одной командой) был убит системой (SIGKILL, `failure_kind:
    system_kill` — VM делят сотни агентов); повтор меньшими порциями
    `-p 1` прошёл, результаты выше.

## 5. Граница фикса (эскалация P2 №3 не тронута)

Гейт покрывает планы, построенные через API/парсеры, где
`Transport.Headers` присутствует как данные плана. Известный разрыв
источника данных — эскалация §5.1 отчёта CENSOR-P2: ни proto-контракт,
ни credential document (`core/control/plan.go`) поля headers не несут,
поэтому импортированная подписка передать WS-заголовки в план пока не
может. Это чужая зона контракта (файл в чужой активной работе) — в этом
фиксе не трогал; как только поле появится в credential document, план
с заголовками сразу попадёт под здешние гейты без дополнительных
изменений.
