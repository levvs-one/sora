# Дрейф sora ↔ sora-legacy: что портировано, что разошлось

**Дата:** 2026-10-20. **Ветки:** `bugfix/audit-2026-10-19` в `~/workspace/bug-hunt/sora`
(1176 коммитов, HEAD `a5455c9`) и `~/workspace/bug-hunt/sora-legacy` (853 коммита,
HEAD `c137090`), локально, пуша нет.

**Направление стрелок в документе:** `sora → legacy` означает «сделано сначала в sora,
затем перенесено в sora-legacy». Обратное направление (`legacy → sora`) в git log
не обнаружено — см. раздел 4.

## 0. Методология и границы честности

- Статусы «портировано» / «не портировано» установлены **только по git log обеих
  веток** (`git log --format='%h %s'`) и поиску по сабжектам коммитов. Кодовое
  сравнение файлов НЕ проводилось.
- «Не портировано» пишется **только после явного grep-поиска** соответствующего
  сабжекта в git log другой ветки. Если эквивалент может существовать под другим
  названием — это помечено как «не проверен код, требуется сверка».
- Источники: git log обеих веток; `FIX-REPORT.md`, `FEATURE-REPORT.md`,
  `REVIEW-5PASS.md` **не содержат** явных заявлений о портах (кроме R5-SC-1-3
  в REVIEW-5PASS.md), поэтому основой являются коммиты.

## 1. Явные порты sora → legacy (подтверждены git log)

| # | Фича/фикс | sora (коммит) | legacy (коммит) | Статус |
|---|-----------|---------------|-----------------|--------|
| 1 | SORA-H6: гонка `journal Append` vs unsubscribe; SORA-M8: `parseCredential` fail-closed | `6b8792f` (H6), `43cea00` (M8) — `[audit-fix][sora-go]` | `ade200b` `[swarm] legacy Go: порт SORA-H6 и SORA-M8 (A20-9)` | ✅ Портировано sora → legacy |
| 2 | SW1 obfs suite: uTLS-профили, ClientHello-фрагментация | `097a0ce` `[swarm] obfs suite: uTLS profiles, ClientHello fragmentation, jitter, fake SNI` | `e213804` `[swarm] port obfs suite to legacy core` + `6b77b80` `[swarm-review] fix proxy gap in ClientHello fragmentation, doc dropped uTLS fields` | ✅ Портировано sora → legacy, **частично** (в legacy отброшены часть uTLS-полей и proxy gap починен отдельным коммитом; jitter/fake SNI в сабжекте порта не упомянуты) |
| 3 | SORA-M10: `WFP.Disarm` очищает сессию только после успешного Close; SORA-L20: fail-closed на пустом `enginesDir` | `b0652da` (M10), `9d25c51` (L20) — `[audit-fix][sora-go]` | `d58a454` `[net-rd] guard: port SORA-M10/SORA-L20 kill-switch fixes to legacy Windows firewall` | ✅ Портировано sora → legacy |
| 4 | SORA-M3 / R5-SC-1-3: проверка подписей апстримов в `fetch.sh` (`engines.sig`) | `9f69b25` `[audit-fix][sora-go] verify upstream signatures in fetch.sh via engines.sig` | `21bf84e` `[review-5pass] scripts-ci: port upstream-signature enforcement to legacy fetch.sh` | ✅ Портировано sora → legacy |
| 5 | Валидация параметров обфускации AmneziaWG в `Outbound.Validate` | `e850488` `[net-rd]` | `993403c` `[net-rd]` — идентичный сабжект | ✅ Портировано sora → legacy (зеркальный сабжект) |
| 6 | mihomo: рендер AnyTLS-аутбаундов | `1da01e9` `[net-rd]` (2026-10-19 20:40 UTC) | `2a100f3` `[net-rd]` — идентичный сабжект (2026-10-19 20:43 UTC) | ✅ Портировано sora → legacy (зеркальный сабжект, sora раньше) |

