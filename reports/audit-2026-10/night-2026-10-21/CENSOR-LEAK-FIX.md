# CENSOR-LEAK-FIX — фикс замечаний ревью CENSOR-LEAK-REVIEW

Фиксер по ревью `CENSOR-LEAK-REVIEW.md` (вердикт «ПРИНЯТЬ С
ЗАМЕЧАНИЯМИ»). Ветка `bugfix/audit-2026-10-19`, строго локально, без
пуша. Все шесть пунктов закрыты; два остаточных подкласса честно
зафиксированы в §3 с обоснованием.

Коммиты (temp-index + CAS по AGENTS.md; состав каждого сверен
`git diff --cached --stat` до коммита — только свои файлы, чужие
staged/WIP не тронуты; оба коммита — предки текущего HEAD, поверх
уже лёг коммит соседа):

- **bc54d959** `[censor] CENSOR-LEAK fix: redactor idempotence …` —
  пп. 1, 2, 3 (код+тесты редактора) и корпус FuzzRedactor из п. 6.
  23 файла: `core/engine/redact.go`, `redact_test.go`,
  `redact_corpus_test.go`, 20 файлов
  `core/engine/testdata/fuzz/FuzzRedactorNoPanicAndIdempotent/`.
- **4530e1f9** `[censor] CENSOR-LEAK fix: obfs fail-closed tests
  bounded …` — п. 5 и корпуса FuzzParseLink/FuzzDetect из п. 6.
  18 файлов: `core/obfs/conn_test.go`, 17 файлов
  `core/parser/testdata/fuzz/…`.

П. 4 — правка `CENSOR-LEAK-LOG-DICT.md` (файл отчётов, вне git).

## 1. [Medium] FuzzRedactor: неидемпотентность на `token  ""0` — ЗАКРЫТО

Корень (подтверждён щупом до фикса): альтернатива quoted-значения в
`keyValuePattern`/`strictKeyValuePattern` останавливалась на
закрывающей кавычке. Приклеенный без пробела суффикс оставался в
выводе (`token: "abc"def` → `token: [masked]def`, `token  ""0` →
`token  [masked]0`), а на втором проходе `\S+`-альтернатива съедала
`[masked]` вместе с суффиксом как «значение» — вывод менялся.
Класс, а не инпут: падали все формы с любым непробельным суффиксом
(буквы, цифры, `,`, `]`, `)` — 11/11 пробных соседей).

Фикс из двух половинок, обе в `core/engine/redact.go`:

1. **Приклеенный суффикс — часть значения.** Quoted-альтернативы
   получили хвост `[^\s,;}\]\)]*` после закрывающей кавычки:
   символы без пробела до структурного разделителя потребляются в
   ту же маску (`""0`, `"abc"def`, `"a"b`, `"a.example"443`).
   Хвост останавливается на `, ; } ] )`, чтобы разделители
   компактного JSON не съедались.
2. **`[masked]`-гард.** Проходы key-value идут через новый
   `replaceKeyValues`: матч, чьё значение уже начинается с
   `[masked]`, копируется как есть. Суффикс за структурным
   разделителем (`token: "abc",` → `token: [masked],`) на втором
   проходе заморожен гардом, а не съеден — идемпотентность и
   сохранность пунктуации одновременно.

Регрессия: `TestRedactorIdempotentQuotedSuffix` — 12 форм (краш-инпут,
пустые кавычки обоих видов + суффиксы `0`/`x`/`0abc`, непустые +
`def`/`b`/`443`, разделители `,`/`]`/`)`), точный первый проход +
`maskPatterns(maskPatterns(x)) == maskPatterns(x)` + идемпотентность
`Redactor.String`. Краш-инпут и соседи добавлены в f.Add сиды и в
файловый корпус (п. 6). Дифференциальный тест
`TestMaskPatternsDifferential` обновлён: референс вызывает тот же
`replaceKeyValues` (тест пинит гейт, а не механику замены — сказано
в его комментарии).

Доказательство: `go test ./engine/ -run 'TestRedactor|TestMask'`
зелёный; фузз-перепрогон **20 с, 11 638 execs, PASS** (ревьюер ловил
краш за ~4,8 с / 393 execs).

## 2. [Medium-Low] Uppercase-hex сида — ЗАКРЫТО

