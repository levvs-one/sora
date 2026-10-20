# S2: Core ↔ движки + Core ↔ zapret — аудит стыков

Кластер S2 отдела совместимости стыков (WAVE-SEAMS). Репозиторий
`bug-hunt/sora`, ветка `bugfix/audit-2026-10-19`. Аудит по HEAD
(`5ba2d079` на старте; HEAD двигался чужими коммитами отделов во время
работы — финальные проверки на `acfcab37` + свои коммиты, см. конец).

## Методика и состояние дерева (горячая зона)

- Пины движков: в HEAD `engines.lock` ещё старые (sing-box
  1.14.3-**lx.14**, Xray **26.3.27**, mihomo **1.19.32**); отдел бампов
  держит в незакоммиченном WT новый лок (sing-box 1.14.3-**lx.22**,
  Xray **26.10.17**, mihomo **1.19.32**). Бинарные проверки ниже
  выполнены на новых пинах: реальные бинари найдены в
  `~/workspace/.engines-amd64/` (и дубль в `~/workspace/.e2e-int/engines/`),
  `version` подтверждает: `sing-box 1.14.3-lx.22` (tags:
  `with_xhttp,with_awg,…`), `Xray 26.10.17`, `Mihomo v1.19.32`.
  В `~/workspace/.build-tmp/ze1-engines/` лежат бинари СТАРЫХ версий
  (1.12.0 / 26.3.27 / 1.19.10) — для проверок пинов непригодны.
- Грязные чужими файлы на старте и по ходу: `core/engine/catalog.go`,
  `engine.go`, `engine_test.go`, `fingerprint.go`, `plan.go`,
  `singbox/render.go`, `core/parser/*`, `core/probe/*`,
  `core/cmd/sora-core/*`, `core/engine/mihomo/{config,proxy,render_test}.go`,
  `core/engine/interop/interop_test.go`, `packaging/engines/engines.lock`,
  l10n. Их не трогал; находки по ним — спеками ниже. Все прогоны тестов —
  по WT (HEAD + WIP отделов), атрибуция оговорена в каждом пункте.
- По ходу работы servers-отдел приземлил в чистый до того
  `core/engine/refs.go` свой ханк (`Group.Selected`, коммит `91e50755`
  и WT-правки) — мой коммит по refs.go сделан фильтром ханков
  (temp-index + CAS), чужой ханк не тронут и не включён.

---

## Задача 1. Capabilities ↔ реальность

Путь исполнения (Connect): `control (SessionPlan → engine.Plan)` →
`registry.Factory()` → для bypass-планов селекция идёт по
`bypass.Rewrite(p)` → `engine.SelectEngine` (`Catalog[kind]` →
`BuildCapabilities(kind, version, buildTags)` → `MissingFor` +
`XrayPlaintextMissing`) → драйвер движка → `bypass.Wrap` при наличии
bypass-аутбаундов. Реклама клиенту: `control.Capabilities()` +
`apiVersion()` (динамические `"serverless"` по `BypassAvailable()` и
`"chains"` по `chainEngines(measurer)`).

### F8 (chains) — СОВМЕСТИМ, пин-тест жив

- `6520840` (`TestApiVersionChainsCapability` в
  `core/control/chain_capability_test.go`) на месте; прогнал:
  `go test -run TestApiVersionChainsCapability ./control/` — **ok**
  (до того, как servers-WIP сломал сборку control, см. «Чужие поломки»).
- Каталог: все три движка заявляют `FeatureChains`; рендереры
  подтверждают: sing-box `dialer_proxy` (render.go), mihomo
  `dialer-proxy` (config.go/proxy.go), Xray `dialerProxy` (render.go);
  chain-тесты есть в каждом пакете рендерера и в `core/engine` —
  все пакеты зелёны (см. задачу 2).

### Матрица протоколов (HEAD-каталог; рендерер → бинарь)

