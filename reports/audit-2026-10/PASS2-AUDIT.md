# PASS2-AUDIT — финальный аудит прохода 2/3 ветки `bugfix/audit-2026-10-19`

Дата: 2026-10-20. Аудитор: финальный аудит прохода 2 (одиночный, без под-агентов).
Репозитории: `~/workspace/bug-hunt/sora` и `~/workspace/bug-hunt/sora-legacy`. Пуша нет.
База: sora `d95b589e` (начало аудита) → закрыт на **`8f6bfb98`** (3 коммита
`[pass2-audit]` — только аудита); legacy `e39fa15` без изменений.
Прочитано перед началом: `~/AGENTS.md`, `FINAL-AUDIT.md`, `PASS1-AUDIT.md`,
`PASS1-SUMMARY.md`, `PASS2-ANALYSIS.md`, `PASS2-DEBT.md`, `PASS2-SWARM.md`,
`PASS2-DETAIL-FIXES.md`, `PASS2-EXTENSIONS.md`, `PASS2-TSPU-ANALYSIS.md`,
`PASS2-TSPU-SOLUTIONS.md`, `PASS2-DEEP-RESEARCH.md`, `WEB-RESEARCH-4.md`.

Метод (урок прохода 1): ни одно закрытие не принимается по отчёту отдела —
только по коду, прямыми прогонами и усиленными векторами. Для каждого
проход-2 закрытия: (а) сверка коммита с HEAD по `git show`, (б) прямой
`go test` соответствующих пакетов (TMPDIR=/tmp), (в) adversarial-вектор
или кросс-верификация там, где закрытие логики это требует.

## Часть A. Перепроверка закрытий прохода 2

### [pass2-debt] — 13 коммитов (`e60f9854..999d58a0`, ровно 13)

Вердикт: **подтверждено** (без фальшивых).
- Прямой прогон на чистом tip `999d58a0` (TMPDIR=/tmp, все три Go-модуля):
  `go build ./...` + `go vet ./...` чисто; `go test -count=1 ./...`
  зелёный по всем пакетам core, `service/sync`, `tools/sora-ext` —
  **ноль падений**, включая 5 тестов, которые на старте долга были красны
  (поимённо из PASS2-DEBT: `TestShadowsocksPluginSurvivesTheVault`,
  `TestRuleSetDownloadsUseHTTPClient`, `TestRuleSetDownloadsFollowProxyFinal`,
  `TestRenderMultiplexDefaultsToReality`, `TestRenderDNSH3UsesTypeH3` —
  перепрогонены отдельно, все PASS).
- Усиленный вектор на исправление кода (а не теста): тест 1 был багом
  `credentialDocument` (не доносил `ss_plugin`/`ss_plugin_opts` до движка) —
  сверен по диффу `0977ab03`: фикс в коде, не подгонка ожиданий.
- Предупреждение из PASS2-DEBT: «чужой WIP в `core/engine/plan.go`
  (удалённое поле `Outbound.OriginalLink`) ломает `go build ./...`» —
  на момент аудита mid-edit уже приземлён (сейчас `3531723a` удалил
  `OriginalLink` чисто, `validate.go` вычищен, сборка зелёная).

### [pass2-tspu] — 4 коммита

Вердикт: **подтверждено все 4**.

1. **`d7a4b0aa` — проводка `RunSeries`.** Реально вызывается из прод-пути:
   флаг `-series-probe` зарегистрирован в `core/cmd/sora-core/cli.go:83`
   и завайрен в run-flow (`cli.go:119-129` → `runSeriesProbe` →
   `Prober.ProbeSeries`); `ProbeSeries` (`serial.go:211`) делегирует в
   `RunSeries` с тем же `p.dial` (address racing, TLS-конфиг, freeze-наблюдение),
   что и одиночная `Probe` — утверждение отчёта о «том же измерительном
   пути» сверено построчно. Правило вердикта (`Liveness()`,
   `SeriesConfirmationWindow = 15 мин`) покрыто 8-кейсовым
   `TestSeriesLivenessVerdictRule` — PASS. Честный остаток (in-app триггер
   ждёт proto-поля) помечен в коде; «фальшивости» нет.
