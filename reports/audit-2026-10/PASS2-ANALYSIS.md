# PASS2-ANALYSIS — свежий взгляд прохода 2/3 (после проходов 0–1 и [pass2-debt])

Дата: 2026-10-20. База: sora `999d58a0` (tip; 13 коммитов `[pass2-debt]`
поверх PASS1 tip `e60f9854`), legacy `1297c0f` (**без изменений с PASS1** —
все находки по legacy ниже получены свежим инструментальным прогоном по
тому же дереву, а не по новому коду).
Прочитано перед началом: `~/AGENTS.md`, `PASS1-SUMMARY.md`,
`PASS1-ANALYSIS.md`, `PASS1-AUDIT.md`, `FINAL-AUDIT.md`,
`SORA-LEGACY-DRIFT.md`. Код не трогался (только чтение, grep, deadcode,
build/vet для верификации).

**Метод — главное отличие от PASS1:** deadcode в PASS1 «технически не
удался» (тулчейн go1.26 против go1.27 пакетов) и был заменён ручным графом
импортов. В этом проходе прогон состоялся:
`GOTOOLCHAIN=go1.27.0 go run golang.org/x/tools/cmd/deadcode@v0.52.0 ./...`
по всем четырём Go-модулям. Корни — только `main`-пакеты, тесты корнями
НЕ являются: это именно «недостижимо из прод-бинарей», а не «никому не
нужно». Контрольный прогон `deadcode -test` по sora core = 0 (всё
достижимо из тестов — согласуется с FINAL-AUDIT).

**Честный вердикт коротко: Critical/High — ноль. Реально нового — один
кластер уровня Medium (примеры расширений: расхождение пакетов с
исходниками + секретные ключи внутри .soraext) и россыпь Low, в основном
впервые измеренного deadcode'ом мёртвого кода. Всё крупное — повторы
PASS1 с честными маркерами; pass2-debt ничего не сломал и несколько
старых хвостов честно дозакрыл.**

Итоги deadcode (недостижимых из прод-`main` функций, прод-файлы):
sora core — **346** (ext 75, tune 50, select 48, probe 44, engine 31,
censor 24, obfs 23, diagnostics 19, wgobfusc 13, session 7, errs 4,
guard 3, ipc 2, control 1, secret 1, deadcheck 1); legacy core — **22**;
service/sync — **0**; tools/sora-ext — **0**. `go build ./...` и
`go vet ./...` sora core — чисто; service/sync build — чисто.

---

## Medium

### N1. Примеры расширений: shipped `.soraext` не соответствуют своим исходникам, внутри пакетов — секретные ключи подписи (НОВОЕ)

Коммит `bc2b9d16` [pass2-debt] добавил `examples/` (4 примера) и гайды.
Проверка `sha256sum -c` и `cmp` loose-файлов против содержимого архивов:

- **Внутри** каждого `.soraext` checksums.txt сходится полностью —
  пакеты самосогласованы. Но собраны они из **старых** исходников:
  - `net-hook-dpi`: loose `README.md` и `hook.json` отличаются от
    архивных. Архивный `hook.json` — «Network-hook contract **v0
    (proposed)**» (strategies fake-sni/split/disorder), loose —
    актуальный L1-контракт (`hook_version: 1`, `engine_fragments`).
  - `routing-split`: архив содержит `rules.json` с «Routing-rules
    contract **v0 (proposed)**» — правила **без id, без priority, без
    routing_version**; loose `routing.json` реализует v1-контракт из
    спек (ids `^[a-z0-9-]{1,32}$`, priority, ≤512 правил). Манифесты
    разошлись: архивный `sora-extension.json` — `"entry": "rules.json"`,
    loose — `"entry": "routing.json"`. Плюс `README.md` differs.
  - `theme-midnight`: `README.md` differs. Только `hello-panel`
    консистентен полностью.
  - Итог: разработчик, пересобравший пример из loose-исходников по
    quickstart, получит пакет, отличный от shipped; разработчик,
    изучающий shipped-пакет, видит отменённый v0-контракт.
