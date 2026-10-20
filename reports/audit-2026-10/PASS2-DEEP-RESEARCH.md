# PASS2-DEEP-RESEARCH — проход 2/3: только новое после PASS1-DEEP-RESEARCH

Дата: 2026-10-20. База: PASS1-DEEP-RESEARCH.md (6 S-tier) + PASS1-SUMMARY.md.
Метод: первичные источники, прочитанные в этом проходе целиком или до
исходника — changelog sing-box (полный, включая 1.14.0 пп. 12–34 и ветку
1.15-alpha), changelog Hysteria (вся линия 2.8.2–2.13.0, в проходе 1
остановились на 2.8.1), GitHub Releases Xray-core (новый тег v26.10.17) и
полный compare-патч `v26.10.10...v26.10.17` (22 коммита), GitHub Releases
mihomo (v1.19.30–v1.19.32), **исходники пинов**: tarball
`Leadaxe/sing-box-lx v1.14.3-lx.14` (тот самый тег, что в
`packaging/engines/engines.lock`) и tarball `MetaCubeX/mihomo v1.19.32`
(пин sora) — распакованы и прочитаны построчно в части AWG / XHTTP /
REALITY / utls. Локальная сверка кода sora — ветка
`bugfix/audit-2026-10-19`, tip `e60f9854`.

**Слоп-фильтр:** как в проходе 1 — только то, что меняет код, каталог,
пины или валидацию sora. Повторы прохода 1 (Chrome 133 в пине Xray,
sing-box 1.15 stable не существует, удаления 1.16, AnyTLS metadata,
MASQUE-alpha, zapret-оси) сюда не переписаны. Отсечённое — в конце.

**Итог одной строкой:** проход 1 в двух местах доверял публичным
описаниям движков вместо их исходников — и в обоих местах исходники пинов
говорят обратное: (1) mihomo **умеет** AWG 3.1, а гейт sora его за это
режет; (2) sing-box-lx по имени `chrome` шлёт **Chrome 133**, а не
«новейший parrot», как утверждает комментарий в нашем fingerprint.go.

---

## S-TIER

### S1. Гейт «mihomo не умеет AWG 3.1» — ЛОЖЬ против собственного пина: mihomo v1.19.32 реализует AWG 3.x полностью, sora зря отказывает в маршрутизации

- **Что:** В проходе 1 (S5) и в коде sora (`core/engine/d24_awg3_test.go`,
  комментарий «mihomo's AmneziaWG stack only knows the 1.x/2.0 keys»,
  `core/engine/mihomo/proxy.go:240-246` — жёсткий отказ рендера при
  `UsesAWG31()`) зафиксировано: 3.1-план на mihomo не должен попадать.
  Исходник пина это опровергает:
  - mihomo **v1.19.30** (changelog на странице релизов): `feat: support
    AmneziaWG v3.0`, `feat: support AmneziaWG v3.1`;
    **v1.19.31**: `fix: RandomPaddingAddition and DisableCookies for
    AmneziaWG v3`.
  - `adapter/outbound/wireguard.go` в v1.19.32: структура
    `AmneziaWGOption` содержит `version` («Only version 3 uses the v3
    implementation»), `header-protection-key`,
    `content-padding-addition`, `rekey-after-time`, `rekey-timeout`,
    `reject-after-time`, `keepalive-timeout`, `max-handshake-attempts`,
    `random-trailers` (v3.1+), `disable-cookies` (v3.1+). При
    `Version == 3` строится `amneziav3.NewDevice`
    (`github.com/metacubex/amneziawg-go/device`), иначе legacy
    `device_v1`. IPC-ключи эмитит те же, что lx:
    `header_protection_key=` (base64→hex конвертируется в конструкторе,
    как в lx), `content_padding_addition=`, …, `random_trailers=1`,
    `disable_cookies=1`.
- **Источники:** https://github.com/MetaCubeX/mihomo/releases
  (блоки v1.19.30 / v1.19.31); исходник пина
  `mihomo@v1.19.32:adapter/outbound/wireguard.go` (поля ~L103–141,
  выбор устройства ~L487–490, IPC ~L670–700).
- **Следствие для sora (конкретно):**
  1. `core/engine/catalog.go`: `Catalog[KindMihomo]` должен получать
     `FeatureAmneziaWG3` для версий ≥1.19.30 (сейчас фичи нет вообще;
     `Missing()` для 3.1-плана на mihomo возвращает её как недостающую —
     тест `d24_awg3_test.go` это ещё и **закрепляет как норму**).
  2. `core/engine/mihomo/proxy.go:amneziaOptions`: снять отказ и
     рендерить 3.x-ключи kebab-именами mihomo
     (`header-protection-key` и т.д.) + обязательно `version: 3` —
     без него mihomo молча строит legacy-устройство и 3.x-поля не
     применяются (та же ловушка «молчаливого даунгрейда», от которой
     отказ и защищал).
  3. План (`core/engine/plan.go:AmneziaWG`) поля `Version` не несёт —
     рендерер выводит `version: 3` из `UsesAWG31()`.
  4. **Граница честности:** сахар `id/ip/ib` (FeatureAmneziaMasquerade)
     в mihomo по-прежнему отсутствует (полей нет в структуре) —
     masquerade остаётся lx-only, этот гейт не трогать. J1/J2/J3/Itime
     в mihomo помечены «v1.5 only, removed in v2+» и с `version: 3`
     несовместимы — валидатор обязан резать комбинацию 3.x + J*
     для mihomo так же, как sing-box-рендер режет J* в принципе.
  5. Тесты: `d24_awg3_test.go` переписать (mihomo ≥1.19.30 несёт 3.1;
     mihomo <1.19.30 — по-прежнему нет: гейт становится
     **версионным**, а не «никогда»); добавить рендер-тест mihomo:
     3.1-план → YAML содержит `version: 3` и все девять 3.x-ключей;
     прогон `mihomo -t` на dev-машине.
- **Рекомендуемое действие:** исправить каталог + рендерер + тесты одним
  заходом; до исправления UI не должен обещать «3.1 только через
  sing-box-lx» — это уже неверно.

