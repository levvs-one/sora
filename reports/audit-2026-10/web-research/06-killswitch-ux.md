# Kill switch UX-паттерны (веб-исследование)

Дата: 2026-10-19. Источники: официальные docs/FAQ (Mullvad, Proton VPN, Windscribe, AdGuard VPN), ревью 2025–2026 (Gizmodo, Cloudwards, PCWorld, Security.org, Rtings, VPN.com, Privacy Guides), DeepWiki по открытым клиентам IVPN/Proton (GTK-app).
Repo-reading: `sora` (только чтение; кода не писался).

## 0. Что у sora сейчас

- Kill switch: простой **bool-тумблер** в настройках (`modes.dart`: `sora.setKillSwitch(v)`), по умолчанию **выключен** (`settings.dart: getBool ?? false`).
- Механика: guard владеет kill switch, gRPC `SetKillSwitch(enabled)` на running session (`core/control/server.go:609`); nftables/WFP, «встаёт до запуска ядра».
- Нет уровней, нет предупреждений, нет персистентности после перезагрузки, нет диалога-подтверждения при отключении.

## 1. Что нашёл

### 1.1 Mullvad — kill switch неотключаемый + Lockdown mode

- Встроенный kill switch **включён по умолчанию и отключить нельзя**; блокирует весь трафик при обрыве туннеля до восстановления. FAQ: «How do I enable the kill switch?» — «enabled by default and cannot be disabled».
- **Lockdown mode** (Settings → VPN Settings): блокирует **весь** интернет, пока устройство не подключено к Mullvad — даже при ручном отключении. Отдельный, более строгий слой поверх базового.
- Android: ведут на системные настройки — Always-on VPN + **«Block connections without VPN»** (Android 8+, не на Android TV). В UI прямо объясняют, что это блокирует и исключённые из split-tunneling приложения, и LAN.
- iOS: опция «Force all apps» (аналог lockdown).
- Обучающий паттерн: страница mullvad.net/check — пользователь может сам проверить состояние (IP, DNS-утечки, WebRTC) одной кнопкой.

Источники:
- https://mullvad.net/de/help/using-mullvad-vpn-on-android
- https://mullvad.net/en/help?Topic=privacy
- https://gizmodo.com/best-vpn/mullvad-vpn
- https://www.security.org/vpn/mullvad/
- https://discuss.privacyguides.net/t/what-should-we-require-of-vpn-providers-on-macos/36175?page=5

### 1.2 IVPN — Firewall вместо kill switch, уровни strictness

- Называется **Firewall** (не «kill switch»): действует на всю систему, блокирует пакеты вне туннеля даже когда VPN неактивен.
- Два режима: **always-on firewall** (строгий lockdown: ничто не выходит мимо VPN, даже при закрытом клиенте) и **on-demand firewall** (только когда VPN подключён — классический kill switch). Можно выбрать, при каком событии firewall снимается: при ручном отключении или при закрытии клиента.
- Уровни не трёхуровневые, но опция «когда снимается» — это по сути третий axis UX.
- Desktop (macOS/Linux/Windows): kill switch всегда активен по умолчанию, без Network Extension, на Packet Filter; optional advanced kill switch («Always-on firewall») + LaunchDaemon, чтобы держать блокировку на boot.
- UI-нотация на главном экране про AntiTracker («Blocks trackers whilst connected») — ревьюеры критикуют, что текст не объясняет всей сути (урок: подписи должны честно описывать поведение).

Источники:
- https://www.cloudwards.net/ivpn-review/
- https://www.ivpn.net/knowledgebase/general/antitracker-faq/
- https://defensivecomputingchecklist.com/vpn.my.experiences.php

### 1.3 Proton VPN — Standard vs Advanced, самая чистая UX-модель

- **Standard**: срабатывает только при **случайном** обрыве; ручное отключение = интернет открыт. Удобно для тех, кто часто переключает серверы.
- **Advanced** (Windows, Linux GUI, iOS/iPadOS beta): интернет работает **только** при активном VPN; персистентно, **переживает перезагрузку** (WFP-правила на Windows). Включается через быстрые настройки → Kill Switch.
- GTK-клиент (открыт): три радио — Off / Standard / Advanced + пояснения; **настройка блокируется, пока VPN подключён** (нельзя менять на лету) — защита от случайного выстрела в ногу.
- Честная коммуникация о trade-off: на странице advanced-kill-switch прямо предупреждают — после смены пароля/обновления Windows/логина через Microsoft-аккаунт без интернета не войти; **настоятельно советуют создать локальный офлайн-аккаунт**. Это эталон объяснения последствий строгого режима.
- Kill switch доступен на всех планах, включая free.
- Gizmodo restart test (2026): Standard **утекает** после ребута; Advanced — проходит.

Источники:
- https://protonvpn.com/support/advanced-kill-switch
- https://protonvpn.com/support/what-is-kill-switch?utm_source=chatgpt.com
- https://gizmodo.com/best-vpn/kill-switch
- https://deepwiki.com/ProtonVPN/proton-vpn-gtk-app/5.2-feature-settings

