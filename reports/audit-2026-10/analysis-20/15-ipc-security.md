# Аналитик №15: безопасность IPC

Зона: `core/control/` (gRPC-сервер, `authz.go`, токены), `core/ipc/` (транспорт, `authlevel.go`, polkit),
`core/secret/` (vault), loopback. Ветка `bugfix/audit-2026-10-19`. Read-only анализ.
Не дублирует: H5/H6/H7 (движок/сессии — чужая зона), `unwrapConn` и panic на пустом секрете
(оба уже корректны/исправлены — см. «Проверено и чисто»).

## Вердикт

Транспорт IPC спроектирован грамотно: нет TCP-порта control plane, kernel-верификация пира
на двух уровнях, fail-closed по умолчанию, клиентская защита от pipe-squatting на Windows,
токен как второй барьер для чувствительных чтений. Это сильная база.

Но есть **одно центральное противоречие threat model**, введённое фиксом SORA-H2 на этой ветке:
polkit-action `io.github.levvs-one.sora.control` переведён с `allow_active=yes` на
`auth_self`, а проверка в коде идёт **без интеракции** — такая комбинация всегда возвращает
challenge, то есть ветка выдачи AuthControl через polkit **мертва**. Итог на дефолтной
установке Linux: desktop-пользователь получает только AuthRead, Handshake не выдаёт ему токен,
Connect/Disconnect недоступны — приложение не может поднять туннель, хотя
`docs/install.md` и `docs/architecture.md` обещают «подключение без пароля, если вы сидите
за компьютером». Это одновременно security-находка (политика строже задокументированной)
и функциональный баг (сломан основной сценарий). Детали — проблема №1 ниже.

Остальное — честные средние/мелкие находки: бессрочный bearer-токен без ротации,
отсутствие audit-log чувствительных IPC-операций, вводящий в заблуждение комментарий allowlist,
два residual TOCTOU на PID.

## Сильные стороны

1. **Нет сетевого control-порта.** Control plane — только Unix-socket (`/run/sora/core.sock`,
   `core/ipc/ipc_unix.go:27`) и Windows named pipe (`\\.\pipe\sora-core-v1`,
   `core/ipc/ipc_windows.go:16`). `127.0.0.1` в `core/cmd/sora-core/main.go:387,523` —
   это loopback-адрес туннельного прокси движка, не control plane.
2. **Двухуровневая проверка пира на kernel-данных.** `Listener.Accept`
   (`core/ipc/ipc.go:99-122`) режет по `allow`, затем `ServerHandshake`
   (`core/ipc/authlevel.go:108-117`) перепроверяет того же пира через `peerCredentials`.
   Идентичность — только из ядра: `SO_PEERCRED` (`core/ipc/ipc_peer_linux.go:19-55`),
   `GetNamedPipeClientProcessId` + токен процесса (`core/ipc/ipc_windows.go:54-88`).
   Клиентских заявлений нет в принципе.
3. **Fail-closed везде.** Неизвестный метод → control-only (`core/control/authz.go:51-61`);
   контекст без peer credentials → `AuthNone` (`core/ipc/authlevel.go:119-128`);
   неверифицированный пир на Linux (сокет 0666) → `AuthNone`
   (`core/ipc/ipc_unix.go:86-93`); `PeerCredentials(nil)` → всех в `AuthNone`.
4. **Per-method allowlist адекватен.** Read-only: handshake, about, routing presets, status,
   stats, events, capabilities (`core/control/authz.go:13-24`). Всё меняющее состояние,
   трогающее секреты/подписки — только `AuthControl`. Чувствительные чтения (логи,
   листинги соединений) дополнительно требуют токен (`core/control/logs.go:22-40`,
   `core/control/server.go:531,575`, `core/control/censor.go:27`) — AuthRead-пир их
   не прочитает, даже though интерцептор его пропускает. Defense in depth, не слоп.
5. **Токен сделан аккуратно.** 32 байта из `crypto/rand`, `subtle.ConstantTimeCompare`
   после проверки длины, копия при выдаче (`Token()`), atomic persist
   (temp + `Chmod(0600)` + `fsync` + rename) в `writeOwnerOnly`
   (`core/control/auth.go:152-185`), `Rotate` — persist-before-swap, fail-closed без пути
   (`core/control/auth.go:122-150`).
