# Web-research #28: Внедрение MASQUE (HTTP/3-проксирование)

Дата: 2026-10-19. Тема: RFC 9484 (CONNECT-IP), RFC 9298 (CONNECT-UDP) — проксирование IP/UDP поверх HTTP как VPN-транспорт.

## Что это

MASQUE (Multiplexed Application Substrate over QUIC Encryption) — семейство IETF-стандартов: CONNECT-UDP (RFC 9298) проксирует UDP, CONNECT-IP (RFC 9484, окт. 2023) — произвольные IP-пакеты поверх HTTP. Трафик выглядит как обычный HTTPS/HTTP-3 до известного веб-сервера (порт 443), мультиплексируется в одном QUIC-соединении, с миграцией соединения при смене сети. Профиль "VPN через браузерный трафик".

## Что нашёл

### 1. Cloudflare: MASQUE по умолчанию для WARP/1.1.1.1 (дек 2024)

Cloudflare перевёл все потребительские приложения 1.1.1.1 и WARP (и Zero Trust агенты) на MASQUE как транспорт по умолчанию, заменив WireGuard: «we believe MASQUE is the future of fast, secure, and stable Internet proxying… deployed it successfully at scale for customers like iCloud Private Relay and Microsoft Edge Secure Network».
- https://blog.cloudflare.com/masque-now-powers-1-1-1-1-and-warp-apps-dex-available-with-remote-captures/ (2024-12-27)

### 2. Apple iCloud Private Relay — крупнейшее живое внедрение MASQUE

Private Relay (iCloud+, сотни миллионов устройств) использует MASQUE: CONNECT + CONNECT-UDP поверх HTTP/3 (QUIC, порт 443, TLS 1.3), fallback на HTTP/2 + TLS 1.3 там, где QUIC невозможен; двуххоповая архитектура ingress (Apple) → egress (Cloudflare/Akamai/Fastly); DNS — ODoH. Доказывает масштабную производственную готовность.
- https://en.wikipedia.org/wiki/ICloud_Private_Relay

### 3. Mullvad: WireGuard внутри QUIC через MASQUE (2025) — кейс против цензуры

Mullvad выпустил обфускацию «WireGuard в QUIC» поверх MASQUE (десктоп 2025.9, мобильные — в планах): VPN-трафик неотличим от обычного веб-трафика; авто-переключение при неудачных попытках; прямой ответ на блокировки/троттлинг WireGuard в РФ и Китае.
- https://reclaimthenet.org/mullvad-vpn-wireguard-quic-masque-bypass-censorship
- https://vpnx.blog/mullvad-adds/ (мобайл + сравнение с Shadowsocks-обфускацией)

### 4. sing-box 1.15.0-alpha.7: нативная поддержка MASQUE (клиент + сервер)

В changelog sing-box 1.15.0-alpha.7 (2025): «Add MASQUE client and server support. The new MASQUE Client and MASQUE Server endpoints provide IP proxying over HTTP (CONNECT-IP), supporting HTTP/1.1, HTTP/2 and HTTP/3, address assignment and route advertisement. They can use the internal network stack or a system TUN interface». В том же релизе HTTP outbound переписан: HTTP/2 по умолчанию, HTTP/3 и UDP через CONNECT-UDP.
- https://sing-box.sagernet.org/changelog/

### 5. mihomo: MASQUE outbound упоминается в свежих релизных заметках/доках

Исследование в репо (sora-legacy/docs/research/mihomo-engine.md) фиксирует страницы outbound для `masque` в релизных заметках mihomo (v1.19.32+) и навигации документации. То есть 2 из 3 движков sora уже/скоро имеют MASQUE.

### 6. Xray: поддержки MASQUE нет (подтверждено поиском)

По Xray-core не найдено ни релизов, ни открытых issues/feature-request'ов про MASQUE CONNECT-IP/CONNECT-UDP — только общие транспорты (QUIC, XHTTP). Вывод: для Xray-зоны MASQUE-транспортов нет.

