# S1: Dart ↔ Go core (gRPC) + l10n — фрагмент отчёта отдела совместимости стыков

Репозиторий: `sora`, ветка `bugfix/audit-2026-10-19`, HEAD на момент старта
`5ba2d079`. Проверки — скриптовые (python3) + дескрипторы из Go-gen через
`protodesc` (авторитетный дамп всех полей/методов), точечные `go test`.
Dart-проверки только статические: `pub get` не запускался (pubspec.lock грязный
чужим отделом), тулчейна protoc-gen-dart нет — стабы ведутся вручную, что и
делает этот стык холодным.

## 1. proto ↔ Go-gen ↔ Dart-стабы

**Методика.** Из каждого `.proto` извлечены все RPC (с направлением стриминга),
все сообщения (имя поля, тег, тип, repeated/map), все enum. Сверено тремя
независимыми путями: (а) protobuf-теги в Go `*.pb.go`; (б) Dart `*.pb.dart`
(`@TagNumber` + BuilderInfo: номер и имя поля); (в) байт-в-байт дескрипторы:
Go-дамп `protodesc.ToFileDescriptorProto` против base64-дескрипторов,
встроенных в Dart `*.pbjson.dart` (имя, номер, label, тип, type_name,
json_name каждого поля; значения enum). Пункт (в) — самый сильный: метод
сначала валидирован на неизменённых сообщениях (ApiVersion, Endpoint:
Dart base64 == Go marshal побайтно).

**CoreControl (proto/sora/core/v1/core_control.proto): СОВМЕСТИМ, кроме одного
разрыва в pbjson (ниже).**
- 40 RPC в proto = 40 в Go grpc-gen = 40 клиентских стабов в Dart pbgrpc
  (пути `/sora.core.v1.CoreControl/<Method>` совпадают множественно).
- Стриминг (server-streaming, 5): `WatchEvents`, `ProbeServers`, `WatchLogs`,
  `WatchSubscriptions`, `BenchmarkServers` — в Dart все 5 объявлены
  `ResponseStream` (5/5), типы ответов совпадают (`CoreEvent`, `ProbeResult`,
  `LogEntry`, `SubscriptionState`, `BandwidthSample`).
- Реализации на сервере: 39 из 40 RPC имеют обработчик в `core/control`
  (server.go, logs.go, subscriptions.go, profiles.go, chain.go, override.go,
  dnsleak.go, benchmark.go). Исключение — осознанное: `GetBenchmarks`
  удалён в PASS1 M3 (комментарий в proto и в `core/control/benchmark.go:200`):
  клиент его никогда не вызывал (в Dart-коде вне generated — 0 вызовов),
  метод падает в `UnimplementedCoreControlServer`, сообщения оставлены для
  wire-совместимости. Не разрыв, а документированный RETIRED.
- 125 сообщений, 8 enum: номера/имена/типы полей совпадают proto↔Go↔Dart
  полностью, enum-значения совпадают (включая SoraErrorCode 0–11).
- `CoreEvent.payload` (oneof, теги 4–13) совпадает на всех трёх сторонах;
  пин — существующий `TestCoreEventPayloadKinds`.

**РАЗРЫВ (исправлен, см. коммиты): `OutboundSpec` в Dart pbjson отстал.**
Поля 1.11 `flow = 10` (string) и `flow_auto = 11` (bool) есть в proto, в
Go-gen и в Dart `core_control.pb.dart` (BuilderInfo `..aOS(10,'flow')`,
`..aOB(11,'flowAuto')`, UI реально читает `shown.flow`/`shown.flowAuto` в
`app/lib/src/ui/servers.dart:450` — бейдж vision), но отсутствовали в
`core_control.pbjson.dart`: и в `OutboundSpec$json` (9 полей вместо 11), и во
встроенном base64-дескрипторе `outboundSpecDescriptor`. Бинарный wire не
страдал (protobuf.dart сериализует по BuilderInfo), страдал JSON-кодек
(`fromJson`/`toProto3Json` терял бы flow) и любой потребитель дескриптора.
Фикс: в pbjson добавлены обе записи $json и дескриптор, пересобранный из
Go-контракта (`protodesc` → marshal → base64, метод побайтно валиден на
соседних сообщениях); добавлен пин-тест
`core/control/dart_descriptor_parity_test.go`, который декодирует ВСЕ 133
встроенных Dart-дескриптора (125 сообщений + 8 enum) и сверяет с Go-контрактом
поле-в-поле, плюс сверяет Dart pbgrpc-стабы с Go service-дескриптором. До
фикса тест падал ровно на OutboundSpec.flow/flow_auto, после — зелёный.
Заодно теги OutboundSpec добавлены в `TestNewFieldTagsAreStable`
(contract_test.go пинил только 1.8–1.10, 1.11-поля не пинились нигде).

