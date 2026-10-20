# Аудит: Dart UI — состояние, пользовательские сценарии, платформы

Репозиторий: `~/workspace/bug-hunt/sora` (Sora — VPN-клиент: Flutter UI + Go-ядро; фактически только Windows и Linux, каталога `android/` нет).
Зона аудита: `app/lib/` (все 72 .dart-файла), `app/test/`, `app/integration_test/`, `app/windows/`, `app/linux/`, `pubspec.yaml` / `pubspec.lock`.

## Методология

- Прочитаны целиком: `src/sora.dart` (состояние подключения, 1193 строки), `main.dart`, `src/settings.dart`, `src/core/link.dart`, `src/core/pipe.dart`, `src/updates.dart`, `src/browser_diagnostics.dart`, `src/desktop/desktop.dart`, `src/desktop/system_proxy.dart`, `src/desktop/links.dart`, `src/desktop/programs.dart`, экраны `home/shell/servers/logs/connections/toasts/speedtest/modes/subscription/subscription_sheet/settings_screen/about/rules_screen/program_picker/notifications_screen`, `src/ui/kit.dart` (частично: `push`, `confirm`, `describe`, `Pressable`), `src/groups.dart`, `src/rules.dart`, `src/notifications.dart`, `src/speedtest_services.dart`, `src/ui/tour.dart`.
- Grep по `app/lib`: `setState`, `mounted`, `dispose`, `StreamSubscription`, `Timer`, `Future`/`async`/`await`/`.then(`/`catchError`, `!`, `late `, `MethodChannel|EventChannel`, `SharedPreferences|secure_storage`, `print|debugPrint`, `TODO|FIXME|XXX|HACK` (последний — пусто).
- Проверено: нативный код `app/linux/runner/my_application.cc`, `app/windows/runner/main.cpp`, `utils.cpp`; версии зависимостей из `pubspec.lock`; покрытие `app/test` (4829 строк).
- Dart/Flutter SDK в окружении отсутствует — `flutter analyze` и прогон тестов невозможны; все находки верифицированы чтением окружающего кода.

## Что проверено и НЕ является багом (чтобы не дублировать)

- `setState` после `dispose`: почти везде есть проверки `mounted` / revision-токены (`logs.dart`, `speedtest.dart`, `toasts.dart`, `program_picker.dart`, `connections.dart`). Утечек `StreamSubscription`/`Timer` в виджетах не найдено — всё отменяется в `dispose`.
- Race connect/disconnect при быстрых тапах: `connect()` синхронно выставляет `_connectionWork` и `Phase.connecting` до первого `await`, повторный вызов отсекается флагом `busy`; `toggle()` во время connecting корректно уходит в `disconnect()` с ожиданием `_connectionWork.future`. Двойной запуск ядра не воспроизводится. Покрыто `test/connection_race_test.dart` (20 тестов).
- Секреты: `SharedPreferences` хранит только нечувствительные настройки; bearer-ссылки подписок намеренно не удерживаются в состоянии (`openSubscriptionPage` — "Fetches the bearer link only for this action"); подписки/серверы хранит ядро "encrypted" (комментарий в `settings.dart`); `debugPrint` только для ошибок очистки WebView; HAR-экспорт затирает `authorization`/`cookie`/`set-cookie` и значения query-параметров (`browser_diagnostics.dart`).
- MethodChannel/EventChannel в Dart-коде отсутствуют (вся нативщина — через плагины и FFI), валидировать нечего.
- Android: платформа отсутствует в репозитории (нет `android/`), вопросы фонового сервиса/ battery optimization неприменимы.
- `win32`/`dart:ffi` импорты в `pipe.dart`, `desktop.dart`, `system_proxy.dart`: `DynamicLibrary.open` вызывается лениво внутри функций/статиков, используемых только на Windows; на Linux код не исполняется.

## Находки

### 1. [High] Импорт-ссылки (`sora://add/...`) теряются, если приложение уже запущено (Linux)
- **Файл:** `app/linux/runner/my_application.cc:93-163`
- `my_application_class_init` переопределяет `activate`, `local_command_line`, `startup`, `shutdown`, `dispose`, а флаги `G_APPLICATION_HANDLES_COMMAND_LINE | G_APPLICATION_HANDLES_OPEN` выставлены. Комментарий обещает: "The command line goes on to the first instance, where it carries a link opened while Sora runs".
- Но обработчики сигналов `command-line` и `open` у primary-инстанса **не реализованы** — дефолтный хендлер лишь активирует окно. Второй инстанс (`local_command_line` возвращает FALSE) корректно форвардит аргументы первому, но первый их никуда не передаёт в Dart: `dart_entrypoint_arguments` заполняются только при старте, `app_links.stringLinkStream` в `desktop.dart` без раннер-хука новых URI не получит.
- На Windows тот же сценарий явно обработан (`SendAppLinkToInstance()` в `windows/runner/main.cpp:25`).
- **Сценарий:** Sora запущена (в трее) → пользователь кликает `sora://add/https://...` в браузере/мессенджере → окно выходит на передний план, но диалог импорта не появляется; ссылка потеряна безвозвратно.
- **Фикс:** реализовать `command_line` (и/или `open`) vfunc в `my_application.cc`, извлекать URI и пробрасывать в Dart (например, через `fl_method_channel`/`app_links` C API, как это делает Windows-раннер).

