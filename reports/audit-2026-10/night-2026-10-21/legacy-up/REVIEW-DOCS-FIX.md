# REVIEW-DOCS-FIX — перепроверка правок Р-1…Р-7, коммит a13d45f [legacy-up] docs

Репозиторий: `sora-legacy`, ветка `bugfix/audit-2026-10-19`. Все сверки — по
закоммиченному состоянию (`git show a13d45f`, родитель `ee5f2ba`), не по
рабочему дереву. Код и доки не правились, коммитов не делалось.

**Вердикт: правки по списку — одна фактическая правка (Ф-1, во всех трёх
местах Р-1).** Все Р-1…Р-7 по существу закрыты, гарантия безопасности нигде
не завышена; новых ложных утверждений, кроме Ф-1, дифф не внёс.

## Ф-1. Р-1: «sing-box (в клиенте — SagerNet)» — ложное отождествление

Во всех трёх местах (README §Безопасность, `docs/install.md` §Обновление,
`docs/security.md`) sing-box отождествлён с SagerNet. По коду это разные типы:

- `ECoreType.SagerNet` (=3): `LazyConfig.cs` — `coreUrl =
  Global.SagerNetCoreUrl` = `https://github.com/SagerNet/v2ray-core/releases`,
  exe `{"SagerNet", "v2ray"}` — это v2ray-core форка SagerNet, не sing-box.
  Именно этот тип вызывается из меню (`MainForm.cs:1456`,
  пункт «Update SagerNet Core»).
- `ECoreType.sing_box` (=24): отдельный `CoreInfo` с `coreUrl =
  Global.singboxCoreUrl` = `https://github.com/SagerNet/sing-box/releases`,
  exe `{"sing-box-client", "sing-box"}`; пункта обновления этого типа в меню
  `MainForm` нет вообще.

Итог: распределение проверки по типам в доках верно по гарантии
(`HasChecksumManifest` = true только для v2fly/v2fly_v5/Xray, для обоих —
и SagerNet, и sing_box — false), но имя названо неверно: через GUI без
`.dgst`-проверки обновляется именно SagerNet (v2ray-core), а не sing-box.
Правка: в трёх местах заменить «sing-box (SagerNet)» / «sing-box (в клиенте —
SagerNet)» на «SagerNet» (при желании добавить «и sing_box, у которого
GUI-обновления нет»). Ошибка унаследована из формулировки Р-1 в REVIEW-DOCS.

## Подтверждено по первоисточникам

| Пункт | Итог |
| --- | --- |
| Р-1 (кроме Ф-1) | Закрыт. `UpdateHandle.HasChecksumManifest`: true только v2fly/v2fly_v5/Xray; при false — `SaveLog("Checksum manifest is not available…")` + `return null` (проверка пропущена, «остаётся запись в журнал» в install.md — правда), запрет downgrade (`CompareVersions <= 0` в `responseHandler`) действует до этого для всех типов. Формулировки во всех трёх файлах согласованы. Обоснование «апстрим не публикует `.dgst` в предсказуемом виде» — **не выдумано**: дословный комментарий в `VerifyCoreArchiveAsync` (та же строка, что и в коде при `!HasChecksumManifest`), плюс комментарий `HasChecksumManifest` «v2fly и XTLS публикуют .dgst-файлы». |
| Р-2 | Закрыт. Поставляемый `Program.cs`: `--silent`, `--restore-proxy`, `--wait-for`, `--tun` (второй параметр `MainForm`). Новый: `ClientContract.cs` — только `SilentArgument`/`RestoreProxyArgument`/`WaitForArgument`/`LinkSchemePrefix`; grep `--tun` по `legacy/Client/` и `legacy/Control/` — 0; заголовок контракта в его `Program.cs` `--tun` не перечисляет. `ClientSettings.Tun`: `[DefaultSettingValue("True")]` — «по умолчанию включена» верно; режим берётся из настройки (`MainForm.cs` нового клиента: `settings.Tun ? …`). Симметричная разница контрактов — ровно `--tun` и `sora://`: иных аргументов ни у одного из двух `Program.cs` нет. |
| Р-3 | Закрыт. Новая фраза README истинна: grep `SoraLegacyCore`/`CoreService` по `legacy/v2rayN/` — 0 обращений к службе; службой пользуется новый клиент через `legacy/Control/CoreService.cs`; поставляемый запускает движки сам. |
| Р-4 | Закрыт. Живой обработчик `MainForm.cs:1434-1437` — только `Process.Start(Global.UpdateUrl)`, `Global.UpdateUrl = "https://github.com/levvs-one/sora-legacy/releases"`; вызов `CheckUpdateGuiN` на строке 1446 закомментирован. «Пункт просто открывает страницу релизов в браузере» (README + install.md) — точно. |
| Р-5 | Закрыт. По csproj ровно шесть net48: Client (net48), Control (`net48;net8.0`), ClientInterop (net48), ControlInterop (`net48;net8.0`), ServiceInterop (net48), `legacy/v2rayN/v2rayN/v2rayN.csproj` (net48). Формулировка development.md (пять в списке + поставляемый, мультитаргет Control/ControlInterop назван) совпадает до проекта. |
| Р-6 | Закрыт. `Sora.iss:PrepareToInstall`: сначала блок KB3033929 (`IsWindows7 and not IsWin64 and not IsKb3033929Installed`), затем `IsDotNet48Installed`. Порядок шагов в install.md теперь совпадает. Коды 3010/1641: в обоих блоках `NeedsRestart := True` — приписка этих кодов шагу KB в новой редакции верна; SHA-256 `.msu` сверяется до `wusa.exe /quiet /norestart` — как написано. |
| Р-7 | Закрыт. Строка «Dart-код контракта 1.3» из §9 engines.md удалена (grep `Dart`/`protoc-gen` по файлу — 0). Оставшееся «1.3» в §5 истинно: proto, поле `SessionPlan.engines` (`repeated string engines = 8`) помечено «Since 1.3», текущая версия контракта 1.7 — `core/cmd/sora-core/main.go`: `Version{Major: 1, Minor: 7}`; заодно исправлено имя поля (было `SessionPlan.engine`, ед. число — такого поля нет). |

## Контроль исполнителя (повторён по дереву a13d45f)

- По 5 изменённым файлам: «один в один» — 0, «оба клиента» — 0,
  `CheckUpdateGuiN` — 0, «Пять проектов» — 0.
- Безусловных `.dgst`-утверждений не осталось: все три вхождения `.dgst` в
  изменённых доках теперь с оговоркой «только для ядер v2fly, v2fly_v5 и
  Xray».
- Ссылки: все относительные ссылки в 5 файлах ведут на существующие файлы
  дерева a13d45f; якоря `docs/install.md#обновление` и `#удаление` — на
  существующие заголовки. Новых ссылок коммит не добавлял.
- Дифф прочитан целиком: каждое изменённое предложение сверено с кодом;
  иных новых ложных утверждений, кроме Ф-1, нет.