**Остальные сервисы: СОВМЕСТИМЫ.**
- `sora.custom.v1.CustomServers` (4 RPC): proto↔Go↔Dart (pb.dart+pbgrpc)
  полное совпадение полей и методов; реализация — `customServer` в
  `core/control/custom.go` (все 4), регистрация — `RegisterCustomServers`
  рядом с основным сервером.
- `sora.leak.v1.LeakService` (1 RPC, streaming `RunLeakTests`): совпадение
  полное; Dart-стаб — `ResponseStream<LeakTestResult>`; реализация —
  `core/control/leak.go`.
- `sora.obfs.v1.ObfsControl` (2 RPC): Go-gen совпадает с proto полностью.
  Dart-клиент **рукописный** (`app/lib/src/obfs.dart`, не generated):
  сверка по `@TagNumber` — все 6 сообщений совпадают по номерам полей
  (ObfuscationProfile 1–6, ApplyObfsProfileRequest 1–2, Response 1–4,
  EngineObfsCapabilities 1–8), enum UtlsProfile (0–10) и ObfsPreset (0–4)
  совпадают по значениям. Реализация — `core/control/obfs.go` (обе RPC).
- `sora.censor.v1.CensorControl` (1 RPC `DetectCensorship`): proto↔Go полное
  совпадение; реализация — `core/control/censor.go`, регистрация в main.
  **Dart-клиента у RPC нет — частичный стык (документированный, не скрытый):**
  `app/lib/src/core/censor.dart` прямо пишет, что on-demand poll — graceful
  no-op (`fetchVerdict == null`), а вердикты приходят push-путём через
  `CoreEvent.censorship_detected` (поле 13 oneof). Push-путь сверен до
  строк: Go `core/censor/types.go` Kind.String() выдаёт ровно
  {no_interference, rst_injection, handshake_timeout, dns_poisoning,
  sni_blocking, ip_blocking, data_stall, unknown}; Dart
  `CensorVerdict.fromWire` знает те же строки, пороги уверенности
  0.35/0.75 соответствуют комментарию контракта. Вердикт: работает через
  события; спека на будущее — сгенерировать Dart-клиент DetectCensorship,
  если понадобится on-demand диагностика. Критичности нет: отсутствие RPC
  не ломает ни один существующий сценарий.
- `sora.ext.v1.ExtensionHost` (6 RPC, streaming `WatchExtensionEvents`):
  proto↔Go полное совпадение (включая пустые RevokeTokenResponse/
  NotifyResponse — структуры есть, полей нет); реализация — `core/ext/host.go`.
  Dart-клиента нет и не требуется: потребитель — процессы расширений, не UI.

Регистрация в `core/cmd/sora-core/main.go`: CoreControl, CustomServers,
LeakService, ObfsControl, CensorControl, ExtensionHost — все шесть
зарегистрированы.

`sora-legacy` — вне объёма S1: у него собственный, более старый срез proto
(нет BenchmarkServers/CheckDnsLeaks/profiles RPC и др.) и C#-клиент; это стык
legacy-кластера, здесь не проверялся.

## 2. Негоциация версии API

**СОВМЕСТИМ, доказано исполняемыми тестами (добавлять было нечего).**
- Dart объявляет: `app/lib/src/core/link.dart:20` —
  `ApiVersion(major: 1, minor: 11, minSupportedMinor: 6)`.
- Core принимает: `core/cmd/sora-core/main.go:50` —
  `control.Version{Major: 1, Minor: 11, MinSupportedMinor: 1}`.
- Семантика одинаковая с обеих сторон, потому что Dart её не реализует сам:
  негоциация — только на core (`core/control/version.go: Negotiate` +
  `server.go: checkVersion`): major должен совпасть; результат —
  `min(client.minor, server.minor)`, если он ≥
  `max(client.minSupportedMinor, server.minSupportedMinor)`, иначе
  `KeyAPIVersionMismatch` (CodeVersionMismatch). Для текущей пары:
  диапазон пересечения [6..11] → negotiated 11.
- Dart-сторона потребляет результат честно: `CoreLink` берёт
  `answer.negotiatedVersion.minor`, handshake-ошибка превращается в
  `CoreFailure(answer.error.userMessageKey)` → `errVersion` в UI.
