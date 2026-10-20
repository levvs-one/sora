# Web-research #5: Split-tunnel UX у лучших клиентов

Дата: 2026-10-19. Запросов в поиск: 7. Источники приоритетно 2025–2026.

## Контекст sora сегодня

- Маршрутизация есть: правила «сайты/IP/программы → напрямую / через VPN / блок», пресеты (всё через VPN, Россия напрямую и т.п.) — см. `competitor-analysis.md` §0.
- UI выбора приложений уже есть: `app/lib/src/desktop/programs.dart` (Linux: .desktop-файлы через GIO; Windows: `tasklist`; есть список запущенных процессов).
- Контракт правил: `destination` вида `domain:bank.ru`, `203.0.113.0/24`, `process:telegram` (`rules.dart`). Отдельной концепции «инверсного режима» и платформенных ограничений в UI нет.

---

## 1. Что нашёл

### 1.1. Два режима: Exclude и Include (инверсный)

Все лидеры, кроме Mullvad, дают два режима с противоположными дефолтами:

- **Proton VPN** — *Exclude mode* (всё через VPN, кроме выбранного) и *Include mode* (только выбранное через VPN); Windows/Linux GUI/macOS — оба режима, Android — только Include. Есть шорткат Split tunneling прямо на домашнем экране, по ховеру — сводка текущей настройки. Гайд: https://protonvpn.com/support/protonvpn-split-tunneling?ref=news.itsfoss.com
- **PIA** — «Bypass the VPN for specific apps» / «Restrict specific apps to the VPN only»; плюс правило «All Other Apps». Гайд: https://helpdesk.privateinternetaccess.com/hc/en-us/articles/46814646791707-How-to-Use-the-Split-Tunneling-Feature-on-Desktop
- **Windscribe** — *Exclusive* vs *Inclusive*, оба режима на Windows/macOS/Linux/Android; на десктопе сплит ещё и по IP/hostname. https://windscribe.com/blog/split-tunnel-vs-full-tunnel/
- **AdGuard VPN** — *Regular* («VPN везде, кроме исключений») и *Selective* («VPN только для исключений»), для приложений и для сайтов отдельно. https://adguard-vpn.com/kb/adguard-vpn-for-android/overview/
- **IVPN** — include/exclude, рекомендует дефолт «все приложения в VPN» против misconfiguration. https://deepwiki.com/ivpn/android-app/4.4-advanced-features
- **Mullvad — инверсного режима НЕТ, сознательно.** FAQ: «Only tunneling some traffic could inadvertently cause leaks which are hard to detect… err on the side of secure by tunneling all traffic by default». Советуют vanilla WireGuard тем, кто понимает риски. Источник: https://mullvad.net/en/help?ref=retiolus.net&Topic=mullvad-app

**Вывод:** sora умеет правила per-target, но не имеет явного глобального инверсного режима в UI. Это базовая опция у 5 из 6 исследованных — её отсутствие заметно.

### 1.2. Измерения сплита: приложения vs домены vs IP

- **Proton Windows:** приложения (.exe через список + ручной «Add» с файловым диалогом) + IP (v4/v6, CIDR), чекбоксы + иконка корзины, кнопка Apply / Reconnect.
- **PIA Windows:** приложения + IP/домены; обзоры отмечают «изменение применилось без рестарта приложения» — hot-apply. https://gizmodo.com/best-vpn/private-internet-access
- **Windscribe:** десктоп — приложения и IP/hostname; Android — только приложения.
- **AdGuard:** приложения И сайты; сайты — вручную, из встроенного списка сервисов (группирует все поддомены платформы: `youtube.com` + `youtu.be`), из браузера через share. При исключении приложения советуют добавлять и его домены.
- **Mullvad:** только приложения, сайтов нет («no way to exclude specific websites»).
- **Обзор 2026:** https://cyberinsider.com/vpn/best/split-tunneling-vpn/ — стандартный набор: apps + IPs (+CIDR), Standard/Inverse.

**Вывод:** набор sora (domain/IP/process) полный по измерениям. Уникальное, чего нет у sora: бандлы «сервис = все его домены» и подсказка «исключая приложение, добавь и его домены».

