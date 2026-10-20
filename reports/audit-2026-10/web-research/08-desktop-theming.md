# Web Research #8: Системы тем в десктоп-приложениях

Дата: 2026-10-19. Источники 2025–2026 приоритетно.

## Что есть у sora сегодня (референс для сравнения)

`app/lib/src/design/theme.dart`: кастомный `Palette` (ThemeExtension) со светлой/тёмной гаммой — монохромный Apple-style (`ink` как primary, `danger`, спектр свечения подключения), `buildTheme(Brightness)`, M3. Темы переключаются светлая/тёмная/системная. Чего **нет**: кастомных акцентных цветов, динамических цветов ОС, high-contrast режима, Mica/vibrancy, пользовательских/импортируемых тем, анимации перехода при смене темы.

## Находки

### 1. Dynamic color / системные акценты во Flutter-десктопе
- Пакет `dynamic_system_colors` (форк заброшенного `dynamic_color` от material-foundation): строит `ColorScheme` из цветов ОС. Windows: системный акцент; macOS: app accent color; Linux: GTK `@theme_selected_bg_color`; Android S+: цвет обоев. Есть гармонизация кастомных цветов под системный primary (`harmonizeWith`).
  - https://pub.dev/packages/dynamic_system_colors
- Пакет `system_theme` — читает системный акцент и умеет слушать его изменение (Windows/macOS слушают, Linux — GTK 3+).
  - https://pub.dev/packages/system_theme
- Ubuntu/Canonical `gtk`+`yaru` пакеты автоматически подхватывают тёмный режим и акценты GTK-окружения.
- Вывод: опция «Акцент: системный» — стандарт ожидания на Windows 11, где пользователи привыкают к единому акцентному цвету (Settings → Personalization → Colors). Системный акцент в Windows применяется и в светлой, и в тёмной теме.

### 2. Telegram Desktop — эталон пользовательских тем
- Редактор тем прямо в приложении (Chat Settings → три точки → Create new theme): палитра цветов, выбор HEX/RGB, предпросмотр, сохранение с именем.
- Темы — shareable-файлы `.tdesktop-theme` (на macOS `.palette`): можно отправлять в чат и применять кликом, существуют каналы с тысячами тем (`@TheThemes`, `@Desktop_Themes`) — экосистема, а не фича.
- Урок: не просто «переключатель light/dark», а **селектор тем с предпросмотром + экспорт/импорт файла**; сообщество делает остальное.
  - https://www.guidingtech.com/how-to-create-a-custom-theme-in-telegram-for-desktop-and-mobile/
  - https://telegrama-wiki.com/how-to-change-the-theme-in-telegram-on-your-computer-and-phone/

### 3. VS Code — самая продуманная модель
- Раздельные настройки «предпочитаемая светлая / тёмная / high-contrast тёмная / high-contrast светлая тема».
- `window.autoDetectColorScheme` — автопереключение темы за сменой схемы ОС; `window.autoDetectHighContrast` — автопереключение на high-contrast тему, когда ОС использует контрастную тему.
- `workbench.colorCustomizations` — точечные переопределения цветов поверх любой темы (живой предпросмотр), в т.ч. `[ИмяТемы]`-скоупы.
- Урок для sora: 4-уровневая модель (light/dark × обычный/HC) + настройка «следовать ОС» + точечные override'ы — это то, чего пользователи про-утилит ждут. В sora уже есть `Palette` как ThemeExtension — это ровно тот слой, куда ложится `colorCustomizations`-подобный override.
  - https://code.visualstudio.com/docs/configure/themes
  - https://code.visualstudio.com/api/extension-guides/color-theme

### 4. Per-platform нюансы
- **Windows 11 Mica/Acrylic:** пакет `flutter_acrylic` (Mica = непрозрачный материал, учитывающий обои; Acrylic = полупрозрачный blur) — но пакет не обновлялся ~2.5 года, риски зависимости. Альтернатива: native titlebar + Mica даёт эффект «приложения из коробки» почти бесплатно. Важно: у sora кастомный титлбар (если он есть) — Mica работает только с нативным окном или требует переключения через `scaffoldBackgroundColor: Colors.transparent`.
  - https://pub.dev/packages/flutter_acrylic/versions/1.1.4
  - https://windowsforum.com/windows-news.4/per-element-acrylic-in-windows-11-fine-grained-blur-for-fluent-ui.388242/
