# Web research #20 — Приватный crash-reporting (без слежки)

Дата: 2026-10-19. Тема: как собирать краш-репорты в privacy-first VPN-клиенте. Текущее состояние sora: crash-reporting отсутствует (в репозитории только строки восстановления сессии после падения; телеметрии/аналитики нет — чистая база).

## Что нашёл

### 1. IVPN — эталон для VPN-клиентов
Политика приватности IVPN прямо описывает crash logs:
- мобильные приложения: **анонимизированные данные о краше по умолчанию** (состояние приложения, ОС, устройство — без PII), можно выключить в настройках;
- десктоп: репорт уходит **только после ручного подтверждения пользователя**;
- отправляются на **собственный сервер IVPN, без третьих лиц и облачных вендоров**.
https://www.ivpn.net/en/privacy-mobile-app/

### 2. Mullvad — «Report a problem» из приложения
- Встроенная форма в Settings → Report a problem; email указывать не обязательно (нужен только если хочешь ответ);
- **логи анонимизируются перед отправкой**, отправляются: redacted-логи, версия приложения, ОС; IP-адреса, номера аккаунтов, чувствительные пути и прочее PII — не отправляются;
- прямое указание: «воздержитесь от ввода персональных данных» в комментарии.
https://mullvad.net/en/help/how-report-bug-or-vulnerability
https://mullvad.net/en/help/privacy-policy

### 3. Mozilla Firefox — per-crash opt-in
- После падения — диалог Crash Reporter: чекбокс «Tell Mozilla about this crash», кнопка **Details…** (показ содержимого репорта), опционально «Include the address of the page I was on» (явное отдельное согласие на URL);
- **краш-репорты не отправляются автоматически**, потому что могут содержать PII; список несданных — `about:crashes`;
- телеметрия отделена от крашей (отдельный переключатель, daily ping только с non-personal данными).
https://support.mozilla.org/en-US/kb/mozillacrashreporter/revision/248057

### 4. Sentry: scrubbing на границе (beforeSend)
Официальная рекомендация Sentry — чистить события **в SDK до отправки**, чтобы чувствительные данные не покидали устройство:
- `beforeSend` / `beforeSendTransaction` хуки (есть в sentry_flutter, sentry-go, sentry-native);
- `send_default_pii=false` по умолчанию (не включать);
- зоны риска: stack-locals (значения переменных в стеке — отключать), breadcrumbs (лог-строки, SQL, query-строки в HTTP), user-контекст, HTTP query/fragment.
https://docs.sentry.io/platforms/flutter/data-management/advanced-datascrubbing/
https://docs.sentry.io/platforms/go/guides/http/data-management/sensitive-data/

### 5. Self-hosted backend: GlitchTip вместо Sentry
- Полноценный self-hosted Sentry: BSL-лицензия, **40+ контейнеров, 8–16 ГБ RAM** (Postgres, Redis, Kafka, ClickHouse, Snuba) — явный перебор для маленькой команды.
- **GlitchTip**: MIT, реализует тот же ingest-протокол Sentry (те же SDK/DSN, zero code changes), **4 контейнера, ~512 МБ RAM**, runs on $6 VPS; source maps/symbolication — совместимо со стандартным `sentry-cli`; активно развивается (GlitchTip 6 вышел в фев 2026). Минусы: нет session replay и полного tracing (sora их не нужно), UI беднее.
https://dev.to/selfhostingsh/glitchtip-vs-sentry-206o
https://devtoolpicks.com/blog/sentry-vs-honeybadger-vs-glitchtip-indie-hackers-2026

### 6. Breakpad/Crashpad и «локальная символизация»
- Breakpad/Crashpad: запись compact **minidump** на клиенте, **символизация на сервере** (symbol dumper → symbol files → processor). Symbolicator в Sentry-стеке делает то же самое по загруженным debug-файлам.
- Для Go-ядра sora (sora-core) Breakpad не нужен: panics ловятся через `recover()` в супервизоре + `debug.Stack()`, нативный стек идёт из runtime.
- Для Flutter: sentry_flutter уже встраивает sentry-native (Crashpad backend опционален) для нативных крашей Android; в sentry-go хватит BeforeSend-хука.
https://docs.sentry.io/platforms/native/configuration/backends/crashpad
https://chromium.googlesource.com/breakpad/breakpad/+/d091e5103f3a9305b56d5aa9ef18e18306d32786/docs/getting_started_with_breakpad.md

### 7. Signal — полюс «ноль телеметрии»
Signal не собирает краши автоматически вообще; баг-репорты — только **ручные debug-логи, которые пользователь сам прикрепляет**. Это цена доверия в их модели. Для sora это не цель, но крайность полезно знать: Mullvad/IVPN показывают жизнеспособную середину.
https://www.radar-chat.app/signal.html (no analytics SDKs)
https://github-wiki-see.page/m/Scratch-net/Signal-Android/wiki/Submitting-useful-bug-reports

## Что sora должен перенять и почему