`derivedForms` добавляет `strings.ToUpper(hex)` рядом с lowercase.
Тот же принцип применён во всех перекодировках, где регистр —
свобода энкодера: percent-формы получили полное кодирование в обоих
регистрах (п. 3), `\uXXXX`-формы — оба регистра hex-цифр (в
`json.Marshal`-форме через `upperUnicodeHexDigits`, в полной и
одиночных — аналогично). Base64 регистро-зависим по построению
(другой регистр = другие байты) — вариантов не существует, это не
пробел.

Про mixed-case: реальные энкодеры консистентны внутри одной строки
(Go hex — lower, `%X`-форматтеры — upper), поэтому чистые upper/lower
формы покрывают класс; покарактерно смешанный регистр потребовал бы
энкодера-рандомизатора, которого нет — остаток зафиксирован в
комментарии `derivedForms` и в §3 ниже.

Тесты: `TestRedactorEncodedSeedForms` — формы `hex upper`,
`percent all upper/lower`; щуп до фикса показывал утечку uppercase-hex
целиком, после — маскируется.

## 3. [Low] Pattern-пути — ЗАКРЫТО, что закрывается безопасно

- **Per-char JSON `\uXXXX`**: в `derivedForms` добавлены (а) полная
  посимвольная форма `\uXXXX` на каждый рун (суррогатные пары выше
  BMP — как JSON-энкодеры), оба регистра; (б) одиночные эскейпы —
  ровно одна позиция экранирована, остальные сырые, для `%XX` и
  `\uXXXX`, оба регистра (`singleEscapes`, сиды ≤ 64 байт).
  Проба ревьюера `mysecr\u0065t1234` и полностью-экранированная
  форма маскируются: `TestRedactorUnicodeEscapeSeedForms`.
- **Полное percent-кодирование**: `percentEncodeAll` в обоих
  регистрах hex; обе пробы ревьюера (`%6d%79…` и `%6D%79…`, до фикса
  утекали целиком) маскируются, тест там же + в
  `TestRedactorEncodedSeedForms`.
- **Вложенный `/api/v1/sub/<token>`**: `subscriptionPathPattern`
  разрешает между хостом и ключевым сегментом только конвенционный
  API-префикс — сегменты `api` и `v<цифры>` в любой комбинации
  (`/api/sub/`, `/v2/subscribe/`, `/api/v1/sub/`, регистр и порт —
  как раньше). `TestRedactorNestedSubscriptionPaths`: 5 вложенных
  форм маскируются; обычные URL без ключевого сегмента, сегмент
  `apiary` (не `api`) и `/api/v1/users/…` не тронуты.

Осталось открытым, сознательно:

- **Произвольная вложенность** (`…/news/sub/<токен>`,
  `…/guide/sub/…`): ключевой сегмент под контентными сегментами
  неотличим от документационного пути; маскировка ломала бы
  обычные URL в логах. Закрыт конвенционный префикс панелей
  провайдеров, не любая глубина.
- **Многопозиционные подмножества эскейпов** (2..n−1 экранированных
  символов внутри сида) и **покарактерно смешанный регистр** hex /
  percent / `\u`: комбинаторны, энкодеров с таким поведением нет
  (см. §2). Одиночные и полные формы — границы реального класса —
  закрыты.
- **Идентификаторы в прозе без присваивания** (`…sni <значение>
  via…`, `hwid <значение>` с пробелом) и `Authorization: Digest
  … response=…`: зафиксировано ревьюером как by design; seeded-путь
  известные значения покрывает, проза без `:`/`=` по контракту
  strict-кольца не трогается (пины прозы в
  `TestRedactorStrictAssignmentKeys` зелёны — не перетянуто).

## 4. [Low] Словарь логов, сайт #16 — ИСПРАВЛЕНО

По факту кода (двойной канал, проверено по `core/control/server.go`
и `obfs.go`): warn-колбэк `loadObfsProfile` в NewServer
(`server.go:299-307`) **сохраняет** текст в `obfsLoadWarning` и,
если лог-центр задан, пишет его `logs.Write` (Warning, SourceCore);
тот же сохранённый текст Connect (`server.go:602-603,624-626`)
добавляет notice-строкой в журнал сессии (`session.EventLog`) на
каждом подключении, пока `ApplyObfsProfile` не очистит
(`obfs.go:431`). Шаблоны — два фиксированных текста
`control/obfs.go:532,539` (`…is corrupt…` / `…is invalid…`, только
имя файла `obfs_profile.json`, содержимого профиля нет). Строка #16
в `CENSOR-LEAK-LOG-DICT.md` переписана под эту механику (сайт,
шаблоны, оба канала, поля). Уточнение к ревью: канал `logs.Write`
Warning в коде есть — неточность словаря была в том, что он
показывал только его и не показывал основной канал доставки
(журнал сессии при Connect).

