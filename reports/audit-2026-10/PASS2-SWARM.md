# PASS2-SWARM — четвёртый круг feature-роя sora, проход 2/3: end-to-end верификация F0–F11 + расширения

Дата: 2026-10-20 (проход ~09:00–09:15 MSK). Ветка `bugfix/audit-2026-10-19`
(`~/workspace/bug-hunt/sora`; регрессионная сверка `~/workspace/bug-hunt/sora-legacy`).
Пуша нет. Координатор прохода: этот отчёт = итоги прохода 2/3.

**Методология:** для каждой фичи — трассировка полного пути
UI(Dart) → proto → control(Go) → engine → файл/состояние. Искал ТОЛЬКО новое
относительно прохода 1 и `[pass2-debt]`: регрессии, «витрины без входа»,
полупроводки, врущие UI-состояния. Тесты: `go build ./...` + `go vet` чисты;
`go test` зелёный по `control`, `engine/...`, `guard`, `session`, `profiles`,
`probe`, `ext`, `service/sync` (детали артефактов — §9).

## Вердикты по фичам (коротко)

| Фича | Вердикт | Примечание |
|---|---|---|
| F0 split-tunnel UX | ✅ работает | program picker из rules_screen доходит до plan routes |
| F1 QR share/scan | ✅ работает | скрытие ссылки по умолчанию, clipboard-фолбэк без камеры |
| F2 benchmark | ✅ работает | стрим RPC завайрен, Dart-экран + история + auto-select её ест; `GetBenchmarks` честно RETIRED (M3) |
| F3 DNS manager | ✅ работает | `CheckDnsLeaks` обе стороны, пресеты → план |
| F4 connections | ✅ работает | ListConnections/CloseConnection из UI |
| F5 network profiles | ⚠️ было сломано → **ИСПРАВЛЕНО (app-side)** | fingerprint никогда не запрашивался; см. §2 |
| F6 subscription overrides | ✅ работает (app-side) / честный NOT WIRED (Go RPC) | локальный стор — источник истины, документирован |
| F7 survivability | ✅ работает | watchdog-баннер, crash-intent, staged с отменой |
| F8 proxy chains | ✅ работает / ProbeChain честный NOT WIRED | capability — живая (installed engines), все 3 рендера чтят Via |
| F9 device sync | ✅ работает по-настоящему | демон, мост 6 kinds, e2e-тесты зелёные; custom servers честно не синкаются |
| F10 extensions | ✅ работает (Dart) / Go-рантайм честно гейтится | background — исполнителя JS нет, бейдж честный; dangerous permissions помечены кодом |
| F11 zapret+VPN | ⚠️ была регрессия → **ИСПРАВЛЕНА** | стратегия-без-стратегии падала только на Connect; см. §1 |
| Обновления (staged+подписи) | ✅ работают / подписи fail-closed | rollout-решения консультируются; key ceremony — блокер владельца |
| Kill switch | ✅ standard работает / strict честно не экспонирован | 3-й «уровень» `KillSwitchChanged` — мёртвое событие, помечено; см. §3 |

## §1. F11 — регрессия от `5695d44f` [detail-fix] ✅ ИСПРАВЛЕНО

**Что было:** коммит `5695d44f` превратил `bypass.DefaultStrategy()` в
современный nfqws/winws-сет (fake, split2, disorder2, multisplit, QUIC).
`applyZapretWithVPN` (`core/control/plan.go`) подставлял его, когда клиент
не присылал `zapret_strategy`. Но nfqws-бэкенд не завайрен:
`bypass.Engine.Apply` для такой стратегии всегда возвращает fail-closed
ошибку. Итог: стратегия-без-стратегии **строила план успешно и падала
только на Connect** — поздняя, непонятная клиенту ошибка. Тест
`TestPlanFromProtoZapretStrategyDefaults` пинил это поведение как норму.

