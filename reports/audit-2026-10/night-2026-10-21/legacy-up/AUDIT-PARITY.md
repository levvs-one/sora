# Аудит паритета sora ↔ legacy — ядро, Windows-интеграция, мелочи C#

Дата: 2026-10-20. Read-only аудит, правок кода не вносилось.
Ветка обоих репозиториев: `bugfix/audit-2026-10-19`.
HEAD на момент аудита: sora `2120fcb14954dc34efca5a5a9946463266fe25e3`,
legacy `1c57528af1a6b4fdae2dbc14634c3768976ae845`.
Эталон — sora. Структурные спеки SP3/SP4/SP5/SP6 глубоко не аудировались
(§6 — только состояние точек касания).

---

## 1. Базовая верификация legacy (факты)

### Go (`sora-legacy/core`, `TMPDIR=$HOME/workspace/.build-tmp`, GOCACHE на диске)

| Шаг | Итог |
|---|---|
| `go build ./...` | ✅ чисто |
| `go vet ./...` | ✅ чисто |
| `go test ./...` | ❌ 2 пакета FAIL, 23 пакета `ok`, 4 — без тестов |

Падения:

1. `engine: TestTunAndFakeIPAvoidLANAndEachOther` — **известный env-артефакт**,
   не регрессия: падает и при `TMPDIR=/tmp` одиночным прогоном
   (`tun: fake-IP pool overlaps an existing interface`), совпадает с описанием
   «падает и на чистом дереве».
2. `engine/mihomo: TestRenderRealityForcesAClientFingerprint` — **РЕАЛЬНОЕ
   падение на текущем HEAD, не артефакт** (см. разрыв G1 в §7). Одиночный
   прогон при `TMPDIR=/tmp` воспроизводится:
   `mihomo: outbound srv-1: REALITY public key is not a 32-byte base64url X25519 key`.
3. `TestDetectCensorshipEventsWithoutOffsetsStayUnknown` в legacy **отсутствует
   как тест** — это тест sora (`sora/core/control/censor_test.go:209`), пакета
   `censor` и RPC `DetectCensorship` в legacy нет (поколенческий разрыв, §2.8).
   В legacy-прогоне с длинным TMPDIR падений по этой причине нет.

### C# (`~/workspace/dotnet/dotnet build`, по одному, последовательно)

| Проект | Итог |
|---|---|
| `legacy/Control/Sora.Legacy.Control.csproj` | ✅ 0 warnings / 0 errors |
| `legacy/Client/Sora.Legacy.Client.csproj` | ✅ 0 warnings / 0 errors |
| `legacy/tests/ClientInterop/ClientInterop.csproj` | ✅ 0 warnings / 0 errors |
| `legacy/tests/ControlInterop/ControlInterop.csproj` | ✅ 0 warnings / 0 errors |
| `legacy/tests/ServiceInterop/ServiceInterop.csproj` | ✅ 0 warnings / 0 errors |

Утверждение WAVE-A-TOOLCHAINS.md §2 (0/0 по проектам) на текущем HEAD
**подтверждено** для всех 5 проектов (в WAVE-A §2 явно названы Control и
Client; три interop-теста также зелёны).

---

## 2. Паритет функций ядра по областям

Легенда: **ПАРИТЕТ** — доказано тестом/кодом; **РАЗРЫВ** — отсутствует в legacy;
**НЕПРИМЕНИМО** — стек/поколение.

### 2.1 Parser — ПАРИТЕТ по базам, РАЗРЫВЫ по соседним функциям (§3)

- Схемы ссылок legacy (`parser/parser.go:120`): vless/vmess/trojan/ss/socks/
  socks5/http/https/hysteria2/hy2/tuic/wireguard/wg — паритет с sora.
- Документы: base64-list, plain-list, clash-yaml, sing-box-json, xray-json,
  xray-profile, wireguard-conf, **SIP008** (`sip008` + `remarks` в
  `mapJSONSpec`) — паритет.
- UUID: `uuidRE` принимает версии **1–8** при строгой проверке варианта —
  паритет пинится `TestParserAcceptsNewerUUIDVersions` /
  `TestParserRejectsInvalidUUIDVersions` (S5-SP2). ✅
