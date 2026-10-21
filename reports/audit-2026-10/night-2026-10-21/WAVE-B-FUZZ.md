# WAVE-B-FUZZ — длинный фаззинг поверхностей атаки (волна B, часть 2)

Ветка `bugfix/audit-2026-10-19` в обоих репозиториях. Метод: native Go fuzz
(`testing.F`) длинными прогонами по одной поверхности за раз (машина — 2 ядра),
Dart — детерминированный мутационный харнесс под `flutter test` (coverage-guided
движка у Dart нет). Каждый краш: минимальный репродуктор → фикс парой
«исполнитель + независимый ревьюер» → регрессионный корпус в `testdata/fuzz`.
Журнал прогонов (execs/sec, новые корпуса) — `fuzz-journal.log` рядом с этим
отчётом и §4 ниже.

## 1. Инвентаризация поверхностей и целей

### Существовало до волны B

| Поверхность | Цель | Репозиторий |
|---|---|---|
| Парсер ссылок/подписок (все форматы через Detect→Parse) | `parser.FuzzDetect`, `parser.FuzzParseLink` | sora + legacy |
| Манифест расширений | `ext.FuzzParseManifest`, `ext.FuzzParseManifestFull`, `ext.FuzzParseChecksums` | sora |
| Zip-архив .soraext | `ext.FuzzOpenBytes` | sora |
| Revocation-список, URL-политика фетча | `ext.FuzzParseRevocationList`, `ext.FuzzFetchURLPolicy` | sora |
| Редактор логов | `engine.FuzzRedactorNoPanicAndIdempotent` (37+ корпусов, включая краш-корпус отдела цензуры) | sora |

Сиды `FuzzParseLink`/`FuzzDetect` при этом были минимальными (один vless) —
остальные форматные ветки (olcrtc, SIP008, Clash YAML, WireGuard, sing-box,
Xray) фаззер достигал только мутациями через детектор.

### Написано в этой волне (коммиты `94f58292` sora, `2abab09` legacy)

| Поверхность | Цель | Что покрывает |
|---|---|---|
| parser, прямые ветки | `FuzzParseJSONFormats`, `FuzzParseYAML`, `FuzzParseWG` | SIP008/sing-box/Xray JSON, Clash-подмножество на yaml.v3 (алиасы/якоря — отдельными сидами), WG-конфиги |
| parser, olcrtc | `FuzzOlcRTCLink` | ручная грамматика olcrtc:// + инвариант parse∘ShareLink = identity по StableKey (legacy-зеркало пинит детерминизм парса — ShareLink в legacy не портирован осознанно) |
| subscription | `FuzzParseInfo`, `FuzzSplitFallback`, `FuzzProviderRoutingFromPayload` | метаданные из заголовков/тела провайдера, fallback-ссылки, happRouting-payload |
| happrouting | `FuzzDecodePayload`, `FuzzParseJSON` | deep-link/base64/JSON + EncodeLink/Convert на принятых профилях |
| secret (vault) | `FuzzVaultFiles` | файл vault + master-key: мусор, splice-окна в подлинный шифртекст, усечения/расширения; инварианты — fail-closed, Refs⇒Get, запись после открытия |
| control | `FuzzDecodeRecord`, `FuzzStoredListProto`, `FuzzCredentialDocument`, `FuzzLoadObfsProfile`, `FuzzSubscriptionLinkParts` | записи подписок, хранимые proto-списки OutboundSpec, credential-документы, protojson-профиль обфускации, нормализация ссылок |
| custom | `FuzzStoreLoad` | servers.json произвольного содержания |
| profiles | `FuzzStoreLoad`, `FuzzRouteParsers` (linux) | profiles.json; парсеры /proc/net/route и iw link |
| ext | `FuzzParseCatalog`, `FuzzParseBackgroundConfig`, `FuzzParseSignText` | каталог расширений, конфиг фоновых воркеров, текстовые форматы minisign |
| olcwrap | `FuzzValidateAndRender` | валидация конфига сайдкара + рендер YAML; инвариант — ключ туннеля не светится в dedup-Key открытым текстом |
| Dart (app/test/fuzz_mutation_test.dart) | мутации валидных документов, PRNG с фиксированным сидом | `ExtManifest.parse`, `ExtensionCatalog.parse`, `RevocationList.parse` (контракт: только объявленный Exception-тип), `convertHappRouting`, `SyncPairing.decodePairPayload` (контракт: null, без бросков) |