Итого: **6 позиций портировано sora → legacy**, из них 4 — явные порты с пометкой
«порт/port» в сабжекте, 2 — зеркальные сабжекты. **Явных портов legacy → sora — 0**
(поиск по `LEGACY-*`, `R5-LG*`, `R5-LC*`, `backport` в git log sora: 0 вхождений).

## 2. Крупные вещи sora, НЕ портированные в legacy (проверено grep'ом git log legacy)

### 2.1. Фичи F0–F11 — только в sora

В legacy **нет ни одного `[feature]`-коммита** за период ветки (поиск по log: 0;
3 совпадения слова «feature» — шум из старой истории: ISSUE_TEMPLATE-файлы).
Волны 1–3 (`FEATURE-REPORT.md`) существуют только в sora:

| Фича | sora | legacy | Статус |
|------|------|--------|--------|
| F1 QR share/scan | `[feature][sora-dart] QR share/scan screens…` и др. | — | ❌ Не портировано |
| F2 benchmark + автовыбор серверов | `[feature][sora-go] probe: throughput benchmarker…`, `[feature][sora-dart] server list: sort menu, speed column, benchmark screen…` | — | ❌ Не портировано |
| F3 DNS-менеджер + CheckDnsLeaks | `[feature][sora-go] DNS leak diagnostics core`, `[feature][sora-dart] DNS manager screen…` | — | ❌ Не портировано |
| F4 rework экрана Connections | `[feature][sora-dart] connections: stats header, group by process…` | — | ❌ Не портировано |
| F5 network profiles + авто-детект | `[feature][sora-go] network profiles: store, fingerprinting…`, Dart UI | — | ❌ Не портировано |
| F6 subscription override layer | `[feature][sora-go] subscription override layer…`, Dart UI | — | ❌ Не портировано |
| F7 staged updates + survivability | `[feature][sora-go] engine crash watchdog + network-move events`, staged update UI | — | ❌ Не портировано |
| F8 proxy chains | `[feature][sora-go] proxy chains: Via links…`, chain builder UI | — | ❌ Не портировано |
| F9 E2E device sync без облака | `[feature][sora-go] E2E device sync service…`, `[swarm] F9 sync daemon…`, Dart UI | — | ❌ Не портировано |
| F10 extensions (manifest v1, .soraext, store) | `[feature][ext] core/ext: manifest v1…`, 6 `[ext]`-коммитов | — | ❌ Не портировано |
| F11 zapret параллельно с VPN | `[feature][sora-go] control: …zapret-with-VPN…`, `[feature][sora-dart] F11 zapret-alongside-VPN toggle…` | — | ❌ Не портировано |
| F0 split-tunnel UX audit | `[feature][sora-dart] program picker…` (UX-правки) | — | ❌ Не портировано |

> Примечание: legacy имеет **свою старую** zapret-интеграцию из истории ветки
> (`d6dc058 feat(core): DPI bypass without a server, through zapret's tpws`,
> `30d37ba feat(linux): ship zapret`) — это не порт F11, а предсуществующий код.
> `[net-rd] bypass: недостающие tamper-опции tpws в BypassStrategy` (`085cd2b`)
> и `verify tpws against SHA256SUMS` (`1800571`, R5-LG-1-3) — собственные
> legacy-доработки, не порты.

### 2.2. SW2–SW7 (ройные волны после F) — только в sora

| Волна | sora | legacy | Статус |
|-------|------|--------|--------|
| SW1 obfs suite | `097a0ce` | `e213804`+`6b77b80` | ✅ портировано (разд. 1, п. 2) |
| SW2 egress self-tests, LeakService RPC, ingress-защита nftables/WFP | `[swarm] egress self-tests (core/leak)…`, `[swarm] ingress-защита…` | grep: `leak`, `LeakService`, `SW2` — 0 | ❌ Не портировано |
| SW3 smart pick (scoring, reliability journal, auto-switch) | `[swarm] smart server selection…`, `[swarm] smart score…` | grep `SW3`, `PickBest`, `auto-switch` — 0 | ❌ Не портировано |
| SW4 детектор цензуры (`core/censor`, `sora.censor.v1`) | `[swarm] детектор цензуры: пакет core/censor…` + 3 фикс-коммита | grep `censor`, `SW4`, `DetectCensorship` — 0 | ❌ Не портировано |
| SW5 авто-тюнинг DPI (`core/tune`, Geneva Strategy Tuner) | `[swarm] авто-тюнинг DPI…`, `[tspu-fix] Geneva Strategy Tuner…` | grep `desync`, `SW5`, `core/tune`, `Geneva` — 0 | ❌ Не портировано |
| SW6 extensions v2 (background workers, `net.fetch`) | `[swarm] background workers + net.fetch…`, `[swarm] ext UI v2…` | grep `SW6`, `net.fetch` — 0 | ❌ Не портировано |
| SW7 custom servers UI | `[swarm] custom servers UI…` | grep `SW7`, `custom servers` — 0 | ❌ Не портировано |

