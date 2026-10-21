# OpenLibre / olcrtc — транспорт (путь B, сайдкар): НЕЗАВИСИМОЕ РЕВЬЮ

Ревьюер: независимый ревьюер подотдела транспорта. Объект: коммиты
`9e04baa0`, `23a094b9`, `d5e652e8`, `733af303`, `ed7fed36` на ветке
`bugfix/audit-2026-10-19`, HEAD на момент начала ревью `ed7fed36`.
Метод: чтение кода + собственные прогоны на чистом `git archive HEAD`
в `/tmp/olc-review` (дерево репозитория не трогалось; все контртесты
ревьюера лежат только в архивной копии). Документы сверены:
TRANSPORT.md, TRANSPORT-ANALYSIS.md, SPEC.md §3.2, IMPORT.md;
первоисточник сверен с тегом `v0.0.1` (коммит `3e42ae98`, аннотированный
тег-объект `e652b768`) и `f3ad8fb` из `~/workspace/openlibre-ref/olcrtc`.

## Вердикт: ПРИНЯТО С ЗАМЕЧАНИЯМИ

Блокеров нет. Все 8 пунктов задания подтверждены, несколько — сильнее,
чем заявлял исполнитель (строгий загрузчик настоящего архива v0.0.1 на
golden-рендерах, перекачанный дайджест архива, подмена бинаря тремя
способами, SIGKILL сайдкара посреди сессии, побайтная сверка
кред-документа с родительским коммитом). Замечания З-1..З-3 — minor
(семантика очистки, асимметрия guard-а vault, пробел в тестовой
таблице), З-4 — уточнение формулировки. Ни одно не меняет поведение
подключения и не открывает дыр.

Замечание о среде: во время ревью параллельный отдел оформления
приземлил на ту же ветку коммит `e7e63f62` ([openlibre] design:
локализация/UI/доки; только `app/` и `docs/`, зон транспорта не
касается). Ревью целиком относится к `ed7fed36`; рабочее дерево и
индекс на обоих замерах чисты.

## 1. Состав коммитов — подтверждено

`git show --stat` по пяти коммитам: только заявленные зоны.

| Коммит | Файлы |
|---|---|
| `9e04baa0` | `core/engine/olcrtc.go` (+test), `core/engine/plan.go`, `core/engine/validate.go`, `core/errs/catalog.go` |
| `23a094b9` | `core/engine/olcwrap/{olcwrap,render}.go` (+tests) |
| `d5e652e8` | `core/control/plan.go`, `core/control/olcrtc_vault_test.go` |
| `733af303` | `core/engine/registry/registry.go` (+test) |
| `ed7fed36` | `THIRD-PARTY-NOTICES.md`, `packaging/engines/{engines.lock,engines.sig,fetch.sh}`, `packaging/linux/nfpm.yaml` |

Итого 18 файлов, +1890/−8. Чужого нет: парсер/подписки не тронуты,
Dart не тронут (транспорт это честно заявляет). `git status` чист на
старте и на финише (кроме параллельного коммита выше).

## 2. Vault — подтверждено, усилено контрпримерами

Тесты исполнителя на архиве зелёны (`TestOlcrtcVaultRoundTrip` 4/4,
`KeepsSubscriptionMeta`, `ServerModeRefusedFromVault`).

Собственные контрпримеры ревьюера (пакет `control`, архивная копия):

- **Ссылка + `auth_token` + `channel`** (поля, которых нет ни в одной
  ссылке корпуса исполнителя — они документ-only):
  `TestReviewVaultAuthTokenAndChannel` — `olcrtc_auth_token` и
  `olcrtc_channel`, выставленные в `Options` (как делает тест srv),
  переживают `credentialDocument → outboundFromProto` целиком,
  `Validate()` чист. Round-trip полный: провайдер/комната/транспорт/
  параметры/meta/channel/auth_token/Password.
- **Побайтная прежность для не-olcrtc** — проверена не тестом внутри
  одного дерева, а межкоммитно: одинаковый печатающий тест на архивах
  `ed7fed36` и родителя `4f5fa7c0` дал для vless-ссылки байт-в-байт
  один документ
  `{"download_port":"0","security":"none","user":"b831…","uuid":"b831…"}`.
  Структурно это обеспечено тем, что блок olcrtc в
  `core/control/plan.go:132` ограждён `EqualFold(spec.Protocol,"olcrtc")`,
  а `doc.field` пустые значения пропускает; существующий
  `TestCredentialDocumentMatchesLegacyMapForm` также зелёный.
