# Аудит: Go-ядро — корректность, concurrency, надёжность (этап 3/5)

**Зона:** `core/session/`, `core/routing/`, `core/diagnostics/` (diagnostics.go, report.go,
packets_linux.go, events_windows.go, events_other.go), `core/logs/`, `core/errs/`,
`core/control/plan.go`, `core/engine/plan.go`, `core/guard/`, `core/engine/tun.go`,
`core/engine/events.go`, `core/engine/backoff.go`, `core/engine/tunroute/`.
Дополнительно прочитаны для проверки контекста: `core/engine/validate.go`, `core/engine/refs.go`,
`core/engine/fields.go`, `core/cmd/sora-core/main.go` (точка конфигурации guard/diagnostics),
`core/control/server.go` (использование Journal/диагностики).

**Методология:**
- Прочитан целиком каждый файл зоны (включая тесты там, где они проясняют контракт).
- Grep-паттерны: `go func`, `make(chan`, `sync.Mutex|atomic.`, `close(`, `select`, `context.`,
  `time.After`, `defer`, `_ =`, `panic(`, `TODO|FIXME|XXX|HACK|BUG`.
- Для каждого concurrency-подозрения проверено: кто пишет/читает поле, есть ли happens-before
  (мьютекс/канал/atomic), завершается ли горутина, закрывается ли канал дважды.
- Для каждого «бага» проверен окружающий код и достижимость (кто вызывает, с какими данными).
- `go vet` / `go build` **не запускались**: в окружении нет Go-тулчейна (`go: command not found`,
  проверены `/usr/local/go/bin`, `/opt`). Все находки — результат ручного чтения кода.
- Код не изменялся, только фиксировались находки.

**Что проверено и признано корректным (ложные срабатывания отсеяны):**
- `engine.EventBus.Publish/Subscribe` (`engine/events.go:51-82`) — отправка под `b.mu`,
  отписка тоже под `b.mu` → гонки закрытия канала нет.
- `logs.Center` + `watch.go` — `notify` идёт под `c.mu`, `Close` удаляет watcher под тем же
  мьютексом → отправки в закрытый канал нет.
- `compositeGuard.Apply/Restore` (`session/guard.go`) — порядок отката и сохранение
  `active` при ошибке корректны.
- Порядок правил tunroute (`tunroute_linux.go`): `suppress_prefixlength 1` подавляет только
  маршруты с длиной префикса ≤1 (т.е. default), `127.0.0.0/8` не подавляется → loopback
  к локальным слушателям движка работает; DNS идёт в TUN раньше foreign-bypass'ов.
  Утечки DNS/IPv6 на уровне правил не найдены.
- `Backoff.Delay` (`engine/backoff.go`) — есть cap и jitter 50–100%, переполнения нет,
  `Wait` отменяется по контексту. `RestartBudget` потокобезопасен.
- `Journal.Append` — trim истории через `append(h[:0], h[n:]...)` корректен (перекрытие
  обрабатывается как memmove).
- `session.SetKillSwitch` vs `restoreGuard` vs `Stop` — порядок блокировок везде
  `guardMu → mu`, дедлоков не найдено.
- `ruleTypeOf` для IPv6/`host:port` — вход **отвергается** валидацией (`refs.go`), а не
  тихо misroute'ится (см. находку M11 — это проблема UX/валидации, не утечка).

---

## HIGH

### H1. Panic: отправка в закрытый канал журнала при гонке Append vs unsubscribe
- **Файл:** `core/session/journal.go:108-143` (`Append`), `core/session/journal.go:163-186`
  (`Subscribe` → `cancel`)
- **Категория:** concurrency / panic
- **Почему баг:** `Append` копирует список подписчиков под `j.mu`, **отпускает мьютекс** и
  затем шлёт событие в каждый канал через `select/default`. Функция отписки из `Subscribe`
  под тем же `j.mu` делает `delete(j.subs, ch); close(ch)`. Если отписка завершается между
  копированием списка и отправкой — `Append` шлёт в уже закрытый канал → **panic:
  send on closed channel**, падение всего core-процесса.
- **Достижимость:** да. `core/control/server.go:690` — `journal.Subscribe(streamBuffer)` в
  стриминге событий клиенту; отписка — при разрыве соединения клиентом. `Append` идёт
  непрерывно (счётчики каждую секунду через `supervise`, события движка). Разрыв UI
  одновременно с тиком счётчиков — штатная ситуация, рано или поздно сработает.
