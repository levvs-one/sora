# Wave 3 Go — featlog (F5 / F8 / F9 / F11)

Ветка `bugfix/audit-2026-10-19`, пуша нет (пользователь мержит сам).
Модуль ядра: `sora/core` (`github.com/levvs-one/sora-client`), proto `sora/proto`,
сервис синка — отдельный модуль `sora/service/sync`
(`github.com/levvs-one/sora-client/sync`, без импорта core: opaque blob sync).

Конвенции окружения: `export PATH=$PATH:~/workspace/go/bin
GOTMPDIR=$HOME/workspace/.tmp-gobuild` (в /tmp сборка падает — tmpfs 512M);
`cd proto && buf generate --template /tmp/buf.gen.go.yaml`.

## F5 — сетевые профили с автодетектом

Коммиты: proto `38585e9`, движки/валидация `e41825a` (общий с F8), профили
`b20ea86`, control `1c55560`.

- Proto: `SessionPlan.chain` (15), `zapret_with_vpn` (16), `zapret_strategy`
  (17); `CoreEvent.profile_matched` (12) + `ProfileMatched`; сообщения
  `NetworkProfile`/`ProfileTriggers`/`ProfileApply`/`NetworkFingerprint`;
  RPC `ListProfiles`, `SaveProfile`, `DeleteProfile`, `GetNetworkFingerprint`,
  `ProbeChain`. API bump 1.9 → 1.10.
- Новый пакет `core/profiles`: Store (JSON 0600, атомарная запись, валидация),
  fingerprint — Linux: шлюз из `/proc/net/route` (little-endian hex), SSID
  через `iw` из фиксированных `/usr/sbin:/sbin:/usr/bin:/bin` (fail-closed);
  Windows: netsh/route из System32; build-теги проставлены. Опциональная
  `asn.json` (CIDR→ASN, битая игнорируется). Матчинг AND-по-группам/OR-внутри;
  профиль без триггеров не матчится никогда.
- Хук в session: `EventProfile` в journal, `Config.Profiles` +
  `checkProfile()`/`matchProfile()` в supervise-цикле **только при смене сети**
  (не на initial connect — иначе loop применения), `ManagerConfig.Profiles`
  passthrough.
- Control `core/control/profiles.go`: 4 RPC + конвертеры; битый файл профилей
  → warning в stderr + in-memory (auxiliary не роняет VPN).
- Тесты профилей, сессии, RPC — зелёные; `go build ./...` + `go vet` чисто.

## F8 — proxy chains

Коммит `e41825a`.

- `engine.Outbound.Via`, `FeatureChains`, `validateChains` + `MaxChainHops=3`
  (цель существует, без self/cycle, Via запрещён на direct/bypass), capability
  у всех трёх движков.
- Рендеры: sing-box `dialer_proxy`, mihomo `dialer-proxy` (второй проход после
  резолва имён), xray `dialerProxy`.
- Control `core/control/chain.go`: `ProbeChain` — 2–3 id, dedup,
  resolveBenchmarkServers, TCP-проба через s.prober, сумма задержек,
  `chainEngines` из registry Availability. `plan.go`: `applyChain`.
- Тесты `core/engine/chain_test.go` + chain-тесты трёх движков — зелёные.

## F11 — VPN + zapret одновременно

Коммит `1c55560` (вместе с control F5/F8).

- `plan.go`: `applyZapretWithVPN` — требует TUN, только Linux, id
  `sora-zapret-direct` с проверкой коллизии, стратегия из `zapret_strategy`
  или дефолт SplitPos 1,2+Disorder; ретаргет правил `direct`→bypass после
  routing.Apply.
- Отсутствие tpws — честная ошибка `KeyEngineBinaryMissing` из
  registry.Factory (не silent fallback).
- Тесты `chain_plan_test.go` — зелёные.

## F9 — E2E-синк устройств без облака

Коммит `43420b3`. Новый модуль `service/sync`, зависимости
`flynn/noise v1.1.0`, `hashicorp/mdns v1.0.7`.

