# UI-зона расширений sora — итог (40-агентная волна, зона UI)

Дата: 2026-10-20. Репозиторий `~/workspace/bug-hunt/sora`, ветка `bugfix/audit-2026-10-19`.

## 0. Статус зоны и жёсткие ограничения

- **Субагентов не было.** Сессия — depth 2/2, `can_spawn=no`: распределить 7 тем по 7 агентам
  технически невозможно. Все 7 тем отработаны лидером зоны лично, последовательно.
- **Dart/Flutter SDK в окружении НЕТ.** Компиляция, `flutter analyze`, виджет-тесты —
  невозможны. Весь код прошёл тройную вычитку вручную (читал каждый изменённый файл
  целиком минимум трижды, сверял сигнатуры с `kit.dart`, `ext/*.dart`, l10n). Всё, что
  нельзя проверить без SDK, ниже помечено **«нужна проверка на dev-машине»**.
- **Коммитов зоны — один** (`14b71a5`, см. п.1). Остальная работа — в worktree + снапшоты
  в `reports/extensions-40/files/`. Причина — инцидент ветки, ниже.

## 1. Инцидент ветки (важно для координатора)

1. Коммит `2767517` («[ext] runtime…») собрал дерево из пустого индекса: **1265 из 1265+
   файлов выпали из дерева**, в дереве осталось 14 файлов. Каскад потомков наследовал
   поломку.
2. Мой коммит `14b71a5` (`[ext] l10n: deduplicate extCapBackground`) успел до поломки,
   в истории цел: он чинил **тройное объявление `extCapBackground`** во всех 30 локалях
   (коммит `57b74a4` параллельного агента), которое не компилировалось. Значение
   оставлено короткое (`Background tasks` / `Фоновые задачи`) — так задумал автор
   ключа; `widgets.dart:capabilityLines` с ним читается нормально.
3. Починка координатора (reset на `1483f57`) не до конца помогла: в какой-то момент
   HEAD снова имел 1 файл в дереве; дважды приходил СТОП на git-записи. Итоговое
   решение: **после `14b71a5` больше не коммитить**, всю работу держать в worktree.
4. Во время починки `git clean` снёс мои **untracked** файлы
   (`ext/conflicts.dart`, `ui/extensions/conflicts_sheet.dart`). Восстановлены из
   снапшотов (`reports/extensions-40/files/`). Урок: в этом shared-worktree untracked =
   небезопасно; снапшоты — вне репозитория.
5. Для будущих коммитов (когда координатор даст добро) готов рецепт из AGENTS.md:
   уникальный `GIT_INDEX_FILE=/tmp/idx_extui_<pid>_<n>`, отфильтрованный патч
   (только свои ханки), `git write-tree` → `git commit-tree` → CAS через
   `git update-ref <branch> $C $H`. Проверено на `14b71a5` — чужие staged/unstaged
   изменения не задеты.

## 2. Внедрено (worktree, тройная вычитка, компиляция — на dev-машине)

### T1. Менеджер расширений — `ui/extensions/store_screen.dart`, `widgets.dart`
- Поиск по установленным (`extSearchInstalled`), пустые состояния разделены:
  «нет расширений» vs «ничего не найдено».
- Шапка «N обновлений доступно» + кнопка **«Обновить все»** (`extUpdateAll`):
  последовательная установка, каждый widening-апдейт по-прежнему спрашивает
  пермишены отдельно; в конце снэкбар считает **только реальные успехи**
  (`extUpdatedCount`), провалы уже показали свои диалоги — тишины нет.
- Вкл/выкл одним тапом как был (Switch), плюс **Semantics-label с именем
  расширения** (`extToggleEnabled`) — скринридер называет, что тогглит.
- Бейдж «есть настройки» (`extSettings` + иконка) на карточках со `settingsSchema`:
  честный сигнал вместо впихивания формы в карточку (см. «Отсеяно»).
- Состояния карточек: версия, `Disabled`, `Update available`, `Not from catalog` —
  как было, плюс бейдж настроек.

### T2. Permissions-экран — `permissions_sheet.dart`, `widgets.dart`, `detail_screen.dart`
- Re-prompt при widening-апдейте уже сделал коллега (`417e4ed`); я закрыл дыры:
  - три честных состояния промпта: fresh install → «Install» + полный список;
    update с добавленными → «Update» + только дельта; update без добавлений →
    «Update» + полный список с нейтральным интро (раньше removal-only апдейт
    показывал титул «Install» — баг, исправлен);
  - **dropped permissions показываются** отдельным блоком (`extPermissionsRemoved`,
    тихий стиль — «вы теряете доступ», не тревога).
- **Честные уровни риска** вместо бинарного dangerous/not: `PermissionRow(blurb, risk)` —
  normal (check, ink2), sensitive (info, ink), dangerous (warning, `palette.danger` +
  обязательный чекбокс). Тир входит в screen-reader label (`extRiskNormal/
  extRiskSensitive/extRiskDangerous`), т.е. не только цветом/иконкой.
