# Ревью коммита 428ace4 — `[legacy-up] SIP002 ss_plugin end-to-end (S5-SP3)`

Репозиторий: `sora-legacy`, ветка `bugfix/audit-2026-10-19`. Эталон: `sora`
(та же ветка). Спека: `reports/seams/s5-mirrors-import-docs.md`, S5-SP3 и §4.
Ревью независимое: отчёту исполнителя не доверял, все звенья и пробы прогнаны
заново временными пробами в обоих репо (пробы удалены, деревья чисты).

## Вердикт: ПРИНЯТЬ С ЗАМЕЧАНИЯМИ

SP3 по тексту спеки портирован **полностью и корректно**: все звенья цепи на
месте, поведение на пробах §4 совпадает с sora на уровне парсера и sing-box,
тесты настоящие и зелёные, гигиена коммита чистая. Замечания — не к полноте
SP3, а к дрейфу эталона: в sora параллельно приземлился слой CENSOR-P4
(каталог `ss_plugin` + fail-closed гейты в рендерах), которого в legacy нет.
Из-за него сегодня остаются **пути молчаливой потери плагина на уровне
рендеров** (F1–F4 ниже). Рекомендация: принять SP3 как есть и завести
отдельный follow-up SP3b на порт каталога/гейтов sora, а не переделывать
этот коммит.

Важная оговорка про эталон: sora в момент ревью — движущаяся цель. Её HEAD
(2634e3e5) ссылается на `engine.SSPluginByName`, определение которого лежит
в *untracked* `core/engine/ss_plugin.go` рабочего дерева; в индексе sora при
этом staged-версии тех же рендеров со старой логикой (совпадающей с legacy).
Сравнение ниже — по фактическому состоянию sora HEAD+worktree на момент
ревью.

## 1. Полнота порта по звеньям — ПОЛНАЯ

| Звено | Состояние |
|---|---|
| parser, link combined (`plugin=name;opts`) | ✅ канонизация в `ss_plugin`/`ss_plugin_opts`, `plugin_opts` побеждает `;`-суффикс |
| parser, link split (`plugin` + `plugin_opts`/`plugin-opts`) | ✅ обе пробы, включая дефисный ключ |
| parser, JSON/SIP008 и sing-box JSON | ✅ `plugin`/`plugin_opts` → канонические ключи поверх generic-dump |
| plan `Plugin`/`PluginOpts` | ✅ поля + комментарий дословно как sora |
| `Outbound.Secrets()` | ✅ `PluginOpts` добавлен, позиция как в sora |
| control `credentialKeys` | ✅ оба ключа |
| control `credentialDocument` / `applyCredential` | ✅ оба направления |
| подписочный путь | ✅ `control/server.go` (import) зовёт тот же `credentialDocument` для каждого сервера — отдельного обхода нет |
| рендер sing-box | ✅ verbatim + приоритет над legacy obfs |
| рендер mihomo | ✅ plugin-путь есть (но см. F1–F3) |

Эмпирически (проба в `control`): документ vault для link / SIP008 /
sing-box JSON содержит `ss_plugin`/`ss_plugin_opts`; сырого ключа `"plugin":`
в документе **нет** ни в одном пути (`rawPluginKey=false` ×3). Сырой `plugin`
остаётся только в `Options` спеки, откуда в vault не копируется.

## 2. Паритет с sora — пробы §4 и рендеры

Парсер: 8/8 проб **байт-в-байт идентичны** в обоих репо (combined/split
v2ray-plugin, combined obfs-local, split с `plugin-opts`, без плагина,
SIP008, sing-box JSON, Clash YAML).

Рендеры (одинаковые планы в обоих репо):

| Случай | sing-box | mihomo | xray |
|---|---|---|---|
| v2ray-plugin `tls;host=…` | = | = | **≠ F4** |
| obfs-local `obfs=tls;obfs-host=…` | = | **≠ F1** | **≠ F4** |
| gost-plugin | **≠ F3** | **≠ F2** | — |
| unknown-xyz | **≠ F3** | **≠ F3** | — |
| shadow-tls | **≠ F3** | = | — |
| plugin поверх legacy Obfs | = приоритет плагина | = | — |
| legacy Obfs, пустой host | = `obfs=tls` | = | — |
| без плагина | = | = | = |

Проверка утверждений исполнителя:

- «Xray не рендерит плагин ни там, ни там» — **буквально верно, по сути
  неполно**: sora *отказывает* в рендере с ошибкой, legacy молча рендерит
  голый SS (проба: длина конфига 1407 байт — тождественна конфигу без
  плагина). См. F4.
