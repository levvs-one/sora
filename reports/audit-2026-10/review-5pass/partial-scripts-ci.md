# 5-проходное ревью: скрипты, установщики, CI

Зона: `packaging/` и `.github/workflows/` обоих репозиториев + корневые скрипты.
Ветка `bugfix/audit-2026-10-19`, ничего не переключалось, ничего не пушилось.
Дата: 2026-10-19. Ревьюер: subagent 5-pass (зона scripts-ci).

## 1. Охват

Проверен каждый файл зоны × 5 проходов (безопасность, корректность, живучесть,
качество, системы). Непокрытых файлов нет.

**sora** (17 файлов):
`packaging/engines/fetch.sh`, `packaging/engines/engines.lock`,
`packaging/engines/engines.sig`, `packaging/install/install.sh`,
`packaging/install/install.ps1`, `packaging/linux/sora-update`,
`packaging/linux/test_update.py`, `packaging/linux/scripts/postinstall.sh`,
`packaging/linux/scripts/preremove.sh`, `packaging/linux/scripts/postremove.sh`,
`packaging/linux/nfpm.yaml`, `packaging/linux/nfpm-app.yaml`,
`packaging/linux/io.github.levvs-one.sora.update.policy`,
`packaging/linux/io.github.levvs_one.sora.desktop`,
`packaging/windows/sora.iss`, `packaging/zapret/build.sh`,
`.github/workflows/repository.yml`, `.github/workflows/security.yml`,
`.github/workflows/autofix.yml`. Корневых скриптов нет (проверено `find`).
READMEs зоны просмотрены на соответствие скриптам.

**sora-legacy** (11 файлов):
`packaging/engines/fetch.sh`, `packaging/engines/engines.lock`,
`packaging/engines/engines.sig` (новый), `packaging/linux/scripts/postinstall.sh`,
`packaging/linux/scripts/preremove.sh`, `packaging/linux/scripts/postremove.sh`,
`packaging/linux/nfpm.yaml`, `packaging/zapret/build.sh`,
`.github/workflows/legacy.yml`, `.github/workflows/security.yml`.
У legacy нет `install.sh`/`install.ps1`/`sora-update`/`.iss` — установщиков
одной командой там не существует, CI их не тестирует.

Инструментальная проверка: `bash -n` — все 12 shell-скриптов OK;
`python3 -m py_compile` — test_update.py OK; YAML всех 5 воркфлоу парсится
(PyYAML), job'ы на месте; `install.ps1` — внимательная вычитка (тулчейна нет,
страхует шаг PSScriptAnalyzer в CI).

## 2. Проверка fail-closed (minisign, SORA-H1) — ГЛАВНОЕ

Фикс H1 (коммит `31f9008`) **реален, а не декорация** — проверено исполнением,
а не чтением:

- `install.sh` с `SORA_DIST` и полным комплектом файлов, но плейсхолдером
  ключа: `sora: release signing is not configured yet: ...` → exit 1,
  **ничего не установлено, сеть не тронута**. Плейсхолдер проверяется
  ПЕРЕД любым копированием/установкой.
- Полный цикл с настоящим minisign 0.11 (бинарь из релиза jedisct1/minisign):
  `minisign -G -W` неинтерактивен; `sed -n '2p'` достаёт base64-ключ;
  реконструкция pub-файла как в install.sh + `minisign -V -q` → OK;
  подменённый файл → reject, rc=1.
- `sora-update`: логика идентична install.sh (case на плейсхолдер → die до
  любых операций с пакетами); minisign ищется в пинированном
  `PATH=/usr/sbin:/usr/bin:/sbin:/bin`, отсутствие → die.
- `install.ps1`: `Assert-ReleaseSignature` бросает на плейсхолдере и при
  отсутствии minisign в PATH; `$LASTEXITCODE` проверяется (native-команда
  не бросает сама при `$ErrorActionPreference='Stop'` — проверено чтением,
  обработка корректна).
- `fetch.sh` (sora): `dgst-crosscheck` для Xray прогнан против живого
  `.dgst` релиза v26.3.27 — хэш совпал с lock; подменённый дайджест —
  `engines.sig: lock digest ... does not match` → exit 1. Парсер
  `awk '/^SHA2-256=/ {print $2}'` соответствует реальному формату файла
  (`SHA2-256=  <hex>`).
- Порт в legacy fetch.sh прогнан так же: совпадение принято, подмена
  отвергнута.

