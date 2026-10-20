# UX-паттерны лучших VPN-клиентов 2025–2026

Дата: 2026-10-19. Метод: 7 поисковых сессий (browser.search), приоритет источникам 2025–2026: релиз-ноуты Proton/AdGuard/Windscribe, обзоры Mullvad/IVPN/Amnezia, гайды v2rayNG/Hiddify/NordVPN.
База для сравнения — UI, уже имеющийся в `sora/app/lib/src/ui`: home, servers, settings_screen, connections, dns, profiles, chains, sync, qr, benchmark, speedtest, rules, modes, subscription(_sheet), logs, notifications/toasts, tour, extensions.

## 1. Что нашёл (по продуктам)

### Mullvad (2025–2026, обзоры PCWorld/Engadget/Security.org)
- Главный экран предельно простой: карта, баннер-статус сверху (красный = disconnected, зелёный = connected), кнопка выбранного сервера и огромная кнопка Connect внизу. Настройки — почти все в виде простых тумблеров.
- Кнопка-«стрелка» рядом с локацией при активном подключении: мгновенная смена сервера **в той же локации** без разрыва (удобно при блокировках/стриминге).
- Дриллдаун страна → город → конкретный сервер; у серверов точки доступности (зелёная/красная). Метрик пинга НЕТ — осознанно.
- Имя устройства для аккаунта — двухсловный никнейм (прилагательное + животное) вместо «Device 1». Источники: [PCWorld](https://www.pcworld.com/article/395038/mullvad-vpn-review-2.html), [mullvad.net](https://mullvad.net/de/help/using-mullvad-vpn-on-android).

### IVPN (обзоры 2025–2026)
- Список стран с пингом у каждой локации и цветным индикатором (зелёный/красный) «насколько будет быстро».
- Переключение single-hop / multi-hop — **две кнопки внизу** вместо вкладок.
- Preferences свернули в один экран (не вкладки).
- «Fastest server» как явный вариант выбора. Источники: [Cloudwards](https://www.cloudwards.net/ivpn-review/), [Wizcase](https://www.wizcase.com/reviews/ivpn/).

### Proton VPN (редизайн 2025–2026 — главный источник новых паттернов)
- Новый home: статус подключения на карте, счётчик блокировок NetShield (реклама/трекеры + сэкономленные данные), **Recent + Favorites** подключения с пинами и one-tap доступом, быстрые ссылки на продвинутые фичи с главного экрана.
- Фильтрация серверов: страна / город / purpose (стриминг, P2P) / качество; **City view** из списка стран.
- **System tray mini-app** (Windows, mid-2025): connect/disconnect/смена профиля без открытия окна + иконка статуса в трее.
- «ⓘ» Info рядом с каждой фичей — короткое человеческое объяснение вместо жаргона.
- Connection preferences: исключение локаций из «Fastest».
- **Connect & Go** (Android): автозапуск приложения/сайта (можно в инкогнито) из VPN-профиля при подключении.
- Виджеты Android/iOS: статус + one-tap доступ к избранным профилям без открытия приложения.
- Custom DNS **в профиле** (не только глобально), kill switch стал проще найти и работает вместе со split tunneling.
- 35 языков (у sora 31 — паритет держать). Источники: [релиз-ноуты Windows](https://protonvpn.com/support/release-notes-windows), [fall-winter recap 2025–2026](https://protonvpn.com/blog/fall-winter-recap-2025-2026?srsltid=AfmBOoovAYsjlHbG3RX_Fx3Onu2BTz7Ni0aeNRUvzb213wz2SYO1sngP), [релиз-ноуты Android](https://protonvpn.com/support/release-notes-android), [Cloudwards guide](https://www.cloudwards.net/how-to-use-proton-vpn/).

### NordVPN (mobile redesign 2026)
- При открытии — сразу предложенная локация (город рядом со страной).
- Меню «⋯» → «Show connection details»: текущий IP, номер сервера, время соединения, reconnect, switch location, settings, help — всё из одного места.
- Карта: компактный вид + разворот на весь экран, пины локаций, подключение кликом по пину. Источник: [nordvpn.com/blog](https://nordvpn.com/blog/mobile-app-redesign-2026/).

### AmneziaVPN (5.x, 2026)
- Гигантская кнопка подключения, минимум суеты — паттерн Mullvad, но у self-hosted клиента.
- Киллер-UX: развёртывание сервера из приложения по IP + SSH (приложение само ставит всё по SSH).
- Критика обзоров: нельзя сменить сервер «на лету» без разрыва; список стран без сортировки по имени/пингу. Источники: [dieg.info](https://dieg.info/en/review/review-amnezia-vpn/), [vpnthat.com](https://vpnthat.com/2026/03/19/amnezia-vpn-review-the-pros-the-cons-and-the-truth/), [xda-developers](https://www.xda-developers.com/self-hosted-vpn-works-where-wireguard-gets-blocked/).

### Windscribe (UI-апдейт 2025)
- **Смена протокола в один клик с главного экрана** (клик по сети → Auto-Secure, Preferred Protocol) — не копаться в 5 слоях настроек.
- Переименование локаций (свои никнеймы серверам: «Rat Island»), круглые флаги, кастомные фоны отдельно для Connected/Disconnected.
- Экспорт конфигов OpenVPN/IKEv2/WireGuard для роутеров. Источники: [windscribe.com/blog](https://windscribe.com/blog/app-update-customization/), [activatesecurity.com](http://activatesecurity.com/blog/is-windscribe-a-good-vpn/).

### AdGuard VPN (2025–2026)
- **Dynamic protocol selection**: режим Auto сам выбирает более быстрый/стабильный протокол под текущие условия.
- Разделение «Launch at startup» vs «Open main window at system startup».
- Оптимизация открытия окна 2–2.5с → 0.2–0.3с.
- Полная accessibility (v2.10, авг 2026): screen reader + только-клавиатурная навигация по всем разделам.
- Паттерн «ключевые настройки на первом экране, продвинутые — не прятать, а убирать из поля зрения» (про их редизайн AdGuard). Источники: [adguard.com 2025 recap](http://adguard.com/en/blog/adguard-2025-year-recap.html), [AdGuard VPN Windows v2.10](https://adguard-vpn.com/en/blog/adguard-vpn-for-windows-v2-10.html).

### Open-source клиенты (v2rayNG / Hiddify / v2rayN)
- v2rayNG: серверный список + ручной тест задержки по каждому, кнопка подключения внизу справа; v2rayN (десктоп): **batch speed-test** всех узлов, realtime-мониторинг, трей-меню как второй UI.
- Hiddify: центральная кнопка подключения, профиль с трафиком и остатком дней на главном экране, QR-скан, автовыбор узла по задержке. Источники: [v2rayfaq guide](https://www.v2rayfaq.com/en/guide.html), [deepwiki hiddify](https://deepwiki.com/hiddify/hiddify-app), [vpngp.com 2026](https://www.vpngp.com/en/blog/articles/android-vpn-recommendation-2026.html).

### Общие паттерны из UX-обзоров
- Зелёный = connected, красный = disconnected; большой Connect; без жаргона на главных экранах (вместо «IKEv2» — «High Security Mode»). [symlexvpn.com](https://symlexvpn.com/importance-of-ui-ux-in-vpn-app-development/), [kolpolok.com](https://kolpolok.com/vpn-interface-ui-ux-tips/)

## 2. Что sora должен перенять и почему

| # | Паттерн (у кого) | Что сделать | Почему / эффект |
|---|---|---|---|
| 1 | Mullvad/Proton home | Главный экран: статус-баннер (цвет + текст), огромная Connect, текущий IP / сервер / время сессии, кнопка выбранного сервера | Основа «лучшего клиента»: состояние видно за 0.3 сек. У sora home уже есть — довести до этого стандарта. **high** |
| 2 | Mullvad стрелка-ресвитч | One-tap смена сервера в той же локации при активном соединении | Киллер для обхода блокировок стримингов/сайтов; у sora fallback-группы есть в ядре — не хватает кнопки. **high** |
| 3 | Proton ⓘ-пояснения | Короткие человеческие описания у каждой фичи в UI, без жаргона | Снижает порог входа и число тикетов; дешево. **high** |
| 4 | Proton recents/favorites | Закреплённые и недавние серверы/профили на главном экране, one-tap | Ускоряет ежедневное использование; sora уже имеет profiles — добавить пины. **high** |
| 5 | IVPN пинг + цвета | Пинг у каждого сервера в списке + зелёный/красный индикатор; сортировка по имени/пингу; фоновая перепроверка (re-test) | «Самый быстрый» должен быть виден глазами; Amnezia за отсутствие сортировки критикуют. **medium** |
| 6 | Windscribe смена протокола с home | Быстрый цикл транспорт/движок с главного экрана (у sora — 3 движка, уникальное преимущество) | Мульти-движок — дифференциатор sora, но спрятан в настройках. **high** |
| 7 | Proton tray mini-app | Расширить трей: connect/disconnect/смена сервера/избранное без открытия окна | Power-user используют трей чаще окна. **medium** |
| 8 | Proton виджеты / Quick tile | Android: виджет и Quick Settings tile со статусом и one-tap подключением | Связано с выходом Android-клиента (P0-гап). **medium** |
| 9 | Windscribe никнеймы | Пользовательские имена серверов («рабочий для YouTube») | В странах с цензурой пользователи помнят «какой сервер работает» — дёшево и точно в боль. **medium** |
| 10 | NordVPN connection details | Меню/панель: IP, сервер №, uptime, кнопка reconnect, switch location | Прозрачность = доверие; у sora данные есть (connections API). **medium** |
| 11 | Proton kill switch заметность | Kill switch — видимый тумблер рядом с подключением, а не глубоко в настройках | Безопасность не должна требовать поиска. **high** |
| 12 | AdGuard auto-transport | Режим «Авто»: сам выбирает быстрейший/стабильный движок+транспорт под текущие условия | Прямое продолжение идеи «умный выбор сервер+движок» (roadmap §3 №1); AdGuard уже делает в проде. **high** |
| 13 | IVPN/Windscribe плоские настройки | Один экран preferences, группировка, без глубоких вложенностей | Сейчас в sora настроек много и растёт — без плоской архитектуры утонет. **high** |
| 14 | Proton Connect & Go | Действия при подключении/отключении профиля: открыть сайт/приложение | Автоматизация ежедневных сценариев; дешёво. **medium** |
| 15 | Mullvad двухсловные ники | Дружелюбные имена устройств вместо «Device 1» (для будущего sync) | Мелочь, но запоминается; пригодится для P2P-синка. **low** |
| 16 | AdGuard accessibility | Screen reader + полная клавиатурная навигация | «Лучший клиент» должен быть доступен всем; конкурентов, сделавших это полностью, мало. **medium** |
| 17 | AdGuard скорость открытия | Окно открывается мгновенно (<0.3с), холодный старт оптимизирован | Воспринимаемое качество; пользователи открывают VPN десятки раз в день. **medium** |
| 18 | Mullvad/Proton city view | Дриллдаун страна → город → сервер | При росте числа серверов в подписках — обязательно. **medium** |
| 19 | Proton NetShield-счётчик | На главном: сколько рекламы/трекеров заблокировано, сколько данных сэкономлено | У sora блокировка рекламы есть — показать цифру = видимая ценность. **medium** |

## 3. Чего НЕ перенимать
- Отказ Mullvad от пингов — для sora (anti-censorship) задержка критична, скрывать её нельзя.
- Кастомизация фонов Windscribe («енот с сигаретой») — фан, не ценность; не тратить время.
- Встроенные покупки/пейволлы коммерческих — sora бесплатна, паттерны монетизации не применимы.

## 4. Приоритет для sora (сводка)
**Сначала (high):** довести home до стандарта Mullvad/Proton (п.1), one-tap ресвитч (п.2), ⓘ-пояснения (п.3), recents/favorites (п.4), быстрый цикл движка с home (п.6), видимый kill switch (п.11), плоские настройки (п.13), auto-transport (п.12).
**Затем (medium):** пинги+сортировка в списке серверов, tray mini-app, виджеты/tile (вместе с Android), никнеймы серверов, connection details, Connect & Go, city view, счётчик блокировок, accessibility, скорость открытия окна.
