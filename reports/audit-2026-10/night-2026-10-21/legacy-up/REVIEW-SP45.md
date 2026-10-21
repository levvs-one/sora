# REVIEW-SP45 — независимое ревью SP4 (ba5625b) и SP5 (e124b74) подъёма sora-legacy

Дата: 2026-10-21. Ревьюер: независимый агент (код не правил, коммитов не делал).
Объект: `sora-legacy` ветка `bugfix/audit-2026-10-19`, HEAD `e124b74`.
Методика: работа только по закоммиченному состоянию — `git archive HEAD`
в `~/workspace/review-sp45/legacy-head`, эталон sora — `git archive HEAD`
(`86c9c2a`) в `~/workspace/review-sp45/sora-head`, baseline — `git archive
5c4190e` в `~/workspace/review-sp45/legacy-base`. Рабочие деревья не читались
как источник истины. Все поведенческие утверждения — своими прогонами
(пробы `probe_review_test.go` в архивных копиях обоих репо, после замеров
удалены из legacy-копии перед полным `go test ./...`; тексты проб сохранены
в `~/workspace/review-sp45/probes/`). Go: `PATH=$HOME/workspace/go/bin`,
модуль `core/go.mod`.

## Вердикты

| Коммит | Вердикт |
|---|---|
| `ba5625b` [legacy-up] SP4: XHTTP extra= end-to-end | **Принять** (с замечаниями §7, все — Low/мелочи) |
| `e124b74` [legacy-up] SP5: TLS.validate ECH/KeyShare + bootstrap | **Принять** (с замечаниями §7, все — Low/мелочи) |

Блокеров не найдено. Цепочки SP4 и правила SP5 дифференциально совпадают
с эталоном на всех проверенных векторах; гейты fail-closed на единственном
продакшен-пути (см. §3.3, §4.3). Замечания касаются глубины обороны
(рендер-бэкстопы) и точности отдельных формулировок, а не корректности
портов.

---

## 1. SP4: полнота цепочки extra= → parser → vault → validate → рендеры

### 1.1 Дифференциальные векторы parser (одна проба, оба репо)

Проба `TestProbeParseFullExtra` прогнана без изменений в legacy-head и
sora-head; вывод **байт-в-байт совпал** (значения spec по всем полям):

| Вход extra= | legacy | sora | Итог |
|---|---|---|---|
| Полный: downloadSettings{down.example.com:8443} + xmux{maxConcurrency:"16-32", cMaxReuseTimes:10, hMaxRequestTimes:"600-900"} + xPaddingBytes | dl=down:8443, conc=16, reuse=10, req=600, pad="100-1000" | идентично | ✓ range → нижняя граница по обоим range-полям |
| downloadSettings port=65535 | импортируется 65535 | — (та же ветка кода, `1..65535`) | ✓ граница сверху |
| downloadSettings port=65536 + xmux{8} | split-секция отброшена целиком, xmux=8 выжил | идентичная логика applyExtra | ✓ секции независимы |
| xmux{maxConcurrency:-4, cMaxReuseTimes:"abc", hMaxRequestTimes:3.9} | −4→0, "abc"→0, 3.9→**3** (int-транкейт float) | идентично (3.9→3) | ✓ включая транкейт |
| xmux{maxConcurrency:{объект}, cMaxReuseTimes:7} + padding | conc=0, reuse=7, pad выжил | RawMessage-путь тот же | ✓ битое поле не валит соседей |
| Битый JSON extra целиком (`{not json`) | импорт сервера успешен, все поля нулевые (также тест коммита) | идентично | ✓ decoration, не ошибка |
| extra с downloadSettings на `type=ws` ссылке | parser импортирует DownloadAddress (отсев — на plan-уровне) | идентично | ✓ validate ловит stray (см. §2) |

Код `applyExtra`/`xmuxRangeValue`/`extraParams` в legacy — дословный порт
sora (сверено чтением обоих текстов; расхождений нет, включая json-теги
`cMaxReuseTimes`/`hMaxRequestTimes`).

