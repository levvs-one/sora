# 01. XHTTP internals — исходники Xray (transport/internet/splithttp)

Дата: 2026-10-20. Источники: исходники Xray-core (`transport/internet/splithttp/`: dialer.go, hub.go, mux.go, config.go/proto, upload_queue.go, connection.go, browser_client.go), XTLS Project X docs, DeepWiki-разборы с привязкой к файлам/строкам, Xray-examples (VLESS-XHTTP3-Nginx/client.jsonc), полевая практика 2025–2026.

## Как устроен транспорт

XHTTP (в коде — `splithttp`) передаёт трафик поверх обычных HTTP-запросов/ответов с разделением путей аплоада и даунлоада. Клиент: `dialer.go`, сервер: `hub.go`. Каждая сессия идентифицируется UUID в пути запроса. Режимы (`dialer.go` ~281–293, `hub.go` 136–141):

- `auto` — выбор по security: REALITY → `stream-one`, остальное → `packet-up`.
- `stream-one` — один HTTP-запрос на оба направления (WebRTC-стиль).
- `stream-up` — аплоад через POST, даунлоад отдельным каналом.
- `stream-down` — наоборот.
- `packet-up` — аплоад пронумерованными POST-запросами (приоритетная очередь в `upload_queue.go` 85–143 гарантирует порядок).

Поддерживаются HTTP/1.1, H2, H3 (QUIC), выбор версии — `dialer.go` 78–95, 144–227.

## Что реально даёт каждая опция

**xmux** (`mux.go`, `dialer.go` 33–76) — управление соединениями. Две взаимоисключающие стратегии:
- `maxConcurrency` — максимум стримов на одно соединение (аналог mux.concurrency). При достижении лимита открываются новые соединения.
- `maxConnections` — каждому стриму своё соединение до лимита, дальше — переиспользование.

Плюс жизненный цикл соединений: `cMaxReuseTimes` (сколько раз переиспользовать), `cMaxLifetimeMs` (макс. время жизни), `hMaxRequestTimes` (макс. запросов на соединение — у nginx дефолт 1000), `hKeepAlivePeriod`. **Практический вывод:** значения обязаны быть согласованы с лимитами фронтенда (nginx `http2_max_concurrent_streams` = 128 по умолчанию); превышение рвёт соединения. Xray-examples прямо требуют выравнивать `maxConcurrency`/`hMaxRequestTimes` с nginx.

**xPaddingBytes** (дефолт `{from: 100, to: 1000}`) — случайный паддинг к запросам/ответам. Механика: ломает фингерпринтинг по размерам пакетов/запросов. Дешёвый анти-анализ, почти бесплатный по трафику. Выключать (`0,0`) — только для отладки.

**downloadSettings** — отдельная конфигурация для даунлоад-пути: другой сервер, другой security, другой транспорт. Механика, которая делает XHTTP уникальным:
- аплоад (малый) — через CDN-домен,
- даунлоад (большой) — напрямую через REALITY-домен или другой сервер/страну/протокол.

Эффекты: обход лимитов CDN на трафик, скорость (прямой путь для тяжёлого направления), ломка анализа паттернов (up и down идут разными путями — корреляция сложнее), обход «TLS-inside-TLS» детекции. **Ограничение из кода:** работает только в `stream-up` (не в `stream-one`). Клиент и сервер обязаны поддерживать опцию (версия ≥ 24.11.30 — «complete XHTTP with true up/down separation»; базовый XHTTP+REALITY — с 24.10.31).

**scMaxEachPostBytes** (дефолт `{from: 1000000, to: 1000000}`) — максимальный размер каждого POST в `stream-up`/`packet-up`. Механика: чанкинг аплоада; меньше значение — больше запросов (похоже на обычную веб-активность, но больше оверхед), больше — эффективнее, но заметнее. Диапазон (from/to) — рандомизация размера для анти-фингерпринтинга.