- Исполняемый пин уже существует и зелёный:
  `core/cmd/sora-core/version_test.go: TestVersionContract` — пинит обе
  константы (core == 1.11/min 1; Dart-клиент в тесте записан литералом
  1.11/min 6 со ссылкой на link.dart), позитивный кейс Negotiate == 11 и
  негативный major=2. Плюс табличный `TestNegotiate` в
  `core/control/contract_test.go` (highest-common, границы min, no-common,
  major mismatch) и e2e handshake в `core/control/e2e_test.go`.
  Прогон в этой сессии: `TestVersionContract`, `TestNegotiate` — PASS.
  Замечание (не разрыв): Dart-константа в Go-тесте продублирована литералом —
  при бампе link.dart без правки теста тест упадёт только если забудут и
  core-сторону; это ровно та защита, ради которой тест написан (комментарий
  в нём это фиксирует).

## 3. Ошибки (errs.Key) и wave/event-сообщения → UI

**Строгий вердикт: ни один ключ не доходит до UI нелокализованным —
СОВМЕСТИМ по букве; есть разрыв специфичности (спека ниже).**
- Источник правды: `core/errs/catalog.go` — 70 ключей `core.*`; вне каталога:
  `core/session` KeySelectionChanged (`core.session.selection_changed`) и
  16 ключей `ext.*` в `core/ext`.
- Путь до UI единственный: `SoraError.user_message_key` (proto-поле 2) или
  gRPC-статус `"<code> <key>"` → Dart `CoreFailure(key)` → ЕДИНСТВЕННАЯ
  функция отрисовки `describe()` в `app/lib/src/ui/kit.dart:689`
  (`reportFailure` и уведомления зовут только её; сырой key нигде не
  показывается — проверено поиском по всем местам использования
  `failure.key`: только сравнения/дедупликация). У `describe()` есть
  терминальный fallback `_ => s.errGeneric` («Что-то пошло не так» /
  "Something went wrong") и префиксный `core.plan.* → s.errServers`.
  Сырой ключ пользователю не виден никогда.
- Покрытие специфичными строками: 33 ключа `core.*` имеют точный кейс в
  describe(); ещё 10 `core.plan.*` покрыты префиксом (errServers). Все 6
  `app.*`-ключей Dart имеют точные кейсы.
- **РАЗРЫВ специфичности (minor, UX; исправление — СПЕКА, не код: файлы ARB
  прямо сейчас переписываются чужим отделом тулчейнов, все 31 не-ru ARB
  грязные; добавлять ключи в 32 файла и перегенерировать strings_*.dart
  в этом состоянии нельзя).** 21 используемый ключ `core.*` падает в
  безликую errGeneric: core.connections.unavailable,
  core.diagnostics.failed, core.diagnostics.too_large,
  core.engine.stalled, core.engine.unstable, core.generic.not_found,
  core.guard.proxy_failed, core.logs.unavailable, core.logs.filter_invalid,
  core.logs.export_failed, core.probe.invalid_endpoint,
  core.probe.no_endpoints, core.probe.too_many, core.request.cancelled,
  core.request.too_large, core.secret.not_found,
  core.secret.reference_invalid, core.secret.too_large,
  core.subscription.not_found, core.subscription.interval_invalid
  (+ core.internal.unexpected → errGeneric по замыслу, это его семантика).
  Спека фикса: добавить в describe() кейсы на существующие строки, где
  смысл совпадает точно (engine.unstable/stalled → отдельная строка про
  нестабильный движок; guard.proxy_failed → строка про системный прокси),
  а для diagnostics/logs/probe/secret.not_found/subscription.not_found
  завести новые ARB-ключи во всех 32 файлах одним коммитом после того,
  как отдел тулчейнов закончит с ARB, + регенерация strings_*.dart.
  Подгонять под неточные существующие строки (типа errSecretStore =
  «хранилище повреждено» для secret.not_found) — слоп, не делать.
- `core.session.selection_changed` — не ошибка: ключ события сессии
  (`core/session/runner.go:806`, EventState), на провод не уходит как
  SoraError; Dart получает состояние типизированным payload-ом CoreEvent.
- Ключи `ext.*` до Dart-UI через CoreFailure не доходят: их потребитель —
  ExtensionHost (процессы расширений) и журналы; Dart ext-UI маппит свои
  сбои своими ARB-строками (extInstallFailed и др.). Единственный
  «мёртвый» ключ: `ext.permission.denied` определён, но вне определения
  нигде не используется (находка для каталога, не для стыка).
- Wave/event-тексты: `CensorshipDetected.explanation/evidence` — свободный
  английский текст из core (`core/censor/detect.go: explain()`), Dart
  показывает его как detail, когда нет своей формулировки для кода
  (censor.dart). Это не ключ, а готовая строка: перевод на стороне core
  невозможен по построению (core не знает локаль) — наблюдение, не разрыв
  стыка; при желании лечится тем же механизмом ключей в будущем контракте.

