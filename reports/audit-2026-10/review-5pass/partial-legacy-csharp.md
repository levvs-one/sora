# 5-проходное ревью: C#-клиент sora-legacy (зона LC)

Дата: 2026-10-19. Ветка: `bugfix/audit-2026-10-19` (не переключалась, не пушилась).
Рабочая копия: `~/workspace/bug-hunt/sora-legacy`.

## Охват

**105 `.cs`-файлов × 5 проходов = 525 точек покрытия. Непокрытых файлов нет.**

- Полностью прочитаны: все `Handler/*` (10), все `Tool/*` (9), все `Base/*` (5),
  `Global.cs`, `Program.cs`, `Forms/MainForm.cs` (+`.Happ`, `.HappPages`, `.SoraDialogs`, `.Community`),
  все диалоги настроек (`AddServerForm`, `AddServer2Form`, `OptionSettingForm`, `SubSettingForm`,
  `SubSettingControl`, `GlobalHotkeySettingForm`, `ServerTransportControl`,
  `RoutingSettingForm`, `RoutingRuleSettingForm`, `RoutingRuleSettingDetailsForm`,
  `MainMsgControl`, `MsgFilterSetForm`, `GroupSettingForm`, `GroupSettingControl`,
  `QRCodeControl`, `BaseForm`, `BaseServerForm`), `ShareHandler`, `UpdateHandle`,
  `Mode/Config.cs`, весь `Client/` (6), весь `Control/` (3), все `tests/` (3).
- Ским + точечный grep: `*.Designer.cs`, `Properties/*`, `Resx/*.Designer.cs` (генерированные),
  мелкие `Mode/*`-енумы, `Mode/V2rayConfig.cs`.
- `app/*.dart` (4 файла) — только глазами: это генерированные protobuf-стабы
  (`core_control.pb*.dart`), рукописного Dart-кода в зоне нет, править нечего.
- Дополнительно: механическая проверка баланса скобок по всем 105 файлам
  (ловля «метод-в-методе» после правок аудита без тулчейна) — кроме одного
  известного случая поломок не найдено.
- C#-тулчейна нет, компиляция невозможна — каждая правка вычитана вручную
  (синтаксис, типы, using, скобки, async/await), баланс скобок проверен скриптом.

## Находки по проходам

### Проход 1 — Безопасность

**R5-LC-1-1 (High, исправлено).** `Handler/DownloadHandle.cs:63` — `DownloadDataAsync`:
`HttpClient` и `CancellationTokenSource` не освобождались (NEW-R2 починил только
`DownloadFileAsync`). Каждый спидтест = висящий сокет до финализатора.
Сценарий: многократные спидтесты → истощение сокетов/портов.
Исправлено: `using` для клиента и CTS — коммит `769ae3b`.

**R5-LC-1-2 (High, исправлено).** `Base/HttpClientHelper.cs:26` — `GetInstance()`:
локальная переменная `httpClientHelper` тенила статическое поле, присваивания полю
не было. Синглтон не работал никогда: каждый вызов создавал новый
`HttpClient`+`HttpClientHandler`. Сценарий: частые `GetAsync`/`PutAsync` → сокеты
в TIME_WAIT, деградация сети.
Исправлено: настоящий `Lazy<T>`-синглтон — коммит `769ae3b`.

**R5-LC-1-3 (Medium, спека).** `Tool/Utils.cs:DeepCopy` — `BinaryFormatter`.
Десериализуется свой же граф (риск эксплуатации низкий), но паттерн запрещённый
и в .NET 8+ удалён. Спека: заменить на JSON-roundtrip через `Utils.ToJson`/`FromJson`
(уже есть в кодовой базе).

**R5-LC-1-4 (Low, спека).** `ConfigHandler.RemoveVmessItem` / `DeleteReplacedSoraCustomFiles`:
`File.Delete(Utils.GetConfigPath(item.address))` без проверки на traversal.
`address` правит пользователь (импорт). Defense-in-depth: тот же StartsWith-гарды,
что уже есть в `AddServer2Form.btnEdit_Click`, вынести в `Utils.IsPathInsideConfigDir`
и переиспользовать.

