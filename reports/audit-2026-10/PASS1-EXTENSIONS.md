# Отдел расширений sora — проход 1/3 (PASS1-EXTENSIONS)

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`, пуша нет.
База: EXTENSIONS-40.md (волна 4). Здесь — только НОВЫЙ слой прохода 1:
что проверено по факту в коде, что доделано, что честно осталось.

Коммиты прохода (все — temp-index CAS-рецептом из AGENTS.md, чужие
staged-файлы не тронуты; подробности инцидента индекса — §8):

| Коммит | Содержание |
|---|---|
| `f84e415` | core/ext: tunnel transport, enforcement-матрица кодом, revocation cache, гейт ui.panel, fuzz wave 2 |
| `1574bf2` | control+cmd: ExtFetchTransport, планировщик в проде, kill switch, revocation cache на старте |
| `f6c64ea` | app: зеркало гейта ui.panel, enforcement.dart, честные тексты конфликтов (62 l10n-файла) |
| `285b5d8` | docs: threat-model синхронизирован с кодом |
| `b82be6d` | DX: CLI sora-ext (лендинг wave-40 WIP + ремонты прохода), hello-panel перепакован |

Проверки: `go build ./...` (чистое дерево на HEAD+изменения), `go vet
./ext/ ./control/ ./cmd/sora-core/`, `go test ./ext/` (весь пакет),
control-тесты ExtFetch/ExtKillSwitch + полный `./control/ ./cmd/sora-core/`,
CLI `go build/vet/test` + dogfooding всех команд. Fuzz: см. §6.
Примечание: в основном рабочем дереве сборка `control/cmd` СЕЙЧАС
заблокирована чужим WIP — import cycle `session ↔ diagnostics`
(untracked `core/session/deadmode.go` + `core/diagnostics/deadsession.go`,
не мои файлы); мои изменения верифицированы на чистом HEAD в отдельном
worktree, где всё зелёно.

---

## 1. Runtime

### Что было на самом деле (проверено grep'ом, не по отчёту волны 4)

- Overlap guard и circuit breaker в `core/ext/worker.go` — **реальны и
  покрыты тестами** (`TestWorkerRunSkipsOverlap`,
  `TestWorkerCircuitBreakerStopsAfterConsecutiveFailures`,
  `TestWorkerFailureCounterResetsOnSuccess`, kill-switch pause в
  `pause_test.go`). Механика честная.
- НО: `NewScheduler` **не имел ни одного прод-вызывающего**. Ни main.go,
  ни control не создавали планировщик; `SetFetchTransport` не вызывался
  никогда ⇒ в проде Fetcher'ы ездили на `http.DefaultTransport` —
  **direct dials мимо туннеля**. Плюс: ни в Go, ни в Dart **нет JS-движка**
  (ни goja/quickjs, ни app-side runner) — `WorkerFunc` это шов без
  исполнителя. Честный статус волны 4: «механика готова, прод — нет».

### Сделано в проходе 1

- **`core/ext/tunnel.go` (новый)**: `TunnelTransport` — RoundTripper,
  который на КАЖДЫЙ запрос резолвит адрес туннельного прокси и едет
  через loopback mixed-listener движка; туннеля нет ⇒ **fail-closed**
  `ext.netfetch.no-tunnel`, а не direct. `ProxyRoundTripper` отвергает
  не-loopback адреса (защита от переподключения на чужой прокси).
  Тесты: маршрут через прокси (origin видит штамп), fail-closed,
  пере-резолв при смене сессии, Fetcher end-to-end отказ без туннеля.
- **`control.Server.ExtFetchTransport`** (`exthost.go`): lookup по живой
  сессии — план с `LocalProxy.Enabled` (APPLICATION/system-proxy режим,
  либо TUN с явно включённым listener'ом) ⇒ `127.0.0.1:<LocalProxyPort>`;
  иначе — нет туннеля. `Config.LocalProxyPort` проброшен из main
  (`tunnelPort` supervise).
- **Планировщик в проде**: main.go создаёт `ext.NewScheduler`,
  `SetFetchTransport(plane.ExtFetchTransport())`, `Start/Stop` в Serve.
  **Ни одной задачи не регистрируется** — исполнителя JS нет; запускать
  пустой планировщик — plumbing, регистрировать фиктивные задачи было
  бы театром. В коде и здесь это помечено NOT WIRED.
- **Kill switch**: `Connect` (сессия может стартовать с включённым
  свитчом), `SetKillSwitch`, `Disconnect` зеркалят состояние в
  `Scheduler.SetKillSwitch` — воркеры ждут, fetch'и фейлятся быстро.
  Тест `TestExtKillSwitchSyncsToScheduler`.
- **TUN-режим**: план TUN не открывает listener ⇒ net.fetch честно
  отказывает `ext.netfetch.no-tunnel` (тест
  `TestExtFetchTransportTunPlanFailsClosed`). Езда «через сам TUN»
  потребует приватного аутентифицированного listener'а в plan-слое —
  это изменение чужой зоны (control/plan), вынесено в §7.

Осталось: JS-исполнитель воркеров (app-side runner или встраиваемый
движок в core) — без него `background` остаётся гейтом без рантайма;
приватный ext-listener для TUN-режима.

## 2. Security

### Enforcement-матрица — теперь КОД, а не проза

**`core/ext/enforcement.go` (новый)** — `EnforcementTable()`: 12 строк,
статусы `Enforced / InstallTime / Inert / Unimplemented`, поле `Where`
(где проверка) пусто ровно у не-enforced строк. Тесты пинят: полноту vs
реестр; «enforced ⇒ есть Where»; RPC-утверждения vs реальный
`rpcPermissions`; гейт background — поведенческим тестом; **Dangerous
строки обязаны оставаться не-enforced**, пока не появится поведенческий
пин настоящего гейта (документацией статус не поднять).
Зеркало: `app/lib/src/ext/enforcement.dart` (новый) с `isNotYetActive()`.

**Честный итог по 12 permissions после прохода 1:**

| Permission | Статус | Где проверка / почему нет |
|---|---|---|
| `connections.read` | ✅ enforced | host.go `Host.check` (каждый вызов) + bridge.dart |
| `servers.read` | ✅ enforced | host.go + bridge.dart |
| `notifications` | ✅ enforced | host.go + капсы текста + bridge.dart |
| `net.fetch` | ✅ enforced | гейт на конструировании Fetcher'а (RegisterConfig) + checkURL на каждый запрос + туннель/fail-closed (проход 1) |
| `background` | ✅ enforced (гейт) | RegisterConfig: capability+permission, кламп, overlap, breaker, kill-switch. **Исполнителя нет** — код расширений не выполняется |
| `ui.panel` | ✅ install-time (**стал настоящим гейтом**, проход 1) | см. ниже |
| `settings.read` | ⚠️ inert | API к настройкам приложения не существует; свои настройки расширения — permissionless by design. Честный маркер, не театр |
| `settings.write` | ⚠️ inert | то же |
| `tray` | ⚠️ unimplemented | tray-API нет |
| `theme.apply` | ⚠️ unimplemented | тема — контракт+пример есть, потребителя нет |
| `routing.rules` | ⚠️ **unimplemented, RiskDangerous** | ноль кода проверок; потребитель не построен |
| `net.hooks` | ⚠️ **unimplemented, RiskDangerous** | ноль кода проверок; потребитель не построен |

Итого: **5/12 enforced на каждый вызов, 1/12 настоящий install-time
гейт, 2/12 честно inert, 4/12 честно не реализованы.** Оба RiskDangerous
по-прежнему unenforced — но теперь это утверждает машинно-читаемый код
с тестами, а не только проза threat model.

### Гейт ui.panel (новая настоящая дыра, закрыта)

Панели НИКАК не были связаны с `ui.panel`: манифест мог объявить панели
без capability `ui-panel` и без permission `ui.panel` — промпт
пользователя вообще не упоминал встраивание UI. Теперь `Validate`
(Go `manifest.go` + зеркало Dart `manifest.dart`): панели ⇒ требуются
capability И permission, по образцу существующих `_checkAssetRef`.
Фикстуры тестов, panel-шаблон CLI и пример hello-panel приведены в
соответствие; hello-panel **перепакован и переподписан** свежим
throwaway-ключом (README примера честно говорит, что это не trust
anchor).

### Revocation list — свежие проверки

Было: `VerifyRevocationList` + enforcement в Store — **без единого
прод-вызывающего и без транспорта/хранилища**: список никогда не
загружался, enforcement не мог сработать в принципе.
Сделано: **`core/ext/revocation_cache.go` (новый)** —
`RevocationCache` (на диск пишутся только верифицированные байты),
`Refresh` (fetch `.json`+`.minisig` → verify → cache; при любой ошибке —
fallback на кэш), `ApplyToStore`. На старте sora-core применяет
кэшированный список к Store (main.go, best-effort, политика «нет кэша —
установки разрешены» сохранена). Тесты: roundtrip, отказ хранить мусор,
битый кэш = нет кэша, fallback при fail-closed верификации, цепочка
cache→Store→отказ в enable.
Честно осталось: **триггера `Refresh` в проде нет** — нет опубликованного
team endpoint, а верификация fail-closed до key ceremony, поэтому кэш
сегодня может быть только пустым. Механизм готов; церемония — за
владельцем.

### Threat model vs код

`docs/extensions/threat-model.md` синхронизирован: строки net.fetch /
background / ui.panel переписаны под факт, §7 дополнен статусом
revocation-пайплайна, §10 — новыми fuzz-таргетами, enforcement.go назван
авторитетным источником матрицы. Панельный CSP (полный lockdown из
финального аудита: `default-src 'self'`, `connect-src 'none'`, img/font/
style/worker/object/form/frame закрыты) и path-traversal защита
loopback-сервера (сегментная проверка `.`/`..`/кодировки/`\`/`:` +
канонизация пути) — **перепроверены в `panel_screen.dart`, на месте,
дыр не найдено**.

## 3. Store

Проверено по коду и тестам (`catalog_store_test.go`, присутствуют в
дереве и зелёны):

- **max_age / offline cache**: `CatalogCache` (Store/Load/Refresh/Fresh),
  `max_age` 300..604800, дефолт 3600; Refresh при ошибке сети/подписи
  отдаёт кэш с `fromCache=true`; битый кэш = нет кэша, не краш. Dart-
  зеркало (`catalog.dart`) повторяет семантику 1-в-1, включая Fresh.
- **Staged rollout**: `rollout_fraction` + детерминированный бакет
  `sha256(install_id|id|version)`, `RolloutEligible` идентичен в Go и
  Dart; тесты на стабильность и распределение — зелёны.
- **Honest ratings / анти-гейминг**: `ratings.go` — байесовское среднее
  (prior 3.0, C=12), затухание half-life 180 дней, дедупликация «1
  аккаунт = 1 голос (последний)», `RankScore` с log-установками. Честная
  оговорка: это **нормативная математика**; считает сервер каталога,
  клиент только отображает готовые числа из подписанного каталога.
  Velocity/account-age проверки — серверные, в этом репозитории их нет и
  быть не должно. Анти-гейминг на клиенте не имитируется.

⚠️ **Флаг для родителя**: `core/ext/ratings.go`, `ratings_test.go`,
`catalog_store_test.go` до сих пор **untracked** в рабочем дереве (WIP
волны 40, не мои файлы) — при чистке дерева они пропадут. Владельцам
зоны стоит залендить. То же — `app/lib/src/ext/conflicts.dart` +
`conflicts_sheet.dart` (не лендил сознательно: они ссылаются на грязный
`store.dart` чужой зоны; коммит без него сломал бы дерево Dart).

## 4. DX

Dogfooding CLI нашёл то, что вычитка не видит:

- **`sora-ext` не собирался**: `validate.ValidatePackage` вызывал
  несуществующий `ext.Open` (есть только `OpenBytes`). Починен; теперь
  ещё и сохраняет `ManifestExt` в результат.
- **3 из 5 шаблонов scaffold были сломаны**: theme просил
  `theme.css.tmpl` (файла нет *по дизайну* — темы это данные, не CSS;
  убрана строка из scaffold), routing просил `rules.json`, а шаблон
  `routing.json.tmpl` нёс устаревший v0-контракт (обновлён под
  spec-routing-hooks: routing_version, id, priority; entry выровнен с
  примером — `routing.json`), у background **не было манифеста вообще**
  (добавлен: background+net.fetch, background_task, network_hosts под
  worker.js.tmpl). Все 5 шаблонов: scaffold → validate → pack → sign →
  publish-gate проходят.
- **Честные предупреждения авторам** (`warnUnenforced` в validate):
  манифест с inert/unimplemented permissions получает warning с
  объяснением «granting changes nothing yet» из `EnforcementTable` —
  разработчик больше не строит фичи на воздухе молча.
- **JSON Schema**: покрывает v1ext-поля (network_hosts, background_task,
  ui), enum'ы permissions/capabilities актуальны — дыр не найдено.
- **TS defs** (`sora-ext.d.ts`): сверены с bridge.dart 1-в-1 (методы,
  unsubscribe у onEvent, коды ошибок) — расхождений не найдено.
- Mock (`sora-ext serve`): permission enforcement в mock'е есть и честно
  помечен как mock.

Осталось разработчику: `sora-ext dev` app-контракт по-прежнему спека без
принимающей стороны в приложении (как и было заявлено в волне 40);
hot-reload работает только против mock-окружения.

## 5. UI

- **Permissions sheet**: тексты и 3 честных состояния промпта перепроверены.
  Остался один шаг честности: строки inert/unimplemented permissions
  пока рендерятся как обычные. Машинный маркер готов
  (`enforcement.dart::isNotYetActive`), предложен l10n-ключ
  `extPermNotYetActive` («пока не активно в этой версии») — врезка в
  `permissions_sheet.dart` + ключ в arb оставлены проходу 2/UI-зоне:
  файл грязный чужой зоной прямо сейчас, лезть в него — риск из
  AGENTS.md.
- **Конфликты — найдена нечестная строка**: `extConflictNote` утверждал
  «применяется движком», `extConflictsIntro` — «возможность будет
  приостановлена». Ни то, ни другое не wired (S5-enforcement — handoff
  в Go-core, потребитель отсутствует). Исправлено во всех 62
  l10n-файлах (en+ru тексты, остальные локали — en-фолбэк, как принято в
  проекте): выбор сохраняется и будет применён, когда движок поддержит
  эти возможности. Докстринг `conflicts.dart` поправлен синхронно.
- **Store UI**: баннер кэша, rollout-гейтинг, отменяемая загрузка,
  методология рейтинга — перепроверены против Go-семантики, расхождений
  не найдено.

## 6. Fuzz

Новые сиды из реальных кейсов в `FuzzParseManifest`: полный
v2-манифест, dangerous-сет, panel-entry атаки (`%2e%2e`, `..%2f`,
`panel.html:evil` ADS, backslash) + честный entry.

Три новых таргета:

| Таргет | Что ловит | Прогон |
|---|---|---|
| `FuzzParseManifestFull` | v2-половина, до которой v1-фаззер не достаёт (unknown keys отбрасываются раньше): background/hosts/поинтеры/гейт панелей | 60s, 1 613 924 execs, 0 находок |
| `FuzzParseRevocationList` | парсер emergency brake: shape-инварианты, детерминизм `IsRevoked`, nil-список | 45s, 215 125 execs, 0 находок |
| `FuzzFetchURLPolicy` | URL-политика net.fetch: принято ⇒ https, без userinfo/IP/портов, хост в allowlist (проверка независимая, сети нет) | 45s, 188 620 execs, 0 находок |

Инварианты приняты = «пере-валидируется второй, независимой проверкой»,
как в существующих таргетах.

## 7. Что осталось (с причинами)

1. **JS-исполнитель background-воркеров** — нет движка ни в core, ни в
   приложении. Решение владельца/архитектуры (goja в core vs app-side
   runner). До него `background` — честный гейт без рантайма.
2. **net.fetch в TUN-режиме** — нужен приватный аутентифицированный
   listener для расширений в plan-слое (зона control/plan). Сейчас —
   fail-closed, не direct: утечки нет, функции в TUN нет.
3. **Триггер revocation Refresh** — после key ceremony: вшить в
   catalog sync (endpoint + расписание). До церемонии бесполезен.
4. **Потребители routing.rules / net.hooks / theme.apply / tray** —
   спеки волны 40 готовы; каждый потребитель обязан в том же коммите
   поднять свою строку в enforcement.go и добавить поведенческий пин.
5. **Permissions sheet: маркер «пока не активно»** — маркер и ключ
   предложены (§5); врезка ждёт стабилизации файла UI-зоной.
6. **S5 conflict enforcement** (применение победителя в core) — handoff
   из волны 40, контракт `conflicts.json` стабилен; тексты UI уже не
   врут про него.
7. **Key ceremony (minisign)** — за владельцем; весь team-путь
   (каталог, revocation) fail-closed до неё, как и было.

## 8. Инцидент индекса (для родителя, важно)

После моих коммитов обнаружил: реальный git-индекс содержит **staged
снапшот старого дерева** (138 файлов): в нём мои только что
закоммиченные файлы (`core/ext/tunnel.go`, весь `tools/`, …) значились
**удалёнными**, а l10n — откаченными к до-фиксовым текстам. Чей-то
stale-index (паттерн из AGENTS.md). По прямой инструкции задачи снял
`git restore --staged` **только 47 staged-удалений** (индекс снова без
удалений; рабочее дерево не тронуто). Осталась 91 staged-модификация
(proto/sync/l10n и др.) — чужая, не трогал. ⚠️ Если её владелец закоммитит
bare-коммитом со stale-деревом, l10n-фикс `f6c64ea` будет откачен, а
proto/sync могут потерять промежуточную работу — владельцу индекса
стоит пересобрать его от текущего HEAD.