- **Частичный подделанный документ** (только `olcrtc_mode:"srv"` без
  provider/transport/params): `srv` не исполняется — см. З-2.

## 3. Рендер YAML — подтверждено против SPEC §3.2 и живого загрузчика

- Словарь `transportSections` (`core/engine/olcwrap/render.go`) сверен
  построчно с SPEC §3.2: vp8 — префиксы `vp8-fps→vp8.fps`,
  `vp8-batch→vp8.batch_size`; sei — **без префикса**:
  `fps/batch/frag/ack-ms → sei.fps/batch_size/fragment_size/ack_timeout_ms`;
  video — все 8 ключей `video-*` в `video.*`, строковые enum (`codec`,
  `qr_recovery`) квотируются, остальные — int с отказом на нецелом.
  Неизвестные и устаревшие (`video-bitrate`/`video-hw`) в YAML не
  попадают (golden-тест + мой рендер с `mode` в Params, п.5).
- **Сильнейшая проверка, которой у исполнителя не было**: golden-рендеры
  sora (datachannel, sei полный словарь, vp8, video-tile с channel)
  прогнаны через **строгий загрузчик настоящего архива тега v0.0.1**
  (`internal/config.Load`, `KnownFields(true)`): все приняты,
  `Apply` даёт верные provider/transport/dns/socks/sei/vp8/video;
  выдуманный ключ загрузчик отвергает — посылка «строгая схема ловит
  опечатки» верна на самом пине.
- **Дефолты**: рендерер секций не синтезирует — при пустых `Params`
  секций `vp8:`/`sei:`/`video:` нет вообще (мой
  `TestReviewNoDefaultsSynthesized`). Тонкость — З-4.
- **DNS**: единственный источник — `PlanResolver`
  (`render.go:147`): plain/TCP дословно → хост первого иного резолвера
  на :53 → первый nameserver `/etc/resolv.conf` → честная ошибка.
  Пути, где протекал бы upstream-дефолт 8.8.8.8, нет: `RenderYAML`
  пишет `cfg.DNS` всегда; при пустом DNS рендерится `dns: ""`, что у
  upstream даёт `ErrDNSServerRequired` (fail-closed), а не дефолт.
  Оговорка: шаг 3 PlanResolver легитимно вернёт 8.8.8.8, если это
  системный nameserver хоста — это выбор системы/плана, не протечка
  дефолта бинаря. В конфиге жизненного цикла теста — `1.1.1.1:53` из
  плана, `8.8.8.8` отсутствует.
- **Ключ ровно из Password**: `ConfigFromOutbound` берёт
  `KeyHex = o.Password`; рендер пишет его в `crypto.key` дословно —
  мой тест сверяет строку `key: "<PSK>"` в файле на диске.
- **SOCKS-креды согласованы и эфемерны**: мой
  `TestReviewSocksCredsConsistentAndEphemeral` — пара user/pass в
  YAML-файле **равна** паре в переписанном аутбаунде, который получил
  inner-движок; два свежих сайдкара получают разные пары
  (`ephemeralCreds`, crypto/rand, `olcwrap.go:506`). Порт — не
  константа: `supervise.FreePort()` (случайный свободный loopback-порт,
  `olcwrap.go:344`).

## 4. Безопасность сайдкара — подтверждено

- Файл `0600` (с принудительным chmod — существующий файл WriteFile не
  сужает), каталог `0700` (`writeConfigFile`, `olcwrap.go:492`;
  жизненный тест сверяет оба mode на диске).
- Удаление: при `Stop`/`Close`/вытеснении конфигурации файл удаляется,
  слушатель гаснет (тест исполнителя + мой рестарт-тест ниже). При
  смерти на старте `start` сам вызывает `sc.stop` — inner не
  применяется, ошибка `KeyEngineStartFailed` (тест исполнителя).
- **Смерть посреди сессии** (моего контрпримера у исполнителя не
  было): SIGKILL живому сайдкару → `keep` (`olcwrap.go:388`) поднимает
  новый процесс **на том же порту** за <15 с (факт ~0.6 с), конфиг на
  время рестарта сохраняется (новый процесс его читает), после `Stop`
  удалён. До рестарта порт отказывает — fail-closed, не утечка.
