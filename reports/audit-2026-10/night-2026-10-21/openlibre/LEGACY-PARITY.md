# OpenLibre / olcrtc — паритет импорта в sora-legacy

Исполнитель: отдел паритета OpenLibre (legacy). База: HEAD legacy
`c367eef` (фактический на момент старта; основное дерево в это время
держит незакоммиченную работу отдела подъёма legacy — не тронута).
Работа велась в отдельном worktree
`~/workspace/bug-hunt/sora-legacy-olcrtc` на ветке
`openlibre-legacy-parity`. Источники истины: sora
`core/parser/olcrtc.go`, ветка olcrtc в `core/parser/parser.go`,
`core/subscription/olcrtc.go` (коммиты `723b1fb6`, `86651735`, фиксы
З-1..З-6 — `4f5fa7c0`), SPEC.md / IMPORT.md / IMPORT-REVIEW.md этого
каталога, а также vault-фикс транспортного отдела sora в
`core/control/plan.go` (ключи документа `olcrtc_*`).

**Вердикт: паритет импорта полный.** Грамматика, строгость,
сентинелы, корпуса и подписочная семантика совпадают с sora;
единственное расхождение — отсутствие эмиттера ссылок (D-1 ниже),
зафиксированное по условию задачи. Транспорта olcrtc в legacy нет —
это граница паритета, запуск честно отказывает (раздел 4).

## 1. Коммиты (ветка `openlibre-legacy-parity`, поверх `c367eef`)

| Коммит | Состав |
|---|---|
| `ae1413b` [openlibre] parser | `core/parser/olcrtc.go` (новый), `olcrtc_test.go` (новый), правки `parser.go`: схема в `linkSchemes`, ветка olcrtc в `validate()`, материал StableKey, диспатч в `parseLink`, `parseList` с привязкой `##` |
| `c5625ef` [openlibre] subscription | `core/subscription/olcrtc.go` (новый), `olcrtc_test.go`, `olcrtc_internal_test.go` (новые), правки `info.go`: `bodyHeaders` возвращает и текст тела, глобалы применяются в `parseInfo` |
| `b3dfa13` [openlibre] control | `core/control/plan.go`: `olcrtc_*` в `credentialDocument` + allowlist `credentialKeys`; `core/control/olcrtc_vault_test.go` (новый): рестарт-тест vault и пин честного отказа запуска |

Основное дерево legacy и его индекс не трогались вообще; в чужом
дереве на момент сдачи по-прежнему только изменения отдела подъёма.

## 2. Что портировано

- **Грамматика 1-в-1**: разрезы в том же порядке (ключ-якорь `#` +
  ровно 64 hex + конец/`$`; комната — первый `@`; payload вплотную
  к транспорту и закрывает сегмент), закрытые реестры провайдеров
  (`jitsi/telemost/wbstream/none`) и транспортов
  (`datachannel/vp8channel/seichannel/videochannel`), словари
  параметров с диапазонами и enum, tile cross-field правила,
  канонизация дефолтов (включая tile-зависимый дефолт `video-w` и
  ведущие нули), неизвестные ключи сохраняются, deprecated
  `video-bitrate`/`video-hw` сохраняются на импорте. Сентинелы те
  же: `ErrUnsupported` для закрытых словарей, `ErrInvalid` с
  причиной для грамматики/диапазонов.
- **Замечания ревью закрыты сразу, а не повторены**: З-1 (битая
  olcrtc-строка сбрасывает привязку `##` — `lastOlcrtc = -1` в ветке
  ошибки `parseList` для olcrtc-подобных строк; регрессионный тест
  `TestOLCRTCMetaAfterBadLink` портирован), З-3 (дробный `#refresh`
  масштабируется без усечения), З-4 (`#available` добивает Total
  независимо от валидного `#used`), З-5 (datachannel отклоняет и
  пустой `<>`), З-6 (`video-tile-module/rs = 0` — «не задан», не
  требует tile и не хранится). З-2 относится к формулировке
  IMPORT.md про эмиттер sora; в legacy эмиттера нет (D-1). З-6-окно
  глобалов (первые 10 строк тела, `bodyHeaderLines`) — та же
  предсуществующая конвенция пакета в обеих кодовых базах.
