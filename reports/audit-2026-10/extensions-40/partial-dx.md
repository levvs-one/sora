# DX-зона расширений — итог (partial-dx)

**Статус: реализовано в файлах, НЕ закоммичено.** Ветка на ремонте у
координатора (два STOP-COMMITS за смену, HEAD скачет: 3bac79d → 26774d8
→ 73e3d8d за пару часов, деревья пересобираются). Коммитить запрещено до
сигнала «можно продолжать». **Вся работа зоны — только в worktree** (в
HEAD её нет: `git show HEAD:core/ext/manifest_v1ext.go` → «exists on
disk, but not in HEAD»). Ниже — инвентаризация и план коммитов.

**Организация работы.** Я — субагент глубины 2/2 (`can_spawn=no`):
породить 7 агентов физически не мог. Все 7 тем выполнил сам
последовательно, с границами модулей как при распределении (таблица
ниже — кому что досталось бы). Пересечений нет: каждый артефакт имеет
одного владельца.

| # | Тема | Артефакты |
|---|------|-----------|
| 1 | CLI `sora-ext` | `tools/sora-ext/cmd/sora-ext/`, `internal/{pack,keyutil}` |
| 2 | JSON Schema + дружелюбные ошибки | `tools/sora-ext/schema/`, `internal/validate/` |
| 3 | TypeScript-определения | `tools/sora-ext/templates/shared/sora-ext.d.ts` |
| 4 | Примеры ×3 | `examples/theme-midnight|net-hook-dpi|routing-split/` |
| 5 | Документация | `docs/extensions-{quickstart,api,cookbook,devmode}.md`, `extensions.md §8` |
| 6 | Dev-режим | `sora-ext dev` (CLI) + спека app-контракта |
| 7 | Песочница тестов | `sora-ext serve`, `tools/sora-ext/mock/sora-ext-mock.js` |

Плюс фундамент, без которого темы 1/4 не собирались: contract pointers
`theme`/`network_hook`/`routing` в `core/ext/manifest_v1ext.go` + Dart-зеркало.

## Внедрено (файлы)

### T1. CLI `sora-ext` — `tools/sora-ext/` (own Go module, `replace` на core)

`scaffold|validate|pack|sign|keygen|publish|dev|serve`, stdlib-only +
`core/ext`. Флаги можно ставить в любом порядке (`reorderArgs` — Go `flag`
молча глотал `--author` после позиционного аргумента; dogfooding поймал).
Exit codes: 0 ok, 1 usage/validation, 2 operational.

- `scaffold <id> --template panel|theme|nethook|routing|background` —
  проект + свежая keypair (`author.key` 0600, не коммитить) + `sora-ext.d.ts`
  рядом с кодом. Все 5 шаблонов прогнаны end-to-end: scaffold → validate →
  pack → sign → validate.
- `pack` — детерминированный-ish zip (mtime из `SOURCE_DATE_EPOCH`, иначе
  фикс. дата — шаг к reproducible builds), `checksums.txt` внутрь;
  `sign --key` дописывает `signature.minisig` через `ext.SignPayload`;
  `keygen` — minisign-совместимый формат (проверен: подпись верифицируется
  `ext.VerifyPackageSignature`).
- `publish` — pre-publish gate: validate чист, пакет подписан, dangerous
  permissions только с `--ack-dangerous`. Печатает sha256 и готовый
  JSON-сниппет catalog entry. Загрузки на сервер нет — честно: нечего
  загружать, каталог сабмитится отдельно.

### T2. Schema + человеческие ошибки

- `schema/manifest.schema.json` (draft 2020-12): мета-валиден,
  все 4 примера проходят, `net.fech` отвергается. Для редакторов (VS Code
  `json.schemas`).
- `internal/validate`: `ParseManifestFull` + позиционный индекс
  (токен-стрим → `file:line:col`), `did you mean` (Levenshtein) для
  permissions/capabilities/полей, таблица fix-hints. Пример:
  `error[unknown-permission]: unknown permission "net.fech"` →
  `sora-extension.json:17:5` + сниппет + `did you mean "net.fetch"?` +
  весь реестр. Каретка указывает на значение, не на ключ. Покрыто тестами
  (`validate_test.go`).

### T3. `sora-ext.d.ts`

