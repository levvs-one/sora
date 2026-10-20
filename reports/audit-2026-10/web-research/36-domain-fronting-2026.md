# Domain fronting: статус 2026

Дата исследования: 2026-10-19. Веб-источник: 7 поисковых запросов + дока провайдеров. Репозитории sora/sora-legacy только прочитаны.

## 1. TL;DR

Классический domain fronting (SNI ≠ Host на чужом мультитенантном CDN) **мёртв**: все крупные CDN запретили расхождение SNI/Host — Google/AWS ещё в 2018, Cloudflare ~2015, Azure 2022, Fastly ~2024. Реализовывать его в клиенте бессмысленно.

Живые практики 2026:
1. **Собственный CDN-фронт** — свой домен за Cloudflare/др. CDN (orange cloud), origin скрыт. В сообществе V2Ray-панелей это и называют «domain fronting» (дока Nexora).
2. **ECH (Encrypted Client Hello)** — RFC 9849 (март 2026). Клиентская поддержка уже есть во всех трёх движках sora (Xray, sing-box, mihomo). Но: Россия блокирует ECH к Cloudflare, Китай давит encrypted DNS, реальное использование мизерное.
3. **Underminr** (май 2026, ADAMnetworks) — злоупотребление shared edge IP CDN: 58–88 млн уязвимых доменов; режимы Simple / Split / ECH / Direct-to-IP. Подтверждает, что трюки с CDN-ребром живы, но это серверная/атакующая сторона.

## 2. Что нашёл (по источникам)

### 2.1. Классический fronting закрыт везде
- Google и AWS заблокировали в 2018 после громких злоупотреблений; Cloudflare — ещё раньше (~2015); Microsoft Azure — к концу 2022; Fastly — около 2024. Меньшие CDN и самописные reverse proxy теоретически ещё пропускают, но без «collateral damage» крупных CDN это не даёт защиты от цензора.
- Источники: https://ambientnode.uk/domain-fronting-ech , https://deepstrike.io/blog/what-is-domain-fronting , https://en.wikipedia.org/wiki/Domain_fronting