2. **`f044075c` — `DnsSpoofNXDomainSplit`.** Вектор НСДИ реально различается:
   раньше NXDOMAIN от НСДИ при ответивших остальных читался как `ok`
   (счётчик nxdomain игнорировался при `answered > 0`); теперь ветка
   `len(nxOnly) > 0 && len(pools) > 0` в `classifySpoof` стоит после
   bogus и перед inconsistent — верно по силе сигнала. Флап поглощён
   по построению: в `nxOnly` попадает резолвер, ни разу не давший адрес
   за все раунды (Detect) / включая prior-round (Compare) — усиленные
   векторы `TestDetectDnsSpoofFlakyNXDomainAbsorbed` и
   `TestDetectDnsSpoofNXDomainSplitNSDI` + `TestCompareDnsSpoofNXDomainSplit`
   — все PASS прямым прогоном. Флаг в `CheckDnsLeaks` (`dnsleak.go:246`)
   включает split в leak-вердикты — утверждение отчёта верно.
3. **`501a50c3` — T048.** `deadmode.go:5-9`: эпизод датирован
   (Feb–May 2026, «ended in May 2026»), dead-mode сформулирован как
   readiness, запрет на current-подачу зафиксирован в комментарии. Grep
   по `core/ app/lib docs/` на «76-day»/«current shutdown» —
   других носителей формулировки нет. Подтверждено.
4. **`1b429247` — T054 FAQ.** Вопрос про RU-хостинг на месте в
   `docs/faq.md`, формулировки корректны (ЦМУ ССОП/ПП-1667/ФЗ-210/Антифрод 3.0).
   Спека-33/34 в `tspu-solutions/34-infra-legal.md` — вне git, как и заявлено.
   Подтверждено.

### [pass2-swarm] — 3 коммита

Вердикт: **подтверждено все 3** (включая усиленную проверку рисков).

1. **`2a1395e6` — F11.** `applyZapretWithVPN` отказывает на уровне плана
   (`CodeFailedPrecondition`, `KeyPlanBypassInvalid`, точная причина про
   nfqws) при `strategy == nil`; мёртвый `defaultZapretStrategy` и импорт
   `bypass` удалены. Усиленный вектор: тест переписан в
   `TestPlanFromProtoZapretWithoutStrategyFails` (ожидает отказ, не
   поведение) — PASS; все zapret-тесты зелёные (`TestPlanFromProtoZapretWithVPN*` PASS).
2. **`8f63b049` — F5.** Проводка реальна: `refreshFingerprint()` вызывает
   `getNetworkFingerprint` из generated-стаба (`pbgrpc.dart:328` — метод
   существует), гейт `link.minor >= 10`, 10-сек таймаут, error/unimplemented-
   толерантность, пустые строки → null. `NetworkFingerprint.unknown()` и
   локальные модели (`profiles.dart:107`) согласованы с вызовом
   (`profiles.match(networkFingerprint)` → `handleProfileMatched`).
   **Риск ambiguous_import (HIGH, dev-машина):** `sora.dart` импортирует
   `core_control.pbgrpc.dart` и `profiles.dart`, оба экспортируют
   `NetworkProfile`/`NetworkFingerprint`; оба имени используются в
   `sora.dart`. Фикс в коммите (`hide NetworkFingerprint, NetworkProfile`,
   строка 24) безвреден и снимает конфликт; proto-типы по имени там не
   нужны (сверено: после hide нет ссылок на proto-имена). Flutter-анализатор
   по-прежнему за dev-машиной — подтвердить.