**Но:** тот же fail-closed **сломал два CI-контракта**, которые фикс не
обновил (коммит `31f9008` тронул только 3 скрипта). Это находки R5-SC-2-1…
R5-SC-2-3 ниже — исправлены.

## 3. Находки по проходам

Формат: `ID`, Severity, файл:строки, суть, сценарий, исправление.

### Проход 1 — Безопасность

**R5-SC-1-1** — Medium — `sora/.github/workflows/{repository,security,autofix}.yml` —
незакреплённые экшены, `govulncheck@latest`, `curl|bash` для actionlint.
Тот же класс, что LEGACY-M8 (P1), который был исправлен **только** в legacy:
`grep -r "@v[0-9]"` в sora давал ~30 совпадений. Сценарий: компрометация
тега major-версии экшена → выполнение чужого кода в CI с `contents: read`
(и `write` в autofix/release). **Исправлено**: все `uses:` запинены по SHA
(те же SHAs, что в legacy, где применимо; остальные резолвлены через GitHub
API: download-artifact@9000827c, flutter-action@1a449444, setup-dart@6afc89df);
`govulncheck@latest` → `@v1.9.0`; actionlint — архив релиза с проверкой
SHA-256 (SHA независимо сверен скачиванием: совпал с пином legacy).
dependabot `github-actions` настроен — пины вида `# v6` он понимает.

**R5-SC-1-2** — Low — `sora/packaging/install/install.ps1:45` — latest релиза
через `api.github.com` (анонимный rate limit 60/час, на shared раннерах
реально исчерпывается), тогда как install.sh сознательно идёт через
`/releases/latest`-редирект («no API call, no rate limit»). Сценарий: пользователь
за корпоративным NAT ловит 403 rate-limited → непонятная ошибка.
**Не исправлено** (поведенческое решение): добавлен ретрай ×3 с backoff и
понятный текст ошибки; в комментарии зафиксировано расхождение.
Спека: унифицировать на редирект как в install.sh.

**R5-SC-1-3** — Medium — `sora-legacy/packaging/engines/fetch.sh` — фикс
SORA-M3 (проверка подписей апстримов через `engines.sig`) был применён
только к sora; legacy качал сторонние сборки по одному SHA-256 из lock.
**Исправлено**: создан `packaging/engines/engines.sig`
(xray — `dgst-crosscheck`, mihomo и SagerNet/sing-box — `none`; отсутствие
`.dgst`/подписей у SagerNet v1.14.2 проверено: 404 на `.dgst`, в списке
ассетов релиза подписей нет), в `fetch.sh` портированы
`signature_method`/`verify_upstream_signature` с fail-closed. Проверено
против живого `.dgst` Xray.

**R5-SC-1-4** — Info — `sora/.github/workflows/repository.yml` (release job):
релизный `SHA256SUMS` публикуется **без** `SHA256SUMS.minisig`, а install.sh/
install.ps1 требуют его наличия. До key ceremony это консистентно с
fail-closed (устанавливать нечего), но после церемонии релизный job должен
подписывать — иначе релизы останутся неустанавливаемыми одной командой.
Спека владельцу (раздел 6).

**R5-SC-1-5** — Info — `curl … | sh` / `irm … | iex` one-liner'ы: сам
`install.sh`/`install.ps1` аутентифицируется только TLS GitHub (TOFU).
Стандартно для такого механизма; частично смягчается тем, что скачанные
пакеты проверяются minisign. Не исправляется кодом.

### Проход 2 — Корректность

**R5-SC-2-1** — High — `sora/.github/workflows/repository.yml`,
шаг «Install with install.sh»: после H1 шаг **не мог пройти никогда**:
`install-test/` не содержал `SHA256SUMS.minisig` → `cp` → die; даже с ним —
плейсхолдер ключа → die. Задокументированный контракт install.sh
(«CI must provide a .minisig made with its test key, or set
SORA_MINISIGN_PUBKEY») не выполнялся. Проверено симуляцией
(`sora: SHA256SUMS.minisig is not in /tmp/fakedist`, затем плейсхолдер-die).
**Исправлено**: `apt install minisign`, эфемерная пара
`minisign -G -W`, подпись `SHA256SUMS`, `SORA_MINISIGN_PUBKEY` в env шага и
прокинут в fedora/arch контейнеры (`-e`), minisign доустановлен и там
(`dnf install minisign`, `pacman -S minisign`).

