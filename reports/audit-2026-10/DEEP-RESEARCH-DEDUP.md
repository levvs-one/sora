# DEEP-RESEARCH-DEDUP: сверка бэклога с фактическим кодом

Дата: 2026-10-20. Ветка: `bugfix/audit-2026-10-19` (коммиты роя на месте).
Метод: read-only — утверждения DEEP-RESEARCH-70 (S1–S12) и P0 из WEB-RESEARCH-2
сверены с кодом `~/workspace/bug-hunt/sora`. Пины движков: `packaging/engines/engines.lock` —
sing-box-lx **v1.14.3-lx.14** (форк с client XHTTP и AWG), Xray **26.3.27**, mihomo **1.19.32**.

Легенда: DONE — реализовано; PARTIAL — частично; TODO — не сделано.

---

## S-TIER

| Пункт | Статус | Что есть / чего нет (файл:строка) | Рекомендуемая зона работ |
|---|---|---|---|
| S1 деприкации sing-box | PARTIAL | DONE: `"stack"` эмитится только для `ver < 1.15` (`core/engine/singbox/render.go:721-728`, коммит `767499b`); DNS plain/tcp/tls/https/quic — новый формат `type`+`server`+`server_port` (`render.go:583`); MTU-дефолт 1500 (`render.go:691-700`). TODO: `download_detour` у remote rule-set эмитится безусловно (`render.go:479`) — deprecated в 1.14, удаление в 1.16; DoH3 — legacy-строка `h3://` без `"type"` (`render.go:576-581`), официальные доки требуют `"type": "h3"` + `server`/`server_port` (см. противоречие №2); `independent_cache` в коде нет и не было (`git log -S` пуст) — пункт отчёта моот; пин остался 1.14.3-lx.14, не ≥1.15 (осознанно: форк трекает 1.14; upstream MinVersion 1.15.0 — `core/engine/catalog.go:50-54`); `sing-box check` — только opt-in тест за env-var (`core/engine/singbox/render_test.go:180`), в CI не гейтит; `multi_queue`/`auto_redirect` на Linux — отсутствуют | Миграция `download_detour` → `http_clients` + `route.default_http_client`; DoH3 → `"type": "h3"`; прогнать `TestEngineAcceptsRenderedPlans` против пин-билдa; Linux TUN: `multi_queue`, `auto_redirect` |
| S2 XTLS Vision | PARTIAL | DONE: варнинги `reality-without-vision`, `reality-xhttp-vision` (`core/engine/reality.go:32-66`); ошибка `flow`+не-TCP в Xray-рендере (`core/engine/xray/render.go:380-383`); mux подавляется под vision (`xray/render.go:253-257`). TODO: авто-vision нет — `flow` прокидывается как есть (`core/engine/plan.go:144`, `core/control/plan.go:561`); нет кнопки «исправить» / UI-бейджа в ядре | Авто-vision для VLESS/Trojan+TCP+REALITY/TLS при пустом flow на уровне плана; UI: бейдж + one-click fix + confirm при ручном отключении |
| S3 свежесть uTLS | PARTIAL | DONE: канонический модуль (`core/engine/fingerprint.go`, net-rd 6/20; дефолт `chrome`→HelloChrome_Auto документирован; Chrome 133 помечен stale/blocked); UI-выбор фингерпринта с пересечением capabilities (`app/lib/src/ui/obfs.dart:106-117`); JA4-stealth-check с детектом PQ key share (`core/diagnostics/ja4.go:150-152,296-309`). TODO: CI-трекинг актуальности (workflows: только autofix/repository/security); авто-fallback при TLS-timeout (ротация есть через censor-трекер по факту заморозки, не по таймауту) | CI-job: сверка `refraction-networking/utls` + вендорных фингерпринтов движков с `known_ja4.json`; авто-fallback фингерпринта по TLS-timeout |
| S4 Hysteria2 | PARTIAL | DONE: `up_mbps`/`down_mbps` в sing-box (`render.go:236-240`) и mihomo (`core/engine/mihomo/proxy.go`, `px.Up`/`px.Down`); port hopping в обоих (`render.go:242-248`, mihomo `Ports`/`HopInterval`); TUIC congestion control (`render.go:270-273`, `config.go`). TODO: stall-watchdog отсутствует (`core/session/watchdog.go` — это crash-watchdog F7, не «established но 0 байт → реконнект»); UI «скорость тарифа» + автокалибровка не подтверждены | Watchdog: established + 0 байт при спросе 15–20 с → реконнект; калибровка up/down по speedtest через туннель |
| S5 AmneziaWG capability-check | DONE | Форк детектится (`isLXFork`, `core/engine/catalog.go:95-98`); `FeatureAmneziaWG`/`FeatureAmneziaWG3`/`FeatureAmneziaMasquerade` ставятся только при теге `with_awg` (`catalog.go:107-117`); план с AWG/3.1 не выбирает движок без фичи (`refs.go:74-89` → `SelectEngine`/`Missing`); рендер всех полей incl. 3.1 и masquerade (`render.go:402-419`); валидация границ (`validate.go:185+`); J1/J2/J3/Itime для sing-box — жёсткая ошибка, не no-op (`render.go:402-404`). Вопрос WEB-RESEARCH-2 «upstream или amnezia-box?» ЗАКРЫТ: шиппится sing-box-lx (engines.lock) | Остаток: runtime-проверка «движок реально применил поля» до старта сессии (сейчас — статическая гарантия тега); UI-варнинг при подмене бинарника |
| S6 mihomo резолверы | DONE | Разделение: `nameserver` / `proxy-server-nameserver` / `default-nameserver` (bootstrap, никогда через прокси) / `direct-nameserver` (`core/engine/mihomo/rules.go:237-244`); `?h3=true` форсит H3 без тихого даунгрейда (`rules.go:203-208`); валидация behavior↔содержимое rule-provider'ов (`rules.go:97-131`) | Не трогать |
| S7 FakeIP | TODO | DONE: нормализация паттернов (`render.go:672-686`). TODO: interior-wildcard'ы `time.*.com`, `ntp.*.com` по-прежнему ПРОПУСКАЮТСЯ, а не разворачиваются (`plan.go:292-302`); нет `time.windows.com`, нет `+.stun.*.*`; пул `/16` в обоих рендерах (`198.18.0.0/16`), унификации `/15` нет; Mullvad в DNS-пресетах отсутствует вообще (дедлайн 02.11.2026 — нечего убирать, см. противоречие №5) | Развернуть wildcard'ы в явные суффиксы; добавить `time.windows.com`, `+.stun.*.*`; унифицировать пул; AAAA в fakeip только при IPv6=on — проверить |
| S8 PQ key_share | PARTIAL | DONE: JA4-диагностика ловит отсутствие X25519MLKEM768 (`ja4.go:296-309`); PQ=RFC 10024 зафиксирован в WEB-RESEARCH-2. TODO: аудит всех ClientHello (uTLS/REALITY/QUIC) как процесс — не найден; WG PSK: `pre_shared_key` рендерится (sing-box peers), но UI-генератора `wg genpsk` в `app/lib` нет; one-click dual-accept — нет | UI: генератор PSK + тумблер «PQ only» с честной подписью |
| S9 tpws→nfqws/winws | PARTIAL | DONE: модель стратегий с nfqws-полями, `BackendOf`, `NFQWSArgs`, `DefaultStrategy` (modern desync set), валидация, packaging собирает и шиппит nfqws (`core/engine/bypass/bypass.go`, `NFQWS-MIGRATION.md`). TODO (эпик): рантайм-экзекутор — только tpws; `Engine.Apply` fail-closed на nfqws-стратегиях (док фиксирует: «Status: spec only»). Расхождение целей: WEB-RESEARCH-2 говорит целиться в zapret2 (Lua-архитектура), спек — в флаги zapret 72.1 | Экзекутор nfqws/winws (эпик, с владельцем); зафиксировать цель: zapret2-Lua vs 72.1-флаги |
| S10 детектор «сибирской заморозки» | DONE | Дифференциальный детектор parallel-vs-sequential, активный + пассивный, `OnFreeze`-хук (`core/probe/freeze.go`); сессионный трекер: backoff ≥120 с, лестница fp-ротация → SNI-ротация → failover, без возврата к suspect-набору (`core/censor/siberian.go`). Внутренняя пометка: `RotateFingerprint` в probe циклит и suspect-имена — противоречит полевым данным (зафиксировано в комментарии `siberian.go`) | Не трогать; при доработке probe — учесть пометку про suspect-набор |
| S11 подписи/обновления | PARTIAL (код) / BLOCKED (владелец) | DONE: честные non-claims — UI не заявляет верификацию (`app/lib/src/updates.dart:25`); `SHA256SUMS.minisig` скачивается; Linux privileged helper перепроверяет подпись как root (SORA-H1). TODO (код): церемония ключа — pending (блокер владельца); staged rollout/когорты 1%→100% — нет (фид = GitHub releases, не `releases.json`); `blocked_versions` — нет; автооткат — нет; health-check 60 с — нет; metered — нет; трафик обновлений идёт прямым HTTP, не через туннель (`_fetch`, `updates.dart:308`) | После церемонии: `releases.json` с когортами + `blocked_versions` + автооткат; metered; туннель для апдейт-трафика |
| S12 Strict kill switch | DONE | Три уровня Off/Standard/Strict (`core/guard/mode.go`); strict-маркер переживает ребут + `Recover` при старте (`guard.go:131-149,196-233`); Standard — дефолт. Нюанс: персистентность через маркер+Recover, а не через WFP `PERSISTENT`-флаги / nftables `policy drop` + systemd-unit, как предписывал отчёт — цель та же, механизм другой | Не трогать; UI confirm-диалог для Strict + self-test сниффером в CI — проверить наличие |

