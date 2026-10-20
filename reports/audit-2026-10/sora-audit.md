# Аудит безопасности и качества: sora (VPN/proxy-клиент)

**Дата:** 2026-10-19. **Объект:** `~/workspace/bug-hunt/sora` (открытый прокси-клиент: Flutter UI + Go-ядро
sora-core над sing-box / Xray / mihomo; платформы Windows, Linux; каталога `app/android/` в репозитории нет).
**Охват:** `core/secret`, `core/ipc`, `core/control`, `core/cmd`, `core/session`, `core/routing`,
`core/diagnostics`, `core/logs`, `core/errs`, `core/guard`, `core/parser`, `core/subscription`,
`core/probe`, `core/engine` (целиком, включая `supervise/`, `registry/`, `tunroute/`), `service/`,
`packaging/`, `proto/`, `third_party/`, `docs/`, `app/lib` (все 72 .dart-файла), `app/test`,
`app/windows`, `app/linux`, `pubspec.yaml`/`pubspec.lock`.

## Методология

Работали 5 параллельных аудиторов по зонам (секреты/IPC/привилегии; парсинг/подписки/запуск движков;
корректность/concurrency/надёжность; Dart UI; платформы/установка/обновления/supply chain) плюс
контрольная проверка координатором. Метод: сплошное чтение кода + grep по опасным паттернам
(`exec.Command`, `LookPath`, `InsecureSkipVerify`, `os.Getenv`, `panic(`, `TODO/FIXME`, права файлов,
`setState`/`mounted`/`dispose` в Dart). Каждая находка сверена с окружающим кодом и достижимостью
(кто вызывает, откуда данные); спекулятивные пункты отброшены. Ключевые High-находки перепроверены
координатором прямым чтением кода (polkit-policy, `Handshake`, `ipc.go:dispatch`, `journal.go`,
`nftables.go` + `EngineUID`, `Session.Stop`, `tunroute` + `validateDisplayName`).

Ограничения: в окружении нет Go-тулчейна (`go build`/`go vet`/`go test` не запускались) и Flutter SDK
(`flutter analyze`/тесты не прогонялись) — все выводы из статического чтения. Код не изменялся.

Детальные отчёты по зонам: `reports/partials/01-secrets-ipc-privileges.md`,
`02-parser-subscription-engine.md`, `03-correctness-concurrency.md`, `04-dart-ui.md`,
`05-platform-packaging-updates.md`.

**Проверено и признано корректным (не баги):** SSRF-защита фетчера подписок (HTTPS-only, 5 валидируемых
редиректов, `dialChecked` против DNS-rebinding, лимиты тела/таймауты); секреты движкам только через
stdin, `SafeEnv()`, home 0700; redaction логов движков; DPAPI user-scope на Windows; hardening
systemd-юнита (`User=sora`, `ProtectSystem=strict`, `NoNewPrivileges`); TOCTOU-защита `sora-update`;
`stripFiles` для Xray-профилей провайдера; `EventBus` и `logs.Center` (отправка/отписка под одним
мьютексом — гонки закрытия нет); `Backoff` с jitter и cap; отсутствие `setState`-после-`dispose` и
утечек подписок/таймеров в Dart; race-устойчивость connect/disconnect (20 тестов).

---

## HIGH

### H1. Релизные артефакты и `SHA256SUMS` не подписаны — вся цепочка доверия обновлений = TLS + хэши
**Категория:** supply chain / update integrity.
**Файлы:** `packaging/README.md:11` («Установщик и пакеты пока не подписаны»);
`.github/workflows/repository.yml:512-516` (CI: `sha256sum -- * > SHA256SUMS`, без GPG/minisign/cosign,
без attestations); `packaging/install/install.sh:84-100`, `packaging/install/install.ps1:33-42`;
`app/lib/src/updates.dart:104-109,163-196`; `packaging/linux/sora-update:43-70`; `docs/install.md:26`.
**Описание:** Все проверки целостности (`install.sh`, `install.ps1`, `sora-update`, встроенный апдейтер)
сверяют только SHA-256 с неподписанным `SHA256SUMS`, скачанным по TLS с GitHub. Критично:
`sora-update` (работает как root через pkexec) берёт `SHA256SUMS` из *записываемого пользователем*
каталога загрузки и сверяет пакеты именно с ним; `install.sh`/`sora-update` используют
`zypper --allow-unsigned-rpm`.
**Почему это баг:** хэш доказывает целостность относительно манифеста, но не аутентифицирует издателя.
Компрометация релиза (взлом аккаунта мейнтейнера, злонамеренный инсайдер, MITM с валидным сертификатом —
реалистично для VPN-клиента обхода блокировок) = перегенерация `SHA256SUMS` вместе с бэкдорными
бинарниками, и все проверки пройдут.
**Сценарий:** (а) атакующий публикует релиз с бэкдором и корректным `SHA256SUMS` — все нажавшие
«Обновить» получают бэкдор с правами администратора/root; (б) локальная малварь подменяет в каталоге
загрузки и пакеты, и `SHA256SUMS` согласованно, ждёт клика «установить обновление» и ввода админ-пароля
в pkexec-промпт → RCE как root.
**Фикс:** подписать `SHA256SUMS` офлайн-ключом (minisign), вшить публичный ключ в `install.sh` /
`install.ps1` / `updates.dart` / `sora-update` и проверять подпись *до* сверки хэшей; подписать
Windows-установщик Authenticode (`SignTool` в `sora.iss`); добавить SLSA/GH-attestations в CI;
убрать `--allow-unsigned-rpm`.

