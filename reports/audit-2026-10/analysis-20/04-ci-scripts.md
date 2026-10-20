# Аналитик №4: CI и скрипты

Зона: `.github/workflows/` (autofix.yml, repository.yml, security.yml), `packaging/` (install.sh, install.ps1, engines/fetch.sh, zapret/build.sh, linux/sora-update, linux/scripts/, nfpm*.yaml, windows/sora.iss), `core/testdata/coexist/run.sh`, l10n-артефакты, testdata/фикстуры.
Метод: read-only. Все утверждения сверены с кодом; там, где что-то «ок», это проверено, а не предположено.

---

## Вердикт

CI зрелый и честный: пины Actions по SHA, проверка SHA-256 скачанного actionlint, fail-closed подпись релизов, настоящие интеграционные тесты (TUN throughput на Windows, coexistence в netns, live-туннель через локальный VLESS, установка/удаление end-to-end, unelevated pipe test). Слоп-уровня «мёртвый workflow» нет.

Но есть **одна высокая находка уровня «CI зелёный, продукт сломан»**: `packaging/linux/nfpm.yaml` не упаковывает `engines.digests`, без которого установленный core считает все движки неустановленными. CI это не ловит, потому что post-install тест проверяет только `systemctl is-active` и `sora-core -version`, но никогда не запускает движок из установленного каталога. Плюс несколько средних зазоров: нет проверки свежести Dart protobuf-кода, нет проверки соответствия `.arb` ↔ `strings_*.dart`, инлайн-дублирование `buf.gen.yaml`, shellcheck покрывает 2 из 7 shell-скриптов.

---

## Сильные стороны

- **Supply chain.** Все Actions зашиты по SHA с комментарием версии (`repository.yml`, `security.yml`, `autofix.yml`). actionlint качается tar-архивом с проверкой SHA-256 вместо install-скрипта (комментарий объясняет почему).
- **Подписи fail-closed.** install.sh, install.ps1, sora-update отказываются работать с плейсхолдером ключа (`REPLACE-ME-AFTER-KEY-CEREMONY`), подпись SHA256SUMS проверяется *до* доверия любому хешу. CI тестирует SORA_DIST-контракт с эфемерным minisign-ключом — честно, без ослабления цепочки.
- **engines/fetch.sh**: `--proto '=https'`, retry, строгая проверка SHA-256 по lock, `engines.sig` с fail-closed методами (dgst-crosscheck/cosign/none — честно задокументировано, что mihomo и sing-box-fork подписей не публикуют).
- **Настоящие тесты, а не галочки.** Windows job: throughput TCP/UDP через каждый TUN-стек, установка через install.ps1, проверка пайпа без админских прав (runas trustlevel), live-туннель с реальным VLESS-сервером, удаление. Linux: packet capture в изолированном netns, coexistence с happ/openvpn в параллельных неймспейсах, install.sh на Ubuntu+Fedora+Arch в docker.
- **Проверки консистентности.** `buf lint` + `buf breaking` против main; `git diff --exit-code -- gen` после регенерации Go protobuf; gofmt/vet/race/golangci-lint; `flutter analyze` + `dart format --set-exit-if-changed`; shellcheck для install.sh и sora-update; PSScriptAnalyzer для install.ps1; python-тест sora-update в bubblewrap; `language_test.dart` сверяет ключи/плейсхолдеры/ссылки по всем `.arb`.
- **Безопасность.** govulncheck (reachable, с комментарием почему не graph-scan), osv-scanner, CodeQL, gitleaks (full history), dependency-review на PR. Секретов в логах не найдено: эфемерные ключи живут в RUNNER_TEMP, в env только публичные; `install.log` в диагностике секретов не содержит.
- **Гигиена пайплайна.** `concurrency.cancel-in-progress`, `fail-fast: false` там где нужна диагностика (coexist matrix, CodeQL), артефакты с `if-no-files-found` явно указаны.

---

## Проблемы

### HIGH

**H1. `engines.digests` не попадает в Linux-пакеты — установленный VPN не работает, CI зелёный.**
`packaging/linux/nfpm.yaml:36-60` перечисляет содержимое пакета явно: `dist/sora-core`, `dist/engines/{sing-box,xray,mihomo,geoip.dat,geosite.dat,tpws,nfqws,zapret/fake/}`, systemd-юниты, лицензии — но **нет `dist/engines/engines.digests`**, который создаёт `packaging/engines/fetch.sh:86-89`.
Цепочка поломки:
- `service/linux/sora-core.service:13` стартует core с `-engines-dir /usr/lib/sora/engines`;
- `core/engine/supervise/binary.go:193` (`loadDigests`): нет манифеста → ошибка «cannot read engines.digests»;
- `core/engine/supervise/binary.go:163`: каждый кандидат отвергается;
- `core/engine/registry/registry.go`: все движки помечаются «not installed», `Usable() == false`.
Итог: сервис `active`, `sora-core -version` работает — оба факта CI проверяет (`repository.yml`, linux-packages, «Install with install.sh…»: `systemctl is-active sora-core`, `/usr/bin/sora-core -version`) — но ни одно соединение core поднять не может. На Windows проблемы нет: `packaging/windows/sora.iss:119` берёт `dist\windows\engines\*` вайлдкардом, манифест попадает. Асимметрия «вайлдкард vs явный список» никем не сверяется.