**R5-LC-1-5 (Low, спека).** `Handler/SysProxyHandle.cs` — `sysproxy.exe` извлекается
из ресурсов в `guiTemps` внутри каталога приложения при каждом старте (TOCTOU-окно
между извлечением и запуском; при per-user установке каталог доступен для записи).
Спека: проверять Authenticode-подпись извлечённого exe или держать его в ACL-закрытом
каталоге.

Проверено и чисто: `OpenSoraCommunityLink` (только хардкод-URL), `SoraMarkdownView`
(валидация схемы http/https в `TryGetSafeUrl`), `btnEdit_Click` (whitelist расширений
+ запуск только через явный `notepad.exe` без `UseShellExecute`), `TunModeController`
(фиксированные пути, типизированные аргументы), `Control/CoreService` (проверка PID
пайп-сервера через SCM до handshake — fail-closed).

### Проход 2 — Корректность

**R5-LC-2-1 (High, исправлено).** `Tool/Utils.cs:426` — `IsNumberic` всегда возвращал
`true`: `ToInt` глотает исключения и возвращает 0, `catch` недостижим.
Вся валидация портов (`AddServerForm:196`, `OptionSettingForm:188,262-267`) не работала —
в порт можно было вбить мусор. Исправлено: `int.TryParse` — коммит `1c6ff01`.
Заодно **R5-LC-2-2**: `IsIP` проверял `cidr[0]` вместо `cidr[1]` (префикс CIDR не
валидировался вообще) — исправлено там же.

**R5-LC-2-3 (High, исправлено).** `Handler/ConfigHandler.cs:LoadConfig` — NRE при
`"vmess": null` в `guiNConfig.json` (строка `config.vmess.Count`) и при
`"inbound": []` (`config.inbound[0]` в десятках мест: `OptionSettingForm`,
`V2rayConfigHandler`, `HappPages`, `MainMsgControl`). Сценарий: ручное редактирование
конфига → падение при старте. Исправлено: нормализация (`vmess ??= new`,
`RemoveAll(null)`, пустой `inbound` → дефолтный socks 10808) — коммит `1c6ff01`.

**R5-LC-2-4 (Medium, исправлено).** `Mode/Config.cs:227` — `GetLocalPort`:
`inbound.FirstOrDefault(...).localPort` — NRE, если socks-inbound отсутствует.
Исправлено: `?.` + fallback `10808` — коммит `1c6ff01`.

**R5-LC-2-5 (Medium, исправлено).** `ConfigHandler.AddServerCommon`:
`vmessItem.sort = maxSort++` — новому серверу присваивался текущий максимум,
коллизия `sort` с существующим. Исправлено: `maxSort + 1` — коммит `1c6ff01`.

**R5-LC-2-6 (Medium, исправлено).** `Enum.Parse` без `TryParse` на тексте ComboBox —
`AddServerForm:238`, `AddServer2Form:91`, `OptionSettingForm.SaveCoreType:318`.
При ручном вводе (если стиль комбо позволяет) — необработанное исключение.
Исправлено: `Enum.TryParse` с сохранением прежнего поведения — коммит `1c6ff01`.

**R5-LC-2-7 (Medium, исправлено).** `SubSettingControl.BindingSub:43-44`,
`GroupSettingControl.BindingSub` — `subItem.remarks.ToString()` / `url.ToString()`:
NRE при null (поле необязательное в JSON). Исправлено: null-safe `TrimEx()` —
коммит `1c6ff01`.

**R5-LC-2-8 (Low, исправлено).** `Forms/MainForm.cs:1201` — `notifyMsg`:
`msg.Substring(1, 63)` терял первый символ уведомления. Исправлено: `(0, 63)` —
коммит `1c6ff01`.

**R5-LC-2-9 (Medium, исправлено).** `Forms/MainForm.cs:1540` —
`tsbSubGroupUpdate_Click` (кнопка «обновить без прокси») передавал `blProxy: true`
— copy-paste с `tsbSubGroupUpdateViaProxy_Click`. Подписки всегда обновлялись через
прокси. Исправлено: `false` — коммит `1c6ff01`.

