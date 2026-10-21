# Legacy-пины движка sing-box для Apple-тиров (факты и измерения)

Дата измерений: **2026-10-21**. Подотдел legacy-пина движка, департамент
устаревших систем sora (Apple-клиенты). Статус: **измерено на этой машине**,
где не оговорено иное; неподтверждённое помечено «не подтверждено».
Вход: `apple/docs/ARCHITECTURE.md` §1.2/§1.6/§2.4 (условие запуска
legacy-работ: старый libbox проходит `sing-box check` на общем корпусе
конфигов sora и не несёт известных критических CVE ветки), основной пин
продукта — sing-box-lx **1.14.3-lx.22** (`packaging/engines/engines.lock`).

Все загрузки — `~/workspace/.legacy-engines/` (исходники — `src-*.tar.gz`,
распаковки — `x/`, бинари — `bins/`, зонды — `probes/`, журналы прогонов —
`checklogs/matrix.txt`, `checklogs/probes*.txt`, `checklogs/corpus111.txt`).
Дайджесты — измерены `sha256sum` по фактически скачанным файлам (§7).

---

## 1. Решения по тирам

| Тир (ARCHITECTURE §1.6) | Пин | Тип поставки |
|---|---|---|
| iOS 13–14 / macOS 11–12 (legacy, полный TUN) | **Leadaxe/sing-box-lx `v1.13.13-lx.15`** (форк, база upstream 1.13.13) | libbox собирается из исходников пина нами (релиз форка xcframework не публикует, §2.3) |
| macOS 10.15 (legacy, ограниченный режим: системный прокси, `mixed`-inbound libbox на loopback, без TUN) | **SagerNet/sing-box `v1.11.15`** (апстрим; lx-тегов линии 1.11 у форка нет, §2.1) | то же, отдельный третий пин со своей урезанной матрицей (§5.3) |
| Резервный кандидат тира 1 (если координатор выберет единство ветки с прецедентом sora-legacy, §3) | SagerNet/sing-box `v1.12.25` | гейты: AWG, XHTTP, ECH `query_server_name`, naive в libbox (§5.2) |

Почему не один пин на всё: ни одна ветка новее 1.11 не достигает macOS 10.15
своим пиннутым Go-тулчейном (§2.2), а ветка 1.11 не проходит основной корпус
без трансляции DNS и теряет AnyTLS/XHTTP/AWG (§5). Это развилка дизайна
ARCHITECTURE §2 для 10.15 («третий, более старый пин только для 10.15-тира»).

**Эскалация (не молчаливое принятие):** условие ARCHITECTURE «нет известных
критических CVE ветки» формально **не выполняет ни один кандидат** — из-за
транзитивной зависимости `google.golang.org/grpc` (§6). По применимости
прекондиции критического advisory в sing-box не выполняются; решение —
за координатором/владельцем, варианты — в §6.3.

---

## 2. Кандидаты и полы libbox

### 2.1. Что существует (git ls-remote, 2026-10-21)

- Апстрим SagerNet/sing-box, последние стабильные теги веток:
  1.9 → `v1.9.7`, 1.10 → `v1.10.7`, 1.11 → `v1.11.15`, 1.12 → `v1.12.25`,
  1.13 → `v1.13.21`.
- Форк Leadaxe/sing-box-lx зеркалит апстрим-теги (те же SHA), а собственные
  `-lx.*` релизы имеет **только на линиях 1.13.13 и 1.14.x**. Линий
  1.11-lx / 1.12-lx не существует. Последний тег legacy-линии форка —
  `v1.13.13-lx.15`; основной линии — `v1.14.3-lx.22` (текущий пин продукта).

### 2.2. Полы: build_libbox + gomobile + Go (по исходникам тегов)

Ключевой факт: **явные `-iosversion`/`-macosversion` передаёт только
lx 1.14.3-lx.22** (`-iosversion=15.0`, `-macosversion=13.0` —
`cmd/internal/build_libbox/main.go` в дереве lx.22). Все кандидаты ниже
флагов **не передают вообще** — пол задают дефолты gomobile и рантайм-пол Go.

