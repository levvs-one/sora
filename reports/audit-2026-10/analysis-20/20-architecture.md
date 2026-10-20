# Анализ №20: архитектура в целом

Репозиторий: `~/workspace/bug-hunt/sora`, ветка `bugfix/audit-2026-10-19` (состояние на 2026-10-20).
Метод: read-only. Проверены границы Flutter → gRPC → Go core → движки, `service/sync`, `sora-update`, расширения.

---

## Вердикт

Архитектура **здоровая в основании, но с тремя серьёзными разрывами**, каждый из которых — молча мёртвый или раздвоённый код, а не просто «техдолг»:

1. **gRPC-сервис `CustomServers` реализован, протестирован, вызывается клиентом — но не смонтирован на сервере.** Фича «свои серверы» молча не работает в проде.
2. **Расширения реализованы дважды**: core-side `ExtensionHost` (с токенами и скоупами) смонтирован, но не имеет ни одного клиента; реально работает app-side JS-мост с проверкой прав в Dart. Два реестра прав, два стора, два верификатора манифеста.
3. **Знание о движках продублировано в Dart**: UI хардкодит список движков и per-engine логику построения плана, потому что контракт (`GetAbout.EngineBuild`) не отдаёт capabilities.

Плюс: добавление 4-го движка — это правки минимум в 8 местах Go + упаковка + 4 места в Dart, без API регистрации драйверов. Плагины протоколов без форка невозможны.

Хорошая новость: фундамент (границы процессов, контракт, авторизация, план как anti-corruption layer, обновления) спроектирован честно и в основном соблюдается. Ниже — что именно хорошо, что сломано, и что делать в порядке приоритета.

---

## Сильные стороны

**1. Граница процессов чистая и соблюдается.**
`docs/architecture.md` описывает: Flutter-приложение (без сети, без прав, без секретов) → gRPC по unix-socket `/run/sora/core.sock` / named pipe `\\.\pipe\sora-core-v1` → служба `sora-core` (Go) → движки отдельными процессами, конфиг через stdin. Проверка показала: UI не спавнит движки (все `Process.start` в `app/lib/src/desktop/desktop.dart` — только рестарт самого приложения и pkexec для `sora-update`), парсинг ссылок серверов — через RPC `ParseImport` в `core/parser` (Dart сам парсит только *подписки* в `app/lib/src/desktop/links.dart`, что корректно), секреты не покидают core (`core/secret`, `PutSecret`/`DeleteSecret`).

**2. Движки за интерфейсом с capability-каталогом.**
`core/engine/engine.go:133-158` — интерфейс `Engine` (Validate/Apply/Stop/Groups/Select/Delay/Counters/Events). `core/engine/catalog.go` — матрица протоколов и фич на движок, `SelectEngine` выбирает первый, который тянет план, с объяснением отказов. Док-комментарий в `engine.go:1-3` («Callers avoid engine-specific configuration») — правильный принцип. Композиция через декораторы: `bypass.Wrap(inner, ...)` (`core/engine/bypass/bypass.go:231`), `xraytun.New` (`core/engine/xraytun/bridge.go:41`). Обнаружение бинарей — digest-verified каталог, PATH не используется (`core/engine/registry/registry.go:57-60`).

**3. Контракт как единый источник истины — с CI-контролем.**
`proto/` → `buf lint` + `buf breaking` + `buf generate`; `.github/workflows/repository.yml:90-97` проверяет `git diff --exit-code -- gen` для Go, Dart докручивает autofix-воркфлоу. Поля помечены `Since 1.N`. Ошибки — ключи каталога `core/errs/catalog.go`, которые едут в `SoraError.user_message_key` (`proto/sora/core/v1/core_control.proto:392`) и резолвятся в l10n на клиенте — дублирования текстов нет, только ключи по конвенции.

**4. Авторизация fail-closed.**
`core/control/authz.go:14-29` — явный allowlist read-only методов, **неизвестные методы по умолчанию control-only** (`checkMethodAuth`). Плюс IPC peer credentials (`core/ipc`), плюс control authenticator из `Handshake`. Правильная глубина обороны.

