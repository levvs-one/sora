# WAVE-OS — отдел интеграции с ОС (Wave A)

Ветка `bugfix/audit-2026-10-19` в обоих репозиториях. Машина отдела — Linux
(Ubuntu 24.04): Linux-интеграция проверена прогонами до конца; Windows и
legacy-Windows — статический аудит построчно + точная спека проверки для
dev-машины (§7). Ни одного вердикта «по аналогии»: где нельзя было прогнать,
так и написано.

## Коммиты отдела (исполнитель + независимый ревьюер на каждый)

| Репо | Коммит | Содержание |
|---|---|---|
| sora | `045fd969` | Windows: AppUserModelID на ярлыке Start Menu (атрибуция тостов) |
| sora | `040ba7ba` | Linux: оживлён тест update-helper'а (allowlist песочницы) |
| sora | `45edd405` | Linux: AppStream metainfo + растровые иконки 48–512 |
| sora | `02429800` | Linux: postremove снимает все три nft-таблицы ядра + доки |
| legacy | `c9554618` | v2rayN: IsAutoRun читает то, что пишет SetAutoRun |
| legacy | `a58894c1` | legacy installer: удаление app-written Run-значения при деинсталляции |

Ревью: 6/6 принято независимым ревьюером (чтение diff + сверка с кодом);
два косметических замечания по комментариям внесены до коммитов.

## 1. Linux (sora) — проверено прогонами

| Проверка | Инструмент | Результат |
|---|---|---|
| systemd-юнит `service/linux/sora-core.service` | `systemd-analyze verify` | чисто; единственное замечание — отсутствие `/usr/bin/sora-core` в песочнице (среда, не дефект) |
| Харденинг юнита | `systemd-analyze security` | exposure **4.0 OK** |
| .desktop | `desktop-file-validate` | PASS |
| Update-helper | `packaging/linux/test_update.py` (bubblewrap) | **3 теста OK** после фикса `040ba7ba`; до фикса — 13 ошибок среды |
| Сборка пакетов | nfpm, реальные конфиги, все форматы | sora-core: deb/rpm/archlinux; sora: deb — собраны; скриптлеты присутствуют во всех форматах, включая Arch `.INSTALL` (post_install/post_upgrade/pre_remove/post_remove) и RPM pre/post-uninstall |
| AppStream | ручная сверка ревьюером (appstreamcli в песочнице недоступен) | id/launchable/icon согласованы с .desktop и APPLICATION_ID; лицензия GPL-3.0-only; скриншоты — реальные файлы `docs/images/home-1440x900-{light,dark}.png` с main |

### Polkit — «мёртвая ветка» из ANALYSIS-20 закрыта проверкой

Ветка **жива и согласована по всем трём сторонам**, удалять нечего:
`service/linux/sora.policy` (actions `io.github.levvs-one.sora.read`/`.control`,
`allow_active=yes`) ↔ константы и вызов `CheckAuthorization` в
`core/ipc/polkit_linux.go` (флаги 0 — интерактивный запрос отключён
сознательно, это задокументировано в комментариях политики и честном
threat-model в `docs/install.md`: любой процесс активной локальной сессии =
control, паритет с Windows) ↔ update-путь: Dart вызывает `/usr/bin/pkexec` +
`/usr/lib/sora/sora-update`, путь совпадает с `exec.path` аннотацией
update-политики и dst в nfpm-app.yaml. XML обеих политик валиден.

Вне зоны ОС, замечено попутно: `Authenticator.Rotate()` в
`core/control/auth.go` не имеет продакшн-вызывающих — на рассмотрение отдела
стыков/ядра, не интеграции.

### Находки и фиксы (Linux)

1. **High — дыра в очистке при удалении.** Ядро создаёт три nft-таблицы:
   `sora` (guard), `sora_ingress` (ingress, цепочка кончается drop),
   `sora_nfqws` (bypass). postremove снимал только первую; отдел стыков
   добавил вторую (`b14a97d7`), третью (`sora_ingress`, остаток с
   drop-политикой — самая неприятная) добавил этот отдел: `02429800`
   (скрипт + доки в `packaging/linux/README.md`, `service/linux/README.md`,
   `docs/troubleshooting.md`; там же честно расписано: purge сносит
   `/var/lib/sora` только у deb, RPM/Arch — вручную).
2. **Мёртвый тест update-helper'а.** `test_update.py` падал не на дефекте
   продукта: песочница пробрасывала allowlist в пустой `/usr/bin`, а
   `sora-update` легитимно зовёт `cut`, `chmod`, `sed`, которых в allowlist
   не было (rc=127 только в позитивных тестах; негативные «проходили»).
   Ревьюер выгреб все 19 внешних команд хелпера — пропусков в allowlist
   больше нет. `040ba7ba`.
3. **AppStream/иконки.** Пакет нёс только SVG-иконку и ни одного metainfo —
   магазины приложений (GNOME Software, Discover) показывали Sora пустой
   карточкой. Добавлены metainfo (EN+RU, утверждения сверены с README/nfpm —
   ничего не выдумано) и PNG 48/64/128/256/512 из `docs/images/logo-512.png`;
   nfpm-app кладёт их в hicolor-размеры и `/usr/share/metainfo/`. Пересборка
   deb на ст
...[truncated 11873 chars]