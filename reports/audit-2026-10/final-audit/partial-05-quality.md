# Подкоманда №5: качество кода и системные паттерны — итоговый отчёт

**Дата:** 2026-10-20. **Ветка:** `bugfix/audit-2026-10-19` в `~/workspace/bug-hunt/sora`
и `~/workspace/bug-hunt/sora-legacy` (локально, пуша нет).
**Метод:** `deadcode` (golang.org/x/tools, собран под go1.27) с флагом `-test`,
ручной grep-proof каждого кандидата, `dupl` (threshold 50/100 токенов),
попарные `diff` ключевых подсистем sora↔legacy, вычитка Dart/C# без тулчейнов
(только явные случаи), сверка proto↔реализация↔клиент.

**Коммиты дисциплины:** перед каждым коммитом проверен `git diff --cached --stat` —
в обоих репо застейджены чужие docs-правки (sora: 6 файлов README/docs, legacy:
1 файл docs), чужих удалений кода не обнаружено; индекс не трогался
(ни `git add`, ни `reset`, ни `checkout`). Коммиты строго pathspec-формой по
своим путям, после — `git show --stat HEAD` (только мои файлы).
Рабочий процесс: при первой попытке удаления `ext/package.go` словил fuzzy-edit,
восстановил файл из `git show HEAD:` и делал удаления точным построчным скриптом;
при `gofmt -w` заметил, что gofmt 1.27 реформатирует чужой doc-comment
(`core/engine/singbox/render.go`) — откатил лишнее, оставив хирургическое удаление.
Урок в AGENTS.md.

---

## 1. Мёртвый код Go — перепись с доказательствами

### 1.1. Исправлено: `dbeecbf` (sora) — 10 функций/методов, 111 строк

`deadcode -test ./...` (тесты считаются entry points) дал ровно 11
недостижимых даже с тестами функций; `openArchive`/`fetchRawCatalog`-аналог —
единственные спутники. Каждый проверен grep'ом по всему репо (нуль call sites,
включая Dart/C#/docs). Все файлы были чистыми в worktree.

| # | Удалено | Доказательство |
|---|---------|----------------|
| 1 | `core/secret/key.go`: `DefaultProtector` | нуль вызовов во всём репо; `cmd/sora-core` имеет **свой** `platformProtector` (`cmd/sora-core/platform_other.go`, `platform_windows.go`) и никогда не зовёт `secret.DefaultProtector()` |
| 2 | `core/secret/file_other.go`: `platformProtector` (!windows) | достижим только из удалённого `DefaultProtector` |
| 3 | `core/secret/file_windows.go`: `platformProtector` (windows) | то же; `GOOS=windows go build ./secret/` зелёный |
| 4 | `core/ext/package.go`: `Open` + `openArchive` (и импорт `os`) | `Open` задокументирован как «не проверяет подпись»; все потребители идут через `OpenBytes` (загрузки) — `Open(path)` никто не зовёт |
| 5 | `core/ext/host.go`: `RegisterOn` | хелпер с вводящим в заблуждение doc-комментарием (ссылался на `control/server.go`); прод-wire — `extv1.RegisterExtensionHostServer` напрямую в `core/cmd/sora-core/main.go:443` |
| 6 | `core/ext/catalog.go`: `FetchCatalog` | каталог качается и верифицируется в Dart (`ext/catalog.dart`); Go-функция без вызовов |
| 7 | `core/ext/permissions.go`: `RequiresExplicitConfirm` | нуль вызовов; Dart решает confirm сам |
| 8 | `core/probe/reality.go`: `CheckDest`, `CheckSNIConsistency` | публичные обёртки без вызовов; тесты зовут внутренние `checkDest`/`checkSNIConsistency` |
| 9 | `core/censor/snipool.go`: `SNIPool.Members` | нуль вызовов даже в тестах пакета |
| 10 | `core/engine/singbox/render.go`: `orDefaultInt` | нуль вызовов в singbox (mihomo имеет свою копию — см. разд. 2) |

