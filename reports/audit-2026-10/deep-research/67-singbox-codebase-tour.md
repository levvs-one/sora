# 67. sing-box codebase tour: архитектура для контрибьюторов

Дата: 2026-10-20. Группа G, третий проход.

## Первоисточники

- `github.com/SagerNet/sing-box` (GPLv3 + ограничение на использование имени), `docs/` в репозитории.
- Разборы кода: DeepWiki SagerNet/sing-box (overview, core components, proxy protocol implementations, DNS, network management).
- Сверка с sora (read-only): sora использует sing-box как **движок-бинарь** (рендер JSON-конфига в `core/engine`), не как библиотеку.

## 1. Большая картина: трёхстадийный конвейер

Весь трафик идёт строго: **inbounds → router → outbounds/endpoints**, параллельно — **DNS-подсистема**.

```
[TUN / SOCKS / mixed / ...]      inbounds/
        │ accept()
        ▼
  route.Router                   route/router.go — правила, sniffing, DNS-решения
        │ route()
        ▼
  outbound.Manager               outbound/
  ┌─────────┬──────────┬─────────┐
  │ vless   │ hysteria2│ selector│  protocol/<name>/outbound.go
  │ direct  │ block    │ urltest │
  └─────────┴──────────┴─────────┘
        ▲                        ▲
  DNS: dns.Router + dns.TransportManager (DoH/DoT/DHCP/fakeip) — параллельно конвейеру
```

Корень — `box.Box` (`box.go`): владеет всеми подсистемами и их жизненным циклом (инициализация → старт → стоп в строгом порядке):
`network (*route.NetworkManager)`, `endpoint`, `inbound`, `outbound`, `dnsTransport`, `dnsRouter`, `connection (*route.ConnectionManager)`, `router`.

## 2. Где что лежит (карта для контрибьютора)

| Путь | Роль |
|---|---|
| `include/registry.go` | **Реестр**: маппинг строковых ID из конфига (`"type": "vless"`) → конструкторы. Точка входа для добавления протокола |
| `option/` | Схема конфига: `option/inbound.go`, `option/outbound.go`, `option/<proto>.go` — всё, что парсится из JSON |
| `adapter/` | Интерфейсы: `adapter/inbound.go`, `adapter/outbound.go`, `adapter/router.go` — контракты, против которых пишут код |
| `protocol/<name>/` | Реализации: `inbound.go` / `outbound.go` на протокол (vless, vmess, trojan, shadowsocks, hysteria2, tuic, anytls, ssh, wireguard…) |
| `transport/v2ray/transport.go` | **Фабрика транспортов**: `NewServerTransport` / `NewClientTransport` — ws, h2, grpc, httpupgrade, quic |
| `transport/trojan/mux.go`, `common/mux/router.go` | Мультиплексинг: smux/h2mux поверх протоколов |
| `common/dialer/` | Диалер с привязкой интерфейса/сокет-опциями — то, через что идёт весь исходящий трафик |
| `route/router.go`, `route/network.go` | Маршрутизация + `NetworkManager`: мониторинг интерфейсов, Wi-Fi-стейт, авто-детект сети (см. `docs/manual/misc/tunnelvision.md`) |
| `dns/` | DNS-роутер, транспорты, fakeip |
| `inbound/` | TUN (свой TCP/IP-стек с 1.15, `stack` deprecated), mixed (SOCKS4/5+HTTP на одном порту), tun, redirect… |
| `experimental/clashapi/` | Clash API — внешний контроллер (то, чем пользуются GUI) |
| `service/` | Фоновые сервисы (напр. powerreport) |
| `constant/` | Константы протоколов/таймаутов |

## 3. Как устроены inbound / outbound / mux (суть)

- **Inbound** = слушатель. Принимает соединение (TCP/UDP/TUN-пакет), опционально sniff'ит (domain sniffing), отдаёт `router` контекст с метаданными (src/dst, sniffed domain, inbound tag).
- **Router** = чистые правила (domain, geosite, geoip, port, process…). Решает: какой outbound/endpoint + какой DNS-сервер.
- **Outbound** = «выход»: оборачивает соединение в протокол (шифрование, заголовки VLESS/VMess, obfs) и **диалит** апстрим через `common/dialer`. Специальные: `direct`, `block`, `dns`, `selector`, `urltest`.
- **Mux** — мультиплексирование нескольких логических стримов в одно TCP/TLS-соединение (меньше handshake'ов → меньше триггеров для «сибирского» детектора; см. тему 64). Два слоя: `common/mux` (общий smux-роутер) и per-protocol (`transport/trojan/mux.go`).
- **Транспорты** отделены от протоколов: VLESS может ехать поверх `tcp`/`ws`/`grpc`/`httpupgrade`/`quic` — комбинация собирается фабрикой, а не копипастой.

## 4. Как добавить свой протокол (чеклист контрибьютора)

1. `option/<proto>.go` — структура опций (JSON-теги).
2. `protocol/<proto>/inbound.go` и/или `outbound.go` — реализация против `adapter.Inbound`/`adapter.Outbound`.
3. Регистрация в `include/registry.go` (иначе `"type": "<proto>"` в конфиге не резолвится).
4. Дока `docs/configuration/{inbound,outbound}/<proto>.md` (+ `.zh.md`).
5. Тест: конфиг-пример в `docs/` + unit на handshake.

То же место, куда смотреть при дебаге «sora сгенерировала конфиг, а движок не стартует»: 90% — несоответствие `option/` схеме (рендер в `core/engine` vs актуальная схема sing-box) — валидировать рендер JSON-схемой из `option/`.

## 5. Что это даёт sora (практика, не теория)

- **Пин версии + схема:** держать пин sing-box ≥1.15 (TUN-стек, тема из WEB-RESEARCH тир 6) и в CI сверять рендер `core/engine` со схемой `option/` из запиненного коммита.
- **Диагностика через clashapi:** `experimental/clashapi` — готовый внешний API (коннекты, трафик, логи); sora может не изобретать свой introspection для движка.
- **NetworkManager как референс:** `route/network.go` — как правильно следить за сменой сети/интерфейсов (для темы 66).
- **Mux осознанно:** включать mux там, где он режет параллелизм handshake'ов (REALITY), и **выключать**, где мультиплексирование мешает (некоторые DPI-триггеры) — решение per-outbound, а не глобально.
- **Лицензия:** GPLv3 — sora держит sing-box как отдельный бинарь движка (текущая модель), не линкует в свой код. При любом углублении интеграции — перепроверить лицензионную границу.

## Вердикт «лучшее или слоп»

**Лучшее:** реестр + адаптеры + фабрика транспортов — архитектура, в которую новый протокол добавляется без правок ядра. Разделение «протокол vs транспорт vs mux» — то, что позволяет sora комбинировать фичи движков, а не форкать их.

**Слоп:** форкать sing-box ради мелких патчей (дрейф, головная боль мерджа); линковать как библиотеку в проприетарный код (GPLv3).

## Рекомендация «внедрить так»

1. В `core/engine`: CI-чек «рендер vs JSON-схема `option/` запиненного sing-box» — ловит рассинхрон до релиза.
2. Для глубокой диагностики — читать `experimental/clashapi` напрямую из sora-core (коннекты/трафик движка без костылей).
3. Внутренний гайд для контрибьюторов sora (этот файл → `docs/`): карта кода + чеклист добавления протокола.
4. Mux-политика per-outbound в пресетах (REALITY: mux on; см. тему 64).
