# REVIEW-SP6B-MICRO — независимое микро-ревью коммита 9e2b677 [legacy-up] control (follow-up по трём Low из REVIEW-SP6B §7)

Дата: 2026-10-21. Ревьюер: независимый агент (код не правил, коммитов не делал).
Объект: `sora-legacy`, ветка `bugfix/audit-2026-10-19`, коммит
`9e2b677575c636981faf99afbe5eb29b59e01f23`.
Методика: работа только по закоммиченному состоянию — `git archive 9e2b677`
в `~/workspace/review-sp6b-micro/legacy-head`; рабочее дерево не читалось как
источник истины (в нём лежат чужие ханки `plan_internal_test.go`/`parser.go` —
в коммит они не попали, см. §4). Все поведенческие утверждения — своими
пробами (временные тесты в архивной копии, прогнаны и удалены): точность —
прямой `resolveImportedSpec`/`credentialDocument` и полный путь
`parser.LinkParser.Parse` → `credentialDocument` → `importedPlan`
(+ `plan.Validate`), атомарность — публичный `Server.ParseImport` с реальным
vault-store. Go: `PATH=$HOME/workspace/go/bin`, TMPDIR/GOCACHE на основном
диске, модуль `core/go.mod`.

## Вердикт

| Пункт | Вердикт |
|---|---|
| Коммит 9e2b677 в целом | **Принять** (блокеров нет; один остаточный Low-нюанс вне скоупа §7 — §5.1) |
| (1) Точность float64 в `blobShortID`, fail-closed при `n >= 2^53` | **Принять** — закрыто полностью, граница и обоснование проверены фактом |
| (2) Остаточные вложенные null (alpn/insecure/headers, reality.enabled) | **Принять** — все точки §7 закрыты; собственный аудит нашёл ещё одну покрытую гардом точку сверх списка исполнителя и один доброкачественный остаток глубже (§5.1) |
| (3) Заголовок `resolveImportedSpec` + `TestImportedSpecHeaderSemantics` | **Принять** — каждое утверждение заголовка подтверждено пробой, включая обратную пару, которой в тесте коммита не было |

---

## 1. Точность: окно float64 закрыто fail-closed

Код (архив, `plan.go:847`): условие отказа — буквально
`n < 0 || n >= 9007199254740992 || n != math.Trunc(n)`, т.е. именно
`>= 2^53` (литерал равен 2^53, не 2^53+1 и не округлённой границе);
отрицательные и дробные по-прежнему fail-closed тем же путём.

Свои пробы, **оба пути** (Clash `reality-opts.short-id` и sing-box
`tls.reality.short_id`), прямым resolve и полным путём парсера:

| Значение | Результат |
|---|---|
| `9007199254740993` (2^53+1) | ✅ отказ, `invalid_argument`, текст называет short-id («…is 9.007199254740992e+15, not a short-id») |
| `9999999999999999` | ✅ отказ `invalid_argument` на обоих путях и полным путём парсера |
| `12345678901234567890` | ✅ отказ `invalid_argument` на обоих путях и полным путём парсера |
| `9007199254740992` (ровно 2^53; в тесте коммита этой границы **нет**) | ✅ отказ — моя дополнительная проба; граница именно включительная, как заявлено |
| `-5`, `-123`, `123.5`, `0.5` | ✅ отказ тем же текстом на обоих путях (регрессии нет) |
| `9007199254740991` (2^53−1) | ✅ точная конверсия цифра-в-цифру на обоих путях; полным путём до плана (`importedPlan` + `Validate`) sid в плане равен исходной строке |
| `12345678`, `1234567890123456`, `0` | ✅ конвертируются как раньше |

Примечание о цене границы: ровно представимые числа ≥ 2^53 (например, само
2^53) тоже отклоняются — это осознанный fail-closed: после float64-декода
исходные цифры уже не восстановить и отличить «точное» от «округлённого»
нельзя. Для short-id (≤ 8 байт) практическая потеря нулевая.

