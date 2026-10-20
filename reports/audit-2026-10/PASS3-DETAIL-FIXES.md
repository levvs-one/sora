# PASS3-DETAIL-FIXES — отдел охотников за мелочами, проход 3/3

Дата: 2026-10-20. База: sora `1925867e`, sora-legacy `e39fa15`, ветка
`bugfix/audit-2026-10-19`, пуша нет. Все коммиты — temp-index + CAS
(`read-tree` → `apply --cached` → `write-tree` → `commit-tree` →
`update-ref` с old-value), `git diff --cached --stat` проверялся перед
каждым лендингом; bare `git commit` не использовался ни разу.
Итоговые tip'ы после работы отдела: sora — поверх `1925867e` лежат
коммиты роя (`[pass3-tspu]` ×3) и 6 коммитов `[pass3-detail]` ниже;
legacy — `a769346` поверх `e39fa15`.

## Сводная таблица «было → стало → коммит → вектор проверки»

| # | Было | Стало | Коммит | Вектор проверки |
|---|---|---|---|---|
| M1 (sora) | `preshared[_-]?key\|pre-shared-key`: `pre_shared_key: abc123` НЕ маскировался (буквальное имя поля WireGuard в JSON sing-box — утечка в engine-логи); кавыченный `"pre_shared_key": "a b c"` тёк целиком | Alternation заменена на каноническое `pre[_-]?shared[_-]?key` (надмножество, байт-в-байт как в legacy) + комментарий о паритете | sora `7a21763` | Исполнение точных regex до фикса (отдельная Go-программа): sora `pre_shared_key` → без маски, после — `[masked]`; `TestRedactorParityKeySpellings` (новый): 14 ключей × 4 формы (plain/`:`/JSON-quoted/quoted-phrase), включая проверку хвоста `"a b c"`; `go test ./engine/ -run TestRedactor` — зелёный; build+vet `./engine/` |
| M1 (legacy) | `spiderx` без разделителя, `public[_-]?key` отсутствует: `public_key`, `public-key`, `spider_x`, `spider-x` НЕ маскировались | Та же каноническая alternation: добавлен `public[_-]?key`, `spiderx` → `spider[_-]?x`, `psk` выровнен по позиции sora — ключевая alternation теперь идентична в обоих репо | legacy `a769346` | Та же исполняемая сверка regex до/после; тот же `TestRedactorParityKeySpellings`, дословно одинаковый в обоих репо; все legacy `TestRedactor*` зелёные |
| Каталог xmux (deep S1) | `Catalog[KindXray]` заявлял `FeatureXHTTPXmux: true`, но НИ ОДИН рендерер не эмитит xmux/x_padding: Xray xhttp — только mode/path/host/downloadSettings; sing-box — host/path/mode/headers; mihomo — path/host/mode/headers. Доки `FeatureXHTTPXmux` и `plan.go` врали следом («routes away from sing-box/mihomo») | `FeatureXHTTPXmux` снят у Xray (у sing-box/mihomo его и не было) с объясняющим комментарием в стиле соседних entries; доки фичи и полей плана переписаны по факту («no engine claims it; план честно рапортует missing на всех движках»). Парная `FeatureXHTTPDownloadSplit` проверена тем же способом: Xray рендерит `downloadSettings` (`xray/render.go:290`, тест `TestRenderPassesXHTTPDownloadSettings`) — оставлена у Xray, у остальных по-прежнему нет | sora `052cb1a` | Новый `TestCatalogXmuxClaimMatchesRenderers`: (1) никто не заявляет Xmux; (2) xmux-план → `feature xhttp-xmux` в Missing на всех 3 движках; (3) split-план → НЕ missing у Xray, missing у sing-box/mihomo. `go test ./engine/...` (engine, xray, singbox, mihomo, bypass) — зелёные; полный `go build ./...` |
| L1 | `bypass.DefaultStrategy` без прод-вызывающих с F11-фикса `2a1395e6`, но док функции, `core/control/plan.go:448` («the core's built-in default») и `NFQWS-MIGRATION.md` называли его применяемым дефолтом, маркера NOT WIRED не было | Док функции помечен `NOT WIRED: no production caller since the F11 plan-time refusal (2a1395e6)… kept as the reference nfqws set`; plan.go — «reference set … NOT WIRED — no production caller applies it as a default»; NFQWS-MIGRATION.md — «reference strategy … currently NOT WIRED», плюс пометка в Current state. Функция и её тесты сохранены (референсный набор для nfqws-миграции) | sora `fa53c894` | `go test ./engine/bypass/ ./control/` — зелёные; grep: «built-in default» применительно к DefaultStrategy в core/docs не осталось |
| L3 | README.md:58 и docs/security.md:46: «единственное сетевое обращение приложения — обновления», хотя в коде есть app-side `fetchCatalog()` (`app/lib/src/ext/catalog.dart:277`, вызывается при открытии магазина расширений) | Оба места честно называют два обращения: обновления GitHub + запрос каталога при открытии магазина; в обоих местах сказано, что адрес каталога — заглушка `extensions.sora.example` (не резолвится), поэтому до настройки настоящего endpoint запрос фактически никуда не уходит. Без завышения (не «уже ходит») и занижения (путь в коде назван) | sora `dc7c00cc` | Сверка текста с кодом: `defaultCatalogUrl = 'https://extensions.sora.example/v1/catalog.json'` (catalog.dart:23), `fetchCatalog` — прямой `package:http` из Dart-процесса |
| L4 (тривиальный Low из PASS3-ANALYSIS, зона docs/) | docs/extensions.md:285: «neither the app nor the service — schedules workers yet» — буквально неверно: служба создаёт и стартует Scheduler | «the service creates and starts the scheduler at startup — but no worker tasks are registered with it yet and there is no JS executor…» | sora `656eaa65` | Код: `core/cmd/sora-core/main.go:355` `ext.NewScheduler(nil)`, `:584` `extSched.Start(ctx)`, регистрация задач отсутствует |
| Toolchain (web S4) | sora `core/go.mod`: `go 1.27` без пина — сборка плавала на 1.27.0/1.27.1 со всеми 15 stdlib-CVE, закрытыми в Go 1.27.2 (2026-10-08); `tools/sora-ext/go.mod` — то же | `toolchain go1.27.2` добавлен в core и tools/sora-ext. Legacy core и service/sync проверены: их директива уже `go 1.26.9` — security-патч линии 1.26; явная строка `toolchain go1.26.9` там НЕ tidy-стабильна (проверено: `go mod tidy` её сносит и без неё `go build` требует tidy), поэтому оставлены как есть — пин у них несёт сама директива `go` | sora `62c818ad` | `go version` в core после пина: `go1.27.2` (переключение на кэшированный тулчейн); `go build ./...` зелёный во всех 4 модулях (core, tools, sync, legacy); `go mod tidy` в core/tools — без диффа (пин tidy-стабилен); тесты: sora `engine/...`, sync `./...`, tools `./...`, legacy `TestRedactor*` — зелёные |

## Что НЕ сделано — спеки остатка

- **S1, рендерная часть (xmux/x_padding):** каталог больше не врёт, но
  сами поля всё ещё не рендерит никто. Спека — PASS3-DEEP-RESEARCH S1
  пп. 2–4: Xray xhttp-кейс += `xmux` (maxConcurrency/maxConnections/
  cMaxReuseTimes/maxRequestTimes), `xPaddingBytes`, `headers`; lx —
  `x_padding_bytes`/`xmux`; mihomo — `reuse-settings`/`x-padding-bytes`
  (A1); парсер поднимает xmux-ключи из `extra=`. После рендера и
  `xray run -test` на пине — вернуть фичу в каталог тем движкам, где
  рендер реально есть.
- **XPaddingBytes без гейта (попутная находка этого прохода):**
  `RequiredFeatures()` (`core/engine/refs.go`) включает
  `FeatureXHTTPXmux` только по Xmux-полям; план с одним лишь
  `XPaddingBytes` нигде не гейтится и молча теряет пэддинг на всех
  движках. Док поля в plan.go приведён к правде (коммит `052cb1a`),
  поведение не менялось. Спека: либо отдельная фича
  `FeatureXHTTPPadding`, либо включение `XPaddingBytes != ""` в тот же
  гейт — решение за владельцем каталога, т.к. меняет UX-текст Missing.
- **L2 (ext Go-половина, 76 недостижимых):** только owner-решение п. 6
  (JS-исполнитель / Go-хост). Новых обманов нет, спека не требуется.
- **L5 (guard strictWanted комментарий):** вне зон этого отдела
  (core/guard не в списке разрешённых). Спека PASS3-ANALYSIS в силе:
  одна правка комментария `strictWanted` (mode.go:86-88) — вызывающих у
  Guard.reconcile/strictIntent нет, стартап зовёт только CleanupStale.
- **L6 (MinSupportedMinor: Go 1 vs Dart 6):** зоны core/cmd + app/lib
  вне отдела. Спека прежняя: один источник правды или тест паритета
  трёх чисел (major, minor, minSupportedMinor).
- **L7 (дубли itoa ×5, largePlan ×3, toWire ×2 и пр.):** консолидация
  затрагивает пакеты вне зон (probe/censor — зона ТСПУ-отдела);
  как «тривиальный и безопасный» не квалифицируется. Без изменений.
- **L8 (RPC без Dart-клиента ≈21/54)** и **L9 (sync log.Printf ×3):**
  L8 — owner-очередь; L9 — код service/sync вне зон отдела (разрешён
  был только его go.mod). Без изменений.
- **L10 (untracked мусор: core/sora-core, service/sync/sora-sync.exe,
  __pycache__, subscriptions.go.309…):** не коммитился и не удалялся —
  часть артефактов может принадлежать параллельным отделам.

## Инциденты (git-дисциплина)

Источник — параллельный отдел(ы) на той же ветке: их рабочее дерево
основано на более старом HEAD, и они стадят свой снапшот в ОБЩИЙ
главный индекс. После каждого моего CAS-лендинга остаток их staged-
снапшота читался как реверсия моего последнего коммита. Worktree во
всех случаях был == HEAD, мои коммиты ни разу не пострадали (все
лендинги — temp-index от актуального HEAD, проверка
`git show --stat` после каждого). По протоколу задания каждый раз
выполнен `git restore --staged` по затронутым путям + сверка
`git diff --cached --stat` = пусто:

1. Перед L1: staged-реверсии каталога/xmux (052cb1a) + staged-удаления
   ja4/bandwidth/faq из in-progress работы `[pass3-tspu]` — растворились
   при лендинге их коммитов `4d8a7121`, `6e31bd2d`, `4237ceba`
   (CAS корректно перебазировал L1 поверх них → `fa53c894`).
2. После L1: staged-реверсия L1 (plan.go, bypass.go,
   NFQWS-MIGRATION.md) — `git restore --staged` ×3 пути.
3. После L3/L4: staged-реверсии README/security.md/extensions.md —
   `git restore --staged` ×3 пути.
4. Legacy, после M1: staged-реверсия M1 (redact.go/redact_test.go) —
   `git restore --staged` ×2 пути.
5. После toolchain-коммита: staged-реверсия go.mod ×2 —
   `git restore --staged` ×2 пути.

Рекомендация рою: отделы, работающие на этой ветке, не должны стадить
в главный индекс из снапшота старого HEAD — это ровно механизм
инцидентов PASS2-AUDIT; temp-index + CAS работает и при гонке
(подтверждено пунктом 1: три чужих коммита встали между моими без
потерь с обеих сторон).

## Попутное наблюдение (не регрессия проходов)

Legacy `go test ./engine/` падает на `TestTunAndFakeIPAvoidLANAndEachOther`
(«fake-IP pool overlaps an existing interface») — воспроизводится на
чистом базовом `e39fa15` в отдельном worktree: интерфейс хоста
`host0@if3` = `198.19.0.2/30` попадает в fake-IP диапазон. Пред-
существующий энв-фейл этой VM, к правкам прохода отношения не имеет;
redactor-тесты legacy зелёны полностью.

*Отдел охотников за мелочами, проход 3/3, завершён 2026-10-20.
Коммиты: sora 7a21763 (M1), 052cb1a (xmux-каталог), fa53c894 (L1),
dc7c00cc (L3), 656eaa65 (L4), 62c818ad (toolchain); legacy a769346 (M1).
Пуша нет.*
