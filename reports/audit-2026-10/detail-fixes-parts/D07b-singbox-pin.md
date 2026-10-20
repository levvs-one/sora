# D07 — пины движков, version-aware TUN stack, ECH (sora Go core)

Статус смешанный, честно по частям. Пуша нет.

## 1. Пин sing-box 1.12.0 → 1.15.0 — В ВЕТКЕ (HEAD)
- **Было:** `MinVersion: "1.12.0"` в `core/engine/catalog.go`.
- **Стало (в HEAD):** `MinVersion: "1.15.0"` + комментарий: в 1.15 TUN переписан вокруг собственного TCP/IP-стека sing-tun, опция `stack` deprecated (удалена в 1.17) — подтверждено официальными changelog/migration-доками.
- **Эффект:** автовыбор честно отбраковывает устаревшие сборки. Атрибуция: изменение D7 присутствует в дереве HEAD (через какой коммит приземлилось в гонке — установить не удалось; отдельный `[detail-fix]`-коммит D7 не создавался — ветка была сломана).

## 2. Полка 1.14.3 для lx-форка — ГОТОВО, НЕ ЗАКОММИЧЕНО
- **Было бы:** слепое поднятие пина убило бы shipped-форк `sing-box-lx v1.14.3-lx.14` (единственный sing-box с AWG; `packaging/engines/engines.lock`) — он стал бы «older than 1.15.0», дефолтный движок упал бы на Xray, AWG-планы — на mihomo, per-app routing (только sing-box) — вообще никуда.
- **Стало (worktree, незакоммичено):** новая `singBoxFloor()`: upstream ≥1.15.0, lx-форк ≥1.14.3; `SelectEngine` берёт floor оттуда.
- **Эффект после коммита:** пин поднят, форк жив, гейт не мёртвый. Тест `TestSingBoxPin115KeepsTheLXFork` зелёный.

## 3. Version-aware `stack`: `MissingFor(p, v)` + `renderVersioned` — ГОТОВО, НЕ ЗАКОММИЧЕНО
- **Было:** renderer всегда писал `"stack"`; конкурент (D01) выпилил его безусловно — что молча роняло явный выбор стека на форке 1.14 (там опция рабочая, дефолт mixed).
- **Стало (worktree):** `Missing` делегирует в `MissingFor(p, v)` — на sing-box ≥1.15 явный stack честно репортится как missing (движок его проигнорирует); renderer через `renderVersioned` (версию несёт driver из `cfg.Binary.Version`) не пишет `stack` на ≥1.15, пишет на <1.15 и unknown; `supervisor.admit` тоже переведён на `MissingFor`.
- **Эффект после коммита:** ни молчаливой потери стека, ни deprecated-опции на 1.15+. Тесты `TestTunStackNeverSilentlyDroppedOnSingBox115`, `TestTunStackFollowsEngineVersion` зелёные; чужой `TestTunDropsDeprecatedStack` сужен до 1.15+ (интент сохранён).

## 4. ECH `query_server_name` — ГОТОВО, НЕ ЗАКОММИЧЕНО
- **Было:** поле плана не рендерилось («needs sing-box >= 1.13, above our 1.12 minimum» — мёртвый гейт).
- **Стало (worktree):** рендерится через `.set` (поле подтверждено официальной докой sing-box, существует с 1.13 — ниже пола 1.14.3/1.15).
- **Эффект после коммита:** ECH может запрашивать конфиг не на server_name. Тест `TestRenderECHQueryServerName` зелёный.

## 5. Хардкод версии в registry → константа — ГОТОВО, НЕ ЗАКОММИЧЕНО
- **Было:** литерал `engine.Version{Major:1, Minor:19, Patch:32}` + строка "1.19.32" в сообщении.
- **Стало (worktree):** `mihomoBridgeMinVersion` (с `Raw`, т.к. `Version.String()` возвращает `Raw` — иначе `%s` печатал бы пустоту).
- **Эффект:** одна точка правки.

## 6. Пины Xray/mihomo — проверены, менять нечего
Xray 26.3.27 vs latest 26.7.28: breaking между ними — удаление legacy reverse; renderer reverse не пишет (проверено grep) — безопасно. mihomo min 1.19.0 / shipped 1.19.32 — ветка свежая, регрессий под наши кейсы нет.

**Где лежит незакоммиченное:** worktree (`core/engine/{catalog.go,engine.go,engine_test.go,enginetest/plans.go,registry/registry.go,singbox/{engine.go,render.go,render_test.go},supervise/supervisor.go}` — ВНИМАНИЕ: в тех же файлах чужие незакоммиченные правки D24/AWG) + бэкап `~/workspace/d7-engine-backup/`. Коммитить только после стабилизации дерева, по CAS-рецепту, фильтруя только свои ханки. `go build` + `go vet` по зоне — чисто.

**Follow-ups:** mihomo тоже умеет `query-server-name` в `ech-opts` (вынести после проверки мин. версии mihomo); подъём пина Xray до 26.7.28 вместе с `engines.lock` (packaging, вне зоны).
