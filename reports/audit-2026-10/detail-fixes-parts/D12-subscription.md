# D12 — core/subscription (commit ddb480f)

## OverrideStore.Save глотал ошибку удаления — исправлен
- Было: при очистке правок `_ = os.Remove(path)` — ошибка глоталась; при сбое FS старые правки продолжали применяться, пользователь считал что сбросил.
- Стало: Save возвращает ошибку удаления (кроме IsNotExist), как Delete. control вернёт ошибку в UI.
- Эффект: сбой очистки виден вместо тихого рассинхрона. Тест TestOverrideEmptySaveWithoutAFileIsFine — PASS.

## Проверено с тестами (багов нет)
- id подписок/серверов стабильны между refresh; протухшие id инертны, но накапливаются в JSON навсегда → рекомендован prune в control-зоне при refresh.
- SSRF-защита держит: TestFetchRefusesARedirectIntoPrivateAddresses, TestFetchFollowsALocalRedirectFromAPrivateLiteral.

## Замеры для парсера (не трогал, код в core/parser)
- XHTTP разбирается полностью (type/path/host/mode/sni/fp/alpn/pbk/sid/spx/downloadSettings/xver).
- `naive+https://` НЕ парсится (unsupported); `vpn://` (AmneziaWG) НЕ парсится.
- Trojan SNI/ALPN корректны; алиас peer= для SNI не recognised (оседает в Options); ветка default затирает Transport:"tcp" (control/plan.go:495 уже чинит через orDefault — эффекта нет).

## Латентный баг control-зоны (не чинил — чужая зона)
- SaveSubscriptionOverride (core/control/override.go:125) собирает Override только из Renames/Hidden/PinnedOrder и перезаписывает файл, молча стирая ExtraRules.
