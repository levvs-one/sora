# 5-проходное ревью Go-ядра sora — partial-sora-go

Ветка: `bugfix/audit-2026-10-19` (не переключалась, не пушилась).
Зона: `core/` (кроме `core/gen` — поверхностно; `core/testdata` — глазами), `service/`, `proto/`.
Дата ревью: 2026-10-19.

## Охват по проходам

| Проход | Линза | Файлов |
|---|---|---|
| 1 | Безопасность | 203/203 (+2 gen skim, 1 proto, 4 service-файла) |
| 2 | Корректность | 203/203 |
| 3 | Живучесть | 203/203 |
| 4 | Качество кода | 203/203 |
| 5 | Системы (контракты) | 203/203 |

Непокрытых файлов нет. `core/gen` (2 файла, ~10k строк) — просмотрены поверхностно: сгенерированный protobuf/gRPC код, расхождений с `proto/sora/core/v1/core_control.proto` не найдено. Тестовые файлы (`*_test.go`) — просмотрены и засчитаны в покрытие; несколько тестов напрямую фиксируют поведение, затронутое находками (см. ниже).

**Важно о контексте:** во время ревью на ветку параллельно ложились фичи другого агента (F2 benchmark, F3 dnsleak, F6 overrides, F7 watchdog). Пять файлов появились уже в ходе ревью (`core/control/override.go`, `core/control/benchmark.go`, `core/subscription/override.go`, `core/probe/bandwidth.go`, `core/session/watchdog.go`) — все проверены. Часть моих ранних наблюдений (неподключённые RPC `BenchmarkServers`/`GetBenchmarks`, непрокинутый `DataDir`) конкурент уже закрыл; ниже отмечено что.

Каждый фикс-коммит: `go build ./...` + `go vet` в `core/` после каждого изменения. Полный `go test ./...` в конце: всё зелёное, кроме одного environment-зависимого теста (см. «Проверено, не является проблемой»).

---

## Проход 1 — Безопасность

### R5-SG-1-1 · High · `core/secret/store.go` — `Apply()` паниковал на пустых секретах — ИСПРАВЛЕНО
`Apply()` сравнивал `&kept[0] != &material[0]` для поиска заменённых значений. Пустой слайс (`len==0`) → `index out of range` → паника всего ядра. Пустые значения запрещены в `Put`/`Apply`, но `unseal()` их не отбраковывал: crafted vault с пустым секретом ронял ядро при любом `Apply()`. Исправление (коммит `72abbb8`): цикл затирания переписан на множество тронутых референсов (без сравнения указателей); `unseal()` отвергает пустые секреты как corrupt.

### R5-SG-1-8 · High · `core/engine/supervise/binary.go` — `Discover()` исполнял бинарь ДО проверки дайджеста — ИСПРАВЛЕНО
`Probe()` (запуск `--version`) вызывался раньше `checkDigest()`, вопреки задокументированному инварианту SORA-H5 («rejected instead of executed») и комментарию теста `TestDiscoverVerifiesDigest` («only digest-verified binaries are executed»). Подменённый бинарь в engines-dir исполнялся при discovery. Исправление (коммит `b07c226`): проверка дайджеста по пути кандидата (`checkDigestPath`/`verifyPathDigest`) до `Probe()`; `VerifyDigest` делегирует той же проверке. Остаточный TOCTOU verify→exec (подмена между проверкой и запуском) — в спеке ниже.

### R5-SG-1-2 · Medium · `core/secret/store.go` — `seal()` не затирал JSON-плейнтекст — ИСПРАВЛЕНО
`payload` (все секреты в открытом виде) оставался в памяти до GC. Добавлен `defer wipe(payload)` (`72abbb8`).

### R5-SG-1-3 · Medium · `core/secret/store.go` — `read()` читал vault без лимита — ИСПРАВЛЕНО
`os.ReadFile` до `unseal()`; `MaxVaultBytes` проверялся только на запись. Огромный файл → OOM до проверки целостности. Теперь размер сверяется со `Stat` против `MaxVaultBytes` до чтения (запись больше никогда не создаёт) (`72abbb8`).

### R5-SG-1-10 · Medium · `core/guard/nftables.go` — сырые bypass-строки интерполировались в nft-ruleset — ИСПРАВЛЕНО
`NftRuleset()` вставлял `bypass []string` как есть в `daddr <строка>`. RPC-путь спасал запрет пробелов в `checkBypass`, но CLI-флаг `--bypass` не валидировался вообще. Теперь каждая запись парсится как `netip.Prefix`/`netip.Addr` и рендерится каноническая маскированная форма; непарсящееся пропускается (fail closed — kill switch блокирует вместо bypass) (`b07c226`).