- «Clash YAML канонизации нет в обоих» — **подтверждено пробой**: в обоих
  `ss_plugin=""`, сырой plugin лежит JSON-строкой, `plugin-opts` — JSON-блоб;
  до vault не доезжает ни там, ни там. См. F5.
- «Пустой `obfs-host=` не эмитится» — **подтверждено в обоих**: legacy-путь
  sing-box даёт `plugin_opts="obfs=tls"` при пустом ObfsParam.

## Находки по серьёзности

### F1 (High) — mihomo: `obfs-local` не переводится в `obfs`, плагин молча игнорируется

Legacy эмитит в mihomo `plugin: "obfs-local"` дословно (проба:
`plugin="obfs-local"`), sora переводит имя через каталог → `plugin="obfs"`.
По замеренному комментарию sora (`ss_plugin.go`, CENSOR-P4) адаптер mihomo
матчит только свои написания и **молча игнорирует** остальные — то есть
именно заглавный плагин проб §4 уезжает в mihomo без обфускации, при живом
UI-статусе «плагин есть». Тест коммита `TestBuildProxyShadowsocksPlugin`
пинит неверное дословное имя. Корень — дрейф эталона после спеки, лечить
follow-up'ом SP3b (порт `SSPluginByName`/`MihomoName`), тест при этом
придётся перевернуть.

### F2 (Medium) — mihomo: gost-plugin рендерится битой формой опций

Legacy `ssPluginOpts` ведёт gost-plugin через generic-passthrough: проба
дала `map[host:example.com tls:]` — нет обязательного `mode: websocket`, а
голый флаг `tls` стал пустой строкой вместо `true`. Sora обрабатывает
gost-plugin общим кейсом с v2ray-plugin: `map[host mode:websocket tls:true]`.

### F3 (Medium) — неизвестные/внешние плагины: legacy рендерит всё подряд, sora — fail-closed

Пробы: sing-box legacy дословно рендерит `gost-plugin`, `shadow-tls` и
`unknown-xyz`; sora отказывает по всем трём («needs a plugin binary sora
does not ship»). Mihomo legacy пропускает `unknown-xyz` в конфиг (где он,
по F1-логике адаптера, молча игнорируется); sora отказывает («which mihomo
does not implement»). Итог у legacy — обещание плагина без обфускации или
FATAL движка на старте вместо отказа на рендере.

### F4 (Medium) — xray: плагин и legacy Obfs молча теряются

Legacy `engine/xray/render.go`, ветка Shadowsocks, не смотрит ни `Plugin`,
ни `Obfs`: рендер успешно выдаёт обычный SS. Sora по обоим полям возвращает
ошибку «refusing to render it unobfuscated». Это ровно тот класс дефекта
(молчаливая потеря обфускации), ради которого заводился SP3, — на движке,
который спека прямо не называла, но пункт «нет ли пути, где плагин всё ещё
молча теряется» покрывает.

### F5 (Low, общий паритетный разрыв, не регрессия legacy) — Clash YAML

Плагин из Clash-SS-прокси (`plugin: obfs` + `plugin-opts:`) не канонизируется
ни в одном репо (см. §2). Теряется в обоих одинаково; фиксить симметрично
или фиксировать как известное ограничение в обоих.

### F6 (Low) — пробелы в постоянных тестах

Поведение проверено пробами, но постоянными тестами не запинено:
sing-box JSON → vault (парсерный уровень покрыт только расширением
`TestParseSIP008Document`); xray-ветка (пинить пока нечего — см. F4).

## 3. Тесты коммита и мои прогоны

Новые тесты покрывают разные звенья и не дублируют друг друга:

- `TestParseShadowsocksPlugin` (parser) — combined / split с приоритетом
  `plugin_opts` / obfs-local / без плагина. Шире эталонного теста sora
  (у sora нет obfs-local кейса).
- Расширение `TestParseSIP008Document` — плагин из SIP008 доезжает до
  канонических ключей.
- `TestShadowsocksPluginSurvivesTheVault` (control) — настоящее сквозное
  звено parser → `credentialDocument` → `parseCredential` → `applyCredential`
  → `engine.Outbound`, а не повтор парсерного.
- `TestRenderShadowsocksPlugin` (singbox) — verbatim+приоритет, пустой
  obfs-host не эмитится, host сохраняется, явный obfs-local verbatim.
