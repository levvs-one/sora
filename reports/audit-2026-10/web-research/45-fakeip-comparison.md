# 45. FakeIP: сравнение реализаций (sing-box vs mihomo)

Дата: 2026-10-19. Источники: официальная документация sing-box, DeepWiki-разборы кода mihomo, гайды Clash-сообщества (2025–2026). Репозитории sora/sora-legacy читались только (grep), код не правился.

## 1. Как устроен FakeIP в двух движках

| Аспект | sing-box (≥1.12) | mihomo (Clash-наследие) |
|---|---|---|
| Формат конфига | DNS-сервер `"type": "fakeip"` в `dns.servers` (новый формат с 1.12; legacy-блок `dns.fakeip` deprecated в 1.12, **удалён в 1.14**) | Блок `dns:` с `enhanced-mode: fake-ip`, `fake-ip-range`, `fake-ip-filter` |
| Диапазон по умолчанию | IPv4 `198.18.0.0/15`, IPv6 `fc00::/18` | IPv4 `198.18.0.1/16` (обратить внимание: **/16**, не /15) |
| Маршрутизация по домену | Реверс-маппинг fake-IP→домен выполняется ядром автоматически; route-правила `domain`/`domain_suffix` матчатся без реального резолва | Аналогично: `tunnel.preHandleMetadata` → `resolver.FindHostByIP`, `DstIP` очищается, outbound получает только домен |
| Фильтр исключений | **Нет встроенного аналога fake-ip-filter** у fakeip-сервера; исключения делаются DNS-правилами (домен → реальный сервер) до catch-all правила | `fake-ip-filter` (домены получают реальный IP) + `fake-ip-filter-mode: blacklist` (дефолт) / `whitelist` |
| Персистентность маппингов | `experimental.cache_file.store_fakeip` | `profile.store-fake-ip` (cache.db) |
| Пул/коллизии | — | Последовательное выделение O(1), при коллизии старый маппинг вытесняется; пул циклический |
| TTL фейкового ответа | — | `fake-ip-ttl` (дефолт 1 сек) |

