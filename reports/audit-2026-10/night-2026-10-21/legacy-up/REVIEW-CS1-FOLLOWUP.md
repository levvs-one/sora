# Ревью follow-up по REVIEW-CS1 — независимый ревьюер

Объект: пять коммитов поверх HEAD ревью CS1 в `sora-legacy`, ветка
`bugfix/audit-2026-10-19`, HEAD `8a6286efe692c04d15c7157ccca3d02d128cf07f`:

- `c55ff3e` — F1 (биты WinINet-флагов, `SystemProxy.cs`);
- `1b484ec` — F4+F7 (`ClientContract.cs`, `ImportLink.cs`, `Program.cs`,
  `AutoRun.cs`);
- `59efda5` — F5 (глобальные обработчики, `Program.cs`);
- `7cc29e8` — честные комментарии (`Sora.iss`, `ClientSettings.cs`);
- `8a6286e` — пин-тесты (`PinTests.cs`, харнесс ClientInterop `--logic`).

Код ревьюером не правился, коммитов не делалось. Рабочее дерево не
использовалось: в нём живой WIP параллельного отдела C# part 2
(`MainForm`/`Strings`/`LogsPage`/`SubscriptionCard`/`app.manifest`).
Всё проверялось по `git archive HEAD`, распакованному в
`~/workspace/review-cs1-followup/archive/`.

Метод: построчная сверка с эталоном `v2rayN/Handler/ProxySetting.cs`
и `v2rayN/Program.cs`; исполнение на байт-в-байт копиях закоммиченных
`SystemProxy.cs`/`ImportLink.cs`/`AutoRun.cs`/`ClientContract.cs`
в scratch-проектах net8 (`~/workspace/review-cs1-followup/scratch-new`,
`scratch-old`; идентичность копий подтверждена `cmp`; стабы — только
вне тестируемой логики: in-memory реестр вместо Win32, путь
`Application.StartupPath/ExecutablePath`, минимальный `JObject` поверх
`System.Text.Json`, заглушка `ClientSettings` для `AutoRun.Reconcile`);
сборка всех 5 проектов из архивной копии.

---

## Вердикты

| Находка | Вердикт |
|---|---|
| F1 (биты флагов / PAC) | **ЗАКРЫТА** — подтверждено исполнением, включая ветку `Restore` и воспроизведение исходного бага |
| F4 (двойной decode имени) | **ЗАКРЫТА** — подтверждено исполнением, обязательными и дополнительными векторами |
| F5 (глобальные обработчики) | **ЗАКРЫТА** — установка и семантика по эталону; одно minor-замечание о судьбе Trace-записи (§3) |
| F7 (контракт в одном месте) | **ЗАКРЫТА** — внутри Client литералов контракта в коде не осталось; формат Run-значения не сломан |
| §4, комментарии: `Sora.iss` | **ЗАКРЫТО** — текст теперь правдив полностью |
| §4, комментарии: `SystemProxy.cs` | **ЗАКРЫТО** — обе частичности задекларированы и соответствуют коду |
| §4, комментарии: `ClientSettings.cs` | **ЧАСТИЧНО** — формулировка описывает состояние WIP-дерева, а не HEAD (§5) |
| Пин-тесты (`8a6286e`) | **ЗАКРЫТО с мелочами** — покрытие совпадает с исполнявшимся, `--logic` существующие режимы не ломает; счётчик проверок в сообщении коммита завышен на 1 (§6) |
| Сборка и дисциплина коммитов | **ЗАКРЫТО** — 5/5 проектов 0/0 из архива; в пяти коммитах только заявленные файлы |

**Общий вердикт по follow-up: ЧАСТИЧНО — по одной точке.**
Весь код (F1/F4/F5/F7) закрыт и подтверждён исполнением; не закрыта
только одна из трёх «честных» формулировок: комментарий в
`ClientSettings.cs` на закоммиченном HEAD утверждает как факт опцию
диалога Modes, которой на HEAD ещё нет (§5). Это та же болезнь, что
лечил коммит `7cc29e8`, в мягкой форме: текст станет правдой, когда
приземлится part 2 соседнего отдела, но на момент HEAD он опережает
код. Достаточное закрытие — либо приземление part 2, либо условная
формулировка комментария.

---

## 1. F1 — ЗАКРЫТА (исполнением)

Константы `SystemProxy.cs:40-43` сверены с эталоном
`v2rayN/Handler/ProxySetting.cs:176-179` (`PerConnFlags`) и стандартом
`INTERNET_PER_CONN_FLAGS`:

| Константа | HEAD | Эталон | Итог |
|---|---|---|---|
| `FlagDirect` | 1 | `PROXY_TYPE_DIRECT = 0x1` | ✓ |
| `FlagProxy` | 2 | `PROXY_TYPE_PROXY = 0x2` | ✓ |
| `FlagAutoProxyUrl` | 4 | `PROXY_TYPE_AUTO_PROXY_URL = 0x4` | ✓ |
| `FlagAutoDetect` | 8 | `PROXY_TYPE_AUTO_DETECT = 0x8` | ✓ |

Scratch-прогон (новый код), все обязательные векторы `ParseFlags`:
`"1"→1, "5"→5, "7"→7, "13"→13, "15"→15, "9"→9, "3"→3, "2"→2, ""→1,
null→1`, токен-форма `PROXY_TYPE_DIRECT|PROXY_TYPE_AUTO_PROXY_URL→5`,
`"bogus"→null` — все PASS. Дополнительные векторы ревьюера тоже PASS:
токены поодиночке (`AUTO_PROXY_URL→4`, `AUTO_DETECT→8`), токены с
пробелами, смешанный `DIRECT|bogus→null`, `" 5 "→5`, `"0"→0`, `"4"`,
`"6"`, `"8"`.

Ветка `Restore` прогнана end-to-end (запись `user-wininet.json` →
in-memory реестр): PAC-бит — это бит 4.

| Flags | `AutoConfigURL` после `Restore` (новый код) |
|---|---|
| `"5"` | **восстановлен** (`SetValue`), файл записи удалён |
| `"7"`, `"13"`, `"15"` | восстановлен |
| `"9"` (DIRECT\|AUTO_DETECT) | **отсутствует** — PAC не воскресает |
| `"1"`, `"3"` | отсутствует |
| `"5"` с пустым `PacUrl` | отсутствует (условие `pacUrl.Length > 0`) |

Воспроизведение исходного бага на родителе (`git show c55ff3e^:...`,
тот же стенд, константы родителя `AutoProxyUrl=8, AutoDetect=4`):

| Flags | Родитель | Новый код |
|---|---|---|
| `"5"` | PAC **удалён** — баг воспроизведён | восстановлен |
| `"7"` | PAC **удалён** — баг воспроизведён | восстановлен |
| `"9"` | PAC ошибочно **восстановлен** (зеркальная сторона бага) | отсутствует |
| `"13"`, `"15"` | восстановлен (случайно верно, бит 8) | восстановлен |
| Токен-форма | `DIRECT\|AUTO_PROXY_URL → 9`: внутренне согласована, числовой баг маскирует — как и писал REVIEW-CS1 | `→ 5` |

Фикс меняет ровно то поведение, которое описывала находка, и ничего
лишнего: остальная логика `Restore` в диффе `c55ff3e` не тронута,
`ParseFlags` лишь widened `private → internal` как шов для пин-тестов.

## 2. F4 — ЗАКРЫТА (исполнением)

Дифф `1b484ec` делает ровно заявленное: query-имя берётся как вернул
`ParseQuery` (один decode), decode в `Parse` остался только на
fragment-ветке, где `Uri.Fragment` приходит экранированным.

Обязательные векторы (scratch, PASS): `name=My%2520Sub → "My%20Sub"`;
`name=My%20Sub → "My Sub"`; `#My%20Sub → "My Sub"`; `add/<url>` обе
формы (verbatim при `://`, percent-decode без схемы); routing-форма
отклонена; не-http(s) цель отклонена в обеих формах (`add/ftp://…`,
`url=ftp%3A%2F%2F…`).

Дополнительные векторы ревьюера (все PASS): fragment `#My%2520Sub →
"My%20Sub"` (fragment тоже декодируется ровно один раз); `name=My+Sub
→ "My Sub"` (`+` обрабатывает `ParseQuery`); двойно-закодированный
query-URL декодируется один раз и отклоняется как не-абсолютный;
CRLF в цели после decode отклонён; host ≠ `add` отклонён; ключи query
регистронезависимы; `add/` пустой и `url=` пустой отклонены;
`ADD/` и схема `SORA://` в inline-форме принимаются. Родительский код
(`1b484ec^`) действительно содержал повторный `UnescapeDataString`
поверх результата `ParseQuery` — находка и фикс соответствуют друг
другу один в один.

## 3. F5 — ЗАКРЫТА (одно minor-замечание)