**R5-LC-2-10 (Medium, исправлено).** `RoutingSettingForm.menuRemove_Click` и
`RoutingRuleSettingForm.menuRemove_Click`: цикл по `lvSelecteds` вызывал
`RemoveAt(index)` (первый выбранный) вместо `RemoveAt(lvSelecteds[k])` —
при мультивыборе удалялись НЕ ТЕ правила (N первых подряд). Исправлено — коммит `1c6ff01`.

**R5-LC-2-11 (Low, исправлено).** `Handler/ShareHandler.cs:444` —
`ResolveVmess4Kitsunebi`: `if (arr21.Length != 2 || arr21.Length != 2)` — опечатка,
вторая проверка должна быть `arr22`; `arr22[1]` падал с IndexOutOfRange на
`method:pass@host` без порта. Исправлено — коммит `1c6ff01`.

**R5-LC-2-12 (Low, исправлено).** `AddServer2Form.btnEdit_Click:162` —
`Path.GetFullPath` вне try: мусорные символы в имени файла → необработанное
исключение. Исправлено: try/catch с диалогом — коммит `1c6ff01`.

**R5-LC-2-13 (Low, исправлено).** `Tool/FileManager.cs:68` — `throw ex;` вместо
`throw;` в `NonExclusiveReadAllText`: терялся стек. Исправлено — коммит `1c6ff01`.

**R5-LC-2-14 (Low, исправлено).** `Handler/UpdateHandle.cs:561` —
`responseHandler`: `gitHubReleases!.First()` — пустой `[]` от API → исключение.
Исправлено: `FirstOrDefault` + явная ошибка — коммит `e29b945`.

**R5-LC-2-15 (Low, исправлено).** `Forms/GlobalHotkeySettingForm.cs` — жёсткая
привязка к 4 текстбоксам (`txtGlobalHotkey{k}`, индекс из имени): 5-е значение
`EGlobalHotkey` роняло бы форму. Добавлены bounds/null-гарды — коммит `e29b945`.

**R5-LC-2-16 (Medium, исправлено).** `RoutingRuleSettingForm.menuImportRulesFromUrl_Click` —
`RefreshRoutingsView()` (трогает ListView) вызывался из `Task.Run`-потока после
скачивания → cross-thread `InvalidOperationException`, правила не обновлялись.
Исправлено: возврат в UI-поток через `BeginInvoke` + гварды `IsDisposed/Disposing` —
коммит `769ae3b`.

**R5-LC-2-17 (Medium, спека).** `Handler/V2rayConfigHandler.cs:972` —
`GenerateClientCustomConfig` (clash): `FindIndex(t => t.Contains("port:"))` матчит
`socks-port:` первым → удаляется не та строка, затем добавляются обе → **дубль
ключа `port:` в YAML**. Спека: матчить `t.TrimStart().StartsWith("port:")`
или regex `^\s*port:`.

**R5-LC-2-18 (Medium, спека).** `Forms/MainForm.cs:SetDefaultServer` (1017) и цикл
подсветки активного сервера: позиционная связь `lstVmess[k]` ↔ `lvServers.Items[k]`
без сверки границ. `RefreshServers` обновляет `lstVmess` синхронно, а
`RefreshServersView` — через `BeginInvoke`: в окне рассинхрона `Items[k]` бросает
`ArgumentOutOfRangeException` (сценарий: смена группы с 2 серверов на 50).
Спека: маппить строки по `indexId`, а не по позиции; добавить bounds-check.

**R5-LC-2-19 (Critical, исправлено).** `Forms/MainForm.Community.cs` — правка аудита
без тулчейна оставила `IsAppDirectoryUserWritable()` вложенным ВНУТРЬ тела
`RestartCommunityAsAdministrator()` между двумя `catch`: модификаторы
`private static` внутри метода + orphaned `catch` — **файл не компилировался,
проект не собирался вообще**. Исправлено: метод вынесен на уровень класса,
второй `catch` присоединён к своему `try`; баланс скобок и структура проверены —
коммит `a047e17`.

**R5-LC-2-20 (Low, спека).** `Handler/ShareHandler.cs:ResolveSocks` — пустая ветка
`if (indexS > 0) { }` + закомментированный код. Спека: убрать.

### Проход 3 — Живучесть

