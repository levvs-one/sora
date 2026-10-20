# NET-RESEARCH: сводка R&D сетевого стека sora

Дата: 2026-10-19. Формат: 20 исследователей × 1 тема, веб-поиск 2025–2026 + анализ кода
sora и sora-legacy (ветка `bugfix/audit-2026-10-19`, пуша нет).
**Фильтр слопа владельца применён ко всем 20 спекам**: безупречное качество,
продуманность, оптимизация, честные измерения (никаких маркетинговых цифр), минимализм.
Каждая позиция ниже помечена, откуда она (тема + коммит/спека); вычеркнутое фильтром —
в §21. Мелкие улучшения закоммичены как `[net-rd]`, крупное — спекой.

## Темы 1–5: протоколы и обфускация

### 1. REALITY + XHTTP (Xray)
Xray-core 26.x (sora pin 26.3.27, апстрим уже 26.9.30+): XHTTP-режимы `auto/packet-up/stream-up/stream-one`,
поле `headers` (маскировка User-Agent 2026), XHTTP/3 (ALPN h3, BBR по умолчанию), REALITY+PQ
(X25519MLKEM768 автоматом при поддержке фингерпринтом, ML-DSA-65 серверно), клиентский TLS ECH
(RFC 9849, 03.2026; в 2026 дефолт `echForceQuery="full"`), переименование `network`→`method`,
с v26.7.11 запрет нешифрованных VLESS/Trojan на публичные IP, Finalmask (2026).
**sora**: xhttp (mode/path/host/auto), REALITY, VLESS Encryption, парсер ссылок, ALPN→tlsSettings —
проброшены; запрещает insecure-TLS. **Не проброшено**: `headers` в xhttpSettings (sing-box/mihomo
уже отдают — рассинхрон), ECH, downloadSettings/xmux, нет пина минимальной версии Xray.
Спека: P0 — XHTTP headers (подготовлен рабочий дифф, не коммитился: дерево было грязным чужими
изменениями), REALITY-hygiene в валидации (варнинг на не-443 порт и цели apple*/icloud* — Xray
банит IP сервера), пин минимальной версии Xray с гейтом для XHTTP/PQ; P1 — ECH-клиент opt-in
(`echForceQuery="half"`, никогда дефолт `full`), верификация `network` vs `method`, XHTTP/3 runbook;
P2 — downloadSettings (ниша CDN), форматы ключей VLESS Encryption.
**Фильтр вычеркнул**: Finalmask (театр без измерений), XHTTP `obfuscations` (сырая, баги dialer),
xmux/sc*/xPaddingBytes (ручки без методологии), `randomized*`-фингерпринты в UI (лотерея).

### 2. Shadowsocks-2022 / SIP022
SIP022 без изменений ядра, но де-факто стандарт; прямые атаки на SS-2022 за 2025–2026 в открытых
источниках отсутствуют; SIP023 (EIH-цепочки `iPSK:uPSK`) — клиентской поддержки в
sing-box/Xray/mihomo на 2026-10 не подтверждено; Outline местами до сих пор на AEAD-2017.
**sora**: SS verbatim во все движки, валидации метода/ключа не было. **Коммиты**:
`c394fb6` + `6a97bc5` — `core/engine/ss.go`: классификация методов, таблица длин PSK, толерантный
base64, учёт SIP023-цепочек, проводка в `Outbound.Warnings()`; 5 тестов.
Спека: P0 — генерация PSK (`crypto/rand`→base64) в редакторе сервера, дефолт нового сервера
→ `2022-blake3-aes-256-gcm` + автогенерация, локализация warning-кодов честными текстами;
P1 — пресет методов в UI (только 3 полновесных; stream ciphers не предлагать), SIP023 — только
investigation (писать UI под несуществующую поддержку = мёртвая фича); P2 — WG-over-SS как
верификация цепочек F8 (не новый режим), one-click deploy в рамках «своего сервера».
**Фильтр вычеркнул**: тумблер UDP для SS (движки и так корректны), расширение SIP003-плагинов
(cloak — театр), «stealth-оценка одним числом» (маркетинговый слоп), авторотация PSK на клиенте
(невозможна без сервера).

### 3. Hysteria2 / TUIC
Апстрим 2025–2026: v2.8 BBR-профили + server-side port range; v2.9 Realms; v2.9.2 Gecko (experimental);
v2.10 ECH; v2.11 Chrome QUIC parrot по умолчанию; v2.13 parrot=Chrome 154, quic-go 0.63.
sing-box 1.14: `server_ports`, `hop_interval(_max)`, `bbr_profile`, `disable_chrome_parrot` (parrot ON
по умолчанию), `obfs.type: gecko`, `realm`. TUIC v4/v5 зрелый, без активной разработки.
**Найденные гэпы sora**: `upmbps/downmbps` из ссылок отбрасывались (Brutal CC никогда не включался —
главный перф-гэп), `mport` парсился но не пробрасывался (port hopping мёртв), TUIC
congestion_control/udp_relay_mode отбрасывались (sing-box хардкодил bbr), TUIC v4 (token) не
поддерживался, Xray hy2+obfs = жёсткая ошибка рендера.
**Коммит** `27a1d77`: UpMbps/DownMbps/HopPorts/HopInterval/CongestionControl/UDPRelayMode/Token —
plan→validate→parser→vault→рендереры sing-box/mihomo, 11 новых тестов, всё зелёное.
Спека: P0 — поднять floor sing-box до 1.14 (Chrome parrot бесплатно), Salamander из UI (путь уже
работает, нужен тоггл+генерация ключа), Xray: пробросить obfs/up/down/hopping либо честно
помечать «только sing-box/mihomo»; P1 — авто-тюнинг bandwidth (медиана замеров × 0.85, честные
замеры через `core/probe`), `bbr_profile`+`hop_interval_max` с гейтом 1.14+, порт в legacy;
P2 — ECH для hy2, Gecko/Realms — наблюдать.
**Фильтр вычеркнул**: Gecko как прод, «турбо-режимы», disableLossCompensation в UI, mimic
(отдельная установка, только Linux), авто-тюнинг «в лоб» (завышенные капы душат Brutal).

