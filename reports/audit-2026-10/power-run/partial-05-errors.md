# Power-run 05 — Полнота обработки ошибок

Агент №5. Ветка `bugfix/audit-2026-10-19`, без переключения и пуша.
Зона: каждый путь ошибки → честное UI-состояние, ничего не глотается молча.
Проверено: новый код волн 1–3 (F1–F11, ext) + действующий функционал.
Метод: вычитка всех `catch` в новых Dart-файлах, `unawaited`, RPC-таймауты, l10n-покрытие
ключей ошибок (скрипт по 31 локали), grep `_ =` / `panic(` / `TODO` / `//nolint` в новом
Go-коде, toWire-маппинг всех `errs.Code`, redaction в `SoraError`, Go build+vet+tests.

К каждой рекомендации применён ФИЛЬТР СЛОПА владельца: рекомендация либо «действительно
лучшее», либо честно помечена как спорная. Спорное не протаскивается молча.

## Сводка

- Проблем найдено: **9** (3 исправлено коммитом, 2 — [cross-ref] чужой зоне, 4 — наблюдения/рекомендации).
- Проглоченных ошибок (молча терялись): **3 шт.** — все исправлены (см. «Что починил»).
- Честность UI в целом: высокая. Типизированные ошибки везде (`CoreFailure`/`UpdateFailure`/
  `PackageError`/`SignatureError`/`CatalogError`/`ExtStoreError`), сырых exception-текстов
  в UI не найдено, l10n-покрытие ключей ошибок — 100% (231 геттер × 31 локаль).

### Топ-3

1. **~25 unary gRPC-вызовов без таймаута** (только connect/disconnect/handshake/logs с
   `CallOptions(timeout:)`). Зависший core → вечный спиннер без ошибки и retry.
   Фильтр слопа: править «в лоб» 25 мест — слоп; правильное решение — центральный
   механизм дефолтного таймаута с переопределениями (стримы исключить — они отменяемы
   пользователем). Dart мне read-only → рекомендация, не коммит.
2. **Core-событие `ProfileMatched` (F5) молча дропается** в `_watchSession` (обрабатываются
   только `stateChanged`/`groupSwitched`), а Dart-TODO «once the Go agent lands
   `core/profiles/profiles.go»` устарел — Go-сторона уже приземлилась. Авто-детект сети
   фактически no-op (фингерпринт всегда `unknown()`). UI честно показывает «сеть
   неизвестна», но событие ядра теряется. [cross-ref] владельцу F5.
3. **Проглоченные `savePeersLocked()` в sync-демоне (F9)** — исправлено: ошибки сохранения
   реестра пиров теперь возвращаются (`Join`/`SyncPeer`/`handlePeerDelete` отвечают
   честной 5xx/ошибкой, фоновые горутины пишут в лог демона).

## Таблица: место → ошибка → UI-исход → вердикт

