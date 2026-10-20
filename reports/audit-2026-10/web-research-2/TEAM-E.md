# TEAM-E — второй проход веб-разведки: первоисточники

Лид команды (субагентов спавнить не могу — depth 2/2, can_spawn=no; все 10 тем отработаны лично).
Метод: исходный код — клонирование репозиториев в `/tmp/src` (depth 1) и чтение; RFC — тексты с rfc-editor/datatracker; Geneva — диссертация Бока (первоисточник статьи CCS 2020); OONI — код `ooni/backend`.
Фильтр владельца: только то, что влияет на решения по sora. Репозитории `~/workspace/bug-hunt/sora` не трогал (только чтение, изменений нет).

---

## 1. RFC 9297 / 9298 / 9484 (MASQUE)

Уточнение: CONNECT-UDP — это RFC 9298 (не 9297); 9297 — только дейтаграммы и капсулы; CONNECT-IP — RFC 9484.

**RFC 9297 — что нужно клиенту:**
- HTTP Datagram по QUIC: `{Quarter Stream ID (varint), Payload}`; по H1/H2 или без QUIC DATAGRAM — Capsule Protocol: TLV `{Type (varint), Length (varint), Value}`.
- `DATAGRAM` capsule = тип `0x00`. Заголовок `Capsule-Protocol: ?1`. H3-настройка `SETTINGS_H3_DATAGRAM = 0x33`, ошибка `H3_DATAGRAM_ERROR = 0x33`.
- Подводные камни из спеки: на H1 капсулы может использовать **только последний запрос** соединения; интермедиар может перекодировать QUIC DATAGRAM ↔ капсула, но только распознав использование Capsule Protocol; **нельзя** накапливать всю капсулу перед перекодировкой (проблемы flow control); не превращать QUIC DATAGRAM в капсулы бездумно — ломает DPLPMTUD; при 0-RTT клиент обязан валидировать, что серверный `SETTINGS_H3_DATAGRAM` ≥ запомненного, иначе `H3_SETTINGS_ERROR`.

**RFC 9298 (CONNECT-UDP):** upgrade-токен `connect-udp`. H1: `GET` + `Upgrade: connect-udp` + `Capsule-Protocol: ?1` → `101`. H2/H3: extended CONNECT (`:method=CONNECT`, `:protocol=connect-udp`, `capsule-protocol: ?1`). URI-шаблон по умолчанию `https://$HOST:$PORT/.well-known/masque/udp/{target_host}/{target_port}/`. Дейтаграммы: `Context ID = 0` + UDP-payload как есть. IPv6 в target — pct-encode двоеточий; порт 1–65535.

**RFC 9484 (CONNECT-IP):** токен `connect-ip`; H2/H3 `:protocol=connect-ip`, успех — любой `2xx` (не `101`!). Шаблон `/.well-known/masque/ip/{target}/{ipproto}/`; `target`/`ipproto` опциональны (`*` = wildcard). **Обязательно поверх TLS/QUIC.** Капсулы на request stream: `ADDRESS_ASSIGN`, `ADDRESS_REQUEST`, `ROUTE_ADVERTISEMENT`. Клиент: запрос → (опционально `ADDRESS_REQUEST`) → ждать `ADDRESS_ASSIGN` → только потом слать IP-пакеты (Context ID 0). ICMP форвардить только клиенту, чей scope совпадает; DSCP inner→outer **не копировать** (раскрывает flow); на H1 запрещён opportunistic send IP-пакетов до ответа (request smuggling).

**Практика из кода Xray** (`transport/internet/masque/`): CONNECT-IP клиент реализован поверх `quic-go`/`http3` (есть и H2-путь через капсулы). Флоу `establish()`: `NewRequest("https://"+host+path)` → `client.Dial` → `RequestAddresses(...)` → блокирующее `ReceiveAddressAssignment(ctx)` → проверка `MaxPacketSize() >= MinPacketSize` → фоновые `serveAddressAssignments/serveAddressRequests`. Кастомный User-Agent ставится явно.

**Вывод для sora:** CONNECT-UDP клиент = HTTP/1.1 upgrade (или H2/H3 extended CONNECT) + framing капсул + маппинг UDP↔дейтаграммы — реалистично за 1–2 недели на Go (quic-go). CONNECT-IP — плюс парсинг адресных капсул и виртуальный IP-стек; объём в ~2–3 раза больше. Оба — кандидат на «stealth-транспорт будущего», но серверной инфраструктуры MASQUE в дикой природе почти нет.

