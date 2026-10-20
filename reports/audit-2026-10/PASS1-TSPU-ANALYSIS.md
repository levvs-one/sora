# PASS1-TSPU-ANALYSIS — обновление картины блокировок (проход 1/3)

Дата: 2026-10-20. Отдел ТСПУ-аналитиков, проход 1/3. Ветка `bugfix/audit-2026-10-19`, HEAD на момент сверки: `76a2ccf1` (голова `76a2ccf1`, TSPU-слои в HEAD).
Метод: перечитан TSPU-ANALYSIS.md (матрица T001–T044), сверка с кодом (grep `T0[0-9][0-9]` по `core/` + TSPU-SOLUTIONS.md + TSPU-FINISH.md), веб-поиск октябрь 2026 (news-вертикаль) по RU/IR/CN/TM/KZ, OONI, GFW Report, Censored Planet, Chrome-релизы, ECH-статус.
Слоп-фильтр: слухи без проверяемых источников — в разделе Rejected, в факты не попали.

**Коротко:** из 44 проблем — 12 изменились полем или новостями, 32 в прежнем состоянии.
Новых подтверждённых проблем — 9 (T045–T053). Решение по uTLS (T001) остаётся актуальным: Chrome 155 — всё ещё последний stable на 20.10.2026. Главный новый факт: **поствыборная волна октября 2026 с ковровыми банами /24 и новыми сигнатурами SOCKS5/VLESS/L2TP**, плюс **план ИИ-детекта 95% (Kommersant, 16.10.2026)** — снят из текущей версии нацпрограммы, но цель 92% к 2030 и бюджет +60% остались.

## §1. Сверка наших контрмер с новой реальностью

### 1.1 uTLS: Chrome новее 155 не вышел?
**Нет.** Google выпустил Chrome 155 в Stable 06.10.2026 (155.0.8059.79), патч-апдейт 13–15.10.2026 (155.0.8059.84/.85, Windows/Mac/Linux/Android) — это последний stable на 20.10.2026. Extended Stable остался на 152. Каденция — примерно раз в 2 недели на milestone, так что **Chrome 156 ожидается в конце октября 2026** (оценка по каденции, не официальная дата).
Наш vendored utls `v1.8.3-0.20261006222701-ff1b50fbbe9a` с `HelloChrome_Auto = HelloChrome_155` — по-прежнему актуальный parrot; CI-gate `obfs.TestCoreUTLSFreshnessGate` сравнивает JA4 с `t13d1517h2_8daaf6152771_cb7bf5808d99` (реальный Chrome 155).
Источники: https://cybernoz.com/google-chrome-155-patches-critical-use-after-free-flaw-and-nine-additional-security-bugs/ ; http://saasplain.blogspot.com/2026/10/chrome-155-or-152-check-update-channel.html
**Вывод:** T001 не устарел, но research-watch за parrot'ами (T039) нужно ужесточить с quarterly до **monthly** и добавить алерт на выход Chrome N+1 — решение T001/T039 обновить (новый зазор, см. T050).

### 1.2 «Сибирская» заморозка: эскалация?
Новых полевых данных о детерминированной цепочке (>3 параллельных handshake за 60 с → заморозка 120 с) не найдено. Но: октябрьская волна подтвердила **системный характер** блокировок (не хаос): «Раньше ограничения были более хаотичными, а за прошедший год стали системными» (BlancVPN, цит. по «Бумаге»). География полигона Сибирь/ДФО сохраняется как паттерн предвестников (T025).
Источник: https://paperpaper.io/my-tochno-znaem-chto-cenzor-prodolzhaet/
**Вывод:** T007-детектор актуален как есть; новых фактов об изменении механики заморозки нет → статус без изменений.

