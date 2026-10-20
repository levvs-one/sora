# PASS1-SWARM — третий круг feature-роя sora, проход 1/3: end-to-end верификация всех фич

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19` (`~/workspace/bug-hunt/sora`). Пуша нет.
Вход: WEB-RESEARCH-3, PASS1-DEEP-RESEARCH (6 S-tier), PASS1-ANALYSIS (M1–M3), SWARM-REPORT (второй круг).

**Условия работы (важно для чтения вердиктов):** дерево активно правили параллельные
агенты (pass1-tspu, pass1-detail, ext-команда). За время прохода HEAD сдвинулся минимум
4 раза; зафиксированы: sweep моего S1-фика в чужой коммит (`be8eddd0`), параллельное
завайривание `ext.Scheduler` в `core/control/server.go`, `WhitelistDetector` в watcher
и subnet-reputation (T011/T045, `6c58c0df`). Все мои коммиты — фильтрованные патчи +
temp-index + CAS `update-ref` по рецепту `~/AGENTS.md`; bare `git commit` не
использовался, кроме одного repair-коммита pathspec-формой по файлам, где весь дифф
был моим (`3be96820`). Тесты: `go build`/`go vet` чисты по всем затронутым пакетам;
известные НЕ мои падения — в конце отчёта.

---

## S2 (deep-research): пин sing-box «1.15.0» — stable не существует ✅ ИСПРАВЛЕНО

**Заявлено vs реально:** подтверждено. `core/engine/catalog.go:58` —
`MinVersion: "1.15.0"`; по changelog на 20.10.2026 последняя stable — 1.14.3,
1.15 — только `1.15.0-alpha.12`. Пол в таком виде принимал ТОЛЬКО пререлизы
upstream (Less() игнорирует prerelease) и отклонял единственную существующую
stable. Контр-аргумент в коде («рендереру нужны 1.15-семантики») не подтвердился:
заголовок каталога фиксирует валидацию рендеров `sing-box check` против
**v1.14.2**, а MissingFor-логика TUN-stack для 1.14.3 работает честно (stack
там honored, а не игнорируется).

**Фикс (коммит `836d0a3f`):** `MinVersion → "1.14.3"` с честным комментарием;
тест `TestSingBoxPin115KeepsTheLXFork` переписан в `TestSingBoxFloorKeepsTheLXFork`
(upstream 1.14.3 принимается, 1.14.2 — нет, будущая 1.15.0 и alpha принимаются,
lx-форк принимается, lx ниже своего пола — нет). Фичи, существующие только в
1.15-alpha (MASQUE endpoints), на «≥1.15.0» не гейтятся нигде в каталоге —
проверено grep'ом по Feature*: MASQUE в каталоге отсутствует, регрессии нет.

⚠️ **Коллизия для владельца чужого WIP:** в дереве лежит незакоммиченный
`singBoxFloor` (catalog.go, чужой рефактор BuildCapabilities). Его комментарий
по-прежнему говорит «1.15.0 upstream» — после моего фикса пол upstream = 1.14.3;
комментарий надо поправить при коммите того WIP (текст в дереве я вернул в
исходное состояние, чужие ханки не трогал).

## S1 (deep-research): Xray 26.3.27 и фингерпринт Chrome 133 ✅ ЧАСТИЧНО ИСПРАВЛЕНО, остаток — честный гейт

**Верификация цепочки:**
- Наш uTLS-пин (core): `v1.8.3-0.20261006-ff1b50f` — содержит HelloChrome_155,
  свежесть покрыта CI-гейтом `TestCoreUTLSFreshnessGate`. ✅ в порядке.
- Fingerprint-модуль: `CurrentChromeParrot = HelloChrome_155`, дефолт для Xray —
  `hellochrome_auto` (не голое `chrome`). ✅ в порядке.
- Что реально шлёт ядро: пин Xray в `packaging/engines/engines.lock` — **26.3.27**;
  его vendored uTLS мапит `chrome` → Chrome 133 (issue XTLS/Xray-core#7131).
  Явного `hellochrome_155` эта сборка НЕ знает (фикс `e5a6911` только в main).
- Находка расхождения: `xrayAcceptsFingerprint` пропускал явный `hellochrome_155`
  в рендер — на пине 26.3.27 конфиг падал бы при загрузке движка без понятной
  причины на нашей стороне.

**Фикс:** в `FingerprintWarning` (core/engine/fingerprint.go) — явное предупреждение
для явных парротов ≥ текущего Chrome: «not in Xray's vendored uTLS on the pinned
26.3.27 build… prefer hellochrome_auto». **Попал в HEAD внутри чужого коммита
`be8eddd0` ([pass1-tspu] T050)** — sweep на общем дереве: агент T050 добавил файл
целиком (его parrotwatch — соседний код). Контент проверен построчно, цел
(fingerprint.go:182–190). Историю не переписывал (дерево грязное, агенты активны).

**НЕ сделано осознанно:** бамп пина Xray — по заданию только на релиз с `e5a6911`;
такого релиза на 20.10.2026 нет (RPRX обещал конец октября). Version-gated порог
«первый релиз с 155» выдумывать нельзя — гейт поставлен вотчем T050 (parrotwatch,
ежемесячный) + этим предупреждением. При выходе релиза: бамп lock + MinVersion
одним заходом вместе с A1 (method/xhttpSettings) и A4 (legacy reverse) из
PASS1-DEEP-RESEARCH.

## S6: AnyTLS metadata ✅ РЕГРЕССИОННЫЙ ТЕСТ ДОБАВЛЕН

Рендер и так чист (`render.go`: только type+password+tls). В коммите `b24efa0e` —
`TestRenderAnyTLSHasNoMetadata` (новый файл `core/engine/singbox/hy2_tuning_test.go`):
allowlist полей anytls-аутбаунда + запрет любых ключей с `metadata`/`client`.
Упоминаний client-id для AnyTLS в UI/доках не найдено (grep).

## S4: Hysteria2 ✅ ИСПРАВЛЕНО

1. **Watchdog-порог:** был `stallWindow = 20s` (комментарий ссылался на «15–20 с»
   из раннего S4). PR #1703 по-прежнему НЕ смержен (проверено по PASS1-DEEP-RESEARCH).
   Коммит `ac4f879f`: порог → **12 с** (верх полосы 10–12: 10 с — таймаут патча
   #1703), комментарий обновлён. Тесты stall используют константу символически — зелёные.
2. **`bbr_profile` / `hop_interval_max` / `gecko`:** отсутствовали полностью (ни полей
   плана, ни рендера). Коммит `b24efa0e`, цепочка end-to-end:
   - план: `Outbound.HopIntervalMax int`, `Outbound.BBRProfile string`;
   - валидация: `hop_interval_max >= hop_interval`, max без портов — ошибка,
     `bbr_profile ∈ {standard, conservative, aggressive}`;
   - рендер sing-box: `hop_interval_max` ("90s"), `bbr_profile` — только когда BBR
     реально у руля (при заданных up/down caps клиент на Brutal, профиль был бы
     мёртвым текстом — тест `TestRenderHysteria2BBRProfileSuppressedUnderBrutal`);
   - `gecko`: тип obfs и раньше проходил через `out["obfs"].type` — добавлен
     регрессионный тест `TestRenderHysteria2GeckoObfs`;
   - импорт: parser принимает `hop-interval-max`/`hopintervalmax`/`bbr-profile`/
     `bbr_profile` в ссылках; `credentialDocument`/`applyCredential` прокидывают
     их в план (та же шина, что hop_interval).
3. **One-click сервер hy2 ≥ 2.8.1:** требование «сервер с фиксом #1703» в коде/доке
   не найдено (grep по репозиторию) — фиксировать нечего; диагностическая ссылка
   на #1703/#7169 как открытые баги апстрима добавлена в комментарий stall.go.

## S5: AmneziaWG 3.1 ✅ ИНВАРИАНТЫ ПОДТВЕРЖДЕНЫ, ОСТАТОК — ДОКУМЕНТИРОВАННАЯ РЕКОМЕНДАЦИЯ

Валидатор (`validateAmneziaWG`) уже содержал жёсткие инварианты спеки (проверено
построчно, тесты зелёные):
- H1–H4 диапазоны не пересекаются → ошибка;
- Header Protection: ключ ровно 32 байта и **S1–S4 ≥ 12** → ошибка;
- тайминги — `range<uint16>` валидируются; CPS-теги I1–I5 — структурно;
- H=1/2/3/4 трактуются как «механизм выключен» (совместимые значения не
  пересекаются по построению) — соответствует рекомендации спеки при HP.

**RandomTrailers ⇒ S1=S2=S3=S4:** в спеке это *рекомендация* («рекомендуется»),
не инвариант. Наш генератор (wgobfusc) СОЗНАТЕЛЬНО использует различные S
(комментарий в generate.go: distinct-but-safe, жёсткая проверка S1+56≠S2 в
валидаторе держится). Делать это ошибкой/варнингом — значит флаговать
канонический вывод собственного генератора. Коммит `5f24ef2a`: рекомендация
зафиксирована комментарием в валидаторе с обоснованием. Вердикт: честно.

**Риск-флаг lx «AWG 2.0» vs 3.1:** рендер-тест `TestRenderEmitsAmneziaWG31`
доказывает, что 3.1-поля уходят в конфиг verbatim. Усиление в `5f24ef2a`:
в `TestEngineAcceptsRenderedPlans` добавлен план `amneziawg3` под гейтом
`FeatureAmneziaWG3` — когда задан env с ПИННОВАННЫМ lx-бинарём, `sing-box check`
отклоняет неизвестные ключи, т.е. сборка, молча режущая 3.1-поля, падает на
проверке. На этой VM lx-бинаря нет — прогон с бинарём остаётся за dev-машиной/
CI (env `Prober.EnvVar`), помечаю как **открытый пункт верификации**, а не как
доказанный факт.

## S3 WEB-RESEARCH-3: ТСПУ бьёт подсетями — выбор серверов ⚠️ ПОЛОВИНА ЖИВА (сделано параллельной командой)

За время прохода приземлился `6c58c0df` ([pass1-tspu] T011/T045). Верификация:
- `core/probe
...[truncated 14362 chars]