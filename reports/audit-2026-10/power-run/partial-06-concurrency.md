# Power-run 06 — Конкурентность

Агент №6. Ветки не переключал, не пушил. Коммит: `457c4bb`
`[power-run] concurrency: no wedged producers in probe benchmarks; stale pairing TTL cannot kill a new session`
(только свои файлы: `core/probe/bandwidth.go`, `core/probe/bandwidth_concurrency_test.go`,
`service/sync/api/pairing.go`, `service/sync/api/pairing_concurrency_test.go`).

Фильтр слопа владельца применён ко всем находкам: чиню только реальные баги минимальными
фиксами; спорное и косметическое — честно помечено и не тронуто.

## Находка 1 (исправлена): утечка engine-процессов и горутин в probe benchmarks

Файл: `sora/core/probe/bandwidth.go` (старые строки ~146–165, 181, 224, 231;
фикс: `send` на строке 154, `benchmarkOne(..., send)`).

Сценарий: `Benchmark` шлёт семплы в `out := make(chan BandwidthSample, len(outbounds)*2)`
**блокирующими** отправками, а каждый сервер генерирует ~1 initial + до ~120 progress
(тикер 500 мс) + 1 Done. Единственный потребитель — `control.BenchmarkServers`
(`core/control/benchmark.go:101`): при обрыве gRPC-стрима он выходит из `range samples`
и вызывает `cancel()`, больше канал никто не читает. Продюсеры, уже заблокированные на
`out <- sample` (буфер полон), **не разблокируются отменой контекста** — отправка не в
`select`. Итог: `wg.Wait()` не завершается, `close(out)` не происходит, отложенный
`eng.Close()` не выполняется — временные engine-процессы и горутины утекают навсегда.

Фикс: все отправки идут через `send` — сначала неблокирующая попытка (сохраняет контракт
«ровно один Done на сервер» для живого потребителя, включая существующий
`TestBenchmarkCancelled`), затем `select { case out <- s: case <-ctx.Done(): }`.
При отмене недоставленные семплы дропаются, горутины разматываются, engine закрываются,
канал закрывается. Контракт задокументирован на `Benchmark`: кто перестал читать —
обязан отменить ctx.

Честная оговорка: первая итерация фикса (только неблокирующий progress) была
**недостаточной** — неблокирующие отправки тоже занимают слоты буфера. Тест это поймал,
фикс переделан. Вердикт фильтра слопа: PASS — реальная воспроизведённая утечка,
минимальный фикс, контракт для живых потребителей не изменился.

Регрессионный тест: `TestBenchmarkAbandonedConsumerTearsDownEngines`
(`core/probe/bandwidth_concurrency_test.go`, медленный стаб — тики успевают заполнить
буфер). На старом коде падает детерминированно: `closed=0 built=2`; на новом — PASS.

## Находка 2 (исправлена): протухший TTL-сторож убивает новую pairing-сессию

Файл: `sora/service/sync/api/pairing.go` (фикс: `stopPairingSession`, строки 162–184;
сторож на строке 107).

Сценарий: `StartPairing` запускает горутину-сторож, которая по истечении `pairingTTL`
вызывает `d.StopPairing()` — а тот закрывает **текущую** сессию, кем бы она ни была.
Если TTL сессии A срабатывает ровно в момент, когда пользователь остановил A и
стартовал B (`select` выбирает между сработавшим таймером и закрытым `s.done`
случайно), сторож закрывает listener/advertiser сессии B и зануляет `d.pairing`.
Окно узкое, но реальное.

Фикс: `stopPairingSession(s)` закрывает сессию только если `d.pairing == s`; сторож
вызывает его вместо `StopPairing()`. Семантика `StopPairing()` (возврат ошибки
`listener.Close()`) сохранена. Вердикт фильтра слопа: PASS — реальная гонка,
точечный фикс, детерминированный регрессионный тест
(`TestStalePairingTTLDoesNotKillNewSession` в `pairing_concurrency_test.go`).

## Результаты `go test -race` / vet (тулчейн `~/workspace/go/bin/go`)

- `core`: `go test -race -count=1 ./probe/...` → **ok** (все существующие тесты +
  новый регрессионный); `go vet ./probe/` → чисто.
- `sync`: `go test -race -count=1 ./api/... ./transport/...` → **ok** (включая
  новый тест pairing); `go vet ./api/` → чисто.