Дефолты gomobile (исходники sagernet/gomobile, `cmd/gomobile/build.go`,
`StringVar` для `iosversion`/`macosversion`) **одинаковы во всех трёх
версиях**: iOS **13.0**, macOS **10.15** (v0.1.4, v0.1.8, v0.1.12 — вычитано
поимённо в каждом дереве).

Рантайм-полы Go по релиз-нотам go.dev (Ports): Go 1.20 — «последний релиз
для macOS 10.13/10.14», сам работает с 10.13; Go 1.23 — «requires macOS 11
Big Sur or later»; Go 1.24 — «последний релиз для macOS 11», Go 1.25 требует
macOS 12. Отдельный iOS-пол Go не публикует: iOS-пол сборки задаётся
`-iosversion` gomobile.

| Кандидат | `go` в go.mod | gomobile | Флаги в build_libbox | Эффективный пол iOS | Эффективный пол macOS |
|---|---|---|---|---|---|
| upstream v1.9.7 | 1.20 | v0.1.4 | нет | 13.0 (дефолт gomobile) | 10.15 достижим (флаг 10.15 ≥ рантайм-пола 10.13) |
| upstream v1.10.7 | 1.20 | v0.1.4 | нет | 13.0 | 10.15 достижим |
| upstream v1.11.15 | 1.20 | v0.1.4 | нет | 13.0 | **10.15 достижим** |
| upstream v1.12.25 | 1.23.1 | v0.1.8 | нет | 13.0 | **11** (рантайм Go 1.23 перекрывает флаг 10.15) |
| upstream v1.13.21 | 1.24.7 | v0.1.12 | нет | 13.0 | **11** (Go 1.24) |
| lx v1.13.13-lx.15 | 1.24.7 | v0.1.12 | нет | 13.0 | **11** (Go 1.24) |
| (справка) lx v1.14.3-lx.22 | 1.25.5 | v0.1.12 | **15.0 / 13.0 явно** | 15.0 | 13.0 |

Выводы:

1. Тир iOS 13–14 / macOS 11–12 по полам достижим ветками 1.11, 1.12 и 1.13
   одинаково; полы кандидатов **не различают** — различают корпус и фичи (§4–5).
2. macOS 10.15 достижима **только** ветками на Go 1.20 (1.9/1.10/1.11).
   Новейшая из них — 1.11 (`v1.11.15`); причин предпочесть 1.9/1.10 нет
   (бинарь 1.10.7 на корпусе падает идентично 1.11.15, §5.1).
3. Альтернатива «собрать ветку 1.12/1.13 старым Go с `-macosversion=10.15`»
   **заблокирована не флагом, а go.mod**: ветки требуют Go 1.23.1 / 1.24.7,
   рантайм которых на 10.15 не работает. Честная формулировка для дизайна:
   не «проверить на Mac», а «невозможно без патча тулчейн-требований ветки»;
   собираемость любого legacy-libbox на Mac при этом остаётся обязательной
   проверкой на машине сборки — **здесь не верифицируется** (нет Xcode).

### 2.3. Поставка libbox

Релиз `v1.13.13-lx.15` (GitHub API, 2026-06-22) публикует только Android
AAR (`libbox-*.aar`) и десктопные архивы; **Libbox.xcframework в активах
нет** — как и у основного пина. Legacy-libbox собирается из исходников
пина нашим `build_libbox` (gomobile v0.1.12) — тот же путь, что ARCHITECTURE
§2.4 предписывает основному таргету.

---

## 3. Прецедент sora-legacy (сверка по запросу подотдела аудита полов)

Факт (первоисточники репозитория sora-legacy, вычитано 2026-10-21):

- `sora-legacy/legacy/THIRD-PARTY-NOTICES.md`, строка 8: **sing-box 1.12.12,
  legacy win7-386**, апстрим SagerNet, релиз `v1.12.12`
  (рядом: Xray-core 25.9.11 win7-32, tun2proxy — строка 7 того же файла).
- `sora-legacy/legacy/build/Stage-Release.ps1`: `WindowsTarget='win7'`,
  sing-box берётся как `tun\sing-box.exe` из CompatPayload и стейджится
  рядом с `xray.exe` и tun2proxy.
- Апстрим со своей стороны тоже маркирует линию 1.12 как legacy для Apple:
  у релиза `v1.12.12` есть актив `sing-box-1.12.12-darwin-amd64-legacy-macos-11.tar.gz`
  (и `windows-*-legacy-windows-7`) — проверено GitHub API 2026-10-21.

