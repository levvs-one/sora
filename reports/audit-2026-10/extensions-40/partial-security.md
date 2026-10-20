# Security-зона расширений sora — частичный отчёт (extensions-40)

Дата: 2026-10-20. Ветка: `bugfix/audit-2026-10-19`.

**Статус коммитов:**
- 00:23–01:0x — работа в файлах завершена, коммиты заморожены (инцидент истории).
- ~01:0x — родитель: «ветка починена, можно коммитить» (HEAD=3bac79d).
- Проверка выявила: прод-код моих изменений (store.go TokenTTL/revocation,
  package.go hardening, main.go wiring) уже попал в историю через
  forward-fix; в рабочем дереве остались только 9 новых файлов.
- **01:3x — ИНЦИДЕНТ ПОВТОРИЛСЯ: HEAD=cc38c4f имеет ПУСТОЕ дерево
  (`git cat-file -p HEAD^{tree}` — 0 записей). Коммиты снова
  заблокированы мной до нового сигнала родителя.** Коммит поверх
  пустого дерева удалил бы весь репозиторий из ветки.
- ~01:58 — родитель: ветка отремонтирована (HEAD=5519bc4, 1275 файлов),
  добро на точечный коммит 9 новых файлов. При подготовке обнаружено:
  ремонт включал `git clean` — 8 из 9 файлов были удалены с диска
  (уцелел только revoke.go). Все 8 восстановлены из контекста сессии
  дословно, gofmt/build/vet/test — зелёные.
- **Коммит приземлён: `977163c` `[ext] security: revocation list,
  sideload consent, token/fuzz/permission tests, threat model`
  (9 файлов, 1185 insertions, CAS через update-ref). `go build ./ext/`
  и `go test -count=1 ./ext/` — зелёные; HEAD больше не красный
  (RevocationList резолвится).**

Репозиторий: `~/workspace/bug-hunt/sora`. Контекст прочитан:
`reports/EXTENSIONS-VISION.md`, `docs/extensions.md`, `core/ext/`,
`proto/sora/ext/v1/ext_host.proto`.

Зона выполнялась одним лидом без подагентов (depth 2/2 не позволяет
порождать агентов) — 8 тем отработаны последовательно как workstreams.

---

## 1. Внедрено (в рабочем дереве, коммиты отложены)

### WS1 — Enforcement permissions: матрица и закрытая дыра mint'а

**Найдено:** из 12 пермишенов реально проверяются в коде только 5:
`connections.read`, `servers.read`, `notifications` (closed map
`rpcPermissions` в `core/ext/host.go` + `app/lib/src/ext/bridge.dart`),
`net.fetch` (конструирование `Fetcher` только при гранте +
попутные проверки), `background` (`Scheduler.Register` требует capability
**и** permission). Остальные 7 (`settings.read/write`, `tray`,
`ui.panel`, `theme.apply`, `routing.rules`, `net.hooks`) не имеют точек
проверки ни в Go, ни в Dart — декларации без enforcement. Особенно
честно: `routing.rules` и `net.hooks` — `RiskDangerous` с нулём кода
проверок. Полная матрица — в `docs/extensions/threat-model.md` §4.

**Закрыто кодом:** хук `Deps.GrantedPermissions` существовал в `host.go`,
но не был нигде подключён — `Host.MintToken` доверял списку пермишенов
от приложения. Подключено в `core/cmd/sora-core/main.go`: ядро минтит
токены только для installed+enabled расширений и только в пределах
выданных юзером пермишенов (`TestMintTokenEnforcesGranted` у смежного
агента покрывает хук; проводка — моя).

**Тест:** `core/ext/security_test.go::TestRpcPermissionsCoverRegistry` —
map ⊆ реестра, все обслуживаемые RPC в closed map, app-only RPC
(`MintToken`/`RevokeToken`) вне extension-token map'а.

### WS2 — Per-extension токены: TTL, ротация, отзыв

- `TokenTTL = 24h` (`core/ext/store.go`): грант несёт `IssuedAt`/`ExpiresAt`;
  `Verify` отвергает и удаляет просроченные; `Mint` лениво выметает
  протухшие (карта не растёт бесконечно).
- Отзыв при disable/uninstall/rollback уже был (`RevokeByExtension`) —
  проверено, не трогал.
- Подмена/утечка: 32 байта CSPRNG, opaque, server-side map,
  constant-time lookup — уже было; TTL ограничивает ущерб от утечки
  сутками. In-memory: рестарт ядра инвалидирует всё, приложение
  перевыпускает при старте.
- Тесты: `TestTokenExpires`, `TestGrantExpired`, `TestMintSweepsExpiredTokens`.

### WS3 — Подпись .soraext и zip-hardening

