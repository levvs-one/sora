# OpenLibre / olcRTC — анализ транспортного пути интеграции в sora

Подотдел транспорта, департамент OpenLibre. Этап: АНАЛИЗ и обоснование. Код продукта не писался; единственный исполняемый артефакт этапа — замер размера в песочнице `/tmp/olcrtc-size-check` (не в дереве sora).

Ревизии источников:

| Репозиторий | Путь | Ветка/HEAD |
|---|---|---|
| sora | `~/workspace/bug-hunt/sora` | ветка `bugfix/audit-2026-10-19` |
| olcrtc | `~/workspace/openlibre-ref/olcrtc` | HEAD на момент анализа (см. `SPEC.md` того же каталога: `f3ad8fb`) |

Префиксы цитат: `[sora]` — файл внутри sora, `[olc]` — внутри olcrtc. Парсинг ссылок `olcrtc://` — зона подотдела ссылок; здесь он затронут только в объёме, нужном транспорту (см. также `SPEC.md` в этом каталоге). Здесь: как трафик sora физически доходит до olcRTC-эгресса и обратно.

---

## 0. Рекомендация одной строкой

**Основной путь — (B) сайдкар-бинарь `olcrtc` в режиме `cnc`, встроенный по образцу zapret/tpws: digest-проверка по `engines.digests`, запуск и надзор через `core/engine/supervise`, план переписывается на loopback SOCKS5-аутбаунд (образец — `core/engine/bypass.Rewrite`). Запасной путь — (A) встраивание `pkg/olcrtc/client` в core тем же декоратором, если сайдкар упрётся в пакетирование/Windows. Путь (C) — нативная перереализация — отклонён.**

Почему не наоборот — §5 и §8. Ключевой структурный факт, на котором стоит вся рекомендация: **публичный API olcrtc не даёт ни `net.Conn`, ни Dialer — только готовый локальный SOCKS5-слушатель** (§1.2). Поэтому во всех вариантах, кроме нативной перереализации, точка сопряжения одна и та же — «движок sora ходит SOCKS5-аутбаундом в loopback-слушатель olcrtc». Различаются варианты только тем, *в каком процессе* живёт olcrtc и *как* он поставляется и надзирается. А это ровно та задача, которую sora уже решила для zapret.

---

## 1. pkg/olcrtc: фактический API

Публичная поверхность — три пакета под `pkg/olcrtc/` плюс gomobile-обёртка `mobile/`. Всё остальное — `internal/`, снаружи недоступно (и не нужно).

### 1.1. `pkg/olcrtc/client` — клиент (нужен sora)

Пакетная документация: «Package client exposes the olcrtc SOCKS5 tunnel client as an embeddable Go library. New registers the built-in providers, engines, and transports automatically» — `[olc] pkg/olcrtc/client/client.go:1-3`.

Сигнатуры дословно:

```go
// pkg/olcrtc/client/client.go:112
func New(cfg Config) *Client

// pkg/olcrtc/client/client.go:118
func (c *Client) Run(ctx context.Context) error

// pkg/olcrtc/client/client.go:123
func (c *Client) RunWithReady(ctx context.Context, onReady func()) error

// pkg/olcrtc/client/client.go:131
func (c *Client) RunWithAddress(ctx context.Context, onReady func(actualAddr string)) error
```

`Config` (`[olc] pkg/olcrtc/client/client.go:79-103`) — плоская структура, все параметры подключения задаются через неё:

| Поле | Смысл |
|---|---|
| `Transport string` | `datachannel` / `videochannel` / `seichannel` / `vp8channel` (реестр: `[olc] internal/app/session/config.go`, `RegisterDefaults`) |
| `Provider string` | `jitsi` / `telemost` / `wbstream` / `none` |
| `RoomURL string` | ID или URL комнаты провайдера |
| `ChannelID string` | опциональный ID канала маршрутизации пиров |
| `Engine string`, `URL string`, `Token string` | прямой режим SFU при `Provider == "none"` |
| `ProviderToken string` | предвыпущенный токен провайдера (wbstream) |
| `KeyHex string` | PSK туннеля, строго 64 hex-символа = 32 байта (валидация: `[olc] internal/app/session/validate.go`, `validateKey`: `hex.DecodeString` + `len != chacha20poly1305.KeySize` → `ErrKeyInvalid`) |
| `LocalAddr string` | адрес локального SOCKS5-слушателя, напр. `127.0.0.1:0` |
| `SOCKSUser`, `SOCKSPass string` | опциональная аутентификация на локальном слушателе |
| `DNSServer string`, `Resolver *net.Resolver` | резолвер для сигналинга/провайдера |
| `TransportOptions TransportOptions` | один из `VideoOptions` / `VP8Options` / `SEIOptions` (интерфейс с неэкспортированным методом — чужие реализации невозможны, только три встроенные структуры) |
| `Liveness`, `Traffic` | контрольный ping/pong и шейпинг пейлоада |
| `DeviceID`, `DeviceIDPath`, `Claims map[string]any` | идентичность для handshake/авторизации у оператора эгресса |
| `OnHealth HealthFunc` | колбэк снапшотов здоровья контрольного потока (`control.Status`) |

Жизненный цикл: `Run*` **блокирует** до отмены контекста или конца конференции; готовность = колбэк `onReady(actualAddr)` после открытия слушателя. Отдельных `Start/Stop/State` нет — остановка только отменой `ctx`, ожидание завершения — возвратом `Run`. Реконнекты к SFU и ре-хендшейк при ротации пира библиотека делает сама внутри (`[olc] internal/client/link.go`, `bringUpLink`/`handleReconnect`).

### 1.2. Что возвращает клиент: только SOCKS5-слушатель. Ни Conn, ни Dialer

Это главный факт этапа. `Client` не экспонирует ни одного метода получения соединения. Единственный выход в мир — TCP-слушатель:

```go
// [olc] internal/client/client.go:151
listener, err := (&net.ListenConfig{}).Listen(runCtx, "tcp4", cfg.LocalAddr)
```

Далее `internal/client` обслуживает на нём SOCKS5 (`[olc] internal/client/socks.go`):

- только команда `CONNECT` (код 1); иное → `ErrUnsupportedSOCKSCommand`. **UDP ASSOCIATE нет**;
- адресные типы IPv4/домен/IPv6 на входе, но слушатель — `tcp4`, а эгресс на сервере — тоже `tcp4` (§4): сквозной IPv6-таргет недостижим;
- доменные имена **не резолвятся на клиенте**: домен уходит строкой в JSON-запрос `{"cmd":"connect","addr":...,"port":...}` по smux-потоку (`[olc] internal/client/tunnel.go`, `sendConnectRequest`) и резолвится резолвером эгресса. Для sora это правильная семантика (аналог socks5h): DNS таргетов не утекает в локальный резолвер;
- аутентификация user/pass — константно-временная (`[olc] internal/client/socks.go`, `socks5UserPassAuth`, `subtle.ConstantTimeCompare` по обеим половинам);
- лимиты: переговорный таймаут 30 c, максимум 512 одновременных соединений.