**Совпадает ли выбор: по ветке — нет, по полам — да.**

- Прецедент — ветка **1.12 апстрима**; мой выбор для iOS 13–14/macOS 11–12 —
  ветка **1.13.13 форка lx**. Расхождение сознательное и объясняется не
  полами: полы ветки 1.12 для Apple измерены в §2.2 (iOS 13.0 флагом,
  macOS 11 рантаймом Go 1.23.1) — тир она **достигает**, как и прецедент
  достигает своего Windows 7 (там связка другая: готовый legacy-windows-7
  бинарь апстрима, а не libbox).
- Различает кандидатов корпус sora: 1.12.25 теряет AmneziaWG и XHTTP —
  фичи основного продукта — а lx.15 проходит корпус 12/12 без правок (§5.1).
  Плюс у 1.12 нет ECH `query_server_name` и naive в стоковых libbox-тегах.
- Если координатор сочтёт единство ветки с sora-legacy важнее паритета
  фич, резервный кандидат — `v1.12.25` (не 1.12.12: внутри ветки берётся
  последний патч) с гейтами §5.2. По CVE ветка 1.12 **не лучше** (§6:
  grpc v1.73.0 — те же 5 advisory, что у остальных).

---

## 4. Дельты схемы конфига: кандидаты vs 1.14

Источники по пунктам: исходники тега (`option/*.go`, `protocol/`,
`transport/`, `cmd/internal/build_libbox/main.go`), `docs/changelog.md`
дерева 1.13.21 (полная история веток) и эмпирические зонды `sing-box check`
(§5.2). «lx.15» = v1.13.13-lx.15, «гл. пин» = lx 1.14.3-lx.22.