Место установки точно как заказано и как в эталоне: `Program.Main` —
`RestoreProxy`-ранний-выход → `WaitForPreviousInstance` →
`EnableDpiAwareness` → **`InstallExceptionHandlers()`** →
`EnableVisualStyles`/`SetCompatibleTextRenderingDefault` →
`Application.Run(context)`. Порядок совпадает с `v2rayN/Program.cs`
(там: wait-for → DPI → обработчики → visual styles → Run) и
удовлетворяет требованию WinForms: `SetUnhandledExceptionMode` вызван
до создания любого окна.

Состав — паритет с эталоном: `SetUnhandledExceptionMode(CatchException)`,
`Application.ThreadException`, `AppDomain.CurrentDomain.UnhandledException`
— все три элемента `v2rayN/Program.cs:39-41` на месте. Обработчики пишут
только имя типа исключения (`e.Exception.GetType().Name`,
`e.ExceptionObject?.GetType().Name ?? "unknown"`) в `Trace`;
пользователю не показывается ничего — сырого текста наружу нет,
новый ARB-ключ не выдумывается. Это соответствует стандарту отдела.

Граница AppDomain-обработчика оценена честно: комментарий в коде
говорит, что сбежавшее исключение «is recorded by the AppDomain
handler on its way out» — процесс при этом не спасается, и комментарий
этого и не обещает. У эталона та же граница (его
`CurrentDomain_UnhandledException` только пишет `SaveLog`): это
паритет, а не недосказанность о выживании. Единственное расхождение
с эталоном — носитель записи (minor): v2rayN пишет полное исключение
в файловый лог (`Utils.SaveLog`), новый Client пишет имя типа в
`Trace`, а слушателя Trace в Client не настроено (grep по архивной
копии: ни `Trace.Listeners`, ни файлового listener, ни `.config`).
Конвенция «только имя типа в Trace» — общая для всех обработчиков
этого клиента, и для цели F5 (убрать сырой диалог) этого достаточно;
но фраза комментария «the log is the record» обещает чуть больше,
чем Trace без слушателя доставляет. Замечание minor, вердикт не
меняет.

Установка после раннего выхода `--restore-proxy` и после `LoadText`
границу не расширяет сверх эталона: у v2rayN restore-путь тоже
завершается до установки обработчиков, а `LoadText` защищён
собственными fallback-перехватами.

## 4. F7 — ЗАКРЫТА

`ClientContract.cs` (новый, `1b484ec`) — единственное место внутри
`legacy/Client`, где в коде живут `RegistryPath = @"Software\Sora"`,
`SilentArgument`, `RestoreProxyArgument`, `WaitForArgument`,
`LinkSchemePrefix`. Grep по архивной копии `legacy/Client` на
`Software\\Sora`, `--silent`, `--restore-proxy`, `--wait-for`,
`sora://`:

| Оставшийся литерал | Где | Оценка |
|---|---|---|
| Все 5 констант | `ClientContract.cs` | само определение — норма |
| `Software\Sora`, `--silent` и др. | комментарии в `Program.cs`/`ImportLink.cs`/`AutoRun.cs`/`SystemProxy.cs` | проза документации, не код |
| `"sora"` (имя схемы без `://`) | `ImportLink.Parse` | грамматика ссылки, не префикс контракта — см. мелочи |
| `--silent`, `--restore-proxy --silent` | `Sora.iss` (`[Icons]`, `[UninstallRun]`) | вне Client: инсталлятор — другая сторона контракта, C#-константу потребить не может; обоснованное исключение |

Потребители переведены полностью: `Program` (`HasArg` ×2,
`WaitForPreviousInstance`, оба реестровых ключа), `ImportLink`
(`FindArgument`, `Forward`, `TakePending`), `AutoRun.Command`.
Сравнений входящих аргументов «в обход» констант в коде не осталось.

Формат Run-значения рефактор не сломал: `AutoRun.Command` =
`"\"" + ExecutablePath + "\" " + ClientContract.SilentArgument` при
`SilentArgument == "--silent"` даёт байт-в-байт эталон c955461
`"<exe>" --silent` — подтверждено исполнением в стенде (стаб-путь
`C:\…\Sora.Legacy.exe` → `"C:\…\Sora.Legacy.exe" --silent`), а
`AutoRun.IsEnabled` по-прежнему принимает ровно три формы эталона
(голый путь, путь в кавычках, путь в кавычках + `--silent`; форма с
`--tun` и пустая строка отклонены — стенд, PASS).

## 5. Честные комментарии — ЧАСТИЧНО (один из трёх текстов)