- **Сценарий:** пользователь закрывает приложение / рвётся IPC во время активной сессии →
  core падает → туннель и kill switch остаются в неопределённом состоянии.
- **Фикс:** не закрывать канал в `cancel` (закрытие под мьютексом + отправка под мьютексом),
  либо держать `j.mu` во время отправки, либо добавить флаг `closed` и проверять его под
  мьютексом перед отправкой. Комментарий «closes it safely on repeated calls» сейчас верен
  только для повторных вызовов, но не для конкурентного `Append`.

### H2. `Session.Stop` без таймаута: `StopGrace` объявлен, но нигде не используется
- **Файл:** `core/session/runner.go:253-295` (`Stop`), поле `Config.StopGrace` —
  `runner.go:45-46`, дефолт `runner.go:129-130`, проброс `manager.go:104`
- **Категория:** надёжность / зависание
- **Почему баг:** комментарий поля — «StopGrace bounds the engine shutdown». По факту
  `Stop` делает `stopErr := s.eng.Stop(ctx)` с **контекстом вызывающего без какого-либо
  таймаута**. Если движок подвис (мёртвый процесс, сетевой шторм на слабом ПК),
  `Stop` висит вечно → `defer m.release()` в `Manager.Connect/Disconnect` не срабатывает →
  `m.busy` остаётся `true` → **все** последующие Connect/Disconnect навсегда получают
  `core.session.busy`. Ядро заклинивает до рестарта процесса.
- **Дополнительно:** `Disconnect`/`Connect` передают пользовательский ctx; если клиент
  отменил RPC, `eng.Stop(ctx)` получает отменённый контекст и может вообще не остановить
  движок, а `restoreGuard` при этом уже снимет kill switch (`WithoutCancel`) — движок
  продолжает работать без защиты.
- **Сценарий:** обрыв сети во время остановки сессии; пользователь жмёт «отключить» —
  UI висит, повторные попытки отклоняются.
- **Фикс:** в `Stop` обернуть остановку движка в контекст с `StopGrace`
  (`context.WithTimeout(context.WithoutCancel(ctx), s.cfg.StopGrace)`), как это уже
  сделано в `engine/supervise/supervisor.go:342`.

### H3. Kill switch не блокирует root-процессы, когда core запущен от root
- **Файл:** `core/guard/nftables.go:45` (`meta skuid <uid> accept`),
  `core/cmd/sora-core/main.go:202` (`EngineUID: os.Getuid()`),
  `core/guard/nftables_linux.go:26-35`
- **Категория:** routing/firewall / утечка трафика
- **Почему баг:** исключение для движка сделано через `meta skuid <engineUID> accept`,
  а `EngineUID` — это UID самого core-процесса (`os.Getuid()`), без какого-либо
  понижения привилегий (поиск по `setuid/capabilities/drop privileges` — пусто).
  При типовом запуске от root (нужен для TUN) правило превращается в
  `meta skuid 0 accept` → **любой root-процесс** (пакетный менеджер, телеметрия,
  cron-задачи) полностью обходит kill switch. Правило стоит раньше DNS-drop и
  финального drop, т.е. обход полный, включая DNS.
- **Сценарий:** включён kill switch, туннель упал; фоновое обновление системы от root
  ходит напрямую, мимо туннеля — пользователь уверен, что «всё заблокировано».
- **Фикс:** запускать движки под выделенным непривилегированным UID и матчить его;
  либо при `uid == 0` отказываться армить с явной ошибкой/предупреждением, либо матчить
  движки по cgroup/exe вместо UID.

---

## MEDIUM

### M1. `Nftables.Arm` не идемпотентен вопреки документации; stale-таблица после краха блокирует переподключение
- **Файл:** `core/guard/nftables_linux.go:47-56` (`Arm`), `core/guard/nftables.go:22-62`
- **Почему баг:** док: «Arm installs or replaces the table, making repeated calls
  idempotent». Реализация шлёт `nft -f -` с `table inet sora { ... }` (= `add table`).
  Повторный `add table` для существующей таблицы завершается ошибкой nft
  («File exists»). Два последствия: (а) двойной `Arm` падает; (б) после краха процесса
  с заармленным свитчем таблица `sora` остаётся (nft не чистит за умершим процессом,
  в отличие от WFP), и следующий `Arm` падает → **подключиться невозможно без ручного
  `nft delete table inet sora`**. При этом трафик остаётся заблокированным (fail-closed —
  с точки зрения безопасности ок, с точки зрения восстановления — нет).