### 1.2 Vault (control/plan.go): своя проба `TestProbeVaultZeroAndBounds`

| Проверка | Факт |
|---|---|
| Нулевой spec → документ | `{"uuid":"…"}` — **ни одного** из 7 SP4-ключей нет («ноль не пишется» подтверждено) |
| Полный spec (port 65535) → round-trip | документ содержит все 7 ключей; `applyCredential` восстанавливает Download 65535, padding, xmux 16/10/600 точно |
| Подделанный документ port=65536 / 70000 / 131071 | → **0**, не uint16-wrap (70000 не превращается в 4464): повторная граница `atoiNonNegative + <=65535` в `applyCredential` работает |
| port="-1" / "abc" / "0" | → 0 |
| xmux="-9" / огромное число (переполнение Atoi) | → 0 / 0 |

Расхождение с эталоном в обратную сторону: sora на нулевом spec **пишет**
`"download_port":"0"` и все четыре `"xmux_*":"0"` (его `doc.field` пропускает
только пустую строку, а `strconv.Itoa(0)` непуста). Legacy чище; семантика
`applyCredential` у обоих одинакова, round-trip идентичен. Не дефект.

`credentialKeys` дополнен всеми 7 ключами — без этого `parseCredential`
отбрасывал бы документ; проверено тем же round-trip (ключи доезжают).

### 1.3 Рендеры: дифференциальный прогон одного плана на трёх движках

План: VLESS+REALITY (enginetest), xhttp stream-up, split
down.example.com:8443, xmux{conc 16, reuse 10}, padding "100-1000",
fingerprint "chrome".

| Движок | legacy | sora на том же входе | Итог |
|---|---|---|---|
| Xray | `downloadSettings{address, port:8443, network:xhttp, security:reality, realitySettings{serverName:"down.example.com", fingerprint:"chrome"}, xhttpSettings{path, xmux}}`; uplink `xmux` + `xPaddingBytes` | поддерево xhttpSettings/downloadSettings **идентично** (вне SP4 sora добавляет лишь spiderX "/" и mux — другие фичи) | ✓ паритет |
| mihomo | `download-settings{server, port:8443, reuse-settings}`, `x-padding-bytes`, tuned reuse без дефолтной concurrency | та же проба — те же блоки | ✓ паритет |
| sing-box | `"xmux":{"c_max_reuse_times":10,"max_concurrency":16}`, `"x_padding_bytes":"100-1000"`; untuned — ни одного ключа | спеллинги те же | ✓ паритет |
| Детерминизм | тесты коммита (xray/singbox byte-equal двух рендеров) зелёны | — | ✓ |

## 2. validateXHTTP

- Файл `validate_xhttp_test.go` в legacy **байт-идентичен** sora
  (`diff` пуст), функция `validateXHTTP` — дословный порт (сверены оба
  текста целиком, включая stray-field ветку, vision-исключение для VLESS
  Encryption и ALPN-h3 гейт).
- Фактическое число векторов — **26 подтестов**, не 27 (посчитано прогоном
  `go test -run TestValidateXHTTP -v`). Заявка исполнителя завышена на 1;
  код при этом полный (см. «Мелочи»).
- Выборочная сверка 10+ векторов с эталоном — все совпали тривиально в силу
  идентичности файла; дополнительно прогнаны **свои негативы**, отсутствующие
  в портированном наборе:

| Свой вектор | Результат |
|---|---|
| stray download на ws / xmux на grpc / padding на ws / только port на tcp | все reject с точным текстом эталона |
| padding "500-100" (lo>hi), "10-" (битый формат), "65536" (>cap) | reject |
| padding "0-65535" | accept (верхняя граница включительно) |
| download address "bad host!" | reject через validateServer |
| xmux conc=200 через полный `Outbound.Validate()` | **accept** + warning `xhttp-xmux-proxy-limit` (не блокирует) |
| граница warning | 128 — нет warning, 129 — есть (также запинено тестом коммита `TestCensorP1XmuxBoundaries`) |

## 3. Гейты SP4

