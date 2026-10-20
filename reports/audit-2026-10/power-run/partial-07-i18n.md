# QA power-run · partial-07 · i18n (агент №7)

Ветка `bugfix/audit-2026-10-19`, коммит с фиксами: `2b3b2c5` `[power-run] i18n: plural connConnectionsCount, zh classes complete, locale number formatting, RTL fixes, ru copy` (66 файлов, без пуша).
Зона: `app/lib/l10n/` + весь новый UI-код волн 1–3. Flutter SDK нет — валидация скриптами (JSON, grep-кроссчеки, баланс скобок).

## Сводка

| Метрика | Значение |
|---|---|
| Ключей в abstract (`S`) | 494 (было 493: +`connConnectionsCount`, +`extInstallOne`, −`connConnections`) |
| arb-файлов | 32, все валидный JSON |
| en/ru arb | 494 ключа, паритет 100% |
| Остальные 29 arb | 279 ключей (214 новых — только en+ru, остальные показывают английский fallback) |
| `strings_*.dart` | 30 файлов, все реализуют все 494 члена (zh — через наследование, см. ниже) |
| Плейсхолдеры arb↔Dart↔ru | 0 расхождений (имена, типы, ICU-синтаксис, баланс скобок) |
| Хардкод-строк в новом UI | 0 (4 совпадения — легитимны, см. ниже) |
| Найдено проблем | 13 (10 пофикшено мной, 1 уже пофикшена смежником, 2 осознанно не тронуты) |

## Что проверено и как

1. **Хардкод**: grep по `Text('…'|'…')`, многострочным `Text(`, `labelText/hintText/tooltip/semanticsLabel`, интерполяциям `${s.…}` во всех файлах волн (`ui/qr,dns,benchmark,profiles,chains,sync,modes,connections,servers,settings_screen,subscription,rules_screen,shell,kit,about,speedtest,language,subscription_sheet,toasts,notifications_screen,program_picker`, `ui/extensions/*`, `src/{overrides,chains,profiles,sync,sora,updates}.dart`). Найдено 4 совпадения — все легитимны: `Sora` (бренд, 3×), `soraext` (расширение файла, 1×). Символы `—`, `↑/↓` — не локализуемый текст.
2. **Паритет ключей**: скрипт abstract↔32 arb↔30 dart. en↔abstract — 1:1.
3. **Плейсхолдеры**: сверка `@key.placeholders` (тип/имя) с сигнатурами Dart и ICU-переменных в ru — 0 проблем.
4. **Plurals/RTL/числа/ru** — ниже.

## Таблица ключей (214 новых + 2 добавленных)

`/tmp/key_table.md` — вставлена ниже целиком.

## Проблемы и фиксы

### P0 · `strings_zh.dart` не компилировался (предсуществующий баг волн)
`SZh` (база, `extends S`, конкретный класс) не реализовывал **88** абстрактных членов — включая старые ключи (`sortBy`, `sortPing`, `sortName`, `measureSpeed`). `SZhHans`/`SZhHant` наследуют от `SZh`, так что им тоже не хватало. Конкретный класс без реализации абстрактных членов = compile error всей l10n-библиотеки. Волны дописывали ключи только в `SZhHant` (английским текстом).
**Фикс**: добавил все 88 реализаций в `SZh` (скопированы из `SZhHant`, английский текст — по конвенции «непереведено = английский»). Теперь `SZh`: 494/494, наследники эффективн
о 494/494. Проверено скриптом покрытия с учётом наследования.
*Вердикт фильтра: PASS — критический баг, безальтернативно.*

### P1 · `connConnections` без plural
`'$active ${s.connConnections}'` → «1 соединения», «5 соединения» — ломаная грамматика (2 места: `connections.dart:192,266`).
**Фикс**: новый ключ `connConnectionsCount(int)` с `Intl.pluralLogic` (en: one/other; ru: one/few/other — «соединение/соединения/соединений»); старый геттер удалён из abstract, 30 файлов и arb. Остальные 28 локалей — английский fallback (конвенция).
*Вердикт фильтра: PASS — видимая пользователю грамматическая ошибка.*