### 7. Реальность DPI: QUIC SNI уже читается, чистый QUIC — не панацея

- USENIX Security 2025 (gfw.report): GFW Китая с апреля 2024 извлекает SNI из QUIC Initial-пакета — «QUIC/HTTP/3 = censorship-proof» частично сломано.
- Россия: март 2022 — TSPU дропал весь QUIC на 443 (payload ≥1001 байт); затем переход к точечной SNI-фильтрации QUIC.
- MASQUE имеет значение именно как маскировка ПОД обычный веб-трафик к популярному SNI/домену + fallback HTTP/2 поверх TCP (у Apple и sing-box встроен). Открытые реализации: connect-ip-go (используется в sing-box), usque (open-source реимплементация MASQUE-клиента Cloudflare WARP).
- https://gfw.report/publications/usenixsecurity25/en/
- https://byteful.com/blog/learn-quic-proxy

### 8. Прочее

- Рабочая группа IETF MASQUE активна в 2025–2026: drafts CONNECT-ETHERNET, CONNECT-IP DNS-конфигурация (DNS_ASSIGN/PREF64 капсулы), CONNECT-UDP rendezvous/listen (P2P без публичного UDP-адреса — интересно для E2E-синка, см. research других номеров).
- Firefox (bug 1991426) дорабатывает fallback MASQUE-соединений — движение в сторону браузеров.

## Что sora должен перенять

1. **Поддержать MASQUE-тип серверов в UI/парсере подписок как новый транспорт** (наравне с VLESS/Hysteria2): sing-box 1.15+ и свежий mihomo уже умеют CONNECT-IP клиент; sora нужно только сгенерировать конфиг, добавить импорт/экспорт (URI-схема или JSON-поля) и автовыбор движка под MASQUE-сервер. Xray-серверы останутся без MASQUE.
2. **Продвигать MASQUE как anti-DPI транспорт первого класса**: для цензурных ISP это «трафик выглядит как HTTPS к обычному сайту» + встроенный HTTP/2-over-TCP fallback там, где UDP/QUIC душится (у Apple и sing-box этот fallback уже есть). Комбинировать с существующими фичами sora: авто-тюнинг фрагментации (roadmap §3 №2) должен учитывать MASQUE как опцию «режим штопор».
3. **CONNECT-UDP для HTTP-outbound'а**: sing-box переписал HTTP-прокси на CONNECT-UDP — sora может предлагать MASQUE-прокси как «лёгкий VPN-режим» (только UDP/TCP-проксирование без полного TUN) для сетей, где TUN запрещён политиками.
4. **Не строить свой MASQUE-сервер с нуля**: использовать sing-box MASQUE Server endpoint (уже есть, HTTP/1.1–3, TUN/gVisor) — в one-click развёртывании сервера из клиента (roadmap §3 №8) предлагать MASQUE как транспорт наравне с VLESS/XHTTP.

## Оценка эффекта

- **Поддержка MASQUE-клиента через sing-box/mihomo: high** — транспортный паритет с Cloudflare WARP / Mullvad / Apple, сильный anti-DPI аргумент; стоимость внедрения низкая (движки уже умеют, нужен только конфигогенератор + UI + capability-детект), Xray остаётся без поддержки — честно отразить в автовыборе движка.
- **MASQUE как опция one-click сервера: medium** — дифференциатор против Amnezia (у них только свои протоколы), но серверная сторона нужна своя.
- **CONNECT-UDP «лёгкий режим» без TUN: low/medium** — нишево, полезно в корпоративных сетях.

## Риски/оговорки

- QUIC Initial SNI читается GFW (с 04.2024) — MASQUE работает против DPI только если SNI/домен сервера «белый» и трафик неотличим от браузерного; не серебряная пуля.
- sing-box MASQUE — alpha-ветка 1.15.0; в прод тащить после стабилизации (или пинить проверенную alpha).
- Экосистема серверов MASQUE пока тонкая (нет массовых провайдеров подписок) — фича «на вырост», ценность раскроется с one-click сервером sora.
