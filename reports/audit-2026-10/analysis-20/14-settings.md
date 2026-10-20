# Аналитик №14: настройки (settings / config / persistence / migrations / F5 / F6)

Repo: `~/workspace/bug-hunt/sora`, ветка `bugfix/audit-2026-10-19`. Read-only анализ.
Охват: `app/lib/src/settings.dart`, `app/lib/src/ui/settings_screen.dart`, `app/lib/src/ui/modes.dart`,
`app/lib/src/ui/obfs.dart`, `app/lib/src/obfs.dart`, `app/lib/src/overrides.dart`, `app/lib/src/profiles.dart`,
`app/lib/src/sora.dart` (план/apply), `core/control/override.go`, `core/control/profiles.go`,
`core/profiles/profiles.go`, `core/control/plan.go`, `proto/sora/core/v1/core_control.proto`.

---

## Вердикт

Модель настроек в целом аккуратная: единый `Settings` с allow-list кэша, дефолты безопасные,
валидация в UI на месте, JSON-сторы парсятся защитно. **Но зона F5/F6 — архитектурный провал:**
две параллельные реализации персистентности (Dart-сторы vs Go-RPC + Go-сторы), из которых
живая только одна, а вторая — полностью написанный, оттестированный, но мёртвый код с
расходящимся контрактом. Плюс две конкурирующие системы фрагментации TLS с двумя тогглами
«Фрагментация» в разных экранах. Это не баги в коде — это слоп в архитектуре: каждая
фича реализована дважды, и ни одна из пар не состыкована.

Честная оговорка: в ходе анализа я сначала зафиксировал «баг» (ключ `autoSwitchOnDegrade`
якобы отсутствует в `_keys` и не персистится) — перепроверка по файлу показала, что ключ
на месте (`settings.dart:49`). Находка отозвана; в отчёт не входит. Остальное проверено
прямым чтением кода.

---

## Сильные стороны

- **Allow-list кэша полный и честный.** `Settings._keys` (`settings.dart:17–60`) покрывает все
  используемые ключи (проверено скриптом по всем `_store.get*/set*`); `SharedPreferencesWithCache`
  с allow-list — правильная дисциплина против гонок чтения.
- **Дефолты безопасны там, где важно.** `killSwitch` — `false` (`settings.dart:116`): fail-open
  по умолчанию, opt-in через диалог режимов (`modes.dart:262`), перевооружение per-session и
  повторная установка после каждого connect (`sora.dart:1207`, `setKillSwitch` at `1331`).
  `connectOnStart=false`, `zapretWithVpn=false`, `controlPort=false`, `fragment=false`,
  обфускация `preset=off` (`obfs.dart:746`). Правильно: ничего опасного не включается само.
- **Защитный парсинг JSON-сторов везде:** `OverrideStore` (`overrides.dart:60–76`),
  `ProfilesStore` (`profiles.dart:110–127`), `ObfsSettings._load` (`obfs.dart:756–772`) —
  повреждённый JSON даёт пустое состояние, а не падение.
- **UI-валидация до сохранения:** regex для `fragmentPackets`/`fragmentLength`/`fragmentInterval`
  (`settings_screen.dart:41–43`), `splitPos` (`_position`), `probeUrl` (`_web`),
  резолверы DNS (`dns.dart:52`). Комментарий «Match core validation» — честная сверка с ядром.
- **Ядро валидирует план на входе:** неизвестный пресет (`core/routing/presets.go:95`),
  «selecting a stack requires TUN mode», local-proxy auth (`core/control/plan.go:207–224`),
  лимиты outbounds/rules (`plan.go:174–185`).
- **Go-валидация сетевых профилей тщательная** (`core/profiles/profiles.go:270–320`: имя, id-charset,
  лимиты триггеров, gateway как IP-адрес, mode ∈ {tun,proxy}, engine из белого списка) —
  жаль только, что она не используется (см. P0).
