# Final audit №3 — корректность и отказоустойчивость

**Дата:** 2026-10-20. **Ветки:** `bugfix/audit-2026-10-19` в `~/workspace/bug-hunt/sora` и `~/workspace/bug-hunt/sora-legacy` (локально, без пуша).
**Охват:** Go-ядро `core/` (оба репо) + `service/sync/` (sora). Контекст POWER-RUN/REVIEW-5PASS/FIX-REPORT учтён — дупликации закрытого нет.
**Фокус:** паники, утечки, гонки, таймауты, fail-open, проглоченные ошибки в новых пакетах (`censor`, `tune`, `ext`, `sync`, `probe/freeze`, `engine/supervise`, `control`, `session`, `guard`).

## 0. Срочное: состояние staged-индекса

⚠️ **Коммит НЕ делал — индекс отравлен чужим WIP.** Перед финальным отчётом проверен `git diff --cached --stat`:
- `sora`: в staged — `README.en.md`, `README.md`, `docs/README.md`, `docs/extensions.md`, `docs/faq.md`, `docs/usage.md` (мне не принадлежат).
- `sora-legacy`: в staged — `docs/architecture/core.md` (чужой).

Мой единственный коммит `a10165e` (до предупреждения) был строго pathspec-формой по моим двум путям, после — `git show --stat HEAD` показал ровно 2 файла. Новые фиксы (F-02 ниже) как спеки — коммитить не стал по требованию родителя.

## 1. Исправлено (1 коммит)

### F-01 `[final-audit]` — гонка данных в DNS-canary тесте (исправлено, `a10165e`)
- **Файлы:** `core/diagnostics/dnsleak.go` (док-комментарий), `core/diagnostics/dnsleak_test.go` (фикс).
- **Сценарий:** `checkTunnelDNS` (dnsleak.go:308) запускает по горутине на каждый resolver и вызывает инъектированный `DnsLeakInput.Probe` **конкурентно**. Тест `TestCheckDnsLeaks_ProbesEveryResolver` писал в разделяемый срез `probed` из этих горутин без синхронизации → `go test -race` ловил DATA RACE (write/write на `probed`, затем growslice).
- **Разбор:** продовый код корректен (`results[i]` — disjoint на горутину; `wg.Wait()` даёт happens-before). Дефект был в тестовой замыкании и в **недокументированном контракте**: поле `Probe` не говорило, что вызывается конкурентно — любой stateful prober унаследовал бы гонку.
- **Фикс:** мьютекс вокруг `probed = append(...)` в тесте + док-комментарий к полю `Probe`: «вызывается конкурентно (по горутине на resolver), stateful prober обязан быть безопасен для конкурентного использования».
- **Верификация:** `go vet ./diagnostics/` чисто; `go test -race -count=1 -run 'TestCheckDnsLeaks' ./diagnostics/` — зелёно. `go build ./...` обоих ядер — чисто.

## 2. Найдено, код не тронут (спеки)

### F-02 — Частичный `Arm` kill switch утекает в armed без сессии (Medium, `core/guard/ingress.go:135-156`)
- **Сценарий:** в проде firewall всегда обёрнут `guard.WithIngress(...)` (main.go:236). `IngressFirewall.Arm`: `inner.Arm` успешен (таблица kill switch в nftables поднята) → затем `ensureBackend()` или `backend.arm()` падает → `Arm` возвращает ошибку. `Guard.applyKillSwitch` возвращает ошибку **не записывая** `applied.KillSwitch`. `Session.Start` падает → менеджер вызывает `created.Stop` → `restoreGuard` → `Guard.Restore`: `g.applied.KillSwitch == false` → **`Disarm` пропускается**. Исходящий трафик заблокирован без живой сессии; UI показывает «отключено/ошибка»; восстановление — только рестарт ядра (`CleanupStale` на старте main.go:241) или ручной `nft flush`.
- **Спека фикса (1 файл, безопасно):** в `Arm` при ошибке после `inner.Arm` — откатить: `_ = f.inner.Disarm(context.WithoutCancel(ctx))` и вернуть join ошибки. Контракт `Disarm` («успех, когда ничего не вооружено», nftables_linux.go:121) делает откат безопасным; на WFP аналогично по контракту интерфейса.
- **Не фиксил:** по срочному указанию — не коммитить при отравленном индексе; сам файл чистый, но рисковать не стал.