**5. Anti-corruption layer между proto и движками.**
`core/control/plan.go:172` `planFromProto` переводит `SessionPlan` в `engine.Plan`; валидация плана до выбора движка; `engine.Missing(p)` объясняет, чего не хватает. Dart строит *намерение*, core — *исполнимый план*.

**6. Обновления: честная граница доверия.**
`app/lib/src/updates.dart:438-444` — комментарий прямо говорит: проверка хеша в приложении это *integrity only, не подпись*. Подпись minisign перепроверяет как root привилегированный `packaging/linux/sora-update` через pkexec (`updates.dart:463`). Windows — через установщик. Fail-closed на незавершённой key ceremony.

**7. `service/sync` — образцовое выделение.**
Отдельный Go-модуль (`service/sync/go.mod`, без replace — не может импортировать типы core), документы — opaque blobs (`service/sync/sync/sync.go:26-31`, «the daemon never parses them»), Noise_XX + mDNS + QR. Жизненный цикл демона честно владеет приложение (`app/lib/src/sync_daemon.dart`: состояния idle/starting/running/unavailable/failed, reuse по `http_addr`+токен, SIGTERM→SIGKILL). Статус на 2026-10-20 честно зафиксирован в комментарии (`sync_daemon.dart:60-64`): document bridge ещё не привязан.

**8. Задел под Android существует, а не декларируется.**
`core/guard/guard.go:17-19` `NoopFirewall` спроектирован под «system-owned tunnels such as Android VpnService»; `docs/android-vpnservice.md` — детальный чек-лист (VpnService.prepare, protect(), 16KB pages, lockdown). Это редкий случай, когда будущая платформа учтена в интерфейсах заранее.

---

## Слоп/проблемы

### P0 — молча мёртвый код в проде

**A1. `CustomServers` не смонтирован на gRPC-сервере.**
- `core/control/custom.go:56-63` — `MountCustomServices` определён; единственный вызов — в `core/control/custom_test.go:67`.
- `core/cmd/sora-core/main.go` — ноль упоминаний «custom» (проверено grep по всем файлам `core/cmd/sora-core/`).
- Клиент вызывает: `app/lib/src/sora.dart:1521` `link.custom.listCustomServers(...)`, `app/lib/src/core/link.dart:31,74` создаёт `CustomServersClient`.
- Итог: весь стек (proto `proto/sora/custom/v1/custom.proto`, реализация 254 строки, 358 строк тестов, Dart-клиент, UI-карточка `app/lib/src/ui/servers.dart:644`) добавлен коммитом `5bcc46f`, но фича в проде отвечает `UNIMPLEMENTED`. Dart глотает это молча (`sora.dart:1529`: `if (error is GrpcError && error.code == StatusCode.unimplemented) return;` + комментарий «The service lands with the core update»). Один пропущенный вызов `plane.MountCustomServices(app.server)` — и нет теста, который бы поймал *класс* таких ошибок (wiring-тест «все proto-сервисы зарегистрированы»).

**A2. `ExtensionHost` смонтирован, но не имеет клиентов.**
- Сервер: `core/cmd/sora-core/main.go:366` `extv1.RegisterExtensionHostServer(...)`, токены, скоупы, `GrantedPermissions` (`main.go:359-364`).
- Клиент: `app/lib/src/core/link.dart:25-74` создаёт 4 клиента (CoreControl, CustomServers, Leak, Obfs) — `ExtensionHostClient` не создаётся нигде в `app/lib` (проверено).
- Реально панели расширений ходят через `app/lib/src/ext/bridge.dart:20-28` (`_methodPermission`) → Dart-колбэки → `CoreControl` с **полным токеном приложения**. То есть permission-модель расширений enforced в Dart-коде хоста WebView, а token-scoped дизайн из `proto/sora/ext/v1/ext_host.proto:9-18` (защита в глубину: даже скомпрометированный мост не выйдет за скоуп токена) — не используется.
- Усугубление: core-side стор (`<service-data>/extensions`, `main.go:348`) никогда не пополняется — установка/включение живут в Dart (`app/lib/src/ext/store.dart`), а `GrantedPermissions` читает core-стор. Даже если клиент появится, `MintToken` будет отказывать: два стора в split-brain.