**`Sora.iss` — правдив, закрыто.** Новый текст называет все три факта:
регистрация сделана впрок («made ahead of time»); поставляемый сегодня
exe собран из v2rayN, аргумент `sora://` не обрабатывает и клик
«silently dropped for now»; обработчик — `Program.cs` нового клиента,
регистрация вступит в силу без изменений при смене stage. Дифф
`7cc29e8` трогает только комментарий: строки `[Registry]`, ключ
`uninsdeletekey` и stage не изменены.

**`SystemProxy.cs` (заголовок, `c55ff3e`) — правдив, закрыто.**
«Restored exactly» теперь оговорено числовым примером `"5"`, который
исполнением подтверждён; обе частичности задекларированы отдельными
пунктами и соответствуют коду: (1) бит `AUTO_DETECT` не
восстанавливается — код действительно не трогает бинарный
`DefaultConnectionSettings`; (2) replay покрывает только LAN-значения
HKCU `Internet Settings` — код действительно открывает только этот
ключ, RAS-записей в нём нет. Ссылка на `ProxySetting.cs (PerConnFlags)`
как источник истины битов — на месте и точна.

**`ClientSettings.cs` — на HEAD опережает код, частично.** Новый
комментарий утверждает в настоящем времени: опция живёт «in the Modes
dialog», а «a change from the dialog is applied through
AutoRun.SetEnabled». На закоммиченном HEAD этого ревью это не так:
диалог Modes на HEAD (`MainForm.ChooseModes` в архивной копии)
содержит только TUN/proxy/killSwitch/engine/stack; grep по HEAD —
ни `launchAtLogin`, ни вызова `AutoRun.SetEnabled` из диалога нет
вообще (единственные вызовы `SetEnabled` — внутри самого `AutoRun`
из `Reconcile`; единственное потребление — `Program.AutoRun.Reconcile`,
и эта вторая половина комментария правдива). Упомянутая опция прямо
сейчас добавляется параллельным отделом: в рабочем дереве (не HEAD)
`ChooseModes` уже содержит чекбокс `launchAtLogin` с чтением
`AutoRun.IsEnabled()` и применением через `AutoRun.SetEnabled(...)`
при сохранении — то есть комментарий станет точным ровно с
приземлением part 2. Оценка дана, как заказано, на момент HEAD:
формулировка описывает будущее состояние как текущий факт.
Сообщение коммита `7cc29e8` («it now names the fact — the option
lives in the Modes dialog») повторяет то же опережение. Засчитываю
как частично: расхождение не в механике (Reconcile-часть верна), а
во времени глагола; закрывается приземлением part 2 либо правкой
формулировки в условную.

## 6. Пин-тесты (`8a6286e`) — закрыто с мелочами

Покрытие `PinTests.cs` совпадает с векторами, исполнявшимися в
scratch: значения флагов против эталонного enum (все 4); числовая
форма `"1"/"5"/"7"/"13"/"15"` равенством; токен-форма и `"bogus"`;
PAC-предикат по 8 значениям (`"1","5","7","13","15","9","3","2"` —
именно бит 4); `ImportLink` в обеих формах, включая `My%2520Sub →
"My%20Sub"` (F4) и fragment-имя с decode. Независимый прогон
ревьюера на тех же копиях — 87/87 PASS, набор шире пин-тестов
(константы 4, `ParseFlags` 22, PAC 12, `Restore` 8, `ImportLink` 35,
`AutoRun` 6).

Режим `--logic` существующие режимы не ломает: перехват стоит в
`ClientInterop/Program.cs` сразу после проверки `args.Length == 1` и
до проверки администратора/GUI-пути; прежний режим (один аргумент —
каталог скриншотов) изменён только тем, что строка `--logic` теперь
зарезервирована. Доступ к internal-типам — рефлексией, существующий
паттерн харнесса (`Assembly.Load("Sora.Legacy")`); шов для этого в
проде — widen `ParseFlags` в `c55ff3e` — на месте.

Честность прогона: сообщение коммита прямо говорит, что идентичные
векторы исполнены на net8 scratch-копиях, а «the in-repo run itself
is a Windows dev-machine step» — это правда (net48 WinForms на этой
Linux-VM не запускается; мой стенд подтвердил векторы, но не сам
`--logic`-прогон). Две мелочи: (1) в сообщении коммита «all 30 checks
pass» — фактических выполнений `Expect` в `PinTests.cs` 29
(4 константы + 10 `ParseFlags` + 8 PAC-цикла + 7 ссылок): завышение
на единицу, не на порядок, но в отделе с пин-тестами счёт должен
сходиться; (2) зазоры покрытия: `"9"/"3"/"2"` пинятся только как
PAC-предикат, не равенством `ParseFlags`; нет токена
`PROXY_TYPE_AUTO_PROXY_URL` соло и query-формы не-http(s) цели
(есть только `add/ftp`). На dev-машине (Windows) осталось: прогнать
`ClientInterop --logic`, ожидается exit 0 и строка PASS.

