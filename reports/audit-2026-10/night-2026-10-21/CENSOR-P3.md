# CENSOR-P3 — Hysteria2 и TUIC до идеала

Ветка `bugfix/audit-2026-10-19`, репозиторий `~/workspace/bug-hunt/sora`.
Пины: sing-box-lx 1.14.3-lx.22, mihomo 1.19.32, Xray 26.10.17
(`~/workspace/.engines-amd64`). Режим: локально, без пуша.

## Главное: критический дефект port hopping на sing-box

Рендер sing-box писал план-спецификацию хопов («20000-30000,40000»,
share-link spelling) в `server_ports` дословно. Пин lx.22 такой конфиг
**отклоняет при загрузке**: `bad port range: 20000-30000` (проверено
`sing-box check` вручную и новым бинарным тестом). sing-box требует
двоеточие и явную верхнюю границу: `"20000:30000"`, а одиночный порт —
как `"40000:40000"` (голое `"40000"` тоже `bad port range`).
Итог до фикса: **любой hy2-план с хоппингом не стартовал на движке по
умолчанию**, а юнит-тесты утверждали только форму JSON, не приёмку
бинарём. Фикс: единый переводчик `engine.SingBoxHopPorts`
(`core/engine/quic_defaults.go`), парсер спеки `engine.HopPortRanges`
— один источник для валидации и обоих рендеров; mihomo получает
плановую (dash) форму дословно (его `-t` dash принимает, colon — нет).

## Сделано

### 1. Единый источник дефолтов и словарей — `core/engine/quic_defaults.go` (новый)
- `DefaultHy2HopIntervalSeconds=30` (дефолт обоих движков и референс-клиента),
  `MinHy2HopIntervalSeconds=5` (минимум спеки hy2; раньше магическая `5` в валидации),
  `MaxHy2BandwidthMbps=100000` (потолок капа; `probe.brutalMaxMbps` теперь алиас этой константы — откалиброванный кап не может быть значением, которое план отвергнет).
- `DefaultTUICCongestion="bbr"`, `DefaultTUICHeartbeatSeconds=10` (дефолт обоих движков),
  `MinTUICHeartbeatSeconds=1`, `MaxTUICHeartbeatSeconds=600`,
  `DefaultTUICUDPRelayMode="native"`.
- Словари: `ValidHy2Obfs={salamander,gecko}`, `ValidTUICCongestion={bbr,cubic,new_reno}`,
  `ValidTUICUDPRelayMode={native,quic}` — валидация и рендеры берут отсюда.
- `Outbound.EffectiveTUICCongestion()`, `EffectiveTUICHeartbeatSeconds()` — резолверы «значение или дефолт», рендеры эмитируют эффективное значение.

### 2. Hysteria2
- **Port hopping**: фикс sing-box spelling (выше); валидация переведена на общий парсер.
- **Obfs (salamander/gecko)**: пароль — данные кредов (`ObfsParam`, в `Secrets()`, маскируется).
  Новые гейты валидации: неизвестный тип → отказ; obfs без пароля → отказ (оба движка
  отклоняют такой блок при загрузке — проверено на пинах); пароль без типа → отказ.
- **Гейт движка**: новый `FeatureHy2Obfs` — sing-box и mihomo заявляют, Xray нет
  (его hysteria-транспорт obfs не имеет; раньше план с obfs выбирался для Xray и умирал
  только на Apply). `RequiredFeatures` требует фичу при `Obfs != ""`.
- **Up/down (brutal)**: добавлен верхний bound валидации = `MaxHy2BandwidthMbps` (раньше только `< 0`).
- **Brutal-калибровка**: см. §4 ниже.

### 3. TUIC
- **Heartbeat — отсутствовал полностью** (ни поля плана, ни рендера). Добавлены:
  `Outbound.TUICHeartbeat` (секунды, 0 = дефолт), рендер sing-box `heartbeat: "<n>s"`,
  рендер mihomo `heartbeat-interval: <n*1000>`, валидация границ, проброс через
  parser (`heartbeat` в share-ссылке) и credential document (`heartbeat` в vault, round-trip тест).
- **Congestion**: sing-box уже эмитил эффективное значение; mihomo теперь тоже
  (раньше опускал при unset — движки расходились бы при смене дефолта одного из них).
  Критично: `mihomo -t` **молча принимает** неизвестный congestion controller и
  неизвестный udp-relay-mode (проверено на пине) — плановая валидация там единственная защита.
- **Relay**: `udp_relay_mode`/`udp-relay-mode` native|quic — было, оставлено, словарь централизован.
- Xray TUIC не имеет (каталог честно не заявляет протокол) — гейт на уровне протоколов работает.

