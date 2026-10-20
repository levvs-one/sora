# Web-исследование #44: GeoIP/GeoSite — источники и практика

Дата: 2026-10-19.

## 1. Что сейчас в sora (по коду, `~/workspace/bug-hunt/sora`)

| Движок | Источник geo-данных | Формат | Обновление |
|---|---|---|---|
| Xray | `geosite:`/`geoip:` теги в правилах; dat-файлы общие с mihomo | `geoip.dat`/`geosite.dat` (V2Ray dat) | Только вместе с обновлением ядра — автообновления данных нет |
| mihomo | `geox-url` → `MetaCubeX/meta-rules-dat` releases (`geoip.dat`, `geosite.dat`), `geodata-mode: true`; локальные shipped-файлы без `geo-auto-update` по умолчанию; опционально `geo-auto-update: true`, `geo-update-interval: 24` ч | dat | 24 ч, только если включена опция `GeoData` |
| sing-box | remote rule sets с `SagerNet/sing-geosite` + `SagerNet/sing-geoip` (ветка `rule-set`, raw.githubusercontent), `format: binary`, скачивание через `download_detour: <final>` при старте | `.srs` | **нет `update_interval`** — обновление только при рестарте ядра |

Пресеты (`core/routing/presets.go`) используют geosite-категории `category-gov-ru`, `category-bank-ru`, `category-ru`, `tld-ru`, `yandex`, `vk`, `mailru`, `category-ir`, `cn`, `category-ads-all`. На sing-box они маппятся на URL вида `https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-<category>.srs`. RU-специфичные категории в sing-geosite не подтверждены веб-источниками (sing-geosite собирается строго из v2fly/domain-list-community) — при 404 URL sing-box молча оставит правило пустым. Проверить и при необходимости переключить RU-категории на проверенный источник — gap.

## 2. Источники geo-данных

### Loyalsoldier/v2ray-rules-dat + Loyalsoldier/geoip (де-факто стандарт экосистемы)
- Форматы: `geoip.dat`/`geosite.dat` (V2Ray), MaxMind `mmdb` (`Country.mmdb`), sing-box `srs`, mihomo `mrs`, Clash ruleset, Surge ruleset, Nginx allow/deny списки. Плюс `direct-list.txt` / `proxy-list.txt` / `reject-list.txt` (текстовые списки «напрямую/через прокси/реклама») — готовая основа для split-туннельных пресетов.
- Релизы: автоматические, еженедельно по четвергам (geoip); dat — daily. Дистрибуция: GitHub Releases + ветка `release` + CDN jsdelivr (`cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/...`), каждый файл с `*.sha256sum`.
- База: MaxMind GeoLite2 + патчи (CN IPv4/IPv6 от gaoyifan/china-operator-ip), плюс свои категории (`cloudflare`, `cloudfront`, `facebook`, `fastly`, `google`, `netflix`, `telegram`, `twitter`, `tor`).
- Источники: https://github.com/Loyalsoldier/v2ray-rules-dat, https://github.com/Loyalsoldier/geoip, https://pkg.go.dev/github.com/Loyalsoldier/geoip

### MetaCubeX/meta-rules-dat (эталон для mihomo)
- Ветка `sing` (в т.ч. `sing/geo/`) и `sing/geo-lite`: готовые `.srs` per-категория для sing-box (`geo/geosite-<name>.srs`, `geo/geoip-<name>.srs`) и `.mrs` для mihomo, плюс `geoip.metadb`, `GeoLite2-ASN.mmdb`, `geosite.dat`/`geoip.dat` для geodata-mode. Используется UUVPN, sbshell и др. как каноничный апстрим.
- mihomo поддерживает `geox-url` + `geo-auto-update: true` + `geo-update-interval` (часы) — автоматическое обновление dat/mmdb без рестарта.
- Источники: https://deepwiki.com/MetaCubeX/Meta-Docs/7.1-geox-configuration, https://deepwiki.com/nicolastinkl/UUVPN/7.2-geo-data-integration

