# CENSOR-SURV-REVIEW — независимое ревью подотдела CENSOR-SURV

**Дата:** 2026-10-20. **Ветка:** `bugfix/audit-2026-10-19`, строго локально, пуша нет, код не правился.
**Объект:** коммиты `44859a82`, `d7e831ee`, `2634e3e5`, `e6bfc22f`, `52b9cd0d`, `7b6584a5`, `8cdd9fd2`; отчёт автора `CENSOR-SURV.md` сверен с кодом.
**Метод:** чтение в worktree на `8cdd9fd2` (`/tmp`, удалён после), собственные тестовые векторы (одноразовые тесты в том же worktree), прогоны `go test`/`go vet` (Go из `~/workspace/go/bin`, TMPDIR/GOCACHE по дисциплине). Ни одного коммита, основная ветка не тронута.

## Итоговая таблица вердиктов

| # | Пункт | Вердикт |
|---|---|---|
| 1 | REALITY-гигиена | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 2 | Вайринг остатков (лимитер, CLI-триггеры, удаление throttle) | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 3 | Цепочка реакции событие→политика→действие | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 4 | Адаптивность (BindNetwork, персистентность BanTracker, Warn) | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 5 | Маскировка фетча (UA-пул, джиттер) | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |
| 6 | Мелочи (константы, границы, MaskedName) | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** |

**Общий вердикт: ПРИНЯТЬ С ЗАМЕЧАНИЯМИ.** Блокирующих дефектов в самих 7 коммитах не найдено; есть 2 замечания уровня Medium в объекте ревью, 1 Medium системное (состояние дерева на `8cdd9fd2`, атрибуция — соседи, но оно опровергает §9 отчёта автора) и ряд Low.

---

## Системное замечание (вне 7 коммитов, но прямо бьёт по §9 отчёта автора)

**[Medium, дерево/честность отчётности] Зафиксированное дерево на `8cdd9fd2` не компилируется в пакете `engine` (и зависимых `engine/xray|singbox|mihomo`, `control`, `cmd/sora-core`).**
Доказательство: чистый worktree на `8cdd9fd2` → `go build ./engine/` — `undefined: FeatureHy2Obfs, MaxHy2BandwidthMbps, MinHy2HopIntervalSeconds, SupportsShadowsocksMethod, SupportsSSPlugin, ValidHy2Obfs, ValidTUICCongestion, ValidTUICUDPRelayMode, HopPortRanges, Min/MaxTUICHeartbeatSeconds, FeatureRealityKeyShare, AmneziaWG.IsZero, SSPluginByName, SingBoxHopPorts, Outbound.EffectiveTUIC*` и др. Ссылки внесены соседними коммитами (начиная с `2bf2df24`, родителя `44859a82`), определения существуют только в незакоммиченном WIP рабочего дерева. Чистый worktree на текущем HEAD (`7b459128`) — та же картина. Утверждение §9 «финальные прогоны — на чистом дереве» для `engine`/`control`/`cmd` из закоммиченного дерева **не воспроизводится**.
Что сделано ревьюером: в одноразовом worktree недостающие символы соседей были закрыты стабами (только для прогона тестов, удалены вместе с worktree). Итоги ниже помечены, где прогон был со стабами.

## 1. REALITY-гигиена — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

Проверено чтением `core/engine/reality.go` (на `8cdd9fd2`) и собственными векторами (прогон со стабами соседей, см. выше): авторский `TestRealityHygieneWarnings` (18 кейсов) и `TestValidateRealityDestShape` — зелёны; легитимные CDN-dest (`cdn.jsdelivr.net`, `www.microsoft.com`) ложно не срабатывают (только `reality-without-vision` фикстуры).

