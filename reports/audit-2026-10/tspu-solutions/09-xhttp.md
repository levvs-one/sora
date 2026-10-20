# 09. XHTTP: downloadSettings, тонкий тюнинг, guards несовместимости

Дата: 2026-10-20. Проблема **T009** (Critical, Tier S12, WEB-RESEARCH.md; матрица: `reports/TSPU-ANALYSIS.md`).
Статус: модель + валидация + гейты движков реализованы в Go (`core/engine`); рендеры тонкой настройки, парсер `extra=`, проброс credential и UI — эта спека.

## 1. Проблема

- **XHTTP отсутствует в stock sing-box** — архитектурный барьер: транспорт разработан XTLS, sing-box реализовал его только в форке `sing-box-lx` (тег сборки `with_xhttp`). sora шиппит `1.14.3-lx.14`, но гейт версий в `catalog.go` раньше отбраковывал форк (MinVersion 1.15.0 не учитывал `-lx.` суффикс) — XHTTP-путь через sing-box был мёртв. Исправлено смежным T009-ханком: `BuildCapabilities` выставляет форку `MinVersion: "1.14.3"`.
- **`downloadSettings` (сплит up/down) не проброшен нигде**: аплоад через CDN-домен, даунлоад напрямую — ломка pattern-анализа ТСПУ. Ни у одного клиента нет в UI.
- **Нет xmux-тюнинга** (`maxConcurrency`/`maxConnections`), **`xPaddingBytes`**, осмысленной работы с **ALPN h3**.
- **XHTTP несовместим с XTLS-Vision** (Vision — TCP-only), а **WebSocket+REALITY не существует вообще** (Xray: «REALITY only supports RAW, XHTTP and gRPC for now») — sora молча рендерила такие планы, и они умирали в рантайме.
- **Версионный риск**: XHTTP в активной разработке, клиент и сервер должны быть на совпадающих версиях Xray, иначе «strange glitches».

## 2. Что уже сделано (Go, `core/engine`)

| Слой | Что |
|---|---|
| `plan.go` | `Transport`: `DownloadAddress`/`DownloadPort` (сплит даунлинка), `XmuxMaxConcurrency`/`XmuxMaxConnections`/`XmuxMaxReuseTimes`/`XmuxMaxRequestTimes`, `XPaddingBytes` («min-max»/число) |
| `engine.go` | `FeatureXHTTPDownloadSplit` (Xray, mihomo; sing-box — нет), `FeatureXHTTPXmux` (Xray, mihomo; sing-box-lx — нет, только `x_padding_bytes`) |
| `refs.go` | `RequiredFeatures()`: сплит/тюнинг тянут фичи → план со сплитом **не маршрутизируется** на sing-box (раньше — молчаливый дроп настроек) |
| `catalog.go` | `Missing()`: Xray честно сообщает «REALITY over ws/httpupgrade (Xray supports REALITY only over tcp, xhttp and grpc)» вместо провала рендера |
| `validate.go` | `validateXHTTP()`: whitelist mode (`auto/packet-up/stream-up/stream-one`); **запрет XHTTP+Vision**; downloadSettings только на xhttp, адрес+порт парой, несовместимость со `stream-one`; xmux неотрицательные + взаимоисключение concurrency/connections; формат `xPaddingBytes`; **ALPN h3 без TLS — ошибка** |
| `validate.go` | `Warnings()`: `xhttp-version-sync` (напоминание о совпадении версий, т.к. версию сервера пробросить нельзя), `xhttp-xmux-proxy-limit` (`maxConcurrency > 128` — лимит nginx) |
| xray render (смежный ханк) | `downloadSettings{address,port,network:"xhttp",security: mirror, SNI=download host}` + `checkStreamCompat` (ws/httpupgrade+reality, flow↔транспорт) + тесты |

## 3. Рендеры тонкой настройки (Go, бэклог — точная спека)

**Xray** (`core/engine/xray/render.go`, в `xhttpSettings` рядом с `downloadSettings`):
```json
"xmux": {"maxConcurrency": 64},
"xPaddingBytes": "100-1000"
```
Числа — plain (официальный `client.jsonc` Xray принимает plain numbers; `RangeConfig` в conf-слое их жуёт). `maxConnections` вместо `maxConcurrency` — взаимоисключительно (валидация уже запрещает пару). `cMaxReuseTimes`/`hMaxRequestTimes` — только если заданы (>0).

**sing-box-lx** (`core/engine/singbox/render.go`, xhttp transport):
```json
"x_padding_bytes": "100-1000"
```
Только padding. xmux и downloadSettings — нет в форке (доки `docs-lx/lx-config.md` исчерпывающие); гейт `FeatureXHTTPXmux`/`FeatureXHTTPDownloadSplit` уже не пускает такие планы на sing-box.