- **Сценарий:** краш core при включённом kill switch → рестарт → все Connect падают с
  `core.guard.firewall_failed`.
- **Фикс:** перед установкой делать `flush table`/`delete table` (идемпотентно) либо
  чистить stale-таблицу при старте; добавить в `Arm` обработку «already exists».

### M2. `Nftables.Disarm` падает, когда нечего снимать — нарушен контракт
- **Файл:** `core/guard/nftables_linux.go:58-67`, `80-92` (`apply`);
  контракт `Firewall.Disarm` — `core/guard/guard.go:29-31`: «It succeeds when nothing
  is armed»; док `NftRemove` (`nftables.go:68-72`): «Missing tables are treated as success»
- **Почему баг:** `apply` возвращает ошибку при **любом** ненулевом выходе `nft`, а
  `delete table inet sora` для отсутствующей таблицы — это ошибка nft
  («No such file or directory»). Тест `TestNftRemoveIsSafeToRunTwice` проверяет только
  строковый префикс и комментарий «Treat nft's missing-table error as success» описывает
  намерение, которое код не реализует. Следствие: `Guard.Restore` возвращает ошибку →
  `Session.Stop` возвращает ошибку → `Manager.Disconnect` не сбрасывает `m.current` →
  пользователь видит «не удалось отключиться», хотя отключаться было не от чего.
- **Сценарий:** двойной Disconnect, либо Disarm после ручной чистки таблицы.
- **Фикс:** в `apply`/`Disarm` игнорировать именно «table does not exist» (по тексту
  первой строки вывода, как уже сделано для `FIB table does not exist` в tunroute).

### M3. `Collector.Run` возвращает немаскированные строки вопреки документации
- **Файл:** `core/diagnostics/diagnostics.go:94-103` (`Run` — «masking each line before
  it leaves the core», но маскирования нет); `core/control/server.go:1185`
  (возвращает `lines` как есть); `core/cmd/sora-core/main.go:340-355` (`EngineLines`)
- **Почему баг:** `Export` маскирует каждую запись через `c.mask`, а `Run` — нет.
  `EngineLines()` включает `endpoint: <address>` (адрес control-endpoint) и версии
  движков; `report()` включает `id: <sessionID>` — при том что `Summary` **намеренно**
  опускает session ID («it identifies a specific run»). Сервер тоже не маскирует.
  Расхождение дока и кода + непоследовательность с `Export`/`Summary`.
- **Фикс:** применять `c.mask` к строкам в `Run` (как в `eventLines`/`Export`).

### M4. `errs.From`/`netDetail`: запрашиваемое DNS-имя утекает через `OpError`, хотя заявлено обратное
- **Файл:** `core/errs/classify.go:90-108` (`netDetail`)
- **Почему баг:** комментарий: «excluding endpoints and queried names». Но первая ветка
  `errors.As(err, &opErr)` возвращает `opErrCause{opErr.Op, opErr.Err}` без разбора
  вложенной ошибки. Типичный кейс — `&net.OpError{Op:"dial", Err: &net.DNSError{Name:
  "secret.example.com", ...}}` → `Detail()` = `dial: lookup secret.example.com: no such
  host`. Отдельная ветка для голого `*net.DNSError` ниже при обёртке в `OpError`
  недостижима. Имена резолвов попадают в детали → журнал → диагностику.
- **Фикс:** в `netDetail` сначала проверять вложенный `*net.DNSError` (рекурсивно через
  уже существующую логику), а не только голый.

### M5. `parseCredential`: ошибка JSON игнорируется → повреждённый секрет даёт пустые credentials
- **Файл:** `core/control/plan.go:48-57` (`_ = json.Unmarshal(material, &out)`)
- **Почему баг:** комментарий обещает «Invalid documents are rejected in full», но
  `_ =` превращает повреждённый документ в **пустую** карту, а не в ошибку. Outbound
  остаётся без логина/пароля, валидация плана это не ловит (credentials не валидируются),
  движок падает на подключении с неочевидной ошибкой аутентификации. Отказ тихий и
  запутывающий.
- **Фикс:** возвращать ошибку при невалидном JSON (fail-closed, как и задумано).

