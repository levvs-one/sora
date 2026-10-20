# TEAM-A: второй проход веб-разведки — перепроверка 10 находок Tier S

Дата: 2026-10-20. Первый проход: `~/workspace/bug-hunt/reports/WEB-RESEARCH.md` (15 находок Tier S).
Задача: перепроверить первые 10 находок **новыми независимыми источниками 2025–2026** (первоисточники: issue-трекеры, исходники, официальные доки/ченджлоги, полевые тесты).

Процедурная пометка: глубина вложенности не позволила расплодить 10 субагентов (max depth 2/2, spawn запрещён рантаймом) — все 10 тем отработаны одним исполнителем, последовательно-параллельными батчами поиска. Репозитории `~/workspace/bug-hunt/sora` — только чтение, код не менялся.

Легенда вердиктов: ✅ подтверждено · ⚠️ уточнено · ❌ опровергнуто.

---

## 1. zapret: nfqws/winws vs tpws; UDP/QUIC-десинхронизация 2026

**Вердикт: ⚠️ уточнено.**

- Активная разработка 2025–2026 — в nfqws/winws: существует уже **новый репозиторий bol-van/zapret2** (C-демон `nfqws2`/`winws2` + Lua-стратегии `zapret-lib.lua`/`zapret-antidpi.lua`/`zapret-auto.lua`; C — дисекция и трекинг, Lua — вся логика fooling: fake, multisplit, oob). Это следующий шаг после nfqws/winws, а не просто их продолжение.
- tpws **не заброшен**, но новых DPI-фич туда не добавляют: он остаётся stream-level движком для платформ, где нет NFQUEUE/WinDivert (Android через VPN API, macOS через PF — матрица платформ из `docs/readme.md` самого zapret). Полевой инструмент `strategy.sh` (nfqws-keenetic) жёстко ставит `SKIP_TPWS=1` — современные стратегии ищут только для nfqws.
- QUIC/UDP-рецепты 2026 подтверждены независимыми преконфигами (ankddev/zapret-discord-youtube, ALT v3): `--filter-udp=443 --dpi-desync=fake,tamper --dpi-desync-repeats=9 --dpi-desync-udplen-pattern=0xFEEDFACE --dpi-desync-fake-quic=quic_initial_www_google_com.bin`; базовый вариант `--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=6`.
- Что нового vs первый проход: найден **zapret2** — если sora будет портировать zapret, целиться надо уже в Lua-архитектуру zapret2, а не в параметры nfqws v1.

Источники:
- https://deepwiki.com/bol-van/zapret2 (обзор архитектуры, docs/readme.md + manual.md репозитория)
- https://deepwiki.com/bol-van/zapret (матрица платформ, docs/readme.md 71–95)
- https://deepwiki.com/ankddev/zapret-discord-youtube/5.3-cloudflare-pre-configs (QUIC-рецепт ALT v3)
- https://deepwiki.com/nfqws/nfqws-keenetic/3.4-strategy-detection-script (`SKIP_TPWS=1`)

## 2. uTLS-кризис: Chrome 133 детектится, Chrome 155 проходит

**Вердикт: ✅ подтверждено, с усилением.**

- **XTLS/Xray-core issue #7131** (открыт 11.10.2026, активен): Xray пинит utls `aa6edf4` → `fingerprint: "chrome"` шлёт Chrome 133. uTLS-коммит `6ebdceb` (06.10.2026) добавляет `HelloChrome_155` и делает его `HelloChrome_Auto`; JA4 захваченных ClientHello совпадает с настоящим Chrome 155: `t13d1517h2_8daaf6152771_cb7bf5808d99`.
- Полевые тесты (Yota mobile, `siberian-check`): Chrome 133 → **TLS handshake timeout (8426 мс)**; Chrome 155 / Firefox 148 / QQ 11.1 → OK (~700 мс).
- **RPRX (мейнтейнер Xray)**: «Chrome 133 fingerprint has long been targeted by TSPU» — ТСПУ лимитирует *число соединений* с фингерпринтом Chrome 133 (поведенческое ограничение, не обязательно точный детект uTLS).
- Chrome 155 существует в дикой природе (Chrome 155.0.8059.40, окт. 2026) — фингерпринт актуален.
- CVE-2026-27017 (GREASE ECH cipher mismatch, fix в utls 1.8.1) и CVE-2026-26995 (missing padding, fix 1.8.2; CVE позже отклонён — дефект внешней зависимости, не ядра uTLS).
- Локальная проверка sora (read-only): `core/go.mod` пинит `github.com/refraction-networking/utls v1.8.2` — свежая, с обоими фиксами. Риск остаётся на стороне движков (Xray/sing-box/mihomo пинят свой utls) и дефолта `chrome` в sora-legacy (`render.go:269`).
- Что нового vs первый проход: прямое подтверждение от RPRX, что ТСПУ давит именно fp Chrome 133 лимитом соединений; предложение в issue — бамп utls ≥ 6ebdceb + `hellochrome_155` в fingerprint map.

