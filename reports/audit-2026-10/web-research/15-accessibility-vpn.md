# Доступность (accessibility) в VPN-клиентах — веб-исследование

Дата: 2026-10-19. Репозитории только читались, код не менялся.

## 1. Что нашёл (по темам, со ссылками)

### 1.1. Статус-кво у VPN-клиентов: доступности почти ни у кого нет
- Прямого аудита доступности популярных VPN-клиентов (Mullvad, Proton, Nord и т.п.) в открытых источниках нет — тема не покрыта обзорами. Единичные упоминания: Mullvad отмечают как «работает хорошо со скринридерами» благодаря минималистичному UI (числовой account ID без email), Proton VPN — «простое переключение одной кнопкой», удобное для TalkBack-шорткатов.
  - https://www.ioupdate.com/2025/09/21/privacy-and-security-when-blind/
- Общий разбор «VPN accessibility for people with disabilities» сводит требования к классике: совместимость со скринридером (метки всех интерактивных элементов), настраиваемый размер шрифта, высококонтрастные схемы, альтернатива звуковым сигналам (текст/визуал), не передавать смысл только цветом.
  - https://www.thevpndirectory.com/knowledge/vpn-accessibility-disabilities.html
- Вывод: ни один конкурент не заявляет доступность как фичу. Это пустое поле — для позиционирования «лучший клиент, включая коммерческие» тут лёгкая дифференциация.

### 1.2. Стандарты: WCAG 2.2 + EN 301 549 + European Accessibility Act
- WCAG 2.2 (W3C Recommendation, с октября 2025 также ISO/IEC 40500:2025) — международный бенчмарк. Ключевое новое для десктопа: минимальный размер цели 24×24 CSS px (2.5.8), доступная аутентификация, видимый фокус.
  - https://userway.org/compliance/en/
- EN 301 549 — европейский стандарт именно для non-web software (глава 11 — десктопные приложения), даёт презумпцию соответствия EAA. V4.1.1 (опубликована, гармонизация ожидается в 2026) переходит с WCAG 2.1 на WCAG 2.2 AA.
  - https://nda.ie/news/en301549-published
  - https://www.cookiedetox.org/rgaa-wcag-en-301-549-comparatif-normes-accessibilite-2026-en.html
- European Accessibility Act применяется с 28.06.2025 к продуктам/услугам для потребителей в ЕС независимо от юрисдикции разработчика (штрафы в отдельных странах до €500k, Германия). Прямо B2B/бесплатное open-source ПО — серая зона, но для «лучшего клиента» игнорировать стандарт глупо: крупные заказчики и госсектор всё чаще требуют accessibility statements от вендоров в цепочке.
  - https://www.audioeye.com/guides/eaa-compliance/
  - https://www.testmuai.com/blog/prepare-for-eu-accessibility-act-2025/

### 1.3. Flutter: что умеет из коробки (2025–2026)
- **Semantics** — дерево для скринридеров: label/hint/role (button), value/checked для кастомных контролов, `MergeSemantics` для группировки, `ExcludeSemantics` для декоративного, `SemanticsService.announce()` для динамических событий (смена статуса!). Семантические метки должны локализоваться вместе с UI-строками. Отладка — `showSemanticsDebugger`, вкладка Accessibility в DevTools.
  - https://www.miquido.com/blog/flutter-accessibility/
  - https://blog.redlinesoft.net/posts/flutter-accessibility-a11y/
- **Keyboard navigation / focus**: на десктопе обязательны Tab-traversal, видимый фокус-индикатор, логичный порядок. `FocusTraversalGroup` + `FocusTraversalOrder`/`OrderedTraversalPolicy` для явного порядка, `FocusableActionDetector` для кастомных контролов. Flutter 3.38 (ноябрь 2025) заметно улучшил focus management.
  - https://docs.flutter.dev/ui/adaptive-responsive/input
  - https://blog.redlinesoft.net/posts/flutter-tab-traversal-focus-management/
- **High contrast**: `MediaQuery.highContrastOf(context)` позволяет подменять тему (насыщенность/контраст) при системной настройке. Отдельный high-contrast вариант палитры — стандартная практика.
  - https://blog.redlinesoft.net/posts/flutter-accessibility-a11y/
- **Text scaling**: Flutter уважает системный масштаб шрифта по умолчанию; типичная ошибка — жёстко зажимать масштаб (clamp) «ради дизайна». Для слабовидящих критично не ломать.
  - https://www.scien.cx/2024/10/19/improving-accessibility-in-flutter-apps-a-comprehensive-guide/
- **Автоматизированные a11y-тесты**: встроенный Accessibility Guideline API (`testWidgets` + `meetsGuideline`): `androidTapTargetGuideline` (48×48), `iOSTapTargetGuideline` (44×44), `labeledTapTargetGuideline`, `textContrastGuideline` (WCAG AA). Запускаются в CI, ловят регрессии.
  - https://docs.flutter.dev/ui/accessibility/accessibility-testing
  - https://dcm.dev/blog/2025/06/30/accessibility-flutter-practical-tips-tools-code-youll-actually-use/
- Пакет `axe_flutter` (Deque) сканирует widget tree на WCAG-нарушения; `flutter_accessibility` — рантайм-реакция на системные настройки.
  - https://zencopa.com/learn/flutter-plugins-to-simplify-ada-compliance

