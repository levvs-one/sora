# TSPU-SOLUTIONS: решения по 44 проблемам цензуры

Дата: 2026-10-20. Спецгруппа из 10 технических агентов. Вход: матрица
[../TSPU-ANALYSIS.md](../TSPU-ANALYSIS.md) (T001–T044, дедуп из ~560 проблем 50 аналитиков)
+ Tier S14 (Geneva Strategy Tuner) из WEB-RESEARCH.md.

Конвенция статусов: **внедрено** — коммит `[tspu-fix]` в ветке `bugfix/audit-2026-10-19`
(пуша нет); **спека** — файл в `tspu-solutions/`; **патч** — готовый diff, не закоммичен
(причина указана). SHA проверены 2026-10-20: 25 из 27 коммитов — предки HEAD,
2 осиротевших (`de2b254`, `a8cfda2`) целы как объекты (см. § «Здоровье ветки»).

По каждой проблеме: решение, сложность/эффект, риски и честные ограничения.

---

## Critical

### T001. uTLS-кризис: дефолт `chrome`=Chrome 133 детектится ТСПУ — ВНЕДРЕНО + спека
- **Решение (код):** bump `github.com/refraction-networking/utls` v1.8.2 →
  `v1.8.3-0.20261006222701-ff1b50fbbe9a`: `HelloChrome_Auto` = **HelloChrome_155**.
  Эмпирически доказано: захваченный JA4 = `t13d1517h2_8daaf6152771_cb7bf5808d99`
  побайтово совпал с полевым замером реального Chrome 155. JA4 self-test
  (`core/diagnostics/ja4.go` — захват реального ClientHello через локальный pipe,
  парсинг строго по референсу FoxIO; по ходу найден и исправлен баг:
  GREASE в signature_algorithms делал JA4 недетерминированным). CI freshness gate
  `TestCoreUTLSFreshnessGate` + PQ regression guard `TestJA4PQKeyShare`.
  База знаний свежести в `core/engine/fingerprint.go`: `IsStaleParrot`,
  `HasPQKeyShare`, `IsRandomizedFingerprint`, `ParrotVersion`, `ReferenceChromeJA4`,
  `DefaultXrayFingerprint="hellochrome_auto"`. Stealth-находки: `tls/fp-stale` (High),
  `tls/no-pq-keyshare` (Medium), `tls/fp-randomized` (Low).
- **Статус:** коммиты `9d9997d`, `3336f31`, `542eab3` (предки HEAD) + спека
  [02-utls-freshness.md](tspu-solutions/02-utls-freshness.md) (UI-выбор фингерпринта,
  авто-fallback при TLS-timeout, процесс мониторинга свежести, PQ-политика).
- Сложность средняя, эффект high. Риски: ложная ротация на плохом Wi-Fi
  (митигация — вердикт цензора + лимиты).
- **Честно:** sora измеряет JA4 только собственного uTLS; свежесть движков
  доказывается `engines.lock`, а не измерением. Bump Xray в `engines.lock` —
  owner-action (релиз-инжиниринг).

### T002. Vision обязателен для VLESS+REALITY — ВНЕДРЕНО (ядро) + спека
- **Решение:** `core/engine/reality.go` — `RealityWarnings()` (коды
  `reality-without-vision`, `reality-ws-transport`, `reality-xhttp-vision`,
  `reality-dest-ip/-not-host/-missing`), `ValidateReality()` (public key =
  32-байтный base64url X25519, shortId hex ≤8B — жёсткие ошибки), `IsVisionFlow()`.
  Архитектурное решение конфликта vision↔mux: **побеждает vision** — Xray-рендер
  не эмитит mux под vision flow (upstream его игнорирует; анти-параллелизм там —
  XHTTP+xmux).
- **Статус:** коммит `07951e4f` (предок HEAD) + спека
  [07-reality-hardening.md](tspu-solutions/07-reality-hardening.md) §5.
  Хуки в `validate.go`/`plan.go`/рендерах — в рабочем дереве (файлы грязные у
  параллельного отдела).
- Сложность низкая, эффект high. Риск: warning ≠ запрет — нужен UI hard-block toggle.

### T003. Детект «фриза»/silent drop после ~16 КБ как отдельный Kind — ВНЕДРЕНО
- **Решение:** новый `KindDataStall` в `core/censor`: правило `dataStallRule` —
  StageData достигнут, данные текли (≥1 КБ, порог ~16 КБ параметризован),
  затем тишина до локального дедлайна, ноль RST/FIN. Триада: SNI-I (RST →
  `KindSNIBlocking`) / SNI-II-III (stall → `KindDataStall`, reset mid-data →
  `KindRSTInjection`). 7 тестов с негативными кейсами.
- **Статус:** коммит `19e78c2` (предок HEAD).
- Сложность низкая, эффект high (диагностика перестаёт врать). Риск: congested-путь
  тоже сталллит — confidence 0.7, explanation честно оговаривает.
- Follow-up: маппинг в proto-enum `sora.censor.v1` (файл соседнего отдела).

### T004. Whitelist default-deny: детектор + стратегия — ВНЕДРЕНО (детектор) + спека
- **Решение:** `censor/whitelist.go` — `WhitelistDetector`: сигнатура отсечки
  ~16 КБ (14–18 КБ out → тишина → таймаут, inbound <2 КБ) по ≥3 дестам за 10 мин
  при нуле успехов; один успех опровергает. Ответ — `WhitelistStrategy{
  TCP443First, ValidSNIOnly, RotateSNI}`. 7 тестов.
