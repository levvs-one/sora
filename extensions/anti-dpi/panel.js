/* Anti-DPI panel (org.sora.anti-dpi).
 *
 * Vanilla JS, no external resources, CSP-safe: every string that comes
 * from the core, from events or from imported JSON is rendered through
 * textContent/createElement only — this file never assigns untrusted
 * text to innerHTML.
 *
 * The only bridge to the app is window.soraExt.call (see
 * docs/extensions-api.md plus the bypass contract in README.md).
 *
 * STRINGS and PRESETS below are generated from strings.json and
 * presets.json (the package's single source of truth for both) because
 * panels cannot fetch at runtime under the panel CSP
 * (connect-src 'none'). Regenerate with the snippet in README.md.
 */
'use strict';

var STRINGS = {
 "en": {
  "app_title": "Anti-DPI",
  "app_sub": "DPI-bypass strategies for this device: presets, a full strategy editor, per-host bindings and automatic tuning.",
  "tab_overview": "Overview",
  "tab_presets": "Presets",
  "tab_editor": "Editor",
  "tab_bindings": "Bindings",
  "tab_tune": "Auto-tune",
  "tab_monitor": "Monitor",
  "tab_profiles": "Profiles",
  "loading": "Loading…",
  "bridge_missing": "The extension bridge is unavailable. Open this panel inside Sora, or run it with the sora-ext dev server (mock).",
  "platform": "Platform",
  "backends": "Backends",
  "backend_available": "available",
  "backend_unavailable": "unavailable",
  "current_state": "Current state",
  "global_source": "Global strategy source",
  "source_user": "Your in-app bypass settings",
  "source_extension": "An extension (this layer)",
  "source_core_default": "Core default",
  "source_none": "No bypass configured",
  "source_unknown": "Unknown source",
  "global_from": "Set by",
  "session_active": "VPN session",
  "session_on": "connected",
  "session_off": "not connected",
  "pending_apply": "Pending apply",
  "pending_yes": "Changes apply on the next connection",
  "pending_no": "Nothing pending",
  "bindings_count": "Bindings in this layer",
  "active_global": "Active global strategy",
  "no_global": "No global strategy in this layer.",
  "custom_strategy": "Custom strategy",
  "updated_at": "Layer updated",
  "refresh": "Refresh",
  "apply": "Apply",
  "apply_global": "Apply as global",
  "apply_layer": "Apply layer to core",
  "confirm_apply_title": "Apply this layer?",
  "confirm_apply_body": "The layer is sent to the core now and takes effect on the next connection. Your in-app bypass rules keep priority over this extension's bindings.",
  "confirm": "Apply",
  "cancel": "Cancel",
  "applied_ok": "Layer applied. It takes effect on the next connection.",
  "dirty": "Unsaved changes (not yet applied to the core)",
  "clean": "In sync with the core layer",
  "preset_apply": "Apply",
  "preset_to_editor": "To editor",
  "preset_targets": "Targets",
  "preset_cost": "Cost / risks",
  "preset_backends": "Backends",
  "editor_intro": "Every BypassStrategy field. Validation mirrors the core: a strategy the core would reject is flagged here before you apply it.",
  "group_split": "Split & order",
  "group_tls": "TLS record",
  "group_http": "HTTP form",
  "group_desync": "nfqws desync",
  "group_filters": "Port & L7 filters",
  "gate_nfqws": "nfqws only",
  "gate_tpws": "tpws only",
  "gate_unavailable": "backend unavailable on this device",
  "reset_to_preset": "Reset to preset",
  "choose_preset": "Choose a preset…",
  "list_hint": "One value per line.",
  "validation_errors": "Fix these before applying:",
  "strategy_empty_ok": "Empty strategy (clears the global strategy when applied).",
  "bindings_intro": "A binding applies its strategy to one match in the core's destination form (for example \"domain:example.com\", an address or a network). Bindings are applied together with the global strategy in one layer.",
  "bindings_precedence": "Precedence: your in-app bypass rules win over this extension's bindings. On conflict, the app keeps your rule and the binding is ignored for that traffic.",
  "binding_match": "Match (domain / address / network)",
  "binding_strategy": "Strategy",
  "binding_add": "Add binding",
  "binding_delete": "Delete",
  "binding_edit": "Edit in editor",
  "binding_from_preset": "from preset",
  "binding_from_editor": "Use current editor strategy",
  "bindings_empty": "No bindings yet.",
  "tune_intro": "The core tries candidate strategies against your current network and scores them live. Nothing is applied automatically.",
  "tune_engine": "Engine",
  "tune_engine_auto": "Auto (core chooses)",
  "tune_run": "Run auto-tune",
  "tune_running": "Tuning… this can take a while.",
  "tune_winner": "Winner",
  "tune_score": "Score",
  "tune_attempts": "Attempts",
  "tune_apply_winner": "Apply winner as global",
  "tune_bound_to_profile": "The core bound this winner to your network profile instead of returning a raw strategy: it will take effect through that profile when this network is matched. There is nothing to apply here manually.",
  "tune_no_winner": "No winner was returned.",
  "monitor_intro": "Censorship events reported by the core for this session.",
  "monitor_empty": "No events yet. When the core detects censorship on a connection, it will appear here.",
  "monitor_clear": "Clear list",
  "profiles_intro": "Export or import the whole layer (global strategy + bindings) as JSON. Panels have no file dialogs, so copy and paste the text.",
  "export_label": "Exported layer JSON",
  "import_label": "Paste a layer JSON to import",
  "import_preview": "Import preview",
  "import_load": "Load into draft",
  "import_invalid": "That text is not a valid layer:",
  "reset_all": "Reset everything",
  "reset_all_body": "Clears the draft global strategy and all bindings. Apply afterwards to push the empty layer to the core.",
  "settings_language": "Panel language",
  "lang_auto": "Auto (app/browser)",
  "error_permission": "Permission denied: this extension was not granted the bypass permission this action needs.",
  "error_invalid": "The core rejected the arguments as invalid.",
  "error_internal": "The core could not complete the call (internal error).",
  "error_generic": "The call failed.",
  "censorship_event": "Censorship detected",
  "event_session_connected": "Session connected",
  "event_session_disconnected": "Session disconnected",
  "event_panel_ready": "Panel ready",
  "at_time": "at",
  "fields": {
   "split_pos": {
    "label": "Split positions",
    "hint": "Where the handshake is cut: byte counts (\"1\", \"-10\" counts from the end) or markers method/host/endhost/sld/midsld/endsld/sniext with an optional +N/-N offset. \"midsni\" is the registry marker for the middle of the actual SNI — the core resolves it per target. Up to 8 positions. Needed by disorder and oob."
   },
   "disorder": {
    "label": "Disorder (send 2nd part first)",
    "hint": "tpws: sends the second part of a split first. On nfqws this is spelled as the disorder/disorder2 desync method instead — core validation rejects disorder together with desync methods."
   },
   "disorder_scope": {
    "label": "Disorder scope",
    "hint": "Limits disorder to one protocol: empty = both, http, or tls. Requires disorder."
   },
   "oob": {
    "label": "Out-of-band byte",
    "hint": "tpws: attaches an out-of-band (urgent) byte at the split so DPI misreads the stream. Requires a split position."
   },
   "oob_scope": {
    "label": "OOB scope",
    "hint": "Limits the out-of-band byte to one protocol: empty = both, http, or tls. Requires oob."
   },
   "oob_data": {
    "label": "OOB byte value",
    "hint": "Overrides the default 0x00 out-of-band byte: one character or 0xHH hex. Requires oob."
   },
   "split_any_protocol": {
    "label": "Split any protocol",
    "hint": "tpws: applies the split to every protocol's first flight, not only HTTP and TLS. Can break protocols whose servers dislike fragmented first flights. tpws-only: rejected together with desync methods."
   },
   "tamper_start": {
    "label": "Tamper start",
    "hint": "Handshake shaping starts at or after this stream position (zapret --tamper-start). Same syntax as split positions, with an optional leading \"n\" selecting a data block number. tpws-only."
   },
   "tamper_cutoff": {
    "label": "Tamper cutoff",
    "hint": "Handshake shaping stops after this position (zapret --tamper-cutoff). Same syntax as tamper start. tpws-only."
   },
   "mss": {
    "label": "MSS clamp",
    "hint": "Clamps the TCP maximum segment size, a plain byte count 64–65495 (zapret --mss). tpws-only."
   },
   "tls_record": {
    "label": "TLS record split",
    "hint": "Re-splits the ClientHello into two TLS records at this position (for example sniext+1). tpws-only: rejected together with desync methods."
   },
   "host_case": {
    "label": "Host case shuffle",
    "hint": "Randomizes letter case in the HTTP Host header (HoSt:). Plain HTTP only."
   },
   "domain_case": {
    "label": "Domain case shuffle",
    "hint": "Randomizes letter case in the requested domain. Plain HTTP only."
   },
   "method_eol": {
    "label": "Method EOL",
    "hint": "Adds an extra end-of-line after the HTTP method. Plain HTTP only."
   },
   "host_dot": {
    "label": "Host trailing dot",
    "hint": "Appends \".\" after the Host: name (example.com.). Plain HTTP only."
   },
   "host_tab": {
    "label": "Host tab",
    "hint": "Replaces the space after Host: with a tab. Plain HTTP only."
   },
   "host_no_space": {
    "label": "Host no space",
    "hint": "Removes the space after Host:. Plain HTTP only; fights host_tab over the same separator."
   },
   "method_space": {
    "label": "Method extra space",
    "hint": "Adds an extra space after the HTTP method. Plain HTTP only."
   },
   "unix_eol": {
    "label": "Unix EOL",
    "hint": "Replaces CRLF with LF in plain-HTTP requests. Plain HTTP only."
   },
   "desync": {
    "label": "Desync methods (nfqws)",
    "hint": "nfqws --dpi-desync methods, in order (fake, split2, disorder2, multisplit and the other modes core validation lists). Any entry selects the nfqws backend. A strategy with desync methods cannot also use tpws-only fields."
   },
   "fake_tls": {
    "label": "Fake TLS payload",
    "hint": "\"tls\" keeps zapret's built-in fake ClientHello; anything else is a file name under the zapret home. Requires the fake desync method."
   },
   "fake_quic": {
    "label": "Fake QUIC payload",
    "hint": "Fake payload for QUIC: a file name under the zapret home (QUIC has no built-in fake; the shipped Initial is used for the \"quic\" keyword). Requires the fake desync method and filter_udp covering 443."
   },
   "fooling": {
    "label": "Fooling",
    "hint": "Degrades the fake/disorder packet so the censor's stack drops it while the real server tolerates it: badseq, badack, md5sig, ts, badsum, datanoack (comma-separated list allowed). Requires a desync method."
   },
   "ttl": {
    "label": "Fake TTL",
    "hint": "Fixes the fake packet TTL (1–255) so it dies before the server. 0 = unset. Mutually exclusive with autottl. Requires the fake desync method. A fixed TTL is a path guess: too small dies before the censor, too large can reach the server."
   },
   "auto_ttl": {
    "label": "Auto TTL",
    "hint": "Derives the fake packet TTL from the path instead of fixing it. Mutually exclusive with a fixed TTL. Requires the fake desync method."
   },
   "repeats": {
    "label": "Fake repeats",
    "hint": "Duplicates the fake injection (1–16). 0 = unset. Requires the fake desync method."
   },
   "filter_tcp": {
    "label": "Filter TCP ports",
    "hint": "Intercepted TCP ports, e.g. \"80,443\" (port ranges allowed). nfqws-only: requires a desync method."
   },
   "filter_udp": {
    "label": "Filter UDP ports",
    "hint": "Intercepted UDP ports, e.g. \"443\". UDP/QUIC desync needs this. nfqws-only: requires a desync method."
   },
   "filter_l7": {
    "label": "Filter L7",
    "hint": "Limits desync to application layers, comma-separated: http, tls, quic, wireguard, dht, discord, stun, unknown. nfqws-only: requires a desync method."
   }
  },
  "groups": {
   "split": "Split & order",
   "tls": "TLS record",
   "http": "HTTP form",
   "desync": "nfqws desync",
   "filters": "Port & L7 filters"
  },
  "censorship_kinds": {
   "sni_block": "SNI block",
   "stall": "Handshake stall",
   "quic_throttle": "QUIC throttling",
   "kz_variant": "Whitelist/MITM variant (KZ)",
   "dns_hijack": "DNS hijack",
   "connection_reset": "Connection reset",
   "timeout": "Connection timeout",
   "unknown": "Censorship"
  },
  "sources": {
   "user": "Your in-app bypass settings",
   "extension": "An extension (this layer)",
   "core_default": "Core default",
   "none": "No bypass configured"
  },
  "v_changes_nothing": "The strategy changes nothing: set at least one of split positions, TLS record, MSS, a desync method, or an HTTP-form option.",
  "v_splitpos_pattern": "is not a split position (byte count or marker with optional ±offset; \"midsni\" is allowed as the registry marker)",
  "v_splitpos_max": "More than 8 split positions.",
  "v_desync_max": "More than 8 desync methods.",
  "v_desync_mode": "is not a dpi-desync method the core knows",
  "v_mix_tpws": "is a tpws-only option: a strategy with desync methods runs on nfqws, which does not render it — clear the desync methods or this field",
  "v_scope_val": "must be empty, \"http\" or \"tls\"",
  "v_disorder_scope_req": "A disorder scope needs disorder.",
  "v_oob_scope_req": "An out-of-band scope needs oob.",
  "v_need_split": "Disorder and out-of-band bytes need a split position.",
  "v_oob_data_req": "An out-of-band byte value needs oob.",
  "v_oob_data_pattern": "The OOB byte must be one character or 0xHH.",
  "v_mss_range": "MSS must be a byte count in 64–65495.",
  "v_tamper_pattern": "is not a tamper position (split-position syntax, optional leading \"n\")",
  "v_pos_pattern": "is not a valid position",
  "v_fooling_req": "Fooling needs a desync method (nfqws-only).",
  "v_fooling_mode": "is not a fooling mode (badseq, badack, md5sig, ts, badsum, datanoack, hopbyhop, hopbyhop2, none)",
  "v_fake_req": "Fake payloads need the fake desync method.",
  "v_fake_name": "must be a built-in keyword or a plain file name (no path)",
  "v_fakequic_udp": "A QUIC fake needs filter_udp (QUIC runs over UDP).",
  "v_ttl_range": "Fake TTL must be in 1–255 (0 = unset).",
  "v_ttl_fake": "A fake TTL needs the fake desync method.",
  "v_ttl_xor": "A fake TTL and autottl are mutually exclusive.",
  "v_autottl_fake": "Autottl needs the fake desync method.",
  "v_repeats_range": "Repeats must be in 1–16 (0 = unset).",
  "v_repeats_fake": "Repeats need the fake desync method.",
  "v_filter_req": "Port/L7 filters need a desync method (nfqws-only).",
  "v_filter_ports": "is not a port list (e.g. 80,443 or 1000-2000)",
  "v_filter_port_range": "Port out of range 1–65535 in",
  "v_filter_l7_val": "is not a filter-l7 protocol (http, tls, quic, wireguard, dht, discord, stun, unknown)",
  "field_prefix": "Field",
  "value_prefix": "Value",
  "desync_modes_label": "Known desync modes"
 },
 "ru": {
  "app_title": "Anti-DPI",
  "app_sub": "Стратегии обхода DPI для этого устройства: пресеты, полный редактор стратегии, привязки по хостам и автоподбор.",
  "tab_overview": "Обзор",
  "tab_presets": "Пресеты",
  "tab_editor": "Редактор",
  "tab_bindings": "Привязки",
  "tab_tune": "Автоподбор",
  "tab_monitor": "Монитор",
  "tab_profiles": "Профили",
  "loading": "Загрузка…",
  "bridge_missing": "Мост расширения недоступен. Откройте панель внутри Sora или через dev-сервер sora-ext (mock).",
  "platform": "Платформа",
  "backends": "Бэкенды",
  "backend_available": "доступен",
  "backend_unavailable": "недоступен",
  "current_state": "Текущее состояние",
  "global_source": "Источник глобальной стратегии",
  "source_user": "Ваши настройки обхода в приложении",
  "source_extension": "Расширение (этот слой)",
  "source_core_default": "Дефолт ядра",
  "source_none": "Обход не настроен",
  "source_unknown": "Неизвестный источник",
  "global_from": "Установлено",
  "session_active": "VPN-сессия",
  "session_on": "подключена",
  "session_off": "не подключена",
  "pending_apply": "Ожидает применения",
  "pending_yes": "Изменения применятся при следующем подключении",
  "pending_no": "Нет ожидающих изменений",
  "bindings_count": "Привязок в этом слое",
  "active_global": "Активная глобальная стратегия",
  "no_global": "В этом слое нет глобальной стратегии.",
  "custom_strategy": "Своя стратегия",
  "updated_at": "Слой обновлён",
  "refresh": "Обновить",
  "apply": "Применить",
  "apply_global": "Применить как глобальную",
  "apply_layer": "Применить слой в ядро",
  "confirm_apply_title": "Применить этот слой?",
  "confirm_apply_body": "Слой отправится в ядро сейчас и подействует при следующем подключении. Ваши правила обхода в приложении сохраняют приоритет над привязками этого расширения.",
  "confirm": "Применить",
  "cancel": "Отмена",
  "applied_ok": "Слой применён. Подействует при следующем подключении.",
  "dirty": "Несохранённые изменения (ещё не применены в ядро)",
  "clean": "Синхронно со слоем ядра",
  "preset_apply": "Применить",
  "preset_to_editor": "В редактор",
  "preset_targets": "Против чего",
  "preset_cost": "Цена / риски",
  "preset_backends": "Бэкенды",
  "editor_intro": "Все поля BypassStrategy. Валидация зеркалит ядро: стратегия, которую ядро отклонило бы, подсветится здесь до применения.",
  "group_split": "Сплит и порядок",
  "group_tls": "TLS-запись",
  "group_http": "HTTP-форма",
  "group_desync": "nfqws-десинк",
  "group_filters": "Фильтры портов и L7",
  "gate_nfqws": "только nfqws",
  "gate_tpws": "только tpws",
  "gate_unavailable": "бэкенд недоступен на этом устройстве",
  "reset_to_preset": "Сбросить к пресету",
  "choose_preset": "Выберите пресет…",
  "list_hint": "По одному значению на строку.",
  "validation_errors": "Исправьте перед применением:",
  "strategy_empty_ok": "Пустая стратегия (при применении очистит глобальную стратегию).",
  "bindings_intro": "Привязка применяет свою стратегию к одному совпадению в форме назначения ядра (например, «domain:example.com», адрес или сеть). Привязки применяются вместе с глобальной стратегией одним слоем.",
  "bindings_precedence": "Приоритет: ваши правила обхода в приложении сильнее привязок этого расширения. При конфликте приложение оставит ваше правило, а привязка для этого трафика будет проигнорирована.",
  "binding_match": "Совпадение (домен / адрес / сеть)",
  "binding_strategy": "Стратегия",
  "binding_add": "Добавить привязку",
  "binding_delete": "Удалить",
  "binding_edit": "В редактор",
  "binding_from_preset": "из пресета",
  "binding_from_editor": "Взять стратегию из редактора",
  "bindings_empty": "Привязок пока нет.",
  "tune_intro": "Ядро пробует стратегии-кандидаты на вашей текущей сети и оценивает их вживую. Автоматически ничего не применяется.",
  "tune_engine": "Движок",
  "tune_engine_auto": "Авто (выбирает ядро)",
  "tune_run": "Запустить подбор",
  "tune_running": "Подбор… это может занять время.",
  "tune_winner": "Победитель",
  "tune_score": "Оценка",
  "tune_attempts": "Попыток",
  "tune_apply_winner": "Применить победителя как глобальную",
  "tune_bound_to_profile": "Ядро привязало этого победителя к вашему сетевому профилю вместо возврата сырой стратегии: он подействует через профиль при совпадении этой сети. Вручную здесь применять нечего.",
  "tune_no_winner": "Победитель не возвращён.",
  "monitor_intro": "События цензуры, о которых ядро сообщило в этой сессии.",
  "monitor_empty": "Событий пока нет. Когда ядро обнаружит цензуру на соединении, событие появится здесь.",
  "monitor_clear": "Очистить список",
  "profiles_intro": "Экспорт и импорт всего слоя (глобальная стратегия + привязки) как JSON. Файловых диалогов у панелей нет — копируйте и вставляйте текст.",
  "export_label": "JSON экспортированного слоя",
  "import_label": "Вставьте JSON слоя для импорта",
  "import_preview": "Предпросмотр импорта",
  "import_load": "Загрузить в черновик",
  "import_invalid": "Этот текст не является валидным слоем:",
  "reset_all": "Сбросить всё",
  "reset_all_body": "Очищает черновик глобальной стратегии и все привязки. Затем нажмите «Применить», чтобы отправить пустой слой в ядро.",
  "settings_language": "Язык панели",
  "lang_auto": "Авто (приложение/браузер)",
  "error_permission": "Нет разрешения: этому расширению не выдано разрешение на обход, нужное для действия.",
  "error_invalid": "Ядро отклонило аргументы как невалидные.",
  "error_internal": "Ядро не смогло выполнить вызов (внутренняя ошибка).",
  "error_generic": "Вызов не удался.",
  "censorship_event": "Обнаружена цензура",
  "event_session_connected": "Сессия подключена",
  "event_session_disconnected": "Сессия отключена",
  "event_panel_ready": "Панель готова",
  "at_time": "в",
  "fields": {
   "split_pos": {
    "label": "Позиции сплита",
    "hint": "Где режется handshake: число байтов («1», «-10» — от конца) или маркеры method/host/endhost/sld/midsld/endsld/sniext с необязательным смещением +N/-N. «midsni» — реестровый маркер середины фактического SNI, ядро разрешает его по цели. До 8 позиций. Нужны для disorder и oob."
   },
   "disorder": {
    "label": "Disorder (вторая часть первой)",
    "hint": "tpws: отправляет вторую часть сплита первой. На nfqws это пишется методом desync disorder/disorder2 — валидация ядра отклоняет disorder вместе с методами desync."
   },
   "disorder_scope": {
    "label": "Область disorder",
    "hint": "Ограничивает disorder одним протоколом: пусто = оба, http или tls. Требует disorder."
   },
   "oob": {
    "label": "Внеполосный байт (OOB)",
    "hint": "tpws: добавляет внеполосный (urgent) байт на разрезе, чтобы DPI неверно прочитал поток. Требует позицию сплита."
   },
   "oob_scope": {
    "label": "Область OOB",
    "hint": "Ограничивает внеполосный байт одним протоколом: пусто = оба, http или tls. Требует oob."
   },
   "oob_data": {
    "label": "Значение байта OOB",
    "hint": "Переопределяет внеполосный байт 0x00 по умолчанию: один символ или 0xHH в hex. Требует oob."
   },
   "split_any_protocol": {
    "label": "Сплит любого протокола",
    "hint": "tpws: применяет сплит к первому полёту любого протокола, а не только HTTP и TLS. Может ломать протоколы, чьи серверы не любят фрагментированный первый полёт. Только tpws: отклоняется вместе с методами desync."
   },
   "tamper_start": {
    "label": "Начало тамперинга",
    "hint": "Формовка handshake начинается с этой позиции потока (zapret --tamper-start). Синтаксис как у позиций сплита, с необязательной ведущей «n» — номером блока данных. Только tpws."
   },
   "tamper_cutoff": {
    "label": "Конец тамперинга",
    "hint": "Формовка handshake прекращается после этой позиции (zapret --tamper-cutoff). Синтаксис как у начала тамперинга. Только tpws."
   },
   "mss": {
    "label": "Ограничение MSS",
    "hint": "Ограничивает максимальный размер сегмента TCP, число байтов 64–65495 (zapret --mss). Только tpws."
   },
   "tls_record": {
    "label": "Сплит TLS-записи",
    "hint": "Перерезает ClientHello на две TLS-записи в этой позиции (например, sniext+1). Только tpws: отклоняется вместе с методами desync."
   },
   "host_case": {
    "label": "Регистр Host",
    "hint": "Случайный регистр букв в заголовке Host (HoSt:). Только обычный HTTP."
   },
   "domain_case": {
    "label": "Регистр домена",
    "hint": "Случайный регистр букв в запрашиваемом домене. Только обычный HTTP."
   },
   "method_eol": {
    "label": "EOL после метода",
    "hint": "Добавляет лишний конец строки после HTTP-метода. Только обычный HTTP."
   },
   "host_dot": {
    "label": "Точка после Host",
    "hint": "Добавляет «.» после имени в Host: (example.com.). Только обычный HTTP."
   },
   "host_tab": {
    "label": "Таб после Host",
    "hint": "Заменяет пробел после Host: на табуляцию. Только обычный HTTP."
   },
   "host_no_space": {
    "label": "Без пробела после Host",
    "hint": "Убирает пробел после Host:. Только обычный HTTP; спорит с host_tab за тот же разделитель."
   },
   "method_space": {
    "label": "Лишний пробел после метода",
    "hint": "Добавляет лишний пробел после HTTP-метода. Только обычный HTTP."
   },
   "unix_eol": {
    "label": "Unix EOL",
    "hint": "Заменяет CRLF на LF в обычных HTTP-запросах. Только обычный HTTP."
   },
   "desync": {
    "label": "Методы desync (nfqws)",
    "hint": "Методы nfqws --dpi-desync по порядку (fake, split2, disorder2, multisplit и остальные из списка валидации ядра). Любая запись выбирает бэкенд nfqws. Стратегия с методами desync не может одновременно использовать поля только-tpws."
   },
   "fake_tls": {
    "label": "Фейковая нагрузка TLS",
    "hint": "«tls» — встроенный фейковый ClientHello zapret; иное — имя файла в домашнем каталоге zapret. Требует метод desync fake."
   },
   "fake_quic": {
    "label": "Фейковая нагрузка QUIC",
    "hint": "Фейковая нагрузка для QUIC: имя файла в домашнем каталоге zapret (встроенного фейка для QUIC нет; для ключевого слова «quic» используется поставляемый Initial). Требует метод desync fake и filter_udp с портом 443."
   },
   "fooling": {
    "label": "Fooling",
    "hint": "Порча фейкового/disorder-пакета, чтобы стек цензора его отбросил, а настоящий сервер стерпел: badseq, badack, md5sig, ts, badsum, datanoack (допустим список через запятую). Требует метод desync."
   },
   "ttl": {
    "label": "TTL фейка",
    "hint": "Фиксирует TTL фейкового пакета (1–255), чтобы он умирал до сервера. 0 = не задан. Взаимоисключается с autottl. Требует метод desync fake. Фиксированный TTL — догадка о пути: мал — умрёт до цензора, велик — может дойти до сервера."
   },
   "auto_ttl": {
    "label": "Авто-TTL",
    "hint": "Выводит TTL фейкового пакета из пути вместо фиксации. Взаимоисключается с фиксированным TTL. Требует метод desync fake."
   },
   "repeats": {
    "label": "Повторы фейка",
    "hint": "Дублирует инжекцию фейка (1–16). 0 = не задано. Требует метод desync fake."
   },
   "filter_tcp": {
    "label": "Фильтр TCP-портов",
    "hint": "Перехватываемые TCP-порты, например «80,443» (допустимы диапазоны). Только nfqws: требует метод desync."
   },
   "filter_udp": {
    "label": "Фильтр UDP-портов",
    "hint": "Перехватываемые UDP-порты, например «443». Для desync UDP/QUIC обязателен. Только nfqws: требует метод desync."
   },
   "filter_l7": {
    "label": "Фильтр L7",
    "hint": "Ограничивает desync прикладными уровнями, через запятую: http, tls, quic, wireguard, dht, discord, stun, unknown. Только nfqws: требует метод desync."
   }
  },
  "groups": {
   "split": "Сплит и порядок",
   "tls": "TLS-запись",
   "http": "HTTP-форма",
   "desync": "nfqws-десинк",
   "filters": "Фильтры портов и L7"
  },
  "censorship_kinds": {
   "sni_block": "Блокировка по SNI",
   "stall": "Зависание handshake",
   "quic_throttle": "Троттлинг QUIC",
   "kz_variant": "Whitelist/MITM-вариант (KZ)",
   "dns_hijack": "Подмена DNS",
   "connection_reset": "Сброс соединения",
   "timeout": "Тайм-аут соединения",
   "unknown": "Цензура"
  },
  "sources": {
   "user": "Ваши настройки обхода в приложении",
   "extension": "Расширение (этот слой)",
   "core_default": "Дефолт ядра",
   "none": "Обход не настроен"
  },
  "v_changes_nothing": "Стратегия ничего не меняет: задайте хотя бы одно из — позиции сплита, TLS-запись, MSS, метод desync или опцию HTTP-формы.",
  "v_splitpos_pattern": "не является позицией сплита (число байтов или маркер с необязательным смещением ±; «midsni» допустим как реестровый маркер)",
  "v_splitpos_max": "Больше 8 позиций сплита.",
  "v_desync_max": "Больше 8 методов desync.",
  "v_desync_mode": "не является методом dpi-desync, известным ядру",
  "v_mix_tpws": "— опция только tpws: стратегия с методами desync работает на nfqws и её не отрендерит — очистите методы desync или это поле",
  "v_scope_val": "должно быть пустым, «http» или «tls»",
  "v_disorder_scope_req": "Область disorder требует включённого disorder.",
  "v_oob_scope_req": "Область OOB требует включённого oob.",
  "v_need_split": "Disorder и внеполосный байт требуют позицию сплита.",
  "v_oob_data_req": "Значение внеполосного байта требует oob.",
  "v_oob_data_pattern": "Байт OOB — один символ или 0xHH.",
  "v_mss_range": "MSS — число байтов в диапазоне 64–65495.",
  "v_tamper_pattern": "не является позицией тамперинга (синтаксис позиции сплита, необязательная ведущая «n»)",
  "v_pos_pattern": "не является валидной позицией",
  "v_fooling_req": "Fooling требует метод desync (только nfqws).",
  "v_fooling_mode": "не является режимом fooling (badseq, badack, md5sig, ts, badsum, datanoack, hopbyhop, hopbyhop2, none)",
  "v_fake_req": "Фейковые нагрузки требуют метод desync fake.",
  "v_fake_name": "должно быть встроенным ключевым словом или простым именем файла (без пути)",
  "v_fakequic_udp": "Фейк QUIC требует filter_udp (QUIC идёт поверх UDP).",
  "v_ttl_range": "TTL фейка — в диапазоне 1–255 (0 = не задан).",
  "v_ttl_fake": "TTL фейка требует метод desync fake.",
  "v_ttl_xor": "TTL фейка и autottl взаимоисключаются.",
  "v_autottl_fake": "Autottl требует метод desync fake.",
  "v_repeats_range": "Повторы — в диапазоне 1–16 (0 = не задано).",
  "v_repeats_fake": "Повторы требуют метод desync fake.",
  "v_filter_req": "Фильтры портов/L7 требуют метод desync (только nfqws).",
  "v_filter_ports": "не является списком портов (например, 80,443 или 1000-2000)",
  "v_filter_port_range": "Порт вне диапазона 1–65535 в",
  "v_filter_l7_val": "не является протоколом filter-l7 (http, tls, quic, wireguard, dht, discord, stun, unknown)",
  "field_prefix": "Поле",
  "value_prefix": "Значение",
  "desync_modes_label": "Известные режимы desync"
 }
};
var PRESETS = [
 {
  "id": "sni_block/split-midsni",
  "name": {
   "en": "Mid-SNI split",
   "ru": "Сплит посередине SNI"
  },
  "description": {
   "en": "Splits the TLS ClientHello in the middle of the actual SNI hostname. The 'midsni' position is a registry marker: the core resolves it against the real target SNI before the strategy is applied, so the cut always lands inside the hostname the censor tries to read.",
   "ru": "Режет TLS ClientHello посередине фактического имени SNI. Позиция «midsni» — реестровый маркер: ядро разрешает его по реальному SNI цели до применения стратегии, поэтому разрез всегда попадает внутрь имени, которое пытается прочитать цензор."
  },
  "targets": {
   "en": "SNI block: the censor reads the ClientHello SNI and kills the connection.",
   "ru": "Блокировка по SNI: цензор читает SNI из ClientHello и рвёт соединение."
  },
  "cost": {
   "en": "Cheapest possible footprint: no fake packets, no extra traffic. A censor that fully reassembles the stream before inspecting it is not fooled.",
   "ru": "Минимальный след: без фейковых пакетов и лишнего трафика. Цензор, полностью собирающий поток до инспекции, не обманется."
  },
  "backends": [
   "tpws"
  ],
  "strategy": {
   "split_pos": [
    "midsni"
   ]
  },
  "source": "core/tune/desync/registry.go sni_block/split-midsni via Params.BypassStrategy() (MethodSplit, marker position, tpws rendering)"
 },
 {
  "id": "sni_block/fake-autottl-badseq",
  "name": {
   "en": "Fake ClientHello, autottl + badseq",
   "ru": "Фейковый ClientHello, autottl + badseq"
  },
  "description": {
   "en": "Injects a fake TLS ClientHello ahead of the real one. The censor classifies and bites the fake; autottl calibrates the fake's TTL from the path so it dies before reaching the server, and badseq fooling makes the censor's stack drop it while the real server would tolerate it.",
   "ru": "Вставляет фейковый TLS ClientHello перед настоящим. Цензор классифицирует и «кусает» фейк; autottl калибрует TTL фейка по пути, чтобы он умер, не дойдя до сервера, а fooling badseq заставляет стек цензора его отбросить."
  },
  "targets": {
   "en": "SNI block on nfqws-capable setups (Linux).",
   "ru": "Блокировка по SNI, где доступен nfqws (Linux)."
  },
  "cost": {
   "en": "Needs the nfqws backend (packet queue, elevated privileges). Autottl needs a short calibration; on paths where the calibration is wrong the fake can occasionally reach the server — the badseq fooling is what protects the real handshake then.",
   "ru": "Нужен бэкенд nfqws (очередь пакетов, повышенные привилегии). Autottl требует короткой калибровки; если она ошиблась, фейк изредка может дойти до сервера — тогда настоящий handshake защищает fooling badseq."
  },
  "backends": [
   "nfqws"
  ],
  "strategy": {
   "split_pos": [
    "2"
   ],
   "desync": [
    "fake"
   ],
   "fake_tls": "tls",
   "fooling": "badseq",
   "auto_ttl": true,
   "filter_tcp": "80,443",
   "filter_l7": "tls"
  },
  "source": "core/tune/desync/registry.go sni_block/fake-autottl-badseq via Params.BypassStrategy() (MethodFake)"
 },
 {
  "id": "sni_block/disorder-midsni",
  "name": {
   "en": "Disorder mid-SNI, md5sig",
   "ru": "Disorder посередине SNI, md5sig"
  },
  "description": {
   "en": "Splits the ClientHello mid-SNI and sends the second part first (nfqws disorder2). A reassembly-based DPI has to hold and reorder segments before it can read the SNI; md5sig fooling degrades the out-of-order segment so the censor's stack drops it while the server reassembles the real stream.",
   "ru": "Режет ClientHello посередине SNI и отправляет вторую часть первой (nfqws disorder2). DPI с реассемблингом вынужден держать и переупорядочивать сегменты, прежде чем прочитать SNI; fooling md5sig портит внеочередной сегмент так, что стек цензора его отбрасывает, а сервер собирает настоящий поток."
  },
  "targets": {
   "en": "SNI block, including censors that reassemble TCP streams.",
   "ru": "Блокировка по SNI, включая цензоров с реассемблингом TCP-потока."
  },
  "cost": {
   "en": "Needs nfqws. Disorder breaks some strict servers and middleboxes: if a site stops opening with this preset, fall back to the plain mid-SNI split.",
   "ru": "Нужен nfqws. Disorder ломает некоторые строгие серверы и мидлбоксы: если сайт перестал открываться, откатитесь на обычный сплит посередине SNI."
  },
  "backends": [
   "nfqws"
  ],
  "strategy": {
   "split_pos": [
    "midsni"
   ],
   "desync": [
    "disorder2"
   ],
   "fooling": "md5sig",
   "filter_tcp": "80,443",
   "filter_l7": "tls"
  },
  "source": "core/tune/desync/registry.go sni_block/disorder-midsni via Params.BypassStrategy() (MethodDisorder + fooling forces nfqws disorder2)"
 },
 {
  "id": "sni_block/tlsrec",
  "name": {
   "en": "TLS record split at SNI extension",
   "ru": "Сплит TLS-записи на расширении SNI"
  },
  "description": {
   "en": "Re-splits the ClientHello into two TLS records at sniext+1 — right after the SNI extension starts. Many censors parse only the first record, so the SNI is never seen whole. The cheapest trick in the set: plain tpws, no packet injection.",
   "ru": "Перерезает ClientHello на две TLS-записи в точке sniext+1 — сразу после начала расширения SNI. Многие цензоры парсят только первую запись и не видят SNI целиком. Самый дешёвый приём набора: обычный tpws, без инжекции пакетов."
  },
  "targets": {
   "en": "SNI block; first thing to try where nfqws is unavailable.",
   "ru": "Блокировка по SNI; первый кандидат там, где nfqws недоступен."
  },
  "cost": {
   "en": "A censor that reassembles TLS records across the stream defeats it. No effect on plain HTTP or QUIC.",
   "ru": "Цензор, собирающий TLS-записи через весь поток, его обходит. Не действует на обычный HTTP и QUIC."
  },
  "backends": [
   "tpws"
  ],
  "strategy": {
   "tls_record": "sniext+1"
  },
  "source": "core/tune/desync/registry.go sni_block/tlsrec via Params.BypassStrategy() (MethodTLSRec clears split_pos into tls_record)"
 },
 {
  "id": "stall/fake-repeats",
  "name": {
   "en": "Repeated fake, TTL 5",
   "ru": "Повторный фейк, TTL 5"
  },
  "description": {
   "en": "Injects the fake TLS ClientHello twice (repeats 2) with a fixed TTL of 5 hops. For censors that sample packets and stall the handshake while classifying: the repeated fake keeps the classifier busy on packets that never reach the server.",
   "ru": "Вставляет фейковый TLS ClientHello дважды (repeats 2) с фиксированным TTL в 5 хопов. Для цензоров, которые сэмплируют пакеты и замораживают handshake на время классификации: повторный фейк занимает классификатор пакетами, которые никогда не дойдут до сервера."
  },
  "targets": {
   "en": "Stall: the handshake (or the session right after it) freezes.",
   "ru": "Зависание (stall): handshake или сессия сразу после него замерзает."
  },
  "cost": {
   "en": "Fixed TTL is a guess about your path: too small and the fake dies before the censor (no effect), too large and it can reach the server. Honest limit from the registry: a stall that is pure post-handshake throttling is a data-plane freeze — desync only helps when the freeze is keyed on the handshake.",
   "ru": "Фиксированный TTL — догадка о вашем пути: слишком мал — фейк умрёт до цензора (нет эффекта), слишком велик — может дойти до сервера. Честный предел из реестра: зависание как чистая пост-handshake троттлинг — это фриз плоскости данных; desync помогает, только если фриз завязан на handshake."
  },
  "backends": [
   "nfqws"
  ],
  "strategy": {
   "split_pos": [
    "2"
   ],
   "desync": [
    "fake"
   ],
   "fake_tls": "tls",
   "ttl": 5,
   "repeats": 2,
   "filter_tcp": "80,443",
   "filter_l7": "tls"
  },
  "source": "core/tune/desync/registry.go stall/fake-repeats via Params.BypassStrategy() (MethodFake, TTL 5, Repeats 2)"
 },
 {
  "id": "stall/fake-sniext-autottl",
  "name": {
   "en": "Fake at SNI extension, autottl",
   "ru": "Фейк на расширении SNI, autottl"
  },
  "description": {
   "en": "Injects a fake ClientHello at the SNI extension boundary (sniext+1) with autottl instead of a fixed TTL: changes the stall-triggering byte layout without betting on a hop count.",
   "ru": "Вставляет фейковый ClientHello на границе расширения SNI (sniext+1) с autottl вместо фиксированного TTL: меняет байтовую раскладку, провоцирующую зависание, без ставки на число хопов."
  },
  "targets": {
   "en": "Stall keyed on the handshake layout.",
   "ru": "Зависание, завязанное на раскладку handshake."
  },
  "cost": {
   "en": "Needs nfqws and a calibratable path for autottl. Like every stall preset, it cannot fix throttling that starts after the handshake.",
   "ru": "Нужен nfqws и калибруемый путь для autottl. Как и все пресеты от зависаний, не чинит троттлинг, начинающийся после handshake."
  },
  "backends": [
   "nfqws"
  ],
  "strategy": {
   "split_pos": [
    "sniext+1"
   ],
   "desync": [
    "fake"
   ],
   "fake_tls": "tls",
   "auto_ttl": true,
   "filter_tcp": "80,443",
   "filter_l7": "tls"
  },
  "source": "core/tune/desync/registry.go stall/fake-sniext-autottl via Params.BypassStrategy() (MethodFake, AutoTTL)"
 },
 {
  "id": "quic_throttle/fake-quic-ttl",
  "name": {
   "en": "Fake QUIC Initial, TTL 3",
   "ru": "Фейковый QUIC Initial, TTL 3"
  },
  "description": {
   "en": "Injects a fake QUIC Initial (the shipped payload file) with a TTL of 3 before the real Initial. The censor classifies the fake; the real Initial follows untouched. QUIC has no built-in fake in zapret, so the payload is the file the core ships (the 'quic' keyword resolves to it).",
   "ru": "Вставляет фейковый QUIC Initial (поставляемый файл полезной нагрузки) с TTL 3 перед настоящим Initial. Цензор классифицирует фейк; настоящий Initial идёт следом нетронутым. Встроенного фейка для QUIC в zapret нет, поэтому нагрузка — файл, который поставляет ядро (ключевое слово «quic» разрешается в него)."
  },
  "targets": {
   "en": "QUIC throttle: UDP/443 is dropped or squeezed.",
   "ru": "Троттлинг QUIC: UDP/443 режется или ужимается."
  },
  "cost": {
   "en": "Fixed TTL 3 is a short-path guess: on longer paths to the censor the fake may die too early. Needs nfqws with UDP filtering on port 443.",
   "ru": "Фиксированный TTL 3 — ставка на короткий путь: если цензор дальше, фейк может умереть слишком рано. Нужен nfqws с фильтрацией UDP на порту 443."
  },
  "backends": [
   "nfqws"
  ],
  "strategy": {
   "desync": [
    "fake"
   ],
   "fake_quic": "quic",
   "ttl": 3,
   "filter_udp": "443",
   "filter_l7": "quic"
  },
  "source": "core/tune/desync/registry.go quic_throttle/fake-quic-ttl via Params.BypassStrategy() (MethodFake, FakeProto quic -> fake_quic + UDP filter)"
 },
 {
  "id": "quic_throttle/fake-quic-split-autottl",
  "name": {
   "en": "Fake QUIC Initial + split, autottl",
   "ru": "Фейковый QUIC Initial + сплит, autottl"
  },
  "description": {
   "en": "Combines a fake QUIC Initial with a split of the real Initial at byte 2, with autottl calibration instead of a fixed TTL. For throttles keyed on the Initial's embedded SNI: the censor sees a fake, then a fragmented real handshake.",
   "ru": "Сочетает фейковый QUIC Initial со сплитом настоящего Initial на байте 2, с калибровкой autottl вместо фиксированного TTL. Для троттлинга по SNI внутри Initial: цензор видит фейк, а затем фрагментированный настоящий handshake."
  },
  "targets": {
   "en": "QUIC throttle keyed on the Initial's SNI.",
   "ru": "Троттлинг QUIC по SNI внутри Initial."
  },
  "cost": {
   "en": "Needs nfqws and autottl calibration. Splitting the Initial can break strict QUIC stacks; if QUIC fails entirely, the browser/app falls back to TCP — check whether that fallback is what you actually measured.",
   "ru": "Нужен nfqws и калибровка autottl. Сплит Initial может ломать строгие QUIC-стеки; если QUIC упадёт полностью, браузер/приложение откатится на TCP — проверяйте, что вы измерили именно это."
  },
  "backends": [
   "nfqws"
  ],
  "strategy": {
   "split_pos": [
    "2"
   ],
   "desync": [
    "fake"
   ],
   "fake_quic": "quic",
   "auto_ttl": true,
   "filter_udp": "443",
   "filter_l7": "quic"
  },
  "source": "core/tune/desync/registry.go quic_throttle/fake-quic-split-autottl via Params.BypassStrategy() (MethodFake, AutoTTL, Scope QUIC)"
 },
 {
  "id": "quic_throttle/split-quic",
  "name": {
   "en": "Split QUIC Initial, badseq",
   "ru": "Сплит QUIC Initial, badseq"
  },
  "description": {
   "en": "The lightest QUIC desync: nfqws split2 of the QUIC Initial at byte 1 with badseq fooling, and no fake payload at all. The censor's reassembly gives up on the out-of-window segment; the server reassembles the real Initial.",
   "ru": "Самый лёгкий desync для QUIC: nfqws split2 QUIC Initial на байте 1 с fooling badseq и вообще без фейковой нагрузки. Реассемблинг цензора сдаётся на внеоконном сегменте; сервер собирает настоящий Initial."
  },
  "targets": {
   "en": "QUIC throttle, minimal-footprint variant.",
   "ru": "Троттлинг QUIC, вариант с минимальным следом."
  },
  "cost": {
   "en": "Needs nfqws. No fake means nothing misleads a classifier that reads only the first fragment — if this fails, move to a fake-QUIC preset.",
   "ru": "Нужен nfqws. Без фейка нечем обмануть классификатор, читающий только первый фрагмент, — если не сработало, переходите к пресетам с фейковым QUIC."
  },
  "backends": [
   "nfqws"
  ],
  "strategy": {
   "split_pos": [
    "1"
   ],
   "desync": [
    "split2"
   ],
   "fooling": "badseq",
   "filter_udp": "443",
   "filter_l7": "quic"
  },
  "source": "core/tune/desync/registry.go quic_throttle/split-quic via Params.BypassStrategy() (MethodSplit + fooling forces nfqws split2, Scope QUIC filters)"
 },
 {
  "id": "kz_variant/fake-md5sig-autottl",
  "name": {
   "en": "Fake with md5sig, autottl (KZ)",
   "ru": "Фейк с md5sig, autottl (KZ)"
  },
  "description": {
   "en": "Fake ClientHello with md5sig fooling and autottl, tuned for the Kazakh variant: a whitelist posture with MITM interception on non-whitelisted SNI, where SNI-keyed kills still occur at the border.",
   "ru": "Фейковый ClientHello с fooling md5sig и autottl, настроенный на казахстанский вариант: whitelist-позиция с MITM-перехватом на не-whitelist SNI, где убийства по SNI на границе всё ещё встречаются."
  },
  "targets": {
   "en": "KZ variant: border SNI kills under a whitelist/MITM posture.",
   "ru": "Казахстанский вариант: убийства по SNI на границе при whitelist/MITM-позиции."
  },
  "cost": {
   "en": "Honest limit from the registry: against a whitelist/MITM posture desync helps only the SNI-kill stage; a hard whitelist needs a whitelisted front, not a strategy. Needs nfqws.",
   "ru": "Честный предел из реестра: против whitelist/MITM-позиции desync помогает только на стадии убийства по SNI; жёсткому whitelist нужен whitelist-фронт, а не стратегия. Нужен nfqws."
  },
  "backends": [
   "nfqws"
  ],
  "strategy": {
   "split_pos": [
    "1"
   ],
   "desync": [
    "fake"
   ],
   "fake_tls": "tls",
   "fooling": "md5sig",
   "auto_ttl": true,
   "filter_tcp": "80,443",
   "filter_l7": "tls"
  },
  "source": "core/tune/desync/registry.go kz_variant/fake-md5sig-autottl via Params.BypassStrategy() (MethodFake, Fooling md5sig, AutoTTL)"
 },
 {
  "id": "kz_variant/split-midsni",
  "name": {
   "en": "Mid-SNI split (KZ)",
   "ru": "Сплит посередине SNI (KZ)"
  },
  "description": {
   "en": "The marker-resolved mid-SNI split as the minimal-footprint strategy for the KZ border SNI check: one cut inside the hostname, nothing else on the wire.",
   "ru": "Сплит посередине SNI с разрешением маркера — стратегия с минимальным следом для пограничной проверки SNI в KZ: один разрез внутри имени хоста и ничего лишнего на проводе."
  },
  "targets": {
   "en": "KZ variant: the border SNI check stage.",
   "ru": "Казахстанский вариант: стадия пограничной проверки SNI."
  },
  "cost": {
   "en": "Same honest limit as every KZ preset: it answers only the SNI-kill stage, not a hard whitelist. Defeated by full stream reassembly.",
   "ru": "Тот же честный предел, что у всех KZ-пресетов: отвечает только на стадию убийства по SNI, а не на жёсткий whitelist. Обходится полным реассемблингом потока."
  },
  "backends": [
   "tpws"
  ],
  "strategy": {
   "split_pos": [
    "midsni"
   ]
  },
  "source": "core/tune/desync/registry.go kz_variant/split-midsni via Params.BypassStrategy() (MethodSplit, marker position, tpws rendering)"
 },
 {
  "id": "classic/app-default-split",
  "name": {
   "en": "App default: split 1 + midsld, disorder",
   "ru": "Дефолт приложения: сплит 1 + midsld, disorder"
  },
  "description": {
   "en": "The application's own default bypass: split the handshake after the first byte and in the middle of the second-level domain (midsld), then send the second part first (disorder). This is the strategy Sora falls back to in its own settings, so it is the baseline everything else is compared against.",
   "ru": "Собственный дефолт приложения: сплит handshake после первого байта и посередине домена второго уровня (midsld), затем вторая часть отправляется первой (disorder). Это стратегия, на которую Sora откатывается в своих настройках, — базовая линия для сравнения."
  },
  "targets": {
   "en": "General first try: SNI block and keyword DPI on TCP (HTTP/TLS).",
   "ru": "Общий первый кандидат: блокировка по SNI и ключевым словам на TCP (HTTP/TLS)."
  },
  "cost": {
   "en": "Disorder breaks some strict servers and middleboxes. tpws is TCP-only: no QUIC/UDP effect.",
   "ru": "Disorder ломает некоторые строгие серверы и мидлбоксы. tpws работает только с TCP: на QUIC/UDP не действует."
  },
  "backends": [
   "tpws"
  ],
  "strategy": {
   "split_pos": [
    "1",
    "midsld"
   ],
   "disorder": true
  },
  "source": "App settings default (app/lib/src/settings.dart splitPos ['1','midsld']; settings_screen disorder default), as prescribed for this package"
 },
 {
  "id": "classic/tls-record-split",
  "name": {
   "en": "Classic TLS record split",
   "ru": "Классический сплит TLS-записи"
  },
  "description": {
   "en": "The classic tpws trick as a standalone preset: re-split the ClientHello into two TLS records at sniext+1 so a censor parsing only the first record never sees the whole SNI. Same strategy the registry seeds for the sni_block class, kept here as the named classic for direct use.",
   "ru": "Классический приём tpws отдельным пресетом: перерезать ClientHello на две TLS-записи в точке sniext+1, чтобы цензор, парсящий только первую запись, не увидел SNI целиком. Та же стратегия, что реестр сеет для класса sni_block, здесь — как именованная классика для прямого применения."
  },
  "targets": {
   "en": "SNI block, where nfqws is unavailable.",
   "ru": "Блокировка по SNI там, где nfqws недоступен."
  },
  "cost": {
   "en": "Defeated by censors that reassemble TLS records. No effect on plain HTTP or QUIC.",
   "ru": "Обходится цензорами с реассемблингом TLS-записей. Не действует на обычный HTTP и QUIC."
  },
  "backends": [
   "tpws"
  ],
  "strategy": {
   "tls_record": "sniext+1"
  },
  "source": "Classic tpws --tlsrec=sniext+1 (compare registry sni_block/tlsrec)"
 },
 {
  "id": "classic/http-reform",
  "name": {
   "en": "HTTP request reform",
   "ru": "Реформа HTTP-запроса"
  },
  "description": {
   "en": "Reshapes plain-HTTP requests so keyword DPI cannot match them literally: mixed case in the Host header (host_case) and in the domain (domain_case), an extra EOL after the method (method_eol), a trailing dot after the host name (host_dot) and an extra space after the method (method_space). Host-tab and host-no-space are deliberately left out: they fight method_space over the same separators, and unix_eol is left out because method_eol already varies the line the censor keys on.",
   "ru": "Перекраивает обычные HTTP-запросы, чтобы DPI по ключевым словам не мог сопоставить их буквально: смешанный регистр в заголовке Host (host_case) и в домене (domain_case), лишний EOL после метода (method_eol), точка после имени хоста (host_dot) и лишний пробел после метода (method_space). Host-tab и host-no-space сознательно не включены: они спорят с method_space за те же разделители; unix_eol не включён, потому что method_eol уже меняет строку, на которую смотрит цензор."
  },
  "targets": {
   "en": "Plain-HTTP keyword/host blocking (port 80).",
   "ru": "Блокировка обычного HTTP по ключевым словам/хосту (порт 80)."
  },
  "cost": {
   "en": "Only plain HTTP is reshaped — HTTPS is untouched. A few strict origin servers reject malformed-looking request lines; if a specific HTTP site breaks, drop method_space first.",
   "ru": "Перекраивается только обычный HTTP — HTTPS не трогается. Некоторые строгие origin-серверы отвергают «кривые» строки запроса; если конкретный HTTP-сайт сломался, сначала уберите method_space."
  },
  "backends": [
   "tpws"
  ],
  "strategy": {
   "host_case": true,
   "domain_case": true,
   "method_eol": true,
   "host_dot": true,
   "method_space": true
  },
  "source": "Classic tpws HTTP shaping family (--hostcase/--domcase/--methodeol/--hostdot/--methodspace in core/engine/bypass Args)"
 },
 {
  "id": "classic/multisplit-sni",
  "name": {
   "en": "Multisplit at SNI, any protocol",
   "ru": "Мультисплит на SNI, любой протокол"
  },
  "description": {
   "en": "Splits at the SNI marker (midsld — the middle of the second-level domain, where the registrable name sits) and lifts the usual HTTP/TLS-only limit: split_any_protocol applies the cut to the first flight of other protocols too. The marker is used instead of a byte count because SNI offsets move with every hostname, while midsld always lands inside the name the censor matches.",
   "ru": "Режет на маркере SNI (midsld — середина домена второго уровня, где сидит регистрируемое имя) и снимает обычное ограничение «только HTTP/TLS»: split_any_protocol применяет разрез и к первому полёту других протоколов. Маркер вместо числа байтов — потому что смещения SNI плавают с каждым именем хоста, а midsld всегда попадает внутрь имени, которое сопоставляет цензор."
  },
  "targets": {
   "en": "SNI block on mixed traffic, including protocols beyond HTTP/TLS.",
   "ru": "Блокировка по SNI на смешанном трафике, включая протоколы за пределами HTTP/TLS."
  },
  "cost": {
   "en": "split_any_protocol can break protocols whose first flight is not a handshake the server tolerates fragmented. If something non-web breaks, scope back to the plain mid-SNI split.",
   "ru": "split_any_protocol может ломать протоколы, чей первый полёт сервер не терпит фрагментированным. Если сломалось что-то не-вебное, откатитесь на обычный сплит посередине SNI."
  },
  "backends": [
   "tpws"
  ],
  "strategy": {
   "split_pos": [
    "midsld"
   ],
   "split_any_protocol": true
  },
  "source": "Classic tpws multisplit (--split-pos=midsld --split-any-protocol in core/engine/bypass Args)"
 }
];