- Trojan/HY2 пароли (password-only credentials): паритет пинится
  `TestParsePasswordOnlyCredentials` (зеркало sora). ✅
- SIP002 `plugin`/`plugin-opts` парсятся, но движковые гейты отсутствуют (G5).
- РАЗРЫВЫ: VMess alterId (G2), XHTTP `extra=` download settings (G4),
  HY2/TUIC тюнинг ключи (`upmbps`/`downmbps`/`mport` есть в sora-парсере,
  в legacy-списке ключей отсутствуют → молча теряются при импорте) (G6).

### 2.2 Engine: валидаторы — ПАРИТЕТ по портированному, РАЗРЫВЫ по соседям

- Порт отдела стыков (коммит `417dc76`): `engine/reality.go`
  (`ValidateReality`, `isX25519PublicKey`, dest/warnings), `validateXHTTP`
  в `validate.go:229`, ECH-honesty правила (`validate.go:482+`),
  `validateAmneziaWG`, whitelist XHTTP-режимов «Same set as sora».
  Пин-тест: `validate_test.go:122` — общий с sora набор векторов
  («S5 seams probe ran against both repos»). ✅ Пакет `engine` по этим тестам
  зелён (падает только env-артефакт TUN, §1).
- РАЗРЫВЫ в том же `validate.go` sora, которых в legacy нет:
  `validateChains` (цепочек в legacy Plan нет вообще), `validateHopPorts`,
  `validateHysteria2Tuning`, `validateTUICTuning`, `validateTransportFields`,
  `validateVMessTrojan`, AWG-подвалидаторы sora (`validateAWGCPS/Domain/
  Masquerade`, `decodeAWGKey`, `parseAWGRangeU16` — в legacy AWG валидация
  есть, но одним `validateAmneziaWG` без CPS/domain/masquerade-разветвлений),
  `validateDesync`. Часть — следствие отсутствующих полей Plan (G6),
  часть — самостоятельные проверки (G2/G6).

### 2.3 Engine: редакторы (redact.go) — ЧАСТИЧНЫЙ ПАРИТЕТ, РАЗРЫВ ПО SEED

- Паттерн-маскировка: паритет **пинится и зелён** —
  `TestRedactorParityKeySpellings` (M1: набор ключей «byte-for-byte with
  sora», включая quoted-формы), `TestRedactorQuotedPhrasesMaskedWhole`,
  composite/Bearer/Basic — в пакете `engine`, тесты проходят.
- РАЗРЫВ (G3): sora `Redactor.Add` расширяет каждый seed производными
  формами (`derivedForms`, `redact.go:100-137`: percent-encoding в обоих
  регистрах hex, base64 std/url ±padding, hex, JSON-escaping). Legacy
  `Add` (`redact.go:28`) регистрирует **только точные значения** —
  секрет, встретившийся в логе в перекодированном виде, seed-путь legacy
  не замаскирует (спасают только паттерны для известных ключей).

### 2.4 Движки и supervise — ПАРИТЕТ

- Digest-гейты legacy (`engine/supervise/binary.go`): отсутствующий/
  битый `SHA256SUMS` → fail-closed (`Discover` возвращает ошибку),
  несовпадение digest → отказ, `VerifyDigest` — паритет по поведению
  с sora (у sora внутренняя структура богаче: `VerifyNamedInDir`,
  `checkDigestPath`, env-путь; публичное поведение совпадает).
- Opt-out: `--allow-unverified-engines` (`cmd/sora-core/cli.go:155` →
  `registry.go:82` → `Prober.AllowUnverified`) — явный флаг, по умолчанию
  выключен, паритет с sora-подходом. ✅
- Реестр движков, interop, singbox/xray/mihomo рендеры присутствуют;
  mihomo REALITY-fingerprint фикс (`af8d343`) на месте — но его тест сломан
  портом валидатора (G1).

### 2.5 Guard / kill switch — БАЗОВЫЙ ПАРИТЕТ, РАЗРЫВ ПО РЕЖИМАМ

