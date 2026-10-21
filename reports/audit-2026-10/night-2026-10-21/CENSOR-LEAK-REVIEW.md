# CENSOR-LEAK — независимое ревью (CENSOR-LEAK-REVIEW)

Ревьюер: независимый подотдел CENSOR-LEAK-review. Ветка
`bugfix/audit-2026-10-19`, репозиторий `~/workspace/bug-hunt/sora`.
Режим: только чтение/тесты/фузз; код не правился; мутация — только в
копии дерева в `~/workspace/.build-tmp/` (удалена после работы).
Объект: `bf0bf820`, `c15558d6`, `cb1038a4`, `ff2a4a2b`, `bcd6015b` +
ханки в `3d506606`. Все шесть коммитов — предки HEAD (`8cdd9fd2`),
проверено `git merge-base --is-ancestor` для каждого.

**Итоговый вердикт: ПРИНЯТЬ С ЗАМЕЧАНИЯМИ.** Утечек уровня High не
найдено; класс редактора в основной массе действительно закрыт.
Замечания: 1× Medium (фузз-инвариант редактора падает
детерминированно), 1× Medium-Low (seeded hex в верхнем регистре),
остальное — Low. Пункт 7 чек-листа как заявлен — отклонить.

## Сводная таблица вердиктов

| # | Пункт | Вердикт |
|---|---|---|
| 1 | Редактор — класс, а не векторы | ПРИНЯТЬ С ЗАМЕЧАНИЯМИ |
| 2 | Лог-сайты и словарь логов | ПРИНЯТЬ С ЗАМЕЧАНИЯМИ |
| 3 | Obfs fail-closed | ПРИНЯТЬ |
| 4 | Переходы (guard) | ПРИНЯТЬ |
| 5 | Эскалация E1 (Xray DNS `+local`) | Автор прав: это дефект (несогласованная семантика), не ошибка отчёта |
| 6 | Мелочи (DNS-размеры, детерминизм, границы) | ПРИНЯТЬ |
| 7 | Фузз | ОТКЛОНИТЬ (как заявлен в отчёте автора) |

## Утверждение про коммит соседа `3d506606` — ПОДТВЕРЖДЕНО поимённо

В HEAD присутствуют все ханки маскировки bypass, приписанные автором
коммиту соседа: `Engine.mask` (`core/engine/bypass/bypass.go:454`) и
вызовы `e.mask(...)` на **четырёх** сайтах — `bypass.go:427` (tpws
keep), `bypass.go:486` (logLine), `nfqws.go:72` (sweep),
`nfqws.go:308` (nfqws keepFilter). Потерь ноль; в HEAD даже на один
сайт больше, чем «три» из текста отчёта.

## 1. Редактор — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

Свои усиленные векторы гонялись отдельным пробным тестом в копии
дерева (файлы сверены с HEAD: `redact.go`, `redact_corpus_test.go`,
`profile.go`, `validate.go` идентичны). Подтверждено замаскировано:

- percent в обоих регистрах (`%2F`/`%2f`), base64 все 4 формы
  (std/url × padded/raw), hex lowercase, JSON-escape в форме Go
  `json.Marshal` — для зарегистрированного сида;
- escaped quotes в обоих видах кавычек: `token: "a \"quoted\"
  tailword"`, `'a \'quoted\' tailwordABC'` — хвост не утекает;
- составные ключи: `access-token`, `access_token`, `accessToken`
  (camelCase), `Pre-Shared-Key`, `pre_shared_key`, `X-Api-Key`;
- `/sub/<token>` от корня (вкл. порт `:8443`, `SUB` в верхнем
  регистре, query после токена);
- `Authorization: Token/Bearer/Basic`, в т.ч. с `=` и в нижнем
  регистре;
- идентификаторы назначения в структурах: `"sni": …`,
  `server-name:`, `serverName=`, `serviceName:`, `"host": …`,
  `host=`, query `?key=&code=&session=`, `uuid:`, `encryption:`;
- нормализация ключей профилей действительно питает маскировку на
  всех сайтах: `Pre_Shared_Key`/`ACCESS_TOKEN`/`uuid`/`encryption`
  извлекаются `profileSecrets` (нормализация lower + снятие `_`/`-`,
  `profile.go`), `address`/`serverNames`/`dest`/`host` —
  `profileIdentifiers`; собранный из `Outbound.Secrets()+Identifiers()`
  редактор замаскировал все 8 проверочных значений в «логовой» строке.
  Транспорт (path/headers → Secrets, host/service/authority/download →
  Identifiers) подтверждён авторским `TestOutboundTransportSecretsCorpus`
  (зелёный в моём прогоне);