6. **Windows: клиентская защита от pipe-squatting.** `app/lib/src/core/pipe.dart`,
   `_servedByService`: сверяет PID сервера пайпа (`GetNamedPipeServerProcessId`)
   с PID сервиса `SoraCore` из SCM; чужой пайп → `GrpcError.unavailable`, клиент не
   отправляет план с секретами злоумышленнику. DACL пайпа (`0x0012018B`)
   исключает `FILE_CREATE_PIPE_INSTANCE` для клиентов
   (`core/ipc/ipc_windows.go:19-47`).
7. **Linux: сквоттинг сокета затруднён.** `/run/sora` создаёт systemd с владельцем
   `sora:sora`, `RuntimeDirectoryMode=0755` (`service/linux/sora-core.service:20-25`);
   писать туда могут только `sora`/root. `removeLeftover` не удаляет живой сокет
   (`core/ipc/ipc_unix.go:117-137`).
8. **Расширения изолированы от мастер-токена.** Per-extension токены через отдельный
   issuer (`core/ext/store.go:548`, `core/ext/host.go:73-87`); `VerifyControl`
   (`core/control/exthost.go:19-21`) проверяет мастер-токен только для app-only
   операций (напр. `MintToken`, `core/ext/host.go:89`).
9. **DoS-рамки на месте.** `MaxConnections`/`DefaultMaxConnections=128`
   (`core/ipc/ipc.go:50-53,123-141`, SORA-M1), handshake timeout 10s, gRPC
   `MaxConnectionIdle: 10m` (`core/cmd/sora-core/main.go:330-333`), лимиты сообщений
   `MaxRecvMsgBytes`/`MaxSendMsgBytes`.

## Проверено и чисто (не findings)

- `unwrapConn` (`core/ipc/authlevel.go:88-106`): nil-safe, распаковывает только
  `connUnwrapper`; неизвестный wrapper → `peerOf` не распознаёт тип → unverified →
  отказ. Fail-closed, корректно.
- Panic на пустом секрете из 5-pass review — исправлен; в `core/secret/store.go:261`
  остался комментарий-фиксатор («comparison, which panicked on empty values from
  a crafted vault»).
- macOS: отсутствие `LOCAL_PEERCRED` честно задокументировано, граница — права
  сокета `0660` + токен (`core/ipc/ipc_peer_other.go:7-15`). Residual risk принят
  осознанно, не баг.

## Слоп / проблемы

### №1 (High). Мёртвая ветка polkit-control: `auth_self` без интеракции никогда не проходит

- `service/linux/sora.policy:36-44` — SORA-H2 (коммит `4c2bcb9`) сменил
  `allow_active` для `io.github.levvs-one.sora.control` с `yes` на `auth_self`.
- `core/ipc/polkit_linux.go:66-72` — `CheckAuthorization` вызывается с flags=0,
  комментарий: «Disable interaction so authorization cannot hold a connection open
  for a password prompt».
- `auth_self` без `AllowUserInteraction` всегда возвращает challenge, не authorized.
  Значит `polkitAllows(peer, PolkitAction)` (`core/ipc/ipc_unix.go:95-97`) всегда
  `false`. Ветка выдачи `AuthControl` через polkit мертва.
- Следствие: на дефолтной установке desktop-пользователь (не в группе `sora`,
  UID ≠ `sora`) получает **только `AuthRead`** → `Handshake`
  (`core/control/server.go:517-519`) не выдаёт токен → `Connect`/`Disconnect`
  отклоняются интерцептором (`AuthControl` required) и проверкой токена.
  **Приложение не может поднять/опустить туннель.**
- Документация противоречит коду: `docs/install.md:82` — «Приложение подключается
  к ней без пароля, если вы сидите за компьютером (это проверяет polkit)»;
  `docs/architecture.md:62-64` — «к сокету пускается процесс из активной локальной
  сессии (проверяет polkit)»; `service/linux/README.md` — то же. Все три описывают
  до-H2 модель.
