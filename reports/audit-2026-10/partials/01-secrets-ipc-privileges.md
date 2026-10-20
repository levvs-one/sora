# Аудит: Go-ядро — секреты, IPC, управление, привилегии, обновления

Этап 1 из 5. Зона: `core/secret/`, `core/ipc/`, `core/control/`, `core/cmd/sora-core/`, `service/`, `packaging/`, `.gitleaks.toml`, `SECURITY.md`, `proto/`.

## Методология

Прочитаны целиком: `core/secret/store.go`, `key.go`, `format.go`, `file.go`, `file_other.go`, `file_windows.go`, `protector_windows.go`; `core/ipc/ipc.go`, `ipc_unix.go`, `ipc_windows.go`, `ipc_peer_linux.go`, `ipc_peer_other.go`, `polkit_linux.go`; `core/control/auth.go`, `server.go`, `logs.go`, `plan.go`, `subscriptions.go`, `errors.go`, `version.go`; `core/cmd/sora-core/main.go`, `cli.go`, `check.go`, `service_windows.go`, `service_other.go`, `platform_other.go`, `platform_windows.go`; `service/linux/sora.policy`, `sora-core.service`, `sora.sysusers`; `packaging/linux/sora-update`, `io.github.levvs-one.sora.update.policy`, `packaging/install/install.sh`, `packaging/install/install.ps1`, `packaging/engines/fetch.sh`, `packaging/linux/nfpm.yaml`, `packaging/linux/scripts/*`, `packaging/windows/sora.iss`, `packaging/zapret/build.sh`; `app/lib/src/updates.dart` (Dart-сторона автообновлений — входит в механизм обновлений); `core/subscription/subscription.go` (SSRF-защита фетчера); `proto/sora/core/v1/core_control.proto` (контракт токена).

Grep-паттерны: `exec.Command`, `os.Getenv`, `net/http`, `InsecureSkipVerify`, `0o777|0755|0777`, `Chmod`, `panic(`, `TODO|FIXME|XXX|HACK`, `token`, `Bearer`, `password`. Каждая находка ниже сверена с окружающим кодом; недоказанные гипотезы отброшены (например, «отсутствует проверка токена на PutSecret» — не баг: контракт `core_control.proto` токена там не требует, это задокументированный дизайн; TOCTOU в `removeLeftover` — не приводит к записи в чужой файл, т.к. `os.Remove` не следует за финальным симлинком, а `bind()` на симлинк возвращает `EADDRINUSE`).

Проверено и признано корректным (не находки): SSRF-защита фетчера подписок (только HTTPS, `dialChecked` с проверкой реального адреса после DNS — защита от rebinding, лимит редиректов, лимит тела); redaction логов движков через `redactor.String()` перед записью в log center; валидация `sessionID`/`reference` строгим алфавитом (path traversal невозможен); DPAPI на Windows (user-scope, без `CRYPTPROTECT_LOCAL_MACHINE`); systemd-юнит (hardening: `ProtectSystem=strict`, `NoNewPrivileges`, `UMask=0077`, `StateDirectoryMode=0700`); `sora-update` (приватный снапшот пакетов, symlink-race проверки, `count==1` для чексумм, проверка метаданных пакета).

## Находки

### 1. [High] Polkit: `allow_active=yes` — любой активный локальный пользователь получает полный контроль над ядром

**Файл:строки:** `service/linux/sora.policy:22` (`<allow_active>yes</allow_active>` для action `io.github.levvs-one.sora.control`)

**Описание:** Любой пользователь с активной локальной сессией авторизуется polkit без пароля. Через `Handshake` (`core/control/server.go`, возвращает `s.auth.Token()` любому допущенному транспортом пиру) он получает control token и далее — весь API: `Connect` с произвольным планом (подмена серверов/маршрутизации), `SetKillSwitch`, `PutSecret`/`DeleteSecret` (перезапись/стирание секретов в vault), `ExportDiagnostics` с форматом PCAPNG (см. находку 2), `SaveSubscription`/`GetSubscriptionLink` (чтение bearer-ссылок подписок).

