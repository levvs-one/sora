# S4 — независимое ревью фиксов кластера sync/ext (отдел стыков)

Ревьюер — не автор; задача была опровергнуть. Объекты ревью — коммиты как
git-объекты ветки `bugfix/audit-2026-10-19` (экспорты `git archive` в /tmp,
рабочее дерево в проверке не участвовало: оно грязное чужим WIP, но целевые
файлы `sync.dart`/`sync_qr_test.dart`/`ext/catalog.dart`/`ext/manifest.dart`
между `7aa0819f` и HEAD и в worktree не менялись). Утверждения сверялись с
`~/workspace/bug-hunt/reports/seams/s4-sync-ext.md`.

Методика: спаренные пробы Go↔Dart на общих корпусах (один и тот же вход —
Go-вердикт через настоящий `pairing.Decode` / `ext.ParseCatalog` /
`ext.ParseManifestFull`, Dart-вердикт через исправленные Dart-парсеры;
сравнивались не только ACCEPT/REJECT, но и декодированные байты).
Корпуса: sync — 155 кейсов, catalog — 41, manifest — 32, rollout — 7
pinned-векторов, примеры — 4. Пробы гонялись в /tmp-экспортах коммитов,
репозиторий не загрязнялся, коммитов ревьюер не делал.

## Вердикты кратко

| Коммит | Вердикт |
|---|---|
| `ba625cf3` sync QR decoder | **ПРИНЯТ** |
| `d508247f` ext/catalog compile + validation parity | **ПРИНЯТ С ЗАМЕЧАНИЯМИ** (1 остаточное расхождение: диапазон UTC-offset в RFC3339) |
| `7aa0819f` ext/manifest parser parity | **ПРИНЯТ С ЗАМЕЧАНИЯМИ** (2 остаточных расхождения: trim полей author; длина wildcard-host) |
| Спека revocation-в-Dart | **SECURITY-РАЗРЫВ, не UX** (см. отдельный раздел; авторская спека по существу верна и скорее недооценивает) |

---

## 1. `ba625cf3` — sync QR decoder — ПРИНЯТ

### (а) Родитель падает, фикс зелёный — подтверждено

- На родителе (`5991f62a`, экспорт `app/`): `flutter test test/sync_qr_test.dart`
  → **19 pass / 4 fail**; падают ровно 4 accept-кейса: T1 decode, uppercase
  scheme, surrounding whitespace, unknown extra keys — везде
  `Expected: not null, Actual: <null>`. Причина в коде родителя видна:
  `_b64rawDecode` звал `base64Url.decode(s)` без нормализации на
  непаддированных 43/22 символах.
- На фиксе: **29/29** («All tests passed!»), включая +8 новых векторов автора.

### (б) Настоящие Go-пэйлоады и враждебные мутации — 155/155, байт-в-байт

Go-проба в пакете `pairing` генерировала корпус честно, в т.ч. 4 пэйлоада
настоящим `pairing.Encode` (id `device-ff` pub=0xFF…/token=0xAB…, port 65535;
id из 64 кириллических символов = ровно 128 байт; id из 128 ASCII; id с эмодзи
`dev-🚀-x`). Плюс: T1; границы id (65 кир. raw/процентные, 129 ASCII, 32/33
эмодзи = 128/132 байта); padding у pub и token; длины mod 4 == 1
(pub 45 и 41 chars, token 21 chars) и соседние длины (33/18 байт);
символы стандартного base64 `+`/`/` в pub; port: `012345` (accept обе),
`%2B12345` (accept обе), `-5`, overflow `99999999999999999999`;
**полные переборы последнего символа** pub (64 варианта) и token (64
варианта) — неканонические trailing-биты. Итог: `diff` вердиктов Go и Dart
**пуст, 155/155**, и для ACCEPT-кейсов совпали hex pub/token, port и id —
т.е. Dart не просто «принимает то же», а декодирует те же байты, включая
варианты, где последний символ меняет последний байт.

Отдельно проверено объяснение автора, почему не хватило бы `normalize()`:
стоковый Dart-декодер на варианте pub `...Hh9` бросает
`FormatException: Invalid encoding before padding` даже после
`base64Url.normalize()`, а без normalize — на любом валидном payload
(`Invalid length, must be multiple of four`). Авторская мотивировка ручного
декодера — правда.