Полные типы `window.soraExt` с JSDoc: 5 методов-перегрузок `call`,
`onEvent` → unsubscribe, `SoraExtError.code` (4 кода), события, лимиты
(`notify` 120/500). Строго по `bridge.dart` + `host.go` — ничего
выдуманного. Нашёл расхождение: реальный `onEvent` не возвращал
unsubscribe → поправил `bridge.dart` (3 строки, обратно совместимо), mock
и `.d.ts` консистентны.

### T4. Три примера (рабочие, подписанные, минимальные)

- `examples/theme-midnight/` — токены по спеке соседней зоны
  (`spec-theme-runtime.md`): `theme_version: 1`, `color.*`/`radius.card`/
  `font.scale`, `dark.tokens`. Пары onX/X проверены на WCAG AA
  (9.36/16.38/6.42). CSS нет — по спеке это executable surface.
- `examples/net-hook-dpi/` — L1 fragments по `spec-net-hooks.md`
  (`hook_version: 1`, `engine_fragments[]` для sing-box/xray).
- `examples/routing-split/` — по `spec-routing-hooks.md` (`routing.json`,
  `routing_version: 1`, `id`/`priority`, без `0.0.0.0/0`).

Каждый: `sora-extension.json` + README с честным статус-баннером +
`checksums.txt` + `signature.minisig` + `.soraext` (layout как у
hello-panel). Ключи throwaway, секреты не коммичены. Манифесты переподписаны
свежими ключами после выравнивания под спеки.

ВАЖНО: изначально примеры шли с моим выдуманным «contract v0»
(css_variables, strategies, rules.json). После обнаружения спек соседних
зон (`spec-{theme-runtime,net-hooks,routing-hooks}.md`) — полностью
переписаны под них. Дублирующих контрактов больше нет.

### T5. Документация (English, как `extensions.md`)

- `docs/extensions-quickstart.md` — «первое расширение за 10 минут»
  (scaffold → dev/serve → validate → pack/sign/publish → install).
- `docs/extensions-api.md` — референс `window.soraExt`: методы,
  permissions, 4 кода ошибок, события, settings_schema, лимиты v1, таблица
  «planned».
- `docs/extensions-cookbook.md` — 8 рецептов (settings, notify on
  disconnect, background worker + net.fetch, тест-матрица панели,
  publish-чеклист…).
- `docs/extensions-devmode.md` — CLI + спека app-контракта.
- `docs/extensions.md`: шапка-ссылки на гайды + новый §8 (контракты
  theme/network_hook/routing). `docs/README.md`: индекс.

### T6. Dev-режим — `sora-ext dev`

Файловый вотчер (500ms poll, без зависимостей), live reload через SSE,
перевалидация на каждое сохранение (ошибки не убивают сервер), serve
строго на 127.0.0.1. App-сторона — спека в `extensions-devmode.md`
(Connect dev server: только loopback, тот же permission prompt, тот же
токен, DEV-бейдж, нет автостарта, выпилено из release-сборок).
Dart-реализации нет — нет SDK в этом окружении, честно зафиксировано.

### T7. Песочница — `sora-ext serve` + mock

Статик-сервер инжектит `mock/sora-ext-mock.js` в HTML: точная семантика
хоста (permission enforcement по манифесту, валидация `notify`/`setSettings`
по `settings_schema`), фикстуры (`--fixtures`), `POST /__soraext__/event`
для событий, `GET /__soraext__/calls` — лог вызовов. Панель тестируется в
десктопном браузере без приложения. Дым-тест: инжект, mock.js, event 204,
calls `[]` — ок.

### Фундамент: contract pointers

`core/ext/manifest_v1ext.go`: `theme`/`network_hook`/`routing` —
strip-before-frozen-decoder (тот же паттерн, что `background_task`),
валидация entry (relative .json, no traversal) + cross-check
capability+permission, новые `errs.Key`. Замороженный `manifest.go` не
тронут. `app/lib/src/ext/manifest.dart`: зеркало (`_parseAssetRef`,
`_checkAssetRef`, `toJson`) — hand-read, без SDK. Тесты Go: 3 новых,
все 15 `TestParseManifestFull*` зелёные, весь пакет `core/ext` зелёный.

## Спеки (не код — осознанно)

1. **App-контракт dev mode** (`docs/extensions-devmode.md`): нужен Dart —
   нет SDK.
2. **Asset-контракты theme/net-hooks/routing**: принадлежат соседним
   зонам (`spec-theme-runtime.md`, `spec-net-hooks.md`,
   `spec-routing-hooks.md`) — мои примеры и шаблоны им следуют; движков
   нет ни у кого (все спеки).
