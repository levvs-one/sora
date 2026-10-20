# PASS2-DEBT — закрытие долга прохода 1 (2026-10-20)

Агент закрытия долга. База: sora `e60f9854` (ветка `bugfix/audit-2026-10-19`),
legacy `1297c0f`. Итог: sora tip **`999d58a0`** (12 коммитов `[pass2-debt]`,
пуша нет). Все коммиты — temp-index CAS-рецептом из `~/AGENTS.md`
(read-tree HEAD → apply только своих путей → проверка
`git diff --cached --stat` → write-tree → commit-tree → update-ref CAS);
bare `git commit` не использовался. После каждого CAS-коммита реальный
индекс синхронизировался `git read-tree HEAD` (индекс отстаёт от HEAD
при commit-tree/update-ref — иначе следующий прогон видит собственный
коммит инверсией как «staged-удаления»; один раз это сработало как
ложная тревога, чужих staged-записей при этом не было).

## Задача 1. WIP закоммичен, чистый tip зелёный

WIP на старте: 32 tracked-файла (+1504/−274) и 17 untracked-путей.
Разобран на связные темы и закоммичен по отдельности:

| Коммит | Тема |
|---|---|
| `0977ab03` | control: SS plugin/plugin_opts переживает vault (T020, фикс кода под `TestShadowsocksPluginSurvivesTheVault`) + `refPrefix`-рефактор subscriptions + untracked `plan_fields_test.go` |
| `f04b3ec1` | diagnostics: JA4 external-тесты (PQ key share, freshness gate, untracked `ja4_test.go`) + комментарий GREASE |
| `b93b59a0` | engine: `MissingFor` по конкретному билду (sing-box 1.15 TUN stack, floor lx 1.14.3 vs upstream 1.15, REALITY-over-ws/httpupgrade гейт для Xray), supervisor использует `MissingFor` |
| `6391cd3a` | test: обновлены устаревшие ожидания sing-box рендера (см. 5 тестов ниже) |
| `a855c2f0` | mihomo: тест REALITY smux по умолчанию (T007) + gofmt |
| `73d62fc1` | stealth: грейдинг stale/randomized/no-PQ фингерпринтов + тесты |
| `e9df39fd` | proto: Since-маркеры 1.10/1.11, история контрактов в proto/README, untracked `version_test.go` (контракт версии в cmd/sora-core) |
| `55541758` | ext: честная математика рейтингов (Bayesian + decay) + `catalog_store_test.go` (untracked волна-40 — связный код с тестами, закоммичен как тема ext) |
| `936cadc3` | app/ext: разрешения конфликтов (untracked `conflicts.dart` + `conflicts_sheet.dart`), UI каталога (рейтинг/rollout/changelog), bridge onEvent unsubscribe |
| `2c682c85` | app: прогресс загрузки обновлений на все файлы + стадия `checking` в About |
| `bc2b9d16` | docs: гайды расширений (quickstart/api/cookbook/devmode), поля каталога в extensions.md, примеры theme/routing/net-hook (со .soraext) |
| `b73da80b` | docs: NFQWS-MIGRATION.md (bypass, spec-only) |
| `999d58a0` | T011 honest NOT WIRED (задача 2) |

Замечание по `e9df39fd`: в WIP у `core/gen/sora/custom/v1/custom_grpc.pb.go`
есть комментарий про TestCustomServer (DNS-резолв вне туннеля), которого
нет в `custom.proto` — gen/proto расходятся на один комментарий; WIP
закоммичен как есть, выровнять при следующей регенерации.

### 5 красных тестов чистого tip `e60f9854` — поимённо и судьба

Установлены прямым прогоном `go test -count=1 ./...` на архиве чистого
HEAD (в PASS1-AUDIT поимённо они не перечислены):

1. `TestShadowsocksPluginSurvivesTheVault` (core/control) — падал:
   `plugin lost on the way to the engine: "" ""`. Это был не устаревший
   тест, а баг кода: `credentialDocument` не клал `ss_plugin`/
   `ss_plugin_opts`. Исправлен КОД коммитом `0977ab03`. На новом tip: PASS.
2. `TestRuleSetDownloadDetourUsesProxyWhenFinalIsDirect` (core/engine/singbox) —
   устаревшее ожидание: рендер уже пишет detour через `http_clients` +
   `route.default_http_client` (download_detour deprecated в 1.14).
   Тест заменён на `TestRuleSetDownloadsUseHTTPClient` (`6391cd3a`). PASS.
3. `TestRuleSetDownloadDetourFollowsProxyFinal` (singbox) — то же.
   Заменён на `TestRuleSetDownloadsFollowProxyFinal`. PASS.
4. `TestRenderNeverEmitsMultiplex` (singbox) — устаревшее ожидание:
   мультиплекс теперь по умолчанию для REALITY (T007). Заменён на
   `TestRenderMultiplexDefaultsToReality`. PASS.
5. `TestRenderDNSH3UsesAddressForm` (singbox) — устаревшее ожидание:
   рендер уже эмитит `type: "h3"` (legacy `h3://` форма удалена в 1.14).
   Заменён на `TestRenderDNSH3UsesTypeH3`. PASS.

Тот же WIP заодно переименовал/усилил `TestRuleSetDownloadDetourOmittedWithoutProxies`
→ `TestRuleSetDownloadsOmitHTTPClientWithoutProxies` и добавил
`TestTunMultiQueueFollowsEngineVersion`, `TestTunAutoRedirectNeedsEngineRouting`
(на чистом tip не краснели).

### Верификация чистого tip `999d58a0` (архив дерева, без worktree)