---

## P0 (WEB-RESEARCH-2)

| # | Статус | Что есть / чего нет | Рекомендуемая зона работ |
|---|---|---|---|
| 1. Xray ≥26.7.11 режет plaintext VLESS/Trojan | TODO | Валидатора с учётом версии ядра нет. Пин 26.3.27 < 26.7.11 — шиппимый движок под breaking change не попадает; `MinVersion` в каталоге = 26.3.27 (`catalog.go`) | Добавить version-aware валидатор для юзерских/будущих Xray ≥26.7.11 (fail-closed вместо «молча не заводится») |
| 2. `"stack": "mixed"`, `gso`, `inet4_*`, DNS-миграция | PARTIAL | `gso`/`inet4_*` в TUN-рендере отсутствуют (остался только `inet4_range` у fakeip — валидная опция); DNS-миграция done кроме DoH3. Остаток = S1-TODO | См. S1 |
| 3. Имена полей XHTTP | DONE | `sessionPlacement`/`sessionKey` в коде отсутствуют полностью — сверять нечего, переименовывать нечего. Xray-рендер: `mode`/`path`/`host` + `downloadSettings` (`xray/render.go:281-291,384-420`); sing-box-lx: `mode`/`host`/`path`/`headers` (`render.go:380-385`) | При бампе Xray сверить рендер с докой 26.x (дешёвая страховка) |
| 4. AnyTLS для mihomo | DONE | Рендерится (`core/engine/mihomo/proxy.go:93-97`), протокол в плане (`plan.go:36`) | Не трогать |
| 5. Диагностика в стиле Clash Verge Rev | PARTIAL | Модуль обширный: `core/diagnostics/` — ja4, dnsleak, dnsspoof, packets_*, throttle, `report.go` с `causeOrNone`. Стиль «реальная причина + ссылка на доку» (как у CVR) — не подтверждена; проверить наличие doc-ссылок в выводе | Добить: логи сервиса в файл + причина + ссылка на доку вместо «cannot start» |
| 6. JA4 stealth-check | DONE | Дубль S3 — `core/diagnostics/ja4.go` | Не трогать |
| 7. SSRF-подтверждение `sora://` | DONE | Парсинг `parseImportLink` (`app/lib/src/desktop/links.dart`); перед импортом — подтверждение: префилленный subscription sheet (URL виден, юзер жмёт add) или confirm-диалог (`app/lib/src/desktop/desktop.dart:569-591`); тихого автоимпорта нет | Не трогать |
| 8. pre-Initial dummy + high-port для QUIC | TODO | Не найдено нигде в `core/` | Дефолт для QUIC-транспортов (hy2/TUIC/QUIC-UTLS) |
| 9. Рейсинг транспортов (HEv3) | TODO | Не найдено; подключение — последовательное | Параллельный рейсинг 2–3 транспорта при коннекте |