| Место | Что происходит с ошибкой | UI-исход | Вердикт |
|---|---|---|---|
| `sora.dart` connect (1002–1025) | `CoreFailure.from` → `failure`, `_emit(ConnectionFailed)` / notice, retry доступен | Локализованный текст + повтор | OK |
| `sora.dart` disconnect (1068–1080) | `reportFailure(source:'disconnect')`, `_readStatus` best-effort | Нотис, состояние перечитано | OK |
| `sora.dart` kill-switch (1175–1186) | `reportFailure(source:'kill-switch')` | Нотис | OK |
| `sora.dart` probe/benchmark стримы (1330–1570) | Ошибка стрима → `reportFailure`, частичные результаты сохранены, `cancelled` отфильтрован | Честный текст + retry, прогресс сброшен | OK |
| `sora.dart` `_call` (подписки, 1294) | `CoreFailure` возвращается вызывающему, нотис | Локализованный текст | OK |
| `sora.dart` checkCrashIntent (727) | Битый JSON интента → интент очищается | Баннер не показывается, состояние честное | OK |
| `sora.dart` restoreCrashedSession (748) | Неизвестный chain → пропуск; connect-ошибки — штатным путём | Честно | OK |
| `sora.dart` watchUnstable (705–720) | 5 обрывов вотча → `app.core_watch_unstable` + кнопка repair | Видимая ошибка + ремонт, не вечный цикл | OK |
| `updates.dart` staged update (286–450) | Все сбои → типизированный `UpdateError` (6 значений); отмена ≠ ошибка; finally сбрасывает `busy/stage`, чистит workdir, снимает `resumeAfterUpdate` | Локализованный текст каждого кейса (`about.dart` покрывает все 6) + retry | OK |
| `updates.dart` обрыв mid-download/убийство app | Флаг `resumeAfterUpdate` снят в finally; workdir временный | Перезапуск — чистое состояние, без фантомного реконнекта | OK |
| `ui/connections.dart` `_read`/`_close` (1с пуллинг) | `reportFailure(source:'connections')`, дедуплика по source | Нотис один раз, список не врёт | OK |
| `ui/dns.dart` CheckDnsLeaks | `failure` в результате → `describe()` | Локализованный текст + повтор | OK |
| `ui/benchmark.dart` | Ошибки — в `sora.benchmarkServers` (см. выше) | Retry-кнопка | OK |
| `ui/chains.dart` connectChain | `reportFailure(source:'chain-connect')` + `recovered` для повтора | Нотис; повторная та же ошибка снова видна | OK |
| `ui/sync.dart` QR-спаривание | Невалидный QR → `s.qrInvalid` снекбар; дубликаты игнорируются реестром | Честно | OK |
| `ui/profiles.dart` `_refresh` | `refreshFingerprint()` сейчас не может бросить (чистый путь); `try/finally` сбрасывает спиннер | OK сегодня; хрупко, если `handleProfileMatched` оживёт (см. находку 2) | Наблюдение |
| `ext/store_screen.dart` каталог | Ошибка → `_catalogError` как флаг (сырые `'timeout'`/`'error'`/`e.message` **не** показываются) | `s.extCatalogError` + retry | OK, но причина нигде не логируется — слепое пятно для отладки |
| `ext/store_screen.dart` `_mapInstallError` | Мэппинг `PackageError.message` по подстрокам 'sha256'/'signature'/'manifest' | Локализованный текст | OK, но хрупко: зависит от английского текста внутренних сообщений |
| `ext/detail_screen.dart` `_saveSettings` | Ошибка персистентности глотается (`catch (_)` + коммент «rare and non-fatal») | **Форма молча не сохраняет настройки** — пользователь не узнает | Находка (minor) |
| `ext/panel_screen.dart` | Ошибка загрузки панели → `_failure='load'` | `s.extPanelUnavailable` | OK |
| `ext/bridge.dart` | `BridgeError(code)` → reply; неизвестное → `'internal'` | Расширение получает код, хост не падает | OK |
| `sync.dart`/`chains.dart`/`profiles.dart`/`ext/store.dart` локальные JSON-сторы | Битый JSON → старт с пустым + перезапись при след. сохранении | Молчаливая потеря пользовательских данных (профили/чейны/девайсы/реестр расширений) без нотиса | Находка (minor): честно было бы один нотис «хранилище повреждено, начато заново» |
| `core/control` → `toWire` | Все 14 `errs.Code` покрыты `wireCodes`; непокрытые → `INTERNAL`; `statusCodes` с фолбэком `Unknown` | Клиент всегда получает код из контракта | OK |
| `core/errs.From` классификация | URL-ошибки: bearer токены вырезаны; пути: без имён аккаунтов; сеть: без эндпоинтов | `DetailRedacted` не несёт секретов | OK |
| `core/control` toWire с `mask=nil` (~60 мест) | Поле называется `DetailRedacted`, но маска применяется лишь в session-путях | Утечек нет (контент санитизирован в `errs.From`; UI detail вообще не показывает), но инвариант «имя врёт» — хрупкий | Наблюдение, не чиню (маски везде = шум без реальной утечки) |
| `session/runner.go` события движка | Двойная редакция (redactor движка + redactor плана сессии) перед журналом | Секреты движков наружу не идут | OK |
| `service/sync` HTTP `writeError` | `{"error": err.Error()}` — сырые строки по локальному HTTP | Видит только локальный демон/приложение; секретов в этих строках нет (проверено) | OK |
| `sora-legacy/core` | `_ =` только на `Close()` в cleanup; `panic(` только testdata + конструкторный guard (тот же, что в sora) | — | OK |

## Проглоченные ошибки (были → исправлены)