| # | Пункт | v1.11.15 | v1.12.25 | upstream v1.13.21 | lx.15 | Главный пин 1.14-lx.22 |
|---|---|---|---|---|---|---|
| 1 | DNS-серверы | **Старый формат** (`address`-строки, `dns.fakeip`-блок); новый `type:`-формат отвергается (`unknown field "path"`) | Новый формат (changelog 1.12.0: «Refactor DNS servers»); legacy-формат принимается с WARN | Новый; legacy fakeip уже ERROR | Новый; legacy fakeip ERROR | Новый; legacy удалён (FATAL) |
| 2 | `route.default_domain_resolver` | нет (зонд: поле снимается трансляцией) | есть (`option/route.go`) | есть | есть | есть |
| 3 | Route actions (`sniff`/`hijack-dns`/`route`) | есть (переведённый корпус проходит, §5.3) | есть | есть | есть | есть |
| 4 | `http_clients` / `route.default_http_client` | нет | нет (зонд: unknown field) | нет (зонд) | нет (зонд) | **есть** (`option/options.go` гл. пина; рендер sora §2.2) |
| 5 | VLESS + REALITY + Vision flow | есть (golden проходит после трансляции DNS) | есть | есть | есть | есть |
| 6 | VMess / Trojan / Shadowsocks | есть (golden) | есть | есть | есть | есть |
| 7 | Hysteria2: `server_ports` + `hop_interval` | есть (`option/hysteria2.go`; зонд — после трансляции DNS не блокирует) | есть (зонд exit 0) | есть (зонд) | есть (зонд) | есть |
| 8 | Hysteria2: `hop_interval_max` | нет | нет (зонд: unknown field) | нет (зонд) | нет (зонд) | **есть** (1.14) |
| 9 | Hysteria2: `bbr_profile` | нет | нет (зонд) | нет (зонд) | нет (зонд) | **есть** (1.14) |
| 10 | Hysteria2 obfs: salamander | есть (`protocol/hysteria2` lx/upstream обрабатывает `salamander`) | есть | есть | есть | есть |
| 11 | Hysteria2 obfs: gecko (+`min/max_packet_size`) | нет | нет (зонд: unknown field) | нет (зонд) | нет (зонд) | **есть** (`option/hysteria2.go`: `enum:"salamander,gecko"`) |
| 12 | Hysteria2 congestion (up/down_mbps → Brutal) | поля `up_mbps/down_mbps` есть во всех ветках (`option/hysteria2.go`) | есть | есть | есть | есть |
| 13 | TUIC (`congestion_control`, `udp_relay_mode`) | есть (`option/tuic.go`) | есть | есть | есть | есть |
| 14 | WireGuard | `endpoints[]` **и** устаревший outbound сосуществуют (`protocol/wireguard/{endpoint,outbound}.go`); golden `endpoints[]` проходит | то же | **только endpoint** (outbound удалён) | только endpoint (+ AWG, п. 15) | только endpoint (+ AWG) |
| 15 | AmneziaWG-параметры WG (`jc/jmin/jmax/h1–h4/i1/s1–s4`) | нет (зонд: `unknown field "h1"`) | нет (зонд) | нет (зонд) | **есть** (golden amneziaWG проходит; `with_awg` в libbox-тегах) | есть |
| 16 | AnyTLS | **нет** (`protocol/anytls` отсутствует) | **есть** (changelog 1.12.0: «Add AnyTLS protocol») | есть | есть | есть |
| 17 | Naive | код есть, но стоковый libbox собирается **без** `with_naive_outbound` (теги build_libbox) | то же — нет в libbox | есть (тег в build_libbox) | есть (тег в build_libbox) | есть |
| 18 | Транспорты ws / grpc / h2(http) / httpupgrade | все есть (`transport/v2ray*`) | есть | есть | есть | есть |
| 19 | Транспорт XHTTP | нет | нет (зонд: `unknown transport type: xhttp`) | **нет** (зонд; в апстриме XHTTP нет и в 1.13) | **есть** (`transport/v2rayxhttp`, тег `with_xhttp` в libbox; зонд exit 0) | есть |
| 20 | TLS ECH (outbound) | есть (`OutboundECHOptions`, тег `with_ech`); без `query_server_name` | есть; без `query_server_name` | есть + `query_server_name` | есть + `query_server_name` | есть + `query_server_name` |
| 21 | ECH `query_server_name` | нет | нет (зонд: unknown field) | **есть** (`option/tls.go`; changelog 1.13.x: «Add `tls.ech.query_server_name` option») | есть | есть |
| 22 | TLS fragment / record_fragment (outbound TLS) | **нет** (зонд на 1.11-базе: `unknown field "fragment"`) | **есть** (changelog 1.12.0: «Add TLS fragment… to outbound TLS options»; зонд exit 0) | есть | есть | есть |
| 23 | uTLS фингерпринты (`common/tls/utls_client.go`, switch поимённо) | `chrome`(+`chrome_psk`, `chrome_psk_shuffle`, `chrome_padding_psk_shuffle`, `chrome_pq`), `firefox`, `edge`, `safari`, `360`, `qq`, `ios`, `android`, `random`, `randomized`; utls = sagernet/utls v1.6.7 | тот же список + `chrome_pq_psk`; utls = metacubex/utls v1.8.4 | тот же, что 1.12 | тот же, что 1.12 | тот же + **`chrome_155`** (lx-форк utls); `chrome_131` не существует **нигде**, включая гл. пин (зонд: `unknown uTLS fingerprint`) |
| 24 | REALITY: `mldsa65` / keyShare | нет (grep по `option/`, `common/` пуст во всех кандидатах) | нет | нет | нет | нет в sing-box-рендере (поля Plan — Xray/mihomo-специфика, ARCHITECTURE §3.3: хранятся, не эмитятся) |
| 25 | Mux (smux `multiplex`) | есть | есть | есть | есть | есть |

Итоговая картина дельт lx.15 vs главного пина — только пп. 4, 8, 9, 11, 23
(`http_clients`, `hop_interval_max`, `bbr_profile`, gecko, `chrome_155`):
все пять — **аддитивные поля 1.14**, генератор SoraCore для legacy-тира
обязан их не эмитить (version-gate), семантика остального конфига совпадает.

---

## 5. Измерение условия дизайна: `sing-box check` по корпусу

Корпус: `~/workspace/.goldcheck/golden/*.json` (12 файлов, сгенерированы
под 1.14.3-lx.22). Бинари — официальные релизные linux-amd64 (дайджесты §7).
Команда: `<binary> check -c <file>` на каждый файл; журнал —
`checklogs/matrix.txt`.

