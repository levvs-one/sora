# 65. Mullvad app: UX-паттерны, CLI, аккаунт-система — что копировать один в один

Дата: 2026-10-20. Группа G, третий проход.

## Первоисточники

- Mullvad help: «How to use the Mullvad CLI», «CLI commands for using WireGuard» (тестировано на 2026.1), «Using the Mullvad VPN app» (обновлено 2026-09-18).
- Mullvad CLI reference (mintlify): обзор команд, `custom-list` (включая таблицу exit status), account management.
- Исходники: `github.com/mullvad/mullvadvpn` (GPL), `mullvad-cli/src/cmds/`.
- Сверка с sora (read-only): `core/cmd/sora-core/cli.go` — CLI есть, но это флаги демона (`--data-dir`, `--install-service`…); **управляющего CLI нет**. `errs` уже даёт exit codes 1/2.

## 1. CLI: таксономия команд (копировать структуру)

Категории Mullvad CLI (все через management-interface RPC к демону — CLI и GUI взаимозаменяемы):

| Группа | Команды |
|---|---|
| Core | `connect`, `disconnect`, `reconnect`, `status [-v]` |
| Account | `account create`, `login <номер>`, `logout`, `get [-v]`, `redeem <VOUCHER>` |
| Relay | `relay list`, `relay set location <cc> [city] [hostname]`, `relay get`, `relay update`, `custom-list` |
| Tunnel | `tunnel set mtu/pq/daita/ipv6/allowed-ips` |
| Network | `dns set`, `lan set allow/block`, `split-tunnel` |
| Security | `lockdown-mode set on/off`, `auto-connect set on/off`, `anti-censorship` |
| Data | `export-settings`, `import-settings`, `factory-reset`, `reset-settings`, `log` |

Детали, которые делают его хорошим:
- **Relay constraints как иерархия:** `relay set location se mma se-mma-wg-001` (страна → город → хост). Ошибка подбора — человекочитаемая: «Blocked: Failure to generate tunnel parameters».
- **JSON-вывод:** `-j/--json` у части команд — CLI скриптуем без парсинга текста.
- **Exit codes:** `0` — успех; `1` — ошибка операции (нет списка, неверная локация). (У sora-core уже есть 1 + 2 для invalid argument — совместить: 0/1/2.)
- **`export-settings`/`import-settings`:** JSON-патч текущих настроек — переносимость конфигурации и дебаг («пришлите export»).
- **Lockdown доступен до логина:** `mullvad lockdown-mode set on` работает без аккаунта (FAQ) — kill switch не должен зависеть от авторизации.
- CLI = тот же daemon API, что и GUI: нет «второго пульта» с дрейфом поведения.

## 2. Аккаунт-система

- **Аккаунт = 16-значный номер**, без email/пароля/логина (`mullvad account login 1234123412341234`). Создание — `account create` прямо из CLI.
- Оплата — ваучеры (`redeem`), кэш, крипта; номер можно пополнять, не раскрывая личность.
- Демон хранит **локальную историю аккаунтов** (последний номер подставляется при отзыве устройства).
- **Web auth token:** `GetWwwAuthToken` RPC — короткоживущий токен для входа на сайт без пароля.
- Устройства: лимит, отзыв, ротация WireGuard-ключей.

Для sora (своя подписочная модель): копировать не номера, а принципы — минимум PII, CLI-управление аккаунтом, токен для веба, локальная история.

## 3. UX-паттерны приложения

- **Один огромный Connect/Disconnect** — главный экран = одна кнопка + статус; всё остальное в настройках.
- **Статус честный:** «Blocked: …» с причиной, а не молчаливый дисконнект.
- **Жёлтая точка на замке:** деградация (аккаунт истекает / есть обновление) видна до открытия приложения.
- **Геолокация до подключения — через свой сервис без логов** (`am.i.mullvad.net`): «ваш IP виден как…» без стороннего GeoIP.
- **Продвинутое не мешает базовому:** DAITA, quantum-resistant exchange, multihop, WireGuard-over-TCP — всё в Advanced, дефолты безопасные.
- **Настройки переживают переустановку логики:** `auto-connect` CLI и GUI — независимые настройки (не перетирают друг друга).

## Вердикт «лучшее или слоп»

**Лучшее:** таксономия CLI (глагол → объект → действие), relay constraints иерархией, JSON-вывод, exit codes, export/import настроек, lockdown до логина, аккаунт без PII. Всё это — десятилетия шлифовки инструмента для headless-серверов и скриптов.

**Слоп:** копировать «16-значные номера» ради копирования (у sora своя модель подписок); тащить DAITA/квантовую риторику в маркетинг без реализации.

## Рекомендация «внедрить так» (закрывает гэп: у sora нет управляющего CLI)

1. **`sora` management CLI** (отдельный бинарь или `sora-core ctl`), говорящий с control socket демона — тот же API, что у Flutter-UI:
   ```
   sora status [-v|--json]
   sora connect [profile] | sora disconnect | sora reconnect
   sora server list [--json] | sora server set <id>
   sora account login|logout|get
   sora killswitch set off|standard|strict
   sora speedtest [server] [--json]
   sora diag [--full]   # JA4-check, canary, siberian-зонд из тем 63–64
   sora settings export|import
   ```
   Exit codes: 0/1/2 (как уже заведено в `errs`).
2. Lockdown/strict — доступен без логина.
3. `sora settings export` — JSON для саппорта и миграций.
4. GUI-паттерны: главный экран — одна кнопка + честный статус; деградация — бейджем до открытия; «ваш IP» — через свой diag-сервис.
