# PASS3-ANALYSIS — свежий системный взгляд прохода 3/3 (после всех правок проходов 0–2)

Дата: 2026-10-20. База: sora `1925867e` (tip ветки `bugfix/audit-2026-10-19`;
ровно 1 коммит `[pass2-opt]` поверх финального аудита прохода 2 `8f6bfb98`),
legacy `e39fa15` (без изменений с PASS2-AUDIT).
Прочитано перед началом: `PASS2-ANALYSIS.md`, `PASS1-ANALYSIS.md`,
`ANALYSIS-20.md`, `PASS2-AUDIT.md` (полностью, фокус — зоны 5 и 9),
`SORA-LEGACY-DRIFT.md`, `OWNER-DECISIONS-PASS2.md`, `PASS2-SUMMARY.md`,
`PASS2-OPTIMIZERS.md`, `~/AGENTS.md`.
Метод: свежий прогон deadcode по всем 4 Go-модулям той же командой, что
проход 2 (`GOTOOLCHAIN=go1.27.0 go run golang.org/x/tools/cmd/deadcode@v0.52.0
./...`, корни — только `main`-пакеты); построчный разбор дельты deadcode;
вычитка диффов всех коммитов прохода 2, не покрытых PASS2-ANALYSIS
(коммиты после `999d58a0`: `[pass2-ext]`×7, `[pass2-swarm]`×3,
`[pass2-detail]`×5, `[pass2-tspu]`×3 из 4, `[pass2-audit]`×3, `[pass2-opt]`×1);
исполняемая проверка редaктор-паттернов (отдельная Go-программа с точными
regex из обоих репо); spot-check ~25 утверждений README/docs против кода;
прямые `go test` (TMPDIR=/tmp): sora `censor`, `ext`, `diagnostics`,
`probe`, `engine`, `control` — зелёные; `service/sync ./...` — зелёный;
legacy `engine` (Redact) — зелёный. `go build ./...` sora core — чисто.
Код не менялся, коммитов нет.

**Честный вердикт коротко: Critical/High — ноль. Проходы 1–2 ничего
крупного не сломали: все перепроверенные закрытия PASS2-AUDIT держатся,
единственная принятая оптимизация прохода 2 (`1925867e`) семантически
чиста. Нового — 1 Medium (редaктор: порт M1 снова разошёлся в одной
реалистичной орфографии ключа, `pre_shared_key` течёт в sora) и россыпь
Low, из которых главная — мёртвый код, рождённый самими фиксами прохода 2
(`DefaultStrategy` осиротел от F11-фикса; Go-половина declared-entries
легла в уже недостижимый Verify). Deadcode-итог почти не сдвинулся:
346 → 347, и вся дельта объясняется поимённо.**

---

## Deadcode: дельта прохода (задача 1)

| Модуль | PASS2 | PASS3 | Δ |
|---|---|---|---|
| sora core | 346 | **347** | +1 |
| sora-legacy core | 22 | **22** (список байт-идентичен) | 0 |
| service/sync | 0 | **0** | 0 |
| tools/sora-ext | 0 | **0** | 0 |

По пакетам sora core: ext 75→**76**, engine 31→**32**,
diagnostics 19→**18**, остальные без изменений (tune 50, select 48,
probe 44, censor 24, obfs 23, wgobfusc 13, session 7, errs 4, guard 3,
ipc 2, control 1, secret 1, deadcheck 1).

Вся дельта — 4 события, каждое с причиной:

1. **−1 diagnostics**: `diagnostics/deadsession.go:29 DetectDeadSession`
   исчез — фасад снесён аудитом (`8f6bfb98`, PASS2 N4 закрыт кодом). ✓
2. **+1 engine**: `engine/bypass/bypass.go:62 DefaultStrategy` стал
   недостижим — см. находку **L1** (последствие F11-фикса `2a1395e6`).
