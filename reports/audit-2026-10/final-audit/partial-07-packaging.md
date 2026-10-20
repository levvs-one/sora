# Final audit — Zone 07: упаковка и релизный путь

- Репозиторий: `~/workspace/bug-hunt/sora`, ветка `bugfix/audit-2026-10-19` (грязное дерево, коммиты не делал — мелких безопасных фиксов в зоне нет, только спеки).
- Дата: 2026-10-20. Аудитор: subagent-07.
- Контекст: `FIX-REPORT.md` (H1), `POWER-RUN.md` (упаковка/обновления), `ANALYSIS-20.md` (19-release-pipeline), `OWNER-PLAYBOOK.md`.

## Что проверялось

`packaging/` (nfpm, Inno, `engines/engines.lock` + `engines.sig` + `fetch.sh`, `zapret/build.sh`, `install.sh`/`install.ps1`),
`.github/workflows/` (repository/security/autofix/utls-freshness), цепочка обновлений end-to-end
(`app/lib/src/updates.dart`, `packaging/linux/sora-update`, `updates/releases.json`, `docs/update-rollout.md`),
согласованность путей пакетов с путями в коде, версии (pubspec/engines.lock/APP_VERSION в CI).

Легенда доказательств: **[локально]** — выполнено на этой машине; **[вычитка]** — статический разбор кода/конфигов.

---

## Находки

### F-1 (High): `tpws` выполняется без проверки дайджеста — разрыв инварианта H5

**[вычитка]** `core/engine/supervise/binary.go::Discover` — комментарий: «Every candidate from the engines directory must match the digest in `engines.digests`; candidates that fail verification are rejected instead of executed (SORA-H5)». Это верно для sing-box/xray/mihomo. Но:

1. `core/engine/registry/registry.go::Discover` (стр. 77–84) находит `tpws` простым `os.Stat` + битом исполнения — **без чтения `engines.digests`**;
2. `packaging/engines/fetch.sh` пишет в `engines.digests` только sing-box/xray/mihomo (+ geo-базы); `packaging/zapret/build.sh` дайджесты `tpws`/`nfqws` не записывает;
3. `nfqws` вообще не резолвится кодом (backend «not wired up yet», `bypass.go:249`, fail-closed — это честно).

Смягчающий фактор: `/usr/lib/sora/engines` root-owned, подменить tpws без root нельзя. Поэтому не Critical, но инвариант «ядро не выполняет непроверенные бинари из своего каталога» частично ложен. `go vet` по `engine/{supervise,registry,bypass}` чистый **[локально]**.

**Спека фикса** (не делал: требует изменений в `fetch.sh` + `build.sh` + `registry.Discover`/`supervise`, не «мелкий безопасный» фикс на грязном дереве):
- `packaging/zapret/build.sh`: после сборки дописывать `sha256(tpws)  tpws` и `sha256(nfqws)  nfqws` в `dist/engines/engines.digests` (формат `sha256sum`, как делает `fetch.sh`);
- `core/engine/supervise/binary.go`: экспортировать проверку дайджеста (`verifyPathDigest`/`loadDigests` сейчас приватны);
- `core/engine/registry/registry.go::Discover`: проверять `tpws` тем же путём, что и движки, — при несовпадении `r.tpws=""` (bypass честно недоступен, `BypassAvailable()` уже это учитывает);
- тест: `TestDiscoverVerifiesDigest`-style для tpws (подмена байта → `BypassAvailable()==false`).

### F-2 (High): `wintun.dll` отсутствует в поставке Windows — гэп NET-RESEARCH P1-4 не закрыт

**[вычитка]** В `packaging/engines/fetch.sh`, `packaging/windows/sora.iss`, `nfpm.yaml` — ноль упоминаний `wintun`. `packaging/windows/README.md` прямо фиксирует: «Обход DPI без сервера (zapret) на Windows пока не встроен» (это про zapret, не wintun — но про wintun вообще нигде ничего). В `NET-RD-12-WINDOWS-WFP-WINTUN.md` это P1-4 (wintun.dll рядом с движками или честное ограничение).

Почему это важно: рендереры sing-box (`core/engine/singbox/render.go:901`) и mihomo (`core/engine/mihomo/rules.go:262`) по умолчанию выдают стек `mixed` (системный TCP-путь), а на Windows системный стек = WinTun-драйвер, которому нужен `wintun.dll` в каталоге загрузки. Дополнительно: даже если бы апстримные zip содержали `wintun.dll`, `fetch.sh` (ветка `windows-*`/`win7-*`) извлекает только `${engine}*.exe` (+ geo-файлы у xray) — всё остальное из архива отбрасывается.