**A3. Расширения реализованы дважды (нарушение DRY в security-critical месте).**
- Реестр прав: `core/ext/permissions.go:29-40` ↔ `app/lib/src/ext/permissions.dart:18-29` — дословный дубликат (`connections.read`, `servers.read`, `notifications`, `net.fetch`, `background`).
- Стор: `core/ext/store.go` (Install/Rollback/SetEnabled/Uninstall/GetSettings/SetSettings) ↔ `app/lib/src/ext/store.dart` (install/rollback/setEnabled/uninstall/getSettings/setSettings).
- Верификация: `core/ext/manifest.go`, `sign.go`, `package.go` ↔ `app/lib/src/ext/manifest.dart`, `verifier.dart`, `package.dart`.
- `core/ext/doc.go:19-21` честно признаёт: «The app (Flutter) owns the user-facing lifecycle … and mirrors the manifest and verification logic in Dart». Зеркало без механизма синхронизации: новое право/поле манифеста, добавленное в один реестр, — это либо дыра, либо молча сломанная фича во втором. Для «лучшего клиента в мире» это главный архитектурный риск.

### P1 — знание о движках утёкло в UI

**B1. Dart хардкодит движки, потому что контракт не отдаёт capabilities.**
- Пикер движков: `app/lib/src/ui/modes.dart:176-180` — `('', 'sing-box', 'xray', 'mihomo')` захардкожены; `modes.dart:182-196` — вопрос про control port привязан к строке `'sing-box'`; `modes.dart:239-255` — per-engine настройки `mihomoTunStack` / `xrayTunStack`.
- Построение плана: `app/lib/src/sora.dart:1894-1895` — `tunStack` switch по `settings.engine`; `sora.dart:1973-1975`, `sora.dart:2024-2025` — fallback-группы только при `settings.engine == 'mihomo'` (комментарий «Other engines compare only main members» — знание из `catalog.go`, продублированное в Dart).
- Категории логов: `app/lib/src/ui/logs.dart:90` — `['sing-box', 'xray', 'mihomo', 'zapret']`.
- При этом `GetAboutResponse.engines` (`proto/sora/core/v1/core_control.proto:603-608`, `EngineBuild`) несёт только `kind/installed/version` — **без фич и протоколов**. UI *вынужден* хардкодить: контракт не даёт данных для capability-driven рендера. Нарушен собственный принцип из `core/engine/engine.go:1-3` («Callers avoid engine-specific configuration») — на уровне Dart он не выполняется.

**B2. Добавление 4-го движка — правки в ≥12 местах, нет точки регистрации.**
Go: `core/engine/engine.go:17-21` (константы `Kind`), `core/engine/catalog.go` (матрица), `core/engine/catalog_linux.go` (фичи платформы), `core/engine/registry/registry.go:38,46` (приватный `drivers` map, наполняемый в `init()` — **нет публичного `Register`**), `registry.go:211` (хардкод `kind == engine.KindXray && p.Tun.Enabled` для моста), `registry.go:193` (`xraytun.New`), новый пакет `core/engine/<name>/` с `Prober`+`New`, `core/engine/supervise` (если свой контрол). Упаковка: `packaging/engines/engines.lock`, `packaging/engines/fetch.sh`, `packaging/linux/nfpm.yaml`. Dart: `modes.dart`, `sora.dart` (план), `logs.dart`, l10n-строки. Пара Xray+mihomo зашита как частный случай, а не как декларируемая композиция — следующий такой мост снова потребует хирургии в `selectPlan`.

**B3. Глобальное мутабельное состояние каталога.**
`core/engine/catalog_linux.go:5` — `func init() { Catalog[KindXray].Features[FeatureTun] = true }`. Мутация глобальной map в `init()` — порядок инициализации неявный, для тестов и будущих платформ хрупко.