- ложные срабатывания на обычной прозе пин НЕ перетянул: мои
  `status code 200, session expired…`, `the host is down, retrying
  the key exchange`, `user agent… login failed`, `bearer of good
  news`, `the service is down and the host unreachable` — без
  изменений. Плата strict-кольца видна только на прозе с явным
  присваиванием (`code: 200`, `host: localhost`, `session: expired`
  маскируются) — это осознанный контракт автора, не регрессия.

Замечания:

- **[Medium-Low] Hex в ВЕРХНЕМ регистре не маскируется.**
  `core/engine/redact.go`, `derivedForms`: добавляется только
  `hex.EncodeToString` (lowercase). Доказательство: сид
  `p@ss word/1234+&`, вход `x <HEX-UPPER> y` → выход содержит сид в
  uppercase-hex целиком (`contains=true`), lowercase-форма при этом
  маскируется. Таблица §1 отчёта обещает «hex» без оговорки о регистре.
- **[Low] Per-char JSON `\uXXXX` не маскируется.** `derivedForms`
  добавляет только результат `json.Marshal` целиком ( `\"`, `\\`,
  `\u003c`…), но не `\uXXXX`-эскейп обычных букв: сид `mysecret1234`
  во входах `mysecr\u0065t1234` и полностью-\u-экранированной форме
  утекает в обоих случаях. Формулировка отчёта «JSON `\uXXXX`» шире
  реализации.
- **[Low] Полное percent-кодирование не маскируется**: сид, где
  закодирован каждый байт (`%70%40%73%73…`), утекает; `derivedForms`
  кодирует только спецсимволы (Query/PathEscape). Экзотический
  энкодер, но «класс» в отчёте заявлен без этого ограничения.
- **[Low] Вложенный префикс перед `/sub/`**: `subscriptionPathPattern`
  требует сегмент сразу после хоста; `https://h.example/api/v1/sub/<token>`
  и `/api/sub/<token>` утекают в pattern-пути (seeded-путь URL
  подписки как целого это не покрывает — в логе URL чужих движков
  сидом не является).
- **[Low, by design — зафиксировано]** Pattern-путь (fallback
  bypass, ext Notify) не маскирует идентификаторы назначения в прозе
  без `:`/`=` (`…sni secret-sni.example via…`, `traffic to dest …`)
  и `hwid <значение>` с пробелом; seeded-путь известные значения
  покрывает. `Authorization: Digest … response=…` не маскируется
  (автором не заявлялся).

## 2. Лог-сайты — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- Редактор реально на пути вывода: `grep` по пакетам
  `engine/bypass`, `engine/supervise`, `control/exthost.go`,
  `obfs` — ни одного `fmt.Print`/`log.Print`/прямого `logs.Write`
  в обход: supervisor — все `logs.Write` через `s.redactor.String/Err`
  (Validate `supervisor.go:270`, logLine `:472`, watch `:562-565,606`,
  Unroute `:655`); c15558d6 добавляет `Add(p.Identifiers()...)` в
  Validate и Apply — на месте. Bypass — все 4 сайта через `e.mask`
  (см. выше), уровни — `bypassLineLevel` из ff2a4a2b. Ext Notify
  (bcd6015b) — `engine.NewRedactor().String` перед `logs.Write`
  (`exthost.go:116-117`).