### R5-SG-1-13 · Medium · `core/subscription/subscription.go` — `publicAddr()` считал CGNAT и special-use «публичными» — ИСПРАВЛЕНО
`IsGlobalUnicast()` в Go возвращает true для `100.64.0.0/10` (CGNAT), documentation (`192.0.2.0/24` и др.), benchmarking (`198.18.0.0/15`), reserved (`240.0.0.0/4`) — проверено исполнением. `checkDial` пропускал их при `allowPrivate=false`, открывая DNS-rebinding в ISP-внутренние сети. Теперь явный список `specialUsePrefixes` отвергается; тест `dial_test.go` расширен (`87e5ac8`).

### R5-SG-1-14 · Medium · `core/logs/privacy.go` — сжатый IPv6 не маскировался — ИСПРАВЛЕНО
Регекс требовал 3+ полных групп (`::1`, `2001:db8::1` без скобок проходили). Добавлен паттерн по двойному двоеточию (в таймстампах его не бывает — ложных срабатываний нет); тест расширен (`87e5ac8`).

### R5-SG-1-4 · Low · `core/secret/key.go` — обёрнутый ключ и payload не затирались — ИСПРАВЛЕНО
`loadOrCreateKey`: `wrapped` (под FileProtector — сырой ключ!) и `payload` оставались в памяти на всех путях. Добавлены wipe через defer (`72abbb8`).

### R5-SG-1-5 · Low · `core/secret/store.go` — `Open()` затирал key, но не id — ИСПРАВЛЕНО
При ошибке `read()` добавлен `wipe(id)` (`72abbb8`).

### R5-SG-1-6 · Low (doc) · `core/ipc/polkit_linux.go` — комментарий противоречил политике — ИСПРАВЛЕНО
«Active local users need no password» для `PolkitAction`, хотя `service/linux/sora.policy` требует `allow_active=auth_self` для control (комментарий для read-действия был верен). Исправлен (`87e5ac8`).

### R5-SG-1-3b · Low · `core/engine/xraytun/bridge.go` — непроверенный type assertion — ИСПРАВЛЕНО
`e.tun.(engine.ConnectionTracker)` в `Select()` паниковал бы при нарушении инварианта. Заменён на comma-ok с ошибкой (`87e5ac8`).

### R5-SG-1-7 · Info · сокет 0o666 на Linux — by design
Методные interceptors корректны, неизвестные методы fail closed. Замечание: свежий D-Bus connect на каждый handshake внутри Accept-loop — локальное DoS-усиление (спек).

### R5-SG-1-9 · Low · `loadDigests()` — нет hex-валидации, дубликаты побеждает последний (спек)
### R5-SG-1-11 · Low · `nftables_linux.go` `isMissingTable()` матчит локализованный текст nft; `apply()` хардкодит `CodePermissionDenied` и для синтаксических ошибок (спек)
### R5-SG-1-12 · Low · `NftBinForTest` — экспортируемая мутабельная var в прод-бинаре (спек: build-tag)
### R5-SG-1-15 · Low · Windows pipe squatting: фиксированное имя `\\.\pipe\sora-core-v1`, множественные инстансы (спек)
### R5-SG-1-16 · Low · `core/diagnostics` `CapturePackets` экспортирована, прод-вызывающих нет — мёртвый код с сырым захватом (спек)
### R5-SG-1-17 · Low · `secureDataDir` (windows): старые секреты остаются под слабыми ACL в `<dir>.untrusted-<ts>` (спек)
### R5-SG-1-18 · Low · `peerOf` (windows): PID-reuse TOCTOU (спек)
### R5-SG-1-19 · Low · `subscriptionBook.load()`: клиент через `PutSecret` может подсунуть `u1_*_rec` как подписку после рестарта — харденинг: проверять `ref == recordRef(rec.ID)` (спек)
### R5-SG-1-20 · Low · `keyValuePattern` не маскирует JSON `"password": "secret"` (спек)
### R5-SG-1-21 · Low · `stateLocked`: зачистка bearer из `WebPageUrl` хрупким точным сравнением (спек)
### R5-SG-1-22 · Low-Medium · geodata `.dat` рядом с бинарями НЕ покрыты `engines.digests` — подмена GeoIP.dat меняет routing-решения без нарушения дайджеста (спек: включить в манифест)

---

## Проход 2 — Корректность

