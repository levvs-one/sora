# Веб-исследование #13: Виджеты и контролы в уведомлениях (quick settings tiles, notification controls)

Дата: 2026-10-19. Источники 2025–2026. Статус sora: Android-приложения нет (в `app/` только `windows` и `linux` раннеры), iOS/macOS нет. Трей на десктопе есть.

## Что нашёл

### 1. Android: Quick Settings Tile — must-have у всех VPN-клиентов
- **FlClash** (Flutter + clash, ближайший аналог sora по стеку): `TileService.kt` — тильт тогглит proxy/VPN, триггерит действия через прозрачную `QuickActionActivity` (START/STOP/TOGGLE); `ServiceBroadcastReceiver` слушает `VPN_START_REQUESTED`/`VPN_REVOKED` и синхронизирует состояние UI с системными событиями. https://deepwiki.com/chen08209/FlClash/5.1-android-integration
- **v2rayNG, NekoBox, Pingtunnel-client** — все имеют QS-тайл с тем же паттерном: `onStartListening()` → чтение состояния → `setState(ACTIVE/INACTIVE)` → `updateTile()`. https://deepwiki.com/itismoej/pingtunnel-client/5.5-quick-settings-tile
- **Android 13+ (API 33)**: `StatusBarManager.requestAddTileService()` — промпт «добавить тайл» в один тап прямо из приложения. Вызывать только в контексте (когда юзер впервые пользуется фичей); при повторных отказах система перестаёт показывать промпт. https://developer.android.google.cn/develop/ui/views/quicksettings-tiles?hl=en
- Flutter-обёртка: пакет `quick_settings_with_flutter_plugins` (`QuickSettings.addTileToQuickSettings()`), тайл показывает title/subtitle/icon, drawable задаётся нативно. https://pub.dev/packages/quick_settings_with_flutter_plugins/versions/1.1.0
- Best practices из документации Android: тайл НЕ должен стартовать activity из фона — использовать `startActivityAndCollapse()` / `unlockAndRun()`; long-press на тайле может вести в настройки (через `ACTION_QS_TILE_PREFERENCES`); состояние тайла всегда перечитывать в `onStartListening()`, т.к. TileService может быть unbound между вызовами. https://developer.android.google.cn/reference/kotlin/android/service/quicksettings/TileService
- Коммерческие: ExpressVPN показывает в шторке уведомление «V — ExpressVPN работает» с именем сервера и кнопкой **Disconnect** — отключение без открытия приложения. https://www.addictivetips.com/vpn/setup-vpn-android/

### 2. Android: уведомление с кнопками Connect/Disconnect
- Паттерн: foreground service (`VpnService`) → `startForeground()` с постоянным уведомлением, в котором `addAction()` — Disconnect (PendingIntent.getService с action STOP), тап по телу — открыть приложение. Стандарт у SSTP-клиента, v2rayNG, ExpressVPN. https://deepwiki.com/kittoku/Open-SSTP-Client/4.1-vpn-service-management, https://ramzijabali.github.io/articles/Dev-Notes/Foreground-Service
- Важно: `FLAG_IMMUTABLE` на PendingIntent, `setOngoing(true)`, отдельный notification channel; на Android 13+ нужен runtime-пермишн `POST_NOTIFICATIONS`.
- В уведомлении полезно показывать: статус (Connected/Connecting), текущий сервер, аптайм/сессия трафика. ExpressVPN показывает сервер в уведомлении.

### 3. iOS: Control Center и виджеты — ограничения
- iOS 18+: Control Center поддерживает контролы сторонних приложений через **ControlWidget API** (на базе WidgetKit + App Intents). Контрол можно добавить через галерею контролов, тап может запускать App Intent. https://www.macstories.net/stories/ios-and-ipados-18-the-macstories-review/4/, https://www.aivanet.com/2024/07/10-changes-to-control-center-in-ios-18/
- Системный тоггл VPN в Control Center (iOS 18.1 — отдельный контрол VPN) управляет только системными VPN-профилями; стороннее приложение не может напрямую тогглить чужой/системный профиль. Свой контрол = тап → App Intent → старт/стоп `NETunnelProviderManager` в фоне. Реально, но с нюансами: App Intent выполняется без открытого UI, NetworkExtension при этом стартует.
- Home Screen виджет (WidgetKit) для VPN — только статус + deep link в приложение; интерактивные кнопки в виджете ограничены App Intent'ами.
- **Вывод: для sora неактуально до появления iOS-порта. Заложить в дизайн: ControlWidget со статусом + тоггл через App Intent.**

