# Shadowsocks: состояние экосистемы 2026

Дата: 2026-10-19. Веб-исследование, источники 2025–2026.

## 1. Что нашёл

### 1.1. SIP022 (Shadowsocks-2022) — зрелый стандарт, но adoption неравномерный

- SIP022 — единственная рекомендованная версия протокола. Главные отличия от старого AEAD: BLAKE3 вместо HKDF-SHA1 для вывода ключей, обязательная защита от реплеев (timestamp ±30 сек + пул соли, хранение 60 сек, запрет Bloom-фильтров), payload chunk до 64 КБ вместо 16 КБ, session-based модель UDP с `client_session_id` (сессии переживают смену IP клиента), закрыты «серьёзные уязвимости» старого AEAD-дизайна и probing-специфика поведения TCP.
  - https://shadowsocks.org/doc/sip022.html
  - https://xtls.github.io/en/config/inbounds/shadowsocks.html (совместимость Xray)
- Рекомендуемые шифры в 2026 (единодушие у Xray docs, Outline docs, shadowsocks.org): **2022-blake3-aes-128-gcm**, **2022-blake3-aes-256-gcm**, **2022-blake3-chacha20-poly1305**. Ключ — base64-PSK фиксированной длины (16/32/32 байта), генерится `openssl rand -base64 N`, не пароль как раньше.
- Stream-шифры (`aes-256-cfb`, `rc4-md5` и т.п.) официально deprecated; outline-ss-server их запрещает целиком.

### 1.2. Лучшие AEAD-шифры: AES vs ChaCha — ответ зависит от CPU

- На x86/x64 с AES-NI: AES-128-GCM самый быстрый (десктопы, типичные VPS). AES-256-GCM — «gold standard» для соответствия/аудита, почти та же скорость с AES-NI.
- На устройствах без AES-NI (старые ARM, бюджетные телефоны, IoT): ChaCha20-Poly1305 быстрее и предсказуем по батарее.
- Практическое правило индустрии (2026): предлагать оба, давать выбирать endpoint'у; дефолт — AES-256-GCM для десктопа, ChaCha20-Poly1305 для мобильных.
- Для SS-2022: `2022-blake3-aes-128-gcm` — дефолт для скорости, `2022-blake3-aes-256-gcm` — дефолт для «максимума безопасности» у провайдеров, `2022-blake3-chacha20-poly1305` — для мобильных клиентов без AES-NI.
  - https://nzbget.com/documentation/choosing-cipher/ (бенчмарки)
  - https://www.privateproxyguide.com/using-openvpn-with-custom-cipher-suites-for-extra-security/

### 1.3. Детект SS-трафика: 2021 → 2026, картина для sora мрачная и ясная

- GFW двухступенчато детектит SS с 2020 (IMC 2020, gfw.report): пассивная эвристика по энтропии и длинам первых пакетов → активное зондирование (replay-пробы, random-пробы, модифицированные реплеи/«partitioning oracle»).
  - https://gfw.report/talks/imc20/en/
- С ноября 2021 у GFW есть **чисто пассивный** реалтайм-детектор fully-encrypted трафика (USENIX Security 2023): вместо «что это за трафик» — эвристики-исключения (фингерпринты известных протоколов, доля set-битов, число/позиция печатаемых ASCII). Что не исключено — блокируется. Приемлемый collateral damage ~0.6%. Это убило идею «выглядеть как ничто».
  - https://par.nsf.gov/biblio/10431830-how-great-firewall-china-detects-blocks-fully-encrypted-traffic
- GFW делает replay-атаки с задержкой до недель (записывает legitimate handshake, реплеит позже). gfw.report прямо советует: replay-фильтр должен помнить nonce **после рестарта** сервера и иметь временную защиту как у VMess. SS-2022 решает это штатно (timestamp ±30с + соль 60 сек).
  - https://gfw.report/blog/ss_advise/en/
- Россия 2024–2025: чистый SS (включая обфусцированные плагинами) детектится по данным практиков с показателем ~95% за часы (dev.to, октябрь 2025); остаются рабочими VLESS+TLS+XHTTP/REALITY (детект <5%). SS жив только как транспорт под обёрткой или в странах без ML-DPI.
  - https://dev.to/__2ea5fee000c/vless-protocol-how-it-bypasses-censorship-in-russia-and-why-it-works-4o9d
  - https://onlineshieldhub.com/stealth-vpn-protocols-bypass-dpi/ (AI-DPI 2026: энтропийный анализ, JA4, active probing)
- Вывод для архитектуры sora: «голый» SS — транспорт для слабого DPI; под сильным DPI SS надо оборачивать (TLS-обёртка, uTLS-фингерпринт браузера) либо предпочитать VLESS/REALITY. Mimicry > pure encryption.

### 1.4. Outline / outline-ss-server: живой, но консервативный

