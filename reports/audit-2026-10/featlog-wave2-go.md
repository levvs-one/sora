# Wave 2 backend (Go) — featlog

Ветка: `bugfix/audit-2026-10-19` (только локально, пуша нет). Формат коммитов: `[feature][sora-go] <что> (F<N>)`.

## F2 — выбор сервера по пропускной способности

- `core/probe/bandwidth.go` — `Benchmarker`: замеры через временную сессию движка **на каждый сервер отдельно** (изоляция маршрутизации), один outbound в плане `benchmark` с `LocalProxy{Enabled:true}` + правило `MatchAll→benchmark`, прокси-порт движка через `runtimeProvider` (`Running()` от встроенного `*supervise.Supervisor` — есть и у clashapi, и у xray). Скачивание диапазона параллельно через явный прокси (без утечек env-прокси), гарантированный teardown `defer eng.Close()`. Прогресс-сэмплы 0..99 + финальный 100/done.
- История: `probe/history.json` в DataDir, атомарная запись (tmp+rename), 0600/0700, TTL 24ч через `StaleAt(now)`, `RecordLatency` мёрджит латентность с пропускной способностью.
- `core/probe/bandwidth_test.go` — 7 тестов (успех, нет движка, падение старта, отмена, TTL/персистентность, мёрдж, валидация конфига).
- Proto (`proto/sora/core/v1/core_control.proto`): RPC `BenchmarkServers` (stream), `GetBenchmarks`, `SaveSubscriptionOverride`, `GetSubscriptionOverride` + сообщения `BandwidthSample`, `BenchmarkRecord`, override-сообщения. Go-код перегенерирован (buf 1.50.0, `/tmp/buf.gen.go.yaml`).
- `core/control/benchmark.go` — хендлеры: аутентификация control-токеном (замеры жгут трафик и спавнят процессы), клампы: servers ≤ 32, duration 5..60с (дефолт 10с), concurrency 1..4 (дефолт 2); резолв `server_ids` по спискам подписок, неизвестные id — done-сэмпл с ошибкой, а не падение батча.
- Латентность из `ProbeServers` автоматически пишется в историю (`feedBenchmarkLatency`) — источник данных для smart score.
- `core/cmd/sora-core/main.go` — `probe.NewBenchmarker` с `NewEngine: app.engines.Factory()` и `SelectKind` через `engine.SelectEngine` + `registry.Availability()`; `control.Config{DataDir, Benchmarker}`.
- API minor: **1.8 → 1.9** (`Version` в main.go). Dart-стороне нужно обновить `link.dart` (задача Dart-агента).

Коммиты: `83b6935` (F6: override store + control), `cfbbf30` (F2: benchmark RPCs + wiring + API 1.9), `3b221f3` (F7: watchdog + network). Каждый коммит собирается отдельно (проверено `go build ./...` на каждом).

## F6 — override-слой поверх подписки

- `core/subscription/override.go` — `Override{renames, hidden, extra_rules, pinned_order}` + `OverrideStore`: файлы `overrides/{id}.json` в DataDir, атомарная запись, валидация id `^[0-9a-f]{16}$` (защита от path traversal), битый JSON → `ErrOverrideCorrupt` (вызывающий логирует и продолжает, обновление не падает), пустой override удаляет файл.
- `core/control/override.go` — `applySubscriptionOverride`: hidden фильтрует (без алиасинга backing array), renames клонируют spec через `proto.Clone` (vet ловил копирование мьютекса protobuf), pinned — стабильный reorder. Сырой список провайдера остаётся в хранилище; оверрайды применяются в `stateLocked` (вид для UI), поэтому un-hide работает без refresh.
- Хуки: `delete()` чистит файл оверрайда; `SaveSubscriptionOverride`/`GetSubscriptionOverride` RPC с control-токеном; save возвращает обновлённый `SubscriptionState`.
- Тесты: 6 в subscription (round-trip, missing, corrupt, bad-id, empty-removes, nil-store) + 5 в control (noop, rename/hide, pin, unknown-pin, empty-rename).

Коммит: `83b6935`.

## F7 (backend) — пакет живучести

- `core/session/watchdog.go` — `crashWatch`: >5 крашей движка за 60с → одно событие `EventError` с новым ключом `errs.KeyEngineUnstable` (`core.engine.unstable`, каталог `core/errs/catalog.go`); эпизод сбрасывается после тихого окна или чистого переподключения. Хук в `runner.go` на `EventEngineDown`; `reset()` при `StateConnected` (старт и восстановление).
- Супервизор уже рестартит с backoff в пределах бюджета (5/10мин) и шлёт `EventFatal` при исчерпании — watchdog дополняет его, а не дублирует.
- `EventNetwork` (`core/session/journal.go`): эмитится в `renewConnections` при смене сети; `toWireEvent` маппит явно в `LogBatch` с префиксом `NetworkEventPrefix = "network-changed: "` (парсит клиент).
- Graceful degradation: `registry.Factory` уже выбирает движок по preference order с fallback между видами — нового кода не потребовалось, зафиксировано здесь во избежание дублирования.
- `session_intent.json` самовосстановление — backend-часть отсутствует в дереве (нет существующего механизма intent'а); UI-часть (автозапуск с выбором) — за Dart-агентом. Не реализовано, см. «Пропущено».

Коммит: `3b221f3`.

## Проверки

- `go build ./...` + `go vet ./...` — чисто (vet поймал копирование protobuf-мьютекса — исправлено через `proto.Clone`).
- `go test ./...` — всё зелёное, кроме предсуществующего `TestTunAndFakeIPAvoidLANAndEachOther` (падает и на чистом дереве: overlap fake-IP pool с интерфейсами песочницы, не регрессия).

## Пропущено / делегировано

- `session_intent.json` (F7#6 backend): в дереве нет intent-механизма; UI-автозапуск — задача Dart-агента.
- Dart: bump `link.dart` до API 1.9, экраны F2/F6/F7 — задача Dart-агента (у него незакоммиченные изменения в `app/`).
- Незакоммиченные изменения `core/engine/supervise/binary.go` и `core/session/runner.go` (guard fix) в рабочей копии — не мои (похоже, другой агент), не трогал.
- buf 1.50.0 лежит в `/tmp/buf/buf/bin/buf` (эфемерно); шаблон генерации — `/tmp/buf.gen.go.yaml`.
