# Final Audit — подкоманда №6: тесты, полный прогон и триаж

Дата: 2026-10-20. Дерево грязное чужим WIP (shared branch `bugfix/audit-2026-10-19`); дерево НЕ трогалось,
коммитов не делалось (фиксов не потребовалось — см. триаж).

Окружение всех прогонов: `TMPDIR=$HOME/workspace/.build-tmp GOCACHE=$HOME/workspace/.gocache-v`,
бинарь `~/workspace/go/bin/go`, Go 1.24.7 linux/amd64.

## 1. Сводные прогоны

### sora/core (46 пакетов, 208 test-файлов, ~1270 top-level Test-функций)

| Шаг | Результат |
|---|---|
| `go build ./...` | ✅ чистый (exit 0) |
| `go vet ./...` | ✅ чистый (exit 0) |
| `GOOS=windows go build ./...` | ✅ чистый, без CGO (exit 0) |
| `go test ./...` | ⚠️ 36 ok / 9 без тестов / **1 красный пакет** |

Единственное падение: `control` → `TestDetectCensorshipEventsWithoutOffsetsStayUnknown`:
```
censor_test.go:210: Listen() error = internal core.internal.unexpected:
listen unix /home/hatch/workspace/.build-tmp/TestDetectCensorshipEventsWithoutOffsetsStayUnknown2194744261/001/core.sock: bind: invalid argument
```

### service/sync (6 пакетов, 37 Test-функций)

| Шаг | Результат |
|---|---|
| `go build ./...` | ✅ |
| `go vet ./...` | ✅ |
| `go test ./...` | ✅ все зелёные: api, pairing, sync, transport ok; cmd/sora-sync, discovery — без тестов |

### sora-legacy/core (29 пакетов, 81 test-файл, ~377 Test-функций)

| Шаг | Результат |
|---|---|
| `go build ./...` | ✅ |
| `go vet ./...` | ✅ |
| `GOOS=windows go build ./...` | ✅ чистый, без CGO (exit 0) |
| `go test ./...` | ⚠️ 24 ok / 4 без тестов / **1 красный пакет** |

Единственное падение: `engine` → `TestTunAndFakeIPAvoidLANAndEachOther`:
```
tun_test.go:77: tun: fake-IP pool overlaps an existing interface
```

## 2. Триаж падений

### 2.1. `TestDetectCensorshipEventsWithoutOffsetsStayUnknown` (sora/core, control) — env, ДОКАЗАНО

- **Причина:** лимит `sockaddr_un.sun_path` = 108 байт с NUL ⇒ рабочий лимит 107 символов.
  Тест поднимает IPC-сервер на сокете `filepath.Join(t.TempDir(), "core.sock")`
  (control/e2e_test.go:245). При мандатном TMPDIR путь получается ровно **108 символов**:
  `/home/hatch/workspace/.build-tmp/TestDetectCensorshipEventsWithoutOffsetsStayUnknown2194744261/001/core.sock`
  ⇒ `bind: invalid argument` (EINVAL). Это самый длинный TestName в пакете (51 символ),
  поэтому упал только он.
- **Доказательства env, а не регрессии:**
  1. Падает идентично на чистом HEAD (worktree `/tmp/sora-clean-06`, commit `eb24564`,
     `-count=1`) — т.е. не вызвано WIP в грязном дереве.
  2. Проходит с коротким TMPDIR: `TMPDIR=/tmp go test -count=1 -run ...` → PASS
     (путь ~79 символов < 107).
- **Продукт не затронут:** продовый сокет жёстко `/run/sora/core.sock`
  (core/ipc/ipc_unix.go:24) — короткий. Проблема только в тест-харнесе + глубоком TMPDIR.
- **Класс:** (а) env/песочница, детерминировано, 3/3 наблюдений.
- Фикс не вносился (не баг кода; мердж-блокирующим не является). Замечание: CI с глубоким
  TMPDIR будет видеть красный тест — опционально можно сделать helper короче
  (или скиповать при длине пути), но это не код продукта.

### 2.2. `TestTunAndFakeIPAvoidLANAndEachOther` (sora-legacy/core, engine) — env, ДОКАЗАНО

- **Причина:** песочница имеет интерфейс `host0: 198.19.0.2/30`, который входит в дефолтный
  FakeIP-пул `198.18.0.0/15`. Legacy-вариант теста (core/engine/tun_test.go:73) вызывает
  `PrepareTun(p)` напрямую и читает **реальные** интерфейсы хоста ⇒ дефолтный пул отвергается
  как пересекающийся с интерфейсом: `tun: fake-IP pool overlaps an existing interface`.
- **Доказательства:**
  1. Падает идентично на чистом HEAD (worktree `/tmp/legacy-clean-06`, commit `649237c`)
     — предсуществующее, не регрессия.
  2. Детерминировано: полный прогон + чистый HEAD + `-count=3` в грязном дереве — 5/5 FAIL
     с той же ошибкой. Не флаки.
