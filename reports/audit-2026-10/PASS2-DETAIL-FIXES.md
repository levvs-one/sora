# PASS2-DETAIL-FIXES — отдел охотников за мелочами, проход 2/3 (sora + sora-legacy)

**Дата:** 2026-10-20. Пуша нет — всё локально на `bugfix/audit-2026-10-19`.
**База:** PASS1-DETAIL-FIXES.md и PASS1-SUMMARY.md вычитаны; закрытое проходом 1 не повторяется. Класс прохода: «дефолт врёт / параметр не прокинут / гейт мёртв / пин устарел», сверка пинов — с WEB-RESEARCH-4.md.
**Результат:** **5 коммитов `[pass2-detail]`** (4 sora + 1 legacy). Go: build + `go vet` + тесты после каждого фикса (`go` из `~/workspace/go/bin`, `TMPDIR=$HOME/workspace/.build-tmp`, `GOCACHE=$HOME/workspace/.gocache-v`, из `core/`). Dart — тулчейна нет, тройная вычитка, помечено «не компилировалось». Коммиты — только pathspec-форма, перед каждым `git diff --cached --stat` (чужие staged/unstaged изменения на общей ветке не тронуты; дерево за время прохода двигалось коммитами `[pass2-tspu]`/`[pass2-swarm]`/`[pass2-ext]`).

---

## Исправления (было → стало → эффект → коммит)

