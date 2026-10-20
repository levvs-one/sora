# Финальный аудит №9 — sora-legacy: полный финальный проход

**Дата:** 2026-10-20. **Ветка:** `bugfix/audit-2026-10-19`, репозиторий
`~/workspace/bug-hunt/sora-legacy`, HEAD `649237c`. Пуша нет.
Контекст: `sora-legacy-audit.md`, `FIX-REPORT.md`, `SORA-LEGACY-DRIFT.md`,
`fixlog-legacy-*.md`, `REVIEW-5PASS.md` + `review-5pass/partial-legacy-*.md`.

> ⚠️ **Процессная оговорка о дереве (важно, не код).** В момент аудита рабочее
> дерево == HEAD (все фиксы на месте, прогоны ниже — именно против этого
> состояния), но **в индексе (staged) лежит откат A20-коммитов** ровно по 7
> файлам: `core/control/plan.go`, `core/control/plan_internal_test.go`,
> `core/session/journal_test.go`, `legacy/v2rayN/v2rayN/Forms/MainForm.Community.cs`,
> `MainForm.HappPages.cs`, `MainForm.cs`, `legacy/v2rayN/v2rayN/Handler/V2rayHandler.cs`.
> Staged-дифф снимает: fail-closed credential parsing (`2a467ed`, credentialKeys/
> peers), drainer journal-теста (`32f14db`), watchdog/dispose (`7ead4d8`, `c137090`,
> `649237c`). Unstaged-правки в рабочем дереве этот откат в точности компенсируют
> (`git diff HEAD` по всем 7 файлам — пуст). **Опасность:** любой голый
> `git commit` параллельного агента закоммитит этот откат. Я индекс не трогал
> (по заданию — без add/reset/checkout); родитель должен организовать снятие
> staged-отката (`git restore --staged` по этим 7 путям или эквивалент) до
> любых коммитов на ветке.

## 1. Go core (`core/`) — прогоны

Окружение: `~/workspace/go/bin/go` (go1.26.9 linux/amd64),
`TMPDIR=$HOME/workspace/.build-tmp`, `GOCACHE=$HOME/workspace/.gocache-v`,
рабочий каталог — `core/` (модуль `core/go.mod`).

| Проверка | Результат |
|---|---|
| `go build ./...` | ✅ exit 0, вывод пуст |
| `go vet ./...` | ✅ exit 0, вывод пуст |
| `go test ./...` | ⚠️ 25 пакетов ok, 1 падение — только известный env-кейс (см. ниже) |

Пакеты зелёные (выборочно, ключевые): `control` 4.178s, `session` 6.276s,
`engine/supervise` 4.862s, `engine/registry`, `engine/interop`, `secret`,
`probe`, `subscription`, `parser`, `obfs` 2.123s, `legacycontrol`, `ipc`,
`guard`, `diagnostics`, `cmd/sora-core`.

### Env-кейс (честный триаж — НЕ регрессия)

`TestTunAndFakeIPAvoidLANAndEachOther` (`core/engine`):
`tun_test.go:77: tun: fake-IP pool overlaps an existing interface`.
В песочнице есть интерфейс `host0` с `198.19.0.2/30`, пересекающимся с
fake-IP пулом теста — тест по своему дизайну отвергает такой пул. Та же причина
зафиксирована независимо в трёх предшествующих документах (FIX-REPORT §2,
fixlog-legacy-r2, review-5pass/partial-legacy-go §1): падение воспроизводится
и на чистом дереве. Регрессией **не объявляется**.

### Фиксы аудита на месте в финальном виде (вычитка кода, не только git log)