- **Статус:** коммит `aa629d12` (предок HEAD) + спека
  [04-whitelist-and-proberesist.md](tspu-solutions/04-whitelist-and-proberesist.md)
  (стратегия для control-plane).
- Сложность средняя, эффект high. **Честно:** ни один desync whitelist не обходит —
  это детект и смена тактики, а не «обход».

### T005. nfqws-исполнитель и UDP-тракт — ЧАСТИЧНО ВНЕДРЕНО
- **Решение:** `core/engine/bypass/nfqws_queue.go` — `QueueAllocator` (очереди
  200–219, thread-safe) + рендер nft-правил `add/delete rule inet sora_nfqws
  output ... queue num N` из FilterTCP/FilterUDP со строгой валидацией портов
  (инъекции отвергаются), 6 тестов. Плюс `TamperStart/TamperCutoff/OOBData/MSS`
  для tpws (шейпить только handshake). Параллельный агент делает data-model
  (`Desync/FakeTLS/FakeQUIC/Fooling/TTL/AutoTTL/Repeats/FilterTCP/UDP/L7`),
  валидацию, `BackendOf`/`NFQWSArgs`, fail-closed и `NFQWS-MIGRATION.md` — не
  дублировалось.
- **Статус:** коммиты `d49fb7b`, `3b808df` (предки HEAD). Открыто: runtime
  исполнителя — активная работа sibling'а по его спеке.
- **Честно:** без root+NFQUEUE (Linux) / WinDivert-драйвера (Windows) QUIC-десинк
  невозможен в принципе; на Android/macOS — только tpws.

### T006. Probe-resistant fallback — ВНЕДРЕНО (клиент) + спека
- **Решение:** `core/probe/reality.go` — `CheckDest` (домен→резолв→не
  Cloudflare→TLS 1.3→ALPN h2→X25519-only handshake→валидный серт; 8 негативных
  тестов) + `CheckSNIConsistency` (дест не указывает на сам сервер).
- **Статус:** коммит `aa629d12` (предок HEAD) + спека `04-...md` §5
  (dokodemo-door fallback — серверная часть для one-click; серверного кода в репо нет).
- Сложность низкая, эффект high. **Честно:** активный пробинг чужих серверов не делаем (юрриск).