### 1.3 QUIC-баны: новые сроки?
Новых замеров residual-бана в RU не найдено; 420 с (замер 03–04.2026) остаётся последним числом — в коде это честно помечено как «перепроверять». Новое:
- **FOCI 2026 Best Practical Paper / USENIX Security 2025 Honorable Mention**: «Exposing and Circumventing SNI-based QUIC Censorship of the Great Firewall of China» (UMass SPIN + GFW Report + Stanford + CU Boulder). Ключевое: **умеренная нагрузка перегружает QUIC-парсер GFW → fail-open**; вычислительная стоимость расшифровки Initial — ахиллесова пята цензора. Техники обхода (dummy pre-handshake packet и др.) уже **интегрированы upstream в Mozilla Firefox, quic-go и все major QUIC-based circumvention tools**. Плюс: механизм цензора weaponizable — его можно использовать для блокировки UDP между произвольными хостами.
- QUICv2 по-прежнему не парсится (новых данных об обратном нет — окно открыто).
Источники: https://www.cics.umass.edu/news/researchers-reveal-crack-chinas-great-firewall ; https://gfw.report/publications/usenixsecurity25/en/ ; https://internationalfinance.com/technology/chinas-attempt-upgrade-great-firewall-didnt-yield-desired-results-study/
**Вывод:** T008/T036/T005: зазор — проверить, что умеет наш vendored quic-go из этой upstream-работы (dummy-packet circumvention), QUICv2-canary держать; residual 420 с перепроверить полем (новая проблема T049).

### 1.4 Carpet-баны: расширение?
**Да, подтверждена эскалация.** Волна октября 2026 (после сентябрьских выборов в Госдуму): блокировки бьют **целыми подсетями хостинг-провайдеров**, а не отдельными IP. Пострадали публично: Amnezia, Paper VPN, VPN Legend, GaMMa VPN, LTVPN, ABS, FoxyBot. Параллельно РКН подтвердил (начало октября 2026), что **ТСПУ научились определять SOCKS5, VLESS и L2TP** — новые протокольные сигнатуры в проде.
«Бумага» (опрос 4 сервисов): «за прошедший год стали системными»; Paper VPN: «кратное усиление и ускорение блокировок, блокируются как подсети, так и отдельные адреса. Аналогичные ситуации происходят и у self-hosted VPN».
Источники: https://vgtimes.ru/tech-and-hardware/171165-v-rossii-novaya-volna-blokirovok-vpn-pod-udar-popali-celye-podseti-hosting-provayderov.html ; https://paperpaper.io/my-tochno-znaem-chto-cenzor-prodolzhaet/ ; https://anyproxy.site/blog/russia-vpn-crackdown-2026/
**Вывод:** T011-спека (репутация подсетей, миграция <4 ч) из «важно» стала **критическим приоритетом** — её имплементация теперь главный зазор. AmneziaWG при этом назван «одним из самых надёжных на мобильных операторах РФ» (Игорь Бедеров, «Интернет-розыск») — подтверждает ценность T012.

### 1.5 ECH-статус
Без изменений для RU: ТСПУ по-прежнему дропает ClientHello с ECH-расширением при outer SNI `cloudflare-ech.com` (блок с 11.2024). Протокол дозрел: **RFC 9849 опубликован 03.2026**, OpenSSL 4.0 и NGINX 1.29.4 реализуют ECH (self-hosting возможен), Cloudflare — по-прежнему единственный крупный провайдер ECH. Новое: **в Госдуму внесён законопроект, запрещающий протоколы, скрывающие имя сайта (нацелен на ECH и Tor)** — юридический риск растёт, закон не принят.
Источники: https://ambientnode.uk/domain-fronting-ech ; https://linuxreviews.org/New_Russian_Legislation_Would_Outlaw_Tor_And_Sites_Using_Encrypted_ClientHello ; https://anyproxy.site/blog/russia-vpn-crackdown-2026/
**Вывод:** T024-стратегия (fail-closed, ECH не primary для RU) верна; добавить мониторинг принятия закона (T051).