- В промпте апдейта — **changelog новых версий** (`extChangelog`, уже был в l10n)
  поверх списка пермишенов: сначала «почему», потом «что просится».

### T3. Обновления UX — `store_screen.dart`, `permissions_sheet.dart`, `detail_screen.dart`
- Changelog: data-model (Go `core/ext/catalog.go` + Dart `ext/catalog.dart`,
  `ChangelogEntry{version,date,notes}`, валидация) **уже сделал параллельный агент** —
  не дублировал. Я сделал UI-рендер: в re-prompt диалоге (только строки новее
  установленной версии) и в detail (у коллеги уже была секция).
- `_installBytes`/`_installFromCatalog` теперь `Future<bool>` — отмена промпта ≠ успех,
  нужно для честного счётчика «Обновить все».
- **Честная ошибка при неудачном апдейте**: `isUpdate` отслеживается с момента
  `ExtPackage.open`; к тексту ошибки добавляется `extUpdateFailedKept`
  («Предыдущая версия осталась установлена») — правда, т.к. реестр переписывается
  только после полной распаковки.
- Откат в один тап был; оставлен как есть (подтверждение — осознанное действие).

### T4. Панель-хост — `detail_screen.dart`
- Изоляция (CSP `connect-src 'none'`, loopback-сервер, lock навигации) — делает коллега,
  не трогал.
- **Мульти-панели**: в detail — секция «Panels» (`extCapPanel` переиспользован) со
  строкой на каждую панель (`LinkTile` → `ExtensionPanelScreen(panelId: …)`).
  Одиночная кнопка «Open panel», молча открывавшая первую панель, удалена.
  Заголовок = титул панели, закрытие = back (есть в `Screen`).
- Спека: таб-бар внутри хоста с несколькими живыми WebView — отложен (см. «Отсеяно»).

### T5. Конфликты расширений — НОВОЕ
- `app/lib/src/ext/conflicts.dart` (новый, чистый): `ExtConflictKind`
  (routingRules/themeApply/netHooks) ←→ пермишены `routing.rules`/`theme.apply`/
  `net.hooks`; `findConflicts` (enabled + granted, ≥2 претендентов);
  `unresolvedConflicts` (нет сохранённого победителя / победитель пропал,
  выключен или лишился пермишена); стабильный `key` вида `kind:id1,id2`.
- `app/lib/src/ext/store.dart`: `conflicts.json` (атомарная запись через tmp),
  `conflictWinner(s)`, `setConflictWinner` (бросает `ExtStoreError`, стор откатывает
  in-memory), `_loadConflicts` через shared future (без гонки).
- `app/lib/src/ui/extensions/conflicts_sheet.dart` (новый): шит разрешения —
  по каждому конфликту радиоряд претендентов (имя, версия, автор), дисклеймер
  `extConflictNote`, кнопка активна только когда всё решено; ошибка сохранения —
  текстом, шит не закрывается молча.
- Баннер `_ConflictBanner` над списком установленных (`extConflictsCount`,
  `extConflictsResolve`): слушает стор сам, исчезает когда всё решено.
- **Честное ограничение (в отчёт, не в UI-ложь)**: UI фиксирует намерение
  пользователя; *применение* победителя движком (routing/theme/hooks) — handoff
  Go-core зоне, трек в п.6.

### T6. Производительность при 100+ — `store_screen.dart`
- `_filtered()` мемоизирован (ключ: revision|query|category|capability|sort);
  **исправлен in-place sort списка каталога** (раньше `list.sort` мутировал
  `_catalog.entries` когда фильтры пусты — теперь всегда копия).
- Списки и так ленивые (`ListView.separated` строит только видимое);
  добавлен `addAutomaticKeepAlives: false` у installed-списка.
- Замеры без SDK невозможны — спека в п.4; кодовых регрессий не внесено
  (фильтрация O(n), сортировка только по miss мемоизации).

### T7. Доступность
- `StarRating`: один семантический узел (`excludeSemantics`), иконки декоративные.
- `PermissionRow`: тир риска в label, `excludeSemantics`.
- Интерактивные кастомные контролы (`_ContenderRow`, баннер конфликтов) —
  `Semantics(button, checked, label, onTap)` + `excludeSemantics`: скринридер
  и объявляет, и **активирует** (баг «нет onTap» найден и исправлен при вычитке).
- Ряды чип-фильтров: высота 36→40 (не клиппит при крупном тексте).
- Switch в карточке: именованный label (T1).
- Контраст: только инк-система + семантический `danger`; красного хардкода нет
  (проверено grep по `Colors.red` — чисто).
- Keyboard: все контролы — стандартные фокусируемые (Switch, кнопки, чипы,
  InkWell-чекбокс); отдельных ловушек фокуса не создано.

## 3. Спеки (спроектировано, код — следующим шагом)

- **S5-enforcement**: Go-core должен читать `conflicts.json`
  (или получать winners через RPC) и применять: routing — порядок/приоритет правил,
  theme — только победитель, net.hooks — цепочка с приоритетом победителя.
  Формат ключа стабилен (`kind:sorted_ids`), контракт описан в шапке
  `ext/conflicts.dart`.