### T007. Детектор «сибирской» заморозки + бюджет handshake — ВНЕДРЕНО + спека
- **Решение:** `mux.go` — `MuxOptions`, `RealityMux()` (дефолт ON для REALITY),
  `MuxConcurrency()`; рендеры Xray/sing-box/mihomo. `censor/siberian.go` —
  `FreezeDetector`: узкая сигнатура (TCP ок, TLS убит до байтов сервера),
  backoff ≥120 с с запретом смены fp (`BackoffUntil`/`RetryAfter`), лестница
  fp→SNI→failover, ротация только `firefox→edge→qq→android` (без возврата к
  подозрительным Chrome/Safari/iOS). `snipool.go` — пул SNI; `budget.go` —
  `HandshakeLimiter` (≤3/SNI для dial'ов core).
- **Статус:** коммит `07951e4f` (предок HEAD) + спека
  [07-reality-hardening.md](tspu-solutions/07-reality-hardening.md).
- Сложность средняя, эффект high. **Конфликт:** у sibling'а `core/probe/freeze.go`
  (untracked) — второй детектор, циклит подозрительные fp — нужна унификация,
  чужой файл не правился.

### T008. QUIC residual-бан 420 с — ВНЕДРЕНО + спека
- **Решение:** `core/probe/quic.go` — `ProbeQUIC` (один Initial с grease-версией →
  Version Negotiation; VN=путь открыт, тишина при живом TCP=`Blocked`,
  ICMP=`Filtered`, оба молчат=`Down`; без ретрансмитов — зонд не должен сам себя
  банить), `BanTracker` (бан 4-tuple 420 с; политика «ротация source port, не
  ретрай» — ретрай продлевает бан), `Advice()` — запрет слепого TCP-fallback как
  политика в коде (для YouTube TCP хуже). 7 тестов.
- **Статус:** коммит `1147cc4` (предок HEAD) + спека
  [31-quic-residual-ban.md](tspu-solutions/31-quic-residual-ban.md) (врезка трекера
  в дайлеры, QUICv2-canary, shadow-handshake).
- Сложность низкая/средняя, эффект high (конец самобанам). **Честно:** VN-зонд —
  активный метод (только по явной кнопке/rate-limit); 420 с — замер 03–04.2026,
  перепроверять; за CGNAT бан может тянуть весь NAT-пул.

### T009. XHTTP: downloadSettings + тюнинг + guards — ЧАСТИЧНО (модель в ветке, валидация патчем)
- **Решение:** модель (`plan.go`, `engine.go`, `refs.go`, `catalog.go`): `Transport`
  получил `DownloadAddress`/`DownloadPort`, `XmuxMaxConcurrency/MaxConnections/
  MaxReuseTimes/MaxRequestTimes`, `XPaddingBytes`; фичи `FeatureXHTTPDownloadSplit`,
  `FeatureXHTTPXmux` (Xray✓, mihomo✓, sing-box✗); `RequiredFeatures()` тянет их из
  плана — план со сплитом **не маршрутизируется** на sing-box (раньше настройки
  молча дропались). Guards (`validate.go`): `validateXHTTP()` — whitelist mode,
  **запрет XHTTP+Vision**, downloadSettings только на xhttp + адрес/порт парой,
  xmux-правила, формат `xPaddingBytes`, ALPN h3 без TLS — ошибка; `Missing()`
  честно сообщает про REALITY-over-ws. Варнинги: `xhttp-version-sync`,
  `xhttp-xmux-proxy-limit` (>128 — лимит nginx). Standalone-тест validateXHTTP —
  20/20 кейсов.
- **Статус:** модель/фичи/гейты — в ветке (подобраны консолидатором).
  Валидация+варнинги — патч `~/workspace/.tspu-scratch-t009/
  t009-validate-catalog.patch` (137 строк, vs HEAD 9121cb3), не закоммичен —
  ветка была сломана пустыми деревьями. Рендеры/парсер — заспецифицированы:
  [09-xhttp.md](tspu-solutions/09-xhttp.md).
- Сложность средняя, эффект high (единственный клиент со сплитом up/down и
  честными запретами битых пар). **Честно:** sing-box-lx архитектурно не умеет
  downloadSettings/xmux; version-sync — эвристика; `xPaddingBytes` затрудняет, а не скрывает.

### T010. DNS-защита: детект инъекции/перехвата + bootstrap — ВНЕДРЕНО (зонд) + спека
- **Решение:** `core/diagnostics/dnsintercept.go` — рантайм-зонд перехвата
  (NXDOMAIN с aa-флагом, расхождение UDP/TCP, IP-маркеры цензора, бюджет 3 с,
  stdlib-only), тесты зелёные.
- **Статус:** коммит `fe048b5` (предок HEAD) + спека
  [10-dns-protection.md](tspu-solutions/10-dns-protection.md) (DNS внутри туннеля
  как дефолт, запрет тихого даунгрейда, DoH по IP-литералу + racing 2–4 с,
  RU-пресет Comss — проверено живо 2026-10-20, зонд в пайплайне подключения).
- Сложность средняя, эффект high. **Честно:** зонд не отличает провайдерский
  прокси от ТСПУ; DoH3 — opt-in до полевых замеров.

### T011. Ковровые баны подсетей — СПЕКА
- **Решение:** [11-subnet-bans.md](tspu-solutions/11-subnet-bans.md): репутация /24
  (healthy/degraded/dead, окно 15 мин), сегрегация (лимит плотности нод),
  автомиграция <4 ч (тёплый резерв 20–30%, канарейки, карантин 30 дней), фид с
  ≥3 RU-вантеджей (подписанный minisign), отказ от RU-ASN и Cloudflare для транспорта.
- Сложность высокая (деньги + операционка), эффект high. Риски: ложные
  срабатывания (кворум ≥2 + гистерезис), утечка инвентаря через фид.

### T012. AmneziaWG: честность параметров — ВНЕДРЕНО + спека
- **Решение:** запрет дефолтных/публичных параметров (`matchAWGPublicExample` в
  `validate.go` — отклоняет опубликованные примеры с требованием сгенерировать
  уникальный набор). Fail-closed проверка движка: xray отказывается рендерить
  **любой** AmneziaWG; mihomo отказывается от 3.1-полей; sing-box — позитивные
  тесты, что 3.1 доходит до with_awg-форка verbatim. Параметры 3.1 в
  plan/validate/render (`UsesAWG31()`). `wgobfusc.Generate/Generate31` —
  крипторэндом, проходит валидатор, никогда не совпадает с публичными примерами.
- **Статус:** коммит `16941d4` (предок HEAD, 7 файлов, тесты зелёные) + спека
  [05-amneziawg-31.md](tspu-solutions/05-amneziawg-31.md) (UI-редактор, `vpn://`
  импорт + QR, замерный стенд, §6.1: Китай — VLESS/XHTTP, не AWG).
- Сложность средняя, эффект high. **Честно:** AWG достаточен для РФ/BY/TR,
  частично IR, нет для CN.

## High

### T013. Мобильный whitelist-профиль — СПЕКА
- [13-mobile-whitelist.md](tspu-solutions/13-mobile-whitelist.md): TCP/443-first,
  пул SNI с ротацией ≤1/нед, обход 16-КБ отсечки (16101 байт: фрагментация +
  XHTTP downloadSettings), CGNAT keepalive 45–75 с ±25%, детект ложных дропов при
  перегрузке ТСПУ, рантайм-детектор whitelist-режима, per-ASN кэширование.
- Сложность высокая, эффект high. Go-часть упирается в `core/profiles`
  (горячий у другого отдела).

### T014. Измерительный контур: риск-скор транспортов — СПЕКА
- [14-measurement-loop.md](tspu-solutions/14-measurement-loop.md): двухплечевой
  контур — серверный агрегатор (OONI API/MAT + Censored Planet + собственные
  RU-вантеджи) → подписанный фид скоров; клиентский движок рекомендаций по
  min-risk + «погода цензуры». Формула: дневной риск
  `0.65·confirmed + 0.30·anomaly_consistent + 0.05·failure`, EWMA α=0.25/14 дней,
  пороги (N≥50/день на ASN, иначе country-fallback `confidence: low`), защита от
  отравления (медианы, кросс-валидация). Opt-in зонды с устройства
  (handshake-only, серии 10–15 мин), zero hidden telemetry.
- Сложность высокая, эффект high. Риски: ложные скоры при малых N; OONI API из
  RU может быть недоступен (агрегатор вне RU); ToS OONI не проверен.

### T015. Fake-пакеты: редизайн autottl — ВНЕДРЕНО
- **Решение:** `core/engine/bypass/fakettl.go` — `FakeTTL(hopsToServer, delta)`:
  калибровка «дистанция до сервера минус delta», потому что наивный autottl
  «нащупать хоп DPI» невозможен в принципе (ТСПУ — L2-мост, TTL не
  декрементирует, в traceroute невидим). Неизвестная дистанция = ошибка, не
  догадка; схлопывание окна (сервер в 2–4 хопах) → `ok=false` → fallback на
  split/disorder вместо фейка, бьющего по серверу. Тесты с негативными кейсами.
- **Статус:** коммит `c3b99d4` (предок HEAD).
- Сложность низкая, эффект средний (убирает класс «молча умирающих»
  fake-стратегий). Рандомизация шаблонов и измерение дистанции — полевые работы.

### T016. Мимикрия поведенческая, не только байтовая — ЧАСТИЧНО
- **Сделано:** 3.1 range-тайминги в `Generate31`; `ContentPaddingAddition`.
- **Нет:** побайтовый валидатор QUIC-мимикрии (нужен тест на захвате);
  probe-resistant UDP-ответы (серверная сторона); модель таймингов под
  протокол-донор; padding под распределение донора; двусторонняя мимикрия
  (AWG CPS односторонняя из коробки).
- Детали и честные ограничения — [05-amneziawg-31.md](tspu-solutions/05-amneziawg-31.md) §5–6.

### T017. Длинные сессии: duration-гигиена — КОММИТ ОСИРОТЕЛ (восстановим)
- **Решение:** `core/session/rehandshake.go` — `RehandshakePolicy` (дедлайн MaxAge
  ± uniform Jitter, fail-closed на нуле), `KeepaliveInterval` (base ±25%);
  возраст сессии = now−SYN (keepalive/KeyUpdate/rekey его не сбрасывают —
  только новый handshake). 5 тестов, пакет session зелёный. Проводка в менеджер
  + телеметрия обрывов — в спеке.
- **Статус:** коммит `de2b254` **осиротел** при сбросе ветки 22:27 (объект цел,
  файлы пропали из дерева) — восстановить cherry-pick'ом при стабилизации +
  спека [17-long-sessions.md](tspu-solutions/17-long-sessions.md).
- Сложность средняя, эффект medium-high. Риск: re-handshake во время
  «сибирской» заморозки усугубляет бан (в спеке — запрет); MaxAge <15 мин сам
  становится признаком.

### T018. Различать throttle vs block — ВНЕДРЕНО (ядро) + спека
- **Решение:** `core/diagnostics/throttle.go` — дифференциальный классификатор
  (Policer/Congestion/Event/Blocked/Degraded/Unknown) по парным замерам
  target-vs-control, методология OONI; негативные кейсы.
- **Статус:** коммит `15175c2` (предок HEAD) + спека
  [18-throttle-vs-block.md](tspu-solutions/18-throttle-vs-block.md) (замерный
  пайплайн, UX «троттлится, а не лежит», failover с backoff).
- Сложность низкая-средняя, эффект medium-high.

### T019. IPv6: kill-switch с перепроверкой — СПЕКА
- [19-ipv6-killswitch.md](tspu-solutions/19-ipv6-killswitch.md): firewall-level
  блок (не disable стека) с перепроверкой после каждого сетевого события,
  встроенный leak-тест (AAAA + канарейка, в т.ч. Android allowBypass-путь),
  мониторинг RA/option 121, детерминированный Happy Eyeballs, dual-stack opt-in.
- Сложность высокая, эффект high. `core/guard` горячий у другого отдела.

### T020. Shadowsocks: SIP022-честность — ВНЕДРЕНО + спека
- **Решение:** аудит Xray-core v26.10.17 — Detection Prevention по SIP022
  соблюдён (single-write handshake, SO_LINGER=0, паддинг 1..900, ±30 с, replay
  sliding window). В sora: бейдж Legacy + предупреждение о порте 8388, хелперы
  миграции (`GenerateShadowsocks2022PSK`, дефолт `2022-blake3-aes-256-gcm`),
  сквозной plumbing `plugin`/`plugin_opts` (parser → control/vault →
  sing-box/mihomo; xray честно не поддерживает — ограничение движка).
- **Статус:** коммиты `13bdb64`, `73e3d8d` (предки HEAD) + спека
  [T020-shadowsocks.md](tspu-solutions/T020-shadowsocks.md) (матрица движков,
  UI-решения). Plugin-plumbing был заметён ремонтом дерева (`1121593`/`26774d8`)
  — содержимое проверено на месте.
- Сложность средняя, эффект high. **Честно:** SS-2022 закрывает replay, не
  энтропийный вектор; legacy-шифры не удалены (бейдж + миграция).

### T021. Hysteria2: довести до ума — ПАТЧ + спека
- **Решение:** проверка маппинга Xray: **не устаревший** — `protocol:
  "hysteria"` + `settings.version: 2` и есть нативный Hysteria2 (утверждение
  старого web-research про «v1-outbound» — ошибка, зафиксировано). Реальный гэп:
  Xray не получал `up_mbps`/`down_mbps` → brutal не включался и там — написан
  фикс `hysteria()` + тест `TestRenderPassesHysteria2BandwidthToBrutal`
  (нулевые капы не рендерятся).
- **Статус:** патч
  [21-xray-hy2-brutal.patch](tspu-solutions/21-xray-hy2-brutal.patch) (44
  добавления, 0 чужого кода) — не закоммичен, файл `xray/render.go` горячий у
  другого отдела + спека [21-hysteria2.md](tspu-solutions/21-hysteria2.md)
  (UI тарифа, авто-калибровка brutal по speedtest, TCP-фолбэк, salamander-тест,
  QUIC ClientHello-аудит).
- Сложность низкая, эффект high. Риски: завышенный up деградирует канал
  (UI-варн + калибровка ×0.9); `ignoreClientBandwidth` делает тюнинг плацебо
  (честный хинт); hopping бесполезен при резке UDP целиком.

### T022. Trojan: self-test fallback — ВНЕДРЕНО + спека
- **Решение:** `core/probe/trojan.go` — `ProbeTrojanFallback(ctx, target)`:
  5 классов trojan-prober (h1-close, h1-incomplete, overbuffer-incomplete,
  h1-alpn-h2, short-alpn-h2), классификация web-like/proxy-like, `Report{OK,
  Summary}`. TLS-пробы с осознанным InsecureSkipVerify (поведение, не идентичность).
- **Статус:** коммит `b63c41b` (предок HEAD) + спека
  [T022-trojan-selftest.md](tspu-solutions/T022-trojan-selftest.md) (таблица
  классов, UI/RPC, запрет авто-прогонов).
- Сложность средняя, эффект high. **Честно:** `OK=true` ≠ «недетектируем»,
  пассивный DPI не покрывается.

### T023. OpenVPN: продуктовое решение — ВНЕДРЕНО (решение)
- **Решение:** вариант (б) — не добавлять вообще. Проверено: OpenVPN в sora
  отсутствует (детектируется по дизайну: открытый opcode-байт; tls-crypt/XOR не
  спасают). Контракт отклонения `openvpn://` на импорте зафиксирован тестом
  (unsupported-строка в отчёте, не тихий импорт; смешанные списки работают).
- **Статус:** коммит `b225dcc` (предок HEAD) + спека
  [T023-openvpn-decision.md](tspu-solutions/T023-openvpn-decision.md).
- Сложность низкая, эффект средний (продуктовая ясность). Рисков нет.

### T024. ECH: честная стратегия — ВНЕДРЕНО (валидация) + спека
- **Решение:** fail-closed валидация в `core/engine/validate.go`: ECH+REALITY →
  reject, ECH без TLS → reject, не отрендеренный QueryServerName → reject, ECH
  без пиннутого конфига требует зашифрованный DNS (8 тестов).
- **Статус:** коммит `cb87078` (предок HEAD) + спека
  [24-ech-strategy.md](tspu-solutions/24-ech-strategy.md) (outer SNI пулом, не
  cloudflare-ech.com; ECHConfig только по защищённому каналу; fallback при
  reject; threat model в UI).
- **Честно:** ECH скрывает SNI, не IP; в privacy score — низкий вес; в RU ECH —
  не primary (блок по паре `cloudflare-ech.com` + extension с 11.2024); без T010
  не включается.

### T025. Волны: раннее предупреждение — СПЕКА
- [25-wave-early-warning.md](tspu-solutions/25-wave-early-warning.md):
  региональные зонды (Сибирь/ДФО — обязательный полигон; триггер «деградация в
  1–2 регионах при норме в остальных = тест сигнатуры → L1»); мониторинг закупок
  ТСПУ (zakupki.gov.ru, ГРЧЦ) + НПА + App Store-удалений как предвестников;
  правило «два независимых источника» для уровней L0–L3; ранбуки R1–R4
  (ротация «часы, не дни», автопилот + T042); event-mode UX.
- Сложность средняя-высокая, эффект high. Риск: усталость от ложных тревог
  (митигация — два источника).

### T026. Размер/тайминг: pcap-харнесс — СПЕКА
- [09-pcap-harness.md](tspu-solutions/09-pcap-harness.md): трёхуровневый харнесс
  (L1 JA4 уже есть; L2 размеры/тайминги первых 16 КБ; L3 DF-CNN отличимость
  ≤0.60), версионированные baseline-pcap'ы, cold-start shaping («защита с
  пакета №1»), netem для честных IAT.