### (в) Reject-семантика не ослаблена — подтверждено

Подделки с валидным base64, но чужой структурой отвергнуты **обеими**
сторонами: `https://pair?…` (fake-https-url), переставленные pub/token
местами (fake-swapped-pub-token), JSON-блоб, произвольный текст, битый
padding, mod-1 длины. Ни одного случая «Dart принял — Go отверг» или
наоборот во всём корпусе нет.

Замечаний нет. Утверждения коммита и §1д отчёта автора верны полностью.

---

## 2. `d508247f` — ext/catalog — ПРИНЯТ С ЗАМЕЧАНИЯМИ

### (а) Компиляция — подтверждено точно по строкам автора

На родителе (`376ea52f`) `dart analyze lib/src/ext/catalog.dart`:

```
error - catalog.dart:147:10 - undefined_method ('convert' isn't defined for String)
error - catalog.dart:151:13 - invalid_assignment (double -> int)
warning - catalog.dart:9:8 - unused_import (package:crypto)
```

Т.е. файл действительно не компилировался из-за затенения `sha256` полем
записи. На фиксе по `catalog.dart`+`manifest.dart`: **0 errors, 0 warnings**
(остался 1 pre-existing info про `<...>` в doc-comment — он есть и на родителе,
к коммиту отношения не имеет). Runtime-проба корпуса на родителе невозможна в
принципе — импорт `catalog.dart` падает с той же ошибкой компиляции
`:147 convert`; до фикса Dart-валидация каталога была не «слабее», а мертва.

Заодно: семантика починенного `rolloutEligible` сверена с Go по всем 7
pinned-векторам `TestRolloutEligiblePinnedVectors` — совпадение полное
(хеш с NUL-сепараторами, BE u64 mod 10000).

### (б) 6 пунктов паритета — все подтверждены спаренными пробами

Корпус из 41 JSON (база — валидный каталог с настоящим minisign-ключом,
сгенерированным из того же seed, что Go-тесты `core/ext`), вердикты
`ParseCatalog` (Go) против `ExtensionCatalog.parse` (Dart):

| Пункт автора | Кейсы | Итог |
|---|---|---|
| id-паттерн | без точек, uppercase, leading-hyphen label | REJECT обе ✓ |
| semver (version, min_app_version, changelog version) | `v1.0`, `1.0`, `1.9`, `v1` | REJECT обе ✓ |
| RFC3339 (updated_at, changelog date) | date-only, `2026-02-31`, space-separator, `yesterday`, lowercase t/z, second=60 | REJECT обе ✓; валидные offset `+03:00` и fractional seconds — ACCEPT обе ✓ |
| unknown fields | top-level, entry, changelog | REJECT обе ✓ |
| float-в-int | `catalog_version: 1.0`, `"1"`, `max_age: 3600.0`, `size: 1024.0`, `ratings_count: 10.5`, `installs: 100.0` | REJECT обе ✓ |
| байтовая длина notes | 1001 кир. = 2002 байта — REJECT обе; ровно 1000 кир. = 2000 байт — ACCEPT обе (граница точная) | ✓ |

Плюс контрольные: uppercase sha256 — ACCEPT обе (как заявлял автор),
`rating: 5.0` — ACCEPT обе.

Итог по корпусу: 35/41 идентично; все 6 расхождений — один корень ниже.

### Замечание (дефект фикса, точный сценарий)

`parseCatalogTimestamp` в исправленном Dart не проверяет диапазон
UTC-offset: regex допускает любые `\d{2}:\d{2}`, локальная часть проверяется,
а offset — нет; `DateTime.tryParse` такие значения нормализует и принимает.
Go `time.Parse(time.RFC3339)` — отвергает. Пробы:

- `updated_at = 2026-10-20T00:00:00+99:99` → Go **REJECT**, Dart **ACCEPT**
- то же для `+25:00`, `+48:00`, `+99:00`, `+00:99`, `+23:99` → Go REJECT, Dart ACCEPT