- **T6-замеры**: на dev-машине — сгенерировать 500 фейковых `CatalogEntry`,
  DevTools timeline: скролл <16мс/кадр, фильтр+сортировка <100мс, первый кадр
  списка <300мс. Мемоизация уже даёт O(1) на повторные билды.
- **T4-tabbar**: табы внутри `ExtensionPanelScreen` (несколько WebView) —
  требует решения о lifecycle (держать живыми = память; пересоздавать = потеря
  состояния панели) и проверки на движке без SDK — рискованно.

## 4. Отсеяно и почему

- **Настройки из settingsSchema прямо в карточке** (T1, из видения): полная форма
  в карточке = теснота + сложное состояние + рассинхрон с detail. Оставлен честный
  сигнал (бейдж) + полная форма в detail в один тап. Не слоп, а граница.
- **Changelog в Go-манифесте**: не нужен — changelog едет каталогом, не пакетом;
  дублировать поле в манифест = два источника правды.
- **In-panel переключатель панелей**: файл `panel_screen.dart` активно правит
  коллега (CSP); второй писатель в тот же файл сейчас = конфликт. Покрыто
  списком панелей в detail.
- **Debounce поиска**: фильтрация 100+ записей — доли миллисекунды, ListView
  ленивый; debounce добавил бы лаг без выгоды. Если замеры (п.3) покажут иное —
  вернуть.
- **Автопредложение отката после неудачного апдейта**: не нужно — при неудаче
  старая версия и так активна (см. `extUpdateFailedKept`); откат уже есть в detail.

## 5. l10n — 19 новых ключей

`extToggleEnabled(name)`, `extSearchInstalled`, `extUpdateAll`,
`extUpdatesAvailable(count)`, `extUpdatedCount(count)`, `extRiskNormal`,
`extRiskSensitive`, `extRiskDangerous`, `extPermissionsRemoved`,
`extUpdateFailedKept`, `extConflictsTitle`, `extConflictsIntro`,
`extConflictRoutingRules`, `extConflictTheme`, `extConflictNetHooks`,
`extConflictWinner(name)`, `extConflictsCount(count)`, `extConflictsResolve`,
`extConflictNote`.
Внесены в `app_en.arb`/`app_ru.arb` (с `@placeholders`), `strings.dart`
(abstract) и все 30 `strings_XX.dart` (ru — перевод, остальные — английский
фолбэк по конвенции репо). Скрипт-генератор (идемпотентный):
[add_l10n_keys.py](sandbox://workspace/bug-hunt/reports/extensions-40/add_l10n_keys.py).
Никакого хардкода строк в UI-коде не осталось (проверено grep по всем
затронутым файлам: все пользовательские строки — через `S.of`).

## 6. Нужна проверка на dev-машине (нет SDK здесь)

1. `flutter analyze` + сборка: особенно `permissions_sheet.dart`
   (новые опциональные параметры), `store_screen.dart` (`Future<bool>` цепочка),
   `conflicts_sheet.dart`/`conflicts.dart` (новые файлы), все 33 l10n-файла
   (ручная правка generated-кода).
2. Re-prompt: widening-апдейт с добавленными/убранными пермишенами —
   три состояния титула/интро.
3. «Обновить все»: 2+ апдейта, один с widening (промпт на каждый), один с
   ошибкой сети — счётчик и диалоги.
4. Конфликты: два расширения с `routing.rules` → баннер → шит → персист
   (перезапуск приложения).
5. Скринридер: PermissionRow объявляет тир; радиоряды активируются.
6. 200% масштаб текста: ряды чипов, шит конфликтов, карточки.
7. `ext/conflicts.dart` зависит только от пермишенов (стабильно), но
   `store_screen.dart` уже использует `rolloutEligible`/`installId` коллеги —
   убедиться, что его коммит сел.

## 7. Артефакты

- Снапшоты всех 7 файлов (восстановлено после `git clean`):
  [files/](sandbox://workspace/bug-hunt/reports/extensions-40/files/) —
  `store_screen.dart.snapshot`, `detail_screen.dart.snapshot`,
  `permissions_sheet.dart.snapshot`, `widgets.dart.snapshot`,
  `conflicts_sheet.dart.snapshot`, `conflicts.dart.snapshot`, `store.dart.snapshot`.
- Скрипт l10n: [add_l10n_keys.py](sandbox://workspace/bug-hunt/reports/extensions-40/add_l10n_keys.py).
- Закоммичено: только `14b71a5` `[ext] l10n: deduplicate extCapBackground`.

## 8. Открытые вопросы координатору

1. Дать добро на коммиты зоны (рецепт CAS в п.1) — разбить на
   `[ext] ui: permissions re-prompt + risk tiers`, `[ext] ui: updates UX`,
   `[ext] ui: conflicts`, `[ext] ui: manager + a11y`, `[ext] l10n: 19 keys`.
2. Подтвердить handoff S5-enforcement в Go-core зону.
3. `extOpenPanel` (l10n) остался без использования после замены кнопки списком
   панелей — удалить или оставить коллеге; безвреден.
