# Анализ №6: legacy Go-ядро (sora-legacy/core)

Read-only анализ ветки `bugfix/audit-2026-10-19` на HEAD `65998529`.
Проверено сборкой: `go build ./...` и `go vet ./...` — чисто; staticcheck `U1000` — ноль неиспользуемых приватных идентификаторов; `TODO/FIXME` — ноль.
Дерево живое: во время анализа параллельный агент закрыл одну из находок (MTU-валидатор, коммит `b92735e`) — это отмечено в тексте.

---

## Вердикт

Код ядра — качественный: чистая слоистая архитектура (`control` → `session` → `engine` → `guard`/`secret`), аккуратный IPC, честная деградация на старых ОС, ноль мусора в линтерах. Главная болезнь — не код, а **модель владения кодом**: legacy-ядро на ~91% состоит из строк, совпадающих с sora-core, но живёт отдельным форком. Замеры (только не-тестовые файлы, 14 общих пакетов, 67 файлов с парой в sora):

- 18 файлов байт-в-байт идентичны (`logs/export.go`, `errs/errs.go`, `routing/presets.go`, `secret/format.go`, `engine/backoff.go` и др.);
- 40 файлов совпадают ≥90%;
- 12 341 из 13 557 строк совпадают — **91,0%**.

Итог — двусторонний дрейф: в legacy сидят баги, уже исправленные в sora (включая потенциальную панику процесса), а в sora отсутствуют фиксы, сделанные в legacy при его аудите. Порты идут вручную и отрывочно: SW1-порт (`e213804`) привёз в `obfs` фрагментацию и uTLS, но не jitter и не FakeSNI; `[net-rd]`-порты закрыли AmneziaWG-валидацию, но не whitelist'ы протоколов. Это игра в «ударь крота», а не стратегия. Для продукта, чьё позиционирование — «версия для старых систем» (где каждый sec-fix критичен, а QA-цикл тяжёлый), такое владение кодом — главный архитектурный риск.

Позиционирование при этом неожиданно честное (см. «Сильные стороны» и `legacy/PLANS.md`): проект не выдаёт непроверенное за проверенное.

---

## Сильные стороны

1. **Честность позиционирования.** `legacy/PLANS.md` прямо фиксирует: проверки шли на Linux и современной Windows в CI и «не подтверждают работу на Windows 7 или 8.1»; «Pktmon на Windows 7 отсутствует»; «Naive/cronet в выбранной legacy-сборке sing-box отсутствует»; «нельзя считать Linux-only zapret реализованным на Windows»; «Устаревший WebView2/CEF 109 не выдаётся за актуальный браузер». README.md: «совместимость с Windows 7 SP1 и 8.1 ещё не подтверждена запуском». Так и должно быть.
2. **Win7-инженерия — настоящая, а не декларативная.** SDK: форк `XTLS/go-win7` Go 1.26.9, архив с pinned SHA256 `4a8ea746…` и проверкой `VERSION` в CI (`.github/workflows/legacy.yml:89-91`). Движки под Win7: Xray win7-32, sing-box legacy win7-386, `sing-box-lx 1.14.3-lx.14` (собственная сборка из закреплённого исходника), mihomo x86 собран go120 (последний Go с поддержкой Win7), tun2proxy win7-i686 — всё с SHA256 в `THIRD-PARTY-NOTICES.md:6-10`.
3. **Graceful degradation на Win7.** `core/diagnostics/packets_windows.go:159-170`: `pktmonapi.dll` (требует Win10 1809+) грузится через `LazySystemDLL` + `proc.Find()` → на Win7 возвращается `CodeUnsupported`, служба не падает; `ExportDiagnostics` пробрасывает ошибку клиенту (`core/control/server.go:1311`), а не вешает RPC.
4. **Аккуратный legacy-мост для .NET.** `core/legacycontrol/server.go:37-60`: JSON-RPC поверх того же IPC-транспорта, методы берутся из сгенерированных gRPC-дескрипторов — валидация и lifecycle остаются в shared `control`. Лишнего кода почти нет (200 строк).
5. **Гигиена.** `go vet` чист, staticcheck `U1000` — ноль мёртвых приватных идентификаторов, ноль `TODO/FIXME/XXX`. Комментарии в целом честные и точные.
6. **В legacy есть фиксы, которых нет в sora** (обратный дрейф — см. §«Что портировать в sora»): probe не сканирует приватные сети, ipc гасит флуд неавторизованных подключений backoff'ом, subscription fetcher фрагментирует ClientHello.