### 1.6 Whitelist-режим мобильных операторов
Расширен: **мобильные шатдауны стали нормой** — интернет отключают регионами с 2025, «реестр социально значимых сервисов» вырос с 57 до **100+** (Kommersant, 03.2026): Gosuslugi, Yandex/VK, Ozon/Wildberries, банки, приложения операторов. WhatsApp заблокирован с 02.2026, Telegram — с весны 2026 (полный блок, раньше были троттлинг звонков 08.2025 и медиа-policer 02.2026). Wikipedia: Россия движется к «localized state-controlled whitelist internet model». Иран параллельно ввёл двухъярусную систему (NetBlocks: шатдаун — 76-й день на ~15.10.2026).
Источники: https://zyesims.com/russia-mobile-internet-shutdowns-whitelist/ ; https://en.wikipedia.org/w/index.php?title=Internet_censorship_in_Russia&printable=yes ; https://gnusocial.jp/user/96214 ; https://digiato.global/news/iran-32-point-unblocking-plan-disclosed/
**Вывод:** T004-стратегия должна различать «whitelist у оператора» и «полный шатдаун сегмента» (при втором не поможет никакой протокол — нужен честный dead-mode, новая T047). T043 (детект троттлинга мессенджеров) дополнить детектом `blocked-tcp`/`blocked-tls` паттернов.

### 1.7 ИИ-детект: новое
**Kommersant, 16.10.2026**: черновик нацпрограммы по ИИ до 2030 включал анализ характеристик VPN с эффективностью до **95%** (анализ размеров пакетов, таймингов, длительности сессий, соотношений трафика, хостеров, соседних IP — «косвенная идентификация инфраструктуры VPN»). Минцифры: мера **отсутствует в текущей версии** плана. Но: бюджет ГРЧЦ 2027 — 20→31,8 млрд ₽ (+60%, подтвердилось), цель — **92% эффективности сигнатур к 2030**, мощность ТСПУ — до 954 Тбит/с, 98% трафика через ТСПУ. Ошибка ложных срабатываний сейчас — 5–6% (оценка источников).
Источники: https://united24media.com/world/russia-eyes-ai-powered-vpn-crackdown-with-95-blocking-accuracy-23515 ; https://vpnlab.io/en/russia-doubles-internet-blocking-vpn-budget-2026-2619 ; https://english.nv.ua/business/putin-nearly-doubles-russia-s-internet-blocking-spending-to-706-million-50647634.html ; https://www.webpronews.com/russias-700-million-firewall-moscow-doubles-down-on-internet-controls-with-massive-2027-budget-push/
**Вывод:** прямых свидетельств ML в проде ТСПУ по-прежнему нет (честно), но план публично обсуждался и снят лишь из текущей версии. Конвергенция к ML-детекту 2027–2028 вероятна → T025-предвестники расширить (закупки GPU/кластеров ГРЧЦ), T027-стенд дополнить ML-детекторами (новая T046). T039 roadmap обновить.

## §2. Таблица статусов T001–T044

Легенда: ✅ внедрено+завайрено · 🟡 внедрено, честный NOT WIRED (причина в коде) · 📝 спека, кода нет · 🔄 изменилось полем/новостями · ❌ устарело · 🔒 закрыта решением (не полем)

### Critical

