# CENSOR-SURV-FIX — закрытие замечаний ревью CENSOR-SURV-REVIEW

**Дата:** 2026-10-21. **Ветка:** `bugfix/audit-2026-10-19` (sora), строго локально, пуша нет.
**Объект:** замечания из `CENSOR-SURV-REVIEW.md` (вердикт «ПРИНЯТЬ С ЗАМЕЧАНИЯМИ») к коммитам подотдела CENSOR-SURV.
**Дисциплина:** все коммиты — temp-index + CAS (`read-tree HEAD` → `git add -- <paths>` во временный индекс → сверка `git diff --cached --stat` → `commit-tree` → `update-ref` со старым значением); bare `git commit` не использовался, чужие staged/WIP не тронуты. `core/engine/validate.go` (рабочий файл P1, чужие ханки AmneziaWG/SS-plugin) не трогался вообще — блок REALITY живёт в `reality.go`.

## Коммиты (все `[censor]`)

| Хеш | Что |
|---|---|
| `150a29d3` | п.1: ValidateReality по эффективному SNI + пробелы покрытия гигиены REALITY |
| `f23c9eb3` | п.2 + п.4: единый инстанс бюджета рукопожатий; MaskedName без паник/mojibake; маскировка отказа бюджета и DNS-события |
| `62f133c6` | п.3: `-quic-probe` не теряет вердикт при проблемах персистентности BanTracker |
| `86c9c2a2` | п.5: docs/providers.md — убран старый UA `sora-core/1` |

П.6 — правка файлом в `CENSOR-SURV.md` (см. ниже, почему не коммитом).

## 1. [Medium] ValidateReality блокировал не то, что рендерится — ЗАКРЫТО

**Семантика рендеров проверена по всем трём движкам** (не только sing-box):
- sing-box: общий TLS-блок — `server_name = o.TLS.ServerName` (пустой опускается через `obj.set`), naive-путь — явно `orDefault(o.TLS.ServerName, o.Server)`;
- Xray: `realitySettings.serverName = o.TLS.ServerName` дословно;
- mihomo: `sni`/`servername` выставляется только при непустом ServerName; комментарий адаптера в `proxy.go` фиксирует фолбэк на адрес дайла.

Итог: при пустом ServerName каждый движок уносит на провод `o.Server` — эффективное SNI = `realityDest()` (ServerName, иначе Server). Именно оно уже использовалось предупреждениями; блок его не использовал.

**Фикс (`core/engine/reality.go`):** `ValidateReality` валидирует `o.realityDest()`. Вектор ревьюера `Server="my_site.example.com", SNI=""` теперь даёт ошибку (раньше `nil`).

**Пробелы покрытия (все — векторами в новом `core/engine/reality_surv_fix_test.go`):**
- *sni-is-server для parent/subdomain:* сравнение переведено с точного равенства строк на региструемый домен (eTLD+1 через `publicsuffix`, имена предварительно канонизируются в A-label): пары `vpn.example.com`/`www.example.com`, `example.com`/`cdn.example.com`, обратная пара, пара под `co.uk`, IDN-пара — предупреждают; разные региструемые домены (`edge.provider.net` vs `www.example.com`, разные владельцы под `co.uk`) — молчат.
- *not-public суффиксы:* добавлены `.home.arpa` (RFC 8375, включая голый `home.arpa`), `.onion` (RFC 7686), `.localdomain`.
- *Квази-IP `123.456.78`:* `validDNSName` отклоняет имя с полностью цифровым последним лейблом (цифровой TLD не существует, RFC 1123; форма — битый IP-литерал). Следствие: предупреждение `reality-dest-malformed` и блок в ValidateReality; вектор `999.1.2.3` — туда же.
- *U-label IDN:* `validDNSName` сначала конвертирует имя через IDNA (`idna.Lookup.ToASCII`, тот же `golang.org/x/net`, что уже использует `control/plan.go`) и валидирует A-label-форму. `bücher.example.de` и его punycode-форма проходят и не блокируются и не флажатся malformed; мусор (underscore, пробел, wildcard, лейбл с ведущего дефиса) IDNA отклоняет — malformed сохраняется.
- *low-entropy расширен:* новый `lowEntropyShortID` — все байты равны (как было) ИЛИ короткий период, повторяющийся по байтам/по hex-тексту (`abcdabcd…`, `deadbeefdeadbeef…`, тайлинг `aabbccdd…`) ИЛИ известное плейсхолдер-слово в hex (`deadbeef`, `cafebabe`, `feedface`) даже однократно. Взаимоисключение с `reality-shortid-short` сохранено (switch, не пересекаются).
- *Без ложных срабатываний:* CDN-dest из ревью (`cdn.jsdelivr.net`, `www.microsoft.com`) и реальные shortId (`6ba85179e30d`, `6ba85179e30d4fc2`) pinned тестами как чистые.