Источники:
- https://github.com/XTLS/Xray-core/issues/7131
- https://www.sentinelone.com/vulnerability-database/cve-2026-27017/
- https://www.wiz.io/vulnerability-database/cve/cve-2026-26995
- https://medium.com/@cachelinecacheline/a-browser-fingerprint-outlived-five-empty-chrome-profiles-0b8be153e2b4 (Chrome 155 в проде)

## 3. REALITY «сибирская» волна: поведенческий детект

**Вердикт: ✅ подтверждено двумя независимыми (не-habr) источниками.**

1. Тот же тред Xray #7131: FunLay123 воспроизвёл на **настоящем Chrome** (не uTLS) — 3 параллельных соединения с одним SNI проходят, 4-е → заморозка на 120 секунд; RPRX подтверждает механику лимита по числу соединений. То есть эвристика поведения, а не детект uTLS — воспроизведено мейнтейнерами Xray, не только автором habr-статьи.
2. parsers.vc (июньская волна 2026): всплески параллельных TCP/TLS-соединений выглядят для фильтров РКН как «аномальный всплеск» → временные баны; HTTP/2 (меньше параллельных соединений) — задокументированное смягчение. Независимое подтверждение той же эвристики с другой стороны.
- Контекст: vgtimes (4 дня назад) — РКН ограничил ~95% VPN-сервисов, в реестре 439+; VLESS+REALITY и AmneziaWG остаются среди самых надёжных на мобильных операторах РФ.
- Что нового vs первый проход: порог «>3 параллельных TLS с одним SNI» подтверждён независимой репликацией; HTTP/2 как контрмера — новый практический вывод.

Источники:
- https://github.com/XTLS/Xray-core/issues/7131 (комментарии FunLay123, RPRX, 13.10.2026)
- https://parsers.vc/news/260612-russia-s-digital-clampdown-snarls-online/
- https://vgtimes.ru/tech-and-hardware/171165-v-rossii-novaya-volna-blokirovok-vpn-pod-udar-popali-celye-podseti-hosting-provayderov.html

## 4. Kill switch 3 уровня: утечки Standard после ребута

**Вердикт: ✅ подтверждено, с важной оговоркой.**

- **Gizmodo, окт. 2026** (независимые reboot-тесты, Windows 11): дефолтные настройки Proton VPN, ExpressVPN, CyberGhost — **утекли после рестарта**; Proton Advanced kill switch и ExpressVPN «Enable at all times» — прошли; NordVPN прошёл на дефолте; CyberGhost чинится только вручную (нет строгого режима).
- **Официальная дока Proton**: Advanced kill switch — персистентные фильтры Windows Filtering Platform, переживающие загрузку/выключение; на Linux — dummy-интерфейс с редиректом всего трафика в никуда. Standard vs Advanced — официальное разделение. Kill switch несовместим со split tunneling (кроме Windows).
- **Оговорка (danielbrummitt.com, март 2026)**: независимый разбор показал, что даже «персистентный» Advanced kill switch Proton на конкретной машине применял правила слишком поздно при загрузке (race condition) — «permanent» на практике может быть application-managed. Доверять только собственным reboot-тестам.
- Mullvad/IVPN (разбор PrivacyGuides, macOS): kill switch всегда включён на Packet Filter; опциональный Lockdown mode (Mullvad) / Always-on firewall (IVPN) с LaunchDaemon, блокирующим не-VPN трафик на старте системы. У Proton на macOS Advanced-режима нет (только Network Extension).
- Windscribe: RTINGS 2024 — из 20 VPN почти все утекли при ребуте; их Always-On пишет правила в ядро ОС, активные с момента включения железа.
- Что нового vs первый проход: свежий (окт. 2026) независимый тест Gizmodo; задокументированный кейс, где даже Advanced-режим подвёл (race на загрузке).

