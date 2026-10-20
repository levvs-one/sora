# Онбординг топовых коммерческих VPN: что перенять Sora

Дата: 2026-10-19. 5 поисковых запросов (browser.search), приоритет источникам 2025–2026.

Текущее состояние Sora (read-only проверка репо): есть только `app/lib/src/ui/tour.dart` — пассивный 5-шаговый спотлайт-тур по UI на showcaseview: `tourAdd` («добавь ссылку подписки провайдера»), `tourServer`, `tourConnect`, `tourMode`, `tourSettings`, с кнопками Next/Back/Skip. Гайдид-визарда первого запуска, welcome-экрана, объяснения ценности и in-context запроса разрешений — нет.

## 1. Что делают конкуренты

### Proton VPN
- Welcome-экран: «Sign in» или **«Continue as guest»** — без аккаунта, без персональных данных, сразу к ценности. Home: открытый замок + «You are unprotected» + текущая страна, карточка «Fastest free server» и кнопка Connect под картой. После подключения: зелёный замок, «Protected», имя сервера, кнопка Disconnect. Статус читается мгновенно, учить нечему.
- На Windows после установки — **быстрый тур** по основам (guided tour, обзор Digital Trends). Но продвинутые фичи (Secure Core, нагрузка серверов по цветным кружкам) остаются непонятны — обзорщик гуглил.
- Разрешение Android («Connection request» → OK) всплывает при первом коннекте **без предварительного in-app объяснения** — слабое место.
- Источники: https://insiderbits.com/educational-apps/vpn-app-2/ · https://www.aivanet.com/2021/04/how-to-download-and-install-protonvpn-on-android/ · https://robots.net/tech/how-to-use-proton-vpn/ · https://www.aivanet.com/2024/08/proton-vpn-review-a-scientific-approach-to-security/ · https://www.engadget.com/cybersecurity/vpn/proton-vpn-review-2025-a-nonprofit-service-with-premium-performance-153046073.html

### Mullvad
- Радикальное упрощение входа: никаких email/имён — **генерируется случайный 16-значный номер аккаунта**, это и есть логин. Анонимная регистрация = нулевое трение.
- Приложение — маленькое однопанельное окно (как и IVPN), тура/онбординга **нет вообще**: дизайн самодокументирован, одна кнопка подключения.
- Источники: https://www.vpn.com/vpn/mullvad/ · https://gizmodo.com/best-vpn/mullvad-vpn

### IVPN
- Создание аккаунта минимально (автогенерация Account ID, email не нужен) → логин по ID → **слайдер «Disconnected» → подключение к быстрейшему серверу одним движением**.
- Home намеренно скудный: кнопка Connect + Multi-hop. Приложение спроектировано «работать в фоне, а не чтобы в нём сидеть».
- В UI акцентирована **Network Protection** — автоподключение на недоверенных Wi-Fi (trusted networks) — ключевая ценность вынесена на первый план, а не закопана в настройках.
- Источники: https://vpnoverview.com/vpn-reviews/ivpn/?ref_id=vpn_reviews_ivpn · https://www.wizcase.com/reviews/ivpn/ · https://www.top10vpn.com/reviews/ivpn/ · https://www.cloudwards.net/ivpn-review/

### AdGuard VPN
- Вход — через AdGuard-аккаунт (email или Google/Apple/FB SSO). Главная: большая кнопка Connect + список локаций **с пингом каждой** — латентность показана до выбора, решение «куда коннектиться» принимается на месте.
- Ценность коммуницируется оффером: **бесплатные 3 ГБ/мес**. Официальная формула: «Install the app. Log in and click Connect. All done!» — весь онбординг в 3 глагола.
- Источники: https://adguard-vpn.com/kb/adguard-vpn-for-ios/overview/ · https://adguard-vpn.com/en/what-is-vpn.html?source=ag_products_page

### Windscribe
- **Самый низкий порог входа**: «Get Started» → 2 ГБ/мес **без аккаунта**, аккаунт можно «забрать» позже ради 10 ГБ. Ценность до регистрации.
- Первый запуск: вопрос «уже есть аккаунт?» → игривая «human check»-капча (персоналити как часть онбординга) → при первом запуске ещё и открывается браузер со страницей «установка завершена» и предложением поставить расширение.
- Главная — большая кнопка-питание = «подключить к лучшей локации». На TV — Lazy Login (авторизация через другое устройство, не вводить пароль пультом).
- Источники: https://windscribe.com/blog/how-to-windscribe/ · https://www.cloudwards.net/how-to-use-windscribe-vpn/ · https://thebestvpn.com/reviews/windscribe-vpn/ · https://windscribe.com/blog/how-to-use-vpn/

