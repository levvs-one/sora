# Анализ Go-пакетов ядра sora (core/)

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`, read-only. Проверено: API-границы всех 20+ пакетов `core/`, дерево зависимостей бинаря (`go list -deps ./cmd/sora-core`), дублирование логики, обработка ошибок, тестируемость. Находки предыдущих отчётов (аудит, FIX-REPORT, REVIEW-5PASS, POWER-RUN) не дублируются — это новый слой.

## Вердикт

Архитектурный скелет ядра здоров: единый data-контракт `engine.Plan`, чистый `Engine`-интерфейс, честная модель ошибок `errs`, аккуратный lifecycle сессий. Но поверх скелета наросло ~2500 строк мёртвого кода (пакеты `select`, `tune`, `tune/desync`, `wgobfusc`, `engine/stealth` — ни одного импортёра, подтверждено `go list`), четыре независимых классификатора dial-ошибок, два побайтово скопированных DNS-хелпера, два расходящихся списка встроенных rule-target'ов (control принимает `block`, engine — `pass`/`dns`: валидация плана происходит трижды с двумя разными контрактами) и второй, более грубый маппинг ошибок→gRPC в `ext`, который, в отличие от control, кладёт детали ошибок в текст статуса. Это не косметика: пункты P0 — реальные дефекты согласованности, пункты P1 — вырезание мёртвого кода и слияние дублирующейся логики.

## Сильные стороны (конкретно)

- **Единый data-контракт.** `engine.Plan` (`engine/plan.go:399`) — единственный формат, который понимают control, session и все три движка. Граница движка — интерфейс `Engine` (`engine/engine.go:133`, Validate/Apply/Stop/Close + Events), выбор движка вынесен в `engine/registry`, супервизия процесса — в `engine/supervise`. Рендереры (`mihomo`/`singbox`/`xray/render.go`) зависят только от Plan, не от control.
- **Модель ошибок `errs`.** Закрытый набор `Code` с фиксированной транспортной семантикой, стабильный каталог `Key` как публичный контракт (`errs/catalog.go`), иммутабельные копии через `With*`, `oneLine` против инъекции переводов строк в журнал (`errs/errs.go:100`). `control/errors.go` честно разделяет transport-ошибки (gRPC status) и domain-ошибки (SoraError в ответе), причём детали специально исключены из текста статуса: `// Status text excludes details because access logs may not redact them` (`control/errors.go:77`).
- **Session lifecycle.** Явная машина состояний с таблицей разрешённых переходов (`session/session.go:47` `allowedTransitions`), независимый контекст (`context.WithoutCancel`, `session/runner.go:212`) — cleanup переживает отмену RPC клиентом, `crashWatch` со скользящим окном (`session/watchdog.go`), `compositeGuard` с rollback при частичном Apply (`session/guard.go:100`). Конструктор `session.New` валидирует инварианты вместо доверия вызывающему.
- **Редактор секретов.** `engine.Redactor` маскирует longest-first, чтобы `strings.Replacer` не портил длинные значения частичным совпадением (`engine/redact.go:53`), а `maskedError` сохраняет `Unwrap` — `errors.Is/As` продолжают работать после маскирования.
- **Тестируемость.** 136 test-файлов; `engine/interop` гоняет реальный трафик через все три движка; `engine/enginetest` — общие планы для валидации; `session.Config.Now`/`TunUp`/`Network` — seam'ы для детерминированных тестов.
- **Fail-closed по умолчанию.** `control/authz.go`: неизвестные методы требуют control-прав; `errs.From` на неизвестное возвращает internal, а не гадание.

## Слоп / проблемы

### P0 — дефекты согласованности

