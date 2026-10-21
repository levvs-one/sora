# REVIEW-SP6B — независимое ревью SP6b: коммиты A (8737081), B (142f3c9), C (29d9cc4) подъёма sora-legacy

Дата: 2026-10-21. Ревьюер: независимый агент (код не правил, коммитов не делал).
Объект: `sora-legacy`, ветка `bugfix/audit-2026-10-19`, HEAD `29d9cc4`.
Основания: REVIEW-SP6.md (F1–F4), REVIEW-G4.md (пункт Z1),
REVIEW-SP45.md (§6 про Identifiers/Secrets, §3.3 про render-бэкстопы).
Методика: работа только по закоммиченным состояниям — `git archive
29d9cc4` в `~/workspace/review-sp6b/legacy-head`, эталон sora —
`git archive 4fcf774b` (снимок исполнителя) в `~/workspace/review-sp6b/sora-ref`;
дополнительно сверено с текущим HEAD sora `63faf1d3` (`sora-head`):
`validate.go`, `profile.go`, `xray/render.go`, `singbox/render.go` между
4fcf774b и HEAD байт-идентичны, в mihomo изменился только класс
ssPluginOpts (к ECH/KeyShare отношения не имеет) — выводы по эталону
одинаковы на обоих снимках. Рабочие деревья не читались как источник
истины. Все поведенческие утверждения — своими прогонами (пробы в
`~/workspace/review-sp6b/probes/`, прогнаны в архивных копиях обоих
репо, после замеров из копий удалены). Go: `PATH=$HOME/workspace/go/bin`,
TMPDIR/GOCACHE на основном диске, модуль `core/go.mod`.

## Вердикты

| Коммит | Вердикт |
|---|---|
| `8737081` (A) SP6b: numeric short-id, null tls, h2-opts, отказ Clash http, F3/F4/Z1 | **Принять с замечаниями** (три Low — §7: неточность под-утверждения заголовка F4, окно точности float64, остаточные вложенные null; блокеров нет) |
| `142f3c9` (B) engine: полный состав сидов редактора | **Принять** (паритет состава доказан попольно; замечаний по существу нет) |
| `29d9cc4` (C) xray: render-отказ REALITY key_share | **Принять** (порт точный, текст ошибки эталона; классификация остающихся потерь исполнителя подтверждена) |

---

## 1. A / F1 — числовой short-id, null-блобы, атомарность

Пробы ревьюера — полным публичным путём (`ParseImport` /
`credentialDocument` → vault → `planFromProto` → `Validate`), не только
тесты коммита (все тесты коммита при этом зелёны, см. §6):

| Проба | Результат |
|---|---|
| Clash flow, `short-id: 12345678` (8 цифр) | ✅ план REALITY, sid строкой `"12345678"` в vault-документе |
| Clash block, `short-id: 1234567890123456` (16 цифр) | ✅ sid `"1234567890123456"` |
| sing-box `short_id: 12345678` (число) | ✅ sid `"12345678"` |
| `short-id: 123.5` (Clash и sing-box) | ✅ отказ импорта: «the … short-id option … is 123.5, not a short-id», `invalid_argument` — не конверсия |
| `short-id: -123` / `-5` (оба диалекта) | ✅ отказ импорта с именованной причиной |
| `short_id: 0` | ✅ конвертируется в `"0"`, документ полный (pbk/security/uuid на месте) |
| `"tls": null` / пустая строка `tls:` / `tls: false` | ✅ импорт без TLS-claim, транспорт ws и path выживают, REALITY не выдумывается |
| sing-box tls-блоб с вложенными `"reality": null, "utls": null` | ✅ не валит импорт, claim не выдумывает, `server_name` выживает; `short_id: null` → пустой sid; `utls.fingerprint: null` → пустой fp |
| Null на уровне опции для **всех** блобов (`reality-opts`, `transport`, `ws-opts`, `grpc-opts`, `xhttp-opts`, `h2-opts`, `network`, `servername` — прямой `resolveImportedSpec`) | ✅ везде «отсутствует», без ошибок |
| pbk числом (оба диалекта: `public-key: 12345678`, `"public_key":12345678`) | ✅ по-прежнему отказ: «is float64, not a string» — строгий `blobString` сохранён |