Шифрование и мультиплексирование внутри: PSK → направленные ключи HKDF, рекорды XChaCha20-Poly1305 (слой «OLC2», анти-реплей окно) — `[olc] internal/crypto/chacha.go:1-6`; поверх — `xtaci/smux`, контрольный поток с liveness ping/pong.

### 1.3. `pkg/olcrtc/engineconn` — не альтернатива

Может показаться «низкоуровневой» точкой входа, но для продукта непригоден по собственному описанию: «This package does not provide tunnel encryption, handshake, smux, SOCKS, or liveness. Use package client or tunnel for the complete product stack» — `[olc] pkg/olcrtc/engineconn/engineconn.go:1-6`. Его `Dial` сознательно возвращает не `net.Conn`:

```go
// pkg/olcrtc/engineconn/engineconn.go:154
func (s *Session) Dial(ctx context.Context) (io.ReadWriteCloser, error)
```

(комментарий там же: поток «intentionally implements io.ReadWriteCloser rather than net.Conn because engine writes do not support context cancellation or interruptible deadlines»). Сырой байтовый поток одного SFU-движка без шифрования — строительный блок транспортов olcrtc, а не транспортный API. В интеграции не используется.

### 1.4. `pkg/olcrtc/tunnel` — серверная библиотека (sora НЕ нужна)

Зеркальный пакет для эгресса: `func New(cfg Config) *Server` и `func (s *Server) Run(ctx context.Context) error` — `[olc] pkg/olcrtc/tunnel/tunnel.go:127,133`. Подробнее — §4: sora — клиентский продукт, серверная часть ей не требуется.

### 1.5. CLI `cmd/olcrtc` — интерфейс сайдкара

```
olcrtc <config.yaml>
```

«All runtime settings come from the YAML file. There are no other CLI flags» — `[olc] cmd/olcrtc/main.go:1-6`. Ровно один аргумент; режимы — полем `mode` внутри YAML: `srv` (сервер-эгресс), `cnc` (клиент с SOCKS5), `gen` (генерация room ID) — `[olc] internal/app/session/config.go`, константы `ModeSrv/ModeCnc/ModeGen`; диспетчер — `[olc] internal/app/session/run.go`, `runOnce` → `runServer`/`runClient`. Есть failover-профили поверх нескольких конфигов (`[olc] internal/supervisor/supervisor.go`, `Run`), graceful shutdown по SIGINT/SIGTERM с grace 5 c (`[olc] cmd/olcrtc/main.go`, `runManaged`/`shutdownGrace`).

Следствия для сайдкар-варианта:

- **Версии у бинаря нет.** Ни `--version`, ни version-строки в выводе: запуск без аргумента — ошибка `usage: olcrtc <config.yaml>`. Пробер вида sora (`supervise.Prober`: выполнить `--version`-подобные аргументы, распарсить первую строку) к нему неприменим — только digest-проверка, как для tpws (§2.4).
- **Конфиг — только файлом.** `supervise.Spec.Config` (конфиг через stdin, `[sora] core/engine/supervise/process.go:24-37`) использовать нельзя: olcrtc читает путь из argv. Файл придётся писать в runtime-home сайдкара (см. §5.B про секретность).
- **Готовность не анонсируется наружу** машиночитаемо (только лог-строка `SOCKS5 server listening on ...`). Надзору нужен поллинг порта — прецедент есть (§2.4).
- YAML строгий: неизвестный ключ — ошибка (`[olc] internal/config/config.go`, `Load`, `KnownFields(true)`). Рендер конфига из плана обязан эмитить только известные поля — это плюс: опечатка в рендерере падает сразу, а не молча.

Схема YAML — `[olc] internal/config/config.go`, `File`/`Settings`: `auth.provider/token`, `room.id/channel`, `crypto.key|key_file`, `net.transport/dns`, `socks.host/port/user/pass` (+ `proxy_*` для серверного режима), `engine.*` для `provider: none`, секции `video/vp8/sei`, `liveness`, `lifecycle`, `traffic`. Маппинг полей `olcrtc://` → YAML — в `SPEC.md` §1.2 и `[olc] docs/uri.md` (таблица Mapping).

### 1.6. `mobile/` — gomobile-биндинги

`mobile.Runtime` оборачивает тот же `pkg/olcrtc/client`: `func New() *Runtime`, `Start()`, `Stop(timeoutMillis int)`, `WaitReady(timeoutMillis int)`, `State() string` — `[olc] mobile/runtime.go:70,91,198`; сеттеры конфигурации (`SetProvider/SetTransport/SetRoom/SetKey/SetDNS/SetSocksPort/...`) — `[olc] mobile/config.go`; `Ping/Probe` для проверок — `[olc] mobile/ping.go`, `mobile/probe.go`. Плюс `cmd/olcrtc-cgo` — c-shared экспорт `Ping`/`Check` для десктопных клиентов.

Для десктопной sora (Flutter + Go core через gRPC) `mobile/` не нужен. Ценность — на будущее Android: если sora пойдёт на Android, клиентская часть берётся как есть, а защита сокетов уже спроектирована: `Runtime.SetProtector` → процессно-глобальный `protect.SetProtector(func(fd int) bool)` — `[olc] mobile/protector.go`, `[olc] internal/protect/protect.go` (`SetProtector`, атомарный holder). Это Android `VpnService.protect(fd)` паттерн; на десктопе protector не выставлен и `controlFunc` — no-op.

### 1.7. Зависимости, размер, лицензии

`go.mod`: модуль `github.com/openlibrecommunity/olcrtc`, `go 1.26.3` — `[olc] go.mod:1,3`. Прямых зависимостей 21, всего модулей в графе 92 (у sora core — 25 строк требований при `go 1.27`, `[sora] core/go.mod:1-3`; `go.sum`: 329 строк против 94 у sora core).

Тяжёлые прямые зависимости olcrtc:

- Pion: `pion/webrtc/v4`, `pion/ice/v4`, `pion/interceptor`, `pion/rtp`, `pion/transport/v4` (+ косвенно dtls/sctp/srtp/stun/turn/mdns/datachannel) — WebRTC-стек целиком;
- LiveKit: `livekit/protocol`, `owenewans/owenlivekit/v2` — тянет косвенно protobuf/grpc, prometheus, otel, nats, redis-клиент и пр. в граф модулей (не обязательно весь граф — в бинарь; но весь — в `go.sum`, аудит и CVE-поверхность);
- `xtaci/smux`, `xtaci/kcp-go/v5` (vp8channel), `gorilla/websocket`, `google/uuid`, `golang.org/x/crypto`, `gopkg.in/yaml.v3`;
- экзотика, требующая отдельной provenance-проверки при вендоринге/аудите: `codeberg.org/rape4me/kc`, `github.com/zarazaex69/gr`, `github.com/zarazaex69/j`.

Замер прироста бинаря при встраивании — §7.

