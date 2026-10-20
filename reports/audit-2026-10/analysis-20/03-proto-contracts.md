# Аналитик №3: proto-контракты и их реализации

Read-only анализ ветки `bugfix/audit-2026-10-19` репозитория `~/workspace/bug-hunt/sora`, 2026-10-20.
Охват: `proto/` (6 файлов), Go-генерация `core/gen/`, Go-реализации (`core/control`, `core/ext/host.go`),
Dart-стабы `app/lib/src/generated/` + ручные стабы `app/lib/src/obfs.dart`, гейты версий в Dart.

## Вердикт

Контрактная дисциплина на Go-стороне — **сильная**: версионирование честное, все 40 RPC CoreControl
реализованы и проверяют версию, теги 1.8–1.10 зафиксированы тестами. Но система в целом —
**рассинхронизирована на трёх швах**:

1. **Dart-стабы заморожены на ~1.8 + точечные правки**: в `core_control.pb.dart` отсутствуют все 22
   сообщения контрактов 1.9/1.10 (бенчмарки, override подписок, профили сетей, ProbeChain), а в
   `core_control.pbgrpc.dart` — 8 из 40 RPC. Dart-клиент физически не может вызвать половину
   возможностей ядра 1.9–1.10.
2. **CustomServers мёртв на проводе**: proto, Go-реализация, Dart-стабы и UI есть, но
   `MountCustomServices` нигде не вызывается в `core/cmd/sora-core/main.go` — сервис не
   зарегистрирован в боевом бинаре. Все 4 RPC возвращают UNIMPLEMENTED.
3. **ExtensionHost — реализованный сервис без единого клиента**: Go-сервер зарегистрирован,
   но ни Dart, ни Go его не вызывают (панели расширений в `app/lib/src/ui/extensions/`
   ходят напрямую через `CoreControl.listConnections` по JS-бриджу). Мёртвый сервис с
   поверхностью атаки (MintToken).

Плюс два «тихих» расхождения честности: `ApplyObfsProfile` документирует требование
control authenticator, которого нет в сообщении; `CoreEvent` содержит два payload-варианта
(`BypassStrategyChanged`, `KillSwitchChanged`), которые ядро никогда не эмитит.

Детали ниже. Все номера строк — по состоянию ветки на момент анализа.

## Сильные стороны

- **Переговор версии честный и покрыт везде**: `core/control/version.go:16` (`Negotiate`),
  `server.go:340` (`checkVersion`), `authz.go:24` (`checkMethodAuth`). Проверкой версии
  покрыты все 40 RPC `CoreControl`, 2 RPC `ObfsControl` (`obfs.go:357,393`), `DetectCensorship`
  (`censor.go:24`), `RunLeakTests` (`leak.go:25`, через `authorize`), 4 RPC CustomServers
  (`custom.go`, через `authorize`). Неизвестные методы по умолчанию control-only (`authz.go:48`).
- **Стабильность тегов зафиксирована тестом**: `core/control/contract_test.go:59`
  (`TestNewFieldTagsAreStable`) пинает wire-теги всех полей 1.8–1.10; `TestSecretMaterialHasExactlyOneCarrier`
  гарантирует, что credential material несёт только `PutSecret`; `TestErrorCodesAreUniqueAndNamed`.
- **Dart честно гейтит то, что умеет**: `link.dart:20` — `ApiVersion(1, 11, minSupportedMinor: 6)`;
  `obfs.dart:710` — `obfsMinApiMinor = 11`, проверки в `sora.dart:400,439`; `sora.dart:1154`
  (`tun_stack` за minor≥7), `sora.dart:1162` (chain/zapret за minor≥10);
  `ui/leaktest.dart:119` маппит UNIMPLEMENTED в `core.api.version_mismatch`, а не во
  «внутреннюю ошибку».
- **Go-генерация — настоящий protoc**: `core/gen/sora/core/v1/core_control.pb.go:1`
  (`protoc-gen-go v1.36.11`), все 6 сервисов сгенерированы, синхронизированы с proto 1.11.