- Сложность высокая, эффект high (единственное честное измерение «похожести на
  браузер»). Риски: метрика как самоцель, тяжёлый CI (L3 — nightly).

### T027. Стенд «прокси цензора» — СПЕКА
- [10-censor-proxy-testbed.md](tspu-solutions/10-censor-proxy-testbed.md):
  4 детектора (эвристики Wu et al., JA4/JA3 + SNI-консистентность, wavelet-RF,
  DF-CNN), пресетные пороги (≥0.7 блокер), квартальная сверка мимикрии.
- Сложность высокая, эффект high (regression-контроль каждого релиза). Риск:
  «театр безопасности», переобучение на свои захваты (baseline — только
  реальные браузеры).

### T028. BY/KZ: pinning и детект MITM — ВНЕДРЕНО (детект) + спека
- **Решение:** `clientHelloStallRule` в `core/censor/detect.go`: ClientHello
  ушёл → тишина до дедлайна → 0 байт = `KindHandshakeTimeout` @ 0.7. 3 теста,
  censor-suite зелёный.
- **Статус:** коммит `8e1cae4` (предок HEAD) + спека
  [28-by-kz.md](tspu-solutions/28-by-kz.md) (SPKI-pinning против нац. корня KZ,
  зеркала дистрибуции, BY event-mode).