### H2. Polkit `allow_active=yes` — любой активный локальный пользователь получает полный контроль над ядром
**Категория:** IPC / authorization.
**Файлы:** `service/linux/sora.policy:22` (`<allow_active>yes</allow_active>` для
`io.github.levvs-one.sora.control`); `core/control/server.go:449-460` (`Handshake` возвращает
`s.auth.Token()` любому допущенному транспортом пиру); `core/ipc/polkit_linux.go:36-56`.
**Описание:** Любой пользователь с активной локальной сессией авторизуется polkit без пароля, проходит
`Handshake`, получает control token — и далее весь API: `Connect` с произвольным планом (подмена
серверов/маршрутизации), `SetKillSwitch`, `PutSecret`/`DeleteSecret` (перезапись/стирание секретов),
`ExportDiagnostics` с PCAPNG (см. H3), чтение bearer-ссылок подписок. Аналогия в комментарии policy
(«как сетевые настройки десктопа») неверна: NetworkManager требует `auth_admin` для системных
соединений.
**Сценарий:** shared-машина (семейный ПК, лаборатория, fast user switching): второй активный пользователь
подключается к `/run/sora/core.sock` → `Handshake` → token → `Connect` со своим планом /
`ExportDiagnostics{PCAPNG}` — перехват чужого туннеля и дамп трафика.
**Фикс:** разделить action на read-only (`allow_active=yes`: статус/статистика/события) и control
(`allow_active=auth_self`/`auth_admin`: Connect/Disconnect/SetKillSwitch/секреты/подписки/PCAPNG);
либо задокументировать как осознанный риск в `SECURITY.md`.

### H3. `ExportDiagnostics` (PCAPNG/EVTX) возвращает сырые нередкатированные данные вопреки гарантии docstring
**Категория:** privacy / information disclosure.
**Файлы:** `core/control/server.go:1192-1193` (docstring: «returns an archive built from already-redacted
core values. Clients cannot expand its contents»), `1194-1235` (реализация);
`core/diagnostics/packets_linux.go:18-50`.
**Описание:** Для `DIAGNOSTIC_FORMAT_PCAPNG` возвращается `diagnostics.CapturePackets(...)` — сырой
10-секундный захват всего TUN-трафика (заголовки целиком + до 256 байт payload на пакет: DNS-запросы,
SNI, куски plaintext-трафика) без редактуры; для `DIAGNOSTIC_FORMAT_EVTX` — сырые Windows event logs.
Код прямо противоречит собственной security-гарантии. В связке с H2 любой активный локальный
пользователь снимает 10 секунд чужого VPN-трафика.
**Сценарий:** пользователь B с активной сессией → `Handshake` → token → `ExportDiagnostics{PCAPNG}` →
pcapng с трафиком пользователя A.
**Фикс:** убрать сырые форматы из метода (оставить только редиктированный архив) либо требовать для
PCAPNG/EVTX отдельную привилегию администратора + явное подтверждение пользователя в UI; исправить
docstring.

### H4. Kill switch не блокирует root-процессы, когда core запущен от root
**Категория:** firewall / traffic leak.
**Файлы:** `core/guard/nftables.go:45` (`meta skuid <engineUID> accept`); `core/cmd/sora-core/main.go:202`
(`EngineUID: os.Getuid()`).
**Описание:** Исключение для движка сделано через `meta skuid <engineUID> accept`, а `EngineUID` — это UID
самого core-процесса без какого-либо понижения привилегий (поиск `setuid`/drop capabilities — пусто).
При типовом запуске от root (нужен для TUN) правило превращается в `meta skuid 0 accept` → **любой
root-процесс** (пакетный менеджер, телеметрия, cron) полностью обходит kill switch; правило стоит раньше
DNS-drop и финального drop, т.е. обход полный, включая DNS.
**Сценарий:** включён kill switch, туннель упал; фоновое обновление системы от root ходит напрямую мимо
туннеля — пользователь уверен, что «всё заблокировано».
**Фикс:** запускать движки под выделенным непривилегированным UID и матчить его; либо при `uid == 0`
отказываться армить с явной ошибкой/предупреждением; либо матчить движки по cgroup/exe вместо UID.

### H5. Подмена бинарника движка: PATH-fallback в discovery + мёртвый `VerifyDigest`
**Категория:** binary planting / insecure search path (CWE-426).
**Файлы:** `core/engine/supervise/binary.go:83-112` (`Discover`: env → `enginesDir` →
`exec.LookPath(pr.Name)`), `115-128` (`VerifyDigest` — ноль вызывающих в production);
`core/engine/supervise/binary.go:82` (комментарий «the updater ships engines and verifies checksums» —
вводит в заблуждение); `core/engine/registry/registry.go:69-90`.
**Описание:** Аутентификация бинарника — только `Probe()`: запуск с аргументами `version` и сверка stdout
с regexp (тривиально подделать). Если в `enginesDir` бинаря нет (свежая установка, updater ещё не
отработал), подхватывается любой `sing-box`/`xray`/`mihomo` из PATH (на десктопе каталоги вроде
`~/.local/bin` обычно user-writable). Дальше «движок» запускается с привилегиями сервиса (на Windows —
как `SoraCore` под LocalSystem, на Linux — с `CAP_NET_ADMIN`) и получает весь конфиг со всеми
credentials подписок через stdin.
**Сценарий:** локальный атакующий кладёт исполняемую `xray`-заглушку, печатающую `Xray 26.3.27`, в ранний
каталог PATH до того, как updater положит настоящий бинарь → core выполняет её как сервис → слив всех
секретов подписок + произвольный код от сервис-пользователя.
**Фикс:** убрать PATH-fallback (только `enginesDir` + явный env-override оператора); вшить ожидаемые
дайджесты из `engines.lock` в сборку ядра и вызывать `VerifyDigest` в `Discover`; исправить
вводящий в заблуждение комментарий.