### 5.1. Матрица по основному корпусу (без правок)

| Бинарь | PASS | Отказы |
|---|---|---|
| lx **1.13.13-lx.15** | **12/12** | — |
| upstream 1.13.21 | 11/12 | `amneziaWG.json`: `endpoints[0].h1: unknown field` (AWG — lx-only) |
| upstream 1.12.25 | 11/12 | тот же AWG-отказ |
| upstream 1.11.15 | 0/12 | все: `dns.servers[0].path: unknown field "path"` (новый DNS-формат) — первый, маскирующий отказ |
| upstream 1.10.7 | 0/12 | идентично 1.11.15 |

Вывод условия ARCHITECTURE для тира 1: **lx.15 проходит общий корпус sora
целиком, без единой version-gated правки** — сильнее, чем требует условие
(оно допускало legacy-корпус как подмножество). Апстрим-кандидаты условие
выполняют только с гейтом AWG.

### 5.2. Зонды 1.14-фич (на базе golden, `checklogs/probes*.txt`)

| Зонд | lx.15 | 1.12.25 | 1.13.21 | гл. пин |
|---|---|---|---|---|
| hy2 `bbr_profile` | ✗ unknown field | ✗ | ✗ | ✓ |
| hy2 `hop_interval_max` | ✗ unknown field | ✗ | ✗ | ✓ |
| hy2 `server_ports`+`hop_interval` | ✓ | ✓ | ✓ | ✓ |
| hy2 obfs gecko | ✗ unknown field `min_packet_size` | ✗ | ✗ | ✓ |
| vless transport xhttp | **✓** | ✗ unknown transport | ✗ unknown transport | ✓ |
| vless tls `fragment` | ✓ | ✓ | ✓ | ✓ (на 1.11-базе: ✗) |
| trojan ECH + `query_server_name` | поле принято (отказ только на тестовом PEM) | ✗ unknown field | поле принято | поле принято |
| `http_clients` + `route.default_http_client` | ✗ unknown field | ✗ | ✗ | ✓ |
| utls `chrome_131` | ✗ unknown fingerprint | ✗ | ✗ | ✗ (имени нет ни в одной ветке) |

Пробел корпуса (честно): в golden нет XHTTP-конфига и нет anytls-конфига;
XHTTP на lx.15 подтверждён зондом выше, anytls — исходниками ветки
(`protocol/anytls`), не check-прогоном корпуса.

### 5.3. Legacy-корпус тира macOS 10.15 (пин 1.11.15)

Трансляция (механическая, `corpus111/`): DNS → старый формат
(`address: https://1.1.1.1/dns-query`, fakeip → `dns.fakeip`-блок),
`route.default_domain_resolver` снят. Результат (`checklogs/corpus111.txt`):

- **11/12 PASS**: chain, hysteria2, shadowsocks, trojan, tuic,
  vless ×4, vmess, wireguard (включая `endpoints[]` и REALITY/Vision).
- **1 отказ — `amneziaWG.json`** (`endpoints[0].h1: unknown field`):
  классифицируется «фича только lx/1.14-линии» → AWG в 10.15-тире
  **version-gated out**, в legacy-корпус не входит.
- Дополнительно гейтятся по §4: AnyTLS (нет протокола), TLS fragment,
  ECH `query_server_name`, XHTTP. Базовый конфиг (DNS после трансляции,
  TUN/mixed, route-actions, все базовые протоколы корпуса) — **проходит**,
  блокирующих отказов нет.

Состав legacy-корпуса lx.15-тира: **все 12 файлов основного корпуса как
есть** + гейт-лист §4 (пп. 4, 8, 9, 11, 23) на уровне генератора.

---

## 6. CVE-статус веток

Метод: GitHub Advisory Database API (`api.github.com/advisories?affects=…`),
21.10.2026; релиз-ноты безопасности апстрима.

### 6.1. Модуль sing-box