### 3.1 Матрица движок × фича — фактическими прогонами, не каталогом

| План | sing-box статик | sing-box lx.22 + with_xhttp (BuildCapabilities) | sing-box upstream 1.14.3 | mihomo | xray |
|---|---|---|---|---|---|
| download-split | Missing: split (+xhttp) | **Missing: split** (никогда не заявляется) | Missing | несёт | несёт |
| xmux-only | Missing | **несёт** (`SelectEngine` выбирает) | Missing → `SelectEngine` fail | несёт | несёт |
| padding-only | Missing | несёт | Missing | несёт | несёт |
| lx без тега with_xhttp | — | xmux/padding/xhttp **не заявляются** (все три от тега) | — | — | — |
| lx версии < 1.14.3 с тегом | — | xmux **не заявляется** (порог версии в BuildCapabilities) | — | — | — |

`SelectEngine(split, только sing-box lx)` → ошибка
`no engine can carry this plan (sing-box: cannot carry feature xhttp-download-split)` —
падение на выборе движка, а не молчаливая потеря. Подтверждено прогоном.

### 3.2 Рендер-отказы Xray (прогоны: тесты коммита + своя проба)

Отказывает: битая пара (address без port / port без address), stream-one +
split, download на ws-транспорте, пустой fingerprint на downlink. Mihomo
отказывает на битой паре download через собственный `p.Validate()` в начале
`Render`. Sing-box рендер split **молча отбрасывает** — но так же делает и
sora (дифференциально подтверждено: sora sing-box Render того же плана —
err=nil, адреса нет), защита обоих репо — гейт, не рендер.

### 3.3 Замечание (Low): глубина бэкстопов рендеров

Прямой вызов `Render` в обход `Plan.Validate`/`SelectEngine` в legacy:
xray молча теряет xmux/padding на ws-транспорте (guard есть только на
download), sing-box молча теряет split (паритет с sora), xray/singbox молча
теряют ECH/KeyShare (§4.3). Продакшен-путь при этом fail-closed:
`supervise.Supervisor.admit` (`p.Validate()` + `Capabilities().Missing(p)`)
стоит перед любым `Render` в `Validate`/`Apply`, а `start`/`reload`
достижимы только через `Apply`. У sora для KeyShare есть дополнительный
рендер-бэкстоп в xray (`outbound()` отказывает) — в legacy его нет.
Рекомендация (не блокер): добавить симметричные отказы в xray outbound и
sing-box tls/transport при случае.

## 4. SP5: ECH / KeyShare

### 4.1 TLS.validate — свои векторы поверх портированных тестов

| Вектор | Результат |
|---|---|
| KeyShare ∈ {"", classical, hybrid} + REALITY | accept (тест коммита + проба) |
| KeyShare "CLASSICAL" (регистр) | reject — значения регистрозависимы, как в sora |
| KeyShare без REALITY / неизвестное значение | reject (`key_share needs REALITY` / `not "classical" or "hybrid"`) |
| ECH без TLS / ECH+REALITY | reject |
| Пин: **свой** ECHConfigList (raw `00080100200004AABBCCDD`, base64 в PEM-арморе) | `ECHConfigListBytes` возвращает те же байты; TLS.validate accept |
| Пин: unterminated armor / мусор `%%%bad%%%` / два PEM-блока / armor-only / not-base64 | reject на всех формах (своя проба + `echconfig_test` коммита) |
| ECHConfigListBytes(nil) | (nil, nil) — «нет пина», не ошибка; вызывающие гейтятся на `len(Config)` |

Тело `ECHConfigListBytes` в legacy байт-идентично sora (`diff` показал
только комментарии и отсутствие render-хелперов, см. отклонение 5).
`TLS.validate` legacy = sora минус клауза ML-DSA-65 (поля нет, отклонение 4).

### 4.2 Bootstrap-правило (Plan.Validate) — полная матрица своей пробой

ECH без пина, DNS включён:

| DNS-транспорт | Plan.Validate |
|---|---|
| https (DoH) | **accept** |
| tls (DoT) | **accept** |
| quic (DoQ) | **accept** |
| udp / tcp / system / fakeip | **reject** (`no encrypted DNS transport`) |
| DNS выключен, но с https-сервером в списке | **reject** (`hasEncryptedServer` требует `Enabled`) |
| без DNS вовсе | **reject** (тест коммита) |
| пин + plaintext DNS | **accept** |
| ECH выключен + plaintext DNS | **accept** |

### 4.3 Гейты SP5 — fail-closed подтверждён кодом и прогоном

- Ни один legacy-движок не заявляет `FeatureECH`/`FeatureRealityKeyShare`:
  проверено по статическому `Catalog` (все 3) и по `BuildCapabilities`
  sing-box lx со всеми тегами.
- План с ECH: `RequiredFeatures` требует `ech`; `Catalog[kind].Missing`
  содержит `feature ech` для всех трёх движков → `SelectEngine` и
  `Supervisor.admit` отказывают. Аналогично KeyShare → `feature
  reality-key-share`. Это именно fail-closed на уровне выбора/допуска,
  а не молчаливая потеря: план никуда не уезжает.
- Оговорка §3.3 применима и сюда: голый `Render` (xray/singbox) ECH/KeyShare
  молча отбрасывает (прогон: err=nil, спеллингов нет). Производственный путь
  через admit закрыт; прямого продакшен-вызывающего Render в обход admit
  поиском по `core/` не найдено (вызовы — supervise start/reload/Validate,
  все после admit).

## 5. Шесть заявленных отклонений — вердикты

| # | Отклонение | Вердикт | Обоснование (факты прогонов) |
|---|---|---|---|
| 1 | Xray downlink fingerprint verbatim, без каталога имён и hint-ов; пустой → отказ | **Честно и приемлемо** (Low-наблюдение) | Своя проба: `"totally-bogus-parrot-999"` в legacy рендерится verbatim; в sora тот же вход **отказывается** (`NormalizeFingerprint` + `xrayAcceptsFingerprint` + fpHints). Риск ограничен: явное значение плана никогда не подменяется молча (это и есть цель SP4-честности), а мусорное имя упадёт поздно — на бинарной проверке `Supervisor.check`, а не тихо поедет другим ClientHello. Рекомендую позже портировать проверку имени или plan-level валидацию отпечатка. |
| 2 | mihomo reuse-settings всегда, дефолт 16-32 для ненастроенного плана | **Паритет с sora; поведенческий риск — нет, это фикс** | Функция `xhttpReuseSettings` байт-идентична sora; дифференциальный рендер sora того же untuned-плана дал тот же блок `max-concurrency: 16-32`. Изменение рендера всех существующих mihomo-xhttp планов реально (раньше блока не было), но без блока mihomo **отключает reuse полностью** (документированное upstream-поведение, на которое ссылаются оба репо) — старый рендер был хуже, а не «нейтрален». Принять; в release notes строчка не помешает. Проверено также: tuned-план с max-connections не получает дефолтную concurrency сверху (конфликт исключён в обоих репо). |
| 3 | hasEncryptedServer без h3 | **Честно и приемлемо, с уточнением** | Факт подтверждён: константы `DNSH3` в legacy нет (grep по всему `core/`). Уточнение, смягчающее отклонение: legacy `control.splitDNSServer` маппит `h3://` → `DNSHTTPS`, поэтому h3-резолвер в legacy всё равно считается зашифрованным (через https-ведро) и ECH-bootstrap ложно не отклоняется. У sora `h3://` → отдельный `DNSH3` и `hasEncryptedServer(h3)=true` (прогон). Остаточный разрыв — невозможность отдельного FeatureDoH3-гейтинга в legacy; генерационный, вне SP5. |
| 4 | ML-DSA-65 / pqv не портирована | **Факт подтверждён; приемлемо в скоупе SP5, но фиксирую как известный зазор** | `grep MLDSA/mldsa/pqv` по всему legacy `core/` — **0 вхождений**: поля `RealityMLDSA65Verify` нет, парсер `pqv` не читает. Следствие честнее формулировки «вне SP5»: vless-ссылка с `pqv` в legacy импортируется с **молча отброшенной** проверкой — тот же класс тихой потери, против которого направлен SP5, только на соседней фиче. Исполнитель раскрыл это явно, спека SP5 фичу не покрывала — коммит не виноват. Рекомендую отдельную спеку (аналог S5-SP7) до того, как pqv-ссылки встретятся в проде. |
| 5 | echconfig — только декодер, без render-хелперов | **Подтверждено поиском; приемлемо** | `ECHConfigListBase64`/`ECHConfigPEM` в legacy отсутствуют; ни один legacy-рендер не содержит спеллинга ECH (grep по render-файлам xray/mihomo/singbox — пусто). Хелперы были бы мёртвым кодом: гейт §4.3 не пускает ECH-планы ни на один движок. Декодер при этом нужен уже сейчас (валидация пина) и портирован полностью. |
| 6 | SP5-гейты инвертированы относительно sora-теста, запинены как есть | **Честно и приемлемо** | Дифференциальный факт: sora каталог — sing-box заявляет ECH **и** KeyShare, mihomo и xray — ECH (прогон своей пробы на sora). Legacy заявляет ничего, и тест `TestECHPlanRequiresFeatureECH`/`TestValidateKeyShare` утверждает `Missing ∋ feature …` для всех трёх движков; инверсия прямо задокументирована в шапке `validate_ech_test.go`. Это корректная fail-closed поза для отсутствующих рендеров, а не подгонка. |