/* Field metadata: key, editor control type, group. Labels and hints are
 * localized in STRINGS[lang].fields. Order mirrors BypassStrategy in
 * proto/sora/core/v1/core_control.proto. */
var FIELD_DEFS = [
  { key: 'split_pos', type: 'list', group: 'split' },
  { key: 'disorder', type: 'bool', group: 'split' },
  { key: 'disorder_scope', type: 'enum', group: 'split' },
  { key: 'oob', type: 'bool', group: 'split' },
  { key: 'oob_scope', type: 'enum', group: 'split' },
  { key: 'oob_data', type: 'string', group: 'split' },
  { key: 'split_any_protocol', type: 'bool', group: 'split' },
  { key: 'tamper_start', type: 'string', group: 'split' },
  { key: 'tamper_cutoff', type: 'string', group: 'split' },
  { key: 'mss', type: 'string', group: 'split' },
  { key: 'tls_record', type: 'string', group: 'tls' },
  { key: 'host_case', type: 'bool', group: 'http' },
  { key: 'domain_case', type: 'bool', group: 'http' },
  { key: 'method_eol', type: 'bool', group: 'http' },
  { key: 'host_dot', type: 'bool', group: 'http' },
  { key: 'host_tab', type: 'bool', group: 'http' },
  { key: 'host_no_space', type: 'bool', group: 'http' },
  { key: 'method_space', type: 'bool', group: 'http' },
  { key: 'unix_eol', type: 'bool', group: 'http' },
  { key: 'desync', type: 'list', group: 'desync' },
  { key: 'fake_tls', type: 'string', group: 'desync' },
  { key: 'fake_quic', type: 'string', group: 'desync' },
  { key: 'fooling', type: 'string', group: 'desync' },
  { key: 'ttl', type: 'int', group: 'desync', min: 0, max: 255 },
  { key: 'auto_ttl', type: 'bool', group: 'desync' },
  { key: 'repeats', type: 'int', group: 'desync', min: 0, max: 16 },
  { key: 'filter_tcp', type: 'string', group: 'filters' },
  { key: 'filter_udp', type: 'string', group: 'filters' },
  { key: 'filter_l7', type: 'string', group: 'filters' }
];
var GROUPS = ['split', 'tls', 'http', 'desync', 'filters'];
/* Mirrors validDesyncModes / validFooling / validFilterL7 in
 * core/engine/validate.go (validateDesync). */