### H6. Panic: гонка `Append` vs unsubscribe в журнале → send on closed channel роняет core
**Категория:** concurrency / panic.
**Файлы:** `core/session/journal.go:108-143` (`Append`: копирует подписчиков под `j.mu`, **отпускает
мьютекс**, затем шлёт через `select/default`), `163-186` (`Subscribe` → `cancel`: `delete` + `close(ch)`
под тем же `j.mu`).
**Описание:** Если отписка завершается между копированием списка и отправкой, `Append` шлёт в уже закрытый
канал — send on closed channel паникует **даже внутри `select`**, падает весь core-процесс.
**Сценарий:** `control/server.go:690` — `journal.Subscribe` в стриминге событий клиенту, отписка при разрыве
соединения; `Append` идёт непрерывно (счётчики каждую секунду). Пользователь закрывает приложение во время
активной сессии → core падает → туннель и kill switch в неопределённом состоянии.
**Фикс:** не закрывать канал в `cancel` (или закрывать и отправлять под одним мьютексом); держать `j.mu`
во время отправки; либо флаг `closed`, проверяемый под мьютексом перед отправкой.

### H7. `Session.Stop` без таймаута: `StopGrace` объявлен, но нигде не используется — клин менеджера
**Категория:** reliability / hang.
**Файлы:** `core/session/runner.go:253-295` (`Stop`: `s.eng.Stop(ctx)` с контекстом вызывающего без
таймаута), `45-46` (поле `Config.StopGrace` — «bounds the engine shutdown»), `129-130` (дефолт 3s),
`core/session/manager.go:104` (проброс).
**Описание:** Если движок подвис, `Stop` висит вечно → `defer m.release()` в `Manager` не срабатывает →
`m.busy` остаётся `true` → **все** последующие Connect/Disconnect навсегда получают
`core.session.busy`. Ядро заклинивает до рестарта. Дополнительно: `Disconnect` передаёт пользовательский
ctx; если клиент отменил RPC, движок может вообще не остановиться, а `restoreGuard` уже снимет kill
switch — движок продолжает работать без защиты.
**Сценарий:** обрыв сети во время остановки; пользователь жмёт «отключить» — UI висит, повторные попытки
отклоняются.
**Фикс:** в `Stop` обернуть остановку в `context.WithTimeout(context.WithoutCancel(ctx), s.cfg.StopGrace)`
(как уже сделано в `engine/supervise/supervisor.go:342`).

### H8. На Linux импорт-ссылки `sora://add/...` безвозвратно теряются, если приложение уже запущено
**Категория:** platform / user scenario.
**Файлы:** `app/linux/runner/my_application.cc:93-163`; для сравнения `app/windows/runner/main.cpp:25`
(`SendAppLinkToInstance`).
**Описание:** Раннер выставляет `G_APPLICATION_HANDLES_COMMAND_LINE | G_APPLICATION_HANDLES_OPEN` и
комментарий обещает форвард ссылки первому инстансу, но обработчики сигналов `command-line`/`open` у
primary-инстанса **не реализованы** — дефолтный хендлер лишь активирует окно. Второй инстанс корректно
форвардит аргументы первому, но первый их никуда не передаёт в Dart (`dart_entrypoint_arguments` только
при старте, `app_links.stringLinkStream` новых URI не получит).
**Сценарий:** Sora запущена (в трее) → клик `sora://add/https://...` в браузере/мессенджере → окно выходит
на передний план, диалог импорта не появляется, ссылка потеряна.
**Фикс:** реализовать `command_line` (и/или `open`) vfunc в `my_application.cc`, извлекать URI и
пробрасывать в Dart (через `fl_method_channel`/app_links C API, как на Windows).

---

## MEDIUM

### M1. IPC: handshake-дедлайн ставится и тут же снимается — неограниченные висячие соединения (локальный DoS)
**Файлы:** `core/ipc/ipc.go:144-147` (`dispatch`); `core/cmd/sora-core/main.go` (`grpc.NewServer` — только
лимиты размеров, своих read-дедлайнов нет).
**Описание:** `handshakeTimeout` (10s) устанавливается и синхронно снимается *до* вызова gRPC-хендлера.
Молчаливое соединение висит вечно, занимая fd и горутины; `Serve` спавнит `go l.dispatch(...)` на каждый
допущенный `Accept` без лимита.
**Сценарий:** любой допущенный транспортом пир (на Linux — любой активный локальный пользователь, сокет
0666 позволяет *подключиться* кому угодно): 1024 висячих `Dial` → `EMFILE` → `Accept` падает → процесс
завершается → systemd `Restart=on-failure` → цикл рестартов, VPN недоступен, легитимный UI не может
подключиться.
**Фикс:** не снимать дедлайн до завершения introduction (прочитать HTTP/2 preface с дедлайном); ввести
лимит одновременных соединений в `Serve` + `grpc.KeepaliveParams`/`MaxConnectionIdle`.

### M2. Инъекция аргументов в привилегированный `ip` через `Tun.DeviceName`
**Категория:** command argument injection (CWE-88).
**Файлы:** `core/engine/tunroute/tunroute_linux.go:52-84` (`routeSteps` подставляет `tun.DeviceName`),
`349-358` (`ip()`: `exec.CommandContext(ctx, "ip", strings.Fields(args)...)`);
`core/engine/fields.go:80-97` (`validateDisplayName` запрещает только управляющие символы и пробелы
по краям — **внутренние пробелы разрешены**).
**Описание:** Шелла нет (не RCE), но `ip` выполняется с привилегиями сервиса: имя `sora0 bogus`
разваливается на лишние argv-элементы, имя с ведущим `-` парсится как опция. Можно сломать установку
маршрутов (DoS туннеля) или подсунуть лишние селекторы в `ip rule/route/addr`. Источник —
`p.Tun.DeviceName`, `PrepareTun` его не валидирует вообще.
**Сценарий:** план с `tun.device_name = "sora0 xfrm"` → `ip -4 addr replace 192.0.2.1/30 dev sora0 xfrm`
→ ошибка `ip`, маршруты не встали, трафик идёт мимо туннеля.
**Фикс:** строгая валидация в `Tun.validate()`: `^[A-Za-z0-9][A-Za-z0-9_.-]{0,14}$` (IFNAMSIZ=16); строить
argv как `[]string`, а не конкатенацией строк.

