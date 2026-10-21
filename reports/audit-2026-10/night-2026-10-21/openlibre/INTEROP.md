# OpenLibre / olcrtc — interop: фактический трафик против референса

Подотдел interop, департамент OpenLibre. Стенд: `~/workspace/openlibre-ref/interop/`
(вне репозитория sora; код sora не менялся — `git status` чист; бинарь sora-core
собран из чекаута в состоянии ed7fed36 на старте задачи; по ходу стенда ветку
`bugfix/audit-2026-10-19` параллельные отделы продвинули до c93f37d — стенд
файлов репозитория не трогал).

## Итог одной строкой

Сквозной трафик через настоящий SFU в этой песочнице **не поднялся ни по одному
провайдеру — по трём независимым, измеренным свойствам среды** (не по дефектам
sora или olcrtc): (1) эгресс-прокси песочницы обслуживает GET, но **зависает на
любых POST и на WebSocket-Upgrade** — сигналинг jitsi/telemost/wbstream мёртв;
(2) **UDP запрещён на уровне ядра, включая loopback** (`sendto: operation not
permitted`) — WebRTC-медиа невозможно ни к одному SFU; (3) прямой эгресс без
прокси перехватывается (TLS ломается). Всё, что от среды не зависит, проверено
фактически и в основном зелёно: туннельный слой пина несёт сверенный трафик
(32 МиБ эха байт-в-байт), sora импортирует ссылку, рендерит сайдкар, проходит
digest-ворота, честно и быстро падает на сетевой стадии, переживает рестарт
ядра с байт-идентичным конфигом сайдкара; все негативные ворота sora —
fail-closed вживую. Замеры join/пропускной на живом провайдере остаются
открытым риском TRANSPORT.md — их честно нельзя снять здесь, команды для
dev-машины — в §7.

## 1. Стенд и хэши

Все olcrtc-роли (референс cnc, референс srv, сайдкар sora) — **один и тот же
бинарь**, собранный из архива тега v0.0.1 ровно путём `packaging/engines/fetch.sh`
(`CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" ./cmd/olcrtc`):

| Артефакт | SHA-256 |
|---|---|
| Архив `v0.0.1.tar.gz` (GitHub) | `acaaee246e876aed83fd6a21f77c1ff7a8093584ee5a36453ab1803f9a2bcca7` — совпал с `engines.lock` |
| `olcrtc` (сборка стенда; cnc+srv+сайдкар) | `cc95af7b8b7f105331463e2a83cdc0c618c606ec67ceb16a51de82f32779ff3c` |
| `sing-box` 1.14.3-lx.22 (архив сверен с lock: `1c827252…`) | бинарь `fb982d22f3a2171d7fb3a93209bb88a6d097af2c9cde736c300f460dea28d6ac` |
| `livekit-server` 1.13.10 (локальный SFU стенда) | `9aab8bee073c67e75691a6e88c881eec339c646e17cd6228177a92fe90cc1f19` |
| `sora-core` (сборка стенда из ed7fed36) | `1dec3f38bee6806cf5845e7f72631f0d34a4c8426bfb671cac1c253829b11c3d` |

Несовпадение хэша бинаря olcrtc между сборками ожидаемо (TRANSPORT.md §4: пин
стоит на архиве исходников, digest бинаря — факт сборки в `engines.digests`;
стенд сгенерировал свой `engines.digests` тем же `sha256sum`-путём).

Целевая «мишень»: локальный HTTP-сервер (`interop/run/target.py`, loopback):
GET отдаёт детерминированное тело 64 КиБ (SHA-256
`978b568d649dac256bf0d1ab835944299ea032c8c5a46f4a115cfaf3d325f938`), POST `/echo`
возвращает тело байт-в-байт, каждый хит пишется в лог — попадание запроса в
мишень доказуемо независимо от ответа клиенту.

Замечание о референсном чекауте: `~/workspace/openlibre-ref/olcrtc` стоит на
HEAD f3ad8fb, а не на теге. Стенд везде использовал **распакованный архив тега**
(`interop/src/olcrtc-v0.0.1`) — и для бинарей, и для e2e-тестов пина.

## 2. Диагностика среды (измерено, логи: `interop/logs/netprobe.log`, `logs/probe`)

