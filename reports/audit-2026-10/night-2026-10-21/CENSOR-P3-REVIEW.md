# CENSOR-P3-REVIEW — независимое ревью Hysteria2 + TUIC

Ревьюер: независимый, код не правил. Ветка `bugfix/audit-2026-10-19`,
`~/workspace/bug-hunt/sora`. Объект: `77e33259`, `dfd75223`, `429936d9`,
`91e9c4cf`, `50433b72` + отчёт автора `CENSOR-P3.md`.
Метод: чистый экспорт HEAD в worktree `/tmp` (на момент экспорта HEAD =
`150a29d3`, P3-коммиты — предки; ветка живая, к концу ревью HEAD ушёл
дальше), свои конфиги на пинах `~/workspace/.engines-amd64`
(sing-box-lx lx.22, mihomo 1.19.32, Xray 26.10.17), свои тестовые
векторы в worktree (не в репозитории). Пуша не было, коммитов не было.

## Итоговая таблица

| # | Пункт | Вердикт |
|---|-------|---------|
| 1 | Port hopping — главный фикс | **ПРИНЯТЬ** |
| 2 | TUIC (heartbeat, CC-словарь) | **ПРИНЯТЬ** |
| 3 | Obfs-гейт | **ПРИНЯТЬ** |
| 4 | BrutalCalibrator — честность | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** (Low: формула up в спеке §4.3) |
| 5 | Interop-честность | **ПРИНЯТЬ** (живой QUIC — ограничение среды, не PASS) |
| 6 | Мелочи | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** (см. M1, L3) |
| 7 | HEAD-консистентность + E3 | **ПРИНЯТЬ** (P3 полон; недостающее — чужое, перечислено) |

**Общий вердикт: ПРИНЯТЬ С ЗАМЕЧАНИЯМИ.** Ни одного High/блокирующего
замечания по коду P3. Единственное Medium — текстовый перекос в
комментариях самого P3 (M1), кода не касается.

## 1. Port hopping — ПРИНЯТЬ

Свои конфиги на реальных бинарях (не рендеры sora — ручные JSON/YAML):

| Проба | sing-box `check` | mihomo `-t` |
|---|---|---|
| `server_ports: ["20000-30000"]` (dash) | **FATAL `bad port range: 20000-30000`** | — |
| `server_ports: ["20000:30000"]` (colon) | OK | — |
| `server_ports: ["40000"]` (голый) | **FATAL `bad port range: 40000`** | — |
| `server_ports: ["40000:40000"]` | OK | — |
| `["20000:30000","40000:40000"]` (микс рендера) | OK | — |
| без `server_ports` | OK | — |
| `ports: 20000-30000` | — | OK |
| `ports: 20000:30000` | — | **error `invalid range: 20000:30000`** |
| `ports: 40000` | — | OK |

Главный тезис автора подтверждён дословно, включая текст ошибки бинаря.

Единый источник: `grep` по `core/` — `SingBoxHopPorts` вызывается ровно
в одном месте (`core/engine/singbox/render.go:323`), `HopPortRanges` —
он же + валидация (`core/engine/validate.go:1436`). Второго места со
спеллингом нет; mihomo пишет плановую форму дословно
(`core/engine/mihomo/proxy.go:96 px.Ports = o.HopPorts`) — правильно,
его бинарь dash требует. Одиночный порт и вырожденный диапазон: мой
вектор `SingBoxHopPorts("40000") = ["40000:40000"]`,
`("40000-40000")` — то же. Пустой набор: `if o.HopPorts != ""`
(render.go:322) — поля нет; мой `SingBoxHopPorts("") = []`, бинарь без
поля принимается. Бинарный тест автора
`TestBinaryAcceptsHy2HoppingAndTUICTuning` в чистом HEAD: **PASS**
(0.91 с, реальный `sing-box check`).

## 2. TUIC — ПРИНЯТЬ

