# CENSOR-P3-FIX — исправления замечаний ревью CENSOR-P3

Фиксер: только тексты/комментарии и один тест; логика не менялась.
Ветка `bugfix/audit-2026-10-19`, `~/workspace/bug-hunt/sora`.
Коммит: **`5b0966e0`** `[censor] CENSOR-P3 review fixes: …`
(temp-index + CAS, родитель `86c9c2a2`, ровно 5 файлов, +86/−20;
реальный индекс и чужие staged/WIP не тронуты; пуша не было).

## Что исправлено

### M1 (Medium) — «verified by live traffic» при не запускавшемся трафике

Проаудированы все вхождения `live` / `traffic` / `verified` в зоне P3
(`quic_defaults.go`, `interop/hy2tuic_test.go`,
`singbox/binary_hy2tuic_test.go`, `validate_hy2tuic_test.go`,
`singbox/hy2_tuning_test.go`, `probe/{brutal,calibrate,quic}.go` и тесты).
Ложных утверждений о живом трафике нашлось ровно два — оба в
`quic_defaults.go` (коммит `77e33259`), как и указывал ревьюер. Остальные
`verified` зоны P3 — честные проверки `check`/`-t`; они не ослаблены, а
уточнены (каким именно бинарём/командой проверено). Утверждения о трафике
в чужих зонах (`catalog.go`, `engine.go` — XHTTP/REALITY/SS, TCP-interop,
который реально гонялся) вне зоны P3, не трогались; у `catalog.go` к тому
же есть чужой ворктри-дрейф относительно HEAD.

### L2 (Low) — «EPERM для любого процесса»

Единственное вхождение в коде зоны P3 — комментарий `udpChildProbeWorks`
в `interop/hy2tuic_test.go`. Приведено к точному описанию по типам проб:
python/shell raw-socket — EPERM на `sendto`; Go-дочерняя проба — не EPERM,
а молчаливый дроп и `i/o timeout` на чтении. Заодно убрано неподтверждённое
«the same binaries orchestrated from a shell pass traffic freely».
Прямое подтверждение нового текста получено при верификации (см. ниже):
дочерняя Go-проба падает именно `read udp 127.0.0.1:…: i/o timeout`.

### Рекомендация ревьюера — тест pruning `NoteBlocked`

Добавлен постоянный регрессионный тест
`TestBanTrackerNoteBlockedPrunesExpired` (`core/probe/quic_test.go`, в
стиле пакета: подмена `b.now`, как в `TestBanTrackerExpiryBoundary`):
500 записей, сдвиг часов за TTL (420 с), одна новая запись →
`len(b.until) == 1`, свежая запись жива, истёкшая вычищена именно записью.
PASS.

### L1 (Low, только документация) — спека 21 §4.3 vs passthrough тарифа

Проверено: поведение кода не менялось и не меняется (до-P3 семантика,
пин `TestCalibrateBrutal`: замер 100 + тариф 20 → up=20). Явного называния
расхождения осознанным отклонением в месте калибратора **не было** —
комментарий `CalibrateBrutal` честно описывал формулу, но не сверял её со
спекой. Добавлен абзац в док-комментарий `CalibrateBrutal`
(`core/probe/calibrate.go`): §4.3 буквально пишет
`up = min(userTariff, measured_down * 0.1)`; код сознательно делает
passthrough тарифа; причина — доля 0.1 это оценка для случая «тариф
неизвестен» (см. `brutalUpShare`), и позволять оценке от моментального
замера урезать заявленный пользователем тариф значит давать догадке
переопределять данные (тот же принцип, что у `BrutalCalibrator`:
ручные капы — данные, не подсказка); смена на `min()` — решение владельца
спеки, не тихий фикс.

## Таблица «утверждение было → стало»

