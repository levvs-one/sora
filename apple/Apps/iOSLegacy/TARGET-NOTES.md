# TARGET-NOTES — таргет iOSLegacy (iOS 13–14)

Подотдел iOS 13–14, департамент устаревших систем. Этот файл — точная
спецификация для координатора: как собрать таргет из готовых файлов
зоны, что решить и что честно не покрыто. Коммитов подотдел не делает,
`project.yml` не трогает.

Дизайн: ARCHITECTURE §1.6 (legacy-таргет, старый libbox,
NavigationView-UI), §5.2 (лестница сегмента), §3.4 (идентификаторы),
§8 (стандарт мелочей); BUILD-MAC §6 (матрица); пин — sing-box-lx
**v1.13.13-lx.15** (apple/Legacy/ENGINES.md).

## 1. Файлы зоны (всё новое — только здесь)

```
Apps/iOSLegacy/
  AppDelegate.swift          — @UIApplicationMain, граф объектов, quick actions
  SceneDelegate.swift        — UIWindow + UIHostingController, deeplink-вход, wake на active
  AppState.swift             — владелец моделей (замена @StateObject), тема, connect-поток
  LegacyRouter.swift         — вкладки/шиты/held deeplink (аналог AppRouter основного приложения)
  LegacyDesignTokens.swift   — токены §8 зеркалом + SwiftUI-1 компоненты (см. §6)
  LegacyEngineConfig.swift   — ЕДИНСТВЕННАЯ точка вызова генератора, tier .legacy (см. §4)
  LegacyShortcuts.swift      — ограниченный режим Shortcuts (§5.2): NSUserActivity + quick actions
  Views/LegacyContentView.swift    — TabView-шелл
  Views/LegacyServersView.swift    — серверы: список+поиск+статус+connect (+LegacyServerRow)
  Views/LegacyServerEditView.swift — редактор сервера
  Views/LegacyImportView.swift     — импорт: вставка/буфер/сканер, hand-off подписки-URL
  Views/LegacyQRScannerView.swift  — AVFoundation-сканер с честным qrNoCamera
  Views/LegacyQRShareView.swift    — QR-шаринг (+LegacyQRCodeImageView)
  Views/LegacyStatsView.swift      — статистика провайдера
  Views/LegacySettingsView.swift   — настройки + секция честных состояний сегмента
  Views/LegacyOnboardingView.swift — первый запуск
  Info.plist                 — со сцен- манифестом iOS 13 (отличается от основного!)
  SoraLegacy.entitlements    — NE + тот же App Group, что основной клиент
PacketTunnel/Legacy/
  LibboxBridgeLegacy.swift   — мост lx.15, drop-in замена LibboxBridge.swift
  LegacyBridgeNotes.md       — карта функций 1.14 → lx.15
```

## 2. Идентификаторы (§3.4 + предложение суффикса)

§3.4 фиксирует один bundle id приложения на продукт. Legacy-приложение
не может делить id с основным (две установки, два embedded-расширения
с одним id расширения конфликтуют при установке). Предложение
координатору (одно решение, не развилка в коде):

| Идентификатор | Предложение |
|---|---|
| App iOSLegacy | `io.github.levvs-one.sora.legacy` |
| PacketTunnel legacy | `io.github.levvs-one.sora.legacy.PacketTunnel` (суффикс от legacy-app id — конвенция Apple: id расширения начинается с id приложения) |
| App Group | `group.io.github.levvs-one.sora` — **без суффикса, как §3.4**: профили/настройки общие с основным клиентом, это и есть смысл одного контейнера. Если координатор захочет изоляцию legacy-профилей — меняется одной строкой в entitlements обоих legacy-таргетов + `SoraIdentifiers` НЕ трогается (идентификаторы провайдера живут в TunnelConfigExchange.swift, значение appGroup там общее; изоляция потребует отдельной константы — эскалация, а не тихая правка) |
| Keychain access group | `$(AppIdentifierPrefix)io.github.levvs-one.sora` (§3.4, без изменений) |
| URL-схема | `sora://` (§3.4; коллизия с основным приложением на одном устройстве разрешается iOS произвольно — известный платформенный факт, не баг зоны; на практике legacy ставят на устройства без основного клиента) |

Код зоны bundle id приложения нигде не хардкодит, кроме Info.plist
(предложение выше) и action-типов NSUserActivity в LegacyShortcuts
(`io.github.levvs-one.sora.action.*` — это НЕ bundle id, а типы
активностей; суффикс им не нужен).

## 3. Состав таргетов для project.yml (фрагменты координатору)

### 3.1. Приложение