### P2 — дубли знаний и мелкие разрывы

**C1. Версия контракта в двух местах вручную.**
`core/cmd/sora-core/main.go:50` (`control.Version{Major: 1, Minor: 11, MinSupportedMinor: 1}`) ↔ `app/lib/src/core/link.dart:20` (`ApiVersion(major: 1, minor: 11, minSupportedMinor: 6)`). `docs/development.md:104-112` требует бампить оба вручную. Семантика разная (пол клиента vs пол сервера), но рассинхрон уже виден невооружённо и ничто его не ловит.

**C2. Sync: мост документов не привязан.**
`app/lib/src/sync_daemon.dart:60-64` — честный комментарий: «The app-to-daemon document bridge (which document kinds the app feeds in) is not wired yet». Демон живёт пока живёт приложение (spawn при старте, SIGTERM при выходе, `desktop.dart:172`); кто рестартует упавший демон между запусками приложения — reuse по `http_addr`, но мёртвый демон = мёртвый синк до следующего запуска приложения. Для «работает безупречно» нужен супервизор или запуск от системы.

**C3. Мусор в репозитории.**
`reports/featlog-swarm-sw2.md` закоммичен в `b0932bb` — отчёты роя не принадлежат репозиторию (им место в `~/workspace/bug-hunt/reports/`). Процессный слоп; добавить `reports/` в `.gitignore`.

**C4. Мелкие дубли.**
- `version_ge` в `packaging/linux/sora-update` (sh) ↔ сравнение версий в `app/lib/src/updates.dart` — две реализации.
- `writeFileAtomic`: `service/sync/api/daemon.go:310` ↔ аналоги в core — приемлемо для отдельных модулей, но отметить.
- `core/ext/worker.go:7-8` — фоновые воркеры расширений «выполняет app-side JS runner»: кто их шедулит, когда приложение закрыто, — владение не определено (а core-side `WorkerFunc`/`ClampWorkerInterval` существует, но никем не вызывается из прод-пути — проверить при реализации).

### P3 — готовность к Android (честно: спека, не код)

- `app/` содержит раннеры только `windows`/`linux`; Android — только `docs/android-vpnservice.md`.
- `DefaultPreference` в `core/engine/catalog.go:150` («sing-box, Xray, mihomo») — desktop-образный порядок; на Android множество движков и kill-switch стратегия другие. Точка расширения (platform profile для registry + guard) пока не выделена, хотя `NoopFirewall` уже намекает.
- `app/lib/src/sync_daemon.dart:116-118` — `resolveBinary()` возвращает null на Android («Android cannot spawn the Go binary as a child process (contract §5)») — значит на Android sora-sync должен либо жить внутри процесса, либо не жить; решение отложено.

---

## Ранжированные рекомендации

**P0 — починить молча мёртвое, прежде чем строить новое**

1. **Смонтировать `CustomServers`**: добавить `plane.MountCustomServices(app.server)` в `core/cmd/sora-core/main.go` рядом с остальными `Register*` (строки 332-366). Одна строка.
2. **Wiring-тест на все proto-сервисы**: тест в `core/cmd/sora-core` (или `core/control`), который рефлексией `grpc.Server.GetServiceInfo()` сверяет зарегистрированные сервисы со списком `*_grpc.pb.go` — ловит весь класс «реализовал, но не смонтировал» навсегда. A1 и A2 оба ловятся этим тестом.
3. **Определиться с authority расширений** (самое важное архитектурное решение): либо панели идут через `ExtensionHost` (Dart минтит токен через `MintToken` и дергает ext-сервис — тогда permission-check в Dart-мосте становится defense-in-depth, а не единственной стеной; core-стор становится источником правды, Dart-стор — кэшем/зеркалом с протоколом синхронизации), либо удалить core-side `ext.NewHost`, `core/ext/store.go`, `permissions.go`, `manifest.go`, `sign.go` как мёртвый код и честно признать Dart единственным хозяином. Текущее «и то, и то» — худший вариант: security-check в двух местах без синхронизации.

