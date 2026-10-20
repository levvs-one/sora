# S5 — зеркала sora ↔ sora-legacy + внешние форматы + docs ↔ код

Отдел совместимости стыков, кластер S5. Дата: 2026-10-20.
Репозитории: `sora` и `sora-legacy`, ветка `bugfix/audit-2026-10-19`, без пуша.
Горячая зона соблюдена: `sora/core/parser/*` и `sora/core/probe/*` в момент
работы — `MM` (отдел интеграции, коммиты `[integration]` 408ad878 / 1b094621 /
f7a830b7 / 5ba2d079 поверх). Ни один грязный чужой файл не тронут; все находки
по горячим файлам sora оформлены спеками (раздел «Спеки для sora»), фиксы
внесены только в чистые файлы legacy и в чистые `core/engine/redact*` обоих репо.

Методика: скриптовые сверки множеств (паттерны, схемы, поля, форматы) +
одинаковые поведенческие пробы временными тестами в обоих репо (пробы удалены
после прогона; постоянные тесты — в коммитах кластера).

---

## 1. Редакторы логов (parity)

Реализации: `core/engine/redact.go` в обоих репо (единственный паттерн-редактор;
`core/logs` секретов не маскирует — только хранит/экспортирует, маскирование —
`engine.Redactor`).

Сверка множеств (скриптом, по исходникам):

- 5 паттернов в обоих: `uuidPattern`, `keyValuePattern`,
  `strictKeyValuePattern`, `userInfoPattern`, `tokenLinkPattern`.
- Альтернация ключей `keyValuePattern` совпадает по составу (uuid, password,
  passwd, secret, token, private[_-]?key, pre[_-]?shared[_-]?key,
  obfs[_-]?password, obfs[_-]?param, api[_-]?key, auth(?:[_-]?str)?,
  secret[_-]?key, client[_-]?secret, psk, public[_-]?key, short[_-]?id,
  spider[_-]?x, username). Текстуально различается только экранирование кавычки
  в raw-строке (`\\\"` в sora против `\"` в legacy) — семантика классов
  эквивалентна для разделителя (лишний `\` в классе sora безвреден).
- Альтернация схем `userInfoPattern` идентична.
- Гейты: у обоих — per-pattern ASCII-гейты (`gateFlagsASCII`/`keyGateWords`);
  у sora дополнительно `gateContains`+`gateWords` для не-ASCII пути, у legacy
  не-ASCII путь безусловный. Поведенчески эквивалентно (дифференциальный тест
  в обоих репо это пинит).

Прогон пинов: `go test ./engine/ -run 'TestRedactorParity|TestMaskGateParity'`
— **ok в обоих репо**. `TestRedactorParityKeySpellings` жив с обеих сторон
(pre_shared_key ↔ public_key/spider_x дрейф 3-го прохода закрыт и запинен).

Расширенная проба S5 (17 форм, одинаковый файл в обоих репо): формы из аудитов
(password/token/uuid/private_key в кавычках ×3 вида, без кавычек, с пробелами,
в URL `?token=`, в JSON, `PrivateKey =`/`PresharedKey =` в WG-стиле,
`X-Api-Key:`) маскируются **в обоих**. НО найдены одинаковые в обоих репо
незапиненные формы (**общий слепой пятно, не дрейф**):

- `access_token=…`, `refresh_token=…`, `session_token=…`,
  `"accessToken": "…"` — НЕ маскировались: `\btoken\b` не матчится внутри
  составного ключа (`_` — word-символ, границы слова нет).
- `Authorization: Bearer …` и голый `Bearer …` — НЕ маскировались
  (`auth` в alternation не покрывает `Authorization:` — после `auth` нет `\b`).

**Вердикт: РАЗРЫВ (общий, исправлен в обоих репо)** — фикс S5-R1 ниже:
в `keyValuePattern` добавлены составные `*_token`
(`(?:access|refresh|session|id|auth|api)[_-]?token`), добавлены
`authHeaderPattern` и `bearerPattern` с собственными гейтами; паритет запинен
новым `TestRedactorParityCompoundTokens` в обоих репо, дифференциальные
тесты обновлены (эталонный конвейер включает новые паттерны, фрагменты
`Authorization: Bearer …` / `access_token=…` добавлены в корпус).

Мелочь без фикса: значение в обратных кавычках (`token: \`phrase tail\``)
маскирует только первое слово — backtick не входит в value-альтернацию ни в
одном репо; формы секретов в backtick в реальных конфигах движков не
встречаются, риск — хвост фразы в логе, не сам секрет целиком. Оставлено
спекой низкого приоритета.

