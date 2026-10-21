# Apple-клиенты sora — отчёт департамента (2026-10-20)

Новые клиенты sora под iOS и macOS: новое дерево `apple/` в репозитории
sora, ветка `bugfix/audit-2026-10-19`. Работали 6 подотделов +
центральная приёмка координатора. Пуш — за родителем; департамент не пушил.

## Коммиты `[apple]` (все — pathspec/temp-index+CAS, чужие зоны не тронуты)

| Коммит | Содержание |
|---|---|
| `b3816f42` + `467ae597` | Локализация, ассеты, project.yml, BUILD-MAC (repair убрал `__pycache__`) |
| `27c717fa` | SoraCore: парсеры + модели (10 файлов) |
| `ce546020` | iOS-приложение + PacketTunnel (30 файлов) |
| `c8597cd0` | SoraCore: генератор конфигов libbox + хранилище (12 файлов) |
| `88e90b98` | macOS-приложение (34 файла) |
| `b84ae1a8` | Приёмка координатора: фиксы sing-box 1.14 в генераторе, Intents в project.yml, ARCHITECTURE/PARITY |
| `ffc1f5b2` | Фикс синтаксиса ViewModels (пойман parse-sweep'ом приёмки) |

## Что построено

- **`apple/SoraCore/`** — общий SPM-пакет (чистый Swift + Foundation):
  парсеры ссылок всех протоколов контракта (vless/trojan/ss/vmess/hy2/
  tuic/wg/awg; UUID версий 1–8 принимаются по Go-векторам, мусор
  отклоняется), подписки (base64, plain, sing-box JSON, SIP008, Clash
  YAML-подмножество, WG .conf), модель ServerProfile со стабильным id
  (формат Go StableKey), чистый Swift SHA-256 (векторы NIST),
  генератор конфигов libbox (все 8 протоколов, цепочки detour, fakeip
  DNS, kill switch, split tunnel, bypass LAN), валидация зеркально Go
  (mux+vision, XHTTP+vision, AWG-поля, REALITY…), хранилище профилей
  (аддитивные миграции v1→v2), PlatformCapabilities вместо веток по
  версии ОС.
- **`apple/PacketTunnel/`** — NEPacketTunnelProvider; весь libbox за
  швом `LibboxBridge` (сигнатуры помечены `TODO(verify-on-mac)` — список
  из 5 точек собран в BUILD-MAC.md); обмен конфигом — providerConfiguration
  + App Group.
- **`apple/Apps/iOS/`** — SwiftUI: онбординг, серверы, редактор, импорт
  (вставка + QR/AVFoundation с честным состоянием «камера недоступна»),
  QR-шаринг, статистика, настройки; виджет WidgetKit; AppIntents
  Connect/Disconnect/Status; deep links `sora://` и всех схем парсера;
  on-demand правила и устойчивость к смене сети/сну; честные состояния
  state.* вместо сырого системного текста.
- **`apple/Apps/macOS/`** — окно с сайдбаром; меню-бар двумя путями
  (MenuBarExtra 13+ и NSStatusItem 11–12) через единый
  FeatureAvailability; system extension flow; автозапуск двумя путями
  (SMAppService / Login Item helper); виджет; AppIntents; Handoff;
  глобальный хоткей ⌃⌥S (Carbon, без Accessibility-TCC); drag&drop
  подписок; security-scoped bookmarks; два набора entitlements
  (MAS / Developer ID).
- **`apple/Localizations/`** — Localizable.xcstrings: 760 ключей;
  711 ключей основного приложения × 31 локаль — 100% (конвертер из ARB
  реально прогнан, 32 ARB → 31 BCP 47); 49 Apple-only ключей (state.*,
  notify.*, alert.*) с полными EN+RU и честным EN-фолбэком в остальных.
  GLOSSARY.md + `check_glossary.py` — 0 нарушений.
- **`apple/Assets/`** — AppIcon 25 PNG из logo-512, размеры сверены
  скриптом 25/25; AccentColor из палитры Flutter.
- **`apple/docs/`** — ARCHITECTURE.md (758 строк: таргеты, движок,
  адаптивность §5, стандарт мелочей §8, идентификаторы §3.4 — единый
  источник), PARITY.md (матрица паритета + аддендум приёмки),
  BUILD-MAC.md (сборка на Mac: XcodeGen, Libbox.xcframework из
  sing-box-lx v1.14.3-lx.22, подписи, notarization, TestFlight,
  чек-листы приёмки).

## Покрытие систем (ARCHITECTURE.md, каждое исключение обосновано)

| Сегмент | Статус |
|---|---|
| iOS/iPadOS 15–26, macOS 13–26 | Основной таргет, полный TUN (код написан) |
| iOS 13–14 | Условный legacy (старый libbox + NavigationView) — спроектировано, канала стора не подтверждено |
| macOS 11–12 | Legacy-таргет — спроектировано; фолбэки в коде главного таргета сохранены |
| macOS 10.15 | Ограниченный режим (системный прокси без TUN) — спроектировано |
| iOS ≤12, macOS ≤10.14, 32-бит | Документированный отказ с обоснованием (32-бит закрыт самой ОС) |

Пол движка — не «платформа не умеет»: NE доступен с iOS 9/macOS 10.11,
предел задают libbox-сборка sing-box 1.14 (iOS 15+/macOS 13+) и
App Store/Xcode 26. Невозможно на платформе (честно, в PARITY):
zapret в обеих формах, per-app split на iOS, расширения с кодом.

## Машинная проверка здесь (Linux, Swift 6.0.3)

- **`swift test` SoraCore: 88/88 зелёные** на итоговом HEAD (парсеры,
  модели, SHA-256, генератор, валидация, хранилище).
- **`sing-box check`: 12/12 PASS настоящим бинарём sing-box-lx
  1.14.3-lx.22** (скачан по `packaging/engines/engines.lock`, SHA-256
  сверен с локом) — по одному конфигу на каждый из 8 протоколов +
  цепочка, kill switch off, blockOnFailure, split tunnel. Golden'ы:
  `~/workspace/.goldcheck/golden/`, бинарь: `~/workspace/.sbcheck/`.
- **`swiftc -parse`: 74/74 файла** дерева apple/ после фикса приёмки.
- Валидаторы: project.yml (YAML), xcstrings (JSON), все plist/
  entitlements, Contents.json иконок — валидны.

## Что поймала приёмка координатора (не подотделы сами)

1. **Блокирующий дефект генератора**: аутбаунд `{"type":"dns"}` удалён
   в sing-box 1.13 — каждый сгенерированный конфиг отклонялся пиннутым
   движком 1.14.3. Убран; block заменён route-action `reject` (как Go).
2. **Отсутствовал `route.default_domain_resolver`** — ERROR в 1.14.
   Добавлен по точной семантике Go `dns()` (bootstrap: первый IP/local
   сервер, иначе appended `local`; hostname-резолверам — domain_resolver).
   Оба фикса запинены тестами; после них check 12/12.
3. **App Group в трёх написаниях** у трёх подотделов (`group.io.github.
   levvs-one.sora` / `group.one.levvs.sora` / `group.dev.sora.app`) —
   сведено к канону ARCHITECTURE §3.4 везде, grep по дереву — 0 остатков.
4. **Intents не попадали ни в один таргет** project.yml — iOS исключал
   Intents/**, macOS не включал каталог. Исправлено.
5. **Синтаксическая ошибка** в iOS ViewModels (словарный тип без
   двоеточия) — найдена parse-sweep'ом, исправлена (`ffc1f5b2`).
6. Тесты хранилища соседа падали на stale-id фикстурах — исправлено на
   стороне фикстур (refreshID), декодер по мандату не тронут.
7. Токены анимаций приведены к фактическому Flutter `Motion`
   160/180/220 мс (исследовательский подотдел поймал расхождение с
   первоначальным брифом 0.20/0.30).

## Что НЕ проверено и требует Mac владельца (честно)

- Компиляция SwiftUI/NetworkExtension/AppIntents против Apple SDK —
  здесь нет Xcode; первый билд — по BUILD-MAC.md, возможны type-level
  правки (композиция сцен macOS отмечена автором как риск).
- **Libbox.xcframework именно форка sing-box-lx** — главный риск волны:
  в engines.lock Apple-артефактов нет; сборка из исходников форка
  официальным `build_libbox` расписана в BUILD-MAC §2, сигнатуры моста
  сверяются по заголовкам (5 TODO-точек перечислены).
- Подписи, notarization, TestFlight, одобрение system extension,
  рендер виджетов, Handoff между устройствами, реальный туннель.

## Решения/действия владельца

1. Мастер иконки ≥1024 (или SVG): текущие 1024×1024 — Lanczos-апскейл
   из logo-512, на ретина-сторе возможно «мыло».
2. Legacy-таргеты (iOS 13–14 / macOS 11–12 / 10.15-limited): строить ли
   отдельным этапом — в этой волне только спроектированы и обоснованы.
3. Канал macOS: Developer ID (первичен по ARCHITECTURE) vs MAS —
   entitlements готовы под оба.

## Состояние дерева

HEAD ветки на сдаче департамента — `ffc1f5b2`; `git diff HEAD -- apple/`
пуст (ворктри == HEAD по всей зоне). Общий индекс ворктри параллельные
отделы периодически загрязняют staged-чужими — HEAD и ворктри зоны
apple/ это не затрагивало ни разу; перед пушем родителю — стандартная
точечная нейтрализация по своим путям.