### P1 · Ручное форматирование чисел вместо `NumberFormat`
- `speedMbps`: `'${value.toStringAsFixed(1)} Mbps'` — точка вместо запятой для ru/de/fr/… **Фикс**: `intl.NumberFormat('0.0', localeName).format(value)` во всех 30 файлах (ru: «12,3 Мбит/с»).
- `StarRating`: `rating.toStringAsFixed(1)` (визуально + screen-reader). **Фикс**: `NumberFormat('0.0', locale)` по `Localizations.localeOf(context)`.
- `_compact`: самописные `1.2K/3.4M` с точкой. **Фикс**: `NumberFormat.compact(locale: …)` («1,2 тыс.» для ru).
*Вердикт фильтра: PASS — класс дефектов локализации, textbook fix, нулевой риск для en.*

### P2 · `extInstallsCount`: «1 installs» / «установок: 1»
**Фикс**: новый ключ `extInstallOne` («1 install» / «1 установка»), call-site: `installs == 1 ? s.extInstallOne : …`.
*Вердикт фильтра: PASS (спорно, но честно) — edge-case, однако «1 installs» — ломаный английский в showcase-продукте; решение минимально (1 ключ).*

### P2 · RTL
- `dns.dart`: 3× `EdgeInsets.only(left: 24, …)` → `EdgeInsetsDirectional.only(start: 24, …)` (вложенные строки отчёта).
- `connections.dart:269`: шеврон `keyboard_arrow_right_rounded` не зеркалится в RTL → выбор иконки по `Directionality.of(context)` (ar/fa/ur — реальные RTL-локали приложения).
- `store_screen.dart:437` (`right: 8` → `end: 8`): **уже исправлено смежным агентом** в `34d6375` (конвергентный фикс, в мой коммит не вошло).
*Вердикт фильтра: PASS — реальные баги для RTL-пользователей.*

### P3 · ru-копия (только `app_ru.arb`, мелкие диффы)
- `syncLastSync`: «Последний синк» → «Последняя синхронизация» (сленг в UI).
- `syncSecureNote`: «зашифрован end-to-end» → «защищён сквозным шифрованием» (англицизм в русском тексте).
- `syncPairingTitle`: «Спарьтесь с этим устройством» → «Спарить с этим устройством» (консистентность с инфинитивным стилем заголовков: `qrScanTitle`, `syncPair`).
- «kill switch» оставлен по-английски — консистентно со старыми строками (`tourMode`).
*Вердикт фильтра: PASS — видимый текст, крошечные диффы.*

### Чистка мусора
- `extensionsSoon`: протухший ключ (заменён на `extCatalogSoonTitle/Body` в F10) — удалён из 29 arb + doc-комментарий из `strings.dart`. В коде не использовался.
*Вердикт фильтра: PASS — удаление слопа.*

## Что отсеяно фильтром слопа (осознанно НЕ делал)

1. **Машинный перевод 214 ключей × 29 языков** — REJECT. Фейковое качество хуже честного: английский fallback уже работает везде (конвенция кодовой базы). Перевод — задача владельца/профессиональных переводчиков.
2. **Новые ключи ради склеек** `'${s.errGeneric}. ${s.refresh}'`, `'${s.sortBy}: …'`, `'${s.dnsExpected}: ${value}'`, middot-джоины — REJECT. Это фрагменты (label/value), их независимый перевод — стандартная практика; churn 30 файлов ради нулевого видимого эффекта = слоп.
3. **Дедуплика `SZhHans`** (на 100% копирует базу построчно) — REJECT. Установленный паттерн файла (похоже, машинная генерация); рискованно и вне скоупа.
4. `zh_Hans/zh_Hant` arb без своих dart — не баг: `lookupS` отдаёт `SZhHans`/`SZhHant`, наследующих `SZh`.

## [cross-ref] — чужое, требует внимания

1. **WIP коллег ломает компиляцию l10n** (не моё, не трогал): `dns.dart` ссылается на `s.leakTestTitle`, `widgets.dart` — на `s.extCapBackground`/`s.extCapNetwork`/`s.extCapNetworkHosts`; ключей нет ни в abstract, ни в arb. Их файлы: `app/lib/src/ui/{leaktest.dart (untracked),dns.dart}`, `app/lib/src/ui/extensions/widgets.dart`. Коллегам нужно докрутить ключи во все 30 `strings_*.dart` + abstract + en/ru arb (иначе не соберётся).
2. Ветки-конкуренты: несколько `[power-run]`-агентов коммитят в ту же ветку одновременно; один мой RTL-фикс (`store_screen`) уже был закоммичен смежником раньше меня. При ревью учитывать возможные пересечения.
3. Наблюдение: в середине прогона мой незакоммиченный `strings.dart` один раз молча откатился к HEAD (вероятно, конкурентная операция в рабочей копии). Перед коммитом всё перепроверил скриптами.