### R5-SG-2-1 · `core/session/runner.go` `guardApplied` — ЛОЖНОЕ СРАБАТЫВАНИЕ, отозвано
Флаг перед `Apply()` выглядит подозрительно, но тест `TestPartialApplyKeepsOwnershipWhenRollbackFails` фиксирует намеренную семантику: при частичном применении composite-guard с упавшим rollback сессия обязана сохранить владение для ретрая в `Disconnect`. Моя первая правка ломала тест — откачена. Поведение корректно.

### R5-SG-2-2 · Low · `subscriptionBook.loadList()`: `ListParts` из хранимой записи не ограничен — цикл `secrets.Get` по коррапченой записи (спек: bound)
### R5-SG-2-4 · Low · `core/logs/logs.go` `Write()`: свёртка с engine-timestamp из прошлого двигает время записи назад (спек: clamp)
### R5-SG-2-5 · Low · `control/plan.go` `dnsFromProto`: молча обрезает резолверы сверх `MaxDNSServers` вместо ошибки (спек)
### R5-SG-2-6 · Low · `engine/refs.go` `RulePort`: только `Atoi`, без проверки 0–65535 (спек)
### R5-SG-2-7 · Low · `engine.ParseVersion`/`Version.Less` игнорируют PreRelease — beta проходит minimum-version checks (спек)
### R5-SG-2-8 · Low · `fields.go` `isDomain` требует точку — `localhost` и single-label отвергаются (спек)
### R5-SG-2-9 · Medium-Low · `core/control/override.go` `SaveSubscriptionOverride` молча отбрасывает `ExtraRules` из запроса (файл конкурента F6; `Get` их возвращает — мёртвое поле контракта) (спек)
### R5-SG-2-10 · Low · `SaveSubscriptionOverride` не валидирует/не ограничивает `Renames` (размер значений, контрольные символы) — файл растёт без bound, rename с `\n` едет в UI (спек: bound + validateDisplayName)

---

## Проход 3 — Живучесть

### R5-SG-3-1 · Low-Medium · `registry.go` `measureThroughController`: `sem <- struct{}{}` без select на ctx — hang при отмене, если воркеры застряли (спек)
### R5-SG-3-2 · Low-Medium · `App.Close()` (`main.go`): `GracefulStop()` может висеть вечно на зависших стримах `WatchEvents` (спек: таймаут + `Stop()`)
### R5-SG-3-3 · Low · `xray/engine.go` `measureBatch`: тот же паттерн семафора без ctx (спек)
### R5-SG-3-4 · Low · `probe/bandwidth.go`: история benchmarks не prune'ится (только TTL для отображения) — JSON растёт вечно, грузится целиком в память (спек: cap/prune)
### R5-SG-3-5 · Low · `probe/bandwidth.go` `loadHistory`: `os.ReadFile` + `json.Unmarshal` без лимита размера (спек: Stat-check)

Проверено и ОК: журнал SORA-H6, supervisor watch/retry с budget, `compositeGuard` rollback, tunroute rollback через `errors.Join`, probe-каналы закрываются при cancel, watchdog F7 корректен (rolling window, once-per-episode, reset при восстановлении).

---

## Проход 4 — Качество кода

### R5-SG-4-1 · Low-Medium · `engine.Redactor.Add`: O(n²) дедуп + неограниченный рост через `Apply()` (спек: bound)
### R5-SG-4-2 · Low · `probe.toWire(err, host)`: параметр `host` рудиментарен (спек: убрать)
### R5-SG-4-3 · Low · `tunroute_linux.go` `unroute()`: матч «FIB table does not exist» только на английском (спек: код выхода вместо текста)
### R5-SG-4-4 · Info · `redactorCache`: проанализирован, не баг (single-session инвариант)
### R5-SG-4-5 · Low · `cli.go --print-token`: base64 vs raw 32 байта wire — недокументировано (спек: doc)
### R5-SG-4-6 · Info · `planFromProto` хардкодит `LogLevel: "debug"` — осознанный трейдофф
### R5-SG-4-7 · Low · `normalizedLink`: дедуп пропускает варианты с default-портом/trailing slash (спек)
### R5-SG-4-8 · Low · `PrivatePreference = [singbox, mihomo, xray]`: sing-box первым, но никогда не проходит `FeaturePrivateControl` — мёртвый вес в порядке (спек: убрать)
### R5-SG-4-9 · Low · `core/control/benchmark.go`: мёртвый `byID` map (строится, не читается) (спек)

---

## Проход 5 — Системы (контракты)