- `go test -race ./probe/... ./ext/...` ранее — ok; единственное падение vet в
  `core/engine` было транзиентным артефактом чужого незакоммиченного редактирования
  (см. [cross-ref]).

Примечание: `/tmp` (tmpfs 512M) был забит скрачем других агентов → свои сборки
гонял с `TMPDIR=~/workspace/.tmp GOCACHE=~/workspace/.gocache` (скрытые каталоги,
вне репозитория).

## Проверено, чисто (без дублирования REVIEW-5PASS)

- `core/session/journal.go` Subscribe/unsubscribe: мьютекс, канал никогда не
  закрывается, cancel идемпотентен (`sync.Once`), публикация неблокирующая.
- `core/session/watchdog.go` + хук `EventEngineDown` в `runner.go:502`: `crashWatch`
  под своим мьютексом, вызывается из event loop.
- `core/control/exthost.go` WatchEvents-адаптер: `unsub()` на `ctx.Done()`, горутина
  завершается; `control/server.go` WatchEvents/`eventFeed`: `defer feed.close()` на
  всех путях; `runner.go` `engineSub` отменяется в `Stop` под `s.mu`.
- `core/ext/store.go`: порядок блокировок односторонний (Store.mu → Issuer.mu),
  гранты иммутабельны после `Mint`; `Verify`/`Revoke` под `t.mu`.
- `core/subscription/override.go`: все файловые операции под `s.mu`, nil-ресивер
  безопасен.
- `service/sync/transport/transport.go`: горутины `withDeadline` — буферизованный
  done-канал + дедлайн на соединении (не утекают); все ошибочные пути закрывают
  `netConn`; `WriteMsg`/`ReadMsg` — раздельные `wmu`/`rmu`, взаимных захватов нет.
- `service/sync/api` daemon: `wg.Add` всегда до `go`; счётчик > 0 пока жив хоть один
  потенциальный `Add` → гонки Wait/Add нет; `Shutdown` корректно останавливает всё.
- `service/sync/discovery` (`Browse`/`FindDevice`): буферизованные каналы, выход по ctx.
- `sync/sync/session.recv`: горутина ограничена временем жизни соединения
  (`defer c.Close()` у вызывающих).
- `core/engine/bypass/bypass.go` keep loop: `supervise.Start` привязывает процесс к
  ctx через вотчер — сиротских tpws при `Stop` нет; `e.mu` не держится поверх `Wait`.
- sora-legacy (кратко): `core/control/server.go` ProbeServers — суммарно отправок в
  буферизованный `results` ≤ `len(endpoints)+len(outbounds)` = ёмкости (измеритель
  шлёт ровно 1 результат на outbound, `registry.go:265`); утечки нет. `auth.go` —
  только RWMutex.

## Осознанно НЕ чиню (вердикт фильтра слопа)

- `time.After` в poll-циклах (`waitProxy`, `waitListening`, `discovery`) — только
  churn таймеров, не утечка. Править = шум.
- Мьютекс поверх дискового I/O (`ext.Store.Install/saveLocked`,
  `OverrideStore`, `Benchmarker.recordBandwidth`) — корректно, дедлоков нет
  (один мьютекс, без инверсий порядка); ослабление гранулярности — рефакторинг
  без выигрыша в корректности.
- Нетрекированная горутина `server.Close()`-вотчера в `http.go:ServeHTTP` —
  завершается по `d.ctx.Done()` в `Shutdown`; утечки нет.

## [cross-ref] для других агентов / оркестратора

- `core/engine/validate.go`: чужое незакоммиченное изменение (AmneziaWG-валидация)
  в момент моего прогона роняло `go vet ./engine/` (`expected at most 2 expressions`,
  :214); при повторной проверке — чисто. Не мой файл, не трогал.
- `core/ext/host.go`: чужая косметическая правка (убран `_ = g`) — на конкурентность
  не влияет.
- `service/sync/api/pairing.go` + `daemon.go`: параллельная чужая правка
  (upsertPeer теперь возвращает error); пакет собирается. Мой коммит включает их
  ханки как есть — отмечено в сообщении коммита.
- В `core/probe/bandwidth.go` до моего фикса существовал `TestBenchmarkCancelled`
  (отмена до старта) — он не покрывал сценарий «потребитель ушёл посреди замера»;
  новый тест закрывает именно его.