- **Linux GTK:** тёмная тема детектится через `org.freedesktop.appearance color-scheme` (портал xdg-desktop-portal); пакет `system_theme` читает GTK-акцент. GNOME 42+ не имеет глобального «акцента» кроме `@theme_selected_bg_color` — у динамических тем на Linux охват ограничен.
- **macOS (перспектива):** нативный accent color + NSAppearance vibrancy; Flutter покрывает через `system_theme`/`dynamic_system_colors`.

### 5. Тёмная тема: лучшие практики 2025–2026
- `ThemeMode.system` + `theme`/`darkTheme` — стандарт; `ColorScheme.fromSeed(seed)` даёт 45 ролей M3 из одного seed-цвета; при желании точности — `DynamicSchemeVariant.fidelity` (seed остаётся узнаваемым, а не вымывается).
- `MediaQuery.highContrastOf(context)` / `disableAnimationsOf` — Flutter сам отдаёт флаги доступности ОС; sora уже уважает disable-animations через `MotionScope`.
- Анимация перехода при смене темы: `AnimatedTheme`/`enableThemeAnimation` — переход — это «моргание», а не «щёлк» (пример shadcn Flutter).
  - https://blog.redlinesoft.net/posts/flutter-dark-mode-theming/
  - https://shadcnstudio.com/blog/how-to-use-shadcn-with-flutter/

### 6. High contrast
- ОС-уровень: Windows «Contrast themes», macOS «Increase contrast», GNOME «High contrast». VS Code автоматически подхватывает (`autoDetectHighContrast`) и подменяет тему. Flutter экспонирует `MediaQuery.highContrastOf` — sora может автоматически переключаться на отдельную `Palette` с усиленными контрастами, а не просто инвертировать существующую тёмную.

## Что sora должен перенять (по приоритету)

1. **Акцент: Системный / Синий / Фиолетовый / Оранжевый / Моно (5–6 вариантов) + «следовать Windows/macOS/GTK».** *(эффект: high)* — Пользователи Windows 11 ожидают акцентной персонализации; сейчас sora монохромный, выглядит «проигрывателем», а не флагманом. Реализация: поле `accent` в `Palette` + `ColorScheme.fromSeed`-производные, гармонизация `spectrum`/`danger` под акцент. Пакет `system_theme` для чтения системного акцента. Аккуратно: brand-цвета статуса (зелёный/красный/спектр) не трогать — акцент только для интерактива (выбор, прогресс, переключатели).
2. **High-contrast палитры + `autoDetectHighContrast` (по VS Code).** *(эффект: medium-high)* — Вопроса доступности в roadmap нет, а для утилиты, живущей в трее, это вопрос доверия. Четыре палитры (light/dark/HC-light/HC-dark) + автоследование `MediaQuery.highContrastOf`. Технически дёшево: тот же `buildTheme(Brightness)`, новый аргумент.
3. **Тема-селектор в стиле Telegram: 4–6 встроенных тем, предпросмотр, экспорт/импорт `.sora-theme` (JSON палитры).** *(эффект: medium)* — Расширяет «extensions»-визию: сообщество начнёт делиться темами, как в Telegram. Импорт файла темы = почти тот же UX, что deep-link `sora://` (уже есть инфра обработки ссылок). Риск: палитра у sora из 12 цветов — формат темы тривиальный.
4. **Анимированный переход темы (`AnimatedTheme`, ~200ms).** *(эффект: low-medium)* — Дёшево, заметно в восприятии качества; сочетается с существующим `Motion`-respect (уважать disable-animations).
5. **Mica на Windows 11 + прозрачный фон у нативных всплывающих элементов.** *(эффект: medium)* — «Родное» ощущение приложения из коробки. Но: `flutter_acrylic` заброшен — либо форкнуть/заменить минимальным FFI, либо ждать официального API. Не брать как зависимость в текущем виде. Поставить в P2 с проверкой свежести экосистемы.
6. **Точечные override'ы цветов (уровень VS Code `colorCustomizations`).** *(эффект: low)* — P2/P3; нужен сначала селектор тем из п.3.

## Чего НЕ делать

- Не уходить в полный Material You с обоями: на десктопе Windows/Linux источник «динамического» цвета — акцент ОС, а не обои; копировать Android-поведение бессмысленно.
- Не ломать монохромную фирменность насильно: акцент должен быть опцией (по умолчанию — текущий монохромный стиль, «Sora Mono»), а не дефолтом.
- Не тащить `flutter_acrylic` в зависимости без аудита — пакет старый; Mica можно включить минимальным платформенным кодом.
