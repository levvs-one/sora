# Glossary / Глоссарий — sora Apple clients

One concept = one term, in every string, in both languages. The ARB files
of the main app (`app/lib/l10n/`) are the source of usage; this glossary
fixes the pairs for the Apple port and for any new `state.*` / `alert.*` /
`notify.*` keys. Consistency is enforced by `check_glossary.py` (run it
after regenerating the catalog).

| Concept | EN (only this) | RU (only this) | Never use | Notes |
|---|---|---|---|---|
| server | server | сервер | node, relay; узел | A single outbound endpoint the user picks. |
| host | host | хост | — (not a synonym of server) | Distinct concept: the destination host of a live connection, the `Host` header case transform, an extension's allowed network hosts (`connCopyHost`, `hostCase`, `extPermNetworkDetail`). |
| subscription | subscription | подписка | membership, abonnement; абонемент | A provider feed that yields servers. `plan` is allowed only for a provider's tariff (`modesGuide`: "your plan's bandwidth"). |
| connection (state/process) | connection, connect | подключение, подключить | подсоединение, коннект | The act/state of being connected. |
| connection (one flow) | connection | соединение | — | Distinct, narrower: one row in the Connections list (`connConnectionsCount`). Same EN word, different RU word — do not "unify" them. |
| tunnel | tunnel | туннель | тоннель, тунель | The VPN tunnel as a whole. |
| chain | chain | цепочка | cascade; каскад | Proxy chain (several servers in sequence). |
| network profile | profile | профиль | — | sora's own network profile (auto-apply by SSID/gateway, main-app F5). |
| VPN profile | VPN profile / VPN configuration | VPN-профиль / VPN-конфигурация | — (not "profile" alone in system contexts) | Distinct concept: the *system* VPN configuration the OS approves (`state.vpnProfile*`, `state.profileNotCreated`). In `state.*` keys always say "VPN profile", never bare "profile". |
| kill switch | kill switch | kill switch | аварийный выключатель | Kept untranslated in RU in the main app (`killSwitch`); do not invent a RU rendering in new keys. |
| extension | network extension | сетевое расширение | плагин, аддон | The PacketTunnel provider / system extension. "Extension" alone is fine after first mention. |
| engine | engine | ядро (движок only for the engine binaries in packaging contexts) | мотор | The proxy core (sing-box/Xray/mihomo) as the main app calls it. |

## Style for empty states and errors (all locales)

Not literal calques. One pattern in both languages, comparable length:

- **Empty state:** what is empty + the one action that fills it.
  EN: "No servers yet. Add a subscription or import a link."
  RU: «Пока нет серверов. Добавьте подписку или импортируйте ссылку.»
- **Error / honest state (`state.*`):** what happened + what the user does
  next, one or two short sentences. No raw system text, no blame, no
  exclamation marks.
  EN: "VPN profile not approved yet. Open Settings and allow Sora to add
  a VPN configuration, then try again."
  RU: «VPN-профиль ещё не одобрен. Откройте «Настройки» и разрешите Sora
  добавить VPN-конфигурацию, затем попробуйте снова.»
- Keep RU and EN within ~±30% length of each other; if the RU needs three
  sentences, the EN is too terse (or vice versa).

## Check result (2026-10-20, catalog as generated)

`python3 check_glossary.py` → **0 violations, 5 sanctioned exceptions**
(keys where an intruder word carries the distinct meaning above):
`connCopyHost` (en+ru, host), `hostCase` (en, host), `extPermNetworkDetail`
(ru, хосты), `modesGuide` (en, tariff plan). The script exits non-zero on
any non-allowlisted hit, so future ARB imports cannot silently drift.