### M3. Движки — сторонние сборки (включая форк), «проверка» лишь сверяет дайджест с самопубликуемым
**Категория:** supply chain.
**Файлы:** `packaging/engines/engines.lock:1-12`, `packaging/engines/fetch.sh:27-28`.
**Описание:** `sing-box` — из форка `Leadaxe/sing-box-lx` (не апстрим SagerNet), `xray` — `XTLS/Xray-core`,
`mihomo` — `MetaCubeX/mihomo`. Дайджест в lock-файле доказывает лишь, что скачанное совпадает с тем, что
лежит на GitHub у третьей стороны, а не то, что бинарь собран из заявленных исходников. Подписи апстрима
(cosign/sigstore) не проверяются; reproducible-build сверки нет. Движок видит весь трафик пользователя —
идеальное место для закладки.
**Сценарий:** компрометация релиза одного из апстримов (или бэкдор от мейнтейнера форка) → `fetch.sh`
скачает вредоносный движок, хэш совпадёт → CI упакует во все дистрибутивы.
**Фикс:** проверять подписи апстримов там, где есть; зафиксировать решение о доверии форку письменно;
в идеале — собирать движки из исходников в CI.

### M4. `Nftables.Arm` не идемпотентен вопреки документации; stale-таблица после краха блокирует переподключение
**Файлы:** `core/guard/nftables_linux.go:47-56` (`add table` падает на существующей — «File exists»);
`core/guard/nftables.go:22-62`.
**Описание:** Двойной `Arm` падает; после краха процесса с заармленным свитчем таблица `sora` остаётся
(nft не чистит за умершим процессом, в отличие от WFP), и следующий `Arm` падает → подключиться
невозможно без ручного `nft delete table inet sora` (трафик при этом заблокирован — fail-closed по
безопасности ок, по восстановлению нет).
**Сценарий:** краш core при включённом kill switch → рестарт → все Connect падают с
`core.guard.firewall_failed`.
**Фикс:** перед установкой делать `flush/delete table` идемпотентно; чистить stale-таблицу при старте.

### M5. `Nftables.Disarm` падает, когда нечего снимать — нарушен контракт
**Файлы:** `core/guard/nftables_linux.go:58-67,80-92` (`apply` возвращает ошибку при любом ненулевом выходе
`nft`; `delete table` для отсутствующей таблицы — ошибка nft); контракт `core/guard/guard.go:29-31`:
«It succeeds when nothing is armed»; док `nftables.go:68-72`: «Missing tables are treated as success»
(намерение, которое код не реализует).
**Описание:** `Guard.Restore` возвращает ошибку → `Session.Stop` возвращает ошибку → `Manager.Disconnect`
не сбрасывает `m.current` → «не удалось отключиться», хотя отключаться было не от чего.
**Сценарий:** двойной Disconnect; Disarm после ручной чистки таблицы.
**Фикс:** в `apply`/`Disarm` игнорировать именно «table does not exist» (как уже сделано для
`FIB table does not exist` в tunroute).

### M6. `Collector.Run` возвращает немаскированные строки вопреки документации
**Файлы:** `core/diagnostics/diagnostics.go:94-103` (док: «masking each line before it leaves the core» —
маскирования нет); `core/control/server.go:1185`; `core/cmd/sora-core/main.go:340-355` (`EngineLines`).
**Описание:** `Export` маскирует через `c.mask`, а `Run` — нет. `EngineLines()` включает
`endpoint: <address>`; `report()` включает `id: <sessionID>`, хотя `Summary` намеренно опускает session ID.
Непоследовательность с `Export`/`Summary` + расхождение дока и кода.
**Фикс:** применять `c.mask` к строкам в `Run`, как в `eventLines`/`Export`.

### M7. `errs.From`/`netDetail`: запрашиваемое DNS-имя утекает через `OpError`, хотя заявлено обратное
**Файлы:** `core/errs/classify.go:90-108` (`netDetail`; комментарий: «excluding endpoints and queried names»).
**Описание:** первая ветка `errors.As(err, &opErr)` возвращает `opErrCause{opErr.Op, opErr.Err}` без разбора
вложенной ошибки: `&net.OpError{Op:"dial", Err:&net.DNSError{Name:"secret.example.com"...}}` →
`Detail()` = `dial: lookup secret.example.com: no such host`. Ветка для голого `*net.DNSError` ниже при
обёртке в `OpError` недостижима. Имена резолвов попадают в журнал → диагностику.
**Фикс:** в `netDetail` сначала проверять вложенный `*net.DNSError` рекурсивно.

### M8. `parseCredential`: ошибка JSON игнорируется → повреждённый секрет даёт пустые credentials
**Файлы:** `core/control/plan.go:48-57` (`_ = json.Unmarshal(material, &out)`; комментарий обещает
«Invalid documents are rejected in full»).
**Описание:** Повреждённый документ превращается в **пустую** карту, а не в ошибку; outbound остаётся без
логина/пароля, валидация плана это не ловит, движок падает с неочевидной ошибкой аутентификации. Тихий,
запутывающий отказ.
**Фикс:** возвращать ошибку при невалидном JSON (fail-closed, как задумано).

### M9. `tunroute.route()`: ошибка отката после частичной установки проглатывается
**Файлы:** `core/engine/tunroute/tunroute_linux.go:43-47,88-118` (`_ = unroute(ctx)`).
**Описание:** Если откат тоже не удался (нет `ip`, нет прав, гонка) — в системе остаются частичные правила
5333–5339: часть трафика идёт в TUN, часть — нет; вызывающий думает, что откат выполнен. Следующий
`route()` начнёт с `cleanup`, но между попытками система несогласованна.
**Сценарий:** слабый ПК / обрыв во время применения маршрутов.
**Фикс:** джойнить ошибку отката (`errors.Join`) и/или верифицировать отсутствие своих правил после
`unroute`.

