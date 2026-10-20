# Веб-исследование #16: Лучшие опенсорсные Flutter-десктоп приложения — архитектура

Дата: 2026-10-19. Тема: какие крупные Flutter-десктоп проекты лучшие по архитектуре и что sora должен перенять.

## 1. Что изучено

### LocalSend (github.com/localsend/localsend, ~50k+ звёзд) — флагман Flutter-десктопа
- State management: **Refena** (свой Redux-подобный: Providers + Actions + RefenaContainer как DI-контейнер), а не Riverpod. Типизированный, реактивный.
  Источник: https://deepwiki.com/localsend/localsend/2.3-state-management
- **Двухфазная инициализация**: `preInit()` — DI-контейнер и дорогие зависимости (device info, persistence services) создаются ДО дерева виджетов, затем `init()`. Жёсткое упорядочивание зависимостей.
- Core вынесен в **Rust**, Flutter — только UI. Лёгкий мост через flutter_rust_bridge-подобный подход.
- Версия Flutter зафиксирована через **fvm** (.fvmrc) — билд детерминирован.
- i18n через JSON-файлы под Weblate (`assets/i18n/strings_<locale>.i18n.json`), поля с `@` не переводятся.

### FlClash (github.com/chen08209/FlClash) — ближайший родственник sora (VPN/прокси клиент)
Самый релевантный проект для заимствования.
- **Слоистая архитектура, явно задокументированная** (файл `.agents/architecture.md` в репо):
  Presentation (Flutter UI, Material 3) → Application (Riverpod + GlobalState + AppController) → Core Engine (Go: `core/hub.go`, ClashMeta) → Platform Services (tray, hotkeys, native plugins) → Data (Drift SQLite + SharedPreferences + WebDAV).
  Источник: https://deepwiki.com/chen08209/FlClash/3-architecture
- **Riverpod, 100+ провайдеров** по доменам, однонаправленный поток данных: widget → `appController.updateStart()` → `globalState.handleStart()` → `coreController.startListener()` (Go core) → providers → UI. State отделён от контроллеров.
  Источник: https://deepwiki.com/chen08209/FlClash/3.2-state-management
- **Персистентность разделена по типу данных**: Drift (типизированный SQLite) для структурированных данных (профили, правила, группы прокси), SharedPreferences — только для простых настроек. WebDAV — облачный синк/бэкап.
  Источник: https://deepwiki.com/chen08209/FlClash/7-data-persistence
- **Нативные мосты по платформе**: FFI (Rust helper, системный прокси) на десктопе; MethodChannel (Kotlin) только на Android для VPN-сервиса/тайлов.
  Источник: https://deepwiki.com/chen08209/FlClash/5-platform-integration
- Билд/пакетирование: один скрипт `setup.dart` + `flutter_distributor` → DEB/RPM/AppImage/DMG/EXE/портативный zip; CI `.github/workflows/build.yaml`.

### Hiddify (github.com/hiddify/hiddify-app) — Flutter + sing-box, 25k+ звёзд
- Flutter (Riverpod) + Go core (libbox). **Native Integration: platform channels (mobile), FFI (desktop)** — ровно то же разделение, что у FlClash.
- Ключевая находка — **абстракция `core_interface`**: `core_interface.dart` (интерфейс) + `core_interface_mobile.dart` + `core_interface_desktop.dart` (реализации). UI и сервисы зависят только от интерфейса.
- **Dual-client архитектура gRPC**: `fgClient` (порт 17078: валидация конфигов, парсинг) + `bgClient` (VPN-сервис, управление соединением, стримы статуса); на десктопе — один процесс, оба клиента указывают на один порт.
  Источник: https://deepwiki.com/hiddify/hiddify-app/4-core-features
- Данные: Drift + SharedPreferences (та же схема, что FlClash).

### Практики из свежих источников (2025–2026)
- **Pigeon для типизированных платформенных каналов**: прогрессия «сырой MethodChannel (1–2 метода) → Pigeon (растущая поверхность, типовые ошибки) → FFI (только hot path)»; канал всегда оборачивать в собственный API с первого дня, чтобы тесты не зависели от реализации.
  Источники: https://verygood.ventures/blog/flutter-pigeon-type-safe-platform-channels/, https://blog.redlinesoft.net/posts/flutter-methodchannel-native-communication/, https://blog.redlinesoft.net/posts/pigeon-type-safe-platform-channels/