### v2fly/geoip + v2fly/domain-list-community (апстрим)
- Ежемесячные сборки из DB-IP Lite (`0 0 5 * *`); `geoip.dat`, `cn.dat`, `private.dat`, каждый с `.sha256sum`; дистрибуция releases + ветка `release` + jsdelivr. GeoSite: `v2fly/domain-list-community` → `dlc.dat` (данные — отдельные файлы-категории в `data/`, включается `include:`).
- Менее богат категориями, чем Loyalsoldier; база только DB-IP.
- Источники: https://deepwiki.com/v2fly/geoip/7-build-and-release, https://deepwiki.com/v2fly/geoip/7.3-distribution-channels

### SagerNet/sing-geoip + sing-geosite (апстрим sing-box)
- Бинарные per-category `.srs` на ветке `rule-set`, URL-шаблон `.../rule-set/geosite-<name>.srs`. Собраны из v2fly-источников; RU-специфичных категорий в базовом наборе нет.
- Источники: https://github.com/SagerNet/sing-geosite, https://github.com/SagerNet/sing-geoip (URLs взяты из кода sora, проверены против документации sing-box)

### RU-специфичные источники (аудитория sora)
- `runetfreedom/russia-v2ray-rules-dat` (+ `russia-blocked-geoip`, `russia-blocked-geosite`): все категории v2fly + `geosite:ru-blocked` (antifilter-download-community + re:filter), `ru-blocked-all` (~700k доменов, осторожно), `ru-available-only-inside`, `category-ads-all` (переписанный, больше чем у v2fly), `win-spy`/`win-update`/`win-extra`. Есть утилита `geodat2srs` для конвертации в `.srs`. Разбор: https://habr.com/en/articles/990178/
- `itdoginfo/allow-domains` («Russia Inside»): категории block/geoblock/news/porn + RAW и `.srs` на релизах. https://deepwiki.com/itdoginfo/allow-domains/2-available-lists

## 3. Форматы

- `dat` — V2Ray/Xray, protobuf. Совместим с mihomo geodata-mode и GeoX.
- `srs` — sing-box binary rule set (быстрый матчинг, маленький размер). Генерится `sing-box rule-set convert` из JSON.
- `mrs` — mihomo binary rule set (`mihomo convert-ruleset`). GeoX (metadb) — mihomo-специфичный формат с multi-result (IP → несколько кодов), совместим с парсингом sing-geoip.
- `mmdb` — MaxMind; ASN.mmdb для ASN-лукапов. metacubex/geo CLI умеет конвертации между форматами, но MaxMind → Meta-geoip сознательно не поддерживается (юр. причины). https://pkg.go.dev/github.com/metacubex/geo
- Текстовые `direct/proxy/reject-list.txt` у Loyalsoldier — готовые списки для генерации правил/пресетов без парсинга dat.

## 4. Практика автообновления у клиентов

- v2rayN: ручное «Settings → Check for updates → Geo files», затем рестарт ядра. Автообновления geo нет. https://www.v2ray168.com/en/blog/articles/maintain-geoip-geosite-routing-data.html
- v2rayNG: управление своими ресурсными каталогами, встроенное обновление geo-ресурсов из приложения.
- mihomo: `geo-auto-update` + `geo-update-interval` (24 ч — де-факто стандарт конфигов).
- sing-box: remote rule sets с `update_interval` (в wild конфигах ставят 1 ч для часто меняющихся, 24 ч — разумный дефолт); без `update_interval` набор скачивается один раз при старте.
- Серверные скрипты (Xray-script): cron daily 6:30, скачивание из v2ray-rules-dat с проверкой размера, рестарт ядра.
- Правило надёжности: обновлять через staging (скачать → сверить sha256 → заменить → рестарт), никогда не заменять dat «на живую». Скачивание rule sets — через отдельный detour/outbound (у sora уже так: `download_detour = final`), чтобы не зависеть от текущего прокси.

## 5. Лицензирование MaxMind