### M6. `tunroute.route()`: ошибка отката после частичной установки проглатывается
- **Файл:** `core/engine/tunroute/tunroute_linux.go:43-47, 88-118` (`_ = unroute(ctx)`)
- **Почему баг:** при ошибке любого `ip rule/route` шага код пытается откатить
  `unroute(ctx)`, но его ошибку отбрасывает. Если откат тоже не удался (нет `ip`,
  нет прав, гонка) — в системе остаются **частичные** правила 5333–5339: часть трафика
  идёт в TUN, часть — нет; вызывающий думает, что откат выполнен. Следующий `route()`
  начнёт с `cleanup`, но между попытками система в несогласованном состоянии.
- **Сценарий:** слабый ПК / обрыв во время применения маршрутов; повторный Connect
  может увидеть «чисто», а правила — остаться.
- **Фикс:** джойнить ошибку отката (`errors.Join`) и/или верифицировать отсутствие
  своих правил после `unroute`.

### M7. `WFP.Disarm`: при ошибке `Close` состояние всё равно сбрасывается
- **Файл:** `core/guard/firewall_windows.go:97-108`
- **Почему баг:** `err := w.session.Close(); w.session = nil` — `session` зануляется
  даже если `Close` вернул ошибку. `Armed()` после этого врёт (`false`), хотя фильтры
  WFP могут оставаться → `Guard.Restore` не будет ретраить (у него `applied` сброшен
  только при успехе, но нижележащий firewall уже «разоружён» по своему отчёту) →
  kill switch может остаться включённым навсегда или, наоборот, считаться снятым.
- **Фикс:** занулять `w.session` только при `err == nil`.

### M8. `renewConnections`: шторм полных рестартов движка при флэппинге сети, без backoff
- **Файл:** `core/session/network.go:101-124`, тик `DefaultNetworkInterval = 2s`
  (`network.go:20`), вызов из `supervise` (`runner.go:425-429`)
- **Почему баг:** при каждой смене fingerprint (а при пустом — при каждом возврате
  сети) для движков без `ConnectionTracker` (Xray) вызывается **полный**
  `s.eng.Apply(ctx, plan)` — фактически рестарт движка. Между Wi-Fi и мобильной сетью
  fingerprint осциллирует A→B→A→B → рестарт каждые 2 секунды без какого-либо backoff:
  разряд батареи, разрыв всех соединений, `EventEngineDown` → `StateReconnecting`
  по кругу. Дебаунс/гистерезис отсутствует.
- **Фикс:** дебаунс смены сети (например, требовать 2 совпадающих подряд fingerprint)
  и/или минимальный интервал между `renewConnections`.

### M9. Гонка `Start` vs `Stop`: возможен «зомби»-сессия
- **Файл:** `core/session/runner.go:187-247` (`Start`), `253-295` (`Stop`)
- **Почему баг:** `Stop` выставляет `s.stopping = true`, но `Start` этот флаг **никогда
  не проверяет** — только `state == StateDisconnected`. Сценарии: (а) `Stop` до `Start`:
  `setState(Disconnected)` отбрасывается как нелегальный переход, затем `Start`
  проходит проверку и поднимает guard+движок уже после возврата из `Stop` — сессия
  работает, владельца нет, `supervise` крутится; (б) `Stop` во время `Start`
  (guard применён, `eng.Apply` в процессе): `Stop` останавливает движок, `Start`
  продолжает и переводит состояние в `Connected` уже остановленной сессии.
  `Manager` сериализует через `busy`, но сам `Session` — публичный API без защиты.
- **Фикс:** в `Start` проверять `s.stopping` под `s.mu` после захвата блокировки и на
  ключевых точках; либо сделать `Start`/`Stop` взаимно исключающими.

### M10. `splitDNSServer` ломает IPv6-резолверы
- **Файл:** `core/control/plan.go:658-685`
- **Почему баг:** разбор `host:port` через `strings.Cut(rest, ":")` по **первому**
  двоеточию. `tls://[2001:db8::1]:853` → `head="[2001"`, `ParseUint("db8::1]:853")`
  падает → возвращается `host="[2001:db8::1]:853"`, `port=0` — мусор, который движок
  не распарсит. IPv6 DNS-серверы в плане неработоспособны.
- **Фикс:** использовать `net.SplitHostPort` с фолбэком, корректно обрабатывать
  скобочную нотацию.

### M11. `ruleTypeOf` классифицирует голый IPv6 и `host:port` как `port`-правила → валидные планы отвергаются
- **Файл:** `core/control/plan.go:599-620` (`ruleTypeOf`: любое `":"` → `RulePort`),
  `core/engine/refs.go:110-133` (`Rule.validate`: `Atoi` падает)
