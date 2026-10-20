# D11 — диагностика DNS и JA4: полнота, честность, реальные байты (sora Go core)

Коммиты: часть в чужом `1121593` (`dnsleak.go`, `dnsspoof.go` + тесты — побайтово D11, сверено md5), свой `47fe6da` (7 новых файлов). Пуша нет.

## 1. CheckDnsLeaks врал и молчал — три класса проблем устранены
- **Было:** канарейка помечала TCP-резолверы как пробируемые, но `resolveVia` всегда звонил по UDP — ложный «unreachable» про TCP-путь; пробировался только первый plain-резолвер (сломанный второй за рабочим первым проходил молча); шифрованные транспорты (DoT/DoH) — тихий pass «canary not probed: encrypted transport», даже если DoH мёртв; **пропущенный вектор**: при `DnsHijacked=true` проверка чистая, хотя hijack ловит только порт 53 — системный DoT/DoH (systemd-resolved `DNSOverTLS`, DoH ОС/браузера) уходит мимо туннеля, и проверка об этом молчала.
- **Стало** (`dnsleak.go` переписан, новый `dnsprobe.go`, `systemdns_encrypted_linux.go`/`_other.go`): `Probe(ctx, network, addr, host)` вместо `Resolve` — сеть (`udp`/`tcp`/`tls`/`https`) едет в пробер; `canaryTarget` честно описывает непробируемое (`quic`/`h3` — «no QUIC prober», `fakeip` — «synthetic answers»); канарейка параллельно пробирует все пробируемые резолверы; новые stdlib-проберы `dohVia` (DoH RFC 8484, POST `application/dns-message`, A+AAAA параллельно) и `dotVia` (DoT RFC 7858, length-prefixed кадры) — без новых зависимостей; новая проверка **encrypted-dns**: сверяет ОС-шифрованный DNS с туннельными шифрованными резолверами (Linux — парсинг `resolved.conf` + drop-ins; остальные ОС — честное «(unknown)»); `DnsHijacked` её намеренно не подавляет (hijack — только порт 53), подавляет только kill switch. IPv6: отдельного нового вектора не найдено — system-resolvers уже сравнивают IPv6, канарейка IPv6-резолверы пробирует.
- **Эффект:** врущие/молчащие результаты устранены; новый вектор обхода (DoH мимо туннеля) теперь ловится.

## 2. JA4 stealth-оценка — реальная проверка, не текст (новый `ja4.go`)
- **Было:** только текстовые знания в `engine/fingerprint.go`.
- **Стало:** `AssessJA4` захватывает реальные байты ClientHello, которые uTLS-профиль ядра эмитит (рукопожатие против записывающей заглушки, сеть не задействована), парсит их и считает JA4 по спецификации FoxIO (сортировка, GREASE strip, SNI/ALPN исключены из хэша, sigalgs дописаны). Корректность доказана побайтовым совпадением с документированным JA4 Chrome 133 (`t13d1516h2_8daaf6152771_d8a2da3f94cd`). Вердикт свежести: stale-set (Chrome 133 задокументирован как блокируемый ТСПУ), documented-good (Chrome 155); для `randomized` — 3 захвата должны дать ≥2 разных JA4 (иначе «randomization is broken»); нота про PQ key share (X25519MLKEM768).
- **Ключевая находка:** в `go.mod` зафиксирован utls v1.8.2, где `HelloChrome_Auto = HelloChrome_133` — профиль «chrome» реально эмитит stale-фингерпринт, блокируемый ТСПУ. Проверка это ловит и честно репортит (`Fresh=false`). Бамп utls — решение владельца (зависимостей D11 не трогал).
- **Эффект:** клиент впервые измеряет свой TLS-отпечаток, а не гадает; связка с D05 (ротация фингерпринтов).

## 3. Таймауты/дефолты канареек
- **Исправлено:** `resolveVia` теперь ставит `Dialer.Timeout` (раньше полагался только на ctx — висел бы на голом контексте); `dohVia` — `http.Client{Timeout}`; `dotVia` — dial-timeout + deadline. `defaultResolveTimeout=3с` оставлен (проберы параллельны → худшее ≈3с, внутри 10с бюджета control); `canaryHost=one.one.one.one` оставлен; новый `defaultJA4Timeout=5с` (захват локальный, ~100мс).

Верификация: `go build`, `go vet` — чисто; `go test ./diagnostics/` — всё зелёное (точное совпадение JA4 Chrome 133; DoH через httptest позитив/500/дедлайн; DoT через локальный TLS-сервер; wire round-trip и негативы парсера; encrypted-dns leak/covered/killswitch; TCP-проба по TCP).

⚠️ **Инцидент (вина D11, честно):** первый коммит ушёл с пустым деревом (`ca280d8`, осиротел — вреда нет); второй (`47fe6da`) — со stale-деревом и молча откатил ~38 файлов сиблингов (l10n, updates UI, `engine/validate.go`, удалил `validate_ech_test.go`) — дерево починилось само через чужой коммит. Урок в AGENTS.md дополнен: temp index только с фиксированным именем внутри одного exec-вызова, без `$$`.

**Открытое:** проводка `AssessJA4` в control RPC / UI (нужен ID проверки в контракте); бамп utls до HelloChrome_155; `TestCoreUTLSFreshnessGate` падает by design (tripwire — решить: оставить или смягчить).