| Протокол | mihomo | sing-box | Xray | Подтверждение |
|---|---|---|---|---|
| vless, vmess, trojan, shadowsocks, hysteria2, wireguard, socks5, http, direct | ✓ | ✓ | ✓ | рендер-кейсы у всех трёх; бинарные accept-тесты (зад. 2) |
| tuic | ✓ | ✓ | — | у Xray нет клейма; рендерер честно возвращает `protocol %q is not supported` |
| anytls | ✓ | ✓ | — | аналогично |
| xray-profile | — | — | ✓ | `xray/profile.go` |
| bypass | не протокол каталога: `registry` селектит по переписанному плану (SOCKS5/direct), `Catalog` ProtocolBypass не содержит ни у кого — Rewrite является load-bearing, и он на месте в `Factory` и в `bypass.Engine.Validate` | | | код + тесты bypass/registry |

### Матрица фич (реклама каталога HEAD → RequiredFeatures/MissingFor → рендерер)

| Фича | Клейм (HEAD) | Гейт селекции | Рендерер/путь | Вердикт |
|---|---|---|---|---|
| tun | все (Xray — linux init + tunroute/bridge) | `Tun.Enabled` | ✓ | СОВМЕСТИМ |
| fake-ip | mihomo, sing-box | `DNS.Mode=fakeip` | оба рендерят (sing-box `fakeip` server, mihomo `fake-ip-range`); Xray-bridge честно понижает DNS-mode для своей ноги | СОВМЕСТИМ |
| rule-sets | mihomo, sing-box | правило `rule-set` | ✓ (sing-box rule-sets + `ruleset_pin_test`) | СОВМЕСТИМ |
| proxy-providers | mihomo | `Group.Provider` | ✓ | СОВМЕСТИМ |
| url-test / fallback-group / load-balance | url-test: все; fallback: mihomo; LB: mihomo+Xray | тип группы | ✓ | СОВМЕСТИМ |
| latency-test | все | не требуется RequiredFeatures (информационный клейм) | `Delay`/Measure у всех трёх | СОВМЕСТИМ (не гейтит) |
| hot-apply | mihomo | не гейтится | mihomo live-путь (hot Apply в `live_test`) | СОВМЕСТИМ (не гейтит) |
| geodata | все | `Options.GeoData` гейта не имеет — безвредно: заявляют все трое | ✓ | СОВМЕСТИМ |
| per-app-routing | sing-box | `Tun.Include/ExcludeApps` | sing-box `include_package/exclude_package` ✓. **Замечание (не разрыв):** mihomo-рендерер тоже эмитит `include_package/exclude_package` в TUN-конфиг (`mihomo/rules.go`), но клейма не имеет — недо-клейм, консервативно (план уйдёт в sing-box), тихой потери нет | СОВМЕСТИМ |
| tls-fragment | sing-box, Xray | `Options.Fragment.Enabled` | sing-box `fragment:true` (скип QUIC-протоколов), Xray freedom-fragment + `dialerProxy` | СОВМЕСТИМ |
| xhttp | mihomo, Xray; sing-box — условно | `Transport.Type=xhttp` | sing-box клейм только через `BuildCapabilities`: lx-форк + тег `with_xhttp`; у поставленного lx.22 тег есть (вывод `sing-box version`) | СОВМЕСТИМ |
| vless-encryption | mihomo, Xray; sing-box — условно | `Encryption != ""/none` | sing-box: lx-форк ≥1.14.3 в `BuildCapabilities`; бинарный accept `vless-encryption` — PASS | СОВМЕСТИМ |
| xhttp-download-split | HEAD: Xray; **WT отдела бампов: +mihomo** | `DownloadAddress` | Xray `downloadSettings` ✓, mihomo `download-settings` ✓, sing-box — нет | СОВМЕСТИМ (на WT — с бинарной верификацией, см. зад. 2) |
| xhttp-xmux | HEAD: **никто**; **WT: mihomo** | `Xmux*` поля | mihomo `reuse-settings`+`x-padding-bytes` ✓; Xray/sing-box не эмитят | СОВМЕСТИМ после WT бампов; на HEAD — честное «missing everywhere» |
| amneziawg | mihomo; sing-box — условно `with_awg` | `Amnezia != nil` | Xray-рендерер **явно отказывает** AWG-аутбаунду (не рендерит «голый» WG) | СОВМЕСТИМ |
| amneziawg3 | гейты по версии/тегам в `BuildCapabilities` (mihomo ≥1.19.30; lx `with_awg`) | `UsesAWG31()` | sing-box бинарный accept `amneziawg3` на lx.22 — PASS (зад. 2) | СОВМЕСТИМ |
| amneziawg-masquerade | sing-box lx `with_awg` | `UsesMasquerade()` | ✓ | СОВМЕСТИМ |
| private-control | mihomo, Xray | `Plan.PrivateControl` | `PrivatePreference` ставит sing-box первым, но `SelectEngine` его честно реджектит по missing и идёт дальше | СОВМЕСТИМ |
| chains | все | `Via != ""` | см. F8 выше | СОВМЕСТИМ |
| hy2-port-hop | mihomo, sing-box | `HopPorts != ""` | `server_ports` / `ports` ✓ | СОВМЕСТИМ |
| doh3 | mihomo, sing-box | DNS-сервер `h3` | Xray-рендерер отказывает с guidance (`TestRenderRejectsDoH3WithGuidance` PASS) | СОВМЕСТИМ |
| ech | mihomo, sing-box | `TLS.ECH.Enabled` | sing-box `ech{config,query_server_name}`, mihomo `ech-opts`; Xray-рендерер **отказывает** (`TestRenderRefusesECH` PASS) | СОВМЕСТИМ |