**Атомарность.** Своя проба публичным `ParseImport`: валидный trojan +
vless с каждым из трёх больших sid → wire-ошибка
`SORA_ERROR_CODE_INVALID_ARGUMENT` с detail, называющим short-id,
`outbounds=0`, `store.Len()=0` — во всех трёх случаях. «Частичный импорт»
не протекает.

**Обоснование fail-closed против UseNumber — по факту верно.**
`optionBlob` декодирует `json.Unmarshal` в `any`, и тип числа потребляют
все экстракторы, а не только `blobShortID`:

- `blobBool` ключится на `case float64` для 0/1 (своя проба:
  `skip-cert-verify: 1` → insecure=true, `0` → false — работает сегодня;
  при `json.Number` ни `case float64`, ни `case string` не сматчились бы,
  числовые булевы стали бы shape-ошибкой без переписывания потребителя);
- `blobString` для числового public-key даёт запиненную диагностику
  «is float64, not a string» (своя проба: `public-key: 12345678` → ровно
  этот текст); при UseNumber `%T` стал бы `json.Number` и диагностика
  уехала бы, вместе с остальными `%T`-текстами (`blobBool`,
  `blobStringList`, `blobObject`);
- `blobHost`/`blobStringList`/`applyTLSBlob` разделяют те же типы.

То есть комментарий коммита («would change the type of every number in
every blob») — факт, а не отговорка: UseNumber потребовал бы касания всех
потребителей ради sid, которые ни один провайдер так не пишет. Выбор
fail-closed соразмерен.

## 2. Вложенные null: точки §7 закрыты, аудит исполнителя в основном полный

Пробы коммита (`TestImportedNestedNullsAreAbsent`, 7 прямых + 2 полных
документа) прогнаны — все зелёны. Сверх них, своими документами через
`resolveImportedSpec` и полным путём `ParseImport` (sing-box документ со
всеми null сразу):

| Проба | Результат |
|---|---|
| `tls.alpn: null`, `tls.insecure: null` | ✅ отсутствуют, `server_name`/security выживают, insecure не выдумывается |
| `transport.headers: null`, `h2-opts.headers: null`, `ws-opts.headers: null`, всё сразу | ✅ заголовков нет, path/транспорт выживают |
| `tls.reality.enabled: null` | ✅ claim REALITY сохраняется (обёртка `rawEnabled != nil` работает: enabled остаётся default true), pbk/sid на месте; полным `ParseImport` — security=`reality`, 1 outbound, план валиден (тест коммита + моя проба) |
| Полные документы sing-box и Clash через парсер+vault | ✅ импорт успешен, поля с null отсутствуют, соседние значения (server_name, path) выживают, план валиден |

**Собственный аудит остальных точек извлечения** в
`resolveImportedSpec`/`extractBlobFields`/`apply*` (прочитаны все вызовы
`blob*` в архиве): пропущенных точек, где JSON null дал бы ошибку или
выдуманный claim, **не нашёл**. Подтверждено пробами сверх списка
исполнителя — все ✅ без ошибок и без выдуманных значений:
`tls.enabled: null` (закрыта тем же nil-кейсом `blobBool`, хотя исполнитель
её отдельно не называл — аудит фактически шире его списка),
`tls.utls.fingerprint: null`, `transport.type/path/service_name: null`,
`grpc-opts.grpc-service-name: null`, `xhttp-opts.path/host/mode: null`,
`h2-opts.host: null`, null-элемент внутри ALPN-списка (пропускается,
остальные элементы выживают), `[null]` как host-список, `short_id: null` и
`utls/reality: null` (закрыты раньше, регрессии нет). Структурно:
`blobObject` нигде не вызывается на вложенном значении без nil-гарда
(`utls`/`reality` — под `raw != nil`, остальные — на option-уровне, где
`optionBlob` отсекает null сам), `blobString`/`blobShortID`/`blobHost`
nil-безопасны по построению, что я и подтвердил чтением кода.

Оговорка по построению, не дефект: `reality:{public_key: null}` даёт отказ
«claims REALITY but carries no public key» — присутствие блока и есть
claim, отсутствие ключа при claim'е отказывается дизайном F3; null здесь
ничего не выдумывает.

## 3. Заголовок: финальный текст построчно равен коду