Атомарность, своя проба через публичный `ParseImport` (валидный trojan
+ плохой второй сервер): дробный sid, отрицательный sid, Clash http,
числовой pbk — во всех четырёх случаях `outbounds=0`, `store.Len()=0`,
ошибка именована. Контроль (валидный + numeric-sid) — импортируется
целиком: 2 outbound, 2 записи vault.

Остаточный зазор той же природы (Low, вне заявленного исполнителем
набора): вложенные null **внутри** tls-блоба за пределами
reality/utls — `"alpn": null` и `"insecure": null` — и `"headers":
null` в h2-opts/transport по-прежнему валят импорт shape-ошибкой
(пробы: «tls.alpn … is \<nil\>, not a string or a list», «h2-opts.headers
… is \<nil\>, not an object»). Лечится однострочными nil-гардами в
`blobStringList`/`blobBool`/`blobHeaders`; см. §7.

## 2. A / F2 — h2-opts, Clash http, sing-box http→h2

- **h2-opts извлекаются полностью** (своя проба сверх теста коммита,
  который пинит только path/host): `path` ✅, host-список → первый
  элемент ✅, `headers` ✅ — заголовки доезжают в `Transport.Headers`
  целиком (включая `X-Custom`); поле Host при этом — первый элемент
  host-списка, а `Host` из headers остаётся в карте заголовков.
- **Clash `network: http`** — отказ **на импорте**, не паника и не
  тихая потеря: `invalid_argument`, текст называет транспорт дословно
  («uses the http transport, which no engine carries (h2 is a
  different transport in the Clash dialect)»); на полном ParseImport —
  атомарно (см. §1). Работает и для сырого скаляра `network: http`
  (прямая проба resolve).
- **sing-box `transport.type: "http"` → план `h2`**: объектная форма ✅
  (path + первый host выживают), строковая форма (`"transport":"http"`
  и сырой `http`) ✅ обе мапятся. Обратный рендер: sing-box Render
  плана с `type: h2` пишет `"type":"http"` и host-список — круговая
  проба пройдена (и в эталоне тот же рендер даёт тот же спеллинг).
- **Обоснование исполнителя проверено по эталону самостоятельно:**
  (а) извлечения блобов в sora **нет вовсе** — `grep extractBlobFields/
  reality-opts/blobString` по `core/control` и `core/parser` sora@4fcf774b
  пуст; (б) whitelist транспортов обоих репо байт-в-байт один набор
  (`"", tcp, ws, grpc, h2, httpupgrade, xhttp` — `http` нет ни там, ни
  там); (в) одна и та же проба плана с `Transport.Type="http"` в
  sora даёт `Outbound.Validate`/`Plan.Validate` → «unknown transport
  "http"» — эталон отклоняет те же планы на построении сессии, как и
  заявил исполнитель. Маппинг sing-box http→h2 — переименование
  диалектов (рендерер эталона пишет h2 обратно как http), а
  Clash http→h2 был бы сменой протокола — разделение исполнителя верно.

## 3. A / F3 — сплит «форма ключа — дело Validate»

- Свои пробы + тест коммита: pbk `"AAAA"` и sid `"zzzz"` **импорт
  проходят** (`credentialDocument` без ошибки), а `planFromProto` падает
  с текстами «REALITY public key is not a 32-byte base64url X25519 key» /
  «REALITY shortId must be hex, at most 8 bytes». Тексты сверены grep-ом
  по обоим репо: строки в `engine/reality.go` legacy и sora идентичны.
- Комментарий сплита у `resolveImportedSpec` соответствует факту во
  всех частях: на импорте отказывается только отсутствие ключа при
  заявленном REALITY; формы не проверяются; утверждение «the reference's
  import performs no form check at all» — правда сильнее буквальной:
  у эталона импортного blob-пути нет вовсе, а его Validate даёт те же
  тексты. Сплит запинен тестом `TestImportedMalformedRealityFailsAtValidate`
  (зелёный, обе ветки).

