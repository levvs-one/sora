# S1-ревью: независимая проверка фикса кластера S1 (стык совместимости)

Ревьюер: независимый, не автор. Объект: коммит `ff3a7f95` «[seams-s1] dart
pbjson: OutboundSpec descriptor gains flow/flow_auto (1.11) + Go parity pins»
и утверждения §1 отчёта `s1-grpc-l10n.md`.

## Вердикт: ПРИНЯТ С ЗАМЕЧАНИЯМИ

Сам фикс корректен и полон: все четыре утверждения автора подтверждены
независимыми проверками (местами — более сильными, чем у автора). Замечания
касаются не кода фикса, а силы пин-теста и точности формулировок: тест не
пинит три вещи, которые текст коммита/отчёта позволяет считать запиненными
($json-таблицы, nested-типы, стриминг в pbgrpc). Точные сценарии — в разделе
«Замечания»; все три подтверждены фактическими мутациями.

## Методика ревью

- Чистый sparse-checkout HEAD (`16a8d8ba` на момент финальных прогонов) вне
  рабочего дерева (основное дерево загрязнено WIP других отделов, включая
  proto 1.12). Файлы ревью (`core_control.pbjson.dart`, `pb.dart`,
  `pbgrpc.dart`, `contract_test.go`, `dart_descriptor_parity_test.go`)
  байт-в-байт неизменны на всём отрезке `ff3a7f95..HEAD` — проверено
  `git diff ff3a7f95..HEAD --stat` (пусто).
- Декодирование дескрипторов — двумя независимыми путями: (а) ручной
  wire-парсер DescriptorProto на чистом Python (без protobuf-библиотеки);
  (б) Go-утилита на `protodesc`/`descriptorpb` из модуля core.
- Мутационные тесты — в одноразовом checkout, после каждой мутации файл
  восстанавливался `git checkout --`; в репозитории коммитов ревьюер не делал.

## Проверка утверждений автора

### 1. Дрейф существовал — ПОДТВЕРЖДЕНО

- proto (`core_control.proto:258,261`): `string flow = 10`, `bool flow_auto = 11`,
  «Since 1.11». Dart `core_control.pb.dart:1347-1348`: `..aOS(10, 'flow')`,
  `..aOB(11, 'flowAuto')`. UI реально читает: `app/lib/src/ui/servers.dart:450`
  — `_FlowBadge(flow: shown.flow, auto: shown.flowAuto)`.
- Pre-fix pbjson (из `ff3a7f95^`): независимый декодер показал в
  `outboundSpecDescriptor` ровно 9 полей и в `OutboundSpec$json` ровно
  9 записей — flow/flow_auto отсутствовали в обоих местах.

### 2. Scope коммита — ПОДТВЕРЖДЕНО

- `git show ff3a7f95 --stat`: ровно 3 файла (pbjson +19/−7 в одном сообщении,
  `contract_test.go` +9, новый `dart_descriptor_parity_test.go` +185),
  посторонних hunks нет.
- Побайтовое сравнение всех 133 дескрипторов pre-fix vs post-fix: изменился
  ровно ОДИН — `outboundSpecDescriptor`. Остальные 132 байт-идентичны:
  поля ДРУГИХ сообщений при «пересборке дескриптора» не поехали.

### 3. Пересобранный дескриптор и $json — ПОДТВЕРЖДЕНО (сильнее, чем у автора)

- Декодированный post-fix `outboundSpecDescriptor` (Python-парсер):
  id=1/string, display_name=2/string, protocol=3, transport=4, security=5,
  endpoint=6/message `.sora.core.v1.Endpoint`, credentials=7/message
  `.sora.core.v1.CredentialsRef`, bypass=8/message `.sora.core.v1.BypassStrategy`,
  display_protocol=9/string, **flow=10/string/json_name=`flow`,
  flow_auto=11/bool/json_name=`flowAuto`** — полное совпадение с proto
  (номера, имена, типы, label, type_name, json_name).
- Go-проверка: байты Dart-дескриптора OutboundSpec **равны**
  `proto.Marshal(protodesc.ToDescriptorProto(Go OutboundSpec))` — т.е.
  дескриптор совпадает с тем, что несёт Go-контракт, сгенерированный из
  текущего proto (protoc-gen-dart на VM нет; Go-protodesc — авторитетный
  контракт, расхождений именно по OutboundSpec нет).
- `$json` ↔ дескриптор: все 11 записей `OutboundSpec$json` сверены с
  декодированным дескриптором (имя/номер/label/тип/type_name/json_name) —
  расхождений нет.

### 4. Тесты: поведение до/после и сила — ПОДТВЕРЖДЕНО с оговорками (см. замечания)

- На чистом HEAD: `TestDartEmbeddedDescriptorsMatchGoContract`,
  `TestDartGrpcStubsMatchGoContract`, `TestNewFieldTagsAreStable` — PASS
  (два независимых прогона, Go из `~/workspace/go/bin`, из `sora/core`,
  `-count=1`).
- Мутация M1 (в checkout подставлен pre-fix pbjson целиком): тест падает
  ровно так, как заявил автор, и ни на чём больше:
  `message OutboundSpec: Dart descriptor has 9 fields, Go contract has 11`;
  `lacks field flow (10)`; `lacks field flow_auto (11)`. Утверждение «до
  фикса падал ровно на этом дрейфе» — правда.
- `TestNewFieldTagsAreStable`: запись OutboundSpec добавлена полностью
  (все 11 полей, не только новые 10/11) — сверено чтением теста.

### 5. Побочное утверждение: 40/40 RPC, 5 стримов, три стороны — ПОДТВЕРЖДЕНО

Независимый подсчёт по proto / Go file descriptor / Go grpc-gen / Dart pbgrpc:

- RPC: proto = 40, Go service descriptor = 40 методов, Dart pbgrpc = 40
  различных путей `/sora.core.v1.CoreControl/<Method>`; множества имён
  совпадают на всех сторонах.
- Server-streaming ровно 5 на всех сторонах, с совпадающими типами ответов:
  WatchEvents→CoreEvent, ProbeServers→ProbeResult, WatchLogs→LogEntry,
  WatchSubscriptions→SubscriptionState, BenchmarkServers→BandwidthSample
  (Go: `serverStream=true` ровно у этих пяти; Dart: `ResponseStream<...>`
  ровно у этих пяти).
- Выборочная сверк
...[truncated 3862 chars]