**R5-LC-3-1 (Medium, исправлено).** `Base/HttpClientHelper.cs` —
`DownloadFileAsync`/`DownloadDataAsync4Speed`: бессмысленные аллокации
`new byte[read]` + `buffer.ToList().CopyTo(...)` на каждый чанк (в speed-варианте
`data` вообще мёртвая). Исправлено: прямая запись/подсчёт — коммит `769ae3b`.
Там же: `using` для всех `HttpResponseMessage` (включая `PutAsync`).

**R5-LC-3-2 (Low, исправлено).** Утечки IDisposable: `Utils.Ping` (`Ping`),
`Utils.GetMD5` (`MD5`), `Utils.ScanScreen` (`Bitmap target` в цикле — до 10 GDI-объектов
на экран за проход). Исправлено: `using` — коммит `769ae3b`.

**R5-LC-3-3 (Medium, исправлено).** `Forms/MainMsgControl.cs:231` — пользовательский
regex-фильтр журнала без таймаута: злонамеренный/случайный ReDoS-паттерн вешает UI
на каждой перерисовке истории (до 1000 строк × `IsMatch`). Исправлено: таймаут 2с
+ `RegexMatchTimeoutException` → fail-open (показать строку) — коммит `769ae3b`.

**R5-LC-3-4 (Low, исправлено).** `Tool/SoraText.cs` — `CurrentLanguage` читал реестр
при КАЖДОМ `Translate` (сотни чтений при построении UI). Исправлено: кэш +
`RefreshLanguage()`-инвалидация, подключённая к `Select()` и
`MainForm.SetCurrentLanguage()` — коммит `769ae3b`.

**R5-LC-3-5 (Low, спека).** `MainForm.HappPages/ShowSoraImportDialog` — `AnalyzeSoraImport`
(3 JSON-парсинга) на каждое нажатие клавиши при `MaxLength=4MB` → фриз UI на больших
вставках. Спека: дебаунс 300–500мс + парсинг в фоне.

**R5-LC-3-6 (Low, спека).** `Forms/MainForm.cs:1034,1040` (`SetDefaultServer`) и `:408`
— `new Font(...)` на каждую строку при каждом обновлении списка, старый шрифт не
диспоузится (GDI-лики при частых обновлениях/тестах скорости).

**R5-LC-3-7 (Low, спека).** `Handler/MainFormHandler.cs:GetNotifyIcon4Routing` —
`new Bitmap(item.customIcon)` не диспоузится; `Icon.FromHandle` без `DestroyIcon`
(утечка GDI-хендла иконки трея).

**R5-LC-3-8 (Low, спека).** `SubSettingControl.btnShare_Click`, `QRCodeControl.showQRCode` —
старый `picQRCode.Image` не диспоузится при каждом показе QR (клик по каждому серверу).

**R5-LC-3-9 (Low, спека).** `Client/MainForm.cs:RenderSubscriptions` — полная перестройка
всех карточек (Dispose + new) на КАЖДЫЙ результат пинга во время `Probe`. При сотнях
серверов — O(n²) UI-чёрн. Спека: обновлять только строку пинга (in-place) или
батчить перерисовку по завершении пробы.

### Проход 4 — Качество кода

**R5-LC-4-1 (Medium, спека).** `Handler/ProxySetting.cs` — полностью мёртвый класс
(вызывающих нет), внутри незакрытый `HGlobal`. Спека: удалить файл.

**R5-LC-4-2 (Low, спека).** `Utils.FromJson<T>` — catch-фолбэк `DeserializeObject<T>("")`
бессмысленен (бросает снова) и маскирует реальную ошибку парсинга. Спека: вернуть
`default` + лог.

**R5-LC-4-3 (Medium, спека).** `MainForm.HappPages.NormalizeSoraVisibleConfiguration` —
деструктивно ПЕРЕИМЕНОВЫВАЕТ пользовательские routing-наборы, содержащие
"Whitelist"/"Blacklist"/"Global", в русские названия при каждом старте.
Пользовательский конфиг молча мутирует. Спека: маппить отображаемое имя отдельно,
не трогая `remarks`.

**R5-LC-4-4 (Low, спека).** `ConfigHandler.DedupServerList` — `source.Reverse()` мутирует
список вызывающего + закомментированный код внутри. Спека: работать с копией.

