# Web-исследование #34: NaiveProxy и аналоги (Chrome-стек проксирование)

Дата: 2026-10-19. Источников: 6 веб-запросов, приоритет 2025–2026.

## 1. Что нашёл

### 1.1. Состояние проекта klzgrad/naiveproxy — жив и активно поддерживается
- Репозиторий ребейзится под каждый релиз Chromium; на 2026-10 пин `CHROMIUM_VERSION = 154.0.8037.49`. Мастер ребейзится, стабильные релизы — по git-тегам.
- Нативные бинари: Linux (x86/x64/arm/arm64/mips/riscv), Windows (x86/x64/arm64), macOS (x64/arm64), **Android** (APK-плагин для Exclave/husi/NekoBox — экосистема SagerNet), OpenWrt (40+ архитектур).
- Суть: прокси поверх HTTP/2 (или HTTP/3/QUIC) CONNECT на **настоящем сетевом стеке Chromium**: TLS-фингерпринт побайтово = Chrome, порядок H2-фреймов = Chrome. Плюс opt-in padding-протокол (первые 8 чтений/записей стрима), application fronting (сервер прячется за обычным веб-сервером, одинаково отвечает на active probing и на браузер).
- Источники: https://deepwiki.com/klzgrad/naiveproxy/1-overview , https://www.gitplanet.com/project/naiveproxy

### 1.2. Детект: не невидимка, но один из лучших
- **Факт 2026-10**: госзакупка КНР (Suzhou Health Information Center, 14.10.2026) — устройство мониторинга трансграничного VPN-трафика, в списке идентифицируемых протоколов: OpenVPN, WireGuard, Shadowsocks, V2Ray, Trojan **и NaiveProxy**. Коммерческие DPI уже умеют его классифицировать.
  Источник: https://ministryofcyberaffairs.com/news/suzhou-health-authorities-procure-vpn-monitoring-equipment-to-regulate-unauthorized-cross-border-access-f1c9b01f-8164-4d9c-b901-5a9e29c8028d
- Сам автор документирует известные слабости TLS-in-TLS архитектуры: двойной handshake (узнаваемый тайминг), инфляция размеров пакетов, превышение MTU, долгие туннели, поведение RST_STREAM. Честная позиция: «не claim'им идеальную недетектируемость».
  Источник: https://deepwiki.com/klzgrad/naiveproxy (раздел Known Limitations, README 153–161)
- При этом: padding + fronting + настоящий Chrome-стек дают устойчивость к passive fingerprinting (ClientHello не отличить от Chrome) и к active probing (сервер = обычный веб-сайт). В независимых рейтингах anti-censorship resistance — «Very High», рядом с meek. Для Китая-2026 консенсус источников: №1 VLESS-Reality, Hysteria2 как fallback; naive — нишевый, но валидный третий вариант там, где REALITY жгут по поведенческим признакам.
  Источники: https://deepwiki.com/danoctavian/awesome-anti-censorship/2.2-network-tunnels-and-proxies , https://www.throughwire.net/blog/best-protocol-for-china

### 1.3. Ключевое открытие: sing-box УЖЕ умеет naive нативно
- sing-box имеет **нативные inbound и outbound `type: "naive"`**. Outbound использует настоящий Chromium-стек через `cronet-go` (`cronet.NaiveClient`) — тот же уровень маскировки, что у оригинального клиента. Поддержка HTTP/2 и HTTP/3 (QUIC, congestion control BBR/BBRv2/Cubic/Reno), ECH опционально, UDP — только через `udp_over_tcp`.
- Билд-тег `with_naive_outbound` включён **по умолчанию** в официальных релизах sing-box.
- Ограничение: нужна `libcronet` — Windows: `libcronet.dll` рядом с бинарём/PATH; Linux: `libcronet.so` (glibc ≥2.31 или musl-вариант); Android/Apple — через libbox. TLS-настройки валидируются строго (запрещены insecure/отключение SNI/кастомный ALPN — чтобы не ломать фингерпринт).
- De-facto URI-формат: `naive+https://user:pass@host:port` (и `quic://` для H3). Клиентский парсинг есть у singbox2proxy.
- Источники: https://singbox-internals.hidandelion.com/protocols/naive.html , https://deepwiki.com/hoaxisr/amnezia-box/4.5-naiveproxy-outbound , https://pypi.org/project/singbox2proxy/0.2.3/

### 1.4. Поддержка в клиентской экосистеме (конкуренты)
- **Nekoray**: NaïveProxy через Custom Core (сторонний бинарь).
- **NekoBox (Android)**: naive через APK-плагин.
- **v2rayNG**: naive **нет** в списке протоколов.
- **v2rayN** (десктоп, есть в sora-legacy!): naive через `ECoreType.naiveproxy` — спавн внешнего `naive`-бинаря как custom core (`naiveproxy_custom`).
- **Xray-core**: naive **нет и не будет** (только через custom core / внешний бинарь).
- Вывод: на десктопе ни один массовый клиент не имеет **первоклассной нативной** поддержки naive — все через костыли (custom core/плагин). Окно для дифференциации открыто.

