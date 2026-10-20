# Web-исследование №31: Развитие VLESS в 2025–2026

Дата: 2026-10-19. Веб-поиск: 7 запросов, приоритет источникам 2025–2026.
Состояние sora (read-only сканирование): VLESS уже поддерживается во всех трёх движках; в UI серверы подписываются как `VLESS | XHTTP | REALITY | JSON`, есть VLESS Encryption, фрагментация TLS, uTLS fingerprint.

## Что нового в VLESS (2025–2026)

### 1. XHTTP — основной новый транспорт (наследник SplitHTTP)
- Xray-core 2025: транспорт `xhttp` (ранее `splithttp`), режимы `stream-one` / `stream-up` / `packet-up`. В `packet-up`/`stream-up` аплинк и даунлинк идут отдельными соединениями и могут конфигурироваться независимо (разные протоколы: QUIC в одну сторону, HTTPS в другую; разные IP/домены/серверы) — это ломает pattern-анализ TLS-in-TLS.
- XMUX — новый мультиплексор под XHTTP (параметры `maxConcurrency`, `hMaxRequestTimes`).
- XHTTP не совместим с XTLS Vision, но защита от детекта достигается мультиплексированием + разделением потоков. С REALITY — выбирается `stream-one` по умолчанию. Клиент и сервер должны быть на одной версии Xray — иначе глюки.
- Важно для sora: sing-box официально НЕ поддерживает XHTTP (по состоянию на 2025; позже sing-box добавил собственный `xhttp` outbound, см. ниже — с оговорками о несовместимости с Xray-only semantics).
- Источники: https://habr.com/en/articles/990208/ , https://deepwiki.com/XTLS/Xray-examples/2.4-vless-+-http3-and-modern-transports

### 2. sing-box догнал XHTTP (2025–2026)
- Новые sing-box версии добавили `xhttp` outbound с XMUX, padding, кастомными методами. Но: поведение remap'а xHTTP/httpupgrade на sing-box может отличаться от Xray-only semantics; серверные панели, настроенные под Xray, иногда отклоняют sing-box-вариант.
- sing-box имеет `xtls-rprx-vision` flow, REALITY, XUDP по умолчанию включён, uTLS/REALITY библиотеки обновлены.
- Источники: https://pub.dev/packages/singbox_mm/changelog , https://deepwiki.com/xinebf/mihomo/4.1-proxy-protocol-adapters-(shadowsocks-vmess-vless-trojan-socks5-http-snell-wireguard-hysteria2-tuic)

### 3. XTLS Vision — зрелый дефолт
- `xtls-rprx-vision` (и вариант `-udp443` для клиентов, форсирующих QUIC): random padding во внутреннем хендшейке, интерсепт UDP/443 для максимизации splice'а, direct mode — переключение writer'а напрямую на net.Conn после детекта TLS 1.3 Application Data, экономия всего IO-оверхеда ядра.
- Встречаемость в диких подписках: ~64% VLESS-линков с vision (по выборке ~110 прокси).
- Источники: https://xtls.github.io/en/config/outbounds/vless.html , https://xtls.github.io/en/config/inbounds/vless.html

### 4. REALITY + постквант
- REALITY: гибридный key exchange X25519 + ML-KEM-768 (если fingerprint поддерживает TLS 1.3 с PQ), опциональная верификация сертификата через ML-DSA-65. Хендшейк постквантово безопасен вне зависимости от опций.
- В `outbounds/vless` документации VLESS есть `encryption: mlkem768x25519plus` (0-RTT/1-RTT, native/xorpub/random) — постквантовое шифрование VLESS поверх Xray; mihomo тоже поддерживает `mlkem768x25519plus.*` в `encryption`.
- Полевое мнение 2026: VLESS-REALITY — рекомендуемый stealth-дефолт для Китая; active-probe-resistant по дизайну.
- Источники: https://deepwiki.com/amnezia-vpn/amnezia-xray-core/5.2-tls-and-security , https://deepwiki.com/XTLS/Xray-core/4.1-vless-protocol , https://www.throughwire.net/blog/best-protocol-for-china