**Фикс (коммит `2a1395e6`):** `applyZapretWithVPN` отказывает на уровне
плана (`CodeFailedPrecondition`, `KeyPlanBypassInvalid`) с точной причиной —
«built-in default needs the nfqws backend, which is not wired up yet».
Мёртвый `defaultZapretStrategy` удалён (вместе с теперь неиспользуемым
импортом `bypass`), тест переписан в
`TestPlanFromProtoZapretWithoutStrategyFails` (ожидает отказ + упоминание
nfqws). Прод-путь не тронут: приложение всегда шлёт свою tpws-стратегию,
все существующие zapret-тесты зелёные.

## §2. F5 — авто-применение профилей было недостижимо ✅ ИСПРАВЛЕНО (app-side)

**Что было (верификация, не регрессия прохода 1 — наследие волны 3, но
явного тикета не было):**
- `Sora.refreshFingerprint()` хардкодил `NetworkFingerprint.unknown()`,
  за ним `TODO(profiles): wire to the GetNetworkFingerprint RPC`.
- Локальный матчер `ProfilesStore.match` на unknown всегда возвращает null.
- Core-side матчер (`session.checkProfile` → `ProfileMatched`) мёртв,
  потому что приложение никогда не вызывает `SaveProfile` (стор ядра пуст).
- На экране профилей нет кнопки «применить сейчас».
- Итог: **профиль можно создать, но он не мог примениться никогда** —
  ни автоматически (autoApply), ни вручную; переключатель «Apply
  automatically» + хинт обещали работающую автоматизацию. Витрина без входа.

**Фикс (коммит `8f63b049`, Dart, вычитка — SDK нет):**
- `refreshFingerprint()` теперь реально вызывает
  `GetNetworkFingerprint` (API 1.10, таймаут 10с, гейт `link.minor >= 10`,
  UNIMPLEMENTED- и error-толерантность по образцу `getObfsCapabilities`);
  пустые строки маппятся в null. Go-сторона реальна
  (`core/profiles/fingerprint.go`: default route, gateway, SSID, ASN-таблица).
- Матчер стал живым: открывается экран профилей / жмётся refresh →
  fingerprint → match → `handleProfileMatched` (auto-apply или ask).
  Без линка/при ошибке — честный unknown, UI говорит «unavailable».
- Комментарии в `profiles.dart`/`sora.dart` переписаны честно: core-стор
  и `List/Save/DeleteProfile` по-прежнему не вызываются (решение владельца:
  один store of truth — см. «Честные NOT WIRED»).

**Попутная находка — вероятная ошибка компиляции Dart (HIGH):**
`sora.dart` импортирует `core_control.pbgrpc.dart` (экспортирует proto-классы
`NetworkProfile`, `NetworkFingerprint`) **и** `profiles.dart` (локальные
одноимённые модели) без префиксов; оба имени используются в `sora.dart`
(поле `networkFingerprint`, `applyProfile(NetworkProfile ...)`). По правилам
Dart это `ambiguous_import` на каждом использовании — приложение, вероятно,
не проходит `flutter analyze`/`build` с момента волны 3 (тулчейна здесь нет,
все раунды — вычитка; dev-машина так и не гоняла analyze). Фикс в том же
коммите: `hide NetworkFingerprint, NetworkProfile` на pbgrpc-импорте
(proto-типы в `sora.dart` по имени не нужны нигде). **Владельцу: прогнать
`flutter analyze` — подтвердить/опровергнуть; если анализатор его не
ловит, значит локальные декларации как-то побеждают, но hide безвреден в
любом случае.**

## §3. Мёртвые события контракта ✅ честно помечены (коммит `351b0d87`)

`KillSwitchChanged` (поле 10) и `BypassStrategyChanged` (поле 6) в
`CoreEvent`: **ноль продюсеров в Go** (session не имеет таких EventKind,
конвертер в `server.go` их не строит) и **ноль потребителей в Dart**
(`_watchSession` их не обрабатывает). UI не врёт — kill switch читается из
`SetKillSwitch`/`GetStatus`, bypass-уведомления идут journal-строками, —
но контракт обещал то, чего нет. По прецеденту M3/GetBenchmarks: сообщения
оставлены (wire-compat), в `.proto` добавлены пометки `NOT WIRED (2026-10-20)`
с указанием, откуда течёт живое состояние. `proto_parity.py`: 0 ошибок.