## Таблица ключей

| key | en | ru | other 29 | status |
|---|---|---|---|---|
| `autoSelectMode` | Auto-select server | Автовыбор сервера | EN fallback |  |
| `autoSelectPing` | Fastest ping | Самый быстрый пинг | EN fallback |  |
| `autoSelectSmart` | Smart choice | Умный выбор | EN fallback |  |
| `autoSelectSpeed` | Fastest speed | Самая высокая скорость | EN fallback |  |
| `benchmarkProgress` | Measuring {done} of {total}… | Замер {done} из {total}… | EN fallback |  |
| `benchmarkStale` | outdated | устарело | EN fallback |  |
| `chainAdd` | New chain | Новая цепочка | EN fallback |  |
| `chainDelete` | Delete chain | Удалить цепочку | EN fallback |  |
| `chainDeleteConfirm` | Delete chain "{name}"? | Удалить цепочку «{name}»? | EN fallback |  |
| `chainDuplicate` | Each server can appear only once | Каждый сервер — только один раз | EN fallback |  |
| `chainEntry` | Entry | Вход | EN fallback |  |
| `chainEstimate` | Estimated latency | Примерная задержка | EN fallback |  |
| `chainExit` | Exit | Выход | EN fallback |  |
| `chainHop` | Hop {n} | Хоп {n} | EN fallback |  |
| `chainHopMissing` | One of the chain servers is no longer availabl | Один из серверов цепочки больше недоступен | EN fallback |  |
| `chainName` | Chain name | Название цепочки | EN fallback |  |
| `chainOrderHint` | Drag to reorder: traffic enters at the top and | Перетащите, чтобы изменить порядок: трафик вхо | EN fallback |  |
| `chainPickServers` | Pick 2–3 servers | Выберите 2–3 сервера | EN fallback |  |
| `chainSave` | Save chain | Сохранить цепочку | EN fallback |  |
| `chainTooFew` | Pick at least 2 servers | Выберите минимум 2 сервера | EN fallback |  |
| `chainTooMany` | A chain holds at most 3 servers | В цепочке максимум 3 сервера | EN fallback |  |
| `chainUnsupported` | The current engine cannot build chains | Текущий движок не умеет строить цепочки | EN fallback |  |
| `chains` | Proxy chains | Цепочки прокси | EN fallback |  |
| `chainsEmpty` | No chains yet. Link 2–3 servers so traffic hop | Цепочек пока нет. Свяжите 2–3 сервера, чтобы т | EN fallback |  |
| `connAddRule` | Add rule | Добавить правило | EN fallback |  |
| `connConnectionsCount` | {count, plural, one{# connection} other{# conn | {count, plural, one{# соединение} few{# соедин | EN fallback |  |
| `connCopyHost` | Copy host | Скопировать хост | EN fallback |  |
| `connGroupByProcess` | By process | По процессам | EN fallback |  |
| `connListView` | As list | Списком | EN fallback |  |
| `coreRestoringLink` | Restoring the link to the core… | Восстанавливаю связь с ядром… | EN fallback |  |
| `coreWatchUnstable` | The link to the core is unstable | Связь с ядром нестабильна | EN fallback |  |
| `crashDismiss` | Not now | Не сейчас | EN fallback |  |
| `crashRestore` | Restore | Восстановить | EN fallback |  |
| `crashRestoreTitle` | The last session was interrupted | Прошлое соединение оборвалось | EN fallback |  |
| `dnsActual` | Observed | Обнаружено | EN fallback |  |
| `dnsCheck` | Check for leaks | Проверить утечки | EN fallback |  |
| `dnsCheckNeedsConnection` | Connect to the VPN first, then check for leaks | Сначала подключитесь к VPN, затем проверьте ут | EN fallback |  |
| `dnsChecking` | Checking... | Проверка... | EN fallback |  |
| `dnsExpected` | Expected | Ожидалось | EN fallback |  |
| `dnsLastCheck` | Last check | Последняя проверка | EN fallback |  |
| `dnsLeakCheckKillSwitchDns` | Kill switch DNS cover | Kill switch закрывает DNS | EN fallback |  |
| `dnsLeakCheckSystemResolvers` | System resolvers | Системные резолверы | EN fallback |  |
| `dnsLeakCheckTunnelDns` | Tunnel DNS resolvers | Резолверы DNS туннеля | EN fallback |  |
| `dnsLeakFixConfigureTunnelDns` | Set the tunnel DNS in the DNS settings above. | Задайте DNS туннеля в настройках выше. | EN fallback |  |
| `dnsLeakFixEnableKillSwitch` | Enable the kill switch so DNS stays inside the | Включите kill switch, чтобы DNS оставался в ту | EN fallback |  |
| `dnsLeakFixReviewSystemResolvers` | Check which resolvers your system would use ou | Проверьте, какие резолверы система использует  | EN fallback |  |
| `dnsLeakFound` | Leak detected | Обнаружена утечка | EN fallback |  |
| `dnsNeverChecked` | Not checked yet | Ещё не проверялось | EN fallback |  |
| `dnsNoLeak` | No leaks found | Утечек не найдено | EN fallback |  |
| `dnsPreset` | Preset | Пресет | EN fallback |  |
| `dnsPresetAdGuard` | AdGuard | AdGuard | EN fallback |  |
| `dnsPresetCloudflare` | Cloudflare | Cloudflare | EN fallback |  |
| `dnsPresetCustom` | Custom | Свой | EN fallback |  |
| `dnsPresetGoogle` | Google | Google | EN fallback |  |
| `dnsPresetQuad9` | Quad9 | Quad9 | EN fallback |  |
| `edit` | Edit | Изменить | EN fallback |  |
| `errBenchmarkUnsupported` | Speed measurement needs a newer core | Для замера скорости нужна новая версия ядра | EN fallback |  |
| `extAbout` | About | Описание | EN fallback |  |
| `extAuthor` | Author | Автор | EN fallback |  |
| `extBadgeNew` | New | Новое | EN fallback |  |
| `extBadgeStaff` | Sora team | Команда Sora | EN fallback |  |
| `extBadgeTop` | Top this week | Топ недели | EN fallback |  |
| `extBadgeVerified` | Verified | Проверено | EN fallback |  |
| `extByAuthor` | by {author} | {author} | EN fallback |  |
| `extCancel` | Cancel | Отмена | EN fallback |  |
| `extCatAll` | All | Все | EN fallback |  |
| `extCatAutomation` | Automation | Автоматизация | EN fallback |  |
| `extCatNetwork` | Network | Сеть | EN fallback |  |
| `extCatStats` | Statistics | Статистика | EN fallback |  |
| `extCatThemes` | Themes | Темы | EN fallback |  |
| `extCatTools` | Tools | Инструменты | EN fallback |  |
| `extCatalog` | Catalog | Каталог | EN fallback |  |
| `extCatalogError` | Could not load the catalog | Не удалось загрузить каталог | EN fallback |  |
| `extCatalogSoonBody` | Until then, you can install extensions from a  | А пока расширения можно устанавливать из файла | EN fallback |  |
| `extCatalogSoonTitle` | The team catalog is coming soon | Каталог команды скоро появится | EN fallback |  |
| `extConfirm` | Confirm | Подтвердить | EN fallback |  |
| `extDangerousAck` | I understand these permissions are powerful | Я понимаю, что эти разрешения серьёзные | EN fallback |  |
| `extDisabled` | Disabled | Отключено | EN fallback |  |
| `extDownload` | Download | Скачать | EN fallback |  |
| `extDownloading` | Downloading… | Скачивание… | EN fallback |  |
| `extEmptyInstalled` | No extensions installed yet. ⏎ Find one in the | Пока нет установленных расширений. ⏎ Найдите в | EN fallback |  |
| `extEmptySearch` | Nothing found | Ничего не найдено | EN fallback |  |
| `extEnabled` | Enabled | Включено | EN fallback |  |
| `extErrGeneric` | Something went wrong. Please try again. | Что-то пошло не так. Попробуйте снова. | EN fallback |  |
| `extErrHash` | The download does not match the catalog. It ma | Скачанный файл не совпадает с каталогом. Возмо | EN fallback |  |
| `extErrHttpsOnly` | Only https:// links are allowed | Разрешены только ссылки https:// | EN fallback |  |
| `extErrManifest` | The extension manifest is invalid. | Манифест расширения некорректен. | EN fallback |  |
| `extErrMinApp` | This extension needs app version {version} or  | Расширению нужна версия приложения {version} и | EN fallback |  |
| `extErrNetwork` | Network error. Check your connection and try a | Ошибка сети. Проверьте соединение и попробуйте | EN fallback |  |
| `extErrSignature` | The signature check failed. The file may be da | Проверка подписи не пройдена. Файл может быть  | EN fallback |  |
| `extInstall` | Install | Установить | EN fallback |  |
| `extInstallFailed` | Install failed | Не удалось установить | EN fallback |  |
| `extInstallFromFile` | Install from file | Установить из файла | EN fallback |  |
| `extInstallFromUrl` | Install from URL | Установить по ссылке | EN fallback |  |
| `extInstallOne` | 1 install | 1 установка | EN fallback |  |
| `extInstallTitle` | Install {name} | Установить «{name}» | EN fallback |  |
| `extInstalled` | Installed | Установленные | EN fallback |  |
| `extInstalling` | Installing… | Установка… | EN fallback |  |
| `extInstalls` | Installs | Установки | EN fallback |  |
| `extInstallsCount` | {count} installs | установок: {count} | EN fallback | → +extInstallOne for n=1 |
| `extNoPermissions` | No special permissions. | Особых разрешений не требуется. | EN fallback |  |
| `extOk` | OK | ОК | EN fallback |  |
| `extOpenPanel` | Open panel | Открыть панель | EN fallback |  |
| `extPanelUnavailable` | The panel is unavailable. The extension may ha | Панель недоступна. Возможно, расширение отключ | EN fallback |  |
| `extPermBackground` | Run background tasks | Выполнять фоновые задачи | EN fallback |  |
| `extPermConnectionsRead` | See the list of active connections | Видеть список активных соединений | EN fallback |  |
| `extPermNetFetch` | Fetch URLs from an allowlist | Запрашивать URL из разрешённого списка | EN fallback |  |
| `extPermNetHooks` | Hook into the network path (DPI bypass modules | Встраиваться в сетевой тракт (модули обхода DP | EN fallback |  |
| `extPermNotifications` | Show notifications | Показывать уведомления | EN fallback |  |
| `extPermRoutingRules` | Add routing rules (affects where traffic goes) | Добавлять правила маршрутизации (влияет на тра | EN fallback |  |
| `extPermServersRead` | See your server list | Видеть список ваших серверов | EN fallback |  |
| `extPermSettingsRead` | Read app settings | Читать настройки приложения | EN fallback |  |
| `extPermSettingsWrite` | Change app settings | Изменять настройки приложения | EN fallback |  |
| `extPermThemeApply` | Apply themes to the app | Применять темы оформления | EN fallback |  |
| `extPermTray` | Add tray menu entries | Добавлять пункты в меню трея | EN fallback |  |
| `extPermUiPanel` | Show panels inside the app | Показывать панели в приложении | EN fallback |  |
| `extPermissionsIntro` | This extension will be able to: | Расширение сможет: | EN fallback |  |
| `extPermissionsTitle` | Permissions | Разрешения | EN fallback |  |
| `extPermissionsWidened` | The update asks for new permissions: | Обновление запрашивает новые разрешения: | EN fallback |  |
| `extRating` | Rating | Оценка | EN fallback |  |
| `extRatingLabel` | Rating {rating} of 5 | Оценка {rating} из 5 | EN fallback |  |
| `extRetry` | Retry | Повторить | EN fallback |  |
| `extRollbackConfirm` | Roll back to version {version}? | Откатить до версии {version}? | EN fallback |  |
| `extRollbackTo` | Roll back to {version} | Откатить до {version} | EN fallback |  |
| `extSaveSettings` | Save settings | Сохранить настройки | EN fallback |  |
| `extSaving` | Saving… | Сохранение… | EN fallback |  |
| `extSearchHint` | Search extensions | Поиск расширений | EN fallback |  |
| `extSettings` | Settings | Настройки | EN fallback |  |
| `extSideloadShort` | Not from catalog | Не из каталога | EN fallback |  |
| `extSideloadWarning` | Not from the team catalog. The author's key is | Не из каталога команды. Ключ автора не провере | EN fallback |  |
| `extSortBy` | Sort by | Сортировка | EN fallback |  |
| `extSortName` | Name | По названию | EN fallback |  |
| `extSortPopular` | Most popular | По популярности | EN fallback |  |
| `extSortRating` | Highest rated | По рейтингу | EN fallback |  |
| `extUninstall` | Uninstall | Удалить | EN fallback |  |
| `extUninstallConfirm` | Remove “{name}” and its settings? | Удалить «{name}» и его настройки? | EN fallback |  |
| `extUpdate` | Update | Обновить | EN fallback |  |
| `extUpdateAvailable` | Update available | Доступно обновление | EN fallback |  |
| `extUpdateTitle` | Update {name} | Обновить «{name}» | EN fallback |  |
| `extUpdateTo` | Update to {version} | Обновить до {version} | EN fallback |  |
| `extUrlHint` | https://…/extension.soraext | https://…/extension.soraext | EN fallback |  |
| `extVerifying` | Verifying… | Проверка… | EN fallback |  |
| `extVersion` | Version | Версия | EN fallback |  |
| `extVersionLabel` | Version {version} | Версия {version} | EN fallback |  |
| `latencyMs` | {value} ms | {value} мс | EN fallback |  |
| `measureSpeed` | Measure speed | Замерить скорость | EN fallback |  |
| `networkNow` | Now: {info} | Сейчас: {info} | EN fallback |  |
| `networkUnknown` | Network info unavailable | Нет данных о сети | EN fallback |  |
| `overrideClear` | Clear edits | Сбросить правки | EN fallback |  |
| `overrideCustomRules` | Custom rules | Свои правила | EN fallback |  |
| `overrideEdit` | Edit servers | Редактировать серверы | EN fallback |  |
| `overrideEmpty` | No edits yet | Пока нет правок | EN fallback |  |
| `overrideHide` | Hide | Скрыть | EN fallback |  |
| `overrideTitle` | My edits | Мои правки | EN fallback |  |
| `overrideUnhide` | Show | Показать | EN fallback |  |
| `profileActive` | Active | Активен | EN fallback |  |
| `profileAdd` | Add profile | Добавить профиль | EN fallback |  |
| `profileApplied` | Profile "{name}" applied | Профиль «{name}» применён | EN fallback |  |
| `profileApply` | Apply | Применить | EN fallback |  |
| `profileApplyAsk` | Apply profile "{name}"? | Применить профиль «{name}»? | EN fallback |  |
| `profileAsns` | AS numbers | Номера AS | EN fallback |  |
| `profileAutoApply` | Apply automatically | Применять автоматически | EN fallback |  |
| `profileAutoApplyHint` | Ask before applying when off | Если выключено — спрашивать перед применением | EN fallback |  |
| `profileDelete` | Delete profile | Удалить профиль | EN fallback |  |
| `profileDeleteConfirm` | Delete profile "{name}"? | Удалить профиль «{name}»? | EN fallback |  |
| `profileGateways` | Gateways | Шлюзы | EN fallback |  |
| `profileName` | Profile name | Название профиля | EN fallback |  |
| `profileNoTriggers` | Add at least one trigger: SSID, gateway or ASN | Добавьте хотя бы один триггер: SSID, шлюз или  | EN fallback |  |
| `profileSnapshot` | Remember current settings | Запомнить текущие настройки | EN fallback |  |
| `profileSnapshotDone` | Current settings saved into the profile | Текущие настройки сохранены в профиль | EN fallback |  |
| `profileSsids` | Wi-Fi networks (SSID) | Wi-Fi-сети (SSID) | EN fallback |  |
| `profileSsidsHint` | Home, Office — comma separated | Дом, Офис — через запятую | EN fallback |  |
| `profileUndo` | Undo | Отменить | EN fallback |  |
| `profiles` | Network profiles | Сетевые профили | EN fallback |  |
| `profilesEmpty` | No profiles yet. Create one to apply settings  | Профилей пока нет. Создайте профиль, чтобы нас | EN fallback |  |
| `qrCopyLink` | Copy link | Скопировать ссылку | EN fallback |  |
| `qrFromClipboard` | Paste from clipboard | Вставить из буфера обмена | EN fallback |  |
| `qrHideLink` | Hide link | Скрыть ссылку | EN fallback |  |
| `qrInvalid` | This QR code does not contain a valid link. | В этом QR-коде нет корректной ссылки. | EN fallback |  |
| `qrNoCamera` | Camera is unavailable. Paste the link from the | Камера недоступна. Вставьте ссылку из буфера о | EN fallback |  |
| `qrScan` | Scan QR | Сканировать QR | EN fallback |  |
| `qrScanHint` | Point the camera at a QR code | Наведите камеру на QR-код | EN fallback |  |
| `qrScanTitle` | Scan QR code | Сканировать QR-код | EN fallback |  |
| `qrShareTitle` | Share via QR | Поделиться QR-кодом | EN fallback |  |
| `qrShowLink` | Show link | Показать ссылку | EN fallback |  |
| `qrTorch` | Flashlight | Фонарик | EN fallback |  |
| `qrWarning` | This QR code contains connection details. Do n | QR-код содержит данные для подключения. Не пок | EN fallback |  |
| `remove` | Remove | Убрать | EN fallback |  |
| `restoreOnCrash` | Restore session after a crash | Восстанавливать сессию после сбоя | EN fallback |  |
| `sortBy` | Sort by | Сортировать | EN fallback |  |
| `sortName` | Name | Имя | EN fallback |  |
| `sortPing` | Ping | Пинг | EN fallback |  |
| `sortSpeed` | Speed | Скорость | EN fallback |  |
| `speedMbps` | {value} Mbps | {value} Мбит/с | EN fallback |  |
| `sync` | Device sync | Синхронизация устройств | EN fallback |  |
| `syncDevices` | My devices | Мои устройства | EN fallback |  |
| `syncEmpty` | No paired devices. Pair another device to keep | Нет спаренных устройств. Спарьте другое устрой | EN fallback |  |
| `syncLastSync` | Last sync: {time} | Последняя синхронизация: {time} | EN fallback |  |
| `syncNever` | Never | Никогда | EN fallback |  |
| `syncNoLan` | Devices must be on the same local network | Устройства должны быть в одной локальной сети | EN fallback |  |
| `syncPair` | Pair a device | Спарить устройство | EN fallback |  |
| `syncPaired` | Device paired | Устройство спарено | EN fallback |  |
| `syncPairingTitle` | Pair with this device | Спарить с этим устройством | EN fallback |  |
| `syncRevoke` | Revoke | Отозвать | EN fallback |  |
| `syncRevokeConfirm` | Revoke "{name}"? | Отозвать «{name}»? | EN fallback |  |
| `syncScanCode` | Scan a code | Сканировать код | EN fallback |  |
| `syncSecureNote` | End-to-end encrypted channel. No accounts, no  | Канал защищён сквозным шифрованием. Никаких ак | EN fallback |  |
| `syncShowCode` | Show my code | Показать мой код | EN fallback |  |
| `syncWaiting` | Waiting for the other device… | Ожидание другого устройства… | EN fallback |  |
| `syncWhat` | What syncs | Что синхронизируется | EN fallback |  |
| `syncWhatBody` | Subscriptions, rules, settings and network pro | Подписки, правила, настройки и сетевые профили | EN fallback |  |
| `updateStageVerify` | Verifying | Проверка | EN fallback |  |
| `watchReconnect` | Reconnect | Переподключить | EN fallback |  |
| `zapretWithVpn` | DPI bypass for direct traffic | DPI-обход для прямого трафика | EN fallback |  |
| `zapretWithVpnHint` | Runs zapret next to the VPN tunnel: tunneled t | Запускает zapret рядом с VPN-туннелем: туннели | EN fallback |  |

_214 wave keys + 2 added this run (`connConnectionsCount`, `extInstallOne`). Abstract: 494 members; all 30 locale files complete._