**scMinPostsIntervalMs** (дефолт `{from: 30, to: 30}`) — минимальный интервал между POST. Пейсинг аплоада: сглаживает бёрсты, имитирует «человеческий» темп запросов.

**scMaxBufferedPosts** (дефолт 30) — серверный буфер ожидающих POST. Защита сервера от переполнения при медленном чтении; занижение при слабом сервере.

Прочее: `noGRPCHeader`/`noSSEHeader` — убрать Content-Type маркеры gRPC/SSE (SSE-заголовок помогает проходить буферизующие прокси); `browser_client.go` — клиент на Fetch API для браузеров (не релевантно десктопу, но показывает: протокол спроектирован неотличимым от обычного веба).

## Вердикт: лучшее

Консенсусный топ-транспорт 2025–2026: единственный с высокой оценкой и по обфускации, и по производительности, плюс полная поддержка CDN. Опции не маркетинговые — у каждой измеримая механика (паддинг ломает size-фингерпринт, xmux управляет видимым числом соединений, downloadSettings ломает корреляцию up/down). Слоп-фильтр пройден: всё подтверждено кодом.

**Отсеяно фильтром:** «XHTTP невидим для любого DPI» — маркетинг; при неправильном xmux (превышение лимитов nginx) соединения рвутся, при рассинхроне версий клиент/сервер downloadSettings молча не работает. Анекдотичные «XHTTP быстрее WS в N раз» без методологии — не воспроизводимо, зависит от сети.

## Внедрить в sora так

Состояние sora сейчас (`core/engine/plan.go`, `core/engine/xray/render.go`): `Transport` имеет только `Type/Path/Host/Service/Headers/Mode`; рендерится `mode/path/host/headers` в `xhttpSettings`. xmux/xPaddingBytes/downloadSettings/sc* — отсутствуют полностью (в тестах мелькает `extra.xmux.maxConnections`, но это не first-class).

1. **plan.go:** расширить `Transport`:
   - `Xmux XmuxConfig` (`MaxConcurrency int`, `MaxConnections int` — взаимоисключающие; `CMaxReuseTimes`, `CMaxLifetimeMs`, `HMaxRequestTimes`, `HKeepAlivePeriod`),
   - `XPaddingBytes Range {From, To int}` (дефолт 100/1000),
   - `ScMaxEachPostBytes Range`, `ScMinPostsIntervalMs Range`, `ScMaxBufferedPosts int`,
   - `Download *Transport` + `DownloadTLS *TLSConfig` (рекурсивно: свой сервер/security/транспорт для даунлоада).
2. **render.go (xray):** маппить всё в `xhttpSettings`/`downloadSettings`. sing-box (`lx` форк): проверить эквивалент (`xhttp` в sing-box поддерживает `download_detour`? — сверить с кодом sing-box перед рендером; если нет — варнинг).
3. **validate.go:** `maxConcurrency` и `maxConnections` одновременно → ошибка; `downloadSettings` при `mode: stream-one` → ошибка (код не поддерживает); версия движка < 24.11.30 + `downloadSettings` → варнинг в диагностике (молча не сработает).
4. **UI:** секция «XHTTP» в редакторе сервера: режим (auto/packet-up/stream-up/stream-one), xmux-пресеты («CDN/nginx-совместимый»: maxConcurrency=128, hMaxRequestTimes=1000), «Сплит up/down» — два блока серверов (аплоад-домен через CDN, даунлоад-домен напрямую). Предупреждение о несовместимости с XTLS-Vision (см. тему 03).
5. **One-click деплой:** шаблон сервера с `downloadSettings` из коробки (up через CDN-домен, down через REALITY) — такого нет ни у одного клиента из 13.
6. **Диагностика:** проверка версии Xray клиента и сервера (XHTTP требует паритета версий) + сравнение транспортов встроенным speedtest (XHTTP vs WS vs gRPC на одном сервере).

Приоритет: P0 — базовая проброска xmux/xPaddingBytes (дёшево, большой эффект); P1 — downloadSettings UI (дифференциатор).