- **FFI не нужен для большинства задач**: overhead канала <1 мс; FFI оправдан для существующих C-библиотек, латентности <1 мс в циклах, общего кода с не-Dart рантаймом. На десктопе FFI — первоклассный гражданин.
  Источник: https://www.coderblog.in/posts/flutter-ffi-dart-native-code-2026.html
- **CI для Flutter-десктопа**: widget-тесты на каждый PR; интеграционные тесты десктопа через `xvfb-run -a flutter test integration_test -d linux`; golden-тесты сравнивать в PR, обновлять goldens — отдельным ручным workflow; пинить версию Flutter (fvm); кэш SDK (`cache: true`).
  Источники: https://qaskills.sh/blog/flutter-integration-testing-guide, https://qaskills.sh/blog/flutter-golden-tests-visual-regression-guide, https://blog.redlinesoft.net/posts/flutter-ci-cd-pipelines/
- **Riverpod — дефолт для новых профессиональных проектов в 2026** (compile-time safety, модульность, тестируемость); BLoC — для enterprise со строгими границами; GetX — в упадке (урок про зависимость от одного мейнтейнера).
  Источники: https://foresightmobile.com/blog/best-flutter-state-management, https://www.miquido.com/blog/flutter-app-best-practices/

## 2. Текущее состояние sora (прочитано в ~/workspace/bug-hunt/sora/app, код не менялся)

- **Нет никакого state-management фреймворка**: в pubspec нет riverpod/bloc/provider. Есть god-object `Sora extends ChangeNotifier` (lib/src/sora.dart:73) + ChangeNotifier-синглтоны (updates, profiles, chains, sync, ext/store). 32 файла используют ChangeNotifier/StatefulWidget напрямую. Состояние, бизнес-логика и UI связаны вручную через `notifyListeners()`.
- Нативные мосты: `ffi` уже в зависимостях, gRPC к привилегированному сервису sora-core — правильно. Но нет абстракции «интерфейс платформенного сервиса → реализации» (как core_interface у Hiddify): платформенный код лежит в `lib/src/core/`, `lib/src/desktop/`.
- Персистентность: AES-хранилище подписок + SharedPreferences; структурированные данные (правила, профили, логи, соединения) не в SQL.
- Тесты: `flutter test` + `integration_test/` есть, CI (repository.yml) уже гоняет analyze, test, build linux/windows, интеграционные тесты на windows. Golden-тестов нет.
- Flutter-версия в CI не зафиксирована через fvm (проверить — см. repository.yml, используется subosito/flutter-action; pin отсутствует).

## 3. Что sora должен перенять и почему

### 3.1. Внедрить Riverpod и распилить god-object `Sora` (HIGH)
- **Что**: заменить ручные ChangeNotifier-синглтоны на Riverpod-провайдеры по доменам (как у FlClash: 100+ провайдеров, однонаправленный поток widget → controller → core → state → UI). `Sora extends ChangeNotifier` распилить на домены: connection, profiles, rules, subscriptions, updates, notifications, extensions.
- **Почему**: сейчас каждое `notifyListeners()` на god-object перестраивает всё дерево; состояние нетестируемо изолированно; добавление фич (waves 1–3 уже это показали) плодит связанность. FlClash и Hiddify — оба VPN-клиента на Flutter — сошлись на Riverpod; это консенсус 2025–2026.
- **Эффект: HIGH** — главный архитектурный долг UI-слоя; ускорит все будущие фичи и уберёт класс багов «забыли notifyListeners / лишний rebuild».

### 3.2. Явные слои архитектуры + ARCHITECTURE.md в репо (HIGH)
- **Что**: зафиксировать слои (Presentation → Application/Riverpod → Core Engine (Go) → Platform Services → Data), как у FlClash, и положить `.agents/architecture.md` (или `docs/ARCHITECTURE.md`) с картой слоёв и правилами зависимостей (UI не трогает gRPC напрямую, только через application-слой).
- **Почему**: у sora слои есть де-факто (app → gRPC → sora-core), но не зафиксированы; новый код легко нарушает границы. Документ — дешёвый способ держать «ноль слопа» при росте команды/контрибьюторов.
- **Эффект: HIGH** для поддерживаемости, LOW по трудозатратам.