- core: `go build ./...` + `go vet ./...` — чисто.
- core: `go test -count=1 ./...` — зелёный, КРОМЕ одного load-флейка:
  `TestProbeFreezeDetectsCensor` упал 1 раз в полном параллельном
  прогоне; соло пакет probe зелёный многократно (3/3 на `e60f9854`,
  1/1 на `999d58a0`, 14.5 с). Тот же класс флейков, что зафиксирован в
  PASS1-AUDIT (нагрузочные). Не регрессия этого долга.
- service/sync: build+vet+test `-count=1` — зелёный.
- tools/sora-ext: build+vet+test `-count=1` — зелёный.
- 5 тестов выше поимённо прогнаны на чистом tip: все PASS.

### Worktree после

Связного незакоммиченного WIP не осталось. Остаток — только мусор
(НЕ коммитился, как предписано):
`core/sora-core` (бинарь 26 MB), `service/sync/sora-sync.exe`,
`app/tool/__pycache__/`, `packaging/linux/__pycache__/`,
`core/control/subscriptions.go.3091033395789509018` (temp-копия).
Индекс чист (`git diff --cached` пуст).

⚠️ **Чужой WIP появился ВО ВРЕМЯ этой сессии и продолжает расти:**
`core/probe/serial.go` (+131/−16) и `core/probe/serial_test.go` (+118),
mtime 06:02 UTC; к концу сессии добавились `M core/cmd/sora-core/cli.go`
и untracked `core/cmd/sora-core/seriesprobe.go` + `seriesprobe_test.go`
(та же тема series-probe). Конкурентный агент всё ещё пишет в дерево.
Ничего из этого не тронуто и не закоммичено; владельцу зоны —
разобрать. (Подтверждает наблюдение PASS1 про отравление/гонки:
перед мержем проверить `git status` ещё раз.)

### sora-legacy

WIP нет (`git status` чист, tip `1297c0f` без изменений). Чистый tip:
build+vet чисто; `go test -count=1 ./...` — единственный фейл
`TestTunAndFakeIPAvoidLANAndEachOther` — доказанный env-артефакт
PASS1-AUDIT (интерфейс VM `host0 = 198.19.0.2/30` внутри fake-IP пула
`198.18.0.0/15`), не устаревшее ожидание. Действий не требуется.

## Задача 2. T011 — вердикт: честный NOT WIRED (завайрить некуда)

`Picker.WithSubnets` НЕ завайрен в прод, и это не недосмотр, а
отсутствие точки потребления. Доказательства:

1. **Прод-импортёров `core/select` — ноль.** `grep -rn "serversel\|core/select"`
   по `core/`, `service/`, `tools/`, `app/` вне самого пакета: пусто.
   `WithSubnets` вызывают только тесты пакета (`core/select/subnet_test.go`).
2. **В Go нет места, где результаты проб превращаются в выбор сервера.**
   `control.Server` только стримит `ProbeResult` (`ProbeServers`),
   `Connect` получает от Dart готовый план (`planFromProto`), выбор
   внутри групп делегирован url-test самих движков. Ни одного
   PickBest/NewPicker-вызова в проде нет.
3. **Живой выбор — в Dart** (`compareAutoSelect`, `_fastest`,
   `pickMember` в `app/lib/src/sora.dart`, режимы ping/speed/smart на
   Dart-истории latency/bandwidth). Туда subnet-вердикт не подать:
   `ProbeResult` (proto, поля 1–6) не имеет subnet-поля, а
   buf/protoc в окружении нет (`which buf protoc` — пусто) —
   сгенерированные стабы руками не правятся честно.
4. **Пакет уже несёт owner-решение:** `core/select/select.go` —
   «NOT WIRED … moving selection into the core … is an owner decision
   (SW3)». Вайринг Picker'а в план-группы вопреки SW3 был бы
   выдуманной фичей (порядок fallback-членов осознанно строит Dart по
   latency; у Go на Connect нет ни latency, ни bandwidth, а Addr
   кандидатов чаще домен, а не IP).
5. Живая часть T011 не пострадала: трекер питается реальными дайлами
   пробера (`probe.go`), читается диагностикой
   (`cmd/sora-core/main.go`: `prober.Subnets().SummaryLines()`).

### Что сделано по T011 (коммит `999d58a0`)

- `core/probe/probe.go`: исправлен **врущий комментарий** у `Subnets()` —
  было «Server selection reads it to avoid carpet-banned subnets»
  (неправда); теперь честный статус T011 + блокеры + ссылка на SW3.
- `core/select/select.go`: к существующему NOT WIRED добавлен
  pass-2 вердикт и **чек-лист разблокировки**: (1) owner решает дом
  выбора (SW3); (2a) Dart-путь — поле subnet-state в ProbeResult
  (нужен buf/protoc) + потребление в `compareAutoSelect`/`_fastest`;
  (2b) core-путь — selection-RPC/шаг плана, строящий
  `NewPicker(...).WithSubnets(prober.Subnets())`.
- `app/lib/src/sora.dart`: у `compareAutoSelect` поставлен маркер
  «T011 NOT WIRED here» с причиной (нет поля в ProbeResult, нет
  protoc, Go-пикер без вызывающего) — Dart-выбор нельзя описывать как
  избегающий подгоревших подсетей.
- Тест «прод-пути» не написан по определению: прод-пути нет; юнит-тесты
  Picker'а с WithSubnets (`TestPickRejectsBurnedSubnet` и др.) на месте
  и зелёны — они пинят поведение на день разблокировки.

Итог по T011: **сбор сигналов и диагностика — WIRED; потребитель —
NOT WIRED, честно помечен в трёх местах кода, разблокировка = решение
владельца SW3 + (protoc | Go-selection)**.
