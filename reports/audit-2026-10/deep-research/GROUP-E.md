# GROUP-E — «TUN и датаплан»: сводка третьего прохода

Дата: 2026-10-20. Лид группы E. 10 тем (файлы 41–50), каждая: веб-поиск 2025–2026 + первоисточники (официальная документация sing-box, WinTun, gVisor, Android Developers, замеры ecn-apps/tech-insider/netgate) → `~/workspace/bug-hunt/reports/deep-research/`. Первый проход (WEB-RESEARCH тир 6, `web-research/46-tun-performance-tuning.md`, `48-wireguard-kernel-userspace.md`, `25-amneziawg-vs-wireguard.md`, `47-vpn-battery-impact.md`) не дублируется: здесь механика, исправление одной фактической ошибки первого прохода и новые темы 44, 49, 50.

## Исправление к первому проходу

В `46-tun-performance-tuning.md` сказано, что `"stack": "mixed"` «держит TCP на медленном gVisor». По официальной документации sing-box это неверно: **`mixed` = TCP через system-стек, UDP через gVisor**. Страдает UDP-путь (QUIC, DNS, VoIP, игры), а не TCP. Вывод «убрать `stack`» не меняется, но аргументация и приоритеты — да: снятие `mixed` чинит в первую очередь UDP.

## Сводка по темам