| # | Было | Стало | Эффект | Коммит |
|---|---|---|---|---|
| 1 | **sora Dart: ядро публикует вердикты цензуры, приложение их выбрасывает.** Go публикует `CoreEvent.censorship_detected` (ядро `core/control/server.go`, payload с 1.11, коммит роя b8da4b86), generated-стаб `core_control.pb.dart` поле #13 имеет, но обработчик `WatchEvents` в `app/lib/src/sora.dart` ветки под него не имел — стоял устаревший `TODO(censor)`: «подождать, пока приземлится censor.proto и перегенерируются стабы». Блокер ложный: payload едет в `core_control`, чьи стабы полны. Итог: экран блокировочной диагностики вечно пуст при живом детекторе в ядре; `CensorDetector.fetchVerdict` при этом навсегда `null` (у DetectCensorship RPC нет Dart-клиента). | В `_watchSession` добавлена ветка `hasCensorshipDetected() && fresh` → `ingestCensorVerdict(CensorVerdict.fromWire(...))`; в `core/censor.dart` добавлен `CensorVerdict.fromWire` — конверсия wire→UI-модель: kind-строки ядра (`rst_injection`, `handshake_timeout`, `dns_poisoning`, `sni_blocking`, `ip_blocking`, `data_stall`) → `blocked/likelyBlocked` по полосам уверенности самого ядра (proto-контракт: <0.35 = UNKNOWN; `explain()` в `core/censor`: 0.35–0.75 «likely», 0.75+ — без оговорок), `no_interference` → `notBlocked`, незнакомые kind не апгрейдятся в обвинение; explanation+evidence → reasons; id = `core-<sequence>-<emittedAt ms>` (sequence перезапускается с ядром, история переживает его). Устаревшие комментарии (TODO, «no-op until the detector API lands», док `CensorDetector`) переписаны честно: push-путь завайрен, RPC-поллинг по-прежнему без клиента. | Детектор в UI ожил: история вердиктов, actionable-промпт и уведомления получают данные, которые ядро уже присылало. Не компилировалось (Dart SDK нет) — тройная вычитка против generated-стаба (аксессоры `hasCensorshipDetected/kind/confidence/explanation/evidence` сверены с `core_control.pb.dart`) и против `Kind.String()`/`explain()` в `core/censor`. | sora `8c81cb01` |
| 2 | **sora CI: golangci-lint отстал.** `repository.yml` пинил `v2.14.0`; актуальный релиз — **v2.15.0** (2026-10-16, changelog golangci-lint.run; сверено веб-поиском). Legacy тот же бамп сделал в D30 (`ed2f2d3`), sora пропустила. Конфиг `core/.golangci.yml` переименованных в 2.15 опций `exhaustive` не использует — бамп безопасен. | `version: v2.15.0` (одна строка). | Линтер в CI соответствует актуальному релизу и паритету с legacy. | sora `2742ca32` |
| 3 | **sora CI: proto-джоба на хардкоде Go 1.23.** Единственная Go-джоба с `go-version: '1.23'`; все остальные (5 мест в том же файле + autofix/security) — `go-version-file: core/go.mod`. Хардкод устарел при подъёме go-директивы до 1.27 (D20): buf ставится тулчейном на 4 минора старше того, которым собирается ядро. | Proto-джоба — `go-version-file: core/go.mod`, как везде. | Пин не может молча протухнуть при следующем подъёме go-директивы; buf собирается тем же Go, что и ядро. | sora `8c839cfe` |
| 4 | **sora core: 12 полей `engine.Plan`-структур, которые никто не выставляет и никто не читает** (все — из исходного мега-коммита `be91b66f`, ни разу не завайрены): `Transport.Prefix`, `Transport.IdleTimeout`, `Outbound.Tags`, `Outbound.CountryCode`, `Outbound.ProviderID`, `Outbound.OriginalLink`, `DNSServer.Suffixes`, `Group.Include`, `Group.Exclude`, `Options.UnifiedDelay`, `Options.ProfileStorage`. Комментарий у `Tags` при этом врал: «come from subscriptions and drive grouping in the interface» — группировки по тегам в коде нет. `Options.UnifiedDelay` — ручка, которой нет: mihomo-рендер хардкодит `unified-delay: true` сам. `OriginalLink` жил только в списке секрет-кандидатов `Outbound.Secrets()` при навсегда пустом значении. Доказательство мёртвости: полный grep по `core/ service/ tools/` (поля вне определения / вне `gen/`) — 0 присваиваний, 0 чтений; финальный арбитр — `go build ./...` (именно сборка, а не grep, поймала ложноположительный `DNSServer.Dialer` — он читается mihomo и в список не вошёл). | Поля удалены из `core/engine/plan.go`; `OriginalLink` убран из кандидатов в `core/engine/validate.go`. Остальные «читаемые, но не выставляемые» ручки (`DNSServer.Dialer`, `Options.FindProcess/GeoData/AllowLAN`) не тронуты — это поддерживаемые рендерами нобы в ожидании proto-поля, не ложь. | Контракт плана больше не обещает параметров, которые движки молча игнорируют: выставить «работающий» `IdleTimeout`/`Suffixes`/`UnifiedDelay` теперь невозможно в принципе (аналог D08 fail-closed на уровне типов). Build + vet + `./engine/... ./control/` — зелёно. | sora `3531723a` |
| 5 | **legacy: та же мёртвая поверхность отмечена наполовину.** Коммит `6599852` пометил `reserved` только `Transport.Prefix/IdleTimeout` и `DNSServer.Suffixes`; остальные поля того же класса (`Tags` — с тем же врущим комментарием про группировку, `CountryCode`, `ProviderID`, `OriginalLink`, `Group.Include/Exclude`, `Options.UnifiedDelay`, `Options.ProfileStorage`) пометки не получили — читатель не отличает живое от мёртвого. | Все оставшиеся поля помечены `reserved` в формулировках соседей по файлу (`Dialer` в legacy уже был честно документирован: «nothing in the tree sets it» — не тронут). Legacy-конвенция `6599852` (помечать, не удалять — контракт зеркалится C#-клиентом) соблюдена; в sora (фикс 4) тот же класс удалён, т.к. там конвенция D08. Побочно: файл приведён к gofmt-чистоте. | В legacy-плане каждое мёртвое поле теперь честно подписано. Build + vet зелёно; тесты `engine` — зелёно, кроме известного предсуществующего env-артефакта (ниже). | legacy `e39fa15` |

---

## Проверено как «чисто, фиксить нечего» (с доказательствами)

- **Hand-written Dart-стабы `app/lib/src/obfs.dart` vs `obfs.proto`** (зона, которую D42 оставил непроверенной): теги `ObfuscationProfile` 1–6, `ApplyObfsProfileRequest/Response` 1–2/1–4, `GetObfsCapabilities*`, `EngineObfsCapabilities` 1–8, значения enum `UtlsProfile` 0–10 и `ObfsPreset` 0–4, пути клиента `/sora.obfs.v1.ObfsControl/…` — полное совпадение. `ObfsSettings` в проде вызывается (connect-путь `sora.dart:712`, UI `sora.dart:514`).
- **Dart Settings → proto в `buildPlan`**: все поля (`preset/blockAds/engine/ipv6/dns/fragment*/tun-stack-и/controlPort`) доходят до `SessionPlan`; probe-настройки (`probeMethod/probeUrl/probeTimeout`) доходят до `ProbeServers` (`sora.dart:1803`). `BypassStrategy.oob/domain_case/method_eol` в UI отсутствуют как класс (нет настройки — не дроп).
- **Дефолт DNS ядра честный**: `defaultTunResolvers` = DoH `https://1.1.1.1/dns-query`, `https://8.8.8.8/dns-query` — совпадает с proto-доком `DnsPolicy` и `docs/usage.md`.
- **`updates/releases.json`**: rollout `1.0.12` = pubspec `1.0.12+13`.
- **Пины движков согласованы внутри репо**: engines.lock ↔ `core/engine/catalog.go` MinVersion ↔ THIRD-PARTY-NOTICES (sora и legacy: sing-box(-lx) 1.14.3 / xray 26.3.27 / mihomo 1.19.32). `service/sync` на `go 1.26.9` — осознанно, задокументировано в `security.yml` (govulncheck-матрица), не дрейф.
- **Версионный контракт API**: ядро `Version{1, 11, MinSupported 1}` (`core/cmd/sora-core/main.go`), Dart `apiVersion{1, 11, minSupported 6}` — запинено контрактным тестом `core/cmd/sora-core/version_test.go`.
- **Legacy known-flake подтверждён**: `TestTunAndFakeIPAvoidLANAndEachOther` падает и на чистом HEAD legacy (проверено `git stash`) — предсуществующий env-артефакт песочницы из PASS1-SUMMARY, не регрессия фикса 5.

---

## Отклонено слоп-фильтром / заблокировано (с причинами)

1. **Бамп Xray 26.3.27 → v26.10.17 (WEB-RESEARCH-4 S1)** — НЕ сделан, заблокирован не кодом: (а) дайджесты 6+ ассетов в `engines.lock` должны браться из upstream `.dgst` на момент бампа и валидироваться прогоном движка (`catalog.go`: рендеры валидированы именно на 26.3.27 `run -test`), бинаря 26.10.17 в среде нет; (б) вместе с пином живут гейты, привязанные к 26.3.27: предупреждение fingerprint.go («newest Chrome parrot is 133 on the pinned build»), plaintext-VLESS гейт ≥26.7.11 в catalog, `hellochrome_155`-доступность — бамп без перепроверки каждого врёт в обратную сторону; (в) legacy-lock осознанно держит 26.3.27 политикой «stable only» (комментарий в `sora-legacy/packaging/engines/engines.lock`). Это одна связная задача владельца/координатора с dev-машиной, а не деталь. Рекомендация: бамп одним коммитом «lock+дайджесты из .dgst+catalog MinVersion+fingerprint-гейт+перевалидация рендеров».
2. **sing-box 1.15** — по WEB-RESEARCH-4 A2 stable по-прежнему нет (1.15.0-alpha.12); MinVersion/пин не трогать. Подготовка к `stack`-миграции в рендере уже сделана проходом 1/`[pass2-debt]` (TUN stack на 1.15 не рендерится) — повторять нечего.
3. **`DetectCensorship` RPC — Dart-клиент** — не написан: в `app/lib/src/generated` нет censor-пакета вообще, hand-written gRPC-клиент под заказной сервис — не «мелкая деталь», а генерация стабов на dev-машине (protoc). Фикс 1 закрыл пользовательский эффект (экран ожил) через push-путь; RPC-поллинг честно задокументирован как отсутствующий.
4. **mihomo `UnifiedDelay`/`TCPConcurrent` хардкод `true` в рендере** — не фикс: это документированный выбор рендера, а не игнорирование параметра (параметра-плана под него после фикса 4 не существует).
5. **`parser.OutboundSpec.CountryCode` (sora и legacy)** — вычисляется и покрыт тестом парсера, но на провод не уходит (proto-поля нет; Dart достаёт флаг из display name сам, `servers.dart:331`). Удаление — нулевой наблюдаемый эффект и шум в тестах парсера; оставлено, зафиксировано здесь.
6. **Flutter-пин 3.47.6, .NET-пин 8.0.424 (legacy CI)** — вне источников WEB-RESEARCH-4, проверить актуальность по авторитетному источнику в объёме прохода не удалось; не трогал, чтобы не менять вслепую.

---

## Коммиты прохода

sora (`bugfix/audit-2026-10-19`):
- `8c81cb01` `[pass2-detail] dart: ingest pushed censorship_detected verdicts` *(Dart, не компилировалось — нет тулчейна)*
- `2742ca32` `[pass2-detail] ci: golangci-lint v2.14.0 -> v2.15.0`
- `8c839cfe` `[pass2-detail] ci: proto job follows core/go.mod instead of hardcoded go 1.23`
- `3531723a` `[pass2-detail] engine: drop plan fields nothing sets or reads`

legacy (`bugfix/audit-2026-10-19`):
- `e39fa15` `[pass2-detail] engine: mark the remaining never-set/never-read plan fields reserved`

Все коммиты проверены `git show --stat HEAD` — только свои файлы. Пуша нет.

*Отчёт прохода 2/3 — отдел мелких деталей, 2026-10-20.*
