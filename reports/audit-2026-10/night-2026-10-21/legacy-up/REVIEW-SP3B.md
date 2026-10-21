# Ревью коммитов 61045d8 + 426422a — `[legacy-up] ss_plugin catalog + fail-closed gates (S5-SP3b)` и repair

Репозиторий: `sora-legacy`, ветка `bugfix/audit-2026-10-19`. Основание:
`REVIEW-SP3.md` (находки F1–F4, F6 по коммиту 428ace4). Ревью независимое:
отчёту исполнителя не доверял, все гейты и рендеры прогнаны заново своими
временными пробами (пробы удалены, временный worktree снят, деревья не тронуты).

**Фиксация эталона.** sora снова уехала: HEAD `88774340` (ветка
`bugfix/audit-2026-10-19`), рабочее дерево массово грязное (MM/D/?? по app и
core). Ключевой факт тот же, что в REVIEW-SP3: `core/engine/ss_plugin.go` в
sora — **untracked** (482 строки), гейты в catalog/validate/mihomo/singbox/xray
живут в MM-файлах рабочего дерева, в HEAD их нет. Сравнение ниже — по
фактическому состоянию **sora HEAD+worktree на момент ревью**, не по HEAD.

## Вердикты по находкам

| Находка | Вердикт |
|---|---|
| F1 (mihomo `obfs-local`→`obfs`, имена каталога, тест) | **ЗАКРЫТА** |
| F2 (gost-plugin в mihomo — общий кейс с v2ray-plugin) | **ЗАКРЫТА** |
| F3 (unknown/внешние плагины fail-closed во всех рендерах + валидация/селекшн) | **ЗАКРЫТА** |
| F4 (xray отказывает на plugin/obfs) | **ЗАКРЫТА** |
| F6 (постоянные тесты sing-box JSON→vault и xray-ветки) | **ЗАКРЫТА** |
| Repair 426422a | **ПОДТВЕРЖДЁН** по содержанию; одна gofmt-мелочь (см. §3) |

**Общий вердикт: ПРИНЯТЬ.** Все пять находок закрыты полностью, пробами
подтверждено отсутствие обходных путей; единственное замечание — лишняя
пустая строка, оставленная repair-коммитом (gofmt), на поведение не влияет.

## 1. F1–F4, F6 — проверки по пунктам

### Каталог (база для F1/F3)

`core/engine/ss_plugin.go` в legacy@61045d8 (516 строк) против untracked
эталона sora (482 строки): данные каталога извлечены программно и совпали
**полностью** — 7 плагинов, у каждого Name, MihomoName, Engines и схема Opts
(ключи, виды, порядок) идентичны:

| Плагин | MihomoName | Engines |
|---|---|---|
| obfs-local | obfs | sing-box, mihomo |
| v2ray-plugin | (то же) | sing-box, mihomo |
| gost-plugin | (то же) | mihomo |
| shadow-tls | shadow-tls | mihomo |
| restls-plugin | restls | mihomo |
| jls-plugin | jls | mihomo |
| kcptun | (то же) | mihomo |

Расхождения файлов — только адаптация, не данные: комментарии переписаны
под legacy («sora»→«the client», тег CENSOR-P4→SP3b, сняты конкретные пины
sing-box-lx/Xray из текста sora), локальный `validatePluginHost` вместо
отсутствующего в legacy `validateAWGDomain`, и сохранён предсуществующий
legacy-чек `ObfsParam` через `isDomain` (был в validate.go до SP3b).

### F1 — ЗАКРЫТА

Моя проба mihomo (`buildProxy`): `obfs-local` → `name="obfs"`,
`opts=map[host:example.com mode:tls]`; заодно все остальные переводы:
`restls-plugin`→`restls`, `jls-plugin`→`jls`, остальные — тождественно.
Sing-box, наоборот, рендерит `obfs-local` дословно (имя бинаря) — верно.
Тест SP3, пинивший неверное имя, **перевёрнут**: `TestBuildProxyShadowsocksPlugin`
теперь требует `px.SSPlugin == "obfs"`; добавлен `TestBuildProxyPluginNameTranslation`,
пинящий все 7 переводов и отказ на unknown.

