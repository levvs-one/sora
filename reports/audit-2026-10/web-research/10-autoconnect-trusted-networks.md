# Web research #10: Auto-connect / доверенные сети UX

Дата: 2026-10-19. Запросы: 8 (browser.search), приоритет источникам 2025–2026.
Репозитории sora: только чтение (подтверждено: есть auto-connect при старте, есть сетевые профили F5 в разработке, нет доверенных сетей, нет captive portal handling).

## 1. Что делают конкуренты

### IVPN — эталон trusted-network UX
- Для каждого Wi-Fi (SSID) — статус доверия: trusted / untrusted / none + действия при подключении: автоподключение VPN на ненадёжных, автоотключение на доверенных. Отдельно: блокировать LAN на ненадёжных сетях.
- Дефолтный статус для новых сетей (рекомендация IVPN: `untrusted`).
- Источники: [блог IVPN (2018, фича жива в текущих apps)](https://www.ivpn.net/blog/new-trusted-wi-fi-networks-feature-for-ivpn-apps/), [DeepWiki по iOS-клиенту — ключи `networkProtectionUntrustedConnect`, `networkProtectionTrustedDisconnect`, `networkProtectionUntrustedBlockLan`](https://deepwiki.com/ivpn/ios-app/8.2-network-protection).

### PIA — Automation rules
- Правила «подключить/отключить при присоединении к сети»: на мобильных — по типу сети (защищённый Wi-Fi / открытый Wi-Fi / сотовая), на Android/Windows — по конкретной сети.
- Важно: Engadget-тест показывает, что правила срабатывают нестабильно («doesn't work half the time»), на iOS/macOS — только 3 типа сети, без привязки к SSID. Android требует разрешение на геолокацию, чтобы читать SSID.
- Источники: [PIA helpdesk — Network Management/Automation](https://helpdesk.privateinternetaccess.com/kb/articles/i-am-experiencing-issues-with-the-ios-automation-feature), [Engadget PIA review](https://www.engadget.com/cybersecurity/vpn/private-internet-access-vpn-review-both-more-and-less-than-a-budget-vpn-120033882.html).

### Windscribe — Network Options + per-network memory
- Список всех встреченных сетей, каждой — метка Secured/Unsecured (название вводит в заблуждение: Secured = «VPN включается на этой сети»; Engadget критикует терминологию).
- Переключатель Auto-Secure Networks: новые сети автоматом помечаются Secured. На каждую сеть можно назначить свой протокол.
- Отдельно: клиент запоминает, какой протокол лучше всего работает на каждой сети, и применяет при повторном подключении (per-network protocol memory).
- Источники: [Engadget Windscribe review — Network Options](https://www.engadget.com/cybersecurity/vpn/windscribe-review-despite-the-annoyances-it-has-the-right-idea-120000837.html), [Windscribe KB о протоколах — per-network memory](https://windscribe.com/knowledge-base/articles/which-vpn-protocols-perform-the-best).

### AdGuard VPN
- Auto-protection: просыпается и подключается при присоединении к ненадёжному Wi-Fi (только мобильные apps). Отдельно: автоподключение при старте устройства, kill switch.
- Источник: [AdGuard VPN for Android](https://adguard-vpn.com/en/android/overview.html), [AdGuard — автоматизация на любой ОС](https://onlinegeeks.net/automate-adguard-vpn-on-any-os/).

### Mullvad — без trusted networks
- Только: launch on startup / connect on launch (независимые тумблеры), Always-on VPN (Android OS), встроенный kill switch + «Always require VPN». SSID-логики нет.
- Источник: [Mullvad — Android VPN settings](https://mullvad.net/de/help/using-mullvad-vpn-on-android).

### Proton VPN — доверенных сетей нет, пользователи просят
- Auto-connect при старте приложения; на мобильных — auto-connect на ненадёжных сетях.
- В Proton UserVoice два топовых запроса именно про это: «автовключение VPN на публичном/скомпрометированном Wi-Fi» (463 голоса) и «отключать VPN на доверенном Wi-Fi» (385 голосов) — т.е. даже у Proton это не закрыто.
- Источник: [Proton UserVoice — VPN feature ideas](https://protonmail.uservoice.com/forums/932836-proton-vpn/category/397504/filters/top?page=1).

### IPVanish — Trusted Networks
- Пользователь помечает доверенные сети (Wi-Fi/Ethernet/сотовая); всё остальное считается ненадёжным → автовключение VPN. На доверенных — VPN не включается.
- Источник: [IPVanish support](https://support.ipvanish.com/hc/en-us/articles/6668692952219-Using-the-IPVanish-Trusted-Networks-Feature).

### NordVPN / Surfshark / hide.me / CyberGhost
- Nord: auto-connect на ненадёжных сетях. Surfshark: Auto Connect при присоединении к Wi-Fi/Ethernet. hide.me: различает secure/insecure сети. CyberGhost: Wi-Fi-правила.
- Источник: [обзор «Best VPN for Public Wi-Fi 2026»](https://www.wonderhowto.com/forum/buyers-guides-best-vpn-for-wifi-security/).

### Kaspersky VPN — детект ненадёжности по свойствам сети
- Критерии «небезопасной» сети: нет пароля, слабое шифрование, распространённый SSID, включён WPS, публичная сеть. Настраиваемые промпты «включить защищённое соединение».
- Источник: [Kaspersky support](https://support.kaspersky.com/us/ksec-for-windows/155630).

### Speedify — Captive Portal Assist (единственный внятный референс)
- Детектит captive portal → уведомление «хотите войти?» → открывает страницу портала в отдельном окне, трафик к порталу временно идёт мимо туннеля → после логина трафик возвращается в туннель. VPN-сессия не рвётся (на мобильных — держится за счёт сотовой).
- Источник: [Speedify KB — Captive Portal Handling](https://support.speedify.com/article/877-captive-portal).

## 2. Платформенные ограничения (важно для реализации)
- **Android**: чтение SSID требует разрешения на геолокацию (у PIA из-за этого застревают пользователи). API: `WifiManager`/`ConnectivityManager`, `NetworkCallback`.
- **Windows**: текущий SSID — через Native WLAN API / `netsh wlan show interfaces`; смена сети — NLM (Network List Manager) события.
- **Linux**: NetworkManager D-Bus — `PropertiesChanged` на активных соединениях, SSID/BSSID/тип безопасности доступны.
- Детект captive portal: OS-уровень — Android (`ConnectivityManager` captive portal API), Windows (NCSI), Linux (NetworkManager connectivity check); app-уровень — HTTP-проба к `connectivitycheck`/`generate_204`.

## 3. Что sora должен перенять

### (1) Доверенные сети как часть сетевых профилей — эффект HIGH
**Что:** таблица сетей (SSID/BSSID + тип сети) со статусом: доверенная / ненадёжная / не задано; действия при присоединении: подключить VPN (на ненадёжной), отключить (на доверенной), «не трогать». Дефолт для новых сетей — **ненадёжная** (как рекомендует IVPN; safe default).
**Почему:** это отраслевой стандарт де-факто (IVPN, PIA, Windscribe, AdGuard, IPVanish); у Proton это топ-просьба пользователей. У sora сетевые профили (F5) уже в разработке — доверенные сети естественно становятся первым измерением профиля, а не отдельной фичей. Даёт «умное» поведение вместо вечного ручного вкл/выкл.
**Связь с планами:** прямое усиление F5 (сетевые профили с автоопределением). Terminology: не повторять ошибку Windscribe — называть «доверенная/ненадёжная сеть», а не «secured/unsecured».

### (2) Автоподключение при присоединении к сети (не только при старте) — эффект MEDIUM
**Что:** сейчас у sora auto-connect срабатывает при старте; добавить триггер «присоединение к новой/ненадёжной сети» + переподключение при смене сети (частично уже есть — переподключение при смене сети/сне, по competitor-analysis).
**Почему:** главный сценарий — ноутбук/телефон, прыгающий между кафе/отелем/офисом. Ноутбук — ключевой кейс для десктопного sora сегодня.

### (3) Per-network memory протокола/транспорта — эффект MEDIUM
**Что:** запоминать, какой движок/транспорт/протокол реально сработал на данной сети (SSID), и применять при повторном входе. У Windscribe это уже есть для протоколов; у sora — мульти-движок, так что память должна быть парой «движок+транспорт».
**Почему:** питает фичи §3 №1–2 competitor-analysis (умный выбор «сервер+движок», авто-тюнинг под DPI): первая ручная победа на сети превращается в автоматическую. Дешёвая в реализации (таблица SSID → последний рабочий конфиг), видимая польза в странах с DPI.

### (4) Эвристика ненадёжности сети — эффект MEDIUM
**Что:** автоопределение «открытая сеть / WEP / распространённый SSID / captive portal» → авто-классификация как ненадёжной + промпт пользователю (модель Kaspersky).
**Почему:** закрывает кейс «пользователь забыл пометить сеть» — safe default работает без ручной разметки.

### (5) Captive portal handling — эффект MEDIUM
**Что:** по Speedify-паттерну: детект портала → тост/уведомление «требуется вход в сеть» → временный выпуск трафика к порталу мимо VPN (узкий allowlist: DNS + HTTP(S) к IP портала, остальное — kill switch держит) → возврат в туннель после авторизации.
**Почему:** в competitor-analysis (§3 №6) уже отмечено как «боль всех VPN-клиентов, не реализовано ни у кого из прокси-клиентов». Speedify — единственный референс. Реализация S/M; сильный дифференциатор именно для путешественников.

### (6) Промпт «доверять этой сети?» при первом подключении — эффект LOW (дешёвый UX)
**Что:** одноразовый вопрос при присоединении к новой сети. Заполняет таблицу доверия без похода в настройки.
**Почему:** решает проблему холодного старта таблицы сетей; почти нулевая цена.

### (7) Усиление kill switch на ненадёжных сетях — эффект LOW
**Что:** режим «на ненадёжных сетях — strict: нет VPN = нет интернета» (аналог PIA Advanced / Mullvad «Always require VPN»).
**Почему:** у sora kill switch уже встаёт до запуска ядра — это скорее экспозиция существующего в UI доверенных сетей, а не новая механика.

## 4. Чего НЕ перенимать
- **Модель PIA «только 3 типа сети, без SSID» на десктопе** — урезана и, судя по Engadget, глючит; SSID-уровень (IVPN/Windscribe) информативнее.
- **Терминологию Windscribe** (Secured = «VPN включается») — пользователи путаются; говорить языком доверия к сети.
- **Обязательную геолокацию ради SSID** — на Android запрашивать location только когда пользователь включает automation, с объяснением зачем (урок PIA).

## 5. Предлагаемый порядок
1. Доверенные сети (п.1) как первая реализация измерения в F5-профилях + дефолт «ненадёжная» + промпт при первом подключении (п.6).
2. Триггер «присоединение к сети» (п.2) поверх существующего переподключения.
3. Per-network memory транспорта (п.3) — фундамент под авто-тюнинг DPI.
4. Эвристика ненадёжности (п.4), затем captive portal (п.5).
