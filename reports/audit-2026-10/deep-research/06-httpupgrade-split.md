# 06. HTTPUpgrade / SplitHTTP — реализация в mihomo и sing-box, когда вместо WS

Дата: 2026-10-20. Источники: исходники mihomo (`transport/vmess/websocket.go`: `V2rayHttpUpgrade`, `V2rayHttpUpgradeFastOpen`), sing-box docs (v2ray-transport: `type: httpupgrade`), исходники Xray (`transport/internet/httpupgrade`), конвертер shipengtao (междвижковый маппинг), XTLS-статус legacy.

## Что такое HTTPUpgrade

HTTPUpgrade — транспорт, который начинается как **обычный HTTP/1.1 GET-запрос** и апгрейдится в двунаправленный поток без WebSocket-фрейминга. На проводе после апгрейда — «голые» байты (как у TCP), без WS-заголовков 2–14 байт на фрейм.

Реализация по движкам (важно: **разная модель**):

- **Xray:** отдельный транспорт `transport/internet/httpupgrade`, `httpupgradeSettings: {path, host}`. Статус в amnezia-форке: помечен legacy/deprecated наряду с `grpc` и `websocket` — XTLS двигает всех на XHTTP.
- **sing-box:** отдельный тип транспорта `{"type": "httpupgrade", "host", "path", "headers"}`.
- **mihomo:** **не отдельный транспорт**, а флаг на WebSocket: `network: ws + v2ray-http-upgrade: true` (`WebsocketConfig.V2rayHttpUpgrade`). Конвертеры (shipengtao) маппят `type=httpupgrade` из VLESS-ссылки именно так. Плюс `V2rayHttpUpgradeFastOpen` — ленивое чтение ответа (defer до первого read), экономия RTT.

Вывод для мультидвижкового клиента: один и тот же URI `type=httpupgrade` рендерится тремя разными способами. Ошибка маппинга = молча неработающий конфиг.

## Когда использовать вместо WS

**За HTTPUpgrade:**
1. **Меньше оверхед** — нет WS-фрейминга; на мелких пакетах (игры, VoIP-сигналинг, DNS) экономия заметна.
2. **Проще для middlebox'ов** — некоторые корпоративные/отельные прокси режут именно WebSocket-upgrade (фильтр по `Upgrade: websocket`), а generic HTTP-upgrade пропускают. Нишевый, но реальный кейс.
3. **Меньше характерных признаков**, чем у WS: нет WS-хендшейка с `Sec-WebSocket-Key/Accept` — после апгрейда поток выглядит как долгоживущий HTTP.
4. Работает за реверс-прокси без WS-поддержки (достаточно проксирования upgrade).

**Против (почему не дефолт):**
1. XTLS считает его legacy — развитие (фичи, багфиксы) идёт в XHTTP.
2. Нет мультиплексирования на уровне транспорта (как и у WS).
3. CDN-поддержка уже, чем у WS: Cloudflare и др. оптимизированы под WS; HTTPUpgrade — «второй сорт» на edge.
4. Нет early-data механики Xray (`?ed=`) в том же виде — экономия 1 RTT теряется.

**Правило выбора:** WS — когда нужен CDN и early data; **HTTPUpgrade — когда WS режется middlebox'ом или нужен минимальный оверхед без WS-сигнатуры**; XHTTP — дефолт для новых деплоев (позиция XTLS).

## Вердикт: лучшее (нишевое)

HTTPUpgrade — не слоп: у него есть своя ниша (middlebox'ы, режущие WS; минимальный оверхед) и он дёшев в поддержке. Но это не «стелс-транспорт» — позиционировать честно как fallback-опцию, а не фичу.

**Отсеяно фильтром:** «HTTPUpgrade невидимее WS» — частично верно лишь против наивных фильтров по строке `websocket`; против DPI с анализом паттернов оба — долгоживущие h1.1-соединения.

## Внедрить в sora так

Состояние sora: Xray рендерит `httpupgradeSettings {path, host}`; sing-box — проверить (в `engine/singbox/render.go` кейс `httpupgrade` есть в списке транспортов выше). mihomo — **проверить**: рендерится ли как `network: ws + v2ray-http-upgrade: true`, а не как отдельный тип (иначе mihomo-движок сломается молча).

1. **render.go (mihomo):** `type=httpupgrade` → `network: ws`, `ws-opts: {path, headers}`, `v2ray-http-upgrade: true`. Покрыть тестом на уровне рендера (сейчас такого теста, судя по всему, нет — добавить).
2. **validate.go:** кросспроверка «транспорт поддерживается выбранным движком» (матрица: Xray ✓ / sing-box ✓ / mihomo ✓-как-флаг).
3. **UI:** в селекторе транспорта — HTTPUpgrade с подписью «если WebSocket режется сетью; меньше оверхед, без early-data». Не прятать в advanced, но и не ставить дефолтом.
4. **Диагностика:** авто-тест «WS заблокирован?» — при фейле WS-хендшейка предлагать переключение на HTTPUpgrade в один клик (реальный сценарий отельных сетей).
5. **Не делать:** позиционировать как upgrade над WS по стелсу; депрекейтить вслед за XTLS — пока mihomo/sing-box поддерживают, держать как рабочую опцию.
