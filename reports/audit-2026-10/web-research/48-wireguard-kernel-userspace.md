# WireGuard kernel vs userspace в 2026

Исследование для sora (Flutter UI + Go core, движки sing-box / Xray / mihomo — все используют userspace-реализацию WireGuard).
Дата: 2026-10-19. Веб-поиск обязателен — выполнено 7 запросов, приоритет источникам 2025–2026.

## Что нашёл

### 1. Linux: kernel module — эталон, userspace отстаёт на 10–15%
- Модуль в ядре с 5.6, разработка активно продолжается внутри mainline: netlink-rewrite, GSO, threaded NAPI, hardening (pbxscience.com, ~сен 2026): https://pbxscience.com/why-the-linux-kernel-includes-wireguard-but-not-openvpn/
- Замеры (Phoronix / tech-insider.org, AMD EPYC, 10 GbE): kernel single-stream iperf3 ~8.0 Gbps при ~15% ниже CPU, чем userspace; OpenVPN ~1.1 Gbps для сравнения: https://tech-insider.org/tailscale-vs-wireguard-2026/
- Tailscale (userspace wireguard-go + TUN): ~6.8 Gbps прямая точка-точка на том же железе; их экспериментальный kernel-бэкенд на Linux 6.x — 10+ Gbps. Разрыв 10–15% vs raw kernel — «стоимость userspace»: https://tech-insider.org/tailscale-vs-wireguard-2026/
- Важно для клиента: idle CPU на peer kernel <0.1% против ~0.3% userspace; при 1 Gbps — 3–5% CPU против 12–18%.

### 2. wireguard-nt (Windows): быстрейший вариант, но риски поставки в 2026
- WireGuardNT — нативный kernel/NDIS-драйвер, официальный клиент Windows использует его по умолчанию; коммерческие клиенты (hide.me) включили как дефолт из-за заметного прироста: https://hide.me/en/knowledgebase/wireguardnt-experimental-kernel-driver-on-windows/
- Апрель 2026: Microsoft в рамках верификационной зачистки Hardware Program **приостановила аккаунт разработчика WireGuard**, лишив возможности пересертифицировать kernel-драйвер. Аккаунт восстановили после огласки, но VeraCrypt до сих пор заблокирован: https://winbuzzer.com/2026/04/10/microsoft-locks-out-veracrypt-wireguard-devs-halting-windows-xcxwbn/
- Вывод: kernel-драйвер на Windows = зависимость от attestation-подписи Microsoft и Partner Center. Сигнальная история для опенсорсного проекта.
- Отдельный кейс (фев 2026, KB5075912): осиротевший драйвер WireGuard в `C:\Windows\System32\drivers` после деинсталляции VPN сломал UAC и servicing stack — гигиена установки/удаления драйвера критична: https://steamcommunity.com/discussions/forum/13/797837920511958325/

### 3. wireguard-go: живой, но стагнирует как протокол-стек; есть дешёвый буст
- Апстрим развивается слабо; все крупные вендоры держат форки (Tailscale). Mullvad в дек 2025 объявил **GotaTun** — свой Rust-форк BoringTun, замена wireguard-go: краши на Android упали с 0.40% до 0.01%, пользователи отмечают скорость и батарею. В 2026 — сторонний аудит и замена на всех платформах: https://mullvad.net/en/blog/announcing-gotatun-the-future-of-wireguard-at-mullvad-vpn
- Cloudflare (автор BoringTun): Go хорош для серверов, но плох для raw packet processing — бенчмарки wireguard-go сильно проигрывают kernel-модулю, поэтому выбран Rust: https://blog.cloudflare.com/boringtun-userspace-wireguard-rust/
- Но (toonk.io, окт 2026): **multi-queue TUN доводит stock wireguard-go с сотен kpps до ~1.5 Mpps** на мелких пакетах без смены архитектуры. Эксперимент показал, что crypto обычно не bottleneck — bottleneck'и в TUN-очереди, replay window и таймерах: http://toonk.io/wireguard-dpdk/index.html
- Экзотика вне контекста: DPDK-путь даёт 30–40 Mpps, но требует захвата NIC и убивает routing/firewall/tcpdump на хосте — не для VPN-клиента.

### 4. macOS / iOS: только userspace, выбора нет
- В ядре macOS WireGuard нет и не будет. Официальный App Store-клиент и wireguard-go работают через utun NetworkExtension; имена интерфейсов ограничены `utun[0-9]+`: https://www.vpnsmith.com/en/blog/wireguard-macos-setup-2026
- wireguard-go не умеет sticky sockets и fwmark на Darwin — учитывать при split-tunnel через fwmark.

### 5. BoringTun (Rust): отраслевой стандарт userspace
- Cloudflare BoringTun — MIT/Apache, активен (LTO, portable-atomic, фиксы nonce-reuse на 32-бит): https://deepwiki.com/cloudflare/boringtun
- Windscribe: под нагрузкой userspace (их модифицированный BoringTun) пинит CPU, поэтому они на серверах ушли в kernel — но это про серверную сторону, не клиент: https://windscribe.com/blog/cloudflare-warp-vs-vpn/