---

## Уже сделано net-rd / роем — не трогать (дедуплика)

- hy2 `up_mbps`/`down_mbps` + port hopping — оба рендера; TUIC congestion control — оба рендера.
- Канонический uTLS-модуль (`core/engine/fingerprint.go`) + UI-выбор фингерпринта (`app/lib/src/ui/obfs.dart`).
- mihomo: разделение резолверов + `?h3=true` без даунгрейда + behavior-валидация rule-provider'ов.
- AWG: capability-check по `with_awg`-тегу форка + гейт выбора движка + рендер всех полей incl. 3.1/masquerade + валидация границ.
- SS-2022: валидация методов/ключей по SIP022 (`core/engine/ss.go`).
- FakeIP: нормализация фильтров, `disable_cache`, стратегия IPv6.
- Детектор заморозки: `core/probe/freeze.go` + `core/censor/siberian.go`.
- Kill switch Off/Standard/Strict с персистентным маркером (`core/guard/`).
- XHTTP `downloadSettings` (Xray) + vision/mux взаимоисключение; REALITY dest-валидация и варнинги (`core/engine/reality.go`).
- `sing-box check` opt-in тест (`render_test.go:180`); MTU-дефолт 1500.
- `sora://` deep-link: парсинг + подтверждение перед импортом.
- JA4-диагностика с PQ key-share.

## Противоречия отчёта с реальностью