- Outline (Jigsaw) — по-прежнему главный массовый SS-клиент/сервер для «своего VPN». Активен: Android-клиент 1.21.5 (обновление в Play — 26.08.2025), гайды по деплою 2026 года, outline-ss-server поддерживает мульти-юзеров на одном порту и Prometheus-мониторинг.
  - https://play.google.com/store/apps/details?id=org.outline.android.client&hl=en-gb&gl=lu
  - https://pkg.go.dev/github.com/Jigsaw-code/outline-ss-server
  - https://blog.flokinet.is/2026/03/06/outline-vpn-one-method-to-bypass-internet-censorship/
- Ограничения Outline: только классические AEAD-шифры (chacha20-ietf-poly1305 дефолт), SIP022 не принят как стандарт Outline-ключей; ss:// URI у Outline — классический формат. Outline не конкурент sora как «прокси-клиент вообще», но эталон UX «свой сервер в один клик» и прямой конкурент фичи «развёртывание своего сервера» (roadmap P2).

### 1.5. shadowsocks-rust: активен, reference-де-факто для SS-2022

- shadowsocks-rust поддерживает SIP004 AEAD, SIP022 AEAD-2022, SIP002/SIP003(u) плагины, защиту от реплеев, manager API, ACL. Активная разработка (версии 1.21+ в 2025–2026, crate в топе downloads).
  - https://lib.rs/crates/shadowsocks-rust
- shadowsocks-crypto: v1-aead дефолт; v2 (SS-2022) — opt-in feature flag (blake3 + aes-gcm/chacha20poly1305), v2-extra — chacha8 reduced-round.
  - https://deepwiki.com/shadowsocks/shadowsocks-crypto

## 2. Что sora должен перенять

1. **Приоритет SS-2022 шифров при импорте/генерации конфигов (high).** При импорте `ss://` распознавать и рекомендовать `2022-blake3-*`; при создании/рекомендации серверов (one-click deploy, будущий) генерировать PSK через `openssl rand -base64`, а не пароли. Xray/sing-box/mihomo все поддерживают SS-2022 — sora может просто выставлять приоритет, движки уже умеют.
2. **Дефолтный шифр по платформе (medium).** На десктопе — `2022-blake3-aes-256-gcm` (или aes-128 для скорости), на Android — `2022-blake3-chacha20-poly1305` (мобильные CPU часто без AES-NI, батарея). Это бесплатная производительность без потери безопасности.
3. **Предупреждение «голый SS под сильным DPI» (medium).** Stealth-оценка конфигурации (roadmap §3 №13): если SS без TLS-обёртки/обфускации, а регион = RU/CN/IR (по ASN), показывать предупреждение и предлагать обёрнутый транспорт. Исследования 2021–2026 дают для этого фактическую базу.
4. **Replay-устойчивость по gfw.report для своих серверных сценариев (low/medium).** Если/когда sora будет разворачивать SS-серверы (one-click deploy), сервер обязан помнить nonce после рестарта и использовать timestamp-окно как VMess — SS-2022 это делает штатно, просто не отключать и не ставить классический AEAD.
5. **Опыт Outline для one-click deploy (medium).** Outline Manager — эталон UX «VPS → ключ за 5 минут» (Docker-образ, менеджмент-ключи, revoke). sora P2 «развёртывание мультипротокольного сервера» должен копировать этот флоу, но сразу на SS-2022 + VLESS/REALITY/Hysteria2 стеке — это будет объективно сильнее Outline.
6. **ss:// URI совместимость (low).** Убедиться, что импорт `ss://` корректно парсит base64-PSK для 2022-шифров (там нет `method:password`, а `method:base64key`, некоторые клиенты это ломают).

## 3. Оценка эффекта

| Действие | Эффект | Почему |
|---|---|---|
| Приоритет SS-2022 при импорте/генерации | high | Закрывает известные CVE-класса уязвимости старого AEAD и probing-векторы; стандарт 2026 |
| Дефолт шифра по платформе (AES десктоп / ChaCha мобайл) | medium | Заметный выигрыш скорости/батареи, нулевой риск |
| Предупреждение «голый SS» + предложение обёртки | medium | Честность продукта: SS детектится ~95% в RU; снижает ложное чувство безопасности |
| Replay-устойчивость в one-click deploy | medium | gfw.report: replay через недели после рестарта — реальная атака, SS-2022 закрывает |
| UX one-click deploy как у Outline, но мультипротокол | medium | Главный дифференциатор против Outline; уже в P2 |
| Парсинг ss:// с base64-PSK 2022 | low | Гигиена совместимости |

Ключевой стратегический вывод: **Shadowsocks в 2026 — это «транспорт второго эшелона»**: надёжен там, где DPI слабый, но под сильным DPI проигрывает VLESS+TLS/XHTTP/REALITY. Sora правильно держит SS в стеке, но не должна позиционировать его как anti-DPI решение; ценность sora — в автовыборе движка/транспорта под конкретный DPI (roadmap: умный выбор сервера+движка, авто-тюнинг фрагментации), а не в самом SS.
