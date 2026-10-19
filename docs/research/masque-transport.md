# MASQUE / HTTP-3-проксирование как транспорт sora

Research-заметка (net-rd, тема 9/20). Статус на 2026-10-19.

## 1. Что такое MASQUE

- **CONNECT-UDP** — RFC 9484 (обновляет RFC 9298): проксирование UDP поверх HTTP
  через HTTP Datagrams. `:protocol = connect-udp`.
- **CONNECT-IP** — RFC 9485: проксирование произвольных IP-пакетов (полноценный
  VPN-туннель) поверх HTTP. Сервер выдаёт клиенту адрес (ADDRESS_ASSIGN),
  анонсирует маршруты (ROUTE_ADVERTISEMENT), опционально DNS (DNS_ASSIGN).
- Работает поверх HTTP/1.1 (Upgrade), HTTP/2 и HTTP/3 (Extended CONNECT).
  Полная мощь — поверх HTTP/3: мультиплексирование потоков, один congestion
  controller, UDP без head-of-line blocking, миграция соединения.
- WG MASQUE перечартерована: в работе расширения (UDP listen, оптимизация
  CONNECT-UDP для QUIC-трафика, Ethernet-туннелирование).

## 2. Кто реализовал (2025–2026)

- **sing-box 1.15.0-alpha.7** (авг 2025): MASQUE client + server — CONNECT-IP
  поверх HTTP/1.1, HTTP/2, HTTP/3; address assignment, route advertisement,
  внутренний стек или системный TUN. Отдельно: HTTP-proxy переписан —
  HTTP/2 по умолчанию, **HTTP/3 через опцию `version: 3`** и UDP-проксирование
  через CONNECT-UDP в HTTP inbound/outbound. Это главный задел для sora.
- **quic-go/masque-go**: CONNECT-UDP клиент+сервер (RFC 9298) как библиотека.
- **quic-go/connect-ip-go**: CONNECT-IP библиотека (используется в usque).
- **Cloudflare quiche / tokio-quiche**: MASQUE CONNECT + CONNECT-UDP в проде
  (Privacy Proxy, iCloud Private Relay — второй релей).
- **Apple iCloud Private Relay**, **Chrome IP Protection**: крупные деплойменты
  CONNECT-IP.
- **Oxylabs** (окт 2026): CONNECT-UDP в residential proxies, порт 5000.
- **mp0rta/mqvpn**: VPN поверх CONNECT-IP + Multipath QUIC.
- **ErikBcd/masquerade**: CONNECT-IP клиент (Rust, TUN).
- **UnboundTechCo/usque**: реимплементация WARP-клиента (CONNECT-IP).
- **Envoy**: CONNECT-UDP проксирование HTTP/3.
- **Xray-core, mihomo**: публичной поддержки MASQUE на дату исследования нет.

## 3. VPN-применения

- CONNECT-IP = «VPN без VPN-клиента»: full-tunnel через один HTTPS-запрос,
  адрес и маршруты прилетают капсулами. Для sora — потенциальный транспорт
  «одного прыжка», где не нужен ни WireGuard, ни Shadowsocks на сервере —
  достаточно HTTPS-терминатора.
- CONNECT-UDP поверх HTTP/3: пробрасывает UDP (QUIC сайтов, DNS, VoIP) без
  UDP-over-TCP костылей; трафик выглядит как обычный HTTP/3 к CDN — полезно
  против DPI, блокирующего «непохожий» UDP.
- Ограничения: UDP 443 режут часть сетей (нужен fallback); CONNECT-IP требует
  серверной стороны с пулом адресов и NAT; зрелость — alpha в sing-box.

## 4. Заделы в коде sora / sora-legacy

Архитектура обеих кодовых баз одинакова: `core/engine` строит
`engine.Plan` → `singbox.Render()` генерирует JSON → отдельный процесс
sing-box (`run -c stdin`). Значит MASQUE не требует нового сетевого кода —
нужно только научить рендер и каталог возможностей новому outbound'у.

- `core/engine/plan.go`: `Protocol` — добавить `ProtocolMASQUE = "masque"`;
  `Transport.Type` — добавить вариант для HTTP/3 (`"h3"`), т.к. сейчас
  только tcp/ws/grpc/h2/httpupgrade/xhttp.
- `core/engine/catalog.go`: `KindSingBox` — добавить `ProtocolMASQUE`
  в `Protocols`, гейт по версии ≥ 1.15 в `BuildCapabilities`
  (там уже есть прецедент версионного гейта для `lx.`-сборок).
- `core/engine/singbox/render.go`: case `ProtocolMASQUE` → outbound
  `{"type": "masque", "server", "server_port", "tls": {...}}`; для
  `ProtocolHTTP` — опция `"version": 3` при `Transport.Type == "h3"`.
  Версии в `Render` нет (в `supervise.Runtime` её нет) — гейт только на
  уровне capabilities/валидации, сам рендер рендерит по флагу плана.
- `core/engine/validate.go`: валидация нового протокола и h3-транспорта.
- Рендер покрыт тестами (`render_test.go`, `names_test.go`, `chain_test.go`) —
  новые кейсы ложатся в существующий паттерн.
- sora-legacy: `core/engine/*` зеркалит структуру (singbox/xray/mihomo,
  plan.go, catalog.go) — та же встройка.

## 5. Спека P0 / P1 / P2

### P0 — HTTP/3 для HTTP-outbound (CONNECT-UDP). Эффект средний, сложность низкая.

Добавить `Transport.Type = "h3"` → рендер `{"type": "http", "version": 3, ...}`
для sing-box ≥ 1.15. Даёт UDP-проксирование через CONNECT-UDP и маскировку
под обычный HTTP/3-трафик. Клиентская сторона полностью на sing-box;
серверная — любой MASQUE-совместимый HTTP-прокси. Fallback: `version` 2→1
уже встроен в sing-box (`disable_version_fallback: false`).
Оценка: 1–2 дня, в т.ч. тесты рендера и `sing-box check` на 1.15.

### P1 — MASQUE CONNECT-IP outbound. Эффект высокий, сложность средняя.

Новый `ProtocolMASQUE`: рендер `{"type": "masque", ...}` + TLS; выбор движка
только sing-box ≥ 1.15 (capabilities). Нужна серверная сторона: либо свой
MASQUE-сервер (sing-box 1.15 `masque` inbound с пулом адресов), либо
совместимый провайдер. DNS — через существующий DoH-механизм sora,
роуты прилетают от сервера (ROUTE_ADVERTISEMENT).
Оценка: 3–5 дней клиент + отдельная задача на сервер/инфраструктуру.

### P2 — QUIC-маскировка и оптимизация CONNECT-UDP под QUIC. Эффект средний, сложность высокая.

draft-ietf-masque-quic-proxy (scramble/forwarding transforms): прокси не
терминирует QUIC, а форвардит — DPI видит «сквозной» QUIC до настоящего
сайта. Требует поддержки обеими сторонами и зрелости драфта; в sing-box
пока нет. Отложить до стабилизации драфта и появления в sing-box.

## 6. Рекомендация

Начать с P0: минимальный дифф, работает на существующей инфраструктуре
HTTP-прокси, даёт измеримый выигрыш (UDP через прокси + H3-маскировка).
P1 — следующим, когда будет MASQUE-сервер. P2 — наблюдать.