**Почему это баг:** Комментарий в policy оправдывает это аналогией «как сетевые настройки десктопа», но аналогия неверна: например, NetworkManager требует `auth_admin` для системных соединений. Угроза реальна на shared-машинах (семейный ПК с двумя аккаунтами, лабораторные/терминальные машины, fast user switching): второй активный пользователь может перехватить/перенаправить чужой VPN-туннель и снять дамп трафика. Нарушен принцип наименьших привилегий: чтение статуса — да, управление туннелем/файрволом/секретами — нет.

**Эксплуатация:** На машине, где жертва держит Sora-подключение, второй локальный пользователь с активной сессией: `polkit` → подключение к `/run/sora/core.sock` (0666) → `Handshake` → token → `ExportDiagnostics(PCAPNG)` / `Connect` со своим планом.

**Фикс:** Разделить action на read-only (`allow_active=yes`: `GetStatus`, `GetStats`, `WatchEvents`) и control (`allow_active=auth_self` или `auth_admin`: `Connect`/`Disconnect`/`SetKillSwitch`/секреты/подписки/PCAPNG). Либо задокументировать как осознанный риск в `SECURITY.md`.

---

### 2. [High] `ExportDiagnostics` (PCAPNG/EVTX) возвращает сырые нередкатированные данные вопреки гарантии в docstring

**Файл:строки:** `core/control/server.go:1192-1193` (docstring), `1194-1235` (реализация); `core/diagnostics/packets_linux.go:18-50`

**Описание:** Docstring метода: «ExportDiagnostics returns an archive built from already-redacted core values. Clients cannot expand its contents.» Но для `DIAGNOSTIC_FORMAT_PCAPNG` возвращается `diagnostics.CapturePackets(capture, engine.TunDevice, 10*time.Second)` — сырой 10-секундный pcapng всего TUN-трафика (`SetCaptureLength(256)` — заголовки целиком + до 256 байт payload на пакет: DNS-запросы, SNI, куски plaintext-трафика), без какой-либо редактуры. Для `DIAGNOSTIC_FORMAT_EVTX` — сырые Windows event logs (`diagnostics.ExportWindowsEvents`). Метод требует только control token, который выдаётся любому допущенному транспортом пиру через `Handshake` (см. находку 1: на Linux — любому активному локальному пользователю).

**Почему это баг:** Код прямо противоречит собственной security-гарантии. Это межпользовательская утечка трафика на shared-машинах: второй активный пользователь снимает 10 секунд чужого VPN-трафика в сыром виде.

**Эксплуатация:** Активная сессия пользователя B → `Handshake` на `/run/sora/core.sock` → token → `ExportDiagnostics{format: PCAPNG}` → pcapng с трафиком пользователя A.

**Фикс:** Либо убрать сырые форматы из метода (оставить только редиктированный архив), либо требовать для PCAPNG/EVTX отдельную привилегию (администратор), явно задокументировать, что эти форматы не редиктируются, и добавить явное подтверждение пользователя в UI.

---

### 3. [Medium] IPC handshake-timeout никогда не срабатывает: дедлайн ставится и тут же снимается — неограниченные висячие соединения (локальный DoS)

**Файл:строки:** `core/ipc/ipc.go:144-147` (`dispatch`)

```go
_ = connection.SetDeadline(time.Now().Add(timeout))
// Clear the introduction deadline because the handler owns subsequent
// long-lived streams.
_ = connection.SetDeadline(time.Time{})
_ = handle(connectionCtx, connection)
```

**Описание:** `handshakeTimeout` (10s, «bounds silent connections before introduction») устанавливается и синхронно снимается *до* вызова `handle` (gRPC-сервер не ставит своих read-дедлайнов: `grpc.NewServer` в `core/cmd/sora-core/main.go` — только лимиты размеров сообщений). Итог: молчаливое соединение висит вечно, занимая fd и горутины. `Serve` вызывает `go l.dispatch(...)` для каждого допущенного `Accept` пира без какого-либо лимита числа соединений.