3. **+2 ext**: `ext/package.go:197 declaredEntries` и `:223
   checkDeclaredEntries` — новые хелперы из `[pass2-ext] da936b06`
   (declared-entry gate). Они достижимы только из `Package.Verify` /
   `VerifyWithKey`, которые сами недостижимы из прода: вся Go-верификация
   пакетов — reference-половина, живой гейт — Dart (`app/lib/src/ext/
   package.dart:169-188`, зеркало сверено, паритет полный — см.
   «Проверено чисто»). То есть security-фикс прохода 2 приземлился
   одновременно в живую (Dart) и в мёртвую (Go) половину — класс F10,
   не новая дыра. См. **L2**.
4. **−1 ext**: `ext/worker.go:377 WorkerTask.recordRun` вышел из списка —
   `[pass2-ext] 1f0ba5e5` довёл до него вызовы из `runOnce`
   (worker.go:606,612,617,628) внутри Scheduler, который в проде
   создаётся и стартует (`cmd/sora-core/main.go`, пламбинг PASS2).
   Честное закрытие внутри пакета. ✓

**Театр уровня пакетов — без изменений**: `core/select` (48),
`core/tune`+`desync` (50), `core/wgobfusc` (13), `core/engine/stealth`
(внутри engine) — ноль прод-импортёров, маркеры `NOT WIRED` на месте,
owner-решение п. 3 висит. Непомеченного нового театра уровня пакетов
нет; непомеченный новый мёртвый код — уровня функций (L1, L2).

---

## Medium

### M1. Redactor: порт M1 снова разошёлся — sora не маскирует `pre_shared_key`, legacy не маскирует `public_key`/`spider_x` (РЕГРЕССИЯ-ДРЕЙФ прохода 1)

PASS1 M1 по существу **закрыт**: порт `41445257` + фиксы разделителя
`sora 5b6185cc` / `legacy 1297c0f` дали обеим сторонам богатый паттерн,
кавычки, strict user/login и tokenLink; паритет-тесты зелёные на обеих
сторонах (перепрогнано в этом проходе). Но параллельные правки паттернов
в проходах 1–2 снова развели списки ключей в деталях. Доказательство —
исполнение точных regex из `sora/core/engine/redact.go:102` и
`sora-legacy/core/engine/redact.go:99` на векторах `ключ: abc123`:

| Вектор | sora | legacy |
|---|---|---|
| `pre_shared_key` | **не маскируется** | маскируется |
| `public_key`, `public-key` | маскируется | **не маскируется** |
| `spider_x`, `spider-x` | маскируется | **не маскируется** |
| `pre-shared-key`, `preshared_key`, `presharedkey`, `spiderx`, `auth_str`, `short_id` | ✓ | ✓ |

Причина: sora пишет `preshared[_-]?key|pre-shared-key` (нет варианта
с разделителем после `pre`), legacy — `pre[_-]?shared[_-]?key`
(покрывает все), но legacy несёт `spiderx` без `[_-]?` и не имеет
`public[_-]?key`. Практический вес асимметричен: `pre_shared_key` —
это буквальное имя поля WireGuard в JSON рендеров sing-box, т.е.
реалистичная строка в engine-логах sora с живым секретом; `public_key`
публичен по природе, `spider_x`/`spider-x` — параметр обфускации
AmneziaWG (низкая чувствительность). Поэтому sora-сторона — Medium,
legacy-сторона — Low, одна находка.

Попутно проверен sora-only fast-path оптимизатора прохода 1
(`e60f9854`, `gateWords`, redact.go:118-152): гейт — настоящий суперсет,
оговорка про UUID реализована счётом дефисов (`strings.Count(s, "-") < 4`),
утечки через гейт нет. Legacy гейта не имеет (только перф-отставание).

Спека-фикс: привести alternation к объединению обеих сторон в обоих
репо одной правкой — канонический список:
`pre[_-]?shared[_-]?key` (вместо двух sora-вариантов),
`spider[_-]?x`, добавить `public[_-]?key` в legacy; добавить векторы
`pre_shared_key: x`, `public_key: x`, `spider_x: x` в redact-тесты
обоих репо, чтобы паритет пинился исполнением, а не вычиткой.

---

## Low

