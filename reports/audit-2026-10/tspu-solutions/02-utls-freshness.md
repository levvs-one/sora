# 02. uTLS freshness: UI-выбор фингерпринта, авто-fallback, мониторинг, PQ-политика

Дата: 2026-10-20. Пучок: T001 (Critical, TSPU-ANALYSIS.md; исследование: `reports/web-research/26-utls-fingerprints.md`).
Статус кода: ядро сделано коммитами `[tspu-fix]` (см. §2). Эта спека — крупное: UI, авто-fallback при TLS-timeout, процесс мониторинга свежести, PQ-политика, честные ограничения.

## 1. Проблема

- Дефолтный `chrome`-фингерпринт резолвится в `utls.HelloChrome_Auto` — то есть в **тот Chrome, который знает вендоренный uTLS**, а не в актуальный. До bump'а это был Chrome 133, который ТСПУ детектит и блокирует (полевое подтверждение Xray-core #7131: таймаут 8426 мс против 733 мс у Chrome 155).
- sora выбирает фингерпринт тремя независимыми путями (подписка `fp=` → парсер → план; дефолт рендера для REALITY; obfs-профиль для собственных handshake'ов ядра) — ни один не проверяет свежесть.
- Пользователь не может выбрать фингерпринт в UI и не узнаёт, что его блокирует именно протухший ClientHello: в диагностике это было невидимо.
- Randomized-фингерпринты вредны (консенсус 2025–2026: точная имитация популярного браузера эффективнее; JA4 устойчив к рандомизации), но ничто не мешало их выбрать как «антидетект».
- Отсутствие X25519MLKEM768 при «свежем Chrome» — противоречие, видимое DPI до HTTP (90%+ реального Chrome-трафика 2026 его имеет).

## 2. Что уже сделано (код, коммиты `[tspu-fix]`)

| Изменение | Файлы |
|---|---|
| Bump `github.com/refraction-networking/utls` v1.8.2 → v1.8.3-0.20261006222701: `HelloChrome_Auto` = **HelloChrome_155** | `core/go.mod`, `core/go.sum` |
| JA4 self-test: захват реального ClientHello (локальный pipe, без сети), парсинг, вычисление JA4 строго по референсной реализации FoxIO (сортировка, GREASE strip, sigAlgs в хэше, версия = max non-GREASE) | `core/diagnostics/ja4.go` |
| Эмпирическая верификация: вычисленный JA4 побайтово совпал с полевыми замерами (`t13d1516h2_8daaf6152771_d8a2da3f94cd` для 133; `t13d1517h2_8daaf6152771_cb7bf5808d99` для 155). По ходу найден и исправлен баг: GREASE в signature_algorithms делал JA4 недетерминированным | `core/diagnostics/ja4.go`, тесты |
| CI freshness gate: `TestCoreUTLSFreshnessGate` падает, пока вендоренный uTLS не знает текущий Chrome; обновление референса = документированная процедура | `core/diagnostics/ja4_test.go` |
| PQ regression guard: `TestJA4PQKeyShare` — граница Chrome 131 (есть X25519MLKEM768) vs 120 (нет) | `core/diagnostics/ja4_test.go` |
| База знаний свежести: `IsStaleParrot`, `HasPQKeyShare`, `IsRandomizedFingerprint`, `ParrotVersion`, `ReferenceChromeJA4`, `DefaultXrayFingerprint="hellochrome_auto"` | `core/engine/fingerprint.go` |
| Рендеры используют константы вместо захардкоженного `"chrome"` | `core/engine/{xray,singbox}/render.go` |
| Stealth-находки: `tls/fp-stale` (High), `tls/no-pq-keyshare` (Medium), `tls/fp-randomized` (Low); убран вредный совет «such as chrome» | `core/engine/stealth/` |

## 3. UI-выбор фингерпринта (бэклог: нужен Dart SDK)

Текущее состояние: фингерпринт per-server приходит из подписки (`fp=` → `parser` → `OutboundSpec.Fingerprint` → `control/plan.go:562` → `plan.Outbound.TLS.Fingerprint`). UI-переопределения нет. Obfs-профиль (`UtlsProfile`: chrome/firefox/safari/randomized) относится только к собственным handshake'ам ядра (пробы, DoH, подписки), не к серверным.

Дизайн:
1. **Прото**: добавить `fingerprint_override` в per-server конфиг (слой subscription override, F6). Пустое = «как в подписке»; значение пишется в `Outbound.TLS.Fingerprint` поверх спарсенного, до рендера. Валидация имени — через `engine.NormalizeFingerprint` + `IsKnownFingerprint`/`IsVersionedParrot`; предупреждение — через `FingerprintWarning` (уже различает stale/engine-specific).
2. **UI (Dart)**: в редакторе сервера дропдаун «TLS fingerprint»: Auto (дефолт), Chrome (fresh), Firefox, Safari, iOS, Edge, QQ, 360, Android + «Custom (Xray versioned)» с текстовым полем. У stale-вариантов — бейдж «устарел, блокируется» (данные — из таблицы `engine`, §2; пока нет control-API — захардкоженный список в Dart с комментарием «синхронизировать с `core/engine/fingerprint.go`»).
3. **Control API (следующий шаг)**: `ListFingerprints() → [{name, label, pq, stale, note}]` из `engine`-таблицы, чтобы UI не дрейфовал. Без этого — честное ограничение §6.

## 4. Авто-fallback при TLS-timeout (бэклог: session/control)

Текущее состояние: `core/session/censor.go` (`censorshipWatcher`) только диагностирует (публикует вердикт в журнал), план не мутирует.

Дизайн:
1. Триггер: вердикт класса TLS-timeout/handshake-timeout на outbound с TLS-фингерпринтом → кандидат на ротацию.
2. Порядок ротации — по полевым данным, а не по алфавиту: «сибирская» заморозка бьёт по Chrome/Safari/iOS, проходят Firefox/Edge/QQ/Android. Ротация: `hellochrome_auto → hellofirefox_auto → helloedge_auto → helloqq_auto`. Никогда не ротировать в `random`/`randomized` (вредно, §1) и в pinned старые версии.
3. Запрет ротации во время активной заморозки (T007): backoff ≥120 с после распознанного фриза; ротация в это окно только сжигает следующий фингерпринт в тот же флаг (subnet, SNI). Политикой владеет трекер `core/censor/siberian.go` — fallback спрашивает у него разрешения.
4. Механизм: `control.RotateFingerprint(serverID)` → перерендер плана → рестарт движка. Новый журнал-событийный тип «fingerprint-rotated(reason, old→new)». Лимит: ≤3 ротаций/час на сервер; пользовательский тумблер «стабильный фингерпринт» (для нецензурированных сетей ротация — лишний шум).
5. UI-индикатор: «фингерпринт сменён автоматически (TLS-timeout) — текущий: Firefox».

## 5. Процесс мониторинга свежести (г)

1. **CI**: `TestCoreUTLSFreshnessGate` — падает, когда вендоренный uTLS отстаёт. Падение = сигнал к bump'у, а не «починить тест».
2. **Каденция — МЕСЯЧНАЯ (T050, с 2026-10-20).** Chrome выпускает milestone примерно раз в 2 недели (155 stable — 06.10.2026, 156 ожидается к концу октября): квартальная каденция давала stale-parrot окно до 3 месяцев, за которые реальный Chrome уходит на 4–6 версий. **engines.lock**: раз в месяц (и на каждый релиз Xray/sing-box/mihomo) проверять: какой utls вендорит pinned-билд (читать `go.mod` тега релиза). Критерий: дата utls ≥ коммита `CurrentChromeParrot`. Процедура — чеклист в OWNER-PLAYBOOK.md (владелец).
3. **research-watch**: следить за `refraction-networking/utls` master (новые `HelloChrome_*`/`HelloFirefox_*`) и Xray-core релизами (их utls-bump'ы). Источник истины для «что сейчас шлёт реальный Chrome» — каталог ClientHello (crawlex) + полевые замеры JA4. **Авто-алерт на Chrome N+1**: подписка на chromereleases (GoogleChromeReleases блог) + CI-скрипт, который парсит последнюю stable-версию и сравнивает с `engine.CurrentChromeVersion`; расхождение = задача «проверить utls/parrot» без ожидания месячного ревью. Скрипт ещё не написан (задача CI-владельца) — до него работает рантайм-механизм п. 6.
4. **Обновление референсов** при новом Chrome (напр. 156): `engine.CurrentChromeParrot` + `engine.ReferenceChromeJA4` + `wantJA4` в gate-тесте + `knownGoodJA4` в диагностике — одним коммитом. Падение gate-теста до обновления — задуманное поведение.
5. **Xray в engines.lock**: bump бинарника — релиз-инжиниринг (скачать, сверить sha256, прогнать тесты движков per `core/README.md`), не кодовый коммит. Владелец.
6. **Рантайм-напоминание (внедрено, T050)**: `engine.ParrotReviewOverdue(now)` + `engine.ParrotReviewedAt` (дата последней сверки знаний в `fingerprint.go`); при просрочке > 30 дней каждый Connect добавляет в журнал сессии notice «fingerprint review overdue» (`control/parrotReviewNotice`). Просрочка, таким образом, кричит сама; процесс без этого был «квартальный, никто не помнит». При ревью — бамп `ParrotReviewedAt` тем же коммитом, что и `CurrentChromeParrot`.

## 6. PQ-политика (д)

Enforcement — трёхуровневый, потому что sora **не может** инжектить key share в чужой parrot (он сбандлен):
1. Дефолты всегда резолвятся в parrot ≥131 (сейчас — 155): PQ идёт «бесплатно».
2. Stealth `tls/no-pq-keyshare` (Medium) на явный pre-131 parrot.
3. CI `TestJA4PQKeyShare`: если будущий bump уронит X25519MLKEM768 из auto — тест упадёт.

Честно: если цензор начнёт резать сам MLKEM (middlebox intolerance уже наблюдался), ручки «выключить PQ» нет — ответом будет другой parrot, а не хирургия ClientHello.

## 7. Честные ограничения (обязательно в UX и документации)

1. **Байты шлёт движок, не sora.** JA4 self-test измеряет только собственный uTLS ядра. Свежесть движков доказывается `engines.lock` + их release notes, а не измерением — sora не может выполнить их код.
2. **`hellochrome_auto` vs `chrome` в Xray — косметика** (один указатель на `HelloChrome_Auto`); настоящее исправление — bump uTLS. Имя фиксирует намерение «всегда newest verified», а не меняет байты.
3. **Ротация фингерпринта видна как поведение**: несколько handshake'ов с разными JA4 от одного клиента за короткое время — тоже сигнал. Поэтому лимиты и запрет ротации в заморозку.
4. **Никакой фингерпринт не помогает**, если режут по IP/SNI или включён whitelist-режим (T004) — fallback тогда обязан остановиться и сказать это пользователю, а не жечь фингерпринты.
5. UI-список без control-API будет дрейфовать от `engine`-таблицы — пункт 3 §3 закрывает это следующим шагом.

## 8. Сложность / эффект / риски

- **Сложность**: средняя. Ядро готово; UI — дропдаун + прото-поле + валидация; авто-fallback — новый control-метод + стейт-машина ротации + координация с T007-трекером; процесс — чеклисты.
- **Эффект**: high. Устаревший фингерпринт — активная причина блокировки в RU (полевые данные); свежий auto + видимость в диагностике закрывают класс проблем целиком для собственного стека ядра.
- **Риски**:
  - Ложная ротация на плохом Wi-Fi (не цензура) → митигация: вердикт цензора + лимиты + тумблер.
  - Пользователь пинит старый `fp=` в подписке и страдает молча → митигация: stealth-бейдж в UI сервера (T001-код уже даёт данные).
  - Bump uTLS тянет новые зависимости (уже потянул `go-brrr`) → митигация: gate-тест + полный прогон тестов ядра после каждого bump'а.