По модулю `github.com/sagernet/sing-box` в GHSA DB существует **ровно одно**
advisory за всю историю: GHSA-r5hm-mp3j-285g / CVE-2023-43644 (Critical,
обход аутентификации SOCKS-inbound, затронуты < 1.4.5). **Ни один кандидат
(1.11+) им не затронут.** Собственных repo-advisory у SagerNet/sing-box
не опубликовано. По форку `github.com/sagernet/quic-go` (v0.49.0-beta.1 /
v0.52.0-sing-box-mod.3 / v0.59.0-sing-box-mod.4 у кандидатов) advisory
в GHSA DB — 0 (запрос по имени модуля форка; статус апстрим-quic-go на
форк механически не переносится — **не подтверждено** глубже этого запроса).

### 6.2. Транзитивная зависимость grpc — эскалация

Все кандидаты несут `google.golang.org/grpc` версий, попадающих в диапазоны
**5 advisory** GHSA DB (запросы `affects=google.golang.org/grpc@<версия>`
для 1.63.2, 1.73.0, 1.79.1 дают одинаковый набор):

| Advisory | Severity | Затронутые пины |
|---|---|---|
| GHSA-p77j-4mvh-x3m3 / CVE-2026-33186 — authz bypass через `:path` без слэша | **Critical** | все кандидаты (grpc 1.63.2 / 1.73.0 / 1.79.1 < 1.79.3) |
| GHSA-vp52-pcj8-j9qc / CVE-2026-84304 — HTTP/2 DATA fragmentation, heap OOM | High | все кандидаты |
| GHSA-2v4p-qf9q-27wj / CVE-2026-84445 — xDS server DoS | High | все кандидаты |
| GHSA-hrxh-6v49-42gf — xDS RBAC + HTTP/2 (rollup) | High | все кандидаты |
| GHSA-qc2q-p7wx-3px3 / CVE-2026-84303 — xDS RBAC header matching | Medium | все кандидаты |

Главный пин продукта этот класс уже закрывал: lx 1.14.3-lx.22 несёт
grpc **v1.83.1** (go.mod вычитан) — вне диапазонов.

**Применимость (по исходникам кандидатов):** Critical и три xDS/RBAC
advisory требуют gRPC-**сервер** с `grpc/authz`-интерцепторами или xDS.
sing-box использует grpc-go только как транспорт V2Ray
(`transport/v2raygrpc` client+server); `grpc/authz` и xDS в дереве
**не импортируются** (grep по дереву lx.15 пуст). Конфиги, которые
генерирует sora для Apple, gRPC-inbound не создают (inbound — tun/mixed).
GHSA-vp52 (HTTP/2 серверный стек) теоретически ближе к коду, но её
прекондиция — принимающий gRPC-сервер, которого в генерируемых конфигах нет.
Итог: **эксплуатируемость в продукте не подтверждена и по прекондициям
выглядит отсутствующей; формальный флаг сканеров зависимостей — есть.**

### 6.3. Варианты для координатора (эскалация по условию ARCHITECTURE)

1. **Принять lx.15 с документированным риск-акцептом** по §6.2 (прекондиции
   не выполняются; libbox в NE-расширении, gRPC-сервер конфигами sora
   не поднимается). Условие «нет критических CVE» при этом трактуется
   по применимости, а не по версии зависимости.
2. **Сборочный патч:** раз libbox всё равно собирается нами (§2.3),
   добавить `replace google.golang.org/grpc => v1.83.1` (версия главного
   пина) при сборке legacy-libbox. Совместимость с кодом 1.13.13 —
   **проверить на Mac, здесь не верифицируется**; при несовместимости —
   минимально ≥ v1.79.3.
3. **Сменить ветку на 1.12.25** (прецедент sora-legacy) — CVE **не чинит**
   (grpc ещё старше, набор advisory тот же) и добавляет гейты §5.2/§4.
   Как CVE-ответ не работает; имеет смысл только ради единства ветки.
4. Отказ от legacy-тира до выхода lx-линейки на новой базе — теряет
   iOS 13–14 / macOS 11–12 целиком при измеренном 12/12 по корпусу.

Рекомендация подотдела: вариант 1 + вариант 2 как hardening-задача
сборочного подотдела.

---

## 7. Дайджесты (измерено `sha256sum`, 2026-10-21)