- **Подписка**: строки `olcrtc://` в существующем пайплайне
  (`parseList`), `##` привязывается к ближайшей предыдущей
  olcrtc-строке (дубль строки привязывает к дедуплицированной
  записи, не-olcrtc сервер сбрасывает, сирота — Invalid), глобалы
  `#name/#refresh/#used/#available` — в `Info` только для тел,
  реально содержащих `olcrtc://`, и только в пустые поля (панельные
  заголовки выигрывают).
- **Модель сервера** — та же, что в sora: `Protocol="olcrtc"`,
  `Transport` = транспорт olcrtc, `Security="olc2"`, `Host` = RoomID,
  `Port=0`, ключ — в `Password`, провайдер/комната — в
  `Options["olcrtc_provider"/"olcrtc_room"]`, параметры — в Options
  под своими URI-именами, `##`-поля — под `olcrtc_meta_*`,
  `StableKey` включает провайдера и транспорт. `ToProto` legacy
  несёт комнату/транспорт/security/протокол в proto как есть.

## 3. Vault / переживание рестарта (класс разрыва З-7) — починено

В legacy был тот же разрыв, что ревью нашло в sora: `credentialDocument`
писал только закрытый allowlist полей, а `outboundToProto` не имеет
proto-поля под провайдера и параметры — импортированный olcrtc-сервер
терял провайдера, все параметры транспорта и все `olcrtc_meta_*` при
первом же рестарте (переживали только ключ в `password`, комната и
транспорт в proto). Починено в объёме импорта, зеркально vault-фиксу
sora: `credentialDocument` для `protocol == "olcrtc"` пишет
`olcrtc_provider`, `olcrtc_room` (фолбэк — Host), `olcrtc_transport`,
`olcrtc_channel`, `olcrtc_auth_token`, `olcrtc_mode` и два JSON-документа
— `olcrtc_params` (все параметры транспорта, включая неизвестные
ключи) и `olcrtc_meta` (все `##`-поля без префикса); все ключи
добавлены в `credentialKeys`, поэтому `parseCredential` документ
принимает и не режет. Имена и формы ключей совпадают с sora — будущий
транспорт legacy будет восстанавливаться из тех же полей.
Пин: `TestOlcrtcVaultSurvivesRestart` (5 ссылок: параметры, мета,
детерминированность документа, стабильность reference) и
`TestOlcrtcVaultKeepsSubscriptionMeta`.

Восстановление из документа в engine.Outbound сознательно не
делалось: в legacy нет поля под olcrtc-конфигурацию outbound'а —
это зона транспорта, а не импорта (в sora это поле появилось вместе
с транспортом).

## 4. Граница паритета: импорт — полный, транспорт — нет

Транспорта olcrtc в legacy нет (решение родителя). Отдельного
механизма «неподключаемых» меток в legacy не существует — и он не
понадобился: запуск olcrtc-сервера отказывает существующим
механизмом валидации плана. `engine.Outbound.Validate` держит
закрытый whitelist `validProtocols` (ровно константы протоколов
пакета; `olcrtc` среди них нет) и `validTransports` (транспортов
olcrtc там тоже нет), а `planFromProto` заканчивает работу
`plan.Validate()`. Итог: план с olcrtc-outbound отклоняется с
понятной ошибкой `unknown protocol "olcrtc"` (и `unknown transport`
для datachannel и т.д.) — не молчаливый запуск и не паника. Пин:
`TestOlcrtcLaunchIsRefusedHonestly` (outbound- и plan-уровни).

## 5. Взаимная сверка корпусов sora ↔ legacy

