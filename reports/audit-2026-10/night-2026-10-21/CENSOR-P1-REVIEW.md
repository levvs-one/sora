# CENSOR-P1 — независимое ревью (VLESS+REALITY+Vision, XHTTP)

Ревьюер: независимый, код не правил, коммитов не делал, пуша не было.
Объект: коммиты `4aa6b9f3, d68fce9b, 75fbfd8b, 9d6bd2ef, 6038af81,
4fcf774b, ec1459f0`, отчёт автора `CENSOR-P1.md`.
Проверялся **чистый экспорт HEAD на старте ревью — `ec1459f0`**
(`git archive`, не грязное рабочее дерево). Во время ревью HEAD
сдвинулся соседями: `db451d03…3b003e8b` (P4) и `63faf1d3` (FP,
фикс п.3 — см. ниже); все выводы по содержанию сверены с `ec1459f0`,
для п.3/п.4 дан повторный прогон на `63faf1d3`.
Пины: sing-box-lx lx.22, Xray 26.10.17, mihomo 1.19.32
(`~/workspace/.engines-amd64`). Go 1.24.7.

## ИТОГОВЫЙ ВЕРДИКТ: ОТКЛОНИТЬ (точечно)

Ядро работы принято без замечаний (пп. 1, 2, 6, 7 — трафиком,
бинарными пробами и мутацией). HEAD не принимается в текущем виде
из-за двух оставшихся дефектов, оба — собственные P1:

- **T1 (High):** `TestCatalogXmuxClaimMatchesRenderers` красный и на
  `ec1459f0`, и на текущем `63faf1d3` — пакет `core/engine` не зелёный.
- **T2 (Medium):** импорт `extra=`: типово-битая секция молча роняет
  все остальные секции, вопреки собственному комментарию в коде.

П.3 (KeyShareGate) на проверявшемся снапшоте был красным по вине FP
и **закрыт самим FP коммитом `63faf1d3` во время этого ревью** —
перепроверено, тест зелёный.

## Таблица вердиктов 1–8

| # | Пункт | Вердикт |
|---|-------|---------|
| 1 | Баг mux×XHTTP | **ПРИНЯТЬ** |
| 2 | mldsa65 end-to-end | **ПРИНЯТЬ** (позитивный handshake — эскалация, см. ниже) |
| 3 | KeyShareGate | **ПРИНЯТЬ на текущем HEAD**; на `ec1459f0` был **ОТКЛОНЁН** (остаток FP, закрыт `63faf1d3`) |
| 4 | Xmux-противоречие | **ОТКЛОНИТЬ**: прав каталог/рендер, красный тест — недоведённый коммит P1 `75fbfd8b` |
| 5 | XHTTP паритет и импорт | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** (Medium T2 + Low по mihomo padding) |
| 6 | REALITY completeness | **ПРИНЯТЬ** |
| 7 | Адаптивность | **ПРИНЯТЬ** |
| 8 | Мелочи | **ПРИНЯТЬ С ЗАМЕЧАНИЯМИ** (Info: gofmt-претензия автора не подтвердилась) |

## 1. Баг mux×XHTTP — ПРИНЯТЬ

- Предикат — один источник: `core/engine/mux.go:63`
  `RealityMux = Reality && !Disabled && !IsVisionFlow && Transport.Type != "xhttp"`.
  Все три рендера зовут только его: `xray/render.go:284`,
  `singbox/render.go:410`, `mihomo/proxy.go:196`. Своих mux-условий
  в рендерах нет (grep по дереву).
- Pre-fix семантика по истории: `git show 6038af81^:mux.go` — предикат
  был без `xhttp`; фикс `6038af81` добавил ровно одно условие.
  Vision-исключение существовало до фикса и не тронуто
  (`TestRealityMuxExcludesVision` — PASS).
- Не-XHTTP поведение не изменилось: `TestCensorP1RealityMuxExcludesXHTTP`
  (PASS) пинит mux=true для `"", ws, grpc, httpupgrade`.
- Трафик (перепрогон ревьюера, `SORA_ENGINES_DIR` на пинах):
  `TestXHTTPTuningThroughEveryEngine` — **PASS**: sing-box (6.41 c)
  и Xray (2.06 c) несут не-vision REALITY+XHTTP план с xmux 16/10 и
  padding 100-1000 против Xray-сервера **без ручного подавления mux**;
  негатив по неверному UUID — трафика нет. Именно этот план до фикса
  был сломан дефолтом.

