# Power-run 04 — Контракты API/proto (Go ↔ Dart ↔ proto)

Агент №4. Ветка `bugfix/audit-2026-10-19`, рабочая копия `~/workspace/bug-hunt/sora`.
Метод: все 108 base64-дескрипторов из `core_control.pbjson.dart` декодированы и
сравнены программно (Go, `protoreflect` из Go-codegen как эталон) по каждому полю:
tag, имя, тип, repeated, type_name, oneof, proto3_optional; плюс ручная сверка
`pb.dart`/`pbgrpc.dart`, `link.dart`, `main.go`, `contract_test.go`, `ext_host`.

Применён ФИЛЬТР СЛОПА владельца: каждая рекомендация ниже имеет вердикт —
«реально лучшее» или «слоп/спорно, не делать». Спорное помечено честно.

## Сводка

- Расхождений найдено: **31** (2 wire-бага + 1 пробел в тестах + 28 отсутствующих стабов).
- Исправлено коммитами `[power-run]` (без пуша): **3** позиции.
- Топ-3:
  1. **Dart `BenchmarkServersRequest` имел сдвинутые теги** — пропущены `request_id` (#3)
     и `url` (#7); app слал `server_ids` на теге, который ядро читает как `request_id`.
     F2-бенчмарки были мертвы на проводе. Исправлено.
  2. **Dart-клиент заявлял API 1.8, ядро — 1.10** — negotiation упирался в 1.8, и гейт
     `link.minor >= 10` в `sora.dart` безусловно отключал proxy chains (F8) и
     zapret-with-VPN (F11). Бамп до 1.10. Исправлено.
  3. **В Dart-стабах нет 8 RPC и 20 сообщений 1.9/1.10** (профили, оверрайды,
     ProbeChain, GetBenchmarks, `ProfileMatched` в oneof `CoreEvent`). App их сейчас
     не вызывает (профили/оверрайды — client-side по дизайну), дописывать вручную
     НЕ стал — вердикт фильтра: слоп/риск. Правильный фикс — `buf generate`
     (protoc-gen-dart уже прописан в `proto/buf.gen.yaml`).

## Таблица: RPC/поле → proto → Go → Dart → статус

### Версионирование

| Позиция | proto / Go | Dart | Статус |
|---|---|---|---|
| `Version` ядра | `core/cmd/sora-core/main.go:47` → `1.10` (min 1) | `app/lib/src/core/link.dart:12` было `1.8` (min 6) | ❌ было → ✅ исправлено: `1.10` (min 6) |
| Negotiation | `core/control/version.go:12` — min(client,server), пересечение min-поддержки | `link.dart:56` — `negotiatedVersion.minor` → `link.minor` | ✅ корректна обеими сторонами |
| Гейты фич в app | — | `sora.dart:962` tunStack ≥ 1.7; `sora.dart:970` chain/zapret ≥ 1.10 | ✅ есть; до бампа второй гейт был недостижим |
| `sync`-сервис | отдельный модуль `service/sync/go.mod`, core API не импортирует | — | ✅ не зацеплен |

### SessionPlan — новые поля

| Поле | proto | Go (`core_control.pb.go`) | Dart (`pb.dart`) | Статус |
|---|---|---|---|---|
| `tun_stack` = 14, string | ✅ | ✅ `:1013` | ✅ `:743` aOS(14) | ✅ |
| `chain` = 15, repeated string | ✅ | ✅ `:1017` | ✅ `:744` pPS(15) | ✅ |
| `zapret_with_vpn` = 16, bool | ✅ | ✅ `:1021` | ✅ `:745` aOB(16) | ✅ |
| `zapret_strategy` = 17, BypassStrategy | ✅ | ✅ `:1024` | ✅ `:746-747` aOM(17) | ✅ |

### BenchmarkServers (1.9) — БЫЛ WIRE-БАГ

| Поле | proto | Go | Dart (было) | Статус |
|---|---|---|---|---|
| `request_id` = 3, string | ✅ | ✅ | ❌ отсутствовало | ✅ исправлено |
| `server_ids` = 4, repeated string | ✅ | ✅ | ❌ было на теге 3 | ✅ исправлено → 4 |
| `duration_s` = 5, uint32 | ✅ | ✅ | ❌ было на теге 4 | ✅ исправлено → 5 |
| `concurrency` = 6, uint32 | ✅ | ✅ | ❌ было на теге 5 | ✅ исправлено → 6 |
| `url` = 7, string | ✅ | ✅ | ❌ отсутствовало | ✅ исправлено |
| `BandwidthSample` 1..5 | ✅ | ✅ | ✅ типы/теги совпали | ✅ |
| RPC `BenchmarkServers` (stream) | ✅ | ✅ `core_control_grpc.pb.go` | ✅ `pbgrpc.dart:311,475` путь `/sora.core.v1.CoreControl/BenchmarkServers` | ✅ |

### CheckDnsLeaks (1.8)

| Позиция | proto | Go | Dart | Статус |
|---|---|---|---|---|
| `CheckDnsLeaks` RPC | ✅ | ✅ | ✅ `pbgrpc.dart:411` | ✅ |
| `DnsLeakCheck` 1..6, `CheckDnsLeaksRequest/Response` | ✅ | ✅ | ✅ дескрипторы совпали | ✅ |

### Отсутствует в Dart (1.9/1.10) — app не вызывает

RPC (Go 40 методов, Dart-клиент 30; пути проверены — все 30 вида
`/sora.core.v1.CoreControl/<Name>` корректны):

| RPC | proto+Go | Dart |
|---|---|---|
| `GetBenchmarks` | ✅ | ❌ нет |
| `SaveSubscriptionOverride` / `GetSubscriptionOverride` | ✅ | ❌ нет |
| `ListProfiles` / `SaveProfile` / `DeleteProfile` / `GetNetworkFingerprint` | ✅ | ❌ нет |
| `ProbeChain` | ✅ | ❌ нет |

Сообщения (20): `BenchmarkRecord`, `GetBenchmarksRequest/Response`,
`SaveSubscriptionOverrideRequest/Response`, `GetSubscriptionOverrideRequest/Response`,
`OverrideRule`, `ProfileMatched`, `NetworkProfile`, `ProfileTriggers`, `ProfileApply`,
`ListProfilesRequest/Response`, `SaveProfileRequest/Response`, `DeleteProfileRequest/Response`,
`GetNetworkFingerprintRequest/Response`, `NetworkFingerprint`, `ProbeChainRequest/Response`,
`ChainHop`.

Особо: `CoreEvent.profile_matched` = 12 — есть в proto/Go и в `contract_test.go`,
но в Dart `CoreEvent_Payload` (`pb.dart:2075-2133`) его нет. Ядро при совпадении
профиля шлёт событие, Dart складывает его в unknown fields и молча теряет.
Функционально безвредно сейчас (app матчит профили локально, `sora.dart:890`),
но это именно та щель, ради которой написан новый тест.

### ext_host

| Позиция | Статус |
|---|---|
| proto `proto/sora/ext/v1/ext_host.proto` (6 RPC) ↔ Go codegen | ✅ совпадает |
| Dart-стабы ext_host | отсутствуют — и **не нужны**: `grep` по `app/lib` — ни одного обращения к `ExtensionHost`/`MintToken`/`extension_token`. Панели — WebView с JS-мостом, мост в ext_host не ходит | ✅ |

### Типы / oneof / дефолты

- Несоответствий типов (int32 vs int64, string vs bytes) среди присутствующих
  сообщений: **нет** (проверено компаратором по всем 108 дескрипторам).
- `bytes_per_sec` uint64 ↔ Dart `$fixnum.Int64` — корректное отображение protobuf.dart.
- proto3-дефолты: `url=""` → ядро берёт дефолтный speedtest-URL; `request_id=""` →
  ядро генерирует `req_<hex>` (`server.go: requestID`). App `url`/`requestId` не
  выставляет — поведение корректно.
- Неизвестные поля: обе стороны на proto3 — старое ядро игнорирует новые поля
  от нового клиента; новый клиент складывает неизвестное от нового ядра в
  unknown fields. Проверено: гейты в `sora.dart` не дают слать 1.10-поля ядру < 1.10.

### contract_test.go

- Было: покрывал negotiation, oneof `CoreEvent` (включая 12=ProfileMatched),
  redaction, secret-carrier, коды ошибок. Теги новых полей **не пинил**.
- Стало: добавлен `TestNewFieldTagsAreStable` — пинит теги всех полей 1.8–1.10
  (28 сообщений). ✅

## Расхождения (файл:строка)

1. `app/lib/src/core/link.dart:12` — `apiVersion` minor 8 при ядре 1.10 → **исправлено**
   (коммит `1d71e18`).
2. `app/lib/src/generated/sora/core/v1/core_control.pb.dart:8533` — класс
   `BenchmarkServersRequest`: теги 3/4/5 вместо 3..7, нет `requestId`/`url` →
   **исправлено** (коммит `1d71e18`; сверено с дескриптором Go байт-в-байт).
3. `app/lib/src/generated/sora/core/v1/core_control.pbjson.dart:1871,1884` —
   `$json` и base64-дескриптор того же сообщения → **исправлено** тем же коммитом.
4. `core/control/contract_test.go` — не пинил теги 1.8–1.10 → **исправлено**
   (коммит `f931167`, тест проходит).
5. `app/lib/src/generated/.../core_control.pbgrpc.dart` — нет 8 RPC 1.9/1.10
   (методы клиента заканчиваются на `watchSubscriptions`, `:413`) → **не чиню**,
   см. вердикт ниже.
6. `app/lib/src/generated/.../core_control.pb.dart:2075-2133` — в oneof
   `CoreEvent` нет `profileMatched` → **не чиню вручную**, см. вердикт ниже.

## Что осталось (с вердиктами фильтра слопа)

- **[ОСТАЛОСЬ] Дописать Dart-стабы для 8 RPC + 20 сообщений 1.9/1.10.**
  Вердикт: ❌ НЕ дописывать вручную. Это ровно та работа, которая породила баг №2
  (hand-written дескриптор против спеки). Правильный фикс — прогнать
  `buf generate` там, где доступен protoc-gen-dart (уже настроен в
  `proto/buf.gen.yaml`), и удалить HAND-WRITTEN пометки. Ручное дописывание 20
  классов — функциональный шум: сейчас их никто не вызывает (профили/оверрайды
  живут в app: `profiles.dart`, `overrides.dart` — осознанно client-side).
- **[ОСТАЛОСЬ] `dart analyze` / компиляция app.** Тулчейна Dart на этой машине нет
  (как и в прошлых прогонах); правки pb.dart проверены балансом скобок и
  побайтовой сверкой дескриптора с Go-эталоном, но на dev-машине нужен
  `dart analyze` перед мержем.
- **[CROSS-REF] Чужие WIP-прото:** `proto/sora/{leak,obfs,censor,custom}/v1/*.proto`
  и Dart-стаб `app/lib/src/generated/sora/leak/` — untracked, помечены автором
  «RECONCILE BEFORE MERGE». Согласованность их контрактов — тому, кто их
  приземляет; не моя зона.
- **[CROSS-REF] Ветка сейчас не собирается целиком:** `core/engine/validate.go`
  (`validateHysteria2Tuning`/`validateTUICTuning` undefined) и `core/control`
  (`obfsProfilePath`/`loadObfsProfile` undefined) — чужая незавершённая работа
  sibling-агентов, не связано с моими правками. Мой тест проверен изолированно
  (только gen-пакет) — PASS.

## Что починил (коммиты, без пуша)

- `1d71e18` `[power-run] contracts: fix Dart BenchmarkServersRequest wire tags, bump client API to 1.10`
  (`pb.dart`, `pbjson.dart`, `link.dart`)
- `f931167` `[power-run] contracts: pin 1.8-1.10 field tags in contract_test.go`

Проверки: Go build+vet для `core/control`, `core/gen` — ок там, где пакет
собирается; новый тест — PASS. Временные утилиты сравнения удалены из дерева.
