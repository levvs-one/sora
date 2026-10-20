# S3: Core ↔ пакеты + обновления

Кластер отдела совместимости стыков. Репозитории: `sora` и `sora-legacy`,
ветка `bugfix/audit-2026-10-19`. Метод: полный греп runtime-лукапов по
Go (`core/`, `service/`), Dart (`app/lib`), C# (`legacy/`) → сверка с
фактической поставкой (nfpm ×2, Inno Setup, zapret/engines build-скрипты,
CI `repository.yml` / `legacy.yml`, install-скрипты) → двусторонний дифф →
round-trip формата обновлений через все парсеры. Проверки скриптовые, без
полных сборок.

Вердикты: **СОВМЕСТИМ** (есть доказательство) / **РАЗРЫВ** (хеш фикса или
спека) / **НЕ ПРОВЕРЯЕМО ЗДЕСЬ** (причина).

---

## 1. Что код ищет на диске (инвентарь лукапов)

### 1.1 Go core (sora)

| Что | Кто ищет | Путь / источник | Фолбэк |
|---|---|---|---|
| `sing-box`, `xray`, `mihomo` (+`.exe` на Windows) | `core/engine/supervise/binary.go:Discover`, проберы в `singbox/xray/mihomo/engine.go` | `filepath.Join(enginesDir, name)`; `enginesDir` = флаг `-engines-dir` | env `SORA_SINGBOX_BIN`/`SORA_XRAY_BIN`/`SORA_MIHOMO_BIN` — **только** с флагом `-allow-env-bin`. PATH не консультируется никогда (SORA-H5) |
| `engines.digests` | `supervise.loadDigests` | `<enginesDir>/engines.digests`, формат sha256sum (`<hash>␣␣<name>`) | Нет: нет манифеста/записи → бинарь не исполняется (fail-closed) |
| `tpws` | `core/engine/registry/registry.go:Discover` | `<enginesDir>/tpws`, exec-бит + `VerifyNamedInDir` по `engines.digests` | Нет: не верифицирован → bypass честно недоступен |
| `nfqws` (Linux) / `winws.exe` (Windows) | тот же `registry.Discover` | `<enginesDir>/nfqws` / `<enginesDir>/winws.exe`, тот же digest-гейт | Нет (см. РАЗРЫВ-2 для Windows) |
| `zapret/fake/*.bin` | `registry` (`zapretAssets=<enginesDir>/zapret`), `bypass.NFQWSArgs`/`Args` | `<assets>/fake/<имя из стратегии>`; дефолт `quic_initial_www_google_com.bin` | `assets==""` → runtime-home движка (тесты) |
| `geoip.dat`, `geosite.dat` | `mihomo/engine.go:Prepare` (копирует `geoip.dat→GeoIP.dat`, `geosite.dat→GeoSite.dat` в home движка); Xray — из каталога своего бинаря | Каталог бинаря движка (`filepath.Dir(b.Path)`) | mihomo: отсутствие файла допустимо для планов без geo-правил; sing-box локальные `.dat` не использует (remote `.srs` rule sets, pinned в `singbox/render.go`) |
| `wintun.dll` | Прямого лукапа в Go **нет**: DLL грузят сами движки из каталога своих exe | Каталог движков на Windows | — (см. §3.2) |
| `nft`, `ip` | `guard/nftables_linux.go`, `engine/tunroute`, `engine/bypass/nfqws_linux.go` | Доверенные каталоги `/usr/sbin:/sbin:/usr/bin:/bin`, не PATH | Fail-closed, ошибка называет каталоги |
| `iw` | `profiles/fingerprint_linux.go` | Те же доверенные каталоги | Best-effort: нет `iw` → `SecurityUnknown`, не ошибка |
| polkit action `io.github.levvs-one.sora.read` / `.control` | `core/ipc/polkit_linux.go` (константы) | D-Bus polkit, файл политики — `/usr/share/polkit-1/actions/io.github.levvs-one.sora.policy` | Для систем без polkit — группа `sora` на сокете |
| Сокет управления | `core/ipc/ipc_unix.go` / `ipc_windows.go` | `/run/sora/core.sock` / `\\.\pipe\sora-core-v1` | Флаг `-socket` |
| Data dir: `control.token`, `secrets/`, `engine/<kind>/` (home движков, `cache.db` mihomo), `extensions/`, `custom/`, профили/подписки | `core/cmd/sora-core/{cli,main}.go` и пакеты | Флаг `-data-dir`; дефолт: env `SORA_DATA_DIR`, иначе `UserConfigDir()/sora/core`; `-engines-dir` по умолчанию `<dataDir>/engines` (не пакетный путь — сервисы обязаны передавать явно, что unit и ISS делают) | `./.sora-core` |
| Системные: `route.exe`, `netsh.exe` | `profiles/fingerprint_windows.go` | `%SystemRoot%\System32` | — |