var DESYNC_MODES = ['fake', 'fakeknown', 'rst', 'rstack', 'synack', 'syndata',
  'fakeddisorder', 'disorder', 'fakedsplit', 'split', 'multisplit', 'split2',
  'multidisorder', 'disorder2', 'hostfakesplit', 'ipfrag2', 'hopbyhop',
  'destopt', 'ipfrag1', 'udplen', 'tamper'];
var FOOLING_MODES = ['md5sig', 'ts', 'badsum', 'badseq', 'datanoack',
  'hopbyhop', 'hopbyhop2', 'none'];
var FILTER_L7 = ['http', 'tls', 'quic', 'wireguard', 'dht', 'discord',
  'stun', 'unknown'];
var POS_RE = /^(-?[0-9]{1,4}|(method|host|endhost|sld|midsld|endsld|sniext)([+-][0-9]{1,4})?)$/;
var TAMPER_RE = /^n?(-?[0-9]{1,4}|(method|host|endhost|sld|midsld|endsld|sniext)([+-][0-9]{1,4})?)$/;
var PORTS_RE = /^([0-9]{1,5}(-[0-9]{1,5})?)(,([0-9]{1,5}(-[0-9]{1,5})?))*$/;
var FAKENAME_RE = /^([A-Za-z0-9_.-]+|tls|quic)$/;
/* tpws-only fields: core validation rejects each of them when a desync
 * method is present (the strategy then runs on nfqws). */