После: `go build ./...` + `go vet ./...` (linux), `GOOS=windows go build ./secret/`,
тесты `ext/`, `secret/`, `censor/`, `probe/`, `engine/singbox/` — всё зелёно.
`gofmt -l` по изменённым — чисто (предсуществующая не-gofmt чистота
`core/secret/store_test.go` не трогалась).

### 1.2. Исправлено: `9fd5598` (legacy) — та же пара `secret`, 12 строк

`deadcode -test ./...` в legacy дал ровно 2 кандидата: `DefaultProtector`
(`core/secret/key.go:42`) и `platformProtector` (`file_other.go`, `file_windows.go`).
Доказательство идентично: `legacy/core/cmd/sora-core` имеет свой
`platformProtector`, grep `DefaultProtector` по репо — только определение.
`go build ./...` + `go vet ./...` + `GOOS=windows go build ./secret/` + тест
`secret/` — зелёно.

### 1.3. Не исправлено (доказано недостижимы из прод-main, но НЕ трогал)

- **sora: ~400 функций — честные «NOT WIRED»/тестовые.** Без `-test` deadcode
  показывает 413 кандидатов; с `-test` остаются только 11 выше. Остальное —
  документированные невключённые примитивы (см. реестр разд. 4) и
  тестовые хелперы (`enginetest` планы, `singbox.Render`/`xray.Render` —
  обёртки, используемые тестами; `ipc.Dial` — тестовый клиентский путь).
  Удалять нельзя: это осознанная поверхность под будущие фичи + тесты.
- **legacy: 24 кандидата без `-test`, с `-test` — только пара из 1.2.**
  `obfs` uTLS-функции, `session.NewCompositeGuard`, `errs.Keys/DefaultKey/Retryable/RetryAfter`,
  `enginetest`-хелперы — все достижимы из тестов. Не трогать.
- **`secret` как дублированный платформенный фасад:** после удаления `platformProtector`
  из `secret` осталось `FileProtector`/`DPAPIProtector` (используются напрямую из cmd)
  — это осознанная граница «пакет vs бинарь».

### 1.4. Дарт (без тулчейна, только явные)

Подтверждённых мёртвых Dart-классов/методов **не найдено**: скан классов
`sora.dart`, `ui/`, `ext/` дал ложные срабатывания (экраны референсятся
навигацией внутри тех же файлов). Проверенные кандидаты из REVIEW-5PASS:
`_appVersion` — уже убран (теперь `appVersion` из `String.fromEnvironment`).
Вывод: Dart-плоскость чистая по этому критерию.

### 1.5. C# legacy (без тулчейна → спека, удаления не делал)

| Кандидат | Доказательство | Вердикт |
|----------|----------------|---------|
| `legacy/v2rayN/v2rayN/Handler/ProxySetting.cs`: класс `ProxySetting` (`SetProxy`/`UnsetProxy` через WinINET) | 0 ссылок во всём `legacy/` (только определение) | **спека: удалить файл**, проверить `dotnet build` на dev-машине |
| `legacy/v2rayN/v2rayN/Tool/QueryableExtension.cs`: `OrderBy(propertyName)` | 0 вызовов (только рефлексия внутри себя) | **спека: удалить файл**, проверить `dotnet build` |

### 1.6. Proto — мёртвая wire-поверхность (спека, удалять = ломать контракт)

Все 54 RPC sora имеют Go-реализации. Но покрытие вызовами из Dart (через
`CoreControlClient` и др.; верифицировано grep'ом camelCase-вызовов, `generated/`
исключён):

- **Нет Dart-стабов вообще** (директории `generated/sora/censor/v1/`,
  `generated/sora/ext/v1/` отсутствуют): `CensorControl.DetectCensorship` —
  Dart `core/censor.dart` работает на локальных эвристиках + комментарий-ссылка
  на proto; `ExtensionHost.*` — только Go-сервер, Dart управляет стором
  клиентски. `DetectCensorship` — мёртвая с точки зрения shipped-клиента wire-поверхность.