- Legacy: `guard.Guard.Apply/Restore`, Windows firewall
  (`firewall_windows.go`), nftables (`nftables*.go`, golden-тесты), 
  `session.SetKillSwitch` применяется немедленно. Базовый сценарий паритетен.
- РАЗРЫВ: у sora есть `guard/mode.go` (ModeStandard/Strict/Off + маркер
  strict-намерения, переживающий крэш), `HoldBlock`/`Blocked`
  (удержание блока на время переключения сервера), ingress-бэкенд
  (`guard/ingress*.go`). В legacy ничего из этого нет: strict-режима нет,
  удержания блока при смене сервера нет (в legacy смена сервера — полный
  Connect, RPC `SelectServer` отсутствует поколенчески, §2.8). Strict
  kill switch в самой sora — скрытая функция под решением владельца,
  поэтому разрыв классифицирован как спека владельцу (G10).

### 2.6 Обновления — НЕПРИМЕНИМО к core / разрыв на уровне продукта

- В Go-core обоих репозиториев самообновления нет: обновления — слой
  приложения (sora: `app/lib/src/updates.dart`, staged rollout +
  minisign-верификация + opt-out `setChecking`). Legacy-аналога
  (ни в новом Client, ни отдельным сервисом) не существует; v2rayN-часть
  содержит только автообновление **подписок** (не приложения).
  Классификация: продуктовый разрыв поколения, решение владельца (G11).

### 2.7 Diagnostics — РАЗРЫВ

- Legacy: коллектор отчёта (env/интерфейсы/Windows events/packet capture,
  `diagnostics.go`, `report.go`, маскировка `mask`) — своя сильная часть.
- Отсутствует весь sora-набор сетевой диагностики: `CheckDnsLeaks`
  (DNS-leak/spoof/intercept, `diagnostics/dnsleak.go`, `dnsspoof.go`,
  `dnsintercept.go`, `dnsprobe.go`), JA4 (`diagnostics/ja4.go`),
  классификация троттлинга (`throttle.go`). RPC `RunDiagnostics`/
  `ExportDiagnostics` в legacy есть, но проверяют меньше (G7).

### 2.8 Control / RPC — ПОКОЛЕНЧЕСКИЙ РАЗРЫВ, ДОКУМЕНТИРОВАН КОСВЕННО

- Proto: sora 43 RPC, legacy 30 RPC. Отсутствуют ровно 13:
  `SelectServer`, `CheckDnsLeaks`, `BenchmarkServers`, `GetBenchmarks`,
  `SaveSubscriptionOverride`, `GetSubscriptionOverride`, `ListProfiles`,
  `SaveProfile`, `DeleteProfile`, `GetNetworkFingerprint`, `ProbeChain`,
  `GetDeviceIdentity`, `SetDeviceIdentity` (все — Since 1.8+ у sora;
  legacy ведёт переговоры на ApiVersion 1.7, `Control/CoreConnection.cs:43`).
- Проверка обещаний: поиском по `docs/`, `README.md`, `CHANGELOG.md`
  legacy ни один из отсутствующих RPC/фич не обещается. ✅ Ложных
  обещаний нет; разрыв — документированное генерационное расхождение.

### 2.9 Subscription — ПАРИТЕТ ПО ФЕТЧУ, РАЗРЫВ ПО СЛОЯМ

- Фетч legacy (`subscription/subscription.go`): SSRF-защита
  (`checkedDialer`/`checkDial`, запрет приватных адресов), валидация и лимит
  редиректов (5), лимиты тела, `subscription-info` заголовки (`info.go`),
  User-Agent правила — паритет с базой sora, тесты зелёны. ✅
- РАЗРЫВЫ (все — sora-фичи круга 2): override-слой
  (`subscription/override.go`: Load/Save/Delete), fallback-URL
  (`fallback.go`: Split/JoinFallback), HWID-идентичность устройства
  (`device.go`/`device_store.go`: GenerateHWID/ValidHWID/Headers),
  happRouting провайдер-роутинг (`happrouting.go`) (G8).

### 2.10 Routing — ПАРИТЕТ ✅

Функциональный состав `routing/` совпал полностью (4/4 функций,
пресеты + тесты зелёны).