| # | Файл | Суть | Вердикт |
|---|---|---|---|
| 41 | [41-singbox-tun-stack.md](sandbox://workspace/bug-hunt/reports/deep-research/41-singbox-tun-stack.md) | `stack` deprecated в 1.15, удаляется в 1.17 (на 1.16 требует `ENABLE_DEPRECATED_TUN_STACK=true`); `mixed` = system-TCP + gVisor-UDP; новый стек + `multi_queue` (Linux, масштабирование по ядрам) | лучшее |
| 42 | [42-gvisor-netstack-perf.md](sandbox://workspace/bug-hunt/reports/deep-research/42-gvisor-netstack-perf.md) | gVisor: «optimized for security over performance» (gvisor.dev), «likely always will be» медленнее ядра (HN); bulk −7%, pps/conn — кратно хуже; тюнинга, догоняющего ядро, не существует | слоп как цель оптимизации |
| 43 | [43-wintun-architecture.md](sandbox://workspace/bug-hunt/reports/deep-research/43-wintun-architecture.md) | Shared-memory кольца 128 KiB–64 MiB, zero-syscall; спин встроен в драйвер (3 фазы: busy ~0.1 мс → yield → block) + userspace-спин по доке; референс rateJuggler: порог 800 Мбит/с, кольцо 8 МБ, батчинг — TODO | лучшее |
| 44 | [44-wfp-vs-wintun.md](sandbox://workspace/bug-hunt/reports/deep-research/44-wfp-vs-wintun.md) | WFP callout как датаплан — свой подписанный драйвер ради худшего перфа (риск истории апр. 2026); WFP-фильтры без драйвера — идеальный policy-слой (kill switch, per-app) | callout — слоп, фильтры — лучшее |
| 45 | [45-kernel-wireguard.md](sandbox://workspace/bug-hunt/reports/deep-research/45-kernel-wireguard.md) | Цифры подтверждены: 9.38 vs 6.12 Gbps single-stream, CPU 3–5% vs 12–18% при 1 Gbps; разрыв 1.1x–2.8x в зависимости от CPU; userspace приемлем до ~500 Мбит/с | лучшее как опциональный fast path |
| 46 | [46-amneziawg-kernel-vs-go.md](sandbox://workspace/bug-hunt/reports/deep-research/46-amneziawg-kernel-vs-go.md) | «65% overhead» — смешение оверхеда протокола (<12%) с userspace-налогом на слабом CPU; сами разработчики AWG отследили цифру до amneziawg-go; kernel: 92 vs 95 Мбит/с (−3%) | миф — слоп, разница — лучшее |
| 47 | [47-mtu-mss-pmtud.md](sandbox://workspace/bug-hunt/reports/deep-research/47-mtu-mss-pmtud.md) | Арифметика: WG 1420 = 1500−80 (худший случай); MTU 9000 → фрагментация в userspace/дропы; PMTUD black hole — обрезанный ICMP; MSS clamping (`--clamp-mss-to-pmtu`) чинит 90%; QUIC clamping игнорирует | лучшее |
| 48 | [48-android-vpnservice.md](sandbox://workspace/bug-hunt/reports/deep-research/48-android-vpnservice.md) | fd через `establish()`, hard cap MTU 1500, per-app списки до establish, DeadSystemException на множестве роутов → только `0.0.0.0/0`; always-on/lockdown — системные, бесплатно; foreground service + battery-exemption — условие выживания | лучшее (проектный задел) |
| 49 | [49-macos-utun-networkextension.md](sandbox://workspace/bug-hunt/reports/deep-research/49-macos-utun-networkextension.md) | utun через NEPacketTunnelProvider (отдельный процесс, лимиты памяти); нет kernel WG; per-app VPN только с MDM; kill switch — проект в духе Mullvad (on-demand + dummy-блок), не флажок; TunnelVision в чеклист | лучшее (проектный задел) |
| 50 | [50-tun-benchmark-methodology.md](sandbox://workspace/bug-hunt/reports/deep-research/50-tun-benchmark-methodology.md) | Протокол: контроль напрямую → TUN 1 поток → 4 потока → UDP, оба направления, ≥30 с, `-O 3`, JSON; матрица симптомов→диагнозов; CI-стенд с порогом регрессии 10%; публикация цифр | лучшее |

## Ранжированные рекомендации

### S-tier — делать сейчас, дёшево, эффект измерим

1. **Убрать `"stack"` из рендера sing-box** (`core/engine/singbox/render.go:640` — удалить строку, не менять значение), **поднять пин до ≥1.15**, **включить `multi_queue: true` на Linux**, **дефолтом `auto_redirect`** (nftables, официальная рекомендация апстрима). Иначе: UDP-деградация сегодня, отказ запуска на 1.17 завтра. Первым прогоном стенда (п.3) зафиксировать дельту.
2. **MTU 9000 → 1420** (TUN sing-box; AWG 1280 уже правильно, mihomo 1420 правильно) **+ MSS clamping** (движком или iptables/WFP; v4 = MTU−40, v6 = MTU−60). Валидация в UI: варнинг при MTU >1500. MTU-probe (`ping -M do` бинпоиск) в диагностику.
3. **Построить TUN-бенчстенд** (тема 50): скрипт матрицы + эталонный сервер + CI-порог 10% на смену пина движка + встроенный замер «потолок клиента vs потолок канала» в диагностику. Без этого все остальные пункты — «вроде лучше».

### A-tier — высокий эффект, средняя сложность

4. **Автовыбор dataplane WireGuard/AmneziaWG на Linux**: kernel-модуль через netlink когда доступен → fallback userspace. До 2.8x throughput на слабом CPU, 3x меньше CPU при 1 Gbps. Настройки: Auto / Kernel / Userspace + бейдж в диагностике.
5. **WinTun-аудит sing-tun**: размер кольца сессии (цель ≥8 МБ), spin-before-block в read-пути, drain-the-ring за проход (батчинг). Недоделки — issue/патч апстриму. Плюс исключение Defender в доке/установщике.
6. **Kill switch на WFP-фильтрах** (user-mode `FwpmFilterAdd`, без своего kernel-драйвера): ALE connect-блок + персистентность через ребут. Свой WFP callout-драйвер — никогда (риски подписи, худший перф).
7. **AWG-честность**: свои замеры WG-kernel vs AWG-kernel vs AWG-Go на одном железе → публикация в Trust Center (никто из конкурентов не даёт таких цифр). Приоритетом выше — проверка, что движок реально применяет AWG-поля, и параметры 3.1 (тема 25 первого прохода).

### B-tier — задел под платформы (проектировать сейчас, кодить при порте)

8. **Android**: Kotlin `VpnService` только владеет fd; датаплан — Go-core; MTU 1400 (cap 1500); маршруты только `0.0.0.0/0`+`::/0`; per-app через Builder-списки; экран-инструкция для системных always-on/lockdown; foreground service + battery-exemption гайд; тест-матрица (Doze 8ч, 20 смен сети, captive portal).
9. **macOS**: Go-core как `NEPacketTunnelProvider`-расширение (Swift-обёртка); бюджет памяти расширения; MTU 1400 + `exclude_mptcp`; kill switch по модели Mullvad; split только правилами движка (per-app без MDM невозможен); TunnelVision-митигация в чеклист.

### Не делать

- Тюнинг gVisor netstack (тема 42) — тупиковая ветка, апстрим удаляет.
- Свой WFP callout-драйвер как датаплан (тема 44) — дорого, хуже WinTun, риск подписи.
- Свой kernel-модуль WireGuard; форк wireguard-go ради перфа (тема 45) — watch за GotaTun после аудита 2026.
- MTU >1500 на TUN без осознанного «я понимаю» (тема 47).
- UDP-замеры с `-b` выше аплоада; выводы по одному 5-секундному потоку (тема 50).

## Сквозные принципы группы E

1. **Свежесть — это перф**: пин sing-box ≥1.15 — не «обновление ради обновления», а смена архитектуры датаплана.
2. **Честные цифры вместо маркетинга**: свой стенд, публикация замеров, бейджи dataplane — дифференциатор, которого нет ни у кого из 13 конкурентов.
3. **Платформенные ограничения — в архитектуру заранее**: Android (fd/роуты/Doze) и macOS (NE-процесс/kill switch) спроектированы до кода, а не отлажены после.
4. **Policy и datapath разделены**: WinTun/utun/tun — транспорт; WFP-фильтры/правила движка — политика. Не смешивать.
