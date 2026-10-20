# Web-research #41: Экосистема v2ray-плагинов и расширений

Дата: 2026-10-19. Тема: что живёт вокруг v2ray/Xray/sing-box/mihomo — гео-данные, rule-sets, плагины протоколов, скрипты, менеджеры подписок, telegram-экосистема — и что перенять в sora (учитывает F10: `.soraext`, `core/ext`, `docs/extensions/manifest-v1.md`).

## 1. Гео-данные (фундамент маршрутизации)

- **Loyalsoldier/v2ray-rules-dat** — де-факто стандарт усиленных `geoip.dat`/`geosite.dat`. Ежедневный rebuild через GitHub Actions (6:00 Beijing), экстра-категории: `geoip:telegram`, `geoip:netflix`, `geoip:cloudflare`, `geoip:tor`, `geoip:cloudfront` и др.; CN-диапазоны из gaoyifan/china-operator-ip. Совместим с V2Ray, Xray, mihomo, hysteria, Trojan-Go, leaf. ([README](https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/master/README.md))
- **Loyalsoldier/geoip** — генератор гео-данных сразу в 6+ форматах: V2Ray dat, MaxMind mmdb, **sing-box SRS**, **mihomo MRS**, Clash ruleset, Surge ruleset. Один пайплайн → все движки. Критично для sora с её 3 движками. ([api.github.com/users/vboy1010/starred](https://api.github.com/users/vboy1010/starred))
- **Исходники**: `v2fly/geoip`, `v2fly/domain-list-community` (официальные, беднее категориями).
- **Зеркала для цензурируемых регионов**: `v2rayA/dist-v2ray-rules-dat` — авто-синк релизов Loyalsoldier в отдельный репо (weekly workflow).
- **Как клиенты обновляют**: v2rayN — Settings → Check for updates → Geo files; Exclave/NekoBox (Sagernet-семейство) — экран AssetsActivity с **выбором провайдера** (0=v2fly, 1=Loyalsoldier, 2=Chocolate4U/Iran-v2ray-rules, 3=custom URL) + импорт файлом. ([deepwiki](https://deepwiki.com/dyhkwong/Exclave/5.2-asset-management))
- OpenWRT-пакеты (`v2ray-geodata-updater`): скачивание + **проверка SHA256** + cron + fallback через прокси-зеркала. ([deepwiki](https://deepwiki.com/ridesnails/OpenWRT-CI/5.2-geodata-and-routing-intelligence))
- Xray-core сам тянет `Loyalsoldier/v2ray-rules-dat` в CI-релизах с валидацией SHA256. ([deepwiki](https://deepwiki.com/XTLS/Xray-core/1.3-ecosystem-and-distribution))
- Практика обслуживания (v2ray168): обновлять по одному ресурсу за раз, держать reproducible test-запросы (direct/proxy/LAN) до и после. ([статья](https://www.v2ray168.com/en/blog/articles/maintain-geoip-geosite-routing-data.html))

## 2. Rule-sets (обновляемые наборы правил поверх гео-данных)

- **Loyalsoldier/clash-rules**: `reject.txt` (ads/tracking), `proxy.txt`, `direct.txt` — ежедневно, раздача через jsdelivr. Классический `rule-providers` в Clash: `type: http, behavior: domain/ipcidr/classical, interval: 86400`, локальный кэш, при ошибке — старая версия. ([clashhelp](https://www.clashhelp.com/en/docs.html))
- **MetaCubeX/meta-rules-dat**: бинарные **.srs** (sing-box) и **.mrs** (mihomo) по категориям: `apple`, `google`, `telegram`, `netflix`, `openai`, `cn`, `proxy`, `gfw`… URL-паттерн `…/meta-rules-dat/{sing|meta}/geo/{geosite|geoip}/{category}.{srs|mrs}`. ([Meta-Docs](https://deepwiki.com/MetaCubeX/Meta-Docs/7.2-rule-set-configuration), [пример .srs](https://github.com/MetaCubeX/meta-rules-dat/blob/sing/geo/geosite/0x0.srs))
- **ACL4SSR**: ~27 текстовых ruleset'ов по сервисам (Telegram, YouTube, Steam, OpenAI, Apple, Microsoft…) — `RULE-SET,name,policy`.
- **Конвертеры**: `sing-box rule-set convert` (текст → .srs, валидация на этапе компиляции, быстрый lookup); `metacubex/meta-rules-converter` (Go-библиотека, `SaveSingRuleSet`). ([pkg.go.dev](https://pkg.go.dev/github.com/metacubex/meta-rules-converter/output/sing))
- **mihomo rule-providers**: автообновление по `interval`, ручной триггер через API `PUT /providers/rules/:name`, при фейле — кэш.
- **Sub-Store templates для sing-box** (xishang0128/sub-store-template): готовые конфиги, тянущие MetaCubeX .srs через CDN-зеркала (ghfast.top) с `download_detour: direct`. ([deepwiki](https://deepwiki.com/xishang0128/sub-store-template))

## 3. Плагины протоколов (расширение движка без пересборки)

- **Sagernet Android plugin contract** (NekoBox, SFA, Matsuri): плагин = отдельное APK с `ACTION_NATIVE_PLUGIN` intent-filter и `METADATA_KEY_ID` (напр. `naive-plugin`); бинарник отдаётся через `ContentProvider`/`BinaryProvider` с правами 0755; хост исполняет его как subprocess. Существующие: **NaïveProxy Plugin, Hysteria Plugin, Mieru Plugin, Trojan Plugin, Socks5 Plugin, SocksTun**. ([deepwiki](https://deepwiki.com/btwiuse/yass-nekobox-plugin/3-android-plugin-architecture), [openapk](https://www.openapk.net/sing-box/io.nekohasekai.sfa/))
- **nekoray**: custom core — подмена бинарника ядра целиком (грубее, но гибко).
- **sing-box libbox**: `PlatformInterface` (gomobile) — embedding ядра в чужие приложения; официальный SFA/SFI/SFM построены на нём.
- **singbox_mm** (pub.dev, 2026): Flutter-плагин — sing-box runtime bridge + парсер share-ссылок + split-tunnel + anti-throttling пресеты. Прямой референс для Android-клиента sora. ([changelog](https://pub.dev/packages/singbox_mm/changelog))

## 4. Скрипты и request-модули (iOS-экосистема Surge/Loon/QuanX/Shadowrocket)

- **Форматы**: Surge `.sgmodule`, QuantumultX `[rewrite_local]`/`[task_local]`, Shadowrocket modules; все — URL-паттерн + JS, автообновление по `update-interval`.
- **Script-Hub**: конвертер скриптов между платформами (QuanX/Surge/Loon → Shadowrocket) — один скрипт работает везде.
- **BoxJs**: персистентное хранилище настроек скриптов + веб-дашборд + синхронизация между устройствами.
- **Легитимное ядро, которое стоит перенять**: utility-скрипты `event-interaction` — проверка разблокировки стримингов, GeoIP-запрос, **проверка чистоты IP узла**, детект цензуры; репозитории правил **blackmatrix7/ios_rule_script** (5 платформ, тиры поддержки) и **Johnshall/Shadowrocket-ADBlock-Rules-Forever**.
- ⚠️ Большая часть этой экосистемы — app-unlock/cookie-capture скрипты (пиратство). Механики перенимать, контент — нет.

## 5. Менеджеры подписок

- **Sub-Store**: подписки как программируемый пайплайн — merge нескольких подписок, filter/include-exclude, rename по regex, cron-обновление, выдача единого результата в Shadowrocket/Surge/Loon/QuanX/sing-box.
- **subconverter / subconverter-rs (WASM)**: `GET /sub?target=clash&url=…&include=HK|SG&emoji=true&udp=true` — конвертация любого формата подписки в Clash/Surge/QuantumultX, склейка нескольких URL (`url=a|b`), внешний ini-конфиг. Есть чисто клиентский WASM-вариант без отправки ссылок на сервер. ([API](https://deepwiki.com/lonelam/subconverter-rs/6-api-reference))
- **Clash Verge Rev**: **Merge-профили** (`prepend-rules`/`append-rules`/`prepend-proxies`) + **Script-профили** (`function main(config) { … return config; }` на JS — фильтрация узлов по региону, авто-добавление url-test групп). Цепочка приоритетов фиксирована: подписка → правки подписки → global Merge → global Script → ядро. ([clash-dev](https://www.clash-dev.com/en/troubleshooting.html), [clashhelp](https://www.clashhelp.com/en/docs.html))
- **proxy-providers** (mihomo): несколько подписок как провайдеры узлов в одном конфиге, `use:` в группах, `filter`/`exclude-filter`, `override.additional-prefix`. ([clash911](https://www.clash911.com/en/config-guide.html))
- **Karing**: единый набор правил поверх нескольких подписок (уже отмечено в competitor-analysis).
- Боль подписок, признанная экосистемой: обновление подписки **затирает** пользовательские правки — отсюда весь слой override. ([clash-code](https://www.clash-code.com/en/blog/articles/multi-device-config-sync.html))

## 6. Telegram-экосистема (панели, боты, распространение)

- **Remnawave** (панель, Xray JSON — sora уже поддерживает): REST API + subscription-page + Telegram-боты: **remnashop** (aiogram + celery + платежи + подписки) и **remnawave-limiter** (алерты о превышении лимита устройств с inline-кнопками действий). ([remnashop](https://deepwiki.com/snoups/remnashop/3-external-integrations), [limiter bot](https://deepwiki.com/syvlech/remnawave-limiter/5-telegram-bot-interface))
- **Marzban / 3x-ui** — панели-стандарты выдачи vless/vmess/trojan подписок; TG-боты при них — основной канал «продажа → выдача конфига → инструкция».
- **Боты-генераторы** (@vpngeneratorbot и аналоги): self-hosted генерация конфигов через bot-интерфейс — массовый онбординг неопытных пользователей.
- Паттерн: deep-link из бота (`vless://…`, `https://t.me/…?start=`) → импорт в клиент в один тап.

---

## Что sora должен перенять

### 1. Менеджер гео-данных и rule-sets с автообновлением — эффект HIGH
Встроить в клиент экран «Активы» (как AssetsActivity у Sagernet): выбор провайдера гео-данных (v2fly / Loyalsoldier / custom URL), кнопка «обновить», расписание, SHA256-проверка, кэш + откат на старую версию при ошибке. Отдельно — подписка на внешние **rule-providers** (ads, proxy/direct категории) в форматах `.dat`/`.srs`/`.mrs` под каждый из 3 движков (Loyalsoldier/geoip даёт все форматы из одного пайплайна — брать его за upstream). Почему: правила маршрутизации протухают быстрее всего; у конкурентов это уже гигиена, у sora — статичные пресеты. Плюс reproducibility-тест (direct/proxy/LAN) после обновления.

### 2. Встроенный конвертер подписок (subconverter-класс) — эффект HIGH
Нормализация любой подписки (base64 URI-list, Clash YAML, Xray JSON, SIP008) в конфиг любого из 3 движков + фильтры include/exclude + переименование узлов. У sora мульти-движок с автовыбором — конвертер снимает проблему «подписка провайдера не дружит с выбранным движком». Референс: subconverter-rs, есть WASM-вариант — конвертация локально, ссылки не уходят наружу (важно для приватностного позиционирования).

### 3. Слой override поверх подписки: Merge + Script — эффект HIGH
Формализовать F6 (subscription override layer) по образцу Clash Verge: `prepend-rules`/`append-rules`, `prepend-proxies`, и скриптовый слой `main(config)` (JS-движок уже есть в планах расширений — переиспользовать). Фиксированная цепочка приоритетов, видимая пользователю. Почему: это главная боль экосистемы подписок — обновление затирает правки; у sora JSON-подписки Remnawave идут «как есть», своих правок поверх нет.

### 4. Rule-set пакеты как тип расширения `.soraext` — эффект MEDIUM
Новый тип расширения в F10-манифесте: `kind: "ruleset"` — подписанный набор правил (домены/IP/категории) с `update_url` и интервалом. Даёт community-каталог: RU-специфичные наборы (банки/госуслуги напрямую), ads-списки, стриминги. Подпись minisign уже есть в F10 — переиспользовать. Почему: бутстрапит экосистему без кода в ядре; правила — самый безопасный тип расширений (нет произвольного кода).

### 5. Диагностические utility-расширения (чистота IP, unlock-check, детект цензуры) — эффект MEDIUM
Легитимная часть QuanX-экосистемы (`event-interaction` скрипты) как готовые `.soraext`-панели: проверка разблокировки стримингов через выбранный узел, IP purity score, быстрый тест «что видит провайдер». Ложится на уже построенный ExtensionHost + панели. Почему: дифференциатор — ни один десктопный v2ray-клиент такого из коробки не даёт, а у sora уже есть встроенные speedtest-сайты — это следующий шаг.

### 6. Telegram-интеграция: импорт и шеринг — эффект MEDIUM
One-tap импорт конфига/подписки из TG-бота (обработка `https://t.me/<bot>?start=<payload>` deep-link'ов, QR в чате бота), официальный sora-бот для шеринга подписки между своими устройствами (мостик к F9 E2E-синку). Плюс нативная поддержка выдачи панелей Remnawave/Marzban/3x-ui (Xray JSON уже есть — добавить автоопределение панели по URL). Почему: в RU/Иран-экосистеме Telegram — главный канал распространения конфигов; конкуренты (Amnezia QR-шеринг) это уже эксплуатируют.

### 7. Плагины протоколов для десктопа (Sagernet-контракт) — эффект MEDIUM
Механизм внешних outbound-плагинов: отдельный исполняемый файл + манифест, общение с core по IPC/gRPC (рядом с ext_host.proto). Позволяет добавлять экспериментальные транспорты без пересборки sora-core и без раздувания бинарника. Почему не high: sing-box/Xray/mihomo покрывают ~всё актуальное; ценно как страховка на будущее (новые DPI-обходы появляются быстрее релизов ядер).

### 8. BoxJs-подобное хранилище настроек расширений — эффект LOW
Персистентные настройки `.soraext` с UI-формой из манифеста + участие в F9-синке между устройствами. Маленькая фича, но без неё расширения остаются игрушкой. Сделать вместе с каталогом расширений.

## Не перенимать
- App-unlock/cookie-capture скрипты iOS-экосистемы (пиратство, юридические риски).
- Подмену ядра целиком (nekoray custom core) — противоречит модели подписанных движков sora.
- Централизованный Sub-Store-сервер — только локальный пайплайн (приватность).

## Приоритетный порядок (предложение)
1. Менеджер гео-данных + rule-providers (п.1) — фундамент маршрутизации.
2. Конвертер подписок (п.2) + Merge/Script override (п.3) — закрыть боль подписок до выхода Android.
3. `kind: ruleset` в F10 (п.4) + первые party-пакеты от команды sora.
4. TG-импорт/шеринг (п.6) — дешёвый рост распространения.
5. Utility-расширения (п.5), хранилище настроек (п.8), плагины протоколов (п.7) — по мере зрелости каталога.
