# Fixlog: legacy C# (sora-legacy) — Раунд 1

Ветка: `bugfix/audit-2026-10-19` (репозиторий `~/workspace/bug-hunt/sora-legacy`).
Пуши не делались. C#-тулчейна в окружении нет — сборка не проверялась, все правки вычитаны вручную дважды.
Коммиты: `[audit-fix][legacy-csharp] ... (<ID>)`.

## Исправлено

| ID | Файлы | Что сделано (1 строка) |
|----|-------|------------------------|
| LEGACY-H1 | `legacy/v2rayN/v2rayN/Handler/UpdateHandle.cs` | Запрет downgrade (числовое сравнение версий в `responseHandler`); сверка SHA-256 скачанного zip с `.dgst`-манифестом релиза до распаковки для v2fly/v2fly_v5/Xray (fail-closed, битый архив удаляется). |
| LEGACY-H2 | `legacy/v2rayN/v2rayN/Forms/MainForm.Community.cs` | Перед runas-рестартом TUN: если каталог установки доступен для записи текущему пользователю — явное предупреждение + подтверждение, иначе отмена. |
| LEGACY-H3 | `legacy/v2rayN/v2rayN/Forms/AddServer2Form.cs`, `Handler/ConfigHandler.cs`, `Tool/Utils.cs` | Whitelist расширений (`.json/.yaml/.yml`) в диалоге импорта и в `AddCustomServer`; кнопка Edit открывает только через явный `notepad.exe` с `UseShellExecute=false` + проверка на path traversal. |
| LEGACY-M9 | `legacy/v2rayN/v2rayN/Handler/V2rayHandler.cs` | `V2rayStopPid`: перед Kill сверка `MainModule.FileName` со списком известных бинарников ядер из каталога приложения (защита от PID-reuse); `using` для Process. |
| LEGACY-M10 | `legacy/v2rayN/v2rayN/Handler/UpdateHandle.cs` | `getCoreVersion`: `using` для Process + `Kill()` при превышении 5s-таймаута. |
| LEGACY-M11 | `legacy/v2rayN/v2rayN/Handler/SysProxyHandle.cs` | `QuoteArgument` применён и в `global`-ветке `SetIEProxy` (был только в `ResetIEProxy`). |
| LEGACY-L8 | `legacy/v2rayN/v2rayUpgrade/` (удалён), `legacy/v2rayN/v2rayN/Tool/FileManager.cs` | Мёртвый каталог `v2rayUpgrade` удалён (`git rm`; в `.sln` и коде ссылок нет); в `ZipExtractToFullFile` добавлена проверка `GetFullPath` + префикс каталога (Zip-Slip). |
| LEGACY-L9 | `legacy/v2rayN/v2rayN/Handler/DownloadHandle.cs`, `Handler/UpdateHandle.cs` | `DownloadFileAsync` стал `async Task`: `CancellationTokenSource` в `using` + `CancelAfter(downloadTimeout)` вместо fire-and-forget; вызывающий код адаптирован (`_ =`). |
| LEGACY-L10 | `legacy/v2rayN/v2rayN/Handler/UpdateHandle.cs`, `Forms/MainForm.cs` | Сторожевой файл `proxy_restore.pending`: ставится перед снятием системного прокси, удаляется после восстановления; при старте (`MainForm_Load`) незавершённое восстановление докатывается. |
| LEGACY-L11a | `legacy/v2rayN/v2rayN/Program.cs`, `legacy/installer/Sora.iss` | `--restore-proxy` без `--silent` требует подтверждения в диалоге; деинсталлятор (`UninstallRun`) теперь передаёт `--silent`. |
| LEGACY-L11b | `legacy/v2rayN/v2rayN/Program.cs` | `IsDuplicateInstance`: если мьютекс занят, но живого процесса с этим exe нет — чужой дескриптор закрывается и мьютекс пересоздаётся (защита от squatting/DoS). |
| LEGACY-L11c | `legacy/v2rayN/v2rayN/Global.cs` | `SpeedTestUrl`: `http://` → `https://` (других plaintext-URL замеров в коде нет). |

## Пропущено (с причиной)

| ID | Причина |
|----|---------|
| LEGACY-H1 (geo-часть) | Сверка хэша для `geoip.dat`/`geosite.dat` не реализована: у источника (`Loyalsoldier/v2ray-rules-dat`, `releases/latest/download/{0}.dat`) не подтверждён предсказуемый URL checksum-манифеста (GitHub API rate-limited, гадать запрещено); fail-closed без проверки сломал бы обновление geo. Downgrade-защита к geo неприменима (версий нет). |
| LEGACY-H1 (Authenticode) | Проверка Authenticode-подписи скачанных движков не добавлена: официальные сборки Xray/v2fly не подписаны (насколько известно), требование подписи сломало бы обновления; minisign-ключи — действие владельца (раздел 9 FIX-PLAN). |
| LEGACY-H2 (вариант A) | Перевод установщика на per-machine (`{autopf}`, `PrivilegesRequired=admin`) не сделан: меняет модель установки, тянет миграцию существующих per-user установок и elevation для самообновления ядер — без тестов рискованно; реализован вариант «явный запрос» из брифа. |
| LEGACY-H2 (TunModeController) | Отдельных правок в `TunModeController.cs` нет: запуск elevated-процесса покрыт гейтом в `RestartCommunityAsAdministrator` (точка входа в elevated-режим). |
| LEGACY-H6/H7/H8, LEGACY-M12/M13 | Android: кода нет (только README) — это новая разработка, не фикс; пункты зафиксированы как security requirements в FIX-PLAN. |

## Замечания для следующих раундов

- `VerifyCoreArchiveAsync` покрывает только v2fly/v2fly_v5/Xray (у них точно есть `.dgst`); для SagerNet/clash/hysteria/tuic/sing-box манифест не подтверждён — проверка пропускается с записью в лог. Кандидат на Раунд 2: таблица ожидаемых хэшей/URL манифестов после ручной верификации.
- `CompareVersions` — внутренний `internal static`, покрыть unit-тестом при появлении тестового проекта.
- Конкурентный `git`-поток: на ветке также коммитит `legacy-go` агент (только `core/`, `packaging/`); мои коммиты — только `legacy/`, пересечений нет.
