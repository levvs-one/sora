# DoH3 / DoQ для sora — веб-исследование

Дата: 2026-10-19. Тема: развёртывание DNS over HTTP/3 и DNS over QUIC в sora. Контекст: sora использует sing-box/Xray/mihomo; DNS-менеджер запланирован как P0 (PLANS.md), DoH3/DoQ в коде отсутствуют.

## 1. Что это и почему важно

- **DoH3** = DoH поверх HTTP/3 (QUIC), порт UDP 443. Сочетает незаметность DoH (трафик на 443 неотличим от обычного HTTPS, блок 853 его не затрагивает) с преимуществами QUIC: handshake за 1 RTT (против 2 у DoT/DoH-over-TCP), нет head-of-line blocking, **connection migration** — DNS-сессия переживает смену сети Wi-Fi → LTE без переподключения.
- **DoQ** = DNS поверх QUIC напрямую, порт UDP 853, RFC 9250 (2022). Самый быстрый шифрованный DNS: ~33% быстрее DoT/DoH по времени одного запроса при session resumption, всего на ~2% медленнее голого UDP, 10% выигрыш в page load против DoH. При 2% потерь пакетов p99 остаётся стабильным, тогда как у TCP-вариантов вырастает почти на секунду ([dnsdoh.art, 08.2026](https://www.webpronews.com/dns-over-quic-gains-traction-as-quad9-and-root-servers-test-a-faster-encrypted-alternative/)).
- Ключевой антицензурный аргумент: **DoH3 на 443 UDP работает там, где DPI режет UDP 853** (DoT/DoQ падают молча по простому правилу «закрыть 853-й порт»), и при этом не страдает от SNI-блокировки так сильно, как DoH over TCP (зависание из-за сброса пакетов по SNI — типичная картина в РФ).
- Россия, 2025–2026: РКН по сообщениям целево блокирует DoH/DoT Google и Cloudflare; ТСПУ умеет SNI-фильтр по `dns.google`/`cloudflare-dns.com` на 443 TCP, но QUIC-трафик на 443 UDP фильтровать точечно сложнее — и его нельзя резать целиком без убийства всего HTTP/3 ([cybernews, ~08.2026](https://cybernews.com/tech/russia-tries-to-whack-another-mole-in-its-internet-censorship-quest/), [akonit](https://lk.akonit.org/app/tech/dns.html)).

## 2. Поддержка резолверов (состояние на 2026)

| Резолвер | DoH3 | DoQ | Комментарий |
|---|---|---|---|
| Cloudflare 1.1.1.1 | ✓ | частич./тесты | DoH3 есть; DoQ для 1.1.1.1 тестируется, полного rollout нет |
| Google Public DNS | ✓ | ✗ | DoH3 есть |
| Quad9 9.9.9.9 | ✓ | ✓ | DoQ — масштабное внедрение 2026 |
| AdGuard DNS | ✓ | ✓ | Первыми реализовали DoQ публично |
| NextDNS | ✓ | ✓ | DoQ на `dns.nextdns.io` |
| Control D | ✓ | ✓ | |
| Alibaba 223.5.5.5 | ✓ | ? | Используется в конфигах sing-box как DoH3-эндпоинт |

Основа: [Privacy Guides](https://www.privacyGuides.org/nl/dns/), [dev.to сводка](https://dev.to/gustavo_gallas_4e45019b5c/dns-over-https-dns-over-tls-and-dns-over-quic-which-encrypted-dns-protocol-should-you-use-2kpb), [simeononsecurity 2026](https://simeononsecurity.com/articles/dns-comparison-adguard-quad9-cloudflare-pi-hole/). Детальные endpoint-списки: [dnsbench.pp.ua](https://www.dnsbench.pp.ua/dns-over-https).

## 3. Поддержка в платформах и конкурентах

- **Android**: с Android 11+ (через Play system update) система использует DoH3 вместо DoT для известных серверов, её поддерживающих ([Google Security Blog](https://security.googleblog.com/2022/07/dns-over-http3-in-android.html?hl=pt_BR)). Android 14 добавил нативный DoQ. Браузеры: Chrome/Firefox/Edge — автоматический DoH3 к поддерживающим резолверам. OS-клиентов (Windows/macOS/iOS/Linux systemd) с нативным DoQ до сих пор почти нет — всё решается клиентским софтом.
- **sing-box** (движок sora): нативная поддержка обоих — DNS-транспорт `h3://` (`dns/transport/quic/http3.go`) и `quic://` (`dns/transport/quic/quic.go`); протоколы различаются и в rule engine ([SagerNet/sing-box DeepWiki](https://deepwiki.com/SagerNet/sing-box/2.4-rule-actions-and-traffic-control)).
- **Surge**: `encrypted-dns-server` с протоколами `PROTOCOL,DOH` / `DOH3` (`h3://`) / `DOQ` (`quic://`) / `DOT` ([manual](https://manual.nssurge.com/dns/encrypted-dns.html)).
- **AdGuard VPN** (коммерческий): с v2.3 (2024) поддерживает кастомные DNS-серверы в формате `h3://` — это их рекламируемая фича ([adguard-vpn.com](https://adguard-vpn.com/ta/blog/adguard-vpn-v2-3-for-mac-and-windows.html)).
- **Android-клиенты**: RethinkDNS, Nebulo — DoH/DoT/DNSCrypt; AdGuard для Android поддерживает DoQ на кастомных серверах. Среди прокси-клиентов (v2rayNG, Hiddify, NekoBox, Streisand, FoXray, Shadowrocket) отдельного DoH3/DoQ-маркетинга не найдено — у тех, что на sing-box (Hiddify, SFM/SFI), поддержка есть транзитивно через движок, но в UI как фича не выставляется. **Вывод: в UI прокси-клиентов DoH3/DoQ — незанятая ниша.**

## 4. Что sora должен перенять

### R1. DoH3/DoQ как типы DNS-сервера в DNS-менеджере (P0) — эффект HIGH
- В плановый DNS-менеджер добавить типы `h3://` и `quic://` наряду с DoH/DoT/plain. На sing-box-движке это бесплатно (нативная поддержка), на Xray/mihomo — маппинг в ближайший поддерживаемый транспорт или через sing-box fallback.
- Почему: в РФ UDP 853 режут массово (DoT/DoQ на 853 — рискованно как единственный выбор), а DoH3 на 443 UDP — единственный шифрованный DNS, который (а) не режется портом, (б) сложнее точечно фильтровать по SNI, чем DoH-over-TCP, (в) быстрее. Это прямо стыкуется с позиционированием «работает из коробки в жёсткой цензуре».

### R2. Дефолтный набор резолверов с протоколом и порядком fallback — эффект HIGH
- По умолчанию: DoH3 (Quad9/AdGuard/Cloudflare `h3://`) → DoH (TCP, 443) → DoT. DoQ включать только опционально/по кнопке «максимальная скорость», т.к. порт 853 блокируем — автоопределение.
- Важно: резолверы для bootstrap DNS не должны сами требовать DNS (использовать IP-адреса в конфиге, как `h3://223.5.5.5/dns-query` в примерах sub2sing-box), иначе петля при сломанном системном DNS.

### R3. Проба протоколов при первом запуске / смене сети («DNS transport probing») — эффект MEDIUM
- При старте (и по триггеру «смена сети», у sora уже есть детект смены сети) фоном прогнать 1–2 тестовых запроса по каждому транспорту до выбранных резолверов и выбрать рабочий. Сохранять профиль «ISP → рабочий транспорт». Это мини-версия фичи «авто-тюнинг под DPI» (§3 №2 competitor-analysis) — только для DNS.
- Почему: поведение DPI различается по провайдерам и во времени; статический выбор «DoH3 всегда» сломается там, где режут весь UDP.

### R4. Индикация транспорта DNS в UI + тест утечек — эффект MEDIUM
- В DNS-менеджере показывать, каким транспортом реально идёт каждый запрос (цветной бейдж: DoH3/DoH/DoT/DoQ/plain), и интегрировать с уже запланированной проверкой утечек (dnsleak.go есть). Пользователь видит, что DNS не «утёк» в провайдера.
- Дифференциатор: ни один конкурент не показывает live-транспорт DNS в UI.

### R5. DoQ как опция «спорт-режима» — эффект LOW
- DoQ быстрее DoH3 на единицы процентов при чистом канале, но на 853-м порту — высокий риск блокировки в РФ/Иране/Китае. Держать как продвинутую опцию с предупреждением, не как дефолт. Приоритет ниже DoH3.

### R6. Не делать: собственный DoQ/DoH3-резолвер на стороне sora — эффект LOW/отрицательный
- Держать свой публичный резолвер — операционная и юридическая нагрузка, плюс единая точка доверия. Не нужно: достаточно качественного клиентского выбора транспорта.

## 5. Риски и ограничения
- DoH3 требует UDP 443 открытым в обе стороны; часть корпоративных сетей и часть DPI режут весь QUIC — поэтому обязателен fallback на DoH-over-TCP (R2/R3), иначе «всё мучительно висит» — худший UX из возможных.
- SNI в ClientHello QUIC виден DPI; полная невидимость требует ECH, который резолверы почти не поддерживают — не продавать DoH3 как «недетектимый».
- Cloudflare/Google до сих пор без production-DoQ — не строить дефолты на DoQ к ним.

## 6. Итоговая оценка
- **HIGH**: R1 (типы h3/quic в DNS-менеджере) + R2 (дефолт DoH3-first с fallback) — дёшево (sing-box умеет из коробки), закрывает реальную боль блокировки 853 и даёт маркетинговый пункт «первый прокси-клиент с DoH3 в UI».
- **MEDIUM**: R3 (протокол-пробинг под ISP) + R4 (индикация транспорта в UI).
- **LOW**: R5 (DoQ как продвинутая опция), R6 (не делать свой резолвер).