- Round-trip: в чистом HEAD `TestTUICTuningSurvivesTheVault` **PASS** —
  ссылка `…&heartbeat=25` → parser (`heartbeat` в белом списке,
  `dfd75223`) → credential document (`plan.go`, `heartbeat` field +
  `TUICHeartbeat = atoiNonNegative(...)`) → `Outbound.TUICHeartbeat=25`;
  рендеры: sing-box `heartbeat: "25s"` (render.go:362,
  `EffectiveTUICHeartbeatSeconds`), mihomo `heartbeat-interval: 25000`
  (proxy.go:120). Не теряется, молча не дефолтится: unset рендерится
  эффективным значением явно в обоих движках (mihomo
  `TestRenderTUICDefaults` PASS: `bbr` + `10000`).
- CC-словарь один источник: `ValidTUICCongestion`/`ValidTUICUDPRelayMode`
  только в `quic_defaults.go`; валидация берёт оттуда, рендеры —
  `EffectiveTUICCongestion()`.
- Мусор на бинарях (мои пробы): sing-box отклоняет
  `congestion_control: "fast"` (`unknown congestion control algorithm`),
  `heartbeat: "bogus"`, `udp_relay_mode: "bogus"`. **mihomo `-t` молча
  принимает** `congestion-controller: fast` и `udp-relay-mode: bogus`
  («test is successful») — тезис автора верен, план-валидация там
  единственная защита.
- Мои векторы валидации (свой тест в worktree, PASS): heartbeat
  `0` → OK (дефолт), `1`/`600` → OK, **`601` → ошибка, `-5` → ошибка**;
  CC **`"fast"` → ошибка**, `""` → OK и резолвится в `"bbr"`;
  relay `"bogusmode"` → ошибка.

## 3. Obfs-гейт — ПРИНЯТЬ

- `RequiredFeatures` (`refs.go`, коммит `77e33259`): `Obfs != ""` на
  hy2 → `FeatureHy2Obfs`. Каталог: sing-box и mihomo заявляют
  (`catalog.go:57,90`), Xray — нет (`catalog.go:152`, с комментарием).
  Отсечка на выборе: `TestHy2SelectionGates` (interop) в чистом HEAD
  **PASS** — `SelectEngine(…, [Xray])` ошибается на salamander- и
  hopping-планах, sing-box выбирается. Рендер Xray при этом тоже
  отказывает (`xray/render.go:268-272`) — защита в глубину, а не
  единственный барьер.
- Парные ошибки: тип без пароля и пароль без типа — обе ошибки
  валидации (`validate.go:1392,1395`); бинарная подпорка моя:
  sing-box `obfs salamander` без пароля → `missing obfs password`,
  `obfs bogus` → `unknown obfs type`, gecko+salamander с паролем → OK;
  mihomo gecko OK, bogus отклоняет.
- Утечка пароля: мой вектор с уникальным маркером
  `MARKERP3-UNIQUE-9182` в трёх конфигурациях (пароль без типа,
  bogus-тип+маркер, тип без пароля) — **маркер ни разу не встретился в
  текстах ошибок**; тест ревьюера PASS, авторский
  `TestHy2ObfsValidationNeverEchoesPassword` PASS. Пароль при этом в
  `Secrets()` (маскировка сохранена).

## 4. BrutalCalibrator — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- Ручной кап не перетирается: `brutal.go` Apply возвращает
  `SourceManual` до любого обращения к кэшу/замеру; мой тест добавил
  частичный ручной случай (только `UpMbps=7`, `DownMbps=0`) — тоже
  `SourceManual`, значения нетронуты, кэш не заполняется (авторский
  тест + мой, PASS).
- Нет измерения → нет фиктивного капа: перебор всех присваиваний
  `UpMbps/DownMbps` вне тестов: `brutal.go:94` (кэш-копия уже
  измеренного), `brutal.go:110` (свежий замер), `control/plan.go`
  (данные кредов — ручной путь). Других путей нет; при
  `measuredDownMbps <= 0` и холодном кэше — `SourceNone`, поля
  остаются 0 (BBR), мой тест PASS.
- Кэш 7 суток, граница: мой тест с подменой `now` — на
  `cooldown − 1s` отдаётся `SourceCached`, **ровно на границе**
  (`now.Sub(at) < CalibrationCooldown` ложно) истёкший кэш не
  применяется: без замера `SourceNone`, с замером — перекалибровка.
  PASS.
