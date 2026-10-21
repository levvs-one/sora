# OpenLibre / olcrtc — транспорт (путь B, сайдкар) — реализация

Подотдел транспорта, департамент OpenLibre. Ветка `bugfix/audit-2026-10-19`,
репозиторий sora. Реализован путь B из TRANSPORT-ANALYSIS.md целиком:
сайдкар `olcrtc` в режиме `cnc` по кальке zapret/tpws. Парсер/подписки не
трогались (идёт параллельное ревью импорта); зоны работ — engine, control,
registry, packaging.

## 1. Vault-перенос (блокер IMPORT.md — закрыт)

`credentialDocument` (core/control/plan.go) для протокола `olcrtc` теперь
пишет в кред-документ, в общем отсортированном порядке ключей:

| Ключ документа | Источник в OutboundSpec |
|---|---|
| `olcrtc_provider` | `Options["olcrtc_provider"]` |
| `olcrtc_room` | `Options["olcrtc_room"]` (fallback — Host) |
| `olcrtc_transport` | `Transport` |
| `olcrtc_params` | JSON: все Options, кроме служебных `olcrtc_*` и `olcrtc_meta_*` — то есть каждый транспортный параметр под URI-именем, включая неизвестные (forward-compat парсера не теряется) |
| `olcrtc_meta` | JSON: поля `##`-блока подписки (префикс `olcrtc_meta_` снят) |
| `olcrtc_channel`, `olcrtc_auth_token`, `olcrtc_mode` | одноимённые Options (ссылка их не несёт; документ готов к будущим источникам) |
| `password` | ключ 64hex (как раньше) |

`applyCredential` восстанавливает из документа `engine.OlcrtcConfig`
(провайдер/комната/транспорт/канал/токен/режим/параметры); битый JSON
параметров — fail-closed, как WireGuard peers. `outboundFromProto`
нормализует контрактную форму в движковую (как WireGuard): proto-transport
(имя olcrtc-транспорта) уходит в `Olcrtc.Transport`, `Transport.Type=""`,
security `olc2` не превращается в TLS, `Server` = комната, `Port=0`.

Тест `TestOlcrtcVaultRoundTrip` (core/control/olcrtc_vault_test.go):
4 ссылки (sei с полным словарём, jitsi datachannel с URL-комнатой, telemost
videochannel tile, wbstream vp8 с не-дефолтными 25/1) → документ →
`outboundFromProto` со стаб-резолвером («рестарт») → `OlcrtcConfig`
DeepEqual исходному, Password/Server/Port на месте, `Validate()` чист,
reference (StableKey) не дрейфует, документ детерминирован побайтно.
Отдельно: `##`-мета в документе; `olcrtc_mode=srv` из документа →
валидация плана отказывает.

Для не-olcrtc серверов документ **побайтно прежний** (поля пусты → field
пропускает), что пинит существующий byte-identity тест кред-документа.

## 2. Рендер конфига сайдкара

Пакет `core/engine/olcwrap` (новый). `RenderYAML` — детерминированный
рендер строго по схеме upstream (`KnownFields`): `mode: cnc` (иной режим
рендерер отказывается производить), `auth.provider[/token]`,
`room.id[/channel]`, `crypto.key`, `net.transport`, `net.dns`, `socks`
(host/port/user/pass), `engine.*` — только если заданы (план их не несёт),
секция транспорта (`vp8`/`sei`/`video`) — только параметры из плана, в
словарном порядке SPEC §3.2:

- vp8channel: `vp8-fps→vp8.fps`, `vp8-batch→vp8.batch_size`
- seichannel: `fps→sei.fps`, `batch→sei.batch_size`, `frag→sei.fragment_size`, `ack-ms→sei.ack_timeout_ms`
- videochannel: `video-w/h/fps/codec/qr-size/qr-recovery/tile-module/tile-rs → video.width/height/fps/codec/qr_size/qr_recovery/tile_module/tile_rs`

Неизвестные и устаревшие (`video-bitrate`/`video-hw`) параметры в YAML не
попадают: у них нет YAML-семантики, а строгий загрузчик чужой ключ
отвергнет; в vault они при этом сохраняются (п.1). Строки — всегда в
кавычках (`strconv.Quote`, подмножество YAML-эскейпов): URL-комната или
комната с `:`/`#` не ломает документ. Нецелое значение известного
int-параметра — ошибка рендера, а не битый YAML.

- **DNS**: `net.dns` — всегда из плана (`PlanResolver`): первый plain/TCP
  резолвер дословно host:port → иначе хост первого резолвера плана на :53 →
  иначе первый nameserver `/etc/resolv.conf` → иначе честная ошибка.
  Дефолт olcrtc 8.8.8.8 не может просочиться: поле обязательно у olcrtc
  (без него `ErrDNSServerRequired`), а рендер его пишет всегда.
