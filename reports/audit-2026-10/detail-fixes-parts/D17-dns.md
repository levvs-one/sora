# D17 — DNS: DoH3-first, FakeIP v6 (sora Go core) — БЕЗ КОММИТА (осознанно)

Статус: имплементация D17 побитово покрыта коммитом сиблинга (проверено) — дублирующий коммит не делался; остались только 7 тестов патчем `~/workspace/bug-hunt/d17/d17-dns-tests.patch` (чистые append'ы в конец 4 файлов, применить `git apply`, когда ветка зелёная). Причина: HEAD не собирался (`engine/plan.go:549: undefined: MuxOptions` — чужой in-flight рефактор), коммит поверх дал бы битое дерево. Пуша нет.

Зона по факту: `core/engine/{plan,refs,catalog,fields}.go`, `core/engine/{singbox,mihomo,xray,xraytun}/render*.go`, `core/control/plan.go`, `app/lib/src/ui/dns.dart` (`core/dns/` в репо нет).

## 1. DoH3-first: документированный `h3://` ронял сессию
- **Было:** `h3://`-резолвер, задокументированный в `docs/usage.md` как поддерживаемый, ронял соединение на xray (`dns transport "h3" is not supported`) и на xraytun-мосту (x-leg не проходил Validate); авто-выбор движка мог отдать h3-план xray.
- **Стало (в ветке):** `FeatureDoH3` — план с h3-резолвером требует движок с DoH3-транспортом (sing-box `h3://`, mihomo `?h3=true` с форсированным H3 без даунгрейда — намеренно, задокументировано); xray помечен как не поддерживающий, селектор уводит h3-планы на sing-box/mihomo; xraytun: tun-leg (mihomo) держит h3, x-leg (только резолв имён прокси) понижается до `https`; кандидат в registry зеркалит даунгрейд; ошибка xray стала actionable («xray has no DNS-over-HTTP/3; use https:// … or the sing-box/mihomo engine»).
- **Эффект:** документированный `h3://` больше не роняет сессию ни на одном движке; выбор движка честный, без silent-даунгрейда. Тесты D17 (в патче): `TestDoH3ResolverRequiresDoH3Feature`, `TestDoH3PlanAvoidsXray` (+негатив: pinned xray отклоняется с `doh3`), `TestBridgeDowngradesDoH3ForTheXrayLeg` (+негатив: исходный план не мутирует — shallow-copy ловушка), `TestRenderRejectsDoH3WithGuidance`.

## 2. Fallback DoH→DoT→plain и split-DNS для .ru — отсутствуют, и это честно
Фич нет; `docs/usage.md` прямо предупреждает про блокировку Cloudflare/Google; sing-box перебирает серверы по порядку (поведение движка). `NameserverPolicy` — мёртвое поле, ни control, ни UI его не заполняют. Ничего не врало — фиксировать нечего, не слоп.

## 3. Captive portal детект — отсутствует
Только упоминания в классификации (`probe/classify.go`, `censor/detect.go`); детекта при коннекте нет. Зафиксировано как пробел, не враньё.

## 4. FakeIP: не было IPv6-пула
- **Было:** sing-box fakeip-сервер рендерился только с `inet4_range`; при включённом IPv6 AAAA-запросы шли на fakeip без v6-пула.
- **Стало (в истории ветки):** поле плана `DNS.FakeIPRange6` + валидация «именно IPv6-CIDR»; sing-box рендерит обязательный `inet6_range` (дефолт `fc00::/18`) когда IPv6 on, опускает когда off; mihomo v6 fake-ip не умеет апстримно. Исключения `.local`/`.lan`/mDNS/NTP/OS-пробы есть (`DefaultFakeIPFilter`). FakeIP-режим недостижим из UI/proto (`DnsPolicy` без fakeip-полей) — придумывать что-то было бы слопом.
- **Эффект:** AAAA через fakeip больше не уходит в пустоту. Тесты D17 (в патче): `TestFakeIPRange6Validation` (+негативы), `TestFakeIPRendersIPv6RangeWhenIPv6IsOn`, `TestFakeIPOmitsIPv6RangeWhenIPv6IsOff`.

## Передано другим (не зона D17)
- **UI-пресеты DNS врут про транспорт** (Dart): пресеты Cloudflare/Google/Quad9/AdGuard задают голые IP → парсятся как plaintext UDP, хотя docs обещают DoH-дефолты. Фикс: `https://…/dns-query` в `_presets` (`app/lib/src/ui/dns.dart`) — отдать UI-агенту.
- `DnsPolicy.block_private` (proto) — мёртвое поле, `control/plan.go` его не читает (см. D08).
- mihomo `buildDNS`: захардкоженный фолбэк `223.5.5.5` при пустых списках (см. вопрос владельцу #1).