### F2 — ЗАКРЫТА

`ssPluginOpts`: `case "v2ray-plugin", "gost-plugin"` — общий кейс, дословно
как в sora. Проба: `gost-plugin, "tls;host=example.com"` →
`map[host:example.com mode:websocket tls:true]` — байт-в-байт та форма, что
REVIEW-SP3 замеряла у sora (у legacy было `map[host tls:]`). Пинят
`TestSSPluginOptsGostShape` + два gost-кейса в таблице `TestSSPluginOpts`.

### F3 — ЗАКРЫТА (протащить не удалось ни одним путём)

Собственные пробы по всем трём рендерам + валидация + селекшн, плагины:
gost, shadow-tls, restls, jls, kcptun, `unknown-xyz`, а также алиасы
`obfs` (mihomo-написание как канонический ввод), `simple-obfs`, `v2ray`:

- **sing-box**: всё, что не несёт пинованный билд (gost/shadow-tls/restls/
  jls/kcptun/unknown/алиасы), отказано на рендере с именем плагина;
  рендерятся только obfs-local и v2ray-plugin, `plugin_opts` — в каноническом
  порядке схемы (`path=/ws;host=…;tls` → `tls;host=…;path=/ws`).
- **mihomo**: unknown и `obfs` отказаны в `buildProxy` («which mihomo does
  not implement») до вызова `ssPluginOpts`; несомые плагины рендерятся.
- **xray**: отказывает на любом плагине (см. F4).
- **Валидация плана** (`Outbound.Validate`→`validateShadowsocksPlugin`):
  unknown/алиасы — «unknown shadowsocks plugin» со списком известных;
  также пинятся opts без плагина, неизвестный/дублирующийся ключ опций,
  битые flag/host/path/mode, legacy-obfs режим/хост, инъекция `;` в
  obfs-host, плагин на не-SS протоколе.
- **Селекшн** (`Catalog.Missing`): матрица моей пробы по трём движкам ×
  11 имён — ровно колонка Engines каталога; legacy obfs «missing» только
  у xray.

Ни одного пути, где плагин молча теряется или рендерится битым, не осталось.

### F4 — ЗАКРЫТА

Проба xray: plugin (obfs-local / v2ray / gost / shadow-tls / unknown) и
legacy `Obfs=tls` — все отказаны: «which Xray does not implement:
refusing to render it unobfuscated», длина конфига 0. Голый SS рендерится
(1407 байт — тот размер, что REVIEW-SP3 мерила у молчаливого рендера;
теперь он выдаётся только для действительно голого outbound).

### F6 — ЗАКРЫТА

- `TestShadowsocksPluginSurvivesTheVaultFromSingBoxJSON` (control) —
  настоящий, не парсерный повтор: парсит sing-box JSON, требует
  `Format==FormatSingBox`, проверяет, что credential document несёт
  `"ss_plugin"` и **не** несёт сырого `"plugin":`, затем полная цепочка
  `parseCredential`→`applyCredential`→`engine.Outbound` с точным сравнением
  Plugin/PluginOpts.
- `TestRenderShadowsocksPluginFailClosed` (xray) — три отказных кейса
  (plugin / obfs-local plugin / legacy obfs) с проверкой обеих частей
  текста ошибки + положительный контроль: голый SS рендерится.
- Сверх F6 коммит добавил осмысленные тесты engine-уровня:
  `TestSSPluginSelectionMatrix`, `TestValidateShadowsocksPluginFailsClosed`
  (16 кейсов), `TestCanonicalSSPluginOpts`, `TestSecretsCoverPluginSecretValues`,
  singbox `TestRenderShadowsocksPluginFailClosed`/`TestRenderPluginOptsCanonicalOrder`.

## 2. Мои прогоны

Go: `PATH=$HOME/workspace/go/bin`, TMPDIR/GOCACHE в workspace. Прогоны — в
чистом detached-worktree на проверяемых коммитах (основное дерево legacy в
это время грязное от параллельной работы):