### Вне объёма (осознанно)

- gRPC-каркас: распаковку proto делает grpc-go/protobuf — библиотечный код,
  фаззится через хранимые декодеры control (выше), а не через сетевой стек.
- Рендеры движков (sing-box/xray/mihomo) — генераторы, не парсеры; их вход —
  типизированный план после валидации (валидатор фаззится опосредованно через
  парсеры и credential-документы).
- `core/routing`, `core/censor`, `core/tune`: правила и стратегии задаёт
  локальный пользователь через UI, не удалённая сторона; поверхности
  инвентаризированы, в приоритет волны не вошли.

## 2. DoS-границы (проверено чтением до прогонов)

- parser: `MaxInputSize` 16 MiB на вход, `DefaultMaxItems` 20 000 аутбаундов.
- subscription fetch: `MaxBodyBytes`, лимит редиректов, `io.LimitReader` на
  дрене и теле.
- secret: `MaxSecretBytes` 64 KiB, `MaxSecrets` 4096, `MaxVaultBytes` 8 MiB,
  `MaxReferenceLen` 64.
- ext package: лимиты на размер члена и суммарный объём, считаются по
  фактическим байтам (`readAllLimited`), а не по заголовкам zip.
- Dart catalog/revocation: жёсткие капы размера (4 MiB / `maxRevocationBytes`)
  до декодирования.
- Открытый вопрос к прогонам: yaml.v3 в `parseYAML` не имеет встроенного
  лимита расширения алиасов — вход ограничен 16 MiB, но коэффициент
  расширения алиасов на таком входе фаззер и проверяет (сид с якорем в
  `FuzzParseYAML`).

## 3. Находки и фиксы

### F-1 (Dart, краш контракта) — `convertHappRouting` пропускал ArgumentError

Мутационный харнесс (4000 мутаций): на payload с битым percent-escape
(`…O%ZIx…`) `Uri.decodeComponent` бросает **ArgumentError**, а `_decode`
в `app/lib/src/desktop/happ_routing.dart` ловил только FormatException.
Вызывающий (`ui/routing_import.dart`) ловит null-контракт, а не исключения —
краш на импорте провайдерской ссылки. Go-зеркало (`happrouting.DecodePayload`)
на тех же входах честно возвращает ErrInvalid — паритет восстановлен.
Фикс: `on ArgumentError { return null; }` в percent-ветке. Независимое ревью:
**APPROVE** (откат фикса возвращает краш; валидные входы не затронуты).

### F-2 (Dart, краш контракта) — `SyncPairing.decodePairPayload` пропускал FormatException

Мутации: percent-последовательность с невалидным UTF-8 (`%AA` — одинокий
continuation byte) в значении query: ленивые геттеры `uri.queryParametersAll`/
`queryParameters` декодируют значения как UTF-8 и бросают
`FormatException: Unexpected extension byte`, хотя функция обещает null на
битом входе (поток сканирования QR пэйринга). Фикс: геттеры обёрнуты в
try/on FormatException → return null.

**Регрессия первого фикса, пойманная независимым ревью (REJECT → исправлено):**
первая версия диффа попутно удалила проверку дубликатов query-ключей — дубли
pub/id/port стали принимались с последним значением (ровно сценарий
расхождения сторон, ради которого проверка писалась; падали два пиннутых
вектора `sync_qr_test`). Проверка возвращена одной строкой после try-блока;
итог: sync_qr + happ_routing + fuzz_mutation = **+49, все зелёны**. Урок в
копилку программы: мутационный харнесс ловит утечки исключений, но не тихие
ослабления приёмки — пиннутые векторы и ревью обязательны.

### Расхождения приёмки Dart↔Go (не краши; зафиксировано ревью, риск низкий)

- Pairing `id=%zz`: Dart принимает буквально (`"%zz"` — его query-декодер
  пропускает невалидный escape как есть, не различая `%25zz` и `%zz`), Go
  отклоняет (ParseQuery выбрасывает пару → «no device id»). Обратно:
  `id=%AA`/`%C3%28` — Go принимает сырые байты, Dart после F-2 → null
  (строже; геттер декодирует весь query, включая неизвестные ключи).
  Заголовок sync.dart обещает «app accepts ⇒ daemon accepts» — теперь это
  не вполне правда на краях; аутентификацию несут pub/token + Noise, id —
  только корреляция/отображение, поэтому риск оценён низким. Лечение
  (скан сырого query) — поведение за пределами краш-фикса, на решение
  владельца sync-контракта.