- **Стабы есть, вызовов нет** (22 RPC): `ListSubscriptions` (только
  `watchSubscriptions` используется), `SaveProfile`/`ListProfiles`/`DeleteProfile`/
  `GetNetworkFingerprint` (F5 сделан клиентским `ProfilesStore`; `TODO(profiles)`
  подтверждает невключённость fingerprint), `PutSecret`/`DeleteSecret`,
  `ParseImport` (Dart парсит сам: `parseImportLink`), `ProbeChain` (F8),
  `SaveSubscriptionOverride`/`GetSubscriptionOverride` (F6 — Dart override
  слой клиентский?), `GetRoutingPresets`, `GetBenchmarks`, `RunDiagnostics`,
  `FetchSubscription`, `DeleteProfile`, `GetConnections`/`GetServers`/`MintToken`/
  `Notify`/`RevokeToken`/`WatchExtensionEvents` (ExtensionHost — только для рантайма
  расширений).
- **Legacy:** 30 RPC, Go реализует все. C# клиент вызывает через generic-обёртки
  (`CallAsync<T>`, `WatchAsync`), поэтому надёжный per-RPC census по именам
  невозможен без тулчейна — кандидат на генерируемый contract-тест.

Рекомендация: не удалять RPC из proto (брейкинг), а либо задокументировать
«server-side only / future», либо довести вызовы. Минимально — сгенерировать
Dart-стабы для `censor/v1` (иначе `DetectCensorship` — API-призрак).

### 1.7. Остаток: `BypassSettings` (было «молча выбрасывается», REVIEW-5PASS)

Статус улучшился: `core/control/plan.go:330` валидирует `BypassSettings.rules`
через `checkBypass` (fail-closed), `core/control/server.go:48` кладёт их в
`session.Settings.Bypass`, сессия несёт в `Status.Bypass` (runner.go:754/812).
Но **data-plane потребитель отсутствует** — строки копируются в статус и нигде
не применяются (рабочий zapret — отдельный `engine.BypassStrategy`).
Спека сохраняется: реализовать применение или честный отказ с ключом ошибки.

---

## 2. Дублирование

### 2.1. Внутри репо (`dupl`, threshold 50 токенов)

- sora: 14 clone groups, legacy: 4 — все мелкие (10–20 строк), в основном
  switch-boilerplate по enum'ам (`control/censor.go:236` ≈ `control/custom.go:224` ≈
  `control/server.go:456` — enum-мэппинги, содержимое различается, риск дрейфа
  нулевой) и парные ARM/Disarm-врапперы. Ничего архитектурного.
- Отмечено: `orDefaultInt` существовал в singbox и mihomo как две копии —
  singbox-копия удалена (разд. 1.1), mihomo-копия живая и используется.

### 2.2. sora ↔ legacy: структурные копии с опасными расхождениями

Пакеты `secret`, `errs`, `ipc`, `session`, `subscription`, `engine/*` —
близнецы с дрейфом. Найденные расхождения класса «фикс в одном месте, нет в копии»:

| # | Расхождение | Статус |
|---|-------------|--------|
| D1 | **`secret`: verify-on-open (SORA-L3) есть только в sora.** sora: `checkDataDir` в `Open` + `checkOwnerOnly` на master/id/vault при каждом открытии (key.go:99,127; store.go:335). legacy: **ни одного** `checkOwnerOnly`/`checkDataDir` — только write-time `hardenFile`. Права/владельца файлов при чтении никто не проверяет. В SORA-LEGACY-DRIFT.md не задокументировано | **незаявленный дрейф, security-flavored** — кандидат на порт |
| D2 | **`engine/redact.go`: legacy-редактор богаче.** legacy: `strictKeyValuePattern`, кавычки в значениях, ключи `api_key`, `obfs_param`, `auth`, `client_secret`, «user/login» только с `=` (не маскирует «user agent»). sora: простой паттерн, этих ключей нет → **sora может течь `api_key`/`obfs_param` в логи** | **обратное направление: фикс/улучшение есть в legacy, нет в sora** — портнуть sora ← legacy |
| D3 | `errs/catalog.go` почти идентичен; legacy не хватает 2 ключей sora: `core.engine.unstable`, `core.engine.stalled` (S4 stall-watchdog — задекларировано в DRIFT как не портировано, консистентно) | ок |
| D4 | `session/guard.go` NewCompositeGuard и `ipc.Dial` — в обоих репо мертвы из прод-кода, живы в тестах (симметрично) | ок, консистентно |
| D5 | Локальные `orDefault`-хелперы продублированы между пакетами рендеров (singbox vs mihomo) — мелочь, кандидат на `engine/internal` | low |