Дополнительные честные гейты в `MissingFor` (не через RequiredFeatures) —
проверены по коду: Xray + `NameserverPolicy` (split-DNS не рендерится),
Xray + `TLS.Insecure` без REALITY, Xray + REALITY over ws/httpupgrade,
sing-box + AWG `J1/J2/J3/Itime`, TUN stack правила (sing-box ≥1.15,
Xray ≠ gvisor), `XrayPlaintextMissing` (cutoff 26.7.11; на новом пине
26.10.17 гейт активен для поставленного билда — WT каталога это уже
отражает; на HEAD-пине 26.3.27 гейт спал).

### РАЗРЫВ S2-C1: XPaddingBytes без гейта — ПОЧИНЕНО (acfcab37)

- `Transport.XPaddingBytes` — единственный XHTTP-тюнинг, не входивший
  в гейт: `RequiredFeatures` требовал `FeatureXHTTPXmux` только за
  `XmuxMax*` поля. Padding-only план проходил селекцию на любой
  XHTTP-движок, а рендереры Xray и sing-box значение **молча роняли**
  (sing-box xhttp-кейс: только mode/host/path/headers; Xray:
  mode/path/host/headers/downloadSettings). Сам `plan.go` честно
  писал «validated here and dropped at render time» — при том что
  парные xmux-поля гейтились именно против такой потери (PASS3 S1).
- Фикс (`core/engine/refs.go`, файл был чистым; коммит фильтром ханков
  из-за чужого WIP в том же файле): `XPaddingBytes != ""` теперь тоже
  требует `FeatureXHTTPXmux`. На HEAD-каталоге padding-only план честно
  получит missing на всех (как xmux до верификации); на WT-каталоге
  отдела бампов уйдёт в mihomo, который `x-padding-bytes` рендерит и
  чей рендер принят бинарём (зад. 2). Пин-тест:
  `core/engine/xpadding_gate_test.go` (`TestXPaddingBytesRequiresXmuxCapability`).

### РАЗРЫВ S2-C2 (спека, файл грязный чужими): одиночные поля без гейта

Файлы правок — `core/engine/catalog.go` (горячая зона отдела бампов) и,
для варианта «новый Feature», `core/engine/engine.go` (тоже грязный).
Поэтому — спека, не фикс:

1. **`TLS.KeyShare`** (сильнейший из трёх). Рендерит только mihomo
   (`reality-opts.support-x25519mlkem768`, `mihomo/proxy.go`);
   `plan.go` сам фиксирует: sing-box-lx key_share — «separate PASS2 S3
   item», Xray не рендерит. Гейта нет ни в `RequiredFeatures`, ни в
   `MissingFor`. План с `KeyShare="classical"` уйдёт в sing-box/Xray и
   молча потеряет выбор key share; против REALITY-серверов на
   Xray ≥26.9.8, принимающих только hybrid, это обрыв хендшейка с
   непрозрачной ошибкой (сценарий описан в комментарии `plan.go`).
   **Спека фикса** (прецедент — AWG J1/J2/J3 в `MissingFor`): в
   `Capabilities.MissingFor` для `Kind != KindMihomo` добавлять
   `REALITY key share` при любом аутбаунде с `TLS.KeyShare != ""`;
   пин-тест по образцу `TestXrayMissesNameserverPolicy`.
2. **`Outbound.BBRProfile` + `HopIntervalMax`** — рендерит только
   sing-box (`bbr_profile`, `hop_interval_max`, sing-box 1.14);
   mihomo рендерит только `HopInterval`, Xray hy2 port-hop не умеет
   вовсе (но `BBRProfile` без `HopPorts` гейтом не ловится). Та же
   спека `MissingFor`: для `Kind != KindSingBox` при
   `BBRProfile != "" || HopIntervalMax > 0` — missing. Тяжесть ниже:
   док-комментарий поля честно называет его sing-box-выбором.
3. **`TLS.SpiderX`** — рендерит только Xray (`realitySettings.spiderX`);
   sing-box/mihomo игнорируют. SpiderX — Xray-концепт REALITY, потеря
   не ломает хендшейк; та же спека применима при желании полноты.

---

## Задача 2. Рендереры ↔ схемы запиненных версий

Прогоны из `sora/core`, `SORA_ENGINES_DIR=~/workspace/.engines-amd64`
(+ `SORA_{SINGBOX,XRAY,MIHOMO}_BIN` для accept-тестов — они гейтятся
именно per-engine env, без них молча SKIP).

### Без бинарей (юнит/рендер-тесты, по пакетам)

`go test ./engine/ ./engine/bypass/ ./tune/desync/` — **ok**;
`./engine/singbox/ ./engine/mihomo/ ./engine/xray/` — **ok**;
`./control/` (подмножество chain/apiVersion/select) — **ok** на момент
прогона. Полный `./control/` дал два падения, оба **чужие/окружение**
(см. «Чужие поломки» в конце), не S2.

### С бинарями новых пинов (`TestEngineAcceptsRenderedPlans` = `sing-box check` / `mihomo -t` / `xray run -test` на рендерах enginetest-планов)

- **sing-box 1.14.3-lx.22 — PASS**, все подтесты: all protocols,
  fake-ip, fragment, xhttp ×4 режима, vless-encryption, amneziawg,
  **amneziawg3** (ключевой: форк реально принимает 3.1-параметры,
  а не «молчит» — sing-box режектит неизвестные ключи на check).
- **mihomo 1.19.32 — PASS**: all protocols + amneziawg, xhttp.
  Отдельно: WT-тест отдела бампов `TestBinaryAcceptsXHTTPDownloadSettings`
  (`mihomo -t` на split-XHTTP рендере: download-settings +
  reuse-settings) — **PASS (5.9s)**. Это та самая верификация, на
  которой WT-каталог перевернул клеймы xmux/download-split для
  mihomo; на HEAD клеймов ещё нет — расхождение HEAD↔WT осознанное и
  принадлежит отделу бампов, S2 его не дублирует.
- **Xray 26.10.17 — ЧАСТИЧНО**: `xhttp_reality` PASS; `all_protocols` и
  `fragment` **FAIL** на WireGuard-аутбаунде:
  `proxy/wireguard: Using kernel TUN` →
  `Failed to start: main: failed to create server > protocol not supported`.

