# Аудит безопасности и качества: sora-legacy

**Дата:** 19.10.2026. **Область:** весь репозиторий `sora-legacy` (ветка `legacy`):
Go-ядро `core/` (control, ipc, secret, session, engine/supervise, guard, subscription,
parser, routing, probe, diagnostics, legacycontrol, logs, cmd),
C#-клиенты `legacy/v2rayN` (форк v2rayN), `legacy/Client`, `legacy/Control`,
`legacy/build`, `legacy/installer`, `service/`, `packaging/`, `proto/`, `app/`.

## Методология

Аудит выполнен пятью параллельными потоками: координатор (Go-ядро: control plane,
IPC, секреты, сессии, супервизор движков, guard, CLI) + четыре специализированных
субагента (C#/WinForms-клиент; мобильный `app/`; service/packaging/installer/CI;
парсеры/подписки/routing/probe/diagnostics + верификация прошлых аудитов).

Метод: построчное чтение ключевых файлов, `grep` по опасным паттернам
(`exec.Command`, `Process.Start`, `UseShellExecute`, `InsecureSkipVerify`,
`unsafe`, `TODO/FIXME`, `http.Get`, `panic(`, `SetDeadline`), трассировка
потоков данных (токен → Handshake, секреты → маскировщик → архив диагностики,
env → discovery движков), проверка каждого прошлого пункта аудитов
`docs/audits/2026-10-02-*.md` по коду. Каждая находка подтверждена чтением
окружающего кода; неподтверждённое отброшено. Сборка/тесты не запускались
(Go-тулчейна на машине нет; тесты — в CI, как отмечено в прошлом аудите).

**Архитектурный контекст.** sora-legacy — предыдущее поколение: привилегированное
ядро (`sora-core`, Go) + IPC (Unix socket / Windows named pipe) + толстые клиенты
(C# WinForms). По сравнению с «современным» подходом (тот же репозиторий
фактически и есть modern core — ветка legacy его продолжает) унаследованные
проблемы: доверие локальному пользователю (polkit `allow_active=yes`, Windows
active-session), токен как «мягкая» аутентификация поверх транспорта, запуск
сторонних бинарей движков дочерними процессами, per-user установка Windows-клиента.

---

## Находки

### HIGH

#### H-1. Обновление движков без проверки подписи/хэша — подмена xray.exe → RCE
- **Категория:** безопасность / supply-chain. **Файлы:**
  `legacy/v2rayN/v2rayN/Handler/UpdateHandle.cs:120-168` (`CheckUpdateCore`),
  `:496-567` (`responseHandler`), `Handler/DownloadHandle.cs:105-148`,
  `Forms/MainForm.cs:1463-1490`, `Tool/FileManager.cs:71` (`ZipExtractToFile`).
- **Описание:** цепочка обновления ядра: JSON релизов с `api.github.com` →
  `TagName` подставляется в URL → скачивание zip → `ZipExtractToFile` поверх
  `xray.exe` → `LoadV2ray()` немедленно запускает скачанный бинарник. Нигде нет
  проверки SHA-256/подписи (grep `verifysignature/checksum/hash` пуст). То же для
  `UpdateGeoFile` (`:347-395`): `geoip.dat`/`geosite.dat` без верификации.
  Запрета downgrade нет — только сравнение `curVersion == version`.
- **Сценарий:** компрометация релиза любого движка на GitHub (Xray/sing-box/mihomo)
  или MITM с валидным сертификатом → пользователю предлагается «обновление» →
  скачанный бэкдор запускается приложением. Подмена geo-файлов → манипуляция
  маршрутизацией.
- **Фикс:** сверять SHA-256 ассетов (как уже делает `packaging/engines/fetch.sh`
  через `engines.lock` и `build/Stage-Release.ps1` через `Assert-Sha256`) или
  Authenticode-подпись до распаковки; запретить downgrade; скачивать во временное
  имя + атомарный `File.Move`.

#### H-2. Local privesc: user-writable каталог + runas-рестарт TUN без проверки целостности
- **Категория:** безопасность / повышение привилегий. **Файлы:**
  `legacy/v2rayN/v2rayN/Forms/MainForm.Community.cs:868-891`
  (`RestartCommunityAsAdministrator`),
  `legacy/v2rayN/v2rayN/Tool/TunModeController.cs:17-90` (`Start`),
  `legacy/installer/Sora.iss` (`DefaultDirName={localappdata}\Programs\Sora`,
  `PrivilegesRequired=lowest`).
