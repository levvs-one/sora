# Аналитик №18: тесты (sora + sora-legacy, ветка bugfix/audit-2026-10-19)

Read-only анализ. Метод: подсчёт (143 Go test-файла, 812 `func Test`, 23 766 строк тестов в `core/`+`service/`; 136 Dart-тестов в `app/test`; 3 Python-теста `packaging/linux/test_update.py`), выборочное чтение ~25 ключевых файлов, прогон `go test ./...` в обоих репозиториях.

## Вердикт

Культура тестов неожиданно зрелая: негативные кейсы, fail-closed проверки и regression-тесты на гонки есть там, где они решают (сессии, секреты, дайджесты, подпись расширений, пэйринг). Театра покрытия почти нет — пропуски честно оформлены через `t.Skip` с причинами. **Но ветка сейчас красная**: три независимые поломки делают часть сюиты незапускаемой, плюс один тест хрупок по дизайну и падает в песочнице (воспроизведено). Ранжированные рекомендации ниже — по порядку устранения.

## Сильные стороны

- **Fail-closed покрытие критичных путей настоящее, не декоративное.**
  - `core/session/session_test.go` (18 тестов) — почти все про отказы: `TestSessionFailsWithoutTouchingTheSystemWhenThePlanIsRejected:246`, `TestSessionRestoresTheSystemWhenTheEngineWillNotStart:267`, `TestManagerRetriesRestorationAfterAFailedDisconnect`, `TestStopBoundsAHungEngine:579`. Менеджер сессий тестируется как машина отказов, а не happy path.
  - `core/engine/supervise/discovery_test.go:63` `TestDiscoverVerifiesDigest` — табличные субтесты: верифицированный бинарь находится, подменённый после манифеста отвергается, отсутствующий манифест — fail closed, PATH никогда не используется. Привязка к SORA-H5 в комментарии. Это ровно тот тест, который должен существовать.
  - `core/secret/store_test.go` — 15 тестов: `TestCorruptVaultIsRefused`, `TestVaultCannotBeCombinedWithAForeignKeyOrID`, `TestConcurrentUseKeepsTheVaultConsistent`, `TestVaultIsEncryptedOnDisk`, `TestApplyIsAllOrNothing`, `TestOpenRefusesWeakenedPermissions`. Образцово.
  - `core/ext/*_test.go` — подпись/верификация: `TestSignTamperFails`, `TestPackageExtraFileFails`, `TestPackageBadSignatureFails`, `TestPackageNotZip`, `TestTeamSignatureFailsClosed`, `TestStoreUpdateRejectsDowngrade`, `TestStoreRollback`. Fail-closed везде.
  - `service/sync/api/pairing_concurrency_test.go` — regression на конкретную гонку (stale TTL watcher не должен убивать новую pairing-сессию). Маленький, точный, с комментарием о причине.
  - `service/sync/api/e2e_test.go` — pairing и HTTP API end-to-end через Noise_XX поверх loopback, без моков криптографии.
- **Редактор секретов тестируется паттернами, а не одним кейсом:** `core/engine/support_test.go:55` `TestRedactorMasksPlanSecretsAndPatterns`, `:139` `TestRedactorMasksRealityAndModernSchemes` (REALITY/shadowsocks-2022 и т.д., привязка к SORA-L9).
- **Censor-detect — сценарные тесты, а не юнит-театр:** `core/censor/detect_test.go` — 14 тестов строят временные ряды событий (DNS→TCP→TLS→RST) и проверяют классификацию (SNI blocking, RST injection, confidence ≥ 0.75, подбор obfs-пресета). `core/censor/probe_test.go`, `journal_test.go` рядом.
- **Obfs тестирует настоящий handshake:** `core/obfs/utls_test.go:87` `TestUTLSHandshake`, `:126` `TestUTLSHandshakeWrongServerNameFails` — реальный TLS против локального сервера; `conn_test.go:136` `TestDialTLS`. Без выхода в интернет.
- **DNS-leak и ext/netfetch мокают сеть правильно:** `core/diagnostics/dnsleak_test.go` инжектит `Resolve` с каноническим `203.0.113.7`; `core/ext/netfetch_test.go` переписывает `http.Transport.DialContext` на `httptest.TLSServer`. Реестр allowlist/redirect/size-limit/rate-limit покрыт 15 тестами.
- **Привилегированный helper обновлений тестируется в изоляции:** `packaging/linux/test_update.py` (3 теста) — фейковые package managers, downgrade protection, fail-closed при плохой подписи, `TEST_MINISIGN_FAILURE=1` для abort-пути. `app/test/updates_test.dart` (9 тестов) — парсинг релизов, сверка SHA256SUMS, выбор пакетного менеджера по моку процессов.
- **Скипаются честно:** `core/engine/interop/*` и `*/live_test.go`, `render_test.go` требуют `SORA_ENGINES_DIR`/бинари; `core/guard/nftables_test.go:85` прямо пишет «arming it in a test would change this machine». Это не театр — это признание границ.

