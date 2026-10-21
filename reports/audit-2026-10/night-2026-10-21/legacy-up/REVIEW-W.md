# Ревью пакета W (legacy-up): W1 тюнинг HY2/TUIC, W2 fallback/override, W4 FakeSNI/jitter

Дата: 2026-10-21. Ревьюер: независимый, кода не правил, коммитов не делал.
Метод: только закоммиченные состояния (`git archive`), рабочие деревья не
читались и не использовались. Все стенды — собственные тесты ревьюера,
идентичные файлы бросались в архивы обоих репозиториев и сравнивались
по выводу.

## Снимок и дрейф

- Эталон исполнителя: sora `142397c59480bc79801d9765755b6c2217f07aa8` —
  зафиксирован, сверка велась **с ним**.
- Текущий HEAD sora: `d93d5e94` — ровно один коммит поверх снимка
  (errkeys2: bypass-strategy errkey в `core/control/plan.go` + l10n).
  По W-зонам (engine, parser, subscription, obfs, рендеры, control
  subscriptions/plan-тюнинг) дрейфа **нет**: `git diff --name-only`
  снимок→HEAD не содержит ни одного файла этих зон.
- Legacy: шесть коммитов — верхушка ветки `bugfix/audit-2026-10-19`,
  HEAD `48fe953`, цепочка линейна поверх `15f313e`.

## W1 — ПРИНЯТЬ

Дифференциальный стенд ревьюера (Parse → credentialDocument →
parseCredential → applyCredential; рендеры трёх движков; 23 негативных
вектора валидаторов; SelectEngine):

- **Vault-цепочка**: hy2-ссылка с полным тюнингом (up/down 100/200,
  mport `20000-30000,40000`, hop-interval 45, hop-interval-max 90,
  bbr-profile aggressive, obfs salamander+пароль) и tuic-ссылка
  (congestion cubic, udp-relay-mode quic, heartbeat 15, token) дают
  в legacy поля плана, **идентичные эталону** по всем значениям;
  документы vault по ключам тюнинга совпадают.
- **«Тюнинг умирал в vault» до порта — подтверждено пробой на родителе**
  `15f313e`: парсер родителя Options несёт `upmbps/mport/hop-interval`,
  а `credentialDocument` родителя их не пишет (в документе только
  obfs/password/security/server_name) — потеря именно на vault-шаге.
- **Рендеры**: sing-box outbound-объекты — **байт-в-байт одинаковы**
  с эталоном во всех трёх кейсах: brutal (`up_mbps/down_mbps`,
  `server_ports` colon-орфография `["20000:30000","40000:40000"]`,
  `hop_interval:"45s"`, `hop_interval_max:"90s"`, без `bbr_profile`),
  BBR (`bbr_profile:"aggressive"` без caps), TUIC
  (`congestion_control`, `udp_relay_mode`, `heartbeat:"25s"`).
  Mihomo: строки тюнинга идентичны (`up: 20 Mbps`, `ports: …`,
  `hop-interval: 45`, TUIC `heartbeat-interval: 25000` — миллисекунды,
  `token:`). Xray: `hysteriaSettings={auth, up_mbps:20, down_mbps:100,
  version:2}` в brutal-кейсе; в BBR-кейсе тюнинг-ключей нет (честное
  отсутствие); obfs-план Xray **отклоняет ошибкой** в обоих репо
  (одинаковый текст), не теряет молча.
- **Валидаторы**: тела `validateHysteria2Tuning/validateTUICTuning/
  validateHopPorts` дословно равны эталону; 23 негативных/позитивных
  вектора моего стенда (битые hop-спеки, reversed/70000/0, max<interval,
  bbr-bogus, отрицательные/огромные caps, чужие cc/urm, heartbeat вне
  диапазона…) — ошибки **идентичны по тексту** в обоих репо, включая
  места, где эталон сознательно пропускает (hop-interval вне диапазона
  без max — nil в обоих; unknown obfs — nil в обоих, судят рендер/гейт).