Я **не проверял**, падает ли runtime на Windows без wintun (нужна машина с Windows; CI `windows`-job гоняет `TestWindowsTunSwitchesCarryTCPAndUDP` через установленные движки из `dist/windows/engines` — результат неизвестен без запуска CI).

**Спека фикса**:
- В `engines.lock` добавить строку вида `wintun windows-amd64 <sha256> https://www.wintun.net/builds/wintun-0.14.1.zip` (версию/хеш брать с официального сайта в момент внедрения — **не выдумывать**);
- `fetch.sh`: для `wintun` извлекать `wintun.dll` (x64) в `dist/engines/` рядом с `.exe` и записывать дайджест;
- `sora.iss`: `[Files]` уже берёт `dist\windows\engines\*` целиком — dll подхватится автоматически; ничего менять не надо (проверить, что Inno не фильтрует dll — не фильтрует);
- `registry.go`: `firewall_windows.go` уже ожидает wintun как IF_TYPE_PROP_VIRTUAL(53) — согласовать с докой;
- CI: в `windows`-job после установки проверить наличие `wintun.dll` в `{app}\core\engines` и прогон TUN-теста с системным стеком.

### F-3 (Medium): `engines.lock` держит `win7-386`-пины, у которых нет потребителя

**[локально]** Python-валидация `engines.lock`: формат `engine arch sha256 url` корректен на всех 12 строках, все хеши — 64 hex, все URL — `github.com`. Но `grep win7` по `.github/workflows/`, `packaging/` (кроме `fetch.sh` usage), `app/windows/` — пусто: ни один CI-job, ни один установщик `win7-386`-движки не собирает и не пакует. `sora.iss` ставит `MinVersion=10.0.17763` (Win10 1809+). Комментарий в lock-файле описывает назначение (Windows 7 SP1 32-bit), но в этом репозитории это мёртвый пин — вероятно, наследие/задел под sora-legacy.

**Спека**: либо добавить job/вариант установщика под Win7 (вряд ли — MinVersion и Flutter этого не хотят), либо убрать `win7-386`-строки из lock-файла с пометкой в README, что Win7 покрывает sora-legacy. Держать мёртвые пины = риск, что кто-то «обновит» их, не проверив сборку.

### F-4 (Low): `fake/`-каталог zapret пакуется, но код ищет его в другом месте

**[вычитка]** `nfpm.yaml` кладёт `./dist/engines/zapret/fake/` → `/usr/lib/sora/engines/zapret/fake`. Но `registry.go:200`: `bypass.Wrap(built, r.tpws, filepath.Join(r.base.HomeDir, "zapret"), …)`, где `HomeDir = DataDir/engine` (`main.go:198`) — т.е. fake-файлы резолвятся в `/var/lib/sora/engine/zapret/fake`, который никогда не наполняется. Сейчас безвредно: `tpws`-путь (`bypass.Args`) fake-файлы не использует, а `nfqws`-путь (`NFQWSArgs`, `bypass.go:73-108`) fail-closed «not wired up yet». При внедрении nfqws по `NFQWS-MIGRATION.md` это станет реальным багом.

**Спека**: при вайринге nfqws — либо копировать `fake/` из engines dir в `$DataDir/engine/zapret/fake` при старте (root → sora user), либо передавать в `Wrap` путь `/usr/lib/sora/engines` как home (но тогда home станет read-only root-owned — для tpws `Dir` это ок, т.к. tpws только читает; проверить `supervise.Spec.Dir` на запись логов).

### F-5 (Info): `sora-update` чтит `SORA_MINISIGN_PUBKEY` из окружения

**[вычитка]** `packaging/linux/sora-update`: `SORA_RELEASE_PUBKEY=${SORA_MINISIGN_PUBKEY:-REPLACE-ME-AFTER-KEY-CEREMONY}`. Хелпер запускается через pkexec от root. На практике pkexec чистит окружение (сохраняет только белый список), так что непривилегированный пользователь подменить ключ не может; переопределение нужно CI-тесту (`test_update.py` запускает хелпер напрямую). Дизайн осознанный (тот же контракт у `install.sh`/`install.ps1`), но стоит зафиксировать в комментарии у строки: «pkexec не пропускает эту переменную от вызывающего; переопределение только для прямого запуска в тестах». Сейчас комментарий этого не говорит.

Фикс не делал: однострочный комментарий — тривиально, но на грязном дереве с конкурирующими агентами даже это лучше оставить владельцу/следующему проходу; заношу как рекомендацию.

### Что НЕ является проблемой (проверено)