| Фикс | Проверка | Итог |
|---|---|---|
| LEGACY-M7 probe не сканирует приватные сети | `probe.Prober.measure` (probe.go:145+) отклоняет private/loopback/link-local до dial; `AllowPrivate` — opt-in, в продакшне дефолт `false`; `specialUse` расширен (incl. `0.0.0.0/8`, `240.0.0.0/4`, коммит `0ef63db`; R5-LG-1-1) | ✅ |
| DNS-rebinding пробера (R5-LG-1-2) | `Control`-хук `checkDialTarget` перепроверяет реальный адрес dial'а | ✅ |
| LEGACY-M3 redactor | `supervisor.go:313-314`: redactor сидируется и `p.Secrets()`, и `p.Identifiers()`; detail-fix `de68f41` расширил маскировку на все протоколы/форматы; тест `TestRedactorMasksServerIdentifiers` зелёный (control ok) | ✅ |
| LEGACY-H5 VerifyDigest вызывается | `registry.go:102-110` (`LoadDigests` → `VerifyDigest` для движков и `tpws`, R5-LG-1-3); `binary.go:117` — discovery сверяет кандидатов по `SHA256SUMS`; `AllowEnv` — opt-in (`--allow-env-bin`), PATH-fallback удалён (`exec.LookPath` в binary.go отсутствует) | ✅ |
| Handshake-токены (LEGACY-M4, H4-вариант B) | `control/auth.go`: 32-байт токен, `Rotate()` атомарно персистит до смены в памяти, threat model честно задокументирован (токен — не граница против same-account); матрица авторизации LEGACY-M1 в `server.go` | ✅ |
| NEW-1 resolve системных бинарей не через PATH | `tunroute_linux.go:143-158`: `systemBinDirs = {/usr/sbin, /sbin, /usr/bin, /bin}`, `resolveSystemBin` — **fail-closed** (`ErrBinNotFound`); `guard/nftables_linux.go:30`: абсолютные `nftSearchPaths` | ✅ |
| geoip/geosite SHA-256 | Go-сторона: `packaging/engines/fetch.sh` пишет `SHA256SUMS`, `engines.sig` enforcement (порт R5-SC, `21bf84e`); C#-сторона: `VerifyGeoFileAsync` (`.sha256sum`, fail-closed до замены файла) | ✅ |
| SORA-H6/M8 порты (A20-9) | `session/journal.go` Subscribe/cancel через closed-флаг под мьютексом; `control/plan.go:68-82` `credentialKeys` + reject пустых/чужих документов; `TestBrokenPeersFailClosed` на месте. **В рабочем дереве ✅; в staged-индексе эти правки откачены — см. оговорку выше** | ✅ (дерево) |
| Поздние волны: tune/censor порты | `core/tune`, `core/censor`, Geneva/`DetectCensorship` — **отсутствуют** (совпадает с DRIFT §2.2: SW4/SW5 не портировались) — регрессий ловить негде | ✅ n/a |
| SW1 obfs порт (частичный) | `core/obfs` на месте, компилируется, тесты зелёные (2.123s); отброшенные uTLS-поля задокументированы в `6b77b80` | ✅ без регрессий |

### Находки Go

- **Критичных/High/Medium/Low кодовых находок финального вида не выявлено.**
  Все фиксы аудита, 5-pass и последующих волн присутствуют и покрыты зелёными
  тестами (кроме env-кейса выше).
- Info: известные открытые спеки из 5-pass (R5-LG-1-4 WFP Glob, R5-LG-2-10
  probeProfile selectors, R5-LG-4-2 wire-код Unsupported, R5-LG-5-2 мёртвый
  `BypassSettings`) остаются спеками — финальный аудит их не усугубил и не
  скрыл; `6599852` честно пометил мёртвые поля контракта как reserved.

## 2. C# WinForms (`legacy/v2rayN/`) — вычитка (тулчейна НЕТ)

### Синтаксическая целостность

- Механическая проверка баланса скобок/скобок всех видов по **всем 105 `.cs`
  файлам** (`legacy/` целиком: v2rayN 93 + Client 6 + Control 3 + tests 3),
  со стрипом строк/комментариев: **дисбалансов — 0**.
- «Метод в методе» (класс R5-LC-2-19 Critical): `IsAppDirectoryUserWritable`
  находится на уровне класса (`MainForm.Community.cs:915`), после корректно
  закрытых `catch` у `RestartCommunityAsAdministrator` (строки 897/903). ✅
- Поздние волны вычитаны построчно в изменённых местах: watchdog смерти ядра
  (`V2rayCoreExited`/`CommunityCoreExited`, маршалинг через `BeginInvoke` +
  гварды `IsDisposed/Disposing/IsHandleCreated`), kill-switch gate через
  Modes dialog (`6c9d51d`), dispose/volatile в `V2rayHandler` — структура
  методов и скобки согласованы.

### Фиксы на месте в финальном виде

