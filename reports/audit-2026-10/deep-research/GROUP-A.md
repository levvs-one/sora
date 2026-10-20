# GROUP-A «Транспорты» — сводка глубокого прохода

Дата: 2026-10-20. Лид группы: проход выполнен лично (субагенты недоступны на глубине 2/2 — 10 тем исследованы последовательно). Метод: 25+ поисковых запросов, первоисточники (исходники Xray-core/sing-box/mihomo, RFC 9297/9298/9484/9000, официальные доки XTLS/sing-box, changelog'и Hysteria/sing-box, USENIX 2025, FOCI 2026) + сверка с кодом sora (`core/engine`, `core/parser`). Первый проход (WEB-RESEARCH.md, тиры 1–46) не дублируется — здесь только механика из кода и то, что меняет решения.

Отчёты: `01-xhttp-internals.md`, `02-reality-internals.md`, `03-xtls-vision.md`, `04-websocket-early-data.md`, `05-grpc-transport.md`, `06-httpupgrade-split.md`, `07-masque.md`, `08-naiveproxy.md`, `09-quic-transport.md`, `10-dead-transports.md`.

## Ранжированные рекомендации

### P0 — критично, дёшево (делать первым)

1. **XTLS Vision: авто-включение + валидация** (03). Факт: без `flow=xtls-rprx-vision` связка REALITY+TCP несёт детектируемый TLS-in-TLS сигнал (ТСПУ его распознаёт). sora сейчас прокидывает `flow` из URI как есть, авто-логики нет. Внедрить: `plan.go` — авто-vision для VLESS/Trojan + TCP + REALITY/TLS при пустом flow; `validate.go` — ошибка на vision+не-TCP, варнинг на reality+tcp без vision с кнопкой «исправить»; UI-бейдж + confirm при отключении.
2. **XHTTP: пробросить xmux и xPaddingBytes** (01). sora рендерит только mode/path/host/headers — самые дешёвые и эффективные опции отсутствуют. `Transport` ← `Xmux{MaxConcurrency/MaxConnections взаимоисключающе, CMaxReuseTimes, CMaxLifetimeMs, HMaxRequestTimes, HKeepAlivePeriod}`, `XPaddingBytes{100,1000}`; валидация против лимитов nginx (128/1000).
3. **Свежесть движков как фича** (09). Подтверждено changelog'ами: Hysteria ≥2.6.2 — фрагментация ClientHello против SNI-фильтров; sing-box ≥1.12 — Chrome-parrot QUIC-хендшейка hy2, обфускации `gecko`/`salamander`; Xray — свежий quic-go форк. Поднять пины: Hysteria ≥2.6.5 (фикс BBR + memory leak), sing-box ≥1.12. Плюс прокинуть `disable_chrome_parrot` и типы обфускации в UI.
4. **Чистка мёртвого** (10): выпилить мёртвое поле `AllowInsecure` из парсера (не рендерится никуда; Xray ≥26.2.6 его удалил в пользу `pinnedPeerCertSha256`); `h2`+Xray → авто-миграция в XHTTP `stream-one`/H3 с уведомлением (upstream так предписывает).

### P1 — дифференциаторы (ни у кого из 13 конкурентов нет)

5. **XHTTP `downloadSettings`** (01): сплит аплоад/даунлоад по разным серверам (up через CDN, down напрямую через REALITY) — ломает корреляцию и обходит лимиты CDN. `Transport` ← `Download *Transport + *TLSConfig`; валидация (только `stream-up`, не `stream-one`; Xray ≥24.11.30); one-click серверный шаблон из коробки.
6. **NaiveProxy нативно через sing-box** (08): настоящий Chrome-стек (cronet-go, тег `with_naive_outbound`), padding-протокол (первые 8 read/write), application fronting против active probing. Цена честная: libcronet десятки МБ + обязательное обновление синхронно с Chromium (иначе фингерпринт протухает и становится сигналом); UDP только через UoT. One-click деплой: Caddy + forwardproxy@naive.
7. **MASQUE** (07): RFC 9297/9298/9484, Xray — `proxy/masque` с 02.2025, прод-доказательства (Cloudflare WARP, Chrome IP Protection, Oxylabs 10.2026). Окно первенства: ни у кого нет в UI. Честные лимиты: мёртв без UDP; UDP-приложения — с оговорками инкапсуляции. Внедрить: Xray inbound/outbound + mihomo-адаптер + UDP/QUIC-префлайт в диагностике с авто-fallback.
8. **REALITY: dest-диагностика + no-steal** (02): проверка dest (TLS 1.3, ALPN h2, X25519, PQ key share, не-anycast, гео-близость) с индикатором; серверный шаблон «без кражи» (dest → локальный dokodemo-door + SNI-роутинг → blackhole); генератор shortId; spiderX по умолчанию.

### P2 — добор

9. **WS: early data + heartbeat** (04): `?ed=2560` (Xray) / `max_early_data` + `early_data_header_name` (sing-box, авто-подстановка для Xray-серверов); `heartbeatPeriod` для мобильных сетей; баннер «XTLS рекомендует XHTTP (ALPN http/1.1 — известный сигнал)» с миграцией в клик.
10. **gRPC тюнинг** (05): `idle_timeout/health_check_timeout/permit_without_stream/initial_windows_size/user_agent/authority` в план и оба рендера; ALPN-валидация (h2 первым); `multiMode` — только за advanced с бейджем BETA (не дефолт: совместимость не гарантирована).
11. **HTTPUpgrade: починить mihomo-маппинг** (06): `type=httpupgrade` → `network: ws + v2ray-http-upgrade: true` (сейчас риск молча битого конфига); UI-подпись «если WS режется сетью»; авто-предложение при фейле WS-хендшейка.
12. **Зафиксировать «не будем»** (10): mKCP и standalone quic — wontfix в docs (sing-box не имеет mKCP; Xray удалил quic-транспорт). WS/gRPC/HTTPUpgrade — **не** выпиливать (deprecated ≠ удалён; есть ниши и живые подписки).

## Честные пометки (слоп-фильтр группы)

- «QUIC SNI slicing по умолчанию в Xray ≥25.6.8» — из prior research; **первоисточник в этом проходе не найден**, помечено как требующее верификации, не как факт. Подтверждены только Hysteria 2.6.2 (фрагментация ClientHello) и sing-box 1.12 (Chrome-parrot).
- «REALITY/MASQUE/NaiveProxy невидимы» — во всех трёх отчётах опровергнуто: детект идёт по поведению (сибирская волна РКН, QUIC SNI-парсинг GFW/USENIX 2025, DPI-закупка КНР 10.2026). Позиционирование — «устойчивость к конкретным методам», не «невидимость».
- «gRPC multiMode +20%» — только тестовые окружения XTLS, BETA без гарантии совместимости.
- Нумерация RFC: CONNECT-UDP — это RFC 9298 (в задаче указан 9297 — это HTTP Datagrams/Capsule; 9484 — CONNECT-IP). В отчёте 07 — корректно.

## Что sora получает бесплатно

Держа пины движков свежими (п.3), sora автоматически забирает: фрагментацию ClientHello, Chrome-parrot QUIC, свежие uTLS-фингерпринты, quic-go фиксы. Релизный чеклист sora обязан включать «проверить пины движков + libcronet» — иначе фичи превращаются в детект-сигналы.

## Следующий шаг для оркестратора

Темы 01–10 закрыты файлами выше. Для планирования работ: P0 — объём ~2–4 дня (plan/render/validate/UI), P1 — по 3–7 дней на протокол (NaiveProxy и MASQUE — самые ёмкие: сборка с тегами, дистрибуция libcronet, серверные шаблоны). Зависимость: P0 п.4 (пины) — перед всем остальным.
