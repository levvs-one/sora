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
cd app; flutter build windows --release "--extra-gen-snapshot-options=--compiler_passes=-LICM" --dart-define=SORA_VERSION=1.0.6; cd ..
iscc /DAppVersion=1.0.6 packaging\windows\sora.iss
```

Опубликованный v1.1.2 не подписан Authenticode; SmartScreen может показывать предупреждение. Tag CI требует действительных подписей установщика, GUI, core и sync, только когда в workflow настроен сертификат `WINDOWS_SIGNING_CERTIFICATE`; без него записывает неподписанные EXE в job summary и пропускает выпуск. MSI не собирается; тихая установка EXE работает с ключами `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`.

Тихая установка всегда открывает Sora после регистрации и запуска службы, с исходными правами пользователя. В приложении установщик запускается через ShellExecuteEx с действием `open`, чтобы загрузчик Inno сам запросил UAC и сохранил исходную учётную запись для `[Run]`. Контрольная сумма проверяется до запуска. `install.ps1` ждёт завершения установщика через `WaitForExit()`: `Start-Process -Wait` ждёт ещё и открытую Sora. CI проверяет появление процесса Sora после `install.ps1`.

## Комплект библиотек

CMake `InstallRequiredSystemLibraries` копирует официальные release-библиотеки MSVC рядом с `sora.exe`, включая `msvcp140.dll`, `vcruntime140.dll` и `vcruntime140_1.dll`. Если toolchain не содержит их, конфигурация завершается ошибкой. Установщик уже копирует весь каталог Release вместе с DLL и `data`; переносить один `sora.exe` недостаточно. Системная установка Visual C++ Redistributable пользователю не требуется.

`check-security.ps1` проверяет наличие и непустое содержимое обязательных DLL, AOT и ICU, каталог Flutter assets, SHA-256 и Authenticode всех EXE/DLL/SYS, затем выполняет сканирование Defender без изменения защиты и без удаления файлов. CI сохраняет JSON-отчёт. Отсутствующий Defender или ошибка сканирования не считаются успешной проверкой.

Источники: [рекомендации Flutter по распространению](https://docs.flutter.dev/platform-integration/windows/building#building-your-own-zip-file-for-windows), [стандартный модуль CMake](https://cmake.org/cmake/help/latest/module/InstallRequiredSystemLibraries.html).

## Обход DPI

Windows использует нативный ByeDPI v0.17.3: локальный SOCKS на `127.0.0.1`, без WinDivert и служб перехвата пакетов. Архив закреплён SHA-256 в `packaging/engines/fetch.sh`; в пакет входят только исполняемый файл и MIT-лицензия. Linux продолжает использовать tpws.

Поддерживаются числовые позиции split и TLS record, disorder/OOB и изменение регистра HTTP. Маркеры tpws (`midsld`, `sniext`) и MethodEOL отвергаются до остановки действующего прокси. Настройки по умолчанию Windows используют позицию `1`. UDP отключён: QUIC и блокировку по IP эта стратегия не устраняет. Нативный тест проверяет HTTP/TLS и сохранение работающего прокси после неверного плана; это не доказательство доступности всех сайтов у каждого провайдера.

Выбор проверен 24.10.2026: [ByeDPI](https://github.com/hufrea/byedpi) - v0.17.3 от 22.09.2025, 3434 звезды, 95 открытых issues/PR, MIT, Windows x64-архив 69 809 байт; последнее изменение 29.03.2026, что создаёт риск сопровождения. [zapret2](https://github.com/bol-van/zapret2) - v1.0.6 от 21.10.2026, 5770 звёзд, 8 открытых issues/PR, архив 9 970 350 байт, требует драйвера на Windows. [GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI) - v0.2.2 от 21.03.2022, 28 796 звёзд, 154 открытых issues/PR, Apache-2.0, архив 635 551 байт, старый релиз и драйвер. ByeDPI выбран владельцем и совместим с существующей маршрутизацией SOCKS без изменения сетевой архитектуры.

## Антивирусы

Локальный Defender с базой 1.461.176.0 не обнаружил угроз в официальном установщике v1.1.2 и закреплённом ByeDPI 24.10.2026. Это ограниченное свидетельство, а не обещание отсутствия предупреждений всех антивирусов. У v1.1.2 отсутствует Authenticode; репутация SmartScreen отдельно не подтверждена. Исключения защиты, скрытие кода и самоподписанный сертификат проблему доверия не решают. Текущая ветка ещё должна пройти полную Windows-сборку и проверку нового установщика.