## 5. [Low] Форма net.Pipe тестов — ЗАКРЫТО, проверено мутацией

`core/obfs/conn_test.go`: обе fail-closed ветки переведены на
`writeBounded` (Write в горутине, `select` с границей 5 с) +
`assertPeerSilent` (чтение пира с дедлайном 200 мс, ноль байт).
Ветка без SNI и `TestWrapConnFragmentAndSNI` получили дедлайны
чтения (5/10 с) и ограниченное ожидание завершения Write.
Зависать больше не на чем: синхронных блокирующих операций на
тестовой горутине в этих тестах не осталось.

Мутация в /tmp-копии дерева (обе ветки возвращены к fail-open:
rewrite-ошибка → оригинал, split-ошибка → hello целиком):

- до фикса (по ревью): зависание, процесс убит на ~517 с;
- после фикса: `TestWrapConnFailsClosedOnRewriteError` FAIL за
  **5,01 с**, `TestWrapConnFailsClosedOnSplitError` FAIL за
  **5,00 с**, чистое сообщение («Write did not return within 5s:
  a fail-open write blocks on net.Pipe…»). Мутация снята, пакет
  зелёный: `go test ./obfs/ -count=1` ok.

## 6. Сид-корпуса фузза — ЗАКОММИЧЕНЫ

Файлы `testdata/fuzz/**` в формате этой версии Go
(`go test fuzz v1` + `string("…")` / `[]byte("…")`):

- `core/engine/testdata/fuzz/FuzzRedactorNoPanicAndIdempotent/` —
  20 файлов: краш-инпут отдельным файлом
  `crash-token-empty-quotes-suffix0`, все соседние формы п. 1 и
  прежние inline-сиды;
- `core/parser/testdata/fuzz/FuzzParseLink/` — 10 файлов (vless
  plain/full, trojan, ss, hy2, tuic, socks, пара ссылок, пустой,
  мусор);
- `core/parser/testdata/fuzz/FuzzDetect/` — 7 файлов ([]byte: link,
  JSON, YAML, base64, пустой, мусор).

Обычный `go test` гоняет их как сабтесты: FuzzRedactor — 41 сабтест
(файлы + inline), FuzzParseLink/FuzzDetect — PASS в обычном режиме
(проверено `-run` без `-fuzz` в копии и в общем дереве).

## Верификация (копия дерева в /tmp + общее дерево после коммитов)

- `go vet ./engine/ ./obfs/ ./parser/` — чисто.
- `go test ./engine/ -run 'TestRedactor|TestMask|TestProfile|
  TestOutbound|FuzzRedactor'` — все PASS, включая дифференциальный
  и паритетные тесты.
- `go test ./parser/ -count=1` — ok. `go test ./obfs/ -count=1` — ok.
- Фузз-перепрогоны: FuzzRedactor 20 с / 11 638 execs PASS;
  FuzzParseLink 15 с / 6 754 execs PASS; FuzzDetect 15 с /
  6 372 execs PASS.
- После коммитов в общем дереве: `go test ./engine/ -run
  'TestRedactor|TestMask|FuzzRedactor'`, `./parser/`, `./obfs/
  -run 'Fuzz|TestWrapConn'` — ok; HEAD содержит оба коммита.
- Единственное падение полного `./engine/` —
  `TestSelectEngineProbedPrefersFact` (probecaps/ECH, нужен
  бинарь mihomo актуальной версии): воспроизводится на дереве без
  моих правок, редактора не касается, чужая зона. Падения
  bypass/interop/tunroute в /tmp-копии — артефакт копии (тесты
  читают `third_party/` и `packaging/` от корня репозитория,
  которых в копии нет).

## Что осталось открытым

Только сознательные остатки §3 (произвольная вложенность sub-пути,
многопозиционные эскейп-подмножества, покарактерный mixed-case,
проза без присваивания, Digest-auth) — с обоснованиями выше.
Замечаний ревью без закрытия или без зафиксированного обоснования
не осталось.
