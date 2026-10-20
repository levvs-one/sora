# partial-04-e2e — end-to-end честность фич (подкома №4)

Дата: 2026-10-20. Репозиторий: `~/workspace/bug-hunt/sora`, ветка `bugfix/audit-2026-10-19`.
Метод: read-only трассировка кода «UI → Dart-клиент → gRPC → Go-ядро → реальный эффект».
Dart-тулчейна нет — вычитка; Go собирается (`go build ./...` не запускался в этом
аудите, только чтение; TSPU-FINISH фиксирует зелёный build/vet).

Легенда вердиктов: **WIRED** — цепочка UI→RPC→ядро→эффект прослежена кодом;
**PARTIAL** — работает частично, указано что именно; **THEATER** — экран/тумблер есть,
функции нет (Critical для честности продукта). Нарочно не завышено.

## 0. Коммит-дисциплина (блокер для фиксов)

**Коммитов в этой подкоме не сделано.** Причина: staged-индекс снова чужой —
`git diff --cached --stat` показывает 6 модифицированных док-файлов, которые я не
трогал (`README.en.md`, `README.md`, `docs/README.md`, `docs/extensions.md`,
`docs/faq.md`, `docs/usage.md`; удалений в staged сейчас нет — `git diff --cached
--name-status | grep -c ^D` = 0). По срочному предупреждению родителя: не коммитить,
сообщить в отчёте. Все находки ниже — как спеки/патчи, ничего не приземлено.

