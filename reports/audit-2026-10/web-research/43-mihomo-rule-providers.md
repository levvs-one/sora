# Mihomo rule providers: лучшие практики (web research #43)

Дата: 2026-10-19. Источники: Meta-Docs wiki, mihomo source (через DeepWiki), clash-dev.com, clashsg.com, clash16.com, ssclash.com, community-конфиги и репозитории rule-сетов.

## 1. Что нашёл

### 1.1. Схема rule provider (mihomo)

Поля (rules/provider/parse.go, Meta-Docs): `type` (`file`/`http`/`inline`), `behavior` (`domain`/`ipcidr`/`classical`), `format` (`yaml`/`text`/`mrs`, default `yaml`), `path` (локальный кэш), `url`, `proxy` (исходящее соединение для скачивания), `interval` (секунды; поддерживаются и duration-строки типа `1h`, `5m`), `size-limit` (макс. размер ответа), `payload` (inline или fallback), `header` (кастомные HTTP-заголовки). Правила ссылаются провайдером строкой `RULE-SET,<name>,<policy>`.

Источники: https://deepwiki.com/nekrozis/mihomo/7.2-rule-providers-and-strategies, https://www.clash-dev.com/en/troubleshooting.html

### 1.2. Три стратегии (behavior) — это важно, behavior обязан совпадать с содержимым

- `domain` → `trie.DomainSet` (доменный trie, сегменты в обратном порядке; оптимален по памяти/поиску).
- `ipcidr` → `IPCIDRSet` (radix/BART-дерево; тысячи CIDR-блоков за O(префикс)).
- `classical` → список `C.Rule`, парсится обычным `ParseRule` (смешанные типы: DOMAIN-SUFFIX, IP-CIDR, GEOIP…). Для больших списков медленнее и прожорливее.

Если доменный список объявить как `ipcidr` — mihomo молча не сработает, ядро не исправляет это само. Ошибка валидации — на стороне клиента/конфига.

Источник: https://www.clash16.com/en/blog/articles/clash-premium-meta-mihomo-compared.html

### 1.3. Формат MRS — главный performance-приём

MRS (Mihomo RuleSet) — бинарный формат: сериализованные `DomainSet`/`IPCIDRSet` напрямую, без текстового парсинга и компиляции regex при загрузке. Результат: в разы быстрее старт ядра на больших списках и меньше RAM. Поддерживается только для `domain` и `ipcidr` (у `classical` MRS нет). Community-пайплайн: текстовый `+.domain.com`-список → сборка `.mrs` в GitHub Actions (пример: akashanahida/ad-list, ~438 878 доменов, сборка каждые 2 часа, ~2–5 МБ бинарник).

Источники: https://deepwiki.com/akashanahida/ad-list/2.3-mihomo-binary-format, https://deepwiki.com/akashanahida/ad-list/5.3-using-with-mihomoclash

### 1.4. Механика скачивания (component/resource/vehicle.go)

- ETag → условный GET (`If-None-Match`), 304 экономит трафик при отсутствии изменений.
- `size-limit` — защита от OOM на битых/враждебных URL.
- `proxy` — скачивание списка через указанный outbound (важно там, где raw.githubusercontent.com режется).
- `header` — кастомные заголовки (авторизация, User-Agent).
- `path` — локальный кэш; при недоступности сети/ошибке скачивания ядро продолжает работать на кэше.

Источник: https://deepwiki.com/nekrozis/mihomo/7.2-rule-providers-and-strategies (раздел Vehicle and Fetcher)

### 1.5. Интервал обновления: консенсус 86400

86400 (24 ч) — дефолт почти всех community-конфигов. «Чаще — не лучше»: лишние скачивания = лишняя работа на старте и сетевые запросы. 3600 уместен только для волатильных списков (прокси/подписки, но не правила). Для rule providers короче суток смысла почти нет — списки доменов/IP меняются медленно.