- `TestSSPluginOpts` + `TestBuildProxyShadowsocksPlugin` (mihomo) —
  трансляция опций таблицей (6 кейсов, включая unknown-passthrough и пустые
  opts) и приоритет плагина над native obfs на уровне proxy-структуры.
  Оговорка: второй пинит поведение F1.

Мои прогоны (Go: `PATH=$HOME/workspace/go/bin`, TMPDIR/GOCACHE в workspace):

- `go build ./...` — ✅ чисто; `go vet ./...` — ✅ чисто.
- `go test ./parser/ ./control/ ./engine/singbox/ ./engine/mihomo/ -count=1`:
  parser ✅, control ✅, singbox ✅; mihomo — единственный FAIL
  `TestRenderRealityForcesAClientFingerprint`.
- Предсуществование подтверждено: тот же тест с тем же сообщением падает на
  чистом архиве `HEAD~1` (без коммита), и это единственный фейл пакета там и
  там. Не регрессия 428ace4, против коммита не засчитывается.

## 4. Гигиена коммита

- Ровно 11 файлов, +353/−23, все строго по SP3 (parser, control, engine
  plan/validate, singbox, mihomo + их тесты). Посторонних правок нет.
- Стиль и комментарии — по эталону, местами дословно (см. «Мелочи»).
- Адаптивная ОС-интеграция: коммит трогает только платформенно-нейтральное
  Go-ядро — ни одного `GOOS`/`runtime`-предположения, ни одного нового
  пользовательского текста; сырого технического текста пользователю не
  добавляет. Напротив, `PluginOpts` в `Secrets()` улучшает маскирование в
  логах.

## Мелочи

### (а) Имена и комментарии — один термин, одно имя

- ✅ Поля `Plugin`/`PluginOpts` и их комментарий в `engine/plan.go` —
  дословно как в sora; поля `SSPlugin`/`SSPluginOpts` и комментарий в
  `mihomo/config.go` — дословно как в sora; канонические ключи
  `ss_plugin`/`ss_plugin_opts`, функция `ssPluginOpts`, имя теста
  `TestParseShadowsocksPlugin` — совпадают с эталоном.
- ✅ Комментарий в `control/plan.go` аккуратно адаптирован из sora:
  висячая ссылка на тикет `(T020)` из sora **не** скопирована (в legacy
  такого реестра нет), добавлена точная фраза про vault. Комментарий
  соответствует коду legacy.
- ✅ Комментарий JSON-пути («DisplayName already comes from "remarks" via
  mapJSONSpec») соответствует именно legacy-коду, где `mapJSONSpec` сам
  читает remarks, — расхождение с комментарием sora здесь правильное,
  а не дрейф.
- ⚠️ Единственное реальное расхождение комментарий↔код: doc-комментарий
  `ssPluginOpts` скопирован из sora дословно, включая «mihomo validates it
  (fail-closed on unknown plugins)». В legacy ничего не валидирует —
  гейта перед вызовом нет, фраза описывает несуществующее поведение
  (текстовый след F3). В sora та же фраза подкреплена гейтом в
  `buildProxy`. При SP3b комментарий либо подкрепить гейтом, либо
  переписать.
- Нит без действия: комментарий и тест в control говорят «vault», а
  doc-комментарии того же файла — «credential document». Термин «vault»
  не введён этим коммитом (прецедент — существующий
  `TestRealityAndTransportSurviveTheVault` и одноимённые тесты sora),
  зафиксировано для порядка, правки не требует.

### (б) Тексты ошибок и подсказок

- Коммит не добавляет **ни одной** новой строки ошибки (проверено по диффу:
  ни `fmt.Errorf`, ни `errs.New*`) — дрейфа стиля и сырого жаргона в
  пользовательских/логовых текстах коммит не вносит по построению.
- Обратная сторона: fail-closed текстов, существующих в нынешней sora
  («uses plugin %q, which mihomo does not implement», «refusing to render
  it unobfuscated», «needs a plugin binary sora does not ship»), в legacy
  нет — но это содержание F3/F4, а не дефект стиля. Стиль этих текстов
  sora (префикс движка, имя outbound, имя плагина) совместим с существующим
  стилем legacy (ср. xray hy2: «which Sora does not render for Xray» —
  предсуществующий текст, коммитом не тронут).
- Пользовательских строк в коммите нет вообще: ни Dart, ни l10n, ни
  `errs.Key*`; имена плагинов попадают только в конфиги движков.

### UI-пункты стандарта

Неприменимы к Go-порту (табуляция, мнемоники, трей, DPI в коммите
отсутствуют как класс) — проверок по ним не выдумывал.
