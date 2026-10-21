# CENSOR-LEAK — утечки и безопасность обфусцирующего кода

Подотдел CENSOR-LEAK, ветка bugfix/audit-2026-10-19, строго локально.
Коммиты: **bf0bf820** (редактор: класс), **c15558d6** (supervisor
identifiers + пин bypass), **cb1038a4** (guard: чистка ingress при
старте), **ff2a4a2b** (obfs fail-closed, DNS-размеры по спекам,
детерминизм, уровни логов), **bcd6015b** (уведомления расширений через
редактор). Дополнительно: маскировка вывода bypass (mask/logLine) физически
уехала в коммит соседа **3d506606** — его CAS-коммит подхватил мои грязные
ханки bypass.go/nfqws.go с общего ворктри (инцидент в стиле AGENTS.md,
потерь ноль: наличие в HEAD проверено поимённо — `Engine.mask`,
`e.mask(...)` на всех трёх сайтах).

## 1. Редактор — закрыт класс, а не вектор

История дрейфа (пасс 1 → пасс 3 → волна A) повторялась потому, что пинился
очередной спеллинг. Находки этого прохода — все подтверждены щупом до фикса:

| Вектор | Было | Стало |
|---|---|---|
| Сид в перекодировке | Redactor знал только сырую строку: `p%40ss+word` (query), path-escape, base64 (4 формы), hex, JSON `\uXXXX` уходили в лог целиком | `derivedForms`: все перечисленные формы регистрируются вместе с сидом при сборке Replacer |
| Quoted-значение с escaped quotes | `token: "a \"quoted\" tailword"` → маскировалось только `"a \"`, хвост — в логе | alternation `"(?:\\.|[^"\\])*"` (и для `'`) |
| Голые `key/code/session` в query подписки | `?key=…&code=…&session=…` не маскировались (bare key отсутствовал в alternation) | strict-кольцо: только за `:`/`=` (проза «status code 200», «the host is down» не тронута — запинено) |
| SNI/dest/host/serviceName как идентификаторы назначения | `sni: …`, `dest: …`, `"host": …` не маскировались паттернами вообще | то же strict-кольцо |
| `hwid`, `device_id`, `seed`, `encryption` | не маскировались | strict-кольцо |
| Токен подписки сегментом пути | `https://host/sub/<token>` — ни userinfo, ни ключа | `subscriptionPathPattern` (sub/subscribe/subscription/feed/token/link + сегмент ≥8) |
| `Authorization: Token …` | только Bearer/Basic | + Token |
| Профиль Xray (profileSecrets) | точный спеллинг ключей; `token/uuid/encryption/apikey` отсутствовали; спеллинги вида `Pre_Shared_Key`/`ACCESS_TOKEN` промахивались | нормализация ключа (lower, без `_`/`-`) + расширенный набор |
| Профиль Xray (идентификаторы) | address/serverNames/dest/host профиля **не извлекались никуда** — адрес сервера и REALITY dest профиля не знал ни один редактор | `profileIdentifiers` → `Outbound.Identifiers()` |
| Транспорт | WS/XHTTP path (часто «секретный путь» провайдера) и значения кастомных заголовков не были сидами; Transport.Host/Service/GRPCAuthority/DownloadAddress — не идентификаторы | path+headers → Secrets (ключи заголовков — в сортированном порядке); host/service/authority/download → Identifiers |
| Supervisor | редактор, маскирующий **сырой вывод движков**, регистрировал только Secrets — хосты/SNI/REALITY-параметры в логах движков жили | Validate/Apply: `Add(Identifiers...)` рядом с Secrets |
| bypass logLine | вывод tpws/nfqws (хосты и SNI desync) писался в logs.Center **сырым** | `Engine.mask` (редактор внутреннего движка; fallback — паттерн-редактор) |
| ext Notify | текст сторонних расширений писался в лог сырым | паттерн-редактор (bcd6015b) |

Паритет запинен исполняемым корпусом `core/engine/redact_corpus_test.go`
(классы, не спеллинги): кодировки сидов, strict-кольцо в plain/JSON/query
формах, профиль-корпус, транспорт-корпус, **граничные векторы** и
детерминизм (см. §6). Плюс дифференциальный тест gate-паритета расширен
новыми фрагментами и fuzz-таргет редактора.

### Legacy — зафиксированные расхождения (не чинил, чужой департамент)

`sora-legacy/core/engine/redact.go` на момент аудита: нет derivedForms
(сиды только сырые), strict-кольцо только `user|login`, нет
subscriptionPathPattern, authHeader без Token, quoted-alternation без
escaped quotes (`"[^"]*"`). Класс там открыт в том же объёме, что был в
sora до bf0bf820.

## 2. DNS-утечки

- **CheckDnsLeaks: 5/5 проверок на месте** (tunnel-dns с пробами каждого
  резолвера, system-resolvers, encrypted-dns, killswitch-dns, dns-spoof) —
  аудит кода и тестов, дыр не найдено. DoQ/DoH3 честно отчитываются
  «no QUIC prober» в Actual, а не молча пропускаются.