- **Секретные ключи в пакетах:** каждый из 4 архивов содержит
  `author.key` (141–160 байт, первая строка `untrusted comment:
  sora-ext signing key` — настоящий minisign secret key, его хеш есть
  в checksums.txt) и `author.pub`. Это прямо противоречит собственному
  `docs/extensions-quickstart.md:27`: «`author.key` secret — **keep
  offline, never commit**». Ключи — демонстрационные, по одному на
  пример, публичные части запинены в манифестах как автор «Sora Team»
  (`github:levvs-one`): любой может извлечь секретный ключ и
  переподписать изменённый пакет этим авторским ключом. Командного
  ключа каталога это не касается (церемонии не было), но паттерн
  «секретный ключ внутри распространяемого пакета» в официальных
  примерах — плохой прецедент, и ключи уже навсегда в git-истории.

Спека-фикс: пересобрать 4 пакета из актуальных loose-исходников,
`author.key`/`author.pub` из пакетов убрать (в пакете место только
манифесту, ассетам, checksums, signature), в README примеров честно
написать, что demo-ключи опубликованы намеренно и не имеют доверия —
либо перегенерировать примеры без ключей внутри.

### N2. Go-половина расширений: deadcode впервые измерил масштаб (ПОВТОР класса F10, новая квантификация)

`core/ext` — 75 недостижимых из прода функций, включая почти всю
мутирующую половину Go-стора: `Store.Install` (store.go:209),
`Store.Rollback` (:464), `Store.SetEnabled` (:540), `Store.Uninstall`
(:561), `Store.GetSettings/SetSettings` (:633/:662),
`ParseManifest`/`ParseManifestFull` (manifest.go:89,
manifest_v1ext.go:121), весь `sign.go` (`VerifyPayload`,
`VerifyPackageSignature`, `VerifyCatalogSignature`, `SignPayload`),
половина `catalog.go` (`ParseCatalog`, `CatalogCache.*`, `Fresh`),
`enforcement.go` целиком как API (`EnforcementTable`/`Enforced` —
матрица живёт только тестами и Dart-зеркалом). В проде из Go-стора
используются только `OpenStore`, `Get`, `Issuer`, revocation-кэш и
Scheduler-пламбинг (`cmd/sora-core/main.go:441-466`); установка,
настройки, парсинг манифестов и проверка подписей пакетов происходят
**исключительно в Dart-реализации**. Это та же архитектура, что
FINAL-AUDIT зафиксировал как owner-вопрос F10, — новое здесь то, что
pass1/pass2 продолжали наращивать именно недостижимую половину
(см. N3), а не достижимую.

### N3. `core/ext/ratings.go` — новый код сразу в недостижимой половине (НОВОЕ, Low-Medium)

Коммит `55541758` [pass2-debt] закоммитил `ratings.go` (был untracked
WIP в PASS1): `BayesianAverage` (:56), `DecayWeight` (:69),
`DeduplicateVotes` (:82), `Aggregate` (:105), `RankScore` (:128) —
**ноль вызывающих** вне файла и его тестов (проверено grep по
`core service tools` + deadcode). Рейтинг в каталоге приходит готовым
числом в JSON (`catalog.go:40-41` — только валидация диапазона),
Dart показывает его как есть. Честности ради: шапка файла прямо
говорит, что это «reference implementation of the published
methodology… The team server computes the aggregates» — обмана нет,
это нормативно-справочный код. Но по факту прохода: 133 строки новой
логики + 94 строки тестов приземлились в пакет, чья Go-сторона и так
ждёт owner-решения «удалить или завайрить».

---

## Low

### N4. `diagnostics/deadsession.go` — мёртвый фасад поверх deadcheck (НОВОЕ)

Файл — сплошные алиасы и форвардер: `DeadSessionState =
deadcheck.DeadSessionState` (:14-16, :20-22), `DetectDeadSession`
(:29-30) просто вызывает `deadcheck.DetectDeadSession`. Прод-вызывающий
у мёртвого режима один — `session/deadmode.go:127` — и он зовёт
`deadcheck` **напрямую**. У фасада вызывающих нет (deadcode:
`diagnostics/deadsession.go:29`). FINAL-AUDIT упоминал файл как
untracked WIP; теперь он закоммичен и остался лишним слоем дублирования
API. Удалить фасад или перевести deadmode на него — одно из двух.

### N5. `engine.FingerprintWarning` не вызывается никем; «S1 доставлен» — про другую функцию (НОВОЕ)

deadcode: `engine/fingerprint.go` — `FingerprintWarning` (:169),
`ParrotVersion` (:219), `KnownMissingPQKeyShare` (:249) недостижимы;
`IsStaleParrot` зовёт только незавайренный `stealth`. Док функции:
«Callers surface this in diagnostics» — вызывающих нет ни в Go, ни в
Dart (grep по всему репо). Реально завайренное уведомление прохода 1 —
другая функция: `parrotReviewNotice` на `engine.ParrotReviewOverdue`
(`core/control/server.go:596`). PASS1-SUMMARY кредитовал «S1
FingerprintWarning» как внедрённый внутри `be8eddd0` — внедрён был
monthly-watch, а сам `FingerprintWarning` как был без потребителя,
так и остался.