- **[Medium] Блок в `ValidateReality` асимметричен предупреждениям: проверяется только `TLS.ServerName`, а dest-fallback на `Server` — нет.** `reality.go:280-286` (блок) против `realityDest()` (`ServerName`, иначе `Server`) в предупреждениях и `core/engine/singbox/render.go:374` — `server_name = orDefault(o.TLS.ServerName, o.Server)`: при пустом ServerName именно `Server` уходит в SNI на проводе (sing-box). Доказательство (свой вектор): `Server="my_site.example.com"`, `ServerName=""` → `RealityWarnings()=[…, reality-dest-malformed]`, а `ValidateReality()=nil`. Битый dest через поле сервера проходит «блок» импорта на sing-box-пути.
- **[Low] `reality-sni-is-server` — только точное равенство; корреляция по региструемому домену не ловится.** Доказано векторами (все — без предупреждения): `Server=vpn.example.com`/`SNI=www.example.com`; `Server=example.com`/`SNI=cdn.example.com`; обратная пара. SNI и сервер на одной инфраструктуре/домене ТСПУ коррелирует, предупреждение молчит. (Проводная сторона частично закрыта `CheckDestForServer` через резолв — но это не статический импорт-чек.)
- **[Low] Пропуски `isPublicDestName`:** в `privateDestSuffixes` нет `home.arpa` (RFC 8375), `.onion` (RFC 7686), `.localdomain`. Доказано: `router.home.arpa`, `abcdef.onion`, `host.localdomain` — предупреждений нет.
- **[Low] Квази-IP `123.456.78`** (не IP по `ParseAddr`, не валидное публичное имя) — молчание и предупреждений, и валидации.
- **[Low] Жёсткий блок на U-label IDN.** Вектор `bücher.example.de` → `reality-dest-malformed` + ошибка `ValidateReality` (импорт режется, не предупреждение). Punycode-форма (`xn--…`) проходит. Если провайдеры отдают dest U-label'ом — легитимный конфиг не импортируется.
- **[Low] `reality-shortid-low-entropy` уже своего имени:** ловится только «все байты одинаковы». Доказано: `abcdabcdabcdabcd`, `deadbeefdeadbeef` (классический плейсхолдер) — молчание. Реализация честно соответствует док-комментарию, но UI-подпись «low-entropy» обещает больше.
- Подтверждено без замечаний: коды не пересекаются (`switch` short→low-entropy взаимоисключающ, `else if` malformed→not-public; `"00"` даёт только `short` — и авторским тестом, и чтением); одно-лейбл публичных dest в природе нет — флаг на одно-лейбл корректен; блок не ломает валидные конфиги: таргетные тесты `engine -run Reality` (со стабами), `parser -run 'TestParse|TestImport|Reality'`, `control -run 'Subscription|…'` — зелёны. Полный `go test ./engine/` в этом дереве невозможен как факт (см. системное замечание); со стабами падают 6 тестов — все в соседских зонах Hy2/TUIC/KeyShare (`TestValidateRejectsBadHysteria2Tuning`, `TestCensorP1KeyShareGate`), ни одного в REALITY-зоне; атрибуция — стабы/отсутствующие определения соседей, не объект ревью.

## 2. Вайринг остатков — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- Лимитер: единственный **код** — `core/probe/budget.go:39` (`type HandshakeLimiter struct`); `core/censor/budget.go:24` — `type HandshakeLimiter = probe.HandshakeLimiter` (алиас, не копия). Потребители реальны: `probe/reality.go` `dialLimited` аквайрит слот на каждый из двух хендшейков `CheckDest`; `censor/probe.go:128-137` аквайрит **до** ClientHello, отказ → событие `StageTLS/WhatError "handshake budget: …"`, коннект закрывается, 4-го ClientHello нет. Тесты `TestCheckDestRespectsHandshakeBudget` (dial не вызывается при насыщении), `TestProbeHandshakeBudgetRefusal` — зелёны в полном прогоне `probe`/`censor`.
- **[Medium] Два разных инстанса бюджета, а не один общий.** `CheckDest` ходит в пакетный `destHandshakeLimiter` (`probe/reality.go`), `censor.Prober` — в `censor.DefaultHandshakeBudget`. Оба дефолта 3/SNI, но это независимые семафоры: параллельный dest-check + пробы по одному SNI дадут до 6 одновременных хендшейков — выше порога фриза, ради которого бюджет существует. «Единственный источник» верен про реализацию, не про инстанс.
- **[Medium] `-quic-probe` теряет результат, если data-dir не существует.** `core/cmd/sora-core/netcheck.go`: проба выполняется, затем `SaveBanTracker` падает на `WriteFile` в несуществующий каталог, `runQUICProbe` возвращает ошибку без единой строки вердикта (CLI печатает только ошибку, exit≠0). Доказано своим тестом: `runQUICProbe(ctx, <tmp>/does-not-exist, …)` → `lines=[]`, `err=probe: write ban tracker: … no such file or directory`. Свежий операторский запуск (data-dir ещё не создан инсталляцией) — ровно этот случай. Лечится `MkdirAll` в `runQUICProbe`/`SaveBanTracker`.
- CLI-триггеры настоящие: `cli.go` парсит `-quic-probe`/`-dns-check` и диспатчит **до** подъёма сервиса: `runQUICProbe → probe.ProbeQUICWithTracker`, `runDNSInterceptCheck → diagnostics.DetectDNSIntercept` (не заглушки). Тесты `netcheck_test.go` ×4 — зелёны (прогон со стабами соседей для `cmd`).
- Удаление throttle — **полное и чистое**: на `8cdd9fd2` нет файла, нет ссылок на `ClassifyDegradation`/`DegradationVerdict`/`ThroughputSample` во всём дереве (git grep); оставшиеся слова «throttle» — другие концепты (QUIC-throttle класс desync, комментарии freeze). Восстановление из `7b6584a5^` возможно: родитель содержит `core/diagnostics/throttle.go` целиком, удаление — один коммит. Обоснование удаления (нет источника парных goodput-рядов) по коду подтверждается: прод-потребителей у классификатора не было.
- Честно отмечено автором и подтверждаю: endpoint-`Prober` в `probe.go` бюджет не аквайрит (док в `probe/budget.go` называет это ожидающим швом, не сделанной работой).

