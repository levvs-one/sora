# Отдел расширений sora — итог 40-агентной волны (EXTENSIONS-40)

Дата: 2026-10-20. Ветка `bugfix/audit-2026-10-19`, пуша нет (по требованию владельца).
Сводный отчёт лида отдела. Частичные отчёты зон: `reports/extensions-40/partial-{runtime,security,store,ui,dx}.md`.

## 0. Организация

Задача ставила 40 агентов в 5 зонах (Runtime 10, Security 8, Store 8, DX 7, UI 7).
Физическое ограничение: лиды зон — субагенты depth 2/2 (`can_spawn=no`), породить
подагентов технически невозможно. Все 5 лидов отработали свои зоны лично,
последовательно, как набор workstream'ов с жёсткими границами модулей.
Пересечений нет; места совместной работы со смежными отделами помечены в
частичных отчётах, двойного учёта заслуг нет.

Критерии качества владельца применены везде: безупречное качество без
компромиссов, продуманность до мелочей, оптимизация, честность (никакого театра
безопасности), минимализм, удобство и скорость, ноль слопа. Каждое решение —
через фильтр «лучшее или слоп».

## 1. Внедрено — в истории (коммиты)

### Базовый задел (волна 3 + смежные отделы, было до волны-40)
- `7413d53` manifest v1, minisign-verify, `.soraext` lifecycle, каталог, ExtensionHost
- `98d299b` docs + пример hello-panel; `4452141` store UI; `499c850` честный catalog-soon;
  `f3395bf` wiring ExtensionHost в sora-core
- `2551170` [swarm] background workers + net.fetch
- `10396ca` [swarm-review] ext v2 Go: redacted query, IP-like host rejection, task lifecycle
- `0562a88`/`62e8623` [power-run] ext honesty/security
- `2adbe6a` [detail-fix] token scope enforced at mint

### Волна-40, Runtime (код попал в историю через repair-forward-fix `26774d8`;
### оригинальный коммит `2767517` заброшен — см. §6)
- `core/ext/worker.go`: overlap guard (atomic.Bool — пропуск тика с warn вместо
  лавины горутин) + circuit breaker (10 подряд падений → Unregister до рестарта app).
  Тесты: overlap skip, breaker trip, counter reset. `go test -race` зелёный.
- `core/ext/netfetch.go`: `NewFetcherForExtensionWithTransport` — шов туннельного
  транспорта (прод обязан вести через VPN; `nil` = direct только для тестов),
  `Scheduler.SetFetchTransport`, `Fetcher.Stats()` (запросы/отказы/байты).
  Per-call permission-check отсеян как театр: гейт на конструировании + отзыв при disable.
- `app/lib/src/ui/extensions/panel_screen.dart`: **CSP `connect-src 'none'` на каждый
  ответ loopback-сервера** — закрыта дыра POWER-RUN (fetch у панелей = эксфильтрация
  одним запросом). Дополняет meta-CSP при распаковке. Аудит loopback/навигации/моста —
  без дыр; исправлен doc-drift в `bridge.dart`.

### Волна-40, Security — `a7f63e8` (мой re-land по CAS; оригинал `977163c` заброшен ремонтом)
9 новых файлов, 1185 insertions. `go build`/`go vet`/`go test ./ext/` — зелёные.
- `revoke.go`: signed revocation list (team key, fail-closed до key ceremony),
  enforcement в Install/SetEnabled, честная офлайн-политика (без театра).
  **Этот коммит починил красный HEAD** (store.go ссылался на RevocationList).
- `sideload.go`: факты для честного экрана согласия (fingerprint ключа автора,
  конкретные последствия пермишенов, self-attested варнинг).
