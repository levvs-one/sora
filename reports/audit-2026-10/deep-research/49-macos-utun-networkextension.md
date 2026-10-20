# 49 — macOS: utun, NetworkExtension, поддержка в sing-box; ограничения

Дата: 2026-10-20. Третий проход группы E. macOS-клиента у sora пока нет. Здесь — платформенные ограничения, которые надо заложить в архитектуру заранее, а не обнаружить при порте.

## 1. utun: что это и чем отличается от Linux TUN

- На macOS нет `/dev/net/tun`. VPN-клиенты получают L3-интерфейс через **NetworkExtension**: `NEPacketTunnelProvider` создаёт интерфейс `utun[0-9]+`, приложение читает/пишет IP-пакеты через `packetFlow` (`readPackets`/`writePackets`) или сырой fd (`tunnelFileDescriptor`).
- Классические TUN/TAP kext (tuntaposx) мертвы: сторонние kernel extensions на современном macOS практически невозможны (SIP, user-approved KEXT, deprecation). Путь только через NetworkExtension.
- Имена интерфейсов ограничены `utun[0-9]+` — нельзя выбрать произвольное имя (vpnsmith.com, 2026).
- sing-box TUN inbound «Only supported on Linux, Windows and macOS» — на macOS работает через utun. Новый стек 1.15 (без `stack`) применим и там.

## 2. NetworkExtension: энтайтлменты и процессная модель

- Энтайтлмент `com.apple.developer.networking.networkextension` со значением `packet-tunnel-provider` — обязателен. Для App Store — через стандартный capability-запрос; для распространения вне Store — тоже доступен, но профиль нужно оформлять корректно (пример: nthlink-os-macos, PacketTunnel.entitlements).
- Туннель живёт в **отдельном процессе-расширении** (`NEPacketTunnelProvider`), а не в приложении. Следствия:
  - **Лимиты памяти**: на iOS расширение жёстко ограничено (~50 МБ, система убивает при превышении); на macOS лимит выше, но расширение всё равно под присмотром `nehelper` — течь памяти = смерть туннеля. Go-рантайм с дефолтным GC в расширении — проектировать с `GOGC` повыше и лимитом heap, либо держать движок в приложении и гонять пакеты через IPC (дорого).
  - **Коммуникация app ↔ расширение**: только через App Groups (shared UserDefaults/файлы) и `NETunnelProviderSession` сообщения. Конфиг движка — сериализовать, передавать при старте; хот-реконфиг — сообщениями.
  - Приложение может быть убито, а туннель продолжает работать — и наоборот. Состояние подключения — запрашивать у `NETunnelProviderManager`, не хранить в UI-памяти.
- `NEPacketTunnelNetworkSettings`: адреса, `includedRoutes`/`excludedRoutes`, DNS (`dnsSettings`), `mtu`. Маршрут по умолчанию — `NEIPv4Route.default()` / `NEIPv6Route.default()`.

## 3. Ограничения, критичные для sora

1. **Нет kernel WireGuard** — и не будет. Только userspace (wireguard-go / BoringTun / GoтаTun-аналоги). Потолок скорости ниже Linux (тема 45). Правильные ожидания + MTU ≤1400.
2. **Per-app VPN — только через MDM** (управляемые устройства, `NEPerApp...`). Для consumer-клиента per-app сплит на macOS недоступен как класс. Split tunneling — только по доменам/IP через правила движка внутри TUN, не средствами ОС.
3. **Kill switch честный — сложен**: `includeAllNetworks` (iOS 14+/macOS) теоретически не пропускает ничего мимо туннеля, но Mullvad сознательно его **не использует**: «We have determined that from a security and privacy standpoint… TunnelVision (CVE-2024-3661) and TunnelCrack… are virtually identical». Вместо этого — on-demand rules + трюк с dummy-туннелем в error-state (блок всего трафика через остановленный WireGuard-адаптер). Урок: kill switch на Apple-платформах — отдельная инженерная задача, не «флажок».
4. **TunnelVision (CVE-2024-3661)**: declined DHCP-роуты могут увести трафик мимо туннеля. Митигация — `includeAllNetworks` или ручная чистка роутов; держать в чеклисте аудита.
5. **DNS**: macOS агрессивно использует все доступные резолверы (multihomed); `dnsSettings` расширения + `strict_route`-аналог нужны, иначе утечки. sing-box `dns_mode: hijack` покрывает частично.
6. **Пробуждение/сон**: `disconnectOnSleep` — туннель рвётся при сне; переподключение по пробуждению должно быть быстрым и бесшумным (on-demand rules).
7. **MPTCP**: Apple-устройства любят MPTCP — sing-box 1.13+ имеет `exclude_mptcp` («MPTCP cannot be transparently proxied»): включать, иначе странные обрывы на Apple-технике.

## 4. sing-box на macOS: что поддерживается

- TUN inbound через utun — да; новый стек 1.15 — да (кроссплатформенный).
- `auto_redirect` — нет (только Linux/nftables). Роутинг — через системные route-команды (`auto_route`).
- `route_address_set` с большими списками — работает (лимит DeadSystemException — только Android).
- `platform.http_proxy` — системный HTTP-прокси из настроек ОС; `bypass_domain` матчит **суффиксы** на Apple-платформах.

## 5. Вердикт: лучшее или слоп

**Лучшее — как набор ограничений для проектирования.** Ничего из этого не блокирует macOS-клиент, но каждое нарушение стоит месяцев: отдельный процесс расширения с лимитом памяти, отсутствие per-app VPN без MDM, kill switch как проект, а не флажок.

## 6. Рекомендация «внедрить так» (задел под будущий macOS-клиент)

1. Архитектура: Go-core как `NEPacketTunnelProvider`-расширение (gomobile невозможен для NE — писать Swift/ObjC-обёртку, Go — статическая библиотека). Конфиг — сериализованный JSON при `startTunnel`, управление — `NETunnelProviderSession` сообщениями.
2. Память расширения: бюджет и мониторинг (Xcode Memory Debugger в CI-нагрузке); `GOGC` тюнинг; алерты на рост heap в телеметрии.
3. MTU utun дефолт **1400**, MSS clamping включён; `exclude_mptcp: true`.
4. Kill switch: проектировать как у Mullvad (on-demand + error-state dummy-блок), не полагаться на `includeAllNetworks` вслепую; в чеклист — TunnelVision-митигация.
5. Split tunneling на macOS — только L3/L4-правилами движка (домены/IP), per-app средствами ОС не делать (невозможно без MDM) — честно сказать в UI.
6. DNS: `dns_mode: hijack` + проверка утечек в диагностике (multihomed-резолверы macOS).
7. Состояние туннеля — всегда из `NETunnelProviderManager`, UI не хранит своё «подключено».