**H2 (смежно). zapret вне дайджест-модели, комментарий врёт.**
`fetch.sh:86-89` заявляет: «The core verifies every discovered engine binary against this manifest». По факту в манифест пишутся только sing-box/xray/mihomo; `tpws`/`nfqws` (собираются позже через `packaging/zapret/build.sh`) туда не попадают, а `core/engine/registry/registry.go:74-78` находит `tpws` простой проверкой существования и executable-бита — без сверки дайджеста. Это расхождение с SORA-H5 («never execute unverified»). Либо включить zapret в манифест и проверять, либо честно задокументировать исключение.

### MEDIUM

**M1. Нет проверки свежести Dart protobuf-кода.**
`repository.yml:93-96` (go job) регенерирует *только Go* и делает `git diff --exit-code -- gen`. Dart-код (`app/lib/src/generated`) регенерирует только `autofix.yml`, который срабатывает только на `pull_request` (`autofix.yml:4`). Прямой push в main с изменённым `proto/` и несгенерированным Dart пройдёт весь CI. Класс бага «API mismatch между слоями» (в истории проекта уже был: мёртвый `connectChain`, мёртвый zapret-тоггл) именно так и проскакивает.

**M2. Два источника истины для генерации protobuf.**
`repository.yml:93-95` использует инлайн `--template '{...protoc-gen-go...protoc-gen-go-grpc...}'`, дублирующий `proto/buf.gen.yaml` (тот же out, те же opt, плюс Dart-плагин). Версии инструментов продублированы в двух файлах: `protoc-gen-go@v1.36.5`, `protoc-gen-go-grpc@v1.5.1` — в `autofix.yml:27-29` и `repository.yml:86-88`; `protoc_plugin 25.1.0` — только в `autofix.yml:34`. Правка в одном месте молча рассинхронизирует другое.

**M3. `.arb` ↔ `strings_*.dart` ничем не сверяются.**
`app/lib/l10n/` содержит 32 `.arb` и 32 `strings_*.dart`. `app/test/language_test.dart` проверяет только `.arb`↔`.arb` (ключи, плейсхолдеры, ссылки). Виджет-тесты используют Dart-классы. Ничто не гарантирует, что правка `.arb` отражена в `.dart` и наоборот; документированного генератора нет (`app/l10n.yaml` подразумевает `flutter gen-l10n` в `strings.dart`, но он рукописный — импортирует `strings_xx.dart`). Сегодня в синхроне (проверено скриптом: 506 ключей `app_en.arb` == 506 членов `strings_en.dart`, расхождений нет) — держится на дисциплине.