**Лицензия olcrtc — НЕ MIT** (проверено по первоисточнику, гипотеза из постановки не подтвердилась): `LICENSE` — **WTFPL v2**, «Copyright (C) 2026 zarazaex», единственное условие — «You just DO WHAT THE FUCK YOU WANT TO» — `[olc] LICENSE:1-12`. Для sora (GPL-3.0, `[sora] LICENSE`) это беспроблемно в обоих вариантах: WTFPL разрешает всё, включая включение в GPL-продукт и распространение бинаря; обязательств, кроме сохранения здравого смысла в `THIRD-PARTY-NOTICES.md`, не создаёт. Лицензии зависимостей стандартные и совместимые: Pion — MIT, LiveKit — Apache-2.0, smux/kcp-go — MIT, gorilla/websocket — BSD-3-Clause, uuid — BSD-3-Clause. При варианте (A) все они становятся лицензиями *включённых в core* компонентов и обязаны попасть в `[sora] THIRD-PARTY-NOTICES.md` полным списком графа; при варианте (B) — списком компонентов отдельного бинаря (прецедент оформления — таблица движков и zapret в том же файле).

Чужой `AGENTS.md` olcrtc диктует конвенции только для разработки самого olcrtc; на код sora не распространяется ни в одном варианте (при (A) импортируется скомпилированный модуль, а не копируются исходники со стилем).

---

## 2. Модель sora: куда встраивается транспорт

### 2.1. Движки и план

sora не знает «транспортов» в смысле olcrtc; её абстракция — **план** (`engine.Plan`) и **движок** (`engine.Engine`), который план исполняет внешним бинарём:

```go
// [sora] core/engine/engine.go — интерфейс Engine (методы):
Kind() Kind; Capabilities() Capabilities; State() State; Version() Version
Validate(ctx, *Plan) error; Apply(ctx, *Plan) error; Stop(ctx) error; Close() error
Groups(ctx); Select(ctx, group, target); Delay(ctx, name, url, timeout); Counters(ctx); Events() *EventBus
```

Движков ровно три — `KindMihomo`, `KindSingBox`, `KindXray` (`[sora] core/engine/engine.go`, константы `Kind*`); каталог возможностей — `[sora] core/engine/catalog.go`, `Catalog`: протоколы и фичи на движок, выбор — `engine.SelectEngine` по `RequiredFeatures()` плана. План собирается из proto-контракта в `[sora] core/control/plan.go`, `planFromProto`: proto `SessionPlan`/`OutboundSpec` — `[sora] proto/sora/core/v1/core_control.proto:138,256`; протокол аутбаунда в контракте — свободная строка, секреты в план попадают только через credential document секрет-стора (`credentialDocument`/`applyCredential` в том же файле), наружу — только ссылки `CredentialsRef`.

Аутбаунд плана — `[sora] core/engine/plan.go`, `type Outbound`: `Protocol`, `Server`, `Port`, креды (`UUID/Password/UserID/...`), `SOCKSUDP bool`, `Via string` (цепочки), `Bypass *BypassStrategy`. Протокол `socks5` существует и поддержан всеми тремя движками (каталоги в `catalog.go`: `ProtocolSOCKS5: true` у mihomo, sing-box и Xray).

### 2.2. SOCKS5-аутбаунд движка — готовая точка сопряжения

Каждый рендерер умеет «выйти через чужой SOCKS5»:

- sing-box: `case engine.ProtocolSOCKS5: out.set("type", "socks").set("version", "5").set("username", o.UserID).set("password", o.Password)` — `[sora] core/engine/singbox/render.go:382-384`; цепочки — `dialer_proxy` по `Via` (там же, рендер аутбаунда);
- mihomo: `px.Type = "socks5"`, username/password — `[sora] core/engine/mihomo/proxy.go`, ветка `ProtocolSOCKS5/ProtocolHTTP`;
- Xray: `protocol = "socks"`, `users[{user, pass}]` — `[sora] core/engine/xray/render.go`, ветка `ProtocolSOCKS5/ProtocolHTTP`.

Итого: чтобы трафик плана пошёл в olcRTC, движку не нужно знать про olcRTC вообще — нужен аутбаунд `socks5 → 127.0.0.1:<порт olcrtc>` в плане. Ровно так уже работает zapret (§2.4). Ограничения этой точки:

- **TCP only.** olcrtc не умеет UDP ASSOCIATE (§1.2), а поле `SOCKSUDP` у аутбаунда честно обещает UDP. Для olcrtc-аутбаундов `SOCKSUDP` обязан быть `false`, а UDP-трафик плана (DNS по UDP, QUIC) через такой аутбаунд не пройдёт: движки попытаются — и получат отказ/чёрную дыру. Это ограничение v1, подлежащее честному отражению в UI и доке (§6), а не молчаливому проглатыванию.
- **Цепочки:** `Via` + фича `chains` (`MaxChainHops = 3`, `[sora] core/engine/validate.go`, `validateChains`) позволяют ставить olcrtc-SOCKS как хоп цепочки и наоборот — композиция с существующими серверами бесплатна на уровне плана.
- **Endpoint-контракт:** `OutboundSpec` и валидатор парсера требуют осмысленные host/port (`[sora] core/parser/parser.go`, `OutboundSpec.validate`: протокол/host/port обязательны). У olcrtc «эндпоинта» нет — есть провайдер+комната+ключ. Маппинг — задача слоя плана: либо синтетический эндпоинт + параметры в credential document (прецедент — Xray-профиль целиком в `Options["profile"]` и поля в credential document, `[sora] core/control/plan.go`), либо отдельные поля контракта с бампом версии API. Транспортному слою нужен второй вариант в перспективе, но v1 проезжает на первом без изменения proto (протокол-строка `"olcrtc"` + креденшел-документ).

### 2.3. Реестр и фабрика

`[sora] core/engine/registry/registry.go`: `Discover` находит бинари, `Factory()` возвращает `func(ctx, *Plan) (engine.Engine, error)` — выбирает первый движок, несущий весь план, и **декорирует** его обёртками по содержимому плана. Точка расширения для olcrtc — та же фабрика: план содержит olcrtc-аутбаунд → движок оборачивается olcrtc-декоратором (вариант A) или сайдкар-декоратором (вариант B); декораторы компонуются с bypass-обёрткой (порядок обёрток определить явно: olcrtc внутри, bypass снаружи — по аналогии с тем, как `bypass.Wrap` — внешняя, `registry.go`, конец `Factory`).

### 2.4. Прецедент zapret: «непротокольный» компонент уже встроен именно так

`core/engine/bypass` — ближайший и исчерпывающий прецедент. Его пакетная документация фиксирует архитектуру: «Legacy strategies run on tpws, **one loopback SOCKS5 proxy per strategy, with bypass outbounds rewritten to SOCKS5**; strategies with desync methods run on the nfqws executor … **Both backends share one lifecycle, one log source and one fail-closed policy**» — `[sora] core/engine/bypass/bypass.go:1-9`. Разбор по механизмам, каждый из которых olcrtc-интеграция наследует:

1. **Декоратор движка.** `bypass.Engine` встраивает `engine.Engine` и перехватывает `Validate/Apply/Stop/Close`; конструктор — `func Wrap(inner engine.Engine, bins Binaries, home string, center *logs.Center) *Engine` (`bypass.go`). `Validate` валидирует *переписанный* план: `e.Engine.Validate(ctx, Rewrite(p, nil))`.
2. **Rewrite плана.** `func Rewrite(p *engine.Plan, ports map[string]int) *engine.Plan` (`bypass.go`): tpws-аутбаунды → `ProtocolSOCKS5, Server: "127.0.0.1", Port: <порт стратегии>`; nfqws-аутбаунды → `ProtocolDirect` (пакетный слой ниже движка). Дедупликация процессов — по ключу стратегии `key(s)`. Для olcrtc: ключ = хэш нормализованной конфигурации (provider/transport/room/channel/transport-options/dns), порты — по одному слушателю на уникальную конфигурацию.
3. **Fail-closed ворота в Apply.** Сначала capability-gate и проверка бинарей, «before any state changes»; отсутствующий бинарь — именованная ошибка `errs.KeyEngineBinaryMissing` ещё в фабрике (`registry.go`, блок `withBypass`: отдельно для tpws и nfqws). Никакого «молча пропустить обфускацию».
4. **Надзор процесса.** `supervise.Start(pctx, supervise.Spec{Name, Path, Args, Dir, Lines})` + `waitListening` (поллинг TCP-порта до 5 c) + горутина `keep` с бэкоффом `engine.DefaultBackoff()`, перезапуск на том же порту, чтобы аутбаунды движка не инвалидировались (`bypass.go`, `start`/`keep`).
5. **Digest-проверка хелперов без version-пробы.** tpws/nfqws не пробятся по версии — только `supervise.VerifyNamedInDir(enginesDir, "tpws")` при discovery (`registry.go`, `Discover`), а сам механизм — `[sora] core/engine/supervise/binary.go`: `Discover` «never consults PATH», кандидат из engines-каталога обязан совпасть с `engines.digests`, проверка — **до** исполнения (SORA-H5); `VerifyNamedInDir` существует именно «for helpers that are not version-probed engines — zapret's tpws». olcrtc-сайдкар ложится в этот абзац дословно.
6. **Маскирование логов.** Вывод tpws/nfqws идёт через `Lines` в `logs.Center` с обязательным редектором (`bypass.go`, `mask`/`logLine`, урок CENSOR-LEAK: сырой вывод хелпера называет хосты/SNI и не должен попадать в логи как есть) и классификацией уровней (`bypassLineLevel`). Для olcrtc это критично вдвойне: его лог называет комнаты и эндпоинты SFU.
7. **Пакетирование.** tpws/nfqws собираются из vendored zapret (`[sora] packaging/zapret/build.sh`), кладутся в `/usr/lib/sora/engines/` рядом с движками (`[sora] packaging/linux/nfpm.yaml:55-56`), дайджесты дописываются в `engines.digests` тем же скриптом.

Второй, меньший прецедент «компонента не из плана движков» — `applyZapretWithVPN` (`[sora] core/control/plan.go`): синтетический аутбаунд с зарезервированным ID вставляется в план контролом, правила `direct` перецеливаются на него. Для olcrtc аналогичный синтетический путь не нужен — olcrtc-аутбаунд является настоящим пользовательским сервером из подписки, а не синтетикой.

### 2.5. Сессия и guard: порядок запуска

`[sora] core/session/runner.go`, `Session.Start`: сначала `guard.Apply(...)`, **потом** `eng.Apply(plan)`; `Stop` — в обратном порядке: движок остановлен до восстановления guard («Stop the engine before restoring the guard to prevent packets using settings being removed»). Переключение серверов менеджером держит kill-switch взведённым через `BlockHolder` (`[sora] core/session/guard.go`, `HoldBlock`). Следствие: любой olcrtc-компонент, стартующий внутри `Apply` декоратора, стартует **уже под взведённым kill-switch** и обязан сам укладываться в его семантику (§3), а не надеяться на окно до взведения.

---

## 3. Kill-switch / guard: что происходит с трафиком olcrtc

Правила Linux-guard рендерятся в `[sora] core/guard/nftables.go`, `NftRuleset(engineUID, bypass, blocked...)`. Порядок в output-цепочке: `oif lo accept` → `oifname "sora0" accept` → drop заблокированных (fake-IP/туннельные сети вне туннеля) → **`meta skuid <engineUID> accept`** → drop DNS (53 tcp/udp) вне туннеля → accept на established-replies и bypass-сети (по умолчанию приватные) → финальный `counter drop`.

Кто такой engineUID: `EngineUID: os.Getuid()` — UID **самого процесса sora-core**; движки — его дочерние процессы с тем же UID (`[sora] core/cmd/sora-core/main.go:221-225`, комментарий там же: при root guard отказывается взводиться, SORA-H4).

Отсюда по вариантам:

- **(A) in-process:** сокеты WebRTC/сигналинга olcrtc принадлежат процессу core → `skuid`-исключение покрывает их автоматически, наравне с движками. Loopback-слушатель покрыт `oif lo accept`. Никаких изменений guard не требуется.
- **(B) сайдкар:** дочерний процесс core, запущенный через `supervise` без смены UID (у `supervise.Spec` нет credential-полей; процесс наследует UID core) → то же `skuid`-исключение. **Условие:** сайдкар нельзя выносить в отдельный systemd-юнит с другим пользователем и нельзя запускать от имени UI — тогда его SFU-трафик ляжет под финальный drop при взведённом kill-switch, причём отказ будет выглядеть как «комната не отвечает». Это требование фиксируется в пакетировании: бинарь живёт в engines-каталоге и запускается только core.
- **Общий остаточный риск обоих вариантов — петля через TUN.** Движки избегают зацикливания своих серверных подключений собственными средствами (их исходящие сокеты и маршруты — часть движка). Подключения olcrtc к SFU (WebSocket/HTTPS сигналинг к Telemost/Jitsi/WBStream, ICE UDP к STUN/TURN и пиру, API провайдера) исходят **не из движка**, и движок про эндпоинты SFU ничего не знает: при TUN с маршрутом по умолчанию эти пакеты рискуют завернуться в `sora0` → движок → SOCKS-аутбаунд → olcrtc → снова в TUN. У olcrtc есть частичная защита на уровне ICE: `ProtectedNet` вырезает интерфейсы с префиксами `tun/ppp/pptp` из сбора кандидатов (`[olc] internal/protect/pionnet.go`), а Android-путь умеет `protect(fd)`. Но: (1) сигналинг (не ICE) этим не покрыт; (2) исключение интерфейса из кандидатов ≠ исключение маршрута по умолчанию для исходящих UDP/TCP сокетов пион-стека на десктопе. **В песочнице без TUN это не проверяется** (та же честная граница, что у проекта для kill-switch/TUN в целом). До dev-машины это открытый риск R1 (§8) с обязательным E2E-тестом «TUN up + olcrtc-сессия» и заготовленными митигациями: per-session bypass в guard для разрешённых SFU/провайдер-эндпоинтов (механизм `Settings.Bypass` существует — `[sora] core/session/guard.go`, `Settings`), либо привязка исходящих сокетов olcrtc к физическому интерфейсу (для (A) — через собственный `Resolver`/dialer-контекст невозможна: публичный `Config` даёт только `Resolver *net.Resolver`, dialer сигналинга наружу не выставлен; для (B) — тоже нет: CLI таких опций не имеет). Практический вывод: митигация уровня плана/guard (bypass-список из плана) — единственная доступная без форка olcrtc; её надо проектировать сразу, а не после первого зацикливания.
- **Отказ olcrtc в живой сессии — fail-closed по построению.** Переписанный аутбаунд указывает в loopback; мёртвый слушатель = отказ соединения у движка, а не прямой выход: трафик приложений при TUN всё равно в движке, при system-proxy — в loopback движка. Утечки «мимо» не возникает ни в (A) (Run вернул ошибку → декоратор обязан перевести движок/сессию в failed, а не оставлять план применённым), ни в (B) (процесс умер → `keep`-рестарт на том же порту по образцу tpws; до рестарта — отказы, не утечка). Условие для (A): декоратор обязан мониторить возврат клиентского `Run` в отдельной горутине и публиковать engine event/ошибку сессии — сам по себе возврат `Run` никто не заметит, сессия останется «connected» с чёрной дырой. Это явный пункт дизайна, а не деталь реализации.
- **DNS.** У olcrtc два разных DNS-контура: (1) свой сигналинг — резолвер из `Config.DNSServer/Resolver`, по умолчанию у `mobile/` это `8.8.8.8:53` (`[olc] mobile/config.go`, `defaultDNSServer`) — **в sora этот дефолт недопустим** (хардкод чужого резолвера вразрез с планом и политикой «без хардкода»): декоратор обязан подставлять резолвер из DNS-секции плана (или системный, если план так говорит) и в (A), и в (B) (поле `net.dns` YAML); (2) DNS таргетов — резолвится на эгрессе (§1.2), локально не утекает.

