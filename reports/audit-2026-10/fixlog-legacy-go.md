# Fix log — sora-legacy, Go-ядро (Раунд 1)

**Агент:** Go-разработчик (legacy-go). **Ветка:** `bugfix/audit-2026-10-19`.
**Дата начала:** 2026-10-19. **План:** `~/workspace/bug-hunt/reports/FIX-PLAN.md`.

Пути: `core/`, `service/`, `packaging/`, `proto/`, `docs/`. Не трогаю: `legacy/`, `app/` (другой агент).

## Прогресс

## LEGACY-H5 (P0) — done, commit fb7cf2a
- `core/engine/supervise/binary.go`: `Prober.AllowEnv` (env-override только при opt-in);
  `Discover` больше не падает в `exec.LookPath` (PATH-fallback удалён); проверка дайджеста
  кандидатов из enginesDir по манифесту `SHA256SUMS` (новый `LoadDigests`); честный комментарий
  вместо «the updater ships engines and verifies checksums».
- `core/engine/supervise/supervisor.go`: `Config.AllowEnvBin`.
- `core/engine/registry/registry.go`: копия prober'а с `AllowEnv = base.AllowEnvBin`; правка дока.
- `core/cmd/sora-core/{cli,main}.go`: флаг `--allow-env-bin`, проброс в Options/Config и в
  аргументы установки сервиса.
- `packaging/engines/fetch.sh`: пишет `SHA256SUMS` извлечённых бинарей в dest.
- `core/guard/nftables_linux.go`: `nft` резолвится в абсолютный путь (lazy, кэшируется; без nft
  ядро стартует как раньше, падает только Arm); валидация `--bypass` как CIDR/IP (часть LEGACY-L4).
- Приёмка H5: `SORA_XRAY_BIN=/tmp/evil` без флага игнорируется; PATH-бинарь больше не подхватывается.
- `go build ./...` OK, `go vet` OK, тесты supervise/registry/guard зелёные.
- Сознательно не тронут: `SafeEnv` оставлен как есть (убирать PATH рискованно для DLL-поиска
  движков на Windows без возможности протестировать).

## LEGACY-H4 (P0) — done as variant B, commit a8a556a
- Исправлена ложная документация: `core/control/auth.go` (комментарий Authenticator),
  `core/ipc/ipc.go` (package doc), `Authenticator.Token()`, `Server.Handshake` — теперь честно
  сказано, что токен не является границей безопасности против same-account процессов, реальная
  граница — allow-list транспорта.
- Вариант A (убрать токен из Handshake, выдавать только легитимному клиенту по сверке образа
  процесса) НЕ внедрён: требует согласованного изменения C#-клиента (другой агент, legacy/) и
  продуктового решения по polkit (`allow_active=yes` в service/linux/sora.policy задокументирован
  как intended — «as with the network settings of a desktop»). Зафиксировано как future work.
- `go build ./...` OK, `go vet` OK.

## LEGACY-H1 (P0) — Go/packaging part done
- Сам апдейтер движков — C# (`legacy/v2rayN/...UpdateHandle.cs`) — чужой путь, не трогаю (другой агент).
- В моих путях: `packaging/engines/fetch.sh` уже сверял SHA-256 архивов; добавлен бинарный манифест
  `SHA256SUMS` + его упаковка в `packaging/linux/nfpm.yaml` (`/usr/lib/sora/engines/SHA256SUMS`, 0644)
  + документация в `packaging/linux/README.md`. Ядро сверяет бинари по манифесту при discovery (см. H5).
- Key ceremony (подпись релизов, minisign-ключ) — за владельцем (раздел 9 плана).