- **Fail-closed при плейсхолдере ключа** — **[локально]** прогнал `verify_signature` из `sora-update` и `install.sh` с неустановленным `SORA_MINISIGN_PUBKEY`: оба умирают с `release signing is not configured yet … owner must complete the key ceremony` (exit 1), до любых сетевых/файловых операций. `install.ps1` — тот же шаблон (`Assert-ReleaseSignature` бросает на плейсхолдере), **[вычитка]**.
- **Порядок верификации** — во всех трёх точках (`sora-update`, `install.sh`, `install.ps1`) подпись `SHA256SUMS.minisig` проверяется **до** доверия любому хешу из манифеста; пакеты сверяются с подписанным манифестом; затем — метаданные пакета (имя/версия/архитектура через `dpkg-deb`/`rpm -qp`/`pacman -Qp`) — **[вычитка]**.
- **Downgrade-защита** — `sora-update` отказывает в даунгрейде без `--allow-downgrade` (сравнение с установленной версией), rollback S11b идёт через тот же хелпер с явным флагом — **[вычитка]**.
- **TOCTOU** — хелпер копирует файлы в приватный `mktemp -d /var/tmp`, отклоняет симлинки до и после копирования (`cp -P` + повторная проверка), `umask 077`, `PATH` зафиксирован — **[вычитка]**.
- **Движки не через PATH** (H5/NEW-1) — `supervise.Prober.Discover`: кандидаты только из `enginesDir` (+ опциональный `SORA_*_BIN` при явном `--allow-env-bin`); PATH не консультируется — **[вычитка]**.
- **Пины экшенов** — все `uses:` в 4 workflow привязаны к SHA (проверено `grep`, **[локально]**); unpinned-uses нет. `permissions:` минимальные (`contents: read` глобально; `write` только в `autofix` и `release`-job; `security-events: write` только в codeql-job). Секреты: `GITHUB_TOKEN` только там, где нужен (release draft, gitleaks, utls-check) — **[локально]**.
- **Версии согласованы**: `app/pubspec.yaml` = `1.0.12+13`; `updates/releases.json` → `rollout.version: 1.0.12`, `percent: 100` (релиз завершён); `APP_VERSION`/`SORA_VERSION` в CI читаются из `pubspec.yaml` (`grep '^version:' … cut -d+ -f1`) и прокидываются `--dart-define` в обоих `flutter build` (linux-packages и windows jobs) — **[локально]**.
- **Пути пакетов == пути в коде**: systemd-unit `/usr/lib/systemd/system/sora-core.service` запускает `/usr/bin/sora-core -data-dir /var/lib/sora -engines-dir /usr/lib/sora/engines` — совпадает с `nfpm.yaml` (`/usr/bin/sora-core`, `/usr/lib/sora/engines/*`, `engines.digests` рядом — требуется `supervise`); polkit-action `io.github.levvs-one.sora.policy` → `/usr/share/polkit-1/actions/`; `sora-update` + его policy — те же пути, что в `updates.dart` (`updateHelper`, `updatePolicy`); Windows: `{app}\core\engines\*.exe` + `-engines-dir` в `[Run]` — совпадает с `Discover` (`name + ".exe"`) — **[вычитка]**.
- **Права**: `sora-core`/`sora-update`/движки — 0755; geo-базы — 0644 (default); unit — 0644; sysusers/polkit — 0644; service `User=sora` + `AmbientCapabilities=CAP_NET_ADMIN…`, `NoNewPrivileges`, `ProtectSystem=strict` — **[вычитка]**.
- **Staged rollout/откат**: `updates/releases.json` (policy-only, fail-closed при malformed/version-mismatch, kill-switch через `blocked_versions`), S11b rollback-cache (пакеты прошлой версии качаются с GitHub, хеши сверяются с их SHA256SUMS, установка через хелпер с `--allow-downgrade`), health-check 60с с маркером `PendingUpdate` — **[вычитка]**; rollback-cache: комментарий в `install()` говорит «verified copies of the currently installed packages», фактически — скачанные пакеты *предыдущего релиза* с GitHub (не копия установленных). Мелкое расхождение комментария с реализацией, не поведение.
- **`install.sh` regex vs `sora-update` awk**: `install.sh` ищет пакет в SHA256SUMS через `grep -E`, `sora-update` — через точное сравнение `awk`. Коллизия в `install.sh` даёт лишнюю строку в `expected` → `sha256sum -c` падает → fail-closed. Не находка.
- **Windows in-app update**: заблокирован fail-closed (`UpdateError.signatureRequired`, `updates.dart:613-626`) — **[вычитка]**.
- `engines.sig`: `xray dgst-crosscheck`, `mihomo/sing-box none` — честно задокументировано как текущий статус апстримов — **[вычитка]**.
- `test_update.py` локально не запускается: нет `bwrap` (все 13 кейсов — `FileNotFoundError: bwrap`) — **[локально]**; покрытие остаётся за CI (`app`-job: `shellcheck` + `python3 test_update.py -v` в user-namespace). `sh -n` по `sora-update` и `install.sh` — чисто **[локально]**.