| # | Статус | Что со времени первого прохода |
|---|--------|-------------------------------|
| T001 | ✅ | utls bump (`v1.8.3-0.20261006`, `HelloChrome_Auto=155`), `fingerprint.go`, JA4 CI-gate, PQ key share. Chrome 155 — всё ещё последний stable → не устарел. НО: каденция Chrome ~2 нед → зазор: parrot-watch monthly вместо quarterly (T050). |
| T002 | ✅ | `ValidateReality` в validate.go, UI-варнинги; конфликт vision+mux — честное архитектурное решение. Актуален. |
| T003 | 🟡 | data-stall detector (`dataStallRule` → `Detector.Detect` → watcher+RPC) внедрён и завайрен. Актуален. |
| T004 | 🟡 🔄 | `WhitelistDetector` в коде, но честно NOT WIRED (646eb41). **Поле изменилось**: шатдауны как норма, реестр 100+, полный default-deny сегментов → стратегия должна покрывать «интернета нет вообще» (T047). Решение недостаточно для новой реальности. |
| T005 | 🟡 | `QueueAllocator` есть, NOT WIRED — нет нативного per-OS хелпера (NFQUEUE/WinDivert). Новое: quic-go upstream получил circumvention-техники из FOCI-paper → зазор проверить bump (T049). |
| T006 | ✅ 🔄 | Валидации REALITY внедрены. Новые данные: GFW QUIC fail-open под нагрузкой; VLESS-сигнатуры в RU публично подтверждены (10.2026) → T006-волны эскалируют. |
| T007 | ✅ | Freeze-детекторы унифицированы (`probe.FreezeDetector` — единый источник), re-handshake с deferral по заморозке завайрен; `HandshakeLimiter` честно NOT WIRED. Новых данных о механике заморозки нет. |
| T008 | 🟡 🔄 | BanTracker + DialQUIC (движковые QUIC-дайлеры — внешние бинарники → NOT WIRED честно); 420 с — замер 03–04.2026, перепроверять. QUICv2-canary — спека. Новое: FOCI-2026 fail-open исследование (T049). |
| T009 | ✅ | XHTTP-модель + `validateXHTTP` завайрены (df89781); downloadSettings не рендерится sing-box — честно. Актуален. |
| T010 | 🟡 | `dnsintercept.go` внедрён; `DetectDNSIntercept` NOT WIRED честно. DNS в туннеле — спека. По DNS/ECH новостей, меняющих картину, нет. |
| T011 | 📝 🔄 | Только спека (репутация /24, миграция <4 ч, подписанный фид). **Эскалация поля**: октябрьская волна ковровых /24 — спека стала критическим приоритетом (T045). |
| T012 | ✅ | Запрет дефолтных AWG-параметров внедрён. Поле подтверждает: AmneziaWG — «один из самых надёжных на моб. операторах РФ» (Бедеров). Актуален. |

### High

| # | Статус | Что со времени первого прохода |
|---|--------|-------------------------------|
| T013 | 📝 🔄 | Спека моб. whitelist-профиля. Поле: шатдауны регионами как норма → спека должна включать режим полного шатдауна (связано с T047). |
| T014 | 📝 | Спека измерительного контура. Новое: **shutdown.fyi** — готовая референсная методология (two-vantage probing RU vs Helsinki, 5-мин каденция, вердикты blocked-tls/blocked-tcp) для имплементации. Источник: https://dev.to/shutdownfyi/telling-censorship-from-outages-probing-russias-internet-from-both-sides-of-the-border-3c28 |
| T015 | 🟡 | `FakeTTL` внедрён, NOT WIRED (измерение дистанции — полевые работы). Без изменений. |
| T016 | 🟡 | Частично (тайминги 3.1, ContentPaddingAddition). Без изменений; приоритет растёт на фоне T046 (ML-детект). |
| T017 | ✅ | Planned re-handshake (45м±10м) + freeze-deferral завайрены (02dd088); keepalive NOT WIRED честно. Без изменений. |
| T018 | 🟡 | `throttle.go` в дереве (восстановлен после sweep-инцидента); `ClassifyDegradation` NOT WIRED. Без изменений. |
| T019 | 📝 | Спека IPv6 kill-switch. Без изменений. |
| T020 | ✅ | Аудит SIP022, `GenerateShadowsocks2022PSK` NOT WIRED; legacy-шифры не удалены — честно. Без изменений. |
| T021 | ✅ | Brutal up/down прокинуты в Xray; `CalibrateBrutal` NOT WIRED честно. Без изменений. |
| T022 | 🟡 | `ProbeTrojanFallback` внедрён, NOT WIRED (запрет авто-прогонов). Без изменений. |
| T023 | 🔒 | Закрыта продуктовым решением (OpenVPN не внедряем; reject-тест). Не полем, а решением — статус финальный. |
| T024 | ✅ | `validateECH` внедрён. ECH-блок в RU не изменился; новый юрриск — законопроект о запрете ECH (T051). |
| T025 | 📝 🔄 | Спека раннего предупреждения. Новое: предвестники расширить на ИИ-кластеры/закупки GPU ГРЧЦ и снятый-но-живой план 95% (T046). |
| T026 | 📝 | Спека pcap-харнесса; L1 (JA4 gate) внедрён. Без изменений. |
| T027 | 📝 🔄 | Спека стенда «прокси цензора». Зазор: добавить ML-детекторы (не только эвристики Wu et al.) — ответ на T046. |
| T028 | ✅ | `clientHelloStallRule` внедрён. Без изменений. |
| T029 | 🟡 🔄 | `deadsession.go` внедрён (untracked worktree — нужна проводка); UI dead-mode — спека. **Поле**: Иран — шатдаун 76+ дней, two-tier whitelist, план интенсификации борьбы с VPN (T048). |
| T030 | 📝 | Stage-gated спека MASQUE. Без изменений. |
| T031 | 🟡 | `MidSNISplit` внедрён, NOT WIRED. Без изменений. |
| T032 | 📝 | Спека GFW-готовности. Без изменений; default-deny как базовый сценарий подтверждён новостями. |

