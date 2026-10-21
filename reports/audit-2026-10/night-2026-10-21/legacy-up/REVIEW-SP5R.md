# REVIEW-SP5R — независимое ревью пакета SP5-render (5 коммитов) подъёма sora-legacy

Дата: 2026-10-21. Ревьюер: независимый агент (код не правил, коммитов не делал).
Объект: `sora-legacy`, ветка `bugfix/audit-2026-10-19`, HEAD `c3c61bb`.
Основание: REVIEW-SP45.md §SP5 (гейты SP5 были fail-closed именно потому, что
рендеров ECH/KeyShare в legacy не существовало; этот пакет их портирует).

Методика: работа только по закоммиченным состояниям — `git archive
c3c61bb` в `~/workspace/review-sp5r/legacy`, эталон — `git archive
63faf1d3480d5429b6bcec3483c19c8e03defb85` в `~/workspace/review-sp5r/sora-snap`.
Рабочие деревья обоих репо как источник истины не использовались (в обоих
идёт чужая живая работа: в legacy worktree грязные `core/parser/parser.go`
и `core/control/plan_internal_test.go`, в sora — большой грязный набор;
ни один из этих ханков в проверяемые коммиты не попал, см. §7).
Все поведенческие утверждения — своими прогонами: дифференциальные пробы
`probe_sp5r_test.go` (engine / singbox / mihomo / xray) написаны один раз,
прогнаны без изменений в архивных копиях обоих репо, выводы сохранены в
`~/workspace/review-sp5r/probes/`; перед полными прогонами пробы из копий
удалены. Go: `PATH=$HOME/workspace/go/bin`,
`TMPDIR=$HOME/workspace/.build-tmp`, `GOCACHE=$HOME/workspace/.gocache-v`,
модуль `core/go.mod`.

### Сверка со снимком исполнителя

Исполнитель работал по `sora@63faf1d`. Я проверял **именно с ним**.
HEAD sora на старте ревью был `79803f49` (2 коммита поверх снимка), а пока
шло ревью — продвинулся до `f8370738` (третий, CENSOR-LEAK E1: Xray DNS).
Полный дифф `63faf1d..f8370738` (6 файлов: parser extra=, interop-тест,
mihomo binary_xhttp_test, xray dns_render + ветка `dns()` в render.go)
**не содержит ни одной строки про ECH/KeyShare** (`grep -i ech|key_share`
по диффу — пусто); блок ECH в xray/render.go поимённо идентичен снимку.
Дрейфа по ECH/KeyShare-рендерам между снимком и более новым HEAD нет —
выводы ревью одинаковы для обоих.

## Вердикты

| Коммит | Вердикт |
|---|---|
| `4fb7874` echconfig: ECHConfigListBase64/ECHConfigPEM | **Принять** |
| `6c13890` sing-box: tls.ech + reality.key_share, tls() → error | **Принять** (замечание Low §5в — про унаследованный MinVersion, не про код коммита) |
| `c12a054` mihomo: ech-opts + support-x25519mlkem768 | **Принять** |
| `7a58e17` xray: echConfigList/echForceQuery, отказ QSN | **Принять** |
| `c3c61bb` гейты: FeatureECH ×3, FeatureRealityKeyShare mihomo + lx | **Принять** |

Блокеров не найдено. Пакет неразрывен по смыслу (хелперы → рендеры → гейты),
но каждый коммит по отдельности соответствует своей заявке. Единственное
содержательное замечание пакета — Low §5в (MinVersion 1.12.0 против
query_server_name с 1.13; поставляемый пин 1.14.3 не затронут).

---

## 1. Дифференциальный стенд: 30 векторов, байт-в-байт

Полностью явные планы (enginetest/testPlan, идентичные в обоих репо),
сравнивались ECH/KeyShare-фрагменты (распарсенные под-объекты, не сырой
рендер целиком — вне SP5 у репо генерационные различия: ResolveFingerprint
и пр.) и точные тексты ошибок. Заявленные исполнителем «17/17» моей
разбивкой не воспроизводятся 1-в-1 (его партиция векторов мне не передана),
но мой стенд шире и покрывает все заявленные режимы:

| Группа | Векторы | legacy vs sora@63faf1d |
|---|---|---|
| echconfig-хелперы | base64; PEM канонический из «ECHCONFIG»-лейбла; PEM wrap: длинный payload (72 b64-символа → строки 64+8); битый base64 → ошибка; два PEM-блока → ошибка | **5/5 идентичны**, включая тексты `ech: the pinned ECH config is not PEM/base64 ECHConfigList data` и `ech: 2 pinned ECH configs cannot be merged into one ECHConfigList` |
| sing-box | ECH pinned; pinned+query_server_name; unpinned (`{"enabled":true}` без config); unset (ключа `ech` нет); KeyShare hybrid/classical/unset | **7/7 идентичны**: PEM-армор `-----BEGIN ECH CONFIGS-----`, `key_share` verbatim, unset — ключа нет |
| mihomo | ECH unpinned (`ech-opts: enable: true`, без config); pinned+QSN (`config: <один base64>`, `query-server-name:`); unset (нет `ech-opts`); KeyShare hybrid→`support-x25519mlkem768: true`, classical→`false` явно, unset→ключа нет | **6/6 идентичны** |
| xray | pinned→`echConfigList: "QUJD"`; unpinned→`echForceQuery: "full"`; unset→ни одного ключа | **3/3 идентичны** |
| ошибки (см. §2) | singbox bad pin; mihomo два блока / не-base64 / битый пин; xray QSN / QSN+pinned / bad pin / KeyShare ×2 | **9/9 идентичны посимвольно** |

Итого **30/30** рендер/хелпер/ошибочных векторов — вывод проб обоих репо
совпал полностью (diff файлов проб пуст, кроме строки `ok … 0.00Xs`).
Кодовое чтение подтверждает механику: тела `ECHConfigListBase64`/
`ECHConfigPEM` в legacy байт-идентичны эталону (diff echconfig.go — только
шапка-комментарий); блоки ECH в singbox `tls()`, mihomo `applyTLS`/
`mihomoECHConfig`, xray `stream()` — дословные порты (расхождения вокруг —
генерационные: у sing-box эталона fingerprint идёт через
`ResolveFingerprint`, у legacy — `orDefault(…, "chrome")`, вне фрагментов).

## 2. Негативы исполнением

Все негативы — отказ (ошибка, не паника, не молчаливая пустота), на голом
`Render` в обход валидации плана:

| Вектор | legacy (факт) | Эталон |
|---|---|---|
| sing-box битый пин | `singbox: outbound trojan: ech: the pinned ECH config is not PEM/base64 ECHConfigList data` — имя аутбаунда есть (`trojan` — ID enginetest-плана) | идентично |
| mihomo два PEM-блока | `mihomo: outbound srv-1: ech: 2 pinned ECH configs cannot be merged into one ECHConfigList` | идентично |
| mihomo не-base64 config | `mihomo: outbound srv-1: ech: the pinned ECH config is not PEM/base64 ECHConfigList data` | идентично |
| xray битый пин | `xray: outbound vless: xray: outbound vless: ech: the pinned ECH config is not PEM/base64 ECHConfigList data` — отказ с именем; про двойной префикс см. «Мелочи» п.1 | **идентично, включая двойной префикс** |
| xray QueryServerName (pinned и unpinned) | `xray: outbound vless: xray: outbound vless sets ECH query_server_name "ech.example.com", which Xray does not spell; use the sing-box or mihomo engine` — именной отказ | идентично |
| xray KeyShare (29d9cc4, не тронут) | `xray: outbound vless pins a REALITY key_share, which Xray does not expose (the fingerprint parrot decides the key share); use the sing-box or mihomo engine` — строка отказа в `c3c61bb` та же, что в `29d9cc4` (строка 205 файла, посимвольно); дифф `7a58e17` строк KeyShare в коде не содержит | паритет |

`tls()` → error в sing-box остальные режимы не сломал: полный сьют пакета
singbox зелён (18 топ-левел тестов, 0 FAIL — REALITY/plain/uTLS/fragment
рендеры как раньше), mihomo — 29/0, xray — 19/0; целевые SP5-тесты:
singbox 5 PASS + 1 SKIP (`TestCensorP1BinaryAcceptsKeyShareRender` —
честный self-skip без пинованного бинаря), mihomo 5 PASS, xray 2 PASS.

## 3. Гейты по факту (пробы в пакете engine, оба репо)

Матрица legacy после `c3c61bb` — в точности заявленная:

| | sing-box статика | sing-box lx (BuildCapabilities) | mihomo | xray |
|---|---|---|---|---|
| FeatureECH | ✓ (`Missing(ech-план)=[]`) | ✓ | ✓ | ✓ |
| FeatureRealityKeyShare | ✗ (`missing=[feature reality-key-share]`) | ✓ | ✓ | ✗ |

`SelectEngine` своей пробой (legacy):
- ECH-план, все три движка доступны → выбирается sing-box (первый по
  preference), отказов нет. ECH выбираем на всех трёх.
- KeyShare-план, upstream sing-box 1.14.3 + xray + mihomo → выбирается
  **mihomo**, rejected = `[sing-box: cannot carry feature
  reality-key-share, xray: cannot carry feature reality-key-share]`.
- KeyShare-план, sing-box lx.22 первым → выбирается **sing-box**.
- KeyShare-план, только upstream sing-box + xray → ошибка
  `engine: no engine can carry this plan (...)`. Статика upstream и xray
  KeyShare-план не получают — подтверждено исполнением, не чтением.

Обоснование расхождения по sing-box — фактом:
- `packaging/engines/engines.lock` legacy пинит **upstream** SagerNet
  sing-box **v1.14.3** (`github.com/SagerNet/sing-box/releases/download/
  v1.14.3/...`, обе арки); эталон пинит форк Leadaxe sing-box-lx
  `v1.14.3-lx.22`. Расхождение пинов реально.
- Что upstream 1.14.3 поля `reality.key_share` не имеет: в репозиториях
  исходника upstream нет, поэтому честная формулировка — **по заявлению +
  структуре эталона**: в sora поле везде описано как «tls.reality.key_share
  **of the lx fork** (PASS2 S3), probed on the pinned lx.22 binary»
  (probecaps, комментарии рендера), статический клейм эталона существует
  именно потому, что его поставляемый бинарь — форк. Независимого
  подтверждения по upstream-бинарю в этом ревью не выполнялось.
- Условия клейма в `BuildCapabilities` — уточнение к формулировке задания:
  клейм стоит в той же lx-ветке, что и FeatureXHTTP, и делит с ней
  **версионный** гейт (`PreRelease` с префиксом `lx.` и версия ≥1.14.3 —
  проба: lx.22@1.14.2 → KeyShare=false), но **не делит тег `with_xhttp`**:
  проба lx@1.14.3 с `tags=nil` даёт `FeatureXHTTP=false, FeatureXHTTPXmux=
  false`, а `FeatureRealityKeyShare=true`. Это намеренно и правильно
  (key_share не зависит от сборки XHTTP-транспорта) и запинено тестом
  самого коммита (`BuildCapabilities(..., nil)` в TestValidateKeyShare).
  Формулировка коммита «rides the lx branch, next to FeatureXHTTP» точна;
  читать её как «с тем же тегом» было бы ошибкой.

## 4. Обновлённые SP5-тесты

- `validate_ech_test.go` (коммит `c3c61bb`): изменены ровно шапка, ассерт
  `TestECHPlanRequiresFeatureECH` (инверсия: было «каждый движок обязан
  miss-ить ech» → стало «ни один не смеет miss-ить») и гейт-половина
  `TestValidateKeyShare` (mihomo несёт; sing-box статика и xray miss-ят;
  lx-build несёт). Остальные ассерты файла диффом коммита **не тронуты**.
  Сверка с эталоном: legacy-файл ⊇ sora-файл (в legacy дополнительно
  `TestValidateRejectsGarbagePinnedECHConfig`, а TestValidateKeyShare
  принесён из sora `reality_test.go`); ослаблений нет — `containsStr`
  эталона заменён эквивалентным `slices.Contains`.
- Bootstrap-правило по-прежнему fail-closed — своей пробой и сьютом:
  ECH без пина + без DNS → отказ; + plaintext DNS → отказ
  (`plan: outbound ech1 enables ECH without a pinned config, but the plan
  has no encrypted DNS transport; …`, текст идентичен эталону); + DoH →
  accept. Все 13 тестов файла зелёны.
- `xray/render_keyshare_test.go` (коммит `c3c61bb`): дифф — **только**
  шапка-комментарий (переписан под пост-порт мир: гейт теперь не «никто не
  заявляет», а «xray не заявляет нигде»). Тело теста, включая текст
  ожидаемой ошибки, без изменений.

## 5. Вне-скоуп заявления исполнителя — выборочная проверка фактом