3. **`351b0d87` — мёртвые события.** `NOT WIRED (2026-10-20)` помечены оба:
   `KillSwitchChanged` (поле 10) и `BypassStrategyChanged` (поле 6)
   `core_control.proto:279,302`. Живое состояние реально течёт по другим
   путям (SetKillSwitch/GetStatus; bypass — journal), сверено с grep
   продюсеров/потребителей (ноль). Подтверждено.

### [pass2-detail] — 5 коммитов

Вердикт: **подтверждено все 5**.

1. **`8c81cb01` — цензурное событие в Dart.** Ветка реально завайрена:
   `_watchSession` (`sora.dart:939`) → `hasCensorshipDetected() && fresh` →
   `ingestCensorVerdict(CensorVerdict.fromWire(...))`; аксессоры
   `kind/confidence/explanation/evidence` сверены с `core_control.pb.dart`
   (класс `CensorshipDetected`, поля 1–4); Go-публикация существует
   (`server.go:937` — payload `CoreEvent_CensorshipDetected`). Вычитка
   аксессоров усилена сравнением с generated-кодом, не на доверии.
   Dart-тулчейна нет — компиляция за dev-машиной.
2. **`3531723a` — удаление Plan-полей.** 11 полей удалены из `plan.go`;
   проверка DNSServer.Dialer-прецедента: `Dialer` (`plan.go:297`) жив и
   читается рендерами (`mihomo/render.go:167`, `rules.go:224`,
   `config.go:89`) — не попал под удаление. `OriginalLink` убран и из
   `Outbound.Secrets()`; build+vet+tests зелёные. Подтверждено.
3. **`2742ca32`, `8c839cfe` — пины CI.** `golangci-lint` v2.15.0 (актуален;
   паритет с legacy `ed2f2d3`), proto-джоба на `go-version-file: core/go.mod`
   (все 6 мест в файле теперь согласованы). Подтверждено.