- Цепочка minisign переиспользует H1-инфраструктуру (`VerifyPayload`) —
  было, не трогал. Покрытие checksums: каждый файл ровно один раз;
  `signature.minisig`/`checksums.txt` аутентифицируются trusted comment.
- **Найдено и исправлено:** `isSafeArchivePath` пропускал `\` и `:` —
  на Windows/Dart-экстракторе бэкслэш это разделитель (`..\..\evil`,
  `C:\evil`), двоеточие — ADS (`panel.html:evil`). Теперь оба символа
  отвергаются всегда (спека §1 требует только forward-slash).
  `core/ext/package.go`, тест `TestArchivePathHardening`.
- Downgrade: `Install` требует строго более новую semver — было, верно.
  Откат — явное действие юзера. Менять нечего.

### WS4 — Revocation list (новый код)

`core/ext/revoke.go` + `revoke_test.go`, интеграция в `Store`:

- Формат: `revocations.json` + `.minisig` (team key, trusted comment
  `file:revocations.json`; fail-closed до key ceremony —
  `VerifyRevocationList`). Язык версий намеренно крошечный:
  `*`, `=x.y.z`, `<x.y.z`, `<=x.y.z`.
- Enforcement: `Install`/`SetEnabled(true)` отвергают отозванные
  id@version.
- Честная офлайн-политика (без театра): нет кэша — установки идут
  (каталог — первичный гейт); протухший кэш — новые установки/обновления
  блокируются (fail closed), установленные продолжают работать;
  emergency kill (`"versions":"*"`) работает только когда устройство
  может скачать список. Приложение перепроверяет при каждом старте.
- Тесты: парсинг/отвержения, `versionMatches`, fail-closed до церемонии,
  блокировка install/enable, протухший список, отсутствие списка.

### WS5 — Аудит секретов: доказательство кодом

Доказано (не декларацией), записано в `threat-model.md` §5:

1. Секреты — в `srv.secrets` (`core/control`), в `OutboundSpec` только
   `CredentialsRef` (ссылка, не байты).
2. `core/ext` не импортирует `core/control` (проверено grep'ом, только
   комментарии) и содержит ноль обращений к secret store. Стрелка
   зависимости строго `control → ext`.
3. Адаптеры в `core/control/exthost.go` проецируют: `ListServers` →
   `{ID, Name}` (endpoint и даже референс credentials отброшены),
   `ListConnections` → `{ID, Process, Host, Up, Down}`.
4. В `ext_host.proto` нет секретоподобных полей в ответах/событиях;
   `WatchExtensionEvents` шлёт `detail: ""` намеренно.
5. Логи: `safeMethodURL` режет query/fragment/userinfo; ядро не пишет
   credential-материал в логи расширений.
6. Dart-зеркало `app/lib/src/ext/*.dart`: секретов нет (кроме самих
   `extension_token`/`control_token` — это механизм аутентификации).

**Отсеяно:** явный permission-путь к секретам. Такого пермишена нет и не
планируется. Если потребность появится — только новый `RiskDangerous`
пермишен с отдельным экраном согласия, аудитом и аппрувом владельца,
не расширение существующего. «Расширения никогда не видят секреты
подписок» — нагрузочный инвариант.

### WS6 — Sideload: честное предупреждение

`core/ext/sideload.go` + `sideload_test.go`:

- `SideloadConsent(manifest)` (только после `pkg.Verify()`) строит факты
  для экрана согласия: автор, identity, key id + SHA-256 fingerprint
  ключа (`AuthorKeyFingerprint`, формат `AB12:CD34:…`), все пермишены с
  **конкретными** последствиями («сможет перенаправлять ваш трафик —
  включая банк и почту — через выбранные им серверы»), dangerous
  первыми; блок рисков: «не из каталога», «подпись self-attested —
  доказывает неизменность, а не личность автора», «продолжайте, только
  если fingerprint совпадает с опубликованным ключом автора».
- Спека UI (экран согласия, TOFU-пининг ключей автора с громким
  варнингом при смене ключа, «доверять автору» как осознанный тап без
  пречека) — в отчёте, реализация на Dart-стороне (SDK недоступен).

### WS7 — Threat model

`docs/extensions/threat-model.md`: активы (A1–A6), акторы, границы
доверия (диаграмма), матрица enforcement §4, аудит секретов §5,
подписи §6, revocation §7, sideload §8, **остаточные риски §9 (честно,
без театра)** — компрометация рендерера, тотальность dangerous
пермишенов, компрометация ключа автора, офлайн-килл, незавершённая
церемония ключей, DNS-allowlist, инертные dangerous-пермишены.

### WS8 — Fuzzing валидатора манифеста

`core/ext/manifest_fuzz_test.go`: `FuzzParseManifest` (малформированный
JSON, глубокая вложенность, транкейшн, битый UTF-8, unicode-трюки:
lookalike-точки, RTL-override, zero-width) и `FuzzParseChecksums`.
Инварианты: без паник; accept ⇒ ревалидация и независимая проверка
структурных правил.

**Прогон:** `FuzzParseManifest` — 44 784 execs за 76с, **находок нет**;
`FuzzParseChecksums` — 697 337 execs за 60с, **находок нет**.
(Прогон шёл в изолированном модуле-копии из-за битого /tmp и
конфликтующих тест-файлов смежника; инварианты и сиды те же, что в
репозитории.)

---

## 2. Спеки (не код — осознанно)

1. **Доставка revocation list:** signed fetch с каталогового эндпоинта,
   `expires_at` как max-age (рекомендуется 7 дней), приложение кэширует
   и перепроверяет при старте/синке каталога; emergency kill —
   внеплановый fetch + push-уведомление. Код проверки готов (§WS4).
2. **Экран согласия сайдлоада** и **TOFU-пининг ключей** — Dart-сторона,
   факты готовы (§WS6).
3. **Проактивная ротация токенов** приложением (TTL 24ч — серверная
   сторона готова; клиент может перевыпускать чаще).
4. **Маркировка неимплементированных пермишенов** в UI установки:
   `routing.rules`/`net.hooks`/`theme.apply`/`tray` показывать как
   «не поддерживается этой версией», а не как granted capability.

---

## 3. Отсеяно и почему

| Идея | Решение |
|---|---|
| Permission на чтение секретов подписок | Отклонено: инвариант «никогда» сильнее любого пермишена; путь — только новый dangerous-пермишен с отдельным аудитом |
| Constant-time сравнение sha256 в `Verify()` | Отклонено: это integrity-check, не сравнение секрета; timing oracle неприменим |
| Блокировка установок при отсутствии revocation list | Отклонено: сломало бы first-run и офлайн-установки; каталог — первичный гейт |
| Удаление протухших расширений при офлайне | Отклонено: kill без связи недоставим; притворяться — театр |
| Прото-изменения (expiry в `MintTokenResponse`) | Отклонено: требует перегенерации; TTL enforced server-side, клиенту знать не обязан |

---

## 4. Критерий «лучшее или слоп» — что вычищено по ходу

- Удалён мой же `ValidateGrant`/`MintTokenFor` из `store.go`: дублировал
  уже существующий хук `GrantedPermissions` смежного агента — мёртвый
  код не коммитим.
- Удалён `_ = pubLine` и `old` variable hacks в тестах.
- `patch`-бэкап `store.go.orig` удалён.
- Не стал «чинить» чужой `netfetch_stats_test.go` (автор починил сам за
  минуту) — не трогаю чужую активную работу.

---

## 5. Инциденты совместной работы (родителю)

1. **Мой `git stash` случайно забрал незакоммиченную работу всех**
   (думал — только свою). Восстановил: свои файлы вытащил обратно
   (`checkout stash@{0} -- <мои пути>`), чужую дельту `store.go`
   смержил поверх (7/8 ханков автоматом, Rollback — вручную с
   сохранением их intent + моего match-check), `fingerprint_test.go`
   восстановил. **В `stash@{0}` (WIP on bugfix/audit-2026-10-19: 94f9e30)
   остаются чужие pre-stash изменения — не дропать без разбора.**
2. Смежный агент landed `2517723 [detail-fix] ext: token scope enforced
   at mint` — мой WS1-хук оказался уже реализован им; моя проводка в
   `main.go` легла поверх его хука (14 строк, совместимо).
3. `go test ./ext/` дважды ломался чужими промежуточными состояниями
   (дубли `roundTripFunc`, type mismatch) — оба раза автор чинил сам;
   финальный прогон зелёный.
4. Два ложных «HEAD сломан» (моя ошибка чтения `git ls-tree` без
   слэша) — проверено, история цела.

## 6. Что pending от родителя

- **Сигнал «можно коммитить»** после forward-fix'а истории. Порядок
  коммитов (каждый селективно, temp-index по рецепту из AGENTS.md):
  1. `[ext] security: per-extension token TTL (24h) + expiry sweep`
  2. `[ext] security: signed revocation list, install/enable enforcement`
  3. `[ext] security: zip path hardening — reject backslash and colon`
  4. `[ext] security: sideload consent facts + author key fingerprint`
  5. `[ext] security: manifest validator fuzz tests`
  6. `[ext] security: wire GrantedPermissions into MintToken`
  7. `[ext] docs: extensions threat model`
- Владелец: key ceremony (блокер каталога и revocation), ручная
  проверка Dart-зеркала (`isSafeArchivePath` надо повторить
  побайтово в `app/lib/src/ext/package.dart`).
