# T002 + T007: REALITY hardening — vision mandate & siberian freeze defense

IDs: **T002** (vision обязателен для VLESS+REALITY), **T007** (детектор «сибирской» заморозки + бюджет handshake).
Дата: 2026-10-20. Статус: код — коммит `[tspu-fix]` (см. ниже); остальное — контракт для control-plane / app / операторов.

## 1. Проблема

Полевые данные (TSPU-ANALYSIS §10, §21): протокольного детекта REALITY нет (nDPI: NOT DETECTED),
но серверы классифицируются как прокси через ошибки деплоя, а клиенты — через поведение:

- **T002.** VLESS+REALITY+TCP без `xtls-rprx-vision` — это TLS-in-TLS: внутренний handshake виден
  внутри внешнего, детектируемый сигнал, который цензор уже распознаёт.
- **T007.** «Сибирская» волна: (подсеть/AS × SNI × uTLS-фингерпринт) + **>3 параллельных
  TLS-handshake за 60 с на один SNI → заморозка 120 с**. Подозрительные fp: Chrome/Safari/iOS;
  проходят Firefox/Edge/QQ/Android(OkHttp). Прямых свидетельств ML в проде ТСПУ нет — это
  детерминированная эвристика, и она бьётся структурно.
- Архитектурный конфликт: **в Xray vision несовместим с mux** (upstream silently ignores mux
  под vision). Нельзя «включить и то, и другое» — нужно решение, что побеждает.

## 2. Решение: что сделано в коде

### 2.1. T002 — vision-контроль и верификация параметров

**`core/engine/reality.go`** (новое):
- `RealityWarnings() []string` — коды предупреждений (стабильный UI-контракт):
  - `reality-without-vision` — VLESS+REALITY+TCP без vision (TLS-in-TLS);
  - `reality-ws-transport` — WS+REALITY (Xray-рендер это реджектит; варнинг — раньше, на импорте);
  - `reality-xhttp-vision` — XHTTP+vision (несовместимы; мультиплексирование там — работа xmux);
  - `reality-dest-ip`, `reality-dest-not-host`, `reality-dest-missing` — дест не похож на настоящий сайт.
- `ValidateReality() error` — жёсткие ошибки: нет public key; ключ не 32-байтный base64url
  X25519; shortId не hex или длиннее 8 байт (лимит Xray). Подключено в `Outbound.Validate()`
  и `Outbound.Warnings()` (хуки — см. §5).
- `IsVisionFlow()` — оба варианта vision (`xtls-rprx-vision`, `xtls-rprx-vision-udp443`).

### 2.2. T002 — архитектурное решение vision↔mux

**Решение: побеждает vision.** В `core/engine/xray/render.go` mux НЕ эмитится под любым vision
flow (Xray всё равно его игнорирует — эмитить было бы ложью в конфиге). Роль анти-параллелизма
под vision отдана **XHTTP+xmux**, не outbound-mux. sing-box и mihomo vision не поддерживают —
там mux для REALITY всегда применим.

### 2.3. T007 — mux по умолчанию для REALITY

**`core/engine/mux.go`** (новое): `MuxOptions{Disabled, Concurrency}`, `RealityMux()` (дефолт ON
для REALITY), `MuxConcurrency()` (дефолт 8, clamp 128). `Options.Mux` — в `engine.Options`.
Рендеры: Xray `"mux": {"enabled": true, "concurrency": N}` (кроме vision); sing-box
`"multiplex": {"enabled": true, "protocol": "smux", "max_streams": N}`; mihomo
`smux: {enabled: true, protocol: smux}`. Один TLS-коннект вместо N параллельных handshake —
триггер заморозки отрезан структурно.

### 2.4. T007 — сессионный трекер заморозки

**`core/censor/siberian.go`** — `FreezeDetector` поверх сессионных `Attempt` (не проб!):
узкая сигнатура (TCP завершён, TLS встал/убит до первого байта сервера) → действие:
- **backoff ≥120 с** (`BackoffUntil`/`RetryAfter`): во время горячей заморозки — никаких новых
  handshake и **запрет смены fp** (смена mid-freeze сжигает следующий фингерпринт);
