# GROUP-D «DNS» — сводка третьего прохода

Дата: 2026-10-20. Лид группы D. 10 тем, файлы `31–40` в `deep-research/`. Первый проход (WEB-RESEARCH тиры 18/30, отчёты 29-doh3-doq.md, 45-fakeip-comparison.md) — не дублируется: здесь RFC, исходники sing-box/mihomo, доки, факты 2026.

Отчёты:
- [31-doh-rfc8484.md](31-doh-rfc8484.md) — RFC 8484: механика, границы, когда DoH достаточно
- [32-doh3-doq-rfc9250.md](32-doh3-doq-rfc9250.md) — RFC 9250: стримы, 0-RTT, ALPN doq, порт 853
- [33-fakeip-deep.md](33-fakeip-deep.md) — FakeIP: аллокация, IPv6, исключения, пул; найден дефект фильтра в sora
- [34-dns-leaks.md](34-dns-leaks.md) — утечки: NRPT/SMHNR, systemd-resolved, macOS, Android (Private DNS + keepalive-обход 09.2026)
- [35-split-dns.md](35-split-dns.md) — split DNS, исключения .ru, captive-portal state machine
- [36-https-svcb-ech.md](36-https-svcb-ech.md) — HTTPS/SVCB (RFC 9460) + ECH (RFC 9849): DNS как enabler
- [37-dns-hijacking.md](37-dns-hijacking.md) — хайджекинг: APT28/Operation Masquerade (04.2026), детект, RU-пресет
- [38-singbox-dns.md](38-singbox-dns.md) — DNS в sing-box 1.14: найден вероятный баг DoH3-рендера
- [39-mihomo-dns.md](39-mihomo-dns.md) — DNS в mihomo: 4 контекста, fallback-filter, policy; найдено смешивание классов
- [40-resolver-audit-2026.md](40-resolver-audit-2026.md) — аудит резолверов: DoH3-факты, no-logs с основаниями, закрытие Mullvad 02.11.2026

## Найденные дефекты в коде sora (проверить и чинить)

1. **DoH3-рендер sing-box — legacy-формат** (`core/engine/singbox/render.go:515-523`): `{"address": "h3://..."}` без `"type"`. По докам: без type = legacy, legacy удалён в 1.14 (sora пинит 1.14.2). Правильно: `{"type":"h3","server":...,"server_port":443,"path":"/dns-query", dial fields}`. Проверить `sing-box check -c` на 1.14.2.
2. **Фильтр FakeIP в sing-box молча неполный** (`fakeIPFilterSuffixes`): паттерны с interior wildcard (`time.*.com`, `ntp.*.com`) пропускаются — на sing-box NTP получает фейковые IP, на mihomo реальные. Развернуть в явные суффиксы.
3. **mihomo: direct+proxy в одном `nameserver`** (`rules.go:223`): `batchExchange` гонит серверы наперегонки — путь DNS недетерминирован, часть запросов светит домены провайдеру. Разделить: `nameserver`=proxy-only, прямые → `direct-nameserver`.

## Ранжированные рекомендации

### TIER S — баги и блокеры

| # | Что | Эффект |
|---|---|---|
| S1 | Починить DoH3-рендер sing-box под 1.14 (`type: h3` + dial fields), `sing-box check` в CI | Конфиг может не валидироваться на 1.14 |
| S2 | Починить FakeIP-исключения sing-box (interior wildcard → явные суффиксы) + `time.windows.com`, `+.stun.*.*` | Ломается NTP/WebRTC на sing-box |
| S3 | Разделить классы резолверов в mihomo (nameserver / direct-nameserver / proxy-server-nameserver) | Недетерминированный путь DNS = утечки |
| S4 | Убрать Mullvad из пресетов (shutdown 02.11.2026), миграционное предупреждение | Мёртвый резолвер в UI через 2 недели |

### TIER A — высокий эффект

| # | Что | Отчёт |
|---|---|---|
| A1 | DoH3-first с transport probing при старте/смене сети; лестница DoH3→DoH→DoT; DoQ — только ручная опция | 31, 32 |
| A2 | Закрытие утечек на уровне ОС: NRPT `.`→туннельный DNS + DisableSmartNameResolution (Windows-служба); `resolvectl dns/domain sora0 ~.` (Linux-служба); macOS — честный «частично» | 34 |
| A3 | Captive-portal state machine: пробы 3 платформ → portal (system DNS + bypass хоста) → online (restore + probing); пробы только через system/local | 35 |
| A4 | Пресет «RU-антицензурный» одним выбором: DoH3-first через туннель, Quad9/AdGuard/CF h3, `.ru`→direct, детект подмены | 37, 40 |
| A5 | Split DNS `.ru/.рф` → direct (sing-box правило + direct-сервер; mihomo nameserver-policy) | 35, 39 |
| A6 | FakeIP: унифицировать `/15`, AAAA в fakeip только при IPv6=on, инвалидация кэша при смене движка, диагностика пула | 33 |

### TIER B — средний эффект

| # | Что | Отчёт |
|---|---|---|
| B1 | Диагностика ECH-readiness (HTTPS-запись через туннельный DoH, парсинг `ech=`); инвариант «QTYPE 65/64 не фильтруются, не уходят в fakeip» | 36 |
| B2 | Дифференциальный детект подмены DNS (3 пути резолва; «подмена» vs «цензура» — разные UI-строки) | 37 |
| B3 | sing-box: `optimistic` кэш, `disable_cache` для `rcode://`, `type: mdns` для `.local`, явный `detour` у proxy-only (новый формат не наследует default route) | 38 |
| B4 | UI резолверов: протоколы + основание privacy-заявления (аудит KPMG 04.2026 / заявление оператора) + юрисдикция; перепроверка раз в полгода | 40 |
| B5 | mihomo: `?h3=true` только при явном выборе DoH3 («без отката на H2»); `ipv6: false` при IPv6=off; fallback-filter для RU через ipcidr/domain (честно: детект отравления, не цензуры) | 39 |
| B6 | Документировать как не-баги: браузерный DoH обходит hijack, Android keepalive-offload (09.2026, без фикса Google) | 34 |

## Что НЕ делать (отсеяно фильтром)

- Свой публичный резолвер sora (операционная нагрузка + точка доверия).
- «Переключатель ECH» в UI (клиент не владеет TLS-хендшейком; ECH делает браузер).
- DoQ как дефолт в RU (порт 853 — первый кандидат на блокировку; сам RFC 9250 не обещает middlebox-resistance).
- `fake-ip-filter-mode: whitelist` по умолчанию (ломает новые сервисы).
- Пометка «no-logs» без указания основания (аудит vs заявление) — маркетинг уровня скам-VPN.
- Локальная DNSSEC-валидация как требование (ломает кривые зоны; достаточно валидации на резолвере).

## Ключевые факты 2026, влияющие на решения

- Mullvad public DNS — shutdown 02.11.2026, спонсирует Quad9 (S4).
- APT28/Operation Masquerade (04.2026): 18k+ роутеров с переписанным DNS — «доверять DHCP-DNS» больше нельзя (37).
- Android keepalive-offload (09.2026): обход «Block connections without VPN», фикса Google нет (34).
- Cloudflare KPMG-аудит 04.2026 — единственный независимый аудит no-logs среди бесплатных (40).
- sing-box 1.14: legacy DNS-формат удалён, `independent_cache` deprecated (удаление в 1.16) (38).
- ECH = RFC 9849 (2025); Firefox 119+/Chromium 117+ — ECH по умолчанию, но только при HTTPS-записях через DoH (36).
