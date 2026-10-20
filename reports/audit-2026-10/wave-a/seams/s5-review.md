# S5 — независимый ревью фиксов кластера S5 (отдел совместимости стыков)

Ревьюер: независимый, не автор. Дата: 2026-10-20.
Методика: коммиты читались как объекты (`git show`); все исполнения — на чистых
снимках (`git worktree` в /tmp от нужных коммитов/родителей, после работы сняты).
Грязное дерево sora не использовалось. Собственные пробы писались только в
worktree и удалены вместе с ними; в репозиториях ничего не менялось, коммитов нет.

Итог: **все три фикса приняты**, опровергнуть заявленное поведение не удалось.
Замечания — ниже по каждому коммиту; дефектов (сценариев «вход → ожидаемое →
фактическое», ломающих заявленное) не найдено ни одного.

---

## 1. sora `5f9013c` + legacy `d92ec9a` — редактор: составные токены и auth-заголовки

**Вердикт: ПРИНЯТ** (пара целиком).

### (а) Воспроизведение на родителях — утверждение подтверждено в обоих репо

Родители: sora `7aa0819f`, legacy `417dc76` (непосредственный родитель `d92ec9a`).
Проба `maskPatterns` (22 строки, одинаковый файл в обоих репо). На родителях
**идентично в sora и legacy**:

| Вход | Родитель (ожидаемое по заявлению → фактическое) |
|---|---|
| `access_token: SECVAL…` | утечка → утечка ✔ |
| `"refresh_token":"SECVAL…"` | утечка → утечка ✔ |
| `accessToken=SECVAL…` | утечка → утечка ✔ |
| `session_token: SECVAL…` | утечка → утечка ✔ |
| `Authorization: Bearer SECVAL…` | утечка → утечка ✔ |
| `Authorization: Basic SECVAL…` | утечка → утечка ✔ |
| `Authorization: Bearer abcshort` (короткое значение) | утечка → утечка ✔ (бонус к заявлению) |
| `password: SECVAL…` (контроль) | маскируется → маскируется ✔ |
| `uuid: 123e4567-…` (контроль) | маскируется → маскируется ✔ |

На фиксах обе реализации маскируют **все** строки выше, включая короткое
значение после `Authorization:` (authHeaderPattern не имеет порога длины;
порог 12+ стоит только на голом `Bearer`). Дополнительно проверены и совпали
sora↔legacy: `id_token=`, `auth_token:`, `api_token:`, camelCase
`refreshToken=`/`sessionToken:`, голый `Bearer <12+ символов>`, а также
не-ASCII путь (`пароль access_token: …`, `токен Authorization: Bearer …`,
`ключ Bearer …`) — маскируется в обоих репо (у sora гейт `gateWords` пополнен
`bearer`, у legacy не-ASCII путь безусловный — расхождения нет).

### Ложные срабатывания — решение ревьюера

- `tokenizer: <значение>` — **не маскируется** ни до, ни после. Верно:
  `tokenizer` — не секретный ключ; ложного срабатывания фикс не внёс.
- `token_count: 5` — **не маскируется** ни до, ни после. Верно и желательно:
  счётчик — не секрет. Причина та же граница слова: после `token` стоит `_`
  (word-символ), `\b` нет — составная альтернация требует префикс
  (`access|refresh|…`), а не суффикс.
- `access_token_count: 42` — **не маскируется** и после фикса (после
  `access_token` снова `_`). Приемлемо: это счётчик токенов, не токен;
  зафиксировать как осознанное поведение, не дефект.
- Проза из авторского пина (`bearer shares good news`,
  `the bearer cheque is payable…`) не тронута — проверено авторским тестом
  и моей пробой.
- Единственная теоретическая цена: значение ключа вида именно
  `access_token`/`api_token` маскируется независимо от содержимого (хоть `5`).
  Это консервативное поведение всего редактора (так же маскируется
  `password: 5`), приемлемо.

### (б) Зеркальность