Ссылки: https://www.rfc-editor.org/info/rfc9297/, https://www.rfc-editor.org/rfc/rfc9484.html, https://www.hjp.at/doc/rfc/rfc9298.html, код: `XTLS/Xray-core/transport/internet/masque/`.

---

## 2. RFC 9848 / 9849 (ECH)

Уточнение: сам протокол ECH — **RFC 9849** (март 2026); RFC 9848 — только доставка `ECHConfig` через DNS (SVCB/HTTPS RR, `SvcParamKey 5 "ech"`, значение = base64 `ECHConfigList`).

**Требования к клиенту (RFC 9848 §5) — это и есть спека внедрения:**
- Клиент **MUST NOT** слать ClientHello до завершения SVCB-resolution.
- Если SVCB-resolution успешен и у всех альтернативных endpoints есть `ech` → клиент обязан перейти в SVCB-reliant режим (никакого fallback на прямое соединение — иначе вся приватность насмарку).
- Inner ClientHello несёт настоящий SNI/ALPN; outer — контролируется ECHConfig.
- Mixed RRSet (часть с `ech`, часть без) — downgrade-атака: посредник душит ECH-endpoints → fallback. NOT RECOMMENDED; если неизбежно — `ech`-записи с меньшим SvcPriority.
- DNS-запрос сам раскрывает имя → без защищённого DNS (DoH/DoT) ECH почти бессмысленен; враждебный резолвер, режущий SVCB, — штатный вектор даунгрейда.

**Практика из Xray** (`transport/internet/tls/ech.go`) — готовый референс для sora:
- `EchConfigList` = base64 ECHConfigList **или** DoH-источник: `"https://1.1.1.1/dns-query"` / `"example.com+https://1.1.1.1/dns-query"`.
- Глобальный кэш конфигов с expiry (`ECHConfigCache`, один update в полёте).
- **Fail-closed**: если конфиг получить не удалось — подставляется заведомо невалидный (`{1,1,4,5,1,4}`), соединение падает. Никакого тихого fallback на открытый SNI. Это решение sora должна скопировать.

**Урок из CVE-2026-27017** (uTLS 1.6.0–1.8.0): Chrome-паррот при GREASE ECH выбирал шифр случайно (AES/ChaCha20), а настоящий Chrome — детерминированно по железу → 50% детект. Вывод: ECH-реализация обязана в точности повторять выбор шифра реального браузера, иначе «стелс» превращается в маяк.

Ссылки: https://datatracker.ietf.org/doc/html/rfc9848, https://www.rfc-editor.org/info/rfc9849, код: `XTLS/Xray-core/transport/internet/tls/ech.go`.

---

## 3. sing-box: TUN-стек из исходников

(`option/tun.go`, `protocol/tun/inbound.go`, `docs/configuration/inbound/tun.md`, `experimental/deprecated/constants.go`; master на 2026-10-20)

