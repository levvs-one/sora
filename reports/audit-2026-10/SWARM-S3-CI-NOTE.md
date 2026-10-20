# S3: CI-job свежести uTLS-фингерпринтов — записка

## Что сделано
Новый workflow `.github/workflows/utls-freshness.yml` (ежедневно 04:43 UTC + ручной запуск).
Job **падает** (красный, не warning) в трёх случаях:

1. **Лаг utls** — пин `refraction-networking/utls` в `core/go.mod` старше tip
   upstream более чем на **30 дней**. 30 дней = один релизный цикл Chrome (~4 недели)
   + запас: каждый релиз Chrome — потенциальный новый parrot в utls.
2. **Chrome stable ушёл вперёд** — Google Version History API сообщает major
   больше, чем `chrome_version` в `known_ja4.json`: эталонный JA4 и parrot могли
   протухнуть (сценарий Chrome 133 / ТСПУ, окт. 2026).
3. **Рассинхрон** `known_ja4.json` ↔ `core/engine/fingerprint.go`
   (`CurrentChromeVersion`, `ReferenceChromeJA4`) — правили одно, забыли другое.

Создан минимальный эталон `known_ja4.json` (файла не было): Chrome 155,
JA4 `t13d1517h2_8daaf6152771_cb7bf5808d99`, stamp 2026-10-20.
Скрипт — stdlib-only Python, SHA-пины экшенов как в остальных workflow.
Сетевой сбой = тоже красный (`INFRA:`), неизвестное состояние не считается пассом.

## Файлы
- `.github/workflows/utls-freshness.yml` — workflow
- `.github/utls-freshness/check.py` — проверки (флаги `--selftest`, env-оверрайды)
- `.github/utls-freshness/known_ja4.json` — эталон
- `.github/utls-freshness/README.md` — доки: что проверяет, почему 30 дней, что делать при красном

## Как проверить
- `python3 .github/utls-freshness/check.py --selftest` — офлайн
- `python3 .github/utls-freshness/check.py` — полный прогон (сейчас зелёный: lag 0 дней, Chrome 155)
- Симуляция красного: `S3_LAG_LIMIT_DAYS=-1 python3 .github/utls-freshness/check.py` (exit 1, FAIL с инструкцией);
  либо подсунуть копию `known_ja4.json` с пониженным `chrome_version` через `S3_KNOWN_JA4=...`
- `actionlint .github/workflows/utls-freshness.yml` — чист (SHA-верификация архива как в repository.yml)

## Что делать при красном job'е
См. раздел «Что делать, когда job красный» в `.github/utls-freshness/README.md`
(бамп utls → перепроверка HelloChrome_Auto → при смене Chrome: ручное переизмерение
JA4 против брендированного Chrome + обновление фикстуры, fingerprint.go, engines.lock).

## Не в скоупе (другой агент)
Авто-fallback фингерпринта при TLS-timeout. Ядро не тронуто (только чтение
`fingerprint.go` для кросс-проверки); `core/diagnostics/ja4.go` и список «не трогать»
дедупликации не задеты.