- Развилка без хорошего дефолта:
  - (a) вернуть `allow_active=yes` для control → доки сходятся, но **любой процесс
    активной сессии (любой малварь пользователя) = полный контроль**, как на Windows;
  - (b) оставить `auth_self` → фактически control только для группы `sora`/UID `sora`,
    тогда чинить доки и UX (сейчас клиент получает голый `permissionDenied`,
    `app/lib/src/core/link.dart:50-58` ретраит всё, кроме него, — пользователь увидит
    `core.auth.unauthenticated` без объяснения про группу).
- Как есть сейчас — худшее из двух: политика строгая, а доки и UX делают вид,
  что пароль не нужен.

### №2 (Medium). Токен — бессрочный bearer, ротации нет

- `Authenticator.Rotate` (`core/control/auth.go:122-150`) написан корректно, но
  **нигде не вызывается** вне тестов (проверено grep по `core/`; в
  `core/cmd/sora-core/main.go:177` только `LoadOrCreateToken`).
- Токен создаётся один раз при первом старте, лежит в `/var/lib/sora/control.token`
  (0600), живёт вечно. Компрометация (дамп памяти, бэкап data dir, чтение тем же
  UID — 0600 не барьер внутри аккаунта) = постоянный контроль до wipe каталога.
- Нет rotation RPC, нет ротации при рестарте службы, нет TTL. Клиенты и так
  пере-handshake'ятся при обрыве (`CoreLink.open` ретраит), так что ротация при
  старте почти бесплатна.

### №3 (Medium). Нет audit-log чувствительных IPC-операций

- `Handshake` (выдача токена), `Connect`/`Disconnect` (успех и отказ),
  отказы transport-auth (`ServerHandshake`), отказы проверки токена, `Rotate` —
  нигде не логируются с идентификацией пира.
- `core/control/server.go:506-580`, `core/ipc/authlevel.go:108-117`: тишина.
  Операционные события (подписки, расширения) в `s.logs` пишутся, security-событий нет.
- При инциденте («кто остановил туннель в 03:12?») смотреть нечего.
- Нюанс: `AuthLevel.String()` «never carries peer identity» — для audit-формата нужен
  отдельный рендер с uid/pid; это нормально для локального лога в каталоге 0700,
  секреты туда писать нельзя (токен, план — нет; uid/pid/method/decision — да).

### №4 (Low). Комментарий allowlist врёт про «log inspection»

- `core/control/authz.go:13-14`: «read-only RPCs: version negotiation, status,
  statistics, events, and **log inspection**».
- Факт: `QueryLogs`, `WatchLogs`, `GetLogSettings` (`core/control/logs.go:119,142,298`)
  идут через `s.authorize`, требующую **токен**, который `AuthRead`-пиры никогда
  не получают (`core/control/server.go:517-519`). Эффективная политика — control-only.
- Сама двухуровневость — хорошо (defense in depth), но комментарий вводит в
  заблуждение следующего читателя/аудитора. Это слоп: либо убрать логи из
  `readOnlyMethods` (честнее — они всё равно недоступны read-пирам), либо
  задокументировать, что токен сужает allowlist.

### №5 (Low). Residual TOCTOU: PID-reuse между accept и polkit-проверкой

- `peerOf` фиксирует PID в момент `Accept` (`core/ipc/ipc_peer_linux.go:48-54`);
  `polkitAllows` резолвит процесс по PID позже (timeout до 3s,
  `core/ipc/polkit_linux.go:60-72`). Клиент может выйти, PID — переиспользоваться
  процессом **того же UID**. Polkit сам сверяет start-time, но гонка между accept
  и check остаётся принципиальной.
- Практический импакт низкий: эскалации между пользователями нет (UID тот же),
  окно — миллисекунды, эксплуатация требует намеренного выхода и удачи
  планировщика PID. Принять как известный риск; не чинить сложно.

### №6 (Low). То же окно на Windows

- `peerOf` (`core/ipc/ipc_windows.go:54-88`): `GetNamedPipeClientProcessId` →
  `OpenProcess` → чтение токена. Между получением PID и открытием процесса окно
  переиспользования PID; на Windows нет привязки к UID, но успешная эксплуатация
  требует, чтобы PID занял привилегированный процесс в мик окне, — практически
  неэксплуатируемо. Residual, зафиксировать.