- Ключ в логах: вывод идёт через редектор, засеянный секретами и
  идентификаторами применённого плана (`Apply` пересобирает
  `e.redactor` из `p.Secrets()+p.Identifiers()`, куда ключ входит как
  Password, токен — через `Outbound.appendSecrets`, комната — через
  `appendIdentifiers`); тест маскирования зелёный. В argv ключа нет —
  только путь конфига; `Config.Key()` содержит секреты только хэшами.
- Слушатель только loopback: рендер жёстко пишет `host: "127.0.0.1"`,
  Rewrite — `Server: "127.0.0.1"`; иного пути задать host нет.
- **Digest mismatch → fail-closed**: тест исполнителя зелёный; мои
  варианты на архиве (`TestReviewTamperedBinaryRejected`): (а) бинарь
  подменён после записи манифеста — не discovered; (б) записи olcrtc
  в `engines.digests` нет вовсе — не discovered; (в) бинарь без
  exec-бита при верном дайджесте — не discovered. Во всех случаях
  фабрика отвечает `KeyEngineBinaryMissing` до выбора движка
  (`registry.go:279`).

## 5. Матрица и отказы — подтверждено, таблица исполнителя дополнена

Код: `ValidateConnect` (`olcwrap.go:183`) + структурная половина в
`engine.validateOlcrtc`. Коды каталога (`core/errs/catalog.go:156-160`)
совпадают с таблицей TRANSPORT.md §5 (combination=Unsupported,
token_required/not_connectable=FailedPrecondition,
server_mode/invalid=InvalidArgument).

Мой `TestReviewMatrixComplete` закрывает то, чего в таблице
исполнителя нет: **все 12 пар** 3 провайдеров × 4 транспорта —
включая пропущенную исполнителем `wbstream+videochannel`
(подключаема, верно по матрице settings.md) — плюс `none` × все 4
транспорта (везде `not_connectable`, отказ стоит до проверки матрицы)
и `wbstream+datachannel`: без токена `token_required`, с токеном
проходит (и там, и в тесте исполнителя).

**Обход `mode: srv` не найден.** Проверены все поверхности:

- `OlcrtcConfig.Mode` — режется в трёх слоях независимо:
  `validateOlcrtc` (план), `ValidateConnect`, `RenderYAML`; регистр
  не спасает (`"SRV"`, `"gen"`, `"cnc "` — все отказ, мой тест).
- Через `Params`: рендерер пишет `mode: cnc` безусловно первой
  строкой, а Params смотрит только по словарю транспорта —
  `Params{"mode":"srv"}` в YAML не протекает (мой
  `TestReviewSrvViaParamsDoesNotRender`).
- Через общее поле документа `mode` (XHTTP): ложится в
  `Transport.Mode`, который olcwrap вообще не читает.
- Через proto напрямую: у контракта поля режима для olcrtc нет;
  fallback в `outboundFromProto` создаёт конфиг с `Mode ""`.
- Через `provider none` + engine.*: `ConfigFromOutbound` никогда не
  заполняет `EngineName/URL/Token` из плана, а `none` отказывает до
  рендера — прямого SFU из плана не собрать.
- YAML-инъекция через комнату/провайдера: все строки —
  `strconv.Quote`; комната с `\r\n\x00` дополнительно режется
  валидацией.

**Пробинг честный**: мой `TestReviewMeasureOlcrtcIsErrNoEngine` на
архиве — `Registry.Measure` по olcrtc-аутбаунду отдаёт ровно
`ErrNoEngine` с нулевой латентностью (ни один движок не заявляет
протокол в каталоге → orphan-ветка), не фейковый замер.

## 6. Порядок обёрток — подтверждено

`registry.go:350-360`: `olcwrap.Wrap` — внутренняя, `bypass.Wrap` —
внешняя; селекция движка идёт по плану после обоих Rewrite
(bypass первым в коде фабрики, olcrtc вторым — перестановки
эквивалентны, см. ниже).

Собственный тест композиции (`TestReviewRewriteCompositionWithBypass`):
план с olcrtc- и bypass-аутбаундами одновременно; применение
`bypass.Rewrite` и `olcwrap.Rewrite` в обоих порядках даёт: olcrtc →
SOCKS5 на порт сайдкара с кредами и **сохранённым `Via`**, bypass →
SOCKS5 на tpws-порт (заглушка 1 без запущенного tpws, конвенция
bypass); вызывающий план не мутируется ни в одном порядке. Rewrite
действуют на непересекающиеся протоколы, поэтому композиция не ломает
ни одну сторону. Полный Apply стеком bypass⊃olcwrap в песочнице не
гонялся (нужен настоящий tpws + capability-gate хоста) — это та же
честная граница, что у исполнителя; Validate-цепочка и фабричная
селекция при этом покрыты кодом и тестами выше.