| Путь | Результат |
|---|---|
| HTTPS GET через эгресс-прокси (config.js jitsi-хостов и др.) | работает (200, ~0.1–2.3 с) |
| HTTPS POST через прокси | **зависает без ответа** — `example.com`, `postman-echo.com`, `httpbingo.org`, `/http-bind` четырёх jitsi-хостов; Go-зонд тем же стеком, что olcrtc (`protect.NewHTTPClient`, `ProxyFromEnvironment`): `context deadline exceeded` на 20 с |
| WebSocket-Upgrade через прокси (`wss://…/xmpp-websocket`, coder/websocket — та же библиотека, что у `j`) | **зависает на рукопожатии** (deadline 20 с); голый GET того же URL отдаёт страницу Prosody мгновенно |
| Прямой HTTPS без прокси | TLS ломается мгновенно: curl exit 35; под sora — `tls: first record does not look like a TLS handshake` |
| UDP, любой адрес, включая `127.0.0.1` | `sendto: operation not permitted` (Errno 1) — python-зонд и логи pion обеих сторон |
| TCP loopback | работает |

Следствия по провайдерам:

- **jitsi**: сигналинг = WS, запасной = BOSH (POST) — оба пути мертвы в прокси.
  Дымовой прогон транспорта («клиент дошёл до join в MUC») в текущем состоянии
  песочницы **не воспроизводится**: обе стороны умирают на
  `bosh init: Post "https://meet.handyweb.org/http-bind": timeout awaiting response headers`
  после отвисшего WS (`interop/logs/s1-jitsi-{srv,cnc}.log`).
- **wbstream**: REST-флоу — POST (`internal/auth/wbstream/api.go`) — мёртв.
  Плюс комнаты/токена модератора у стенда нет и выдумывать нечего.
- **telemost**: `Issue` — GET, но медиа-движок Goolom — WebRTC: сигналинг WS +
  медиа UDP — мертво дважды; готовой комнаты telemost у стенда нет.
- **none/direct + локальный LiveKit**: сигналинг WS на 127.0.0.1 идёт мимо
  прокси (`no_proxy`) и **работает**; медиа упирается в запрет UDP (ниже).

WebRTC-медиа, добивание темы: клиенты на pion (owenlivekit SDK 2.18.2) собирают
**только UDP host-кандидаты** — TCP-кандидатов в pinned-стеке нет (нет ICE TCP
mux, `SetNetworkTypes` не расширяется), серверный `tcp4 host 127.0.0.1:7881`
остаётся без пары. Встроенный TURN LiveKit без TLS-сертификатов рекламируется
только как `turn:…:3478?transport=udp`; TURN/TCP в любом случае оставил бы
UDP-лег между TURN и SFU. То есть в этой песочнице медиа не существует ни в
одной конфигурации пина — это свойство среды + транспортных дефолтов upstream,
не дефект: на обычной сети UDP разрешён и схема стандартна.

## 3. Матрица сценариев

Обозначения: ✅ факт получен; 🟡 получен по слоям/частично (среда отрезала
следующий слой); ⛔ заблокировано средой (не дефект); 🚫 отказ по дизайну,
проверен вживую.