- **Гейты**: `FeatureHy2PortHop/FeatureHy2Obfs` заявляют mihomo+sing-box,
  xray — нет, как эталон. План с port-hop при доступном только xray:
  `SelectEngine` возвращает ошибку с причиной `xray: cannot carry
  feature hy2-port-hop` — в обоих репо одинаково; при всех движках
  выбирается sing-box.
- `quic_defaults.go` — код идентичен эталону (diff только в комментарии
  про пины). `Token` входит в `Outbound.Secrets()` ✓.
  Портированный `validate_hy2tuic_test.go` отличается от эталона одной
  строкой пробелов; `quic_defaults` константы — те же.

Замечание (не блокирует): см. §«MinVersion» ниже — это спека-риск,
подтверждённый поведенчески, а не дефект порта W1 как такового.

## W2 — ПРИНЯТЬ

- `subscription/fallback.go` и `subscription/override.go` — **diff 0
  строк** с эталоном; их тесты (`fallback_test.go`, `override_test.go`)
  тоже diff 0 и зелёны в обоих репо.
- Fetcher (по дословным тестам эталона, прогнаны в legacy): основная
  падает (500/403/пустое тело/unreachable) → fallback используется,
  `UsedFallback=true`; обе падают → возвращается **первичная** ошибка
  (`TestBothDownReturnsThePrimaryError`); fallback не задан/основная
  жива → fallback не трогается (счётчики хитов 1/0).
- Control — **свой стенд ревьюера** на архиве legacy HEAD (bookServer +
  реальный OverrideStore в DataDir):
  - save ссылки с фрагментом: record разделён — `URL` без фрагмента,
    `FallbackURL` отдельно ✓;
  - `GetSubscriptionLink` (с ApiVersion/auth, как контракт требует)
    возвращает вставленную ссылку **байт-в-байт** (канонический
    percent-encoded фрагмент) ✓;
  - изменение **только fallback** → re-fetch (счётчик fetch 1→2),
    fallback заменён ✓;
  - save без ссылки (переименование) → ни URL, ни fallback не тронуты,
    re-fetch нет ✓;
  - применение override в `stateLocked`: дословный wiring-тест
    исполнителя (rename+hide реально меняют итоговый набор state)
    зелён в полном сьюте;
  - удаление подписки через RPC → файл `overrides/<id>.json`
    **физически исчезает** (stat IsNotExist), `Load` после — пустой
    override без ошибки ✓ (исполнителя wiring-тест это заявлял
    комментарием, но сам не удалял — закрыто моим стендом).
- Refresh через fallback: код `subscriptions.go` — при
  `fetched.UsedFallback` пишется warning `Subscription updated via
  fallback: N servers` (LevelWarning) — строка и уровень идентичны
  эталону (его `subscriptions.go:518`); состояние из fallback-тела
  пинится тестом исполнителя.
- RPC-отсутствие: `grep` по legacy `core/gen/.../core_control.pb.go` —
  `SaveSubscriptionOverride/GetSubscriptionOverride` **0** вхождений;
  в legacy proto только пакет `core` под `gen/sora/`. Кодом не
  выдумано ✓. У эталона: 78 строк / 92 вхождения `SubscriptionOverride`
  в pb.go (см. мелочь про цифру 39 в спеке).

## W4 — ПРИНЯТЬ

- `obfs/sni.go` и `obfs/jitter.go` — **diff 0 строк** с эталоном;
  `obfs/profile.go` — код идентичен (diff только комментарии);
  пресеты (Balanced Jitter 25ms, Max 150ms), Clamp (Jitter→5s,
  FragDelay→2s) и Validate FakeSNI/Jitter совпали на стенде.
- Дифференциал по ClientHello (свой стенд, одинаковый вход):
  `RewriteClientHelloSNI` — выходы структурно идентичны для трёх
  fake-имён (различаются только случайные байты самого тестового
  hello, генерируемого билдером каждого репо); через WrapConn SNI
  на проводе — `decoy.test` в обоих.
- **Порядок стека** jitter → SNI-rewrite → фрагментер подтверждён
  поведением: при FakeSNI+FragSizes переписанный hello фрагментируется;
  payload после сборки равен переписанному hello в обоих репо.
  Форма на проводе различается **по архитектуре, как заявлено в спеке**:
  legacy — байтовые чанки одной записи (wire == переписанная запись,
  78 байт), эталон — record-aware разрезание (88 байт, несколько
  записей, payload тот же).