## 2. mldsa65 end-to-end — ПРИНЯТЬ

- Собственная проба пина: `xray mldsa65` → Verify 2603 символа /
  1952 байта после base64url-декода — совпадает с
  `mldsa65VerifyKeyBytes=1952` (`reality.go:486`) и валидацией формы.
- Бинарный тест автора с ключом от самого бинаря:
  `TestBinaryAcceptsMLDSA65Verify` — **PASS (6.55 c)**,
  `xray run -test` принимает рендер.
- Рендер в обеих ногах: `TestRenderMLDSA65Verify` и
  `TestRenderMLDSA65VerifyOnDownloadLeg` — PASS, ключ встречается в
  рендере ровно 2 раза (основной stream + downloadSettings),
  `xray/render.go:386,543`.
- Битый ключ: план — `TestValidateMLDSA65Verify` PASS (`AAAA`,
  усечение до 2600, не-base64url — отказ; ошибка `reality.go:428`
  содержит только outbound ID, не значение). Собственная проба
  бинаря: `AAAA` — отказ загрузки; мусор правильной длины бинарь
  принимает (проверка только формы) — план ведёт себя так же,
  расхождения нет.
- Fail-closed: sing-box рендер — отказ (`singbox/render.go:392-397`,
  только ID); mihomo — план-гейт **и** отказ рендера
  (`mihomo/proxy.go:457-463`; автор писал только про гейт — по факту
  сильнее). Каталог: claim `FeatureRealityMLDSA65` только у Xray
  (`catalog.go:127`).
- Redactor: ключ попал в `Identifiers()` (`validate.go`,
  appendIdentifiers — рядом с RealityPublicKey/ShortID), тест
  `TestMLDSA65VerifyIsIdentifier` PASS. В `Secrets()` ключа нет —
  это публичный verify-ключ, автор заявлял именно Identifiers;
  соответствует заявленному.

## 3. KeyShareGate — на ec1459f0 КРАСНЫЙ (остаток FP), на текущем HEAD зелёный

- На чистом `ec1459f0`: `TestCensorP1KeyShareGate` — **FAIL**,
  `reality_censor_test.go:126`: mihomo «spells key_share and must not
  report it missing: "feature reality-key-share"».
- Причина: в `Catalog[KindMihomo]` не было `FeatureRealityKeyShare`
  (у sing-box был, `catalog.go:91`), хотя mihomo-рендер ключ пишет
  (`mihomo/proxy.go:483`, `reality-opts.support-x25519mlkem768`,
  `config.go:260`), а `probecaps.go:62-71` в комментарии утверждает,
  что несут оба движка.
- Это не только юнит-тест: интероп автора
  `TestRealityKeyShareThroughSingBoxAndMihomo` на `ec1459f0` —
  **FAIL** на селекции: `censor_p1_test.go:394: mihomo must carry
  the key_share plan: … cannot carry feature reality-key-share`
  (sing-box сабтест PASS, 12.13 c). То есть утверждение отчёта
  автора «KeyShare=hybrid: mihomo ✓ трафиком» на HEAD `ec1459f0`
  **не соответствовало факту**: план с KeyShare на mihomo вообще
  не роутился.
- **Строка закрытия: остаток FP — гейт `FeatureRealityKeyShare`
  заведён коммитом FP `5b6337fa` с клеймом только для sing-box;
  тест P1 `d68fce9b` прав и ловил именно это.**
- Закрытие во время ревью: FP коммит `63faf1d3` (23:00:29 UTC,
  «claim FeatureRealityKeyShare for mihomo … catalog silence kept
  TestCensorP1KeyShareGate red») добавил клейм (`catalog.go:55`).
  Перепрогон ревьюера на чистом экспорте `63faf1d3`:
  `TestCensorP1KeyShareGate` — **PASS**.

## 4. Xmux-противоречие — ОТКЛОНИТЬ (тест врёт, каталог прав)

- На чистом HEAD (и `ec1459f0`, и `63faf1d3`):
  `TestCatalogXmuxClaimMatchesRenderers` — **FAIL**:
  `engine_test.go:475: xray claims FeatureXHTTPXmux but its renderer
  emits no xmux`; `engine_test.go:492: xray: xmux plan must report
  xhttp-xmux missing, got ""`.
