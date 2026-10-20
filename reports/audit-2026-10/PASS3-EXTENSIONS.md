# Отдел расширений sora — проход 3/3 (PASS3-EXTENSIONS)

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`, пуша нет.
База: PASS2-EXTENSIONS.md, EXTENSIONS-40.md, PASS3-ANALYSIS.md,
OWNER-DECISIONS-PASS2.md п. 6. Решения владельца НЕ принимались:
JS-исполнитель не строился, судьба Go-хоста не решалась, приватный
ext-listener не проектировался в код. Все коммиты — temp-index +
commit-tree + CAS `update-ref` (ни одного bare commit, ни одного
`git add` в общий индекс).

Коммиты прохода:

| Коммит | Содержание |
|---|---|
| `2455159f` | docs: doc.go — честное разделение живой и reference-половин core/ext (задача 1 + граничная находка анализа по doc.go) |
| `eb045bbb` | settings: setSettings merge-семантика на всех поверхностях + код ошибки моста invalid-argument |
| `cdc58a5f` | dx: JSON Schema required == реальный контракт + schema_sync_test.go (пин зеркал) |
| `3af8bbd0` | security: TestEnforcementDartMirrorMatches — паритет enforcement-матрицы Go↔Dart запинен |
| `f822e26a` | fuzz: новый FuzzOpenBytes + итоги фазз-кампании увеличенным бюджетом |

Проверки финальные: `go build ./...` (ядро) чисто; `go vet ./ext/`
и tools `./...` чисто; `go test ./ext/ ./control/ ./cmd/sora-core/`
и tools `./...` зелёные; отдельный `-race` прогон по
worker/scheduler/pause/stop/status — зелёный; gofmt по тронутым
файлам чист. Dart — вычитка (SDK нет).

---

## 1. Задача 1: +2 недостижимых хелпера declared-entries (PASS3-ANALYSIS L2)

Разобрано по факту. `declaredEntries`/`checkDeclaredEntries`
достижимы только из `Package.Verify`/`VerifyWithKey`; те, в свою
очередь, не имеют прод-вызывающих внутри бинаря sora-core (живой
install-гейт — Dart-зеркало в `app/lib/src/ext/package.dart`).
Но честный потребитель у Go-половины есть, и это не тесты ради
тестов:

- `tools/sora-ext` (отдельный модуль, свой main): `ValidatePackage`
  вызывает `pkg.Verify()` — CLI есть авторитетный пакетный гейт для
  авторов (validate/pack/publish), и в модуле tools deadcode по этим
  функциям — 0.
- Внутри пакета: `Store.Install` (store.go:225) и rollback re-verify
  (:521) — reference-жизненный цикл, дословное зеркало Dart.

Решение: **не удалять и не завайривать фиктивно**. Удаление
развело бы зеркала (Dart-гейт остался бы без исполняемой спеки);
«потребитель» внутри бинаря ради deadcode-цифры был бы театром.
Вместо этого — честная маркировка там, где анализ нашёл граничную
формулировку: `core/ext/doc.go` теперь дословно разделяет пакет на
живую половину (ExtensionHost на control-сокете, issuer за
OpenStore-реестром, revocation-arming на старте, Scheduler-пламбинг
без зарегистрированных задач) и reference-половину (Verify incl.
declared-entry gate, Store lifecycle, catalog, ratings, sideload —
без прод-вызывающих в бинаре; живой гейт — Dart; судьба решается
вместе с п. 6 владельца). Счётчик deadcode ext останется 76 до
решения владельца — теперь с точной причиной в шапке пакета.

## 2. Задача 2: остаток поверхности прохода 2 — регрессий нет

- **Stop-abort воркеров под нагрузкой.** Код вычитан (runOnce:
  контекст прогона = min(timeout, task.ctx, pause-ctx через
  AfterFunc); abort хостом логируется interrupted и не идёт в
  circuit breaker; таймаут — честный фейл). `-race` прогон по
  Worker/Scheduler/Pause/Unregister/Stop/Status — зелёный, включая
  `TestUnregisterAbortsInflightRun` и `TestSchedulerStopAbortsInflightRun`
  из прохода 2.
- **Канонические пути.** Полный `go test ./ext/` зелёный:
  zip_path_test, package_entry_test (алиасы, dir-entries,
  missing entries всех 5 видов) держатся.
- **Rollout-паритет Go↔Dart после правок прохода 3.** Правки
  прохода 3 rollout не касались; паритет перепроверен независимо от
  кода: алгоритм Dart (пошаговый mod 10000, floor(f*10000))
  воспроизведён в Python против Go-семантики (uint64-транкейт) —
  7/7 pinned vectors совпали с ожидаемыми, sweep 3000 случайных
  install-id × 11 дробей (включая 0.29/0.57/0.07) — 0 расхождений.
  Go-тест `TestRolloutEligiblePinnedVectors` зелёный в составе пакета.

## 3. Задача 3: следующий слой

### 3.1 DX/Store — setSettings: три поверхности, две семантики (найдено и починено)

Контракт панелей обещал merge: docs/extensions.md:142 и quickstart
показывают `setSettings({refresh_seconds: 10})` как запись одного
ключа, и мок `sora-ext serve` всегда мержил. А оба настоящих стора —
Go `Store.SetSettings` и Dart `ExtensionStore.setSettings` —
**заменяли документ целиком**: панель, обновившая один ключ, молча
стирала остальные, включая значения, выставленные пользователем в
форме настроек приложения (форма пишет тем же путём). Расхождение
классическое «разработано под мок — в проде иначе».

Фикс (`eb045bbb`): validate-then-merge в обоих сторах (битый
stored-файл чинится в пустой, как в GetSettings; отклонённая запись
не меняет ничего — валидация до мерджа). Семантика дословно записана
в sora-ext.d.ts и docs/extensions-api.md. Пин: `TestSetSettingsMerges`
(merge / overwrite одного ключа / reject пишет ничего).

Заодно в том же пути: мост панелей возвращал `internal` на
отклонённые схемой значения, хотя d.ts/мок/доки обещают
`invalid-argument` (ExtStoreError не транслировался в BridgeError).
`panel_screen.dart` теперь транслирует, контракт запинен
комментарием у поля колбэка в bridge.dart.

### 3.2 DX — JSON Schema была строже реального контракта (починено)

`tools/sora-ext/schema/manifest.schema.json` требовал ключи
`permissions` и `capabilities`, которые оба парсера (Go
ParseManifestFull, Dart ExtManifest) трактуют как опциональные
(отсутствие = пустой список): редактор ругался на валидные по
авторитетному CLI манифесты. Schema приведена к контракту,
описания полей говорят «may be omitted» (`cdc58a5f`).

Чтобы зеркала не разъезжались в четвёртый раз, добавлен
`schema_sync_test.go` (tools/validate) — пины исполнением, а не
вычиткой: schema enum permissions == `ext.AllPermissions`; enum
capabilities == реестр; **каждое** поле из schema.required
поведенчески обязательно (удаление из манифеста ломает
ParseManifestFull), а permissions/capabilities в required быть не
должно; author.required — аналогично; sora-ext.d.ts называет все
методы моста, все 4 кода ошибок, все 4 вида событий и wire-поля.

Dogfooding: `sora-ext validate` по всем 4 примерам (проект + пакет) —
valid, только честные warnings (dangerous/unimplemented).

### 3.3 Security — enforcement-матрица: что ещё enforce'ится без исполнителя

Перебраны все 6 не-enforced строк:

- `settings.read`/`settings.write` (Inert) — API к настройкам
  приложения не существует по построению; собственные настройки
  расширения permissionless by design. Enforce'ить нечего.
- `tray` (Unimplemented) — API нет вообще.
- `theme.apply` (Unimplemented) — install-time кросс-чеки указателя
  (capability+permission) уже стоят в ParseManifestFull с прохода
  волн; runtime-потребителя нет, поднимать строку до InstallTime
  было бы неверно: в отличие от ui.panel, где loader реально
  обслуживает только задекларированные панели, тема не обслуживается
  никем — честный статус остаётся Unimplemented.
- `routing.rules`/`net.hooks` (оба RiskDangerous) — по решению
  владельца не тронуты. Проверка пинов: Go —
  `TestEnforcementDangerousAreNotClaimedEnforced` (статус, текст
  ноты «zero enforcement code», Enforced()==false) на месте и
  зелёный. **Dart-зеркало пина не имело** — добавлен
  `TestEnforcementDartMirrorMatches` (`3af8bbd0`): сверяет зеркало
  с Go-таблицей строка-в-строку в порядке реестра и отдельно
  утверждает, что оба Dangerous стоят unimplemented именно в
  Dart-таблице, которую читают install prompt и detail screen.

Итоговая матрица — без изменений статусов (поднимать было нечего,
и это зафиксировано, а не замаскировано): **5/12 Enforced**
(connections.read, servers.read, notifications, net.fetch,
background), **1 InstallTime** (ui.panel), **2 Inert** (settings.*),
**4 Unimplemented** (tray, theme.apply, routing.rules, net.hooks).

Install-time поверхность Dart перепроверена вычиткой и полна:
min_app_version гейт (store_screen, честный skip без APP_VERSION),
downgrade refuse, author-key pin + смена ключа при обновлении,
expected sha256 из каталога, rollout-гейтинг кнопок обновлений.

### 3.4 Store — catalog cache/rollout честность

Вычитка Go↔Dart: max_age (300..604800, default 3600), Fresh-семантика,
fallback на кэш при любой ошибке фетча/подписи, «cached» состояние
в UI, verified-only запись в кэш — паритет полный, правок не
потребовалось. Rollout — см. §2.

## 4. Задача 4: fuzz увеличенным бюджетом

Существующие таргеты — по 60 с каждый (проход 1: короткие прогоны;
здесь суммарно ~1.55M execs):

| Таргет | Execs | Итог |
|---|---|---|
| FuzzParseManifest | 228 766 | PASS, 0 находок |
| FuzzParseManifestFull | 422 256 | PASS, 0 находок |
| FuzzParseChecksums | 381 218 | PASS, 0 находок |
| FuzzParseRevocationList | 147 926 | PASS, 0 находок |
| FuzzFetchURLPolicy | 369 178 | PASS, 0 находок |

Пробел: у парсера пакетов — единственного, через который проходит
каждый sideload/catalog байт до проверки подписи, — таргета не было.
Добавлен `FuzzOpenBytes` (`f822e26a`): инварианты — без паник;
открытый пакет соблюдает все заявленные лимиты (безопасные
канонические пути, per-file/total/file-count caps, манифест
re-validate'ится, Verify не паникует). Прогон 60 с: 1 284 execs
(доминирует распаковка zip), PASS, 0 находок.

## 5. Инциденты ветки

Дважды за проход общий staged-индекс оказывался отравлен деревом
состояния «до моих коммитов» ровно по моим файлам (чужой процесс,
похоже, периодически делает read-tree/reset в общий индекс):
(1) после коммита `3af8bbd0` — staged-удаления трёх моих новых
тестовых файлов + staged-откаты 7 файлов; (2) после `f822e26a` —
staged-удаление package_fuzz_test.go. Оба раза: `git restore
--staged` только по своим путям, worktree и история не пострадали,
все 5 коммитов прохода проверены в HEAD после каждого инцидента.
Финальное состояние индекса — чисто. Отдельно: PASS2-EXTENSIONS.md
на диске буквально обрезан на полуслове маркером «...[truncated
9166 chars]» — файл отчёта прохода 2 повреждён при записи; к
родителю: выводы прохода 2 частично невосстановимы из файла
(использовалась уцелевшая часть + код как источник правды).

## 6. Остаток и спеки (честно)

- Owner п. 6 — без изменений и без самодеятельности: JS-исполнитель,
  судьба Go-хоста (deadcode ext = 76, из них +2 прохода 2 теперь с
  точной пометкой в doc.go), приватный ext-listener, proto для
  WorkerStatus (Go-источник правды готов с прохода 2, поверхности
  нет), Refresh-триггер revocation (ждёт key ceremony, п. 5).
- Mock расхождений после этого прохода: setSettings — выровнен
  (мёрж везде). Осталось известное: мок никогда не эмитит
  `not-connected` (фикстуры всегда «подключены») — приемлемо для
  мока, в d.ts код описан как поведение панельного моста.
- Notify-лимиты считаются в разных единицах по поверхностям
  (Go — байты, Dart/JS — UTF-16 units): все стороны отклоняют
  «длинное», расхождение только на экзотической границе у
  не-ASCII; не дыра, записано сюда как известный косметический
  остаток.
- Dart по-прежнему без SDK в этой среде: все Dart-правки прохода
  (merge в store.dart, трансляция ошибки в panel_screen.dart,
  док в bridge.dart) — вычитка; нужен `flutter analyze` на
  dev-машине владельца (п. 9).

*Проход 3/3, отдел расширений, завершён 2026-10-20. Коммиты:
2455159f, eb045bbb, cdc58a5f, 3af8bbd0, f822e26a. Пуша нет.*