---

## 4. Серверная сторона: sora нужен только клиент — подтверждено

Постановка «srv нужен только оператору эгресса» **подтверждается кодом**:

- Режимы равноправны и раздельны: `runOnce` диспетчит `ModeSrv → server.Run(...)`, `ModeCnc → client.Run(...)` (`[olc] internal/app/session/run.go`). Клиентский путь не тянет и не требует серверного кода сверх общих транспортов/крипты.
- Сервер (`[olc] internal/server/server.go`, `Run`) — это эгресс-узел: принимает туннельные smux-потоки, по JSON-запросу `connect` **сам** дозванивается до таргетов (`[olc] internal/server/egress.go`, `dial`: прямой `net.Dialer` `tcp4` либо через опциональный upstream SOCKS5 `SOCKSProxyAddr/Port`) и проксирует байты. То есть srv — машина, чьим IP «светит» пользователь; её эксплуатирует оператор (сообщество/провайдер подписки), а не владелец sora.
- Для подключения по `olcrtc://` клиенту нужны только поля ссылки (провайдер/транспорт/комната/ключ — `SPEC.md` §1.2) и живой srv на той стороне комнаты; подписка OpenLibre такие комнаты раздаёт. Ставить пользователю sora собственный srv = делать его машину чужим эгрессом: вне продуктового объёма, с отдельными abuse/юридическими последствиями. **Вывод: ни `pkg/olcrtc/tunnel`, ни режим `srv` в поставку sora не включаются.** В варианте (B) бинарь физически содержит srv внутри (это один CLI), но sora никогда не рендерит конфиг с `mode: srv` — валидатор декоратора обязан отклонять такой план (защита от превращения клиентской машины в эгресс по ошибке/атаке через план).

---

## 5. Варианты интеграции

Общая для (A) и (B) часть (ядро дизайна, пишется один раз): новый пакет-декоратор уровня `core/engine/bypass`, назовём его для определённости `core/engine/olcwrap`:

- распознаёт в плане аутбаунды `Protocol == "olcrtc"` и их параметры из credential document (provider/transport/room/channel/key/provider_token/transport_options/dns-override);
- `Validate`: переписывает каждый такой аутбаунд в `socks5 127.0.0.1:<порт>` (порт-заглушка 1 при валидации — как `Rewrite(p, nil)` у bypass) и делегирует внутреннему движку; плюс собственные проверки: провайдер/транспорт из реестров olcrtc, ключ — 64 hex, `mode` только клиентский, `SOCKSUDP == false` не требуется — декоратор сам гасит UDP-обещание (§6), но план с явным требованием UDP на этом аутбаунде честно отклоняется? Нет: отклонять нельзя — план не различает; фиксация ограничения — §6;
- `Apply`: сгруппировать аутбаунды по ключу конфигурации; для каждой уникальной конфигурации обеспечить живой olcrtc-клиент (процесс или горутину); дождаться готовности слушателя; переписать план реальными портами; `inner.Apply`; при любой ошибке — откатить поднятые клиенты и вернуть ошибку (fail-closed, до изменения состояния — порядок как в `bypass.Apply`);
- `Stop/Close`: гасить клиентов после остановки внутреннего движка (зеркально `bypass.stopAll`);
- логи olcrtc — только через редектор в `logs.Center` под отдельным source (`"olcrtc"`), ключ/токены/комната — в маске редектора как секреты плана;
- здоровье: смерть клиента в живой сессии → engine event + перевод сессии в reconnecting/failed (механизм §3), а не тихая чёрная дыра.

### 5.A. Встраивание `pkg/olcrtc/client` в sora core

**Механика.** `go.mod` core требует `github.com/openlibrecommunity/olcrtc` (пинится точная версия/коммит). Декоратор на каждую уникальную конфигурацию запускает:

```go
cli := client.New(client.Config{ /* все поля — из плана/креденшела, §1.1 */ })
go func() { err := cli.RunWithAddress(ctx, func(actual string) { /* записать порт, закрыть ready-канал */ }) }()
```

`LocalAddr: "127.0.0.1:0"` + `RunWithAddress` дают реальный порт без гонки предвыделения (в отличие от `supervise.FreePort()` у tpws). SOCKS-аутентификацию на слушателе декоратор выставляет из сгенерированных на сессию user/pass (поля есть в `Config` и в SOCKS-аутбаунде движка — `UserID/Password`), чтобы слушатель не был открытым локальным прокси для любого процесса машины (угроза та же, что описана в контракте для `LocalProxy`, `[sora] proto/sora/core/v1/core_control.proto`, комментарий к `LocalProxy`). Жизнь = `context` сессии; `OnHealth` маппится в события декоратора.

**Объём работы.** Декоратор + маппинг плана/креденшела + фабричная регистрация + тесты: оценка 1 пакет ~600-900 строк с тестами. Плюс разовая цена: граф зависимостей core вырастает с 25 до ~110 модулей (§1.7), `go.sum` — с 94 до ~420 строк; пересборка и ре-аудит `THIRD-PARTY-NOTICES.md`; проверка, что Pion/LiveKit не тянут cgo на целевых платформах (десктопный путь olcrtc — чистый Go; cgo встречается только в android-варианте `pionnet_android.go`).

**Плюсы.**

- Жизненный цикл — самый чистый из трёх вариантов: нет процессов, портов-файлов, сирот при краше core; контекст отменяется — клиент умер; `Stop` детерминированно ждёт возврата `Run`.
- Готовность — точный колбэк `RunWithAddress`, а не поллинг порта.
- Обновления upstream = бамп версии модуля + прогон тестов core; нет отдельной поставки/подписей/пакета.
- Guard: автоматически тот же UID (§3).
- Тестируемость максимальная: декоратор тестируется в процессе, с фейковым внутренним движком и настоящим клиентом на loopback (§7).

**Минусы / риски.**

