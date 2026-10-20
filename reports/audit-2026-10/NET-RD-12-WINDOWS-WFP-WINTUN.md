# NET-RD 12/20: Windows — WFP vs WinTun

R&D-отчёт: что используют топовые клиенты, что уже есть в sora/legacy, спека P0/P1/P2.
Ветка `bugfix/audit-2026-10-19`, пуша нет. **Фильтр слопа владельца применён** — см. §5.

## 1. Каталог публичных техник (2025–2026)

**WFP и WinTun — не конкуренты, а ортогональные слои.** WinTun (WireGuard LLC, L3 TUN-драйвер,
NDIS 6) — это *виртуальный адаптер*, который двигает пакеты. WFP (Windows Filtering Platform) —
это *платформа фильтрации*, которая решает, каким пакетам жить. Каждому VPN-клиенту на Windows
нужны оба: WinTun (или аналог) несёт трафик, WFP его душит/режет. Путать их — слоп.

### 1.1. Kill switch через WFP (user-mode, без драйвера) — стандарт индустрии

- **WireGuard for Windows** (`tunnel/firewall/`): динамическая WFP-сессия
  (`FWPM_SESSION_FLAG_DYNAMIC` — фильтры умирают вместе с процессом), отдельный провайдер +
  саблейер, транзакционная установка. Лестница весов: permit сервиса (15) > DNS pin (15/14) >
  loopback (13) > **TUN по LUID адаптера (12)** > DHCP (12) > block-all (0). Фильтры ставятся
  только при catch-all `0.0.0.0/0`.
- **Tailscale** (пакет `tailscale/wf` — тот же, что использует sora): та же динамическая модель.
- **sora** (`core/guard/firewall_windows.go`): динамическая сессия, саблейер 0xffff (выше всех),
  веса 0/10/20/30/40/50; пермиты: exe движков+ядра по AppID+SID пользователя (Windows без UID),
  loopback, TUN-сети с проверкой `NexthopInterfaceType == 53` (+ reauthorize-пермит по
  `ArrivalInterfaceType`), блок destinations туннеля, блок DNS :53 вне туннеля, LAN-bypass,
  DHCP/DHCPv6/ND. Плюс **ingress-guard** (`ingress_windows.go`): `ALE_AUTH_RECV_ACCEPT`
  дропает входящие мимо туннеля — этого нет даже у WireGuard-клиента из коробки.
- **IVPN** (open source, `ivpn/desktop-app`): тот же WFP-подход, но **persistent-фильтры** и
  режим «always-on», включая защиту **при загрузке ОС**. Файрвол независим от клиента —
  переживает краш.
- **NordVPN (2025)**: «system-level kill switch», переживающий жёсткий краш — по механике это
  те же persistent WFP-фильтры, что у IVPN (маркетинговую обёртку отбрасываем, технику берём).

Динамическая модель честно fail-open после краша (как WireGuard/Tailscale) — это осознанный
трейд-офф, а не баг. Persistent-модель честно fail-closed — сильнее, но может «окирпичить»
сеть при баге.

### 1.2. Per-app split tunneling: два уровня

**Уровень A — user-mode (без драйвера).** sora сейчас здесь: sing-box `process_name`,
mihomo `PROCESS-NAME`, xray — правила `process` в routing. Аттрибуция процесса — в юзерспейсе
(IP Helper API). Честные ограничения (их документирует даже Mullvad для своего драйвера):
DNS от `dnscache`/`svchost` атрибутировать некому — уходит в туннель; дочерние процессы надо
перечислять явно; race между захватом пакета TUN и аттрибуцией.

**Уровень B — WFP callout-драйвер (ядро). Mullvad `win-split-tunnel` (v1.2.4.0, open source):**
WDF-драйвер с ALE-connect callout: сокеты исключённых процессов биндятся на физический
интерфейс мимо туннеля; атомарная классификация (без race), наследование дочерними
процессами, убийство pre-existing соединений при смене конфига, динамическая
реконфигурация. Цена — см. §4.