## 3. Цепочка реакции — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- `core/censor/reaction_chain_test.go` идёт по **настоящим** компонентам, не по мокам самих себя: реальные `probe.FreezeDetector` (сэмплы → `Frozen`), `FreezePolicy.Assess`, `SNIPool`. Прогон пакета `censor` — зелёный.
- Горячий backoff = «ждать» — доказано кодом и тестом: `siberian.go` `Assess` возвращает оценку **до** присваивания `SuggestedFingerprint`, пока `now < backoffEnd`; тест звена 2 требует `SuggestedFingerprint==""` и `RetryAfter≈+120с`. Сжигания отпечатка при свежем backoff нет.
- Дальше по тесту: после +3 мин — `SuggestedFingerprint="firefox"` (голова единого списка `probe.FreezeFingerprintRotation`, `siberianRotation` — алиас на него, второго списка нет) → `NoteRotation` → `BurnAndRotate` даёт следующий dest и держит burn → при продолжении столлов `RotateSNI`, после двух ротаций `Failover`, исчерпанный пул = `""`.
- **[Low] Замечание о границах доказательства:** звенья «политика → действие» тест дёргает руками (`pool.BurnAndRotate`, `policy.NoteRotation` вызывает сам тест). Прод-автоматика сегодня заканчивается на `OnFreeze` → журнал + `ExpediteForCensorship`; драйвера `Assess→BurnAndRotate` на живой сессии нет — автор это честно эскалирует (Э1/Э2), противоречия отчёту нет. Тест доказывает собираемость цепочки, не её прод-замкнутость — заголовок §5 отчёта это не превышает («проходит всю цепочку по звеньям»), но читать его как «реакция автоматическая» нельзя.

## 4. Адаптивность — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ (отдельный вердикт)

- `BindNetwork` у всех четырёх типов (`probe/freeze.go:276`, `probe/quic.go:317` BanTracker, `censor/snipool.go:47`, `censor/siberian.go:143`): семантика едина и тестами покрыта (пакеты `probe`/`censor` зелёны): пустой фингерпринт не инвалидирует, первый бинд только фиксирует эпоху, смена сбрасывает **только эпохальное** состояние. Данные профилей не теряются — доказано `TestSNIPoolNetworkChangeUnburns`: кандидаты и их порядок (`Snapshot`) переживают смену сети, сгорают только burn-метки (+сброс индекса ротации — эпохальное, приемлемо); у политики падают только backoff-треки, у детектора — сэмплы/кулдауны.
- BanTracker-персистентность: рестарт внутри окна бана сохраняет бан — `TestBanTrackerPersistenceAcrossRestart` зелёный (save → новый трекер из файла → оба бана активны; файл `0600`, запись атомарна tmp+rename, истёкшие режутся и на save, и на load). Ровно-420с граница — п.6.
- Битый файл = громко, не тишина и не паника: `LoadBanTracker` возвращает `(nil, err)`; `netcheck.go` печатает `ban tracker state reset: <причина>`, продолжает с пустого и переписывает файл валидным — `TestRunQUICProbeCorruptTrackerIsHonestReset` зелёный. Оговорка: «громкое событие» здесь — строка stdout операторского CLI, не Warn в журнал; для операторского режима это адекватная поверхность, для in-app пути (которого нет, Э3) — нечего проверять.
- «Реакция недоступна» пишется Warn — подтверждено чтением `core/cmd/sora-core/main.go` `OnFreeze`: нет живой сессии → `Warn "censorship reaction unavailable: freeze detected with no live session…"` с `probe.MaskedName(v.SNI)`; нет control plane → второй Warn про не-expedited refresh. Замечание: вторая ветка практически недостижима после завершения `New()` (plane строится до `Serve`, а детектор питается через plane) — безвредный мёртвый guard, не дефект.
- **[Low] Прод-вайринг `BindNetwork` есть только у FreezeDetector** (`main.go` стартовый бинд + `watchCensorshipNetwork`, поллинг 10 с, подтверждённая смена пишется в журнал сессии — чтением подтверждено). `BanTracker`/`SNIPool`/`FreezePolicy` биндятся только в тестах: у пула и политики прод-владельца нет (Э1/Э2 автора), трекер в CLI живёт один запуск. Формулировка §3 отчёта («смена сети инвалидирует состояние») прод-истинна только для распознавателя — в отчёте это не оговорено явно, хотя эскалации Э1/Э2 картину в целом не скрывают.
- **[Info] Косметика:** `Restore()` считает «восстановленными» и записи, которые уже были в трекере с более поздним expiry (завышение счётчика в CLI-строке); `SaveBanTracker` пишет tmp через `WriteFile(0600)` — предсуществующий tmp с более широкими правами прав не унаследует уже́м (WriteFile режим существующего файла не меняет) — угол пренебрежимый.