- По факту бинарей права сторона каталога/рендера:
  `TestCensorP1BinaryAcceptsXHTTPTuning` — PASS для Xray
  (`run -test`, 4.07 c) и sing-box (`check`, 1.89 c): xmux и
  padding рендерятся и принимаются пинами. Padding — отдельный
  гейт: `FeatureXHTTPPadding` (`refs.go:85` отдельно от xmux
  `refs.go:73-75`; `TestXPaddingBytesGate` PASS).
- Причина красного теста — собственный недоведённый коммит P1:
  `git show 75fbfd8b -- core/engine/engine_test.go` меняет в тесте
  **только комментарий** (новая правда: все три рендера эмитят xmux,
  Xray/mihomo клеймят статично, sing-box — probed), а **тело теста
  осталось до-P1**: «клеймить может только mihomo; Xray и sing-box
  обязаны репортить missing». Тело противоречит собственному
  комментарию в том же файле (`engine_test.go:462-472`).
- Фикс за P1: переписать тело под комментарий (Xray+mihomo — claim,
  sing-box static — missing, sing-box lx+with_xhttp — claim).

## 5. XHTTP паритет и импорт — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

Паритет — PASS:

- Рендеры всех трёх движков и пробы: xray и sing-box —
  `TestCensorP1BinaryAcceptsXHTTPTuning` PASS (см. п.4); mihomo —
  `TestBinaryAcceptsXHTTPDownloadSettings` PASS (8.64 c).
- **Low:** проба mihomo слабая по построению — сам автор фиксирует,
  что mihomo молча игнорирует неизвестные ключи, а план в
  `binary_xhttp_test.go` не содержит `XPaddingBytes` вовсе:
  mihomo-padding подтверждён только строкой рендера
  (`mihomo/render_test.go:398-400`), не бинарём.

Импорт extra= — **Medium (T2)**, собственная мутация ревьюера
в копии дерева (`/tmp`, тест `TestZZReviewExtraMalformedSection`):

- Авторские тесты PASS, но покрывают только семантически пустой
  downloadSettings и мусорный JSON целиком.
- Типово-битая секция роняет **все** секции:
  `{"xmux":{"maxConcurrency":8},"xPaddingBytes":123}` → xmux=0;
  `{"downloadSettings":{"address":"dl.example.com","port":"443"},…}`
  (port строкой) → xmux=0, split потерян;
  `{"xmux":"oops","xPaddingBytes":"0-100"}` → padding потерян.
- Причина: `parser.go` `applyExtra` — один `json.Unmarshal` в
  `extraParams` и `return` при любой ошибке типа, при собственном
  комментарии «Each section applies independently — a missing,
  malformed, or unusable section is ignored without taking the
  others down». Молчаливая потеря тюнинга/сплита — тот класс
  дефектов, ради которого P1 и делался. Канонические формы пинов
  (числа, строки-диапазоны) не затронуты — потому Medium, не High.
  Фикс: декодировать секции независимо (`map[string]json.RawMessage`).

Прочее по п.5 — PASS:

- Диапазоны xmux по нижней границе — осознанно и задокументировано:
  `parser.go` `xmuxRangeValue` (комментарий), `parser_extra_test.go`
  («16-32» → 16).
- Кред-документ: `TestCredentialDocumentMatchesLegacyMapForm` на
  чистом HEAD — **PASS** (перепрогон, короткий TMPDIR); untuned
  документ байт-идентичен legacy-форме, `itoaNonZero` —
  `control/plan.go:195-198,720-724`, коммит `ec1459f0` подтверждён.

## 6. REALITY completeness — ПРИНЯТЬ

- SpiderX: собственные пробы ревьюера на пине Xray (ручной конфиг,
  без sora-кода): без ведущего `/` — отказ загрузки
  (`invalid "spiderX"`); `/a b`, `/a?x=1#y`, 8000 и 8001 символ —
  `Configuration OK`. План валидирует ровно слеш
  (`TestCensorP1SpiderXValidation` PASS) — ни шире, ни уже бинаря.