- **`Since`-аннотации в proto** — почти на всех добавлениях 1.3–1.11, с честными
  комментариями про аутентификацию и лимиты.

## Слоп / проблемы

### P0 — Критично

1. **Dart-стабы отстают на два минора: отсутствуют 22 сообщения и 8 RPC (1.9/1.10).**
   `app/lib/src/generated/sora/core/v1/core_control.pb.dart` не содержит ни одного из:
   `BenchmarkRecord`, `BandwidthSample`(есть? — нет: проверено списком), `GetBenchmarksRequest/Response`,
   `SaveSubscriptionOverrideRequest/Response`, `GetSubscriptionOverrideRequest/Response`, `OverrideRule`,
   `NetworkProfile`, `ProfileTriggers`, `ProfileApply`, `NetworkFingerprint`,
   `ListProfilesRequest/Response`, `SaveProfileRequest/Response`, `DeleteProfileRequest/Response`,
   `GetNetworkFingerprintRequest/Response`, `ProbeChainRequest/Response`, `ChainHop`,
   `ProfileMatched` (полный список — 22 имени, получен `comm` по `proto` vs `pb.dart`+`pbenum.dart`).
   В `core_control.pbgrpc.dart` только 32 `ClientMethod` вместо 40; отсутствуют:
   `DeleteProfile`, `ListProfiles`, `SaveProfile`, `GetNetworkFingerprint`, `ProbeChain`,
   `GetBenchmarks`, `GetSubscriptionOverride`, `SaveSubscriptionOverride`.
   Дополнительно: `CoreEvent` в Dart — `..oo(0, [4..11])`
   (`core_control.pb.dart:2138`), поле 12 `profile_matched` отсутствует: события
   автовыбора профиля ядро эмитит (`server.go:872`), Dart их молча роняет.
   Файл при этом подписан «This is a generated file — do not edit»
   (`core_control.pb.dart:1`), хотя правился вручную точечно (добавлены `chain`=15,
   `zapret_with_vpn`=16, `zapret_strategy`=17, `tun_stack`=14 — `pb.dart:733-745`).
   Это ровно тот класс риска, о котором предупреждает `contract_test.go:63`.

2. **CustomServers не смонтирован: 4 RPC мёртвы в проде.**
   `core/control/custom.go:62` (`MountCustomServices`) вызывается только из
   `custom_test.go:67`. В `core/cmd/sora-core/main.go` (регистрация сервисов,
   строки 332–353) нет ни `MountCustomServices`, ни упоминания `custom` вообще.
   При этом Dart-клиент создаёт `CustomServersClient` (`link.dart:75`), UI
   addserver/servers (незакоммиченные правки `app/lib/src/ui/addserver.dart`,
   `servers.dart`) его дёргает — все вызовы получат UNIMPLEMENTED. Комментарий
   в `custom.go:56-59` прямо описывает wiring-шаг, который никто не выполнил.

3. **ExtensionHost: реализован, зарегистрирован, никем не вызывается.**
   `main.go:353` регистрирует `extv1.RegisterExtensionHostServer`, `core/ext/host.go`
   реализует 7 методов, но `grep` по всему репозиторию не находит ни одного
   `NewExtensionHostClient` / `ExtensionHostClient` — ни в Dart, ни в Go.
   Панели расширений (`app/lib/src/ui/extensions/panel_screen.dart:203`) вызывают
   `link.stub.listConnections` напрямую, минуя сервис. Итог: на сокете висит
   сервис с `MintToken`/`RevokeToken`, у которого ноль легитимных клиентов —
   мёртвая поверхность атаки. Заодно: у всего `ext_host.proto` **нет поля версии** —
   `MintTokenRequest`/`WatchExtensionEventsRequest` и др. не несут `ApiVersion`,
   переговора контракта для этого сервиса не существует в принципе.

### P1 — Серьёзно

