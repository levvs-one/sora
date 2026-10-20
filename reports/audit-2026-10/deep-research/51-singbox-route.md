# 51. sing-box route: правила, rule_set, бинарный SRS, geosite/geoip

Группа F «Маршрутизация и файрвол», проход 3. Дата: 2026-10-20.
Не дублирует WEB-RESEARCH §28–29 (NTP-bypass, split-DNS, tls_fragment, GeoIP-апстримы): здесь — механика rule_set до исходников и спеки.

## Находки

### 1. rule_set — замена legacy GeoIP/GeoSite с 1.8.0
- По официальному changelog sing-box 1.8.0: «rule-set is independent collections of rules that can be compiled into binaries to improve performance. Compared to legacy GeoIP and Geosite resources, it can include more types of rules, load faster, use less memory, and update automatically». Добавлены команды `sing-box geoip`, `sing-box geosite`, `sing-box rule-set` для миграции.
- Типы: `local` (format `source` = JSON, или `binary` = .srs) и `remote` (format `binary`/`source`, `url`, `update_interval`, `download_detour`). Remote скачивается при первом использовании, кэшируется локально, обновляется по `update_interval`.
- Загрузка rule-set в router идёт параллельно (concurrency 5, `route/router.go`).

### 2. SRS — бинарный формат: цифры
- Magic `SRSx` (0x53 0x52 0x53 0x78). Исходник — JSON schema `version: 2`, компиляция `sing-box rule-set compile`. Внутри: хэш-таблицы и radix-деревья для доменов, бинарные деревья диапазонов для IP, дедупликация строк.
- Замеры community (ad-list, sing-box-geosite4, 2025–2026): бинарь грузится в 10–250 раз быстрее текстового парсинга (small <1MB: 10–50x, large >10MB: 100–250x; пример: 8–10MB dns.txt парсится 500–1000мс / ~100MB RAM, .srs 12–15MB грузится 50–100мс / ~50MB RAM). JSON 4.1MB → SRS 642KB в одном из кейсов.
- Формат поддерживает memory-mapped доступ: zero-copy загрузка, ленивая подгрузка страниц.

### 3. Важное: `download_detour` deprecated в 1.14, удаляется в 1.16
- sing-box 1.14 ввёл топ-уровень `http_clients`; `download_detour` у remote rule-set заменён на `http_client`, `route.default_http_client` выбирает клиент по умолчанию. Legacy-поведение (system default outbound) deprecated, **удаляется в 1.16.0** (docs/deprecated.md).
- Факт по репо sora: `core/engine/singbox/render.go:437` до сих пор ставит `rs["download_detour"] = final`. На sing-box ≥1.16 конфиг с этим полем перестанет работать. Это тикающий баг, а не вкусовщина.
- Там же `render.go:640` — `"stack": "mixed"` (deprecated 1.15, удаляется в 1.17) — уже зафиксировано в WEB-RESEARCH §6, здесь подтверждаю из migration.md.

### 4. Официальные SRS-источники
- SagerNet/sing-geosite и SagerNet/sing-geoip — канонические бинарные наборы (`https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-<tag>.srs`). Имена с `@`: `geosite-category-games@cn` и т.п.
- `download_detour`/`http_client` должен указывать на outbound, через который качать: community-консенсус — качать через `direct` во избежание циклических зависимостей, но для RU (GitHub raw режется) — через прокси или зеркало (см. тему 54). sing-box позволяет `http_client` с `detour`.

### 5. Actions и порядок правил
- Actions: `route` (финальный), `route-options`, `sniff`, `resolve`, `hijack-dns`, `reject`, `bypass` (1.12+). Правила evaluated top-down, first match wins. `final` — outbound при отсутствии совпадений.
- `rule_set` матчится как условие внутри route/dns правил: `{"rule_set": ["geosite-cn"], "outbound": "direct"}`.

## Вердикт: лучшее или слоп
- **Лучшее:** remote rule-set в `binary` + собственные прекомпилированные .srs для встроенных списков (adblock, RU-пресеты) — измеримый выигрыш старта и памяти, автообновление из коробки.
- **Слоп:** инлайн-тысячи `domain_suffix` в `route.rules` (парсится каждый старт, жрёт RAM); legacy `geoip:`/`geosite:` ресурсы (deprecated upstream); `download_detour` — уже мёртв, держать его в рендере = баг на 1.16.

## Рекомендация «внедрить так»
1. **Мигрировать рендер сейчас:** заменить `download_detour` на `http_clients` + `route.default_http_client` (совместимо с 1.14+, обязательно для 1.16). Пин sing-box ≥1.15 (см. §6 WEB-RESEARCH).
2. **Свои наборы — в .srs при сборке:** adblock, RU-антицензурный пресет, банковские исключения — компилировать `sing-box rule-set compile` в CI, класть в дистрибутив как `local`/`binary`. JSON-исходники держать в репо для ревью.
3. **Remote rule-set для обновляемых:** `type: remote, format: binary, update_interval: 24h`, URL — через переключаемый апстрим (тема 54), скачивание через именованный http_client с detour на рабочий outbound (в RU — не direct к GitHub raw, а зеркало/прокси).
4. **`final` = selector «Прокси»** (уже частично есть, `render.go:399`), `auto_detect_interface: true` — оставить.
5. Валидация при генерации: каждый `tag` из `rule_set` в правилах обязан существовать в `route.rule_set` — ловить опечатки до старта движка.