| # | Сценарий | Вердикт | Ключевой факт |
|---|---|---|---|
| S1a | Реф↔реф, jitsi+datachannel, публичный `meet.handyweb.org` | ⛔ среда | Обе стороны: WS завис → BOSH POST завис → `timeout awaiting response headers` (~21 с srv, ~22 с cnc) |
| S1b | Реф↔реф, локальный LiveKit (none/direct) | 🟡 | Сигналинг и комната — ✅ (SFU-лог: srv и cnc в одной комнате, SDK protocol 17, гранты верные); медиа — ⛔ ICE: все UDP `sendto EPERM`, `could not connect after timeout` (~5 с) |
| S1c | Туннельный слой пина (upstream e2e, in-process транспорт) | ✅ | См. §4: SOCKS→handshake→crypto→srv-эхо, 32 МиБ сверено |
| S2 | Sora end-to-end по импортированной ссылке | 🟡 | Импорт→план→digest-ворота→рендер YAML→запуск сайдкара — ✅ вживую; трафик — ⛔ на стадии join (два разных сетевых отказа, §5) |
| S3 | Транспорты vp8/sei/video через LiveKit | 🟡 | Все три: пара в одной комнате SFU (лог), дальше ⛔ тот же ICE/UDP |
| S4a | Неверный ключ (реф↔реф, LiveKit) | 🟡 | Пара в одной комнате; туннель не встал; **отличить стадию handshake от ICE здесь нельзя** — среда режет раньше. Честный разбор — на dev-машине (§7) |
| S4b | Мёртвая комната (cnc в другой комнате) | ✅ как негатив | SFU-лог: srv в `interop-s4-deadroom`, cnc в `interop-dead-s4-deadroom`; peer не появился, слушателя нет, трафика нет |
| S4c | Подменённый сайдкар (digest mismatch) | ✅ | `core.engine.binary_missing` за 13 мс, процессов сайдкара: 0, сессия не тронута |
| S4d | wbstream+datachannel без токена | ✅ | `core.olcrtc.token_required` за 9 мс, до запуска сайдкара |
| S4e | (бонус) provider none из ссылки; telemost+datachannel | 🚫✅ | `core.olcrtc.not_connectable` (8 мс); `core.olcrtc.combination_unsupported` (12 мс) |
| S5 | Рестарт ядра, подключение из vault без повторного импорта | ✅ в доступной части | §6: YAML сайдкара после рестарта байт-идентичен (норм.), стадия отказа та же |

## 4. S1c — туннель пина несёт трафик (факт)

На распакованных исходниках тега v0.0.1 прогнан собственный e2e-набор
upstream (`go test ./internal/e2e/ -count=1`, пакет `ok`, 61.9 с;
лог `interop/logs/e2e-memory.log`). Транспорт там заменён in-process
реализацией `engine.Session` по конструкции самих тестов — это **не** SFU-медиа,
а полный стек выше него: `session` → handshake (CLIENT_HELLO/SERVER_WELCOME,
OLC2) → crypto → smux → SOCKS (cnc) → dial (srv):

- `TestClientServerSOCKSTunnelOverMemoryDatachannel` — PASS: эхо через
  SOCKS-туннель сверено байт-в-байт.
- `TestLargeTransferOverTunnel` — PASS: **32 МиБ** потокового паттерна через
  туннель, сверка по смещениям; время теста 0.53 с (≈60 МиБ/с — потолок
  in-process транспорта, НЕ пропускная SFU; живую пропускную снять негде).
- `TestFrequentReconnectsStillAllowNewSOCKSConnections` — PASS (61.3 с):
  5 реконнектов, новые SOCKS-подключения после каждого несут эхо.
- `TestSupervisorFailoverProfilesReachWorkingSOCKS`, `TestEndedCallbackStopsClientAndServer` — PASS.
- `TestDeadLinkDetectionWindow`, `TestLocalThroughputSoak` — SKIP по собственным
  флагам upstream (`-olcrtc.deadlink`, `-olcrtc.local-soak`); не включал: soak —
  длительный, deadlink меряет окно детекта на том же in-process транспорте,
  к вопросу interop ничего не добавляет.

Вывод слоя: связка cnc↔srv пина корректна и трафиконосна; недоказанным в
песочнице остаётся только WebRTC-лег (SFU), который среда запрещает физически.

## 5. S2 — sora вживую: что именно произошло

Стенд: настоящий `sora-core` (бинарь выше) + `soractl` (тонкий клиент
контрол-плоскости стенда, `interop/src/soractl/`), engines-dir стенда
(`sing-box` + `olcrtc` + `engines.digests`), режим `TUNNEL_MODE_APPLICATION`
(TUN не нужен: локальный mixed-прокси ядра на `-tunnel-port`), план правится
только клиентскими полями (Routing/DNS/LocalProxy/`NetworkControlAllowed`),
аутбаунд — из `ParseImport` как есть.

Ссылка: `olcrtc://jitsi?datachannel@https://meet.handyweb.org/olcrtc-interop-13ebd534#<ключ стенда>$interop-stand`
(та же комната и ключ, что S1a).

1. `ParseImport` — ✅: аутбаунд `olcrtc…:da9c71380b9097c4`, протокол `olcrtc`,
   транспорт `datachannel`, vault-ref `s1_22ee5fb67d0022edbaa99ea7abb35a3a`.
