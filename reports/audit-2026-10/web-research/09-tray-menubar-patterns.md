# Паттерны tray / menu-bar приложений: веб-исследование

Дата: 2026-10-19. Источники: обзоры и доки Mullvad, PIA, NordVPN, ProtonVPN, AdGuard, Apple HIG, GNOME/StatusNotifier-спеки, Flutter-экосистема. Контекст текущего трея sora: `app/lib/src/desktop/desktop.dart` (пакет `tray_manager`).

Текущий трей sora (база): иконка on/connecting/off + тултип «статус: сервер»; меню: строка статуса → Connect/Disconnect → подменю Server (Auto + первые 40, radio-check) → подменю Modes (TUN/proxy/serverless) → Open / Quit. Левый клик — открыть окно, правый — меню. Linux: ожидание StatusNotifierWatcher по D-Bus, меню не пересобирается пока открыто.

## 1. Что делают конкуренты

**Mullvad** — эталон минимализма: замок в menu bar, зелёный = подключён, красный = нет ([blog](https://mullvad.net/fa/blog/linux-users-official-release-mullvad-vpn-app)). Смена локации прямо из меню → автореконнект. «Recents»: 3 последних локации запоминаются и показываются сверху списка ([help](https://mullvad.net/de/help/using-mullvad-vpn-on-android)). Кастомные списки локаций (аналог favorites) — быстрый доступ к глубоким пунктам.

**AdGuard VPN** — «полная функциональность в трей-меню»: connect, выбор сервера, disable, список исключений, настройки, поддержка, выход ([mac beta changelog](https://adguard-vpn.com/pt_pt/versions/mac/beta.html)). На Windows добавили в меню кнопки Connect, **Check for updates** и **полосу статуса соединения**; в списке серверов — флаги стран ([windows changelog](https://adguard-vpn.com/en/versions/windows/release.html)). Трей как мини-панель управления, а не просто меню.

**PIA** — дашборд по умолчанию **прикреплён к трею** (панель висит над иконкой в правом нижнем углу), опционально отделяемое окно ([digitaltrends](https://www.digitaltrends.com/computing/private-internet-access-vpn-review/)). Настройки: Tray Icon Style, Connect on Launch, серверный список с сортировкой по пингу прямо в панели ([piavpnsupport](https://piavpnsupport.zendesk.com/hc/en-us/articles/46813740976667-Understanding-Advanced-Settings-on-the-Desktop-PIA-Client)). Критика: tray-only без опции окна раздражает часть пользователей ([reviews.org](https://www.reviews.org/au/vpn/private-internet-access-review/)) — выбор режима панели должен быть в настройках.

**NordVPN (Linux tray, v3.18+)** — трей-панель: статус, Quick connect, «Connect to» (список серверов), настройки (тумблеры tray icon / notifications), аккаунт, Quit. Цвет иконки = статус: белая = отключён, синяя = подключён ([support.nordvpn.com](https://support.nordvpn.com/hc/en-us/articles/25538632595601-How-to-use-NordVPN-Tray-functionality-on-Linux)). Урок: в трей выносят **квик-тогглы**, а не только connect.

**ProtonVPN** — пользователи просят менять **цвет иконки** под статус, потому что мелкий крестик/галочка нечитаем на HiDPI ([uservoice](https://protonmail.uservoice.com/forums/932836-proton-vpn/filters/top?category_id=397501-changes-to-existing-features)). Урок: состояния должны различаться формой/цветом целиком, а не деталями. Отключение — прямо из трей-иконки (Windows) ([robots.net](https://robots.net/tech/how-to-use-proton-vpn/)).

## 2. Платформенные различия

- **Windows 11:** notification area + overflow под стрелкой; иконки часто скрыты по умолчанию — sora уже показывает hint при первом сворачивании в трей (хорошо). Иконки — .ico с несколькими размерами; монохром-дружелюбные (тёмная/светлая панель). Правый клик = контекстное меню, левый = действие/окно. Тултипы иногда «залипают» (известный баг у NordVPN) — тултип держать коротким.
- **macOS (будущее sora):** menu bar extras — **монохромные template-изображения** (система красит), левый клик = меню (а не окно — в отличие от Windows). Apple HIG: иконки у пунктов меню — скупо и только с ясным смыслом ([HIG via 9to5mac](https://9to5mac.com/2026/06/11/apple-again-warns-developers-not-to-do-what-apple-did-in-macos-26-tahoe/)). При порте на macOS текущий паттерн «левый клик → окно» надо инвертировать.
- **Linux:** стандарт — StatusNotifierItem/AppIndicator по D-Bus; GNOME по умолчанию без расширения трея нет (нужен AppIndicator extension) ([discourse.gnome.org](https://discourse.gnome.org/t/what-to-use-instead-of-statusicon-in-gtk4-to-display-the-icon-in-the-system-tray/7175.rss)). sora уже корректно ждёт StatusNotifierWatcher — держать. Меню на GNOME рендерится расширением через DBusMenu: глубокие подменю и radio-группы могут выглядеть иначе — меню держать **плоским и коротким**.

## 3. Flutter-экосистема

- `tray_manager` (leanflutter) — то, что уже использует sora; мейнстрим, Win/macOS/Linux. Оставаться на нём.
- `system_tray` (antler119) — старше, менее активно.
- `flutter_desktop_tray` — новый (2025–2026), stream-based события, checked/disabled пункты ([pub.dev](https://pub.dev/packages/flutter_desktop_tray)). Интересен для будущих платформ, но миграция не нужна: `tray_manager` покрывает всё.
- `hotkey_manager` (тот же автор) — глобальные хоткеи; естественное дополнение трея (коннект/дисконнект по хоткею).

## 4. Что sora должен перенять

| # | Перенять | Почему | Эффект |
|---|---|---|---|
| 1 | **Recents вверху подменю серверов** (последние 3–5, как у Mullvad) | Самый частый сценарий смены сервера — повторный; сейчас подменю — первые 40 без порядка использования | high |
| 2 | **Флаги/метки стран в списке серверов трея** (как AdGuard) | Быстрое сканирование списка глазами; у sora уже есть флаги? в UI — донести в трей | medium |
| 3 | **Reconnect + «подключиться при старте» из трея** | У sora есть Connect/Disconnect, но нет явного Reconnect при зависшем соединении; connect-on-launch сейчас только в настройках окна | medium |
| 4 | **Квик-тогглы в трей-меню**: kill switch, serverless/zapret, сетевой профиль (когда появится F5) | Паттерн NordVPN/AdGuard: трей = мини-пульт, а не только connect. Для «штопора»/DPI-ситуаций критично переключать не открывая окно | high |
| 5 | **Check for updates в трей-меню** (как AdGuard) | У sora автообновление уже есть; пункт в трее — видимость для пользователя | low |
| 6 | **Опция «панель у трея» vs отдельное окно** (урок PIA) | Когда-нибудь: PIA-style attached panel над треем как альтернатива окну; но обязательно с выбором в настройках — tray-only раздражает | medium |
| 7 | **Глобальный хоткей connect/disconnect** (hotkey_manager) | Дополняет трей для power-user; в roadmap уже есть «хоткеи на профили» (§3 №14) — начать с базового тоггла | medium |
| 8 | **Иконка различается целиком** (форма+цвет, не детали) | Урок ProtonVPN/HiDPI: on/connecting/off у sora уже разные файлы — проверить читаемость на 16px в тёмной и светлой теме, добавить вариант для colorblind (форма, не только цвет) | medium |
| 9 | **Плоское короткое меню на Linux** | DBusMenu/GNOME-расширения плохо переваривают глубину; серверы уже урезаны до 40 — держать, recents сверху вместо расширения списка | low |
| 10 | **macOS: заложить инверсию кликов и template-иконки** | macOS нет в планах ближайших, но архитектуру Desktop не цементировать под «левый клик = окно»; вынести click behavior за платформенный флаг | low (сейчас) |

## 5. Чего НЕ делать

- Не раздувать трей-меню до «второго главного окна» — потолок: статус, connect/disconnect/reconnect, recents+серверы, 2–3 квик-тоггла, режимы, открыть/обновления/выход.
- Не вешать иконку на каждый пункт меню (Apple HIG прямо против; актуально для будущего macOS).
- Не полагаться на тултип как единственный индикатор статуса (залипания, тачскрины).