(Граница Go при этом сама либеральна: `+24:00`, `+23:60`, `+00:60` принимают
обе стороны — расхождение именно за этой границей.)
Сценарий: team-signed каталог (или битый генератор каталога) с таким
`updated_at` приложение примет и покажет, ядро отклонит целиком.
Серьёзность низкая (поле свежести каталога, не граница безопасности: подпись
каталога проверяется отдельно и до парсинга), но формулировка коммита
«RFC3339-strict» — преувеличение. Лечение: в `parseCatalogTimestamp`
проверять offset-часы/минуты в тех же пределах, что Go.

---

## 3. `7aa0819f` — ext/manifest — ПРИНЯТ С ЗАМЕЧАНИЯМИ

### Пробы по каждому пункту — подтверждены; посылка автора доказана на родителе

Корпус из 32 манифестов, `ParseManifestFull` (Go) против `ExtManifest.parse`
(Dart). На **родителе** (`16a8d8ba`) тот же корпус Dart принимал все
дефектные варианты: `public_key = "not-a-key"` — ACCEPT, битый envelope —
ACCEPT, unknown поля в author/ui/panel — ACCEPT, длины в кириллице сверх
лимита — ACCEPT, `manifest_version: 1.0` — ACCEPT. На фиксе:

| Пункт | Кейсы | Итог |
|---|---|---|
| public_key = minisign-envelope | garbage, wrong-envelope (`XX`+42B), empty, короткий b64 | REJECT обе ✓; ключ с окружающими пробелами — ACCEPT обе ✓ |
| nested unknown fields | author, ui, panel (+ top-level контроль) | REJECT обе ✓ |
| байтовые лимиты | name 40/41 кир. (80/82 байта), description 1000/1001 кир., author name 40/41, identity 80/81, panel title 30/31, settings-name 32/33 кир. | вердикты и границы совпали по всем ✓ |
| manifest_version | `1.0` double, `"1"` string, `2` | REJECT обе ✓ |

### Shipped примеры — проходят на обеих сторонах

Все 4 примера (`hello-panel`, `net-hook-dpi`, `routing-split`,
`theme-midnight`): Go `ParseManifestFull` — ACCEPT ×4; Dart — manifest parse
ACCEPT ×4 и `ExtPackage.open` + `verify()` (подпись+checksums) по
`.soraext` — ACCEPT ×4. Регрессии от фикса нет.

### Замечания (2 остаточных расхождения, точные сценарии)

**З-1. Поля author меряются после trim — Dart слабее Go (направление
«принял то, что ядро отвергнет»).** `ExtAuthor.fromJson` обрезает
`name`/`identity` (`.trim()`) до `validate()`, а Go валидирует сырые строки
(`len()` по байтам, пустота — по trimmed). Пробы:

- `author.name = "A"×79 + "  "` (81 сырой байт) → Go **REJECT**, Dart **ACCEPT**
- `author.identity = "i"×159 + "  "` (161 сырой байт) → Go **REJECT**, Dart **ACCEPT**

Для сравнения: те же хвостовые пробелы у `name` манифеста (81 байт) и у
panel title (61 байт) отвергают обе стороны — там fromJson не триммит;
пропущены ровно два поля author. Сценарий: манифест, который приложение
установит, а ядро при любом обращении к `ParseManifestFull` отвергнет;
хранимое значение при этом обрезанное, т.е. расхождение только в вердикте
валидации, не в данных. Серьёзность низкая, но это ровно тот класс
(«лимиты в байтах по сырой строке»), который коммит заявлял закрытым.

**З-2. Wildcard-host: Dart строже Go (ложный отказ).** Dart
`_parseNetworkHosts` меряет лимит 253 байта по строке целиком, включая
префикс `*.`; Go `normalizeHostPattern` сначала снимает `*.` и меряет
остаток. Проба: `network_hosts = ["*." + имя из 252 символов]` (метки
63/63/63/60, суммарно строка 254 символа) → Go **ACCEPT**, Dart **REJECT**.
Сценарий: валидный по ядру манифест с длинным wildcard-host приложение не
установит. Серьёзность низкая (глубокий край DNS-имён), направление —
безопасное (строже), но паритет нарушен.

Оба замечания — не основания отклонять коммит: все заявленные автором
пункты исправлены и доказаны; это хвосты той же работы, одним коммитом
сверху каждый чинится в несколько строк.

---

## 4. Отдельный вердикт: спека revocation-в-Dart

