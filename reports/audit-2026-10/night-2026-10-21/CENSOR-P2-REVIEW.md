# CENSOR-P2-REVIEW — независимое ревью WS/HTTPUpgrade/gRPC + VMess + Trojan

Ревьюер: независимый подотдел CENSOR-P2-REVIEW. Дата: 2026-10-21.
Объект: `ba6b002`, `2bf2df2`, `aad7ae3`, `a4344be`, `df67de6` (ветка
`bugfix/audit-2026-10-19`, ревьюемый HEAD = `df67de6`; ветка продолжала
двигаться соседями во время ревью — все проверки привязаны к `df67de6`).
Метод: чистый worktree от HEAD, симуляция в /tmp-worktree, собственные
конфиги на пинах (`~/workspace/.engines-amd64`: sing-box 1.14.3-lx.22,
Xray 26.10.17, mihomo 1.19.32 — версии подтверждены на бинарях),
перепрогон сьютов и interop-матрицы. Код не правился.

## Итоговая таблица

| # | Пункт | Вердикт |
|---|---|---|
| 1 | Инцидент §9 (чужие ханки в ba6b002/2bf2df2) | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 2 | Рендеры WS/HTTPUpgrade/gRPC + early-data name | **ПРИНЯТЬ** |
| 3 | Валидация плана (whitelist, чужие поля, alterId, credential) | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 4 | Interop + Xray cert-эскалация | **ПРИНЯТЬ** (эскалация подтверждена) |
| 5 | Адаптивность гейтов | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 6 | Мелочи (детерминизм, empty-vs-absent, границы, warning) | **ПРИНЯТЬ** |

**Общий вердикт: ПРИНЯТЬ С ЗАМЕЧАНИЯМИ.** Собственный код P2 дефектов
не содержит; замечания — к полноте §9 отчёта автора и одному остаточному
краю валидации заголовков.

## 1. Инцидент — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

**(а) Список символов: точен для пакета engine, неполон для репозитория.**
В чистом worktree от `df67de6` `go build ./...` падает ровно на шести
символах из §9 и ни на одном другом:
`catalog.go:43,76,139 / validate.go:1331,1340,1355 / singbox/render.go:277,280 /
xray/render.go:254 / mihomo/proxy.go:40,53,229` — `FeatureHy2Obfs`,
`SupportsShadowsocksMethod`, `SupportsSSPlugin`, `MaxHy2BandwidthMbps`,
`ValidHy2Obfs`, `MinHy2HopIntervalSeconds`. Но build останавливается на
первом пакете: после добавления недостающих определений вскрывается
**седьмой символ, не названный в §9** — `AmneziaWG.IsZero`
(`mihomo/proxy.go:151`, `singbox/render.go:574`, `xray/render.go:610`),
чьи вызовы тоже подхвачены именно `2bf2df2` (`git log -S IsZero` по трём
рендерерам показывает только этот коммит), а определение — WIP P4 в
`core/engine/plan.go` (+11 строк, незакоммичено).

**(б) Каждый недостающий символ — чужой незакоммиченный WIP, не дефект P2.**
Определения в общем ворктри: `FeatureHy2Obfs` — `engine.go:102` (P3,
комментарий прямо ссылается на CENSOR-P3); `MaxHy2BandwidthMbps:37`,
`MinHy2HopIntervalSeconds:31`, `ValidHy2Obfs:71`, а также
`ValidTUICCongestion`, `EffectiveTUIC*`, `MinTUICHeartbeatSeconds` —
`quic_defaults.go` (P3, файл **untracked**); `SupportsShadowsocksMethod`
— `ss_support.go:94`, `SupportsSSPlugin`/`SSPluginByName` — `ss_plugin.go`
(P4, оба файла **untracked**); `AmneziaWG.IsZero` — `plan.go:543` (P4).
Собственный код P2 ни одного из этих символов не вводит и не требует.