### M10. `WFP.Disarm`: при ошибке `Close` состояние всё равно сбрасывается
**Файлы:** `core/guard/firewall_windows.go:97-108` (`err := w.session.Close(); w.session = nil` —
зануляется даже при ошибке).
**Описание:** `Armed()` после этого врёт (`false`), хотя фильтры WFP могут оставаться → `Guard.Restore`
не будет ретраить → kill switch может остаться включённым навсегда или считаться снятым, хотя это не так.
**Фикс:** занулять `w.session` только при `err == nil`.

### M11. `renewConnections`: шторм полных рестартов движка при флэппинге сети, без backoff
**Файлы:** `core/session/network.go:101-124` (тик `DefaultNetworkInterval = 2s`, `network.go:20`; вызов из
`supervise`, `runner.go:425-429`).
**Описание:** При каждой смене fingerprint для движков без `ConnectionTracker` (Xray) вызывается полный
`s.eng.Apply(ctx, plan)` — фактически рестарт движка. Осцилляция A→B→A→B между Wi-Fi и мобильной сетью →
рестарт каждые 2 секунды без backoff: разряд батареи, разрыв всех соединений, цикл
`EventEngineDown` → `StateReconnecting`. Дебаунс/гистерезис отсутствует.
**Фикс:** дебаунс смены сети (2 совпадающих подряд fingerprint) и/или минимальный интервал между
`renewConnections`.

### M12. Гонка `Start` vs `Stop`: возможна «зомби»-сессия
**Файлы:** `core/session/runner.go:187-247` (`Start`), `253-295` (`Stop`).
**Описание:** `Stop` выставляет `s.stopping = true`, но `Start` этот флаг **никогда не проверяет** — только
`state == StateDisconnected`. Сценарии: (а) `Stop` до `Start`: `Start` поднимает guard+движок уже после
возврата из `Stop` — сессия работает без владельца, `supervise` крутится; (б) `Stop` во время `Start`:
`Stop` останавливает движок, `Start` продолжает и переводит состояние в `Connected` уже остановленной
сессии. `Manager` сериализует через `busy`, но сам `Session` — публичный API без защиты.
**Фикс:** в `Start` проверять `s.stopping` под `s.mu` после захвата блокировки и на ключевых точках.

### M13. `splitDNSServer` ломает IPv6-резолверы
**Файлы:** `core/control/plan.go:658-685` (разбор `host:port` через `strings.Cut(rest, ":")` по **первому**
двоеточию).
**Описание:** `tls://[2001:db8::1]:853` → `head="[2001"`, `ParseUint("db8::1]:853")` падает → возвращается
`host="[2001:db8::1]:853"`, `port=0` — мусор, который движок не распарсит. IPv6 DNS-серверы в плане
неработоспособны.
**Фикс:** `net.SplitHostPort` с фолбэком, корректная обработка скобочной нотации.

### M14. `ruleTypeOf` классифицирует голый IPv6 и `host:port` как `port`-правила → валидные планы отвергаются
**Файлы:** `core/control/plan.go:599-620` (любое `":"` → `RulePort`); `core/engine/refs.go:110-133`.
**Описание:** `2001:db8::1` или `example.com:443` превращаются в правило типа `port` со значением-мусором,
которое отвергается валидацией («not a port»). Пользователь не может выразить IPv6-правило без `/` и
`host:port`-правило вообще. Тихого misroute нет (план отклоняется), но это дефект построения плана.
**Фикс:** в `ruleTypeOf` сначала пробовать `netip.ParseAddr`, `host:port` разбирать явно.

### M15. `CapturePackets`: конкурентный `Close` во время чтения + двойное закрытие handle
**Файлы:** `core/diagnostics/packets_linux.go:17-69` (`context.AfterFunc(capture, func() { _ = handle.Close() })`
закрывает pcap-handle из другой горутины, пока основной цикл внутри `handle.ZeroCopyReadPacketData()`;
плюс `defer handle.Close()` — второе закрытие).
**Описание:** Нет свидетельств, что `pcapgo.EthernetHandle` потокобезопасен для concurrent Close/Read
(data race внутри pcapgo).
**Сценарий:** короткий `duration` + активный трафик на TUN → срабатывание таймера ровно во время чтения.
**Фикс:** останавливать чтение через атомарный флаг/канал, закрывать handle только в одной горутине после
выхода цикла.

### M16. Ошибка `eng.Stop` после провала `TunUp` игнорируется — движок может пережить неудачный старт
**Файлы:** `core/session/runner.go:216-219` (`_ = s.eng.Stop(context.WithoutCancel(ctx))`).
**Описание:** Если адаптер не поднялся за 5с, сессия зовёт `eng.Stop`, но ошибку отбрасывает. Подвисший
движок продолжает работать: сокеты/маршруты живут, а сессия уже в `StateFailed` и менеджер считает, что
всё остановлено. Следующий `Connect`/`route()` натыкается на занятые ресурсы.
**Фикс:** логировать/джойнить ошибку в журнал и возвращать её в причине failure.

### M17. Опрос `getStats` каждую секунду без единого потребителя
**Файлы:** `app/lib/src/sora.dart:249-280,341` (`Timer.periodic(1s)` → gRPC `getStats`); поля `stats`,
`speedUp`, `speedDown` нигде не читаются.
**Описание:** Вечный бесполезный IPC-трафик и пробуждения каждую секунду (батарея/CPU); при сбоях —
`reportFailure(error, source: 'stats')`, т.е. error-тосты пользователю ради данных, которые никто не
показывает.
**Сценарий:** приложение просто открыто и подключено — каждую секунду RPC в ядро.
**Фикс:** удалить опрос (или отложить до появления UI-потребителя); не вызывать `reportFailure` для
неиспользуемых данных.