### 4. AmneziaWG deep-dive
AWG = WireGuard-Go с нетронутым криптоядром; junk Jc/Jmin/Jmax, паддинг S1–S4 (ловушка S1+56≠S2),
H1–H4 (2.0 — непересекающиеся диапазоны, случайное значение на пакет), I1–I5 с CPS-тегами
(мимикрия QUIC/DNS). 3.1 (ответ на RU-блокировки 06–07.2026): Header Protection (ChaCha20, требует
S1–S4≥12), ContentPaddingAddition. Поле 2026: в CN AWG часто детектится (там честнее
VLESS+REALITY); AS-блокировки пробиваются I1 под QUIC Initial. **sora**: модель полная для 1.x/2.0,
но параметров 3.1 нет, валидации диапазонов не было, в Dart-UI AmneziaWG отсутствует (только
импорт), sing-box без J1/J2/J3/Itime (гейт по capabilities), Xray — нет.
**Коммиты** `e850488` (sora), `993403c` (legacy): валидация Jc 0–128, 0≤Jmin≤Jmax<1280, капы S1–S4,
S1+56≠S2, H-диапазоны без пересечений, запрет AWG на не-WireGuard; табличные тесты.
Спека `reports/amneziawg-spec.md`: P0 — 3 пресета обфускации в UI (честная подпись «не гарантия»);
P1 — I1-пресеты мимикрии под AS-блокировки, параметры 3.1 с гейтом; P2 — честный авто-подбор junk
(лестница пресетов × замеры, без «AI»).
**Фильтр вычеркнул**: «stealth score» в процентах, авто-ротацию H (2.0 уже рандомизирует),
формулировки «невидим для DPI».

### 5. Обфускация WireGuard: трюки платных клиентов
Публичный каталог: Mullvad — UDP-over-TCP, WG-внутри-Shadowsocks, port agility, multihop, LWO
(скремблинг заголовка, но серверная сторона проприетарна — GotaTun), WG-внутри-QUIC/MASQUE,
PQ-PSK (Rosenpass-стиль), DAITA/Maybenot-шейпинг; IVPN — WG-внутри-VMess (честно про overhead);
Nord — obfuscated servers = OpenVPN+XOR (механика не раскрыта, копировать нечего);
NordWhisper — сам Nord заявляет «не для национальной цензуры».
**sora**: WG на 3 движках, цепочки F8 (`Via`), PSK; не хватает override порта пира, пресетов поверх
цепочек, **проверки что Xray реально применяет `dialerProxy` к UDP-сокету WG** (подозрение на молча
битый конфиг).
**Коммит** `4268da6` (+ в ветке через `2551170`): пакет `core/wgobfusc` — каталог 9 техник как данные
+ матрица поддержки движками; тесты зелёные. Спека `reports/WG-OBFUSCATION-RD.md`: P0 — port
agility (S), one-click «SS:443 → WG» поверх F8 (только если у провайдера есть SS-вход, S),
верификация Xray dialerProxy (S); P1 — PQ-PSK/ротация + задел Rosenpass-KEM (M), WG-over-VMess
как цепочка (S); P2 — QUIC/MASQUE ждать upstream, DAITA только research, UDP-over-TCP только при
поддержке провайдера.
**Фильтр вычеркнул**: копии NordWhisper/Proton Stealth/Lightway (спек нет, проверить нельзя),
OpenVPN-XOR «obfuscated» (театр), udp2raw (meltdown), клон LWO без серверной стороны (карго-культ).

## Темы 6–10: TLS, DPI, ECH, MASQUE, DNS