- Файлы: `core/subscription/olcrtc.go` и оба его теста портированы
  **байт-в-байт** (diff пуст). `core/parser/olcrtc.go`: весь
  не-комментарный diff против sora — это `sort`-импорт и блок
  `ShareLink`/`emitOLCRTCParams` (D-1) плюс абзац в шапке файла;
  грамматика идентична текстуально. `core/parser/olcrtc_test.go` —
  тот же корпус (дословные примеры sub.md/uri.md, все негативы,
  привязка, З-1/З-5/З-6 регрессии); изменены только три места,
  упиравшиеся в эмиттер (D-1): identity переформулирована как
  детерминированность разбора + StableKey + неканоничность
  дефолтов на импорте.
- Живой прогон: один и тот же файл из 16 строк (10 позитивов —
  документированные примеры и вариации; 6 негативов — короткий
  ключ, неизвестный провайдер, пустой `<>` у datachannel,
  tile-module=0, fps=241, wbstream placeholder `any`) прогнан через
  `LinkParser.Parse` обеих кодовых баз с полным дампом полей
  (протокол/транспорт/security/host/port/имя/страна/ключ/StableKey/
  все Options). **Вывод идентичен байт-в-байт, включая значения
  StableKey.** Расхождений нет.

### Таблица расхождений

| # | Расхождение | Статус |
|---|---|---|
| D-1 | В legacy нет эмиттера share-ссылок: `ShareLink`/`emitOLCRTCParams` не портированы | Осознанно, по условию задачи: генерации per-server ссылок в legacy нет нигде — ни в Go core, ни в Dart app (`app/lib`: нет ни одного упоминания olcrtc и ни одного генератора ссылок; серверные ссылки целиком уходят в core ParseImport), ни в C# клиенте (только импорт). Мёртвый API без вызывающего не добавляли. Если в legacy появится шаринг ссылок — эмиттер sora портируется как есть, грамматика и канонизация под него уже совпадают |
| — | Поведенческих расхождений корпусов (грамматика, валидация, привязка, глобалы, StableKey, vault-документ по ключам/формам) | **нет** |

## 6. Проверка

```text
go build ./...                                  — чисто
go vet ./parser/ ./subscription/ ./control/     — чисто
go test ./parser/ ./subscription/ ./control/    — все зелёные
go test -race ./parser/ ./subscription/         — зелёные
```
(Go: `~/workspace/go/bin/go`, `TMPDIR=$HOME/workspace/.build-tmp`,
`GOCACHE=$HOME/workspace/.gocache-v`, модуль `core/`.) Все
предсуществующие тесты legacy в затронутых пакетах зелёны, включая
`TestLimit`/`TestReportItemsAreBounded` на новом порядке `parseList`.
Замечание: `gofmt -l` ругается на `core/parser/parser.go` — это
предсуществующий на HEAD дефект (пропущенная пустая строка вне
hunk'ов этой работы), не трогал, чтобы не раздувать слияние.

## 7. Инструкция слияния для родителя

1. Сливать после сдачи отдела подъёма legacy: ветка
   `openlibre-legacy-parity` (`c367eef` + 3 коммита выше) в
   `bugfix/audit-2026-10-19`.
2. Ожидаемые точки пересечения с работой отдела подъёма: они сейчас
   держат незакоммиченными `core/parser/parser.go`,
   `core/control/plan_internal_test.go`, `core/engine/redact.go`.
   - `core/parser/parser.go` — единственный реальный риск конфликта:
     мои hunk'и — `linkSchemes`, `StableKey`, `validate()`,
     `parseList`, голова `parseLink`; если отдел подъёма трогал те же
     функции, конфликт решается вручную сохранением обеих правок
     (мои блоки самодостаточны, опираются только на `olcrtc.go`).
   - `core/control/plan.go` отдел подъёма не трогает; мой hunk —
     один блок в `credentialDocument` + 3 строки в `credentialKeys`.
     `plan_internal_test.go` я не трогал (`mapResolver` оттуда
     используется моим тестом как есть).
3. После слияния: `go build ./... && go test ./parser/
   ./subscription/ ./control/` из `core/` должны быть зелёны;
   конфликтов в subscription нет (отдел подъёма её не трогает).