### Medium

| # | Статус | Что со времени первого прохода |
|---|--------|-------------------------------|
| T033 | 📝 | Спека bootstrap; сначала замеры ICMP/DNS-проходимости. Без изменений. |
| T034 | 📝 | Спека юридики инфраструктуры. Без изменений. |
| T035 | ✅ | `QualityRegistry` feed завайрен (02dd088); readout CENSORSHIP-METER — UI-часть. Без изменений. |
| T036 | 📝 | Спека QUIC SNI slicing; QUICv2-окно всё ещё открыто. Без изменений. |
| T037 | 📝 | Спека моб. SIM/тетеринг. Без изменений. |
| T038 | 📝 🔄 | Спека мониторинга вендоров. Зазор: QUICv2-canary важнее; добавить мониторинг закупок ИИ-кластеров (T046). |
| T039 | 🔄 | Roadmap; обновить: ML-конвергенция 2027–2028, parrot-watch monthly (Chrome-каденция 2 нед), повтор матрицы ежегодно. |
| T040 | ✅ | Per-ASN кэш стратегий внедрён; мультистратегический движок — спека после T005. Без изменений. |
| T041 | 🟡 | `RunSeries` внедрён, NOT WIRED. Без изменений. |
| T042 | ✅ | `ExpediteUpdate` + wiring (`SetCensorshipHook`) завайрены (02dd088). Без изменений. |
| T043 | 📝 🔄 | Спека детекта троттлинга мессенджеров. **Поле**: WhatsApp заблокирован с 02.2026, Telegram — с весны 2026 (полный блок, не троттлинг) → дополнить детектом blocked-tcp/blocked-tls паттернов (методология shutdown.fyi). |
| T044 | 📝 🔄 | Спека канала сигналов. Поле: событийный троттлинг теперь включает шатдауны и поствыборные волны; добавить crowdsource-источник vpnstatus.site. |

## §3. Новые проблемы (T045+)

### T045. Поствыборная волна 10.2026: ковровые /24 + новые сигнатуры — Critical
- **Проблема:** после сентябрьских выборов в Госдуму РКН перешёл к системным ковровым банам целых подсетей хостеров и добавил сигнатуры SOCKS5/VLESS/L2TP в ТСПУ (подтверждено в начале 10.2026). Пострадали Amnezia, Paper VPN, VPN Legend, GaMMa VPN, LTVPN, ABS, FoxyBot; ≥10 сервисов сообщали о блоках в конце сентября.
- **Механизм:** /24-блоки + сигнатурный детект протоколов (не только IP-реестр).
- **Наши контрмеры:** T011-спека (не код), T002/T006 частично, T012 (AmneziaWG держится).
- **Зазор:** имплементировать ядро T011 (репутация подсетей, автомиграция <4 ч, wave-mode в UI), VLESS считать перманентной мишенью (T039). Приоритет P0.

