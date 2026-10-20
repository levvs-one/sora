# Отчёт №34. Альтернативы domain fronting

**Аналитик цензуры №34 из 50 · 2026-10-20 · Источники: веб-поиск 2026-10-20 (7 запросов), приоритет 2025–2026.**

---

## 1. Статус классического domain fronting: мёртв, но идея жива

Классическое domain fronting (SNI = «front»-домен, HTTP Host = реальный домен, оба на одном CDN, CDN роутит по Host) **практически мертво как массовая техника**:

- Cloudflare — запретил ~2015; AWS CloudFront и Google — 2018 (принудительное соответствие SNI ↔ Host, отклонение mismatched); Azure — 2022; Fastly — ~2024.
- Провайдеры сверяют SNI (TLS ClientHello) с Host (HTTP) и отказывают или перекидывают на дефолтный бэкенд при расхождении.
- «Но не полностью»: остаются мелкие/миссконфигурированные CDN и новые cloud-продукты, где сверка не внедрена; это фрагментарно и ломается при первом же ужесточении конфига. Строить на этом продакшен-маршрут — ненадёжно (проверено — источники deepstrike.io, crazydomains.com.au, 2025).

Что пришло на смену (наследники идеи «выглядит как легитимный трафик к белому домену, внутри — нужное»):

1. **SNI/Host-разделение на своих инфраструктурах** — свой edge (nginx/ATS с разрешённым mismatch), либо эксплуатация чужих shared-edge (Underminr).
2. **Direct-to-IP** — соединение на известный IP CDN-edge в обход DNS, SNI = целевой домен.
3. **ECH (Encrypted Client Hello, RFC 9849, март 2026)** — шифрование внутреннего ClientHello (включая SNI) через ключ из HTTPS DNS-записи.
4. **XHTTP / SplitHTTP downloadSettings** — разделение up/down потоков на независимые соединения (Xray-core ≥ v1.8.x): можно разнести uplink и downlink по разным транспортам, IP, провайдерам, даже странам.
5. **CDN-легитимный трафик (serverless relay)** — XHTTP/WS-трафик через Vercel Edge Functions (`*.vercel.app`), Cloudflare Workers и т.п.: с точки зрения ТСПУ это TLS к респектабельному домену, внутри — relay на origin-VPS.

---

## 2. Где применяется

| Контекст | Роль техники |
|---|---|
| Обход цензуры (RU, IR, CN) | Маскировка прокси-трафика (VLESS/XHTTP, Shadowsocks) под трафик к белым доменам/CDN; обход SNI-блоков ТСПУ и DNS-подмен |
| C2 / red team | Скрытие командных каналов за репутацией крупных CDN (APT29-стиль, но уже через Underminr-моды, а не классический fronting — SC Media, 2025) |
| VPN-клиенты (наш кейс sora) | Транспорты VLESS+XHTTP/TLS, REALITY, relay через serverless-front — всё это «наследники» fronting-логики на стороне клиента |

Ключевое для RU-контекста: ТСПУ умеет **дропать ClientHello с ECH-расширением** при outer-SNI `cloudflare-ech.com` (ноябрь 2024, Cloudflare включил ECH по умолчанию → РKН отрезал). Т.е. противник уже умеет детектить маркеры новых техник, а не только SNI-строки.

---

## 3. Как технически: наследники

### 3.1. SNI/Host-разделение (классика и её остатки)

- **Механика:** TLS-handshake с SNI=front.example (белый домен), затем внутри зашифрованного HTTP — `Host: real.example`. Легитимный CDN с проверкой соответствия отклоняет.
- **Где ещё живо:** собственный edge (nginx `ssl_preread` + map SNI→backend, игнорирующий Host-mismatch — сознательно разрешённый фронт на своей инфраструктуре); мелкие CDN; **CVE-2026-102795** (Apache Traffic Server, окт. 2026): несрабатывание SNI→Host-matching policy — пример того, что сверка ломается и в мейнстрим-продуктах. Публичного PoC на момент написания нет — **не строить на этом**.
- **Underminr-вариант** (ADAMnetworks, май 2026): SNI и Host **совпадают** (поэтому CDN-защиты от fronting не срабатывают), а расхождение — между **DNS-ответом и фактическим IP/хостом**: резолвится доверенный домен → получается IP shared edge → TLS открывается на тот же IP, но с SNI/Host скрытого домена-арендатора того же edge. Четыре моды: Simple (обманный SNI после легитимного DNS), Split (сначала легитимное TLS-соединение для прохождения first-packet DPI, затем второе соединение с другим SNI на тот же IP), ECH (внутренний SNI зашифрован), Direct-to-IP (без DNS вообще).