Контракты `control → session → guard/engine/secret`, `ipc` auth-уровни, `secret` reference-модель — держатся. Проверено:
- `SelectEngine` + `RequiredFeatures` + `Missing()` корректно отсекают sing-box для private-планов;
- `session.Manager` single-session инвариант; `bypass.Engine` обёртка переписывает план до `admit()`;
- Xray profile render: file-ключи strip'аются, inbounds/reverse заменяются, probe-теги переименовываются консистентно;
- mihomo `Prepare` копирует geodata атомарно (tmp+rename), но **вне дайджест-манифеста** (R5-SG-1-22);
- systemd-юнит (`service/linux/sora-core.service`) — образцовый: свой пользователь, `NoNewPrivileges`, `ProtectSystem=strict`, минимальные capabilities, `UMask=0077`;
- polkit-policy согласована с кодом после правки комментария (R5-SG-1-6);
- proto-контракт 1.9: `BenchmarkServers`/`GetBenchmarks`/`SaveSubscriptionOverride`/`GetSubscriptionOverride` — конкурент дописал хендлеры и wiring уже в ходе ревью; расхождений gen vs proto нет.

Нарушений инвариантов, задокументированных в комментариях, после фиксов не осталось, кроме отмеченных спекой.

---

## Проверено, НЕ является проблемой

- `CheckDnsLeaks` вне `readOnlyMethods` — intentional (proto: «Requires the control authenticator»).
- `guardApplied=true` до `Apply()` — intentional (тест `TestPartialApplyKeepsOwnershipWhenRollbackFails`).
- `PrivatePreference` с sing-box первым — безвредно (feature-check отсекает).
- `TestTunAndFakeIPAvoidLANAndEachOther` падает в этой VM: интерфейс `host0` `198.19.0.2/30` пересекается с тестовым пулом `198.19.0.0/16`. Environment-зависимо, к изменениям отношения не имеет.
- `StableKey` содержит хост в открытом виде — осознанно (человекочитаемый ID для UI/логов; redactor покрывает).

---

## Сводная таблица severity

| Severity | Найдено | Исправлено сразу | Осталось спекой |
|---|---|---|---|
| Critical | 0 | — | — |
| High | 2 | 2 | 0 |
| Medium | 6 | 5 | 1 (R5-SG-1-22) |
| Low | ~25 | 6 | ~19 |
| Info | 4 | 0 | 0 (замечания) |

Ложных срабатываний: 1 (R5-SG-2-1, отозвано с тестом-доказательством).

## Топ-3 критичных

1. **R5-SG-1-8 (High)** — исполнение бинаря до проверки дайджеста нарушало SORA-H5; подменённый engine исполнялся при discovery. Исправлено: verify-before-execute.
2. **R5-SG-1-1 (High)** — паника ядра через crafted vault с пустым секретом (DoS). Исправлено: touched-set + reject empty в unseal.
3. **R5-SG-1-10 (Medium)** — инъекция в nft-ruleset через невалидированный `--bypass`. Исправлено: канонизация через netip, fail closed.

## Исправлено сразу (коммиты)

- `72abbb8a2a091686e7a0421abd3fd7b3b676919e` `[review-5pass] secret: fix Apply panic on empty values, wipe plaintext buffers, bound vault reads` — R5-SG-1-1…1-5.
- `b07c226f245d3ca8226b41ef9eb289b047f8450a` `[review-5pass] supervise+guard: verify digest before probing, canonicalize nft bypass` — R5-SG-1-8, R5-SG-1-10.
- `87e5ac8937bce8c890b84be2388093d69b531cd7` `[review-5pass] ipc/xraytun/subscription/logs: harden type assert, dial policy, destination masking` — R5-SG-1-6, R5-SG-1-13, R5-SG-1-14, R5-SG-2-3.

После каждого: `go build ./...` + `go vet` в `core/` — чисто. Финальный `go test ./...`: зелёный, кроме environment-зависимого `TestTunAndFakeIPAvoidLANAndEachOther` (интерфейс VM).

## Осталось спекой (для отдельного прохода)

Архитектурное/не-мелкое: R5-SG-1-7 (D-Bus connect per handshake), R5-SG-1-9, R5-SG-1-11, R5-SG-1-12, R5-SG-1-15…1-22, R5-SG-2-2, R5-SG-2-4…2-10, R5-SG-3-1…3-5, R5-SG-4-1…4-9 — детали в разделах выше. Отдельно: re-verify дайджеста в `supervise.Start` (закрыть TOCTOU verify→exec полностью), https-only валидация кастомного benchmark URL при дозревании RPC.