### 1.3. UX выбора приложений (пикер)

Общие паттерны у IVPN/Mullvad (Android), Proton (Windows):

- Поиск по списку, иконки приложений.
- Тумблер «Show system apps / системные процессы» (Mullvad, IVPN).
- IVPN Android: сканирует только приложения с INTERNET-permission, делит на обычные/системные, bulk-операции «выбрать всё / снять всё», хранение в зашифрованных преференсах.
- Proton Windows: ручное добавление произвольного .exe через файловый диалог (важно для portable/неинсталлированных).
- PIA: hot-apply правил без перезапуска клиента.

**Вывод:** у sora пикер есть (installed + running), но, судя по коду, без поиска, без системного фильтра/тумблера, без ручного добавления бинарника, неясно hot-apply.

### 1.4. Предупреждения о рисках и «сдвиг safety net»

- **Windscribe** (лучший разбор): 1) DNS-ловушка — у исключённого приложения DNS может всё равно идти через VPN (стриминг получит «не тот» каталог) или, наоборот, локально (ISP видит запросы); 2) наследование исключений дочерними процессами (исключил Steam → игры тоже исключены); 3) активные соединения не перемаршрутизируются — нужен рестарт приложения; 4) kill switch покрывает уже не «весь трафик», а «весь, кроме исключений». https://windscribe.com/blog/split-tunnel-vs-full-tunnel/
- **Mullvad Android:** исключённые приложения ломаются при включённом «Block connections without VPN»; DNS исключённых всё равно идёт через DNS Mullvad.
- **Red Shield VPN** (честный список лимитов Windows): не работают Microsoft Store/UWP-приложения, Java-приложения, некоторые игры; конфликт с другими VPN/антивирусами с собственными split-tunnel драйверами (требуется полное удаление, вплоть до `sc delete` чужого драйвера); приложение, запущенное из другого приложения, наследует его настройку. https://redshieldvpn.xyz/en/help/apps/windows/split_tunneling
- **Mullvad FAQ:** Windows Store apps исключить нельзя вообще.

**Вывод:** никто из лидеров не прячет эти оговорки — у лучших это текст прямо в UI/гайдах. У sora таких предупреждений нет.

### 1.5. DNS-поведение при сплите

- **PIA:** настройка «Set DNS Behavior» — DNS следует split-правилам или всегда идёт через DNS PIA (Windows/Linux).
- **Windscribe:** системный DNS (R.O.B.E.R.T./кастомный) применяется ко всем приложениям, включая исключённые.
- **Mullvad:** DNS исключённых приложений — всё равно через сервер Mullvad, если не переопределить.

**Вывод:** явный переключатель «DNS следует правилам сплита / всегда через туннель» — ожидаемая опция; у sora её нет.

### 1.6. Совместимость с kill switch

- **Proton Windows 4.3.7+:** Split Tunneling + Kill Switch + NetShield работают одновременно (раньше было «выбери два»). https://protonmail.uservoice.com/forums/932836-proton-vpn/suggestions/50522838-offer-split-tunneling-even-with-the-kill-switch-a
- У sora kill switch — nftables/WFP на уровне системы, встаёт до ядра. Конфликта «pick two» быть не должно по архитектуре, но поведение исключений при обрыве туннеля нигде не специфицировано.

### 1.7. Платформенные ограничения (таблица)