- Warning-коды фингерпринта (`reality-fingerprint-randomized`,
  `-stale`, `-no-pq-key-share`, `reality.go:96-102`) grep'ом по
  дереву ни с одним существующим кодом SURV/P1 не пересекаются
  (соседние семейства: `reality-dest-*`, `reality-shortid-*`,
  `reality-without-vision` — все различны).
- Единые источники: `DefaultSpiderX` (`reality.go:57`) и
  `DefaultXHTTPMode` (`plan.go:30`) — единственные определения;
  литеральных дублей в рендерах нет (grep: обе ноги Xray используют
  `DefaultSpiderX`, Xray и sing-box — `DefaultXHTTPMode`).
- shortId: собственная проба — 17 hex и 18 hex — отказ загрузки
  Xray; 16 и 2 — OK. Границы плана совпадают
  (`TestCensorP1ShortIDBoundaries` PASS: 0/2/16 ok; нечёт/18/не-hex —
  ошибка).

## 7. Адаптивность — ПРИНЯТЬ

- Sing-box xmux/padding клеймы живут в `BuildCapabilities`
  (`catalog.go:244-250`): `FeatureXHTTPXmux = FeatureXHTTPPadding =
  slices.Contains(tags, "with_xhttp")`, статично в каталоге их нет.
- Мутация ревьюера (копия дерева в /tmp, тест на
  `BuildCapabilities(KindSingBox, lx.22, tags)`): с тегом
  `with_xhttp` — оба клейма true; **без тега — оба падают** вместе
  с `FeatureXHTTP`, и `Missing()` tuned-плана репортит обе фичи,
  т.е. проба реально определяет claim и гейтит план — **PASS**.
- Остальные клеймы зоны (Xray/mihomo xmux+padding, mldsa) —
  статичные данные пинов, каждый с бинарным тестом-трипваером
  (перечислены в пп.2,4,5; все перепрогонены зелёными).

## 8. Мелочи — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

- Детерминизм: перепрогон ×3 движка — PASS:
  `TestCensorP1RenderDeterministic` (xray), он же в singbox,
  `TestCensorP1RenderDeterministicXHTTP` (mihomo); рендеры
  XHTTP+REALITY байт-идентичны.
- Утечки: вектор `leakme` для spiderX перепрогонен —
  `TestCensorP1SpiderXValidation` PASS, значения в ошибке нет;
  mldsa-ошибки и KeyShare-отказ Xray (`xray/render.go:213-220`)
  содержат только outbound ID (чтение кода + тесты).
- Границы из отчёта автора покрыты и проходят на чистом HEAD:
  xmux 0/1/128/129(warning, не ошибка)/−1/взаимоисключающая пара —
  `TestCensorP1XmuxBoundaries` PASS; padding 0, 0-0, 65535 — ok,
  65536, инверсия, мусор — ошибка —
  `TestCensorP1PaddingBoundaries` PASS.
- **Info (претензия автора не подтвердилась):** «косметический
  gofmt-дефект у vmessBlob в `9d6bd2ef`» — `gofmt -d` по
  `core/parser/parser.go` **пуст и в коммите `9d6bd2ef`, и в HEAD**;
  там ровно одна стандартная пустая строка перед комментарием
  `vmessBlob` — это gofmt-норма, дефекта в HEAD нет, тяжесть нулевая.

## Эскалации автора — выборочная проверка

1. **ML-DSA stock↔stock — по гейту подтверждено, своей голой пробой
   не воспроизведено.** Прогон с `SORA_INTEROP_MLDSA_LIVE=1` в
   песочнице — **FAIL**: позитивная нога падает на
   `censor_p1_test.go:200` (`request through xray with
   mldsa65Verify: status 503`), т.е. handshake не завершается и через
   sora-клиент против ручного стокового сервера. Без флага тест
   PASS: enforcement-нога честна (план без verify против seeded
   сервера трафика не несёт), позитив заскипан с логом. Собственные
   голые пробы ревьюера (сток Xray↔Xray, dest на openssl и на Go с
   форсированной/дефолтной кривой X25519MLKEM768, fingerprint
   chrome и hellochrome_auto) ML-DSA **не вовлекли вовсе**:
   трафик нёс и неверный verify — в этих конфигурациях verify не
   консультируется, поэтому они ни подтверждают, ни опровергают
   репро автора с его форсировкой группы. Итог: позитивный ML-DSA
   handshake в песочнице **не доказан никем**, гейт теста честен,
   проверка на dev-машине остаётся обязательной; дефекта кода P1
   из доступных доказательств не следует.