## Честные NOT WIRED (подтверждены перепроверкой, не чинить без решений владельца)

1. **F5:** core-стор профилей (`SaveProfile`/`List`/`Delete`) — стор пуст,
   core-матчер не стреляет. Теперь частично перекрыто app-side (§2).
   Решение владельца: сшивка vs удаление Go-стора.
2. **F6:** Go override-стор (`SaveSubscriptionOverride` RPC) — не вызывается;
   локальный стор честно документирован как источник истины.
3. **F8:** `ProbeChain` RPC — реализован и протестирован, Dart не вызывает;
   честная пометка в `chain.go` от pass1 intact.
4. **F9:** синк custom servers — ядро не отдаёт credentials
   (`ListCustomServers` даёт только `HasCredentials`); контракт §4
   документирует, UI не обещает.
5. **Расширения:** JS-исполнитель `background`-воркеров отсутствует
   (Scheduler инстанцирован в main по pass1-ext, задач ноль — не театр);
   `net.hooks`/`routing.rules` — RiskDangerous, честно не заэнфорсены и
   запинены тестами; `ui.panel` — настоящий install-time гейт.
6. **Kill switch strict:** реализован и протестирован в `guard`, но
   умышленно внутренний (`modeStrict` не экспортируется) — продуктовое
   решение владельца не принято; `mode.go` документирует честно.
7. **`core/select`, `core/tune`, `core/engine/stealth`** — маркеры NOT WIRED
   от второго круга на месте.

## Что перепроверено и в порядке (без изменений)

- **F2 end-to-end:** `BenchmarkServers` (auth, лимиты 32/5–60с/1–4, done-сэмплы,
  неизвестные id — честный per-server фейл), `probe.NewBenchmarker` завайрен
  в `main.go`; Dart-экран, `bandwidth`-история (TTL 24ч), `compareAutoSelect`
  ест bandwidth. Мелочь: кастомные серверы `resolveBenchmarkServers` не
  находит (ищет только по подпискам) — получат честный «unknown server»
  сэмпл, не молчание. LOW, не чинил (зона shared).
- **F8 честность capability:** `chains` в `About.capabilities` считается
  вживую через `chainEngines(s.measurer)` →
  `BuildCapabilities(kind, version, tags).Supports(FeatureChains)` по
  **установленным** движкам; все три рендера (sing-box `dialer_proxy`, xray
  `dialerProxy`, mihomo `dialer-proxy`) чтят `Via`; `RequiredFeatures`
  гейтит план. `connectChain` + crash-restore (`chain:`-выбор) — end-to-end.
- **F11 прод-путь:** тоггл гейтится `Platform.isLinux && serverlessAvailable`
  (modes.dart); Dart всегда шлёт tpws-стратегию из настроек; Go строит
  синтетический bypass-аутбаунд и ретаргетит `direct`-правила; движок
  fail-closed без tpws. В proxy-режиме Go честно отказывает (needs TUN);
  тоггл при этом виден и в proxy-режиме — UI-мелочь: юзер может включить,
  connect упадёт с понятной ошибкой. LOW, не чинил (дизайн-решение: прятать
  ли тоггл вне TUN-режима).
- **F9 мост — реальный синк:** `SyncDocumentBridge.publish()` (6 kinds:
  subscriptions/app_settings/overrides/profiles/chains/obfs, hash-skip,
  debounce) вызывается перед каждым синком; `applyPulled` применяется к
  `pulled`-метам; конфликты LWW с метой (kind/name/from) в UI; QR round-trip
  тесты; `service/sync` — `go test ./...` зелёный (api, pairing, sync,
  transport). Демон спавнится приложением (`sync_daemon.dart`, per-platform
  резолв бинаря).
