# D42 — Dart pb-стабы: сверка hand-written стабов с proto (sora Dart)

Пуша нет. Dart SDK нет — сверка парсером + pin-тест (обязательно прогнать `flutter test test/proto_wire_tags_test.dart` в CI).

## Метод
Написан парсер-сверка: каждый `message`/`enum`/`rpc` из `proto/sora/{core,custom,leak}/v1/*.proto` против `app/lib/src/generated/.../*.pb.dart`, `*.pbenum.dart`, `*.pbgrpc.dart` (номера полей, типы, имена, oneof, RPC-пути). Все base64-дескрипторы из `*.pbjson.dart` декодированы своим декодером DescriptorProto и сверены с proto. Для новых дескрипторов написан энкодер DescriptorProto, fidelity доказан: на всех pre-existing сообщениях даёт байт-в-байт те же дескрипторы, что лежат в pbjson.

## 1. 24 сообщения волн фич отсутствовали в `core_control.pb.dart` — мёртвые на проводе
F2: `GetBenchmarksRequest/Response`, `BenchmarkRecord`; F6: `SaveSubscriptionOverrideRequest/Response`, `GetSubscriptionOverrideRequest/Response` (включая `map<string,string> renames`), `OverrideRule`; F5: `ProfileMatched`, `NetworkProfile`, `ProfileTriggers`, `ProfileApply`, `ListProfilesRequest/Response`, `SaveProfileRequest/Response`, `DeleteProfileRequest/Response`, `GetNetworkFingerprintRequest/Response`, `NetworkFingerprint`; F8: `ProbeChainRequest/Response`, `ChainHop`.
- **Было:** классов нет — вызов этих RPC из Dart невозможен типизированно.
- **Стало:** 24 класса дописаны в стиле protoc-gen-dart (BuilderInfo с точными номерами, геттеры/сеттеры/has/clear/ensure, fromBuffer/fromJson).
- **Эффект:** RPC волн F2/F5/F6/F8 вызываемы с корректными wire-тегами.

## 2. `CoreEvent.profile_matched` (#12) отсутствовал
- **Было:** в proto есть, в стабе нет; oneof был `[4..11]` — событие матчинга профиля не декодировалось.
- **Стало:** поле #12 добавлено: `..oo(0,[4..12])`, `_PayloadByTag`, `CoreEvent_Payload.profileMatched`, `whichPayload`/`clearPayload`, фабрика, акцессоры.
- **Эффект:** `WatchEvents` корректно доставляет `ProfileMatched`.

## 3. 8 RPC отсутствовали в `core_control.pbgrpc.dart`
`GetBenchmarks`, `SaveSubscriptionOverride`, `GetSubscriptionOverride`, `ListProfiles`, `SaveProfile`, `DeleteProfile`, `GetNetworkFingerprint`, `ProbeChain`.
- **Было:** нет методов/дескрипторов.
- **Стало:** client-методы + `ClientMethod`-дескрипторы с путями `/sora.core.v1.CoreControl/<Rpc>` + service-base (`$addMethod`, `_Pre`, abstract).
- **Эффект:** RPC вызываемы по правильным путям.

## 4. `core_control.pbjson.dart` — паритет дескрипторов
- **Было:** reflection/JSON-дескрипторы неполны.
- **Стало:** `profile_matched` в `CoreEvent$json`, 24 `$json`-блока и base64-дескриптора дописаны; все 124 дескриптора сверяются с proto.
- **Эффект:** полный паритет Dart↔Go.

## 5. Pin-тест `app/test/proto_wire_tags_test.dart`
Для каждого нового/тронутого поля кодирует сообщение с одним выставленным полем и ассертит точный tag-varint (`field<<3|wire`) + round-trip для `renames`-мапы и oneof. Падение = дрейф тега = wire-несовместимость.

## Ложные срабатывания (чинить не надо)
`SessionPlan.zapret_strategy` #17 на месте; `leak.pbenum.dart` не нужен (в `leak.proto` нет enum'ов); `custom`/`leak` стабы — полное соответствие.

⚠️ **Инциденты:** сосед смёл staged `pb.dart`+`pbgrpc` в свой `1121593` (shared-index hazard); первый `[detail-fix]`-коммит `cc38c4f` записал пустое дерево (`$$` сменился между exec-вызовами — урок в AGENTS.md: один exec-вызов, фиксированное имя); repair `26774d8` восстановил полное дерево (1269 файлов). Историю не переписывал.

**Известный гэп (вне зоны `generated/`):** `ext_host.proto`, `censor.proto`, `obfs.proto` не имеют generated-стабов вообще; app-код использует hand-written клиенты — Dart-код там не сверялся.