- Happ: сырой JSON с литеральным `%zz` в строковом значении Go принимает,
  Dart → null (направление строгое; до F-1 это был краш).

### F-3 (olcwrap) — ложное срабатывание собственного инварианта цели

`FuzzValidateAndRender` упала за 2 секунды на входе «все поля = "0"»
(корпус `c423a06d891139f5`): мой инвариант «dedup Key не содержит ключ
открытым текстом» сработал на односимвольном ключе — символ встречается
в 64-hex дайджесте с вероятностью ≈98,4%. Независимое ревью: **AGREE,
ложное срабатывание доказано** — `Config.Key()` встраивает секреты
только их SHA-256 суммами; путь через `Params` также чист по построению
(два производителя, секреты исключены явным списком; эксперимент ревью
с секретом в Params — дайджест не содержит). Инвариант исправлен
(вооружён при len(key) ≥ 32; зубы подтверждены: P совпадения ≤ 9,7e-38),
корпус-вход оставлен регрессией. Перепрогон: 8 мин, **6 668 157 exec,
PASS**. Побочное наблюдение ревью (латентное, не находка): `Key()` не
учитывает EngineName/EngineURL — dedup-коллизия станет реальной, если
появится direct-SFU контракт; сегодня поля недостижимы из плана.

### F-4 (olcwrap) — разрыв слоёв валидации: ValidateConnect не проверяет Params

Находка ревью цели (контрпримеры построены вручную, все подтверждены
экспериментально): `ValidateConnect` параметры не проверяет вообще, а
`RenderYAML` отказывает на не-десятичном числовом параметре
(`fps="abc"`, `video-w="notint"`, переполнение `frag`). Легальный по
ValidateConnect конфиг из подделанного/ручного credential document
умирает только в рендере при старте сайдкара, а не честным отказом на
подключении. Это не краш и не обход (парсер ссылок параметры валидирует;
отказ типизированный, `core.olcrtc.invalid`), но ворота подключения
неполны относительно рендера. Рекомендация владельцам olcwrap: перенести
проверку грамматики параметров в `ValidateConnect` (или разделить
отказы явно). В самой цели инвариант переформулирован честно: рендер
после ValidateConnect может отказать только этим типизированным классом;
любая другая ошибка или паника — FAIL.

### Инцидент журнала раунда 1 (целостность данных)

Доставленный runtime вывод о «завершении раунда 1» (включая падение
`ext.FuzzOpenBytes` rc=1) **не подтвердился состоянием диска**: раунд 1 был
убит рестартом runtime ~04:17 на середине FuzzParseJSONFormats (журнал и
кэш корпусов обрываются там же), слоты OpenBytes/ManifestFull в этой линии
не запускались, краш-корпуса не существует, на живом дереве не
воспроизводится. rc=1 классифицирован как недоказанный артефакт убитого
процесса и из находок исключён. Раунд 2 потерял записи журнала после
05:45 при откате ФС; все слоты без физических следов (корпуса в GOCACHE,
логи на диске) перезапущены раундом 2b, и только его журнал — основание
для §4.

## 4. Журнал прогонов

Источники: `fuzz-journal.log` (раунды 1–2, уцелел до 05:53),
`~/.fuzzwork/journal2b.log` (раунд 2b), кэш корпусов GOCACHE, логи
перепрогонов в `~/.fuzzwork/`. Execs — последняя выборка прогона
(нижняя оценка), corpus — финальный размер кэша цели. **Итого по всем
прогонам: ≥ 104 млн выполнений Go-фаззеров** (+ перепрогоны olcwrap
6,67 млн; + Dart 22 000 мутаций).

### sora — парсеры и подписки

| Цель | Слот | Execs | Corpus | Итог |
|---|---:|---:|---:|---|
| parser FuzzParseLink | 20m | ~4 203 308 | 1055 | PASS |
| parser FuzzOlcRTCLink | 15m | ~4 331 409 | 891 | PASS (инвариант identity) |
| parser FuzzParseYAML | 15m | ~1 969 269 | 592 | PASS |
| parser FuzzParseJSONFormats | 12m (2b) | ~12 016 129 | 557 | PASS |
| parser FuzzParseWG | 8m (2b) | ~9 698 402 | 221 | PASS |
| parser FuzzDetect | 8m (перепрогон) | 6 812 799 | 807 | PASS |
| subscription FuzzParseInfo | 10m | ~2 046 289 | 515 | PASS |
| subscription FuzzProviderRoutingFromPayload | 8m | ~2 046 129 | 526 | PASS |
| subscription FuzzSplitFallback | 5m | ~1 248 894 | 240 | PASS |
| happrouting FuzzDecodePayload | 8m (перепрогон) | 11 159 046 | 676 | PASS |
| happrouting FuzzParseJSON | 8m (2b) | ~12 096 087 | 625 | PASS |

