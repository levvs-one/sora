# packaging/windows

Установщик для Windows 10 1809+ и 11, x64. Собирается Inno Setup 6.7 из `sora.iss`.

Что делает установщик:

- кладёт приложение в `Program Files\Sora`, службу и ядра в `Program Files\Sora\core`;
- регистрирует службу `SoraCore` (`sora-core.exe -install-service`): автозапуск, перезапуск после сбоя, данные в `ProgramData\Sora`;
- регистрирует ссылки `sora://`, а `happ://` только если их ещё никто не открывает;
- при обновлении останавливает службу перед заменой файлов;
- при удалении удаляет службу, запись автозапуска и регистрацию `happ://`, если она принадлежит Sora.

Вид: стиль Windows 11, светлая или тёмная тема по системе, фон из `art/`. Страниц две: выбор пунктов с кнопкой «Установить» и финал.

## Сборка

```powershell
cd core; go build -trimpath -ldflags '-s -w' -o ..\dist\windows\sora-core.exe .\cmd\sora-core; cd ..
bash packaging/engines/fetch.sh windows-amd64 dist/windows/engines
cd app; flutter build windows --release --dart-define=SORA_VERSION=1.0.6 --dart-define=APP_VERSION=1.0.6; cd ..
iscc /DAppVersion=1.0.6 /DSoraUnsigned packaging\windows\sora.iss
```

Подписанная сборка (сертификат владельца) — команда как раньше:

```powershell
iscc /DAppVersion=1.0.6 "/SsoraSign=signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 $f" packaging\windows\sora.iss
```

В `sora.iss` подпись включается через `SignTool=soraSign` (плюс
`SignedUninstaller=yes` для деинсталлятора), но только если сборка не
отказалась от неё явным `/DSoraUnsigned`: сборка без определённого `soraSign`
и без `/DSoraUnsigned` падает с ошибкой компиляции, так что неподписанный
установщик не уедет в релиз случайно. Сам сертификат (Azure Trusted Signing) —
действие владельца, см. FIX-PLAN.md, раздел 9. Без подписи SmartScreen
показывает предупреждение; подлинность — по `SHA256SUMS` (подробно про
подписанный и неподписанный артефакт — в `docs/development.md`, раздел
«Подпись установщика Windows»). MSI не собирается: для обычной установки хватает EXE, тихая установка работает с ключами `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`.

Тихая установка всегда открывает Sora после регистрации и запуска службы, с исходными правами пользователя. В приложении установщик запускается через ShellExecuteEx с действием `open`, чтобы загрузчик Inno сам запросил UAC и сохранил исходную учётную запись для `[Run]`. Контрольная сумма проверяется до запуска. `install.ps1` ждёт завершения установщика через `WaitForExit()`: `Start-Process -Wait` ждёт ещё и открытую Sora. CI проверяет появление процесса Sora после `install.ps1`.

Обход DPI без сервера (zapret) на Windows пока не встроен.