3. **Загрузка в каталог** (`publish`): некуда загружать — gate без upload,
   честно.

## Отсеяно и почему

- **Интерактивные промпты в CLI** — ломают скрипты; всё флагами.
- **fsnotify-зависимость** — poll 500ms достаточно для dev-loop, ноль
  зависимостей.
- **Cobra и пр.** — stdlib `flag` + `reorderArgs` покрывает.
- **Remote dev servers** (не loopback) — приложение, исполняющее чужой JS
  с правами расширения: угроза не стоит удобства.
- **Авто-реконнект dev-расширений** — не должны тихо переживать рестарт.
- **Валидация asset-содержимого в Go** (токены темы и т.д.) — контракт
  соседних зон, их движки будут валидировать; указатель проверяет путь +
  права.
- **Собственный формат контрактов** (первая итерация примеров) — убит в
  пользу спек соседних зон, чтобы не плодить два стандарта.

## Инциденты смены (честно)

1. **Конкурентный revert**: другой агент откатил мой `manifest_v1ext.go`
   посреди работы — переприменил, добавил тест-регрессию через /tmp-копию
   пакета (их `detail_test.go` тогда ломал сборку тестов).
2. **Два STOP-COMMITS**: ветку дважды ломали пустые деревья; repair делал
   `reset --hard` — снёс ВЕСЬ мой незакоммиченный worktree
   (`tools/sora-ext/`, примеры, доки). Восстановил всё из
   `stash@{0}^3` через `git archive` (read-only) + shell — 53 файла, затем
   доработал до актуального состояния. Потеряно: только секретные
   example-ключи из /tmp (перегенерированы, манифесты переподписаны).
3. **Сломанный repair-HEAD**: `core/ext/store.go` ссылался на пропавший
   `revoke.go` (чужой незакоммиченный файл) — восстановил его из того же
   сташа, сборка зелёная. Сам `revoke.go` — чужой код, не мой.
4. **core/go.mod bump 1.26.9 → 1.27** чужим агентом: мой модуль тоже
   поднял до `go 1.27` (тулчейн 1.27.0 доступен через auto).

## План коммитов (жду сигнала «можно продолжать»)

Все файлы — worktree-only. Коммитить — только по CAS-рецепту из AGENTS.md

1. `[ext] manifest: theme/network-hook/routing contract pointers` —
   `core/ext/manifest_v1ext.go`, `manifest_v1ext_test.go`,
   `app/lib/src/ext/manifest.dart` (Dart — hand-read, без SDK)
2. `[ext] sora-ext CLI: scaffold/validate/pack/sign/keygen/publish` —
   `tools/sora-ext/` (без dev/serve)
3. `[ext] sora-ext dev/serve + browser mock` — `cmd/sora-ext/devserve.go`,
   `internal/server/`, `mock/`
4. `[ext] extension DX docs: quickstart, API, cookbook, dev-mode` —
   `docs/extensions-*.md`, `extensions.md §8`, `docs/README.md`
5. `[ext] three new examples: theme, net-hook, routing` — `examples/*/`
6. `[ext] bridge: onEvent returns unsubscribe` —
   `app/lib/src/ext/bridge.dart` (Dart — hand-read)

Коммитить — только по CAS-рецепту из AGENTS.md (temp index
`/tmp/idx_extdx_<pid>`, `git update-ref` CAS), после проверки
`git diff` на чужеродные ханки. `revoke.go` не коммичу отдельно — он уже
в repair-HEAD? Нет: я восстановил его в worktree, в HEAD его нет
(проверить перед коммитом; если чужой агент его вернёт сам — убрать мой).

## Проверено

- `go build ./...` + `go vet ./...` + `go test ./...` в `tools/sora-ext`:
  зелёные.
- `go build` + `go test ./ext/` в `core`: зелёные (обход сломанного
  чужого `detail_test.go` больше не нужен — починили).
- Dogfood: 5/5 шаблонов scaffold → validate → pack → sign → validate;
  friendly errors (позиции, did-you-mean); `serve` (инжект мока, event,
  calls); `dev` (валидация при старте, live reload snippet).
- JSON Schema: мета-валиден (draft 2020-12), 4/4 манифестов проходят,
  негативный кейс отвергается.
- Dart: только вычитка, SDK нет — пометить для `flutter analyze` на
  dev-машине перед мержем.