- **Известный кейс ПОДТВЕРЖДЁН для legacy**, но **ОПРОВЕРГНУТ для sora/core**: в sora тот же
  тест (core/engine/tun_test.go:58) инжектит `fakeAddrs(...)` и НЕ читает интерфейсы машины
  (комментарий в файле прямо ссылается на кейс с хостом в 198.18.0.0/15) —
  в грязном дереве и на чистом HEAD `eb24564` тест проходит `-count=1`.
- **Класс:** (а) env/песочница, детерминировано. Мердж-блокирующим не является;
  желателен порт фикса из sora (инъекция адресов) или skip при коллизии дефолтного пула,
  чтобы убрать шум в CI.

### 2.3. Флаки

Не обнаружены: оба красных теста детерминированы и объяснены. Повторные прогоны
(3× legacy, 3× control-кейс) стабильны.

**Вывод по находкам:** реальных багов в этой зоне нет — коммитов `[final-audit]` не делалось
(нечего фиксить; env-кейсы фиксом кода не закрываются и закрываться кодом не должны).

## 3. Покрытие ключевых пакетов sora/core (`go test -count=1 -cover`, свежие прогоны)

| Пакет | Покрытие |
|---|---|
| control | 71.9% |
| engine | 81.4% |
| ext | 80.9% |
| censor | 78.8% |
| probe | 81.7% |
| subscription | 88.7% |
| session | 83.9% |

Пакетов с 0% покрытием при наличии критичной логики — **нет**.

## 4. Пакеты вообще без тестов при нетривиальной логике

**sora/core** (9 безтестовых пакетов): `gen/*` (6 шт., generated protobuf — ок),
корневой `doc.go` (ок), `engine/enginetest` (фича-фикстуры для тестов — ок),
`cmd/sora-censor-proxy` (117 строк; ручной regression-testbed поверх pcap, сам файл
документирует: "Manual runs; CI wiring is a separate task" — допустимо).

**sora-legacy/core** (4 безтестовых): `gen/sora/core/v1` (generated), корневой `doc.go`,
`engine/enginetest` (фикстуры) — всё ок; ⚠️ **`engine/xraytun`** (bridge.go, 218 строк,
12 функций): мост Xray-routing + mihomo TUN, приватный SOCKS-линк, владение двумя
процессами и рестартами — **нет тестов в legacy**, тогда как в sora/core у xraytun
тесты есть. Это покрытие-гэп, достойный пометки (не баг, а слепая зона).

**service/sync** (2 безтестовых): `cmd/sora-sync` (main-обёртка, 140 строк — допустимо),
⚠️ **`discovery`** (discovery.go, 174 строки): mDNS-обнаружение пиров для pairing —
security-adjacent путь, тестов нет. Слепая зона №2.

**Дополнительная оговорка по сигналу:** пакеты `engine/interop` в обоих репозиториях —
тест-онли (только `*_test.go`, в sora 7 тестов, в legacy 5), требуют `SORA_ENGINES_DIR`
с реальными бинарниками sing-box/xray/mihomo. В этой песочнице все SKIP (0 PASS/FAIL),
пакет отчитывается `ok`. «Зелёный» interop здесь означает «ничего не запускалось» —
сквозной трафик через реальные движки в CI без этих бинарников не проверяется.

## 5. Вердикт зоны: можно ли доверять сигналу для мерджа

- **sora/core:** зелёный сигнал достоверен, кроме одного детерминированного env-артефакта
  (длина unix-сокета под глубоким TMPDIR). Красный тест — не блокер и не регрессия.
  Покрытие критичных пакетов 72–89%. Единственная слепая зона: interop-тесты скипаются
  без `SORA_ENGINES_DIR` — end-to-end по живым движкам сигнал не даёт.
- **service/sync:** полностью доверяемый зелёный (малый объём, 37 тестов). Слепая зона:
  mDNS-discovery без тестов.
- **sora-legacy/core:** зелёный достоверен, кроме одного детерминированного env-артефакта
  (интерфейс песочницы 198.19.0.2/30 ⊂ дефолтного FakeIP-пула; legacy читает реальные
  интерфейсы). Подтверждено на чистом HEAD `649237c`. Слепая зона: `engine/xraytun`
  без тестов.
- **Кросс-сборки Windows** обоих core-модулей чистые, CGO не нужен.
- `go vet` чист везде, `go build` чист везде.

**Итог:** реальных багов (Critical/High) тестовая зона не выявила; оба красных теста —
строго доказанные env-кейсы (чистый HEAD + воспроизводимость + объяснение механизма).
Мердж не блокировать по этим тестам; для чистоты CI рекомендовано (не обязательно):
портировать в legacy инъекцию `fakeAddrs` из sora (как сделано для sora/core) и/или
укоротить путь сокета в `censorClient`-хелпере, добавить тесты для legacy `engine/xraytun`
и sync `discovery`.

*Примечание о HEAD: в момент прогона HEAD sora был `eb24564` (clean worktree создан от него);
к концу прогона ветка ушла вперёд (`1c71376`) — параллельная работа других агентов,
дерево мной не трогалось. Временные worktree `/tmp/sora-clean-06`, `/tmp/legacy-clean-06` удалены.*
