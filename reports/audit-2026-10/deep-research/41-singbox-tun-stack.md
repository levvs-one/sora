# 41 — sing-box TUN: стеки system/gVisor, новый стек 1.15, deprecation `stack`

Дата: 2026-10-20. Третий проход группы E. Первый проход (WEB-RESEARCH тир 6, отчёт `web-research/46-tun-performance-tuning.md`) установил факт: 1.15 переписал стек, `stack` deprecated, удаление в 1.17, sora рендерит `"stack": "mixed"` + MTU 9000. Здесь — механика до уровня исходников и документации, что именно делает `"mixed"`, что сломается и когда, и что даёт новый стек сверх «substantial improvements».

## 1. Что именно означают значения `stack` (первоисточник — официальная документация)

https://sing-box.sagernet.org/configuration/inbound/tun/ (раздел `stack`, состояние на 1.15):

| Значение | Механика |
|---|---|
| `system` | L3→L4 трансляция через системный сетевой стек ОС |
| `gvisor` | L3→L4 через виртуальный стек gVisor netstack |
| `mixed` | **TCP через `system`, UDP через `gvisor`** |

Уточнение к первому проходу: там было написано, что `"mixed"` «держит TCP на медленном gVisor» — это неверно. По документации `mixed` = system-TCP + gVisor-UDP. Исторический смысл `mixed`: раньше system-стек плохо умел UDP NAT/conntrack, и UDP отдавали gVisor. Практический вывод не меняется, но причина другая: **в `mixed` страдает UDP-путь** (QUIC, DNS, VoIP, игры — всё через userspace-стек), а не TCP.

## 2. Хронология deprecation (первоисточники)

- sing-box 1.8.0: legacy LWIP-стек deprecated и удалён (та же страница документации, `stack` → «Changes in 1.8.0»).
- sing-box 1.15.0-alpha.3 (changelog): «Significantly improve TUN performance with a new TCP/IP stack. Since 1.15.0, sing-tun uses its own TCP/IP stack, with substantial improvements over all previous implementations in peak performance, energy efficiency, and memory usage» (https://sing-box.sagernet.org/changelog/).
- 1.15.0: опция `stack` deprecated. Миграционная страница: «Remove the `stack` option to use it» (https://sing-box.sagernet.org/migration/).
- 1.16.0: использование `stack` требует `ENABLE_DEPRECATED_TUN_STACK=true` в окружении, иначе отказ.
- **1.17.0: опция удаляется.** Конфиг с `"stack": "mixed"` перестанет валидироваться — движок не стартует.

Что будет, если оставить `"mixed"`:
- на 1.15: ворнинг о deprecated + принудительно старый путь (system-TCP/gVisor-UDP), новый стек недоступен;
- на 1.16: без `ENABLE_DEPRECATED_TUN_STACK=true` — отказ запуска;
- на 1.17: жёсткая ошибка валидации конфига, TUN не поднимется вообще.

## 3. Что даёт новый стек сверх маркетинга (из документации и кода)

Новый собственный TCP/IP-стек sing-tun (репозиторий `SagerNet/sing-tun`, используется sing-box ≥1.15 как дефолт при отсутствии `stack`):

1. **`multi_queue` (новое в 1.15, только Linux, требует новый стек).** Документация: «Enable multi-queue support based on `IFF_MULTI_QUEUE`, allowing throughput to scale with the number of CPU cores». Это прямой ответ на главный ботлнек userspace-TUN — однопоточное чтение `/dev/net/tun`. Эксперимент toonk.io (окт 2026) показал: multi-queue доводит stock wireguard-go с сотен kpps до ~1.5 Mpps без смены архитектуры. sing-box теперь даёт это из коробки флагом.
2. **Единый стек для TCP и UDP** — уходит асимметрия `mixed` (два разных кода трансляции, два набора багов и тюнинга).
3. **Энергоэффективность и память** — заявлены в changelog; для ноутбуков и будущего Android-клиента это важнее пиковых Gbps.

Важно: опция `gso` («GSO has no advantages for transparent proxy scenarios») deprecated ещё в 1.11 и удалена в 1.12 — руками GSO крутить не нужно и вредно.

## 4. Смежные находки из той же страницы документации (для других тем группы)

- `auto_redirect` «always recommended on Linux»: лучше роутинг, выше производительность, чем tproxy, решает конфликты с Docker bridge. Для sora на Linux — включать дефолтом вместо чистого TUN-роутинга.
- Android: `route_address_set` «doesn't work on the Android graphical client due to the Android VpnService not being able to handle a large number of routes (DeadSystemException)» — жёсткое ограничение платформы, учесть при порте (тема 48).
- `auto_redirect` «fully supported on Android through the root service of the graphical client or a root shell».
- `dns_mode: hijack` — дефолт при `auto_route`; на Windows со `strict_route` блокирует DNS мимо TUN (релевантно kill switch, тема 44).

## 5. Вердикт: лучшее или слоп

**Лучшее.** Новый стек — не маркетинг: это смена архитектуры (свой TCP/IP-стек + multi-queue), deprecation-таймлайн жёсткий и задокументированный. Оставление `"mixed"` — это одновременно перф-деградация UDP-пути сегодня и гарантированная поломка конфига на 1.17.

## 6. Рекомендация «внедрить так»

1. **Убрать `"stack"` из рендера** (`core/engine/singbox/render.go:640` — удалить строку целиком, не менять дефолт на другое значение). Поле `t.Stack` в плане можно оставить для обратной совместимости, но рендер должен его игнорировать с варнингом в лог.
2. **Поднять минимальный пин sing-box до ≥1.15** (сейчас код ориентируется на 1.12–1.14: см. `engine.go`, `render.go`). Без этого удаление `stack` бессмысленно.
3. **Включить `"multi_queue": true` на Linux** при отсутствии `stack` — бесплатное масштабирование чтения TUN по ядрам. Завернуть в capability-check версии ≥1.15.
4. **На Linux дефолтом включать `auto_redirect`** (nftables) вместо голого TUN-роутинга — официальная рекомендация апстрима, выше перф и нет конфликта с Docker.
5. **Валидация конфига в CI**: тест, что рендер sing-box не содержит ключа `stack` ни при каких входных планах (регрессия в духе «вернули mixed»).
6. Снятие `"mixed"` также чинит UDP-путь (QUIC/DNS/игры) — это замерить отдельным прогоном методологии из темы 50, а не верить changelog на слово.
