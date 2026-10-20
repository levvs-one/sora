# Отдел расширений sora — проход 2/3 (PASS2-EXTENSIONS)

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`, пуша нет.
База: PASS1-EXTENSIONS.md. Здесь — только НОВЫЙ слой прохода 2: что
перепроверено по факту в коде (включая [pass2-debt] коммиты других зон),
что доделано, что честно осталось. JS-исполнитель воркеров не
реализовывался — это решение владельца, как предписано.

Коммиты прохода (все — pathspec-форма `git commit -m ... -- <paths>`,
статистика каждого сверена после лендинга; чужие staged/unstaged
изменения общей ветки не тронуты):

| Коммит | Содержание |
|---|---|
| `1f0ba5e5` | runtime: отмена in-flight run при unregister/stop; WorkerStatus |
| `da936b06` | security: канонические пути архива; existence задекларированных entry в Verify (Go+Dart) |
| `bb7e2a1e` | store: Dart rollout-бакет хэшировал не те байты разделителя; pinned vectors в Go |
| `439f70d1` | store: gofmt repair-forward для `bb7e2a1e` (выравнивание таблицы векторов) |
| `e831c805` | dx: JSON Schema — contract pointers; контракт ошибок bridge == mock/TS/docs |
| `d43646d9` | ui: маркер «пока не активно» в install prompt + detail screen (63 l10n-файла) |
| `d95b589e` | docs: threat-model §6 синхронизирован с новыми проверками пакетов |

Проверки: `go build ./...` (всё ядро), `go vet ./ext/ ./control/
./cmd/sora-core/`, `go test ./ext/` (полный пакет, плюс отдельный
`-race` прогон по worker/pause), `go test ./control/ ./cmd/sora-core/`,
CLI `go build/vet/test` + dogfooding `sora-ext validate` по всем 4
примерам (valid, только честные warnings). Единственный фейл на пути —
`TestDetectCensorshipEventsWithoutOffsetsStayUnknown` под
`TMPDIR=$HOME/workspace/.build-tmp`: bind unix-сокета упирается в лимит
длины пути; с `TMPDIR=/tmp` тест и весь `./control/` зелёные. Env-артефакт,
не код. Dart — вычитка (SDK нет), см. §7.

---

## 1. Runtime

### Перепроверено по коду

Overlap guard и circuit breaker — на месте и покрыты тестами, как в
проходе 1. Scheduler в проде создаётся/стартует (main.go:355, Serve
:584), kill-switch синхронизируется, транспорт — туннельный fail-closed.

### Найден и починен реальный дефект надёжности

`runOnce` строил контекст прогона **только** от pause-контекста
kill-switch'а (`context.WithTimeout(pauseCtx, …)`). Контекст задачи
(`task.ctx`, который отменяют Unregister/замена/Stop) в прогон не
попадал. Следствия:

- Unregister/Disable в полёте: воркер продолжал работать до конца
  (до 5 минут `WorkerRunTimeout`), хотя расширение уже выключено.
- `Scheduler.Stop()` на shutdown: `wg.Wait()` ждал loop-горутину,
  застрявшую в таком прогоне, — выключение приложения могло висеть
  до 5 минут на одном застрявшем воркере.

Фикс (`worker.go`): контекст прогона теперь завершается первым из —
таймаута, контекста задачи (родитель) или pause-контекста (линк через
`context.AfterFunc`). Прогон, оборванный хостом (пауза ИЛИ
stop/unregister), логируется как interrupted и **не** идёт в circuit
breaker — раньше «оборван остановкой» считался бы честным фейлом, когда
доживал до возврата ошибки. Тесты: `TestUnregisterAbortsInflightRun`,
`TestSchedulerStopAbortsInflightRun` (+ существующие pause-тесты все
зелёны, `-race` чист).

### Честные статусы — добавлен снимок состояния

До прохода у Scheduler не было НИ ОДНОГО способа спросить состояние
задачи снаружи: поля WorkerTask неэкспортированы, исход последнего
прогона жил только в логе, `Fetcher.Stats()` был недостижим через
Scheduler. Добавлен `Scheduler.Status(extID) (WorkerStatus, bool)` и
`Statuses()` (сортирован): Disabled (user override), Running, Paused
(kill-switch), ConsecutiveFailures, HasRun/LastRunAt/LastRunOK/
LastRunInterrupted, Fetch *FetchStats. Принципиально честно:
задача, остановленная circuit breaker'ом, **отсутствует** в Status
(она unregistered — как и обещает её лог-строка), а не рисуется
виртуальным «broken». UI-поверхности у Status пока нет — нужен proto
(§6), в Go это готовый источник правды для неё.

## 2. Security

Матрица enforcement **не изменилась** — и это зафиксировано как есть:
5/12 on-call enforced, ui.panel install-time, 2 inert, 4 unimplemented,
оба RiskDangerous по-прежнему unenforced и запинены тестами
enforcement.go. Поднимать статусы документацией не стали. Усиливали
только то, что усиливается без исполнителя и потребителей: install-time
и статические гейты пакетов.

### Гейт 1 — канонические пути архива (был реальный обход слоя защиты)

Go `isSafeArchivePath` принимал `"./panel.html"`, `"a//b"`, `"a/./b"`
(Dart-открыватель их всегда отвергал посегментно — вердикты по одному
пакету расходились между CLI/ядром и приложением). Алиас — не косметика:

- extractor пишет файл по каноническому пути на диске, а инжектор CSP
  в `Store.extractLocked` сверяется с именем из манифеста — для
  `"./panel.html"` meta-CSP **не вставлялась** (оставался только
  HTTP-заголовок panel-сервера — второй слой, не первый);
- rollback re-verify (`readVersionFiles` даёт канонические имена)
  против checksums с алиасом **всегда падал** — пакет ставился, но
  откатить его было нельзя в принципе.

Фикс: `isSafeArchivePath` требует `name == path.Clean(name)`; записи
директорий пропускаются до проверки (как в Dart phase 2 — стандартные
zip с dir-записями продолжают открываться, тест это пинит).

### Гейт 2 — задекларированный entry обязан существовать в пакете

Ни Go, ни Dart не проверяли, что файлы, на которые манифест ссылается
указателями (панели, `background_task.entry`, `theme` /
`network_hook` / `routing` entries), вообще есть в пакете. Пакет без
своего panel-файла проходил Verify и ставился: панель 404, воркер без
скрипта, контрактный ассет молча отсутствует. Project-сторона CLI это
всегда запрещала (`missing-entry` в ValidateProject) — пакетная сторона
отставала от собственной спеки инструмента.

Фикс: `Package.Verify/VerifyWithKey` (Go) и `ExtPackage.verify` (Dart)
отказывают пакету с отсутствующим declared entry. Покрывает Install,
Rollback re-verify и CLI `validate` .soraext-файлов. Фикстура
`buildRawPackage` честно доукомплектована `worker.js`; новые тесты —
`package_entry_test.go` (panel/worker/theme/hook/routing missing,
алиас-путь, dir-entry). Threat-model §6 дополнен обеими проверками.

### Sideload — наблюдение без действия

`SideloadConsent` (Go) по-прежнему не имеет прод-вызывающих: экран
согласия рисует Dart по своим данным. Факты в Go не вр
...[truncated 9166 chars]