- **Описание:** установщик per-user, весь каталог перезаписываем процессами того
  же пользователя. Для TUN приложение перезапускает себя с `Verb="runas"` и
  из-под администратора запускает `tun2proxy\tun2proxy-bin.exe`,
  `xray.exe`, `sysproxy.exe` (абсолютные пути, `UseShellExecute=false` —
  PATH-hijack нет, но проверки хэша/подписи компонентов в рантайме нет; хэши
  считаются только для отображения в диагностике).
- **Сценарий:** малварь того же пользователя подменяет `tun2proxy-bin.exe` /
  `wintun.dll` / `xray.exe`; пользователь включает TUN, подтверждает UAC →
  planted-бинарник выполняется как администратор.
- **Фикс:** установка в Program Files (elevation при установке) либо сверка
  SHA-256/Authenticode перед elevated-запуском; вынести TUN-setup в отдельный
  минимальный хелпер вместо подъёма всего GUI.

#### H-3. Кнопка «Edit» кастомного сервера выполняет произвольные файлы
- **Категория:** безопасность / пользовательский сценарий. **Файлы:**
  `legacy/v2rayN/v2rayN/Forms/AddServer2Form.cs:109-153`
  (`btnBrowse_Click`, `btnEdit_Click`),
  `legacy/v2rayN/v2rayN/Handler/ConfigHandler.cs:467-505` (`AddCustomServer`).
- **Описание:** `btnBrowse_Click` (`OpenFileDialog`, фильтр `All|*.*`) позволяет
  выбрать любой файл; `AddCustomServer` копирует его в `guiConfigs\<GUID>.<ext>`
  (расширение не валидируется) и сохраняет `address = "<GUID>.exe"`.
  `btnEdit_Click` делает `Process.Start(Utils.GetConfigPath(txtAddress.Text))`;
  проект `net48`, `Process.Start(string)` по умолчанию `UseShellExecute=true` →
  для `.exe`/`.bat`/`.ps1`/`.msi` это выполнение, а не открытие в редакторе.
- **Сценарий (социнженерия):** жертве присылают «конфиг бесплатного VPN» —
  переименованный exe; импорт как custom-сервер + кнопка Edit → выполнение кода.
- **Фикс:** whitelist расширений (`.json/.yaml/.yml`); открывать через явный
  `notepad.exe` с `UseShellExecute=false`; валидировать `address` от
  `..`/абсолютных путей при загрузке.

#### H-4. Handshake отдаёт control-токен любому допущенному транспортом пиру
- **Категория:** безопасность / аутентификация. **Файлы:**
  `core/control/server.go:449-459`
  (`return &corev1.HandshakeResponse{..., ControlAuthenticator: s.auth.Token()}`),
  `core/control/auth.go:20-22,96-101`.
- **Описание:** `Handshake` не требует токена (by design) и возвращает
  `s.auth.Token()` каждому, кого пропустил транспорт. Документация `auth.go`
  заявляет: «The OS-generated token protects the local endpoint from
  unauthenticated same-account processes and stale clients» — это неверно:
  любой same-account процесс свободно получает токен через Handshake. Реальная
  граница — только allow-list транспорта. Следствие: токен не добавляет защиты
  ни от кого, кого допускает транспорт (любой активный локальный пользователь
  через polkit, любой процесс той же учётки).
- **Сценарий:** малварь того же пользователя (или второй пользователь активной
  сессии): `Handshake` → токен → `Connect` с произвольным планом, `PutSecret`,
  `FetchSubscription`, `SetKillSwitch`, `Disconnect` чужой сессии → перехват
  трафика жертвы / снятие kill switch / DoS туннеля.
