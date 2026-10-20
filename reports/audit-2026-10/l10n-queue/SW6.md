# l10n queue — SW6: UI возможностей расширений v2

Ветка `bugfix/audit-2026-10-19`, только `app/`. Код уже ссылается на ключи ниже
через `S.of(context)`; сами `app/lib/l10n/*` НЕ трогать.

Применение: добавить ключи в `app/lib/l10n/app_en.arb` и `app/lib/l10n/app_ru.arb`
(английский — fallback для остальных 27 языков), затем `flutter gen-l10n`.
Метаданные `@key` с `placeholders` — по образцу существующих
(`@extInstallsCount`, `@extByAuthor`). Plural-ключи — по образцу `groupOrdered`.

| key | en | ru | placeholders |
|---|---|---|---|
| `extCapBackground` | `Runs in the background` | `Работает в фоновом режиме` | — |
| `extCapNetwork` | `Network access` | `Доступ к сети` | — |
| `extCapNetworkHosts` | `Network: {hosts}` | `Сеть: {hosts}` | `hosts`: String — хосты через запятую, напр. `api.example.com, *.cdn.example.com` |
| `extPermBackgroundDetail` | `Runs scheduled tasks even when the panel is closed. You can pause it or change how often it runs in the extension settings.` | `Выполняет задачи по расписанию, даже когда панель расширения закрыта. Приостановить или изменить интервал можно в настройках расширения.` | — |
| `extPermNetworkDetail` | `Fetches data from the internet. Only the hosts below are allowed — everything else is blocked.` | `Загружает данные из интернета. Разрешены только хосты из списка ниже — всё остальное заблокировано.` | — |
| `extBgTitle` | `Background task` | `Фоновая задача` | — |
| `extBgEnabled` | `Run in the background` | `Выполнять в фоне` | — |
| `extBgInterval` | `Run every` | `Запускать каждые` | — |
| `extBgMinutes` | `{count, plural, one {# minute} other {# minutes}}` | `{count, plural, one {# минуту} few {# минуты} other {# минут}}` | `count`: int |
| `extBgHours` | `{count, plural, one {# hour} other {# hours}}` | `{count, plural, one {# час} few {# часа} other {# часов}}` | `count`: int |
| `extBgNote` | `The system may delay runs to save battery. The shortest interval is 15 minutes.` | `Система может откладывать запуски для экономии заряда. Минимальный интервал — 15 минут.` | — |
| `extBgDisabledNote` | `Enable the extension to manage its background task.` | `Включите расширение, чтобы управлять его фоновой задачей.` | — |

Проверка после применения: `grep -rn "extBg\|extCap\|extPermBackgroundDetail\|extPermNetworkDetail\|extCapNetwork" app/lib --include='*.dart'` —
каждый ключ из таблицы должен использоваться, каждый `S.of(context).ext*` из кода
настоящего отчёта — присутствовать в таблице.
