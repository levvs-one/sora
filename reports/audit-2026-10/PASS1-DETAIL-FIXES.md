# PASS1-DETAIL-FIXES — отдел охотников за мелочами, проход 1/3 (новый круг)

**Период:** 2026-10-20 (после DETAIL-FIXES.md). Пуша нет — всё локально на `bugfix/audit-2026-10-19`.
**База:** DETAIL-FIXES.md (секции A–H) вычитана; за время после неё приземлились TSPU-wire, final-audit, swarm и 21 `[opt]`-коммит оптимизаторов — проверены на изменение семантики и на новые «дефолт врёт / параметр не прокинут / гейт мёртв / пин устарел».
**Результат прохода:** **7 коммитов `[pass1-detail]`** (5 sora + 2 sora-legacy), каждый со своей зоной. Каждый коммит: build + `go vet` + тесты (Go), тройная вычитка (Dart, тулчейна нет). Грязные shared-файлы с чужим WIP не трогал; коммиты только своими ханками (pathspec, для грязных файлов — temp-index CAS-рецепт из AGENTS.md).
**Слоп-фильтр:** мелочь ради мелочи — нет; каждая правка с наблюдаемым эффектом. Часть зоны закрыта как «чисто, фиксить нечего» с доказательствами.

Формат: **было → стало → эффект**.

---

## A. Исправления (коммиты)

### P1 — sora: mihomo REALITY без client-fingerprint (коммит `ad814efa`)

**Было:** `core/engine/mihomo/proxy.go:applyTLS` рендерил REALITY-узлы без `client-fingerprint`, если план его не задавал. sing-box дефолтит отпечаток (`DefaultFingerprint`), xray — `hellochrome_auto`; mihomo оставлял выбор за движком. Асимметрия: один и тот же план на трёх движках — три разных ClientHello на REALITY.
**Стало:** REALITY принуждает `client-fingerprint: engine.DefaultFingerprint` («chrome»), как sing-box-рендер; явный отпечаток побеждает; не-REALITY TLS без отпечатка отпечатка не получает (else-ветка). Порт legacy-коммита `af8d343` (D25), который в sora прошлый круг пропустил.
**Эффект:** REALITY на mihomo всегда едет за uTLS-отпечатком; конфиг детерминирован.
**Тесты:** `TestRenderRealityForcesAClientFingerprint` (позитив: пустой fp → chrome; негатив: «firefox» сохраняется; негатив: plain TLS без REALITY остаётся без client-fingerprint) — PASS; весь пакет mihomo — PASS.

### P2 — sora: AmneziaWG 3.1 + masquerade-ключи не проходили через импорт (коммит `c35a9179`; закрывает Q20 прошлого раунда)

**Было:** `amneziaKeys`/`amneziaFrom` в `core/control/plan.go` знали только 1.x/2.0-ключи. 3.1-параметры (`HeaderProtectionKey`, `ContentPaddingAddition`, `RekeyAfterTime/RekeyTimeout/RejectAfterTime/KeepaliveTimeout/MaxHandshakeAttempts`, `RandomTrailers`, `DisableCookies`, masquerade-трио) молча выкидывались фильтром — конфиг 3.1, импортированный из .conf/ссылки, деградировал до 2.0 без единой жалобы (при этом движок D24 честно отбраковывал бы 3.1 на неподдерживающем движке — но поля не доезжали даже до него).
**Стало:** фильтр расширен всеми документированными 3.1-ключами (строчные интерфейсные имена — 1:1 как на `engine.AmneziaWG`), `amneziaFrom` маппит range/protection-строки verbatim (валидация формы — за валидатором движка D24), bool'ы принимают `1`/`true` как `insecure` в том же файле. Парсер .conf уже выдаёт ключи в нижнем регистре (проверено в `parseWG`).
**Эффект:** 3.1-обфускация переживает импорт; `UsesAWG31()` срабатывает и держит гейт выбора движка.
**Тесты:** `TestAmneziaWG31SurvivesTheVault` — .conf с 3.1 + masquerade → credential vault → `engine.AmneziaWG` все 11 новых полей на месте, `UsesAWG31()==true` — PASS (старый `TestAmneziaWGSurvivesTheVault` тоже зелёный).
**Процесс:** `plan.go` несёт чужой WIP (SS-plugin `ss_plugin`-ханки); коммит собран temp-index CAS-рецептом с фильтром только своих ханков — чужие ханки не тронуты, в коммите их нет (`git show --stat` — только 2 файла).

### P3 — sora Dart: DNS-пресеты врали про шифрование (коммит `cac2cf87`; закрывает Q14)

