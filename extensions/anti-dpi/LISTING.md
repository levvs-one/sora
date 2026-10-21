# Store listing — Anti-DPI

- **Name:** Anti-DPI
- **Extension id:** `org.sora.anti-dpi`
- **Version:** 1.0.0
- **Author:** Sora Team (github:levvs-one)
- **Categories:** Bypasses & network hooks, Tools
- **Screenshots:** pending (to be captured from the running app before
  catalog publication; none are bundled with this listing)

## Short description

**EN:** DPI-bypass control panel: curated presets, a full strategy
editor, per-host bindings and automatic tuning through the core.

**RU:** Панель управления обходом DPI: готовые пресеты, полный
редактор стратегий, привязки по хостам и автоподбор через ядро.

## Full description

**EN:**

Anti-DPI puts Sora's DPI-bypass machinery into one panel.

- **Presets.** The core tuner's own registry (SNI-block, stall,
  QUIC-throttle and KZ-variant strategies) plus the classic tpws
  strategies — each with an honest explanation of the mechanism, the
  censorship class it targets, and its costs and risks. Each preset
  declares a `scope`: three `midsni` presets are binding-only (the
  marker resolves against a concrete domain, so they apply solely to
  a plain-domain binding, never as the global strategy); the rest are
  global-scoped.
- **Editor.** Every `BypassStrategy` field, grouped (split & order,
  TLS record, HTTP form, nfqws desync, port/L7 filters), with hints
  per field and validation that mirrors the core: what the core would
  reject is flagged before you apply it.
- **Bindings.** Different strategies for different hosts: bind a
  strategy to a domain, address or network. Your in-app bypass rules
  always win over the extension's bindings.
- **Auto-tune.** The core scores candidate strategies against your
  current network live; apply the winner in one click — or get an
  honest explanation when the winner was bound to a network profile
  instead.
- **Monitor.** A live feed of the censorship events the core detects,
  in human language (EN/RU).
- **Profiles.** Export, import and reset the whole bypass layer as
  JSON.

Applying is explicit: edits stay local until you press Apply, the
layer takes effect on the next connection, and the panel always shows
what came from you, from this extension, or from the core default.

**RU:**

Anti-DPI собирает механизмы обхода DPI из Sora в одной панели.

- **Пресеты.** Собственный реестр тюнера ядра (стратегии против
  блокировки по SNI, зависаний, троттлинга QUIC и казахстанского
  варианта) плюс классические стратегии tpws — каждая с честным
  объяснением механизма, класса цензуры, против которого она работает,
  и её цены и рисков. У каждого пресета указана область применения
  (scope): три пресета с маркером midsni — только для привязок (маркер разрешается по
  конкретному домену, поэтому они применимы лишь к привязке с обычным
  доменом, а не как глобальная стратегия); остальные — глобальные.
- **Редактор.** Все поля `BypassStrategy`, сгруппированные (сплит и
  порядок, TLS-запись, HTTP-форма, nfqws-десинк, фильтры портов и
  L7), с подсказками по каждому полю и валидацией, зеркалящей ядро:
  то, что ядро отклонило бы, подсветится до применения.
- **Привязки.** Разные стратегии для разных хостов: привяжите
  стратегию к домену, адресу или сети. Ваши правила обхода в
  приложении всегда сильнее привязок расширения.
- **Автоподбор.** Ядро вживую оценивает стратегии-кандидаты на вашей
  текущей сети; победитель применяется в один клик — либо вы получите
  честное объяснение, если победитель был привязан к сетевому
  профилю.
- **Монитор.** Живая лента событий цензуры, которые обнаруживает
  ядро, человеческим языком (EN/RU).
- **Профили.** Экспорт, импорт и сброс всего слоя обхода как JSON.

Применение — явное: правки остаются локальными, пока вы не нажмёте
«Применить», слой действует со следующего подключения, а панель
всегда показывает, что пришло от вас, от этого расширения или из
дефолта ядра.

## Permissions — justification for each

| Permission | Justification |
|---|---|
| `ui.panel` | The extension is a panel; without it there is nothing to show. |
| `bypass.read` | Reads bypass capabilities, state and the current layer so the panel can display what the device supports and what is applied. It exposes no traffic content, no hosts you visited and no credentials. |
| `bypass.write` | Applies the layer (global strategy + bindings) the user explicitly built and confirmed in the panel. Nothing is written without the Apply action. |
| `bypass.tune` | Runs the core's strategy auto-tuner against the current network when the user presses the button. |
| `notifications` | A single notification confirming that a layer was applied (the panel reports the same in-place). |

## Honest limitations

- Strategies take effect on the **next connection**, not on the
  session already running.
- **tpws** covers TCP only (HTTP/TLS); **nfqws** strategies need the
  nfqws backend, which the core may report unavailable on a given
  platform (the panel shows the core's reason instead of hiding it).
- The two backends cannot be mixed in one strategy; the editor
  enforces the core's rule.
- No desync strategy defeats every censor: full stream reassembly
  defeats splits, fixed-TTL fakes are path guesses, and a hard
  whitelist/MITM posture needs a whitelisted front, not a strategy.
  Preset cards state the limit of each preset.
- The panel cannot read your subscriptions, traffic or credentials —
  no permission for that exists, and it does not ask for one.
- This build is signed with a developer key; catalog publication
  follows the owner's key ceremony, after which the listing will pin
  the ceremony key.
