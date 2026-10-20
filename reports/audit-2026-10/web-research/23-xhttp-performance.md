# Web-research #23: XHTTP — отчёты о производительности и внедрении

Дата: 2026-10-19. Источники: 6 поисковых запросов, приоритет 2025–2026. Статус в sora сверен с репозиториями (read-only): XHTTP уже поддерживается во всех 3 движках (Xray, sing-box-lx, mihomo), пробрасываются `mode` (default auto), `path`, `host`, `headers` (legacy: `core/engine/xray/render.go:256`, `singbox/render.go:285`, `mihomo/proxy.go:151`).

## 1. Что нашёл

### 1.1. Сводная таблица транспортов (XTLS/Xray-examples)
Официальный вики XTLS оценивает транспорты так ([Transport Technologies](https://deepwiki.com/XTLS/Xray-examples/1.2-transport-technologies)):

| Транспорт | Обфускация | Производительность | CDN | Сложность |
|---|---|---|---|---|
| TCP | Low | High | No | Low |
| WebSocket | Medium | **Medium** | Yes | Medium |
| gRPC | High | **Medium** | Yes | Medium |
| HTTP/3 | Medium | High | Limited | High |
| **XHTTP** | **High** | **High** | **Yes** | High |
| SplitHTTP | High | Medium | Yes | High |

**Вывод:** XHTTP — единственный транспорт с оценкой High по обеим осям (обфускация + скорость) и полной поддержкой CDN. В гайде [VLESS + HTTP/3 and Modern Transports](https://deepwiki.com/XTLS/Xray-examples/2.4-vless-+-http3-and-modern-transports) он позиционируется как «modern default».

### 1.2. Замеры и практические наблюдения
- Независимых строгих бенчмарков XHTTP vs WS/gRPC по пропускной способности в открытых источниках **нет**. Полевой тест [v2rayedge (2026)](https://www.v2rayedge.com/en/blog/articles/xray-vs-v2fly-kernel-differences.html): на одной линии разница между ядрами <5%; сначала совместимость протокола, потом скорость. Ранний практический тест [chengxiaobai](https://www.chengxiaobai.com/en/trouble-maker/journey-switching-from-v2ray-to-xray): VLESS+gRPC — самый медленный, VLESS+Vision и Trojan+TCP — почти без разницы, VMess+WS+TLS+CDN «достаточен как аварийный».
- Консенсус 2026 ([throughwire](https://www.throughwire.net/blog/best-protocol-for-china)): дефолт для жёсткой цензуры — **VLESS-REALITY**, пиковый fallback — Hysteria2. XHTTP+REALITY — рабочий «stealth + CDN» вариант.
- REALITY на слабом VPS стоит дорого (1 vCPU: AmneziaWG 70 Мбит/с vs VLESS-REALITY 25 Мбит/с, [dev.to](https://dev.to/technimbus3/how-to-build-an-unblockable-vpn-in-2-clicks-xray-vless-reality-setup-speed-test-36ma)) — криптографическая цена стелса, не специфика XHTTP.

### 1.3. Режимы и главная фишка — асимметрия up/down
Режимы XHTTP (`auto` / `packet-up` / `stream-up` / `stream-one`): `auto` → REALITY даёт `stream-one`, остальное — `packet-up`. `stream-up` обязателен при использовании `downloadSettings` ([SplitHTTP Transport](https://deepwiki.com/lhear/Xray-core/4.3-splithttp-transport)).

**`downloadSettings` — ключевая фишка:** upload и download идут разными соединениями, которые можно настроить независимо: аплоад — через CDN-домен (XHTTP+TLS, IP VPS скрыт), даунлоад — напрямую (XHTTP+REALITY, обход лимитов трафика CDN, быстрее). Генерация share-ссылок уже поддерживает автоподстановку домена по направлению трафика ([zxcvos/Xray-script SNI](https://deepwiki.com/zxcvos/Xray-script/5.3-sni-configuration)). Обзор [habr](https://habr.com/en/articles/990208/): up и down можно гнать даже через разные серверы/провайдеры/страны и разные домены — это ломает анализ паттернов и «TLS-inside-TLS» детекцию.

**Статус в sora:** `downloadSettings` не пробрасывается (render.go ставит только mode/path/host). Share-ссылки с асимметрией sora, судя по коду, не парсит.

### 1.4. Настройки тонкой подгонки
- **xmux**: `maxConcurrency` / `maxConnections` (взаимоисключающие), `cMaxReuseTimes`, `cMaxLifetimeMs`, `hMaxRequestTimes`, `hKeepAlivePeriod`. Важно: лимиты реверс-прокси (Nginx ~128 стримов) — превышение ломает соединение ([Xray-examples](https://deepwiki.com/XTLS/Xray-examples/1.2-transport-technologies), xray-ui [stream_xhttp](https://deepwiki.com/qist/xray-ui/4.3-stream-settings)).
- **xPaddingBytes** (default 100–1000): случайный паддинг запросов/ответов против фингерпринтинга ([lhear/Xray-core](https://deepwiki.com/lhear/Xray-core/4.3-splithttp-transport)). mihomo-реализация добавляет методы и позиции паддинга.
- **scMaxEachPostBytes / scMinPostsIntervalMs / scMaxBufferedPosts** — тюнинг packet-up режима.
- UDS между реверс-прокси и Xray снижает latency (серверная сторона; для клиента нерелевантно).

### 1.5. HTTP/3
XHTTP умеет H1.1/H2/H3: напрямую — QUIC/H3, через CDN — H2 (ALPN сервера должен разрешать даунгрейд). При плохой производительности H3 смотреть лог на «QUIC flood detected» ([Xray-examples](https://deepwiki.com/XTLS/Xray-examples/2.4-vless-+-http3-and-modern-transports)). sora ALPN `h3` для XHTTP не выставляет.

### 1.6. Совместимость и грабли внедрения
- XHTTP **несовместим с XTLS-Vision**; защита от tls-inside-tls — через xmux + сплит up/down ([habr](https://habr.com/en/articles/990208/)).
- WebSocket + REALITY **не поддерживается** Xray вообще; XHTTP + REALITY — поддерживается ([xtls.github.io](https://xtls.github.io/en/config/transport.html)). sora должен это отражать в UI (запрет WS+REALITY).
- XHTTP в активной разработке: версии Xray клиента и сервера должны совпадать, иначе «странные глюки» ([habr](https://habr.com/en/articles/990208/)). У sora движки свои (свежие), но серверные — чужие: нужен варнинг в диагностике.
- sing-box: стоковый sing-box XHTTP не поддерживал ([nexora docs](https://docs.nexora-panel.org/protocols/vmess): «sing-box apps — yes, except xhttp and mkcp»), форки добавили (sing-box-lx — у sora уже в CHANGELOG: «sing-box-lx 1.14.3-lx.14 с XHTTP»; L×Box тоже форкнул, [openapk](https://www.openapk.net/ko/l%97box/com.leadaxe.lxbox/)). mihomo xhttp поддерживает (xinebf). Вывод: у sora покрытие полное, но share-ссылки XHTTP могут не читаться стоковыми sing-box-клиентами — учитывать при экспорте.

## 2. Что sora должен перенять

| # | Что | Почему | Эффект |
|---|---|---|---|
| 1 | **Пробросить `downloadSettings`** (поле в `Transport` + парсинг асимметричных share-ссылок) и, опционально, UI-опцию «upload через CDN / download напрямую» | Главная фишка XHTTP, отсутствующая у конкурентов в UI; обход лимитов CDN, скорость, анти-анализ паттернов | **high** |
| 2 | **VLESS+XHTTP+REALITY как рекомендованный дефолт** в UI/гайдах; запрет/варнинг WS+REALITY (не поддерживается ядром) | XHTTP — единственный транспорт High/High по обфускации и скорости; WS+REALITY — нерабочая комбинация, которую юзер может собрать руками | **medium** |
| 3 | **xmux в advanced-настройках** (`maxConcurrency`/`maxConnections`, `cMaxReuseTimes`, `hMaxRequestTimes`) + гард «не превышать 128» при реверс-прокси | Предотвращает «молчаливые» обрывы за nginx; дефолты Xray ок, но за прокси рвутся | **medium** |
| 4 | **xPaddingBytes** (диапазон паддинга) в advanced для XHTTP | Дешёвый анти-фингерпринтинг; уже есть в Xray и mihomo | **medium** |
| 5 | **ALPN `h3` опция** для XHTTP при прямом соединении | HTTP/3 даёт лучшую производительность на lossy-линиях (QUIC), сейчас sora её не предлагает | **medium** |
| 6 | **Запрет XHTTP+Vision в UI** с объяснением (защита — через xmux/сплит) | Предотвращает нерабочие конфиги; сейчас юзер может собрать несовместимую пару | **medium** |
| 7 | **Встроенный speedtest: сравнение транспортов** на одном сервере (XHTTP vs WS vs gRPC) | У sora уже есть встроенный speedtest — дифференциатор «лучшего клиента»: объективный выбор транспорта, данных в открытых источниках нет | **medium** |
| 8 | **Диагностика версий XHTTP**: варнинг при рассинхроне версий Xray клиент/сервер, напоминание держать движки свежими | Известный источник «странных глюков», дебаг вслепую | **low** |
| 9 | **Тюнинг packet-up** (`scMaxEachPostBytes`, `scMinPostsIntervalMs`, `scMaxBufferedPosts`) в advanced | Для тяжёлых аплоадов; нишево | **low** |

## 3. Оценка итогом
XHTTP — консенсусный «best transport» 2025–2026 для связки стелс+скорость+CDN; sora уже покрывает его на всех трёх движках (редкое преимущество — даже sing-box через lx-форк). Главный пробел — **не используется асимметрия up/down (`downloadSettings`)**, это единственная фича XHTTP, которой нет ни у одного конкурента в UI. Остальное — advanced-тюнинг (xmux, padding, h3) и защита от нерабочих комбинаций (Vision, WS+REALITY).
