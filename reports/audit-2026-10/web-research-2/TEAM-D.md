# TEAM-D: второй проход веб-разведки — новые техники 2025–2026

Дата: 2026-10-20. Команда: 10 тем, копали до первоисточников (RFC, научные работы, исходники, блоги операторов).
Первый проход — `~/workspace/bug-hunt/reports/WEB-RESEARCH.md` (+ `web-research/NN-*.md`). Здесь — только то, чего там нет или что там недокопано.
Фильтр владельца: только механика с доказательствами, каждый вердикт — с источниками. Слоп отсечён явно.

## Сводка вердиктов

| # | Тема | Вердикт |
|---|---|---|
| 1 | Encrypted DNS 2026 | DoH3-first подтвердить; добавить DDR-детект (не в ценз. сетях); h-root DoQ — watch |
| 2 | QUIC v2 (RFC 9369) | Ничего не делать; v2 почти не развёрнут, фич не даёт |
| 3 | Happy Eyeballs v3 | Внедрять принципы (рейсинг транспортов, SVCB-hints), не драфт дословно |
| 4 | Censorship measurement | CensorAlert + Tor vantage-pattern в модуль censorship intelligence; BLACKOUT — watch |
| 5 | SVCB/HTTPS для обхода | Резолвить HTTPS-записи (ECH/hints) для прокси-доменов; DDR — только в доверенных сетях |
| 6 | WARP/MASQUE уроки | Брать Auto+fallback и мультиплексирование; домен MASQUE-сервера — блокируемый вектор |
| 7 | WireGuard kernel 2026 | Нового в протоколе нет; GotaTun прошёл аудит — поднять приоритет watch |
| 8 | PQ в TLS 2026 | RFC 10024 закрыл вопрос; X25519MLKEM768 на свои origins; ML-DSA — ждать |
| 9 | QUIC SNI DPI | Держать движки свежими (slicing бесплатно); pre-Initial dummy + high-port для QUIC-транспортов |
| 10 | Padding/мимикрия | DAITA как референс механики; Maybenot для экспериментов; оценивать cross-network |

---

## 1. Encrypted DNS 2026: новое сверх первого прохода

Первый проход (29-doh3-doq.md) закрыл: DoH3/DoQ-матрицу резолверов, поддержку в sing-box, DoH3-first стратегию. Новое:

- **h-root — экспериментальный DoQ с апреля 2026.** Первый root-оператор с DoQ-тестом ([webpronews, ~08.2026](https://www.webpronews.com/dns-over-quic-gains-traction-as-quad9-and-root-servers-test-a-faster-encrypted-alternative/)). Сигнал: шифрование докатывается до recursive→authoritative слоя.
- **ADoT/ADoX-статус (dnsprivacy.org, июль 2026):** ~25 неймсерверов и 65 зон отвечают на 853; Google — unilateral probing по RFC 9539 на ~6% egress-трафика; Quad9 включил тот же механизм в июле 2025 (PowerDNS Recursor). Источник: тот же webpronews-обзор.
- **Windows DNS Server: DoH в GA с июня 2026** (KB5094125, Windows Server 2025) — шифрованный DNS становится enterprise-дефолтом, а не экзотикой (тот же обзор).
- **Замеры Internet Society Pulse (окт 2026), Индия, 28 резолверов / 13 ASN / 18 ISP:** DoH — 71.4%, DoQ — 46.4%, DoH/3 — всего 7.1%. Cold-start (Airtel): DoH 243 мс / DoQ 178 мс / DoH3 145 мс. Steady-state разница мала (Jio 79–83 мс у всех). Вывод: выигрыш QUIC — в установке соединения, не в установившемся режиме ([pulse.internetsociety.org](https://pulse.internetsociety.org/en/blog/2026/10/what-we-learned-about-encrypted-dns-on-indias-networks/)).
- **DDR (RFC 9462) + DNR (RFC 9463) — структурный тренд:** клиент сам находит шифрованные эндпоинты своего сетевого резолвера через SVCB `_dns.resolver.arpa`. Деплой измерен (RIPE Labs; пример: 1.1.1.1 отдаёт DoH alpn=h2,h3 + DoT) ([labs.ripe.net](https://labs.ripe.net/author/yevheniya-nosyk/discovering-the-discovery-of-designated-resolvers/), [aicassindra.com, DNS in 2026](https://www.aicassindra.com/blogs/networking/dns_in_2026.html)).
- **Oblivious DNS over QUIC (ODoQ):** arXiv-препринт конца 2025 — прокси-слой, прячущий identity клиента от резолвера (упомянут в webpronews-обзоре). Пока исследование, не деплой.
- Новых глобальных публичных резолверов 2025–2026 не найдено — рост идёт в поддержке протоколов у существующих, не в новых именах. Честно фиксирую.

**Вердикт.** DoH3-first стратегия первого прохода подтверждается свежими замерами (худший cold-start у DoH-over-TCP, лучший у DoH3). Новое к внедрению: (a) DDR-детект в DNS-менеджер — авто-апгрейд сетевого резолвера там, где сеть доверенная; **в цензурируемых сетях DDR к резолверу провайдера вреден** (шифруешься к цензору) — дефолт остаётся на публичных резолверах; (b) h-root DoQ и ADoT — watch, не действие. Слоп-фильтр: «свой резолвер sora» — по-прежнему нет (R6 первого прохода в силе).

## 2. QUIC v2 (RFC 9369): статус 2026 и влияние на VPN-клиенты

- **Развёртывания почти нет.** Слайды IETF 126 «Telemetry on HTTPS RR and QUIC v2 adoption»: «QUIC ossification: v2 is barely deployed»; телеметрия Firefox Nightly — v2 ~0% QUIC-хендшейков; измерения IMC 2024 — v2 на <0.003% QUICv1-доменов ([datatracker, слайды 126](https://datatracker.ietf.org/meeting/126/materials/slides-126-quic-telemetry-on-https-rr-and-quic-v2-adoption-00)).
- **Свежее движение:** Firefox Nightly включил compatible version negotiation (RFC 9368/9369) — bug 2040450, milestone 154 (~авг 2026): «first time QUIC v2 is used in the wild by Firefox», замер negotiated version через Glean, rollout на Beta/Release после обкатки ([bugzilla 2040450](https://bugzilla.mozilla.org/show_bug.cgi?id=2040450)).
- **Что это технически:** v2 функционально идентичен v1 — отличаются только соли, лейблы и кодпоинты (анти-оссификация, упражнение version negotiation). ALPN `h3` и `doq` работают и на v2. Security consideration из RFC: поддержка v2 помогает наблюдателю фингерпринтить клиент и сервер ([RFC 9369](https://www.rfc-editor.org/rfc/rfc9369.xml)). Multipath QUIC — по-прежнему Internet-Draft, не путать с v2 (на середину 2026).

**Вердикт.** Для VPN-клиента действий не требуется. v2 не даёт новых возможностей — это grease-механизм; поддержка наследуется от QUIC-стека движков автоматически; форсировать v2 не нужно и вредно для фингерпринт-стойкости (редкая версия = выделимый клиент). Следить за итогами Firefox-измерений. Слоп-фильтр: «поддержка QUIC v2» как фича/маркетинг — слоп.

## 3. Happy Eyeballs v3 / QUIC-aware Happy Eyeballs

- **Статус:** отдельная WG `happy`, `draft-ietf-happy-happyeyeballs-v3-02` (окт 2025; milestone на standards-track — июль 2026). Отдельного «QUIC-aware HE» драфта нет — QUIC влит в HEv3 ([datatracker](https://datatracker.ietf.org/doc/html/draft-ietf-happy-happyeyeballs-v3-02), [WG happy](https://dataTracker.ietf.org/wg/happy/about/)).
- **Что нового в алгоритме:** порядок DNS-запросов SVCB/HTTPS → AAAA → A; Resolution Delay 50 мс (рекоменд.); предпочтение QUIC над TCP; **рейсинг через полный хендшейк, включая TLS/QUIC** (не только TCP-connect); address hints из SVCB (`ipv4hint`/`ipv6hint`) считаются positive answers; сортировка адресов + асинхронные попытки с отменой проигравших.
- **Firefox уже шипает** (слайды IETF 126): `mozilla/happyeyeballs` — детерминированный sans-I/O state machine; attempt delay 50 мс base ×2 backoff (50/150/350/750), resolution delay 25 мс (подтюнено по телеметрии), interleave protocol variant с address family (QUIC достигается рано), optimistic DNS. В планах — **proxy awareness: MASQUE connect-udp vs HTTP CONNECT ordering**, WebSocket/WebTransport EXTENDED CONNECT ([слайды 126](https://datatracker.ietf.org/meeting/126/materials/slides-126-happy-update-on-firefox-implementation-00)).

**Вердикт.** Внедрять принципы, не драфт дословно. Для sora это три конкретные вещи: (1) **рейсинг транспортов при подключении** — гнать параллельно 2–3 кандидата (напр. VLESS/REALITY vs Hysteria2 vs MASQUE) вместо последовательного перебора; прямо ложится на auto-transport (TIER S #21) и OONI-риск-скор (TIER S #9): порядок по скору, гонка внутри тира; (2) SVCB/HTTPS-записи как источник hints для сортировки кандидатов (связка с темой 5); (3) задел на MASQUE-vs-CONNECT ordering, когда MASQUE будет в движках. Это измеримое ускорение коннекта в сетях с частичными блокировками, а не «ещё один таймаут». Следить за публикацией RFC.

## 4. Censorship measurement 2026: новое без OONI

Первый проход (38-ooni-censored-planet.md) закрыл OONI API и Censored Planet как bulk-источник. Новое:

- **CensorAlert (FOCI 2026, Zohaib, Sheffey, Wu, Houmansadr):** платформа, агрегирующая отчёты о цензуре LLM-агентами из measurement API, форумов, соцсетей, СМИ — классификация, перевод, скоринг, ranked feed и real-time алерты ([слайды](https://foci.community/slides/slides-2026-0002.pdf), censoralert.org). Мотивация — то, чего не хватает платформам: измерительные системы пропускают локальные/новые методы цензуры (примеры: детект GFW-блокировки fully-encrypted трафика из форумного поста; SNI-based QUIC-блокировку в Китае — из Telegram-поста). Прямое дополнение к OONI-агрегации: ловит свежее и локальное.
- **BLACKOUT (SCSP, 2026):** open-source платформа трекинга интернет-цензуры; кейс — блэкаут Ирана, январь 2026: сначала деградация целых категорий шифрованного трафика, затем 8 января почти полное отключение международного трафика. Вывод для threat model: цензура движется от блокировок сервисов к отключению связности — circumvention не роутит вокруг несуществующего соединения ([scsp222.substack.com](https://scsp222.substack.com/p/the-next-generation-technology-stack)).
- **Tor (дек 2025):** in-region vantage-point system внутри Ирана + автоматический тестер domain-fronting конфигураций для Snowflake broker и Moat — измеряет, какие front-домены лучше работают по локациям, и выбирает конфигурации ([forum.torproject.org](https://forum.torproject.org/t/staying-ahead-of-censors-in-2025-what-weve-learned-from-fighting-censorship-in-iran-and-russia/20898)). Референс-паттерн для собственных канареек sora.
- **GFWatch (Citizen Lab):** лонгитюдный замер DNS-цензуры GFW извне Китая (в пике 534M доменов, ~411M/день): UDP-запросы к контролируемым хостам в CN, GFW инжектит поддельные ответы независимо от направления запроса ([citizenlab.ca](https://googlier.com/forward.php?url=https://citizenlab.ca/2021/11/gfwatch-a-longitudinal-measurement-platform-built-to-monitor-chinas-dns-censorship-at-scale/)). Методология жива и воспроизводима.
- Takedown Observer (март 2025, internet Research Lab): детект геоблокировок контента в соцсетях через браузерное расширение ([irl.works](https://irl.works/blog/2025/03/06/takedown-observer-announcement.html)) — уровень контента, не сети; для VPN-клиента нерелевантно, фиксирую чтобы не копали.

**Вердикт.** В модуль censorship intelligence (TIER S #9): (a) CensorAlert-лента как источник свежих инцидентов поверх OONI-агрегации (то, что пропускают платформы); (b) Tor-паттерн in-region авто-тестера — референс для канареек sora (авто-тест транспортов/front-доменов по локациям уже заложен в Strategy Tuner, TIER S #14); (c) BLACKOUT — watch. Отправку измерений из клиента не встраивать (те же риски, что R5 у OONI: consent и безопасность пользователей).

## 5. DNS SVCB/HTTPS-записи: использование для обхода

Первый проход касался ECH отдельно (27-ech-status.md). Здесь — SVCB/HTTPS как механизм обхода:

- **ECH через HTTPS-записи — главный доказанный механизм.** ECH стандартизирован (RFC 9849), `ech`-параметр — в RFC 9848. `draft-ietf-tls-svcb-ech`: ECH-клиент НЕ ДОЛЖЕН слать ClientHello до завершения SVCB-резолва; смешанный RRSet (часть записей с `ech`, часть без) уязвим к даунгрейду — цензор блокирует ECH-эндпоинты, клиент падает на не-ECH (конфигурация NOT RECOMMENDED) ([datatracker](https://datatracker.ietf.org/doc/draft-ietf-tls-svcb-ech/08/)).
- **Практики обхода через параметры записей:** `ipv4hint`/`ipv6hint` — получить IP, минуя отравленный A-запрос (обход DNS-poisoning без полного DoH); `alpn=h3` — сразу QUIC без TCP-пробы (меньше сигналов); ECH-конфиг из записи — убрать SNI-вектор до первого пакета ([aicassindra.com](https://www.aicassindra.com/blogs/networking/dns_in_2026.html)).
- **DDR/DNR (RFC 9462/9463):** `_dns.resolver.arpa` SVCB → клиент апгрейдит свой сетевой резолвер до шифрованного, сертификат валидируется по IP. Двойной край: в benign-сети — приватность без смены резолвера; в цензурируемой — шифрование к резолверу цензора ([labs.ripe.net](https://labs.ripe.net/author/yevheniya-nosyk/discovering-the-discovery-of-designated-resolvers/)).
- **Поведение цензоров:** GFW на янв 2025 не блочил QUIC+ECH (кроме outer SNI из блоклиста), браузеры шлют dummy ECH — см. тему 9; контрпример — Узбекистан, дек 2024: блочил QUIC-соединения с ECH-расширением (gfw.report, тема 9).

**Вердикт.** (1) Резолвить HTTPS-записи для прокси-доменов в движке выбора транспорта: ECH-конфиги + address hints + alpn — дешёво, стандартно, даёт и приватность SNI, и обход отравления; (2) DDR — только для доверенных сетей (связка с trusted networks, TIER S #13), в цензурируемых дефолт — публичные резолверы; (3) в диагностику — детект «HTTPS-запись с ech есть, но соединение даунгрейдится до не-ECH» как сигнал активного цензора. Слоп-фильтр: «SVCB-обход» как отдельный протокол/фича — слоп; это discovery-механизм, не транспорт.

## 6. WARP/MASQUE: уроки продакшн-развёртывания Cloudflare

Первый проход (28-masque-adoption.md) зафиксировал факт перехода WARP на MASQUE. Здесь — технические детали из блога и чейнджлогов 2025:

- **Архитектура (пост 27.12.2024, первоисточник):** CONNECT-IP (`:protocol = connect-ip`, `:path = /.well-known/masque/ip/*/*/`, `capsule-protocol`), мультиплексирование множества конкурентных запросов в одном QUIC-соединении, QUIC unreliable datagrams (RFC 9221). Аргументы Cloudflare: MASQUE «more like normal HTTP traffic» → совместимость с существующими firewall-правилами; cryptographic agility (постквант). Селектор протокола в клиенте: Auto / MASQUE / WireGuard (`warp-cli tunnel protocol set`) ([blog.cloudflare.com](https://blog.cloudflare.com/masque-now-powers-1-1-1-1-and-warp-apps-dex-available-with-remote-captures/)).
- **2025, чейнджлоги:** MASQUE — дефолт для всех новых WARP device profiles (июль 2025); MASQUE — единственный протокол для Proxy mode (сен 2025); PQ end-to-end в WARP-клиенте (2025.5, май 2025, включается через MDM); цель — PQ для MASQUE-соединения к середине 2025 ([community.cloudflare.com](https://community.cloudflare.com/t/zero-trust-warp-client-warp-client-for-windows-version-2025-7-106-1/835808)). Доки: весь трафик в MASQUE-туннеле шифруется постквантовой криптографией ([developers.cloudflare.com](https://developers.cloudflare.com/warp-client/warp-modes/)).
- **Детали надёжности из тех же чейнджлогов:** keep TCP alive при первом коннекте (RDP/SSH не рвутся), captive portal improvements, graceful handling MDM-изменений — класс «невидимых» доработок, отличающих прод от демо.
- **Честная оговорка из USENIX Security 2025 (тема 9):** GFW таргетит MASQUE-субдомен WARP (ломали startup handshake) и кастомные Hysteria-домены — SNI/домен сервера остаётся блокируемым вектором даже для QUIC-прокси.

**Вердикт.** Уроки для sora: (1) паттерн Auto-протокол с fallback — брать для auto-transport (TIER S #21); (2) мультиплексирование всего в одном QUIC-соединении — архитектурный аргумент за MASQUE как транспорт (меньше хендшейков = меньше SNI-сигналов); (3) CONNECT-IP поверх стандартного HTTP — совместимость с корпоративными фаерволами (кейс «лёгкого режима» из первого прохода); (4) честно: домен MASQUE-сервера — блокируемый вектор (кейс WARP), маскировка ≠ невидимость. Слоп-фильтр: «MASQUE невидим для DPI» — слоп, опровергнут измерениями.

## 7. WireGuard kernel 2026: что нового

Первый проход (48-wireguard-kernel-userspace.md) закрыл иерархию kernel/userspace, GotaTun-анонс, инцидент с подписью wireguard-nt, multi-queue TUN. Новое:

- **В самом протоколе/ядре нового нет — и это by design.** Доненфельд сознательно отказался от crypto-agility; mainline-разработка 2025–2026 — эволюция (GSO, threaded NAPI, netlink-переработки, hardening), не новые фичи протокола ([pbxscience.com, сен 2026](https://pbxscience.com/why-the-linux-kernel-includes-wireguard-but-not-openvpn/)).
- **Главная новость userspace — GotaTun прошёл аудит.** Assured Security Consultants, 19.01–15.02.2026, GotaTun 0.2.0 (Rust-форк BoringTun от Mullvad): 0 critical/high/medium, 2 low + 9 notes; DAITA-код и CLI вне скоупа. Crash rate на Android: 0.40% → 0.01% после замены wireguard-go (роллаут с дек 2025, десктоп/iOS — в течение 2026) ([cyberinsider.com](https://cyberinsider.com/mullvads-new-gotatun-protocol-passes-first-independent-audit/), [mullvad.net](https://mullvad.net/en/blog/announcing-gotatun-the-future-of-wireguard-at-mullvad-vpn), [отчёт аудита](https://arietiform.com/application/nph-tsq.cgi/su/20/https/www.assured.se/publications/Assured_Mullvad_GotaTun_Code_Review_2026.pdf)). Рекомендации аудиторов: ближе к спецификации WireGuard (паддинг, генерация session id), упростить packet buffer.

**Вердикт.** Позиция первого прохода (kernel fast path на Linux + tuned userspace + watch GotaTun) в силе; апдейт: аудит пройден чисто → приоритет watch повышается до «кандидат на userspace-путь после стабилизации десктоп-роллаута Mullvad». Своего kernel-модуля по-прежнему не писать (нечего добавлять — протокол заморожен). Слоп-фильтр: DPDK/AF_XDP в клиенте — по-прежнему нет.

## 8. Постквантум в TLS 2026: статус ML-KEM, кто внедрил

Первый проход (49-postquantum-vpn.md) закрыл PQ в VPN-туннелях (Mullvad/ExpressVPN/Nord/Windscribe, PSK-паттерн), Go-TLS дефолт, Signal PQXDH/SPQR, OpenSSH. Новое — **черновики стали RFC**:

- **RFC 10024 (10 авг 2026, Proposed Standard):** три гибрида для TLS 1.3 — X25519MLKEM768 (0x11EC, Recommended Y), SecP256r1MLKEM768 (0x11EB, N), SecP384r1MLKEM1024 (0x11ED, N). Эволюция из `draft-ietf-tls-ecdhe-mlkem`; компаньон — RFC 9954 (июль 2026, Informational, общая hybrid-конструкция); ссылается на FIPS 203 и RFC 9846 (обновлённый TLS 1.3, июль 2026). Обсолетен X25519Kyber768Draft00 (0x6399 → Recommended D, discouraged) ([postquantum.com](https://postquantum.com/security-pqc/rfc-10024-hybrid-mlkem-tls/)).
- **Деплой:** Cloudflare, 30.04.2026 — >2/3 human TLS-трафика с hybrid PQ; Automatic Key Exchange (08.09.2026) — автопроб origins: ~33% сканируемых доменов с PQ-преференсом, >12% origins поддерживают PQ, 99.2% хендшейков без HelloRetryRequest. QUIC наследует TLS 1.3 KEX → HTTP/3 тоже PQ (тот же источник).
- **Рядом в очереди:** `draft-ietf-tls-mlkem` (standalone ML-KEM) — IESG approved 03.09.2026 → Informational RFC; `draft-ietf-tls-mldsa` — approved сен 2026 → Informational RFC; rustls 0.23.44 (07.09.2026) — ML-DSA verify by default. Но: ни один браузер не ведёт ML-DSA для серверных сертов по дефолту, публичных ML-DSA root нет; Chrome вместо X.509-PQ делает Merkle Tree Certificates (план до Q3 2027); Cloudflare: PQ-аутентификация — середина 2027, full PQ — 2029 ([postquantum.com](https://postquantum.com/security-pqc/rfc-10024-hybrid-mlkem-tls/), [qntonsol.com](https://www.qntonsol.com/learn/cloudflare-google-apple-pqc-rollout-2026.html)).
- **EO 14412 (22.06.2026):** федеральные дедлайны PQC — key establishment до 31.12.2030, signatures до 31.12.2031 (тот же postquantum.com).
- **Apple:** X25519MLKEM768 системно в iOS 26 / macOS Tahoe (Safari 26, весь стек) — новое 2026 ([qntonsol.com](https://www.qntonsol.com/learn/try-post-quantum-tls-today-openssl-browsers-cloudflare.html)). PQ3 (iMessage, 2024, гибрид Kyber-1024) — новых деталей 2025–2026 не найдено, честно фиксирую.
- **Signal / Mullvad:** новее первого прохода (PQXDH-дефолт май 2026, SPQR-роллаут; quantum-resistant tunnels default) не найдено; фокус Mullvad 2026 — GotaTun/DAITA (темы 7/10).

**Вердикт.** (1) Вывод первого прохода (X25519MLKEM768 обязателен в ClientHello «свежего» фингерпринта, TIER S #2) теперь опирается на RFC, а не драфт — обновить доки/комменты в коде; (2) серверная сторона sora (one-click деплой): включать X25519MLKEM768 на origins (OpenSSL 3.5+, Go 1.24+, rustls 0.23.27+ умеют) — иначе «свежий клиент к своему серверу без PQ» выглядит аномально для DPI; (3) ML-DSA-сертификаты — ждать WebPKI (2027–2029), не делать. Слоп-фильтр: «PQ-сертификаты сейчас», «quantum-VPN маркетинг» — нет.

## 9. Парсинг QUIC SNI цензорами (USENIX Security 2025 и последователи)

Первый проход упоминал факт одной строкой. Здесь — точная механика из первоисточника и проверенные контрмеры.

Работа: Zohaib, Zao, Sippe, Alaraj, Houmansadr, Durumeric, Wustrow — «Exposing and Circumventing SNI-based QUIC Censorship of the Great Firewall of China», USENIX Security 2025 ([gfw.report](https://gfw.report/publications/usenixsecurity25/en/)).

**Что умеет цензор (измерено, 7 vantage points в CN):**
- С 07.04.2024 GFW расшифровывает QUIC Initial в масштабе: ключ выводим из plaintext DCID + version-specific salt — любой пассивный наблюдатель может.
- Эвристики-оптимизации: игнор пакетов с `srcport ≤ dstport` («только клиентский трафик»); QUIC v1, порт 443.
- Отдельный QUIC-блоклист (~60% размера DNS-блоклиста; много доменов вообще без QUIC-поддержки).
- **Один** Initial с запрещённым SNI → дроп всего client→server UDP на 3-tuple (src IP, dst IP, dst port) на **180 секунд** — первый residual blocking для UDP-протокола. Смена srcport не помогает (дропаются даже 10-байтные random-пакеты на тот же dst IP:port); server→client не дропается. С 30.09.2024 inbound-триггер в основном убран (кроме Пекина/Гуанчжоу).
- Ограничение цензора: расшифровка дорогая → диурнальный паттерн (ночью блочит сильнее); умеренный флуд QUIC Initials (даже к незаблокированным доменам) роняет эффективность блокировки. Уязвимость disclosed в CERT Китая; авторы показывают weaponization — блокировка произвольного UDP между CN и миром одной spoofing-машиной.

**Контрмеры, проверенные в работе:**
1. `srcport ≤ dstport` — сервер на высоком порту (≥ эфемерного диапазона клиента); iptables REDIRECT-трюк `--dport 65535 -j REDIRECT --to-port 443`.
2. **Pre-QUIC dummy UDP datagram** перед Initial — ломает first-packet assumption; настоящий QUIC-сервер (проверено на Chromium Quiche) её игнорирует.
3. **Фрагментация Initial / SNI slicing** по нескольким UDP-датаграммам или CRYPTO-фреймам — GFW не реассемблит (на янв 2025). Chrome Chaos Protection (2021) и PQ key shares (Initial > MTU) случайно дают тот же эффект. В проде: Firefox 137 (neqo v0.12.0, 27.01.2025) slicing by default; quic-go v0.52.0 (23.05.2025) → sing-box 1.12.0-beta.17, V2Ray 5.33.0, Xray 25.6.8, Hysteria 2.6.2.
4. **ECH** — GFW не блочил QUIC+ECH на янв 2025 (кроме outer SNI из блоклиста); браузеры шлют dummy ECH.
5. Version negotiation trick — Initial с неизвестной версией undecryptable, затем хендшейк на поддерживаемой.
6. Connection migration после 1-RTT на другой 4-tuple (GFW не трекает CID); QUICstep — хендшейк по защищённому каналу, миграция на обычный.
7. Авторы: stopgap-решения против цензоров живут годами (бюрократия vs опенсорс).

**Последователи:** FOCI 2026 — Россия: расшифровка QUIC Initial, SNI-блоклист 2644 домена = TLS-блоклист, ТСПУ между 3-м и 4-м хопом (первый проход, 37-1.5); Узбекистан, дек 2024 — блок QUIC с ECH-расширением (gfw.report). Важно: GFW таргетит MASQUE-субдомен WARP и кастомные Hysteria-домены — SNI/домен остаётся вектором даже для QUIC-прокси.

**Вердикт.** (1) Держать движки свежими — SNI slicing получается бесплатно (quic-go ≥0.52.0); (2) для QUIC-транспортов (Hysteria2/TUIC/MASQUE) добавить опции **pre-Initial dummy packet** и **high-port дефолт** — дешёвые контрмеры с доказанной механикой; (3) ECH для QUIC-транспортов где поддерживается (с оговоркой про Узбекистан/ТСПУ); (4) в диагностику — паттерн «QUIC Initial дропается» (UDP 443 умирает на первом пакете) → авто-переключение на TCP-транспорт. Не делать: overwhelm-флуд как фичу клиента — это offensive-техника, не клиентская. Слоп-фильтр: «QUIC невидим для DPI» — слоп, опровергнут.

## 10. Stochastic padding / мимикрия трафика: свежие работы 2025–2026

Первый проход (37-1.1/1.2/1.4, 43) дал UPGen, cross-layer RTT, Huma и рекомендацию stochastic padding. Здесь — работы с доказанной механикой против ML-классификации:

- **Maybenot** (Witwer; Rust-фреймворк, arXiv tech report): probabilistic finite state machines для padding- **и** blocking-защит (блокировка пакетов = искусственная задержка). Наследник ограниченного Tor circuit padding framework; standalone-библиотека для экспериментов ([ethanwitwer.com](https://www.ethanwitwer.com/posts/maybenot-framework/)).
- **MSP (ICDF2C 2024 / Springer 2025):** zero-latency lightweight WF-защита для Tor — только паддинг, без добавления задержки. Ключевое измерение: защита без latency-цены ([Springer](https://link.springer.com/chapter/10.1007/978-3-031-89360-5_11)).
- **Prism (ACM):** защита от DNN-фингерпринтинга через adversarial examples **без** прекомьютед-базы и без полного трейса заранее; генерация учится по ходу потока; может работать на ретрансляторах (клиенту без GPU) ([citedrive](https://www.citedrive.com/en/discovery/defending-against-deep-learning-based-traffic-fingerprinting-attacks-with-adversarial-examples/)).
- **«Reality Check for Tor WF in the Open World» (arXiv 2603.07412, март 2026) — честный негативный результат:** классификаторы деградируют cross-network (train AU / test CA) и со временем (concept drift за месяц); RF (2023) и Holmes (2024) падают сильнее DF/Tik-Tok. Вывод: лабораторные 98% не переносятся в прод — любую защиту оценивать только cross-network + time gap.
- **Mullvad DAITA — продакшн-доказательство механики:** constant packet size padding + dummy traffic + timing randomization на entry-сервере (120+ серверов, 22 страны); цена — скорость и батарея (Gizmodo/Engadget 2026); quantum-resistant tunnels default ([gizmodo.com](https://gizmodo.com/best-vpn/mullvad-vpn), [engadget.com](https://www.engadget.com/cybersecurity/vpn/mullvad-vpn-review-near-total-privacy-with-a-few-sacrifices-130000056.html)).
- Контекст из первого прохода: DF держит >90% accuracy против WTF-PAD (random padding без constant-size пробивается); Walkie-Talkie держит DF на 49.7% — half-duplex mold сильнее наивного паддинга.

**Вердикт.** (1) DAITA — референс продакшн-механики для «режима штопор» sora: паддинг до константного размера + dummy на entry, с честной ценой (скорость/батарея) в UI; (2) Maybenot — взять как фреймворк для экспериментов и тюнинга стратегий паддинга (в т.ч. для Strategy Tuner, TIER S #14); (3) zero-latency паддинг (MSP-класс) — кандидат в дефолт: защита без latency-цены; (4) adversarial-подходы (Prism) — watch, не в прод; (5) любую ML-защиту оценивать по methodology Reality Check (cross-network + time gap), иначе цифры врут. Слоп-фильтр: «AI-антидетект» без измерений и рандомный паддинг без constant-size — слоп (пробивается DF).

---

## Что отсеяно фильтром (слоп)

- QUIC v2 как «фича» — grease без новых возможностей, развёртывания нет.
- «SVCB-обход» как отдельный протокол; DDR в цензурируемых сетях (шифрование к цензору).
- «MASQUE невидим для DPI» — GFW таргетит MASQUE-домены (WARP-кейс).
- PQ-сертификаты (ML-DSA) в 2026 — WebPKI не готов до 2027–2029.
- Overwhelm-флуд QUIC Initials как клиентская фича — offensive-техника.
- «AI-антидетект» без cross-network измерений; наивный random padding (DF: >90% против WTF-PAD).
- Takedown Observer — уровень контента соцсетей, не сети; для VPN-клиента нерелевантно.
- Новых глобальных публичных DNS-резолверов 2025–2026 не найдено — не выдумывать.
- По Apple PQ3 и Signal свежих деталей 2025–2026 не найдено — честно зафиксировано, не додумано.

## Источники (первоисточники и ключевые)

- RFC 9369 (QUIC v2); RFC 10024 (hybrid ML-KEM TLS 1.3, авг 2026); RFC 9954 (hybrid-конструкция); RFC 9846 (TLS 1.3 update); RFC 9462/9463 (DDR/DNR); draft-ietf-tls-svcb-ech-08; draft-ietf-happy-happyeyeballs-v3-02.
- USENIX Security 2025: Zohaib et al., QUIC SNI censorship — https://gfw.report/publications/usenixsecurity25/en/
- FOCI 2026: CensorAlert — https://foci.community/slides/slides-2026-0002.pdf
- Cloudflare blog 27.12.2024 (MASQUE) — https://blog.cloudflare.com/masque-now-powers-1-1-1-1-and-warp-apps-dex-available-with-remote-captures/
- postquantum.com: RFC 10024 — https://postquantum.com/security-pqc/rfc-10024-hybrid-mlkem-tls/
- Internet Society Pulse: encrypted DNS India — https://pulse.internetsociety.org/en/blog/2026/10/what-we-learned-about-encrypted-dns-on-indias-networks/
- RIPE Labs: DDR — https://labs.ripe.net/author/yevheniya-nosyk/discovering-the-discovery-of-designated-resolvers/
- aiCassindra: DNS in 2026 — https://www.aicassindra.com/blogs/networking/dns_in_2026.html
- webpronews: DoQ traction (h-root, ADoX) — https://www.webpronews.com/dns-over-quic-gains-traction-as-quad9-and-root-servers-test-a-faster-encrypted-alternative/
- Bugzilla 2040450 (Firefox QUIC v2); IETF 126 slides (QUIC v2 telemetry, HEv3 Firefox).
- Assured: GotaTun audit — https://arietiform.com/application/nph-tsq.cgi/su/20/https/www.assured.se/publications/Assured_Mullvad_GotaTun_Code_Review_2026.pdf
- Maybenot — https://www.ethanwitwer.com/posts/maybenot-framework/ ; arXiv 2603.07412 (Reality Check).
- Tor forum 2025 (vantage points) — https://forum.torproject.org/t/staying-ahead-of-censors-in-2025-what-weve-learned-from-fighting-censorship-in-iran-and-russia/20898
- Citizen Lab: GFWatch — https://citizenlab.ca/2021/11/gfwatch-a-longitudinal-measurement-platform-built-to-monitor-chinas-dns-censorship-at-scale/
