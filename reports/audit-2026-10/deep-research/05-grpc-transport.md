# 05. gRPC транспорт в Xray/sing-box — gun vs multi, health-check, тюнинг

Дата: 2026-10-20. Источники: официальные доки XTLS Project X (grpc), исходники Xray (`transport/internet/grpc`, `encoding/stream.go`), sing-box docs (v2ray-transport: grpc), mihomo `transport/gun/gun.go`, Xray-examples (VLESS-GRPC: nginx `grpc_pass`, Caddy `reverse_proxy`).

## gun vs multi: что это на самом деле

**gun (дефолт, `multiMode: false`)** — «gRPC» от Xray это не стандартный gRPC-стек, а облегчённая реализация поверх HTTP/2:
- Клиент открывает HTTP/2 bidirectional stream к пути `/<serviceName>/Tun` (`ServiceNameToPath` в mihomo; аналогично в Xray).
- Данные фреймятся в Length-Prefixed Messages: 5-байтовый gRPC-заголовок (1 байт compression flag + 4 байта big-endian длины) + protobuf-обёртка (тег `0x0A` + UVarint длина) — `transport/internet/grpc/encoding/stream.go`.
- Xray использует собственную реализацию (не `google.golang.org/grpc` на горячем пути — в go.mod она есть, но транспорт gun — кастомный, более лёгкий).

Снаружи выглядит как обычный gRPC API-трафик — хорошо для сетей, где gRPC легален и популярен (микросервисные инфраструктуры).

**multiMode (`multiMode: true`, BETA)** — экспериментальный режим: клиент открывает **несколько параллельных gRPC-стримов** вместо одного. Официальная формулировка: «~20% прироста производительности в тестовых окружениях, реальные результаты зависят от скорости». Только клиентская опция. Статус BETA означает буквально: **может не сохраниться, кросс-версионная совместимость не гарантируется**. Сервер multi не требует (договаривается клиент).

**Практический вывод:** gun — зрелый дефолт; multi — лотерея: на слабых каналах выигрыша может не быть вообще, а при рассинхроне версий клиент/сервер — риск молчаливой деградации. Для продукта, который обещает «работает всегда», multi — не дефолт.

## Health-check и таймауты

Механика (Xray `grpcSettings`):
- `idle_timeout` (сек, минимум 10 — меньше принудительно станет 10): нет данных N секунд → health check (HTTP/2 PING).
- `health_check_timeout` (дефолт 20): сколько ждать ответа на health check.
- `permit_without_stream` (дефолт false): слать ли keepalive-пинги при отсутствии активных стримов. `false` = не слать (экономия батареи/трафика, но NAT может убить соединение).
- `initial_windows_size` (0 = дефолт): стартовое HTTP/2 flow-control окно. На high-BDP каналах (дальние серверы) увеличение окна поднимает throughput — это реальный тюнинг, а не плацебо.

sing-box (`type: grpc`): `idle_timeout` / `ping_timeout` (дефолт "15s"), `permit_without_stream` — та же семантика; плюс примечание: «standard gRPC» (полный grpc-go стек) в sing-box **не включён по умолчанию** (отдельный билд-тег) — дефолтный gun-совместимый.

## Тонкости, которые ломают деплой

1. **ALPN:** `h2` обязан быть первым в `tlsSettings.alpn`, иначе gRPC не завершит TLS-хендшейк (официальное требование XTLS).
2. **gRPC нельзя сплитить по path** на уровне фронтенда как WS — только по `serviceName` (nginx: `grpc_pass` + location по service path; Caddy: `reverse_proxy` с `transport http { versions h2c }`).
3. **serviceName как путь:** если начинается со `/` и содержит ≥2 слэшей — кастомный путь; сервер может принимать несколько (`/my/sample/path1|path2`), клиент выбирает один. Это фича для сокрытия за «похожим на API» путём.
4. **`user_agent`** (только клиент): некоторые CDN режут дефолтный gRPC user-agent — кастомизация решает блокировку на edge, не трогая сервер.
5. **`authority`**: переопределяет `:authority`/Host — инструмент для фронтинга внутри gRPC.
6. **Реверс-прокси:** Xray умеет слушать gRPC на unix-socket за nginx/Caddy — производительнее и не занимает порт.

## Вердикт: лучшее (gun + health-check); multi — пограничный слоп

gun — зрелый транспорт с честной механикой маскировки под API-трафик. Health-check тюнинг — реальный инструмент против «молча мёртвых» соединений. **multiMode — отсеять из дефолтов**: BETA-статус + негарантированная совместимость = неприемлемо для клиента, обещающего надёжность; оставить как advanced-опцию с честной пометкой «эксперимент».

**Отсеяно фильтром:** «gRPC невидим, потому что все используют gRPC» — верно лишь там, где gRPC-трафик действительно фоновый; в домашней сети долгоживущий gRPC-стрим к одному хосту — аномалия. «multi даёт +20% всегда» — только в тестах XTLS, зависит от канала.

## Внедрить в sora так

Состояние sora: Xray — `grpcSettings: {serviceName}` только; sing-box — `type: grpc, service_name` только. Health-check, user_agent, authority, multi — отсутствуют.

1. **plan.go:** `Transport` ← `GrpcAuthority string`, `GrpcUserAgent string`, `GrpcIdleTimeout int` (сек), `GrpcHealthCheckTimeout int`, `GrpcPermitWithoutStream bool`, `GrpcInitialWindowSize int`, `GrpcMultiMode bool` (advanced).
2. **render.go (xray):** пробросить всё в `grpcSettings`; **render.go (sing-box):** `idle_timeout/ping_timeout/permit_without_stream` (sing-box понимает; `service_name` уже есть).
3. **validate.go:** `transport=grpc` + ALPN без `h2` первым → ошибка с автофиксом («поставить h2 первым»); `multiMode=true` → варнинг «BETA, совместимость не гарантирована» + требование подтверждения в UI.
4. **UI:** секция gRPC: serviceName (с генератором «похоже на API» путей), user-agent (пресет «дефолт/Chrome-API/кастом»), health-check (пресеты: «десктоп» 60/20, «мобильный/экономия» — permit_without_stream=false + больший idle). multiMode — за «продвинутым» тумблером с бейджем BETA.
5. **One-click деплой:** шаблон nginx `grpc_pass` на unix-socket + `serviceName` из генератора — готовый серверный конфиг, которого нет у конкурентов в one-click.
6. **Не делать:** multi дефолтом; автовключение `permit_without_stream=true` на мобильных (жрёт батарею ради keepalive пустоты).