Источники:
- https://gizmodo.com/best-vpn/kill-switch
- https://protonvpn.com/support/advanced-kill-switch
- https://www.danielbrummitt.com/p/critical-security-flaw
- https://discuss.privacyguides.net/t/what-should-we-require-of-vpn-providers-on-macos/36175?page=5
- https://windscribe.com/blog/vpn-kill-switch/

## 5. Встроенный speedtest: методология и реализации у конкурентов

**Вердикт: ✅ подтверждено, с коррекцией по PIA.**

- **Ookla (первоисточник)**: `speedtest.net/help/guides/assessing-accuracy` — download/upload: множество соединений на порт 8080, адаптивный размер чанков и буферов по realtime-замеру, докрутка соединений в первой половине теста при необходимости; latency: серия замеров, в результат идёт **минимальное** значение. `ookla.com/resources/guides/speedtest-methodology` — динамическое масштабирование числа соединений к нескольким серверам (до 10 Gbps), три сценария latency (базовая, multi-server, под нагрузкой).
- **LibreSpeed (собственная документация)**: ping — многократная загрузка пустого файла, тайминг через Performance API; **jitter = стандартное отклонение замеров пинга**; download — параллельные чанки, upload — параллельные POST.
- **ExpressVPN (официально)**: встроенный Speed Test на Windows/Mac/Linux/iOS/Android/Apple TV; по каждой локации — latency + скорость загрузки + Speed Index, сортировка, подключение из результатов. Linux 5.0.0 (21.11.2025): вкладка Speed Test с realtime-разбивкой up/down. По troypoint: тест запускается **в отключённом состоянии** (мерит серверы напрямую, не через туннель — важный нюанс для sora: их цифры про серверы, а не про «скорость через VPN»).
- **PIA — коррекция**: per-server **speed test в клиенте PIA не подтверждён**. Подтверждено (офиц. поддержка PIA + 3 независимых обзора): в списке серверов показывается **latency в мс** с сортировкой по ней, «Choose Automatically» = сервер с минимальной задержкой. Клиенты действительно open source (организация `pia-foss` на GitHub).
- Что нового vs первый проход: методология взята из первоисточников дословно; PIA понижен с «per-server speed check» до «per-server latency»; нюанс ExpressVPN (тест при отключённом VPN) — sora должен мерить именно через туннель, иначе цифры врут.

Источники:
- https://www.speedtest.net/help/guides/assessing-accuracy
- https://www.ookla.com/resources/guides/speedtest-methodology
- https://deepwiki.com/librespeed/speedtest/1.1-features-and-capabilities (документация и код LibreSpeed)
- https://www.expressvpn.com/what-is-vpn/vpn-speed-test
- https://www.expressVPN.com/support/vpn-setup/release-notes/linux-app/ (Linux 5.0.0, 21.11.2025)
- https://piavpnsupport.zendesk.com/hc/en-us/articles/46813740976667-Understanding-Advanced-Settings-on-the-Desktop-PIA-Client

## 6. sing-box TUN: новый стек в 1.15, `stack: mixed` deprecated

**Вердикт: ✅ подтверждено по официальным первоисточникам.**