## 4. A / F4 — заголовок resolveImportedSpec построчно

Прямые пробы `resolveImportedSpec` с типизированными полями против блобов:

| Утверждение заголовка | Факт пробы | Вердикт |
|---|---|---|
| Скаляры: типизированные побеждают блоб | pbk, sid, server_name, fingerprint, path, host, service_name, mode, ALPN — все 9 типизированных значений уцелели против блобных | ✅ точно |
| Transport — исключение, блоб всегда | типизированный `tcp` заменён блобным `ws` | ✅ точно |
| REALITY-claim бьёт метку `tls` | `tls` + reality-opts → `reality`; `tls` + reality внутри tls-блоба → `reality` | ✅ точно |
| «any other typed security, including an explicit "none", keeps winning over the blob's label» | `none` + tls-блоб → `none` ✅; **но** `none` + reality-opts → **`reality`** (pbk импортирован) | ⚠️ **неточно** |

Свитч в коде ключится на `f.security == "reality"` безусловно, поэтому
REALITY-claim перекрывает **любую** типизированную метку, включая явный
`none`, а не только `tls`. Заголовок в этой под-фразе обещает обратное —
та же природа неточности, которую F4 просил убрать. Поведение само по
себе защитимо (reality-opts — сильный claim; комбинация «типизированный
none + reality-блоб» парсером недостижима, что заголовок честно оговаривает
про исключения в целом), серьёзность — **Low, документация**. Рекомендация:
одна строка правки заголовка («a REALITY claim outranks any typed label;
any other blob label loses to any typed security, including "none"»).
Сюда же, мельче: монотонность insecure (блоб может только включить
поверх типизированного false) заголовком не упомянута — унаследовано из
исходного комментария, не регрессия A.

## 5. A / Z1 — AllowInsecure классического VMess

Тест коммита `TestParseClassicVMessAllowInsecure` зелёный. Свои
дополнительные формы (та же проба, классический блоб): `2` → true,
`-1` → true, `"True"` → true, `"0"` → false, `"FALSE"` → false,
`allowInsecure:"1"` при `insecure:false` → true (спеллинги объединяются
через OR), `allowInsecure:0` при `insecure:true` → true, `0.0` → false,
`null` → false. Все исходы следуют из `jsonBool` (float != 0;
`"1"`/EqualFold `"true"`), функция байт-идентична эталону (REVIEW-G4).
Комментарий теста описывает множество истинности точно.

## 6. B — состав сидов редактора (142f3c9)

**Попольная сверка, а не по списку исполнителя.** Одна и та же проба
(рефлексия + максимальный outbound + profile JSON с вариантными
спеллингами) прогнана без изменений в обоих репо; списки выведены и
сравнены целиком:

- `Secrets()`: legacy = sora **значение-в-значение и в том же порядке**,
  за двумя исключениями — у sora дополнительно `Token` (после
  PluginOpts) и `Amnezia.HeaderProtectionKey` (после PrivateKey).
- `Identifiers()`: идентично, за двумя исключениями — у sora
  дополнительно `TLS.RealityMLDSA65Verify` (после RealityShortID) и
  `Transport.GRPCAuthority` (после Service).
- Перечень непортированного исполнителя проверен фактом по типам:
  все четыре поля **отсутствуют в типах legacy** (рефлексия пробы +
  дамп структур `Outbound`/`TLS`/`Transport`/`AmneziaWG` обоих репо).
  Других расхождений состава нет: ни одного поля, которое эталон
  регистрирует, а legacy (при наличии поля в типе) — нет, и наоборот,
  кроме одного пункта ниже. Заявленные «точные спеллинги 11 →
  нормализованные 20 ключей» подтверждаются: `profile.go` legacy
  байт-идентичен sora, кроме одной строки комментария («…, ported from
  sora»); 20 нормализованных secret-ключей + 7 identifier-ключей,
  `normalizeProfileKey`/`profileWalk`/`profileSecrets`/`profileIdentifiers`
  портированы целиком.