### N6. Одинаковый мёртвый код в обоих форках (НОВОЕ по измерению, Low)

deadcode нашёл дословно параллельный мёртвый набор в sora и legacy —
дрейф-отчёты отслеживали фичи, но не общее мёртвое наследие форков:

- `session.NewCompositeGuard` + весь `compositeGuard`
  (sora `session/guard.go:85`; legacy — те же 5 позиций): прод
  конструирует одиночный `guard.New` (`cmd/sora-core/main.go:250`),
  композитор не нужен.
- `errs`: `Keys`, `DefaultKey`, `Retryable`, `RetryAfter` — в обоих
  репо (sora `errs/catalog.go:194,204`, `errs/errs.go:232,242`).
- `secret.NewReference` (sora `secret/key.go:141`; legacy
  `secret/key.go:123`), `ipc.Dial`/`dialLocal` (оба репо).
- sora-only: `control.NewAuthenticator` (`control/auth.go:40`) —
  test-only конструктор, прод идёт через `LoadOrCreateToken`;
  `session.KeepaliveInterval` (`session/rehandshake.go:59`).

Каждое по отдельности — мелочь; суммарно это класс «форки тащат общий
балласт», который без deadcode не виден.

### N7. Legacy: док obfs обещает завайренный uTLS-диалер, которого нет (НОВОЕ — непортированная честность)

В sora `core/obfs/doc.go` переписан честно (SW1c из SWARM-REPORT:
«Production status… WrapConn and DialTLS… are not called by any
production code path»). В legacy тот же пакет документирован в
прежнем, неправдивом виде: `sora-legacy/core/obfs/doc.go` — «the
obfuscation suite for TLS handshakes the core initiates itself…
uTLS profiles are available to direct TLS dials via Dialer, where the
caller owns the whole handshake». По deadcode+grep в legacy у
`Dialer.DialTLS` (`obfs/dial.go:37`), `Profile.UTLSConfig`
(`obfs/utls.go:56`), `Profile.NewUTLSConn` (:106), `Profile.
FingerprintID` (:19), `Profile.UTLSEnabled` (`obfs/profile.go:110`)
**ноль прод-вызывающих**. Справедливости ради: фрагментация через
fetcher в legacy действительно завайрена
(`subscription/subscription.go:112-116`) — врёт только uTLS-часть
дока. Фикс честности из sora в legacy не портирован.

### N8. `docs/extensions-api.md`: форма `getServers` не совпадает с кодом (НОВОЕ)

Новый (pass2-debt) API-гайд, таблица методов: `getServers` возвращает
`[{id, name, country, latency_ms}]` (`-1` = unknown). Реальная
реализация моста — `app/lib/src/ui/extensions/panel_screen.dart`,
`_servers()`: возвращает `{id, name, protocol}` — ни `country`, ни
`latency_ms` нет. Панель, написанная по гайду, прочитает undefined.
Остальной мост честен: `getConnections` идёт в настоящий
`ListConnections` RPC, лимиты `notify` (title ≤120, body ≤500)
принуждаются в `app/lib/src/ext/bridge.dart:92`.

### N9. Censor: Dart-обоснование «ядро ещё не готово» устарело (ПОВТОР спеки FINAL-AUDIT, обострение новое)

Go-сторона CensorControl полностью готова и зарегистрирована:
`core/control/censor.go:22`, `core/cmd/sora-core/main.go:437`;
proto/README заявляет «1.11 adds sora.censor.v1.CensorControl».
Dart-клиента по-прежнему нет ни сгенерированного, ни рукописного
(в `app/lib/src/core/link.dart` конструируются только core/custom/
leak/obfs клиенты), а `fetchVerdict` не инжектится. При этом
комментарий в `app/lib/src/sora.dart:319` гласит: «A no-op **until
the core detector API lands** (CensorDetector.fetchVerdict)» — API
уже приземлился; не хватает только Dart-клиента. Экран цензуры
остаётся локально-инертным, но причина в коде названа неверно —
следующий, кто пойдёт чинить «по комментарию», будет искать не там.

