# 5-проходное ревью: Go-ядро sora-legacy (R5-LG)

- Ветка: `bugfix/audit-2026-10-19` (репозиторий `~/workspace/bug-hunt/sora-legacy`), коммиты НЕ пушились.
- Дата ревью: 2026-10-19. Язык отчёта: русский.
- Зона: `core/` (кроме `core/gen` — generated), `service/`, `proto/`, `docs/`.

## 1. Охват

Всего в зоне **182 `.go`-файла** (список: `~/workspace/bug-hunt/reports/review-5pass/files-list.txt`).

| Категория | Файлов | Глубина |
|---|---|---|
| Не-тестовые `.go` в `core/` (~109) | 109 | Прочитаны целиком, каждый — всеми 5 линзами |
| `*_test.go` (73) | 73 | Просмотрены все (имена, ключевые ассёрты, точечное чтение); полный прогон `go test ./...` |
| `proto/sora/core/v1/core_control.proto` | 1 | Прочитан (контракт) |
| `docs/architecture/*`, `docs/*.md` | — | Прочитаны архитектурные; противоречий с кодом не найдено |
| `service/linux/*` (unit, polkit) | — | Проверены линзой 1, hardening на месте |

Покрытие: **182 файла × 5 проходов = 910 проходо-слотов, непокрытых нет.**

Проверки после каждого коммита: `go build ./...` + `go vet ./...` в `core/` — чисто.
`go test ./...`: всё зелёное, кроме **одного предсуществующего окруженческого**
падения: `TestTunAndFakeIPAvoidLANAndEachOther` — в песочнице есть интерфейс
`host0` с `198.19.0.2/30`, пересекающийся с тестовым fake-IP пулом `198.19.0.0/16`
(тест корректно отвергает такой пул; на чистой машине проходит).

## 2. Находки по проходам

Формат: `ID | Severity | файл:строки | статус`.

### Проход 1 — Безопасность

**R5-LG-1-1 | Low-Medium | `core/subscription/subscription.go:320`, `core/probe/probe.go:219` | ИСПРАВЛЕНО (1a25f0f)**
`publicAddr()` считал «публичными» диапазоны, для которых Go возвращает
`IsGlobalUnicast()==true`: `100.64.0.0/10` (CGNAT), `192.0.0.0/24`,
`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24` (TEST-NET),
`198.18.0.0/15` (benchmarking), `2001:db8::/32`. Отягчающее: `192.0.2.0/24`
и `2001:db8::/32` — собственные TUN-пулы Sora: вредоносный редирект подписки
или цель пробинга могли указывать на локальный TUN-адаптер. В оба зеркала
добавлен явный blocklist `specialUse`; тесты покрывают новые диапазоны.
Попутно: тест редиректа использовал `provider.example`, который резолвер
песочницы sinkhole'ит в `198.18.160.30`, — тест переведён на публичный
IP-литерал, чтобы не зависеть от DNS окружения.

**R5-LG-1-2 | Medium | `core/probe/probe.go:148,183` | ИСПРАВЛЕНО (f31f52e)**
DNS-rebinding TOCTOU: `isPrivateTarget` резолвил имя и проверял IP, затем
`dial` резолвил то же имя заново. Злой резолвер отдаёт публичный IP при
проверке и приватный при dial — пробер становится оракулом локальной сети
(комментарий при этом утверждал, что работает «как subscription.dialChecked»).
Исправление тем же паттерном: `Control`-хук диалерa (`checkDialTarget`)
перепроверяет адрес, к которому реально идёт подключение, на обоих путях
(plain и TLS). `errs.From` сохраняет permission-denied сквозь обёртку dialer'а.

**R5-LG-1-3 | Low | `core/engine/registry/registry.go:69` | ИСПРАВЛЕНО (1800571)**
`Discover()` принимал zapret'овский `tpws` по имени и битам исполняемости,
тогда как движковые бинарники сверяются с `SHA256SUMS`. Теперь `verifyTpws`
прогоняет `tpws` через тот же `VerifyDigest`, когда манифест его содержит;
манифест без `tpws` (текущая упаковка — zapret ships separately) сохраняет
прежнее поведение, чтобы не ломать bypass. Тест покрывает 4 случая.

