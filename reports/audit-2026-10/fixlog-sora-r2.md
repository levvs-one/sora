# Fix log — sora, раунд 2 (верификация + добор)

Ветка: `bugfix/audit-2026-10-19` в `~/workspace/bug-hunt/sora`. Пуша нет.
Go-тулчейн: `~/workspace/go/bin/go` — `go build ./...` и `go vet` по `core/` чистые.
Flutter SDK / сборка Linux/Windows недоступны — C++/Dart вычитаны вручную.

## 1. Spot-check раунда 1: проверено 8 коммитов, ошибок не найдено

| Коммит | Что проверено | Итог |
|---|---|---|
| `e0062ec` (H8/L27/L28/L29) | `my_application.cc`: vfunc-сигнатуры `command_line`/`open`, флаги `HANDLES_COMMAND_LINE\|HANDLES_OPEN` на месте, `transfer full/none` для `fl_plugin_registry_get_registrar_for_plugin` / `g_file_get_uri*` — `g_autoptr`/`g_autofree` корректны; `dispose` чистит `deep_link_channel`/`pending_link`; `main.cpp`: мьютекс до первой попытки отправки, ретрай 40×100мс с выходом при появлении окна; `desktop.dart`: `dart:async` импортирован (`unawaited`), `exec "$2"` в кавычках, `_tell` в try/catch, дедуп `_open` 5с | OK |
| `beaa8b3` (M17/M20/L23/L24/L25) | остатков `_statsTimer` нет (`grep` — 0), `catchError` не глотает тип, очередь `_connectQueued` сбрасывается при повторном `disconnect`, throttling probe 300мс + финальный notify | OK |
| `2f39f36` (M18/M19) | `_known: Set<Int64>` синхронизирован во всех 4 путях (`_reload`/`_older`/`_arrive`/`_clear`); `desktop.navigator` — `GlobalKey<NavigatorState>`, `currentContext` валиден | OK |
| `ac8fbba` (L22/L26) | generation token `_copiedStamp`, `_pipe?.closed ?? Future.value()` | OK |
| `6b8792f` (H6) | журнал: канал больше не закрывается, `closed`-флаг под мьютексом, мьютекс держится весь цикл отправки, отправки неблокирующие | OK |
| `9da448a` (H5) | PATH-fallback удалён, `checkDigest` fail-closed, env-override только с флагом; `fromEnv` без записи в манифесте — осознанное доверие оператора, задокументировано | OK |
| `4c2bcb9` (H2) | `PeerCredentials`/`AuthLevel`, таблица `readOnlyMethods`, интерцепторы на unary+stream, Handshake выдаёт токен только `AuthControl`; unknown methods → control-only (fail closed) | OK |
| `31f9008` (H1) | `verify_signature` до сверки хэшей во всех трёх скриптах; плейсхолдер ключа — fail-closed с понятным сообщением; убран `--allow-unsigned-rpm` | OK |

Дополнительно: `go build ./...` + `go vet ./...` по `core/` — чисто.

## 2. Свежий grep-поиск: 1 новый баг (исправлен), остальное — чисто/ложные

Паттерны: `exec.Command|LookPath`, `InsecureSkipVerify` (0), `os.Getenv`, `panic(`,
`http.DefaultClient` (0), `ioutil.` (0), `TODO|FIXME|XXX|HACK` (0), `0600|0700|0777`
(только тесты/комментарии), `setState` без `mounted` (все 13 мест под guard),
`sh`/`cmd` в Go (0), `ShellExecute` в runner (0).

- **NEW-1 (найден и исправлен):** `ip` (tunroute) и `nft` (guard) исполнялись через
  PATH-резолв в демоне, который может работать как root. Подложенный раньше в PATH
  бинарник получал бы привилегии sora-core. Фикс: `NewNftables` резолвит `nft`
  в абсолютный путь при конструировании и падает fail-closed, если его нет
  (`main.go` уже fail-closed на ошибке `PlatformFirewall`); tunroute резолвит `ip`
  через новый `ipBin()` при каждом вызове (PATH может меняться; отсутствие —
  fail-closed с прежним сообщением). `TestArmRefusesRootUid` теперь подкладывает
  фейковый `nft` в PATH, чтобы не зависеть от хоста. Коммит `0b295ca`.
  Проверено: `go build`, `go vet`, `go test ./guard/... ./engine/tunroute/...` — зелёные.
- `panic("session: manager needs an engine factory")` — guard конструктора от
  nil-фабрики, не достижим из пользовательского ввода. Не баг.
- `SORA_DATA_DIR` (cli.go) — операторская переменная; L3-проверки прав
  (0600/0700, владелец==euid) делают перенаправление fail-closed. Не баг.
- `exec.LookPath("ip")` в `cleanup()` — оставлен намеренно (tolerant-ветка для
  proxy-only режима), теперь через `ipBin()` с тем же сообщением; `errors.Is(err,
  exec.ErrNotFound)` работает сквозь `%w`.

## 3. Добор пропусков раунда 1

- **SORA-L8** — `third_party/README.md` (новый): происхождение WinDivert-бlобов
  из вендорного дерева zapret (апстрим basil00/WinDivert внутри bol-van/zapret
  v72.1, LGPLv3 по шапке `windivert.h`, SHA-256 всех 6 файлов, кто их линкует —
  `nfq/Makefile` для Windows-сборки zapret). Блобы используются сборкой zapret,
  удалять нельзя — зафиксировано происхождение. Коммит `41f013a`.
- **SORA-L18** — `docs/usage.md`: новый подраздел «DNS по умолчанию» — какие
  резолверы (`https://1.1.1.1/dns-query`, `https://8.8.8.8/dns-query`), когда
  применяются (TUN-планы без своих серверов), следствие для приватности
  (метаданные у Cloudflare/Google), как переопределить (поле DNS в настройках
  подключения, форматы `https://`, `h3://`, `tls://`, `tcp://`, `quic://`, IP).
  Коммит `41f013a`.

## Итог раунда 2

- Проверено исправлений раунда 1: **8** (6 Go + 4 Dart/C++ логически; все без ошибок).
- Найдено новых багов свежим поиском: **1** (NEW-1).
- Исправлено новых: **1** (NEW-1, коммит `0b295ca`, тесты зелёные).
- Добор пропусков: **2** (L8, L18 — коммит `41f013a`).
- Осталось открытых: из скоупа sora — **0** кодовых пунктов FIX-PLAN; вне кода —
  key ceremony (H1), CI-подпись (L5), прошлые аудиты №6/№11/№20 формулировки —
  действия владельца, как и было зафиксировано в раунде 1.