**R5-SC-2-2** — High — `sora/packaging/linux/test_update.py`: сломан **двумя**
фиксами сразу: (а) L4 (downgrade protection, коммит `87cbda4`) добавил
`installed_version()`, а фейки `dpkg-query`/`rpm`/`pacman` на запросы версии
отвечали мусором (`installed`, `sora\nsora-core`) → happy-path умирал на
«cannot determine the installed version»; (б) H1 — плейсхолдер ключа →
`verify_signature` умирает раньше любых ассертов. Итог: `test_pair_in_one_`
transaction_for_every_manager` красный, остальные тесты проходили
тривиально (умирали раньше своих сценариев). **Исправлено**: фейки отвечают
на version-запросы через `${TEST_VERSION:-1.0.5}`; добавлен фейк `minisign`
(`exit ${TEST_MINISIGN_FAILURE:-0}`) + `SORA_MINISIGN_PUBKEY` в bwrap-env;
новый кейс `badsig` покрывает fail-closed при плохой подписи. Логика всех
фейков прогнана шеллом построчно. bwrap в этом окружении нет — полный
прогон остаётся за CI.

**R5-SC-2-3** — High — `sora/.github/workflows/repository.yml`, шаг
«Install with install.ps1»: та же поломка — `dist\` без `.minisig`,
плейсхолдер → `Copy-Item` бросает / `Assert-ReleaseSignature` бросает.
**Исправлено**: `choco install minisign`, эфемерный ключ,
`$env:SORA_MINISIGN_PUBKEY = (Get-Content $pub)[1]`, подпись `SHA256SUMS`.

**R5-SC-2-4** — Low — `sora/packaging/install/install.sh`: `SORA_VERSION` из
окружения никак не валидировался (только автоопределённый latest); значение
попадало в имена файлов и URL. Прямой инъекции нет (всё в кавычках, без
eval), но `1.0.5;evil`/`../x` доходили до `cp`/`curl`. **Исправлено**:
строгая проверка до использования — алфавит `[0-9A-Za-z.~+-]`, начало/конец
алфанумерик, dotted-numeric форма. Матрица проверена исполнением
(`1.0.3`/`0.0.0~42`/`1.0.3-rc1` проходят, `;`, `/`, `v`-префикс, пробелы —
die). Консистентно с regex-валидацией в install.ps1.

**R5-SC-2-5** — Medium — `sora/packaging/install/install.sh`, ветка zypper:
`zypper --non-interactive install` локальных **неподписанных** .rpm —
комментарий в коде запрещает ослаблять проверку, но тогда zypper своей
проверкой, скорее всего, уронит установку (unsigned → prompt → в
non-interactive отказ). Путь не покрыт CI (fedora→dnf, arch→pacman).
**Не исправлено**: нужна проверка на живой openSUSE. Спека (раздел 6).

**R5-SC-2-6** — Low — `sora-legacy/packaging/linux/nfpm.yaml`:
`homepage: https://github.com/levvs-one/sora-client` — чужой/несуществующий
репо. **Исправлено** → `https://github.com/levvs-one/sora-legacy`.

**R5-SC-2-7** — Info — `sora/packaging/windows/sora.iss:4`: пример сборки
`iscc /DAppVersion=0.3.0` протух (рядом пример с 1.0.6). **Исправлено** →
1.0.6.

**R5-SC-2-8** — Info — `sora/packaging/linux/sora-update`: если
`installed_version()` упадёт между проверками (пакет снесли), `current=$(…)`
под `set -e` выйдет молча, без `die`-сообщения. Сценарий экзотический,
поведение всё равно безопасное (ничего не ставится). Не трогал.

Проверено и **не** является находкой: `tr -d '~'` для pacman в install.sh —
nfpm v2.47.0 `arch.go:validPkgName` вырезает `~` из имени файла, так что
`0.0.0~123` → `sora-core-0.0.0123-1-x86_64.pkg.tar.zst` сходится с ожиданием
скрипта (сверено с исходником nfpm). Комментарий «A pacman version has no
"~"» фактически точен для nfpm-имён.

### Проход 3 — Живучесть

**R5-SC-3-1** — Medium — `install.sh`: `curl` без `--retry`, без таймаутов —
как HEAD на `/releases/latest`, так и загрузки пакетов (десятки МБ).
Обрыв зеркала = висящий или упавший однострочник. **Исправлено**:
`--retry 3 --connect-timeout 20 --max-time 600` (загрузки),
`--max-time 60` (probe).