**Вердикт ревьюера: это security-разрыв, а не UX-несоответствие.**
Авторская спека в §3 отчёта S4 по существу верна («в Dart отсутствует
целиком», «пользовательский путь обходит Go-enforcement»), но картина по
факту хуже её формулировки «Go-стек полный»: ядерный enforcement в проде
не охраняет вообще ничего.

### Доказательная цепочка (все ссылки — состояние на `7aa0819f`)

1. **Установка из UI не проходит через ядро вообще.**
   `app/lib/src/ui/extensions/store_screen.dart`: `_store = ExtensionStore()`
   (:39), установка — `_store.install(...)` (:243) / `_installBytes` (:898);
   `detail_screen.dart:336` — `store.setEnabled(live.id, v)`. Всё это —
   чисто Dart-класс `ExtensionStore` (`app/lib/src/ext/store.dart`):
   свой реестр `installed.json`, своя экстракция, своя проверка подписи;
   `install`/`installBytes` (:384) / `setEnabled` (:410) не содержат ни
   слова про revocation (grep `revoc` по `app/lib/src/ext/` и
   `app/lib/src/ui/extensions/` — пусто).
2. **Ядерного RPC для install/enable не существует.**
   `proto/sora/ext/v1/ext_host.proto`: сервис `ExtensionHost` — только
   `MintToken`, `RevokeToken`, `GetConnections`, `GetServers`, `Notify`,
   `WatchExtensionEvents`. Dart-клиента для `sora.ext.v1` в приложении нет
   вовсе (в `app/lib/src/generated/` — только core/custom/leak;
   grep `MintToken` по `app/lib/` — пусто). Т.е. гипотетический путь
   «UI предлагает — ядро отказывает» отсутствует конструктивно.
3. **Go-Store в проде пуст и недостижим.** `core/cmd/sora-core/main.go:451`
   открывает `ext.OpenStore(<core dataDir>/extensions)` и вешает только
   host-сервис (:468). Вызывающих `Store.Install`/`Store.SetEnabled` вне
   `*_test.go` в репозитории нет (grep по `core/`, `tools/`, `service/`).
   Реестры при этом физически разные: ядро на Linux —
   `/var/lib/sora/extensions` (unit `service/linux/sora-core.service:13`:
   `-data-dir /var/lib/sora`, процесс от пользователя `sora`,
   `ProtectHome=yes` — домашний каталог ему даже не виден), приложение —
   `$XDG_DATA_HOME/sora/extensions` (`store.dart:33`, `extensionsDir()`);
   на Windows ядро — `{commonappdata}\Sora\extensions`
   (`packaging/windows/sora.iss:139`), приложение — `%APPDATA%\sora\extensions`.
   Даже `GrantedPermissions`-замыкание в `main.go` смотрит в пустой реестр.
4. **Список отзыва в проде никогда не загружается.** Enforcement в Go
   настоящий (`core/ext/store.go`: `checkRevocationsLocked` :90,
   вызовы из `Install` :253 и `SetEnabled` :563; просроченный кэш —
   fail-closed для install/update), и `main.go:474` при старте делает
   `RevocationCache.Load()` + `ApplyToStore`. Но `RevocationCache.Refresh`
   (единственный путь, которым verified-список попадает в кэш) **не
   вызывается нигде вне тестов**; `VerifyRevocationList` дополнительно
   fail-closed до key ceremony (`core/ext/revoke.go`). Итог: кэш-файла
   `revocations.json` в ядерном data-dir в проде не существует, список в
   сторе — nil, политика при nil — «installs proceed».
5. **Исполнение панели — тоже целиком Dart.** `panel_screen.dart`:
   доступ — по флагу `inst.enabled` из Dart-реестра; мост
   (`app/lib/src/ext/bridge.dart`) отвечает сам: `getConnections` идёт в
   `CoreControl.ListConnections` (не в ExtensionHost), `getServers` — из
   состояния приложения, `notify` — локально, настройки — Dart-стор.
   Ядерные токены на этом пути не минтятся и не проверяются.

### Точный сценарий разрыва

1. Расширение `com.example.x@1.0.0` легитимно подписано автором, попало в
   каталог, установлено пользователями. Команда узнаёт, что оно вредоносно
   (сам `revoke.go` приводит пример `com.evil.miner`), и публикует
   подписанный `revocations.json` с `{"id": "com.example.x", "versions": "*"}`
   — штатный «emergency brake».