var TPWS_ONLY = ['disorder', 'disorder_scope', 'oob', 'oob_scope', 'oob_data',
  'tls_record', 'host_case', 'domain_case', 'method_eol', 'host_dot',
  'host_tab', 'host_no_space', 'method_space', 'unix_eol',
  'split_any_protocol', 'tamper_start', 'tamper_cutoff', 'mss'];

/* ---------------- state ---------------- */
var settings = { language: 'auto', confirm_apply: true, monitor_limit: 50 };
var lang = 'en';
var caps = null;          /* getBypassCapabilities result */
var coreState = null;     /* getBypassState result */
var coreLayer = null;     /* last layer read from / accepted by the core */
var draft = { global: null, bindings: [] };
var editorBuf = emptyStrategy();
var editorSourcePreset = '';
var monitorEvents = [];
var tuneResult = null;
var activeTab = 'overview';
var bridgeOK = typeof window !== 'undefined' && !!window.soraExt;

/* ---------------- i18n ---------------- */
function resolveLang() {
  if (settings.language === 'ru' || settings.language === 'en') return settings.language;
  var nl = (navigator.language || 'en').toLowerCase();
  return nl.indexOf('ru') === 0 ? 'ru' : 'en';
}
function t(key) {
  var table = STRINGS[lang] || STRINGS.en;
  return table[key] || STRINGS.en[key] || key;
}
function fieldText(key, part) {
  var table = STRINGS[lang] || STRINGS.en;
  var f = (table.fields && table.fields[key]) || (STRINGS.en.fields && STRINGS.en.fields[key]) || {};
  return f[part] || key;
}
function loc(obj) {
  if (!obj) return '';
  return obj[lang] || obj.en || '';
}

