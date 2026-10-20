# Web-research #42: Лучшие community-конфиги sing-box

Дата: 2026-10-19. Sora генерирует конфиги под sing-box ≥1.12 (`core/engine/singbox/render.go`). Проверено против текущего рендера.

## Источники

1. Официальная документация: `sing-box.sagernet.org` — TUN (`/configuration/inbound/tun/`), Rule Action (`/configuration/route/rule_action/`), Migration (`/migration/`), Changelog (`/changelog/`).
2. legiz-ru/sub2sing-box — модульные шаблоны linux/windows + `sing-box merge`: https://deepwiki.com/legiz-ru/sub2sing-box/6-configuration-reference , DNS: https://deepwiki.com/legiz-ru/sub2sing-box/6.1-dns-configuration
3. gitduk/box_for_magisk — конфиг с регионами/селекторами: https://deepwiki.com/gitduk/box_for_magisk/3.1-singbox-configuration
4. zipvpn/freevpnnodes — DNS-иерархия с bootstrap-цепочкой: https://deepwiki.com/zipvpn/freevpnnodes/5.3-sing-box-advanced-features
5. xxphantom/singbox-service — TUN-конфиг с локальными rule sets: https://deepwiki.com/xxphantom/singbox-service/3.1-tun-mode-configuration
6. Хабр: v2rayN + российские Geo-источники (runetfreedom): https://habr.com/en/articles/990178/
7. rpPH4kQocMjkm2Ve/infra — роутер с geoip-ru, geosite telegram/youtube: https://deepwiki.com/rpPH4kQocMjkm2Ve/infra/3.2-sing-box-router-configuration
8. vpnsmith: v2rayN с sing-box-ядром, нюансы DNS под Xray vs sing-box: https://www.vpnsmith.com/en/blog/v2rayn-sing-box-core

## Находки (что принято в сообществе)

### 1. Каноничный порядок route-правил
Почти все эталонные конфиги идут в порядке: **sniff → hijack-dns → NTP bypass (`port 123 → direct`) → private-IP direct → ads reject → geo/category rule sets → final**. Sora уже ставит `{"action":"sniff"}` и `hijack-dns` первыми (верно). Но общепринятые **NTP-bypass и явное `ip_is_private → direct`** в начало — у sora нет; отсутствие NTP-bypass ломает синхронизацию времени через прокси у ряда пользователей.
Ссылки: #7 (шаблон: sniff → hijack-dns → port 123 → direct), #2 (таблица паттернов).

### 2. Split DNS с bootstrap-цепочкой
Зрелые конфиги строят 4–5 серверов: `dns_proxy` (DoH/DoH3 через прокси), `dns_direct` (DoH3 `h3://dns.alidns.com/dns-query` напрямую), `dns_resolver` (IP-адрес `223.5.5.5`, bootstrap для остальных), `rcode://success` для рекламы, опционально fakeip. Ключевое — `address_resolver`/`domain_resolver`: имена хостов DNS-серверов резолвятся через IP-резолвер, иначе циклическая зависимость (прокси-домен резолвится через прокси-DNS). Sora уже делает bootstrap (`domain_resolver` на серверы по имени хоста) и `default_domain_resolver` — это соответствует практике. Чего нет: **готовых split-политик под пресеты** (RU-домены → локальный DoH3 напрямую, остальное → через прокси), флаг `independent_cache: true` на серверах, отключение кэша на rcode-сервере.
Ссылки: #4 (таблица иерархии DNS + independent_cache), #2 (3 сервера + 6 правил).

### 3. Remote binary rule sets (.srs) с download_detour
Все используют `type: "remote", format: "binary"` из `SagerNet/sing-geosite` и `SagerNet/sing-geoip`, с `download_detour` на прокси и `update_interval` (1h–24h). Sora так и делает (raw.githubusercontent.com, `download_detour = final`). Практические добавления из конфигов:
- **Обязательный ads rule set** `geosite-category-ads-all → reject` (dns+route) — у sora есть UI-блокировка рекламы, проверить, что она сводится к этим rule sets, а не списку доменов.
- **geoip/geosite-ru + сторонние RU-источники**: `github.com/runetfreedom/russia-v2ray-rules-dat` — агрегатор заблокированных в РФ доменов/IP (geoip+geosite для sing-box) — критично для пресета «Россия напрямую/всё через VPN». Хабр #6 документирует как v2rayN добавил региональный пресет «Россия» на этих источниках.
Ссылки: #2 (таблица rule sets), #6.

### 4. TUN: auto_redirect на Linux, gso мёртв
Официальные доки: на Linux `auto_redirect: true` «always recommended» — лучше маршрутизация, выше производительность, чем tproxy, нет конфликтов с Docker-мостами; `gso` deprecated 1.11, удалён 1.12. Sora: `stack: "mixed"` (ок), `auto_route: false` на Linux (свои nftables — ок), но `auto_redirect` не выставляется вообще. `stack` deprecated в 1.15 в пользу внутреннего стека — следить. Также практика: `route_exclude_address` для LAN и `exclude_interface: ["tailscale0"]` (конфликты с Tailscale — релевантно для «сосуществование с другими VPN»).
Ссылка: #1 (Tun).