2. Пользователь открывает приложение → Расширения: Dart-стор списка отзыва
   не фетчит, не парсит и не проверяет (его в Dart нет). Уже установленное
   расширение остаётся `enabled=true` в Dart-реестре; `load()` при старте
   ничего не отключает. Ещё не установленное — спокойно ставится через
   `installBytes` (подпись пакета валидна — отзыв бьёт именно по валидно
   подписанным пакетам, подписью он не заменяется), `setEnabled(true)`
   проходит безусловно.
3. Пользователь открывает панель: WebView обслуживается из Dart
   content-dir, мост даёт расширению `connections.read` (список соединений
   через CoreControl), `servers.read`, `notifications` и его настройки —
   в объёме выданных при установке разрешений. Ядро на всём пути не
   встречается: его отказ из п.3–4 относится к пустому реестру, которого
   приложение не касается.
4. Перезапуск ядра не помогает: список в его кэш никогда не записывался,
   а даже записанный вручную — заблокировал бы только недостижимые
   `Store.Install/SetEnabled` и не тронул бы Dart-реестр и панели.

Честная граница ущерба на сегодня: самые опасные разрешения
(`net.hooks`, `routing.rules`, `theme.apply`, `background`-исполнитель) по
`core/ext/enforcement.go` — Unimplemented, потребителя в проде у них нет;
реально достижимая поверхность отозванного расширения — панель в WebView
(с CSP-локдауном из `panel_screen.dart`) + данные моста выше. Это не
перехват трафика, но это ровно то, от чего revocation существует:
валидно подписанное расширение, которое команда публично отозвала,
продолжает устанавливаться, включаться и работать с данными соединений
у всех пользователей приложения, бесконечно.

### Оценка авторской спеки фикса

Направление спеки (порт `revoke.dart` + проверка подписи через
`verifier.dart` + кэш + enforcement в Dart `install/installBytes/setEnabled`
+ disable при старте/синхронизации каталога) — правильное и необходимое:
чинить надо именно Dart-путь, потому что только он существует. Два
уточнения к спеке по фактам выше:

- Кэш и список должны жить в **Dart** ext-dir (`extensionsDir()`), а не в
  «ext dir» вообще: ядерный `<dataDir>/extensions` приложению недоступен
  как источник (другой пользователь/путь), а спека это не различает.
- Утверждение «Go-стек полный» надо читать как «полный по библиотеке»:
  в проде не хватает ещё и триггера `Refresh` — если когда-нибудь
  ядерный путь станет реальным (RPC install), список туда сам не придёт.
  Для Dart-фикса это не блокер: фетч списка — пункт (3) спеки.

Итоговая серьёзность: **High как дефект механизма отзыва** (единственный
emergency brake расширений не подключён к единственному пути установки и
исполнения), при сегодняшней фактической поверхности атаки — панель+мост,
без трафиковых разрешений.

---

## 5. Что ещё прогнано для контекста

- `go test ./ext/ -count=1` (core, фикс-состояние) — ok; `go test ./...`
  в `service/sync` — все пакеты ok. Авторские заявления о зелёных
  Go-сьютах подтверждаются.
- Родитель manifest (`16a8d8ba`): тот же Dart-корпус принимает все
  дефектные кейсы коммита `7aa0819f` — посылка «Dart был слабее Go по
  всем пунктам» доказана прямым прогоном, не только чтением кода.

## Итог

- `ba625cf3` — **ПРИНЯТ** без замечаний (155/155 спаренных вердиктов,
  включая байты и переборы trailing-битов).
- `d508247f` — **ПРИНЯТ С ЗАМЕЧАНИЯМИ**: все 6 пунктов и компиляция
  доказаны; остаток — диапазон UTC-offset в `parseCatalogTimestamp`
  (Go REJECT / Dart ACCEPT на `+25:00` и хуже), низкая серьёзность.
- `7aa0819f` — **ПРИНЯТ С ЗАМЕЧАНИЯМИ**: все пункты доказаны, примеры
  4/4 на обеих сторонах; остатки — trim полей author (Dart слабее) и
  длина wildcard-host (Dart строже), низкая серьёзность.
- Revocation: **security-разрыв** (не UX); авторская спека верна по
  существу, с двумя уточнениями выше.
