# Аналитик №11: Диагностика (core/diagnostics, redact, UI, RPC CheckDnsLeaks)

Read-only анализ ветки `bugfix/audit-2026-10-19`, репозиторий `~/workspace/bug-hunt/sora`.
H3 (неочищенный PCAPNG в ExportDiagnostics) исправлен отказом от raw-форматов — не дублирую,
копаю последствия и своё.

## Вердикт

Архитектура приватности диагностики — сильная: маскирование при записи логов, маскирование
на границе ядра, сидирование redact точными секретами плана, честный отказ от PCAPNG/EVTX,
образцовый HAR-экспорт. Но фикс H3 оставил за собой **цепочку мёртвого кода и мёртвого UI**:
меню «Packet capture» / «Windows events» в приложении обещает то, что ядро безусловно
отклоняет; ~700 строк capture-кода и 345 строк DNS-spoof-детектора недостижимы ни из одного
RPC. Плюс три пятна на честности (захардкоженная версия ядра в отчёте, `events_collected`
врёт, session ID в report.txt противоречит собственному Summary) и проверенные
ложные срабатывания/промахи паттернов redact. Итог: **приватность — отлично,
честность и минимализм — требуют добора**. Критичных утечек секретов не найдено.

## Сильные стороны

- **Маскирование на границе, а не понадежде.** `Collector.Run` маскирует каждую строку
  (`core/diagnostics/diagnostics.go:105-114`), `Export` маскирует содержимое каждого
  zip-entry при записи (`diagnostics.go:147-154`), `eventLines` маскирует события
  (`report.go:62-72`). Двойное маскирование (storage + boundary) — правильно.
- **Redact сидируется точными значениями**: `plan.Secrets()` + `plan.Identifiers()`
  (`core/control/server.go:397-404`, `core/engine/validate.go:16-80`). Общий redactor
  процесса аккумулирует секреты всех сессий (`core/cmd/sora-core/main.go:239-262`) —
  для приватности это супермножество, утечка исключена по построению.
- **H3 закрыт правильно**: отказ безусловный, а не загейченный авторизацией
  (`core/control/server.go:1291-1296`), покрыт тестом
  (`core/control/native_diagnostics_test.go`), сообщение честное.
