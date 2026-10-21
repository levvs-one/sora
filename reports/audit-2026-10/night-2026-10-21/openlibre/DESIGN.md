# OpenLibre / olcrtc — оформление (локализация, UI-поверхности, docs, notices)

Подотдел оформления, департамент OpenLibre. Ветка `bugfix/audit-2026-10-19`,
репозиторий sora. Источники: SPEC.md, IMPORT.md, TRANSPORT.md §«Ключи
локализации для подотдела оформления» рядом. Зоны работ — `app/lib`,
`app/test`, `app/assets`, `docs/`; core и proto не трогались.

## 1. Локализация: ключи × локали

EN-саммари в каталоге `core/errs` стояли (сверено: catalog.go:156-160, все
пять ключей). Dart-сторона идёт существующим механизмом: core отдаёт
`userMessageKey` → `CoreFailure(key)` → `describe(S, failure)` в
`app/lib/src/ui/kit.dart`. Туда добавлены все пять маппингов; fallback для
неизвестных ключей прежний (`errGeneric`, сырого текста в UI нет).

Новые ARB-ключи (без плейсхолдеров, по конвенциям соседних `err*`):

| ARB-ключ | Core-ключ / код | EN | RU |
| --- | --- | --- | --- |
| `errOlcrtcInvalid` | `core.olcrtc.invalid` | This olcRTC server is incomplete: check the provider, transport, room and encryption key | Сервер olcRTC заполнен не полностью: проверьте провайдера, транспорт, комнату и ключ шифрования |
| `errOlcrtcCombination` | `core.olcrtc.combination_unsupported` | This olcRTC provider and transport cannot work together | Этот провайдер и транспорт olcRTC не работают вместе |
| `errOlcrtcTokenRequired` | `core.olcrtc.token_required` | This olcRTC server needs a provider account token that the link does not carry | Этому серверу olcRTC нужен токен аккаунта провайдера, которого нет в ссылке |
| `errOlcrtcNotConnectable` | `core.olcrtc.not_connectable` | This olcRTC server cannot be connected from a link alone | К этому серверу olcRTC нельзя подключиться только по ссылке |
| `errOlcrtcServerMode` | `core.olcrtc.server_mode_refused` | Sora only connects to olcRTC servers and does not run one | Sora только подключается к серверам olcRTC, а свой не запускает |
| `olcrtcTcpOnly` | warning `olcrtc-tcp-only` | TCP only | Только TCP |
| `olcrtcIpv4Only` | warning `olcrtc-ipv4-only` | IPv4 only | Только IPv4 |

Все 7 ключей внесены во **все 32 ARB-файла** (`app/lib/l10n/app_*.arb`:
ar, az, be, bn, de, en, es, fa, fr, hi, hy, id, it, ja, ka, kk, ko, ky, pl,
pt, ru, tg, th, tk, tr, uk, ur, uz, vi, zh, zh_Hans, zh_Hant) аккуратными
переводами; термин «olcRTC» не переводится, «комната/room» — как в
отчётах департамента. `flutter gen-l10n` перегенерировал `strings*.dart`
(только добавления геттеров, 0 удалений). Warning-коды получили
Dart-маппинг `warningLabel(S, code)` в том же kit.dart (неизвестный код →
null, сырьём не показывается никогда) — раньше у Dart UI маппинга
warning-кодов аутбаундов не было вообще.

Паритет: проектный `app/test/language_test.dart` (ключи × локали ×
плейсхолдеры по всем языкам) — зелёный.

## 2. UI-поверхности

Новых экранов нет. Что было и что добавлено:

**Уже работало без изменений:**
- Импорт подписки olcrtc: существующий поток (лист серверов → «Добавить
  подписку» → core `SaveSubscription` → fetch → `ParseImport`); тело
  sub.md разбирает core (IMPORT.md), Dart-парсера ссылок в проекте нет и
  не нужен.
- Вставка/скан голой `olcrtc://`-ссылки: `parseImportLink` (desktop/links)
  её спокойно отклоняет (это не URL подписки) — QR/вставка отвечает
  существующей локализованной пометкой «неверная ссылка», падений и
  сырого текста нет. Запинено тестом.