- Официальный changelog sing-box (1.15.0-alpha.3): «Significantly improve TUN performance with a new TCP/IP stack — Since 1.15.0, sing-tun uses its own TCP/IP stack, with substantial improvements over all previous implementations in peak performance, energy efficiency, and memory usage. Remove the `stack` option to use it. The `stack` option is deprecated and **will be removed in sing-box 1.17.0**».
- Официальный Migration guide: «The `stack` option is deprecated in sing-box 1.15.0 and will be removed in sing-box 1.17.0»; с 1.16.0 для легаси-стека нужен `ENABLE_DEPRECATED_TUN_STACK=true`.
- Дока TUN inbound: `stack` — «Deprecated in sing-box 1.15.0».
- Независимое эхо про MTU: changelog Flutter-пакета v2ray_box — «reduced VPN TUN MTU from 9000 to 1500 for better mobile network stability». Практика подтверждает: MTU 9000 — баг.
- Что нового vs первый проход: ничего противоречащего; всё подтверждено дословно из официальных док. Дополнительно: в ченджлоге 1.14.0 видны смежные новинки (Chrome QUIC fingerprint parroting, BBR profile, hop interval randomization у Hysteria2).

Источники:
- https://sing-box.sagernet.org/changelog/
- https://sing-box.sagernet.org/migration/
- https://sing-box.sagernet.org/configuration/inbound/tun/
- https://pub.dev/packages/v2ray_box/changelog

## 7. Hysteria2 brutal CC + port hopping

**Вердикт: ✅ подтверждено (механизм + полевые тесты); независимых численных замеров brutal-vs-BBR не найдено.**

- **Официальная дока hysteria.network**: brutal CC активируется, когда заданы `up_mbps`/`down_mbps`, иначе fallback на BBR. Port Hopping: «ISPs block or throttle persistent UDP connections… these restrictions often only apply to the specific port being used. Port hopping can be used as a workaround» — прямое подтверждение назначения; `hopInterval` / `minHopInterval`+`maxHopInterval` (рандомизация против детекта паттерна).
- Код (daeuniverse/outbound, client.go 126–145): выбор алгоритма — `actualTx = min(serverRx, clientTx) > 0 → Brutal`, иначе BBR.
- **Независимый полевой тест — Colitu (VPN-вендор, окт. 2026)**: port hopping на Android — хоп каждые ~30 с, сервер отвечает на каждом новом порту, прозрачно для верхних слоёв, «сетям, которые душат долгоживущие UDP-потоки, так сложнее это делать».
- **Бонусное подтверждение из того же источника**: баг сервера v2.11.0 «живое, но не шлёт» (stall без обрыва после upload speed test — flow-control window пинится дестинейшеном, который перестал читать) — независимо воспроизведён в лаборатории и пофикшен 37 строками на сервере. Совпадает с находкой первого прохода.
- Ограничение: численные замеры первого прохода (Москва→DE: hy2 88/62 vs VLESS 72/45) независимого подтверждения не получили — считать их ориентиром, не фактом.
- Что нового vs первый проход: официальная дока port hopping как анти-throttling; независимое подтверждение stall-бага v2.11.0.

Источники:
- https://hysteria.network/docs/advanced/Port-Hopping/
- https://deepwiki.com/daeuniverse/outbound/5.1-hysteria2-protocol
- https://dev.to/colitu/our-hysteria2-connections-died-after-every-upload-speed-test-the-fix-was-37-lines-2n81
- https://lab.colitu.com/research/hysteria2-stall-after-upload

## 8. mihomo rule-providers: MRS и behavior-mismatch

**Вердикт: ✅ подтверждено (официальные доки + исходники).**

- **Meta-Docs (официальная документация mihomo)**: поле `behavior` «must match the actual content format of the rule file»; типы: `domain` (только DOMAIN/DOMAIN-SUFFIX/DOMAIN-KEYWORD), `ipcidr` (только IP-CIDR/IP-CIDR6), `classical` (все типы).
- **MRS** (Meta Rule Set): бинарный формат, поддерживает только `domain` и `ipcidr`; генерация штатным CLI: `mihomo convert-ruleset domain/ipcidr yaml/text XXX.yaml XXX.mrs`; в сравнении форматов — «smallest size, fastest parsing», рекомендован для продакшена. Пример из официальных конфигов: `geoip/cn.mrs`, `geosite/google.mrs`.
- **Исходники** (через deepwiki xinebf/mihomo): MRS — zstd-сжатый прекомпилированный trie/CIDR-set (`rules/provider/mrs_converter.go`, magic bytes, behavior зашит в файл); `domain` → DomainTrie+DomainSet, `ipcidr` → CIDR trie, `classical` → последовательный список (`rules/provider/*_strategy.go`).
- Mismatch: валидации соответствия behavior↔контент в ядре нет — провайдер молча парсит чужой стратегией (пустые/неверные матчи). Вывод первого прохода (sora должен валидировать сам с понятным сообщением) — в силе.
- Что нового vs первый проход: точная команда генерации MRS и структура формата из исходников; официальные примеры `.mrs`-URL (Loyalsoldier-стиль: `geoip/`, `geosite/`).