- Константы против спеки `reports/tspu-solutions/21-hysteria2.md` §4:
  `0.9` — §4.3 `down = measured * 0.9` ✔; `0.1` — §4.2/§4.3 эвристика
  `down * 0.1` с пометкой «оценка» ✔ (флаг `UpEstimated` есть);
  cooldown 7 суток — §4.4 ✔.
- **L1 (Low, не регрессия P3):** §4.3 буквально пишет
  `up = min(userTariff, measured_down * 0.1)`, а код (и тест
  `TestCalibrateBrutal`, существовавший до P3) делает passthrough
  тарифа: замер 100 + тариф 20 → up=20, а не min(20, 9)=9. P3 эту
  семантику не вводил и не менял, в `calibrate.go` она честно
  задокументирована («up = the stated tariff when present»). Это
  расхождение текста спеки и кода — на решение владельца спеки, не
  блокер P3.

## 5. Interop-честность — ПРИНЯТЬ (трафик не проверен: среда)

Перепрогон в чистом HEAD (`SORA_ENGINES_DIR` задан):

```
TestHysteria2AndTUICThroughEngines — SKIP (3.05s):
  "UDP traffic from spawned engine processes is unavailable in this
   environment, so QUIC scenarios cannot run here (run on a dev
   machine): udp child probe: … read udp … i/o timeout"
TestHy2SelectionGates — PASS (9.59s)
```

Не PASS-обманка и не FAIL: сьют сам пробует UDP дочерним процессом и
честно скипает с причиной за ~3 с. Selection-гейты при этом реально
проходят. Фальшивая «матрица 13/21»: `grep "13/21"` по репозиторию —
только в отчёте автора как отзыв собственной ошибки (no_proxy-обход);
в коде и закоммиченных артефактах PASS по QUIC-трафику нет, матрица в
`hy2tuic_test.go` ничего не утверждает без трафика.
Независимое подтверждение среды: мой python UDP-loopback здесь умирает
`PermissionError: [Errno 1] Operation not permitted` на `sendto`.
**L2 (Low):** формулировка отчёта «EPERM для любого процесса» чуть
шире факта — Go-ребёнок пробы получает не EPERM, а молчаливый дроп
(read timeout). Вывод тот же (UDP недоступен), логика SKIP устойчива к
обеим формам.
**Живой QUIC/hy2/tuic трафик в этой песочнице НЕ проверен никем —
это ограничение среды, не PASS. Матрицу прогнать на dev-машине.**

## 6. Мелочи — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- `quic_defaults.go`, выборочно 4 числа до источника:
  `30` (hop interval) — спека 21 §3: дефолт UI 30, оба движка; ✔
  `5` (min hop) — спека 21 §3/§2: `hop_interval ≥ 5s`; ✔
  `100000` (кап) — спека 21 §3: валидация `≤ 100000`, и она же потолок
  калибровки (алиас в probe); ✔
  heartbeat `10` — заявлен как дефолт обоих движков; прямо из бинаря
  дефолт не извлекается, но значение рендерится явно, поэтому даже при
  расхождении дефолтов поведение детерминировано; `600` (max) — не
  пин спеки, а обоснованная в комментарии граница (NAT lifetime) —
  комментарий это не маскирует под спеку. Приемлемо.
- **M1 (Medium, честность текстов, коммит `77e33259`):** шапка
  `quic_defaults.go` (~стр. 16) утверждает проверку «and by live
  traffic in core/engine/interop/hy2tuic_test.go», а комментарий
  `ValidHy2Obfs` — «verified with `mihomo -t` and by live traffic».
  Живого трафика не было нигде (см. §5): проверены `check`/`-t`, не
  трафик. По стандарту владельца («не выдумывать») формулировки надо
  поправить на «traffic suite pending a UDP-capable machine». Кода и
  поведения не касается, потому не блокер приёмки работы, но это
  именно тот класс перекоса, который P3 сам честно ловил у себя в
  «13/21», — в коммит-текстах его оставлять нельзя.
- Границы hop: полный набор (перевёрнутый `30000-20000`, `0`, `65536`,
  один порт, `1-65535`, вырожденный, пустой элемент, trailing comma)
  — авторская матрица + мои векторы, все PASS, валидация и
  `HopPortRanges` согласны на каждом векторе.