## 4. ARB-паритет

**СОВМЕСТИМ полностью.** Скриптовая сверка рабочего дерева (важная оговорка:
31 из 32 ARB грязные незакоммиченной работой отдела тулчейнов — они
добавляют `@`-метаданные; наборы ключей при этом не тронуты, app_ru.arb
чистый):

| Файл | Ключей | vs app_ru (шаблон) |
|---|---|---|
| app_ru.arb (template, l10n.yaml) | 666 | — |
| остальные 31 (ar…zh_Hant) | 666 каждый | missing = 0, extra = 0 у всех |

- Плейсхолдеры: ICU-осознанная сверка (`{name}` / `{name, plural/select…}`)
  — расхождений нет. Очевидные «расхождения» наивного regex — артефакт:
  тела plural-кейсов на CJK пишутся без пробелов. Доказательство сильнее
  regex: сгенерированные сигнатуры методов совпадают между локалями
  (напр. `expiresIn(String name, int days)` в strings.dart и strings_ja.dart).
- Геттеры/методы: все 666 ключей покрыты в `app/lib/l10n/strings.dart`
  (594 геттера + параметризованные методы; «ARB keys not covered» = 0),
  и каждый strings_<locale>.dart реализует все (пропусков реализации = 0).
- `@`-метаданные: app_en.arb в рабочем дереве не имеет `@` для 20 ключей —
  это не дефект: template по `app/l10n.yaml` — app_ru.arb, метаданные
  не-шаблонных локалей gen-l10n не нужны; отдел тулчейнов как раз добавляет
  их сейчас (виден в dirty-diff), набор ключей это не меняет.

## Итоговые вердикты

| Стык | Вердикт |
|---|---|
| CoreControl proto↔Go↔Dart pb.dart/pbgrpc (40 RPC, 125 msg, 8 enum) | СОВМЕСТИМ (скрипт + дескрипторы + тесты) |
| OutboundSpec в Dart pbjson ($json + дескриптор) | РАЗРЫВ → исправлен, коммит ниже |
| GetBenchmarks без реализации | СОВМЕСТИМ (документированный RETIRED, клиент не зовёт) |
| custom / leak / obfs (рукописный Dart) / ext | СОВМЕСТИМ (поля, теги, enum, регистрации) |
| censor DetectCensorship без Dart-клиента | ЧАСТИЧНО: push-путь СОВМЕСТИМ до строк Kind; RPC — документированный no-op, спека выше |
| Негоциация версии 1.11 (Dart min 6 / core min 1) | СОВМЕСТИМ, пины TestVersionContract + TestNegotiate зелёны |
| errs.Key → UI | СОВМЕСТИМ по локализации (fallback всегда локализован); РАЗРЫВ специфичности по 21 ключу — спека в §3 (ARB заняты чужим отделом) |
| ARB-паритет 32×666 + код↔ARB | СОВМЕСТИМ |

## Коммиты этого кластера

- `ff3a7f95` — `[seams-s1] dart pbjson: OutboundSpec descriptor gains
  flow/flow_auto (1.11) + Go parity pins` (3 файла: pbjson-фикс,
  `core/control/dart_descriptor_parity_test.go` — новый пин,
  `core/control/contract_test.go` — пин тегов OutboundSpec). Коммит сделан
  temp-index+CAS по рецепту AGENTS.md; родитель на момент лендинга —
  `7413465a`; после коммита `git show --stat HEAD` показал ровно 3 файла;
  целевые тесты (`TestDartEmbeddedDescriptorsMatchGoContract`,
  `TestDartGrpcStubsMatchGoContract`, `TestNewFieldTagsAreStable`,
  `TestNegotiate`, `TestVersionContract`) — PASS на закоммиченном состоянии.

Примечание о дереве: сразу после коммита в общем индексе обнаружился
очередной эпизод staged-откатов (13 файлов, включая полные staged-удаления
моих трёх файлов и чужих свежих файлов, напр. manager_switch_test.go).
История не пострадала (ff3a7f95 на месте, поверх уже лёг чужой коммит
215645e5). Свои 3 файла я нейтрализовал точечно `git restore --staged --
<paths>` (worktree не тронут, содержимое = коммиту). На момент сдачи в
индексе остаются ещё 10 staged-файлов чужих отделов с суммарно −1084 строк
(выглядят как тот же staged-откат, включая packaging/* и core/session/*) —
я их НЕ трогал; родителю стоит проверить/нейтрализовать до следующего
чужого коммита, чтобы откат не уехал в историю.