- Token TTL 24h + expiry sweep; zip-hardening (`\` и `:` отвергаются — Windows ADS);
  permission matrix test; manifest fuzz seeds (742k execs у автора, 0 находок).
- `docs/extensions/threat-model.md`: активы, акторы, границы, матрица enforcement
  (честно: реально проверяются 5/12 пермишенов; `routing.rules`/`net.hooks` —
  RiskDangerous с нулём кода проверок — зафиксировано как долг),
  аудит секретов (доказано кодом: расширения никогда не видят секреты подписок —
  инвариант), остаточные риски §9.
- Подключён висячий хук `GrantedPermissions` в `main.go` (ядро не минтит токены
  для disabled/негрантед).

### Волна-40, Store (в истории)
- `a971a20` каталог: max_age + офлайн-кэш + staged rollout + screenshots/changelog/capabilities
- `b8b5f23` честная методология рейтинга (байесовское среднее m0=3.0/C=12,
  затухание свежести half-life 180д, дедуплика «1 аккаунт = 1 голос», RankScore)
- `57b74a4` l10n-ключи store UX; `14b71a5` фикс тройного объявления extCapBackground

## 2. Внедрено — worktree-only (код готов, коммиты ждут стабилизации ветки)

Всё ниже — в рабочем дереве, с бэкапами вне репозитория. Не коммитилось из-за
инцидентов ветки (§6). У каждого лида готов план CAS-коммитов.

### Store (бэкап `reports/extensions-40/wip-backup/`, 7 файлов)
- `core/ext/ratings.go` + тесты: байесовский рейтинг, затухание, анти-накрутка.
- `core/ext/catalog.go`: `CatalogCache` (Store/Load/Refresh/Fresh), `rollout_fraction`
  + детерминированный бакет `sha256(install_id|id|version)`, screenshots/changelog/capabilities.
- Dart: `ext/catalog.dart` (зеркало + `rolloutEligible`, точное совпадение с Go),
  `ext/store.dart` (`installId`), `ui/extensions/store_screen.dart` (фильтры
  capabilities, сортировка «Релевантность», **отменяемая загрузка**, баннер кэша,
  rollout-gating), `detail_screen.dart` (карусель скриншотов, changelog, диалог
  методологии рейтинга), `widgets.dart` (`showRatingHowDialog`).

### UI (снапшоты `reports/extensions-40/files/`, 7 файлов + `add_l10n_keys.py`)
- Менеджер: поиск по установленным, «Обновить все» с честным счётчиком успехов,
  Semantics-label у Switch, бейдж «есть настройки».
- Permissions-экран: 3 честных состояния промпта (fresh/widening/removal-only —
  исправлен баг титула «Install»), блок dropped permissions, 3 тира риска
  (normal/sensitive/dangerous) с озвучкой для скринридера, changelog в промпте.
- Обновления: `_installBytes → Future<bool>` (отмена ≠ успех), честная ошибка
  `extUpdateFailedKept` («предыдущая версия осталась»).
- **Конфликты расширений (новое)**: `ext/conflicts.dart` (детекция по
  routing.rules/theme.apply/net.hooks), `conflicts.json` (атомарно),
  `conflicts_sheet.dart` (шит разрешения с радиорядами), баннер над списком.
- Перф: мемоизация `_filtered()`, исправлен in-place sort каталога.
- A11y: Semantics-узлы, чипы 36→40, ноль хардкод-красного (grep по Colors.red чист).
- 19 новых l10n-ключей (en+ru+28 фолбэков), всё через `S.of`.

### DX (worktree: `tools/sora-ext/`, `examples/*`, `docs/extensions-*.md`)
- **CLI `sora-ext`** (own Go module, stdlib-only): scaffold (5 шаблонов) / validate /
  pack / sign / keygen / publish (pre-publish gate: подпись + `--ack-dangerous`) /
  dev / serve. Exit codes 0/1/2. Dogfooding поймал и исправил 4 бага.
- JSON Schema (draft 2020-12) + валидатор с человеческими ошибками
  (`file:line:col` + сниппет + `did you mean "net.fetch"?` + fix-hints).
- `sora-ext.d.ts`: полные типы `window.soraExt` с JSDoc, строго по bridge.dart/host.go.
  Найдено расхождение `onEvent` без unsubscribe — исправлено в `bridge.dart`.
- 3 примера (`theme-midnight`, `net-hook-dpi`, `routing-split`): рабочие, подписанные,
  переписаны под спеки соседних зон (двух стандартов нет).
- Доки: quickstart «10 минут», API-референс, cookbook (8 рецептов), devmode-гайд.
- Dev-режим: `sora-ext dev` (watch 500ms, SSE live reload, строго 127.0.0.1) + спека
  app-контракта. Песочница: `sora-ext serve` + mock с permission enforcement.
- Фундамент: contract pointers `theme`/`network_hook`/`routing` в
  `manifest_v1ext.go` (frozen `manifest.go` не тронут) + Dart-зеркало.

## 3. Спеки (спроектировано — код следующим шагом)

Runtime (`reports/extensions-40/spec-*.md`): theme-runtime (темы как данные,
allowlist, WCAG-контраст), routing-hooks (декларативный routing.json,
приоритет пользователь > расширения), net-hooks (L1 фрагменты конфига движка +
L2 observer с дедлайном 50мс), quotas (честные границы, wall-time вотчдоги),
crash-isolation (супервизия за ОС, политика рестартов), event-bus (backpressure,
семантика переподписки).
Store (`reports/extensions-40/specs/`): review-queue (SLA 5/3/1, апелляция),
badges-policy (критерии-числа, запрет платного продвижения), abuse-handling
(триаж за часы → revocation → публичный лог), ratings-methodology, catalog-ops.
DX: app-контракт dev mode (`docs/extensions-devmode.md`).
UI: S5-enforcement (Go-core читает `conflicts.json`, применяет победителя —
**handoff в Go-core зону**, контракт ключа стабилен).

## 4. Отсеяно фильтром «лучшее или слоп»

**Runtime:** per-call permission-аргумент в fetch (театр — проверяющий и
проверяемый один); произвольный CSS тем (`url()` → exfiltration); код расширений
на горячем пути трафика (только декларативные данные); псевдоточный CPU-аккаунтинг
и cgroup-лимиты; отдельный супервизор расширений; exactly-once/replay событий;
полный `script-src` lockdown панелей (сломал бы легитимные инлайн-скрипты —
`connect-src 'none'` закрывает именно дыру).
**Security:** permission на чтение секретов (инвариант «никогда» сильнее);
constant-time sha256 в Verify (не сравнение секрета); блокировка установок без
revocation list (сломало бы first-run); удаление протухших при офлайне (театр);
expiry в MintTokenResponse (перегенерация proto ради ничего).
**Store:** кнопка «Пожаловаться» без бэкенда (фейк); подборки-коллекции и
вкусовой staff pick (заменены формулой `top`); платное продвижение и ускорение
ревью (убивает доверие — запрещено спеком); фильтрация листинга по rollout
(нечестно прятать опубликованное); тихое удаление отозванного (только
автоотключение, удаляет пользователь).
**UI:** настройки settingsSchema прямо в карточке (теснота/рассинхрон — оставлен
бейдж + форма в detail); changelog в манифесте (два источника правды);
in-panel переключатель (конфликт писателей); debounce поиска (лаг без выгоды);
авто-предложение отката после неудачного апдейта (старая версия и так активна).
**DX:** интерактивные промпты CLI (ломают скрипты); fsnotify (poll достаточно);
Cobra (stdlib покрывает); remote dev servers (угроза); авто-реконнект
dev-расширений; Go-валидация содержимого ассетов (контракт соседних зон);
собственный формат контрактов v0 (убит в пользу спек соседних зон).

## 5. Волна 4 из плана — покрытие

| Пункт волны 4 | Статус |
|---|---|
| background workers | В истории: lifecycle (overlap guard, circuit breaker), планировщик |
| `net.fetch` с пермишенами | В истории: permission-gate на конструировании, туннельный транспорт, stats |
| theme runtime | Спека `spec-theme-runtime.md` + contract pointer + пример theme-midnight |
| routing hooks | Спека `spec-routing-hooks.md` + contract pointer + пример routing-split |
| net-hook runtime | Спека `spec-net-hooks.md` + contract pointer + пример net-hook-dpi |
| агрегированные звёзды/рейтинги | В истории (методология) + worktree (ratings.go с тестами) |
| revocation list | В истории (`a7f63e8`): формат, подпись, enforcement, офлайн-политика |

## 6. Инциденты ветки (честно, для родителя)

Ветку трижды ломало пустыми деревьями: `2767517` (runtime-лид: `$$` сменился
между двумя вызовами шелла — урок: весь CAS-рецепт в одном вызове), затем
`3b45d28`/`2517723`/`de2b254`, затем рецидив `cc38c4f` (0 файлов) + `cf15b7b`
(1 файл). Чинилось reset'ами (`1483f57`, `26774d8`) с переприменением честных
коммитов. Дополнительно: `git clean` во время ремонтов сносил untracked-файлы
трёх зон — восстановлены из снапшотов/сташа (потери: только throwaway-ключи
примеров, перегенерированы). Уроки занесены в `~/AGENTS.md` (уникальные
temp-index имена, CAS через `update-ref`, рецепт в одном вызове).
`stash@{0}` (94f9e30) и `stash@{1}` (26774d8) хранят чужие WIP — **не дропать
без разбора**.

## 7. Блокеры и handoff'ы

**Владелец:** key ceremony (team key — блокер подписанного каталога и
revocation list; всё fail-closed до неё); `flutter analyze` + ручной тест
панелей/permission-промптов/конфликтов на dev-машине (Dart без SDK — только
вычитка); `extOpenPanel` (l10n-ключ без использования) — удалить или оставить.
**Координация:** S5-enforcement (применение победителя конфликтов) — handoff в
Go-core зону, контракт `kind:sorted_ids` стабилен; D42 proto stubs (`cc38c4f`) —
потеряны, владельцу перекоммитить из своего дерева при нужде; worktree-only код
Store/UI/DX (§2) — коммитить CAS-рецептом после стабилизации ветки (планы у лидов).
**Проверено лидом:** `go build ./...`, `go vet ./ext/`, `go test -count=1 ./ext/` —
зелёные на HEAD `a7f63e8` (1295 файлов, дерево полное).
