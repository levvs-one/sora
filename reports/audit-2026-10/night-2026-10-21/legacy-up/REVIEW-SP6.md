# REVIEW-SP6 — извлечение REALITY/TLS/transport из sing-box и Clash блобов (S5-SP6)

Ревьюер: независимый, код не правил. Объект: `dc95212` (конверсия) и
`4f60852` (тесты) в sora-legacy, ветка `bugfix/audit-2026-10-19`.
Спека: `reports/seams/s5-mirrors-import-docs.md`, S5-SP6 + пробы §4.

**Вердикт: ПРИНЯТЬ С ЗАМЕЧАНИЯМИ.**

Критерий приёмки спеки выполнен полностью: образцы §4 обоих диалектов
дают план, проходящий `Validate`, с pbk/sid/servername/path заполненными;
fail-closed для полу-REALITY честный и атомарный. Замечания — про формы
реальных подписок за пределами образцов спеки (числовой short-id в YAML,
http/h2-opts у Clash) и одну неточность в комментарии; ни одно не ломает
образцы спеки и не создаёт молчаливой полу-конфигурации.

Методическая оговорка: в момент ревью соседний отдел (S5-SP4) правил
рабочее дерево наживо (`parser.go` ссылался на ещё не существующий
`applyExtra`, `control/plan.go` получал чужие ханки). Все прогоны ниже —
в чистой копии коммитнутого состояния (`git archive HEAD`, HEAD=5c4190e,
содержит оба коммита), не по грязному дереву. Пробные файлы ревью
удалены, дерево после ревью содержит только чужой WIP.

## 1. Полнота извлечения по спеке — ПОДТВЕРЖДЕНО

Прогон через публичный путь (`Server.ParseImport` → vault →
`planFromProto` → `plan.Validate`), пробы ревьюера, не только тесты коммита:

| Форма | Результат пробы |
|---|---|
| sing-box `tls.reality.{public_key,short_id}`, `tls.server_name`, transport ws | ✅ pbk/sid/server_name/path/Host-header в плане, Validate ok |
| sing-box transport grpc `service_name` | ✅ |
| sing-box transport **xhttp** path/host/mode | ✅ (своя проба, в тестах коммита xhttp нет) |
| sing-box transport host полем и списком (http-стиль, первый элемент) | ✅ resolve-уровень; до плана — см. F2 |
| sing-box headers: Host + кастомный `X-Custom` | ✅ оба в `Transport.Headers` |
| sing-box TLS сверх спеки: `alpn`, `utls.fingerprint`, `insecure` | ✅ всё доезжает |
| Clash `reality-opts.{public-key,short-id}`, `servername`, `ws-opts.path`+`headers`, flow-стиль | ✅ |
| Clash те же поля **block-стилем** (вложенные мапы, не flow) | ✅ (своя проба; тесты коммита — только flow) |
| Clash `grpc-opts.grpc-service-name`, `network` | ✅ |
| Clash `xhttp-opts` path/host/mode, `sni` вместо `servername`, `client-fingerprint`, `skip-cert-verify` | ✅ (сверх спеки) |
| Clash trojan (без reality) ws и без opts вообще | ✅ не ломается, пароль/sni на месте |

Путь честный целиком: `parsePayload` резолвит до `referenceOf` и
`credentialDocument` (server.go), заголовки транспорта едут отдельным
JSON-документом в vault (`headers` добавлен в `credentialKeys`) и
восстанавливаются в `applyCredential`; повторный резолв уже
разрешённой спеки идемпотентен (проба: документ байт-в-байт тот же).

## 2. Граничные случаи — пробы ревьюера

- Reality без `short_id` (оба диалекта): импорт проходит, sid пуст,
  Validate ok — правильно, short_id опционален (`ValidateReality`
  проверяет только непустой sid).
- `tls` без reality: plain TLS, `security=tls`, REALITY не выдумывается. ✅
- ws без path: проходит с пустым path. ✅
- `reality.enabled:false` без pbk: **не** claim, импорт проходит как
  plain TLS — семантика sing-box соблюдена. ✅