## LEGACY-M1 (P1) — done as documented matrix
- Полное единое требование токена потребовало бы изменения wire-контракта (поля
  control_authenticator в ~10 сообщениях proto + регенерация + согласованное обновление
  C#/Flutter-клиентов других агентов). По H4 токен не является границей безопасности,
  поэтому в R1 зафиксирована явная матрица авторизации в коде (`Server`, server.go):
  какие методы требуют токен, какие нет и почему; известные гэпы помечены (*).
- Равномерное требование токена — отложить до скоординированного изменения контракта.

## LEGACY-M2 (P1) — done
- `checkSession` теперь отклоняет пустой session ID (InvalidArgument) и требует совпадения
  с текущей сессией; при отсутствии сессии — FailedPrecondition.
- `GetStatus`/`GetStats` намеренно lenient к пустому ID (публичный статус, опрос до подключения),
  но отклоняют неверный непустой ID.
- `WatchEvents` переведён на строгий `checkSession` (был inline-lenient).
- `runningSession` (logs.go): сначала проверка наличия сессии ("unavailable"), затем строгий checkSession.
- Обновлены тесты: e2e (session ID из Connect + проверка отказа анонимного WatchEvents),
  server_test (GetStatus с ID), logs_test (ListConnections/CloseConnection с ID).
- `go build ./...` OK, `go vet` OK, `go test ./control/` зелёный.

## LEGACY-M3 (P1) — done, commit 67f3cb4
- `Supervisor.Apply`: redactor теперь сидируется и `p.Identifiers()` (host/host:port/SNI/имена),
  а не только `p.Secrets()` — архив диагностики больше не светит серверы при `values_masked: true`.
- Регрессионный тест `TestRedactorMasksServerIdentifiers`.
- `go build` OK; `TestTunAndFakeIPAvoidLANAndEachOther` падает и на чистом дереве (окружение).

## LEGACY-M4 (P1) — done
- `secret.WriteFileAtomic` экспортирована для переиспользования.
- `Authenticator` хранит путь токен-файла; `LoadOrCreateToken` пишет атомарно;
  `Rotate()` сначала атомарно перезаписывает файл, затем меняет токен в памяти —
  рестарт больше не воскрешает скомпрометированный токен; при ошибке записи старый токен жив.
- Регрессионный тест `TestRotatePersistsToken` (ротация → "рестарт" → старый невалиден).
- `go build ./...` OK, `go vet` OK, тесты control/secret зелёные.

## LEGACY-M5 (P1) — done, commit 710d06d
- `parseJSON`/`parseYAML`: кап принятых серверов по `p.limit()` (как в parseList), избыток → Unsupported.
- `parseWG`: кап числа пиров по `p.limit()`.
- Регрессионный тест `TestLimitAppliesToEveryFormat` (json/yaml/wireguard).
- `go build` OK, `go vet` OK, тесты parser зелёные.

## LEGACY-M6 (P1) — done
- `ipc.Listener.dispatch`: дедлайн интродукции теперь реально действует — `SetReadDeadline`
  вместо `SetDeadline` + убрано преждевременное снятие; хендлер (legacycontrol) снимает его
  после успешного Handshake, как и было задумано.
- `ipc.Listener.Serve`: кап одновременных соединений (дефолт 128, настраивается через
  `Options.MaxConnections`), сверх лимита соединения закрываются сразу.
- gRPC-сервер: `keepalive.ServerParameters{MaxConnectionIdle: 5m}`.
- `go build ./...` OK, `go vet` OK, тесты ipc/legacycontrol зелёные.

## LEGACY-M6 (P1) — done, commit cadb40b — см. выше
## LEGACY-M7 (P1) — done
- `Prober.measure`: отклонение приватных/loopback/link-local целей (как `dialChecked`
  в subscription), до dial'а; без утечки адреса в ошибке.
- `probe.Config.AllowPrivate` (дефолт false) — escape hatch для тестов и LAN; продакшн
  (`main.go`) остался с дефолтом.
- Тесты: существующие переведены на `AllowPrivate: true`; новый
  `TestProbeRejectsPrivateTargets` (127.0.0.1, 169.254.169.254, 192.168.1.1, 10.0.0.1, ::1).
- `go build ./...` OK, `go vet` OK, тесты probe зелёные.

## LEGACY-M7 (P1) — done, commit d426416 — см. выше
## LEGACY-M8 (P1) — SKIP: `.github/workflows` вне моих путей (не core/service/packaging/proto/docs).
## LEGACY-L1 (P2) — done, commit 8cf7795
- Исправлены формулировки прошлых аудитов: №20 (`0660` → `0666`+`SO_PEERCRED`, core-security),
  №6 (control-surface: WatchEvents теперь строго сверяет ID — LEGACY-M2),
  №11 (core-security: redactor теперь сидируется идентификаторами — LEGACY-M3).

## LEGACY-L2 (P2) — done
- `redactorCache.put`: FIFO-вытеснение oldest вместо `clear()` всего кэша; порядок в `order`.
- При `Connect` дропаются redactor'ы всех предыдущих сессий (новый метод `sessions()`).
- `go build` OK, тесты control зелёные.

## LEGACY-L3 (P2) — done
- `Disconnect`: ID завершающейся сессии захватывается ДО вызова `sessions.Disconnect`
  (через `Current()`), redactor дропается безусловно, а не через `Status()` который может
  быть уже сброшен.

## LEGACY-L4 (P2) — done в коммите H5 (nft абсолютным путём lazy + validateBypass CIDR)
## LEGACY-L5 (P2) — done
- `defaultDataDir` теперь возвращает (dir, fromEnv); при euid==0 и env-перенаправлении
  (без явного -data-dir) env игнорируется + warning в лог; иначе warning о перенаправлении.
- CWD-дефолт убран для root: при недоступности UserConfigDir используется
  /var/lib/sora-legacy-core.
- Обновлён `legacy_test.go` под новую сигнатуру.
- `go build ./...` OK, `go vet` OK, тесты cmd/sora-core зелёные.

## LEGACY-L6 (P2) — done, commit 6d46d57
- `Fetcher.Fetch`: политика приватных хостов теперь проверяется на КАЖДОМ хопе, а не
  только при dial'е. При настроенном прокси `dialChecked` видит только адрес прокси,
  а цель уходит в CONNECT без проверки — теперь цель валидируется до запроса.
- `allowPrivate` из контекста вызова теперь уважается (явный opt-in), иначе вычисляется
  по начальному хосту как раньше.
- Новый регрессионный тест `TestFetchRejectsARedirectIntoThePrivateNetwork`.
- `go build ./...` OK, `go vet` OK, тесты subscription зелёные.

## LEGACY-L7 (P2) — не требует действий
- `diagnostics.Run` уже использует `engine.Redactor`, который кэширует `strings.Replacer`
  (`r.build`) и перестраивает только при `Add()` новых значений. Находка устарела
  (код отрефакторен после аудита). Изменений не вносил.

## LEGACY-L8..L11 (P2) — SKIP: все в `legacy/` (C#) — чужой путь.
- L11 (`--restore-proxy`, Mutex-DoS, HTTP-спидтест) — полностью C#, зафиксирован в плане.

## LEGACY-H6/H7/H8/M12/M13 (P0, newdev) — done (документ)
- Написан `docs/android-security-requirements.md`: требования к разработке Android-приложения
  (UID-авторизация, манифест, хранение токена в Keystore, канал UI↔ядро, дизайн ключей кэша)
  с критериями приёмки. Код не писался (`app/` — чужой путь, код отсутствует).

## LEGACY-H2, H3 (P0) — SKIP: оба в `legacy/` (C#) — чужой путь.
## LEGACY-M9, M10, M11 — SKIP: все в `legacy/` (C#) — чужой путь.
## Info (4 пометки) — действий по коду не требуют (по плану).
