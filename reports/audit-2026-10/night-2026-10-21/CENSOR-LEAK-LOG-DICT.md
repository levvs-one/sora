# CENSOR-LEAK — словарь лог-сообщений обфусцирующих путей

Приложение к CENSOR-LEAK.md. Охват: все места в core, куда пишут вывод
обфусцирующих/цензурных путей (supervise, bypass tpws/nfqws, obfs,
censor watcher, guard, leak/dns-диагностика, расширения). Шаблон на
класс событий один; поля «цель/SNI/IP/токен» допустимы только после
редактора; свободный текст движков идёт через Redactor.String всегда.

| # | Источник (source) | Сайт | Шаблон / класс | Уровень | Поля | Редакция |
|---|---|---|---|---|---|---|
| 1 | имя движка (sing-box/xray/mihomo) | supervise logLine | сырая строка движка (её собственный формат) | разбирает driver LogParser (debug/info/warn/error движка) | что напечатал движок | Redactor (seeds **+ identifiers** с коммита c15558d6) |
| 2 | имя движка | supervise Validate/Apply/start failures | `<kind>: …` текст ошибки | Error | текст ошибки | Redactor.Err |
| 3 | имя движка | supervise watch | `engine exited unexpectedly: <process state>` | Error | только состояние процесса | поля нет |
| 4 | имя движка | supervise watch | строки `proc.Output().Last(8/5)` | Error | вывод движка | Redactor.String |
| 5 | имя движка | supervise watch | `more than %d restarts within %s` | (event) StateFailed | числа бюджета | поля-цели нет |
| 6 | имя движка | supervise watch | `restarting in <delay>` | (event) StateRecovering | длительность | поля-цели нет |
| 7 | `zapret` | bypass keep (tpws) | `tpws stopped (%v); starting it again` | Warning | ошибка процесса | e.mask (Redactor внутреннего движка или паттерн-редактор) — коммит 3d506606 |
| 8 | `zapret` | bypass keepFilter (nfqws) | `nfqws stopped (%v); starting it again` | Warning | ошибка процесса | e.mask — 3d506606 |
| 9 | `zapret` | bypass sweep | `nfqws: dropping a stale interception table failed: %v` | Warning | ошибка nft | e.mask — 3d506606 |
| 10 | `zapret` | bypass logLine | сырая строка tpws/nfqws | **классификация bypassLineLevel** (ведущее слово уровня → logs.ParseLevel; иначе error/fatal→Error, warn→Warning, иначе Info) — коммит ff2a4a2b; раньше всегда Info | что напечатал процесс (хосты/SNI desync — его работа) | e.mask — 3d506606 |
| 11 | журнал сессии | session/censor publish | `censorship check: <Explanation>` | EventCensor | Explanation — шаблонные тексты censor-пакета, содержат только публичные canary-имена | журнал; наружу — через control toWireEvent с сессионным редактором |
| 12 | журнал сессии | session/censor shutdown | `network mode: <Explanation>` | EventCensor | то же | то же |
| 13 | журнал сессии | session/deadmode | `dead-mode: the tunnel connected but carries no traffic — …` / `dead-mode cleared: payload flows through the tunnel again` | Error / Log | фиксированный текст, полей нет | не нужны |
| 14 | журнал сессии | session/stall | `the tunnel moved no traffic for %s with %d connections open; reopening flows` | Error | длительность, число соединений | целей нет |
| 15 | журнал сессии | session/network | `the network changed` / `the machine woke from sleep` (+ `; connections reopen`) | Network/Log | фиксированные строки | не нужны |
| 16 | `core` | control NewServer: warn-колбэк loadObfsProfile (`server.go:299-307`) сохраняет текст в `obfsLoadWarning`, пишет его в лог-центр (`logs.Write`, Warning, SourceCore), если центр задан, и тот же сохранённый текст Connect (`server.go:602-603,624-626`) добавляет notice-строкой в журнал сессии (`session.EventLog`) на каждом подключении, пока ApplyObfsProfile не очистит предупреждение (`obfs.go:431`) | два фиксированных шаблона loadObfsProfile: `obfuscation: the stored profile (obfs_profile.json) is corrupt and was ignored; the suite stays disabled until a profile is applied` / тот же с `is invalid` (`control/obfs.go:532,539`) | Warning (лог-центр) + EventLog (журнал сессии) | только имя файла профиля и класс причины (corrupt/invalid), без содержимого профиля | содержимого нет; тексты фиксированные |
| 17 | `ext:<id>` | control exthost Notify | `<title>: <body>` от расширения | Info | текст стороннего расширения | **паттерн-редактор** — коммит bcd6015b; раньше писалось сырым |
| 18 | `core` (slog) | cmd/sora-core main | `core: stale firewall cleanup failed` (err) | Warn | ошибка nft-чистки | цели нет; см. эскалацию E4 в CENSOR-LEAK.md |
| 19 | stdout оператора | cmd/sora-censor-proxy | вердикт + причины по потокам | — (не лог центра) | публичные canary/причины детектора | локальная консоль оператора |
| 20 | `subscription` | control subscriptions/override | `subscription … failed id=<local id>` и т.п. | Warning/Info | только локальный id подписки, без URL | URL не логируется by design; fetch-ошибки — errs.From срезает URL из *url.Error |

Правила словаря (запинены тестами redact_corpus_test.go,
redact_log_test.go, TestBypassLineLevelAgreement):
1. Ни одного нового лог-сайта на обфусцирующих путях без Redactor
   (seeded или, минимум, паттерн-) на пути к logs.Center.
2. Один шаблон на класс: `<процесс> stopped (%v); starting it again`
   для обоих zapret-процессов; `<процесс>: …` для ошибок движков.
3. Уровни: вывод процессов — их собственный/классифицированный
   уровень; падения и отказы — Error; рестарты/деградации — Warning;
   рутина — Info. Debug в обфусцирующих путях не пишется.