- Детерминизм: `TestRenderHy2TUICDeterministic` в singbox и mihomo в
  чистом HEAD — PASS (байт-идентичность, 3 повтора у sing-box).
- `NoteBlocked` не копит: реализация — pruning всех истёкших на
  единственной точке записи (`probe/quic.go:352`). Мой тест на рост:
  500 записей, сдвиг времени за TTL (420 с), одна новая запись →
  `len == 1`. PASS. Авторского теста именно на pruning в наборе нет —
  пробел закрыт тестом ревьюера в worktree; рекомендую автору добавить
  такой тест в пакет (не блокер: поведение верное).

## 7. HEAD-консистентность — ПРИНЯТЬ; E3 точна

- Все символы P3 в чистом HEAD полны: `FeatureHy2Obfs`,
  `MaxHy2BandwidthMbps`, `HopPortRanges`/`SingBoxHopPorts`,
  `Outbound.TUICHeartbeat`, `ValidTUIC*`, `BrutalCalibrator`,
  `TestHy2SelectionGates` — определены, тесты зелёны.
- Чистый экспорт HEAD **не собирается без ЧУЖИХ файлов** — ровно три
  стаба, все не P3:
  1. `core/engine/ss_support.go` — `SupportsShadowsocksMethod`
     (зона CENSOR-P1; файл untracked в общем ворктри, в HEAD нет —
     автор о нём честно писал);
  2. `core/engine/ss_plugin.go` — `SupportsSSPlugin` (CENSOR-P1/P4;
     untracked, в HEAD нет) — у автора не упомянут: HEAD с момента его
     отчёта ушёл вперёд, каталог уже ссылается и на него;
  3. метод `AmneziaWG.IsZero` — ханк CENSOR-P4 в
     `core/engine/plan.go:543` общего ворктри (незакоммичен), а
     рендеры HEAD (singbox/mihomo/xray) его уже вызывают.
  С этими тремя стабами `go build ./...` чист и весь P3-набор тестов
  проходит. Чужие падения вне P3 в чистом HEAD: полный прогон
  `core/probe` падает на `TestProbeSeriesAgainstListener`
  (serial/freeze-зона, не brutal/quic/hy2; P3-тесты пакета по
  отдельности зелёны) — фиксирую как чужое, не P3.
- **E3 точна.** `BenchmarkServers` (`core/control/benchmark.go:33`)
  реально стримит `BandwidthSample{BytesPerSec uint64, Done}`
  (`probe/bandwidth.go:74`, финальный Done-сэмпл — `:239`); сигнатура
  `BrutalCalibrator.Apply(o, measuredDownMbps, userUpMbps)` совпадает
  с предложенным вызовом `Apply(outbound, float64(sample.BytesPerSec)*8/1e6, 0)`.
  Оба файла (`control/benchmark.go`, `control/server.go`) — чужая
  зона и прямо сейчас модифицированы другими отделами (MM в общем
  ворктри). Дифф выполним ровно как описан и действительно упирается
  только в чужие файлы; до него калибратор — протестированная
  библиотека с одним документированным швом, что автор честно и
  заявил (не «подключено», а «шов»).

## Замечания по серьёзности (сводно)

- **Medium:** M1 — «verified by live traffic» в комментариях
  `quic_defaults.go` при фактически не запускавшемся трафике
  (`77e33259`). Исправление текстовое.
- **Low:** L1 — спека 21 §4.3 `min(userTariff, down*0.1)` vs passthrough
  тарифа в коде (до-P3 семантика, задокументирована, тест-пинована);
  L2 — «EPERM для любого процесса» в отчёте шире факта (Go-проба —
  timeout); плюс рекомендация добавить тест pruning `NoteBlocked` в
  пакет probe.
- **Info:** набор чужих стабов для сборки HEAD вырос с 1 (у автора)
  до 3 — HEAD живой, не претензия к P3.

Непроверенное (честно): живой QUIC-трафик hy2/tuic (матрица 50433b72)
— только на машине с разрешённым UDP; Xray-кейс матрицы там же может
упереться в CA-обёртки/SORA-H5, о чём в тесте есть пометка.