- Сложность средняя, эффект medium-high.

### T029. Иран: hostile-окружение — ВНЕДРЕНО (детектор) + спека
- **Решение:** `core/diagnostics/deadsession.go` — чистый детектор payload-health
  (injectable probe, бюджет 10 с): `Alive` / `NoTraffic` (0 байт за бюджет) /
  `Unknown` (проба сломалась сама — не путать с «нет трафика»). 6 тестов.
- **Статус:** коммит `5d616c9` (предок HEAD) + спека
  [29-iran-hostile.md](tspu-solutions/29-iran-hostile.md) (проводка в session
  manager, dead-mode UX, **запрет downgrade до HTTP** на уровне валидации,
  DNS-независимость клиента).
- Сложность средняя, эффект high для IR.

### T030. MASQUE: замерить, потом внедрять — СПЕКА
- [30-masque-measure-first.md](tspu-solutions/30-masque-measure-first.md). Два
  ключевых решения: (1) **коррекция модели:** MASQUE — протокол/endpoint, не
  транспорт VLESS (sing-box 1.15 — endpoints CONNECT-IP; Xray — `proxy/masque`
  как протокол; mihomo — outbound-тип). «VLESS поверх MASQUE» = композиция
  через существующие proxy chains (`Via`), ноль нового транспортного кода.
  (2) Stage-gated план: Stage 0 — полевые замеры (H3+H2 endpoint'ы, 3+
  RU-вантеджей, серии 10–15 мин, pcap-baseline); gates G1–G4 — провал gate =
  возврат к замерам, не шиппинг. Приоритет MASQUE-over-H2+CONNECT-IP, автофолбэк
  H3→H2, probe-resistant сервер (405), SNI-slicing.
