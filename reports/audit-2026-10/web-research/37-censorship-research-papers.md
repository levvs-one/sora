# Научные работы по обходу цензуры 2025–2026 — ресёрч для sora

Дата: 2026-10-19. Ресёрчер #37. Метод: 5 поисковых запросов, приоритет источникам FOCI/USENIX Security/NDSS/PETS 2025–2026.

## 1. Что нашёл

### 1.1. UPGen — Censorship Evasion with Unidentified Protocol Generation (USENIX Security 2025)
- **Суть:** генерация новых протоколов шифрованной связи, которые не распознаются как «протоколы обхода», а выглядят как некий неизвестный доброкачественный шифрованный протокол. Каждый прокси может работать на своём сгенерированном протоколе.
- **Ключевой аргумент:** цензор не может заблокировать «все неопознанные протоколы», не нанеся колоссальный побочный ущерб — блокировка по ML-классификаторам неотличима от блокировки существующих шифрованных протоколов.
- **Результат:** производительность на уровне или выше обычных circumvention-протоколов; блокировка без collateral damage невозможна.
- Авторы: Ryan Wails, Rob Jansen, Aaron Johnson (NRL), Micah Sherr (Georgetown).
- https://www.usenix.org/conference/usenixsecurity25/presentation/wails

### 1.2. The Discriminative Power of Cross-layer RTTs in Fingerprinting Proxy Traffic (NDSS 2025)
- **Суть:** фундаментальный, протокольно-независимый отпечаток прокси-трафика — рассинхронизация транспортного и прикладного слоёв (client↔proxy и proxy↔server = разные RTT). Цензор детектирует прокси по разнице RTT между слоями.
- **Масштаб:** оценка на контролируемых стендах и реальном трафике партнёрского ISP; 80% топ-5000 сайтов давали детектируемый отпечаток при использовании обфусцированного прокси.
- **Контрмеры из работы:** задержка ACK до 500 мс; мультиплексирование (создаёт неопределённость тайминга). Долгосрочно — реалистичная имитация тайминга «нормального» трафика (открытая исследовательская проблема).
- Авторы: Diwen Xue, Robert Stanley, Piyush Kumar, Roya Ensafi (U. Michigan). DOI: 10.14722/ndss.2025.240966
- https://www.ndss-symposium.org/ndss-paper/ (pdf: www.ndss-symposium.org/wp-content/uploads/2025-966-paper.pdf)

### 1.3. Wallbleed: A Memory Disclosure Vulnerability in the Great Firewall of China (NDSS 2025)
- **Суть:** buffer over-read в DNS-инжекторе GFW: специально crafted DNS-запрос заставлял middlebox отдавать до 125 байт своей памяти. Два года лонгитюдных измерений (окт. 2021 → мар. 2024), reverse-engineering парсера инжектора, архитектурные инсайты (Linux, x86_64, ASLR, load-balancing).
- **Для нас:** не техника обхода, а доказательство того, что DNS-слой — поле боя; любой plaintext-DNS в клиенте — источник утечек и детекта. Подтверждает приоритет зашифрованного DNS (DoH/DoT) и того, что клиент не должен слать лишних резолвов.
- Авторы: Shencha Fan et al. (CU Boulder, UMass, Shinonome Lab, GFW Report).
- https://censorbib.nymity.ch/pdf/Fan2025a.pdf

### 1.4. Huma: Censorship Circumvention via Web Protocol Tunneling with Deferred Traffic Replacement (NDSS 2026)
- **Суть:** новый инструмент web protocol tunneling. Отложенная подмена трафика: участвующий сайт сначала отвечает немодифицированным контентом, а ответ с covert-данными готовится в фоне и отдаётся при следующем запросе клиента — убирает тайминг-аномалии, облегчающие fingerprinting. Плюс overt user simulator, моделирующий реалистичное поведение пользователя в браузере.
- **Важно:** защита от связывания конечных точек коммуникации сайтом противника (intranet-сценарии).
- Авторы: Sina Kamali, Diogo Barradas (U. Waterloo). Принята в NDSS'26.
- https://cs.uwaterloo.ca/~s4kamali/publications/huma/

