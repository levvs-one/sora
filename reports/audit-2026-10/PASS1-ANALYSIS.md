# PASS1-ANALYSIS — свежий взгляд прохода 1/3 (после всех волн правок)

Дата: 2026-10-20. База: sora `76a2ccf1` (HEAD на момент анализа; 21 коммит
оптимизаторов поверх FINAL-AUDIT `43c3846`), legacy `2c6b9de`.
Прочитано перед началом: `ANALYSIS-20.md`, `FINAL-AUDIT.md`, `~/AGENTS.md`
(про git-уроки — см. решение ниже).

Метод: свежий diff-ревью всех коммитов после `43c3846` (sora) и `9fd5598`
(legacy): tspu-wire (10), swarm-второй-круг, detail-fixes, оптимизаторы (21),
legacy-opts (2); grep-вызывающие для каждого «нового» пакета
(core/tune, core/select, censor, wgobfusc, ext runtime, sync);
ручная проверка семантики каждого оптимизаторного диффа (in-place Seal/Open,
lazy warm registry, nft-рендер, hash-кэш, journal buffer, freeze window,
presize); `go build`, `go vet`, `go test` для всех затронутых пакетов
(всё зелёное); прогон `go run golang.org/x/tools/cmd/deadcode@latest`
неудачен по окружению (tool собран под go1.26, пакеты требуют go1.27) —
вместо него ручной импорт-граф.

**Честный вердикт коротко: нового мало.** Critical и High — ноль. Main-улов —
2 Medium (один — недозакрытый дрейф D2 из FINAL-AUDIT с новым конкретным
примером утечки; второй — новая семантическая трещина в sync-кэше),
1 Medium-Low (оптимизация мёртвого RPC), остальное — Low/nit и честные
«чисто». Все оптимизаторы семантику не сломали (проверено по диффам +
тесты зелёные). Код не менялся: по соседству в дереве — грязное дерево
других отделов (60 изменённых/незакоммиченных путей на момент анализа,
включая `core/control/plan.go`, `subscriptions.go`, `engine/catalog.go`,
`app/lib/src/ext/*`); править рядом с их WIP сейчас — риск sweep'а по
урокам AGENTS.md. Все находки — спеками ниже, фиксы — следующим проходам
или лидам отделов.

---

## Medium

### M1. Redactor-дрейф sora↔legacy: в sora секреты с пробелами и кавычками частично текут в логи движков

`~/workspace/bug-hunt/sora/core/engine/redact.go:92`:

```go
keyValuePattern = regexp.MustCompile(`(?i)\b(uuid|password|passwd|secret|token|private[_-]?key|preshared[_-]?key|pre-shared-key|obfs[_-]?password|psk|public[_-]?key|short[_-]?id|spider[_-]?x)\b([=: ]+)(\S+)`)
```

Legacy (`~/workspace/bug-hunt/sora-legacy/core/engine/redact.go:97-101`)
богаче: добавляет `api[_-]?key`, `obfs[_-]?param`, `auth`, `secret[_-]?key`,
`client[_-]?secret`, `username`, плюс `tokenLinkPattern` (маскирует токен в
URL вида `scheme://token@host`, строка 117) и `strictKeyValuePattern` для
`user`/`login` с явным присваиванием (строки 99-101). FINAL-AUDIT пометил
это D2-спекой («в sora эти ключи могут течь в логи») — она до сих пор
открыта, и у неё есть новый конкретный кейс:

- **Кавычки с пробелом**: sora-паттерн `(\S+)` после разделителя
  захватывает только до первого пробела. Строка `token: "my secret value"`
  → маскируется `"my`, а `secret value"` остаётся в открытом виде в
  engine-логах. Legacy-паттерн (`(\"[^\"]*\"|'[^']*'|\S+)`) закрывает
  кейс полностью.
- **`api_key=sk-...` / `obfs_param: ...` / `username: ...`** — в sora
  не маскируются вообще.

Спека-фикс: портировать legacy-паттерны (строки 95-101 + `tokenLinkPattern`)
в sora `engine/redact.go` вместе с legacy-тестами (`redact_test.go` у
legacy — проверить наличие; минимум — добавить векторы
`token: "a b"`, `api_key=x`, `obfs_param: y`, `user = bob`, URL
`https://token123@host/`). Осторожно: паттерн legacy шире — прогнать
`go test ./engine/...` и false-positive набор sora (ANALYSIS-20/11
отмечал `token bucket` как ложное срабатывание диагностического
редaктора — не усугубить).