```yaml
  SoraIOSLegacy:
    type: application
    platform: iOS
    deploymentTarget: "13.0"
    sources:
      - path: Apps/iOSLegacy
      # Общие источники основного приложения (API-совместимы с iOS 13,
      # см. §3.3):
      - path: Apps/iOS/TunnelManager.swift
      - path: Apps/iOS/TunnelState.swift
      - path: Apps/iOS/ViewModels.swift
      - path: Apps/iOS/DeepLinks.swift
      - path: Apps/iOS/Notifications.swift
      - path: Apps/iOS/LinkEncoder.swift
      - path: Localizations/Localizable.xcstrings
      - path: Assets/Media.xcassets
    dependencies:
      - package: SoraCore
      - target: PacketTunnelIOSLegacy
        embed: true
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: io.github.levvs-one.sora.legacy   # §2, решение координатора
        INFOPLIST_FILE: Apps/iOSLegacy/Info.plist
        CODE_SIGN_ENTITLEMENTS: Apps/iOSLegacy/SoraLegacy.entitlements
        TARGETED_DEVICE_FAMILY: "1,2"
```

НЕ включать из Apps/iOS: `SoraApp.swift` (нет @main-App на 13),
`Design.swift` (Canvas в SoraMarkView — iOS 15; палитра и ByteFormat
зеркалятся LegacyDesignTokens), `Design/DesignTokens.swift`
(SoraEmptyStateView — .borderedProminent, iOS 15; значения зеркалятся),
`Views/*` (NavigationStack/.searchable/.task/.swipeActions и т.д. —
у зоны свои Legacy*), `Intents/SoraIntents.swift` (AppIntents — iOS 16;
у зоны LegacyShortcuts), `Widgets/**` (см. §5).

### 3.2. PacketTunnel (ключевое разведение файлов)

```yaml
  PacketTunnelIOSLegacy:
    type: app-extension
    platform: iOS
    deploymentTarget: "13.0"
    sources:
      # Общие файлы провайдера — БЕЗ ИЗМЕНЕНИЙ:
      - path: PacketTunnel/PacketTunnelProvider.swift
      - path: PacketTunnel/TunnelConfigExchange.swift
      # Info.plist общий, НО его CFBundleIdentifier — основной
      # (io.github.levvs-one.sora.PacketTunnel): legacy-таргет
      # переопределяет его своим PRODUCT_BUNDLE_IDENTIFIER через
      # build setting, файл не правится:
      - path: PacketTunnel/Info.plist
      # Мост тира — ВМЕСТО PacketTunnel/LibboxBridge.swift:
      - path: PacketTunnel/Legacy/LibboxBridgeLegacy.swift
    dependencies:
      - package: SoraCore
      # + Libbox.xcframework пина lx.15 (собирается из исходников,
      #   ENGINES.md §2.3) — link+embed, как основному PacketTunnelIOS
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: io.github.levvs-one.sora.legacy.PacketTunnel  # §2
        INFOPLIST_KEY_NSExtension_NSExtensionPointIdentifier: com.apple.networkextension.packet-tunnel
        CODE_SIGN_ENTITLEMENTS: PacketTunnel/PacketTunnel.entitlements  # общий файл подходит как есть
```

`LibboxBridgeLegacy.swift` определяет те же `LibboxBridge` /
`LibboxBridgeError` / `LibboxBridgeImpl`, что `LibboxBridge.swift`;
одновременное включение обоих файлов в один таргет = duplicate
declaration, поэтому exclude-разведение обязательно, а не опция.

### 3.3. Общие источники приложения: оговорки verify-on-mac

- `TunnelManager.swift`, `ViewModels.swift`: `@MainActor` + async/await
  — Swift concurrency бэк-деплоится на iOS 13 при компиляторе ≥5.5
  (проект — Swift 5.9), но финал проверяется только сборкой: точки
  риска — `Task { @MainActor … }` в observer-замыкании TunnelManager
  и вызовы @MainActor-инициализаторов из AppState.
- `Notifications.swift`: async-вариант `requestAuthorization` —
  подтвердить доступность при deployment 13.0; при отсутствии —
  completion-вариант в этом же файле общей правкой (не зоной).
- `TunnelManager.publishSnapshot` уже ограждён `#available(iOS 14.0)`
  под canImport(WidgetKit) — на 13.0 виджета нет, снимок в App Group
  всё равно пишется (его читает только виджет; стоимость — одна
  запись UserDefaults, приемлемо и одинаково с основным клиентом).

## 4. Точка вызова генератора (tier)

- Единственное место зоны, где строится конфиг, —
  `LegacyEngineConfig.buildConfig/buildChainConfig`
  (Apps/iOSLegacy/LegacyEngineConfig.swift), вызов помечен
  `// tier: .legacy (iOS 13–14 pin lx.15)`.
- AppState.connect/switchServer строит конфиг через адаптер как
  префлайт (честный `alert.configBuildFailed` до касания VPN-профиля).
- **Интеграционный шаг координатора** (общие файлы — не зона): когда
  подотдел ядра добавит параметр тира в `LibboxConfigBuilder`
  (source-compatible, default .main), (а) в адаптере передать тир
  одной строкой; (б) внутренние вызовы `LibboxConfigBuilder.build`
  в `TunnelManager.connect/switchServer` (Apps/iOS, общие файлы)
  должны получить тир таргета — чище всего инъекцией строителя в
  TunnelManager с default .main и передачей
  `LegacyEngineConfig.buildConfig` из AppState. До этого шага
  туннель legacy-приложения строится основным тиром — расхождение
  ровно в пяти 1.14-добавках ENGINES.md §4; lx.15 такой конфиг
  отклонит на CheckConfig-префлайте моста (честный отказ, не тихий
  провал), поэтому шаг (б) — условие рабочего legacy-туннеля, а не
  косметика.