### 1.5. On Russia's Early Introduction of QUIC SNI Censorship (FOCI 2026)
- **Суть:** Россия расшифровывает QUIC Initial packets, извлекает SNI из вложенного TLS ClientHello и дропает пакеты по блоклисту — 2644 домена, поведение идентично TLS-цензуре; блоклисты TLS и QUIC совпадают.
- **Измерения:** 3 российских vantage points, март–апрель 2026; цензура происходит между 3-м и 4-м хопом (ТСПУ на стороне ISP).
- https://jonsnowwhite.de/files/foci_26_russia.pdf

### 1.6. OpenVPN is Open to VPN Fingerprinting (USENIX Security; arXiv 2403.03998)
- **Суть:** двухфазная атака (пассивный fingerprint по byte patterns/размерам пакетов/ответам сервера + активное probing). На трафике реального ISP (Merit, ~1 млн пользователей) — точность 85%. 8 из 10 топ VPN-провайдеров помечены как подозрительные; XOR-обфускация 4 из топ-5 легко фингерпринтится.
- **Рекомендации авторов:** случайный паддинг вместо статичного; разделение obfuscation-серверов и OpenVPN-инстансов по IP; в долгую — стандартные Pluggable Transports и прозрачность техник обфускации.
- https://arxiv.org/html/2403.03998v1

### 1.7. "How Afraid Should You Be of VPN Traffic Identification?" (TMA 2025)
- **Суть:** сравнение туннельных протоколов 7 популярных VPN (Nord, Express, Proton, Vypr, Windscribe, Perfect Privacy, Cloudflare WARP): OpenVPN легко фингерпринтится; WireGuard — узнаваемые паттерны в handshake-пакетах; TLS 1.3/SSH-VPN блокировать сложно без collateral damage (IPSec вообще ломает VoLTE/корпсети — цензоры осторожны).
- **Контрмеры:** маскировка под веб-трафик (модификация метаданных TLS handshake), размазывание паттернов по размерам пакетов, dummy/malformed-пакеты как шум; новый метод для OpenVPN — per-session крипто-handshake, скрывающий идентификаторы без потери масштабируемости.
- https://pulse-wp.internetsociety.org/ (тег tls, обзор доклада TMA 2025)

### 1.8. On Precisely Detecting Censorship Circumvention in Real-World Networks (NDSS 2024/25)
- **Суть:** Wails et al. показывают, что flow-based ML-детекторы дают >94% false positives, но комбинация deep-learning классификатора потоков + host-based детекции (агрегация по хосту во времени) на 60M реальных потоков даёт perfect recall с нулевыми false positives при любом base rate.
- **Вывод для дизайна:** будущие circumvention-системы должны учитывать host-based детекцию цензора (не только flow-level обфускацию).
- Авторы: Ryan Wails, George Arnold Sullivan, Micah Sherr, Rob Jansen.
- https://www.ndss-symposium.org/ndss-paper/on-precisely-detecting-censorship-circumvention-in-real-world-networks/

### 1.9. Snowflake: system paper (USENIX Security 2024)
- **Суть:** ретроспектива Snowflake — эфемерные WebRTC-прокси, динамический rendezvous, бесшовное переключение при отвале прокси; уроки развёртывания (Россия 2021, Иран 2022) и попыток блокировки.
- Для нас: модель «дешёвых одноразовых проксей, устойчивых к перечислению» — референс для дизайна резервных каналов.
- https://www.usenix.org/conference/usenixsecurity24/presentation/bocovich

### 1.10. CensorLess: Cost-Efficient Censorship Circumvention Through Serverless Cloud Functions (GFW Report / PETS 26b)
- **Суть:** обход через serverless cloud functions — инфраструктура провайдера как прокси, сложная для блокировки по IP (shared cloud IP space = высокий collateral damage).
- https://gfw.report/publications/pets26b/en/

### 1.11. Контекст угроз (не paper, но важно для приоритетов)
- Россия: проект бюджета 2027–2029 удваивает расходы на систему блокировок АСБИ — 19.87 млрд ₽/год, цель — блокировать 92% VPN к 2030; готовится whitelisting-режим (весь трафик блокируется по умолчанию).
  https://vpnlab.io/en/russia-doubles-internet-blocking-vpn-budget-2026-2619
