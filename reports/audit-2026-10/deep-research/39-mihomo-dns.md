# 39. DNS в mihomo — nameserver-policy, fallback-filter, direct-nameserver

Дата: 2026-10-20. Группа D «DNS», третий проход. По коду mihomo (dns/resolver.go, dns/util.go, config/config.go — через DeepWiki-разборы) и рендеру sora `core/engine/mihomo/rules.go:buildDNS`.

## 1. Архитектура резолверов mihomo

Четыре контекста (component/resolver): **Default** (общие запросы + fake-ip), **ProxyServer** (имена прокси-серверов — анти-петля), **Direct** (direct-цели), **System** (bootstrap). Разделение — защита от циклических зависимостей: имя прокси-сервера нельзя резолвить через прокси, который ещё не поднят.

- `default-nameserver` — **только bootstrap** для hostname'ов DoH/DoT-апстримов; обязаны быть plain UDP/TCP; никогда не используются для обычных запросов. (В sora: `out.DefaultNameserver = firstNonEmpty(system, bootstrap, ...)` — проверить, что туда не попадают `https://` — по докам bootstrap обязан быть plain.)
- `nameserver` — основные; `batchExchange` **гонит все серверы наперегонки**, побеждает быстрейший не-ошибочный ответ. Вывод: в `nameserver` класть 2–3 резолвера одного класса (все через туннель или все прямые) — смешивание классов даёт недетерминированный путь.
- `proxy-server-nameserver` — резолв имён прокси-эндпоинтов (у sora маппится из ProxyOnly — верно).
- `direct-nameserver` (+ `direct-nameserver-follow-policy`) — резолв для direct-целей; при `follow-policy=true` наследует nameserver-policy.

## 2. fallback-filter — механика против отравления

`fallback` опрашивается, когда ответ primary «ненадёжен». Критерии (`dns/resolver.go:ipExchange`):
- `geoip: true` + `geoip-code: CN` — если IP ответа **не** из указанной страны → fallback (классика против китайского DNS-отравления: отравленный ответ даёт случайный/внутренний IP);
- `ipcidr` — совпадение IP с листом → fallback;
- `domain` / `geosite` — эти домены **сразу** идут в fallback, минуя primary.

Для RU-пресета: `geoip-code` под RU адаптируется плохо (идея фильтра — «мой провайдер врёт про чужие домены»; в RU подмена идёт по списку блокировок, а не по гео). Рабочий вариант для RU: `ipcidr` с bogon/заглушками провайдеров + `domain`-лист критичных доменов → fallback на туннельный DoH. Честно: fallback-filter — детект **отравления**, а не цензуры; блокировку по списку он не чинит.

## 3. nameserver-policy

Ordered map, **первое совпадение побеждает** (порядок объявления = приоритет). Ключи: plain-домен, `+.example.com`, `geosite:`, `rule-set:`. Внутри — trie (`domainTriePolicy`) для plain-паттернов.

Применение для sora: `{"+.ru": [direct-nameserver], "+.рф": [...]}` — split DNS из 35. Порядок: сначала исключения (банки/госуслуги → direct), потом общее правило.

## 4. Транспортные нюансы mihomo

- DoH: `https://host/dns-query`; `?h3=true` — **принудительный H3 без fallback** (sora так рендерит DNSH3 — поведение честное, но в UI должно быть подписано «без отката на H2»);
- `?skip-cert-verify=true` — для корпоративного MITM (у sora есть SkipVerify — верно);
- DoQ: `quic://host` (пул QUIC-соединений, 0-RTT);
- `dns-hijack: ["any:53"]` в TUN — перехват; `enhanced-mode: fake-ip | redir-host`;
- `ipv6` + `ipv6-timeout` — ожидание AAAA; при выключенном IPv6 — `ipv6: false`, иначе висяки.

## 5. Замечание по текущему рендеру sora

`out.Nameserver = firstNonEmpty(direct, remote, system, ...)` — смешивание direct и remote в одном `nameserver`-листе включает race между «напрямую» и «через туннель»: путь DNS становится недетерминированным, и половина запросов светит домены провайдеру. Правильно: `nameserver` — один класс (обычно remote/proxy-only), direct-резолверы — в `direct-nameserver` + `nameserver-policy`.

## Вердикт: лучшее

Четыре контекста резолверов и policy-механика — лучшее: именно так строится split DNS без петель. Слоп — сваливать direct+proxy серверы в один `nameserver` (недетерминированный путь).

## Рекомендация: внедрить так

1. Разделить: `nameserver` = proxy-only (один класс), `direct-nameserver` = прямые, `proxy-server-nameserver` = для имён прокси, `default-nameserver` = только plain UDP bootstrap.
2. `nameserver-policy`: `+.ru/+.рф` → direct; порядок «исключения → общее».
3. `fallback-filter` для RU: `ipcidr` bogon/заглушки + `domain`-лист → fallback на туннельный DoH (детект отравления, не цензуры — честно в доке).
4. `?h3=true` — только при явном выборе DoH3, с подписью «без отката».
5. `ipv6: false` при выключенном IPv6 в плане.