### T046. ИИ-детект 95%: план снят, цель осталась — High
- **Проблема:** Kommersant (16.10.2026): черновик нацпрограммы ИИ до 2030 включал анализ характеристик VPN с эффективностью до 95% (размеры/тайминги пакетов, длительность сессий, соотношения трафика, хостеры, соседние IP). Минцифры: в текущей версии меры нет. Но бюджет +60% и цель 92% сигнатур к 2030 остались; «intelligent algorithms» уже используются (не считаются ИИ).
- **Механизм:** телеметрия с узлов ТСПУ → кластеры обучения → распространение моделей на узлы.
- **Наши контрмеры:** T027-стенд (эвристики), T039-roadmap.
- **Зазор:** T025-предвестники: закупки GPU/кластеров ГРЧЦ; T027: добавить ML-детекторы в стенд; поднять приоритет T016 (поведенческая мимикрия). Прямых свидетельств ML в проде по-прежнему нет — честно.

### T047. Национальные whitelist-шатдауны как норма (RU) — Critical
- **Проблема:** мобильный интернет отключают регионами с 2025; реестр «социально значимых» вырос 57→100+; Wikipedia фиксирует сдвиг к «localized state-controlled whitelist internet model». При полном шатдауне не работает никакой протокол.
- **Механизм:** default-deny L3 + allow-list сервисов.
- **Наши контрмеры:** T004-детектор whitelist-режима (честно NOT WIRED).
- **Зазор:** различать «whitelist у оператора» (работает VLESS+REALITY поверх XHTTP) vs «полный шатдаун сегмента» (ничего не работает → честный dead-mode, как T029, но для RU); не retry-штормить. Приоритет P0.

### T048. Иран: шатдаун 76+ дней + two-tier доступ + план интенсификации — High
- **Проблема:** NetBlocks (~15.10.2026): шатдаун — 76-й день, двухъярусная система (доступ у избранных, население offline). 13.10.2026 рассекречен 32-пунктный план: разблокировка платформ увязана с «интенсификацией борьбы с инструментами обхода». Официально признаны «преднамеренные замедления» (15.10.2026). Блокировки SIM критиков (DW, 02.10.2026).
- **Механизм:** tiered whitelist на национальном уровне; во время шатдауна VPN не работает вообще.
- **Наши контрмеры:** T029 `deadsession.go` (детектор, честно не завайрен).
- **Зазор:** проводка dead-mode UX («связи нет вообще, это не баг sora»), запрет retry-шторма, офлайн-доставка конфигов (T033), спутник — только как документированная альтернатива, не код.

### T049. GFW QUIC fail-open под нагрузкой + upstream-интеграция circumvention — High
- **Проблема:** FOCI 2026 Best Paper / USENIX Security 2025: парсер QUIC Initial у GFW перегружается умеренным трафиком → fail-open; расшифровка Initial — вычислительно дорогая ахиллесова пята. Техники обхода (dummy pre-handshake packet и др.) уже **в upstream Firefox, quic-go и major QUIC-инструментах**.
- **Механизм:** стоимость парсинга Initial для цензора; weaponization — механизм можно обратить против произвольных хостов.
- **Наши контрмеры:** T008 (BanTracker), T036 (slicing-спека), T005.
- **Зазор:** (1) проверить vendored quic-go на наличие upstream circumvention (dummy-packet) и включить опцию; (2) residual 420 с перепроверить полем (последний замер 03–04.2026); (3) спроектировать детект weaponized-цензуры (аномальный UDP-дроп). QUICv2-окно открыто — держать canary.

### T050. Каденция Chrome ~2 недели: parrot-watch ужесточить — Medium
- **Проблема:** Chrome 155 — последний stable на 20.10.2026, но milestone-каденция ~2 недели → Chrome 156 ожидается в конце октября (оценка). HelloChrome_155 устареет за недели, не кварталы.
- **Механизм:** JA4-счётчик расширений и GREASE/ECH-mismatch как различители (уже в анализе).
- **Наши контрмеры:** T001 (CI JA4-gate).
- **Зазор:** research-watch parrot'ов: quarterly → monthly; авто-алерт на релиз Chrome N+1 (мониторинг chromereleases); процесс bump'а Xray в engines.lock держать горячим.