Источники: https://www.clashsg.com/en/blog/articles/mihomo-vs-classic-core.html, https://deepwiki.com/loyalsoldier/clash-rules/2.1-configuration-setup

### 1.6. Лучшие community rule-сеты

- **Loyalsoldier/clash-rules** — эталон: 13 файлов под `behavior` (reject, direct, proxy, private, apple, icloud, google, gfw, tld-not-cn — `domain`; cncidr, telegramcidr, lancidr — `ipcidr`; applications — `classical`). Рекомендует whitelist-режим: неизвестное → PROXY, explicit — что идёт напрямую. Порядок: специфичное раньше общего. https://deepwiki.com/loyalsoldier/clash-rules/2-user-guide
- **ACL4SSR** — классический шаблон/набор правил эпохи Clash, до сих пор референс для структуры конфигов (концепт «漏网之鱼» — отдельная группа для «непокрытого» трафика = осознанный выбор между whitelist и GFWList-режимом). https://gist.github.com/skywakener/7fe2a8d031d626d2bfb5b21c74214e26
- **anti-AD (privacy-protection-tools/anti-AD)** — adblock-домены как rule provider (`behavior: domain`), плюс парный белый список `anti-AD-white`, подключаемый через `AND,(AND,(RULE-SET,anti-AD),(NOT,((RULE-SET,anti-AD-white))))` — паттерн «блоклист минус вайтлист» логическими правилами mihomo.
- **GEOSITE/GEOIP** — встроенные категориальные базы mihomo (`GEOSITE,cn`, `GEOSITE,category-ads-all`, `GEOIP,CN`): одно правило покрывает тысячи доменов/IP, конфиг не раздувается. База mmdb обновляется вместе с ядром; клиенты обычно бандлят и периодически обновляют.

### 1.7. Порядок правил (best practice из clash-dev)

1. LAN/приватные подсети → DIRECT с `no-resolve` (чтобы IP-CIDR не триггерил DNS-резолв).
2. PROCESS-NAME правила.
3. Специфичное раньше общего: DOMAIN → DOMAIN-SUFFIX → RULE-SET/GEOSITE.
4. GEOSITE/GEOIP сворачивают «домашние» direct-правила вместо перечисления доменов.
5. MATCH всегда последний.

Источник: https://www.clash-dev.com/en/troubleshooting.html

### 1.8. Производительность при больших списках

- Плоские inline-правила матчатся за O(n) по числу правил; провайдеры с trie/BART — почти константа.
- Базовая память mihomo ~20–50 МБ; кэш конфига растёт с числом правил; YAML-списки на сотни тысяч строк заметно тормозят старт (парсинг) — лечится MRS.
- `classical` для больших списков — худший выбор; `domain`/`ipcidr` + MRS — лучший.

Источник: https://deepwiki.com/666OS/ClashMac/4.4-mihomo-proxy-core

## 2. Что sora должен перенять

Контекст по коду sora (только чтение): в `core/engine/mihomo/rules.go` тип `RULE-SET` замаплен (`engine.RuleRuleSet: "RULE-SET"`), но секция `rule-providers:` нигде не генерируется — в `plan.go` вообще нет понятия rule provider. То есть RULE-SET-правила сегодня ссылаются на несуществующих провайдеров: фича мертва/сломана.