**Почему это баг:** Любой допущенный транспортом пир (на Linux — любой активный локальный пользователь через polkit; сокет 0666 позволяет *подключиться* кому угодно) может открыть ~1024 висячих соединений (лимит fd сервиса) и держать их. Дальше два эффекта: (а) у ядра заканчиваются fd → `Accept` возвращает `EMFILE` → `Serve` возвращает ошибку → `app.Serve` завершает процесс → systemd `Restart=on-failure` → цикл падений, VPN недоступен; (б) даже без исчерпания fd — раздувание памяти/горутин. Легитимный UI при этом не может подключиться.

**Эксплуатация:** Скрипт от имени любого активного локального пользователя: 1024× `Dial("unix", "/run/sora/core.sock")`, держать сокеты открытыми, ничего не отправлять → ядро падает по EMFILE → рестарт → повтор.

**Фикс:** Не снимать дедлайн до завершения introduction: например, прочитать HTTP/2 preface с дедлайном и снять его только после первых байт, либо ввести семафор/лимит на число одновременных соединений в `Serve` + `grpc.KeepaliveParams`/`MaxConnectionIdle`.

---

### 4. [Medium] В цепочке автообновлений нет криптографической подписи — только чексуммы; SHA256SUMS не аутентифицирован

**Файл:строки:** `app/lib/src/updates.dart:163-196` (verify `expectedHash`/`verifyUpdateFile`), `packaging/linux/sora-update:43-56` (проверка `sha256sum -c`), `packaging/install/install.sh:88-100`, `packaging/install/install.ps1:36-44`

**Описание:** Вся цепочка доверяет SHA-256 чексуммам из файла `SHA256SUMS`, который скачивается по TLS с GitHub и нигде не подписан (нет GPG/minisign, нет pinned публичного ключа). Критично: `sora-update` (работает как root через pkexec) берёт `SHA256SUMS` из *записываемого пользователем* каталога загрузки (`$3`, `Directory.systemTemp.createTemp('sora-update-')`) и сверяет пакеты именно с ним. Локальный атакующий с правами того же пользователя (малварь) может подменить в каталоге загрузки и пакеты, и `SHA256SUMS` согласованно — проверка пройдёт, и после того, как пользователь введёт пароль администратора в pkexec-промпт («обновление Sora»), вредоносные пакеты установятся как root. Второй вектор: компрометация релизных артефактов на GitHub — нет второго фактора аутентификации издателя. Дополнительно: `install.sh`/`sora-update` для zypper используют `--allow-unsigned-rpm` (подписи RPM игнорируются осознанно, т.к. их нет).

**Почему это баг:** Чексумма доказывает целостность относительно манифеста, но не аутентифицирует издателя. Downgrade при этом закрыт корректно (`newerRelease` в `updates.dart:37-41` требует `next > current` и не-prerelease) — проблема именно в отсутствии подписи.

**Эксплуатация:** Малварь от имени пользователя подменяет `$TMP/sora-update-*/SHA256SUMS` + `.deb/.rpm` на свои (с пересчитанными хешами), ждёт клика «установить обновление» и ввода админ-пароля → RCE как root.

**Фикс:** Подписывать `SHA256SUMS` (minisign/GPG), вшить публичный ключ в приложение и в `sora-update`, проверять подпись *до* сверки хешей в обоих местах. Для RPM — начать подписывать пакеты и убрать `--allow-unsigned-rpm`.

---

### 5. [Low] `Authenticator.Rotate()` не сохраняет новый токен — «инвалидированный» токен воскресает после рестарта

**Файл:строки:** `core/control/auth.go:108-117`

**Описание:** `Rotate()` генерирует свежий токен, меняет его в памяти и возвращает вызывающему, но не пишет в `control.token` на диске. `LoadOrCreateToken` при следующем старте загрузит *старый* токен из файла. Docstring обещает: «All existing client tokens become invalid» — это верно только до рестарта ядра. Если ротация была вызвана подозрением на компрометацию токена, скомпрометированный токен снова станет валидным после рестарта.