### 3.2. Direct-to-IP

- **Механика:** клиент не делает DNS-запрос на целевой домен вообще; коннектится напрямую на известный edge-IP CDN (из кэша, хардкода, полученный через легитимный канал), SNI = нужный домен-арендатор того же edge.
- **Что видит ТСПУ:** TCP/TLS на IP из диапазона Cloudflare/Fastly/etc., SNI — произвольный домен на этом edge. DNS-телеметрии ноль (Underminr Direct-to-IP mode).
- **Ограничение:** IP edge меняются (anycast стабильнее), нужен канал обновления IP-листа; SNI всё равно в открытом виде (без ECH).

### 3.3. ECH (Encrypted Client Hello)

- **Механика (RFC 9849 + RFC 9848, март 2026):** два ClientHello — `ClientHelloOuter` (открытый, SNI = cover-домен, напр. `cloudflare-ech.com`) и зашифрованный `ClientHelloInner` (настоящий SNI + расширения), шифруется HPKE-ключом из HTTPS/SVCB DNS-записи домена. Расшифровать может только client-facing server (обычно CDN).
- **Статус внедрения (проверено):** Chrome ≥117, Firefox ≥118 — ECH включён по умолчанию (с 2023); **Android 17 (2026)** — OS-wide ECH + ECH GREASE по умолчанию (фальшивые ECH-расширения на все соединения, чтобы ECH-трафик не выделялся); OkHttp — ECH в core; NGINX 1.29.4 (фев. 2026) — нативный ECH; OpenSSL 4.0 — ECH (только shared mode); Cloudflare — основной провайдер.
- **Измерения:** Corrata, янв–мар 2025: <10% топ-1M сайтов с ECH-поддержкой, реально использовали 0.06% соединений; все observed outer-SNI были одинаковыми (`cloudflare-ech.com`) — ECH-сайты неразличимы между собой, но **сам факт ECH виден**.
- **Анти-ECH у цензоров (проверено):** ТСПУ/РКН дропает ClientHello с ECH при outer `cloudflare-ech.com` (с ноя. 2024); Китай/Иран бьют по шифрованному DNS (без DoH/DoT клиент не получает ECH-ключ → fallback на открытый SNI); Cloudflare-дока описывает, как сети **отключают** ECH (NXDOMAIN на HTTPS-запросы, canary `use-application-dns.net`).
- **Слабости:** не скрывает IP (бесполезно при выделенном IP сервиса); зависит от шифрованного DNS; fallback на plaintext SNI при недоступности ECH; outer-SNI — сильный фингерпринт (все одинаковые).

### 3.4. XHTTP / SplitHTTP с downloadSettings (сплит up/down)

- **Механика:** XHTTP (Xray-core, наследник SplitHTTP) делит прокси-сессию на независимые HTTP-запросы: uplink (POST, «outbound») и downlink (GET/SSE, «inbound»). В режимах `packet-up` / `stream-up` — минимум два соединения.
- **Ключевое свойство для нас:** `downloadSettings` в `xhttpSettings` позволяет задать **независимые параметры для downlink**: другой адрес, другой транспорт (up — QUIC, down — HTTPS), другой IP-стек (up — IPv6, down — IPv4), **разные серверы у разных хостеров в разных странах**, разные домены. Подтверждено документацией Xray-core (`transport/internet/splithttp/config.proto`: `downloadSettings`) и практикой (habr.com, 2025).
- **Эффект против DPI:** uplink несёт мало (запросы пользователя), downlink — много (ответы). Разнесение ломает корреляцию «запрос→ответ» внутри одного потока; два TLS-соединения к разным IP с разными SNI выглядят как два независимых веб-серфинга.
- **Ограничения:** XHTTP не работает с XTLS-Vision (защита от tls-in-tls — через XMUX-мультиплексирование и сам сплит); **sing-box-based клиенты XHTTP не поддерживают** (только Xray-based: v2rayN/v2rayNG — важно для sora, у нас Go-core: надо проверять, что за ядро); версии клиента и сервера Xray должны совпадать (активная разработка, глюки при рассинхроне); при REALITY — принудительно `stream-one` по умолчанию.