1. **Два `isBuiltInTarget` с расходящимися множествами.** `control/plan.go:360` признаёт `{direct, block, reject}`, `engine/refs.go:83` — `{direct, reject, pass, dns}`. Control валидирует правила и группы первым (`control/plan.go:258, 349`), затем `engine.Plan.Validate()` перепроверяет другим множеством (`engine/validate.go:365, 382`). Итог: target `pass`/`dns` отвергается на входе, хотя движок его принимает; target `block` проходит control и падает уже в `session.New` с `KeyPlanOutbounds`. План валидируется трижды (`control/plan.go:300`, `session/runner.go:154`, плюс `eng.Validate` в registry) — и с двумя разными контрактами. Почему плохо: два источника истины для одного правила; расхождение молча меняет поведение в зависимости от того, где сработал первый чек.
2. **`ext.toStatus` — второй, худший маппинг ошибок→gRPC.** `ext/host.go:244`: switch на 4 кода против 7 в `control/errors.go` (`statusCodes`), дефолт — `Internal` вместо `Unknown`, и главное — `e.Error()` (с деталями!) уходит в текст статуса, прямо нарушая контракт из `control/errors.go:77`. Плюс type assertion `err.(*errs.Error)` вместо `errors.As` — обёрнутые ошибки не классифицируются. Почему плохо: один сервис течёт деталями в access-логи, другой — нет; поведение зависит от того, через какой RPC пришла ошибка.

### P1 — мёртвый код (подтверждено `go list -deps ./cmd/sora-core`: пакеты вне дерева)