## 2. Парсеры подписок — зеркальный дифф

Схемы ссылок: множества идентичны в обоих репо —
`vless, vmess, trojan, ss, socks, socks5, http, https, hysteria2, hy2, tuic,
wireguard, wg` (`hasScheme`/`linkSchemes`); форматы детекта идентичны —
`unknown, https/http-subscription, share-link, base64-list, sip008,
clash-yaml, sing-box-json, xray-json, wireguard-conf, plain-list`.
Негативный паритет: `openvpn://` отвергается обоими (в sora запинено
`TestOpenVPNLinksAreRejected`; схем naive/snell/anytls-ссылок нет ни в одном —
anytls существует только как протокольная константа плана).

Поведенческая проба (одинаковые ссылки/образцы в обоих репо) — расхождения:

| Вход | sora | sora-legacy | Вердикт |
|---|---|---|---|
| `trojan://pass@host` | Password=pass, UUID="" | Password="", UUID=pass | **РАЗРЫВ → исправлен в legacy** (порт фикса интеграции 1b094621; тест `TestParsePasswordOnlyCredentials` теперь в обоих репо) |
| `hysteria2://pass@host`, `hy2://…` | то же | то же | **РАЗРЫВ → исправлен в legacy** |
| SIP008 JSON (без поля `type`, `remarks`) | 0 серверов, Invalid=1 | 0 серверов, Invalid=1 | **РАЗРЫВ общий**: формат обещан и детектится, но не импортируется. Исправлен в legacy (fallback `shadowsocks` + `remarks`); для sora — спека S5-SP1 (файл горячий) |
| `vless://<uuid-v7>@host` | Invalid (uuidRE `[1-5]`) | импортируется (uuidRE `[1-8]`, тест `TestParserAcceptsNewerUUIDVersions`) | **РАЗРЫВ**: sora отстаёт; спека S5-SP2 (файл горячий). Провайдеры (Remnawave и др.) выдают v7 |
| `ss://…?plugin=v2ray-plugin%3Btls%3Bhost=…` | Options: `ss_plugin`+`ss_plugin_opts` канонизированы, downstream `control/plan.go` → `Outbound.Plugin/PluginOpts` | только сырой `plugin` в Options; ни parser-канонизации, ни `Plugin`-полей в плане, ни чтения в `control/plan.go` | **РАЗРЫВ (legacy, структурный)**: SIP002-плагин молча теряется end-to-end. Спека S5-SP3 — порт полей+канонизации целиком, одним изменением, не по частям |
| `vless … type=xhttp&extra={downloadSettings}` | `DownloadAddress/DownloadPort` в спеке и плане | полей нет ни в спеке, ни в `Transport` | **РАЗРЫВ (legacy, структурный)** — часть XHTTP-разрыва §3 |
| hy2 tuning (`upmbps/downmbps/ports/obfs/obfs-password`), TUIC (`congestion_control/udp_relay_mode`), vmess classic base64-JSON и URL-формы, WG `.conf`, socks5 user:pass | импортируется | импортируется идентично (Options/поля совпали в пробе) | СОВМЕСТИМ (доказательство — проба §4) |
| sing-box JSON / Clash YAML (§4) | 1 сервер, сырьё в Options | идентично | СОВМЕСТИМ на уровне парсера |

