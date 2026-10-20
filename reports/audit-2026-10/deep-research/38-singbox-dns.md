# 38. DNS в sing-box — правила, detour'ы, кэш, резолверы

Дата: 2026-10-20. Группа D «DNS», третий проход. По официальным докам sing-box (1.14) и коду sora `core/engine/singbox/render.go`. Найден вероятный баг рендера DoH3.

## 1. Формат DNS-серверов 1.12+ (legacy удалён в 1.14)

Типы: `udp tcp tls quic https h3 dhcp mdns fakeip local hosts tailscale openconnect openvpn resolved`. Ключевые отличия нового формата от legacy:

- `address_resolver`/`address_strategy` → **`domain_resolver` + `domain_strategy` в Dial Fields**;
- новый `https`/`h3` использует **dialer как outbound (эквивалент пустого direct) по умолчанию**, а legacy — default route, если не задан `detour`. Для sora это означает: proxy-only DNS в новом формате **требует явного detour** — иначе DoH пойдёт напрямую, засветив SNI провайдеру;
- `detour` остаётся в Dial Fields — работает, но семантика «по умолчанию» инвертирована относительно legacy.

**НАЙДЕНО (вероятный баг):** `render.go:515-523` рендерит DoH3 как `{"address": "h3://host:port/dns-query"}` **без поля `type`**. По докам: отсутствие `type` = legacy-формат, а legacy-формат **удалён в sing-box 1.14** (sora пинит 1.14.2 — `engine.go:19`). Комментарий в коде («DoH3 has no legacy type spelling») описывает поведение 1.12, а не 1.14. Правильно:
```json
{"type": "h3", "tag": "dns-1", "server": "9.9.9.9", "server_port": 443,
 "path": "/dns-query", "detour": "<proxy|direct>", "domain_resolver": "<bootstrap>"}
```
Проверить запуском `sing-box check -c` на 1.14.2: ожидается ошибка валидации текущего рендера. (Память упоминает «DNS h3:// downgrade fix» от network R&D — тот фикс был про mihomo `h3=true`; sing-box-рендер он не затронул.)

## 2. DNS-правила

- `dns.rules` — **first-match-wins**, `final` — сервер по умолчанию (у sora: `orDefault(remote, direct)` — корректно);
- правило `query_type: [A, AAAA] → fakeip` + исключения `domain_suffix → real` **перед** ним — текущая схема sora верна;
- `disable_cache` per-rule — обязательно для `rcode://` (блок-листы), иначе REFUSED закэшируется;
- `timeout` per-rule (с 1.14) — для канареечных пробов ставить короткий.

## 3. Кэш: что изменилось в 1.14

- **`independent_cache` deprecated в 1.14, удаление в 1.16** — не использовать (sora не использует — держать так);
- новое: **`optimistic`** (stale-while-revalidate, дефолт 3d) — включает «мгновенный» DNS при протухшем кэше; конфликтует с `disable_cache`/`disable_expire`;
- `cache_capacity` (LRU, <1024 игнорируется), `timeout` per-query (дефолт 10s);
- `client_subnet` — **не задавать** к публичным резолверам (см. 31);
- `reverse_mapping` — маппит IP→домен после резолва; **проблематично на macOS** (системный DNS-прокси+кэш) — по докам; для TUN+FakeIP не нужен (fakeip даёт реверс сам).

## 4. Route-правила и hijack-dns

- `{"protocol": "dns", "action": "hijack-dns"}` в route — перехват DNS в туннель; у sora уже первым правилом (render.go:398) — верно;
- `sniff` до hijack-dns — порядок sora корректен.

## 5. mdns (новое в 1.14)

Тип `mdns` — резолв через mDNS. Для FakeIP-исключений `.local` это естественнее, чем «реальный сервер»: mDNS-запросы вообще не должны уходить на upstream. Кандидат: правило `domain_suffix: ["local"] → mdns-сервер`.

## Вердикт: лучшее

Глубина деталей sing-box — лучшее: detour-семантика, domain_resolver, per-rule timeout/disable_cache — всё это прямые рычаги качества DNS в sora.

## Рекомендация: внедрить так

1. **Починить DoH3-рендер** под новый формат (`type: h3` + dial fields); прогнать `sing-box check` на 1.14.2; регресс-тест на формат.
2. **Proxy-only серверам всегда задавать detour явно** (новый формат не наследует default route).
3. `rcode://`-правилам — `disable_cache: true`.
4. Включить `optimistic` кэш (дефолт 3d) — бесплатная отзывчивость; не трогать `independent_cache`.
5. `.local` — рассмотреть `type: mdns` вместо upstream.
6. Документировать в коде инвариант: «hostname-сервер ⇒ domain_resolver=bootstrap (IP или local)».