- Словарь vs код, выборочно построчно сверено 9 сайтов из 20:
  #1, #2, #3/#4 (watch: фикс. текст + `Last(8)` через редактор),
  #7, #8, #9, #10, #11/#12 (session/censor: шаблоны `censorship
  check: <Explanation>`/`network mode: …`, наружу — `toWireEvent`
  с сессионным редактором, `control/server.go:990`), #13, #14,
  #15, #17, #18 (main: slog Warn `core: stale firewall cleanup
  failed` — на месте), #20 (subscriptions: только `id=`, URL нет).
  Совпадают по шаблону, уровню и редакции.
- **[Low] Словарь, сайт #16 описан неточно**: в коде это не
  `logs.Write` уровня Warning из NewServer, а сохранённый
  `obfsLoadWarning` (`control/server.go:298-301`), который всплывает
  notice-строкой в журнал сессии при Connect (`server.go:602,625`).
  Суть («содержимого профиля в тексте нет» — сообщения фиксированные,
  `control/obfs.go:532,539`) верна, канал и уровень в словаре —
  нет.

## 3. Obfs fail-closed — ПРИНЯТЬ

- Код HEAD (`core/obfs/conn.go:29-58`): ошибка Rewrite → `return 0,
  error`, ошибка Split → `return 0, error`; исходный hello не
  отправляется ни в одной из веток.
- Тесты настоящие, не моки: `TestWrapConnFailsClosedOnRewriteError`,
  `…OnSplitError`, `TestWrapConnNoSNIPassesThrough`
  (`conn_test.go:230,252,271`) используют реальный `net.Pipe` и
  проверяют, что peer не получает байт (чтение с дедлайном). Весь
  пакет `obfs` в моём прогоне зелёный.
- Исключение `errNoServerName` обосновано: `findServerNameExt`
  (`sni.go`) возвращает sentinel только после полной валидации
  длин и обхода всех расширений, ни одно из которых не имеет тип 0;
  hello С server_name возвращает найденное расширение, обрезанный/
  битый hello с SNI даёт другие ошибки (truncated/mismatch) и
  уходит в fail-closed. Ветка с наличием SNI недостижима.
- Мутация (копия в /tmp): обе ветки возвращены к старому поведению
  (rewrite → оригинал, split → hello целиком). Тесты на мутации
  **не проходят**: синхронный `Write` в `net.Pipe` блокируется на
  отправке оригинала (процесс теста убит по истечении ~517 с, до
  `go test`-таймаута не доводил). Форма отличия — зависание, а не
  чистый FAIL: тест различает старое/новое поведение, но против
  старого кода даёт timeout, не assertion. Замечание к форме теста,
  не к фиксу.
- **[Low, наблюдение вне заявленных веток]** `fragConn.Write`
  (`conn.go:22-25`): буфер, который `parseTLSRecords` не разобрал
  или без ClientHello, проходит насквозь без изменений — это
  дословный дизайн для не-TLS данных; hello, разрезанный вызывающим
  на два Write, обфускацию не получит. TLS-стеки пишут hello одним
  Write, риск теоретический; в отчёте автора этот путь не упомянут.

## 4. Переходы — ПРИНЯТЬ

- `CleanupStale` чистит ОБЕ таблицы: `guard/ingress.go:283+` —
  inner `CleanupStale` + проба ingress-бэкенда **по платформе**
  (`backend.armed`), `disarm` при наличии таблицы; ошибка бэкенда
  не маскирует inner-результат (`errors.Join`). Тест настоящий:
  `TestIngressCleanupStaleRemovesBothTables`
  (`ingress_linux_test.go:394`) — fake-nft это shell-скрипт-субпроцесс
  с файловым состоянием таблиц, не мок собственных интерфейсов;
  в моём прогоне PASS, включая идемпотентный второй вызов.
- Выборочно проверены 3 перехода из таблицы §3–4 отчёта:
  1. **Hold на переключении** — `session/manager.go` Connect: hold
     берётся до `previous.Stop`, ошибка hold = отказ переключения
     со старым туннелем живым, release после старта новой/отката,
     deferred-release при панике. Соответствует.
  2. **Атомарный Arm** — `guard/nftables_linux.go:94+`: один
     nft-батч `NftReplace` (delete+add одной транзакцией), fallback
     на чистый ruleset только при missing-table. Соответствует.
  3. **Postremove** — это nfpm: `packaging/linux/nfpm.yaml:80`
     подключает `packaging/linux/scripts/postremove.sh`, который
     снимает все три таблицы (`sora`, `sora_nfqws`, `sora_ingress`),
     purge — плюс `/var/lib/sora`. Соответствует.
- E4 (main: Warn + продолжение при ошибке CleanupStale) автором
  честно эскалирован и в HEAD не исправлен (`cmd/sora-core/main.go:250`)
  — не дефект этого набора коммитов, остаётся открытым решением.

## 5. Эскалация E1 — автор прав; вердикт: ДЕФЕКТ (не ошибка отчёта)

По коду HEAD, `core/engine/xray/render.go:735-769` (`dns()`):

- комментарий рендера дословно: «Proxy-only DNS follows routing;
  other resolvers use direct "+local" dialing»;
- `local := "+local"`, снимается только при `s.ProxyOnly`;
- `+local` применяется к `DNSTCP` (`tcp+local://`), `DNSHTTPS`
  (`https+local://…/dns-query`), `DNSQUIC` (`quic+local://`);
- `DNSPlain` пишется голым адресом, `DNSTLS` — `tls://` без
  `+local`, т.е. в routed-режиме Xray (через правила маршрутизации,
  не гарантированно «через туннель» — зависит от финального правила
  плана; оговорка к слову «через туннель» в отчёте, сути не меняет).