Источники:
- https://deepwiki.com/MetaCubeX/Meta-Docs/4.2-rule-providers (официальные доки rule-providers)
- https://deepwiki.com/MetaCubeX/Meta-Docs/7.2-rule-set-configuration (RULE-SET синтаксис, примеры)
- https://deepwiki.com/nekrozis/mihomo/2.3-metadata-and-rule-engine (mrs_converter.go, стратегии)

## 9. OONI intelligence: живость API и прецеденты

**Вердикт: ✅ подтверждено.**

- **api.ooni.io жив**: сторонние интеграции используют `https://api.ooni.io` как прод-эндпоинт (пример — OONI RIA Data Node); ClickHouse (кейс-стади, ~март 2026): OONI держит живую таблицу `fastpath` на **1.4 млрд записей**, агрегационные запросы питают Measurement Aggregation Toolkit (MAT) — инфраструктура активно работает.
- **Aggregation API существует**: в бэкенде ooni (`ooniapi/services/oonimeasurements/.../aggregate_analysis.py`) — эндпоинт анализа с LONI-векторами (likelihood: blocked / down / OK), квантильная статистика `quantile(0.95)` по `dns_blocked`/`tcp_blocked`/`tls_blocked`; измерения группируются по `probe_cc`, `probe_asn`, `test_name`. ooni.org официально рекомендует агрегатный анализ + ASN-уровень для выводов о цензуре.
- **Tor Connection Assist — прецедент подтверждён**: Tor Browser 11.5+ автоматически подбирает мосты под страну пользователя — скачивает country-specific список через Moat API (с согласия пользователя, domain fronting, без подключения к Tor-сети). Tails-доки подтверждают тот же Moat-механизм («ask for a bridge based on your region»).
- **Psiphon — прецедент подтверждён официально** (psiphon.ca): «Rather than relying on a single fixed transport, the client varies how that connection is carried and obfuscated, selecting an approach dynamically based on the conditions in the user's network»; «Tap Connect and Psiphon tries the available routes and connection methods for you». Полевой масштаб: Иран, январь 2026 — до **9.6 млн дневных пользователей** во время национального шатдауна (Iran Chronicle, июль 2026).
- Что нового vs первый проход: LONI-модель и квантильная агрегация как готовый формат «риск-скора»; масштабный свежий прецедент Psiphon (9.6M DAU в шатдаун).

Источники:
- https://deepwiki.com/ooni/backend/5.2-data-aggregation-service
- https://clickhouse.com/blog/ooni-analyzes-internet-censorship-data-with-clickhouse
- https://ooni.org/support/interpreting-ooni-data/
- https://www.infosecurity-magazine.com/news/tor-browser-automatic-censorship/
- https://www1.tails.net/doc/anonymous_internet/tor/index.en.html
- https://Psiphon.ca/en/faq.html
- https://www.psiphon.ca/en/why-psiphon.html
- https://iran-chronik.org/artikel/internetzensur-psiphon.en.html

## 10. AmneziaWG 3.1 и применение AWG-полей движком

**Вердикт: ✅ подтверждено; риск молчаливого no-op подтверждён кодом самой sora.**

- **AmneziaWG 3.1 существует** (официальные доки docs.amnezia.org + блог amnezia.org):
  - **Header Protection**: ChaCha20 поверх незашифрованных служебных частей WG-пакетов; nonce — первые 12 байт соответствующего `S1–S4`-префикса, ключ — параметр **`HeaderProtectionKey`**; применяется к Init (148 B) / Response (92 B) / Cookie (64 B) / Data (16 B); требуется `S1–S4` ≥ 12 байт; при включённой защите `H1–H4` рекомендуют оставить стандартными (1,2,3,4) — кастомный header-механизм при этом отключён.
  - **ContentPaddingAddition**: случайный паддинг транспортных пакетов в пределах внутреннего MTU (ломает статистику «кратно 16»).
  - **Custom timings**: re-handshake/keepalive/timeout как диапазоны, значение выбирается случайно.
  - Релиз — ответ на поведенческий AI-DPI («летняя атака»); self-hosted — 3.1, Premium — 3.0; нужен Amnezia VPN 5.0.1.5.
