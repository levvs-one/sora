# Обновления uTLS-фингерпринтов 2025–2026 (веб-исследование #26)

Дата: 2026-10-19. Источники — веб (min 4 запроса, приоритет 2025–2026) + read-only просмотр ~/workspace/bug-hunt/sora и sora-legacy.

## Что нашёл

### 1. uTLS догнал Chrome 155; HelloChrome_Auto обновлён
- Коммит uTLS `6ebdceb` (06.10.2026) добавил `HelloChrome_155`, сверенный с реальным Chrome, и сделал его `HelloChrome_Auto` — https://github.com/XTLS/Xray-core/issues/7131
- Отпечатки JA4: Xray 26.10.10 с `chrome` → `t13d1516h2_8daaf6152771_d8a2da3f94cd`; uTLS 6ebdceb → `t13d1517h2_8daaf6152771_cb7bf5808d99`, идентично реальному Google Chrome 155 (Linux). Отличаются только рандомизированные значения (GREASE, ключи, ECH payload, порядок расширений).
- Веха фингерпринтов: Chrome 131+ — X25519MLKEM768 (post-quantum hybrid key share, ~90%+ трафика Chrome к 2026), Chrome 120+ — ECH/GREASE ECH, Chrome 100+ — ALPS/application_settings + compress_certificate.
  - https://blog.crawlex.net/blog/browser-clienthello-catalog/
  - https://www.qntonsol.com/learn/try-post-quantum-tls-today-openssl-browsers-cloudflare.html

### 2. Старые фингерпринты детектятся DPI (Россия, ТСПУ)
- По issue XTLS/Xray-core#7131 (октябрь 2026): в России текущий `chrome`-фингерпринт (Chrome 133) «похоже, детектируется и блокируется ТСПУ».
- Подтверждает контекст: ТСПУ (Россия) делает TLS SNI-инспекцию, fingerprinting по ClientHello/QUIC Initial, активный пробинг; Cloudflare-отчёт об ECH-блокинге измерен ещё в марте 2025 — https://www.criticalinfralab.net/wp-content/uploads/2026/10/TSPU-and-You_WEB_2026-09.pdf
- Вывод для клиентов: устаревший фингерпринт — это не «старый, но рабочий», а активная причина блокировки в жёсткой цензуре.

### 3. CVE в uTLS — мелкие расхождения с Chrome детектируются
- CVE-2026-27017 (опубл. 19.02.2026, фикс в uTLS 1.8.1): Chrome-parrot в uTLS 1.6.0–1.8.0 при GREASE ECH случайно выбирал ChaCha20 для ECH при AES в outer ClientHello — комбинация, невозможная в настоящем Chrome, 50% соединений — https://www.tenable.com/cve/CVE-2026-27017
- CVE-2026-26995: отсутствие padding-расширения для Chrome 120 (фикс в uTLS 1.8.2) — https://vulert.com/vuln-db/fingerprint-vulnerability-in-utls-from-missing-padding-extension-for-chrome-120-in-github-com-refrac-
- Вывод: DPI учится ловить не только «старый фингерпринт», но и «почти правильный» — любая деталь (padding, GREASE, порядок расширений) становится вектором детекции. Ручное «подкручивание» фингерпринта опасно; безопаснее точный паритет с реальным браузером.

### 4. Randomized fingerprints — хуже, чем точная имитация
- Консенсус детекторщиков 2025–2026: случайные/рандомные TLS-фингерпринты в реальной популяции браузеров не существуют и делают клиента *более* детектируемым, а не менее; JA4 специально проектировали устойчивым к рандомизации — https://justbrowser.app/blog/ja4-tls-fingerprint-antidetect-browser-cross-product
- uTLS `HelloRandomizedALPN`/`HelloRandomizedNoALPN` и xray-опции `random`/`randomized` существуют, но это трюк «не засветиться дважды», а не способ стать незаметным. Для обхода цензуры правильная стратегия — точное совпадение с популярным браузером (Chrome auto), а не рандом.

### 5. ECH + фингерпринт — связка
- Chrome 120+ отправляет GREASE ECH по умолчанию; ECH скрывает внутренний SNI. uTLS поддерживает ECH (в т.ч. через `BoringGREASEECH`), но только свежие версии без багов выше.
- sing-box уже умеет `tls.ech` (enabled/config/query_server_name) + `tls.utls` (fingerprint) в outbound — https://sing-box.sagernet.org/configuration/shared/tls/
- Осторожно: Cloudflare-специфичные ECH-блокировки ТСПУ измерены (март 2025), ECH не панацея и должен быть опцией, а не дефолтом.