- **Размер и поверхность core.** Прирост бинаря — §7 (замер); даже по нижней оценке это мегабайты WebRTC/LiveKit-кода в *привилегированном* процессе, который держит kill-switch и секреты. Паника в Pion/LiveKit роняет весь core (guard-правила при этом останутся взведёнными ядром — трафик встанет, а не утечёт, но сессия и управление мертвы до рестарта сервиса).
- **Дисциплина обновлений.** olcrtc молод и быстро меняется; его `internal/` не является API — но `pkg/olcrtc/client` зависит от `internal/` того же модуля, поэтому потребитель пиннит поведение целиком. Сломанный/скомпрометированный апстрим-релиз попадает прямо в core одной строкой `go.mod` — смягчается только пинном коммита и ревью диффов при бампе.
- **Конфликты версий зависимостей.** Общие с sora зависимости (`golang.org/x/crypto`, `yaml.v3`, protobuf/grpc через LiveKit-граф) начнут резолвиться по максимальной версии: риск тихого бампа версий внутри core при добавлении olcrtc (лечится отдельным шагом: сначала `go mod tidy` + полный прогон + дифф `go.mod` как отдельный коммит-гейт).
- **Логи olcrtc идут в stderr/std log процесса** (`internal/logger`, `log.SetOutput` настраивает только CLI в `cmd/olcrtc/main.go`, `configureLogging`). Внутри core их придётся перехватывать глобальным `log.SetOutput` — а это процессно-глобальное состояние чужой библиотеки внутри core: приемлемо один раз при инициализации декоратора, но это самая «грязная» точка варианта.

### 5.B. Сайдкар-бинарь `olcrtc` в режиме `cnc` (по модели engines)

**Механика.** Upstream собирается как есть (`go build ./cmd/olcrtc`), кладётся в engines-каталог рядом с `tpws`/`nfqws`; `engines.lock`/`fetch.sh` (или build-скрипт по образцу `[sora] packaging/zapret/build.sh`) фиксируют версию и SHA-256, дайджест дописывается в `engines.digests`. При discovery реестра — проверка `supervise.VerifyNamedInDir(enginesDir, "olcrtc")` (как tpws в `[sora] core/engine/registry/registry.go`, `Discover`); отсутствие/несоответствие → olcrtc-аутбаунды честно недоступны с `KeyEngineBinaryMissing` (как bypass в `Factory`). Декоратор на каждую уникальную конфигурацию: рендерит YAML-конфиг (§1.5) в файл `0600` внутри runtime-home (`Dir` процесса, сам каталог `0o700` — `[sora] core/engine/supervise/process.go`, `Start`), стартует `supervise.Start(Spec{Name: "olcrtc", Path, Args: []string{configPath}, Dir, Lines: maskedLog})`, ждёт слушатель поллингом порта (`waitListening` — готовый образец в bypass), перезапускает с бэкоффом на том же порту/конфиге при смерти (`keep` — готовый образец). Порт для сайдкара выбирается заранее через `supervise.FreePort()` (у CLI нет колбэка адреса — адрес задаётся в YAML `socks.host/port`).

**Объём работы.** Тот же декоратор (~как в A, плюс YAML-рендерер вместо структуры и процессный надзор вместо горутины — образцы целиком в bypass, пишется по кальке) + пакетирование: запись в `engines.lock`, fetch/build для linux amd64/arm64 и windows-amd64, nfpm/Inno включение, notices. Оценка: декоратор ~700-1000 строк с тестами; пакетирование — 1 скрипт + правки манифестов.

**Плюсы.**

- **Core не меняется в размере и графе зависимостей вообще.** Бинарь core остаётся 18,8 МБ оптимизированного baseline (OPT40), его аудит поверхности — прежним.
- **Изоляция отказов:** паника/смерть olcrtc не роняет core; надзор перезапускает сайдкар, сессия видит reconnect, а не смерть сервиса. Обратное тоже верно: рестарт core не обязан тащить WebRTC-состояние.
- **Точное следование существующей политике поставки:** fail-closed digest до исполнения (SORA-H5), ни PATH, ни env-override без явного флага оператора; обновление olcrtc = замена бинаря + дайджеста, без пересборки core; можно не поставлять olcrtc в минимальных сборках (аутбаунды честно недоступны, как nfqws сегодня).
- Лицензионно чище: отдельный бинарь со своим набором notices; WTFPL (§1.7) не «растекается» по исходникам core.
- Соответствует философии проекта: все тяжёлые чужие рантаймы sora — внешние бинари (sing-box/Xray/mihomo/zapret); olcrtc — четвёртый в ряд, а не первое исключение.

**Минусы / риски.**

- **Секрет в файле.** YAML содержит `crypto.key` (и при наличии — `auth.token`) открытым текстом на время жизни сессии. Митигации: файл в `0o700` home, права `0600`, удаление при `Stop`, никогда не в argv (argv — только путь), никогда не в логи; `crypto.key_file` у olcrtc есть, но файл тот же самый — выигрыша нет. Остаточный риск выше, чем в (A), где ключ живёт только в памяти core и секрет-сторе. Приемлемость — та же модель, что у движков с их конфигами? Нет: движкам конфиг подаётся через stdin (`supervise.Spec.Config`: «keeping credentials off disk and out of process arguments») — olcrtc stdin не читает, это его ограничение, фиксируем честно.
- **Готовность — поллинг**, а не колбэк: до 5 c ожидания по образцу tpws, плюс теоретическая гонка «порт ещё не слушает, а конференция уже мертва» — решается тем же `waitListening` + проверкой `proc.Err()`.
- **Версии нет** (§1.5): capability-проверка сайдкара слабее движковой — только digest + факт запуска + живой SOCKS. Компенсация: digest и есть пин версии (engines.lock фиксирует, *какой* upstream собран); функциональный smoke — поднявшийся слушатель.
- **Пакетирование Windows** — отдельный бинарь в инсталлер; на Windows olcrtc не проверялся ни нами, ни (по докам) как основной сценарий — dev-машина.
- Сироты при жёсткой смерти core: `supervise` процессы — контекстно-привязанные дети, при SIGKILL core ребёнок переживёт; tpws несёт тот же риск сегодня (и тот же ответ: при следующем старте core порт занят чужим слушателем → декоратор обязан перед стартом проверять/переиспользовать или убивать свой предыдущий экземпляр по pidfile в home — пункт дизайна для B).

### 5.C. Нативная реализация протокола в sora

**Что пришлось бы написать.** По коду olcrtc, протокол — это не «WebRTC-звонок», а стек: (1) провайдерная аутентификация и получение SFU-креденшелов для трёх провайдеров (Telemost API, Jitsi, WBStream — `[olc] internal/auth/{telemost,jitsi,wbstream}`); (2) SFU-движки двух семейств (LiveKit-клиент и Goolom/Jitsi-бридж — `[olc] internal/engine/{livekit,goolom,jitsi}`, Pion WebRTC, ICE, переподключения, эпо́хи пиров); (3) четыре транспорта данных поверх медиаканала (datachannel; videochannel — QR/tile видеокодирование кадров; seichannel — H.264 SEI; vp8channel — VP8 + KCP — `[olc] internal/transport/{datachannel,videochannel,seichannel,vp8channel}`); (4) слой OLC2-крипты, handshake с claims/device-id, smux-мультиплекс, контрольный liveness-протокол (`[olc] internal/{crypto,handshake,muxconn,control,tunnelcore}`), включая wire-совместимые мелочи уровня «seichannel/videochannel требуют OLVC frame version 5 на обоих концах» (`[olc] docs/uri.md`). Это переписывание практически всего `internal/` olcrtc — десятков пакетов с их тестами — с последующей вечной синхронизацией с живым сообществом: любой сдвиг wire-формата у провайдеров/сообщества ломает совместимость с чужими srv, а своих srv у пользователей sora нет (§4) — то есть несовместимость = полная неработоспособность.