| Платформа | Что возможно | Ограничения |
|---|---|---|
| **Android** | Только per-app: `VpnService.Builder.addAllowedApplication` (allowlist) ИЛИ `addDisallowedApplication` (denylist), но не оба сразу; список задаётся до `establish()`, изменение = новое соединение. https://developer.android.com/reference/kotlin/android/net/VpnService.Builder | Нет per-IP/per-domain (подтверждает и матрица Windscribe). Исключённые приложения + системный «Block connections without VPN» = нет сети (предупреждать). Своё приложение надо исключать из маршрутов против петель. |
| **Windows** | Per-app через WFP/драйвер; per-IP через маршруты | Нет нативной per-process абстракции в ОС. Не поддерживаются: UWP/Store-приложения (Mullvad FAQ, Red Shield), Java-приложения, часть игр. Наследование дочерними процессами. Конфликт драйверов с другими VPN/антивирусами — детектить и предупреждать. |
| **Linux** | sing-box умеет `process_name` в route-правилах; ручные методы — cgroups/netns/ip rule | Ядро не маршрутизирует per-process «из коробки»; PIA и Windscribe дают per-app и на Linux, но это их драйверная/пользовательская магия, а не ОС. |
| **macOS** | Per-app есть (Proton добавил в 2026, PIA, Mullvad) | Для sora пока неактуально (нет клиента). |
| **iOS** | Нет, кроме MDM-managed устройств (ограничение Apple). Windscribe сознательно не шиппит через MDM — «asking privacy-conscious users to accept that level of control… is a massive trade-off». https://vpnsherlock.com/best-vpn-ios | Для sora неактуально сейчас, но матрицу возможностей стоит зафиксировать заранее. |

---

## 2. Что sora должен перенять и почему

### HIGH

1. **Явный инверсный режим (Include/Selective) в UI.** У 5 из 6 лидеров есть; Mullvad — единственное исключение по идеологическим причинам, и sora не Mullvad. Реализация: глобальный тумблер режима поверх существующих правил; дефолт — Exclude («всё через VPN»), с явным выбором пользователя.
2. **Предупреждения о рисках прямо в экране сплита.** Короткий блок: «исключённые приложения не защищены; дочерние процессы наследуют правило; после добавления перезапусти приложение; DNS может идти иначе». Это то, за что хвалят Windscribe/Mullvad, и этого нет ни у одного опенсорсного конкурента из анализа — шанс выделиться.
3. **Пикер приложений: поиск + «показывать системные» + ручное добавление бинарника + выбрать всё/снять всё.** Паттерн IVPN/Mullvad/Proton. На Windows ручной .exe-пикер критичен (portable-приложения не в списке установленных).
4. **Android: корректный allowlist/denylist через VpnService.Builder + предупреждение про «Block connections without VPN».** Для будущего Android-клиента (P0-дыра из competitor-analysis) это must-have с первого дня; API позволяет только один из списков — архитектура должна это учитывать заранее.

### MEDIUM

5. **Переключатель поведения DNS при сплите** («DNS следует правилам» vs «всегда через туннель») — как у PIA. У sora уже есть свой DNS и диагностика утечек (dnsleak.go) — логичное продолжение.
6. **Hot-apply правил без перезапуска ядра** — как у PIA. Проверить, умеет ли текущий план/движок; если нет — заложить.
7. **Бандлы «сервис = все домены» + подсказка «добавить домены приложения».** Как у AdGuard: исключая приложение, предлагать добавить его домены одним тапом; встроенный список популярных сервисов с поддоменами.
8. **Спецификация поведения при обрыве туннеля + kill switch.** Зафиксировать и показать в UI: исключённые приложения продолжают работать напрямую (by design), остальное блокируется. Как у Proton 4.3.7+ — «всё сразу, без pick two».
9. **Windows: обработка UWP/Java/наследования + детект конфликтующих драйверов.** Честная матрица «не поддерживается» + предупреждение при установленном стороннем split-tunnel драйвере (паттерн Red Shield).

### LOW

10. **Сводка сплита на главном экране** (ховер/подзаголовок «Split: 3 apps excluded»), как шорткат у Proton. Дешёво, повышает обнаруживаемость фичи.
11. **Документация платформенной матрицы** (таблица из §1.7) в справке приложения — снимает поток «почему не работает» заранее.

---

## 3. Чего НЕ перенимать

- **Позицию Mullvad «нет инверсному режиму».** Это их бренд-философия; для цели «лучший клиент для всех» отсутствие Include-режима — проигрыш Proton/PIA/Windscribe/AdGuard/IVPN.
- **Терминологию AdGuard («Regular/Selective», «Exclusions»).** Обзоры 2026 отмечают, что она путает пользователей; лучше пара Exclude/Include или «Всё через VPN, кроме… / Только выбранное через VPN».