Доказательство: `go test ./engine/ -run 'Reality|Validate' -count=1` — зелёно; полный `./engine/` — зелёно (см. «Доказательства» ниже).

## 2. [Medium] Два инстанса бюджета HandshakeLimiter — ЗАКРЫТО

Единый источник инстанса: `probe.DefaultHandshakeLimiter` — единственный процессный объект.
- `probe.destHandshakeLimiter` теперь по умолчанию равен ему (тестовый шов подмены сохранён);
- `censor.DefaultHandshakeBudget = probe.DefaultHandshakeLimiter` — та же переменная-объект, не копия и не второй `NewHandshakeLimiter`.

Тест `core/censor/budget_shared_test.go::TestSharedHandshakeBudgetAcrossPaths`: тождество указателей + суммарный кап — 2 слота через censor-путь и 1 через probe-путь на один SNI дают `InFlight=3`, 4-й аквайр через ЛЮБОЙ путь отклоняется. На probe-стороне тождество pinned в `TestDefaultDestLimiterIsTheSharedInstance`. Суммарно >3 параллельных рукопожатий на SNI через оба прод-пути больше невозможно (кастомные лимитеры в тестах/бенчах — не прод-пути).

## 3. [Medium] `-quic-probe` терял вердикт при несуществующем data-dir — ЗАКРЫТО

- `probe.SaveBanTracker` создаёт родительский каталог (`MkdirAll`, 0700): свежий операторский запуск без data-dir — норма, а не ошибка.
- `cmd/sora-core.runQUICProbe` перестроен: вердикт строится и возвращается независимо от сохранения; ошибка записи добавляется строкой `warning: ban tracker was not saved: … (the verdict above is unaffected)`, а не возвращается вместо результата. Утверждение reaction-строки про «файл сохранён» при провале записи заменено честной формой «recorded … for this process».

Тесты (`netcheck_test.go`): `TestRunQUICProbeMissingDataDir` (несуществующий data-dir → вердикт `open` + файл трекера создан) и `TestRunQUICProbeSaveFailureKeepsVerdict` (путь трекера заблокирован каталогом → вердикт `blocked` + warning-строка, `err=nil`). Существующие 4 теста netcheck — зелёны.

## 4. [Мелочи, серьёзно] MaskedName и сырые имена в событиях — ЗАКРЫТО

**MaskedName (`core/probe/freeze.go`) переписан тотально:**
- Паники устранены: пустые лейблы отбрасываются до индексирования; `"."`, `".com"`, `".."`, `".a"` и т.п. дают `"***"`/`"c***"`/`"a***"`, а не `index out of range`. Векторы — `core/probe/maskedname_surv_fix_test.go`: пустая строка, точки, сверхдлинное имя (5000 символов), битый UTF-8 — без паник и без утечки сырых байт.
- Mojibake устранён: видимый первый символ — руна (`utf8.DecodeRuneInString`), `éxample.com → é***.com`, `привет.example.ru → п***.example.ru`; невалидный UTF-8 маскируется плейсхолдером.

**Сырые имена в событиях замаскированы:**
- `probe/budget.go`: `errHandshakeBudgetTimeout.Error()` теперь несёт `MaskedName(sni)` — именно этот текст попадал в `censor.Event.Detail`. Тест: отказ по `secret-host.example.com` содержит `s***.example.com` и не содержит сырого имени.
- `censor/probe.go`: (а) отказ бюджета — Detail из замаскированной ошибки (префикс `handshake budget:` не дублируется); (б) DNS-событие `WhatResolved` — `probe.MaskedName(ip)` вместо сырого IP (дайл по-прежнему идёт по сырому адресу, маскируется только запись).
- Следствие для детектора закрыто честно: `Detector` сравнивал `resolvedTo` с `ExpectedIP` — сравнение сделано mask-aware (`resolvedMismatch` в `censor/detect.go`): замаскированное значение сравнивается по замаскированной форме (первый октет), два сырых — как раньше точно; evidence правила DNS-poisoning печатает только замаскированные формы. Тест `TestDNSPoisoningMaskedResolvedComparison` + сквозной `TestProbeEventsMaskNamesAndUseSharedBudget` (реальный Prober на локальном листенере при насыщенном общем бюджете: DNS-Detail `127.***`, бюджетный отказ замаскирован, сырого `127.0.0.1` нет ни в одном Detail).