### №7 (Info). `removeLeftover`: dial-to-decide без проверки личности слушателя

- `core/ipc/ipc_unix.go:117-137`: успешный dial = «сокет живой», иначе unlink.
  Злоумышленник с правом записи в `/run/sora` (только `sora`/root при systemd-установке)
  может держать слушателя на пути → `lc.Listen` упадёт с `EADDRINUSE` → DoS старта ядра.
  Личность слушателя не проверяется (SO_PEERCRED слушателя недоступен до bind).
  Приемлемо при текущей модели каталога; отметить как границу.

### №8 (Info). Токен ≠ второй фактор против AuthControl-пиров

- `Handshake` выдаёт токен **каждому** `AuthControl`-пиру (`core/control/server.go:517-519`).
  На Windows любой малварь активной сессии (политика: `Present` → `AuthControl`,
  `core/ipc/ipc_windows.go:99-106`) получает токен бесплатно.
- Реальная ценность токена: (а) барьер для `AuthRead`-пиров на чувствительных чтениях;
  (б) defense in depth при баге в transport-auth. В коде это честно помечено (SORA-H2),
  но в threat model стоит зафиксировать явно, чтобы не было иллюзии «двух факторов».

## Ранжированные рекомендации

1. **Решить дилемму №1 явно и зафиксировать в коде.** Вариант (a):
   вернуть `allow_active=yes` для control-action — тогда threat model Linux =
   Windows («любой процесс активной сессии = полный контроль»), доки сходятся,
   UX работает. Вариант (b): оставить `auth_self` (фактически control только для
   группы `sora`) — тогда обновить `docs/install.md:82`,
   `docs/architecture.md:62-64`, `service/linux/README.md` и добавить в UI внятную
   ошибку про группу `sora` вместо голого `core.auth.unauthenticated`.
   В обоих случаях добавить интеграционный тест «desktop-пользователь может/не может
   вызвать Connect» — сейчас это поведение не покрыто ничем
   (`core/ipc/*_test.go`, `polkit_linux_test.go` мокают, e2e идёт от root/sora).
   Приоритет: P0 — ломает основной сценарий либо врёт в threat model.
2. **Оживить ротацию токена.** Самый дешёвый вариант: `Rotate()` при каждом старте
   службы (`core/cmd/sora-core/main.go`, рядом с `LoadOrCreateToken`) — клиенты
   пере-handshake'ятся сами (`CoreLink.open` уже ретраит). Альтернатива — TTL/ротация
   по таймеру. Сейчас `Rotate` — мёртвый код, а токен — бессрочный bearer.
3. **Audit-log IPC auth-событий.** Писать в core logs (уровень info/warning,
   `SourceCore`): `ipc: handshake peer=uid=%d pid=%d level=%s token_issued=%v`,
   `ipc: connect allowed/denied ...`, `ipc: auth failure method=... reason=...`.
   Без секретов (токен/план — никогда), с uid/pid — это локальный лог 0700,
   идентификация пира там уместна.
4. **Починить комментарий №4.** В `core/control/authz.go:13-24` убрать «log inspection»
   из описания read-only либо дописать, что `s.authorize` в `logs.go` сужает их
   до token-holders. Мелочь, но сейчас это ловушка для следующего аудитора.
5. **Зафиксировать threat model в одном месте** (`docs/security.md` или
   `docs/architecture.md#кто-может-управлять-службой`): Windows — любой процесс
   активной сессии = `AuthControl`; Linux — `sora`-UID / группа `sora` (+ `AuthRead`
   для активных сессий через polkit); macOS — граница по правам сокета;
   токен — не второй фактор против `AuthControl`, а барьер для `AuthRead` +
   defense in depth. Сейчас модель размазана по комментариям и частично
   противоречит коду (№1).
6. **TOCTOU №5/№6** — принять как известный residual риск, упомянуть в том же
   разделе threat model; активного фикса не требует (окно неустранимо в принципе,
   импакт низкий).
7. Не делать: не переносить control plane на TCP-loopback (текущее «только
   socket/pipe» — сила, не слабость); не добавлять интерактивный polkit в службе
   (зависшие handshake — хуже); не хранить токен в менее защищённом месте ради
   «удобства» клиентов.
