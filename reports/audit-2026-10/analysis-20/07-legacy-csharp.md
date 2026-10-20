# Аналитик №7: legacy C#-клиент (WinForms)

Репозиторий: `~/workspace/bug-hunt/sora-legacy`, ветка `bugfix/audit-2026-10-19`.
Метод: только вычитка (C#-тулчейна нет), код не менялся. Охвачены: `legacy/v2rayN/v2rayN` (WinForms-клиент: формы, `UpdateHandle`, `HttpClientHelper`, запуск движка, IPC-жизненный цикл), `legacy/Client`, `legacy/Control`. Аудит и 5-pass review не дублируются — копал своё.

## Вердикт

Клиент находится в состоянии «двух клиентов в одном»: новая Happ-оболочка (тёмная, кастомный хром, подписки-аккордеоны) нашита поверх полностью сохранённой старой v2rayN-оболочки. Старая оболочка не удалена, а **спрятана флагами видимости** — в результате примерно треть C#-кода это зомби: ~35 недостижимых обработчиков меню/тулбара, 9+ мёртвых форм, ~1190 строк мёртвого лейаута в `MainForm.Community.cs`. Это главный источник слопа.

По надёжности — два высокоприоритетных UX-дефекта, оба про «что видит пользователь, когда что-то сломалось»:
1. **Нет watchdog'а за процессом Xray.** Если ядро упадёт после старта, интерфейс навсегда останется в состоянии «Подключено», а системный прокси — включённым. TUN-процесс такой колбэк имеет, Xray — нет. Асимметрия внутри одного жизненного цикла.
2. **Обновление подписок (и ручное, и автоматическое по таймеру) молча снимает системный прокси на всё время обновления** — пользователь остаётся без защиты без какого-либо предупреждения, только строка в журнале.

Остальное: несогласованные контракты обработки ошибок (`DownloadHandle`), три параллельные реализации горячих клавиш (одна мёртвая), дублирующиеся проверки состояния подключения, мёртвый метод с латентным багом, хрупкий загрузчик иконок без fallback (падение на старте при битых Assets).

Сильных сторон тоже хватает — ниже.

## Сильные стороны

- **Жизненный цикл процессов аккуратный там, где его делали осознанно.** `V2rayHandler.V2rayStopPid` защищён от PID-reuse (`IsKnownCoreProcess`, `Handler/V2rayHandler.cs:268-310`); `V2rayStart`/`V2rayStartNew` ждут 1 с и, если ядро упало сразу, показывают stderr пользователю, а не молчат (`Handler/V2rayHandler.cs:410-420`, `482-492`). `TunModeController` подписывается на `Exited` и корректно пробрасывает код выхода (`Tool/TunModeController.cs:68-74`).
- **Привилегированные операции с подтверждением.** `RestartCommunityAsAdministrator` требует явного согласия, если каталог доступен для записи без прав (`Forms/MainForm.Community.cs:869-914`); `--restore-proxy` в `Program.cs:18-33` без `--silent` спрашивает подтверждения.
- **Сторожевой флаг прокси сделан осмысленно.** `ProxyRestoreSentinelPath` + `RestoreSystemProxyIfInterrupted` (`Handler/UpdateHandle.cs:257-261`, `760-793`) закрывают окно «обновление убило процесс между снятием и восстановлением прокси».
- **`MainMsgControl.AppendText` потокобезопасен** (очередь + flush-таймер, `Forms/MainMsgControl.cs:50-95`) — фоновые потоки могут писать в лог без Invoke-танцев.
- **Новый сервисный клиент (`legacy/Client` + `legacy/Control`) написан заметно чище старого:** `SessionRequests` сериализует команды через bounded channel с DropOldest, отмена вытесняет устаревшие планы (`Control/SessionRequests.cs:26-56`); `LogsPage` — revision-guard'ы и корректная отмена (`Client/LogsPage.cs:149-202`); `CoreService.ConnectAsync` проверяет, что пайп принадлежит именно сервису `SoraLegacyCore` в состоянии RUNNING (`Control/CoreService.cs:46-58`).
- **Диалоги Happ аккуратны в деталях:** `AccessibleName`/`AccessibleRole` почти везде, Esc/Enter привязаны (`CreateSoraDialog`), автоназвание подписки не затирает ручной ввод (`Forms/MainForm.SoraDialogs.cs:183-197`).

## Слоп / проблемы

### HIGH

**H1. Нет наблюдения за смертью процесса Xray — UI врёт «Подключено»**
`V2rayHandler` нигде не подписывается на `Process.Exited`; после стартовой проверки (`Handler/V2rayHandler.cs:410`, `482` — `WaitForExit(1000)`) `IsRunning` больше никто не опрашивает. `UpdateCommunityConnectionState` (`Forms/MainForm.Community.cs:620-642`) вызывается только по действиям пользователя. Если xray упадёт через 5 минут после подключения: orb останется «зелёным» с растущим таймером (`HappConnectionControl.OnPaint`), системный прокси останется включённым, трафик — без VPN. Для TUN аналогичная ситуация закрыта: `Exited` → `CommunityTunExited` (`Forms/MainForm.Community.cs:948`) обновляет состояние и пишет в журнал. `StatisticsHandler` опрашивает gRPC-канал ядра, но его смерть в UI не транслируется (`Handler/StatisticsHandler.cs:94-140`). Состояние «обрыв IPC» для пользователя сегодня — это отсутствие состояния.

**H2. Обновление подписок снимает системный прокси на время обновления — молча**
`Handler/UpdateHandle.cs:253-275`: при `sysProxyType == ForcedChange` и `blProxy == false` ставит `ForcedClear`, ждёт 3 с, качает все подписки, восстанавливает в `finally`. Весь Happ-путь вызывает его с `blProxy: false` (`Forms/MainForm.HappPages.cs:745`), включая **автоматический шедулер** `StartSoraSubscriptionScheduler` (`Forms/MainForm.HappPages.cs:761-790`, тик каждые 30 с, интервал по умолчанию 720 мин). Итог: раз в 12 часов (или по ручному «Обновить») подключённый пользователь на время обновления — без прокси и без защиты, без модального предупреждения и без индикатора; единственное свидетельство — строка `[SUBSCRIPTION]` в журнале. Вариант «обновить через прокси» (`blProxy: true`) существует в коде, но в живом UI недостижим (только мёртвые `menuUpdateSubViaProxy_Click`, `tsbSubUpdateViaProxy_Click`). Fail-closed восстановление через sentinel есть, но окно утечки трафика — нет.

### MEDIUM

**M1. ~1190 строк мёртвого лейаута: `ApplyCommunityLayout` никогда не вызывается**
`Forms/MainForm.Community.cs:43` — метод определён, вызовов ноль (конструктор зовёт `ApplyHappLayout`, `Forms/MainForm.cs:38`). Вместе с ним мертвы: `BuildCommunitySidebar` (:251), `BuildCommunityHeader` (:325), `BuildCommunityWorkspace` (:383), `CreateNavigationButton` (:477), `CreateHeaderButton` (:527), `DrawCommunityGroupTab` (:549), `ShowCommunityBackupMenu` (:308), `BuildCommunityEmptyState` (:164), `CreateActionButton` (:502 — все 5 вызовов только из мёртвых билдеров). Файл при этом содержит живой код (TUN-жизненный цикл, `UpdateCommunityConnectionState`) — живое и мёртвое перемешаны в одном partial без пометок. Побочный эффект: `UpdateCommunityEmptyState` (:1003) вызывается из живых мест (`Forms/MainForm.cs:297`, `Forms/MainForm.Happ.cs:146`), но `_communityEmptyState` создаётся только в мёртвом `ApplyCommunityLayout` → вызовы — гарантированные no-op; Happ-путь использует отдельный `BuildHappEmptyState` (`Forms/MainForm.Happ.cs:641`) — два параллельных механизма «пустого состояния», один мёртв. Вторая половина `UpdateCommunityConnectionState` (:627-641 — `_communityConnectionStatus`, `_communityConnect/_communityTun/_communityDisconnect`) в Happ-пути тоже недостижима: эти контролы строятся только мёртвым `BuildCommunityHeader`, везде null-guard'ы.

**M2. Мёртвые формы — дубли старой оболочки (9+)**
Живой UI их не создаёт; замены указаны:
- `SubSettingForm` + `SubSettingControl` → заменена `ShowSoraSubscriptionEditor` (`Forms/MainForm.HappPages.cs:42-155`); инстанцируется только в мёртвом `tsbSubSetting_Click` (`Forms/MainForm.cs:1524`).
- `MsgFilterSetForm` → заменён строкой поиска (`WireHappSearch`, `Forms/MainForm.Happ.cs:627-634`); только в мёртвом `menuServerFilter_Click` (`Forms/MainForm.cs:811`).
- `AddServerForm`, `AddServer2Form`, `BaseServerForm`, `ServerTransportControl` → заменены `ShowSoraServerEditor` (`Forms/MainForm.SoraDialogs.cs:449`); `ShowServerForm` (`Forms/MainForm.cs:651`) вызывается только из мёртвых `menuAdd*Server_Click` (`Forms/MainForm.cs:750-1100`).
- `OptionSettingForm` → заменена страницей настроек Happ (`BuildHappSettingsPage`, `Forms/MainForm.HappPages.cs:22`); только в мёртвом `tsbOptionSetting_Click` (`Forms/MainForm.cs:957`).
- `GroupSettingForm` + `GroupSettingControl` → **замены нет**: вкладки групп убраны из UI (`scBig.Visible=false`), но `_groupId`-фильтрация жива — настройка групп стала недоступна вообще.
- `RoutingSettingForm`, `RoutingRuleSettingForm`, `RoutingRuleSettingDetailsForm` → заменены `BuildHappRoutingPage`; цепочка начинается в мёртвом `tsbRoutingSetting_Click` (`Forms/MainForm.cs:967`).
- `GlobalHotkeySettingForm` → **замены нет**: `RegisterGlobalHotkey` по-прежнему вызывается в `MainForm_Shown` (`Forms/MainForm.cs:141`), сохранённые хоткеи работают, но UI для их настройки исчез из приложения.
- `QRCodeControl` — особый случай: жив в дизайнере (`scServers.Panel2`, `Forms/MainForm.Designer.cs:160`), `lvServers_Click` (`Forms/MainForm.cs:640-647`, всё ещё привязан в дизайнере) вызывает `qrCodeControl.showQRCode(...)` при каждом клике — но панель лежит в скрытом `scServers` (`Forms/MainForm.Happ.cs:101`), т.е. код работает в невидимый контрол. Клик по серверу молча «ничего не показывает».

**M3. ~35 обработчиков-зомби скрытого тулбара и контекстного меню**
`tsMain.Visible = false` (`Forms/MainForm.Happ.cs:101`), `lvServers.ContextMenuStrip = null` (`Forms/MainForm.Happ.cs:317`), `notifyMain.ContextMenuStrip` заменён на `BuildSoraTrayMenu` (`Forms/MainForm.Happ.cs:94`). Из живых Happ-путей вызываются только 8 старых обработчиков (`menuExport2ShareUrl_Click`, `menuSetDefaultServer_Click`, `menuAddVlessServer_Click`, `tsbSubUpdate_Click`, `tsbSubSetting_Click`, `tsbRoutingSetting_Click`, `tsbOptionSetting_Click`, `menuExit_Click`). Остальные — `menuAddVmessServer_Click`, `menuPingServer_Click`/`menuTcpingServer_Click`/`menuRealPingServer_Click`/`menuSpeedServer_Click`, `menuRemoveDuplicateServer_Click`, `menuClearStatistic_Click`, `menuCopyServer_Click`, `menuExport2ClientConfig/ServerConfig/SubContent_Click`, `menuMoveTop/Up/Down/Bottom_Click`, `tsbCheckUpdate*` (5 шт.), `tsbTestMe_Click`, `tsbReload_Click`, `tsbClose_Click`, `tsbQRCodeSwitch_CheckedChanged`, `tsbBackupGuiNConfig_Click`/`tsbRestoreGuiNConfig_Click`, `tsbGroupSetting_Click`, `tsbGlobalHotkeySetting_Click`, `menuKeepClear/Global/KeepNothing_Click`, `menuUpdateSubscriptions/UpdateSubViaProxy_Click`, `tsbSubGroupUpdate(ViaProxy)_Click`, `tsbLanguageDef/ZhHans_Click`, `tsbAbout/V2rayWebsite_Click`, `tabGroup_SelectedIndexChanged`, `menuMoveToGroup_Click` (пустое тело) — привязаны в `Forms/MainForm.Designer.cs` к невидимым/отсоединённым контролам и недостижимы.

**M4. Несогласованные контракты ошибок в `DownloadHandle`**
- `DownloadStringAsync` / `DownloadFileAsync`: возвращают `null`, поднимают событие `Error` **и** пишут в лог (`Handler/DownloadHandle.cs:113-151`).
- `DownloadDataAsync`: событие `Error` поднимает, но запись в лог закомментирована (`Handler/DownloadHandle.cs:103-111`).
- `UrlRedirectAsync`: вообще без try/catch — исключения наружу (`Handler/DownloadHandle.cs:154-172`); метод при этом мёртв (см. M6).
Вызывающий код вынужден угадывать, по какому из трёх каналов пришла ошибка.

**M5. `SpeedtestHandler.RunSpeedTestAsync` без try/finally — утечка временного процесса**
`Handler/SpeedtestHandler.cs:308-344`: временный xray для замера (`pid`) убивается строкой `if (pid > 0) _v2rayHandler.V2rayStopPid(pid)` в конце метода. Любое исключение в цикле (отмена, обрыв сети в `DownloadDataAsync`) — процесс остаётся висеть навсегда. В том же файле `RunRealPing` (`:160-206`) обёрнут в try/finally образцово — несогласованность внутри одного файла.

**M6. Мёртвый `UrlRedirectAsync` с латентным багом**
`Handler/DownloadHandle.cs:154` — ноль вызовов во всём репозитории. Плюс баг: `response.StatusCode.ToString() == "Redirect"` — имени `Redirect` в `HttpStatusCode` нет (302 — это `Found`), метод никогда бы не вернул URL даже если бы вызывался.

**M7. Три параллельные реализации горячих клавиш**
- `lvServers_KeyDown` (`Forms/MainForm.cs:683-737`) — мёртв: отвязан в Happ-пути (`Forms/MainForm.Happ.cs:327-328`), но тело живёт.
- `SoraServersKeyDown` (`Forms/MainForm.SoraDialogs.cs:942-964`) — жив, привязан к `lvServers`.
- `HandleHappShortcut` (`Forms/MainForm.Happ.cs:1197-1221`) — жив, через `KeyPreview` на форме.
Ctrl+V/C, Enter, Delete обрабатываются в двух живых местах с пересекающейся логикой. Рядом: дублированный guard `if (e.Column < 0) return;` в начале **и** в конце `lvServers_ColumnClick` (`Forms/MainForm.cs:438` и `:483`); тройное дословное дублирование проверки «подключено ли» (`Forms/MainForm.Happ.cs:678-679`, `:1133-1134`, `Forms/MainForm.SoraDialogs.cs:773-774`) — просится в один хелпер `IsCommunityConnected()`.

**M8. `HappIconLoader` без fallback — падение на старте при битых Assets**
`Forms/HappThemeControls.cs:21-55`: `new Bitmap(path)` бросит `FileNotFoundException`/`ArgumentException`, если `Assets/Phosphor/<name>-bold.png` или `Assets/Sora/sora-logo-white.png` отсутствует/повреждён. Первый же вызов — `BuildHappTitleBar` → `CreateWindowButton` (`Forms/MainForm.Happ.cs:152-164`) в `ApplyHappLayout`, т.е. приложение не стартует вообще, без диагностики. Для portable-копии под Win7 (флешка, кривой распаковщик) — реальный сценарий.

### LOW

**L1. God-форма.** `MainForm` — 5 partial-файлов, ~6000 строк суммарно; бизнес-логика (подписки, TUN, прокси, хоткеи, статистика) в обработчиках кликов и приватных методах формы.

**L2. Пустые `catch {}` без комментария:** `Forms/MainForm.cs:208` (`ts_Click`), `Forms/MainForm.cs:1192` (`AppendText` — глотает вообще всё), `Handler/ShareHandler.cs:658`, `Handler/DownloadHandle.cs:324` (`SocketCheck`). `Program.cs:79,138` и `Tool/Logging.cs:64,68` — оправданы.

**L3. `UI.ShowError` неотличим от warning.** `Tool/UI.cs:22-25`: иконка `"warning"`, заголовок «Не удалось выполнить действие» — ошибка выглядит как предупреждение.

**L4. Рассинхрон orb в Error-состоянии.** `HappConnectionControl` рисует «ПОВТОРИТЬ» (`Forms/HappThemeControls.cs:178-181`), а `AccessibleName` для `Error` падает в ветку «Подключиться» (`:85-87`).

**L5. legacy/Client: `RenderSubscriptions` пересоздаёт все карточки на каждый тик пинга.** `Client/MainForm.cs` — `Probe` → `Progress<ProbeResult>` → `RenderSubscriptions()` → Dispose+создание всех `SubscriptionCard` заново на каждый ответ. При подписке на 50 серверов — 50 полных перерисовок списка за один пинг-проход (мерцание, O(N²)).

**L6. legacy/Client: единичный сбой poll = «ядро мертво».** `poll.Tick` (`Client/MainForm.cs`): любой `catch` → `error.Text = text["errCore"]; retry.Visible = true`, хотя соединение может быть живо (транзиентный таймаут 5 с).

**L7. Кастомный хром и старые ОС.** `FormBorderStyle.None` + собственный хиттест ресайза (`Forms/MainForm.Happ.cs:1206-1218`), свои кнопки свернуть/развернуть/закрыть. На Win7: нет Aero Snap, нет системного меню окна, `ToggleHappMaximize` не знает про мультимониторные таскбары. Работает, но каждая такая деталь — ручной велосипед вместо системного поведения.

**L8. Несогласованность про самообновление.** `CheckUpdateGuiN` говорит «самообновление отключено» (`Handler/UpdateHandle.cs:133-136`), а мёртвый `tsbCheckUpdateN_Click` (`Forms/MainForm.cs:1433`) открывает браузер на releases. Живому пользователю пункт недоступен — только как артефакт.

## Ранжированные рекомендации

1. **(H1) Подписаться на смерть ядра.** В `V2rayHandler` добавить `EnableRaisingEvents` + `Exited` (как в `Tool/TunModeController.cs:68-74`), в обработчике — `ShowMsg(true, …)` и событие для формы; в `MainForm` — перевод `_happConnection.State` в `Error`, обновление через `UpdateCommunityConnectionState`, немодальное уведомление. Это закрывает «что видит пользователь при обрыве IPC» для главного процесса.
2. **(H2) Не снимать системный прокси при обновлении подписок.** Если `sysProxyType == ForcedChange` — качать через собственный прокси (`blProxy: true`, код уже есть) либо пропускать автообновление шедулером и показывать явный бейдж «обновление подписок — VPN приостановлен» на время ручного. Сейчас это тихая утечка трафика.
3. **(M1–M3) Удалить зомби-код одним проходом:** `ApplyCommunityLayout` и всё достижимое только из него (`Forms/MainForm.Community.cs:43-619` за вычетом живых методов TUN/состояния); 9 мёртвых форм + их Designer/Resx; отвязанные пункты меню и тулбар в `Forms/MainForm.Designer.cs` вместе с ~35 обработчиками. Ожидаемый эффект: минус ~2500-3000 строк, ноль поведенческих изменений.
4. **(M4) Унифицировать контракт `DownloadHandle`:** один канал ошибок — либо исключения, либо `(result, error)`. Убрать двойную сигнализацию «return null + событие + лог».
5. **(M5) Обернуть `RunSpeedTestAsync` в try/finally** по образцу `RunRealPing` из того же файла.
6. **(M6) Удалить `UrlRedirectAsync`** (`Handler/DownloadHandle.cs:154-172`).
7. **(M7) Одна реализация хоткеев и один хелпер `IsCommunityConnected()`.** Удалить `lvServers_KeyDown`; оставить `SoraServersKeyDown` + `HandleHappShortcut` с явным разделением (контролы списка vs страница).
8. **(M8) Fallback в `HappIconLoader.Load`:** при отсутствии файла — генерировать плейсхолдер-иконку в памяти и писать в лог, а не ронять старт приложения.
9. **(M2-доп) Вернуть UI для хоткеев или удалить `GlobalHotkeySettingForm` вместе с регистрацией.** Сейчас фича без интерфейса: либо строка в Happ-настройках, либо честно выкинуть. То же для `GroupSettingForm` (группы) — либо вернуть управление группами, либо убрать `_groupId`-механику.
10. **(L5, L6) legacy/Client:** обновлять пинг точечно в существующей карточке вместо полного `RenderSubscriptions`; в `poll.Tick` показывать `errCore` только после N подряд сбоев.
11. **(L2, L3) Гигиена:** пустые `catch` — либо с комментарием «почему ок», либо с `Utils.SaveLog`; `UI.ShowError` — иконка ошибки, а не warning.

## Честные оговорки

- C#-тулчейна в окружении нет: «мёртвый код» определялся статическим поиском вызовов по всем `.cs`, включая `*.Designer.cs`. Рефлексия/динамические вызовы в этих местах не используются (проверено), но 100% гарантии без компиляции нет.
- Поведение Win7 (Aero Snap, DWM) оценено по коду, не прогоном.
- `legacy/Control` + `legacy/Client` (сервисная архитектура) — заметно чище WinForms-клиента; глубоких проблем там не найдено, только L5/L6.
- Дублирования с аудитом/5-pass review нет: их правки (PID-reuse, digest-check, sentinel прокси, mutex) на месте и не пересекаются с находками выше.