- Сложность высокая, эффект high при проходе gates (ниша пуста у всех 13
  конкурентов). Gating по движкам: нужен sing-box 1.15+ (sora шиппит 1.14.3-lx
  — заблокировано до обновления поставки). **Честно:** MASQUE не «невидимость»
  (поведенческий детект остаётся).

### T031. Фрагментация: точная настройка — ВНЕДРЕНО
- **Решение:** `core/engine/bypass/split.go` — `MidSNISplit(sni)` возвращает
  `sniext+N`, где N=9+len/2 бьёт в середину hostname (проверено по исходникам
  вендорного tpws: маркер = начало extension, layout подтверждён). Маркер
  резолвится парсингом реального ClientHello в рантайме → нечувствителен к
  uTLS-перестановкам и REALITY (в отличие от абсолютных оффсетов). Валидация
  входа, тесты сверяют результат с реальным regex из `validate.go`.
- **Статус:** коммит `b22f132` (предок HEAD).
- Сложность низкая, эффект средний.

### T032. GFW-готовность — СПЕКА
- [11-gfw-readiness.md](tspu-solutions/11-gfw-readiness.md): целевой профиль
  «браузинг» (6 пунктов), пробоустойчивый handshake (fallback на реальный
  сайт), симулятор `gfw-strict` в CI, 4-фазный план на whitelist (детект T004 →
  авто-`hostile` → поведенческая мимикрия T016).
- Сложность высокая, эффект high (архитектурный ответ на главный тренд). Риски:
  шейпинг режет скорость (opt-in по детекту), шейпинг как новый фингерпринт
  (митигация: диапазоны + джиттер).

## Medium

### T033. ICMP/DNS-туннели как last-resort bootstrap — СПЕКА
- [33-icmp-dns-bootstrap.md](tspu-solutions/33-icmp-dns-bootstrap.md):
  last-resort **bootstrap** (доставка конфига, килобайты, минуты) — не транспорт.
  Первый артефакт — замеры проходимости ICMP/DNS из RU/KZ/BY/IR; нет данных —
  нет кода. Подпись minisign обязательна.
- **Честно:** это не «VPN через DNS».

### T034. Юридика инфраструктуры — СПЕКА
- [34-infra-legal.md](tspu-solutions/34-infra-legal.md): хостинг вне RU (ноды
  NL/DE/FI/SE, управление — отдельная юрисдикция IS/CH), опсек (no-logs как
  юрщит, SSH-только-ключи, ротация, инцидент-процедура), BY/KZ мультирегион.
- Сложность средне-высокая, эффект — юрнеуязвимость + no-logs как продуктовое обещание.

### T035. QUIC-метрики и CENSORSHIP-METER — КОММИТ ОСИРОТЕЛ (восстановим)
- **Решение:** `core/probe/pathquality.go` — `PathQuality` (EWMA RTT alpha 1/8,
  джиттер RFC 3550, loss-стрики, предикат `Stalled`; потокобезопасный;
  негативные кейсы: ноль без данных, отсутствие данных ≠ stall). Тесты зелёные.
- **Статус:** коммит `a8cfda2` **осиротел** при сбросе ветки (объект цел) —
  восстановить cherry-pick'ом + спека
  [35-quic-metrics.md](tspu-solutions/35-quic-metrics.md) (интеграция в
  CENSORSHIP-METER).
- Сложность средняя, эффект medium-high.

### T036. QUIC SNI slicing — СПЕКА
- [32-quic-sni-slicing.md](tspu-solutions/32-quic-sni-slicing.md): quic-go
  v0.52.0 существует; Xray v26.3.27 использует форк `apernet/quic-go` v0.61.1
  (дивергенция дефолтов — отдельный риск). Методология трекинга версий через
  engines.lock, требования к pcap-стенду (ассёрт ≥2 CRYPTO), ротация srcport
  уже внедрена через `BanTracker` (T008).
- **Честно:** против ТСПУ не измерено — до полевого замера это «вероятно
  помогает», не «обход».

### T037. Мобильные: иностранные SIM, тетеринг — СПЕКА
- [37-mobile-sim-tethering.md](tspu-solutions/37-mobile-sim-tethering.md):
  детект роуминга (MCC/MNC), 24 ч карантин-баннер, metered-режим,
  тетеринг-эвристики (OUI+TTL) с пометкой «вероятно», авто-применение
  T013-профиля. Миф «travel-eSIM обходит» — с 07.2026 фильтрация идентична.
- Сложность средняя, эффект medium (Android method-channel впереди).

