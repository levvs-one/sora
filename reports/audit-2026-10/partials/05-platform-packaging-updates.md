# Этап 5/5 — Аудит платформ, установки, обновлений и цепочки поставки

**Объект:** `~/workspace/bug-hunt/sora` (VPN/proxy-клиент: Flutter UI + Go-ядро sora-core; Windows, Linux).
**Зона:** `packaging/` (целиком), `service/linux/`, `app/windows/`, `app/linux/`, `core/cmd/sora-core/`,
`third_party/`, `proto/`, `docs/`, `core/engine/catalog*.go` + `core/engine/supervise/binary.go` + `core/engine/registry/`
(происхождение бинарников движков), механизм автообновлений (`app/lib/src/updates.dart`, `app/lib/src/desktop/desktop.dart`).

## Методология

1. Прочитаны целиком: `packaging/engines/engines.lock`, `packaging/engines/fetch.sh`,
   `packaging/install/install.sh`, `packaging/install/install.ps1`, `packaging/linux/sora-update`,
   `packaging/linux/nfpm.yaml`, `packaging/linux/nfpm-app.yaml`, `packaging/linux/scripts/*.sh`,
   `packaging/linux/io.github.levvs-one.sora.update.policy`, `packaging/windows/sora.iss`,
   `packaging/zapret/build.sh`, `service/linux/sora-core.service`, `service/linux/sora.policy`,
   `service/linux/sora.sysusers`, `core/cmd/sora-core/{main,cli,check,service_windows,service_other,platform_windows,platform_other}.go`,
   `core/engine/catalog.go`, `core/engine/catalog_linux.go`, `core/engine/registry/registry.go`,
   `core/engine/supervise/binary.go`, `core/engine/supervise/host.go`,
   `app/lib/src/updates.dart`, `app/lib/src/desktop/desktop.dart` (launchUpdate/restartAfterUpdate),
   `docs/install.md`, `packaging/windows/README.md`, `packaging/linux/README.md`, `service/linux/README.md`,
   `app/windows/runner/runner.exe.manifest`, `packaging/linux/test_update.py` (частично).
2. Grep по паттернам: `InsecureSkipVerify` (нет, кроме корректного `tls.Config` в `core/probe/probe.go:194`
   с включённой верификацией), `http://` (только loopback-контроллеры движков — не баги),
   `sha256|checksum|signature|gpg|cosign`, `chmod +x`, `sudo`, `User=`, `ExecStart`,
   `AmbientCapabilities`, `0o777`, `curl|sh`, `LoadLibrary` (нет), `setuid` (нет), `runas` (только
   легитимный `runasoriginaluser` в .iss).
3. Проверены: CI-воркфлоу релиза (`.github/workflows/repository.yml`) на предмет подписи артефактов,
   происхождение вендоренных бинарников (`git ls-files`), вызываемость `VerifyDigest` (мёртвый код).
4. Каждая находка ниже проверена чтением окружающего кода; спекулятивные пункты отброшены или помечены.

**Что проверено и признано корректным (защита в глубину на месте):**
- `sora-update`: санитизация `PATH`, `umask 077`, валидация версии regex, отказ от symlink в source
  (`cp -P` + повторная проверка), `mktemp -d` от root, сверка SHA256, сверка метаданных пакета
  (имя/версия/архитектура через `dpkg-deb`/`rpm -qp`/`pacman -Qp`), привязка polkit-действия к
  `org.freedesktop.policykit.exec.path=/usr/lib/sora/sora-update`, `auth_admin` без сохранения.
- `install.sh`/`install.ps1`: `--proto '=https'`, `--tlsv1.2`, сверка с `SHA256SUMS` до установки/запуска.
- `updates.dart`: строгая валидация `SoraRelease.parse` (draft/prerelease отбрасываются, URL ассета обязан
  в точности равняться `$repo/releases/download/$tag/$name`, ровно один хэш на файл), потоковая сверка
  SHA256 до передачи в привилегированный helper, downgrade-гейт `newerRelease` в UI.
- `fetch.sh`: сначала скачивание → `sha256sum --check` → только потом распаковка (verify-before-extract),
  `--proto '=https'`.
