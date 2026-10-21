# W-пакет (желательные разрывы паритета): спеки непортированного

Дата: 2026-10-21. Исполнитель: отдел подъёма sora-legacy, пакет W.
Эталон: sora, **снимок `142397c59480bc79801d9765755b6c2217f07aa8`**
(только закоммиченное состояние; чтение через `git archive HEAD`).
База legacy на старте: `9e2b677`; коммиты пакета садились CAS-ом поверх
живой ветки `bugfix/audit-2026-10-19`.

Портировано коммитами (здесь не дублируется): W1 — `4df568c`, `28cbbb0`;
W2 — `5361e6f`, `011f784`, `794a476`; W4 — `48fe953`.
Этот файл — то, что сознательно НЕ портировано, и почему.

---

## W1-остаток. Тюнинг в документах (sing-box JSON / Clash YAML): паритет потери

Факт снимка (доказан дифференциальной пробой 2026-10-21, одинаковый вход
в оба репозитория): parser обоих репозиториев складывает поля документов
в `Options` под **документными** именами (`up_mbps`, `server_ports`,
`hop_interval:"45s"` у sing-box; `up:"100 Mbps"`, `down`, `ports`,
`congestion-controller`, `heartbeat-interval` у Clash), а
`credentialDocument` обоих читает только **ссылочные** имена
(`upmbps/downmbps/mport/ports/hop-interval/congestion_control/…`).

Итог на снимке, одинаковый в эталоне и legacy после W1:

- Clash HY2: `ports` и `hop-interval` **сохраняются** (их читает
  `firstOpt("mport","ports")` / `firstOpt("hop-interval","hopinterval")`);
  `up`/`down` теряются **в обоих**.
- sing-box JSON: `up_mbps/down_mbps/server_ports/hop_interval` теряются
  **в обоих**; TUIC `congestion_control/udp_relay_mode` в JSON-документе
  лежат в Options JSON-кавыченными (`"\"cubic\""`) и в vault попадают
  как есть — **в обоих**.

Это не разрыв legacy, а дыра самого эталона на снимке. Чинить её в
legacy в одиночку — значит уехать от эталона. Если владелец решит чинить:
точка одна — нормализация документных имён в `credentialDocument`
(legacy: после `resolveImportedSpec`; эталон: в `credentialDocument`),
~15 ключей + тесты-векторы на оба формата; делать синхронно в обоих
репозиториях.

## W1-риск. sing-box MinVersion против 1.14-полей

Рендер sing-box после W1 эмитит `hop_interval_max` и `bbr_profile` —
написания sing-box **1.14**. Каталог sora держит пол sing-box
`MinVersion: "1.14.3"`; каталог legacy — `"1.12.0"` при поставляемом
пине upstream 1.14.3. На поставляемом пине всё честно; гипотетический
пользовательский sing-box 1.12–1.13 (формально допустим каталогом)
откажется загружать конфиг с этими двумя ключами. Решения: (а) поднять
legacy MinVersion до 1.14.3, как в эталоне; (б) гейтить рендер по
версии. Не сделано в W1: это меняет допуск движков, а не паритет
тюнинга; за владельцем/отделом движков.

---

## W2-спека. RPC записи override и провайдерский слой

### Что есть в эталоне на снимке

- RPC `SaveSubscriptionOverride` / `GetSubscriptionOverride`
  (proto-сообщения + `OverrideRule` в ответе Get): широко представлен в
  `core/gen/sora/core/v1/core_control.pb.go` эталона (по сверке
  REVIEW-W: 78 строк / 92 вхождения; в legacy — 0); обработчики —
  `core/control/override.go` (сохранение с преемственностью ExtraRules
  и ProviderRouting, Clear-семантика, ответ — свежее состояние).
- Провайдерский routing-слой (happRouting, C3): пакет
  `core/happrouting` (конверсия документа провайдера), поле
  `Info.HappRouting`, `applyProviderRoutingLocked` на каждом успешном
  refresh: слой заменяется целиком, битый документ — слой сохраняется,
  пользовательские правки не трогаются никогда.
- HWID-идентичность устройства: `core/subscription/device.go`,
  `device_store.go` (GenerateHWID/ValidHWID/Headers), резолв на каждый
  fetch в control. По аудиту — класс **ВЛАДЕЛЕЦ**, здесь не
  переоткрывается.

### Что есть в legacy после W2

- `subscription.OverrideStore` + `Override` (включая поле
  `ProviderRouting` — форма хранения совместима с эталоном),
  применение в `stateLocked` (`applySubscriptionOverride`), удаление
  файла при удалении подписки. Записывать файл сегодня некому:
  достижимого писателя без RPC в legacy нет.

### Чего нет и объём порта

