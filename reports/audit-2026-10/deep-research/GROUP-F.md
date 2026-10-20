# GROUP-F. Маршрутизация и файрвол — сводка третьего прохода

Лид группы F. Дата: 2026-10-20. 10 тем, файлы `51–60-*.md` в этом каталоге.
Первый проход (WEB-RESEARCH, тиры S/A/B): kill switch 3 уровня, mihomo rule-providers битые, GeoIP/GeoSite — не дублируется; здесь — механика до исходников и спеки.

## Ключевые находки прохода

1. **Тикающий баг в рендере sing-box:** `render.go:437` ставит `download_detour` у remote rule-set — поле deprecated в 1.14, **удаляется в 1.16.0** (замена: `http_clients` + `route.default_http_client`). Рядом `render.go:640` — `"stack": "mixed"` (удаляется в 1.17). Оба — поломка конфига на свежих движках, чинить парой.
2. **SRS/MRS — не оптимизация «когда-нибудь», а базовый гигиенический уровень 2026:** бинарь грузится в 10–250 раз быстрее текстового парсинга; sing-box (1.8+) и mihomo (`convert-ruleset`) оба умеют; community-конвенция — `interval: 86400`, `format: mrs`.
3. **mihomo молча ломается при mismatch behavior↔содержимое** — валидация обязана жить в генераторе sora, движок не поможет.
4. **WFP/nftables:** текущий гард sora-legacy — это Standard (динамические фильтры, снимаются крашем). Strict = persistent-фильтры (WFP `FWPM_FILTER_FLAG_PERSISTENT`, nftables `policy drop` + ранний systemd unit). Это разные реализации, а не «флажок».
5. **Xray слабее всех в rule-механике** (нет rule-set, только `ext:file:tag`), но у него есть `domainStrategy: IPIfNonMatch`, `geoip:private`, `process`-правила и балансировщики — достаточно для паритета.
6. **Captive portal при strict:** единственная честная модель — Speedify (scoped exception + явное согласие + авто-возврат); NordLayer «3 минуты без VPN» — анти-паттерн.
7. **RU-специфика подтверждена:** GitHub raw режется → апстрим sokudo + зеркала + скачивание гео/rule-set через detour/proxy, иначе автообновление — фикция.

## Ранжированные рекомендации

### P0 — чинить сейчас (баги/поломки на горизонте версий)
| # | Что | Откуда | Эффект |
|---|-----|--------|--------|
| F-P0-1 | Мигрировать `download_detour` → `http_clients`/`default_http_client` в sing-box рендере; убрать `"stack": "mixed"` | 51 | Конфиг не сломается на sing-box 1.16/1.17 |
| F-P0-2 | Валидация behavior↔содержимое и RULE-SET→провайдер при генерации mihomo-конфига, с понятной ошибкой до старта | 52 | Убирает класс «молча битых» конфигов |
| F-P0-3 | Xray-шаблон: `IPIfNonMatch` + `geoip:private → direct` первым правилом + явный catch-all (не «первый outbound») | 53 | Паритет роутинга, закрытие LAN-утечек на Xray-движке |

### P1 — ядро дифференциации (большой эффект, умеренная цена)
| # | Что | Откуда | Эффект |
|---|-----|--------|--------|
| F-P1-1 | Strict kill switch как отдельная реализация: nftables `policy drop` + systemd unit до сети; WFP persistent-фильтры в sublayer 0xFFFF | 55, 56 | Единственный честный strict; reboot-тесты проходятся |
| F-P1-2 | Свои .srs/.mrs при сборке (adblock, RU-пресеты) + remote rule-set `binary`/`mrs`, `interval 86400`, ETag, `size-limit`, скачивание через detour/proxy | 51, 52 | Старт ядра в разы быстрее, меньше RAM, живые списки |
| F-P1-3 | Geo-модуль: переключаемый апстрим (MetaCubeX/Loyalsoldier/sokudo/custom), автообновление 24ч с джиттером, SHA256, fallback на встроенные, UI-индикатор свежести | 54 | Независимость от GitHub в RU; честная свежесть баз |
| F-P1-4 | Captive-state machine: детект (canary + DHCP 114) → согласие → scoped exception TTL 15 мин → авто-возврат; при strict без согласия — ничего не открывать | 60 | Путешественники не ломаются; strict остаётся strict |

### P2 — укрепление (средний эффект)
| # | Что | Откуда | Эффект |
|---|-----|--------|--------|
| F-P2-1 | LAN-bypass: тумблер Выкл/Вкл/Авто-по-доверенной-сети + явные multicast-исключения (mDNS/SSDP/LLMNR); strict при дисконнекте блочит и LAN | 59 | Принтеры/Chromecast работают без дыр |
| F-P2-2 | Policy routing: отдельная таблица + fwmark + `blackhole default` как второй рубеж; анти-луп трафика движка по UID | 58 | Туннель лёг — трафик не уходит в main |
| F-P2-3 | BFE-конфликты (WFP): одна транзакция, retry, понятная ошибка про AV в UI; self-test kill switch с попыткой утечки | 55, 56 | Диагностируемость вместо «failed to apply firewall rules» |
| F-P2-4 | Android: системный Always-on + Block connections without VPN как kill switch; честное предупреждение про конфликт с LAN sharing | 58, 59 | Не изобретать велосипед на платформе |

### P3 — гигиена
| # | Что | Откуда |
|---|-----|--------|
| F-P3-1 | nftables — единственный бэкенд; grep-гейт на `iptables` в собственном коде в CI; zapret оставить вендорным в nft-режиме | 57 |
| F-P3-2 | Xray: `process: ["self/"] → direct` (анти-луп), `balancerTag` для групп серверов, `queryStrategy: UseIPv4` в RU | 53 |
| F-P3-3 | Не тащить GeoLite2-City; `country.mmdb` достаточно; превью гео-правил в UI | 54 |
| F-P3-4 | Кнопка «найти принтеры» (mDNS-browse) в диагностике LAN; `ip rule`/`table sora` в диагностике сети | 58, 59 |

## Что отсеяно фильтром «лучшее или слоп»
- Инлайн-тысячи `domain_suffix` в route.rules; legacy `geoip:`/`geosite:`-ресурсы sing-box; `classical` behavior для больших списков; `interval: 600` у rule-providers; `policy accept` для strict; динамические WFP-фильтры под видом strict; NordLayer-модель «3 минуты без VPN»; молчаливый авто-bypass портала при strict; TUN как default в main; собственный kill switch на Android поверх системного; GeoLite2-City в дистрибутиве; захардкоженный GitHub raw без зеркал.

## Связки с другими группами
- **Группа E (платформы):** Android VpnService (тема 48) ↔ 58/59/60 — per-app сплит, системный kill switch, captive portal на Android.
- **Группа D (движки):** sing-box TUN-стек 1.15+ (тема 41) ↔ 51 — rule_set уже на новом стеке; пин версий общий.
- **Группа A/B:** доверенные сети (F5-профили) ↔ 59 (LAN-bypass по доверию) и 60 (портал = untrusted).
- **Диагностика (общее):** self-test kill switch, свежесть геобаз, hitCount правил mihomo — всё это данные для экрана диагностики.

## Открытые вопросы к владельцу
1. Strict по умолчанию выключен (консервативно) или включён (максимум безопасности, риск «интернет сломался» у новичков)? Рекомендация группы: Standard по умолчанию, Strict — осознанный выбор с confirm-диалогом.
2. Собственное CDN-зеркало sora для геобаз/rule-set — закладывать в инфраструктуру 2026? Без него RU-автообновление зависит от community-зеркал.
