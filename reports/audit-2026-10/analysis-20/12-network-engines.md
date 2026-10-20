# Аналитик №12: сеть и движки (core/engine, core/guard, core/bypass, core/probe)

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`. Read-only анализ.
Важно: во время анализа параллельный агент активно правил эту же зону (uncommitted-изменения:
пин sing-box 1.15, MTU 1500, удаление `stack`, ECH query_server_name, Naive outbound,
FeatureHy2PortHop). Ниже — состояние рабочего дерева на момент анализа; там, где работа
в полёте, это помечено отдельно, чтобы не дублировать.

## Вердикт

Сетевой слой спроектирован честно и продуманно: автовыбор движка возвращает причины
отклонения каждого кандидата, валидность генерируемых конфигов проверяется самим движком
(`check`/`-test`) до применения, падение движка обрабатывается бюджетом рестартов с
backoff и снятием маршрутов при фатале, kill switch fail-closed. Это сильная база.

Но Tier S из WEB-RESEARCH покрыт неровно: **mihomo RULE-SET и Hysteria2 brutal CC — да;
zapret/QUIC — нет вообще** (tpws-only, `core/tune/desync` — мёртвый код, никем не
импортируется); **uTLS-кризис и TUN-стек — в работе у соседа, но с недоделками**:
`core/engine/xray/render.go:341` остался на захардкоженном `"chrome"`, а
`TestTunDropsDeprecatedStack` прямо сейчас **падает**. Детектор SNI-freeze существует, но
его `OnFreeze` никуда не подключён — детекция без контура управления. Плюс несколько
точечных слопов: три независимые таблицы «когда TLS включён», рассинхрон дефолтов
фингерпринта (3 места), отсутствие предупреждения REALITY-без-vision и mux по умолчанию.

## Сверка с Tier S (WEB-RESEARCH)

| # | Находка | Статус |
|---|---------|--------|
| 1 | zapret: tpws→nfqws, UDP/QUIC-десинхронизация | ❌ НЕ покрыто. `core/engine/bypass/bypass.go` — только tpws (TCP). nfqws собирается `packaging/zapret/build.sh`, но не запускается (подтверждено ZAPRET-EVOLUTION-SPEC §2). QUIC/UDP в bypass — ноль. `core/tune/desync` (поиск стратегий, QUIC-scopes в `params.go:63`, QUIC-сиды в `seed.go:67`) — **не импортируется никем** (проверено `go list`), мёртвый код. Решение спеки «nfqws только для QUIC/UDP» не реализовано нигде в core. |
| 2 | uTLS-кризис: дефолт `chrome` = Chrome 133 = блокируется ТСПУ | 🔄 В работе. `core/engine/fingerprint.go` — канонический модуль знаний; xray REALITY теперь `hellochrome_auto` (`fingerprint.go:61`); sing-box использует `engine.DefaultFingerprint` («chrome», комментарий утверждает что резолвится в HelloChrome_Auto). **Но:** утверждение про sing-box не верифицировано, а официальные доки sing-box теперь помечают uTLS как «Not Recommended» для обхода цензуры (рекомендуют NaiveProxy). |
| 3 | REALITY: vision обязателен, mux по умолчанию, детектор «сибирской» заморозки | ⚠️ Частично. Детектор есть (`core/probe/freeze.go`, дифференциальный тест parallel-vs-sequential — качественный), но `OnFreeze` **не подключён ни к одному control plane** (`SetFreezeDetector` вызывается только внутри probe). Предупреждения «REALITY без vision» в валидации нет, mux по умолчанию не ставится ни в одном рендере. |
| 5 | Hysteria2 brutal CC не прокидывается | ✅ Покрыто. `up_mbps`/`down_mbps` (`core/engine/singbox/render.go:214-228`), `congestion_control` для TUIC, port hopping, фича-гейт `FeatureHy2PortHop` в `core/engine/refs.go:70-74` (честно отклоняет Xray для hopping-планов вместо тихого схлопывания). |
| 6 | sing-box TUN: убрать `stack: mixed`, пин ≥1.15, MTU 9000→1500 | 🔄 В работе у соседа, **недоделано**: MTU дефолт стал 1500 (`tunDefaultMTU`), `stack` дропается для ≥1.15 через `renderVersioned`, `MinVersion: "1.15.0"` (`catalog.go:51`). Но см. проблему №2 ниже — тест падает. |
| 8 | mihomo RULE-SET битый (нет секции rule-providers) | ✅ Покрыто. `core/engine/mihomo/rules.go` генерирует секцию, есть валидация wire-формата, тесты (`rules_test.go:73`). |
| — | kernel WireGuard на Linux (9.38 vs 6.12 Gbps) | ❌ Не сделано. WG всегда идёт через userspace-реализацию движков; предпочтения kernel WG нет нигде. Честная оговорка: заметно только на гигабитных каналах. |

## Сильные стороны

1. **Честный автовыбор.** `SelectEngine` (`core/engine/catalog.go:124-173`) возвращает
   `Rejected` с причинами по каждому движку; `BuildCapabilities` различает upstream и
   downstream-сборки (lx-форк с тегами `with_xhttp`/`with_awg`). Фича-гейты через
   `RequiredFeatures` (`core/engine/refs.go`) — план, требующий невозможного, отклоняется
   с объяснением, а не молча деградирует.
2. **Render validity machine-checked.** `Supervisor.Validate` рендерит конфиг и гоняет его
   через `Check` (движковый `check`/`-test`) до `Apply` (`core/engine/supervise/supervisor.go:263-321`);
   для TUN-валидации используется отдельный device name, чтобы не уронить рабочий туннель.
3. **Падение движка — продумано.** `watch` (`supervisor.go:537-608`): бюджет рестартов,
   backoff с джиттером, публикация событий `EventEngineDown`/`EventRestart`/`EventFatal`,
   при исчерпании бюджета — `unroute` (снимает маршруты, fail-closed) и `StateFailed`.
   Редактor чистит последние строки stderr перед логом.
4. **Kill switch fail-closed.** nftables отказывается армриться от root (`core/guard/nftables_linux.go:101-106`,
   SORA-H4), бинарь `nft` резолвится только из доверенных системных директорий
   (`resolveSystemBin`), WFP-иерархия весов зафиксирована тестом
   (`core/guard/firewall_windows.go:64-69`, `firewall_weights_windows_test.go`).
5. **Probe-качество.** `classify.go` — атрибуция фазы/сignature отказа (dns/tcp/tls +
   reset/timeout/nxdomain…); `bandwidth.go` — бенчмарк с честными таймаутами, семафором
   (max 4), гарантированным teardown движка и незалипающим каналом сэмплов.
6. **xraytun bridge** (`core/engine/xraytun/bridge.go`) — честная архитектура: Xray держит
   роутинг/транспорты, mihomo — TUN; один супервизор владеет рестартами обоих.
7. **Naive outbound** (в полёте, `core/engine/singbox/render.go:254-270`) — точно в русле
   рекомендаций WEB-RESEARCH и официальных доков sing-box («use NaiveProxy instead» uTLS);
   честный отказ при `insecure` и явное `udp_over_tcp v2` вместо тихого blackhole UDP.

## Слоп/проблемы (файл:строка)

1. **`core/engine/xray/render.go:341` — недомигрированный дефолт фингерпринта.**
   `realitySettings` в `stream()` (строка 284) использует `engine.DefaultXrayFingerprint`
   (`"hellochrome_auto"`), а тот же блок в XHTTP `downloadSettings` (строка 341) —
   захардкоженный `"chrome"`. У одного соединения uplink и downlink получат разные
   ClientHello-парроты, причём downlink — stale Chrome 133, который по Tier S #2
   детектится ТСПУ. Плюс третий источник дефолта: `engine.DefaultFingerprint` для sing-box.
   Дефолт фингерпринта сейчас живёт в трёх местах — нужен один.
2. **`core/engine/singbox/render_test.go:112` — `TestTunDropsDeprecatedStack` падает
   прямо сейчас.** Тест требует, чтобы `stack` не рендерился никогда («Even an explicit
   plan stack must not reach the config»), а `tun()` (`render.go:721-729`) для zero-version
   (`Render` → `renderVersioned(p, rt, engine.Version{})`) держит legacy-ветку
   `out["stack"] = orDefault(t.Stack, "mixed")`. Комментарий кода («zero version keeps the
   legacy spelling») прямо противоречит комментарию теста. Работа соседа в полёте —
   не чинить поверх, но зафиксировать: либо тест должен использовать `renderVersioned`
   с 1.15, либо zero-version не должен считаться «старым би
...[truncated 7335 chars]