### 2.11 Obfs — ЧАСТИЧНЫЙ ПАРИТЕТ

- Legacy: свой набор — `Profile.Validate/Clamp`, fragmentation
  (`fragment.go`: `WrapConn`, разрезание первой записи), uTLS
  (`utls.go`), `Dialer.DialTLS`. Тесты зелёны.
- РАЗРЫВ: у sora — record-aware разрезание ClientHello
  (`SplitClientHello`/`parseTLSRecords`), **перезапись SNI**
  (`RewriteClientHelloSNI`, `obfs/sni.go`), jitter (`jitter.go`),
  conn-обёртка с детектом ClientHello, proto-конверсия профиля
  (`ProfileFromProto` — связно с отсутствием obfs-RPC в legacy proto).
  В legacy SNI-rewrite и jitter отсутствуют как классы (G9).

### 2.12 Прочее ядро (вне обязательного списка, одной строкой)

`secret/` — паритет (у legacy экспортированный `WriteFileAtomic`).
`logs/` — у sora есть JSON-экспорт (`logs/export.go`: jsonRows/writeTextEntry),
у legacy экспорт только текстовый — мелкий разрыв, желательно.
`probe/` — legacy минимален (только базовый probe + собственная защита
от приватных целей), sora-набор (bandwidth/quality/QUIC/REALITY-dest/
ban-tracker) отсутствует поколенчески. `session/` — у sora добавлены
stall-watchdog, dead-mode, rehandshake, censorship-hook; у legacy их нет
(связано с отсутствием censor-подсистемы).

---

## 3. Полнота портов отдела стыков (проверка «соседей»)

Портировано и пинится тестами: SIP008 ✅, trojan/hy2 пароли ✅,
REALITY/XHTTP валидация ✅ (векторы общие с sora), редакторы-паттерны ✅,
UUID 1–8 ✅.

Непортированные соседи **в тех же файлах** sora:

| # | Сосед | Файл sora | Что в legacy |
|---|---|---|---|
| 1 | `checkVMessAlterID` (+ вызовы из JSON-путей) | `core/parser/parser.go:687,766` | `mapJSONSpec` (`parser.go:611`) aid игнорирует, значение уходит в `Options` — G2 |
| 2 | `applyExtraDownloadSettings` (`extra=` XHTTP) | `core/parser/parser.go:510` | Поля в `engine.Transport` отсутствуют (признано комментарием `validate.go:225`) — G4 |
| 3 | `mapVMessJSON`/`vmessBlob` специализация | `core/parser/parser.go:571,640` | Общий `mapJSONSpec` на все JSON-форматы: работает, но без VMess-специфичных проверок (см. п.1) |
| 4 | `derivedForms`/`lowerPercentHex` редактора | `core/engine/redact.go:100` | `Add` без производных форм — G3 |
| 5 | Фикстура REALITY-ключа в mihomo-тесте | `core/engine/mihomo/render_test.go:611` (валидный 43-симв. ключ) | Устаревший 35-симв. ключ `QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVo` — G1 |

---

## 4. Адаптивная интеграция с ОС (Windows)

Объекты: новый клиент `legacy/Client` (по `legacy/README.md:5` — будущий
продуктовый интерфейс, **в поставку пока не собирается**), поставляемый exe —
v2rayN-проект (`legacy/build/Build-WindowsProfiles.ps1`: цели win7/win8/
win10/win11, runtime win7-x86, `AssemblyName=sora_<target>`),
инсталлятор `legacy/installer/Sora.iss`. Сданное отделом WAVE-OS
(`c955461` autostart read-back, `a58894c` uninstall Run) не дублируется.

### Что адаптивно и хорошо (ОК)

- **Инсталлятор — проверки возможностей, а не предположения:**
  KB3033929 ставится только на Win7 (`IsWindows7`: Major=6/Minor=1) и только
  x86; .NET 4.8 проверяется по `Release >= 528040` в обеих вьюхах реестра
  (HKLM32/HKLM64); оба бандл-инсталлятора сверяются по SHA-256, mismatch —
  fail-closed с понятным русским сообщением; `MinVersion` параметризован
  под цель (`6.1sp1` для win7). Ошибки пользователю — человеческим текстом
  («Проверка целостности … не пройдена»), хотя коды присутствуют
  («завершилась с кодом %d» — приемлемый компромисс, не сырой стектрейс).
