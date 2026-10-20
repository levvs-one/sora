# 56. WFP kill switch на Windows: слои, персистентность

Группа F «Маршрутизация и файрвол», проход 3. Дата: 2026-10-20.

## Находки

### 1. Архитектура WFP (Microsoft docs + практика вендоров)
- Компоненты: **фильтры** (permit/block по IP/порту/приложению/пользователю/интерфейсу), **слои** (точки в стеке), **подслои** (группировка, предсказуемость). User-mode — Base Filtering Engine (BFE) сервис, kernel-mode — сам WFP.
- Для kill switch нужны **ALE-слои** (Application Layer Enforcement): `FWPM_LAYER_ALE_AUTH_CONNECT_V4/V6` (исходящие TCP/UDP, решение на первом пакете), `FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4/V6` (входящие), `FWPM_LAYER_ALE_FLOW_ESTABLISHED_V4/V6` (уведомление об установке). ALE stateful: решение принимается **раз на соединение**, а не на пакет — на порядки дешевле пакетной фильтрации (официальная рекомендация Microsoft).
- Свои фильтры — в **собственный sublayer** с высоким весом (не в дефолтный: там их может перекрыть Windows Firewall своими terminating-правилами).

### 2. Персистентность: FWPM_FILTER_FLAG_PERSISTENT
- Фильтры бывают временными и постоянными. **Постоянные переживают ребут**: BFE применяет их при старте `tcpip.sys` на загрузке — то есть до того, как поднимется пользовательская сессия и сеть. Это и есть Windows-аналог «strict через ребут».
- Boot-time защита: постоянные фильтры активны с ранней загрузки — окно утечки между включением сетевого стека и стартом VPN-клиента закрыто.
- Снятие — только явным удалением фильтров (при выключении Strict пользователем). Краш приложения фильтры не снимает — ключевое отличие от динамических.

### 3. Эталоны
- **Mullvad (Windows):** WFP; известная боль — `failed to apply firewall rules` / `Initiate WFP transaction: The call timed out while waiting to acquire the transaction lock` — конфликт за BFE transaction lock со сторонними AV/файрволами. Вывод: все изменения фильтров — в одной транзакции, с retry и понятной ошибкой в UI.
- **Windscribe (открытый код):** класс `FirewallFilter` поверх WFP+BFE; kill switch = блок всего кроме VPN-трафика и essential (DHCP, DNS к своим серверам); явная IPv6-защита (блок IPv6 при IPv4-only туннеле); детект состояния BFE при ограничении доступа к SCM.
- **TunSafe:** kill switch через WFP + DNS-блок.

### 4. Состояние репо sora (факты)
- `sora-legacy/core/guard/firewall_windows.go`: WFP через `github.com/tailscale/wf`, **динамический sublayer** `Sora kill switch` с весом `0xFFFF`, слои `ALE_AUTH_CONNECT_V4/V6`, матчинг движка по executable (на Windows нет UID), разрешены TUN/local/DHCP/neighbor-discovery.
- Комментарий в коде честно фиксирует ограничение: «Windows removes filters on close or process exit, allowing traffic after crashes, as WireGuard and Tailscale do» — то есть текущий уровень = Standard (защита от случайных утечек при живом процессе), но **не Strict**: краш/ребут без службы = снятие фильтров.
- Вывод: архитектура правильная (свой sublayer, ALE, app-matching), не хватает persistent-варианта для Strict.

### 5. Реализация persistent в Go
- `golang.org/x/sys/windows`: `FwpmEngineOpen0`, `FwpmSubLayerAdd0`, `FwpmFilterAdd0` с `FWPM_FILTER_FLAG_PERSISTENT`. `tailscale/wf` persistent-флаги не выставляет (динамическая модель) — для Strict нужен либо форк/расширение, либо прямые вызовы x/sys.
- Требуется привилегия: ставит фильтры SYSTEM-служба (sora-core как служба на Windows). GUI-процесс пользователя persistent-фильтры ставить не должен (и не сможет без UAC).

## Вердикт: лучшее или слоп
- **Лучшее:** persistent ALE-фильтры в собственном sublayer (вес 0xFFFF) для Strict: block-all + allow (tunnel endpoint по app-id/порту, DHCP, DNS→туннель, TUN-интерфейс, опционально LAN); явный блок IPv6 при IPv4-туннеле; BFE-конфликты с retry и диагностикой.
- **Слоп:** только динамические фильтры под видом «strict» (снимаются крашем); фильтрация на транспортных слоях вместо ALE (дорого); свой sublayer с дефолтным весом (перекрывается Windows Firewall).

## Рекомендация «внедрить так»
1. **Два режима WFP-гарда:** Standard = текущий динамический (как сейчас, через `wf`); **Strict = persistent-фильтры** (`FWPM_FILTER_FLAG_PERSISTENT`), ставятся службой, переживают ребут и краш, снимаются только явным выключением Strict.
2. Sublayer «Sora kill switch», вес 0xFFFF (уже есть — переиспользовать); фильтры: `ALE_AUTH_CONNECT_V4/V6` block-all внизу, выше — permit: app-id движка → endpoint IP/порт, `oif` TUN-интерфейс, DHCP (67/68), ICMPv6 neighbor discovery; IPv6 — либо mirror-permit через туннель, либо явный block при IPv4-only.
3. **BFE-конфликты:** все операции в одной транзакции, retry с backoff при `FWP_E_TIMEOUT`, в UI — понятная ошибка «конфликт с <AV>», а не «failed to apply firewall rules».
4. Self-test как в теме 55: попытка утечки мимо туннеля при включённом Strict → проверка блока → статус в UI.
5. При выключении Strict — удалять persistent-фильтры и **проверять**, что удалились (иначе «интернет сломался» после выключения VPN — классическая жалоба, Mullvad FAQ фиксирует тот же класс проблем).