### M18. Экран логов: O(n) на каждое событие при буфере до 200 000 записей — jank на медленном ПК
**Файлы:** `app/lib/src/ui/logs.dart:177-200` (`_arrive`: `_entries.indexWhere(...)` — линейный поиск,
затем `_entries.insert(0, entry)` — сдвиг до 200k элементов).
**Описание:** При «разговорчивом» ядре (десятки событий/сек) — миллионы операций в UI-изоляте на событие.
**Сценарий:** медленный ПК, debug-уровень логов, активный трафик → просадки UI при открытом экране логов.
**Фикс:** `Set`/`Map` для дедупликации за O(1); вставка без сдвига (обратный порядок + `add` в конец).

### M19. Обновление отменяется молча, если закрыть экран «О приложении» во время загрузки
**Файлы:** `app/lib/src/ui/about.dart:158`, `app/lib/src/updates.dart:369`
(`confirmDrop: () => !mounted ? Future.value(false) : confirm(...)`).
**Описание:** `install()` после завершения загрузки (таймаут до 30 минут) вызывает `confirmDrop()`,
получает `false` и делает `return` без установки `error` и без уведомления; скачанные сотни мегабайт
удалены в `finally`.
**Сценарий:** нажали «Установить обновление», ушли в другие разделы, вернулись — прогресс сброшен, никаких
объяснений.
**Фикс:** блокировать уход с экрана во время `updates.busy` либо выставлять `error`/уведомление при отмене
по `!mounted`; не захватывать `State.mounted` долгоживущим колбэком.

### M20. `probe()`: `notifyListeners()` на каждый сервер — сотни перестроений UI и трея
**Файлы:** `app/lib/src/sora.dart:942-982` (`await for`: `latency[...] = ...; notifyListeners();` на каждый
результат; `_updateTray()` → `setTooltip` на каждый чих).
**Описание:** Для подписки на сотни серверов — сотни полных перестроений (`SoraScope` слушают все экраны).
**Сценарий:** большая подписка (500+ серверов) + «проверить пинг» → видимые подтормаживания, особенно на
медленном ПК.
**Фикс:** батчить — накапливать результаты, `notifyListeners()` раз в ~200–500 мс или в конце.

---

## LOW

### L1. `Authenticator.Rotate()` не сохраняет новый токен — «инвалидированный» токен воскресает после рестарта
**Файлы:** `core/control/auth.go:108-125` (ср. `LoadOrCreateToken`, `40-70`).
**Описание:** `Rotate()` меняет токен в памяти, но не пишет в `control.token`. При следующем старте
загрузится *старый* токен. Docstring «All existing client tokens become invalid» верен только до рестарта.
Латентно (вызывающих у `Rotate` сейчас нет), но API лжёт о гарантиях. Дополнительно токен пишется
неатомарно (`os.WriteFile` напрямую, в отличие от vault/master key через `writeFileAtomic` с fsync+rename) —
обрыв записи = ядро не стартует до ручного вмешательства.
**Фикс:** в `Rotate()` атомарно перезаписывать файл токена owner-only (тем же atomic-write), либо
задокументировать session-scope ротации.

### L2. Токен-файл 0600 не защищает от процессов того же пользователя вопреки комментарию
**Файлы:** `core/control/auth.go:20-24` (комментарий: «protects the local endpoint from unauthenticated
same-account processes»); `LoadOrCreateToken`.
**Описание:** Любой процесс того же пользователя читает 0600-файл владельца — токен не является барьером
для same-user малвари; реальная граница — только cross-user. В связке с M1/H2 это усиливает риск, но само
по себе — ограничение дизайна, а не exploit.
**Фикс:** исправить комментарий под реальную threat model; рассмотреть привязку токена к peer-identity
там, где транспорт её даёт.

### L3. На Linux/macOS мастер-ключ лежит в открытом виде; комментарии утверждают несуществующие проверки прав
**Файлы:** `core/secret/key.go:28-36` (`FileProtector` — тождественные функции); `core/cmd/sora-core/platform_other.go:25-27`
(`secureDataDir` — no-op).
**Описание:** AES-256-GCM vault на этих платформах не даёт ничего сверх прав ФС; комментарий «the owning
store checks file permissions» — такой проверки в коде нет (`Open`/`loadOrCreateKey` не делают `stat`);
`os.MkdirAll(dir, 0o700)` не чинит права уже существующего каталога. При ручном запуске с ослабленными
правами ядро молча продолжит работу.
**Фикс:** при `Open` требовать `0600`/`0700` и владельца == euid (fail-closed), как Windows-вариант
`secureDataDir`.

### L4. Downgrade-защита только в UI-слое; привилегированный helper примет любую корректную версию
**Файлы:** `packaging/linux/sora-update:13` (валидация только формата `x.y.z`); `app/lib/src/updates.dart:36-40`
(`newerRelease` — единственное сравнение версий).
**Описание:** `apt-get/dnf/pacman` примут и более старый пакет. Сегодня downgrade невозможен только потому,
что единственный вызывающий проверяет `newerRelease`. Прямой вызов через `pkexec` (легитимный ручной
сценарий) откатит на уязвимую версию без предупреждений.
**Фикс:** в `sora-update` сравнивать с установленной версией и отказываться от downgrade без
`--allow-downgrade`.

### L5. Windows-установщик не подписан: нет `SignTool`, нет identity издателя
**Файлы:** `packaging/windows/sora.iss` (директива подписи отсутствует); `docs/install.md:26`;
`packaging/windows/README.md`.
**Описание:** Без Authenticode пользователь не отличит официальный билд от пересобранного с бэкдором;
SmartScreen-варнинг учит кликать «всё равно запустить». Признано авторами, не исправлено.
**Фикс:** кодовый сертификат (или Azure Trusted Signing) + `SignTool` в CI; публиковать отпечаток.

