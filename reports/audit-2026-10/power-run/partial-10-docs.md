# Агент №10 — Доки vs код (power-run, 2026-10-19)

Ветка `bugfix/audit-2026-10-19`, репо `sora` + `sora-legacy`. Код не трогался;
правки — только доки (коммит `5bcc46f` `[power-run] docs: ...`, без пуша).
**Важно про коммит:** `git add` подхватил уже staged в индексе файлы чужой
работы (другой агент) — в `5bcc46f` помимо моих 11 файлов попали
`core/custom/*`, `proto/sora/custom/*`, `core/gen/sora/custom/*` (~2800 строк).
Откатывать/переписывать историю не стал: дерево активно переписывается
параллельными агентами (коммиты шли прямо во время прогона), риск потерять
чужую работу выше пользы. Содержимое легитимно и принадлежит ветке;
координатору — учесть при сквоше/мерже (разделить по коммитам).

Применён ФИЛЬТР СЛОПА владельца: ниже честно разделено «реально работает»
и «витрина». Спорные вердикты помечены.

## 1. Таблица «документ → утверждение → код → вердикт»

| # | Документ | Утверждение | Код | Вердикт |
|---|----------|-------------|-----|---------|
| D1 | `docs/usage.md` | Раздел «Расширения» = «Скоро появится» | Реальный раздел: стор, установка, панели (`app/lib/src/ui/extensions/`) | **WRONG → исправлено** |
| D2 | `docs/usage.md`, `README.md`, `README.en.md` | «31 вариант/язык интерфейса» | `supportedLocales` = 32, 32 `.arb` | **WRONG → исправлено** (везде «32») |
| D3 | `docs/extensions.md` §1.1 | `checksums.txt`: «paths sorted» (как требование) | `parseChecksums` (Go/Dart) порядок не проверяет; сортирует только reference packager | **WRONG (мелочь) → исправлено**: «сортировка — правило для упаковщика, верификация принимает любой порядок» |
| D4 | `docs/extensions.md` §2 | `min_app_version` гейтится через `--dart-define=APP_VERSION=…` | `store_screen.dart:280` читает `APP_VERSION`; но релизный пайплайн (`development.md`, `packaging/*/README.md`, CI `repository.yml`) прокидывает только `SORA_VERSION` → в релизах гейт **молча пропускается** | **WRONG (доки несогласованы) → исправлено в доках**; CI yaml — **[cross-ref]**: добавить `--dart-define=APP_VERSION=${{ env.SORA_VERSION }}` в обе flutter-сборки |
| D5 | `docs/extensions.md` §4 | «`fetch`/`XMLHttpRequest` from panel JS have no network access in v1» | `panel_screen.dart`: `onNavigationRequest` режет только топ-уровневую навигацию; subresource-запросы (fetch/XHR/img) не перехватываются — панель **может** ходить в сеть | **WRONG (код отстаёт от доки) → [cross-ref]**: нужен перехват запросов или CSP; док пока обещает больше, чем песочница даёт |
| D6 | `docs/extensions.md` §6 | «Catalog packages are verified against the catalog-pinned author key» | `_installBytes` (source='catalog'): сверяет sha256 с entry + `pkg.verify()` по **self-attested** ключу из манифеста; `entry.authorKey` нигде не сравнивается | **WRONG (код отстаёт) → [cross-ref]**: добавить проверку `manifest.author.publicKey == entry.authorKey`. Смягчающее: каталог fail-closed до key ceremony, эксплойт — только после неё |
| D7 | `docs/extensions.md` §7 | Background workers + net.fetch (runtime v2) | `core/ext/manifest_v1ext.go` (clamp [15 мин, 7 дней], capability+permission), `netfetch.go` (https-only, редиректы re-check ≤3, 30s/1MiB/8MiB, 30 req/min burst 10), `worker.go`, `extlog.go` — всё сходится | **OK** |
| D8 | `docs/extensions.md` §7 | «The app-side JS runner executes `entry` inside this envelope…» | В Dart раннера воркеров нет (только UI-секция `_BackgroundTaskSection`) | **OUTDATED/аспирация** — док забегает вперёд; помечено в отчёте, не правил (допишет автор v2) |
| D9 | `docs/sync-threat-model.md` (протокол) | Noise_XX_25519_ChaChaPoly_SHA256, HMAC(token, handshake_hash), токен 16 байт, TTL 5 мин, API только 127.0.0.1, 0600, лимиты 16/64/17 MiB | `service/sync/{transport,pairing,api,sync}` — всё сходится | **OK** |
| D10 | `docs/sync-threat-model.md` «What the app must do» | показать пира, revoke, нотификация о pulled-документах до применения, не светить api_token | Приложение ничего этого не делает (нет API-клиента вообще) | **MISSING → добавлен status-note** в начало документа |
| D11 | `app/lib/src/sync.dart`, `app/lib/src/ui/sync.dart` (doc-комменты) | «канал живёт в Go sync service (`core/sync/sync.go`)», «UI complete and honest about what is synced» | Сервис не запускается и не вызывается; путь неверный (`service/sync`); QR-формат Dart несовместим с Go-декодером | **WRONG → исправлено**: честный статус «реестр устройств, сервис не подвязан» |
| D12 | `app/lib/src/ext/bridge.dart` (doc-коммент) | `getServers` → `[{id, name, protocol}]` | Реально `[{id, name, country, latency_ms}]` | **WRONG → исправлено** |
| D13 | `docs/architecture.md`, `install.md`, `troubleshooting.md`, `providers.md`, `development.md` | архитектурные/процедурные утверждения | Сверены с кодом волн — противоречий не найдено (порядок движков, TUN, kill switch, DoH-дефолты `1.1.1.1`/`8.8.8.8` — всё на месте) | **OK** |
| D14 | `sora-legacy/docs/` | `android-security-requirements.md` — честно «требования к новой разработке, кода нет»; arch/audit/research — без противоречий с фи
...[truncated 7113 chars]