# REALITY в дикой природе: детект, эволюция, best practices

Дата: 2026-10-19. 5 поисковых запросов + чтение первоисточников (habr, Xray-core #7131, Project X docs, rks.global, dev.to). Плюс read-only проверка репо sora/sora-legacy.

## 1. Что нашёл

### 1.1. Протокольного детекта REALITY нет (апрель–октябрь 2026)
- Консенсус источников: REALITY не имеет собственной сигнатуры. Для неаутентифицированного клиента сервер проксирует соединение на настоящий `dest` — DPI видит байт-в-байт легитимный TLS к реальному домену. Активное зондирование получает настоящий сайт с настоящим сертификатом, зонду нечего зацепить.
  - https://gist.github.com/Piska-Kiska/5eaf0d5470d10198a5e83ab4d7fb1615
  - https://dev.to/sofiisrum/how-vless-reality-made-vpns-unblockable-by-pretending-to-be-google-5hfj
  - Независимый nDPI-тест (Wireshark + nDPI, ~апрель 2026): 5 из 6 коммерческих VPN детектятся за <1.5 с, VLESS+REALITY — NOT DETECTED. https://dev.to/evilork/i-fingerprinted-6-commercial-vpns-in-200ms-with-open-source-dpi-heres-the-wireshark-data-164o
- Обзор «protocol massacre, октябрь 2025» (личный блог, непроверяемо, но согласуется с остальными): OpenVPN 100% детект за 30 с, WireGuard 100%, Shadowsocks 95%, Trojan 90% (убит активным зондированием — отвечает на невалидные запросы отличительно), VMess 80%, VLESS+REALITY <5%. https://dev.to/__2ea5fee000c/vless-protocol-how-it-bypasses-censorship-in-russia-and-why-it-works-4o9d

### 1.2. «Сибирская» волна РКН, июнь 2026 — главный практический кейс
habr.com/ru/articles/1044396/ — реверс алгоритма ограничений РКН (мобильные + домашние провайдеры):
- Цензор смотрит на **тройку**: (а) подсеть/AS сервера («подозрительные» — в т.ч. Selectel, Яндекс.Облако, Cloud.ru, не только зарубежные); (б) SNI; (в) **uTLS-фингерпринт** — «подозрительные»: Chrome, Safari, iOS. **Проходят: Firefox, Android OkHttp, Edge, 360, QQ.**
- Триггер: **>3 параллельных TLS-соединений с одним SNI за 60 с** (задержка между ними <350–400 мс) → заморозка всех соединений на 120 с. Смена фингерпринта после заморозки давала +600 с (позже убрали).
- Воспроизведено на **настоящем Google Chrome** — т.е. это не детект uTLS-библиотеки, а эвристика поведения. Обход: нарушить любое условие цепочки (другой фингерпринт, пустой SNI — ограничение не применялось, другой AS).
- Вывод для клиента: mux (меньше параллельных TLS), выбор фингерпринта и ротация SNI — рабочие контрмеры.

### 1.3. TSPU блочит устаревший uTLS-отпечаток Chrome 133 (октябрь 2026)
XTLS/Xray-core issue #7131 (https://github.com/XTLS/Xray-core/issues/7131):
- Xray-core пинил uTLS с `HelloChrome_133`; тесты в RU (Yota, siberian-check): Chrome 133 → TLS handshake timeout (8426 мс), Chrome 155 → OK (733 мс), Firefox 148 → OK, QQ 11.1 → OK.
- RPRX подтвердил: **TSPU ограничил соединения с отпечатком Chrome 133**. Бамп uTLS до ff1b50f добавил `hellochrome_155` (= настоящий Chrome 155 по JA4: `t13d1517h2_8daaf6152771_cb7bf5808d99`).
- Fangliding уточняет: версии Chrome 133–154 делят один отпечаток (изменён в 133), плюс Electron/Chromium-фреймворки шлют старые отпечатки — «новый» не всегда = «популярный в трафике».
- Вывод: **дефолт `chrome` — самый рискованный выбор в RU прямо сейчас**. sora-legacy ставит именно его по умолчанию (`render.go:269`: `orDefault(o.TLS.Fingerprint, "chrome")`).

### 1.4. Vision flow обязателен
- `xtls-rprx-vision` для VLESS+TCP+REALITY: убирает TLS-in-TLS (сильный прокси-сигнал для DPI: «TLS-сессия, несущая TLS-сессию»), добавляет случайный padding в handshake, включает splice. Без vision — TLS-over-TLS, который РКН уже распознаёт (deepwiki igareck/vpn-configs-for-russia). Документация Project X: https://xtls.github.io/en/config/outbounds/vless.html
- Начиная с новых версий Xray: flow поддерживает кастомный padding/delay и ML-KEM768-верификацию сервера (постквантовая защита от будущей расшифровки ключей клиента).

### 1.5. Best practices: dest, shortId, spiderX, theft-защита
- `dest`: обязательны TLS 1.3 + HTTP/2 + X25519 key exchange; **не Cloudflare** (мешает handshake); желательно крупный домен, доступный из цензурируемой страны (www.amazon.com, www.intel.com, www.microsoft.com, github.com). https://deepwiki.com/xiaowenlaile/reality/8-advanced-topics
- `shortIds`: случайные hex 8–16 символов; пустая строка `""` — только для legacy-совместимости.
- `spiderX`: стартовый путь «паучьего» режима — клиент при неудачной аутентификации ведёт себя как краулер, поддерживая иллюзию легитимного визита.
- Traffic theft: чужой может использовать REALITY-сервер как форвардер к `dest` → защита через `dokodemo-door` + routing rules. https://deepwiki.com/XTLS/Xray-examples/3.3-reality-protocol-implementation

### 1.6. Остаточные векторы (не закрыты протоколом)
- **Статистика сессий**: длинные непрерывные двунаправленные потоки vs короткие bursty визиты — ML-аномалия.
- **IP reputation**: много клиентов на один VPS-IP с SNI «github.com» → триггер ручного/авто зондирования.
- **MITM с гос-CA** на устройстве: расшифровка → внутри виден VLESS (не лечится клиентом).
- rks.global (Runet 2025, июнь 2026): с декабря 2025 TSPU научился идентифицировать VLESS по **косвенным признакам**; цензура смещается от формальных блоков к деградации/нестабильности. https://rks.global/files/research/censorship_review_2025_en.pdf?v=2

## 2. Что sora должен перенять и почему

| # | Мера | Почему | Эффект |
|---|------|--------|--------|
| 1 | **Убрать дефолт `chrome`, добавить выбор/override фингерпринта в UI + авто-fallback.** Сейчас sora-legacy жёстко ставит `chrome` при отсутствии в конфиге (render.go:269) — это самый блочимый вариант в RU (сибирская волна + TSPU-ограничение Chrome 133, issue #7131). Нужно: ручной выбор fp (chrome/firefox/qq/edge/safari/android/ios) поверх подписки, «умный дефолт» по стране (для RU — firefox), авто-перебор fp при TLS-timeout. | Прямое следствие 1.2–1.3; без этого REALITY-конфиги sora будут отваливаться в RU | high |
| 2 | **Трекинг актуальности uTLS-отпечатков в движках.** Chrome меняет отпечаток раз в ~несколько релизов; устаревший пин = детект. Нужен процесс: следить за бампами utls в Xray/sing-box/mihomo, обновлять движки, в UI показывать «возраст» отпечатка. Связка с фичей №13 roadmap (stealth-оценка): показывать JA4 клиента vs актуальный JA4 Chrome. | 1.3: окно между релизом Chrome и бампом utls — период повышенного риска | high |
| 3 | **Детектор «siberian»-заморозки с авто-реакцией.** Паттерн «TCP коннектится, TLS handshake висит/таймаутит» → автоматическая смена фингерпринта и/или SNI (смена SNI сбрасывает контекст цензора), затем повтор. Это конкретизация фичи №3 roadmap (детектор цензуры с упреждающим failover). | 1.2: алгоритм РКН детерминирован и обходится сменой одного параметра | high |
| 4 | **Валидация: REALITY без vision → предупреждение.** Клиент должен помечать конфиги VLESS+REALITY+TCP без `xtls-rprx-vision` как «легко детектится (TLS-in-TLS)» — в UI сервера и в stealth-оценке. | 1.4: РКН распознаёт TLS-over-TLS; vision — дешёвая и обязательная мера | high |
| 5 | **mux по умолчанию для REALITY.** Меньше параллельных TLS-соединений с одним SNI → не срабатывает триггер «>3 за 60 с» сибирского алгоритма. | 1.2 напрямую: параллелизм — третье условие цепочки | medium |
| 6 | **Чек-лист dest для one-click развёртывания сервера** (фича №8 roadmap): TLS 1.3 + H2 + X25519, не Cloudflare/CDN, топовый домен, доступность из страны пользователя; серверный шаблон с защитой от traffic theft (dokodemo-door). Клиентская валидация импортируемых конфигов по тем же правилам. | 1.5: неправильный dest = либо неработающий REALITY, либо кража трафика | medium |
| 7 | **shortId hygiene + spiderX по умолчанию.** Генерировать случайные 8–16 hex shortId (не пустые) в one-click сетапе; spiderX="/" по умолчанию. | 1.5: базовая гигиена, дешево | low |
| 8 | **Ротация SNI / несколько serverNames.** Смена SNI обнуляет счётчик параллельных соединений у цензора; несколько serverNames на сервере дают запасной вариант. | 1.2: SNI — ось, по которой цензор группирует контекст | low |

## 3. Ключевые ссылки
- https://habr.com/ru/articles/1044396/ — реверс «сибирских» ограничений РКН, июнь 2026
- https://github.com/XTLS/Xray-core/issues/7131 — TSPU vs Chrome 133 uTLS, октябрь 2026
- https://xtls.github.io/en/config/outbounds/vless.html — Vision flow, padding, ML-KEM
- https://deepwiki.com/xiaowenlaile/reality/8-advanced-topics — dest/shortId best practices
- https://deepwiki.com/XTLS/Xray-examples/3.3-reality-protocol-implementation — spider mode, theft-защита
- https://rks.global/files/research/censorship_review_2025_en.pdf?v=2 — Runet 2025: VLESS по косвенным признакам с декабря 2025
- https://dev.to/evilork/i-fingerprinted-6-commercial-vpns-in-200ms-with-open-source-dpi-heres-the-wireshark-data-164o — nDPI-тест, REALITY не детектится