### T051. Законопроект о запрете ECH/Tor в RU — Medium
- **Проблема:** внесён законопроект, запрещающий протоколы, скрывающие имя сайта (нацелен на ECH и Tor); не принят.
- **Механизм:** юридический, не технический.
- **Наши контрмеры:** T024 fail-closed валидация.
- **Зазор:** мониторить принятие; при принятии — ECH в RU только как нарушение, UI-дисклеймер. RFC 9849 (03.2026) и OpenSSL 4.0/NGINX 1.29.4 для RU-пользователей значения не имеют.

### T052. Туркменистан: глубина default-deny — Medium
- **Проблема:** HRW World Report 2026: власти таргетируют VPN, **онлайн-игры, антивирусные обновления, тысячи IP**; продвигают государственные VPN; WhatsApp открывали 23.02.2026 и закрыли через 5 дней. Чёрный рынок доступа: VPN-ключи ~$50/мес, «освобождённое» подключение — до $2000.
- **Механизм:** тотальный default-deny с ручным вайтлистингом.
- **Наши контрмеры:** T034, T033 (спеки).
- **Зазор:** офлайн-обновления движков (side-load пакеты — нельзя полагаться на автообновление через интернет), доставка конфигов через bootstrap-каналы (T033), UI-предупреждение при детекте TM-ASN.

### T053. Методология shutdown.fyi как референс для T014 — Medium
- **Проблема:** отсутствует (возможность, не угроза).
- **Механизм:** two-vantage probing (RU vs Helsinki), 5-мин каденция, 38 сервисов × 8 операторов × 85 регионов; дифференциальные вердикты `blocked-tls` (TCP ok, TLS timeout) / `blocked-tcp` (IP unreachable) / `down`.
- **Наши контрмеры:** T014-спека, T018-классификатор.
- **Зазор:** заимствовать таксономию вердиктов в `ClassifyDegradation` (T018) и дизайн зондов T014; правило «двух независимых источников» (уже в T025) применимо к crowdsource-данным vpnstatus.site.

## §4. Приоритизированные зазоры для тех-агентов

**P0 (волна идёт сейчас):**
1. **T011-core → код.** Репутация подсетей (healthy/degraded/dead), wave-mode в UI, автомиграция. Ковровые /24 — главная угроза октября 2026.
2. **T004 → T047.** Различать whitelist-оператора vs полный шатдаун; dead-mode UX для RU (не только IR).
3. **T050.** Parrot-watch monthly + алерт Chrome 156; держать горячим процесс bump'а engines.lock.

**P1 (окно возможности / растущий риск):**
4. **T049.** Проверить vendored quic-go на upstream circumvention (dummy-packet); перепроверить residual 420 с полем; QUICv2-canary.
5. **T014.** Имплементировать измерительный контур по методологии shutdown.fyi (T053).
6. **T029 → T048.** Проводка `deadsession.go` в session manager + dead-mode UX; запрет retry-шторма.
7. **T005.** Нативный UDP-хелпер per-OS — блокер всего QUIC-десинка.

**P2 (стратегическое):**
8. **T027.** ML-детекторы в стенд «прокси цензора» (ответ на T046).
9. **T025/T038.** Предвестники: закупки ИИ-кластеров ГРЧЦ, App Store-удаления, НПА (включая T051).
10. **T052.** Офлайн-обновления движков + bootstrap-доставка конфигов для TM.
11. **T043.** Детект `blocked-tcp`/`blocked-tls` паттернов (мессенджеры уже не троттлятся, а блокируются).

**Не делать:** активное вызывание fail-open перегрузкой (юрриск — уже в T040); авто-прогоны trojan-prober (запрет уже в T022); молчаливое изменение keepalive пользователя (честно зафиксировано в T017).

## §5. Rejected (слухи/маркетинг без проверяемых источников)