### 2. [Medium] Опрос `getStats` каждую секунду без единого потребителя
- **Файл:** `app/lib/src/sora.dart:249-280, 341`
- `run()` ставит `Timer.periodic(1s)` → `readStats()` → gRPC `getStats` через pipe/unix-socket. Поля `stats`, `speedUp`, `speedDown` нигде не читаются (grep по `src/` — только запись в `sora.dart`).
- Итог: вечный бесполезный IPC-трафик и пробуждения каждую секунду (батарея/CPU), а при сбоях — `reportFailure(error, source: 'stats')`, т.е. пользовательские error-тосты ради данных, которые никто не показывает.
- **Сценарий:** приложение просто открыто и подключено — каждую секунду RPC в ядро.
- **Фикс:** удалить опрос (или отложить до появления UI-потребителя); как минимум не вызывать `reportFailure` для неиспользуемых данных.

### 3. [Medium] Экран логов: O(n) на каждое событие при буфере до 200 000 записей — jank на медленном ПК
- **Файл:** `app/lib/src/ui/logs.dart:177-200` (`_arrive`)
- На каждое событие: `_entries.indexWhere(...)` — линейный поиск по всему списку, затем `_entries.insert(0, entry)` — сдвиг до 200k элементов (`_keep = 200000`). При «разговорчивом» ядре (десятки событий/сек) это миллионы операций в UI-изоляте на событие.
- **Сценарий:** медленный ПК, включён debug-уровень логов, активный трафик → просадки UI при открытом экране логов.
- **Фикс:** держать `Set<Int64>` известных `sequence` (или `Map`) для дедупликации за O(1); вставку новых — через структуру без сдвига (например, хранить в обратном порядке и `add` в конец, либо `List` чанками).

### 4. [Medium] Обновление отменяется молча, если закрыть экран «О приложении» во время загрузки
- **Файлы:** `app/lib/src/ui/about.dart:158`, `app/lib/src/updates.dart:369`
- `confirmDrop: () => !mounted ? Future.value(false) : confirm(...)` — если пользователь ушёл с экрана About во время скачивания (таймаут до 30 минут на файл), `install()` после завершения загрузки вызывает `confirmDrop()`, получает `false` и делает `return` без установки флага `error` и без уведомления.
- **Сценарий:** нажали «Установить обновление», ушли в другие разделы, вернулись — прогресс сброшен, никакой ошибки/объяснения; скачанные сотни мегабайт удалены в `finally`.
- **Фикс:** либо запретить уход с экрана во время `updates.busy` (блокирующий диалог), либо при отмене по `!mounted` выставлять `error`/уведомление вместо тихого `return`; не захватывать `State.mounted` долгоживущим колбэком.

### 5. [Medium] `probe()`: `notifyListeners()` на каждый сервер — сотни перестроений UI и трея
- **Файл:** `app/lib/src/sora.dart:942-982`
- В цикле `await for (final r in call)`: `latency[...] = ...; notifyListeners();` на **каждый** результат. Для подписки на сотни серверов — сотни полных перестроений (`SoraScope` слушают все экраны) плюс `_updateTray()` → `setTooltip` в трее на каждый чих (`desktop.dart`).
- **Сценарий:** большая подписка (500+ серверов) + кнопка «проверить пинг» → видимые подтормаживания, особенно на медленном ПК.
- **Фикс:** батчить — накапливать результаты и вызывать `notifyListeners()` раз в ~200–500 мс или в конце.

### 6. [Low] Гонка сброса индикатора «скопировано» (proxy address)
- **Файл:** `app/lib/src/ui/settings_screen.dart:160-167`
- `onTap`: `setState(_copied = true)` → `await 1500ms` → `if (mounted) setState(_copied = false)`. Два быстрых тапа: первый таймер гасит индикатор раньше, чем истекут 1.5 с второго тапа.
- **Фикс:** токен/поколение (`final stamp = ++_copiedStamp; ... if (stamp == _copiedStamp)`).

### 7. [Low] Тихий no-op: действие «повторить подключение» из уведомления при недоступном ядре
- **Файлы:** `app/lib/src/sora.dart:611-614`, `app/lib/src/ui/notifications_screen.dart` (`runNotificationAction`, case 'connect')
- `connect()` при `_link == null` делает просто `return` без установки `failure` и без уведомления. Тап «повторить» из уведомления, когда ядро ещё не поднялось, — ноль обратной связи.
- **Фикс:** в `connect()` при `link == null` выставлять `failure = CoreFailure.unavailable` + `notifyListeners()` (или тост).