### 6. sing-box / mihomo / xray: везде userspace
- sing-box: `transport/wireguard` — `stackDevice` (gVisor stack, портативно, медленнее) и `systemDevice` (native TUN + `tun.LinuxTUN` batch ops на Linux): https://deepwiki.com/reF1nd/sing-box/4.2.2-wireguard-implementation
- mihomo: WireGuard outbound — wireguard-go-дериват через IPC-конфиг, TUN inbound через sing-tun (gVisor / System / Mixed): https://deepwiki.com/epidnkkeu/mihomo/5-transport-protocols
- Ни у одного из трёх движков нет kernel-режима из коробки. Выбор kernel = отдельная интеграция поверх движков.

### 7. AmneziaWG: жив и развивается, критичен для RU
- Активно поддерживается: версии 2.0 → 3.1 (шифрование низкоэнтропийных полей ChaCha20, I1–I5 сигнатурные пакеты под QUIC): https://dev.to/selfhostpilot/wireguard-split-tunneling-on-blocked-networks-udp2raw-144p
- Есть GPL-2.0 kernel-модуль и wireguard-go-форк (MIT). В России stock WireGuard мёртв с середины 2025, AWG 2.0 держится: https://dev.to/bivlked/amneziawg-20-self-host-an-obfuscated-wireguard-vpn-that-bypasses-dpi-4692
- Важно: для Китая с late-2025 (GFW 4.0) vanilla AWG уже часто детектится: https://www.vpnsmith.com/en/blog/anti-dpi-vpn-bypass-2026
- Сторонние клиенты (WG Tunnel) поддерживают AWG 2.0–3.1 — sora должен держать паритет версий: https://www.apkmirror.com/apk/zane-schepke/wg-tunnel/wg-tunnel-5-7-5-release/wg-tunnel-5-7-5-2-android-apk-download/

## Что sora должен перенять и почему

| # | Рекомендация | Почему | Эффект |
|---|---|---|---|
| 1 | **Linux: опциональный fast path через kernel-модуль** (создание wg-интерфейса через netlink, когда доступен; fallback на userspace). Интегрировать поверх движков как отдельный dataplane-режим. | ~10–15% пропускной способности, в 3× меньше CPU при 1 Gbps, почти нулевая латентность; конкурентное преимущество в бенчмарках, которые все меряют на Linux. | **high** (perf), medium (сложность, привилегии) |
| 2 | **Включить multi-queue / batch TUN в userspace-пути на Linux** (аналог toonk.io: 1.5 Mpps из stock wireguard-go). Проверить, что используемые движки (sing-box systemDevice с LinuxTUN) реально включают batch ops; если нет — патч/настройка. | Дешёвое изменение, максимальный ROI на userspace-пути; снимает главную причину отставания от kernel на мелких пакетах. | **high** (perf/$effort) |
| 3 | **Не делать ставку на wireguard-nt на Windows в ближайший год.** Оставаться на userspace на Windows до стабилизации поставки драйверов (урок апреля 2026). Если kernel — только с безупречной гигиеной установки/удаления драйвера (кейс KB5075912) и attestation-подписью в key ceremony. | Избежать зависимости от Partner Center и BSOD/UAC-рисков; userspace на Windows для клиентских нагрузок достаточен. | **medium** (риск-менеджмент) |
| 4 | **Следить за Mullvad GotaTun (аудит в 2026) как кандидатом на замену wireguard-go на мобильных/desktop userspace-путях.** 40-кратное снижение крашей на Android — сильный аргумент. | Стабильность > скорость для «лучшего клиента в мире»; wireguard-go признанно проблемен в проде. | **medium** (stability), low (сейчас — ждать аудита) |
| 5 | **macOS/iOS: принять userspace как данность; оптимизировать** (batch read/write, преаллокация буферов, избегать лишних копий в TUN-пути). | Выбора нет — выиграть можно только качеством userspace-стека. | **medium** |
| 6 | **Держать паритет AmneziaWG до 3.1** (параметры I1–I5, H1–H4, S1–S4, Jc/Jmin/Jmax; QUIC-имитация). | Для RU — ключевой сценарий обхода DPI; конкуренты (WG Tunnel) уже на 3.1. | **high** (для целевого рынка) |
| 7 | **Добавить в диагностику dataplane-бейдж**: какой backend WireGuard реально используется (kernel / userspace, multiqueue on/off) + замер. | Прозрачность = доверие; упрощает поддержку и позволяет A/B-выбор лучшего пути автоматически. | **low** (effort), medium (value) |

## Чего делать НЕ стоит
- **DPDK/AF_XDP fast path в клиенте** — 40 Mpps не нужны VPN-клиенту; цена — потеря routing/firewall/visibility ОС. Отклонить.
- **Свой kernel-модуль** — писать свой WireGuard-модуль бессмысленно; использовать in-tree модуль Linux там, где он есть.
- **Форкать wireguard-go ради perf** — ROI низкий; лучше дождаться GotaTun или взять BoringTun.

## Итоговая позиция
2026 год: kernel — лучший dataplane там, где доступен (Linux; Windows — с оговорками поставки). Userspace — единственный вариант на macOS/iOS. Главный практический вывод для sora: (а) userspace-путь ещё далеко не выжат — multi-queue TUN даёт кратный прирост почти бесплатно; (б) wireguard-go как библиотека — зрелый, но проблемный в проде выбор, индустрия мигрирует на Rust (BoringTun → GotaTun); (в) стратегически выигрышная архитектура — **автовыбор dataplane**: kernel на Linux при наличии → userspace (tuned) везде → опционально GotaTun после аудита 2026.
