# D1 — core/engine/singbox TUN (commit 767499b, 63+/2-, через временный индекс)

## `"stack": "mixed"` — больше не рендерится
- Было: tun() всегда писал `"stack": orDefault(t.Stack, "mixed")`.
- Стало: ключ stack отсутствует в JSON. Deprecated в 1.15, удаление в 1.17; миграция sing-box — убрать stack для нового TCP/IP-стека. На 1.12–1.14 отсутствие = дефолт движка (тот же mixed). plan.Tun.Stack сохранён (mihomo/Xray-бридж его честно используют; для sing-box теперь no-op by design).
- Эффект: на 1.15+ новый быстрый стек вместо deprecation-warning и будущего сломанного конфига.
- Тест TestTunDropsDeprecatedStack ("", mixed, system, gvisor → ключа нет) — PASS.

## MTU 9000 → 1500
- Было: `"mtu": orDefaultInt(t.MTU, 9000)`.
- Стало: константа tunDefaultMTU=1500, хелпер tunMTU() (явный MTU плана побеждает; 0/отрицательный → 1500). 1400 — документированная PPPoE-альтернатива.
- Эффект: нет анонса MSS 8960 на TUN, сегменты 1460 проходят без фрагментации и PMTUD black holes.
- Тест TestTunMTUDefaultsSane — PASS.

## Хвосты другим отделам
- MSS clamping в рендере невозможен (у sing-box нет ручки) — только iptables/nftables TCPMSS в engine/tunroute (спека).
- mihomo MTU 9000 + протухший комментарий «sing-box uses 9000» — комментарий починен D18; дефолт mihomo 9000 оставлен осознанно.
- Tun.MTU не выставляется: нет proto-поля и UI — срабатывает только дефолт рендера.
- Дерево core/engine было сломано чужим naive-коммитом — тесты гонялись в изолированном worktree на HEAD.