| # | Что сделать | Почему | Эффект |
|---|-------------|--------|--------|
| 1 | Сгенерировать секцию `rule-providers:` в рендере mihomo-конфига (новый тип в plan: name/type/behavior/format/url/path/interval/proxy/header/size-limit). Сегодня RULE-SET — битая фича | Без этого вся тема rule providers в sora не работает в принципе | **high** |
| 2 | Валидировать пару behavior↔содержимое и behavior↔format до записи конфига (mihomo молча ломается при mismatch, например domain-список как ipcidr; у classical нет MRS) | Ловить ошибку на стороне sora с понятным сообщением, а не «правила не срабатывают» | **high** |
| 3 | Большие встроенные списки (adblock, пресеты RU/IR/CN) — `behavior: domain`/`ipcidr` + `format: mrs`; .mrs прекомпилировать при сборке sora или тянуть готовые | Быстрый старт ядра, меньше RAM, конфиг не раздувается тысячами строк. Прямой вклад в «лучший клиент» | **high** |
| 4 | HTTP-провайдеры: включить ETag (If-None-Match), выставить `size-limit` (~10–20 МБ), дать `proxy`-опцию для скачивания (GitHub raw режется в RU/IR), кастомный User-Agent через `header` | Экономия трафика, защита от OOM на битых URL, работа списков в цензурируемых сетях | **medium** |
| 5 | Stale-on-error как принцип: при ошибке обновления продолжать работать на кэше (`path`), показывать в UI «список устарел, N дней» вместо падения | Надёжность: VPN не должен ломаться из-за недоступного rule-хоста | **medium** |
| 6 | `interval: 86400` по умолчанию; кнопка «обновить сейчас» в UI; запрет интервалов < 1 ч для rule providers (подсказка в UI) | Консенсус community; защита от footgun'а «обновлять каждые 5 минут» | **medium** |
| 7 | URL rule providers — только HTTPS (консистентно с уже существующим HTTPS-only для подписок в sora) | Целостность правил маршрутизации = безопасность; MITM на rule-списке = перенаправление трафика | **medium** |
| 8 | Пресеты маршрутизации («Россия напрямую», «Иран» и т.д.) выразить через rule providers + GEOSITE/GEOIP вместо инлайн-списков; whitelist/blacklist-режим как у Loyalsoldier — переключателем в UI | Меньше кода генерации, списки обновляются независимо от релиза sora, понятная UX-семантика | **medium** |
| 9 | Бандлить и периодически обновлять mmdb (GEOIP) и geosite-базу, вынести в UI статус свежести | `GEOIP,CN`-style правила для RU/IR-пресетов; устаревшая база = неверная маршрутизация без видимых ошибок | **low** |
| 10 | Паттерн «блоклист минус вайтлист» через `AND`/`NOT` + два RULE-SET (как anti-AD/anti-AD-white) для адблока с исключениями | Пользовательский вайтлист поверх community-блоклиста без форка списка | **low** |

## 3. Источники

- Meta-Docs / mihomo source — provider schema, стратегии, vehicle: https://deepwiki.com/nekrozis/mihomo/7.2-rule-providers-and-strategies
- Meta-Docs — config basics, duration-строки: https://deepwiki.com/MetaCubeX/Meta-Docs/3-configuration-basics
- Loyalsoldier/clash-rules — user guide: https://deepwiki.com/loyalsoldier/clash-rules/2-user-guide
- Loyalsoldier/clash-rules — configuration setup: https://deepwiki.com/loyalsoldier/clash-rules/2.1-configuration-setup
- akashanahida/ad-list — MRS binary format: https://deepwiki.com/akashanahida/ad-list/2.3-mihomo-binary-format
- akashanahida/ad-list — using with mihomo: https://deepwiki.com/akashanahida/ad-list/5.3-using-with-mihomoclash
- clash-dev.com — config reference, порядок правил: https://www.clash-dev.com/en/troubleshooting.html
- clashsg.com — mihomo vs classic core, rule providers: https://www.clashsg.com/en/blog/articles/mihomo-vs-classic-core.html
- clash16.com — сравнение ядер, RULE-SET: https://www.clash16.com/en/blog/articles/clash-premium-meta-mihomo-compared.html
- ssclash.com — mihomo vs classic, providers: https://www.ssclash.com/en/blog/articles/mihomo-vs-classic-core.html
- ACL4SSR-стиль конфига (референс структуры): https://gist.github.com/skywakener/7fe2a8d031d626d2bfb5b21c74214e26
- Ресурсы mihomo (базовая память/overhead): https://deepwiki.com/666OS/ClashMac/4.4-mihomo-proxy-core