### M2. Sync: кэшированный `hash` больше не обязан равняться `sha256(payload)`

`~/workspace/bug-hunt/sora/service/sync/sync/store.go:103,145`
(коммит `c311ff75`): `List()` и `Get()` теперь доверяют полю
`storedDoc.Hash` с диска, не сверяя с payload. `Put` считает честно
(`:182`), файлы пишут только свои — расхождение возможно лишь при
ручном редактировании/миграции файла. Проверено: решения протокола
принимаются по `UpdatedAt` (`sync.go:199,217`), Hash в выборе
pull/push не участвует; API-ответы (`api/http.go:182`) пересчитывают
хеш заново — поэтому эффект сегодня косметический (Low по факту),
но инвариант `Meta.Hash == hex sha256(payload)`, записанный в доке
типа (`sync.go:26`), для `Get()` уже ложен.

Спека-фикс (дешёвый, семантика не меняется): в `Get()` пересчитывать
`HashOf(payload)` — payload там уже декодирован из base64 и JSON, хеш
in-memory буфера стоит копейки; кэш оставить только в `List()`
(единственное место, где он реально экономит). Либо ослабить док
`Meta.Hash` до «кэшированный, может устареть» — но это хуже.

### M3. Оптимизаторный волной оптимизирован мёртвый путь: `GetBenchmarks`

- `core/control/benchmark.go:156` — RPC `GetBenchmarks` живёт в бинаре,
  но в Dart ноль вызывающих (проверено grep по `app/lib/src`, кроме
  generated). Dart хранит историю бенчмарков локально в settings JSON
  (`app/lib/src/sora.dart:1912,1930`).
- Коммит `a70ec541` добавил `GetBenchmarks` в «hot-path suite»
  бенчмарков — бенчмарк на мёртвый RPC.
- `feedBenchmarkLatency` (`server.go:1233`) и бенчмарк-раны кормят
  `benchmarker.History()` при каждом пробе — хранилище, которое читает
  только мёртвый RPC. Двойное состояние: история в Dart-настройках
  (авторитетна для UI) и in-memory в core (никем не читается).

Решение владельца: либо завайрить Dart на `GetBenchmarks` и удалить
Dart-историю (один источник правды), либо удалить RPC + `History()`
(и тогда `feedBenchmarkLatency` — мёртвый код). Минимум: убрать
`GetBenchmarks` из hot-path бенчмарков — перф-внимание на мёртвый
код это театр производительности.

---

## Low / nit

### L1. `siberian.go`: док заявляет то, чего нет
`core/censor/siberian.go:29-33`: «The policy is kept, tested, and **fed
through ObserveAttempt**». Но `NewFreezePolicy`, `ObserveAttempt`,
`Assess` не имеют ни одного вызывающего (проверено: только внутренние
вызовы внутри файла + тесты `NextSiberianFingerprint`). Честный маркер
«POLICY's actions still have no consumer» в том же файле есть — но
конкретная фраза «fed through ObserveAttempt» ложна. Однострочный
фикс дока.

### L2. `itoa`×4 — дубль жив
`core/control/server.go:73`, `core/censor/probe.go:286`,
`core/custom/probe.go:86`, `core/guard/nftables.go:169`. Тест-наследство
ANALYSIS-20/01; тривиальная консолидация в один пакет (например
`core/errs` или `internal/str`). Slop-класс «системная болезнь
дублирования» не лечится, но и не растёт.

### L3. Дубль тестовых хелперов оптимизаторов
`largePlan()` определён в трёх `opt_bench_test.go`
(`engine/singbox`, `engine/xray`, `engine/mihomo`) — разные пакеты,
конфликта нет, но это тест-копипаста; `core/testutil` существует.
Мелочь для следующего прохода качества.

### L4. Комментарий-врака в Dart про «core worker runtime»
`app/lib/src/ext/store.dart:619-623` ссылается на «the core worker
runtime» как на существующую сущность. Реальность: `ext.NewScheduler`
не конструируется нигде в проде (нет в `main.go`, нет в `host.go`),
`GetBackgroundConfig`/`ParseBackgroundConfig` — только тесты.
Docs честны (`docs/extensions.md:282`: «neither the app nor the
service — schedules workers yet»), комментарий в Dart — нет.
Однострочная правка дока (файл сейчас в грязном дереве другого
отдела — не трогать до их коммита).