- **Логи маскируются при записи** (`core/logs/logs.go:58`: "Message is already masked
  when it is stored"), destinations скрываются паттернами при выключенной записи
  (`core/logs/privacy.go`), длинные строки режутся по границе руны (`logs.go:144-151`).
- **HAR-экспорт — образцовый** (`app/lib/src/browser_diagnostics.dart`): значения
  query-параметров → `[redacted]`, `authorization`/`cookie`/`set-cookie` → `[redacted]`,
  тел нет вообще, userInfo вычищен, лимиты 500 записей / 2 МБ. Можно отправлять разрабу.
- **Честность DNS-проверки**: провал канарейки — это outage, а не leak
  (`core/diagnostics/dnsleak.go:188-193`); kill switch / hijack подавляют флаг корректно;
  недетектированные резолверы — `(unknown: OS resolvers not detected)`, а не гадание
  (`dnsleak.go:222-226`); зашифрованные транспорты честно не пробуются
  (`dnsleak.go:177-180`). ID чеков — стабильный контракт, label/hint — ключи локализации.
- **Архив детерминирован**: фиксированные имена и порядок entry, лимит 8 МБ с честной
  ошибкой, `values_masked` в summary, версионированный `sora-diagnostics/1`.
- **Нет авто-эксфильтрации**: экспорт сохраняет локальный файл, пользователь отправляет
  вручную (GitHub/Telegram из About). Отдельного «отправить разрабу» с риском утечки нет.

## Слоп / проблемы

### P0. Мёртвые пункты меню: UI обещает capture, ядро всегда отказывает
- `app/lib/src/ui/logs.dart:300-316` — пункты `diagnosticPackets` («Packet capture»)
  и `diagnosticEvents` («Windows events») вызывают `_diagnostic('pcapng'/'evtx')`,
  который шлёт `DiagnosticFormat_PCAPNG/EVTX` (`logs.dart:303-310`).
- `core/control/server.go:1291-1296` — любой не-UNSPECIFIED формат отклоняется
  с `INVALID_ARGUMENT`. Кнопки **всегда** заканчиваются нотификацией об ошибке.
- Тултип врёт: `diagnosticPackets: diagnosticCapture` = «Packet capture:
  Capture for 10 seconds» (`app/lib/l10n/strings_en.dart:1079,1085`) — захвата нет и не будет.
- Гейт `native-diagnostics` (`logs.dart:289`) бессмысленен: capability до сих пор
  рекламируется сервером (`core/control/server.go:101`), хотя за ней ничего нет.

### P1. Мёртвый код capture/spoof после H3 (~700 + 345 строк, ноль вызовов)
- `core/diagnostics/packets_linux.go:22` `CapturePackets` (79 строк),
  `core/diagnostics/packets_windows.go:114` `CapturePackets` (292 строки),
  `core/diagnostics/packets_other.go:13`, `core/diagnostics/events_windows.go:19`
  `ExportWindowsEvents` (56 строк), `core/diagnostics/events_other.go:12` —
  вне `_test.go` вызовов нет (проверено grep по всему дереву).
- `core/diagnostics/dnsspoof.go:133` `DetectDnsSpoof` (весь файл 345 строк) —
  вызовов нет; UI leak-тест идёт через отдельный `RunLeakTests`-стрим.
- Enum `DIAGNOSTIC_FORMAT_PCAPNG/EVTX` живёт в `proto/sora/core/v1/core_control.proto:349-353`
  и в сгенерированном коде — контракт обещает то, чего нет.
- Решение «удалить vs вернуть через redactable-путь» не принято — код висит в лимбо.

### P2. Отчёт врёт о версии ядра
- `core/diagnostics/report.go:15-16`: `const coreVersion = "0.1.0-dev"`, строка
  `core: 0.1.0-dev` (`report.go:29`) и `Core: 0.1.0-dev` в `summary.json`
  (`diagnostics.go:183`).
- Настоящая версия — ldflags-stamped `buildVersion`
  (`core/cmd/sora-core/cli.go:161-162`), отдаётся через About RPC
  (`core/cmd/sora-core/main.go:392-393`); в том же отчёте engine-строки пишут
  `contract: 1.11`. В одном файле две истории о версии. Диагностика, по которой
  нельзя понять, какой билд сломан, — не диагностика.
- Тот же `coreVersion` зашит в `packets_linux.go:44`, `packets_windows.go:238`
  (мертвый код, но симптом тот же).

### P3. `events_collected` в summary.json — это лимит, а не факт
- `core/diagnostics/diagnostics.go:196`: `Events: c.events`, где `c.events` —
  настроенный `EventCount` (дефолт 200). При 37 событиях в журнале архив заявит
  `"events_collected": 200`. Метка врёт; должно быть реальное число строк
  в `events.log`.

### P4. Session ID: report.txt включает, Summary — принципиально исключает
- `core/diagnostics/report.go:34`: `"id: " + orNone(status.SessionID)`.
- `core/diagnostics/diagnostics.go:174-178`: Summary «omits the session ID because
  it identifies a specific run without helping diagnostics».
- Противоречие внутри одного архива: либо ID помогает чинить (тогда и в summary),
  либо это идентификатор ранга приватности (тогда убрать из report.txt). Сейчас —
  ни то ни другое, а половинчатое решение с комментарием, который опровергается
  соседним файлом.

### P5. Redact: проверенные ложные срабатывания (воспроизведено исполнением)
`core/engine/redact.go:44`, `keyValuePattern`:
- `xray: token bucket filter initialized` → `xray: token [masked] filter initialized`.
  «Token bucket» — штатный термин сетевого стека (QoS/rate limiting) в логах движков;
  паттерн уродует легитимные диагностические строки.
- Проза `no secret leaked here` → `no secret [masked] here` — шум в events.log.
- `public_key = …` маскируется, хотя публичный ключ — не секрет (безвредно, но шумно;
  тест `TestAProfileHidesItsCredentials` это закрепляет как норму).

### P6. Redact: проверенный промах того же паттерна
- `pre-shared-key (hex) f00d` → `pre-shared-key [masked] f00d`: паттерн съедает `(hex)`
  как «значение», а настоящий ключ `f00d` остаётся открытым. Тот же класс:
  `password="a b"` → маскируется только `"a`, хвост `b"` утекает.
- На практике смягчается точным сидированием из `plan.Secrets()`, но паттерн заявлен
  как fallback «для неизвестных значений» (`redact.go:3-4`) — и в этой роли он
  одновременно over- и under-matches. Краевой случай: секрет, обрезанный лимитом
  `MaxMessageBytes` (`core/logs/logs.go:91-93`), перестаёт совпадать с полным сидом.

### P7. Рассинхрон таймаутов экспорта
- UI: `CallOptions(timeout: 30s)` (`app/lib/src/ui/logs.dart:311`).
- Сервер: `importTimeout = 60s` (`core/control/server.go:487`) для Run/ExportDiagnostics.
  Клиент сдаётся раньше серверного дедлайна; на медленной машине большой экспорт
  будет отменён UI, хотя ядро готово ждать вдвое дольше.

### P8. systemd-resolved: проверка сравнивает стаб, а не апстрим
- `core/diagnostics/systemdns_resolvconf.go:18-45` читает `/etc/resolv.conf`; на
  systemd-системах там `nameserver 127.0.0.53` (стаб).
- `checkSystemResolvers` (`core/diagnostics/dnsleak.go:211-244`) сравнит стаб
  с туннельными резолверами и поднимет `Leaked` с `Actual: 127.0.0.53`, а хинт
  «review system resolvers» отправит пользователя править resolv.conf, который —
  симлинк. Значения показаны честно, но вывод на типовом десктопном Linux
  вводит в заблуждение. Известное ограничение, не задокументировано.

### P9. Чего не хватает для чинки проблем (полнота)
`report.txt`/`summary.json` не содержат ничего из эффективного конфига сессии:
какой движок реально выбран (EngineLines перечисляет *доступные*, не *выбранный* —
`core/cmd/sora-core/main.go:428-445`), какой DNS-пресет действует, какой TUN-стек,
детали kill switch кроме bool. Для VPN-клиента это ровно те ответы, ради которых
открывают диагностику. `events.log` (200 событий) — единственное настоящее топливо
для дебага; `report.txt` тонок.

### P10. Мелочь: канарейка идёт мимо DNS-стека сессии
- `resolveVia` (`core/diagnostics/dnsleak.go:272-297`) открывает raw UDP-сокет
  из процесса ядра напрямую на адрес резолвера — в обход hijack-правил и DNS-стека
  сессии. Отвечает на «резолвер жив», а не строго на «туннельный DNS-путь работает».
  Сообщается честно (без флага leak при провале), но ограничение стоит зафиксировать;
  при armed kill switch канарейка всегда «unreachable» — ожидаемо, но шумно.

## Ранжированные рекомендации

1. **Убрать мёртвые пункты меню PCAPNG/EVTX** (`app/lib/src/ui/logs.dart:296-316`)
   либо вернуть функционал через redactable-путь. Промежуточное состояние —
   худшее: кнопка, которая всегда ошибается, — это слоп и ложь в UI. Заодно убрать
   `native-diagnostics` из рекламируемых capabilities (`core/control/server.go:101`)
   или привязать к нему что-то реальное.
2. **Удалить недостижимый capture/spoof-код** (`packets_*.go`, `events_*.go`,
   `dnsspoof.go` — целиком файлы, они ниоткуда не вызываются) и enum-значения
   `DIAGNOSTIC_FORMAT_PCAPNG/EVTX` из proto — либо принять решение «возвращаем»,
   но тогда с дизайном redactable-экспорта, а не висением. ~1000 строк мёртвого
   кода в security-sensitive зоне — это риск, а не запас.
3. **Пробросить настоящую версию в диагностику**: добавить `CoreVersion`
   в `diagnostics.Options`, передать `buildVersion` из `main.go:258-262`,
   использовать вместо `coreVersion = "0.1.0-dev"` (`report.go:15-16`,
   `diagnostics.go:183`). Один архив — одна правда о билде.
4. **Починить `events_collected`**: писать фактическое число строк `events.log`,
   а не лимит (`diagnostics.go:196`).
5. **Разрешить противоречие session ID**: либо убрать `id:` из `report.txt`
   (`report.go:34`), либо задокументировать, зачем он нужен, и тогда включить
   в summary. Сейчас комментарий в коде лжёт соседнему файлу.
6. **Ужесточить `keyValuePattern`** (`core/engine/redact.go:44`): требовать
   `=`/`:` как разделитель (а не пробел) — уберёт `token bucket` и прозу;
   поддерживать кавычки/скобки вокруг значения — закроет промах
   `pre-shared-key (hex) f00d` / `password="a b"`. Добавить тест на оба класса.
7. **Синхронизировать таймауты**: UI 30s vs сервер 60s (`logs.dart:311`,
   `server.go:487`) — поднять клиентский хотя бы до серверного.
8. **Задокументировать/обработать systemd-stub**: при `127.0.0.53`/`127.0.0.1`
   в system resolvers помечать проверку как inconclusive с пояснением,
   а не как leak (`dnsleak.go:211-244`).
9. **Добавить секцию `[config]` в report.txt**: выбранный движок, DNS-пресет,
   TUN-стек, режим — всё несекретное, всё уже известно UI. Это превратит архив
   из «приложение к» в самостоятельный инструмент дебага.
10. **UX перед отправкой разрабу**: показать пользователю, что именно войдёт
    в архив (хотя бы список entry + `values_masked`), прежде чем файл уйдёт
    в GitHub issue/Telegram. Сейчас `_diagnostic` пишет файл молча.

## Проверено исполнением

- Паттерны redact прогнаны на Go-реплике (`token bucket`, `pre-shared-key (hex)`,
  `spider_x:`, `vmess uuid …`): P5/P6 воспроизводятся буквально.
- Отсутствие вызовов `CapturePackets`/`ExportWindowsEvents`/`DetectDnsSpoof`
  подтверждено grep по всему дереву (только `_test.go`).
- `go test ./diagnostics/` на этой ветке **не собирается** — но не по вине
  диагностики: в `core/engine/catalog.go` (незакоммиченные чужие правки,
  `undefined: ProtocolNaive`) и `core/censor/detect.go` (`undefined: offset`)
  есть breakage от параллельной работы на общей ветке. Тесты зоны прогнать
  не удалось; findings выше — по чтению кода, не по прогону.

## Интеграция с поддержкой (ответ на вопрос зоны)

In-app «отправить разрабу» отсутствует: пользователь жмёт экспорт в LogsScreen,
сохраняет файл и вручную прикладывает к issue/Telegram (ссылки в About).
Это хорошо с точки зрения приватности (нет авто-эксфильтрации, файл можно
открыть и проверить), и содержимое безопасно: архив и логи маскированы,
HAR вычищен образцово. Не хватает только: (а) превью содержимого перед
отправкой, (б) гайда «приложите sora-log_*.zip к issue», (в) включения
результатов DNS-проверки в архив — сейчас они живут только на экране.
