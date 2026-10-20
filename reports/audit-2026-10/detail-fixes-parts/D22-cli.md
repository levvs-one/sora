# D22 — CLI (commit 4a4fd9a)

## sora-core -h врал и выходил с кодом 2 — исправлен
- Было: -h печатал usage, затем `sora-core: core.auth.unauthenticated: flag: help requested`, exit 2.
- Стало: flag.ErrHelp → exit 0, usage в stdout; битые флаги → exit 2 с честным `core.request.invalid` (не unauthenticated).
- Эффект: честные коды выхода; `sora-core -h | less` работает. Harness-тест: -h→0, --help→0, -bogus→2, валидный флаг→0.

## Проверено без изменений
- Help ↔ флаги (14 флагов sora-core, sora-sync -data-dir) — расхождений нет; упоминания в README/docs/service-файле существуют.
- sora-update fail-closed без подписи: плейсхолдер → die exit 1 до действий; негативная матрица (нет args/неверный arg/zip/1.0.x/относительный путь) — все exit 1. Даунгрейд через UI невозможен.
- Мёртвых команд нет; -install-service на Linux честно «Windows only».

## Кавеат
- Первая правка cli.go исчезла из working tree (кто-то откатил) — переприменил и сразу закоммитил.