- «GFW unified ML real-time model» (sunsetbrowser.app, коммерческий блог): ни одна peer-reviewed работа не подтверждает — как и было в первом проходе. Не включать в факты.
- Провинциальная цензура Henan как отдельный слой (btcvpn.com, коммерческий VPN-блог): недостаточно подтверждения; оставить как lead для полевой проверки, не факт.
- «Белые списки больше НЕ РАБОТАЮТ» (sozai.app, транскрипт видео о самописном VPN): про geo-блоки сервисов, не про ТСПУ — нерелевантно.
- Слухи об изменении residual-бана 420 с или механики «сибирской» заморозки: новых данных нет — старые числа остаются, перепроверка запланирована.
- «ТСПУ определяет AmneziaWG»: публичных подтверждений нет; полевое мнение (Бедеров) — наоборот, называет его надёжным на моб. операторах.

## §6. Источники (проверяемые, октябрь 2026)

1. Поствыборная волна /24 и сигнатуры SOCKS5/VLESS/L2TP: https://vgtimes.ru/tech-and-hardware/171165-v-rossii-novaya-volna-blokirovok-vpn-pod-udar-popali-celye-podseti-hosting-provayderov.html
2. «Бумага», опрос Amnezia/BlancVPN/Liberty/Paper VPN: https://paperpaper.io/my-tochno-znaem-chto-cenzor-prodolzhaet/
3. Разбор механики блокировок 2026 (Profile, anyproxy): https://anyproxy.site/blog/russia-vpn-crackdown-2026/
4. План ИИ-детекта 95% (Kommersant 16.10.2026): https://united24media.com/world/russia-eyes-ai-powered-vpn-crackdown-with-95-blocking-accuracy-23515
5. Бюджет ГРЧЦ +60%, цель 92% к 2030: https://vpnlab.io/en/russia-doubles-internet-blocking-vpn-budget-2026-2619 ; https://english.nv.ua/business/putin-nearly-doubles-russia-s-internet-blocking-spending-to-706-million-50647634.html ; https://www.webpronews.com/russias-700-million-firewall-moscow-doubles-down-on-internet-controls-with-massive-2027-budget-push/
6. Chrome 155 stable (06–15.10.2026): https://cybernoz.com/google-chrome-155-patches-critical-use-after-free-flaw-and-nine-additional-security-bugs/ ; http://saasplain.blogspot.com/2026/10/chrome-155-or-152-check-update-channel.html
7. FOCI 2026 Best Paper — GFW QUIC fail-open: https://www.cics.umass.edu/news/researchers-reveal-crack-chinas-great-firewall ; https://gfw.report/publications/usenixsecurity25/en/ ; https://internationalfinance.com/technology/chinas-attempt-upgrade-great-firewall-didnt-yield-desired-results-study/
8. ECH-статус, RFC 9849, законопроект RU: https://ambientnode.uk/domain-fronting-ech ; https://linuxreviews.org/New_Russian_Legislation_Would_Outlaw_Tor_And_Sites_Using_Encrypted_ClientHello
9. Whitelist-шатдауны RU, реестр 100+: https://zyesims.com/russia-mobile-internet-shutdowns-whitelist/ ; https://en.wikipedia.org/w/index.php?title=Internet_censorship_in_Russia&printable=yes
10. Иран: шатдаун NetBlocks, 32-пунктный план: https://gnusocial.jp/user/96214 ; https://digiato.global/news/iran-32-point-unblocking-plan-disclosed/ ; https://irannewswire.org/iran-internet-slowdown-filtering-starlink/
11. Туркменистан HRW 2026: https://www.hrw.org/world-report/2026/country-chapters/turkmenistan
12. shutdown.fyi методология: https://dev.to/shutdownfyi/telling-censorship-from-outages-probing-russias-internet-from-both-sides-of-the-border-3c28
13. Регуляторный ландшафт VPN 2026 (469 блоков RU): https://analysis-atlas.com/research/vpn-market-regulatory-landscape/