---

## Слоп / проблемы

### Высокая серьёзность

**H1. `core/session/journal.go:167-183` — гонка «send on closed channel», паника процесса (SORA-H6 не портирован).**
`Subscribe` возвращает cancel, который делает `close(ch)` под мьютексом (строка 182). `Append` (строка 97) копирует подписчиков под мьютексом, **отпускает его и шлёт уже без мьютекса**. `WatchEvents` (`core/control/server.go:726-752`) подписывается на строке 774 и откладывает `feed.close()` (строка 736). Если отписка произойдёт между unlock и send в `Append` — паника всего процесса ядра. В sora это исправлено: подписчик — структура с флагом `closed`, канал никогда не закрывается, потребители завершаются по контексту. Триггер реален: события (StatsTick и др.) идут постоянно, `WatchEvents` рвётся при каждом отключении UI. `engine.EventBus` (`core/engine/events.go:77-90`) той же болезнью не страдает — там send идёт под мьютексом.

**H2. `core/control/plan.go:47-55` — `parseCredential` молча глотает ошибки (SORA-M8 не портирован), комментарий лжёт.**
```go
// parseCredential reads the import pipeline's flat credential map. Invalid
// documents are rejected in full to avoid partially configured connections.
func parseCredential(material []byte) map[string]string {
	out := make(map[string]string, 12)
	if len(material) == 0 {
		return out
	}
	_ = json.Unmarshal(material, &out)
	return out
}
```
«Rejected in full» — неправда: невалидный документ превращается в **пустую** карту секретов. `PutSecret` (`core/control/server.go:998-1017`) принимает произвольный `material` от клиента; при `Connect` `outboundFromProto` (строка 386) построит outbound с пустыми UUID/паролем вместо ошибки. В sora — fail closed с `CodeInvalidArgument`. Тот же fail-open паттерн рядом: `core/control/plan.go:432-436` — битый WireGuard `peers`-документ молча даёт outbound без пиров («plan validation identifies the failing outbound» — спорно); в sora там fail closed (SORA-L17).

### Средняя серьёзность

**M1. Протокольные пробелы: в `engine.Plan` нет `Token`, `Plugin`/`PluginOpts`, `AmneziaWG.HeaderProtectionKey`.**
Проверено: `grep` по `core/engine/plan.go` — совпадений ноль; `core/parser/parser.go` их не produces. Следствия:
- TUIC v4 (token auth) не поддерживается — только v5 (UUID+password);
- SIP002-плагины (v2ray-plugin и т.п.) не поддерживаются — только узкий мэппинг `obfs`/`obfs-host` (`core/engine/singbox/render.go:209-215`, `core/engine/mihomo/proxy.go:32-54`), тогда как sora умеет произвольные `Plugin`/`PluginOpts` (`sora/core/engine/mihomo/proxy.go:295-299`);
- AmneziaWG без header-protection key.
Часть подписок на legacy-клиенте молча не заведётся. Это не дыра маскирования (маскировать нечего — полей нет), а дыра поддержки протоколов. Решение должно быть осознанным: либо добавить, либо зафиксировать в `legacy/PLANS.md` как неподдерживаемое.

**M2. `core/engine/fields.go` vs рендеры — исправлено во время анализа.**
Валидатор отвергал MTU > 1500, а sing-box (`core/engine/singbox/render.go:564`) и mihomo (`core/engine/mihomo/rules.go:165`, коммит `177cc8a`) дефолтили неуказанный MTU в 9000: явно заданные 9000 отвергались, те же 9000 приходили молча по дефолту. Параллельный агент закрыл это коммитом `b92735e` («validator accepts the 9000 renderer default») прямо во время данного анализа — оставлено здесь как иллюстрация скорости дрейфа и ручных портов.

**M3. `core/obfs`: SW1-порт частичный.**
`core/obfs/profile.go` (120 строк) против sora (164): нет полей `Jitter` и `FakeSNI`; нет `jitter.go` (`jitterConn` — случайные задержки handshake-пакетов) и `sni.go` (`RewriteClientHelloSNI`). Порт `e213804` привёз только uTLS-профили и фрагментацию. Если scope legacy — «только SW1», это надо зафиксировать; иначе — допортить.