- лестница: ротация fp → ротация SNI → failover; `Begin()/end()` меряет пиковый параллелизм.
- Ротация `NextSiberianFingerprint`: только `firefox→edge→qq→android`, без возврата к
  подозрительным Chrome/Safari/iOS.

**Расхождение с `core/probe/freeze.go` (sibling):** там — измерение явления (пассивные сэмплы +
активный дифференциальный пробинг); здесь — политика сессии по уже случившимся событиям,
без лишнего проб-трафика. Разные работы. Но: их `RotateFingerprint` циклит и подозрительные
fp (chrome/safari/ios) — противоречит полевым данным T007; **рекомендация — унифицировать
на «подозрительные исключены»** (чужой файл не правил).

**`core/censor/snipool.go`** — `SNIPool`: пул консистентных SNI (ротация, `MarkBad`).
**`core/censor/budget.go`** — `HandshakeLimiter`: ≤3 параллельных handshake на SNI для
dial'ов самого core (на движки не распространяется — там защита = mux).
**`core/censor/scan.go`** — общий примитив `terminalScan`.

### 2.5. Wiring-контракт для control-plane (не код)

1. Dial'ы оборачивать: `end := detector.Begin(sni); defer end()`; исход → `Observe`/`ObserveSuccess`.
2. Перед коннектом — `BackoffUntil(sni)`; во время бэкoff'а не dial'ить и не менять fp.
3. `Assess(sni, fp)` → `RetryAfter`/`SuggestedFingerprint`/`RotateSNI`/`Failover`; `NoteRotation`.
4. Core-dial'ы — через `HandshakeLimiter.Acquire`. 5. Пул SNI — из дестов после `probe.CheckDest`.

## 3. Сложность / эффект / риски

| # | Сложность | Эффект | Риски |
|---|-----------|--------|-------|
| 2.1 | Низкая | 3 из 4 векторов «ошибок деплоя» видны до коннекта | Варнинг ≠ запрет (UI: опциональный hard-block) |
| 2.2 | Низкая | Убран ложный конфиг; честное разделение vision/mux | Под vision без XHTTP параллелизм — только детектор+пул |
| 2.3 | Низкая | Главный структурный фикс T007 | Битый mux на сервере → `Options.Mux.Disabled` |
| 2.4 | Средняя | Политика вместо гадания | Два детектора — нужен один владелец политики |

## 4. UI-контракт (Dart; только спека)

- Коды `RealityWarnings()` → локализация; `reality-without-vision` — варнинг + кнопка
  «Включить vision» + опция hard-block (default off).
- Ошибки `ValidateReality()` — красным на импорте, коннект не стартует.
- Заморозка: «Сеть замораживает направление, пауза 2 мин…» (не «сервер мёртв»).

## 5. Хуки в грязных файлах (не вошли в коммит — применить после стабилизации дерева)

- `core/engine/plan.go`: поле `Options.Mux MuxOptions`.
- `core/engine/validate.go`: `o.RealityWarnings()` в `Warnings()`; `o.ValidateReality()` в `Validate()`.
- `core/engine/xray/render.go`: mux-блок (кроме vision), spiderX дефолт `"/"` (2 места).
- `core/engine/singbox/render.go`: `multiplex`-блок.
- `core/engine/mihomo/{proxy,render}.go`: `buildProxy(o, mux)`, `px.Smux`.
- Тесты: `TestRenderRealityMux`, `TestRenderRealitySpiderXDefault` (xray);
  `TestRenderMultiplexDefaultsToReality` (singbox; заменяет устаревший
  `TestRenderNeverEmitsMultiplex` — посылка «у плана нет mux-knob» неверна);
  `TestBuildProxyRealitySmux` (mihomo).

## 6. Честные ограничения

1. Популярность деста офлайн не проверяется (только структура) — решение оператора.
2. SNI↔ASN кросс-чек требует ASN-таблицы — follow-up (`core/profiles/asn.go`).
3. Mux не покрывает dial'ы движков; `Disabled` возвращает триггер — сказано в доке.
4. Whitelist (T004) mux'ом не лечится — отдельная стратегия (файл 04).
5. В ходе работы мои файлы трижды удалялись из working tree (восстановлены, закоммичены);
   hunks в `plan.go` один раз затирались параллельной правкой. Коммиты — только по
   race-free рецепту из AGENTS.md.