### 5. Изменения 1.12–1.14, которые надо держать в голове
- Рефактор DNS-серверов в 1.12; **старые форматы удаляются в 1.14**; legacy `outbound` DNS-правила → `domain_resolver` (sora уже мигрировал); `independent_cache` deprecated в 1.14 → transport-keyed cache (не завязываться на него).
- Спец-outbound'ы `block`/`dns` deprecated 1.11 → rule actions `reject`/`hijack-dns` (sora уже мигрировал).
- Новое в 1.12: **TLS fragment route options** (`tls_fragment`, `tls_spoof` в `route-options`) — фрагментация TLS-handshake для обхода простых DPI; целевое применение точечно по SNI, не на всё.
- Новое в 1.13: action `bypass` (Linux + auto_redirect) — обход ядра на уровне nftables для pre-match; `reject` теперь умеет отвечать на ICMP.
- Deprecation-реестр: `experimental/deprecated/constants.go` — проверять при апгрейде версии движка.
Ссылки: #1 (Migration), #1 (Changelog 1.12.0-alpha).

### 6. FakeIP: стандарт и споры
Стандарт: `198.18.0.0/15` (IANA benchmarking), `cache_file.store_fakeip: true` (sora делает), короткий TTL. Trade-off из практики (Surge/FlClash): FakeIP убирает ожидание реального DNS перед установкой соединения и даёт правилам всегда видеть домен; redir-host проще, но медленнее старт. Для TUN-режима с доменными правилами FakeIP — дефолт сообщества. Нюанс: FakeIP-диапазоны надо исключать из bypass-правил для интранета (порядок правил!), иначе трафик на fake-IP уйдёт напрямую.
Ссылка: clash-iphone.com Fake-IP explainer (поиск #6).

### 7. Группы outbounds: urltest с фильтрами
Практика box_for_magisk: один главный `selector` + регионные `urltest`-группы с `filter` по ключевым словам в тегах + `tolerance`/`interval`. Sora уже генерирует selector/urltest; стоит перенять **регионные urltest-группы из коробки** (по странам серверов подписки), а не только один selector.
Ссылка: #3.

### 8. Модульные шаблоны + `sing-box merge`
sub2sing-box держит `templates/{linux,windows}/{dns,route,route_rule_set,inbounds}.json` и собирает `sing-box merge`. Для sora: версионировать эталонные JSON под каждую поддерживаемую версию sing-box (1.12/1.13/1.14) — страховка от deprecation-сюрпризов; `sing-box check -c` в CI на каждый рендер.

### 9. Мелочи из эталонов
- `{"action":"sniff"}` отдельным первым правилом (не флаг в inbound) — sora уже так.
- Блокировка QUIC/UDP:443 не консенсус; блок `geosite-category-ads-all` и в DNS (rcode), и в route — консенсус.
- `route.default_domain_resolver` — sora уже выставляет.
- UDP timeout'ы по сниффнутым протоколам (dns/ntp/stun 10s, quic/dtls 30s) — дефолты sing-box, трогать не надо.

## Что sora должен перенять

| # | Действие | Почему | Эффект |
|---|----------|--------|--------|
| 1 | Добавить в начало route: `{"port":[123],"action":"route","outbound":"direct"}` (NTP) и `{"ip_is_private":true}→direct` | Канон community; без NTP-bypass ломается время через прокси, private-правило защищает LAN до пользовательских правил | high |
| 2 | Подключить `geosite-category-ads-all.srs` (reject + rcode-DNS) как дефолтный ads-движок и добавить RU-источники `runetfreedom/russia-v2ray-rules-dat` для пресетов «Россия напрямую» / RU-домены | Лучшая практика блокировки рекламы; российские списки точнее sing-geosite для Рунета; v2rayN уже так делает (пресет «Россия») | high |
| 3 | Split-DNS политики из коробки по пресетам: RU/CN-домены → DoH3 напрямую, остальное → DoH через прокси; `independent_cache:true` на серверах, `disable_cache` на rcode | Убирает утечки DNS и гео-промах CDN; стандарт зрелых конфигов | high |
| 4 | На Linux выставлять `auto_redirect: true` в TUN (+ nftables pre-match), убрать зависимость от `gso` | Официальная рекомендация: быстрее tproxy, нет конфликтов с Docker-мостами; gso уже удалён в 1.12 | medium |
| 5 | Регионные `urltest`-группы с `filter` по странам из коробки поверх главного selector | Практика топовых конфигов; ускоряет выбор сервера и UX | medium |
| 6 | Точечный TLS-fragment через `route-options` (`tls_fragment`) для известных блокируемых SNI (совместно с zapret, не вместо) | Фича 1.12 для простых DPI; дешёвый дополнительный слой обхода | medium |
| 7 | `exclude_interface` для TUN (tailscale0 и др.) + `route_exclude_address` для LAN-диапазонов | Конфликты с Tailscale/другими VPN — заявленная фича sora «сосуществование» | medium |
| 8 | Версионировать эталонные конфиги под версии sing-box; `sing-box check` в CI; следить за `experimental/deprecated` при апгрейде (1.14 удаляет старые DNS-форматы и independent_cache) | Страховка от deprecation-сюрпризов при обновлении движка | medium |
| 9 | Не завязываться на `independent_cache` (deprecated 1.14); следить за deprecation `stack` (1.15→1.17) | Совместимость вперёд | low |

## Открытые вопросы
- Точный набор RU rule-set источников: сравнить свежесть `runetfreedom/russia-v2ray-rules-dat` vs `sing-geosite` (geosite-ru) — нужен замер актуальности списков.
- `auto_redirect` требует `nfnetlink_queue` в ядре — проверить доступность на целевых дистрибутивах sora (deb/rpm/Arch) и fallback.