**M4. `core/guard/nftables.go:61` — сырая интерполяция bypass в nft-ruleset.**
```go
b.WriteString("\t\t" + family + " daddr " + network + " accept ...")
```
Производственный путь сегодня прикрыт `validateBypass` (`core/guard/nftables_linux.go:62-71`, вызывается из `NewNftables`), но экспортированная `NftRuleset` сама по себе — footgun для любого будущего вызывающего. В sora исправлено на уровне рендера (`parseBypassNetwork`: canonicalize + skip невалидного, fail closed). Defense in depth не портирован.

**M5. `core/session/runner.go` — не портированы robustness-фиксы sora:**
- строка 217: `_ = s.eng.Stop(context.WithoutCancel(ctx))` — ошибка остановки глотается (SORA-M16: в sora пишется в журнал как `EventError`);
- строка 257: `s.eng.Stop(ctx)` — остановка не отвязана от контекста вызывающего; отменённый `Disconnect` может подвесить manager (SORA-H7: в sora — `context.WithoutCancel` + `StopGrace`-таймаут);
- нет защиты от повторного `Start` после stop (SORA-M12);
- строка 82: `time.After` в цикле вместо переиспользуемого тикера (SORA-L21).

**M6. `core/control/subscriptions.go` — нет `killSwitchHolding`.**
В sora фоновые обновления подписок (прямой HTTPS) ждут отключения, пока поднят kill switch; в legacy они идут всегда — упираются в фаервол (шумно) и концептуально нарушают обещание «ни байта вне туннеля» для фоновой активности ядра.

**M7. Валидация плана слабее, чем в sora** (`core/engine/validate.go` vs sora):
- нет whitelist'ов `validProtocols`/`validTransports` — неизвестный протокол/транспорт падает поздно, на рендере, а не на валидации;
- нет `validateHysteria2Tuning`/`validateTUICTuning` (hop-порты, congestion control);
- нет `shadowsocksWarnings()`.

**M8. `core/secret/file_other.go` — нет `checkOwnerOnly`/`checkDataDir` (SORA-L3).**
Sora проверяет owner-only права каталога хранилища при каждом открытии; legacy — только при создании. На Linux права, ослабленные позже, не детектятся.

**M9. `core/engine/clashapi` дрейфует мелочью:** sora — `DisableKeepAlives` для короткоживущих controller-клиентов и `isRefused`-классификация; legacy — `MaxIdleConnsPerHost: 4` и широкий `isNetworkError` (`core/engine/clashapi/client.go:72-73`, `ops.go:202-206`). Не баг, но тот же дрейф.

### Низкая серьёзность / слоп

**L1. `docs/architecture/{core,engines,logs}.md` — чужие документы.**
Описывают modern sora: «интерфейс (Flutter, непривилегированный)», «Windows, Linux, Android и Android TV», «служба туннеля Android», ветки `feat/core-control-plane`. В sora-репозитории этих файлов вообще нет (там один `docs/architecture.md`). В legacy-репо (клиент .NET Framework 4.8, Windows 7/8.1 + Linux, без Android) они вводят в заблуждение. Переписать под legacy или удалить.

**L2. `core/obfs/dial.go` — `Dialer.DialTLS` без продакшн-вызывающих.**
Единственный прод-потребитель `obfs` — subscription fetcher через `Profile.WrapConn` (`core/cmd/sora-core/main.go:258-259`, `core/subscription/subscription.go:73`). `Dialer` (строки 18-83) покрыт тестами (`core/obfs/utls_test.go:72-128`), но в проде мёртв. Либо найти применение, либо честно пометить как API-заготовку.

**L3. `core/testdata/coexist/{dns,probe}.go` — 257 строк ничьего scratch.**
Linux-only `package main`-хелперы (фейковый DNS-сервер, probe-харнес), игнорируются тулчейном (testdata), ни один тест их не использует (`grep coexist` вне testdata — пусто), `os.Args[1]` без проверки границ. Вынести в `tools/` или удалить.

**L4. `core/README.md`:** таблица пакетов не упоминает `legacycontrol` и `engine/xraytun`; «Tested engine builds» без оговорки про `sing-box-lx`-форк для Win7; `packaging/engines/engines.lock` содержит только linux-бинарники — где пинятся Windows-сборки, из README не следует (они в `THIRD-PARTY-NOTICES.md` и CI).

**L5. `core/engine/redact.go:28` — O(n²) дедупликация в `Add`** (линейный скан на значение). Унаследовано из sora; при сотнях секретов не критично, но `map` был бы честнее.

---

## Что портировать в sora (обратный дрейф — legacy местами впереди)