### N10. guard: внутреннее противоречие доков strict-режима (ПОВТОР-окрестность, Low)

`guard.Options` честен: strict-режим «exists inside the package for
tests but is not selectable here… product decision the owner has not
taken». Но `guard/mode.go` (`strictWanted`) комментирует: «Callers
use it at startup to decide between Guard.reconcile (re-arm) and
stale-table cleanup». По deadcode `Guard.reconcile` (guard.go:209),
`Guard.strictIntent` (:244) и `parseMode` (mode.go:62) вызывающих не
имеют; стартап делает только `CleanupStale` напрямую
(`main.go:~245`). Поведение безопасно, документация внутри одного
пакета противоречит сама себе.

### N11. service/sync: `log.Printf` ×3 (ПОВТОР, выросло с 2)

FINAL-AUDIT фиксировал ×2. Сейчас: `service/sync/api/syncloop.go:88`,
`service/sync/api/pairing.go:164`, `service/sync/cmd/sora-sync/
main.go:123`. Мелочь, но направление не то.

---

## Повторы PASS1 — статус подтверждён без изменений (не новые)

- **Театр-пакеты**: `core/select` (48 недостижимых функций), `core/tune`
  + `tune/desync` (50), `core/wgobfusc` (13), `core/engine/stealth` —
  ноль прод-импортёров у каждого; маркеры `NOT WIRED` честные,
  для select обновлены коммитом `999d58a0` вместе с Dart-маркером
  (`app/lib/src/sora.dart:2396`). ~5.5k строк, owner-решение висит.
- **Честно помеченные примитивы без триггера**: `DetectDNSIntercept`
  (diagnostics/dnsintercept.go:129), `ClassifyDegradation`
  (throttle.go:110), `RunSeries` (probe/serial.go:80), `CalibrateBrutal`
  (probe/calibrate.go:21), `ProbeQUIC` (probe/quic.go:132),
  `ProbeTrojanFallback` (probe/trojan.go:340), censor `FreezePolicy`/
  `SNIPool`/`HandshakeLimiter` (budget.go:25), bypass nfqws (T005,
  NFQWS-MIGRATION.md на месте), ротация ключей SS/WG
  (engine/ss.go:180 NOT WIRED). Все маркеры сверены с отсутствием
  вызывающих — **ни одного ложного маркера и ни одного «помечено
  wired, а вызывающих нет» не нашлось** (обратное направление чисто).
- **RPC без Dart-клиента: ≈21/54** (стабильно с FINAL-AUDIT 22/54):
  CoreControl не зовутся из приложения: ParseImport, FetchSubscription,
  GetRoutingPresets, RunDiagnostics, ListSubscriptions, PutSecret,
  DeleteSecret, Save/GetSubscriptionOverride, List/Save/DeleteProfile,
  ProbeChain, GetBenchmarks (RETIRED); CensorControl — 1/1;
  ExtensionHost — 6/6 (приложение живёт на Dart-реализации).
  Профильный CRUD при этом честно локален в Dart; `GetNetworkFingerprint`
  и `ProfileMatched` живы — F5-статус из PASS1 без изменений.
- **Асимметрия версий**: Go `main.go:50` — `Version{1, 11,
  MinSupportedMinor: 1}`; Dart `app/lib/src/core/link.dart:20` —
  `ApiVersion(major: 1, minor: 11, minSupportedMinor: 6)`. Повтор
  Medium-дрейфа FINAL-AUDIT; `e9df39fd` добавил Since-маркеры и
  контрактный тест тегов, но не это.
- **Дубли**: `itoa` ×5 (пятый, `diagnostics/dnsspoof.go:245`, теперь
  закоммичен); `largePlan()` ×3 в render_bench_test.go трёх движков.
- **docs/extensions.md:281-282**: «no host… schedules workers yet» —
  формулировка по-прежнему чуть устарела (Scheduler создаётся,
  стартует и останавливается в проде, `main.go:355,583-585`,
  `SetFetchTransport` завайрен `:410`), по существу верна (задач не
  регистрируется, JS-исполнителя нет; комментарий в `main.go:351-354`
  честен дословно).
- **Мусор в дереве** (не коммитить, статус прежний): `core/sora-core`,
  `service/sync/sora-sync.exe`, `__pycache__`,
  `core/control/subscriptions.go.3091033395789509018` — untracked.

## Проверено — чисто / закрыто-ложно (чтобы не копали повторно)

