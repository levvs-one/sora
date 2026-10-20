# Web-research #24: Hysteria2 — реальный тюнинг и опыт эксплуатации

Дата: 2026-10-19. Тема: практический тюнинг Hysteria2 (congestion control, QoS/UDP-обход, порты, salamander, замеры, проблемы с DPI) и что sora должна перенять.

## Текущее состояние Hysteria2 в sora (по коду, read-only)

- sing-box renderer (`core/engine/singbox/render.go`): передаёт только `type: hysteria2`, `password` и `obfs: {type, password}`. **`up_mbps`/`down_mbps` (brutal CC) не передаются вообще** — значит brutal congestion control никогда не включается (sing-box падает обратно на BBR, см. ниже).
- mihomo renderer (`core/engine/mihomo/proxy.go`): `password`, `obfs`/`obfs-password`. Без `up`/`down`, без `ports`/`hop-interval`.
- Xray (`core/engine/xray/render.go`): Hysteria2 маппится на устаревший `hysteria` v1-outbound; obfs для Xray не рендерится (возвращает ошибку).
- QUIC-настройки (recv windows), port hopping, uTLS fingerprint поверх hy2 — нигде не прокинуты.

Вывод: sora сегодня использует Hysteria2 в «дефолтном», самом слабом режиме — без её главного преимущества.

## Что нашёл (по источникам)

### 1. Brutal congestion control: главный параметр hy2