## 6. Попутная находка: Identifiers() без Transport.Host/Service

**Вердикт: находка реальная, серьёзность Low (полнота редактирования/
приватность), не косметика и не блокер SP4/SP5.**

Факты (своя проба, оба репо, один вход: Host=`secret-cdn-host.example.com`,
Service=`secret-grpc-service`, Download=`dl.example.com:8443`):

- legacy `Identifiers()` = `[server, server:port, name, dl.example.com,
  dl.example.com:8443]` — DownloadAddress добавлен SP4 корректно, включая
  host:port-форму. Host и Service **отсутствуют**.
- sora `Identifiers()` на том же входе содержит Host и Service (порядок:
  после Name, до DownloadAddress; плюс GRPCAuthority, которого в legacy
  Transport как поля ещё нет — генерационное).

Что дают Identifiers: это сиды редактора — `supervise/supervisor.go`
(`redactor.Add(p.Secrets()..., p.Identifiers()...)`), `control/server.go`
(диагностические архивы и per-outbound редакторы). Редактор маскирует
точное значение и его производные кодировки (G3-replacer). Отсутствие
значения в сидах = оно уходит в логи/события/диагностику как есть.

Оценка риска:
- **Host** (ws/xhttp/h2): CDN-/фронтинг-домен. Не креденшел, но
  идентифицирует инфраструктуру провайдера ровно в том смысле, в котором
  маскируются Server и SNI; когда Host ≠ Server/SNI (фронтинг — штатный
  приём), он утекает чистым. Это тот же класс данных, что и добавленный
  SP4 DownloadAddress, — непоследовательность внутри одного коммита
  понятна (SP4 добавлял только своё поле), но разрыв настоящий.
- **Service** (gRPC service name): обычно не секрет; однако у части
  провайдеров пара path/service используется как полусекретный токен
  («secret path»-развёртывания). Как сид отсутствует и в `Secrets()`.
- Потолок серьёзности ограничен: Host/Service не дают доступа, утечка —
  только в собственные логи и диагностические архивы пользователя, не
  наружу по сети. Поэтому Low, а не Medium. Фикс — несколько строк +
  тест; рекомендую отдельной микрозадачей вместе с пунктом ниже.

Дополнительное наблюдение ревьюера (вне находки исполнителя и вне скоупа
SP4/SP5, на вердикты не влияет): та же проба показала, что legacy
`Secrets()` не включает `Transport.Path` и значения `Transport.Headers`
(у sora на том же входе оба в Secrets — CENSOR-LEAK порт). Secret-path —
известный bearer-паттерн провайдеров, поэтому этот соседний разрыв
потенциально серьёзнее Host/Service (Medium-Low); заслуживает своей спеки,
а не пришивания к SP4/SP5 задним числом.