- **Порт**: `supervise.FreePort()` (существующий аллокатор core), не хардкод.
- **Креды слушателя**: эфемерные на конфигурацию (crypto/rand), слушатель
  с SOCKS user/pass — не открытый локальный прокси.
- **Файл**: `olcrtc-<hash16>.yaml`, 0600 (с принудительным chmod —
  WriteFile не сужает существующий файл) в home 0700; удаляется при
  остановке конфигурации/Stop. Ключ в argv не попадает (только путь).
- **Логи**: вывод сайдкара — в `logs.Center` под source `olcrtc` через
  редектор, засеянный секретами и идентификаторами применённого плана
  (ключ — это Password аутбаунда, токен и комната тоже в семенах);
  уровни классифицируются как у bypass. Тест пинит: строка с hex-ключом
  в логе замаскирована.

Живой дымовой прогон настоящим бинарём пина (см. п.4): конфиг из моего
golden-рендера принят строгим загрузчиком v0.0.1 без единой ошибки,
клиент дошёл до join в MUC провайдера. Слушатель у upstream открывается
только после установления линка — это учтено в готовности (п.3).

## 3. Декоратор движка

`olcwrap.Engine` по образцу `bypass.Engine`: `Wrap(inner, binary, home, logs)`.

- `Rewrite(plan, dns, listeners)`: olcrtc-аутбаунд → SOCKS5
  `127.0.0.1:<порт>` с эфемерными кредами, `Via` сохраняется (цепочки
  работают), `SOCKSUDP` всегда false; план вызывающего не мутируется;
  без слушателей — порт-заглушка 1 (конвенция bypass). Форма одна для
  всех трёх движков — sing-box/mihomo/Xray получают обычный socks5.
- Дедуп: одна уникальная конфигурация (provider/transport/room/channel/
  key-hash/token-hash/params/dns) = один сайдкар; ключ — sha256, секреты
  в ключ входят только хэшами.
- `Apply`: все ворота до изменения состояния (нет бинаря →
  `KeyEngineBinaryMissing`; матрица/токен/none → п.5; резолвер) →
  старт недостающих → `inner.Apply(rewritten)`. Устаревшие конфигурации
  останавливаются, их файлы удаляются.
- Надзор: `supervise.Start`; готовность — фактический слушатель
  (поллинг порта + `proc.Err()`, кап 30 c: слушатель открывается после
  join конференции — WebSocket-сигналинг + WebRTC; контекст вызывающего
  всё равно ограничивает). Смерть в живой сессии — `keep` с
  `engine.DefaultBackoff()`, рестарт на том же порту/конфиге/кредах;
  до рестарта порт отказывает (fail-closed, не утечка).
- Digest: реестр при discovery проверяет `olcrtc` тем же
  `supervise.VerifyNamedInDir` по `engines.digests`, что и tpws/nfqws
  (SORA-H5, fail-closed; тест на mismatch в registry).
- Реестр (`registry.Factory`): план с olcrtc при отсутствующем сайдкаре —
  `KeyEngineBinaryMissing` до выбора движка; селекция — по переписанному
  (SOCKS5) плану; порядок обёрток явный: **olcrtc внутри, bypass снаружи**.

## 4. Реестр движков и пин релиза

Факт по GitHub (проверено API 2026-10-21): **релизов у
openlibrecommunity/olcrtc нет вообще** — список releases пуст; единственный
тег — `v0.0.1` (коммит `3e42ae98d81280242ad38582896fc47d56dc62c0`).
Собственный `install.sh` upstream раздаёт olcrtc **сборкой из исходников**
(`go build -trimpath -ldflags='-s -w'`). Поэтому пин — на сборку из тега,
как предписывала постановка для этого случая:

- `engines.lock`: три строки `olcrtc` (amd64, arm64, windows-amd64),
  URL — архив тега v0.0.1 на GitHub, digest — **фактический SHA-256
  скачанного архива**: `acaaee246e876aed83fd6a21f77c1ff7a8093584ee5a36453ab1803f9a2bcca7`.
  Схема YAML/дефолты/валидация между v0.0.1 и проанализированным
  f3ad8fb не различаются (diff по internal/config, internal/app/session,
  docs — пуст), то есть SPEC/TRANSPORT-ANALYSIS применимы к пину дословно.