Отдельно: интеграционные фиксы sora (vmess classic 408ad878, trojan/hy2
1b094621) запинены тестами sora (`TestParseClassicVMessJSON`,
`TestParseVMessURLStyleStillWorks`, `TestParsePasswordOnlyCredentials`,
`TestParseHysteria2TuningOptions`, `TestParseShadowsocksPlugin`,
`TestParseExtraDownloadSettings`) — прогон `./parser/` в sora: тесты парсера
проходят; полный `go test ./...` в момент проверки падал на **чужом грязном**
`core/engine/mihomo` (`binary_xhttp_test.go`: `undefined:
renderOutboundYAMLForEngine`) — не парсер и не зона S5, зафиксировано как
чужая WIP-ломка, родителю на заметку.

## 3. Валидаторы REALITY / XHTTP / AmneziaWG

Общая проба (12 векторов, `Outbound.Validate()`, одинаковый файл в обоих репо):

| Вектор | sora | legacy (до фикса) |
|---|---|---|
| AWG sane / Jc=129 | ok / reject | ok / reject — **СОВМЕСТИМ** |
| REALITY good (43-char pbk, hex sid) | ok | ok |
| REALITY pbk="" / "AAAA" / sid не-hex / sid 20 hex | reject ×4 | **accept ×4** |
| XHTTP mode="stream-sideways" | reject | **accept** |
| XHTTP + vision без VLESS Encryption | reject | **accept** |
| protocol="bogusproto" / transport="bogustransport" | reject | **accept** (проверялась только пустота протокола) |

Причина: в legacy нет `reality.go` вообще, нет `validateXHTTP`, нет белых
списков протоколов/транспортов; `Transport` legacy не имеет полей
DownloadAddress/Port, Xmux*, XPaddingBytes (структурный разрыв XHTTP —
валидировать нечего, поля теряются раньше, на конверсии в план).
AmneziaWG: ядро bounds (Jc/Jmin/Jmax/S*/H*-диапазоны/пересечения) байт-в-байт
то же; sora дополнительно валидирует 3.1-поля, которых в legacy-структуре
`AmneziaWG` нет (HeaderProtectionKey, *PaddingAddition, тайминги,
Masquerade*) — генерационное расхождение, не дефект общих векторов.
ECH/KeyShare-валидация TLS в sora (`TLS.validate`) в legacy отсутствует —
та же спека.

**Вердикт: РАЗРЫВ → частично исправлен в legacy** (фикс S5-V1): портированы
`reality.go` (ValidateReality/RealityWarnings/хелперы, поведение — оригиналы
sora), подмножество `validateXHTTP` для представимых в legacy полей
(mode-whitelist, vision-без-Encryption, ALPN h3 без TLS), белые списки
протоколов/транспортов (множества = sora), `Identifiers()` дополнен
RealityPublicKey/ShortID/SpiderX (sora SORA-L9: legacy не маскировал их в
логах). Запинено `TestValidateRealityParity` (12 векторов выше).
Остаток спеками: S5-SP4 (XHTTP-поля в `Transport` legacy + остальные проверки
sora), S5-SP5 (ECH/KeyShare).

Известный env-шум: `TestTunAndFakeIPAvoidLANAndEachOther` падает на ЭТОЙ VM
и на чистом HEAD legacy (fake-IP пул пересекается с реальным интерфейсом
хоста) — не связано с фиксами S5, **НЕ ПРОВЕРЯЕМО ЗДЕСЬ** для этого теста.

## 4. Внешний импорт ↔ обещания

Обещания взяты из `docs/providers.md` (главный документ обещаний), `docs/usage.md`,
Dart `app/lib/src/desktop/links.dart`. Образцы прогнаны через `LinkParser.Parse`
в обоих репо (проба §2) + существующие тесты парсера:

| Обещание | Результат пробы | Вердикт |
|---|---|---|
| Список ссылок / он же в base64 | `TestParseLinks`, `TestBase64Wrapped` + проба | СОВМЕСТИМ |
| Ссылки vless/vmess/trojan/ss/hy2/tuic/wg/socks/http(s) | проба по каждой схеме | СОВМЕСТИМ (кроме trojan/hy2-пароля в legacy — §2, исправлено) |
| WG/AmneziaWG `.conf` | проба: 1 сервер, peer+psk+endpoint+allowedIPs сохранены, interface в Options | СОВМЕСТИМ |
| SIP008 | проба: 0 серверов в обоих | **РАЗРЫВ** (§2) |
| Xray JSON-подписки (Remnawave) целиком профилем | `TestXrayConfigurationsBecomeProfiles` в обоих + проба xrayItems | СОВМЕСТИМ |
| sing-box JSON (`outbounds[]`) | проба: Format=sing-box-json, 1 сервер; НО типизированные поля спеки (PublicKey/ShortID/ServerName/Path) пусты — REALITY/TLS/WS лежат только сырым JSON в Options; downstream `control/plan.go` читает типизированные поля | **ЧАСТИЧНЫЙ РАЗРЫВ (общий)**: импорт не теряет данные безвозвратно (Options полны), но plan-конверсия REALITY из sing-box/Clash JSON не извлекает. Спека S5-SP6 (конверсия — не горячий parser, а `core/control/plan.go`; в sora файл на момент проверки чистый, но это зона стыка с интеграцией — оставлено спекой) |
| Clash YAML (`proxies:`) | проба: flow- и block-стили, vless+reality-opts, trojan — 1 сервер каждый; та же оговорка про типизированные поля (transport=ws извлечён, path из ws-opts — нет) | **ЧАСТИЧНЫЙ РАЗРЫВ (общий)** — та же спека S5-SP6 |
| v2rayNG-ссылки | v2rayNG отдаёт те же share-ссылки (vmess classic запинен тестом sora; в legacy classic-форма та же — проба parseVMess идентична) + `v2rayn://install-config` диплинк в Dart | СОВМЕСТИМ |
| Happ-экспорт | Отдельного формата экспорта Happ НЕ существует (WAVE-INTEGRATION-happ.md): Happ принимает те же подписки/ссылки; фирменные только `happ://crypt…` (закрытый формат) и `happRouting`. `docs/providers.md` честно пишет: crypt не читается; Dart `links.dart` возвращает `SealedForHapp` | СОВМЕСТИМ с обещанием (обещание = честный отказ, код ему соответствует). `happRouting` в sora не принимается — в docs НЕ обещан, разрывом не является; зафиксировано в WAVE-INTEGRATION как C3 |
| Диплинки импорта: `sora://add/…`, `sora://add?url=…`, `happ://add/…`, `v2rayn://install-config?url=`, `clash://install-config?url=&name=`, `hiddify://import/…#name`, `sing-box://import-remote-profile?url=#name` | Все формы разбираются `parseImportLink` (links.dart): sora/happ — `add/` и host==`add`+`url`; v2rayn/v2rayng/clash/clashx/mihomo — `install-config`; sing-box — `import-remote-profile`, имя из fragment; hiddify — `import/`, имя после последнего `#` | СОВМЕСТИМ (чтение кода + `app/test/desktop_test.dart` содержит тесты parseImportLink; Dart-тесты здесь не гонялись — нет Flutter-тулчейна в этой сессии, **НЕ ПРОВЕРЯЕМО ЗДЕСЬ** исполнением) |
| Дополнительно в Dart, НЕ в docs: `streisand://import/…` | Поддерживается кодом, в providers.md не упомянут | Не разрыв обещания (недокументированная возможность); заметка, не спека |

