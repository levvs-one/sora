# 61. OONI: API, тесты обхода цензуры, риск-скор протоколов по стране

Дата: 2026-10-20. Группа G, третий проход (углубление WEB-RESEARCH, не дубль).

## Первоисточники

- OONI backend: `ooni/backend`, сервис `oonimeasurements` — роутеры `routers/data/aggregate_observations.py`, `aggregate_analysis.py` (ClickHouse-агрегации).
- OONI Probe CLI: `ooni/probe-cli` — `internal/experiment/vanillator` (тест `vanilla_tor`), `internal/experiment/tor`, `torsf`, `psiphon`, `openvpn`; реестр групп `cmd/ooniprobe/internal/nettests/groups.go`.
- Спеки тестов: `ooni/spec` — `nettests/ts-016-vanilla-tor.md`, `nettests/ts-040-openvpn.md`.
- Go-пакеты: `pkg.go.dev/github.com/ooni/probe-cli/v3/.../ooapi/apimodel`, `.../engine/probeservices`.
- Доки OONI Explorer / MAT (Measurement Aggregation Toolkit).

## 1. API: что есть на самом деле

Базовый хост: `https://api.ooni.io`.

**Классический v1 (стабильный, документирован через код probe-cli):**
- `GET /api/v1/measurements` — метаданные измерений. Фильтры: `probe_cc`, `test_name`, `since`, `until`, `probe_asn`, `input`, `category_code`, `anomaly`, `failure`, `confirmed`.
- `GET /api/v1/measurement_meta?report_id=...&full=...` — одна запись: `anomaly`, `confirmed`, `failure`, `scores`, `test_name`, `probe_cc`, `probe_asn`, `measurement_start_time`, `raw_measurement` (опционально).
- `GET /api/v1/files` — ссылки на сырые JSON-файлы измерений.
- Служебные probe-сервисы (`/api/v1/check-in`, `/register`, `/login`) — для самих проб, не для чтения данных.

**Новый агрегационный слой (`/v1/aggregation`, ClickHouse, для дашбордов и аналитики):**
- `GET /v1/aggregation/observations` — группировка сырых наблюдений из таблицы `obs_web` по измерениям: `timestamp`, `failure` (классифицированные типы вроде `dns_isp.nxdomain`, `tcp.timeout`), `hostname`, `ip`, `probe_cc`, `probe_asn`, `test_name`.
- `GET /v1/aggregation/analysis` — анализ вероятности цензуры с векторами blocking probability.
- Гранулярность времени: `hour` / `day` / `week` / `month` / `year` / `auto` (дефолт day).
- Фильтры общие: `probe_cc`, `probe_asn` (принимает `AS197207`), `hostname`, `domain`, `input`, `test_name`, `since`, `until`.

Для риск-скора протоколов достаточно классического `/api/v1/measurements` с фильтром `test_name` + `anomaly=true`, либо агрегаций. Агрегации легче для трендов, классика — для точных долей.

## 2. Тесты обхода цензуры: реальные имена и что они меряют

| test_name | Что меряет | Спека |
|---|---|---|
| `vanilla_tor` | Bootstrap обычного Tor-клиента (без PT). Успех = bootstrap ≤300 c. TestKeys: `bootstrap_time`, `failure`, `success`, `timeout` | ts-016-vanilla-tor.md; `internal/experiment/vanillator` |
| `tor` | Достижимость Tor (директории/OR) | probe-cli |
| `torsf` | Bootstrap Tor через Snowflake | probe-cli `internal/experiment/torsf` |
| `psiphon` | Bootstrap Psiphon-клиента | probe-cli |
| `openvpn` | Handshake OpenVPN через `minivpn` (tracer `vpntracex`) | ts-040-openvpn.md |
| `riseupvpn` | RiseupVPN | probe-cli |
| `sni_blocking`, `echcheck`, `stunreachability`, `tcpping`, `tlsping`, `dnsping` | Низкоуровневые зонды | registry |

Группировка в CLI (`groups.go`): `circumvention` = {Psiphon, Tor}; `experimental` = {OpenVPN, TorSf, VanillaTor, STUNReachability}.

