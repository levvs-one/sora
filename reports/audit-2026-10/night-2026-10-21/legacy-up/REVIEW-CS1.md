# Ревью C#-W1 — независимый ревьюер C#-W1

Объект: коммиты `44acb5f` (Client: CLI-контракт инсталлятора) и `5c4190e`
(installer: регистрация sora://) в `sora-legacy`, ветка
`bugfix/audit-2026-10-19`, HEAD `5c4190e8aa3edf2ec6fbfd97b13ff420cc87d7b5`.
Основания: `AUDIT-PARITY.md` (W1, §4–§5), `WAVE-OS.md` (фиксы `c955461`,
`a58894c`). Код ревьюером не правился.

Метод: построчная сверка новых файлов Client (`Program.cs`, `AutoRun.cs`,
`SystemProxy.cs`, `ImportLink.cs`, `ClientSettings.cs`) с эталоном —
поставляемым v2rayN-путём (`v2rayN/Program.cs`, `Tool/Utils.cs`,
`Handler/SysProxyHandle.cs`, `Handler/ProxySetting.cs`, `Global.cs`,
`Forms/MainForm.cs`) и с `installer/Sora.iss`; парсер ссылок сверен с
`sora/app/lib/src/desktop/links.dart`; формат записи прокси — с бинарём
`sysproxy.exe` из ресурсов v2rayN (строки/usage). Сборка — фактически
прогнана (§3). Рантайм на Windows в этой песочнице невозможен: все
поведенческие утверждения — по коду, список живой проверки — §5.
Все ревьюируемые файлы на момент проверки совпадали с HEAD байт-в-байт
(контроль `git diff HEAD` — чисто).

---

## Вердикты по пунктам контракта (в начале, как заказано)

| Пункт | Вердикт |
|---|---|
| `--silent` | **ЗАКРЫТ** (замечания F6 — резиденция трея) |
| `--restore-proxy` | **ЧАСТИЧНО** — F1: перепутаны биты флагов, PAC-адрес на реальном формате записи теряется |
| Single-instance mutex | **ЗАКРЫТ** |
| Активация первого экземпляра вторым запуском | **ЗАКРЫТ** |
| `--wait-for <pid>` (попутно, в заголовке Program.cs) | **ЗАКРЫТ** |
| Автозапуск Run (реестр) | **ЧАСТИЧНО** — реестровый контракт байт-в-байт, но UI-опции в Client нет (F3) |
| `sora://` регистрация + импорт | **ЧАСТИЧНО** — Client-сторона и синтаксис .iss верны; на поставляемом сегодня exe регистрация мёртвая (F2), мелкий F4 |
| Адаптивная ОС-интеграция / локализация (§2) | **ЧАСТИЧНО** — в основном закрыто; F5, F6 |
| Сборка 5 проектов на HEAD (§3) | **ЗАКРЫТ** — 5/5 по 0 warnings / 0 errors |

**Общий вердикт: ЧАСТИЧНО.** Каркас контракта в новом Client построен
честно и в основном точно по v2rayN-семантике, но W1 нельзя принимать
как закрытый: F1 ломает восстановление PAC на пути деинсталляции,
F2 делает регистрацию `sora://` мёртвой для фактически поставляемого
продукта, F3 оставляет автозапуск без пользовательского управления.

---

## 1. Трассировка контракта инсталлер ↔ Client

Эталонные точки инсталлятора (`Sora.iss`): ярлык `{userstartup}` с
`--silent` (строка 70), `[UninstallRun] --restore-proxy --silent` с
`waituntilterminated` (строка 88), задача `autorun`, удаление
app-written Run-значения процедурой `RemoveOrphanedAutoRun` (a58894c).

### 1.1 `--silent` — ЗАКРЫТ, семантика v2rayN-пути соблюдена

`Program.Main` (`Program.cs:46-70`): `silent = HasArg(args, "--silent")`
(регистронезависимо, как v2rayN), `startHidden: silent && link == null`.
`ClientContext` при скрытом старте форму не показывает, создаёт
`NotifyIcon` с локализованным меню (`trayOpen`/`trayQuit`), двойной клик
и «Открыть» показывают окно (`ShowMainWindow` + `Activate`). Окно при
входе в Windows не всплывает — главное, чего ждёт ярлык автозапуска.
Обработка `--restore-proxy` стоит **до** mutex/DPI/Reconcile (как в
v2rayN), поэтому скрытый uninstall-вызов не зависит от GUI-состояния.

Замечания (F6, не блокируют пункт):
- Трей существует **только** в silent-старте. При обычном запуске трея
  нет вовсе, а закрытие окна (`MainForm.OnFormClosing`) завершает
  процесс, а не сворачивает в трей — резиденция v2rayN (X = HideForm в
  трей) не воспроизведена. Это зона W2, но расхождение семантики
  «tray start» фиксирую: silent-экземпляр, открытый и закрытый крестом,
  умирает вместо возврата в трей.
- Подключение к ядру в скрытом старте ленивое: `MainForm.Shown →
  OpenCore` сработает при первом показе окна. Для тонкого UI поверх
  отдельной службы ядра это допустимо (туннель живёт не в UI), но от
  v2rayN, где silent-старт полностью рабочий в фоне, отличается.
- Подпись трея `Text = "Sora Legacy"` — захардкоженная, не через ARB.

### 1.2 `--restore-proxy` — ЧАСТИЧНО (F1 — главная находка ревью)

Что совпало с эталоном `SysProxyHandle.ResetIEProxy` построчно:
- Подтверждение: без `--silent` — локализованный диалог
  `restoreProxyConfirm`, кнопка по умолчанию — **Button2 (No)**
  (`Program.cs:90-108`); деинсталлятор передаёт `--silent` — без диалога.
  Это та же LEGACY-L11-семантика, что v2rayN («только с явным
  подтверждением»), текст при этом точнее эталона (v2rayN спрашивает
  про «настройки по умолчанию», хотя восстанавливает записанные).
  Отказ пользователя → выход 0; успех/нет записи → 0; битая запись → 1 —
  коды совпадают с `Environment.ExitCode = ResetIEProxy() ? 0 : 1`.
  Честный отказ при недоступных строках: нет `Strings` → return 1,
  а не молчаливое изменение (Program.cs:98-100).
- Файл записи: `Path.Combine(Application.StartupPath,
  "user-wininet.json")` — тот же путь, что `Utils.GetPath(...)` v2rayN.
  Ключи JSON (`UserSettingsRecorded/Flags/ProxyServer/BypassList/
  PacUrl`) — поля `SysproxyConfig` как сериализует Newtonsoft. ✓
- Нет файла или `UserSettingsRecorded != true` → `true` без удаления;
  успешный replay → файл удаляется; битый JSON/флаги → `false` без
  удаления. Идентично эталону. Нормализация `"(null)" → ""` — та же,
  что `NormalizeQueryValue` эталона. ✓
- Восстанавливаются реестром HKCU `Internet Settings`: `ProxyEnable`
  (бит PROXY), `ProxyServer`, `ProxyOverride`, `AutoConfigURL`;
  уведомление `InternetSetOption(SETTINGS_CHANGED/REFRESH)` с
  перехватом `DllNotFound/EntryPointNotFound` — wininet есть на Win7+. ✓

**F1. Биты `AUTO_PROXY_URL` и `AUTO_DETECT` перепутаны местами.**
`SystemProxy.cs:32-35`:

```
FlagDirect = 1; FlagProxy = 2; FlagAutoDetect = 4; FlagAutoProxyUrl = 8;
```

Эталон в том же репозитории, `v2rayN/Handler/ProxySetting.cs:176-179`
(и стандарт WinINet `INTERNET_PER_CONN_FLAGS`):

```
PROXY_TYPE_DIRECT = 0x1; PROXY_TYPE_PROXY = 0x2;
PROXY_TYPE_AUTO_PROXY_URL = 0x4; PROXY_TYPE_AUTO_DETECT = 0x8;
```

Формат записи — **числовой**: в распакованном `sysproxy.exe` строк
`PROXY_TYPE_*` нет вообще (query/set работают с числом; значение по
умолчанию в `SysproxyConfig` — `"1"`; комментарий самого SystemProxy
это подтверждает). На числовом пути подмена не компенсируется:
`Restore()` проверяет `(flags & FlagAutoProxyUrl) != 0`, т.е. бит **8**
вместо бита **4**. Итог для пользователя, у которого до Sora стоял
только PAC (типичная запись `Flags = "5"` = DIRECT|AUTO_PROXY_URL;
также `"7"`): условие ложно → ветка `else` **удаляет `AutoConfigURL`**
— вместо восстановления uninstall молча сносит PAC-адрес пользователя.
Случаи с битом 8 (`"13"`, `"15"` — PAC+Detect) срабатывают случайно
правильно; токен-форма в `ParseFlags` внутренне согласована (parse и
проверка используют одну неверную константу) и потому работает, но
токенов реальный рекордер не пишет. Заявленная в комментарии
«named values … are restored exactly» для PAC неверна.

Незадекларированные/задекларированные деградации рядом:
- `AUTO_DETECT`: комментарий честно признаёт невосстановление бита
  (живёт только в бинарном `DefaultConnectionSettings`) — принимаю
  как честную деградацию; с учётом F1 формулировку надо переписать.
- RAS-подключения: эталонный `sysproxy.exe` применяет set и к RAS-
  записям (в бинаре есть `RasEnumEntries`), реестровый replay нового
  Client трогает только LAN-значения по умолчанию. В комментарии не
  упомянуто — недекларированная частичность, minor.
- Рекордера записи в новом Client нет (только replay-половина): пока
  пишет v2rayN — контракт цел; после смены stage записывать
  `user-wininet.json` обязан тот, кто ставит системный прокси (ядро?),
  в объёме W1-коммитов такого писателя нет. Открытый вопрос родителю,
  не дефект этих двух коммитов.

### 1.3 Single-instance mutex — ЗАКРЫТ

Имя: `Application.ExecutablePath.Replace("\\", "/")`
(`Program.cs:126`) — формула байт-в-байт как v2rayN
(`Utils.GetExePath()` + та же замена, `Program.cs` v2rayN
`IsDuplicateInstance`). Следствия: (а) с v2rayN **не конфликтует** при
сосуществовании — пути exe разные (`Sora.Legacy.exe` против
`sora_<target>.exe`), пространства имён разнесены путём, как задумано
эталоном («allow different locations to run»); (б) после переименования
Client в поставляемое имя mutex намеренно совпадёт — один экземпляр на
путь, что и требуется. Захват/пересоздание при squatting —
`TryEnterSingleInstance` (`Program.cs:130-141`) повторяет LEGACY-L11
эталона один в один, включая `IsOwnExecutableRunning` с fail-closed
(`catch → true`) и сравнением `MainModule.FileName` без учёта регистра.
Дескриптор удерживается статическим полем на жизнь процесса. ✓

### 1.4 Активация первого экземпляра — ЗАКРЫТ, способ Win7-совместим

Второй запуск: `ImportLink.Forward(link)` (если есть ссылка), затем
`TryActivateRunningInstance` (`Program.cs:167-181`): HKCU
`Software\Sora`, значение `WindowHwnd_<MD5(StartupPath)>`, десятичная
строка — ключ, имя и формат те же, что эталон (`Global.MyRegPath`,
`Utils.WindowHwndKey`, `Convert.ToString((long)Handle)`); публикация —
`form.Handle.ToInt64().ToString()` (`Program.cs:271`). Проверка
`IsWindow`, затем `ShowWindow(hwnd, 4)` (SW_SHOWNOACTIVATE, то же
число, что эталон) и `SwitchToThisWindow(hwnd, true)` — все три API
существуют со времён XP, никаких Win8+-вызовов. Публикация в новом
Client раньше и надёжнее эталона: в конструкторе контекста и на
`Shown`, а не только в `HideForm`. Диалог `alreadyRunning` — только
когда нет ссылки и активировать не удалось; текст RU байт-в-байт
совпадает с эталонным «Sora уже запущен.», ключ добавлен во все ARB.
Унаследованный от эталона риск (переиспользование HWND чужим окном
после смерти первого экземпляра) — паритетный, не регрессия.

### 1.5 Автозапуск Run — ЧАСТИЧНО (реестр закрыт байт-в-байт, опции нет)

Сверка с `c955461`/`a58894c` и текущим `Utils.cs:540-615`:

| Элемент | v2rayN (эталон) | Client (`AutoRun.cs`) | Итог |
|---|---|---|---|
| Ключ | HKCU `Software\Microsoft\Windows\CurrentVersion\Run` | та же строка `RunPath` | ✓ |
| Имя значения | `SoraAutoRun_<GetMD5(StartupPath())>` | `SoraAutoRun_` + MD5(UTF8(`Application.StartupPath`)), hex `x2` | ✓ байт-в-байт |
| Значение (вкл) | `"<exe>" --silent` | `Command` = `"` + `ExecutablePath` + `" --silent` | ✓ байт-в-байт |
| Значение (выкл) | `RegWriteValue(..., "")` → удаление значения | `DeleteValue(name, false)` | ✓ тот же конечный результат |
| Read-back (IsAutoRun) | ровно 3 формы: `exe`, `"exe"`, `"exe" --silent` | `IsEnabled`: те же 3 формы | ✓ c955461 не регрессировал |

`Reconcile` (`AutoRun.cs:89-106`) — новая, разумная семантика перехода:
существующее значение усыновляется в настройку (`AutoRun=true`) и
переписывается на текущий exe (значение от v2rayN в той же папке
отличается только именем файла — хэш папки совпадает); настройка
включена, а значения нет — записывается. Сканирование деинсталлятора
(a58894c: имя с префиксом `soraautorun_` + командная строка содержит
exe установки) такое значение опознаёт и удалит. ✓

**F3. Пользователь не может управлять автозапуском из нового Client.**
`launchAtLogin` в ARB есть, `ClientSettings.AutoRun` есть,
`AutoRun.SetEnabled` есть — но вызывающего UI нет: диалог Modes
(`MainForm.ChooseModes`) содержит только TUN/proxy/killSwitch/engine/
stack; `SetEnabled` вызывается исключительно из `Reconcile`. Хуже
того, выключить нельзя даже вручную: удалённое из реестра значение
при следующем старте воскреснет (`settings.AutoRun == true` →
`SetEnabled(true)`), а настройку в UI не снять. Комментарий в
`ClientSettings.cs:22` («The in-app "launch at sign-in" option»)
описывает опцию, которой в интерфейсе не существует. AUDIT-PARITY W1
требовал «нет автозапуска в настройках» закрыть — закрыта только
машинная половина.

### 1.6 `sora://` — ЧАСТИЧНО (Client готов; на поставляемом exe мёртво)

Инсталлятор (`5c4190e`, `Sora.iss:72-82`) — синтаксис Inno верен:
- `Root: HKA` при `PrivilegesRequired=lowest` и установке в
  `{localappdata}` разрешается в HKCU `Software\Classes\sora` —
  стандартная per-user регистрация, на Win7 работает; при админской
  установке уйдёт в HKLM, тоже работоспособно.
- Значение по умолчанию ключа — `URL:Sora`, пустой `URL Protocol` —
  обязательный маркер протокола присутствует.
- `DefaultIcon` = `"{app}\<exe>",0` — квотирование Inno разобрано
  верно.
- `shell\open\command` = `"{app}\<exe>" "%1"` — путь в кавычках, `%1`
  в кавычках, ссылка придёт одним аргументом. ✓
- `uninsdeletekey` на корневом ключе протокола снимает дерево при
  деинсталляции. ✓

**F2. Регистрация указывает на exe, который ссылку не обрабатывает.**
`{#MyAppExeName}` = `sora_<target>.exe` собирается из **v2rayN**
(`build/Build-WindowsProfiles.ps1` строит только `v2rayN.csproj`;
`Stage-Release.ps1` ждёт `sora_$WindowsTarget.exe` из его выхода).
`v2rayN/Program.cs` аргумент `sora://…` не обрабатывает вообще
(только `--silent/--tun/--wait-for/--restore-proxy`) — клик по ссылке
сегодня запустит/активирует v2rayN и **молча выбросит ссылку**.
Новый Client в сборочно-поставочный контур не входит нигде
(grep по `legacy/build`, `Stage-Release.ps1`, `Sora.iss` — пусто),
его exe — `Sora.Legacy.exe` (подтверждено сборкой §3). Комментарий
в .iss «the shipped executable, whose command-line contract …
handles the argument» сегодня **неверен**: обрабатывает Program.cs
другого, непоставляемого exe. Как и весь W1, регистрация оживёт при
смене stage без правок .iss — но заголовок коммита «on the shipped
executable» и комментарий создают ложное впечатление работающей
фичи уже сейчас; честная формулировка — «регистрация впрок, обработчик
появится со сменой stage». Классификация AUDIT-PARITY для W3 была
«решением владельца»; здесь владелец получил код, создающий видимость
закрытия, — потому ЧАСТИЧНО, а не ЗАКРЫТО.

Client-сторона импорта — при смене stage заработает, проверена глубоко:
- `ImportLink.FindArgument` находит аргумент `sora://` (без регистра);
  `Parse` покрывает обе формы эталона `links.dart`: `add/<url>`
  (verbatim при `://`, иначе percent-decode) и `add?url=&name=`
  (host == `add`); цель валидируется (http/https + host + запрет
  CRLF), ядро перепроверяет при `SaveSubscription`. ✓
- `sora://routing/add/…` сознательно отклоняется (в legacy-ядре нет
  routing-импорта) с показом `errSubFormat` — честный отказ вместо
  тихого проглатывания, задокументирован в комментарии. ✓
- Импорт идёт тем же запросом, что диалог добавления
  (`SaveSubscriptionRequest{Url, Name, AutoUpdate=true}` через
  `CoreService.ConnectAsync`, таймаут 8 c), ошибки — только
  `text.Error(key)`/`errSubFormat`/`errCore`. ✓
- Передача работающему экземпляру: `PendingImport_<hash>` в том же
  `Software\Sora`, опрос раз в 1 c (`pendingLinks`), значение удаляется
  при чтении — ссылка не теряется с уходящим вторым процессом даже при
  неудачной активации окна и даже в tray-режиме первого экземпляра. ✓
- Старт по ссылке не бывает скрытым (`startHidden` требует
  `link == null`) — пользователь видит результат. ✓

**F4 (minor). Двойной percent-decode имени в query-форме.**
`ImportLink.cs:56-60`: `ParseQuery` уже делает `UnescapeDataString`
по каждому значению, а `Parse` повторно вызывает
`Uri.UnescapeDataString(name)`. Имя вида `My%2520Sub` придёт как
`My Sub` вместо `My%20Sub`. У эталона Dart декодирование однократное.
Для fragment-ветки повторный decode как раз нужен (фрагмент
`Uri.Fragment` приходит экранированным) — исправление: декодировать
только fragment-ветку.

## 2. Адаптивная ОС-интеграция и локализация — ЧАСТИЧНО (в основном закрыто)

Capability checks вместо предположений о версии — соблюдены:
- DPI: `EnableDpiAwareness` — `OSVersion.Major < 6 → пропуск`, вызов
  `SetProcessDPIAware` в `try/catch (DllNotFound, EntryPointNotFound)` —
  байт-в-байт подход эталона v2rayN (`Program.cs:34-37`). Тем самым
  DPI-половина W4 для Client закрыта (был «нет вызова вообще»);
  PerMonitorV2 нет — как и у эталона, вне W1.
- Восстановление прокси намеренно сделано без внешних бинарей и без
  API новее Win7: реестр + `wininet.dll` (есть на всех целевых ОС),
  сбой уведомления не роняет restore. `Mutex`/MD5/`Process` — всё
  .NET Framework 4.8 / Win7 SP1, который инсталлятор и так гарантирует.
- Ошибки реестра/автозапуска/публикации HWND перехватываются, наружу —
  только `Trace` с **именем типа** исключения, не сообщением.

Локализация: новые ключи `alreadyRunning` и `restoreProxyConfirm`
добавлены во **все 31 ARB-файл** (проверено: валидный JSON, ключи на
месте, включая RU «Sora уже запущен.»); все диалоги новых путей —
через `Strings`; сырого `exception.Message` пользователю нет
(`ImportAsync`: `InvalidOperationException` трактуется как ключ и
маппится `Strings.Error`, неизвестное → `errCore`). Подтверждение
restore без локализации честно отказывает (return 1), а не показывает
английский текст.

**F5 (minor). Нет глобальных обработчиков исключений.** v2rayN ставит
`SetUnhandledExceptionMode(CatchException)` + `ThreadException` +
`AppDomain.UnhandledException` с записью в лог; новый `Program.cs`
не ставит ничего. Обработанные пути чисты, но необработанное
исключение UI-потока покажет пользователю сырой .NET-диалог со
стектрейсом — прямо против стандарта «сырого технического текста
наружу нет». Строки для такого диалога не нужно, нужен перехват+лог.

Мелочи: подпись трея «Sora Legacy» и fallback-пункт меню «Sora» при
`text == null` — захардкожены (F6); заголовки MessageBox «Sora» —
имя продукта, приемлемо.

## 3. Сборка — ЗАКРЫТ (5/5 по 0/0 на HEAD), с двумя оговорками о среде

`~/workspace/dotnet/dotnet build`, `TMPDIR=$HOME/workspace/.build-tmp`,
HEAD `5c4190e`:

| Проект | Итог |
|---|---|
| `legacy/Control/Sora.Legacy.Control.csproj` | ✅ 0 warnings / 0 errors |
| `legacy/Client/Sora.Legacy.Client.csproj` | ✅ 0 / 0 (выход — `Sora.Legacy.exe`, см. F2) |
| `legacy/tests/ClientInterop/ClientInterop.csproj` | ✅ 0 / 0 — на чистом `git archive HEAD` (см. оговорку 2) |
| `legacy/tests/ControlInterop/ControlInterop.csproj` | ✅ 0 / 0 |
| `legacy/tests/ServiceInterop/ServiceInterop.csproj` | ✅ 0 / 0 |

Оговорки (не код): (1) подтверждение получено тремя независимыми
прогонами — исходный последовательный цикл по всем пяти проектам
(полный restore, суммарно ~5 мин) завершился по каждому «Build
succeeded, 0 Warning(s), 0 Error(s)»; повторные сборки с `--no-restore
-p:UseSharedCompilation=false` дали тот же итог попоектно; в
промежуточных выводах мелькали транзиентные MSB3027 (повторная попытка
копирования при локе файла параллельной сборкой) и NU1301 (restore
при недоступной из песочницы api.nuget.org) — на финальный результат
прогонов не повлияли. (2) В общем рабочем
дереве **прямо сейчас** лежит чужой незакоммиченный WIP
(`legacy/Client/MainForm.cs`, `legacy/Client/Strings.cs` — трей-работа
соседнего отдела, половинчатая: `MainForm.cs` ссылается на ещё не
существующие `CreateTrayIcon`/`ShowFromTray`); сборка ClientInterop
из грязного дерева падает с 3 ошибками CS0103 — это не HEAD и не
предмет этого ревью, но родителю стоит знать, что дерево временно
красное. Ревьюируемые файлы W1 этим WIP не затронуты.

## 4. Мелочи: имена, константы, комментарии

- **F7. Контрактные строки не сведены в одно место.** `SoraRegistryPath
  = @"Software\Sora"` продублирована в `Program.cs:24` и
  `ImportLink.cs:19` (у эталона — одна `Global.MyRegPath`); литералы
  `--silent`/`--restore-proxy`/`--wait-for`/`sora://` разбросаны по
  трём файлам; флаги WinINet передекларированы в `SystemProxy` вместо
  сверки с существующим `ProxySetting.PerConnFlags` — это и есть
  корневая причина F1: вторая копия констант разъехалась с первой.
  Внутри Client дублирование `SoraRegistryPath` устранимо одной общей
  константой.
- Комментарии, которые врут коду:
  1. `Sora.iss:73-77` — «the shipped executable … handles the
     argument»: сегодня неверно (F2).
  2. `SystemProxy.cs:19-26` — «the named values … are restored
     exactly»: неверно для PAC (F1).
  3. `ClientSettings.cs:22-24` — «in-app option»: опции в UI нет (F3).
- Комментарии, которые точны и полезны: заголовок `Program.cs`
  (контракт + коды возврата; мелкая неточность — при ручном отказе от
  подтверждения тоже возвращается 0, как у эталона, в комментарии не
  оговорено), `AutoRun.cs` (происхождение имени/команды и ловушка
  c955461 описаны верно), `ImportLink.cs` (отказ routing задокументирован
  честно), объяснение squatting-пересоздания mutex.
- Имена новых типов (`AutoRun`, `SystemProxy`, `ImportLink`,
  `ClientContext`) и методов (`Reconcile`, `Forward`, `TakePending`,
  `Restore`) — предметные, стиль C# выдержан, nullable-дисциплина есть;
  тестов на новые классы (парсер ссылок, ParseFlags, IsEnabled) в
  коммитах нет — парсер при этом легко тестируем и является главным
  кандидатом на пин-тесты до смены stage.

## 5. Проверить на dev-машине (Windows) — не проверялось здесь

1. Win7 SP1 x86: установка → клик `sora://add/…` в браузере при
   непоставляемом пока stage Client под именем `sora_<target>.exe`:
   подписка добавляется; повторный клик при работающем экземпляре —
   импорт через pending + активация окна.
2. Uninstall при записанном PAC (`Flags="5"`): после фикса F1
   `AutoConfigURL` обязан вернуться; до фикса — воспроизводит F1.
3. `--silent` из `{userstartup}`: нет окна, есть трей; Quit из трея в
   dormant-режиме завершает процесс (путь `MainForm.OnFormClosing`
   при `core == null` статически не прогонялся).
4. Второй запуск при занятом mutex чужим процессом (squatting):
   пересоздание срабатывает, первый «чужой» процесс не активируется.

---

Итог одной строкой: контракт в Client реализован грамотно и по
эталонной семантике (mutex, активация, Run-значение, коды возврата —
байт-в-байт), но принимать W1 закрытым нельзя: F1 (PAC теряется при
`--restore-proxy`), F2 (`sora://` мёртв на поставляемом exe при живом
комментарии в .iss), F3 (автозапуск без UI) — после их закрытия и
пин-тестов на `ImportLink`/`SystemProxy` пункт можно пересматривать.