### F-03 — `GracefulStop` без дедлайна при закрытии ядра (Low/Medium, `core/cmd/sora-core/main.go:568-575`)
- `App.Close()` вызывает `a.server.GracefulStop()` без таймаута; 20-секундный `stopCtx` ограничивает только `sessions.Shutdown`. Зависший клиент с открытым `WatchSession`/стримом событий (или вообще любой незакрытый RPC) блокирует `GracefulStop` навсегда → `sora-core` не завершается (systemd в итоге SIGKILL). Спека: `GracefulStop` в горутине + select на `stopCtx.Done()` → `a.server.Stop()`.
- Файл под чужим WIP (MM) — точно только спека.

### F-04 — legacy: отсутствие/порча SHA256SUMS молча отключает верификацию движков (Medium, `sora-legacy/core/engine/supervise/binary.go:117`)
- `digests, _ = LoadDigests(enginesDir)` — ошибка глотается; при отсутствии манифеста проверка **пропускается целиком**, бинарь исполняется без верификации. В sora-близнеце (`sora/core/engine/supervise/binary.go`) отсутствие манифеста — fail-closed отказ. У legacy это документированное поведение («manual or development layouts»), но злоумышленник, удаливший/испортивший `SHA256SUMS`, получает исполнение неподписанного движка. Спека: скопировать fail-closed модель sora или требовать явный `--allow-unverified-engines`.

### F-05 — `Daemon.Shutdown` ждёт бесконечно (Low, `sora/service/sync/api/syncloop.go:140`)
- `d.wg.Wait()` без дедлайна. На практике ограничен ctx хендлеров (2 мин на pairing/transport), так что «зависнет максимум на 2 мин», но как паттерн shutdown — хрупко. Спека: бюджет shutdown с логом.

### F-06 — unbounded рост `sems` в `HandshakeLimiter` (Low, `sora/core/censor/budget.go:31`)
- Карта `map[string]chan struct{}` — по одному каналу на каждый когда-либо виденный SNI; запись никогда не чистится. Долгий аптайм → медленная утечка. Не wired в прод (помечено NOT WIRED), поэтому Low. Спека: LRU/eviction по времени или одна запись при отсутствии активности.

### F-07 — расхождение legacy: проглоченный `eng.Stop` в TunUp-fail пути (Low, `sora-legacy/core/session/runner.go:217`)
- `_ = s.eng.Stop(...)` — в sora аналогичный путь журналирует ошибку (SORA-M16). Дивергенция ядра sora; стоит портировать однострочно.

## 3. Проверено и здорово (отрицательный результат — тоже результат)

- **Паники `[0]`/`nil-deref`/`assert`:** перебраны все `…[0]` в фокусных пакетах (censor/probe.go, probe/quic.go, probe/reality.go: `PeerCertificates` — под `len()>0`; censor/siberian.go — цикл с return; ext/sign.go, ext/package.go — после len-проверок; control/obfs.go — под `len>0`; session/guard.go — под `len==0 → NoopGuard`; session/manager.go — под `id != ""`; session/censor.go — под `len(Outbounds)>0`; sync/transport.go:465 — под `len(plain)==0`). Все защищены. Type assertions без comma-ok в новом коде — не найдены (`probe/quic.go:136`, `control/override.go:42` — с `ok`; `obfs.go:460` — под `obfsEnabled` → non-nil). `WatchEvents` отдаёт `[2]string` — `ev[0]` массив, не срез.
- **close():** `subscriptionBook.watch()` — close под членством в map (двойной close невозможен); `eventFeed.close()` — через unsubscribe; `ext/worker.go:SetKillSwitch` — `pauseCh` под `pauseMu`, сериализован; `sync/api/pairing.go` `close(s.done)` — defer один раз; `session/runner.go` `close(s.done)` — только в supervise.
- **Утечки горутин/дескрипторов:** `bandwidth.go` — класс проблемы (engine-процессы при обрыве стрима) проверен заново, фикс держится: ctx-aware `send`, `defer eng.Close()`, ticker.Stop. Класс проверен в `probe.Probe` (результаты buffered, `wg.Wait` + `close(results)`), `RunSeries` (ticker.Stop), `ext worker` (startLoopWith — один loop на задачу, `task.ctx.Done`), session `supervise` (выход на `ctx.Done`/закрытие events, `ticker.Stop` все), sync `pairingLoop` (выход на Accept-error при `listener.Close`), sync `recv` — горутина при `ctx.Done` завершается, т.к. владеющий хендлер закрывает conn. **Goroutine-лика в продовых путях не найдено.**
- **Таймеры/тикеры:** все `NewTicker` в фокусе — под `defer Stop()` (bandwidth, serial, runner, supervisor waitReady, bandwidth downloadGoodput, guard/manager rehandshake).
- **HTTP-клиенты:** `metricsClient` (xray) — per-request 3s ctx, ок; `netfetch` — per-request ctx из `limits.Timeout`, ок; `catalog` — 30s default, ок; `subscription` — DefaultTimeout 30s + Dialer/`ResponseHeaderTimeout`, ок; clashapi — проверен (с таймаутом). `sync/cmd/sora-sync` использует `http.DefaultClient` для webhook — только в CLI-утилите (main.go:78), с 3s ctx — ок.
- **Kill switch fail-open:** все пути `Arm`/`Disarm` в `guard` (nftables атомарный batch, root-UID fail closed, strict-marker rollback, `Armed` сверяется с ядром) — fail-closed. Ошибки DNS-диагностики — честный «unknown», не «clean» (dnsleak.go:339-341 «Detection failed; say so instead of guessing»). Верификация расширений: install/rollback — fail-closed (`store.go:225`, `512`: rollback отказывается при failed re-check).
- **Проглоченные ошибки:** 70 `_ =` в фокусе — перебраны: критичных нет (в основном `Close`/`Remove`/`SetDeadline` с комментариями). Исключение: legacy F-04/F-07.
- **`sync.go`:** `Join` `*d.peers[c.Peer.DeviceID]` — безопасно (upsertPeer проверен на ошибку выше, entry гарантирован).
- **Гонка session SetKillSwitch × Start:** оба пути сериализованы мьютексами guard (`Guard.mu`, `guardMu`); nftables/Ingress — идемпотентны. Race-тесты session — зелёно.

