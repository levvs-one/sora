# Отчёт аудита: Go-ядро (parser, subscription, engine, probe)

**Зона:** `core/parser/`, `core/subscription/`, `core/probe/`, `core/engine/` (catalog.go, catalog_linux.go, registry/, supervise/, engine.go, profile.go, validate.go, fields.go, refs.go, redact.go, backoff.go, tun.go), `core/engine/bypass/`, дополнительно по необходимости `core/engine/tunroute/`, `core/engine/xray/`, `core/engine/xraytun/`, `core/engine/clashapi/`, `core/engine/mihomo/`, `core/engine/singbox/`.

**Дата:** 2026-10-19. **Методология:** сплошное чтение кода + точечный grep по паттернам (`exec.Command`, `LookPath`, `InsecureSkipVerify`, `os.WriteFile`, `http.Get`, `syscall`, `panic(`, `template`, `filepath.Join`, `..`). Go toolchain в окружении отсутствует — только статический анализ, без запуска тестов. Каждый баг проверен чтением окружающего кода (валидация выше/ниже по потоку, кто вызывает, откуда данные).

**Краткий вывод по проверенным рискам (без находок):**
- SSRF при фетче подписок — защита сильная: только HTTPS, запрет userinfo, лимит 5 редиректов с ревалидацией каждого хопа, `dialChecked` блокирует dial на непубличные адреса (защита от DNS-rebinding через `Control`-хук), лимит тела 16 МиБ, таймауты (30 c общий, 20 c на заголовки, 10 c TLS-handshake). Остаток — находка L5.
- Секреты в argv/env — чисто: конфиги движков идут через stdin (`-c stdin`, `-f -`), `SafeEnv()` режет env до allowlist, контроллерный secret — в stdin-конфиге, не в argv.
- World-readable файлы с секретами — нет: конфиги на диск не пишутся вообще; `fakeip-pool` — 0600; home-директории движков — 0700; geodata копируются через temp+rename.
- Path traversal из подписки — нет: тела подписок на диск не кэшируются; имена из подписки не используются как имена файлов (home-директории — из фиксированных kind'ов).
- Инъекция в argv движков — конфиги JSON/YAML собираются через marshal (инъекционно-безопасно); tpws-аргументы строятся из `BypassStrategy`, валидированной строгим regexp. Исключение — находка M1.
- Таймауты HTTP — есть везде (см. выше); probe — 5 c на эндпоинт, лимиты 256 эндпоинтов / 8 сокетов / 4 конкурентных запроса.
- YAML/JSON-парсинг — лимит 16 МиБ; yaml.v3 не разворачивает алиасы экспоненциально.
- Xray-профили провайдера — `stripFiles` рекурсивно удаляет `certificateFile`/`keyFile`/`masterKeyLog`; `profileOwned` удаляет `inbounds/log/api/stats/metrics/policy/remarks/meta/reverse` до подстановки сессионных. Файловое чтение через профиль закрыто.

---

## Находки

### 1. [Medium] Инъекция аргументов в привилегированный `ip` через `Tun.DeviceName`
**Категория:** command argument injection (CWE-88) · **Файлы:** `core/engine/tunroute/tunroute_linux.go:52-84, 349-358`, `core/engine/fields.go:42-59`

`ip()` собирает командную строку конкатенацией строк и режет её `strings.Fields`:
```go
out, err := exec.CommandContext(ctx, "ip", strings.Fields(args)...).CombinedOutput()
```
а `routeSteps`/`cleanup` подставляют туда `tun.DeviceName` как есть:
```go
family+" addr replace "+address+" dev "+tun.DeviceName
family+" route replace default dev "+tun.DeviceName+" src "+source+" table "+table
family+" addr del "+address.String()+" dev "+tun.DeviceName   // cleanup()
```
Валидация имени — лишь `validateDisplayName("tun", t.DeviceName)` (`fields.go:55`), которая запрещает только управляющие символы и пробелы по краям; **внутренние пробелы разрешены**. Имя вида `sora0 bogus` разваливается на два argv-элемента; имя с ведущим `-` парсится как опция `ip`. Шелла нет, поэтому это не RCE, но `ip` выполняется с привилегиями сервиса (установка маршрутов требует root/CAP_NET_ADMIN): можно сломать установку маршрутов (DoS туннеля) или подсунуть лишние селекторы в `ip rule/route/addr`. Источник `DeviceName` — план (`p.Tun.DeviceName`), `PrepareTun` его не валидирует вообще (только дефолт `sora0`).

**Сценарий:** план с `tun.device_name = "sora0 xfrm"` → `ip -4 addr replace 192.0.2.1/30 dev sora0 xfrm` → ошибка `ip`, маршруты не встали, трафик идёт мимо туннеля/туннель мёртв. Вариант с `-`: `device_name = "-json"` → `ip` трактует как флаг.

**Фикс:** строгая валидация имени интерфейса в `Tun.validate()`: `^[A-Za-z0-9][A-Za-z0-9_.-]{0,14}$` (лимит ядра IFNAMSIZ=16); плюс строить argv как `[]string`, а не конкатенацией строк.

### 2. [Medium] Подмена бинарника движка через PATH-fallback при discovery
**Категория:** binary planting / insecure search path (CWE-426) · **Файлы:** `core/engine/supervise/binary.go:83-112`, `core/engine/registry/registry.go:69-90`

`Prober.Discover` ищет бинарь в порядке: env-override → `enginesDir` → **`exec.LookPath(pr.Name)` (PATH)**. Если в `enginesDir` бинаря нет (свежая установка, updater ещё не отработал), подхватывается любой `sing-box`/`xray`/`mihomo` из PATH. Аутентификация бинаря — только `Probe()`: запуск с `version` и сверка stdout с regexp. Подделать вывод `version` тривиально для злоумышленника, контролирующего PATH (на десктопе каталоги PATH вроде `~/.local/bin` обычно user-writable). Дальше «движок» запускается с привилегиями сервиса и получает **весь конфиг со всеми credentials подписок через stdin**. `Binary.VerifyDigest` существует (`binary.go:116`), но в пути discovery не вызывается нигде — проверка контрольных сумм осталась на совести updater'а вне core.

**Сценарий:** локальный атакующий (или скомпрометированный пользовательский процесс) кладёт исполняемый `xray`-заглушку в ранний каталог PATH до того, как updater положит настоящий бинарь в `enginesDir` → core выполняет его как сервис → слив всех секретов подписок + произвольный код от сервис-пользователя.

**Фикс:** убрать PATH-fallback (только `enginesDir` + явный env-override оператора) либо требовать `VerifyDigest` перед первым запуском бинаря, найденного вне `enginesDir`.

### 3. [Low] `Outbound.Identifiers()` не маскирует REALITY-идентификаторы вопреки комментарию
**Категория:** incomplete redaction (CWE-532) · **Файлы:** `core/engine/plan.go:65-69`, `core/engine/validate.go:52-65`, `core/engine/redact.go:92`

Комментарий в `plan.go`: «RealityPublicKey and other REALITY parameters are public but masked because they identify a server». Но `Identifiers()` добавляет только `Server`, `host:port`, `TLS.ServerName`, `Name` — `RealityPublicKey`/`RealityShortID`/`SpiderX` нигде не регистрируются в redactor'е (в `Secrets()` их тоже нет — и это корректно, они не credentials). В итоге REALITY-публичный ключ (уникален на сервер, 43 символа base64) светится в логах движков и диагностических архивах, хотя код заявляет обратное. Усугубляется находкой 4: паттерн `keyValuePattern` не знает ключей `publicKey`/`shortId`/`spiderX`.

**Фикс:** добавить три поля в `Identifiers()` и ключи `publickey|shortid|spiderx` в `keyValuePattern`.

### 4. [Low] `userInfoPattern` не покрывает схемы hysteria2/tuic/wireguard
**Категория:** incomplete redaction · **Файл:** `core/engine/redact.go:93`

```go
userInfoPattern = regexp.MustCompile(`(?i)\b(https?|socks5|vless|vmess|trojan|ss)://[^/\s:@]+:[^@\s]+@`)
```
Парсер поддерживает `hysteria2://`, `hy2://`, `tuic://`, `wireguard://`, `wg://` (`parser.go:hasScheme`), и все они могут нести credentials в userinfo (`hysteria2://password@host:port`, `tuic://uuid:pass@host`, `parseWireURL` кладёт userinfo в `Password`). Строка лога с такой ссылкой не будет замаскирована паттерном (точное совпадение через `Secrets()` сработает только если redactor знает план; `maskPatterns` — для неизвестных значений, и тут он молчит).

**Фикс:** расширить альтернативу схем: `hysteria2|hy2|tuic|wireguard|wg`.

### 5. [Low] Метрики Xray на loopback идут через `http.DefaultClient` — уважает `HTTP_PROXY`
**Категория:** unintended egress · **Файл:** `core/engine/xray/engine.go:141-158`

`readVars` делает `http.DefaultClient.Do(req)` к `http://127.0.0.1:PORT/debug/vars`. `http.DefaultTransport` использует `ProxyFromEnvironment`, а спец-кейс «без прокси» в Go действует только для хоста `localhost`, не для `127.0.0.1`. При установленном `HTTP_PROXY` (типично для пользователей VPN в цензурируемых сетях) запрос с внутренними метриками (счётчики трафика, observatory-задержки) уйдёт на прокси, а при отказе прокси handshake готовности будет ложно падать. Остальные клиенты (`clashapi.NewClient`, `timeThrough`) прокси окружения не используют — только это место.

**Фикс:** свой `http.Client{Transport: &http.Transport{DialContext: ...}}` без `Proxy` (или `Proxy: nil` явно) для loopback-метрик.

### 6. [Low] SSRF-сторож `allowPrivate` зависит от DNS-ответа атакующего на исходный хост
**Категория:** SSRF guard bypass (narrow) · **Файл:** `core/subscription/subscription.go:137, 300-341`

`allowPrivate` вычисляется один раз: `isPrivateHost(ctx, target.Hostname())` — через системный DNS по **исходному** хостнейму подписки. Если атакующий контролирует DNS этого имени и в момент проверки вернёт приватный IP, `dialChecked` разрешит dial на любые приватные адреса (редиректы при этом всё равно валидируются, но уже не блокируются по адресу). Практическая эксплуатация узкая: тело ответа уходит в парсер подписки, прямой эксфильтрации нет; но возможен «внутренний GET» (CSRF-подобный) по приватным admin-эндпоинтам. Основная защита (redirect→private при публичном исходном хосте) работает корректно.

**Фикс (defense in depth):** не доверять `allowPrivate=true` для хостов, которые не являются буквально IP-литералами/`.local`/loopback — т.е. сузить до «исходный хост — IP-литерал из приватного диапазона или localhost», а не «так сказал DNS».

### 7. [Low] `StableKey` включает UUID-credential в хэш идентичности
**Категория:** privacy · **Файл:** `core/parser/parser.go:207-222`

Комментарий: «Exclude passwords from identity to avoid storing password hashes». Но `material` включает `o.UUID`, а для VLESS/VMess/TUIC UUID — это и есть credential (пароль). Выход — лишь 64-битный усечённый sha256, необратимый, используется для дедупликации; риск — подтверждение угаданного UUID по совпадению ключа и расхождение с заявленным намерением.

**Фикс:** либо документировать, что UUID входит в identity осознанно, либо строить ключ без UUID (только protocol/host/port/user).

---

## Проверено, проблем нет
- `subscription`: HTTPS-only, запрет userinfo, 5 валидируемых редиректов, `dialChecked` против rebinding, лимиты тела, таймауты — сильных находок нет.
- `parser`: лимиты 16 МиБ/20000 items, валидация UUID/port/host, `Options` с произвольными query-параметрами не пересекают границу в конфиг движка (whitelist в `core/control/plan.go`, вне зоны, но проверен как граница).
- `supervise`: конфиги только через stdin, `SafeEnv`, home 0700, сокет контроллера в owner-only директории (`privateDir` защищён от pre-creation), secret 32 байта CSPRNG на запуск, рестарт-бюджет.
- `bypass`: аргументы tpws из строго валидированной стратегии; bind только на 127.0.0.1.
- `probe`: лимиты, контексты, TLS 1.2+ с верификацией, сокрытие адресов в ошибках (`errs.netDetail`); прямые dial'ы — задокументированный дизайн.
- `xray profile`: рекурсивный `stripFiles` + удаление `profileOwned` закрывают чтение файлов провайдерским конфигом.
- `tunroute`: удаление чужих правил ограничено зарезервированными приоритетами/таблицей/protocol=242 (`ownedRule` консервативен в сторону сохранения).

## ИТОГО: 7 находок (Critical: 0, High: 0, Medium: 2, Low: 5)