## 5. Лестница §5.2 для сегмента — как реализована

| Ступень | iOS 13.0 | iOS 14.0 |
|---|---|---|
| Туннель (PacketTunnel + lx.15) | полный | полный |
| Навигация | полная: NavigationView-адаптер (StackNavigationViewStyle), те же экраны и роутер-состояния | так же |
| Виджеты | **ступень пропущена целиком**: таргета виджета в поставке 13.0 НЕТ (WidgetKit — с iOS 14). В настройках — честное состояние `state.widgetUnavailableIOS13` | вариант для координатора: добавить `SoraWidgetsIOS` из основного приложения отдельным таргетом с deploymentTarget 14.0 и embed в SoraIOSLegacy только для 14-сборки; код виджета (Apps/iOS/Widgets) от 13-API не зависит сверх WidgetKit. Одна сборка на 13+14 с виджетом невозможна без поднятия пола приложения — это и есть цена ступени |
| Shortcuts | ограниченный режим: donated NSUserActivity (Siri Suggestions/Shortcuts после первого действия) + Home-screen quick actions; состояние — `state.shortcutsLimitedMode` в настройках. AppIntents нет; кастомный INIntent требует .intentdefinition + Intents extension — НЕ входит, решение координатора | тот же ограниченный режим (AppIntents — только iOS 16) |
| Статистика | поток StatusMessage lx.15; недоступна → `trafficUnavailable`, не нули | так же |

## 6. Дизайн-токены (§8)

Значения — зеркало Apps/iOS/Design/DesignTokens.swift + Design.swift
(SoraPalette): сетка 4/8 (4,8,12,16,24,32,48), радиусы 8/12/16/20,
motion 0.16/0.18/0.22 easeInOut + spring, семантические цвета по
схеме, hit target 44, row 52. Литералов в экранах зоны нет — всё из
LegacyDesignTokens. Долговременная форма (решение координатора):
выделить из основного DesignTokens iOS-13-чистую часть значений в
общий файл и удалить зеркало, чтобы зеркало не разъехалось.

## 7. Ключи локализации

Файлы Localizations/** — не зона; ключи только списком.

- Использованные зоной ключи — те же, что основной клиент (полный
  список — в отчёте подотдела, фрагмент IOS13.md §5). Из них в
  каталоге Localizable.xcstrings уже есть 55; остальные уже заявлены
  основным приложением и ждут его локализационного прохода — это не
  новый долг legacy-зоны.
- **НОВЫЕ ключи, предложенные зоной (4)** — нужны RU+EN строки по
  глоссарию §8.3, в каталог не вносились:
  1. `state.widgetUnavailableIOS13` — честное состояние виджетов на iOS 13 (настройки).
  2. `state.shortcutsLimitedMode` — честное состояние ограниченного режима Shortcuts (настройки).
  3. `settingsLegacyCapabilitiesTitle` — заголовок секции честных состояний в настройках legacy.
  4. `settingsWidgetsTitle` — название строки «Виджеты» в той же секции (у основного приложения отдельной строки виджетов в настройках нет).
- Строки project.yml: новых не требуется; значения — в фрагментах §3.

## 8. Честно не покрыто / verify-on-mac

1. **TUN fd регистрация** (мост, D6 в LibboxBridgeLegacy): одна строка
   при сборке таргета — провайдеру нужен мост к packetFlow fd;
   общий PacketTunnelProvider мост-агностичен. TODO(verify-on-mac).
2. Все gomobile-спеллинги lx.15 в LibboxBridgeLegacy —
   TODO(verify-on-mac) по заголовкам собранного фреймворка (чек-лист
   по образцу BUILD-MAC §7 — в шапке файла и LegacyBridgeNotes).
3. LegacyPlatformInterface: GetInterfaces (getifaddrs) и
   SystemCertificates (SecTrust PEM) — честные пустые заглушки до
   Mac-верификации (LegacyBridgeNotes §3).
4. Сборка/сабмит: гейт Xcode 26 для таргетов < iOS 15 —
   ARCHITECTURE §1.3, не подтверждён; storный канал legacy не
   обещается.
5. `UILaunchStoryboardName: LaunchScreen` — сториборда в репозитории
   нет и у основного приложения (предсуществующий пробел поставки,
   не legacy-зоны).
6. Серверный редактор: autocorrection/autocapitalization на полях
   адреса/ключа — SwiftUI-модификаторы для этого iOS 15+; на 13
   поля наследуют системное поведение (основной клиент отключает).
   Мелочь §8 зафиксирована здесь, а не замолчана.
7. Кастомный INIntent для Shortcuts (см. §5) — вне поставки зоны.
8. Тесты зоны: юнит-тестов в зоне нет (SoraCore-тесты общие);
   паритет конфигов lx.15 — корпус ENGINES.md §5 (12/12 на бинаре).