### L6. Возможный unquoted ImagePath службы Windows (несогласованность веток)
**Файлы:** `core/cmd/sora-core/service_windows.go:128` (ветка обновления квотирует через
`windows.ComposeCommandLine`) vs `:133` (создание передаёт «голый» `exe` в `mgr.CreateService`).
**Описание:** Квотирование при создании зависит от поведения `golang.org/x/sys` (проверить исходники в
окружении не удалось). Классическая unquoted-service-path проблема (`C:\Program.exe`,
`C:\Program Files\Sora.exe` → выполнение как SYSTEM). При стандартных ACL `Program Files`
практическая эксплуатируемость низкая.
**Фикс:** в обеих ветках явно задавать `config.BinaryPathName` через `ComposeCommandLine`; CI-проверка
`sc.exe qc SoraCore` на кавычки.

### L7. Секреты остаются на диске после удаления программы
**Файлы:** `docs/install.md:34`; `packaging/linux/scripts/postremove.sh` (чистит только nftables-таблицу).
**Описание:** `%ProgramData%\Sora`, `/var/lib/sora` (0700) с зашифрованными подписками/токенами переживают
удаление — неожиданно для пользователя и плохо для threat model обхода цензуры (форензика показывает
использование VPN-клиента).
**Фикс:** спросить при деинсталляции (`[UninstallDelete]` в .iss); на Linux удалять `/var/lib/sora` при
purge; предупреждать в UI деинсталлятора.

### L8. Предсобранные WinDivert-блобы в репозитории без зафиксированного происхождения
**Файлы:** `third_party/zapret/nfq/windows/windivert/libwindivert{32,64}.a`,
`third_party/zapret/nfq/windows/res/{32,64}/winicon.o`, `winmanifest.o` (в git).
**Описание:** Скомпилированные статические библиотеки без версии апстрима/хэша/способа воспроизведения.
Сейчас не используются (zapret на Windows «не встроен»), но могут быть слинкованы «как есть».
**Фикс:** зафиксировать происхождение (апстрим, версия, SHA256) либо удалить и собирать при сборке.

### L9. Неполное маскирование: REALITY-идентификаторы и схемы hysteria2/tuic/wireguard
**Файлы:** `core/engine/plan.go:65-69` (комментарий обещает маскировку `RealityPublicKey`/`ShortID`/`SpiderX`,
но `Identifiers()` их не регистрирует); `core/engine/redact.go:92-93` (`userInfoPattern` не знает схем
`hysteria2|hy2|tuic|wireguard|wg`).
**Описание:** REALITY-публичный ключ (уникален на сервер) светится в логах/диагностике вопреки
заявленному; строки логов со ссылками `hysteria2://password@host` не маскируются паттерном (точное
совпадение через `Secrets()` сработает, только если redactor знает план).
**Фикс:** добавить три поля в `Identifiers()` + ключи `publickey|shortid|spiderx` в `keyValuePattern`;
расширить альтернативу схем в `userInfoPattern`.

### L10. Метрики Xray на loopback идут через `http.DefaultClient` — уважает `HTTP_PROXY`
**Файлы:** `core/engine/xray/engine.go:141-158` (`readVars`: `http.DefaultClient.Do` к
`http://127.0.0.1:PORT/debug/vars`).
**Описание:** `http.DefaultTransport` использует `ProxyFromEnvironment`; исключение «без прокси» в Go —
только для хоста `localhost`, не `127.0.0.1`. При установленном `HTTP_PROXY` внутренние метрики
(счётчики трафика, задержки) уйдут на прокси; при отказе прокси readiness-handshake ложно падает.
**Фикс:** свой `http.Client` с `Proxy: nil` для loopback-метрик.

### L11. SSRF-сторож `allowPrivate` зависит от DNS-ответа атакующего на исходный хост
**Файлы:** `core/subscription/subscription.go:137,300-341`.
**Описание:** `allowPrivate` вычисляется один раз через системный DNS по исходному хостнейму подписки. Если
атакующий контролирует DNS этого имени и вернёт приватный IP, `dialChecked` разрешит dial на приватные
адреса. Практическая эксплуатация узкая (тело уходит в парсер, прямой эксфильтрации нет), основная защита
(redirect→private при публичном исходном хосте) корректна.
**Фикс (defense in depth):** сузить `allowPrivate=true` до «исходный хост — IP-литерал из приватного
диапазона или localhost», а не «так сказал DNS».

### L12. `StableKey` включает UUID-credential в хэш идентичности
**Файлы:** `core/parser/parser.go:207-222` (комментарий: «Exclude passwords from identity», но `material`
включает `o.UUID`, а для VLESS/VMess/TUIC UUID и есть пароль).
**Описание:** Выход — 64-битный усечённый sha256 (необратим, для дедупликации); риск — подтверждение
угаданного UUID по совпадению ключа + расхождение с заявленным намерением.
**Фикс:** документировать осознанность либо строить ключ без UUID.

### L13–L21. Прочие Low (ядро)
- **Игнорируемые ошибки `eng.Close()`** — возможные утечки дескрипторов: `core/session/runner.go:286`,
  `core/session/manager.go:112,116,120,126`. Фикс: хотя бы журнал.
- **Захват пакетов включает IP-заголовки пользовательского трафика**: `core/diagnostics/packets_linux.go:17-35`
  (snaplen 256) vs package-док «omits local addresses, hosts» — несогласованность документации.
- **`logs.Write` режет сообщение посередине руны**: `core/logs/logs.go` (`message[:MaxMessageBytes]` по
  байтам → невалидный UTF-8). Фикс: резать по границе рун.