### 1.2 Dart app (sora)

| Что | Кто | Путь | Фолбэк |
|---|---|---|---|
| Сокет/пайп ядра | `src/core/link.dart` | env `SORA_CORE_SOCKET`, иначе `/run/sora/core.sock` / `\\.\pipe\sora-core-v1` — совпадает с Go 1:1 | — |
| **`sora-sync`** | `src/sync_daemon.dart:resolveBinary` | Linux: `/usr/bin/sora-sync` (только этот путь); Windows: `<каталог sora.exe>\sora-sync.exe`; Android: нет | Нет → `SyncDaemonState.unavailable/binaryMissing`, UI честно говорит «переустановите приложение» |
| Интерфейс демона sync | тот же файл ↔ `service/sync/cmd/sora-sync/main.go`, `service/sync/api/daemon.go` | Спан с `--data-dir <dir>` (Go-флаг `data-dir` ✓); демон пишет `<dir>/http_addr`, `<dir>/api_token`; Dart читает те же имена, health-check `GET /v1/status` | Data dir Dart: `%APPDATA%\sora\sync` / `$XDG_DATA_HOME/sora/sync` / `~/.local/share/sora/sync` |
| `sora-update` helper | `src/updates.dart` (`updateHelper`) | `/usr/lib/sora/sora-update` | Нет pkexec/helper/policy → `manualCommand` (честный ручной путь) |
| Update polkit policy | `updates.dart` (`updatePolicy`, проверка существования в `_canElevate`) | `/usr/share/polkit-1/actions/io.github.levvs-one.sora.update.policy`; внутри annotate `exec.path=/usr/lib/sora/sora-update` | См. выше |
| `pkexec` | `updates.dart` | `/usr/bin/pkexec` (existence-check) | Ручная команда |
| Своё имя для package-owner запросов | `LinuxInstallation.detect` | `Platform.resolvedExecutable` = `/usr/lib/sora/app/sora` (симлинк `/usr/bin/sora` резолвится); запросы `dpkg-query -S` / `rpm -qf` / `pacman -Qoq` | — |
| Менеджеры/форматы | `updates.dart`, `desktop/system_proxy.dart`, `desktop/programs.dart` | `dpkg-query/rpm/pacman/dnf/zypper/apt-get` по PATH; `gsettings`, `kwriteconfig5/6` (+че
...[truncated 20048 chars]к существования `/usr/bin/kwriteconfig6`), `kreadconfig*`, `dbus-send` — инструменты DE | Ошибка → исключение с текстом stderr |
| Rollout feed | `updates.dart:rolloutPolicyUrl` | `https://raw.githubusercontent.com/levvs-one/sora/main/updates/releases.json` | Транспортная ошибка → legacy offer-all; битый/не тот релиз → fail-closed (§4) |

### 1.3 Legacy