Round-trip шаринга: per-server генератора ссылок в sora нет — шаринг это
ссылка подписки (`GetSubscriptionLink` возвращает сохранённый URL;
`servers.dart::_shareQr` QR-кодирует именно его). Round-trip сводится к:
(1) `https://…` и `sora://add/<url>` обратно разбираются `parseImportLink`
в тот же URL — СОВМЕСТИМ по коду Dart; (2) повторный Parse тех же share-ссылок
парсером детерминирован (StableKey стабилен, дубли отсекаются — запинено
`TestParseClashDuplicatesByStableKey`/`TestParseJSONDuplicatesByStableKey`
в обоих репо) — СОВМЕСТИМ.

## 5. Docs ↔ код (sora)

Скриптовая сверка (извлечено из `docs/*.md` + корневых README; каждое проверено
грепом по всему репозиторию, включая скрипты/тесты/packaging, не только Go):

- **Env-переменные** (14): SORA_ARCH, SORA_COEXIST_{CORE,SECONDS,VPNS,WORK},
  SORA_CORE_LIVE, SORA_CORE_SOCKET, SORA_ENGINES_DIR, SORA_MIHOMO_BIN,
  SORA_SINGBOX_BIN, SORA_TUNNEL_{LIVE,LOG}, SORA_VERSION, SORA_XRAY_BIN —
  **все живы** (Go-код, `core/testdata/coexist/run.sh`, `app/test/live_*`,
  workflows, nfpm). Мёртвых нет.
- **CLI-флаги** sora-core (13): allow-file-keys, bypass, check, data-dir,
  engine, engines-dir, install-service, log-level, print-token, socket,
  tunnel-port, uninstall-service, version — **все найдены в коде**. Мёртвых нет.
- **Имена сервисов/файлов**: `sora-core.service` → `service/linux/sora-core.service`
  (ExecStart совпадает с install.md), Windows-служба `SoraCore` (docs/architecture,
  install) — соответствует packaging/windows; `sora-sync` — `service/sync`
  существует; отсутствие sora-sync в пакетах docs не скрывают (usage.md: экран
  честно сообщает о недоступности) — не мёртвое обещание, известное решение владельца.
- **Пути файлов из docs** (~45 backtick-путей): все существуют, включая
  `core/control/exthost.go`, `core/ext/*`, `tools/sora-ext/templates/shared/sora-ext.d.ts`,
  `updates/releases.json`, `examples/{theme-midnight,net-hook-dpi,routing-split}`.
  Единственное «несуществующее» — `core/mobile` в `docs/android-vpnservice.md`,
  но документ — спека будущей Android-разработки («новый пакет core/mobile»,
  чекбоксы не закрыты), не ссылка на существующее. Не разрыв.
- **Внутренние markdown-ссылки**: скриптом проверены все относительные ссылки
  в `docs/**` + README обоих репо — **битых: 0 / 0**.
- **RPC**: имена из docs (GetSubscriptionLink, WatchSubscriptions, ListConnections,
  ListServers и др.) присутствуют в `proto/sora/core/v1/core_control.proto` и коде.
  Обратная проверка: proto sora = контракт 1.11 (CheckDnsLeaks, BenchmarkServers,
  overrides, profiles, ProbeChain — Since 1.8–1.10), proto legacy отстаёт
  (нет RPC Since 1.8+) — генерационное расхождение поколений, docs legacy его
  не обещают; не разрыв docs↔код ни в одном репо.

**Вердикт §5: СОВМЕСТИМ** — мёртвых ссылок/флагов/env/путей не найдено,
правки docs не потребовались (ни одного doc-файла не тронуто).

---

## Спеки для sora (горячая зона / чужие файлы — НЕ исправлено здесь)

- **S5-SP1 (SIP008, sora)**: в `core/parser/parser.go::parseJSON` при
  `f == FormatSIP008` передавать в `mapJSONSpec` fallback `"shadowsocks"` и
  в `mapJSONSpec` добирать `DisplayName` из `remarks`. Эталон — фикс legacy
  (этот кластер) + тест `TestParseSIP008Document` перенести дословно.
  Приёмка: образец §4 импортирует 1 сервер, `./parser/` зелёный.