1. **Proto**: в legacy `core/gen/sora/` только пакет `core`;
   сообщений `SaveSubscriptionOverrideRequest/Response`,
   `GetSubscriptionOverrideRequest/Response`, `OverrideRule` нет
   (grep по pb.go: 0). Порт = правка `.proto` источника (вне core/),
   регенерация `buf generate` (на dev-машине, в песочнице buf нет),
   +2 метода в интерфейс `CoreControlServer`, версия контракта
   (legacy ведёт переговоры на ApiVersion 1.7; эталон относит эти RPC
   к Since 1.8+).
2. **Обработчики**: `Save/GetSubscriptionOverride` из эталонного
   `control/override.go` (~110 строк) переносятся дословно после п.1;
   зависимости (`subs.get`, `subs.state`) в legacy отсутствуют как
   методы книги — добавляются там же (~30 строк, есть в эталоне).
3. **Клиент**: C# Client legacy не имеет экрана правок подписки;
   без него RPC мёртв со стороны продукта. Это UI-задача поколения
   Client, не core.
4. **ProviderRouting-писатель**: порт `core/happrouting` (~эталон:
   пакет + конверсия + тесты), поле в `subscription.Info`,
   `applyProviderRoutingLocked` в refresh, слияние правил в план на
   стороне клиента (sentinel `proxy`). Объём — отдельный пакет уровня
   C3 эталона; в одиночку, без клиентского слияния, даёт только
   хранение.

Риски: регенерация proto трогает весь сгенерированный контракт
(дифф по pb.go большой, ревью обязательно на dev-машине с buf);
поднятие ApiVersion — переговорный риск со старым C# клиентом.

---

## W3-спека. Диагностика DNS-leak / JA4 / throttle (полностью спека)

Вердикт пакета: **ничего не портировано**. Каждая проверка эталона
достижима пользователем только через поверхность, которой в legacy
нет; портировать «голые» функции без поверхности — мёртвый код.

### DNS-leak

Эталон на снимке:

- RPC `CheckDnsLeaks` (proto + `control/dnsleak.go`, 10с бюджет,
  требует активную сессию; ответ — `[]DnsLeakCheck{id,label,expected,
  actual,leaked,fix_hint}`, label/fix — l10n-ключи).
- `core/diagnostics`: `dnsleak.go` (533), `dnsspoof.go` (301),
  `dnsintercept.go` (431), `dnsprobe.go` (346) — проверки
  tunnel-dns / system-resolvers / encrypted-dns / killswitch-dns /
  dns-spoof с canary `one.one.one.one`.
- Детект системного DNS: `systemdns_resolvconf.go` (45),
  `systemdns_windows.go` (41), `systemdns_encrypted_linux.go` (85),
  `systemdns_encrypted_other.go` (12) — `SystemResolvers()` и
  зашифрованные системные резолверы.
- Контекст сессии в control: `leak.go` (112) — `hijacksDNS(tunnelMode,
  plan)`, `killSwitchArmed` (платформенный пробинг фактического
  состояния guard, не желания сессии); рядом живёт пакет
  `core/leak` (687) — соседняя поверхность тех же проверок.

Legacy: proto RPC нет (поколенческий разрыв 30 vs 43, G12/ВЛАДЕЛЕЦ);
`core/diagnostics` — только коллектор отчёта (env/интерфейсы/события/
пакеты), ни одного из файлов выше; `session.Plan()` в legacy есть и
plan отдаёт (уточнение REVIEW-W) — недостижима именно проба контекста
сессии эталона из `leak.go`; guard legacy не имеет платформенной пробы
«kill switch фактически стоит» (есть Apply/Restore, пробы нет).

Объём полного порта: proto (+1 RPC, регенерация) → diagnostics
(~1750 строк + тесты ~1200) → systemdns (4 файла, платформенные) →
control-обвязка (сессия/guard-проба, ~150 строк) → l10n-ключи в C#
клиенте. Точки касания: `core/diagnostics`, `core/control`,
`core/session`, `core/guard`, proto, ARB клиента. Риск: canary-пробы
шлют реальный DNS-трафик — поведение на заблокированных сетях нужно
проверять на dev-машине; в песочнице не верифицируется.

Достижимый эквивалент без новых RPC: **нет**. `RunDiagnostics` legacy
возвращает текстовый отчёт коллектора; встроить туда leak-проверки
нельзя без тех же входов (план сессии + системные резолверы + проба
guard), а результат без id/label/fix-контракта клиент не покажет —
это была бы вторая, несовместимая поверхность.

### JA4

Эталон: `diagnostics/ja4.go` (695) — захват ClientHello uTLS-паррота
без сети, парсинг, JA4 по спеке FoxIO, суд «свежести»
 (`AssessJA4`),
`diagnostics/freshness.go` (108) и `hello.go` (173); данные парротов —
`engine/fingerprint.go` (275) + `fingerprint_policy.go` (244) +
watch-тесты; потребление — `control/ja4.go` (49, freshness notices на
плане) и `control/parrotwatch.go` (27), т.е. JA4 в эталоне — не
отдельный экран, а часть свежести отпечатков в потоке сессии/плана.