3. **`core/select` (serversel) — ~1010 строк, ноль импортёров.** `select.go`, `pick.go`, `score.go`, `reliability.go`, `advisor.go` + 6 test-файлов. Ни одного вызова `NewPicker`/`NewScorer`/`NewAdvisor`/`NewReliabilityStore` во всём модуле. Данные для него (benchmark history) пишутся (`probe.Benchmarker`), но ранжирование никто не потребляет — F2 собран наполовину.
4. **`core/tune` и `core/tune/desync` — два мёртвых тюнера рядом.** `tune` (~4 файла: стратегии, кэш, тюнер), `tune/desync` (~900 строк, по собственному `doc.go` — «prototype» Geneva-style tuner'а). Оба без импортёров. Почему плохо: прототип лежит рядом с «боевым» пакетом, оба мёртвые — читатель не понимает, что живо.
5. **`core/obfs`: жива только обёртка, мертва суть.** Внешне используются лишь `obfs.Profile{...}.FingerprintID()` и `obfs.UTLSRandomized` (`diagnostics/ja4.go:109, 133`); `obfs.PresetMax/PresetBalanced` упоминаются только в комментариях мёртвого `tune`. Весь conn-уровень — `fragConn`, `SplitClientHello`, `WriteFragmented`, `RewriteClientHelloSNI`, `DialTLS`, `WrapConn`, jitter — не вызывается никем. При этом `control/obfs.go:9-12` заявляет: «core/obfs (engine-config rendering) consumes engine.Plan» — комментарий врёт, реальный seam — `MergeObfsProfile` в control. Почему плохо: мёртвый сетевой код с претензией на seam + вводящий в заблуждение комментарий.
6. **`core/wgobfusc`, `engine/stealth` — без импортёров.** (`engine/enginetest`, `engine/interop` — честная test-инфраструктура, к ним претензий нет.)

### P1 — дублирование логики

7. **Четыре классификатора dial-ошибок, три словаря типов.** `probe/classify.go:146` (`ClassifyDialError` → `DialFailure`, ~100 строк с `opSignature`), `censor/probe.go:170,192` (`classifyConnError`/`classifyTLSError` → `What`), `custom/probe.go:63` (`classifyProbeError`, грубая 3-ветка), `errs/classify.go` (`From`). Одна и та же errno-семантика (timeout/reset/refused/DNS) закодирована четырежды в разных типах (`DialSignature`, `What`, `errs.Key`).
8. **`normalizeResolver` + `displayList` скопированы побайтово.** `diagnostics/dnsleak.go:95,117` vs `leak/leak.go:347,368` — уже с дрейфом: `netip.ParseAddr` против `net.ParseIP`. Два DNS-самопроверочных механизма (`diagnostics` — пассивный анализ, `leak` — активные пробы) делят скопированные хелперы вместо общего пакета.
9. **Два конвертера ошибок→`SoraError`.** `control/errors.go:56` (`toWire`, с `RequestId`/`RetryAfter`, таблица `wireCodes` на 15 кодов) vs `probe/probe.go:275` (`toWire`, без них) + собственная таблица `probeCode` (`probe/probe.go:242`, 4 кейса, дефолт `UNAVAILABLE`). Один и тот же `errs.Code` маппится в разные wire-коды в зависимости от вызывающего.
10. **`itoa` × 4, `firstLine` × 2.** `control/server.go:73` (uint32), `guard/nftables.go:129` (int), `censor/probe.go:286` (int), `custom/probe.go:86` (uint16, с комментарием «mirroring the control plane's helper» — признание копипасты); `guard/nftables.go:121` (`FirstLine`, exported) vs `censor/probe.go:276` (`firstLine`).
11. **Два парсера semver.** `engine.ParseVersion` (`engine/engine.go:92`, с PreRelease) vs `ext.parseSemver` (`ext/manifest.go:223`, молча отрезает prerelease) + `ext.CompareVersions` (`:210`). Манифест расширений и движки сравнивают версии разной логикой.
12. **Пять JSON-персистентных сторов, у каждого свой atomic-write.** `probe.Benchmarker` (`probe/history.json`, `probe/bandwidth.go:420`), `select.ReliabilityStore` (мёртв, `select/reliability.go:185`), `tune.Cache` (`tune/cache.json` с версионированием, `tune/cache.go:18`), `custom.Store` (свой tmp+rename, `custom/store.go:184`), `secret.Store` (`writeFileAtomic`, `secret/file.go:13` — unexported, переиспользовать нельзя). Нет общего хелпера «атомарно записать JSON с версией».
13. **`session.Counters` — поле-в-поле копия `engine.Counters`.** `session/journal.go:67` vs `engine/events.go:32` (минус `MemoryBytes`), ручной маппинг в `session/runner.go` (`publishEngineEvent`). Комментарий честно говорит «independently… to preserve the client contract» — обоснование есть, но цена — вечный ручной маппинг при каждом новом поле.
14. **Логика извлечения target'а из плана живёт не там.** `censorTargetOf`/`serverIDOf` (`session/censor.go:191,210`) — знание о структуре `engine.Plan` в пакете session; `censorActionFor` (`:175`) — ещё один маппинг код→действие поверх `probe/classify.go`.

### P2 — границы и API

15. **Инверсия зависимости `guard → session`.** Интерфейс `session.Guard` и тип `session.Settings` определены в `session/guard.go`, а пакет-имплементация `guard` импортирует `session` (`guard/guard.go:7-13`, `var _ session.Guard = (*Guard)(nil)`). Абстракция принадлежит потребителю, а не владельцу; плюс два уровня абстракции (`session.Guard` Apply/Restore поверх `guard.Firewall` Arm/Disarm) без явной необходимости.
16. **`control` толстеет: `server.go` 1311 строк, `plan.go` 919 строк.** `plan.go` — прото↔engine транслятор, знающий все протоколы, и он же дублирует часть `engine.Validate` (см. п.1). `Server` — 20+ полей (`control/server.go:146`).
17. **Два конфига об одном.** `session.Config` (`session/runner.go:26`, 14 полей) и `ManagerConfig` (`session/manager.go:16`), конструктор копирует поле-в-поле (`manager.go:183-197`). Добавление seam'а требует правки двух структур и копипасты.
18. **Координационная записка в коде.** Комментарий в `control/server.go` (~строка 141): «CensorControl serves the parallel swarm agent's… the embedding was missing while their handler was in flight… See reports/featlog-swarm-sw1.md» — внутренняя переписка агентов в исходниках.
19. **Три тонкие `mask`-обёртки** (`session/runner.go:656`, `diagnostics/diagnostics.go:148`, `control/server.go:396`) — каждая «redact перед записью», но нет единого правила «где именно редэктится». Пока консистентно, но хрупко.

## Ранжированные рекомендации

1. **Починить (P0):** один канонический список встроенных target'ов в `engine` (экспортировать), `control/plan.go` переиспользует его; убрать дублирующую валидацию из `planFromProto`, оставив `engine.Plan.Validate()` единственным чекером. Файлы: `control/plan.go:258,349,360`, `engine/refs.go:83`, `engine/validate.go:365,382`.
2. **Починить (P0):** `ext.toStatus` → использовать `control.transportStatus`/`statusCodes` (вынести маппинг в `errs` или общий пакет), убрать детали из текста статуса, `errors.As` вместо type assertion. Файл: `ext/host.go:244`.
3. **Вырезать (P1):** удалить `core/select`, `core/tune`, `core/tune/desync`, `core/wgobfusc`, `engine/stealth`; из `core/obfs` оставить только то, что использует `diagnostics/ja4.go` (или перенести `FingerprintID` в `diagnostics`/`engine`), остальное — удалить вместе с вводящим в заблуждение комментарием `control/obfs.go:9-12`.
4. **Слить (P1):** один классификатор dial-ошибок — `probe/classify.go` как канон; `censor` и `custom` — тонкие адаптеры поверх него. Файлы: `probe/classify.go`, `censor/probe.go:159-200`, `custom/probe.go:63-98`.
5. **Слить (P1):** `diagnostics/dnsleak.go` и `leak/leak.go` — одна реализация DNS-проверок, общие `normalizeResolver`/`displayList` в одном месте. Файлы: `diagnostics/dnsleak.go:95,117`, `leak/leak.go:347,368`.
6. **Слить (P1):** один `toWire`/`wireCodes` в control; удалить `probe.toWire`/`probeCode`. Файлы: `control/errors.go`, `probe/probe.go:242-290`.
7. **Выделить (P2):** внутренний пакет мелких хелперов (`itoa`, `firstLine`, clamp'ы для wire-полей, atomic JSON store с версионированием) — убивает пп. 10 и 12 одним махом.
8. **Слить (P2):** `ext` использует `engine.ParseVersion`; удалить `ext.parseSemver`/`CompareVersions`. Файлы: `ext/manifest.go:210-244`, `engine/engine.go:92`.
9. **Переделать (P2):** перенести `Guard`/`Settings` в `guard` (или отдельный контрактный пакет), `session` зависит от `guard`, а не наоборот. Файлы: `session/guard.go`, `guard/guard.go`.
10. **Слить (P2):** один конфиг сессии — `ManagerConfig` встраивает `session.Config` вместо дублирования полей. Файлы: `session/manager.go:16`, `session/runner.go:26`.
11. **Вычистить (P3):** убрать swarm-комментарий из `control/server.go`; рассмотреть декомпозицию `control/plan.go` по протоколам, когда он снова вырастет.

## Проверяемость утверждений

- Мёртвые пакеты: `go list ./... | grep sora-client | sort -u` vs `go list -deps ./cmd/sora-core | grep sora-client | sort -u`, `comm -23` → `core`, `engine/enginetest`, `engine/interop`, `engine/stealth`, `select`, `tune`, `tune/desync`, `wgobfusc` (первые три — корень и test-инфра, остальные — мёртвый код).
- Отсутствие вызовов: `grep -rn "NewPicker\|NewScorer\|NewAdvisor\|NewReliabilityStore" --include="*.go" .` (вне `core/select/`) — пусто; то же для `core/tune`, `core/wgobfusc`, `engine/stealth`.
- Дубли `isBuiltInTarget`, `itoa`, `firstLine`, `normalizeResolver`, `displayList`, `toWire`, `probeCode`, `parseSemver` — все пары сверены построчно, приведены выше с файлами и строками.
