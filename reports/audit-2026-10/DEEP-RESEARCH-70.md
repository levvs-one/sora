# DEEP-RESEARCH-70: третий, самый глубокий проход

Дата: 2026-10-20. 70 узких тем, 7 групп × 10. Метод: первоисточники — RFC, научные статьи (CCS/USENIX/NDSS), исходный код Xray-core/sing-box/mihomo/hysteria/zapret/amneziawg-go, issue-трекеры, changelog'и, полевые измерения 2025–2026. Первый проход (WEB-RESEARCH.md, тиры 1–46) не дублируется: там «что делать», здесь — механика «до провода» и точное «внедрить так».

Отчёты по темам: `~/workspace/bug-hunt/reports/deep-research/01..70-*.md`. Сводки групп: `GROUP-A..G.md`. Репозитории только читались, код не менялся.

Фильтр слопа владельца применён ко всем 70: каждая находка с вердиктом «лучшее или слоп», слухи/маркетинг/anecdotal без подтверждения отсечены или помечены как требующие проверки. Неподтверждённое честно помечено — не выдано за факт.

---

## S-TIER — разрыв «работает / не работает»

### S1. Тикающие деприкации sing-box в рендере sora (баги, чинить сейчас)
Факты из официальных доков и changelog'ов:
- `core/engine/singbox/render.go:437` ставит `download_detour` у remote rule-set — deprecated в 1.14, **удаляется в 1.16** (замена: `http_clients` + `route.default_http_client`).
- `render.go:640` — `"stack": "mixed"` — deprecated в 1.15, **удаляется в 1.17** (на 1.16 требует `ENABLE_DEPRECATED_TUN_STACK=true`).
- `render.go:515-523` — DoH3 рендерится legacy-строкой `{"address":"h3://..."}` без `"type"`; legacy DNS-формат **удалён в 1.14** (sora пинит 1.14.2) — конфиг может не валидироваться.
- `independent_cache` deprecated, удаление в 1.16.
- Поправка к первому проходу: `mixed` = TCP через system-стек + UDP через gVisor (не «TCP на gVisor»). Страдает UDP-путь (QUIC, DNS, VoIP, игры).

**Внедрить так:** мигрировать все четыре места одним коммитом; убрать `"stack"` из рендера (удалить строку, не менять значение); пин sing-box ≥1.15; добавить `sing-box check -c` в CI на каждый рендер-шаблон; на Linux включить `multi_queue: true` и дефолтом `auto_redirect` (официальная рекомендация апстрима).

### S2. XTLS Vision: авто-включение и валидация
Факт из исходников Xray: без `flow=xtls-rprx-vision` связка REALITY+TCP несёт детектируемый TLS-in-TLS сигнал (ТСПУ его распознаёт). sora прокидывает `flow` из URI как есть, авто-логики нет. Пары: XHTTP+vision несовместимы (запрещать), vision+не-TCP — ошибка.
**Внедрить так:** `plan.go` — авто-vision для VLESS/Trojan + TCP + REALITY/TLS при пустом flow; `validate.go` — ошибка на vision+не-TCP, варнинг на reality+tcp без vision с кнопкой «исправить»; UI-бейдж + confirm при ручном отключении.

### S3. Свежесть uTLS как процесс, не как флаг
Факты: HelloChrome_Auto = Chrome 155 (коммит 06.10.2026); пин uTLS ≥1.8.2 (CVE-2026-27017 — GREASE-консистентность, CVE-2026-26995 — padding: «почти правильный» фингерпринт детектится); дефолт `chrome` у sora-legacy = Chrome 133 = блокируется ТСПУ в RU. Randomized-фингерпринты вредны (консенсус 2025–2026, JA4 их переживает).
**Внедрить так:** убрать молчаливый дефолт `chrome`; UI-выбор фингерпринта; CI-трекинг актуальности отпечатков; JA4-stealth-check в диагностике (`core/stealth/ja4.go`, таблица `known_ja4.json` из CI); авто-fallback фингерпринта при TLS-timeout.

