# TSPU-FINISH — финальная фаза: дожимание решений

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`, коммиты `[tspu-wire]`, пуша нет.
HEAD: `eb245641464b84720d43941358508b333fda0f61`. Все сборки: `go build ./...`,
`go vet ./...` зелёные; тесты `probe/censor/session/control/engine/bypass/
diagnostics/parser` зелёные (подробности в конце).

## 1. Завайрено (по задачам)

### Задача 1 — T017: planned re-handshake (коммит `02dd0882`)
- `Session.HandshakeAt()` (`core/session/runner.go`): ставится при достижении
  `StateConnected` — возраст handshake как cheap correlatable feature.
- `ManagerConfig.Rehandshake RehandshakePolicy`, per-session воркер в
  `core/session/manager.go`: тик 1 мин, дедлайн из `policy.Deadline` с
  session-local `math/rand/v2` источником; по overdue — `Connect` на тот же
  план, триггер одноразовый (новая сессия получает свой воркер).
- Деферрал по заморозке (`frozenRecently`): скан журнала сессии на `EventCensor`
  с interference-kind за последние 5 минут (T017 §3.5). `KindUnknown`/
  `KindNoInterference` — не interference.
- `main.go`: дефолт `RehandshakePolicy{MaxAge: 45m, Jitter: 10m}`.
- **Честный скоуп**: `KeepaliveInterval` остался NOT WIRED — sora не владеет ни
  одним метрономным keepalive (значения берутся verbatim из пользовательских
  ссылок; молча джиттерить конфиг пользователя = врать о применённом).
- Тесты: `core/session/rehandshake_wire_test.go` (HandshakeAt, деферрал,
  fail-closed disabled policy, superseded target, хук watcher'а).

### Задача 2 — T035: PathQuality + реестр (коммиты `29cdf13`, `fe7f6d2`)
- Осиротевшие `de2b254`/`a8cfda2` восстановлены `git add` (файлы лежали
  untracked в worktree, байт-идентичны — cherry-pick был бы эквивалентен).
- `core/probe/quality.go`: `QualityRegistry` (per (server, transport)
  `PathQuality`, in-memory only, анонимные сэмплы дропаются); `Prober.Quality()`;
  каждый дайл фидится в реестр (`Prober.measure`: успех=RTT, фейл=loss).
- Честный скоуп: реестр **фидится** (prod-writer = Prober), но readout
  CENSORSHIP-METER (спека 35 §3) не построен — meter это UI/UI-контракт, не Go.

### Задача 3 — T009-остаток + T024 (коммит `df89781`)
- Патч `~/.tspu-scratch-t009/t009-validate-catalog.patch` **не существует**
  (директории нет). Валидация `validateXHTTP` уже лежала незакоммиченной в
  worktree — закоммирена честно: XHTTP+Vision=ошибка, whitelist mode, пары
  адрес/порт downloadSettings только на xhttp, xmux-правила, xPaddingBytes,
  ALPN h3 без TLS=ошибка; варнинги xhttp-version-sync, xhttp-xmux-proxy-limit.
  T024 (ECH-честность) лежал в том же файле — коммит назван честно
  «T009-остаток + T024». Новый тест `validate_xhttp_test.go` (22 кейса).

### Задача 4 — T021-остаток
- Патч `21-xray-hy2-brutal.patch` **избыточен**: Xray brutal уже в HEAD
  (`core/engine/xray/render.go:467-471` + тест `TestRenderPassesHysteria2BandwidthToBrutal`).
- Остаток по спеке 21 §4–5: `CalibrateBrutal` (`core/probe/calibrate.go`,
  коммит `fe7f6d2`): down=measured×0.9, up=тариф или down×0.1 с флагом
  estimated, кламп [1,100000], `CalibrationCooldown=7 дней`. **NOT WIRED**
  (маркер в коде): триггер — клиентский шов (post-connect hook + запись в
  credential doc); фоновый самозамер запрещён спекой.

### Задача 5 — унификация детекторов заморозки (коммиты `fe7f6d2`, `09865607`)
- Единый источник правды: `probe.FreezeDetector` (дифференциальная сигнатура
  из T007). Дублирующий `censor.FreezeDetector` (слабая сигнатура «3 pre-byte
  фейла», противоречащий rotation-лист) **удалён**; вместо него `censor.FreezePolicy` —
  только политика действий (backoff ≥120с, лестница fp→SNI→failover, RetryAfter,
  `NoteRotation`), читающая список из `probe.FreezeFingerprintRotation()`.
- Rotation-лист унифицирован: `["firefox","edge","qq","android"]` (chrome/safari/ios
  исключены по полевым данным T007). SNI-нормализация в `probe.FreezeDetector`.
- **Проводка распознавателя** (коммит `02dd088`): `main.go` создаёт
  `freezeDet := &probe.FreezeDetector{}` и `prober.SetFreezeDetector(freezeDet)`;
  `OnFreeze` пишет `EventCensor` в журнал текущей сессии и вызывает
  `ExpediteForCensorship`. Политика (`FreezePolicy`) завайрена как распознаватель;
  её *действия* (ротация на живой сессии) — NOT WIRED, решение владельца (SW4 tier 2),
  маркер в коде.

### Задача 6 — BanTracker в дайлеры (коммит `fe7f6d2`)
- `probe.DialQUIC(ctx, raddr, tracker)`: ротация source port при бане (420с),
  экспоненциальный backoff 100/200/400мс, макс 4 попытки, banned-сокет
  закрывается без единого пакета; `ProbeQUICWithTracker` (+ `NoteBlocked` на
  VerdictBlocked); `ProbeQUIC` делегирует с nil-трекером.
- Честный скоуп: QUIC внутри движков (hy2/TUIC) — внешние бинарники, врезка
  невозможна → NOT WIRED с причиной в доке `DialQUIC` и спеке 31.

### Задача 7 — ExpediteUpdate подписок, T042 (коммит `02dd088`)
- `ManagerConfig.OnCensorshipVerdict func(censor.Verdict, string)` +
  `Manager.SetCensorshipHook(fn)`; watcher в `core/session/censor.go`
  (`publish` — единственная точка) вызывает хук после journal append.
- `subscriptionBook.subscriptionsOf(serverID)` (обратный lookup по
  `b.lists` — **не** по `rec.Servers`, там refs секретного стора) +
  `Server.ExpediteForCensorship(v, serverID)` (`core/control/censor.go`):
  триггер только на interference-kinds (RSTInjection, HandshakeTimeout,
  DNSPoisoning, SNIBlocking, IPBlocking, DataStall); NoInterference/Unknown —
  игнор; cooldown 15 мин наследует от `ExpediteUpdate`.
- `main.go`: `manager.SetCensorshipHook` → `plane.ExpediteForCensorship`.
- Тесты: `TestExpediteForCensorship` (cooldown, фильтры kind'ов, reverse lookup).

### Задача 8 — сверка: прод-вызывающий у каждого модуля
- Промаркированы NOT WIRED в коде (коммит `f6c431a`), каждый с причиной:
  `ProbeQUIC` (T008), `ProbeTrojanFallback` (T022), `RunSeries` (T041),
  `GenerateShadowsocks2022PSK` (T020), `FakeTTL` (T015), `HandshakeLimiter`
  (T007 budget), `QueueAllocator` (T005), `DetectDNSIntercept` (T010),
  `ClassifyDegradation` (T018), `MidSNISplit` (T031), `CalibrateBrutal` (T021).
- Ранее промаркированы роем: `WhitelistDetector` (646eb41), tune/select/stealth
  (42f4ef0).
- Завайрены и имеют прод-вызывающих (проверено grep'ом): `IsStaleParrot` →
  `ja4FreshnessNotices` (control), `RealityMux` → рендеры (xray/singbox/mihomo),
  `ValidateReality/validateXHTTP/validateECH/matchAWGPublicExample` →
  `Validate()` → `NewSession`, `RealityWarnings` → UI/RPC, `dataStallRule` →
  `Detector.Detect` → watcher+RPC, `wgobfusc.Generate` → `validate.go`,
  `leak.Run` → control RPC, `CheckDest` → `censor/snipool.go`,
  `DetectCensorship` RPC → `censor.Detector`.

## 2. Потери, найденные и восстановленные этой фазой
- `147af4c` ([i18n], sweep-инцидент) снёс `core/probe/trojan.go`+`trojan_test.go`
  (T022) и `core/parser/unsupported_schemes_test.go` (T023) — «ремонт» 9c6c011
  их не вернул. Восстановлены из `b63c41b`/`b225dcc` (коммит `73e76b9`),
  build+тесты зелёные.
- Три файла TSPU-источников выпали из дерева HEAD при stale-tree коммитах
  других агентов: `core/diagnostics/throttle.go` (T018), 
...[truncated 2359 chars]
`core/engine/bypass/fakettl.go` (T015), `core/engine/bypass/split.go` (T031).
  Восстановлены целиком (включая мои маркеры) коммитом `f6c431a`.
- Тесты тех же источников тоже выпадали из дерева: `throttle_test.go`,
  `fakettl_test.go`, `split_test.go` — восстановлены коммитом `eb24564`.
- Не-TSPU потери дерева, оставлены владельцам (существуют только как
  untracked worktree-файлы): `core/diagnostics/deadsession.go` (T029, см. §5)
  + `deadsession_test.go`, `core/cmd/sora-core/version_test.go`,
  `core/control/plan_fields_test.go`, `core/ext/ratings.go` +
  `ratings_test.go` + `catalog_store_test.go`,
  `core/diagnostics/ja4_test.go` (никогда не был в истории).

## 3. Осталось и почему (все пункты честно промаркированы в коде)
- Триггеры UI/RPC для протестированных примитивов: `ProbeQUIC`,
  `ProbeTrojanFallback`, `RunSeries`, `DetectDNSIntercept`,
  `GenerateShadowsocks2022PSK`, `CalibrateBrutal` — спецификации уже
  написаны роем TSPU-SOLUTIONS; клиентская часть — следующая волна.
- `HandshakeLimiter`, `FakeTTL`, `MidSNISplit`, `QueueAllocator` —
  врезка в probe-дайлы / desync-аргбилдер / nfqws-executor; executor —
  активная работа sibling'а по T005.
- Действия `FreezePolicy` на живой сессии (ротация fp/SNI) — решение
  владельца (SW4 tier 2); распознаватель уже работает и фидится.
- Readout CENSORSHIP-METER из `QualityRegistry` (T035/T018) — UI-контракт;
  классификатор `ClassifyDegradation` готов и чист.
- QUIC BanTracker внутри движков (hy2/TUIC) — принципиально невозможно,
  движки внешние; тема закрыта честным маркером.

## 4. Коммиты фазы
```
9a20ba7 [tspu-wire] T017: restore re-handshake policy (de2b254)
29cdf13 [tspu-wire] T035: restore PathQuality sampling core (a8cfda2)
df89781 [tspu-wire] T009-остаток + T024: XHTTP guards + ECH honesty
fe7f6d2 [tspu-wire] probe: unified rotation list, BanTracker dials, T035 registry, T021 calibration
0986560 [tspu-wire] freeze detectors unified (probe = single recognizer, censor.FreezePolicy)
02dd088 [tspu-wire] T017 wired (worker + freeze deferral), T042 wired, freeze recognizer on control prober
73e76b9 [tspu-wire] restore T022 trojan self-test + T023 openvpn-rejection test
f6c431a [tspu-wire] audit: honest NOT WIRED markers (10 files, incl. 3 restored sources)
eb24564 [tspu-wire] restore lost test files for restored TSPU sources
```

## 5. Уточнение по T029 (для финального аудита)
- Детектор T029 — `DetectDeadSession` (`core/diagnostics/deadsession.go`,
  payload-health, коммит `5d616c9`, снесён `147af4c`) — существует, но только
  как **незакоммиченный worktree-файл** (восстановлен sibling'ом), без
  прод-вызывающих. Промаркирован NOT WIRED (как и все tested-but-untriggered).
  Статус «ВНЕДРЕНО (детектор)» в TSPU-SOLUTIONS.md формально верен как
  «код написан и протестирован», но в прод не завайрен и в HEAD не лежит —
  задача финального аудита: либо закоммитить+завайрить, либо
  скорректировать статус.

## Примечания для родительского агента
1. **Общий индекс отравлен**: sibling застейджил удаления (`D `) ровно всех
   15 файлов моей фазы (validate_xhttp/ech tests, pathquality, quality,
   calibrate, trojan, rehandshake + wire tests, unsupported_schemes_test).
   Мои коммиты в HEAD и worktree не задеты, но любой чужой bare `git commit`
   приземлит эти удаления. Рекомендую `git restore --staged` по этим путям
   до следующего чужого коммита. Я индекс не трогал.
2. Предсуществующие фейлы окружения (не регрессии): unix-socket путь
   108 символов (TMPDIR длинный) и `TestTunAndFakeIPAvoidLANAndEachOther`
   (песочница). Один прогон `go test ./probe/` под параллельной нагрузкой
   дал FAIL без воспроизведения (3 чистых перепрогона, включая `-count=1`).