- **`stack` deprecated в 1.15.0, удаление в 1.17.0** (env-переопределение `TUN_STACK`, миграция: https://sing-box.sagernet.org/migration/#migrate-tun-stack). С 1.15 sing-tun использует **собственный TCP/IP стек** — «substantial improvements over all previous implementations in peak performance, energy efficiency, and memory usage». **Решение для sora: убрать `stack` из генерируемых конфигов вообще.**
- `gso`: deprecated 1.11 → **удалён в 1.12, код возвращает ошибку** при установке. Авто-включение на Linux при `MTU < 49152`.
- MTU по умолчанию: `65535`; **Android — `9000`** («Some Android devices report ENOBUFS when using MTU 65535»); Network Extension (Apple) — `4064` (выше — «performance will drop significantly, which may be a system bug»).
- `multi_queue`: только Linux и только `go`-стек — иначе ошибка.
- Legacy `inet4_address`/`inet6_address`/`inet4_route_*` и пр.: **ошибка «deprecated in 1.10.0 and removed in 1.12.0»** — использовать только `address`/`route_address`/`route_exclude_address`.
- Legacy inbound-поля: ошибка с 1.13. `endpoint_independent_nat` без эффекта с 1.11; с 1.14 — UDP NAT fields (`udp_mapping`/`udp_filtering`).

**Вывод для sora:** не выставлять `stack`/`gso`/`inet4_*` (часть уже hard error на свежих версиях); MTU дефолт 9000 на Android оставить как есть; для десктопа дефолт 65535 ок.

Ссылки: https://sing-box.sagernet.org/configuration/inbound/tun/, код: `SagerNet/sing-box/{option/tun.go,protocol/tun/inbound.go}`.

---

## 4. Xray-core: XHTTP и REALITY

### XHTTP (`transport/internet/splithttp/`)
- Дефолты из `config.go`: uplink — `POST`, session/seq — в path; `scMaxEachPostBytes` = 1MB; `scMinPostsIntervalMs` = 30ms; `scMaxBufferedPosts` = 30; `scStreamUpServerSecs` = **случайно 20–80s** (сервер рвёт uplink-стрим); uplink chunk: cookie 2–3 KiB, header 3–4 KB.
- `XPadding` (`xpadding.go`): методы `repeat-x` / `tokenish` (base62-строки) — маскировка паддинга под токены; placement: cookie/header/query/path.
- **Недокументированное:** `decideHTTPVersion()` — при REALITY **принудительно H2** (не H3!); TLS без ALPN → H2; ALPN `http/1.1` → H1.1; `h3` → H3.
- `XmuxManager`: мультиплексирование XHTTP-сессий поверх одного HTTP-клиента (ключ — dest+settings).

### REALITY, клиент (`transport/internet/reality/reality.go`, `UClient`)
- `SessionTicketsDisabled: true` (resumption раскрыл бы), `InsecureSkipVerify: true` + свой `VerifyPeerCertificate`.
- SessionId (32 байта), позиция фиксирована (`hello.Raw[39:]`): `[0:3]` = версия Xray, `[4:8]` = unix time, `[8:]` = ShortId; затем **AES-GCM seal** `client_random[20:]` ключом `AuthKey = HKDF(X25519(ecdhe, serverPub), client_random[:20], "REALITY")`.
- Требует фингерпринт с TLS 1.3 (есть фолбэк на `MlkemEcdhe` — PQ key share).
- **Стелс при незащите:** если сервер не аутентифицировался (обычный сайт-заглушка), клиент ведёт себя как браузер: обход по `href="..."` со стартовой `SpiderX`-страницы, padding-cookie случайной длины, Referer-цепочки, случайные конкурентность/интервалы из `SpiderY[10]`, затем `«REALITY: processed invalid connection»`. Работает из коробки.
- Недокументированное: версия Xray зашита в SessionId — **пассивный фингерпринт версии клиента**; `Show: true` — дебаг-принт ключей (не включать в проде).

**Вывод для sora:** XHTTP-дефолты Xray — готовый референс таймингов для своего XHTTP-клиента; REALITY-стелс уже покрыт кодом Xray (писать свой не нужно); при аудите чужих конфигов смотреть `Show` и версию в SessionId.

Ссылки: код `XTLS/Xray-core/transport/internet/{splithttp,rea
lity}`.

---

## 5. uTLS: фингерпринты из исходников

- **Репозиторий переехал:** `refractionPOINT/utls` мёртв (404) → актуальный `refraction-networking/utls`.
- Актуальные парроты (master): `HelloChrome_155` (= `HelloChrome_Auto`), `HelloFirefox_148` (= `HelloFirefox_Auto`), `HelloSafari_26_3` (= `HelloSafari_Auto`), `HelloIOS_14`, `HelloEdge_85` (= `HelloEdge_Auto`; **Edge_106 признан несовместимым** — Auto остался на 85). Плюс PSK/Shuffle-варианты (`HelloChrome_112_PSK_Shuf`, `HelloChrome_114_Padding_PSK_Shuf` и др.).
- Обновление = новые константы в `u_parrots.go` + сдвиг `_Auto`-алиасов в `u_common.go` (строки ~606–665). Свежая версия тегируется (v1.8.1 закрыла CVE-2026-27017).
- **Программная проверка свежести** (встроенного фида версий нет):
  1. `Fingerprinter.FingerprintClientHello(data)` (`u_fingerprinter.go`) — распарсить свой ClientHello в `ClientHelloSpec` и сравнить с эталоном;
  2. `Roller` (`u_roller.go`) — перебор HelloID до успешного handshake (уже готовый механизм);
  3. JA4-сравнение паррота с JA4 реального браузера (см. §10) — честный стелс-тест;
  4. процесс: pin версии в `go.mod` + Renovate/Dependabot на `refraction-networking/utls`.
- Chrome-паррот из коробки включает: GREASE, shuffle расширений, `X25519MLKEM768` (PQ), ALPS (`ApplicationSettingsExtensionNew`), `BoringGREASEECH()` — при самописном `ClientHelloSpec` легко отстать именно здесь.

**Вывод для sora:** свежие парроты уже в uTLS — обновлять библиотеку, а не копипастить спеки; для диагностики добавить JA4-сверку паррота с эталоном (связь с §10).

Ссылки: https://github.com/refraction-networking/utls, `u_parrots.go` / `u_common.go` / `u_roller.go` / `u_fingerprinter.go`.

---

## 6. Geneva (CCS 2020) — методология для bounded-поиска

Первоисточник: диссертация Kevin Bock, гл. 3 (статья CCS 2020 — та же методология).

- **Представление стратегии:** лес `(триггер → дерево действий)`; действия: `drop`, `tamper{поле: replace/corrupt}`, `duplicate(...)`, `fragment(...)`. Inbound-лес — без branching (ограничение NFQueue). Синтаксис: `[TCP:flags:S]-duplicate(tamper{TCP:flags:replace:SA}(send),send)-|`.
- **Эволюция:** инициализация 200 (реальный мир) – 1000 (лаб) особей, у каждой 3 случайных действия + 1 триггер; мутация 90% особей/поколение (add 20% / remove 20% / trigger 20% / action 40%); кроссовер 40% **до** мутации; турнирный отбор с возвратом; **Hall of Fame** — глобальный отсортированный архив всех оценённых особей (не потерять найденное).
- **Фитнес:** forbidden-действие удалось → плюс; цензура (RST/drop/injected cert) → большой минус; **каждую стратегию оценивать дважды, брать худший результат** (анти-флакинес); штрафы за vestigial-деревья (триггер ни разу не сработал), за overhead (лишние пакеты), за сложность (число действий) — два последних **только при положительном фитнесе** (не душить разведку на старте).
- **Ключевой приём мутаций:** значения тянуть из **реального pcap** предыдущего прогона (а не uniform random) — иначе почти всегда невалидные комбинации (например, флаги TCP). Плюс: инжектированные цензором пакеты тоже попадают в pcap и становятся материалом для триггеров.
- **Фазы** (возникают сами): триггеры → «не убить TCP» → обход → минимизация. Случайный поиск: 0 стратегий за 100k особей; Geneva: успех за ≤10k. Генетика критична, не опциональна.
- **Бюджет для клиента:** поколение 5–10 мин в реальном мире, сессия 4–8 часов, ~500KB out + 2MB in на поколение. Это фоновая задача, не интерактивная. Bounded-поиск в sora: бюджет = популяция × поколения × 2 оценки; оценка — дешёвое forbidden-действие (HTTP GET с запрещённым словом / DNS-запрос); **TCP-segmentation-only стратегии работают без root** — самый дешёвый класс для десктопного клиента.
- Meta-слой покрытия: если успешные стратегии многих прогонов используют одно поле заголовка — исключать его из следующих сессий (расширение поиска).

**Вывод для sora:** копировать 1:1 — представление (триггер, дерево), двойная оценка с min, штрафы только при успехе, Hall of Fame, мутации из pcap, сид популяции «вымершими» стратегиями для дообучения.

Ссылки: https://kevinbock.phd/pdf/2022-dissertation.pdf (гл. 3), https://geneva.cs.umd.edu/.

---

## 7. OONI API — спека для модуля censorship intelligence

Код: `ooni/backend`, сервис `ooniapi/services/oonimeasurements`. База `https://api.ooni.io`.

- `GET /api/v1/measurements` — фильтры: `probe_cc`, `probe_asn` (ASxxx), `test_name`, `domain`, `input`, `report_id`, `category_code`, `anomaly`, `confirmed`, `failure`, `since`/`until` (**интервал ≤ 180 дней**), версии ПО; пагинация `limit`/`offset`, `next_url` в ответе.
- `GET /api/v1/measurement_meta`, `GET /api/v1/raw_measurement` — мета и тело измерения (тянет из S3/ClickHouse — дорого).
- `GET /api/v1/aggregation` (legacy); **`GET /api/v1/aggregation/observations`** — группировка по `timestamp`/`failure`/`hostname`/`ip`/`probe_cc`/`probe_asn`/`test_name`, `time_grain=day` (дефолт); **`GET /api/v1/aggregation/analysis`** — вероятности блокировки (blocking probability vectors); `/aggregation/observations/ctrl` — ground truth от контрольных точек.
- `GET /api/v1/observations`, `GET /api/v1/analysis` — сырые списки; **`GET /api/v1/detector/changepoints`** — CUSUM-детектор событий цензуры (готовая «тревога»).
- **Лимиты** (`common/rate_limit_quotas.py`): `RateLimiterMiddleware`, дефолт **`10/minute; 400000/day; 200000/7day`** на IP (blake2b-хеш). Стоимость запроса — в единицах 10ms: тяжёлые запросы (raw) жрут квоту быстрее.

**Вывод для sora:** модуль разведки = агрегации (`/aggregation/observations` + `/analysis` + `changepoints`), кэшировать, опрашивать не чаще ~10/мин с IP; сырые измерения — точечно и редко. Лимитов хватает на фоновый мониторинг, но не на интерактивные запросы каждого пользователя — нужен серверный/кэширующий слой.

Ссылки: https://api.ooni.io/, код `ooni/backend/ooniapi/services/oonimeasurements/src/oonimeasurements/routers/{v1/measurements.py,v1/aggregation.py,data/aggregate_observations.py,data/aggregate_analysis.py}`.

---

## 8. Hysteria2: congestion control и port hopping

Код: `apernet/hysteria`, `core/internal/congestion/`, `core/client/client.go`, `extras/transport/udphop/`.

**Congestion — выбор в handshake** (`client.go`):
- сервер `RxAuto` → `UseConfigured` (bbr/reno, без brutal);
- иначе `actualTx = min(serverRx, clientTx)`; `actualTx > 0` → `UseBrutal(tx, disableLossCompensation)`; иначе `UseConfigured`.
- Типы: `bbr` (дефолт, есть профили), `reno` (дефолт quic-go), `brutal` (только при известной полосе).

**Brutal** (`brutal.go`): на потери не реагирует вообще (`OnCongestionEvent` — stub); pacing `bps/ackRate`; `cwnd = bps × smoothedRTT × 2 / ackRate`; `ackRate` — компенсация потерь по 5 скользящим секундным слотам (мин. 50 сэмплов, пол 0.8); дебаг через `HYSTERIA_BRUTAL_DEBUG`.

**Вывод для sora:** brutal осмыслен только при измеренном реальном uplink; без измерения — BBR. Неправильный `up_mbps` = либо недожим, либо самоддос и лёгкий детект по агрессивному pacing. `disableLossCompensation` — ручка на случай шейперов с потерями.

**Port hopping** (`udphop/`): только клиентская фича. Адрес `"host:111,222,333"` / `"host:20000-50000"`; интервал случайный в `[min,max]`, **минимум 5s** (hard error), дефолт 30s; при хопе — новый `PacketConn`, QUIC переживает за счёт connection migration; сервер просто слушает на всех портах. Для верхних слоёв прозрачно. **Несовместим с TCP-mimic.** Помогает только против per-port троттлинга UDP — против blanket UDP-block бесполезен.

Ссылки: https://hysteria.network/docs/advanced/Port-Hopping/, код `apernet/hysteria/{core/internal/congestion/brutal/brutal.go,extras/transport/udphop/conn.go}`.

---

## 9. AmneziaWG: точная семантика параметров (amneziawg-go)

**Порядок при handshake** (`device/send.go`): сначала I-пакеты (`ipackets[0..4]`), затем `Jc` junk-пакетов, затем initiation с префиксом `S1`.

- `Jc` (1–128): число junk-пакетов **перед** handshake. `Jmin`/`Jmax`: размер каждого = `min + rand(max-min)`, содержимое — чистый `rand.Read`. Сервер их молча дропает (нет magic header). Могут различаться у пиров.
- `S1`/`S2`/`S3`/`S4`: байт случайного префикса **перед** пакетом: init / response / cookie / transport. На приёме отрезается по известной обеим сторонам длине — **должны совпадать** у клиента и сервера. Ограничения из кода: S1 ≤ 1132, S2 ≤ 1188, **S1+56 ≠ S2** (иначе неоднозначность длины init/response!), S3 ≤ 1216, S4 ≤ 32.
- `H1`–`H4`: замена 4-байтного type-id WireGuard на случайное значение из **диапазона** `[min,max]` (v2; в v1 — фиксированное). H1≠H2≠H3≠H4. Проверка на приёме — ранний дроп чужих пакетов. Диапазон 5–2147483647.
- `I1`–`I5`: цепочки обфускации — DSL тегов `<b> <t> <r> <rc> <rd> <d> <ds> <dz>` (bytes, timestamp, random, rand chars, rand digits, data, data-string, data-size). `newObfChain()` в `device/obf.go` парсит теги. Это «сигнатурные» пакеты для имитации другого протокола (пресеты QUIC/WebRTC).
- **Критично:** все параметры, кроме `Jc`/`Jmin`/`Jmax`, должны совпадать у клиента и сервера, иначе handshake не сойдётся.

**Вывод для sora:** валидатор конфигов должен проверять `Jmin<Jmax`, `S1+56≠S2`, уникальность H1–H4, лимиты S; пресеты «под QUIC/WebRTC» — это I-цепочки, их можно генерировать.

Ссылки: код `amnezia-vpn/amneziawg-go/device/{obf.go,uapi.go,send.go,noise-protocol.go}`; параметры: https://docs.gl-inet.com/router/en/4/faq/amnezia_obfuscation_parameters/.

---

## 10. JA4 — спека для честного stealth-check

Первоисточник: `FoxIO-LLC/ja4`, `technical_details/JA4.md`.

**Алгоритм (клиентский JA4 = `a_b_c`):**
- `a` = `(t|q|d)` [TCP/QUIC/DTLS] + версия 2 chars (`13`/`12`/…; брать max из ext `0x002b`, иначе legacy version; handshake version игнорировать) + (`d`|SNI есть|`i`) + число шифров 2 chars (cap 99) + число расширений + первый+последний ASCII-alnum char **первого** ALPN (нет — `"00"`; не-alnum — hex).
- `b` = `sha256(шифры hex строчными через запятую, **отсортированные**)[:12]`.
- `c` = `sha256(расширения отсортированные **без 0000 (SNI) и 0010 (ALPN)** + `_` + sigalgs **в исходном порядке**)[:12]`.
- **GREASE игнорировать везде**; SCSV (`0x00FF`, `0x5600`) и experimental — считать; пустые списки → `"000000000000"`.
- Raw-режимы: `JA4_r` (отсортированные списки открытым текстом), `JA4_o` (исходный порядок, с SNI/ALPN) — для диагностики «почему отличается».

**Вывод для sora (диагностика):** вычислить JA4 собственного ClientHello (uTLS-паррота / `crypto/tls`) и сравнить с эталонными JA4 Chrome/Firefox/Safari — несовпадение = провал стелса, `JA4_o` покажет причину. Важно: сортировка в JA4 нейтрализует шафл шифров Go — «go-шный» JA4 стабилен и узнаваем, маскировка требует именно паррота, а не рандомизации.

Ссылки: https://github.com/FoxIO-LLC/ja4/blob/main/technical_details/JA4.md.

---

## Сводка решений для sora (без воды)

| # | Решение |
|---|---------|
| 1 | MASQUE: CONNECT-UDP реализуем сам (1–2 нед., quic-go); CONNECT-IP — позже, объём ×2–3. Xray `masque/` — референс флоу. |
| 2 | ECH: брать `ECHConfig` из HTTPS-RR `ech` (или DoH), кэшировать с expiry; **fail-closed** при отсутствии конфига (как Xray); без защищённого DNS ECH не включать. ECH-протокол = RFC 9849, не 9848. |
| 3 | sing-box TUN: убрать `stack`, `gso`, `inet4_*` из генерируемых конфигов; MTU-дефолты не трогать (Android 9000). |
| 4 | XHTTP: тайминги Xray — референс; REALITY: свой код не писать; в аудите смотреть `Show` и версию в SessionId. |
| 5 | uTLS: следить за `refraction-networking/utls` (не старым URL); свежесть проверять JA4-сверкой паррота с эталоном браузера. |
| 6 | Bounded-поиск а-ля Geneva: (триггер, дерево из drop/tamper/duplicate/fragment), двойная оценка с min, штрафы только при успехе, Hall of Fame, мутации из pcap; бюджет считать как популяция × поколения × 2. |
| 7 | OONI: тянуть `/aggregation/observations` + `/analysis` + `/detector/changepoints`, кэшировать; лимит 10/мин/IP — нужен кэширующий слой, не прямые запросы из клиента. |
| 8 | Hysteria2: brutal только при измеренном uplink (иначе BBR); port hopping — интервал ≥5s, дефолт 30s, несовместим с TCP-mimic. |
| 9 | AmneziaWG: валидировать `Jmin<Jmax`, `S1+56≠S2`, уникальность H1–H4, лимиты S; всё кроме J* — синхронно с сервером. |
| 10 | JA4: встроить подсчёт в диагностику; эталон — JA4 реального браузера; `JA4_o` для разбора расхождений. |
