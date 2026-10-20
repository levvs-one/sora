# 45 — Kernel WireGuard (Linux): замеры, цена userspace, когда userspace приемлем

Дата: 2026-10-20. Третий проход группы E. Первый проход дал цифры и иерархию (темы 46/48). Здесь — верификация цифр по свежим источникам, механика разрыва и честная граница «когда неважно».

## 1. Замеры (источники 2025–2026, сверка)

**ecn-apps.com** (обновлено ~окт 2026, таблица kernel WireGuard vs Tailscale-userspace, 10GbE):
- Single-stream iperf3: **9.38 Gbps (kernel, GSO включён)** vs **6.12 Gbps (userspace, «single-thread TUN bottleneck»)**.
- RTT overhead: 0.08 мс vs 0.35 мс (контекстные переключения через `/dev/net/tun`).
- https://ecn-apps.com/pages/articles/tailscale-vs-wireguard-benchmarks-routing.html

**tech-insider.org** (сен 2026, сводка по Phoronix + Tailscale):
- Phoronix, AMD EPYC 9654: kernel WireGuard **~7.5–8.0 Gbps single-stream TCP**, CPU на ~15% ниже userspace-альтернатив; OpenVPN ~1.1 Gbps для масштаба.
- Tailscale userspace (wireguard-go): ~6.8 Gbps point-to-point; их экспериментальный kernel-бэкенд на Linux 6.x — 10+ Gbps.
- 8-stream: 9.4 vs 9.1 Gbps — **разрыв почти исчезает на многопоточности**.
- Idle CPU на пир: <0.1% vs ~0.3%. **CPU при 1 Gbps: 3–5% vs 12–18%.**
- https://tech-insider.org/tailscale-vs-wireguard-2026/

**netgate.com** (pfSense, старые но показательные цифры kernel vs wireguard-go на одном железе):
- Atom C3558 (4 ядра): kernel **909 Мбит/с** (99.89% теоретического максимума линка) vs wireguard-go **329 Мбит/с** (36.15%) — разрыв **2.76x** на слабом CPU.
- Xeon D-1541 (8 ядер): 1542 vs 1370 Мбит/с — разрыв всего **1.12x** на мощном CPU.
- 4 параллельных туннеля, TRex, пакеты 1420: kernel 1846 Мбит/с vs userspace 661 Мбит/с (2.79x).
- https://www.netgate.com/blog/wireguard-in-pfsense-2-5-performance.html

**ssdnodes.com** (2026, гайд по диагностике): kernel-модуль «spreads a peer's encryption across cores»; wireguard-go медленнее; AES-NI для WireGuard бесполезен (ChaCha20 — чистый софт), проверять `%soft`/`%usr` в `mpstat`, а не наличие AES-инструкций. https://www.ssdnodes.com/learn/wireguard-slow-speeds-and-mtu

Вывод по цифрам: разрыв kernel/userspace — **не константа, а функция железа и нагрузки**: 1.1x на мощном многоядерном CPU при bulk-трафике → 2.8x на слабом CPU / мелкопакетной нагрузке. Цифры «9.38 vs 6.12» и «3–5% vs 12–18% CPU» подтверждаются независимыми источниками.

## 2. Механика разрыва

1. **Контекстные переключения**: userspace-путь = kernel TUN → userspace-демон (Go) → kernel UDP-сокет: минимум 2 перехода и 2 копирования на пакет. Kernel-путь: шифрование в softirq, `sk_buff` идёт дальше без переходов.
2. **Single-thread TUN bottleneck**: чтение `/dev/net/tun` — одна очередь, один поток. Отсюда 6.12 vs 9.38 на single-stream и схождение на 8-stream (9.1 vs 9.4).
3. **GSO**: kernel WG использует UDP GSO (батчинг), userspace-путь батчит хуже или никак.
4. **Go runtime**: GC-паузы и планировщик в горячем пакетном пути (аргумент Cloudflare за BoringTun на Rust).

## 3. Когда userspace приемлем (честная граница)

- **Линки до ~500 Мбит/с на современном десктопном CPU**: userspace насыщает линк, пользователь разницы не видит. Разрыв проявляется только когда потолок — сам датаплан, а не канал.
- **Мобильные/ноутбучные сценарии**: важнее idle-поведение (0.3% vs 0.1%) и отсутствие keepalive, чем пиковые Gbps.
- **Когда kernel недоступен**: macOS/iOS (модуля нет и не будет), Windows (WireGuardNT — риски подписи, тема 44/48-первый-проход), контейнеры без прав.
- **Когда цена интеграции выше выигрыша**: у sora движки (sing-box/Xray/mihomo) — userspace из коробки; kernel-путь = отдельный dataplane-режим поверх движков (создание wg-интерфейса через netlink + AllowedIPs-роутинг в обход движка).

## 4. Вердикт: лучшее или слоп

**Лучшее — как опциональный fast path, слоп — как дефолтная сложность.** Kernel WG на Linux — измеримо лучший датаплан (до 2.8x на слабом железе, 3x меньше CPU), и sora-сервис уже работает как root — привилегий хватает. Но делать его единственным путём — слоп: ломается кроссплатформенность и растёт поверхность багов.

## 5. Рекомендация «внедрить так»

1. **Автовыбор dataplane на Linux**: если доступен kernel-модуль (`/sys/module/wireguard`) и протокол — WireGuard/AmneziaWG — поднимать kernel-интерфейс через netlink (wg-quick-стиль, но своим кодом поверх `wgctrl-go`), иначе fallback на userspace движка. Переключатель в настройках: Auto / Kernel / Userspace.
2. **AmneziaWG kernel**: использовать kernel-модуль AmneziaWG (GPL-2.0, DKMS) там же, где kernel WG — обфускация в ядре, без userspace-налога (тема 46).
3. **Не трогать Windows**: оставаться на userspace (WinTun) до стабилизации поставок WireGuardNT-подписей; урок апреля 2026.
4. **В userspace-пути выжать дешёвое**: multi-queue TUN (тема 41, `multi_queue`), батчинг чтений — это закрывает большую часть разрыва на современном железе (toonk.io: сотни kpps → 1.5 Mpps).
5. **Бейдж dataplane в диагностике**: `kernel` / `userspace` (+ multi-queue on/off) и замер — прозрачность и материал для A/B (первый проход, тема 48).
6. Watch-лист: **Mullvad GotaTun** (Rust-форк BoringTun, краши на Android 0.40%→0.01%, аудит в 2026) — кандидат на замену wireguard-go в userspace-путях после аудита; самим wireguard-go не форкать.