Дополнительно: `core/diagnostics/deadsession.go` + `deadsession_test.go` (T029)
**не в HEAD** — только untracked worktree-файлы (см. находку #7). Коммит любого
файла из `core/` pathspec-формой сейчас — безопасен по путям, но запрещён
директивой из-за отравленного индекса.

Post-scriptum (во время аудита): HEAD продвинулся (`a10165e` — чужой
`[final-audit]` про dnsleak), staged-6-файлов не унесён им; состояние индекса на
конец аудита то же, что в начале. Перепроверить перед любым своим коммитом.

## 1. Таблица вердиктов

| Фича | Вердикт | Доказательство цепочки (файл:строка) |
|---|---|---|
| F1 QR шеринг/скан | **WIRED** | Share: `app/lib/src/ui/servers.dart:672` `_shareQr` → `sora.fetchSubscriptionLink` (`app/lib/src/sora.dart:1609`) → `stub.getSubscriptionLink` → `core/control/subscriptions.go:717` (возвращает `rec.URL`). Scan: `servers.dart:122` → `ui/qr.dart:169` `_import` → `parseImportLink` → `showSubscriptionSheet` → `sora.addSubscription` (`sora.dart:1560`) → `SaveSubscription` RPC → сервер `FetchSubscription` переиспользует `ParseImport` (`core/control/server.go:1111`, импл. `server.go:957`). QR скрывает ссылку (H-коррекция в `QrShareScreen`). |
| F2 benchmark | **WIRED** (+ Low: мёртвый RPC `GetBenchmarks`) | `ui/benchmark.dart:37,93` → `sora.benchmarkServers` (`sora.dart:1990`) → streaming `stub.benchmarkServers` → `core/control/benchmark.go:31` → `probe.Benchmarker.Benchmark` (временные сессии движка, `core/probe/bandwidth.go`; история `probe/history.json` с TTL, in-memory + файл). Smart-скоринг потребляет результаты: `smartScoreOf`/`compareAutoSelect`/`autoSelect` (`sora.dart:2325+`, `settings_screen.dart:386-389`, `servers.dart:321,385`). Dart держит свою копию истории (`settings.benchmarkHistory`, `sora.dart:1911-1928`). Найти: серверный `GetBenchmarks` (`benchmark.go:148`) **не вызывается ни из одного места Dart** — мёртвый RPC (сервер без клиента). |
| F3 DNS-менеджер + CheckDnsLeaks | **WIRED** | `_check` (`ui/dns.dart:112`) → `sora.checkDnsLeaks` (`sora.dart:377`) → `stub.checkDnsLeaks` → `core/control/dnsleak.go:20` → `diagnostics.CheckDnsLeaks` (3 проверки; сигнал hijack честно исправлен через `hijacksDNS`, не через мёртвое поле `HijackTun`). Пресеты: `_applyPreset` (`dns.dart:60-67`) → `settings.dns` → `buildPlan` `DnsPolicy(servers: settings.dns)` (`sora.dart:2151`) → `plan.go:312` `dnsFromProto`. |
| F4 экран подключений | **WIRED** | `_read` (`ui/connections.dart:73`) poll → `stub.listConnections`; `_close` (`connections.dart:105`) → `stub.closeConnection` → `core/control/logs.go:329,349` → `session.Connections` (`core/session/runner.go:454`) → `clashapi` (`core/engine/clashapi/ops.go:53`); «закрыть» — реально рвёт соединение (`CloseConnections`). `_addRule` — в sheet правил. Шапка скоростей — `getStats` RPC (`sora.dart:344`). Для xray — честное пустое состояние («xray engine cannot list connections»). |
| F5 сетевые профили | **PARTIAL** | WIRED: редактор профилей, локальный `ProfilesStore` (`profiles.dart`), ручное применение с undo (`sora.applyProfile/applyProfileWithUndo/undoProfileApply`, `sora.dart:1122-1208`), нудж-уведомления (`handleProfileMatched`). Go-сторона тоже написана: `checkProfile` в раннере (`core/session/runner.go:531,602`), `ProfileMatched` в `_watchSession` (`sora.dart:928-934`). NOT WIRED: `refreshFingerprint` (`sora.dart:1214`) **никогда не вызывает** `GetNetworkFingerprint` RPC → `networkFingerprint` навсегда `unknown()` → `ProfilesStore.match` всегда null (профили автоматически **никогда** не применяются); Dart никогда не вызывает `SaveProfile` → ядро-стор `core/profiles/` пуст → `checkProfile` матчит пустое. Экран честно показывает `s.networkUnknown`. Технический долг явно задокументирован в шапке `profiles.dart` («dual-store… Open owner decision»). Не THEATER (ручное применение реально), но автодетект-сети мёртв. |
| F6 override подписок | **WIRED** (app layer; осознанный dual-store) | UI: `ui/subscription.dart:264,283,317,389` (скрыть/переименовать) → локальный `OverrideStore` (`overrides.dart`). Применяется: скрытие в списках (`ui/servers.dart:295`), исключение из автовыбора (`sora.dart:585-606` `withoutHidden`), переименования везде через `displayNameOf` (`sora.dart:574`). Переживают refresh (персистент в settings, ключи по server id). Ядерные RPC `SaveSubscriptionOverride/GetSubscriptionOverride` (`core/control/override.go`) реализованы, но Dart их не вызывает — задокументировано в шапке `overrides.dart` как owner decision. |
| F7 живучесть | **WIRED** | Ядро: `crashWatch` (`core/session/watchdog.go`: 5 крашей/60с → `KeyEngineUnstable` в журнале, `runner.go:548-557`). UI: watchdog `WatchEvents` (`sora.dart:896-986` — счётчик разрывов, 5 подряд → видимая ошибка + кнопка ремонта `repairWatch`); баннер `_WatchBanner` (`ui/home.dart:75,179`). Crash-intent: `checkCrashIntent`/`restoreCrashedSession` (`sora.dart:1010-1080`), баннер в `home.dart:219`. Staged updates: `updates.dart` — стейджинг в temp-dir, hash-verify vs manifest, `_prepareRollbackCache` ДО handoff, `checkPendingUpdate`/`noteCoreHealthy`/`_rollback`; Windows in-app путь честно fail-closed (`signatureRequired`, коммент SORA-H1; привилегированный хелпер перепроверяет подпись как root). |
| F8 цепочки прокси | **THEATER** (connect-функция) / PARTIAL (редактор) — **Critical** | Go-реализация полная: `applyChain` → `Via` (`core/control/plan.go:395-417`), `ProbeChain` RPC (`core/control/chain.go:23`), per-engine `FeatureChains` в каталоге (`core/engine/catalog.go:41,68,95`). Dart: редактор + `connectChain` (`sora.dart:1226` — валидации, fail-loud на битые хопы), `buildPlan(chain: hops)` (`sora.dart:2194`), API-minor guard 1.10. **НО:** `connectChain` первым делом бросает `chainUnsupported`, если `coreCapabilities` не содержит `'chains'`; capability берётся из `apiVersion()` ядра (`sora.dart:699` ← `GetAbout` ← `apiVersion()`), а `Capabilities()` (`core/control/server.go:89`) **никогда не возвращает `"chains"`** — `apiVersion()` (`server.go:339-348`) добавляет только `"serverless"`. Итог: `connectChain` бросает `chainUnsupported` **на любом реальном ядре**, UI показывает баннер «unsupported» (`ui/chains.dart:56`) — подключить цепочку невозможно. Заявление FEATURE-REPORT («connectChain … теперь реально строит план и подключается») **неверно в рантайме**. Спек фикса — в §2 находка #1. Мёртвый RPC: `ProbeChain` не вызывается из Dart. |
| F9 device sync | **WIRED** | UI `ui/sync.dart` реально управляет демоном `service/sync`: `SyncDaemon.ensureRunning` → `Process.start(sora-sync, ['--data-dir', dir])` (`sync_daemon.dart:209`), ожидание `http_addr` (10с), чтение `api_token` (0600), health `GET /v1/status`; reuse-путь с bearer-проверкой (`_tryReuse`); SIGTERM→wait→SIGKILL при выходе; Android → честное «unavailable» (контракт §5). QR: `POST /v1/pairing/start` → QR от демона (`ui/sync.dart:699`); скан: локальная валидация `SyncPairing.decodePairPayload` (`sync.dart`) — побайтовый миррор Go `pairing.Decode` (`service/sync/pairing/pairing.go:80`) → `POST /v1/pairing/join` с сырой строкой; «paired» только по ответу демона; реестр пиров — демон. Формат сверен побайтово: тест-векторы контракта `T1`/`TestVectorsReject` замиррорены в Dart-тесте `app/test/sync_qr_test.dart`. Документы: `SyncDocumentBridge` (`sync_docs.dart`) публикует `subscriptions`, `app_settings` (вкл. `rules` — в `syncableSettingsKeys`, `settings.dart:388-399`), `overrides`, `profiles`, `chains`, `obfs` и применяет входящие (merge). Старый «реестр устройств» честно удалён (`_migrateLegacyRegistry`, `ui/sync.dart:94`). |
| F10 расширения | **PARTIAL** | WIRED: манифест v1 + пермиссии; `.soraext`-верификация в едином гейте `install()` (`ext/store.dart:327`, zip-path checks); install/update/rollback (`store.dart:424`), enable/disable, sideload UI с предупреждением (`ui/extensions/store_screen.dart:87,140`); подписанный каталог с team-verify (`ext/catalog.dart:268` `fetchRawCatalog` + `verifyCatalogSignature`); панели в WebView с пермишн-allowlisted bridge (`ext/bridge.dart`: `getConnections/getServers/notify/getSettings/setSettings` — реальные обработчики). NOT: (a) **каталогные установки недостижимы**: team-ключ — плейсхолдер (`ext/verifier.dart:17-20`, `teamSigningConfigured=false` → fail-closed отказ) и `defaultCatalogUrl = extensions.sora.example` — ждёт церемонии ключа владельца (честно); (b) Go `core/ext` + `ExtensionHost` gRPC зарегистрированы в `sora-core` (`core/cmd/sora-core/main.go:443`) **без единого клиента**: у приложения нет сгенерированных ext-стабов вообще, UI ставит в *отдельный* Dart-стор — Go-стор (`dataDir/extensions`) остаётся пустым; `MintToken`/`WatchExtensionEvents` из продукта недостижимы; (c) `BackgroundTaskConfig` (`ext/store.dart:616`) редактируется в UI (`detail_screen.dart:558-593`), но **ничто его не исполняет**: Go-`Scheduler` (`core/ext/worker.go`) читает только пустой Go-стор. |
| F11 VPN+zapret | **WIRED** | Тоггл `ui/modes.dart:269-271` → `settings.zapretWithVpn` → `buildPlan` (Linux && `serverlessAvailable`, `sora.dart:652,1304`) → `SessionPlan.zapret_with_vpn` (field 16, сгенерированный Dart-pb и Go-pb совпадают: `core_control.pb.go:1024`) + `zapretStrategy` из настроек tpws-шейпинга (`sora.dart:2180`, НЕ дефолт ядра) → `plan.go:325` `applyZapretWithVPN` (синтетический bypass-outbound, ретаргет `direct`-правил) → `registry.go:201` `bypass.Wrap` (tpws-супервизор); `registry.go:171` — честный отказ при отсутствии tpws. Верифицировано, что клиентский путь не попадает в nfqws-дефолт (см. Low-заметку ниже). |
| Censor-детекторы (swarm) | **PARTIAL** | В ядре WIRED: унифицированный `probe.FreezeDetector` (`main.go` → `prober.SetFreezeDetector`), `OnFreeze` → journal + `ExpediteForCensorship` (`session/censor.go` watcher → `Manager.SetCensorshipHook`, `main.go` → `plane.ExpediteForCensorship`, `core/control/censor.go`), `DetectCensorship` RPC реализован и зарегистрирован (`core/control/censor.go:22`, `main.go:422`). Клиентская видимость — **инертна**: `CensorDetector.fetchVerdict` (`core/censor.dart:111`) **никогда не присваивается**; `pollAfterFailure` — вечный no-op (коммент `sora.dart:319` признаёт); `proto/sora/censor/v1/censor.proto` **существует**, но Dart-стабы не сгенерированы (`app/lib/src/generated/sora/` содержит только `core`,`custom`,`leak`); `ui/censor.dart` показывает `history`, которую ничто не наполняет → экран «Blocking diagnostics» вечно в пустом состоянии. Эффект в ядре (ускоренный refresh подписок при цензуре) — реален. |
| Obfs-экран (swarm) | **WIRED** | `ui/obfs.dart` `_load` → `sora.getObfsCapabilities` (`sora.dart:410`) → `obfs` gRPC; `_update` → `updateObfs` → `applyObfsProfile` RPC (`sora.dart:444`, per-engine capability check, `needsReconnect` баннер); ядро персистит и **мержит профиль в каждый `Connect`** (`core/control/server.go:565` `MergeObfsProfile`). |
| NOT WIRED-маркеры (17 файлов Go) | **осознанные** | Проверены все: `diagnostics/dnsintercept.go` (T010), `diagnostics/throttle.go` (T018), `engine/bypass/nfqws_queue.go` (T005), `engine/bypass/fakettl.go` (T015), `engine/bypass/split.go` (T031), `engine/ss.go` (T020), `engine/stealth/stealth.go` (S8), `probe/quic.go` (T008), `probe/serial.go` (T041), `probe/calibrate.go` (T021), `probe/trojan.go` (T022), `probe/calibrate.go`, `censor/budget.go` (T007), `censor/whitelist.go`, `select/select.go` (SW3), `tune/doc.go` + `tune/desync/doc.go` (SW1d), `censor/siberian.go` (FreezePolicy-actions; honest production-status header). Каждый снабжён причиной + отсылкой к спеке/решению владельца (TSPU-FINISH §3/§8, SWARM-REPORT: owner decisions S8/SW1d/SW3/SW4-tier2/S9) — **забытых среди них нет**. Исключения — находки #7 и #8 ниже. |

Legacy: волны 1–3 и TSPU-фазы реализованы только в `sora`; `sora-legacy`
аудитом фич не затрагивается (отдельный `SORA-LEGACY-DRIFT.md`). Dart-вычитка без
тулчейна — риск несоответствий hand-written protobuf-стабов реален; сверка
перегенерацией — в списке владельца (FEATURE-REPORT «Проверки»).

## 2. Находки по критичности

### #1 Critical — F8: «цепочки прокси» невозможно подключить (гейт capability не завайрен)

- **Что:** `CoreControl.Capabilities()` (`core/control/server.go:89-103`) возвращает фиксированный список без `"chains"`; `apiVersion()` (`server.go:339-348`) добавляет только `"serverless"`. Dart `chainsSupported` = `coreCapabilities.contains('chains')` (`chains.dart:14`, `sora.dart:568`) всегда false на живом ядре → `connectChain` всегда бросает `chainUnsupported` → экран показывает «unsupported» (сам по себе честно). Весь остальной F8 (`applyChain`, `ProbeChain`, `Via`-рендеры, редактор, restore-логика `chain:`) написан и протестирован.
- **Почему Critical:** определяющая функция фичи недостижима; FEATURE-REPORT заявлял тень закрытой — ложно.
- **Спек фикса (НЕ применён, см. §0):**
  В `core/control/server.go`, в `apiVersion()` рядом с веткой `"serverless"`:
  ```go
  if chainProvider, ok := s.measurer.(chainAvailability); ok && len(chainEngines(chainProvider)) > 0 {
      capabilities = append(capabilities, "chains")
  }
  ```
  (`chainAvailability`/`chainEngines` уже существуют в `core/control/chain.go:77-96` — тот же гейт, что `ProbeChain`.) Тест: `core/control/contract_test.go` — зафиксировать, что capabilities содержат `"chains"` при availability с `FeatureChains` и не содержат без него. После фикса Dart-путь `connectChain → buildPlan(chain) → Connect` становится рабочим без изменений на клиенте.

### #2 Critical — F8-дух: RPC без клиентского вызова

- `ProbeChain` (`core/control/chain.go:23`) и `GetBenchmarks` (`core/control/benchmark.go:148`) реализованы на сервере, в Dart не вызываются нигде. Класс «RPC без клиентского вызова» из задания. Low по отдельности (не являются заявленной фичей для пользователя), но фиксируется как долг.

### #3 High — F10: extension background tasks и Go-хост недостижимы из продукта

- `core/ext` (store/scheduler/worker), `ExtensionHost` gRPC (`proto/sora/ext/v1/ext_host.proto`, зарег. в `main.go:443`) — живые в бинари, но: (а) у приложения нет стабов и нет пути установки в Go-стор; (б) UI ставит расширения в отдельный Dart-стор; (в) `BackgroundTaskConfig` настраивается в UI, но исполнителя нет ни на одной стороне для UI-расширений.
- **Спека:** решение владельца — либо удалить Go-сторону (если расширения = только Dart+WebView), либо завайрить UI на `ExtensionHost` (install/mint/статусы) и убрать двойной стор. Текущее состояние — театральная инфраструктура внутри продукта; сам стор-панельный MVP — реален (см. таблицу).

### #4 High — клиентская «диагностика блокировок» инертна (censor UI)

- Экран `ui/censor.dart` вечно пуст: `fetchVerdict` не присваивается, стабы `proto/sora/censor/v1` не сгенерированы (proto существует!). Эффект в ядре (`ExpediteForCensorship`) реален, но пользовательский сценарий «детектор сказал блокировка → предложить профиль» не работает.
- **Спека:** сгенерировать Dart-стабы `censor.proto`, реализовать `fetchVerdict` через `DetectCensorship` (с таймаутом, fail-quiet), проглотить pushed `CoreEvent.censorVerdict` (п.920 `sora.dart` TODO). Тогда `ingestCensorVerdict`/`handleCensorVerdict` оживут.

### #5 Medium — F5: автоприменение профилей по сети мёртво

- `refreshFingerprint` не вызывает `GetNetworkFingerprint`; Dart не вызывает `SaveProfile`. Работают: редактор, ручное применение, undo, нудж по `ProfileMatched`.
- **Спека:** завайрить `refreshFingerprint → GetNetworkFingerprint` + push профилей через `SaveProfile` при изменении Dart-стора (один стор правды), либо честно удалить из UI триггеры SSID/шлюз/ASN как «скоро». Код уже сам честно это помечает (TODO в `sora.dart:1205`).

### #6 Medium — F10: каталог расширений недостижим (известный блокер)

- Team-ключ плейсхолдер (`ext/verifier.dart:17-20`), `defaultCatalogUrl = extensions.sora.example`; установки из каталога — fail-closed отказ. Честно, но это owner action (церемония ключа) — повторить в owner checklist.

### #7 Medium — T029 `DetectDeadSession`: код вне HEAD

- `core/diagnostics/deadsession.go` (+ тест) — только untracked worktree-файлы (см. §0), в `git ls-files` отсутствуют; маркер NOT WIRED есть в файле, но build/тесты в CI его не видят, `go build ./...` его не компилирует. TSPU-FINISH §5 уже фиксировал; состояние не изменилось.
- **Спека:** либо `git add` + коммит (с atom
...[truncated 2146 chars]