## 4. Результаты `go test -race`

env: `TMPDIR=$HOME/workspace/.build-tmp GOCACHE=$HOME/workspace/.gocache-v`, `~/workspace/go/bin/go`.

| Модуль | Пакеты | Итог |
|---|---|---|
| sora core | control | 1 FAIL → **артефакт окружения**: `TestDetectCensorshipEventsWithoutOffsetsStayUnknown` — путь unix-сокета > 108 байт из-за длинного TMPDIR; с `TMPDIR=/tmp` — зелёно |
| sora core | session, probe, censor, ext | **ok, гонок нет** |
| sora core | tune, engine (все 14 подпакетов), supervise | **ok, гонок нет** |
| sora core | diagnostics | **1 настоящая гонка** → исправлена `a10165e` (см. F-01); после фикса зелёно |
| sora service/sync | api, pairing, sync, transport | **ok, гонок нет** |
| legacy core | control, session, probe, guard, engine/supervise | **ok, гонок нет** |

`go build ./...` и `go vet` — чисто во всех трёх модулях (после фикса; sora core, sync, legacy core).

## 5. Что не успел проверить (честно)

- Windows-пути (`WFP`, `window_windows.go`) — только вычитка сигнатур; сборка под Windows не гонялась.
- C# (legacy) и Dart/Flutter — вне фокуса этой подкоманды (Go-only).
- Полный `-race` всего дерева (ipc, logs, routing, secret, subscription, obfs, profiles, custom, wgobfusc) — не гонял; фокус был на пакеты из задания + engine + diagnostics + tune.
- Нагрузочные/хаос-тесты (kill -9 движка под kill switch, обрыв сети mid-benchmark) — только кодовый разбор.
- F-02/F-03/F-04/F-05 — спеки без кода по требованию коммит-дисциплины; файл для F-02 (`core/guard/ingress.go`) сейчас чистый и готов к однострочному фиксу отдельной коммит-сессией.
- Конфликтные WIP-файлы (`core/cmd/sora-core/main.go` MM, `core/control/*` MM и др.) не трогал вовсе.

## 6. Вердикт зоны

**Корректность/отказоустойчивость Go-кода: высокая, с оговорками.** Новых паник и утечек в новом коде не найдено; класс engine-утечек держится; kill switch fail-closed везде, где проверено; `-race` чист за вычетом одной пойманной и исправленной гонки. Реальные дыры: **F-02** (частичный Arm оставляет сеть заблокированной без сессии — availability), **F-04** (legacy fail-open при отсутствии SHA256SUMS — security-adjacent). F-03/F-05/F-06/F-07 — мелкие. Рекомендую исправить F-02 и F-04 до мержа.