- Пустой `reality-opts: {}`: claim есть, pbk нет → отказ
  invalid_argument. ✅
- Битый JSON / неверная форма в **потребляемых** блобах: `transport`,
  `reality-opts`, `grpc-opts` (число вместо строки), `headers`
  (числовое значение), `alpn` (объект) — все честно падают
  invalid_argument. Битый JSON в **непотребляемом** ключе Options
  игнорируется — правильно, это не блоб конверсии. ✅
- Конфликт блоб vs типизированные поля (прямая проба
  `resolveImportedSpec`): скаляры — **типизированные побеждают**
  (pbk, sid, server_name, fingerprint, path, host, service_name, mode,
  ALPN), insecure монотонен (блоб только включает). Два исключения,
  оба осознанные в коде: `Transport` блоб перезаписывает всегда
  (парсер для sing-box ставит типовому полю дефолт `tcp`, блоб —
  первоисточник) и `security=reality` из блоба побеждает типовую
  метку `tls` (Clash `tls:true`+`reality-opts` иначе не разрешить).
  Для реальных входов парсера исключения недостижимы во вред:
  типовые поля у JSON/YAML-импортов либо пусты, либо выведены из того
  же блоба. См. однако F4 про комментарий.

## 3. Fail-closed честность — ПОДТВЕРЖДЕНО, с оговоркой F3

- Заявленный REALITY без public key (sing-box и Clash, включая
  пустой `public-key:""`) отклоняется **на импорте**, код
  invalid_argument, сообщение называет причину дословно:
  «an imported vless outbound claims REALITY but carries no public
  key».
- Атомарность (проба через публичный `ParseImport`): подписка из
  хорошего trojan + полу-REALITY vless → ошибка целиком, SessionPlan
  пуст, **vault: 0 записей** — хороший сервер не сохраняется наполовину.
  Это осознанный дизайн (комментарий в server.go), не случайность.
- Различение «claim из блоба» vs «метка security=reality» корректно:
  Xray-профиль с `security=reality` без плоского pbk импортируется
  (запинено тестом коммита, мутационно подтверждено ниже).
- Битый сохранённый `headers`-документ падает в `applyCredential`,
  как peers/xray_profile — заголовки не теряются молча.
- Полу-REALITY «валится в непонятном месте» не возникает: всё, что
  проходит импорт, либо полноценно, либо падает на `plan.Validate`
  с именованной причиной (см. F3).

## 4. Тесты 4f60852 — НЕ тавтология; прогоны ревьюера

Чистое коммитнутое состояние (архив HEAD), Go с
`PATH=$HOME/workspace/go/bin:$PATH`, TMPDIR/GOCACHE на основном диске:

- `go build ./...` — ok; `go vet ./...` — ok.
- `go test -count=1 ./control/ ./parser/` — **ok оба пакета полностью**.
- SP6-тесты коммита: 6/6 Survive-подтестов, 5/5 FailClosed, XrayProfile,
  BrokenHeaders — зелёные с `-count=1`.
- Мутационная проверка (только в архивной копии): (а) `resolveImportedSpec`
  → no-op: падают **все** 6 Survive и **все** 5 FailClosed подтестов;
  (б) отключён только гейт `realityClaimed && pbk==""`: падают ровно
  два подтеста «reality без public key», остальные зелёные. Тесты
  пинят поведение точечно, включая позитивный контроль XrayProfile.
- Покрытие тестами коммита уже, чем код: нет xhttp, block-YAML,
  конфликтов и частичных блобов (§2) — ревьюер закрыл своими пробами,
  все прошли; в постоянные тесты стоит добавить хотя бы xhttp и
  block-стиль (не блокер).

## 5. Замечания