- systemd-юнит: `User=sora`, `ProtectSystem=strict`, `NoNewPrivileges=yes`, `AmbientCapabilities` только
  `CAP_NET_ADMIN/CAP_NET_BIND_SERVICE/CAP_NET_RAW`, `DevicePolicy=closed`, `RestrictSUIDSGID` и др.;
  `secureDataDir` на Windows переименовывает предсозданный недоверенный data-dir и ставит DACL только
  для SYSTEM/Administrators.
- `SafeEnv()` (`core/engine/supervise/host.go:104`) вычищает proxy-переменные и секреты из окружения
  дочерних движков; `SafeEnv` + случайный секрет контроллера (`RandomSecret`).

---

## Находки

### 1. [High] Цепочка поставки: релизные артефакты и SHA256SUMS не имеют никакой подписи — вся проверка целостности сводится к TLS + хэшам
**Категория:** supply chain / update integrity
**Файлы:**
- `packaging/README.md:11` — «Установщик и пакеты пока не подписаны.»
- `.github/workflows/repository.yml:512-516` — CI генерирует `SHA256SUMS` обычным `sha256sum`, без
  `gpg --detach-sign` / minisign / cosign / SLSA-аттестации; `gh release create` без attest.
- `packaging/install/install.sh:84-100`, `packaging/install/install.ps1:33-42` — сверка только с
  неподписанным `SHA256SUMS`.
- `app/lib/src/updates.dart:104-109` (`verifyUpdateFile`) — сверка только SHA256.
- `packaging/linux/sora-update:55-70` — сверка только SHA256.
- `docs/install.md:26` — признание: «Установщик не подписан сертификатом».

**Почему это баг:** SHA256 защищает от случайной порчи, но не от компрометации: любой, кто может
подменить релизные ассеты (взлом GitHub-аккаунта мейнтейнера, злонамеренный инсайдер, MITM с валидным
сертификатом — реалистично для VPN-клиента обхода блокировок), просто перегенерирует `SHA256SUMS`
вместе с бэкдорными бинарниками, и все проверки (`install.sh`, `install.ps1`, `sora-update`,
встроенный апдейтер) пройдут. То же касается бутстрапа `curl …/install.sh | sh`
(`docs/install.md:43`, `README.md:27`) и `irm …/install.ps1 | iex`: сам скрипт-установщик без подписи.
Дополнительно: `zypper --allow-unsigned-rpm` в `packaging/install/install.sh:110` и
`packaging/linux/sora-update:82` — установка неподписанных RPM как норма.

**Сценарий:** атакующий публикует (или подменяет через скомпрометированный аккаунт) релиз с
бэкдором в `sora-core`/движке и корректным `SHA256SUMS`. Все пользователи, нажавшие «Обновить» или
выполнившие one-line install, получают бэкдор с правами администратора/root без единого предупреждения.
Для клиента, чья угрозная модель включает state-level adversary, это главный вектор массовой компрометации.

**Фикс:** подписать `SHA256SUMS` офлайн-ключом (minisign — один файл, удобно для скриптов), вшить
публичный ключ в `install.sh`/`install.ps1`/`updates.dart`/`sora-update` и проверять подпись до сверки
хэшей; подписать Windows-установщик Authenticode-сертификатом (`SignTool` в `sora.iss`); добавить
SLSA/GH-attestations в CI; задокументировать ротацию ключей.

---

### 2. [Medium] Движки — сторонние сборки (включая форк), «проверка» лишь сверяет дайджест с тем, что опубликовал сам апстрим
**Категория:** supply chain / third-party binaries
**Файлы:** `packaging/engines/engines.lock:1-12`, `packaging/engines/fetch.sh:27-28`.

**Почему это баг:** `sing-box` берётся из форка `Leadaxe/sing-box-lx` (не апстрим SagerNet), `xray` —
`XTLS/Xray-core`, `mihomo` — `MetaCubeX/mihomo`. Комментарий в lock-файле честно говорит: «The SHA-256 is
the digest GitHub publishes for the release asset» — т.е. дайджест доказывает лишь, что скачанное
совпадает с тем, что лежит на GitHub у третьей стороны, но не то, что бинарь собран из заявленных
исходников и не содержит бэкдора. Подписи апстрима (cosign/sigstore, `.sig`/`.pem` файлы релизов) не
проверяются нигде; reproducible-build сверка отсутствует. Это движок VPN-трафика — идеальное место для
закладки (весь трафик пользователя проходит через него).