- **Go core (legacy)** — та же схема, что 1.1, но манифест дайджестов называется
  **`SHA256SUMS`** (`core/engine/supervise/binary.go:digestManifestName`), env-оверрайд
  данных — `SORA_LEGACY_DATA_DIR`, на Windows пайп `\\.\pipe\sora-legacy-core-v1`,
  служба `SoraLegacyCore` (флаги `--install-service` с двойным дефисом).
  `verifyTpws` в `registry.go`: tpws проверяется по манифесту **только если записан**
  в нём; незаписанный — доверяется без проверки (см. РАЗРЫВ-6, исправлен).
  nfqws в legacy core **не ищется вообще** (ноль ссылок во всём `core/`).
- **C# тонкий клиент** (`legacy/Client`, `legacy/Control/CoreService.cs`): пайп
  `sora-legacy-core-v1`, проверка службы `SoraLegacyCore` через SCM — совпадает с Go.
- **C# v2rayN-форк** (`legacy/v2rayN`): `xray.exe`/`sing-box.exe` рядом с exe,
  `tun2proxy\wintun.dll` + `tun2proxy-bin.exe` + `tun2proxy.dll` + `udpgw-server.exe`
  (`Tool/TunModeController.cs`, `Tool/CommunityDiagnostics.cs`), `geoip.dat`/`geosite.dat`
  рядом с exe, автообновление гео-файлов по URL из `Global.cs`.

---

## 2. Что реально поставляется (по платформам)

### Linux, пакет `sora-core` (nfpm.yaml; deb/rpm/archlinux; amd64+arm64)

`/usr/bin/sora-core`; `/usr/lib/sora/engines/`: `sing-box`, `xray`, `mihomo`,
`geoip.dat`, `geosite.dat`, `engines.digests`, `tpws`, `nfqws`, дерево `zapret/fake/`;
`service/linux/sora-core.service` → systemd-unit; `sora.sysusers` → sysusers.d;
`service/linux/sora.policy` → polkit actions каталог; лицензии; скрипты
postinstall/preremove/postremove. Зависимости: nftables, iproute2,
libnetfilter-queue, zlib (+recommends polkitd/polkit).

Состав `dist/engines` производят: `packaging/engines/fetch.sh <arch>`
(скачивает по `engines.lock` с проверкой SHA-256 архивов и `engines.sig`,
раскладывает 3 движка + geo; на Windows-арках + `wintun.dll`; пишет
`engines.digests` по **бинарям**) и `packaging/zapret/build.sh`
(собирает tpws/nfqws из `third_party/zapret`, кладёт `zapret/fake/*.bin`,
**дописывает** дайджесты tpws/nfqws в `engines.digests`).

### Linux, пакет `sora` (nfpm-app.yaml; только amd64)

