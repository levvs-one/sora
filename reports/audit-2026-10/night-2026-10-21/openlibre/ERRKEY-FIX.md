# OpenLibre: всплытие ключей ворот olcrtc на живом Connect (ERRKEY-FIX)

Наблюдение: INTEROP.md §5 — при живом `Connect` ключи ворот подключения
olcrtc (`core.olcrtc.token_required`, `combination_unsupported`,
`not_connectable`, `server_mode_refused`, `invalid`) приходили на проводе
завёрнутыми в общий `core.plan.outbounds_invalid`; конкретный ключ был
виден только внутри `DetailRedacted`, и UI показывал общую ошибку плана
вместо локализованной причины, хотя все 5 ключей переведены на 32 языка
и замаплены в `describe()` (коммит e7e63f62).

База: sora, ветка `bugfix/audit-2026-10-19`, HEAD до фикса `c93f37d3`.

## 1. Трасса (факт, замерено на живом Server.Connect до фикса)

Путь отказа `token_required` (wbstream+datachannel без токена), по шагам:

1. `core/control/server.go:589` — `Server.Connect` → `planFromProto`.
   Структурно план валиден (токен — свойство подключения, не ссылки),
   `planFromProto` проходит.
2. Ворота: `core/engine/olcwrap/olcwrap.go:183` `ValidateConnect` —
   возвращает каталожную ошибку `errs.Newf(CodeFailedPrecondition,
   KeyOlcrtcTokenRequired, "olcrtc: wbstream datachannel needs …")`.
   Вызывается из `olcwrap.Engine.Validate` (`olcwrap.go:249`).
3. **Заворот №1 (главный):** `core/session/manager.go:159` (до фикса) —
   `buildSession`: `built.Validate` → `errs.Wrap(err, CodeInvalidArgument,
   KeyPlanOutbounds)`. Внешняя ошибка становится главной: ключ
   `core.plan.outbounds_invalid`, код `invalid_argument` (у ворот —
   `failed_precondition`).
4. Тот же заворот стоял ещё в двух местах session-слоя:
   `core/session/runner.go:263` (до фикса) — `Session.Start` →
   `s.eng.Validate` → Wrap в `KeyPlanOutbounds`; `runner.go:183` —
   `session.New` → `Plan.Validate` → тот же Wrap.
5. Провод: `core/control/server.go:614→592` — ошибка `sessions.Connect`
   → `toWire` (`core/control/errors.go:60`): `UserMessageKey`/`Code` —
   из `errs.From(err)` (`core/errs/classify.go:20`), а `errors.As`
   находит **внешнюю** каталожную ошибку — обёртку. Вложенная ошибка
   ворот survives только как `cause`, и её рендер
   (`failed_precondition core.olcrtc.token_required: …`) попадает в
   `Detail` обёртки → `DetailRedacted`.
6. UI: Dart берёт `CoreFailure(answer.error.userMessageKey)`
   (`app/lib/src/sora.dart`, `app/lib/src/core/link.dart:90`) →
   `describe()` (`app/lib/src/ui/kit.dart:705`): ветки olcrtc
   (kit.dart:715–719) недостижимы, срабатывает
   `_ when key.startsWith('core.plan.') => s.errServers` — общая
   «невалидные серверы».

Замер до фикса (стенд: настоящий `Server.Connect`, фабрика =
`olcwrap.Wrap(stub)`, как в registry):

| Сценарий | Wire code | UserMessageKey | DetailRedacted |
|---|---|---|---|
| wbstream+datachannel без токена | INVALID_ARGUMENT | `core.plan.outbounds_invalid` | `failed_precondition core.olcrtc.token_required: olcrtc: wbstream datachannel needs a provider account token …` |
| provider `none` | INVALID_ARGUMENT | `core.plan.outbounds_invalid` | `failed_precondition core.olcrtc.not_connectable: …` |
| telemost+datachannel | INVALID_ARGUMENT | `core.plan.outbounds_invalid` | `unsupported core.olcrtc.combination_unsupported: …` |
| mode `srv` (из vault-документа) | INVALID_ARGUMENT | `core.plan.groups_invalid` | `outbound out-1: olcrtc mode "srv" is refused: sora is a client only ("cnc")` |
| битый ключ (не 64 hex) | INVALID_ARGUMENT | `core.plan.groups_invalid` | `outbound out-1: olcrtc encryption key must be exactly 64 hex characters` |

Отдельно про `srv`/`invalid`: структурная валидация olcrtc
(`core/engine/olcrtc.go:88` `validateOlcrtc`, plain `fmt.Errorf`) вливается
джойном в `Plan.Validate` (`core/engine/validate.go:996`) и умирает ещё
раньше — в `planFromProto` (`core/control/plan.go:491` до фикса: Wrap в
`KeyPlanGroupsInvalid`), вообще не дойдя до ворот `ValidateConnect`,
где `srv` имеет каталожный ключ.

Контраст (прецеденты сохранения ключа в проекте):

