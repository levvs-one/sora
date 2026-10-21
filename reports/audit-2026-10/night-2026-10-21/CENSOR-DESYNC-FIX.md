# CENSOR-DESYNC-FIX — закрытие замечаний ревью CENSOR-DESYNC-REVIEW

Ветка `bugfix/audit-2026-10-19`, репозиторий sora. Режим: строго локально, пуша нет.
Коммиты (все — temp-index + CAS от текущего HEAD, состав проверен по `git diff --cached --stat` перед каждым; чужие staged/WIP не тронуты):

- `74f98971` — M1 (исполнитель сам себе сторож)
- `7b3ffb3a` — M2, M3, M4 (состояние), M6
- `57479dd0` — подключения (OnRefuse в журнал, IsCanary на прод-пути), M5 (контракт), proto-комментарии

## M1 — закрыта

`Engine.Apply` (`core/engine/bypass/bypass.go`) теперь первым шагом вызывает `resolvePlanStrategies` (`core/engine/bypass/resolve.go`): каждая bypass-стратегия плана резолвится самим исполнителем через `ResolveStrategy` и валидируется через тот же `engine.Outbound.Validate()`, что использует plan-валидация. Контекст Apply честно зафиксирован в комментарии: у Apply нет единого target SNI и измеренной длины пути (план обслуживает много хостов), поэтому резолв идёт с пустым SNI и hops=0 — стратегия с маркером `midsni` в этом контексте неразрешима и **отклоняется с ошибкой, называющей лекарство** (resolve against the target first — как делают тюнер и session-prober), а не стартует «примерно». Autottl-форма сохраняется для нативной калибровки nfqws. Резолвнутый план (копия, вход не мутируется) используется и для `Rewrite`, так что ключи портов и argv согласованы по резолвнутой форме. `Plan.Validate` в session остался вторым слоем.

Тест (по образцу probe ревьюера): `core/engine/bypass/apply_guard_test.go` — фейковые tpws/nfqws, записывающие argv в файл; прямой Apply стратегии `--split-pos=midsni` (tpws), nfqws-варианта и TLSRecord-маркера → отказ, бинарь не стартовал (файла argv нет), правил не установлено; отдельно — невалидная стратегия (OOBData без OOB) отклоняется самим Apply без всякого Plan.Validate выше по стеку.

**Мутационная самопроверка (требование задания):** резолв временно вырезан из Apply → `TestApplyRefusesUnresolvedMarkerItself` падает по всем трём строкам (nfqws-строка: Apply вернул nil — фильтр стартовал с маркером; tpws-строка: бинарь стартовал). Мутация убита, код восстановлен, пакет зелёный.

## M2 — закрыта

`profileForParams` (`core/tune/desync/registry.go`) сравнивает в одном пространстве: реестровые параметры резолвятся тем же SNI канарейки (`BlockedCanary.SNI`), что использует `Tune` в `resolveMarkers`, и ID сравниваются в резолвнутой форме. Регрессии: `TestProfileForParamsBindsMarkerProfiles` — все 3 маркерных профиля (`sni_block/split-midsni`, `sni_block/disorder-midsni`, `kz_variant/split-midsni`); честная оговорка в тесте: геном `kz_variant/split-midsni` байт-в-байт идентичен `sni_block/split-midsni`, поэтому биндится к той записи — F5 исполняет геном, а не ярлык. Сквозной `TestServiceTuneBindsWinner`-аналог `TestServiceTuneBindsMarkerWinner`: выигрыш маркерного профиля → биндер вызван с `sni_block/split-midsni`, `Binding.ProfileID` заполнен (probe ревьюера давал 0 вызовов и `ProfileID=""`).

## M3 — закрыта

`Service.Current()` пере-валидирует победителя через `validatedRing` (`runner.go`): версия реестра **и** версия пула генов (`GenePoolVersion` раньше не проверялась), резолв маркера, конвертируемость победителя (`convertsValidly` = `BypassStrategy()` + `Outbound.Validate()`). Неконвертируемый/устаревший победитель = честное «нет победителя» (ok=false) **+ событие**: новый колбэк `Service.OnRefuse(fp, reason)` с фиксированным токеном причины (без содержимого генома); контрольная плоскость подключила его к журналу (`desyncService()` в `core/control/desync_tune.go`, LevelWarning, source `zapret`, фингерпринт сети в лог НЕ пишется). Раннер-апы фильтруются по конвертируемости, а не роняют валидного победителя. Обе падающие probe ревьюера — тесты: `TestCurrentRefusesUnconvertibleWinner` (fake+TTL:5+AutoTTL при верных версиях) и `TestCurrentRefusesStaleGenePoolVersion` (GenePoolVersion+99); обе проверяют и отказ, и ровно одно событие.

## M4 — состояние починено полностью; прод-подключение Observe/Current — эскалация (точной точки без чужой зоны нет)

Состояние: `Rotator` больше не строится на каждый вызов. `Service` держит персистентные кольца по сети (`map[string]*boundRing`), кольцо строится из биндинга и перестраивается только при смене биндинга (At или победитель), рождается в `Binding.At` (новый `NewRotatorBorn` в `rotate.go`; `NewRotator` делегирует с now). `Current()` возвращает один и тот же `*Rotator` между вызовами (тест проверяет тождество указателя). Возрастная ротация работает от реального возраста победителя: probe ревьюера (биндинг часовой давности + раннер-ап) — тест `TestCurrentServesPersistentRingBornAtBindingTime`, кольцо сразу отдаёт раннер-апа. `Observe` теперь приводит то же кольцо в движение: цензурно-специфичные плохие сигналы (injected RST / block page / SNI stall) = `Rotator.Fail()`, чистый коннект = `Success()`; plain reset — только в health (шум кольцом не считается, тест пинит). Литералы `3, 15*time.Minute` вынесены в именованные константы с обоснованием. `Tune` сбрасывает кольцо сети при новом победителе.