- **Почему баг:** `2001:db8::1` или `example.com:443` превращаются в правило типа
  `port` со значением-мусором, которое затем отвергается валидацией («not a port»).
  Пользователь не может выразить IPv6-правило без `/` и `host:port`-правило вообще.
  Тихого misroute нет (план отклоняется), но это дефект корректности построения плана.
- **Фикс:** в `ruleTypeOf` сначала пробовать `netip.ParseAddr` (→ ip-cidr/host),
  `host:port` разбирать явно.

### M12. `CapturePackets`: конкурентный `Close` во время чтения + двойное закрытие handle
- **Файл:** `core/diagnostics/packets_linux.go:17-69`
- **Почему баг:** `context.AfterFunc(capture, func() { _ = handle.Close() })` закрывает
  pcap-handle **из другой горутины**, пока основной цикл находится внутри
  `handle.ZeroCopyReadPacketData()` — нет свидетельств, что `pcapgo.EthernetHandle`
  потокобезопасен для concurrent Close/Read (data race внутри pcapgo). Плюс
  `defer handle.Close()` — второе закрытие после срабатывания AfterFunc.
- **Сценарий:** короткий `duration` + активный трафик на TUN → срабатывание таймера
  ровно во время чтения.
- **Фикс:** останавливать чтение через атомарный флаг/канал и закрывать handle только
  в одной горутине после выхода цикла.

### M13. Ошибка `eng.Stop` после провала `TunUp` игнорируется — движок может пережить неудачный старт
- **Файл:** `core/session/runner.go:216-219` (`_ = s.eng.Stop(context.WithoutCancel(ctx))`)
- **Почему баг:** если адаптер не поднялся за 5с, сессия зовёт `eng.Stop`, но ошибку
  отбрасывает. Движок, не сумевший остановиться (подвисший процесс), продолжает
  работать: его сокеты/маршруты живут, а сессия уже в `StateFailed` и менеджер
  считает, что всё остановлено. Следующий `Connect`/`route()` натыкается на
  занятые ресурсы.
- **Фикс:** логировать/джойнить ошибку в журнал и возвращать её в причине failure.

---

## LOW

### L1. Игнорируемые ошибки `eng.Close()` — возможные утечки дескрипторов
- `core/session/runner.go:286` (`_ = s.eng.Close()` в `Stop`),
  `core/session/manager.go:112,116,120,126` (`_ = built.Close()` ×4).
  `Close` освобождает ресурсы движка; молчаливый игнор прячет утечки fd/process-handle.
  Фикс: хотя бы журнал.

### L2. Захват пакетов включает IP-заголовки пользовательского трафика
- `core/diagnostics/packets_linux.go:17-35` (snaplen 256 — «keeps packet headers useful»).
  Заголовки содержат адреса назначений пользователя; package-док (`diagnostics.go:1-8`)
  заявляет «omits local addresses, hosts». Для ручного экспорта по запросу — скорее
  несогласованность документации, чем баг. Отметить в доке явно.

### L3. `interfaceUp`: `time.After` в цикле каждые 50мс
- `core/session/runner.go:77-90`. Таймеры срабатывают и подбираются GC — утечки нет,
  но правильнее один `time.NewTimer`/`NewTicker`. Косметика.

### L4. `logs.Write` режет сообщение посередине руны
- `core/logs/logs.go:~150` (`message[:MaxMessageBytes]` по байтам). Многобайтовый UTF-8
  символ на границе → невалидный UTF-8 в хранилище/экспорте. Фикс: резать по границе рун.

### L5. Неизвестные protocol/transport проходят валидацию плана
- `core/control/plan.go` (`outboundFromProto`), `core/engine/validate.go`
  (`Outbound.Validate` проверяет только `Protocol == ""`). `protocol: "foobar"` или
  `transport: "quic-goofy"` отклоняются только на `eng.Apply` — поздно, с неочевидной
  ошибкой. Фикс: whitelist на уровне плана.

### L6. `applyCredential`: битый JSON пиров WireGuard тихо даёт outbound без пиров
- `core/control/plan.go:443` (`_ = json.Unmarshal(...)`, «plan validation identifies the
  failing outbound» — но `Outbound.Validate` пиры не проверяет). Та же природа, что M5,
  тихий отказ.