**Вердикт: отклонить.** Объём — на порядок больше (A)/(B) вместе взятых, результат заведомо хуже upstream по покрытию провайдеров и транспортов, а выигрыш (нет чужой зависимости) не нужен: лицензия WTFPL (§1.7) и оба механизма поставки sora (модуль Go / engines-бинарь) дают легальные дешёвые пути. Единственный сценарий воскрешения (C): смерть/закрытие upstream — и тогда правильная форма (C) называется «форк olcrtc и вариант (A)/(B) на форке», а не переписывание.

### 5.D. Сравнительная таблица

| Критерий | A: встраивание | B: сайдкар | C: нативно |
|---|---|---|---|
| Точка сопряжения | SOCKS5 loopback | SOCKS5 loopback | своя |
| Объём новой работы | средний | средний (+пакеты) | неприемлемый |
| Размер core | растёт (§7) | без изменений | растёт умеренно |
| Граф зависимостей core | 25 → ~110 модулей | без изменений | +Pion только |
| Изоляция паник olcrtc | нет (паника = смерть core) | да | нет |
| Секрет ключа | только память core | файл 0600 на время сессии | только память |
| Обновление upstream | бамп go.mod, ревью диффа | замена бинаря + digest | вручную, вечный дрейф |
| Соответствие модели поставки sora | исключение | точная калька zapret | исключение |
| Guard/kill-switch | автоматически | автоматически (тот же UID) при запуске из core | автоматически |
| Готовность/надзор | колбэк, точнее | поллинг порта, образцы есть | свой |
| Windows | собирается в core | отдельный бинарь, не проверен | собирается в core |
| Лицензии | WTFPL + весь граф в notices core | WTFPL у отдельного бинаря | чисто, но ценой объёма |

---

## 6. Сквозные ограничения v1 (обязаны быть честными в продукте)

1. **TCP-only.** Нет UDP через olcrtc (§1.2, §2.2): QUIC/HTTP3 и UDP-DNS через такой сервер не идут. Движок при этом не «врёт» — SOCKS5-аутбаунд без UDP-ассоциации просто не унесёт UDP; приложения откатятся на TCP (браузеры — да; не все). В UI/доке сервер olcrtc помечается как TCP-only; метрики/диагностика не должны показывать UDP-потоки через него.
2. **IPv4-only эгресс.** Слушатель клиента `tcp4`, dial эгресса `tcp4` (§1.2, §4): IPv6-таргеты недостижимы, AAAA-only ресурсы не откроются. План с `ipv6: on` + olcrtc-аутбаунд — валиден, но v6 пойдёт только в другие аутбаунды/группы.
3. **Задержка и пропускная способность** определяются SFU и транспортом (videochannel/seichannel/vp8channel — кадровые транспорты с FPS/батчами; datachannel — самый прямой). Профилирование — не задача этого этапа; для UI важна только классификация «тяжёлый/лёгкий» транспорт из плана, без обещаний цифр.
4. **Зависимость от третьей стороны в рантайме:** комната живёт на чужом SFU; смерть конференции = смерть туннеля (библиотека честно завершает `Run` / шлёт ended-callback — декоратор обязан превращать это в reconnect/fail сессии по §3, failover-профили уровня olcrtc-супервизора в (B) для sora не используем: failover серверов — работа групп/плана sora, а не сайдкара).
5. **Метаданные у оператора SFU:** провайдер видит факт и объём медиасессии (не содержимое: OLC2-шифрование end-to-end между cnc и srv поверх SFU). Это свойство протокола сообщества, фиксируется в доке безопасности как есть.

---

## 7. Тестируемость в песочнице (без TUN) и замер размера

### 7.1. Что проверяется без TUN и без живого SFU

- **Декоратор как юнит:** Rewrite-чистота (план не мутируется — у bypass это закреплено тестом `TestXrayBridgeAdjustmentNeverMutatesTheCallerPlan`-класса), дедуп по ключу конфигурации, fail-closed ворота (нет бинаря / битый ключ / неизвестный провайдер — именованные ошибки до изменения состояния), маскирование логов. Всё — фейковый внутренний движок, образец — тесты `core/engine/bypass`.
- **Контракт с olcrtc:** (A) — настоящий `pkg/olcrtc/client` на loopback: конфиг с `Provider: "none"` + недоступный SFU обязан вернуть ошибку из `Run`, а декоратор — не применить план; (B) — настоящий бинарь: digest-гейт (подмена бинаря → отказ discovery), YAML-рендер (только известные ключи — строгий парсер olcrtc сам является тестом), файл 0600, слушатель поднялся/умер/перезапустился на том же порту.
- **SOCKS-сопряжение:** настоящий sing-box/mihomo из engines с планом «socks5 → loopback» против фейкового SOCKS-сервера и против настоящего olcrtc-клиента в паре с настоящим olcrtc-srv *без SFU не выйдет*: cnc и srv встречаются только внутри SFU-комнаты. Полный e2e требует либо публичного провайдера (сеть, чужая комната — только dev-машина/ручной прогон), либо локального LiveKit/Jitsi стенда (подъём SFU в CI — отдельная инфраструктурная задача этапа реализации; у самого olcrtc e2e-тесты живут в `internal/e2e` и часть из них — `*_real_test.go` — тоже требует живых провайдеров).
- **Guard:** рендер правил уже покрыт тестами `core/guard`; olcrtc ничего в правилах не меняет (§3) — новых guard-тестов не требуется, требуется один dev-machine E2E: TUN up + kill-switch armed + olcrtc-сессия (риск R1, петля маршрутизации) — в песочнице невозможен по той же причине, что и весь TUN/kill-switch контур проекта.

### 7.2. Замер размера (песочница)

Метод: отдельный модуль в `/tmp/olcrtc-size-check`, импортирующий только `pkg/olcrtc/client`, `replace` на локальный клон olcrtc; сборка `go build -trimpath -ldflags="-s -w"` тем же тулчейном, что собирает upstream (go 1.26.10, подтянут по `GOTOOLCHAIN=auto`; локальный go 1.24.7 сам по себе olcrtc не соберёт — ему нужен ≥ 1.26.3). Для сравнения: оптимизированный sora-core linux/amd64 — 18 825 376 байт (OPT40).

Результаты замера (linux/amd64, тулчейн go1.26.3 по `go version -m` собранного бинаря, ревизия olcrtc `f3ad8fb`):