2. `Connect` — план прошёл селекцию (sing-box), digest-ворота сайдкара открылись,
   `olcwrap` отрендерил YAML (перехвачен в полёте, `interop/logs/sidecar-run1.yaml`):
   `mode: cnc`, провайдер/комната/ключ — дословно из ссылки, `net.dns: 198.19.0.1:53`
   — из плана (не дефолт 8.8.8.8), SOCKS — loopback + эфемерные креды.
3. Сайдкар стартовал и умер на join за **157–275 мс**:
   `client: failed to connect link: … Get "https://meet.handyweb.org/xmpp-websocket?room=…": tls: first record does not look like a TLS handshake`.
   Ядро вернуло `UNAVAILABLE / core.engine.start_failed` с текстом сайдкара в
   деталях, статус сессии — `FAILED`, прямого протекания нет (fail-closed).
4. Почему отказ другой, чем у автономного бинаря (висел на прокси): под ядром
   сайдкар получает `supervise.SafeEnv()` — окружение **без прокси-переменных**
   (by design, `core/engine/supervise/host.go:105`), поэтому идёт напрямую и
   умирает на перехвате прямого TLS мгновенно. На обычной сети прямое
   соединение — корректное поведение; в песочнице оба пути мертвы по разным
   причинам среды.

Дефекта sora здесь нет: вся цепочка «импорт → vault → план → реестр →
сайдкар → провайдер» отработала, отказ — сетевой, честный, быстрый.

Наблюдение отделу оформления (не дефект транспорта): ворота подключения
(`token_required` и др.) на проводе приходят завёрнутыми — верхний
`UserMessageKey` = `core.plan.outbound
...[truncated 5845 chars]s_invalid` (wire-код `SORA_ERROR_CODE_INVALID_ARGUMENT`), а конкретный ключ и его код словом (`failed_precondition core.olcrtc.token_required: …`) живут внутри `DetailRedacted`. Локализация по верхнему ключу покажет общую ошибку плана вместо конкретной причины; стоит ли доставать вложенный ключ наверх — решение отдела оформления/контракта, фиксирую как наблюдение по факту стенда.

## 6. S5 — рестарт ядра и vault

`interop/run_sora1.sh`, фаза RUN 2: ядро остановлено и поднято заново на том же `-data-dir`; повторного `ParseImport` не было — тот же файл плана (только credential-references) подан в `Connect`:

- план построился из secret store (без vault это был бы отказ по отсутствующей ссылке);
- YAML сайдкара перехвачен повторно: после нормализации эфемерных полей (SOCKS-порт, user/pass слушателя) — **байт-идентичен** YAML первого запуска (проверка в скрипте: `SIDECAR_YAML_STABLE_ACROSS_RESTART yes`; хэши файлов: run1 `555b5241…`, run2 `54076ad6…` — различаются только эфемерными полями);
- подключение дошло до той же стадии join и упало тем же честным `core.engine.start_failed` (другой display-nick в логе сайдкара — процесс действительно новый).

Итог: vault round-trip вживую замкнут — импорт один раз, рестарт, подключение без повторного импорта. Трафиковая часть S5 наследует блокировку S2.

## 7. Замеры

| Замер | Значение | Комментарий |
|---|---|---|
| Join до слушателя сайдкара на живом провайдере (риск TRANSPORT.md) | **не измерен** | слушатель открывается после туннельного handshake; среда режет раньше (сигналинг/ICE). Остаётся открытым риском, кап готовности в `olcwrap` — 30 с |
| Сигналинг-join локального LiveKit | ~0,4–1,9 с | по SFU-логу: старт сервера → сессия srv; обе стороны в комнате за ≤2 с от старта процессов |
| MUC-join публичного jitsi | не завершился | ≥20 с (зонд, deadline) / ~21 с до BOSH-таймаута у бинаря |
| Sora Connect → отказ сайдкара на join | 137–275 мс | быстрый отказ прямого TLS под `SafeEnv` |
| Ворота sora (token_required / not_connectable / combination / binary_missing) | 8–13 мс | до любого сетевого действия |
| Пропускная на эхо-потоке через SFU | **не измерена** | медиа недостижимо; in-process потолок туннеля — §4 (32 МиБ за 0,53 с теста) — это не SFU-цифра и как SFU-замер не подаётся |

## 8. Дефекты