**Не входило в замечание и не тронуто:** `DestReport.Issues` в `probe/reality.go` по-прежнему содержат сырой хост/IP явно запрошенной оператором цели (операторская диагностика по своему же вводу — позиция автора CENSOR-SURV §7; ревью отметило расхождение формулировки §7 с фактом, задача фиксера этот пункт не включала).

## 5. [Low] docs/providers.md учил старому UA — ЗАКРЫТО

Строка 29 переписана под фактический контракт: подписка запрашивается обычным браузерным UA из пула (Chrome/Safari/Firefox/Edge), выбор детерминирован по хосту провайдера, самоназывающегося UA нет, панель не должна настраивать формат «по UA Sora»; пользовательский override в настройках подписки упомянут. Поиск по всему `docs/`: других мест со старым UA не было и не осталось (`grep "sora-core/1"` по docs/app/core — пусто; `docs/faq.md` и `docs/security.md` про `Sora/<версия>` для api.github.com — другой, актуальный механизм, не подписки).

## 6. BindNetwork: фактическое состояние (точность отчётности)

Зафиксировано по коду на момент фикса (`grep BindNetwork` по прод-коду и тестам):

| Компонент | API | Прод-вайринг | Тесты |
|---|---|---|---|
| `probe.FreezeDetector` | да | **да** — `cmd/sora-core/main.go`: стартовый бинд + `watchCensorshipNetwork` (поллинг) | да |
| `probe.BanTracker` | да | **нет** — живёт один операторский запуск `-quic-probe`, к сети не биндится | да |
| `censor.SNIPool` | да | **нет** — прод-владельца нет (эскалация Э2 владельца) | да |
| `censor.FreezePolicy` | да | **нет** — прод-владельца нет (эскалация Э1 владельца); внутри делегирует своему детектору, но вызывающего у самой политики в проде нет | да |

Прод-биндинг для последних трёх кодом НЕ выдумывался (это решения владельца Э1/Э2). В `CENSOR-SURV.md` §3 внесено явное уточнение с этой таблицей в текстовой форме. **Не коммитом:** `~/workspace/bug-hunt/reports/` не входит ни в один git-репозиторий (урок AGENTS.md от 2026-10-20 — коммит отчёта оттуда даёт пустой коммит), поэтому «отдельный коммит [censor] docs» для этого файла физически невозможен; правка сделана в файле, факт и причина зафиксированы здесь.

## Доказательства (финальные прогоны в ворктри, Go из `~/workspace/go/bin`, TMPDIR/GOCACHE по дисциплине)

- `go test ./probe/ ./censor/ ./diagnostics/ -count=1` — все зелёны (probe 16.6 с).
- `go test ./cmd/sora-core/ -count=1` — зелёно.
- `go test ./engine/ ./engine/singbox/ ./engine/xray/ ./engine/mihomo/ -count=1` — все зелёны; точечно `-run 'Reality|Validate'` — зелёно.
- `go vet ./probe/ ./censor/ ./diagnostics/ ./engine/ ./cmd/sora-core/` — чисто; `gofmt -l` по всем тронутым файлам — пусто.
- По ходу работы наблюдался провал `TestSelectEngineProbedPrefersFact` (engine, ECH/probecaps): воспроизведён на чистом HEAD-`reality.go` без моих правок — чужая зона WIP; позже закрыт соседями (`288353aa`/`84b35166`), финальный полный прогон engine зелёный.

## Остатки и честные оговорки

1. **Сборка HEAD как закоммиченного дерева** по-прежнему зависит от незакоммиченных символов соседних департаментов (P3/P4 и др.): чистый worktree на HEAD без ворктри-WIP не собирает `engine` (это системное замечание самого ревью, не моя зона). Все прогоны выше — в живом ворктри, где WIP соседей присутствует; мои коммиты лежат поверх движущегося HEAD и каждый проверялся CAS-ом на точном родителе.
2. Dart-сторона: новые/изменённые warning-коды не вводились (состав кодов гигиены тот же), рендер предупреждений в UI не затронут.
3. `DestReport.Issues` с сырым хостом — см. п.4, осознанно вне объёма задачи.
4. Пуш запрещён заданием и не выполнялся; все 4 коммита только локально на `bugfix/audit-2026-10-19`.