- **Рендеры по движкам расходятся (эскалация E1):** sing-box — DNS без
  detour идёт через default outbound (туннель); mihomo — nameserver из
  direct-списка опрашивается напрямую (зашифровано для DoH/DoT/DoQ, но
  мимо туннеля); **Xray — `tcp+local://`, `https+local://`, `quic+local://`
  для не-ProxyOnly резолверов = прямое соединение**, при этом plain и
  `tls://` — через роутинг. Единой семантики «DNS только через туннель»
  между движками нет; Xray-вариант выглядит как bootstrap-приём,
  распространённый на все резолверы. Это зона отделов движков/серверов —
  фиксирую как находку с доказательствами (xray/render.go dns()),
  сам рендер не трогал.
- FakeIP: при IPv6 выкл. sing-box отдаёт AAAA мимо fakeip (осознанно,
  S7-комментарий); guard блокирует fake-пулы v4/v6 через SetBlockedNetworks
  включая диапазон внутри fc00::/7 bypass — аудит пройден, дыр не найдено.
- Переключение серверов: DNS-конфиг — часть плана; hold блока (см. §4)
  держит и правило `th dport 53 drop` nft-таблицы на всём переключении.
- Падение туннеля: при armed kill switch DNS наружу режется тем же
  правилом до финального drop; при выключенном kill switch — окно по
  настройке пользователя (E3).

## 3–4. Direct-окна и системные переходы (усиленный мандат владельца)

Таблица переходов × гарантий. «KS» = kill switch armed (nft `sora` +
`sora_ingress`; nfqws — `sora_nfqws`). Живой nft в песочнице недоступен —
гарантии по коду + fake-nft тесты.

| Переход | Что происходит с правилами | Гарантия | Статус |
|---|---|---|---|
| Старт сессии | Guard.Apply: сначала SetBlockedNetworks (fake-пулы/TUN-сети), затем Arm атомарной заменой таблицы | окна без таблицы нет (один nft-батч) | ✅ по коду |
| Переключение сервера | Manager: HoldBlock до Stop старой сессии, release после старта новой/отката | блок не снимается ни на миг; отказ hold = отказ переключения, старый туннель жив | ✅ (закрыто отделом серверов, перепроверено) |
| Смена профиля (F5) | тот же путь Manager.Connect | как выше | ✅ |
| Смена сети / пробуждение | networkWatch (debounce 2 замера; сон — сразу) → renewConnections → CloseConnections или eng.Apply; guard не ресторится | nft-таблицы переживают переход; риск только внутри engine restart при **выкл.** KS | ⚠️ E3 |
| Падение движка, watchdog-рестарт | supervisor.watch: бюджет рестартов, unroute только при исчерпании бюджета; guard не тронут | KS цел; без KS трафик/DNS идут direct на окне рестарта (StateRecovering честно публикуется) | ⚠️ E3 |
| Рестарт ядра/сервиса (systemd Restart=on-failure) | main: CleanupStale снимает `sora`; новая сессия переармливает | **было: `sora_ingress` оставалась висеть** (CleanupStale форвардил только inner) — блокирующий остаток без владельца | ✅ исправлено cb1038a4 (+тест обеих таблиц) |
| Краш ядра (SIGKILL) | таблицы остаются в ядре | fail-closed физически (трафик режется), следующий старт чистит все три: `sora`+`sora_ingress` (cb1038a4), `sora_nfqws` — sweep при первом bypass-Apply | ⚠️ `sora_nfqws` до первого Apply: очереди без слушателя → NFQUEUE без `bypass`-флага = пакеты дропаются (fail-closed, не direct) |
| Чистый стоп сессии | Restore → Disarm обеих таблиц; ошибка Disarm не финализирует release — повтор на следующем Restore | ни дыры, ни застрявшего блока без механизма повтора | ✅ |
| Деинсталляция | postremove.sh снимает все три таблицы; purge — + /var/lib/sora | остатков нет | ✅ (WAVE-OS, перепроверено) |
| Reboot | ModeStandard: таблиц нет до старта ядра и сессии (systemd Restart только on-failure); modeStrict существует, но **недостижим** (решение владельца не принято) | после ребута до первой сессии трафик direct — by design standard-режима | ⚠️ E2 (owner decision висит) |
| nft отсутствует/стар | PlatformFirewall падает на конструкции (resolveSystemBin из доверенных каталогов), Arm переспрашивает kernel через Armed() | честный отказ с причиной, не молчаливый пропуск; root-UID Arm отказывает (SORA-H4) | ✅ |
| Ошибка чистки при старте | main: `log.Warn` и **продолжение запуска** | физически fail-closed (таблицы целы), но ядро стартует «успешно» | ⚠️ E4 — нужен честный отказ в main (чужой файл, не трогал) |

## 5. Fail-closed аудит обфусцирующих путей

- **obfs/fragConn (найдено и исправлено, ff2a4a2b):** ошибка
  RewriteClientHelloSNI раньше отправляла оригинал («obfuscation must
  never break the write path») — реальный SNI уходил открытым текстом;
  ошибка SplitClientHello — отправляла hello целиком. Теперь обе ошибки
  = отказ Write, peer не получает ничего. Единственное исключение —
  корректный hello **без** server_name (утекать нечему), через новый
  sentinel errNoServerName. Все три ветки запинены net.Pipe тестами.