### S2. sing-box-lx: фингерпринт `chrome` = Chrome 133 (замороженный ТСПУ), Chrome 155 — только по явному имени `chrome_155`; наш комментарий в fingerprint.go про lx неверен

- **Что:** Та же болезнь, что S1 прохода 1 (пин Xray), но на втором
  движке — и проход 1 её не видел, потому что смотрел публичное
  описание L×Box, а не форк utls. В поставленном пине
  `v1.14.3-lx.14`:
  - `common/tls/utls_client.go:386-387`: `case "chrome_155": return
    utls.HelloChrome_155` с комментарием «`"chrome" stays 133`»;
  - `option/tls.go:249-250`: enum фингерпринтов расширен значением
    `chrome_155` (opt-in пресет из форка utls);
  - SPEC 118 в дереве форка: решение владельца lx от 2026-10-08 —
    `HelloChrome_Auto` в их форке **намеренно оставлен = HelloChrome_133**
    (у refraction Auto уже = 155); причины держать 155 opt-in:
    пресет 155 объявляет ML-DSA в `signature_algorithms`, но проверить
    ML-DSA-подпись форк не может (нужен `crypto/mldsa`, Go 1.27; форк
    стоит на Go 1.26.8), и расширение `trust_anchors` меняет выбор
    цепочки сервером. Статус SPEC 118 — implemented, в дереве lx.14
    код и страж-тесты присутствуют (проверено по tarball'у тега).
- **Источники:** исходник пина `sing-box-lx@v1.14.3-lx.14`:
  `common/tls/utls_client.go`, `option/tls.go`,
  `SPECS/TASKS/118-UTLS_CHROME_155/SPEC.md`,
  `common/tls/utls_firefox148_lx_test.go` (стражи: `chrome`/`""` =
  HelloChrome_133, `chrome_155` = HelloChrome_155).
- **Следствие для sora:**
  1. `core/engine/fingerprint.go:52-59`: комментарий «In sing-box,
     mihomo and Xray this alias resolves to utls.HelloChrome_Auto —
     the newest verified Chrome parrot» для lx **ложен**: Auto там =
     133. `DefaultFingerprint = "chrome"` на sing-box-пути в RU =
     тот же замороженный отпечаток, от которого проход 1 лечил Xray.
  2. `FingerprintWarning` (проход 1, S1) знает про пин Xray, но не про
     lx: нужен симметричный warning «на sing-box-lx `chrome` =
     Chrome 133» и предложение `chrome_155`.
  3. Имя `chrome_155` сейчас **не входит** в `KnownFingerprints`
     (список: chrome/firefox/safari/ios/android/edge/360/qq/random) —
     проверить путь импорта/валидации: если подписка принесёт
     `fp=chrome_155`, план не должен ни терять его, ни нормализовать
     в `chrome`. Рендерер sing-box имя прокидывает дословно
     (`render.go` utls-блок), т.е. чинить надо каталог имён и
     валидацию, не рендер.
  4. Дефолт **не** переворачивать молча на `chrome_155`: у opt-in есть
     документированная цена (ML-DSA-объявление без проверки,
     trust_anchors) — это решение уровня владельца/профиля RU,
     как и в lx. Для mihomo сверить отдельно: его utls — metacubex
     v1.8.7, где Auto по данным lx SPEC 118 тоже = 133 (тот же класс
     проверки, что S1 прохода 1 требовал для бинаря Xray; в этом
     проходе по исходнику mihomo имя `chrome_155` не подтверждено —
     не выдумывать, проверять на бинаре `mihomo -t` + захватом).
- **Рекомендуемое действие:** warning + пропуск `chrome_155` в
  каталог/валидатор + правка комментария fingerprint.go; JA4/freshness-
  гейт расширить захватом ClientHello именно lx-бинаря (аналогично
  действию 3 из S1 прохода 1, которое касалось только Xray).

### S3. REALITY: Xray ≥26.9.8 принимает только гибридный key share X25519MLKEM768; апстрим sing-box гибрид вырезал, lx вернул с ручкой `key_share` — у sora ни ручки, ни валидации отпечатков без гибрида

- **Что:** Это не VLESS Encryption (проход 1 его покрыл) — это
  рукопожатие самого REALITY:
  - lx FEATURE 017 (прочитана целиком): «Xray ≥ v26.9.8 принимает
    только ClientHello с гибридным key share `X25519MLKEM768` перед
    `X25519`; апстрим этот шар вырезал». Симптом отказа —
    `reality verification failed`, неотличимый от чужого ключа;
    сервер молча уводит на камуфляжный сайт.
  - Гибрид несут только пресеты `chrome`/`chrome_*`, `firefox`,
    `safari`. `edge`, `ios`, `android`, `360`, `qq` — **только
    X25519 → сервер ≥26.9.8 их отвергает**; `random` — 3 из 5,
    `randomized` — ~½. В Xray-клиенте граница та же.
  - Вторая тихая отсечка (lx задача 053): сервер с `minClientVer`
    (механизм активен с Xray v26.7.11+) режет клиентов ниже порога;
    lx объявляет в session id ровно `26.3.27`.
  - Ручка lx: `tls.reality.key_share` (`""`|`classical`|`hybrid`,
    `option/tls.go:257-262` в пине lx.14 — присутствует):
    `classical` вырезает гибрид (только серверы <26.9.8; нужен сетям,
    теряющим длинный ClientHello — гибридный ClientHello в 2–3 раза
    длиннее и уходит двумя TCP-сегментами), `hybrid` — явная ошибка,
    если пресет гибрида не несёт. Также lx применяет
    `fragment`/`record_fragment` к REALITY-рукопожатию (задача 088) и
    чинит панику на `short_id` длиннее 16 hex (задача 090: ошибка
    конфигурации вместо паники процесса).
  - Подтверждение со стороны Xray: в compare-патче
    `v26.10.10...v26.10.17` зависимость `github.com/xtls/reality`
    поднята до `20261014101318` — серверная библиотека REALITY
    продолжает ужесточаться уже после 26.10.10.
- **Источники:** исходник пина lx.14: `SPECS/FEATURES/017-REALITY/
  FEATURE.md`, `option/tls.go`, `constant/tls.go` (`RealityKeyShare*`),
  задачи 053/083/086/087/088/089/090;
  https://github.com/XTLS/Xray-core/compare/v26.10.10...v26.10.17
  (патч 08/22).
- **Следствие для sora:**
  1. `core/engine/plan.go` (структура TLS): нет поля KeyShare;
     `core/engine/singbox/render.go` (utls/reality-блок ~L382-392):
     `key_share` не рендерится. План с REALITY на sing-box-пути
     сегодня целиком зависит от пресета движка.
  2. `core/engine/validate.go`: нет предупреждения «отпечаток
     X не несёт X25519MLKEM768; серверы Xray ≥26.9.8 такой REALITY
     отвергнут» для `edge/ios/android/360/qq/random/randomized` —
     пользователь получает мёртвый узел без объяснения. Наш
     `KnownMissingPQKeyShare` существует, но смотрит только парроты
     **собственного** core-utls (diagnostics), не движковые пресеты
     sing-box/mihomo.
  3. На Xray-пути sora защищена лучше (свой клиент Xray), но пин
     26.3.27 как клиент к серверу ≥26.9.8: Xray-клиент гибрид несёт —
     действия не требуется, зафиксировать тестом при бампе пина.
- **Рекомендуемое действие:** добавить `TLS.KeyShare` в план +
  рендер в lx-блок reality + валидационный warning по набору
  отпечатков без гибрида (таблица из FEATURE 017); short_id >16 hex
  резать в нашем валидаторе уже сейчас (паника — свойство старых
  сборок, ошибка — дёшева).

### S4. Hysteria2: линия ушла 2.8.1 → 2.13.0 — два security-релиза, разрыв совместимости UDP и новый пол для one-click серверов; «требовать ≥2.8.1» из прохода 1 устарело

- **Что:** Проход 1 закрылся на 2.8.1. Полный changelog, прочитанный
  в этом проходе:
  - **2.8.2 (security):** OOM сервера через специально собранные QUIC-
    пакеты при включённом sniff; **разрыв совместимости: UDP
    forwarding не работает, когда клиент ≥2.8.2 соединяется со
    старым сервером** (TCP не затронут); серверы 2.8.2 совместимы в
    обе стороны → вывод: сначала серверы, потом клиенты.
  - **2.9.2 (security):** обход ACL для UDP-пакетов; OOM через
    неполные/огромные HTTP-запросы при sniff; обход ACL завершающей
    точкой в домене (`example.com.`); + Gecko obfs.
  - **2.9.3:** лимит длины CNAME-цепочки в резолвере; фикс
    nftables-редиректа при bind на конкретный IPv6.
  - **2.10.0:** ECH support; `bandwidth.disableLossCompensation`
    (выключение компенсации потерь Brutal).
  - **2.11.0:** Chrome QUIC parrot по умолчанию
    (`quic.disableChromeParrot`), quic-go v0.61.0.
  - **2.12.0:** mimic (маскировка под TCP, Linux); **BBR panic на
    путях с малым MTU**, введённый Chrome parrot в 2.11.0.
  - **2.12.1:** QUIC stateless reset — клиент после сна/idle
    переподключается сразу, а не по idle timeout (мобильный сценарий);
    **2.12.2:** ручка `quic.disableStatelessReset`.
  - **2.12.3:** `hysteria ech` — генерация ECH-ключей; фикс
    port-hopping правил на Linux (редиректили чужой исходящий UDP,
    ломали Realms).
  - **2.13.0:** sniff чинит много-пакетный QUIC ClientHello
    (ACL по домену снова применяется к современному QUIC);
    sing-tun обновлён до v0.9.6, **TUN `route.strict` удалён как
    недействующий**; Chrome QUIC parrot → **Chrome 154**;
    quic-go **v0.63.0**; фикс ложного «ECH not accepted» в логе при
    parrot.
- **Источник:** https://hysteria.network/docs/Changelog/
- **Следствие для sora:**
  1. One-click деплой (подсистема серверов sora): пол поднять
     **2.8.1 → 2.13.0**; порядок раскатки «серверы раньше клиентов»
     из ноты 2.8.2 — записать в процедуру обновления (клиент sora
     ходит через движки, но свои hy2-серверы обновляем мы).
  2. Диагностика: «UDP мёртв, TCP жив» на паре (новый клиент,
     старый сервер) — теперь известная подпись 2.8.2-разрыва, а не
     сеть; «BBR panic / малый MTU» — подпись 2.11/2.12. Добавить в
     диагностические подсказки hy2.
  3. Рендер hy2 (sing-box): имя ручки parrot в апстримном Hysteria —
     `quic.disableChromeParrot`, в sing-box — `disable_chrome_parrot`
     (проход 1, A7) — не смешивать при генерации серверных конфигов.
  4. Stall-история (проход 1, S4): клиентская половина Xray
     **смержена** — см. S5; серверный PR apernet/hysteria #1703 в
     changelog до 2.13.0 **не появился** (проверено полным чтением
     линии 2.8.2–2.13.0) — watchdog 10–12 с остаётся обязательным,
     «сервер с фиксом #1703» по-прежнему не существует.
- **Рекомендуемое действие:** бамп пола one-click + диагностические
  подписи + запись порядка раскатки; код клиента не трогать.

### S5. Xray v26.10.17 (вышел после прохода 1): клиентский stall-фикс смержен, gVisor-стек TUN заменён собственным, REALITY и Vision обновлены под Go 1.27.3+

- **Что:** Страница релизов Xray-core на 20.10.2026 показывает новый
  тег **v26.10.17** (все теги 26.x по-прежнему **Pre-release** —
  см. A5). Полный compare `v26.10.10...v26.10.17` — 22 коммита,
  из них бьющие по sora:
  - **Патч 17/22 (PR #7172):** «Hysteria client: Reset stalled writes
    when the connection is closed» — прямое закрытие
    XTLS/Xray-core#7169 (та самая клиентская половина hy2-stall из
    прохода 1, S4: `Close()` при зависшей записи делает
    `CancelRead/CancelWrite` вместо вечного ожидания окна).
    **Статус #7169 сменился с «открыт» на «исправлен в релизе».**
  - **Патчи 03/05:** Hysteria client — honor cancellation during
    dialing; release client map lock before cleanup.
  - **Патч 01/22 (PR #7130):** TUN inbound — **gVisor-стек удалён**,
    заменён встроенным lightweight TCP/IP стеком Xray
    (`stack_gvisor*.go` удалены, `tcp_lightweight.go` +999 строк);
    **патч 02/22:** TUN `autoSystemDnsToGateway`.
  - **Патч 08/22:** `xtls/reality` → 20261014 (см. S3).
  - **Патч 19/22 (PR #7176, issue #7162):** XTLS Vision —
    совместимость с **Go 1.27.3+** (перестройка VisionReader вокруг
    `**bytes.Buffer`; комментарий в диффе: прежний сброс буфера
    «may not be suitable for Go 1.27.3+»). Наш core собран на
    Go 1.27 (`core/go.mod`) — для dev-машины, собирающей Xray из
    исходников или гоняющей Vision interop-тесты свежим тулчейном,
    пин <26.10.17 на Go ≥1.27.3 — риск именно в Vision-пути.
  - Патчи 07/12: MASQUE client — XMUX (`maxConnections: 1` по
    умолчанию) и перевод WireGuard/MASQUE на встроенный стек;
    патч 11: XDNS finalmask — DoH; патчи 20/21: новый транспорт
    XDRIVE (в план sora не берём — слоп-фильтр, см. «Отсечено»).
  - utls-пин в этом compare **не менялся** — статус Chrome 155 в
    Xray (проход 1, S1) без изменений, e5a6911 в релиз по-прежнему
    не попал (в патче нет бампа utls). Фиксирую как проверку, не как
    находку.
- **Источник:** https://github.com/XTLS/Xray-core/releases ;
  compare-патч `v26.10.10...v26.10.17` (заголовки и диффы выше —
  по нему).
- **Следствие для sora:**
  1. `core/engine/xraytun` + `core/engine/tunroute`: предположение
     «Xray TUN = gVisor» при бампе пина мертво. Поведение
     lightweight-стека (MSS, ICMP, UDP full-cone — файлы в том же
     патче переписаны) перепроверять стендом, а не экстраполяцией
     с 26.3.27. Каталог (`catalog.go`: «Xray TUN does not install
     routes; engine/tunroute supplies them») дополнить
     `autoSystemDnsToGateway` в чеклист бампа.
  2. Бамп пина Xray (когда выйдет релиз с Chrome 155) теперь тянет
     **три** независимые перепроверки одним заходом: fingerprint
     (проход 1, S1), TUN-стек (этот S5) и REALITY-либу (S3).
     Зафиксировать чеклистом в engines.lock-комментарии при бампе.
  3. Диагностика hy2 через Xray: на пине ≥26.10.17 подпись
     «запись зависла при закрытии» — исправлена апстримом; на
     текущем пине 26.3.27 — наш watchdog по-прежнему единственная
     защита (не снимать).

### S6. lx-XHTTP: проход 1 объявил имена session*-полей «не раскрыты» — lx их реализовал и сверил с Xray поименно; каталог sora про lx-XHTTP врёт, рендер sing-box молча роняет xmux / x_padding / session

- **Что:** В пине lx.14 XHTTP — полный клиентский транспорт, а не
  «x_padding_bytes only» (комментарий в `catalog.go` у KindSingBox):
  - `option/v2ray_xhttp.go`: режимы auto/packet-up/stream-up/
    stream-one, `xmux` (пул включён всегда, как в Xray),
    `session_placement`/`session_key`, `seq_placement`/`seq_key`,
    `session_table`/`session_length`, `uplink_data_placement`/
    `uplink_data_key`/`uplink_chunk_size`/`uplink_http_method`,
    `x_padding_obfs_mode`/`x_padding_key`/`x_padding_header`/
    `x_padding_placement`/`x_padding_method`, `sc_max_each_post_bytes`,
    `sc_min_posts_interval_ms`, `no_grpc_header`.
  - `SPECS/TASKS/002-XHTTP_CLIENT_TRANSPORT/PARAM_MAP.md` — аудит
    поименно против Xray-core `transport/internet/splithttp`:
    Xray proto-имена — **`sessionIDPlacement` / `sessionIDKey`**
    (proto-поля 20/21), `seqPlacement`/`seqKey` (22/23); JSON-имя в
    экосистеме sing-box — snake_case выше. Это закрывает открытый
    пункт A1 прохода 1 («точные новые имена не выдумывать — сверить
    на пине»): имена теперь известны из исходника пина.
  - Тот же тег lx.14 чинит (SPEC 119, issue #36): `path` с query
    (`/?proxyip=…`) раньше уходил на провод как `/%3Fproxyip=…` —
    реле edgetunnel на Cloudflare Workers отдавали 502 на CF-сайты
    через 20–60 с. Теперь хвост после первого `?` — настоящий query.
    Заметка lx: парсеры ссылок лаунчера обязаны срезать `?…`-хвост
    у xhttp `path` на своей стороне. Наш парсер
    (`core/parser/parser.go:414`) кладёт `path` в план дословно —
    на lx.14 ядро само режет по `?` при построении запроса, но
    **валидация/нормализация пути в плане** хвоста не ожидает:
    сверить, что `path` с `?` не роняет другие движки (Xray-рендер
    пишет path как есть — у Xray `GetNormalizedPath` режет сам;
    mihomo — проверить).
- **Источники:** исходник пина lx.14: `option/v2ray_xhttp.go`,
  `option/v2ray_xhttp_xmux_range.go`, PARAM_MAP.md (SPEC 002),
  `docs-lx/releases/v1.14.3-lx.14.md` (SPEC 119/120),
  `SPECS/FEATURES/002-XHTTP/FEATURE.md`.
- **Следствие для sora:**
  1. `core/engine/catalog.go` (комментарий у KindSingBox: «the lx
     fork's xhttp transport has neither downlink splitting nor xmux
     reuse tuning (x_padding_bytes only)») — **неверен в обеих
     частях про xmux**; `FeatureXHTTPDownloadSplit` для lx при этом
     действительно отсутствует (downloadSettings-формы у lx нет —
     split делается отдельным outbound'ом, не полем транспорта) —
     разделить эти два утверждения в каталоге.
  2. `core/engine/singbox/render.go` (xhttp-кейс ~L440): рендерит
     только host/path/mode/headers (+ `max_early_data` во втором
     кейсе). `Transport.XPaddingBytes` **не рендерится ни одним**
     не-Xray рендерером (grep по singbox/mihomo — пусто), xmux-поля
     плана честно маршрутизируют план от sing-box через
     `FeatureXHTTPXmux` — но для lx это лишнее ограничение:
     lx xmux умеет. Итог сегодня: подписка с xmux/extra-настройками
     на sing-box-пути либо уходит на Xray без нужды, либо (при
     прямом рендере) молча теряет x_padding.
  3. Плану не хватает session/seq/uplink-полей как класса: импорт
     `extra=` (`core/parser/parser.go`, комментарий у
     extraDownloadSettings: «every other key inside extra (xmux
     tuning, session placement, ...) is ignored by the parser») —
     теперь это игнорирование бьёт по **рабочему** функционалу пина,
     а не по гипотетическому.
- **Рекомендуемое действие:** (а) исправить комментарий и гейтинг
  каталога: lx ≥1.14.3-lx.14 получает xmux-capability для sing-box-
  пути; (б) рендерить в lx-XHTTP: `x_padding_bytes`, `xmux`,
  session/seq placement из новых полей плана; (в) парсер `extra=` —
  поднимать session/xmux ключи в план вместо игнорирования;
  (г) регрессионный тест: `path` с `?proxyip=` проходит все три
  рендерера без `%3F`.

---

## A-TIER

### A1. AWG 3.1 в lx — вопрос прохода 1 «применяет или молча режет» ЗАКРЫТ по исходнику: применяет; но семантика `disable_cookies` в lx шире официальной спеки

- **Что:** Открытый пункт dev-машины из S5 прохода 1 можно снять без
  dev-машины для **транспортного слоя**: в пине lx.14
  `option/wireguard_awg.go` документирует все 3.x-поля;
  `transport/wireguard/device_awg.go` (`//go:build with_awg`)
  эмитит их в IpcSet-строки (`header_protection_key` base64→hex с
  проверками: 32 байта, не все нули, каждый S1–S4 ≥12 — с ошибкой
  на этапе `sing-box check`; ranged-ключи «N»/«N-M»; свитчи = `1`);
  `transport/wireguard/device_awg3_test.go` содержит вектор живого
  3.1-экспорта с полным ожидаемым IPC-текстом;
  `device_stub_awg.go` (сборка без `with_awg`) **отклоняет** любой
  AWG-конфиг явной ошибкой вместо тихого даунгрейда. Публичное
  «AmneziaWG 2.0» в описании L×Box — маркетинг, ядро по факту
  2.0+3.x (FEATURE 003 в дереве так и пишет: «2.0 / 3.x»).
- **Оговорки (честно):** (1) tarball релиза **не содержит**
  сабмодулей — реальное применение ключей живёт в
  `Leadaxe/wireguard-go-awg2-lx` (ветка `lx-awg2-v005`, replace в
  `go.mod` lx), по одному релизному tarball'у поведение
  send/receive не доказывается; доказательство уровня «конфиг не
  режется и уходит в устройство правильными ключами» — полное,
  уровня «пакет на проводе» — по-прежнему стенд. (2) Семантика:
  комментарий lx у `DisableCookies` — «never send **or demand**
  cookie replies (the under-load mac2 gate)», а официальная спека
  (проход 1, S5) — отключается только отправка, входящие
  обрабатываются как раньше. Расхождение lx ↔ спека ↔ наш
  `core/engine/plan.go` («stops sending Cookie Reply messages;
  incoming cookies keep working»): наш текст повторяет спеку,
  lx обещает больше. На совместимость клиент↔сервер не влияет
  (клиентская ручка), но UI-описание для lx-пути должно говорить
  «не шлёт и не требует», либо не обещать вовсе.
- **Источники:** исходник пина lx.14: `option/wireguard_awg.go`,
  `transport/wireguard/device_awg.go`, `device_awg3_test.go`,
  `device_stub_awg.go`, `.gitmodules`, `go.mod` (replace-блоки).
- **Действие:** закрыть пункт S5 прохода 1 как «транспорт — доказан,
  провод — стенд при следующем синке lx»; поправить текст
  DisableCookies в плане/UI под фактическую семантику движка.

### A2. sing-box 1.14: TUN `dns_mode=hijack` по умолчанию ставит платформенный перехват DNS — пересекается с собственными tunroute / kill switch / CheckDnsLeaks sora

- **Что:** Changelog 1.14.0, п. 19 (и alpha.21): на TUN inbound
  появились `dns_mode`/`dns_address`; дефолтный `hijack` теперь
  **сам** выставляет DNS интерфейсу платформы (systemd-resolved на
  Linux, per-interface DNS на Windows/Apple) и ставит платформенный
  перехват: iproute2-правило на Linux, **nftables DNAT** при
  `auto_redirect`, **WFP-фильтры на Windows при `strict_route`**.
  Дополнительно апстрим уже после 1.14.3 чинил «inconsistent DNS
  mode behavior without auto_route» (видно из синк-нот lx.12:
  коммит `tun: Fix inconsistent DNS mode behavior without
  auto_route` + sing-tun «Disable DNS mode by default without auto
  route») — т.е. поведение на конфигурации **как у нас** (Linux:
  `auto_route=false`, маршруты ведёт наш tunroute) у апстрима
  дрейфовало между 1.14.2→stable.
- **Источник:** https://sing-box.sagernet.org/changelog/
  (1.14.0 п. 19); lx-changelog в пине lx.14 (синк-ноты lx.12).
- **Следствие:** `core/engine/singbox/render.go:tun()` `dns_mode`
  не эмитит — действует дефолт движка, который теперь имеет
  собственные побочные эффекты на платформе. Риски: двойной
  перехват DNS (наш hijack-dns route-action + платформенный),
  WFP-фильтры движка рядом с нашим Windows kill switch
  (tailscale/wf в `core/go.mod`), systemd-resolved правки вне
  нашего crash-cleanup.
- **Действие:** явно рендерить `dns_mode` из плана (или
  задокументированно фиксировать значение) для sing-box-пути и
  прогнать CheckDnsLeaks-стенд на пине lx.14 на Linux и Windows;
  расхождение «без auto_route» учесть — наш Linux-кейс ровно он.

### A3. sing-box 1.14: семантика rule-set matching переписана (merged → только одиночный default) — молчаливая смена поведения пользовательских правил на бампе

- **Что:** Changelog 1.14.0, п. 14 (и beta.1): merged matching
  rule-set'ов теперь работает **только** когда rule-set содержит
  ровно одно `default`-правило без `invert`; любой другой
  referenced rule-set матчится как «other field» (любое его правило
  само по себе). Апстрим: «we do not consider this a breaking
  change — except for configurations that worked without their
  author understanding why». В проходе 1 этот пункт не попал
  (там были только deprecation-удаления 1.16).
- **Источник:** https://sing-box.sagernet.org/changelog/ (1.14.0
  п. 14).
- **Следствие:** наши встроенные remote rule-set'ы
  (`render.go`: geosite/geoip, одиночные категории) под удар не
  попадают. Под ударом — **импортированные полные sing-box
  профили** и пользовательские rule-set'ы с несколькими правилами,
  где автор (или генератор подписки) рассчитывал на слияние полей
  с внешней rule: после бампа на 1.14 такие конфиги меняют
  маршрутизацию без единой ошибки.
- **Действие:** в импортёр полных профилей добавить lint: rule,
  ссылающаяся на rule-set с >1 правилом / invert, + собственные
  поля поверх — warning с текстом про смену семантики в 1.14.

### A4. quic-go CVE-2026-40898 (QPACK trailer expansion, фикс 0.59.1): пины движков чисты, но Hysteria 2.7.1 из старых рекомендаций — уязвим; плюс CVE-2026-56862 в crypto/tls у mihomo

- **Что:** CVE-2026-40898 / GHSA-vvgj-x9jq-8cj9: до quic-go
  **0.59.1** HTTP/3 клиент и сервер строят `http.Header` для
  трейлеров, ограничивая только сжатую секцию QPACK, — peer
  раздувает декодированную секцию и исчерпывает память (DoS,
  CVSS High по NVD-агрегации). Сверка пинов на 20.10.2026:
  sing-box 1.14 — quic-go **v0.61.0** (changelog 1.14.0) — чист;
  lx.14 — `sagernet/quic-go v0.61.0-sing-box-mod.9` — чист по
  версии (mod-форк: фикс трейлеров унаследован от базы 0.61);
  mihomo 1.19.32 — quic-go 0.61.0 (бамп в 1.19.30) — чист;
  Hysteria — 2.7.1 сидел на **0.59.0 (уязвим)**, 2.9.3 — 0.60.0,
  2.11.0 — 0.61.0, 2.13.0 — 0.63.0. Xray тащит apernet/quic-go
  v0.61.1-линейку (по go.mod Xray main) — чист.
  Отдельно: mihomo v1.19.30 changelog — `fix: CVE-2026-56862 for
  crypto/tls`: наш пин 1.19.32 фикс включает; фиксирую как
  «проверено, закрыто пином», деталей CVE в этом проходе не
  разбирал — не раздувать.
- **Источники:** https://cvefeed.io/vuln/detail/CVE-2026-40898 ;
  https://hysteria.network/docs/Changelog/ (версии quic-go по
  релизам); https://github.com/MetaCubeX/mihomo/releases (1.19.30);
  changelog sing-box (1.14.0: quic-go v0.61.0).
- **Действие:** пол Hysteria из S4 (≥2.13.0) автоматически уводит
  от уязвимого 2.7.1; в freshness-чеклист пинов добавить строку
  «quic-go ≥0.59.1 у всех четырёх движков» — дёшево, ловит класс.

### A5. Supply chain пинов: все релизы Xray 26.x — GitHub Pre-release; lx собирается из четырёх форк-сабмодулей, которых нет в релизном tarball'е

- **Что:** (1) Страница релизов Xray-core: каждый тег 26.x
  (26.10.17 … 26.6.1) помечен **Pre-release** — «стабильного»
  канала у Xray фактически нет; наш engines.lock это молча
  принимает. (2) lx: `go.mod` пина содержит четыре `replace` на
  сабмодули-форки — `Leadaxe/wireguard-go-awg2-lx` (ветка
  `lx-awg2-v005`), `Leadaxe/sing-tun-lx`, `Leadaxe/gvisor-lx`,
  `Leadaxe/utls-lx`; README форка: «`--recurse-submodules` is
  required for every build. A clone without them does not
  compile». Релизный tarball GitHub сабмодули **не включает**
  (проверено распаковкой тега lx.14: каталоги пустые) — аудит
  поставленного бинаря по «исходнику тега» без рекурсивного клона
  невозможен; наш контроль — только sha256 бинаря в engines.lock
  (он есть и это правильно).
- **Источники:** https://github.com/XTLS/Xray-core/releases ;
  исходник пина lx.14: `go.mod`, `.gitmodules`, `README.md`
  (секция сборки, LX_TAGS).
- **Действие:** в engines.lock рядом с lx-строками зафиксировать
  коммиты сабмодулей тега lx.14 (gitlink'и видны в полном клоне) —
  чтобы следующий аудит форка не начинался с археологии; для Xray
  в OWNER-чеклист: «pre-release статус — осознанный», без кода.

### A6. lx `lx.mtu_align` (тот же тег lx.14): движок сам выравнивает размер QUIC-пакетов под detour/chain — пересечение с нашей логикой MTU цепочек

- **Что:** SPEC 120 / релиз lx.14: узел поверх IP-туннеля (detour,
  транзитивный detour, звено chain) получает `mtu` (wireguard/
  masque) или `initial_packet_size` +
  `disable_path_mtu_discovery: true` (hysteria2/tuic/hysteria) под
  ёмкость нижнего звена; дефолт — `clamp` (только понижать).
  Полевой повод (issue #37): hy2 через MASQUE/WARP умирал на
  IPv6-сервер (gVisor резал 1328-байтные пакеты под MTU 1280, WARP
  IPv6-фрагменты теряет; проходит ≤1232 байт payload). Заодно
  MASQUE-QUIC стартует с `InitialPacketSize = mtu+51` вместо
  константы 1242 (иначе первые ~6 RTT пакеты 1205–1280 байт молча
  дропались как DatagramTooLarge).
- **Источник:** исходник пина lx.14: `docs-lx/releases/
  v1.14.3-lx.14.md`, `docs-lx/lx-changelog.md` (SPEC 120/121).
- **Следствие:** `core/engine/singbox/render.go:wireguard()`
  ставит AWG/WG `mtu` 1280/1420 жёстко; наши цепочки (F8,
  FeatureChains) считают MTU сами. На lx-пути теперь **два**
  выравнивателя: наш рендер и пре-пасс движка — результат
  детерминирован (clamp только понижает), но диагностика
  «почему initial_packet_size 1232» будет удивлять без знания про
  `mtu_align`-лог (`mtu_align: <tag> <field> → <effective>`).
- **Действие:** ничего не рендерить; в диагностику цепочек
  добавить чтение `mtu_align:`-строк из лога движка; при ручном
  `initial_packet_size` в плане помнить про clamp.

### A7. mihomo 1.19.32: дефолтный TUN-стек сменён на `mips` — sora защищена явным рендером, кроме одного места, которое стоит перепроверить

- **Что:** v1.19.32 changelog: «change default IP stack mode to
  mips and support `congestion-controller` option for tun»,
  «default listener tun to mips stack»; v1.19.31: MSS-учёт TCP
  options в mipstack. Наш `core/engine/mihomo/rules.go:buildTun`
  стек рендерит **явно** (`orDefault(t.Stack, "mixed")`, на Windows
  без явного — `mips`), поэтому дефолт движка нас не двигает.
  Остаётся узкое место: plan-значение `mixed` на Windows-пользова-
  тельских профилях и `congestion-controller` (cubic/reno/bbr/
  bbr3, действует только на mips) — план такого поля не несёт.
- **Источник:** https://github.com/MetaCubeX/mihomo/releases
  (v1.19.32).
- **Действие:** кода не требуется; при следующем касании mihomo
  TUN — решить, нужен ли `congestion-controller` в плане
  (сейчас — нет: нет полевых данных, слоп-фильтр).

---

## B-TIER

### B1. sing-box 1.14: TLS `spoof` (поддельный ClientHello перед настоящим) и TLS-движки `windows`/`apple` — новая поверхность, которой у плана нет

- Changelog 1.14.0, п. 26: outbound TLS `spoof`/`spoof_method` +
  route action `tls_spoof`: перед настоящим рукопожатием шлётся
  forged ClientHello с whitelisted SNI против SNI-фильтров.
  Требует `CAP_NET_RAW`+`CAP_NET_ADMIN`/root (Linux/macOS),
  Administrator (Windows), ARM64-Windows не поддерживается.
  П. 27: TLS `engine: windows` (Schannel/SSPI, build ≥17763) и
  `apple` (Network.framework).
- Для sora: наш ответ SNI-фильтрам — TLS fragment / zapret, не
  spoof. Spoof конфликтует по привилегиям с нашей моделью
  (непривилегированный core + отдельный helper) и пересекается с
  fragment-семантикой. **Действие: не внедрять**; зафиксировать
  как осознанный отказ, чтобы следующий проход не «открывал»
  заново. Источник: changelog 1.14.0 пп. 26–27.

### B2. Hysteria ECH (2.10+) и sing-box ECH: наш ECH-план покрывает только TLS-outbound'ы

- Hysteria 2.10.0 добавил ECH, 2.12.3 — `hysteria ech` генерацию
  ключей/клиентского конфига, 2.13.0 — фикс ложного ECH-лога при
  Chrome parrot. Наш `ECHConfig` (`plan.go`) рендерится в
  sing-box TLS-блок и mihomo `ech: true` (проверено grep'ом), но
  серверная сторона one-click hy2 ECH не конфигурирует.
- **Действие:** B-очередь: ECH для one-click hy2-серверов — после
  S4 (сначала пол версии). Источник: Hysteria changelog.

### B3. Платформы — честные негативы и мелочи

- **WinTun:** новее 0.14.1 релиза на wintun.net не нашлось; пин в
  engines.lock актуален (перепроверено в этом проходе поиском —
  слабое доказательство, помечаю как «не нашлось», не «нет»).
- **Android:** sing-box 1.15.0-alpha.1 — `auto_redirect` полностью
  функционален на Android через root service графического
  клиента; Xray 26.10.17 переписал `tun_android.go` в составе
  lightweight-стека (S5). Для sora Android-приложения пока нет
  (решение владельца из прохода 1 висит) — это входные данные к
  нему, не задача. Источники: changelog sing-box (1.15-alpha.1);
  compare-патч Xray (патч 01/22).
- **Linux polkit/nftables:** новых изменений, бьющих по sora,
  кроме A2 (nftables DNAT — часть `dns_mode`/`auto_redirect`
  самого sing-box), в этом проходе не нашлось. Отдельный поиск
  по polkit/WFP дал только нерелевантный шум — фиксирую как
  «проверено, пусто», а не как находку.

### B4. Go-тулчейн: sing-box 1.14 требует Go ≥1.25, lx собран на Go 1.26.8, наш core — Go 1.27

- Changelog 1.14.0, п. 34: «sing-box 1.14.0 requires at least
  Go 1.25». lx-пин: `go.version` = go1.26.8. Наш core: `go 1.27`.
  Практический вывод один: dev-машина, собирающая lx из исходников
  для аудита (A5), не должна удивляться несовпадению тулчейнов;
  а Vision-риск Go 1.27.3+ — это S5, не здесь. Действия нет.

---

## Пины: дельта к таблице прохода 1

| Компонент | Было (проход 1) | Стало известно в проходе 2 | Действие |
|---|---|---|---|
| Xray | ждать релиз с e5a6911 | Вышел **v26.10.17** (pre-release): utls **без изменений** (155 в релиз не попал), зато #7169 закрыт, TUN-стек заменён, REALITY →20261014 | Бамп по-прежнему ждать; чеклист бампа расширен (S5) |
| sing-box-lx | 1.14.3-lx.14, «перепроверить with_awg» | Тот же тег: AWG 3.x **доказан по исходнику** (A1); `chrome`=133, есть `chrome_155` (S2); `key_share` есть (S3); xmux/session — полные (S6); `lx.mtu_align` (A6) | Пину оставаться; чинить каталог/рендеры sora |
| mihomo | 1.19.32, «сверить тег» | 1.19.32 — по-прежнему последний; содержимое оказалось богаче каталога: **AWG 3.0/3.1 с 1.19.30** (S1), CVE-2026-56862 закрыт, quic-go 0.61.0, TUN-дефолт → mips (A7) | Пин верен; гейт AWG3 — исправить (S1) |
| Hysteria (one-click сервер) | пол ≥2.8.1 | Линия — **2.13.0**; 2.8.2 ломает UDP со старыми серверами, 2.9.2 — security | Пол → **2.13.0**, раскатка серверы→клиенты (S4) |
| quic-go (транзитивно) | ≥0.59 (фрагментация) | CVE-2026-40898: пол **≥0.59.1**; у всех пинов 0.61+ | Чеклист (A4) |
| uTLS (core) | ff1b50f, потолок 155 | Без изменений; **но** движковые utls живут своей жизнью: lx Auto=133 (S2), metacubex 1.8.7 в sing-box/mihomo | Гейт свежести — на бинари, не на core (S2) |

## Что проход 1 объявил открытым — статус после прохода 2

| Пункт прохода 1 | Статус |
|---|---|
| S5: применяет ли lx `with_awg` параметры 3.1 | **Закрыт по исходнику пина** (A1): транспортный слой применяет, stub без тега — явная ошибка; провод — стенд |
| A1: точные имена XHTTP session*-полей | **Закрыты** (S6): Xray — `sessionIDPlacement`/`sessionIDKey`; lx/mihomo-экосистема — snake_case |
| S4: PR #1703 (серверный hy2 stall) | По-прежнему не смержен / в changelog до 2.13.0 отсутствует; **клиентский #7169 — закрыт в Xray v26.10.17** (S5) |
| S1: релиз Xray с Chrome 155 | По-прежнему нет (v26.10.17 utls не трогал) |
| Dev-машина: AWG 3.1 на проводе | Остаётся стендовым пунктом (A1, оговорка про сабмодуль wireguard-go) |

## Отсечено слоп-фильтром

- **TUIC «новое»** — повторно rejected: релизов протокола/референса
  в 2026 не нашлось; в движках TUIC едет на общих QUIC-параметрах
  sing-box 1.14 (п. 23 — унификация H2/QUIC), собственного изменения
  рендера sora это не требует (наш TUIC-рендер: congestion_control +
  udp_relay_mode — покрыто).
- **AnyTLS сверх прохода 1** — rejected: в mihomo 1.19.30 появился
  `client-metadata` config с «DON'T sent by default» (та же политика,
  что S6 прохода 1, нового действия нет); 1.19.32 — race-фикс
  idleSession у AnyTLS listener'а (движковый багфикс, рендер не
  трогает).
- **XDRIVE (Xray, патчи 20/21 compare)** — rejected: новый транспорт
  апстрима без полевой истории и без запроса в плане протоколов
  sora; появление в движке ≠ повод для рендера (тот же принцип, что
  Sudoku/Mieru в проходе 1).
- **CVE-2026-26995 (uTLS, HelloChrome_120 padding)** — rejected
  как действие: CVE формально **отклонён** программой CVE, затронут
  только пресет Chrome 120, который sora нигде не выбирает
  (дефолты — Auto/155-путь). Зафиксировано, чтобы не всплывал
  «новой критической CVE в utls».
- **CVE-2026-21435 (webtransport-go, hang на закрытии сессии)** —
  watch, не действие: sora core зависимости не имеет (go.mod
  проверен); вендоринг внутри бинарей движков из открытых
  источников не подтверждается и не опровергается — при следующем
  аудите бинарей проверить `go version -m`.
- **sing-box 1.15 новый TCP/IP стек (alpha.3) «значительно
  быстрее/экономичнее»** — watch: заявление changelog'а без
  независимых замеров; наш рендер к 1.15 уже готов (stack не
  эмитится, multi_queue на Linux есть) — пересматривать только по
  замерам на dev-машине после stable.
- **OpenVPN/OpenConnect/Snell/Tailscale в sing-box 1.14** —
  rejected повторно по принципу прохода 1: протоколов нет в
  продуктовом плане sora.
- **Android 16 «VPN bug» из потребительской прессы** — rejected:
  единственный источник — пересказ без CVE/трекера Google; в отчёт
  не беру, к B3 не относится.

---

*Код не трогался, коммитов нет — как заказано. Все утверждения про
исходники пинов проверяемы локально: tarball'ы тегов
`sing-box-lx v1.14.3-lx.14` и `mihomo v1.19.32` (файлы и строки
указаны в тексте), compare-патч Xray `v26.10.10...v26.10.17`.*