| # | Файл | Было | Стало |
|---|------|------|-------|
| 1 | `core/engine/quic_defaults.go`, шапка | «Every value below was verified against the pinned binaries (sing-box-lx 1.14.3-lx.22 `check`, mihomo 1.19.32 `-t`, Xray 26.10.17 `run -test`) **and by live traffic in core/engine/interop/hy2tuic_test.go**» | «verified against the pinned binaries **by config acceptance** — `check` / `-t` / `run -test` — **and by the render and validation tests** in this tree. Those checks are real: they are what caught the sing-box hop-port spelling the binary rejects at load. **Live QUIC traffic was NOT verified in the audit environment (UDP is blocked there)** … the traffic matrix … self-skips where UDP is unavailable, and **it must be run on a UDP-capable dev machine**» |
| 2 | `core/engine/quic_defaults.go`, `ValidHy2Obfs` | «mihomo 1.19.32 also accepts (**verified with `mihomo -t` and by live traffic**, see the interop suite)» | «(verified with **`mihomo -t` and `sing-box check`** on the pinned binaries; **live traffic through the interop suite was not run in the audit environment and is pending a UDP-capable dev machine** — see hy2tuic_test.go, which self-skips there)» |
| 3 | `core/engine/quic_defaults.go`, hop-интервал 30 | «hy2 client (**verified on the pins**, CENSOR-P3)» | «hy2 client (**verified on the pins by `check`/`-t` config acceptance**, CENSOR-P3)» — утверждение было верным, уточнён способ проверки |
| 4 | `core/engine/quic_defaults.go`, `HopPortRanges` | «rejects the dash form at config load (**verified on lx.22**: "bad port range: 20000-30000"), while mihomo takes the plan spelling verbatim» | «(verified with **`sing-box check` on lx.22**: …), while mihomo takes the plan spelling verbatim (**verified with `mihomo -t`**)» |
| 5 | `core/engine/quic_defaults.go`, `SingBoxHopPorts` | «the binary rejects a bare "40000" as a bad port range, **verified on lx.22**» | «… **verified with `sing-box check` on lx.22**» |
| 6 | `core/engine/validate_hy2tuic_test.go`, `TestValidateHysteria2ObfsGate` | «both hopping engines reject an obfs block without a password at config load (**verified on the pins**)» | «… (verified on the pins with **`sing-box check` and `mihomo -t` — config acceptance, not live traffic**)» |
| 7 | `core/engine/interop/hy2tuic_test.go`, шапка сьюта | (описание сьюта «by fact of traffic» без оговорки о среде; читалось как «трафик проверен») | Добавлен абзац «Environment honesty»: **в аудит-песочнице UDP заблокирован, трафиковая верификация там НЕ запускалась**; сьют самопропускается по факту пробы; живой QUIC-прогон — **pending a UDP-capable dev machine**; в песочнице проверены config acceptance и юнит-тесты, и они не замена трафику |
| 8 | `core/engine/interop/hy2tuic_test.go`, `udpChildProbeWorks` (L2) | «in the audit sandbox **every UDP send from a descendant of the Go test binary is refused with EPERM** by the environment's network policy (measured 2026-10-20, all packet sizes, **while the same binaries orchestrated from a shell pass traffic freely**)» | «How the audit sandbox blocks UDP **depends on the probe type** (measured 2026-10-20): **python/shell raw-socket probes fail at sendto with EPERM** (Operation not permitted), while **the Go child probe here does not get EPERM — its datagram is silently dropped and the read times out (i/o timeout)**. Both forms mean UDP is unavailable there, and this probe treats either as a failure of the child…» |
| 9 | `core/probe/calibrate.go`, `CalibrateBrutal` (L1) | Формула задокументирована («up = the stated tariff when present»), расхождение со спекой 21 §4.3 **никак не названо** | Добавлено: «**Deliberate deviation from spec 21-hysteria2.md §4.3, named as such**: §4.3 literally writes up = min(userTariff, measured_down * 0.1), but this code passes a stated tariff through unchanged (measured 100 + tariff 20 yields up=20, not min(20, 9)=9). Reason: …» + причина и «changing it … is a decision for the spec's owner, not a silent fix here» (полный текст — в коммите) |
| 10 | `core/probe/quic_test.go` (тест) | Теста pruning `NoteBlocked` в пакете **не было** (пробел закрывал только тест ревьюера в его worktree) | Добавлен `TestBanTrackerNoteBlockedPrunesExpired`: 500 записей → сдвиг за TTL → одна запись → остаётся ровно 1 актуальная |

## Верификация

- `go vet ./probe/ ./engine/ ./engine/interop/` — чисто.
- `go test ./probe/` (полный пакет) — **PASS** (17.1 с), включая новый
  `TestBanTrackerNoteBlockedPrunesExpired` — PASS, и пин L1
  `TestCalibrateBrutal` (включая сабтест tariff 20 → up=20) — PASS.
- `go test ./engine/ ./engine/interop/` (полные пакеты) — **PASS**.
  Точечно по зоне P3: `TestValidateHy2TUICBoundaries`,
  `TestHy2ObfsRequiresFeatureGate`, `TestHopPortRangesAndSingBoxSpelling`,
  `TestEffectiveTUICDefaults`, детерминизм рендеров sing-box/mihomo — PASS.
- С пинами (`SORA_ENGINES_DIR=~/workspace/.engines-amd64`):
  `TestBinaryAcceptsHy2HoppingAndTUICTuning` (`sing-box check`) — **PASS**;
  `TestHy2SelectionGates` — **PASS** (12 с);
  `TestHysteria2AndTUICThroughEngines` — **SKIP** с причиной, дочерняя
  проба: `read udp 127.0.0.1:56803->127.0.0.1:52402: i/o timeout` —
  живое подтверждение исправленного текста L2 (Go-проба: timeout, не EPERM).
- `gofmt`: мои файлы `quic_defaults.go`, `calibrate.go`, `quic_test.go` —
  чисты. По двум тронутым файлам `gofmt -l` флаги **предсуществующие на
  HEAD** (проверено по HEAD-блобам, моими правками не внесены):
  `interop/hy2tuic_test.go` — порядок импортов (`os/exec`);
  `validate_hy2tuic_test.go` — `MinHy2HopIntervalSeconds - 1` без пробелов
  в чужой строке таблицы. В коммит не вносились: это не тексты замечаний,
  а чужие ханки форматирования.

## Чужие падения / не моё

- Отмеченное ревьюером падение `TestProbeSeriesAgainstListener` в чистом
  экспорте HEAD в текущем ворктри **не воспроизвелось**: полный пакет
  `probe` зелёный. Не чинилось (не падало), фиксирую как наблюдение.
- Иных падений в затронутых пакетах (`probe`, `engine`, `engine/interop`,
  `engine/singbox`, `engine/mihomo`) нет.
- Реальный git-индекс ветки по-прежнему содержит массовые staged-удаления
  параллельных отделов (состояние до моей работы) — не тронут; коммит сделан
  temp-index + CAS (`update-ref` со старым значением), `git show --stat HEAD`
  показывает ровно мои 5 файлов.

## Осталось (честная эскалация, без изменений)

- **Живой QUIC-трафик hy2/tuic по-прежнему не проверен никем** — прогон
  матрицы `interop/hy2tuic_test.go` на машине с разрешённым UDP
  (dev-машина). Теперь это дословно написано в шапке `quic_defaults.go`,
  у `ValidHy2Obfs` и в шапке самого сьюта.
- Расхождение спеки 21 §4.3 (`min(...)`) с кодом (passthrough) — решение
  владельца спеки; в коде теперь названо осознанным отклонением с причиной.