**R5-SC-3-2** — Medium — `install.ps1`: одиночный `Invoke-WebRequest` без
таймаута и ретраев. **Исправлено**: `Invoke-SoraDownload` (3 попытки,
backoff 5→10с, `-TimeoutSec 300`); lookup latest через API тоже с ретраем
и внятным сообщением.

**R5-SC-3-3** — Low — `packaging/engines/fetch.sh` (sora): был `--retry 3`,
но без таймаутов. **Исправлено**: `--connect-timeout 20 --max-time 600`
на все три curl-вызова; то же в порте для legacy.

**R5-SC-3-4** — Info — единственный источник загрузок — GitHub, зеркал нет.
Осознанно (подписи/пины привязаны к релизам GitHub). Не менял.

### Проход 4 — Качество кода

- Дублирование `verify_signature` в трёх файлах (sh×2, ps1×1) — осознанное:
  install.sh распространяется отдельно one-liner'ом, sora-update ставится
  файлом, ps1 — другой язык. Выносить некуда без регресса распространения.
- `install.ps1` vs `install.sh`: discovery latest (API vs redirect) — см.
  R5-SC-1-2; regex хэша в ps1 требует lowercase, awk в sora-update
  принимает uppercase — тривиальная несогласованность, релизный пайплайн
  пишет lowercase; не трогал.
- Мёртвых веток не найдено: `with_app`, `arch_arch`, `allow_downgrade`,
  все `case`-ветки форматов, `found`-счётчик в fetch.sh — всё достижимо.
- Магические числа: `Sleep(1500)` в sora.iss (ожидание остановки службы),
  backoff-константы в новом коде — с комментариями. В пределах нормы.
- `zapret/build.sh` идентичен в обоих репо — дублирование между репо
  осознанное (независимые релизы).

### Проход 5 — Системы

- **Консистентность версий/имён проверена матрицей**: nfpm.yaml →
  `sora-core_${ver}_${arch}.deb` / `sora-core-${ver}-1.${arch}.rpm` /
  `sora-core-${ver}-1-${arch}.pkg.tar.zst` — сходится с ожиданиями install.sh
  (все 4 менеджера, arm64 — только core) и sora-update (все 3 формата,
  amd64); `.iss` `OutputBaseFilename=Sora-Setup-{#AppVersion}-x64` сходится
  с `$name` в install.ps1; `engines.sig` покрывает все 3 движка из lock.
- **sora-update ↔ nfpm-app.yaml**: policy annotate
  `/usr/lib/sora/sora-update` = dst в nfpm-app.yaml ✓; скрипт ставится
  0755 ✓.
- **CI ↔ скрипты**: контракт SORA_DIST теперь выполняется (R5-SC-2-1,
  R5-SC-2-3); `shellcheck`/`PSScriptAnalyzer` шаги на месте.
- Остаток: release job без подписи SHA256SUMS (R5-SC-1-4), zypper
  неподписанные пакеты (R5-SC-2-5) — спека ниже.

## 4. Сводная таблица

| ID | Sev | Файл | Суть | Статус |
|---|---|---|---|---|
| R5-SC-1-1 | M | sora `.github/workflows/*` | floating action tags, govulncheck@latest, curl\|bash | ✅ исправлено |
| R5-SC-1-2 | L | install.ps1 | latest через rate-limited API, расхождение с install.sh | спека |
| R5-SC-1-3 | M | legacy fetch.sh | нет проверки подписей апстримов (M3 не портирован) | ✅ исправлено |
| R5-SC-1-4 | M | repository.yml release job | релиз без SHA256SUMS.minisig | спека (ждёт key ceremony) |
| R5-SC-1-5 | I | install.sh/ps1 | TOFU one-liner | info |
| R5-SC-2-1 | H | repository.yml | CI install.sh сломан H1 (нет .minisig/ключа) | ✅ исправлено |
| R5-SC-2-2 | H | test_update.py | сломан L4+H1 (фейки версий, плейсхолдер) | ✅ исправлено |
| R5-SC-2-3 | H | repository.yml | CI install.ps1 сломан H1 | ✅ исправлено |
| R5-SC-2-4 | L | install.sh | SORA_VERSION из env не валидировался | ✅ исправлено |
| R5-SC-2-5 | M | install.sh | zypper + unsigned rpm в non-interactive | спека (нужен живой openSUSE) |
| R5-SC-2-6 | L | legacy nfpm.yaml | homepage → sora-client | ✅ исправлено |
| R5-SC-2-7 | I | sora.iss | протухший пример 0.3.0 | ✅ исправлено |
| R5-SC-2-8 | I | sora-update | молчаливый выход installed_version под set -e | info |
| R5-SC-3-1 | M | install.sh | curl без ретраев/таймаутов | ✅ исправлено |
| R5-SC-3-2 | M | install.ps1 | загрузки без ретраев/таймаута | ✅ исправлено |
| R5-SC-3-3 | L | fetch.sh ×2 | curl без таймаутов | ✅ исправлено |
| R5-SC-3-4 | I | все загрузчики | единственный источник — GitHub | info |