### L5. Напоминание про мусор в дереве (не коммитить)
`service/sync/sora-sync.exe`, `core/sora-core` (26 MB бинарник снова в
worktree), `app/tool/__pycache__/`, `packaging/linux/__pycache__/`,
`core/control/subscriptions.go.3091033395789509018` — untracked.
FINAL-AUDIT уже запрещал их коммитить; подтверждаю статус.

---

## Проверено — чисто (чтобы не копали повторно)

1. **In-place Seal/Open в sync-транспорте** (`3177fb9d`):
   `writeChunk` собирает header+flag+payload в `wscratch` и силит
   `Encrypt(dst=buf[:2], buf[2:])` — dst-префикс ровно перед плейнтекстом
   в том же backing-массиве, классический безопасный in-place паттерн
   (шифртекст пишется по мере чтения, позиции совпадают). Wire-формат
   байт-в-байт как раньше (2-байт len + flag + ciphertext + tag 16).
   ReadMsg fast-path возвращает `plain[1:]` — алиас frame-буфера,
   но `readFrame` аллоцирует буфер на фрейм, потребитель не хранит его
   между вызовами. `wscratch` растёт, но невалидных чтений нет.
   `go test ./...` в `service/sync` — зелёный.
2. **Lazy warm registry** (`fc65480a`, `core/cmd/sora-core/engines.go`):
   пин валидируется eagerly на zero registry (эквивалент прежнего
   fail-fast на неизвестный engine; `Pin("")` = no-op как раньше);
   все 4 метода (`Factory/Availability/Binaries/Usable`) вызываются из
   `main.go`/`check.go` — мёртвых методов нет; `sync.Once` исключает
   двойную discovery; `-check` (`check.go:23`) блокируется на том же
   `get()` — поведение эквивалентно. Дельта: варнинг «no engine binary
   found» теперь может не успеть залогироваться при мгновенном выходе
   процесса — косметика. Конкурентный запуск discovery с остальным
   `New` (спавн движков для version probe) — безвреден.
3. **nft-рендер** (`b697ee03`): `NftIngressRuleset`/`NftRuleset` —
   текстовая эквивалентность сохранена (семейство по
   `masked.Addr().Is6()`, `Masked()` как раньше,
   `Addr.AppendTo` == `String()`); гейт `cfg.AllowLAN` не тронут;
   `defaultBypassPrefixes` — `len==cap`, append извне не испортит
   shared backing. `go test ./guard/` зелёный.
4. **Freeze window shift** (`ee6d07d0`, `core/probe/freeze.go:254`):
   copy-shift эквивалентен append+reslice (тот же набор/порядок
   последних `freezeMaxSamples`). `go test ./probe/` зелёный (14.3s).
5. **Session journal buffer + copyBypass** (`8a4c34fb`): рост с 64 —
   steady state тот же; `copyBypass` возвращает nil на пустом — раньше
   `append([]string(nil), ...)` на пустом тоже давал nil. Эквивалент.
6. **Pre-size волна** (`486a2dcc`, `76a2ccf1`, `fb0fb057`, `a70ec541`):
   везде `make([]T, 0, n)` + append — классической ошибки
   `make([]T, n)` с ведущими нулями нет; `xray observed()` добавил
   тот же type-assert `b["selector"].([]string)` в pre-count цикл —
   конструктор один (`render.go:572`), панки нет, но ассёрт хрупкий
   (pre-existing стиль, не регрессия).
7. **Legacy parser opt** (`2c6b9de`): `decodeBase64` early-exit на `':'`
   корректен (`':'` нет ни в одном base64-алфавите); `hasPrefixFold`
   эквивалентен старому `ToLower+HasPrefix`; общий декодированный
   payload `detect→Parse` — тот же вход. `go test` legacy core —
   не гонялся здесь (не требовалось задачей; дифф вычитан вручную).
   Дрейф: sora-парсер опты не получил (перф, не корректность) —
   приемлемо.
8. **xray `observed()`** — см. п.6: чисто при текущем конструкторе.
9. **deadcode-прогон**: технически не удался (см. метод), заменён
   ручным графом импортов.

## Театр: статус после волн (без изменений, решения владельца висят)

- `core/select` (1896 строк кода + 883 тесты), `core/tune` (1171+614),
  `core/tune/desync` (1285), `core/wgobfusc` (751+234),
  `core/engine/stealth` (482) — **ноль прод-импортёров у каждого**
  (проверено grep по `core service tools`, исключая тесты и сам пакет).
  Честные `NOT WIRED` маркеры на месте (swarm `42f4ef05`), FINAL-AUDIT
  «deadcode -test = 0» технически верен (тесты держат пакеты живыми
  для инструмента), но ~5585 строк кода без единого прод-вызова —
  это витрина, а не запас. Решение владельца (удалить / завайрить)
  не принято — подтверждаю статус, нового нет.