### 3.3. Абстракция платформенных сервисов: интерфейс + реализации (HIGH)
- **Что**: как `core_interface.dart` у Hiddify — единый Dart-интерфейс для платформенных операций (tray, autostart, system proxy, hotkeys, deeplinks), с реализациями `*_windows.dart` / `*_linux.dart` (и заготовкой под Android/macOS). Весь `lib/src/desktop/` и `lib/src/core/` завести за этот интерфейс.
- **Почему**: сейчас платформенный код размазан; добавление macOS/Android (заявлены в планах) потребует рефакторинга по живому. Интерфейс делает UI тестируемым без платформы (моки) и готовит почву под новые ОС.
- **Эффект: HIGH** — стратегически, разблокирует macOS/Android без переписывания.

### 3.4. Pigeon (или минимум: свой API-обёртка) для платформенных каналов (MEDIUM)
- **Что**: обернуть каждый MethodChannel в собственный типизированный API-класс с первого дня; при росте поверхности (>3–5 методов на канал) — перейти на Pigeon для кодогенерации контрактов.
- **Почему**: у sora есть нативный код (tray, window_manager, deeplinks, уведомления). Типизированные контракты убирают класс ошибок «имя канала/типы не совпали», а обёртка позволяет мокать в widget-тестах без `TestDefaultBinaryMessenger`.
- **Эффект: MEDIUM**.

### 3.5. Drift (SQLite) для структурированных данных (MEDIUM)
- **Что**: профили, правила маршрутизации, история соединений, логи, расширения — в Drift; SharedPreferences оставить только для плоских настроек. Сейчас у sora JSON/AES-файлы.
- **Почему**: FlClash и Hiddify оба используют именно эту схему. Поиск/фильтрация логов (у sora 8 форматов экспорта, категории, поиск) на SQL быстрее и надёжнее, чем in-memory фильтрация JSON; миграции схемы — из коробки.
- **Эффект: MEDIUM** — выигрыш на логах/соединениях/правилах; миграция существующих хранилищ — аккуратная работа.

### 3.6. Двухфазная инициализация с DI-контейнером (MEDIUM)
- **Что**: как `preInit()` у LocalSend — сначала синхронно/упорядоченно инициализируются сервисы (gRPC-клиент, хранилища, device info, i18n), и только потом строится дерево виджетов. С Riverpod это естественно ложится на provider overrides.
- **Почему**: у sora тяжёлый старт (подключение к sora-core, загрузка подписок, проверка обновлений). Явный порядок инициализации убирает race conditions на старте и делает splash/прогресс детерминированным.
- **Эффект: MEDIUM**.

### 3.7. Golden-тесты для ключевых экранов (MEDIUM)
- **Что**: golden-тесты для home/settings/servers/connections; в CI — отдельный job «compare», обновление goldens — только вручную/отдельным workflow (практика qaskills.sh).
- **Почему**: у sora 31 язык и светлая/тёмная темы — регрессии вёрстки при i18n самые частые и самые заметные для «лучшего клиента в мире». Дешёвый способ их ловить.
- **Эффект: MEDIUM**.

### 3.8. Зафиксировать версию Flutter (fvm) (LOW)
- **Что**: как у LocalSend — `.fvmrc` + использование той же версии в CI (subosito/flutter-action поддерживает `flutter-version-file`).
- **Почему**: плавающий stable ломает CI в день релиза Flutter; детерминизм билда — часть «прозрачной подписи/воспроизводимости», которую sora декларирует.
- **Эффект: LOW** по коду, HIGH по спокойствию релизов.

### 3.9. Чего НЕ делать
- Не тащить FFI ради «скорости»: мост sora — gRPC к отдельному привилегированному процессу, это архитектурно правильно (изоляция привилегий). FFI здесь не нужен и был бы шагом назад в безопасности.
- Не брать GetX и не писать свой state management (урок LocalSend с Refena — исключение, подтверждающее правило: у них свой фреймворк, но sora он не нужен).
- Не копировать у FlClash GlobalState-синглтон поверх Riverpod — это их компромисс; чистый Riverpod без синглтонов чище.

## 4. Приоритетный порядок внедрения

1. Riverpod + распил `Sora` (3.1) — фундамент всего остального.
2. ARCHITECTURE.md + слои (3.2) — параллельно с 1, почти бесплатно.
3. Интерфейс платформенных сервисов (3.3) — следом, готовит macOS/Android.
4. Двухфазный init (3.6) — естественно в ходе 1.
5. Pigeon/обёртки каналов (3.4), Drift (3.5) — по мере касания соответствующих модулей.
6. Golden-тесты (3.7), fvm-pin (3.8) — быстрые победы в CI.