## Слоп/проблемы (файл:строка)

### P0 — ветка красная, сюита частично незапускаема

1. **`core/engine/mihomo/rules_test.go:79` — синтаксическая поломка.** После закрывающей скобки `TestBuildRulesRejectsSingBoxBinaryRuleSet` висит осиротевший блок `rules := []engine.Rule{...}` вне какой-либо функции (похоже, удалён заголовок теста вида `TestBuildRulesRejectsInsecureRuleSets`). `go test ./engine/mihomo` падает на этапе компиляции: `rules_test.go:79:2: expected declaration, found rules`. Весь пакет mihomo (render/rules/cache/dns_route/logparse/names) не тестируется вообще. Введён коммитом ffdf453 («mihomo: render rule-providers…»).
2. **`core/ext/store.go:4` и `core/ext/worker.go:22` — неиспользуемые импорты** (`"bytes"`, `"sync/atomic"`). Пакет `core/ext` не компилируется: `go build ./ext/` → обе ошибки. Следствие: ~60 тестов расширений (manifest/sign/verify/store/worker/netfetch — вся F10-инфраструктура) не запускаются. Похоже на недовинченный рефакторинг из коммита 62e8623 («ext event detail withheld…»).
3. **`core/engine/tun_test.go:74` `TestTunAndFakeIPAvoidLANAndEachOther` — падает в песочнице (воспроизведено).** Причина: `PrepareTun` читает живые интерфейсы через `net.InterfaceAddrs()` (`core/engine/tun.go:24`), а в этой среде есть `host0 198.19.0.2/30`, пересекающийся с benchmark-диапазоном `198.18.0.0/15` → `tun: fake-IP pool overlaps an existing interface`. Тест зависит от сетевого окружения машины по дизайну. Лечится инжекцией списка интерфейсов (параметр/переменная пакета), а не пропуском.
4. **`sora-legacy/core/engine/redact_scratch_test.go` — неотслеживаемый (untracked) scratch-файл с пометкой «NOT committed», заведомо падающий.** `TestScratchPatternBackstop` документирует 26 LEAK-кейсов паттернов редактора (trojan/hysteria2/ss-base64/socks/vmess-base64/JSON/INI/WG-ключи). Локальный `go test ./...` в sora-legacy из-за него красный. Либо чинить паттерны и превращать в настоящий backstop, либо удалять — scratch в рабочем дереве это слоп.

### P1 — честные пробелы в покрытии критичных путей

5. **Rendered-конфиги не проверяются без бинарников движков.** Все `render_test.go` (xray/singbox/mihomo) и `live_test.go` скипаются без `SORA_ENGINES_DIR`/Prober-бинаря — то есть самый опасный путь (сгенерированный конфиг реально стартует в движке) на обычном `go test`/`flutter test` не покрыт ничем, кроме синтаксических снапшотов. Это честно заскипано, но дыра реальная: ошибка рендера видна только в CI-джобе с движками.
6. **Kill switch по-настоящему не тестируется нигде** (`core/guard/nftables_test.go:73,85,87` — скипы «изменит эту машину»; `firewall_windows_test.go:31` — скип «this machine reaches nothing outside»). Guard покрыт через фейковый firewall (`guard_test.go`), сами бэкенды — нет. Для security-критичной фичи это осознанный, но самый большой остаточный риск.
7. **Staged update (F7) как «обновление без разрыва туннеля» тестами не зафиксирован.** `app/test/updates_test.dart` покрывает парсинг/верификацию/установку с моками; сценария «релиз ставится, сессия переживает рестарт core» нет ни в Dart, ни в Go.