## 5. Топ-3

1. **R5-SC-2-1 / R5-SC-2-3 — CI install.sh/install.ps1 были мертвы после H1.**
   Fail-closed фикс оказался настоящим (проверено исполнением), но его автор
   не обновил два CI-контракта, прямо описанные в шапках скриптов. Шаги
   умирали на отсутствующем `SHA256SUMS.minisig` и плейсхолдере ключа —
   то есть «тот же скрипт, что у людей» в CI не прогонялся вообще.
2. **R5-SC-2-2 — test_update.py сломан сразу двумя фиксами (L4+H1).**
   Happy-path тест не мог стать зелёным: фейки не отвечали на новые
   version-запросы, а подпись упиралась в плейсхолдер. Остальные тесты
   проходили тривиально, умирая раньше своих сценариев, — ложное чувство
   покрытия привилегированного root-хелпера.
3. **R5-SC-1-1 — supply-chain в sora-воркфлоу.** LEGACY-M8 (P1) закрепил
   пины только в legacy; sora жил на floating `@v6`/`@v5`, `govulncheck@latest`
   и `curl|bash`-установке actionlint. Теперь всё запинено по SHA
   (SHAs резолвлены через API, actionlint-SHA независимо сверен скачиванием).

## 6. Исправлено сразу

Коммиты (только свои пути, без пуша):

- sora `98794f1` — `[review-5pass] scripts-ci: fix CI contract broken by H1
  fail-closed, pin actions, harden downloads` (8 файлов: install.sh,
  install.ps1, fetch.sh, test_update.py, sora.iss, 3 воркфлоу)
- sora-legacy `21bf84e` — `[review-5pass] scripts-ci: port upstream-signature
  enforcement to legacy fetch.sh` (fetch.sh, engines.sig новый,
  nfpm.yaml)

Проверки после правок: `bash -n` ×12, `py_compile`, парсинг YAML ×5,
симуляция fail-closed install.sh (плейсхолдер → die до установки),
сквозной цикл minisign 0.11 (gen→sign→verify→tamper-reject),
dgst-crosscheck против живого `.dgst` Xray (match/tamper), фейки
test_update.py — построчный прогон шеллом, матрица валидации SORA_VERSION,
сверка `~`-поведения с исходником nfpm v2.47.0. Полный прогон
test_update.py невозможен здесь (нет bwrap) — за CI.

## 7. Осталось спекой (нужны решения/доступ родителя или владельца)

1. **R5-SC-1-4**: после key ceremony добавить в release job подпись
   `SHA256SUMS` релизным ключом (сейчас публикуется без `.minisig` —
   install.sh/ps1 не смогут ставить релизы). Заодно задокументировать
   ротацию (FIX-PLAN §9 уже требует).
2. **R5-SC-2-5**: проверить ветку zypper на живой openSUSE —
   установятся ли неподписанные .rpm через `zypper --non-interactive`;
   если нет — решение: подписывать rpm (GPG, тоже ceremony) или
   осознанно документировать ограничение.
3. **R5-SC-1-2**: унифицировать discovery latest в install.ps1 на
   `/releases/latest`-редирект как в install.sh (убрать зависимость от
   rate-limited API).
4. Полный прогон `python3 packaging/linux/test_update.py -v` в CI после
   мержа — убедиться, что bwrap-песочница с новыми фейками зелёная
   (локально bwrap недоступен).
5. Напоминание: сами значения `REPLACE-ME-AFTER-KEY-CEREMONY` в трёх
   скриптах — действие владельца (key ceremony, FIX-PLAN §9); fail-closed
   до тех пор — это корректное состояние, не баг.