### 2.3. TSPU-фиксы (30 `[tspu-fix]` в sora) — не портированы

Поиск в git log legacy: `tspu` — **0 совпадений**. Проверенные примеры:

| TSPU-фикс | sora | legacy | Статус |
|-----------|------|--------|--------|
| T001: utls bump до v1.8.3, stealth grades, JA4 strips GREASE | `542eab3`, `3336f31`, `9d9997d` | grep `utls`, `JA4`, `T001` — 0 (в истории legacy есть только старый `9fd20d1 Add fingerprint(uTLS) option`) | ❌ Не портировано |
| T002+T007/T004+T006: REALITY vision validation, dest checklist | `07951e4`, `aa629d1` | 0 | ❌ Не портировано |
| T008: QUIC VN-probe, residual-ban tracker | `1147cc4` | 0 | ❌ Не портировано |
| T012: fail-closed AmneziaWG gates + `wgobfusc.Generate` | `16941d4`, `58fb4e3` | grep `wgobfusc` — 0 | ❌ Не портировано |
| T015/T031/T029: fake-TTL калибровка, SNI-aligned split, dead-session detector | `c3b99d4`, `b22f132`, `5d616c9` | 0 | ❌ Не портировано |
| T022: trojan active-probe self-test | `b63c41b` | 0 | ❌ Не портировано |
| AWG 3.1: параметры плана, валидация 3.1, masquerade/early-data, stealth 3.x grading | `[tspu-fix] awg: add AmneziaWG 3.1 parameters…`, `9c6c011 [detail-fix] awg: 3.1/masquerade…` | grep `3.1`, `masquerade`, `AmneziaWG3` — 0 | ❌ Не портировано |
| Geneva Strategy Tuner (`core/tune/desync`) | `[tspu-fix] Geneva Strategy Tuner…` | 0 | ❌ Не портировано |
| zapret pool (8 стратегий), tamper-start/cutoff, oob-data, mss | `[tspu-fix] tune: curated 8-strategy zapret pool…`, `[tspu-fix] bypass: tamper-start…` | 0 | ❌ Не портировано |

### 2.4. Прочие sora-фиксы/улучшения, отсутствующие в legacy