- **Legacy-суперсет `OriginalLink`**: единственное обратное расхождение.
  Оценка: **нейтрально, не вред и не мёртвый код в плохом смысле** —
  поле в `plan.go` явно задокументировано как reserved («appears only
  in the secret-candidate list … and is never assigned», помечено ещё
  pass2-detail коммитом e39fa15), пустое значение отсекается фильтром
  `len>=4`, а если поле когда-нибудь начнут присваивать, маскировка
  сработает в безопасную сторону. В скоуп B не входит; удалять не нужно.
- **Детерминизм**: тесты коммита прогнаны `-count=5` — без флейка;
  своя проба — 50 итераций в одном процессе (карта Headers из 3 ключей
  + profile): списки стабильны; механизм — сортировка ключей Headers в
  `Secrets()` и сортированный обход в `profileWalk`, оба на месте.
- **Сквозная проба**: `TestRedactorMasksTransportSeeds` (коммит) зелёна
  в том же прогоне: plan с Host/Service/Path/Headers → редактор,
  засеянный как `Supervisor` (Secrets+Identifiers), маскирует строку
  со всеми четырьмя значениями. Существующие тесты пакета engine не
  покраснели (полный прогон §8: в engine единственный FAIL — известный
  env-артефакт TUN, не связанный с B).

## 7. C — render-бэкстоп xray KeyShare (29d9cc4) и остающиеся потери

- Своя проба голого `Render` в обеих копиях: KeyShare `hybrid` и
  `classical` → отказ, текст **байт-в-байт равен эталонному**: «xray:
  outbound %s pins a REALITY key_share, which Xray does not expose (the
  fingerprint parrot decides the key share); use the sing-box or mihomo
  engine». Контроль без KeyShare рендерится. Тест коммита зелёный.
- Утверждение «у эталона ровно один render-отказ по этим классам»
  проверено поиском по всем трём рендерам sora@4fcf774b (и HEAD — без
  изменений в этих классах): в классах потерь из REVIEW-SP45 §3.3 это
  так — KeyShare рендерится эталоном на sing-box (`key_share`) и
  mihomo (`support-x25519mlkem768`), ECH рендерится на всех трёх,
  отказов там нет. Две точности ради честности картины (вывод C не
  меняют): (а) у эталона есть ещё отказ xray на ECH `query_server_name`
  — это под-случай **рендерящегося** ECH, а не класс потери; портировать
  его в legacy без ECH-рендера было бы мёртвым кодом; (б) отказ sing-box
  на ML-DSA-65 verify — другой класс, поля в legacy нет.
- **Остающиеся потери голого `Render` в legacy — классификация
  подтверждена одинаковыми пробами в обоих репо:**

  | Потеря | sora, голый Render | legacy, голый Render | Класс |
  |---|---|---|---|
  | xray: stray xmux/padding на ws | молча теряет (err=nil) | молча теряет | **паритет** |
  | sing-box: download-split | молча теряет (err=nil, адреса нет) | молча теряет | **паритет** |
  | ECH (xray/sing-box/mihomo) | **рендерит** (echForceQuery / ech / ech-opts) | молча теряет везде | **фича-разрыв, не паритет** |
  | KeyShare на sing-box/mihomo | **рендерит** (key_share / support-x25519mlkem768) | молча теряет | **фича-разрыв, не паритет** |

  Исполнитель заявил классификацию честно и точно. Фактическая
  серьёзность разрывов ограничена: продакшен закрыт гейтом —
  `RequiredFeatures` требует `ech`/`reality-key-share`, ни один legacy-
  движок их не заявляет (grep по catalog пуст; комментарии engine.go/
  plan.go это фиксируют), `Supervisor.admit` стоит перед любым Render
  на продакшен-пути (REVIEW-SP45 §3.3/§4.3, перепроверено поиском).
  Это бэклог портов рендеров (фичи), а не дефект безопасности; решение
  о порте — за координатором, как и было поставлено.

## 8. Дисциплина и регрессии