**Важное уточнение к постановке:** теста `lantern` в OONI **нет** (в probe-cli его не существует; упоминания Lantern в блогах — про ручные проверки, не nettest). Риск-скор строим только по реально существующим: `vanilla_tor`, `tor`, `torsf`, `psiphon`, `openvpn`, `riseupvpn`. Не выдумывать `lantern` в коде — иначе запросы вернут пусто и скор будет молча нулевым.

## 3. Как строить риск-скор протоколов по стране

Формула (честная, воспроизводимая):

```
для test_name T, страны CC, окна W=30 дней:
  total   = count(measurements, probe_cc=CC, since=now-30d)
  blocked = count(measurements, probe_cc=CC, anomaly=true)
  score_T = blocked / max(total, N_min)   # N_min=20, иначе "недостаточно данных"
риск_протокола = score_T, взвешенный по числу ASN (покрытие сетей)
```

Детали, которые решают:
- Фильтровать `failure=true` отдельно: сбой измерения ≠ блокировка. OONI различает `anomaly` (признак цензуры) и `failure` (ошибка теста). Смешивание — классическая ошибка.
- Считать не только по стране, но и по `probe_asn`: в РФ блокировки сильно различаются между провайдерами. Скор «по стране» — медиана по ASN с весом по числу измерений.
- Учитывать `confirmed` (автоподтверждённые блокировки, напр. блок-страница) как вес ×1.5.
- Использовать `measurement_start_time`, не время загрузки.
- Задержка данных OONI — часы/дни; для «свежести» показывать `as_of`.

## 4. Офлайн-снапшот (api.ooni.io могут блокировать)

Риски реальные: домен `api.ooni.io` ходит по HTTPS с открытым SNI; цензор может резать точечно. Стратегия для sora:

1. **Снапшот в поставке.** JSON `ooni_risk_snapshot.json`: `{cc, test_name, score, asns_covered, measurements, as_of}` для топ-20 стран sora (RU, BY, KZ, UA, IR, CN, TM, ...). Обновляется релизным пайплайном (ночной джоб → коммит артефакта), не руками.
2. **Фоновая синка в core.** Раз в 24 ч (и при смене страны/провайдера) дергать `/api/v1/measurements` за последние 30 дней по 6 тестам. Кэш в локальной БД с TTL.
3. **Фолбэки по цепочке:** прямое HTTPS → через активный VPN-туннель sora (если подключён) → через Tor/Snowflake (torsf — ирония в тему) → стоп, работаем на снапшоте.
4. **Честность UI:** всегда показывать `as_of` и бейдж «данные за N дней / офлайн-снапшот». Скор без даты — слоп.

## Вердикт «лучшее или слоп»

**Лучшее:** сам подход — внешний, независимый, воспроизводимый источник правды о блокировках протоколов. OONI-данные публичны, методология открыта, спеки тестов читаемы. Риск-скор по `anomaly`-доле — честная метрика, а не «наш внутренний индекс».

**Слоп, которого избегать:** (а) скор без указания окна/покрытия ASN; (б) смешивание `failure` и `anomaly`; (в) «живой» скор, который при блокировке api.ooni.io молча показывает нули — обязательно явный стейл-бейдж; (г) выдуманный тест `lantern`.

## Рекомендация «внедрить так»

1. В sora-core: модуль `ooni` — клиент `/api/v1/measurements` + `/v1/aggregation/analysis`, модель риск-скора (формула выше), SQLite-кэш, фолбэк-цепочка.
2. Встроенный снапшот `assets/ooni_risk_snapshot.json`, генерируемый CI-джобом.
3. UI «Censorship Meter»: для страны пользователя — таблица протоколов (Tor, Snowflake, Psiphon, OpenVPN, RiseupVPN) со скором блокировки, покрытием ASN и датой. Скор кормит автовыбор протокола (низкий риск + speedtest = кандидат).
4. Не запускать собственные тесты OONI из клиента (лишний трафик, вопросы приватности) — только читать агрегаты.
