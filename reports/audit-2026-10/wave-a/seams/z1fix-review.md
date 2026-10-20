# REJECT-фикс revocation (b015cef1) — независимое ревью

Ревьюер — не автор; задача — опровергнуть. Объект: коммит `b015cef1`
на `bugfix/audit-2026-10-19`, родитель `b4863c85`. Работа — на снимках
`git archive` в `~/workspace/.build-tmp/z1fix_fix|z1fix_parent`
(грязное дерево не тронуто, коммитов ревьюер не делал).

## Вердикт: **ПРИНЯТ**

Опровергнуть не удалось: форма обоих фиксов верна, пины падают на
родителе ровно по заявленным причинам, регрессий в ext нет.

## 1. З-1: аудит copyWith перепроверен независимо

Греп `copyWith` по всему `app/` (lib+test, без generated/protobuf и
TextStyle/прочих чужих типов): вызовов `InstalledExtension.copyWith`
ровно **два**, оба в `store.dart`, ни один не передаёт `previous`:
`_disableRevokedMatches` (стр. 262, `copyWith(enabled: false)`) и
`setEnabled` (стр. 531, `copyWith(enabled: enabled)`).
`install()` (стр. 477) и `rollback()` (стр. 572) конструируют
`InstalledExtension` напрямую: install ставит `previous: cur?.version`,
rollback поле опускает (цепочка после отката очищается намеренно и не
через copyWith). Вызывающего, которому `previous ?? this.previous`
вредит (явная передача или намеренная очистка через copyWith), в
репозитории **нет** — сценария для отклонения не нашлось.

## 2. Сценарий ревью — дословно, фикс зелёный / родитель падает на previous

Авторский тест на снимке фикса проходит в составе сьюта (см. п. 4).
Тот же файл теста, пересаженный на снимок родителя: сценарий падает
**именно на `previous`**, не на чём-либо другом:

```
Expected: '1.0.0'  Actual: <null>   (test/ext_revocation_test.dart:480 —
expect(store2.get(...)!.previous, '1.0.0') после load()-свипа)
```

Т.е. на родителе свип обнуляет указатель отката (дальше rollback умер
бы с «has no previous version»); на фиксе вся цепочка проходит:
свип отключил 2.0.0, previous=1.0.0 сохранён, rollback → 1.0.0,
`setEnabled(true)` проходит гейт.

## 3. З-2 BOM — собственная проба ревьюера (литеральные байты)

Проба `zz_probe_bom_test.dart` (в обоих снимках, не в репозитории):
payload = байты `EF BB BF` + валидный JSON, подпись — настоящим
ed25519 по точным байтам; плюс контроль без BOM.

| Путь | Родитель | Фикс |
|---|---|---|
| `RevocationList.parse` (BOM) | **ACCEPT** (`returned <RevocationList>`) | REJECT |
| `verifyRevocationList`, честная подпись по BOM-байтам | ACCEPT | REJECT |
| `RevocationCache.store` (BOM) | ACCEPT | REJECT |
| `RevocationCache.load` файла с BOM | список | `null` |
| Контроль без BOM: parse/verify/store+load | ACCEPT | ACCEPT |

Авторский пин BOM в корпусе (`'\uFEFF'`-строка) эквивалентен:
`utf8.encode` даёт те же `EF BB BF` — подтверждено моей пробой на
литеральных байтах. Кэш-пути закрыты тем же parse (store и load оба
идут через него).

## 4. Состав и сьюты на снимке коммита

- Состав `b015cef1` — ровно 3 заявленных файла
  (`ext/store.dart`, `ext/revoke.dart`, `test/ext_revocation_test.dart`),
  постороннего нет.
- `flutter test test/ext_revocation_test.dart` — **36/36**.
- `flutter test test/ext_parity_test.dart` — **72/72**.
- Суммарно на родителе с пересаженными тестами: ровно 5 падений —
  rollback-сценарий (previous), авторский BOM-пин и 3 BOM-пробы
  ревьюера; контроль и остальные 35 тестов родителя зелёны.

**Итог: ПРИНЯТ.** З-1 и З-2 закрыты по существу; замечаний нет.