### S4. Hysteria2: brutal CC + stall-watchdog
Факты: без `up_mbps`/`down_mbps` hy2 падает на BBR — протокол-кастрат (разрыв 30–50 п.п. на потерях); баг сервера v2.11.0 «stall без обрыва» (QUIC window exhaustion, фикс PR #1703).
**Внедрить так:** прокинуть up/down в sing-box (`up_mbps`/`down_mbps`) и mihomo (`up`/`down`); UI «скорость тарифа» + авто-калибровка по speedtest (ручной ввод завышают); port hopping (`server_ports`+`hop_interval`); клиентский watchdog «established, но 0 байт при спросе 15–20 с → реконнект»; в one-click деплое требовать сервер с фиксом PR #1703.

### S5. AmneziaWG: capability-check движка
Факт: sing-box upstream AWG не умеет (только форк amnezia-box). Если движок молча игнорирует AWG-поля — на проводе обычный WireGuard. Это обман пользователя.
**Внедрить так:** жёсткий варнинг/блок при `awg_supported=false`; проверка, что движок реально применяет поля, до старта сессии.

### S6. mihomo: классы резолверов + валидация правил
Факты из исходников: `core/engine/mihomo/rules.go:223` — direct+proxy смешаны в одном `nameserver`, `batchExchange` гонит серверы наперегонки → путь DNS недетерминирован, часть запросов светит домены провайдеру. mihomo молча ломается при mismatch behavior↔содержимое — движок не поможет.
**Внедрить так:** разделить `nameserver` (proxy-only) / `direct-nameserver` / `proxy-server-nameserver`; валидация behavior↔содержимое и RULE-SET→провайдер в генераторе sora с понятной ошибкой до старта.

### S7. FakeIP-дефекты + дедлайн Mullvad
Факты: `fakeIPFilterSuffixes` в sing-box-рендере молча пропускает interior-wildcard (`time.*.com`, `ntp.*.com`) → NTP получает фейковые IP только на sing-box; Mullvad public DNS закрывается **02.11.2026**.
**Внедрить так:** развернуть wildcard'ы в явные суффиксы, добавить `time.windows.com`, `+.stun.*.*`; унифицировать пул `/15`, AAAA в fakeip только при IPv6=on, инвалидация кэша при смене движка; убрать Mullvad из пресетов с миграционным предупреждением.

### S8. PQ key_share в ClientHello
Факты: X25519MLKEM768 — дефолт Chrome 131+, RFC 10024 финализирован (08.2026), >2/3 трафика Cloudflare — гибрид. Фингерпринт «свежий Chrome без PQ» — противоречие, видимое DPI до HTTP.
**Внедрить так:** аудит всех ClientHello (uTLS, REALITY, QUIC); JA4-check в диагностике ловит отсутствие PQ; WG PSK-слой (`wg genpsk` в UI + one-click dual-accept по прецеденту AmneziaVPN 11.2024) — квантово-стойкий хендшейк почти бесплатно; тумблер «PQ only» для параноиков с честной подписью.

### S9. Миграция bypass-движка tpws → nfqws/winws
Факты из исходников zapret: трёхфазная модель (`nfq/desync.c:161-186`), fooling (md5sig/badseq/badsum/ts), autottl, QUIC fake, lua `circular`-ротация. tpws — TCP-only без fake: sora отстаёт на поколение бэкенда. winws — тот же движок через WinDivert; цена — драйвер, UAC, антивирусы, WFP-конфликты (обработать честно).
**Внедрить так:** эпик с владельцем; QUIC-профиль nfqws (fake+repeats=6); bounded Strategy Tuner по pipeline форка «Просвет» (курированный генофонд + скрещивание + двойной прогон стабильности + привязка к F5-профилю), не чистый GA.

### S10. Детектор «сибирской заморозки» с автосменой фингерпринта
Факты: волна РКН-2026 бьёт по поведению (>3 параллельных TLS с одним SNI → заморозка), не по протоколу; проходят Firefox/QQ/Edge/OkHttp, палятся Chrome/Safari/iOS.
**Внедрить так:** активный зонд 6×TLS с fp-контролем, ротация на проходящие fp, бэк-офф, журнал событий; обязательный mux/vision для REALITY.

### S11. Подписи и обновления: key ceremony + staged + автооткат
Факты: minisign-ключ до сих пор плейсхолдер — вся цепочка подписей декларативна; эталоны — Sparkle 2 (EdDSA+дельты+атомарность+phased), Tailscale `clientupdate` (треки, Confirm, re-exec), minisign trusted comment (анти-даунгрейд). Аудит `updates.dart`: нет staged rollout/отката/metered.
**Внедрить так:** церемония ключа (блокер владельца) → фид `releases.json` с когортами 1%→100%, стоп-кран `blocked_versions`, health-check 60 с, автооткат, апдейт-трафик через туннель, уважение к metered-соединениям.

### S12. Strict kill switch — отдельная реализация
Факты: текущий гард sora — Standard (динамические фильтры, умирают с процессом/ребутом — reboot-тесты это ловят). Strict = nftables `policy drop` + ранний systemd unit до сети; Windows — WFP persistent-фильтры (`FWPM_FILTER_FLAG_PERSISTENT`) в sublayer 0xFFFF. Свой WFP callout-драйвер как датаплан — слоп (подпись, худший перф).
**Внедрить так:** три уровня Off/Standard/Strict; Standard по умолчанию (консервативно), Strict — осознанный выбор с confirm-диалогом и честными подписями последствий (captive portal!); UI-статус «Blocked: no traffic allowed»; self-test kill switch сниффером в CI.

---

## A-TIER — высокий эффект, дифференциаторы

**A1. XHTTP: xmux + xPaddingBytes + downloadSettings.** sora рендерит только mode/path/host/headers. `Xmux{MaxConcurrency/MaxConnections — взаимоисключающе, CMaxReuseTimes, CMaxLifetimeMs}`, `XPaddingBytes{100,1000}`, валидация против лимитов nginx (128/1000). `downloadSettings` — сплит аплоад/даунлоад по разным серверам (up через CDN, down напрямую через REALITY): ломает корреляцию и обходит лимиты CDN; только `stream-up`, Xray ≥24.11.30. Ни у кого из 13 конкурентов нет в UI. (01)

**A2. NaiveProxy нативно через sing-box.** Настоящий Chrome-стек (cronet-go, тег `with_naive_outbound`), padding первых 8 read/write, application fronting против active probing. Честная цена: libcronet десятки МБ + обязательное обновление синхронно с Chromium (протухший фингерпринт = детект-сигнал) — релизный процесс; UDP только через UoT. One-click деплой: Caddy + forwardproxy@naive. Честно: КНР заявляет идентификацию DPI-оборудованием (госзакупка 14.10.2026) — позиционирование «устойчивость к зондам», не «невидимость». (08)

**A3. MASQUE.** RFC 9297 (HTTP Datagrams) / 9298 (CONNECT-UDP) / 9484 (CONNECT-IP); Xray `proxy/masque` с 02.2025; прод-доказательства (Cloudflare WARP, Chrome IP Protection, Oxylabs 10.2026). Окно первенства: ни у кого нет в UI. Честные лимиты: мёртв без UDP. Внедрить: Xray inbound/outbound + mihomo-адаптер + UDP/QUIC-префлайт в диагностике с авто-fallback. (07)

**A4. REALITY dest-диагностика + no-steal.** Проверка dest (TLS 1.3, ALPN h2, X25519, PQ key share, не-anycast, гео-близость) с индикатором; серверный шаблон «без кражи» (dest → локальный dokodemo-door + SNI-роутинг → blackhole); генератор shortId; spiderX по умолчанию. (02)

**A5. OONI censorship intelligence.** `/api/v1/measurements` + `/v1/aggregation/*`; риск-скор по `anomaly`-доле (не путать с `failure`!), по ASN, с `as_of`; офлайн-снапшот с фолбэк-цепочкой (туннель → Tor → снапшот — api.ooni.io могут блокировать). Кормит автовыбор протокола. Поправка: теста `lantern` в OONI не существует — скор без него. Фоновые зонды — только с явного согласия. (61)

**A6. Speedtest в core через туннель.** Методология дословно из исходников: усечённое среднее Ookla (минус топ-2, минус нижние 22%), LibreSpeed (`count_ping=10`, grace 1.5 с, асимметричный jitter: `0.7/0.3` на всплеск, `0.2/0.8` на спад), замер строго через туннель с egress-проверкой, пара «VPN/прямо», история → топливо автовыбора сервера/движка. (62)

**A7. Доверенные сети по спеке IVPN.** Точная модель: trusted/untrusted/default, дефолт новых сетей **untrusted**, матрица действий 2×2 + block LAN, firewall как независимый контур; улучшения — SSID+BSSID, captive-probe. Ложится на существующие `core/profiles`. (66)

**A8. Management CLI по таксономии Mullvad.** `sora status/connect/server/account/killswitch/speedtest/diag`, `--json`, exit 0/1/2, тот же gRPC API что у GUI; export/import настроек. У sora управляющего CLI нет — только флаги демона. (65)

**A9. AmneziaWG 3.1 полностью.** HeaderProtectionKey, ContentPaddingAddition, тайминги-диапазоны (RekeyAfterTime/RekeyTimeout/RejectAfterTime/KeepaliveTimeout/MaxHandshakeAttempts), RandomTrailers, DisableCookies. Валидация: H-диапазоны не пересекаются, Jmax < MTU, S1+56 ≠ S2. Генератор «диалектов» + I1-пресеты (QUIC/DNS/SIP) + CPS-редактор. Честно: CN — не AWG. (17)

**A10. Shadowsocks-2022 как дефолт SS.** `2022-blake3-aes-256-gcm` (BLAKE3-деривация, separate header, replay-защита ±30с), генератор base64-ключей в UI (пароли запрещены спекой SIP022), EIH (`iPSK:uPSK`, SIP023) для мультитенанта, UDP relay нативный (роуминг по session_id). Legacy-методы — в «устаревшие» с варнингом про replay-атаки. (12)

**A11. Trojan: fallback как фича.** Без fallback на голом IP палится пробингом за один запрос. One-click деплой: настоящий сайт + fallback + длинный WS-путь + LE-серт. Уникальная диагностика: «невалидный пароль → отвечает настоящий сайт». (13)

**A12. TUIC v5 рядом с hy2.** Замеры 2026: TUIC прощает отсутствие тюнинга, выигрывает интерактив/0-RTT на мобильных; hy2+brutal — bulk и потери. Держать оба, автовыбор по speedtest-матрице на одном сервере (таких данных в открытых источниках нет — дифференциатор). v4 не деплоить. (15)

**A13. Captive-state machine.** Детект (canary + DHCP 114, RFC 8910/8908) → согласие → scoped exception TTL 15 мин → авто-возврат; при strict без согласия — ничего не открывать. Модель Speedify; NordLayer «3 минуты без VPN» — анти-паттерн. (60)

**A14. SRS/MRS rule-set'ы + гео-модуль.** Бинарь грузится в 10–250 раз быстрее текстового парсинга; свои .srs/.mrs при сборке (adblock, RU-пресеты) + remote `binary`/`mrs`, `interval 86400`, ETag, `size-limit`, скачивание через detour/proxy. Гео: переключаемый апстрим (MetaCubeX/Loyalsoldier/sokudo/custom), автообновление 24ч с джиттером, SHA256, fallback на встроенные, UI-индикатор свежести. RU-специфика: GitHub raw режется → зеркала обязательны. (51, 52, 54)

**A15. DoH3-first + RU-пресет.** Transport probing при старте/смене сети; лестница DoH3→DoH→DoT; DoQ — только ручная опция (порт 853 — первый кандидат на блокировку; сам RFC 9250 не обещает middlebox-resistance). Пресет «RU-антицензурный» одним выбором: DoH3-first через туннель, Quad9/AdGuard/CF h3, `.ru`→direct, дифференциальный детект подмены. (31, 32, 37, 40)

**A16. Закрытие утечек на уровне ОС.** Windows: NRPT `.`→туннельный DNS + DisableSmartNameResolution (надёжнее отключения SMHNR); Linux: `resolvectl dns/domain sora0 ~.`; macOS — честно «частично». Android: Private DNS + keepalive-offload 09.2026 (обход «Block connections without VPN», фикса Google нет — документировать как не-баг). (34)

**A17. Threat model + подготовка к аудиту.** `docs/threat-model.md` (host-based, T1–T7, не-цели; гэпы сейчас: TunnelVision/DHCP, Max-style oracle при split-tunnel, ключ подписи — плейсхолдер). По отчётам Cure53/X41/Assured/ROS: аудиторы проверяют IPC-права, kill switch сниффером, no-logs форензикой, фаззинг, стейджинг≠прод. Автотест kill switch сниффером в CI — уже сейчас. (69, 70)

**A18. TUN-бенчстенд.** Протокол: напрямую → TUN 1 поток → 4 потока → UDP, оба направления, ≥30 с, матрица симптомов→диагнозов; CI-порог регрессии 10% на смену пина движка; публикация цифр в Trust Center (никто из конкурентов так не делает). Без стенда «вроде лучше» — не аргумент. (50)

**A19. MTU 1420 + MSS clamping.** WG-арифметика: 1420 = 1500−80 (худший случай); MTU 9000 → фрагментация в userspace/дропы; PMTUD black hole — обрезанный ICMP; MSS clamping чинит 90% «медленного VPN» (v4 = MTU−40, v6 = MTU−60); QUIC clamping игнорирует — ему нужен живой ICMP. UI-варнинг при MTU >1500; MTU-probe (бинпоиск `ping -M do`) в диагностику. (47)

**A20. Kernel WG/AWG fast path на Linux.** Цифры подтверждены: 9.38 vs 6.12 Gbps single-stream, CPU 3–5% vs 12–18% при 1 Gbps; разрыв 1.1x–2.8x. Автовыбор dataplane: kernel-модуль через netlink когда доступен → fallback userspace; настройки Auto/Kernel/Userspace + бейдж в диагностике. Миф «65% overhead» AWG разобран: оверхед протокола <12%, kernel-модуль −3% к WG. (45, 46)

---

## B-TIER — укрепление, средний эффект

- **WS:** early data `?ed=2560` (Xray) / `max_early_data`+`early_data_header_name` (sing-box), `heartbeatPeriod` для мобильных; баннер «XTLS рекомендует XHTTP (ALPN http/1.1 — известный сигнал)» с миграцией в клик. (04)
- **gRPC:** `idle_timeout/health_check_timeout/permit_without_stream/initial_windows_size/user_agent/authority` в план и оба рендера; ALPN-валидация (h2 первым); `multiMode` — только за advanced с бейджем BETA. (05)
- **HTTPUpgrade:** починить mihomo-маппинг (`type=httpupgrade` → `network: ws + v2ray-http-upgrade: true`, сейчас риск молча битого конфига); UI-подпись «если WS режется сетью». (06)
- **Мёртвое в парсере:** выпилить `AllowInsecure` (парсится, не рендерится; Xray ≥26.2.6 удалил в пользу `pinnedPeerCertSha256`); `h2`+Xray → авто-миграция в XHTTP `stream-one`/H3 с уведомлением. Зафиксировать wontfix: mKCP, standalone quic. (10)
- **WG TCP-режим** для сетей без UDP — честная подпись «не стелс, а доступность». Диагностика трёх случаев: «нет UDP» / «режут WG-сигнатуру» / «AS-уровень» → три разных совета. (19)
- **VMess — честный legacy:** не удалять; автонормализация `aid→0` с уведомлением, бейдж Legacy, мастер миграции на VLESS+REALITY. (18)
- **ECH-readiness диагностика:** HTTPS-запись через туннельный DoH, парсинг `ech=`; инвариант «QTYPE 65/64 не фильтруются и не уходят в fakeip». «Переключатель ECH» в UI — слоп (клиент не владеет TLS-хендшейком; ECH делает браузер). ECH = RFC 9849 (протокол), 9848 — DNS-сторона. (26, 36)
- **Split DNS:** `.ru/.рф` → direct (sing-box правило + direct-сервер; mihomo `nameserver-policy`); captive portal → обычный DNS. (35)
- **LAN-bypass:** тумблер Выкл/Вкл/Авто-по-доверенной-сети + явные multicast-исключения (mDNS/SSDP/LLMNR); strict при дисконнекте блочит и LAN. (59)
- **Policy routing:** отдельная таблица + fwmark + `blackhole default` как второй рубеж; анти-луп трафика движка по UID. (58)
- **sing-box DNS:** `optimistic` кэш, `disable_cache` для `rcode://`, `type: mdns` для `.local`, явный `detour` у proxy-only. mihomo: `?h3=true` только при явном выборе DoH3; `ipv6: false` при IPv6=off. (38, 39)
- **UI резолверов:** протоколы + основание privacy-заявления (аудит KPMG 04.2026 у CF — единственный независимый среди бесплатных / заявление оператора) + юрисдикция; перепроверка раз в полгода. (40)
- **Гайд контрибьютора по sing-box + CI-чек «рендер vs схема option/»** — ловит рассинхрон до релиза. (67)
- **Reproducible builds Go + SLSA** (`-trimpath`, `SOURCE_DATE_EPOCH`, «пересобери сам»); Flutter — честно best effort. (69)
- **WinTun-аудит sing-tun:** кольцо сессии ≥8 МБ, spin-before-block в read-пути, drain-the-ring за проход; недоделки — issue/патч апстриму. (43)
- **BFE-конфликты (WFP):** одна транзакция, retry, понятная ошибка про AV в UI. (56)
- **Android/macOS проектные чеклисты** — спроектированы до кода (VpnService: fd/роуты/Doze/per-app; NE: процесс-расширение, лимиты памяти, kill switch по Mullvad, per-app без MDM невозможен, TunnelVision в чеклист). (48, 49)

---

## Исправления фактов первого прохода

1. `"stack": "mixed"` = TCP system + UDP gVisor (не «TCP на gVisor»); страдает UDP-путь. Вывод «убрать» усилен: на 1.17 конфиг не стартует.
2. ECH-протокол = RFC 9849; RFC 9848 — DNS-сторона. В задаче была неточность — в отчётах исправлено.
3. CONNECT-UDP = RFC 9298 (не 9297 — это HTTP Datagrams/Capsule; 9484 — CONNECT-IP).
4. Теста `lantern` в OONI не существует — в постановке была ошибка, зафиксирована.
5. «QUIC SNI slicing по умолчанию в Xray ≥25.6.8» — первоисточник в этом проходе не найден; подтверждены только Hysteria 2.6.2 (фрагментация ClientHello) и sing-box 1.12 (Chrome-parrot). Помечено «требует проверки», не выдано за факт.

## Отсечено фильтром «лучшее или слоп» (сводно)

Кастомные надстройки над VLESS; randomized-фингерпринты; udp2tcp-«стелс»; «смена порта WG» как анти-DPI; quantum-маркетинг и кастомные PQ-гибриды; удаление VMess; Trojan без fallback; SS-2022 как одиночный анти-DPI; legacy SS в новых деплоях; WFP callout-драйвер как датаплан; тюнинг gVisor (тупиковая ветка, апстрим удаляет); свой kernel-модуль WG; свой публичный резолвер; DoQ как дефолт в RU; `fake-ip-filter-mode: whitelist` по умолчанию; «переключатель ECH»; no-logs без основания; локальная DNSSEC-валидация как требование; ECH+REALITY; «невидимость» REALITY/MASQUE/NaiveProxy (везде опровергнута — детект идёт по поведению); чистый неограниченный GA в клиенте; один флаг «DPI-обход»; GeoLite2-City в дистрибутиве; собственный kill switch на Android поверх системного; молчаливый авто-bypass портала при strict.

## Требует проверки (честные пометки)

- Детали эвристик GFW QUIC после 2025 (payload≥1001, sport>dport — замер авторов; могли поменяться).
- Масштаб ML-DPI ТСПУ («апрельская чистка», «сибирская волна» — полевые реверсы, не официальные спеки; рабочие гипотезы).
- Эффективность форка «Просвет» — по README автора, независимых замеров нет.
- winws на ARM64 Windows — не проверено.
- Два фетча первоисточников упали (deepwiki 429, GitHub таймаут) — механика восстановлена по поисковым выборкам с цитатами файлов/строк; помечено в GROUP-C.
- Точные цифры прироста нового sing-tun стека 1.15 апстрим не публикует («substantial» без чисел) — закрывается только своим стендом.
- Прямых бенчмарков amneziawg-go vs kernel-модуля в открытых источниках нет — пробел, который sora может закрыть публикацией.

## Открытые вопросы владельцу

1. Приоритет P0-эпиков: миграция bypass-движка tpws→nfqws/winws — самая дорогая работа; подтвердить порядок перед включением в roadmap.
2. Принцип «mimicry-first, randomness-last» — закрепить в ARCHITECTURE.md как инвариант код-ревью? (доказано: Wang 2012, Sensors 2026, поле 2026).
3. Strict kill switch по умолчанию выключен (консервативно) или включён? Рекомендация: Standard по умолчанию, Strict — осознанный выбор.
4. Собственное CDN-зеркало sora для геобаз/rule-set — закладывать в инфраструктуру 2026?
5. Церемония minisign-ключа — блокер для обновлений и аудитов (уже в OWNER-PLAYBOOK).
6. Фоновые зонды цензуры и OONI-синк — только с явного согласия пользователя?
7. Каденс и бюджет внешних аудитов (Mullvad: раз в 2 года; X41 — ~30 человеко-дней на 5 платформ).
8. Warrant canary — заводить? (практика IVPN, дёшево).

## Карта «тема → отчёт»

Группа A (транспорты): 01-xhttp-internals, 02-reality-internals, 03-xtls-vision, 04-websocket-early-data, 05-grpc-transport, 06-httpupgrade-split, 07-masque, 08-naiveproxy, 09-quic-transport, 10-dead-transports.
Группа B (протоколы): 11-vless, 12-shadowsocks-2022, 13-trojan, 14-hysteria2, 15-tuic-v2, 16-wireguard, 17-amneziawg-3-1, 18-vmess-aead, 19-wireguard-obfuscation, 20-postquantum.
Группа C (DPI-обход): 21-nfqws-internals, 22-winws, 23-quic-desync, 24-geneva, 25-utls, 26-ech, 27-mimicry-vs-randomization, 28-tls-fragment, 29-active-probing, 30-ml-classification.
Группа D (DNS): 31-doh-rfc8484, 32-doh3-doq-rfc9250, 33-fakeip-deep, 34-dns-leaks, 35-split-dns, 36-https-svcb-ech, 37-dns-hijacking, 38-singbox-dns, 39-mihomo-dns, 40-resolver-audit-2026.
Группа E (TUN/датаплан): 41-singbox-tun-stack, 42-gvisor-netstack-perf, 43-wintun-architecture, 44-wfp-vs-wintun, 45-kernel-wireguard, 46-amneziawg-kernel-vs-go, 47-mtu-mss-pmtud, 48-android-vpnservice, 49-macos-utun-networkextension, 50-tun-benchmark-methodology.
Группа F (маршрутизация/файрвол): 51-singbox-route, 52-mihomo-rules, 53-xray-routing, 54-geoip-geosite, 55-nftables-killswitch, 56-wfp-killswitch, 57-iptables-migration, 58-policy-routing, 59-lan-bypass, 60-captive-portals.
Группа G (измерения/UX/архитектура/релизы): 61-ooni-api, 62-speedtest-methodology, 63-ja4-fingerprint, 64-censorship-detection, 65-mullvad-app-ux, 66-ivpn-trusted-networks, 67-singbox-codebase-tour, 68-update-frameworks, 69-reproducible-builds-audits, 70-threat-models.