4. **legacy `e39fa15`.** Все 11 полей класса помечены `reserved` с точной
   формулировкой соседей; legacy-конвенция «помечать, не удалять»
   (C#-зеркало контракта) соблюдена; gofmt чисто; legacy build+vet+`engine`
   тесты зелёные (кроме известного env-артефакта). Подтверждено.

### [pass2-ext] — 7 коммитов

Вердикт: **подтверждено все 7**.

1. **`1f0ba5e5` — Stop прерывает run.** `runOnce` теперь строит контекст
   через `task.ctx` + `context.AfterFunc(pauseCtx, cancel)`: композиция
   таймаут ∨ задача (unregister/stop) ∨ пауза — сверено построчно
   (`worker.go:532-611`); host-aborted run не идёт в circuit breaker.
   Усиленный вектор: `TestUnregisterAbortsInflightRun`,
   `TestSchedulerStopAbortsInflightRun` — PASS под `-race`; существующие
   pause-тесты зелёные. `Scheduler.Status/Statuses` честен
   (circuit-breaker-задача отсутствует в статусе). Подтверждено.
2. **`da936b06` — канонические пути + declared entries.** `isSafeArchivePath`
   требует `name == path.Clean(name)` (`package.go:129-160`); Dir-записи
   пропускаются (пинится тестом). Declared-entry gate в Go
   (`package.go:227`) и Dart (`ext/package.dart:169-188`, фазовое зеркало
   `core/ext checkDeclaredEntries`) — обе стороны отказывают пакету без
   panel/worker/theme/hook/routing-файла. Threat-model §6 синхронизирован.
   Усиленный вектор: Алиас `"./panel.html"` — Meta-CSP не вставлялся,
   rollback re-verify падал: оба сценария закрыты каноничностью;
   CSP-полная политика `default-src 'self'` + `connect-src 'none'` intact
   (`store.go:402`, Dart-панель `panel_screen.dart:46`). Подтверждено.
3. **`bb7e2a1e` + `439f70d1` — rollout-бакет Go↔Dart.** Кросс-верификация
   независимым пересчётом (python sha256, NUL-разделители, BE-первые-8-байт
   mod 10000): все 7 pinned-векторов `TestRolloutEligiblePinnedVectors`
   сошлись 1:1 (бакеты 1113/5344/9757/4223/4108/2831/2831). Dart-комментарий
   честно фиксирует ловушку `'\\x00'` в Dart. Подтверждено.
4. **`e831c805` — схема/контракт bridge.** JSON Schema получила
   theme/network_hook/routing-поинтеры (schema раньше отвергала собственные
   примеры); коды ошибок bridge выровнены на документированный контракт
   (`invalid-argument`, `not-connected` задокументирован); `sora-ext.d.ts`
   без phantom-`token-revoked`. **Попутно закрыто N8 из PASS2-ANALYSIS**
   (гэп `getServers`: `_servers()` теперь отдаёт `{id, name, country,
   latency_ms}` с `country: ''` и `latency_ms` из probe-результатов, −1 —
   сверено `panel_screen.dart:289-303`). Подтверждено.
5. **`d43646d9` — маркер «not yet active».** Вайринг в install prompt
   (`permissions_sheet.dart:271-284`) и detail screen; 63 l10n-файла
   получили строку — коммит чистый, в дереве на месте. Подтверждено.
6. **`d95b589e` — threat-model §6.** Синхронизирован с гейтами 1–2.
   Подтверждено (сверка текстовых указаний с кодом).

### [pass2-audit] — 3 новых коммита (аудит)

1. **`5ad1ee75` — N1: примеры пересобраны без секретных ключей.** См. находку
   N1 ниже — закрытие сверено: 4 архива не содержат `author.key`/`author.pub`,
   payload 1:1 с loose-исходниками (все пакеты — актуальный v1-контракт,
   stale v0 удалён), подписи валидны через `pkg.Verify()`.
2. **`77f9f827` — pack отказывает на *.key.** Root cause N1 устранён в
   инструменте: `Collect` громко отказывает (`internal/pack/pack_test.go`
   пинит 3 варианта имени); dogfood: пересобранный пример валидируется,
   каталог с `author.key` отвергается.
3. **`8f6bfb98` — N4: снесён мёртвый фасад `diagnostics/deadsession.go`.**
   Ноль прод-вызывающих (deadmode зовёт `deadcheck` напрямую); тесты
   переехали в `core/deadcheck/deadcheck_test.go` (у пакета тестов не было —
   покрытие сохранено там, где живёт имплементация); build+vet+тесты
   `deadcheck`/`diagnostics` зелёные.

**Фальшивых закрытий прохода 2 — ноль.** Урок прохода 1 усвоен: каждый
претензионный пункт отдел подтверждает кодом и тестом, регрессионные
векторы на месте (NSDI-flaky, zapret-without-strategy, rollout-vectors,
pack-key-refusal, rollout, nxdomain-split).

---

## Часть B. 10 зон аудита

### Зона 1. Целостность ветки — PASS с оговоркой

- **Отравление staged-индекса ПРОДОЛЖАЕТСЯ (источник не найден).** На старте
  аудита индекс содержал точный реверт трёх коммитов `[pass2-swarm]`
  (staged-удаления в `plan.go`/`plan_fields_test.go`, `profiles.dart`,
  `sora.dart`, `core_control.proto` — рабочее дерево при этом == HEAD;
  проверено `git show HEAD:<path>` попайловым cmp). Снято
  `git restore --staged` (только свои 5 путей; чужих записей не было).
  Это уже 5+ инцидентов за два прохода. Рекомендация владельцу/координатору:
  найти источник (вероятно, конкурентный агент держит устаревший индекс),
  до устранения — каждый коммит только с проверкой `git diff --cached --stat`.
- История линейна, коммиты прохода в заявленном составе:
  13 `[pass2-debt]` + 4 `[pass2-tspu]` + 3 `[pass2-swarm]` + 4 `[pass2-detail]`
  (sora) + 1 `[pass2-detail]` (legacy) + 7 `[pass2-ext]` + 3 `[pass2-audit]`.
  Потерянных/переписанных коммитов нет (`git fsck` — только обычные dangling).
- Аудит-коммиты садились pathspec-формой, каждый со сверкой
  `git diff --cached --stat` перед и `git show --stat HEAD` после;
  чужие staged/unstaged не тронуты.
- Legacy: tip `e39fa15`, дерево и индекс чисты, untracked нет.

### Зона 2. Безопасность — PASS после фиксов аудита

- **N1 (Medium, закрыта кодом — см. выше). Реальный риск, честная оценка:**
  *Факт:* каждый из 4 `.soraext` содержал настоящий minisign secret key
  `author.key` (формат `untrusted comment: sora-ext signing key` + 74-байт
  `Ed`-envelope — не заглушка, а валидный секретный ключ), а манифест
  пинил соответствующую публичную часть как автора «Sora Team»
  (`github:levvs-one`). Также пакеты разошлись с loose-исходниками
  (net-hook-dpi и routing-split несли отменённый v0-контракт, theme-midnight —
  stale `theme.css`).
  *Риск (реальный, не завышенный):* компрометирован демо-ключ, а не
  командный. Каталог под командной подписью не опубликован (key ceremony
  не состоялась; церемониальный ключ — отдельный плейсхолдер), значит
  «доверенного», которое подписывалось бы этим ключом, в проде нет.
  Но: sideload-verify использует self-attested ключ из манифеста, а
  Store.Install пинит author key при обновлениях — обладатель секрета
  может выпускать «обновления» официальных примеров с тем же
  отпечатком ключа, и пользователь, установивший пример, получит
  подмену без ре-промпта. Импакт ограничен экосистемой примеров (JS
  без runtime, панели под CSP-lockdown), но прецедент «секрет в
  дистрибутиве» — недопустим для showcase-репозитория.
  *Фикс (безопасен, применён):* 4 пакета пересобраны из актуальных
  loose-исходников через штатный `sora-ext pack` и подписаны **свежими**
  одноразовыми ключами, чьи секреты уничтожены (shred) и нигде не лежат;
  манифесты ротированы на новые публичные ключи; старые ключи в README
  каждого примера объявлены burned/недоверяемыми; loose
  checksums.txt/signature.minisig теперь 1:1 с пакетами; `sora-ext pack`
  громко отказывает на `*.key` в проекте. **Остаток владельцу:** ключи
  навсегда останутся в git-истории (`bc2b9d16`) — к ним относиться как к
  публичным; при первой же публикации каталога использовать только
  свежие ключи церемонии; переписывать историю не предлагаю.
- N2/N3 (Go-ext недостижимая половина; ratings): как и в PASS2-ANALYSIS —
  честно задокументированный справочный код, без обмана; owner-решение F10
  висит.
- Adversarial-поверхность расширений (канонические пути, declared entries,
  CSP-lockdown, fail-closed net.fetch): перепроверена, зелёная.
- Legacy: redactor-паритет intact; нового не найдено.

### Зона 3. Корректность/отказоустойчивость — PASS с замечаниями

- **Новое S-tier из PASS2-DEEP-RESEARCH — спеки владельцу (не мелкие фиксы):**
  - **S1 (Medium-High):** `core/engine/mihomo/proxy.go:245` + `refs.go:82`
    жёстко отказывают AmneziaWG 3.1 на mihomo (`FeatureAmneziaWG3`) —
    deep-research показал, что пиннутый mihomo v1.19.32 реализует AWG 3.x
    полностью. Код **ложно отказывает** в рабочем пути. Правильный фикс —
    рендер 3.1-параметров в формат mihomo-опций + поднятие capability +
    интероп-валидация против бинаря (семантика `disable_cookies` в mihomo
    шире официальной спеки — A1). Вручную «по исходнику» не чиню —
    это класс ошибок молча-неправильного рендера; спека для транспортного
    отдела с dev-машиной.
  - **S2:** комментарий про lx-фингерпринт (`fingerprint.go`) неверен:
    `chrome` в lx = Chrome 133 (замороженный), Chrome 155 — только
    `chrome_155`; влияет на выбор/предупреждения — перепроверить на lx.
  - **S3:** Xray ≥26.9.8 требует гибридный key share X25519MLKEM768;
    у sora нет ручки и валидации — при бампе пина ломается REALITY.
  - **S5/S6:** Xray v26.10.17 (stall-фикс, новый TUN-стек, Go 1.27.3+) —
    input к бампу пина (только с .dgst-дайджестами и перевалидацией,
    см. решение detail-отдела по S1); lx-XHTTP: имена session*-полей
    реализованы — каталог про lx-XHTTP врёт, рендер молча роняет
    xmux/x_padding/session — спека транспортному отделу.
  - A4: CVE-2026-40898 (quic-go QPACK, фикс 0.59.1) — пины движков чисты;
    старые рекомендации Hysteria 2.7.1 уязвимы (доки сверены? — проверить
    при проходе 3).
- Из PASS2-ANALYSIS: N9 (устаревший комментарий sora.dart) — закрыт
  pass2-detail; N10 (противоречие доков strict-режима guard) — Low,
  поведение безопасно, оставлено; N5 (FingerprintWarning без вызывающих) —
  помечено как честная API-утилита в доке; не чиню (utility без триггера
  ≠ ложь, маркер в доке есть).
- F11 F5 (план-отказ, fingerprint) — см. часть A.

### Зона 4. End-to-end честность — PASS

- Новых театров за проход не найдено. Все претензии прохода —
  либо реальные проводки, либо честные NOT WIRED (обратное направление —
  «помечено wired, а вызывающих нет» — проверено deadcode-логикой по
  выборке: ложных маркеров нет).
- T011: сбор сигналов + диагностика WIRED, потребитель NOT WIRED —
  статус честный, owner-решение SW3 висит (не регрессия).
- F10 Go-сторона: owner-решение «удалить или завайрить» висит;
  проход нарастил только честно помеченные/справочные части.
- Sync E2E: демон, мост, QR round-trip — тесты зелёные; синк custom
  servers по-прежнему честно не поддерживается (ядро не отдаёт credentials).

### Зона 5. Качество кода — PASS

- `deadcode`-картина из PASS2-ANALYSIS без изменений за проход
  (фасад deadsession убран аудитом — −1 из списка).
- `go build ./...` + `go vet ./...` (все три Go-модуля) — чисто;
  `gofmt` — чисто по затронутым файлам.
- wire-compat удалённых/помеченных сущностей сохранена (GetBenchmarks
  RETIRED; мёртвые события — в proto с маркерами).

### Зона 6. Тесты — PASS

- **sora core: `go test -count=1 ./...` (TMPDIR=/tmp) — все пакеты
  зелёные, 0 падений** на финальном tip (включая ext под `-race` по
  worker-тестам; контрольный повтор после аудит-коммитов).
- `service/sync` и `tools/sora-ext` (вкл. новый `internal/pack`) — зелёные.
- **legacy: единственное падение `TestTunAndFakeIPAvoidLANAndEachOther` —
  доказанный env-артефакт** (интерфейс песочницы `host0` внутри fake-IP
  пула; падает и на чистом HEAD, зафиксировано в PASS1-AUDIT/PASS2-DEBT).
- Усиленные регрессионные векторы прохода: все поименно перепрогнаны —
  PASS (см. часть A).
- Предсуществующие флейки под нагрузкой (`TestWaitWhilePausedRePauseBeforeWakeup`
  под параллелью, `TestProbeFreezeDetectsCensor` под TMPDIR-длинным-путем) —
  класс env/тайминг, прод-багов нет; в полном прогоне на финальном tip не
  проявились.

### Зона 7. Упаковка/релиз — условно, без регрессий

- Пины движков согласованы (engines.lock ↔ catalog MinVersion ↔
  THIRD-PARTY-NOTICES): sing-box(-lx) 1.14.3 / xray 26.3.27 / mihomo 1.19.32.
  `updates/releases.json` 1.0.12 == pubspec 1.0.12+13.
- Открытые High из FINAL-AUDIT без изменений: digest tpws/nfqws в
  `build.sh`+`Discover`; `wintun.dll` в Windows-поставке; key ceremony —
  главный блокер (обновления и каталог расширений).
- Xray-бамп до v26.10.17 (S5) — input владельцу: только коммитом
  «lock+дайджесты из .dgst+MinVersion+гейты+перевалидация рендеров».

### Зона 8. Dart UI/UX/i18n/a11y — PASS с оговоркой (тулчейн)

- 3 Dart-правки прохода (F5-проводка, hide ambiguous-import, ingest
  censorship_detected) — вычитка против generated-стабов и proto;
  `flutter analyze`/`flutter test`/сборка — **обязательно на dev-машине
  до мержа** (накопленные Dart-изменения кругов 2–3, SDK здесь нет).
- l10n: маркер «not yet active» во всех 63 файлах; rollback-строки
  обновлений — русские дыры закрыты проходом 1.

### Зона 9. Legacy (Go + C#) — PASS по Go, C# вычиткой

- Коммитов прохода 2 в legacy — 1 (`e39fa15`), перепроверен (зона 4A).
- Legacy core: build+vet чисто; тесты зелёные кроме доказанного
  env-артефакта (зона 6).
- Дрейф за проход — односторонний (13 коммитов sora не портированы);
  содержательно релевантны: N7 (obfs-док legacy по-прежнему врёт про
  завайренный uTLS-диалер — фикс честности есть в sora, в legacy не
  портирован; Low, speка) и общий мёртвый набор форков (N6).
- C# — без изменений, вычитка прохода 1 в силе; сборка — за dev-машиной.

### Зона 10. Доки vs код — PASS после фиксов

- N8 (getServers) — закрыт `e831c805`; N9 (комментарий «API не приземлился») —
  закрыт `8c81cb01`; README примеров — честная burned-нота.
- `docs/extensions-quickstart.md:27` («never commit») — теперь
  подкреплено кодом (pack отказывает).
- Врущих утверждений, не зафиксированных в зонах выше, не найдено
  (spot-check ~25 ключевых утверждений проходов 0–1 держится).

---

## Честный ответ: готова ли ветка к ревью владельцем

**К ревью — да. К мержу — нет, пока не закрыт короткий список:**

1. **Dev-машина (владелец):** `flutter analyze` + `flutter test` + сборка
   (Dart-правки трёх проходов, особенно F5-hide); C# build; `buf generate`
   и дифф стабов; ручной `sora://` deeplink; релизные сборки с
   `--dart-define=APP_VERSION`; `test_update.py` (нужен bwrap).
2. **Владелец (действия):** key ceremony (minisign: обновления + каталог
   расширений) — главный блокер; social preview 1200×630 в Settings;
   решения: F10 Go-сторона (удалить/завайрить), F5/F6 core-сторы
   (сшить/снести), судьба select/tune/wgobfusc/stealth (~5.5k строк),
   Xray-бамп (с .dgst и перевалидацией), spectransportные спеки S1–S3/S6,
   N7-порт честности в legacy.
3. **Процесс:** источник отравления staged-индекса не найден —
   повторяется (5+ инцидентов); до устранения — каждый коммит только с
   `git diff --cached --stat` и чужие staged — `git restore --staged`.
4. Ключи примеров из `bc2b9d16` считать публичными навсегда; в
   прод-дов
...[truncated 138 chars]