## 7. Пин честности — подтверждено независимо

- **Дайджест перекачан ревьюером**: архив
  `https://github.com/openlibrecommunity/olcrtc/archive/refs/tags/v0.0.1.tar.gz`,
  SHA-256 = `acaaee246e876aed83fd6a21f77c1ff7a8093584ee5a36453ab1803f9a2bcca7`
  — байт-в-байт заявленный в `engines.lock` (все 3 строки) и в
  TRANSPORT.md.
- Тег: аннотированный `v0.0.1` → коммит `3e42ae98…` (TRANSPORT.md
  цитирует коммит верно). Заявка «схема между v0.0.1 и f3ad8fb не
  различается» проверена двумя путями: `git diff 3e42ae9 f3ad8fb --
  internal/config internal/app/session docs` пуст; файлы скачанного
  архива `internal/config/config.go` и весь `internal/app/session/`
  идентичны дереву `f3ad8fb`. (Вне этих путей диффы есть — client/
  engine/transport — но на схему/дефолты/валидацию они не влияют, и
  TRANSPORT.md заявку именно на эти пути и делал.)
- `engines.sig`: `olcrtc none` с обоснованием на месте.
- win7-386: строки нет, исключение задокументировано в трёх местах
  (комментарий lock, ветка fetch.sh, TRANSPORT.md); арифметика
  счётчика fetch.sh сверена со всеми строками lock вручную:
  amd64/arm64 — 4, windows-amd64 — 5, win7-386 — 4 (3 движка +
  wintun, без olcrtc). Сходится.
- Notices/лицензия: строка olcrtc v0.0.1 / WTFPL-2.0 / © zarazaex в
  `THIRD-PARTY-NOTICES.md` на месте; LICENSE в архиве тега — WTFPL v2,
  «Copyright (C) 2026 zarazaex» — совпадает. nfpm.yaml кладёт бинарь
  в `/usr/lib/sora/engines/olcrtc` 0755.

## 8. Метки — подтверждено

`Outbound.Warnings()` (`core/engine/validate.go:216` →
`olcrtcWarnings`, `core/engine/olcrtc.go:135`) для olcrtc отдаёт ровно
`[olcrtc-tcp-only, olcrtc-ipv4-only]`. Мой
`TestReviewPlanWarningsSurface`: на уровне плана метки всплывают из
olcrtc-аутбаунда и не всплывают из direct-аутбаунда того же плана.
SOCKSUDP на olcrtc план-валидация отвергает, Rewrite его никогда не
выставляет — обещание UDP не возникает нигде.

## Замечания

### З-1 (minor) — При ошибке inner Apply сайдкары остаются запущенными до Stop вызывающего

`core/engine/olcwrap/olcwrap.go:320`: `return e.Engine.Apply(ctx, Rewrite(p, dns, listeners))` —
если inner-движок вернул ошибку, уже запущенные этим вызовом
сайдкары не останавливаются внутри `Apply` (та же картина, если старт
второй конфигурации упал после первой). Контрпример ревьюера
(`TestReviewInnerApplyFailureCleanup`, фейковый движок с падающим
Apply): после ошибки — `procs=1`, файл конфига на месте, слушатель
жив; всё убирается только `Stop`.
Смягчающие обстоятельства: паттерн зеркалит `bypass.Apply`;
штатный путь сессии закрыт — `session.Manager` при провале
`created.Start` вызывает `created.Stop`, а `olcwrap.Stop` делает
`stopAll`. Реальный остаток — вызывающие фабрики без Stop и то, что
сайдкар в этот промежуток **активно сидит в комнате провайдера** с
ключом пользователя при уже отказанной сессии (tpws, в отличие от
olcrtc, пассивен). Рекомендация: при ошибке inner Apply останавливать
сайдкары, запущенные этим вызовом, либо явно задокументировать в
пакете контракт «ошибка Apply ⇒ вызывающий обязан Stop».

### З-2 (minor) — Guard восстановления vault асимметричен: документ только с channel/token/mode теряется молча