### 2.2. Практика провайдеров 2026: «фронт» = свой домен за CDN
Дока панелей (Nexora, https://docs.nexora-panel.org/use/fronting):
- Фронт — CDN-хостнейм, который набирает клиент вместо адреса ноды; CDN терминирует TLS и форвардит HTTP-запросы на origin.
- Работает только с транспортами, которые CDN несёт: **WebSocket, HTTPUpgrade, gRPC, XHTTP, HTTP/2**. НЕ работает: REALITY (свой сертификат инбаунда), Hysteria/Hysteria2/TUIC (QUIC/UDP), port hopping, raw TCP/AnyTLS/ShadowTLS.
- Трюк «wildcard-фронт» (`*.cdn.example.com`): каждый подписчик получает свой поддомен — блокировка одного имени бьёт по одному клиенту, а не по всем. Нужна wildcard DNS-запись и сертификат, покрывающий имя.
- «Only through a front»: инбаунд отдаёт в подписку только фронтовые записи, прямой IP ноды не светится.
- Заголовок реального IP клиента (`CF-Connecting-IP`, `True-Client-IP` Akamai, `Fastly-Client-IP`, `AR-Real-IP` ArvanCloud) — для лимитов устройств и логов.

### 2.3. ECH: стандарт есть, внедрение догоняет, цензоры уже бьют
- **RFC 9849 (март 2026)**, DNS-бутстрэп — RFC 9848. Клиент шлёт два ClientHello: внешний (публичный SNI, общий для многих) + зашифрованный внутренний с реальным SNI; ключ публикуется в DNS HTTPS-записи.
- Серверная сторона: Cloudflare — единственный крупный провайдер с ECH (включён по умолчанию в конце 2024); Fastly, Amazon, Akamai «ведут внедрение» (RSAC 2025). NGINX 1.29.4 (фев. 2026) и OpenSSL 4.0 — нативный ECH (пока только shared mode). Android 17 — платформенный ECH по умолчанию (Jigsaw/Google).
- Замеры Corrata (янв–мар 2025): ~10% топ-1M сайтов поддерживают ECH, но реально используют **0.06% соединений**; все внешние ClientHello несут один SNI `cloudflare-ech.com`. В топ-100 — 1% поддержки.
- **Россия**: с ноября 2024 TSPU режет ClientHello с ECH-расширением при SNI `cloudflare-ech.com` (подтвердил Роскомнадзор). **Китай**: блокировал ESNI (`0xffce`); новые ECH-значения (`0xff02–0xff04`) по замерам gfw.report не триггерят блок, но Китай давит encrypted DNS — без DoH/DoT ECH бесполезен (имя утекает в DNS). Иран — аналогично бьёт по encrypted DNS.
- Ограничения ECH: не прячет IP (бесполезен на выделенном IP), при недоступности — fallback на обычный TLS с открытым SNI, нужен зашифрованный DNS.
- Источники: https://www.vectra.ai/topics/encrypted-traffic-analysis , https://ambientnode.uk/domain-fronting-ech , https://gfw.report/blog/gfw_esni_blocking/en/?ref=langton.cloud , https://adguard-dns.io/sk/blog/encrypted-client-hello-misconceptions-future.html , https://www.engadget.com/2245189/google-deploys-support-encrypted-client-hello-on-android-17/

### 2.4. Underminr (май 2026) — CDN-ребро как вектор
ADAMnetworks: злоупотребление shared edge IP — резолвится доверенный домен, а TLS идёт с обманным SNI к другому домену на том же ребре. Режимы: Simple (обманный SNI после легитимного DNS), Split (сначала легитимный handshake для DPI, потом скрытое соединение), **ECH** (настоящий SNI в зашифрованном inner), Direct-to-IP (DNS вообще нет). Наблюдалось в дикой природе (APT Flax Typhoon через SoftEther VPN). 58 млн (консервативно) — 88 млн уязвимых доменов.
- Источники: https://cyberpress.org/leverage-shared-cdn-edge-ips/ , https://healsecurity.com/hackers-abuse-shared-cdn-edge-ips-to-bypass-protective-dns-filtering/

### 2.5. Поддержка в движках (важно: всё уже в коде, sora только не экспонирует)
- **Xray-core**: `transport/internet/tls/ech.go` — клиентский и серверный ECH, автополучение ECH-конфига по DNS (DoH/UDP), кэширование, CLI `xray tls ech`. Источник: https://xray-internals.hidandelion.com/transport/tls.html , https://deepwiki.com/XTLS/Xray-core/4.4-encrypted-client-hello-(ech)
- **sing-box**: outbound TLS — `ech { config, config_path, query_server_name }`, при пустом конфиге загрузка из DNS; `fragment` (с 1.12) и `disable_sni` уже есть; `sing-box generate ech-keypair`. Источник: https://sing-box.sagernet.org/configuration/shared/tls/
- **mihomo**: `component/ech`, ECH для VLESS/VMess/TUIC/Hysteria2 инбаундов и клиентский ECH (`transport/vmess/tls.go`); TLS-дока подтверждает опцию. Источник: https://wiki.MetaCubeX.one/en/config/proxies/tls/
- Практика конкурентов: NordVPN NordWhisper (Linux) — ECH в обфусцированном протоколе (2026); cryptostorm — Xray/REALITY; Amnezia — REALITY («крадёт» handshake легитимного сайта) + AmneziaWG, отдельного «hidden domain» не найдено.

### 2.6. Состояние в коде sora
Grep по `~/workspace/bug-hunt/sora` и `sora-legacy`: ни `fronting`, ни ECH в Go-коде нет (совпадения только в l10n-строках и доках zapret). Движки не вендорятся (скачиваются отдельно). Фрагментация TLS и uTLS в UI уже есть (по competitor-analysis).

## 3. Что sora должен перенять и почему

| # | Предложение | Почему | Эффект |
|---|-------------|--------|--------|
| 1 | **UI-переключатель ECH** для TLS-исходящих (VLESS/VMess/Trojan + TLS, Xray/sing-box/mihomo): опция «ECH: выкл / авто (DNS) / свой конфиг», с явным предупреждением о fallback на открытый SNI и требованием DoH | Поддержка уже есть во всех трёх движках — это тонкая обёртка над существующим кодом, а не новая криптография. Даёт скрытие SNI там, где ECH не блокируется (вне РФ/КНР против SNI-фильтров; свои серверы с NGINX 1.29.4+OpenSSL 4.0). NordVPN уже продаёт это как фичу (NordWhisper) — паритет с коммерцией | medium |
| 2 | **Раздельные поля SNI и HTTP Host** в редакторе сервера для ws / xhttp / gRPC / httpupgrade (сейчас, судя по коду, SNI берётся из адреса). Позволить SNI=CDN-хост, Host=другое имя — это и есть рабочий «фронтинг» 2026 через свой CDN | Без этого клиент не может использовать ни классический фронт (где ещё жив), ни wildcard-фронты провайдеров, ни связку «SNI фронтовой, Host реальный». Прямой запрос практики из док Nexora | medium |
| 3 | **Direct-to-IP режим**: поле «подключаться к IP» — dial на заданный IP (или резолв через DoH один раз и пин), SNI/Host отдельно. Закрывает Underminr-style «Direct-to-IP Mode» для легитимного использования и убирает DNS-утечку имени | Убирает имя сервера из plaintext-DNS; полезно в связке с ECH (иначе ECH бессмыслен) | medium |
| 4 | **Пресет «CDN-фронт» в мастере добавления сервера**: VLESS+WS+TLS (или XHTTP) с подсказками «проксируйте домен через Cloudflare (оранжевое облако), origin — ваш сервер; включите Only-through-front на панели». Плюс валидация: предупреждать, если выбран REALITY/Hysteria (несовместимы с CDN) | Копирует проверенный провайдерский флоу; снижает порог для self-hosted пользователей sora; конкуренты (v2rayNG/Hiddify) отдают это на откуп подпискам без объяснений | low–medium |
| 5 | **Опция «не отправлять SNI» (domainless)** для TLS-исходящих (sing-box `disable_sni` уже умеет; для Xray — через uTLS-вариант) с предупреждением о совместимости | Дешёвый трюк из Wikipedia-статьи; работает против части SNI-фильтров, где пустой SNI не блочится. Почти бесплатно | low |
| 6 | **Детектор «сервер за CDN» в диагностике**: по IP/заголовкам определять Cloudflare/Akamai/Fastly и подсказывать, что IP origin скрыт + ECH доступен (по HTTPS-записи) | Диагностическая ценность, ноль риска; помогает пользователю понять, почему сервер жив | low |

**Чего НЕ делать:**
- Не реализовывать классический fronting через чужие CDN (мёртв, плюс репутационные/ToS-риски).
- Не подавать ECH как «невидимость»: не прячет IP, в РФ режется по сигнатуре, в КНР требует DoH. В UI — честные предупреждения.
- Не смешивать ECH с REALITY: REALITY несовместим с CDN-терминацией (свой сертификат инбаунда), это альтернативные, а не комбинируемые механизмы.

## 4. Оценка эффекта для цели «лучший клиент»
- Ни один из 13 конкурентов в competitor-analysis не экспонирует ECH в UI (даже v2rayN с 10 движками). ECH-переключатель + раздельные SNI/Host + direct-to-IP — это дифференциатор уровня «первый среди опенсорсных клиентов», закрывающий паритет с NordWhisper.
- Совокупный эффект пакета: **medium** (не high: в главных цензурируемых юрисдикциях ECH частично нейтрализован, а CDN-фронт — в первую очередь серверная настройка провайдера).
- Стоимость: низкая — всё уже реализовано в движках, работа только в конфиг-мэппинге sora-core и Flutter-UI.