### 2.3. Копипаст с расхождением внутри `secret/store.go` (проверено diff)

- sora: `writeFileAtomic` (неэкспортный hook) + `checkDataDir`; legacy: `WriteFileAtomic`
  (экспортный) без проверки каталога — имена хуков разошлись (D1 выше).
- Исправление паники crafted-vault (R5-SG-1-1): sora — touched-set (`72abbb8`),
  legacy — `sameBacking` с guard на пустые слайсы — **разные реализации, обе
  корректны** (проверено чтением), но держать две реализации одного инварианта —
  риск.

---

## 3. Системные паттерны

### 3.1. Обработка ошибок — консистентно, дисциплинированно

- Пользовательские ошибки — только через каталог `errs` (`errs.Newf`/`errs.Wrap`
  с `Key*`): sora 505, legacy 188 вызовов. Ключи — `snake_case` вида
  `core.api.version_mismatch`. Сырых `errors.New` для UI-путей не найдено.
- `panic(` в прод-коде: только конструкторные инварианты
  (`session: manager needs an engine factory` — идентично в обоих репо) и
  `testdata/`. `os.Exit`/`log.Fatal` — только в `cmd/`. 
- Формат сообщений: префикс подсистемы (`"control: ..."`, `"ext: ..."`,
  `"secret store: ..."`), детали — через `errs.Detail`, маскирование в UI —
  через `CoreFailure`→`describe()`→l10n (проверено в fixlog-quality).

### 3.2. Логирование — консистентно, 1 исключение

- Core: `slog` везде; сырых `fmt.Print*`/`log.Printf` в библиотечном коде нет.
- **Исключение:** `sora/service/sync` — 2× `log.Printf` (`syncloop.go:88`,
  `pairing.go:164`, «sync: save peers registry»). Отдельный модуль со своей
  конвенцией — спека: перевести на slog/structured.

### 3.3. Нейминг RPC — консистентно

Все 6 сервисов: `PascalCase` RPC `VerbNoun` (`RunLeakTests`, `ApplyObfsProfile`,
`DetectCensorship`, `GetSubscriptionOverride`…), сообщения `XxxRequest/Response`,
поля `snake_case`, enum-значения с префиксом. Расхождений стиля нет.

### 3.4. Версионирование API — сверенные фактические значения

| Компонент | Major | Minor | MinSupportedMinor | Источник |
|-----------|-------|-------|-------------------|----------|
| sora Go core | 1 | **11** | 1 | `core/cmd/sora-core/main.go:51` |
| sora Dart client | 1 | **11** | **6** | `app/lib/src/core/link.dart:20` |
| legacy Go core | 1 | **7** | 1 | `core/cmd/sora-core/main.go:46` |
| legacy C# client | 1 | **7** | **7** | `legacy/Control/CoreConnection.cs:43` |

- Major везде 1, minor внутри пары совпадает. **Асимметрия:** Dart заявляет
  `minSupportedMinor: 6`, а ядро — `1`: клиент строже сервера; негоциация
  сходится (low=max(6,1), high=min(11,11)), но семантика «поддерживаемого»
  разная в двух местах — задокументировать единое правило.
