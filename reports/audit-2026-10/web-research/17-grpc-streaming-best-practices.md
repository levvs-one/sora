# gRPC-стриминг: клиент ↔ локальный демон (sora-core)

Дата: 2026-10-19. Запросы: 5 поисковых сессий (browser.search), приоритет источникам 2025–2026. Только чтение репозиториев, код не менялся.

## 1. Что нашёл

### 1.1. Backpressure: Send блокируется, очередь растёт, память течёт

Ключевой свежий материал: разбор серверного стриминга под backpressure в grpc-go ([dev.to, 21 день назад](https://dev.to/neeraj_singhi_golang/grpc-server-side-streaming-under-backpressure-flow-control-send-blocking-and-the-buffer-1gg8)). Тезисы:

- HTTP/2 flow control заставляет `stream.Send()` блокироваться, когда клиент не читает. Серверная очередь перед Send при этом неограниченно растёт → рост heap → GC жмёт хвост латентности несвязанных RPC.
- Правило: **явная slow-consumer политика — drop, coalesce или disconnect** ([aicassindra, WebSocket vs gRPC bidi, 2026](https://www.aicassindra.com/blogs/bidi/websocket_vs_grpc_bidi.html)). Ни один протокол не реплеит потерянные сообщения сам — sequence numbers, acks и политика медленного потребителя на совести приложения.
- Продакшн-паттерн из статьи: пер-send таймаут не гонкой на горутину-на-send (утечка горутин), а на уровне select по каналу + явный выбор: для упорядоченных событий — выселить стрим с `ResourceExhausted` (клиент переподключается с resume-токеном), для loss-tolerant (метрики, дашборды) — дропать событие и продолжать.
- Docker daemon events как референс локального демона: каждый слушатель — 100 мс на приём события, не успел — событие пропускается; `Subscribe` возвращает 256 последних событий ([pkg.go.dev, docker daemon/events](https://pkg.go.dev/github.com/docker/dockeR/daemon/events@v28.1.1+incompatible)). То есть: bounded ring buffer + silent skip медленных подписчиков — индустриальный стандарт для локальных демонов.

### 1.2. Reconnect: state machine, а не retry-loop; backoff с полным jitter

- Реконнект по state machine: Connected → Reconnecting(attempt, lastOffset) → BackingOff → Suspended. Ретраить только `UNAVAILABLE`; остальное — пробрасывать ([dev.to, mobile workshop](https://dev.to/software_mvp-factory/grpc-bidirectional-streaming-for-mobile-apps-a-practical-workshop-8ao)).
- Формула полного jitter: `delay = min(base*2^attempt, max)/2 + rand(delay/2)` — при 2% одновременных реконнектов без jitter'а thread pool ложится за <5 сек, с jitter'ом пик 40–80 коннектов ([dev.to, KMP](https://dev.to/software_mvp-factory/wiring-grpc-bidirectional-streaming-to-a-kotlin-multiplatform-mobile-client-3md)).
- Протокол должен поддерживать resume с offset: `sequence_id` в сообщениях с первого дня дизайна, иначе реконнект = полный реплей или потеря ([там же](https://dev.to/software_mvp-factory/grpc-bidirectional-streaming-for-mobile-apps-a-practical-workshop-8ao)).
- gRPC retry-policy через service config: только идемпотентные методы, `RetryableStatusCodes: ["UNAVAILABLE"]`, капированный backoff ([seomis.cc](https://seomis.cc/blog/grpc-enhance-your-calm)).

### 1.3. Keepalive: настраивать согласованно, для локального сокета — минимально

- Клиент: `Time` 10–30 сек для обычных приложений; `Timeout` 20 сек по умолчанию разумен. `PermitWithoutStream: true` — только если нужно детектить мёртвые коннекты в idle ([deepwiki, grpc-go keepalive](https://deepwiki.com/abab2025/grpc_grpc-go_master_5878d96/4.3-keepalive)).
- Сервер: `EnforcementPolicy.MinTime` не менее 1 мин (защита от ping-флуда), `MaxConnectionIdle` 5–15 мин для чистки, `MaxConnectionAge` + jitter ±10% для пересоздания коннектов.
- Для локального IPC через unix/named pipe keepalive-пинги избыточны: нет middlebox'ов с idle-таймаутами (это главная причина пингов в WAN — [appmaster.io](https://appmaster.io/blog/grpc-streaming-vs-rest-polling)). Серверу достаточно `MaxConnectionIdle` для уборки мусора.

### 1.4. Deadline'ы: унарные — всегда, у бесконечных стримов — heartbeat вместо deadline

- «Всегда ставить deadline» — золотое правило для унарных RPC; deadline по SLO, а не щедрый ([dev.to, BoldSign](https://dev.to/boldsign/why-grpc-is-ideal-for-high-performance-apis-4l84), [amtocsoft](http://amtocsoft.blogspot.com/2026/04/grpc-in-production-protocol-buffers.html)).
- Для долгоживущих стримов deadline на весь вызов не ставят; вместо этого — heartbeat-сообщения при тишине (держат стрим живым через прокси и детектят half-open соединения) + idle-таймаут на сервере ([appmaster.io](https://appmaster.io/blog/grpc-streaming-vs-rest-polling), [aicassindra ADK+grpc](https://www.aicassindra.com/blogs/adk_java/adk_java_grpc.html)).

### 1.5. Бинарный протокол vs JSON

- Protobuf: −60–80% размера, сериализация на 75% быстрее, парсинг в 2–6× быстрее JSON ([cherradix.dev](https://cherradix.dev/blog/beyond-json-binary-serialization-formats), [dzone](https://dzone.com/articles/replacing-json-with-protbuf)).
- Вывод для sora: бинарный protobuf уже используется — менять нечего. JSON только для экспорта/отладки (уже так). gRPC-сжатие (gzip) на локальном сокете не включать: CPU дороже выгоды.

### 1.6. Мультиплексирование

- HTTP/2 мультиплексирует стримы в одном соединении: один долгоживущий `ClientConn` на все RPC, а не dial на каждый стрим. containerd — референс: полный gRPC API поверх unix-сокета, shim'ы переживают рестарт демона ([dev.to, modern linux systems](https://dev.to/muktadirmaashif/modern-linux-systems-grpc-rest-and-process-communication-26nh)).
- Коалесцирование высокочастотных событий (StatsTick) перед отправкой: тики не чаще 1/сек, батчинг логов — снижает нагрузку на UI-рендер.

## 2. Статус-кво в sora (прочитано в коде, без изменений)

Уже хорошо:
- Server-streaming RPC: `WatchEvents` (с `after_sequence` + реплей истории журнала), `WatchLogs` (`after_sequence`, `ResourceExhausted` при отставании), `WatchSubscriptions`, `ProbeServers`, `BenchmarkServers`.
- `Journal.Append`: неблокирующий drop в полный канал подписчика (буфер 128) — серверная память ограничена, как у Docker.
- Унарные RPC с дефолтными deadline (connect 30s, stats 5s и т.д.), лимиты `MaxRecvMsgBytes`/`MaxSendMsgBytes`.

Пробелы:
1. `WatchEvents`/`WatchLogs`: `stream.Send` блокируется при медленном/мёртвом клиенте без таймаута — горутина хендлера висит бесконечно (контекст стрима не истекает, keepalive не настроен явно). Память журнала при этом ограничена drop'ом, но горутина + подписка живут.
2. Нет heartbeat в тихих стримах → half-open соединение (упавший без FIN клиент) детектится только по TCP-таймауту.
3. Нет явного keepalive/`MaxConnectionIdle` на сервере; нет per-send таймаута с политикой evict.
4. Не проверял Dart-клиент: неизвестен ли общий `ClientChannel` на все стримы и есть ли reconnect-state-machine с jitter при обрыве (см. раздел 1.2).

## 3. Что sora должен перенять

| # | Рекомендация | Почему | Эффект |
|---|---|---|---|
| R1 | Per-send таймаут + явная политика для стримов: в `WatchEvents`/`WatchLogs`/`WatchSubscriptions` ограничить время блокировки `Send` (напр. 10–30 с через select на канале, не горутина-на-send) и при истечении — закрывать стрим `ResourceExhausted` «resume from last sequence». Клиент переподключается с `after_sequence`. | Сейчас hung-клиент = hung горутина сервера навсегда; при рестарте UI это реальный сценарий (трей/Flutter умирает, стрим остаётся). Упорядоченные события требуют evict+reconnect, а не молчаливого дропа. Источник: [dev.to backpressure](https://dev.to/neeraj_singhi_golang/grpc-server-side-streaming-under-backpressure-flow-control-send-blocking-and-the-buffer-1gg8). | high |
| R2 | Heartbeat в `WatchEvents` при тишине (напр. пустой `CoreEvent`/`emitted_at`-only каждые 30 с) + серверный idle-watchdog: нет сообщений от клиента/прогресса дольше N мин → закрыть стрим. | Детект half-open соединений без агрессивных keepalive-пингов; держит стрим живым, даёт UI «пульс» соединения с демоном. Источник: [appmaster.io](https://appmaster.io/blog/grpc-streaming-vs-rest-polling). | medium |
| R3 | Reconnect state machine в Dart-клиенте: ретрай только на `UNAVAILABLE`, экспоненциальный backoff с полным jitter (base ~0.5 с, cap 30 с), resume с последнего `sequence`. Один общий `ClientChannel` на все стримы (мультиплексирование HTTP/2). | Без jitter массовый реконнект после рестарта `sora-core` даёт thundering herd; без resume — потеря событий или полный реплей. Источник: [KMP статья](https://dev.to/software_mvp-factory/wiring-grpc-bidirectional-streaming-to-a-kotlin-multiplatform-mobile-client-3md). | high |
| R4 | Серверный `MaxConnectionIdle` (5–15 мин) и `EnforcementPolicy.MinTime` ≥ 1 мин; keepalive-пинги клиента выкл. или редкие — на unix-сокете middlebox'ов нет. | Уборка мёртвых коннектов без лишнего трафика/пробуждений CPU; защита от ping-флуда. Источник: [deepwiki keepalive](https://deepwiki.com/abab2025/grpc_grpc-go_master_5878d96/4.3-keepalive). | medium |
| R5 | Коалесцирование `StatsTick`: не чаще 1 события/сек на стрим; логи уже батчатся (`LogBatch`) — держать. | Меньше нагрузка на Flutter-рендер и батарею; loss-tolerant данные — идеальный кандидат на coalesce вместо drop/disconnect. Источник: [aicassindra](https://www.aicassindra.com/blogs/bidi/websocket_vs_grpc_bidi.html). | medium |
| R6 | gRPC retry-policy в service config только для идемпотентных унарных методов (`UNAVAILABLE`, cap 5 попыток); стримы ретраить только через R3-механику resume. | Ретрай стримов без resume дублирует события; ретрай неидемпотентных методов (Connect/Disconnect) опасен. Источник: [seomis.cc](https://seomis.cc/blog/grpc-enhance-your-calm). | medium |
| R7 | Метрики/логгирование разрывов: счётчики `stream.send_timeout`, `stream.evicted`, причина закрытия (код статуса) на клиенте и сервере; алерт на рост `INTERNAL`/`ResourceExhausted`. | Без этого R1–R3 не наблюдаемы; disconnect reason — первое, что смотрят при дебаге стримов. Источник: [appmaster.io](https://appmaster.io/blog/grpc-streaming-vs-rest-polling). | low |

### Чего НЕ делать
- Не переходить на JSON поверх gRPC/HTTP: protobuf уже даёт −60–80% размера и в разы быстрее парсинг; JSON оставить только для экспорта ([cherradix.dev](https://cherradix.dev/blog/beyond-json-binary-serialization-formats)).
- Не включать gRPC-компрессию на локальном сокете: CPU дороже выгоды.
- Не ставить deadline на весь бесконечный стрим — вместо этого heartbeat + idle-watchdog (R2).
- Не делать dial на каждый стрим — один `ClientConn`, мультиплексирование HTTP/2 (паттерн containerd, [dev.to](https://dev.to/muktadirmaashif/modern-linux-systems-grpc-rest-and-process-communication-26nh)).
- Не ретраить всё подряд: только `UNAVAILABLE`, с jitter и cap ([BoldSign/dev.to](https://dev.to/boldsign/why-grpc-is-ideal-for-high-performance-apis-4l84)).

## Источники (все открыты поиском, 2025–2026 приоритет)
- https://dev.to/neeraj_singhi_golang/grpc-server-side-streaming-under-backpressure-flow-control-send-blocking-and-the-buffer-1gg8 — backpressure, send-таймаут, evict vs drop
- https://www.aicassindra.com/blogs/bidi/websocket_vs_grpc_bidi.html — контракты, slow-consumer политика, resume
- https://dev.to/software_mvp-factory/wiring-grpc-bidirectional-streaming-to-a-kotlin-multiplatform-mobile-client-3md — backoff+jitter, thundering herd
- https://dev.to/software_mvp-factory/grpc-bidirectional-streaming-for-mobile-apps-a-practical-workshop-8ao — state machine реконнекта, sequence_id с первого дня
- https://deepwiki.com/abab2025/grpc_grpc-go_master_5878d96/4.3-keepalive — keepalive client/server best practices
- https://seomis.cc/blog/grpc-enhance-your-calm — keepalive, reconnect, retry policy
- https://oneuptime.com/blog/post/2026-01-08-grpc-keepalive-connections/view — keepalive + ConnectParams backoff пример
- https://appmaster.io/blog/grpc-streaming-vs-rest-polling — heartbeat, idle-таймауты, логгирование disconnect'ов
- https://www.aicassindra.com/blogs/bidi/backpressure_in_bidirectional_streams.html — ручной flow control, isReady/onReady
- https://www.aicassindra.com/blogs/adk_java/adk_java_grpc.html — версии proto, deadline, keepalive под longest run
- https://cherradix.dev/blog/beyond-json-binary-serialization-formats — protobuf vs JSON цифры
- https://dzone.com/articles/replacing-json-with-protbuf — механика бинарного выигрыша
- https://dev.to/muktadirmaashif/modern-linux-systems-grpc-rest-and-process-communication-26nh — containerd gRPC over unix socket, shims переживают рестарт
- https://pkg.go.dev/github.com/docker/dockeR/daemon/events@v28.1.1+incompatible — Docker events: 256 ring buffer, 100ms skip
- https://dev.to/boldsign/why-grpc-is-ideal-for-high-performance-apis-4l84 — golden rules: deadlines, ретраи, версионирование