### Атрибуция Xray/WireGuard — НЕ ПРОВЕРЯЕМО ЗДЕСЬ (окружение), спека S2-E1 отделу бампов

- Падение воспроизводится **ручной минимальной** WG-конфигурацией
  (не рендером sora) на том же бинаре: конфиг парсится, отказ — на
  создании kernel WG-устройства. В VM нет `/sys/module/wireguard`;
  `xray run -test` без WG — `Configuration OK`. Значит это не
  схемный разрыв рендера: `run -test` у Xray инстанцирует WG, а
  `check`/`-t` у остальных — нет.
- Что остаётся отделу бампов (не дублирую): прогнать
  `TestEngineAcceptsRenderedPlans ./engine/xray/` на хосте с kernel
  WireGuard **или** принять решение по `noKernelTun`: рендерер sora
  (`xray/render.go`, `wireguard()`) это поле не выставляет, и на
  пользовательских машинах без kernel WG тот же сценарий даст
  мёртвый WG-аутбаунд при живом конфиге.

### Interop (живой трафик)

`TestEveryEngineCarriesTrafficThroughEveryTransport` с
`SORA_ENGINES_DIR` на новые пины: на момент сдачи фрагмента прогон
**не завершён** (долгая матрица транспорт×движок из коммита
`5ba2d079`) — результат не засчитан ни в плюс, ни в минус;
остаётся за интеграционным отделом, которому принадлежит тест.

---

## Задача 3. zapret-стык по HEAD (db519b5f..90987630)

Цепочка: `proto BypassStrategy` → `control/plan.go` (конверсия) →
`engine.BypassStrategy` → валидация (`engine/validate.go`) →
`bypass.BackendOf` → `bypass.Args` (tpws) / `bypass.NFQWSArgs` (nfqws)
→ executor (`bypass.go` / `nfqws.go`, `--qnum` + nftables-очередь).

### Поле → argv (Go-стратегия, 29 полей)

| Поля | tpws (`Args`) | nfqws (`NFQWSArgs`) | Итог |
|---|---|---|---|
| SplitPos | `--split-pos` | `--dpi-desync-split-pos` | ✓ оба |
| Disorder/DisorderScope, OOB/OOBScope/OOBData, TLSRecord, HostCase, DomainCase, MethodEOL, HostDot, HostTab, HostNoSpace, MethodSpace, UnixEOL, SplitAnyProtocol, TamperStart, TamperCutoff, MSS | все рендерятся (`--disorder[=scope]`, `--oob[=scope]`, `--tlsrec`, `--hostcase`, `--domcase`, `--methodeol`, `--hostdot`, `--hosttab`, `--hostnospace`, `--methodspace`, `--unixeol`, `--split-any-protocol`, `--tamper-start/-cutoff`, `--oob-data`, `--mss`) | **не рендерились и не отвергались** | РАЗРЫВ S2-Z1 → починено (934ce3e7) |
| Desync, Fooling, TTL/AutoTTL, Repeats, FakeTLS, FakeQUIC, FilterTCP, FilterUDP, FilterL7 | не применимо: `BackendOf` уводит такие стратегии в nfqws; валидация требует desync для nfqws-полей | все рендерятся (`--dpi-desync`, `-fooling`, `-ttl`/`-autottl`, `-repeats`, `-fake-tls`, `-fake-quic`, `--filter-tcp/-udp/-l7`) | ✓ |

Нюансы без потери: `Repeats=1` валиден и не эмитится (семантически
identity — nfqws и так шлёт один раз); `FakeTLS="tls"` не эмитится
(встроенный ClientHello zapret — дефолт бинаря, params.c собирает его
при пустой коллекции).

### РАЗРЫВ S2-Z1: legacy-поля молча терялись на nfqws — ПОЧИНЕНО (934ce3e7)

- `validateDesync` отвергал nfqws-поля без desync, но обратного гейта
  не было: стратегия `{Desync:[fake], Disorder:true, SplitPos:[1],
  FilterTCP:"443"}` проходила валид
...[truncated 8067 chars]