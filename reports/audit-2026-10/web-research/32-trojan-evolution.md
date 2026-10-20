# Веб-рисеч #32: Эволюция Trojan в 2025–2026

Дата: 2026-10-19. Источники: 6 поисковых сессий, приоритет — материалы 2025–2026 (статьи о GFW, issue-трекер Xray-core, доки sing-box/Xray/mihomo, DeepWiki разборы репозиториев).

## 1. Что нашёл

### 1.1. Trojan-Go как проект мёртв, протокол — нет
- Оригинальный репозиторий **p4gefau1t/trojan-go** исчез из GitHub; живой след — форк **yanBinChen/trojan-go** (DeepWiki: https://deepwiki.com/yanBinChen/trojan-go, https://deepwiki.com/yanBinChen/trojan-go/2-getting-started). Релизы не выходят, docker-тег `latest` заморожен на версии ~0.10.6 (https://hub.docker.com/r/gists/trojan-go/tags).
- Это не проблема: сам протокол Trojan заморожен осознанно (простой, SHA224-хэш пароля + CRLF-разделитель, дальше SOCKS5-адресация). Все его фичи поглощены движками: multiplexing, WebSocket+CDN, TLS-фингерпринт-подмена — всё это нативно есть в sing-box, Xray и mihomo.
- Вывод для sora: на standalone Trojan-Go **не опираться** — только на троян-реализации в bundld-движках.

### 1.2. Trojan по-прежнему probe-resistant (2025)
- Свежие разборы GFW (Sep 2025; https://medium.com/btcvpn/inside-the-great-firewall-how-chinas-censorship-machine-really-works-and-how-to-beat-it-b92b3be410a2, https://arxiv.org/html/2503.02018v1) относят Trojan к протоколам, устойчивым к активному зондированию: невалидное соединение проксируется на настоящий веб-сервер (fallback на Nginx/decoy-сайт), проба становится неубедительной. Тот же класс — VLESS+TLS.
- Fallback-механика неизменна с 2020: сервер терминирует настоящий TLS с настоящим CA-сертификатом, неверный пароль → побайтовая пересылка на decoy (https://deepwiki.com/atrandys/trojan/2.1-runtime-traffic-flow).

### 1.3. Связка Trojan + REALITY — жива и поддерживается
- Xray поддерживает `trojan` + `security=reality`: панели 3X-UI документируют создание Trojan-inbound с Reality (https://blog.ishosting.com/en/3x-ui-trojan-setup, ~май 2026): Security → Reality, uTLS (Chrome/Firefox), `pbk`, sniffing. Преимущества связки: не нужен сертификат, REALITY крадёт TLS-отпечаток целевого сайта, fallback на настоящий сайт при пробе, плюс парольная аутентификация Trojan.
- В sora это уже возможно на уровне рендера: `core/engine/{singbox,xray,mihomo}` применяют блок `tls.reality` к trojan-outbound через общий TLS-блок (singbox/render.go:250-253, xray/render.go:269-274, mihomo/proxy.go:231-235), парсер читает `pbk`/`spx` из URL (parser.go:397-399).

### 1.4. Главная боль 2025–2026 — свежесть uTLS-фингерпринтов
- Xray-core issue #7131 (11 окт 2026; https://github.com/XTLS/Xray-core/issues/7131): `fingerprint: "chrome"` в Xray до сих пор шлёт ClientHello **Chrome 133** (utls зафиксен), тогда как реальный Chrome — **155** (отличие видно по JA4). Автор прямо пишет: в России текущий `chrome`-фингерпринт, похоже, детектится и блокируется ТСПУ. Требуется bump utls до версии с HelloChrome_155.
- mihomo уже умеет взвешенно-случайный выбор фингерпринта (`random`: chrome 6 / safari 3 / ios 2 / firefox 1) и версионно-специфичные (`chrome120`, `firefox120`) (https://deepwiki.com/xinebf/mihomo/6.1-tls-reality-and-utls-fingerprinting).
- Отдельно: CVE-2026-26995 — отсутствие padding-расширения в uTLS для Chrome 120 (https://vulert.com/vuln-db/fingerprint-vulnerability-in-utls-from-missing-padding-extension-for-chrome-120-in-github-com-refrac-), лечится обновлением utls ≥ 1.8.2.

### 1.5. Контекст 2025: что вокруг Trojan изменилось
- QUIC SNI slicing — дефолт в Firefox 137, V2Ray 5.33, **Xray 25.6.8**, Hysteria 2.6.2, **sing-box 1.12**; pre-QUIC dummy-пакеты; ECH (RFC 9849, март 2026; ТСПУ режет ECH с outer SNI `cloudflare-ech.com`, КНР/Иран бьют по зашифрованному DNS) (источники: medium/btcvpn Sep 2025; https://ambientnode.uk/domain-fronting-ech).
- Trojan+WS за CDN — по-прежнему валидное развёртывание (https://deepwiki.com/roosterkid/openproxylist/3.1.4-trojan-protocol).

## 2. Что sora должен перенять и почему

| # | Рекомендация | Почему | Эффект |
|---|---|---|---|
| 1 | **Держать движки свежими (≥ sing-box 1.12, Xray 25.6.8, последний mihomo) + build-time проверка версии utls/Chrome-фингерпринта.** В CI сравнивать JA4/версию зашитого `chrome`-фингерпринта с актуальным релизом Chrome; при расхождении — ворнинг в сборке/диагностике. | Устаревший фингерпринт — единственный реально подтверждённый в 2026 детект-вектор Trojan/VLESS-трафика (ТСПУ, issue #7131). | high |
| 2 | **Trojan+REALITY как first-class комбо в UI и пресетах.** Проверить end-to-end импорт `trojan://...?security=reality&pbk=...&fp=chrome`, добавить пресет «Trojan + REALITY» в мастер настройки/региональные рекомендации (РФ/КНР/Иран). Рендер уже умеет, дело за парсером-проверкой и UI. | Даёт probe-resistance REALITY без сертификата + парольную модель Trojan; конкуренты (панели 3X-UI) это уже продают как фичу. | high |
| 3 | **Политика свежести/ротации фингерпринта в настройках:** опция «случайный фингерпринт» (взвешенно, как в mihomo), выбор конкретной версии (`chrome155`, `firefox`), предупреждение если выбранный фингерпринт старше N месяцев. | Снимает класс проблем из #7131 проактивно, а не реактивно; выделит sora среди клиентов, где выбор фингерпринта — просто выпадашка без контекста. | medium |
| 4 | **«Оценка probe-resistance» сервера в UI** (экран соединений / выбор сервера): Trojan и VLESS+REALITY — высокий скор, голый VLESS/SS — низкий; учитывать в эвристике автовыбора для регионов с активным зондированием. | Прямой UX-выигрыш из исследования GFW: пользователи в РФ/КНР выбирают протокол вслепую; sora может выбирать за них осознанно. | medium |
| 5 | **Импорт `trojan-go://` share-ссылок** (формат yanBinChen: `trojan-go://pwd@host/?type=ws&path=...&encryption=ss;...`). | Дешёвая совместимость с экосистемой форка; расширяет импорт без затрат на движок. | low |
| 6 | **Дока для самохостеров**: чеклист decoy-сайта для Trojan-сервера (реальный сайт на 443, fallback-порт, живой контент) — в docs/, не в клиентском коде. | Fallback — половина stealth-модели Trojan; пользователи sora часто поднимают свои серверы. | low |

## 3. Чего делать НЕ надо
- Не тащить Trojan-Go как отдельный движок/бинарь: протокол заморожен, развитие идёт внутри sing-box/Xray/mihomo.
- Не изобретать свой TLS-фингерпринт: только свежий utls из движков + политика ротации (п.3).
- Не продвигать голый Trojan без TLS 1.3/uTLS как «stealth по умолчанию» в регионах с ТСПУ/GFW — минимум требовать uTLS-фингерпринт актуального браузера.