Дефектов sora стенд не вскрыл. Дефектов пина v0.0.1 стенд не вскрыл (его собственный e2e-набор на тег-исходниках зелёный в доступной части). Все красные точки выше — среда песочницы (прокси POST/Upgrade, запрет UDP, перехват прямого TLS) и один by-design отказ sora (provider `none` из ссылки), который и должен был отказать.

Несостыковка на заметку: дымовой результат транспортного отдела («настоящий бинарь пина дошёл до join в MUC») в текущем состоянии песочницы не воспроизводится — сигналинг умирает раньше MUC. Это дрейф состояния среды между прогонами, а не чья-либо ошибка в коде; на dev-машине проверяется первым же запуском §9.

## 9. Повторение на dev-машине (нормальная сеть: UDP разрешён, эгресс без POST-фильтра)

Стенд целиком лежит в `~/workspace/openlibre-ref/interop/` и параметризуется комнатой/ключом (`run/key.txt`, `run/room.txt`).

1. Публичный SFU (главный недостающий прогон):
   - выбрать живой инстанс из `olcrtc/docs/jitsi.instances.yaml` (на стенде отвечали по config.js: meet.egovm.ru, meet.mamba.group, meet.mirox.chat, conf.expressmoney.com, m.catonmoon.com, meet.riddlerx.org, meet.handyweb.org, meet.jit.si);
   - srv: `bin/olcrtc run/srv.yaml` (mode srv, та же комната/ключ), cnc: `bin/olcrtc run/cnc.yaml`;
   - трафик: `curl -x socks5h://127.0.0.1:18080 http://127.0.0.1:18741/body` при поднятой мишени (`python3 run/target.py 18741`), сверка SHA-256 тела и POST-эха как в `run_pair.sh` — скрипт `run_pair.sh` надо лишь переключить с LiveKit-YAML на jitsi-YAML (готовые `run/srv.yaml`/`run/cnc.yaml` в стенде уже лежат);
   - замерить: время от старта cnc до открытия SOCKS-слушателя (join), пропускную на 4 МиБ эхе — обе цифры ждёт TRANSPORT.md.
2. Sora end-to-end: `bash run_sora1.sh`, но ссылка — на ту же живую комнату; ожидается `CONNECT OK`, затем `curl -x http://127.0.0.1:18081 http://127.0.0.1:18741/body` (tunnel-port ядра) со сверкой тела; RUN 2 тем же скриптом замыкает S5 уже с трафиком.
3. Транспорты: `run_pair.sh vp8channel|seichannel|videochannel` против jitsi той же парой YAML (секции транспортов в скрипте уже есть); у jitsi datachannel данные идут через colibri-ws — проверить отдельно, что на инстансе без colibri-ws datachannel честно не встаёт.
4. Негативы с различением стадий: неверный ключ (handshake должен отклонить после установления медиа — слушателя нет, в логе srv нет сессии), мёртвая комната (нет peer), wbstream+datachannel с модераторским токеном (нужен реальный аккаунт — владельцу).
5. Что в песочнице не поднималось в принципе: TUN-целиком (нет /dev/net/tun и привилегий) — sora в `TUNNEL_MODE_SYSTEM` + kill-switch; Windows (бинарь пина кросс-собирается fetch.sh, WebRTC на Windows не подтверждён — риск R3 TRANSPORT-ANALYSIS).

## Приложение. Файлы стенда

- `interop/bin/` — olcrtc (пин), livekit-server, sora-core, soractl, probe (WS/BOSH-зонд).
- `interop/engines/` — sing-box + olcrtc + `engines.digests` для ядра.
- `interop/run_all.sh`, `run_pair.sh` — референсные пары (LiveKit none/direct; транспорты и негативы параметрами).
- `interop/run_sora1.sh` — S2+S5; `run_sora2.sh` — негативы sora (S4c/d/e).
- `interop/run/` — YAML-конфиги, мишень, планы (proto), livekit.yaml (node_ip 127.0.0.1, TURN — §2).
- `interop/logs/` — все логи прогонов: `netprobe.log`, `e2e-memory.log`, `s1-jitsi-*.log`, `s1-dc-*.log`, `s3-*.log`, `s4-*.log`, `livekit.log`, `run_sora1.log`, `run_sora2.log`, `sidecar-run{1,2}.yaml`.
- `interop/src/` — архив и дерево тега v0.0.1, исходники probe и soractl.