- **Fail-closed**: hello, который парсится как запись, но не
  переписывается (обрезан внутри расширений, длина записи
  консистентна), — Write падает с одинаковой ошибкой
  `refusing to send the real SNI`, на провод уходит **0 байт** в обоих.
  Hello без SNI — проброс без изменений ✓ в обоих. Не-TLS запись —
  проброс ✓.
- Нюанс паритета (не разрыв): hello, обрезанный **на уровне записи**
  (префикс длины не сходится), оба репо **пропускают как есть** —
  legacy `sniConn` повторяет правило эталонного `fragConn`
  (`parseTLSRecords` err → passthrough). Формулировка задачи
  «битый/обрезанный … рвётся» верна для обрезанного внутри записи;
  record-level обрезка — сознательное правило эталона, legacy ему
  следует.
- Фетчер legacy оборачивает при любой conn-технике
  (`Fragmentation() || FakeSNI != "" || Jitter > 0`, subscription.go)
  ✓ кодом. Legacy-фрагментер действительно байтовый
  (`fragmentConn.writeFirst` режет поток первой записи, заголовок
  целиком в первом чанке), и fetcher запинен на эту семантику
  (`subscription/obfs_test.go`, `obfs/fragment_test.go` — зелёны).

## Спека W-SPECS.md и остатки — ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

Проверено выборочно-глубоко по снимку эталона, фактология в основном
точна до строк:

- **W3/DNS-leak**: `CheckDnsLeaks` RPC есть в proto эталона (Since 1.8)
  и pb.go (31 вхождение), в legacy 0. Размеры файлов эталона совпали
  **точно**: dnsleak 533, dnsspoof 301, dnsintercept 431, dnsprobe 346,
  systemdns 45/41/85/12, control/leak.go 112 (hijacksDNS +
  killSwitchArmed на месте), `core/leak/leak.go` 687, canary
  `one.one.one.one` на месте. Legacy: diagnostics — только коллектор
  (diagnostics.go/report.go/packets/events), ни одного из файлов;
  платформенной пробы «guard фактически стоит» в legacy guard нет
  (только Apply/Restore) ✓.
- **W3/JA4**: ja4.go 695 (`AssessJA4` на месте), freshness 108,
  hello 173, fingerprint.go 275, fingerprint_policy.go 244,
  control/ja4.go 49, parrotwatch.go 27 — всё точно. В legacy нет ни
  fingerprint.go, ни потребителей ✓. Пины utls: legacy 1.8.2, эталон
  `v1.8.3-0.20261006…` — как в спеке ✓.
- **W3/throttle**: `core/diagnostics/throttle.go` на снимке
  **отсутствует** ✓; `quic_throttle` живёт в `core/tune/desync`
  (registry.go) ✓; подсистемы tune в legacy нет ✓.
- **W2-остаток**: proto — 43 rpc эталон / 30 legacy (grep по .proto) ✓;
  legacy ApiVersion переговоров 1.7 (`cmd/sora-core` Version{1,7}) ✓;
  `core/happrouting` и `Info.HappRouting` эталона на месте;
  `ProviderRouting` в legacy Override — есть (форма хранения
  совместима) ✓; `control/override.go` эталона — 208 строк
  (handlers — часть файла, оценка спеки «~110 строк» правдоподобна).
- **W1-остаток (документные написания)**: моя проба на снимке эталона
  и на legacy HEAD дала **одинаковую** картину потери:
  sing-box JSON — `up_mbps/down_mbps/server_ports/hop_interval`
  теряются в обоих; TUIC JSON — `congestion_control/udp_relay_mode`
  попадают в vault JSON-кавыченными (`"\"cubic\""`) в обоих,
  heartbeat — так же (`"\"15s\""` → 0). Уточнение к спеке: Clash
  `ports` ключ читается в обоих, но значение доезжает **тоже
  JSON-кавыченным** (`"\"20000-30000\""`) — формулировка спеки
  «сохраняются» верна про ключ, оптимистична про значение; hop-interval
  Clash (45) доезжает числом в обоих. Классификация «дыра эталона,
  не разрыв legacy» — верна.
