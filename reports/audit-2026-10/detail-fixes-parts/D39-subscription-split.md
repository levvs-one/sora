# D39 — подписки/сплит: переименования и скрытия участников групп (sora Dart)

Коммит: `90cc320` `[detail-fix] subscription overrides: grouped-member renames split into visible entries; hidden members excluded from plan groups` (5 файлов). Первый коммит `562452e` был осиротелен чужим repair-коммитом `26774d8` (откат ветки) — историю не переписывал, перезалил идентичное дерево через CAS `update-ref` (деревья совпадают, чужих ханков нет, отфильтрован чужой ханк сиблинга в sora.dart). Пуша нет. Dart SDK нет — тройная вычитка.

## Проверено, чисто — фиксить нечего (без слопа)
Карточки подписок честные: трафик только при `info.hasUsage` (настоящее bool-поле proto, tag 3); `totalBytes == 0` → только used («zero means unlimited»); expiry по presence `hasExpire()`, локальный часовой пояс; `UsageBar` клампится 0..1; `subscriptionWarning` считает той же математикой; Go `parseUsage` выставляет `HasUsage` только при ключах upload/download; ms-метки expire отбрасываются. Atomic update с delta: пустой URL сохраняет хранимый, пустое имя → title провайдера, одна атомарная `persistLocked`-запись; refresh атомарный; оверрайды keyed by StableKey (sha256 protocol/host/port/uuid/user). Split-tunnel доходит до ядра end-to-end (`addRuleSheet` → `settings.rules` → `buildPlan.routes` → `planFromProto` → `routing.Apply`, правила юзера первые, MatchAll последним) → рендер во всех трёх движках; бридж xraytun отвергает несохранимые process-правила ошибкой, а не молчаливым обходом. Дисклеймеры через `S.of`, захардкоженных UI-строк нет.

## Баг 1 — переименование участника группы молча терялось
- **Было:** `_visibleEntries` (servers.dart) и `_trayEntries` (desktop.dart) применяли `override.renames` только к не-групповым записям; переименование сохранялось и светилось в «Мои правки», но в списке/трее не появлялось никогда.
- **Стало:** новый `Entry.applyRenames` (groups.dart) — переименованный участник выходит из группы отдельной записью сразу после неё (id сервера и роли остальных сохраняются); оба call site переведены; тест в `app/test/app_test.dart`.
- **Эффект:** каждая правка переименования видима; группировка не ломается.

## Баг 2 — скрытие участника группы ломало подключение
- **Было:** `Sora.currentPlan` отдавал в `buildPlan` entry из кэша без фильтрации скрытых → группа ссылалась на id, отсутствующий в outbounds → ядро отвергало план (`KeyPlanGroupsInvalid`) → connect падал.
- **Стало:** `currentPlan` и `selected` применяют `withoutHidden(hiddenServerIds)`; полностью скрытая группа → честный fallback на `auto`.
- **Эффект:** скрытие участников групп больше не роняет подключение.

## Мелочь — консистентность имён
`notificationFor` показывал имя провайдера (`nameOf`), а не переименование; стало `displayNameOf`, как в трее и остальных местах.

Follow-up: `flutter test`/`flutter analyze` на dev-машине (тест `applyRenames` проверен только вычиткой); мёртвый l10n-ключ `activeRules` не тронут (сиблинг перегенерирует l10n); интерактивная проверка «скрыть всех участников выбранной группы» (fallback на auto на месте, рантайм-проверки не было).