### 8. [Low] Тапы по орбу во время `Phase.disconnecting` проглатываются
- **Файл:** `app/lib/src/sora.dart` (`toggle()`)
- В `toggle()` нет ветки для `Phase.disconnecting` — тап во время отключения игнорируется; пользователь жмёт, ничего не происходит, нужно жать повторно после перехода в `off`.
- **Фикс:** трактовать как отмену/игнор осознанно, либо сразу ставить в очередь `connect()` после завершения disconnect.

### 9. [Low] Отравление цепочки `_historyWork` при ошибке записи истории уведомлений
- **Файл:** `app/lib/src/sora.dart:163`
- `_historyWork = _historyWork.then((_) => settings.saveNotificationHistory(snapshot))` — если `saveNotificationHistory` хоть раз бросит исключение, цепочка навсегда останется в состоянии ошибки, все последующие сохранения будут наследовать её, а futures нигде не наблюдаются (повторные unhandled errors).
- **Фикс:** `...then(...).catchError((_) {})` или try/catch внутри.

### 10. [Low] `PipeConnector.done` — force-unwrap `_pipe!`
- **Файл:** `app/lib/src/core/pipe.dart:37`
- `Future<void> get done => _pipe!.closed;` упадёт с `StateError`, если gRPC прочитает `done` до завершения `connect()`. Путь вызова в grpc 5.1.0 не верифицирован (нет pub-кэша), риск латентный.
- **Фикс:** `_pipe?.closed ?? Future.value()`.

### 11. [Low] Необработанные ошибки системных уведомлений (`unawaited(_tell(...))`)
- **Файл:** `app/lib/src/desktop/desktop.dart:462, 475` (и `:129`)
- `_tell` → `_notifications.show(...)` без try/catch; при ошибке D-Bus/плагина — unhandled async error (в debug шум, в release — запись в зону без диагностики).
- **Фикс:** обернуть `show` в try/catch внутри `_tell`.

### 12. [Low] `restartAfterUpdate` захардкожен на `/usr/bin/sora`
- **Файл:** `app/lib/src/desktop/desktop.dart` (`restartAfterUpdate`)
- После обновления всегда запускается `/usr/bin/sora`, независимо от того, откуда запущен текущий процесс (`Platform.resolvedExecutable`). Для неупакованных установок рестарт запустит не тот бинарь или упадёт.
- **Фикс:** использовать `Platform.resolvedExecutable`.

### 13. [Low] Windows: второй инстанс молча выходит, если окно первого ещё не создано
- **Файл:** `app/windows/runner/main.cpp:31-38`
- При существующем мьютексе код ищет окно `FindWindowW`; если первый инстанс ещё стартует (окна нет, в т.ч. `--hidden` до создания), второй просто завершается — переданная ему ссылка (уже форварднутая через `SendAppLinkToInstance` — ок) или намерение показать окно теряется.
- **Фикс:** при отсутствии окна — ждать/ретраить `FindWindowW` несколько секунд.

## Зависимости (pubspec)

Все ключевые пакеты актуальны на момент lock-файла: `grpc 5.1.0`, `http2 2.3.1`, `http 1.6.0`, `protobuf 6.1.0`, `crypto 3.0.7`, `win32 6.4.0`, `ffi 2.2.0`, `shared_preferences 2.5.6`, `url_launcher 6.3.3`, `flutter_local_notifications 22.3.1`, `tray_manager 0.7.0`, `window_manager 0.5.2`, `dbus 0.7.15`, `intl 0.20.3`. Пингов древних версий с известными CVE нет (зафиксированы точные версии `crypto 3.0.7`, `http 1.6.0`, `flutter_markdown_plus 1.0.12`, `showcaseview 5.1.0`, `toastification 3.2.0`, `webview_all 1.4.4` через path-override на `third_party/`). Рекомендация: периодически прогонять `flutter pub outdated` + OSV-сканер; `third_party/webview_all_*` — вендоренные форки, их CVE-статус отдельно не отслеживается pub'ом.

## Покрытие тестами

- Сильное: `test/connection_race_test.dart` (20 тестов — гонки connect/disconnect/select/failover на моке gRPC-ядра), `test/app_test.dart` (19), `test/updates_test.dart` (9), `test/browser_diagnostics_test.dart`, `test/desktop_shell_test.dart`, `test/speedtest_test.dart`.
- Слабое: виджет-тесты UI почти отсутствуют (`ui2_test.dart` — 1 тест); перф-сценарии (логи, probe на сотнях серверов), опрос статистики, Linux deep-link при запущенном приложении — не покрыты.
- `integration_test/` — живые тесты браузера/туннеля (требуют окружения).

## ИТОГО: 13 находок (Critical: 0, High: 1, Medium: 4, Low: 8)