- bypass: стратегия с desync — без nfqws нет tpws-fallback (nfqws.go:93);
  capability-гейт (3d506606) отказывает до изменения состояния; nfqws
  Sync — атомарная замена таблицы, Sweep толерантен к отсутствию.
- Xray DoH3: рендер отказывает честной ошибкой; бридж-путь (xraytun)
  понижает h3→https только для candidate-отбора — задокументировано в
  коде, молчаливого downgrade живого плана нет.
- ECH: план с ECH без pinned config и без encrypted DNS отклоняется в
  Validate (fail-closed, с текстом фикса).
- zapret-стратегии: микс tpws-only полей с desync-методами отклоняется в
  validateDesync вместо молчаливого дропа при рендере.

## 6. Мелочи (дополнение владельца)

1. **Словарь логов** — отдельный файл
   [CENSOR-LEAK-LOG-DICT.md](sandbox://workspace/bug-hunt/reports/CENSOR-LEAK-LOG-DICT.md):
   20 сайтов, один шаблон на класс, уровни согласованы. В рамках него
   исправлены: bypass logLine (редактор + классификация уровней,
   ff2a4a2b) и ext Notify (редактор, bcd6015b).
2. **Границы редактора векторами** (TestRedactorBoundaryVectors): сиды
   длиной 0/1 (никогда), 3 (ниже пола — осознанный контракт: паттерн-кольцо
   как backstop), 4 (первый маскируемый); сид в начале/конце строки;
   bearer 11 (проза-гард) vs 12 (маска); сид с разделителями
   (`user:p@ss/word` в тексте, userinfo и key-pair); многострочное quoted
   значение маскируется целиком; целый многострочный сид — только целиком
   (известный предел, запинен).
3. **Размеры DNS по спекам:** leak — буферы поименованы
   (RFC 1035 §2.3.4, 512 B UDP); diagnostics queryDNSWire — TCP-ответ
   читается полностью по length-префиксу §4.2.2 вместо одного Read в
   магические 4096 (тот обрезал длинные ответы посреди записи).
   dnsprobe.go уже читал по префиксу; DoH body ограничен 64 KiB именованно.
4. **Детерминизм:** profileWalk — сортированная итерация ключей
   (Secrets/Identifiers стабильны между запусками; тест 32 прогона);
   header-ключи в appendSecrets сортируются; NftRuleset/NftIngressRuleset
   детерминированы (сортировка patterns в sing-box DNS rules — по коду
   рендера); производные формы редактора строятся в фиксированном порядке.

## 7. Фузз

- `FuzzRedactorNoPanicAndIdempotent` (новый): 45 с, 66 538 execs, крашей
  нет; инварианты — no panic + идемпотентность маски.
- `FuzzParseLink` (parser подписок): 40 с, 64 552 execs, PASS.
- `FuzzDetect`: 25 с, 120 212 execs, PASS.
- Длительные прогоны ограничены машиной (2 ядра); крашей нет, регрессий
  не потребовалось. Desync/profile парсеры покрыты существующими
  валидационными тестами validateDesync/Bypass.validate (фузз-таргетов у
  них нет — кандидат на следующий проход).

## 8. Верификация

- `go build ./...` — core и service/sync чисто.
- Тесты пакетов engine (только мои наборы — см. оговорку), bypass,
  supervise, guard, diagnostics, leak, obfs — зелёные.
- service/sync логи аудитированы: только собственные bind-адреса и
  fs-ошибки реестра пиров; секретов/токенов в логах нет.
- Оговорка о среде: в момент прогонов чужие отделы держали грязные
  catalog.go/engine.go/validate.go — полный `go test ./engine/` показал
  1 чужое падение (TestECHPlanRequiresFeatureECH, их in-flight ECH-работа)
  и HEAD сам по себе временно не собирался без их ворктри. Все тесты
  CENSOR-LEAK наборов проходят.
- В индекс общего дерева дважды вносились чужие staged-удаления моих
  тест-файлов; коммиты строились temp-index+CAS из HEAD+ворктри, состав
  каждого коммита сверен по --stat и numstat.

## Эскалации

- **E1 (движки):** расхождение DNS-семантики рендеров; Xray `+local` для
  tcp/https/quic резолверов — DNS мимо туннеля by render. Нужна единая
  политика «DNS через туннель, bootstrap — явным исключением».
- **E2 (owner):** reboot-переход в ModeStandard без блока до первой
  сессии; modeStrict готов и протестирован, но недостижим без решения
  владельца.
- **E3 (продукт):** все direct-окна при **выключенном** kill switch
  (watchdog-рестарт, смена сети) — поведение соответствует настройке,
  но UI стоит явно показывать «окно без блока» в StateRecovering.
- **E4 (main):** ошибка CleanupStale при старте — Warn + продолжение;
  по критерию владельца нужен честный отказ запуска с причиной.
- **E5 (legacy):** класс редактора в sora-legacy открыт (§1) — перенос
  bf0bf820 в legacy-отдел.