- **v2rayN:** single-instance с поднятием окна первой копии (реестровый
  hwnd), `--restore-proxy` без `--silent` требует явного подтверждения
  (LEGACY-L11), DPI-aware включается проверкой `OSVersion.Major >= 6`.
- **Деинсталляция (поставляемый exe):** `[UninstallRun] --restore-proxy
  --silent`, `[UninstallDelete]` (guiNConfig/statistics/guiLogs/guiTemps/
  guiBackups/guiConfigs), `RemoveOrphanedAutoRun` (a58894c), ярлык
  `{userstartup}` Inno снимает сам. Хвостов у v2rayN-поставки не найдено.

### Остаточные разрывы

- **W1. Контракт инсталлятор ↔ новый Client не сходится.** `Client/
  Program.cs`: `Main()` **без аргументов** — `--silent`, `--restore-proxy`,
  `--wait-for`, `sora://…` игнорируются полностью; нет single-instance
  mutex; нет автозапуска в настройках. Пока в stage v2rayN-exe — контракт
  цел; в момент переключения stage на Client: задача `autorun`
  (`{userstartup}` с `--silent`) будет открывать полное окно при входе,
  а `[UninstallRun]` запустит GUI и будет ждать его закрытия
  (`waituntilterminated`). Чинить **до** смены поставляемого exe.
- **W2. Трей поставляемого клиента не показывает состояние подключения.**
  Иконка (`MainFormHandler.GetNotifyIcon`) выбирается по `sysProxyType` и
  цвету маршрутизации — состояния подключено/подключение/ошибка визуально
  **неразличимы**; tooltip (`MainForm.cs:1203`) — последняя строка лога,
  обрезанная на 63 символа, а не подпись состояния; balloon/toast-
  уведомлений в коде нет вообще — в трей-режиме ошибки молчаливы.
  У нового Client трея **нет как класса** (ни NotifyIcon, ни сворачивания).
- **W3. Протокол `sora://` не существует в продукте legacy.** В `Sora.iss`
  нет регистрации URL-протокола; ни v2rayN (`Program.cs` обрабатывает
  только --silent/--tun/--wait-for/--restore-proxy), ни новый Client
  аргумент-ссылку не принимают. Документация legacy этого и не обещает;
  импорт — только вручную/из буфера (в v2rayN буферный импорт есть).
  Для поколения, чья sora-сестра чинила потерю sora:// ссылок (H8),
  это осознанный продуктовый разрыв — решением владельца.
- **W4. DPI-адаптация неполная.** v2rayN: только system-DPI-aware
  (`SetProcessDPIAware`), PerMonitorV2 на Win10/11 не используется —
  перенос окна между мониторами с разным масштабом даст мыло.
  Новый Client: вызова DPI-aware и манифеста нет вообще (`csproj` без
  `ApplicationManifest`, `Program.cs` без `SetProcessDPIAware`) —
  процесс DPI-unaware, виртуализация растянет интерфейс при 125–200%,
  несмотря на `AutoScaleMode.Dpi` у MainForm.
- **W5. Имя exe.** Client собирается как `Sora.Legacy.exe`, инсталлятор и
  build-скрипты оперируют `sora_<target>.exe` от v2rayN — ещё один маркер
  незавершённого переключения поставки (связано с W1).

---

## 5. Чек-лист мелочей C#-клиента и Windows-интеграции

Объекты: новый Client (C) и поставляемый v2rayN (V) раздельно, где важно.