### T038. Вендоры: мониторинг новых коробок — СПЕКА
- [38-vendor-monitoring.md](tspu-solutions/38-vendor-monitoring.md):
  еженедельный скрининг (закупки ГРЧЦ/РКН, утечки, вакансии, FOCI) с пометками
  факт/[СЛУХ]/[МАРКЕТИНГ] → бюллетень для T025/T014; **QUICv2-canary** —
  ежедневные зонды, триггер «парсер обновили» → алерт + план отката; A/B-зонды
  точного триггера ECH-детекта; живой стенд desync-техник × операторы
  (ground truth для Geneva-tuner и T015/T031).
- Сложность низкая-средняя, эффект средний сам / высокий как мультипликатор.

### T039. Эволюция ТСПУ: горизонт до 2030 — ROADMAP (покрыто лидом)
- В матрице: хроника Gen1→Gen3, VLESS — перманентная мишень, переоценка
  QUIC-обфускации. Рекомендация:
  1. **Транспортная гибкость вместо «волшебного протокола»:** VLESS считать
     перманентно таргетированным; инвестиции — в композицию транспортов
     (XHTTP downloadSettings T009, MASQUE-over-H2 T030, naive T7, proxy chains
     уже в продукте) и быстрый failover между ними (T007/T008-детекторы).
  2. **Default-deny как базовый сценарий:** hostile-архитектура (детектор T004 →
     авто-`hostile` T032 → поведенческая мимикрия T016) — проектировать уже
     сейчас, активный пробинг из РФ считается вопросом времени (бюджет РКН +60%).
  3. **QUIC-обфускация:** держать QUICv2-canary (T038) и SNI-slicing (T036) как
     эксперименты с полевыми gates; не шиппить без замеров.
  4. **Каденция:** повторять 50-аналитиков матрицу ежегодно (отчёты датированы
     2026-10-19); research-watch за parrot'ами (T001) — quarterly.
- Статус: roadmap-рекомендация, кода не требует.

### T040. Слабости как архитектура: per-ASN кэш, мультистратегия — ЧАСТИЧНО
- **Решение:** per-ASN keying уже был в `tune/cache.go`
  (`SSID\x1fGateway\x1fASN`); добавлен тест `TestCacheSeparatesASNs` (стратегия
  с одного ASN не протекает на другой).
- **Статус:** коммит `e6cb12d` (предок HEAD) + спека
  [40-multi-strategy-engine.md](tspu-solutions/40-multi-strategy-engine.md)
  (nfqws `--new`-профили по классам трафика, `BypassChain`, запрет активных
  методов вызова bypass — юрриск). Делать после исполнителя T005.

### T041. Двухстадийность: серийные пробы 10–15 мин — ВНЕДРЕНО
- **Решение:** `core/probe/serial.go` — `RunSeries`: серия длиной `Duration`
  (дефолт 12 мин) с интервалом (дефолт 1 мин); `Clean` только если все попытки
  прошли; `TwoStage` = были проходы, затем все последующие провалы (флаппинг
  не qualifies); early-stop нет (это и есть ложь одиночной пробы); отмена
  контекста возвращает частичную серию. 6 тестов.
- **Статус:** коммит `515646f` (предок HEAD).
- Сложность низкая, эффект средний (ловит двухстадийность вместо false negative).

### T042. Подписная ссылка как единица устойчивости — ВНЕДРЕНО (ядро) + спека
- **Решение:** `ExpediteUpdate(id)` в `core/control/subscriptions_expedite.go` —
  досрочный refresh по сигналу, ≤1 раза в 15 мин на подписку, без
  перекрывающихся fetch; `nextUpdate` учитывает через `expeditedDue`;
  атомарность замены списка не тронута. Состояние in-memory (рестарт →
  консервативно к расписанию).
- **Статус:** коммит `24f4749` (предок HEAD, тесты: cooldown, очистка маркера,
  запрет overlap) + спека [T042-subscription-resilience.md](tspu-solutions/T042-subscription-resilience.md)
  (триггеры: смерть сервера, кнопка UI, детектор волн T025; RPC-предложение).
- Сложность низкая, эффект средний-высокий при волнах. **Честно:** expedite не
  создаёт серверы — лишь раньше забирает ротированный список.

### T043. Детект троттлинга мессенджеров — СПЕКА
- [43-messenger-throttle.md](tspu-solutions/43-messenger-throttle.md):
  обобщение `throttle.go` (T018) на пары функций (текст vs звонки vs медиа),
  UX «текст ✓, звонки ✗», без кругового failover при классовом policer'е.

### T044. Событийный троттлинг: канал сигналов — СПЕКА
- [44-event-throttling-signals.md](tspu-solutions/44-event-throttling-signals.md):
  источники (OONI MAT всплески, DPIdetector, vpn-status.site, новостные ленты,
  opt-in маяки парка, локальные эвристики) → нормализация → классификация
  policer/конгестия/событие → подписанный фид (CDN, TTL минуты, отзывы ложных
  тревог) → event-mode клиента (консервативный транспорт по T014-матрице,
  честный UX «троттлится VPN vs лежит сегмент»). Маяки: строго opt-in, агрегаты
  `{asn, hour, ok/degraded, control_ok}`, без идентификаторов; правило двух
  независимых источников.
- Сложность средняя/высокая, эффект high (убирает класс «вечером медленно →
  чиним не то»).

---