### 4. Brutal-калибровка: спроектирован и подключён честный шов
`CalibrateBrutal` был помечен NOT WIRED. Теперь:
- `core/probe/brutal.go` — `BrutalCalibrator`: кэш результата по id аутбаунда,
  кулдаун `CalibrationCooldown` (7 суток, спека §4.4), ручной override —
  данные плана: аутбаунд с `UpMbps/DownMbps > 0` возвращается нетронутым
  (`SourceManual`), кэш не трогается. Без свежего измерения и без свежего
  кэша — честный `SourceNone` (остаётся BBR), **фиктивные капы не изобретаются**.
  Измерение — только из явно запущенного Benchmarker-прогона вызывающим;
  сам калибратор трафик не генерирует (спека запрещает фоновые замеры).
- Комментарий NOT WIRED в `calibrate.go` заменён на фактическое описание шва.
- Тесты: measured→cached→expired→re-measured, manual wins, чужие протоколы игнорятся.

### 5. QUIC-путь: полнота BanTracker / DialQUIC
Проверено по коду и тестам:
- Ротация source-port, TTL бана 420с (FOCI-2026), попытки 4, backoff ×2 — на месте;
  вердикт `ProbeQUICWithTracker` пишет в трекер при Blocked — на месте.
- Найдено и исправлено: (а) магический литерал backoff 100ms → именованная
  `quicDialBackoffStart` с обоснованием; (б) трекер рос без bound — истёкшие
  записи вычищались только при чтении того же ключа; теперь pruning на единственной
  точке записи `NoteBlocked`.
- Engine-internal QUIC (handshake внутри бинарей движков) — честно задокументирован
  в `quic.go`: ротация портов движков из core не сращивается; это не скрывается.
- Параллельный отдел (CENSOR-SURV) в ходе этой же волны подключил production-триггер
  `ProbeQUICWithTracker` (operator mode `sora-core -quic-probe` + персистентный
  BanTracker с network-epoch) — эскалация E2 ниже снята ими, не мной.

## Мелочи (стандарт владельца)
1. **Границы тестами** (`TestValidateHy2TUICBoundaries` + существующие):
   caps 0 / ceiling / ceiling+1 / отрицательные; hop: пустой, один порт, порт 1,
   65535, 0, 65536, полный диапазон 1-65535, вырожденный 5000-5000, перевёрнутый,
   пустой элемент, trailing comma; hop interval = min / min−1; intervalMax = interval;
   heartbeat 0 / min / default / max / max+1 / −1.
2. **Константы с обоснованием**: каждое число в `quic_defaults.go` и `calibrate.go`
   несёт «почему именно это» (дефолт движков, минимум спеки, измерение FOCI 420с,
   margin 0.9 и upShare 0.1 — спека 21-hysteria2.md §4 с причиной). Круглых
   необоснованных чисел в новом коде нет.
3. **Детерминизм рендеров**: `TestRenderHy2TUICDeterministic` в sing-box и mihomo —
   повторный рендер hy2/tuic планов байт-идентичен (3 повтора).
4. **Логи**: нового логирования не добавлено. Пароль obfs остаётся в `Secrets()`
   (редактор-маскировка) и **не** попадает в тексты ошибок валидации —
   тест `TestHy2ObfsValidationNeverEchoesPassword`. Адреса серверов — существующий
   механизм `Identifiers()`, не расширялся.

## Доказательства (факт, не предположения)
- Ручные проверки пинов: `sing-box check` (server_ports colon/dash/одиночный,
  obfs salamander/gecko/bogus, obfs без пароля, tuic heartbeat ok/bogus,
  tuic congestion bogus → отказ, bbr_profile bogus → отказ);
  `mihomo -t` (ports colon → отказ, dash → ок; obfs gecko → ок, bogus → отказ;
  tuic congestion/relay bogus → **молча ок**, отсюда плановая валидация).
- Новый бинарный тест `singbox.TestBinaryAcceptsHy2HoppingAndTUICTuning`:
  рендеры hopping+brutal и tuic-tuning проходят `sing-box check` на пине. PASS.
- Юнит-тесты пакетов engine, engine/singbox, engine/mihomo, probe, parser —
  все тесты этого отдела зелёны (чужие падения в тех же пакетах — ECH/CENSOR-FP,
  censor_p4, reality_censor, probe freeze — не мои ханки, см. эскалации).

### Interop по трафику: в этой песочнице НЕВОЗМОЖЕН — измерено, не предположено
- Факт 1: `sendto()` UDP на 127.0.0.1 возвращает **EPERM (Operation not
  permitted)** для любого процесса моей сессии — сырой python-сокет из шелла,
  дети Go-теста, все размеры датаграмм (32…1400). Политика egress песочницы
  режет UDP полностью; TCP работает. Поэтому QUIC-handshake здесь не проходит
  ни у одного движка — это свойство окружения, а не кода (тот же вывод —
  хроническая боль соседних отделов с AWG/QUIC-тестами; существующий interop
  suite в репозитории TCP-only именно поэтому).
