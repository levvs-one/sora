# Веб-исследование #14: Шорткаты и автоматизация — URL-схемы, CLI, deep links

Дата: 2026-10-19. Цель: как конкуренты дают автоматизацию, и что перенять sora.

## 1. Что нашли

### 1.1. CLI как стандарт управления (десктоп / серверы)

- **Tailscale CLI** — зрелый референс: `up/down/login/logout`, `set` (преференсы), `status`, `netcheck`, `exit-node`, `update`, `whois`, `--json` вывод для скриптов, `--wait` для синхронного ожидания (`tailscale status --json | jq ...` — канонический пример автоматизации в пайплайнах). Источники: [Kali tools — полный список субкоманд](https://www.kali.org/tools/tailscale/), [Indie IT Wiki — рецепты автоматизации](https://wiki.indie-it.com/index.php?title=Tailscale&).
- **Mullvad CLI** — эталон для VPN-клиента: `mullvad connect/disconnect/reconnect [--wait]`, `relay set location <cc> <city> <host>`, `relay list`, `status [-v]`, `auto-connect set on/off`, `lan set allow`, `lockdown-mode set on`, `tunnel set ipv6 on`, CLI и GUI взаимозаменяемы, коды выхода 0/1 для скриптов. Источники: [официальный гайд «How to use the Mullvad CLI»](https://mullvad.net/fa/help/how-use-mullvad-cli?gclid=CjwKCAiA04arBhAkEiwAuNOsIo_qm01-jaBXSf27hnDHtU88NgzDdF36NV2Wto0_VXgh3vEvXu63yBoCGasQAvD_BwE), [документация команды reconnect (mintlify)](https://www.mintlify.com/mullvad/mullvadvpn-app/cli/commands/reconnect).
- **Вывод:** у коммерческих VPN-клиентов CLI — полноценный интерфейс управления сервисом, а не дебаг-приложение. У sora CLI вообще нет: управление только через Flutter UI → gRPC.

### 1.2. iOS Shortcuts / App Intents

- **Системное действие «Set VPN»** (iOS 14+): Connect / Disconnect / Toggle / Set On Demand — работает для любого установленного VPN-профиля из Shortcuts/автоматизаций без участия приложения. Источник: [гайд по VPN-шорткату](https://umatechnology.org/how-to-turn-off-vpn-on-iphone-new-shortcut/).
- **Kaspersky VPN для iOS** — публикует собственные действия «Turn on VPN» / «Turn off VPN» и официально документирует автоматизацию «подключить VPN при открытии приложения» через вкладку Automation → App trigger. Источник: [официальный блог Kaspersky](https://www.toddpigram.com/2024/07/how-to-set-up-apple-shortcuts-in-vpn.html).
- **WireGuard для Apple**: обсуждается набор App Intents поверх «turn on/off» (tun on/off, update config), намеренно не дублирующих системное «Set VPN»; интент-триггер по запуску приложения — стандартный сценарий. Источник: [wireguard-apple issue #8](https://gitmemories.com/WireGuard/wireguard-apple/issues/8).
- **Shadowrocket (iOS)** — вместо шорткатов ставит на **On Demand rules** (Wi-Fi/Cellular/домен-триггеры) внутри приложения. Источник: [shadow-help.com, On Demand](https://www.shadow-help.com/en/blog/articles/on-demand-wifi-cellular-trigger.html).
- **Вывод:** на iOS есть два слоя: (а) бесплатный системный «Set VPN» (работает из коробки для любого клиента), (б) собственные App Intents приложения (выбор сервера, триггеры). Коммерческие клиенты делают (б) + документируют рецепты автоматизаций.

### 1.3. Android: Tasker / intents / плагины

- **OpenVPN Connect** — официальный гайд Tasker-интеграции: intents `net.openvpn.openvpn.CONNECT/DISCONNECT` с extras `AUTOSTART_PROFILE_ID`, `AUTOCONNECT`. Это отраслевой стандарт де-факто для «VPN + Tasker». Источник: [официальная документация OpenVPN](https://openvpn.net/connect-docs/how-to-use-tasker.html).
- **WireGuard Android** — экспортирует broadcast actions `com.wireguard.android.action.SET_TUNNEL_UP/DOWN`, `REFRESH_TUNNEL_STATES`; power-users дергают их из Tasker. Источник: [XDA, руководство по WireGuard](https://forum.xda-developers.com/t/guide-how-to-use-wireguard-on-android-ubuntu-and-macos.3723544/page-25).
- **AdGuard Android** — эталонная реализация «automation API»: документированные intent-actions (`start/stop/pause/update`, `dns_filtering`, `proxy_state` и т.д.) + парольная защита от сторонних вызовов. Источник: [AdGuard KB: How to automate](https://kb.Adguard.com/kb/it/adguard-for-android/solving-problems/tasker/).
- **FlClash** — Quick Settings Tile (`TileService`) + `ServiceBroadcastReceiver` на системные события (`VPN_START_REQUESTED`, `VPN_REVOKED`). Источник: [DeepWiki: FlClash Android integration](https://deepwiki.com/chen08209/FlClash/5.1-android-integration).
- **v2rayNG** — явного Tasker API / intent-контракта в публичной документации не найдено (есть только внутренний `ACTION_STOP_V2RAY`); автоматизация идёт через сторонние костыли.
- **Вывод:** стандарт Android-автоматизации = документированные intent-actions (старт/стоп/переключить + выбор профиля) + Quick Settings Tile + опциональная аутентификация вызовов (как у AdGuard).

### 1.4. URL-схемы / deep links у прокси-клиентов

- Все клиенты поддерживают **import-схемы** (`vless://`, `ss://`, `hiddify://`, `sing-box://`, `clash://` и т.д.) — это про импорт конфигов, у sora уже есть (`sora://` + чужие схемы через `app_links`).
- **Action-схемы** (не импорт, а управление) почти ни у кого из опенсорса нет. Исключение-ориентир: Hiddify Panel генерирует deep links вида «one-click import + connect» для связки панель→приложение ([DeepWiki: Hiddify API](https://deepwiki.com/hiddifypanel/5-api-documentation)); коммерческие панели массово используют `https://…/addprofile?url=` → перехват приложением.
- **Вывод:** импорт по deep link — гигиена (у sora есть). Непокрытая ниша — action-ссылки вида `sora://connect?server=…`, `sora://toggle`, которые можно дёргать из браузера, скриптов, ярлыков рабочего стола, Stream Deck и т.п.

### 1.5. Десктопная автоматизация помимо CLI

- У v2rayN/Nekoray публичного CLI/URL-API для управления соединением не найдено — управление только через GUI/трей. Это слабое место всего опенсорсного десктоп-сегмента.
- Стандарт для скриптов на Windows/Linux: CLI с `--json` + кодами выхода (Mullvad/Tailscale-образец), плюс регистрация URL-протокола в реестре/`desktop`-файле, чтобы `sora://…` работал из Run/терминала/ярлыков.

## 2. Что sora должен перенять

Контекст текущего состояния sora (проверено чтением репо): deep-link импорт через `app_links` есть; CLI нет; intent-контракта нет; App Intents нет (iOS клиента вообще нет); Tasker-интеграции нет.

### P0 — `sora` CLI (управление службой из терминала)

- **Что:** бинарь `sora` (рядом с `sora-core`), говорящий с тем же gRPC, что и Flutter UI: `sora connect [имя]`, `sora disconnect`, `sora toggle`, `sora reconnect [--wait]`, `sora status [--json]`, `sora servers list [--json]`, `sora select <имя>`, `sora mode <tun|proxy|off>`, `sora profile <имя>`, `sora subscription update`, `sora version`, коды выхода 0/1, `--json` везде для скриптов.
- **Почему:** закрывает сразу три аудитории — power-users, скрипты/Task Scheduler/cron, headless-серверы (где GUI вообще нет). У Mullvad/Tailscale это доказало ценность; ни у одного опенсорсного прокси-клиента такого нет — чистый дифференциатор. Реализация дешёвая: gRPC API уже существует, нужен только тонкий клиент.
- **Эффект: high.**

### P0 — Action URL-схема `sora://`

- **Что:** расширить существующий `sora://` с импорта на действия: `sora://connect?server=<id|name>`, `sora://disconnect`, `sora://toggle`, `sora://select?server=…`, `sora://import?url=…` (уже есть), `sora://profile?name=…`. Регистрация протокола в инсталляторе (реестр Windows, .desktop Linux).
- **Почему:** универсальный клей для автоматизации без кода: ярлыки рабочего стола, Win+R, скрипты, Stream Deck/макросы, ссылки из браузера и тикетов поддержки («нажми чтобы подключиться к серверу X»). Ни у кого из прямых конкурентов нет action-схемы — только import.
- **Эффект: high.** Сложность S (обработчик уже есть в `desktop.dart`, добавить маршруты).

### P1 — Android: Tasker/интент-контракт + Quick Settings Tile

- **Что (к моменту Android-клиента):** документированные broadcast actions `com.sora.action.CONNECT/DISCONNECT/TOGGLE` с extras (`server`, `profile`), по образцу OpenVPN Connect; защита вызовов опцией «требовать подтверждение/пароль» (урок AdGuard); Quick Settings Tile для переключения (образец FlClash).
- **Почему:** Tasker/Automate/MacroDroid — стандарт автоматизации на Android; без intent-контракта клиент «глух» к экосистеме. v2rayNG этого не даёт — шанс обогнать лидера сегмента именно в автоматизации.
- **Эффект: high** (для мобильного будущего; до выхода Android — medium как подготовка API).

### P1 — Сетевые триггеры внутри приложения (On Demand по-соровски)

- **Что:** правила «подключать/отключать при смене сети»: по SSID, типу сети (Wi-Fi/сотовая/роуминг), captive portal. Это развитие запланированных «сетевых профилей» в сторону автоматических действий, как On Demand у Shadowrocket.
- **Почему:** самый частый реальный сценарий автоматизации («включи VPN вне дома») сегодня решается костылями через Tasker. Встроенные триггеры — фича уровня «лучший клиент», конкурентов с этим в прокси-сегменте нет.
- **Эффект: high.** Сложность M.

### P2 — iOS/macOS: App Intents (когда будет Apple-клиент)

- **Что:** App Intents «Connect to <server>», «Disconnect», «Toggle VPN» + Siri-фразы; системный «Set VPN» заработает сам по себе через NetworkExtension.
- **Почему:** гигиена Apple-экосистемы; Kaspersky и WireGuard показывают образец. Без своих интентов нельзя выбрать сервер голосом/автоматизацией.
- **Эффект: medium** (актуально только после Apple-клиента).

### P2 — Документация «Automation cookbook»

- **Что:** страница в docs: рецепты Tasker, Shortcuts, PowerShell/`sora status --json | jq`, systemd-юниты, примеры для Stream Deck. Mullvad и OpenVPN выигрывают именно документированными рецептами, а не только наличием API.
- **Эффект: medium.** Сложность S, делать вместе с CLI.

## 3. Сводная оценка

| # | Мера | Сложность | Эффект | Обоснование эффекта |
|---|---|---|---|---|
| 1 | CLI `sora` поверх gRPC | S/M | **high** | Нет ни у одного опенсорсного прокси-клиента; открывает headless, скрипты, Task Scheduler |
| 2 | Action URL-схема `sora://connect/disconnect/toggle` | S | **high** | Дешёвый универсальный клей автоматизации; у конкурентов только import-схемы |
| 3 | Android intent-контракт + QS Tile | M | **high** (после Android) | Стандарт Tasker-экосистемы; v2rayNG этого не даёт |
| 4 | Сетевые триггеры (SSID/тип сети) | M | **high** | Топ-сценарий автоматизации из коробки; ни у кого в сегменте нет |
| 5 | App Intents (iOS/macOS) | M | medium | Гигиена Apple, после появления клиента |
| 6 | Automation cookbook в docs | S | medium | Умножает ценность CLI/intents; образец — Mullvad/OpenVPN docs |

## 4. Рекомендуемый порядок

1. **Сейчас (десктоп):** CLI + action-схема `sora://` — обе меры дешёвые, ложатся на существующие gRPC и `app_links`, дают максимальный дифференциатор именно там, где sora уже силён (десктоп).
2. **С Android-клиентом:** intent-контракт и QS Tile проектировать сразу, не «потом».
3. **Следом:** сетевые триггеры как развитие профилей; cookbook параллельно с CLI.
