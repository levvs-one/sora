# PASS1-DEEP-RESEARCH — проход 1/3: свежие находки после DEEP-RESEARCH-70

Дата: 2026-10-20. База: DEEP-RESEARCH-70.md. Метод: первичные источники — changelog'и sing-box/Xray/Hysteria, issue-трекеры (XTLS/Xray-core #7131, #7169; apernet/hysteria #1702/#1703), официальные доки AmneziaWG/XTLS, полевые замеры RU (октябрь 2026). Локальная проверка кода sora — ветка `bugfix/audit-2026-10-19`.

**Слоп-фильтр:** в отчёт попало только то, что меняет код, конфиг или пины sora. Отсечённое — в конце с причинами.

---

## S-TIER

### S1. Пин Xray 26.3.27 несёт Chrome 133 parrot — в RU он заморожен ТСПУ; фикс 155 ещё не в релизе
- **Что:** Issue XTLS/Xray-core #7131 (открыт 11.10.2026): vendored uTLS в релизных Xray по-прежнему мапит `chrome` → Chrome **133**. Полевой замер FunLay123 на Yota mobile (13.10.2026, siberian-check, uTLS ff1b50f): Chrome 133 → «Siberian restriction: YES, TLS handshake timeout 8426 ms»; Chrome 155 → OK (733 ms); Firefox 148 → OK; QQ → OK. RPRX подтвердил: ТСПУ лимитит число соединений с фингерпринтом Chrome 133. Коммит e5a6911 (16.10.2026) «Bump uTLS to ff1b50f, add hellochrome_155 fingerprint» ушёл в main, **но не в релиз**; RPRX (12.10): «добавим перед следующим релизом (~2 недели), если uTLS не зарелизится раньше».
- **Источник:** https://github.com/XTLS/Xray-core/issues/7131
- **Действие для кода:**
  1. НЕ поднимать пин Xray вслепую: бамп до релиза, содержащего e5a6911 (ожидается v26.9.x-конец октября/26.10.x), с проверкой, что имя `chrome155` зарегистрировано в fingerprint map этой сборки.
  2. Рендер Xray REALITY/TLS: имя фингерпринта — version-gated. На пинах < релиза-с-155 явное `chrome155` упадёт как unknown fingerprint; голое `chrome` = 133 = заморозка. Наш `core/engine/fingerprint.go` уже различает DefaultXrayFingerprint / DefaultFingerprint — добавить в capability-каталог Xray флаг `chrome155Parrot` по версии и валидацию в `validate.go`: Xray-пин без 155-parrot + RU-профиль → warning «fingerprint chrome на этом ядре = Chrome 133, заморожен ТСПУ», предлагать firefox/qq из FreezeFingerprintRotation.
  3. CI-гейт свежести (`TestCoreUTLSFreshnessGate`) дополнить проверкой именно движкового бинаря Xray, а не только core-utls: наши пин utls ff1b50f уже содержит 155, но пользовательский Xray от этого не свежеет.

### S2. Upstream sing-box 1.15.0 stable НЕ СУЩЕСТВУЕТ — наш MinVersion указывает на альфу
- **Что:** Официальный changelog (свежая выгрузка 20.10.2026): последняя stable — **1.14.3**; ветка 1.15 — на стадии **1.15.0-alpha.12**. В `core/engine/catalog.go:58` для upstream sing-box стоит `MinVersion: "1.15.0"` — версии, которой нет в stable-канале. sing-box-lx (1.14-база, `1.14.3-lx.14`) при этом корректен.
- **Источник:** https://sing-box.sagernet.org/changelog/
- **Действие для кода:** `catalog.go`: upstream sing-box MinVersion → `1.14.3` (stable) ИЛИ явный alpha-канал с отдельным capability-набором. Заодно зафиксировать в каталоге: фичи, которые есть ТОЛЬКО в 1.15-alpha (MASQUE endpoints, см. A2), нельзя гейтить на «sing-box ≥1.15.0», пока нет stable — для них единственный носитель сейчас lx-форк (свой MASQUE-бэкпорт) и mihomo (см. A3).

