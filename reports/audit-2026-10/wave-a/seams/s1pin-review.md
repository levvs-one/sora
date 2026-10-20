# S1pin-ревью: независимая проверка follow-up коммита 5f98a724 (пины $json / стриминг / строгий nested)

Ревьюер: независимый, не автор. Объект: коммит `5f98a724` «[seams-s1] parity
pins: pin Dart $json maps and grpc streaming shape, strict nested descriptor
compare» — follow-up к `ff3a7f95`, закрывающий три слепых пятна из
`s1-review.md` (M2: $json не пинился; M3: стриминг в pbgrpc не пинился;
nested-сравнение нестрогое, proto.Equal 131/133 из-за map_entry у двух
RenamesEntry). Коммитов ревьюер не делал.

## Вердикт: ПРИНЯТ

Все три заявленных закрытия подтверждены независимыми мутациями (плюс три
дополнительные мутации сверх задания — все пойманы). Ни одна мутация не
прошла незамеченной. Прежние проверки ff3a7f95 не ослаблены: diff теста —
чисто аддитивный, за исключением одной удалённой строки-заглушки. Whitelist
ровно из двух пунктов проверен по коду и по контракту; утверждение о
безвредности gap'ов подтверждено чтением pb.dart.

## Методика и база прогонов

- Worktree: `~/workspace/.build-tmp/wt-s1pin-review` (detached, вне основного
  грязного дерева). Мутации гонялись на самом коммите `5f98a724`:
  релевантные файлы байт-идентичны на всём отрезке `5f98a724..HEAD`
  (`git diff 5f98a724..HEAD --stat` по двум тестовым файлам и
  `app/lib/src/generated/sora/core/v1/` — пусто), поэтому база эквивалентна
  текущему HEAD для всех проверяемых поверхностей.
- Почему не HEAD напрямую: worktree, созданный от тогдашнего HEAD
  `fffd20b0`, валидной базы не дал — пакет не собирался:
  `engine/singbox/render.go: g.Selected undefined` (в fffd20b0 попали чужие
  swept-in hunks render.go без поля `Group.Selected`; инцидент того же
  класса, что описан в AGENTS.md, и уже закрыт выше по ветке коммитом
  `3e2f738c` «repair fffd20b0: drop swept-in hunks»). (Поправка после
  сдачи: промежуточное уведомление о якобы PASS на fffd20b0 финальным
  результатом того же прогона не подтвердилось — билд упал; на вердикт
  это не влияет, все прогоны ниже выполнены в foreground на 5f98a724 и
  3e2f738c.) Чтобы ревью не зависело от движущегося чужого дерева,
  мутации выполнены на 5f98a724, а на отремонтированном потомке
  `3e2f738c` сделан контрольный прогон — PASS по всем 4 тестам, блобы
  тестовых файлов те же.
- Go: `export PATH=$HOME/workspace/go/bin:$PATH
  TMPDIR=$HOME/workspace/.build-tmp GOCACHE=$HOME/workspace/.gocache-v`,
  прогоны из `core/`, точечно `-run`, всегда `-count=1`. Каждая мутация
  применялась точечно, после прогона откатывалась `git checkout --`;
  финальное состояние worktree — чистый 5f98a724.

## Scope коммита — ПОДТВЕРЖДЕНО

- `git show 5f98a724 --stat`: ровно 2 заявленных файла, посторонних hunks
  нет: `core/control/dart_descriptor_parity_test.go` (+536/−1) и
  `core/control/contract_test.go` (+1/−1).
- contract_test.go: единственное изменение — шапка комментария
  `contract 1.8-1.10` → `1.8-1.11` (текст коммита честно говорит «comment
  only»); таблица тегов `TestNewFieldTagsAreStable` не тронута.
- Идентичность блобов: в worktree `git hash-object` дал
  `c0bc040a…` (dart_descriptor_parity_test.go) и `eaa4b588…`
  (contract_test.go) — совпадают с блобами коммита 5f98a724 один в один;
  протестировано ровно то, что закоммичено.

## Базовый прогон — PASS

На чистом 5f98a724 (и повторно после всех откатов мутаций, и на 3e2f738c):

- `TestDartEmbeddedDescriptorsMatchGoContract` — PASS
- `TestDartJSONMapsMatchGoContract` — PASS
- `TestDartGrpcStubsMatchGoContract` — PASS
- `TestNewFieldTagsAreStable` — PASS

## Мутации (каждая — в worktree, каждая откачена)

### M2 ($json): flow удалён только из OutboundSpec$json — ПОЙМАНА, как заявлено

Удалена ровно одна строка `{'1': 'flow', '3': 10, …}` из блока
`OutboundSpec$json` в `core_control.pbjson.dart` (бинарный дескриптор не
тронут; diff — 1 deletion). Результат:

- `TestDartJSONMapsMatchGoContract` — FAIL:
  `message OutboundSpec: $json has 10 fields, Go contract has 11`;
  `$json lacks field flow (10)`.
- `TestDartEmbeddedDescriptorsMatchGoContract` — остался зелёным.

Ровно протокол из задания и из текста коммита.

Дополнительно (сверх задания): в поле flow добавлен непиненный ключ
`'7': 'x'` → FAIL: `$json carries unpinned key "7"` (строка 514) — защита
от «выросшего» компонента $json работает, а не только от удаления.

### M3 (стриминг): watchEvents ResponseStream→ResponseFuture — ПОЙМАНА

Одна замена в клиентском стабе `core_control.pbgrpc.dart`:
`$grpc.ResponseStream<$0.CoreEvent> watchEvents(` →
`$grpc.ResponseFuture<…>`. Результат — FAIL:
`Dart pbgrpc stub WatchEvents returns ResponseFuture, Go contract
server-streaming=true wants ResponseStream` (строка 689).