**R5-LG-1-4 | Low | `core/guard/firewall_windows.go:257` | СПЕКА**
WFP kill switch разрешает **любой** `*.exe` из `enginesDir`, а не найденные
бинарники. Практический риск низкий (запись в enginesDir в service-режиме
требует прав администратора, который и так может снять kill switch), но это
defense-in-depth дыра: любой процесс от учётки ядра, подсунувший exe в
каталог, получает сеть мимо kill switch. Спека: добавить в
`guard.FirewallOptions` список обнаруженных бинарников (`registry.Binary`)
и использовать его вместо `filepath.Glob("*.exe")`.

**R5-LG-1-5 | Low | `core/engine/validate.go` (новое), `core/engine/singbox/render.go:210` | ИСПРАВЛЕНО (5fadb0a)**
Значения `obfs`/`obfs-host` из подписок интерполировались в строку
`plugin_opts` sing-box (`"obfs="+o.Obfs+";obfs-host="+o.ObfsParam`) без
валидации — возможна инъекция опций плагина через `;`. `Outbound.validate()`
теперь принимает для shadowsocks только `http`/`tls` и требует от
`obfs-host` быть bare hostname/IP.

### Проход 2 — Корректность

**R5-LG-2-1 | Low | `core/secret/store.go:255` | ИСПРАВЛЕНО (10ae560)**
`Apply` сравнивал `&kept[0] != &material[0]` — паника на пустом значении.
`unseal` пустые значения не отвергал, так что подделанный vault ронял процесс.
Теперь: `unseal` отвергает пустые/сверхлимитные секреты и `len(items) >
MaxSecrets`; само сравнение стало пусто-безопасным (`sameBacking`).

**R5-LG-2-2 | Low | `core/secret/store.go:312` | ИСПРАВЛЕНО (10ae560)**
`read()` делал `os.ReadFile` без ограничения — файл любого размера тянулся
в память на старте (запись ограничена `MaxVaultBytes`, чтение — нет).
Теперь чтение через `io.LimitReader(MaxVaultBytes+1)` с отказом при превышении.

**R5-LG-2-3 | Low | `core/parser/parser.go:226` | ИСПРАВЛЕНО (9cb8dad)**
`uuidRE` требовал version-nibble `[1-5]` — отвергались валидные UUID v6/v7/v8
(RFC 9562). Стало `[1-8]`.

**R5-LG-2-4 | Low | `core/control/plan.go:ruleTypeOf` | ИСПРАВЛЕНО (9cb8dad)**
`::1` классифицировался как `RulePort` (из-за `":"`), `1.2.3.4` — как
`RuleDomainKeyword` (молча неверная маршрутизация!). Bare IP-адреса теперь
определяются через `netip.ParseAddr` и классифицируются как `RuleIPCIDR` —
контракт требует сеть вида `203.0.113.0/24`, так что они отвергаются валидацией
с точной ошибкой вместо тихой мисклассификации.

**R5-LG-2-5 | Low | `core/engine/refs.go:Rule.validate` | ИСПРАВЛЕНО (9cb8dad)**
`RulePort`/`RuleSrcPort` принимали `0`, `-1`, `99999` (`strconv.Atoi` без
диапазона) и уходили в рендеры. Теперь `1–65535`.

**R5-LG-2-6 | Low | `core/engine/xray/engine.go:Handshake` | ИСПРАВЛЕНО (9cb8dad)**
`return "", conn.Close()` — ошибка закрытия (редкая, незначащая) выдавалась
за провал handshake при успешном dial. Теперь `_ = conn.Close(); return "", nil`.

**R5-LG-2-7 | Low | `core/parser/parser.go:315,625,747` | ИСПРАВЛЕНО (9cb8dad)**
`parseList`/`parseJSON`/`parseYAML` добавляли `ItemReason` на КАЖДУЮ строку
сверх лимита — подписка на ~1M строк раздувала отчёт на десятки МБ. Новый
`appendReason` ограничивает 100 записями на категорию; счётчики считают дальше.

**R5-LG-2-8 | Low | `core/engine/validate.go` (новое) | ИСПРАВЛЕНО (9cb8dad)**
Порты пиров WireGuard не валидировались вообще; sing-box делал `port, _ :=`
(Atoi с игнором ошибки → молча `port: 0`). `validatePeerEndpoint` проверяет
форму `host:port` и диапазон порта на уровне `Outbound.validate()`.