**Почему это баг:** Неполная security-операция: инвариант «старый токен мёртв» не переживает рестарт. Сейчас усугубляется тем, что у `Rotate` нет вызывающих (grep по `core/`, `app/`, `proto/` — только определение), т.е. дефект латентный, но API лжёт о своих гарантиях.

**Фикс:** В `Rotate()` атомарно перезаписывать файл токена (owner-only, через тот же atomic-write, что и vault) либо явно задокументировать session-scope ротации.

---

### 6. [Low] На Linux/macOS мастер-ключ хранится в открытом виде; комментарии утверждают несуществующие проверки прав

**Файл:строки:** `core/secret/key.go:28-36` (`FileProtector`), `core/cmd/sora-core/platform_other.go:25-27` (`secureDataDir` — no-op)

**Описание:** `FileProtector.Protect/Unprotect` — тождественные функции: `master.key` лежит рядом с `secrets.vault` в открытом виде (0600). Т.е. AES-256-GCM шифрование vault на этих платформах не даёт ничего сверх прав файловой системы — это честно отражено в комментарии «Protection depends on the service account's security», но соседние комментарии вводят в заблуждение: «Unprotect copies the key; the owning store checks file permissions» — такой проверки в коде нет (в `Open`/`loadOrCreateKey`/`readMasterFile` нет ни одного `stat`/проверки mode; `os.MkdirAll(dir, 0o700)` не чинит права уже существующего каталога, а `secureDataDir` на не-Windows — no-op и полностью полагается на systemd-юнит). При ручном запуске с уже существующим каталогом с широкими правами ядро молча продолжит работу.

**Почему это баг (hardening):** Расхождение кода и задокументированных инвариантов + отсутствие fail-closed при ослабленных правах на каталог секретов.

**Фикс:** При `Open` проверять `stat` каталога и файлов (`master.key`, `control.token`, `secrets.vault`): требовать `0600`/`0700` и владельца == euid, иначе отказываться стартовать с понятной ошибкой (как уже делает Windows-вариант `secureDataDir`, переименовывающий недоверенный каталог).

---

### 7. [Low] Файл control token пишется неатомарно — обрыв записи = отказ в старте ядра

**Файл:строки:** `core/control/auth.go:120-125` (`writeOwnerOnly` → `os.WriteFile(path, data, 0o600)`)

**Описание:** В отличие от vault и master key (пишутся через `writeFileAtomic` с fsync + rename), токен пишется напрямую. Крэш/потеря питания посередине записи → усечённый `control.token` → `LoadOrCreateToken` отвергнет его («the stored authenticator is not readable») → ядро не стартует до ручного вмешательства. Права 0600 при этом корректны (umask учтён), проблема только в атомарности.

**Фикс:** Использовать тот же `writeFileAtomic`-подход для токена.

---

## Что проверено и не является находкой

- Контракт `core_control.proto`: методы без проверки токена (`PutSecret`, `ParseImport`, `SetKillSwitch` и др.) токена и не требуют по контракту — это осознанный дизайн (граница — транспортная аутентификация через polkit/pipe ACL), а не пропущенная проверка.
- SSRF-защита фетчера подписок, redaction логов движков, валидация sessionID/reference, DPAPI user-scope, hardening systemd-юнита, symlink-race защита в `sora-update`, `removeLeftover` (удаление не следует за симлинком; `bind()` на симлинк даёт `EADDRINUSE`).
- `VerifyDigest` для бинарников движков существует, но не вызывается никем — мёртвый код, не уязвимость (рантайм доверяет правам ФС на `/usr/lib/sora/engines`, что консистентно с моделью угроз).
- `panic(`, `InsecureSkipVerify`, `TODO/FIXME` — отсутствуют в зоне аудита; `0755/0777` — только на каталоге сокета (осознанно) и бинарниках в пакетах.

ИТОГО: 7 находок (Critical: 0, High: 2, Medium: 2, Low: 3)