/* ---------------- DOM helpers (textContent only) ---------------- */
function el(tag, cls, text) {
  var n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text !== undefined && text !== null) n.textContent = text;
  return n;
}
function clear(node) { while (node.firstChild) node.removeChild(node.firstChild); }
function badge(text, kind) { return el('span', 'badge' + (kind ? ' badge-' + kind : ''), text); }

/* ---------------- strategy utils ---------------- */
function emptyStrategy() {
  return {
    split_pos: [], disorder: false, oob: false, tls_record: '',
    host_case: false, domain_case: false, method_eol: false,
    disorder_scope: '', oob_scope: '', host_dot: false, host_tab: false,
    host_no_space: false, method_space: false, unix_eol: false,
    split_any_protocol: false, tamper_start: '', tamper_cutoff: '',
    oob_data: '', mss: '', desync: [], fake_tls: '', fake_quic: '',
    fooling: '', ttl: 0, auto_ttl: false, repeats: 0,
    filter_tcp: '', filter_udp: '', filter_l7: ''
  };
}
function normalizeStrategy(s) {
  var out = emptyStrategy();
  if (!s || typeof s !== 'object') return out;
  FIELD_DEFS.forEach(function (fd) {
    var v = s[fd.key];
    if (v === undefined || v === null) return;
    if (fd.type === 'list') { if (Array.isArray(v)) out[fd.key] = v.map(String); }
    else if (fd.type === 'bool') out[fd.key] = !!v;
    else if (fd.type === 'int') out[fd.key] = Math.trunc(Number(v) || 0);
    else out[fd.key] = String(v);
  });
  return out;
}
/* Sparse wire form: only non-default fields, like presets.json. */
function toWire(full) {
  var out = {};
  FIELD_DEFS.forEach(function (fd) {
    var v = full[fd.key];
    if (fd.type === 'list') { if (v && v.length) out[fd.key] = v.slice(); }
    else if (fd.type === 'bool') { if (v) out[fd.key] = true; }
    else if (fd.type === 'int') { if (v) out[fd.key] = v; }
    else if (v !== '') out[fd.key] = v;
  });
  return out;
}
function isEmptyWire(w) { return !w || Object.keys(w).length === 0; }
function clone(o) { return JSON.parse(JSON.stringify(o)); }
function sameJSON(a, b) { return JSON.stringify(a) === JSON.stringify(b); }
function findPreset(id) {
  for (var i = 0; i < PRESETS.length; i++) if (PRESETS[i].id === id) return PRESETS[i];
  return null;
}
function presetForStrategy(wire) {
  if (isEmptyWire(wire)) return null;
  for (var i = 0; i < PRESETS.length; i++) {
    if (sameJSON(PRESETS[i].strategy, wire)) return PRESETS[i];
  }
  return null;
}
function strategySummary(wire) {
  if (isEmptyWire(wire)) return t('no_global');
  var p = presetForStrategy(wire);
  if (p) return loc(p.name);
  var parts = Object.keys(wire).map(function (k) {
    var v = wire[k];
    return k + '=' + (Array.isArray(v) ? v.join(',') : String(v));
  });
  return t('custom_strategy') + ': ' + parts.join(' · ');
}