| Фикс | sora | Проверка в legacy | Статус |
|------|------|-------------------|--------|
| P0-9: Happy Eyeballs v3 racer (`core/race`), race resolved endpoint addresses, panic guard | `3e58a09`, `273ee1d`, `85773c9` | grep `eyeballs`, `race`, `Happy` — 0 (watchdog-совпадения — про C# Xray watchdog, другое) | ❌ Не портировано |
| P0-1: version-aware gate — Xray ≥26.7.11 отказывает в plaintext VLESS/Trojan | `5effaf4` | grep `P0-1`, `plaintext` — 0 | ❌ Не портировано |
| S4: stall-watchdog (established-but-dead → reconnect с backoff) | `f1c057b`, `8cbe5c85` | grep `stall-watchdog`, `S4` — 0 | ❌ Не портировано |
| S7: FakeIP-дефекты (единый пул 198.18.0.0/15, suffix+regex, time.windows.com/STUN в фильтре, AAAA только при IPv6) | `63cd74e`, `af30c90` | grep `FakeIP`, `fake-ip`, `S7` — 0 | ❌ Не портировано |
| S1: sing-box deprecations (http_clients, DoH3 `type:h3`, TUN multi_queue/auto_redirect, CI-gate `sing-box check`) | `2758c6e` | grep `http_clients`, `multi_queue`, `S1` — 0 | ❌ Не портировано |
| S2: auto-vision на уровне плана, FlowAuto badge | `ae5311b`, `4a02921` | grep `auto-vision`, `FlowAuto`, `S2` — 0 | ❌ Не портировано |
| S3: CI-job свежести uTLS-фингерпринтов (`known_ja4.json`) | `9121cb3` | grep `known_ja4`, `S3` — 0 | ❌ Не портировано |
| Канонический uTLS-модуль фингерпринтов + разрыв: bare Go ClientHello в plain-TLS аутбаундах | `[net-rd] fingerprint: canonical uTLS fingerprint knowledge + validation` | grep `canonical`, `fingerprint` в новых коммитах — 0 | ❌ Не портировано |
| Hysteria2 up/down mbps + port hopping через ссылку; TUIC congestion control | `[net-rd] Hysteria2/TUIC: тюнинг…` | grep `up_mbps`, `port hopping`, `congestion` — 0 | ❌ Не портировано |
| mihomo: render rule-providers (RuleRuleSet https URLs) | `[net-rd] mihomo: render rule-providers…` | grep `rule-provider`, `RuleRuleSet` — 0 | ❌ Не портировано |
| Атомарный Linux kill switch (одна nft-транзакция) | `[net-rd] atomic nftables kill-switch…` | grep `kill-switch`, `nftables` — только старые и d58a454 (Windows) | ❌ Не портировано |
| DNS: FakeIPFilter/FakeIPTTL/SkipVerify контракт, fake-ip exclusions LAN, h3:// downgrade fix | `[net-rd] DNS contract…`, `[net-rd] singbox: fake-ip exclusions…` | grep `h3://`, `FakeIPFilter` — 0 | ❌ Не портировано |
| A20-3: Windows in-app update fail-closed до minisign-верификации в Dart | `2041bef` | grep `A20-3`, `in-app update` — 0 | ❌ Не портировано |
| A20-12: honest crash-restore (post-connect intent, 24h TTL) | `cf49a4c` | grep `crash-restore`, `A20-12` — 0 | ❌ Не портировано |
| A20-4: polkit-сплит + per-method authorization | `2c96105` | grep `polkit`, `A20-4` — 0 | ❌ Не портировано |
| A20-16: pin sing-box remote rule sets на commit SHA | `1e3eb16` | grep `A20-16`, `rule sets` — 0 | ❌ Не портировано |
| Строгий kill-switch (Off/Standard/Strict), честный Armed/Blocked | `[detail-fix] guard: strict kill-switch mode…` | grep `Strict` в новых коммитах — 0 | ❌ Не портировано |

## 3. Чеклист портирования sora → legacy (кандидаты, по приоритету)

Безопасность/устойчивость сначала. Каждый пункт проверен на отсутствие в git log legacy.

- [ ] **P0-9 Happy Eyeballs v3 racer + race resolved endpoint addresses** (`3e58a09`, `273ee1d`) — сетевой уровень, архитектура legacy-Go близка.
- [ ] **S4 stall-watchdog** (`f1c057b`) — reconnect мёртвого туннеля с backoff; в legacy есть свой engine watchdog только в C# (A20-14), core-уровня нет.
- [ ] **P0-1 plaintext gate** (`5effaf4`) — Xray ≥26.7.11 отказывает plaintext VLESS/Trojan; security-relevant для обоих.
- [ ] **S7 FakeIP-дефекты** (`63cd74e`, `af30c90`) — если legacy FakeIP используется, сверить пул/фильтр.
- [ ] **T001 utls bump + stealth grades + JA4** (`542eab3`, `3336f31`, `9d9997d`) — legacy использует uTLS из старой истории.
- [ ] **AmneziaWG 3.1 + masquerade/early-data + stealth 3.x grading** (`9c6c011`) — в legacy нет вообще.
- [ ] **Hysteria2 bandwidth/port-hopping + TUIC congestion** (`[net-rd] Hysteria2/TUIC…`) — legacy поддерживает hysteria/tuic из истории, тюнинга нет.
- [ ] **Атомарный Linux kill switch** (одна nft-транзакция) — legacy Linux kill switch существует (`8de39c3` в истории), но не атомарный.
- [ ] **mihomo rule-providers, DNS h3 fix, fake-ip exclusions** — если legacy рендерит mihomo-конфиги (да: `2a100f3`, `af8d343`).
- [ ] **Канонический uTLS-модуль + fix bare-TLS ClientHello** — anti-fingerprint для legacy.
- [ ] **S2 auto-vision, S3 uTLS-freshness CI** — средний приоритет.
- [ ] **F0–F11** — решение владельца: legacy позиционирован как «версия для старых систем» (README), UI — C#, портирование тяжёлое; точечно рассмотреть только F2 (benchmark/автовыбор) и F3 (DNS leak check) как наиболее независимые от платформы.

## 4. Обратное направление: legacy → sora

**Явных портов из legacy в sora в git log ветки `bugfix/audit-2026-10-19` не найдено**
(поиск по `LEGACY-*`, `R5-LG*`, `R5-LC*`, `backport` в log sora — 0 вхождений).
Кандидаты на сверку (сабжекты проверены в log sora, **кодовое сравнение не проводилось** —
эквивалент мог быть сделан под другим названием):

- [ ] **R5-LG-1-2**: DNS-rebinding TOCTOU в пробере legacy (`f31f52e`, закрыто Control-хуком по образцу `dialChecked`) — в log sora прямых совпадений нет (есть `87e5ac8` про dial policy — вероятно другое). Требует проверки кода sora.
- [ ] **R5-LG-2-1/2-2**: `secret.Store` против forged/oversized vaults (`10ae560`) — в sora есть SORA-L1..L3 (другой набор: персист токена, 0600, мастер-ключ). Частичное покрытие, кандидат на сверку.
- [ ] **R5-LG-3-1..3-4**: liveness — bounded watchers, backoffs, shutdown (`5bc06ec`) — в sora есть F7 engine crash watchdog; кандидат на сверку.
- [ ] **R5-LG-1-1**: special-use ranges как non-public в subscription/probe (`1a25f0f`); в legacy detail-fix `0ef63db` добавил 0.0.0.0/8 и 240.0.0.0/4 — в log sora совпадений нет, кандидат на проверку.
- [ ] **A20-14** (legacy C#): watchdog смерти Xray + снятие системного прокси при обрыве обновления подписок (`7ead4d8`, `c137090`) — C#-специфично; в sora эквивалент частично покрыт A20-3 (in-app update fail-closed). Прямого порта нет по архитектурным причинам.
- [ ] **LEGACY-M6**: live handshake read deadline, connection cap, gRPC idle keepalive (`cadb40b`) — в sora есть SORA-M1 (cap control-plane connections, reap idle); кандидат на сверку покрытия.
- [ ] **LEGACY-L11/L10** (C#): `--restore-proxy` подтверждение, сторожевой флаг восстановления прокси (`6a2e94f`, `6d46d57`-series C#) — клиент-специфично для C# UI; в sora (Flutter) аналога не найдено в log.

## 5. Итоговая картина

- **Всё движение — sora → legacy**, 6 подтверждённых портов. Обратных портов нет.
- legacy получил точечные сетевые/безопасностные порты (obfs SW1, kill-switch, fetch.sh-сигнатуры, AmneziaWG-валидация, AnyTLS, H6/M8), но **ни одной фичи F0–F11, ни одной волны SW2–SW7, ни одного TSPU-фикса**.
- Дрейф структурный: sora — Flutter UI + новый Go core с 12 фичами и большим anti-censorship стеком; sora-legacy — C# UI + старый Go core, развивается точечными портами. README позиционирует legacy как «версию для старых систем» — это согласуется с наблюдаемым дрейфом.
- Решение владельца (из задачи): только документ, никакого рефакторинга/портирования в этом заходе.