1. `service/sync/api/daemon.go` — `_ = d.savePeersLocked()` в `upsertPeer`/`RevokePeer`:
   падение записи `peers.json` терялось молча; демон отвечал «спарено», но забывал
   устройство после рестарта. → **Исправлено**: обе функции возвращают ошибку;
   `Join`/`SyncPeer`/`handlePeerDelete` отвечают честно (502/500), фоновые горутины
   логируют (`log.Printf`, префикс `sora-sync:` уже настроен в main).
2. `core/control/plan.go` `wireguardMaterial` — `key, _ = url.PathUnescape(spec.Password)`:
   битая %-кодировка молча превращала приватный ключ в `""` → непонятный фейл на
   стороне движка. → **Исправлено**: при ошибке unescape сохраняется сырой пароль,
   движок репортит реальную проблему формата.
3. `core/ext/host.go` `WatchExtensionEvents` — `_ = g` глушил неиспользуемую переменную
   (костыль против компилятора). → **Исправлено**: `if _, err := h.check(...); err != nil`.

Остальные `_ =` в новом коде — осознанные: `Close()` в cleanup-путях, фоновые
`refresh()` подписок (ошибки идут в журнал через `notifyLocked(LevelError)` +
`LastError` в состоянии), best-effort кэш истории бенчмарков (авторитетна память,
перезапись ретраится), `os.Remove` временных файлов.

## Что починил (коммит, без пуша)

`0562a88 [power-run] error honesty: sync peer registry save errors surfaced, ext _ = g
removed, wireguard key not silently emptied` — 6 файлов:
- `service/sync/api/{daemon,pairing,syncloop,http}.go`
- `core/ext/host.go`, `core/control/plan.go`

Проверки: `go build` + `go vet` для `service/sync/...`, `core/control`, `core/ext` —
чисто; `go test ./api/...`, `./ext/...`, `./control/ -run 'TestPlan|TestWireguard|TestMaterial'` —
зелёные. `sora-legacy/core` собирается.

## [cross-ref] — чужая зона / требует решения владельца

1. **F5: `ProfileMatched` дропается; TODO устарел** (`app/lib/src/sora.dart:640-700, 882-905`).
   Ядро шлёт событие (Go-сторона приземлилась: `control/profiles.go`, `server.go:862`),
   Dart его игнорирует; `refreshFingerprint()` всегда `unknown()`. UI честен («сеть
   неизвестна»), но авто-детект не работает end-to-end. Фильтр слопа: чинить wiring —
   работа владельца F5, не мой error-path фикс.
2. **`core/cmd/sora-core` не собирается в worktree**: `control.Server` не имплементирует
   `leakv1.LeakServiceServer` (`missing method mustEmbedUnimplementedLeakServiceServer`) —
   in-flight работа параллельного swarm-агента (untracked `core/control/leak.go`,
   `core/gen/sora/leak/`, `core/leak/`). Не моя поломка, не трогаю. Родителю: пнуть
   swarm-агента добавить `leakv1.UnimplementedLeakServiceServer` в embed.
3. **`session.NewManager` паникует при nil factory** (sora и sora-legacy, `manager.go:60`).
   Сознательный fail-fast конструктора, срабатывает только на ошибку программиста при
   старте; ядро под супервизором, приложение покажет `app.core_unavailable`. Фильтр
   слопа: переделывать в `(nil, error)` ради теоретической чистоты — churn без
   выигрыша. Оставляю как есть, фиксирую решение.

## Рекомендации (не коммитил; Dart мне read-only «вычитка»)

1. **RPC-таймауты**: добавить центральный дефолтный `CallOptions(timeout:)` для unary-вызовов
   (разумно ~30с) с точечными переопределениями (connect 35с уже есть) и исключением
   стримов. Фильтр слопа: править 25 мест вручную — слоп; один choke point — лучшее решение.
2. **`ext/detail_screen.dart` `_saveSettings`**: показать нотис при ошибке сохранения
   настроек расширения (сейчас молча).
3. **Локальные JSON-сторы** (профили/чейны/девайсы/реестр расширений): при битом файле —
   один нотис «хранилище повреждено», вместо молчаливого сброса.
4. **`store_screen.dart`**: логировать реальную причину ошибки каталога (сейчас только
   флаг), чтобы было что дебажить.
