# WEB-RESEARCH-2: второй проход веб-разведки

Дата: 2026-10-20. 50 исследователей (5 команд по 10), второй проход поверх
`WEB-RESEARCH.md`. Командные сводки: `web-research-2/TEAM-A..E.md`.
Процедурная пометка: на глубине 2/2 спавн субагентов запрещён рантаймом —
все команды отработаны лидами напрямую по первоисточникам
(issue-трекеры, исходники, официальные changelog'и, RFC, диссертации).
Репозитории sora — только чтение, код не менялся.

Фильтр слопа владельца применён: каждый пункт — с вердиктом и источником.
Слоп — в конце, с причинами.

---

## 1. Верификация Tier S: 15/15 подтверждены, 0 опровергнуто

| # | Находка | Вердикт |
|---|---------|---------|
| 1 | zapret: nfqws/winws, QUIC-десинхронизация | ⚠️ Уточнено: активная разработка ушла в **zapret2** (C-демон + Lua-стратегии); tpws — платформенный fallback (Android/macOS), не мёртв. QUIC-рецепты 2026 подтверждены преконфигами |
| 2 | uTLS-кризис: Chrome 133 детектится | ✅ Xray-core #7131 (окт. 2026) + RPRX («ТСПУ лимитит число соединений с fp Chrome 133») + полевые тесты: Chrome 133 → TLS timeout, Chrome 155 → OK. sora пинит uTLS v1.8.2 (фиксы CVE внутри); риск — на стороне движков и дефолта `chrome` в sora-legacy |
| 3 | REALITY «сибирская» волна | ✅ Репликация мейнтейнерами Xray на **настоящем Chrome** (не uTLS): 4-е параллельное TLS с одним SNI → заморозка 120 с. Независимое подтверждение — parsers.vc. Новое: HTTP/2 как смягчение (меньше параллельных соединений) |
| 4 | Kill switch 3 уровня | ✅ Gizmodo (окт. 2026, reboot-тесты): дефолты Proton/ExpressVPN/CyberGhost текут, строгие режимы — нет. Оговорка: кейс race condition даже у «персистентного» Advanced (danielbrummitt.com) — доверять только собственным reboot-тестам |
| 5 | Встроенный speedtest | ✅ Методология из первоисточников Ookla/LibreSpeed. **Коррекция: у PIA в клиенте только per-server latency, не speed test** (офиц. поддержка PIA). Нюанс ExpressVPN: их тест запускается при отключённом VPN — sora обязана мерить через туннель |
| 6 | sing-box TUN: новый стек 1.15 | ✅ Дословно из официального changelog/migration: новый TCP/IP-стек в 1.15, `stack` deprecated, удаление в 1.17.0. Бонус из исходников: `gso` — уже hard error с 1.12; MTU-дефолты: 65535 / 9000 (Android) / 4064 (Apple NE) |
| 7 | Hysteria2: brutal CC + port hopping | ✅ Доки + код (`actualTx>0 → Brutal`) + полевой тест Colitu (окт. 2026). Stall-баг v2.11.0 независимо подтверждён. Ограничение: численных бенчмарков brutal-vs-BBR не найдено |
| 8 | mihomo rule-providers / MRS | ✅ Meta-Docs + исходники: MRS — zstd-сжатый прекомпилированный trie, команда `mihomo convert-ruleset`; mismatch behavior↔контент ядром не валидируется — sora должен валидировать сам |
| 9 | OONI intelligence | ✅ api.ooni.io жив (1.4 млрд записей, MAT/LONI-агрегация). Прецеденты: Tor Connection Assist (Moat API), Psiphon — автовыбор транспорта, 9.6M DAU в иранском шатдауне (янв. 2026). Лимиты: 10/мин с IP — нужен кэширующий слой, не прямые запросы из клиента |
| 10 | AmneziaWG 3.1 + применение полей | ✅ Параметры 3.1 (HeaderProtectionKey, ContentPaddingAddition, тайминги) — официальные доки. Апстримный sing-box AWG-полей **не имеет** (только форк amnezia-box). **Локально доказан риск**: `core/engine/singbox/render.go` эмитит `jc/jmin/jmax/s1–s4/h1–h4/i1–i5` в конфиг, а движки у sora — внешние бинарники. Если подкладывается апстримный sing-box — на проводе молча обычный WireGuard |
| 11 | NaiveProxy нативно в sing-box | ✅ С 1.13.0, биндинги `0x676e67/cronet-go`, тег `with_naive_outbound` по умолчанию. **Официальная позиция sing-box: «uTLS не для обхода цензуры — использовать NaiveProxy»** |
| 12 | XHTTP downloadSettings | ✅ Матрица подтверждена официальной докой Xray (xhttp+REALITY ✓, WS/HTTPUpgrade+REALITY ✗, XHTTP+Vision ✗). **Поправка: upstream sing-box xhttp-транспорта НЕ имеет** (только ремаппинг в форках) — «полное покрытие движков» первого прохода неверно для sing-box |
| 13 | Доверенные сети (IVPN-модель) | ✅ Официальный блог IVPN: per-SSID trusted/untrusted/none, дефолт новых = untrusted. Captive portal по механике Speedify (портал мимо туннеля → возврат после логина) — задокументировано |
| 14 | Geneva Strategy Tuner | ✅ CCS 2020 + диссертация Бока: рандом-strawman нашёл 0 стратегий — GA критичен. Извлечены точные параметры эволюции (популяция 200–1000, 50 поколений, мутация 90%, двойная оценка с min, Hall of Fame, мутации из pcap) — готовая спека bounded-поиска. **Форк «Просвет» не найден** — открытый вопрос, не факт |
| 15 | CLI + action URL-схемы | ✅ Mullvad CLI (гайд 2026.1), Tailscale CLI — задокументированы. У OSS прокси-клиентов — только import-схемы. Бонус: Hiddify 4.x добавил **подтверждение deep-link импорта против SSRF** — обязательный паттерн для `sora://` |

---

## 2. Поправки к первому проходу (важное)

1. **Xray уже не 25.x, а 26.x** (текущий 26.9.30). Два breaking change бьют по sora напрямую:
   - с **v26.7.11** Xray отклоняет нешифрованные VLESS/Trojan на публичные IP; MinVersion sora — 26.3.27 (ниже порога) → валидатор обязан учитывать версию ядра, иначе молча не заведётся;
   - удалён `legacy reverse` (миграция на VLESS Reverse Proxy); переименованы поля XHTTP (`sessionPlacement`/`sessionKey`) — сверить рендер.
2. **ECH = RFC 9849** (9848 — только DNS-доставка). **MASQUE: CONNECT-UDP = RFC 9298**, CONNECT-IP = RFC 9484. **PQ в TLS = RFC 10024** (авг. 2026), X25519MLKEM768 — Recommended.
3. Репозиторий uTLS переехал: `refractionPOINT/utls` мёртв → актуальный `refraction-networking/utls`.
4. Тема «Streisand» была без базы: iOS-клиент как репозиторий не найден, в первом проходе — 0 упоминаний. Не покрыто.
5. По Apple PQ3 и Signal новее первого прохода ничего не найдено — честно зафиксировано, не додумано.

---

## 3. Новое (чего не было в первом проходе)

### Движки
- **sing-box 1.12–1.15-alpha** (changelog целиком): DNS отрефакторен, legacy-формат мёртв в 1.14 (сверить рендер sora); AnyTLS нативно; TLS fragment/record fragment (дешёвый десинх без zapret); ECH на stdlib; `wifi_ssid`/`wifi_bssid`-правила (готовый фундамент F5); kTLS; ICMP echo proxy (пинг серверов без костылей); 1.14: OpenVPN/OpenConnect-клиент, sing-box API service + dashboard + `sing-box api` CLI, hy2-дефолты (Chrome QUIC parroting, `bbr_profile`, `gecko` obfs, рандомизация hop_interval), DNS race/speculative; 1.15-alpha: **MASQUE client+server**, переписанный HTTP-прокси, полный certificate pinning, Tailcat (задел для F9 без центрального сервера). **sing-box for Desktop — новый конкурент.**
- **mihomo ≥v1.19.20**: ECH, X25519-MLKEM768 в REALITY, AnyTLS нативно; MASQUE/Mieru — только в форках. Upstream сознательно не гонится за совместимостью с Xray ≥26.7.11 по REALITY — тестировать пары версий клиент/сервер.
- **AnyTLS реален**: оба движка, валидирован закупкой DPI-оборудования в КНР (требуют его идентификацию наряду с NaiveProxy/Shadowsocks/V2Ray). sora рендерит для sing-box — добавить mihomo.
- **zapret2**: портировать целиться в Lua-архитектуру, не в параметры nfqws v1.

### Конкуренты
- **Hiddify v4.1.2**: proxy chains уже в UI в проде (обогнал sora F8); Vaydns со сканером; `awg`-тип в редакторе; issue #2371 — сломанная подпись на Intel macOS (напоминание про матрицу старых macOS).
- **v2rayN 7.24.4**: security fix — MitM в даунлоадере ядер. Урок для update-UX sora: цепочка доставки движков только с проверкой подписи.
- **Mullvad**: автоматический multi-hop с decision tree (копировать для F8); iOS «Force all apps»; публичный known-issues с утечками (фича доверия).
- **Proton**: переписанный WG-стек; thumbs up/down после коннекта (дешёвое топливо для F2); авто-детект конфликтов сети; очистка DNS-правил после краша (проверить у sora).
- **IVPN**: modDNS (аудированный DNS-фильтр — референс для F3); load серверов в UI; V2Ray-обфускация на всех платформах.
- **AmneziaVPN 5.0.x**: AWG 3.1; one-click деплой MTProxy/Telemt; XHTTP в UI; TProxy (изучить как альтернативу TUN).
- **Clash Verge Rev 2.5.7**: копировать диагностику service-mode (логи сервиса в файл, реальная причина + ссылка на доку вместо «cannot start kernel»). **Clash Party 2.0.3**: Smart-ядро с ML-группами — референс для F2.
- **Nekoray desktop dormant** (тег 4.0.1, 2024) — окно возможности. **Karing**: лицензия «NOASSERTION», не чистый OSS — дифференциатор sora.

### Техники и исследования
- **RFC 10024** закрыл PQ-вопрос: включать X25519MLKEM768 на свои origins (one-click деплой), иначе «свежий клиент без PQ» — аномалия для DPI. ML-DSA-сертификаты — ждать WebPKI (2027–2029).
- **QUIC SNI DPI — полная механика** (gfw.report, USENIX 2025): 1 Initial → 180 с дропа 3-tuple; 7 проверенных контрмер (dummy pre-packet, high-port, slicing — бесплатно в quic-go ≥0.52.0, ECH, version-negotiation, миграция, QUICstep). Для QUIC-транспортов sora: pre-Initial dummy + high-port дефолт.
- **Happy Eyeballs v3**: внедрять принципы — рейсинг 2–3 транспортов параллельно вместо последовательного перебора (ложится на auto-transport + OONI-риск-скор).
- **SVCB/HTTPS**: ECH через HTTPS-записи — доказанный механизм; смешанный ech/non-ech RRSet уязвим к даунгрейду; DDR — только в доверенных сетях (в цензурируемых шифрование к резолверу цензора вредно).
- **CensorAlert** (FOCI 2026, LLM-агрегация репортов) — лента свежих инцидентов поверх OONI-агрегации; **Tor in-region vantage points** — референс-паттерн для канареек sora.
- **Padding**: DAITA — продакшн-референс механики для «режима штопор» (constant-size + dummy, с честной ценой в UI); Maybenot — фреймворк для экспериментов; **Reality Check 2026** — честный негативный результат: лабораторные 98% детекта не переносятся cross-network (любую ML-защиту оценивать только так).
- **GotaTun прошёл аудит** (0 critical/high/medium) — кандидат на userspace-путь после стабилизации роллаута Mullvad.
- **QUIC v2**: развёртывания ~0% — ничего не делать (редкая версия = выделимый клиент).
- **JA4**: полная формула из первоисточника — спека для честного stealth-check в диагностике sora (JA4 паррота vs JA4 реального браузера; сортировка в JA4 нейтрализует шафл Go — маскировка требует паррота, не рандомизации).
- **AmneziaWG**: точная семантика из кода (порядок handshake, `S1+56≠S2`, уникальность H1–H4, лимиты S) — спека валидатора конфигов sora.
- **OONI API**: точные endpoint'ы (`/aggregation/observations`, `/analysis`, `/detector/changepoints`) и лимиты — спека модуля censorship intelligence.
- **Xray изнутри**: XHTTP-дефолты таймингов (референс); при REALITY XHTTP принудительно H2; версия Xray зашита в SessionId (пассивный фингерпринт); `ech.go` — эталон fail-closed внедрения ECH (копировать).
- **Hysteria2 изнутри**: brutal осмыслен только при измеренном uplink (иначе BBR); port hopping — интервал ≥5s, дефолт 30s, несовместим с TCP-mimic.
- **MASQUE из RFC**: CONNECT-UDP реалистичен за 1–2 недели на Go (quic-go), Xray `masque/` — референс флоу; CONNECT-IP — объём ×2–3, позже. Честно: GFW таргетит MASQUE-домены (WARP-кейс) — маскировка ≠ невидимость.
- h-root — экспериментальный DoQ (апр. 2026); Windows Server DoH — GA (июнь 2026); замеры ISOC: выигрыш DoH3 только в cold-start.

---

## 4. Ранжированный бэклог второго прохода

**P0 (молча ломается):**
1. Xray ≥26.7.11 режет plaintext VLESS/Trojan на публичные IP — валидатор с учётом версии ядра; рассмотреть bump MinVersion.
2. Убрать `"stack": "mixed"` из рендера sing-box (удаление в 1.17.0); добить миграцию DNS-генерации на новый формат (legacy мёртв в 1.14); убрать `gso`/`inet4_*` (hard error на свежих).
3. Сверка имён полей XHTTP в рендере (старые `sessionPlacement`/`sessionKey` умрут).
4. **Вопрос владельцу:** какой sing-box бинарник шиппит sora — upstream или amnezia-box? От этого зависит, реален ли молчаливый AWG no-op (доказан кодом рендера).

**P1 (дешёвые выигрыши с доказанной механикой):**
5. hy2-дефолты из sing-box 1.14: Chrome QUIC parroting, `bbr_profile`, `gecko`, рандомизация hop_interval.
6. TLS fragment / record fragment в UI тюнинга (нативный десинх без zapret).
7. NaiveProxy 1.13+: QUIC/ECH/UoT; libcronet в дистрибуцию (обновлять синхронно с Chromium).
8. `wifi_ssid`-правила sing-box в F5 (доверенные сети).
9. AnyTLS для mihomo-движка; в one-click деплой — AnyTLS-сервер.
10. Диагностика в стиле Clash Verge Rev: логи сервиса в файл, реальные причины + ссылки на доку.
11. X25519MLKEM768 на origins one-click деплоя (RFC 10024).
12. Pre-Initial dummy + high-port дефолт для QUIC-транспортов.
13. Рейсинг транспортов при подключении (принципы HEv3).
14. JA4 stealth-check в диагностике (паррот vs эталон браузера).
15. Валидатор AmneziaWG по точной семантике кода (`Jmin<Jmax`, `S1+56≠S2`, уникальность H, лимиты S) + параметры 3.1.
16. ECH по референсу Xray `ech.go`: ECHConfig из HTTPS-RR/DoH, кэш с expiry, **fail-closed**; без защищённого DNS не включать.
17. Thumbs up/down после коннекта (паттерн Proton) → топливо для F2; server load в UI (паттерн IVPN).
18. SSRF-подтверждение deep-link импорта для `sora://` (паттерн Hiddify 4.x).
19. Проверка: очистка DNS-правил после краша (паттерн Proton — у sora проверить).

**P2 (roadmap):**
20. MASQUE через sing-box 1.15 stable / Xray (CONNECT-UDP первым).
21. zapret2 (Lua-архитектура) как цель портирования; Strategy Tuner по точным параметрам Geneva.
22. Censorship intelligence: OONI-агрегации + CensorAlert-лента + кэширующий слой (лимиты 10/мин).
23. Captive portal по механике Speedify (ниша без конкурентов среди прокси-клиентов).
24. Tailcat как транспорт для F9 (watch, не строить на alpha).
25. Mieru — мониторить upstream-принятие; sing-box for Desktop — отслеживать как конкурента.

---

## 5. Отсеяно фильтром (слоп) — не делать

TUIC v2 (не существует); Snell, Sudoku (нишевые/форковые, без аудита); QUIC v2 как «фича» (grease, ~0% деплоя); «SVCB-обход» как отдельный протокол; DDR в цензурируемых сетях (шифрование к цензору); ML-DSA-сертификаты в 2026 (WebPKI не готов); «MASQUE невидим для DPI» (GFW таргетит домены); overwhelm-флуд QUIC Initials как клиентская фича (offensive-техника); «AI-антидетект» без cross-network измерений; наивный random padding (пробивается DF >90%); интерактивный глобус Mullvad (фан-сервис); Mieru-интеграция сейчас (цена — форк-движки); «quantum-VPN»-маркетинг; свой DNS-резолвер (в силе); Streisand как тема (без базы).

---

## 6. Сквозные выводы

1. **Свежесть — это фича, подтверждено дважды.** uTLS, Xray 26.x, TUN-стек: «старое» = «не работает/молча ломается/детектится». Процесс отслеживания свежести (pin + Renovate + JA4-сверка) важнее любой отдельной фичи.
2. **Мимикрия > рандомизации, подтверждено дважды.** Точная имитация популярного бьёт случайность (JA4-сортировка нейтрализует шафл; «секретные» протоколы — слоп).
3. **Честность как архитектура.** Fail-closed везде (ECH по Xray, minisign-обновления, валидатор версий ядер): лучше не подключиться, чем подключиться «вроде как защищённо».
4. **Данные — топливо.** OONI-скоры, CensorAlert, JA4-замеры, thumbs up/down, per-network memory — всё в автовыбор сервера+движка+транспорта.
5. **Лабораторные цифры врут.** Reality Check 2026: любую защиту/детект оценивать cross-network + time gap, иначе это маркетинг.