1. **S1 `independent_cache`**: в коде его нет и не было (`git log -S independent_cache` пуст). Пункт отчёта — не о чем; исправлять нечего.
2. **S1 DoH3**: отчёт — «legacy-формат удалён в 1.14, баг». Код (`render.go:576-581` + комментарий) — «у DoH3 нет legacy-`type`-спеллинга, sing-box сам берёт H3 из префикса». Официальные доки: корректный спеллинг — `"type": "h3"` + `server`/`server_port`, а `h3://` — это «legacy H3 server» (https://sing-box.sagernet.org/configuration/dns/server/http3/). Комментарий в коде неверен, отчёт прав по сути. Нюанс: пин 1.14.3-lx.14 может ещё парсить legacy — точку ставит `sing-box check` против пин-билда.
3. **S5 vs sing-box-lx**: отчёт строился на «upstream AWG не умеет → риск silent no-op». Реальность: sora шиппит sing-box-lx С AWG (engines.lock), а код гейтит выбор движка по `with_awg`-тегу сборки (`catalog.go:107-117`, `refs.go:74-89`). Открытый вопрос WEB-RESEARCH-2 §4 («upstream или amnezia-box?») — ЗАКРЫТ. Остаточный риск — только подмена бинарника юзером, и он закрыт capability-check.
4. **S1 пин ≥1.15**: отчёт рекомендовал бамп; реальность — осознанно 1.14.3-lx.14 (форк трекает 1.14; в `catalog.go` upstream-MinVersion 1.15.0, у lx-форка 1.14.3). Деприкации закрыты версионным гейтом рендера, а не бампом — валидная альтернатива.
5. **S7 Mullvad**: отчёт требует «убрать из пресетов» с дедлайном 02.11.2026; в коде Mullvad в DNS-пресетах отсутствует — убирать нечего, дедлайн не применим.
6. **P0-3**: отчёт предполагал `sessionPlacement`/`sessionKey` в рендере; их нет нигде в коде — сверять/мигрировать нечего.
7. **S9 цель миграции**: спек `NFQWS-MIGRATION.md` целится в флаги вендоренного zapret 72.1, а WEB-RESEARCH-2 фиксирует, что активная разработка ушла в zapret2 (C-демон + Lua-стратегии). Цели расходятся — зафиксировать решение до кодирования экзекутора.
8. **S10 внутреннее**: комментарий в `core/censor/siberian.go` фиксирует, что `RotateFingerprint` в `core/probe` циклит и suspect-имена (Chrome/Safari/iOS), что противоречит полевым данным — код сам помечает расхождение.

## 5 исправленных фактов первого прохода — где отражены

1. **`"stack": "mixed"` = TCP system + UDP gVisor** (не «TCP на gVisor»): явной формулировки в коде/доках не найдено; действие выполнено — `stack` не эмитится для 1.15+ (`render.go:721-728`). Рекомендую добавить комментарий с семантикой, чтобы не воспроизвели старую ошибку.
2. **ECH = RFC 9849** (9848 — только DNS-доставка): отражено — `core/engine/plan.go:58` «Encrypted Client Hello (RFC 9849)»; упоминаний RFC 9848 в коде нет — чисто.
3. **CONNECT-UDP = RFC 9298, CONNECT-IP = RFC 9484**: **НЕ отражено корректно** — `docs/research/masque-transport.md:7-9` (net-rd, 2026-10-19) пишет «CONNECT-UDP — RFC 9484 (обновляет RFC 9298)» и «CONNECT-IP — RFC 9485». Оба номера неверны. Имплементаторы возьмут их из заметки — исправить до кодирования MASQUE.
4. **Теста `lantern` в OONI не существует**: упоминаний в коде/доках нет — чисто, ошибка не воспроизведена.
5. **«QUIC SNI slicing по умолчанию в Xray ≥25.6.8»** (неподтверждено): утверждений в коде/доках нет — чисто.

---

## Итог для планирования

**Чистые TODO (брать в работу):** S7 (FakeIP wildcard'ы/пул), P0-1 (version-aware валидатор Xray), P0-8 (pre-Initial dummy + high-port QUIC), P0-9 (рейсинг транспортов), S9-экзекутор (эпик, после решения zapret2-vs-72.1), S4-stall-watchdog, S8-остаток (UI PSK-генератор, ClientHello-аудит как процесс), S3-CI-трекинг фингерпринтов, S11-кодовая часть (staged/откат/metered/туннель — после церемонии ключа).

**Частичные (добить):** S1 (`download_detour`, DoH3 `type:"h3"`, CI-гейт `sing-box check`, Linux `multi_queue`/`auto_redirect`), S2 (авто-vision + UI-бейдж/фикс), P0-5 (диагностика: причина + ссылка на доку).

**Не трогать (готово):** S5, S6, S10, S12, P0-3, P0-4, P0-6, P0-7 + список net-rd выше.

**Исправить в спеках (не код):** `docs/research/masque-transport.md` — номера RFC MASQUE (9298/9484, не 9484/9485).

**Блокеры владельца (без изменений):** церемония minisign-ключа (S11), решение по цели S9 (zapret2 vs 72.1).
