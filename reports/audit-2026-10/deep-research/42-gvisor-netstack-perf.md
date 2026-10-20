# 42 — gVisor netstack: честные характеристики, тюнинг, когда проигрывает ядру

Дата: 2026-10-20. Третий проход группы E. Первый проход зафиксировал консенсус «gVisor всегда медленнее ядра». Здесь — цифры, механика отставания и честный ответ на вопрос «а потюнить можно?».

## 1. Позиция самого gVisor (первоисточники)

- Официальный production-гайд (https://gvisor.dev/docs/user_guide/production/, раздел «Optimizing network performance»): «Networking is typically the **second most-impacted** performance characteristic… gVisor implements its own network stack, **which is optimized for security over performance**». Для тех, кому сеть важнее изоляции, есть опция **Network Passthrough** — отдать трафик хостовому стеку Linux вместо netstack.
- Официальный блог gVisor, 2026-10-02: команда сама признаёт «performance perception problem» — «out-of-the-box performance often shows performance degradation for certain I/O-intensive workloads» (https://gvisor.dev/blog/2026/10/02/gvisor-cncf/).
- Ключевая цитата из обсуждения userspace TCP-стеков (HN): «gVisor's netstack is **still much slower than the kernel's (and likely always will be)**. The goal of this userspace netstack is not to compete with the kernel on performance, but offer an alternative that is more portable and secure» (https://news.ycombinator.com/item?id=40586757).

## 2. Честные цифры

Прямых «gVisor netstack vs kernel, Gbps» бенчмарков в 2025–2026 мало — показательно само по себе (никто не меряет, потому что ответ известен заранее). Что есть:

- Замеры виртуализации (Oulu, serverless): bulk throughput gVisor ~875 Мбит/с против ~940 Мбит/с bare metal на гигабитном линке — **~7% потерь на bulk**, но джиттер и дисперсия выше (stddev 25.75 против 1.59). Bulk — лучший кейс netstack; на мелких пакетах и conn/s разрыв кратный.
- Отраслевые оценки I/O-overhead gVisor в целом: 10–30% на I/O-heavy workloads (northflank, sitepoint, 2025–2026). Сеть — второй по страданию компонент после файлового I/O.
- Контекст TUN: в sing-box `mixed`-режиме весь UDP-путь (QUIC, DNS, VoIP) идёт через netstack. QUIC особенно болезнен: netstack реализует упрощённый TCP (консервативные congestion control, нет современных оптимизаций ядра — BBR, RACK, pacing ядра), а UDP-путь добавляет userspace-конвейер поверх.

Механика отставания (почему «likely always will be»):
1. **Нет доступа к ядерным оптимизациям**: GSO/GRO-батчинг на входе, TCP pacing, BBR, threaded NAPI — всё это живёт в ядре и не портируется в userspace один в один.
2. **Двойной проход данных**: пакет копируется kernel→userspace (TUN read), обрабатывается netstack, копируется обратно (socket write) — минимум 2 лишних копирования и 2 контекстных переключения на пакет против нуля у kernel-пути.
3. **Планировщик**: netstack работает в userspace-потоках Go-процесса, без приоритетов softirq; под нагрузкой конкурирует с остальным приложением за CPU.

## 3. Тюнинг: что реально существует

Честный ответ: **потюнить netstack до уровня ядра нельзя** — это архитектурный потолок, а не недонастройка. Существующие рычаги:

- **Платформа gVisor (KVM vs systrap/ptrace)**: самый высокоуровневый рычаг, но в sing-box неприменим — там netstack встроен как библиотека, платформа не выбирается.
- **Network Passthrough** (gvisor.dev): отдать сокеты хостовому стеку. В sing-box это эквивалент `stack: system` / нового стека 1.15 — т.е. «тюнинг» = не использовать netstack.
- **Буферы сокетов** (`net.core.rmem_max` и т.п.): системные sysctl влияют на хостовую сторону, но не на внутреннюю логику netstack; эффект — проценты, не разы.
- В sing-box не экспонируется ни один netstack-тюнабл (нет опций размера окон, CC-алгоритма, числа воркеров netstack). Крутить нечего — это тоже ответ.

## 4. Когда gVisor приемлем (честные границы)

- Линки ≤200–300 Мбит/с, немелкопакетный трафик: разница с ядром не видна пользователю (bulk-потери ~7%).
- Портативность важнее скорости: netstack одинаков на Linux/Windows/macOS — для кроссплатформенного клиента это был аргумент до 1.15.
- **Неприемлем**: гигабитные линки, UDP-heavy (QUIC/игры/VoIP), высокий pps, ноутбуки на батарее (лишние копии = лишние ватты).

## 5. Вердикт: лучшее или слоп

**Слоп — как цель оптимизации.** Тратить инженерное время на тюнинг gVisor-пути в 2026 году — это оптимизация тупиковой ветки: апстрим её deprecated, в 1.17 удаляет, а потолок архитектурный. Единственный «тюнинг» gVisor, который имеет смысл, — перестать его использовать.

## 6. Рекомендация «внедрить так»

1. Не инвестировать ничего в gVisor-тюнинг. Удаление `stack` (тема 41) автоматически уводит весь трафик с netstack.
2. В диагностике/доке честно зафиксировать: «до 1.15 UDP-путь шёл через gVisor netstack — архитектурно медленнее ядра, не тюнится; с 1.15 используется собственный стек sing-tun».
3. Если где-то в коде/конфигах остались упоминания `stack: gvisor` как «быстрого варианта» — вычистить как вводящие в заблуждение.
4. Единственное место, где netstack остаётся релевантен sora, — mihomo: проверить, какой стек использует mihomo TUN в пинящейся версии, и применить ту же логику (дефолт нового стека, без gVisor).