/* ---------------- client validation: mirrors core/engine/validate.go
 * (BypassStrategy.validate + validateDesync). Returns localized error
 * strings; an empty list means the core would accept the strategy
 * (an all-default strategy is the documented "changes nothing" case
 * and is reported separately by the caller). ---------------- */
function validateStrategy(full) {
  var errs = [];
  var w = toWire(full);
  var hasDesync = full.desync.length > 0;
  var hasFake = full.desync.indexOf('fake') >= 0;
  function fname(k) { return fieldText(k, 'label'); }
  if (isEmptyWire(w)) { errs.push(t('v_changes_nothing')); return errs; }
  if (full.split_pos.length > 8) errs.push(t('v_splitpos_max'));
  full.split_pos.forEach(function (pos) {
    if (pos !== 'midsni' && !POS_RE.test(pos)) {
      errs.push(t('field_prefix') + ' split_pos: ' + t('value_prefix') + ' "' + pos + '" ' + t('v_splitpos_pattern'));
    }
  });
  if (full.tls_record !== '' && full.tls_record !== 'midsni' && !POS_RE.test(full.tls_record)) {
    errs.push(t('field_prefix') + ' tls_record: "' + full.tls_record + '" ' + t('v_pos_pattern'));
  }
  ['tamper_start', 'tamper_cutoff'].forEach(function (k) {
    if (full[k] !== '' && !TAMPER_RE.test(full[k])) {
      errs.push(t('field_prefix') + ' ' + k + ': "' + full[k] + '" ' + t('v_tamper_pattern'));
    }
  });
  if (full.oob_data !== '' && !(full.oob_data.length === 1 ||
      /^0[xX][0-9a-fA-F]{2}$/.test(full.oob_data))) {
    errs.push(t('v_oob_data_pattern'));
  }
  if (full.oob_data !== '' && !full.oob) errs.push(t('v_oob_data_req'));
  if (full.mss !== '') {
    var mss = Number(full.mss);
    if (!/^[0-9]+$/.test(full.mss) || mss < 64 || mss > 65495) errs.push(t('v_mss_range'));
  }
  ['disorder_scope', 'oob_scope'].forEach(function (k) {
    if (full[k] !== '' && full[k] !== 'http' && full[k] !== 'tls') {
      errs.push(t('field_prefix') + ' ' + k + ' ' + t('v_scope_val'));
    }
  });
  if (full.disorder_scope !== '' && !full.disorder) errs.push(t('v_disorder_scope_req'));
  if (full.oob_scope !== '' && !full.oob) errs.push(t('v_oob_scope_req'));
  if ((full.disorder || full.oob) && full.split_pos.length === 0) errs.push(t('v_need_split'));
  if (full.desync.length > 8) errs.push(t('v_desync_max'));
  full.desync.forEach(function (m) {
    if (DESYNC_MODES.indexOf(m) < 0) {
      errs.push(t('field_prefix') + ' desync: "' + m + '" ' + t('v_desync_mode'));
    }
  });
  if (hasDesync) {
    TPWS_ONLY.forEach(function (k) {
      var v = full[k];
      var set = (typeof v === 'boolean') ? v : (v !== '' && v !== 0);
      if (set) errs.push(fname(k) + ' ' + t('v_mix_tpws'));
    });
  }
  if (full.fooling !== '') {
    if (!hasDesync) errs.push(t('v_fooling_req'));
    full.fooling.split(',').forEach(function (f) {
      if (FOOLING_MODES.indexOf(f) < 0) {
        errs.push(t('field_prefix') + ' fooling: "' + f + '" ' + t('v_fooling_mode'));
      }
    });
  }
  if (full.fake_tls !== '' || full.fake_quic !== '') {
    if (!hasFake) errs.push(t('v_fake_req'));
    ['fake_tls', 'fake_quic'].forEach(function (k) {
      if (full[k] !== '' && !FAKENAME_RE.test(full[k])) {
        errs.push(t('field_prefix') + ' ' + k + ' ' + t('v_fake_name'));
      }
    });
  }
  if (full.fake_quic !== '' && full.filter_udp === '') errs.push(t('v_fakequic_udp'));
  if (full.ttl < 0 || full.ttl > 255) errs.push(t('v_ttl_range'));
  if (full.ttl > 0 && !hasFake) errs.push(t('v_ttl_fake'));
  if (full.ttl > 0 && full.auto_ttl) errs.push(t('v_ttl_xor'));
  if (full.auto_ttl && !hasFake) errs.push(t('v_autottl_fake'));
  if (full.repeats !== 0) {
    if (!hasFake) errs.push(t('v_repeats_fake'));
    if (full.repeats < 1 || full.repeats > 16) errs.push(t('v_repeats_range'));
  }
  ['filter_tcp', 'filter_udp'].forEach(function (k) {
    if (full[k] === '') return;
    if (!hasDesync) { errs.push(t('v_filter_req')); return; }
    if (!PORTS_RE.test(full[k])) {
      errs.push(t('field_prefix') + ' ' + k + ': "' + full[k] + '" ' + t('v_filter_ports'));
      return;
    }
    full[k].split(',').forEach(function (part) {
      part.split('-').forEach(function (p) {
        var n = Number(p);
        if (n < 1 || n > 65535) errs.push(t('v_filter_port_range') + ' ' + k);
      });
    });
  });
  if (full.filter_l7 !== '') {
    if (!hasDesync) errs.push(t('v_filter_req'));
    full.filter_l7.split(',').forEach(function (l) {
      if (FILTER_L7.indexOf(l) < 0) {
        errs.push(t('field_prefix') + ' filter_l7: "' + l + '" ' + t('v_filter_l7_val'));
      }
    });
  }
  return errs;
}

/* ---------------- bridge ---------------- */
function api(method, args) {
  if (!bridgeOK) {
    var e = new Error(t('bridge_missing'));
    e.code = 'internal';
    return Promise.reject(e);
  }
  return window.soraExt.call(method, args);
}
function errorText(e) {
  var code = e && e.code;
  if (code === 'permission-denied') return t('error_permission');
  if (code === 'invalid-argument') return t('error_invalid') + (e && e.message ? ' — ' + e.message : '');
  if (code === 'internal') return t('error_internal') + (e && e.message ? ' — ' + e.message : '');
  return t('error_generic') + (e && e.message ? ' — ' + e.message : '');
}
var bannerNode = null;
function showBanner(text, isError) {
  if (!bannerNode) return;
  clear(bannerNode);
  if (!text) { bannerNode.style.display = 'none'; return; }
  bannerNode.style.display = '';
  bannerNode.className = isError ? 'banner banner-err' : 'banner banner-ok';
  bannerNode.textContent = text;
}

/* ---------------- layer state ---------------- */
function draftDirty() {
  if (!coreLayer) return !isEmptyWire(draft.global || {}) || draft.bindings.length > 0;
  return !sameJSON(draft.global || null, coreLayer.global || null) ||
    !sameJSON(draft.bindings, coreLayer.bindings || []);
}
function syncDraftFromCore() {
  if (!coreLayer) { draft = { global: null, bindings: [] }; return; }
  draft = {
    global: coreLayer.global ? clone(coreLayer.global) : null,
    bindings: (coreLayer.bindings || []).map(function (b) {
      return { match: String(b.match || ''), strategy: clone(b.strategy || {}), preset_id: '' };
    })
  };
}
async function refreshCore() {
  try { caps = await api('getBypassCapabilities', {}); } catch (e) { caps = null; showBanner(errorText(e), true); }
  try { coreState = await api('getBypassState', {}); } catch (e) { coreState = null; }
  try {
    var layer = await api('getBypassLayer', {});
    coreLayer = {
      global: layer && layer.global ? layer.global : null,
      bindings: (layer && layer.bindings) || [],
      updated_at: (layer && layer.updated_at) || ''
    };
    syncDraftFromCore();
    editorBuf = normalizeStrategy(draft.global || {});
    editorSourcePreset = '';
    var p = presetForStrategy(draft.global || {});
    if (p) editorSourcePreset = p.id;
  } catch (e) { coreLayer = null; }
  renderAll();
}
function backendAvailable(kind) {
  if (!caps || !caps.backends) return null; /* unknown */
  for (var i = 0; i < caps.backends.length; i++) {
    if (caps.backends[i].kind === kind) return !!caps.backends[i].available;
  }
  return null;
}

/* Apply the whole draft layer (global + bindings) in one call. */
var confirmResolver = null;
function askConfirm() {
  return new Promise(function (resolve) {
    if (!settings.confirm_apply) { resolve(true); return; }
    confirmResolver = resolve;
    var modal = document.getElementById('confirm-modal');
    modal.style.display = '';
  });
}
async function applyLayer() {
  var problems = [];
  if (draft.global) problems = problems.concat(validateStrategy(normalizeStrategy(draft.global)));
  draft.bindings.forEach(function (b, i) {
    validateStrategy(normalizeStrategy(b.strategy)).forEach(function (msg) {
      problems.push(t('binding_match') + ' #' + (i + 1) + ' (' + b.match + '): ' + msg);
    });
    if (!b.match) problems.push(t('binding_match') + ' #' + (i + 1) + ': ∅');
  });
  if (problems.length) { showBanner(problems.join('\n'), true); return false; }
  var ok = await askConfirm();
  if (!ok) return false;
  try {
    var res = await api('applyBypassLayer', {
      global: draft.global || null,
      bindings: draft.bindings.map(function (b) { return { match: b.match, strategy: b.strategy }; })
    });
    coreLayer = {
      global: draft.global ? clone(draft.global) : null,
      bindings: clone(draft.bindings),
      updated_at: (res && res.updated_at) || ''
    };
    showBanner(t('applied_ok'), false);
    try { await api('notify', { title: t('app_title'), body: t('applied_ok') }); } catch (e) { /* best effort */ }
    try { coreState = await api('getBypassState', {}); } catch (e) { /* keep old */ }
    renderAll();
    return true;
  } catch (e) {
    showBanner(errorText(e), true);
    return false;
  }
}