Добавленные фрагменты **байт-в-байт идентичны**: альтернация
`(?:access|refresh|session|id|auth|api)[_-]?token` в той же позиции
`keyValuePattern`, `authHeaderPattern`, `bearerPattern`, гейт `f.bearer`
(включая ветку `'b'` по `bearer`/`basic` и `authorization` в ветке `'a'`),
порядок применения в обоих путях `maskPatterns` (безусловный и ASCII-гейт).
Единственное текстовое различие самих паттернов — предсуществующее, фиксом не
внесено: класс разделителя sora `[\\\"']` против legacy `[\"']` (у sora в класс
входит обратный слэш; на заявленные формы не влияет, паритет проб это
подтверждает). Тест `TestRedactorParityCompoundTokens` в обоих репо идентичен
дословно.

### (в) Пин

- На фиксах: `TestRedactorParityCompoundTokens`, `TestRedactorParityKeySpellings`,
  `TestMaskPatternsDifferential` (+ `TestMaskGateParity` в sora) — PASS в обоих;
  полный `go test ./engine/` в sora — ok; в legacy — единственный FAIL
  `TestTunAndFakeIPAvoidLANAndEachOther` (см. «env» ниже, к редактору не относится).
- На родителях: изолированная функция пина (только
  `TestRedactorParityCompoundTokens`, без остального файла) падает
  **утверждениями** в обоих репо (все 11 leak-форм: «compound secret leaked» /
  «nothing masked»). Методическая оговорка, не дефект: пересадка файла
  `redact_test.go` целиком на родителя даёт не падение пина, а ошибку сборки —
  обновлённый `TestMaskPatternsDifferential` ссылается на новые
  `authHeaderPattern`/`bearerPattern`. Кто будет переигрывать проверку —
  пересаживать надо изолированно.

Объём: ровно заявленные файлы (`core/engine/redact.go`, `redact_test.go`) ×2 репо.

---

## 2. legacy `6379922` — parser: trojan/hy2 пароль + SIP008

**Вердикт: ПРИНЯТ.**

### Порт против оригинала sora `1b094621`

Код ветки `case "trojan", "hysteria2", "hy2"` **идентичен оригиналу**
(`if o.Password == "" { o.Password = o.User }`, те же
`Transport`/`Security` из query) — различие только в тексте комментария.
SIP008-часть — собственное добавление legacy, в sora её нет (там спека S5-SP1 —
соответствует отчёту автора, расхождения с заявлением нет).

### Пробы (снимок `6379922` против родителя `9fc03a7`)

- `trojan://s3cret@…`, `hysteria2://hy2pass@…`, `hy2://hy2pass2@…`: родитель →
  `UUID="s3cret", Password=""` (заявление подтверждено); фикс →
  `UUID="", Password` на месте, протокол/хост/порт верны.
- SIP008, моя проба на **3 записи** (авторский тест — 1): родитель →
  `servers=0, Invalid=3`; фикс → `Imported=3`, все три `Protocol="shadowsocks"`,
  пароли/шифры/порты верны, `DisplayName` из `remarks` у всех трёх.
- Регрессий SIP002 нет: `ss://` в обеих формах (base64-userinfo
  `YWVzLTI1Ni1nY206…` и plain `aes-256-gcm:plainpass@`) даёт байт-идентичный
  результат до и после фикса; `vless://` — UUID на месте, пароль пуст, как раньше.
- Полный пакет: `go test ./parser/` на снимке фикса — **все тесты PASS**
  (включая перенесённые `TestParsePasswordOnlyCredentials`,
  `TestParseSIP008Document`, фузз-корпуса как юнит-тесты).

Наблюдение (не дефект, паритет с sora): форма `trojan://user:realpass@…` —
родитель парковал `user` в UUID, фикс оставляет `UUID=""` (`user` остаётся в
поле `User`, пароль сохранён). Это ровно поведение оригинального фикса sora
и строго лучше прежнего; потребителей UUID у trojan нет.

Объём: ровно `core/parser/parser.go` + `parser_test.go`.

---

## 3. legacy `417dc76` — порт REALITY/XHTTP-валидаторов из sora

**Вердикт: ПРИНЯТ.**

### Паритетный пин

- `TestValidateRealityParity` на снимке (tip `d92ec9a`, содержит `417dc76`) —
  **12/12 PASS**. `go test ./control/` — ok; `go vet ./engine/ ./parser/` — чисто.