### 3.5. CDN-легитимный трафик (serverless relay)

- **Механика:** XHTTP-inbound на VPS + relay на Vercel Edge Function / Cloudflare Worker под `*.vercel.app` / `*.workers.dev`. Клиент: `TLS (SNI=vercel.com) → *.vercel.app → edge function (streaming relay, без буферизации) → HTTP/2 → backend Xray XHTTP inbound`.
- **Что видит цензор:** обычный TLS к домену Vercel/Cloudflare — репутация домена белая, SNI и Host совпадают, DNS легитимен. Это не fronting в классическом смысле, а «паразитирование на репутации чужой инфраструктуры» — и провайдеры это терпят, пока abuse не станет массовым.
- **Ограничения:** на Vercel Edge работает только XHTTP (не WS/gRPC/TCP/QUIC/REALITY); free-tier лимиты; IP origin-VPS скрыт, но сам relay-домен можно заблокировать по SNI (как уже делали с ECH-доменами) — **single point of failure на уровне SNI белого домена**.

---

## 4. Надёжность каждого (оценка для RU/ТСПУ, 2025–2026)

| Техника | Надёжность против ТСПУ | Комментарий |
|---|---|---|
| Классический fronting на крупных CDN | ☠ ~0 | Отклоняется на edge; мёртв с 2018–2024 |
| Fronting на своём edge (свой nginx) | ● Высокая | Мы сами разрешаем mismatch; упирается в репутацию IP/домена нашего edge, а не в технику |
| Underminr Simple/Split | ◐ Средняя, падает | Работает против DNS-only защит; Split-мода бьёт first-packet DPI, но CDN-корреляция может её палить (отмечено исследователями) |
| Underminr Direct-to-IP | ◐ Средняя | Нет DNS-телеметрии; SNI открыт — лечится SNI-блоком целевого домена, если он известен |
| ECH (Cloudflare) | ◐ Средняя, падает в RU | В RU дропается по маркеру ECH + outer `cloudflare-ech.com` с ноя. 2024; ECH GREASE (Android 17) частично маскирует сам факт, но GREASE≠реальный ECH — цензор может дропать все ECH-ClientHello |
| XHTTP downloadSettings сплит | ● Высокая (пока) | Нет известного сигнатурного детекта сплита up/down; сила — в асимметрии и разносе по инфраструктурам; требует Xray с обеих сторон |
| Serverless relay (Vercel/Workers) | ◐ Средняя | Живёт пока abuse незаметен; SNI белого домена — единая точка блокировки; free-tier/ToS-риски |

Шкала: ● высокая / ◐ средняя (работает, но есть известные контрмеры) / ☠ мертва. Все оценки — на октябрь 2026, ТСПУ умеет обновляться.

---

## 5. Что неизвестно / требует проверки

1. **Детектит ли ТСПУ XHTTP-сплит эвристически?** Нет публичных данных о сигнатурах под `packet-up`/`stream-up` с `downloadSettings`. Слух (помечаю как слух): в RU-гайдах упоминается детект старых Reality через TLS 1.3 NewSessionTicket — про XHTTP-сплит аналогичных разборов не найдено. Требует полевых тестов.
2. **ECH GREASE как маскировка:** Android 17 шлёт фейковые ECH-расширения везде. Неизвестно, дропает ли ТСПУ *все* ClientHello с ECH-расширением (включая GREASE) или только с валидным ECH. Если все — GREASE превращается в маркер для дропа.
3. **Underminr в дикой природе цензуры:** исследование ADAMnetworks — про enterprise/PDNS-обход (май 2026). Применимость мод против ТСПУ (а не корпоративного PDNS) не измерялась; Split-мода против state-DPI — экстраполяция.
4. **Живые мелкие CDN с разрешённым fronting:** нет актуального (2025–2026) публичного списка; всё, что находится, — быстро чинится после disclosure.
5. **Vercel/Workers-relay и ToS:** неизвестно, как быстро Vercel/Cloudflare реагируют на abuse-репорты по XHTTP-relay; прецедентов массовых банов именно XHTTP-relay не найдено.
6. **Корреляция up/down при downloadSettings:** не измерено, умеет ли DPI связывать два TLS-потока к разным IP по таймингу/размерам (traffic-analysis, а не сигнатуры). Теоретически — да, практически для ТСПУ — неизвестно.