`core/control/plan.go:917`: `applyCredential` создаёт `OlcrtcConfig`
только если непуст хотя бы один из `olcrtc_provider` /
`olcrtc_transport` / `olcrtc_params`. Документ, несущий только
`olcrtc_channel`, `olcrtc_auth_token` или `olcrtc_mode`, эти поля
теряет без ошибки. Контрпример ревьюера
(`TestReviewVaultModeOnlyDocument`): документ `{"olcrtc_mode":"srv",…}`
даёт конфиг с `Mode ""` — то есть srv при этом **не исполняется**
(по эффекту fail-closed, egress не стартует), но и не отказывается
явно, а просто испаряется.
На легитимный round-trip не влияет: `credentialDocument` для olcrtc
всегда пишет provider+transport вместе. Замечание — про будущее:
TRANSPORT.md §1 заявляет документ «готовым к будущим источникам»
channel/token; источник, который запишет только их, потеряет данные
молча. Рекомендация: расширить условие guard-а на
channel/auth_token/mode (создавать конфиг и при них), чтобы потеря
была невозможна по построению.

### З-3 (minor, тесты) — Таблица матрицы исполнителя неполна при верном коде

`core/engine/olcwrap/olcwrap_test.go`, `TestValidateConnectMatrix`:
нет строки `wbstream+videochannel` (12-я пара матрицы) и нет
`none` на транспортах, кроме datachannel. Код при этом верен —
полнота доказана таблицей ревьюера (п.5), — но пин неполон ровно в
том месте, где регрессия вероятнее всего (новая пара в матрице
upstream). Рекомендация: дополнить таблицу до 12 пар + `none`×4.

### З-4 (наблюдение) — «Дефолты не эмитятся» обеспечивает импорт, не рендерер

`RenderYAML` эмитит любой параметр из `Params`, включая равный
session-дефолту, если план его несёт; отсутствие дефолтов в YAML —
заслуга канонизации парсера (IMPORT.md), а не фильтра рендерера.
Семантически безвредно (upstream применит то же значение), но
формулировку TRANSPORT.md §2 «только параметры из плана» стоит
читать буквально: рендерер дефолты не добавляет и не вычитает.

## Прогоны ревьюера (архив `ed7fed36`, `/tmp/olc-review`)

- `go build ./...` (core) — чисто; `go vet` по
  engine/olcwrap/registry/control/errs — чисто.
- `go test -count=1 ./engine/ ./engine/olcwrap/ ./engine/registry/
  ./control/ ./errs/` — все зелёные; `-race` по olcwrap/registry —
  зелёный. Единственное падение — предсуществующее
  `TestDetectCensorshipEventsWithoutOffsetsStayUnknown` при
  `TMPDIR=$HOME/workspace/.build-tmp` (длина unix-socket пути >108),
  с `TMPDIR=/tmp` зелёное; исполнитель эту оговорку честно заявлял,
  к изменениям отношения не имеет.
- Собственные контртесты (только в архивной копии, в репозиторий не
  вносились): control — `TestReviewVaultAuthTokenAndChannel`,
  `TestReviewVaultModeOnlyDocument`,
  `TestReviewNonOlcrtcDocumentHasNoOlcrtcKeys`; olcwrap —
  `TestReviewMatrixComplete`, `TestReviewSrvViaParamsDoesNotRender`,
  `TestReviewNoDefaultsSynthesized`,
  `TestReviewSocksCredsConsistentAndEphemeral`,
  `TestReviewInnerApplyFailureCleanup` (контрпример З-1),
  `TestReviewRewriteCompositionWithBypass`,
  `TestReviewSidecarKilledMidSessionRestarts`; registry —
  `TestReviewTamperedBinaryRejected`,
  `TestReviewMeasureOlcrtcIsErrNoEngine`,
  `TestReviewPlanWarningsSurface`; upstream —
  `TestReviewSoraGoldenRendersLoadStrict` в дереве скачанного архива
  v0.0.1. Все зелёные, кроме специально зафиксированного поведения
  в З-1/З-2.
- Дайджест архива v0.0.1 перекачан и пересчитан ревьюером (п.7).

## Что не проверялось (честные границы)

- Живой e2e с настоящей комнатой провайдера, TUN и kill-switch —
  остаток interop-отдела по TRANSPORT.md, в песочнице недостижим;
  ревью его не подменяет.
- Полный `fetch.sh` end-to-end (падает на предсуществующей распаковке
  sing-box в userns, до ветки olcrtc) и Windows-сборка бинаря —
  приняты по чтению ветки olcrtc и счётчика; сама ветка (сверка
  архива → сборка → record_digest) прочитана и согласуется с п.7.
- Dart-зеркало ключей ошибок/меток — зона отдела оформления
  (параллельный коммит `e7e63f62`), в это ревью не входило.