### P2 — качество тестов: хорошо, но не безупречно

8. **Табличных тестов мало: 18 из 143 файлов (~13%).** Большинство — развёрнутые hand-written кейсы. Читаемо, но раздувает объём (23.7k строк) и затрудняет добавление кейсов. Кандидаты на таблицы: `validate_test.go`, `validate_hy2tuic_test.go`, `parser/parser_test.go`, `errs/classify_test.go`.
9. **Временные слипы в тестах:** `core/session/session_test.go:335` (50ms), `:474` (settle через `StatsInterval`), `:526` (2ms), `:593` (5s timeout); `core/engine/supervise/supervisor_test.go:73,148,203,364`; `core/control/e2e_test.go:234` (5s). Слипы маленькие и с таймаутами, но `session_test.go:474` завязан на wall-clock интервал — кандидат в flakes на загруженном CI.
10. **`core/testdata/coexist/` — ручной harness (`run.sh` + `dns.go` + `probe.go`), не подключён к `go test`.** Либо обернуть в `TestMain`/go-тест со скипом по `SORA_*`, либо вынести из `testdata` в `scripts/`, чтобы не создавать иллюзию покрытия.
11. **sora-legacy: C# (`app/`) — ноль тестовых проектов.** Вся клиентская логика legacy (движок-менеджмент, verify скачанных бинарников — то, что чинили в аудите) без автотестов. Go-часть legacy покрыта средне; красный scratch см. п.4.
12. **Мёртвых/закомментированных тестов нет** (проверено grep по `// func Test` и `// t.(Fatal|Error|Skip)` — чисто), TODO/FIXME в тестах нет. `t.Skip` используется только по делу.

## Ранжированные рекомендации

1. **Починить красную ветку (блокер для всего остального):** восстановить/удалить осиротевший блок в `core/engine/mihomo/rules_test.go:79`; убрать неиспользуемые импорты `core/ext/store.go:4`, `core/ext/worker.go:22`; удалить или довести до зелёного `sora-legacy/core/engine/redact_scratch_test.go`. После этого `go test ./...` в обоих репо должен быть зелёным без скипов по вине кода.
2. **Сделать `TestTunAndFakeIPAvoidLANAndEachOther` детерминированным:** инжектировать список интерфейсов в `PrepareTun` (параметр или переопределяемая переменная пакета), тест — на синтетических адресах. Текущий вариант будет падать на любой машине с адресом из `198.18.0.0/15` (Docker, VPN, песочницы).
3. **Добавить conformance-тест рендера без бинарников:** хотя бы JSON/YAML-парсинг сгенерированных конфигов против схем движков или golden-файлы с диффом — чтобы `go test` ловил сломанный рендер до CI с движками.
4. **Зафиксировать staged-update сценарий:** тест «обновление применяется, сессия/plan переживают рестарт core» (Dart-интеграционный с моком или Go-уровень через session manager).
5. **Kill switch:** вынести построение правил nftables/Windows firewall в чистые функции и покрыть их юнит-тестами (генерация правил — без применения). Применение оставить за ручными/CI-привилегированными джобами.
6. **Консолидировать в таблицы** validate/parser/classify-тесты; убрать wall-clock settle в `session_test.go:474` в пользу каналов/событий.
7. **Определить судьбу `core/testdata/coexist`:** либо go-тест со скипом, либо переезд из `testdata`.
8. **sora-legacy:** минимум — smoke-тесты Go-ядра вокруг verify/downgrade-protection (то, что чинилось в аудите); C# — признать отсутствие тестов техническим долгом явно (сейчас это молчаливый факт).

## Сводка цифр

- sora `core/`+`service/`: 143 test-файла, 812 тестов, 23 766 строк; пакеты без тестов: только `gen/`, `cmd/`, `doc.go`, `enginetest` (хелпер), `service/sync/discovery` (mDNS).
- `app/test`: 136 Dart-тестов + 2 integration; `packaging/linux/test_update.py`: 3 теста.
- sora-legacy `core/`: ~70 test-файлов; локально красный только из-за scratch-файла (п.4); C#: 0 тестов.
- CI (`.github/workflows/repository.yml`): `go test -race ./...` (строка 106), `flutter test` (141), `go test ./...` (175) — на текущей ветке джобы Go красные по пп.1–2.