- `fetch.sh`: ветка olcrtc — сверка архива по digest → сборка
  `./cmd/olcrtc` под целевую GOOS/GOARCH (CGO off, флаги install.sh) →
  install в engines-каталог → **дайджест собранного бинаря пишется в
  engines.digests** тем же `record_digest`, что у всех движков (поэтому
  runtime-проверка SORA-H5 работает без изменений). Прогон ветки
  end-to-end в песочнице: архив сверен, бинарь собран (32,5 МБ),
  digest записан. Полный fetch.sh в этой песочнице падает раньше — на
  предсуществующей распаковке sing-box (tar chown в userns), к olcrtc
  отношения не имеет.
- `engines.sig`: `olcrtc none` с обоснованием (подписей upstream не
  публикует; якорь — digest архива в lock + digest бинаря в manifest).
- win7-386 строки нет честно: тулчейн olcrtc (go 1.26+) Windows 7 не
  собирает; счётчик ожидаемых ассетов в fetch.sh пересчитан
  (amd64/arm64 — 4, windows-amd64 — 5, win7-386 — 4).
- `nfpm.yaml`: `olcrtc` → `/usr/lib/sora/engines/olcrtc` (0755).
  Windows-инсталлятор берёт каталог движков glob-ом — `olcrtc.exe`
  попадает без правок. THIRD-PARTY-NOTICES: строка olcrtc v0.0.1, WTFPL-2.0.

Воспроизводимость: два сборочных прогона дали разные digest бинаря
(окружение/тулчейн), поэтому пин стоит на архиве исходников, а digest
бинаря — всегда факт конкретной сборки в engines.digests, как и задумано
механизмом.

## 5. Проверки на подключении (не на импорте)

`olcwrap.ValidateConnect` — вызывается из `Validate` и первым шагом
`Apply` декоратора; импорт их не делает (матрица — свойство подключения):

| Случай | Ключ errs | Код |
|---|---|---|
| telemost + datachannel, telemost + seichannel | `core.olcrtc.combination_unsupported` | unsupported |
| wbstream + datachannel без `auth.token` | `core.olcrtc.token_required` | failed_precondition |
| provider `none` (из ссылки не подключаем) | `core.olcrtc.not_connectable` | failed_precondition |
| `mode: srv` в плане (и в рендере) | `core.olcrtc.server_mode_refused` | invalid_argument |
| битый провайдер/транспорт/ключ/нет комнаты | `core.olcrtc.invalid` | invalid_argument |

Структурная половина тех же правил (реестры, ключ 64hex, комната, srv)
стоит и в `engine.Outbound.Validate` — план с `srv` не проходит даже
`plan.Validate()`. Матрица покрыта табличным тестом: все 12 пар
провайдер×транспорт + токен + none + srv + битые поля.

## 6. Честные ограничения v1

- `engine.Outbound.Warnings()` для olcrtc отдаёт **`olcrtc-tcp-only`** и
  **`olcrtc-ipv4-only`** — существующий механизм capability-меток (по нему
  UI показывает все прочие предупреждения; клиенты локализуют коды).
- `SOCKSUDP=true` на olcrtc-аутбаунде план-валидация отвергает, а rewrite
  никогда не выставляет: UDP через туннель не обещается нигде.
- Пробинг (registry.Measure): olcrtc-аутбаунды сейчас честно получают
  `ErrNoEngine` — замер через движок невозможен без сайдкара; это
  осознанный остаток interop-отделу (ниже), а не тихий фейк замера.

## 7. Тесты

- olcwrap: golden-рендер YAML (datachannel + все транспорты/провайдеры,
  полный словарь sei, tile, кавычки комнаты, отказ srv/не-int,
  непопадание неизвестных/устаревших ключей); rewrite (форма для движков,
  немутация плана, заглушка); жизненный цикл на фейковом сайдкаре
  (sh+python слушатель из YAML): старт/готовность/доступность порта,
  0600/0700, plan-resolver в конфиге и отсутствие 8.8.8.8, дедуп двух
  аутбаундов в один процесс, Stop удаляет конфиг и гасит слушатель;
  смерть при старте → `KeyEngineStartFailed`, inner не применён;
  ворота Apply до состояния; маскирование ключа в логах; PlanResolver
  (plain/TCP/encrypted-fallback/IPv6/system).
- control: vault round-trip (п.1), meta, srv из vault.
- engine: структурная валидация (11 отказов + URL-комната + none без
  комнаты), warnings-метки, секреты/идентификаторы.
- registry: digest-gate сайдкара (match → доступен; mismatch → недоступен
  и фабрика отвечает `KeyEngineBinaryMissing`).
- Реальный бинарь пина в тестах не используется; дымовой прогон им —
  вручную, результат в п.2.