- `diagnostics/coreVersion = "0.1.0-dev"` — захардкожена в обоих репо и **используется**
  (поле `Core` в отчётах, pcap `Application: "Sora …"`), расходится с
  `buildVersion` (`"dev"` по умолчанию, подменяется ldflags). Не мёртвый код,
  но два источника версии ядра — спека: брать из одного.
- App: `pubspec.yaml` `1.0.12+13`, `SORA_VERSION` env override (default `'dev'`).
- Proto-версионирование: `ApiVersion{major,minor,min_supported_minor,capabilities}`
  в handshake; поля добавляются опционально — схема совместима.

### 3.5. TODO/FIXME/HACK — реестр (2 реальных, остальное — осознанные маркеры)

Реальных `TODO` в обоих репо — **ровно 2** (sora), в legacy — **0**
(ложные срабатывания: испан./итал. `todo` = «весь» в l10n):

1. `sora/app/lib/src/sora.dart:920` — `TODO(censor): ingest pushed detector verdicts
   here once [censor.proto] lands and the Dart stubs are…` — **забытый долг**:
   стабы так и не сгенерированы (разд. 1.6), SW4 UI висит на локальных эвристиках.
2. `sora/app/lib/src/sora.dart:1205` — `TODO(profiles): wire to the GetNetworkFingerprint
   RPC` — **осознанный маркер**: F5 работает клиентски, RPC существует серверно;
   рядом комментарий `:562` утверждает обратное («reachable from Dart») —
   комментарии противоречат друг другу, факт — вызовов нет.

**«NOT WIRED» / «Production status» — 17 осознанных маркеров (sora, legacy — 0):**
`diagnostics` (dnsintercept, deadsession, throttle), `engine/bypass`
(fakettl, split, nfqws_queue), `engine/ss` (GenerateShadowsocks2022PSK),
`engine/stealth`, `probe` (quic, serial, calibrate, trojan), `censor`
(budget, whitelist), `select/*`, `tune/*` (+`tune/desync`), `wgobfusc`.
Все — тестированные примитивы TSPU-волны с честным «не включено» в doc-комментарии
(поставлено `[tspu-wire]`). Классификация: осознанные маркеры, не долг.
Рекомендация процессу: при включении — убирать маркер в том же коммите.

---

## 4. Дрейф sora ↔ legacy — вердикт по SORA-LEGACY-DRIFT.md

### 4.1. Заявленное — подтверждено кодом (выборочно)

| Заявление DRIFT.md | Проверка кодом | Вердикт |
|--------------------|----------------|---------|
| Порт SORA-H6 (journal) в legacy | `legacy/core/session/journal.go` — `Append/Since/Subscribe` структура соответствует | ✅ |
| Порт SORA-M10 (`WFP.Disarm`) | `legacy/core/guard/firewall_windows.go:101` — сессия очищается только после успешного `Close()`, комментарий ссылается на SORA-M10 | ✅ дословно |
| Порт AmneziaWG-валидации | `legacy/core/engine/validate.go:325` `validateAmneziaWG` | ✅ |
| Порт mihomo AnyTLS | `legacy/core/engine/mihomo/proxy.go:60` + `render_test.go:226 TestRenderAnyTLSProxy` | ✅ |
| Hysteria2 up/down mbps, port hopping — НЕ портированы | grep по legacy — 0; в sora `xray/render.go:468` | ✅ (заявлено как отсутствующее) |
| SW2 ingress-защита — НЕ портирована | `legacy/core/guard/` не содержит `ingress*.go`/`mode.go`; diff функций guard: −30 функций vs sora | ✅ |
| `dialChecked` (R5-LG-1-2, кандидат «проверить sora») | **sora имеет свой** `dialChecked` в `core/subscription/subscription.go:332` (+ `publicAddr`, R5-SG `87e5ac8`) — кандидат закрыт: защита от rebinding есть в обоих | ✅ эквивалент |
| TSPU/SW2–SW7/F0–F11 — только sora | `core/{censor,tune,select,wgobfusc,leak}` и `proto/sora/{censor,leak,obfs,ext,custom}` отсутствуют в legacy | ✅ |

