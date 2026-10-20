# TEAM-C: второй проход веб-разведки — движки и конкуренты (2026)

Дата: 2026-10-20. Лид-проход без субагентов (depth 2/2 — делегирование недоступно, все 10 тем отработаны напрямую по первоисточникам: официальный changelog sing-box, GitHub-релизы Xray-core, wiki.metacubex.one, блоги Mullvad/Proton/IVPN/Amnezia, pkg.go.dev, DeepWiki по исходникам).
Первый проход: `~/workspace/bug-hunt/reports/WEB-RESEARCH.md`. Здесь — только новое/уточнённое, без повторов.

Фильтр владельца применён: в отчёте только то, что реально работает и имеет измеримый эффект для sora (десктоп Flutter + Go core, 3 движка, рынок РФ/СНГ). Слоп — в разделе «Отсеяно» с причиной.

Ключевая поправка к первому проходу: **Xray-core уже не 25.x, а 26.x (текущий 26.9.30), и в 26.x есть два breaking change, бьющих по sora напрямую.** Это самый важный результат прохода.

---

## 1. sing-box 1.12 / 1.13 / 1.14 / 1.15-alpha — разбор changelog

Источник: https://sing-box.sagernet.org/changelog/ (прочитан целиком, секции 1.12.0 / 1.13.0 / 1.14.0 / 1.15.0-alpha).

### 1.12.0 — релевантное для VPN-клиента
- **DNS-серверы отрефакторены; старые форматы удалены в 1.14.0.** Legacy `outbound` DNS-правила deprecated → замена `domain_resolver`. sora рендерит `domain_resolver` (2 вхождения в `core/engine/singbox/render.go`) — сверить, что нигде не остался старый формат, иначе конфиг умрёт на 1.14.
- **AnyTLS-протокол** (inbound+outbound): «mitigate TLS proxy traffic characteristics», собственная схема мультиплексирования. sora уже рендерит (`render.go:248`) — ок.
- **TLS fragment / record fragment** в route-опциях и TLS-опциях — нативный DPI-десинх TLS-хендшейка без zapret. Дешёвый выигрыш: прокинуть в UI тюнинга.
- **ECH на stdlib**, тег `with_ech` больше не нужен.
- **Wildcard SNI для ShadowTLS inbound.**
- **Certificate options**: выбор CA-стора (system / Mozilla; в 1.13 добавился Chrome; оба фильтруют китайские CA).
- Tailscale endpoint, NTP sniffer, DERP/Resolved/SSM-API сервисы (серверная экзотика — не для клиента).
- Apple TUN: gVisor 1500 MTU 2.57→4.68 Gbps DL на M4 (замер tun_bench из changelog).