То есть Xray-рендер действительно пишет tcp/https/quic не-ProxyOnly
резолверы как direct. Расхождение движков подтверждается и по
соседним рендерам: sing-box — `detour` только для ProxyOnly
(`singbox/render.go:828`), mihomo — не-ProxyOnly резолверы попадают
в direct-бакет/`Nameserver` (`mihomo/rules.go:233-239`). Это
осознанно записанная в коде, но несогласованная между движками
семантика «DNS мимо туннеля по умолчанию» — дефект политики,
эскалация E1 обоснована; рендеры в этом наборе коммитов не правились
и правильно не правились (чужая зона).

## 6. Мелочи — ПРИНЯТЬ

- **DNS-размеры по RFC 1035**: буферы поименованы —
  `dnsMaxUDPMessage = 512` с ссылкой на §2.3.4 в обоих местах
  (`diagnostics/dnsintercept.go:341`, `leak/leak.go:91`); TCP-ответ
  в `queryDNSWire` читается по length-префиксу §4.2.2 полностью:
  `io.ReadFull` префикса, затем `io.ReadFull` ровно Uint16 байт
  (`dnsintercept.go:~326-335`). Магические 4096 одним Read убраны
  именно там, где указал автор. Пакеты diagnostics и leak зелёны.
- **Детерминизм profileWalk**: ключи обходятся в сортированном
  порядке (`profile.go`, ff2a4a2b); `TestProfileExtractionDeterministic`
  — настоящий тест: 32 прогона со сравнением `Secrets()`/`Identifiers()`
  (`redact_corpus_test.go:263+`), в моём прогоне PASS.
- **Граничные векторы в тестах, а не в отчёте**: `TestRedactorBoundaryVectors`
  (`redact_corpus_test.go:208+`) содержит сиды 0/1 (никогда не
  маскируются), 3 (ниже пола — выживает), 4 (первый маскируемый),
  bearer 11 (выживает) / 12 (маскируется), сид с разделителями,
  многострочные случаи. Весь набор engine-тестов редактора/профиля
  в моём прогоне зелёный.

## 7. Фузз — ОТКЛОНИТЬ (как заявлен)

- `FuzzParseLink`: мой перепрогон 10–12 с — PASS (2 594 execs),
  крашей нет.
- **[Medium] `FuzzRedactorNoPanicAndIdempotent` падает
  детерминированно.** Перепрогон 10 с нашёл падающий инпут за
  ~4.8 с / 393 execs (корпус кэша фуззера — 81 базовый сид).
  Инпут: `token  ""0` → `maskPatterns` неидемпотентен:
  once = `token  [masked]0`, twice = `token  [masked]`
  (`redact_corpus_test.go:196`). Воспроизводится как обычный юнит
  по корпусному файлу (`go test -run FuzzRedactorNoPanicAndIdempotent`
  → FAIL). Паники нет и утечки нет (второй проход маскирует больше),
  но: (а) утверждение отчёта «45 с, 66 538 execs, крашей нет» моим
  перепрогоном не воспроизвелось; (б) с этим корпусным файлом в
  `testdata/` обычный `go test ./engine/` становится красным —
  инвариант таргета сильнее паттернов (пустое кавыченное значение
  + суффикс). Нужен фикс паттерна или ослабление инварианта и
  коммит корпуса.
- **Сид-корпуса**: в HEAD закоммичены только inline-сиды `f.Add`
  (Redactor — 9, ParseLink — 1, Detect — 1); файлов
  `testdata/fuzz/**` в HEAD нет ни для одного таргета. Найденный
  падающий инпут в HEAD не закоммичен.

## Что не проверено

- Живой nft/ядро в песочнице недоступны (как и у автора): переходы
  §4 — по коду и fake-nft харнесу, не на живом трафике.
- Полный `go test ./...`: HEAD-дерево само по себе не собирается
  без грязного ворктри соседних отделов (в чистом worktree HEAD
  `core/engine` ссылается на отсутствующие символы соседей);
  прогоны делались в полной копии рабочего дерева, релевантные
  файлы которой побитно равны HEAD (сверено diff по redact.go,
  corpus-тесту, obfs/conn.go, guard/ingress.go). Чужие in-flight
  падения в копии (например, появившийся mid-run
  `xhttp_censor_test.go` без своей реализации) к этому набору
  не относятся.
- Legacy-расхождения (§1 отчёта, E5) не перепроверялись — вне
  чек-листа этого ревью.
