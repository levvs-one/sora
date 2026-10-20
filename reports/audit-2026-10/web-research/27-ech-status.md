# Статус внедрения ECH (Encrypted Client Hello), 2025–2026

Дата исследования: 2026-10-19. ECH = шифрование ClientHello целиком (включая SNI) через inner/outer hello; ключ берётся из DNS HTTPS/SVCB-записи. RFC 9849 опубликован в марте 2026.

## 1. Что нашёл

**Клиентская сторона готова повсеместно**
- Chrome/Edge/Safari/Firefox включают ECH по умолчанию, никаких настроек не требуется (Firefox ≥119, `network.dns.echconfig.enabled`). [1][2]
- OpenSSL 4.0 получил нативную поддержку ECH (март 2026, shared mode). NGINX 1.29.4 — тоже. [3][6]

**Серверная сторона**
- Cloudflare — первый крупный провайдер: ~4.3 млн ECH-способных доменов (август 2026), общий outer SNI `cloudflare-ech.com`. На бесплатных тарифах отключить нельзя. [4][5]
- Доминирует в деплое; есть другие мелкие операторы. [4]

**Движки, которые использует sora**
- **sing-box**: клиентский ECH есть в TLS-настройках outbound (`"ech": {"enabled", "config", "config_path", "query_server_name"}`), с автоматическим retry при ECH-отказе (`RetryConfigList` из HelloRetryRequest). [7][9]
- **Xray-core**: клиентский и серверный ECH есть (Go ≥1.23; `transport/internet/tls/ech.go`): шифрование исходящего ClientHello, декрипт входящих, автополучение ECH-конфигов через DNS (DoH/H2C/UDP) + кэширование с TTL. Серверные ключи генерируются `xray tls ech --serverName`. [8][10]
- Влияет и на соседей: Xray задокументировал, что новые браузеры используют ECH — его собственный sniffing тогда видит только outer-домен. [11]

**Ограничения, критичные для VPN-клиента**
- ECH прячет только hostname, не IP: если у сервиса свой выделенный IP, пользы почти нет. [5]
- Требует шифрованного DNS (DoH/DoT): с plaintext-DNS hostname утекает ещё до TLS. [5]
- ТСПУ (РКН) **дропает ClientHello с ECH-расширением** в связке с outer SNI `cloudflare-ech.com` — блокировки начались в ноябре 2024 после включения ECH в Cloudflare по умолчанию. Само наличие ECH стало сигналом для фильтра. [5][12]
- GFW (Китай): не блокирует ECH-расширения целиком (на янв. 2025; старые ESNI-значения `0xffce` резались, новые ECH `0xff02–0xff04` — нет). Вместо этого давят на шифрованный DNS. [13][14]
- Фрагментация ClientHello и ECH теперь тоже детектятся ТСПУ: ГРЧЦ научил систему пересборке фрагментов и отлову TTL-несоответствий. [12]

**Конкуренты**: UI-поле для ECH есть в subscription-генераторах типа EdgeTunnel (для sing-box/Clash), [15]; ни один массовый VPN-клиент из анализа не делает ECH фичей-знаменосцем — это по-прежнему «инфраструктурная» настройка.

## 2. Что sora должен перенять и почему

Проверка кода: в `core/engine/` и `core/control/` упоминаний ECH нет (совпадения grep — ложные, подстрока в словах). Фичи нет ни для sing-box, ни для Xray, ни для mihomo.

1. **Проброс ECH-флага в конфиги sing-box и Xray outbounds** — обёртка над уже существующими опциями движков, не новая реализация протокола. Для sing-box: `tls.ech.enabled + config/query_server_name`. Для Xray: клиентский ECH через его штатный механизм с автополучением конфигов по DNS. UI: переключатель «ECH» на уровне сервера/подписки (по умолчанию off).
2. **Автопроверка пригодности**: ECH имеет смысл только когда hostname резолвится в shared-IP (CDN), ECH-конфиг есть в DNS, а клиентский DNS — DoH/DoT (sora уже имеет свой DNS-менеджер). Иначе — тихий fallback на обычный TLS. Это убирает главный UX-риск (сломанное подключение из-за невалидного конфига).
3. **Не позиционировать ECH как anti-DPI**: в РФ ECH-расширение — само по себе триггер блокировки; в Китае — риск меньше, но давят DNS. Для обхода DPI у sora уже есть REALITY/фрагментация/XHTTP. ECH — это приватность метаданных (SNI не видит пассивный наблюдатель/провайдер в «серых» сетях), а не инструмент прорыва цензуры.
4. **Осторожно с дефолтом**: включать ECH только явно или в «privacy-режиме», не глобально — иначе в РФ часть серверов станет недоступна.

## 3. Оценка эффекта

- **Проброс ECH в sing-box/Xray outbounds + UI-переключатель + автопроверка DNS/CDN-условий — medium.** Низкая стоимость (обёртка над готовыми опциями движков), реальная польза для приватности SNI в сетях без активного ECH-детекта; ни один конкурент не предлагает это удобно. Не решает обход блокировок в РФ (там ECH вреден), поэтому не high.
- **ECH как часть «privacy score» сервера (проверка: HTTPS-запись с ech= + DoH + shared IP) — low.** Приятный дифференциатор для продвинутых пользователей, но нишевый.
- **Собственный ECH-серверный режим / ECH-домены для подписок sora — low.** Имеет смысл только при своей CDN-инфраструктуре; у sora её нет.

## Источники

[1] https://www.makeuseof.com/every-browser-just-got-major-privacy-upgrade-most-people-dont-know-it/
[2] https://dev.to/weatherclockdash/encrypted-client-hello-ech-in-firefox-what-it-does-and-why-it-matters-3b7g
[3] https://medium.com/tls-port/the-eagle-has-landed-how-openssl-4-0-0-rewrites-the-rules-of-internet-security-40bac3f712aa
[4] https://netd.cs.tu-dresden.de/papers/mgsw-dechd-26.pdf
[5] https://ambientnode.uk/domain-fronting-ech
[6] https://secure.cisco.com/secure-firewall/v7.6/docs/encrypted-client-hello-defense-strategies-how-cisco-secure-firewall-tackles-ech
[7] https://sing-box.sagernet.org/configuration/shared/tls/
[8] https://deepwiki.com/XTLS/Xray-core/4.4-encrypted-client-hello-(ech)
[9] https://deepwiki.com/reF1nd/sing-box/5-advanced-features
[10] https://deepwiki.com/xeefei/X-Panel/7.3-ssltls-and-security-configuration
[11] https://xtls.github.io/en/config/inbound.html
[12] https://ateo.digital/blog/obhod-belyh-spiskov-kak-rabotaet/
[13] https://gfw.report/publications/usenixsecurity25/en/
[14] https://gfw.report/blog/gfw_esni_blocking/en/?ref=langton.cloud
[15] https://deepwiki.com/cmliu/edgetunnel/5-advanced-features