**Было:** пресеты в `app/lib/src/ui/dns.dart` (`_presets`) задавали голые IP (`1.1.1.1`, `8.8.8.8`, `9.9.9.9`, `94.140.14.14`…), которые ядро парсит как plaintext UDP/53. При этом дефолт `auto` — DoH (`https://1.1.1.1/dns-query`, см. `docs/usage.md` «DNS по умолчанию»), а UI показывает пресеты как «резолверы из каталога». Итог: пользователь, выбравший пресет «Cloudflare», молча **понижал** себя с шифрованного DoH на чистый текст.
**Стало:** все пресеты — DoH: Cloudflare/Google — IP-адресованные (как дефолты ядра, bootstrap не нужен); Quad9 → `https://dns.quad9.net/dns-query` (официальный DoH-эндпоинт Quad9, hostname идёт через bootstrap-резолвер движка — проверена логика `byHostname`/`domain_resolver` в sing-box-рендере); AdGuard → `https://dns.adguard-dns.com/dns-query` (канонический DoH AdGuard; hostname резолвится bootstrap'ом). Эндпоинты сверены с официальными источниками (FAQ Quad9, KB AdGuard).
**Эффект:** пресет больше не даунгрейдит шифрование; формат `https://…/dns-query` распознаётся ядром (`splitDNSServer`), регулярка кастомного ввода UI его принимает.
**Проверка:** Dart SDK нет — тройная вычитка + скрипт инвариантов пресетов против `splitDNSServer`.

### P4 — sora: packaging-README врали версию 1.0.6 (коммит `165082a4`; закрывает Q7)

**Было:** `packaging/linux/README.md` и `packaging/windows/README.md` хардкодили `SORA_VERSION=1.0.6` / `APP_VERSION=1.0.6`, а pubspec уже `1.0.12+13`. Тот, кто собирает по README, молча пакует релиз не той версии (и ломает minisign/версионный гейт обновлений, который D47 чинил в CI).
**Стало:** обе инструкции выводят версию из `app/pubspec.yaml` той же командой, что CI (`.github/workflows/repository.yml`: `grep '^version:' … | cut -d' ' -f2 | cut -d+ -f1` — sh-вариант и PowerShell-эквивалент), с комментарием про единый источник.
**Эффект:** дрейф версии невозможен — документация всегда собирает ту версию, что в pubspec.
**Процесс:** перед `git add` индекс оказался отравлен чужими staged-удалениями `core/control/plan*.go` (тот же процесс, что в OPTIMIZERS.md); снято `git restore --staged`, коммит pathspec-формой — только 2 своих файла.

### P5 — sora: parser fail-closed на hy2 `pinSHA256` (коммит `d6e43be4`)

**Было:** `pinSHA256`/`pin_sha256` собирались парсером в `Options`, но ни план, ни один из трёх рендеров их не потребляют (поля `TLS` в `engine/plan.go` нет). Hysteria2-ссылка с пином сертификата импортировалась **без пина** — пользователь думал, что MITM-пининг работает, а его не было.
**Стало:** `parseLink` отказывает hy2-ссылкам с `pinSHA256`/`pin_sha256` ошибкой `ErrUnsupported` — в списках ссылка пропускается и честно считается в `Report.Unsupported` («unsupported protocol or option»), одиночная — возвращается как unsupported. Прецедент — D08 (fail-closed на нереализованных полях).
**Эффект:** невозможно импортировать «закреплённое» соединение без закрепления; полноценный pinning — задача уровнем выше (согласование трёх движков: `certificate_public_key_sha256`-подобные поля есть не везде).
**Тесты:** `TestPinnedHysteria2LinkIsRefusedNotUnpinned` — `pinSHA256` и `pin_sha256` формы отказаны; в списке из 2 ссылок 1 импортирована + 1 unsupported — PASS; весь пакет parser — PASS.
**Процесс:** `core/parser/parser.go` несёт чужой 1-строчный WIP-ханк по соседству — коммит собран temp-index CAS с фильтром строго по своим маркерам (фильтр с перестраховкой проверен на отсутствие чужих ханков).

### P6 — legacy: xray REALITY-дефолт — закреплённый Chrome 133 (коммит `9bad6de`; аналог D05)

**Было:** `core/engine/xray/render.go` — REALITY без отпечатка рендерил `"fingerprint": "chrome"`. Пиннутый Xray-алиас `chrome` = Chrome 133, который ТСПУ фингерпринтит и бьёт (доказано в sora `engine/fingerprint.go` + JA4-tripwire D11). В sora это чинил D05 через `hellochrome_auto`; legacy остался с дефолтом-133.
**Стало:** дефолт — `hellochrome_auto` (новейший проверенный Chrome-паррот вендорного uTLS Xray 26.3.27 — того же пина, что в sora); явный выбор не переопределяется.
**Эффект:** REALITY-дефолт легаси больше не светит помеченным отпечатком.
**Тесты:** `TestRenderRealityDefaultsToAutoFingerprint` (пустой fp → `hellochrome_auto`; явный `firefox` сохраняется) — PASS; весь пакет xray — PASS.

### P7 — legacy: parser fail-closed на hy2 `pinSHA256` (коммит `9d48637`)

**Было/стало/эффект:** зеркало P5: та же дыра в `core/parser/parser.go` легаси (`pinSHA256` собирался в `Options`, никуда не шёл). Отказ с `ErrUnsupported`, ссылка считается unsupported. Тест `TestPinnedHysteria2LinkIsRefusedNotUnpinned` (список: 1 imported + 1 unsupported) — PASS; пакет parser — PASS.

---

## B. Проверено как «чисто, фиксить нечего» (с доказательствами)

### B1. Оптимизаторы: семантика не изменилась (зонально по коммитам)
- **`76a2ccf1` render pre-size** — sing-box `dns()`: добавлена нормализация пустых `rules` → nil, чтобы сохранить байт-в-байт `null` (был риск `[]` vs `null`); xray `observed()`: `balancerFor` кладёт typed-nil `[]string` — type-assert не паникует, `null` сохранён; `GetBenchmarks`/`found`/`missing`: пустые non-nil слайсы — wire/protobuf-индифферентно, callers смотрят `len()`. Byte-identical рендеры подтверждены тестами пакета.
- **`fc65480a` lazy engine discovery** — `Registry.Pin` сверяет только статическую таблицу драйверов (не зависит от discovery), т.е. eager-валидация пина эквивалентна; `Usable()`-warn перенесён внутрь `get()` — срабатывает до первого connect/measure/status; фабрика — lazy closure. Семантика старта сохранена; экономия ~1с старта реальна.
- **`8a4c34fb` journal prealloc 64** — trim-семантика при переполнении не тронута; `copyBypass`: пустой список → nil, потребители смотрят только `len()`.
- **`b697ee03` guard nft** — `defaultBypassPrefixes` shared-slice read-only (все потребители только читают); `NftIngressRuleset` при `!AllowLAN` ведёт себя как раньше; byte-identical вывод покрыт дифф-тестами.
- **`c311ff75` sync hash-cache** — единственный писатель `storedDoc` — `Put` (считает hash сам, не доверяет `doc.Hash`); legacy-файлы без hash — fallback с декодом (тест `c0e66e7`); `List` через `storedMeta` — JSON-subset, семантика `Meta` та же.
- **`3177fb9d` sync transport in-place** — `readFrame` аллоцирует буфер на чанк, fast-path `ReadMsg` отдаёт владеемый слайс корректно; `wscratch` за `wmu` сериализован, рост в пределах cap (chunk 32K ≤ cap).
- **`ee6d07d0` probe** — freeze-window in-place shift эквивалентен append+trim (длина ≤ Max инвариант); `greaseInitial` — побайтовые офсеты сверены (DCID 8B @6..13, SCID len @14, token @15, length @16..17, PN @18); `banKey` — тот же формат `%d->%s`.
- **legacy `2c6b9de` parser** — `detect` vs `Detect` эквивалентен (bytes.TrimSpace == strings.TrimSpace для детекта; `hasPrefixFold` == ToLower-prefix; `:`-short-circuit в `decodeBase64` валиден — `:` нет ни в одном base64-алфавите; `q := u.Query()` однократно — те же значения); `parseList` cap — `p.limit()` guard на 0 сохранён.
- **Dart-оптимизаторы** (`fcb1fb1`, `1dcfbf7`, `4481a37`, `bc1522b`) — построчная сверка диффов: те же ветки, тот же порядок сортировки (memoized keys — та же математика; свежесть теперь зафиксирована на build-pass, что устраняет латентную неконсистентность); search — тот же предикат, перестраивается только список. Статически подтверждено; `flutter analyze` — за dev-машиной (тулчейна нет).

### B2. Известные красные тесты на чистом HEAD — перепроверены
- `TestRenderDNSH3UsesAddressForm` (singbox), `TestShadowsocksPluginSurvivesTheVault` (control) — падают на чистом HEAD, проходят с чужим незакоммиченным WIP (как писал OPTIMIZERS.md). Не трогал чужую работу; зафиксировано.
- `TestDetectCensorshipEventsWithoutOffsetsStayUnknown` — env-флейк (длина пути unix-сокета > 108 при длинном TMPDIR); с коротким TMPDIR не воспроизводится.
- `TestSaveSubscriptionOverridePreservesExtraRules` — в одном полном suite-прогоне под тяжёлой параллельной нагрузкой упал; изолированно и пакетом (`./control/`) — PASS дважды. Зафиксировано как флейк-под-нагрузкой, не регрессия; требует прогона на спокойной машине.
- `TestCapturedHello_ChromeParrotMatchesDocumented` (diagnostics) — в том же нагруженном прогоне: captured JA4 `t13d1713h2` vs documented Chrome 155 `t13d1516h2`. Изолированно и пакетом — PASS. Зафиксировано как флейк-под-нагрузкой; если воспроизведётся на спокойной машине — это сигнал о дрейфе паррота pseudo-version utls vs документированного Chrome 155, и тогда нужен не фикс теста, а сверка с реальным Chrome 155.

### B3. l10n — рассинхрона нет
- Все 32 arb-файла содержат все 661 ключ en (0 missing/extra); плейсхолдеры совпадают (ложные срабатывания — только вложенные plural-скобки в `expiresIn`); все 32 `strings_XX` класса реализуют все abstract-мемберы (кроме унаследованного `localeName` — by design); ключи роя (S11a: `updateVersionRevoked`, `updateRolloutPending`; F9 `connEmpty`; rollback-строки) — во всех локалях.

### B4. Пины и версии
- engines.lock ↔ catalog MinVersion ↔ fetch.sh — согласованы (sora: sing-box-lx 1.14.3-lx.14 / xray 26.3.27 / mihomo 1.19.32; legacy: upstream sing-box 1.14.3 / xray 26.3.27 / mihomo 1.19.32).
- utls: sora — `v1.8.3-0.20261006222701` (HelloChrome_Auto=155, S8); legacy — `v1.8.2` (Auto=133) — бамп невозможен без подъёма `go`-директивы до 1.27 (новая версия требует go≥1.27), а legacy CI жёстко ассертит `go1.26.9` (`legacy.yml:92`) и `go-win7`-история. **Оставлено как owner-решение (было Q9)** — правка отменена и откачена чисто.
- D08-поля `session_identity` / `dns_policy.block_private` — fail-closed держится (ошибки на месте); решение владельца pending.
- NOT-WIRED маркеры (tspu-wire) — честные, проверены выборочно; новых «молча не сшитых» полей после роя не найдено.
- `Updates/releases.json` feed URL — одинаков в коде и `docs/update-rollout.md`; cohort/parsing — fail-closed по таблице решений.

---

## C. Не закрыто / передано (не код, нужны решения или чужие зоны)

1. **utls-бамп легаси** (см. B4): `v1.8.2 → v1.8.3-0.20261006…` требует `go 1.27` в `core/go.mod` + правки CI (`legacy.yml` ассертит `go1.26.9`). Пока легаси светит Chrome 133 в obfs-dials. Owner-решение.
2. **Полноценный cert-pinning hy2** (P5/P7 — только fail-closed): `pinSHA256` принят де-факто стандартом hy2-ссылок; реализация требует поля плана + рендеров во все три движка + валидации. Задача уровнем выше.
3. **JA4-дрейф паррота** (см. B2): если `TestCapturedHello_ChromeParrotMatchesDocumented` воспроизведётся на спокойной машине — сверить pseudo-version utls с реальным Chrome 155, а не править тест.
4. **Legacy test flakes** (`session`/`tunroute`/`subscription` — netlink/caps в песочнице): изолированно проходят; suite под нагрузкой сыпал. Нужен спокойный прогон перед мержем.
5. **Dart `flutter analyze`** для P3 и всех dart-правок роя — тулчейна в среде нет (standing caveat).
6. **C#-проверка** не требовалась (C# не трогал).

---

## D. Коммиты прохода

sora (`bugfix/audit-2026-10-19`):
- `ad814efa` `[pass1-detail] mihomo: force client-fingerprint for REALITY outbounds (port of legacy af8d343)`
- `c35a9179` `[pass1-detail] control: plumb AmneziaWG 3.1 + masquerade keys through the vault (Q20)` *(temp-index CAS, только свои ханки)*
- `cac2cf87` `[pass1-detail] dart: DNS presets speak DoH instead of plaintext UDP (Q14)`
- `165082a4` `[pass1-detail] packaging docs: derive version from pubspec instead of stale 1.0.6 literals (Q7)`
- `d6e43be4` `[pass1-detail] parser: fail-closed on hy2 pinSHA256 links (pin never reached any engine)` *(temp-index CAS, только свои ханки)*

legacy (`bugfix/audit-2026-10-19`):
- `9bad6de` `[pass1-detail] xray: REALITY defaults to hellochrome_auto, not TSPU-flagged pinned chrome (D05 analog)`
- `9d48637` `[pass1-detail] parser: fail-closed on hy2 pinSHA256 links (pin never reached any engine)`

Все коммиты проверены `git show --stat HEAD` — только свои файлы. Инцидент: перед коммитом `cac2cf87` индекс держал чужие staged-удаления `core/control/plan*.go` (откат моего `c35a9179`) — снято `git restore --staged`, pathspec-коммит чистый.

*Отчёт прохода 1/3 — отдел мелких деталей, 2026-10-20. Пуша нет.*