- **Неизвестные protocol/transport проходят валидацию плана**: `core/control/plan.go`
  (`outboundFromProto`), `core/engine/validate.go` — `protocol: "foobar"` отклоняется только на
  `eng.Apply`, поздно и неочевидно. Фикс: whitelist на уровне плана.
- **Битый JSON пиров WireGuard тихо даёт outbound без пиров**: `core/control/plan.go:443`
  (`_ = json.Unmarshal(...)`). Фикс: fail-closed.
- **Дефолтные DoH-резолверы захардкожены** (Cloudflare/Google): `core/control/plan.go:673-674` —
  метаданные резолвинга у третьих лиц по умолчанию; там, где заблокированы, — нет коннективити.
  Фикс: документировать для пользователя.
- **`PrepareTun`: заданные вызывающим TUN-префиксы не проверяются на пересечение с LAN**:
  `core/engine/tun.go:48-70` (проверка `Overlaps` только для автопула). Риск для будущих вызывающих.
- **WFP: пустой `enginesDir` → `Glob("*.exe")` в cwd**: `core/guard/firewall_windows.go:184-193` —
  случайные `*.exe` получают permit по AppID. Фикс: требовать непустой `enginesDir`.
- **`interfaceUp`: `time.After` в цикле каждые 50мс**: `core/session/runner.go:77-90` — косметика, один
  `time.NewTimer`/`NewTicker`.

### L22–L29. Прочие Low (Dart UI)
- **Гонка сброса индикатора «скопировано»**: `app/lib/src/ui/settings_screen.dart:160-167` — два быстрых
  тапа, первый таймер гасит индикатор второго. Фикс: токен-поколение.
- **Тихий no-op «повторить подключение» из уведомления при недоступном ядре**:
  `app/lib/src/sora.dart:611-614` (`connect()` при `_link == null` — просто `return`). Фикс: выставлять
  `failure = CoreFailure.unavailable` + тост.
- **Тапы по орбу во время `Phase.disconnecting` проглатываются**: `app/lib/src/sora.dart` (`toggle()` без
  ветки) — ставить в очередь `connect()` после завершения disconnect.
- **Отравление цепочки `_historyWork` при ошибке записи истории**: `app/lib/src/sora.dart:163`
  (`.then(...)` без `catchError` — одна ошибка ломает все последующие сохранения). Фикс: `catchError`.
- **`PipeConnector.done` — force-unwrap `_pipe!`**: `app/lib/src/core/pipe.dart:37` — `StateError`, если
  gRPC прочитает `done` до `connect()`. Фикс: `_pipe?.closed ?? Future.value()`.
- **Необработанные ошибки системных уведомлений**: `app/lib/src/desktop/desktop.dart:462,475,129`
  (`unawaited(_tell(...))` без try/catch). Фикс: try/catch внутри `_tell`.
- **`restartAfterUpdate` захардкожен на `/usr/bin/sora`**: `app/lib/src/desktop/desktop.dart` — для
  неупакованных установок рестарт запустит не тот бинарь. Фикс: `Platform.resolvedExecutable`.
- **Windows: второй инстанс молча выходит, если окно первого ещё не создано**:
  `app/windows/runner/main.cpp:31-38` (`FindWindowW` → нет окна → выход; ссылка/показ окна теряются).
  Фикс: ждать/ретраить `FindWindowW` несколько секунд.

---

## Сводная таблица

| Severity | Количество |
|----------|-----------|
| Critical | 0 |
| High | 8 |
| Medium | 20 |
| Low | 29 |
| **Итого** | **57** |

Распределение по зонам (находок): IPC/секреты/привилегии — 6 (2H/1M/3L); парсинг/подписки/движки —
8 (1H/1M/6L); корректность/concurrency — 25 (3H/13M/9L); Dart UI — 13 (1H/4M/8L);
платформы/обновления/supply chain — 7 (1H/1M/5L). Две дублирующиеся находки из зон объединены
(неподписанные обновления — в H1; мёртвый `VerifyDigest` + PATH-fallback — в H5); два пункта
неполного маскирования объединены в L9.

## Топ-5 самых критичных

1. **H1 — неподписанные релизные артефакты.** Вся защита обновлений сводится к TLS + самопубликуемым
   хэшам. Компрометация релиза = тихий бэкдор с правами root/администратора всем пользователям сразу.
   Для VPN-клиента обхода блокировок это главный вектор массовой компрометации.
2. **H2 — polkit `allow_active=yes`.** Любой активный локальный пользователь без пароля получает полный
   контроль над ядром: подмена туннеля, стирание секретов, сырой дамп чужого трафика (H3). Shared-машины
   полностью открыты.
3. **H4 — kill switch не блокирует root-трафик.** При запуске от root (типовой сценарий для TUN) правило
   `meta skuid 0 accept` пропускает мимо kill switch весь root-трафик, включая DNS. Пользователь уверен,
   что «всё заблокировано», — а фоновые системные процессы ходят напрямую. Тихая утечка трафика.
4. **H5 — подмена бинарника движка через PATH.** Ядро исполняет первый подошедший `sing-box`/`xray`/`mihomo`
   из PATH по одной лишь строке `version`, с привилегиями сервиса и всеми credentials подписок через stdin;
   `VerifyDigest` — мёртвый код вопреки комментарию.
5. **H6 — panic в журнале событий.** Гонка `Append` vs отписка → send on closed channel → падение всего
   core-процесса из штатной ситуации (закрытие UI во время сессии). Туннель и kill switch остаются в
   неопределённом состоянии.

За топ-5, также High: H3 (сырой PCAPNG вопреки гарантии «already-redacted» — межпользовательская утечка
трафика), H7 (клин менеджера при зависшем движке — DoS самого VPN), H8 (потеря sora://-ссылок на Linux).