**M4. shellcheck покрывает 2 из 7 shell-скриптов.**
Проверяются: `packaging/install/install.sh` (`repository.yml`, linux-packages), `packaging/linux/sora-update` (app job). Не проверяются: `packaging/engines/fetch.sh`, `packaging/zapret/build.sh`, `packaging/linux/scripts/postinstall.sh`, `preremove.sh`, `postremove.sh`, `core/testdata/coexist/run.sh` (самый сложный — неймспейсы, trap, фоновые job'ы).

**M5. `go mod tidy` без проверки чистоты.**
`repository.yml:97-98`: `go mod tidy` выполняется, но `git diff --exit-code -- go.mod go.sum` после него нет. Дрейф зависимостей молча правится только autofix на PR; на push в main — никак.

**M6. Нет path-фильтров: docs-only PR гоняет всё.**
`repository.yml:3-9`: `push: branches [main], tags [v*]`, `pull_request` — без `paths`. Правка опечатки в `docs/` запускает Windows long-pole (timeout 90 мин: TUN throughput 10 мин, live browser, live tunnel, install/uninstall) и linux matrix (docker Fedora/Arch, coexistence). Дорого и замедляет мелкие PR.

**M7. `cache: false` везде без объяснения.**
`repository.yml:47,80,166,408`, `autofix.yml:22`, `security.yml` (оба setup-go). Каждый запуск заново качает весь Go-модуль-граф и ставит `buf`, `protoc-gen-go(-grpc)`, `nfpm`, `govulncheck` через `go install`. Если это осознанно (hermeticity) — нужен комментарий; иначе это просто медленный пайплайн.

**M8. Schedule 4×/день дублирует полный race-suite.**
`security.yml:9-11` (`cron: '17 */6 * * *'`) + job `cross-build`: `go test -race -count=1 ./...` — та же сюита, что `repository.yml` гоняет на каждый push/PR. На расписании достаточно vuln/osv/secrets; race уже покрыт.

### LOW

**L1.** `packaging/engines/fetch.sh:143`: `[[ "$found" -ne 3 ]]` — захардкоженное число движков; при добавлении 4-го упадёт с неочевидной ошибкой. Лучше сверять с lock.
**L2.** `packaging/install/install.sh`: поиск в SHA256SUMS через `grep -E "  \\*?$name\$"` — точки версии работают как regex; `sora-update` в том же репо использует точный awk-матч. Fail-closed в обоих, но несогласованность.
**L3.** `.gitignore` не игнорирует `core/sora-core` — сейчас такой untracked бинарь висит в дереве (`git status`). Мелочь, но `autofix.yml` делает `git add -A`.
**L4.** `autofix.yml:19`: `fetch-depth: 0` для задачи «отформатировать и запушить» избыточен.
**L5.** Нет проверки битых ссылок в docs (`docs/` ~15 файлов, внешние ссылки на releases/issues) — дешёвый lychee.
**L6.** Нет `git diff --check` (whitespace errors) ни в одном job.
**L7.** `packaging/zapret/build.sh` утверждает «vendored unchanged», но ничто не сверяет `third_party/zapret` с апстримом (хеш вендоренного дерева).

### Проверено — не проблема

- `repository.yml:46` (`proto` job): `go-version: '1.23'` против `go 1.26.9` в `core/go.mod` — ок: `buf@v1.50.0` требует `go 1.22.0` / toolchain `go1.23.4` (проверено через module proxy).
- Фикстура `app/test/fixtures/releases/install.sh` — намеренно старый скрипт без подписи, используется в `updates_test.dart` как произвольный blob для тестов хеширования; не stale.
- `go.mod` module `github.com/levvs-one/sora-client/core` при репозитории `levvs-one/sora` — историческое имя, на CI не влияет.

---

## Ранжированные рекомендации

1. **[H1] Добавить `dist/engines/engines.digests` в `packaging/linux/nfpm.yaml`** (contents, dst `/usr/lib/sora/engines/engines.digests`) **и добавить в CI post-install smoke**: после «Install with install.sh…» выполнить `sora-core -check -engines-dir /usr/lib/sora/engines` (или assert на `registry.Usable()`) — именно этой проверки не хватило бы, чтобы поймать H1. То же для Windows уже покрыто live-тестами.
2. **[H2] Закрыть zapret в дайджест-модели**: писать `tpws`/`nfqws` в `engines.digests` в `build.sh` и проверять в `registry.Discover`, либо задокументировать исключение и поправить комментарий `fetch.sh:86-89`.
3. **[M1] Добавить job «Dart protobuf is current»** в `repository.yml`: `dart-lang/setup-dart` + `buf generate` только с dart-плагином из `buf.gen.yaml` + `git diff --exit-code -- app/lib/src/generated`. Дешёво, ловит класс «API mismatch между слоями».
4. **[M2] Один источник истины для генерации**: убрать инлайн `--template` из `repository.yml:93-95`, генерировать из `proto/buf.gen.yaml` (с фильтром плагинов при нужде); версии инструментов вынести в один файл (напр. `.github/protobuf-tools.env`), читаемый обоими workflow.
5. **[M3] CI-проверка `.arb` ↔ `strings_*.dart`**: маленький тест/скрипт «ключи `app_en.arb` == члены `SEn`» + задокументировать, чем генерируются `strings_*.dart` (сейчас это нигде не описано).
6. **[M4] shellcheck для всех shell-скриптов**: добавить в `repository.yml` шаг по `packaging/engines/fetch.sh`, `packaging/zapret/build.sh`, `packaging/linux/scripts/*.sh`, `core/testdata/coexist/run.sh`.
7. **[M5] `git diff --exit-code -- go.mod go.sum`** после `go mod tidy` в `repository.yml:97-98`.
8. **[M6] Path-фильтры**: `paths-ignore: ['docs/**', '*.md']` для тяжёлых job (`windows`, `linux-packages`) на PR; `security` и `proto`/`go` оставить без фильтров. Осторожно: dependency-review от путей не зависит.
9. **[M7] Убрать `cache: false` или задокументировать причину**; пины инструментов оставить, кэш модулей включить.
10. **[M8] В schedule `security.yml` оставить vuln/osv/secrets**, race-suite на расписании убрать (покрыта на push/PR).
11. **[L1–L7] Мелочи**: `found` сверять с lock, а не с константой 3; `grep -F` в install.sh; `.gitignore` для `core/sora-core`; `fetch-depth: 1` в autofix; lychee для docs; `git diff --check`; хеш вендоренного `third_party/zapret` в CI.

**Что НЕ рекомендую менять**: fail-closed модель подписей, пины по SHA, объём интеграционных тестов на Windows/Linux (это сильная сторона, а не слоп), `buf breaking`, связку govulncheck+osv+gitleaks+dependency-review.