## Вне матрицы: S14 Geneva «Strategy Tuner» — ВНЕДРЕНО (ядро) + спека
- **Решение:** новый пакет `core/tune/desync` (8 файлов, ~1280 строк):
  bounded-перебор параметров (геном `Params`: метод десинка, split-pos,
  fooling, fake-вариант TLS/QUIC, TTL/autottl, repeats, scope) — двухпоколенческий
  поиск, рамки ≤64 кандидатов / ≤30 с на пробу / ≤5 мин всего, дедуп по ID;
  фитнес `Score = (запрещённое получено) × (TCP не сломан) × (краткость)`
  (инжектированный RST / упавший контрольный fetch = 0 — жёсткий гейт);
  привязка к F5 (`NetworkKey()` SSID+gateway+ASN, `NeedsRetune()` — смена сети
  или fail-rate ≥0.5 при ≥8 сэмплах); циклическая ротация топ-N
  (`circular:fails=3:maxtime=60`, maxAge 15 мин); курированный генофонд v1 —
  12 сидов (каждый валидируется вживую). Пакет не ходит в сеть сам —
  зондирование через `ProbeFunc` вызывающего.
- **Статус:** коммит `057bbb2` (предок HEAD, `go build`+`go vet`+`go test
  ./tune/...` зелёные) + спека
  [08-geneva-tuner.md](tspu-solutions/08-geneva-tuner.md) (UI, проводка к
  F5/`tune.Cache`/`bypass.Engine`, канарейки, nfqws-исполнитель, дисклеймер RU).
- Сложность средняя, эффект high (пустая ниша среди 13 конкурентов).
- **Честно:** не обходит блокировку по IP; активный скан — только opt-in
  кнопка, rate-limited, против своих канареек; стратегия скоропортящаяся
  (5–15 мин) — ротация/перетюнинг это норма.

---

## Здоровье ветки (проверено 2026-10-20, важно)

1. **25 из 27** `[tspu-fix]`-коммитов — предки HEAD. Два осиротевших
   (`de2b254` T017, `a8cfda2` T035) — объекты целы, восстановить cherry-pick'ом
   при стабилизации (файлы пропали из дерева).
2. **Сборка:** `censor`, `tune`, `wgobfusc`, `diagnostics`, `probe`, `engine` —
   зелёные. Сломан **`core/ext`**: `ext/store.go` ссылается на
   `RevocationList`/`KeyRevocationInvalid` — символы в незакоммиченном сташе
   соседнего отдела. Починит автор сташа.
3. **Инциденты за день:** сбросы указателя ветки (осиротили 6+ коммитов),
   пустые деревья (`cc38c4f`, `977163c` — коммит через пустой индекс),
   массовое удаление (`147af4c` — 2942 строки в 95 файлах, частично
   восстановлено), затирание файлов между агентами, history rewrite. Уроки уже
   внесены в `~/AGENTS.md` (CAS через `git update-ref`, уникальные /tmp-имена,
   temp-index рецепт, запрет сташей на общей ветке). По AGENTS.md историю при
   грязном дереве не переписываю — восстановление за координатором/владельцем.
4. **Потерянный незакоммиченный код** (по отчётам агентов): ext revocation list
   (в сташе), subscription overrides `562452e` — replay владельцами.
5. **Рекомендация:** перед дальнейшей параллельной работой — заморозить ветку
   или ввести окна коммитов; восстановить символы `core/ext`; replay
   осиротевших коммитов; применить патчи
   [21-xray-hy2-brutal.patch](tspu-solutions/21-xray-hy2-brutal.patch) и
   `~/workspace/.tspu-scratch-t009/t009-validate-catalog.patch` когда
   соответствующие файлы остынут.
6. `/tmp` (tmpfs 512M) был забит на 100% — сборки гнать с
   `TMPDIR=~/workspace/.tmp`; GOCACHE одного из агентов — `~/gocache-tspu`
   (оставлен для следующих прогонов).

---

## Follow-ups / owner-actions

- Bump Xray в `engines.lock` (релиз-инжиниринг: бинарь + sha256 + тесты движков).
- Research-watch за parrot'ами (quarterly) + CI-gate уже внедрён (T001).
- UI-части: выбор фингерпринта (T001), XHTTP-редактор (T009), AWG-редактор
  (T012), SS-бейдж/миграция (T020), ECH-threat-model (T024) — нужен Dart SDK
  на dev-машине.
- Унификация двух детекторов заморозки (`censor/siberian.go` vs
  `core/probe/freeze.go` sibling'а; ротация fp должна исключать
  Chrome/Safari/iOS — полевые данные T007).
- Маппинг `KindDataStall` → `sora.censor.v1.CensorshipKind` (proto).
- `buf generate` для новых полей `BypassStrategy` в proto + Dart-регенерация.
- Врезка `BanTracker` в QUIC-дайлеры движков; runtime исполнителя nfqws
  (у sibling'а по `NFQWS-MIGRATION.md`).
- Полевые замеры из RU (вне кода, нужны вантажи): QUICv2-canary,
  shadow-handshake, CRYPTO-reassembly, TTL-окно до GGC, ICMP/DNS-проходимость
  (T033), MASQUE Stage 0 (T030).
- Ежегодный повтор матрицы 50 аналитиков (T039).

---

## Сводка

| Приоритет | Проблем | Внедрено (код) | Патч (готов) | Спека | Осиротевший коммит |
|---|---|---|---|---|---|
| Critical (12) | T001–T012 | 10 | 1 (T009 валидация) | 2 (T011 + часть T009) | — |
| High (20) | T013–T032 | 9 | 1 (T021) | 9 (+ спеки у T017, T021) | 1 (T017) |
| Medium (12) | T033–T044 | 2 | — | 9 (+ спека у T035) | 1 (T035) |
| Вне матрицы | S14 | 1 | — | 1 | — |
| **Итого** | **45** | **22** | **2** | **25** | **2** |

Спеки: 41 файл в `tspu-solutions/`. Коммиты `[tspu-fix]`: 27 (25 в HEAD).
Dart/UI-части — только спеки (SDK нет, по правилам — вычитка на dev-машине).