| Проверка | Результат |
|---|---|
| `git show --stat` трёх коммитов | A — ровно 4 заявленных файла; B — ровно 3; C — ровно 2 (render.go + новый render_keyshare_test.go). Чужих файлов нет |
| Чужие worktree-ханки | В коммиты **не попали**: worktree несёт `parser.go` (пустая строка у `getq`), `plan_internal_test.go` (убрана пустая строка), `catalog.go` и `redact.*` — ни одного из этих файлов в списках трёх коммитов нет; все три коммита собраны из закоммиченного состояния |
| `go build ./...`, `go vet ./...` (архив HEAD) | чисто; vet по затронутым пакетам перепрогнан отдельно — чисто |
| Полный `go test ./...` (архив HEAD `29d9cc4`) | все пакеты ok; единственный FAIL — `engine.TestTunAndFakeIPAvoidLANAndEachOther` («fake-IP pool overlaps an existing interface») — разрешённый env-артефакт VM, тот же FAIL на чистом baseline по REVIEW-SP45 |
| Целевые тесты коммитов | A: все 8 тестов/поднаборов SP6b зелёны (numeric-survives ×4, fractional, null-tls ×3, h2, http-refused, singbox-http, malformed×2, ParseImport-подписка); B: 4 теста `-count=5` зелёны; C: зелёный; Z1: зелёный |
| `gofmt -l` по 9 файлам коммитов | пусто (чисто) |

## 9. Мелочи

1. **blobShortID и точность float64 — посылка «отклоняется уже
   Validate» верна лишь частично; есть контрпример.** Тремя
   независимыми пробами (прямой resolve, vault-документ, план):
   sid `9007199254740993` (2^53+1) импортируется как `"9007199254740992"`
   — **другой** sid, 16 hex-цифр, `plan.Validate()` проходит (nil).
   Длинные случаи Validate действительно отклоняет, но по длине, а не
   по точности: `9999999999999999` → `"10000000000000000"` (17 цифр,
   отказ), `12345678901234567890` → `"12345678901234567168"` (отказ).
   Молчаливое окно — интегральные sid из [2^53, 10^16), чья округлённая
   форма остаётся 16-значной. Практический риск ничтожен (числовой sid
   такого размера — провайдер, записавший 8-байтный sid голым десятичным
   числом ≥ 9×10^15; реальные числовые sid малы), поэтому это **не
   блокер A**, но честный фикс дёшев и «раньше»: потеря происходит в
   `optionBlob` (`json.Unmarshal` → float64), при этом сырая строка
   Options цифры сохраняет точно (проба: Options содержит
   `9007199254740993` дословно) — `json.Decoder.UseNumber` в optionBlob
   или отказ при `|n| >= 2^53` в blobShortID закрывают окно полностью.
   Рекомендую follow-up микрокоммитом; формулировку «Validate
   отклоняет» как общее утверждение не принимать.
2. **Вложенные null — «бонус F5 по соседству» или самовольство: по
   существу — в скоупе.** Null на уровне опции для всех блобов — это и
   есть лечение F1 (REVIEW-SP6 прямо требовал «null-блобы трактуются
   как отсутствующие»), не бонус. Гарды `reality`/`utls` внутри
   tls-блоба — тот же класс дефекта одним уровнем глубже: sing-box
   документ с `"reality": null` — реалистичный спеллинг провайдера, и
   без гарда он валил бы всю подписку, против чего направлен весь F1.
   Риск изменения минимален (null → отсутствие, claim не выдумывается —
   пробами подтверждено). Остаток класса (alpn/insecure/headers null,
   §1) — Low follow-up, а не претензия к A.
3. **Заголовок F4**: одна под-фраза про `none` неточна (§4) — Low,
   документация; поправить одной строкой при следующем касании файла.
4. Для симметрии фиксирую точное: комментарии тестов B и C (список
   отсутствующих полей эталона; почему для sing-box/mihomo бэкстоп не
   портируется) проверены фактом и **верны дословно** — неточность
   исполнителя нашлась только в п.1 и п.3 выше.