4. **`ApplyObfsProfile`: комментарий требует authenticator, которого нет в сообщении.**
   `proto/sora/obfs/v1/obfs.proto:53-56`: «Needs the control authenticator».
   Но `ApplyObfsProfileRequest` = `{api_version=1, profile=2}` — поля под токен нет,
   и хендлер (`obfs.go:353-357`) делает только `checkVersion`, без `authorize`.
   Фактическая защита — transport peer должен быть AuthControl (`authz.go`: метод
   не в `readOnlyMethods`). Это разумно, но комментарий proto врёт: читатель
   контракта ожидает токен в запросе. Либо добавить поле, либо поправить комментарий.

5. **Мёртвые payload-варианты `CoreEvent`: `BypassStrategyChanged`, `KillSwitchChanged`.**
   `toWireEvent` (`server.go:809-880`) не имеет для них ни одного `case`;
   `grep` по всему `core/` (исключая `gen/`) не находит ни одной конструкции этих
   сообщений. `KillSwitchChanged` при этом документирован подробно
   (различие enabled vs enforced) — клиент никогда не узнает, что киллсвитч
   «включён, но не применяется». Либо эмитить, либо убрать из контракта.

6. **`minSupportedMinor: 6` в Dart никак не enforced.**
   `link.dart:20` заявляет, что клиенту нужен минимум 1.6 («1.6 is required to open
   subscription pages without exposing links in states»), но после Handshake
   negotiated minor нигде не сравнивается с 6. Со старым ядром 1.5
   `fetchSubscriptionLink`/`openSubscriptionPage` (`sora.dart:1423,1438`) получат
   UNIMPLEMENTED → `CoreFailure.from` (`link.dart:100`) смаппит в
   `core.internal.unexpected`, а не в «обновите ядро». (Для leak-тестов аналогичный
   путь обработан честно — `leaktest.dart:119`.)

### P2 — Средне

7. **Нет политики backward-compat в документации.** `grep -ri backward` по
   `docs/`, `CONTRIBUTING.md`, `core/doc.go` — пусто. `CHANGELOG.md` — пользовательский,
   версии API-контракта не трекает. Правило «только добавлять поля, теги стабильны»
   существует лишь как Go-тест (`contract_test.go:59`), который к тому же покрывает
   только 1.8–1.10, но не 1.11 (`leak`, `obfs`, `censor`, `ext` теги не запинаны).

8. **Несогласованный нейминг:**
   - сервисы: `CoreControl`, `ObfsControl`, `CensorControl` vs `CustomServers`
     (plural), `LeakService`, `ExtensionHost` — три разных суффикса;
   - `ext_host.proto`: `control_token`/`extension_token` vs `control_authenticator`
     во всех остальных proto;
   - RPC `CensorControl.DetectCensorship` — глагол не совпадает с именем сервиса
     (везде иначе `Get*`/`*` без дублирования смысла);
   - `main.go:50`: `control.Version{1, 11, 1}` — контракт уже **1.11**, а не 1.10
     (премисса задачи устарела; Dart уже заявляет 1.11 — `link.dart:20`).

9. **`custom.proto` и `ext_host.proto` без `Since`-аннотаций** — в отличие от
   остальных файлов, невозможно понять, с какой версии существует каждый RPC
   (важно для гейтов типа `obfsMinApiMinor`).

10. **Ручные стабы без pbjson для custom/leak/obfs.** `core_control` имеет
    `.pbjson.dart`, у `custom`/`leak` его нет, у ручного `obfs.dart` — тоже.
    Сейчас `pbjson` нигде не импортится вне generated (проверено), так что
    не баг, а дрейф формата: «generated»-файлы пишутся тремя разными руками.

11. **Незакоммиченные правки стабов в рабочем дереве.** `git status`:
    `app/lib/src/generated/sora/custom/v1/custom.pb.dart` (+189/−332) и
    `custom.pbgrpc.dart` переписаны вручную: старый коммит содержал сдвинутые
    теги (`ListCustomServersResponse { error=1; servers=2 }` против proto
    `{ servers=1; error=2 }`, `TestCustomServerRequest.server=3` против
    `id=3, timeout_ms=4`, `protocol` строкой вместо enum `CustomProtocol`).
    Фикс в worktree правильный, но он (а) не закоммичен, (б) подтверждает, что
    ручные стабы дрейфуют от proto и чинятся вручную постфактум.

### P3 — Мелочь