### 1.4 PIA — Classic/Standard/Advanced + automation

- Три режима: **Off / Standard** (блок только при неожиданном обрыве) / **Advanced** (без VPN нет интернета вообще, блокирует даже до запуска приложения; переживает ребут).
- Плюс **application-level kill switch**: убивает выбранные приложения (торрент-клиент) при обрыве, остальное продолжает работать — для тех, кому система целиком резать не надо.
- **Automation rules**: автоподключение/отключение по типу сети (дома выкл, публичный Wi-Fi вкл) — снижает человеческий фактор.
- Ревьюеры подчёркивают: включать Advanced надо осознанно («если интернет "сломался" — это фича, а не баг»).
- Gizmodo restart test: Standard **утекает** при ребуте (фоновые приложения успевают стукнуться до подключения); Advanced — проходит.

Источники:
- https://vpncentral.com/private-internet-access-vpn-review-customizable-private-and-open-source/
- https://gizmodo.com/best-vpn/nordvpn-vs-pia
- https://vpnalert.com/guides/private-internet-access-kill-switch/
- https://www.passwordgeeks.com/pia-review.html

### 1.5 Windscribe — Firewall: Automatic / Manual / Always-On + «fail closed» риторика

- Термин **Firewall**, а не kill switch. Аргументация: kill switch реактивен (режет после того как заметил обрыв — в зазоре пакеты уходят), firewall **проактивен** — трафик вне туннеля запрещён по умолчанию (fail closed).
- Три режима: **Automatic** (вкл при подключении, снимается при ручном выходе из клиента), **Manual** (ручной тумблер), **Always-On** (без VPN нет интернета, переживает краш/выход/ребут).
- У них есть инструкция «как проверить kill switch»: quick test (обрыв → refresh what's-my-IP) и **reboot test** — pattern, который sora могла бы встроить в UI.
- Настройка «Allow LAN traffic if firewall is active» — явный тумблер для локальной сети при активном firewall (важный UX-детейл: строгий режим не должен молча ломать принтеры/Chromecast).
- Блог-статья «VPN Kill Switch: What It Is… and Why a Firewall Is Better» — образец объяснения для пользователя «зачем это нужно».

Источники:
- https://windscribe.com/blog/vpn-kill-switch/
- https://windscribe.com/knowledge-base/articles/how-to-use-windscribe-with-bittorrent-classic
- http://activatesecurity.com/blog/is-windscribe-a-good-vpn/

### 1.6 AdGuard VPN — Android-паттерн + сценарий «публичный Wi-Fi»

- Android: kill switch = системные Always-on VPN + Block connections without VPN (ведут пользователя в системные настройки по шагам: Settings → Kill Switch → Open settings → включить оба тумблера).
- Объяснение «зачем»: привязка к сценарию — «публичный Wi-Fi в кафе/метро/аэропорту; если VPN упал — данные уйдут мошенникам». Плюс **Auto-protection**: автоподключение на незнакомых сетях (iOS/Android).
- Совместимость с split-tunneling: исключённые приложения продолжают работать даже с включённым kill switch — это явно документировано и настроено в UI, а не молчаливое поведение.

Источники:
- https://adguard.com/en/blog/adguard-vpn-for-android-official-release.html
- https://adguard-vpn.com/kb/adguard-vpn-for-android/overview/
- https://adguard-vpn.com/kb/general/why-adguard-vpn/

### 1.7 Предупреждения при отключении (cross-vendor)

- **VPN Unlimited**: при попытке подключиться к P2P-серверу с выключенным kill switch — **модальный warning** с предложением включить; если отказался — явный дисклеймер «мы не отвечаем за утечки». Паттерн: контекстное предупреждение в момент риска, а не только в настройках.
- **ExpressVPN (Android)**: отдельно документируют разницу между их in-app Internet Kill Switch (только при неожиданном обрыве, не ломает split-tunnel и LAN) и системным Always-on (блокирует и ручное отключение). Два слоя объяснены на одной странице.
- **Rtings (апрель 2025)**: независимое тестирование показывает — почти все kill switch'и проваливают reboot-тест, если не персистентны на уровне firewall/OS. Вывод для UX: нельзя обещать «защита», если режим не переживает ребут; честность в подписи режима — обязательна.

Источники:
- https://www.vpnunlimited.com/blog/kill-switch-september-update-on-windows
- https://www.expressvpn.com/support/troubleshooting/android-block-connections-without-vpn
- https://www.rtings.com/vpn/learn/research/killswitch-leak

## 2. Что sora должен перенять и почему

### P0 (high)

1. **Три уровня вместо bool: Off / Standard / Strict (Always-on).**
   Текущий bool — это по сути Standard. Добавить Strict: nftables/WFP-правила, которые держат блокировку без туннеля, переживают краш приложения и перезагрузку. Это консенсус лучших: Proton Advanced, PIA Advanced, Windscribe Always-On, Mullvad Lockdown, IVPN always-on firewall. Без strict-уровня sora проигрывает по главному security-тесту (reboot test у Gizmodo/Rtings).
   Эффект: **high** — доверие и паритет с топом.

2. **Персистентность strict-режима через ребут (desktop).**
   WFP persistent rules (Windows) / nftables через сервис (Linux, уже есть sora-core как служба — задел готов). Proton/PIA/Windscribe все это делают; Rtings прямо показывает, что без этого kill switch — маркетинг.
   Эффект: **high**.

3. **Предупреждение при отключении/выключении.**
   - При ручном disconnect с включённым Standard: тост/баннер «соединение больше не защищено» (стандарт индустрии).
   - При попытке выключить kill switch или выбрать Off: confirm-dialog с объяснением риска (паттерн VPN Unlimited). Сейчас выключение — один тап без последствий в UI.
   Эффект: **high** — дешево, закрывает «oops, I forgot» сценарий, который Windscribe называет главной причиной утечек.

4. **Явный UI-статус блокировки.**
   Когда strict-режим активен и VPN отключён, главный экран должен показывать не просто «Disconnected», а «Blocked: no traffic allowed (strict kill switch)» — иначе пользователь решит, что «интернет сломался» (жалоба, которую PIA заранее отрабатывает в доках). Отдельное визуальное состояние: иконка замка, красный/янтарный бейдж.
   Эффект: **high** — поддержка и понимание фичи.

### P1 (medium)

5. **Объяснение «зачем» в одну строку у каждого уровня.**
   Формат Proton: подпись под радио-кнопкой — что блокируется, переживает ли ребут, что сломается (captive portal!). Обязательно упомянуть: strict ломает captive-portal на публичном Wi-Fi (Gizmodo) и вход в Windows через MS-аккаунт (Proton) — честность как у Proton с их советом про локальный аккаунт.
   Эффект: **medium** — снижает страх перед strict и число обращений в поддержку.

6. **Тумблер «разрешить LAN при активном firewall» (Windscribe-паттерн).**
   Strict не должен молча убивать принтеры, NAS, Chromecast. Отдельная опция, по умолчанию выкл.
   Эффект: **medium**.

7. **Встроенный «проверь свой kill switch» (Windscribe-паттерн).**
   Кнопка в настройках: quick test (рвём туннель → проверяем IP через API) + инструкция reboot test. У sora уже есть встроенный браузер и диагностика — задел есть. Превращает абстрактную фичу в проверяемый факт.
   Эффект: **medium** — дифференциатор, почти никто не встраивает в клиент.

8. **Взаимодействие со split-tunneling — явное, а не молчаливое.**
   Как у AdGuard/ExpressVPN: документировать и показывать в UI, что происходит с исключёнными приложениями при срабатывании kill switch (блокируются vs продолжают напрямую). Сейчас у sora это не определено в UX.
   Эффект: **medium**.

### P2 (low-medium)

9. **Android: вести в системные Always-on + Block connections without VPN** (Mullvad/AdGuard-паттерн) — актуально когда появится Android-клиент. In-app кнопка «Открыть системные настройки» с пошаговой подсказкой.
   Эффект: **medium** (low до выхода Android).

10. **Термин «Firewall» как опция нейминга** (Windscribe/IVPN). «Kill switch» пугает новичков; «Firewall: Automatic / Always-on» понятнее. Можно A/B: основной термин Firewall, в скобках kill switch.
    Эффект: **low** — косметика, но влияет на восприятие.

11. **Automation по типу сети** (PIA): strict на публичном Wi-Fi, standard/off дома. Ложится на запланированные сетевые профили (P1 roadmap) — kill switch как часть профиля.
    Эффект: **medium**, но после сетевых профилей.

12. **App-level kill switch** (Nord/PIA): «закрыть выбранные приложения при обрыве» — ниша торрент-пользователей. Для sora избыточно при наличии strict, отложить.
    Эффект: **low**.

## 3. Сводная таблица уровней (предложение для sora)

| Уровень | Поведение | Переживает ребут | Ручной disconnect |
|---|---|---|---|
| Off | без защиты | — | интернет открыт |
| Standard (default on?) | блок при случайном обрыве | нет | интернет открыт |
| Strict / Lockdown | блок всего без туннеля | да | интернет заблокирован |

По умолчанию: Mullvad делает kill switch неотключаемым; для sora как showcase-качества — рассмотреть **Standard включённым по умолчанию** (сейчас выключен). Strict — всегда opt-in с confirm-dialog.

## 4. Открытые вопросы

- Где хранить strict-правила на Linux, чтобы пережить ребут: в юните systemd sora-core или в nftables persistent set — решение за core-командой.
- Captive-portal UX при strict: нужен «режим портала» (временное окно 3–5 минут без VPN для авторизации) — ни у кого из исследованных нет хорошего решения, шанс выделиться (пересекается с идеей §3.6 competitor-analysis).