- **Обновления:** rollout-политика реально консультируется
  (`applyRolloutPolicy`: withhold/pending/blocked + decision-table тесты);
  подписи fail-closed: Windows — `UpdateError.signatureRequired` до
  minisign-в-Dart (честный текст, не «проверено»); Linux —
  `packaging/linux/sora-update` перепроверяет `SHA256SUMS.minisig` от root,
  но ключ — плейсхолдер → честный `die` до key ceremony; S11b пишет маркер
  после `exitCode == 0` (фикс второго круга intact), health-check 60с.
- **Kill switch:** `SetKillSwitch` → `Session.SetKillSwitch` →
  `guard.Apply` (+ зеркало в `extSched`); `GetStatus` отдаёт применённое
  состояние; self-тесты читают `Guard.Blocked` (фикс B intact); `ModeOff`
  честно ошибается вместо молчания.
- **Расширения:** стор — таб в shell; install проверяет подпись внутри
  `install()`; zip-бомбы — стриминг-капы в обеих реализациях; пин ключа
  автора + перепроверка при rollback; `ui.panel`-гейт зеркалится в Dart;
  `net.fetch` — `TunnelTransport`, fail-closed без туннеля.
- **Legacy:** `go build` + `go vet` чисто (redactor-фикс `1297c0f` intact).
  C#-правки по-прежнему только вычиткой.

## Тесты и артефакты (честно)

- `go build ./...`, `go vet` (control, engine/..., guard, session, probe,
  profiles, ext, cmd) — чисто. `go test -count=1` зелёный: control, engine
  (+bypass, mihomo, singbox, xray, stealth, registry, supervise, tunroute,
  clashapi, interop), guard, session, profiles, probe, ext, service/sync.
- Два несвязанных с фичами артефакта окружения (не регрессии):
  - `TestDetectCensorshipEventsWithoutOffsetsStayUnknown` падает при
    `TMPDIR=$HOME/workspace/.build-tmp` — unix-socket path длиннее 108
    символов (`bind: invalid argument`); с `TMPDIR=/tmp` зелёный. Тот же
    класс артефакта, что фиксировал координатор прохода 1.
  - `TestWaitWhilePausedRePauseBeforeWakeup` (ext) — тайминг-флейк под
    параллельной нагрузкой; standalone и `-count=3` зелёный. Кандидат в
    стабилизацию отдельным тикетом, не прод-баг.
- Предсуществующие `gofmt`-грязные файлы не мои (`chain_plan_test.go`,
  `contract_test.go`, `override.go`, `profiles_rpc_test.go`,
  `subscriptions.go`) — не трогал (чужие WIP).

## Коммиты прохода (`[pass2-swarm]`, CAS-рецепт AGENTS.md, чужие staged не тронуты)

1. `2a1395e6` — F11: отказ на уровне плана без стратегии
   (`core/control/plan.go`, `plan_fields_test.go`).
2. `8f63b049` — F5: проводка `GetNetworkFingerprint` + hide
   ambiguous-import (`app/lib/src/sora.dart`, `app/lib/src/profiles.dart`).
3. `351b0d87` — proto: NOT WIRED-маркеры двух мёртвых событий
   (`proto/sora/core/v1/core_control.proto`).

## Владельцу (решения / dev-машина)

1. **`flutter analyze` + `flutter test` — обязательно до мержа:**
   Dart-правки этого прохода (особенно §2 — подтвердить/опровергнуть
   ambiguous_import) плюс накопленные Dart-изменения кругов 2–3.
2. F5: архитектурное решение — сшить Dart-стор с core RPC
   (`SaveProfile` push → живой фоновый матчер при смене сети) или удалить
   Go-стор; то же для F6 (Go override-стор).
3. Key ceremony (minisign) — по-прежнему главный блокер релиза обновлений
   и каталога расширений; JS-исполнитель background-воркеров; приватный
   ext-listener для TUN; синк custom servers — нужно RPC ядра с credentials.
4. Стабилизировать `TestWaitWhilePausedRePauseBeforeWakeup` под нагрузкой.
5. F11-мелочь: прятать ли тоггл zapret вне TUN-режима (сейчас виден,
   connect честно отказывает).