### 5. Сравнение по детекту (практика 2025–2026)
- VLESS (корректно настроенный: TLS/XHTTP/REALITY): detection rate <5% в России по наблюдениям операторов; VMess — до 80% (DPI-апдейты сентября 2025, отличимая структура пакетов), Trojan — ~90% (активный probing серверов, с августа 2025), Shadowsocks — 95%, WireGuard — 100%.
- VMess в Xray 2025–2026 — legacy; вся новая разработка идёт в VLESS (XHTTP, encryption, PQ).
- Trojan считается слабее VLESS-Reality по устойчивости к активному probing; VLESS-REALITY — «state of the art» анти-DPI 2026.
- Источники: https://dev.to/__2ea5fee000c/vless-protocol-how-it-bypasses-censorship-in-russia-and-why-it-works-4o9d , https://www.throughwire.net/blog/best-protocol-for-china , https://securityexpress.info/raccoonline-releases-comparative-report-on-wireguard-openvpn-and-vless/ , https://www.vpnsmith.com/en/blog/v2ray-vmess-vless-setup-2026

### 6. Парсинг и совместимость линков
- vless:// URI: параметры `flow`, `fp`, `pbk`, `sid`, `spx`/`spider_x`, `type=xhttp`, `mode=stream-one|stream-up|packet-up`, `xPaddingBytes`, `path`, `authority`. Современные парсеры извлекают host из `host`/`ws_host`/`authority`/`:authority` с fallback на SNI.
- XHTTP-линки в экспортах панелей 2026 года содержат `mode=stream-one`, `xPaddingBytes`.
- Источники: https://pub.dev/packages/singbox_mm/changelog , https://deepwiki.com/igareck/vpn-configs-for-russia/1.2-client-applications-and-setup

## Что sora должен перенять

1. **XHTTP в маппинге движков + fallback-логика** (high). XHTTP — де-факто новый стандарт транспорта VLESS в 2025–2026; конкуренты (v2rayN/NG, Happ, Shadowrocket) уже поддерживают. Автовыбор движка под сервер должен учитывать: XHTTP + Xray-семантика → предпочесть Xray, а не sing-box (у sing-box возможны 404/протокольные расхождения с Xray-only серверами). Добавить парсинг `type=xhttp`, `mode=`, `xPaddingBytes`, `authority`, `spx`.
2. **Предупреждение о несовпадении версий Xray для XHTTP** (medium). XHTTP требует одинаковых версий ядра на клиенте и сервере. В карточке сервера / диагностике стоит показывать предупреждение, если профиль XHTTP, а серверная панель старее.
3. **Постквантовый VLESS (`mlkem768x25519plus`) в парсере и движках** (medium). u: sora уже имеет «VLESS Encryption» — проверить покрытие нового синтаксиса `encryption=mlkem768x25519plus.*` (0-RTT/1-RTT) в парсере URI и в конфигах sing-box/mihomo; REALITY-side ML-KEM идёт из ядра бесплатно, но `mlkem768`-ключи в REALITY `pbk` тоже стоит принимать.
4. **Приоритет VLESS над VMess/Trojan в ранжировании серверов** (medium). Полевые данные: VMess/Trojan детектятся в 2025–2026 существенно чаще; при автовыборе «самого быстрого»/fallback стоит давать бонус VLESS+Vision/XHTTP+Reality-профилям.
5. **mux concurrency по умолчанию для VLESS-TCP** (low-medium). Источники рекомендуют mux concurrency 8 для меньшего числа видимых соединений; на мобильных/нестабильных сетях — опция отключения (head-of-line blocking).
6. **`xtls-rprx-vision-udp443` как опция** (low). Для клиентов, форсирующих QUIC; нишево, но дешево добавить в парсер/настройки.