### 4. Windows: Quick Settings закрыты для сторонних VPN
- Плитка VPN в Windows 11 Quick Settings работает только для VPN-профилей, управляемых ОС (через Settings → Network → VPN). Стороннее приложение добавить туда свою плитку **не может** — API нет.
- Best practice коммерческих клиентов (NordVPN/ExpressVPN/Surfshark): иконка в трее → контекстное меню Connect/Disconnect + статус; глобальный хоткей; jump list. У sora хоткеи уже есть, трей есть.
- Что можно улучшить: пункт Connect/Disconnect прямо в контекстном меню трея (проверить, что есть), быстрый выбор сервера из трея (подменю «последние серверы»).

### 5. macOS: menu bar — основной quick control
- Паттерн Tunnelblick/Cisco AnyConnect/NordVPN: иконка в menu bar → клик → Connect/Disconnect, выбор конфигурации, статус и IP в первой строке меню. Системный Control Center показывает VPN только для NetworkExtension-профилей.
- Для sora неактуально до macOS-порта. При порте — menu bar extra обязателен с первого релиза.

### 6. Linux: GNOME Quick Settings
- GNOME 43+ имеет системное меню быстрых настроек; сторонние приложения добавляют туда тогглы только через GNOME Shell extension. Практичнее: трей-иконка (у sora есть) с меню Connect/Disconnect + `libappindicator`. KDE — виджет в системном лотке аналогично.
- Низкий приоритет.

## Что sora должен перенять и почему

| # | Фича | Платформа | Почему | Эффект |
|---|---|---|---|---|
| 1 | **QS Tile: тоггл Connect/Disconnect** с синхром состояния (`onStartListening` + broadcast receiver на системные VPN-события) | Android (когда будет порт) | У всех конкурентов; самый частый сценарий — «быстро выключить VPN для банка». FlClash-паттерн (TileService + прозрачная QuickActionActivity) напрямую переносим на Flutter-стек sora | **high** |
| 2 | **Постоянное уведомление FGS с кнопкой Disconnect** (+ имя сервера, трафик сессии, аптайм) | Android | Стандарт ExpressVPN/v2rayNG; отключение без открытия приложения; обязательно как часть VpnService в любом случае | **high** |
| 3 | **`requestAddTileService()` промпт** при первом подключении | Android 13+ | Снимает трение «найди тайл в редакторе»; одноразовый контекстный промпт, дёшево в реализации | **medium** |
| 4 | **Расширить контекстное меню трея**: Connect/Disconnect, подменю «последние 5 серверов», пауза на N минут | Windows/Linux | Компенсирует отсутствие доступа к Windows Quick Settings; у коммерческих клиентов это базовый UX | **medium** |
| 5 | **ControlWidget (iOS 18+)**: статус + тоггл через App Intent | iOS (будущее) | Единственный легальный путь в Control Center для стороннего VPN; заложить при проектировании iOS-порта | **medium** (когда будет iOS) |
| 6 | **Menu bar extra**: Connect/Disconnect, выбор сервера, статус/IP | macOS (будущее) | Базовый UX де-факто для VPN на macOS (Tunnelblick-паттерн) | **medium** (когда будет macOS) |
| 7 | Тоггл в GNOME Quick Settings через расширение | Linux | Нишево; трей покрывает 95% сценариев | **low** |

## Ключевые технические заметки для реализации (Android)
- TileService: `BIND_QUICK_SETTINGS_TILE` permission, `exported=true`, intent-filter `QS_TILE`; `onClick` → `unlockAndRun()`/`startActivityAndCollapse()` (нельзя стартовать activity из фона напрямую).
- Состояние гонки: тильт может показать stale-статус — всегда перечитывать из истины (сервис/sora-core) в `onStartListening()`; широковещательный ресивер на `VPN_REVOKED` для случая «системный диалог отключил VPN».
- Уведомление: `POST_NOTIFICATIONS` runtime permission (Android 13+); кнопки через `PendingIntent.getService` + `FLAG_IMMUTABLE`; `setOngoing(true)`.
- Не дублировать системное VPN-уведомление Android («VPN activated by app») — оно показывается само; уведомление sora — для действий.

## Ссылки
- https://developer.android.google.cn/develop/ui/views/quicksettings-tiles?hl=en
- https://developer.android.google.cn/reference/kotlin/android/service/quicksettings/TileService
- https://developer.android.com/reference/kotlin/android/net/VpnService
- https://deepwiki.com/chen08209/FlClash/5.1-android-integration
- https://deepwiki.com/itismoej/pingtunnel-client/5.5-quick-settings-tile
- https://deepwiki.com/kittoku/Open-SSTP-Client/4.1-vpn-service-management
- https://pub.dev/packages/quick_settings_with_flutter_plugins/versions/1.1.0
- https://www.macstories.net/stories/ios-and-ipados-18-the-macstories-review/4/
- https://www.aivanet.com/2024/07/10-changes-to-control-center-in-ios-18/
- https://www.addictivetips.com/vpn/setup-vpn-android/
- https://umatechnology.org/how-to-turn-off-vpn-windows-11/
- https://cleanmymac.com/blog/how-to-turn-off-vpn-on-mac