**R5-LC-4-5 (Low, спека).** `Tool/QueryableExtension.cs` — вызывающих нет (проверено
grep), `_GetLamba` (опечатка), NRE при отсутствии свойства. Спека: удалить.

**R5-LC-4-6 (Low, спека).** Нейминг/опечатки: `_GetLamba` → `_GetLambda`,
`entryOuputPath` → `entryOutputPath`; смешанные комментарии (китайский/русский/
английский) затрудняют ревью.

**R5-LC-4-7 (Low, спека).** Мёртвые закомментированные блоки: `ShareHandler`
(Sip002/Socks старые варианты), `ConfigHandler.LoadConfig` (http-inbound),
`ListViewFlickerFree.lv_DragDrop`, `Utils.IsIP` (`//ip = ip.TrimEx()`).
Спека: вычистить.

### Проход 5 — Системы и UX

**R5-LC-5-1 (Medium, спека).** Хардкод русских строк в новом коде вместо ресурсов:
`UpdateHandle.UpdateSubscriptionsAsync` («Не заполнен адрес подписки.»,
«Требуется защищённый адрес HTTPS.» и др.), весь новый Happ UI
(`MainForm.HappPages.cs:27-76+`, `MainForm.Community.cs:176-418` — десятки строк),
`CommunityDiagnostics`, `TunModeController` («Компоненты TUN не установлены...»).
Английская/китайская локали их не увидят.

**R5-LC-5-2 (Low, спека).** `MainForm.HappPages.FormatSoraInterval` — неверная
плюрализация: «3 часов» (надо «3 часа»), «3 дней» (надо «3 дня»), «3 минут»
(надо «3 минуты»). Спека: полноценная русская плюрализация (1/2-4/5+).

**R5-LC-5-3 (Low, спека).** `Global.SpeedPingTestUrl = "https://www.google.com/generate_204"` —
в РФ google.com часто недоступен/медленный → ложные «недоступен». Спека: нейтральный
эндпоинт или конфигурируемый URL.

**R5-LC-5-4 (Low, спека).** `MainForm.SetCurrentLanguage` пишет реестр без рестарта,
`SoraText.Select` — с рестартом: после смены языка из legacy-меню UI частично
переведён (непоследовательно). Кэш `RefreshLanguage` подключён (коммит `769ae3b`),
но семантика «без рестарта» осталась. Спека: унифицировать (рестарт + диалог).

**R5-LC-5-5 (Low, спека).** `HappIconLoader.Load/LoadSoraLogo` — исключение при
отсутствующих ассетах роняет старт без диагностики. Спека: fallback-иконка + лог.

## Сводная таблица

