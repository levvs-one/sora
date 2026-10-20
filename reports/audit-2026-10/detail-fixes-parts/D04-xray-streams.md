# D04 — xray: XHTTP downloadSettings, hy2-мэппинг, transport×security-гейты (sora Go core)

Статус: работа выполнена и протестирована; отдельный `[detail-fix]`-коммит создать не удалось — ханки swept в чужой коммит сиблинга `1121593` (pathspec по грязным shared-файлам, авария из AGENTS.md). Маркеры проверены в tip побайтово. Пуша нет.

## 1. XHTTP `downloadSettings` не пробрасывались — параметр не прокинут
- **Было:** рендерились только mode/path/host; асимметрия up/down через разные домены была невозможна — поля молча терялись.
- **Стало:** `engine.Transport` получил `DownloadAddress string` / `DownloadPort uint16` (`core/engine/plan.go`); рендер собирает `xhttpSettings.downloadSettings` как независимый Xray StreamConfig — свой address/port/network, `xhttpSettings.path` зеркалит uplink-путь, security зеркалит главный стрим, SNI (`serverName` в tlsSettings/realitySettings) указывает на downlink-хост. Валидация с явными ошибками: задан только один из пары адрес/порт; поля на не-XHTTP транспорте (раньше молча дропались); `mode: stream-one` + downloadSettings (противоречие: stream-one — одно соединение на оба направления, несовместимо по Xray-examples).
- **Эффект:** подписки могут задавать асимметричные XHTTP-маршруты; битые комбинации падают на рендере с понятной ошибкой, а не в рантайме Xray. 5 новых тестов зелёные.

## 2. Xray-мэппинг hy2 — гипотеза не подтвердилась, закрыто фактами
- **Было (гипотеза):** «Xray маппит hy2 на устаревший v1-outbound».
- **Проверка по первоисточникам:** гипотеза устарела. `HysteriaClientConfig.Build()` возвращает ошибку при `version != 2` — outbound `hysteria` имеет нативную реализацию Hysteria2; официальные доки: «version, must be 2». Текущий маппинг (`protocol: hysteria`, `settings: {version: 2, ...}`) корректен. Отказ от salamander-obfs сохранён — в транспортном `config.proto` Xray поля obfs нет (проверено).
- **Стало:** кода не менял (ломать нечего); добавлен комментарий со ссылкой на доки + pinning-тест `TestRenderPinsHysteria2NativeMapping`, чтобы маппинг нельзя было тихо откатить.
- **Эффект:** вопрос закрыт фактами, регрессия заблокирована тестом.

## 3. Запрещённые пары транспорт×security рендерились молча
- **Было:** `ws`/`httpupgrade` + REALITY и `xhttp`/`grpc` + `flow=xtls-rprx-vision` рендерились молча и ломались в рантайме.
- **Стало:** `checkStreamCompat()` в `stream()` отказывает с ошибкой: REALITY с `ws`/`httpupgrade` (официальная матрица Xray: Not supported), любой непустой XTLS-flow с не-TCP транспортом (XTLS только под TCP+TLS/REALITY). Позитивные контроли рендерятся: xhttp+reality, grpc+reality, ws+tls, tcp+vision+reality.
- **Эффект:** 4 негативных + 4 позитивных кейса (`TestRenderRefusesIncompatibleTransportPairs` / `TestRenderAcceptsCompatibleTransportPairs`); битые подписки отбраковываются до запуска движка.

Верификация: `go build ./engine/...`, `go vet ./engine/xray/`, `go test ./engine/xray/` — всё зелёно (прогонялось на здоровом дереве).
