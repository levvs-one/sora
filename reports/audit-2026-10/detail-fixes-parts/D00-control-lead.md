# LEAD — core/control: две дыры, найденные охотниками, но не чиненные (commit ae1823f)

## ExportDiagnostics не проверял control_authenticator — исправлен
- Было: proto field 5 control_authenticator принимается, Dart его шлёт, но хендлер токен не проверял (Connect/Disconnect проверяют). Любой локальный вызывающий мог забрать архив диагностики.
- Стало: `s.auth.Check(req.GetControlAuthenticator())` сразу после checkVersion — тот же паттерн, что у Connect/Disconnect.
- Эффект: мёртвое поле стало рабочей проверкой.
- Тесты: TestExportDiagnosticsRefusesABadToken (+) — PASS; TestNativeDiagnosticsRequireAuthenticationAndTheOwnedSession обновлён (без токена теперь Unauthenticated до проверки формата) — PASS.

## SaveSubscriptionOverride молча стирал ExtraRules — исправлен
- Было: хендлер собирал Override только из renames/hidden/pinned и перезаписывал файл; в запросе нет поля extra_rules → сохранённые ExtraRules стирались при каждом сохранении переименований.
- Стало: перед сохранением подгружается существующий Override, ExtraRules переносятся (кроме Clear=true — там стирается всё).
- Эффект: пользовательские routing-правила переживают правки подписки.
- Тесты: TestSaveSubscriptionOverridePreservesExtraRules (+, включая негатив Clear) — PASS.

## Проверки
- go build ./control/ — чисто (ветка). go vet падает только на чужом сломанном core/ext (missing imports — half-applied работа другого агента), не мои файлы.
- Тесты прогнаны в полном worktree на здоровом типе ветки (мой коммит — предок) — все PASS.

## ИНЦИДЕНТ: пустой коммит ca280d8
- Охотник D11 закоммитил ca280d8 "[detail-fix] diagnostics: ..." с ПУСТЫМ деревом (tree 4b825dc — empty hash): temp-index рецепт без read-tree HEAD. Ветка указывала на пустое дерево.
- Действие: атомарный CAS update-ref вернул указатель на 1483f57 (родитель, дерево здорово: 24 entries, engine/go.mod на месте). Плохой коммит брошен (остался в object DB).
- Работа D11 не потеряна: его файлы застейджены в индексе (A core/diagnostics/...) — ему нужно перекоммитить нормально.
- Мой коммит ae1823f собран по полному CAS-рецепту (read-tree + фильтр 5 файлов + write-tree + commit-tree + update-ref old-value) — приземлился чисто, при проверке `git show --stat HEAD` только мои файлы.
- Урок для всех: после КАЖДОГО коммита проверять `git show --stat HEAD` и что дерево не пустое (`git ls-tree HEAD | wc -l` >> 0).

## ИНЦИДЕНТ-2: throttle.go выпал из дерева (спасён)
- core/diagnostics/throttle.go + throttle_test.go (фича T018 TSPU-отдела, коммит 15175c2) пропали из дерева HEAD из-за sparse-коммита вскоре после 15175c2 (уже в 3d5f268 их нет). В worktree файлы уцелели нетронутыми.
- Действие: сверен хеш (байт-в-байт с 15175c2), файлы возвращены в индекс (`git add`). Следующий полный коммит вернёт их в дерево.
- Урок усилен: sparse-акциденты роняют чужие фичи молча; `git show --stat HEAD` после каждого коммита обязателен.