**(а) Парсинга ECH из ссылок нет ни в одном репо — правда.**
`grep -rn "ECH|ech" core/parser/` — **0 вхождений в обоих репо**
(у sora parser больше файлов, включая pqv-тесты, — ECH нет и там).
ECH попадает в план только программно, не из ссылки, в обоих поколениях.

**(б) Нативный hysteria2-путь xray ECH не спеллит в обоих репо — правда,
подтверждено кодом и исполнением.** `hysteria()` в обоих репо собирает
`tlsSettings` только из `serverName`+`alpn` и возвращает аутбаунд до ветки
`stream()`, где живёт ECH. Своя проба (hy2 без obfs, ECH pinned): рендеры
обоих репо **байт-идентичны целиком (1494 байта)**, `tlsSettings =
{"serverName":"edge.example.com"}` — ни `echConfigList`, ни
`echForceQuery`. Оговорка ревьюера: это паритетная тихая потеря эталона,
а не дефект порта — план hy2+ECH гейтом FeatureECH пропускается на xray
(гейт по движку, не по протоколу), а нативный путь ECH роняет; в обоих
репо одинаково. Заслуживает отдельной спеки на оба репо, к SP5-render
отношения не имеет.

**(в) sing-box MinVersion legacy 1.12.0 при query_server_name с 1.13 —
правда; классификация Low, поставляемый пин не затронут.**
Факты: legacy `Catalog[KindSingBox].MinVersion = "1.12.0"` (комментарий —
про DNS/rule-action форматы 1.12); эталон — `1.14.3`. Комментарий в обоих
рендерах: query_server_name «exists since sing-box 1.13». Следствие:
пользовательский бинарь sing-box 1.12.x проходит `SelectEngine`
(MinVersion), и план ECH+QueryServerName отрендерится с полем, которого у
этой версии нет. Поставляемый пин — 1.14.3 (≥1.13), штатный путь не
затронут; зазор только для принесённых пользователем старых сборок и
только при заданном QSN. Усугубляет мелочь: портированный комментарий в
legacy render.go гласит «below the 1.14.3/1.15 floor, so it is always
safe to emit» — для эталона (floor 1.14.3) это правда, для legacy с её
1.12.0 — нет. Рекомендация (не блокер): поднять legacy MinVersion до
1.13+ (или до 1.14.3 вровень с пином) либо поправить комментарий;
коммит `6c13890` MinVersion не трогал — зазор унаследован, порт его
только сделал достижимым.

## 6. Непортированные тесты эталона

Причины — действительно генерационные, проверено поиском по архивной
копии legacy: `ResolveFingerprint` — **0 вхождений**, `DefaultSpiderX` —
**0**, `FingerprintPolicy` — **0** (у эталона: 22 / 7 / есть).
- `TestRenderRealityKeyShareAndPolicySpelling` (sora,
  singbox/fingerprint_censor_test.go): первая половина — key_share
  classical + unset; вторая — политика отпечатка (`hellochrome_133` →
  алиас `chrome` через ResolveFingerprint), которой в legacy как
  механизма не существует. KeyShare-половина покрыта портированными
  тестами полностью: singbox `TestCensorP1RenderKeyShare`
  (hybrid/classical/unset) + binary-accept (skip без бинаря), mihomo
  `TestRenderRealityKeyShare` (все три состояния), xray-отказ
  (`TestRenderRefusesRealityKeyShare`, 29d9cc4), гейт-половина
  `TestValidateKeyShare`. Пробела по key_share нет.
- `TestCensorP1SpiderXDefault` (sora, xray/censor_p1_render_test.go):
  пинит `engine.DefaultSpiderX` как дефолт unset-SpiderX — константы и
  дефолта в legacy нет (SpiderX рендерится verbatim, пустой опускается).
  К ECH/KeyShare отношения не имеет.

## 7. Дисциплина и регрессии