**(в) Чужие ханки целостны.** По диффам: `ba6b002` подхватил Hy2-валидацию
(bandwidth/obfs/hop + TUIC heartbeat через quic_defaults) в validate.go;
`2bf2df2` — SS-гейты каталога и всех трёх рендереров
(SupportsShadowsocksMethod/SupportsSSPlugin/SSPluginByName), TUIC
effective congestion/heartbeat в sing-box/mihomo, MLDSA65-рендер Xray и
fail-closed sing-box/mihomo, каталоговый `FeatureRealityMLDSA65` (сам
символ при этом в HEAD есть — `engine.go:123`). Половинчатых ханков не
найдено: все вызовы семантически завершены.

**Восстановится ли HEAD-consistency коммитами P3/P4: ДА, с условием.**
Симуляция (worktree от `df67de6` + только 5 файлов-источников определений
из общего ворктри: `engine.go`, `plan.go`, `quic_defaults.go`,
`ss_support.go`, `ss_plugin.go`): `go build ./...` — чисто,
`go vet ./engine/... ./parser/` — чисто. Условия: владельцы должны
закоммитить именно эти файлы (три из них сейчас untracked — риск потери
выше, чем у просто грязных файлов), а для полной зелени тестов P3 ещё
нужен его остальной render-WIP: в симуляции падает
`TestRenderHysteria2BandwidthAndHopping` (singbox) — не из-за битости
подхваченных ханков, а из-за отсутствующего продолжения P3 в ворктри.

Замечание к §8 отчёта автора (среднее): «единственный FAIL пакета —
probecaps» верно только в полном грязном ворктри автора. В состоянии
HEAD+определения дополнительно падают `TestCensorP1KeyShareGate` (P1) и
`TestCredentialDocumentMatchesLegacyMapForm` (control, xmux-поля P1) —
все три к P2 не относятся, но формулировка §8 завышает зелень HEAD.

## 2. Рендеры — ПРИНЯТЬ

Код: sing-box WS — `wsHeaders()` (явный Host побеждает одноимённый
заголовок) + `early_data_header_name` (render.go:499,503), HTTPUpgrade —
`headers` (render.go:524-528); Xray — `headers` на ws/httpupgrade/xhttp
(render.go:309-351), `earlyDataHeaderName` (308), gRPC полный набор
`authority`/`multiMode`/`user_agent` (324-325); mihomo — ws-opts headers +
`early-data-header-name` (proxy.go:222, config.go:179), httpupgrade через
ws-opts, gRPC `grpc-user-agent` (proxy.go:237).

Собственные пробы на пинах (не рендеры автора — ручные конфиги с теми же
написаниями, UA `ReviewUA/1.0`, кастомное имя early-data):
sing-box `check` — OK; Xray `run -test` — OK; mihomo `-t` — successful
(включая ws-opts headers и `early-data-header-name: X-Custom-ED`).
Плюс перепрогон авторских `TestBinaryAcceptsCensorP2Transports` — PASS во
всех трёх пакетах на реальных пинах, и трафик interop (§4) идёт с
заголовками в плане. Оговорка: доставку конкретного заголовка до сервера
по проводу interop не наблюдает (цель — локальный HTTP за Xray-сервером);
доказательство — рендер-контент + бинарная приёмка + трафик.

gRPC-гейты согласованы на всех трёх уровнях: каталог
(`catalog.go:414-443`: authority/multi-mode missing на sing-box+mihomo,
user-agent missing только на sing-box) и рендер-backstop'ы
(sing-box render.go:512 отказывает по всем трём полям; mihomo proxy.go:229
— по authority/multi-mode). Собственная проба факта mihomo: block-YAML с
`authority`, `multi-mode`, `bogus-key` в grpc-opts и мусорным ключом
прокси — `mihomo -t` **successful** (молча игнорит, как заявлено).
Собственная проба sing-box: gRPC transport с ключом `authority` —
`FATAL … json: unknown field "authority"` (отказ
...[truncated 4158 chars]