---

## Чек-лист «пакет → установленный продукт работает»

| # | Проверка | Статус | Доказательство |
|---|----------|--------|----------------|
| 1 | Все 4 workflow: экшены по SHA, минимальные права, секреты не светятся | **pass** | **[локально]** grep по `.github/workflows/*.yml`; `GITHUB_TOKEN` только в release/gitleaks/utls |
| 2 | `engines.lock`: формат, 3 движка × 4 арха, хеши 64-hex | **pass** | **[локально]** python-валидация |
| 3 | `fetch.sh` отказывает при несовпадении SHA-256; требует 3 движка на арх | **pass** | **[вычитка]** `sha256sum --check --strict`, `found -ne 3 → exit 1`; сигнатурная проверка `dgst-crosscheck` fail-closed |
| 4 | Плейсхолдер ключа → отказ, а не пропуск (sora-update, install.sh, install.ps1) | **pass** | **[локально]** выполнение `verify_signature` (exit 1, текст про key ceremony); install.ps1 — **[вычитка]** |
| 5 | Подпись SHA256SUMS проверяется до доверия хешам | **pass** | **[вычитка]** все 3 скрипта |
| 6 | sora-update: root-check, umask 077, фикс PATH, anti-symlink копирование, проверка метаданных пакета | **pass** | **[вычитка]** |
| 7 | Downgrade-защита в хелпере; rollback S11b через `--allow-downgrade` + health-check 60с | **pass** | **[вычитка]** |
| 8 | Staged rollout: policy feed fail-closed, kill-switch | **pass** | **[вычитка]** `updates.dart` + `docs/update-rollout.md` |
| 9 | Пути установки == путям в коде (движки, digests, geo, data-dir, polkit) | **pass** | **[вычитка]** nfpm.yaml ↔ cli.go/registry/supervise; sora.iss ↔ Discover |
| 10 | Движки резолвятся только из engines-dir, не из PATH | **pass** | **[вычитка]** `supervise.Discover` |
| 11 | Версии согласованы (pubspec 1.0.12+13 ↔ releases.json 1.0.12 ↔ CI dart-defines) | **pass** | **[локально]** |
| 12 | zapret: tpws/nfqws/fake в пакете; билд из вендоренного дерева | **pass (частично)** | **[вычитка]** nfpm.yaml + build.sh; но см. F-1 (tpws без дайджеста) и F-4 (fake не там ищется) |
| 13 | systemd unit/polkit/sysusers: права, capabilities, hardening | **pass** | **[вычитка]** |
| 14 | `wintun.dll` в Windows-поставке | **FAIL** | F-2: отсутствует везде, гэп P1-4 не закрыт |
| 15 | `test_update.py` зелёный | **не проверено локально** | нет `bwrap` на машине; остаётся за CI |
| 16 | win7-386 пины имеют потребителя | **fail (мёртвый пин)** | F-3 |
| 17 | Windows in-app update не обходит подпись | **pass** | **[вычитка]** fail-closed `signatureRequired` |

## Вердикт зоны

**Условный pass с двумя открытыми High.** Цепочка доверия обновлений (H1) спроектирована и реализована корректно: подпись до хешей, fail-closed на плейсхолдере (доказано выполнением), даунгрейд-защита, staged rollout с kill-switch, откат с health-check. Упаковка Linux согласована с кодом по путям и правам; CI покрывает сборку→установку→сервис→туннель на обеих платформах. Открыты: **F-1** (tpws без проверки дайджеста — разрыв инварианта H5, смягчено root-owned каталогом) и **F-2** (нет `wintun.dll` в Windows-поставке при системном TUN-стеке по умолчанию — гэп P1-4 из NET-RESEARCH не закрыт). Плюс F-3 (мёртвые win7-пины), F-4 (fake/ ищется не там, где лежит; безвредно пока nfqws не wired), F-5 (info). Фиксов не коммитил: безопасных однострочных правок в зоне нет, всё остальное — спеки выше. Дерево осталось нетронутым мной (грязные файлы — чужая конкурентная работа; `git status` не менял).