### 1.3. TUN на Windows

- WireGuard/Tailscale/Cloudflare WARP — WinTun. sing-box/mihomo `system`-стек — тоже WinTun
  (нужен `wintun.dll` рядом с движком; gVisor-стек — без драйвера вообще).
- sora: sing-box `tun` inbound, `stack: mixed` (дефолт), `interface_name: sora0`, `auto_route`
  на Windows; xray/mihomo — аналогично. Проверка: в `packaging/` нет `wintun.dll` —
  system-стек молча зависит от наличия драйвера (P1-4).

## 2. Что есть в sora / sora-legacy и чего не хватает

| Техника из каталога | sora | legacy | Статус |
|---|---|---|---|
| WFP dynamic kill switch (outbound) | ✅ полный | ✅ минус 2 фикса | портировано (d58a454) |
| WFP ingress-guard (inbound) | ✅ есть | ? не проверял детально | — |
| TUN-permit по **LUID** адаптера (как WireGuard) | ❌ type-53 | ❌ type-53 | P1-1 |
| Persistent always-on (как IVPN) | ❌ | ❌ | P1-2 |
| Inverse split («только эти приложения в VPN», как NordVPN) | ❌ нет plan-режима | ❌ | P1-3 |
| wintun.dll в поставке/проверка | ❌ не зафиксировано | ❌ | P1-4 |
| Callout-драйвер split (как Mullvad) | ❌ | ❌ | P2-1 (с ценой) |
| Честные ограничения user-space split в доках | ❌ | ❌ | в спеке |

## 3. Спека P0/P1/P2

### P0 — сделано коммитами
- `[net-rd] guard: port SORA-M10/SORA-L20 kill-switch fixes to legacy Windows firewall`
  (sora-legacy `d58a454`; `GOOS=windows go build+vet` ✅).
- `[net-rd] guard: lock WFP kill-switch weight hierarchy with a test`
  (sora `104fc0c`, новый файл `core/guard/firewall_weights_windows_test.go`; gofmt ✅,
  `go vet` заблокирован чужой поломкой — см. §6).

### P1
- **P1-1. TUN-permit по LUID `sora0` вместо `IF_TYPE_PROP_VIRTUAL` (53).** Сейчас пермит
  «трафик с TUN-адресом через виртуальный адаптер» матчит *любой* type-53 адаптер
  (Hyper-V, WSL2, чужой VPN). WireGuard матчит LUID своего туннеля — точнее и без новых
  зависимостей (`FWPM_CONDITION_IP_NEXTHOP_INTERFACE`, `FWP_UINT64`, `wf` умеет).
  Сложность: малая+. Нюанс: kill switch встаёт *до* запуска ядра, адаптера ещё нет —
  нужен `SetTunInterfaceLUID` + резолв LUID после создания адаптера (супервизор уже ждёт
  адаптер) с фолбэком на type-53. Фильтр слопа: ✅ делает ровно то, что лучший в классе.
- **P1-2. Опциональный persistent always-on kill switch (техника IVPN).** FWPM persistent-
  фильтры переживают краш процесса; ставит/снимает привилегированный сервис; защита с
  загрузки ОС. Закрывает главное честное ограничение dynamic-модели. Сложность:
  средняя-высокая. Обязательно: opt-in, recovery-UX («не окирпичить сеть»), тесты на
  перезагрузку. Подпись драйвера **не** нужна — persistent-объекты ставит user-mode сервис
  с админ-правами. Фильтр слопа: ✅ реальная безопасность, IVPN доказывает шиппабельность;
  не маркетинг.
- **P1-3. Inverse split-tunnel** («только выбранные приложения через VPN», у NordVPN есть
  оба направления). Движок уже умеет (rule targets), нужен plan-режим + UI (UI — не моя
  зона). Сложность: малая/средняя. Фильтр слопа: ✅ симметрия фичи, без драйвера.
