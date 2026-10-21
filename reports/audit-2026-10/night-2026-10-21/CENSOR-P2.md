# CENSOR-P2 — транспорты WS/HTTPUpgrade/gRPC + протоколы VMess/Trojan

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`, строго локально, пуша нет.
Пины (факт бинарей в `~/workspace/.engines-amd64`): sing-box 1.14.3-lx.22,
Xray 26.10.17, mihomo 1.19.32 — совпадают с мандатом.

## Коммиты [censor]

| Коммит | Содержание |
|---|---|
| `ba6b002` | План+валидация: gRPC authority/multi-mode/user-agent и early-data header name как данные; whitelist VMess security; обязательные credential VMess/Trojan; чужие поля транспорта — отказ на уровне плана |
| `2bf2df2` | Рендереры: WS/HTTPUpgrade headers и early-data header name на всех движках; gRPC полный набор Xray, user-agent mihomo, честные отказы sing-box/mihomo + гейт каталога |
| `aad7ae3` | Парсер: legacy VMess alterId (pre-AEAD) — ErrUnsupported при импорте вместо молчаливой «модернизации» в AEAD |
| `a4344be` | Тесты: binary-приёмка рендеров на реальных пинах (sing-box check / xray run -test / mihomo -t), детерминизм рендеров, empty-vs-absent, границы |
| `df67de6` | Interop: новые traffic-кейсы + негативный контроль; ремонт cert-рига после SORA-H5 (AllowEnvBin + переименование CA-обёрток) |

## 1. Аудит параметров как данных

### WebSocket
- **Было:** sing-box рендерил только `Host` из заголовков — весь остальной
  набор `Transport.Headers` (User-Agent и др. — маскировочные данные)
  молча терялся; Xray не рендерил headers вообще; mihomo рендерил полностью.
- **Стало:** все три рендерера эмитируют полный набор; явное поле `Host`
  побеждает одноимённый заголовок (семантика mihomo, теперь единая).
  Проверено бинарями: `sing-box check` и `xray run -test` принимают рендеры.
- **Early data (0-RTT):** размер проброшен во все три движка ранее
  (`max_early_data`/`maxEarlyData`/`max-early-data`), гейт «только ws» —
  в валидации. Не хватало **имени заголовка**: добавлено поле
  `Transport.EarlyDataHeaderName` (sing-box `early_data_header_name`, Xray
  `earlyDataHeaderName`, mihomo `early-data-header-name` — все три написания
  подтверждены на пинах: sing-box check / xray run -test / mihomo -t).
  Валидация: только ws, только при EarlyData > 0, имя — валидный HTTP-токен.
  Добавлен warning-код `websocket-early-data-0rtt` (риски §3).

### HTTPUpgrade
- **Было:** sing-box и Xray роняли `Headers` (mihomo нёс через ws-opts).
- **Стало:** headers рендерятся на всех трёх; на пине sing-box поле
  `headers` у httpupgrade подтверждено `sing-box check`, у Xray —
  `xray run -test`.

### gRPC
- **Было:** только `serviceName` на всех движках.
- **Стало (данные плана):** `GRPCAuthority` (:authority), `GRPCMultiMode`,
  `GRPCUserAgent`. По факту бинарей: полный набор умеет только Xray
  (`authority`/`multiMode`/`user_agent`, `xray run -test` — OK); mihomo
  умеет `grpc-user-agent` (`mihomo -t` — OK) и **молча игнорирует**
  неизвестные YAML-ключи (проверено подстановкой мусорного ключа — тест
  проходит), sing-box не умеет ничего из трёх и неизвестные ключи
  отклоняет. Гейты: каталог `MissingFor` — authority/multi-mode
  missing на sing-box и mihomo, user-agent missing на sing-box; рендереры
  sing-box/mihomo дополнительно отказывают именованной ошибкой (backstop).
- `Service` на не-grpc транспорте, как и все gRPC-поля на не-grpc, теперь
  отказ валидации плана, а не молчаливая потеря.

### VMess
- **AEAD:** план поля alterId не имеет по дизайну; mihomo рендерит
  `alterId: 0`, sing-box/Xray — без legacy-полей. **Наследие честно
  отвергается при импорте:** классический JSON (`aid` число/строка),
  URL-форма (`?aid=`) и sing-box-JSON (`alter_id`) с alterId ≠ 0 →
  `ErrUnsupported` («legacy pre-AEAD; sora renders AEAD only»), по
  прецеденту hy2 pinSHA256.
- **Security:** валидации не было. Факт пинов: sing-box lx.22 и mihomo
  1.19.32 отклоняют всё вне {auto, aes-128-gcm, chacha20-poly1305, none,
  zero} на загрузке («unsupported security type»), включая исторический
  `aes-128-ctr`; Xray 26.10.17 принимает даже мусорное значение и молча
  откатывается. Whitelist поэтому живёт на уровне плана
  (`validVMessSecurity`), пустое значение = движковый дефолт (auto).
- **UUID:** пустой UUID VMess теперь отказ валидации (раньше — пустая
  строка в рендер и нечитаемая ошибка движка).

### Trojan
- Пустой пароль — отказ валидации. Password/SNI/транспорт-опции
  рендерятся на всех движках (SNI: mihomo — ключ `sni` для trojan,
  sing-box/Xray — TLS-блок, `needsTLS` на обоих).
- **Selftest (core/probe/trojan.go):** `ProbeTrojanFallback` реализован и
  покрыт тестами, но production-триггера нет. Минимальный честный шов —
  **эскалация, не код** (см. §5.2): нужен RPC в proto + обработчик в
  `core/control/server.go` (чужая зона, файл в списке чужого WIP) + UI.
  В этом проходе шов не тянули: полуподключённый триггер без UI —
  тот же «NOT WIRED», только дороже.

## 2. Capability-гейты (прецедент PASS3-TRANSPORT соблюдён)

Каждое поле: рендер во все движки с поддержкой; где движок не умеет —
отказ на уровне плана (каталог) + отказ рендера (backstop), не потеря.
Сводная матрица — в §6 отчёта. Runtime-пробы вместо предположений из
пинов: для каждого нового написания есть binary-тест
(`TestBinaryAcceptsCensorP2Transports` в пакетах singbox/xray/mihomo,
env `SORA_ENGINES_DIR`, skip без бинарей — паттерн binary_xhttp/mldsa).

## 3. Цензурный аспект

- WS/gRPC маскировка: headers/User-Agent теперь данные плана, доходящие
  до провода на всех движках (раньше Xray/sing-box несли голый handshake
  без UA — прямое отличие от браузера).
- Early data: первые байты аутентифицированного потока в handshake-flight
  — replay-риск и характерная форма первого полёта для entropy-эвристик
  ТСПУ-каскада (анализ 06/16КБ-энтропия). Поэтому: только opt-in данными,
  никогда дефолт, warning-код UI, имя заголовка — данными (дефолтный
  Sec-WebSocket-Protocol — самый узнаваемый вариант).
- gRPC authority/UA: расхождение authority↔SNI и дефолтный UA gRPC-стека —
  известные пассивные признаки; оба теперь управляются данными, а не
  дефолтами движка.

## 4. Interop по факту трафика

Матрица `TestEveryEngineCarriesTrafficThroughEveryTransport` (Xray-сервер,
клиенты — все три движка), добавлены: VMess+gRPC (cipher
chacha20-poly1305 — план-значение несёт нагрузку), VMess+HTTPUpgrade,
Trojan+WS, Trojan+gRPC; негативный контроль — Trojan с неверным паролем.

Результаты первого прогона: VMess ws/grpc/httpupgrade — PASS на всех
движках; wrong-trojan-password — PASS (трафик не проходит) на всех;
Trojan positive и **предсуществующие** vless-xhttp-tls-* — FAIL на всех
движках с одной причиной: `x509: certificate signed by unknown
authority` у клиента. Ручная проверка той же связки голыми бинарями
(Xray↔Xray trojan-ws, тот же сертификат/SNI, SSL_CERT_FILE) — 200 OK.

Причина — регрессия тестового рига от чужого хардненинга SORA-H5, в
два слоя: (1) `supervise.Discover` стал honor'ить `SORA_*_BIN` только
при `DiscoveryOptions.AllowEnvBin`, а interop-тесты его не выставляли;
(2) обёртка-скрипт с именем ровно «xray»/«sing-box»/«mihomo» не
проходит digest-сверку `checkDigestPath` (манифест знает это имя и
ждёт дайджест настоящего бинаря) — кандидат молча отбрасывался в
пользу голого бинаря без CA. REALITY-кейс (CA не нужен) продолжал
проходить и маскировал поломку. Фикс в риге (коммит `df67de6`):
`AllowEnvBin: true` в обоих `registry.Discover` матричного теста;
обёртки TrustCertificate переименованы в `<engine>.sora-ca-wrapper`
(имя манифест не клеймит, explicit-trust путь документирован в
checkDigestPath). Итог после фикса: **sing-box и mihomo — все кейсы
PASS** (trojan-ws, trojan-grpc, xhttp-tls-auto, wrong-trojan-password);
**xray — остаточный FAIL** тех же cert-кейсов (по-прежнему x509 в
логе клиента): при этом (а) голыми бинарями та же связка работает
(200), (б) discovery с AllowEnvBin обёртку выбирает (отдельная проба:
path=wrapper, version 26.10.17), (в) sing-box/mihomo через тот же
механизм починились. Остаток — эскалация владельцам xray-драйвера/
рига: похоже, xray-процесс в матричном тесте стартует не тем Binary,
что выбрал registry, либо его supervise-путь теряет env-обёртку;
мои транспортные рендеры для xray при этом доказаны `run -test` и
ручным трафиком. Та же латентная проблема opt-in —
в `core/engine/interop/hy2tuic_test.go` (чужой файл, не трогал):
его TLS-кейсам нужны AllowEnvBin в его Discover-вызовах.

## 5. Эскалации

### 5.1 Headers не доезжают от импорта до плана
`Transport.Headers` — данные уровня плана, но ни proto-контракт, ни
credential document (`core/control/plan.go`) поля headers не несут:
импортированная подписка не может передать WS-заголовки в план вообще.
Рендереры теперь честны, но источник данных — только прямой план.
Нужно решение владельца/контрольного отдела: поле в credential document
(без смены proto — как download_address) — вне зоны CENSOR-P2 и в файле
чужой активной работы.

### 5.2 Trojan selftest — минимальный шов
1) proto: `CheckTrojanFallback(server_id) -> {ok, summary, results[]}`
   в core_control.proto; 2) control: обработчик вызывает
   `probe.ProbeTrojanFallback(ctx, host:port выбранного Trojan-сервера)`;
   3) Dart: пункт в чеклисте сервера. Файл обработчика —
   `core/control/server.go` (чужой WIP по мандату) — не тронут.

### 5.3 gRPC timeouts sing-box
sing-box gRPC несёт `idle_timeout`/`ping_timeout`/`permit_without_stream`
(подтверждено check на пине), Xray — `idle_timeout`/`health_check_timeout`/
`initial_windows_size`. В план не добавлялись: мандат называет
serviceName/multi-mode/authority; inventing дефолты = магия. Если владелец
захочет — поля добавляются тем же паттерном (данные + гейты по факту).

## 6. Матрица полей (итог)

| Поле | sing-box lx.22 | Xray 26.10.17 | mihomo 1.19.32 |
|---|---|---|---|
| WS path/host/headers | ✅ (headers были потерей) | ✅ (были потерей) | ✅ |
| WS early-data + header name | ✅ | ✅ | ✅ |
| HTTPUpgrade path/host/headers | ✅ (headers были потерей) | ✅ (были потерей) | ✅ (ws-opts) |
| gRPC serviceName | ✅ | ✅ | ✅ |
| gRPC authority / multi-mode | ❌ гейт+отказ | ✅ | ❌ гейт+отказ |
| gRPC user-agent | ❌ гейт+отказ | ✅ | ✅ |
| VMess security whitelist | план | план (движок молча принимает мусор) | план |
| VMess alterId ≠ 0 | отказ импорта | отказ импорта | отказ импорта |
| Trojan password/SNI | ✅ | ✅ | ✅ |

## 7. Мелочи (стандарт владельца)

1. **Границы:** EarlyData 0 = ключ отсутствует во всех рендерах (пины
   per-engine тестов d24 + CensorP2); отрицательный — отказ валидации;
   верхняя граница планом не выдумывается (см. §7.3); 1 MiB проходит
   данными насквозь (тест). Path 1025 байт и Host 253 байта (максимум
   DNS-имени) — проходят без усечения (тест). Пустой serviceName ≠
   отсутствующий в рендере нет: оба — ключ опущен на всех движках
   (тесты per-engine), семантика «дефолт движка» при этом едина.
2. **Детерминизм:** повторный рендер плана с 4 заголовками —
   байт-идентичен на всех трёх движках (тесты per-engine; JSON-маршал
   сортирует ключи map, yaml mihomo — тоже).
3. **Тайминги:** новых тайминг-констант проход не вводит. Единственное
   «число» зоны — граница early-data — сознательно НЕ введена: пины
   принимают ≥1 MiB (Xray, sing-box check), sing-box — 16 MiB; выдуманный
   лимит плана был бы магией без источника. Таймауты gRPC — §5.3.
4. **Логи/ошибки:** новые ошибки следуют существующим форматам
   («outbound %s: … needs the grpc transport», «<engine>: … Xray-only»),
   не содержат credentials (пароли/UUID в тексты не попадают — поля
   authority/UA/service это конфигурация пользователя, не секреты и не
   цели сверх уже имеющихся в плане идентификаторов сервера).

## 8. Финальная верификация

`go build ./...` (core) — чисто в worktree; `go vet` по engine/parser/
probe/enginetest/interop — чисто. Тесты: parser, probe, singbox, xray,
mihomo — ok (включая все три binary-теста на реальных пинах и все
CensorP2-кейсы); engine — все мои тесты (7 групп: валидация, гейты
каталога, границы, warnings) PASS, единственный FAIL пакета —
`TestSelectEngineProbedPrefersFact` из probecaps_test.go (чужой отдел
FP, environment-чувствительная проба ECH, к транспортам P2 не
относится). Interop: VMess все комбо + Trojan sing-box/mihomo +
негативные контроли PASS; xray cert-кейсы — эскалация §4.

## 9. Инцидент с общими файлами (честно)

Коммиты `ba6b002` и `2bf2df2` делались temp-index'ом по целым файлам.
Между началом прохода и коммитами соседние отделы успели внести в **те
же файлы** (engine/validate.go, catalog.go, singbox/render.go,
xray/render.go, mihomo/config.go, mihomo/proxy.go) свой незакоммиченный
WIP (SS method/plugin гейты, TUIC effective congestion/heartbeat,
Hy2Obfs, RealityMLDSA65 и др.), и `git add <file>` включил эти ханки в
мои коммиты. Контент не потерян и в worktree всё собирается; но HEAD сам
по себе временно не собирается, пока отделы-владельцы не закоммитят свои
завершающие файлы. Точный список недостающих в HEAD символов (проверка
чистым worktree от HEAD 75fbfd8b, `go build ./...`): FeatureHy2Obfs
(engine.go), MaxHy2BandwidthMbps, MinHy2HopIntervalSeconds, ValidHy2Obfs
(quic_defaults.go), SupportsShadowsocksMethod, SupportsSSPlugin
(ss_support.go / ss_plugin.go) — все определены в общем worktree.
По AGENTS.md историю при грязном дереве и коммитах соседей не
переписываю; repair-forward (снос чужих ханков) сломал бы уже лёгшие
поверх коммиты соседей (44859a82 и далее). Парсерный коммит после
инцидента сделан уже отфильтрованным патчем только своих ханков
(проверено: чужие MLDSA-ханки остались в worktree незакоммиченными).
Прошу координатора подтвердить владельцам ханков, что их код в HEAD —
под чужим сообщением коммита.