- На **426422a**: `go build ./...` ✅, `go vet ./...` ✅;
  `go test ./parser/ ./control/ ./engine/singbox/ ./engine/mihomo/ ./engine/xray/`
  — все ✅ (mihomo целиком зелёный: фейл из REVIEW-SP3 был закрыт раньше
  коммитом G1). `./engine/` — единственный FAIL
  `TestTunAndFakeIPAvoidLANAndEachOther` («fake-IP pool overlaps an existing
  interface»): **подтвердил предсуществование** — тот же фейл на чистом
  `b8ff202` (база до SP3b), это env-артефакт интерфейсов VM, не регрессия и
  по заданию не засчитывается.
- Именные SP3/SP3b тесты (16 шт., все пакеты) — все PASS.
- На **4f60852**: SP6-тесты своим коммитом — PASS (см. §3).
- На **HEAD 5c4190e**: та же картина — control/parser/singbox/mihomo/xray ✅,
  engine — только тот же env-фейл.

## 3. Repair-коммит 426422a — ПОДТВЕРЖДЁН, с одной мелочью

- `git diff b8ff202..426422a -- core/control/plan_internal_test.go` =
  **ровно +37 строк**: импорт `strings` + тест
  `TestShadowsocksPluginSurvivesTheVaultFromSingBoxJSON`. Ни одного
  идентификатора SP6 (`TestImportedBlobs*`, `TestXrayProfileReality*`,
  `TestBrokenHeadersFailClosed`, `importedPlan`) в файле на 426 нет.
- Ничего не потеряно: SP6-блок (helper `importedPlan` + 4 теста, 254 строки),
  вычищенный из файла, **побайтно идентичен** блоку, который коммит
  `4f60852` вернул тем же файлом; на 4f60852 все 4 SP6-теста + оба
  vault-теста зелёны.
- Контекст, делающий repair существенным, а не косметическим: в самом
  61045d8 чужие тесты висели **без своего кода** (код SP6 приземлился позже,
  в dc95212) — проверил: на чистом 61045d8 три из четырёх SP6-тестов падают.
  Repair + переприземление в 4f60852 — корректный forward-fix; состояния
  с 426422a и далее консистентны и зелёны.
- **Мелочь (gofmt):** удаление оставило после SP3b-теста двойную пустую
  строку — `gofmt -l` флажит `plan_internal_test.go` начиная с 426422a
  (на базе и на 61045d8 файл был чист) и до сих пор на HEAD. На build/vet
  не влияет. Отмечаю как единственный дефект repair: в рабочем дереве
  legacy на момент ревью эта строка уже удалена незакоммиченным изменением
  (чужая параллельная работа) — при ближайшем коммите файла уйдёт сама.

## 4. Мелочи: имена/комментарии vs эталон

- ✅ Гейки во всех пяти точках (catalog, validate, mihomo, singbox, xray)
  попунктно совпадают с sora HEAD+worktree — та же логика, те же тексты
  ошибок, отличаются только номера строк и теги комментариев
  (CENSOR-P4→SP3b).
- ✅ Комментарий «fail-closed on unknown plugins» у `ssPluginOpts`
  **теперь правда**: единственный прод-вызов `ssPluginOpts` — в
  `buildProxy` строкой ниже гейта (`SSPluginByName`/`SupportsSSPlugin`).
  Legacy при этом уточнила фразу эталона довеском «— buildProxy refuses a
  plugin the catalog does not carry on mihomo before this is called» —
  формулировка стала точнее, чем в sora, где та же фраза держится на том
  же гейте без пояснения.
- Нит без действия: текст ошибки sing-box «which needs a plugin binary
  **sora** does not ship» сохранён дословно из эталона. Продукт legacy —
  тот же sora-client (модуль `github.com/levvs-one/sora-client`), так что
  это паритет с эталоном, а не чужое имя; в самом `ss_plugin.go` legacy
  при этом аккуратно заменила «sora» на «the client» в комментариях.
- ✅ Бонус сверх находок, проверен по диффу: `Outbound.Secrets()` теперь
  регистрирует секретные значения опций (shadow-tls/restls/jls password,
  kcptun key) по отдельности — маскирование логов усилено, тест есть.