Прогоны: `go build ./...`, `go vet ./...`, `go test ./...` по core —
зелёные; `-race` по olcwrap/registry/bypass — зелёный; модули
service/sync и tools/sora-ext собираются. Оговорка песочницы: при
`TMPDIR=$HOME/workspace/.build-tmp` один предсуществующий тест control
(`TestDetectCensorshipEventsWithoutOffsetsStayUnknown`) падает на длине
unix-socket пути (>108 символов) — с `TMPDIR=/tmp` зелёный, к изменениям
отношения не имеет.

## Ключи локализации для подотдела оформления

Ошибки (errs, EN-summary уже в каталоге core/errs):

- `core.olcrtc.invalid`
- `core.olcrtc.combination_unsupported`
- `core.olcrtc.token_required`
- `core.olcrtc.not_connectable`
- `core.olcrtc.server_mode_refused`

Warning-коды аутбаунда (Warnings(), по образцу прочих):

- `olcrtc-tcp-only`
- `olcrtc-ipv4-only`

Dart-сторону (kit.dart-маппинг) не трогал — это зона оформления; ключи
выше — полный список, который ей нужен от транспорта.

## Что осталось interop-отделу

1. Живой e2e: TUN up + kill-switch + настоящая комната провайдера
   (риск R1 TRANSPORT-ANALYSIS — петля SFU-трафика через TUN; в песочнице
   не проверяется). Сюда же — фактическое время join до открытия
   слушателя на живых провайдерах (кап готовности сейчас 30 c).
2. cnc↔чужой srv сквозь настоящие SFU по всем парам матрицы, включая
   wbstream+datachannel с модераторским токеном (у транспорта токен
   поддержан, живого токена для проверки нет).
3. Пробинг/замер olcrtc-серверов: сейчас `ErrNoEngine` (п.6) — нужен
   замер через сайдкар или честный UI-статус «не замеряется».
4. Windows: бинарь собирается кроссом (fetch валидирован на linux/amd64),
   работа WebRTC на Windows не подтверждена (R3) — при провале триггер
   запасного пути A из TRANSPORT-ANALYSIS.
5. R2 остаточный: ключ лежит в YAML-файле 0600 на время сессии —
   ограничение бинаря (конфиг только файлом), зафиксировано в доке
   olcwrap и здесь.

## Фиксы по ревью

По замечаниям независимого ревью транспорта (TRANSPORT-REVIEW.md,
З-1..З-4; блокеров не было):

- **З-1 (olcwrap.Apply)**: при ошибке inner Apply (и при падении
  старта более поздней конфигурации) сайдкары, запущенные именно
  этим вызовом Apply, останавливаются внутри Apply, их конфиги
  удаляются; сайдкары прежних успешных Apply ретроактивно не
  трогаются, успешный путь и семантика keep/restart не изменились.
  Регрессионные тесты: `TestInnerApplyFailureCleansUpStartedSidecars`
  (procs=0, конфигов не осталось) и
  `TestInnerApplyFailureKeepsEarlierSidecars`.
- **З-2 (control.applyCredential)**: guard восстановления vault
  симметричен — блок создаётся при любом olcrtc-поле конфигурации.
  Выбран вариант «битый документ»: `credentialDocument` пишет
  provider+transport атомарно с остальным блоком, а честного
  дефолтного провайдера не существует, поэтому документ только с
  дополнительными полями (channel/auth_token/mode/room) легитимного
  продюсера не имеет и теперь отказывается с понятной ошибкой
  `incomplete olcrtc credential document` — как битые WireGuard
  peers/params рядом, а не молча теряет поля. srv-эффект остался
  fail-closed: одиночный `olcrtc_mode:"srv"` конфиг не воскрешает
  (ошибка выше), а srv в полном документе по-прежнему режется
  валидацией плана. Тесты:
  `TestOlcrtcVaultPartialDocumentFailsClosed` (включая документ
  «только channel+token» на полном пути плана) и
  `TestOlcrtcVaultChannelAndTokenRestoredWithIdentity`.
- **З-3 (тесты матрицы)**: `TestValidateConnectMatrix` дополнен до
  полных 12 пар провайдер×транспорт (добавлена
  wbstream+videochannel — подключаема) плюс provider `none` на всех
  четырёх транспортах (везде `not_connectable`); код матрицы не
  менялся — он был верен, неполна была таблица.
- **З-4 (формулировка к §2)**: «дефолты не эмитятся» обеспечивает
  канонизация импорта, а не рендерер: рендерер эмитит любой
  параметр из Params как есть, включая равный сессионному дефолту,
  если план его несёт.