## 5. Маскировка фетча — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- UA-пул — данные: `var DefaultUserAgents` (`core/subscription/subscription.go:53`, 4 обычных браузерных агента, экспортируемая переменная, не константы в коде ветвлений). Самоназывающегося UA в **коде** не осталось: git grep по дереву `8cdd9fd2` — `sora-core/1` встречается только в docs/reports (ниже), в коде — ноль.
- Выбор детерминирован по хосту: `userAgentForHost` — FNV-1a по нормализованному (lower/trim) хосту; FNV в stdlib без сида — стабильность между запусками и процессами следует из кода; тест `TestUserAgentForHostPool` (стабильность ×2 вызовов + регистронезависимость + разброс по 8 хостам) зелёный в пакете `subscription`.
- Override побеждает пул: `Fetch` берёт пул-агент только при `agent==""` после `UserAgentFor(opts.UserAgent)`; агент выбирается один раз из primary-ссылки (`target.Hostname()`) и едет на fallback и все редиректы (`f.fetch` получает готовый `agent`) — чтением и тестами пакета подтверждено.
- Джиттер: `core/control/subscriptions.go:612` `fetchJitter` — чистая функция ID (SHA-256), диапазон `[0, min(30мин, interval/8))`, не отрицателен; применяется только в success-ветке `nextUpdate`; фейлы идут по backoff без джиттера; `expeditedDue` перекрывает расписание — expedite джиттером не задерживается. Таргетные тесты `control` — зелёны (со стабами соседей).
- **[Low] Документация врёт после изменения:** `docs/providers.md:29` на `8cdd9fd2` по-прежнему учит провайдеров: «Подписку Sora запрашивает с заголовком `User-Agent: sora-core/1 (+https://github.com/levvs-one/sora)`». Панель, настроенная по доке под этот UA, формата по нему не получит — клиент теперь шлёт пул-агенты. Утверждение автора «самоназывающегося UA не осталось поиском по репо» для доков неверно.
- **[Info]** Хост с trailing dot (`example.com.`) хэшируется иначе, чем без точки, — тот же провайдер в двух записях URL может получить два разных UA. Пренебрежимо.

## 6. Мелочи — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ (отдельный вердикт)

Константы — выборочная сверка 4/4 с кодом; все четыре «круглые, но с письменным обоснованием на месте»:

| Константа | Код | Обоснование в коде | Тип основания |
|---|---|---|---|
| Freeze cooldown 15 мин | `probe/freeze.go` `freezeCooldownDefault = 15 * time.Minute` | ~7 циклов freeze/backoff, половина TTL сэмплов (30 мин); честно названа policy bound, «not a measurement» | суждение, не замер |
| QUIC probe timeout 3 с | `probe/quic.go` `quicProbeTimeout = 3 * time.Second` | VN = один UDP round trip; тишина дольше = сам дроп-сигнал | суждение от протокола |
| Dest-check timeout 10 с | `probe/reality.go` `destDialTimeout = 10 * time.Second` | 2 RTT реального сайта + холодный резолвер; медленнее = улика против dest | суждение |
| Бан 420 с | `probe/quic.go` `residualBanTTL = 420 * time.Second` | FOCI 2026, замер по ТСПУ, источник назван в шапке файла | **замер** |