- **W1-риск MinVersion — классификация верна, продемонстрирован
  поведенчески**: каталог legacy sing-box `MinVersion: "1.12.0"`,
  эталон `"1.14.3"`, поставляемый пин legacy — upstream 1.14.3
  (комментарий каталога), т.е. на пине всё честно. Мой стенд: план с
  HopIntervalMax+BBRProfile (рендер эмитит 1.14-поля
  `hop_interval_max`/`bbr_profile`) при доступном только sing-box
  1.12.0 — **legacy SelectEngine выбирает sing-box**, эталон
  отклоняет («version 1.12.0 is older than 1.14.3»). Гипотетический
  пользовательский 1.12–1.13 в legacy получит конфиг, который движок
  откажется грузить, — ровно риск спеки; решение (поднять пол до
  1.14.3) — за владельцем/отделом движков, в W1 не входило.

Замечания к фактологии спеки (мелочи, выводов не меняют):

1. «39 упоминаний» override-RPC в pb.go эталона моей метрикой не
   воспроизводится: 78 строк / 92 вхождения `SubscriptionOverride`
   (Save×46 и Get×46 вхождений), плюс 30 строк в grpc pb.go. Порядок
   «в эталоне есть, в legacy 0» — верен.
2. «session не отдаёт plan в той форме (running.Plan())» — неточно:
   у legacy `Session.Plan()` существует (session/runner.go:163).
   Отсутствует именно guard-проба и diagnostics-входы; на объём
   порта W3 это не влияет.

## Дисциплина и регрессии

- `git show --stat` шести коммитов: только заявленные зоны —
  4df568c engine (7 файлов), 28cbbb0 parser/control/3 рендера (10),
  5361e6f subscription (3), 011f784 subscription+control+main.go
  DataDir (8), 794a476 control (2), 48fe953 obfs+1 строка fetcher (10).
  Чужих зон (C#, proto, чужие пакеты) нет.
- Архив legacy HEAD (без стендов ревьюера): `go build ./...` чисто,
  `go vet ./...` чисто, `go test ./...` — **единственный FAIL —
  разрешённый env-артефакт** `engine: TestTunAndFakeIPAvoidLANAndEachOther`
  (`fake-IP pool overlaps an existing interface`); остальные 28 пакетов
  ok, 4 без тестов. Для базы: на снимке эталона пакет engine падает на
  собственном `TestCatalogXmuxClaimMatchesRenderers` (вне W-зон) —
  legacy по затронутым пакетам не хуже эталона.
- gofmt по 38 файлам коммитов: flagged только `core/parser/parser.go`,
  и дефект (пропущенный пустой разделитель у `getq`, ~стр. 639)
  **предсуществует на родителе 15f313e** — W-коммиты gofmt-грязи не
  внесли.
- Портированные тесты «дословно» — выборочная сверка diff-ом:
  fallback_test.go, override_test.go (subscription), sni_test.go,
  jitter_test.go — **diff 0**; validate_hy2tuic_test.go — 1 строка
  пробелов; fallback.go/override.go/sni.go/jitter.go (код) — diff 0.

## Мелочи

- Документы vault legacy и эталона различаются вне тюнинга
  (эталон всегда пишет `"download_port":"0"`, legacy извлекает
  `server_name` из blob-ов в документ, эталон — нет): предсуществующая
  разница архитектур credentialDocument, к W1 не относится, на поля
  плана по тюнингу не влияет.
- `credentialKeys` legacy не пополнился новыми ключами тюнинга —
  проверено как потенциальный дефект: не воспроизводится, т.к.
  `parseCredential` требует лишь один известный ключ, а документы
  tuic/hy2 всегда несут `security`/`password` (token-only tuic без
  sni прошёл цепочку в обоих репо на моём стенде).
- Wiring-тест исполнителя по override заявлял удаление файла
  комментарием, но сам удаление не выполнял; поведение тем не менее
  корректно (закрыто стендом ревьюера выше).