### 1.4. Как аудитят доступность (методология)
Профессиональный аудит = 4 слоя: автоматическое сканирование (axe/WAVE) → keyboard-only проход всех интерактивных элементов → скринридеры (NVDA+JAWS на Windows, VoiceOver на macOS, TalkBack/Orca для будущих Android/Linux) → визуальные проверки (400% zoom, reflow, отключение цвета, текст-спейсинг). Автоматы ловят лишь часть проблем; скринридер-тест ключевых сценариев (подключить/отключить VPN!) обязателен вручную.
  - https://www.xsibility.com/services/website-accessibility-audit.html
  - https://medium.com/@marketing_58999/how-to-test-website-accessibility-with-a-screen-reader-674a46e285bc

## 2. Текущее состояние sora (read-only осмотр)
- `Semantics` используется точечно (~9 файлов: shell, home, servers, toasts, speedtest, kit, extensions), но **полного аудита покрытия нет** — есть немаркированные иконки-действия.
- **Нет** обработки `MediaQuery.highContrastOf` (поиск пуст) — высококонтрастной темы нет.
- **Нет** явной поддержки text scaling (нет `textScaleFactor`/`textScaler` в коде); неизвестно, ломается ли вёрстка при 200%.
- **Нет** `FocusTraversalGroup`/`FocusTraversalOrder` — порядок Tab не контролируется; есть только разрозненные `autofocus`.
- Хоткеи уже есть (home.dart, kit.dart) — хорошая база для keyboard-first.
- Темы светлая/тёмная есть, но контрастность палитры против WCAG AA (4.5:1 обычный текст / 3:1 крупный) не проверялась.
- 31 язык l10n — семантические метки при аудите нужно будет сразу закладывать локализованными.

## 3. Что sora должен перенять

| # | Мера | Почему | Эффект |
|---|---|---|---|
| 1 | **Семантический аудит + локализованные labels**: все icon-only кнопки и кастомные контролы получают `Semantics(label, button: true)`, статусы — `value`; метки в l10n-arb рядом с UI-строками | Скринридер без этого читает «button» или молчит; у VPN-клиента критический путь — подключить/отключить, выбрать сервер | high |
| 2 | **CI-тесты на Accessibility Guideline API** (`labeledTapTarget`, `androidTapTarget` 48×48, `textContrastGuideline`) на ключевых экранах | Ловит регрессии автоматически; соответствует стандарту «zero slop» — дёшево, один раз написать | high |
| 3 | **Анонс смены состояния VPN**: `SemanticsService.announce()` при connect/disconnect/failover + текстовый (не только звуковой/цветовой) индикатор | Незрячий пользователь не видит трей-иконку; это буквально вопрос «защищён ли я сейчас» | high |
| 4 | **Keyboard-first десктоп**: `FocusTraversalGroup` на главных экранах, видимый focus indicator в обеих темах, все действия доступны с клавиатуры (расширить существующие хоткеи) | sora — десктопный клиент; для моторных нарушений и power-user это базовое ожидание; конкуренты-Qt (Nekoray/v2rayN) получают это бесплатно от тулкита, Flutter — нет | high |
| 5 | **High-contrast тема** через `MediaQuery.highContrastOf` + прогон палитры по WCAG AA 4.5:1/3:1 | Системная настройка у слабовидящих; без неё приложение может стать нечитаемым в принудительном high-contrast режиме ОС | high |
| 6 | **Не передавать смысл только цветом**: статус подключения, задержка серверов (зелёный/жёлтый/красный), иконки — дублировать текстом/формой | Прямое требование WCAG 1.4.1; в VPN-клиенте цветовая кодировка пинга — повсеместно | medium |
| 7 | **Уважать системный text scaling**, проверить вёрстку при 200% (особенно экран серверов, журнал) | Сломаная вёрстка при крупном шрифте = недоступность; проверить дешевле, чем чинить потом | medium |
| 8 | **Hit targets ≥48×48** для трей-меню и мелких иконок (сейчас часть icon-button без явного минимума) | WCAG 2.2 2.5.8 требует минимум 24×24, гайдлайны платформ — 48; моторные нарушения | medium |
| 9 | **Accessibility statement + раздел в документации** (что поддерживается: NVDA/VoiceOver/TalkBack/Orca, хоткеи, high contrast) | Нужно для EAA-позиционирования и enterprise/госзаказчиков; никто из конкурентов этого не публикует | medium |
| 10 | **Опция reduce motion** (отключение анимаций тостов/переходов) | Вестибулярные нарушения, требование WCAG 2.3.3; мелочь, делается флагом | low |

### Почему это стратегически правильно
1. **Пустое поле**: ни один VPN-клиент (включая коммерческих) не заявляет доступность. Sora может стать первым open-source VPN-клиентом с документированным соответствием WCAG 2.2 AA — это и PR, и барьер для подражания.
2. **Дешёвый вход**: пункты 2, 3, 6, 10 — дни работы; пункты 1, 4, 5 — недели. Никаких архитектурных изменений не нужно.
3. **Регуляторный попутный ветер**: EN 301 549 v4.1.1 / EAA делают доступность вопросом соответствия для EU-рынка; раннее внедрение дешевле ретрофита.
4. **Синергия с Android**: когда выйдет мобильный клиент, TalkBack-поддержка из коробки даст фору v2rayNG/NekoBox, где с этим тоже никто не работал.

### Порядок действий (предложение)
1. Неделя 1: пункты 2+3+6 (CI-тесты, анонсы статуса, дублирование цвета текстом).
2. Недели 2–3: пункт 1 (семантический аудит с l10n) + ручной проход NVDA на Windows по сценарию «установить → импортировать подписку → подключиться → отключиться».
3. Недели 3–4: пункты 4+5 (focus traversal, high-contrast тема) + проверка text scaling 200%.
4. Публикация accessibility statement (п. 9) после первых трёх шагов.