| # | Пункт | Вердикт | Доказательство / деталь |
|---|---|---|---|
| 1 | Порядок табуляции и начальный фокус | **РАЗРЫВ (minor)** | Явных `TabIndex` нет нигде: grep по `legacy/Client/*.cs` — 0, по Designer-файлам v2rayN — 0; порядок = порядок создания контролов, отдельно не проектировался. Диалоги Client: AddSubscription — ввод первым, `AcceptButton=confirm` (Enter = отправить, для этого диалога уместно); Modes — первый контрол радиокнопка TUN (безопасно). **Но** удаление подписки: `MessageBox.Show(..., OKCancel)` (`MainForm.cs:461`) — фокус по умолчанию на **OK**, т.е. Enter подтверждает деструктивное действие |
| 2 | Мнемоники (Alt-…) | **РАЗРЫВ (minor)** | Символа `&` нет ни в текстах Client (код + ARB), ни в `Resx/SoraUI.resx` v2rayN — Alt-навигации нет как функции; дублей, соответственно, тоже нет |
| 3 | Выравнивание / сетка | **ОК (Client) / неприменимо-частично (V)** | Client строится на FlowLayoutPanel + единых отступах (Padding 24/36, Margin 8, высоты 44), SubscriptionCard считает высоту по измеренному тексту; фиксированная геометрия — только диалог AddSubscription (координаты вручную: input 20,20; кнопка 320,88) — единичное место. У v2rayN — штатный designer-набор v2rayN, в рамках аудита не переизмерялся |
| 4 | Тексты ошибок / глоссарий | **ОК с оговоркой** | Client: все ошибки пользователю — только ключи `err*` из ARB через `Strings.Error()` (маппинг core-ключей, `Strings.cs:40`); сырьё (`exception.Message`) наружу не выходит — в UI попадает `text.Error(key)` либо `errGeneric`, стектрейсов нет. v2rayN: `ex.Message` уходит только в лог, пользователю — человеческие `UI.ShowWarning`. Глоссарий: ARB Client — подмножество ARB sora (280 из 711 ключей), значения общих ключей совпадают **все, кроме одного** (`modesGuide`); термины «подписка/сервер/подключение» едины. Оговорка: подмножество никто не пинит — дрейф ловится только вручную |
| 5 | Иконка трея: состояния | **РАЗРЫВ** | См. W2: состояния не кодируются ни иконкой, ни подписью; tooltip — строка лога ≤63 симв. У Client трея нет |
| 6 | Длинные имена / пути | **ОК (Client) / частично (V)** | Client: имена серверов — `TextFormatFlags.EndEllipsis` + полный ToolTip в списке (`SubscriptionCard.cs:142,113`), описание карточки — измеренная высота с WordBreak, LogsPage — `AutoEllipsis` + EndEllipsis, ошибка в MainForm — `MaximumSize(460,0)` с переносом. Критичный конец пути нигде не отрезается молча: полей путей в Client нет. v2rayN: tooltip трея режет конец строки лога (см. п.5) |
| 7 | DPI 100–200% | **РАЗРЫВ** | См. W4: Client — нет манифеста/вызова aware, диалоги Client не задают `AutoScaleMode` (только MainForm: `Dpi`), размеры шрифтов заданы в пикселях (13/15/22 px) — при виртуализации терпимо, но размыто; v2rayN — system-aware + `AutoScaleMode.Font` у главной формы, PerMonitor нет |
| 8 | Консистентность имён / комментариев | **РАЗРЫВ (minor)** | Go-сторона: комментарии прямо ссылаются на паритет с sora и спеки — рассинхрона не найдено. C#: в v2rayN остались upstream-комментарии на китайском (напр. `/// 托盘信息` у notifyMsg) рядом с русскими LEGACY-пометками; Client: `AssemblyName=Sora.Legacy` против продуктового `sora_<target>.exe` (W5); термин «Ядро» для engine в ARB (`engine = Ядро`) при «core/служба» в ошибках (`errCore = Служба Sora не отвечает`) — пользователь видит два имени одного компонента |

---

## 6. Структурные спеки SP3/SP4/SP5/SP6 — точки касания (без глубокого аудита)

- **SP3 (SIP002 ss_plugin):** по независимому ревью
  (`reports/legacy-up/REVIEW-SP3.md`, коммит `428ace4`) портирован полностью,
  принят с замечаниями; остаток — каталог/гейты sora `ss_plugin`
  (follow-up **SP3b**) — в настоящем аудите подтверждается: функций
  `SSPluginByName/SSPluginNames/SupportsSSPlugin/validateShadowsocksPlugin`
  в legacy нет (G5).