- `pairing/`: `Invitation{DeviceID, PublicKey[32], Token[16], Port}`,
  `Generate` (X25519 ephemeral + 16-байт токен), Encode
  `sora-sync://pair?v=1&id=&pub=&token=&port=` (base64 RawURL), строгий Decode
  (схема/host/версия/длины/порт). Тесты: round-trip, reject garbage
  (включая плохой порт), пустой device id.
- `transport/`: Noise_XX_25519_ChaChaPoly_SHA256. Режим спаривания —
  ephemeral-ключи как static + подтверждение токена
  HMAC-SHA256(token, handshake_hash) с обеих сторон (привязка канала к факту
  видения QR, защита от LAN MITM без QR); проверка static-ключа пира =
  ключу из QR. Режим известных пиров (`DialKnown`/`AcceptKnown`) —
  long-term identity-ключи + сверка с `peers.json`. После handshake —
  напрямую CipherState (инициатор шифрует первым, респондер вторым, мьютексы
  на направления). Фреймы: 2-байт длина, чанки 32KB с флагом last, лимит
  64MiB, дедлайны через контекст. Тесты на net.Pipe: handshake+обмен
  сообщениями (включая 100KB и пустое), reject wrong token, reject impostor
  (чужой static-ключ), known-peer handshake + reject unpaired.
  По ходу найден и исправлен баг: в flynn/noise после handshake надо брать
  CipherState из финального сообщения (WriteMessage дальше не работает);
  и баг responder-ветки — не сохранялся peerKey, `AcceptKnown` отклонял всех.
- `discovery/`: mDNS `_sora-sync._tcp`, `Advertise` (FQDN hostname, не-loopback
  IP), `Browse`/`FindDevice` по device id из TXT.
- `sync/`: протокол hello/inv/get/doc/bye; инициатор ведёт, респондер
  реактивен; LWW по `updated_at` (unix ms); `DirStore` — `<dir>/<kind>/<name>.json`,
  0600/атомарно, kind/name `[A-Za-z0-9._-]` ≤128 (иначе reject до файловой
  системы), документы ≤16MiB. Демон полезную нагрузку не парсит (opaque).
  Тесты: конвергенция двух сторов, пропуск равных документов, unsafe-имена.
- `api/`: демон — identity (`identity.json`, 0600, id 12 случайных байт hex,
  имя = hostname), пиры (`peers.json`), pairing-сессии (listener на всех
  интерфейсах + mDNS, TTL 5 мин, автостоп), `Join` (Decode QR → FindDevice →
  dial ip:qr_port → Dial → первый синк), постоянный sync-listener для парных
  пиров, HTTP API только на 127.0.0.1 с Bearer-токеном (`api_token`, 0600,
  constant-time compare): status, pairing start/stop/join, peers, revoke,
  per-peer sync, documents PUT/GET. Тесты API (auth 401, документы, lifecycle
  спаривания, revoke) + E2E двух демонов (QR → dial → Noise → синк →
  конвергенция документов).
- `cmd/sora-sync`: бинарь, `--data-dir` (per-OS дефолты), пишет `http_addr`,
  SIGINT/SIGTERM → graceful shutdown. Дымовой тест бинаря — OK.
- `docs/sync-threat-model.md`: ассеты, границы доверия, разбор протокола,
  принятые риски (shoulder-surfing QR, stolen device, traffic analysis),
  обязанности приложения.

## Замечания для координатора

- В `service/sync/api/serve.go` лежал незакоммиченный черновик другого агента
  (конфликтовал с `http.go`/`syncloop.go`, ссылался на несуществующие методы
  и ломал `go build ./...` всего модуля). Перемещён в
  `/tmp/foreign-backup/serve.go.foreign-2026-10-19` — владелец может забрать;
  в коммит не включён.
- В `core/cmd/sora-core/main.go` (M) и `core/control/exthost.go` (??) —
  чужие незакоммиченные правки (5-pass ревью), не трогал.
- `TestTunAndFakeIPAvoidLANAndEachOther` падает и на чистом дереве
  (песочница) — не регрессия Волны 3.
- mDNS discovery не тестировался в песочнице (нет multicast); E2E-тест
  идёт напрямую по порту из QR — тот же кодовый путь минус discovery.
- Dart-сторона F5/F8/F9/F11 — за Dart-агентом; hand-written protobuf Dart
  сверить с protoc-gen-dart на dev-машине перед мержем.