### A. Модель согласия: opt-in + per-crash prompt (эффект: HIGH)
Комбинировать Firefox и IVPN:
1. **Мастер-тоггл в настройках, по умолчанию ВЫКЛ.** Текст согласия прямо перечисляет, что именно уходит (версия, ОС, очищенный стек) и что никогда не уходит (IP, аккаунты, URL подписок, пути).
2. **Очередь несданных репортов локально** (pending queue). При следующем запуске — диалог «Отправить отчёт о падении?» с кнопкой **«Показать содержимое»** (как Details у Mozilla) и опциональным полем комментария (с пометкой «виден разработчикам, не пишите персональные данные» — как у Mullvad).
3. Десктоп: всегда ручное подтверждение (IVPN-модель). Android-будущее: то же самое — ручное, либо тоггл с дефолтом OFF.

Почему: для VPN-клиента отправка чего-либо «по умолчанию» — репутационный риск; per-crash prompt + прозрачное содержимое — это то, что Mullvad/IVPN/Firefox делают стандартом доверия.

### B. Минимизация данных и scrubbing на клиенте (эффект: HIGH)
Жёсткий контракт на содержимое репорта:
- Разрешено: версия sora, билд/коммит, ОС+архитектура, тип исключения, **санитизированный** стек-трейс, uptime до падения, версия ядра.
- Запрещено: IP (свои и серверов), URL подписок, секреты/токены, имена пользователей в путях (замена на `<user>`), фрагменты конфигов ядер, breadcrumbs с логами запросов.
- Реализация: переиспользовать **существующее маскирование секретов в журнале sora** (уже есть в кодовой базе) + `beforeSend`-аналогичные хуки в Dart (`SentryFlutter` options.beforeSend) и Go (sentry-go `BeforeSend`), `sendDefaultPii=false`, stack-locals выключены.
- Комментарии пользователя отсылать только после ручного ввода (не автоприкреплять).

Почему: scrubbing до отправки — официальный гайдлайн Sentry; повторное использование имеющегося маскировщика sora — дёшево и консистентно.

### C. Backend: self-hosted GlitchTip, никаких SaaS (эффект: HIGH)
- Поднять GlitchTip на своём VPS (4 контейнера, ~512 МБ RAM, MIT). DSN свой, данные — на своей инфраструктуре (как IVPN: «no third-party vendors»).
- SDK: `sentry_flutter` в app + `sentry-go` в sora-core — без переписывания при смене бэкенда (DSN-своп совместим).
- Retention policy: краши хранятся ограниченно (напр. 90 дней), затем удаляются — зафиксировать в privacy policy.
- Не поднимать полный self-hosted Sentry — 40+ контейнеров несоразмерно задаче.

### D. «Приватная» загрузка символов: server-side symbolication (эффект: MEDIUM)
- Не встраивать символы в клиент (увеличит размер и раскрывает структуру). Загружать debug/symbol-файлы (Go build IDs, Dart symbol files) на свой GlitchTip/Symbolicator при релизе CI — стек символизируется на сервере.
- Breakpad/Crashpad как отдельная зависимость **не нужны**: Go — recover()+debug.Stack в супервизоре; Flutter — sentry-native из sentry_flutter покрывает нативные краши Android.

### E. In-app «Report a problem» по образцу Mullvad (эффект: MEDIUM)
- Пункт в Settings → Support: форма с комментарием пользователя + checkbox «прикрепить последний краш-репорт» (анонимизированный); при отправке показывать, что именно уходит; email — опционально.
- Переиспользовать уже существующий механизм экспорта журнала (8 форматов) — но с тем же scrubbing-контрактом из B.

### F. Документация в privacy policy (эффект: MEDIUM)
- Отдельный раздел, как у IVPN/Mullvad: что собирается, что никогда не собирается, где хранится (свой сервер), срок хранения, как выключить. У sora позиционирование «приватность как бренд» — это must-have, а не nice-to-have.

## Оценка эффекта по пунктам

| Пункт | Эффект | Сложность (грубо) |
|---|---|---|
| A. Opt-in + per-crash prompt | HIGH (доверие) | S — очередь + диалог |
| B. Минимизация + scrubbing в beforeSend | HIGH (риск PII) | S — reuse маскировщика |
| C. GlitchTip на своём VPS | HIGH (независимость от SaaS) | S — docker compose |
| D. Server-side symbolication | MEDIUM (качество стектрейсов) | S — CI-загрузка символов |
| E. In-app «Report a problem» | MEDIUM (поддержка) | S |
| F. Раздел privacy policy | MEDIUM (юридическое доверие) | XS |

Ключевой вывод: индустрии-стандарт для privacy-first продуктов (IVPN десктоп, Mullvad, Firefox) — **не автоматическая отправка**, а **явное согласие на конкретный репорт + показ содержимого + свой сервер без третьих лиц**. Sentry-стек для этого не нужен целиком: достаточно sentry_flutter/sentry-go + лёгкий GlitchTip + клиентский scrubbing поверх уже имеющегося маскировщика секретов sora.