| ID | Проход | Sev | Файл | Статус |
|---|---|---|---|---|
| R5-LC-2-19 | 2 | Critical | Forms/MainForm.Community.cs | ✅ `a047e17` |
| R5-LC-1-1 | 1 | High | Handler/DownloadHandle.cs | ✅ `769ae3b` |
| R5-LC-1-2 | 1 | High | Base/HttpClientHelper.cs | ✅ `769ae3b` |
| R5-LC-2-1 | 2 | High | Tool/Utils.cs (IsNumberic) | ✅ `1c6ff01` |
| R5-LC-2-2 | 2 | High | Tool/Utils.cs (IsIP) | ✅ `1c6ff01` |
| R5-LC-2-3 | 2 | High | Handler/ConfigHandler.cs (LoadConfig) | ✅ `1c6ff01` |
| R5-LC-1-3 | 1 | Medium | Tool/Utils.cs (DeepCopy) | 📝 спека |
| R5-LC-2-4 | 2 | Medium | Mode/Config.cs (GetLocalPort) | ✅ `1c6ff01` |
| R5-LC-2-5 | 2 | Medium | Handler/ConfigHandler.cs (sort) | ✅ `1c6ff01` |
| R5-LC-2-6 | 2 | Medium | Forms (Enum.Parse ×3) | ✅ `1c6ff01` |
| R5-LC-2-7 | 2 | Medium | Forms (BindingSub NRE ×3) | ✅ `1c6ff01` |
| R5-LC-2-9 | 2 | Medium | Forms/MainForm.cs (blProxy) | ✅ `1c6ff01` |
| R5-LC-2-10 | 2 | Medium | Forms (menuRemove ×2) | ✅ `1c6ff01` |
| R5-LC-2-16 | 2 | Medium | Forms/RoutingRuleSettingForm.cs (UI-поток) | ✅ `769ae3b` |
| R5-LC-2-17 | 2 | Medium | Handler/V2rayConfigHandler.cs (port:) | 📝 спека |
| R5-LC-2-18 | 2 | Medium | Forms/MainForm.cs (SetDefaultServer) | 📝 спека |
| R5-LC-3-1 | 3 | Medium | Base/HttpClientHelper.cs (копии буфера) | ✅ `769ae3b` |
| R5-LC-3-3 | 3 | Medium | Forms/MainMsgControl.cs (ReDoS) | ✅ `769ae3b` |
| R5-LC-4-1 | 4 | Medium | Handler/ProxySetting.cs (мёртвый) | 📝 спека |
| R5-LC-4-3 | 4 | Medium | Forms/MainForm.HappPages.cs (переименование) | 📝 спека |
| R5-LC-5-1 | 5 | Medium | Хардкод RU-строк | 📝 спека |
| R5-LC-1-4 | 1 | Low | File.Delete traversal | 📝 спека |
| R5-LC-1-5 | 1 | Low | sysproxy.exe TOCTOU | 📝 спека |
| R5-LC-2-8 | 2 | Low | Forms/MainForm.cs (Substring) | ✅ `1c6ff01` |
| R5-LC-2-11 | 2 | Low | Handler/ShareHandler.cs (arr22) | ✅ `1c6ff01` |
| R5-LC-2-12 | 2 | Low | Forms/AddServer2Form.cs (GetFullPath) | ✅ `1c6ff01` |
| R5-LC-2-13 | 2 | Low | Tool/FileManager.cs (throw;) | ✅ `1c6ff01` |
| R5-LC-2-14 | 2 | Low | Handler/UpdateHandle.cs (First) | ✅ `e29b945` |
| R5-LC-2-15 | 2 | Low | Forms/GlobalHotkeySettingForm.cs | ✅ `e29b945` |
| R5-LC-2-20 | 2 | Low | Handler/ShareHandler.cs (пустая ветка) | 📝 спека |
| R5-LC-3-2 | 3 | Low | Tool/Utils.cs (Ping/MD5/Bitmap) | ✅ `769ae3b` |
| R5-LC-3-4 | 3 | Low | Tool/SoraText.cs (кэш языка) | ✅ `769ae3b` |
| R5-LC-3-5 | 3 | Low | Дебаунс импорта | 📝 спека |
| R5-LC-3-6 | 3 | Low | new Font без dispose | 📝 спека |
| R5-LC-3-7 | 3 | Low | Bitmap/Icon трея | 📝 спека |
| R5-LC-3-8 | 3 | Low | picQRCode.Image | 📝 спека |
| R5-LC-3-9 | 3 | Low | RenderSubscriptions O(n²) | 📝 спека |
| R5-LC-4-2 | 4 | Low | FromJson фолбэк | 📝 спека |
| R5-LC-4-4 | 4 | Low | DedupServerList Reverse | 📝 спека |
| R5-LC-4-5 | 4 | Low | QueryableExtension | 📝 спека |
| R5-LC-4-6 | 4 | Low | Опечатки/нейминг | 📝 спека |
| R5-LC-4-7 | 4 | Low | Закомментированный код | 📝 спека |
| R5-LC-5-2 | 5 | Low | Плюрализация | 📝 спека |
| R5-LC-5-3 | 5 | Low | SpeedPingTestUrl | 📝 спека |
| R5-LC-5-4 | 5 | Low | SetCurrentLanguage | 📝 спека |
| R5-LC-5-5 | 5 | Low | HappIconLoader | 📝 спека |

Итого: 46 находок (1 Critical, 5 High, 14 Medium, 26 Low).
Исправлено кодом: 22. Осталось спекой: 24.

## Топ-3

1. **R5-LC-2-19 (Critical)** — правка аудита без тулчейна сломала компиляцию всего
   проекта (`MainForm.Community.cs`): метод внутри метода + orphaned `catch`.
   Главный урок: C# без компилятора требует построчной вычитки каждой правки
   и механической проверки (баланс скобок) после. Исправлено, `a047e17`.