Финальный заголовок (архив, `plan.go:253-268`) против кода и проб:

| Утверждение заголовка | Факт |
|---|---|
| Typed wins по всем скалярам | ✅ код заполняет каждое скалярное поле только при пустом typed; пробы — 9 полей в REVIEW-SP6B §4 + моя: typed `Fingerprint`/`Mode` бьют блобные, блобный `Path` при пустом typed доезжает |
| Transport — всегда блоб | ✅ `if f.transport != "" { out.Transport = f.transport }` безусловно |
| REALITY-claim бьёт **любую** typed-метку | ✅ свитч ключится на `f.security == "reality"` первым, безусловным кейсом; запинено тестом коммита (`none` + reality-opts → reality) |
| Прочий блоб-лейбл проигрывает любому typed security, включая «none» | ✅ второй кейс свитча — только при `out.Security == ""`; запинено (`none` + tls-блоб → none) |
| Insecure монотонна только в сторону включения | ✅ `if f.insecure { out.AllowInsecure = true }` — присваивания false в resolve нет; 4 пробы теста коммита прогнаны |

`TestImportedSpecHeaderSemantics` прогнан — зелёный, и пинит именно
заголовок (reality > none; не-REALITY лейбл < none; монотонность insecure
×4), а не что-то соседнее.

**Своя обратная пара** (в тесте коммита её нет): typed `security="tls"` +
блоб с меткой `"none"` (tls-блоб строкой `"none"`, а также объект
`{"enabled":false}`) → в обоих случаях итог `tls`: заголовок и код
согласны и в эту сторону. Контроль той же пробы: typed `tls` +
reality-opts → `reality`.

## 4. Дисциплина и регрессии (архив 9e2b677, пробы удалены перед прогонами)

| Проверка | Результат |
|---|---|
| `git show --stat 9e2b677` | ровно 2 заявленных файла: `core/control/plan.go` (+42/−11 в файле, итог 53 строки диффа) и `core/control/plan_sp6b_internal_test.go` (+268). Чужих файлов нет |
| Чужие worktree-ханки | не попали: worktree несёт правки `plan_internal_test.go` и `parser.go` — ни одного из них в коммите нет; дифф коммита по двум файлам чистый и самодостаточный (архив строится и тестируется без worktree) |
| `go build ./...`, `go vet ./...` | чисто |
| `go test ./control/ ./parser/ -count=1` | оба ok |
| Полный `go test ./...` | единственный FAIL — `engine.TestTunAndFakeIPAvoidLANAndEachOther` («fake-IP pool overlaps an existing interface») — разрешённый env-артефакт VM, тот же на baseline |
| `gofmt -l` по двум файлам коммита | пусто (чисто) |
| Тесты коммита | `TestImportedShortIDPrecisionWindowFailsClosed` (5), `TestImportedShortIDBelowPrecisionBoundStillConverts` (3), `TestImportedNestedNullsAreAbsent` (9), `TestImportedSpecHeaderSemantics` (1+4) — все зелёны |

## 5. Мелочи

1. **Остаточный null глубже (§2, Low, вне скоупа §7):** значение null
   *внутри* headers-объекта — `headers: {"X-Custom": null}` — не
   отсутствует, а превращается в заголовок с пустым значением
   (`map["X-Custom":""]` доезжает в `f.headers`): `blobHeaders` пишет
   результат `blobString` (nil → `""`) в карту безусловно. Не ошибка
   импорта и не security-claim, поведение предшествует этому коммиту
   (nil-кейс `blobString` старше), поэтому вердикт по п.2 не меняет;
   честный остаток того же класса одним уровнем глубже — лечится
   пропуском nil-значений в `blobHeaders` при следующем касании.
2. Тест коммита не пинит ровно 2^53 и sing-box-варианты для
   `9999999999999999`/`12345678901234567890` — поведение при этом верное
   (мои пробы §1), это пробел покрытия, а не поведения.
3. Диагностика отказа для больших чисел печатает float в научной
   нотации («9.007199254740992e+15») через `%v` — причину называет,
   читаемость хуже, чем у исходных цифр; косметика.