### AmneziaVPN (релевантнее всех: open-source, self-hosted)
- Первый запуск: кнопка **«Let's get started»** / «➕». Для Amnezia Free: + → «VPN by Amnezia» → выбрать регион → Connect — 3 тапа до ценности.
- Self-hosted визард задаёт **вопрос о цели**: «разблокировать конкретные сайты или весь интернет» → уровень контроля в регионе (High/Low → автовыбор AmneziaWG vs WireGuard) → автодеплой на VPS с прогрессом (2–5 мин). Персонализация одним вопросом → умные дефолты.
- Источники: https://docs.amnezia.org/documentation/instructions/connect-amfree/ · https://hostkey.com/documentation/marketplace/security/amnezia/ · https://nda.news/virtual-private-network-st_2899/news/i-built-my-own-vpn-server-and-this-is-what-i-learned-sn_2576445/

## 2. Кросс-индустриальные паттерны онбординга (2025–2026)

Консенсус источников: просить разрешения **в контексте, с объяснением выгоды, в момент нужды** — не на первом запуске; 3–5 экранов максимум, одна идея на экран, прогресс-индикатор, Skip всегда виден; ценность до регистрации; интерактивные туториалы вместо пассивных слайдов; персистентный чеклист вместо попапа; один вопрос персонализации → мгновенный фидбек.
- Источники: https://www.protobrief.com/blog/app-onboarding-best-practices/ · https://www.designstudiouiux.com/blog/mobile-app-onboarding-best-practices/ · https://www.goodbarber.com/blog/mobile-app-onboarding-best-practices-to-drive-users-to-value-faster-a1612/ · https://www.zigpoll.com/content/what-are-some-effective-strategies-a-ux-designer-can-use-to-improve-user-onboarding-in-a-mobile-app-to-reduce-dropoff-rates · https://imprasit.substack.com/p/app-onboarding-best-practices-how

## 3. Что перенять Sora (по приоритету)

1. **Визард первого запуска «Начать» (паттерн Amnezia «Let's get started»)** — 3 шага, всё скипабельно: (а) один вопрос о цели — «Разблокировать сайты» / «Весь трафик через VPN» / «Обход блокировок» → ставит routing-пресет (у Sora пресеты уже есть); (б) добавление подписки — вставить ссылку / QR / файл; (в) кнопка «Подключить» с пре-чекетом разрешений. Текущий пассивный тур не ведёт к активации; визард ведёт. Эффект: **high**.

2. **Permission priming перед системным диалогом** — экран «Сейчас система спросит разрешение на VPN-подключение — нажми OK, иначе Sora не сможет работать» (Android «Connection request»; Windows — UAC/установка службы). Никто из конкурентов этого не делает хорошо — это дифференциатор, а дроп на системном диалоге — известная дыра воронки. Эффект: **high**.

3. **Персистентный чеклист «Первые шаги» вместо/в дополнение к туру** — на home в empty-state: [ ] добавил подписку, [ ] подключился впервые, [ ] включил kill switch, [ ] попробовал speedtest. Интерактивно, закрывается, возвращается из настроек. Паттерн из imprasit/goodbarber: чеклист продолжает помогать после онбординга, в отличие от одноразового попапа. Эффект: **high**.

4. **Предложить kill switch сразу после первого успешного подключения** (паттерн Proton/IVPN/Windscribe: kill switch — фича первого экрана, а не глубина настроек) — «Включить защиту от утечек?» с объяснением одной строкой. У Sora kill switch есть, но закопан. Эффект: **medium**.

5. **Язык статуса как у Proton** — «Вы не защищены / Защищены» крупно на home вместо нейтрального «Отключено/Подключено». Эмоциональная рамка ценности; дёшево, переводится в l10n. Эффект: **medium**.

6. **Пинг/скорость на экране выбора сервера до подключения** (паттерн AdGuard: пинг у каждой локации) — у Sora автовыбор по задержке есть в ядре, но в UI выбора сервера пользователь этого не видит. Показать измеренную задержку/нагрузку в списке серверов. Эффект: **medium**.

7. **«Гостевой» режим знакомства без подписки** (паттерн Windscribe 2 ГБ / Proton guest): у Sora нет своей инфраструктуры, но можно дать «демо-подписку» (локальный пример + zapret-режим без сервера) чтобы потыкать UI до добавления своей подписки. Эффект: **medium**.

8. **Вопрос о цели как у Amnezia** — уже покрыт п.1(а); отдельно: ответ «обход блокировок в моей стране» может включать zapret/фрагментацию автоматически. Эффект: **medium** (часть п.1).

9. **Оставить существующий тур, но запускать контекстно** (не на первом экране скопом): подсказка про режимы — при первом переключении режима; про правила — при первом открытии. Плюс «повторить тур» в настройках. Эффект: **low**.

## 4. Чего НЕ копировать

- Обязательный аккаунт до ценности (AdGuard) — у Sora BYO-подписки, аккаунт не нужен в принципе; это преимущество, его подчёркивать.
- Длинные продуктовые туры про продвинутые фичи на первом запуске (ошибка Proton: Secure Core/цвета нагрузки остались непоняты) — продвинутое только контекстно.
- Капча-персоналити Windscribe — чужой тон, Sora про надёжность/прозрачность.