/* ---------------- rendering ---------------- */
var root = null;
function renderAll() {
  if (!root) return;
  clear(root);
  root.appendChild(renderHeader());
  bannerNode = el('div', 'banner');
  bannerNode.style.display = 'none';
  root.appendChild(bannerNode);
  root.appendChild(renderTabs());
  var dirty = el('div', 'dirty ' + (draftDirty() ? 'dirty-on' : ''), draftDirty() ? t('dirty') : t('clean'));
  root.appendChild(dirty);
  var section = el('div', 'section');
  if (activeTab === 'overview') renderOverview(section);
  else if (activeTab === 'presets') renderPresets(section);
  else if (activeTab === 'editor') renderEditor(section);
  else if (activeTab === 'bindings') renderBindings(section);
  else if (activeTab === 'tune') renderTune(section);
  else if (activeTab === 'monitor') renderMonitor(section);
  else if (activeTab === 'profiles') renderProfiles(section);
  root.appendChild(section);
}
function renderHeader() {
  var h = el('div', 'header');
  var left = el('div');
  left.appendChild(el('h1', '', t('app_title')));
  left.appendChild(el('p', 'sub', t('app_sub')));
  h.appendChild(left);
  var right = el('div', 'langbox');
  right.appendChild(el('label', '', t('settings_language')));
  var sel = el('select', 'input');
  [['auto', t('lang_auto')], ['en', 'English'], ['ru', 'Русский']].forEach(function (pair) {
    var o = el('option', '', pair[1]);
    o.value = pair[0];
    if (settings.language === pair[0]) o.selected = true;
    sel.appendChild(o);
  });
  sel.addEventListener('change', async function () {
    settings.language = sel.value;
    lang = resolveLang();
    try { await api('setSettings', { language: sel.value }); } catch (e) { /* local only */ }
    renderAll();
  });
  right.appendChild(sel);
  h.appendChild(right);
  return h;
}
function renderTabs() {
  var nav = el('div', 'tabs');
  [['overview', 'tab_overview'], ['presets', 'tab_presets'], ['editor', 'tab_editor'],
   ['bindings', 'tab_bindings'], ['tune', 'tab_tune'], ['monitor', 'tab_monitor'],
   ['profiles', 'tab_profiles']].forEach(function (pair) {
    var b = el('button', 'tab' + (activeTab === pair[0] ? ' tab-active' : ''), t(pair[1]));
    b.addEventListener('click', function () { activeTab = pair[0]; renderAll(); });
    nav.appendChild(b);
  });
  return nav;
}
function kv(parent, key, valueNode) {
  var row = el('div', 'kv');
  row.appendChild(el('div', 'kv-k', key));
  var v = el('div', 'kv-v');
  if (typeof valueNode === 'string') v.textContent = valueNode; else v.appendChild(valueNode);
  row.appendChild(v);
  parent.appendChild(row);
}
function renderOverview(section) {
  var refreshBtn = el('button', 'btn', t('refresh'));
  refreshBtn.addEventListener('click', refreshCore);
  section.appendChild(refreshBtn);
  if (!bridgeOK) section.appendChild(el('p', 'warn', t('bridge_missing')));
  var capBox = el('div', 'card');
  capBox.appendChild(el('h2', '', t('backends')));
  if (caps) {
    kv(capBox, t('platform'), String(caps.platform || ''));
    (caps.backends || []).forEach(function (b) {
      var v = el('span');
      v.appendChild(document.createTextNode(b.kind + ' — '));
      v.appendChild(badge(b.available ? t('backend_available') : t('backend_unavailable'), b.available ? 'ok' : 'bad'));
      if (!b.available && b.reason) v.appendChild(el('span', 'reason', ' ' + String(b.reason)));
      kv(capBox, b.kind, v);
    });
  }
  section.appendChild(capBox);
  var stBox = el('div', 'card');
  stBox.appendChild(el('h2', '', t('current_state')));
  if (coreState) {
    var srcKey = String(coreState.global_source || '');
    var srcLabel = (STRINGS[lang].sources && STRINGS[lang].sources[srcKey]) || t('source_unknown');
    kv(stBox, t('global_source'), srcLabel);
    if (coreState.global_from) kv(stBox, t('global_from'), String(coreState.global_from));
    kv(stBox, t('session_active'), coreState.session_active ? t('session_on') : t('session_off'));
    kv(stBox, t('pending_apply'), coreState.pending_apply ? t('pending_yes') : t('pending_no'));
    kv(stBox, t('bindings_count'), String(coreState.bindings_count || 0));
  }
  kv(stBox, t('active_global'), strategySummary(draft.global || {}));
  if (coreLayer && coreLayer.updated_at) kv(stBox, t('updated_at'), String(coreLayer.updated_at));
  section.appendChild(stBox);
}
function presetCard(p) {
  var card = el('div', 'card preset');
  var head = el('div', 'row');
  head.appendChild(el('h3', '', loc(p.name)));
  (p.backends || []).forEach(function (b) {
    var avail = backendAvailable(b);
    head.appendChild(badge(b, avail === false ? 'bad' : 'ok'));
  });
  card.appendChild(head);
  card.appendChild(el('p', '', loc(p.description)));
  card.appendChild(el('p', 'muted', t('preset_targets') + ': ' + loc(p.targets)));
  card.appendChild(el('p', 'muted', t('preset_cost') + ': ' + loc(p.cost)));
  card.appendChild(el('p', 'mono muted', JSON.stringify(p.strategy)));
  var row = el('div', 'row');
  var applyBtn = el('button', 'btn btn-primary', t('preset_apply'));
  applyBtn.addEventListener('click', async function () {
    draft.global = clone(p.strategy);
    await applyLayer();
  });
  row.appendChild(applyBtn);
  var edBtn = el('button', 'btn', t('preset_to_editor'));
  edBtn.addEventListener('click', function () {
    editorBuf = normalizeStrategy(clone(p.strategy));
    editorSourcePreset = p.id;
    activeTab = 'editor';
    renderAll();
  });
  row.appendChild(edBtn);
  card.appendChild(row);
  return card;
}
function renderPresets(section) {
  PRESETS.forEach(function (p) { section.appendChild(presetCard(p)); });
}

/* ---------------- editor ---------------- */
function groupGate(group) {
  /* Returns {badgeText, unavailable} for a field group. */
  if (group === 'desync' || group === 'filters') {
    var a = backendAvailable('nfqws');
    return { label: t('gate_nfqws'), unavailable: a === false };
  }
  return null;
}
function fieldGate(fd) {
  if (fd.group === 'desync' || fd.group === 'filters') return null; /* group gate covers it */
  if (fd.key === 'split_pos') return null; /* both backends consume split positions */
  if (TPWS_ONLY.indexOf(fd.key) >= 0) {
    var a = backendAvailable('tpws');
    return { label: t('gate_tpws'), unavailable: a === false };
  }
  return null;
}
function renderEditor(section) {
  section.appendChild(el('p', 'muted', t('editor_intro')));
  var srcRow = el('div', 'row');
  var sel = el('select', 'input');
  var noneOpt = el('option', '', t('choose_preset'));
  noneOpt.value = '';
  sel.appendChild(noneOpt);
  PRESETS.forEach(function (p) {
    var o = el('option', '', loc(p.name));
    o.value = p.id;
    if (editorSourcePreset === p.id) o.selected = true;
    sel.appendChild(o);
  });
  sel.addEventListener('change', function () {
    var p = findPreset(sel.value);
    if (p) {
      editorBuf = normalizeStrategy(clone(p.strategy));
      editorSourcePreset = p.id;
      renderAll();
    }
  });
  srcRow.appendChild(sel);
  var resetBtn = el('button', 'btn', t('reset_to_preset'));
  resetBtn.addEventListener('click', function () {
    var p = findPreset(editorSourcePreset);
    editorBuf = p ? normalizeStrategy(clone(p.strategy)) : normalizeStrategy(draft.global || {});
    renderAll();
  });
  srcRow.appendChild(resetBtn);
  section.appendChild(srcRow);

  var errBox = el('div', 'errors');
  section.appendChild(errBox);
  function refreshErrors() {
    clear(errBox);
    var errs = validateStrategy(editorBuf);
    var wire = toWire(editorBuf);
    if (isEmptyWire(wire)) {
      errBox.appendChild(el('p', 'muted', t('strategy_empty_ok')));
      return;
    }
    if (errs.length) {
      errBox.appendChild(el('p', 'err-title', t('validation_errors')));
      errs.forEach(function (m) { errBox.appendChild(el('p', 'err', m)); });
    }
  }

  GROUPS.forEach(function (group) {
    var box = el('div', 'card');
    var head = el('div', 'row');
    head.appendChild(el('h3', '', (STRINGS[lang].groups && STRINGS[lang].groups[group]) || group));
    var gate = groupGate(group);
    if (gate) {
      head.appendChild(badge(gate.label, gate.unavailable ? 'bad' : 'dim'));
      if (gate.unavailable) head.appendChild(el('span', 'reason', t('gate_unavailable')));
    }
    box.appendChild(head);
    FIELD_DEFS.filter(function (fd) { return fd.group === group; }).forEach(function (fd) {
      box.appendChild(renderField(fd, refreshErrors));
    });
    section.appendChild(box);
  });
  refreshErrors();

  var row = el('div', 'row');
  var applyBtn = el('button', 'btn btn-primary', t('apply_global'));
  applyBtn.addEventListener('click', async function () {
    var errs = validateStrategy(editorBuf);
    if (!isEmptyWire(toWire(editorBuf)) && errs.length) { showBanner(errs.join('\n'), true); return; }
    draft.global = isEmptyWire(toWire(editorBuf)) ? null : toWire(editorBuf);
    await applyLayer();
  });
  row.appendChild(applyBtn);
  var dirtySpan = el('span', 'muted',
    sameJSON(toWire(editorBuf), draft.global || {}) ? '' : t('dirty'));
  row.appendChild(dirtySpan);
  section.appendChild(row);
}
function renderField(fd, onChange) {
  var wrap = el('div', 'field');
  var labelRow = el('div', 'row');
  labelRow.appendChild(el('label', 'field-label', fieldText(fd.key, 'label')));
  var gate = fieldGate(fd);
  if (gate) {
    labelRow.appendChild(badge(gate.label, gate.unavailable ? 'bad' : 'dim'));
    if (gate.unavailable) labelRow.appendChild(el('span', 'reason', t('gate_unavailable')));
  }
  labelRow.appendChild(el('span', 'mono muted', fd.key));
  wrap.appendChild(labelRow);
  wrap.appendChild(el('p', 'hint', fieldText(fd.key, 'hint')));
  var v = editorBuf[fd.key];
  var input;
  if (fd.type === 'bool') {
    input = el('input', 'check');
    input.type = 'checkbox';
    input.checked = !!v;
    input.addEventListener('change', function () { editorBuf[fd.key] = input.checked; onChange(); });
  } else if (fd.type === 'enum') {
    input = el('select', 'input');
    ['', 'http', 'tls'].forEach(function (opt) {
      var o = el('option', '', opt === '' ? '—' : opt);
      o.value = opt;
      if (v === opt) o.selected = true;
      input.appendChild(o);
    });
    input.addEventListener('change', function () { editorBuf[fd.key] = input.value; onChange(); });
  } else if (fd.type === 'int') {
    input = el('input', 'input');
    input.type = 'number';
    input.min = String(fd.min);
    input.max = String(fd.max);
    input.value = String(v || 0);
    input.addEventListener('change', function () {
      editorBuf[fd.key] = Math.trunc(Number(input.value) || 0);
      onChange();
    });
  } else if (fd.type === 'list') {
    input = el('textarea', 'input mono');
    input.rows = 3;
    input.value = (v || []).join('\n');
    input.placeholder = t('list_hint');
    if (fd.key === 'desync') input.placeholder = t('desync_modes_label') + ': ' + DESYNC_MODES.join(', ');
    input.addEventListener('change', function () {
      editorBuf[fd.key] = input.value.split('\n').map(function (s) { return s.trim(); }).filter(Boolean);
      onChange();
    });
  } else {
    input = el('input', 'input mono');
    input.type = 'text';
    input.value = v || '';
    input.addEventListener('change', function () { editorBuf[fd.key] = input.value.trim(); onChange(); });
  }
  wrap.appendChild(input);
  return wrap;
}