| Проверка | Результат |
|---|---|
| `git show --stat` ×5 | `4fb7874`: 2 файла (echconfig.go, echconfig_test.go); `6c13890`: 2 (singbox/render.go, render_ech_keyshare_test.go); `c12a054`: 3 (mihomo/config.go, proxy.go, render_ech_keyshare_test.go); `7a58e17`: 2 (xray/render.go, render_ech_test.go); `c3c61bb`: 7 (catalog/engine/plan/refs/validate.go, validate_ech_test.go, xray/render_keyshare_test.go) — **только заявленные файлы** |
| Чужие worktree-ханки | Суммарный список диапазона `29d9cc4..c3c61bb` — 16 уникальных файлов, все из таблицы выше; `parser.go` и `plan_internal_test.go` в коммитах **отсутствуют** (в worktree legacy они при этом грязные — `git status` показывает `M` по обоим; в коммиты не утекли) |
| `go build ./...` (архивная копия legacy) | чисто, exit 0 |
| `go vet ./engine/...` | чисто, exit 0 |
| `gofmt` по всем 16 файлам коммитов | чисто |
| Сьюты engine + singbox + mihomo + xray | singbox/mihomo/xray — полностью зелёны; engine — зелён, кроме единственного FAIL ниже |
| Полный `go test ./...` legacy | 24 пакета ok; единственный FAIL — `engine.TestTunAndFakeIPAvoidLANAndEachOther` (`tun_test.go:77: fake-IP pool overlaps an existing interface`) |
| Тот же тест на базе `29d9cc4` (до SP5-render) | FAIL с **идентичным** сообщением — известный env-артефакт VM, не регрессия пакета |
| Сьюты трёх движков на снимке эталона | зелёны (контроль, что пробы сравнивались с живым эталоном) |

## 8. Мелочи

1. **Двойной префикс в ошибках xray — паритет, не дефект порта.** Битый
   пин: `xray: outbound vless: xray: outbound vless: ech: …`; QSN:
   `xray: outbound vless: xray: outbound vless sets ECH query_server_name
   …`. Причина — два обёртывания в самом эталоне: `stream()` возвращает
   уже префиксованную ошибку (`xray: outbound %s: %w` / `… sets ECH
   query_server_name …`), а `outbound()` оборачивает ещё раз
   (`xray: outbound %s: %w`). Мои пробы дали этот текст **посимвольно в
   обоих репо**; «исправление» в legacy сломало бы паритет. Тесты обоих
   репо ассертят только подстроки (`ech:`, `query_server_name`), поэтому
   дубль тестами не виден ни там, ни там. Для симметрии: sing-box
   (`singbox: outbound <id>: ech: …`) и mihomo (`mihomo: outbound <id>:
   ech: …`) — по одному префиксу, тоже паритет.
2. **Клейм FeatureECH для xray в legacy держится на спеллинге, не на
   бинарной пробе своего пина.** Эталон клеймит по wire-пробе на 26.10.17;
   legacy поставляет 26.3.27 и рендерит идентично, но пробу на 26.3.27 не
   гонял. Это честно раскрыто в комментарии catalog.go («the wire probe
   was not re-run on 26.3.27 here») — но только там, не в сообщении
   коммита `c3c61bb`. Info/Low, остаточный риск за владельцем пина.
3. **Голый sing-box Render эмитит `key_share` и для upstream-сборок**
   (рендерер не различает форк) — как и эталон; защита — гейт §3, а не
   рендер. Паритет осознанный (тот же класс, что REVIEW-SP45 §3.3), не
   замечание к порту.
4. **Имена/комментарии снимка — аккуратны.** Legacy-комментарии
   консистентно цитируют полный хэш снимка `63faf1d3480d…`. Отдельно
   проверено утверждение legacy plan.go о том, что комментарий эталона
   про QueryServerName «stale»: в снимке sora plan.go действительно пишет
   «The Xray renderer does not emit ECH at all» при живом ECH-рендере —
   legacy-комментарий это место исправляет, а не повторяет. Правда.
5. **Раскладка тестов.** Эталон держит ECH/KeyShare-тесты внутри больших
   `render_test.go`/`censor_p1_*_test.go`; legacy вынес порты в отдельные
   `render_ech*_test.go`/`render_ech_keyshare_test.go` с сохранением
   имён тестовых функций. Косметика, навигационно даже удобнее.
   Единственное расхождение имён — xray-бэкстоп: legacy
   `TestRenderRefusesRealityKeyShare` против эталонного
   `TestCensorP1XrayRefusesKeyShare` (унаследовано от SP6b-коммита
   29d9cc4, не от SP5-render).
6. **Тест эталона `TestRenderECH` (xray) битопин-негатива не содержит** —
   legacy добавил его от себя (`not base64!!!` → отказ). Моя проба на
   эталоне дала тот же отказ посимвольно: поведение эталона тестом не
   запинено, портом — запинено. Усиление, не расхождение.