### 1.5. Аналоги (прокси на реальном browser-стеке)
Настоящий browser-стек использует, по сути, только naiveproxy и его производные:
1. **klzgrad/forwardproxy@naive** — форк Caddy forwardproxy с naive padding-слоем. Собирается одной командой через xcaddy — **самый простой серверный деплой** (чистый Go, без сборки Chromium). Серверная сторона для провайдеров.
   Источник: https://www.gitplanet.com/project/naiveproxy
2. **sing-box naive inbound** — Go-нативный naive-совместимый сервер (HTTP/2+HTTP/3, padding). Сервер без Chromium.
   Источник: https://singbox-internals.hidandelion.com/protocols/naive.html
3. **sing-box naive outbound (cronet-go)** — клиентская сторона внутри sing-box (см. 1.3). Это и есть «аналог», встроенный в движок sora.
4. Косвенные аналоги (не browser-стек, но та же ниша «выглядеть как обычный HTTPS»): **Trojan** (TLS-камуфляж, слабее), **XHTTP** (уже есть в sora), **VLESS REALITY** (уже есть; фингерпринт uTLS, не настоящий Chrome). Прямого конкурента «настоящий Chrome-стек» у naive нет.

### 1.6. Производительность и цена вопроса
- TLS-over-TLS: больше round trips на handshake, инфляция пакетов, выше CPU/память, чем у VLESS. HTTP/3-режим частично компенсирует на плохих линиях.
- UDP только через UoT — для игр/VoIP хуже, чем нативный UDP у Hysteria2/TUIC.
- Дистрибуция: +libcronet (десятки МБ) к sora-core на Windows/Linux; обновление libcronet при обновлении Chromium — иначе фингерпринт устареет и станет детект-сигналом (README прямо требует «always use latest»).
- Серверная сторона сложнее, чем у VLESS: правильный деплой = Caddy/HAProxy + фронтинг контентом.

## 2. Что sora должен перенять и почему

### R1. Нативная поддержка naive как протокола sing-box-движка (high)
- **Что**: парсинг `naive+https://user:pass@host:port[?quic]` (+ импорт из подписок), генерация sing-box outbound `type: naive` (TLS, `udp_over_tcp.enabled`, опция QUIC), протокол в автовыборе движка по capabilities (только sing-box; Xray/mihomo — пометить unsupported), бейдж протокола в UI.
- **Почему**: нулевая зависимость от внешнего бинаря — всё уже скомпилировано в sing-box. Работа = парсер + рендер конфига + доставка libcronet. Ни один массовый десктоп-клиент не даёт naive из коробки — это дифференциатор «лучшего клиента». Закрывает сценарий «REALITY палят по поведению, нужен настоящий Chrome-фингерпринт».
- **Нюансы**: шиппить `libcronet.dll`/`libcronet.so` вместе с sora-core (проверка наличия при старте naive-аутбаунда, понятная ошибка); версионировать libcronet вместе с обновлениями sing-box; в UI честно пометить «UDP через TCP, не для игр».

### R2. One-click деплой naive-сервера из клиента (medium, синергия с P2 «свои серверы»)
- **Что**: в запланированной фиче «развёртывание своего сервера из клиента» добавить шаблон naive: `xcaddy build --with forwardproxy@naive` + генерация Caddyfile (fronting-сайт + basic_auth + probe_resistance).
- **Почему**: серверная сторона — главный барьер входа в naive; убрав его, sora создаёт предложение «клиент+сервер», которого нет ни у кого.

### R3. Padding/anti-probing практики в собственной диагностике (low)
- **Что**: в сетевую диагностику sora добавить проверку «сервер отвечает на active probing как обычный веб-сайт» (простой HTTP GET без auth → должен отдать веб-контент/404, а не прокси-ошибку).
- **Почему**: дешёвая фича, повышает выживаемость любых TLS-протоколов sora, а не только naive.

### Чего НЕ делать
- Не тащить внешний `naive`-бинарь как custom core (путь v2rayN/Nekoray): лишний процесс, лишний апдейт-канал, проигрыш нативному cronet в sing-box.
- Не позиционировать naive как «недетектируемый»: DPI-вендоры 2026 уже заявляют его идентификацию; честная формулировка — «Chrome-фингерпринт, устойчив к active probing».

## 3. Оценка эффекта

| # | Действие | Эффект | Обоснование |
|---|---|---|---|
| R1 | Нативный naive в sing-box-движке | **high** | Единственный протокол с настоящим Chrome-стеком; ни у кого из массовых десктоп-клиентов нет из коробки; стоимость внедрения низкая (движок уже умеет) |
| R2 | Деплой naive-сервера из клиента | **medium** | Синергия с P2; снимает главный барьер; уникальное предложение клиент+сервер |
| R3 | Проверка active-probing в диагностике | **low** | Дёшево, полезно для всех TLS-протоколов |

## 4. Итог: стоит ли поддерживать в клиенте
**Да.** NaiveProxy жив (Chromium 154, октябрь 2026), остаётся эталоном «выглядеть как Chrome», а sing-box уже содержит его нативно через cronet — sora получает протокол почти бесплатно (парсер + libcronet в дистрибуции). Это реальный дифференциатор против v2rayNG/Nekoray/NekoBox/v2rayN и страховка на случай деградации REALITY. Не панацея от DPI (вендоры 2026 заявляют детект), поэтому подавать честно: Chrome-фингерпринт + anti-probing, не «невидимость».