- **P1-4. Зафиксировать wintun.dll для system-стека.** Честное ограничение: без WinTun
  system-стек не поднимется; инсталлер должен класть `wintun.dll` рядом с движками
  (лицензия wintun.net это разрешает при скачивании с официального сайта) или явно
  фолбэчить на gVisor с предупреждением. Сложность: малая. Фильтр слопа: ✅ убирает
  молчаливый даунгрейд.

### P2
- **P2-1. Mullvad-grade WFP callout-драйвер для split tunneling.** Лучшая корректность:
  атомарная классификация, дочерние процессы, без TUN-захвата. **Честная цена:**
  kernel-драйвер, EV-сертификат + Microsoft attestation/WHQL-подпись *каждого* релиза,
  риск BSOD, аудит драйвера, конфликт с принципом «релизы должны быть лёгкими».
  Дефолт остаётся user-space (уровень A). Внедрять только осознанным решением владельца.
  Фильтр слопа: ✅ лучшее техническое решение, но цена выписана явно.

## 4. Честные ограничения: что требует драйвера/подписи, а что нет

- **Не требует драйвера:** весь текущий kill switch sora; persistent always-on (P1-2) —
  достаточно привилегированного сервиса; user-space per-app split.
- **Требует kernel-драйвера + EV + attestation-подписи каждого релиза:** только P2-1
  (Mullvad-подобный callout). WinTun сам по себе уже подписан WireGuard LLC —
  sora его не подписывает, только поставляет `wintun.dll`.
- **Не решается без драйвера:** аттрибуция DNS от `dnscache`/`svchost` к процессу —
  документированное ограничение даже у Mullvad; принять и задокументировать.

## 5. Фильтр слопа: что вычеркнуто и почему

- ❌ **Surfshark «Bypasser: приложения И сайты» как отдельная техника** — «сайты» это
  обычные domain/IP-правила, которые rule engine sora уже умеет. Маркетинговое
  переименование, не техника.
- ❌ **VPN Lifeguard и внешние вотчеры** — костыль вместо архитектуры.
- ❌ **Маркетинговые цифры скорости** (обзоры с «400–600 Мбит/с») — в спеке только
  механизмы, никаких цифр.
- ❌ **Quirk WireGuard «kill switch только при 0.0.0.0/0»** — UX-частность, не техника.
- ❌ **«NordVPN-like kill switch» как пункт спеки** — берём механику (persistent WFP),
  отбрасываем бренд.

## 6. Коммиты, инциденты, блокеры

- Коммиты: sora-legacy `d58a454` (M10+L20, build+vet ✅); sora `104fc0c` (тест весов,
  gofmt ✅).
- **Инцидент:** `104fc0c` случайно включил 6 staged-файлов чужого net-rd агента
  (mihomo/config.go, mihomo/proxy.go, mihomo/render_test.go, engine/plan.go,
  singbox/render.go, singbox/render_test.go). Контент цел; владелец продолжил работу
  поверх (ffdf453, 1da01e9, be01e06). Историю из 12 коммитов на горячей ветке не
  переписывал — добавил `git notes` к `104fc0c`. Нужно решение parent.
- **Блокер:** `core/` sora не собирается — `engine/validate.go` ссылается на
  несуществующие `validateHysteria2Tuning`/`validateTUICTuning` (коммит `7e0403d`,
  чужой net-rd). Мой тест проверен gofmt + ручной сверкой идентификаторов; `go vet`
  перезапустить после фикса владельца.
- Предсуществующий gofmt-дефект `core/guard/nftables.go` — не мой, не трогал.
- MSDN-страница filtering-condition-identifiers недоступна из песочницы (403);
  LUID-доступность на `ALE_AUTH_CONNECT` подтверждена кодом WireGuard
  (`permitTunInterface` матчит TUN LUID на том же слое).