- Факт 2 (ловушка, найденная на себе): env песочницы содержит
  `no_proxy=…,127.0.0.1,…` — urllib и curl с `-x` **обходят** прокси для
  loopback-целей и ходят напрямую. Первая версия моего shell-драйвера матрицы
  показала фальшивые «13/21 PASS» именно этим обходом; после замены fetch на
  сырой сокет через прокси драйвер честно показал блокировку UDP по всем
  сценариям (timeouts/502/503). Ручные curl-проверки начала работы по той же
  причине трафиком **не считаются** и как доказательства не заявляются.
- Артефакт для машины, где UDP разрешён: `core/engine/interop/hy2tuic_test.go` —
  полная матрица (сервер sing-box: hy2 plain/salamander/gecko/3 hop-порта/tuic;
  клиенты sing-box+mihomo по сценариям, Xray plain с верификацией TLS;
  негативные контроли: неверный пароль obfs, gecko↔salamander, неверные пароли
  hy2/tuic). Сьют **сам определяет среду по факту**: дочерний UDP-probe
  (re-exec тест-бинаря); если посылки запрещены — `SKIP` с точной причиной за
  ~3 секунды вместо 8 минут таймаутов, маскирующихся под поломки движков
  (усиление мандата владельца: доступность QUIC — рантайм-проба по факту
  системы, честный отказ с причиной). В этой песочнице: SKIP с причиной —
  зафиксировано. Selection-гейты вынесены в отдельный
  `TestHy2SelectionGates` (UDP не нужен): **PASS здесь и сейчас**.
- Замечание соседа (CENSOR-P2): после SORA-H5 digest-манифест отбрасывает
  CA-обёртки бинарей без AllowEnvBin opt-in — Xray-кейс сьюта на dev-машине
  может потребовать переименования обёрток; пометка внесена в тест.

## Коммиты (все [censor], temp-index + CAS, чужие ханки не свёрнуты)
- `77e33259` — engine: единый источник QUIC-дефолтов (quic_defaults.go),
  FeatureHy2Obfs + гейт в RequiredFeatures, Outbound.TUICHeartbeat.
  (Рендеры/валидация/каталог с этими символами уехали раньше коммитами
  соседей, подхватившими общий ворктри, — по информации CENSOR-P2; этот
  коммит закрывает недостающие определения, HEAD по моим символам полон:
  проверено экспортом HEAD — FeatureHy2Obfs, MaxHy2BandwidthMbps,
  SingBoxHopPorts определены.)
- `dfd75223` — parser+control: heartbeat в белом списке опций и в
  credential document (round-trip тестами).
- `429936d9` — probe: BrutalCalibrator (честный шов) + тесты;
  CalibrateBrutal на общем MaxHy2BandwidthMbps.
- `91e9c4cf` — тесты: границы, детерминизм рендеров, бинарная приёмка.
- `50433b72` — interop: матрица hy2/tuic с факт-пробой UDP.
- Зеркальная ситуация у соседа: экспорт HEAD сейчас не собирается из-за
  `SupportsShadowsocksMethod/SupportsSSPlugin` — определения лежат в
  незакоммиченном `core/engine/ss_support.go` (зона CENSOR-P1), не моя.

## Эскалации (точные)
- **E1 (чужая поломка дерева, блокирует финальный прогон)**: два соседних отдела
  одновременно завели `FeatureRealityKeyShare` — `core/engine/engine.go:128` и
  `core/engine/probecaps.go:71` (redeclared), плюс дубль ключа
  `"reality-key-share"` в `core/engine/catalog.go:58`. Пока не разрешено ими,
  `go build ./engine/` падает. Мои ханки к этим строкам отношения не имеют
  (мои строки каталога — только `FeatureHy2Obfs`). Также соседний CENSOR-FP
  заявил `FeatureECH` для Xray в каталоге, не обновив
  `TestECHPlanRequiresFeatureECH` — тест падает на их ханке.
- **E2 (снята соседями)**: production-вызывающий ProbeQUIC — подключён отделом
  CENSOR-SURV (operator mode + persistent BanTracker), в моих файлах не дублировал.
- **E3 (brutal seam — остаток)**: вызов `BrutalCalibrator.Apply` из конца
  `BenchmarkServers` (core/control/benchmark.go) и сохранение результата в
  credential document (Connect-путь, core/control/server.go) — оба файла в
  чужой зоне («не трогать» по мандату). Точный дифф для владельца файлов:
  после финального Done-сэмпла hy2-сервера без капов вызвать
  `calibrator.Apply(outbound, float64(sample.BytesPerSec)*8/1e6, 0)` и при
  `SourceMeasured/SourceCached` записать `upmbps/downmbps` в credential
  document сервера тем же `SecretStore.Apply`, что пишет импорт. До этого
  диффа калибратор — протестированная библиотека с одним документированным
  вызывающим швом, а не мёртвый код: его контракт и тесты зафиксированы здесь.
- **E4**: `heartbeat` в proto-контракте (OutboundSpec) не заведён — поле едет
  через credential document, как остальные hy2/tuic тюнинги (hop_interval и т.д.)
  — консистентно с существующим механизмом, proto-правка не потребовалась.