- **Undo-снапшот при применении профиля** (`sora.dart:1005+`), `proxySnapshot` переживает
  `reset()` (`settings.dart:327–341`) — продуманное восстановление после краша.
- **Семантика матчинга профилей совпадает** в обеих реализациях (AND групп, `profiles.dart:56–65`
  vs `core/profiles/profiles.go:97–110`) — дублирование хотя бы не врёт.

---

## Слоп / проблемы

### P0 — F5/F6 реализованы дважды; живая только Dart-сторона, Go-сторона мертва

**Файлы:**
- `app/lib/src/overrides.dart:1–12` — docstring: «Stored locally in settings (`subscriptionOverrides`)
  **until the core implements the SaveSubscriptionOverride/GetSubscriptionOverride RPCs**».
- `app/lib/src/profiles.dart:1–13` — «The Go core owns trigger matching… **until the core sync lands**».
- `core/control/override.go` — RPC `SaveSubscriptionOverride`/`GetSubscriptionOverride` полностью реализованы.
- `core/control/profiles.go`, `core/profiles/profiles.go` — RPC `ListProfiles`/`SaveProfile`/`DeleteProfile`/
  `GetNetworkFingerprint`, файловый стор, эмит `ProfileMatched` (`core/control/server.go:866`).

**Факты:**
1. В Dart-коде **ноль** вызовов этих RPC (grep по `saveSubscriptionOverride|getSubscriptionOverride|listProfiles|saveProfile|deleteProfile|getNetworkFingerprint` в `app/lib` — пусто).
2. UI целиком сидит на локальных сторах: `sora.overrides` (`ui/subscription.dart:187,264,283`,
   `ui/servers.dart:262`), `sora.profiles` (`ui/profiles.dart:64,272`, `settings_screen.dart`).
3. `Sora.refreshFingerprint()` — заглушка с `TODO(core)` (`sora.dart:1058–1070`): фингерпринт всегда
   unknown, `handleProfileMatched` кормится только локальным матчером.
4. Docstring'и врут: core RPC **уже** реализованы (коммиты волн), «миграция» не случилась —
   теперь это два источника правды. Core при фоновом рефреше подписок применяет **свои**
   (пустые) оверрайды (`applySubscriptionOverride` в `subscriptionBook.state`), а пользовательские
   rename/hidden живут только в плане, который строит приложение. Любой core-driven UI
   (уведомления с именами серверов и т.п.) их не увидит.
5. Логика фильтрации дублирована: `applySubscriptionOverride` (Go, hidden/renames/pinned,
   `override.go:21–77`) vs Dart-фильтрация в построении списков — два места для одного
   преобразования, разъедутся при первой же правке семантики.
6. **Контракт уже разъехался по именам:** Go wire `ProfileApply{Mode, Dns, RulesPreset, ServerId, Engine}`
   (`profiles.go:39–56`) vs Dart `NetworkProfile{tunnel, preset, dns, dnsPreset, serverId, engine}`
   (`profiles.dart:36–48`). `tunnel`↔`Mode`, `preset`↔`RulesPreset`, а `dnsPreset` в Go-контракте
   вообще отсутствует. Будущий «sync» без переписывания невозможен — поля не маппятся 1:1.

Это самый крупный слоп в зоне: сотни строк Go-кода + тесты (`override_test.go`, `profiles_test.go`,
`profiles_rpc_test.go`, `contract_test.go`) обслуживают API, которое никто не вызывает.

### P1 — Две конкурирующие системы фрагментации TLS

- **Legacy:** `settings.fragment/fragmentPackets/fragmentLength/fragmentInterval`
  (`settings.dart:130–137`) → `SessionPlan.antiCensorship` (`sora.dart:1901–1906`) → `engine.Fragment`
  (`core/control/plan.go:190`). UI: Settings → Соединение → «Фрагментация TLS»
  (`ui/settings_screen.dart:294–325`).
