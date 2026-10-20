# WebSocket/CDN-фронтинг техники для прокси — веб-исследование #35

Дата: 2026-10-19. Тема: WebSocket за CDN, маскировка path/headers, early data, multiplexing, практика Xray/sing-box. Минимум 6 поисковых запросов, источники 2025–2026.

## 1. Что нашёл (с источниками)

### 1.1. CDN, пропускающие WebSocket-фронтинг

- **Cloudflare** — полноценная поддержка WS/WS через CDN, любые custom paths, TLS 1.2+, все CF-порты (80/8080/8880/2052/2082/2086/2095/443/2053/2083/2087/2096/8443): [Xray-examples VLESS+WebSocket](https://deepwiki.com/XTLS/Xray-examples/2.5-vless-+-websocket), [VMess client setup (Argo/туннели)](https://deepwiki.com/wy580477/PaaS-vmess-trojan-argo/5.1-vmess-client-setup). Классика `vless://uuid@cf-domain:443?type=ws&security=tls&sni=argo-domain&host=argo-domain&path=/uuid-vless`.
- **Cloudflare Argo Tunnel** — самый живучий паттерн: Xray/sing-box слушает на localhost, cloudflared выносит WS наружу, домен `*.trycloudflare.com`, TLS терминируется на edge CF. Четыре режима (Origin Rules, Temporary, Json, Token) по степени контроля домена: [github-edgeone Argo](https://deepwiki.com/liwoyuandianer/github-edgeone/3.4-argo-tunnel-integration). Оригин-сервер вообще не светится в интернете.
- **AWS CloudFront** — WS-проксинг поддерживается, путь не должен конфликтовать с origin-правилами: [таблица совместимости](https://deepwiki.com/XTLS/Xray-examples/2.5-vless-+-websocket).
- **KeyCDN** — ограниченная поддержка; generic CDN — case-by-case.
- Доменный фронтинг в чистом виде (SNI ≠ Host) на CF большей частью закрыт, но рабочий паттерн — **domain shadowing** (USENIX'21: front-end разрешённого домена + back-end заблокированного на одном CDN, все индикаторы — URL, SNI, Host — принадлежат разрешённому домену): [usenix.org](https://www.usenix.org/conference/usenixsecurity21/presentation/wei). Релевантно для sora как «план Б», если ws по прямому домену блокируется.
- Полевая практика (РФ/Иран, 2026): CDN-IP-сканеры (cdn-ip-scanner) подбирают быстрейшие edge-IP и тестируют их против `vless://`/`vmess://`/`trojan://`-конфигов с автозаменой IP — по ISP (Irancell, MCI, Rightel, российские операторы): [offsecblog, 2026-09](https://www.offsecblog.com/2026/09/inside-cdn-ip-scanner-how-it-maps-fast.html). Т.е. «CDN-фронтинг» — это уже не про домен, а про подбор edge-IP под конкретного оператора.

### 1.2. Маскировка path/headers

- Стандартный приём: секретный WS-path (лучше — UUID-based, напр. `/{uuid}-vless`), Nginx `location /secretpath` → Xray localhost, всё остальное — на настоящий сайт: [V2Ray & WebSockets (dev.to)](https://dev.to/lag_lagendary/v2ray-websockets-3b21). Проверка `Upgrade == websocket`, иначе 404.
- Практика с Worker/Pages: конфиг-эндпоинты `/{uuid}/sb` и т.д., неизвестные запросы — на случайные «камуфляжные» хосты: [Request Processing Flow](https://deepwiki.com/yonggekkk/Cloudflare-vless-trojan/3.2-request-processing-flow).
- Cloudflare Workers/Pages раздают готовые VLESS/WS-конфиги по `/{uuid}` с QR — то же самое sora уже умеет парсить.
- Sing-box поддерживает custom WS-headers (`headers` в transport), Xray — `wsSettings.headers` (в старых схемах), HTTP Upgrade — `httpupgradeSettings`. sora сегодня рендерит только path + Host.

### 1.3. Early data (0-RTT для WebSocket)

- **Xray**: `?ed=2048` в path query — начальные данные (зашифрованный VLESS-заголовок) летят в самом handshake, экономит 1 RTT: [VMess client setup](https://deepwiki.com/wy580477/PaaS-vmess-trojan-argo/5.1-vmess-client-setup), [argosbx dual-support](https://deepwiki.com/yonggekkk/argosbx/3.3-supported-protocols-and-kernels).
- **sing-box**: `max_early_data: 2048`, `early_data_header_name: Sec-WebSocket-Protocol`, данные в base64 в path или header: [sing-box WS+gRPC internals](https://deepwiki.com/reF1nd/sing-box/4.3.2-websocket-and-grpc). Дефолтный паттерн `233boy/sing-box`: early_data_header_name = `Sec-WebSocket-Protocol`: [Caddy integration](https://deepwiki.com/233boy/sing-box/5.2-caddy-integration).
- Нюанс: early data требует поддержки и сервером, и клиентом; не все CDN проксируют заголовок `Sec-WebSocket-Protocol`, поэтому fallback — path-метод.
- **Mihomo/clash**: `ws-opts` поддерживает path/headers; early-data — через `?ed=` в v2ray-подобных ссылках (ограниченно).

### 1.4. Multiplexing поверх WS

- XHTTP `xmux` — истинный мультиплекс нескольких логических потоков в одном WS/H2-соединении; упирается в лимиты reverse-proxy (Nginx ~128 streams): [Xray-examples Transport Technologies](https://deepwiki.com/XTLS/Xray-examples/1.2-transport-technologies).
- XHTTP vs WS по матрице: WS — obfuscation medium/perf medium/CDN yes; XHTTP — obfuscation high/perf high/CDN yes. Т.е. **для CDN-фронтинга XHTTP объективно лучше WS** и тоже проксируется: [та же страница](https://deepwiki.com/XTLS/Xray-examples/1.2-transport-technologies). SplitHTTP — тоже CDN-совместим, но сложнее.
- Outline (Jigsaw) официально документирует Shadowsocks-over-WebSocket через Cloudflare Tunnel как продакшн-путь: [developer.getoutline.org](https://developer.getoutline.org/vpn/advanced/websockets/).
- WebTransport за reverse-proxy в 2026 практически не работает (проблема слоя прокси, не браузеров) — не конкурент WS/XHTTP для клиентских VPN: [lupyd.com, 2026-10](https://blogs.lupyd.com/blog/the-state-of-webtransport-and-the-proxy-problem/).

## 2. Что sora должен перенять

Проверено по коду (только чтение, `core/parser/parser.go`, `core/engine/{xray,singbox,mihomo}/`):

**Gap 1. WS early data не поддерживается нигде.** Парсер кладёт `ed` в общий `Options`, но рендеры не используют: `xray/render.go:251-253` рендерит только `path`+`host` в `wsSettings` (нет `maxEarlyData`); `singbox/render.go:275-276` — только `path`+`headers` (нет `max_early_data`/`early_data_header_name`). Подписки/ссылки с `?ed=2048` молча теряют 0-RTT. **Оценка: medium** (1 RTT на handshake — заметно на мобильных/слабых сетях, плюс часть «камуфляжа» handshake-трафика).

**Gap 2. Custom WS-заголовки не проходят.** Парсер и транспорты несут только `Host`. Кастомные заголовки из ссылок (User-Agent, CDN-специфичные) теряются: для sing-box `headers` есть только у xhttp-транспорта, для xray `wsSettings` headers не рендерятся вообще. **Оценка: medium** (камуфляж под конкретный CDN/сайт — рабочая техника; конкурентные клиенты вроде Streisand/FoXray заголовки пробрасывают).

**Gap 3. Нет UX-пресета «CDN-fronting».** У sora нет: (а) распознавания/метки серверов «за CDN» в UI; (б) режима «оптимальный CF edge-IP» (как cdn-ip-scanner: тест edge-IP против конфига с автозаменой IP); (в) подсказок/шаблонов настройки Argo-туннеля или CloudFront-фронтинга в диагностике/справке. Конкуренты (v2rayN — сканирование и замена IP; Karing — 4 канала синка конфигов) это частично покрывают. **Оценка: high** — для цели «лучший клиент мира» фронтинг — ключевой сценарий выживаемости в РФ/Иране/Китае, а sora его никак не выделяет.

**Gap 4. XHTTP вместо WS для CDN — не подсказывается.** Все три движка sora уже умеют XHTTP, но клиент не умеет предлагать «если сервер за CDN, предпочтите XHTTP над WS» (выше обфускация и производительность при той же CDN-совместимости). **Оценка: medium** (чисто клиентская логика/подсказка, сервер должен поддерживать XHTTP).

**Gap 5. SplitHTTP/HTTPUpgrade как запасной транспорт.** `httpupgrade` рендерится только в xray/sing-box; mihomo — не проверен; SplitHTTP нигде. Для жёстких DPI-сетей, где WS сигнатурится, это дешёвый fallback. **Оценка: low** (нишевый сценарий, ws+xhttp покрывают 95%).

**Не перенимать:** WebTransport (не работает за reverse-proxy/CDN в 2026); «доменный фронтинг» в лоб через SNI≠Host (большинство CDN закрыли); самописные CDN IP-сканеры в клиент — только как опциональный инструмент, не дефолт.

## 3. Конкретные рекомендации (приоритет)

1. **Парсить и применять `ed`**: `?ed=N` → Xray `wsSettings.maxEarlyData`, sing-box `max_early_data` (+ `early_data_header_name: Sec-WebSocket-Protocol` при path/header fallback). Эффект: −1 RTT на каждое соединение. (high среди medium-задач)
2. **Проброс custom headers** из URI (`headers` JSON / отдельные параметры) в sing-box `headers` и xray `wsSettings`. (medium)
3. **«CDN-fronting» как первоклассный сценарий в UI**: бейдж «за CDN» у сервера (эвристика: CF IP-диапазоны / `cdn` в имени / Argo-домен), кнопка «подобрать быстрый edge-IP» (тест скорости по списку CF edge-IP против текущего конфига), шаблон-справка «как поднять Argo-туннель за 5 минут». (high)
4. **Подсказка «XHTTP для CDN-серверов»** в автовыборе транспорта/диагностике, когда конфиг типа ws+cdn. (medium)
5. **HTTPUpgrade/SplitHTTP** — дотянуть рендеры mihomo и добавить SplitHTTP в xray/sing-box рендеры как экспериментальный fallback. (low)