### 6. uTLS: гонка фингерпринтов
Upstream utls — HelloChrome_155 (2026-10-06), JA4 совпадает; Xray пинит старый utls с Chrome 133 —
детектится ТСПУ в РФ (issue #7131); CVE-2026-27017 (ECH GREASE-несогласованность); JA4/JA4+ —
стандарт, JA3 устарел; mihomo `random` уникален (взвешен по Cloudflare Radar), с v1.19.20 требует
SNI; доки sing-box 1.14 помечают uTLS «Not Recommended» (уязвимости фингерпринта) — для REALITY
uTLS обязателен, держим в уме.
**Гэпы sora**: дефолт `"chrome"` только для REALITY, обычные TLS-аутбаунды — голый Go-ClientHello;
fp из подписок без валидации; нет UI-выбора; пины движков старые → паррот ~20 мес. давности;
ECH не конфигурируется.
**Коммит** `7e0403d`: `core/engine/fingerprint.go` + тест. Спека: P0 — uTLS-дефолт для ВСЕХ
TLS-аутбаундов, `NormalizeFingerprint`, бамп `engines.lock`, фикс mihomo SNI; мониторинг свежести
(JA4 дефолта vs свежий Chrome — stale fingerprint = блокировка в RU).
Caveat: нужен живой доступ к релизам движков для сверки vendored utls (у исследователей не было
live-браузера — делегировать).

### 7. DPI-обходы: эволюция zapret
Вендорная zapret в sora — v72.13, актуальная; но используется **только tpws в `--socks`-режиме**:
проброшены SplitPos/Disorder/OOB/TLSRecord/HostCase/DomCase/MethodEOL; авто-подбора стратегий нет,
дефолт один на всех. tpws умеет больше: мульти-стратегии (`--new` + фильтры + `--hostlist-auto`),
`--split-any-protocol`, `--tamper-start/cutoff`, `--mss`. nfqws (v71–v72): multisplit/fake с неверным
SEQ, fooling md5sig/ts/badsum, QUIC-fake — но требует root и **никогда не запускается** (собирается,
ссылок в коде ноль). zapret2 (2025): Lua-скриптуемый desync. **QUIC: ноль обработки** — tpws видит
только TCP, UDP/QUIC идёт мимо (FOCI 2026: SNI-цензура QUIC в РФ).
**Коммиты**: `5b34de1` (sora) — `Apply` не держит мьютекс, пока tpws стартует (до 5с); tamper-опции
tpws в `BypassStrategy` (HostDot/HostTab/HostNoSpace/MethodSpace/UnixEOL, SplitAnyProtocol,
DisorderScope/OOBScope) — в sora контент внутри `be01e06` (чужой `git add -A`), в legacy чистый
`085cd2b`. Спека `reports/ZAPRET-EVOLUTION-SPEC.md`: P0 — курированный пул ~8 стратегий (корпус
blockcheck) + перебор через `core/tune` с per-network кэшем («подключил и работает»), проброс полей
в proto/RPC/UI, QUIC-probe + честный fallback на TCP; P1 — мульти-стратегии per-domain + 
`--hostlist-auto`, `--tamper-start/cutoff`; P2 — opt-in nfqws только для UDP/QUIC на Linux+root
(единственное, что tpws физически не может), opt-in краудсорсинговая карта стратегий по ASN.
**Фильтр вычеркнул**: миграция на zapret2 (Lua ради <10 стратегий — оверхед), dvtws (нет BSD),
свой blockcheck с нуля (брать корпус стратегий, не код), `--mss` по умолчанию (режет скорость),
nfqws вместо tpws (root ради TCP, который tpws делает в userspace), цифры эффективности без
честных замеров.

### 8. ECH
Статус: RFC 9849 (март 2026) + RFC 9848 (публикация через HTTPS/SVCB); клиенты — Firefox 119+,
Chromium 117+ (при DoH), Android 17, OkHttp 5.5+, OpenSSL 4.0, nginx 1.29.4. Серверно фактически
только Cloudflare. Блокировки: RU (11.2024) — дроп ClientHello с ECH в связке с SNI
`cloudflare-ech.com` (точечно); CN/IR — душат encrypted DNS, ECH не сбутстрапится. FOCI 2025:
вклад ECH в обход цензуры сейчас ограничен. Движки: sing-box `ech{enabled,config,config_path,
query_server_name (≥1.13)}`, build tag `with_ech` по умолчанию; mihomo `ech: true` (работает с
uTLS); Xray — клиент+сервер есть, JSON-поверхность на 26.3.27 не верифицирована.
**sora**: ECH не было нигде. **Коммит** `104fc0c` (через sibling-коммит): `engine.ECHConfig{Enabled,
Config, QueryServerName}` + рендер sing-box (`ech{enabled,config}`) и mihomo (`ech: true`),
4 теста; всё opt-in, по умолчанию ВЫКЛ (в RU автовключение ломало бы соединения — ТСПУ дропает).
Спека: P0 — зафиксировать зависимость: ECH без шифрованного DNS не сбутстрапится (тихий фолбэк;
валидация предупреждает, если ECH включён без DoH/DoT), pinned `ECHConfigList` для стран с
заблокированным DoH; P1 — Xray ECH после верификации JSON-ключа по исходникам, per-region guard
(RU), `query_server_name` при floor 1.13; P2 — только настройка сервера, без бейджей.
**Фильтр вычеркнул**: «ECH для DoH-соединений» (SNI выводится из IP — шифровать нечего),
UI-индикатор «ECH активен» (движки не сообщают, принял ли сервер — бейдж был бы ложью),
позиционирование ECH как антицензуры (противоречит FOCI 2025).

### 9. MASQUE / HTTP-3
RFC 9484/9485 (CONNECT-IP, CONNECT-UDP). sing-box 1.15.0-alpha.7 (08.2025): MASQUE client+server
(CONNECT-IP), HTTP/3 через `version: 3`. Xray/mihomo — без MASQUE.
**Коммит** `4dfa79d`: `sora/docs/research/masque-transport.md`. Спека: P0 — HTTP/3 для HTTP-outbound
(1–2 дня, точки встройки `core/engine/plan.go` ProtocolMASQUE, `catalog.go` гейт ≥1.15,
`singbox/render.go`); P1 — MASQUE CONNECT-IP outbound (3–5 дней + сервер); P2 — QUIC-маскировка
(драфт незрелый — отложить).

### 10. DNS: DoH3/DoQ, утечки
Резолверы: DoH3 — Cloudflare, Google; DoQ — NextDNS, AdGuard, Quad9-частично; **Cloudflare/Google
production-DoQ не дают** → DoQ «по умолчанию» = слоп. Движки: mihomo — DoQ (`quic://`), DoH3
(`?h3=true`, force без фолбэка); sing-box ≥1.8 — DoQ, DoH3 только адресная форма `h3://`;
Xray — DoQ, DoH без H3. Векторы утечек: Windows NRPT, Android Private DNS, captive portals, IPv6 DNS
при v4-туннеле, mDNS/LLMNR, ручной DNS, split-tunnel.
**Баг найден и исправлен**: `h3://` молча даунгрейдился в DoH2 в обоих рендерах, хотя `docs/usage.md`
обещал DoH3. Новый `engine.DNSH3`: mihomo → `?h3=true`, sing-box → `h3://host:443/dns-query`;
контент в коммитах `ffdf453`/`7009223` (чужой `git add -A`), ~15 строк + 4 теста.
Спека: P1 — DNS-профили с блокировкой по модели Mullvad (пресеты резолверов `base/extended/family/all`,
ноль кода в клиенте) + custom-DNS passthrough для NextDNS/ControlD/AdGuard (интегрировать, не
копировать); расширенный leak-check — Windows NRPT (hint, не «утечка»), Android Private DNS mode,
IPv6-резолверы при v4-туннеле (только hints, ID чеков стабильны); P2 — captive portal: детект →
явный «режим портала» с баннером и авто-возвратом, никакого тихого открытия трафика.
**Фильтр вычеркнул**: клиентский adblock-движок (плохой клон NextDNS/Pi-hole), «умный» выбор DoH3
с фолбэком (молчаливый даунгрейд = враньё), маркетинговые «на 33% быстрее».

## Темы 11–15: TUN, платформы, маршрутизация

### 11. TUN: gVisor vs системные стеки
Главное 2025: mihomo встраивает `mipstack` (свой userspace TCP/IP-стек, конкурент gVisor); в
закреплённом v1.19.32 проверено в бинарнике. sing-box 1.15: sing-tun на собственном стеке, опция
`stack` deprecated (удаление в 1.17), `multi_queue` (Linux, многоядерность) требует новый стек.
Community-бенчмарк (индикативно): system ~87 МБ/с, mixed ~84, gvisor ~76. gVisor = король
совместимости, аутсайдер throughput. **sora**: mihomo Windows→`mips` (измерено в CI), иначе `mixed`,
MTU был 1500 (отклонение от upstream-дефолта 9000); sing-box везде `mixed`, MTU 9000.
**Коммиты**: legacy `177cc8a` (Windows mips + MTU 9000, чистый); sora MTU 1500→9000 — контент внутри
`ffdf453` (чужой коммит). Спека: P0 — расширить Windows CI-харнес throughput-замеров на Linux
(дефолты Linux/macOS сейчас не измерены, а значит нечестны) + статичная per-OS таблица дефолтов в
коде; P1 — проверить lx-форк на новый стек sing-box 1.15+, убрать `stack` из рендера, `multi_queue`
на Linux; P2 — прогнать Xray gvisor-TUN vs mihomo-мост через тот же харнес.
**Фильтр вычеркнул**: runtime авто-выбор стека бенчмарком при старте (недетерминизм),
ручной тюнинг GSO (в 1.12+ автодетект — cargo-cult), цифры из VPN-блогов как истина.

### 12. Windows: WFP vs WinTun
WFP и WinTun — ортогональные слои: WinTun двигает пакеты, WFP решает, каким жить. Каталог:
kill switch через WFP без драйвера — стандарт (WireGuard for Windows: динамическая сессия, веса,
TUN-пермит **по LUID адаптера**; Tailscale — тот же `tailscale/wf`, что у sora; IVPN — persistent
+ always-on с загрузки, переживают краш; Nord «system-level» = те же persistent-фильтры).
Split: уровень A — user-space (sora сейчас; честные пределы: dnscache не атрибутировать, дочерние
процессы, race), уровень B — WFP callout-драйвер (Mullvad `win-split-tunnel`). **sora**: зрелый WFP
kill switch (веса 0/10/20/30/40/50, саблейер, AppID+SID, блок :53, DHCP/ND/loopback) + редкий
ingress-guard на `ALE_AUTH_RECV_ACCEPT`; TUN через движки; per-app через process-правила.
Не хватает: LUID-матчинг (везде type-53), persistent always-on, inverse split, `wintun.dll` в
`packaging/` нет (молчаливая зависимость system-стека).
**Коммиты**: legacy `d58a454` (порты SORA-M10/SORA-L20, GOOS=windows build+vet ✅); sora `104fc0c`
(тест инварианта иерархии весов WFP).
Спека `reports/NET-RD-12-WINDOWS-WFP-WINTUN.md`: P1 — TUN-пермит по LUID `sora0` (как WireGuard),
опциональный persistent always-on (техника IVPN, opt-in + recovery-UX, без драйвера), inverse
split-tunnel («только эти приложения в VPN»), зафиксировать `wintun.dll`; P2 — callout-драйвер
Mullvad-grade с честной ценой (EV-сертификат + attestation-подпись каждого релиза, риск BSOD;
дефолт остаётся user-space).
**Фильтр вычеркнул**: Surfshark «Bypasser: сайты» (уже есть domain/IP-правила), Lifeguard-вотчеры
(костыль), маркетинговые цифры скорости.

### 13. Linux: nftables, policy routing
Ядро 6.16 — OpenVPN DCO в mainline; nftables 1.1.2→1.1.7. Mullvad Linux split = nftables route-hook
(ct mark + meta mark) + `mullvad-exclude`; `socket cgroupv2` match для per-app.
**Найдено и исправлено**: Arm был delete+add двумя вызовами (fail-open окно). **Коммит** `2953fbe`:
атомарный Arm в `sora/core/guard/nftables.go`.
Спека: P1 — make-before-break в tunroute, унификация UID, mark-архитектура в стиле Mullvad,
per-app через cgroupv2; P2 — IPv6-паритет while armed (сейчас NDP/DHCPv6 ломаются).
Открытый вопрос: SO_MARK требует CAP_NET_ADMIN — метку ставит core через nftables route-hook по skuid.

### 14. FakeIP / перехват DNS
**Баги найдены и исправлены**: mihomo `fake-ip-filter` был захардкожен (`*.lan,*.local`) — план не
мог задать; sing-box аналога не было вообще (правило → fakeip безусловное: `printer.local`,
`router.lan`, NTP получали фейки — ломались LAN/печать/время); рассинхрон `inet4_range`
(sing-box `/15` vs `PrepareTun`/mihomo `/16`); `fake-ip-ttl` не рендерился; `skip-cert-verify`
отсутствовал (DoT/DoH за корпоративным MITM ронял резолву).
**Коммиты** `7a954db` (контракт: `DNS.FakeIPFilter` + `DefaultFakeIPFilter` best-practice —
`*.home.arpa`, NTP, `+.msftconnecttest.com`, `+.msftncsi.com`; `FakeIPTTL`; `DNSServer.SkipVerify`),
`e1beb89` (sing-box exclusion-правила `domain_suffix` перед catch-all, `tls.insecure`, `inet4_range`
→ `/16`); mihomo-рендер — контент мой, ханки в чужих `ffdf453`/`7009223`.
Спека: P1 — IPv6 fake-IP (`inet6_range`; умный пул — кандидат `2001:db8:534x::/126`, не `fc00::/18`
— конфликт с kill-switch), умный выбор пула с автоподбором при коллизии вместо жёсткой ошибки;
P2 — метрики коллизий (хук на цикл пула mihomo + gauge в diagnostics).
**Фильтр вычеркнул**: `fake-ip-filter-mode` (нишевый knob), «перехват DoH на 443» (MITM ломает
доверие; блочить 853 — ломать легитимные приложения), поднятие TTL по умолчанию (1с у mihomo —
осознанный дизайн), слепой `fc00::/18`.

### 15. Маршрутизация: geoip/geosite
Источники 2025–2026: v2fly/geoip (ежемесячно, из DB-IP Lite), domain-list-community (geosite),
Loyalsoldier/geoip (еженедельно, 7 форматов), SagerNet/sing-geoip+sing-geosite (.srs, авто-апдейт),
MetaCubeX/meta-rules-dat (дефолт mihomo в sora). **MaxMind GeoLite2 — слоп для встраивания**
(аккаунт+ключ+EULA, удаление старых баз за 30 дней, ключи протухают каждые 90 дней).
**sora**: `engine.Rule` — 12 типов, ASN и time отсутствуют; пресеты global/ru/ir/cn + BlockAds;
shipped .dat обновляются только со сменой Xray; **SHA-256 покрывает бинари движков, сами .dat
отдельно не верифицируются**; mihomo тянет dat с MetaCubeX **без верификации**.
**Баг найден и исправлен**: mihomo заявлял `FeatureRuleSets`, но `RuleRuleSet` рендерился как
`RULE-SET,<url>` без секции rule-providers → невалидный конфиг.
**Коммит** `ffdf453`: `core/engine/mihomo/rules.go` — rule-providers (type http, behavior classical,
format по расширению, interval 86400, дедуп, не-https = ошибка рендера); 4 теста.
Спека `reports/routing-netrd-spec.md`: P0 — подписанное авто-обновление geo-баз (minisign-манифест,
инфра есть в `core/ext`; staged rollout, rollback, CI-сверка тегов); P1 — ASN-правила
(`engine.RuleASN`; sing-box `asn`, mihomo `ASN`, Xray — честный отказ), импорт rule-set'ов
(.srs + clash rule-providers с валидацией и provenance в UI), конструктор правил (порядок, детект
затенённых, dry-run); P2 — CI-сверка тегов, ASN-датасорс с атрибуцией.
**Фильтр вычеркнул**: time-правила (ценность ~0), multihop entry/exit в UI (дублирует F8), MaxMind
напрямую, «fastest server» по пингу (уже честные замеры), WiFi SSID-матчеры (перекрыто F5).

## Темы 16–20: стелс, детект, Android, аудиты движков

### 16. «Стелс»-режимы платных клиентов
Каталог (только публичное): Mullvad — самый открытый (bridge WG-over-SS; DAITA на открытом Maybenot,
рецензирована академически; ML-KEM по умолчанию, `mullvad-upgrade-tunnel` открыт; GPL, аудиты);
Nord — самый закрытый (obfuscated = OpenVPN+XOR, механика не раскрыта; NordWhisper — «для локальных
блокировок, не национальной цензуры»; help center признаёт полную блокировку в CN); Proton Stealth —
WG поверх обфусцированного TLS на 443 (форк wireguard-go открыт, параметры handshake скрыты);
Lightway — антипример (open source, но ни один клиент не взял, в CN не работает; скорость ≠
незаметность); AmneziaVPN — полностью открыт (признанная слабость v1: статичные заголовки DPI
выучивает — обфускация обязана рандомизироваться).
**sora**: есть zapret/tpws, TLS-фрагментация, uTLS, REALITY, XHTTP, AmneziaWG (все параметры 2.0),
SS obfs, цепочки `Via`, VLESS PQ, `AntiCensorship`. Не хватает: WG-over-SS одной кнопкой (руками
через `Via` возможно, пресета нет), WG-over-TLS (аналог Proton Stealth), cover-трафика/шейпинга,
PQ-handshake для WG, «уровня стелса» в UI, оценки незаметности конфига.
**Коммиты**: `bb79d39` — `core/engine/stealth/`: `Grade()` оценивает план 0–100 по публичным
DPI-фактам (plain WG, статичные H1–H4, нет uTLS/фрагмента, голый SS/Hy2/TUIC; чейны — по внешнему
плечу); 10 тестов. `88d824b` — `docs/stealth.md` (каталог вендоров + gap-анализ).
Спека `reports/STEALTH-RD.md`: P0 — `stealth.Bridge(inner,outer)` (WG-через-SS одной функцией),
матрица zapret-стратегий (docs), Amnezia-параметры из подписки (обязаны совпадать на обоих концах);
P1 — WG-over-TLS сайдкар (нужен серверный терминатор), `stealth_level` 0–3 в `AntiCensorship`,
PQ-handshake WG (X25519+ML-KEM), stealth-самопроверка в diagnostics; P2 — Maybenot-шейпинг
(нужна поддержка входного сервера, как DAITA), адаптивные камуфляж-профили, бейдж стелса в UI.
**Не делаем**: копировать NordWhisper/детали Proton-handshake; свой VPN-протокол; обещать
«undetectable».

### 17. Детект блокировок
Каталог: OONI Web Connectivity v0.4/v0.5 — золотой стандарт (шаги DNS→TCP→TLS→HTTP, сравнение с
контрольной точкой; единичный замер = возможный false positive, сигнал только в агрегате по ASN во
времени); OONI DNSCheck; Iris (академия, ML-классификация DNS-манипуляций); TraceVis/wikicensorship
(back-TTL, TTL-sweep); Psiphon — только популяционные агрегаты, локального детекта нет; Amnezia
«checker» — публичного репозитория не найдено (vaporware не спекаем); captive portal — детерминированные
OS-механики (Android `generate_204`, Apple, Windows NCSI, Firefox, RFC 8910).
Дифференциация: DNS-спуф (несогласованность/немаршрутизируемые IP/NXDOMAIN-подделка), SNI-reset
(RST после ClientHello при живом TCP), IP-drop (тишина SYN на всех портах).
**Гэп sora**: `core/probe` схлопывал всё в UNAVAILABLE/DEADLINE_EXCEEDED — отличить «сервер мёртв»
от «цензура режет» было нельзя; CheckDnsLeaks имел канарейку, но ответы не проверял на честность.
**Коммиты**: `56ab7e4` — `core/probe/classify.go`: классификация dial-ошибок по фазе
(dns/tcp/tls) и сигнатуре (refused/timeout/reset/unreachable/nxdomain/handshake/certificate) +
`CensorshipLike()`; ноль нового трафика. `9c727cd` — `core/diagnostics/dnsspoof.go`: детектор
DNS-спуфинга (канарейка через системные и туннельный резолверы, 2 раунда, правило большинства;
вердикты ok/inconsistent/bogus/nxdomain/unresolved); тесты.
Спека `reports/CENSORSHIP-METER-SPEC.md` (всё локально, без телеметрии): P0 — фаза+сигнатура в
`ProbeResult` (done), DNS-спуфинг как 4-я проверка CheckDnsLeaks (done, контракт UI цел), captive
portal как отдельное состояние (дешёвый plain-HTTP тест — убивает ложные «цензура!»), чистая функция
«вердикт → рекомендация транспорта» (формулировки-рекомендации, не гарантии); P1 — дифференциальный
SNI-зонд (домены задаёт пользователь, без захардкоженного блоклиста), UDP/443 reachability-зонд,
локальная история вердиктов по сети (сжатое во времени правило OONI); P2 — честный детект
троттлинга (только с бейзлайном; пока методологии нет — заявлений в UI не будет), ECH-зонд.
**Фильтр вычеркнул**: ICMP как сигнал цензуры (шум/привилегии), Psiphon-телеметрию (наружу нельзя),
захардкоженные списки заблокированных доменов (протухают), карту миддлбоксов (данные ради данных),
«троттлинг» из одного замера скорости (маркетинговые цифры).

### 18. Android VpnService
**Коммит** `d8159de`: `sora/docs/android-vpnservice.md`. Находки: Android 14+ требует FGS
`specialUse`; kill switch = системный always-on + lockdown (свой на iptables невозможен);
per-app через addAllowed/DisallowedApplication; `protect()` сокетов; strict Private DNS
переопределяет DNS VPN (детектить); 16 KB page size для Play; gomobile реален, но движки сейчас
внешние процессы — нужен in-process `engine.Driver` (прецедент libbox); нужен
`systemdns_android.go` (resolv.conf на Android — мусор); zapret без root невозможен.
Открытые вопросы владельцу: Kotlin vs Flutter для Android-UI; embedded-драйвер sing-box как первая
веха.

### 19. sing-box 1.11/1.12+ аудит
Новое: rule actions (sniff/hijack-dns/route/reject, TCP RST/ICMP), WG как endpoint (удалён в 1.13),
multi-network dialing, `network_type`/`is_expensive`/`is_constrained`, Hysteria2 port hopping,
rule-set merge; 1.12: рефактор DNS, `domain_resolver`, TLS fragment в route actions и outbound,
certificate options, **Tailscale endpoint+DNS**, AnyTLS, stdlib ECH (без build tag), NTP sniffer,
TUN `loopback_address`, перф TUN на Apple. sora MinVersion 1.12.0.
**Гэпы sora** (таблица в отчёте): per-rule `tls_fragment` (только глобальный свитч — дороже по CPU и
заметнее для DPI), multi-network dialing, `network_type` rules, Tailscale endpoint, certificate
options; ECH и Hy2-hopping — in-flight у других агентов.
**Коммит** (контент в `6a97bc5`, атрибуция смешанная): TUN `route_address` из `Tun.RouteAddressSets`
(паритет с mihomo; при пустом поле ключ опускается); тест `TestTunRendersRouteAddressSets`.
Спека: P0 — per-rule TLS fragment (чейнджлог 1.12 рекомендует точечный fragment «только для
известных заблокированных SNI», а не на все соединения); P1 — auto_redirect на Linux («always
recommended», но конфликт с `tunroute` — нужно архитектурное решение), certificate options
(правильный путь вместо `insecure` для корпоративных MITM), multi-network dialing (честно: на
десктопе выигрыш в основном мобильный), `network_type` rules (стык с F5); P2 — 1.14 (`evaluate`/
`race` DNS, MASQUE, Snell/OpenVPN endpoints, bridge outbound, netns).
**Фильтр вычеркнул**: `tls_record_fragment` отдельно (доки: «for debugging only»), крутилки
(`udp_timeout`/`cache_capacity`), `override_address/override_port` (шейпинг покрывает zapret),
server-side DERP/SSM, StosVPN loopback.

### 20. Xray/mihomo latest
Xray (pin 26.3.27, апстрим 26.9.30/26.10.x): клиентский ECH, VLESS Encryption с блоками
(`0rtt` резампшн), flow `xtls-rprx-vision-udp443`, XHTTP как единый транспорт (h2 **удалён** в v26 —
sora уже реджектит), REALITY ML-DSA-65 + X25519MLKEM768, uTLS-догонялки (issue #7131: chrome=133
давится ТСПУ, апстрим → HelloChrome_155), splice (Linux, Vision, автоматический).
mihomo (min 1.19.0, валидировано 1.19.32): AnyTLS, `ech-opts` + `reality-opts.support-x25519mlkem768`,
shadow-tls-opts v3, restls/jls/tlsmirror-opts, VLESS `encryption` (PQ) + `packet-encoding:
packetaddr`, per-proxy `smux`, LB `consistent-hashing`/`sticky-sessions`, `listeners`, TUN `mips`,
`prefer-h3` для DoH, DNS-кэш `arc`.
**Важно**: mihomo официально отказывается от совместимости reality-клиента с xray v26.7.11+
(«deliberately incompatible») — sora на 26.3.27 пока в безопасности.
**Коммиты**: sora `1da01e9`, legacy `2a100f3` — mihomo: рендер AnyTLS outbounds (был только
sing-box); `type: anytls` + password, TLS принудительно, SNI/uTLS из плана.
Спека: P0 — guard Xray ≥26.7.11 для reality-трасс mihomo→xray (catalog MaxVersion/warning + тест),
мониторинг свежести uTLS (JA4 дефолта vs свежий Chrome), ECH для Xray (`echServerName`/
`echConfigList` — сначала подтвердить кодировку на 26.3.27, иначе нерабочая фича = слоп);
P1 — mihomo `smux` (реальный выигрыш на потерях, один флаг), REALITY PQ-флаги,
`packet-encoding: packetaddr`; P2 — LB-стратегии, DNS `arc` (только после измерения),
ShadowTLS v3 (зрелая техника, ниша), bump Xray min-версии после P0.
**Фильтр вычеркнул**: Smart Groups (сторонний форк), zeptun (только авторские бенчмарки),
tlsmirror-opts (экспериментальный VMess-only), RESTLS/JLS (без экосистемы), `fingerprint: random`
по умолчанию (недетерминизм).

---

## Ранжированный бэклог

Формат: [тема] задача — эффект / сложность. Внутри P0 — по убыванию (эффект×доступность)/сложность.

### P0 — делать первым (недели)
1. [6] uTLS-дефолт для всех TLS-аутбаундов + `NormalizeFingerprint` + бамп `engines.lock` + фикс
   mihomo SNI — высокий / средняя. Stale fingerprint = реальная блокировка в RU (issue #7131).
2. [20] Мониторинг свежести uTLS (JA4 дефолта vs свежий Chrome) — высокий / малая. Дешёвая страховка
   от повторения #7131.
3. [7] Курированный пул ~8 zapret-стратегий + перебор через `core/tune` с per-network кэшем —
   высокий / средняя. «Подключил и работает» — ключевой UX антицензуры.
4. [17] Captive portal как отдельное состояние + «вердикт → рекомендация транспорта» (формулировки-
   рекомендации, не гарантии) — высокий / малая. Убивает ложные «цензура!».
5. [2] Генерация PSK + дефолт `2022-blake3-aes-256-gcm` для новых SS-серверов — средний / малая.
   Главный usability-гэп лучшего протокола.
6. [4] Пресеты обфускации AmneziaWG в UI (3, честная подпись) + параметры 3.1 с гейтом capabilities —
   высокий для RU / малая–средняя.
7. [1] XHTTP headers → xhttpSettings (готовый дифф — применить, когда дерево чисто) + REALITY-hygiene
   варнинги + пин минимальной версии Xray — средний / малая.
8. [3] Floor sing-box → 1.14 (Chrome parrot бесплатно) + `server_ports`/`bbr_profile` гейт —
   средний / малая.
9. [19] Per-rule TLS fragment (вместо глобального) — средний / средняя. Та же эвазия, меньше CPU и
   заметности; рекомендовано чейнджлогом 1.12.
10. [15] Подписанное авто-обновление geo-баз (minisign, staged rollout, rollback) — средний / средняя.
    Свежесть без MITM; сейчас dat обновляются только со сменой Xray и не верифицируются.
11. [20] Guard Xray ≥26.7.11 для reality mihomo→xray — средний / малая. Реальный риск поломки.
12. [5] Port agility WG + one-click «SS:443 → WG» поверх F8 + верификация Xray dialerProxy —
    средний / малая.
13. [12] WFP: TUN-пермит по LUID + зафиксировать `wintun.dll` в поставке — средний / малая.
14. [8] ECH plumbing opt-in (уже в ветке) + правило «ECH без DoH/DoT → warning» — средний-низкий /
    малая. Приватность SNI там, где есть (фактически Cloudflare).
15. [9] HTTP/3 для HTTP-outbound — средний / малая (1–2 дня).
16. [10] DNS-профили блокировки по модели Mullvad + extended leak-check hints (NRPT, Android Private
    DNS, IPv6) — средний / средняя.
17. [16] `stealth.Bridge(inner,outer)` + матрица zapret-стратегий в docs + Amnezia-параметры из
    подписки — средний / малая.
18. [11] P0-измерительная база TUN (расширить CI-харнес на Linux) + статичная per-OS таблица дефолтов —
    средний / средняя. Все будущие решения по стекам — на цифрах, не на теории.

### P1 — следующим (месяцы)
- [9] MASQUE CONNECT-IP outbound (+ сервер), [16] WG-over-TLS сайдкар, [3] авто-тюнинг bandwidth
  (медиана × 0.85), [20] mihomo `smux`, [20] REALITY PQ-флаги, [15] ASN-правила + импорт rule-set'ов +
  конструктор правил, [13] mark-архитектура Mullvad-style + per-app cgroupv2, [12] inverse
  split-tunnel + опциональный persistent always-on, [19] auto_redirect на Linux (архитектурное
  решение vs tunroute) + certificate options, [14] IPv6 fake-IP + умный выбор пула, [7] мульти-
  стратегии tpws per-domain + `--hostlist-auto`, [5] PQ-PSK (Rosenpass-стиль), [17] дифференциальный
  SNI-зонд + UDP/443-зонд + локальная история вердиктов, [4] I1-пресеты мимикрии, [1] ECH-клиент
  Xray (после верификации JSON), [11] sing-box 1.15+ (убрать `stack`, `multi_queue` на Linux),
  [18] in-process `engine.Driver` (прецедент libbox) — веха Android.

### P2 — кварталы / наблюдать
- [16] Maybenot-шейпинг (нужен серверный cover-трафик), [13] IPv6-паритет while armed, [20] LB-
  стратегии + ShadowTLS v3 + DNS `arc` (после измерения), [7] opt-in nfqws для UDP/QUIC + opt-in
  краудсорсинговая карта стратегий по ASN, [17] честный детект троттлинга (только с бейзлайном),
  ECH-зонд, [3] Gecko/Realms — наблюдать, [5] QUIC/MASQUE — ждать upstream, DAITA — research,
  [12] callout-драйвер (честная цена: EV + attestation, риск BSOD), [1] downloadSettings (ниша CDN).

### Явные «не делаем» (фильтр слопа, зафиксировано)
Свой VPN-протокол; обещания «undetectable»; копии NordWhisper/Proton-handshake/Lightway-обфускации
(спек нет); OpenVPN-XOR «obfuscated»; Finalmask; «stealth score» одним числом; «умный» DoH3 с
молчаливым даунгрейдом; клиентский adblock-движок; ECH как антицензура; ICMP как сигнал цензуры;
телеметрия наружу; захардкоженные блоклисты; авто-тюнинг «в лоб»; runtime-бенчмарк выбора TUN-стека;
цифры эффективности без честных замеров.

---

## §21. Технические долги и вопросы владельцу

1. **Сломанная сборка**: `core/engine/validate.go` ссылается на несуществующие
   `validateHysteria2Tuning`/`validateTUICTuning` (остаток коммита `7e0403d`), `core/control`
   гонялся за `obfs.go`, `core/censor` — `undefined: obfsv1`. На момент завершения части агентов
   `go build ./core/...` был красным не по их вине. Требуется: добить `core/tune` или откатить
   ссылки, затем полный `go build ./...` + `go vet`.
2. **Общий индекс git**: агенты регулярно коммитили чужие ханки целыми файлами
   (`ffdf453`, `7009223`, `104fc0c`, `1da01e9`, `2551170`, `6a97bc5`, `be01e06`) — атрибуция в
   истории смешанная, но контент проверен. Рекомендация: пер-агентные ветки или строгая
   патч-дисциплина (`git add` только своих файлов + проверка `git diff --cached --name-only`).
   Коммит `104fc0c` случайно включил 6 staged-файлов чужого агента — решение: оставить или
   скоординировать тихую переписку (git notes уже добавлены).
3. **Env-падение** `TestTunAndFakeIPAvoidLANAndEachOther` в песочнице (NIC `198.19.0.2/30`) —
   предсуществующее, не код; заодно доказывает, что гард коллизий работает.
4. **sora-legacy**: часть фиксов портирована (AnyTLS `2a100f3`, Amnezia-валидация `993403c`,
   WFP-порты `d58a454`, zapret-tamper `085cd2b`, mips/MTU `177cc8a`); зеркальные гэпы остались:
   XHTTP headers, RULE-SET rule-providers, FakeIP-контракт — рекомендованы отдельной зоной.
5. **Открытые вопросы**: Kotlin vs Flutter для Android-UI; embedded-драйвер sing-box как первая
   веха Android; кодировка `echConfigList` в Xray 26.3.27 (нужна для P0 спеки темы 20); поднимать
   ли Xray выше 26.7.x при reality-несовместимости с mihomo; живой доступ к релизам движков для
   сверки vendored utls (у суб-исследователей не было live-браузера).

## Артефакты
Спеки: `reports/amneziawg-spec.md`, `reports/STEALTH-RD.md`, `reports/CENSORSHIP-METER-SPEC.md`,
`reports/ZAPRET-EVOLUTION-SPEC.md`, `reports/routing-netrd-spec.md`, `reports/WG-OBFUSCATION-RD.md`,
`docs/stealth.md`, `docs/android-vpnservice.md`, `docs/research/masque-transport.md`,
`reports/NET-RD-12-WINDOWS-WFP-WINTUN.md` (все — `~/workspace/bug-hunt/`).
Ключевые коммиты `[net-rd]` (ветка `bugfix/audit-2026-10-19`, без пуша): `d8159de`, `4dfa79d`,
`7e0403d`, `2953fbe`, `bb79d39`, `88d824b`, `56ab7e4`, `9c727cd`, `c394fb6`, `e850488`, `993403c`,
`104fc0c`, `ffdf453`, `7009223`, `1da01e9`, `2a100f3`, `d58a454`, `177cc8a`, `7a954db`, `e1beb89`,
`27a1d77`, `5b34de1`, `085cd2b`, `4268da6`.
