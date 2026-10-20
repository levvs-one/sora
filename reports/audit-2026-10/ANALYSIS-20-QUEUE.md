# ANALYSIS-20 — очередь роя (запуск после закрытия круга 1)

Дата: 2026-10-20. Источник: `ANALYSIS-20.md` + 20 детальных отчётов `analysis-20/01..20-*.md`.
Круг 1 = вердикт F9-ревью + отчёт дедупликации DEEP-RESEARCH. После — диспетчер по этой очереди.

## Уже закрыто (не брать)
- (2) `engines.digests` в nfpm.yaml — исправлено владельцем лично (коммит `1121593`).
- (15) красная ветка `engine/mihomo` + `core/ext` тесты — закрыто параллельной работой (проверено зелёным).
- (7) Xray v26.3.27 + uTLS-кризис — в работе через DEEP-RESEARCH S3 + WEB-RESEARCH-2 P0(1).
- (8) F9-театр — в работе (F9-ревьюер).
- (9), (14) legacy Go / legacy C# — запущены 2026-10-20 (A20-9, A20-14), репо sora-legacy.

## Решения владельца (зафиксированы, не переспрашивать)
- **Windows in-app update**: или проверка minisign в Dart (переиспользовать `ext/verifier.dart`), или fail-closed блокировка пути. Доки врать не должны (`security.md:32`).
- **Polkit**: чинить правило с `allow_active=yes` (память H2: без него ветка мертва). Threat model честно: «любой процесс сессии = контроль», как на Windows. `docs/install.md:82` не должен обещать невозможного.
- **F5/F6**: установить единый источник правды — проверить, что Go-сторона мертва (ноль вызовов из Dart), убрать дубль, починить врущие docstring'и.
- **Мёртвый код**: вырезать только доказанно мёртвое (`go list -deps` + история), не WIP.
- **Дрейф sora↔legacy**: только документировать, не рефакторить.
- **launchAtLogin**: opt-in (дефолт false), не агрессивный `true`.
- Фильтр слопа и стандарт качества — как всегда. Коммиты `[swarm] <что> (A20-<N>)`, пуша нет.

## Очередь (порядок = приоритет P0)

### A. Релиз/инфра (sora)
- **A1 — Windows-сборка мертва** (`sora.iss:36` требует `SignTool=soraSign`, CI не передаёт `/S`; см. `repository.yml:221`, `analysis-20/19`). Починить: условный SignTool (подпись только когда доступна) или условный `/S` в CI. Windows-сборку здесь не проверить — логика обязана быть review-obvious. Имплементатор + строгий ревьюер.
- **A2 — Windows in-app update без minisign** (`analysis-20/10`). Или проверка minisig в Dart (reuse `ext/verifier.dart`), или честная fail-closed блокировка. Security-critical → имплементатор + отдельный ревьюер. Доки не врут.
- **A3 — Polkit** (`analysis-20/15`): `allow_active=yes`, интеграционный тест, честные доки + threat model.

### B. Контракты/Dart (sora/app — сериализовать между собой)
- **B1 — Dart-стабы отстают** (22 сообщения, 8 RPC, `profile_matched` роняется в `_watchSession`; `analysis-20/03`). Синхронизировать стабы + тест паритета proto↔Dart. Проверить незакоммиченный worktree-фикс `custom.pb.dart` перед стартом.
- **B2 — CustomServers не смонтирован** (одна строка → UNIMPLEMENTED). Сначала прочитать `reports/featlog-swarm-sw7.md` (врезка хуков SW7) — возможно, это и есть недостающий кусок. Wiring-тест на все proto-сервисы.
- **B3 — F5/F6 ×2** (`analysis-20/14`): установить источник правды, убрать дубль.
- **B4 — два `isBuiltInTarget`** (`control/plan.go:360` vs `engine/refs.go:83`): канонический список в `engine`.
- **B5 — Connections вне навигации** (`shell.dart:47` `_sectionOrder`, `pages[2]` недостижим): вернуть в сайдбар.
- **B6 — crash-restore нечестен** (`analysis-20/13` P1–P4): флаг чистого завершения + TTL intent'а + запись после RPC-успеха; скоординировать с auto-connect.
- **B7 — probe >256 серверов мёртв** (`analysis-20/16`): чанкинг (Go-лимит + Dart-клиент шлёт чанками).

### C. Расширения P0 (`analysis-20/08`)
- **C1**: (а) тумблер «Run in background» — или настоящий раннер, или честный бейдж (фильтр слопа: имитацию не внедрять); (б) пин ключа автора в каталоге + проверка непрерывности ключа при update; (в) zip-бомба в Dart-распаковке. Вопрос authority (ExtensionHost vs Dart-мост) — отделу расширений, не сюда.

### D. Движки
- **D1 — XHTTP downloadSettings захардкожен на `chrome`** (`xray/render.go:341` при `hellochrome_auto` в stream). Та же зона, что WEB-RESEARCH-2 P0(3) (имена полей XHTTP) — один агент на оба или строго сериализовать.
- **D2 — rule sets sing-box с tip-веток без пина** (`analysis-20/17`): запинить (коммит/дайджест).

### F. Сквозное
- **F1 — мёртвый код core (~2500 строк)** (`analysis-20/01`): вырезать доказанно мёртвое. **ЗАПРЕТ: не трогать** `core/obfs`, `core/select`, `core/tune`, `core/leak`, `core/censor` (фичи круга 1, WIP-интеграция), `core/ext` (свой отдел), `service/sync`.
- **F2 — мёртвый код diagnostics (~1000 строк capture/spoof)** + мёртвые пункты меню PCAPNG/EVTX (`analysis-20/11` P0–P1): убрать или вернуть функционал — честно.
- **F3 — сканеры слепы к `service/sync` и `app`**: расширить govulncheck/osv/dependabot на весь монорепо.
- **F4 — доки P0-противоречия** (`analysis-20/05`): `security.md:16`/`faq.md:47` (маскирование доменов «по умолчанию» — ложь), `security.md:38` («приложение не ходит в сеть» — ложь, `updates.dart` → `api.github.com`), `usage.md:52` (Xray TUN на Windows), `security.md:32` (инструкция проверки подписи). Плюс дописать usage.md про фичи волн (P1, если останется ресурс).
- **F5 — дрейф sora↔legacy**: только документ (куда что портировано/нет, чеклист портов).
- **F6 — launchAtLogin opt-in**: дефолт false + честный текст тоггла.

## Открытые вопросы владельцу (из ANALYSIS-20, кодом не чинятся)
1. Authority расширений (ExtensionHost vs Dart-мост) — отделу расширений.
2. Key ceremony + Authenticode + per-machine решение — главные блокеры релиза.
3. Zapret scope: nfqws/QUIC или зафиксировать tpws-only (эпик S9).
4. Каденс аудитов, warrant canary — из DEEP-RESEARCH-70.