**P1 — вернуть знание о движках в core**

4. **Отдавать capabilities в `GetAbout`**: расширить `EngineBuild` (`proto/sora/core/v1/core_control.proto:603`) полями `features[]`, `protocols[]` (или ссылкой на версию матрицы). Тогда `modes.dart` рендерит пикер из `about.engines`, TUN-стеки и fallback-шейпинг выбираются по фичам, а не по строкам `'mihomo'`.
5. **Перенести engine-специфичный шейпинг плана в core**: `sora.dart:1973-2025` (fallback→url-test для не-mihomo) и `1894-1895` (tunStack) — это нормализация плана, ей место в `core/control/plan.go` рядом с `planFromProto`, где уже есть прецедент (`registry.go:211-219` переписывает Xray-TUN план под мост). Dart шлёт намерение + `engines` pin; core решает, как его исполнить на выбранном движке.
6. **Публичный `registry.Register(kind, driver)`** вместо `init()`-наполнения приватной map (`registry.go:38-46`). 4-й движок тогда = новый пакет + одна строка регистрации + запись в `engines.lock`, а не хирургия в 8 файлах. Мост Xray+mihomo оформить как декларируемую композицию (capability `needs-packet-bridge`), а не `kind == KindXray` в `selectPlan`.

**P2 — убрать дубли и глобальное состояние**

7. `catalog_linux.go`: заменить мутацию глобала на платформенно-зависимую чистую функцию `platformCapabilities(kind)`.
8. Версия контракта: генерировать `apiVersion` в `link.dart` из одного источника (или тест на равенство minor в обе стороны).
9. Sync: привязать document bridge (какие kinds фидит приложение) и определить супервизию демона (systemd unit / launchd / Task Scheduler вместо «жив пока живо приложение»).
10. Удалить `reports/` из git, добавить в `.gitignore`.

**P3 — Android**

11. Выделить `PlatformProfile` для registry (порядок движков, доступные фичи TUN, стратегия kill-switch: `guard.Firewall` vs системный lockdown) — сейчас `DefaultPreference` и `BypassAvailable` (`registry.go:123-125`, `runtime.GOOS == "linux"`) захардкожены под десктоп. `NoopFirewall` уже есть — довести до интерфейса `PlatformPolicy`.

---

## Приложение: карта слоёв (фактическая)

```
Flutter app (пользователь, без привилегий)
  │  gRPC: unix-socket / named pipe; 4 клиента (CoreControl, CustomServers†, Leak, ObfsControl)
  │  † CustomServersClient есть, сервиса на сервере нет (A1)
  ▼
sora-core (Go, служба: LocalSystem / user sora + CAP_*)
  │  control.Server — фасад; authz fail-closed; planFromProto (anti-corruption)
  │  + LeakService, ObfsControl, CensorControl, ExtensionHost‡ (‡ смонтирован, клиентов нет — A2)
  ▼
engine iface → registry → supervise → процессы sing-box / Xray / mihomo (+ xraytun-мост, bypass-обёртка, tpws)

Отдельно:
  service/sync (sora-sync, свой Go-модуль) — демон, app спавнит/убивает, HTTP 127.0.0.1 + bearer
  packaging/linux/sora-update — sh-хелпер, pkexec, minisign как root
  Расширения: панели (WebView в app) → PanelBridge (Dart, проверка прав) → CoreControl;
             core/ext/* — параллельная неиспользуемая реализация (A3)
```

**Соответствие vision** («лучший клиент в мире, включая коммерческие; код — публичная витрина, ноль слопа»): фундамент держит — границы, контракт, авторизация, обновления, честность комментариев (редкий уровень: `updates.dart:438-444`, `sync_daemon.dart:60-64` прямо фиксируют, чего нет). Но A1–A3 — это именно тот слоп, который витрине противопоказан: мёртвый код, который *выглядит* рабочим (тесты зелёные, UI рендерится), и двойная реализация security-границы. Убрать A1–A3 и выполнить P1 — и архитектура будет соответствовать заявке.
