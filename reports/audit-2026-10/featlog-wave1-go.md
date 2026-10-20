# Wave 1 backend (Go) — featlog

## F3: DNS leak check (backend) — DONE

**Proto** (`proto/sora/core/v1/core_control.proto`):
- Новый RPC `CheckDnsLeaks` (секция "Since 1.8", требует control authenticator).
- `message DnsLeakCheck { id, label, expected, actual, leaked, fix_hint }` — label и
  fix_hint задокументированы как **ключи локализации**, не свободный текст.
- `CheckDnsLeaksRequest{api_version, control_authenticator, session_id}`,
  `CheckDnsLeaksResponse{repeated DnsLeakCheck checks, SoraError error}`.
- Go-код перегенерирован через buf 1.50.0 + protoc-gen-go v1.36.11 +
  protoc-gen-go-grpc v1.5.1 (временно исключён protoc-gen-dart из buf.gen.yaml,
  файл возвращён как был — **Dart-codegen не перегенерирован, это за Dart-агентом**).
- Bump API: `core/cmd/sora-core/main.go` Minor 7 → 8 (MinSupportedMinor без изменений).

**Логика** (`core/diagnostics/dnsleak.go`, новый):
- `CheckDnsLeaks(ctx, DnsLeakInput) []DnsLeakCheck` — три проверки:
  - `tunnel-dns`: настроены ли резолверы туннеля + sanity-probe canary-домена
    (`one.one.one.one`, задокументирован; один DNS-запрос, больше никакого трафика).
    Пустой конфиг = leak. Упавший canary = outage, не leak (честно в actual).
  - `system-resolvers`: резолверы ОС vs резолверы туннеля; расхождение вне
    туннеля = leak, но только если DNS не hijacked и kill switch не armed.
    Детект не удался = "(unknown)", без гаданий.
  - `killswitch-dns`: kill switch не armed = warning (fix_hint), не leak.
- Нормализация резолверов (IPv6-скобки, нестандартные порты), сравнение по множеству.
- Encrypted-транспорты (tls/https/quic) для canary не пробуются — честно в actual.
- Весь ввод для тестов инжектится (SystemResolvers, CanaryHost, Resolve, timeouts).

**Детект системных резолверов**:
- `systemdns_resolvconf.go` (`!windows`): парсинг `/etc/resolv.conf`.
- `systemdns_windows.go` (`windows`): `GetAdaptersAddresses` (паттерн как в
  `packets_windows.go`), `SocketAddress.IP()`.

**RPC** (`core/control/dnsleak.go`, новый): `CheckDnsLeaks` — `s.authorize`
(version + token, как ListConnections), требует активную сессию
(`KeySessionRequired` = "not connected" в UI), таймаут 10с (контракт < 10с),
туннельные резолверы из `running.Plan().DNS`, hijack из `HijackTun`,
kill switch из `running.Status().KillSwitch`. В `readOnlyMethods` не добавлен —
по умолчанию control-only (fail closed), как задумано.

**Тесты** (`dnsleak_test.go` — 13, `systemdns_internal_test.go` — 3):
чистый кейс, детект утечки, подавление hijack/killswitch, warning killswitch,
пустой туннель, падение canary, выбор резолвера для canary, пропуск encrypted,
дедлайн контекста, IPv6 в скобках/с портом, парсинг resolv.conf (комменты,
дубли, отсутствие файла). Мутационная проверка: инверсия сравнения → тест падает.

**Проверки**: `go build ./...`, `go vet`, `gofmt` — чисто (linux + GOOS=windows);
`go test ./diagnostics/ ./control/` — зелёные.

## F4 (backend) — N/A
По плану: «Ядро (Go): без изменений» (`ListConnections`/`CloseConnection`/`GetStats`
уже есть). Ничего не делал.

## Теневые фичи T1–T11 (волна 1) — backend
- T10 → F3 (выше). T7 → F4 (без backend-изменений). T5 → F0 (без нового кода).
  Других backend-кусочков волны 1 в плане нет.

## Заметки для Dart-агента (F3 UI)
- Нужна перегенерация Dart-codegen (`protoc-gen-dart`, buf) — Go-сторона готова.
- `app/lib/src/core/link.dart`: apiVersion 1.7 → 1.8 (иначе CheckDnsLeaks недоступен).
- Контракт: `label`/`fix_hint` — ключи (`dnsLeak.check.*`, `dnsLeak.fix.*`), добавить
  в `app_ru.arb`/`app_en.arb`; `fix_hint` при `leaked=false` = жёлтое предупреждение.
- `expected`/`actual` — сырые значения (IP через запятую, "(none)", "(unknown: …)").

## Коммиты
- `[feature][sora-go] proto: CheckDnsLeaks RPC + API 1.8 (F3)`
- `[feature][sora-go] DNS leak diagnostics core (F3)`
- `[feature][sora-go] wire CheckDnsLeaks RPC in control plane (F3)`