- **sing-box upstream AWG-поля не применяет**: поддержка AmneziaWG существует только в форке **amnezia-box** (hoaxisr) — файлы `option/awg.go`, `protocol/awg/endpoint.go`, `include/awg.go` + патчи к `amneziawg-go` (AWG 2.0: counter obf tag, S4 keepalive fix). В апстриме SagerNet/sing-box их нет.
- **Локальная проверка sora (read-only, ключевая находка)**: `core/engine/singbox/render.go` (`wireguard()`) при заданном `o.Amnezia` **эмитит `jc/jmin/jmax/s1–s4/h1–h4/i1–i5` в конфиг `type: wireguard` эндпоинта** и падает с ошибкой только на `J1/J2/J3/Itime` («require another engine»). При этом `core/go.mod` вообще не зависит от sing-box как библиотеки — движки у sora внешние бинарники. **Вывод: если sora подкладывает апстримный sing-box, все эти поля молча игнорируются — на проводе обычный WireGuard.** Предупреждение первого прохода из гипотезы превратилось в подтверждённый кодом факт.
- Полевые данные (vpnsmith, 1 день назад): AmneziaWG в Китае (GFW 4.0) по публичным отчётам часто детектится — «Китай — не AWG, а VLESS/XHTTP» подтверждается.
- Что нового vs первый проход: точная механика HeaderProtectionKey из официальных док; **локально доказанный** no-op риск в рендере sora.

Источники:
- https://docs.amnezia.org/documentation/amnezia-wg/
- https://amnezia.org/blog/amneziawg-3-1-is-here
- https://deepwiki.com/hoaxisr/amnezia-box/10.3-amneziawg-patches
- https://deepwiki.com/hoaxisr/amnezia-box/4.3-wireguard-and-amneziawg-outbounds
- https://www.vpnsmith.com/en/blog/anti-dpi-vpn-bypass-2026
- Локально: `~/workspace/bug-hunt/sora/core/engine/singbox/render.go` (функция `wireguard`, строки ~331–352), `~/workspace/bug-hunt/sora/core/go.mod` (нет зависимости sing-box)

---

## Сводка вердиктов

| # | Тема | Вердикт |
|---|------|---------|
| 1 | zapret: nfqws/winws vs tpws; QUIC-рецепты | ⚠️ уточнено (появился zapret2 с Lua; tpws — не мёртв, а платформенный fallback) |
| 2 | uTLS: Chrome 133 детектится, 155 проходит | ✅ подтверждено (Xray #7131 + RPRX + полевые тесты) |
| 3 | REALITY «сибирская» волна | ✅ подтверждено (репликация мейнтейнерами Xray + parsers.vc) |
| 4 | Kill switch: Standard течёт после ребута | ✅ подтверждено (Gizmodo 10/2026 + доки Proton/Mullvad/IVPN; оговорка про race) |
| 5 | Встроенный speedtest | ✅ подтверждено, PIA скорректирован (latency, не speed test) |
| 6 | sing-box 1.15 TUN / `stack` deprecated | ✅ подтверждено (официальные changelog/migration/доки) |
| 7 | Hysteria2 brutal CC + port hopping | ✅ подтверждено (доки + код + полевой тест Colitu); численных бенчмарков не найдено |
| 8 | mihomo rule-providers / MRS | ✅ подтверждено (Meta-Docs + исходники) |
| 9 | OONI API + прецеденты | ✅ подтверждено (MAT/LONI живы; Connection Assist; Psiphon 9.6M DAU) |
| 10 | AmneziaWG 3.1 + применение полей | ✅ подтверждено; no-op риск доказан кодом sora |

Ни одна из 10 находок не опровергнута. Две уточнены (1, 5). Новых блокирующих противоречий первому проходу нет.