Вывод: «круглых чисел без обоснования не осталось» — верно буквально; но только 420 с — данные, остальные три — документированные суждения (в коде это не маскируется под замеры — претензий к честности нет).

Границы — все тестами, прогоны `probe`/`censor` зелёны: бан жив на TTL−1с и **мёртв ровно на 420 с** (`TestBanTrackerExpiryBoundary`, полуинтервал `[start, start+420s)`); пул 0 (везде `""`, ничего не выдумывает) / 1 (ротация возвращает себя, burn → исчерпан) / 300 (полный цикл без повторов) + детерминизм двумя полными циклами байт-в-байт; `concurrency == 3` — не параллель (столлы на ровно-3 не дают фриза при любом числе), 1 stalled parallel — нет клейма, 2 — клеймо, без sequential success клейма нет; лимитер дефолт: 3 аквайра ок, 4-й таймаутится.

MaskedName — применён там, где автор заявил: `FreezeVerdict.Mitigation().Why` (`probe/freeze.go:226`), журнал и оба Warn в `main.go` OnFreeze. Но:

- **[Low] `MaskedName` паникует на dot-именах.** Доказано своим тестом: `MaskedName(".")`, `(".com")`, `("..")`, `(".a")` → `panic: index out of range` (`labels[0][0]` по пустому первому лейблу, `probe/freeze.go` реализация после :137). Прод-достижимость низкая (детектор нормализует и отбрасывает такие SNI до `Mitigation`), но экспортированный «безопасный для логов» хелпер обязан не падать именно на мусорных именах — это его входной домен.
- **[Low] Первый лейбл — байт, не руна:** `MaskedName("éxample.com") = "Ã***.com"` (mojibake в логе; доказано тем же тестом).
- **[Low] Не все события зоны маскированы.** (а) Отказ бюджета, внесённый именно `d7e831ee`: `errHandshakeBudgetTimeout.Error()` = `"handshake budget: no slot for " + <сырой SNI>` (`probe/budget.go:144`), и `censor/probe.go:136` кладёт это сырьё в `Event.Detail` попытки. (б) Предсуществующее: `censor/probe.go:103` — DNS-событие `WhatResolved` с сырым IP (`ips[0].IP.String()`). (в) `DestReport.Issues` несут сырые хост/IP (`probe/reality.go:238,269`) — это операторская диагностика по явно запрошенной цели (как CLI-цель у автора), но формулировка §7 «в логах/журнале/диагностике имена — только маскированно» шире факта. Справедливости ради: `Evidence` фриза, журнал сессии и Warn-пути — чисты.

---

## Что проверено прогонами (сводка доказательств)

- `go test ./probe/ ./censor/ ./subscription/ ./diagnostics/ -count=1` на чистом дереве `8cdd9fd2` — **все зелёны** (probe 16.9 с).
- Со стабами соседских символов (одноразовый worktree): `engine -run 'Reality|ValidateRealityDestShape'` + свои векторы п.1 — зелёны, векторы выше — из этого прогона; `cmd/sora-core -run 'TestRunQUICProbe|TestQUICTarget'` — 4/4 зелёны; `control -run 'Subscription|Fetch|NextUpdate|Expedite|Jitter'` — зелёны; `go build ./...` — собирается; `go vet` по probe/censor/diagnostics/subscription/cmd — чист.
- Свой тест на `-quic-probe` с несуществующим data-dir — воспроизводит Medium из п.2.
- Свой тест на `MaskedName` — воспроизводит паники и mojibake из п.6.

## Непроверенное (честно)

- Живой QUIC/DNS по сети: песочница режет UDP-ответы (`sendto: operation not permitted`) — проводная логика пробы подтверждена только инжектируемыми тестами пакетов, не живым трафиком. Согласуется с оговоркой автора §9(2).
- Полные suites `engine`/`control`/`cmd` в закоммиченном дереве: невозможны без чужих незакоммиченных определений (системное замечание); прогоны выше — таргетные, со стабами, и падения вне зоны ревью помечены как стабовые/чужие.
- Dart-сторона предупреждений REALITY (рендер кодов в UI) — вне зоны и вне этих коммитов.
- Поведение `ValidateReality`-блока на реальных провайдерских подписках (доля U-label/нестандартных dest в поле) — данных нет; риск п.1-Low (IDN) оценён по коду, не по полю.