| Артефакт | Сборка | Байт |
|---|---|---|
| пустая программа (база рантайма) | `-trimpath -ldflags="-s -w"` | 1 007 800 |
| только `pkg/olcrtc/client` (песочница, `func main` + `client.New(...).Run`) | та же | 32 379 145 |
| полный `cmd/olcrtc` (клиент + сервер + gen + CLI) | та же | 32 624 905 |
| полный `cmd/olcrtc` | `-trimpath`, без strip | 46 444 489 |
| sora-core (OPT40 baseline, для масштаба) | оптимизированная | 18 825 376 |

Выводы из цифр:

- **Чистый вес клиентского стека olcrtc ≈ 31,4 МБ** поверх базы Go-рантайма; серверная часть и CLI добавляют к нему лишь ~0,25 МБ — то есть «клиентская библиотека лёгкая, тяжёл только бинарь целиком» неверно: тяжёл именно клиент (Pion + LiveKit + транспорты).
- **Вариант (A):** встраивание `pkg/olcrtc/client` в core даст прирост, близкий к этим 31,4 МБ, за вычетом пересечения с уже имеющимися в core зависимостями (grpc/protobuf/yaml/x/crypto — единицы МБ). Итоговая оценка: core вырастет с 18,8 МБ примерно до **45-50 МБ (×2,5)**. Это нижняя граница цены варианта (A) — до CVE-поверхности §1.7.
- **Вариант (B):** цена поставки — **+32,6 МБ к пакету** (stripped-бинарь сайдкара) при нулевом росте core. Для масштаба: движки sora по отдельности крупнее, а вопрос «таскать ли +7,7 МБ за sora-sync» у проекта уже стоял как решение владельца — тем более оно нужно здесь (Q2, §8.2).

---

## 8. Рекомендация, риски, порядок работ

### 8.1. Решение

**Основной путь — (B) сайдкар.** Обоснование по критериям владельца:

- **Качество/ноль слопа:** интеграция целиком собирается из уже существующих, отревьюенных механизмов sora (декоратор, Rewrite, supervise, digest-гейт, маскирование логов, fail-closed фабрика). Новых архитектурных сущностей — ноль. Вариант (A) при той же внешней семантике вносит в core чужой граф из ~90 модулей и процессно-глобальный перехват логов — это слоп архитектурного уровня, даже если код декоратора одинаково чист.
- **Без хардкода:** все параметры (провайдер/транспорт/комната/ключ/опции транспорта/DNS/liveness) берутся из плана и credential document; DNS-дефолт olcrtc (8.8.8.8) перекрывается планом (§3); порты — аллокатором; пути — engines/home каталогами core.
- **Адаптируемость и обновления:** olcrtc обновляется независимо от core (бинарь + digest), core — независимо от olcrtc; протокол сообщества может меняться с темпом сообщества, не диктуя релизный цикл sora.
- **Безопасность:** привилегированный процесс не получает WebRTC/LiveKit поверхность; паника сайдкара не роняет держателя kill-switch; поставка бинаря — под той же SORA-H5 политикой, что и движки.

**Запасной путь — (A) встраивание**, тем же декоратором (его контракт от способа жизни клиента не зависит: «обеспечить слушатель на 127.0.0.1:P и дождаться готовности»). Триггеры перехода на запасной: (1) пакетирование Windows-сайдкара упрётся в неподдерживаемость olcrtc на Windows; (2) вес/подпись отдельного бинаря окажется неприемлемой для канала дистрибуции; (3) понадобится Android, где сайдкар невозможен в принципе, а `pkg/olcrtc/client` + protector-модель olcrtc — родной путь (§1.6). Дизайн декоратора обязан с первого дня прятать источник слушателя за внутренним интерфейсом из двух методов (`Ensure(cfg) (port int, err error)` / `Release(key)`), чтобы замена (B)→(A) была заменой одной реализации, а не переписыванием.

### 8.2. Риски и открытые вопросы

| # | Риск/вопрос | Кому/когда |
|---|---|---|
| R1 | Петля маршрутизации SFU-трафика через TUN (§3): не проверяется в песочнице | E2E на dev-машине до релиза фичи; митигация — bypass-эндпоинты из плана в guard |
| R2 | Секрет ключа в YAML-файле сайдкара на время сессии (§5.B) | Принятая модель угроз фиксируется в security-доке; 0600/0700/удаление при Stop — в критериях приёмки |
| R3 | olcrtc на Windows: таргет сборки у upstream есть (`magefile.go` — windows/amd64 в матрице), но CI upstream — только ubuntu, работа WebRTC на Windows никем не подтверждена | Dev-машина; при провале — триггер запасного пути (A) или Linux-only v1 с честной недоступностью |
| R4 | Upstream молодой: wire-формат и API могут ломаться между релизами | Пин в `engines.lock`; бамп — только с прогоном interop-прогона против живого провайдера |
| R5 | UDP/IPv6-ограничения v1 (§6) молча воспримутся как «sora сломана» | UI-пометка TCP-only у olcrtc-серверов — критерий приёмки, не «потом» |
| Q1 | Нужен ли sora-operated публичный srv-эгресс когда-либо? (§4: сейчас — нет) | Решение владельца; на транспорт клиента не влияет |
| Q2 | Поставлять ли olcrtc-бинарь в базовый пакет (+размер пакета) или опциональным компонентом | Владелец; механика одинакова, меняется только содержимое пакета |

### 8.3. Порядок работ при реализации (не этот этап)

1. Декоратор `olcwrap` + маппинг плана/креденшела + юнит-тесты (без бинаря: фейковый источник слушателя).
2. Источник-«сайдкар»: YAML-рендер, discovery/digest, надзор по образцу bypass; тесты digest-гейта и рестарта.
3. Пакетирование: `engines.lock`, fetch/build, nfpm; notices (WTFPL + граф бинаря).
4. Связка с подотделом ссылок: протокол `"olcrtc"` в плане, поля креденшела, UI-пометки TCP-only (их SPEC/парсер — отдельная задача; транспорт потребляет только готовый credential document).
5. Dev-машина: R1/R3 E2E (TUN + kill-switch + живой провайдер), interop-прогон cnc↔чужой srv.
6. Запасной источник-«встраивание» — только по триггерам §8.1.

---

## Приложение. Сигнатуры pkg/olcrtc дословно (сводка)

```go
// pkg/olcrtc/client/client.go:112,118,123,131
func New(cfg Config) *Client
func (c *Client) Run(ctx context.Context) error
func (c *Client) RunWithReady(ctx context.Context, onReady func()) error
func (c *Client) RunWithAddress(ctx context.Context, onReady func(actualAddr string)) error

// pkg/olcrtc/tunnel/tunnel.go:127,133 — сервер, sora не нужен (§4)
func New(cfg Config) *Server
func (s *Server) Run(ctx context.Context) error

// pkg/olcrtc/engineconn/engineconn.go:73,154 — сырой поток, не для продукта (§1.3)
func New(ctx context.Context, cfg Config) (*Session, error)
func (s *Session) Dial(ctx context.Context) (io.ReadWriteCloser, error)

// mobile/runtime.go:70,91,198 — gomobile, будущее Android (§1.6)
func New() *Runtime
func (r *Runtime) Start() error
func (r *Runtime) Stop(timeoutMillis int) error
```