2. **R5-LC-1-2 + R5-LC-2-1 (High)** — два «тихих убийцы», которые выглядели рабочими:
   синглтон `HttpClientHelper`, который никогда не был синглтоном (локальная
   переменная тенила поле), и `IsNumberic`, всегда возвращавший `true` (валидация
   портов была фикцией). Оба — классика дефектов, невидимых без чтения кода.
3. **R5-LC-3-3 (Medium)** — ReDoS через пользовательский regex-фильтр журнала:
   один паттерн вида `(a+)+$` вешал UI намертво на каждой перерисовке.
   Пользовательский ввод нельзя отдавать в `Regex` без таймаута — теперь есть
   (2с, fail-open).

## Исправлено сразу (коммиты, ветка bugfix/audit-2026-10-19, без пуша)

- `a047e17` — `[review-5pass] fix MainForm.Community.cs: IsAppDirectoryUserWritable
  was nested inside RestartCommunityAsAdministrator (R5-LC-2)` — 1 файл.
- `1c6ff01` — `[review-5pass] correctness fixes (pass 2): validation, NRE guards,
  off-by-ones` — 12 файлов (R5-LC-2-1/2/3/4/5/6/7/8/9/10/11/12/13).
- `769ae3b` — `[review-5pass] resource & threading fixes (passes 2-3): HttpClient,
  disposables, ReDoS, UI thread` — 5 файлов (R5-LC-1-1/1-2/2-16, R5-LC-3-1/2/3/4).
- `e29b945` — `[review-5pass] harden GlobalHotkeySettingForm indexing; graceful
  empty release list` — 2 файла (R5-LC-2-14/2-15).

Каждый коммит — только пути `legacy/` (своя зона). В рабочей копии есть незакоммиченные
изменения sibling-агента в `core/` — не трогал, не коммитил.

## Осталось спекой (24)

Безопасность: R5-LC-1-3 (BinaryFormatter→JSON), R5-LC-1-4 (гарды traversal),
R5-LC-1-5 (подпись sysproxy.exe).
Корректность: R5-LC-2-17 (clash `port:`/`socks-port:`), R5-LC-2-18 (позиционная
связь `lstVmess`↔`lvServers.Items`), R5-LC-2-20 (пустая ветка).
Живучесть: R5-LC-3-5 (дебаунс импорта), R5-LC-3-6 (Font), R5-LC-3-7 (Bitmap/Icon),
R5-LC-3-8 (QR Image), R5-LC-3-9 (RenderSubscriptions O(n²)).
Качество: R5-LC-4-1 (удалить ProxySetting), R5-LC-4-2 (FromJson), R5-LC-4-3
(не переименовывать routing-наборы), R5-LC-4-4 (Reverse), R5-LC-4-5 (удалить
QueryableExtension), R5-LC-4-6 (опечатки), R5-LC-4-7 (закомментированный код).
UX: R5-LC-5-1 (строки в ресурсы), R5-LC-5-2 (плюрализация), R5-LC-5-3
(SpeedPingTestUrl), R5-LC-5-4 (рестарт при смене языка), R5-LC-5-5 (HappIconLoader).

## Примечания

- Аудит-фиксы (C# без тулчейна) в целом корректны: диффы 17 затронутых файлов
  вычитаны; структурная поломка найдена ровно одна (R5-LC-2-19, исправлена).
  Логика остальных фиксов (верификация движков, downgrade-protection, Mutex,
  спидтест) — без замечаний.
- `Control/`, `Client/`, `tests/` (новый interop-клиент) — написаны аккуратно:
  pipe-верификация через SCM до handshake (fail-closed), bounded channel с
  DropOldest, корректные таймауты RPC. Замечания только мелкие (R5-LC-3-9,
  fallback языка в `MakeLanguageSelect` при битом значении в настройках —
  `Single()` бросит; рекомендую `SingleOrDefault` + дефолт).
- Файлы `legacy/Client/MainForm.cs`, `legacy/Control/SessionRequests.cs`,
  `legacy/tests/*/Program.cs` в `git log` аудита — это история базовой ветки
  `legacy`, не правки аудита.
