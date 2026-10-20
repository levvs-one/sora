# D3 — core/engine/singbox route/DNS (commit 1c40351, +149/−6)

## rule_set.download_detour — баг, исправлен
- Было: `rs["download_detour"] = final`. При final=direct скачивание rule-set шло напрямую; в RU raw.githubusercontent.com режется → geo-правила молча не работали. Комментарий при этом врал («через default route»).
- Стало: `ruleSetDetour()` — final через прокси → detour=final; final=direct но прокси есть → detour=тег первого прокси; прокси нет → ключ не рендерится.
- Эффект: geo rule-set'ы качаются через прокси везде, где он есть.
- Тесты: позитив/негатив/лок поведения — PASS.

## prefer_ipv6 — врущий дефолт, исправлен
- Было: `Options.IPv6=true → strategy="prefer_ipv4"` — ровно дефолт движка; тумблер «включить IPv6» деприоритизировал IPv6.
- Стало: `IPv6=true → "prefer_ipv6"`, `false → "ipv4_only"`.
- Эффект: DNS-стратегия честно отражает тумблер. Тест PASS.

## tls_fragment — проброс есть, фиксить нечего
- Fragment.Enabled → tls.fragment на TCP; hy2/TUIC пропускаются (у QUIC нет TCP ClientHello). Packets/Length/Interval у sing-box — bool-only, ограничение движка.

## QUIC в mux — нечему ломаться
- Mux как концепт отсутствует в engine.Plan; негативный тест TestRenderNeverEmitsMultiplex (все 11 протоколов) — PASS.

## Замечания вне зоны
- engine/mihomo/config.go:148 — smux объявлен, но рендер не выставляет: мёртвый код (зона D6, он в работе).
- TestTunAndFakeIPAvoidLANAndEachOther падает и на чистом дереве — предсуществующее, VM.