### S3. sing-box 1.16 удаляет ещё три вещи из нашего рендера — проверить до бампа пина
- **Что:** Из changelog 1.14.0 (финальный список deprecation'ов с удалением в 1.16.0):
  - `independent_cache` (DNS) и `store_rdrc` (cache file) → замена `optimistic` + `store_dns`;
  - legacy fallback remote rule-set (default outbound при пустом `http_clients`) + `download_detour` — **у нас уже мигрировано** (`render.go:570-585`: `http_clients` + `default_http_client`), действие не требуется, только регрессионный тест;
  - legacy DNS rule address-filter поля (`ip_cidr`/`ip_is_private` без `match_response`), legacy `strategy` DNS rule action, `rule_set_ip_cidr_accept_empty`; смешивание legacy+новых полей в одном DNS-конфиге **отклоняется на старте**;
  - Hysteria **v1** tuning-поля (`recv_window_conn`, `recv_window`, `recv_window_client`, `max_conn_client`, `disable_mtu_discovery`) — удаляются в 1.16.
  - TUN `stack` удаляется в **1.17** (на 1.16 уже нужен `ENABLE_DEPRECATED_TUN_STACK=true`) — из раунда 1 (S1), не закрыто ли в рендере — проверить.
- **Источник:** https://sing-box.sagernet.org/changelog/ (раздел 1.14.0, пункты 12/15/22/23), https://sing-box.sagernet.org/migration/
- **Действие для кода:** grep-аудит `core/engine/singbox/render.go` + шаблоны: `independent_cache`, `store_rdrc`, `"stack"`, DNS-правила с `ip_cidr` без `match_response` (найденный `ip_cidr` на render.go:615 — route-правило, НЕ legacy DNS — чисто), Hysteria v1 мы не рендерим (чисто). Добавить `sing-box check` в CI против 1.16-совместимого снапшота схемы при появлении 1.16-alpha.

### S4. Hysteria2: PR #1703 (stall-фикс) всё ещё НЕ смержен; вместо него — 2.8.x линия
- **Что:** Отчёт colitu lab (15.10.2026): баг «hy2 встал после upload speedtest» (QUIC window exhaustion) — PR apernet/hysteria #1703 (stall timeout, дефолт 10 с) и клиентская половина Xray-core #7169 (cancel стрима освобождает окно) по состоянию на 16.10.2026 **оба открыты, не смержены**. Рекомендация раунда 1 «требовать сервер с фиксом #1703» невыполнима — такого релиза нет. Параллельно апстрим выпустил: **2.8.0** — конфигурируемый congestion control (`bbr`/`reno` + BBR-профили `standard`/`conservative`/`aggressive`), рандомизированный hop-интервал (`minHopInterval`/`maxHopInterval`), server-side port-range listening; **2.8.1** — краш сервера при BBR/Reno от клиентских подключений (важно: one-click серверы на 2.8.0 уязвимы); **2.7.0** — фикс BBR oversend; **2.7.1** — speed test по умолчанию time-based 10 с.
- **Источники:** https://lab.colitu.com/research/hysteria2-stall-after-upload , https://hysteria.network/docs/Changelog/
- **Действие для кода:**
  1. One-click деплой: минимальная версия сервера hy2 → **2.8.1** (не «с #1703»); в диагностике stall-сценария ссылаться на #1703/#7169 как известные открытые баги апстрима.
  2. Клиентский stall-watchdog (S4 раунда 1: «established, 0 байт при спросе 15–20 с → реконнект») остаётся единственным работающим средством — приоритет не снижать; порог сверен с патчем #1703 (10 с): наш watchdog ставить на **10–12 с**, не 15–20.
  3. Рендер hy2 (sing-box): апстрим sing-box 1.14 уже поддерживает `bbr_profile`, `hop_interval_max`, obfs `gecko` — прокинуть в plan/render (сейчас рендерятся только базовые поля + `hop_interval`); валидация: `hop_interval_max >= hop_interval`.

### S5. AmneziaWG 3.1: официальная спека финализирована — в ней жёсткие инварианты, которых нет в нашем валидаторе
- **Что:** docs.amnezia.org (AmneziaWG, актуальная редакция под 3.1):
  - Диапазоны **H1–H4 не должны пересекаться**;
  - Header Protection: nonce = первые 12 байт S-префикса ⇒ **S1–S4 ≥ 12** и `HeaderProtectionKey` задан; при включённом Header Protection рекомендуется **H1=1, H2=2, H3=3, H4=4** (кастомные заголовки отключаются);
  - При `RandomTrailers` рекомендуется **S1=S2=S3=S4** (иначе риск неверного детекта типа пакета);
  - Тайминги (`RekeyAfterTime`, `RekeyTimeout`, `RejectAfterTime`, `KeepaliveTimeout`, `MaxHandshakeAttempts`) — **диапазоны** `range<uint16>`, не скаляры;
  - `DisableCookies` отключает только ОТПРАВКУ Cookie Reply; входящие обрабатываются как раньше;
  - CPS-теги I1–I5: `b` (hex), `t` (timestamp), `r` (≤1000), `rc` (≤1000), `rd` (≤1000).
- **Источник:** https://docs.amnezia.org/documentation/amnezia-wg/
- **Действие для кода:** `core/engine/validate.go` + `core/wgobfusc/generate.go`: добавить инварианты выше как ошибки/варнинги валидации AWG 3.1; генератор «диалектов» — пресеты I1 из CPS-тегов с лимитами. Наш гейт движка уже корректен (`d24_awg3_test.go`: 3.1-план не падает на mihomo, требует sing-box-lx `with_awg`) — но публичное описание lx-форка (L×Box) заявляет «AmneziaWG 2.0»; **перепроверить, что `with_awg` в поставляемой сборке lx реально применяет 3.1-параметры** (HeaderProtectionKey и тайминг-диапазоны), а не молча их режет — иначе это случай S5 раунда 1 (обман пользователя). Тест: рендер 3.1-конфига → `sing-box check` + сверка полей на выходе lx-бинаря.

### S6. AnyTLS: sing-box по умолчанию больше не шлёт client metadata (профилирование вендорами)
- **Что:** sing-box 1.13.16 / 1.14.0-beta.5: «Remove client metadata from AnyTLS requests by default» — метаданные не используются open-source сервером, есть репорты о профилировании/дискриминации пользователей вендорами по ним; теперь пусто по умолчанию, кастомизируется опцией AnyTLS client metadata.
- **Источник:** https://sing-box.sagernet.org/changelog/ (1.13.16, 1.14.0-beta.5)
- **Действие для кода:** наш sing-box рендер метаданные не ставит (проверено: `render.go:319-320` — только type+password) — кода не требуется; убрать из UI/доков любые упоминания client-id для AnyTLS и НЕ добавлять поле metadata в plan (защита от регрессии — тест «anytls render не содержит metadata»).

---

## A-TIER

### A1. Xray: каноническая схема streamSettings теперь `method` + `xhttpSettings`/`rawSettings`
- Официальные доки XTLS (актуальная редакция): `streamSettings.method: "raw"|"xhttp"|"mkcp"|"grpc"|"websocket"|"httpupgrade"|"hysteria"`, транспортные объекты переименованы (`splithttpSettings`→`xhttpSettings`, TCP→`rawSettings`). Legacy `network` пока принимается (свежие гайды октября 2026 используют `network` с текущим Xray), но документация его больше не показывает. Наш рендер пишет только legacy-форму (`render.go:278-296`).
- **Действие:** при бампе пина на 26.9.x+ — рендерить `method`+новые имена объектов, legacy держать для старых пинов (version-gated, как xrayPlaintextCutoff); добавить в CI прогон `xray run -test` по всем шаблонам на целевом пине. Отдельно: 3x-ui делает автоматический «XHTTP lifting» legacy-полей `sessionPlacement`/`sessionKey` под новые имена — проверить имена в Xray 26.9 при бампе и не эмитить legacy-имена из нашего plan (точные новые имена в открытых источниках не раскрыты — помечено «требует проверки на пине», не выдумывать).

### A2. sing-box 1.15-alpha: нативный MASQUE + полное пинование сертификатов — план на stable
- 1.15.0-alpha.7: MASQUE client/server endpoints (CONNECT-IP, HTTP/1.1+H2+H3, address assignment, route advertisement), переписанный HTTP proxy (H2/H3, CONNECT-UDP), TLS-опции `certificate_sha256`/`client_certificate_sha256` (полный пин сертификата в дополнение к public-key pinning). alpha.9: NaiveProxy обновлён до **154.0.8037.49-2** (в stable 1.14 — 150.0.7871.63-2). alpha.8: route/DNS rule items `dns_server_address`/`dns_search_domain`.
- **Действие:** A3 раунда 1 (MASQUE) на stable 1.15 получит второй носитель (sing-box) в дополнение к Xray/mihomo; не начинать, пока 1.15 не выйдет в stable (см. S2). `certificate_sha256` — добавить в TLS-план как усиление `pinnedPeerCertSha256` при доступности движка ≥1.15.

### A3. mihomo 1.19: MASQUE outbound и новые адаптеры уже в линейке
- В кодовой базе mihomo-линейки 1.19 присутствуют `adapter/outbound/masque.go` + `transport/masque` (клиент H2/H3), а также OpenVPN, Tailscale, Sudoku, Mieru, ShadowQUIC адаптеры и ECH в listener'ах. Пин sora — 1.19.32 (bridge min в `registry.go:31`); в дикой природе видны ядра до 1.19.30+ — сверить точный последний тег при следующем бампе (открытая выдача точный тег не подтвердила).
- **Действие:** проверить MASQUE-адаптер именно в MetaCubeX upstream (deepwiki-выборки — по форкам xinebf/hooraygith), после подтверждения — capability `FeatureMASQUE` для KindMihomo и рендер MASQUE-ноды через mihomo как fallback, когда нет Xray/lx. Sudoku/Mieru — не рендерить (нет в плане протоколов sora; слоп-фильтр).

### A4. Xray 26.7.28: «legacy reverse» удалён — валидатор должен резать reverse-конфиги с понятной ошибкой
- FreshPorts/ports: на 26.7.28 конфиги с legacy reverse падают на старте («The feature "legacy reverse" has been removed and migrated to "VLESS Reverse Proxy"»). Полные Xray JSON-профили от провайдеров могут содержать `reverse` — на новом пине движок просто не стартует.
- **Источник:** https://www.freshports.org/security/xray-core/ (commit 26.7.28_1)
- **Действие:** `validate.go`: при импорте полного Xray-профиля с `reverse` и пине ≥26.7.28 — ошибка с текстом апстрима и подсказкой про VLESS Reverse Proxy, а не молчаливый fail запуска.

### A5. zapret v72.x: три новые оси desync отсутствуют в геноме нашего Geneva-тюнера
- zapret v72.2 (mirror SourceForge): nfqws `--wssize-forced-cutoff=0`, манипуляция TCP-флагами `--[orig|dup|dpi-desync]-tcp-flags-[set|unset]`, `--dup-ip-id` для дублированных пакетов. Линейка дошла до v72.6. В `core/tune/desync/params.go` этих осей нет (только методы/split/fooling/fake/ttl/repeats).
- **Действие:** добавить три оси в пространство поиска тюнера (nfqws-only, как repeats), сиды не трогать.

### A6. uTLS: тега свежее ff1b50f нет, Chrome 155 — текущий потолок; sing-box тащит uTLS v1.8.7
- uTLS не выпускал тега новее нашего пина pseudo-версии `v1.8.3-0.20261006222701-ff1b50fbbe9a` (Chrome 155 parrot); sing-box 1.14.0 в чейнджлоге заявляет «Update uTLS to v1.8.7» (свой вендоринг SagerNet — при аудите lx сверять именно его). CVE-2026-27017 (GREASE ECH) закрыт с 1.8.1 — мы выше.
- **Действие:** пинов не трогать; в freshness-гейт добавить ожидание `HelloChrome_156` как триггер следующего бампа (комментарий в `ja4_test.go:51-54` это уже предусматривает).

### A7. Hysteria2 в sing-box 1.14: Chrome QUIC parrot по умолчанию ломает Ed25519-серверы
- sing-box 1.14.0-beta.7/финал: hy2-клиент по умолчанию parrot'ит Chrome QUIC handshake; Chrome не декларирует Ed25519 ⇒ серверы с Ed25519-сертификатами падают на хендшейке; лечится `disable_chrome_parrot`.
- **Источник:** https://sing-box.sagernet.org/changelog/ (1.14.0, п.11)
- **Действие:** диагностика hy2: ошибка хендшейка + Ed25519-сертификат сервера (виден из TLS) → подсказка/авто-фолбэк `disable_chrome_parrot: true` в рендере для таких нод.

---

## Наши внедрения vs реальность

### Geneva-тюнер (`core/tune/desync`) — стратегии актуальны, но тюнер всё ещё не подключён
- Сам Geneva-подход жив: движок Geneva в проде у Psiphon и TunnelBear, тема доклада SCaLE 2026 «History and Future of Censorship Evasion» (март 2026). Досье Geneva как проекта новых стратегий не публикует — актуальность определяется геномом zapret, а не Geneva.
- Оси сидов (split/disorder/tlsrec/fake+autottl/fooling md5sig/badseq, QUIC fake repeats) соответствуют текущему nfqws v72.x. Пробелы — A5 (tcp-flags, dup-ip-id, wssize-forced-cutoff).
- Честный статус из `doc.go`: **NOT WIRED — prototype, no production callers**. Заявление «Geneva-тюнер внедрён» верно только про код прототипа; подключение — отдельное решение владельца (в паре с миграцией tpws→nfqws из S9 раунда 1: половина генома nfqws-only и на tpws-исполнителе не выполнится).

### FreezeDetector (`core/probe/freeze.go`, `core/censor/siberian.go`) — пороги ПОДТВЕРЖДЕНЫ полем, менять не надо
- Свежие данные (октябрь 2026): Habr-замер, цитированный в Xray #7131, — 3 одновременных Chrome-соединения проходят, **4 → заморозка 120 с**; замер FunLay123 на Yota — Chrome 133 заморожен, 155/Firefox/QQ проходят.
- Наши константы: `freezeParallelThreshold = 3` (stall при Concurrent > 3, т.е. ровно ≥4 — совпадает), `freezeBackoff = 120s` и обязательный quiet period ≥120 с в siberian.go (совпадает с измеренной длительностью заморозки), эскалация при 6. **Вердикт: пороги актуальны, правок не требуется.** Единственное дополнение — в ротацию `FreezeFingerprintRotation` первым кандидатом после заморозки на Xray-пине без 155-parrot не должен попадать `chrome` (см. S1).

### JA4 self-test (`core/diagnostics/ja4.go`) — формула НЕ менялась
- Спецификация FoxIO JA4 в 2026 ревизий не получала (страница JA4+ без изменений; новых версий метода не анонсировано). Наша реализация соответствует спеке: JA4_b/JA4_c = sha256[:12] от сортированных списков с GREASE-strip, SNI/ALPN в JA4_a. `ReferenceChromeJA4` + гейт на HelloChrome_155 актуальны: 155 — текущий stable Chrome и текущий parrot uTLS. **Вердикт: self-test корректен, действие — только A6 (следить за 156).**

### Fingerprint-модуль (`core/engine/fingerprint.go`) — ядро в порядке, дыра на стороне движка
- Наш core-utls пин = ff1b50f = тот же коммит, что Xray тащит в main для 155. `CurrentChromeParrot = HelloChrome_155` — верно. Реальная дыра — не наш модуль, а вендоренный uTLS пина Xray 26.3.27 (S1).

---

## Пины к обновлению

| Компонент | Сейчас в sora | Реальность на 20.10.2026 | Действие |
|---|---|---|---|
| Xray | 26.3.27 (MinVersion, catalog.go:79) | Вышли 26.7.28, 26.9.8, 26.9.9 (pre-release теги); main = 26.9.30; hellochrome_155 — в main, не в релизе | Ждать релиз с e5a6911, затем бамп + S1/A1/A4 одним заходом |
| sing-box upstream | MinVersion 1.15.0 (catalog.go:58) | Stable = 1.14.3; 1.15 = alpha.12 | MinVersion → 1.14.3 или явный alpha-канал (S2) |
| sing-box-lx | 1.14.3-lx.14 | Форк жив (L×Box: XHTTP stream-one, MASQUE, AWG), свежих тегов в выдаче не видно | Перепроверить with_awg против AWG 3.1 (S5) при следующем синке lx |
| mihomo | bridge min 1.19.32 (registry.go:31), catalog MinVersion 1.19.0 | Линейка 1.19 жива; точный последний тег выдачей не подтверждён (видны сборки 1.19.30) | Сверить тег на GitHub при бампе; MASQUE-адаптер — A3 |
| uTLS (core) | v1.8.3-0.20261006-ff1b50f | Тот же коммит — tip с Chrome 155; тега новее нет | Не трогать; триггер бампа — HelloChrome_156 (A6) |
| Hysteria (one-click сервер) | требование «фикс PR #1703» из раунда 1 | #1703 не смержен; актуальная линия 2.8.1 | Требование заменить на ≥2.8.1 (S4) |
| NaiveProxy (внутри sing-box) | как в пине движка | 1.14 → Chromium 150; 1.15-alpha → 154 | Учесть в чеклисте релиза: naive отстанет от Chrome stable (155) на всём stable-канале |

## Отсечено слоп-фильтром

- **TUIC «свежие изменения»** — rejected: релизов протокола/эталонной реализации в 2026 не найдено; активность только в клиентах (mihomo congestion_v2 унаследован от hy2). Менять в sora нечего; политика «только v5» из A12 раунда 1 остаётся.
- **«MASQUE невидимость»** — rejected повторно: MASQUE на Yota работает (поле из #7131), но это транспортный факт, не стелс-гарантия; в отчёт пошло только как capability/рендер (A2/A3).
- **Geneva upstream-стратегии 2026** — rejected: проект стратегий не публикует; источник актуальности — zapret (A5).
- **ECH/GREASE-новости uTLS** — rejected как действие: CVE-2026-27017 закрыт в нашем пине; новых ECH-изменений, меняющих fingerprint-модуль, не найдено.
- **Sudoku/Mieru/OpenVPN в mihomo** — rejected: протоколов нет в продуктовом плане sora; появление адаптеров в движке само по себе не повод для рендера.
- **Точные новые имена XHTTP session-полей (A1)** — не выдуманы: в открытых источниках раскрыт только факт переименования (3x-ui lifting); имена сверить на целевом пине по `xray run -test` и докам сборки.