- Изолированная пересадка пина на до-фиксовый снимок `6379922`: **8/12 FAIL**
  (empty pbk, short pbk, nonhex sid, long sid, bad xhttp mode, vision без
  Encryption, unknown protocol, unknown transport), 4 контрольных — PASS.
  Заявление «до фикса legacy принимал всё битое» подтверждено и моей пробой
  (см. ниже: на `6379922` все битые векторы дают `err=nil`).

### Свои векторы: sora (`5f9013c`) против legacy (tip), 23 случая через `Validate()`

Вердикты **и тексты ошибок совпали по всем 23**, включая не заявленные автором:

- валидный REALITY принимается обеими (также: пустой sid — ok; sid ровно
  16 hex — ok; sid в верхнем регистре — ok);
- pbk не-base64url: 43 символа с `+` (std-base64) — reject обеими; с `!` —
  reject; 44 символа с паддингом `=` — reject; 42 символа — reject;
- sid не-hex `zz11` — reject; sid нечётной длины `ab1` — reject; sid 18 hex —
  reject;
- XHTTP `mode="stream-one"` **без** downloadSettings — **accept обеими**
  (важно: whitelist, а не запрет); `stream-up` — accept; `AUTO` в верхнем
  регистре — reject обеими; `stream-sideways` — reject;
- vision-udp443 без Encryption на XHTTP — reject обеими (проверка по префиксу,
  не по равенству — порт не потерял этот нюанс sora);
- ALPN `h3` без TLS — reject обеими, с TLS — accept;
- unknown protocol/transport — reject; transport `h2` — accept (whitelist
  совпадает); REALITY на ws — accept обеими (только warning, не error).

### Неполнота порта — новых расхождений на заявленных векторах не создаёт

Проверил по факту структур: legacy `Transport` не имеет
DownloadAddress/DownloadPort/Xmux*/XPaddingBytes, legacy `TLS` не имеет
ECH/KeyShare. Следовательно проверки sora, которых в порте нет
(downloadSettings↔stream-one, xmux-взаимоисключение/негативы, xPaddingBytes,
не-XHTTP-транспорт с XHTTP-полями, ECH/KeyShare), в legacy **невыразимы
входом** — Outbound, который их нарушает, нельзя сконструировать; на всех
выразимых векторах (12 заявленных + 23 моих) расхождений нет. Это ровно
оговорка автора (спеки S5-SP4/S5-SP5), а не скрытый дефект.
Дополнительно: `reality.go` legacy против sora — различия только в комментариях
и месте `HasVLESSEncryption` (в sora — `vision.go`, тело идентично:
`Encryption != "" && != "none"`); множества `validProtocols`/`validTransports`/
`validXHTTPModes` совпадают с sora дословно; добавленные попутно
`Warnings()` (`xhttp-version-sync`, `RealityWarnings`) и `Identifiers()`
(RealityPublicKey/ShortID/SpiderX) присутствуют и в sora — не самодеятельность.

Объём: ровно `core/engine/reality.go` (новый), `validate.go`, `validate_test.go`.

---

## Env-шум (по заданию дефектом не считать — подтверждено независимо)

`TestTunAndFakeIPAvoidLANAndEachOther` падает на чистом до-S5 снимке legacy
`9fc03a7` с той же диагностикой (`fake-IP pool overlaps an existing interface`),
что и на tip с фиксами S5. Единственное падение в затронутых пакетах legacy;
в sora на снимке `5f9013c` `./engine/` и `./parser/` полностью зелёны.

## Сводка

| Коммит | Вердикт |
|---|---|
| sora `5f9013c` + legacy `d92ec9a` (редактор) | **ПРИНЯТ** |
| legacy `6379922` (parser trojan/hy2 + SIP008) | **ПРИНЯТ** |
| legacy `417dc76` (REALITY/XHTTP-валидаторы) | **ПРИНЯТ** |

Дефектов не найдено. Нюансы для родителя: (1) пересадка пина редактора на
родителя — только изолированной функцией, иначе ошибка сборки маскирует
результат; (2) `token_count`/`access_token_count` редактором не маскируются —
осознанно и правильно (счётчики), но если когда-нибудь провайдер назовёт
секрет `*_token_count`, это будет слепое пятно вне текущего заявления.