---

## 6. Проблемы для тех-агентов

- **P34-1.** Реализовать в sora транспорт XHTTP с `downloadSettings`: uplink и downlink на разные адреса/транспорты (напр. up — QUIC/IPv6, down — TLS/IPv4 или разные хостеры). Требуется Xray-core с обеих сторон и совпадение версий — зафиксировать минимальную версию ядра в клиенте и проверять её при подключении.
- **P34-2.** Проверить, какое ядро реально использует sora Go-core: sing-box-based сборки XHTTP не поддерживают (подтверждено). Если ядро — sing-box, XHTTP-сплит недоступен без смены/добавления Xray-core — архитектурное решение.
- **P34-3.** Спроектировать fallback-цепочку при недоступности ECH: ECH → ECH GREASE → обычный TLS с «белым» SNI. GREASE может стать маркером для дропа — нужен kill-switch GREASE по результатам полевых тестов (см. п.5.2).
- **P34-4.** Реализовать ECH-клиент в sora (получение ECH-ключа из HTTPS DNS-записи через DoH; построение ClientHelloOuter/Inner). Учесть: без шифрованного DNS ECH бесполезен — DoH должен идти через уже установленный канал или доверенный резолвер.
- **P34-5.** Для serverless-relay (Vercel/Workers) нужен механизм ротации front-доменов: SNI белого домена — единая точка блокировки (прецедент: дроп `cloudflare-ech.com`). Хранить пул front-доменов + health-check доступности каждого из RU.
- **P34-6.** Direct-to-IP режим: вести обновляемый список edge-IP CDN (anycast-диапазоны стабильнее), получать его через защищённый канал (подписка/DoH), не хардкодить навсегда.
- **P34-7.** Underminr Split-мода: реализовать «прогревочное» легитимное TLS-соединение перед основным для прохождения first-packet DPI. Оценить риск CDN-сторона корреляции (исследователи предупреждают) — включать только как опцию.
- **P34-8.** Измерить, связывает ли ТСПУ-подобный DPI два XHTTP-потока (up/down к разным IP) по таймингу/размерам пакетов: поставить стенд, прогнать трафик-анализ, зафиксировать порог, при котором сплит перестаёт помогать.
- **P34-9.** Свой edge с разрешённым SNI/Host-mismatch (альтернатива мёртвому fronting на чужих CDN): поднять контролируемый фронт, где mismatch — фича, а не баг; упираемся в репутацию IP — решить вопрос «чистых» IP и их ротации.
- **P34-10.** Не использовать CVE-2026-102795 (ATS SNI/Host-matching) как опору: нет публичного PoC, вендор пофиксил в 9.2.15/10.1.4 — техника одноразовая и уже мёртвая.

---

*Источники: deepstrike.io/blog/what-is-domain-fronting; crazydomains.com.au/learn/domain-fronting/; praetorian.com/blog/domain-fronting-is-dead-long-live-domain-fronting/; scworld.com/news/underminr-exploitation-poses-similar-risks-to-domain-fronting-researchers-say; dev.to/dnsassistant (Underminr 4 modes); cyberpress.org/leverage-shared-cdn-edge-ips/; ambientnode.uk/domain-fronting-ech; vectra.ai/topics/encrypted-traffic-analysis; thehackernews.com/2026/08/android-17-adds-os-wide-ech-to-hide.html; developers.cloudflare.com/ssl/edge-certificates/ech/; netd.cs.tu-dresden.de/papers/mgsw-dechd-26.pdf (IMC'26); habr.com/en/articles/990208/ (XHTTP); habr.com/en/articles/990206/ (whitelist bypass chains); deepwiki.com/lhear/Xray-core/4.3-splithttp-transport; lobehub.com (vercel-xhttp-relay); cybernews.com/tech/russia-tries-to-whack-another-mole-in-its-internet-censorship-quest/ (DoH/DoT-блокировки RU); malware.news (TSPU timeline).*