## 7. Дисциплина и регрессии

| Проверка | Результат |
|---|---|
| `git show --stat ba5625b` | 19 файлов, состав соответствует спеке SP4 |
| `git show --stat e124b74` | 7 файлов, только `core/engine` — соответствует SP5 |
| parser.go в ba5625b | **ровно 3 ханка**, все SP4 (struct-поля, вызов applyExtra, applyExtra-блок); `grep alterId/alter_id` по всему диффу коммита — **0**; alterId-работа живёт отдельно в `6ac5553` (5 ханков parser.go) — чужих ханков в SP4 нет |
| Полный `go test ./...` на архивном HEAD | все пакеты ok; единственный FAIL — `engine.TestTunAndFakeIPAvoidLANAndEachOther` |
| Тот же тест на чистом baseline `5c4190e` (архив) | FAIL с **идентичным** сообщением (`tun_test.go:77: fake-IP pool overlaps an existing interface`) — известный env-артефакт VM, не регрессия |
| Целевые тесты SP4/SP5 на HEAD | все зелёны: TestValidateXHTTP (26), TestCensorP1{Xmux,Padding}Boundaries, TestParseExtra*, TestXHTTP*SurvivesTheVault, render_xhttp ×3 движка, TestECHConfigListBytes{Shapes,Rejects}, TestValidate{ECH,KeyShare}* |
| `go vet` по пакетам обоих коммитов | чисто |
| `gofmt` по файлам коммитов | чисто, кроме `parser/parser.go`: одна недостающая пустая строка перед комментарием `getq` — **пре-существующая**: `gofmt -d` на baseline `5c4190e` и на pre-SP4 ревизии даёт тот же самый дифф (SP4 лишь сдвинул номер строки). SP4 её не вносил |

## 8. Мелочи

1. **«27 векторов» в заявке исполнителя** — фактически 26 подтестов
   `TestValidateXHTTP` (посчитано прогоном). Файл при этом байт-идентичен
   эталону; расхождение только в числе, не в покрытии.
2. **Литерал `"auto"` вместо константы**: legacy рендеры xray и sing-box —
   `orDefault(t.Mode, "auto")`; у sora — `engine.DefaultXHTTPMode`.
   Исполнитель честно отметил это в комментариях обоих render-тестов.
   Поведение не меняется; константа удобнее для будущего переименования.
3. **Локальные хелперы в тестах**: в пакете engine два почти одинаковых
   билдера REALITY-аутбаунда с одним и тем же ключом —
   `xhttpRealityOutbound` (`xhttp_censor_test.go`, SP4) и
   `keyShareRealityOutbound` (`validate_ech_test.go`, SP5). Дублирование
   только тестового кода; напрашивается один общий хелпер.
4. **Комментарий константы `FeatureXHTTPXmux`** (engine.go): «All three
   engines claim it» — для sing-box неточно: статический каталог не
   заявляет, заявляет только `BuildCapabilities` для lx+with_xhttp.
   Точная формулировка есть в catalog.go; комментарий константы стоит
   выровнять по нему.
5. **Комментарий границы padding**: «larger than any plausible MTU» при
   фактическом капе 65535 (и имя портированного подтеста «above MTU
   sanity bound» для 70000) — унаследовано из sora дословно, неточность
   обоих репо: 65535 — это wire/uint16-потолок, а не MTU-правдоподобие.
6. **Комментарий поля DownloadAddress в plan.go**: «rejected there by the
   engines» про чужие транспорты — сильнее факта: отклоняют plan-валидация
   и гейты; из рендеров отказ есть только у xray на download (см. §3.3).
7. **SP4-комментарий в mihomo/config.go и proxy.go** точен (docs-default,
   конфликт concurrency/connections) — претензий нет; фиксирую, чтобы
   точность была отмечена так же явно, как неточности выше.