### sora — хранимые данные, vault, ext

| Цель | Слот | Execs | Corpus | Итог |
|---|---:|---:|---:|---|
| secret FuzzVaultFiles | 12m | ~7 337 | 17 | PASS (I/O-bound: полная пересборка хранилища на итерацию) |
| control FuzzDecodeRecord | 8m | ~652 344 | 313 | PASS |
| control FuzzStoredListProto | 8m | ~221 053 | 133 | PASS |
| control FuzzCredentialDocument | 8m | ~331 733 | 206 | PASS |
| control FuzzLoadObfsProfile | 8m | ~28 793 | 104 | PASS |
| control FuzzSubscriptionLinkParts | 5m | ~337 729 | 224 | PASS |
| custom FuzzStoreLoad | 6m (2b) | ~534 500 | 318 | PASS |
| profiles FuzzStoreLoad | 6m (2b) | ~1 330 591 | 415 | PASS |
| profiles FuzzRouteParsers | 5m (2b) | ~3 745 553 | 134 | PASS |
| engine FuzzRedactorNoPanicAndIdempotent | 12m | ~351 601 | 387 | PASS |
| engine/olcwrap FuzzValidateAndRender | 8m (2b) | — | — | rc=1 — F-3 (ложное срабатывание цели); перепрогоны после исправления: 8m / 6 668 157 exec PASS + 3m PASS |
| ext FuzzParseManifestFull | 12m (2b) | ~3 679 059 | 422 | PASS |
| ext FuzzParseManifest | 10m (2b) | ~3 672 185 | 322 | PASS |
| ext FuzzOpenBytes | 15m (2b) | ~826 430 | 46 | PASS |
| ext FuzzParseRevocationList | 8m (2b) | ~2 078 356 | 438 | PASS |
| ext FuzzFetchURLPolicy | 5m (2b) | ~1 903 020 | 318 | PASS |
| ext FuzzParseChecksums | 5m (2b) | ~2 034 475 | 197 | PASS |
| ext FuzzParseCatalog | 8m (2b) | ~1 776 366 | 397 | PASS |
| ext FuzzParseBackgroundConfig | 5m (2b) | ~1 741 001 | 456 | PASS |
| ext FuzzParseSignText | 5m (2b) | ~1 457 661 | 138 | PASS |

### legacy — паритет

| Цель | Слот | Execs | Corpus | Итог |
|---|---:|---:|---:|---|
| parser FuzzParseLink | 15m (2b) | ~5 509 802 | 1548 | PASS |
| parser FuzzOlcRTCLink | 10m (2b) | ~3 933 526 | 1067 | PASS (детерминизм) |
| parser FuzzParseYAML | 10m (2b) | ~2 165 073 | 794 | PASS |
| parser FuzzParseJSONFormats | 10m (2b) | ~4 641 212 | 638 | PASS |
| parser FuzzDetect | 6m (2b) | ~2 541 222 | 455 | PASS |
| parser FuzzParseWG | 6m (2b) | ~2 688 951 | 235 | PASS |
| subscription FuzzParseInfo | 8m (2b) | ~3 658 039 | 611 | PASS |
| subscription FuzzSplitFallback | 5m (2b) | ~2 906 343 | 283 | PASS |
| secret FuzzVaultFiles | 10m (2b) | ~8 670 | 21 | PASS |

### Dart

| Набор | Объём | Итог |
|---|---:|---|
| fuzz_mutation_test (5 парсеров + регрессии) | 22 000 мутаций, PRNG-сид фиксирован | PASS после F-1/F-2 (до фиксов: 2 утечки исключений) |
| sync_qr + happ_routing + fuzz_mutation (приёмка фиксов) | +49 тестов | PASS |

## 5. Непроверяемое в этой среде

- Ничего из фаззинга не требует сети/привилегий: все цели — чистые
  декодеры и файловые форматы; среда выполнения — та же песочница, что у
  остальных отделов волны.