**R5-LG-2-9 | Low | `core/engine/xraytun/bridge.go:179` | ИСПРАВЛЕНО (9cb8dad)**
`e.tun.(engine.ConnectionTracker)` без comma-ok — паника, если TUN-движок
не реализует интерфейс. Теперь явная ошибка.

**R5-LG-2-10 | Low | `core/engine/xray/profile.go:probeProfile` | СПЕКА**
`probeProfile` переименовывает теги аутбаундов префиксом, но НЕ
переименовывает ссылки на них в `selector` балансировщиков и правилах
маршрутизации внутри профиля — измерение профиля с балансировщиком ломается.
Спека: при переименовании обходить `balancers[].selector`,
`routing.rules[].outboundTag|balancerTag` и `observatory.subjectSelector`.

### Проход 3 — Живучесть

**R5-LG-3-1 | Low | `core/ipc/ipc.go:Accept` | ИСПРАВЛЕНО (5bc06ec)**
Цикл `Accept` на неавторизованных коннектах крутился без паузы — локальный
флуд коннектами выжигал CPU. Добавлен backoff 10мс×N с потолком 250мс.

**R5-LG-3-2 | Low-Medium | `core/logs/watch.go:Watch`, `core/logs/logs.go:normalized` | ИСПРАВЛЕНО (5bc06ec)**
Два слоя: (а) `Watch` аллоцировал канал `len(replay)+512` — при большом
`MaxEntries` десятки МБ на watcher; теперь replay ограничен 4096 записями,
остаток считается `lost` (контракт `WatchLogs` уже просит таких клиентов
продолжить через `Query`); (б) `Settings.normalized()` теперь ограничивает
сверху `MaxEntries` (200k) и `MaxBytes` (256МБ) — раньше один вызов
`SetLogSettings` мог увести запись в гигабайты.

**R5-LG-3-3 | Low | `core/cmd/sora-core/main.go:App.Close` | ИСПРАВЛЕНО (5bc06ec)**
`grpc.GracefulStop()` без таймаута — зависший клиентский стрим вешал шатдаун
навсегда. Теперь 10с, затем `Stop()`.

**R5-LG-3-4 | Low | `core/engine/bypass/bypass.go:Apply` | ИСПРАВЛЕНО (5bc06ec)**
`Apply` держал `e.mu` во время `start()` (до 5с ожидания `waitListening` на
стратегию), блокируя `Stop`. Перестроено: остановка лишнего — под замком,
старты — без замка с идемпотентной публикацией (`publish` гасит дубликат
при гонке двух `Apply`); ожидание слушателя чтит контекст вызывающего.

**R5-LG-3-5 | Info | `core/engine/bypass/bypass.go:190` | ЗАМЕЧАНИЕ**
`keep()` перезапускает упавший `tpws` бесконечно (backoff с потолком 2 мин,
без бюджета попыток). Осознанный выбор для DPI-обхода, но стоит держать в
уме: вечно падающий tpws = вечный спавн процессов. Кандидат на бюджет
перезапусков в будущем.

### Проход 4 — Качество кода

**R5-LG-4-1 | Info | `core/control/plan.go:checkBypass` | ИСПРАВЛЕНО (9cb8dad)**
Комментарий обещал отказ «не домену/адресу/сети», код режектил только
whitespace. Комментарий приведён к коду.

**R5-LG-4-2 | Low | `core/control/errors.go:27` | СПЕКА**
`wireCodes` мапит `errs.CodeUnsupported` → `SORA_ERROR_CODE_INVALID_ARGUMENT`.
«Не поддерживается» ≠ «невалидный аргумент»: клиент не отличит «движок не
умеет» от «ты прислал мусор». Спека: завести в контракте
`SORA_ERROR_CODE_UNSUPPORTED` (минорное расширение proto, обратно совместимо:
старые клиенты увидят неизвестный enum → 0/UNSPECIFIED) либо мапить на
ближайший честный код с ключом `core.*.unsupported`.