2. **Mihomo REALITY vs Xray-сервер — pre-existing, не P1:
   подтверждено.** `interop_test.go:530-539` (до-P1 файл) фиксирует
   то же; основная матрица водит mihomo через sing-box сервер и на
   перепрогоне ревьюера зелёна (см. статус тестов). P1-поверхность
   (XHTTP) при этом у mihomo покрыта selection+render — а для
   KeyShare-планов селекция на `ec1459f0` была сломана п.3, это
   отдельный дефект каталога, не эта эскалация.

## Статус ранее падавших тестов зоны на чистом HEAD

| Тест | ec1459f0 (снапшот ревью) | 63faf1d3 (текущий HEAD) |
|---|---|---|
| `TestCensorP1KeyShareGate` | **FAIL** (mihomo claim) | PASS (фикс FP) |
| `TestCatalogXmuxClaimMatchesRenderers` | **FAIL** (устаревшее тело) | **FAIL** (тот же) |
| `TestRealityKeyShareThroughSingBoxAndMihomo` (interop) | **FAIL** (селекция mihomo; sing-box PASS) | не перепрогонялся (причина устранена тем же коммитом) |
| `TestRealityMLDSA65ThroughXray` (без LIVE) | PASS (enforcement + skip позитива) | — |
| `TestRealityMLDSA65ThroughXray` (LIVE=1) | FAIL (позитивная нога, status 503; эскалация 1) | — |
| `TestXHTTPTuningThroughEveryEngine` | PASS (sing-box, xray) | — |
| `TestRealityThroughEveryEngine` | PASS при TMPDIR на диске (первый FAIL — `/tmp` no space, среда) | — |
| `TestCredentialDocumentMatchesLegacyMapForm` (control) | PASS standalone | — |
| `TestDetectCensorshipEventsWithoutOffsetsStayUnknown` (control, сосед) | PASS standalone; в полном пакете FAIL только из-за длины unix-сокета при длинном TMPDIR (`censor_test.go:210`, bind invalid argument) — среда, не P1 | — |
| `TestSelectEngineProbedPrefersFact` (FP) | PASS (в полном прогоне engine) | — |
| Остальные пакеты `engine/…`, `parser` | PASS (единственные FAIL — два теста выше) | — |

## Замечания по серьёзности (сводно)

- **High — T1:** красный `TestCatalogXmuxClaimMatchesRenderers`
  на текущем HEAD; тело теста не обновлено коммитом `75fbfd8b`
  (обновлён только комментарий). Владелец: P1.
- **High → закрыто во время ревью:** отсутствующий клейм
  `FeatureRealityKeyShare` у mihomo (селекция + интероп красные,
  расхождение с отчётом автора). Владелец: FP; закрыто `63faf1d3`.
- **Medium — T2:** `extra=` импорт: типово-битая секция молча
  роняет все секции (`parser.go` `applyExtra`), вопреки
  документированной независимости. Владелец: P1.
- **Low:** mihomo `xPaddingBytes` не покрыт бинарной пробой
  (рендер-строка только; `mihomo -t` неизвестные ключи не ловит).
- **Info:** gofmt-претензия к `vmessBlob` не подтвердилась;
  позитивный ML-DSA handshake в песочнице не доказан (эскалация 1
  остаётся открытой для dev-машины — честно).

## Дисциплина / окружение

- Ревью шло по чистым экспортам в /tmp и на домашнем диске;
  рабочее дерево и индекс не трогал, коммитов нет.
- Индекс: на старте ревью staged был пуст. В конце ревью в общем
  индексе снова staged (`core/engine/catalog.go`, в полёте у FP) и
  HEAD сдвинут соседями до `63faf1d3` — зафиксировано, не тронуто.
  Ранее в течение ревью наблюдался staged-набор из 16 файлов
  (P4-фиксы), впоследствии уехавший коммитами `db451d03…3b003e8b`.
- `/tmp` в середине ревью был переполнен чужими файлами (97–100%),
  один прогон Reality-матрицы упал по `no space left on device` —
  среда, перепрогоном с TMPDIR на домашнем диске снято.
