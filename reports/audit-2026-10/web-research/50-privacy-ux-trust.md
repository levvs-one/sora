# Веб-ресёрч #50: Лучшие privacy-UX — коммуникация no-logs и доверия

Дата: 2026-10-19. Источники: browser.search (5 запросов), репозитории sora/sora-legacy (только чтение).

Ключевая оговорка: Mullvad/IVPN/Proton — провайдеры с серверами, sora — клиент. Sora не может «аудитировать серверы» и не ведёт no-logs-политику для трафика: логи зависят от провайдера подписки. Но privacy-UX приёмы переносятся: коммуникация «что мы не делаем», прозрачность кода и сборок, аудиты клиента, честность про границы ответственности.

## 1. Что нашёл

### 1.1. Mullvad — «никогда не собирай то, что не нужно»
- Главная коммуникация — принцип data minimization, а не список фич: «Most of Mullvad's privacy design comes down to one decision: never collect what you don't need. No email, no name, no payment details tied to your traffic… Connection logs simply aren't written in the first place» (mullvadvpnofficial.com).
- Анонимные аккаунты: при регистрации генерируется случайный 16-значный номер, никаких персональных данных.
- Аудиты — как программа, а не бейдж: регулярные с 2018, Cure53 (инфраструктура), X41 D-Sec (приложения), NCC Group (Android), Assured (серверы/веб); 18 аудитов к 2026, отчёты публикуются целиком, а не «summary on request». https://gizmodo.com/best-vpn/mullvad-vpn , https://www.pcworld.com/article/395038/mullvad-vpn-review-2.html
- «Доказательство боем»: рейд шведской полиции в апреле 2023 — отдать было нечего, потому что данных нет. Используется как главный аргумент доверия, а не маркетинг.
- Открытость о проблемах: в мае и сентябре 2026 публично раскрыли утечки в Android-приложении (связывание сессий при смене серверов) и способ исправления. https://www.bestproductranking.com/en/rankings/best-vpn-services.html