**R5-LG-4-3 | Info | `core/control/subscriptions.go:182` | ИСПРАВЛЕНО (4602748)**
`newSubscriptionID`: ошибка `rand.Read` мапилась на `KeySecretStoreUnavailable`.
Стало `KeyInternal` (`core.internal.unexpected`).

**R5-LG-4-4 | Info | `core/cmd/sora-core/check.go:74`, `cli.go:80` | ИСПРАВЛЕНО (4602748)**
Неверный `--log-level` и ошибка парсинга флагов мапились на
`KeyUnauthenticated`. Стало `KeyInvalidRequest`.

**R5-LG-4-5 | Info | `core/engine/clashapi/ops.go:202` | ИСПРАВЛЕНО (4602748)**
`isRefused` матчил **любой** `*net.OpError`, а не отказ в соединении.
Переименовано в `isNetworkError` с честным doc-комментарием.

**R5-LG-4-6 | Info | `core/engine/mihomo/proxy.go:294` | ИСПРАВЛЕНО (4602748)**
`sortedMap` не сортировал — просто копировал (сортирует и так `yaml.Marshal`).
Функция удалена, литерал инлайн.

**R5-LG-4-7 | Info | `core/diagnostics/report.go:22` | ИСПРАВЛЕНО (4602748)**
Текстовый `report()` пишет `id: <sessionID>`, а комментарий `Summary()`
говорит, что session ID опускается, — выглядело противоречием. Doc `report()`
теперь явно фиксирует различие (ID нужен для корреляции саппорт-бандла).

**R5-LG-4-8 | Info | `core/control/server.go:1276` | ИСПРАВЛЕНО (4602748)**
Комментарий `ExportDiagnostics` «already-redacted… Clients cannot expand its
contents» врал для веток PCAPNG/EVTX (сырые захваты). Комментарий уточнён
по форматам.

**R5-LG-4-9 | Low | `core/logs/logs.go:173` | ИСПРАВЛЕНО (4602748)**
Свёртка идентичных сообщений: `at.Sub(last.Time) < foldWindow` истинно и для
отрицательной дельты — запись с более старым timestamp схлопывалась в новую
и **отматывала часы записи назад**. Добавлена проверка `!at.Before(last.Time)`.

**R5-LG-4-10 | Info | `core/engine/singbox/render.go:564` | ЗАМЕЧАНИЕ**
`singbox.tun()` ставит MTU 9000 по умолчанию, тогда как валидация плана
режет MTU > 1500. Не баг (9000 валиден для sing-box TUN), но значения по
умолчанию расходятся между движками (mihomo: 1500). Кандидат на унификацию
дефолтов.

Дополнительно: поправлен устаревший комментарий `TunnelMode` в
`core/session/guard.go` («system, application or none» — `none` не производится).

### Проход 5 — Системы

**R5-LG-5-1 | Medium | `core/engine/refs.go:80`, `core/control/plan.go:316`, рендеры | ИСПРАВЛЕНО (dc83bf1)**
`isBuiltInTarget` была продублирована с **расходящимися** множествами:
control `{direct,block,reject}` vs engine `{direct,reject,pass,dns}`.
Последствия: `block` проходил control-валидацию и падал в КАЖДОМ рендере;
`pass`/`dns` режектились на входе, хотя engine их принимал; `reject` падал
в sing-box на этапе рендера (поздняя ошибка после старта сессии).
Теперь единый экспортируемый `engine.IsBuiltInTarget` (union из пяти),
control использует его, и все рендеры обрабатывают все пять:
mihomo `block→REJECT`; sing-box `block→reject`-action, `pass→direct`,
match-all `dns→hijack-dns`; xray `block→blackhole`, `pass→direct`,
`renderProfile` выровнен. Тесты: control принимает все пять, каждый рендер
рендерит все пять.