- Методика shutdown.fyi (dev.to/shutdownfyi): диагностика цензуры по 4 шагам DNS→TCP→TLS→HTTP с двух vantage points — готовый шаблон для самодиагностики в клиенте.
  https://dev.to/shutdownfyi/telling-censorship-from-outages-probing-russias-internet-from-both-sides-of-the-border-3c28

---

## 2. Что sora должен перенять и почему (по приоритету)

| # | Что перенять | Из чего | Почему | Эффект |
|---|---|---|---|---|
| 1 | **Случайный паддинг и рандомизация размеров пакетов как дефолт**, а не фиксированная фрагментация | §1.6, §1.7 | OpenVPN-исследование: статический паддинг/XOR фингерпринтится; рандомизация размеров — рекомендованная краткосрочная защита. У sora уже есть фрагментация TLS — сделать её stochastic по умолчанию | high |
| 2 | **Мимикрия вместо «шифровать сильнее»**: приоритет REALITY/XHTTP, реалистичные паттерны браузинга | §1.4, §1.7, вывод gist 2026 | Консенсус 2025–2026: прячутся не шифрованием, а неразличимостью от легитимного трафика, который цензор не может заблокировать. Huma показывает следующий шаг — user simulator | high |
| 3 | **Тайминг-гигиена**: мультиплексирование по умолчанию + сглаживание RTT-сигнатуры | §1.2 | Cross-layer RTT — протокольно-независимый детектор, бьёт по любым обфусцированным прокси. Мультиплексирование (уже есть XHTTP/smux) снижает риск; стоит добавить измерение собственной RTT-дискрепансии в диагностику | high |
| 4 | **ECH + камуфляж SNI для QUIC** (Hysteria2/TUIC) | §1.5 | Россия с 2025–2026 расшифровывает QUIC Initial и фильтрует по SNI. QUIC-транспорты без ECH/маскировки SNI — лёгкая мишень в главном рынке sora | high |
| 5 | **Host-based детекция в threat model**: ротация endpoints, распределение трафика по нескольким хостам | §1.8 | Цензор агрегирует по хосту во времени и достигает perfect recall. Ответ — proxy chains (F8 уже в работе), ротация серверов, избегание «один IP = один долгоживущий туннель» | medium |
| 6 | **Самодиагностика цензуры по методике shutdown.fyi** (DNS→TCP→TLS→HTTP, сравнение) | §1.11 | Позволит клиенту самому определять, на каком слое режут, и автоматически переключать протокол/транспорт. Уникальная фича, ни у кого из конкурентов нет | medium |
| 7 | **Архитектура pluggable transports** (через расширения, F10) | §1.6, §1.10 | Авторы OpenVPN-работы прямо призывают к стандартизированным обфускационным транспортам. У sora есть задел (extensions MVP + 3 движка) — оформить транспортный слой как сменный | medium |
| 8 | **Per-session рандомизация handshake** (идея из TMA 2025) | §1.7 | Долгосрочный ответ на fingerprinting handshake'ов (WireGuard-паттерны и т.п.). Исследовать для собственных/расширяемых транспортов | medium |
| 9 | **Зашифрованный DNS без исключений + минимум резолвов** | §1.3 | Wallbleed напоминает: DNS-слой — инструмент цензора. DNS-менеджер (F3) уже запланирован — держать DoH/DoT дефолтом, логировать попытки plaintext-fallback как инцидент | low |
| 10 | **Постоянный research-watch**: censorbib.nymity.ch + gfw.report/publications | все | Поле меняется за месяцы; нужен процесс мониторинга, а не разовый ресёрч. Добавить в AGENTS.md/GOAL.md квартальный пересмотр | low |

## 3. Чего НЕ делать (выводы из тех же работ)
- Не полагаться на «неопознанный шифрованный трафик» как защиту: NDSS 2025 показывает детект по таймингу независимо от протокола; UPGen — это про генерацию разнообразия протоколов, а не про «просто шифруй».
- Не использовать статичную обфускацию (XOR, фикс. паддинг) — фингерпринтится (8/10 топ-провайдеров помечены).
- Не держать долгоживущие соединения к одному IP — host-based детекция (§1.8) именно это и ловит.