### L1. `bypass.DefaultStrategy` осиротел от F11-фикса прохода 2 и не помечен (НОВОЕ, рождено проходом 2)

Фикс `2a1395e6` правильный: `applyZapretWithVPN` больше не подставляет
`bypass.DefaultStrategy()` по умолчанию, а отказывает на уровне плана.
Но сама функция осталась без единого прод-вызывающего (deadcode:
`engine/bypass/bypass.go:62`; остались только тесты
`bypass_test.go:177,223,268` и упоминание в комментарии
`core/control/plan.go:448` — «the core's built-in default»). Док функции
(bypass.go:58-61) по-прежнему описывает её как поставляемый дефолт
 («is the modern nfqws/winws desync set»), без `NOT WIRED`-маркера,
который в этом репо принято ставить честному мёртвому коду. Поведение
безопасно (стратегии с desync-методами и так fail-closed через
`BackendOf`), вред — только честность/балласт: следующий читатель
решит, что дефолт где-то применяется.
Спека: либо пометить док `NOT WIRED: no production caller since the
F11 plan-time refusal (2a1395e6); kept as the reference nfqws set for
the migration in NFQWS-MIGRATION.md`, либо удалить функцию с тестами
и поправить комментарий в plan.go:448. Заодно это остаток owner-п. 4
(nfqws-эпик): статус эпика не изменился, изменился только статус
его «точки входа».

### L2. Go-половина ext: +2 недостижимых хелпера за проход; итог 76 (КВАНТИФИКАЦИЯ, класс F10)

См. дельту deadcode п. 3 выше: `declaredEntries`/`checkDeclaredEntries`
(`da936b06`) — корректный код, дословное зеркало живого Dart-гейта,
но в Go недостижим по построению, пока недостижим весь `Verify`.
Плюс PASS2 N3 (`ratings.go`, 5 функций) — без изменений, справочная
реализация с честной шапкой. Новых обманов нет; счётчик owner-очереди
F10 вырос с 75 до 76 не из-за «наращивания витрины», а из-за парного
зеркалирования security-фикса. Фикс — только owner-решение п. 6;
отдельной спеки не требуется, фиксирую дельту и причину, чтобы
проход-3 цифра не читалась как регрессия дисциплины.

### L3. README/security.md: «единственное сетевое обращение приложения — проверка обновлений» против app-side загрузки каталога расширений (НОВОЕ, docs vs code)

`README.md:58` и `docs/security.md:46` утверждают, что приложение само
ходит в сеть только за обновлениями (api.github.com). После F10 в
приложении есть второй сетевой путь: `app/lib/src/ext/catalog.dart:277
fetchCatalog()` вызывается из `store_screen.dart:446` при открытии
магазина расширений — прямым `package:http` из Dart-процесса. Сегодня
URL — плейсхолдер `https://extensions.sora.example/v1/catalog.json`
(catalog.dart:23, `.example` не резолвится), поэтому фактического
трафика нет; но утверждение доков уже неверно по коду и станет
неверным по факту, как только впишут настоящий endpoint каталога
(увязка с owner-п. 5/6). Security.md при этом точен в остальном
(подписки — служба, сокет — локальный).
Спека: одна фраза в оба места — «…и за каталогом расширений, когда вы
открываете магазин (адрес каталога; до настройки endpoint запрос
никуда не уходит)», либо вынести fetch каталога в службу и тогда
оставить текст. Low: ни утечки, ни обмана пользователя по существу
(.example), только точность showcase-доков.

### L4. `docs/extensions.md:285`: «neither the app nor the service — schedules workers yet» — формулировка по-прежнему буквально неверна (ПОВТОР PASS2)

Scheduler создаётся, стартует и останавливается в проде
(`main.go:355,583-585`, `SetFetchTransport` завайрен `:410` — цифры
PASS2 перепроверены, сдвигов нет); не регистрируется ни одной задачи
и нет JS-исполнителя, поэтому по существу фраза верна, буквально —
нет (service шедулер именно что запускает). Комментарий в
`main.go:351-354` честен дословно. Спека та же, что в PASS2:
переформулировать в «no worker tasks are registered yet…».
За проход не исправлено; фиксирую как висящий Low.

### L5. guard: противоречие доков strict-режима сузилось, но не закрыто (ПОВТОР-остаток PASS2 N10)

Пакетный док `core/guard/mode.go:7-13` теперь честен («machinery stays
tested but unreachable from the public API»). Но комментарий
`strictWanted` (mode.go:86-88) дословно прежний: «Callers use it at
startup to decide between Guard.reconcile (re-arm) and stale-table
cleanup» — при том что `Guard.reconcile` (guard.go:209),
`Guard.strictIntent` (:244) и `parseMode` (mode.go:62) по deadcode
вызывающих не имеют, а стартап зовёт только `CleanupStale`. Одна
правка комментария; поведение безопасно. Owner-п. 7 (экспонировать
Strict) — статус без изменений.

### L6. Асимметрия версий контракта: `MinSupportedMinor` Go 1 vs Dart 6 (ПОВТОР, без сдвигов)

`core/cmd/sora-core/main.go:50` — `Version{1, 11, MinSupportedMinor: 1}`;
`app/lib/src/core/link.dart:20` — `ApiVersion(1, 11, minSupportedMinor: 6)`.
Major/minor согласованы (1.11 на обеих сторонах, Since-маркеры и
контрактный тест тегов из `e9df39fd` на месте, тесты control зелёные);
расходится только нижний порог совместимости. Проходы 1–2 это не
трогали. Спека прежняя: один источник правды или тест паритета трёх
чисел.

### L7. Дубли: движения нет (ПОВТОРЫ, одной строкой каждый)

- `itoa` ×5 — стабильно: `control/server.go:74`,
  `diagnostics/dnsspoof.go:289`, `censor/probe.go:286`,
  `custom/probe.go:86`, `guard/nftables.go:169`. Пятый (dnsspoof) —
  наследие прохода 1; проход 2 шестого не добавил.
- Тестовый `largePlan()` ×3 (`engine/singbox|xray|mihomo`
  render_bench_test.go) — без изменений.
- `toWire` ×2 (`control/errors.go:60`, `probe/probe.go:471`) —
  разные сигнатуры и пакеты, известный остаток ANALYSIS-20.
- Классификаторы ошибок: новых не появилось; набор прежний
  (probe.ClassifyDialError, censor classifyConnError/classifyTLSError,
  custom classifyProbeError, race classifyUnanimous, ss
  classifyShadowsocksMethod) — консолидации не было, роста не было.
- F5/F6 сторы ×2 (Dart живые, Go RPC без клиентов) — без изменений,
  см. «RPC без Dart-клиента» ниже и статус owner-п. 2.
- Парсеры: legacy-only оптимизация парсера (`2c6b9de`) в sora не
  портирована (перф, не семантика) — повтор PASS1, без изменений.

### L8. RPC без Dart-клиента: ≈21/54 — стабильно (ПОВТОР, перемерено)

Всего RPC: 54 (CoreControl 40, Custom 4, ExtensionHost 6, Obfs 2,
Censor 1, Leak 1). Именной grep по Dart (не-generated) даёт 13
CoreControl-методов без единого упоминания: RunDiagnostics,
GetRoutingPresets, ListSubscriptions, PutSecret, DeleteSecret,
GetBenchmarks (RETIRED по дизайну), Save/GetSubscriptionOverride,
List/Save/DeleteProfile, ProbeChain. Сверх того PASS2-метод (ручная
сверка вызовов, а не имён) добавлял ParseImport и FetchSubscription —
их Dart-тёзки (`parseImportLink`, `fetchSubscriptionLink`) —
локальные хелперы, не RPC-вызовы; CensorControl 1/1 и ExtensionHost
6/6 клиентов не имеют. Итог совпадает с PASS2 (≈21/54). Нового за
проход не отвалилось и не подключилось; F5-часть множества —
см. статус п. 2 ниже.

### L9. service/sync: `log.Printf` ×3 (ПОВТОР, без сдвигов)

`service/sync/api/syncloop.go:88`, `api/pairing.go:164`,
`cmd/sora-sync/main.go:123` — те же три места, что PASS2 N11.
Проход 2 их не трогал и четвёртого не добавил.

### L10. Мусор в дереве (ПОВТОР, статус прежний)

Untracked: `core/sora-core`, `service/sync/sora-sync.exe`,
`app/tool/__pycache__/`, `packaging/linux/__pycache__/`,
`core/control/subscriptions.go.3091033395789509018`. Не коммитить.
Процессное наблюдение этого прохода: staged-индекс на момент анализа
**чист** (`git diff --cached --stat` пуст в обоих репо) — отравления,
отмеченного PASS2-AUDIT (5+ инцидентов), в этот раз не видно; это
наблюдение одного момента, а не доказательство устранения источника.

---

## Дрейф sora ↔ legacy: дельта проходов 1–2 (задача 4)

Legacy за оба прохода получил ровно 1 коммит (`e39fa15`,
reserved-маркеры plan-полей). Сверка содержательной нужности:

- **Нужно legacy и не портировано — только M1-остаток** (legacy-сторона
  находки M1: `public[_-]?key`, `spider[_-]?x`) и известный **N7**
  (legacy `core/obfs/doc.go` по-прежнему обещает завайренный
  uTLS-диалер; deadcode legacy подтверждает: `Dialer.DialTLS`
  dial.go:37, `Profile.UTLSConfig` utls.go:56, `NewUTLSConn` :106,
  `FingerprintID` :19, `UTLSEnabled` profile.go:110 — ноль
  прод-вызывающих; фикс честности из sora `core/obfs/doc.go` не
  портирован). Статус N7: открыт, без изменений.
- **Неприменимо к legacy** (подсистем в legacy нет — проверено по
  дереву): censor (нет пакета), NSDI/DnsSpoof (нет
  `diagnostics/dnsspoof.go`), RunSeries (нет `probe/serial.go`),
  F11-default (нет `DefaultStrategy` и zapret-with-VPN плана; legacy
  zapret — своя старая интеграция), SS-plugin vault (`0977ab03`) —
  grep `ss_plugin` по legacy parser/control: 0, поверхности нет.
  Это не «отставание фиксами», а рост структурного расхождения:
  проходы 1–2 добавили sora три подсистемы, которых в legacy нет
  по позиционированию.
- **Закрывшийся дрейф**: golangci-lint пин — sora догнал legacy
  v2.15.0 (`2742ca32`); plan-поля закрыты с обеих сторон, но
  **разными стилями**: sora удалил поля из Go-структур (`3531723a`,
  11 полей), legacy сохранил с `reserved`-комментариями
  (`6599852`+`e39fa15`). Оба честны внутри своих конвенций (legacy —
  C#-зеркало контракта, «помечать, не удалять» по PASS2-AUDIT);
  wire не затронут (plan — Go-внутренняя структура, proto не менялся).
  Не регрессия; фиксирую как осознанную дивергенцию файлов, бывших
  почти идентичными, — будущие порты между форками по этим файлам
  пойдут труднее.
- Общего мёртвого набора форков (PASS2 N6) никто не чистил:
  legacy deadcode-список байт-идентичен проходу 2 (22 позиции, включая
  `NewCompositeGuard`×5, errs×4, `ipc.Dial`, `secret.NewReference`),
  sora-зеркала тех же позиций на месте. Без изменений.

---

## Регрессии проходов 1–2: что перепроверено и ЧИСТО (задача 2)

1. **`1925867e` censor-opt** (единственная оптимизация прохода 2):
   построчно — `maxBytesIn` (init от первого события + max) равен
   исходному fallback-максимуму по всем событиям, терминал принадлежит
   тому же множеству событий; `terminalDetail` = `ToLower(terminal.
   Detail)` один раз вместо трёх; `sawTLSSent` эквивалентен удалённому
   циклу в `clientHelloStallRule`. Вердикты идентичны по построению;
   `go test ./censor/ ./probe/ ./diagnostics/` — зелёные в этом
   проходе. Регрессии нет.
2. **`bb7e2a1e` rollout-бакет**: Dart теперь хэширует настоящий NUL
   (`catalog.dart:146-147`, `'\u0000'` с объяснением ловушки `'\x00'`);
   Go-сторона и 7 pinned-векторов подтверждены аудитом прохода 2,
   за этот проход кода там не менялось. Зеркала сошлись, рассинхрона
   не осталось.
3. **`da936b06` declared-entries + canonical paths**: Go
   `Verify()` → `VerifyWithKey()` → `checkDeclaredEntries()` первым
   гейтом (package.go:179,237); Dart `verify()` (package.dart:169-188)
   проверяет те же 5 видов entry (panels, background, theme,
   network_hook, routing) на том же месте конвейера. Паритет полный.
4. **`e831c805`**: PASS2 N8 закрыт — `docs/extensions-api.md:27`
   `getServers → [{id, name, country, latency_ms}]` совпадает с
   `panel_screen.dart:289-303` (`country: ''` честно объяснён в
   комментарии :292-293, `latency_ms` из probe, −1 unknown).
5. **`8c81cb01`**: PASS2 N9 закрыт — комментарий `sora.dart:323-326`
   теперь точен («no-op while DetectCensorship has no Dart client;
   verdicts … arrive as censorship_detected watch events»), путь
   watch-событий завайрен. Остаток по существу прежний: `fetchVerdict`
   (`core/censor.dart:158`) никем не инжектится, CensorControl
   Dart-клиента нет (generated есть только core/custom/leak) — но
   теперь это честно написано в коде, обмана нет.
6. **`f044075c` NSDI / `d7a4b0aa` RunSeries**: проводка и тесты
   подтверждены аудитом прохода 2; остаточный комментарий
   `probe/serial.go:22-27` честен (CLI `-series-probe` завайрен,
   in-app триггер ждёт proto-поля — так и написано). Тесты probe
   зелёные (15.4 с).
7. **Примеры `.soraext`** (N1): независимо перемерено в этом проходе —
   все 4 архива без `author.key`/`author.pub`; содержимое
   routing-split — актуальный v1 (`routing.json`, не v0 `rules.json`);
   README примеров содержит burned-ноту (hello-panel README:22);
   `sora-ext pack` отказывает на `*.key` (`77f9f827`). Регрессии нет.
8. **PASS1 M2 (sync Meta.Hash)**: закрыт — `DirStore.Get`
   (service/sync/sync/store.go) пересчитывает `HashOf(payload)` с
   комментарием-обоснованием, кэш остался только в `List()` с
   legacy-fallback на пустой hash. Инвариант `Meta.Hash ==
   sha256(payload)` (sync.go:26) снова истинен для Get.
9. **Plan-поля**: см. дрейф выше — оба стиля честны, DNSServer.Dialer
   не пострадал (подтверждено аудитом, сборка/тесты зелёны).

---

## TODO/FIXME/NOT WIRED инвентаризация (задача 6)

- `TODO`/`FIXME`/`XXX`/`HACK` в Go и Dart **обоих репо: 0** (grep по
  `core/ service/ tools/ app/lib/` и legacy `core/`). Ни одного
  висящего TODO не осталось — включая бывший ложный блокер censor
  (закрыт `8c81cb01`).
- `NOT WIRED`-маркеров в sora: **20** (core 17, Dart 1, proto 2).
  Каждый сверен с deadcode/вызывающими: все 20 по-прежнему точны.
  Обратное направление («помечено wired, а вызывающих нет»): ложных
  маркеров не найдено; единственные **непомеченные** мёртвые места —
  L1 (`DefaultStrategy`, новый) и известный function-level остаток
  внутри честно помеченных пакетов (guard strict-машинерия — док
  пакета честен, врёт только комментарий одной функции, L5;
  Go-половина ext — док пакета `core/ext/doc.go` называет себя
  «reference implementation plus host service», что при 76
  недостижимых функциях и живом только Scheduler-пламбинге —
  формулировка на грани, но owner-класс F10, нового обмана нет).
- Маркеры, ставшие **неправдой в обратную сторону** (помечено NOT
  WIRED, а уже завайрено): не найдено. Ближайший кандидат —
  `probe/serial.go` — маркер заменён честным Wiring-комментарием
  в том же коммите, что и проводка (`d7a4b0aa`). ✓

---

## Docs vs code: spot-check ~25 утверждений (задача 5)

Сверено прямым чтением обеих сторон; «✓» — код подтверждает,
«фикс» — было неверно в прошлых проходах и исправлено, «✗» — находка выше.

| # | Утверждение | Вердикт |
|---|---|---|
| 1 | `docs/security.md:16` маскирование доменов «по переключателю, по умолчанию пишутся открыто» | ✓ фикс (ANALYSIS-20 P0 закрыт) |
| 2 | `docs/security.md:46` сетевые контакты приложения (GitHub, 12 ч, UA) | ✓ фикс, кроме L3 (каталог) |
| 3 | `README.md:56` minisign fail-closed, ключ — церемония владельца | ✓ (TeamPublicKey PLACEHOLDER, sign.go:22) |
| 4 | `README.md:58` «единственное обращение — обновления» | ✗ L3 |
| 5 | `README.md:12,48-49` платформы Win/Linux; zapret — Linux, «IP не скрывает» | ✓ |
| 6 | `docs/usage.md:74` Xray TUN на Windows с 1.0.10 через мост mihomo | ✓ фикс |
| 7 | `docs/usage.md:46` профили: привязка SSID/шлюз/ASN, «Применять автоматически» | ✓ (autoApply opt-in в коде, см. статус п. 2) |
| 8 | `docs/install.md:95` polkit: «любой процесс активной сессии = управление, сознательное решение» | ✓ честный TM |
| 9 | `docs/extensions-api.md:27` getServers форма | ✓ фикс (N8) |
| 10 | `docs/extensions.md:285` scheduler «не шедулит» | ✗ L4 (по существу верно) |
| 11 | `docs/extensions-quickstart.md:27` «author.key never commit» | ✓ теперь подкреплено кодом (pack refusal) |
| 12 | `docs/sync-threat-model.md:40` «app side is wired (2026-10-20)» | ✓ |
| 13 | `docs/faq.md` T054 RU-хостинг (ЦМУ ССОП/ФЗ-210) | ✓ (аудит прохода 2) |
| 14 | sora `core/obfs/doc.go` Production status | ✓ честен |
| 15 | legacy `core/obfs/doc.go` uTLS через Dialer | ✗ N7 повтор (дрейф) |
| 16 | `core/engine/stealth/stealth.go:9` NOT WIRED | ✓ честен |
| 17 | `core/probe/serial.go:22` Wiring (CLI да, in-app нет) | ✓ честен |
| 18 | `proto/core_control.proto:279,302` NOT WIRED события | ✓ помечены `351b0d87` |
| 19 | `app/lib/src/sora.dart:325` censor poll no-op причина | ✓ фикс (N9) |
| 20 | Контракт 1.11: proto Since ↔ Go Version ↔ Dart apiVersion | ✓ (кроме L6 — minSupportedMinor) |
| 21 | `examples/*/README` старые ключи burned | ✓ |
| 22 | `docs/extensions.md:195-222` поля каталога rating/rollout/changelog ↔ Go+Dart | ✓ (PASS2, кода не менялось) |
| 23 | `core/guard/mode.go:7` strict «unreachable from public API» | ✓ / комментарий функции — ✗ L5 |
| 24 | `core/ext/doc.go` «reference implementation plus host service» | ~ гранично, класс F10 (L2) |
| 25 | README sora-legacy позиционирование «для старых систем» | ✓ согласуется с наблюдаемым дрейфом |

Итог: 25 проверок — 19 ✓, 2 фикса подтверждены в составе ✓,
3 ✗ уровня Low (L3, L4, N7-legacy), 1 граничная (ext doc).
Privacy-P0 из ANALYSIS-20 (маскирование, «не ходит в сеть») закрыты
по-настоящему, новых враний уровня выше Low не найдено.

---

## Статус OWNER-DECISIONS-PASS2 (10 пунктов — только изменения статуса)

| # | Пункт | Статус на PASS3 |
|---|---|---|
| 1 | Xray-бамп v26.10.17 | без изменений: `packaging/engines/engines.lock:10` — всё ещё v26.3.27 |
| 2 | F5 авто-применение | **уточнение статуса**: opt-in `autoApply` реализован и задокументирован — `profiles.dart:28,42` (флаг, дефолт false), тумблер `ui/profiles.dart:328`, `handleProfileMatched` (sora.dart:1161) применяет с undo-снапшотом либо спрашивает; `usage.md:46` описывает ровно это. Живой триггер — `refreshFingerprint()` при открытии экрана/refresh, потому что профили в core-стор приложением не пушатся (SaveProfile без вызывающих, L8), и core-матчер `session.checkProfile` работает по пустому стору — это честно записано в комментарии sora.dart:1236-1243 («Open owner decision: one store of truth»). Остаток решения: авто-триггер по смене сети без экрана + единый стор. Реализацию как находку не предлагаю — фиксирую, что формулировка «текущее = только вручную» устарела |
| 3 | NOT WIRED модули ~5.5k | без изменений (deadcode: select 48 + tune 50 + wgobfusc 13 + stealth — те же) |
| 4 | nfqws-эпик | без изменений; побочный эффект — L1 |
| 5 | Key ceremony | без изменений: `core/ext/sign.go:22` TeamPublicKey — PLACEHOLDER |
| 6 | JS-исполнитель / Go-хост ext | без изменений (Go ext dead = 76, L2) |
| 7 | Strict kill switch | без изменений (не экспонирован; L5) |
| 8 | Android | без изменений: клиента нет, `docs/android-*.md` — спеки |
| 9 | Dev-машина | без изменений: тулчейнов Dart/C# в этой среде нет, перепроверить нечем |
| 10 | N1 ключ в примерах | **ЗАКРЫТ** проходом 2 (аудит) и независимо перепроверен здесь (п. 7 «Чисто») |

---

## Итоговый счёт

- **Нового: 1 Medium** (M1 — редaкторный микро-дрейф с реалистичной
  утечкой `pre_shared_key` в sora), **5 Low-новых/уточнённых**
  (L1 — осиротевший `DefaultStrategy`, рождён F11-фиксом; L2 —
  квантификация ext +2; L3 — доки про «единственное обращение» vs
  fetch каталога), **остальные Low — повторы без сдвигов**
  (L4–L10, N7-legacy).
- **Critical/High: 0** — третий проход подряд. Регрессий уровня выше
  Medium от правок проходов 1–2 не найдено; все закрытия прохода 2,
  перепроверенные здесь независимо (N1, N4, N8, N9, M2-прохода-1,
  rollout-паритет, declared-entries паритет, censor-opt), держатся.
- Deadcode: **347 / 22 / 0 / 0** против 346 / 22 / 0 / 0 прохода 2;
  дельта +1 полностью разложена на 4 поимённых события, из которых
  два — закрытия (−1 фасад, −1 recordRun), два — рост мёртвой
  половины известными фиксами (+1 DefaultStrategy, +2 ext-хелпера).
- Рекомендации следующим отделам (только спеки, код не трогался):
  M1 — объединить alternation редaктора в обоих репо + векторы в
  тесты обеих сторон; L1 — маркер или удаление `DefaultStrategy` +
  правка `plan.go:448`; L3 — одна фраза в README:58 и
  security.md:46; L4/L5 — по одному комментарию. L2/L6–L10 —
  в существующие owner-очереди, новых решений не требуют.

*Проход 3/3, отдел анализаторов, завершён 2026-10-20. Код не менялся,
коммитов нет. Артефакт: `~/workspace/bug-hunt/reports/PASS3-ANALYSIS.md`.
Временные файлы deadcode: `/tmp/dc3_sora_core.txt`, `/tmp/dc3_legacy.txt`,
`/tmp/dc3_sync.txt`, `/tmp/dc3_ext.txt` (эфемерны, выводы полностью в отчёте).*