- **Obfs-suite:** `settings.obfs` JSON `{preset, utls, fragment, jitter}` (`settings.dart:294–296`,
  `obfs.dart:736–810`) → `ObfsControl.ApplyObfsProfile` → «core merges it into the engine plan»
  (`sora.dart:417–430`). UI: Modes → Обфускация → «Фрагментация» (`ui/obfs.dart:209–216`).

Два тоггла с одним именем в разных экранах, два разных пути в один движок. Что происходит при
одновременном включении обоих — из кода не следует (core «мержит» obfs-профиль поверх плана,
где уже лежит legacy `Fragment`). Пользователь не может понять, какая настройка действует.
Одна из систем должна уйти (legacy — кандидат: у obfs есть пресеты, capabilities и валидация
в core), либо нужен явный запрет/приоритет.

### P1 — `ExtraRules`: читаются, но записать их нечем

- Формат файла поддерживает: `core/subscription/override.go:24–25` (`ExtraRules []OverrideRule`).
- `GetSubscriptionOverride` возвращает (`core/control/override.go:161–166`).
- `SaveSubscriptionOverrideRequest` **не имеет поля** для них (`proto/sora/core/v1/core_control.proto:715–727`:
  только renames/hidden/pinned_order/clear). В Dart-UI редактора extra-правил тоже нет.
- Итог: полуфича. Либо добавить `extra_rules` в Save-запрос, либо убрать из Get и формата.

### P1 — `applyProfile` (F5) пишет сырые строки без валидации

`sora.dart:969–982`:
```dart
if (profile.tunnel != null) x.tunnel = profile.tunnel!;
if (profile.preset != null) x.preset = profile.preset!;
if (profile.engine != null) x.engine = profile.engine!;
if (profile.serverId != null ...) x.server = profile.serverId!;
```
- `buildPlan` мапит **любой** `tunnel != 'proxy'` в `TUNNEL_MODE_SYSTEM` (`sora.dart:1893`) — мусор
  из JSON молча становится TUN.
- `engine` уходит в `plan.engines` как есть; `kinds()` в `plan.go:165` не валидирует имена —
  неизвестный движок умрёт только на коннекте невнятной ошибкой.
- `preset` валидируется лишь в core (`routing: unknown preset`) — пользователь узнает о битом
  профиле в момент подключения, а не в редакторе.
- `NetworkProfile.fromJson` (`profiles.dart:67–84`) не проверяет gateway как IP (Go-валидация
  это делает, но она не используется) — профиль с мусором в триггерах просто никогда не матчится,
  молча.

### P2 — Геттеры не клампят значения к белому списку

Только `mihomoTunStack`/`xrayTunStack` валидируют в геттере (`settings.dart:208–220`).
`theme`, `language`, `preset`, `tunnel`, `engine`, `probeMethod`, `dnsPreset`, `serverSortMode`,
`autoSelectMode` — доверяют сырому значению из SharedPreferences. UI даёт только ChoiceTile,
но повреждённое/ручное значение (или будущий apply из профиля/sync) проходит без нормализации
к дефолту. Дешёвый фикс по образцу tun-стеков.

### P2 — Миграции минимальны; схема JSON-сторов не версионирована

- `format = 1`, `_migrate()` (`settings.dart:73–100`) покрывает только `tourDone`-детект апгрейда
  и locale-дефолт `preset`. Это ок для аддитивных ключей, но:
- JSON-сторы (`networkProfiles`, `subscriptionOverrides`, `proxyChains`, `syncedDevices`, `obfs`)
  не имеют версии схемы — изменение формата в будущем потребует эвристик вместо миграции.
- Удалённые ключи остаются в хранилище навсегда (пример: `'speedtestFilter'` удалён в истории,
  ключ-сирота нигде не чистится). Мелочь, но `reset()`/`_migrate()` — естественное место для чистки.

### P2 — Дефолт `launchAtLogin = true` — агрессивный

