# D47 — .github/workflows (commit 2b2631a)

## Незапиненные экшены
- Было: все workflow проверены — все сторонние экшены уже запинены по SHA (коммит 98794f1). Ни одного `uses:` с тегом не осталось.
- Стало: менять нечего; подтверждено грепом.
- Эффект: supply-chain защищён.

## --dart-define=APP_VERSION в релизной сборке
- Было: store_screen.dart читает String.fromEnvironment('APP_VERSION'); релизные джобы (windows, linux-packages) передавали только SORA_VERSION — APP_VERSION пуст, гейт min_app_version не работал в релизе.
- Стало: в оба джоба добавлен шаг «Read APP_VERSION from pubspec» + `--dart-define=APP_VERSION=${{ env.APP_VERSION }}`. Рецепт даёт 1.0.12 из pubspec. Проверено actionlint 1.7.7 — чисто.
- Эффект: магазин расширений в релизе видит настоящую версию и отсекает несовместимые.

## CI-рецепты vs реальные команды
- Было/стало: сверено с docs/development.md — Flutter 3.47.6, ldflags buildVersion, nfpm, fetch.sh, iscc — совпадают.
- Эффект: расхождений нет. Кавеат: SHA-пины сверены по форме, не пересчётом с upstream.