### 1.13.0 — релевантное
- **NaiveProxy outbound**: QUIC, ECH, UDP-over-TCP, настраиваемый QUIC congestion control (BBR/BBRv2). Подтверждает ставку первого прохода (#11). Цена: `libcronet.dll` рядом с exe на Windows; self-signed серты больше не поддерживаются (ломают смысл naive).
- **Официальная позиция sing-box по uTLS**: «uTLS is not recommended for censorship circumvention due to fundamental architectural limitations; use NaiveProxy instead». Это приговор от автора движка — усиливает вывод первого прохода (TIER S #2): держать uTLS свежим, но стратегически уходить на naive/REALITY.
- **uTLS v1.8.1/1.8.2**: фикс критического детекта Chrome-фингерпринтов (refraction-networking/utls#375 — missing padding extension для Chrome 120+). sora пинит uTLS v1.8.2 в `core/go.mod` — уже содержит фикс; в 1.14 движок ушёл на v1.8.7, проверить, нужен ли bump.
- **Wi-Fi state на Linux/Windows** (`wifi_ssid`/`wifi_bssid` в route-правилах) — готовый фундамент под доверенные сети (F5): sing-box умеет матчить SSID нативно.
- **kTLS**: `kernel_tx`/`kernel_rx` — kernel TLS offload через splice(2) на Linux 5.1+ (пока только inbound; для клиента — задел).
- **auto_redirect**: pre-match `bypass`-action, reject MPTCP по умолчанию (фикс совместимости), fallback iproute2-правило.
- **ICMP echo proxy** (ping через TUN/WireGuard/Tailscale) — полезно для диагностики в клиенте (пинг серверов без костылей).
- `local` DNS перешёл на platform-native (systemd-resolved DBus, getaddrinfo) — важно для DNS-менеджера sora: поведение `local` теперь системно-зависимое.
- TCP keep-alive дефолт 10→5 мин.

### 1.14.0 — крупное
- **OpenVPN client+server, OpenConnect client** (AnyConnect/GlobalProtect/Fortinet/F5/Pulse/Juniper, SSO). Для sora — опциональный корпоративный интероп; низкий приоритет, но дешёвый (движок умеет).
- **Snell** (реимплементация закрытого протокола Surge на Go). Ниша — пропустить.
- **L3 forwarding + `bridge` outbound**, **network namespaces** (`unshare` без root) — для продвинутого split-tunnel; задел, не срочно.
- **sing-box API service** (gRPC: статус, логи, группы, Clash-режим, коннекты, тесты качества сети, STUN) + **Dashboard** + **`sing-box api` CLI**. Референс для sora: их API покрывает network quality tests и STUN из коробки — сверить с нашим gRPC.
- **Hysteria2**: Chrome QUIC parroting **по умолчанию**, `bbr_profile`, рандомизация `hop_interval`, новый obfs `gecko` + `min/max_packet_size`. Прямой ответ на троттлинг QUIC — включить дефолты при рендере hy2.
- **DNS**: `evaluate`-action, Response Match Fields, **параллельная оценка ответов** (`race`/`speculative`), optimistic cache, mDNS-сервер. Для DNS-менеджера sora — готовые примитивы.
- **Rule-set семантика исправлена** (merged matching → «other field»; поведение в спорных случаях было undefined, breaking не считают, но конфиги с хитрой логикой могут поехать). Проверить генерацию rule-set в sora.
- **TLS spoof**, Windows/Apple TLS engines, Tailscale SSH/Taildrop, JSON Schema, cloudflared inbound.
- **sing-box for Desktop** (Windows/Linux) — новый конкурент в том же сегменте, что sora. Отслеживать.
- GUI-клиенты: JSON-редактор с completion, power report, шифрованный экспорт.

### 1.15.0-alpha — в разработке
- **Новый TUN TCP/IP-стек** («substantial improvements» perf/energy/memory). Опция `stack` deprecated, **удаление в 1.17.0**. Подтверждает первый проход (#6): убрать `"stack": "mixed"` из рендера сейчас, иначе конфиг сломается на 1.17.
- **MASQUE client+server** (CONNECT-IP, HTTP/1.1+2+3, address assignment). Первый мэйнстрим-движок с MASQUE-клиентом.
- **HTTP-прокси переписан**: HTTP/2, HTTP/3, UDP через CONNECT-UDP; outbound по дефолту HTTP/2 с fallback.
- **Полный certificate pinning** (`certificate_sha256`).
- **Tailcat** (Tailscale data plane без control plane, DERP-bootstrap) — интересный примитив для F9 device sync без центрального сервера; ниша, но задел.
- `dns_server_address`/`dns_search_domain` rule items.
- quic-go 0.55/0.61, фикс утечки памяти hysteria2.

**Вердикт по теме:** sing-box — самый быстрорастущий из трёх движков. Для sora: (1) убрать `stack` из рендера до 1.17; (2) мигрировать DNS-генерацию на новый формат полностью (старый мёртв в 1.14); (3) прокинуть TLS-fragment, hy2-дефолты (parrot/bbr/gecko), naive QUIC/ECH; (4) wifi_ssid-правила в F5; (5) MASQUE — в roadmap, брать из 1.15 stable.

---

## 2. Xray-core 26.x — свежие релизы, breaking changes

Текущий: **26.9.30** (core.go; DeepWiki, окт 2026). Ветка 26.x идёт с начала 2026. sora пинит минимум **26.3.27** — ниже критических breaking-версий. Источники: релизы https://github.com/XTLS/Xray-core/releases/tag/v26.7.28, https://github.com/XTLS/Xray-core/releases/tag/v26.2.4, FreshPorts `security/xray-core`, разбор 3x-ui, заявление RPRX о security-направлении.

### Breaking change №1 (критично для sora): запрет нешифрованных outbound к публичным IP
- **С v26.7.11 Xray отклоняет нешифрованные VLESS/Trojan outbound на публичные IP** (подтверждено гейтом `shouldSkipLegacyUnencryptedOutboundRejection` в 3x-ui: `xray_setting.go`; старые ядра продолжают работать со старыми конфигами).
- Направление RPRX (2026): `allowInsecure` поэтапно удаляется начиная с **v26.2.6**, замена — `pinnedPeerCertSha256` / `verifyPeerCertByName`; в будущем Xray будет доверять только встроенному списку корневых CA; все крупные панели уже убрали публичный plaintext-HTTP.
- **Действие для sora:** MinVersion 26.3.27 < 26.7.11 — движок в руках пользователя может быть любым. Валидатор обязан варнить/блочить нешифрованный VLESS/Trojan на публичный IP при Xray ≥26.7.11 (иначе молча не заведётся). Это честность продукта, не косметика.

### Breaking change №2: удалён «legacy reverse»
- В 26.7.28 (по FreshPorts): фича `legacy reverse` удалена, миграция на **«VLESS Reverse Proxy»**. Если sora где-то рендерит reverse — переписать.

### XHTTP: переименованы поля
- 3x-ui автоматически мигрирует legacy `sessionPlacement`/`sessionKey` на новые имена XHTTP. **Проверить имена полей XHTTP в рендере sora** — генерация по старым именам сломается на свежем ядре. (Первый проход #12 просил `downloadSettings` — сначала сверить актуальные имена полей.)

### Новое важное
- **VLESS Encryption** (PR #5067) — постквантово-ориентированное шифрование VLESS, не-TLS-внешность по умолчанию (но «не для прямого прохода GFW» — честная оговорка RPRX).
- **REALITY**: поддержка X25519MLKEM768 (PQ key exchange) + ML-DSA-65 для аутентификации (PR #4915).
- **mihomo официально отказывается гнаться за совместимостью** с reality-поведением Xray ≥26.7.11 («Due to xray-core's deliberately incompatible behavior, we will not consider compatibility with xray v26.7.11+ versions» — wiki.metacubex.one). Сигнал фрагментации экосистемы: тестировать REALITY-пары версий клиент/сервер.
- Go 1.27 для сборки; quic-go — форк `apernet/quic-go` v0.61.1; Win7-сборки продолжают жить (XTLS/go-win7).
- По полевым данным (2025–2026): REALITY — транспорт, реже всего ломаемый обновлениями ТСПУ, т.к. хендшейк неотличим от визита на cover-домен.

**Вердикт по теме:** поднять в sora: (1) валидация unencrypted→public IP с учётом версии ядра; (2) миграция reverse→VLESS Reverse Proxy; (3) сверка имён полей XHTTP; (4) рассмотреть bump MinVersion до ≥26.7.11 с честным changelog для пользователя. PQ-фичи (VLESS Encryption, MLKEM в REALITY) — включать как опцию, не дефолт.

---

## 3. mihomo (MetaCubeX) — свежие релизы

Стабильный канал: **≥v1.19.20** (подтверждено OpenWrt-фидом kenzok8/small: PKG_VERSION=1.19.20; дока wiki.metacubex.one упоминает поведение «from v1.19.20 onwards»). Alpha-канал активен (релиз 2026-10-11). Детальных release notes upstream не публикует — только списки коммитов; ниже — сверено по исходникам и докам.

Подтверждённый upstream-набор 2026 (wiki.metacubex.one + исходники):
- **ECH** (Encrypted Client Hello) в TLS-стеке; **X25519-MLKEM768** в REALITY; **mTLS** (client cert/key); управление CA-пулом (system + embedded + custom).
- **AnyTLS** — нативно (transport/anytls: padding, собственная сессионная мультиплексация). uTLS-фингерпринт применяется и к AnyTLS; с v1.19.20 SNI/servername обязателен.
- Structured logs API (`?format=structured`), REST: version/meta, обновление GEO/ядра по каналам.
- TUIC: v4+v5, UDP-over-Stream, настраиваемые CC; `transport/tuic/congestion_v2` (BBR/brutal v2).
- ECH/TLS: предупреждение upstream — **совместимость с Xray ≥26.7.11 по reality сознательно не поддерживается**.

Чего **нет** в upstream (проверено поиском по wiki.metacubex.one — ноль хитов): **MASQUE** и **Mieru** — только в форках (xinebf/mihomo, hooraygith/m). Первый проход (#16) был прав: у mihomo MASQUE нет.

**Вердикт:** держать пин свежим (≥1.19.20); AnyTLS для mihomo — проверить маппинг в `core/engine/mihomo` (для sing-box уже есть); ECH/MLKEM — прокинуть в UI как опции; MASQUE/Mieru через mihomo не брать.

---

## 4. Clash Verge Rev / Mihomo Party (теперь Clash Party)

- **Clash Verge Rev v2.5.7 (окт 2026), текущий v2.5.8.** Релиз почти целиком про service-mode/TUN-стабильность (Windows/macOS/Linux). Копируемое: **диагностика service-mode** — рантайм-логи сервиса пишутся в файл для выяснения причин остановки ядра; при провале security-check Windows-сервиса показывается **реальная причина + ссылка на доку**, а не «service cannot start kernel». Это ровно класс UX, который sora должна скопировать в свой сервис. Плюс: переключение ядер verge-mihomo / verge-mihomo-alpha в рантайме, WebDAV-бэкап, `clash://`/`clash-verge://` deeplinks, Tauri 2 (лёгкий).
  Источник: https://whatsnew.fyi/product/clash-verge-rev/releases/v2.5.7
- **Clash Party (ex-Mihomo Party) v2.0.3 (2026-09-20).** Два ядра: **Smart** (форк vernesong с ML-группами: parallel dialing/racing, LightGBM-модель выбора) + Mihomo. Electron, WebDAV-бэкап, 4 варианта AUR-пакетов. Smart-группы — референс для F2 (автовыбор сервера): умная группа с замерами вместо эвристик.
  Источник: https://clashapp.org/en-US/clash-client/clash-party.html

**Вердикт:** копировать диагностические паттерны Verge (логи сервиса в файл, честные причины ошибок); Smart-группы изучить как референс F2. Прямой угрозы sora нет — оба клиенты без DPI-фокуса РФ.

---

## 5. AmneziaVPN client — свежие релизы

- **5.0.0.5** (amnezia.org/blog): **AmneziaWG 3.0/3.1** (header/size/timing obfuscation + сигнатурные пакеты мимикрии DNS/QUIC — совпадает с первым проходом #10); **установка MTProxy и Telemt-proxy сервисов в один клик**; расширенные VLESS-конфиги (SNI, порт, **transport, security, flow, XHTTP, mKCP-параметры** — т.е. Amnezia уже экспонирует XHTTP в UI); macOS Network Extension в App Store; Android 16KB page size.
  Источник: https://amnezia.org/blog/amneziavpn-5-0-0-5-update
- **5.0.3.0 / 5.0.3.1 (сен 2026)**: **TProxy-поддержка**, обновлённый Xray-core, стабильность. TProxy — их ответ на прозрачный проксинг без TUN (сравнить с планами sora по nfqws).
  Источник: https://www.software-mirrors.com/products/amnezia-vpn-client
- Контекст: 3 публичных аудита 7ASecurity; WhatsApp в 2026 официально рекомендовал Amnezia для censored-регионов; >10M загрузок.

**Вердикт:** главный конкурент по обфускации. Копировать: (1) one-click деплой прокси-сервисов из клиента (MTProxy-паттерн → для sora: one-click naive/XHTTP/AmneziaWG); (2) XHTTP-параметры в UI (у sora тоже в планах — не отстать); (3) TProxy как альтернатива TUN изучить. AWG 3.1-параметры в sora — в работу (первый проход #10).

---

## 6. Коммерческие VPN 2026 — Mullvad, Proton, IVPN

### Mullvad
- **Android 2026.10 (сен 2026)**: интерактивный глобус серверов; **автоматический multi-hop** — клиент сам вставляет entry-hop, когда exit не поддерживает DAITA/PQ (дерево решений внутри клиента, фильтры entry/exit разделены); фикс QUIC-hang (2026.9-регрессия — избегать 2026.9).
- **iOS «Force all apps» (апр 2026)**: `includeAllNetworks` master switch против утечек при обновлениях App Store; честно описаны trade-off (петля обновлений) + safeguards. Это kill-switch уровня Strict из первого прохода (#4) — референс честной коммуникации.
- Прозрачность: публичный known-issues с платформенными утечками (Android 16/17 ломают туннели, broadcast/NAT keep-alive leaks).
  Источники: https://www.webpronews.com/mullvads-quiet-android-overhaul-adds-spinning-globe-and-automatic-multi-hop-routing/ ; https://cyberinsider.com/mullvad-to-add-feature-that-forces-all-ios-traffic-through-the-vpn-tunnel/
- **Копировать:** автоматический multi-hop с decision tree (для F8 proxy chains); документирование известных утечек как фича доверия; strict kill switch с честными предупреждениями.

### Proton VPN
- **Proton Protocols (5.1.5, июль 2026)**: переписанный клиентский WireGuard-стек — быстрее коннекты, меньше дропов; **автоматический детект конфликтов сети** (другой софт мешает VPN — понятный troubleshooting вместо молчания); **connection feedback** (thumbs up/down после коннекта — обратная связь для улучшения); фикс залипших DNS-правил после краша.
- Roadmap осень-зима 2026: новый UI на всех платформах, **улучшения kill switch**, простое «пауза VPN», Stealth на Linux, антицензура + PQ-задел.
  Источники: https://www.webpronews.com/proton-vpn-overhauls-wireguard-codebase-in-quiet-push-for-faster-harder-to-block-connections/ ; https://protonvpn.com/support/release-notes-windows ; https://www.thurrott.com/cloud/342911/proton-discusses-the-roadmaps-for-mail-drive-pass-vpn-and-lumo
- **Копировать:** thumbs up/down после подключения (дешёвый сигнал для F2-автовыбора и диагностики); авто-детект конфликтов (антивирус/файрвол) с понятным текстом; очистка DNS-правил после краша (проверить у sora).

### IVPN
- **Новые тарифы (май 2026)**: Standard ($60/год, теперь с Multi-hop, 5 девайсов), Plus ($80: +Mailx email-aliasing, +modDNS), Pro Suite ($100: +Portmaster Pro). Модель «VPN + смежные приватные сервисы».
- **modDNS (бета, мар 2026)**: аудированный DNS-фильтр (ads/trackers/malware) с гранулярным контролем — референс для DNS-менеджера sora (F3): фильтрующий DNS как отдельный аудированный сервис.
- **V2Ray-обфускация на всех платформах** (ноя 2025) — у IVPN теперь обфускация везде; sora обязана не отставать по покрытию.
- Android: выбор конкретных серверов, **load серверов в UI**, MTU-конфиг для WireGuard, 16KB page.
  Источники: https://www.ivpn.net/blog/ivpn-plan-changes-new-plus-tier-increased-device-limits-additional-privacy-services/ ; https://www.ivpn.net/en/blog/
- **Копировать:** load/скорость серверов в UI (связка с F2/speedtest); DNS-фильтрация как продуктовая единица; V2Ray-обфускация как обязательный минимум покрытия.

---

## 7. ShadowTLS / ShadowTLSv3 — состояние 2026

**Жив, но нишевый.** Факты:
- sing-box 1.12 добавил wildcard SNI для ShadowTLS inbound — протокол поддерживается и развивается в экосистеме.
- `sagernet/sing-shadowtls` v0.2.1 (Go-порт) обновлялся в 2026.
- ShadowTLSv3: привязка канала через session-ID (аутентификация без лишнего round-trip) — самое продвинутое из трёх версий.
- Но: **официальная позиция sing-box — для обхода цензуры использовать NaiveProxy, а не uTLS-трюки** (см. тему 1). ShadowTLS остаётся TLS-in-TLS с известными ограничениями.
- mihomo: ShadowTLS как обёртка поверх shadowsocks (`sing_shadowsocks`).

**Вердикт:** держать как есть (sora уже поддерживает), не инвестировать. Ставка — naive / REALITY / XHTTP / AnyTLS.

---

## 8. TUIC v2 — состояние 2026

**Такого протокола нет — слоп.** Проверка:
- Актуальные версии TUIC — **v4/v5**, поддерживаются sing-box и mihomo (QUIC, UDP-over-Stream, настраиваемые CC).
- То, что мелькает как «v2» — `transport/tuic/congestion_v2` в mihomo (BBR/brutal congestion controller v2), не протокол.
- Поиск «TUICv2» даёт только блокчейн-мусор.

**Вердикт:** игнорировать. TUIC v5 держать как есть.

---

## 9. AnyTLS — что за протокол, состояние 2026

**Реален, поддерживается обоими движками sora, валидирован противником.**
- Что это: TLS-инкапсуляция прокси-трафика для обхода SNI-фильтрации + собственная схема мультиплексирования (заявлено: «mitigate TLS proxy traffic characteristics»). Авторская реализация — AnyTLS/anytls-go.
- Поддержка: **sing-box 1.12+** (inbound+outbound, нативно), **mihomo upstream** (transport/anytls: padding, session/frames, skiplist; uTLS-фингерпринт применяется; с v1.19.20 SNI обязателен).
- Сигнал релевантности: госзакупка КНР (Сучжоу, сен 2026) требует от DPI-оборудования идентификации **AnyTLS** наряду с NaiveProxy/Shadowsocks/V2Ray — протокол в поле зрения цензора, т.е. реально используется для обхода.
  Источник: https://ministryofcyberaffairs.com/news/suzhou-health-authorities-procure-vpn-monitoring-equipment-to-regulate-unauthorized-cross-border-access-f1c9b01f-8164-4d9c-b901-5a9e29c8028d
- sora: рендер для sing-box уже есть (`render.go:248`); **проверить маппинг для mihomo** и capabilities.

**Вердикт:** включать в матрицу протоколов наравне с остальными; в one-click деплой добавить AnyTLS-сервер (дешёвый, движки умеют обе стороны).

---

## 10. Новые протоколы 2025–2026, пропущенные первым проходом

### Mieru — жив, но мимо мейнстрима
- enfein/mieru **v3** активен (pkg.go.dev, 2026). Без TLS (не нужен домен/фейк-сайт), XChaCha20-Poly1305, ключи из username+password+время (PBKDF2, ротация каждые 2 мин), random padding, replay detection, TCP+UDP.
- Клиенты: **Clash Verge Rev, Mihomo Party, Shadowrocket (iOS), Karing**, ClashMi, Exclave. Сервер: форки mihomo, enfein/mbox (форк sing-box).
- **Нет в upstream sing-box и upstream mihomo** (поиск по wiki.metacubex.one — ноль; только форки). Один автор.
- **Вердикт:** мониторить, не интегрировать. Интеграция потребовала бы форк-движков — противоречит 3-движковой модели sora. Пересмотреть, если войдёт в upstream sing-box/mihomo.

### MASQUE — в работе у мейнстрима
- sing-box **1.15-alpha**: MASQUE client+server (CONNECT-IP). Xray: с фев 2025 (первый проход). mihomo: только форки.
- **Вердикт:** в roadmap sora — брать через sing-box/Xray когда 1.15 станет stable; mihomo-версию не ждать.

### Snell — пропустить
- sing-box 1.14 реимплементировал закрытый протокол Surge. Нишевый, проприетарные корни. Слоп для sora.

### Sudoku — слоп
- Кастомный обфускационный протокол форков mihomo (HTTP-маскировка + мультиплексирование). Один форк, ноль аудита. Игнорировать.

### Tailcat — нишевый задел
- sing-box 1.15-alpha: data plane Tailscale без control plane (WireGuard P2P через DERP). Потенциальный транспорт для F9 device sync без центрального сервера. Запомнить, не строить на alpha.

### OpenVPN/OpenConnect в sing-box 1.14 — низкий приоритет
- Клиентская совместимость с корпоративными VPN (Cisco/Fortinet/Palo Alto). Для sora — возможная фича «импорт корпоративного VPN», но не DPI-тема. Отложить.

---

## Отсеяно фильтром (слоп)
- **TUIC v2** — не существует (см. тему 8).
- **Snell, Sudoku** — нишевые/форковые протоколы без аудита и мейнстрим-поддержки.
- **Интерактивный глобус Mullvad** — фан-сервис; копировать только decision-tree multi-hop, не глобус.
- **Clash Party Smart-ядро как зависимость** — брать как референс алгоритма (F2), не как движок (форк одного автора).
- **Mieru-интеграция сейчас** — цена (форк-движки) выше выигрыша.
- **«Quantum-VPN»-маркетинг** вокруг VLESS Encryption — сама фича реальна, но позиционировать честно: PQ-задел, не «невидимость».

---

## Приоритетные действия для sora (сводка)

**P0 (ломается молча):**
1. Xray ≥26.7.11 режет нешифрованный VLESS/Trojan на публичные IP — валидатор sora должен учитывать версию ядра (MinVersion 26.3.27 ниже порога!). Источники: 3x-ui `xray_setting.go`, RPRX.
2. sing-box: убрать `"stack": "mixed"` из рендера (удаление в 1.17.0); полный переход DNS-генерации на новый формат (старый мёртв в 1.14.0). Источник: официальный changelog.
3. Сверка имён полей XHTTP в рендере (3x-ui мигрирует `sessionPlacement`/`sessionKey` — старые имена умрут).

**P1 (дешёвые выигрыши):**
4. hy2-дефолты из 1.14: Chrome QUIC parroting, `bbr_profile`, `gecko` obfs, рандомизация hop_interval.
5. TLS fragment/record fragment в UI тюнинга (нативный десинх без zapret).
6. NaiveProxy: QUIC/ECH/UoT/BBR (1.13), libcronet в дистрибуцию.
7. `wifi_ssid`/`wifi_bssid`-правила в F5 (доверенные сети).
8. AnyTLS для mihomo-движка (для sing-box уже есть).
9. Диагностика в стиле Clash Verge Rev: логи сервиса в файл, реальные причины ошибок + ссылки на доку.

**P2 (roadmap):**
10. MASQUE через sing-box 1.15 stable / Xray.
11. Connection feedback (thumbs up/down, паттерн Proton) → топливо для F2.
12. Server load в UI (паттерн IVPN) + speedtest-сравнение транспортов (уникально, из первого прохода #12).
13. Bump uTLS до v1.8.7 (sora пинит v1.8.2; фикс детекта уже в .2, но движок ушёл дальше).

**Мониторить:** Mieru (upstream-принятие), sing-box for Desktop (конкурент), VLESS Encryption (зрелость), Tailcat для F9.