**F1 (среднее). Числовой short-id в Clash YAML отклоняется — и валит
всю подписку.** `short-id: 12345678` без кавычек (обе формы, flow и
block; проба ревьюера) YAML-декодер парсера превращает в число,
`mapJSONSpec` маршалит его как JSON-число, а строгий `blobString`
отклоняет: «the reality-opts.short-id option … is float64, not a
string». Для mihomo такой YAML валиден (декодирует в строковое поле
по литералу). All-digit hex sid у провайдеров встречается; в силу
атомарности (§3) один такой сервер блокирует импорт всей подписки.
Туда же, слабее: `"tls": null` отклоняется («<nil>, not an object or
a boolean») вместо «отсутствует». Лечение: `blobString` для short_id
принимает интегральные числа, `null`-блобы трактуются как отсутствующие.

**F2 (среднее-низкое). Clash `http-opts`/`h2-opts` не извлекаются;
транспорт `http` упирается в белый список.** Пробы: `network: h2` +
`h2-opts` — план валиден, но path/host **молча пусты**; `network: http`
+ `http-opts` — path/host пусты, а verbatim-транспорт `http` не входит
в `validTransports` движка («», tcp, ws, grpc, h2, httpupgrade, xhttp)
и план падает уже при построении сессии — с понятной ошибкой, но после
успешного импорта. То же с sing-box `transport.type: "http"`:
извлечение (path + первый host списка) работает, план не проходит.
Спека http/h2-opts не перечисляла — это неполнота за её пределами, но
именно verbatim-проброс транспорта в SP6 превратил sing-box http из
прежней тихой деградации в tcp в отказ; напрашивается маппинг
`http`→`h2` или честный отказ на импорте, а для h2-opts — извлечение
по образцу grpc-opts.

**F3 (низкое). Битый, но присутствующий ключ проходит импорт.**
pbk `"AAAA"` и не-hex sid: `credentialDocument` проверяет только
наличие, форма проверяется позже — импорт сохраняет сервер, отказ
приходит на `plan.Validate`. Сообщения образцовые (проба: «REALITY
public key is not a 32-byte base64url X25519 key», «REALITY shortId
must be hex, at most 8 bytes») — «непонятного места» нет, но асимметрия
с отсутствующим pbk (отказ на импорте) заметна. По желанию: проверять
форму ключа в резолве при `realityClaimed`.

**F4 (низкое, документация).** Заголовок `resolveImportedSpec` —
«Typed fields always win» — неточен: transport и security=reality
являются исключениями (объяснены только инлайн-комментариями по
местам). Поправить заголовок, чтобы следующий читатель не «исправил»
исключения как баг. Сюда же: типовая `security="none"` против
tls-блоба — побеждает `none` (проба), от парсера недостижимо, но
асимметрия с reality-веткой стоит одной строки комментария.

**F5 (тривиальное, стиль).** `gofmt -l` на коммитнутом состоянии:
только `plan_internal_test.go` — одна лишняя пустая строка перед
`importedPlan`, внесена 4f60852. `plan.go`/`server.go` чисты. Внимание:
в живом дереве эту же строку уже удаляет чужой незакоммиченный WIP —
не применять фикс вслепую поверх.

## 6. Мелочи и стиль (вне замечаний)

Имена (`blobFields`, `extractBlobFields`, `applyTLSBlob`,
`optionBlob`, `blobError`) и стиль ошибок (`errs.Newf`,
CodeInvalidArgument / KeyPlanOutbounds) — в конвенциях пакета;
комментарии объясняют «почему», включая нетривиальное различение
claim/метка. `optionBlob` аккуратно различает JSON-значения и сырые
скаляры share-ссылок, поэтому резолв безопасен и для линков
(регрессий по существующим тестам линкового пути нет — полный пакет
зелёный). Дублирование резолва в трёх точках (parsePayload,
credentialDocument, outboundToProto с проглатыванием ошибки в
последней) оправдано комментариями: в ParseImport-пути ошибка всегда
всплывает раньше, в credentialDocument.

Итог: принять; F1 — первым кандидатом в следующий фикс, F2/F4 — по
возможности, F3/F5 — косметика.