- GeoLite2 по-прежнему бесплатен, но с 2019 г. требуется аккаунт + лицензионный ключ + подписанный EULA для каждой загрузки; ключи с 2023 г. протухают каждые 90 дней без реконфирмации email; в 2025–2026 комплаенс-команды массово отказываются от GeoLite2 из-за неоднозначности лицензии. Распространение готовой базы третьим лицам без ключа нарушает EULA.
- Вывод для sora: **никогда не шиппить и не раздавать готовые GeoLite2-mmdb**; использовать community-сборки (Loyalsoldier/MetaCubeX/v2fly), у которых лицензии уже урегулированы апстримом, и давать пользователю опцию «свой URL / свой ключ MaxMind» для тех, кому нужна точность GeoLite2. Источники: https://dev.to/nexgendata/ipinfo-got-expensive-maxmind-got-complicated-heres-the-00005-drop-in-that-needs-zero-setup-14ii, https://datahub.io/core/geoip2-ipv4

## 6. Что sora должен перенять

1. **`update_interval` для sing-box remote rule sets (high).** Сейчас `.srs` качаются один раз при старте ядра и стареют до рестарта. Добавить `update_interval: 24h` (а лучше настраиваемый, 1–24 ч). Эффект: правила блокировки рекламы и RU-обходы не деградируют со временем; ноль UX-изменений.
2. **Автообновление Xray dat-файлов (high).** Сейчас geoip/geosite.dat у Xray обновляются только с ядром. Добавить фоновый апдейтер: скачать с Loyalsoldier releases → сверить `.sha256sum` → staging → hot-reload ядра (Xray перечитывает dat при рестарте; проверить поддерживает ли используемая версия reload без разрыва — иначе обновлять между переподключениями). Дефолтный интервал — 24 ч, опция в UI с датой последнего обновления.
3. **Включить `geo-auto-update` у mihomo по умолчанию, а не опционально (medium).** Сейчас интервал 24 ч есть, но только если пользователь включил `GeoData`. Сделать дефолтом `true` с тумблером в UI — паритет с ожиданиями (mihomo-конфиги в wild все так делают).
4. **Единый переключаемый источник geo-данных + кастомный URL (medium).** Дать выбор апстрима: Loyalsoldier (богатые категории + списки direct/proxy/reject), MetaCubeX, v2fly, runetfreedom (RU) — плюс поле «свой URL». Сегодня источник зашит в коде per-движок. Эффект: RU-аудитория получает актуальные `ru-blocked`/`category-ads-all`, юзеры в CN — свои категории; снимает риск 404 на RU-категориях sing-geosite.
5. **Проверить и зафиксировать RU-категории для sing-box (medium).** Пресеты используют `category-gov-ru`/`category-bank-ru`/`category-ru`/`tld-ru` — подтвердить их наличие в выбранном источнике `.srs` (у SagerNet их, вероятно, нет) или маппить на эквивалент (напр. runetfreedom через geodat2srs, или свои компилированные `.srs`). 404 remote rule set в sing-box = тихое неработающее правило.
6. **Использовать текстовые списки Loyalsoldier для пресетов split-tunneling (medium).** `direct-list.txt`/`proxy-list.txt`/`reject-list.txt` — готовые, обновляемые списки; из них можно генерировать пресеты и правила «Россия напрямую» без ручного курирования доменов.
7. **UI: статус geo-данных (low).** Показывать источник, версию/дату сборки и кнопку «обновить сейчас» в настройках маршрутизации. v2rayN так делает (ручной апдейт) — у sora это станет видимым плюсом при автообновлении.
8. **ASN.mmdb для экрана соединений (low).** MetaCubeX раздаёт `GeoLite2-ASN.mmdb` — пригодится для обогащения UI мониторинга соединений (организация/ASN), когда он появится (P1 в roadmap).
9. **Не делать:** шиппить GeoLite2-mmdb в дистрибутив; тянуть dat напрямую с MaxMind без ключа; автообновление чаще раза в сутки для dat (нагрузка на апстрим, выше риск сломанного релиза — держать откат на предыдущую копию).