`/usr/lib/sora/sora-update` (0755); update polkit policy;
бандл Flutter → `/usr/lib/sora/app` (дерево); `/usr/bin/sora` → симлинк на
`/usr/lib/sora/app/sora` (имя бинаря бандла — `BINARY_NAME "sora"` в
`app/linux/CMakeLists.txt` ✓); `.desktop` (Exec=`sora %u`, Icon=
`io.github.levvs_one.sora`, MimeType sora://+happ://); SVG-иконка с тем же
именем; лицензии. Зависимости: `sora-core` той же версии, gtk/webkit/gstreamer
(+ после фикса S3: pkexec/polkit, minisign).

### Windows (sora.iss, x64)

`{app}` = бандл Flutter (`sora.exe` + assets: флаги/шрифты/трей — внутри бандла);
`{app}\core\sora-core.exe`; `{app}\core\engines\*` — плоская раскладка fetch.sh
windows-amd64: `sing-box.exe`, `xray.exe`, `mihomo.exe`, `geoip.dat`,
`geosite.dat`, `wintun.dll`, `engines.digests`; лицензии. Регистрация службы:
`sora-core.exe -install-service -data-dir "{commonappdata}\Sora" -engines-dir
"{app}\core\engines"` — ядро форвардит оба флага в сервис ✓. zapret на Windows
не поставляется (прямо сказано в packaging/windows/README).

### CI / релиз (repository.yml)

- `windows` job: core+engines+app+Inno → артефакт `sora-windows-x64` = `dist/Sora-Setup-*.exe`.
- `linux-packages` job (amd64+arm64): core, fetch, zapret build, nfpm; app — только amd64;
  артефакты `sora-linux-<arch>` = `dist/*.deb|*.rpm|*.pkg.tar.zst`.
- `release` job (только тег `v*`): скачивает `sora-*` артефакты в один `dist/`,
  добавляет `install.sh`/`install.ps1`, `sha256sum -- * > SHA256SUMS`,
  создаёт **draft** релиза из `dist/*`. `SHA256SUMS.minisig` CI **не** создаёт:
  владелец подписывает и догружает руками после key ceremony (fail-closed дизайн SORA-H1).
- **Ни один job не собирает `service/sync`** (нет `go build ./service/sync` нигде в CI).

### Legacy

- Linux `sora-core` (свой nfpm.yaml, только core-пакета): как выше, но манифест —
  `./dist/engines/SHA256SUMS` → `/usr/lib/sora/engines/SHA256SUMS` (пишет fetch.sh:
  sing-box/xray/mihomo/geoip/geosite), **без** app-пакета, без sora-update, без
  desktop/icon. До фикса S3 zapret build дайджесты tpws/nfqws в SHA256SUMS не дописывал.
- Windows: CI `legacy.yml` собирает Go-ядро (`sora-legacy-core-{x86,x64}.exe`,
  только CI-артефакты) и v2rayN-форк; установщик `legacy/installer/Sora.iss`
  ставит **только staged v2rayN-клиент**: `legacy/build/Stage-Release.ps1`
  собирает stage из `sora_<target>.exe`, `xray.exe`, `sing-box.exe` (сверка
  SHA-256 payload), `tun2proxy\{tun2proxy-bin.exe, tun2proxy.dll, udpgw-server.exe,
  wintun.dll}`, `geoip.dat`, `geosite.dat`, лицензий. Тонкий клиент и Go-ядро
  в stage/установщик **не попадают** (CI-артефакты для разработки).

---

## 3. Двусторонний дифф

### 3.1 Ищется, но не поставляется

**РАЗРЫВ-1 (главный): `sora-sync` не поставляется нигде.**
- Ищет: `app/lib/src/sync_daemon.dart:106-122` — Linux `/usr/bin/sora-sync`,
  Windows `<dir of sora.exe>\sora-sync.exe`. Бинарник существует:
  `service/sync/cmd/sora-sync` (отдельный Go-модуль `service/sync/go.mod`).
- Не поставляет: `packaging/linux/nfpm.yaml` (нет), `nfpm-app.yaml` (нет),
  `packaging/windows/sora.iss` (нет), `.github/workflows/repository.yml`
  (нет build-шага service/sync вообще). Итог: F9 sync на любой установленной
  системе недостижим, UI навсегда в `binaryMissing` («переустановите
  приложение» не помогает).
- Интерфейс при этом полностью согласован (флаг, `http_addr`, `api_token`,
  `/v1/status`, data-dir layout) — чинится только поставкой.
- **Спека фикса** (НЕ применён: размер пакета ~+7.7 MB — известное решение
  владельца): (a) CI: `cd service/sync && go build ./cmd/sora-sync` в linux
  (amd64; arm64 — по решению) и windows jobs; (b) Linux: запись в
  `nfpm-app.yaml` **или** `nfpm.yaml`: `./dist/sora-sync` → `/usr/bin/sora-sync`
  (0755) — Dart ищет именно в `/usr/bin`, не в `/usr/lib/sora`;
  (c) Windows: файл `sora-sync.exe` в `{app}` рядом с `sora.exe` (строка ISS
  `[Files]` из `dist\windows\sora-sync.exe`); (d) smoke: установленный пакет →
  `resolveBinary() != null` → демон отвечает на `/v1/status`.

**РАЗРЫВ-2: `winws.exe` (Windows NFQWS) — поиск без поставки и без дайджеста.**
- Ищет: `registry.go:96-105`: на Windows кандидат `<enginesDir>/winws.exe` с
  exec-битом и обязательным `VerifyNamedInDir(..., "winws.exe")`.
- Не поставляет: `engines.lock`/`fetch.sh` для `windows-amd64`/`win7-386`
  дают ровно 3 движка + wintun (expected=4); zapret Windows не собирается.
  WinDivert (драйвер/`.sys`+`.dll`, нужен winws) не упомянут нигде в поставке.
- Следствие: даже вручную подложенный `winws.exe` не пройдёт — в
  `engines.digests` нет ключа `winws`, discovery отклонит. На Windows
  `BypassBackends().nfqws` всегда false.
- Это задокументированный fail-closed (`bypass/nfqws_other.go`: «executor is
  not wired up yet, WinDivert step pending»), т.е. поведение честное, но шов
  разомкнут. **Спека** (когда дойдёт executor): строки winws+WinDivert в
  `engines.lock`/`engines.sig`, ветка в fetch.sh (expected 4→6), запись
  дайджестов winws/WinDivertDll, прогон `TestWindowsTun...`-класса тестов.

**РАЗРЫВ-3 (исправлен, `924f2201`): зависимости `sora-update` не объявлены.**
Хелпер жёстко требует `minisign` (`command -v minisign || die`) и запускается
через `/usr/bin/pkexec`; Dart `_canElevate` проверяет pkexec, но ни один пакет
не зависел ни от того, ни от другого (у core лишь `recommends: polkitd`, а
pkexec в Debian — отдельный пакет и не входит в polkitd). На чистой системе
обновление предлагалось и умирало внутри хелпера. Фикс: в `nfpm-app.yaml`
deb += `pkexec, minisign`; rpm += `polkit, minisign`; arch += `polkit, minisign`.

**РАЗРЫВ-4 (исправлен, `3860be97`): `install.sh` отвергал binary-mode SHA256SUMS** — см. §4.

**РАЗРЫВ-5 (legacy, спека): `nfqws` поставляется, но legacy-ядром не ищется.**
Legacy nfpm кладёт `/usr/lib/sora/engines/nfqws` и тянет зависимости
`libnetfilter-queue` именно под него (комментарий в nfpm), legacy zapret его
собирает — но в legacy `core/` **ноль** ссылок на nfqws: bypass только tpws
(`core/engine/bypass/bypass.go` — один файл, BackendOf/desync отсутствуют).
Мёртвый груз в пакете + лишняя системная зависимость. Варианты владельцу:
(a) убрать nfqws из legacy-пакета и build.sh (и пересмотреть depends), или
(b) портировать nfqws executor как в main. Не чинено: продуктовое решение,
пакетный состав legacy — не косметика.

**РАЗРЫВ-6 (legacy, исправлен `375cb10a` + `9fc03a7a`): tpws без дайджеста.**
Legacy `fetch.sh` пишет SHA256SUMS только по 5 файлам (движки+geo), zapret
build дайджесты не дописывал → строгая ветка `verifyTpws` никогда не
срабатывала, поставленный tpws исполнялся без проверки (в main тот же шов
закрыт дописыванием в `engines.digests`). Заодно: legacy
`packaging/zapret/build.sh` клал `$dest/zapret/LICENSE.txt`, который никто не
читает (nfpm ставит лицензию из third_party напрямую) — копия убрана, как в
main. И рецепт сборки в legacy `packaging/linux/README.md` не запускал
zapret build, хотя nfpm требует его выходы — шаг добавлен.

**РАЗРЫВ-7 (исправлен, `b14a97d7`): postremove не снимал `sora_nfqws`.**
Ядро при остановке снимает обе свои таблицы (`inet sora` kill switch и
`inet sora_nfqws` nfqws-перехватчика, `core/engine/bypass/nfqws_linux.go`),
а `packaging/linux/scripts/postremove.sh` — страховка на случай убитого
ядра — знал только `inet sora`. Убитое -9 ядро с активными nfqws-правилами
оставляло после удаления пакета правила, ведущие трафик в NFQUEUE без
слушателя. Добавлена симметричная строка `nft delete table inet sora_nfqws`.

**Мелочи (не разрывы, осознанные деградации):**
- `iw` не входит в зависимости пакета: Wi-Fi fingerprint молча даёт
  `SecurityUnknown`. Best-effort по дизайну; hard-dep ради подсказки — решение владельца.
- `gsettings`/`kwriteconfig*`/`dbus-send` — инструменты DE, не зависимости пакета;
  вызываются только на своём DE (system_proxy.dart).

### 3.2 Поставляется, но никем не ищется (мёртвый груз)

| Артефакт | Кто поставляет | Кто (не) ищет | Вердикт |
|---|---|---|---|
| `nfqws` в legacy-пакете | legacy nfpm+zapret | legacy core: ноль ссылок | РАЗРЫВ-5 |
| `wintun.dll` дайджест в `engines.digests` | fetch.sh (windows) | Ядро дайджест wintun не сверяет (нет VerifyNamedInDir-вызова); сама DLL потребляется движками неявно | Микро: запись манифеста без потребителя; безвредна, оставлена |
| `geoip.dat`/`geosite.dat` в legacy `SHA256SUMS` | legacy fetch.sh | Legacy supervise сверяет по манифесту только бинари движков; geo-записи не читает никто | Как выше, безвредно |
| Тонкий клиент legacy + `sora-legacy-core-*.exe` | CI legacy.yml (артефакты) | Установщик их не ставит; поставляемый клиент — v2rayN-форк | Наблюдение: у пары «тонкий клиент+ядро» нет пакетного маршрута, только dev-артефакты; если это осознанная стадия — ок |

Обратных мёртвых поставок в main-пакетах не найдено: каждый файл nfpm/ISS
имеет потребителя из §1 (unit→systemd, sysusers→systemd-sysusers,
policies→polkit по id из кода, desktop/icon→DE, лицензии→люди/лицензионная
гигиена). Все `src:` nfpm, указывающие в репозиторий (не в dist/build),
существуют — проверено скриптом по обоим nfpm и legacy.

### 3.3 Подтверждённо совместимые швы (доказательства)

- **Движки+манифест (main)**: fetch раскладывает ровно те имена, что ищет
  `Discover` (`sing-box/xray/mihomo[.exe]`), `engines.digests` пишется по
  бинарям и дописывается zapret-ом для tpws/nfqws; ядро без валидного
  дайджеста не исполняет. nfpm кладёт весь набор + манифест в
  `/usr/lib/sora/engines`, unit передаёт `-engines-dir` туда же. Windows:
  wildcard ISS покрывает плоскую раскладку incl. digests.
- **Geo**: Xray и geo лежат в одном каталоге (Xray резолвит assets от exe);
  mihomo `Prepare` копирует из каталога бинаря. Набор `.dat` в обоих пакетах есть.
- **zapret fake**: `third_party/zapret/files/fake/quic_initial_www_google_com.bin`
  (дефолт стратегии) существует; дерево ставится в `<engines>/zapret/fake`,
  `registry.zapretAssets` указывает туда же.
- **Ядро↔приложение**: сокет/пайп строки идентичны (Go↔Dart, main и legacy);
  polkit id в коде = id в поставляемых `.policy`; systemd `StateDirectory/
  RuntimeDirectory=sora` соответствуют `-data-dir /var/lib/sora` и
  `/run/sora/core.sock`. (Бонусный микро-разрыв на этом шве — postremove
  не снимал таблицу nfqws `inet sora_nfqws` — исправлен, см. РАЗРЫВ-7.)
- **sora-update по путям**: helper/policy/pkexec пути Dart = поставка
  nfpm-app = annotate внутри policy (три стороны, один путь).
- **Desktop**: Exec `sora` → `/usr/bin/sora` симлинк → бандл `sora`;
  Icon = имя SVG-файла в поставке; APPLICATION_ID CMake = basename desktop-файла.

---

## 4. Обновления: производство ↔ проверка

### 4.1 Имена артефактов: СОВМЕСТИМ (доказано записанным релизом)

Единая таблица имён (версия `X.Y.Z`, тег `vX.Y.Z`):

| Артефакт | Производит | Ищут-проверяют |
|---|---|---|
| `sora-core_X.Y.Z_amd64.deb`, `sora_X.Y.Z_amd64.deb` | nfpm deb, SORA_ARCH=amd64 | Dart `filenames(deb)`, sora-update (deb), install.sh (apt) |
| `sora-core-X.Y.Z-1.x86_64.rpm`, `sora-X.Y.Z-1.x86_64.rpm` | nfpm rpm (amd64→x86_64) | Dart, sora-update (rpm), install.sh (dnf/zypper) |
| `sora-core-X.Y.Z-1-x86_64.pkg.tar.zst`, пара app | nfpm archlinux | Dart, sora-update (arch), install.sh (pacman) |
| arm64 core-only: `_arm64.deb`, `-1.aarch64.rpm`, `-1-aarch64.pkg.tar.zst` | nfpm, SORA_ARCH=arm64 | install.sh (aarch64 ветка, with_app=no); Dart N/A — приложения на arm64 нет |
| `Sora-Setup-X.Y.Z-x64.exe` | ISS `OutputBaseFilename=Sora-Setup-{#AppVersion}-x64` | Dart (windows names), install.ps1, CI windows job |
| `SHA256SUMS`, `SHA256SUMS.minisig`, `install.sh`, `install.ps1` | release job (+minisig — владелец) | все потребители ниже |

Доказательство: `app/test/fixtures/releases/SHA256SUMS` — записанный манифест
реального релиза 1.0.5 — содержит все 12 пакетных имён выше ровно в этих
формах (включая обе aarch64-формы); `app/test/updates_test.dart` гоняет по
нему `SoraRelease.parse` записанного `latest.json` и проверяет, что каждый
`LinuxInstallation.filenames()` и `Sora-Setup-…` находится среди ассетов.
Версии: единый источник — тег (CI) / pubspec (локальные рецепты README);
трёхчастный semver enforce-ится и Dart-парсером релиза, и regex-ом sora-update.

### 4.2 Формат SHA256SUMS: round-trip

Производитель (все три места): `sha256sum -- * > SHA256SUMS`
(release job), `sha256sum -- *` в install-test, PowerShell
`"<hash-lower>␣␣<name>"` (windows job) → текстовый формат
`<64-hex lower>␣␣<name>\n`.

Потребители и результат прогона формата производителя через каждый парсер
(скрипт в рамках этой проверки, фикстуры в /tmp):

| Парсер | Text mode `␣␣` | Binary mode `␣*` | Как проверено |
|---|---|---|---|
| Dart `expectedHash` (`^([a-fA-F0-9]{64}) [ *](.+)$`, дубль→ошибка) | ✓ | ✓ | Существующий `updates_test.dart` по записанному манифесту + экв. регэксп в прогоне |
| `sora-update` (awk: `substr($0,67)`, tolower, count==1 иначе die; потом `sha256sum -c`) | ✓ | ✓ | Прогон точного awk по фикстуре; полный `test_update.py` — НЕ ПРОВЕРЯЕМО ЗДЕСЬ (нет bwrap в VM; CI гоняет) |
| `install.ps1` (`^([0-9a-f]{64})\s+\*?name$`) | ✓ | ✓ | Эквивалент паттерна в прогоне; pwsh в VM нет |
| `install.sh` (`grep -E "  \*?name$"`) | ✓ | **✗ до фикса** | Прогон: text OK, binary FAIL; после фикса обе формы + `sha256sum -c` проходят |

**РАЗРЫВ-4 (исправлен, sora `3860be97`)**: install.sh требовал два пробела
перед необязательной `*`: строка бинарного формата (`<hash> *<name>`, её дают
`sha256sum -b` и Windows-генераторы манифестов) не матчилась, хотя остальные
три читателя её принимают (Dart-тест прямо закрепляет ` *install.sh` как
валидный вход). Текущий производитель бинарный формат не эмитит, поэтому
разрыв латентный: первый же манифест, собранный не GNU-`sha256sum`, ломал
только install.sh. Паттерн заменён на `" [ *]name$"`; `sha256sum -c` на
выходе обе формы парсит сам.

Подпись: `.minisig` — stock minisign по SHA256SUMS. Проверяют как root/при
установке: sora-update, install.sh, install.ps1 (у всех один embedded
pubkey-слот, сейчас placeholder → fail-closed до key ceremony — это
задокументированный дизайн SORA-H1, не разрыв шва). Dart в приложении
подпись **не** проверяет и UI этого не утверждает (комментарий в
`UpdateStage`); Windows in-app путь Dart заблокирован целиком
(`UpdateError.signatureRequired`) до появления ключа — согласовано с
политикой. Откат (S11b) переиспользует те же имена/манифест/helper с
`--allow-downgrade` — формат пары «текущий релиз» берётся из того же
`releases/tags/v<from>` API, шов симметричен прямому обновлению.

Rollout feed: `updates/releases.json` в репозитории соответствует строгой
схеме Dart `RolloutPolicy.parse` (format=1, rollout.version/percent,
blocked_versions) — проверено скриптом по живому файлу.

### 4.3 НЕ ПРОВЕРЯЕМО ЗДЕСЬ

- `packaging/linux/test_update.py` целиком: нужен `bwrap`+user namespaces,
  в VM отсутствует (CI job `app` его гоняет). Логика хелпера сверена чтением
  + точным awk-прогоном выше.
- Реальные имена файлов nfpm: nfpm в VM не установлен; имена доказаны
  записанным релизным манифестом (§4.1), а не локальной сборкой пакетов.
- Inno Setup компиляция/установка и PowerShell-парсер: нет Windows/pwsh.
- Настоящий minisign sign→verify round-trip: minisign не установлен, ключ —
  placeholder по дизайну; CI делает это эфемерным ключом в install-тестах.

---

## 5. Свои коммиты

sora (`bugfix/audit-2026-10-19`, не запушено):
- `3860be97` — [seams-s3] install.sh: binary-mode SHA256SUMS (РАЗРЫВ-4).
- `924f2201` — [seams-s3] nfpm-app: pkexec+minisign в зависимости (РАЗРЫВ-3).
- `b14a97d7` — [seams-s3] postremove: снятие таблицы `sora_nfqws` (РАЗРЫВ-7).

sora-legacy (`bugfix/audit-2026-10-19`, не запушено):
- `375cb10a` — [seams-s3] legacy zapret: дайджесты tpws/nfqws в SHA256SUMS,
  убран мёртвый LICENSE (РАЗРЫВ-6).
- `9fc03a7a` — [seams-s3] legacy linux README: шаг zapret build в рецепте (РАЗРЫВ-6).

Открытые спеки без фиксов: РАЗРЫВ-1 (sora-sync — решение владельца по
размеру пакета), РАЗРЫВ-2 (winws — ждёт executor/WinDivert), РАЗРЫВ-5
(legacy nfqws — продуктовое решение). Чужие грязные файлы не трогались:
все правки — по предварительно проверенным `git status` чистым файлам,
коммиты — temp-index+CAS, `git show --stat` после каждого показывает ровно
один файл.