12. `ApiVersion.capabilities` (`server.go:89-104`: 13 строк + `serverless`) пишется
    ядром, но Dart его нигде не читает.
13. `exthost.go` (`ExtHostDeps.ListServers`) не мержит `CustomOutbounds()`,
    хотя комментарий `custom.go:247-249` прямо требует мержить «into the extension
    host's ListServers».
14. `TokenIssuer.Mint` (`ext/store.go:713`) проверяет, что permissions известны
    (`IsKnownPermission`), но не проверяет, что они входят в granted-набор
    расширения — полагается на «app-only» вызова. Приемлемо, но стоит комментария.

## Ранжированные рекомендации

1. **(P0-1) Синхронизировать Dart-стабы с proto 1.11.** В идеале — поднять
   protoc-gen-dart в CI и генерировать `app/lib/src/generated/` из `proto/`
   (Go-сторона уже генерируется protoc). Пока генератора нет — дописать вручную
   22 сообщения + 8 RPC + поле 12 в `CoreEvent`, затем добавить тест паритета:
   Dart-скрипт, сверяющий множество RPC/сообщений/тегов с дескриптором из Go
   (зеркало `TestNewFieldTagsAreStable`).
2. **(P0-2) Либо вызвать `plane.MountCustomServices(app.server)` в `main.go`
   рядом с остальными Register (строки 332–353), либо удалить сервис из proto
   и Dart.** Сейчас — худшее из двух: UI обещает, ядро молчит.
3. **(P0-3) Решить судьбу ExtensionHost:** либо Dart-клиент реально ходит через
   него (тогда дописать стабы + `ApiVersion` в запросы), либо снять регистрацию
   в `main.go:353` до появления клиентов. Мёртвый привилегированный сервис на
   сокете — неприемлемо.
4. **(P1-4) Починить комментарий `ApplyObfsProfile`** (или добавить
   `control_authenticator` в запрос и проверять через `authorize`, как в
   `custom.go`/`leak.go`).
5. **(P1-5) Убрать `BypassStrategyChanged`/`KillSwitchChanged` из `CoreEvent`
   oneof** (reserved) либо начать их эмитить — сейчас это ложное обещание
   контракта. Если убирать — с тестом, что oneof не растёт молча.
6. **(P1-6) Enforce `minSupportedMinor` в Dart**: после Handshake, если
   `negotiated < 6` — показывать `core.api.version_mismatch`, а не пытаться
   работать (сейчас `fetchSubscriptionLink` даст `core.internal.unexpected`).
7. **(P2-7/9) Завести `proto/CHANGELOG.md`** (или раздел в существующем):
   версия контракта → список RPC/полей; дописать `Since`-аннотации в
   `custom.proto`/`ext_host.proto`; расширить `TestNewFieldTagsAreStable`
   на 1.11.
8. **(P2-8/10) Нейминг и формат стабов:** унифицировать суффиксы сервисов и
   `control_token` → `control_authenticator`; зафиксировать единый формат
   ручных стабов (с `pbjson` или без) и убрать ложный баннер «generated —
   do not edit» с файлов, которые правятся руками.
9. **(P2-11) Закоммитить worktree-фикс `custom.pb.dart`/`pbgrpc.dart`** отдельным
   коммитом с pathspec по этим файлам (осторожно: в дереве конкурирующие
   агенты — см. уроки в `~/AGENTS.md` про pathspec и /tmp).
10. **(P3)** Читать `capabilities` в Dart или убрать поле; домержить
    `CustomOutbounds()` в `ExtHostDeps.ListServers`; комментарий про
    `Mint`-permissions.

## Примечания о покрытии

- Не проверял: содержимое `service/` (установщик/сокет) и `app/test/live_core_test.dart`
  на предмет контрактных тестов Dart — Dart-тулчейна в окружении нет.
- Go-тесты (`contract_test.go`) — прочитаны, не запускались (read-only задача;
  `go vet`/`go test` не выполнялись).
- Все утверждения о «никто не вызывает» — по `grep` на момент анализа;
  динамических вызовов через reflection в Dart/Go не обнаружено.