**Эскалация — точная точка подключения прод-вызывающего.** В дереве по-прежнему нет прод-потребителя `Current()` и прод-источника `Observe()`: победитель тюнера никем не подаётся в живую сессию (это авторская эскалация №4 исходного отчёта, она не закрывалась и этим фиксом не закрывается). Шва внутри зон DESYNC нет — оба кандидата лежат в чужих зонах, где сейчас работают P1/P3/P4 и фиксеры LEAK/SURV:

1. Источник сигналов для `Observe`: `core/session/censor.go` — `censorshipWatcher.publish()` / хук `s.censorHook` (прецедент T042: manager уже вешает туда expedited-refresh). Подключение: второй потребитель вердиктов в session manager, маппинг `censor.Verdict.Kind` → `desync.Signal` (`KindRSTInjection`→`SignalInjectedRST`, `KindSNIBlocking`/`KindDataStall`→`SignalSNITimeout`, `KindNoInterference`→`SignalSuccess`), фингерпринт — `profiles.Current()`, Service — из `core/control` (`desyncServices`). Зоны: `core/session` + регистрация в менеджере сессий.
2. Потребитель `Current()`: сборка плана подключения (control `plan.go` / session runner) — при наличии bypass-аутбаунда брать победителя кольца по фингерпринту сети. Зоны: `core/control/plan.go`, `core/session`.
3. Альтернатива поллером по образцу SURV: `App.watchCensorshipNetwork` в `core/cmd/sora-core/main.go` уже крутит 10-секундный цикл в `Serve` — туда можно добавить опрос журнальных EventCensor текущей сессии, но это та же чужая зона (cmd).

До подключения кольцо полностью функционально через API Service (Tune → Bind → Current/Observe консистентны), что и пинят тесты выше.

## Миноры

- **M5 — контракт честно сужен** (второй вариант задания). Измерения хопов в дереве не существует: grep по `core/probe`, диагностике и всему core — ни traceroute, ни TTL-пробы нет; подключать нечего. У единственного прод-вызывающего (`desyncSessionProber.Probe`, hops=0) поставлен развёрнутый комментарий: ветка FakeTTL из этого пути недостижима сознательно, autottl калибрует сам nfqws (`--dpi-desync-autottl=<delta>:min-max`), FakeTTL работает для вызывающих с измеренными хопами через `ArgsForTarget`/`NFQWSArgsForTarget`; выдумывать хопы ради достижимости ветки — калибровка фейков по догадке. Если владелец захочет живое измерение — это отдельная задача в `core/probe` (зона не DESYNC).
- **M6 — закрыта.** `Summary()` больше не вставляет текст `BindErr`: вместо `%v` — фиксированная категория из `bindErrKind` (permission denied / storage path missing / storage path conflict / bind error по `errors.Is` на `fs.Err*`), полный текст ошибки остаётся доступен программно в `SearchResult.BindErr`. Тест `TestSummarySanitizesBindErr` — probe ревьюера verbatim (gateway `192.168.1.1` + SNI в ошибке): ни адреса, ни SNI, ни слова gateway в строке нет, предупреждение «binding not saved» сохранено.
- **IsCanary — завайрен по факту** (не удалён): `desyncSessionProber.handshake` в `core/control/desync_tune.go` теперь первым делом проверяет `desync.IsCanary(canary)` и не дёргает не-канареечный таргет; док `IsCanary` обновлён (структурная половина гарантии — отсутствие поля таргета в запросе — названа рядом). Существующий `TestCanaryAllowlist` зелёный.
- **Proto-комментарии приведены к хендлеру** (`proto/sora/censor/v1/censor.proto`, только комментарии, генерация не требуется — дескрипторы комментариев не содержат): `engine` — «empty = nfqws безусловно, capability-фолбэка на tpws нет»; заодно `probe_ran` — «хендлер всегда ставит true; случай false зарезервирован и не производится» (второе расхождение из того же абзаца ревью).

## Не входило в задание (фиксирую, не трогал)

- m3 ревью (авторский тест stopFilters не пинит фикс) и m4 (док `Capabilities.Gate` обещает фильтрацию кандидатов тюнером) в список миноров задания не входили; код по обоим пунктам ревьюером признан верным. m4 — однострочный док в `capability.go`, могу закрыть отдельным коммитом по слову родителя.
- Nit ревью про `e.swept` вне `e.mu` (потенциальный race Apply‖Close) ревьюером помечен как непроверенный, в задание не входил.

## Доказательства

- `go vet` чист: `engine/bypass`, `tune/...`, `control`, `profiles`, `censor`.
- `go test` зелёный в ворктри: `engine/bypass` ✓, `tune/...` ✓ (включая +7 новых тестов), `profiles` ✓, `censor` ✓, `control` — все desync-тесты ✓ (`TestTuneDesync*`).
- Полный `go build ./...` по core — чист.
- Известные чужие падения в `control`, не связанные с этим диффом: `TestCredentialDocumentMatchesLegacyMapForm` (xmux-поля из работы P1 в HEAD, ожидание теста — их зона) и `TestDetectCensorshipEventsWithoutOffsetsStayUnknown` — артефакт длины unix-socket пути при предписанном TMPDIR (тот же, что отметил ревьюер); с коротким TMPDIR проходит — перепроверено.
- gofmt чист по всем тронутым файлам.
- Живой пакетный прогон nfqws по-прежнему невозможен в песочнице (нет nfnetlink_queue) — граница из исходной эскалации №1, без изменений.