- Отсутствующий бинарь olcrtc: core отдаёт `core.engine.binary_missing`,
  уже замаплен на `errEngineMissing` («Не найдено ядро для этого
  сервера») — отдельная работа не понадобилась.
- Сервер olcrtc в списке: `protocolLine` уже честно показывает
  `OLCRTC | DATACHANNEL | OLC2` из полей OutboundSpec.

**Добавлено (минимальная проводка в существующих паттернах):**
- `describe()` — 5 olcrtc-ключей (п.1): неподключаемые случаи
  (combination/token_required/none/server_mode/invalid) теперь показывают
  локализованную причину вместо общей `errGeneric`.
- Строка сервера: `olcrtcLimits(S, spec)` в servers.dart дописывает в
  detail-строку `_ServerRow` локализованные «Только TCP · Только IPv4»
  для protocol == `olcrtc`. Причина формы: у `OutboundSpec` в proto нет
  поля warnings, поэтому честная пометка выводится в Dart из протокола и
  тех же кодов `olcrtc-tcp-only`/`olcrtc-ipv4-only` через `warningLabel`;
  если interop заведёт warnings в proto — источник поменяется в одном
  месте (`olcrtcLimits`).

**Тесты** (`app/test/olcrtc_test.dart`, 5 тестов, все зелёные):
- describe(): все 5 ключей → свои строки в RU и EN, не generic, без
  сырого `core.` и с «olcRTC»;
- warningLabel: оба кода локализуются, неизвестный → null;
- olcrtcLimits/protocolLine: olcrtc → «Только TCP · Только IPv4» и
  `OLCRTC | DATACHANNEL | OLC2`, vless → null;
- parseImportLink: olcrtc-ссылка не бросает и не маршрутизируется,
  https-подписка по-прежнему распознаётся;
- виджет: список серверов с olcrtc-подпиской показывает пометку
  ограничений у olcrtc-строки и не показывает сырой код.

Регрессии соседних зон: `app_test.dart`, `ui2_test.dart`,
`licenses_test.dart`, `language_test.dart` — все зелёные;
`flutter analyze` по kit.dart/servers.dart/olcrtc_test.dart — No issues.

## 3. Документация

- Новая страница: [`docs/olcrtc.md`](../../sora/docs/olcrtc.md)
  — что это, импорт ссылки/подписки существующими потоками, таблица
  провайдеров (комната/гость/примечания) и транспортов (совместимость),
  честные ограничения v1 (TCP/IPv4-only, нужен бинарь из пакета,
  Windows-оговорка из остаточных рисков TRANSPORT.md, только клиент,
  ключ в файле 0600), ссылки на первоисточники сообщества
  (openlibrecommunity/olcrtc, его docs/uri.md и docs/sub.md) и на нашу
  SPEC-выжимку. Стиль раздела — русский, как соседние страницы.
- Индекс `docs/README.md` — добавлена строка в «Пользователям».
- `docs/providers.md` — `olcrtc://` и подписки OpenLibre добавлены в
  список понимаемых форматов со ссылкой на новую страницу.

## 4. Notices

- `THIRD-PARTY-NOTICES.md`: строка olcrtc (v0.0.1, WTFPL-2.0, © zarazaex,
  ссылка на исходники) уже стояла — коммит упаковки ed7fed36, сверено.
- UI-место notices: About → «Лицензии компонентов» читает
  `app/assets/licenses.json` через LicenseRegistry (main.dart). Там
  olcrtc **отсутствовал** (zapret и движки есть) — добавлен ключ `olcrtc`
  с полным дословным текстом LICENSE из upstream (WTFPL-2.0,
  Copyright (C) 2026 zarazaex) после `zapret`. `licenses_test.dart`
  зелёный.

## Проверки (итог)

| Проверка | Результат |
| --- | --- |
| `flutter gen-l10n` | чисто, только добавления |
| `flutter analyze` (kit, servers, olcrtc_test) | No issues found |
| `flutter test test/olcrtc_test.dart test/language_test.dart` | 38/38 (паритет ARB включён) |
| `flutter test test/app_test.dart test/licenses_test.dart` | 29/29 |
| `flutter test test/ui2_test.dart` | 26/26 |