Hysteria2 имеет два режима congestion control (источник: sing-box docs via [deepwiki](https://deepwiki.com/hoaxisr/amnezia-box/4.2-quic-based-outbounds-(hysteria-hysteria2-tuic)), [офиц. доки](https://hysteria.network/docs/advanced/Full-Server-Config/)):
- **Brutal** — включается, когда заданы `up_mbps`/`down_mbps` (клиент) / `bandwidth.up/down` (сервер). Агрессивно заполняет заданную полосу, не реагируя на потерю пакетов как на конгестию (в отличие от TCP).
- **BBR** — fallback, когда bandwidth не задан. Официальный клиент Hysteria без `up/down` использует BBR.

Ключевые детали:
- Значения — это **hint'ы для CC, а не жёсткие лимиты**. Завышение относительно реального канала → перегрузка и деградация; занижение → недоиспользование (Full Server Config).
- `disableLossCompensation`: Brutal при потерях посылает чуть быстрее заданного, чтобы компенсировать loss. Иногда вредит — можно отключить (серверная опция, локальна для направления upload этого хоста).
- `ignoreClientBandwidth` (сервер): игнорировать клиентские hint'ы и использовать non-Brutal контроллер — полезно знать, потому что **многие провайдеры подписок это включают**; тогда клиентский тюнинг up/down бесполезен.
- Реальные замеры (2025–2026):
  - Москва → Германия, 100 Мбит: Hysteria2 дал 88 Мбит down / 62 Мбит up против VLESS 72/45 и 68/41 ([medium.com тест](https://medium.com/@alexfomin010/how-we-set-up-a-personal-vpn-with-hiddify-on-two-servers-in-germany-fc4f1a5e0273)). Hysteria2 стабильно выигрывает по throughput за счёт агрессивного CC; VLESS выигрывает по стабильности.
  - Clash reference (2026): «Throughput on a lossy link: Hysteria2 — Highest, VLESS — Low» ([clashzip.com](https://www.clashzip.com/en/reference.html)).
  - Китайский тест (2026): на чистом канале Trojan 62 / VLESS 67 / Hysteria2 94 Мбит; при 3% потерь — 38 / 35 / 51 ([yjw333.com](https://www.yjw333.com/3lafx3tit.html)).
- Предостережение: завышенный up «не доказательство, что маршрут выдержит» — sender перегружает маршрут, растут потери, страдает и остальной трафик ([qsvpn.com, 2026](https://qsvpn.com/en/blog/articles/hysteria2-protocol-explained-2026.html)). Практика: выставлять по реальному тарифу пользователя/сервера, а не «побольше».

### 2. Port hopping против QoS/троттлинга UDP

- Официальная механика ([hysteria.network Port Hopping](https://hysteria.network/docs/advanced/Port-Hopping/)): клиенты в Китае сообщают, что ISP режут/троттлят долгоживущие UDP-соединения, но **ограничение часто привязано к конкретному порту**. Клиент: `example.com:1234,5678,9012` / `20000-50000`, случайный выбор порта на старте + периодическая смена. `hopInterval: 30s` (sing-box: `hop_interval`, default 30s, min 5s). Есть `minHopInterval`/`maxHopInterval` для случайного интервала — менее предсказуемый паттерн.
- sing-box inbound/outbound поддерживает `server_ports` + `hop_interval` (deepwiki mihomo: `ports`, `hop-interval`, min 5s).
- **Важно**: если режется UDP целиком (а не по портам), hopping не помогает. Тогда альтернатива — **Mimic** (маскировка под TCP), но с hopping'ом несовместим.
- Из опыта: если TCP-протоколы работают, а hy2 таймаутит — сначала проверить UDP-достижимость порта/файрвол, а не крутить bandwidth ([yjw333.com](https://www.yjw333.com/3lafx3tit.html)).

### 3. Salamander / Gecko обфускация

- По умолчанию hy2 мимикрирует под HTTP/3. Salamander превращает каждый пакет в «случайные» байты без паттерна — против сетей, которые режут QUIC/HTTP3, но не UDP вообще ([Full Server Config](https://hysteria.network/docs/advanced/Full-Server-Config/), [habr](https://habr.com/en/amp/publications/990176/)).
- **Gecko (экспериментальный)**: поверх salamander дополнительно фрагментирует QUIC handshake-пакеты на чанки случайного размера с паддингом (`minPacketSize` 512 / `maxPacketSize` 1200, ≤2048). Бьёт по DPI-сигнатурам handshake.
- Цена: с включённой обфускацией сервер несовместим со стандартными QUIC/HTTP3-соединениями (нельзя совместить с маскировкой под сайт на том же порту). Пароль salamander должен совпадать на клиенте и сервере.
- sing-box outbound поддерживает только `salamander` (mihomo `obfs: salamander` + `obfs-password`); **gecko в sing-box/mihomo клиентах не поддерживается** — только официальный клиент/сервер Hysteria.

### 4. Реальные проблемы эксплуатации (свежие, 2026)

- **Stall после аплоада** ([lab.colitu.com, окт 2026](https://lab.colitu.com/research/hysteria2-stall-after-upload)): баг официального сервера v2.11.0 — дестинация, переставшая читать upload, пинила flow-control window всего соединения; клиент переставал слать stream data, хотя QUIC жив. Лечится серверным патчем (write deadline 10s). Урок для sora: health-check транспорта должен детектить «живое, но не шлёт» состояние (их метрика: запись без прогресса), а не только обрыв соединения.
- Hysteria2 **полностью зависит от UDP**: «No. Hysteria2 relies on QUIC over UDP» при блокировке UDP ([nagorik.tech](https://nagorik.tech/blog/how-modern-protocols-bypass-dpi)). Обязателен TCP-fallback (у sora есть fallback-группы — hy2 должен всегда идти в паре с VLESS/Trojan spare).
- Настройки QUIC-окон (`initial/max stream/connection receive window`) и `udp-mtu` (mihomo default 1197) влияют на throughput; в дефолтах sing-quic обычно ок, но для high-BDP каналов окна стоит поднимать.

### 5. URL-формат и параметры (для импорта/экспорта ссылок)

`hysteria2://user@host:port?password=..&up=100&down=500&sni=..&obfs=salamander&obfs-password=..&insecure=1&alpn=h3,h2` ([sub-convert deepwiki](https://deepwiki.com/jwyGithub/sub-convert/12.5-hysteria2-protocol)). Поддерживаемые префиксы: `hysteria2://`, `hy2://`, `hysteria://`.

## Что sora должна перенять

| # | Что | Почему | Эффект |
|---|---|---|---|
| 1 | **Прокинуть `up_mbps`/`down_mbps` в sing-box и `up`/`down` в mihomo** (новые поля Outbound, UI: «скорость тарифа», автоопределение через speedtest). Сейчас hy2 в sora = BBR без brutal, т.е. без главного преимущества протокола. | high |
| 2 | **Port hopping: `server_ports` + `hop_interval`** — парсинг мультипорт-формата из hy2-ссылок (`host:20000-50000`) и UI-поле «диапазон портов», прокидка в оба движка. | Прямой ответ на троттлинг долгоживущих UDP у ISP (кейс Китая, актуален и для части провайдеров РФ). | high |
| 3 | **Salamander уже есть; добавить поддержку в UI как явный тогл** + warn, что сервер должен его поддерживать. Gecko — только если sora будет использовать официальный hy2-клиент как движок (сейчас нет) → отложить. | medium |
| 4 | **Авто-калибровка brutal по speedtest**: при первом подключении hy2-сервера замерять реальную полосу и подставлять up/down, периодически перепроверять (стыкуется с roadmap «история скорости серверов»). Ручной ввод «тарифа» почти все выставляют неверно. | high |
| 5 | **Детект «stall без обрыва»**: в health-check транспорта добавить условие «нет прогресса записи N секунд при живом соединении» → failover на TCP-spare раньше, чем таймаут (урок colitu). | medium |
| 6 | **Порт 443/udp + отдельный SNI как пресет**: дефолтный совет «443/udp» для hy2-серверов (меньше режут, маскировка под QUIC/HTTP3) в one-click-развёртывании сервера из клиента (roadmap P2). | medium |
| 7 | **QUIC receive windows как advanced-настройка** для high-latency каналов; `disableLossCompensation`-аналог на клиенте при джиттере. | low |
| 8 | **Предупреждение в UI**: если сервер включил `ignoreClientBandwidth` (детектить нельзя напрямую — но можно показать хинт, что провайдер может игнорировать up/down). | low |

## Конкретные параметры для конфигов (шпаргалка)

```yaml
# sing-box outbound hysteria2 — целевой вид
type: hysteria2
server: example.com
server_port: 443
server_ports: ["20000-50000"]   # port hopping
hop_interval: 30s              # или 15-45s random (min/max у офиц. клиента)
up_mbps: 100                   # brutal CC; = реальный upload канала
down_mbps: 500                 # brutal CC; = реальный download канала
password: "..."
obfs: {type: salamander, password: "..."}
tls: {enabled: true, server_name: example.com, alpn: ["h3"]}
```
```yaml
# mihomo proxy hysteria2 — целевой вид
type: hysteria2
server: example.com
port: 443
ports: 20000-50000
hop-interval: 30
up: "100 Mbps"
down: "500 Mbps"
password: "..."
obfs: salamander
obfs-password: "..."
sni: example.com
skip-cert-verify: false
```

## Ссылки

- https://hysteria.network/docs/advanced/Full-Server-Config/ — bandwidth, loss compensation, ignoreClientBandwidth, salamander/gecko
- https://hysteria.network/docs/advanced/Port-Hopping/ — официальная механика hopping
- https://lab.colitu.com/research/hysteria2-stall-after-upload — stall-баг v2.11.0 и health-check «нет прогресса»
- https://medium.com/@alexfomin010/how-we-set-up-a-personal-vpn-with-hiddify-on-two-servers-in-germany-fc4f1a5e0273 — замеры hy2 vs VLESS, Москва→DE 2025
- https://www.clashzip.com/en/reference.html — сравнение протоколов (lossy link: hy2 highest)
- https://www.yjw333.com/3lafx3tit.html — замеры при 0%/3% потерь, методика диагностики
- https://qsvpn.com/en/blog/articles/hysteria2-protocol-explained-2026.html — предостережение про завышенный up
- https://nagorik.tech/blog/how-modern-protocols-bypass-dpi — hy2 vs DPI, зависимость от UDP
- https://habr.com/en/amp/publications/990176/ — salamander/hopping практика (RU)
- https://deepwiki.com/iyanging/mihomo/5.6-hysteria-and-hysteria2 — поля mihomo Hysteria2Option