1. **Proto ↔ Go ↔ Dart (core)**: все 40 RPC CoreControl реализованы в
   Go, единственный отсутствующий — `GetBenchmarks` (RETIRED по
   дизайну, `Unimplemented`, wire-совместимость сохранена,
   proto-комментарий и `contract_test.go:75-76` пинят его теги).
   Дельта pass2-debt по proto — **только комментарии** (Since-маркеры);
   Dart-стаб зеркалит proto (spot-check SessionPlan: теги
   chain=15/zapret_with_vpn=16/zapret_strategy=17 совпадают,
   `core_control.pb.dart:901-924`). Custom/Leak/Obfs/Censor — все
   реализованы в Go; Dart-клиенты есть у custom/leak/obfs
   (obfs — рукописный, честно помечен в шапке `app/lib/src/obfs.dart`).
2. **Каталог расширений Go↔Dart↔доки**: поля `rating`,
   `ratings_count`, `rollout_fraction`, `changelog` согласованы в
   `core/ext/catalog.go`, `app/lib/src/ext/catalog.dart` и
   `docs/extensions.md:195-222`. Расхождений нет.
3. **Новый Dart UI pass2-debt завайрен**: conflicts sheet зовётся из
   `store_screen.dart:1096`; все классы `ui/*Screen` достижимы
   (ModesGuideScreen — через `showModes` из settings_screen.dart:178,
   ложная тревога первого grep снята).
4. **sora-ext CLI**: все команды из quickstart (scaffold, dev, serve,
   validate, pack, sign, publish) существуют (`cmd/sora-ext/main.go:
   28-35`); deadcode по модулю — 0.
5. **`MissingFor`** (b93b59a0) завайрен: `engine/supervise/
   supervisor.go:302`, `engine/catalog.go:255`.
6. **checksums внутри .soraext** валидны (см. N1 — проблема не в
   чексуммах, а в устаревших исходниках пакетов и ключах внутри).
7. **cmd/sora-censor-proxy** — честно документированный ручной стенд
   («Manual runs; CI wiring is a separate task»), не поставляется и
   не заявляется как часть продукта. Не театр.
8. **Legacy**: коммитов после PASS1 нет; redactor-паритет (D2) и
   микро-дрейф паттернов из PASS1-AUDIT зона 9 — без изменений;
   новых расхождений внутри legacy не появилось по определению.

## Дрейф sora ↔ legacy: дельта прохода

Legacy стоит на `1297c0f`, поэтому вся дельта — односторонняя: 13
коммитов sora не портированы (протокольные Since-маркеры, stealth-
грейдинг `73d62fc1`, ratings, примеры/гайды расширений, T011-маркеры).
Содержательно для legacy релевантны только: (а) N7 — фикс честности
obfs-дока существует в sora и не портирован; (б) N6 — общий мёртвый
набор форков, чистка которого в одном репо без другого увеличит
расхождение файлов, которые иначе идентичны. Остальное — фичи и
контракты, которых в legacy нет по позиционированию (см.
SORA-LEGACY-DRIFT).

## Итоговый счёт

- **Нового: 1 кластер Medium** (N1: примеры — устаревшие пакеты +
  ключи внутри), **1 новая квантификация известного класса** (N2),
  **6 Low-новых** (N3–N8, из них N7 — дрейф честности в legacy),
  3 обострения/повтора с новыми деталями (N9–N11).
- **Critical/High: 0.** Впервые за все проходы deadcode отработал по
  всем модулям: прод-недостижимый код почти весь либо честно
  помечен NOT WIRED, либо является известной owner-очередью
  (select/tune/wgobfusc/stealth, F10 Go-ext). Непомеченного нового
  «театра» уровня пакетов не нашлось — нашёлся непомеченный мёртвый
  код уровня функций и один непорядoк в примерах.
- Рекомендации финальному аудиту прохода 2: N1 (пересборка примеров
  без ключей), N4 (снести фасад deadsession), N8 (одна строка в
  api-гайде), N9 (правка комментария в sora.dart:319). N2/N3/N6 —
  в owner-очередь к F10 и решению по форкам.

---

*Проход 2/3, отдел анализаторов, завершён 2026-10-20. Код не менялся,
коммитов нет. Артефакт: `~/workspace/bug-hunt/reports/PASS2-ANALYSIS.md`.
Временные файлы deadcode: `/tmp/deadcode_sora_core.txt`, `/tmp/dc_legacy.txt`,
`/tmp/dc_sync.txt` (эфемерны, выводы полностью в отчёте).*
