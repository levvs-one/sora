# 46 — Тюнинг TUN-производительности на всех платформах

Дата: 2026-10-19. Репо прочитаны только в read-only (core/engine/*/render.go и др.). Sora сегодня: sing-box tun рендерится со `"stack": "mixed"`, MTU по умолчанию 9000 (singbox/render.go:562-563); mihomo tun MTU 1420 (mihomo/proxy.go:63); Xray tun MTU unset→1500. Движки — внешние бинарники, sora их скачивает и может выбирать версию пина.

## 1. Что нашёл (с источниками)

### 1.1. sing-box 1.15 переписал TUN-стек — это главная новость
- Начиная с sing-box 1.15.0, `sing-tun` использует собственный TCP/IP-стек вместо gVisor/system/mixed. Официальный changelog: «substantial improvements over all previous implementations in peak performance, energy efficiency, and memory usage». Опция `stack` deprecated и **удаляется в sing-box 1.17.0**; с 1.16.0 для её использования нужен `ENABLE_DEPRECATED_TUN_STACK=true`.
  - https://sing-box.sagernet.org/changelog/ (1.15.0-alpha.3)
  - https://sing-box.sagernet.org/configuration/inbound/tun/ (раздел `stack`)
  - https://sing-box.sagernet.org/migration/ (миграция 1.15.0)
- Sora сейчас рендерит `"stack": "mixed"` → это буквально запрещает новый стек и оставляет TCP-трафик на gVisor. В mixed-режиме TCP идёт через userspace-стек gVisor — исторически главный ботлнек.

### 1.2. gVisor всегда медленнее ядра — консенсус
- «gVisor's netstack is still much slower than the kernel's (and likely always will be). The goal of this userspace netstack is not to compete with the kernel on performance, but offer an alternative that is more portable and secure» (Hacker News, обсуждение userspace TCP-стеков).
  - https://news.ycombinator.com/item?id=40586757
- gVisor сам признаёт performance perception problem: «out-of-the-box performance often shows performance degradation for certain I/O-intensive workloads» (официальный блог gVisor, 2026-10-02).
  - https://gvisor.dev/blog/2026/10/02/gvisor-cncf/

### 1.3. MTU: большой MTU ускоряет, но ломает реальные пути
- Замеры OpenVPN: tun-mtu 1500→48000 даёт 158→510 Mbps (Blowfish), 126→259 Mbps (AES-256) — эффект только на гигабитных линках без фрагментации.
  - https://community.openvpn.net/Archived/Optimizing%20Performance%20on%20Gigabit%20Networks
- Но в реальном интернете PMTUD ломается (black holes, ICMP режут): правило — MTU туннеля ≤ path MTU минус overhead; практический VPN-диапазон 1280–1420; MSS clamping решает большинство случаев (privateproxyguide, обновлено 2026).
  - https://www.privateproxyguide.com/optimizing-openvpn-performance-by-adjusting-mtu-and-fragmentation/
  - https://www.valtersit.com/guides/networking/the-mtu-nightmare-why_your_vpn_connection_is_fragmenting_to_death/
- Вывод для sora: дефолт MTU 9000 на tun без поддержки пути = фрагментация и ретрансмиты; безопасный дефолт 1500/1400 + MSS clamp.

### 1.4. Windows: WinTun — ring buffers, spin-read, батчинг решает
- WinTun: userspace общается с драйвером через пару shared ring buffers (128 KiB–64 MiB); официальная дока рекомендует «spin on WintunReceivePacket for a number of cycles before falling back to waiting on the read-wait event» для high-performance use cases.
  - https://git.zx2c4.com/wintun/about/
- amneziawg-go (Windows): `rateJuggler` — переключение между blocking read и spinloop при >800 Mbps, ring 8 MB; `BatchSize()` возвращает 1 — батчинг чтения до сих пор TODO (известный задел).
  - https://deepwiki.com/amnezia-vpn/amneziawg-go/3.2-windows-tun-implementation
- OpenVPN: 414 Mbps через tap-windows против 737 Mbps через WinTun — выбор драйвера сам по себе ~1.8x.
  - https://malwaretips.com/threads/new-wireguardnt-shatters-throughput-ceilings-on-windows.109397/
- Антивирус (Defender) сканирует весь туннельный трафик — известная причина «медленного VPN» на Windows.
  - https://deepwiki.com/goxray/tun/7.3-windows-deployment

### 1.5. Linux: userspace платит 10–30%, однопоточный TUN — главный враг
- Tailscale (wireguard-go, userspace) vs kernel WireGuard на 10GbE: single-stream 6.12 против 9.38 Gbps — «single-thread TUN bottleneck»; multi-stream разрыв почти исчезает (9.1 vs 9.4). CPU при 1 Gbps: 12–18% против 3–5%.
  - https://ecn-apps.com/pages/articles/tailscale-vs-wireguard-benchmarks-routing.html
- Phoronix 2025 (EPYC 9654): kernel WireGuard ~7.5–8.0 Gbps single-stream TCP, на ~15% ниже CPU, чем userspace-альтернативы; OpenVPN ~1.1 Gbps.
  - цит. по https://tech-insider.org/tailscale-vs-wireguard-2026/
- Эксперимент toonk.io (окт 2026): дать stock wireguard-go multi-queue TUN — рост с «a few hundred thousand pps» до ~1.5 Mpps. Вывод: масштабирование чтения TUN по очередям/потокам важнее крипты.
  - http://toonk.io/wireguard-dpdk/index.html
- Виртуальные интерфейсы Linux по умолчанию без TX TCP segmentation offload → сегментация на CPU; включение offload даёт заметный прирост (исследование UvA).
  - https://rp.os3.nl/2016-2017/p84/report.pdf
- sing-tun (новый, 1.15) уже умеет GSO: `GSOSplit`/`ErrTooManySegments` в API — батчинг чтений из коробки.
  - https://pkg.go.dev/github.com/metacubex/sing-tun

### 1.6. macOS/iOS: utun + userspace — потолок ниже
- На macOS/iOS клиенты вынуждены использовать `wireguard-go` (kernel-модуль загрузить нельзя) — он медленнее kernel-реализации (разбор ssdnodes, 2026).
  - https://www.ssdnodes.com/learn/wireguard-slow-speeds-and-mtu
- Методология замера, которую стоит перенять: сначала iperf напрямую, потом через туннель, оба направления, затем `-P 4` (один TCP-поток упирается в окно/RTT, а не в TUN).
  - там же

## 2. Что sora должен перенять

| # | Мера | Почему | Эффект |
|---|------|--------|--------|
| 1 | Убрать `"stack"` из рендера sing-box tun (singbox/render.go:562) и поднять пин sing-box до ≥1.15 | Новый собственный стек быстрее всех прежних (peak perf, энерго, память — по changelog); `stack` удаляют в 1.17.0 — конфиг иначе сломается; gVisor-режим уходит вместе с опцией | **high** |
| 2 | Дефолт MTU tun 9000 → 1500 (или 1400) + MSS clamping для TCP через TUN | 9000 без поддержки пути = фрагментация/ретрансмиты и PMTUD black holes; 1280–1420 — практический VPN-диапазон; clamping чинит 90% «медленного VPN» без угадывания MTU | **high** (корректность+скорость) |
| 3 | Windows: убедиться, что движок использует spin-before-block чтение WinTun и достаточный ring capacity; проверить батчинг | Официальная рекомендация WinTun; amneziawg-go показывает паттерн (spinloop >800 Mbps); отсутствие батчинга — известный TODO даже у конкурентов | **medium** (high на гигабите) |
| 4 | Linux: для WireGuard/AmneziaWG предпочитать kernel-реализацию, когда есть root | 2–4x throughput single-stream, в разы меньше CPU (6.12→9.38 Gbps, CPU 12–18%→3–5% при 1 Gbps); sora-сервис уже работает как root — препятствий нет | **medium** (high на быстрых линках) |
| 5 | Ничего не делать руками с GSO — новый sing-tun (1.15) уже батчит чтения (GSOSplit); просто не мешать | Батчинг чтений из TUN — доказанный множитель pps (toonk.io: сотни k → 1.5 Mpps на multi-queue) | **medium** (бесплатно с п.1) |
| 6 | Добавить замер throughput через TUN в диагностику (iperf-стиль, оба направления, 1 и 4 потока) | Встроенный speedtest у sora уже есть — прогнать его через tun и показать «потолок клиента»; ловит регрессии движков и MTU-проблемы по методологии ssdnodes | **medium** |
| 7 | Windows: задокументировать/автоматически предлагать исключение Defender для sora-core и движков | Реал-тайм сканирование всего туннельного трафика — частая причина жалоб на скорость, чинится одной галкой | **low** (дешёво) |
| 8 | macOS (будущее, когда будет клиент): держать MTU ≤1400 на utun, не гнаться за kernel-скоростями | Платформенное ограничение (только userspace); правильные ожидания + MTU спасут от «медленного VPN» на Mac | **low** (пока нет macOS) |
| 9 | Android (будущее): VpnService жёстко требует MTU ≤1500; sing-box 1.15 даёт полноценный `auto_redirect` на Android | Учесть при порте заранее, иначе те же грабли, что у всех | **low** (пока нет Android) |

## 3. Типичные ботлнеки TUN (шпаргалка для диагностики)

1. **Userspace TCP/IP-стек (gVisor)** — главный исторический ботлнек sing-box/mihomo; лечится п.1.
2. **Per-packet syscall / отсутствие батчинга** — каждый пакет = read/write; лечится GSO/batching (п.5) и multi-queue чтением.
3. **Однопоточное чтение TUN** — single-stream упирается в одно ядро (6.12 vs 9.38 Gbps); multi-stream маскирует.
4. **MTU/фрагментация** — большой MTU без поддержки пути; маленький MTU = больше pps на ту же пропускную способность.
5. **Контекстные переключения kernel↔userspace** — неустранимы в userspace-VPN; минимизируются батчингом и kernel-датапасом (WireGuardNT, kernel WG).
6. **WFP callout'ы / антивирус на Windows** — внешний налог на каждый пакет.
7. **Одно TCP-соединение vs окно/RTT** — часто «медленный VPN» это не TUN, а TCP-физика; проверять `-P 4` до тюнинга.

## 4. Открытые вопросы (нужен замер, а не поиск)

- Сколько именно даёт новый sing-tun стек в цифрах на типовом железе (разработчики пишут «substantial», цифр в changelog нет) — проверить своим бенчмарком из п.6 до/после.
- Какой MTU оптимален для связки «TUN 9000 внутри → VPN-протокол наружу» при типичных RU/EU-провайдерах — прогнать MTU-probe на реальных сетях.