**Сценарий:** компрометация релиза/аккаунта одного из трёх апстримов (или вставка бэкдора мейнтейнером
форка `sing-box-lx`) → `fetch.sh` скачает вредоносный движок, хэш совпадёт с lock-файлом, CI упакует его
во все дистрибутивы. Обнаружение — только ручным реверсом.

**Фикс:** проверять подписи апстримов там, где они есть (у Xray к релизам прилагаются `.dgst`-файлы —
уже упомянуто в lock-файле, но не используется для верификации подписи); для форка `sing-box-lx`
зафиксировать решение о доверии письменно (почему форк, кто мейнтейнер, какой коммит соответствует);
в идеале — собирать движки из исходников в CI или сверять с reproducible builds.

---

### 3. [Medium] Рантайм-проверка целостности бинарников движков отсутствует: `VerifyDigest` — мёртвый код, а комментарий утверждает обратное
**Категория:** supply chain / runtime integrity
**Файлы:** `core/engine/supervise/binary.go:82`, `core/engine/supervise/binary.go:115-128`.

**Почему это баг:** Комментарий к `Discover` (строка 82) гласит: «It does not download; the updater ships
engines and verifies checksums.» — но никакого «updater», вызывающего `VerifyDigest` (строки 115–128),
в `core/` и `app/lib` нет (проверено grep'ом — ноль вызывающих). То есть на машине ядро исполняет первый
подошедший бинарь из `enginesDir`, `PATH` (`exec.LookPath`, `binary.go:95`) или env-переопределений
`SORA_SINGBOX_BIN` / `SORA_XRAY_BIN` / `SORA_MIHOMO_BIN`, прошедший лишь «пробу» — запуск с аргументами
`version` и парсинг stdout по regex. Любой исполняемый файл, печатающий похожую строку версии,
будет запущен: на Windows — как сервис `SoraCore` под LocalSystem, на Linux — с `CAP_NET_ADMIN` и
доступом к `/dev/net/tun`. Сегодня единственная защита — ACL каталогов (`Program Files`, `/usr/lib/sora`).

**Сценарий:** локальный атакующий (или вредонос), получивший запись в каталог движков из-за
некорректных прав после ручной установки / восстановления из бэкапа, подменяет `sing-box` на свой
бинарь, печатающий `sing-box version 1.14.3` — ядро запускает его с системными привилегиями при следующем
подключении. Подмена также переживает обновления, т.к. сверки дайджеста нет.

**Фикс:** вшить ожидаемые дайджесты из `engines.lock` в сборку ядра (генерация Go-файла в CI или
`ldflags`) и вызывать `VerifyDigest` в `Discover` для бинарей из `enginesDir`; для ручных запусков
оставить env-override, но логировать digest mismatch как ошибку, а не молча пропускать; убрать/исправить
вводящий в заблуждение комментарий.

---

### 4. [Low] Защита от downgrade — только в UI-слое; привилегированный helper примет любую корректную версию
**Категория:** update integrity / downgrade
**Файлы:** `packaging/linux/sora-update:13` (валидация только формата `x.y.z`), `app/lib/src/updates.dart:36-40`
(`newerRelease` — единственное место сравнения версий).

**Почему это баг:** `sora-update` проверяет, что версия — это `x.y.z`, но никогда не сравнивает её с
установленной. `apt-get install -y /var/tmp/…/sora_1.0.4_amd64.deb` / `dnf` / `pacman -U` примут и более
старый пакет. Сегодня downgrade невозможен только потому, что единственный вызывающий (приложение)
предварительно проверяет `newerRelease`. Любой будущий вызывающий helper'а или прямой вызов через
`pkexec /usr/lib/sora/sora-update …` (требует пароль админа, но это легитимный ручной сценарий)
сможет откатить пару пакетов на уязвимую версию без предупреждений.

**Сценарий:** злоумышленник с разовым доступом к разблокированной машине администратора (или
социнженерия «запустите эту команду для отката») выполняет откат на версию с известной уязвимостью;
пользователь не получает никакого предупреждения.

**Фикс:** в `sora-update` сравнивать запрошенную версию с установленной (`dpkg-query -W -f='${Version}'`,
`rpm -q --qf '%{VERSION}'`, `pacman -Q`) и отказываться от downgrade без явного флага
(e.g. `--allow-downgrade`); дублировать проверку `newerRelease` на стороне helper'а.

---

### 5. [Low] Windows-установщик не подписан: нет `SignTool` в `sora.iss`, нет identity издателя
**Категория:** packaging / code signing
**Файлы:** `packaging/windows/sora.iss` (вся секция `[Setup]` — директива подписи отсутствует),
`docs/install.md:26`, `packaging/windows/README.md` («Установщик не подписан, SmartScreen показывает
предупреждение»).

**Почему это баг:** без Authenticode-подписи у установщика нет криптографической привязки к издателю:
пользователь не может отличить официальный билд от пересобранного с бэкдором (SmartScreen-варнинг
учит пользователей кликать «всё равно запустить», что нивелирует и защиту от подмен). Для ПО, которое
ставится с правами администратора и регистрирует системную службу, это базовый гигиенический провал
(признанный самими авторами, но не исправленный).

**Сценарий:** фишинговая копия сайта/релиза с «Sora-Setup» без подписи — пользователь, привыкший к
SmartScreen-варнингу и на официальном файле, не заметит разницы.

**Фикс:** приобрести/получить кодовый сертификат (или Azure Trusted Signing), добавить `SignTool` в
CI-сборку `sora.iss`; публиковать отпечаток сертификата для ручной проверки.

---

### 6. [Low] Неквотированный ImagePath службы Windows возможен: путь создания сервиса делегирован x/sys, путь обновления — квотируется (несогласованность)
**Категория:** platform / privilege escalation hardening
**Файлы:** `core/cmd/sora-core/service_windows.go:133` (`m.CreateService(serviceName, exe, config, arguments...)`)
vs `:128` (`current.BinaryPathName = windows.ComposeCommandLine(...)`).

**Почему это баг (с оговоркой):** путь обновления существующей службы явно квотируется через
`windows.ComposeCommandLine`, а путь создания новой службы передаёт «голый» `exe`
(`C:\Program Files\Sora\core\sora-core.exe` — содержит пробелы) в `mgr.CreateService` из
`golang.org/x/sys v0.48.0`; квотирование ImagePath в этом случае полностью зависит от поведения
библиотеки, исходники которой в данном окружении проверить не удалось. Классическая проблема
unquoted service path: Windows пробует `C:\Program.exe`, `C:\Program Files\Sora.exe` и т.д. При
стандартных ACL `Program Files` записать туда может только администратор, поэтому практическая
эксплуатируемость низкая — но несогласованность двух веток одного файла подозрительна и легко
устранима.

**Сценарий:** на машине с ослабленными ACL (пользовательская установка в каталог с правом записи,
перенесённый `Program Files`) локальный пользователь кладёт свой exe по одному из «промежуточных»
путей → выполнение как SYSTEM при старте службы.

**Фикс:** в обеих ветках явно задавать `config.BinaryPathName = windows.ComposeCommandLine(append([]string{exe}, arguments...))`
и не полагаться на поведение `CreateService`; добавить CI-проверку `sc.exe qc SoraCore` на кавычки
(в workflow уже есть `sc.exe qc` — `repository.yml`, расширить assert'ом).

---

### 7. [Low] Секреты остаются на диске после удаления программы
**Категория:** platform / privacy
**Файлы:** `docs/install.md:34` («Данные в `C:\ProgramData\Sora` остаются, их можно удалить вручную»);
`packaging/linux/scripts/postremove.sh` (весь файл — чистит только nftables-таблицу, `/var/lib/sora`
с `StateDirectory=sora` остаётся).

**Почему это баг:** после удаления VPN-клиента на диске остаются зашифрованные подписки/токены/ключи
(DataDir: `%ProgramData%\Sora`, `/var/lib/sora` с `0700`). Шифрование — DPAPI/file-protector, но сам
факт использования VPN, подписки и токены переживают «удаление», что неожиданно для пользователя и
плохо для threat model обхода цензуры (форензика диска показывает использование VPN-клиента).

**Сценарий:** пользователь удаляет Sora перед проверкой устройства; экспертиза находит
`control.token`/секреты подписок в `%ProgramData%\Sora` или `/var/lib/sora`.

**Фикс:** Windows — спросить при деинсталляции и/или добавить `[UninstallDelete] Type: filesandordirs;
Name: "{commonappdata}\Sora"`; Linux — удалять `/var/lib/sora` при purge (`postremove` с проверкой
аргумента `purge`/0) и задокументировать; как минимум явно предупреждать в UI деинсталлятора.

---

### 8. [Low] Предсобранные бинарные блобы в репозитории без зафиксированного происхождения
**Категория:** supply chain / vendored binaries
**Файлы:** `third_party/zapret/nfq/windows/windivert/libwindivert32.a`,
`third_party/zapret/nfq/windows/windivert/libwindivert64.a`,
`third_party/zapret/nfq/windows/res/{32,64}/winicon.o`, `winmanifest.o` (все — в git, см. `git ls-files`).

**Почему это баг:** в дереве лежат скомпилированные статические библиотеки WinDivert и объектные файлы
без указания точной версии апстрима, хэша и способа воспроизведения. Сейчас они не используются
(zapret на Windows «пока не встроен», `packaging/windows/README.md:28`; `build.sh` собирает только
Linux-бинари из исходников), но лежат в supply chain репозитория и однажды могут быть слинкованы
«как есть».

**Сценарий:** при включении zapret на Windows кто-то слинкует эти `.a` без проверки — в итоговый
дистрибутив попадёт непроверенный бинарный код с правами сетевого драйвера.

**Фикс:** зафиксировать происхождение (апстрим, версия, SHA256, как воспроизвести) в
`third_party/zapret/` README/`.gitattributes`-комментарии, либо удалить блобы и скачивать/собирать
WinDivert при сборке с проверкой хэша.

---

## Покрытие по директориям

| Директория | Статус |
|---|---|
| `packaging/` (README, engines, install, linux, windows, zapret) | ✅ полностью, находки 1, 2, 4, 5, 8 |
| `service/linux/` (unit, polkit, sysusers) | ✅ полностью, юнит закалён; находок нет |
| `app/windows/`, `app/linux/` (runner, CMake) | ✅, находок нет (манифест без `requestedExecutionLevel` — корректно: повышение только через установщик) |
| `core/cmd/sora-core/` | ✅ полностью, находка 6 (+7 частично) |
| `third_party/` | ✅, находка 8; zapret собирается из исходников в CI (`build.sh`) — корректно |
| `proto/` | ✅, контракт версионирован (`Version{Major:1, Minor:7}` в `main.go`, `proto/README.md`) — находок нет |
| `docs/` | ✅, `install.md`/`development.md`: `curl|sh` — официальный способ, скрипты сами сверяют хэши (риск — следствие находки 1); опасных советов не найдено |
| `core/engine/catalog*.go` + registry/supervise | ✅, находки 2, 3 |
| Механизм обновлений (app + движки) | ✅ `app/lib/src/updates.dart`, `desktop.dart`, `sora-update`, `install.*`; движки отдельно не автообновляются — только в составе пакетов/установщика; downgrade-гейт только в UI (находка 4) |
| Android (манифест, разрешения, network security config) | ⚠️ **не покрыто**: `app/android/` отсутствует в репозитории — проверять нечего |

## ИТОГО: 8 находок (Critical: 0, High: 1, Medium: 2, Low: 5)

- **High (1):** №1 — неподписанные релизные артефакты и SHA256SUMS; вся цепочка доверия = TLS + хэши.
- **Medium (2):** №2 — движки из сторонних сборок/форка, проверка только по самопубликуемым дайджестам;
  №3 — `VerifyDigest` мёртвый код, рантайм-проверка целостности движков отсутствует вопреки комментарию.
- **Low (5):** №4 — downgrade-защита только в UI; №5 — неподписанный Windows-установщик (нет SignTool);
  №6 — возможный unquoted ImagePath службы (несогласованность веток, зависит от x/sys);
  №7 — секреты остаются после удаления; №8 — бинарные блобы WinDivert в репо без provenance.