/* ---------------- bindings ---------------- */
function renderBindings(section) {
  section.appendChild(el('p', 'muted', t('bindings_intro')));
  section.appendChild(el('p', 'warn', t('bindings_precedence')));
  if (!draft.bindings.length) section.appendChild(el('p', 'muted', t('bindings_empty')));
  draft.bindings.forEach(function (b, i) {
    var card = el('div', 'card');
    var row = el('div', 'row');
    var matchInput = el('input', 'input');
    matchInput.type = 'text';
    matchInput.value = b.match;
    matchInput.placeholder = t('binding_match');
    matchInput.addEventListener('change', function () { b.match = matchInput.value.trim(); renderAll(); });
    row.appendChild(matchInput);
    var edBtn = el('button', 'btn', t('binding_edit'));
    edBtn.addEventListener('click', function () {
      editorBuf = normalizeStrategy(clone(b.strategy));
      editorSourcePreset = b.preset_id || '';
      activeTab = 'editor';
      renderAll();
    });
    row.appendChild(edBtn);
    var delBtn = el('button', 'btn', t('binding_delete'));
    delBtn.addEventListener('click', function () { draft.bindings.splice(i, 1); renderAll(); });
    row.appendChild(delBtn);
    card.appendChild(row);
    card.appendChild(el('p', 'mono muted', JSON.stringify(b.strategy)));
    var presetSel = el('select', 'input');
    var po = el('option', '', t('choose_preset'));
    po.value = '';
    presetSel.appendChild(po);
    PRESETS.forEach(function (p) {
      var o = el('option', '', loc(p.name));
      o.value = p.id;
      if (b.preset_id === p.id) o.selected = true;
      presetSel.appendChild(o);
    });
    presetSel.addEventListener('change', function () {
      var p = findPreset(presetSel.value);
      if (p) { b.strategy = clone(p.strategy); b.preset_id = p.id; renderAll(); }
    });
    card.appendChild(presetSel);
    section.appendChild(card);
  });
  var addCard = el('div', 'card');
  addCard.appendChild(el('h3', '', t('binding_add')));
  var addRow = el('div', 'row');
  var newMatch = el('input', 'input');
  newMatch.type = 'text';
  newMatch.placeholder = t('binding_match');
  addRow.appendChild(newMatch);
  var newPreset = el('select', 'input');
  var npo = el('option', '', t('choose_preset'));
  npo.value = '';
  newPreset.appendChild(npo);
  PRESETS.forEach(function (p) {
    var o = el('option', '', loc(p.name));
    o.value = p.id;
    newPreset.appendChild(o);
  });
  addRow.appendChild(newPreset);
  addCard.appendChild(addRow);
  var addBtns = el('div', 'row');
  var addPresetBtn = el('button', 'btn', t('binding_add') + ' · ' + t('binding_from_preset'));
  addPresetBtn.addEventListener('click', function () {
    var p = findPreset(newPreset.value);
    if (!newMatch.value.trim() || !p) return;
    draft.bindings.push({ match: newMatch.value.trim(), strategy: clone(p.strategy), preset_id: p.id });
    renderAll();
  });
  addBtns.appendChild(addPresetBtn);
  var addEditorBtn = el('button', 'btn', t('binding_from_editor'));
  addEditorBtn.addEventListener('click', function () {
    if (!newMatch.value.trim()) return;
    draft.bindings.push({ match: newMatch.value.trim(), strategy: toWire(editorBuf), preset_id: '' });
    renderAll();
  });
  addBtns.appendChild(addEditorBtn);
  addCard.appendChild(addBtns);
  section.appendChild(addCard);
  var applyBtn = el('button', 'btn btn-primary', t('apply_layer'));
  applyBtn.addEventListener('click', function () { applyLayer(); });
  section.appendChild(applyBtn);
}

/* ---------------- tune ---------------- */
function renderTune(section) {
  section.appendChild(el('p', 'muted', t('tune_intro')));
  var row = el('div', 'row');
  row.appendChild(el('label', '', t('tune_engine')));
  var eng = el('select', 'input');
  [['', t('tune_engine_auto')], ['nfqws', 'nfqws'], ['tpws', 'tpws']].forEach(function (pair) {
    var o = el('option', '', pair[1]);
    o.value = pair[0];
    eng.appendChild(o);
  });
  row.appendChild(eng);
  var runBtn = el('button', 'btn btn-primary', t('tune_run'));
  row.appendChild(runBtn);
  section.appendChild(row);
  var out = el('div');
  section.appendChild(out);
  runBtn.addEventListener('click', async function () {
    clear(out);
    out.appendChild(el('p', 'muted', t('tune_running')));
    try {
      tuneResult = await api('tuneDesync', { engine: eng.value });
      renderAll();
    } catch (e) {
      clear(out);
      out.appendChild(el('p', 'err', errorText(e)));
    }
  });
  if (tuneResult) {
    var box = el('div', 'card');
    box.appendChild(el('h3', '', t('tune_winner')));
    if (tuneResult.winner_describe) kv(box, t('tune_winner'), String(tuneResult.winner_describe));
    if (tuneResult.winner_id) kv(box, 'id', String(tuneResult.winner_id));
    if (typeof tuneResult.score === 'number') {
      /* The contract does not pin the scale: <= 1.5 reads as a
       * fraction, anything larger as an already-percent value. */
      var pct = tuneResult.score <= 1.5 ? tuneResult.score * 100 : tuneResult.score;
      kv(box, t('tune_score'), String(Math.round(pct)) + '%');
    }
    if (typeof tuneResult.attempts === 'number') kv(box, t('tune_attempts'), String(tuneResult.attempts));
    if (tuneResult.strategy) {
      box.appendChild(el('p', 'mono muted', JSON.stringify(tuneResult.strategy)));
      var ab = el('button', 'btn btn-primary', t('tune_apply_winner'));
      ab.addEventListener('click', async function () {
        draft.global = clone(tuneResult.strategy);
        await applyLayer();
      });
      box.appendChild(ab);
    } else if (tuneResult.winner_id || tuneResult.winner_describe) {
      box.appendChild(el('p', 'muted', t('tune_bound_to_profile')));
    } else {
      box.appendChild(el('p', 'muted', t('tune_no_winner')));
    }
    section.appendChild(box);
  }
}

/* ---------------- monitor ---------------- */
function renderMonitor(section) {
  section.appendChild(el('p', 'muted', t('monitor_intro')));
  var clearBtn = el('button', 'btn', t('monitor_clear'));
  clearBtn.addEventListener('click', function () { monitorEvents = []; renderAll(); });
  section.appendChild(clearBtn);
  if (!monitorEvents.length) {
    section.appendChild(el('p', 'empty', t('monitor_empty')));
    return;
  }
  monitorEvents.slice().reverse().forEach(function (ev) {
    var card = el('div', 'card');
    var kindLabel = (STRINGS[lang].censorship_kinds && STRINGS[lang].censorship_kinds[ev.censorship_kind]) ||
      STRINGS.en.censorship_kinds.unknown;
    var head = el('div', 'row');
    head.appendChild(el('strong', '', t('censorship_event') + ': ' + kindLabel));
    if (ev.censorship_kind && !STRINGS.en.censorship_kinds[ev.censorship_kind]) {
      head.appendChild(el('span', 'mono muted', String(ev.censorship_kind)));
    }
    if (ev.at) head.appendChild(el('span', 'muted', new Date(ev.at).toLocaleString()));
    card.appendChild(head);
    if (ev.explanation) card.appendChild(el('p', '', String(ev.explanation)));
    section.appendChild(card);
  });
}

/* ---------------- profiles (export / import / reset) ---------------- */
function renderProfiles(section) {
  section.appendChild(el('p', 'muted', t('profiles_intro')));
  var box = el('div', 'card');
  box.appendChild(el('h3', '', t('export_label')));
  var exp = el('textarea', 'input mono');
  exp.rows = 10;
  exp.readOnly = true;
  exp.value = JSON.stringify({
    global: draft.global || null,
    bindings: draft.bindings.map(function (b) { return { match: b.match, strategy: b.strategy }; })
  }, null, 2);
  box.appendChild(exp);
  section.appendChild(box);

  var impBox = el('div', 'card');
  impBox.appendChild(el('h3', '', t('import_label')));
  var imp = el('textarea', 'input mono');
  imp.rows = 10;
  impBox.appendChild(imp);
  var preview = el('div');
  impBox.appendChild(preview);
  var loadBtn = el('button', 'btn btn-primary', t('import_load'));
  loadBtn.disabled = true;
  impBox.appendChild(loadBtn);
  var parsed = null;
  imp.addEventListener('input', function () {
    clear(preview);
    parsed = null;
    loadBtn.disabled = true;
    if (!imp.value.trim()) return;
    try {
      var obj = JSON.parse(imp.value);
      if (!obj || typeof obj !== 'object' || Array.isArray(obj)) throw new Error('not an object');
      var g = obj.global ? normalizeStrategy(obj.global) : null;
      var binds = Array.isArray(obj.bindings) ? obj.bindings : [];
      var normBinds = binds.map(function (b) {
        if (!b || typeof b.match !== 'string' || !b.match) throw new Error('binding without match');
        return { match: b.match, strategy: toWire(normalizeStrategy(b.strategy || {})), preset_id: '' };
      });
      var problems = [];
      if (g && !isEmptyWire(toWire(g))) problems = problems.concat(validateStrategy(g));
      normBinds.forEach(function (b) {
        problems = problems.concat(validateStrategy(normalizeStrategy(b.strategy)));
      });
      if (problems.length) throw new Error(problems.join('; '));
      parsed = { global: g ? (isEmptyWire(toWire(g)) ? null : toWire(g)) : null, bindings: normBinds };
      preview.appendChild(el('p', 'muted', t('import_preview') + ': ' + t('active_global') + ' = ' +
        strategySummary(parsed.global || {}) + '; ' + t('bindings_count') + ' = ' + parsed.bindings.length));
      loadBtn.disabled = false;
    } catch (e) {
      preview.appendChild(el('p', 'err', t('import_invalid') + ' ' + (e && e.message ? e.message : '')));
    }
  });
  loadBtn.addEventListener('click', function () {
    if (!parsed) return;
    draft.global = parsed.global;
    draft.bindings = parsed.bindings;
    editorBuf = normalizeStrategy(draft.global || {});
    showBanner(t('dirty'), false);
    renderAll();
  });
  section.appendChild(impBox);

  var resetBtn = el('button', 'btn btn-danger', t('reset_all'));
  resetBtn.addEventListener('click', function () {
    draft.global = null;
    draft.bindings = [];
    editorBuf = emptyStrategy();
    editorSourcePreset = '';
    showBanner(t('reset_all_body'), false);
    renderAll();
  });
  section.appendChild(resetBtn);
  section.appendChild(el('p', 'muted', t('reset_all_body')));
  var applyBtn = el('button', 'btn btn-primary', t('apply_layer'));
  applyBtn.addEventListener('click', function () { applyLayer(); });
  section.appendChild(applyBtn);
}

/* ---------------- events & boot ---------------- */
function onBridgeEvent(kind, detail) {
  if (kind === 'bypass.event') {
    var ev = null;
    try { ev = JSON.parse(detail); } catch (e) { ev = null; }
    if (ev && ev.kind === 'censorship') {
      monitorEvents.push({
        censorship_kind: String(ev.censorship_kind || 'unknown'),
        explanation: String(ev.explanation || ''),
        at: ev.at || new Date().toISOString()
      });
      var limit = settings.monitor_limit || 50;
      if (monitorEvents.length > limit) monitorEvents = monitorEvents.slice(monitorEvents.length - limit);
      if (activeTab === 'monitor') renderAll();
    }
    return;
  }
  if (kind === 'session.connected' || kind === 'session.disconnected') { refreshCore(); }
}
async function boot() {
  root = document.getElementById('app');
  var modal = document.getElementById('confirm-modal');
  document.getElementById('confirm-title').textContent = t('confirm_apply_title');
  document.getElementById('confirm-body').textContent = t('confirm_apply_body');
  var okBtn = document.getElementById('confirm-ok');
  var cancelBtn = document.getElementById('confirm-cancel');
  okBtn.textContent = t('confirm');
  cancelBtn.textContent = t('cancel');
  function closeModal(result) {
    modal.style.display = 'none';
    if (confirmResolver) { var r = confirmResolver; confirmResolver = null; r(result); }
  }
  okBtn.addEventListener('click', function () { closeModal(true); });
  cancelBtn.addEventListener('click', function () { closeModal(false); });
  if (bridgeOK) {
    try {
      var s = await api('getSettings', {});
      if (s && typeof s === 'object') {
        if (typeof s.language === 'string') settings.language = s.language;
        if (typeof s.confirm_apply === 'boolean') settings.confirm_apply = s.confirm_apply;
        if (typeof s.monitor_limit === 'number') settings.monitor_limit = s.monitor_limit;
      }
    } catch (e) { /* defaults apply */ }
    lang = resolveLang();
    document.getElementById('confirm-title').textContent = t('confirm_apply_title');
    document.getElementById('confirm-body').textContent = t('confirm_apply_body');
    okBtn.textContent = t('confirm');
    cancelBtn.textContent = t('cancel');
    if (window.soraExt.onEvent) window.soraExt.onEvent(onBridgeEvent);
    renderAll();
    refreshCore();
  } else {
    lang = resolveLang();
    renderAll();
    showBanner(t('bridge_missing'), true);
  }
}
document.addEventListener('DOMContentLoaded', boot);
