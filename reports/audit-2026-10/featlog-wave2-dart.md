# Wave 2 UI (Dart) — featlog

Ветка: `bugfix/audit-2026-10-19`. Пути: только `sora/app`.
Flutter SDK в окружении нет — код вычитан вручную (многопроходно: баланс скобок
токенизатором, сверка акцессоров protobuf с паттерном сгенерированного кода,
проверка типов/импортов/ключей локализации), сборка невозможна.

## F2: выбор сервера по пропускной способности — DONE (UI готов, RPC ждёт Go)

Backend (параллельный Go-агент): `core/probe/bandwidth.go` + streaming RPC
`BenchmarkServers`. На момент написания Go-агент ещё не работал, поэтому
клиентская часть заложена строго по спеке FEATURE-PLAN.md §F2 и помечена
`HAND-WRITTEN (pending Go protoc codegen)`:

- `app/lib/src/generated/sora/core/v1/core_control.pb.dart`: вручную дописаны
  `BenchmarkServersRequest` (api_version, control_authenticator, server_ids,
  duration_s, concurrency) и `BandwidthSample` (server_id, bytes_per_sec,
  progress_pct, done, error) — строго по паттерну protoc-gen-dart. Семантика
  `$_getN/$_setString/...` (индекс поля) vs `$_setField/$_clearField` (номер тега)
  выведена из существующего кода (доказано на `ProbeResult.method`, tag 5 →
  index 4) и проверена скриптом по всем 10 полям. Найденный при самопроверке
  баг (`$_setBytes(2)` вместо `(1)` у control_authenticator) исправлен.
- `core_control.pbgrpc.dart`: клиентский метод `benchmarkServers`, дескриптор
  `_$benchmarkServers` (`/sora.core.v1.CoreControl/BenchmarkServers`),
  server-side `ServiceMethod` + `benchmarkServers_Pre` — по шаблону
  `probeServers`.
- `core_control.pbjson.dart`: `$json`-карты + base64-дескрипторы, сгенерированы
  честным protobuf-энкодером на Python с round-trip проверкой
  (имена/номера/типы/лейблы полей). Файл нигде не импортируется, но оставлен
  консистентным.
- `app/lib/src/sora.dart`:
  - `bandwidth: Map<String, ({int bps, DateTime at})>` + персист в
    `settings.benchmarkHistory` (JSON, толерантен к битым данным),
    `freshBandwidth()` (TTL 24ч — stale игнорируется speed-режимами),
    `benchmarkServers({serverIds})` — стриминг с троттлингом `notifyListeners`
    (тот же `_probeNotifyInterval`, что у probe), `benchmarkProgress`,
    `benchmarkPct` (per-server %), `cancelBenchmark()` (частичные результаты
    сохраняются), `canBenchmark`.
  - Ядро без RPC отвечает UNIMPLEMENTED → дружелюбное `errBenchmarkUnsupported`
    через `describe()` вместо сырой gRPC-ошибки.
  - Smart-скоринг: топ-уровневые чистые `freshBandwidthOf`, `smartScoreOf`
    (пинг 40% / скорость 40% / свежесть 20%), `compareAutoSelect`
    (ping/speed/smart, tie-break по пингу). `_fastest`, `buildPlan`
    (новый опциональный `bandwidth`, `settings.autoSelectMode`),
    `pickMember` (опциональные `bandwidth`/`autoSelect`, дефолт — старое
    поведение) переведены на него; `Sora.compareServers(a, b, mode)` — для
    сортировки списка (+ режим `name` через `displayNameOf`).
- `app/lib/src/ui/servers.dart`: кнопка замера (открывает экран бенчмарка),
  меню сортировки (пинг/скорость/имя, `MenuAnchor` по существующему паттерну),
  колонка скорости под пингом (stale — приглушённым), сортировка групп по
  представителю того же режима.
- `app/lib/src/ui/benchmark.dart` (новый): `BenchmarkScreen` — автозапуск
  замера при открытии, общий прогресс (`benchmarkProgress(done,total)`),
  per-server прогресс-бары, результаты (быстрые сверху), stale-метки,
  отмена, повторный замер, empty-state.
- `app/lib/src/ui/settings_screen.dart`: `ChoiceTile` режима автовыбора
  (пинг/скорость/умный, с replan — влияет на план) в секции пинга.
- Локализация: `speedMbps(double)` во всех 31 файле + arbs (ru: «Мбит/с»).

## F7: пакет живучести (UI-часть) — DONE

- Watchdog за `WatchEvents` (`app/lib/src/sora.dart`): счётчик `_watchFailures`
  в `_watchSession`, сброс любым здоровым событием; первая ошибка стрима —
  тост `coreRestoringLink` («восстанавливаем связь» вместо тихих ретраев);
  после 5 неудач подряд — авто-восстановление останавливается, выставляется
  `failure = 'app.core_watch_unstable'` (маппинг в `describe()` → `kit.dart`),
  на home — баннер с кнопкой «Переподключить» → `repairWatch()`.
  При ошибке стрим переоткрывается с паузой 2с (без tight loop).
- Crash-intent: `connect()` пишет `settings.sessionIntent` (JSON
  `{server, at}`), `disconnect()` чистит; `run()` при старте вызывает
  `checkCrashIntent()` → `_pendingRestore`; баннер на home:
  `crashRestoreTitle` + «Восстановить» (`restoreCrashedSession()` — ставит
  выбор и коннектится; удалённый сервер безопасно фолбэчится в auto через
  `selected`) / «Не надо» (`dismissCrashRestore()`). Тоггл `restoreOnCrash`
  в секции соединения настроек (дефолт true).
