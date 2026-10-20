# Техники DPI-обхода 2026 (веб-исследование №21)

Дата: 2026-10-19. Текущее состояние sora (для сравнения): `core/engine/bypass/` — zapret **tpws** (userspace SOCKS-прокси, по одному процессу на стратегию): `SplitPos`, `Disorder`, `OOB`, `TLSRecord`, `HostCase`, `DomainCase`, `MethodEOL`. Плюс `Fragment` в планах (Xray `fragment`: packets/length/interval). uTLS-фрагментация уже есть в UI.

## 1. Что нового / что работает в 2025–2026

### 1.1. zapret: tpws vs nfqws — у sora устаревшая половина
Zapret существует в двух обликах: **tpws** (userspace transparent proxy, что использует sora) и **nfqws/winws** (nfqueue/WinDivert, перехват пакетов на уровне ядра). Вся новая разработка 2025–2026 идёт в nfqws/winws: [bypasscore.com/blog/zapret-vs-goodbyedpi-vs-byedpi-comparison](https://bypasscore.com/blog/zapret-vs-goodbyedpi-vs-byedpi-comparison)
- UDP/QUIC-десинхронизация: `--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=<bin>` — **единственный** из популярных инструментов с полноценным QUIC-обходом; GoodbyeDPI/ByeDPI/SpoofDPI TCP-only.
- Цепочки стратегий в одном правиле: `fake,split2`, `fakedsplit`, `multidisorder`, `disorder2`, `split2`, `syndata` (данные в SYN-пакете), `ipfrag2` (IP-фрагментация первого пакета), `rst/rstack` (фейковые RST), IPv6 `hopbyhop`/`destopt`.
- Fooling: `--dpi-desync-fooling=md5sig,badseq,badsum`; `--dpi-desync-wssize` (манипуляция TCP window); `autottl` (автоподбор TTL так, чтобы фейк умирал на DPI, а не у сервера); `split-pos=1,midsld`; `repeats`.
- Рабочие рецепты 2026 (из стандартных конфигов и blockcheck):
  - HTTPS: `--dpi-desync=fake,split2 --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=<bin> --dpi-desync-fake-tls-mod=rnd,rndsni,padencap --dpi-desync-autottl=2`
  - HTTPS ADV: `--dpi-desync=fake,multidisorder --dpi-desync-split-pos=1,midsld --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --dpi-desync-repeats=11`
  - HTTP: `--dpi-desync=split2 --dpi-desync-split-http-req=host`
  - QUIC: `--dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=<bin>`
  - [deepwiki.com/ankddev/zapret-discord-youtube/5.5-creating-custom-configurations](https://deepwiki.com/ankddev/zapret-discord-youtube/5.5-creating-custom-configurations)
- **blockcheck.sh** — автоматический перебор десятков стратегий под конкретного провайдера, находит рабочую и выдаёт готовую команду. Прямое подтверждение ценности фичи «авто-тюнинг» из roadmap §3 №2: [deepwiki.com/bol-van/zapret-win-bundle/4-dpi-bypass-testing](https://deepwiki.com/bol-van/zapret-win-bundle/4-dpi-bypass-testing)

### 1.2. TSPU научился троттлить по паттерну трафика (лето 2026)
Из issue Flowseal/zapret-discord-youtube#17108 (авг. 2026): ТСПУ режет канал **по паттерну трафика в реальном времени** — YouTube идёт 5 секунд, потом соединение умирает: [github.com/Flowseal/zapret-discord-youtube/issues/17108](https://github.com/Flowseal/zapret-discord-youtube/issues/17108). Пакетный десинх (split/fake) против этого недостаточен — нужна маскировка под обычный трафик и смена транспорта.

### 1.3. Эволюция GFW (данные 2025–2026)
- **Утечка Geedge/MESA (сен. 2025)** — крупнейшая в истории утечка внутренних документов GFW: файрвол стал продуктом, базы известных дата-центр-IP для блокировки VPN-инфраструктуры, расшифровка QUIC-рукопожатий с 2024, «волатильные резеты» (инъекция поддельных TCP в августе 2025): [streamx.com/resources/blog/2025/what-great-firewall-biggest-leak-tells-us-about-the-splinternet-of-the-future.html](https://www.streamx.com/resources/blog/2025/what-great-firewall-biggest-leak-tells-us-about-the-splinternet-of-the-future.html)
- С 2025: **поведенческий DPI + ML-классификация в реальном времени** (timing, dwell time) вместо эвристик — «апрельская чистка 2026» резала все соединения одного ДЦ/протокола сразу: [sunsetbrowser.app/blog/gfw-ai-detection-2026-protocol-survival-en?lang=en](https://sunsetbrowser.app/blog/gfw-ai-detection-2026-protocol-survival-en?lang=en)
- **USENIX Security 2025**: GFW парсит QUIC Initial-пакет и извлекает SNI — QUIC блокируется **одним** Initial-пакетом: тот же источник.
- Что по исследованиям работает в 2025: **QUIC SNI slicing** (разбиение QUIC Initial по нескольким UDP-датаграммам — по умолчанию в Firefox 137, V2Ray 5.33, Xray 25.6.8, Hysteria 2.6.2, sing-box 1.12); **pre-QUIC dummy packet** (любая UDP-датаграмма перед Initial ломает first-packet assumption); **ECH** (GFW на нач. 2025 не блокирует QUIC с ECH); мимикрия под настоящий TLS 1.3 (Trojan/VLESS+TLS); **uTLS-отпечатки браузеров**; QUIC-прокси на высоких портах (GFW пропускает QUIC-инспекцию, когда source port ≤ dest port); **QUIC connection migration** после handshake; ротация IP, избегание дата-центров: [medium.com/btcvpn/inside-the-great-firewall-how-chinas-censorship-machine-really-works-and-how-to-beat-it-b92b3be410a2](https://medium.com/btcvpn/inside-the-great-firewall-how-chinas-censorship-machine-really-works-and-how-to-beat-it-b92b3be410a2)

### 1.4. Протоколы: XHTTP, ECH, AnyTLS
- **XHTTP** — маскировка под обычный HTTP/2; в режимах `packet-up`/`stream-up` аплоад/даунлоад идут по **раздельным соединениям**, которые могут идти к разным адресам/серверам/странам/протоколам (outbound по QUIC, inbound по HTTPS) — резко усложняет анализ. Несовместим с XTLS-Vision; sing-box клиенты XHTTP **не** поддерживают (только Xray) — важно для автовыбора движка: [habr.com/en/articles/990208](https://habr.com/en/articles/990208/)
- mihomo 2025: **ECH** в слушателях VLESS/VMess/TUIC/Hysteria2, XPaddingBytes в xHTTP (настраиваемые паддинги), новые протоколы **AnyTLS** (лёгкий TCP+TLS прокси, есть и в sing-box): [deepwiki.com/xinebf/mihomo/3.2-advanced-protocol-inbound-listeners-(vmess-vless-shadowsocks-trojan-tuic-hysteria2-anytls-mieru-sudoku)](https://deepwiki.com/xinebf/mihomo/3.2-advanced-protocol-inbound-listeners-(vmess-vless-shadowsocks-trojan-tuic-hysteria2-anytls-mieru-sudoku)
- **nDPI 5.0** (релиз ~дек. 2025): единый отпечаток (TCP-метаданные + хеш сертификата + **JA4**), улучшенный First Packet Classification — DPI классифицирует по первому пакету: [prohoster.info/en/blog/novosti-interneta/vypusk-sistemy-glubokogo-inspektirovaniya-paketov-ndpi-5-0](https://prohoster.info/en/blog/novosti-interneta/vypusk-sistemy-glubokogo-inspektirovaniya-paketov-ndpi-5-0)
- Постквантовый TLS (mlkem768x25519, по умолчанию в Firefox 145) меняет отпечатки ClientHello — окно возможностей, пока DPI переучивается: [prohoster.info/en/blog/news/reliz-firefox-145-s-rasshirennoj-zashhitoj-ot-skrytoj-identifikaczii](https://prohoster.info/en/blog/news/reliz-firefox-145-s-rasshirennoj-zashhitoj-ot-skrytoj-identifikaczii)

### 1.5. Новое в инструментах
- **SpoofDPI**: режимы фрагментации SNI/first-byte/chunk/random + `disorder` (низкий TTL) + fake-пакеты; прокси/ SOCKS5/TUN-режимы: [deepwiki.com/xvzc/spoofdpi/4-core-components](https://deepwiki.com/xvzc/spoofdpi/4-core-components)
- **BlindDPI** (сен. 2026, Rust+NFQUEUE): рабочий подход против DPI с полной реассемблей — модификация TCP seq + junk-данные в первый пакет; наивный split и TTL-трюки уже не проходят: [vibingtalk.com](https://vibingtalk.com/index.php?threads/built-an-anti-dpi-traffic-obfuscator-in-rust-using-nfqueue.1577936/)
- **FrainTX/zapret («Просвет»)**: автоподбор рецепта по группам трафика + селекция стратегий (скрещивание/мутации), генерация фейков для любого имени (TLS ClientHello Chrome, QUIC Initial по RFC 9001), автообновления с подписью: [github.com/FrainTX/zapret](https://github.com/FrainTX/zapret)
- Тренд на 2026 (bypasscore): ECH делает SNI-блокировку невозможной без MITM; QUIC-всеприсутствие убивает TCP-only инструменты; AI-DPI смещает фокус от пакетных трюков к трансформации протоколов: [bypasscore.com/blog/goodbye-dpi-alternative-netveil](https://bypasscore.com/blog/goodbye-dpi-alternative-netveil)

## 2. Что sora должен перенять

| # | Мера | Почему | Эффект |
|---|------|--------|--------|
| 1 | Мигрировать bypass с **tpws на nfqws** (Linux; winws — задел на Windows) | tpws — legacy userspace, TCP-only, без fake/multisplit/QUIC. nfqws = полный набор 2026: fake+split2, disorder2, multisplit, syndata, wssize, autottl, UDP/QUIC-десинх. Вся живая разработка — там | **high** |
| 2 | UDP/QUIC-десинхронизация (`--filter-udp=443 --dpi-desync=fake --repeats=6`) | TSPU и GFW душат YouTube/Discord именно по QUIC 443; сейчас у sora для UDP ничего нет | **high** |
| 3 | Цепочки стратегий + fake-пакеты с TTL/autottl и fooling (md5sig/badseq) | Рабочий рецепт 2026 для ТСПУ — `fake,split2 … fooling=md5sig autottl=2`, а не plain split; одиночный split уже перебирается DPI с реассемблей | **high** |
| 4 | Авто-подбор стратегии под ISP (аналог blockcheck) | Roadmap §3 №2 уже планирует авто-тюнинг — исследование подтверждает: готовые рецепты не универсальны, перебор по провайдеру обязателен | **high** |
| 5 | QUIC SNI slicing из коробочных версий движков (Xray ≥25.6.8, sing-box ≥1.12, Hysteria ≥2.6.2) | Дефолтная защита против SNI-инспекции QUIC; sora на этих движках получает её бесплатно — следить за версиями | **medium** |
| 6 | ECH на клиентской стороне (и в one-click серверном деплое) | ECH убирает основной вектор — SNI; GFW не блокирует QUIC+ ECH; Cloudflare уже массово поддерживает | **medium** |
| 7 | AnyTLS как протокол в движке | Лёгкий TCP+TLS прокси 2025 г. (sing-box/mihomo); запасной транспорт, когда VLESS/VMess засигнатурены | **medium** |
| 8 | XHTTP packet-up/stream-up + правило «XHTTP только на Xray» в автовыборе | Раздельные up/down-соединения ломают TLS-inside-TLS анализ; sing-box XHTTP не умеет — автовыбор движка должен это знать (сейчас мультидвижок есть, такого правила нет) | **medium** |
| 9 | Stealth-оценка конфигурации (JA4/uTLS/размер пакетов vs эталоны браузеров) | nDPI 5.0 классифицирует по первому пакету и JA4; roadmap §3 №13 уже предлагает stealth-score — исследование подтверждает актуальность | **medium** |
| 10 | Детектор троттлинга по паттерну (roadmap §3 №3) → переключение на QUIC+XHTTP/padding при срабатывании | TSPU-2026 режет канал mid-stream по паттерну; пакетные трюки бессильны — только смена транспорта до того, как заметил пользователь | **medium** |
| 11 | uTLS-отпечатки с PQ-kem (mlkem768x25519) | Firefox/Chrome уже шлют PQ key exchange; отпечаток без него = аномалия для ML-DPI | **low** |

## 3. Вывод
Главный разрыв sora — **tpws вместо nfqws**: бессерверный обход есть (это уникально), но на устаревшем бэкенде без UDP/QUIC и без современных цепочек fake+split. Второй разрыв — **нет авто-подбора под ISP** (у blockcheck и форка «Просвет» уже есть, у sora в планах). Тренд 2026: от «хитрых пакетов» к мимикрии протоколов (ECH, XHTTP split-up/down, QUIC slicing) и к ML-устойчивости — это должно лечь в roadmap как P1 после миграции на nfqws.
