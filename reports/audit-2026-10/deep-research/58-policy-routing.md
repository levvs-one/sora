# 58. Policy routing: fwmark, таблицы маршрутизации, Android VPN-routing

Группа F «Маршрутизация и файрвол», проход 3. Дата: 2026-10-20.

## Находки

### 1. Linux: каноническая схема fwmark + отдельная таблица
- Ядро: `ip rule add fwmark <mark> table <id>` + в таблице `default dev <tun>`. **Никогда** не делать TUN дефолтом в `main` — это ломает возвратный трафик сервисов на физическом аплинке и усложняет kill switch.
- Маркировка: `iptables -t mangle -A OUTPUT -j MARK --set-mark` / в nft: `meta mark set <mark>`; для транзитного трафика — в `PREROUTING` по source/destination (метка должна стоять до routing decision).
- Reply-консистентность: `connmark` — тегировать соединение при входе с физического аплинка, клонировать в fwmark на выходе (`CONNMARK --restore-mark`). Иначе ответы на входящие соединения уйдут через туннель и умрут. Плюс `rp_filter=2` (loose) или 0 — strict mode ломает асимметричный роутинг.
- **Kill switch нижнего уровня через policy routing** (паттерн keen-pbr, проверен в проде): в VPN-таблице два маршрута — `default dev <tun> metric 100` + `blackhole default metric 200`. Туннель лёг → пакеты падают в blackhole, а не в `main`. Это дешёвая вторая линия обороны поверх nftables.

### 2. sing-box TUN и маршрутизация
- `auto_route` — sing-box сам правит системные таблицы под TUN; `strict_route` — захватывать всё без обхода. Для sora-core как службы: `auto_route: true` + собственная таблица через fwmark для трафика самого движка (чтобы handshake шёл мимо TUN — анти-луп).
- `exclude_interface` — не гнать VPN через самого себя (модемы/ppp — реальный класс багов, WEB-RESEARCH §28).

### 3. Android: VpnService.Builder — что реально умеет
- `addRoute("0.0.0.0", 0)` + `addRoute("::", 0)` = full tunnel; произвольные префиксы = split по маршрутам.
- `addAllowedApplication(pkg)` — только эти приложения через VPN (include); `addDisallowedApplication(pkg)` — эти мимо (exclude). Пустой allow-лист = все через VPN.
- `allowBypass()` — разрешить приложениям самим выбирать сеть (bindProcessToNetwork). Без этого bypass невозможен архитектурно.
- Системный kill switch: **«Always-on VPN» + «Block connections without VPN»** в настройках ОС — нативный, работает без кода приложения. Ограничение (Mullvad FAQ): с включённым «Block connections without VPN» не работает LAN sharing — честное ограничение платформы, надо показывать в UI.
- Вывод для sora-Android: не изобретать свой kill switch поверх — использовать системный флаг + объясняющий UI; per-app сплит — через allowed/disallowed; маршрутный сплит — через addRoute префиксов.

### 4. Связка с движками
- sing-box/Xray/mihomo принимают решения **внутри** (route rules), а TUN-интерфейс отдаёт им весь трафик. Policy routing уровня ОС нужен для: (а) трафика самого движка (анти-луп, handshake мимо TUN), (б) kill switch blackhole, (в) исключений, которые движок не видит (например, captive portal до поднятия TUN — тема 60).

## Вердикт: лучшее или слоп
- **Лучшее:** отдельная таблица + fwmark + blackhole-fallback; анти-луп для трафика движка; на Android — системный Always-on/Block без самодеятельности.
- **Слоп:** TUN как default в main; маркировка без connmark (ломаются входящие); свой велосипедный kill switch на Android поверх системного.

## Рекомендация «внедрить так»
1. **Linux (sora-core служба, root):** таблица `sora` (`/etc/iproute2/rt_tables` или числовой id): `default dev <tun> metric 100`, `blackhole default metric 200`; `ip rule add fwmark 0x736F72 table sora` (mark в диапазоне, не конфликтующем с Mullvad 0x6d6f6c65 и др.); трафик движка маркировать в OUTPUT mangle по UID → мимо TUN напрямую (анти-луп).
2. **Blackhole как второй рубеж:** даже если nftables-правила сняты, лежащий туннель не выпускает трафик в main.
3. **Android:** full-tunnel маршруты + per-app allowed/disallowed из настроек сплита; в UI явно вести на системные «Always-on VPN» + «Block connections without VPN» как kill switch; честно предупреждать про несовместимость с LAN sharing.
4. **Диагностика:** `ip rule` / `ip route show table sora` — в экран диагностики сети; ловит 90% «VPN подключён, а трафик идёт мимо».
5. Не делать: per-packet маркировку в userspace (дорого); управление таблицами из GUI-процесса.