| Фикс | Проверка | Итог |
|---|---|---|
| LEGACY-H1 верификация скачанных движков | `UpdateHandle.VerifyCoreArchiveAsync` — SHA-256 zip vs `.dgst` до распаковки, fail-closed; `VerifyGeoFileAsync` — `.sha256sum` до замены рабочего файла | ✅ |
| Downgrade-защита | `CompareVersions` (числовое сравнение) + `responseHandler`: `CompareVersions(version, curVersion) <= 0` → отказ | ✅ |
| LEGACY-H3 arbitrary-file-launch закрыт | `AddServer2Form.btnEdit_Click`: whitelist расширений, `Path.GetFullPath` внутри try (R5-LC-2-12), префикс-чек каталога конфигов, запуск только явного `notepad.exe` из System folder, `UseShellExecute=false` | ✅ |
| Mutex (LEGACY-L11b) | `Program.IsDuplicateInstance`: при занятом мьютексе без живого процесса своего exe — дескриптор закрывается, мьютекс пересоздаётся; `IsOwnExecutableRunning` fail-closed при ошибке проверки | ✅ |
| HttpClientHelper синглтон (R5-LC-1-2) | Настоящий `Lazy<HttpClientHelper>`; статическое поле присваивается в фабрике; `GetInstance()` возвращает `_instance.Value` | ✅ |
| IsNumberic (R5-LC-2-1) | `int.TryParse(oText, out _)`; заодно `IsIP` проверяет `cidr[1]` (R5-LC-2-2) | ✅ |
| using/dispose в изменённых местах | `UpdateHandle.getCoreVersion`: `using (Process p)` + Kill при таймауте; `DownloadHandle`: `using` для HttpClient и CTS (R2-NEW-1 + R5-LC-1-1); `HttpClientHelper`: `using` для всех `HttpResponseMessage`; `V2rayHandler`: `volatile Process _process`, detach-then-Dispose при штатном стопе, Dispose в Exited-обработчике и на failed-старте (A20, HEAD) | ✅ |
| LEGACY-M9 PID-reuse | `V2rayStopPid` → `IsKnownCoreProcess` (MainModule vs известные бинарники, fail-closed `false` при Win32/InvalidOperation) | ✅ |

### Находки C#

- **Критичных/High/Medium новых находок не выявлено.** Состояние совпадает с
  финальным состоянием после 5-pass + A20/detail-fix волн.
- Остаются в силе 24 спеки из REVIEW-5PASS (Low/Medium, не блокирующие):
  BinaryFormatter в `Utils.DeepCopy`, clash `port:`/`socks-port:` (R5-LC-2-17),
  позиционная связь `lstVmess`↔`lvServers.Items` (R5-LC-2-18), хардкод RU-строк
  (R5-LC-5-1) и др. — без изменений, финальный аудит новых не добавил.
- ⚠️ **Честность обязательна: C# НЕ СОБРАН.** В окружении нет .NET-тулчейна;
  вердикт по C# — это вычитка + механический баланс скобок, а не компиляция.
  Перед мержем ветки сборка на dev-машине обязательна (как уже требовал
  FIX-REPORT §4 п.5).

## 3. Паритет / дрейф (SORA-LEGACY-DRIFT.md, legacy-сторона)

Сверены все 6 «портировано» из §1 DRIFT — все подтверждены кодом, а не только
git log: (1) H6/M8 порты — в коде ✅; (2) SW1 obfs — `core/obfs` ✅ (частичность
задокументирована); (3) M10/L20 WFP — `guard/firewall_windows.go` `Disarm`
закрывает сессию только после успешного Close ✅; (4) fetch.sh `engines.sig`
enforcement ✅; (5) AmneziaWG-валидация, (6) mihomo AnyTLS — коммиты на ветке,
пакетные тесты зелёные ✅.

«Не портировано» (§2 DRIFT: F0–F11, SW2–SW7 кроме SW1, все TSPU-фиксы) —
подтверждено отсутствием `core/tune`, `core/censor`, `core/race`, `core/leak`
и соответствующих символов в финальном дереве. Дрейф структурный и
соответствует позиционированию legacy как «версии для старых систем» —
финальный аудит расхождений с документом не нашёл.

Android (LEGACY-H6/H7/H8/M12/M13): кода по-прежнему нет,
`docs/android-security-requirements.md` на месте — новая разработка,
действие владельца, не фикс.

## 4. Вердикт зоны

**Go core: PASS.** Build/vet чисты; тесты зелёны, единственное падение —
документированный env-кейс песочницы (не регрессия). Все фиксы аудита в
финальном виде на месте; регрессий от поздних волн не найдено.

**C# WinForms: PASS по вычитке, с обязательной оговоркой — НЕ СОБРАН**
(тулчейна в окружении нет). Синтаксическая целостность подтверждена
механически (105/105 файлов) и построчной вычиткой изменённых мест; все
аудит-фиксы в финальном виде. Сборка на dev-машине — обязательное условие
мержа.

**Процесс: ТРЕБУЕТСЯ ДЕЙСТВИЕ РОДИТЕЛЯ** — снять staged-откат A20-фиксов из
индекса (7 файлов, см. оговорку в шапке) до любых коммитов на ветке, иначе
первый же голый `git commit` параллельного агента его закоммитит.

Кодовых фиксов в этом проходе не потребовалось — коммитов `[final-audit]`
не сделано (нечего коммитить: финальные состояния всех фиксов уже на ветке).