`settings.dart:224`: приложение по умолчанию прописывается в автозагрузку. Для VPN-клиента
аргумент «защита с первой секунды» понятен, но это решение за пользователя + запись в
системный автозапуск без явного opt-in. Кандидат на `false` или явный вопрос в онбординге.
(Рядом `closeToTray=true`, `notifications=true`, `checkUpdates=true` — безобидны.)

### Info — мелкие дубли и шероховатости

- `serverSortMode` (сортировка списка) vs `autoSelectMode` (режим автовыбора ping/speed/smart):
  две похожие концепции; оправданы, но нейминг почти синонимичен — легко перепутать.
- `dns` + `dnsPreset`: пресет `custom` дублируется состоянием «`auto` + непустой `dns`»
  (легаси-ветка в `_dnsSummary`, `settings_screen.dart:116–128`) — два представления одного факта.
- `Settings.reset()` сохраняет `proxySnapshot`/`notifiedUpdate`/`notificationHistory`, но молча
  сбрасывает `checkUpdates` в `true` — несюрпризно, но асимметрия намерений не задокументирована.

---

## Ранжированные рекомендации

1. **[P0] Убить одну из реализаций F5/F6.** Решение: core — источник правды, Dart — тонкий
   клиент через RPC (либо наоборот — удалить Go-сторы и RPC). Сейчас: удалить мёртвое
   (Go-сторы + RPC + тесты, либо Dart-сторы), переписать врущие docstring'и в `overrides.dart`
   и `profiles.dart`, выровнять имена контракта (`Mode`/`tunnel`, `RulesPreset`/`preset`,
   решить судьбу `dnsPreset`). Метрика готовности: один стор, один матчер, один путь записи.
2. **[P1] Убрать legacy-фрагментацию** (`settings.fragment*`, `antiCensorship` в плане,
   секция в `settings_screen.dart:294–325`) в пользу obfs-suite — либо явно задепрекейтить
   с баннером и запретить одновременное включение. Определить и задокументировать приоритет
   мержа в core.
3. **[P1] Починить `ExtraRules`:** добавить `extra_rules` в `SaveSubscriptionOverrideRequest`
   (+ UI) или удалить из `GetSubscriptionOverride` и формата файла.
4. **[P1] Валидация в `applyProfile` + кламп геттеров:** белые списки для `tunnel/engine/preset/
   dnsPreset` в редакторе профилей и/или в `NetworkProfile.fromJson`; распространить паттерн
   `mihomoTunStack`-геттера на остальные enum-настройки.
5. **[P2] Версионировать JSON-сторы** (поле `v` в envelope) и чистить ключи-сироты в `_migrate()`.
6. **[P2] Пересмотреть `launchAtLogin=true`** → `false` или явный opt-in в онбординге.
7. **[Info] Схлопнуть `dns`-vs-`dnsPreset=custom`** до одного представления; переименовать
   `serverSortMode`/`autoSelectMode` менее синонимично (например `serverListOrder`).

## Ответы на прямые вопросы задания

- **Настройки без эффекта (театр):** `autoSwitchOnDegrade` — ложная тревога, персистится корректно
  (ключ в `_keys:49`). Реальный театр — Go-RPC `SaveSubscriptionOverride`/`ListProfiles` и
  иже с ними: реализованы, оттестированы, никем не вызываются.
- **Kill switch по дефолту:** выключен (`false`), включается только явным действием пользователя;
  состояние per-session, перевооружение после каждого connect. Безопасный fail-open дефолт.
- **Миграции при апгрейде:** аддитивные ключи дефолтятся корректно; структурных миграций
  (кроме `tourDone`/`preset`) нет; JSON-сторы без версионирования — риск на будущее.
- **Дубли UI↔ядро:** фрагментация ×2 (legacy + obfs), оверрайды ×2 (Dart + Go), профили ×2
  (Dart + Go), матчинг ×2 (семантика совпадает), фильтрация hidden/renames ×2.