1. **`core/probe/probe.go:44-47,145-153,179-188,207-278`** — запрет probing'а приватных/loopback/link-local целей (`AllowPrivate`, `isPrivateTarget`, `checkDialTarget` в `Dialer.Control`), наследие legacy-аудита. В `sora/core/probe/probe.go` этой защиты **нет вообще** — `ProbeServers` в sora может стать оракулом локальной сети.
2. **`core/ipc/ipc.go:123-128`** — backoff при отказе неавторизованным подключениям (`maxRefusedDelay = 250ms`, нарастающая задержка вместо горячего цикла). В sora только cap на число соединений.
3. **`core/subscription/subscription.go:65-73,97-124`** — `Obfs *obfs.Profile`: фрагментация ClientHello для фетчей подписок. В sora это поле выпилено из `subscription.Options`.

---

## Старые ОС: сводка проверки

| Вопрос | Статус |
|---|---|
| Go под Win7 | XTLS/go-win7 форк 1.26.9, SHA256 зашит в CI — честно |
| PktMon (Win10 1809+) | На Win7 graceful `CodeUnsupported`, без падений; зафиксировано в PLANS.md |
| DPAPI / WFP / named pipes / SCM | Win7-совместимы, код общий с sora |
| Движки Win7 | Xray win7-32, sing-box win7-386 + sing-box-lx 1.14.3-lx.14, mihomo x86 (go120), tun2proxy win7-i686 — с SHA256 |
| sing-box-lx без naive/cronet | Ядро таких транспортов не просит — разрыва нет |
| Сеть (fingerprint) | Polling через `net.Interfaces` — портативно |
| Реальный запуск на Win7/8.1 | **Не подтверждён** — честно зафиксировано в README и PLANS.md |

---

## Ранжированные рекомендации

1. **P0 — Починить гонку журнала (H1).** Портировать sora-подход: подписчик как структура с флагом `closed`, канал никогда не закрывать. Паника роняет весь процесс службы.
2. **P0 — `parseCredential` fail-closed (H2).** Вернуть `(map[string]string, error)` как в sora; заодно закрыть `peers` в `applyCredential` (SORA-L17). Убрать лгущий комментарий.
3. **P1 — Решить судьбу дублирования.** Варианты: (а) общий Go-модуль (`logs`, `errs`, `routing`, `secret`, `parser`, `diagnostics`, `session/journal`, `guard`-рендер) с версионированием между репозиториями; (б) зафиксировать legacy как feature-frozen и вести чеклист портов только sec-фиксов; (в) монорепо. Текущее состояние — худшее из двух миров.
4. **P1 — Протокольные пробелы (M1): осознанное решение.** Либо добавить `Token`/`PluginOpts`/`HeaderProtectionKey` + валидацию + маскирование, либо зафиксировать неподдерживаемое в `legacy/PLANS.md`. Сейчас — молча не работает.
5. **P2 — Портировать в legacy:** runner SORA-M12/M16/H7/L21 (M5); `killSwitchHolding` для подписок (M6); `checkOwnerOnly` (M8); `parseBypassNetwork` в `NftRuleset` (M4); `validProtocols`/`validTransports` + hy2/tuic tuning (M7); obfs jitter/FakeSNI или зафиксированный scope (M3).
6. **P2 — Портировать в sora** (обратный дрейф): probe private-target protection; ipc refused-backoff; subscription fetch fragmentation.
7. **P3 — Документы:** переписать `docs/architecture/*` под legacy или удалить (L1); дополнить `core/README.md` (L4).
8. **P3 — Слоп:** `testdata/coexist` → `tools/` или удалить (L3); судьба `obfs.Dialer` (L2); `redact.Add` O(n²) → map (L5).
9. **Процессное:** пока действует модель двух форков — вести единый реестр «что исправлено в sora, но не в legacy» (и наоборот) как часть Definition of Done для sec-фиксов, иначе дрейф будет воспроизводиться каждым новым аудитом.

---

## Методология

Ручной построчный diff 14 общих пакетов (`logs`, `errs`, `routing`, `secret`, `subscription`, `parser`, `diagnostics`, `obfs`, `session`, `ipc`, `guard`, `control`, `probe`, `engine`) + `proto/` + `docs/` + CI/workflow + `packaging/engines` + `THIRD-PARTY-NOTICES.md` + `legacy/PLANS.md`; `go build`, `go vet`, staticcheck `U1000`; проверка Win7-чувствительных API (pktmonapi, DPAPI, WFP, pipes, SCM). Аудит и 5-pass review не дублировались: все находки выше — либо дрейф между форками, либо архитектурный/позиционный слой, которых те не касались.