**R5-LG-5-2 | Medium | `core/control/server.go:39`, `proto/.../core_control.proto:202-204` | СПЕКА**
`SessionPlan.BypassSettings` (enabled + rules) валидируется (`checkBypass`) и
копируется в `session.Settings.Bypass`, но **нигде не применяется**: у
`engine.Plan` нет поля, рендеры его не читают, guard его не видит. Фича молча
мертва; комментарий «Bypass rules exempt private destinations» ложен.
Та же судьба у `DnsPolicy.block_private` — поле контракта, которое ядро
никогда не читает. Спека — два честных варианта:
  - (а) Реализовать: `engine.Plan.Bypass []string` + применение — правила
    bypass как прямые маршруты во всех рендерах (выше пользовательских
    правил, ниже preset'ов?) и/или исключения в nft/WFP kill switch; тогда
    же задействовать `block_private` для DNS. Внимание на взаимодействие с
    kill switch: сейчас «bypass в LAN» при включённом kill switch молча не
    работает — после реализации это станет явным исключением, что нужно
    задокументировать как ослабление kill switch.
  - (б) Убрать из контракта: удалить `BypassSettings`/`block_private` из
    proto (минор, обратно совместимо для чтения) и режектить непустые
    значения с `KeyPlanBypassInvalid`, пока фича не будет готова. Молча
    игнорировать — худший вариант, он сейчас и имеет место.

## 3. Сводная таблица

| ID | Проход | Severity | Статус |
|---|---|---|---|
| R5-LG-1-1 | 1 | Low-Med | Исправлено (1a25f0f) |
| R5-LG-1-2 | 1 | Med | Исправлено (f31f52e) |
| R5-LG-1-3 | 1 | Low | Исправлено (1800571) |
| R5-LG-1-4 | 1 | Low | Спека |
| R5-LG-1-5 | 1 | Low | Исправлено (5fadb0a) |
| R5-LG-2-1 | 2 | Low | Исправлено (10ae560) |
| R5-LG-2-2 | 2 | Low | Исправлено (10ae560) |
| R5-LG-2-3 | 2 | Low | Исправлено (9cb8dad) |
| R5-LG-2-4 | 2 | Low | Исправлено (9cb8dad) |
| R5-LG-2-5 | 2 | Low | Исправлено (9cb8dad) |
| R5-LG-2-6 | 2 | Low | Исправлено (9cb8dad) |
| R5-LG-2-7 | 2 | Low | Исправлено (9cb8dad) |
| R5-LG-2-8 | 2 | Low | Исправлено (9cb8dad) |
| R5-LG-2-9 | 2 | Low | Исправлено (9cb8dad) |
| R5-LG-2-10 | 2 | Low | Спека |
| R5-LG-3-1 | 3 | Low | Исправлено (5bc06ec) |
| R5-LG-3-2 | 3 | Low-Med | Исправлено (5bc06ec) |
| R5-LG-3-3 | 3 | Low | Исправлено (5bc06ec) |
| R5-LG-3-4 | 3 | Low | Исправлено (5bc06ec) |
| R5-LG-3-5 | 3 | Info | Замечание |
| R5-LG-4-1 | 4 | Info | Исправлено (9cb8dad) |
| R5-LG-4-2 | 4 | Low | Спека |
| R5-LG-4-3 | 4 | Info | Исправлено (4602748) |
| R5-LG-4-4 | 4 | Info | Исправлено (4602748) |
| R5-LG-4-5 | 4 | Info | Исправлено (4602748) |
| R5-LG-4-6 | 4 | Info | Исправлено (4602748) |
| R5-LG-4-7 | 4 | Info | Исправлено (4602748) |
| R5-LG-4-8 | 4 | Info | Исправлено (4602748) |
| R5-LG-4-9 | 4 | Low | Исправлено (4602748) |
| R5-LG-4-10 | 4 | Info | Замечание |
| R5-LG-5-1 | 5 | Med | Исправлено (dc83bf1) |
| R5-LG-5-2 | 5 | Med | Спека |

Итого: **32 находки** (3 Medium, 18 Low, 2 Low-Medium, 9 Info).
**Исправлено сразу: 26** (9 коммитов). **Спекой/замечаниями: 6** (1-4, 2-10, 3-5, 4-2, 4-10, 5-2).

## 4. Топ-3

1. **R5-LG-5-2 — мёртвый `BypassSettings`** (Medium, спека). Контракт обещает
   фичу, ядро её валидирует и молча выбрасывает. Пользователь, включивший
   bypass для LAN при активном kill switch, получает не то, что просил, и
   никак об этом не узнаёт. Нужна либо реализация, либо честный отказ.
2. **R5-LG-1-2 — DNS-rebinding в пробере** (Medium, исправлено). Единственная
   находка с реальным сценарием удалённой эксплуатации (злой резолвер →
   оракул локальной сети через измерение задержек). Закрыто `Control`-хуком.
3. **R5-LG-5-1 — расходящиеся `isBuiltInTarget`** (Medium, исправлено).
   Классический контрактный дрейф: две копии «одного» множества с разным
   содержимым, поздние падения в рендерах после успешной валидации.
   Теперь один источник истины + тесты на все пять таргетов в трёх рендерах.

## 5. Исправлено сразу (коммиты, ветка `bugfix/audit-2026-10-19`)

| Хэш | Коммит | Находки |
|---|---|---|
| `1a25f0f` | treat special-use ranges as non-public in subscription/probe | 1-1 |
| `1800571` | verify tpws against SHA256SUMS when the manifest lists it | 1-3 |
| `10ae560` | harden secret.Store against forged and oversized vaults | 2-1, 2-2 |
| `dc83bf1` | unify built-in routing targets across control and engines | 5-1 |
| `9cb8dad` | correctness: validate ports, peers, UUIDs, rule types | 2-3…2-9, 4-1 |
| `4602748` | quality: honest error keys, names and comments | 4-3…4-9 |
| `5bc06ec` | liveness: bound watchers, backoffs and shutdown | 3-1…3-4 |
| `f31f52e` | close the DNS-rebinding window in probe dials | 1-2 |
| `5fadb0a` | constrain shadowsocks obfs at validation | 1-5 |

Каждый коммит: только пути зоны (`core/`), после каждого — `go build ./...` +
`go vet ./...` чисто. К каждому исправлению добавлен регрессионный тест;
все новые тесты падают на старом коде (проверено выборочно через `git stash`).

## 6. Осталось спекой

- **R5-LG-1-4** — WFP: заменить `Glob("*.exe")` на обнаруженные бинарники
  (`guard.FirewallOptions` + проводка из `registry`).
- **R5-LG-2-10** — `probeProfile`: переименовывать ссылки в `selector` /
  `routing.rules` / `subjectSelector` вместе с тегами.
- **R5-LG-3-5** — бюджет перезапусков `tpws` в `bypass.keep()`.
- **R5-LG-4-2** — честный wire-код для `CodeUnsupported`.
- **R5-LG-4-10** — унифицировать дефолтный MTU TUN между движками.
- **R5-LG-5-2** — реализовать или удалить `BypassSettings`/`block_private`
  (детальная спека в разделе 2).

## 7. Проверено, чисто (не находки)

- `subscription.dialChecked` — `Control`-хук против rebinding (образец, по
  которому чинен пробер); bearer из URL вычищается из ошибок.
- `Prober.Discover` сверяет дайджест ДО `Probe`; AES-256-GCM с новым nonce и
  AAD-привязкой к ID стора; `SO_PEERCRED` для пиров IPC; `WriteFileAtomic`
  с fsync; `validateBypass` (CIDR/IP) до интерполяции в nft; `tunroute` —
  argv без shell; `LoadDigests` через `filepath.Base` (без traversal).
- Групповые типы fallback/load-balance консистентно отклоняются через
  `Capabilities.Missing` до рендера.
- systemd-unit: `NoNewPrivileges`, `ProtectSystem=strict`, минимальный
  `CapabilityBoundingSet`, `RestrictAddressFamilies` — hardening на месте.

## 8. Замечания по процессу

- На общей ветке параллельно работали агенты C#-зоны (коммиты `e29b945`,
  `769ae3b`, `1c6ff01`, `a047e17`) — мои 9 коммитов затрагивают только
  `core/`, конфликтов не было.
- Предсуществующее окруженческое падение `TestTunAndFakeIPAvoidLANAndEachOther`
  (интерфейс песочницы `198.19.0.2/30`) — не связано с изменениями; на чистой
  машине тест проходит.
- Наблюдение без ID: `TimeoutStopSec=15s` в unit'е короче худшего кейса
  `App.Close` (20с shutdown + 10с graceful); на практике закрытие занимает
  секунды, а при SIGKILL недочищенное состояние подбирает стартовый
  `Cleanup` — риск низкий, фиксировать не стал.