| Артефакт | SHA-256 |
|---|---|
| src SagerNet/sing-box v1.11.15 (tar.gz) | `97d58dd873d7cf9b5e4b4aca5516568f3b2e6f5c3dbc93241c82fff5e4a609fd` |
| src SagerNet/sing-box v1.12.25 | `881435f07b5ab8170ccf3cb69e87130759521dc0ed1ae4bfeacbe7772a93a158` |
| src SagerNet/sing-box v1.13.21 | `c994018d7c2a8fc9fcf6080e4b9cc4f2f915e755342238b77e46fc0806fe96db` |
| src Leadaxe/sing-box-lx v1.13.13-lx.15 | `71216adb3e038d7fb04661e09b24380a167fffa4c5e7f69d4d1297f5c0d7d0f0` |
| src Leadaxe/sing-box-lx v1.14.3-lx.22 (справка) | `e6a9544f095ee9bd4813ead12f0bb0055fa3a4dd5545b4da6b7a5692dfd10473` |
| src SagerNet/sing-box v1.10.7 / v1.9.7 (справка) | `402b618148b58f5ff6c1bee4f4fdcf7cdcb88a2df6a8bd682ea742a89b5be9ec` / `5b015352f3434bb780af01a6b1f6c0fe706166d6c44a69547e29892f0920b944` |
| bin sing-box 1.11.15 linux-amd64 | `950af37eb2d7e55dddae34a18411cd617303fd99d2dc75bc76b6dd9fcd97d9c5` |
| bin sing-box 1.12.25 linux-amd64 | `a1ec76e2b6b139eb747a1b1ebee7d14b8d4be5a833596cad8070a31ef960301f` |
| bin sing-box 1.13.21 linux-amd64 | `24f9ef8e7234e13e71e74c3598a4164c5fe07b7b67ccc6e96cf68b54789f72cd` |
| bin sing-box-lx 1.13.13-lx.15 linux-amd64 | `4a48bcfd14f9bb258d9c77abb03153a5c58f600d794bbeda21a8931904bdf05e` |
| bin sing-box 1.10.7 linux-amd64 (справка) | `1951a0785c8b4e1e21e0640227a49528ca772aec3d680061652e3d6b687e00fe` |
| src sagernet/gomobile v0.1.4 / v0.1.8 / v0.1.12 | `6101c7f89334e1b53f4bef648bd54c5032bae51661aa8584fdf01dbecdfc4d4a` / `ecbc071eea4c21152cf7c458490ab4404850a2629447856c5770661870a32047` / `53d49268c542accb1d4a4784008b61f0fc13d32610a783ba320555f4e8cafa8c` |

---

## 8. Что не подтверждено (честный остаток)

- Собираемость и рантайм libbox пинов на реальных iOS 13–14 / macOS 11–12 /
  10.15 — проверяется только на Mac с Xcode (здесь нет тулчейна Apple);
  полы §2.2 — это флаги gomobile + рантайм-полы Go + отсутствие явных
  блокировок в исходниках веток, а не успешная сборка.
- Уточнение к §2.2 (измерено `sing-box version` по релизным бинарям §7):
  десктопные релизы тех же тегов апстрим собирает более новым Go, чем
  минимум go.mod, — 1.10.7: go1.23.4; **1.11.15: go1.24.4**; 1.12.25:
  go1.25.8; 1.13.21: go1.25.12 (у lx.15 бинарь — go1.24.7, совпадает с
  go.mod). Следствие: достижимость macOS 10.15 пином 1.11.15 — свойство
  **нашей исходной сборки** libbox тулчейном Go 1.20 (go.mod ветки это
  разрешает), а не готовых бинарей апстрима; что ветка 1.11.15 сегодня
  фактически собирается именно Go 1.20 (а не только ≥ 1.21+ в режиме
  совместимости), на Mac **не подтверждено** — это первый пункт проверки
  сборочного подотдела для 10.15-тира. Для тира 1 (lx.15) оговорка не
  применима: его пол macOS 11 следует и из go.mod, и из фактической
  сборки.
- Точная версия ClientHello за именем uTLS `chrome` у legacy-веток
  (HelloChrome_Auto версии utls-библиотеки ветки) поимённо не детализировалась.
- CVE-статус форка sagernet/quic-go глубже запроса GHSA DB по имени модуля.
- Прохождение App Store/Xcode-гейта legacy-таргетом — зона ARCHITECTURE
  §1.3, этим подотделом не измерялась.