**mihomo** (`core/engine/mihomo/config.go` → `xhttpOpts`, `proxy.go` → `applyTransport`):
```yaml
xhttp-opts:
  x-padding-bytes: "100-1000"      # строка!
  reuse-settings:                  # строки!
    max-concurrency: "64"
    max-connections: "8"
    c-max-reuse-times: "0"
    h-max-request-times: "0"
  download-settings:               # из mihomo v1.19.32 (пин sora)
    server: "down.example.com"
    port: 443
```
Всё — строки (mihomo парсит `interface{}`→строки; числа сломают `-t`). `download-settings` наследует TLS от родителя, когда поля nil — оставить nil, не дублировать.

Тесты: позитивные (YAML/JSON содержат ключи) + негативные (xmux на sing-box → план не выбирает sing-box; `Missing()` содержит `feature xhttp-xmux`).

## 4. Парсинг XHTTP-ссылок (Go, бэклог)

Де-факто стандарт линка (конвертер mihomo, `common/convert/v.go`): `extra=<url-encoded JSON>` с Xray camelCase:
```json
{"downloadSettings": {"address": "down.example.com", "port": 443},
 "xmux": {"maxConcurrency": 64, "maxConnections": 0, "cMaxReuseTimes": 0, "hMaxRequestTimes": 0},
 "xPaddingBytes": "100-1000"}
```
`core/parser/parser.go`: в `parseLink` после разбора query — если есть `extra`, `json.Unmarshal` (ошибка → игнорировать extra, не ронять весь импорт, как mihomo) и разложить по новым полям `OutboundSpec` (`DownloadAddress`, `DownloadPort`, `Xmux*`, `XPaddingBytes`). Остальное из extra (session placement и пр.) — игнорировать.

`core/control/plan.go`: `credentialDocument` пишет ключи `download_address`, `download_port`, `xmux_max_concurrency`, `xmux_max_connections`, `xmux_max_reuse_times`, `xmux_max_request_times`, `xpadding_bytes`; `applyCredential` читает обратно (int через `atoiNonNegative`). Путь импорта (`server.go: parsePayload → credentialDocument → vault → applyCredential`) подхватывает без изменений proto — тюнинг едет внутри credential-документа, не контракта.

Тест: ссылка с `extra=` → `OutboundSpec` с полями → `credentialDocument` → `applyCredential` → `engine.Transport` совпадает (round-trip).

## 5. UI (Dart, бэклог — SDK нет, только спека)

- **Редактор XHTTP** в карточке сервера (секция «Транспорт», видна при `type=xhttp`): mode (dropdown auto/packet-up/stream-up/stream-one) + предупреждение, что `stream-one` несовместим со сплитом; блок «Раздельный даунлинк» (адрес+порт, оба обязательны); `xPaddingBytes` (текст, плейсхолдер `100-1000`); xmux (`maxConcurrency` xor `maxConnections`, advanced-секция).
- **Варнинги**: коды `Warnings()` → локализованные строки; `xhttp-version-sync` — жёлтая плашка «убедитесь, что версия Xray на сервере совпадает»; `xhttp-xmux-proxy-limit` — при `maxConcurrency > 128`.
- **Запреты**: пара Vision+XHTTP и ws/httpupgrade+REALITY не дают сохранить сервер (текст ошибки из `validate.go`, не «что-то пошло не так»).
- **Честность выбора движка**: если план требует сплит/xmux, а доступен только sing-box — показать «нет движка для этого плана (нужен Xray/mihomo)», а не молча дропать настройки.

## 6. Честные ограничения (обязательно в UX и документации)

1. **sing-box-lx: нет downloadSettings и xmux** — архитектурно, не баг sora. Сплит и тюнинг — только Xray/mihomo.
2. **Версионный риск не детектируется**: sora не может узнать версию Xray на сервере; `xhttp-version-sync` — эвристика-напоминание, а не проверка.
3. **mihomo download-TLS inheritance** — выведено из исходников v1.19.32, но не гонялось на живом бинарнике; перед релизом прогнать `mihomo -t` на сгенерированном конфиге со сплитом.
4. **`xPaddingBytes` — не панацея**: паддинг виден как аномальный размер пакетов при статистическом анализе; это затруднение, а не невидимость.
5. **ALPN h3**: Xray реально дайлит QUIC только при `alpn: ["h3"]` ровно; при REALITY+h3 Xray игнорирует h3 (едет H2) — sora не варнит об этом отдельно, молчаливое поведение апстрима.
6. **Импорт `extra=` понимает только распознанные поля**; экзотика (session placement и т.п.) тихо отбрасывается — в UI показать «часть настроек ссылки не поддерживается», а не молчать (T012-паттерн).