## 7. Сборка и дисциплина — ЗАКРЫТО

Сборка из архивной копии HEAD (`dotnet build`, `TMPDIR` на диске):

| Проект | Итог |
|---|---|
| `legacy/Control/Sora.Legacy.Control.csproj` | ✅ 0 warnings / 0 errors |
| `legacy/Client/Sora.Legacy.Client.csproj` | ✅ 0 / 0 |
| `legacy/tests/ClientInterop/ClientInterop.csproj` | ✅ 0 / 0 |
| `legacy/tests/ControlInterop/ControlInterop.csproj` | ✅ 0 / 0 |
| `legacy/tests/ServiceInterop/ServiceInterop.csproj` | ✅ 0 / 0 |

`git show --stat` пяти коммитов — только заявленные файлы: `c55ff3e`
1 файл (`SystemProxy.cs`); `1b484ec` 4 (`AutoRun`, `ClientContract`
новый, `ImportLink`, `Program`); `59efda5` 1 (`Program.cs`);
`7cc29e8` 2 (`ClientSettings.cs`, `Sora.iss`); `8a6286e` 2
(`PinTests.cs` новый, харнесс `Program.cs`). Чужих файлов part 2
(`MainForm`/`Strings`/`LogsPage`/`SubscriptionCard`/`app.manifest`,
ARB) ни в одном из пяти коммитов нет — проверено и по `--stat`, и по
`--name-only` поиском по именам.

## 8. Мелочи

- `ClientContract`: константы объявлены `public const` внутри
  `internal static class` — `public` избыточен и расходится со стилем
  соседних private-констант (`InternetSettingsPath`, `RunPath`);
  на доступность снаружи сборки не влияет.
- Заголовок `ClientContract.cs` слегка приукрашивает эталон: у
  v2rayN в одном месте живёт путь реестра (`Global.MyRegPath`), а
  CLI-литералы в его `Program.cs` как раз выписаны по месту — то есть
  централизация аргументов у нового клиента строже эталона, а не
  «mirroring». Смысл комментария не искажён, точность — на полтона.
- `ImportLink.Parse`: имя схемы сравнивается с литералом `"sora"`, а
  грамматические литералы (`"add"`, `"add/"`, `"routing/add/"`) живут
  в парсере вне `ClientContract`. Это не дрейф контракта инсталлятора,
  но формулировка «Every consumer uses these constants instead of
  spelling the literals» шире фактического периметра констант.
- `SystemProxy.ParseFlags`: в token-switch `PROXY_TYPE_AUTO_DETECT`
  стоит перед `PROXY_TYPE_AUTO_PROXY_URL`, тогда как константы и
  эталонный enum идут в обратном порядке — косметика чтения.
- F5: обработчики у эталона — именованные методы, у нового клиента —
  лямбды; при принятой конвенции записи только имени типа это ни на
  что не влияет.
- `PinTests.cs`: стиль выдержан (счётчик failures, FAIL в stderr,
  PASS одной строкой), но PASS-строка не называет число проверок —
  расхождение «30 против 29» из §6 при такой строке непроверяемо из
  вывода; честнее было бы печатать счётчик.
- Пользователю сырого текста follow-up не добавил: обработчики F5
  молчат, новые диалоги не вводились, локализация не тронута (новых
  ARB-ключей нет — и это правильно: выдумывать ключ чужого отдела
  исполнитель не стал, честно оговорив это в сообщении `59efda5`).
- Адаптивность Win7→Win11 follow-up не ослабляет: новых API новее
  Win7 не введено (`SetUnhandledExceptionMode`/`ThreadException` —
  WinForms времён .NET 2.0), capability-подход DPI/restore не тронут.

---

Итог одной строкой: F1, F4, F5 и F7 закрыты по существу и
подтверждены исполнением (87/87 векторов ревьюера, исходный баг F1
воспроизведён на родителе и снят фиксом), сборка 5/5 по 0/0, чужих
файлов в коммитах нет; follow-up не закрыт в одной точке —
комментарий `ClientSettings.cs` на HEAD описывает опцию диалога
Modes, которая существует пока только в WIP соседнего отдела, и
станет правдой с его приземлением.