### 4.2. Незаявленное крупное — найдено 2 позиции

1. **D1 (§2.2): SORA-L3 (verify-on-open прав/владельца) отсутствует в legacy.**
   В DRIFT.md про L3 ни слова (§4 упоминает `secret.Store` лишь как «частичное
   покрытие»). Код-подтверждение: `checkOwnerOnly` вызывается в sora 4 раза,
   в legacy — 0 определений.
2. **D2 (§2.2): legacy-редактор логов богаче sora.** Улучшение пошло
   legacy → sora? Нет — осталось только в legacy. В DRIFT.md обратного
   направления «0», но это тихое улучшение без порта в sora.

Остальное незаявленное — мелкое (имена тест-хуков `writeFileAtomic` vs
`WriteFileAtomic`, FakeIP-дефолт `198.18.0.0/15` в legacy-рендере уже совпадает
с sora — частичное выравнивание без записи в DRIFT).

**Вердикт по дрейфу:** документ в целом честен (методология «только git log»
оговорена; кодовая проверка подтвердила все выборочные позиции). Дополнить
двумя пунктами выше + закрыть кандидата R5-LG-1-2 (sora-эквивалент существует).
Структурный дрейф сохраняется: sora — Flutter + 12 фич + anti-censorship стек;
legacy — C# + точечные порты. Новых скрытых крупных расхождений в проверенных
подсистемах (engine render, guard, probe, subscription, secret, errs) нет.

---

## 5. Исправлено / осталось

**Исправлено (2 коммита, оба проверены `git show --stat`, чужие staged-файлы не задеты):**
- `dbeecbf` (sora): удалены 10 доказанно мёртвых функций/методов (111 строк).
- `9fd5598` (legacy): удалена мёртвая пара `secret` (12 строк).
- Проверки: `go build ./...`, `go vet ./...` (оба ядра), `GOOS=windows go build ./secret/`,
  тесты затронутых пакетов, `gofmt -l` по изменённым — всё зелёно.

**Осталось спеками (не кодом):**
1. C#: удалить `ProxySetting.cs`, `QueryableExtension.cs` — нужен `dotnet build` на dev-машине.
2. Proto/Dart: 22 RPC без вызовов + `DetectCensorship` без Dart-стабов — решить: довить вызовы/стабы или пометить «server-side only».
3. `BypassSettings.rules` — нет data-plane потребителя (валидируется, хранится, эхается в статус).
4. D1: портировать `checkOwnerOnly`/`checkDataDir` в legacy (или задокументировать расхождение).
5. D2: портировать богатый redactor из legacy в sora (риск утечки `api_key`/`obfs_param` в логах sora).
6. Версии: унифицировать `minSupportedMinor` (Dart 6 vs core 1) и единый источник `coreVersion`/`buildVersion`.
7. `service/sync`: 2× `log.Printf` → slog.
8. `TODO(censor)` sora.dart:920 — сгенерировать Dart-стабы `censor/v1` или снять TODO.
9. Небольшие дубли: `orDefault`-хелперы между рендерами → `engine/internal`; две реализации crafted-vault fix → одна.

---

## 6. Вердикт зоны

**Качество кода: высокое, дрейф — контролируемый.** Мёртвого кода в прод-путях
после чистки не осталось (всё, что недостижимо, — либо удалено с доказательством,
либо честно помечено NOT WIRED с тестами). Дублирование — только мелкое
boilerplate; опасные расхождения копий — 2, оба зафиксированы выше с
рекомендациями портов. Обработка ошибок/логирование/нейминг — консистентны
между репо (один стиль, один каталог ошибок). Версионирование API — фактически
сверено, minor'ы пар сходятся, есть две мелкие асимметрии (minSupportedMinor,
два источника версии ядра). TODO-долг — 2 штуки, оба известны. DRIFT.md
подтверждён кодом с двумя дополнениями. Зона закрыта; блокеров для мержа нет,
пункты 1–9 — в бэклог.