- **Фикс:** либо убрать токен из Handshake и выдавать его только легитимному
  клиенту (сверка образа процесса, как `VerifyService` в C#), либо честно
  задокументировать, что токен — лишь защита от устаревших/случайных клиентов,
  а не граница безопасности, и усилить транспорт (убрать `allow_active=yes`).

#### H-5. Discovery движков доверяет env-переменным и PATH без проверки digest
- **Категория:** безопасность / выполнение кода. **Файлы:**
  `core/engine/supervise/binary.go:81-112` (`Discover`),
  `core/engine/singbox/engine.go:28`, `core/engine/xray/engine.go:33`,
  `core/engine/mihomo/engine.go:28` (`SORA_*_BIN`).
- **Описание:** порядок кандидатов: `$SORA_SINGBOX_BIN` / `$SORA_XRAY_BIN` /
  `$SORA_MIHOMO_BIN` → `enginesDir` → `exec.LookPath` (PATH). «Проверкой»
  является лишь regex по выводу `version` — тривиально подделывается
  (`#!/bin/sh\necho "Xray 1.2.3 (go1.2 linux/amd64)"`). `VerifyDigest`
  (`binary.go:115-130`) существует, но **нигде не вызывается** в прод-коде
  (комментарий «the updater ships engines and verifies checksums» — updater'а,
  который бы это делал, в цепочке нет). `nft` в `core/guard/nftables_linux.go:81`
  также резолвится через PATH; `SafeEnv` (`host.go:87-96`) прокидывает PATH
  дочерним движкам.
- **Сценарий:** процесс, способный влиять на окружение ядра (переменная
  `SORA_LEGACY_DATA_DIR`/`SORA_XRAY_BIN` через `HKCU\Environment` для
  user-запускаемого ядра, наследование env GUI-клиентом, грязный PATH при
  ручном запуске) → произвольный бинарь выполняется от учётки сервиса
  (`sora`, с `CAP_NET_ADMIN`) или SYSTEM. В systemd-юните окружение чистое —
  риск реализуется при не-юнит запусках.
- **Фикс:** вызывать `VerifyDigest` для всех кандидатов кроме enginesDir из
  пакета (или для всех, со списком из `packaging/engines/engines.lock`);
  env-override — только при явном флаге `--allow-env-bin`; `nft` — абсолютным
  путём; не прокидывать PATH в `SafeEnv` без необходимости.

#### H-6. Android: UID-авторизация команд туннеля существует только в README
- **Категория:** безопасность / архитектура (код отсутствует).
  **Файл:** `app/android/tunnel/README.md:15`.
- **Описание:** README декларирует «Команды принимаются только от приложения Sora
  того же UID», но `app/android/tunnel/` содержит только README — ни
  `SoraVpnService`, ни `AndroidManifest.xml` не написаны. Grep подтверждает:
  прикладного кода в `app/` нет (только сгенерированный protobuf-Dart).
- **Сценарий:** при появлении сервиса без проверки любое стороннее приложение
  сможет слать intent-команды на запуск/остановку/перенастройку VPN
  (intent hijacking, принудительный disconnect → деанонимизация).
- **Фикс:** в `onBind()`/`onStartCommand()` проверять
  `Binder.getCallingUid() == Process.myUid()`; только explicit intent'ы;
  signature-level permission; `android:exported=false` по умолчанию.

#### H-7. Android: манифест отсутствует — exported/backup/cleartext неверифицируемы
- **Категория:** безопасность / архитектура. **Файлы:** `app/` (манифеста нет —
  подтверждено `find`).
- **Описание:** невозможно проверить `android:exported`, `android:allowBackup`
  (дефолт `true` → выгрузка секретов в облачный бэкап), `usesCleartextTraffic`,
  `networkSecurityConfig`.
- **Фикс:** при создании манифеста: `allowBackup="false"`, `exported="false"`
  по умолчанию, `networkSecurityConfig` с запретом cleartext, `dataExtractionRules`.

#### H-8. Android: хранение `controlAuthenticator` не определено
- **Категория:** безопасность / архитектура.
  **Файлы:** `app/lib/src/generated/sora/core/v1/core_control.pb.dart:4177-4182`,
  `app/README.md:12` (план `lib/src/store` — не реализован).
- **Описание:** контракт несёт bearer-токен с полным контролем над ядром
  (Connect/Disconnect/SetKillSwitch/PutSecret). Хранилище не реализовано;
  сохранение в SharedPreferences/файл = компрометация токена через бэкап/root.
- **Фикс:** только Android Keystore-backed `EncryptedSharedPreferences` /
  `flutter_secure_storage`; не логировать; занулять в памяти.

### MEDIUM

#### M-1. Несогласованная авторизация методов control plane
- **Категория:** безопасность / авторизация. **Файлы:** `core/control/server.go`
  (Connect:470, Disconnect:509 — токен есть), `core/control/logs.go`
  (`ClearLogs`, `SetLogSettings`, `ListConnections` — токен есть),
  `core/control/subscriptions.go:614-674` (Save/List/Delete/Refresh — токен есть)
  **против**: `ParseImport` (:822), `PutSecret` (:914), `DeleteSecret` (:935),
  `FetchSubscription` (:955), `ProbeServers` (:1008), `WatchEvents` (:636),
  `RunDiagnostics` (:1170), `ExportDiagnostics` (:1194, default-формат) —
  токена **нет**, только версия.
- **Описание:** запись секретов (`PutSecret`), загрузка подписок с bearer-токенами
  (`FetchSubscription`), чтение архива диагностики и потока событий доступны
  любому допущенному транспортом пиру, тогда как куда менее чувствительные
  `ListConnections`/`ClearLogs` требуют токен. В сочетании с H-4 (токен получается
  через Handshake) модель «токен защищает» не работает вообще.
- **Сценарий:** любой активный локальный пользователь (polkit) или same-account
  процесс: `PutSecret` → `FetchSubscription` (SSRF от учётки сервиса, см. M-7),
  чтение чужого `ExportDiagnostics`/`WatchEvents`.
- **Фикс:** единый порог: мутирующие и приватные методы — только с токеном;
  либо задокументировать, что авторизация = транспорт, и убрать токен как
  класс (см. H-4).

#### M-2. Пустой session ID обходит проверку сессии (аудит №6 заявлял обратное)
- **Категория:** безопасность / авторизация. **Файлы:**
  `core/control/server.go:561-572` (`checkSession`: `if wanted == "" { return nil }`),
  `:636-660` (`WatchEvents`), `:1170-1193` (`RunDiagnostics`),
  `:1194-1251` (`ExportDiagnostics`).
- **Описание:** прошлый аудит (control-surface №6) заявлял: «клиент не может
  увидеть чужой журнал — WatchEvents сверяет идентификатор сессии». Проверка
  сверяет ID **только если он непустой**; пустой session ID смотрит/читает/
  экспортирует **текущую** сессию без токена. То же для `RunDiagnostics` и
  дефолтного `ExportDiagnostics`.
- **Сценарий:** второй активный пользователь (polkit `allow_active=yes`) читает
  поток событий, отчёт и архив диагностики чужой VPN-сессии без аутентификации.
- **Фикс:** требовать непустой session ID, равный текущей сессии, для всех
  приватных методов; или требовать токен (см. M-1).

#### M-3. Идентификаторы серверов (host/host:port) не маскируются в архиве диагностики
- **Категория:** безопасность / приватность. **Файлы:**
  `core/engine/supervise/supervisor.go:304`
  (`s.redactor.Add(p.Secrets()...)` — без `Identifiers()`),
  `core/cmd/sora-core/main.go:218,230` (общий redactor для сессии и коллектора),
  `core/diagnostics/diagnostics.go:104-130`, `core/engine/redact.go`
  (паттерны: UUID, key=value, userinfo — но не bare host/IP).
- **Описание:** прошлый аудит (core-security №11) заявлял, что «control plane
  засевает маскировщик и секретами, и идентификаторами» и что тест «проверяет
  каждую запись архива». Проверка: идентификаторы сеются только в **per-plan**
  redactor control plane (`server.go:345`), который используется для
  WatchEvents/GetStats/ProbeServers. Общий redactor (движок → log center →
  архив `ExportDiagnostics`) получает только `Secrets()`. Строки логов движков
  (`dial tcp 203.0.113.5:443` и т.п.) попадают в архив с немаскированными
  IP/hostname. Заявленный регрессионный тест в коде не найден.
  `summary.json` при этом честно пишет `"values_masked": true`.
- **Сценарий:** пользователь публикует «безопасный» диагностический архив на
  форуме/в issue → IP/hostname его VPN-серверов раскрыты. Любой допущенный пир
  (см. M-2) скачивает архив без токена.
- **Фикс:** в `Supervisor.Apply` добавить `p.Identifiers()` в общий redactor;
  добавить регрессионный тест, сажающий имя сервера в engine-лог и проверяющий
  архив; исправить формулировку прошлого аудита.

#### M-4. `Rotate()` не персистит токен — рестарт воскрешает скомпрометированный токен
- **Категория:** безопасность. **Файл:** `core/control/auth.go:110-123`.
- **Описание:** `Rotate()` меняет токен только в памяти; файл `control.token`
  хранит старый. После рестарта ядра валиден снова старый токен. Если ротация
  была реакцией на компрометацию — она откатывается рестартом. Побочно: клиенты,
  прочитавшие файл после ротации, получают уже невалидный токен (DoS новых
  клиентов до рестарта).
- **Фикс:** атомарно перезаписывать файл при ротации (`writeFileAtomic` уже есть).

#### M-5. Парсер: `MaxItems` не применяется к JSON/YAML/WireGuard — исчерпание памяти
- **Категория:** надёжность / DoS. **Файлы:** `core/parser/parser.go:582`
  (`parseJSON`), `:719` (`parseYAML`), `:739` (`parseWG`); лимит проверяется
  только в `parseList` (`:301`).
- **Описание:** `LinkParser.limit()` (дефолт 20000) не сверяется в ветках JSON
  (sing-box/sip008/xray), Clash YAML и WireGuard. Вредоносная подписка 16 МиБ
  (~лимит `MaxInputSize`) с ~300 тыс. мелких объектов → сотни МБ в куче
  привилегированного ядра при `ParseImport`/`FetchSubscription`.
- **Сценарий:** вредоносный провайдер подписки → OOM ядра.
- **Фикс:** проверка `len(r.Servers) >= p.limit()` в `parseJSON`/`parseYAML`/
  `parseWG`, как в `parseList`.

#### M-6. Мёртвый handshake-timeout IPC + нет лимита соединений (локальный DoS)
- **Категория:** надёжность. **Файлы:** `core/ipc/ipc.go:140-148`
  (`dispatch`: `SetDeadline(+timeout)` → тут же `SetDeadline(time.Time{})` —
  дедлайн никогда не срабатывает), `core/ipc/ipc.go:116-134` (`Serve` — горутина
  на соединение без капа), `core/legacycontrol/server.go:55-62` (после Handshake
  read-deadline снимается полностью).
- **Описание:** задуманный 10-секундный бюджет «молчаливого» соединения —
  мёртвый код для gRPC-пути: соединение, ничего не приславшее, висит вечно
  (горутина + FD). Лимита параллельных соединений нет.
- **Сценарий:** допущенный локальный пир открывает тысячи молчаливых соединений
  → исчерпание FD/памяти ядра.
- **Фикс:** не снимать дедлайн до завершения интродукции; щедрый idle-timeout с
  продлением при активности; кап соединений в `Serve`.

#### M-7. Probe — TCP-сканер приватных адресов (оракул достижимости)
- **Категория:** безопасность. **Файл:** `core/probe/probe.go:133-183`.
- **Описание:** `ProbeServers` (лимиты 256 эндпоинтов / 8 сокетов / 5с — корректны)
  диалит любой host:port из запроса, включая `127.0.0.1`, `169.254.169.254`,
  RFC1918; ответ `Reachable`+`LatencyMs` — оракул для картирования внутренней сети.
  (Для подписок аналогичная защита через `dialChecked` есть; для probe — нет.)
- **Сценарий:** держатель токена (== любой допущенный пир, см. H-4) сканирует
  порты локальной сети/метадаты облака с привилегированной учётки.
- **Фикс:** отклонять приватные/loopback-адреса, как в subscription, или
  задокументировать как intended.

#### M-8. Незакреплённые GitHub Actions и remote-code в CI (supply-chain)
- **Категория:** безопасность. **Файлы:** `.github/workflows/legacy.yml`,
  `.github/workflows/security.yml` (`actions/checkout@v6`,
  `actions/setup-go@v5`, `golangci/golangci-lint-action@v8`, …),
  `go run golang.org/x/vuln/cmd/govulncheck@latest`,
  `bash <(curl -sSfL https://raw.githubusercontent.com/…/download-actionlint.bash)`.
- **Описание:** все actions — изменяемые major-теги; `govulncheck@latest`
  резолвится в момент прогона; выполнение удалённого скрипта в CI.
- **Сценарий:** перезапись тега → вредоносный код в CI.
- **Фикс:** pin по SHA (`dependabot` для `github-actions` уже настроен);
  зафиксировать версию govulncheck; actionlint — из релизного архива с SHA.

#### M-9. C#: PID-reuse race — `V2rayStopPid` может убить чужой процесс
- **Категория:** надёжность. **Файлы:**
  `legacy/v2rayN/v2rayN/Handler/V2rayHandler.cs:278-288`,
  `Handler/SpeedtestHandler.cs:129,180,198,220,270,307`.
- **Описание:** сохраняется `int pid`, позже `Process.GetProcessById(pid).Kill()`.
  Если процесс завершился и PID переиспользован — убивается посторонний процесс.
- **Фикс:** хранить `Process`, либо сверять `MainModule.FileName` перед `Kill()`
  (как уже делает `V2rayStop`, `:231-252`).

#### M-10. C#: утечка процесса/дескриптора в `getCoreVersion`
- **Категория:** надёжность. **Файл:**
  `legacy/v2rayN/v2rayN/Handler/UpdateHandle.cs:437-494`.
- **Описание:** `Process p = new Process(); p.Start(); p.WaitForExit(5000)` —
  без `using`; при таймауте процесс не убивается, дескриптор не освобождается.
  Каждая проверка обновлений при зависшем ядре = висящий процесс + handle leak.
- **Фикс:** `using var p`; `if (!p.WaitForExit(5000)) p.Kill()`.

#### M-11. C#: неэкранированные аргументы `sysproxy.exe` из пользовательского шаблона
- **Категория:** безопасность (низкий практический импакт).
  **Файл:** `legacy/v2rayN/v2rayN/Handler/SysProxyHandle.cs:105-135,225-320`.
- **Описание:** ветка `global` собирает `arguments = $"global {strProxy} {strExceptions}"`
  без `QuoteArgument` (есть только в `ResetIEProxy`). `UseShellExecute=false` —
  shell-инъекции нет, но возможна инъекция argv-аргументов; `sysproxy.exe` —
  фиксированный бинарник с фиксированными командами, шаблон правит сам пользователь.
- **Фикс:** применять `QuoteArgument` и в `global`-ветке.

#### M-12. Android: bearer-URL подписки в памяти приложения; канал UI↔ядро не задан
- **Категория:** безопасность / архитектура. **Файлы:**
  `app/lib/src/generated/sora/core/v1/core_control.pb.dart:6699,7576,3785`,
  `app/lib/src/generated/sora/core/v1/core_control.pbgrpc.dart`.
- **Описание:** `GetSubscriptionLinkResponse.url` и `ExportDiagnosticsResponse.archive`
  несут bearer-токен в память приложения — будущий UI обязан не логировать/шарить
  сырой URL (редектирующего хелпера нет). Сгенерированный gRPC-клиент не задаёт
  TLS/credentials — plaintext TCP на loopback позволит любому локальному процессу
  пройти Handshake (см. H-4).
- **Фикс:** центральная утилита редактуры URL; Unix-socket + `SO_PEERCRED` либо
  TLS с пиннингом для канала UI↔ядро; никогда plaintext TCP.

#### M-13. Android: «зашифрованный кэш последнего плана» без дизайна ключей
- **Категория:** безопасность / архитектура. **Файл:** `app/android/tunnel/README.md:8`.
- **Описание:** Always-on VPN стартует из зашифрованного кэша; дизайна key
  management нет. Хардкод ключа = шифрование-фикция; нужен device-protected ключ
  (Direct Boot).
- **Фикс:** ключ в Android Keystore, Direct Boot-aware `EncryptedFile`.

### LOW

#### L-1. Сокет Linux `0o666` (аудит писал `0660`)
- **Файл:** `core/ipc/ipc_peer_linux.go:14` (`socketMode = 0o666`).
  Прошлый аудит (core-security №20) заявлял `0660`, но код намеренно ставит
  `0666`, полагаясь на peer-правило (`SO_PEERCRED`, `defaultAllow`,
  `core/ipc/ipc_unix.go:66-79`): чужой UID закрывается без ответа.
  Отклонение обосновано, но: подключиться (и держать соединения, см. M-6) может
  любой локальный пользователь; формулировку прошлого аудита стоит поправить.

#### L-2. Кэш редакторов сбрасывается целиком при 8 коннектах — маскировка молча отключается
- **Файл:** `core/control/server.go:351-365` (`maxCachedRedactors = 8`,
  `clear(c.byRef)`).
- **Описание:** каждый `Connect` кладёт redactor; `Disconnect` снимает, но
  повторные `Connect` без `Disconnect` (реконнекты, злоумышленник с токеном)
  накапливают записи; 9-й `put` стирает **все**, включая текущий, —
  последующие `WatchEvents`/`GetStats`/`ProbeServers` идут без маскировки.
- **Фикс:** вытеснять oldest, а не `clear()`; дропать redactor предыдущего
  сеанса при `Connect`.

#### L-3. `Disconnect` может не дропнуть redactor
- **Файл:** `core/control/server.go:528-530`.
  `if finished := s.sessions.Status().SessionID; finished != ""` — если статус
  уже сброшен, redactor остаётся в кэше (утечка памяти, слабая).

#### L-4. `nft` резолвится через PATH; bypass правится в ruleset как есть
- **Файлы:** `core/guard/nftables_linux.go:81`, `core/guard/nftables.go:55-58`.
  `nft` — не абсолютный путь. `--bypass` (CLI-флаг оператора) интерполируется
  в ruleset без валидации — опечатка ломает kill switch. Клиентский
  `DeviceName` сервером форсится в константу (`plan.go:172`) — инъекции через
  план нет. Харденинг: абсолютный путь, валидация bypass как CIDR.

#### L-5. Env-перенаправление data-dir; `-print-token`
- **Файлы:** `core/cmd/sora-core/cli.go:161-169` (`SORA_LEGACY_DATA_DIR`),
  `core/cmd/sora-core/check.go:53-59`.
  Env перенаправляет каталог токена/секретов (актуально при user-запуске ядра).
  Дефолт при недоступности `UserConfigDir` — CWD-относительный `./.sora-legacy-core`
  (хрупкая идентичность). Фикс: игнорировать env для привилегированного режима;
  предупреждать в лог.

#### L-6. SSRF-защита подписок обходится при `HTTPS_PROXY`
- **Файл:** `core/subscription/subscription.go:93-107,316-340`.
  `dialChecked` проверяет адрес TCP после DNS (защита от rebinding — корректна),
  но при прокси диалится прокси, а цель уходит в `CONNECT` без проверки;
  редирект на приватный хост выполнит прокси. Только если оператор сам задал
  прокси (доверенная конфигурация). Фикс: проверять hop-URL политикой
  `isPrivateHost` и при прокси.

#### L-7. `diagnostics.Run` возвращает немаскированные строки вопреки комментарию
- **Файл:** `core/diagnostics/diagnostics.go:93-102` («masking each line before
  it leaves the core» — на деле `mask` только в `Export`).
  Сейчас `report()` секретов не содержит, но инвариант хрупкий. Фикс: прогнать
  через `c.mask` в `Run` + тест.

#### L-8. C#: Zip-Slip в мёртвом `v2rayUpgrade`
- **Файл:** `legacy/v2rayN/v2rayUpgrade/MainForm.cs:66-99`
  (`Path.Combine(StartupPath(), entry.FullName)` без проверки `..` →
  `ExtractToFile(..., true)`; апдейтер рассчитан на повышение прав).
  Код мёртвый (не в `.sln`, не собирается, самообновление GUI отключено) —
  поэтому Low. Плюс `:118` `Process.Start("v2rayN.exe")` — поиск по CWD/PATH;
  `FileManager.ZipExtractToFullFile` (`Tool/FileManager.cs:110-131`) — латентный
  траверс без вызывающих. Фикс: удалить `v2rayUpgrade` либо чинить
  (`GetFullPath` + проверка префикса).

#### L-9. C#: `DownloadFileAsync` — игнор таймаута, fire-and-forget
- **Файл:** `legacy/v2rayN/v2rayN/Handler/DownloadHandle.cs:105-148`.
  Без `await`, CTS не отменяется/не диспоузится, `CancelAfter` не вызывается —
  зависшая закачка висит вечно.

#### L-10. C#: обновление подписки на 3 секунды снимает системный прокси (fail-open)
- **Файл:** `legacy/v2rayN/v2rayN/Handler/UpdateHandle.cs:225-250`.
  `ForcedClear` → `Task.Delay(3000)` → восстановление в `finally`; крэш процесса
  в окне → прокси выключен, трафик напрямую. Фикс: сторожевой флаг восстановления
  при старте.

#### L-11. C#: `--restore-proxy`, Mutex-DoS, HTTP-спи
...[truncated 5229 chars]