### 6. Как сейчас устроено в sora
- sora не использует uTLS напрямую (нет прямого импорта в go.mod core) — фингерпринты делегированы движкам: `core/engine/xray/render.go` проставляет `"fingerprint": "chrome"` (дефолт) в realitySettings/tlsSettings Xray; sing-box/mihomo рендерятся аналогично через их нативные опции.
- Значит актуальность фингерпринтов в sora = актуальность версий Xray-core / sing-box / mihomo в зависимостях + какие значения fingerprint прокидываются в конфиги.

## Что sora должен перенять и почему

1. **Держать движки (Xray-core, sing-box, mihomo) на свежих релизах с новым uTLS.** Критичнее всего Xray-core: пока он пинит старый uTLS, `fingerprint: "chrome"` отправляет Chrome 133 — это та самая конфигурация, которую блокирует ТСПУ (окт. 2026). Причина: актуальность фингерпринта решает, работает ли подключение вообще в жёсткой цензуре. **Эффект: high.**
2. **Прокинуть в UI/конфиги новые фингерпринты движков:** `hellochrome_155`/актуальный auto (Xray), авто-версии Firefox/Safari в uTLS 2025–2026. Причина: пользователь не должен вручную гадать; дефолт обязан быть «свежий Chrome». **Эффект: medium.**
3. **Stealth-check фингерпринта в диагностику** (связано с идеей §3.13 competitor-analysis: «stealth-оценка конфигурации»): клиент сверяет свой отправляемый ClientHello (JA4) с эталоном актуального Chrome и предупреждает, если движок устарел. Причина: превращает невидимую причину блокировки в видимое предупреждение до поездки. **Эффект: medium.**
4. **ECH — как опция, но не как «включи и забудь»:** uTLS ≥1.8.2 (без CVE-2026-27017/26995) + ECH в связке с актуальным Chrome-фингерпринтом; предупредить пользователя о Cloudflare-специфичных ECH-блокировках. Причина: ECH прячет SNI — второй по важности сигнал ТСПУ после самого ClientHello. **Эффект: medium.**
5. **НЕ делать «randomized fingerprint» как фичу антидетекта.** Причина: данные детекторщиков показывают, что рандом хуже точной имитации; можно оставить как fallback-опцию, но не рекламировать. **Эффект: low (избежание вреда).**
6. **Постквантовый key share (X25519MLKEM768) обязателен в фингерпринте.** Причина: его отсутствие при заявленном «современном Chrome» — противоречие, видимое DPI до начала HTTP; 90%+ реального Chrome-трафика его имеет (2026). **Эффект: high** (идёт бесплатно с пунктом 1, но проверить явно).

## Источники (ключевые)
- https://github.com/XTLS/Xray-core/issues/7131 — uTLS HelloChrome_155, блокировка Chrome 133 ТСПУ
- https://blog.crawlex.net/blog/browser-clienthello-catalog/ — каталог ClientHello всех браузеров, ML-KEM, перестановка
- https://www.tenable.com/cve/CVE-2026-27017 — GREASE ECH mismatch в uTLS 1.6.0–1.8.0
- https://vulert.com/vuln-db/fingerprint-vulnerability-in-utls-from-missing-padding-extension-for-chrome-120-in-github-com-refrac- — missing padding Chrome 120
- https://www.criticalinfralab.net/wp-content/uploads/2026/10/TSPU-and-You_WEB_2026-09.pdf — архитектура ТСПУ, ECH-блокировки (март 2025)
- https://justbrowser.app/blog/ja4-tls-fingerprint-antidetect-browser-cross-product — JA4, почему рандомные фингерпринты вредны
- https://www.qntonsol.com/learn/try-post-quantum-tls-today-openssl-browsers-cloudflare.html — статус X25519MLKEM768 по браузерам (окт. 2026)
- https://sing-box.sagernet.org/configuration/shared/tls/ — tls.utls + tls.ech в sing-box
- https://evomi.com/blog/how-tls-fingerprinting-works-ja3-ja4-why-your-requests-get-flagged — uTLS/curl_cffi, согласованность слоёв