- Staged updates (`app/lib/src/updates.dart`): `enum UpdateStage
  {idle, checking, downloading, verifying, installing}`, переходы в
  `check()`/`install()`, `cancel()` — прерывает проверку/загрузку через
  общий `_abort`-триггер `_fetch` (отмена не превращается в ошибку:
  `_cancelled` глушит `error`), handoff установки отменить нельзя — так и
  задокументировано. `about.dart`: подпись этапа (`updateStageVerify` …),
  кнопка «Отмена» на этапах checking/downloading.

## F6: override-слой подписки — DONE (локально, RPC ждёт ядро)

- `app/lib/src/overrides.dart` (новый): `SubscriptionOverride`
  (`{renames: {id: name}, hidden: [id]}`, толерантный парсинг) + `OverrideStore`
  (кэш, персист в `settings.subscriptionOverrides`, `onChanged`-хук).
  JSON-формат зеркалит запланированный core-формат — миграция на будущие
  `Save/ GetSubscriptionOverride` RPC — drop-in.
- `app/lib/src/sora.dart`: `overrides`, `hiddenServerIds`, `displayNameOf()`;
  геттер `servers` фильтрует скрытые (план коннекта, probe, fallback —
  скрытые серверы нигде не используются); `deleteSubscription` чистит правки;
  `onChanged` → `notifyListeners()` + `_replan()` (скрытие активного сервера
  предлагает переподключение; rename на план не влияет — ID стабильны).
  `displayNameOf` применён везде, где видно имя сервера: home `_ServerCard`,
  tray (`desktop.dart`), список соединений (`connections.dart`), экран
  серверов (через `Entry.renamed`).
- `app/lib/src/ui/subscription.dart`: секция «Мои правки» (`Heading` +
  `Group`): строки правок (rename с исходным именем в detail / «Скрыт»),
  тоггл видимости с тултипами, удаление rename, диалог-пикер серверов
  (`_ServerPicker`: тап — rename через `showFieldSheet`, глаз — hide),
  ссылка «Особые правила» → `RulesScreen`, «Очистить правки» (danger +
  `confirm`). Правки переживают refresh подписки (ключ — server ID).
- `app/lib/src/groups.dart`: `Entry.renamed()`, `Entry.withoutHidden()`
  (rename только для одиночных записей — группировка стабильна).
- Локализация: `overrideTitle/Hide/Unhide/Clear/Empty/CustomRules/Edit`,
  `restoreOnCrash` — во всех 31 файле + arbs (ru переведено).

## Самопроверка (без SDK)

- Токенизатор баланса скобок/строк/комментариев/интерполяции: все 14 файлов OK.
- Все 10 акцессоров hand-written protobuf-классов сверены с конвенцией
  сгенерированного кода (индекс vs тег) — 1 баг найден и исправлен.
- Base64-дескрипторы pbjson: round-trip decode → поля/номера/типы совпадают.
- Ручной проход типов: `num` от `clamp` исправлен, `export 'core_control.pb.dart'`
  в pbgrpc подтверждает видимость типов, `MenuAnchor`-паттерн сверен с
  `connections.dart`, `const`-конструкторы (`RulesScreen`, `BenchmarkScreen`)
  проверены, все `S.of(context)`-ключи существуют в `strings.dart`
  (31 файл) и arbs валидны (JSON parse).
- `cancel()` в updates защищён от вызова после dispose.

## Что проверить на dev-машине (обязательно до мержа)

1. `flutter analyze` — особенно hand-written protobuf (pb/pbgrpc/pbjson) и
   `servers.dart`/`subscription.dart`/`benchmark.dart`.
2. Запуск: открыть экран серверов → меню сортировки (3 режима), кнопка замера
   → экран бенчмарка (нужен Go-RPC; без него — дружелюбная ошибка
   `errBenchmarkUnsupported`, не красная).
3. F6: rename/hide сервера → список серверов, home-карточка, трей, соединения;
   refresh подписки — правки на месте; удаление подписки — правки чистятся.
4. F7: убить процесс при активном соединении → при старте баннер
   восстановления; staged update — этапы + отмена (Linux/Windows).
5. Иконки `Symbols.gauge_rounded` / `Symbols.sort_rounded` /
   `Symbols.link_off_rounded` / `Symbols.history_rounded` /
   `Symbols.visibility(_off)_rounded` — убедиться, что есть в
   material_symbols_icons 4.2960.0 (все — стандартные Material Symbols,
   но без SDK не верифицировать).
6. После Go codegen: заменить hand-written pb/pbgrpc/pbjson на вывод
   protoc-gen-dart и удалить HAND-WRITTEN-маркировки.

## Пропущено / сознательные упрощения

- Go-сторона `BenchmarkServers` и override-RPC — за параллельным агентом;
  интерфейс заложен по спеке, расхождений быть не должно (теги/типы полей —
  из плана).
- Скорость измеряется только по запросу (кнопка/экран), фоновых замеров нет —
  так задумано планом (экономия трафика).
- Rename не перегруппировывает same-name группы (стабильность группировки).
- Баннер watchUnstable показывается только на home-панели, не на всех экранах.