- `core.engine.binary_missing`: ворота фабрики
  (`core/engine/registry/registry.go:279–282`) — `buildSession`
  возвращает ошибки фабрики **без обёртки** (manager.go, путь Factory),
  ключ доходит до провода как есть (INTEROP S4c, 13 мс).
- Bypass-стратегия: `core/control/plan.go:475–489` — сломанная стратегия
  проверяется **отдельной пробой до** `plan.Validate`, потому что
  «plan.Validate joins every failure into one error, and wrapping that
  join in the groups key told the user the groups were at fault».

## 2. Фикс (минимальный, по этим двум прецедентам)

Матрица/валидация не переписывались; изменено только всплытие ключа.

1. **`core/control/plan.go`** (прецедент bypass-пробы): сразу после
   bypass-пробы и до общего `plan.Validate` каждый olcrtc-аутбаунд
   проверяется пробой `olcwrap.ValidateConnect(olcwrap.ConfigFromOutbound(o, ""))`
   (сейчас строки 490–512). Проба может упасть только по olcrtc-причине
   и уже несёт каталожные ключ+код, поэтому её ошибка возвращается
   **без обёртки** — как ошибки фабрики в session-слое. Это покрывает
   все 5 ключей на границе Connect, включая `srv`/`invalid`, которые
   иначе умирали структурным джойном. Резолвер пробе не нужен: ворота
   поле DNS не читают; `olcwrap` перепроверяет ворота на Validate/Apply
   как раньше.
2. **`core/session/runner.go` + `manager.go`** (прецедент фабрики):
   хелпер `validationErr` (runner.go:152–171) — если ошибка валидации
   уже каталожная (`errors.As` находит `*errs.Error`), она возвращается
   как есть; иначе — прежний Wrap в `KeyPlanOutbounds`. Применён во
   всех трёх местах заворота: `buildSession`→`built.Validate`
   (manager.go:159), `session.New`→`Plan.Validate` (runner.go:203),
   `Session.Start`→`eng.Validate` (runner.go:283). Это чинит всплытие и
   для планов, обходящих control (прямой `Manager.Connect`, rehandshake,
   switch-rollback): там заворот №1 был единственной причиной потери ключа.

Что **не** изменилось:

- Смешанные/прочие невалидные планы: джойн `Plan.Validate` каталожных
  ошибок не содержит → по-прежнему `outbounds_invalid`
  (session) / `groups_invalid` (planFromProto) — как раньше.
- `DetailRedacted` не теряет диагностику: теперь это собственный
  detail ворот (`olcrtc: wbstream datachannel needs a provider
  account token (the guest flow cannot publish data)`), без вложенного
  рендера ключа; маскировка в `Server.Connect` работает как раньше.
- Wire-код теперь каталожный ворот: token/not_connectable —
  `FAILED_PRECONDITION` (был `INVALID_ARGUMENT` у обоих),
  combination — `INVALID_ARGUMENT` (CodeUnsupported маппится туда же),
  srv/invalid — `INVALID_ARGUMENT`.
- Dart-сторона не тронута: ключи уже в `describe()` (kit.dart:715–719)
  и пинятся существующим `app/test/olcrtc_test.dart`.

Остаточная честность: ошибки фазы Apply в `Session.Start` по-прежнему
заворачиваются в `core.engine.start_failed` — но ворота olcrtc до Apply
не доходят (отказ на Validate в buildSession/Start), а
`binary_missing` фазы Apply недостижим в проде (фабрика registry
отказывает раньше). Не трогал: вне объёма задачи.

## 3. Тесты

Новые:

- `core/control/plan_olcrtc_errkey_internal_test.go` — граница
  `planFromProto`: 5 ворот → свой ключ+код+detail без вложенного
  рендера; 5 connectable-планов (в т.ч. wbstream с токеном, режим
  `cnc`) проходят; валидный olcrtc + циклические группы →
  `groups_invalid` как раньше.
- `core/control/olcrtc_errkey_test.go` — граница `Server.Connect`
  (фабрика = `olcwrap.Wrap(stub)`, как registry): те же 5 ворот на
  проводе (`UserMessageKey`, `SoraErrorCode`, `DetailRedacted` не
  содержит `core.plan.outbounds_invalid`); битый vless (порт 70000) →
  `core.plan.outbounds_invalid` как раньше.
- `core/session/validation_errkey_test.go` — `Manager.Connect` и
  `Session.Start`: каталожная ошибка валидации сохраняет ключ/код
  (и `Status().Key` сессии); plain-ошибка валидации и plain-джойн
  `Plan.Validate` → `core.plan.outbounds_invalid` как раньше.

Проверка (Go: `~/workspace/go/bin/go`, `GOCACHE=$HOME/workspace/.gocache-v`,
тесты control — `TMPDIR=/tmp`):

- `go build ./...` — зелёно.
- `go vet ./...` — зелёно.
- `go test ./control/ ./errs/ ./session/ ./engine/olcwrap/ -count=1` — зелёно.
- `go test ./... -count=1` (весь core) — зелёно, регрессий нет.