Дополнительно: обратная мутация (getStatus ResponseFuture→ResponseStream)
тоже поймана: `GetStatus returns ResponseStream, Go contract
server-streaming=false wants ResponseFuture`. Пин двусторонний, а не
только «у стримов должен быть Stream».

### M4 (nested): переименование поля внутри RenamesEntry — ПОЙМАНА строгим сравнением

Временный Go-хелпер (в worktree, удалён после) декодировал
`saveSubscriptionOverrideRequestDescriptor` из pbjson, переименовал
nested-поле `key`→`kez` внутри `RenamesEntry` (json_name и всё остальное
не тронуты; dump до/после: `key(1,json=key) value(2)` →
`kez(1,json=key) value(2)`). Топ-левел поля сообщения не изменились, т.е.
старый полевой цикл эту мутацию не видит в принципе. Результат — FAIL
именно на строгой ветке (строка 190): `message
SaveSubscriptionOverrideRequest: Dart descriptor differs from the Go
contract beyond the known map_entry gaps`, в prototext-диффе —
`name: "kez"` против `"key"` в nested_type.

Дополнительно (enum): переименование самого enum в дескрипторе
(`GroupType`→`GroupTypf`, только бинарный дескриптор, $json не тронут) —
старый цикл сравнивал у enum только значения и это бы пропустил —
поймано: строка 220, `enum GroupType: Dart descriptor differs from the
Go contract` (proto.Equal для enum'ов работает).

## Whitelist knownDartMapEntryGaps — ПОДТВЕРЖДЕНО

- В коде ровно 2 пункта, оба RenamesEntry:
  `SaveSubscriptionOverrideRequest.RenamesEntry`,
  `GetSubscriptionOverrideResponse.RenamesEntry`. Других нет.
- Полнота: во всём контракте ровно два map-поля
  (`core_control.proto:752` и `:771`, оба `map<string,string> renames`) —
  третьего map entry, который мог бы «протечь» мимо whitelist, в контракте
  не существует.
- Gap реален: dump обоих Dart-дескрипторов — у RenamesEntry
  `options=<nil>`, тогда как Go-контракт несёт `options{map_entry: true}`.
- Безвредность — подтверждена чтением `core_control.pb.dart`:
  `SaveSubscriptionOverrideRequest` (BuilderInfo, ~строка 9099):
  `..m<$core.String, $core.String>(4, …, 'renames',
  entryClassName: 'SaveSubscriptionOverrideRequest.RenamesEntry',
  keyFieldType: OS, valueFieldType: OS)`;
  `GetSubscriptionOverrideResponse` (~строка 9359): аналогично
  `..m<…>(1, …, entryClassName: 'GetSubscriptionOverrideResponse.RenamesEntry', …)`,
  геттеры `renames => $_getMap(…)`. Dart-рантайм берёт map-поведение из
  BuilderInfo, а не из встроенного дескриптора — утверждение коммита
  верно.
- Нормализация не маскирует прочее: мутация «ещё один options-бит на том
  же whitelisted типе» — `RenamesEntry.options.deprecated=true`
  (map_entry по-прежнему отсутствует) — ПОЙМАНА (строка 190, в диффе
  `deprecated: true`). Логика forgive чинит только `MapEntry` и только
  при `want.MapEntry=true && got.MapEntry=false` на whitelisted пути;
  остальное proto.Equal сравнивает как есть. Неизвестный/лишний nested
  тип логикой не проглатывается (цикл идёт по got, расхождение ловит
  proto.Equal).

## Прежние проверки ff3a7f95 не ослаблены — ПОДТВЕРЖДЕНО

- Diff `ff3a7f95:…parity_test.go` → `5f98a724:…parity_test.go` (185 → 720
  строк): удалена ровно одна содержательная строка —
  `_ = protoreflect.MethodDescriptor(md)` (no-op заглушка в grpc-тесте),
  заменённая настоящей проверкой стриминга. Всё остальное — добавления.
- Полевой цикл дескрипторного теста (byNumber, сверка
  name/type/label/type_name/json_name, счётчик полей, guard от лишних
  дескрипторов) сохранён verbatim и дополнен строгим сравнением, а не
  заменён им.
- `TestNewFieldTagsAreStable`: таблица тегов (включая полную запись
  OutboundSpec на 11 полей из ff3a7f95) не изменена; изменён только
  диапазон в комментарии.
- $json-тест и grpc-тест — новые поверхности поверх старых: grpc-тест
  сохранил проверку путей `/sora.core.v1.CoreControl/<Method>` и обратный
  guard, добавив индекс сигнатур и обратный guard по нему.

## Замечания (не блокирующие)

- Рукописный парсер $json покрывает только подмножество литералов
  protoc-gen-dart; при несовпадении формата тест падает с Fatal/«unpinned
  key», а не проходит молча — направление отказа безопасное, но при
  будущей регенерации стабов тест может потребовать расширения парсера.
  Это свойство, а не дефект фикса.
- Стриминг пинится только по клиентским стабам pbgrpc (серверные
  хендлеры на `$async.Stream` regex намеренно не матчит) — это ровно
  заявленный в коммите объём («client signatures»), замечание лишь
  фиксирует границу пина.

## Итог

Follow-up `5f98a724` делает ровно то, что заявляет: M2, M3 и нестрогость
nested-сравнения из `s1-review.md` закрыты тестами, чья сила подтверждена
мутациями ревьюера (3 заданные + 3 дополнительные, все пойманы), whitelist
map_entry точен и безвреден, прежние пины не ослаблены. Вердикт: ПРИНЯТ.