- **S5-SP2 (UUID v6–v8, sora)**: `uuidRE` в `core/parser/parser.go` —
  `[1-5]` → `[1-8]` (как legacy) + перенести `TestParserAcceptsNewerUUIDVersions`.
  Иначе vless/vmess/tuic-ссылки с v7-UUID от провайдеров отбраковываются как Invalid.
- **S5-SP3 (SIP002 plugin, legacy — структурно)**: порт из sora целиком:
  parser-канонизация `plugin/plugin_opts` → `ss_plugin/ss_plugin_opts`
  (sora parser.go:397-410, тест `TestParseShadowsocksPlugin`), поля
  `Outbound.Plugin/PluginOpts` (sora engine/plan.go:190-196), конверсия в
  `control/plan.go` (sora: doc.field + outbound.Plugin, строки 175-178/649-650)
  и рендеры obfs-local. По частям не делать: полупорт = та же молчаливая потеря.
- **S5-SP4 (XHTTP-поля, legacy)**: добавить в `Transport` поля
  DownloadAddress/DownloadPort, Xmux*, XPaddingBytes (sora plan.go:122-146),
  протянуть через parser (`applyExtraDownloadSettings` + extra= в ссылках),
  control-конверсию и рендеры; затем дополнить legacy `validateXHTTP`
  проверками downloadSettings/xmux/padding из sora validate.go:258+.
- **S5-SP5 (ECH/KeyShare, legacy)**: порт `TLS.validate` (sora validate.go)
  + hasEncryptedServer-правило ECH.
- **S5-SP6 (sing-box/Clash → типизированные поля)**: в конверсии
  `OutboundSpec → plan` (оба репо, `core/control/plan.go`) извлекать из
  Options-блобов: sing-box `tls.reality.{public_key,short_id}`,
  `tls.server_name`, transport ws/grpc/xhttp path/host; Clash
  `reality-opts.{public-key,short-id}`, `servername`, `ws-opts.path/headers`,
  `grpc-opts`, `network`. Сейчас REALITY-сервер из sing-box/Clash-подписки
  доезжает до плана без pbk и падает уже на ValidateReality (sora) / молча
  без REALITY (legacy). Приёмка: образцы §4 дают план, проходящий Validate,
  с pbk/sid/path заполненными.

## Свои коммиты

Все — ветка `bugfix/audit-2026-10-19`, temp-index + CAS (`update-ref` со
старым значением), `git show --stat HEAD` сверен после каждого; общий индекс
после коммитов содержал чужие снапшоты «наоборот» по тронутым файлам —
нейтрализовано точечным `git restore --staged -- <files>` (worktree == HEAD
во всех случаях, потерь нет; источник эпизодов уже найден форензикой Wave-A).

sora:

- `5f9013c` `[seams-s5] engine/redact: mask compound *_token keys and
  Bearer/Authorization credentials` — redact.go + redact_test.go.
  Проверка: `go test ./engine/` — ok полностью.

sora-legacy:

- `6379922` `[seams-s5] parser: trojan/hy2 password-only links and SIP008
  documents import in legacy` — parser.go + parser_test.go.
  Проверка: `go test ./parser/` — ok.
- `417dc76` `[seams-s5] engine: port REALITY/XHTTP validation and protocol
  whitelists from sora` — reality.go (новый), validate.go, validate_test.go.
  Проверка: целевые тесты engine + `go test ./control/` — ok; полный
  `./engine/` — единственный FAIL `TestTunAndFakeIPAvoidLANAndEachOther`,
  воспроизводится на чистом HEAD (env VM), не связан.
- `d92ec9a` `[seams-s5] engine/redact: mask compound *_token keys and
  Bearer/Authorization credentials` — зеркало sora `5f9013c`.
  Проверка: `go test ./engine/ -run 'TestRedactor|TestMask'` — ok.

В sora кодовых фиксов, кроме редактора, нет сознательно: все остальные
находки — по горячим файлам parser/probe (спеки S5-SP1/S5-SP2) или по
структурным портам (S5-SP3…S5-SP6).