Legacy: нет ни `engine/fingerprint.go`, ни одного потребителя; uTLS
есть (тот же `refraction-networking/utls`, пин 1.8.2 против
`-0.20261006` псевдоверсии эталона — парроты `HelloChrome_Auto` могут
различаться составом). Порт одного `ja4.go` без fingerprint-таблиц и
без потребителя в control даёт функцию без вызывающих. Объём полного
порта: fingerprint-подсистема (~520 строк + тесты) → ja4/freshness/
hello (~975 + тесты) → control notices → сверка парротов на пине
utls 1.8.2 (нужен dev-стенд; JA4 эталона привязан к Chrome 155
checkpoint — на другом парроте значения разойдутся легитимно, векторы
эталона дословно не лягут).

### Throttle

На снимке `core/diagnostics/throttle.go` **не существует** (аудит
ссылался на него по состоянию своего HEAD). Классификация троттлинга
на снимке живёт в `core/tune/desync` (реестр классов, включая
`quic_throttle`) — это зона отдела цензуры эталона, в legacy
подсистемы `tune` нет как класса. Спека: не портировать точечно;
возвращаться только вместе с решением по censor/tune поколению.

---

## W4-остаток. Что в obfs эталона не портировано и почему

Портировано (`48fe953`): `Profile.Jitter/FakeSNI` + валидация/clamp/
пресеты, `RewriteClientHelloSNI` (`sni.go` дословно), `jitterConn`
(`jitter.go` дословно), стек в legacy `WrapConn`
(jitter → rewrite → legacy-фрагментер), fail-closed на
непереписываемом hello, проброс hello без SNI.

Не портировано:

1. **`SplitClientHello` + `WriteFragmented` (record-aware разрезание,
   `frag.go` эталона, 125 строк).** Эталон режет полезную нагрузку
   записи на отдельные TLS-записи; legacy-фрагментер режет **байтовый
   поток** первой записи на TCP-чанки (заголовок записи уходит в
   первом чанке целиком). Это разная форма на проводе и разная
   семантика ошибок: эталонный `fragConn` требует полных записей в
   одном Write и падает closed при неразрезаемом hello; legacy
   пропускает plaintext-преамбулу (proxy CONNECT) и частичные записи.
   Legacy fetcher подписок запинен тестами именно на legacy-семантику
   (`subscription/obfs_test.go`, `fragment_test.go`). Замена сплиттера
   — отдельное решение с перетестированием fetch-пути, не «дослив»
   W4. Точка касания одна: `fragmentConn.writeFirst`.
2. **`ProfileFromProto` (`proto.go` эталона).** Требует
   сгенерированный пакет `gen/sora/obfs/v1`; в legacy `core/gen/sora/`
   только `core`. Порт = proto-генерация + политика нормализации
   профилей на control-плоскости (в legacy obfs-профиля в proto нет
   вообще — профили задаются кодом/пресетами). Поколенческий разрыв.
3. **`Profile.DialTLS` (метод) против legacy `Dialer`.** Эквивалент
   существует: legacy `Dialer.DialTLS` делает то же (raw dial →
   WrapConn → tls/uTLS handshake) с другим расщеплением ответствен-
   ности. Разрыва функции нет; есть разница API-формы, портировать
   нечего.
4. **Пресеты/профили в production-путях legacy.** Как и в эталоне на
   снимке (см. его `obfs/doc.go`: WrapConn/DialTLS в production не
   вызваны нигде, кроме JA4-отпечатка), в legacy после W4 профили
   живут в fetcher-подписках (фрагментация; теперь также SNI/jitter,
   если профиль их задаёт) и в прямых `Dialer`-диалах. Подключение
   профилей к probe/DoH — продуктовое решение обоих поколений
   (у эталона помечено SW1d/SW1c), не разрыв legacy.

---

## Сводка вердиктов пакета W

| Пункт | Вердикт |
|---|---|
| W1 HY2/TUIC тюнинг | **Портировано**: `4df568c` (engine), `28cbbb0` (parser→vault→рендеры). Остаток — §W1-остаток (паритет потери в эталоне) и §W1-риск (MinVersion) |
| W2 override/fallback | **Портировано** самодостаточное: `5361e6f` (fetcher fallback), `011f784` (override store+применение), `794a476` (fallback в control). RPC записи и happRouting/HWID — спека выше |
| W3 DNS-leak/JA4 | **Только спека** (этот файл): поверхность упирается в отсутствующие RPC и подсистемы; достижимого эквивалента без новых RPC нет |
| W4 SNI-rewrite/jitter | **Портировано**: `48fe953`. Record-aware сплиттер и ProfileFromProto — спека выше |