### 1.2. IVPN — «сигналы доверия» и прозрачность процесса
- Отдельная страница «Signals of Trustworthiness» (https://www.ivpn.net/trust/): 8 конкретных пунктов (мультихоп, anonymous payments с 2010, open-source серверы, vulnerability disclosure, warrant canary, публичная информация о команде, privacy guides).
- Аудиты анонсируются ДО проведения: пост «Annual security audit scheduled for 2026» — 8-й ежегодный аудит Cure53, публикуются scope и сроки. Публикация самих отчётов с найденными issues (6-й аудит: 2 low + 2 weaknesses — публикация слабостей трактуется как сигнал доверия). https://franklinetech.com/best-anonymous-vpn-services/
- Warrant canary — раз в месяц: «IVPN releases a warrant canary once a month… states that IVPN did not receive any searches, seizures, or warrants». https://www.vpnmentor.com/reviews/ivpn/
- Политика приватности простым языком (оценка privacy 100% у Cloudwards): объясняет не «мы не логируем», а КАК удаётся избегать типичных ловушек (что именно не собирается: real IP, DNS-запросы, timestamps сессий). https://www.cloudwards.net/ivpn-review/
- Открытое раскрытие инцидентов: взлом BTCPay-сервера (август 2026) и DNS-утечка в iOS-приложении при ротации WireGuard-ключей (февраль 2025) — опубликованы в блоге с деталями. https://www.ivpn.net/en/blog/
- Публичная персона: владелец Nicholas Pestell, 100% собственности, раскрыты на сайте. F-Droid-дистрибуция Android-приложения (без зависимости от Google).

### 1.3. Proton VPN — transparency report + аудит живых серверов
- Transparency report с 2017: таблица по годам — все запросы (orders) и все отклонены (2019: 1/1, 2022: 80/80, 2025: 59/59, 2026: 47/47). https://protonvpn.com/blog/transparency-report
- Аудиты no-logs: Securitum ежегодно с 2022, 2025 — с инспекцией ЖИВЫХ серверов в Цюрихе (случайный выбор, проверка logging settings на production-машинах), а не чтением политики. SOC 2 Type II — июль 2025. Отчёты скачиваются без аккаунта и email. https://gizmodo.com/best-vpn/proton-vpn , https://vpnsites.com/best-no-log-vpns/
- Все приложения open source на GitHub; суд в 2019 (climate activist case) — отдать было нечего (VPN ничего не хранил).
- Warrant canary Proton считает бессмысленным в Швейцарии (закон требует уведомления цели запроса) — честная позиция вместо галочки.

### 1.4. Тренды в коммуникации доверия (2025–2026)
- **Canary → transparency reports.** NordVPN (октябрь 2026) официально переходит с warrant canary на ежемесячные transparency reports: «canary operates on a principle of omission… lacks detail». https://nordvpn.com/es/blog/nordvpn-introduces-transparency-reports/
- **Privacy dashboard в приложении.** Surfshark iOS v5.0.0 (2026): главный экран-хаб — статус защиты, блокировка трекеров, VPN, rotating IP — всё в одном виде, «protection status at a glance». https://www.webpronews.com/surfsharks-ios-v5-0-0-overhaul-puts-every-security-tool-on-one-screen/
- **Телеметрия = явный opt-in.** ExpressVPN/PIA: диагностические данные (краш-репорты, connection diagnostics) — опционально, анонимизированы, отключаемо; PIA прямо пишет в политике, что opt-in делится anonymized connection events. https://travelsecurely.com/best-vpn-for-privacy/ , https://www.2-spyware.com/review-private-internet-access.html
- **«Evidence, not promises» как методология.** Независимые ранкинги (vpncomparison.org, bestproductranking.com, октябрь 2026) проверяют: публичность отчёта, дату, scope аудита, court-tested, open source, раскрытие команды. Один аудит 2019 года ≠ программа аудитов. Только 27 из 377 VPN имеют все три: no-logs policy + независимый аудит + «connection IPs not stored» (7%). http://dev.to/vpnradarlab/no-logs-claims-vs-independent-audits-what-377-vpn-privacy-policies-say-243a

### 1.5. Что у sora уже есть сегодня (прочтено в репо)
- Конфиг ядрам через stdin, секреты в AES-256-GCM, маскирование секретов в журнале, автообновление с SHA256-проверкой (приложение+служба), HTTPS-only подписки, SSRF-защита.
- В UI/текстах НЕТ явной коммуникации приватности: в коде `app/lib` нет ни одного упоминания «no-logs», «telemetry» или privacy-утверждений; SECURITY.md говорит только о репортах уязвимостей. То есть вся реальная privacy-инженерия существует, но пользователю не сообщается — доверие не конвертируется.

## 2. Что sora должен перенять

1. **Экран «Приватность» / Trust Center в приложении (новый раздел в настройках или About).** Структура по образцу ivpn.net/trust: что приложение хранит локально (список данных: подписки в зашифрованном хранилище, правила, логи — всё на устройстве), что НИКОГДА не покидает устройство (секреты подписок, конфиги ядер), что sora не контролирует (логи на стороне серверов провайдера — честный дисклеймер в духе Proton про canary). Каждый пункт — проверяемый факт, а не лозунг. Эффект: **high** — единственные конкуренты-клиенты (v2rayNG/NekoBox/Hiddify) вообще ничего такого не делают; это станет дифференциатором.
2. **Программа публичных аудитов клиента с анонсами и публикацией отчётов (как IVPN/Mullvad).** Заказывать у Cure53/X41/Assured по частям: Go-core (привилегированная служба!), Flutter-приложение, механизм обновлений. Публиковать scope заранее, отчёты — целиком в репозитории + ссылка из Trust Center. Один аудит ≠ программа; нужна регулярность (ежегодно). Эффект: **high** — главный сигнал доверия для open-source клиента; у конкурентов-клиентов аудитов нет вообще.
3. **Reproducible builds + отображение provenance в UI.** Open source сам по себе слаб: «Open code lets outsiders check what the app does» (bestproductranking). Усилить: воспроизводимые сборки (SLSA/provenance через GitHub Actions), в About — commit hash, подпись minisign, ссылка «проверить сборку». Эффект: **high** — для клиента, который пользователь ставит с root-правами, это критично.
4. **«Verified update» как видимый trust-сигнал.** Sora уже проверяет SHA256 обновлений — показать это: в диалоге обновления бейдж «подпись проверена (minisign)», в истории уведомлений запись о результате проверки. Сейчас проверка невидима → доверие не работает. Эффект: **medium** — дёшево (S), усиливает существующую фичу.
5. **Честный дисклеймер про провайдера + защита от небезопасных подписок.** В UI добавления подписки: предупреждение, если URL не HTTPS (сейчас загрузка просто запрещена молча?); пометка «Sora не видит и не контролирует логи серверов — проверяйте политику вашего провайдера». Это честность в стиле Mullvad («nothing to hand over») — парадоксально повышает доверие. Эффект: **medium**.
6. **Privacy dashboard в духе Surfshark, но клиентский:** статус защиты одним взглядом — kill switch активен, DNS-утечек нет (результат последней проверки DNS Leak из F3), секреты замаскированы в логах, обновлений безопасности нет. То есть «панель уверенности», а не маркетинговая. Эффект: **medium** — переиспользует уже запланированный DNS-менеджер и kill switch.
7. **Телеметрия/краш-репорты — только явный opt-in (или их отсутствие как фича).** Сейчас, судя по коду, телеметрии нет — это надо заявить вслух: пункт в Trust Center «Sora не отправляет аналитику и краш-репорты никуда». Если краш-репорты появятся — по образцу PIA/ExpressVPN: opt-in, анонимно, отключаемо, с показом содержимого перед отправкой. Эффект: **medium** — «нулевая телеметрия» как позиционирование против коммерческих VPN.
8. **Публичный security advisory процесс (в духе IVPN/Mullvad).** SECURITY.md уже есть; добавить: публикацию advisory после исправлений, changelog безопасности в приложении (экран «Что нового» с security-бейджами). Раскрытие собственных проблем — сигнал открытости, а не слабости (см. Mullvad 2026, IVPN BTCPay). Эффект: **low/medium** — процессный, не продуктовый.
9. **Warrant canary / transparency — только если появится центральный сервис.** Для чистого клиента canary бессмыслен (как у Proton в Швейцарии — честно объяснить, почему его нет, лучше, чем делать вид). Если появятся: каталог расширений (подписанный team catalog, уже в планах F10) и сервер обновлений — для них публиковать transparency/canary. Эффект: **low** сейчас, вырастет с F10.
10. **Публичная команда/владение (в духе IVPN).** Для open-source клиента: подписанные релизы, прозрачное владение репозиторием, DCO/прозрачные коммиты. Эффект: **low** — гигиена.

## 3. Приоритет для roadmap
- **Сейчас (S/M):** Trust Center в приложении (#1), видимый «verified update» (#4), заявление о нулевой телеметрии (#7), дисклеймер про провайдера (#5).
- **Ближайшие месяцы:** reproducible builds + provenance в UI (#3), запуск программы аудитов (#2, начать с Go-core как самого привилегированного компонента).
- **Позже:** privacy dashboard поверх DNS-менеджера и kill switch (#6), advisory-процесс (#8), canary для каталога расширений (#9).

## 4. Чего НЕ делать
- Не копировать no-logs-риторику провайдеров («мы не логируем») — sora не оператор серверов, такое заявление было бы ложью. Говорить о том, что контролирует клиент.
- Не вешать бейджи аудитов без регулярности: «один аудит в 2026» через год станет антисигналом (см. методологию vpncomparison.org).
- Не делать warrant canary ради галочки там, где он юридически бессмыслен (урок Proton).