- **SP2 (UUID 1–8):** закрыт, пинится тестами (§2.1).
- **SP4/SP5/SP6:** в коде legacy точек касания с явными маркерами не найдено;
  смежные зоны (XHTTP-поля Transport — комментарий `validate.go:225`
  ссылается на «S5 report») остаются структурным разрывом G4. Глубокая
  проверка — у профильных отделов.

---

## 7. Сводная таблица разрывов с приоритетами

Приоритеты: **ОБЯЗАТЕЛЬНО** — чинить в этом подъёме legacy;
**ЖЕЛАТЕЛЬНО** — чинить при возможности / отдельной спекой отдела;
**ВЛАДЕЛЕЦ** — оставить спекой/решением владельцу.

| ID | Разрыв | Приоритет | Эталон sora | Затронуто в legacy |
|---|---|---|---|---|
| G1 | Тест-набор legacy красный: фикстура `TestRenderRealityForcesAClientFingerprint` использует невалидный REALITY-ключ (35 симв. вместо 32-байт base64url) после порта валидатора `417dc76` | **ОБЯЗАТЕЛЬНО** (дёшево: заменить ключ на валидный, как в sora) | `core/engine/mihomo/render_test.go:611` | `core/engine/mihomo/render_test.go:340` |
| G2 | VMess с ненулевым alterId (pre-AEAD) молча принимается при импорте JSON/документов | **ОБЯЗАТЕЛЬНО** (безопасность, малый порт) | `core/parser/parser.go:687` (`checkVMessAlterID`) | `core/parser/parser.go:611` (`mapJSONSpec`) |
| G3 | Редактор: seed-секреты не маскируются в перекодированных формах (percent/base64/hex/JSON-escape) | **ОБЯЗАТЕЛЬНО** (безопасность логов, порт ~1 функции + тесты) | `core/engine/redact.go:100` (`derivedForms`) | `core/engine/redact.go:28` (`Add`) |
| G4 | XHTTP `extra=` (downloadSettings/xmux/xPadding) теряется: нет полей в Transport, нет парсинга | ЖЕЛАТЕЛЬНО (структурно, тянет рендеры всех движков) | `core/parser/parser.go:510`, `core/engine/validate.go` (`validateXHTTP` полная версия) | `core/parser/parser.go`, `core/engine/plan.go` (Transport), `core/engine/validate.go:225` |
| G5 | SIP002 ss_plugin: парсер принимает, движкового каталога и fail-closed гейтов в рендерах нет — плагин может молча потеряться (SP3b) | ЖЕЛАТЕЛЬНО (спека уже заведена ревью SP3) | `core/engine/ss_plugin.go`, `core/engine/ss_support.go` | `core/engine/` (catalog/registry/рендеры singbox, xray, mihomo) |
| G6 | HY2/TUIC тюнинг теряется при импорте: hop-ports (`mport`), `upmbps/downmbps`, congestion/heartbeat — нет ключей парсера, полей Plan и валидаторов | ЖЕЛАТЕЛЬНО | `core/parser/parser.go` (ключи), `core/engine/quic_defaults.go`, `validate.go` (`validateHopPorts/Hysteria2Tuning/TUICTuning`) | `core/parser/parser.go`, `core/engine/plan.go`, `core/engine/validate.go` |
| G7 | Diagnostics: нет DNS-leak/spoof/intercept, JA4, throttle-классификации | ЖЕЛАТЕЛЬНО | `core/diagnostics/dnsleak.go`, `dnsspoof.go`, `dnsintercept.go`, `ja4.go`, `throttle.go` | `core/diagnostics/` |
| G8 | Subscription: нет override-слоя, fallback-URL, HWID, happRouting | ЖЕЛАТЕЛЬНО (override/fallback) / **ВЛАДЕЛЕЦ** (HWID, happRouting — провайдерские фичи) | `core/subscription/override.go`, `fallback.go`, `device.go`, `happrouting.go` | `core/subscription/` (+ proto RPC §2.8) |
| G9 | Obfs: нет SNI-rewrite, jitter, record-aware ClientHello split | ЖЕЛАТЕЛЬНО | `core/obfs/sni.go`, `jitter.go`, `frag.go`, `conn.go` | `core/obfs/` |
| G10 | Guard: нет strict-режима с маркером и HoldBlock при смене сервера | **ВЛАДЕЛЕЦ** (в sora strict скрыт за его решением) | `core/guard/mode.go`, `guard.go` (`HoldBlock`) | `core/guard/`, `core/session/` |
| G11 | Самообновление приложения (staged/minisign/opt-out) отсутствует как слой продукта | **ВЛАДЕЛЕЦ** | `app/lib/src/updates.dart` (sora) | весь legacy-продукт |
| G12 | Proto отстаёт на 13 RPC (SelectServer, CheckDnsLeaks, Benchmark*, Override, Profiles, ProbeChain, DeviceIdentity) | **ВЛАДЕЛЕЦ** (поколенческое расхождение; документация legacy не обещает — проверено) | `proto/sora/core/v1/core_control.proto` (43 RPC) | `proto/…` legacy (30 RPC), `core/control/`, `core/legacycontrol/` |
| W1 | Новый Client игнорирует CLI-контракт инсталлятора (`--silent`, `--restore-proxy`), нет mutex и автозапуска | **ОБЯЗАТЕЛЬНО до смены stage** на Client; пока stage=v2rayN — ЖЕЛАТЕЛЬНО | — (контракт задан `legacy/installer/Sora.iss` + v2rayN `Program.cs`) | `legacy/Client/Program.cs`, `legacy/Client/MainForm.cs` |
| W2 | Трей: состояния подключения неразличимы, tooltip — обрезанная строка лога, уведомлений нет; у Client трея нет | ЖЕЛАТЕЛЬНО (для поставляемого v2rayN), у Client — частью W1-задачи | — | `legacy/v2rayN/v2rayN/Handler/MainFormHandler.cs`, `Forms/MainForm.cs:1203`; `legacy/Client/` |
| W3 | `sora://` не зарегистрирован и не обрабатывается нигде в legacy-продукте | **ВЛАДЕЛЕЦ** (документация не обещает; есть буферный импорт) | sora: H8-фикс deeplink | `legacy/installer/Sora.iss`, оба клиента |
| W4 | DPI: Client — нет aware-манифеста/вызова; v2rayN — только system-aware, без PerMonitorV2 | ЖЕЛАТЕЛЬНО | — | `legacy/Client/Program.cs`, `Sora.Legacy.Client.csproj`; `legacy/v2rayN/v2rayN/Program.cs:34` |
| D1 | Удаление подписки подтверждается MessageBox с фокусом на OK (Enter = удалить) | ЖЕЛАТЕЛЬНО (minor, одна строка — DefaultButton на Cancel) | — | `legacy/Client/MainForm.cs:461` |
| D2 | Нет TabIndex-проектирования и мнемоник ни в Client, ни в v2rayN-формах | ЖЕЛАТЕЛЬНО (minor, доступность) | — | `legacy/Client/*.cs`, `legacy/v2rayN/v2rayN/Forms/*.Designer.cs`, `Resx/SoraUI.resx` |
| D3 | ARB-подмножество Client не запинено от дрейфа с sora (сейчас: 1 расхождение `modesGuide` из 274 общих ключей) | ЖЕЛАТЕЛЬНО (добавить сверку в тесты) | `app/lib/l10n/*.arb` (sora) | `legacy/Client/Assets/l10n/*.arb` |

---

## 8. Итог одной строкой

База legacy здорова (Go build/vet чисты, C# 5/5 по 0/0 подтверждено),
порты отдела стыков в основном полны и запинены, но подъёму обязательно
закрыть три вещи: красную фикстуру mihomo-теста (G1), молчаливый приём
VMess alterId (G2) и дыру редактора по перекодированным секретам (G3);
всё остальное — планомерные разрывы поколения (proto/диагностика/подписные
слои) и остаток Windows-интеграции, критичный только при смене
поставляемого exe на новый Client (W1).
