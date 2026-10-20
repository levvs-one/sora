# 52. mihomo rules: behavior, rule-providers, MRS, валидация

Группа F «Маршрутизация и файрвол», проход 3. Дата: 2026-10-20.
Не дублирует WEB-RESEARCH §8 (там — факт битого RULE-SET и план починки): здесь — механика до исходников.

## Находки

### 1. Три behavior — три разные структуры данных (исходники mihomo)
- `domain`: `DomainTrie` + `DomainSet` — высокоскоростной матчинг суффиксов/ключевых слов (`rules/provider/domain_strategy.go`).
- `ipcidr`: `IpCidrSet` — оптимизированные lookups по диапазонам (`rules/provider/ipcidr_strategy.go`).
- `classical`: список смешанных `C.Rule`, парсится стандартным `ParseRule` — полный синтаксис правил, **но внутри запрещены** `MATCH`, `RULE-SET`, `SUB-RULE` (проверяется в `classicalStrategy.payloadToRule`, `rules/provider/classical_strategy.go`). Классика — самая медленная.
- Константы форматов в `constant/provider/interface.go`: `yaml` (default, `payload:`/`rules:`), `text` (строка на запись), `mrs` (бинарный).

### 2. MRS — нативный бинарный формат mihomo
- `WriteMrs` сериализует `DomainSet`/`IpCidrSet` в бинарный поток, `FromMrs` десериализует **минуя дорогой текстовый парсинг**. Конвертер: `mihomo convert-ruleset`.
- Community-конвенция (конфиги 2025–2026): `behavior: domain, format: mrs` / `behavior: ipcidr, format: mrs`, `interval: 86400`. Classical — только `format: text` для малых смешанных наборов.
- Большие встроенные списки (adblock на сотни тысяч доменов) в yaml/text — это секунды парсинга на старте и лишний RAM; в MRS — миллисекунды.

### 3. Fetcher: как реально работает обновление (component/resource/fetcher.go, vehicle.go)
- На старте **сразу грузится локальный кэш** (если есть), затем фоновый pull-loop каждые `interval` секунд, если файл старше `interval`.
- `etag-support: true` в general-конфиге → отправляется `If-None-Match`, неизменённый контент не перекачивается (экономия трафика, важно на лимитных каналах).
- Ошибка фетча → экспоненциальный backoff минимум 10с; **предыдущая версия сохраняется** (stale-on-error из коробки).
- File-провайдеры не поллятся, а смотрят через `fswatch`.
- Ручное обновление: `PUT /providers/rules/:name`; API отдаёт по правилам `hitCount`/`missCount`/`hitAt` — готовая телеметрия для UI.

### 4. Поля rule-provider, важные для sora
- `type: http|file|inline`, `behavior`, `format`, `url`, `path` (ограничен HomeDir), `interval` (секунды), **`proxy`** — через какой прокси качать (критично: GitHub raw режется в RU/IR), **`size-limit`** — максимум байт, `0` = unlimited (защита от OOM при битом/враждебном URL), `header` — кастомные HTTP-заголовки.
- `geox-url`: переопределение URL для `geoip.dat`/`geosite.dat`/`country.mmdb` — штатный механизм зеркал (`geodata-mode: true`).

### 5. RULE-SET и ловушка behavior↔содержимое
- Правило `RULE-SET,<имя>,<политика>` делегирует матчинг провайдеру по имени через `tunnel.RuleProviders()`; параметры `no-resolve`, `src` поддерживаются.
- **mihomo не валидирует соответствие behavior содержимому**: domain-провайдер с IP-строками или ipcidr с доменами молча деградирует (правила не матчатся, ошибок нет). Это главный класс «молча битых» конфигов. sora обязан валидировать на этапе генерации с понятным сообщением.
- Состояние репо sora: `core/engine/mihomo/rules.go` уже содержит `registerRuleProvider`, `render.go:107`/`config.go:67` — секция `rule-providers` генерируется. Остаток работы — именно валидация и политика обновления (ниже).

## Вердикт: лучшее или слоп
- **Лучшее:** behavior `domain`/`ipcidr` + `format: mrs`; `etag-support: true`; `size-limit` всегда выставлен; `proxy` для скачивания через туннель/зеркало; `interval: 86400`; валидация behavior↔содержимое в генераторе.
- **Слоп:** `classical` для больших списков; `interval: 600` (DDoS апстрима,典型 в «ленивых» конфигах); отсутствие `size-limit`; скачивание rule-set напрямую с GitHub raw в RU без fallback.

## Рекомендация «внедрить так»
1. **Встроенные списки** (adblock, RU-пресеты, исключения банков): `type: file, behavior: domain|ipcidr, format: mrs`, .mrs прекомпилировать в CI (`mihomo convert-ruleset`), класть в дистрибутив.
2. **HTTP-провайдеры:** `interval: 86400`, `size-limit: 50MB`-порядка (по размеру набора), `proxy:` — через активный туннель/зеркало, `etag-support: true` глобально, только HTTPS. Stale-on-error уже в движке — не ломать.
3. **Валидация в plan:** при генерации проверять, что каждая строка провайдера соответствует behavior (домен vs CIDR vs правило), и что каждый `RULE-SET` ссылается на существующий провайдер. Ошибка — с именем провайдера и номером строки, до старта движка.
4. **Паттерн «блоклист минус вайтлист»:** `AND,((RULE-SET,ads),(NOT,(RULE-SET,ads-white)))` — выразить пресеты через провайдеры, а не инлайн-правила.
5. **UI:** индикатор свежести провайдера (дата последнего успешного обновления из кэша) + кнопка «обновить сейчас» (`PUT /providers/rules/:name`); опционально — hitCount из API для диагностики «правило вообще срабатывает?».