### L7. Дефолтные DoH-резолверы захардкожены (Cloudflare/Google)
- `core/control/plan.go:673-674` (`defaultTunResolvers`). Для TUN-планов без явных
  резолверов DNS уходит на `1.1.1.1`/`8.8.8.8` — метаданные резолвинга у третьих лиц
  по умолчанию; там, где они заблокированы, — нет коннективити. Стоит документировать
  для пользователя.

### L8. `PrepareTun`: заданные вызывающим TUN-префиксы не проверяются на пересечение с LAN
- `core/engine/tun.go:48-70`. Проверка `Overlaps` через `chooseTunPrefix` применяется
  только к автоматически выбранным пулам; явно заданные `Tun.IPv4/IPv6` проверяются
  лишь на формат (`Is4/Bits==30/...`), но не на пересечение с существующими
  интерфейсами → возможен конфликт адресов. Сейчас `planFromProto` их не задаёт,
  риск — для будущих/внешних вызывающих.

### L9. WFP: пустой `enginesDir` → `Glob("*.exe")` в cwd
- `core/guard/firewall_windows.go:184-193`. При пустом `EnginesDir` маска применяется
  к рабочей директории и **случайные** `*.exe` получают permit по AppID (+ тот же
  аккаунт). Фикс: требовать непустой `enginesDir` или пропускать glob.

---

## ИТОГО: 25 находок (Critical: 0, High: 3, Medium: 13, Low: 9)

| # | Severity | Категория | Файл:строки | Кратко |
|---|----------|-----------|-------------|--------|
| H1 | High | concurrency/panic | `session/journal.go:108-143,163-186` | Гонка Append vs unsubscribe → send on closed channel → падение core |
| H2 | High | надёжность | `session/runner.go:253-295,45-46` | `Stop` без таймаута, `StopGrace` не используется → клин менеджера |
| H3 | High | firewall/утечка | `guard/nftables.go:45`, `cmd/sora-core/main.go:202` | `skuid 0 accept` при root → весь root-трафик мимо kill switch |
| M1 | Medium | надёжность | `guard/nftables_linux.go:47-56` | `Arm` не идемпотентен; stale-таблица после краха блокирует Connect |
| M2 | Medium | контракт | `guard/nftables_linux.go:58-92` | `Disarm` падает на отсутствующей таблице вопреки «succeeds when nothing is armed» |
| M3 | Medium | приватность | `diagnostics/diagnostics.go:94-103` | `Run` не маскирует строки вопреки доку |
| M4 | Medium | приватность | `errs/classify.go:90-108` | DNS-имя утекает в детали через `OpError(DNSError)` |
| M5 | Medium | корректность | `control/plan.go:48-57` | Игнор ошибки JSON секрета → пустые credentials |
| M6 | Medium | надёжность | `engine/tunroute/tunroute_linux.go:43-118` | `_ = unroute(ctx)` прячет провал отката частичных правил |
| M7 | Medium | состояние | `guard/firewall_windows.go:97-108` | `Disarm` сбрасывает session при ошибке `Close` |
| M8 | Medium | надёжность/батарея | `session/network.go:101-124` | Шторм рестартов движка при флэппинге сети, без backoff |
| M9 | Medium | concurrency | `session/runner.go:187-295` | `Start` не проверяет `stopping` → зомби-сессии |
| M10 | Medium | корректность | `control/plan.go:658-685` | `splitDNSServer` ломает IPv6-резолверы |
| M11 | Medium | корректность | `control/plan.go:599-620` | IPv6/`host:port` классифицируются как `port` → планы отвергаются |
| M12 | Medium | concurrency | `diagnostics/packets_linux.go:17-69` | Конкурентный `Close` во время `ZeroCopyReadPacketData` |
| M13 | Medium | надёжность | `session/runner.go:216-219` | Игнор ошибки `eng.Stop` при провале `TunUp` |
| L1–L9 | Low | разное | см. выше | Игнор `Close`, IP-заголовки в капче, `time.After` в цикле, обрезка рун, отсутствие whitelist protocol/transport, битые WG-пиры, хардкод DoH, overlap заданных TUN-префиксов, `Glob("*.exe")` при пустом `enginesDir` |

**Ограничения аудита:** `go build`/`go vet` не выполнялись — в окружении отсутствует
Go-тулчейн. Все выводы — из ручного чтения кода с проверкой достижимости по вызывающим.
Код не изменялся.