- `core/ext`: `Scheduler` (worker.go), `GetBackgroundConfig`
  (background.go), `SetFetchTransport` (netfetch.go) — ноль прод-вызовов;
  коммит INT-3 (`ea9a7061`) «Go runtime reads background.json» добавил
  код, который никто не вызывает. Dart-раннера по-прежнему нет.
- `censor.FreezePolicy`/`Assess`/`ObserveAttempt` — без вызывающих,
  но док честен (см. L1 про одну фразу). Распознаватель завайрен
  (`main.go:318,343`), это проверено и живо.
- Мёртвые RPC без Dart-клиента: `GetBenchmarks` (см. M3), `ProbeChain`
  (`core/control/chain.go:23`, Dart-вызовов нет — FINAL-AUDIT
  подтверждается).

## Дрейф sora ↔ legacy: что разошлось сильнее

1. **Redactor** — см. M1: legacy ушёл вперёд (tokenLinkPattern,
   strict user/login, богатый keyValuePattern, обработка кавычек);
   sora остался на узком паттерне. Дрейф растёт, а не закрывается.
2. **Parser**: legacy получил opt-волну (`2c6b9de`: query-once,
   fold-prefix, shared base64, pre-sized dedup), sora-парсер — нет.
   Только перф, семантика не разъехалась — но форки живут своей жизнью.
3. **Redact в `plan.go`**: оба содержат `obfs_param`-маскировку
   (`sora/core/control/plan.go:101`, legacy `:115`) — паритет здесь
   есть; расхождение — именно в engine/redact.go.

## Дубли: новое

- Новых прод-дублей волны не принесли. `itoa`×4 и классификаторы —
  старые. Тестовый `largePlan()`×3 — см. L3.
- `sync.HashOf` — один (`service/sync/sync/sync.go:42`); дублей нет.
- `banKey` — один (`core/probe/quic.go:303`).

## Инварианты / fail-closed

- Все проверенные оптимизации fail-closed не ослабили: nft-рендер
  по-прежнему скипает невалидные bypass-записи (сырой текст в
  ruleset не попадает); lazy registry не меняет порядок
  digest-верификации (SORA-H5) — discovery та же, только позже;
  sync Seal/Open не меняет wire-security (тот же Noise AEAD, те же
  чанки).
- Ослаблен один инвариант данных: `Meta.Hash == sha256(payload)`
  (M2). Не fail-closed, но контрактная трещина.

## Что исправлено этим проходом

Ничего кодом — осознанно. Причины: (1) грязное дерево 60 путей от
параллельных отделов в тех же зонах (`core/control/*`,
`app/lib/src/ext/*`, `core/engine/*`) — любой мой коммит сейчас
рискует sweep'ом чужого WIP по урокам `~/AGENTS.md` (staged-индекс
уже «отравлялся» 3+ раз за аудит); (2) оба Medium — спеки, требующие
решения/ревью шире однострочного фикса (M1 — порт паттернов с
тестами на false positives; M2 — контрактное решение).
AGENTS.md-уроки перечитаны; bare `git commit` не использовался,
коммитов не было вообще.

## Рекомендации следующим проходам / владельцу

1. M1 — порт redactor-паттернов legacy→sora + тесты (владелец: это
   закрывает и D2 из FINAL-AUDIT).
2. M3 — решение по `GetBenchmarks`: завайрить Dart или удалить;
   убрать из hot-path бенчмарков в любом случае.
3. M2 — `Get()` в sync store пересчитывает хеш (5 строк).
4. L1, L4 — две однострочные правки доков (после коммита чужих
   WIP в этих файлах).
5. Открытые решения владельца с ANALYSIS-20/FINAL-AUDIT не закрыты:
   судьба select/tune/wgobfusc/stealth, authority расширений
   (Go Scheduler мёртв — удалить или завайрить), F5-автоматч,
   key ceremony. Проход 1/3 нового по ним не нашёл — подтверждаю,
   что висят.
6. Dev-машина (из FINAL-AUDIT, без изменений): `flutter analyze`,
   C# build, `buf generate` + дифф стабов, ручной deeplink.

---

*Проход 1/3 завершён 2026-10-20. Код не менялся, коммитов нет (осознанно,
см. «Что исправлено»). Отчёт — единственный артефакт:
`~/workspace/bug-hunt/reports/PASS1-ANALYSIS.md`.*