Источники: [sing-box fakeip server (новый формат)](https://sing-box.sagernet.org/configuration/dns/server/fakeip/), [legacy fakeip, удалён в 1.14](https://sing-box.sagernet.org/configuration/dns/fakeip/), [миграция 1.12: новые форматы DNS-серверов](https://sing-box.sagernet.org/migration/#migrate-to-new-dns-server-formats), [mihomo DNS config: fake-ip-filter-mode, fake-ip-ttl](https://deepwiki.com/iyanging/mihomo/2.6-dns-configuration), [mihomo DNS middleware и FakeIP](https://deepwiki.com/iyanging/mihomo/4.2-dns-middleware-and-fakeip), [FakeIP System: пул, коллизии](https://deepwiki.com/dahai9/mihomo/5.2-fakeip-system), [mihomo vs clash: DNS-питфоллы](https://www.vpnclash.com/en/blog/articles/mihomo-features-and-clash-differences.html).

## 2. Что sora делает сегодня (по коду, read-only)

- **sing-box** (`core/engine/singbox/render.go:535-537`): сервер `{"type": "fakeip", "tag": "fakeip", "inet4_range": <FakeIPRange|"198.18.0.0/15">}` + правило `{"query_type": ["A","AAAA"], "server": "fakeip"}`; `store_fakeip: true` в cache_file. Новый формат — корректно для sing-box ≥1.12 (проб версии в engine.go упоминает 1.14.2).
- **mihomo** (`core/engine/mihomo/rules.go:buildDNS`): `enhanced-mode: fake-ip`, `fake-ip-range` дефолт `198.18.0.1/16`, `fake-ip-filter: ["*.lan", "*.local"]`, `store-fake-ip: true`. Без fake-IP — `redir-host`.
- **Проблема 1 (асимметрия исключений):** sing-box-рендер не задаёт никаких доменных исключений из fakeip, а mihomo — только `*.lan`/`*.local`. Оба списка беднее community-практик (см. §3).
- **Проблема 2 (IPv6):** sing-box-правило безусловное `query_type: [A, AAAA] → fakeip`, `inet6_range` не задан (дефолт `fc00::/18`). При выключенном в sora IPv6 (`strategy: ipv4_only` применяется к final-серверу, не к fakeip-правилу) приложения всё равно получат фейковые IPv6-адреса — потенциальные висящие коннекты.
- **Проблема 3 (рассинхрон диапазонов):** дефолт sing-box `198.18.0.0/15`, дефолт mihomo `198.18.0.1/16` — разные пулы при переключении движка; маппинги из `cache.db` при смене движка невалидны.
- Плюс: `legacyFakeIPNetwork = "172.19.0.0/16"` в guard (nftables.go:20, firewall_windows.go:202) — не DNS-FakeIP, а отдельная блокируемая сеть; на FakeIP не влияет, упомянуто чтобы не путать.

## 3. Лучшие практики и питфоллы из источников 2025–2026

1. **Минимальный, но достаточный fake-ip-filter.** Ломаются: LAN-discovery, NTP-синхронизация, Windows connectivity checks, STUN/WebRTC. Community-набор: `*.lan`, `+.local`, `time.windows.com`, `+.msftconnecttest.com`, `+.ntp.org`, `time.*.com`, `+.stun.*.*`. Правило: фильтровать только то, что реально сломалось (проверить домен в логах), иначе теряется выигрыш FakeIP. Источники: [Clash Verge knowledge](https://www.clash-verge.us/en/knowledge.html), [Clash advanced manual](https://www.clashhot.com/en/reference.html), [config guide](https://www.clash911.com/en/config-guide.html), [iPhone fake-ip explained](https://www.clash-iphone.com/en/blog/articles/fake-ip-dns-mapping-explained.html).
2. **После смены режима DNS — чистить кэш.** Переключение fake-ip ↔ redir-host оставляет протухшие маппинги в системном/браузерном DNS-кэше → «странное поведение сайтов»; лечится рестартом ядра / flush DNS. Источник: [Clash Verge knowledge](https://www.clash-verge.us/en/knowledge.html).
3. **FakeIP почти обязателен под TUN.** Под TUN без fake-ip каждое соединение ждёт реальный резолв; fake-ip убирает серийную задержку DNS и сохраняет домен до стадии матчинга правил. Источник: [Clash advanced manual](https://www.clashhot.com/en/reference.html).
4. **Пул не должен пересекаться с реальными сетями.** `198.18.0.0/15` зарезервирован под бенчмаркинг и почти нигде не используется, но если корпоративная сеть/LAN его занимает — ядро начнёт считать fake-IP реальными целями. Источник: [Clash78 config guide](https://www.clash78.com/en/config-guide.html).
5. **DoH/DoT приложений обходит DNS-hijack TUN.** `dns-hijack: any:53` перехватывает только порт 53; DoH в браузерах выглядит как обычное HTTPS-соединение — домены для правил тогда берутся только из sniffing, а при ECH и sniffing не спасает. Источник: [Clash78 config guide](https://www.clash78.com/en/config-guide.html).
6. **Циклическая зависимость:** домен самого прокси-сервера нельзя резолвить через прокси, который ещё не поднят — нужен прямой baseline-путь для node-доменов. Источник: [mihomo features/differences](https://www.vpnclash.com/en/blog/articles/mihomo-features-and-clash-differences.html).
7. **IPv6 fake-IP vs intranet-правила.** `fc00::/18` — подмножество `fc00::/7`: в iptables/nftables-сетапах IPv6 fake-IP-правила должны идти **до** intranet-bypass, иначе трафик уйдёт напрямую. Источник: [box DNS hijacking](https://deepwiki.com/boxproxy/box/8-dns-configuration-and-hijacking).

## 4. Что перенять sora

| # | Рекомендация | Почему | Эффект |
|---|---|---|---|
| 1 | Расширить mihomo `fake-ip-filter`: `time.windows.com`, `+.msftconnecttest.com`, `+.ntp.org`, `+.stun.*.*` (сейчас только `*.lan`, `*.local`) | Ломаются синхронизация времени Windows, connectivity checks, WebRTC/STUN — классические жалобы пользователей TUN-клиентов (§3.1) | **high** (фикс реальных поломок, усилие S) |
| 2 | Реализовать исключения для sing-box: DNS-правила «домен → реальный сервер» **перед** catch-all `fakeip`-правилом, с тем же списком, что в №1 | У sing-box fakeip-сервера нет встроенного фильтра; без этого sing-box-режим ломает те же сервисы, что mihomo-фильтр чинит — асимметрия движков видна пользователю | **medium** (паритет движков, усилие S/M) |
| 3 | При выключенном IPv6 не отдавать AAAA в fakeip (правило только `A`, либо условный `inet6_range`); сейчас AAAA безусловно уходит на fakeip-сервер | При IPv6=off приложения получают фейковые `fc00::/18` и могут висеть на коннектах; `strategy: ipv4_only` это правило не покрывает (§2, проблема 2) | **medium** (усилие S; проверить на тестах) |
| 4 | Унифицировать дефолтный диапазон: `198.18.0.0/15` для обоих движков (сейчас mihomo `198.18.0.1/16`) | Один пул = предсказуемость при переключении движка; /15 даёт вдвое больше адресов; заодно инвалидировать `cache.db`-маппинги при смене движка/диапазона | **low** (косметика, но убирает класс «странных» багов) |
| 5 | При смене DNS-режима (fakeip ↔ redir-host/system) делать flush системного DNS-кэша или принудительный рестарт ядра | Протухшие маппинги — задокументированный источник «странного поведения сайтов» (§3.2) | **low** (гигиена) |
| 6 | Валидировать кастомный `FakeIPRange` на пересечение с LAN/корпоративными маршрутами (предупреждение в UI) | Пул, пересекающийся с реальной сетью, превращает fake-IP в реальные цели (§3.4) | **low** (редкий кейс, дешёвая проверка) |
| 7 | Документировать ограничение: DoH/DoT приложений не перехватывается TUN DNS-hijack; домены тогда только из sniffing (не работает с ECH) | Честная граница возможностей, снимает ложные баг-репорты (§3.5) | **low** (дока/FAQ) |
| 8 | Проверить минимальную версию sing-box ≥1.12 в матрице поддержки (legacy `dns.fakeip` удалён в 1.14; sora уже на новом формате — держать так) | Защита от регрессии при обновлении движка | **low** (проверка) |

Не рекомендую: `fake-ip-filter-mode: whitelist` по умолчанию — слишком агрессивно для десктопа (каждый новый сервис рискует сломаться); оставить как опцию для строгих пресетов.
